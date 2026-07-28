# Glossary — 比喻 ↔ 技術對照表

各 repo 頁「費曼式回顧 → 用生活比喻重講一次」出現過的比喻，集中在這裡對照。
讀到不熟的技術名詞時可以反查；寫新頁時也可以先看這裡避免重複用同一個場景。

## 場景總表

| 生活場景 | 對應的技術主題 | 首次出現於 |
|---|---|---|
| 巷口獨立咖啡店 | local-first agent workbench | [synthetic-sciences/openscience](repos/synthetic-sciences__openscience.md) |
| 便當店的手寫食譜卡 | runtime-neutral agent contract | [agentlas-ai/Agentlas-OS](repos/agentlas-ai__Agentlas-OS.md) |
| 圖書館的關係圖 | code AST knowledge graph | [tirth8205/code-review-graph](repos/tirth8205__code-review-graph.md) |
| 鞋店量腳配鞋 | hardware × model fit scoring | [AlexsJones/llmfit](repos/AlexsJones__llmfit.md) |
| 豪宅的翼 / 房間 / 抽屜 | hierarchical memory scope | [MemPalace/mempalace](repos/MemPalace__mempalace.md) |
| 門卡管家 | multi-source adapter registry | [Panniantong/Agent-Reach](repos/Panniantong__Agent-Reach.md) |
| 老房子的便條與錄音帶 | deterministic vs LLM inference | [Graphify-Labs/graphify](repos/Graphify-Labs__graphify.md) |

## 逐項對照

### 巷口獨立咖啡店 — [synthetic-sciences/openscience](repos/synthetic-sciences__openscience.md)

| 比喻 | 技術對應 |
|---|---|
| 客人走進店裡才能點餐 | server 綁 `127.0.0.1`，沒有 remote mode |
| 不接外送、不裝 Uber Eats | 不做 auth / multi-tenant / 雲端 session |
| 中央倉庫送豆子，罷工也照常開 | Atlas 為 optional client，BYOK 路徑不需接雲 |

### 便當店的手寫食譜卡 — [agentlas-ai/Agentlas-OS](repos/agentlas-ai__Agentlas-OS.md)

| 比喻 | 技術對應 |
|---|---|
| 食譜卡寫「加熱到 80 度」而非「開中火 3 分鐘」 | canonical core 只描述意圖，不綁 runtime 實作 |
| 瓦斯爐 / 電磁爐 / 微波爐都能照做 | Claude Code / Codex / Gemini 各自是薄 adapter |
| 厚厚的品管手冊、25 個欄位 | `.agentlas/super-ontology-*.json` 治理契約 |
| 沒填完的卡不准進便當盒 | skill lifecycle：candidate → trial evidence → curator decision |

### 圖書館的關係圖 — [tirth8205/code-review-graph](repos/tirth8205__code-review-graph.md)

| 比喻 | 技術對應 |
|---|---|
| 管理員每次都要把整本書翻一遍 | agent 每次 re-read 原始檔案，token 爆炸 |
| 工讀生把書畫成「誰認識誰」的關係圖 | tree-sitter 抽 AST 建 graph，寫入路徑無 LLM |
| 抬頭看牆上的圖就好 | MCP tool 讓 agent 主動 pull sub-graph |
| 書改了才重畫那幾頁 | file mtime + content hash 做 incremental parse |

### 鞋店量腳配鞋 — [AlexsJones/llmfit](repos/AlexsJones__llmfit.md)

| 比喻 | 技術對應 |
|---|---|
| 店員先量你的腳 | hardware detector 偵測本機規格 |
| 耐穿 / 輕便 / 貼腳 / 能塞多少 | quality / speed / fit / context 四維打分 |
| 貼「✓ 客人實穿過」的鞋 | 社群實測 benchmark 資料 |
| 只憑店員經驗猜的鞋 | heuristic 推估（無實測背書） |
| 門口那本簿子，寫完下個客人看得到 | TUI 內建的 benchmark → PR 回流閉環 |
| 從來不逼你穿某雙，只給比較表 | 不自動路由，只輔助 user 選 |

### 豪宅的翼 / 房間 / 抽屜 — [MemPalace/mempalace](repos/MemPalace__mempalace.md)

| 比喻 | 技術對應 |
|---|---|
| 翼（wing）/ 房間（room）/ 抽屜（drawer） | hierarchical memory scope 三層 |
| 抽屜裡放當天寫的原始便條紙 | verbatim 存原文，write path 不經 LLM 濃縮 |
| 先想「該在哪個翼哪個房間」再翻 | scope filter 先收斂，再做 embedding rank |
| 換新的儲物櫃但格局不變 | pluggable storage backend（Chroma / Qdrant / PGVector） |

### 門卡管家 — [Panniantong/Agent-Reach](repos/Panniantong__Agent-Reach.md)

| 比喻 | 技術對應 |
|---|---|
| 每個平台一張門卡 | 各平台各自的抓取 adapter |
| 門卡管家統一辦卡 | `fetch(url) → normalized_content` 統一介面 |
| 主卡壞了自動換備卡，你不知道換過 | `success_rate_last_100_calls` rolling window 軟切換 |
| 門卡都放你家，管家只幫你維護 | cookie 只存 `~/.agent-reach/cookies/`，不外傳 |

### 老房子的便條與錄音帶 — [Graphify-Labs/graphify](repos/Graphify-Labs__graphify.md)

| 比喻 | 技術對應 |
|---|---|
| 拿放大鏡看得清楚的東西那組人 | tree-sitter AST，deterministic，完全 offline |
| 憑經驗猜照片和錄音那組人 | LLM semantic pass 處理 docs / PDF / image / video |
| 每條線標「看到寫的」還是「猜的」 | edge 的 `extraction_method ∈ {EXTRACTED, INFERRED}` |
| 地圖的色塊跟屋子格局不一樣 | Leiden community detection 揭露實際引用結構 vs 資料夾結構 |

---

> 維護規則：`analyze-repo` 寫新 repo 頁時，若費曼段用了新的生活場景，同步 append 一組到這裡（場景總表加一列 + 逐項對照加一節）。
