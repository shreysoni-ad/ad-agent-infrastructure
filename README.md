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

> **Note:** This repo is a **reference implementation and guidance**. It demonstrates patterns and best practices for AI agent infrastructure. Clone it, study the architecture, and adapt it to your own coding style, tech stack, and requirements. Don't blindly copy — understand what each component does and customize it for your team.

```bash
# Clone this repo to study and adapt
git clone https://github.com/shreysoni-ad/ad-agent-infrastructure.git
cd ad-agent-infrastructure

# Review the docs first
cat docs/getting-started.md
cat docs/infrastructure-overview.md

# When ready — adapt and install to your workspace
# Customize steering files, hooks, and MCP configs for YOUR project
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
| IDE | Any MCP-compatible | Kiro, Claude Code, Cursor, Windsurf, Codex, etc. |

## Works With Any AI Coding Agent

This infrastructure is **not locked to a single IDE**. The same principles, patterns, and tools work across all MCP-compatible AI coding agents:

| IDE / Agent | Steering | Hooks | MCP Servers | Memory | Governance |
|-------------|----------|-------|-------------|--------|------------|
| **Kiro** | `.kiro/steering/*.md` | `.kiro/hooks/*.kiro.hook` | `.kiro/settings/mcp.json` | ✅ | ✅ |
| **Claude Code** | `CLAUDE.md` | `.claude/hooks.json` | `.mcp.json` | ✅ | ✅ (plugin) |
| **Cursor** | `.cursor/rules/*.mdc` | N/A (use rules) | `.cursor/mcp.json` | ✅ | ✅ |
| **OpenAI Codex** | `AGENTS.md` | `.agents/hooks/` | `.agents/mcp.json` | ✅ | ✅ |
| **Windsurf** | `.windsurf/rules/` | N/A | `.codeium/windsurf/mcp_config.json` | ✅ | ✅ |
| **GitHub Copilot** | `.github/copilot-instructions.md` | N/A | VS Code MCP settings | ✅ | ✅ |

**The core concepts are universal:**
- **Steering files** = persistent instructions (different file format per IDE, same purpose)
- **Hooks** = event-driven automation (preToolUse, postToolUse, agentStop — same events everywhere)
- **MCP servers** = identical protocol across all clients (same `mcp.json` format)
- **Memory** = Memory MCP server works in ANY MCP-compatible client
- **Governance** = Microsoft AGT has plugins for Claude Code, Kiro, and VS Code

**To adapt for your IDE:**
1. Read `docs/claude-code-integration.md` for Claude Code specifics
2. Read `docs/kiro-integration.md` for Kiro specifics
3. For Cursor/Codex/Windsurf: same MCP config, translate steering to their rules format
4. The governance policy (AGT) and memory system work identically everywhere

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
