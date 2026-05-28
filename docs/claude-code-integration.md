# Integration with Claude Code

## Overview

This infrastructure is not locked to a single IDE. While it was designed with Kiro in mind, every layer maps cleanly to Claude Code (Anthropic's CLI-based coding agent).

Claude Code uses the same foundational concepts — project instructions, hooks, and MCP servers — with different file formats and conventions.

---

## Concept Mapping: Kiro to Claude Code

| Kiro Concept | Claude Code Equivalent | Notes |
|---|---|---|
| `.kiro/steering/*.md` | `CLAUDE.md` (project root) | Claude Code loads CLAUDE.md automatically |
| `.kiro/hooks/*.kiro.hook` | `.claude/hooks.json` | Same event model, different schema |
| `.kiro/settings/mcp.json` | `.mcp.json` (project root) | Identical MCP protocol |
| Sub-agents | `/agent` slash command | Claude Code supports spawning sub-agents |
| Powers (marketplace) | MCP servers (manual config) | No marketplace equivalent yet |
| Kiro specs | N/A | Claude Code does not have spec workflows |

---

## Step-by-Step Setup for Claude Code Users

### Step 1: Create CLAUDE.md from Steering Files

Claude Code loads a single `CLAUDE.md` file from the project root. Combine your steering files into sections:

```markdown
# CLAUDE.md

## Guardrails

<!-- Contents of .kiro/steering/guardrails.md -->
These rules are NON-NEGOTIABLE...

## Coding Style

<!-- Contents of .kiro/steering/coding-style.md -->
...

## Environment Configuration

<!-- Contents of .kiro/steering/env-config.md -->
...
```

**Tip:** Keep CLAUDE.md under 50KB. Claude Code loads it entirely into context. For large steering sets, use the most critical files (guardrails, env-config, coding-style) and reference others via MCP memory.

You can also use `.claude/` directory structure:
```
.claude/
├── settings.json       # Project settings
├── hooks.json          # Hook definitions
└── commands/           # Custom slash commands
    ├── seed-memory.md
    └── verify.md
```

### Step 2: Configure MCP Servers (`.mcp.json`)

Create `.mcp.json` in your project root. The format is identical to Kiro's:

```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-memory"],
      "env": {
        "MEMORY_FILE": "./work/memory-graph.json"
      }
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-sequential-thinking"]
    },
    "context7": {
      "command": "npx",
      "args": ["@upstash/context7-mcp@latest"]
    },
    "aws-docs": {
      "command": "uvx",
      "args": ["awslabs.aws-documentation-mcp-server@latest"]
    },
    "terraform": {
      "command": "npx",
      "args": ["@hashicorp/terraform-mcp-server@latest"]
    }
  }
}
```

### Step 3: Install Microsoft AGT for Claude Code

AGT provides a dedicated Claude Code plugin for governance enforcement:

```bash
# Install the AGT CLI
npm install -g @microsoft/agent-governance-toolkit

# Install the Claude Code plugin
npm install -g @microsoft/agent-governance-claude-code

# Initialize AGT in your project
agt init --client claude-code

# Verify the policy suite
agt verify
```

This creates `.agt/` directory with policy YAML files that AGT enforces during Claude Code sessions.

### Step 4: Set Up Memory MCP

The Memory MCP server works identically in Claude Code:

```bash
# Ensure the memory file exists
mkdir -p work
echo '{"entities":[],"relations":[]}' > work/memory-graph.json

# The MCP server is configured in .mcp.json (Step 2)
# Claude Code will auto-start it when you use memory tools
```

To seed the knowledge graph, use a custom command:
```
# .claude/commands/seed-memory.md
Seed the knowledge graph with core platform entities from the steering files.
Create entities for: clients, data sources, architectural patterns, and known bugs.
```

### Step 5: Configure Hooks

Claude Code hooks use a JSON format in `.claude/hooks.json`:

```json
{
  "hooks": [
    {
      "name": "security-gate",
      "event": "preToolUse",
      "toolTypes": ["shell", "write"],
      "action": "askAgent",
      "prompt": "Before executing, verify: no secrets hardcoded, no destructive operations in production, no wildcard IAM permissions."
    },
    {
      "name": "memory-sync",
      "event": "agentStop",
      "action": "askAgent",
      "prompt": "Persist any new patterns, decisions, or bugs learned this session to the knowledge graph via memory MCP."
    },
    {
      "name": "lint-python",
      "event": "fileEdited",
      "filePatterns": ["**/*.py"],
      "action": "runCommand",
      "command": "ruff check --fix ${file}"
    }
  ]
}
```

---

## How Each Layer Maps

### Steering Files to CLAUDE.md

| Kiro Feature | Claude Code Approach |
|---|---|
| `always` inclusion mode | Put in CLAUDE.md directly |
| `fileMatch` inclusion mode | Use custom commands or reference in CLAUDE.md with "when editing X, follow Y" |
| `manual` inclusion mode | Create `.claude/commands/` slash commands |
| Multiple steering files | Concatenate into CLAUDE.md sections |

### Hooks to Claude Code Hooks

The event model is the same:

| Kiro Hook Event | Claude Code Hook Event |
|---|---|
| `preToolUse` | `preToolUse` |
| `postToolUse` | `postToolUse` |
| `fileEdited` | `fileEdited` |
| `fileCreated` | `fileCreated` |
| `agentStop` | `agentStop` |
| `promptSubmit` | `promptSubmit` |

### MCP Servers — Identical

MCP is a protocol, not an IDE feature. The same servers work in both environments:

```
Kiro:        .kiro/settings/mcp.json
Claude Code: .mcp.json (project root)
```

The JSON schema is identical. You can symlink or copy between them.

### Memory — Identical

The Memory MCP server (`@modelcontextprotocol/server-memory`) works in any MCP-compatible client. The knowledge graph JSON file is the same format regardless of which IDE writes to it.

### Governance (AGT) — Plugin

AGT has dedicated plugins for each client:
- Kiro: Built-in integration via steering files
- Claude Code: `@microsoft/agent-governance-claude-code` npm package
- VS Code + Continue: `@microsoft/agent-governance-vscode`

---

## Environment Variables

Claude Code reads environment variables from your shell. Configure tokens via your shell profile:

```bash
# ~/.bashrc or ~/.zshrc

# AWS (use SSO, never hardcode keys)
# Run: aws sso login --profile <YOUR_PROFILE>

# GitHub (for MCP server)
export GITHUB_TOKEN="<YOUR_TOKEN_HERE>"  # Generate at github.com/settings/tokens

# Snyk (for security scanning)
export SNYK_TOKEN="<YOUR_TOKEN_HERE>"  # Get from app.snyk.io/account
```

**Never hardcode tokens in `.mcp.json` or `CLAUDE.md`.** Always reference environment variables.

---

## Limitations vs Kiro

| Feature | Kiro | Claude Code |
|---|---|---|
| Steering file hot-reload | Yes (fileMatch) | No (CLAUDE.md loaded once) |
| Visual hook management | Yes (UI) | No (JSON only) |
| Sub-agent marketplace | Yes (Powers) | No |
| Spec workflows | Yes | No |
| MCP server management | Yes (UI) | Manual config |
| Memory MCP | Yes | Yes |
| AGT governance | Yes | Yes (plugin) |
| Hook events | Full set | Full set |

---

## Migration Checklist

If you are moving from Kiro to Claude Code (or supporting both):

- [ ] Combine critical steering files into `CLAUDE.md`
- [ ] Copy `.kiro/settings/mcp.json` content to `.mcp.json`
- [ ] Convert `.kiro/hooks/*.kiro.hook` to `.claude/hooks.json`
- [ ] Install `@microsoft/agent-governance-claude-code`
- [ ] Create `.claude/commands/` for manual-mode steering
- [ ] Verify memory MCP works: ask "What patterns do we use for X?"
- [ ] Run `agt verify` to confirm governance policies load
- [ ] Test a preToolUse hook fires on a destructive command

---

## Dual-IDE Support

To support both Kiro and Claude Code from the same repo:

```
project-root/
├── .kiro/                    # Kiro-native config
│   ├── steering/*.md
│   ├── hooks/*.kiro.hook
│   └── settings/mcp.json
├── .claude/                  # Claude Code config
│   ├── hooks.json
│   └── commands/
├── .mcp.json                 # Shared MCP config (Claude Code reads this)
├── CLAUDE.md                 # Claude Code steering (generated from .kiro/steering/)
├── .agt/                     # Shared AGT policies
│   └── policies/*.yaml
└── work/
    └── memory-graph.json     # Shared memory (both IDEs read/write)
```

Use a script to sync steering files to CLAUDE.md:
```bash
#!/bin/bash
# scripts/sync-claude-md.sh
echo "# CLAUDE.md (auto-generated from .kiro/steering/)" > CLAUDE.md
for f in .kiro/steering/guardrails.md .kiro/steering/coding-style.md .kiro/steering/env-config.md; do
  echo "" >> CLAUDE.md
  cat "$f" >> CLAUDE.md
done
```
