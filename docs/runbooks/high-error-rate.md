# High error rate
**Signal:** `apprunner-error-burn-fast` or `apprunner-error-burn-slow` ALARM.

## Triage
- Logs: sample 5xx traces, note paths/request ids.
- Check last deploy; DB health.

## Actions
- Post-deploy? → rollback.
- 4xx-only? → client changes, CORS/rate limiting.
- Infra? → DB creds/limits/network.

## Exit
- Error rate < threshold for two windows.
