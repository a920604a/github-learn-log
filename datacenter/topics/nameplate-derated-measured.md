---
id: topic-01
title: 銘牌值 vs 降載值 vs 實測值（再加一個配額值：四種數字、兩個方向）
category: topic
written_at: 2026-10-23
sources:
  - https://www.barroso.org/publications/PowerProvisioning.pdf
  - https://www.techtarget.com/it-infrastructure/tip/Avoid-common-pitfalls-when-calculating-data-center-power-load
  - https://datacenters.lbl.gov/sites/default/files/Data%20Center%20Power%20Requirements_2001.pdf
  - https://www.intel.com/content/dam/doc/white-paper/intel-it-data-center-efficiency-server-power-paper.pdf
  - https://netboxlabs.com/docs/v4.4/netbox/models/dcim/powerport/
  - https://netboxlabs.com/docs/v4.4/netbox/models/dcim/powerfeed/
  - https://github.com/netbox-community/netbox/blob/main/netbox/dcim/models/power.py
  - https://community.se.com/t5/ITA-Capacity/Understanding-estimated-load-and-how-it-is-calculated/ta-p/447219
related: [dc-02, dc-09, dc-09c, dc-12, dc-14, dc-15, dc-16, dc-40, dc-44, topic-02, topic-04]
---

# 銘牌值 vs 降載值 vs 實測值（nameplate / derated / measured）

這三個字幾乎每張卡都出現：[dc-02](../devices/transformer.md) 立了「銘牌與可用值分開、可用值用算的」，[dc-12](../devices/rpp-remote-power-panel.md) 立了「容量查詢要回 method」，[dc-15](../devices/power-meter.md) 第一次接觸量測值。這張卡把它們收成**一個型別**，並補上前面沒說破的兩件事：**同一個字在供給側和需求側錯的方向相反**，以及真正拿來做規劃的其實是第四個數字——**配額值**。

## 定義

| 數字 | 誰給的 | 供給側（斷路器、變壓器、饋線）| 需求側（伺服器、交換器）|
|---|---|---|---|
| **銘牌 nameplate** | 廠商，在標準條件下 | 能扛的上限，**前提**是 40 °C、正弦波、列名外殼 | 會吃的上限：全配、100% 負載、**最低輸入電壓** |
| **降載 derated** | 法規或環境係數 | 銘牌 × 係數（溫度、諧波、80% 連續負載）→ **往下修是為了安全** | 工程師把銘牌打 4–6 折 → **往下修是為了不浪費，但失去保證** |
| **實測 measured** | 量測鏈 | 少見（斷路器不會告訴你它還能扛多少）| 某節點、某時窗、某統計量（峰值／95 分位）|
| **配額 allocated** | **人做的決定** | — | 實測峰值 ＋ 緩衝，或銘牌，寫進容量帳本 |

配額不在佇列標題裡，但三個獨立系統都有，且**各取一個名字**：NetBox 叫 `allocated_draw`（「the budgeted amount of power」），EcoStruxure IT 叫 *adjusted nameplate*（「the actual known peak power draw」，手動輸入，沒填就退回銘牌），Intel IT 叫 *expected peak*。**同義不同名**——[dc-25b](airflow-management-metrics.md) 遇過的病。

## 為什麼重要

### 演算一：同一個 rack PDU，四種方法放得下幾台

承 [dc-14](../devices/rack-pdu.md)：208 V delta 30 A，降載 24 A → `√3 × 208 × 24 = 8 646 VA`（**美規**，見誤解三）。伺服器取 Fan et al. 2007 §3.1 的實測：**銘牌 251 W（213 W DC ÷ 0.85 效率），實測最重 benchmark 峰值 145 W = 57.8%**。PF 假設 0.95（**我的假設**）把 W 換成 VA。

| 方法 | 每台 VA | 台數 | 依據 |
|---|---|---|---|
| 銘牌 | 251/0.95 = 264.2 | **32** | 保證不會超過 |
| 實測峰值、零緩衝 | 152.6 | 56 | Fan：rack 層級觀察峰值可達實際峰值 98–100%，**rack 層級超賣不安全** |
| 實測 ×1.20 | 183.2 | **47** | Intel IT 保留 15–20% 緩衝 |
| 實測 ×1.25 | 190.8 | 45 | NEC 220.87 的 1.25（[dc-12](../devices/rpp-remote-power-panel.md)，原用於盤，借來對照） |

**32 到 56，差 75%。** 四種方法回答四個問題；帳本只記「用了 82%」不記方法，數字沒有意義。

### 演算二：銘牌電流是在最低電壓下標的

McFarlane（TechTarget 2009）：銘牌電流是「全選配、100% 使用率、**最低工作電壓**」下的值。電源標「100–240 V~ 10–4 A」（**示意標籤**；兩端 1 000 vs 960 VA，取大者）：

| 算法 | VA | 相對正確值 |
|---|---|---|
| 正確：低壓端 100 V × 10 A | 1 000 | 1.00 |
| 美國：120 V × 90 V 時的電流（原文例） | — | **≥ 1.33**（120/90）|
| 台灣 220 V × 標籤低壓電流 10 A | 2 200 | **2.20** |
| 台灣 110 V 插座 × 10 A | 1 100 | 1.10 |

再疊上廠商把 2.4 A 進位成 3 A（+25%）：美國例 `1.333 × 1.25 = 1.67`，**高估 67%**。**電壓與電流必須來自標籤的同一列**，不能拿現場電壓乘標籤電流。

### 演算三：實測峰值不能相加

Fan 2007 表 3：叢集觀察峰值只有各機實際峰值總和的 **86.5–93.5%**（單一負載；混合 85.4%），真實機房 **71.9%**。

40 櫃，每櫃 30 天實測峰值 6 kW：峰值相加 240 kW；同時峰值 `240 × 0.719 = 172.6 kW`。拿 240 去檢查 UPS 會**多佔 67.4 kW**，正好是 Fan 說「整座機房多放約 39% 機器」的來源（240/172.6 = 1.39）。

**能相加的是時間序列，不是峰值：先 sum 再 max。** `peak(Σ) ≤ Σ peak` 恆成立，等號只在所有櫃同時尖峰時才成立。

### 演算四：NetBox 的 `available_power` 與兩個預設值陷阱

NetBox 原始碼（`dcim/models/power.py`）：

```python
kva = abs(self.voltage) * self.amperage * (self.max_utilization / 100)
self.available_power = round(kva * 1.732) if three_phase else round(kva)   # 存成欄位
```

機櫃用電率 = `Σ allocated / Σ available_power`（`racks.py`）——**分子配額、分母降載值**，實測值不進來。

| 輸入 | `available_power` |
|---|---|
| 預設值 120 V／15 A／80%（`parameters.py`） | **1 440**——美規預設，台灣不改就是錯的 |
| 台灣單相 220 V 32 A 80% | 5 632 |
| 三相 380Y/220，填**線電壓** 380 | 16 849 ✓ |
| 同上但填**相電壓** 220 | 9 755——**只有 57.9%** |

`voltage` 沒說是線電壓還是相電壓，公式默認線電壓。`available_power` 也是**存起來的衍生值**——[dc-02](../devices/transformer.md) 叫我們別做的那種。

### 來源分歧

1. **實測／銘牌比沒有通用值。** Fan 2007 伺服器 57.8%；LBNL（Mitchell-Jackson 等 2003）「多數設備尖峰也不超過 80% 額定」，引 Kunz 1997 網通設備約 **30%**、Norford 1990 個人電腦銘牌高估 **2–4 倍**；同一份 LBNL 的機房設計密度 646 W/m² vs 實測 169 W/m²（**26%**）。
2. **McFarlane「40%–60% high」本身有兩種讀法。** 「比實際高 40–60%」→ 實際 = 銘牌的 **62.5–71.4%**；同段又說工程師「reducing them by that amount」→ 實際 = 銘牌的 **40–60%**。兩種讀法差到 30 個百分點，原文沒裁決。
3. **NetBox 文件 vs 原始碼的單位。** 文件說 `maximum_draw`／`allocated_draw` 單位是 **watts**；`get_power_draw()` 的 docstring 寫「in **VA**」，而分母 `available_power` 是 V×A。PF 0.95 時兩者差 5%。
4. **緩衝取多少。** Intel 15–20%；NEC 220.87 的 25%（美規，且是給盤的既有負載用的）；EcoStruxure 的 30 天趨勢窗沒提緩衝。

**未查證**：台灣屋內線路裝置規則的連續負載與既有負載條文（`topic-02` 處理）、Fan 2007 之後的伺服器世代比值（GPU 機的實測／銘牌比可能高得多）、NetBox `maximum_draw` 在官方語意上是銘牌還是實測峰值（文件只寫 maximum）。

## 常見誤解

**以為「降載」永遠是保守的方向，但實際上供給側降載是往安全修、需求側打折是往風險修。** 斷路器 × 0.8 讓你少用；伺服器銘牌 × 0.6 讓你多放。兩者同一個字、同一個乘法，一個讓你更安全，一個讓你失去保證。schema 裡兩者必須是不同的 `side`。

**以為實測值是最「真」的所以應該取代銘牌，但實際上實測值綁著節點、時窗、統計量三個前提。** 凌晨三點的瞬時值（McFarlane 警告）、7 天的峰值（[dc-12](../devices/rpp-remote-power-panel.md) 判 `valid=False`）、各櫃峰值加總（演算三）都是「實測」，都是錯的。

**以為 NetBox 的機櫃用電率就是用了多少電，但實際上它是 Σ 配額 ÷ Σ 降載容量，沒有量測點參與。** 配額是人填的；雙電源兩個 port 各填一次就變兩倍（[dc-16](../devices/dual-corded-equipment.md) 的 NetBox 斷點）。

## 對資料模型的意涵

1. **一個 `Figure` 取代六個 `Rating`。** 目前模型裡有 [dc-05](../devices/diesel-generator.md) `Rating`、[dc-17](../devices/cooling-tower.md) `RatingPoint`、[dc-19](../devices/chilled-water-pump.md) `Limit`、[dc-26b](../devices/cdu-rating-and-filtration.md) `Rating`、[dc-20](../devices/thermal-storage-tank.md) `Limit`、[dc-14](../devices/rack-pdu.md) `input_nameplate_a`／`input_derated_a`。共同骨架：`Figure(value, unit, kind, side, basis, source)`，`kind ∈ {NAMEPLATE, DERATED, MEASURED, ALLOCATED}`、`side ∈ {SUPPLY, DEMAND}`，兩者**必填無預設**。設備特有條件（濕球、rating class、filter）留在 `basis` 子結構。

2. **命名規則 `<kind>_<量>_<單位>`，並登記第一個實例。** [dc-09](../devices/ups-battery.md) 的 `energy_kwh()` 回 28.0（已乘 DoD 0.8），[dc-09c](../devices/lib-fire-compliance.md) 合規要 35.0（銘牌）——已知缺陷就是**缺了 kind**。用 `Figure` 寫：`nameplate_energy_kwh = Figure(35, "kWh", NAMEPLATE, SUPPLY, …)`、`derated_energy_kwh = Figure(28, "kWh", DERATED, SUPPLY, basis="DoD 0.8")`，合規函式簽名只收 `NAMEPLATE`，傳錯在型別層就擋。

3. **四種 kind 的儲存規則不同。** NAMEPLATE 存；DERATED **不存**，由 NAMEPLATE × 係數算（[dc-02](../devices/transformer.md)）；MEASURED 存成 `(node_id, window, statistic, point_ids)`，**不可相加**（型別不給 `__add__`，加總只能走時間序列）；ALLOCATED 是決定，存 `(value, basis_figure, buffer_pct, decided_by, decided_at)`。

4. **用電率必須寫出分子與分母的 kind。** `Utilization(num_kind, den_kind)`：NetBox 是 `ALLOCATED/DERATED`。同一櫃 `ALLOCATED/DERATED = 85%`、`MEASURED/DERATED = 50%`，差的 35 個百分點就是 `topic-04` 的擱置容量——**擱置容量不是一個欄位，是兩個 kind 的差**。

5. **四條告警**：`ALLOCATION_BELOW_MEASURED`（配額 < 有效時窗實測峰值，帳本在說謊，CRITICAL）；`MEASURED_ABOVE_NAMEPLATE`（需求側實測 > 銘牌，**資料品質**告警：機型登錯、CT 比錯，不是容量問題）；`ALLOCATION_UNBASED`（配額既不等於銘牌、也沒有 `basis_figure`）；`FEED_VOLTAGE_REF_UNKNOWN`（三相饋線沒標線／相電壓）。

## 該問的問題

1. **容量帳本（DCIM／NetBox）裡每台伺服器的功率是哪一種數字？** 銘牌、打折銘牌、還是實測？打折的話打幾折、誰定的？
2. **配額的緩衝是多少，量測時窗多長，用峰值還是 95 分位？** 答不出來就是 `ALLOCATION_UNBASED`。
3. **三相饋線在系統裡填的是 380 還是 220？**

## 動手練習（40 分鐘）

新檔 `figures.py`，接 dc-42 的 `core.Result`／`Reason` 與 `points.Point`（實測值的來源是 `Point`，`quality != GOOD` 的樣本不算）。

```python
class Kind(Enum): NAMEPLATE; DERATED; MEASURED; ALLOCATED
class Side(Enum): SUPPLY; DEMAND
@dataclass(frozen=True) Figure: value, unit, kind, side, basis="", source=""
def to_va(f, pf)                                   # W→VA，unit 不是 W/VA 就 raise
def fit(capacity: Figure, per_unit: Figure) -> int  # capacity 必須 SUPPLY+DERATED，否則 raise
def allocate(measured: Figure, buffer_pct) -> Figure  # buffer_pct <= 0 → raise（Fan：rack 層級不可超賣）
def label_va(v_lo, v_hi, a_at_lo, a_at_hi) -> Figure  # 同一列相乘，回兩端較大者
def nb_available_power(v, a, max_util, three_phase, v_ref)  # v_ref ∈ {"LL","LN"}，LN 先 ×√3；None → raise
def coincident(series: dict[str, list[float]]) -> (sum_of_peaks, peak_of_sum)
def measured_peak(samples, window_days, min_days=30) -> Result | Figure  # 不足 → UNDETERMINED(MISSING_INPUT)
def check(asset, nameplate, allocated, measured) -> list[(code, id)]
```

### 驗收表

| # | 呼叫 | 期望 |
|---|---|---|
| 1 | `to_va(Figure(251,"W",NAMEPLATE,DEMAND), 0.95)` | 264.2 VA |
| 2 | `fit(Figure(8646.4,"VA",DERATED,SUPPLY), 上一列)` | **32** |
| 3 | `fit` 傳 `NAMEPLATE` 的 capacity | raise |
| 4 | `allocate(Figure(145,"W",MEASURED,DEMAND), 20)` → `to_va` → `fit` | 174.0 W、**47** 台；25% → 45 台 |
| 5 | `allocate(…, 0)` | raise |
| 6 | `label_va(100,240,10,4)` | 1 000 VA；**不是** 2 200 |
| 7 | `nb_available_power(380,32,80,True,"LL")` | 16 849 |
| 8 | `nb_available_power(220,32,80,True,"LN")` | 16 896；`v_ref=None` → raise |
| 9 | `coincident({"A":[6,3,3,4],"B":[3,6,3,4],"C":[3,3,6,4]})` | (18, 12)，比值 0.667 |
| 10 | `Figure(MEASURED) + Figure(MEASURED)` | TypeError |
| 11 | `measured_peak(…, window_days=7)` | `Result(UNDETERMINED, MISSING_INPUT)`，**不得退回銘牌** |
| 12 | `check`：配額 150 W、實測 160 W | `ALLOCATION_BELOW_MEASURED` |
| 13 | `check`：實測 300 W、銘牌 251 W | `MEASURED_ABOVE_NAMEPLATE`，且**不得**同時吐容量類告警 |

**加分題**：把 dc-09 的 `energy_kwh()` 改成兩個 `Figure`，寫一個只收 `NAMEPLATE` 的 `fire_compliance_kwh()`，傳 28.0 那個要 raise。

## 自我檢核

**Q1. 同事說「這櫃 NetBox 顯示 85%，滿了」。你要先問哪兩件事？**

??? note "答案"
    (1) **分子是什麼**：NetBox 用電率是 Σ `allocated_draw` ÷ Σ `available_power`，配額是人填的，可能是銘牌、打折銘牌或實測加緩衝；雙電源兩個 port 都填就重複計算（dc-16）。(2) **分母怎麼來**：`available_power = V × A × max_utilization`，有沒有沿用 120 V／15 A 預設、三相填的是線電壓還是相電壓（填 220 只得 57.9%）。實測值根本不在這個比例裡。

**Q2. 40 櫃各自 30 天峰值都是 6 kW，UPS 要檢查的負載是多少？**

??? note "答案"
    不是 240 kW。峰值不可相加，要把 40 條時間序列先加總再取峰值。Fan 2007 的真實機房同時峰值只有峰值總和的 71.9%（≈172.6 kW）。沒有時間序列就只能保守用 240，但要標 `basis="sum_of_peaks"`，不能假裝那是實測。

**Q3. 這張卡會讓你的資料模型長出什麼欄位、刪掉什麼欄位？**

??? note "答案"
    **長出**：`Figure.kind`（四態）與 `Figure.side`（兩態），兩者必填；MEASURED 的 `(node_id, window, statistic)`；ALLOCATED 的 `(basis_figure, buffer_pct, decided_by, decided_at)`；`Utilization(num_kind, den_kind)`；`PowerFeed.voltage_ref ∈ {LL, LN}`。**刪掉**：所有存起來的降載值（`input_derated_a` 之類改成由銘牌與係數算），以及六個各自定義的 `Rating`／`Limit`／`RatingPoint`，收斂成 `Figure` ＋ 各自的 `basis` 子結構。
