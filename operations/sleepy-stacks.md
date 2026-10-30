# Sleepy stacks: implementation and acceptance plan

Status: coordinated implementation, 2026-10-31. The approved current design is the hourly minimum-rate policy below, replacing the included-storage-floor policy for newly applied epochs. Earlier sleepy functionality and billing gates were active only on dev. Tests, CI and deployment of the new minimum-policy revisions have not been verified in this documentation update. Production activation and deployment remain disabled. This agent commits documentation only and does not push; the coordinator owns eventual publication of the dev-only feature.

## Owners and dependency order

| Scope | Owner | Deliverable | Depends on |
| --- | --- | --- | --- |
| sleepy-stack-service | Nash | Per-node HTTP proxy, idle lifecycle, expiring maintenance, durable usage journal, counters, environment configuration and tests | Shared identity and journal contract |
| vm-api | Wegener | Node profile application, Incus metadata, normal-profile recovery and tests | Profile and maintenance contract |
| vm-master-api | Herschel | Canonical stack metadata, maintenance, journal ingestion, UTC uptime aggregation and tests | Node support and proxy journal |
| admin | Aquinas | Normal-first profile picker, SPA/API Ninja/MCP maintenance and uptime, approved billing design enabled only on dev, and tests | Master endpoints and authoritative profile flag |
| LB | Hypatia | Node-aware routing and trusted canonical stack header, with normal routing preserved | Node proxy reachability and master stack identity |
| docs | Faraday | Czech user guide, operations plan, configuration and rollout guidance | Confirmed implementation contracts from all owners |
| Integration and rollout | Parent coordinator | Contract review, pipeline audit, cross-repository CI and approved dev canary | All owners' reviewable changes and acceptance evidence |

1. Freeze identity, maintenance and journal semantics; review each repository's dirty state and isolate overlapping changes. Never edit vendored dependencies directly.
2. Implement and test proxy and node contracts independently using fakes/disposable resources. Publish exact environment names, journal pagination and failure behavior to the coordinator.
3. Implement master ingestion and owner-scoped maintenance/uptime. Verify node/master identity mapping with distinct stack ID, backend name and billing reference.
4. Implement LB routing and admin consumers after producer schemas stabilize. Add features only to the new SPA, API Ninja and MCP; do not extend the legacy Django UI.
5. Reconcile this plan and the user guide with final contracts. Run repository checks and cross-repository acceptance before any push. The coordinator owns integration, green CI and eventual main-branch pushes.
6. After the coordinator completes integration, CI and deployment checks, deploy the already authorized proxy only to `stack-node-dev-01`. Keep production activation and production per-second charges disabled. Production requires a later explicit decision.

## Agreed shared contracts

Profile JSON has `sleepy: boolean`, defaulting to `false` when absent. The applied runtime field `stack.sleepy` is authoritative. Editing the profile catalog does not silently change existing stacks, consistent with existing resource/rate application. Catalog edits affect new allocations or switching to another profile; existing applied pricing snapshots remain unchanged. `UpdateProfile` rejects the same profile ID, so reapplying the current profile is not a refresh mechanism. Create a separate sleepy profile and explicitly switch to that different target profile for conversion; never infer applied mode from mutable catalog data. Master management UI supports the Sleepy checkbox on profile create/edit (`f607cb3`, real-JavaScript tested); admin alignment is `ff4509c3`. Normal profiles appear before sleepy profiles in pickers. No existing profile becomes sleepy implicitly.

Sleepy Incus instances use `user.stack-id` equal to the canonical vm-master-api stack ID. Never substitute `billing_id`, container/backend name or display name. `user.stack-maintenance` is `"1"` only during active maintenance. The shared expiry is `user.stack-maintenance-until`, RFC3339 in UTC, with a 15-minute window. Manual end removes maintenance state. Expired maintenance must stop suppressing idle shutdown even if the writer is unavailable. The proxy persists a fresh 15-minute expiry when an active flag has missing or malformed expiry. On expiry it clears local maintenance values, masking inherited settings. Persistence failures surface as errors; verify retry behavior in integration.

Applying a normal profile removes all sleepy metadata, including stack ID, maintenance flag and expiry, and starts a stopped container. Profile application must reconcile existing state, not only newly created instances. Tests must cover profile changes while stopped and while in maintenance.

### Master API

Implemented owner-scoped master paths:

| Operation | Contract |
| --- | --- |
| Maintenance | `POST /v2/stacks/{owner}/{id}/maintenance`, body `{"enabled": true}` or `{"enabled": false}`; response `{enabled, until}`, where `until` is RFC3339 UTC or `null` |
| Uptime | `GET /v2/stacks/{owner}/{id}/uptime`; optional `from` and `until` are RFC3339, `bucket_seconds` defaults to `3600` |

Uptime response fields are `stack_id`, `timezone: "UTC"`, `today_seconds`, `month_seconds`, `buckets: [{started_at, ended_at, running_seconds}]`, `complete`, and `errors: []`. Confirm final numeric precision, supported ranges, bucket limits, boundary clipping and error item schema against OpenAPI. Incomplete or unavailable readings must remain distinguishable from measured zero usage. Today/month boundaries are UTC; display this explicitly rather than silently using browser local time.

Admin API Ninja: `GET` and `POST /api-n/{company_id}/stacks/{stack_id}/maintenance` (POST body `{enabled}`); `GET /api-n/{company_id}/stacks/{stack_id}/uptime`. MCP: `get_stack_maintenance`, `set_stack_maintenance`, `get_stack_uptime`. All surfaces must preserve company ownership checks, company locks and normal-profile restrictions consistently.

### Proxy journal: agreed contract

The agreed endpoint is `GET` on the local metrics listener at `:8080/v1/usage`, with `after`, `limit`, and optional `stack_id`. Entries carry persistent `meter_id`, immutable cursor, integer `duration_ns`, and UTC start/end timestamps; master ingests with durable deduplication.

The current proxy implementation (`usage.go`) returns `{version: 1, meter_id, has_more, records, next_cursor}`. Records contain `cursor`, `stack_id`, `container`, `started_at`, `ended_at`, integer `duration_ns` and compatibility `uptime_seconds`. `after` defaults to 0 and must be nonnegative; `limit` defaults to 1000 and accepts 1–10000. Results are ordered by cursor, strictly after the supplied cursor. `next_cursor` is the last returned cursor, or the supplied cursor for an empty page. Filtering by `stack_id` preserves global cursor values; ingestion must keep separate cursors when using separate filters. Invalid pagination returns 400; database failures return 503.

The meter ID survives restarts and changes with database replacement. Deduplicate using `(meter_id, cursor)`. Preserve the database and WAL; do not clone an identity into independent active meters. Observed intervals do not reconstruct proxy-offline runtime. The proxy also exposes `GET :8080/v1/gaps?after=0`, an ordered diagnostic array (up to 1000 rows) with `cursor`, UTC `started_at`, nullable `ended_at` and `reason`; a null end denotes an ongoing gap. Master must consume or otherwise account for gaps before claiming completeness. Retention, backup recovery and timestamp/bucket reconciliation still need integration evidence. A Prometheus counter alone is insufficient as an accounting source.

## Hourly minimum-rate billing — approved, dev only

Profile JSON adds `sleepy_minimum_rate_multiplier`, default `0.2`: a finite number in the inclusive range `0..1`, with at most six decimal places. The new profile management UI must show an editable field for sleepy profiles. Catalog edits affect new allocations or a switch to another profile; they do not mutate existing applied pricing snapshots. `UpdateProfile` rejects the same profile ID. Normal profiles retain existing billing.

For each UTC hour, charge `fullProfileHourlyPrice * max(actualAwakeFraction, sleepy_minimum_rate_multiplier)`, plus normal full-price extra disk and snapshots. Maintenance counts as awake. Use the full profile price without subtracting included storage; there is no separately always-charged included-storage component. Evaluate the floor per UTC hour, never against a monthly average. A multiplier of `0` charges actual awake time; `1` charges the full profile for each owned wall-clock hour.

For a profile costing 100 CZK per 720 hours and multiplier `0.2`, the profile portion costs 20 CZK per 720 hours if every hour is at most 20% awake, and 100 CZK if fully awake. An hour that is half awake costs 50% of its full hourly price; an entirely asleep hour costs 20%. Alternating awake and asleep hours cannot be averaged before applying the floor. Add extra disk and snapshots to all examples.

Extra disk is `max(ceil(logicalActualGiB) - includedGiB, 0) * normalDiskUnitHourlyPrice * elapsedWallHours`. Charge it continuously, including while asleep, at the normal full disk unit price; the multiplier does not discount it. For 20 GiB included and 100 GiB logical actual usage, charge 80 GiB extra, with no separate charge for the included 20 GiB. Snapshot and retained-snapshot charging and existing free-account/trial exemptions remain unchanged.

Split each UTC hour at profile/rate epoch and ownership boundaries. For each hourly owner/rate bucket, `eligible_ns` is its eligible wall-clock duration and `actual_ns` is its merged actual awake duration. With integer `multiplierMicros` (the multiplier scaled by 1,000,000), compute `floor_ns = ceil(eligible_ns * multiplierMicros / 1_000_000)` and then `billable_ns = max(actual_ns, floor_ns)`; its profile charge is `frozenFullProfileHourlyPrice * billable_ns / nanosecondsPerHour`. The minimum is prorated within each segment, attributed to that segment's owner and immutable historical rates. For example, a half-hour segment with no awake time and multiplier `0.2` bills six minutes at its own rate. Do not apply a full-hour floor independently to each segment.

Legacy epochs created under the previous included-storage-floor policy retain their frozen storage/compute split and original settlement rules. They are not retroactively repriced or automatically converted by catalog edits or migration. Newly applied epochs use the minimum policy and freeze their full profile price and multiplier. Keep policy identity explicit when settling mixed historical epochs; never interpret legacy storage checkpoints as a new-policy included-storage charge. Current-policy implementation tests, CI and deployed-image verification remain pending here; read-only validation is not a Wallet debit test.

Stopped-container disk sampling is implemented and review is complete (node `42eb85d`). It scans with host `du -sbx` against a verified accessible Btrfs subvolume without waking the container. This does not imply support for all storage backends: unsupported or unmounted layouts fail explicitly rather than reporting zero usage. Billing reads cached disk samples only; missing samples trigger a bounded background scan. Master rejects incomplete disk data for sleepy billing; normal legacy behavior remains unchanged.

Master owns cumulative hourly-minimum accounting and exposes `billable_ns` for minimum-policy epochs. Minimum summaries and admin minimum checkpoints are identified by `(owner/company, stack, rate_epoch)`, without node or meter. Actual runtime snapshots retain `(stack, node, meter, rate_epoch)` identity. Merge actual hourly totals across node moves and meters for the same owner/stack/epoch before applying the maximum, so a move does not create another minimum. Compute the maximum within each UTC hour/ownership/rate bucket before summing; do not take one maximum over lifetime or monthly totals. Runtime uptime endpoints and graphs continue to report actual observed awake time, including maintenance, without the billing floor.

Admin charges only positive unseen cumulative billable deltas at the epoch's frozen full profile rate. Admin atomically commits financial checkpoints, Wallet debit, extra-disk wall-hour checkpoints, snapshot retention checkpoints and rounding carry in one database transaction. Retries, concurrent workers and delayed delivery must not charge twice; failure advances none of these. Journal ingestion cursors are distinct from consumed billing totals. All billing/usage GET reads are cumulative and non-consuming: reads never reset totals, advance a consumer checkpoint or debit Wallet.

The integer ceiling adds at most 1 ns of upward rounding per hourly owner/rate bucket; apply it once after merging across nodes/meters. Admin uses Decimal credit arithmetic and persists credit carry to avoid monetary rounding loss across repeated small debits. Historical rates and policy snapshots are immutable. Use master `docs/sleepy-contract.md` and admin migration/models for the exact snapshot, epoch, checkpoint and carry schemas; verify parity for the new policy before publication.

Missing/reset meters, negative deltas and unknown epochs require reconciliation and visible incompleteness, with no fabricated usage. Preserve durable meter identity across restarts and recognize a replacement meter explicitly. Timestamped journal intervals support historical graphs; reconciliation into authoritative cumulative counters must preserve identity and exactly-once acceptance. Monitoring graphs alone are not an accounting source.

Historical sleepy profile charges settle once after normal conversion, deletion or owner transfer using retained historical epochs and terminal settlements. Terminal rows settle outstanding historical profile charges under each epoch’s frozen policy; active normal rows settle historical sleepy charges alongside unchanged normal hourly sampling. Do not accrue a new-policy floor past the end of ownership or the sleepy epoch. Journal ingestion cursors and consumed cumulative runtime are distinct.

Company account closure has an explicit compatibility limit: financial checkpoints protect company audit references with `PROTECT` foreign keys. `CompanyProcessor.close` preflights for sleepy financial history before any external cleanup and returns an explicit error when such history exists. This avoids partial external cleanup followed by a foreign-key failure. Closing these company accounts requires a future archival/final-settlement workflow; financial audit history must not silently cascade away. This guard does not restrict supported stack deletion, profile changes or owner transfers, which use retained epochs and terminal settlements. Changing the future retention/closure policy requires its own review; implementing the guard does not require renewed approval. Production remains untouched.

Admin opt-in is `SLEEPY_BILLING_ENABLED=1`, default `0`. Historical migration `0135_sleepy_billing` depends on `0134`; migration `0136` adds the legacy storage currency checkpoint. New admin migration `0137` (`SleepyMinimumCheckpoint`) is underway. Its validation and application are not confirmed here; the historical migrations are not evidence that `0137` has been applied. Master explicitly runs `vm-master-api migration sleepy-apply` to extend sealed schema 2; no automatic production apply. `GET /v2/admin/stack-billing-owners` is service-only owner discovery. Use the versioned producer contract and admin schema for exact cumulative snapshot/epoch and Decimal carry fields.

## Proxy configuration and node routing

Every CLI flag maps to `SLEEPY_STACKS_` plus its uppercase name with hyphens replaced by underscores. Environment values set defaults; explicit CLI flags override them. Invalid values fail configuration. The current proxy implementation supports:

```ini
SLEEPY_STACKS_LISTEN=:80
SLEEPY_STACKS_METRICS_LISTEN=:8080
SLEEPY_STACKS_DATABASE=/var/lib/sleepy-stacks/uptime.db
SLEEPY_STACKS_INCUS=incus
SLEEPY_STACKS_INCUS_SOCKET=/var/lib/incus/unix.socket
SLEEPY_STACKS_LOCK_DIR=/run/lock/sleepy-stacks
SLEEPY_STACKS_UPSTREAM_INTERFACE=eth0
SLEEPY_STACKS_INVENTORY_EXCLUDED_INSTANCES=stackimage0
SLEEPY_STACKS_PROJECT=default
SLEEPY_STACKS_IDLE_TIMEOUT=60s
SLEEPY_STACKS_READY_TIMEOUT=60s
SLEEPY_STACKS_POLL_INTERVAL=1s
```

This is a configuration example, not a deployment action. The database path above is an operational persistent path; the CLI default is `sleepy-stacks.db`. The same mapping applies to transport/buffer flags listed in the proxy README. Verify the final systemd environment-file path before installing configuration. `sleepy_stacks_uptime_seconds_total{stack_id,container}` measures observed runtime; `sleepy_stacks_requests_total{stack_id}` counts enrolled requests including failed starts. Counters are operational evidence, not active charges.

Use the explicit host-facing interface (`eth0` by default), with no fallback to nested Docker interfaces such as `docker0`. Real dev smoke found both interfaces.

Proxy and node vm-api must use the same Linux flock directory (`SLEEPY_STACKS_LOCK_DIR`, default `/run/lock/sleepy-stacks`) with shared writable UID/group permissions. Filenames are lowercase SHA256 hex of the UTF-8 instance name plus `.lock`, without a project component. Never unlink lock files. Both services hold the shared lock through fresh reads and lifecycle/configuration operations.

`SLEEPY_STACKS_INCUS_SOCKET` defaults to `/var/lib/incus/unix.socket`. Maintenance uses Incus REST compare-and-set: fresh GET, identity/lease validation and PATCH with exact ETag/If-Match. Conflicts/failures skip shutdown, with no unconditional overwrite fallback. CLI operations address the same local socket. HTTP 202 Incus operations are awaited before treating changes as complete.

| Configuration area | Required review evidence |
| --- | --- |
| Listeners | HTTP on node `:80`; metrics/journal on `:8080`; restricted management-network exposure |
| Incus | Binary path, selected project, least required service permissions and reachable container addresses |
| Persistence | Persistent journal/database path, writable parent directory/WAL storage, backup and meter identity recovery policy |
| Lifecycle | Idle timeout, poll interval, startup/readiness budget, 15-minute maintenance expiry and concurrent request handling |
| Transport | Upstream and client timeouts, streaming/WebSocket behavior, cancellation and graceful shutdown |
| Deployment | Supported environment names/defaults, systemd unit, single manager per project and explicit node selection |

The existing LB terminates public TLS. Hypatia must route sleepy traffic to the proxy on the stack's assigned node, supplying a trusted `X-Stack-ID` containing the canonical stack ID. Public callers must not be able to override this identity. Proxy HTTP access must be limited to trusted ingress; metrics/journal must not become public. Confirm actual routing/configuration keys with Hypatia before writing commands.

Normal-profile traffic retains its normal route. Test multiple nodes with identical backend names and distinct stack IDs, node moves and stale inventory. Confirm the final ordering of metadata, route and profile changes to avoid requests reaching an unmanaged stopped instance. TLS ownership does not move to the proxy. The proxy is separate from any application-level Traefik inside the stack.

## Coverage and inventory metrics

Each usage page adds `coverage: {observed_from, observed_until, gaps, gaps_complete}` from the same SQLite snapshot as the journal. UTC watermarks describe first/last fully successful sweeps and are null before first success. Gaps contain `started_at`, nullable `ended_at`, and `reason`; at most 1000 are returned and truncation sets `gaps_complete: false`. Finish pagination before trusting coverage. Missing/null watermarks, observation beginning after an epoch, failed pages, overlapping gaps or `gaps_complete: false` hold billing; missing observations never imply measured zero.

| Gauge | Scope/meaning |
| --- | --- |
| `sleepy_stacks_stacks` | Proxy node container inventory in configured Incus project, excluding configured unlabeled reference instances |
| `sleepy_stacks_sleepy_stacks` | Enrolled sleepy instances in that project |
| `sleepy_stacks_awake_sleepy_stacks` | Sleepy instances whose Incus state is Running |
| `sleepy_stacks_inventory_success` | 0/1 success of latest inventory sweep |
| `sleepy_stacks_inventory_last_success_timestamp_seconds` | Last successful inventory timestamp |
| `total_number_of_stacks` | Master canonical fleet inventory, existing gauge |
| `total_number_of_sleepy_stacks` | Master canonical fleet sleepy inventory |
| `total_number_of_awake_sleepy_stacks` | Master awake sleepy fleet inventory |

These counts are gauges, not event counters; do not use counter `rate()` queries. Stopped sleepy instances are not awake; running maintenance instances are awake regardless of requests. Proxy emits no count series before the first successful sweep and retains last-good counts on failure. Gate dashboards on success and freshness rather than interpreting failure/staleness as zero. Master freshness gauges are `sleepy_stacks_collection_success` and `sleepy_stacks_collection_last_success_timestamp_seconds`. Node and fleet scopes are not additive independent inventories.

`SLEEPY_STACKS_INVENTORY_EXCLUDED_INSTANCES` defaults to `stackimage0`; it is an exact, case-sensitive comma-separated list replacing the default, with whitespace/empty entries ignored. An explicitly empty value disables exclusions. Nonempty effective `user.stack-id` overrides any name exclusion. VM instances are excluded. These exclusions affect inventory only, not routing/enrollment/lifecycle; ordinary unmarked administrative containers need explicit names to be excluded. Inventory is sampled after lifecycle actions.

## Acceptance matrix

| Area | Required acceptance evidence |
| --- | --- |
| Profiles | Missing flag means false; explicit sleepy works; normal-first picker; normal conversion removes all sleepy metadata and starts stopped runtime; retry is safe |
| Identity | Stack ID differs from billing ID/backend name; no cross-stack routing, metering or owner access; duplicate/missing IDs fail visibly |
| Proxy lifecycle | First HTTP request wakes and waits for readiness; concurrent requests do not cause duplicate starts; idle shutdown; active requests/streams/WebSockets survive; cancellation/start failure bounded |
| Maintenance | Enable returns UTC expiry 15 minutes ahead; both components agree on expiry; manual end; restart/expired/malformed metadata; no indefinite idle exemption |
| Journal/counters | Integer durations, durable identity/cursor, restart/replay/deduplication, pagination, gaps/reset/clock changes, outage completeness and persistent storage failure tests |
| Uptime | Today/month UTC totals; interval/bucket clipping; midnight/month rollover; requested ranges; incomplete data and errors; no inference of zero from failure |
| Admin | SPA graphs/totals and maintenance; API Ninja and MCP parity; ownership/company locks; normal-stack behavior; no new legacy UI |
| Routing | Correct node and trusted header; direct-header spoofing blocked; normal route preserved; metrics private; canary only on approved dev node |
| Billing design | Approved for dev only; new-policy enablement unverified; verify atomic debit/consumed-nanosecond rollback, replay/concurrency idempotency, reset/negative deltas, historical epoch rates, Decimal rounding carry, maintenance runtime, hourly maximum at multipliers 0/0.2/1, finite/range/six-decimal validation, editable sleepy profile field, unchanged applied snapshots and same-ID rejection, mid-hour profile/owner prorating, owner/stack/epoch minimum-checkpoint identity, cross-node hourly merge before maximum, integer ceiling once per bucket and Decimal credit carry, frozen legacy epochs without repricing, full-price extra disk with no-request hours and no separate included-storage charge, unchanged snapshot retention, non-consuming cumulative GET reads and atomic admin cursors/retention hours before passing the dev gate |
| Integration | Producer/consumer schema parity; each repository's appropriate tests/CI; reviewed migration/rollback; no production changes or charges |

Record exact test commands/results and remaining limitations from each owner. A green unit suite does not replace the dev canary, and this plan does not claim that acceptance has passed.

## Rollout gates and rollback

The coordinator reports that admin, LB, node and master main pipelines deploy only to dev; production uses release/manual workflows. Audit exact refs, tags, reusable workflows and registry/image promotion before pushing. Proxy production deployment is manual opt-in only, with no release trigger. Production remains disabled. The docs repository's `.github/workflows/main.yml` builds and deploys on pushes to `master`; the parent publishes the reviewed feature-only docs to default `master` and coordinates the original local default branch fast-forward with Pauli. This docs publication path does not authorize production feature rollout.

The parent completed read-only SSH preflight: `stack-node-dev-01` (`192.168.220.11`), x86_64 Debian 13.3, active vmapi, Incus project `default`, TCP port 80 free, no proxy service and no existing `user.stack-id` labels. No existing containers were touched. Subsequent parent reports confirm initial proxy/LB pipelines green and dev proxy active/enabled. Smoke uses an owned temporary project and separate database; existing dev stacks remain untouched. Subsequent hardened acceptance passed; final deployed heads are recorded below. Admin initially reported 31 Chromium tests green.

For the authorized dev canary after integration checks: capture existing routing/profile configuration, runtime state, image versions and journal identity; deploy compatible producers before consumers; keep production billing disabled and isolate any dev billing verification; enable only explicitly selected disposable sleepy stacks on `stack-node-dev-01`. Verify wake/readiness, maintenance/manual end/expiry, idle shutdown, UTC uptime, journal replay and rollback. Observe errors, request latency and counters. Do not expand to other nodes automatically.

For rollback, first stop assigning sleepy profiles. Coordinate normal-profile conversion, metadata removal, explicit startup and LB restoration while the proxy is still available; verify application health before stopping the proxy. Preserve journal/database, meter identity, accepted cursors and ledger history. Revert consumers before removing producer APIs. Never reset cursors or replay accounting mutations to hide errors. If conversion fails, keep the managed route available and reconcile the instance instead of shutting off its only wake path. Disable dev billing before rollback; production billing remains disabled. Rollback must use the sleepy-compatible verifier binary: disable sleepy/billing flags and convert profiles with that binary. Pre-feature binaries can reject the additive extension tables/seals; do not blindly roll back to an older image. Preserve the extension evidence and financial history rather than dropping tables to make an old binary start. PostgreSQL/SQLite extension DDL and seal commit together; interrupted unsealed MySQL DDL requires operator recovery and must not be automatically admitted.

User documentation: [Sleepy stacky](../docs/cs/stacks/sleepy.md). Availability is dev-only; production remains disabled.

## Historical dev acceptance and publication status

The following evidence concerns the prior storage policy, not acceptance of the new minimum policy. Its results do not establish current-policy test, CI or deployment status. Previously published storage-policy revisions are master `97bf834`, admin `4df69b52` and node `42eb85d`. Their last recorded CI status was in progress; no green CI or deployed-image verification is claimed here for those storage-policy revisions.

The coordinator reports the following completed validation for these revisions: master full Go suite passed; admin SQLite suite passed (127 tests, including one PostgreSQL-only skip), and all 47 sleepy tests separately passed on local PostgreSQL with no skips, including positive storage-charge concurrency coverage. Node full Go suite and race checks passed, along with isolated real-dev acceptance for stopped Btrfs containers, empty cache, sparse files and hard links. These are reported implementation results; this documentation follow-up did not rerun those suites.

Real hardened proxy acceptance passed: cold wake waited for TCP port 80 and returned the original HTTP response; idle shutdown worked; maintenance prevented shutdown and expired/cleared; removal of `user.stack-id` preserved a normal running instance and re-addition re-enrolled it; three requests persisted with nonempty durable journal and coverage. Node real acceptance included a 1/1/1 gauge fixture. All disposable and earlier manual test projects, transient services, separate databases and profile canaries are cleaned up; existing dev stacks were untouched.

Master dev extension apply and verification both exited 0. Master/admin/rq/rq-admin rollouts are ready. Billing configuration is enabled only in rosti-dev (master flag true, common `SLEEPY_BILLING_ENABLED=1`). Admin read-through-master validation returned 1 billing owner and 18 rows without issuing Wallet charges. Both live master fleet and proxy node gauges report 18 total, 0 sleepy and 0 awake sleepy after reference-image exclusion.

Earlier verified green code heads (before the storage-pricing follow-up) were: master `a0ae0db` ([CI 366](https://git.ceperka.net/Rosti/vm-master-api/actions/runs/366)), admin `b92d595f` ([CI 1281](https://git.ceperka.net/Rosti/admin/actions/runs/1281)), node `527dfe1` ([CI 318](https://git.ceperka.net/Rosti/vm-api/actions/runs/318)), proxy `bc66832` ([CI 5](https://git.ceperka.net/Rosti/sleepy-stacks-proxy/actions/runs/5)) and LB `0a25901` ([CI 127](https://git.ceperka.net/Rosti/lbservice/actions/runs/127)). This includes the setup guard and admin refresh callback, with no API change or SQL model/seal change in the final master helper. The coordinator verified exact dev images: master `a0ae0db` and admin/rq/rq-admin `b92d595f`. All workloads are Ready (1/1; rq has 3 ready replicas). Proxy `bc66832` is enabled/active with gauges 18/0/0; node lease implementation `527dfe1` is active. No production workload was changed.

Master management UI Sleepy create/edit checkbox is tested using real JavaScript. Applied `stack.sleepy` remains authoritative; profile catalog changes do not mutate existing stacks. The SPA **Do maintenance** action starts a stopped stack and prevents idle shutdown for 15 minutes. Uptime is in **Metrics** and uses its selected range.

Parent published docs default `master` at `88589b0`; GitHub [build/deploy 41141098455](https://github.com/rosti-cz/docs/actions/runs/41141098455) succeeded. Subsequent documentation updates use the same default-branch build/deploy workflow. Docs publication is not production feature activation. No production release, migration, configuration change or workload deployment was performed.

## Initial sleepy provisioning lease

New sleepy creation installs an initial 15-minute node maintenance lease before boot. During active Setup, master renews it every 5 minutes; each renewal request has a 30-second timeout and the setup guard has an overall 30-minute maximum. Protection spans runtime readiness, initial Compose pull/up and initial LB setup, preventing idle shutdown during long provisioning. Normal stack provisioning is unchanged.

On failure the renewal worker is cancelled and joined before cleanup. On success the worker is also joined and the setup lease is cleared before phase Ready. Manual maintenance changes are blocked while setup is pending. Crashes cannot leave an infinite exemption: the last persisted 15-minute lease expires without further renewal. These provisioning leases are separate from the user's ordinary maintenance action. Both node and master setup-guard heads are published with green CI and their exact deployed dev images are verified; normal provisioning remains unchanged.
