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
- [學習佇列](backlog.md) — 70 項，每個工作日消耗一項
- 設備卡 — [市電進線](devices/utility-feed.md)、[變壓器](devices/transformer.md)、[中壓開關設備](devices/mv-switchgear.md)、[LSC 分級與互鎖](devices/lsc-and-interlocks.md)、[自動切換開關 ATS](devices/ats-transfer-switch.md)、[柴油發電機（額定與容量）](devices/diesel-generator.md)、[發電機起動時序與暫態性能](devices/genset-start-and-transient.md)、[NFPA 110 測試制度與 wet stacking](devices/nfpa110-testing-and-wet-stacking.md)、[日用油箱與儲油槽](devices/day-tank-and-bulk-fuel.md)、[低壓主配電盤（額定電流體系）](devices/lv-switchgear.md)、[低壓盤短路耐受與保護協調](devices/lv-short-circuit-and-coordination.md)、[UPS 不斷電系統（雙轉換式）](devices/ups-double-conversion.md)、[UPS 電池組（VRLA vs 鋰電）](devices/ups-battery.md)、[電池測試制度（IEEE 1188）](devices/battery-testing-regime.md)、[鋰電消防合規（NFPA 855 / UL 9540A）](devices/lib-fire-compliance.md)、[靜態切換開關 STS](devices/static-transfer-switch.md)、[STS 兩源關係（一）拓撲獨立性與容量會計](devices/sts-two-source-relationship.md)、[STS 兩源關係（二）相位同步窗](devices/sts-source-synchronization.md)、[PDU 配電單元](devices/pdu-floor.md)、[RPP 遠端配電盤](devices/rpp-remote-power-panel.md)、[匯流排 busway 與插接箱](devices/busway-and-tap-off-box.md)、[機櫃電源 rack PDU](devices/rack-pdu.md)、[電力監測儀表與電錶](devices/power-meter.md)、[設備端雙電源與單電源](devices/dual-corded-equipment.md)、[冷卻水塔](devices/cooling-tower.md)、[冰水主機](devices/chiller.md)、[一次側／二次側冰水泵](devices/chilled-water-pump.md)、[儲冷槽與 ride-through](devices/thermal-storage-tank.md)、[NPSH 與泵的擺放高度](devices/npsh-and-pump-placement.md)
- [主題卡](topics/index.md) — 容量語意、協定、流程等非設備主題
- [週報](weekly/index.md) — 每週彙整 + 自我測驗 + 間隔複習

## 進度

| 項目 | 狀態 |
|---|---|
| 佇列總數 | 70（2026-09-07 從 dc-19 拆出 `dc-19b` NPSH 與泵的擺放高度） |
| 已完成 | 29 |
| 目前輪次 | **第二輪：冷卻鏈**（2026-09-03 由 [dc-17 冷卻水塔](devices/cooling-tower.md) 開工）。第一輪電力鏈 dc-01 ~ dc-16 已於 2026-09-02 全數完成 |
| 下一張 | `dc-21` 板式熱交換器與免費冷卻。[dc-20](devices/thermal-storage-tank.md) 答的是「冰機停了怎麼撐」，dc-21 答的是「冰機可以少開多久」——同一條熱鏈的另一種容量來源。（`dc-19b` 已於 2026-09-09 補完：它註明的「優先度低於 dc-20」在 dc-20 完成後即耗盡，故回頭取它）|
| ⚠ 欠的盤點 | **單線圖對照盤點尚未做。** 排程任務手上沒有公司的單線圖，無法自動執行。[backlog](backlog.md) 的「第一輪補完」那一節先留空，等使用者拿到圖再回頭插項目 |
| 週報 | 6 份（最新：[2026-W36](weekly/2026-W36.md)） |
| 下次間隔複習 | W37：抽 W35 的卡（dc-10b ~ dc-13）＋ W33 的卡（dc-06 ~ dc-09，第二次） |
| 🔴 已被後續卡片修正的結論 | **兩筆，都在 [W36 週報](weekly/2026-W36.md) 裡。** (1) **[dc-17](devices/cooling-tower.md) 那張「WB 30 °C、4 格、用率 142%、紅燈」的表是錯的**——它假設冷卻水恆定 32 °C，[dc-18](devices/chiller.md) 解聯立後實際收斂在 32.9 °C、**綠燈**；真正的紅燈是「平衡點超過保護設定值」（WB 30／2 格 → 35.8 °C > 冷凝器進水上限 35 °C），而那一列的容量用率**看起來完全正常**。(2) **[dc-16](devices/dual-corded-equipment.md) 驗收表的 `normal` 應是 58.4% 不是 50.5%**（分母誤用 10 kVA 而非單側 derated 的 8 646 VA）——**照它寫測試會直接紅**。W36 連貫性檢視 #6 給了不變式 `used_pct(lose_b) == 2 × used_pct(normal)`，並建議把「同卡內數字的自我一致性」加進 `dc-daily-card` 收尾檢查 |
| **幾何進入容量計算** | **[dc-19b](devices/npsh-and-pump-placement.md) 立的新分界**：前 20 張的拓撲只回答「誰接誰」，NPSH 回答的是「它在幾樓」。同一張單線圖、同一顆泵、同一組型錄數字，泵放地面層 vs 放屋頂與塔並排 → NPSHa **24.89 m vs 7.08 m**，最大可運轉流量 **170.4% vs 100.5%**（後者在 110% 流量時 margin 已是 −0.50 m，直接汽蝕）。→ `Device.elevation_m` ＋ `datum_ref`，且冷水盤要記**運轉水位**不是溢流水位。**第三輪的空間層級（`dc-28`）被提前需要了。** 另：`max_flow` 第一次是**解出來的**（NPSHa(Q) 遞減 × NPSHr(Q) 遞增的交點）而非查表值，且 **margin 判準本身會換分支**（`max(1.0 m, 0.1×NPSHr)`），所以 `Limit.basis` 要記到判準層級 |
| 待收斂的 model code | 13 項。W35 清掉四項舊帳（`DeviceRegistry` ✅ 欠四週終於兌現、`Bound` 值物件 ✅ 用在 `Angle(deg, kind)`、`Alarm`／`Finding` 循環依賴澄清 ✅、兩棵樹橫向邊 ✅）。**新第一順位是 `Finding` 定義 ＋ 三處 `validate() -> list[str]` 改回 `list[Finding]`**；第二順位 **`CapacityReport` 統一**（`dc-11`／`dc-12`／`dc-13` 三種回傳型別互不相交）。**[dc-14](devices/rack-pdu.md)（2026-08-31）的動手練習就是把這兩項一次做完**，並用 rack PDU 當第四個實作者驗證 `binding` 會跑（30 A 機 binding = 進線、50 A 機 binding = bank 斷路器）。`Method` 因此新增 `vector_sum`。[dc-09](devices/ups-battery.md) 的 `energy_kwh()` 改名**連續第二週掛第一順位卻沒做**，10 分鐘。**[dc-15](devices/power-meter.md)（2026-09-01）再加兩項**：`Method` 新增 `measured`（`remaining` 要用誤差帶的保守端，不是點值），以及 `Dimension.valid` 從 dc-14 定義至今第一次真的被用上——錶失聯時實測維度是 stale 不是 0，要退回 nameplate 法並吐 `METER_STALE` 的 `Finding`。**[dc-16](devices/dual-corded-equipment.md)（2026-09-02）再加一項且優先級最高**：`CapacityReport` 要多一維 `scenario`（`normal` / `lose_a` / `lose_b`），`binding()` 取跨情境最壞值。**這是第一個會讓既有數字變壞的維度**——10 kW 機櫃從「每側 50.5% 綠燈」翻成「failover 116.8% 紅燈」，所以它不能排隊，得跟 `Finding` 一起做。**[dc-17](devices/cooling-tower.md)（2026-09-03）再加三項，其中一項是目前為止對既有 code 最大的一刀**：(a) **`Dimension` 新增 `resource` 與 `unit`，`binding()` 改成 per-resource 回傳**——水是第二種資源，kW 不能跟 L/min 比大小，這會動到 dc-11 之後每一個實作者；(b) `Dimension.limit` 從 `float` 變成 `limit(env)`，`CapacityReport` 必須記 `evaluated_at_env`；(c) `Method` 新增 `curve`（廠商性能曲線），與 `nameplate` / `measured` / `vector_sum` 並列。**[dc-18](devices/chiller.md)（2026-09-04）再加三項**：(a) `CapacityReport` 新增 `converged` / `iterations` / `residual_k`——冰機容量要用固定點迭代解，不收斂的報表必須能明講自己不收斂；(b) **`Dimension` 新增 `lower_limit`**，違反時吐 `UNDERLOADED` 而非 `OVERLOADED`（處置方向相反）；(c) `Finding` 新增 `PROTECTION_TRIP_PREDICTED`，與 `OVERLOADED` **並列不可合併**。**[dc-19](devices/chilled-water-pump.md)（2026-09-07）再加三項**：(a) **`Dimension.aggregation` 必須是欄位**——兩台泵並聯只給 1.14 倍流量（87.3 vs 152.9 L/s，相加會高估 **75%**），這是 `sum`／`vector_sum` 之後第三種聚合，**程式裡任何一處寫死 `sum(...)` 都是還沒發現的 bug**；(b) **`Constraint` 第一次要作用在時間導數上**（`|dQ/dt| ≤ limit`），且該值住在 BMS 控制序列不在銘牌 → `RateConstraint(max_pct_per_min, source, commissioned_at)`；(c) `Limit` 要帶 `basis` 且同一維度可有多個上界（流速 12 ft/s vs 墊片 22.5 ft H₂O/pass），`min_flow` 則是**函數**不是欄位（線性 ＋ 50% 地板，寫錯會凍裂管束）。**[dc-20](devices/thermal-storage-tank.md)（2026-09-08）再加三項**：(a) **`Dimension` 新增 `kind = power｜energy`，`binding()` 在 per-resource 之上再加 per-kind**——儲冷槽存得下 400 kWh 卻只放得出 480 kW（能量 100%、功率 **334%**），**一個 `capacity` 欄位表達不了兩個維度**，而 kWh 與 kW 之間比大小沒有意義；(b) `CapacityReport` 新增 `recovery_until`——**容量第一次是路徑的函數**，放電後充回期間第二次事件不可存活，放電測試本身也開同樣的脆弱窗口；(c) `MeasurementPoint` 要有**陣列型別** `SensorArray(positions_m, values)`，SoC 是沿高度溫度剖面積分出來的推導值，頂底兩點量不到 thermocline 也量不到 tilt。**[dc-19b](devices/npsh-and-pump-placement.md)（2026-09-09）再加三項**：(a) **`Constraint` 必須三態** `satisfied / violated / not_applicable`——HI 9.8 淹沒公式只在 v > 0.61 m/s 成立，VFD 降到 41% 流量以下時該約束**不適用**而非滿足；這是 `Dimension.valid` 第一次因**公式適用域**失效（感測器好好的，是模型不成立），壓成 bool 會在低速時回報綠燈；(b) **`MeasurementPoint.range_min` ＋ `SENSOR_CANNOT_REPRESENT`**——吸入端裝普通壓力錶時負壓讀成 **0**，BMS 收到「正常」，**這是 dc-15「錶失聯是 stale 不是 0」的孿生錯誤：這次錶是好的，是量程說不出危險**；(c) `expansion_tank_connection_point` 是**拓撲欄位，決定泵自身揚程在 NPSHa 算式裡的正負號**（接吸入側 30.6 m，接出口側 −14.6 m、入口閃蒸）。**[W36 週報](weekly/2026-W36.md) 結算 W35 六項優先序：#1 `Finding` ✅、#2 `CapacityReport` 統一 ✅（但五天內被五次正交擴充）、#3 `continuous_factor` 🔴、#4 `Breaker`／`Panelboard` 合併 🔴、#5 `energy_kwh()` 🔴 **連續第三週**、#6 `Constraint` 基數 ⚠️ 決定不走。本週新增六項，兩紅**：#1 **`CapacityReport` 已不是一個型別而是三個**（五層正交擴充：向量和／誤差帶＋stale／情境／資源＋環境／迭代解）；#2 **`Finding` 只有 `severity`，還需要 `kind` 與 `lifecycle`**；#3 dc-16 驗收表算錯的數字（見上一列）；#4 `Bound` 與 `Dimension.remaining: float | None` 打架；#5 `Method` 混了兩件正交的事且已長到 8 個值；#6 方法命名第三次漂移。**規律第三次成立：寫成可貼 code 的建議會被採納，需要跨卡重構的不會**——所以 W36 六項全部寫成可貼的 dataclass。**#1 與 #2 必須在 dc-19 動筆前做完**（現在 30 + 20 分鐘；dc-19 是第六個實作者，寫完再做就是六張卡一起改）|
| **容量計算變成解聯立** | **[dc-18](devices/chiller.md) 立的新分界，也是本軌跡至今對計算模型最深的一刀**：前 17 張每一張的容量都是沿路徑的**純函數**（下游不影響上游）。冰機的 `limit` 依賴冷卻水溫，冷卻水溫又依賴冰機自己的排熱——**互為因果的正回饋迴路，只能解不能算**。dc-18 也因此**推翻了 [dc-17](devices/cooling-tower.md) 那張「WB 30 °C、4 格、用率 142%、紅燈」的表**：那是在「冷卻水恆定 32 °C」的錯誤前提下算的，聯立解出來其實收斂在 32.9 °C、綠燈。**真正的紅燈是「解出的平衡點超過保護設定值」**（WB 30／2 格 → 35.8 °C > 冷凝器進水上限 35 °C），而那一列的容量用率看起來完全正常 |
| **冗餘會反咬** | [dc-18](devices/chiller.md)：冰機有**下界**（`min_load_pct`，離心機典型 25–30%）。3 台 × 250 RT 跑 136 RT 時三台並聯每台只剩 18% → surge／熱氣旁通純燒電；只開一台則另兩台成冷備，重啟要好幾分鐘，ride-through 需求反而上升。**這是第一個「加冗餘反而讓事情變糟」的案例** → `RedundancyPolicy` 要能表達熱備 vs 冷備，不能只有 N+1 這個標籤 |
| **兩棵樹的邊變成雙向** | [dc-17](devices/cooling-tower.md) 建立的橫向邊方向是電→熱；[dc-19](devices/chilled-water-pump.md) 補上熱→電：為了熱側的 ride-through 把三台 30 kW 泵掛上 UPS，UPS 負載 1600 → 1690 kW（+5.6%）、runtime 10 → 9.5 分鐘。**這是第一次「為了熱側的可用性去吃電側的容量」** → 電力樹的葉負載清單必須包含冷卻設備，否則 UPS 的 `CapacityReport` 是錯的。Uptime Tier IV 是唯一明文要求 continuous cooling 的等級 |
| **能量 ≠ 功率** | **[dc-20](devices/thermal-storage-tank.md) 立的新分界**：前 19 張所有 `Dimension` 的單位都是**率**（kW／A／L/min／kVA）。儲冷槽同時受**能量**與**功率**約束且兩者互不蘊涵——細高槽（H=10 m、D=2.93）存得下 400 kWh_th（能量 100%），擴散器卻只放得出 480 kW（功率 **334%**）：**不是撐不到 15 分鐘，是撐 0 秒**。而 **binding 是誰取決於採哪套判準**：矮胖槽（L=17 m）在 Fr≤1.0 下 binding 是 Re（1 116 kW，143%），在 Fr≤0.5 下 binding 是 Fr（884 kW，181%）——**Fr 擋住可加大開口 h（∝ h^−1.5），Re 擋住只能加長 L（與 h 無關）**，選錯 basis 會把錢花在改不動的地方。這是 `Limit.basis`（[dc-19](devices/chilled-water-pump.md) 立的）第一次改變的是**改善動作**而不只是數字 |
| **第二個要迭代的設備** | [dc-20](devices/thermal-storage-tank.md)：[dc-18](devices/chiller.md) 迭代的是**運轉狀態**，dc-20 迭代的是**設計參數**——為了讓功率過關把開口 h 從 0.15 加到 0.22 m → 死區 1.5 → 1.64 m → `usable_fraction` 62.5% → 59% → V_geo 91.7 → 97.1 m³ → 直徑變大 → L 變長 → Fr 又鬆了。另：`usable_fraction` 是**幾何的函數**不是 0.9 這種常數（H=10 m → 85%；H=4 m → 62.5%，**同一個 400 kWh_th 需求矮胖槽要多裝 36% 的水**）。冗餘也第一次**無法靠加大單體達成**：兩倍大的槽仍是單一容器，破管／汙染／清洗停用時 ride-through 一次歸零且是隱性的 |
| **第一個需要時間軸的量** | [dc-18](devices/chiller.md)：`ride_through_s = f(loop_volume, allowed_dt, load, pumps_on_ups, restart_time)` 橫跨冰機／泵／儲槽／UPS 四類設備，而 `restart_time` 本身又是回水溫的函數（Cundall 雪梨案例：回水太熱 → 重啟後蒸發器過壓 → 二次跳脫）。**`CapacityReport` 這種穩態結構表達不了它** → 需要 `TransientScenario` |
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
