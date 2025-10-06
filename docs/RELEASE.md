# Release Checklist

1) CI green (tests, Security Scan).
2) Canary green; dashboards nominal.
3) Tag a release (`vX.Y.Z`) → SBOM auto-attached.
4) Monitor 30–60 min (alarms, canary).
5) Rollback if needed: `scripts/rollback_to_sha.sh <sha>` (App Runner auto-deploys `:latest`).
