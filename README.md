# AD Data Platform — Agent Infrastructure

Kiro IDE agent infrastructure for the Alter Domus Data Platform team. This package contains the complete AI-assisted development environment: hooks, steering files, MCP servers, memory system, governance policies, and an AI Engineering Coach persona.

## What's Included

| Component | Count | Purpose |
|-----------|-------|---------|
| Hooks | 15 | Automated triggers for quality, memory, and workflow |
| Steering Files | 8 | Domain-specific guidance loaded into agent context |
| MCP Servers | 22 | External tool integrations (AWS, Atlassian, Terraform, etc.) |
| 3-Tier Memory | 3 layers | Session checkpoints + Knowledge graph + Steering files |
| AGT Governance | 1 policy | OPA-style tool risk classification engine |
| AI Engineering Coach | 1 persona | Karpathy principles + AIDLC workflow |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Kiro IDE Agent                            │
├─────────────────────────────────────────────────────────────┤
│  Steering Files (always-on context)                         │
│  ├── guardrails.md          (safety rules)                  │
│  ├── env-config.md          (AWS accounts, buckets)         │
│  ├── data-platform-overview (architecture)                  │
│  ├── tool-policy-engine.md  (OPA risk tiers)                │
│  ├── karpathy-principles.md (agent behavior)                │
│  ├── aidlc-workflow.md      (dev lifecycle phases)          │
│  ├── memory-management.md   (3-tier memory)                 │
│  └── 20+ domain files       (dbt, Airflow, Terraform...)   │
├─────────────────────────────────────────────────────────────┤
│  Hooks (event-driven automation)                            │
│  ├── Pre-tool: risk gate, security scan                     │
│  ├── Post-tool: file change log, lint                       │
│  ├── On-stop: session checkpoint, memory sync               │
│  └── On-prompt: context load, git activity refresh          │
├─────────────────────────────────────────────────────────────┤
│  MCP Servers (external capabilities)                        │
│  ├── AWS: docs, CloudWatch, CloudTrail, IAM, SNS/SQS...    │
│  ├── Dev: Terraform, Context7, GitHub, Cycode               │
│  ├── Memory: knowledge graph (FalkorDB-backed Graphiti)     │
│  └── Atlassian: Jira + Confluence                           │
├─────────────────────────────────────────────────────────────┤
│  Local Services (Docker)                                    │
│  ├── FalkorDB (graph memory backend)                        │
│  └── OpenMetadata (data catalog, optional)                  │
└─────────────────────────────────────────────────────────────┘
```

## Quick Install

```bash
# Clone this repo or copy the folder
git clone <this-repo> ad-agent-infrastructure
cd ad-agent-infrastructure

# Install to your workspace
./install.sh /path/to/your/workspace

# Start local services (optional — for graph memory)
docker compose up -d
```

Or manually:
```bash
cp -r hooks/ /path/to/workspace/.kiro/hooks/
cp -r steering/ /path/to/workspace/.kiro/steering/
cp -r settings/ /path/to/workspace/.kiro/settings/
```

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Docker | 20+ | FalkorDB, OpenMetadata |
| Python | 3.11+ | uvx, pre-commit, dbt |
| Node.js | 18+ | npx MCP servers |
| uvx | latest | Python MCP servers |
| Kiro IDE | latest | Agent runtime |

## Hooks Summary

See `hooks/HOOKS.md` for full details. Key hooks:

- **file-change-log** — Logs every file edit with timestamp
- **pre-tool-risk-gate** — OPA-style risk classification before tool execution
- **session-checkpoint-save** — Saves session state on agent stop
- **memory-sync-on-stop** — Persists learnings to knowledge graph
- **git-activity-refresh** — Updates recent commit context on prompt

## MCP Servers

See `mcp-servers/MCP-SERVERS.md` for the full list of 22 servers with status and configuration.

## Customization

1. Edit `steering/*.md` files to match your team's conventions
2. Update `settings/mcp.json` with your API tokens
3. Modify `hooks/` to add team-specific automation
4. Adjust `docker-compose.yml` ports if conflicts exist

## Team Onboarding Checklist

- [ ] Copy `.kiro/` folder to workspace
- [ ] Run `docker compose up -d` for graph memory
- [ ] Set AWS SSO profile in terminal
- [ ] Generate GitHub PAT and add to mcp.json (optional)
- [ ] Generate Databricks PAT and add to mcp.json (optional)
- [ ] Run `pre-commit install` in workspace
- [ ] Ask agent: "Seed the knowledge graph with core platform entities"
