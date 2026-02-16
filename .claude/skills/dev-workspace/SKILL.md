---
name: dev-workspace
description: "Manage git workflow operations for projects using the dev-workspace system. Use instead of raw git commands (checkout -b, push, merge, pull) when operating on any codebase containing dev/workspace/workspace-config.yml. Handles feature branch lifecycle (create, push, sync, merge), workspace context management (commit, archive, sync archives), fork management (pristine main, upstream updates, command branch sync), and deploy push. Supports both fork repos (upstream + command branch pattern) and vanilla repos (single main branch). Every command supports --check for safe inspection before execution."
---

# dev-workspace

Git workflow management for dev-workspace codebases.

**Detection:** A project uses dev-workspace if `dev/workspace/workspace-config.yml` exists in its directory tree. The script auto-detects the project root by walking up from CWD.

**Rule:** NEVER use raw git for branch creation, pushing, syncing, merging, or workspace commits in dev-workspace projects. Always use the `dev-workspace` command.

## Commands

```
dev-workspace init                    Scaffold config files from skill template
dev-workspace init --write            Apply config settings to project (idempotent)
dev-workspace init --check            Verify settings are applied

dev-workspace new                     List branches from parent
dev-workspace new <name>              Create new workspace branch
dev-workspace new <name> --check      Validate readiness without creating
dev-workspace new <name> --force      Create even if local is behind remote

dev-workspace push                    Push current branch to origin
dev-workspace push --check            Show push status (ahead/behind/diverged)
dev-workspace push --force-w-l        Force push with lease (post-rebase)

dev-workspace sync                    Merge parent into current feature branch
dev-workspace sync --check            Show how far behind parent
dev-workspace sync --rebase           Rebase onto parent instead of merge

dev-workspace merge                   Merge current branch to parent
dev-workspace merge --check           Full preflight report (ALWAYS run first)
dev-workspace merge --local           Force local merge (skip PR detection)
dev-workspace merge --github          Force GitHub PR merge

dev-workspace commit                  Commit workspace files only
dev-workspace commit --check          Show what would be committed

dev-workspace archive                 Archive workspace to dev/branches/
dev-workspace archive --check         Show archive status + sync divergences
dev-workspace archive --sync          Bidirectional sync archives with parent
dev-workspace archive --path          Output archive path (for scripting)

dev-workspace latest --check          Show sync status of main with remotes
dev-workspace latest --upstream       Reset local main to upstream (fork only)
dev-workspace latest --origin         Reset local main to origin

dev-workspace merge-latest            Merge main_branch into parent_branch
dev-workspace merge-latest --check    Show status, verify main is current
dev-workspace merge-latest --ff       Allow fast-forward merge

dev-workspace rebuild                 Pull latest dev-workspace updates
dev-workspace rebuild --check         Check if updates are available

dev-workspace deploy push             Push source to deploy target
dev-workspace deploy push --check     Show deploy status
```

## The --check Pattern

Every command supports `--check` to inspect state without making changes.

**Mandatory workflow for destructive commands (merge, latest, deploy):**
1. Run `command --check` — inspect state
2. If issues → stop and discuss with human
3. If clear → run the command

## Config

Two YAML files in `dev/workspace/`:
- **`workspace-config.yml`** — Machine-read. Repo setup, remotes, merge strategy, deploy. Created by `init --write` from the skill template.
- **`workspace.yml`** — Human/agent-read. Branch purpose, status, workflow type, plans. Not read by the script.

## References — Essential Reading

**You do not know how this tool works from the commands alone.** The commands are atomic building blocks. The references contain the procedural knowledge you need to use them correctly — safety constraints, required sequences, what to check before acting, how to interpret output, and how to recover from problems. Without reading the relevant reference, you will make mistakes that are difficult to undo (bad merges, lost commits, corrupted branch state).

**Always read the reference for your task before executing commands.**

### `references/init.md` — Project Setup
Read before first-time setup or adding dev-workspace to a new project. You need this because:
- Init is a three-step process (scaffold → edit → write) — running `--write` without scaffolding first fails
- Fork vs vanilla repo config is fundamentally different and affects every other command
- Each init section (merge protection, gitignore, dockerignore, workspace remote) solves a specific problem — understanding why they exist prevents you from disabling something critical
- Re-running init after config changes requires understanding idempotent behaviour

### `references/new-workspace.md` — Branch Creation
Read before creating any branch. You need this because:
- Branch creation has prerequisites (correct parent branch, clean tree, sync with remote) — skipping any causes problems downstream
- The `--no-track` flag on creation is intentional and you must not "fix" it
- Workspace files transfer from parent to new branches by design — this is not a bug
- Post-creation steps (updating workspace.yml) set up the branch for proper workflow

### `references/push.md` — Pushing Branches
Read when `push --check` reports anything other than "X commits to push". You need this because:
- Diverged state requires `--force-w-l` but force pushing has safety implications you must understand
- Force-with-lease is NOT the same as force push — the difference matters
- There are specific scenarios where force push is appropriate vs dangerous
- Push works differently than you might expect — any branch pushes to its matching origin, including main

### `references/sync.md` — Branch Syncing (THREE different commands)
**Critical reading.** This is the most complex area of the tool. You need this because:
- There are THREE separate sync-related commands (`sync`, `latest`, `merge-latest`) that do completely different things — using the wrong one causes real damage
- `latest` uses `git reset --hard` which **destroys commits permanently** — the reference explains exactly when this is safe and when it is not
- Fork repos require a specific multi-step update sequence (latest → merge-latest → sync) — doing them out of order fails
- `merge-latest` self-guards against vanilla repos but you need to understand why
- The full fork update sequence is documented step-by-step — follow it exactly

### `references/merge.md` — Merging Branches
Read before every merge. You need this because:
- The preflight (`--check`) returns exit codes with specific meanings — you must know how to respond to warnings vs blockers
- Workspace file protection happens automatically during merge but you need to understand the mechanism to troubleshoot if something goes wrong
- The three merge strategies (merge/squash/rebase) have different implications for workspace protection
- Archive-before-merge is a configurable requirement — the preflight checks it but you need to know what to do when it fails
- Auto-detection chooses between local and GitHub merge — you need to know when to override with `--local` or `--github`

### `references/commit.md` — Workspace Commits
Read before first use. You need this because:
- The command **unstages everything first** — if you have staged code changes, they will be unstaged. This is intentional but will surprise you if you don't know about it
- Only configured directories are committed — the command is not a general-purpose commit
- Understanding the isolation pattern (workspace commits separate from code commits) is essential

### `references/archive.md` — Context Preservation
Read before archiving or syncing archives. You need this because:
- Archives use `rsync --delete` (mirror) — files deleted from workspace are also deleted from archive. This is correct behaviour but must be understood
- `--sync` is bidirectional and involves temporary branch switching — requires clean working tree and you need to understand what happens if it fails mid-sync
- Pull-first ordering in sync is deliberate and important for consistency
- Archive naming convention (branch name with `/` replaced by `_`) affects how you find archives

### `references/deploy.md` — Deploy Push
Read before any deploy operation. You need this because:
- Remote vs local deploy are configured differently and behave differently
- Docker's `.dockerignore` eliminates the need for directory stripping — understanding this prevents over-engineering the deploy
- Deploy push only moves code to the target — actual deployment is a separate concern with separate tooling
