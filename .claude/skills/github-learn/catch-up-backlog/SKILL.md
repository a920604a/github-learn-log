---
name: github-learn:catch-up-backlog
description: Use when daily/ has gaps between the last daily file and today (routine sandbox failed, on vacation, forgot). Detects missing YYYY-MM-DD dates, then orchestrates scan-trending → analyze-repo × N → update-concepts → daily-digest × N (+ weekly-digest if today is Sunday) to backfill all missing days in one local run. Marks retrofilled days honestly.
---

# catch-up-backlog

## 目的
本地一鍵補齊 `daily/` 缺口。routine sandbox 被 Anthropic 封死後，只能用本地 Claude Code CLI 手動跑。這個 skill 把「找缺口 → 抓 repo → 逐日寫 → 週日補週報 → 一次 commit」串成單一流程，避免手動記日期出錯。

## 何時使用
- `daily/` 最新一份日期 < 今天
- 剛從假期回來 / routine 一直沒動 / 想手動補幾天
- 想一次跑完整條 pipeline 而不是一個一個 skill 手動叫

## 何時不使用
- 只想跑今天 → 直接用 `scan-trending` → `analyze-repo` → `update-concepts` → `daily-digest`
- 想重跑某一天既有的 daily → 手動改該檔，不是這個 skill 的用途

## 誠實性原則
補歷史時**用今天當下的 GitHub trending**，不是那天真正的 trending（Search API 無法乾淨拿歷史 trending 快照）。
→ 每份補的 `daily/YYYY-MM-DD.md` 必須在檔頭 frontmatter 加：

```yaml
---
date: 2026-07-22
ingested_at: 2026-07-26
mode: catch-up
---
```

且在頁面第一段明寫「本日為 YYYY-MM-DD 於 YYYY-MM-DD 補寫，repo 挑選來自補寫當下的 trending」。

## 步驟

### 1. 偵測缺口

```bash
cd /path/to/github-learn-log

LAST_DAILY=$(ls daily/ | grep -E '^\d{4}-\d{2}-\d{2}\.md$' | sort | tail -1 | sed 's/\.md$//')
TODAY=$(date +%Y-%m-%d)

# 產出缺口日期陣列（不含 LAST_DAILY，含 TODAY）
MISSING=()
d=$(date -j -f %Y-%m-%d -v+1d "$LAST_DAILY" +%Y-%m-%d 2>/dev/null || date -d "$LAST_DAILY + 1 day" +%Y-%m-%d)
while [ "$d" \<= "$TODAY" ]; do
  MISSING+=("$d")
  d=$(date -j -f %Y-%m-%d -v+1d "$d" +%Y-%m-%d 2>/dev/null || date -d "$d + 1 day" +%Y-%m-%d)
done

echo "缺口 ${#MISSING[@]} 天：${MISSING[@]}"
```

若 `${#MISSING[@]}` = 0 → 印「無缺口」→ 結束。

### 2. 決定 repo 數

- **補積壓模式**：每天 **1 個** repo（優先趕進度，不追求密度）
- 需要的 shortlist 總數 = `${#MISSING[@]}`
- 若 `${#MISSING[@]}` > 7 → 警告使用者「缺 N 天可能太多，建議只補最近 7 天，早於此的日期以 `daily/YYYY-MM-DD.md` 存留白條說明」

### 3. 抓 shortlist（呼叫 scan-trending）

跑 `scan-trending` skill，但把 shortlist 目標數改為 `${#MISSING[@]}`。若 `scan-trending` 過濾後不足此數 → 放寬 `size` 上限（如 30000 KB）或延伸 topics 允許 `machine-learning` / `tools` 撈到足夠為止。

若最後仍不足 → 有幾個補幾個，剩下日期產出「今日候選不足」空白日報（見 step 5 邊界）。

### 4. 分配 repo 到日期

按 GitHub star 增速排序後，一天一個（最熱的分到最近的日期）。避免同一 repo 出現在多天。

例：MISSING = [07-22, 07-23, 07-24, 07-25, 07-26]，shortlist = [A, B, C, D, E]（E 最熱）
→ 07-22=A, 07-23=B, 07-24=C, 07-25=D, 07-26=E

### 5. 逐日 mini-pipeline

for each `d` in MISSING:

  **5a. analyze-repo**：跑 `analyze-repo` skill 產出 `raw/<name>.md` + `repos/<name>.md`。收集 `concept_tags`。

  **5b. 記錄該日產出**：暫存 `{repo_name, url, one_liner, concept_tags}` 到 accumulator。

  **5c. 寫該日 `daily/<d>.md`**：跑 `daily-digest` skill 的 step 1，**但**：
  - frontmatter 加 `date` / `ingested_at` / `mode: catch-up`
  - 頁首第一段加補寫聲明
  - **不執行 daily-digest 的 step 4/5**（git push + Discord），留到最後統一

  **邊界：若該日無 repo 可分**（step 3 shortlist 不足）→ 仍寫 `daily/<d>.md`，內容：
  ```markdown
  ---
  date: <d>
  ingested_at: <today>
  mode: catch-up-empty
  ---

  # 日報 <d>

  > 本日為 <d> 於 <today> 補寫。當日已無足夠 trending 候選可回溯，本日空白。
  ```

### 6. 一次跑 update-concepts

把 step 5 累積的所有 `(repo_name, concept_tags)` pair 一次餵給 `update-concepts` skill。concepts 頁的 date stamp 用 `<ingested_at>`（今天），註記格式：
```
<!-- +YYYY-MM-DD (catch-up for YYYY-MM-DD) from <repo> -->
```

### 7. 更新 Home.md

跑 `daily-digest` skill 的 step 2 邏輯，但要為每個補寫的日期都 append 一列。順序按日期 ascending。

### 8. 判斷 weekly-digest

```bash
if [ "$(date +%u)" = "7" ]; then
  echo "今天週日 → 跑 weekly-digest"
fi
```

若 yes → 跑 `weekly-digest` skill（它會自己算 week_start / week_end / week_id）。

### 9. 一次 git commit + push

```bash
git add daily/ repos/ raw/ concepts/ Home.md glossary.md weekly/
git commit -m "chore(catch-up): backfill $LAST_DAILY..$TODAY (${#MISSING[@]} days, ${#MISSING[@]} repos)"
git push origin main
```

### 10. Discord push：跳過

本地執行時 `DISCORD_WEBHOOK_URL` 通常不在 env 裡。**catch-up 不推 Discord**——一次推 5 條會轟炸 channel。若真的想推：只推 weekly summary（若 step 8 有跑）。

## 快速參考

| 情境 | 動作 |
|---|---|
| 缺 1 天 | 直接跑，一輪 mini-pipeline |
| 缺 2–7 天 | 正常執行，每天 1 個 repo |
| 缺 > 7 天 | 只補最近 7 天，其餘寫留白條 |
| 缺 0 天 | 印訊息，直接結束 |
| 今天是週日 | step 8 接續跑 weekly-digest |
| shortlist 不足 | 有幾個補幾個，剩餘日期留白條 |

## 常見錯誤

- **忘記標 `mode: catch-up`** → wiki 假裝那天真的分析過，失去追溯性。frontmatter 三欄位（date / ingested_at / mode）都要有。
- **一天塞多個 repo 想補「密度」** → 補積壓的目的是清缺口不是造資料，一天 1 個即可。
- **中途 commit** → 分批 commit 會讓 git log 亂。全部產出後一次 commit + push。
- **重新啟動 routine 期待它自己補** → routine sandbox 是死路（見 CLAUDE.md 註解），本地跑是唯一路徑。

## 輸出
- N 份 `daily/YYYY-MM-DD.md`（含 catch-up frontmatter）
- N 份 `repos/<name>.md` + `raw/<name>.md`
- 更新的 `concepts/*.md`（append，不覆寫）
- 更新的 `Home.md`
- （週日）`weekly/YYYY-Www.md`
- 一個 `chore(catch-up): ...` commit
