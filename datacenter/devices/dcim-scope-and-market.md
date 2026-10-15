---
id: dc-40
title: DCIM 的範疇與市場現況（資產資料庫、容量帳本，以及「對帳」這個動作）
category: systems
written_at: 2026-10-15
sources:
  - https://www.techtarget.com/searchdatacenter/definition/data-center-infrastructure-management-DCIM
  - https://www.vertiv.com/en-emea/about/news-and-insights/articles/educational-articles/what-is-data-center-infrastructure-management-dcim/
  - https://www.datacenterfrontier.com/voices-of-the-industry/article/11427160/benefits-of-integrating-bms-and-epms
  - https://www.businesswire.com/news/home/20250718223502/en
  - https://www.imarcgroup.com/data-center-infrastructure-management-market
  - https://www.datacenterdynamics.com/en/opinions/why-dcim-didnt-fail/
  - https://intelligence.uptimeinstitute.com/resource/recap-roundtable-making-dcim-work-you
  - https://www.datacentres.com/news/dcim-buyer-s-guide-2026-why-60-of-deployments-still-end-up-as-shelfware-in-a-3-1-slot3-2026-08-31
related: [dc-38, dc-39, dc-29, dc-28, dc-41, dc-43, topic-04, topic-09]
---

# DCIM（Data Center Infrastructure Management）

前面幾十張卡各自畫了一張圖：電力樹、冷卻鏈、空間層級、[BMS 的控制依賴](bms-building-management-system.md)、[EPMS 的事件時間基準](epms-electrical-power-monitoring.md)。DCIM 是**把這些圖放進同一個資料庫、並讓人能在上面做容量決策與變更的那一層**。它不是一台設備，也不是一種新的感測器；它的產品是「資產與其關係的一份被維護的記錄」。所以這張卡的重點不在功能清單，而在**這份記錄為什麼會爛、怎麼知道它爛了**。

## 六格

### 拓撲位置
上游：資產的來源有三條——人工登記（採購、上架、變更工單）、自動探索（網路掃描、SNMP／Redfish，見 `dc-43`、`dc-44`）、以及 BMS／EPMS 的點位（[dc-38](bms-building-management-system.md)、[dc-39](epms-electrical-power-monitoring.md)）。下游：容量規劃、變更管理與稽核軌跡、能源報表、對 ITSM／CMDB 的介接。TechTarget 把核心拆成四件：**集中資料庫**（每個被管資產，含伺服器、儲存、網路、PDU、HVAC、環境感測器）、**DCIM 軟體**（取資料庫與效能指標做趨勢與容量規劃）、**儀表板**、**軟體連接器**（API 或自製）。**它不在電力樹上，也不在控制迴圈裡**：它是讀者，不是設備的控制者。

### 容量單位
沒有 kW。DCIM 管的是「**幾個容量維度同時有餘裕**」：電力（kW，見[機櫃 PDU](rack-pdu.md)的降額後預算）、冷卻（kW 熱負載）、空間（U，見[機櫃與 RU](rack-and-rack-unit.md)）；來源另提重量、網路埠。**真正能放幾台，取最先見底的那一維**（計算一）。授權單位則是商業欄位：每機櫃每年（見計算三）。

### 冗餘表達
來源**沒有討論 DCIM 本身的冗餘或可用度**。DCIM 掛了機房照常運轉；它的風險是資料準確度，不是 uptime。

### 遙測介面
| 面向 | 來源實際提到的 | 備註 |
|---|---|---|
| 與設施系統 | 「software integration」、API／連接器 | TechTarget、Vertiv 都**未列協定名** |
| 與 IT 系統 | 與既有管理工具連結；Vertiv 稱可細到「某台機架伺服器的某個埠」 | 廠商宣稱，無細節 |
| 稽核軌跡 | change management：硬體與流程變更、audit trail、work order | 這是 DCIM 與純監控最大的差異 |
| 部署 | on-premises 或雲端託管（TechTarget） | DCD 稱新的雲端版本部署較簡單 |

協定本身留給 `dc-41`、`dc-43`、`dc-44`。

### 故障域
DCIM 掉了，**沒有任何設備掉**。真正的故障是兩種「靜默」：(1) 資料庫與現場不一致（資產搬了沒更新），所有以它為準的容量決策都建立在錯的前提上；(2) 它依賴的連接器斷了，儀表板仍顯示最後一筆值。後者與 dc-38 的 `POINT_STALE` 同構。Uptime 圓桌（2019）把「維持資產資料庫準確」列為困難之一，因為它是其他功能的基礎。

### 維護特性
DCIM 的維護不是版本更新，而是**每次現場變更都要回頭更新記錄**。沒有停機窗口，只有「登記率」：現場變更有幾成被記回資料庫（計算二的 r）。導入本身很重：Uptime 圓桌的與會者說基本功能通常超過 **18 個月**，進階功能更久；資料庫缺乏可自訂欄位的產品特別難設定。

## 關鍵數字與計算

**一、可放幾台：取最先見底的維度（first-to-fill）**。這是容量規劃的最小模型，數字為我的假設：機櫃 42U，預留 4U 給交換器與線管 → 可用 38U；降額後電力預算 8000 W；分到這個機櫃的冷卻能力 7000 W；要放 2U 伺服器，單台尖峰 450 W（熱負載取同值，假設）。

- 空間：38 ÷ 2 = **19**
- 電力：⌊8000 ÷ 450⌋ = **17**
- 冷卻：⌊7000 ÷ 450⌋ = **15**

取最小 **15 台，卡在冷卻**。此時其他維度剩下：空間 38 − 30 = **8U**（21%）、電力 8000 − 6750 = **1250 W**（15.6%）。這 8U 與 1250 W 就是被冷卻鎖住的**擱置容量**（`topic-04` 會細拆）。若冷卻改成 9000 W（可放 20 台），則換成電力卡住，上限 **17**，剩 4U 與 350 W。一張只顯示「機櫃還有 8U」的儀表板，會讓人去放第 16 台。

**二、資產資料庫會爛得多快（我的簡化模型，非來源公式）**。設每月有比例 c 的資產被現場動過（搬移、換件、退役），其中比例 r 被記回資料庫。每月仍正確的比例約 `(1 − c(1 − r))`，t 個月後準確度 `A(t) = (1 − c(1 − r))^t`。取 c = 3%／月：

| 登記率 r | 6 個月 | 12 個月 | 24 個月 |
|---|---|---|---|
| 80% | 0.965 | **0.930** | 0.866 |
| 50% | 0.913 | **0.834** | 0.696 |
| 0%（上線後沒人更新） | 0.833 | **0.694** | 0.481 |

準確度掉到 90% 要幾個月：r = 80% → **18 個月**；r = 50% → **7 個月**。模型很粗（假設各資產獨立、變更率固定），但它點出：**登記率從 80% 掉到 50%，保鮮期從一年半縮成不到半年**。這對應 datacentres.com 的建議：指派資料管理員、把資產更新放進 commissioning。

**三、市場與授權數字，以及它們彼此對不上**。

| 來源 | 年份 | 規模 | 成長 |
|---|---|---|---|
| Research and Markets（Business Wire） | 2024 | US$2.2B | 2030 達 US$3.7B，CAGR 9.2% |
| IMARC | 2025 | US$4.7B | 2034 達 US$13.2B，CAGR 11.73%（頁面內文）；meta 為 US$11.73B／13.2%，兩組數字互相對調 |
| datacentres.com | 2026 | 約 US$3.1B | 約 13%／年（無出處） |

檢查：2.2→3.7、6 年，複合成長 (3.7/2.2)^(1/6) − 1 ≈ **9.05%**，與其 9.2% 相符（四捨五入）。IMARC 4.7→13.2、9 年 ≈ **12.2%**，與其 11.73% 差 0.4 個百分點；若改用 meta 的 11.73B，則 ≈ **10.7%**。把第一家推到 2025 年約 2.4B，**IMARC 的 2025 數字是它的約 2 倍**。市場規模不是一個數，是「怎麼定義 DCIM」的函數。

授權：datacentres.com 稱 **US$800–2,500／機櫃／年**，並說 20 MW、2,500 機櫃的設施「五年約 US$2–5M」。代入：2,500 × 800 = **US$2.0M／年**，五年 = **10M**；2,500 × 2,500 = 6.25M／年。它自己的「五年 2–5M」換算成每機櫃每年只有 **US$160–400**，與它引的區間差 5 到 6 倍。**同一篇文章內部對不上**。

## 常見誤解

**以為 DCIM 是一套買來裝上就會監控機房的軟體，但實際上它是一份資產記錄加上維護這份記錄的流程**。軟體只是介面，資料準確度決定價值。Uptime 的與會者說基本功能超過 18 個月；DCD 作者（為顧問，立場偏 DCIM 支持者）指出主要障礙是實作、技能缺口，以及採購同時牽涉 IT、設施、M&E 三種優先序不同的團隊。

**以為 DCIM 會取代 BMS／EPMS，或是它們終究要整合進 DCIM，但實際上來源對這點立場分歧**。Data Center Frontier（Schneider 贊助）寫「BMS 與 EPMS 管 grey space，DCIM 管 white space」，並說「任何一套都不會取代另一套」，價值在三者重疊處，也不必然要動態整合。Vertiv 與 TechTarget 則把 DCIM 寫成設施與 IT 的**匯流**。見下方「來源分歧」。

**以為資料庫裡的欄位是現場的事實，但實際上它只是「最後一次有人登記時」的事實**。計算二的 A(t) 就是這個落差。軟體工程師習慣資料庫是 source of truth；在機房它是**對現場的一個帶時戳的主張**。

## 對資料模型的意涵

1. **每個資產欄位都要有「權威」與「驗證時戳」**。`Asset{id, kind, location, owner_team, lifecycle, discovery_method}` 之外，每個會被容量計算使用的欄位（位置、U 高、額定功率）另掛 `Verification{field, verified_by, verified_ts, method: human|scan|telemetry}`。**這直接回應「設施與 IT 不共享擁有權，所以記錄分歧」**：欄位級的 `owner_team` 讓誰負責哪個欄位成為資料，不是會議結論。
2. **第十個「缺東西」告警是三個集合的差集，不是一個欄位**。設 A＝DCIM 登記的資產、D＝探索到的資產、P＝有點位的資產 id：`D − A` → `ASSET_UNREGISTERED`（現場有、記錄沒有）；`A − D` → `ASSET_NOT_DISCOVERED`（記錄有、現場沒看到，可能已退役）；`P − A` → `POINT_ORPHAN`（有人在量一個沒人登記的東西）。外加 `ASSET_VERIFICATION_STALE`（驗證時間超過期限）。**前九個「缺東西」是模型內部的缺漏，這一個是模型與現場之間的缺漏。**
3. **容量是帳本，不是欄位**。`CapacityLedger(rack, dimension ∈ {space, power, cooling, weight, ports}, budget, committed)`，`placeable = min over dims`，並回傳 `binding_dimensions`（可能不只一個）。**不要存「剩餘 U」**，剩餘量是派生值；存了就會與其他維度不同步。
4. **DCIM 與 BMS／EPMS 的邊界落在 `Point`**。dc-38 的 `Point.owner_system` 在這裡多一個外鍵 `asset_id`；`asset_id` 為空即 `POINT_ORPHAN`。**不論最後三個系統合併與否，這個外鍵都是必要的**，因為來源分歧的是「要不要整合」，沒有人說可以不知道一個點位屬於誰。
5. **變更是一等實體**。TechTarget 把 change management（稽核軌跡、work order）列為模組。`Change{id, asset_id, field, old, new, requested_by, approved_by, executed_ts, verified_ts}`；`verified_ts` 為空的變更期限一到就是 `CHANGE_UNVERIFIED`。這是計算二裡 r 的來源——登記率可以直接算出來，不用猜。

## 來源分歧

- **範疇**：Data Center Frontier（Schneider 贊助）把 DCIM 限於 white space，BMS／EPMS 管 grey space，三者互補；Vertiv 的頁面以「設施管理、IT 管理與自動化的匯流」描述 DCIM，並引 Gartner 定義為「監測、量測、管理與（或）控制資料中心使用率與**所有 IT 相關設備**的能耗」；TechTarget 同樣寫「IT 基礎設施、營運與建築設施功能的匯流」。Vertiv 引的 Gartner 句子偏 IT 設備，與「匯流」措辭有張力，**三家皆廠商或廠商贊助，沒有獨立裁決**。
- **市場規模**：2.2B（2024）／4.7B（2025）／3.1B（2026），見計算三。IMARC 自身的數字互相對調，datacentres.com 的授權換算自相矛盾。
- **導入時程**：Uptime 圓桌（2019，與會者經驗）基本功能超過 **18 個月**；datacentres.com（2026）建議單點 **6–9 個月**、多點 12–18 個月，且批評廠商「90 天上線」不切實際。兩者相差一倍，**一個是 2019 年的回顧，一個是無出處的 2026 年建議**。
- **失敗率**：datacentres.com 稱約 60% 的部署兩年內未產生可量測回報，來源是「長期的 Uptime Institute 調查」，**未註明報告、年份、樣本或「可量測回報」的定義**。我不把 60% 當事實使用。

**未查證**：Gartner 原始定義全文、Vertiv Trellis 停產（僅 DCD 一家：2021 年秋宣布，支援到 2023）與 Carrier 併購 Nlyte 細節、台灣採用情形與法規、NetBox 在這個光譜上的位置、各廠商功能實測。

## 該問 facility 的問題

1. 現在機房的「資產真相」放在哪裡（Excel、CMDB、廠商 DCIM）？上一次有人把它與現場逐台核對是什麼時候？
2. 現場變更（上架、搬移、退役）誰負責回寫記錄？有沒有一個欄位能看出某筆變更是否已驗證？
3. 設施這邊（BMS／EPMS）與 IT 這邊各有哪些資產清單？兩邊的編號是否有對照表，還是各自一套？

## 動手練習（35 分鐘）

**目標**：寫 `dcim.py`，實作計算一（first-to-fill）、計算二（準確度衰減）與第十個「缺東西」告警（三集合對帳）。**接在 [dc-39](epms-electrical-power-monitoring.md) 的 `epms.py` 後面**：沿用 `(code, subject)` 元組，`reconcile()` 的結果可直接 append 到同一個 `findings`。

```python
# dcim.py（約 50 行；骨架）
def fit(u_free, power_w, cool_w, unit_u, unit_w):
    # lim = {"space": u_free//unit_u, "power": power_w//unit_w, "cooling": cool_w//unit_w}
    # n = min(lim.values()); bind = 所有等於 n 的維度（sorted）
    # left = 每個維度放完 n 台後的剩餘（space 為 U，其餘為 W）
    # return n, bind, left, lim

def accuracy(c, r, months):          # (1 - c*(1-r)) ** months
def months_to(target, c, r):         # 準確度掉到 target 以下所需最少整數月（ceil）

def reconcile(A, D, P, verified_days, limit=180):
    # A, D, P 為 set；verified_days: {asset_id: 距上次驗證的天數}
    # D-A -> ASSET_UNREGISTERED；A-D -> ASSET_NOT_DISCOVERED
    # P-A -> POINT_ORPHAN；verified_days[x] > limit -> ASSET_VERIFICATION_STALE
    # 回傳 sorted 的 (code, subject) 清單
```

測試資料：`A={SRV-1..SRV-5, PDU-A, UPS-A}`；`D={SRV-1, SRV-2, SRV-3, SRV-6, PDU-A, UPS-A}`；`P={UPS-A, PDU-A, CRAC-1}`；`verified_days={SRV-1:10, SRV-2:200, SRV-3:180, SRV-4:181, PDU-A:30}`。

### 驗收表

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | `fit(38, 8000, 7000, 2, 450)` | `n=15`，`bind=["cooling"]`，`lim={space:19, power:17, cooling:15}` |
| 2 | 同上的剩餘量 | 空間 **8** U、電力 **1250** W、冷卻 **250** W |
| 3 | `fit(38, 8000, 9000, 2, 450)` | `n=17`，`bind=["power"]`，剩餘空間 **4** U、電力 **350** W |
| 4 | `fit(38, 7650, 9000, 2, 450)` | `n=17`，電力剩餘 **0**（恰好用盡也要算 17） |
| 5 | `accuracy(0.03, r, 12)`，r = 0.8／0.5／0 | **0.930／0.834／0.694** |
| 6 | `months_to(0.9, 0.03, 0.8)`；`r=0.5` | **18**；**7** |
| 7 | `reconcile(A, D, P, verified_days)` | `[("ASSET_NOT_DISCOVERED","SRV-4"), ("ASSET_NOT_DISCOVERED","SRV-5"), ("ASSET_UNREGISTERED","SRV-6"), ("ASSET_VERIFICATION_STALE","SRV-2"), ("ASSET_VERIFICATION_STALE","SRV-4"), ("POINT_ORPHAN","CRAC-1")]` |
| 8 | 上一列中的 SRV-3（恰好 180 天） | **不**出現在 STALE（邊界用嚴格大於） |
| 9 | 把 SRV-6 加進 A 之後再 `reconcile` | `ASSET_UNREGISTERED` 消失，其餘不變 |

**加分題**：實作 `registration_rate(changes)`，輸入 `Change` 清單（`executed_ts`、`verified_ts` 可為 None），回傳已驗證比例，並用它回推「按現況，準確度幾個月掉到 90%」；再問：如果 r 是量得出來的，容量帳本是否該在 r 低於某個門檻時**拒絕**輸出 `placeable`，改回傳區間？

## 自我檢核

**Q1. 機櫃還有 8U 空間、1250 W 電力餘裕，為什麼不能放第 16 台 2U 伺服器？**

??? note "答案"
    冷卻餘裕只剩 250 W，不到一台 450 W。可放台數取三個維度的最小值，這個機櫃被冷卻卡在 15 台。其他維度的餘裕（8U、1250 W）是被冷卻鎖住的擱置容量。

**Q2. 登記率從 80% 降到 50%，資產準確度掉到 90% 的時間從 18 個月變成多久？為什麼這個數字對 DCIM 的導入計畫重要？**

??? note "答案"
    7 個月（`ceil(ln 0.9 / ln(1 − 0.03×0.5))`）。導入計畫的成本重心不是軟體上線，而是維持登記率；沒有資料管理員與變更驗證流程，資料庫在半年內就不能支撐容量決策。

**Q3. 這張卡會讓資料模型長出什麼欄位與告警？**

??? note "答案"
    欄位級的 `Verification{field, verified_by, verified_ts, method}` 與 `owner_team`；`Point.asset_id` 外鍵；`CapacityLedger(rack, dimension, budget, committed)` 與派生的 `placeable`、`binding_dimensions`；`Change{…, verified_ts}`。告警：`ASSET_UNREGISTERED`、`ASSET_NOT_DISCOVERED`、`POINT_ORPHAN`（第十個「缺東西」，三集合差集）、`ASSET_VERIFICATION_STALE`、`CHANGE_UNVERIFIED`。約束：剩餘量為派生值，不存。

---

**下一張**：`dc-41` Modbus RTU / TCP 基礎與暫存器位址
