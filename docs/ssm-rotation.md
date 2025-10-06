# Parameter Rotation — /todo/prod/DATABASE_URL
- Store: SSM Parameter Store (SecureString)
- Key: aws/ssm (or CMK)
- Cadence: quarterly or on incident

## Steps
1) `aws ssm put-parameter --name "/todo/prod/DATABASE_URL" --type SecureString --value "<new-url>" --overwrite`
2) Update the **RDS user password** to match the new value.
3) Restart App Runner service (or deploy) so new value is fetched.
4) Verify `/health` + DB query route.
5) Remove old DB credentials; note change in CHANGELOG.

## Evidence
- SSM parameter history screenshot (shows versions).
- App Runner deploy event after rotation.
