# github-learn-log — schema

## 目的
個人學習資料庫。目前有**兩條軌跡**，機制不同、目錄不共用：

| 軌跡 | 主題 | 驅動方式 | 位置 |
|---|---|---|---|
| **A. GitHub trending** | 開源專案的架構/資料設計 | **爬蟲驅動** — 每天掃 trending | root 的 `repos/` `concepts/` `daily/` `weekly/` |
| **B. 資料中心** | 自建機房 infra management 的領域知識 | **教材驅動** — `datacenter/backlog.md` 佇列決定 | `datacenter/` 子樹 |

軌跡 B 刻意不用爬蟲驅動：資料中心的基礎知識緩慢變動，每天爬只會拿到同一批概念的重述。**詳見 `datacenter/index.md`。**

---

# 軌跡 A：GitHub trending

## 目錄約定
- raw/<repo>.md          原料快取，不改
- repos/<repo>.md        entity 頁，鐵人日誌風 800–1000 字
- concepts/<slug>.md     跨 repo 累積的模式頁
- daily/YYYY-MM-DD.md    日報，當日 1–2 repo 卡片
- weekly/YYYY-Www.md     週報，整週 7–14 repo 卡片 + 橫向比較
- glossary.md            比喻 ↔ 技術對照表
- Home.md                索引（自動更新）

## 命名慣例
`<owner>__<repo>`（把 `/` 換成 `__`）。例：`karpathy/nanoGPT` → `karpathy__nanoGPT`。

## Skill 位置
所有 ingest skill 都在 `.claude/skills/github-learn/<name>/SKILL.md`。

**日常單日 pipeline（本地手動依序執行）：**
- `.claude/skills/github-learn/scan-trending/SKILL.md`
- `.claude/skills/github-learn/analyze-repo/SKILL.md`
- `.claude/skills/github-learn/update-concepts/SKILL.md`
- `.claude/skills/github-learn/daily-digest/SKILL.md`
- `.claude/skills/github-learn/weekly-digest/SKILL.md`

**Orchestrator（一次補積壓 N 天）：**
- `.claude/skills/github-learn/catch-up-backlog/SKILL.md` — 偵測 `daily/` 缺口 → 一次補 N 天 → 一次 commit

## 交叉引用
- **連結一律用相對 markdown 連結**（`[slug](../concepts/slug.md)`）。**禁用 `[[wikilink]]`** — MkDocs 沒裝 wikilink plugin，會在 CF Pages 上印出字面字串
- repos → concepts：每個專案頁尾必有 `## 相關概念` 區塊；已成頁的 slug 連結、pending 的 slug 用 inline code 不連（避免 404）
- concepts → repos：每個概念頁底部列出「來源專案」清單
- daily → repos：日報每張卡片 link 到對應專案頁
- weekly → daily + repos：週報 link 到當週日報檔 + 專案頁

## 展示語言
- **所有 wiki 內容 + section header 一律使用繁體中文**（例：`## 本日專案` 而非 `## Repos`；`## 概念更新` 而非 `## Concept 更新`）
- YAML frontmatter 的 key（`repo:`, `url:`, `lang:`, `topics:`, `concept_tags:`）保持英文
- Slug / filename 用 kebab-case 英文（例：`local-first-agent-workbench`）
- Commit message 用英文

## 寫作風格（repos/）
- 鐵人日誌口吻，第一人稱「我」
- 800–1000 字（中文；`wc -m` 驗證）
- 必含區塊：前言 / 系統架構（mermaid）/ 資料設計 / 為什麼這樣做 / 我能學到 / **費曼式回顧**
- 比喻新詞 → 同步 append 到 glossary.md

### 費曼式回顧（新，取代 v1 的「重造難度」）
主動學習套件，設計依據：史丹佛 AI 教育應用研究指出 AI 輔助能顯著提升主動學習成效；費曼學習法結合 LLM 可最大化記憶保留率。這一段裡 LLM 要扮演「你的學生」，幫助讀者暴露自己的理解漏洞。

必含三個子項（每個 60–100 字）：

1. **用生活比喻重講一次**：選一個日常場景（廚房做菜 / 交通塞車 / 排隊 / 便當店 / 咖啡店 / 積木 / 學校規則 …），避開技術術語（API、schema、runtime、DAG、RAG 等一律用比喻詞代替），用國中生能聽懂的話重述本專案的核心機制。
2. **你接下來最可能誤解的 3 個地方**：LLM 站在讀者角度預測 3 個「以為 X 但實際上 Y」的常見盲點，用對照格式列出。
3. **換你解釋（call-to-action）**：一句話邀請讀者「現在你用自己的話講一遍給朋友聽，卡在哪裡回來對照上面兩段」。

## Concept 頁累加規則
- 新增：只有當同一模式被 ≥ 2 個 repo 觸及才開頁
- 更新：append 新 repo 做法 + 取捨對比，**不覆寫**
- 每次更新加日期戳 `<!-- +YYYY-MM-DD from <repo> -->`

## Ingest 觸發條件（scan-trending v2，2026-07-28 修正）
- **Star band：200 ≤ stars ≤ 15000**。上限是硬規則——超過的專案已是產品/組織在維護，讀它學到的是「怎麼做大」不是「怎麼設計」，也不可能週末重造。破例必須在 repo 頁 frontmatter 記 `star_cap_override: <理由>`
- **檔案數 ≤ 300**（tree 排除 `node_modules|vendor|dist|build` 後計）
- **不限 created 時間**，改用 `pushed:近 90 天` 判活躍——v1 的 `created:>30天` 結構性排除了 database / distributed-systems 這類成熟專案
- **Topic bucket 每日輪替**（`date +%j % 4`）：A. llm/agent/rag/mcp｜B. database/vector-database/storage-engine｜C. distributed-systems/backend-framework/orchestration｜D. data-engineering/mlops/etl。目的是一週內四類至少各掃到一次，避免 AI 類洗版
- 語言: Python, TypeScript, JavaScript, Go, Rust
- 排除已在 `repos/` 的 repo
- 目標：每日 1–2 個
- **資料路徑**：優先 `gh api`；`api.github.com` 被 proxy 擋時（Cowork / CCR sandbox）fallback 到 `github.com` HTML 抓取。raw 檔要記 `via API` 或 `via HTML`

## Cloudflare Pages
- Build tool: MkDocs + Material（見 `mkdocs.yml` / `requirements.txt`）
- 內容來源：`_docs/` 內的 symlink 指向 root 的 `daily/` / `weekly/` / `repos/` / `concepts/` / `Home.md` / `index.md` / `glossary.md`
- 排版控制：各子目錄的 `.pages` 檔（awesome-pages plugin）
- 部署：CF Pages 綁 `main`，每次 push 自動 build → https://github-learn-log.pages.dev/
- 不 publish：`raw/`（原料快取，僅內部用）

## 自動化現況（2026-07-28 重整）

**Claude Code Remote Routine 已淘汰。** 舊 routine `trig_01HYQVK4tnG6WhkSPMHNPGcj` 因 sandbox egress 全封（api.github.com / git push / discord.com 皆 403）從未產出任何東西，只當過鬧鐘，已於 2026-07-28 決定刪除。

現在改由 **Cowork 排程任務**驅動，實測可行的分工是：

| 環節 | 誰做 | 為什麼 |
|---|---|---|
| 爬資料 | Cowork 排程（`web_fetch` / `WebSearch`；github.com 也可用 curl） | 沙箱 proxy 白名單只放行 github.com，其餘網域 curl 全 000，但 web_fetch 通 |
| 寫檔 + 本機 commit | Cowork 排程 | 掛載目錄就是使用者 Mac 上的真實資料夾，寫進去就在本機 |
| **git push** | **使用者 Mac 上的 launchd job**（`scripts/auto-push.sh`，每 30 分鐘輪詢） | 沙箱沒有 SSH key，push 一定失敗。把這段搬出沙箱就不用存任何 token |

排程任務：
- `github-learn-log-daily` — GitHub trending 軌跡，**2026-07-28 起暫停**（`enabled: false`，未刪除）
- `datacenter-daily-card` — 資料中心軌跡，週一至週五 08:00
- `datacenter-weekly-review` — 資料中心週報，週日 10:00

沙箱還有兩個坑：

1. **預設不能刪檔** → git 無法 unlink 自己的 lock，`commit` 之後會留下 `.git/HEAD.lock` / `.git/index.lock`，**擋住使用者本機的 git 也擋住隔天的排程**（2026-07-29 實測發生）。每支排程 skill 開工前與收工後都要 `rm -f .git/*.lock`；遇到 `Operation not permitted` 先呼叫 `allow_cowork_file_delete`，該權限**每個 session 都要重新取得**。
2. **任務耗時不固定** → 2026-07-29 那次 08:12 啟動、08:31 才 commit 完。所以 push job 不能排固定時間點，改用每 30 分鐘輪詢（`StartInterval 1800`）。

## Discord 推播（2026-07-26 停用）

原本規劃 Discord webhook（daily/weekly SKILL step 5/7 curl POST）已停用。2026-07-26 因 secret 明碼儲存風險，webhook 已刪、GitHub PAT 已撤。日常 wiki 更新走上面「routine 通知 + 本地跑 catch-up」，不再走 Discord。

若日後想恢復：`daily-digest` / `weekly-digest` SKILL 內 step 5 / 7 邏輯還在，重建 webhook + 由本地執行時 export `DISCORD_WEBHOOK_URL` 即可（不要塞回 routine prompt——那是明碼儲存）。

## Lint 規則（v1 手動觸發；未來可加月度 routine）
- 孤兒 concept（沒 repo link）→ 警告
- 過期 concept（> 6 個月沒被觸及）→ 標記 stale
- 交叉引用斷鏈 → 警告

---

# 軌跡 B：資料中心（datacenter/）

## 目的
支援「在自建自營機房（新建中）建置 infra management 系統」所需的領域知識。
使用者時間預算：**每天 1 小時**（六個月約 180 小時）。

## 目錄約定
- `datacenter/index.md`        軌跡首頁 + 進度儀表板
- `datacenter/roadmap.md`      六個月分階段計畫（人維護，不由 skill 改）
- `datacenter/backlog.md`      學習佇列 61 項，每個工作日消耗 1 項
- `datacenter/devices/<slug>.md`  設備卡（六格）
- `datacenter/topics/<slug>.md`   主題卡（非設備）
- `datacenter/weekly/YYYY-Www.md` 週報 + 自我測驗 + 間隔複習

## Skill 位置
- `.claude/skills/datacenter-learn/dc-daily-card/SKILL.md` — 每工作日 1 張卡
- `.claude/skills/datacenter-learn/dc-weekly-review/SKILL.md` — 週日複習

## 設備卡結構（硬性）
六格：拓撲位置 / 容量單位 / 冗餘表達 / 遙測介面 / 故障域 / 維護特性。
六格之後**五段不可省**：

1. **關鍵數字與計算** — 公式 + 至少一個代入數字的實例演算；地區差異要標註（美規數字不等於台灣）
2. **常見誤解** — 3 條，格式 `**以為 X，但實際上 Y**`
3. **對資料模型的意涵** — 這些事實會變成 schema 的哪些欄位、約束、告警規則。**這是整張卡存在的理由**
4. **動手練習** — 一項 30–40 分鐘、有可驗收產出的實作（NetBox demo 建物件 / 寫 model / 跑協定模擬 / 實作公式）。使用者每天 1 小時，讀卡 10–15 分鐘，其餘全給這段
5. **自我檢核** — 3 題，答案用 `??? note` 摺疊；至少 1 題問「這會讓資料模型長出什麼欄位」

## 字數（2026-07-30 上調）
**每張卡 `wc -m` 落在 3000–10000**（含 frontmatter 與 markdown 標記）。上限原為 4500，實測 dc-02 / dc-03 都因此被迫壓縮或拆分，**2026-07-30 起放寬到 10000**。

- **下限 3000 是硬的**：低於此通常代表深度不足或漏了必含段落
- **上限 10000 是硬的**：超過此才需考慮「這張卡是不是塞了兩個主題」
- 舒適區約 **6000–9000**。參考基準卡：`datacenter/devices/transformer.md`（dc-02，實測 9404）。不要為了填滿而灌水，但**也不要再為省字數犧牲深度**——使用者寧願多花時間把概念學透
- 空間有餘裕時，優先加厚的順序：**關鍵數字與計算（多做一個實例演算）→ 動手練習（更完整的骨架與驗收表）→ 對資料模型的意涵**。六格保持精簡即可
- 真的要砍時砍六格，不要砍上面那五段

## 取材路徑（重要）
沙箱的 `curl` **只有 `github.com` 通**。`learn.microsoft.com` / `netboxlabs.com` / `sre.google` / `se.com` / `uptimeinstitute.com` / `raw.githubusercontent.com` 全部回 `000`。
**一律用 `web_fetch` 與 `WebSearch` 工具取材，不要用 curl / wget / requests。**

## 來源分歧的處理
每張卡至少查 2 個獨立來源。兩邊說法衝突 → **卡片裡明寫「來源分歧」並列出兩種說法**，不要自己挑一個裝作確定。這種分歧正是拿去問 facility 團隊的好題目。

## 佇列規則
- 依 `backlog.md` 由上而下取最上面未完成項
- 使用者可在項目後加 `⬆ 優先` 插隊（通常因為公司下週要看那個設備）
- 完成後改 `[x]` + 日期 + 卡片連結，並更新 `index.md` 進度表

## 交叉引用
同軌跡 A：**禁用 `[[wikilink]]`**，一律相對 markdown 連結；未成頁的 slug 用 inline code 不連。
