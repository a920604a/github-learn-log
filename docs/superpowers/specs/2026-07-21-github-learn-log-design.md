# github-learn-log — 設計文件

- **日期**: 2026-07-21
- **狀態**: Draft (待實作) → **v2 partial revision 2026-07-23**（自動化引擎改動，見下方 sunset banner）
- **Owner**: chenyuan (a920604a)
- **Remote**: https://github.com/a920604a/github-learn-log
- **Local**: /Users/chenyuan/Desktop/side-projects/github-learn-log

---

> ## 🚨 【2026-07-23 v2 更新】自動化引擎已改
>
> 本 spec 原設計自動化引擎為 **Claude Code Remote Routine**（`trig_01HYQVK4tnG6WhkSPMHNPGcj`，透過 `/schedule` skill 建立）。**2026-07-23 首次自動觸發時發現該 routine sandbox egress policy 全封**：
> - `git push` 被 Anthropic managed git proxy 阻擋（receive-pack 回 403）
> - REST API 繞路（curl `api.github.com`）也 403：`GitHub access is not enabled for this session`
> - GitHub MCP `push_files` 也 403：`Resource not accessible by integration`
> - Discord webhook 也 403 CONNECT tunnel
>
> **結論：Claude Code Routine 不能拿來做「碰外部服務 / 寫 GitHub」的自動化**。已把該 routine `enabled: false`。
>
> **新自動化架構**：GitHub Actions
> - Workflow: `.github/workflows/daily-ingest.yml`
> - Pipeline prompt: `.github/pipeline-prompt.md`（獨立檔）
> - Runner: `ubuntu-latest` 裝 `@anthropic-ai/claude-code` CLI
> - Cron: `2 0 * * *` UTC = 08:02 Asia/Taipei（原 spec §6 定為 20:00 Asia/Taipei，v2 早上 08:02，跟原本規劃錯開，讓每天早上開電腦有得看）
> - Secrets: `ANTHROPIC_API_KEY`、`DISCORD_WEBHOOK_URL`（push 用 GH Actions 內建 `GITHUB_TOKEN`）
>
> **本 spec 下文中的 §6「Routine 設置」、§8「錯誤處理與邊界」關於 routine 的描述、§9「開放問題」的 routine-related 問題，都以 v2 的 GH Actions 為準；此處保留原 v1 文字作為設計 rationale 的完整快照，不重寫歷史**。SoT 現在是：`README.md` § 自動化引擎 + `.github/workflows/daily-ingest.yml` + `CLAUDE.md` § 自動化引擎。
>
> **另一個 v2 變更**：repos/ 6 段結構的最後一段從「重造難度」改為「費曼式回顧」（生活比喻 + 3 個常見盲點「以為 X 但實際上 Y」 + 換你解釋）— 依據史丹佛 AI 教育應用研究與費曼學習法結合 LLM 可最大化記憶保留率的研究；本 spec 下文中的 6-section 列表已同步替換。

## 1. 目的

建立一個**個人資料庫**，透過 Claude Code routine：

1. **每日**掃 GitHub trending，過濾出 1–2 個「有架構深度 + 小到可週末重造」的專案
2. 對每個入選 repo 做深度分析（做什麼、系統架構、資料設計、為什麼這樣做、能學到什麼）
3. 把分析累積成一個 llm_wiki 風格的 markdown 網絡：**entity 頁**（repo）× **concept 頁**（跨 repo 累積的模式）× **日報** × **週報**
4. **每日**推播日報（1–2 repo 卡片）；**每週日**額外推播週報（整週 7–14 repo 橫向比較）到 Discord
5. **Cloudflare Pages** 把整份 wiki（日/週/repos/concepts/Home）渲染成靜態網站，可用瀏覽器瀏覽（詳見 §12）

**學習目標**：資料設計 + 系統設計。

**設計哲學**：套用 [Karpathy 的 llm_wiki 模式](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — Raw sources 不動 / Wiki 由 LLM 維護（含 concept pages 跨 repo 累加）/ Schema (`CLAUDE.md`) 定義規範。

## 2. 架構

### 2.1 Repo 結構

```
github-learn-log/
├── .claude/
│   └── skills/
│       └── github-learn/
│           ├── scan-trending/SKILL.md
│           ├── analyze-repo/SKILL.md
│           ├── update-concepts/SKILL.md
│           ├── daily-digest/SKILL.md
│           └── weekly-digest/SKILL.md
├── CLAUDE.md              # schema：目錄慣例、寫作風格、交叉引用規則
├── Home.md                # 索引：分類 tag、已重造/待重造清單、學習軌跡
├── _Sidebar.md            # 導覽
├── raw/                   # 原料快取（README、關鍵檔），LLM 讀不改
│   └── <repo>.md
├── daily/                 # 日報：當日 1–2 repo 卡片
│   └── YYYY-MM-DD.md
├── weekly/                # 週報：整週 7–14 repo 卡片式總覽 + 橫向比較
│   └── YYYY-Www.md
├── repos/                 # entity 頁：鐵人日誌風 800–1000 字 + mermaid 架構圖
│   └── <repo>.md
├── concepts/              # concept 頁：跨 repo 累積的模式頁
│   ├── rag-chunking-strategies.md
│   ├── async-task-queue.md
│   └── ...
├── glossary.md            # 比喻 ↔ 技術對照表
└── docs/superpowers/specs/
    └── 2026-07-21-github-learn-log-design.md
```

### 2.2 三層架構（映射 llm_wiki）

| Layer | 對應目錄 | 誰維護 |
|---|---|---|
| Raw sources | `raw/` | LLM 只讀，不改 |
| Wiki | `repos/`, `concepts/`, `daily/`, `weekly/`, `Home.md`, `glossary.md` | LLM 寫，人讀 |
| Schema | `CLAUDE.md`, `.claude/skills/github-learn/` | 人定義規範，LLM 遵守 |

## 3. 執行流程 (Ingest)

### 3.1 每日流程

Routine 觸發時間：**每天 20:00 (Asia/Taipei)**

```
[ scan-trending ] → shortlist.json (1–2 repos)
        ↓
[ analyze-repo ] × 1–2  → repos/<name>.md + raw/<name>.md + concept tags
        ↓
[ update-concepts ] → 新增/append concepts/*.md
        ↓
[ daily-digest ]   → daily/YYYY-MM-DD.md + Home.md 更新 + Discord daily payload
        ↓
git commit + push + Discord 日報推播
```

### 3.2 每週流程

**接續每週日 20:00 的 daily 流程之後執行**（同一次 routine 內判斷「今天是週日？」→ 接續跑 weekly-digest）：

```
[ weekly-digest ] → weekly/YYYY-Www.md（讀當週 daily/ + concepts）
        ↓
git commit + push + Discord 週報推播
```

## 4. Skills 職責

### 4.1 `github-learn:scan-trending`
- **輸入**：無（可選填時間窗）
- **步驟**：
  1. GitHub API 撈 trending，依 topics + 語言過濾
     - Topics: `llm`, `agent`, `rag`, `mlops`, `distributed-systems`, `database`, `data-engineering`, `backend-framework`
     - 語言: Python, TypeScript, Go, Rust
  2. 快速過濾：star 增速 / 檔案數 < 200 / 單人 or 小團隊 / 有 README
  3. Mini-LLM 判斷「架構深度 + 可重造」
  4. 排除已存在於 `repos/` 的 repo（避免重複分析）
  5. 回傳 1–2 個 shortlist
- **輸出**：`shortlist.json`（暫存於 routine 執行上下文）

### 4.2 `github-learn:analyze-repo`
- **輸入**：一個 repo url
- **步驟**：
  1. 拉 README、`package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml`、頂層目錄結構、關鍵入口檔
  2. 存 `raw/<repo>.md`
  3. 依 CLAUDE.md 寫作規則產出 `repos/<repo>.md`：
     - 鐵人日誌口吻，第一人稱「我」
     - 800–1000 字，技術 + 比喻雙軌交錯
     - 必含區塊：**前言 / 系統架構（mermaid） / 資料設計 / 為什麼這樣做 / 我能學到 / 費曼式回顧**
     - 至少 link 2 個 concept
  4. 產出 concept tags list（交給 update-concepts）
- **輸出**：`repos/<repo>.md` + concept tags

### 4.3 `github-learn:update-concepts`
- **輸入**：多個 `(repo, concept_tags)` pair（今日 + 歷史）
- **步驟**：
  1. 統計 concept 觸及次數
  2. **已存在**：append 新 repo 做法 + 取捨對比，**不覆寫**，加日期戳 `<!-- +YYYY-MM-DD from <repo> -->`
  3. **新 concept 達門檻 (≥ 2 repo)**：開新頁
  4. 更新 concept 頁底部「來源 repos」清單
- **輸出**：新增/更新的 `concepts/*.md`

### 4.4 `github-learn:daily-digest`
- **輸入**：今日 analyzed repos + updated concepts
- **步驟**：
  1. 寫 `daily/YYYY-MM-DD.md`：
     - 每 repo 一張卡片（一句話 + 3 個 bullet + link 到 entity 頁）
     - 若今日 concept 有更新，列出更新項
  2. 更新 `Home.md`：新增 repos 到分類 tag，更新學習軌跡
  3. 產出 Discord daily 推播文字：`📚 github-learn 日報 YYYY-MM-DD` + 卡片摘要 + link
- **輸出**：`daily/YYYY-MM-DD.md` + `Home.md` 更新 + Discord daily message payload

### 4.5 `github-learn:weekly-digest`
- **輸入**：本週 `daily/YYYY-MM-DD.md` × 7 + 本週 updated concepts
- **步驟**：
  1. 寫 `weekly/YYYY-Www.md`：
     - 本週 7–14 repo 一段總覽（卡片沿用 daily 內容）
     - 橫向比較表：當本週 shortlist 中有 ≥ 2 個 repo 落在同一 concept tag，將它們列表比較（欄位：核心取捨、資料模型差異、適用場景）；只有 1 個 repo 的 concept 不列表
     - 一句話總結本週主軸
  2. 更新 `Home.md`：週報索引
  3. 產出 Discord weekly 推播文字：週報連結 + 3 個亮點 + 新增/更新 concept 列表
- **輸出**：`weekly/YYYY-Www.md` + `Home.md` 更新 + Discord weekly message payload

## 5. CLAUDE.md 內容（wiki schema）

```markdown
# github-learn-log — schema

## 目的
個人資料庫。累積我對 GitHub trending 專案的架構/資料設計學習軌跡。

## 目錄約定
- raw/<repo>.md          原料快取，不改
- repos/<repo>.md        entity 頁，鐵人日誌風 800–1000 字
- concepts/<slug>.md     跨 repo 累積的模式頁
- daily/YYYY-MM-DD.md    日報，當日 1–2 repo 卡片
- weekly/YYYY-Www.md     週報，整週 7–14 repo 卡片 + 橫向比較
- glossary.md            比喻 ↔ 技術對照表
- Home.md                索引（自動更新）

## 交叉引用
- repos → concepts：每個 repo 頁至少 link 2 個 concept
- concepts → repos：每個 concept 底部列出「來源 repos」清單
- daily → repos：日報每張卡片 link 到對應 repo 頁
- weekly → daily + repos：週報 link 到當週 daily 檔 + repo 頁

## 寫作風格（repos/）
- 鐵人日誌口吻，第一人稱「我」
- 800–1000 字，技術 + 比喻雙軌交錯
- 必含區塊：前言 / 系統架構（mermaid）/ 資料設計 / 為什麼這樣做 / 我能學到 / 費曼式回顧
- 比喻新詞 → 同步更新 glossary.md

## Concept 頁累加規則
- 新增：只有當同一模式被 ≥ 2 個 repo 觸及才開頁
- 更新：append 新 repo 做法 + 取捨對比，不覆寫
- 每次更新加日期戳 `<!-- +YYYY-MM-DD from <repo> -->`

## Ingest 觸發條件（scan-trending）
- Topics: llm, agent, rag, mlops, distributed-systems, database, data-engineering, backend-framework
- 語言: Python, TypeScript, Go, Rust
- AI 篩選：架構深度 + 小到可重造（單人 or 小團隊 / 檔案 < 200 / star 快速成長）
- 排除已在 repos/ 的 repo
- 目標：每日 1–2 個

## Lint 規則（v1 手動觸發；未來可加月度 routine）
- 孤兒 concept（沒 repo link）→ 警告
- 過期 concept（> 6 個月沒被觸及）→ 標記 stale
- 交叉引用斷鏈 → 警告
```

## 6. Routine 設置

- **執行環境**：Claude Code routine (schedule skill)
- **Cron**：每天 20:00 (Asia/Taipei) — 一個 job，內建「今天是週日則接續跑 weekly-digest」判斷
- **執行目標**：clone `https://github.com/a920604a/github-learn-log` → 讀 `CLAUDE.md` + `.claude/skills/github-learn/*` → 執行主流程 → 推播 + push
- **主 prompt**（極短）：「執行今日 github-learn ingest；若今天是週日，接續產本週週報」

## 7. Discord 推播

### 7.1 每日推播
- 標題：`📚 github-learn 日報 YYYY-MM-DD`
- 內容：
  - 當日 1–2 個 repo（一句話 + 3 個 bullet）
  - 每 repo link 到 entity 頁 GitHub URL
  - 若有 concept 更新，列出更新項

### 7.2 每週推播（週日晚間，日報之後）
- 標題：`📚 github-learn 週報 YYYY-Www`
- 內容：
  - 一句話總結本週主軸（例：「這週看了 3 個 RAG framework，chunking 策略各有取捨」）
  - Top 3 亮點 repo（一行 + link）
  - 新增/更新的 concept 頁列表
  - 週報完整連結（GitHub URL）

## 8. 錯誤處理與邊界

- **當日無候選**：仍出日報，標註「今日 shortlist 不足」，不硬湊；週報以實際 repo 數為準
- **GitHub API rate limit**：使用 authenticated request；scan-trending 內建 backoff
- **routine 執行失敗**：透過 Discord 通知失敗，附錯誤摘要；不重試（明日再跑）
- **Concept 頁衝突**：merge 而非覆蓋；若真的矛盾，Lint 環節標記
- **同 repo 重複命中 trending**：scan-trending 排除已存在的 `repos/<name>.md`

## 9. 開放問題（實作前決定）

1. **Routine 執行環境是否自動載入 `.claude/skills/`？** 需先跑最小 skill 驗證
2. **GitHub API token 存哪**：routine secret / repo secret
3. **Discord bot 設定**：token 與 channel id 儲存方式（可能沿用現有 discord:configure 流程）
4. **Trending 資料源**：GitHub trending 沒官方 API — 用 `search/repositories?sort=stars&order=desc&q=created:>...` 或第三方 (e.g., github-trending API)
5. **Lint 何時觸發**：手動 / 月初 routine / weekly-digest 內建（先手動）

## 10. 非目標 (Non-goals)

- 不做互動式 UI（Cloudflare Pages 為純靜態渲染）
- 不做即時查詢介面（未來若要，另開 sub-project）
- 不做自動重造（只做「發現 + 學習素材」，重造是人的事）
- 不追每小時更新（每日足夠）

## 11. 成功指標

- 每日執行不中斷，1 個月內累積 40+ repo entity 頁
- concept 頁達 10+，且每個至少 link 2 個 repo（表示真有被累加）
- 使用者主觀：日報收到後**至少讀一則**、週報**至少讀一半**、每季至少動手重造 1 個
- Cloudflare Pages 每次 `main` push 都有成功 build，可用瀏覽器讀 daily/weekly

## 12. Cloudflare Pages 展示

**目標**：把 `daily/`、`weekly/` (以及 `repos/`、`concepts/`、`Home.md`) 渲染成可瀏覽的靜態網站，避免只能在 GitHub markdown 檢視。

### 12.1 技術選型

- **靜態網站產生器**：MkDocs + Material 主題
  - 理由：對 markdown 原生，無需 JS 框架；nav 自動抓目錄；build 快、無 node 依賴
  - 備選：Astro Starlight（若日後想要更客製化）
- **部署**：Cloudflare Pages 綁 GitHub repo，`main` push 觸發 build
- **Build 指令**：`pip install mkdocs-material && mkdocs build`
- **Output 目錄**：`site/`
- **自訂網域**（optional）：後續設定

### 12.2 目錄映射

| Wiki 檔 | Pages 路徑 |
|---|---|
| `Home.md` | `/`（首頁） |
| `daily/YYYY-MM-DD.md` | `/daily/YYYY-MM-DD/` |
| `weekly/YYYY-Www.md` | `/weekly/YYYY-Www/` |
| `repos/<name>.md` | `/repos/<name>/` |
| `concepts/<slug>.md` | `/concepts/<slug>/` |
| `glossary.md` | `/glossary/` |
| `raw/*` | **不 publish**（原料快取，僅內部用） |

### 12.3 mkdocs.yml 關鍵設定

- `site_name: github-learn-log`
- `nav`：手寫 top-level `Home / Daily / Weekly / Repos / Concepts / Glossary`，子頁交給 `awesome-pages` plugin 自動列
- `theme.name: material`，開啟 `navigation.sections`、`toc.integrate`、`search`
- `markdown_extensions`：`pymdownx.superfences`（含 mermaid）、`admonition`、`tables`
- `plugins`：`search`、`awesome-pages`
- `exclude_docs: raw/`

### 12.4 Discord 推播連結更新

- 日報卡片：GitHub raw link → 改用 Pages URL（例：`https://github-learn-log.pages.dev/daily/2026-07-21/`）
- 週報連結：同上

### 12.5 錯誤處理

- **Build 失敗**：Cloudflare 會回 email；weekly-digest 之後可加一個「檢查最新 deployment status」步驟並在 Discord 告警（v2）
- **Mermaid 渲染**：透過 `mkdocs-material` 內建支援 + `pymdownx.superfences` custom fence 設定
