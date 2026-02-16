# Merge — Merging Branches

## Workflow

```
dev-workspace merge --check              # ALWAYS run first — full preflight
dev-workspace merge                      # Auto-detects PR or local merge
dev-workspace merge --local              # Force local merge (skip PR detection)
dev-workspace merge --github             # Force GitHub PR merge
```

**Rule:** Never run `merge` without running `merge --check` first. The preflight catches issues that are much harder to fix mid-merge.

## Preflight Report (--check)

`merge --check` verifies everything needed for a clean merge:

| Check | What it verifies |
|-------|-----------------|
| Working tree | No uncommitted changes |
| Commits pushed | All local commits exist on origin |
| Merge conflicts | No conflicts with parent branch |
| PR status | PR exists and is not in draft (if using GitHub) |
| Archive | Workspace archived if `archive_before_merge` is configured |

**Exit codes:**
- **0** — Ready to merge. All checks passed.
- **1** — Warnings. Review with user before proceeding.
- **2** — Blockers. Cannot merge until resolved.

### Responding to Preflight Results

**Blockers (exit 2):** Stop. Report the blockers to the user. Common blockers:
- Merge conflicts → run `dev-workspace sync` to resolve conflicts first
- These must be fixed before merge can proceed

**Warnings (exit 1):** Review with user. Common warnings:
- Unpushed commits → run `dev-workspace push` first
- No PR → ask user if local merge is OK, or create PR with `gh pr create`
- Draft PR → ask if they want to publish it first
- No archive → run `dev-workspace archive` if configured

**All clear (exit 0):** Proceed to merge.

## Merge Paths

### Auto-detect (default)
`dev-workspace merge` checks if a GitHub PR exists for the branch:
- PR exists → merges via GitHub (`gh pr merge`)
- No PR → merges locally

### Local Merge
`dev-workspace merge --local` forces local merge regardless of PR status. The flow:
1. Push current branch to origin
2. Checkout parent branch and pull latest
3. Merge with configured strategy (merge/squash/rebase)
4. Restore workspace files (protection step)
5. Push parent branch

### GitHub Merge
`dev-workspace merge --github` forces PR merge. Requires an existing PR. The flow:
1. Push any unpushed commits
2. Merge PR via `gh pr merge` with configured strategy
3. Checkout and update local parent branch

## Merge Strategies

Configured in `workspace-config.yml` under `merge.strategy`:

- **`--merge`** (default): Full history merge with merge commit. Best for visibility — you can see exactly when branches were merged and what they contained.
- **`--squash`**: Collapses all branch commits into a single commit on parent. Clean parent history, but individual commit history is lost.
- **`--rebase`**: Replays branch commits on top of parent. Linear history, but rewrites commit hashes.

The strategy is read from config automatically. No need to pass flags unless overriding.

## Workspace File Protection

**This is critical to understand.** During merge, workspace files are automatically protected.

The problem: Feature branches contain filled-in workspace context (branch purpose, discoveries, plans). Merging this to the parent would overwrite the parent's clean templates.

The solution: After the merge (using `--no-commit`), the script:
1. Unstages all changes in `dev/workspace/`
2. Restores parent branch's workspace files
3. Cleans any new workspace files from the feature branch
4. Then commits the merge

This happens automatically for `--merge` and `--squash` strategies. For `--rebase`, workspace protection works differently via the merge driver configured during `init`.

## Archive Before Merge

If `archive_before_merge: true` in config, the preflight (`--check`) verifies that the workspace has been archived. If not:

1. Run `dev-workspace archive` to create/update the archive
2. Re-run `dev-workspace merge --check` — archive check should now pass
3. Proceed with merge

This ensures workspace context is preserved before the branch is merged and potentially deleted.

## Post-Merge

- Parent branch is pushed to origin automatically
- If `delete_branch_after_merge: true`, the branch is deleted locally and from origin
- If merged via GitHub, the local parent is updated via pull
