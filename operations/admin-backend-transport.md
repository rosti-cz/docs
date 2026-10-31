# Admin backend transport and DEV rollouts

## Evidence collected 2026-10-31

Read-only Kubernetes inspection used explicit context `rosti-dev` and namespace
`rosti-dev`. MASTER image `23ce5fb` had one replica and strategy `Recreate`,
startup/readiness HTTP probes on `/readiness:8000`, and a liveness probe on
`/healthcheck:8000`. The current pod had zero restarts and a ready EndpointSlice.
Deployment events showed four replacements. Most recently the old ReplicaSet
scaled down at 00:21:12 UTC; the replacement became Ready at 00:21:19 UTC.
Current pod logs had no panic/fatal indicators. The traceback includes a Requests
start timestamp of `1793406076.955999`, which converts to
`2026-10-31T00:21:16.955999Z`: inside that seven-second replacement gap. This
correlates the reported connection refusal with the rollout, rather than an
ongoing process crash.

Readiness removes unready pods from routing but cannot provide an endpoint
while a single-replica Recreate replacement is starting. The DEV deployment
script now installs schema-gated startup/readiness probes and rejects any
context except `rosti-dev`. It preserves replicas and strategy. Concurrent
serving safety has not been established; do not switch to surge solely to
hide transport errors. Each serving process starts a metrics gatherer and
usage ingestion has transaction locks, but those facts are not a complete
multi-process writer/job safety assessment.

## Transport behavior

Base client requests receive connect/idle-read timeouts of 3.05/60 seconds.
All existing explicit timeout overrides retain their meaning; writes now accept
an explicit `timeout` keyword too. These are socket phase limits, not an overall
wall-clock deadline or a guarantee about DNS resolution/slow streaming.

Only verified `/profiles`, `/v2/profiles` and numeric profile-detail GETs are
eligible for connection establishment retries. There are at most five attempts,
with 0.5, 1, 2 and 4 seconds of backoff (7.5 seconds total). No HTTP status or
read timeout is retried, including body read timeouts wrapped in ConnectionError.
Unknown GETs and legacy action/token GETs are single-attempt. POST, PATCH, PUT
and DELETE are never retried. Exhaustion becomes a safe ClientException with
HTTP 503 through the existing API handler and a controlled MCP tool error.
Actual upstream status/validation errors remain unchanged. No empty catalog or
financial-data fallback is fabricated.

Sentry frame locals are disabled centrally. Credential-bearing transport frames
are marked sensitive for Django reports. Tests use synthetic credentials only.

## Long-running operations

`StackAPIClient.do_stack_action` passes `(3.05, 1920)` for synchronous Pull+Up,
preserving its 30-minute execution budget plus cleanup/final persistence. Other
actions retain the bounded default. Do not replay an action after a read timeout
without first checking its outcome. Prefer the asynchronous Pull+Up job endpoint
for deployment automation.

Production remains unchanged. The probes are enforced by the DEV deployment
script; deployment and CI verification use the explicit `rosti-dev` context.
