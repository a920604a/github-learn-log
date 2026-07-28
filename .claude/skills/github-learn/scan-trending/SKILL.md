---
name: github-learn:scan-trending
description: Scan GitHub for ingest candidates per CLAUDE.md. Enforces the "small enough to rebuild in a weekend" bar with a star ceiling and file-count check, rotates topic buckets so database / distributed-systems / data-engineering also get covered, and falls back to HTML scraping when api.github.com is unreachable. Outputs 1-2 shortlisted repos with reasons.
---

# scan-trending

## 目的
每日 ingest 的第一步。依 `CLAUDE.md` 的「Ingest 觸發條件」挑 1–2 個「有架構深度 + 小到可週末重造」的 repo。

## v2 修正了什麼（2026-07-28）

v1 的查詢是 `created:>30天 stars:>200 sort=stars`，有兩個結構性偏差：

1. **只撈得到剛發射的病毒式專案**。前 7 篇有 5 篇星數在 26k–97k——那不是週末重造的對象，跟 CLAUDE.md 寫的「小到可重造」直接矛盾。→ v2 加 **star 上限** 和 **檔案數門檻**。
2. **`created:>30天` 結構性排除成熟基礎建設**。database / distributed-systems / data-engineering 這些 topic 不可能 30 天內冒出新專案，所以白名單裡有它們但一個都沒進來過。→ v2 拿掉 created 限制、改用 `pushed` 判活躍，並加 **topic bucket 輪替**。

## 硬門檻（全部要過）

| 條件 | 值 | 為什麼 |
|---|---|---|
| `stars` 下限 | ≥ 200 | 濾掉沒人驗證過的玩具 |
| `stars` **上限** | ≤ 15000 | **v2 新增**。超過這個量級的專案通常已經是產品/組織在維護，讀它學到的是「怎麼做大」不是「怎麼設計」；也不可能週末重造 |
| `size` | < 20000 KB | 專案體積上限 |
| **tree 檔案數** | ≤ 300 | **v2 新增**。用 `git/trees?recursive=1` 數（排除 `node_modules/`、`vendor/`、`dist/`、測試 fixture）。> 300 表示不是單人週末能吃下的範圍 |
| `pushed` | 近 90 天內 | 活躍即可，**不限 created**，讓成熟專案進得來 |
| `language` | Python / TypeScript / JavaScript / Go / Rust | |
| 已在 `repos/` | 排除 | |

> **例外閥**：若某 repo 星數超過上限但架構是明確可切片重造的（例：一個 50k 星專案裡的 200 行 scheduler 設計），可以破例，但**必須在 `repos/<name>.md` frontmatter 加 `star_cap_override: <理由>`**，讓破例是有紀錄的決定而不是習慣。

## Topic bucket 輪替

四個 bucket，用 `date +%j` 對 4 取餘數決定當天的 primary bucket；primary 撈不滿才往其他 bucket 補。

| bucket | index | topics |
|---|---|---|
| A. LLM / Agent | 0 | `llm`, `agent`, `agents`, `rag`, `mcp` |
| B. 資料儲存 | 1 | `database`, `vector-database`, `storage-engine`, `sql` |
| C. 分散式 / 後端 | 2 | `distributed-systems`, `backend-framework`, `orchestration`, `message-queue` |
| D. 資料工程 / MLOps | 3 | `data-engineering`, `mlops`, `etl`, `data-pipeline` |

```bash
BUCKET=$(( $(date +%j) % 4 ))
```

目的：**一週內四類至少各被掃到一次**。沒有這條輪替，sort-by-stars 會讓 AI/agent 類永遠洗版——這正是 W30 七篇全是 AI 工具的原因。

## 兩條資料路徑

`api.github.com` 在部分執行環境（Cowork / CCR sandbox proxy）**被擋**，但 `github.com` 的 HTML 是通的。先試 API，失敗才 fallback。

### 路徑 A：GitHub API（本地 Claude Code CLI 走這條）

```bash
PUSHED_SINCE=$(date -u -v-90d +%Y-%m-%d 2>/dev/null || date -u -d '90 days ago' +%Y-%m-%d)
TOPICS="topic:llm topic:agent topic:rag"   # 依當天 bucket 代入

gh api -X GET search/repositories \
  -f q="pushed:>${PUSHED_SINCE} stars:200..15000 ${TOPICS}" \
  -f sort=updated -f order=desc -f per_page=50 \
  --jq '.items[] | {full_name, html_url, description, language, stargazers_count, topics, size, created_at, pushed_at}'
```

先探測可用性：

```bash
if curl -s -o /dev/null -m 10 -w '%{http_code}' https://api.github.com/rate_limit | grep -qE '^(200|401|403)$'; then
  echo "API 可用 → 路徑 A"
else
  echo "API 被擋 → 路徑 B"
fi
```

### 路徑 B：HTML 抓取（sandbox / 無 gh CLI 時）

```bash
curl -s --max-time 25 "https://github.com/trending?since=daily" -o /tmp/tr.html
```

```python
import re
s = open('/tmp/tr.html', encoding='utf-8').read()
names = re.findall(r'<h2 class="h3 lh-condensed">\s*<a[^>]*?href="/([^"]+)"', s)
langs = re.findall(r'itemprop="programmingLanguage">([^<]+)<', s)
# names[i] 與 langs[i] 對齊；trending 每頁約 25 筆
```

topic / star / size 再逐一補：`curl -s https://github.com/<owner>/<repo>` 然後抓
`id="repo-stars-counter-star" ... title="12,345"`。

亦可用 search 頁（同樣走 HTML）：
`https://github.com/search?q=stars%3A200..15000+topic%3Adatabase&type=repositories`

> **記錄用了哪條路徑**：raw 檔的 `Fetched:` 那行後面加 `via API` 或 `via HTML`。這跟 wiki 自己在講的 EXTRACTED / INFERRED 是同一件事——資料來源要可稽查。

## 步驟

1. 決定當天 bucket（`date +%j % 4`）。
2. 探測 API 可用性，選路徑 A 或 B。
3. 依硬門檻表過濾（star band / size / language / pushed）。
4. **排除已存在**：讀 `repos/` 目錄，若已存在 `<owner>__<repo>.md` 則丟棄。
5. **檔案數檢查**：對剩下的候選拉 tree，排除 `node_modules|vendor|dist|build|.git|test.*fixtures` 後計數，> 300 丟棄。
6. 讀 README 前 200 行，判斷「架構深度 + 可重造」yes/no + 一句 reason。判 yes 的標準是**「這個 repo 有沒有一個我講得出來的設計決策」**，不是「這個 repo 紅不紅」。
7. 挑 1–2 個。primary bucket 不足 → 依序往 bucket+1、+2、+3 補。四個 bucket 都撈不到 → 回傳空陣列 + `"warning": "no_candidates"`；`daily-digest` 會標註「今日 shortlist 不足」。
8. 輸出 JSON：

```json
[
  {
    "url": "https://github.com/owner/repo",
    "name": "owner__repo",
    "bucket": "B",
    "stars": 1840,
    "file_count": 87,
    "source_path": "API",
    "reason": "single-file WAL implementation, 資料結構決策講得清楚"
  }
]
```

## Rate limit 對策
路徑 A：命中 rate limit → sleep 60s 重試一次；仍失敗 → 直接切路徑 B（HTML 無 rate limit 但要節制，每次跑 ≤ 30 個 repo 頁請求）。

## 常見錯誤

- **回頭用 sort=stars 撈熱門榜** → 會退回 v1 的偏差。想看熱門用 trending 頁當**候選來源**沒問題，但硬門檻（star 上限 / 檔案數）一定要照跑。
- **bucket 輪替被跳過** → 「今天 AI 類候選比較好」是每天都會成立的藉口，跳一次就會一直跳。primary bucket 撈得到就用 primary。
- **破例不記錄** → star 上限的破例要寫進 frontmatter，否則三個月後你不知道當初為什麼收它。
