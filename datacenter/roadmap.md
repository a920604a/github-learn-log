# Data Center Infra Management — 六個月學習 Roadmap

> 對象：軟體工程師，要在自建自營機房（新建/施工中）建置 infra management 系統
> 時間預算：**每天 1 小時**（六個月約 180 小時）
> 建立日期：2026-07-28

---

## 一、這份 roadmap 的三個前提

**前提一：你的時間有限，所以這不是閱讀清單。**

每天 1 小時，六個月約 180 小時。一門 Uptime 課程就吃掉 16 小時，一本 Cisco Press 認證書要 80 小時。**如果照傳統路徑走，你六個月只能讀完兩三本書，而且讀完還是不會建模。** 所以這份 roadmap 的每個階段都以**產出一份文件**收尾，不是以「讀完某本書」收尾。讀材料是手段，交付物才是進度。

**前提二：你的角色是建模者，不是設施工程師。**

你不需要會選型冰水主機、不需要算短路電流、不需要會調 PID。你需要知道的是**每一類設備在你的資料模型裡長什麼樣**。這是一個有限的、可窮舉的問題（約 35–45 類設備 × 6 個欄位），而不是一個無底洞。

**前提三：你手上有一批比任何教材都好的東西，而且它有保存期限。**

機房在施工中，代表 **commissioning（系統測試調校）會在接下來幾個月內發生**。負載機測試、UPS 切換測試、發電機帶載測試、整廠斷電演練——這些是**一次性、不可重現**的。建築上線後不會有人為了教你再斷一次電。

> **這是整份 roadmap 裡唯一有時效性的東西。** 其他都可以慢慢來，這個過了就沒了。

---

## 二、被我砍掉的東西（以及為什麼）

| 砍掉 | 原因 |
|---|---|
| **Cisco CCNP Data Center** | 它教你設定 Nexus 交換器與 ACI。除非你要做網路自動化，否則對「建 infra management 系統」貢獻趨近於零，卻要吃掉 80–150 小時 |
| **Uptime ATD** | 需要 PE 執照 + 建議 24 個月設計經歷 + US$4,985。你不是要設計機房，是要管理機房資料 |
| **Schneider 完整課程體系 / DCCA** | 內容不錯但密度太低。你需要的是它的**白皮書**（查參考用），不是它的**課程**（線性讀完） |
| **各種證照** | 六個月 130 小時要同時學新領域又要考證照，兩件事都做不好。**證照放到第二年再談** |
| **SRE Workbook 全書** | 只讀 Monitoring 和 Alerting on SLOs 兩章，其餘與你的場景關聯低 |

砍掉的原則是同一條：**這東西能不能讓我把某一類設備的六格填得更好？** 不能就砍。

---

## 三、核心教材（三層）

### 第 1 層：你公司內部的東西（最高價值，優先取得）

這一層沒有替代品。以下按價值排序：

1. **電力單線圖（Single Line Diagram, SLD）** — 從市電進線 → 變壓器 → ATS → 發電機 → 主配電盤 → UPS → PDU → 機櫃的完整拓撲。**一張 SLD 抵三本書**，因為它就是你資料模型的答案卷
2. **Commissioning 測試計畫與報告** — Level 1–5 測試，特別是 Level 4/5 的整合測試與斷電演練。這裡面寫的是「什麼壞了會怎樣」，也就是你的故障域模型
3. **機械系統圖（冰水管路圖 P&ID）** — 冰水主機 → 一次側泵 → 儲冷槽 → 二次側泵 → CRAH 的水路拓撲
4. **點位表（Point List / I/O List）** — BMS 與 EPMS 的每一個監控點：設備、點名、型態、協定、位址。**這是你遙測 pipeline 的規格書**，通常由控制系統承包商產出
5. **設備清冊與規格書（Submittals）** — 每台設備的廠牌型號、額定值、通訊介面

> **第 0 週的唯一任務就是去把 1、2、4 弄到手。** 拿不到就找到能給你的人。這件事的槓桿遠大於讀任何材料。

### 第 2 層：免費公開教材（建立詞彙與框架）

| 教材 | 用途 | 時數 |
|---|---|---|
| [Microsoft Learn — Introduction to Datacenter](https://learn.microsoft.com/en-us/training/paths/introduction-to-datacenter/) | 六個模組、廠商中立，涵蓋 fundamentals、design、power、cooling、network、operations、sustainability。**唯一推薦從頭讀完的線性教材** | ~4.5h |
| [Schneider Electric 白皮書庫](https://it-resource.schneider-electric.com/white-papers) | **查參考用，不要線性讀。** 分類涵蓋 power fundamentals、cooling fundamentals、management best practices。遇到不懂的名詞就來這裡找對應那篇 | 依需求 |
| [Google SRE Workbook — Monitoring](https://sre.google/workbook/monitoring/) | 監控哲學、四大黃金訊號、如何避免告警疲勞 | ~3h |
| [Google SRE Workbook — Alerting on SLOs](https://sre.google/workbook/alerting-on-slos/) | SLO / error budget / burn rate。**注意：設施告警與軟體 SLO 不能直接照搬**，見階段 5 | ~3h |
| [ASHRAE TC 9.9 熱環境指引](https://www.cky.com.tw/en/insights/ashrae-tc9-datacenter-thermal-guidelines) | 環境告警門檻的權威依據 | ~1h |

**ASHRAE 關鍵數字（第 5 版，2021）——直接會變成你的告警門檻：**

- **建議範圍（Recommended，所有 class 通用）：18–27°C**
- 允許範圍（Allowable）：Class A1 為 15–32°C（企業級伺服器）、Class A2 為 10–35°C（量產型伺服器）
- 濕度建議：露點 −9°C 至 15°C，相對濕度上限 60%
- 允許露點上限：A1 為 17°C DP、A2 為 21°C DP

> 建議範圍是設計目標，允許範圍是短期容忍邊界。**你的告警設計應該是：超出建議範圍 = warning，超出允許範圍 = critical。** 這一條就值回 ASHRAE 那一小時。

### 第 3 層：真實的資料模型（軟體工程師的捷徑）

**這一層是為你這種背景的人準備的，傳統 roadmap 不會有。**

| 資源 | 為什麼重要 |
|---|---|
| [NetBox — Power Tracking 文件](https://netboxlabs.com/docs/netbox/features/power-tracking/) | NetBox 是最成熟的開源 DCIM。它的電力模型是：**PowerPanel（配電盤，最上游）→ PowerFeed（獨立迴路，帶 AC/DC、電壓、電流、primary/redundant 型別）→ Rack → Device**。這是一個經過大量真實部署驗證的 schema |
| [NetBox — PowerPanel 模型](https://netboxlabs.com/docs/netbox/models/dcim/powerpanel/) | 逐欄位定義 |
| [NetBox — PowerFeed 模型](https://netboxlabs.com/docs/netbox/models/dcim/powerfeed/) | 注意它怎麼用 `type: primary / redundant` 表達 A/B 雙路——**這一個欄位就解決了冗餘建模** |
| NetBox 原始碼 `netbox/dcim/models/` | 直接讀 Django model 定義。對你來說，讀 200 行 model 比讀 20 頁白皮書快 |

> **重要提醒**：NetBox 的模型**止於 PowerPanel**——它假設上游（UPS、發電機、變壓器、ATS）不歸你管。但你是自建自營，**這一整段你得自己補**。所以正確用法是：拿 NetBox 當下半段的答案，上半段用你們的 SLD 自己建。**兩者接起來就是你的核心模型。**

---

## 四、六個月分階段

### 第 0 週（5 小時）｜把管道打開

**這一週不讀任何東西。**

- [ ] 找到能給你 SLD、點位表、commissioning 計畫的人，正式提出需求
- [ ] 約 facility / 機電負責人一次 60 分鐘的談話（問題清單見第六節）
- [ ] **問到 commissioning 的排程表**，把 Level 4/5 測試的日期記進行事曆
- [ ] 申請一次現場走訪：電力室、UPS 室、冰水主機房、機房主空間

**交付物**：一份「我拿到了什麼 / 還缺什麼 / 誰能給我」的清單。

---

### 階段 1｜第 1–4 週（20 小時）｜全貌與設備總表骨架

**目標**：建立詞彙，不求深度。能聽懂 facility 同事講話。

| 做什麼 | 時數 |
|---|---|
| 讀完 Microsoft Learn — Introduction to Datacenter 六個模組 | 5h |
| 讀 NetBox Power Tracking + PowerPanel/PowerFeed 模型文件 | 3h |
| **建立設備總表骨架**：列出你們機房會有的所有設備類別（先只列名稱與分類，六格空著） | 8h |
| 現場走訪一次，拿實體對照你列的清單，補漏 | 4h |

**交付物**：`equipment-taxonomy.md` — 五大系統分類下的完整設備類別清單（約 35–45 類），每類先有名稱、中英對照、所屬系統、你在現場有沒有親眼看過。

**驗收**：把這份清單拿給 facility 同事看，他能不能指出你漏了什麼。**漏 3 類以內算過關。**

---

### 階段 2｜第 5–12 週（40 小時）｜電力鏈（最重的一段）

**目標**：能獨立畫出從市電到伺服器電源供應器的完整電力路徑，並用資料結構表達它。

| 做什麼 | 時數 |
|---|---|
| 用你們的 SLD 逐段追：市電 → 變壓器 → ATS → 發電機 → 主配電盤 → UPS → PDU → 匯流排/RPP → rack PDU → 插座 → 設備雙電源 | 12h |
| 遇到不懂的設備就去 Schneider 白皮書庫查那一篇 | 8h |
| 把電力鏈上每一類設備的**六格**填滿（拓撲/容量單位/冗餘/遙測/故障域/維護） | 12h |
| 用 NetBox 的模型當底，設計你自己的 schema：**上游段自己建、下游段照抄** | 8h |

**這一階段必須搞懂的概念**（不懂就去問，不要跳過）：

- A/B 雙路（dual feed）如何表達，以及一台**單電源**設備掛在雙路架構下代表什麼風險
- N、N+1、2N、2N+1 在 UPS 與發電機上分別長什麼樣
- 斷路器的 **80% 連續負載規則**——為什麼一條 100A 迴路只能用 80A
- **並機（parallel）UPS 與獨立（isolated）UPS 的差別**，這會改變你的故障域模型
- 靜態切換開關（STS）與自動切換開關（ATS）的差別與各自位置
- **concurrent maintainability**：為什麼「UPS 要保養」這件事會決定整個架構

**交付物**：
1. `power-chain-model.md` — 你自己畫的電力鏈拓撲 + 每類設備六格
2. 一份可執行的 schema 草案（ER 圖或 Django/SQLAlchemy model 皆可）

**驗收**：拿你畫的拓撲圖跟 SLD 對照，請 facility 同事挑錯。**再問他一個問題：「如果 UPS-A 要保養轉 bypass，這段期間哪些機櫃處於單點風險？」你的模型要能回答這個問題。**

---

### ⚡ 浮動優先事項｜Commissioning 期間（不限階段）

**只要 commissioning 開始，立刻中斷當前階段，全部時間投進去。**

要參加/要到的東西：

- [ ] **整廠斷電測試（black building test）** — 親眼看發電機起動、ATS 切換、UPS 撐過空窗期。**這是你這輩子最好的一堂課**
- [ ] 負載機（load bank）測試報告 — 裡面有真實的容量數字，不是銘牌值
- [ ] UPS 切換與 bypass 測試報告
- [ ] 冷卻系統故障模擬 — 掉一台 CRAH / 一台冰水主機，看溫度多久爬到警戒
- [ ] **各系統的 alarm 清單與觸發門檻** — 這是承包商設定的，你的系統要沿用或改寫，必須知道原始設定值

**交付物**：`commissioning-notes.md` — 每個測試的「做了什麼 / 觀察到什麼 / 對我的模型有什麼啟示」。

---

### 階段 3｜第 13–17 週（25 小時）｜冷卻鏈與環境

| 做什麼 | 時數 |
|---|---|
| 用機械系統圖追冷卻鏈：冷卻水塔 → 冰水主機 → 一次側泵 → 儲冷槽 → 二次側泵 → CRAH → 冷通道 → 熱通道 → 回風 | 8h |
| 讀 ASHRAE TC 9.9 熱環境指引，記住四個關鍵數字 | 2h |
| 冷卻鏈設備六格填滿 | 8h |
| 若有高密度/AI 機櫃：補液冷（直接液冷 DLC、後門熱交換器 RDHx）的基本拓撲 | 4h |
| 冷卻的容量與故障模型：為什麼冷卻的故障域比電力**慢但更難救** | 3h |

**必須搞懂**：

- CRAC（自帶壓縮機，直膨式）與 CRAH（用冰水，無壓縮機）的差別——**你們是自建，大機率是 CRAH**
- 冷熱通道封閉（containment）如何改變你的溫度感測器佈點策略
- delta-T 與旁通氣流（bypass airflow）——為什麼「機房很冷」反而可能是設計失敗
- 冷卻系統的 **ride-through 問題**：斷電時 UPS 撐得住 IT 負載，但冰水主機起動需要時間，這段空窗期靠什麼

**交付物**：`cooling-chain-model.md` + 溫濕度告警門檻設計（引用 ASHRAE 數字）。

---

### 階段 4｜第 18–22 週（25 小時）｜容量語意與遙測

**這一階段是「三者都要」的匯流點。**

| 做什麼 | 時數 |
|---|---|
| **容量語意**：銘牌值 vs 降載值 vs 實測值三者的差別與換算 | 6h |
| 擱置容量（stranded capacity）的四種型態：有電沒空間 / 有空間沒電 / 有電有空間沒冷氣 / 有一切但冗餘不夠 | 4h |
| **點位表逐行讀** — 這是遙測 pipeline 的規格書 | 8h |
| 協定基礎：Modbus（電力/機電，暫存器位址）、BACnet（樓宇/空調，物件模型）、SNMP（IT 設備與 UPS 網卡）、Redfish（伺服器帶外管理） | 7h |

**必須搞懂**：

- **BMS 與 EPMS 通常是兩套獨立系統**，資料格式不通、時間戳不同步。你的 pipeline 第一個難題就是這個
- 為什麼設施遙測的取樣率是分鐘級而不是秒級，以及這對異常偵測的影響
- 銘牌值永遠比實測值高很多——**用銘牌值做容量規劃會嚴重浪費，用實測值做會有風險**，實務怎麼取捨

**交付物**：`capacity-and-telemetry.md` — 容量計算規則 + 遙測來源對照表（設備類別 × 協定 × 關鍵點位 × 取樣率）。

---

### 階段 5｜第 23–26 週（20 小時）｜維運流程與模型定稿

| 做什麼 | 時數 |
|---|---|
| 讀 SRE Workbook 的 Monitoring 與 Alerting on SLOs 兩章 | 6h |
| 訪談維運同事：一天/一週/一個月的實際工作流 | 4h |
| 搞懂 MOP / SOP / EOP、變更窗口、工單、巡檢、事件分級 | 4h |
| **整份資料模型定稿 + 寫成 ADR（架構決策記錄）** | 6h |

**這一階段最重要的一個認知**：

> **設施的告警不能照搬軟體的 SLO 思維。** 軟體世界可以用 error budget「允許一定比例的失敗」；但發電機起動失敗沒有 budget，它是二元的。SRE Workbook 的價值在**告警哲學**（避免疲勞、可行動性、症狀優先於原因），不在把 error budget 直接套到設施上。**這個界線分不清楚，你的告警系統會做壞。**

**交付物**：`data-model-v1.md` + 一份 ADR 說明每個關鍵建模決策的取捨。

**最終驗收**：你的模型能否回答這五個問題——

1. 這台伺服器的電力從哪來？經過哪些設備？
2. 若 UPS-A 保養轉 bypass，哪些設備進入單點風險？
3. 這個機櫃還能再上幾台伺服器？限制是電力、空間、還是冷卻？
4. 若某台 CRAH 掉了，哪些機櫃會先熱起來？
5. 這個月哪些設備到了保養期，保養時需要停哪些東西？

**五題都答得出來，你就具備建置 infra management 系統的領域知識了。**

---

## 五、設備總表的六格規格

每一類設備都填這六格。這不是背誦卡，**是你資料表的欄位規格**。

| 欄位 | 填什麼 |
|---|---|
| **拓撲位置** | 上游接誰、下游接誰 |
| **容量單位** | kW / kVA / A / RT / CFM / U / kg，以及銘牌與實測的關係 |
| **冗餘表達** | N、N+1、2N 在這類設備上具體長什麼樣 |
| **遙測介面** | 協定（Modbus/BACnet/SNMP/Redfish）+ 關鍵點位清單 |
| **故障域** | 它掉了誰跟著死、多久內有影響 |
| **維護特性** | 週期、是否需停機、停機時的替代路徑 |

**已完成範例（見對話）**：UPS、CRAH

**待填清單（五大系統）**：

- **電力鏈**：市電進線、變壓器、中壓開關設備、ATS、發電機、日用油箱/儲油槽、主配電盤、UPS、電池組（鉛酸/鋰電）、STS、PDU、RPP、匯流排（busway）、rack PDU、電力監測儀表
- **冷卻鏈**：冷卻水塔、冰水主機、一次側泵、二次側泵、儲冷槽、板式熱交換器、CRAH/CRAC、精密空調、加濕/除濕、冷熱通道封閉、液冷 CDU、後門熱交換器
- **空間與機櫃**：建築/樓層/機房區、機櫃、機櫃 U 位、盲板、線槽/走線架、配線架、地板/天花板
- **消防與門禁**：極早期偵煙（VESDA）、氣體滅火、消防警報盤、門禁控制器、讀卡機、CCTV、人員通道閘
- **監控與網路**：BMS、EPMS、DCIM、溫濕度感測器、漏水偵測、閘道器/協定轉換器、網管交換器

---

## 六、該問 facility 團隊什麼

**每次談話前挑 3–5 題，不要一次全問。**

**關於架構**
1. 我們是 Tier 幾？設計時做了哪些取捨？
2. 電力是 2N 還是 N+1？UPS 是並機還是獨立？
3. 哪些設備是單點故障（SPOF）？你們自己最擔心哪一個？

**關於維運**
4. 保養時哪些設備需要停機？停機期間的替代路徑是什麼？
5. 你們現在怎麼記錄機櫃容量？Excel 嗎？痛點在哪？
6. 上一次真的出事是什麼狀況？怎麼發現的？

**關於資料（對你的系統最關鍵）**
7. BMS 跟 EPMS 是同一套嗎？資料能不能對得起來？
8. 現在的告警一天大概幾則？多少是雜訊？
9. 如果一個系統能自動回答一個你現在得花半天手動查的問題，那會是什麼問題？

> **第 9 題是整份清單裡最重要的一題。** 它會直接告訴你這套系統的第一個功能該做什麼。

---

## 七、第二年再談的事

以下不是不重要，是**現在做會拖垮前六個月**：

- **證照**：領域知識扎實之後，EPI CDCP（自修版約 US$895，含考券，40 題 1 小時）是投報比最高的第一張
- **Uptime Tier Standard 原文**：等你能看懂 SLD 之後再讀才有意義
- **EN 50600 / ISO 22237**：導入正式流程管理時再查
- **AI / 異常偵測 / 容量預測**：**先有乾淨的資料模型與穩定的遙測，這些才有意義。** 反過來做必然失敗

---

## 參考資料

- [Microsoft Learn — Introduction to Datacenter](https://learn.microsoft.com/en-us/training/paths/introduction-to-datacenter/)
- [Microsoft Learn — Datacenter design, architecture, and infrastructure management](https://learn.microsoft.com/en-us/training/modules/learn-about-datacenter-design/)
- [NetBox Documentation — Power Tracking](https://netboxlabs.com/docs/netbox/features/power-tracking/)
- [NetBox Documentation — PowerPanel](https://netboxlabs.com/docs/netbox/models/dcim/powerpanel/)
- [NetBox Documentation — PowerFeed](https://netboxlabs.com/docs/netbox/models/dcim/powerfeed/)
- [Schneider Electric — Data Center White Papers](https://it-resource.schneider-electric.com/white-papers)
- [Google SRE Workbook — Monitoring](https://sre.google/workbook/monitoring/)
- [Google SRE Workbook — Alerting on SLOs](https://sre.google/workbook/alerting-on-slos/)
- [ASHRAE TC 9.9 Thermal Guidelines 第 5 版摘要](https://www.cky.com.tw/en/insights/ashrae-tc9-datacenter-thermal-guidelines)
- [EPI — Certified Data Center Professional (CDCP) On-Demand](https://www.epi-usainc.com/training-on-demand/certified-data-center-professional-cdcp/)
