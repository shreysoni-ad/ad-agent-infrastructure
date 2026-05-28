# Getting Started — Zero to Governed Agents in 10 Minutes

## Prerequisites

Before you begin, ensure you have:

| Requirement | Version | Check Command |
|-------------|---------|---------------|
| Docker | 24+ | `docker --version` |
| Docker Compose | v2+ | `docker compose version` |
| Python | 3.11+ | `python3 --version` |
| Node.js | 18+ | `node --version` |
| npm | 9+ | `npm --version` |
| IDE | Kiro or Claude Code | — |

Optional (for full feature set):
- AWS CLI v2 (for AWS MCP servers)
- Terraform CLI (for IaC governance)
- Git (for version control hooks)

---

## Step 1: Clone This Repo

```bash
git clone <YOUR_REPO_URL>
cd ad-agent-infrastructure
```

---

## Step 2: Run install.sh

The install script copies the infrastructure into your project:

```bash
chmod +x install.sh
./install.sh
```

**What it does:**
1. Creates `.kiro/steering/` with all steering files
2. Creates `.kiro/hooks/` with security and automation hooks
3. Creates `.kiro/settings/mcp.json` with MCP server configuration
4. Creates `.agt/policies/` with governance policy YAML files
5. Creates `work/` directory for memory and session storage
6. Creates `docker-compose.yml` for memory services
7. Generates `.mcp.json` for Claude Code compatibility

**What it does NOT do:**
- Install any secrets or tokens
- Modify your existing code
- Start any services
- Make network requests

---

## Step 3: Start Docker Services

```bash
docker compose up -d
```

This starts the memory infrastructure:

| Service | Port | Purpose |
|---------|------|---------|
| ChromaDB | 8000 | Semantic memory (vector embeddings) |
| FalkorDB | 6379 | Temporal knowledge graph (Graphiti) |

Verify services are running:
```bash
docker compose ps
```

Expected output:
```
NAME        STATUS    PORTS
chromadb    running   0.0.0.0:8000->8000/tcp
falkordb   running   0.0.0.0:6379->6379/tcp
```

---

## Step 4: Configure Tokens

**CRITICAL: Never hardcode tokens. Always use environment variables.**

### AWS

Use SSO login — no long-lived credentials needed:

```bash
# Configure your SSO profile (one-time setup)
aws configure sso
# Profile name: your-profile
# SSO start URL: <YOUR_SSO_START_URL>
# SSO region: <YOUR_REGION>
# Account ID: <YOUR_ACCOUNT_ID>
# Role: <YOUR_ROLE_NAME>

# Login (do this when your session expires)
aws sso login --profile <YOUR_PROFILE>

# Verify
aws sts get-caller-identity --profile <YOUR_PROFILE>
```

### GitHub

Generate a Personal Access Token for the GitHub MCP server:

1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Select scopes: `repo`, `read:org`, `read:project`
4. Copy the token

```bash
# Add to your shell profile (~/.bashrc or ~/.zshrc)
export GITHUB_TOKEN="<YOUR_TOKEN_HERE>"
```

### Databricks

Generate a PAT for the Databricks MCP server:

1. Open your Databricks workspace
2. Go to User Settings > Developer > Access Tokens
3. Click "Generate New Token"
4. Set a comment and expiration

```bash
export DATABRICKS_HOST="<YOUR_WORKSPACE_URL>"
export DATABRICKS_TOKEN="<YOUR_TOKEN_HERE>"
```

### Snyk

Get your token for security scanning:

1. Go to https://app.snyk.io/account
2. Copy your API token

```bash
export SNYK_TOKEN="<YOUR_TOKEN_HERE>"
```

### Token Storage Best Practices

| Approach | Security | Convenience |
|----------|----------|-------------|
| Shell profile (`~/.zshrc`) | Medium | High |
| `.env` file (gitignored) | Medium | High |
| OS keychain | High | Medium |
| Secret manager (AWS/Vault) | Highest | Low (for local dev) |

**Never commit tokens to git.** Add to `.gitignore`:
```
.env
.env.local
*.pem
*.key
```

---

## Step 5: Verify Installation

### Check AGT Policies

```bash
# Install AGT CLI if not already installed
npm install -g @microsoft/agent-governance-toolkit

# Verify all policies are valid
agt verify

# Expected output:
# All policies valid.
```

### Check Steering Files

```bash
# Count steering files
ls .kiro/steering/*.md | wc -l

# Verify no secrets in steering files
grep -rn "password\|secret\|token\|api_key" .kiro/steering/ || echo "Clean: no secrets found"
```

### Run Full Doctor Check

```bash
agt doctor
```

This checks:
- All policy files are valid YAML
- All steering files are valid markdown
- MCP server binaries are available
- Docker services are running
- No secrets detected in committed files
- Hook files are valid JSON

---

## Step 6: Seed the Knowledge Graph

Start your IDE (Kiro or Claude Code) and ask the agent:

```
Seed the knowledge graph with core platform entities from the steering files.
```

The agent will:
1. Read your steering files
2. Extract key entities (clients, services, patterns, decisions)
3. Create entities in the knowledge graph via Memory MCP
4. Establish relationships between entities

Verify the seed worked:
```
Ask: "What entities are in the knowledge graph?"
```

---

## Step 7: Start Working

That is it. The infrastructure is now active. Here is what happens automatically:

### On Every Session Start
- Steering files load into agent context (guardrails, coding style, env config)
- Memory MCP connects (knowledge graph available for recall)
- Hooks are armed (preToolUse, postToolUse, fileEdited, agentStop)

### On Every Tool Call
- preToolUse hook validates the action
- Policy engine classifies the risk tier
- Tier 4 actions are blocked
- Tier 3 actions require justification

### On Every File Edit
- Lint hooks auto-format code
- Security hooks check for secrets
- File change log is updated

### On Session End
- Memory sync hook persists new learnings
- Session checkpoint captures work state
- Audit trail is complete

---

## Troubleshooting Common Issues

### Docker services will not start

```bash
# Check if ports are already in use
lsof -i :8000  # ChromaDB
lsof -i :6379  # FalkorDB

# Kill conflicting processes or change ports in docker-compose.yml
```

### AGT verify fails

```bash
# Check YAML syntax
agt lint-policy

# Common issue: indentation errors in policy YAML
# Fix: use 2-space indentation, no tabs
```

### MCP server not connecting in Kiro

1. Open Kiro's output panel (View > Output)
2. Select "MCP Servers" from the dropdown
3. Look for error messages
4. Common fix: restart Kiro after changing mcp.json

### Memory not persisting between sessions

```bash
# Check the memory file exists and is writable
ls -la work/memory-graph.json

# If missing, create it
echo '{"entities":[],"relations":[]}' > work/memory-graph.json

# Check the agentStop hook is configured
cat .kiro/hooks/memory-sync.kiro.hook
```

### Hooks not firing

1. Verify hook files are valid JSON (no trailing commas)
2. Check `eventType` matches the expected trigger
3. For `preToolUse`, verify `toolTypes` includes the tool category
4. Restart the IDE after adding new hooks

### Agent ignores guardrails

This usually means steering files are not loading:
1. Check `.kiro/steering/guardrails.md` exists
2. Verify the frontmatter has `inclusion: always`
3. Restart Kiro to force reload
4. If using Claude Code, verify CLAUDE.md contains the guardrails

### Permission denied on work/ directory

```bash
# Fix permissions
chmod -R 755 work/
chmod 666 work/memory-graph.json
```

---

## What is Next

Once you are up and running:

1. **Customize steering files** — add your project's specific conventions
2. **Add domain hooks** — create hooks for your tech stack (dbt, Terraform, etc.)
3. **Tune policies** — adjust risk tiers for your team's comfort level
4. **Seed more memory** — the more the agent knows, the better it performs
5. **Review audit logs** — check `.agt/audit/` for governance decisions

For deeper dives:
- [Infrastructure Overview](./infrastructure-overview.md) — how all layers work together
- [Security and Governance](./security-and-governance.md) — policy engine details
- [Memory System](./memory-system.md) — 3-tier memory architecture
- [Kiro Integration](./kiro-integration.md) — Kiro-specific setup
- [Claude Code Integration](./claude-code-integration.md) — Claude Code setup
