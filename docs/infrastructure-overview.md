# Agent Infrastructure — What It Is and Why You Need It

## The Problem: Unguarded AI Agents in Production

AI coding agents are powerful. They can write code, run commands, modify infrastructure, and deploy services. But without guardrails, they are dangerous in production codebases:

- An agent can `terraform destroy` your production database
- An agent can commit secrets to a public repository
- An agent can run `dbt build` in production without approval
- An agent can install malicious packages via typosquatting
- An agent forgets everything between sessions — repeating mistakes endlessly

The industry response has been prompt-level safety ("please don't do bad things"). This fails. JailbreakBench demonstrates near-100% attack success rates against prompt-only defenses.

**You need infrastructure, not instructions.**

## The Solution: Layered Agent Infrastructure

This repository implements a 6-layer defense-in-depth architecture for AI coding agents. Each layer operates independently — if one fails, the others still protect you.

```
┌─────────────────────────────────────────────────────────────────┐
│                    Layer 6: Observability                         │
│              AI Engineering Coach (retrospective)                 │
├─────────────────────────────────────────────────────────────────┤
│                    Layer 5: Governance                            │
│         OPA-style policy engine + Microsoft AGT                  │
├─────────────────────────────────────────────────────────────────┤
│                    Layer 4: Memory                                │
│     Session checkpoints + Knowledge graph + Semantic search      │
├─────────────────────────────────────────────────────────────────┤
│                    Layer 3: MCP Servers                           │
│        External tool integrations (AWS, Terraform, Jira)         │
├─────────────────────────────────────────────────────────────────┤
│                    Layer 2: Hooks                                 │
│     Event-driven automation (preToolUse, fileEdited, etc.)       │
├─────────────────────────────────────────────────────────────────┤
│                    Layer 1: Steering Files                        │
│           Persistent context that guides agent behavior          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Layer 1: Steering Files

Steering files are markdown documents that provide persistent context to the agent. Unlike chat messages that disappear, steering files are loaded into every session automatically.

**What they contain:**
- Coding standards and conventions
- Environment configurations (without secrets)
- Guardrails and hard rules
- Domain knowledge (architecture, patterns, troubleshooting)
- Anti-hallucination rules

**How they work:**
```
.kiro/steering/
├── guardrails.md          # Hard rules (always loaded)
├── coding-style.md        # Code conventions (always loaded)
├── env-config.md          # Environment details (always loaded)
├── dbt-patterns.md        # dbt guidance (loaded when editing .sql files)
└── terraform.md           # IaC guidance (loaded when editing .tf files)
```

Steering files support three inclusion modes:
- `always` — loaded in every session
- `fileMatch` — loaded when the agent touches matching files
- `manual` — loaded only when explicitly requested

---

## Layer 2: Hooks

Hooks are event-driven automations that fire when specific IDE events occur. They intercept agent actions at critical moments.

**Supported events:**
| Event | When It Fires |
|-------|---------------|
| `preToolUse` | Before the agent executes any tool (write, shell, etc.) |
| `postToolUse` | After a tool executes (for validation) |
| `fileEdited` | When a file is saved or modified |
| `fileCreated` | When a new file is created |
| `agentStop` | When the agent session ends |
| `promptSubmit` | When the user sends a message |

**Example: Block dangerous commands before execution**
```json
{
  "name": "block-destructive-ops",
  "event": "preToolUse",
  "toolTypes": "shell",
  "action": "askAgent",
  "prompt": "Check if this command is destructive. If so, BLOCK it and explain why."
}
```

**Example: Auto-lint on file save**
```json
{
  "name": "lint-on-save",
  "event": "fileEdited",
  "filePatterns": "**/*.py",
  "action": "runCommand",
  "command": "ruff check --fix ${file}"
}
```

---

## Layer 3: MCP Servers

Model Context Protocol (MCP) servers give agents access to external tools and services through a standardized interface. Instead of the agent guessing at CLI commands, it uses structured tool calls.

**Configured servers in this infrastructure:**
| Server | Purpose |
|--------|---------|
| `aws-docs` | Search and read AWS documentation |
| `terraform` | Terraform registry lookups |
| `context7` | Library documentation search |
| `memory` | Knowledge graph persistence |
| `sequential-thinking` | Structured reasoning |
| `cloudwatch` | Log analysis and metrics |
| `atlassian` | Jira and Confluence integration |

**Configuration format:**
```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-memory"],
      "env": {
        "MEMORY_FILE": "${workspaceFolder}/work/memory-graph.json"
      }
    }
  }
}
```

---

## Layer 4: Memory

Agents forget everything between sessions. The 3-tier memory system solves this:

| Tier | Storage | Use Case |
|------|---------|----------|
| Session Checkpoints | Markdown files | Detailed work-in-progress state |
| Knowledge Graph | JSON (Memory MCP) | Patterns, decisions, relationships |
| Semantic Memory | ChromaDB vectors | Fuzzy recall ("what pattern do we use for X?") |

Memory syncs automatically via the `agentStop` hook — when a session ends, key learnings are persisted to the knowledge graph.

---

## Layer 5: Governance

The governance layer provides deterministic enforcement that cannot be bypassed by prompt injection.

**5-tier risk classification:**
| Tier | Action | Example |
|------|--------|---------|
| 0 | Auto-approve | Read files, search, diagnostics |
| 1 | Log only | Edit workspace files |
| 2 | Validate intent | Run shell commands (read-only) |
| 3 | Gate + confirm | Create Jira issues, write to external systems |
| 4 | Forbidden | `terraform destroy`, hardcode secrets |

**Microsoft AGT (Agent Governance Toolkit) integration:**
- Policy defined in YAML (declarative, version-controlled)
- `agt verify` validates the full policy suite
- `agt lint-policy` checks policy syntax
- Intercepts at the application layer — not the prompt layer

---

## Layer 6: Observability

The AI Engineering Coach provides retrospective analysis of agent sessions:

- What tools were used and how often?
- Were any guardrails triggered?
- What was the agent's success rate?
- Where did the agent struggle or loop?
- What patterns should be added to steering files?

This creates a feedback loop: observability findings become new steering rules.

---

## How All Layers Work Together

```
User sends prompt
       │
       ▼
[Layer 1: Steering] ──── Agent receives context (guardrails, patterns, env config)
       │
       ▼
[Layer 4: Memory] ────── Agent recalls past decisions and patterns
       │
       ▼
Agent decides to use a tool
       │
       ▼
[Layer 2: Hook] ──────── preToolUse hook fires, validates the action
       │
       ▼
[Layer 5: Governance] ── Policy engine classifies risk tier
       │                  Tier 4? BLOCKED
       │                  Tier 3? Requires justification
       │                  Tier 0-2? Proceed
       ▼
[Layer 3: MCP Server] ── Tool executes via structured protocol
       │
       ▼
[Layer 2: Hook] ──────── postToolUse hook fires, validates result
       │
       ▼
Agent produces output
       │
       ▼
[Layer 2: Hook] ──────── agentStop hook fires, syncs memory
       │
       ▼
[Layer 6: Observability] Session analyzed for improvements
```

---

## Before and After

### Without Infrastructure

```
Developer: "Fix the production database connection"
Agent: *runs terraform apply in production*
Agent: *hardcodes the new connection string*
Agent: *commits .env file with credentials*
Agent: *forgets what it did next session*
Result: Security breach, production outage, no audit trail
```

### With Infrastructure

```
Developer: "Fix the production database connection"
Agent: *reads guardrails.md — production is read-only*
Agent: *reads env-config.md — uses Secrets Manager path*
Agent: *preToolUse hook blocks terraform apply in prd*
Agent: *policy engine classifies as Tier 4 — FORBIDDEN*
Agent: "Production is read-only. I will prepare the fix for dev
        and provide the promotion path."
Agent: *agentStop hook persists the decision to memory*
Result: Safe fix in dev, proper promotion path, full audit trail
```

---

## Getting Started

See [getting-started.md](./getting-started.md) for installation instructions.

For IDE-specific setup:
- [Kiro Integration](./kiro-integration.md)
- [Claude Code Integration](./claude-code-integration.md)

For deep dives:
- [Security & Governance](./security-and-governance.md)
- [Memory System](./memory-system.md)
