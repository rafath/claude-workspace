# Deploy — Push to Deploy Target

## Commands

```
dev-workspace deploy push --check        # Verify deploy config and source branch
dev-workspace deploy push                # Push to deploy target
```

## Two Deploy Patterns

### Remote Deploy
Code is pushed to a separate deploy repository. Common for fork repos where you push your command branch to the upstream's deploy infrastructure.

```yaml
# workspace-config.yml
deploy:
  deploy_source: command
  deploy_branch: deploy
  remote:
    deploy_remote_url: https://github.com/org/project.git
    deploy_remote_branch: command-mirror
```

The script adds a `deploy` git remote (or updates it) and pushes the source branch to the remote branch.

### Local Deploy
Code is merged to a deploy branch within the same repo. Common for vanilla repos with staging/production branches.

```yaml
# workspace-config.yml
deploy:
  deploy_source: main              # or command
  deploy_branch: staging
  # remote section commented out = local mode
```

The script checks out the deploy branch, merges the source with `--no-ff`, and pushes.

## Docker and Workspace Files

`.dockerignore` excludes `/dev/` from Docker builds (configured during `init`). This means workspace files never reach the server image. **No directory stripping or worktree tricks needed.**

## Deploy Check

`deploy push --check` reports:
- Source and target branch configuration
- Whether remote is configured (remote vs local mode)
- Whether the source branch exists

Always run `--check` before deploying. If config is missing or source branch doesn't exist, the check catches it.

## After Deploy Push

The deploy push only gets code to the target branch/repo. Actual deployment (Docker build, Kamal commands, server operations) is handled by separate tooling. If a `dev-deploy` skill exists, use that for the deployment step.

## No Deploy Config

If the `deploy` section is commented out or missing from config, the deploy command reports "Deploy not configured" and exits. This is expected for projects that don't need deploy automation.
