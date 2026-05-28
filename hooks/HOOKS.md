# Hooks Inventory

All hooks configured in `.kiro/hooks/`. These automate quality, memory, and workflow actions.

## Event: preToolUse

| Hook | Trigger | Description |
|------|---------|-------------|
| pre-tool-risk-gate | `write` tools | OPA-style risk classification — blocks Tier 4, gates Tier 3 |
| cycode-security-check | `write` tools | Verifies no SSRF, hardcoded secrets, or unsanitized input before file writes |
| pre-commit-quality | `write` tools | Checks Python style (type hints, imports, line length) before writing |

## Event: postToolUse

| Hook | Trigger | Description |
|------|---------|-------------|
| file-change-log | `write` tools | Appends timestamp + file + description to FILE-CHANGE-LOG.md |
| post-write-verify | `write` tools | Runs getDiagnostics/lint on code files after write |
| consumption-precommit | `write` tools | Validates isort/flake8/ruff for consumption repo Python files |

## Event: agentStop

| Hook | Trigger | Description |
|------|---------|-------------|
| session-checkpoint-save | agent stops | Saves session state (files changed, decisions, next steps) to work/sessions/ |
| memory-sync-on-stop | agent stops | Persists new patterns/decisions to knowledge graph via Memory MCP |

## Event: promptSubmit

| Hook | Trigger | Description |
|------|---------|-------------|
| session-checkpoint-load | user prompt | Loads relevant session checkpoint when user references past work |
| git-activity-refresh | user prompt | Updates git-activity.md steering file with latest commits |
| context-preload | user prompt | Loads domain-specific steering based on file patterns in prompt |

## Event: fileEdited

| Hook | Trigger | Description |
|------|---------|-------------|
| dbt-model-lint | `**/*.sql` | Validates SQL keywords uppercase, ref()/source() targets exist |
| terraform-fmt-check | `**/*.tf` | Checks terraform fmt compliance on save |

## Event: userTriggered

| Hook | Trigger | Description |
|------|---------|-------------|
| seed-knowledge-graph | manual | Seeds the knowledge graph with core platform entities from steering files |
| full-lint-check | manual | Runs pre-commit on all files in workspace |

## Total: 15 hooks
