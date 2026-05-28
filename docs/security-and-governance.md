# Security & Governance — Making Agents Safe for Production

## Why This Matters

AI agents operate with the same permissions as the developer who runs them. An unguarded agent with AWS credentials can delete production databases, exfiltrate secrets, create wildcard IAM policies, deploy untested code, or install compromised dependencies.

Prompt-level safety ("please be careful") is insufficient. Research from JailbreakBench demonstrates near-100% attack success rates (ASR) against prompt-only defenses. You need deterministic enforcement at the application layer.

---

## OWASP Agentic Security Index (ASI) 2026

The OWASP ASI identifies 10 risk categories for AI agents in production:

| # | Risk Category | This Infrastructure's Mitigation |
|---|---|---|
| 1 | Excessive Agency | 5-tier risk classification limits tool access |
| 2 | Prompt Injection | Governance layer intercepts at application level |
| 3 | Insecure Output | postToolUse hooks validate all outputs |
| 4 | Tool Misuse | preToolUse hooks gate dangerous operations |
| 5 | Insufficient Logging | Every action logged with timestamp and tier |
| 6 | Insecure MCP Servers | Snyk Agent Scan audits MCP server security |
| 7 | Memory Poisoning | Temporal awareness prevents stale data attacks |
| 8 | Privilege Escalation | Environment modifiers escalate risk tiers |
| 9 | Supply Chain | Dependency pinning + security scanning |
| 10 | Denial of Service | Timeout controls on all hook commands |

---

## Why Prompt-Level Safety Fails

```
Traditional approach:
  System prompt: "Never run destructive commands"
  Agent: *receives jailbreak via injected context*
  Agent: *runs terraform destroy anyway*

Infrastructure approach:
  preToolUse hook intercepts the tool call
  Policy engine classifies: Tier 4 (FORBIDDEN)
  Tool call is BLOCKED before execution
  No prompt can override this — it is code, not instructions
```

The key insight: governance must be enforced in code that the agent cannot modify, not in prompts that the agent interprets.

---

## 5-Tier Risk Classification

Every tool invocation is classified into a risk tier before execution:

### Tier 0: Auto-Approve (No Gate)

Tools that are always safe — read-only with no side effects.

```yaml
tier_0_auto_approve:
  - read_file
  - read_files
  - readCode
  - grep_search
  - file_search
  - list_directory
  - getDiagnostics
  - mcp_memory_search_nodes
  - mcp_memory_read_graph
  - mcp_context7_*
  - mcp_aws_docs_*
  - remote_web_search
```

### Tier 1: Low Risk (Log Only)

Tools that modify local workspace files. Logged but not blocked.

```yaml
tier_1_log_only:
  - fs_write (workspace files)
  - fs_append (workspace files)
  - str_replace
  - delete_file (non-critical)
  - mcp_memory_create_entities
  - mcp_memory_create_relations
```

### Tier 2: Medium Risk (Validate Before Execute)

Tools that execute commands or query external systems. Intent is validated.

```yaml
tier_2_validate:
  - execute_bash (read-only: ls, cat, grep, terraform plan)
  - invoke_sub_agent
  - mcp_atlassian_* (read operations)
  - mcp_aws_cloudwatch_execute_log_insights_query
```

### Tier 3: High Risk (Gate + Confirm)

Tools that modify external state or incur costs. Requires justification.

```yaml
tier_3_gate:
  - execute_bash (write: aws create/put/delete, terraform apply)
  - mcp_atlassian_createJiraIssue
  - mcp_atlassian_createConfluencePage
  - mcp_aws_cloudwatch_* (write operations)
```

### Tier 4: Forbidden (Never Execute)

Actions that are absolutely prohibited regardless of context.

```yaml
tier_4_forbidden:
  - terraform destroy (any environment)
  - dbt run/build in production
  - DROP TABLE/DATABASE in production
  - aws s3 rb (bucket deletion)
  - IAM policies with Resource: "*"
  - Hardcoded credentials in any file
  - KMS key deletion
```

---

## Environment Modifiers

Risk tiers escalate based on the target environment:

| Base Tier | dev | qa | sim | prd |
|-----------|-----|-----|-----|-----|
| Tier 1 | Tier 1 | Tier 2 | Tier 3 | Tier 4 |
| Tier 2 | Tier 2 | Tier 3 | Tier 3 | Tier 4 |
| Tier 3 | Tier 3 | Tier 4 | Tier 4 | Tier 4 |

**Example:** Writing a file (Tier 1) in dev stays Tier 1. The same operation targeting a production config escalates to Tier 4 (FORBIDDEN).

---

## Microsoft AGT Integration

The Agent Governance Toolkit (AGT) provides the enforcement engine.

### Policy Definition (YAML)

```yaml
# .agt/policies/tool-policy.yaml
apiVersion: agt/v1
kind: ToolPolicy
metadata:
  name: production-safety
spec:
  rules:
    - name: block-terraform-destroy
      match:
        tool: execute_bash
        args_contain: "terraform destroy"
      action: DENY
      message: "terraform destroy is forbidden in all environments"

    - name: block-production-writes
      match:
        tool: execute_bash
        environment: [prd, sim]
        args_contain: ["terraform apply", "dbt run", "dbt build"]
      action: DENY
      message: "Write operations forbidden in this environment"

    - name: block-secret-hardcoding
      match:
        tool: [fs_write, fs_append, str_replace]
        content_matches: ["hardcoded-secret-pattern"]
      action: DENY
      message: "Hardcoded secrets detected. Use environment variables."
```

### AGT CLI Commands

```bash
# Verify all policies are valid and consistent
agt verify

# Lint policy YAML for syntax errors
agt lint-policy

# Run a dry-run simulation
agt simulate --tool execute_bash --args "terraform destroy" --env prd

# Check policy coverage (which tools are governed)
agt coverage

# Generate audit report
agt audit --since "7 days ago" --format json
```

---

## Snyk Agent Scan

MCP servers are external code that runs with your agent's permissions. Snyk Agent Scan audits them:

```bash
# Scan all configured MCP servers for vulnerabilities
snyk agent-scan --config .kiro/settings/mcp.json

# Scan a specific MCP server package
snyk test @modelcontextprotocol/server-memory

# Monitor for new vulnerabilities
snyk monitor --project-name="agent-mcp-servers"
```

What it checks:
- Known CVEs in MCP server dependencies
- Typosquatting detection on package names
- License compliance
- Malicious code patterns

---

## Cycode SAST Integration

For code-level security scanning of agent-generated code:

```bash
# Scan for SAST findings
cycode scan path .

# Scan for secrets
cycode scan --type secret path .

# Scan infrastructure-as-code
cycode scan --type iac path terraform/
```

Common findings in agent-generated code:
- CWE-918 (SSRF): Dynamic URLs passed to HTTP clients
- CWE-798 (Hardcoded Credentials): Tokens in source files
- CWE-89 (SQL Injection): String concatenation in queries
- CWE-22 (Path Traversal): Unsanitized file paths

---

## Audit Trail

Every agent action is logged with:

| Field | Description |
|-------|-------------|
| `timestamp` | ISO 8601 when the action occurred |
| `tool` | Which tool was invoked |
| `tier` | Risk classification (0-4) |
| `environment` | Target environment (dev/qa/sim/prd) |
| `action` | ALLOW, DENY, or GATE |
| `justification` | Why it was allowed/denied |
| `session_id` | Links to the agent session |

Audit logs are stored in:
- `work/FILE-CHANGE-LOG.md` — file modifications
- `.agt/audit/` — governance decisions
- CloudWatch Logs (if AWS integration enabled)

---

## Kill Switch Pattern

When you need to halt all agent operations immediately:

### Option 1: Environment Variable

```bash
# Set this to immediately block all Tier 1+ operations
export AGT_KILL_SWITCH=true
```

The governance engine checks this variable before every tool execution.

### Option 2: Policy Override

```yaml
# .agt/policies/kill-switch.yaml
apiVersion: agt/v1
kind: ToolPolicy
metadata:
  name: kill-switch
  priority: 0  # Highest priority — evaluated first
spec:
  rules:
    - name: block-everything
      match:
        tool: "*"
      action: DENY
      message: "Kill switch active. All agent operations suspended."
```

### Option 3: Hook Disable

```bash
# Remove all hooks to stop event-driven automation
rm .kiro/hooks/*.kiro.hook
# Or in Claude Code:
rm .claude/hooks.json
```

### Recovery

```bash
# Deactivate kill switch
unset AGT_KILL_SWITCH
# Or remove the kill-switch policy
rm .agt/policies/kill-switch.yaml
# Verify system is operational
agt verify
```

---

## Security Checklist for New Projects

Before enabling agents on a new codebase:

- [ ] Steering files include guardrails with absolute prohibitions
- [ ] preToolUse hook configured for shell and write operations
- [ ] AGT policies cover Tier 4 forbidden actions
- [ ] Environment detection works (dev/qa/sim/prd)
- [ ] No secrets in any committed file (run `detect-secrets scan`)
- [ ] MCP servers scanned with Snyk Agent Scan
- [ ] Audit logging enabled and writing to persistent storage
- [ ] Kill switch mechanism tested and documented
- [ ] Team knows how to activate kill switch
- [ ] Production environment is read-only in all policies
