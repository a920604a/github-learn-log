---
id: dc-38
title: BMS 樓宇管理系統（三層控制、點位所有權與「沒有人看的設備」）
category: systems
written_at: 2026-10-13
sources:
  - https://www.techtarget.com/it-infrastructure/tip/Know-your-data-center-monitoring-system
  - https://datacenterfrontier.com/benefits-of-integrating-bms-and-epms
  - https://www.siemens.com/en-us/industries/data-centers/bms-epms-integration
  - https://bacnet.org/wp-content/uploads/sites/4/2022/06/20837Gollnick.pdf
  - https://open-exam-prep.com/study-guides/aee-cem/controls-automation-ai/8-1-bas-architecture-protocols
  - https://www.wbdg.org/FFC/DOD/UFGS/UFGS 23 09 23.02.pdf
related: [dc-37, dc-36, dc-34, dc-15, dc-39, dc-40, dc-41, dc-42]
---

# BMS 樓宇管理系統（Building Management System）

前面三十七張卡各談「某個東西」，這張談**把它們串起來的那套軟硬體**：BMS 是機房「灰空間」（機電設施）的控制與監看系統，冰水機、CRAH、泵、閥、感測器的**值從哪裡來、設定值寫到哪裡去、誰在迴圈裡真正做控制**，都歸它。對你的 infra 管理系統，BMS 是**最大的資料來源，也是最容易被誤當成「已經有人在看」的假證人**。延續 [dc-37](temperature-humidity-sensor-placement.md)、[dc-36](leak-detection.md) 的母題：沉默的失效。

## 六格

### 拓撲位置
上游（被控制的東西）：[冰水機](chiller.md)、[CRAH](crah-chilled-water.md)、[冷卻塔](cooling-tower.md)、[泵](chilled-water-pump.md)、閥、風機，以及它們身上的感測器（[溫濕度](temperature-humidity-sensor-placement.md)、[漏水](leak-detection.md)）。下游：操作員工作站、告警通知、趨勢資料庫，以及（若整合）EPMS／DCIM。三層結構：**管理層**（伺服器、資料庫、圖形介面）→ **系統層**（監督／全域控制器，轉協定、跑全域策略）→ **現場層**（DDC 控制器，直接掛設備）。**它不在電力樹也不在冷卻樹上**：是第三張圖。

### 容量單位
沒有 kW。三個量：**點位數**、**每條現場匯流排的裝置數**（UFGS 規格：MS/TP 每段不超過 32 台、Max_Master = 31；**美國軍方範本規格，非通用上限**）、**趨勢緩衝**（筆數 × 取樣間隔 ＝ 資料能撐多久）。

### 冗餘表達
沒有 N+1 的統一寫法，要逐層問。BACnet.org 案例：兩台可擴充控制器當冰水廠**備援面板**，一台掛了另一台接手。**現場控制器一台只管一組設備，通常沒有備援**，所以「設備 2N、控制器 1N」是常態：2N 的 CRAH 兩台若接同一顆控制器，拓撲獨立、控制不獨立（與 [dc-28](space-hierarchy.md) 防火區同理）。

### 遙測介面
| 層 | 協定（來源實際提到的） | 備註 |
|---|---|---|
| 管理層／系統層 | BACnet/IP（UDP/IP，乙太網路） | 案例中直接跑在大樓 LAN，與 IT 網路合併 |
| 現場層 | BACnet MS/TP（RS-485，權杖傳遞） | 菊鍊串 VAV 與現場控制器，慢而便宜 |
| 非 BACnet 設備 | Modbus RTU／TCP | 電錶、VFD、柴油引擎；監督控制器當閘道映射成 BACnet 物件 |

協定細節留給 `dc-41` / `dc-42`。**點位有類型（AI／AO／BI／BO），AO 是命令，不是量測**。

### 故障域
**一台現場控制器掛了＝它管的每一台設備失去「控制」**，不是「監看」：設備可能照最後狀態跑，也可能掉到預設位置，**UFGS 規格沒有定義 fail position**。監督控制器或伺服器掛了：具獨立運作能力的現場控制器照跑，但**趨勢、告警、排程全停**，操作員變盲。兩種失效完全不同（見計算四）。

### 維護特性
程式下載、點位重新映射、趨勢緩衝定期拉走。UFGS：時鐘斷電後走 120 小時、時間同步靠 DM-TS-B 或 DM-UTC-B。**改 setpoint 不需停機，風險在於改錯**，所以 setpoint 是「誰、何時、為什麼改」的資料。

## 來源分歧

- **BMS 管不管電**：TechTarget（2014）：BMS 對電力只看到 UPS 輸入，不足以做相位平衡。BACnet.org 案例（Gollnick）：同一套 BMS 監看 PDU、STS、發電機，還有 **54 面第三方配電盤的斷路器狀態**，並計量主電源做計費。Schneider（贊助文章）：BMS 只能做基本電力管理與能源報告，毫秒級事件屬於 EPMS。**「BMS 的範疇」是專案決定，不是標準。**
- **BMS 與 EPMS 該不該互通**：Schneider（贊助文章，推自家產品）：兩者歸不同部門、不同合規與責任，**不該自動互換資料並改彼此的設定**，只建議聚合視圖。Siemens（廠商頁）：合併在同一平台、「single pane of glass」並關聯分析。BACnet.org 案例：全部接上同一條 BACnet 網路。三方都有賣東西的立場，**沒有獨立第三方裁決。**
- **BMS 能不能吃資料中心的資料量**：TechTarget（2014）：BMS 會被設備資料量淹沒，要由 DCIM 把數千點濃縮後只送重大告警上來。BACnet.org 案例的 BMS 接了近 300 台現場控制器。**差異在年代與點位粒度**，數字不能互比。
- **UFGS 自身矛盾**：Trend Log 的 Buffer_Size 一處寫「至少 1000」、另一處寫「400 以上」；告警優先序的數字在抽取結果中亂碼。本卡兩個值都算（計算三），不裁決。
- **未查證**：ASHRAE 135 原文、Uptime／EN 50600 對 BMS 的要求、台灣法規、COV 訂閱細節、各廠 DDC 的斷電預設位置。Siemens「30% 更快上手」無方法學，不採用。

## 關鍵數字與計算

**一、為什麼「設定值 24 °C」不等於「房間 24 °C」（P 控制的殘差）**。比例控制：`輸出% = 偏置 + Kp × 誤差`，`Kp = 100 / PB`（PB 為比例帶，誤差多大時輸出從 0 跑到 100%）。假設（**非來源數字**）CRAH 冷水閥偏置 50%、PB = 4 K → Kp = 25 %/K；房間熱負荷 70 kW、閥全開可移熱 100 kW → 穩態閥位必須是 70%。

- 閥位 70 ＝ 50 ＋ 25 × 誤差 → **誤差 = 0.8 K**，房間穩定在 **24.8 °C**。我用一階模型（C = 5000 kJ/K、dt = 1 s）模擬 6000 s，終值 24.8，與公式吻合。
- PB 縮到 2 K（Kp = 50）→ 殘差 **0.4 K**，但高增益易振盪（hunting）。
- 加積分（Ki = 0.05，我選的）：300 s 24.54、1200 s 24.08、3000 s **24.00**，殘差消失。HVAC 多為 PI。
- **代價**：同樣 60% RH，露點從 24 °C 的 15.75 變成 24.8 °C 的 **16.51 °C**（Magnus，同 dc-37 常數），離建議上限 15 °C 更遠。**一個調不好的迴圈，會把 dc-37 的 UNCERTAIN 推成 OUT。**

**二、BMS 看不見的事（取樣間隔 vs 現象長度）**。Schneider：EPMS 要抓持續「幾毫秒」的電力品質事件，BMS 一般記不到那麼快。若 BMS 趨勢是 15 分鐘（UFGS 預設值）、事件 5 ms：`900 s ÷ 0.005 s =` **180,000 倍**。要穩定觀測到一個長度 d 的現象，取樣間隔需 ≤ d/2（我的推論）。不是「BMS 比較慢」，是**這類事件在 BMS 資料裡根本不存在**。

**三、趨勢緩衝撐多久**（UFGS：15 分鐘間隔、Buffer_Size ≥ 1000、90% 時通知）。

| Buffer | 間隔 | 全滿 | 90% 通知點 |
|---|---|---|---|
| 1000 | 15 分 | 250 h = **10.4 天** | 225 h = **9.4 天** |
| 400（矛盾的另一條） | 15 分 | 100 h = **4.2 天** | 90 h = **3.75 天** |
| 1000 | 1 分 | **16.7 h** | 15 h |

週末無人拉資料，在 400 筆設定下就會掉資料。**緩衝＝`筆數 × 間隔`，決定上游多久必須取一次。**

**四、一個節點掛了，誰受影響（blast radius）**。以練習的小樹：伺服器 S1 → 全域 G1、G2 → 現場 F1、F2（掛 G1）、F3（掛 G2，**無獨立運作能力**）。CRAH1→F1、CRAH2→F2、冰水機與泵→F3、CRAH3 沒有控制器。

| 失效節點 | CRAH1 | CRAH2 | 冰水機／泵 | CRAH3 |
|---|---|---|---|---|
| 無 | 受控 | 受控 | 受控 | **未被監控** |
| G1 | **獨立運作**（操作員盲） | 獨立運作 | 受控 | 未被監控 |
| G2 | 受控 | 受控 | **失控** | 未被監控 |
| F1 | **失控** | 受控 | 受控 | 未被監控 |
| S1 | 獨立運作 | 獨立運作 | **失控** | 未被監控 |

同一句「BMS 掛了」，結果可以是無事，也可以是冰水機失控，差在 `standalone` 一個欄位。

## 常見誤解

**以為「BMS 是更大的 DCIM，什麼都管」，但實際上 BMS 管的是機電設施的控制迴圈，粒度是設備不是機櫃**。TechTarget 列出 BMS 取樣代表性點位，會漏掉機櫃上下的熱點，也沒有庫存管理與相位平衡。把 BMS 當「有人在看機櫃進風」，是 dc-37 的代理問題換個名字。

**以為「BMS 掛了，設備跟著掛」，但實際上現場控制器是獨立運作的，掛的是「操作員的眼睛」**。open-exam-prep：現場控制器有自己的處理器與記憶體，失去監督層仍能獨立跑。更危險的反向：**監督層正常、一台現場控制器掛了，那一組設備失去控制，而畫面可能只是一個沒更新的數字**。

**以為「畫面上有值就代表有在量」，但實際上沒有時間戳與品質欄位的值，會永遠停在最後一次**。圖形畫面最容易把「最後一次的好值」顯示成綠燈。**一個值的可信度＝`value × quality × age`，不是 `value`。**

## 對資料模型的意涵

1. **第三張圖：控制依賴邊**。已有電力邊、冷卻邊，現在加 `ControlEdge{equipment → field_controller → supervisory → server}`。節點有 `tier`、`standalone: bool`、`fail_position: enum|unknown`。**`fail_position` 預設 `unknown` 而不是 `hold`**（UFGS 沒定義，這類缺漏要顯式標）。這張圖與電力樹要能一起查：控制器的電源 `powered_from` 指到哪條分支（UFGS：DDC 必須本地供電並有電源指示燈）。
2. **點位是一等物件，帶來源、類型、品質**：`Point{id, equipment, kind: AI|AO|BI|BO, native_address, protocol, owner_system, interval_s, last_ts, quality: GOOD|UNCERTAIN|BAD|STALE, units}`。**AO 是命令，只有 AO 可被「寫」**；`owner_system` 讓「同一個量被 BMS 與 EPMS 各量一次」可表達。dc-37 的 `Sensor.live: bool` 因此變成**派生值**：`live = quality==GOOD and not stale(now, last_ts, interval_s)`。
3. **第八個「缺東西」告警：`EQUIPMENT_UNMONITORED`，配對 `POINT_STALE`**。每台列管設備（[dc-28](space-hierarchy.md) 空間內有電力或冷卻邊者）至少要有一個 `ControlEdge` 與一個活著的點；缺邊＝未被監控、點過期＝名義上被監控。`stale` 條件為 `now − last_ts > k × interval_s`（k 取 2 是我的假設，不是來源數字），另加 `TREND_BUFFER_AT_RISK`（90% 滿之前須拉走）。
4. **setpoint 是命令物件，不是設備屬性**：`SetpointChange{point, old, new, written_by, written_at, priority, reason}`。UFGS：覆寫使用可命令物件，優先序 ≤ 10 會蓋過程式序列，≥ 11 不會（BACnet 優先序陣列的完整語意留給 `dc-42`）。沒有這張表，「24 °C 設定、24.8 °C 實際」的稽核答不出是誰改的。
5. **可觀測性是約束**：`interval_s ≤ min_duration_s / 2`，違反回報 `PHENOMENON_UNOBSERVABLE`。15 分鐘趨勢掛上「電力品質事件」的需求，應在建模時被擋下，而非事故後才發現。
6. **系統範疇是資料**：`Scope{system, equipment_class, role: control|monitor|alarm_source}`，同一台 UPS 可被 BMS、EPMS、DCIM 各登記一次；否則答不出「這台設備幾個系統在看」。

## 該問 facility 的問題

1. 每台 CRAH、冰水機、泵掛在哪一台現場控制器？控制器失去監督層時，**這顆控制器會獨立運作，還是掉到預設位置**？預設位置是什麼？
2. 現場匯流排上最後一次有人拉走趨勢資料是什麼時候？緩衝筆數與取樣間隔各是多少？
3. 有沒有「圖形畫面上有值，但實際已經沒更新」的點？BMS 能不能匯出每點的 `last_update` 與品質旗標？

## 動手練習（30–40 分鐘）

**目標**：寫 `bms.py`，把「控制依賴圖」「點位新鮮度」「P／PI 殘差」三件事實作出來，並**回頭改 dc-37 的覆蓋計算**，讓 `live` 從手填變成派生值。沿用慣例：不重寫 `core.py`，有 `Finding` 就匯入，沒有就用 `(code, subject)` 元組，接在 [dc-37](temperature-humidity-sensor-placement.md) 的 `uncovered` 後面，同一個 `findings` 清單。

```python
# bms.py（約 80 行；骨架）
@dataclass Node:  id, tier: "server|supervisory|field", parent=None, standalone=True
@dataclass Equip: id, controller: str | None
@dataclass Point: id, equip, kind, interval_s, last_ts

def state(eq, nodes, failed) -> str
    # controller 為 None -> UNMONITORED
    # controller 自己在 failed -> UNCONTROLLED
    # 任一祖先在 failed -> controller.standalone ? STANDALONE : UNCONTROLLED
    # 否則 CONTROLLED
def blast(nodes, equips, failed) -> dict[eq_id, state]
def stale(now, last_ts, interval_s, k=2) -> bool     # now - last_ts > k*interval_s（嚴格大於）
def p_droop(kp, load_kw, qmax_kw, bias=50) -> float  # (load/qmax*100 - bias)/kp
def simulate(kp, ki=0, sp=24, load=70, qmax=100, C=5000, bias=50, n=6000)  # dt=1s 的 Euler
def buffer_hours(size, interval_min); def notify_hours(size, interval_min, pct=.9)
def observable(interval_s, event_s) -> bool           # interval_s <= event_s / 2
def live_sensors(points, now)                         # 餵給 dc-37 的 uncovered()
```

### 驗收表（已用參考實作跑過）

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | `p_droop(100/4, 70, 100)`；`p_droop(100/2, 70, 100)` | **0.8**；**0.4** |
| 2 | `simulate(25)` 終值（T, 閥位） | **24.8 °C，70.0%** |
| 3 | `simulate(25, ki=0.05)` 於 300／1200／3000 s 的溫度 | **24.54／24.08／24.00** |
| 4 | `dew_point(24.8, 60)` 與 `dew_point(24, 60)` | **16.51**；**15.75** |
| 5 | `buffer_hours(1000,15)`；`buffer_hours(400,15)`；`buffer_hours(1000,1)` | **250.0**；**100.0**；**16.7** |
| 6 | `notify_hours(1000,15)`（換算天） | **9.375 天** |
| 7 | `observable(900, 0.005)`；`observable(0.001, 0.005)` | **False**；**True**（900 ÷ 0.005 = 180,000 倍） |
| 8 | 小樹（見計算四）`blast(failed={"G1"})` | CRAH1、CRAH2＝**STANDALONE**；冰水機、泵＝CONTROLLED；CRAH3＝**UNMONITORED** |
| 9 | `blast(failed={"G2"})`；`blast(failed={"F1"})` | 冰水機與泵＝**UNCONTROLLED**；僅 CRAH1＝**UNCONTROLLED** |
| 10 | `stale(1000, 900, 60)`；`(1000, 870, 60)`；`(1000, 880, 60)` | **False**（差 100）；**True**（差 130）；**False**（差 120，嚴格大於） |
| 11 | dc-37 資料集：感測器 pos 4／8／12／16／20，**不再手填 live**，改由 `last_ts` 推（now = 10000、間隔 60 s、16 號 last_ts = 9700，其餘 ≥ 9950） | `uncovered` 仍為 **r1、r15、r16、r17** |
| 12 | 同資料集，全部感測器掛在同一台已失效的 F2 | 全 **20** 櫃未覆蓋 |

**加分題**：加 `powered_from`，寫 `common_cause(nodes, power_tree)`：找出「控制器與它所控制的泵共用同一條配電分支」的組合（[dc-34](access-control-door-controller.md) 同一條 UPS 分支養四個證人的第四次出現）。

## 自我檢核

**Q1. 一台現場控制器失去監督層連線，它管的 CRAH 一定停止控制嗎？**

??? note "答案"
    不一定。取決於 `standalone`：現場控制器有自己的處理器與記憶體，能獨立跑時仍維持控制，但趨勢、告警、排程全部中斷，操作員變盲（STANDALONE）；不能獨立運作時才變 UNCONTROLLED。而控制器本身掛掉時，設備掉到哪個位置（`fail_position`）UFGS 沒定義，要問 facility，資料上預設 `unknown`。

**Q2. 為什麼設定值 24 °C、房間穩態卻是 24.8 °C？**

??? note "答案"
    純比例控制有殘差：誤差 = (必要閥位 − 偏置) ÷ Kp = (70 − 50) ÷ 25 = 0.8 K。加積分才能歸零。後果：同 60% RH 下露點從 15.75 升到 16.51 °C，離 15 °C 建議上限更遠，會把 dc-37 的 UNCERTAIN 推向 OUT。

**Q3. 要讓「有人在看這台設備」成為可查詢的事實，資料模型要長出什麼欄位與約束？**

??? note "答案"
    `ControlEdge{equipment → controller → ... → server, standalone, fail_position}`、`Point{kind, owner_system, interval_s, last_ts, quality}`、`Scope{system, role}`。約束：每台列管設備至少一條控制邊與一個未過期的點（`EQUIPMENT_UNMONITORED`、`POINT_STALE`）、`interval_s ≤ min_duration_s / 2`（`PHENOMENON_UNOBSERVABLE`）、`Sensor.live` 為派生值而非手填。

---

**下一張**：`dc-39` EPMS 電力監控系統（與 BMS 的分工與斷點）
