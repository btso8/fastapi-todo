# DB outage / connectivity
**Signal:** 5xx bursts with DB errors.

## Triage
- App logs for connection errors.
- DB status/endpoint, creds, security groups.

## Actions
- Fail closed: ensure health endpoint reflects DB readiness.
- Restore DB / rotate creds.
- Redeploy if needed to pick up new secrets.

## Done when
- Health 200; errors back to baseline; latency normal.
