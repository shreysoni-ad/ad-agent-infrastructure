# MCP Servers Inventory

22 MCP servers configured across workspace and user settings.

## Enabled (15 servers)

| # | Server | Transport | Purpose | Status |
|---|--------|-----------|---------|--------|
| 1 | `aws-docs` | stdio (uvx) | Search/read AWS documentation | Active |
| 2 | `aws-cloudwatch` | stdio (uvx) | CloudWatch logs, metrics, alarms | Active |
| 3 | `aws-cloudtrail` | stdio (uvx) | CloudTrail event querying and audit | Active |
| 4 | `aws-iam` | stdio (uvx) | IAM policy analysis (read-only) | Active |
| 5 | `aws-data-processing` | stdio (uvx) | Glue, EMR, Athena pipeline visibility | Active |
| 6 | `aws-sns-sqs` | stdio (uvx) | SQS/SNS queue and topic management | Active |
| 7 | `aws-step-functions` | stdio (uvx) | Step Functions workflow execution | Active |
| 8 | `aws-cost-analysis` | stdio (uvx) | AWS billing and cost estimation | Active |
| 9 | `aws-diagram` | stdio (uvx) | Architecture diagram generation | Active |
| 10 | `terraform` | stdio (npx) | Terraform registry lookup | Active |
| 11 | `context7` | stdio (npx) | Library documentation lookup | Active |
| 12 | `sequential-thinking` | stdio (npx) | Multi-step reasoning chains | Active |
| 13 | `cycode` | stdio (cli) | SAST, secrets, SCA, IaC scanning | Active |
| 14 | `atlassian` | HTTP SSE | Jira + Confluence (all projects) | Active |
| 15 | `alterdomus` | HTTP SSE | Internal AlterDomus APIs | Active |

## Disabled (7 servers — need configuration)

| # | Server | Transport | Purpose | Missing Config |
|---|--------|-----------|---------|---------------|
| 16 | `databricks` | stdio (npx) | Workspace, jobs, clusters, SQL | Host URL + PAT |
| 17 | `snowflake` | stdio | Snowflake queries and management | Account + credentials |
| 18 | `github` | stdio (npx) | PRs, issues, commits, CI status | Personal access token |
| 19 | `aws-iac` | stdio (uvx) | IaC analysis | Just disabled |
| 20 | `aws-cfn` | stdio (uvx) | CloudFormation (read-only) | Just disabled |
| 21 | `memory` | stdio (npx) | Knowledge graph persistence | Just disabled |
| 22 | `playwright` | stdio (npx) | Browser automation for E2E | Just disabled |

## Configuration Locations

- Workspace: `.kiro/settings/mcp.json`
- User-level: `~/.kiro/settings/mcp.json`

## Enabling a Disabled Server

1. Open the relevant `mcp.json` file
2. Find the server entry
3. Set `"disabled": false`
4. Add required environment variables (tokens, URLs)
5. Restart Kiro IDE

## Server Categories

### AWS Observability
`aws-cloudwatch`, `aws-cloudtrail`, `aws-cost-analysis`

### AWS Infrastructure
`aws-docs`, `aws-iam`, `aws-data-processing`, `aws-sns-sqs`, `aws-step-functions`, `aws-diagram`, `aws-iac`, `aws-cfn`

### Development Tools
`terraform`, `context7`, `sequential-thinking`, `cycode`, `github`

### Data Platforms
`databricks`, `snowflake`

### Collaboration
`atlassian`, `alterdomus`

### Utilities
`memory`, `playwright`
