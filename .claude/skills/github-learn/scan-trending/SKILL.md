---
name: github-learn:scan-trending
description: Scan GitHub trending, filter by topics/language per CLAUDE.md, exclude repos already in repos/, output 1-2 shortlisted repos with reasons.
---

# scan-trending

## 目的
每日 ingest 的第一步。依 `CLAUDE.md` 的「Ingest 觸發條件」挑 1–2 個「有架構深度 + 小到可週末重造」的 repo。

## 輸入
無（可選填時間窗，預設 last 30 days）。

## 步驟

1. 用 `gh` CLI 撈近 30 天有起 traction 的 repo：
   ```bash
   THIRTY_DAYS_AGO=$(date -u -v-30d +%Y-%m-%d 2>/dev/null || date -u -d '30 days ago' +%Y-%m-%d)
   gh api -X GET search/repositories \
     -f q="created:>${THIRTY_DAYS_AGO} stars:>200" \
     -f sort=stars -f order=desc -f per_page=50 \
     --jq '.items[] | {full_name, html_url, description, language, stargazers_count, topics, size}'
   ```

2. 依 CLAUDE.md `Ingest 觸發條件` 過濾：
   - `language` ∈ {Python, TypeScript, JavaScript, Go, Rust}
   - `topics` 至少命中一個：`llm`, `agent`, `agents`, `rag`, `mlops`, `distributed-systems`, `database`, `data-engineering`, `backend`, `backend-framework`, `vector-database`, `orchestration`
   - `size` < 20000 (KB，約 20 MB 專案上限)

3. 對通過候選補資料（用 `gh api repos/<owner>/<repo>`）：
   - 有 README (`gh api repos/<o>/<r>/readme` 200 OK)
   - `contributors_url` 前 5 個以內，或 `size < 5000` 視為小專案

4. **排除已存在**：讀 `repos/` 目錄，若已存在 `<owner>__<repo>.md` 則丟棄。

5. Mini-LLM 判斷「架構深度 + 可重造」：對每個候選讀 README 前 200 行，判斷 yes/no + 一句 reason。

6. 從通過名單挑 1–2 個。若不足 1 個 → 回傳空陣列並在輸出加 `"warning": "no_candidates"`；`daily-digest` 會標註「今日 shortlist 不足」。

7. 輸出（JSON，交給下游）：
   ```json
   [
     {"url": "https://github.com/owner/repo", "name": "owner__repo", "reason": "small RAG framework with novel chunking"}
   ]
   ```

## Rate limit 對策
使用 `gh auth login` 授權過的 token；命中 rate limit → sleep 60s 重試一次；仍失敗回傳 partial 並加 `"warning": "rate_limited"`。
