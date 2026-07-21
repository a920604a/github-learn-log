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

## 命名慣例
`<owner>__<repo>`（把 `/` 換成 `__`）。例：`karpathy/nanoGPT` → `karpathy__nanoGPT`。

## Skill 位置
所有 ingest skill 都在 `.claude/skills/github-learn/<name>/SKILL.md`。routine 執行時逐一讀取：
- `.claude/skills/github-learn/scan-trending/SKILL.md`
- `.claude/skills/github-learn/analyze-repo/SKILL.md`
- `.claude/skills/github-learn/update-concepts/SKILL.md`
- `.claude/skills/github-learn/daily-digest/SKILL.md`
- `.claude/skills/github-learn/weekly-digest/SKILL.md`

## 交叉引用
- repos → concepts：每個專案頁至少 link 2 個概念
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
- 必含區塊：前言 / 系統架構（mermaid）/ 資料設計 / 為什麼這樣做 / 我能學到 / 重造難度
- 比喻新詞 → 同步 append 到 glossary.md

## Concept 頁累加規則
- 新增：只有當同一模式被 ≥ 2 個 repo 觸及才開頁
- 更新：append 新 repo 做法 + 取捨對比，**不覆寫**
- 每次更新加日期戳 `<!-- +YYYY-MM-DD from <repo> -->`

## Ingest 觸發條件（scan-trending）
- Topics: llm, agent, rag, mlops, distributed-systems, database, data-engineering, backend-framework
- 語言: Python, TypeScript, Go, Rust
- AI 篩選：架構深度 + 小到可重造（單人 or 小團隊 / 檔案 < 200 / star 快速成長）
- 排除已在 `repos/` 的 repo
- 目標：每日 1–2 個

## Cloudflare Pages（可選，後續處理）
- Build tool: MkDocs + Material（見 mkdocs.yml；目前未啟用）
- 不 publish：`raw/`（原料快取，僅內部用）

## Lint 規則（v1 手動觸發；未來可加月度 routine）
- 孤兒 concept（沒 repo link）→ 警告
- 過期 concept（> 6 個月沒被觸及）→ 標記 stale
- 交叉引用斷鏈 → 警告
