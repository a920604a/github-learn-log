# Graphify-Labs/graphify — raw

- URL: https://github.com/Graphify-Labs/graphify
- Description: Turn any codebase, with its docs, SQL schemas, configs, and PDFs, into a queryable knowledge graph. A /graphify skill for Claude Code, Cursor, Codex, Antigravity, Gemini CLI and more.
- Language: Python
- Topics: ai-agents, antigravity, ast, claude-code, code-analysis, code-search, codex, cursor, developer-tools, gemini, graphrag, knowledge-graph, leiden, llm, mcp, openclaw, rag, skills, tree-sitter
- Stars: 96012
- License: Apache-2.0
- Size: 8,329 KB
- Fetched: 2026-07-26 (catch-up)

## README (excerpt)

Type `/graphify` in your AI coding assistant and it maps your entire project (code, docs, PDFs, images, videos) into a **knowledge graph** you can **query instead of grepping** through files.

### Core design principles
- **Code maps for free, fully local.** Code is parsed with tree-sitter AST：deterministic, no LLM, nothing leaves your machine. (Docs, PDFs, images, video use your assistant's model or a configured API key for a semantic pass.)
- **Every edge is explained.** Each connection tagged `EXTRACTED` (explicit in source) or `INFERRED` (resolved by graphify), so you can tell what was read directly vs. what was inferred.
- **Not a vector index.** No embeddings, no vector store：a real graph you traverse. Ask a question, trace the path between two things, or explain one concept.

### Get started (30 seconds)
```bash
uv tool install graphifyy
graphify install               # register the skill with your AI assistant
# in assistant：
/graphify .
```

### Output（three files）
```
graphify-out/
├── graph.html       open in browser — click nodes, filter, search
├── GRAPH_REPORT.md  key concepts, surprising connections, suggested questions
└── graph.json       full graph — query anytime without re-reading files
```

### Query commands
```
graphify explain "APIRouter"
graphify path FastAPI → ModelField
graphify related "authentication"
```

Real output on FastAPI codebase：
```
Node: APIRouter
  Source:    routing.py L2210
  Community: 2
  Degree:    47
  Related:   BaseRoute, Route, params, Depends, ...
```

### Two-tier extraction
| Tier | Data type | Method | Cost |
|---|---|---|---|
| Deterministic | Code files (.py .ts .rs .go .java .rb …) | tree-sitter AST | Free, offline, fast |
| Semantic | Docs, PDFs, images, video | LLM pass | Uses your assistant's model OR API key |

Every edge is tagged with its extraction method；user always knows if a claim is grounded in source text or inferred by LLM.

### Community detection
Uses **Leiden** algorithm to auto-detect concept clusters （colored in `graph.html`）. Communities correspond to "modules of related concepts" — often but not always the same as the file/folder structure.

### Ecosystem
Works in Claude Code, Cursor, Codex, Gemini CLI, GitHub Copilot, Windsurf, Zed, Antigravity, OpenClaw, and 15+ more. Each platform gets a compatible skill wrapper.

### YC S26 backed
Companion cloud product at graphify.com（always-on background indexing across code + docs + meetings）；OSS repo is the local-first CLI.

### Architecture insight
Two design commitments worth noting：（1）**deterministic vs inferred edges are visibly tagged**，not blended — trust becomes an explicit UI dimension；（2）**graph over embeddings** — for structural queries（"what depends on X", "path from A to B"）graph traversal beats vector top-k because the answer has a canonical shape（a path, a subgraph）rather than a ranked list.

_Fetched via api.github.com on 2026-07-26 for catch-up ingest. Full README (867 lines) covers 40+ languages, install matrix, community-detection tuning, cloud-product waitlist._
