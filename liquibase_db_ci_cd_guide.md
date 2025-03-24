# DB CI/CD with Liquibase: Snapshots, Diffing, and Automation
*Generated on 2025-03-21*

---

## 1. Track Database Changes with `DATABASECHANGELOG`

- Every Liquibase ChangeSet applied is recorded in the `DATABASECHANGELOG` table.
- You can query this table to see what was applied and when:

```sql
SELECT id, author, fileName, dateexecuted
FROM DATABASECHANGELOG
ORDER BY dateexecuted DESC;
```

## 2. Snapshot Database Schema After Each Release

Use Liquibase's snapshot feature to capture the current database structure:

```bash
liquibase snapshot \
  --url=jdbc:postgresql://dbhost:5432/mydb \
  --username=postgres \
  --password=admin \
  --snapshotFormat=json \
  --outputFile=snapshots/schema_after_release.json
```

- Store this file in Git or upload it to cloud storage (e.g., AWS S3).
- Use these snapshots to compare schema changes across releases.

## 3. Compare Schema Between Releases

Use `diff` to compare two snapshots or a snapshot vs. live DB:

```bash
liquibase diff \
  --snapshot=snapshots/schema_after_previous_release.json \
  --url=jdbc:postgresql://dbhost:5432/mydb \
  --username=postgres \
  --password=admin
```

Or generate a changelog for the diff:

```bash
liquibase diffChangeLog \
  --referenceUrl=... \
  --url=... \
  --changeLogFile=changes_between_releases.xml
```

## 4. Automate in CI/CD Pipeline

### GitHub Actions Sample

```yaml
name: Check DB Structural Changes

on:
  push:
    branches: [ "main" ]

jobs:
  liquibase-diff:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-java@v3
        with:
          java-version: '11'

      - name: Install Liquibase
        run: |
          wget https://github.com/liquibase/liquibase/releases/latest/download/liquibase.zip
          unzip liquibase.zip -d liquibase
          sudo mv liquibase /usr/local/bin/liquibase

      - name: Compare Schema
        run: |
          liquibase diff \
            --snapshot=snapshots/schema_after_previous_release.json \
            --url=jdbc:postgresql://dbhost:5432/mydb \
            --username=${ secrets.DB_USER } \
            --password=${ secrets.DB_PASS }

      - name: Snapshot After Release
        run: |
          liquibase snapshot \
            --url=jdbc:postgresql://dbhost:5432/mydb \
            --username=${ secrets.DB_USER } \
            --password=${ secrets.DB_PASS } \
            --snapshotFormat=json \
            --outputFile=snapshots/schema_after_release.json

      - name: Commit Snapshot
        run: |
          git add snapshots/schema_after_release.json
          git commit -m "Snapshot after release"
          git push origin main
```

## 5. Structural Change Alerting

Use the output of `diff` to trigger alerting via Slack or Email if differences are detected.

## 6. Summary

| Step | Action |
|------|--------|
| 1️⃣  | Track applied changes in `DATABASECHANGELOG` |
| 2️⃣  | Take snapshot after each release |
| 3️⃣  | Use `diff` to compare schema versions |
| 4️⃣  | Automate via CI/CD |
| 5️⃣  | Alert on structural differences |

