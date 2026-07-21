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

```markdown
# 日報 <today>

> 本日分析 <N> 個 repo。

## Repos

### [owner/repo](../repos/owner__repo.md)
- 一句話：<from analyze-repo one_liner>
- Bullet 1（LLM 從 repos/<name>.md 抽 3 個要點）
- Bullet 2
- Bullet 3

（每個 repo 一段；若 N=0 改印：`> 今日 shortlist 不足，未新增 repo。`）

## Concept 更新
- 新增：`slug-a`, `slug-b`（若無則印「無」）
- 更新：`slug-c`（若無則印「無」）
- Pending（等下次觸及開頁）：`slug-d`（若無則省略此列）
```

### 2. 更新 `Home.md`

找到「### 日報」段，最上方 append 一列：
```
- [YYYY-MM-DD](daily/YYYY-MM-DD.md) — N repo
```

找到「### Repos」段，為本日每個 repo append：
```
- [owner/repo](repos/owner__repo.md)
```

若新 repo 有新 topic 尚未在「## 分類 tag」段 → 補進去。

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

### 5. Discord push（若 chat_id 已設定）

- 從 `CLAUDE.md` 讀「## Discord 推播設定」的 chat_id
- 呼叫 `discord:reply` with `chat_id`, body = step 3 payload
- 若無 chat_id 或 Discord tool 不可用 → skip 並在 log 印「Discord skipped: <reason>」

## 輸出
- `daily/<today>.md`
- 更新的 `Home.md`
- push 成功的 commit
- （可選）推播完成的 Discord message
