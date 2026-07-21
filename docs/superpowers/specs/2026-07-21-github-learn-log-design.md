# github-learn-log — 設計文件

- **日期**: 2026-07-21
- **狀態**: Draft (待實作)
- **Owner**: chenyuan (a920604a)
- **Remote**: https://github.com/a920604a/github-learn-log
- **Local**: /Users/chenyuan/Desktop/side-projects/github-learn-log

## 1. 目的

建立一個**個人資料庫**，透過 Claude Code routine 每週自動：

1. 掃 GitHub trending，過濾出「有架構深度 + 小到可週末重造」的專案
2. 對每個入選 repo 做深度分析（做什麼、系統架構、資料設計、為什麼這樣做、能學到什麼）
3. 把分析累積成一個 llm_wiki 風格的 markdown 網絡：**entity 頁**（repo）× **concept 頁**（跨 repo 累積的模式）× **週報**
4. 推播週報摘要到 Discord

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
│           └── weekly-digest/SKILL.md
├── CLAUDE.md              # schema：目錄慣例、寫作風格、交叉引用規則
├── Home.md                # 索引：分類 tag、已重造/待重造清單、學習軌跡
├── _Sidebar.md            # 導覽
├── raw/                   # 原料快取（README、關鍵檔），LLM 讀不改
│   └── <repo>.md
├── weekly/                # 週報：5–8 repo 卡片式總覽 + 橫向比較
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
| Wiki | `repos/`, `concepts/`, `weekly/`, `Home.md`, `glossary.md` | LLM 寫，人讀 |
| Schema | `CLAUDE.md`, `.claude/skills/github-learn/` | 人定義規範，LLM 遵守 |

## 3. 週度執行流程 (Ingest)

Routine 觸發時間：**每週日 20:00**（可調整）

```
[ scan-trending ] → shortlist.json (5–8 repos)
        ↓
[ analyze-repo ] × 5–8  → repos/<name>.md + raw/<name>.md + concept tags
        ↓
[ update-concepts ] → 新增/append concepts/*.md
        ↓
[ weekly-digest ]   → weekly/YYYY-Www.md + Home.md 更新 + Discord payload
        ↓
git commit + push + Discord 推播
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
  4. 回傳 5–8 個 shortlist
- **輸出**：`shortlist.json`（暫存於 routine 執行上下文）

### 4.2 `github-learn:analyze-repo`
- **輸入**：一個 repo url
- **步驟**：
  1. 拉 README、`package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml`、頂層目錄結構、關鍵入口檔
  2. 存 `raw/<repo>.md`
  3. 依 CLAUDE.md 寫作規則產出 `repos/<repo>.md`：
     - 鐵人日誌口吻，第一人稱「我」
     - 800–1000 字，技術 + 比喻雙軌交錯
     - 必含區塊：**前言 / 系統架構（mermaid） / 資料設計 / 為什麼這樣做 / 我能學到 / 重造難度**
     - 至少 link 2 個 concept
  4. 產出 concept tags list（交給 update-concepts）
- **輸出**：`repos/<repo>.md` + concept tags

### 4.3 `github-learn:update-concepts`
- **輸入**：多個 `(repo, concept_tags)` pair（這週 + 歷史）
- **步驟**：
  1. 統計 concept 觸及次數
  2. **已存在**：append 新 repo 做法 + 取捨對比，**不覆寫**，加日期戳 `<!-- +YYYY-MM-DD from <repo> -->`
  3. **新 concept 達門檻 (≥ 2 repo)**：開新頁
  4. 更新 concept 頁底部「來源 repos」清單
- **輸出**：新增/更新的 `concepts/*.md`

### 4.4 `github-learn:weekly-digest`
- **輸入**：這週分析過的 repos + updated concepts
- **步驟**：
  1. 寫 `weekly/YYYY-Www.md`：
     - 每 repo 一張卡片（極簡版：一句話 + 3 個 bullet + link 到 entity 頁）
     - 橫向比較表：當本週 shortlist 中有 ≥ 2 個 repo 落在同一 concept tag，將它們列表比較（欄位：核心取捨、資料模型差異、適用場景）；只有 1 個 repo 的 concept 不列表
  2. 更新 `Home.md`：新增 repos、concepts 分類、學習軌跡
  3. 產出 Discord 推播文字：週報連結 + 3 個亮點
- **輸出**：`weekly/YYYY-Www.md` + `Home.md` 更新 + Discord message payload

## 5. CLAUDE.md 內容（wiki schema）

```markdown
# github-learn-log — schema

## 目的
個人資料庫。累積我對 GitHub trending 專案的架構/資料設計學習軌跡。

## 目錄約定
- raw/<repo>.md          原料快取，不改
- repos/<repo>.md        entity 頁，鐵人日誌風 800–1000 字
- concepts/<slug>.md     跨 repo 累積的模式頁
- weekly/YYYY-Www.md     週報，5–8 repo 卡片 + 橫向比較
- glossary.md            比喻 ↔ 技術對照表
- Home.md                索引（自動更新）

## 交叉引用
- repos → concepts：每個 repo 頁至少 link 2 個 concept
- concepts → repos：每個 concept 底部列出「來源 repos」清單
- weekly → repos：週報每張卡片 link 到對應 repo 頁

## 寫作風格（repos/）
- 鐵人日誌口吻，第一人稱「我」
- 800–1000 字，技術 + 比喻雙軌交錯
- 必含區塊：前言 / 系統架構（mermaid）/ 資料設計 / 為什麼這樣做 / 我能學到 / 重造難度
- 比喻新詞 → 同步更新 glossary.md

## Concept 頁累加規則
- 新增：只有當同一模式被 ≥ 2 個 repo 觸及才開頁
- 更新：append 新 repo 做法 + 取捨對比，不覆寫
- 每次更新加日期戳 `<!-- +YYYY-MM-DD from <repo> -->`

## Ingest 觸發條件（scan-trending）
- Topics: llm, agent, rag, mlops, distributed-systems, database, data-engineering, backend-framework
- 語言: Python, TypeScript, Go, Rust
- AI 篩選：架構深度 + 小到可重造（單人 or 小團隊 / 檔案 < 200 / star 快速成長）
- 目標：每週 5–8 個

## Lint 規則（v1 手動觸發；未來可加月度 routine）
- 孤兒 concept（沒 repo link）→ 警告
- 過期 concept（> 6 個月沒被觸及）→ 標記 stale
- 交叉引用斷鏈 → 警告
```

## 6. Routine 設置

- **執行環境**：Claude Code routine (schedule skill)
- **Cron**：每週日 20:00 (Asia/Taipei)
- **執行目標**：clone `https://github.com/a920604a/github-learn-log` → 讀 `CLAUDE.md` + `.claude/skills/github-learn/*` → 執行主流程 → 推播 + push
- **主 prompt**（極短）：「執行本週 github-learn ingest」

## 7. Discord 推播

- 標題：`📚 github-learn 週報 YYYY-Www`
- 內容：
  - 一句話總結這週主軸（例：「這週看了 3 個 RAG framework，chunking 策略各有取捨」）
  - Top 3 亮點 repo（一行 + link）
  - 新增/更新的 concept 頁列表
  - 週報完整連結（GitHub URL）

## 8. 錯誤處理與邊界

- **無 5 個候選**：仍出週報，標註「本週 shortlist 不足」，不硬湊
- **GitHub API rate limit**：使用 authenticated request；scan-trending 內建 backoff
- **routine 執行失敗**：透過 Discord 通知失敗，附錯誤摘要；不重試（下週再跑）
- **Concept 頁衝突**：merge 而非覆蓋；若真的矛盾，Lint 環節標記

## 9. 開放問題（實作前決定）

1. **Routine 執行環境是否自動載入 `.claude/skills/`？** 需先跑最小 skill 驗證
2. **GitHub API token 存哪**：routine secret / repo secret
3. **Discord bot 設定**：token 與 channel id 儲存方式（可能沿用現有 discord:configure 流程）
4. **Trending 資料源**：GitHub trending 沒官方 API — 用 `search/repositories?sort=stars&order=desc&q=created:>...` 或第三方 (e.g., github-trending API)
5. **Lint 何時觸發**：手動 / 月初 routine / weekly-digest 內建（先手動）

## 10. 非目標 (Non-goals)

- 不做 UI（純 GitHub markdown 瀏覽）
- 不做即時查詢介面（未來若要，另開 sub-project）
- 不做自動重造（只做「發現 + 學習素材」，重造是人的事）
- 不追每日更新（週度足夠）

## 11. 成功指標

- 每週執行不中斷，2 個月內累積 40+ repo entity 頁
- concept 頁達 10+，且每個至少 link 2 個 repo（表示真有被累加）
- 使用者主觀：週報收到後**至少讀一半**、每季至少動手重造 1 個
