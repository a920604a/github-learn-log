# MemPalace/mempalace — raw

- URL: https://github.com/MemPalace/mempalace
- Description: The best-benchmarked open-source AI memory system. Local-first, verbatim storage, pluggable backend, 96.6% R@5 raw on LongMemEval — zero API calls.
- Language: Python
- Topics: ai, chromadb, llm, mcp, memory, python
- Stars: 57745
- License: MIT
- Size: 22,365 KB
- Fetched: 2026-07-26 (catch-up)

## README (excerpt)

MemPalace stores your conversation history as verbatim text and retrieves it with semantic search. It does not summarize, extract, or paraphrase.

The index is structured — people and projects become **wings**, topics become **rooms**, and original content lives in **drawers** — so searches can be scoped rather than run against a flat corpus.

The retrieval layer is pluggable. The current default is ChromaDB; the interface is defined in `mempalace/backends/base.py` and alternative backends can be dropped in without touching the rest of the system.

Nothing leaves your machine unless you opt in.

### Install
```bash
uv tool install mempalace
mempalace init ~/projects/myapp
```

Docker image also available；MCP server mode + CLI mode both supported.

### Palace metaphor architecture
- **Wings**：top-level scope（people, projects）
- **Rooms**：mid-level scope（topics）
- **Drawers**：verbatim content chunks（never summarized）

Search is scoped：`wing:alice/room:project-x` narrows retrieval before semantic ranking runs. This is a *hierarchical filter × embedding recall* hybrid — you get the specificity of tags with the recall of vectors.

### Retrieval design
- Storage：verbatim（no LLM in the write path），preserves original phrasing exactly
- Retrieval：ChromaDB vector search + hierarchical scope filter
- Benchmarks：LongMemEval R@5 = 96.6% raw（top of the open-source leaderboard）

### Pluggable backend
```python
# mempalace/backends/base.py
class BackendBase(ABC):
    def add(self, chunks): ...
    def search(self, query, scope): ...
    def delete(self, ids): ...
```
Drop-in replacement means you can swap ChromaDB for Qdrant / Weaviate / PGVector without touching the palace-metaphor layer. The metaphor is UX；the vector store is infra；they're separable by design.

### MCP integration
Ships with an MCP server so Claude Code / Cursor / Windsurf can query the palace as a tool — session boundaries stop being memory boundaries.

### Claude Code retention note
Claude Code sessions expire in 30 days without auto-save hooks wired；MemPalace provides a "retention setup checklist" to hook into Claude Code's stop/session-end events and auto-persist.

### Architecture insight
Two design commitments worth noting：（1）**verbatim over summary** — refuses to LLM-compress the write path, which loses information；（2）**metaphor separated from backend** — the palace mental model（wings/rooms/drawers）is a UI abstraction, not tied to any particular vector DB. When Chroma inevitably gets displaced by something faster, MemPalace's API contract stays the same.

_Fetched via api.github.com on 2026-07-26 for catch-up ingest. Full README (279 lines) covers install matrix, Docker setup, MCP config, retention hooks._
