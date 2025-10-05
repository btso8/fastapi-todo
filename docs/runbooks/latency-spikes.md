# Latency spike (p90)
**Signal:** Alarm `apprunner-latency-p90-high`.

## Triage
- Dashboard: CPU/Mem, Concurrency, ActiveInstances.
- Logs: slow endpoints (path, DB timings if logged).

## Actions
- Scale up (if constrained) or reduce load temporarily.
- Check DB: indices, locks, slow queries.
- Rollback if tied to a deploy.

## Done when
- p90 under target (e.g., ≤300 ms) for 3 periods.
