---
name: datacenter-learn:dc-weekly-review
description: Sunday review for the datacenter track. Aggregates the week's cards, adds a self-test with answers hidden, schedules spaced repetition of older cards, and flags what to ask the facility team. Runs after dc-daily-card has produced the week's cards.
---

# dc-weekly-review

## 目的
每週日產出一份複習頁。**這條軌跡的重點不是累積卡片，是讓卡片被記住。** 每天讀一張卡而不複習，六個月後等於沒讀。

## 何時執行
每週日。當週若一張卡都沒產出 → 仍寫一份，內容是「本週停擺」+ 原因 + 建議，不要跳過（斷鏈紀錄本身有價值）。

## 步驟

### 1. 收集當週卡片

```bash
WEEK_START=$(date -d 'last monday' +%Y-%m-%d 2>/dev/null || date -v-mon +%Y-%m-%d)
WEEK_ID=$(date +%Y-W%V)
```

從 `datacenter/devices/` 與 `datacenter/topics/` 找 frontmatter `written_at` 落在本週的卡片。

### 2. 寫 `datacenter/weekly/YYYY-Www.md`

```yaml
---
week: 2026-W31
week_start: 2026-07-27
week_end: 2026-08-02
cards: 5
---
```

**必含五個區塊：**

#### 本週卡片
每張一行：連結 + 一句「這張卡最關鍵的一個事實」。

#### 串起來
**這一段是週報存在的理由。** 把當週 5 張卡接成一條敘事——它們在同一條電力鏈／冷卻鏈上是什麼關係、誰在誰上游、掉一個會連鎖影響到哪。單張卡是點，這段是線。

#### 自我測驗
出 **5 題**，難度分佈：2 題事實回憶、2 題應用、1 題建模判斷。

格式用 MkDocs 的摺疊區塊把答案藏起來（`pymdownx.details` 已啟用）：

```markdown
**Q1. 一條 100A 的迴路，實際可以持續拉多少電流？為什麼？**

??? note "答案"
    80A。斷路器的 80% 連續負載規則——連續負載（3 小時以上）不得超過額定值的 80%，避免熱累積跳脫。
    **對你的模型**：`PowerFeed` 需要 `max_utilization` 欄位，預設 80%。
```

出題原則：**至少 2 題要能連到「你的資料模型該怎麼設計」**，不要全是名詞解釋。

#### 間隔複習
從**兩週前**與**四週前**的卡片各抽 1 張，各出 1 題。這是刻意的間隔重複，不要跳過。
若還沒有那麼早的卡片，就寫「尚無」。

#### 本週該問 facility 的問題
把當週各卡「該問 facility 的問題」段落彙整、去重、排優先序，選出 **3 題**。

> 這 3 題是給使用者**下週真的拿去問人**的。標註建議問誰（機電 / 維運 / 控制系統承包商）。

### 3. 更新索引

`datacenter/index.md` 的進度表：已完成數、目前輪次、下一張。

### 4. 驗證與 commit

```bash
mkdocs build --strict -d /tmp/sitebuild
```

commit message：`docs(dc): weekly review YYYY-Www`

**不要 push。**

## 常見錯誤

- **只列卡片不寫「串起來」** → 那就只是目錄，不是複習
- **測驗題全是名詞解釋** → 記得住定義不代表會建模。至少 2 題要問設計判斷
- **跳過間隔複習** → 這是整份週報中對長期記憶貢獻最大的一段，也是最容易被省略的
- **問題清單寫得太抽象**（例：「問問 UPS 的狀況」）→ 要具體到能直接開口問

## 輸出
- 1 份 `datacenter/weekly/YYYY-Www.md`
- 更新的 `datacenter/index.md`
- 一個 `docs(dc): weekly review ...` commit（未 push）
