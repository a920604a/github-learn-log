# Code AST Knowledge Graph

> Concept slug: `code-ast-knowledge-graph`
> 累加自跨 repo 分析。

## 定義

用 **tree-sitter（或類似的 AST parser）** 把 codebase 抽成 **graph**（nodes = 檔案/類別/函式/import，edges = calls/imports/inherits/defines），持久化到本機 store。**寫入路徑不用 LLM**（deterministic 保證可重現），查詢路徑供 AI agent / CLI / GitHub Action 消費。

值得抽出來，是因為它揭露了一個重要 pattern：**「幫 AI 不要讀」比「幫 AI 讀」更省 token 也更精準**。傳統 RAG 是「把更多內容塞進 context」，AST graph 是「先抽出結構，query 只回結構性答案」。這是介於 grep 和 vector search 之間的第三條路。

## 各專案做法對比

<!-- +2026-07-26 (catch-up for 2026-07-22) from tirth8205__code-review-graph -->
### tirth8205/code-review-graph 的做法
- **核心取捨**：只處理 code（不碰 docs / PDF），全 deterministic 無 LLM；主打「code review workflow」場景。
- **資料模型**：SQLite graph store，recursive CTE 做 traversal；edge 帶 `extractor_version` 支援 parser 升級無 breaking change；file mtime + content hash 做 incremental parse。
- **消費介面**：MCP server 把 graph 包成 tool（`get_context / find_deps / impact_of_change`），agent 主動 pull sub-graph；CLI 給人 debug；GitHub Action 給 PR review。
- **實測效益**：38x–528x token reduction on 6 real repos vs. naive file re-read。
- **範疇**：Python / TypeScript / JavaScript / Rust / Go / Java / C / C++ / Ruby / PHP。

<!-- +2026-07-26 from Graphify-Labs__graphify -->
### Graphify-Labs/graphify 的做法
- **核心取捨**：**混合 extractor**——code 走 deterministic tree-sitter、非 code（docs / PDF / image / video）走 LLM semantic pass。每條 edge 顯性標記 `extraction_method ∈ {EXTRACTED, INFERRED}` 讓下游決定信任度。
- **資料模型**：node + edge 都帶 provenance（EXTRACTED 帶 source_line, INFERRED 帶 confidence + snippet）；Leiden algorithm 做 community detection 自動分色。
- **消費介面**：`/graphify .` skill 呼叫（Claude Code / Cursor / Codex / Antigravity 等 15+ 平台）；輸出 graph.html（人讀）+ graph.json（機器再處理）+ GRAPH_REPORT.md（AI 讀）。
- **範疇**：40+ 語言 + 非 code 檔案。

## 開放問題

- **Deterministic-only vs 混合 extractor**：code-review-graph 純 deterministic 換來完全可預測，graphify 混合換來更廣範疇但引入 LLM 不確定性。前者適合「reproducible CI」場景，後者適合「探索 unstructured 內容」場景。
- **Graph store 選擇**：兩個都不用專用 graph DB（Neo4j）。code-review-graph 用 SQLite（單檔可攜），graphify 用 JSON（可 diff）。專用 graph DB 對「codebase 級 node 數」（10K–100K）都是 overkill。
- **Query 介面差異**：code-review-graph 走 MCP（agent 主動查），graphify 走 file output（人主動看）+ query CLI。前者更適合 in-loop context injection，後者更適合離線探索。兩者其實可以互補。
- **Provenance 深度**：graphify 走「edge-level 標記」（每條連線標 EXTRACTED/INFERRED），code-review-graph 走「edge 帶 source_line + extractor_version」但沒 EXTRACTED/INFERRED 對照（因為它全 deterministic 沒必要）。**「有 LLM 就一定要標」**是可抽出來的守則。
- **incremental 策略**：code-review-graph 明確做 incremental（mtime + hash），graphify README 沒細講。graph 越大 incremental 越關鍵，這是 scalability 分水嶺。

## 來源專案

- [tirth8205/code-review-graph](../repos/tirth8205__code-review-graph.md) — 2026-07-26 (catch-up for 2026-07-22)
- [Graphify-Labs/graphify](../repos/Graphify-Labs__graphify.md) — 2026-07-26
