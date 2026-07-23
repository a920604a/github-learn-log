---
name: github-learn:daily-digest
description: Write daily/YYYY-MM-DD.md with 1-2 repo cards, append to Home.md index, prepare Discord daily payload, git commit + push.
---

# daily-digest

## 目的
每日 ingest 的最後一步：把當日產出整合成日報 + Discord 推播 payload。

## 輸入
- `analyzed_today`: `[{"repo_name": "owner__repo", "url": "...", "one_liner": "..."}]`（`analyze-repo` 執行時保留）
- `concept_changes`: `{"created": [...], "updated": [...], "pending": [...]}`（來自 `update-concepts`）
- `today`: `YYYY-MM-DD`（用 `date +%Y-%m-%d`）

## 步驟

### 1. 寫 `daily/<today>.md`

**所有 section header 必須用中文**（本專案 wiki 展示語言為繁體中文）。

```markdown
# 日報 <today>

> 本日分析 <N> 個專案。

## 本日專案

### [owner/repo](../repos/owner__repo.md)
- 一句話：<from analyze-repo one_liner>
- 要點 1（LLM 從 repos/<name>.md 抽 3 個要點）
- 要點 2
- 要點 3

（每個專案一段；若 N=0 改印：`> 今日候選不足，未新增專案。`）

## 概念更新
- 新增：`slug-a`, `slug-b`（若無則印「無」）
- 更新：`slug-c`（若無則印「無」）
- 待累加（下次觸及再開頁）：`slug-d`（若無則省略此列）
```

### 2. 更新 `Home.md`

找到「### 日報」段，最上方 append 一列：
```
- [YYYY-MM-DD](daily/YYYY-MM-DD.md) — <N> 個專案
```

找到「### 專案（Repos）」段，為本日每個專案 append：
```
- [owner/repo](repos/owner__repo.md) — YYYY-MM-DD
```

若新專案有新 topic 尚未在「## 分類標籤」段 → 補進去。

### 3. 構造 Discord daily payload（暫存為變數，供推播步驟用）

```
標題：📚 github-learn 日報 YYYY-MM-DD

本日 N 個 repo：

1. **owner/repo** — 一句話
   • bullet 1
   • bullet 2
   • bullet 3
   🔗 https://github.com/a920604a/github-learn-log/blob/main/repos/owner__repo.md

（若有 concept 變動）
Concept 更新：slug-a（新增）、slug-c（更新）
```

若 N=0 → 內容改為「今日 shortlist 不足，明日再戰。」

**（Pages URL 之後啟用時，把 GitHub raw link 換成 `https://github-learn-log.pages.dev/repos/owner__repo/`）**

### 4. git commit + push

```bash
cd /path/to/github-learn-log
git add daily/<today>.md Home.md repos/ concepts/ raw/ glossary.md
git commit -m "chore(daily): <today> — <N> repos"
git push origin main
```

### 5. Discord push（webhook 模式）

遠端 routine 環境沒有 Discord bot / MCP，只能用 webhook POST。

- 讀環境變數 `DISCORD_WEBHOOK_URL`（由 routine prompt 注入；本地執行時可能無）
- 若未設 → skip，log 印「Discord skipped: DISCORD_WEBHOOK_URL not set」
- 若已設：

```bash
curl -sS -X POST \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg content "$DAILY_PAYLOAD" '{
    username: "github-learn-log routine",
    content: $content
  }')" \
  "$DISCORD_WEBHOOK_URL"
```

其中 `$DAILY_PAYLOAD` = step 3 構造出的文本（≤ 2000 字元，超過就截斷並在末尾加「... 完整內容請看 wiki」）。

**注意事項**
- Webhook URL 是 secret，不要 echo 到 stdout / log
- HTTP 204 = 成功；其他狀態碼要 log 錯誤但不 fail pipeline（wiki 已 commit 就好）

## 輸出
- `daily/<today>.md`
- 更新的 `Home.md`
- push 成功的 commit
- （可選）推播完成的 Discord message
