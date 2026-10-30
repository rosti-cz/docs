# Sleepy stacks: implementation and acceptance plan

Status: coordinated implementation, 2026-10-30. Production activation and deployment are disabled. The user approved the per-second billing design. Implementation is tested and active on dev only; billing flags are enabled only in rosti-dev. Production remains disabled. This document records agreed contracts separately from pending implementation verification. The user has authorized eventual main-branch pushes and proxy deployment to `stack-node-dev-01`. Dev rollout and real acceptance are complete for the previously deployed heads; final setup-guard head publication/CI and admin UI refresh follow-up remain pending; this agent does not push or deploy.

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

Profile JSON has `sleepy: boolean`, defaulting to `false` when absent. The applied runtime field `stack.sleepy` is authoritative. Editing the profile catalog does not silently change existing stacks, consistent with existing resource/rate application. Create a separate sleepy profile and explicitly choose/apply the target profile for conversion; never infer applied mode from mutable catalog data. Master management UI supports the Sleepy checkbox on profile create/edit (`f607cb3`, real-JavaScript tested); admin alignment is `ff4509c3`. Normal profiles appear before sleepy profiles in pickers. No existing profile becomes sleepy implicitly.

Sleepy Incus instances use `user.stack-id` equal to the canonical vm-master-api stack ID. Never substitute `billing_id`, container/backend name or display name. `user.stack-maintenance` is `"1"` only during active maintenance. The shared expiry is `user.stack-maintenance-until`, RFC3339 in UTC, with a 15-minute window. Manual end removes maintenance state. Expired maintenance must stop suppressing idle shutdown even if the writer is unavailable. The proxy persists a fresh 15-minute expiry when an active flag has missing or malformed expiry. On expiry it clears local maintenance values, masking inherited settings. Persistence failures surface as errors; verify retry behavior in integration.

Applying a normal profile removes all sleepy metadata, including stack ID, maintenance flag and expiry, and starts a stopped container. Profile application must reconcile existing state, not only newly created instances. Tests must cover profile changes while stopped and while in maintenance.

### Master API

These owner-scoped paths are agreed; implementation and OpenAPI parity still require verification:

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

## Per-second billing design — approved, enabled only on dev

The user approved prorating the existing hourly compute price by measured runtime, including runtime during maintenance. This introduces no new rate values. Only existing extra disk usage above the included allowance and snapshots retain existing wall-hour policies, including while asleep. There is no new separate price for included disk. Normal profiles retain existing hourly sampling; per-second charging applies only to sleepy runtime epochs. Production rollout remains forbidden. Implementation is tested and the dev billing gates are enabled; production flags and charges remain untouched. Read-only validation is not a Wallet debit test.

The parent is coordinating cumulative integer runtime snapshots identified by `(stack, node, meter, rate_epoch)`. Admin atomically records consumed nanoseconds and the corresponding debit in one database transaction. Charge only positive, unseen runtime deltas; retries, concurrent workers and delayed delivery must not charge twice. Failed transactions advance neither consumed runtime nor ledger state. Journal ingestion cursors remain distinct from billing's consumed cumulative nanoseconds.

Profile/rate changes require explicit rate epochs with their applicable historical rates. Attribute runtime to its epoch rather than charging an old sample at the current rate. Use Decimal arithmetic and persist rounding carry so repeated small deltas do not lose precision or inflate charges. Exact snapshot fields, epoch creation/transition rules, carry precision and transaction/idempotency schema remain pending the producing agents' contracts.

Missing/reset meters, negative deltas and unknown epochs require reconciliation and visible incompleteness, with no fabricated usage. Preserve durable meter identity across restarts and recognize a replacement meter explicitly. Timestamped journal intervals support historical graphs; reconciliation into authoritative cumulative counters must preserve identity and exactly-once acceptance. Monitoring graphs alone are not an accounting source.

Historical sleepy compute settles once after normal conversion, deletion or owner transfer using retained historical epochs and terminal settlements. Terminal rows settle compute only; active normal rows settle historical sleepy compute alongside unchanged normal hourly sampling. Journal ingestion cursors and consumed cumulative runtime are distinct.

Company account closure has an explicit compatibility limit: financial checkpoints protect company audit references with `PROTECT` foreign keys. `CompanyProcessor.close` preflights for sleepy financial history before any external cleanup and returns an explicit error when such history exists. This avoids partial external cleanup followed by a foreign-key failure. Closing these company accounts requires a future archival/final-settlement workflow; financial audit history must not silently cascade away. This guard does not restrict supported stack deletion, profile changes or owner transfers, which use retained epochs and terminal settlements. Changing the future retention/closure policy requires its own review; implementing the guard does not require renewed approval. Production remains untouched.

Admin opt-in is `SLEEPY_BILLING_ENABLED=1`, default `0`. Migration `0135_sleepy_billing` depends on `0134`. Master explicitly runs `vm-master-api migration sleepy-apply` to extend sealed schema 2; no automatic production apply. `GET /v2/admin/stack-billing-owners` is service-only owner discovery. Exact cumulative snapshot/epoch and Decimal carry schemas still await final agents' contracts.

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

These counts are gauges, not event counters; do not use counter `rate()` queries. Stopped sleepy instances are not awake; running maintenance instances are awake regardless of requests. Proxy emits no count series before the first successful sweep and retains last-good counts on failure. Gate dashboards on success and freshness rather than interpreting failure/staleness as zero. Master success/freshness metric names remain pending confirmation. Node and fleet scopes are not additive independent inventories.

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
| Billing design | Approved and dev-enabled only; verify atomic debit/consumed-nanosecond rollback, replay/concurrency idempotency, reset/negative deltas, historical epoch rates, Decimal rounding carry, maintenance runtime and wall-time disk/snapshot policy before passing the dev gate |
| Integration | Producer/consumer schema parity; each repository's appropriate tests/CI; reviewed migration/rollback; no production changes or charges |

Record exact test commands/results and remaining limitations from each owner. A green unit suite does not replace the dev canary, and this plan does not claim that acceptance has passed.

## Rollout gates and rollback

The coordinator reports that admin, LB, node and master main pipelines deploy only to dev; production uses release/manual workflows. Audit exact refs, tags, reusable workflows and registry/image promotion before pushing. The proposed proxy production workflow is manual opt-in only, with no release trigger; its final YAML still needs review. The docs repository's `.github/workflows/main.yml` builds and deploys on pushes to `master`; the parent will inspect the docs remote/default branch before the authorized main-branch integration push. This docs publication path does not authorize production feature rollout.

The parent completed read-only SSH preflight: `stack-node-dev-01` (`192.168.220.11`), x86_64 Debian 13.3, active vmapi, Incus project `default`, TCP port 80 free, no proxy service and no existing `user.stack-id` labels. No existing containers were touched. Subsequent parent reports confirm initial proxy/LB pipelines green and dev proxy active/enabled. Smoke uses an owned temporary project and separate database; existing dev stacks remain untouched. Subsequent hardened acceptance passed; current final-head limitations are recorded below. Admin initially reported 31 Chromium tests green.

For the authorized dev canary after integration checks: capture existing routing/profile configuration, runtime state, image versions and journal identity; deploy compatible producers before consumers; keep production billing disabled and isolate any dev billing verification; enable only explicitly selected disposable sleepy stacks on `stack-node-dev-01`. Verify wake/readiness, maintenance/manual end/expiry, idle shutdown, UTC uptime, journal replay and rollback. Observe errors, request latency and counters. Do not expand to other nodes automatically.

For rollback, first stop assigning sleepy profiles. Coordinate normal-profile conversion, metadata removal, explicit startup and LB restoration while the proxy is still available; verify application health before stopping the proxy. Preserve journal/database, meter identity, accepted cursors and ledger history. Revert consumers before removing producer APIs. Never reset cursors or replay accounting mutations to hide errors. If conversion fails, keep the managed route available and reconcile the instance instead of shutting off its only wake path. Disable dev billing before rollback; production billing remains disabled.

## Coordinator handoff: open dependencies

- Nash: final README/unit parity with the environment and journal contracts above, durability/retention, maintenance edge cases and tests.
- Wegener: exact sleepy metadata inventory and reconciliation behavior, normal-profile recovery and retry evidence.
- Herschel: OpenAPI and final uptime precision/boundaries/completeness, journal ingestion and deduplication evidence.
- Aquinas: final billing schema and backend results, picker behavior/graph labels and explicit dev-only charging boundary and approved billing implementation contracts.
- Hypatia: routing configuration names, trusted-header enforcement and node transition/rollback evidence.
- Parent: verified deployment audit, authorized dev canary result, integration order and final billing snapshot/epoch contracts and dev-gate evidence. Replace provisional sections only after these contracts are received.

User documentation draft: [Sleepy stacky](../docs/cs/stacks/sleepy.md). It intentionally describes planned behavior and does not announce availability.

## Current dev acceptance and publication status

Real hardened proxy acceptance passed: cold wake waited for TCP port 80 and returned the original HTTP response; idle shutdown worked; maintenance prevented shutdown and expired/cleared; removal of `user.stack-id` preserved a normal running instance and re-addition re-enrolled it; three requests persisted with nonempty durable journal and coverage. Node real acceptance included a 1/1/1 gauge fixture. All disposable and earlier manual test projects, transient services, separate databases and profile canaries are cleaned up; existing dev stacks were untouched.

Master dev extension apply and verification both exited 0. Master/admin/rq/rq-admin rollouts are ready. Billing configuration is enabled only in rosti-dev (master flag true, common `SLEEPY_BILLING_ENABLED=1`). Parent read-only validation uses 18 canonical stacks and does not issue Wallet charges. Both live master fleet and proxy node gauges report 18 total, 0 sleepy and 0 awake sleepy after reference-image exclusion.

Confirmed successful CI heads: master `f607cb3` pipeline 365, admin `ff4509c3` pipeline 1280, node `b86113f` pipeline 317, LB `0a` pipeline 127. Provisioning node follow-up `527` is deployed with pipeline 318 successful. Proxy `bc668` pipeline 5 was pending at the last supplied check. Master setup-guard `a0ae0db` (parent `f607cb3`) passed full Go, race and management UI tests without SQL model/seal changes; its push is awaiting parent automatic review, so final-head publication/CI is not claimed. Admin UI refresh callback follow-up remains under test with no API change.

Master management UI Sleepy create/edit checkbox is tested using real JavaScript. Applied `stack.sleepy` remains authoritative; profile catalog changes do not mutate existing stacks. The SPA **Do maintenance** action starts a stopped stack and prevents idle shutdown for 15 minutes. Uptime is in **Metrics** and uses its selected range.

Parent published docs default `master` at `e09b829`; GitHub build/deploy `41135725607` succeeded. These later corrections are local for parent publication after final head/CI checks. Docs publication is not production feature activation. No production release, migration, configuration change or workload deployment was performed.

## Initial sleepy provisioning lease

New sleepy creation installs an initial 15-minute node maintenance lease before boot. During active Setup, master renews it every 5 minutes; each renewal request has a 30-second timeout and the setup guard has an overall 30-minute maximum. Protection spans runtime readiness, initial Compose pull/up and initial LB setup, preventing idle shutdown during long provisioning. Normal stack provisioning is unchanged.

On failure the renewal worker is cancelled and joined before cleanup. On success the worker is also joined and the setup lease is cleared before phase Ready. Manual maintenance changes are blocked while setup is pending. Crashes cannot leave an infinite exemption: the last persisted 15-minute lease expires without further renewal. These provisioning leases are separate from the user's ordinary maintenance action. The node follow-up is deployed; the master helper has passed its tests and awaits parent publication/final CI.
