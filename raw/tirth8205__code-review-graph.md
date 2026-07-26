# tirth8205/code-review-graph — raw

- URL: https://github.com/tirth8205/code-review-graph
- Description: Local-first code intelligence graph for MCP and CLI. Builds a persistent map of your codebase so AI coding tools read only what matters, with benchmarked 38-528x token reduction across real repos.
- Language: Python
- Topics: ai-coding, claude, claude-code, code-review, graphrag, incremental, knowledge-graph, llm, mcp, python, static-analysis, tree-sitter
- Stars: 26458
- License: MIT
- Size: 12,101 KB
- Fetched: 2026-07-26 (catch-up)

## README (excerpt)

**Stop burning tokens. Start reviewing smarter.**

AI coding tools can end up re-reading large parts of your codebase on review tasks. `code-review-graph` fixes that. It builds a structural map of your code with Tree-sitter, tracks changes incrementally, and gives your AI assistant precise context via MCP so it reads only what matters.

### Quick Start
```bash
pip install code-review-graph
code-review-graph install          # auto-detects and configures all supported platforms
code-review-graph build            # parse your codebase
```

`install` detects which AI coding tools you have (Claude Code, Cursor, Windsurf, Codex, Gemini CLI, Zed, Continue, Kiro, OpenCode, Antigravity, Qwen, Qoder, GitHub Copilot, CodeBuddy…), writes the correct MCP config for each, installs platform-native hooks/skills where supported, and injects graph-aware instructions into platform rules.

### Core mechanics
- **Tree-sitter parsing**：deterministic AST extraction，no LLM in the parse loop
- **Incremental updates**：only re-parses changed files；graph persists between sessions
- **MCP interface**：expose graph queries as tools（`get_context`, `find_dependencies`, `impact_of_change`）that AI assistants call instead of re-reading files
- **Benchmarked reduction**：38x–528x fewer tokens on 6 real repos（vs. tools reading files raw）
- **Persistent map**：graph stored locally in SQLite；survives across sessions；no re-index unless files change

### Supported languages
Python, TypeScript, JavaScript, Rust, Go, Java, C, C++, Ruby, PHP（tree-sitter grammars pluggable）

### GitHub Action integration
Provides `code-review-graph-action` for PR review workflows：runs graph query on PR files，comments actionable review notes based on structural impact，not just diff-line lint.

### Architecture insight
The interesting design：**graph as context-cache**。Instead of feeding an AI assistant an entire codebase or a naive vector top-k, expose a graph query interface so the assistant asks specific questions（"what depends on this class?", "trace call path X→Y"）and receives minimal, structural answers. This is a middle ground between full-file grep and RAG vector search — precise, deterministic, and cheap.

_Fetched via api.github.com on 2026-07-26 for catch-up ingest. Full README (867 lines) has extensive docs, benchmarks, and platform-specific setup._
