---
name: github-learn:update-concepts
description: Given today's (repo, concept_tags) batch, upsert concepts/*.md — create new page only if >=2 repos touched; append (never overwrite) with date stamp; return created/updated slug list.
---

# update-concepts

## 目的
維護跨 repo 累加的 concept 頁。同一 concept 頁上，多次分析 append 對比與取捨，**不覆寫**。

## 輸入
```json
[
  {"repo_name": "owner__repo", "concept_tags": ["rag-chunking-strategies", "async-task-queue"]}
]
```

## 步驟

1. 建立本次 batch 的 (repo_name, slug) pairs。

2. 對每個 slug：

   **情況 A：`concepts/<slug>.md` 已存在**
   - append 一段新 section 到「各 repo 做法對比」段末（模板見下方）
   - append 一項到「來源 repos」清單
   - 記到 `updated`

   **情況 B：`concepts/<slug>.md` 不存在**
   - 全歷史掃描：跨所有 `repos/*.md` 的 YAML frontmatter `concept_tags`，計算「觸及此 slug 的 repo 數（含本次 batch）」
     ```bash
     grep -l "concept_tags:.*${slug}" repos/*.md 2>/dev/null | wc -l
     ```
     或用更嚴謹的 YAML parse。
   - 若總數 ≥ 2 → **建立新頁**（用「新 concept 頁模板」），記到 `created`
   - 若總數 = 1 → **不建立**，僅記錄為 pending（下次觸及同 slug 時再開頁）

3. 回傳：
   ```json
   {"created": ["slug-a"], "updated": ["slug-c"], "pending": ["slug-b"]}
   ```
   交給 `daily-digest`。

## 新 concept 頁模板

`concepts/<slug>.md`:
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

在「## 各 repo 做法對比」段末尾 append：
```markdown

<!-- +YYYY-MM-DD from owner__repo -->
### owner/repo 的做法
- 核心取捨：...
- 資料模型：...
- 適用場景：...
```

在「## 來源 repos」清單 append：
```
- [owner/repo](../repos/owner__repo.md) — YYYY-MM-DD
```

## 輸出
- 新增/更新的 `concepts/*.md`
- Return value：`{"created": [...], "updated": [...], "pending": [...]}` 供 `daily-digest` 顯示
