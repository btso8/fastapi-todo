# Deploy rollback
**When to use:** spike in errors/latency right after a deploy.

## Steps
1) Identify last good SHA in ECR (or from CI).
2) Run: `scripts/rollback_to_sha.sh <sha>`
3) Watch App Runner: Service → Events/Status until **RUNNING**.
4) Verify: `/health`, a couple of CRUD calls.
5) Close the loop: post status + create a bug for the bad release.

## Verification
- CloudWatch: errors normalize, latency back under p90 target.
- GitHub: comment the SHA you rolled back to.
