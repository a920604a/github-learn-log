# github-learn ingest — pipeline prompt

執行今日 github-learn ingest。你是 GitHub Actions runner 上的 Claude CLI，`ANTHROPIC_API_KEY` 與 `DISCORD_WEBHOOK_URL` 已由 workflow 注入到環境變數，**不要 echo 這兩個值**（尤其不要寫進任何會被 commit 的檔或 stdout 印出）。

你在 checkout 好的 `github-learn-log` repo 內執行；先 `cat CLAUDE.md` 理解 wiki schema（特別注意「展示語言」段：**所有 section header 一律繁中**），再依序讀 `.claude/skills/github-learn/*/SKILL.md` 五份 skill file 作為 spec，然後跑：

## 1. scan-trending

用 curl GitHub search API（unauth 60/hr rate limit 足夠），找近 90 天 `stars:>200`、topic 命中 llm/agent/rag/mlops/database/data-engineering/backend-framework 其一、語言 ∈ {Python,TypeScript,Go,Rust}。

**排除**已存在 `repos/<owner>__<repo>.md` 的 repo。

挑 1–2 個「架構深度 + 週末可重造」候選。不足 1 個 → 日報說明，不硬湊。

## 2. analyze-repo × N

對每個入選 repo：curl 拉 README + tree + manifest（package.json / pyproject.toml / go.mod / Cargo.toml 擇一）+ ARCHITECTURE.md/AGENTS.md 若存在。

存 `raw/<owner>__<repo>.md`。依 CLAUDE.md 寫作規範產出 `repos/<owner>__<repo>.md`：

- YAML frontmatter（key 英文：repo/url/lang/topics/stars/analyzed_at/concept_tags）
- **6 個中文 section header 必含且順序固定**：
  - `## 前言`
  - `## 系統架構`（含 mermaid）
  - `## 資料設計`
  - `## 為什麼這樣做`
  - `## 我能學到`
  - `## 費曼式回顧`
- 800–1000 字繁體中文、鐵人日誌筆調、第一人稱「我」
- 文中用 `[[concept-slug]]` 形式 link 至少 2 個 concept slug
- 新比喻 → append 到 `glossary.md`

### 費曼式回顧的寫法（重要，別漏）
內含三小段（每段 60–100 字）：
1. **用生活比喻重講一次**（先想一個具體日常場景 — 廚房 / 塞車 / 便當店 / 咖啡店 / 積木 / 學校規則 …，避開 API / schema / runtime / DAG / RAG 等術語，直接用比喻詞代替）
2. **你接下來最可能誤解的 3 個地方**（LLM 站讀者角度預測 3 個「以為 X 但實際上 Y」的常見盲點，用對照格式列出）
3. **換你解釋**（一句話邀請讀者用自己的話講一遍）

依據：史丹佛 AI 教育應用研究，AI 輔助能顯著提升主動學習成效；費曼學習法結合 LLM 可最大化記憶保留率。LLM 在此扮演「讀者的學生」，主動暴露理解漏洞。

## 3. update-concepts

對每個 concept slug，掃 `repos/*.md` frontmatter 統計觸及次數（含本次）。

- **≥ 2 個 repo** 才建 `concepts/<slug>.md`（用 SKILL.md 模板，所有 section header 中文：`## 定義` / `## 各專案做法對比` / `## 開放問題` / `## 來源專案`）
- 已存在則 append 新 section + 更新「來源專案」清單，加日期戳 `<!-- +YYYY-MM-DD from <name> -->`，**不覆寫**
- 只 1 個 repo 觸及的 slug 記為 pending

## 4. daily-digest

寫 `daily/$(date +%Y-%m-%d).md`（section header 全中文：`## 本日專案` / `## 概念更新`）。

更新 `Home.md`：
- append 到「### 日報」、「### 專案（Repos）」、「### 概念（Concepts）」
- 新 topic 補到「## 分類標籤」

**Discord push（SKILL step 5）**：構造日報 payload（≤ 2000 字元；Discord 訊息裡 wiki 連結一律用 `https://github-learn-log.pages.dev/...`），呼叫：

```bash
curl -sS -X POST -H "Content-Type: application/json" \
  -d "$(jq -n --arg content "$DAILY_PAYLOAD" '{
    username: "github-learn-log routine",
    content: $content
  }')" \
  "$DISCORD_WEBHOOK_URL"
```

HTTP 204 = 成功。其他狀態碼 log 錯誤但不 fail pipeline（wiki 產出比 Discord 通知重要）。

## 5. weekly-digest（僅週日）

```bash
if [ "$(date +%u)" = "7" ]; then
  # 依 SKILL.md 產 weekly/$(date +%G-W%V).md
  # section header 全中文：本週主軸 / 本週專案總覽 / 橫向比較 / 本週概念更新 / 相關日報
  # 更新 Home.md 週報段
  # Discord push (SKILL step 7)：week payload → curl webhook
fi
```

## 6. 寫檔完畢

GH Actions workflow 的下一步會呼 `git add + commit + push origin main`，**你不用碰 git**。你只要確定：
- 所有該寫的檔都寫好
- 內容格式正確
- 沒有把 secrets 寫進去

---

## 全局約束

- 所有 wiki 輸出（文件內容 + section header）**一律繁中**；commit message 英文
- 命名 `<owner>__<repo>`（`/` → `__`）
- concept 頁 `<!-- +YYYY-MM-DD from ... -->` 日期戳必填
- Discord 訊息裡 wiki 連結一律用 `https://github-learn-log.pages.dev/...`
- API rate-limited → sleep 60s 重試一次；仍失敗 → partial 結果 + 日報加 `> ⚠️ API rate limited, partial run`
- pipeline 錯誤 → 仍要寫一份 `daily/YYYY-MM-DD.md` 內容為錯誤摘要 + 已完成步驟；不要靜默 fail
- **絕不要 echo `ANTHROPIC_API_KEY` 或 `DISCORD_WEBHOOK_URL` 到任何可及 commit 的檔或 log**
- 執行環境是 Ubuntu runner，`bash` / `curl` / `jq` / `git` 都在；`base64` 是 GNU 版

開始執行。
