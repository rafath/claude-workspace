# Staging Flow

## Overview

Merge deployable code into the staging branch and deploy via Kamal.

## Sequence

1. **Check state**: `dev-deploy stage --check` — shows how many commits need merging
2. **Stage**: `dev-deploy stage` — merges source into staging branch, pushes to origin
3. **Optional DB refresh**: `dev-deploy deploy staging --refresh-db` — refreshes staging DB from production before deploying
4. **Deploy**: `dev-deploy deploy staging` — pulls latest staging, runs pre_deploy hook, deploys via Kamal, runs post_deploy hook

## Remote Pattern (Fork Repos)

Source is a mirror branch pushed from a fork via `dev-workspace deploy push`:

```
fork repo → dev-workspace deploy push → mirror branch (origin/command-mirror)
         → dev-deploy stage → merges mirror into staging
         → dev-deploy deploy staging → kamal deploy -d staging
```

The `stage` command fetches the remote branch configured in `source.remote` before merging.

## Local Pattern (Vanilla Repos)

Source is a branch in the same repo (usually `main`):

```
main branch → dev-deploy stage → merges main into staging
           → dev-deploy deploy staging → kamal deploy -d staging
```

No fetch needed — direct merge from local branch.

## Merge Conflicts

If `dev-deploy stage` hits a merge conflict, it will fail with git's conflict output. Resolve manually:

1. Fix conflicted files
2. `git add` resolved files
3. `git commit`
4. `git push origin staging`

Then continue with `dev-deploy deploy staging`.

## Safety

- Always `--check` before staging to see what's coming in
- The staging merge uses the strategy configured in `staging.merge_strategy` (default: `--no-edit`)
- Staging deploy is isolated from production — safe to test migrations, new features
- DB refresh is opt-in (`--refresh-db`), never automatic
