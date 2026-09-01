---
track: datacenter
updated: 2026-08-28
---

# 學習佇列

> 每日排程從**最上面未完成的一項**取一項，產出一張卡，然後把它標成完成。
> 這是 syllabus-driven，不是 crawl-driven —— **佇列決定學什麼，不是當天爬到什麼決定學什麼。**

## 規則

- 每個工作日消耗 **1 項**（週六日不跑，週日產週報）
- 完成後把 `[ ]` 改成 `[x]` 並補上日期與卡片連結
- 卡片寫在 `devices/<slug>.md` 或 `topics/<slug>.md`
- 若某項在寫的過程中發現需要拆成兩張，就地插入新項目到佇列
- **順序可以改**：若你在公司剛好碰到某個設備（例如下週要看 UPS 測試），把它拉到最前面

## 第一輪：電力鏈（對應 roadmap 階段 2）

依實際電力流向排序，從上游往下游走。

- [x] `dc-01` 市電進線與受電設施（utility feed / 責任分界點） — 2026-07-28 [卡片](devices/utility-feed.md)
- [x] `dc-02` 變壓器（transformer） — 2026-07-29 [卡片](devices/transformer.md)
- [x] `dc-03` 中壓開關設備（MV switchgear）— 額定與保護 — 2026-07-30 [卡片](devices/mv-switchgear.md)
- [x] `dc-03b` LSC 服務連續性分級與抽出式斷路器互鎖 — 2026-07-31 [卡片](devices/lsc-and-interlocks.md)
- [x] `dc-04` 自動切換開關 ATS（automatic transfer switch） — 2026-08-03 [卡片](devices/ats-transfer-switch.md)
- [x] `dc-05` 柴油發電機（diesel generator）— 額定、降載與容量 — 2026-08-04 [卡片](devices/diesel-generator.md)
- [x] `dc-05b` 發電機起動時序與暫態性能（ISO 8528-5） — 2026-08-05 [卡片](devices/genset-start-and-transient.md)
- [x] `dc-05c` NFPA 110 定期測試制度、30% 門檻與 wet stacking — 2026-08-07 [卡片](devices/nfpa110-testing-and-wet-stacking.md)
      <!-- 2026-08-07 一併修正 dc-04 卡片「每年 4 小時 ≥30% 銘牌負載測試」的混淆說法 -->
- [x] `dc-06` 日用油箱與儲油槽（day tank / bulk fuel） — 2026-08-10 [卡片](devices/day-tank-and-bulk-fuel.md)
- [x] `dc-07` 低壓主配電盤 — 額定電流體系（InA / Inc / Ing / RDF） — 2026-08-11 [卡片](devices/lv-switchgear.md)
- [x] `dc-07b` 低壓盤的短路耐受與保護協調（Icw / Ipk、選擇性協調、ZSI、arc flash 與 ERMS） — 2026-08-12 [卡片](devices/lv-short-circuit-and-coordination.md)
      <!-- 2026-08-11 從 dc-07 拆出：原稿 14238 字元，超過 10000 上限。額定語意與短路/保護是兩個主題 -->
- [x] `dc-08` UPS 不斷電系統（雙轉換式） — 2026-08-13 [卡片](devices/ups-double-conversion.md)
- [x] `dc-09` UPS 電池組（鉛酸 VRLA vs 鋰電 LiB）— 額定、runtime 與壽命 — 2026-08-14 [卡片](devices/ups-battery.md)
- [x] `dc-09b` 電池測試制度（IEEE 1188 內阻／容量門檻、commissioning baseline、測試窗口） — 2026-08-17 [卡片](devices/battery-testing-regime.md)
      <!-- 2026-08-14 從 dc-09 拆出：原稿 11929 字元，超過 10000 上限。電氣特性與測試/合規制度是兩個主題 -->
- [x] `dc-09c` 鋰電消防合規（NFPA 855 能量閘門與間距、UL 9540A 四層測試、off-gas 偵測與爆炸控制、台灣消防署指引與 CNS 對應） — 2026-08-18 [卡片](devices/lib-fire-compliance.md)
      <!-- 2026-08-17 從 dc-09b 再拆出：合併稿 11546 字元超過上限，且動手練習（內阻判定＋容量狀態機＋防火區約束）超過 40 分鐘預算。
           測試制度是「時間軸上的鏈」，消防合規是「與電力樹正交的空間樹」，資料模型需求不同 -->
      <!-- 2026-08-18 來源分歧：NFPA 855 2023 版有 50/250/600 kWh 能量表，2026 版把該表移除、改成 HMA 預設。
           兩版並存（IFC 2024 仍引 2023 版文字），卡片裡明寫並要求 CodeRule 版本化 -->
- [x] `dc-10` 靜態切換開關 STS（static transfer switch）— 設備本體、SCR 與故障狀態機 — 2026-08-20 [卡片](devices/static-transfer-switch.md)
- [x] `dc-10b` STS 的兩源關係（一）：拓撲獨立性（common ancestor）與雙母線容量會計（枚舉配置取 max） — 2026-08-24 [卡片](devices/sts-two-source-relationship.md)
      <!-- 2026-08-20 從 dc-10 拆出：原稿 14075 字元，遠超 10000 上限。
           「一台 STS 內部怎麼運作」與「兩個源之間的關係」是兩個主題，資料模型需求也不同：
           前者是單一實體的狀態機，後者需要 PowerEdge 有身分 + DeviceRegistry 全圖查詢。
           dc-10b 的動手練習就是 W33 連貫性檢視 #3 欠了四週的 DeviceRegistry。 -->
- [x] `dc-10c` STS 的兩源關係（二）：相位同步窗與頻率漂移 — 2026-08-27 [卡片](devices/sts-source-synchronization.md)
      <!-- 2026-08-27 就地補入：dc-10b 把「相位同步窗」拆給 dc-10c，但佇列裡一直沒有這個項目，
           造成 dc-10b 卡片內文指向一張不存在的卡。本日補寫並歸位。
           同時裁決了 dc-11 標記的重複卡問題：刪除 sts-dual-source-relationship.md
           （2026-08-25，12901 字元、超過 10000 上限，且與 dc-10b + dc-10c 內容重疊），
           保留佇列所連的 sts-two-source-relationship.md。 -->
- [x] `dc-11` PDU 配電單元（含變壓器型 / 非變壓器型） — 2026-08-27 [卡片](devices/pdu-floor.md)
      <!-- 2026-08-27 dc-11 立下的命名規約（要回頭套用到 dc-09）：
           打過折的量一律 `_derated` 後綴，未打折一律 `_nameplate`，不准有無後綴版本 -->
      <!-- 2026-08-27 dc-11 初稿 10504 字元，靠壓縮六格與贅語收到 9998，未拆卡、未刪內容。
           但「諧波／K 係數／中性線定額」與「接地與 separately derived system」兩塊只點到未展開，
           若之後覺得不夠，這兩塊就是最自然的兩張補充卡 -->
- [x] `dc-12` RPP 遠端配電盤（remote power panel） — 2026-08-28 [卡片](devices/rpp-remote-power-panel.md)
      <!-- 2026-08-28 **回頭修正 dc-11 的兩個錯**：
           (1) dc-11 把連續負載的 ×0.80 當常數用。實際上 0.80 是「80% rated 斷路器＋外殼組合」的屬性
               （NEC 210.20(A) 例外 / UL 489 §7.1.4）。IEM 的 RPP 標配就是 100% rated，不打折。
               同一顆 400 A 主開關在 380Y/220V 下是 210.6 kVA 或 263.3 kVA，差 8.7 個 6 kW 機櫃。
               → 命名規約要再補一層：`_derated` 後綴不夠，還要 `derating_basis` 說明打折的理由。
           (2) dc-11 立的「凡是算得出來的一律不存」在插拔式母線（ABB SMISSLINE）上不成立——
               多極裝置可任意插放、可帶電調相位平衡，相位是插法不是位置。
               → 不是推翻規則，是把規則的前提變成欄位：`Panelboard.phase_mode`。 -->
      <!-- 2026-08-28 來源分歧：Schneider WP61 把「非變壓器型 PDU」直接叫 RPP（同一台設備兩個名字）；
           LayerZero FAQ 明說 RPP 是 PDU 下游再一級。後果是拓撲深度不確定（2 跳 vs 3 跳），
           而 dc-10b 的 common-ancestor 計算吃的正是跳數。已列入「該問 facility 的問題」。 -->
      <!-- 2026-08-28 初稿 11230 字元，靠壓縮六格與贅語收到 9998，未拆卡、未刪任何必含段落。
           NEC 220.87（1.25 × 30 天最大需量）是美規；台灣走屋內線路裝置規則，數字尚未查證，
           卡片裡已標註。這是最自然的一張補充卡（`topic-02` 斷路器 80% 規則可以一起收）。 -->
      <!-- 2026-08-28 commit 256c610（使用者本機）把本卡的中途草稿一併 add 進去了，
           最終版本在隔一個 commit。內容以最終版為準。 -->
- [x] `dc-13` 匯流排 busway / 插接箱（tap-off box） — 2026-08-28 [卡片](devices/busway-and-tap-off-box.md)
      <!-- 2026-08-28 來源分歧（一）：廠商文案（Vertiv「hot swappable / zero downtime」、EAE「零停機」）
           vs OSHA 2025-08-25 解釋函引 NFPA 70E (2021) table 130.5(C)——插入／移除 busway 插接裝置
           不論運轉狀態都存在電弧閃絡可能，適用 29 CFR 1910.333(c)。Schneider 型錄裡自己就印了同樣警語。
           → dc-12 立的 `requires_outage_to_add_circuit: bool` 不夠用，改三態 `change_class` -->
      <!-- 2026-08-28 來源分歧（二）：固定插孔式（Schneider iBusway，10 ft 20 孔、每 11.4 in 一個）
           vs 連續槽式（Starline T5 / Vertiv iMPB open channel，任意位置插）。
           不是規格差異而是**型別分水嶺**：`free_outlets` 在連續槽式連型別都不成立 -->
      <!-- 2026-08-28 環境溫度降載係數（>40 °C 每 5 °C 降 3–5%、垂直側立 ×0.85）只查到二手來源，
           卡片裡已標「不要直接用」。要跟廠商拿降載曲線，否則 `derating_basis` 標 unknown -->
      <!-- 2026-08-28 本卡是電力鏈上第一個「順序有意義」的設備：容量約束從 dc-12 的分段和
           推廣成沿路徑的前綴和。中央饋入時左 500/右 300（總和 800 ≤ 800）仍違規 -->
      <!-- 2026-08-28 初稿 11093 字元，壓縮六格與贅語收到 9996，未拆卡、未刪必含段落 -->
- [x] `dc-14` 機櫃電源 rack PDU（basic / metered / switched） — 2026-08-31 [卡片](devices/rack-pdu.md)
      <!-- 2026-08-31 本卡是電力鏈上第一個「電流不能相加」的設備。北美 208 V delta 的線間負載，
           共用相走向量和 I = √(I₁²+I₂²+I₁I₂)：10 A + 10 A = 17.32 A，不是 20 A。
           wye（380Y/220V，台灣常見）則可直接相加 —— 兩種算法都對，錯的是不知道自己在哪一種，
           所以 `RackPdu.wiring` 是決定演算法分岔的模式欄位，不是裝飾。 -->
      <!-- 2026-08-31 **NetBox 斷點第一條具體條目**（記給 `topic-10`）：
           NetBox PowerOutlet 的 `feed_leg` 只能是單一 A|B|C，官方例子也是 wye 式的「1–16 接 A」。
           discussion #8028（2021-12）明確要求 A-B / B-C / C-A，至 v4.6.9 文件仍未實作，
           社群結論是「只能用 custom field」。delta 機櫃在 NetBox 裡表達不了 → `Outlet.legs` 要是 tuple，
           長度由 `wiring` 決定（又一個「模式欄位改變基數」）。 -->
      <!-- 2026-08-31 W35 連貫性檢視 #1 的預言兌現：dc-14 是第四種容量報表（四維：
           input_current / bank / outlet / rack_u），且 **binding 會跑**——
           30 A 機（L21-30P）binding 是進線（8646 VA），50 A 機（AP8868）binding 是 bank 斷路器（9984 VA）。
           同一份 code 兩個答案，證明 binding 必須是查詢結果不是設定值。
           動手練習就是 W35 #1 + #2（Dimension / CapacityReport / Finding）一次做完。 -->
      <!-- 2026-08-31 `derating_basis` 第三種來源：不是外殼列名（dc-12）、不是環境溫度（dc-13），
           而是**內部導體線規與斷路器數量**——同一顆 CS8365C 插頭，3 個斷路器 = 35 A、6 個 = 40 A；
           同一顆 IEC 60309 60 A，6 AWG = 45 A、4 AWG = 48 A。插頭型號推不出容量。
           更狠的是 AP7868（12.5 kW）與 AP8868（10.0 kW）**硬體完全相同、連斷路器曲線都一樣**，
           差別只在 UL 後來強制 80% 降載 → basis 不能是列舉，要能指向一份文件與版本。 -->
      <!-- 2026-08-31 未查證：台灣 CNS 對 IEC 60320 C13/C19 的額定條號（國際 10 A/16 A，
           北美 UL 常標 15 A/20 A）。卡片內已標註未查證，不要直接引用。 -->
      <!-- 2026-08-31 wc -m = 9457，未拆卡。 -->
- [x] `dc-15` 電力監測儀表與電錶（power meter / EPMS 感測點） — 2026-09-01 [卡片](devices/power-meter.md)
      <!-- 2026-09-01 **本卡是電力鏈上第一個不在電力樹上的東西。** 前 14 張建的是一棵有 parent/child 的樹，
           電錶的上下游是同一個 —— 它是掛在節點或邊上的觀測器。硬塞進樹裡的話，每插一顆錶深度就多一層，
           dc-10b 的 common-ancestor 跳數會被觀測器污染。→ 需要 `MeasurementPoint`（標註）與 `PowerEdge`（拓撲）分開。 -->
      <!-- 2026-09-01 來源分歧：**PUE 的 level／category 綁不綁量測頻率？**
           ISO/IEC 30134-2:2016 §6.1.2 明寫「本標準不規定量測頻率」，Category 1/2/3 只定義量測位置；
           The Green Grid 的 Level 1/2/3 則同時綁位置與頻率（月／日／連續 ≤15 min）。
           「做到 Level 3」在兩套定義下是一年 12 個點 vs 35040 個點，儲存與輪詢設計差一個數量級。
           → `measurement_point` 與 `sampling_interval_s` 必須拆兩欄，不能合成 `pue_level` 列舉。 -->
      <!-- 2026-09-01 `accuracy` 是第二個「不能是列舉、要能指向來源」的欄位（第一個是 dc-12 的 `derating_basis`）。
           IEC 61557-12 明文：外部感測器的 PMD 性能等級要與 IEC 61869-2 的 CT 等級合併計算。
           PMD 0.2 ＋ CT 0.5 = 最壞 0.7%（2 MW 上是 14 kW）。更狠的是 CT 等級只在額定附近成立——
           400/5 CT 掛在只跑 60 A 的迴路（15% 額定）誤差比銘牌差，而新機房頭一年正好都在低負載。 -->
      <!-- 2026-09-01 `Dimension.valid`（dc-14 定義但一直沒用上）今天有用途了：錶失聯時實測維度不是 0 是 stale，
           要退回 nameplate 法並吐降級 Finding。回報 0 的系統會宣告機櫃是空的。 -->
      <!-- 2026-09-01 未查證：台電需量計費用的是 fixed block 還是 rolling、區間多長。
           卡片裡以 Schneider PowerLogic 預設（fixed block 15 min）做演算並標註為廠商預設值，不是台灣法規值。
           這一問已列入「該問 facility 的問題」。 -->
      <!-- 2026-09-01 初稿 10970 字元，壓縮六格與贅語收到 9994，未拆卡、未刪任何必含段落。 -->
      <!-- 2026-09-01 dc-16（設備端雙電源）正好接得上：dc-14 Q3 的答案裡欠的
           「每個 PSU 的兩路各接在哪個 bank」就是明天的題目。 -->
- [ ] `dc-16` 設備端雙電源與單電源（dual-corded / single-corded + ATS PDU）

## 第二輪：冷卻鏈（對應 roadmap 階段 3）

- [ ] `dc-17` 冷卻水塔（cooling tower）
- [ ] `dc-18` 冰水主機（chiller，氣冷 vs 水冷）
- [ ] `dc-19` 一次側／二次側冰水泵（primary / secondary pump）
- [ ] `dc-20` 儲冷槽（thermal storage tank）與 ride-through
- [ ] `dc-21` 板式熱交換器與免費冷卻（plate HX / free cooling）
- [ ] `dc-22` CRAH 機房空調（冰水式）
- [ ] `dc-23` CRAC 精密空調（直膨式）
- [ ] `dc-24` 加濕與除濕（humidification / dehumidification）
- [ ] `dc-25` 冷熱通道封閉（containment）與氣流管理
- [ ] `dc-26` 液冷 CDU（coolant distribution unit）
- [ ] `dc-27` 後門熱交換器 RDHx 與直接晶片液冷 DLC

## 第三輪：空間、消防、安全（對應 roadmap 階段 1 補完）

- [ ] `dc-28` 站點／建築／樓層／機房區的空間層級
- [ ] `dc-29` 機櫃與 U 位（rack / rack unit / 盲板）
- [ ] `dc-30` 高架地板與線槽走線架
- [ ] `dc-31` 配線架與結構化布線（patch panel / structured cabling）
- [ ] `dc-32` 極早期偵煙 VESDA
- [ ] `dc-33` 氣體滅火系統與消防警報盤
- [ ] `dc-34` 門禁控制器、讀卡機、人員通道閘
- [ ] `dc-35` CCTV 與影像保存
- [ ] `dc-36` 漏水偵測（leak detection）
- [ ] `dc-37` 溫濕度感測器佈點策略

## 第四輪：系統與協定（對應 roadmap 階段 4）

- [ ] `dc-38` BMS 樓宇管理系統
- [ ] `dc-39` EPMS 電力監控系統（與 BMS 的分工與斷點）
- [ ] `dc-40` DCIM 的範疇與市場現況
- [ ] `dc-41` Modbus RTU / TCP 基礎與暫存器位址
- [ ] `dc-42` BACnet 物件模型與 MS/TP vs IP
- [ ] `dc-43` SNMP 與 MIB（UPS / rack PDU 常見 OID）
- [ ] `dc-44` Redfish / IPMI 伺服器帶外管理
- [ ] `dc-45` 閘道器與協定轉換（protocol gateway）

## 第五輪：主題卡（非設備，對應 roadmap 階段 4–5）

- [ ] `topic-01` 銘牌值 vs 降載值 vs 實測值
- [ ] `topic-02` 斷路器 80% 連續負載規則
- [ ] `topic-03` N / N+1 / 2N / 2N+1 的精確定義與差異
- [ ] `topic-04` 擱置容量 stranded capacity 的四種型態
- [ ] `topic-05` Tier I–IV 定義與 concurrent maintainability
- [ ] `topic-06` 故障域 fault domain 的建模方式
- [ ] `topic-07` PUE 定義、量測點、常見造假手法
- [ ] `topic-08` ASHRAE TC 9.9 熱環境 class 與告警門檻設計
- [ ] `topic-09` NetBox 電力模型逐欄位拆解（PowerPanel → PowerFeed → Rack → Device）
- [ ] `topic-10` NetBox 模型的斷點：上游 UPS/發電機該怎麼自己補
- [ ] `topic-11` 設施告警 vs 軟體 SLO：為什麼 error budget 不能照搬
- [ ] `topic-12` 四大黃金訊號在設施場景的對應物
- [ ] `topic-13` MOP / SOP / EOP 與變更窗口
- [ ] `topic-14` 工單與 CMMS 資料模型
- [ ] `topic-15` 事件分級與升級路徑
- [ ] `topic-16` Commissioning Level 1–5 各測什麼

---

## 進度

- 總項目：69（2026-07-30 從 dc-03 拆出 dc-03b；2026-08-04 從 dc-05 拆出 dc-05b；2026-08-05 從 dc-05b 再拆出 dc-05c；2026-08-11 從 dc-07 拆出 dc-07b；2026-08-14 從 dc-09 拆出 dc-09b；2026-08-17 從 dc-09b 再拆出 dc-09c；2026-08-20 從 dc-10 拆出 dc-10b；2026-08-27 從 dc-10b 再拆出 dc-10c）
- 已完成：23（2026-09-01 dc-15）
- 預估完成：每週 5 項 → 約 13 週跑完第一到第四輪，加主題卡約 15–16 週（深度優先，慢一點沒關係）

> 完成第一輪（電力鏈 16 項）時應該回頭做一次檢查：
> **拿你們公司的單線圖，逐段對照你寫過的卡片，看有沒有哪一段是圖上有、但你的佇列裡沒有的設備。** 有的話就地補進佇列。
