---
track: datacenter
started: 2026-07-28
---

# 資料中心學習軌跡

目標：**在自建自營機房（新建中）建置 infra management 系統**所需的領域知識。
時間預算：**每天 1 小時**，六個月（約 180 小時）。

## 這條軌跡怎麼運作

跟本站另一條 GitHub trending 軌跡**機制完全不同**：

| | GitHub trending 軌跡 | 資料中心軌跡 |
|---|---|---|
| 驅動方式 | **爬蟲驅動** — 每天掃 trending，看到什麼寫什麼 | **教材驅動** — 佇列決定今天寫什麼 |
| 語料 | 開放且每天在變 | **封閉且緩慢變動** |
| 每篇長度 | 800–1000 字 | **6000–9000 字元**（上限 10000；深度優先，寧願慢也要學透） |
| 節奏 | 每日 1–2 篇 | 每日 1 張卡（讀 15 分 + 動手 40 分），週日一份複習 |

之所以不用爬蟲驅動：資料中心的基礎知識十年沒變，每天去爬只會拿到同一批概念的第 N 次重述。**這裡真正稀缺的不是資訊，是把資訊整理成你資料模型的欄位。**

## 每張設備卡的六格

| 欄位 | 填什麼 |
|---|---|
| **拓撲位置** | 上游接誰、下游接誰 |
| **容量單位** | kW / kVA / A / RT / CFM / U / kg，以及銘牌與實測的關係 |
| **冗餘表達** | N、N+1、2N 在這類設備上具體長什麼樣 |
| **遙測介面** | 協定 + 關鍵點位清單 |
| **故障域** | 它掉了誰跟著死、多久內有影響 |
| **維護特性** | 週期、是否需停機、停機時的替代路徑 |

**這六格不是背誦卡，是資料表的欄位規格。**

## 導覽

- [完整 Roadmap](roadmap.md) — 六個月分階段、教材清單、驗收條件
- [學習佇列](backlog.md) — 69 項，每個工作日消耗一項
- 設備卡 — [市電進線](devices/utility-feed.md)、[變壓器](devices/transformer.md)、[中壓開關設備](devices/mv-switchgear.md)、[LSC 分級與互鎖](devices/lsc-and-interlocks.md)、[自動切換開關 ATS](devices/ats-transfer-switch.md)、[柴油發電機（額定與容量）](devices/diesel-generator.md)、[發電機起動時序與暫態性能](devices/genset-start-and-transient.md)、[NFPA 110 測試制度與 wet stacking](devices/nfpa110-testing-and-wet-stacking.md)、[日用油箱與儲油槽](devices/day-tank-and-bulk-fuel.md)、[低壓主配電盤（額定電流體系）](devices/lv-switchgear.md)、[低壓盤短路耐受與保護協調](devices/lv-short-circuit-and-coordination.md)、[UPS 不斷電系統（雙轉換式）](devices/ups-double-conversion.md)、[UPS 電池組（VRLA vs 鋰電）](devices/ups-battery.md)、[電池測試制度（IEEE 1188）](devices/battery-testing-regime.md)、[鋰電消防合規（NFPA 855 / UL 9540A）](devices/lib-fire-compliance.md)、[靜態切換開關 STS](devices/static-transfer-switch.md)、[STS 兩源關係（一）拓撲獨立性與容量會計](devices/sts-two-source-relationship.md)、[STS 兩源關係（二）相位同步窗](devices/sts-source-synchronization.md)、[PDU 配電單元](devices/pdu-floor.md)、[RPP 遠端配電盤](devices/rpp-remote-power-panel.md)、[匯流排 busway 與插接箱](devices/busway-and-tap-off-box.md)、[機櫃電源 rack PDU](devices/rack-pdu.md)
- [主題卡](topics/index.md) — 容量語意、協定、流程等非設備主題
- [週報](weekly/index.md) — 每週彙整 + 自我測驗 + 間隔複習

## 進度

| 項目 | 狀態 |
|---|---|
| 佇列總數 | 69 |
| 已完成 | 22 |
| 目前輪次 | 第一輪：電力鏈 |
| 下一張 | `dc-15` 電力監測儀表與電錶（power meter / EPMS 感測點） |
| 週報 | 5 份（最新：[2026-W35](weekly/2026-W35.md)） |
| 下次間隔複習 | W36：抽 W34 的卡（dc-09b ~ dc-10）＋ W32 的卡（dc-04 ~ dc-05c，第二次） |
| 待收斂的 model code | 11 項。W35 清掉四項舊帳（`DeviceRegistry` ✅ 欠四週終於兌現、`Bound` 值物件 ✅ 用在 `Angle(deg, kind)`、`Alarm`／`Finding` 循環依賴澄清 ✅、兩棵樹橫向邊 ✅）。**新第一順位是 `Finding` 定義 ＋ 三處 `validate() -> list[str]` 改回 `list[Finding]`**；第二順位 **`CapacityReport` 統一**（`dc-11`／`dc-12`／`dc-13` 三種回傳型別互不相交）。**[dc-14](devices/rack-pdu.md)（2026-08-31）的動手練習就是把這兩項一次做完**，並用 rack PDU 當第四個實作者驗證 `binding` 會跑（30 A 機 binding = 進線、50 A 機 binding = bank 斷路器）。`Method` 因此新增 `vector_sum`。[dc-09](devices/ups-battery.md) 的 `energy_kwh()` 改名**連續第二週掛第一順位卻沒做**，10 分鐘 |
| **dc-11 待回頭修** | 兩張卡各找出一個錯。[dc-12](devices/rpp-remote-power-panel.md)：**(1) ×0.80 不是常數**，是「80% rated 斷路器＋列名外殼」這個組合的屬性（同一顆 400 A 差 8.7 個機櫃）→ 要 `derating_basis`；**(2)「算得出來的一律不存」有例外**——插拔式母線上相位是插法不是位置 → 把前提變成欄位 `Panelboard.phase_mode`。另 `Pdu.kva_derated()` 把 0.80 寫死，是目前唯一會改變既有數字的修正 |
| **dc-12 待回頭修** | [dc-13](devices/busway-and-tap-off-box.md) 找出一個錯：**`requires_outage_to_add_circuit: bool` 不夠用**。OSHA 2025-08-25 解釋函（引 NFPA 70E table 130.5(C)）確認 busway 插接箱插拔屬能量作業——不停機但要工單＋合格人員＋PPE。布林會把它錯分到「不用管」→ 改三態 `change_class`。另 `Breaker`／`Panelboard` 被 dc-11／dc-12 各定義一次且欄位不相容（`load_kw` 遺失 → dc-11 的不平衡計算會壞） |

## 提醒：有時效性的事

機房在施工中，**commissioning（系統測試調校）會在接下來幾個月內發生**。整廠斷電測試、UPS 切換測試、發電機帶載測試——這些一次性且不可重現。

> **只要 commissioning 開始，中斷佇列，全部時間投進去。** 事後補不回來。
