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
- 設備卡 — [市電進線](devices/utility-feed.md)、[變壓器](devices/transformer.md)、[中壓開關設備](devices/mv-switchgear.md)、[LSC 分級與互鎖](devices/lsc-and-interlocks.md)、[自動切換開關 ATS](devices/ats-transfer-switch.md)、[柴油發電機（額定與容量）](devices/diesel-generator.md)、[發電機起動時序與暫態性能](devices/genset-start-and-transient.md)、[NFPA 110 測試制度與 wet stacking](devices/nfpa110-testing-and-wet-stacking.md)、[日用油箱與儲油槽](devices/day-tank-and-bulk-fuel.md)、[低壓主配電盤（額定電流體系）](devices/lv-switchgear.md)、[低壓盤短路耐受與保護協調](devices/lv-short-circuit-and-coordination.md)、[UPS 不斷電系統（雙轉換式）](devices/ups-double-conversion.md)、[UPS 電池組（VRLA vs 鋰電）](devices/ups-battery.md)、[電池測試制度（IEEE 1188）](devices/battery-testing-regime.md)、[鋰電消防合規（NFPA 855 / UL 9540A）](devices/lib-fire-compliance.md)、[靜態切換開關 STS](devices/static-transfer-switch.md)、[STS 兩源關係（一）拓撲獨立性與容量會計](devices/sts-two-source-relationship.md)、[STS 兩源關係（二）相位同步窗](devices/sts-source-synchronization.md)、[PDU 配電單元](devices/pdu-floor.md)、[RPP 遠端配電盤](devices/rpp-remote-power-panel.md)、[匯流排 busway 與插接箱](devices/busway-and-tap-off-box.md)、[機櫃電源 rack PDU](devices/rack-pdu.md)、[電力監測儀表與電錶](devices/power-meter.md)、[設備端雙電源與單電源](devices/dual-corded-equipment.md)、[冷卻水塔](devices/cooling-tower.md)
- [主題卡](topics/index.md) — 容量語意、協定、流程等非設備主題
- [週報](weekly/index.md) — 每週彙整 + 自我測驗 + 間隔複習

## 進度

| 項目 | 狀態 |
|---|---|
| 佇列總數 | 69 |
| 已完成 | 25 |
| 目前輪次 | **第二輪：冷卻鏈**（2026-09-03 由 [dc-17 冷卻水塔](devices/cooling-tower.md) 開工）。第一輪電力鏈 dc-01 ~ dc-16 已於 2026-09-02 全數完成 |
| 下一張 | `dc-18` 冰水主機（氣冷 vs 水冷）。[dc-17](devices/cooling-tower.md) 已指出**真正的約束不在水塔身上**——冷卻水溫浮高的代價全部轉嫁給冰機（lift↑、容量↓、kW/ton↑、高壓跳脫），明天要把這條約束算出來 |
| ⚠ 欠的盤點 | **單線圖對照盤點尚未做。** 排程任務手上沒有公司的單線圖，無法自動執行。[backlog](backlog.md) 的「第一輪補完」那一節先留空，等使用者拿到圖再回頭插項目 |
| 週報 | 5 份（最新：[2026-W35](weekly/2026-W35.md)） |
| 下次間隔複習 | W36：抽 W34 的卡（dc-09b ~ dc-10）＋ W32 的卡（dc-04 ~ dc-05c，第二次） |
| 待收斂的 model code | 11 項。W35 清掉四項舊帳（`DeviceRegistry` ✅ 欠四週終於兌現、`Bound` 值物件 ✅ 用在 `Angle(deg, kind)`、`Alarm`／`Finding` 循環依賴澄清 ✅、兩棵樹橫向邊 ✅）。**新第一順位是 `Finding` 定義 ＋ 三處 `validate() -> list[str]` 改回 `list[Finding]`**；第二順位 **`CapacityReport` 統一**（`dc-11`／`dc-12`／`dc-13` 三種回傳型別互不相交）。**[dc-14](devices/rack-pdu.md)（2026-08-31）的動手練習就是把這兩項一次做完**，並用 rack PDU 當第四個實作者驗證 `binding` 會跑（30 A 機 binding = 進線、50 A 機 binding = bank 斷路器）。`Method` 因此新增 `vector_sum`。[dc-09](devices/ups-battery.md) 的 `energy_kwh()` 改名**連續第二週掛第一順位卻沒做**，10 分鐘。**[dc-15](devices/power-meter.md)（2026-09-01）再加兩項**：`Method` 新增 `measured`（`remaining` 要用誤差帶的保守端，不是點值），以及 `Dimension.valid` 從 dc-14 定義至今第一次真的被用上——錶失聯時實測維度是 stale 不是 0，要退回 nameplate 法並吐 `METER_STALE` 的 `Finding`。**[dc-16](devices/dual-corded-equipment.md)（2026-09-02）再加一項且優先級最高**：`CapacityReport` 要多一維 `scenario`（`normal` / `lose_a` / `lose_b`），`binding()` 取跨情境最壞值。**這是第一個會讓既有數字變壞的維度**——10 kW 機櫃從「每側 50.5% 綠燈」翻成「failover 116.8% 紅燈」，所以它不能排隊，得跟 `Finding` 一起做。**[dc-17](devices/cooling-tower.md)（2026-09-03）再加三項，其中一項是目前為止對既有 code 最大的一刀**：(a) **`Dimension` 新增 `resource` 與 `unit`，`binding()` 改成 per-resource 回傳**——水是第二種資源，kW 不能跟 L/min 比大小，這會動到 dc-11 之後每一個實作者；(b) `Dimension.limit` 從 `float` 變成 `limit(env)`，`CapacityReport` 必須記 `evaluated_at_env`；(c) `Method` 新增 `curve`（廠商性能曲線），與 `nameplate` / `measured` / `vector_sum` 並列 |
| **容量是環境的函數** | **[dc-17](devices/cooling-tower.md) 立的新分界**：[dc-16](devices/dual-corded-equipment.md) 讓容量多了**離散**的 `scenario`（3 個值），冷卻水塔多的是**連續**的環境自變數。冷水設定 32 °C 不變時，濕球 28→30 °C（approach 4→2 K）容量掉一半：4 格 × 650 kW 從 2 600 掉到 1 300 kW，而實需 1 850 kW——**零設備故障、容量就已經不足**。前 16 張卡的模型完全表達不了這種狀況。連帶：即時監控與容量規劃第一次需要**不同的輸入**（維護窗口可行性要用設計濕球算，不是今天的遙測值） |
| **站點級外生變數** | **[dc-17](devices/cooling-tower.md) 立的第三類**（繼 dc-15「拓撲 vs 標註」、dc-16「設施 vs IT 管理平面」）：濕球同時被水塔、冰機、free cooling 切換判斷、CRAH 除濕四處消費，掛在單一水塔下當 `MeasurementPoint` 會被複製四份且互相不一致 → 屬於 `SiteEnvironment` 時間序列，且常是推導值（乾球＋RH），要記 `derived_from`，RH 失效時走 dc-15 的降級路徑 |
| **兩棵樹第一次有真實流量** | [dc-17](devices/cooling-tower.md) 是**第一個同時是兩棵樹節點的設備**：熱圖上的節點（上游冰機冷凝器、下游大氣）＋ 電力圖上的葉負載（風扇／泵／盆加熱器）。W35 收斂的「兩棵樹橫向邊」在這裡第一次被用上，且方向是**電→熱**：`lose_a` 要能傳播成熱側的容量損失，所以 [dc-13](devices/busway-and-tap-off-box.md) 立、[dc-16](devices/dual-corded-equipment.md) 參數化的 `prefix_sum(edge, scenario)` 需要一個熱側對偶 |
| **設施 vs IT 管理平面** | **[dc-16](devices/dual-corded-equipment.md) 立的新分界**（繼 dc-15 的「拓撲 vs 標註」）：Dell hot spare 開著時 A/B 分配是 100/0 不是 50/50，而這個設定住在 iDRAC，**設施側任何一張表都沒有**。`psu_policy` 要帶 `source="redfish"` ＋ `fetched_at`，會被伺服器管理員在設施不知情下改掉，**變動時必須觸發容量重算**。凡是「真相在 IT 管理平面」的欄位（PSU 政策、power cap、BMC 回報的實際功耗）之後一律走匯入＋TTL＋降級，不當設施側的靜態設定 |
| **樹變成 DAG** | [dc-16](devices/dual-corded-equipment.md)：前 15 張建的是單父節點的樹，雙電源設備一來就是幾千個**兩個父節點的葉子**。沿樹的前綴和（[dc-13](devices/busway-and-tap-off-box.md) 立的）要參數化成 `prefix_sum(edge, scenario)`；[dc-10b](devices/sts-two-source-relationship.md) 的 common-ancestor 測試從「幾台 STS」擴大到**每一台伺服器**，必須是查詢不是存欄位 |
| **dc-14 待回頭修** | [dc-16](devices/dual-corded-equipment.md) 記下 **NetBox 斷點第二條**（`topic-10`）：NetBox 有 `PowerFeed.type = primary\|redundant`，但機櫃用電率計算**不看這個欄位**——雙電源設備兩個 power port 各填 500 W，機櫃就顯示 1000 W（discussion #12837，至今未實作）。第一條斷點（dc-14 的 `feed_leg` 不支援 delta）是**表達不了**，這一條是**算錯**，後者更危險：它會給你一個看起來合理的數字 |
| **拓撲 vs 標註** | **[dc-15](devices/power-meter.md) 立的新分界**：電錶不是電力樹上的節點，是掛在節點或邊上的觀測器（`MeasurementPoint`）。硬塞進樹裡的話每插一顆錶深度就多一層，[dc-10b](devices/sts-two-source-relationship.md) 的 common-ancestor 跳數會被污染。**凡是「只看不供電」的東西（錶、感測器、CCTV、門禁讀卡機）之後一律走標註不走拓撲** |
| **dc-11 待回頭修** | 兩張卡各找出一個錯。[dc-12](devices/rpp-remote-power-panel.md)：**(1) ×0.80 不是常數**，是「80% rated 斷路器＋列名外殼」這個組合的屬性（同一顆 400 A 差 8.7 個機櫃）→ 要 `derating_basis`；**(2)「算得出來的一律不存」有例外**——插拔式母線上相位是插法不是位置 → 把前提變成欄位 `Panelboard.phase_mode`。另 `Pdu.kva_derated()` 把 0.80 寫死，是目前唯一會改變既有數字的修正 |
| **dc-12 待回頭修** | [dc-13](devices/busway-and-tap-off-box.md) 找出一個錯：**`requires_outage_to_add_circuit: bool` 不夠用**。OSHA 2025-08-25 解釋函（引 NFPA 70E table 130.5(C)）確認 busway 插接箱插拔屬能量作業——不停機但要工單＋合格人員＋PPE。布林會把它錯分到「不用管」→ 改三態 `change_class`。另 `Breaker`／`Panelboard` 被 dc-11／dc-12 各定義一次且欄位不相容（`load_kw` 遺失 → dc-11 的不平衡計算會壞） |

## 提醒：有時效性的事

機房在施工中，**commissioning（系統測試調校）會在接下來幾個月內發生**。整廠斷電測試、UPS 切換測試、發電機帶載測試——這些一次性且不可重現。

> **只要 commissioning 開始，中斷佇列，全部時間投進去。** 事後補不回來。
