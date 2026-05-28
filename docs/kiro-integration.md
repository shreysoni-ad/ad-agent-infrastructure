# Integration with Kiro IDE

## Overview

This infrastructure was built natively for Kiro. Every layer — steering files, hooks, MCP servers, sub-agents, and powers — integrates directly with Kiro's architecture without adapters or plugins.

Kiro provides first-class support for:
- Steering files with conditional loading (always, fileMatch, manual)
- Hook definitions with a visual editor
- MCP server management with a UI
- Custom sub-agents for domain-specific tasks
- A marketplace (Powers) for pre-built integrations

---

## Steering Files

Location: `.kiro/steering/*.md`

Each steering file is a markdown document with a YAML frontmatter header that controls when it loads:

```markdown
---
inclusion: always
---

# Guardrails — Hard Rules

These rules are NON-NEGOTIABLE...
```

### Inclusion Modes

| Mode | Behavior | Use For |
|------|----------|---------|
| `always` | Loaded in every session | Guardrails, coding style, env config |
| `fileMatch` | Loaded when agent touches matching files | Domain-specific guidance (dbt, Terraform) |
| `manual` | Loaded only when explicitly requested | Rarely-needed reference material |

### fileMatch Example

```markdown
---
inclusion: fileMatch
filePatterns:
  - "**/*.sql"
  - "**/dbt/**"
---

# dbt Patterns

Use ref() over hardcoded table names...
```

### Recommended Steering File Structure

```
.kiro/steering/
├── guardrails.md              # [always] Hard rules, absolute prohibitions
├── coding-style.md            # [always] Universal code conventions
├── env-config.md              # [always] Environment details (no secrets!)
├── tool-policy-engine.md      # [always] Risk tier classification
├── memory-management.md       # [always] How memory works
├── git-workflow.md            # [always] Commit, branch, PR conventions
├── troubleshooting.md         # [always] Known error patterns
├── data-engineering.md        # [fileMatch: *.sql, dbt/**] dbt/ETL patterns
├── infrastructure.md          # [fileMatch: *.tf] Terraform/K8s patterns
├── cloud.md                   # [fileMatch: *.tf] AWS/GCP/Azure patterns
├── security.md                # [fileMatch: *.py, *.tf] Security review
└── advanced-patterns.md       # [manual] Debugging, refactoring, incidents
```

---

## Hooks

Location: `.kiro/hooks/*.kiro.hook`

Hooks are JSON files that define event-driven automations:

```json
{
  "id": "security-pre-tool",
  "name": "Security Gate",
  "description": "Validates tool calls before execution for security violations",
  "eventType": "preToolUse",
  "hookAction": "askAgent",
  "toolTypes": "write,shell",
  "outputPrompt": "Before executing, verify: no secrets hardcoded, no destructive operations in production environments, no wildcard IAM permissions. If any violation is detected, BLOCK the action."
}
```

### Hook Examples in This Infrastructure

| Hook | Event | Purpose |
|------|-------|---------|
| `security-pre-tool` | `preToolUse` | Block dangerous operations |
| `cycode-post-write` | `postToolUse` | Run SAST after code writes |
| `lint-on-save` | `fileEdited` | Auto-format Python/SQL on save |
| `memory-sync` | `agentStop` | Persist learnings to knowledge graph |
| `session-checkpoint` | `agentStop` | Save session state to markdown |
| `file-change-log` | `postToolUse` | Track all file modifications |

### Hook Schema

```json
{
  "id": "string (kebab-case, 3 words max)",
  "name": "string (short title)",
  "description": "string (what it does)",
  "eventType": "preToolUse | postToolUse | fileEdited | fileCreated | fileDeleted | agentStop | promptSubmit | userTriggered",
  "hookAction": "askAgent | runCommand",
  "toolTypes": "string (comma-separated: read, write, shell, web, spec, *)",
  "filePatterns": "string (glob patterns, comma-separated)",
  "outputPrompt": "string (for askAgent actions)",
  "command": "string (for runCommand actions)",
  "timeout": "number (seconds, for runCommand)"
}
```

---

## MCP Servers

Location: `.kiro/settings/mcp.json`

```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-memory"],
      "env": {
        "MEMORY_FILE": "${workspaceFolder}/work/memory-graph.json"
      }
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-sequential-thinking"]
    },
    "aws-docs": {
      "command": "uvx",
      "args": ["awslabs.aws-documentation-mcp-server@latest"]
    },
    "terraform": {
      "command": "npx",
      "args": ["@hashicorp/terraform-mcp-server@latest"]
    },
    "context7": {
      "command": "npx",
      "args": ["@upstash/context7-mcp@latest"]
    }
  }
}
```

### Adding a New MCP Server

1. Add the entry to `.kiro/settings/mcp.json`
2. Ensure any required environment variables are set (never hardcode tokens)
3. Restart Kiro or reload the MCP configuration
4. Verify with: ask the agent to use a tool from the new server

---

## Sub-Agents

Kiro supports custom sub-agents for domain-specific tasks. Define them in `.kiro/agents/`:

```json
{
  "name": "security-specialist",
  "description": "Reviews code for security vulnerabilities using OWASP guidelines",
  "prompt": "You are a security specialist. Review the provided code for...",
  "tools": ["readCode", "grep_search", "getDiagnostics"]
}
```

### Sub-Agents in This Infrastructure

| Agent | Purpose |
|-------|---------|
| `context-gatherer` | Explores repo structure before making changes |
| `security-specialist` | Reviews code for vulnerabilities |
| `dbt-specialist` | Domain expert for dbt models and macros |
| `terraform-specialist` | Infrastructure code review |
| `qa-specialist` | Test generation and coverage analysis |

---

## Powers

Powers are Kiro marketplace packages that bundle documentation, MCP servers, and steering files. This infrastructure complements these powers:

| Power | What It Adds |
|-------|-------------|
| `aws-amplify` | Full-stack AWS patterns |
| `terraform` | Terraform registry + MCP tools |
| `context7` | Library documentation lookup |
| `postman` | API testing automation |

Activate a power:
```
kiroPowers action="activate" powerName="terraform"
```

---

## Step-by-Step Setup

### Step 1: Run install.sh

```bash
git clone <YOUR_REPO_URL>
cd ad-agent-infrastructure
chmod +x install.sh
./install.sh
```

This copies the `.kiro/` structure into your project, including steering files, hooks, and MCP configuration.

### Step 2: Start Docker Services

```bash
docker compose up -d
```

This starts:
- ChromaDB (semantic memory vector store)
- FalkorDB (Graphiti temporal knowledge graph)
- Memory MCP server (if running as a container)

### Step 3: Configure API Tokens

**Never hardcode tokens.** Set them as environment variables:

```bash
# AWS — use SSO login
aws sso login --profile <YOUR_PROFILE>

# GitHub — generate a PAT
# Go to: github.com/settings/tokens
export GITHUB_TOKEN="<YOUR_TOKEN_HERE>"

# Databricks — generate a PAT
# Go to: Workspace > User Settings > Developer > Access Tokens
export DATABRICKS_TOKEN="<YOUR_TOKEN_HERE>"
export DATABRICKS_HOST="<YOUR_WORKSPACE_URL>"

# Snyk — get token
# Go to: app.snyk.io/account
export SNYK_TOKEN="<YOUR_TOKEN_HERE>"
```

### Step 4: Verify Installation

```bash
# Check AGT policies
agt verify

# Check all steering files are valid markdown
find .kiro/steering -name "*.md" -exec echo "OK: {}" \;

# Check MCP servers can start
npx @modelcontextprotocol/server-memory --help

# Check Docker services
docker compose ps
```

---

## Directory Structure After Installation

```
your-project/
├── .kiro/
│   ├── steering/
│   │   ├── guardrails.md
│   │   ├── coding-style.md
│   │   ├── env-config.md
│   │   ├── tool-policy-engine.md
│   │   ├── memory-management.md
│   │   └── ...
│   ├── hooks/
│   │   ├── security-pre-tool.kiro.hook
│   │   ├── memory-sync.kiro.hook
│   │   ├── lint-on-save.kiro.hook
│   │   └── ...
│   ├── settings/
│   │   └── mcp.json
│   └── agents/
│       ├── security-specialist.json
│       └── ...
├── .agt/
│   └── policies/
│       ├── tool-policy.yaml
│       ├── environment-policy.yaml
│       └── secret-policy.yaml
├── work/
│   ├── memory-graph.json
│   └── sessions/
├── docker-compose.yml
└── install.sh
```

---

## Troubleshooting

### Steering files not loading
- Check the frontmatter `inclusion` field is valid
- For `fileMatch`, verify the glob pattern matches your files
- Restart Kiro if you just added a new steering file

### Hooks not firing
- Check the `eventType` matches the expected trigger
- For `preToolUse`, verify `toolTypes` includes the tool category
- Check the hook file is valid JSON (no trailing commas)

### MCP server not connecting
- Run the server command manually to check for errors
- Verify environment variables are set in your shell
- Check `.kiro/settings/mcp.json` for syntax errors
- Look at Kiro's MCP server logs in the output panel

### Memory not persisting
- Verify `work/memory-graph.json` exists and is writable
- Check the Memory MCP server is running (not disabled)
- Verify the `agentStop` hook is configured correctly
