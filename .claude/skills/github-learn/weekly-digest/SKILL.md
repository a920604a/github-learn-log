---
name: github-learn:weekly-digest
description: On Sunday, aggregate week's daily/*.md into weekly/YYYY-Www.md — cards + cross-repo comparison table (only for concept tags hit by >=2 repos), one-liner theme, Discord weekly payload.
---

# weekly-digest

## 目的
週日 daily 執行完之後接續跑。把本週所有 daily 檔整合成一份週報。

## 觸發條件
```bash
[ "$(date +%u)" = "7" ]
```
routine 主 prompt 判斷。若非週日 → 不執行。

## 輸入
- `week_id`: `YYYY-Www`（ISO week）：
  ```bash
  date +%G-W%V
  ```
- `week_start`: `YYYY-MM-DD`（週一）
  ```bash
  date -v-mon -v+0d +%Y-%m-%d 2>/dev/null || date -d 'last monday' +%Y-%m-%d
  ```
- `week_end`: `YYYY-MM-DD`（週日；今天）：
  ```bash
  date +%Y-%m-%d
  ```

## 步驟

### 1. 讀本週 daily 檔

```bash
for d in daily/*.md; do
  date_str=$(basename $d .md)
  if [[ "$date_str" > "${week_start_prev}" && "$date_str" < "${week_end_next}" ]]; then
    echo $d
  fi
done
```
（或用 python one-liner）

從每份 daily 抽 repos（parse heading `### [owner/repo]`）。

### 2. 讀本週被更新的 concept

```bash
grep -l "<!-- +${week_start}" concepts/*.md 2>/dev/null
# 或掃 date range
```

### 3. 寫 `weekly/<week_id>.md`

```markdown
# 週報 <week_id> (<week_start> ~ <week_end>)

> 本週 <N> 個 repo。

## 本週主軸
<LLM 依 N 個 repo 的共通性寫一句話，例：「本週 3 個 RAG framework，chunking 策略取捨不同」>

## Repos 總覽

### [owner/repo1](../repos/owner__repo1.md)
（每個 repo 一張卡片，複製 daily 卡片格式，末尾 link 到當日 daily：`— from [YYYY-MM-DD](../daily/YYYY-MM-DD.md)`）

## 橫向比較

<對每個「本週 >=2 個 repo 觸及」的 concept 產一個表>

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

### 4. 更新 `Home.md`

找到「### 週報」段，最上方 append：
```
- [YYYY-Www](weekly/YYYY-Www.md) — <N> repo
```

### 5. 構造 Discord weekly payload

```
標題：📚 github-learn 週報 <week_id>

<一句話主軸>

Top 3 亮點：
1. owner/repo — 一句話
   🔗 https://github.com/a920604a/github-learn-log/blob/main/repos/owner__repo.md
2. ...
3. ...

本週新增/更新 concept：slug-a, slug-c

完整週報 🔗 https://github.com/a920604a/github-learn-log/blob/main/weekly/<week_id>.md
```

Top 3 挑選：LLM 依「個人學習價值」排序，不是 star 數。

### 6. git commit + push

```bash
git add weekly/<week_id>.md Home.md
git commit -m "chore(weekly): <week_id> — <N> repos"
git push origin main
```

### 7. Discord push（同 daily-digest step 5）

## 輸出
- `weekly/<week_id>.md`
- 更新的 `Home.md`
- push 成功的 commit
- （可選）Discord weekly message
