# Disaster Recovery Plan

## Objectives
- **RTO:** <e.g., 60 min>
- **RPO:** <e.g., 15 min>

## What we operate
- **App:** FastAPI (App Runner), auto-deploys `:latest` from ECR.
- **Image:** ECR repo `btso8/fastapi-todo` (tags: latest + short SHA).
- **DB:** <Postgres RDS | SQLite>. See the correct section below.
- **Secrets:** AWS Secrets Manager (e.g., `DATABASE_URL`).
- **Monitoring:** CloudWatch alarms (error rate, p90 latency, 5xx burst); canary every 10 min.
- **Rollback:** `scripts/rollback_to_sha.sh <sha>` retags ECR `latest` to a known good image.

---

## DR Scenario A: Postgres (RDS)

### PITR Drill
1. Choose restore time (UTC).
2. Run: `scripts/rds_pitr.sh <source_id> <new_id> <UTC|latest> [region]`.
3. Create a temporary secret `DATABASE_URL_DR` for the new endpoint DSN:
   `postgresql+psycopg://<user>:<pass>@<ep>:<port>/<db>?sslmode=require`
4. Switch app to the DR DB:
   - Staging: run locally against DR DSN, or
   - Prod: update App Runner env to use the DR secret and redeploy.
5. Verify: `/health` 200, CRUD works, canary green, p95 under target.
6. Switch back to primary; delete DR instance.
7. Record actual RTO/RPO and findings.

---

## DR Scenario B: SQLite

### Restore Drill
1. Nightly backups via `scripts/sqlite_backup.sh` → S3.
2. Restore: `scripts/sqlite_restore.sh <s3_key> <dest> <bucket>`.
3. Run app locally: `DATABASE_URL=sqlite:///./dev_restored.db uvicorn app.main:app`.
4. Verify; note duration and data age.

---

## Evidence
- Screenshot: RDS DR instance `available` (or restored SQLite file).
- `/health` + CRUD successful.
- Canary green; alarms OK.
- RTO/RPO results logged.
