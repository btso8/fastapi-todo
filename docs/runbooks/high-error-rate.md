# High error rate (4xx/5xx)
**Signal:** Alarm `apprunner-error-rate-high`.

## Triage
- CloudWatch → Logs: sample 5xx stack traces.
- Check recent deploy (CI) and DB status.

## Actions
- If after deploy → **rollback** (see runbook).
- If DB/network → restart connection pool, check creds/limits.
- If 4xx spike only → check client changes/rate limiting.

## Done when
- Error rate < SLO budget (e.g., <1% for 3 consecutive periods).
