# 3-Tier Memory System — How Agents Remember Across Sessions

## The Problem: Agents Forget Everything

Every time an agent session ends, all context is lost. Decisions made, patterns discovered, bugs investigated, conventions learned — gone. Without memory, agents repeat mistakes, re-discover patterns, and ask the same questions every session.

---

## Architecture: 3 Tiers of Memory

```
┌─────────────────────────────────────────────────────────────┐
│                  Tier 3: Semantic Memory                      │
│          ChromaDB vector embeddings for fuzzy recall          │
│     "What pattern do we use for..." → nearest neighbors      │
├─────────────────────────────────────────────────────────────┤
│                  Tier 2: Knowledge Graph                      │
│       Entities + Relationships via Memory MCP Server         │
│     Patterns, Decisions, Bugs, Clients, Services             │
├─────────────────────────────────────────────────────────────┤
│                  Tier 1: Session Checkpoints                  │
│         Markdown files with structured session state          │
│     Detailed what-was-done, files changed, next steps        │
└─────────────────────────────────────────────────────────────┘
```

| Tier | Best For | Query Style |
|------|----------|-------------|
| 1 - Checkpoints | "Continue the work from yesterday" | Date/topic lookup |
| 2 - Knowledge Graph | "What caused that Iceberg rebuild?" | Entity/relationship traversal |
| 3 - Semantic | "What pattern do we use for X?" | Fuzzy similarity search |

---

## Tier 1: Session Checkpoints

### What They Are

Markdown files that capture the complete state of a work session. Created automatically when the agent session ends (via the `agentStop` hook).

### Storage Location

```
work/sessions/
├── 2026-05-28-sharepoint-ingestion.md
├── 2026-05-27-iceberg-partition-fix.md
├── 2026-05-26-dbt-model-refactor.md
└── ...
```

### Format

```markdown
# Session: SharePoint Ingestion Pipeline
Date: 2026-05-28
Branch: feature/DATA-69
Status: In Progress

## What Was Done
- Created sharepoint_utils.py with Graph API integration
- Implemented SSRF taint chain fix for Cycode SAST
- Uploaded test CSV to dev raw bucket

## Files Modified
- notebooks/common_utils/sharepoint_utils.py
- resources/jobs/sharepoint_atomic_spreadsheet_ingest.yml

## Decisions Made
- Chose dbutils.fs.put() over boto3 for S3 writes (serverless limitation)
- Used per-sheet CSV split instead of single Excel upload (binary corruption)

## Blockers / Next Steps
- [ ] Graph API pagination not implemented (caps at 100 files)
- [ ] Need to test with production-scale folder (>100 items)

## Key Learnings
- Serverless compute blocks dbutils.fs.cp from local filesystem
- _validate_graph_url() must return str, not None, to break taint chain
```

### When to Use

- "Continue the DATA-69 work" → agent reads the checkpoint
- "What did I do last Tuesday?" → agent finds by date
- "What is the status of the SharePoint pipeline?" → agent reads latest checkpoint

---

## Tier 2: Knowledge Graph

### What It Is

A JSON-based graph of entities and relationships, persisted via the Memory MCP server. Unlike session checkpoints (which are detailed and temporal), the knowledge graph stores durable facts.

### Storage

```
work/memory-graph.json
```

### Entity Types

| Type | Examples |
|------|----------|
| `Pattern` | SSRF taint chain fix, Iceberg partition strategy |
| `Decision` | Chose append-only audit, chose per-env workspaces |
| `Bug` | DD-157 too many partitions, AIDE-1245 Iceberg rebuild |
| `Client` | Generali, Partners Group, Legal and General |
| `DataSource` | atomic_spreadsheet, cepres, yardi, preqin |
| `Service` | MWAA, Databricks, Athena, Glue, Lake Formation |
| `Ticket` | DATA-130, DD-69, DD-77 (with status observations) |

### Relationship Types

```
Pattern ──implements──> Ticket
Bug ──caused_by──> Pattern
Bug ──fixed_by──> Ticket
Model ──belongs_to──> Client
Model ──reads_from──> DataSource
DAG ──produces──> Model
Service ──depends_on──> Service
```

### Querying the Knowledge Graph

The Memory MCP server provides these tools:

```
mcp_memory_search_nodes  → Fuzzy search across all entities
mcp_memory_open_nodes    → Get specific entities by name
mcp_memory_read_graph    → Read the entire graph
```

**Example queries:**
- "What pattern do we use for SSRF fixes?" → searches for Pattern entities
- "What bugs has the Generali client had?" → traverses Client to Bug relationships
- "What is the status of DD-69?" → opens the Ticket entity

### Adding to the Knowledge Graph

```
mcp_memory_create_entities  → Create new entities with observations
mcp_memory_create_relations → Link entities together
mcp_memory_add_observations → Add facts to existing entities
```

---

## Tier 3: Semantic Memory

### What It Is

Vector embeddings stored in ChromaDB that enable fuzzy recall. When the agent asks "what pattern do we use for handling rate limits?", semantic memory finds the closest match even if the exact words differ.

### How It Works

```
1. Agent learns something → text is embedded as a vector
2. Agent needs to recall → query is embedded and compared
3. Nearest neighbors returned → agent gets relevant context
```

### Storage

ChromaDB runs as a Docker container:

```yaml
# docker-compose.yml
services:
  chromadb:
    image: chromadb/chroma:latest
    ports:
      - "8000:8000"
    volumes:
      - ./work/chromadb-data:/chroma/chroma
    environment:
      - ANONYMIZED_TELEMETRY=false
```

### When Semantic Memory Helps

| Query | Knowledge Graph | Semantic Memory |
|-------|----------------|-----------------|
| "What is the SSRF fix pattern?" | Exact match on entity | Works |
| "How do we handle tainted URLs?" | Might miss (different words) | Finds via similarity |
| "Rate limiting strategy" | Only if entity exists | Finds related patterns |

---

## Temporal Awareness

### Date-Prefixed Observations

Every observation in the knowledge graph includes a date prefix:

```
Entity: "DD-157 Iceberg Partition Bug"
Observations:
  - "[2026-03-31] Discovered: per-second partition granularity causing too many open partitions"
  - "[2026-03-31] Hotfix applied: reduced to per-day partitions with DATE_TRUNC"
  - "[2026-03-31] Hotfix reverted: partition change triggered unexpected behavior"
  - "[2026-04-01] Root cause confirmed: Iceberg partition evolution does not rewrite existing data"
```

### Time-Travel Queries

Temporal prefixes enable questions like:
- "What happened with DD-157 last week?"
- "When was the SSRF pattern first used?"
- "What changed about the Generali pipeline in March?"

---

## Automatic Memory Sync

### The agentStop Hook

When a session ends, the `memory-sync` hook fires:

```json
{
  "id": "memory-sync-on-stop",
  "name": "Memory Sync",
  "eventType": "agentStop",
  "hookAction": "askAgent",
  "outputPrompt": "Before ending, persist any new patterns, decisions, or bugs learned this session to the knowledge graph. Create entities for new concepts and add observations to existing ones. Include date prefixes on all observations."
}
```

### What Gets Synced

| Session Activity | Memory Action |
|-----------------|---------------|
| Fixed a bug | Create Bug entity + observations |
| Made an architectural decision | Create Decision entity |
| Discovered a new pattern | Create Pattern entity |
| Worked on a ticket | Update Ticket entity status |
| Learned a new convention | Add observation to relevant entity |

---

## Graphiti Integration (Temporal Knowledge Graphs)

For advanced temporal reasoning, this infrastructure supports Graphiti with FalkorDB:

```yaml
# docker-compose.yml
services:
  falkordb:
    image: falkordb/falkordb:latest
    ports:
      - "6379:6379"
    volumes:
      - ./work/falkordb-data:/data
```

### What Graphiti Adds

- **Temporal edges**: relationships have valid_from/valid_to timestamps
- **Contradiction resolution**: newer facts supersede older ones
- **Episodic memory**: full session transcripts stored as episodes
- **Community detection**: automatic clustering of related entities

### When to Use Graphiti vs Memory MCP

| Feature | Memory MCP | Graphiti |
|---------|-----------|----------|
| Setup complexity | Low (JSON file) | Medium (FalkorDB + Python) |
| Temporal reasoning | Manual (date prefixes) | Native (temporal edges) |
| Contradiction handling | Manual | Automatic |
| Scale | Hundreds of entities | Thousands of entities |
| Query language | Simple search | Cypher queries |

---

## Memory Consolidation Rules

Over time, the knowledge graph accumulates observations. Consolidation keeps it useful:

### Archiving

Observations older than 90 days that have been superseded are archived:
```
Before: "[2026-01-15] DD-69 status: in development"
After archiving: (removed — superseded by "[2026-03-30] DD-69 status: merged")
```

### Superseding

When a newer observation contradicts an older one, the older is marked:
```
"[2026-03-31] SUPERSEDED: Hotfix applied for DD-157"
"[2026-03-31] CURRENT: Hotfix reverted — partition change caused issues"
```

### Merging

When multiple entities describe the same concept, merge them:
```
Before: "SSRF Fix" entity + "Taint Chain Breaking" entity
After: Single "SSRF Taint Chain Fix" entity with combined observations
```

---

## Seeding the Knowledge Graph

On first use, seed the graph with core platform knowledge:

```
Ask the agent: "Seed the knowledge graph with core platform entities"
```

This creates:
- Client entities (with IDs and data sources)
- Service entities (MWAA, Databricks, Athena, etc.)
- Known bug patterns (from troubleshooting docs)
- Architectural decisions (from steering files)
- Key relationships between all entities

---

## Configuration

### Minimal Setup (Tier 1 + Tier 2 only)

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

### Full Setup (All 3 Tiers)

```yaml
# docker-compose.yml
services:
  chromadb:
    image: chromadb/chroma:latest
    ports:
      - "8000:8000"
    volumes:
      - ./work/chromadb-data:/chroma/chroma

  falkordb:
    image: falkordb/falkordb:latest
    ports:
      - "6379:6379"
    volumes:
      - ./work/falkordb-data:/data
```

Plus the Memory MCP server in your IDE configuration.
