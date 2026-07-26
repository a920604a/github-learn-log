# Multi-Provider LLM Routing

> Concept slug: `multi-provider-llm-routing`
> 累加自跨 repo 分析。

## 定義

系統不綁死單一 LLM provider，而是**在多個 provider（Anthropic / OpenAI / Google / 本地 Ollama / MLX / ...）之間做路由決策**。路由條件可能是 quality tier / latency / cost / 特殊能力（vision, tool use）/ 硬體適配 / privacy 需求。值得抽出來，是因為它決定「使用者換 model 需要動多少地方」——好的 routing 抽象讓 model 選擇成為 config，壞的抽象讓每個 caller 都要 case-by-case。

## 各專案做法對比

<!-- +2026-07-21 from synthetic-sciences__openscience -->
### synthetic-sciences/openscience 的做法
- **核心取捨**：BYOK（Bring Your Own Key），路由決策留給使用者。系統只提供**注冊 provider + 選擇 model** 兩個抽象，routing 邏輯本身不下判斷。
- **資料模型**：provider metadata 從 `models.dev` 拉，帶本地 cache + bundled snapshot fallback；prompt 分兩層（provider-level system + agent-level workflow），換 provider 只換下層。
- **適用場景**：使用者知道自己要什麼、願意管 API key 的 power user 場景。「不下判斷」是刻意的——研究者用途 diverse，系統不該猜。

<!-- +2026-07-26 (catch-up for 2026-07-23) from AlexsJones__llmfit -->
### AlexsJones/llmfit 的做法
- **核心取捨**：專注**本地 runtime provider**（Ollama / llama.cpp / MLX / Docker Model Runner / LM Studio），不涉及 cloud provider（Anthropic / OpenAI）。因為 local LLM 生態每年洗牌，抽象層讓使用者能無縫切換今天最快的 runtime。
- **資料模型**：runtime 抽象成 `provider` interface（`serve(model, quant) → tok/s`），每個 backend 提供同一介面的實作；routing 決策靠 4 維 fit scoring（quality/speed/fit/context）給使用者參考，llmfit 自己不強推選擇。
- **適用場景**：跑本地 LLM 的使用者，想在多個 runtime 之間比較與切換。llmfit 是**決策輔助**而非自動路由。

## 開放問題

- **Cloud vs local 統一抽象**：openscience 只處理 cloud provider，llmfit 只處理 local runtime，兩者能不能統一到一個 routing 層？目前看是**不能**——cloud 有 network cost + auth 概念，local 有 hardware cost + runtime process 概念，強行合併會兩邊都不好用。
- **自動路由 vs 決策輔助**：openscience 和 llmfit 都選「不自動路由，只給資訊讓使用者選」。這是 power-user tool 的通性——過度自動化會讓 debug 變不可能。但如果 target user 是新手，可能需要相反的取捨。
- **成本作為第一 routing 條件**：兩個 repo 都沒把 $ 當第一維度（openscience 給 BYOK 用戶自己算，llmfit 沒 cost 概念因為 local 免費）。生產環境的 routing 通常 cost 是主軸——這個 concept 未來如果收到 SaaS 場景的 repo 應該補這維。

## 來源專案

- [synthetic-sciences/openscience](../repos/synthetic-sciences__openscience.md) — 2026-07-21
- [AlexsJones/llmfit](../repos/AlexsJones__llmfit.md) — 2026-07-26 (catch-up for 2026-07-23)
