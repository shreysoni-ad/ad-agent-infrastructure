# Changelog

## 2026-05-28 — Initial Release

### Built

- **15 Hooks** — Event-driven automation for quality, memory, and workflow
  - 3 preToolUse hooks (risk gate, security check, quality check)
  - 3 postToolUse hooks (file change log, verification, consumption precommit)
  - 2 agentStop hooks (session checkpoint, memory sync)
  - 3 promptSubmit hooks (checkpoint load, git refresh, context preload)
  - 2 fileEdited hooks (dbt lint, terraform fmt)
  - 2 userTriggered hooks (seed graph, full lint)

- **30 Steering Files** — Domain-specific agent context
  - Core: guardrails, env-config, tool-policy-engine, karpathy-principles, aidlc-workflow
  - Domain: data-engineering, infrastructure, cloud, software-development, sql
  - Platform: alter-domus-standards, dbt-client-onboarding, dbt-macros, airflow-dags
  - Repos: clone-repos, repo-databricks-engine, repo-cloud-infra, repo-consumption
  - Safety: databricks-guardrails, hotfix-playbook, troubleshooting, cycode-security
  - Workflow: git-workflow, pr-review, pre-commit-checks, context-compaction, memory-management

- **22 MCP Servers** — External tool integrations
  - 9 AWS servers (docs, CloudWatch, CloudTrail, IAM, data-processing, SNS/SQS, Step Functions, cost, diagram)
  - 4 dev tools (Terraform, Context7, sequential-thinking, Cycode)
  - 2 collaboration (Atlassian, AlterDomus internal)
  - 7 disabled/pending config (Databricks, Snowflake, GitHub, aws-iac, aws-cfn, memory, playwright)

- **3-Tier Memory System**
  - Layer 1: Session checkpoints (work/sessions/*.md) — detailed per-session state
  - Layer 2: Knowledge graph (Memory MCP + FalkorDB) — cross-session pattern recall
  - Layer 3: Steering files — persistent domain knowledge

- **AGT Governance (Tool Policy Engine)**
  - Tier 0: Auto-approve (read-only tools)
  - Tier 1: Low risk (local file edits)
  - Tier 2: Medium risk (commands, external reads)
  - Tier 3: High risk (write operations, Jira/Confluence)
  - Tier 4: Forbidden (terraform destroy, prd writes, wildcard IAM)
  - Environment modifiers escalate risk for qa/sim/prd

- **AI Engineering Coach**
  - Karpathy principles: think before coding, simplicity, surgical changes, goal-driven
  - AIDLC workflow: Discovery → Planning → Implementation → Verification → Delivery
  - Confusion surfacing: explicit uncertainty over silent assumptions

### Infrastructure

- Docker Compose for local services (FalkorDB, OpenMetadata)
- Install script for workspace deployment
- Pre-commit configs for all 4 repos (transform-engine, databricks-engine, cloud-infra, consumption)

### Supported Repositories

| Repo | Domain |
|------|--------|
| ad-data-platform-transform-engine | dbt + Airflow |
| ad-data-platform-databricks-engine | Databricks notebooks |
| ad-data-platform-cloud-infra | Terraform IaC |
| ad-data-platform-consumption | FastAPI + MassRelay |
