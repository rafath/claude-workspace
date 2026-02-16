# Sync — Syncing Branches

There are three separate sync-related commands. Each serves a different purpose.

## dev-workspace sync — Feature Branch Sync

Pulls parent branch changes into the current feature branch.

### Workflow
```
dev-workspace sync --check               # How far behind parent?
dev-workspace sync                       # Merge parent into feature branch
dev-workspace sync --rebase              # Rebase onto parent (cleaner history)
```

### When to Sync
- Before merging — ensures no conflicts with parent
- After parent gets new commits you need in your feature branch
- Periodically on long-running branches to avoid large merge conflicts later

### Merge vs Rebase
- **Merge** (default): Creates a merge commit. History shows when sync happened. No force push needed.
- **Rebase** (`--rebase`): Replays your commits on top of parent. Cleaner linear history. Requires `dev-workspace push --force-w-l` afterwards because commit hashes change.

### Conflict Handling
If conflicts occur during sync, the command outputs the conflicting files. The agent should:
1. Report the conflicts to the user
2. Help resolve them if asked
3. Complete the merge/rebase after resolution

---

## dev-workspace latest — Main Branch Reset

Resets the local main branch to match a remote exactly. **This is a destructive operation.**

### Workflow (fork repos)
```
dev-workspace latest --check             # Compare local main with origin AND upstream
dev-workspace latest --upstream          # Reset local main to upstream (original repo)
dev-workspace latest --origin            # Reset local main to origin (your fork)
```

### Workflow (vanilla repos)
```
dev-workspace latest --check             # Compare local main with origin
dev-workspace latest --origin            # Reset local main to origin
```

### When to Use Which Flag
- **`--upstream`**: The original repo (that you forked from) has new commits. You want your local main to match it. Fork repos only — disabled when `upstream` is not set in config.
- **`--origin`**: Your fork on GitHub was updated (e.g. via GitHub UI merge), and you want local to match. Works for both fork and vanilla repos.

### Safety — CRITICAL
`latest` uses `git reset --hard` which **destroys unpushed commits** on the target branch.

The agent MUST:
1. Always run `latest --check` first
2. If check shows unpushed commits → STOP and tell the user. Show them what will be lost.
3. Only proceed after explicit user confirmation
4. The script itself exits with a warning and shows unpushed commits — it does NOT auto-proceed

The `upstream_latest_to` config key controls which branch gets reset. Set to `false` to disable `--upstream` entirely.

---

## dev-workspace merge-latest — Command Branch Sync

Merges `main_branch` into `parent_branch`. Only meaningful for fork repos where these are different branches (e.g. main → command).

### Workflow
```
dev-workspace merge-latest --check       # Verify main is current, see incoming commits
dev-workspace merge-latest               # Merge main → parent (no-ff by default)
dev-workspace merge-latest --ff          # Allow fast-forward merge
```

### Self-Guarding
If `main_branch` equals `parent_branch` (vanilla repo), the command errors: "cannot merge to itself." No accidental damage possible.

### Prerequisites
- Must be on `parent_branch` (command)
- Local `main_branch` must be in sync with origin (the check verifies this)
- If main is stale → run `dev-workspace latest` first

### Why --no-ff is Default
No-ff creates an explicit merge commit even when fast-forward is possible. This makes the history readable — you can see exactly when upstream changes were incorporated into the command branch.

---

## Full Fork Update Sequence

When the upstream repo has new changes, the complete update flow is:

```
# 1. Update local main from upstream
git checkout main
dev-workspace latest --upstream

# 2. Update command branch from main
git checkout command
dev-workspace merge-latest

# 3. Update feature branches from command
git checkout feature/my-work
dev-workspace sync
```

Each step should use `--check` first. The agent should walk through this sequence one step at a time, verifying each before proceeding to the next.
