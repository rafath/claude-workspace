# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a **workflow configuration repository** that provides default templates and configurations for Claude Code and GitHub workflows. It serves as a starting point for new projects and a central place to manage reusable development patterns.

## Key Concepts

### mApp Methodology
This repo includes documentation for **mApp** - a cartographic approach to application design that uses map metaphors (landscape/legend/people) to describe software architecture in an implementation-agnostic way. See `docs/mApp/what_is_mApp.md`:67-53 for full details.

**Key mApp structure:**
- `landscape/` - Application interfaces (regions → areas → places)
- `legend/` - Domain objects/models
- `people/` - User types and roles

### Dev Docs Pattern
A three-file methodology for maintaining context across sessions:
- `[task]-plan.md` - Strategic implementation plan
- `[task]-context.md` - Key decisions, files, progress tracking
- `[task]-tasks.md` - Actionable checklist

See `dev/README.md` for complete pattern documentation.

## Architecture

### Configuration Layers

**`.claude-user/`** - Global user configuration (applies to all projects):
- `commands/` - User-level slash commands (commit, branch management)
- `agents/` - Code review agents (security, performance, test coverage, etc.)
- `skills/` - Reusable skill modules (git operations, skill-creator)
- `output-styles/` - Response formatting styles (concise, rails_backend, etc.)

**`.claude/`** - Project-specific configuration:
- `commands/github/` - GitHub workflow commands (issue-*, pr-*)
- `commands/CSS/` - CSS development commands
- `agents/` - Project agents (css-class-finder, index-file-auditor)
- `output-styles/` - Project output styles (rails-progressive, github-cli)

### Slash Commands

This repo heavily uses slash commands for workflow automation. Key patterns:

**GitHub Issue Workflow:**
- `/github:issue-plan <number>` - Collaborative planning with user approval
- `/github:issue-start <number>` - Readiness check before starting
- `/github:issue-review <number>` - Verify implementation completeness
- `/github:issue-close <number>` - Close with summary comment

**All GitHub commands:**
1. Draft content to `docs/sandbox/`
2. User reviews/approves
3. User posts with `gh` CLI command

Example: `/github:issue-plan` creates `docs/sandbox/issue-{number}-plan.md`, user posts with `gh issue comment {number} -F docs/sandbox/issue-{number}-plan.md`

**Development Commands:**
- `/ruby_scratchpad` - Model features with Ruby
- `/html_scratchpad` - Prototype views with XML
- `/cleanup` - Work through cleanup task list
- `/record_feature` - Document completed features from git history

### Skills System

Prefer using available skills over system instructions. Skills provide customizable workflows:

**Git Skill** (`git/SKILL.md`):
- Decision matrix for commit/branch/push/pull operations
- Reference files for each operation type
- DO NOT use AskUserQuestion tool within git skill

**When user mentions git operations, use the git skill.**

### GitHub Actions

**`.github/workflows/claude-pr-review.yml`** - Automated PR review using `anthropics/claude-code-action@v1`:
- Triggers on PR opened/synchronized/ready_for_review
- Executes `/review-pr` command
- Allows inline comment creation via MCP tool

**`.github/workflows/weekly-cleanup.yml`** - Scheduled cleanup tasks

## Common Patterns

### Sandbox Workflow
All GitHub automation follows this pattern:
1. Claude drafts to `docs/sandbox/[type]-{number}-[action].md`
2. User reviews/edits sandbox file
3. User executes `gh` command with `-F` flag

**Never auto-post to GitHub** - user always has final approval.

### Collaborative Planning
Issue planning uses three-phase approach (see `/github:issue-plan`):
1. **Initial Summary** - Research + questions for user
2. **Refined Summary** - Iterate until approved
3. **Detailed Plan** - Third-person implementation guide

Remove "Questions for User" section from final plan before posting.

### Documentation Templates
Located in `docs/mApp/`:
- `mapp-template.txt` - Application structure
- `meople-template.txt` - User types
- `mobject-template.txt` - Domain objects

### Code Review Agents
Located in `.claude-user/agents/`:
- `security-code-reviewer.md`
- `performance-reviewer.md`
- `test-coverage-reviewer.md`
- `code-quality-reviewer.md`
- `documentation-accuracy-reviewer.md`

Used by `/review-pr` command and GitHub Actions.

## File Organization

```
workflow/
├── .claude/              # Project config
│   ├── commands/github/  # Issue/PR workflow
│   └── agents/          # Project agents
├── .claude-user/        # Global config
│   ├── skills/git/      # Git operations
│   └── agents/          # Code review agents
├── .github/
│   ├── ISSUE_TEMPLATE/  # Structured issue types
│   └── workflows/       # CI/CD automation
├── docs/
│   ├── mApp/           # mApp methodology docs
│   ├── rails/          # Rails reference docs
│   ├── hotwire/        # Hotwire/Turbo docs
│   └── sandbox/        # Draft workspace (gitignored)
└── dev/
    ├── README.md       # Dev docs pattern guide
    └── active/         # Work-in-progress docs
```

## Working with This Repository

### When Creating New Projects
Copy relevant configuration directories:
```bash
# Project config
cp -r .claude/ ~/new-project/

# GitHub templates
cp -r .github/ ~/new-project/

# Global user config (optional)
cp -r .claude-user/* ~/.claude/
```

### When Adding New Workflows
1. Create slash command in `.claude/commands/`
2. Use existing patterns (sandbox workflow, collaborative approval)
3. Document in `.claude/README.md`
4. Add to CLAUDE.md if architecturally significant

### When Modifying Skills
Edit `SKILL.md` and reference files in skill directory. Skills override system instructions when available.

## Important Notes

- **Skills override system instructions** - Use available skills first
- **Never auto-post to GitHub** - Always use sandbox + user approval
- **Markdown syntax helper**: `%% comment %%` for AI agent instructions (remove after processing)
- **Mermaid syntax**: `||--|{` = required FK, `||--o{` = optional FK
- **Username mapping**: dilberryhoundog = GitHub username

## Unresolved Questions

None currently - this repository is a configuration template, not an application under active development.