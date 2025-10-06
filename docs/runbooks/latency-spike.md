# Latency spike
**Signal:** `apprunner-latency-p90-high` ALARM.

## Triage
- Dashboard: CPU/Mem/Concurrency/ActiveInstances/RequestLatency p90.
- Logs: slow endpoints; DB timings if logged.

## Actions
- Scale / reduce load temporarily.
- DB: indices, locks, slow queries.
- Rollback if linked to deploy.

## Exit
- p90 <= target for two windows.
