# Steering Files Inventory

Steering files provide always-on context to the agent. Located in `.kiro/steering/`.

## Inclusion Modes

- **always** — Loaded on every prompt regardless of context
- **fileMatch** — Loaded only when referenced files match a glob pattern
- **manual** — Loaded only when explicitly activated

## Core Steering (always)

| File | Purpose |
|------|---------|
| `guardrails.md` | Non-negotiable safety rules: anti-hallucination, env read-only enforcement, infrastructure prohibitions |
| `env-config.md` | AWS accounts, S3 buckets, Databricks config, Glue databases, MWAA settings |
| `data-platform-overview.md` | End-to-end architecture, repo responsibilities, active work streams |
| `tool-policy-engine.md` | OPA-style risk tier classification for all tool invocations |
| `karpathy-principles.md` | Agent behavior: think before coding, simplicity, surgical changes, goal-driven |
| `aidlc-workflow.md` | 5-phase development lifecycle: Discovery → Planning → Implementation → Verification → Delivery |
| `memory-management.md` | 3-tier memory system: session checkpoints + knowledge graph + steering |
| `alter-domus-standards.md` | Company naming conventions, environments, CI/CD standards |
| `coding-style.md` | Universal code style, naming, error handling, linting |
| `git-workflow.md` | Commit messages, branching, PR conventions |
| `pr-review.md` | PR description format, checklists by change type |
| `conflict-resolution.md` | ECC + Kiro precedence rules |
| `context-compaction.md` | Long session management, checkpoint strategy |
| `advanced-patterns.md` | Debugging protocol, security review, incident response |
| `troubleshooting.md` | Common error patterns: MWAA, dbt, Athena, Terraform, Python |
| `hotfix-playbook.md` | Hotfix vs revert decision tree, lessons learned |
| `mcp-servers.md` | MCP server inventory and configuration |
| `git-activity.md` | Recent commits across all repos (auto-updated) |

## Domain Steering (always)

| File | Purpose |
|------|---------|
| `data-engineering.md` | dbt, ETL, Spark, Airflow, Iceberg, Snowflake patterns |
| `infrastructure.md` | Terraform, Kubernetes, Docker, Helm patterns |
| `cloud.md` | AWS, GCP, Azure, CDK, serverless patterns |
| `software-development.md` | Python, TDD, backend, frontend, security patterns |
| `sql.md` | Query optimization, PostgreSQL, ClickHouse, Athena |

## Repository Deep References (always)

| File | Purpose |
|------|---------|
| `clone-repos.md` | External repo paths, tooling constraints, git operations |
| `repo-databricks-engine.md` | Databricks engine: notebooks, jobs, bundle config |
| `repo-cloud-infra.md` | Cloud infra: Terraform modules, providers, config pattern |
| `repo-consumption.md` | Consumption API: FastAPI routes, helpers, deployment |

## Specialized Steering (fileMatch)

| File | Glob Pattern | Purpose |
|------|-------------|---------|
| `dbt-client-onboarding.md` | `**/dbt/models/**` | Client folder structure, model naming |
| `dbt-macros.md` | `**/dbt/macros/**` | Macro reference: audit, DQ, type conversion |
| `airflow-dags.md` | `**/src/dags/**` | DAG inventory, libraries, utilities |
| `databricks-guardrails.md` | `**/databricks**` | Bundle safety, serverless limits |
| `massrelay.md` | `**/massrelay**` | MassRelay pub/sub architecture |
| `snowflake-integration.md` | `**/snowflake**` | Snowflake client, SFDR, outbound |
| `pre-commit-checks.md` | `**/.pre-commit*` | Pre-commit configs for all repos |
| `cycode-security.md` | `**/*.py` | SAST patterns, taint chain breaking |

## Total: ~30 steering files
