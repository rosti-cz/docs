# Admin credit deduction monitoring

Admin migration `0141_billing_monitoring` installs persistent billing-attempt
history and a UTC monitoring baseline. The baseline is the next full UTC hour
after migration, avoiding a false missed-hour alert during deployment. Earlier
billing history is not reconstructed. This monitoring is independent of optional
product cohort collection and does not alter prices or add automatic retries.

The hourly `subtract_credit` command calls the shared monitoring processor. Each
attempt is recorded before billing. Financial changes and the success marker
commit in one transaction; on failure the financial changes roll back and a
failure marker is saved separately. Abrupt process termination may leave a
`running` attempt; missing-slot and freshness alerts still detect that condition.
If the database itself is unavailable, the failure marker may also be unavailable.

The existing staff-authenticated `/api/metrics` endpoint exposes:

| Metric | Meaning |
| --- | --- |
| `admin_billing_initialized` | Monitoring baseline exists |
| `admin_billing_first_slot_timestamp_seconds` | First monitored UTC slot |
| `admin_billing_last_success_timestamp_seconds` | Last committed scheduled completion |
| `admin_billing_last_start_timestamp_seconds` | Latest scheduled attempt start |
| `admin_billing_last_run_duration_seconds` | Latest scheduled attempt duration; zero while running |
| `admin_billing_last_run_failed` | Latest scheduled attempt failed |
| `admin_billing_unsettled_hours` | Due slots without a committed scheduled run |
| `admin_billing_attempts{status}` | Persisted scheduled attempts by status |
| `admin_billing_failures_total{reason}` | Durable failure count by bounded reason |
| `admin_billing_last_success_credits{service}` | Positive credits deducted in the latest committed scheduled run |
| `admin_billing_last_success_resources{service}` | Resource rows processed after account/trial exemptions in that run |
| `admin_stats_collection_success` | Existing inventory/income collection succeeded |

Service labels are `app`, `normal_stack`, `sleepy_stack`, and `mailbox`. Counts
include zero-cost processed rows. Historical sleepy settlement rows may be
included; a converted normal stack may include historical sleepy charges in its
normal-stack total. No tenant IDs, resource IDs or exception messages are labels.
Charge/resource gauges describe the last successful run, not cumulative or daily
totals. Failure reasons are `stack_billing_unavailable`, `service_unavailable`,
`accounting_conflict`, `database_unavailable`, and `unexpected`.

The CronJob runs at :05. Slots become overdue at :20 UTC, allowing fifteen minutes
of scheduling/execution grace. Distinct successful slots are counted, so duplicate
attempts cannot erase unrelated missing hours. A later success does not clear an
earlier gap. Runs with `--multiply` other than one are manual and do not settle
scheduled slots. Keep the baseline and attempt history; deleting them changes gap
counts and resets counters.

If upstream inventory collection fails, Admin still exports database-backed
billing metrics and `admin_stats_collection_success 0`. It omits unavailable
inventory/income samples rather than reporting zero. Failure of the database or
the endpoint itself is covered by the scrape alert.

Underhood contains `config/9091/rules_admin.yml`, `tests/alert_admin.test.yml`,
`dashboards/admin-metrics.json`, and `docs/admin-metrics.md`. Alerts cover a failed
latest run, missed slots, billing freshness (75-minute warning/two-hour critical),
scrape failures, missing instrumentation, and failed inventory collection. The
dashboard also includes existing Admin inventory, income, and wallet metrics.
It uses the existing production scrape target; no development scrape credentials
or live deployment are added by this change.

Deploy Admin code/migration before the new monitoring rules. Confirm a real
scheduled run and its ledger/checkpoints, then inspect the dashboard and alerts.
Do not blindly replay full deductions or use `--multiply` as recovery. Normal
charges are not universally idempotent, while sleepy cumulative accounting may
already include late usage. Missing-hour recovery requires a separate audited
reconciliation; this change adds no recovery or waiver endpoint.
