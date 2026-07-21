# github-learn-log Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立 github-learn-log 個人 wiki：每日 routine 自動選 1–2 個 GitHub trending repo 深度分析、寫入 markdown wiki、更新 concept 累加頁、產出日/週報，並經 Cloudflare Pages 靜態網站瀏覽 + Discord 推播。

**Architecture:** Karpathy llm_wiki 三層 (Raw sources / Wiki / Schema)。實作面：`.claude/skills/github-learn/*` 五支 skill 由 Claude Code routine 串起（scan → analyze → update-concepts → daily-digest；週日多跑 weekly-digest）。Wiki 內容為純 markdown，`main` push 觸發 Cloudflare Pages 用 MkDocs Material 建站。Discord 推播使用專案既有 `discord:configure` 流程。

**Tech Stack:**
- Claude Code project skills（`.claude/skills/github-learn/*/SKILL.md`）
- GitHub CLI (`gh`) 撈 trending / metadata
- MkDocs + Material 主題（Cloudflare Pages build）
- Cloudflare Pages（GitHub 綁定 + auto build）
- Discord bot（Superpowers 現有 `discord:configure` 流程）
- Claude Code `/schedule` skill 建 routine

## Global Constraints

- **Wiki 語言**：所有 `daily/`、`weekly/`、`repos/`、`concepts/`、`Home.md`、`glossary.md` 內容 → **繁體中文**。commit message、SKILL frontmatter、mkdocs.yml、CLAUDE.md schema 段落 → 英文可，中文亦可。
- **目錄結構**：完全依 spec §2.1；不新增未列出的 top-level 目錄。
- **Skill 目錄慣例**：所有 skill 放在 `.claude/skills/github-learn/<name>/SKILL.md`（巢狀），路徑由 `CLAUDE.md` 明確列出以確保 routine 能讀到。
- **Ingest 頻率**：每日 1–2 個 repo；cron 每天 20:00 (Asia/Taipei)；週日的 daily 之後接續跑 weekly-digest。
- **Repo 去重**：`scan-trending` 必須排除已在 `repos/<name>.md` 存在的 repo。
- **Concept 開頁門檻**：同一 concept 被 ≥ 2 個 repo 觸及才開新頁。
- **Concept 更新**：不覆寫，只 append；每次更新加日期戳 `<!-- +YYYY-MM-DD from <repo> -->`。
- **repos/ 寫作規範**：鐵人日誌口吻、第一人稱「我」、800–1000 字、必含區塊（前言/系統架構 mermaid/資料設計/為什麼這樣做/我能學到/重造難度）、至少 link 2 個 concept。
- **Cloudflare Pages 產物路徑**：`site/`；build command `pip install -r requirements.txt && mkdocs build`；不 publish `raw/`。
- **Discord**：使用專案既有 `discord:configure` 流程；連結一律用 Cloudflare Pages URL。
- **Commit**：小步提交；prefix 用 `feat:` / `chore:` / `docs:` / `refactor:`；每個 task 至少一次 commit。

## File Structure

**Create in this plan:**
- `CLAUDE.md` — project schema，Claude 讀取以了解 wiki 慣例（Task 1）
- `Home.md` — wiki 首頁 / 索引，初始為空模板（Task 1）
- `_Sidebar.md` — 導覽（Task 1）
- `glossary.md` — 比喻對照表，初始為空模板（Task 1）
- `raw/.gitkeep`, `daily/.gitkeep`, `weekly/.gitkeep`, `repos/.gitkeep`, `concepts/.gitkeep`（Task 1）
- `.claude/skills/github-learn/scan-trending/SKILL.md`（Task 2）
- `.claude/skills/github-learn/analyze-repo/SKILL.md`（Task 3）
- `.claude/skills/github-learn/update-concepts/SKILL.md`（Task 4）
- `.claude/skills/github-learn/daily-digest/SKILL.md`（Task 5）
- `.claude/skills/github-learn/weekly-digest/SKILL.md`（Task 6）
- `mkdocs.yml`（Task 7）
- `requirements.txt`（Task 7）
- `.gitignore`（Task 7；加入 `site/`、`.cache/`、`__pycache__/`）

**External (無 code diff，屬 config action)：**
- Cloudflare Pages project binding（Task 9）
- Discord bot 綁定 via `discord:configure`（Task 10）
- Claude Code `/schedule` routine（Task 11）

---

### Task 1: Scaffold repo + CLAUDE.md schema

**Files:**
- Create: `CLAUDE.md`
- Create: `Home.md`
- Create: `_Sidebar.md`
- Create: `glossary.md`
- Create: `raw/.gitkeep`, `daily/.gitkeep`, `weekly/.gitkeep`, `repos/.gitkeep`, `concepts/.gitkeep`

**Interfaces:**
- Consumes: 無
- Produces: `CLAUDE.md`（後續所有 skill 讀取的 schema 來源）；目錄骨架（skill 寫入的目標路徑）

- [ ] **Step 1: 檢查目前 repo 檔案**

Run:
```bash
ls /Users/chenyuan/Desktop/side-projects/github-learn-log
```
Expected: 只有 `README.md`、`docs/`

- [ ] **Step 2: 寫 `CLAUDE.md`**

Path: `/Users/chenyuan/Desktop/side-projects/github-learn-log/CLAUDE.md`

Content:
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

## Skill 位置
- .claude/skills/github-learn/scan-trending/SKILL.md
- .claude/skills/github-learn/analyze-repo/SKILL.md
- .claude/skills/github-learn/update-concepts/SKILL.md
- .claude/skills/github-learn/daily-digest/SKILL.md
- .claude/skills/github-learn/weekly-digest/SKILL.md

## 交叉引用
- repos → concepts：每個 repo 頁至少 link 2 個 concept
- concepts → repos：每個 concept 底部列出「來源 repos」清單
- daily → repos：日報每張卡片 link 到對應 repo 頁
- weekly → daily + repos：週報 link 到當週 daily 檔 + repo 頁

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
- 排除已在 repos/ 的 repo
- 目標：每日 1–2 個

## Cloudflare Pages
- Build tool: MkDocs + Material（見 mkdocs.yml）
- Build command: `pip install -r requirements.txt && mkdocs build`
- Output: `site/`
- 不 publish：`raw/`（原料快取，僅內部用）

## Lint 規則（v1 手動觸發；未來可加月度 routine）
- 孤兒 concept（沒 repo link）→ 警告
- 過期 concept（> 6 個月沒被觸及）→ 標記 stale
- 交叉引用斷鏈 → 警告
```

- [ ] **Step 3: 寫 `Home.md`（初始模板）**

Path: `/Users/chenyuan/Desktop/side-projects/github-learn-log/Home.md`

Content:
```markdown
# github-learn-log

個人資料庫：GitHub trending 專案的架構 / 資料設計學習軌跡。

## 分類 tag
（首次 daily-digest 執行時自動填入）

## 已重造 / 待重造
- 已重造：*（尚無）*
- 待重造：*（尚無）*

## 學習軌跡
（daily-digest / weekly-digest 自動 append 索引）

### 日報
（自動填入）

### 週報
（自動填入）
```

- [ ] **Step 4: 寫 `_Sidebar.md`**

Path: `/Users/chenyuan/Desktop/side-projects/github-learn-log/_Sidebar.md`

Content:
```markdown
- [Home](Home.md)
- [Glossary](glossary.md)
- Daily
- Weekly
- Repos
- Concepts
```

- [ ] **Step 5: 寫 `glossary.md`（初始模板）**

Path: `/Users/chenyuan/Desktop/side-projects/github-learn-log/glossary.md`

Content:
```markdown
# Glossary — 比喻 ↔ 技術對照表

| 比喻 | 技術對應 | 首次出現於 |
|---|---|---|
| *（尚無，首篇 repo 分析時補入）* | | |
```

- [ ] **Step 6: 建立空目錄骨架**

Run:
```bash
cd /Users/chenyuan/Desktop/side-projects/github-learn-log && \
mkdir -p raw daily weekly repos concepts && \
touch raw/.gitkeep daily/.gitkeep weekly/.gitkeep repos/.gitkeep concepts/.gitkeep
```

- [ ] **Step 7: 驗證檔案結構**

Run:
```bash
ls -la /Users/chenyuan/Desktop/side-projects/github-learn-log && \
ls /Users/chenyuan/Desktop/side-projects/github-learn-log/{raw,daily,weekly,repos,concepts}
```
Expected: root 有 `CLAUDE.md`, `Home.md`, `_Sidebar.md`, `glossary.md`；每個子目錄有 `.gitkeep`

- [ ] **Step 8: Commit**

Run:
```bash
cd /Users/chenyuan/Desktop/side-projects/github-learn-log && \
git add CLAUDE.md Home.md _Sidebar.md glossary.md raw daily weekly repos concepts && \
git commit -m "feat: scaffold wiki dirs + CLAUDE.md schema"
```

---

### Task 2: `scan-trending` skill

**Files:**
- Create: `.claude/skills/github-learn/scan-trending/SKILL.md`

**Interfaces:**
- Consumes: 讀 `CLAUDE.md`（ingest 觸發條件）；讀 `repos/` 檔名以去重
- Produces: `shortlist.json`（暫存於 routine context，struct: `[{"url": "https://github.com/o/r", "name": "o__r", "reason": "..." }]`），供 `analyze-repo` 逐一消費

- [ ] **Step 1: 建立目錄**

Run:
```bash
mkdir -p /Users/chenyuan/Desktop/side-projects/github-learn-log/.claude/skills/github-learn/scan-trending
```

- [ ] **Step 2: 寫 SKILL.md**

Path: `/Users/chenyuan/Desktop/side-projects/github-learn-log/.claude/skills/github-learn/scan-trending/SKILL.md`

Content:
```markdown
---
name: github-learn:scan-trending
description: Scan GitHub trending, filter by topics/language and CLAUDE.md rules, exclude repos already in repos/, output 1–2 shortlisted repos with reasons.
---

# scan-trending

## 目的
每日 ingest 的第一步。依 `CLAUDE.md` 的「Ingest 觸發條件」挑 1–2 個「有架構深度 + 小到可週末重造」的 repo。

## 輸入
無（可選填時間窗，預設 last 7 days trending）。

## 步驟

1. 用 `gh api` 撈近 7 天 trending：
   ```bash
   gh api -X GET search/repositories \
     -f q='created:>2026-07-14 stars:>50' \
     -f sort=stars -f order=desc -f per_page=50
   ```
   把日期換成 `(today - 7)`。
2. 依 CLAUDE.md `Ingest 觸發條件` 過濾：
   - Topics 必須包含至少 1 個：`llm`, `agent`, `rag`, `mlops`, `distributed-systems`, `database`, `data-engineering`, `backend-framework`
   - 語言 ∈ {Python, TypeScript, Go, Rust}
3. 快速過濾（用 `gh api repos/<o>/<r>` 補資料）：
   - 有 README (`gh api repos/<o>/<r>/readme` 200 OK)
   - 檔案數 < 200（`gh api repos/<o>/<r>/git/trees/<default_branch>?recursive=1` 的 tree length）
   - 貢獻者 ≤ 5 或近 30 天只有 ≤ 3 名 active author
4. **排除已存在**：讀 `repos/` 目錄檔名（`<owner>__<repo>.md`），命中則丟棄。
5. Mini-LLM 判斷「架構深度 + 可重造」：對每個候選讀 README，用簡短判斷回答 yes/no + 一句 reason。
6. 從通過名單挑 1–2 個（若不足 1 個 → 回傳空陣列，`daily-digest` 會標註「今日 shortlist 不足」）。
7. 輸出 JSON：
   ```json
   [
     {"url": "https://github.com/o/r", "name": "o__r", "reason": "small RAG framework with novel chunking"}
   ]
   ```

## 輸出
`shortlist.json`（stdout；`analyze-repo` 逐項消費）。

## Rate limit 對策
使用 `gh auth login` 授權過的 token；命中 rate limit 時 sleep 60s 後重試一次；仍失敗則回傳 partial 並在輸出加 `"warning": "rate_limited"`。
```

- [ ] **Step 3: 驗證 frontmatter + 檔案存在**

Run:
```bash
head -5 /Users/chenyuan/Desktop/side-projects/github-learn-log/.claude/skills/github-learn/scan-trending/SKILL.md
```
Expected: 前 3 行為 `---` / `name: github-learn:scan-trending` / `description: ...`

- [ ] **Step 4: Commit**

Run:
```bash
cd /Users/chenyuan/Desktop/side-projects/github-learn-log && \
git add .claude/skills/github-learn/scan-trending/SKILL.md && \
git commit -m "feat: add scan-trending skill"
```

---

### Task 3: `analyze-repo` skill

**Files:**
- Create: `.claude/skills/github-learn/analyze-repo/SKILL.md`

**Interfaces:**
- Consumes: 一個 repo URL（來自 `scan-trending` 輸出的 shortlist 項目）；讀 `CLAUDE.md` 寫作規範；讀 `glossary.md` 決定要不要加新比喻
- Produces:
  - `raw/<owner>__<repo>.md`（原料快取）
  - `repos/<owner>__<repo>.md`（entity 頁）
  - `concept_tags`：list of slug strings（例：`["rag-chunking-strategies", "async-task-queue"]`），交給 `update-concepts`
  - 可能新增 rows 到 `glossary.md`

- [ ] **Step 1: 建立目錄**

Run:
```bash
mkdir -p /Users/chenyuan/Desktop/side-projects/github-learn-log/.claude/skills/github-learn/analyze-repo
```

- [ ] **Step 2: 寫 SKILL.md**

Path: `/Users/chenyuan/Desktop/side-projects/github-learn-log/.claude/skills/github-learn/analyze-repo/SKILL.md`

Content:
````markdown
---
name: github-learn:analyze-repo
description: Deep-analyze one GitHub repo per CLAUDE.md rules — write raw cache + entity page (800–1000 zh-TW words, mermaid arch diagram, ≥2 concept links) + emit concept tags list for update-concepts.
---

# analyze-repo

## 目的
針對一個入選 repo 做架構 / 資料設計深度分析，產出鐵人日誌風 entity 頁。

## 輸入
一個 repo URL（例：`https://github.com/owner/repo`）。

## 命名慣例
`<owner>__<repo>`（把 `/` 換成 `__`，避免路徑衝突）。例：`langchain-ai/langchain` → `langchain-ai__langchain`。

## 步驟

1. **拉原料**（存 `raw/<name>.md`）：
   - `gh api repos/<o>/<r>/readme` → base64 decode
   - 依語言拉一個 manifest：`package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml`
   - `gh api repos/<o>/<r>/git/trees/<default_branch>?recursive=1` → 頂層目錄結構（前 2 層）
   - 至多 3 個關鍵入口檔（README 提到的 `main.py`、`server/index.ts`、`cmd/main.go` 之類）
   - 全部寫成一份 `raw/<name>.md`，格式：
     ```
     # <owner>/<repo> — raw
     - URL: ...
     - Cloned at: YYYY-MM-DD
     ## README
     <原文>
     ## Manifest (<file>)
     ```<content>```
     ## Tree (top 2 levels)
     ```<tree>```
     ## Key entry files
     ### <path>
     ```<content>```
     ```

2. **寫 entity 頁**（`repos/<name>.md`）依 CLAUDE.md 寫作風格：
   - 前置 metadata block：
     ```markdown
     ---
     repo: <owner>/<repo>
     url: https://github.com/<owner>/<repo>
     lang: <primary language>
     topics: [...]
     analyzed_at: YYYY-MM-DD
     concept_tags: [slug-1, slug-2, ...]
     ---
     ```
   - 標題：`# <owner>/<repo>`
   - 六個必含區塊，順序固定：
     - `## 前言`（我怎麼看到這個 repo、為什麼在意）
     - `## 系統架構`（含 mermaid diagram）
     - `## 資料設計`（表 schema / 儲存格式 / 流動）
     - `## 為什麼這樣做`（設計取捨）
     - `## 我能學到`（帶回自己專案的具體收穫）
     - `## 重造難度`（週末可重造程度 1–5 + 阻力點）
   - 字數：800–1000（中文計字，可用 `wc -m` 驗證）
   - **至少 link 2 個 concept**：在文中用 `[[concept-slug]]` 形式標記（例：`用了 [[rag-chunking-strategies|semantic chunking]]`）；即使 concept 頁尚未建立也先標，等 `update-concepts` 補
   - 出現新比喻 → append 一 row 到 `glossary.md`

3. **產出 concept tags list**（存於執行上下文，交給 `update-concepts`）：
   - 從 metadata block 的 `concept_tags` 抽出
   - 每個 slug 為 kebab-case 名詞短語（例：`rag-chunking-strategies`）

## 輸出
- `raw/<name>.md`
- `repos/<name>.md`
- `concept_tags`（list<string>）
- 可能更新的 `glossary.md`

## 錯誤處理
- README 拉不到 → 從 metadata block 拿 description 頂替，並在文末加 `> ⚠️ 未讀 README，分析深度受限`
- 大檔（> 100KB entry file）→ 只拉前 200 行 + 加註「truncated」
````

- [ ] **Step 3: 驗證檔案**

Run:
```bash
head -5 /Users/chenyuan/Desktop/side-projects/github-learn-log/.claude/skills/github-learn/analyze-repo/SKILL.md
```
Expected: 前 3 行為 `---` / `name: github-learn:analyze-repo` / `description: ...`

- [ ] **Step 4: Commit**

Run:
```bash
cd /Users/chenyuan/Desktop/side-projects/github-learn-log && \
git add .claude/skills/github-learn/analyze-repo/SKILL.md && \
git commit -m "feat: add analyze-repo skill"
```

---

### Task 4: `update-concepts` skill

**Files:**
- Create: `.claude/skills/github-learn/update-concepts/SKILL.md`

**Interfaces:**
- Consumes: list of `(repo_name, concept_tags: list<string>)` pairs（今日 batch）；讀既有 `concepts/*.md`
- Produces: 新增或 append 到 `concepts/<slug>.md`；回報「新增/更新的 concept slugs」給 `daily-digest`

- [ ] **Step 1: 建立目錄**

Run:
```bash
mkdir -p /Users/chenyuan/Desktop/side-projects/github-learn-log/.claude/skills/github-learn/update-concepts
```

- [ ] **Step 2: 寫 SKILL.md**

Path: `/Users/chenyuan/Desktop/side-projects/github-learn-log/.claude/skills/github-learn/update-concepts/SKILL.md`

Content:
````markdown
---
name: github-learn:update-concepts
description: Given today's (repo, concept_tags) batch, upsert concepts/*.md — create new page only if ≥2 repos touched; append (never overwrite) with date stamp; return list of created/updated slugs.
---

# update-concepts

## 目的
維護跨 repo 累加的 concept 頁。同一個 concept 頁上，多次分析 append 對比與取捨，**不覆寫**。

## 輸入
```json
[
  {"repo_name": "owner__repo", "concept_tags": ["rag-chunking-strategies", "async-task-queue"]},
  ...
]
```

## 步驟

1. 建立本次 batch 的 slug set，逐一處理。
2. 對每個 slug：
   - **情況 A：`concepts/<slug>.md` 已存在** → append 一段新 section（見下方模板），並 append 底部「來源 repos」清單一項。加日期戳。
   - **情況 B：`concepts/<slug>.md` 不存在** →
     - 全歷史掃描（跨所有 `repos/*.md` 的 metadata `concept_tags`）計算「觸及此 slug 的 repo 數（含本次 batch）」
     - 若 ≥ 2 → 建立新頁（模板見下）
     - 若 = 1 → **不建立**，僅記錄為 pending（下次觸及時再開頁）
3. 回傳「本次執行新建或更新的 slug list」給 `daily-digest`。

## 新 concept 頁模板

```markdown
# <human-friendly title>

> Concept slug: `<slug>`
> 累加自跨 repo 分析。

## 定義
<一句話定義 + 為什麼值得抽出來>

## 各 repo 做法對比

<!-- +YYYY-MM-DD from owner__repo -->
### owner/repo 的做法
- 核心取捨：...
- 資料模型：...
- 適用場景：...

## 開放問題
- ...

## 來源 repos
- [owner/repo](../repos/owner__repo.md) — YYYY-MM-DD
```

## Append 模板（既有頁）

在「各 repo 做法對比」段末尾 append：
```markdown

<!-- +YYYY-MM-DD from owner__repo -->
### owner/repo 的做法
- 核心取捨：...
- 資料模型：...
- 適用場景：...
```

並在「來源 repos」清單 append `- [owner/repo](../repos/owner__repo.md) — YYYY-MM-DD`。

## 輸出
- 新增/更新的 `concepts/*.md`
- Return value：`{"created": [...], "updated": [...]}` 供 `daily-digest` 顯示
````

- [ ] **Step 3: 驗證檔案**

Run:
```bash
head -5 /Users/chenyuan/Desktop/side-projects/github-learn-log/.claude/skills/github-learn/update-concepts/SKILL.md
```

- [ ] **Step 4: Commit**

Run:
```bash
cd /Users/chenyuan/Desktop/side-projects/github-learn-log && \
git add .claude/skills/github-learn/update-concepts/SKILL.md && \
git commit -m "feat: add update-concepts skill"
```

---

### Task 5: `daily-digest` skill

**Files:**
- Create: `.claude/skills/github-learn/daily-digest/SKILL.md`

**Interfaces:**
- Consumes: 今日已 analyzed repos（list of `repo_name`）+ `update-concepts` 的 `{"created": [...], "updated": [...]}`
- Produces:
  - `daily/YYYY-MM-DD.md`
  - `Home.md` 更新（append 到「日報」段）
  - Discord daily payload：`{"title": "...", "body": "..."}` 供 `discord:reply`

- [ ] **Step 1: 建立目錄**

Run:
```bash
mkdir -p /Users/chenyuan/Desktop/side-projects/github-learn-log/.claude/skills/github-learn/daily-digest
```

- [ ] **Step 2: 寫 SKILL.md**

Path: `/Users/chenyuan/Desktop/side-projects/github-learn-log/.claude/skills/github-learn/daily-digest/SKILL.md`

Content:
````markdown
---
name: github-learn:daily-digest
description: Write daily/YYYY-MM-DD.md with 1–2 repo cards, append to Home.md index, build Discord daily payload with Cloudflare Pages URL.
---

# daily-digest

## 目的
每日 ingest 的最後一步：把當日產出整合成日報 + Discord 推播 payload。

## 輸入
- `analyzed_today`: list of `{"repo_name": "owner__repo", "url": "...", "one_liner": "..."}`（`analyze-repo` 執行時保留）
- `concept_changes`: `{"created": [...], "updated": [...]}`（來自 `update-concepts`）
- `today`: `YYYY-MM-DD`

## 步驟

1. **寫 `daily/<today>.md`**：
   ```markdown
   # 日報 <today>

   > 本日分析 N 個 repo。

   ## Repos

   ### [owner/repo](../repos/owner__repo.md)
   - 一句話：<from analyze-repo>
   - Bullet 1
   - Bullet 2
   - Bullet 3

   （若 N=0，改印：`> 今日 shortlist 不足，未新增 repo。`）

   ## Concept 更新
   - 新增：`slug-a`, `slug-b`（若無則印「無」）
   - 更新：`slug-c`（若無則印「無」）
   ```

2. **更新 `Home.md`**：
   - 找到「### 日報」段，最上方 append 一列：`- [YYYY-MM-DD](daily/YYYY-MM-DD.md) — N repo`
   - 若 repo 出現新 topic（例：`llm-agent`）尚未在「分類 tag」段，補進去

3. **構造 Discord daily payload**：
   ```
   標題：📚 github-learn 日報 YYYY-MM-DD
   本文：
   本日 N 個 repo：
   1. **owner/repo** — 一句話
      - bullet 1
      - bullet 2
      - bullet 3
      🔗 https://github-learn-log.pages.dev/repos/owner__repo/
   （若有 concept 變動）
   Concept 更新：slug-a（新增）、slug-c（更新）
   ```
   - Pages base URL：`https://github-learn-log.pages.dev`（或未來自訂域）
   - 若 N=0 → 內容改為「今日 shortlist 不足，明日再戰。」

4. **git commit + push**：
   ```bash
   git add daily/<today>.md Home.md repos/ concepts/ raw/ glossary.md
   git commit -m "chore(daily): <today> — N repos"
   git push origin main
   ```
   （push 會觸發 Cloudflare Pages 重 build）

5. **Discord push**：呼叫 `discord:reply` with chat_id from Discord config，body 即步驟 3 的 payload。

## 輸出
- `daily/<today>.md`
- 更新的 `Home.md`
- 推播完成的 Discord message
````

- [ ] **Step 3: 驗證檔案**

Run:
```bash
head -5 /Users/chenyuan/Desktop/side-projects/github-learn-log/.claude/skills/github-learn/daily-digest/SKILL.md
```

- [ ] **Step 4: Commit**

Run:
```bash
cd /Users/chenyuan/Desktop/side-projects/github-learn-log && \
git add .claude/skills/github-learn/daily-digest/SKILL.md && \
git commit -m "feat: add daily-digest skill"
```

---

### Task 6: `weekly-digest` skill

**Files:**
- Create: `.claude/skills/github-learn/weekly-digest/SKILL.md`

**Interfaces:**
- Consumes: 本週 `daily/YYYY-MM-DD.md × 7`（週一到週日）；本週被更新的 concept slugs；`glossary.md`
- Produces:
  - `weekly/YYYY-Www.md`
  - `Home.md` 更新（append 到「週報」段）
  - Discord weekly payload

- [ ] **Step 1: 建立目錄**

Run:
```bash
mkdir -p /Users/chenyuan/Desktop/side-projects/github-learn-log/.claude/skills/github-learn/weekly-digest
```

- [ ] **Step 2: 寫 SKILL.md**

Path: `/Users/chenyuan/Desktop/side-projects/github-learn-log/.claude/skills/github-learn/weekly-digest/SKILL.md`

Content:
````markdown
---
name: github-learn:weekly-digest
description: On Sunday, aggregate the week's daily/*.md into weekly/YYYY-Www.md — cards + cross-repo comparison table (only for concept tags hit by ≥2 repos), one-liner theme, Discord weekly payload.
---

# weekly-digest

## 目的
週日 daily 執行完之後接續跑。把本週所有 daily 檔整合成一份週報。

## 觸發條件
`date +%u` == `7`（週日）。routine 主 prompt 判斷。

## 輸入
- `week_id`: `YYYY-Www`（ISO week，例：`2026-W29`）
- `week_start`, `week_end`: `YYYY-MM-DD`（週一 / 週日）

## 步驟

1. **讀本週 daily 檔**：
   - 掃 `daily/YYYY-MM-DD.md`，篩 `week_start ≤ date ≤ week_end` 的檔
   - 從每份 daily 抽出 repos（用 metadata / heading parse）
2. **讀本週被更新的 concept**：
   - 掃所有 `concepts/*.md`，grep `<!-- +YYYY-MM-DD from ... -->` 落在本週的
3. **寫 `weekly/<week_id>.md`**：
   ```markdown
   # 週報 <week_id> (<week_start> ~ <week_end>)

   > 本週 N 個 repo。

   ## 本週主軸
   <LLM 依 N 個 repo 的共通性寫一句話，例：「本週 3 個 RAG framework，chunking 策略取捨不同」>

   ## Repos 總覽
   <每個 repo 一張卡片，複製 daily 卡片格式 + link 到 daily 檔>

   ## 橫向比較

   <對每個「本週 ≥ 2 個 repo 觸及」的 concept 產一個表>

   ### Concept: [rag-chunking-strategies](../concepts/rag-chunking-strategies.md)

   | Repo | 核心取捨 | 資料模型 | 適用場景 |
   |---|---|---|---|
   | owner/repo1 | ... | ... | ... |
   | owner/repo2 | ... | ... | ... |

   （只有 1 個 repo 的 concept 不列表）

   ## Concept 頁本週更新
   - `slug-a`（新增）
   - `slug-c`（append）

   ## 相關 daily
   - [YYYY-MM-DD](../daily/YYYY-MM-DD.md)
   - ...
   ```

4. **更新 `Home.md`**：「### 週報」段最上方 append `- [YYYY-Www](weekly/YYYY-Www.md) — N repo`

5. **構造 Discord weekly payload**：
   ```
   標題：📚 github-learn 週報 <week_id>
   本文：
   <一句話主軸>

   Top 3 亮點：
   1. owner/repo — 一句話 🔗 https://github-learn-log.pages.dev/repos/owner__repo/
   2. ...
   3. ...

   本週新增/更新 concept：slug-a, slug-c

   完整週報 🔗 https://github-learn-log.pages.dev/weekly/<week_id>/
   ```
   Top 3 挑選：LLM 依「個人學習價值」排序，不是 star 數。

6. **git commit + push**：
   ```bash
   git add weekly/<week_id>.md Home.md
   git commit -m "chore(weekly): <week_id> — N repos"
   git push origin main
   ```

7. **Discord push**：呼叫 `discord:reply` with 步驟 5 payload。

## 輸出
- `weekly/<week_id>.md`
- 更新的 `Home.md`
- 推播完成的 Discord weekly message
````

- [ ] **Step 3: 驗證檔案**

Run:
```bash
head -5 /Users/chenyuan/Desktop/side-projects/github-learn-log/.claude/skills/github-learn/weekly-digest/SKILL.md
```

- [ ] **Step 4: Commit**

Run:
```bash
cd /Users/chenyuan/Desktop/side-projects/github-learn-log && \
git add .claude/skills/github-learn/weekly-digest/SKILL.md && \
git commit -m "feat: add weekly-digest skill"
```

---

### Task 7: MkDocs 設定（Cloudflare Pages build）

**Files:**
- Create: `mkdocs.yml`
- Create: `requirements.txt`
- Create: `.gitignore`

**Interfaces:**
- Consumes: 所有 wiki markdown（`Home.md`, `daily/`, `weekly/`, `repos/`, `concepts/`, `glossary.md`）
- Produces: `site/` 靜態站（Cloudflare Pages 消費）

- [ ] **Step 1: 寫 `mkdocs.yml`**

Path: `/Users/chenyuan/Desktop/side-projects/github-learn-log/mkdocs.yml`

Content:
```yaml
site_name: github-learn-log
site_description: 個人 GitHub trending 學習軌跡
site_url: https://github-learn-log.pages.dev

docs_dir: .
site_dir: site

exclude_docs: |
  raw/
  docs/
  .claude/
  README.md
  _Sidebar.md
  requirements.txt
  mkdocs.yml
  .gitignore
  node_modules/

theme:
  name: material
  language: zh-TW
  features:
    - navigation.sections
    - navigation.expand
    - navigation.top
    - toc.integrate
    - search.suggest
    - search.highlight
    - content.code.copy

nav:
  - 首頁: Home.md
  - 日報:
      - daily
  - 週報:
      - weekly
  - Repos:
      - repos
  - Concepts:
      - concepts
  - Glossary: glossary.md

plugins:
  - search
  - awesome-pages

markdown_extensions:
  - admonition
  - tables
  - toc:
      permalink: true
  - pymdownx.superfences:
      custom_fences:
        - name: mermaid
          class: mermaid
          format: !!python/name:pymdownx.superfences.fence_code_format
  - pymdownx.details
  - pymdownx.highlight
  - pymdownx.inlinehilite

extra_javascript:
  - https://unpkg.com/mermaid@10/dist/mermaid.min.js
```

- [ ] **Step 2: 寫 `requirements.txt`**

Path: `/Users/chenyuan/Desktop/side-projects/github-learn-log/requirements.txt`

Content:
```
mkdocs-material==9.5.42
mkdocs-awesome-pages-plugin==2.9.3
pymdown-extensions==10.11.2
```

- [ ] **Step 3: 寫 `.gitignore`**

Path: `/Users/chenyuan/Desktop/side-projects/github-learn-log/.gitignore`

Content:
```
site/
.cache/
__pycache__/
*.pyc
.venv/
node_modules/
.DS_Store
```

- [ ] **Step 4: 本地 build 驗證**

Run:
```bash
cd /Users/chenyuan/Desktop/side-projects/github-learn-log && \
python3 -m venv .venv && \
source .venv/bin/activate && \
pip install -r requirements.txt && \
mkdocs build --strict
```
Expected: `INFO - Documentation built in ...s`，`site/` 目錄產生；`site/index.html` 存在。

若因目前 `daily/`、`repos/` 只有 `.gitkeep` 導致 nav 報 warning，先跑 `mkdocs build`（不加 `--strict`）確認能 build。

- [ ] **Step 5: 開瀏覽器手動確認**

Run:
```bash
cd /Users/chenyuan/Desktop/side-projects/github-learn-log && \
source .venv/bin/activate && \
mkdocs serve
```
Expected: `Serving on http://127.0.0.1:8000`。瀏覽器打開，看到 Home 頁 + 側欄 5 個分類。

按 `Ctrl-C` 停掉。

- [ ] **Step 6: Commit**

Run:
```bash
cd /Users/chenyuan/Desktop/side-projects/github-learn-log && \
git add mkdocs.yml requirements.txt .gitignore && \
git commit -m "feat: add mkdocs + cloudflare pages build config"
```

---

### Task 8: 端對端 dry-run 一個 fixture repo

**Files:**
- Modify: `raw/<name>.md`, `repos/<name>.md`, `concepts/*.md`, `daily/YYYY-MM-DD.md`, `Home.md`, 可能 `glossary.md`

**Interfaces:**
- Consumes: 前 6 個 task 產出的所有 skill
- Produces: 一份完整的 daily 產物（走完 scan → analyze → update-concepts → daily-digest 路徑），驗證整條 pipeline 正確

- [ ] **Step 1: 挑一個 fixture repo**

選 `karpathy/nanoGPT`（小、有 README、架構清楚，好驗證）。若已 star 過 / 熟悉的 repo 亦可。

- [ ] **Step 2: 手動跑 analyze-repo（跳過 scan-trending）**

在專案根目錄開 Claude Code session，輸入：
```
依 .claude/skills/github-learn/analyze-repo/SKILL.md，
對 https://github.com/karpathy/nanoGPT 執行完整流程。
```

Expected 產出：
- `raw/karpathy__nanoGPT.md`（有 README / manifest / tree）
- `repos/karpathy__nanoGPT.md`（六個必含區塊、mermaid、≥ 2 個 `[[concept-slug]]`）

- [ ] **Step 3: 驗證 entity 頁符合 CLAUDE.md 規範**

Run:
```bash
cd /Users/chenyuan/Desktop/side-projects/github-learn-log && \
echo "--- word count ---" && wc -m repos/karpathy__nanoGPT.md && \
echo "--- 必含區塊 ---" && grep -E '^## (前言|系統架構|資料設計|為什麼這樣做|我能學到|重造難度)' repos/karpathy__nanoGPT.md && \
echo "--- mermaid ---" && grep -c '```mermaid' repos/karpathy__nanoGPT.md && \
echo "--- concept links ---" && grep -oE '\[\[[a-z-]+' repos/karpathy__nanoGPT.md | sort -u
```
Expected:
- word count: ~800–1200（中文計字 `wc -m`）
- 六個 heading 全部命中
- mermaid ≥ 1
- 至少 2 個不同 concept slug

若不符 → 回頭修 `repos/karpathy__nanoGPT.md` 或修 `.claude/skills/github-learn/analyze-repo/SKILL.md` 補規則明確度，再重跑。

- [ ] **Step 4: 手動跑 update-concepts**

在同一 session 輸入：
```
依 .claude/skills/github-learn/update-concepts/SKILL.md，
處理 [{"repo_name": "karpathy__nanoGPT", "concept_tags": [<step 3 撈到的 slugs>]}]。
```

Expected：因每個 slug 目前只有 1 個 repo 觸及 → 全部應該 pending，不建新頁。手動確認 `concepts/` 仍空。

（後續第二個 repo 觸及同 slug 時才會開頁 — 這是預期行為，不是 bug）

- [ ] **Step 5: 手動跑 daily-digest**

在同一 session 輸入：
```
依 .claude/skills/github-learn/daily-digest/SKILL.md，
analyzed_today=[{"repo_name":"karpathy__nanoGPT","url":"https://github.com/karpathy/nanoGPT","one_liner":"<你剛寫的一句話>"}]，
concept_changes={"created":[],"updated":[]}，
today=<今天>。
只寫檔，不推 Discord、不 push。
```

Expected：
- `daily/YYYY-MM-DD.md` 新增
- `Home.md` 有新的日報 index 項

- [ ] **Step 6: mkdocs 本地 build 驗證 Pages 能渲染**

Run:
```bash
cd /Users/chenyuan/Desktop/side-projects/github-learn-log && \
source .venv/bin/activate && \
mkdocs build && \
ls site/repos/karpathy__nanoGPT/ && \
ls site/daily/
```
Expected: `site/repos/karpathy__nanoGPT/index.html` 存在；`site/daily/<today>/index.html` 存在。

打開 `site/repos/karpathy__nanoGPT/index.html` 檢查 mermaid diagram 有渲染（可能需要 `mkdocs serve` 才能看到 JS 生效）。

- [ ] **Step 7: Commit fixture 產出**

Run:
```bash
cd /Users/chenyuan/Desktop/side-projects/github-learn-log && \
git add raw/ repos/ daily/ Home.md glossary.md && \
git commit -m "docs: e2e dry-run with karpathy/nanoGPT fixture"
```

---

### Task 9: Cloudflare Pages 綁定 GitHub

**Files:** 無 code diff（外部 config）

**Interfaces:**
- Consumes: `mkdocs.yml` + `requirements.txt`（Task 7 產出）
- Produces: 一個 `https://github-learn-log.pages.dev`（或自訂域）可訪問的 URL；每次 `main` push 自動 rebuild

- [ ] **Step 1: 確保 GitHub remote 已 push**

Run:
```bash
cd /Users/chenyuan/Desktop/side-projects/github-learn-log && \
git push origin main
```
Expected: `main` 上遠端與本地一致。

- [ ] **Step 2: 到 Cloudflare Dashboard 建 Pages project**

手動步驟（使用者操作，Claude 無法 self-serve）：

1. 打開 https://dash.cloudflare.com → Pages
2. Create project → Connect to Git → 選 `a920604a/github-learn-log`
3. Build settings：
   - Production branch: `main`
   - Build command: `pip install -r requirements.txt && mkdocs build`
   - Build output directory: `site`
   - Environment variables: `PYTHON_VERSION=3.11`
4. Save and Deploy

- [ ] **Step 3: 驗證第一次 deploy 成功**

到 Cloudflare Dashboard → Pages → github-learn-log → Deployments。看到 latest deployment status = Success。

打開 `https://github-learn-log.pages.dev`（或 CF 給的 URL），確認 Home 頁 + fixture repo 頁能開。

- [ ] **Step 4: 更新 Pages base URL 到 skills（若非預設）**

若最終 URL 不是 `https://github-learn-log.pages.dev`（例：`https://foo-bar.pages.dev`）：

- Edit `.claude/skills/github-learn/daily-digest/SKILL.md` — 把 `https://github-learn-log.pages.dev` 全換
- Edit `.claude/skills/github-learn/weekly-digest/SKILL.md` — 同上

Commit:
```bash
cd /Users/chenyuan/Desktop/side-projects/github-learn-log && \
git add .claude/skills/github-learn/ && \
git commit -m "chore: update pages URL in daily/weekly-digest skills"
```

若 URL 為預設 `https://github-learn-log.pages.dev` → 跳過 commit。

---

### Task 10: Discord bot 綁定

**Files:** 無 code diff（透過 `discord:configure` skill 寫入外部 config）

**Interfaces:**
- Consumes: 使用者的 Discord bot token + target channel id
- Produces: 已授權的 chat_id，供 daily/weekly-digest `discord:reply` 呼叫

- [ ] **Step 1: 準備 Discord bot**

若還沒有 bot：到 Discord Developer Portal 建一個 bot，取得 token；把 bot 邀請到目標 channel。

- [ ] **Step 2: 執行 `discord:configure`**

在 Claude Code session 輸入：
```
/discord:configure
```
依 skill 引導：貼 bot token → 選 policy → 記下 channel id（chat_id）。

- [ ] **Step 3: 手動測 Discord push**

在 Claude Code session 輸入：
```
用 discord:reply 傳一句 "github-learn-log 綁定成功 ✅" 到 chat_id=<上一步的 id>。
```

Expected: Discord channel 收到訊息。

- [ ] **Step 4: 把 chat_id 記到 CLAUDE.md**

Edit `CLAUDE.md`，在檔尾新增一段：

```markdown
## Discord 推播設定
- daily/weekly-digest 推播的 chat_id：`<實際 id>`
- Policy 已透過 discord:configure 設定
```

Commit:
```bash
cd /Users/chenyuan/Desktop/side-projects/github-learn-log && \
git add CLAUDE.md && \
git commit -m "docs: record discord chat_id in CLAUDE.md"
```

---

### Task 11: Cron routine 設置

**Files:** 無 code diff（透過 `/schedule` skill 建 routine）

**Interfaces:**
- Consumes: 所有 skills（Task 2-6）+ CLAUDE.md
- Produces: 每天 20:00 (Asia/Taipei) 自動觸發的 routine；週日還會多跑 weekly-digest

- [ ] **Step 1: 用 `/schedule` 建 routine**

在 Claude Code session 輸入：
```
/schedule
```

Skill 引導時：
- Name: `github-learn-daily`
- Cron: `0 20 * * *` (每天 20:00)
- Timezone: `Asia/Taipei`
- Repo: `https://github.com/a920604a/github-learn-log`
- Branch: `main`
- Prompt（極短）：
  ```
  執行今日 github-learn ingest。
  步驟：
  1. 依 .claude/skills/github-learn/scan-trending/SKILL.md 挑 1–2 repo
  2. 對每個 repo 執行 .claude/skills/github-learn/analyze-repo/SKILL.md
  3. 執行 .claude/skills/github-learn/update-concepts/SKILL.md
  4. 執行 .claude/skills/github-learn/daily-digest/SKILL.md
  5. 若 `date +%u` == 7（週日），接續執行 .claude/skills/github-learn/weekly-digest/SKILL.md
  ```

- [ ] **Step 2: 手動觸發一次驗證**

用 `/schedule` 的 run-now 功能觸發一次；或直接在本地 session 貼上步驟 1 的 prompt 執行。

Expected：
- `daily/YYYY-MM-DD.md`（今天）產生
- 1–2 個新的 `repos/<name>.md`
- `Home.md` 更新
- Discord daily 訊息收到
- `main` 分支 push 成功 → Cloudflare Pages rebuild → 新頁上線

- [ ] **Step 3: 驗證每個管道**

Run（本地）：
```bash
cd /Users/chenyuan/Desktop/side-projects/github-learn-log && \
git log --oneline -5 && \
ls daily/ && \
ls repos/ | tail -5
```
Expected: 最新 commit 是 `chore(daily): ...`；`daily/` 有今天檔；`repos/` 有新增。

外部驗證：
- Discord channel：有今日日報
- `https://github-learn-log.pages.dev/daily/<today>/`：能開，內容正確

- [ ] **Step 4: 觀察 3 天穩定性**

（此步為觀察期，非立即執行）
每天檢查：
- Discord 是否有推播
- CF Pages deployment 是否 success
- `main` 有沒有 daily commit

若連續 3 天正常 → 專案上線完成。

---

## Self-Review 檢查表

**1. Spec 覆蓋（對照 `docs/superpowers/specs/2026-07-21-github-learn-log-design.md`）：**
- §1 五個目標：Task 1（wiki 骨架）、Task 2–6（skills）、Task 8（e2e）、Task 9（CF Pages）、Task 10（Discord）、Task 11（cron 觸發每日 ingest）✅
- §2.1 目錄結構：Task 1 全部建立 ✅
- §2.2 三層架構：`raw/` 由 analyze-repo 寫 / `repos/`、`concepts/`、`daily/`、`weekly/` 由對應 skill 寫 / `CLAUDE.md` + `.claude/skills/` 由 Task 1、2–6 建 ✅
- §3.1 每日流程：Task 11 routine prompt 明列 4 步 ✅
- §3.2 每週流程：Task 11 routine prompt 條件執行 weekly-digest ✅
- §4.1–4.5 五 skills：Task 2–6 一對一 ✅
- §5 CLAUDE.md 內容：Task 1 step 2 逐字寫入 ✅
- §6 Routine：Task 11 ✅
- §7.1 日報推播：daily-digest step 3 + Task 11 ✅
- §7.2 週報推播：weekly-digest step 5 + Task 11 ✅
- §8 錯誤處理：scan-trending step 7（rate limit）、daily-digest step 1（N=0 fallback）、Task 11 觀察期 ✅
- §12 Cloudflare Pages：Task 7（mkdocs 設定）+ Task 9（CF 綁定）✅

**2. Placeholder 掃描：** 無 TBD / TODO / 「implement later」／「add error handling」／「similar to Task N」空指令 ✅

**3. Type consistency：**
- `scan-trending` 輸出 `[{url, name, reason}]` → `analyze-repo` 消費 `url`，`name` 用 `owner__repo` 慣例（Task 3 明列）✅
- `analyze-repo` 輸出 `concept_tags: list<string>` → `update-concepts` 輸入 `[{repo_name, concept_tags}]` ✅
- `update-concepts` 回傳 `{created: [...], updated: [...]}` → `daily-digest` 消費 `concept_changes` 同 shape ✅
- `daily-digest` 產出 `daily/YYYY-MM-DD.md` → `weekly-digest` 讀 `daily/YYYY-MM-DD.md × 7` ✅

Plan 定案。
