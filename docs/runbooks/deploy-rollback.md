# Deploy rollback
**When:** spikes in errors/latency after a deploy.

## Steps
1. Identify last good image tag (CI/ECR).
2. `scripts/rollback_to_sha.sh <sha>`
3. Watch App Runner until **RUNNING**.
4. Verify: `/health` + CRUD.
5. Communicate: status, link reverted commit, open fix issue.

## Verify
- CloudWatch: error/latency normalize.
- Canary: next run green.
