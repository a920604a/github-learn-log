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

## 開放問題

- Local-first 和「同步 across devices」怎麼平衡？兩個 repo 都沒直接處理，openscience 用 share link，Agentlas 靠 gitops-style 復原。
- Provider metadata 該 cache 到多新？openscience 選 `models.dev` + snapshot fallback，是可 sync 但可 offline 的漂亮妥協。
- Skill / memory 的 gate 該多嚴？Agentlas 走「預設 off、curator 開」極端側；openscience 讓 skill on-demand load 但沒 promotion gate。

## 來源專案

- [synthetic-sciences/openscience](../repos/synthetic-sciences__openscience.md) — 2026-07-21
- [agentlas-ai/Agentlas-OS](../repos/agentlas-ai__Agentlas-OS.md) — 2026-07-21
