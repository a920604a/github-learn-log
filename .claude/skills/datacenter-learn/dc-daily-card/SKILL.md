---
name: datacenter-learn:dc-daily-card
description: Produce one data-center equipment or topic card per weekday, driven by datacenter/backlog.md (syllabus-driven, NOT crawl-driven). Fills the six-field spec (topology / capacity unit / redundancy / telemetry / failure domain / maintenance) from authoritative sources, writes datacenter/devices|topics/<slug>.md, updates backlog + index, commits locally.
---

# dc-daily-card

## 目的
每個工作日產出**一張**資料中心設備卡或主題卡。這條軌跡是**教材驅動**：`datacenter/backlog.md` 的佇列決定今天寫什麼，**不是**當天爬到什麼決定寫什麼。

## 執行環境的硬限制（先讀，違反會整條掛掉）

沙箱的 `curl` **只有 `github.com` 通得了**。以下網域用 curl 全部回 `000`：

- `learn.microsoft.com`
- `netboxlabs.com` / `netbox.readthedocs.io`
- `sre.google`
- `schneider-electric.com` / `se.com`
- `uptimeinstitute.com`
- `raw.githubusercontent.com`

**取材一律用 `web_fetch` 和 `WebSearch` 工具，不要用 curl / wget / python requests。** 這兩個工具走不同的通道，實測對上述網域全部正常。

## 步驟

### 1. 取佇列項目

讀 `datacenter/backlog.md`，找**最上面未完成**（`[ ]`）的一項。

若使用者在 `backlog.md` 裡把某項標了 `⬆ 優先`，改取那一項（通常是因為他公司下週要看那個設備）。

若全部完成 → 寫訊息說佇列已清空、建議下一步，結束。

### 2. 取材

依項目類型決定來源優先序：

| 項目類型 | 來源優先序 |
|---|---|
| 電力／冷卻設備 | Schneider 白皮書庫 → 廠商技術文件（Vertiv / Eaton / APC / 台達）→ 維基百科補術語 |
| 有 NetBox 對應模型的（rack / PDU / power feed / device） | **NetBox 模型文件優先**（逐欄位定義最有價值）→ 再補實體知識 |
| 協定（Modbus / BACnet / SNMP / Redfish） | 官方規格或 DMTF/ASHRAE 文件 → 實作函式庫文件 |
| 環境門檻 | ASHRAE TC 9.9（第 5 版，2021） |
| 監控／告警哲學 | Google SRE Workbook |
| 流程（MOP/SOP、工單、事件） | Uptime / EN 50600 / ISO 22237 摘要 |

**至少查 2 個獨立來源**。查到的事實若兩邊衝突 → 卡片裡明寫「來源分歧」並列出兩種說法，不要自己挑一個裝作確定。

### 3. 寫卡片

路徑：`datacenter/devices/<slug>.md` 或 `datacenter/topics/<slug>.md`
Slug：kebab-case 英文（例：`ups-double-conversion`、`nameplate-vs-measured`）

**Frontmatter：**
```yaml
---
id: dc-08
title: UPS 不斷電系統（雙轉換式）
category: power        # power | cooling | space | fire-security | systems | topic
written_at: 2026-07-29
sources: [url1, url2]
related: [dc-09, dc-11]
---
```

**設備卡必含結構（順序固定）：**

```markdown
# <中文名>（<English name>）

<一段 60–100 字：這台東西在機房裡是幹嘛的，用白話講>

## 六格

### 拓撲位置
上游：… 下游：…

### 容量單位
…（含銘牌值與實測值的關係）

### 冗餘表達
N / N+1 / 2N 在這類設備上各長什麼樣

### 遙測介面
協定 + 關鍵點位表（用表格）

### 故障域
它掉了誰跟著死、多久內有影響

### 維護特性
週期、是否需停機、停機時的替代路徑

## 關鍵數字與計算
（**新增，不可省**）這類設備身上的公式、經驗值、換算關係。
至少一個**帶數字的實例演算**——不要只寫公式，要代數字算一遍。
數字有地區差異（例：電壓等級、法規）時明確標註，不要把美規數字當通用。

## 常見誤解
（**新增，不可省**）3 條，格式一律 `**以為 X，但實際上 Y**`。
挑「軟體工程師第一次接觸這個設備最容易搞錯」的點，不是隨便挑技術細節。

## 對資料模型的意涵
（2–4 條。**這是整張卡存在的理由** —— 這些事實會變成 schema 的哪些欄位、哪些約束、哪些告警規則）

## 該問 facility 的問題
（1–3 題，具體到能直接問出口）

## 動手練習
（**不可省**）一項 30–40 分鐘可完成的實作，把今天讀的變成做過的。
使用者每天有 1 小時：卡片讀 10–15 分鐘，其餘時間全給這一段。

依卡片類型選練習型態：

| 卡片類型 | 練習型態 |
|---|---|
| 電力／冷卻設備 | 在 [demo.netbox.dev](https://demo.netbox.dev) 建出對應物件並接上關係；或用 mermaid 畫出這段拓撲；或寫出這個設備的 SQLAlchemy/Django model |
| 協定（Modbus/BACnet/SNMP/Redfish） | 用 Python 起一個模擬 server + client 讀點位（`pymodbus`、`pysnmp` 等），跑得起來就好 |
| 容量／計算類主題 | 用假設數字建一張試算表或寫個函式，把該章的公式實作出來並驗證邊界 |
| 流程類主題 | 把流程畫成狀態機，並列出每個狀態轉換需要記錄哪些欄位 |

**練習必須有可驗收的產出**（一段可執行的 code、一張圖、一個 NetBox 物件截圖）。
不要寫「花 30 分鐘思考 X」這種無法驗收的練習。

## 自我檢核
（**新增，不可省**）3 題，答案用 MkDocs 摺疊區塊藏起來：

\`\`\`markdown
**Q1. …？**

??? note "答案"
    …
\`\`\`

其中**至少 1 題要問「這件事會讓你的資料模型長出什麼欄位」**，不能三題都是名詞解釋。
```

**主題卡**（`topics/`）不套六格，改用：`定義 / 為什麼重要 / 常見誤解 / 對資料模型的意涵 / 該問的問題`。

**字數：`wc -m` 落在 3000–4500。**

`wc -m` 會把 frontmatter、markdown 標記、英文與程式碼區塊全部算進去，所以這個數字比「中文正文字數」大不少。**參考基準是 `datacenter/devices/utility-feed.md`（dc-01），實測 3973 —— 那就是目標密度，寫新卡時比照它。**

使用者明確表示**寧願多花時間也要把概念學透**，不要為省字數犧牲深度。但超過 4500 通常代表這張卡塞了兩個主題 → **拆成兩張分兩天寫**，並在 `backlog.md` 就地插入新項目。

不可省的段落（字數不夠時砍六格，不要砍這五段）：**關鍵數字與計算 / 常見誤解 / 對資料模型的意涵 / 動手練習 / 自我檢核**。這五段是知識能不能留下來的關鍵。

### 4. 連結規則

跟本 repo 另一條軌跡相同：**禁用 `[[wikilink]]`**（MkDocs 沒裝 plugin）。

- 已存在的卡片 → `[名稱](../devices/slug.md)`
- 尚未寫的卡片 → inline code 標 slug，不要連
- 引用 roadmap → `[roadmap](../roadmap.md)`

### 5. 更新佇列與索引

- `datacenter/backlog.md`：把該項 `[ ]` 改 `[x]`，後面加 ` — 2026-07-29 [卡片](devices/slug.md)`
- `datacenter/backlog.md` 底部「進度」區塊的已完成數 +1
- `datacenter/index.md` 的進度表：已完成數、下一張

### 6. 驗證與 commit

```bash
pip install -q mkdocs mkdocs-material mkdocs-awesome-pages-plugin --break-system-packages
mkdocs build --strict -d /tmp/sitebuild
grep -r '\[\[' /tmp/sitebuild --include='*.html' && echo "殘留 wikilink，修掉"
```

commit message（英文）：`feat(dc): card <id> <slug>`

**不要 push。** 沙箱沒有 SSH key，使用者 Mac 上的 launchd job 於每日 08:10 自動 push。

## 常見錯誤

- **用 curl 抓 learn.microsoft.com / sre.google** → 回 000，整條掛掉。用 `web_fetch`
- **寫超過 500 字** → 使用者讀不完，累積成債。寧可拆成兩張卡分兩天
- **跳過「對資料模型的意涵」** → 那是這張卡存在的唯一理由，其他段落都是為它服務的
- **不照佇列順序、挑自己好寫的寫** → 電力鏈要按實際電流方向走才建得起拓撲直覺
- **兩個來源衝突時自己挑一個** → 明寫分歧，這是給使用者去問 facility 的線索

## 輸出
- 1 份 `datacenter/devices/<slug>.md` 或 `datacenter/topics/<slug>.md`
- 更新的 `datacenter/backlog.md` + `datacenter/index.md`
- 一個 `feat(dc): ...` commit（未 push）
