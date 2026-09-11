# Appservice Migration: Operator Notice

This is preparation only. No production migration or deployment is authorized.
The admin implementation and full rehearsal/handoff instructions are in the
admin repository at `docs/appservice-migration.md`. The shared service contract
is in node-api at `docs/appservice-contract.md`.

Keep `APP_MANAGEMENT_BACKEND=legacy`. The current admin build deliberately refuses
to initialize in `appservice` mode because legacy forms/DRF, many user actions,
terminal, snapshots, automation and legacy writer paths are not fully converted.
Core Ninja/MCP CRUD, catalogs, legacy read pages and billing branches are preparation, not a completed
cutover. Configuring an undeployed upstream while retaining legacy mode is safe.

Before any final export, import or adoption, freeze all legacy management writers,
in-flight jobs, queued retries, scheduled LB reconciliation, cron/killer/cleanup,
node v1 processing, webhooks and manual operations. Freeze the old app debit loop
at a recorded hour. A new admin setting does not stop old processes. Import must
be inactive and read-only with respect to nodes until explicit adoption.

Preserve numeric app IDs, the actual legacy sequence high-water mark, runtime/LB
names, HTTP, node SSH, public SSH and terminal ports, secrets, FTP/GitHub/SMTP,
snapshot metadata and tombstones. Do not recreate containers during adoption or
drop the legacy databases. Docker's restart policy remains `unless-stopped`.

Migration must preserve effective legacy hourly prices. Legacy admin divides
monthly app credits by **732 hours**, not 720, even where customer-facing monthly
descriptions refer to 30 days. This is a preservation requirement, not permission
to change public prices. Stopped storage charges and the legacy extra-disk GiB
rounding boundary must also remain unchanged. Admin applies discounts and wallet
conversion exactly once; appservice `/billing` returns additive hourly amounts.

Admin's additive interval ledger deduplicates appservice charges by UTC hour and
backend, including overlapping multiply periods. It commits with wallet deductions
and does not deduplicate legacy app, VM or mailbox charges. Use an explicit aware
`--appservice-hour` when rehearsing a billing boundary; current inventory is not a
historical billing snapshot.

Admin also retains durable create/update/delete apply intents. PUT only stores
desired configuration; rebuild or route synchronization is queued explicitly.
A lost PUT remains unresolved and must be reviewed, never automatically replayed.
The full admin runbook documents reconciliation and `--confirm-put-applied`.

Export manifests contain secrets. Use the admin `export_appservice` command's
0600 atomic file output in an access-controlled directory, never stdout or Git.
Dry-run validates without writing. Supplied node inventories are trusted operator
inputs and do not replace actual node adoption verification.

Local contract checks are available in appservice's `integration/` nested Go
module and admin's opt-in `tests.test_appservice_integration` suite. The latter
uses `APPSERVICE_TEST_BINARY` and verifies an actual admin export/import against
a temporary local appservice, with workers disabled and synthetic node inventory.
These tests do not authorize a production handoff.

No fallback to legacy writes is allowed on an appservice outage. Post-adoption
rollback requires an explicit reverse ownership, port and billing handoff, not
just starting the old admin again. Consult the full admin runbook's activation
blocker list before proposing a rollout date.
