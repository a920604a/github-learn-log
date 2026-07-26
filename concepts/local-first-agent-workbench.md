# Local-First Agent Workbench

> Concept slug: `local-first-agent-workbench`
> 累加自跨 repo 分析。

## 定義

Agent 執行環境 / workbench 綁本機（`127.0.0.1` 或 XDG 目錄），連 provider / 外部 DB 走 outbound；**沒有 remote mode**、沒有雲端 auth / multi-tenant 概念。所有 session、artifact、credential 落地本機。值得抽出來，是因為它是「開源 agent 產品」和「SaaS agent 產品」的**架構分水嶺** — 一旦選了 local-first，很多子決策（無 session server、無 remote share model、無 auth）就都跟著定。

## 各專案做法對比

<!-- +2026-07-21 from synthetic-sciences__openscience -->
### synthetic-sciences/openscience 的做法
- **核心取捨**：localhost only + Host/Origin allowlist；Atlas（cloud）僅為 optional client；BYOK 路徑完全不需接雲。
- **資料模型**：session/artifacts/provenance 在 XDG 目錄；provider metadata 從 [models.dev](https://models.dev) 拉+本地 cache+bundled snapshot fallback。
- **適用場景**：研究者要跑本機 exp、有敏感 dataset、不想把 prompt/paper drafts 送 SaaS。

<!-- +2026-07-21 from agentlas-ai__Agentlas-OS -->
### agentlas-ai/Agentlas-OS 的做法
- **核心取捨**：連 memory / skill 也 local-first。Agent trust contract 明言「**no implied hosted Agent Cloud VM**」；skill / memory 有 curator gate；credentials 只落 gitignored local file，public export 只保 value-free reference。
- **資料模型**：`.agentlas/` 目錄下大量 JSON contract file；ontology runtime 用 SQLite + FTS5 + deterministic local vectors，GraphRAG 查詢在本機。
- **適用場景**：想把 agent 當「portable user asset」搬 runtime、要 audit / restore / governance 的場景。

<!-- +2026-07-26 (catch-up for 2026-07-22) from tirth8205__code-review-graph -->
### tirth8205/code-review-graph 的做法
- **核心取捨**：本地 SQLite 存 graph（非 Neo4j daemon），一份檔可 diff / 可 grep / 可放 git；無雲端 sync。
- **資料模型**：nodes (file/class/function/import) + edges 帶 `(source_file, line, extractor_version)` provenance；SQLite recursive CTE 做 graph traversal；file mtime + content hash 做 incremental change detection。
- **適用場景**：想讓 AI coding tools 快速 impact 分析而不外流原始碼；純 CLI + MCP，無網路依賴。

<!-- +2026-07-26 (catch-up for 2026-07-24) from MemPalace__mempalace -->
### MemPalace/mempalace 的做法
- **核心取捨**：conversation history verbatim 存本機（no LLM in write path），連 embedding backend 都是 pluggable，可換 Chroma → Qdrant → PGVector 不動 API contract。
- **資料模型**：hierarchical scope（wing/room/drawer）× ChromaDB embedding；scope filter 先收斂再 embedding rank；drawer 用 content_hash 去重。
- **適用場景**：對「日後想改召回策略」下賭注保留原料；不接受 SaaS memory 或雲同步的個人使用者。

<!-- +2026-07-26 (catch-up for 2026-07-25) from Panniantong__Agent-Reach -->
### Panniantong/Agent-Reach 的做法
- **核心取捨**：所有 cookie 只存 `~/.agent-reach/cookies/`，不外傳；免費爬蟲工具優先，付費代理（$1/月）僅可選；agent 端執行安裝流程不依賴雲部署。
- **資料模型**：`fetch(url) → normalized_content` 每 adapter 內部攤平；`success_rate_last_100_calls` rolling window 做 backend 軟切換。
- **適用場景**：hobby 級「AI 需要讀網路」但不想付 Twitter API 錢、也不想把 cookie 交給 SaaS 中介的族群。

<!-- +2026-07-26 from Graphify-Labs__graphify -->
### Graphify-Labs/graphify 的做法
- **核心取捨**：CLI 完全 local（tree-sitter 走 offline），只有 semantic pass 需 LLM 但可用 assistant 內建 model 不外洩 API key；配套 SaaS graphify.com 為 optional add-on 而非核心依賴。
- **資料模型**：node + edge 帶 `extraction_method ∈ {EXTRACTED, INFERRED}`；graph.json portable 可 diff 可放 git；graph.html 純前端 D3 視覺化不需 server。
- **適用場景**：想在 AI assistant 裡對 codebase 做結構性 query，同時保留「哪些關係是 AI 猜的」透明度。

## 開放問題

- Local-first 和「同步 across devices」怎麼平衡？6 個 repo 各有做法：openscience 用 share link、Agentlas 靠 gitops-style 復原、graphify 靠 portable graph.json、mempalace + code-review-graph 都沒直接處理（假設「一台機器」是主流用例）。
- Provider / catalog metadata 該 cache 到多新？openscience 選 `models.dev` + snapshot fallback；llmfit 選 bundle-in-binary 每 release 更新；code-review-graph 選 no metadata（純 AST）。三種都是有效答案，取決於「metadata 過時的代價有多大」。
- Skill / memory / cookie 的 gate 該多嚴？Agentlas 走「預設 off、curator 開」極端側；agent-reach 走「cookie 本地即用」寬鬆側；mempalace 走「opt-in 才對外」中間側。
- Local + AI 的 tension：越 local 越難利用 LLM inference（要嘛本地跑 LLM 慢、要嘛送雲不 local）。graphify 的解法「code 走 offline + docs 走 LLM」是漂亮的分層取捨。

## 來源專案

- [synthetic-sciences/openscience](../repos/synthetic-sciences__openscience.md) — 2026-07-21
- [agentlas-ai/Agentlas-OS](../repos/agentlas-ai__Agentlas-OS.md) — 2026-07-21
- [tirth8205/code-review-graph](../repos/tirth8205__code-review-graph.md) — 2026-07-26 (catch-up for 2026-07-22)
- [MemPalace/mempalace](../repos/MemPalace__mempalace.md) — 2026-07-26 (catch-up for 2026-07-24)
- [Panniantong/Agent-Reach](../repos/Panniantong__Agent-Reach.md) — 2026-07-26 (catch-up for 2026-07-25)
- [Graphify-Labs/graphify](../repos/Graphify-Labs__graphify.md) — 2026-07-26
