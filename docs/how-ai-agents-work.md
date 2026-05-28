# How AI Coding Agents Work — A Technical Deep Dive

## What Is an AI Coding Agent?

An AI coding agent is not just a chatbot that writes code. It's an autonomous system composed of four core components working together:

```
┌─────────────────────────────────────────────────────────┐
│                    AI CODING AGENT                        │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌─────────┐  ┌─────────┐ │
│  │   LLM    │  │  Tools   │  │ Context │  │ Memory  │ │
│  │ (Brain)  │  │ (Hands)  │  │ (Eyes)  │  │ (Recall)│ │
│  └──────────┘  └──────────┘  └─────────┘  └─────────┘ │
│                                                          │
│  The LLM reasons. Tools act. Context informs.            │
│  Memory persists knowledge across sessions.              │
└─────────────────────────────────────────────────────────┘
```

**LLM (Large Language Model):** The reasoning engine. It interprets instructions, plans multi-step solutions, generates code, and decides which tools to invoke.

**Tools:** The agent's ability to affect the world — file reads/writes, terminal commands, web searches, API calls, database queries. Without tools, an LLM is just a text generator.

**Context:** Everything the agent can "see" at decision time — current files, project structure, steering files, conversation history, and tool outputs. Context is bounded by the model's context window (typically 100K-200K tokens).

**Memory:** Persistent knowledge that survives beyond a single session — session checkpoints, knowledge graphs, vector embeddings. Without memory, every conversation starts from zero.

---

## The Agent Loop: Think → Plan → Act → Observe → Repeat

Every agent operates on a fundamental loop:

```
         ┌──────────────────────────────────────┐
         │                                      │
         ▼                                      │
    ┌─────────┐    ┌─────────┐    ┌─────────┐  │
    │  THINK  │───▶│  PLAN   │───▶│   ACT   │  │
    │         │    │         │    │         │  │
    │ Analyze │    │ Choose  │    │ Execute │  │
    │ context │    │ tools & │    │ tool    │  │
    │         │    │ sequence│    │ calls   │  │
    └─────────┘    └─────────┘    └────┬────┘  │
                                       │       │
                                       ▼       │
                                  ┌─────────┐  │
                                  │ OBSERVE │  │
                                  │         │──┘
                                  │ Process │
                                  │ results │
                                  └─────────┘
```

1. **Think:** The agent reads the user's request plus all available context (steering files, open files, conversation history). It reasons about what needs to happen.

2. **Plan:** Based on its understanding, the agent decides which tools to call and in what order. Complex tasks get broken into sub-steps.

3. **Act:** The agent invokes tools — reads files, runs commands, writes code, searches the web. Each tool call is a discrete action with inputs and outputs.

4. **Observe:** The agent processes tool outputs. Did the command succeed? Did the file contain what was expected? Are there errors to handle?

5. **Repeat:** Based on observations, the agent decides whether the task is complete or needs more iterations. It loops until done or blocked.

This loop runs autonomously. A well-configured agent can execute dozens of iterations without human intervention — reading code, writing tests, fixing errors, and verifying results.

---

## Context Window Management

The context window is the agent's working memory — everything it can consider simultaneously. It's finite, and managing it well is the difference between a useful agent and a confused one.

### Why Steering Files Matter

Steering files are persistent instructions loaded into the agent's context at the start of every session. They solve a critical problem: **agents forget everything between sessions**.

```
Without Steering Files:
  Session 1: "Use snake_case for Python files"
  Session 2: Agent uses camelCase (forgot)
  Session 3: Agent uses PascalCase (forgot again)

With Steering Files:
  Every session: Agent reads coding-style.md → always uses snake_case
```

Steering files encode:
- **Coding standards** — how to write code in this project
- **Architecture decisions** — patterns to follow, anti-patterns to avoid
- **Safety rules** — what the agent must never do
- **Domain knowledge** — project-specific context that would take pages to explain each time

### Context Compaction

When the context window fills up, older content gets compressed or dropped. Strategic context management prevents losing critical information:

- **Front-load critical facts** — safety rules and key constraints go first
- **Delegate to sub-agents** — give isolated tasks fresh context windows
- **Use memory systems** — persist important facts outside the context window
- **Checkpoint progress** — save state so work can resume after compaction

---

## Tool Use via MCP (Model Context Protocol)

MCP is an open standard that defines how AI agents communicate with external tools and services. Think of it as USB for AI — a universal interface that lets any agent talk to any tool.

### How MCP Works

```
┌──────────┐         ┌──────────────┐         ┌──────────────┐
│  Agent   │◀──MCP──▶│  MCP Server  │◀───────▶│  External    │
│  (Client)│         │  (Adapter)   │         │  Service     │
└──────────┘         └──────────────┘         └──────────────┘

Examples:
  Agent ◀──MCP──▶ AWS MCP Server ◀──▶ AWS APIs
  Agent ◀──MCP──▶ Terraform MCP  ◀──▶ Terraform Registry
  Agent ◀──MCP──▶ Memory MCP     ◀──▶ Knowledge Graph DB
  Agent ◀──MCP──▶ Jira MCP       ◀──▶ Atlassian APIs
```

### MCP Message Flow

1. Agent decides it needs to call a tool (e.g., "read AWS documentation")
2. Agent sends a structured request to the MCP server
3. MCP server translates the request into the external service's API format
4. External service responds
5. MCP server formats the response back to the agent
6. Agent incorporates the result into its reasoning

### Why MCP Matters for Governance

MCP creates a **single interception point** for all tool calls. This means:
- Every action can be logged
- Policies can be enforced before execution
- Dangerous operations can be blocked deterministically
- Audit trails are automatic

---

## Multi-Agent Patterns

Complex tasks often exceed what a single agent can handle efficiently. Multi-agent architectures distribute work across specialized agents.

### Fan-Out Pattern

One orchestrator dispatches independent sub-tasks to multiple agents in parallel:

```
                    ┌─── Agent A (Terraform review) ───┐
                    │                                    │
Orchestrator ───────┼─── Agent B (Python linting) ──────┼──▶ Merge results
                    │                                    │
                    └─── Agent C (Security scan) ───────┘
```

**Use case:** PR review where different aspects can be checked independently.

### Pipeline Pattern

Agents process work sequentially, each building on the previous output:

```
Agent A ──▶ Agent B ──▶ Agent C ──▶ Final Output
(Research)   (Design)   (Implement)
```

**Use case:** Feature development where research informs design, which informs implementation.

### Supervisor Pattern

A supervisor agent monitors and coordinates worker agents:

```
         ┌─────────────┐
         │  Supervisor  │
         │  (Monitors,  │
         │   redirects) │
         └──────┬───────┘
                │
    ┌───────────┼───────────┐
    ▼           ▼           ▼
┌───────┐  ┌───────┐  ┌───────┐
│Worker │  │Worker │  │Worker │
│  A    │  │  B    │  │  C    │
└───────┘  └───────┘  └───────┘
```

**Use case:** Long-running tasks where workers might get stuck or need course correction.

### Player-Coach Pattern

A senior agent both does work AND coordinates other agents:

```
┌──────────────────────────────────┐
│  Player-Coach Agent              │
│  - Does complex reasoning        │
│  - Delegates routine work        │
│  - Reviews sub-agent output      │
│  - Makes final decisions         │
└──────────────┬───────────────────┘
               │
    ┌──────────┼──────────┐
    ▼                     ▼
┌────────────┐      ┌────────────┐
│ Specialist │      │ Specialist │
│ (dbt)      │      │ (Terraform)│
└────────────┘      └────────────┘
```

**Use case:** Domain-specific tasks where a generalist coordinates specialists.

---

## Memory: Session vs Persistent vs Semantic

Agents need different types of memory for different purposes:

### Session Memory (Short-Term)

- **Scope:** Single conversation
- **Content:** What was discussed, what files were read, what decisions were made
- **Persistence:** Lost when the session ends (unless checkpointed)
- **Format:** Conversation history in the context window

### Persistent Memory (Long-Term)

- **Scope:** Across all sessions
- **Content:** Patterns, decisions, entity relationships, project knowledge
- **Persistence:** Stored in a knowledge graph or structured files
- **Format:** Entities + relationships (e.g., "Pattern X was used to fix Bug Y")

### Semantic Memory (Fuzzy Recall)

- **Scope:** Across all sessions
- **Content:** Embeddings of past interactions, code snippets, documentation
- **Persistence:** Stored in a vector database
- **Format:** High-dimensional vectors that enable similarity search
- **Query:** "What's similar to this problem?" → retrieves relevant past context

```
┌─────────────────────────────────────────────────────┐
│                  MEMORY HIERARCHY                     │
│                                                      │
│  Session Memory    ← Fast, limited, ephemeral        │
│       │                                              │
│       ▼                                              │
│  Persistent Memory ← Structured, durable, queryable │
│       │                                              │
│       ▼                                              │
│  Semantic Memory   ← Fuzzy, associative, vast        │
└─────────────────────────────────────────────────────┘
```

---

## Governance: Why Prompt-Level Safety Isn't Enough

### The Problem with "Please Don't Do Bad Things"

Most AI safety today relies on prompt-level instructions:

```
System prompt: "Never delete production databases"
```

This is necessary but insufficient. Research shows:

- **JailbreakBench (2024):** Near-100% attack success rate against prompt-level defenses
- **OWASP Agentic Security Index (ASI) 2026:** Identifies 10 risk categories specific to AI agents
- **Real-world incidents:** Agents bypassing safety instructions through indirect prompt injection, tool misuse, and context manipulation

### The Difference: Asking vs Making

| Approach | Mechanism | Bypass Difficulty |
|----------|-----------|-------------------|
| Prompt-level safety | "Please don't do X" | Trivial (prompt injection) |
| Application-layer enforcement | Intercept tool calls, block forbidden actions | Requires exploiting the enforcement layer itself |

**Asking an agent to behave** = putting a sign on the door that says "Please don't enter"

**Making an agent incapable of misbehaving** = removing the door entirely

### Application-Layer Enforcement

Instead of relying on the LLM to self-police, intercept at the tool execution layer:

```
Agent wants to run: terraform destroy --auto-approve
                         │
                         ▼
              ┌─────────────────────┐
              │   POLICY ENGINE     │
              │                     │
              │ Rule: BLOCK all     │
              │ terraform destroy   │
              │ in prd environment  │
              │                     │
              │ Result: DENIED      │
              └─────────────────────┘
                         │
                         ▼
              Agent receives: "Action blocked by policy.
              Reason: terraform destroy is forbidden in prd."
```

The agent never gets to execute the dangerous action. The policy engine operates independently of the LLM's reasoning — it doesn't matter if the agent was tricked, confused, or deliberately trying to bypass safety. The enforcement is deterministic.

### OWASP ASI 2026 — 10 Risk Categories

The OWASP Agentic Security Index identifies these risk areas for AI agents:

1. **Excessive Agency** — Agent has more permissions than needed
2. **Uncontrolled Tool Access** — No governance over which tools can be called
3. **Prompt Injection** — Malicious instructions embedded in data
4. **Insecure Output Handling** — Agent output used unsafely downstream
5. **Insufficient Monitoring** — No visibility into agent actions
6. **Inadequate Sandboxing** — Agent can affect systems beyond its scope
7. **Supply Chain Vulnerabilities** — Compromised MCP servers or plugins
8. **Memory Poisoning** — Corrupted persistent memory influencing decisions
9. **Multi-Agent Coordination Failures** — Agents working at cross-purposes
10. **Privilege Escalation** — Agent gaining capabilities beyond its authorization

A comprehensive agent infrastructure must address all 10 categories — not just the ones that are easy to solve with prompts.

---

## Summary

AI coding agents are powerful but dangerous without proper infrastructure. The key insights:

1. **Agents are loops, not one-shots** — they iterate autonomously
2. **Context is finite** — steering files and memory systems extend effective context
3. **MCP standardizes tool access** — creating a universal interception point
4. **Multi-agent patterns scale** — but add coordination complexity
5. **Memory enables continuity** — without it, every session starts from scratch
6. **Governance must be deterministic** — prompt-level safety is necessary but insufficient

The rest of this documentation covers how to build the infrastructure that makes agents safe, effective, and production-ready.
