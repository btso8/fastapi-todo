# DB outage / connectivity
**Signal:** bursts of 5xx with DB errors.

## Triage
- App logs: connection errors/timeouts.
- DB status: endpoint, creds, limits, SG rules.

## Actions
- Ensure /health reflects DB readiness.
- Restore DB / rotate secrets.
- Redeploy if needed to pick up secrets.

## Exit
- Health 200; error rate normalized.
