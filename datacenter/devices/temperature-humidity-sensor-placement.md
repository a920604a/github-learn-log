---
id: dc-37
title: 溫濕度感測器佈點策略（進風口代理、露點限值與讀值區間）
category: cooling
written_at: 2026-10-12
sources:
  - https://www.upsite.com/blog/data-center-temperature-sensor-location/
  - https://www.akcp.com/2026/08/04/how-many-temperature-sensors/
  - https://dataspan.com/blog/data-center-temperature-sensor-placement/
  - https://raritan.com/blog/detail/data-center-environmental-monitoring-best-practices
  - https://www.ashrae.org/file library/technical resources/bookstore/supplemental files/therm-gdlns-5th-r-e-refcard.pdf
  - https://www.techtarget.com/it-infrastructure/tip/Data-center-temperature-and-humidity-guidelines
related: [dc-36, dc-29, dc-28, dc-27, dc-15]
---

# 溫濕度感測器佈點策略（Temperature & Humidity Sensor Placement）

ASHRAE 的限值是對「**IT 設備進風口**」說的，但沒有人把感測器放進每一顆進風口：實務上放的是少數幾顆，**把它們的讀值當成「附近那些進風口」的代理（proxy）**。所以這張卡的核心不是感測器本身，而是那條代理關係：一顆感測器代表誰、在什麼條件下代表得準、讀值本身有多大的不確定。延續 [dc-36](leak-detection.md) 的主題：覆蓋是**關係**，不是地板的屬性。

## 六格

### 拓撲位置
上游（被量測的東西）：[CRAH](crah-chilled-water.md) 送風、[冷／熱通道隔離](aisle-containment.md) 後的冷通道空氣、機櫃前門後的 IT 進風口；排風側則是機櫃後方。下游：感測器 → 控制器／網路感測盒 → SNMP／Modbus／BACnet → BMS／DCIM。感測器**不在電力樹也不在冷卻樹上**，與 [dc-15 電錶](power-meter.md) 同屬「掛在位置上的觀測器」。

### 容量單位
沒有 kW。三個量：**密度**（每機櫃幾顆／每幾個機櫃一顆／每 m² 幾顆）、**高度**（top／middle／bottom，或離地 mm）、**精度**（±°C、±%RH）。密度各來源差到 48 倍（見來源分歧）。

### 冗餘表達
沒有 N+1。冗餘是「**兩顆感測器蓋同一個進風口**」；與漏水同理，壞掉的感測器不算覆蓋。Dataspan 建議關鍵與高密度區放冗餘感測器。

### 遙測介面
| 點位 | 內容 | 備註 |
|---|---|---|
| 乾球溫度 | °C，每顆感測器 | 進風側（前）與排風側（後）是**不同的量** |
| 相對濕度 | %RH | **取決於溫度**，不是獨立量 |
| 露點 | 派生值（`f(T, RH)`） | ASHRAE 建議範圍是以露點定的 |
| 通訊 | SNMP、Modbus、BACnet；許多機櫃 PDU 內建感測埠 | 協定留給 dc-41~43 |

### 故障域
一顆感測器壞＝它代理的那幾個進風口失去監看；一個感測盒掛多顆感測器時，盒子掉了＝**整排同時盲**。感測器與其供電（PoE 或 PDU）共因，見資料模型第 5 條。

### 維護特性
Dataspan：**至少每年校正**，高風險環境可半年一次，**感測器搬位置後要重新校正**。Upsite 提醒：租戶退場後空排上的感測器仍在上報高溫，曾因此誤判違反 SLA，這種感測器要移走或停用。

## 來源分歧

- **密度（最大分歧）**：Upsite 引 ASHRAE《Thermal Guidelines》**第 3 版** p.54：持續監測**每第 4 個機櫃位置**、離地約 5 ft（1524 mm）、**冷通道中央**一顆；安裝驗證則在機櫃**頂／中／底**三處進風口前約 2 in 量（p.56）。AKCP 寫「ASHRAE 建議**至少每第 3 個機櫃**」，且另寫每櫃 **6 顆**（前 3＋後 3）「符合 ASHRAE」。Raritan 寫 ASHRAE 建議「**不少於 6 顆**」，另提三點式（前下、前上、後上）。Dataspan 寫「至少每櫃 1 顆」。**四個來源，四種數字，全都沒有版本與頁碼（Upsite 除外），ASHRAE 原書（付費）未取得。** AKCP 與 Raritan 賣感測硬體，Upsite 賣氣流管理，利益方向不同。
- **誰量得準**：ASHRAE（經 Upsite 轉述）把冷通道中央當進風口的代理；Upsite 自己反駁：盲板縫、設備反裝、維護時拆隔離，代理就失準，冷通道中央與機櫃頂進風口相差最多 **25 °F（13.9 K）**，也有中央讀 85 °F 而進風其實合格的假陽性。
- **濕度範圍**：Dataspan 寫 ASHRAE「最低 20%、最高 80% RH、目標約 50%」。ASHRAE 第 5 版參考卡：建議範圍是**露點 −9～15 °C**，再加 RH 上限 **70%（或 50%，視腐蝕片條件）**；容許 A1 是 8%～80% RH。**20% 不在參考卡內**，80% 是 A1 容許上限而非建議值。
- **溫變速率**：參考卡 Table 2.1 欄位為「5/20 °C/h」，註 f（經摘要）：任何 15 分鐘內不超過 5 °C、一小時內不超過 20 °C；TechTarget 寫「5 °C **每 20 小時**」，兩者不能同時為真。**註 f 原文未直接讀到，本卡不拿它做計算。**
- **小瑕疵**：Raritan 的「20 °C／35 °F」溫差換算應為 36 °F；Dataspan 同頁溫度範圍有「64.4–80.6 °F」與「64～81 °F」兩種寫法。**台灣法規與 CNS 對應未查證。**

## 關鍵數字與計算

**一、露點（Magnus 近似，常數 b = 17.62、c = 243.12，我用的是 Sonntag 版本）**：`γ = ln(RH/100) + b·T/(c+T)`；`DP = c·γ / (b − γ)`。

- 24 °C、60% RH：`γ = −0.5108 + 17.62×24/267.12 = 1.0723`；`DP = 243.12×1.0723 / (17.62−1.0723) =` **15.75 °C**。
- 結果：溫度 24 °C 在 18～27 內、RH 60% 也 ≤ 70%，**但露點 15.75 超過建議上限 15 °C**。這就是 [dc-27](rdhx-and-dlc.md) 那個「24 °C / 60% RH」案例窗口為空的前提。
- 22 °C、45% RH → **9.52 °C**，三個限值都在內。

**二、同一個露點限值，RH 不是常數**：`RH = 100·exp(b·DP/(c+DP) − b·T/(c+T))`。DP = 15 °C：在 27 °C 對應 **47.8%**，24 °C 對應 **57.2%**。於是「RH ≤ 60% 就好」在 27 °C 時已經超限；在 18 °C、DP = −9 °C 的下限對應 **15.1%**——這就是為什麼 Dataspan 的「20% 下限」比 ASHRAE 的建議下限更嚴（見分歧）。**告警規則該寫在露點上，RH 只當輔助。**

**三、讀值是區間，不是點**：假設（**非來源數字**）溫度 ±0.5 °C、RH ±5%RH。24 °C／60% 的露點下界 `dew_point(23.5, 55) = 13.94`、上界 `dew_point(24.5, 65) = 17.49`，**區間 [13.94, 17.49] 橫跨 15 °C 限值**——三態：IN／OUT／**UNCERTAIN**。22 °C／45% 區間 [7.32, 11.55] 全在內；24 °C／75% 區間 [17.71, 20.82] 全在外。**一個 `value > limit` 的布林式告警，在 UNCERTAIN 時一半是對的。**

**四、同一排用不同密度要幾顆？**（情境為**我假設**：10 排、每排 20 櫃，冷通道 5 條，每條服務兩排）

| 策略 | 公式 | 顆數 |
|---|---|---|
| ASHRAE 持續監測（經 Upsite）每第 4 櫃，每冷通道 | `5 × ⌈20/4⌉` | **25** |
| AKCP 每第 3 櫃、每排 1 個高度 | `10 × ⌈20/3⌉` | **70** |
| AKCP 每第 3 櫃、三個高度 | `70 × 3` | **210** |
| Upsite／ASHRAE 安裝驗證，每櫃 3 顆 | `10×20×3` | **600** |
| AKCP／Raritan 每櫃 6 顆 | `10×20×6` | **1,200** |

最大／最小 = 1200 ÷ 25 = **48 倍**。這不是矛盾，是**問題不同**：25 顆回答「整間有沒有大問題」，600 顆回答「每個機櫃的進風口是否合規」。

**五、代理失準的量級**：冷通道中央讀 18 °C（建議下限、看起來很安全），若 Upsite 的最大差 13.9 K 發生在機櫃頂，頂部進風口 `18 + 13.9 =` **31.9 °C**——已超建議上限 27 °C 達 4.9 K，逼近 A1 容許上限 32 °C。這是**上限情境**，不是典型值，且來源只給圖，沒給出現條件。

## 常見誤解

**以為「機房溫度」是一個數字，但實際上限值是對每一顆 IT 進風口說的**。回風溫度、室溫、冷通道中央都只是進風口的**代理**，代理品質取決於氣流管理（[隔離](aisle-containment.md)、盲板、設備方向，見[氣流管理的度量](../topics/airflow-management-metrics.md)）。回風 24 °C 完全不保證任何進風口 ≤ 27 °C。

**以為「感測器越多越好」或「ASHRAE 規定每櫃三顆」，但實際上密度由要回答的問題決定，來源之間差 48 倍**。持續監測、安裝驗證、除錯定位是三種任務；且賣感測器的來源傾向多、賣氣流管理的傾向講代理失準。資料模型要存的是「這顆感測器**用來回答哪個問題**」，不是一個全域密度常數。

**以為「RH 在 20～80% 之間就合規」，但實際上建議範圍是露點 −9～15 °C 加 RH 上限，而 RH 隨溫度變**。24 °C／60% RH 在 RH 數字上沒問題，露點 15.75 °C 已超標。把 RH 當獨立量存、獨立告警，會同時產生漏報（高溫高露點）與誤報（低溫下 RH 偏高但露點很低）。

## 對資料模型的意涵

1. **感測器是「測量點」，代理關係是獨立的邊**：`SensorPoint{space, aisle, rack_pos, side: front|rear, height_mm, measures}` 與 `Proxies{sensor → [rack_inlet], basis: ashrae_every_nth|tor_row|measured, valid_when: [containment_ok, blanking_ok]}`。沿用 [dc-15](power-meter.md) 的 `MeasurementPoint` 標註，不放進電力樹。**代理有前提條件**，條件變了（維護時拆隔離）代理就降級，這是資料不是註解。
2. **第七個「缺東西」告警：`RACK_INLET_UNCOVERED`**。每個機櫃（[dc-29](rack-and-rack-unit.md)）需至少一顆**活著**的感測器在 `reach` 範圍內（`reach` 由策略決定：每第 4 櫃 → ±2 位置）；高度需求另有 `RACK_INLET_HEIGHT_UNCOVERED`。同族：`LEAK_SOURCE_UNCOVERED`（dc-36）等六個。
3. **讀值帶不確定度，判定是三態**：`Reading{value, accuracy, ts}`；`verdict ∈ {IN, OUT, UNCERTAIN}`。`UNCERTAIN` 不等於綠燈：它要產生「感測精度不足以證明合規」的低優先事件，並在 `alarm_setpoint = limit − accuracy − margin` 那一側留裕度。濕度只存 T 與 RH 原始值，**露點是派生值**（帶區間）。
4. **限值是帶來源與版本的資料，且依位置而異**：`EnvelopeLimit{class: A1..A4|H1, recommended|allowable, dp_min, dp_max, rh_max, source: Sourced(ASHRAE 5th ed 2021, refcard), version}`，`Space.env_class` 與 `Device.env_spec`（設備可覆寫：Dell 部分機型連續運轉到約 100 °F）。Dataspan：**每顆感測器的閾值依其位置與周圍變動設定**——所以 threshold 屬於 `Proxies`，不屬於感測器型號。
5. **感測器位置要版本化，搬動會重置校正**：`SensorPoint.position` 帶 `version`；`Reading.position_version` 指向當時的位置；`calibrated_at`、`calibration_interval_days = 365`（高風險 180）；`CALIBRATION_OVERDUE`；搬動 ⇒ `calibrated_at = null`。供電共因：感測盒 `powered_from` 指到 UPS／PoE 交換器（與 dc-34/35/36 的「同一條分支養四個證人」相同的 bug 來源）。
6. **空排上的感測器要能被標「不適用」**：`Proxies.rack_set = ∅` 時，告警抑制並產生 `SENSOR_ORPHANED`；對應 Upsite 的租戶退場誤報。

## 該問 facility 的問題

1. 現有感測器是放在**進風口前、冷通道中央、還是回風**？高度各是多少？有沒有人能指出每個機櫃由哪顆感測器代表？
2. 感測器的型號精度（±°C、±%RH）、最近一次校正日期、以及搬動過之後有沒有重新校正？
3. 驗收時是 3 點（頂／中／底）量過進風口，還是只放持續監測用的感測器？空排與退場租戶的感測器有沒有停用？

## 動手練習（30–40 分鐘）

**目標**：把上面的計算寫成 `sensors.py`，並做出第七個「缺東西」告警與三態判定。沿用慣例：不重寫 `core.py`，有 `Finding` 就匯入，沒有就用 `(code, subject)` 元組。接在 [dc-36](leak-detection.md) 的 `leak_findings` 後面，同一個 `findings` 清單。

```python
# sensors.py（約 70 行；骨架）
def dew_point(t_c, rh)                   # Magnus，b=17.62 c=243.12
def rh_from_dp(t_c, dp_c)
def dp_interval(t_c, rh, t_acc=.5, rh_acc=5.)   # (lo, hi)，lo 用 T-acc/RH-acc，hi 用 T+acc/RH+acc
def verdict(t_c, rh, ...)                # IN | OUT | UNCERTAIN；限值 T 18~27、DP -9~15、RH<=70
def count_fourth_rack(aisles, racks_per_row, every=4)
def count_every_third_row(rows, racks_per_row, heights=1)
def count_per_rack(rows, racks_per_row, per_rack)
def worst_inlet(center_c, recirc_k=13.9)
@dataclass Sensor: id, aisle, pos, height_mm, live=True
@dataclass Rack:   id, aisle, pos
def uncovered(racks, sensors, reach=2, need_heights=())
    # 同冷通道、|pos差|<=reach、live 的感測器才算；需要高度時 |h差|<=300 mm
```

### 驗收表（已用參考實作跑過）

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | `dew_point(24,60)`；`dew_point(22,45)` | **15.75**；**9.52** |
| 2 | `rh_from_dp(27,15)`；`(24,15)`；`(18,-9)` | **47.8**；**57.2**；**15.1** |
| 3 | `dp_interval(24,60)` | **(13.94, 17.49)** |
| 4 | `verdict(22,45)`；`(24,60)`；`(24,75)`；`(16,40)` | **IN**；**UNCERTAIN**；**OUT**；**OUT** |
| 5 | `dew_point(27,50)`（比較 RH 數字與露點） | **15.69**（RH 只有 50%，但已超 15 °C） |
| 6 | `count_fourth_rack(5,20)`；`count_every_third_row(10,20)`；`(10,20,3)` | **25**；**70**；**210** |
| 7 | `count_per_rack(10,20,3)`；`(10,20,6)` | **600**；**1200**（比 25 = 48 倍） |
| 8 | `worst_inlet(18)` | **31.9** |
| 9 | 資料集：A1 通道 20 櫃（pos 1~20）；感測器 pos 4／8／12／16／20，高度皆 1500 mm，**16 號 live=False**；`uncovered(racks, sensors)` | 四項：`r1`、`r15`、`r16`、`r17`（**壞掉的 16 號不算覆蓋**） |
| 10 | 同資料集 `need_heights=(300,1500,1900)` | 共 **36** 項（4 項無感測 ＋ 16 櫃 × 缺 300 與 1900 兩個高度） |

**加分題**：加上 `Reading.position_version`，寫 `stale_after_move(reading, sensor)`：讀值的位置版本不等於感測器現行版本時，回傳 `CALIBRATION_OVERDUE`。

## 自我檢核

**Q1. 24 °C、60% RH、感測器 ±0.5 °C／±5%RH，是否合規（建議範圍）？**

??? note "答案"
    不能判定。露點點估計 15.75 °C 已超過 15 °C，但區間 [13.94, 17.49] 橫跨限值，判定為 UNCERTAIN；若要證明合規，需要更準的感測器或把設定值往下調。

**Q2. 為什麼同一個「RH ≤ 60%」規則，在 27 °C 與 18 °C 的結果不同？**

??? note "答案"
    因為建議範圍以露點為準：DP = 15 °C 在 27 °C 只對應 47.8% RH，24 °C 對應 57.2%。RH 規則在高溫時會漏報。告警該寫在派生的露點上。

**Q3. 要把「每櫃進風口有人看著」做成可查詢的事實，資料模型要長出什麼欄位與約束？**

??? note "答案"
    `SensorPoint{aisle, rack_pos, side, height_mm, position_version, calibrated_at, accuracy}`、`Proxies{sensor → racks, basis, valid_when, threshold}`、`EnvelopeLimit{class, dp/rh/T 範圍, source, version}`。約束：每櫃至少一顆活著的感測器在 reach 內（`RACK_INLET_UNCOVERED`）、搬動即重置校正、判定三態而非布林、露點為派生值。

---

**下一張**：`dc-38` BMS 樓宇管理系統
