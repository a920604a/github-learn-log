---
id: dc-17
title: 冷卻水塔（cooling tower）
category: cooling
written_at: 2026-09-03
sources:
  - https://spxcooling.com/wp-content/uploads/AE-AS-24-1.pdf
  - https://herinc.ca/understanding-cooling-tower-performance-factors-ratings-and-design-considerations/
  - https://h2ocooling.com/cooling-tower-design-parameters/
  - https://www.idc-online.com/control2/Cooling_Tower_Efficiency_Calculations.pdf
  - https://agiwater.com/wp-content/uploads/Cooling_Tower_Cycles_of_Concentration.pdf
  - https://thermairsystems.com/wp-content/uploads/2011/10/ASHRAE-Systems-and-Equipment-Cooling-Towers.pdf
  - https://getchemready.com/water-facts/what-is-ashrae-188-and-why-is-it-important/
  - https://www.superlab.com.tw/pneumophila-1/
related: [dc-15, dc-16, dc-18, dc-20, dc-21, dc-38, topic-10]
---

# 冷卻水塔（cooling tower）

屋頂上那幾格會冒白煙的東西。把冰機冷凝器帶出來的溫水灑下來、風扇把空氣抽過去，靠**蒸發掉一小部分水**把熱丟給大氣。整條熱鏈的終點——對應電力鏈的 [市電進線](utility-feed.md)：一個是能量入口，一個是出口。

第二輪第一張卡，一來就打破前 16 張建立的三個習慣。

## 六格

### 拓撲位置
上游：冰機冷凝器（`dc-18`）的溫水，或 free cooling 的板式熱交換器（`dc-21`）；補水來自市水／中水。下游：**大氣**與廢水。同時它是**電力樹的葉負載**（風扇、泵、盆加熱器由機械盤／[RPP](rpp-remote-power-panel.md) 供電）——第一個同時掛兩棵樹的設備。

### 容量單位
名目冷卻水塔噸（15 000 Btu/h）或 kW 排熱，**但單獨一個數字沒有意義**——必須綁條件。CTI 標準條件：95/85 °F @ 78 °F WB、range 10 °F、approach 7 °F、3 GPM/噸。

### 冗餘表達
以 **cell（格）** 為單位，N+1 是多一格。但 2N 要看**集水盆是否共用**——共用盆是共同祖先，[dc-10b](sts-two-source-relationship.md) 的 common-ancestor 測試在熱側原封不動成立。風扇 VFD、齒輪箱仍各自是單點。

### 遙測介面
BACnet/IP 或 Modbus TCP 上 BMS（`dc-38`）。

| 點位 | 為什麼要 |
|---|---|
| 冷水出水溫 / 熱水進水溫 | 算 range 與實際 approach |
| 站點濕球（或乾球＋RH 推導） | **容量的自變數**，見下 |
| 風扇轉速 % / 風扇 kW | 剩餘出力餘裕；同時是電力側負載 |
| 盆水位 / 補水累計流量 | 斷水 ride-through、WUE 分母 |
| 導電度 / 排污閥 / 加藥泵 | COC 控制迴路的受控變數 |
| 振動開關 / 盆加熱器狀態 | 保護跳脫與防凍 |

### 故障域
一格掉 → 剩餘格 approach 惡化 → 冷卻水溫爬升 → 冰機 lift 上升、容量下降，過高則高壓跳脫。**不是瞬斷，是溫度慢慢爬**——電是毫秒，這裡是分鐘到小時。`dc-20` 儲冷槽就是花錢把這段時間買長。

### 維護特性
排空清洗＋消毒、fill 更換、齒輪箱換油、drift eliminator 檢查。**清洗必須把該格停機排空**，所以 concurrent maintainability 要求 N+1 **且**單格可隔離。

## 關鍵數字與計算

以下用一座台灣機房當例子：IT 負載 **1 600 kW**，冰機 0.55 kW/ton。

### 1. 水塔要排的熱不等於 IT 負載

```
冰機蒸發器負載 = 1 600 kW = 1 600 / 3.517 = 455 RT
壓縮機功 = 455 × 0.55 = 250 kW
水塔排熱 = 1 600 + 250 = 1 850 kW
```

而「名目冷卻水塔噸」＝ 15 000 Btu/h ＝ 12 000（冷凍噸）＋ 3 000（壓縮機熱）。那 3 000 Btu/h 換算回去是 **0.879 kW/ton**——一台 1970 年代的冰機。現代機 0.55，所以照慣例「455 噸冰機配 455 名目噸水塔」實際上給了你

```
455 × 4.396 kW = 2 000 kW  vs  實需 1 850 kW  →  約 8% 的隱性餘裕
```

**但 free cooling 模式下沒有壓縮機熱**，同一台水塔只需排 1 600 kW——噸數的語意在兩個模式下根本不同。這就是為什麼 `capacity` 必須帶 `mode`。

### 2. 容量隨濕球走——這是整張卡最重要的數字

濕球是蒸發冷卻的**絕對地板**，水塔永遠到不了。設計點取台灣夏季濕球 28 °C、冷水出水設定 32 °C：

```
approach = 32 − 28 = 4 K
range    = 37 − 32 = 5 K
效率 = range / (range + approach) = 5/9 = 55.6%
```

冷水設定溫度不變時，可用的傳熱推力正比於 approach。做一階線性近似：

| 濕球 | approach | 容量係數 | 4 格 × 650 kW 可排 |
|---|---|---|---|
| 28 °C（設計） | 4.0 K | 1.00 | 2 600 kW |
| 29 °C | 3.0 K | 0.75 | 1 950 kW |
| 30 °C | 2.0 K | 0.50 | **1 300 kW** |
| 31 °C | 1.0 K | 0.25 | 650 kW |

**濕球升 2 °C，容量掉一半。** 一格設備都沒壞。實需 1 850 kW 在 30 °C 那列就已經不夠了。

!!! warning "這張表是一階近似，不是規格"
    真實水塔用廠商性能曲線（cold water temp vs 濕球 vs 水量），不是線性。h2ocooling 明說「manufacturers publish tower performance curves for each model and flow rate」。**線性近似只用來理解方向與量級，不可以拿去做設計或驗收。** 資料模型要留 `Method.curve` 這條路，等拿到曲線就換掉。

實務上操作員不會硬撐 32 °C，而是讓冷水溫浮到 34 °C 把 approach 換回來——代價轉嫁給冰機：lift 上升、容量下降、kW/ton 上升，再高就高壓跳脫。**真正的約束不在水塔，在下游冰機**。這條線留給 `dc-18`。

### 3. 水量：蒸發、排污與補水

```
水量 m = Q / (Cp × ΔT) = 1 850 / (4.186 × 5) = 88.4 kg/s ≈ 5 300 L/min
蒸發 E ≈ Q / h_fg = 1 850 / 2 440 = 0.758 kg/s ≈ 45.5 L/min
```

用經驗法則交叉驗證（循環量的 1% 每 10 °F range；range 5 K = 9 °F）：

```
E = 5 300 × 1% × 0.9 = 47.7 L/min   ← 與物理算法差 5%，可接受
```

COC = 3（SPX：C = (E+D+B)/(D+B)，drift 忽略）：

```
排污 B = E / (COC − 1) = 47.7 / 2 = 23.9 L/min
補水 C = E + B = 71.6 L/min = 103 m³/day
```

把 COC 拉到 6：`B = 47.7/5 = 9.5`，補水降到 **57.2 L/min（−20%）**——但結垢風險上升，要更強的水處理。所以 COC 是控制設定值不是設備屬性。

年用水（假設全年設計條件）103 × 365 = **37 600 m³**，對上 IT 年耗電 14 016 MWh：

```
WUE = 37 600 000 L / 14 016 000 kWh = 2.68 L/kWh
```

業界常見值約 1.8 L/kWh，這裡偏高——正因為假設了全年設計濕球，帶出下面第一條分歧。

## 來源分歧

!!! warning "分歧一：蒸發量到底跟不跟濕球走？"
    - **h2ocooling / idc-online 等**：「蒸發量 ≈ 循環量的 1% 每 10 °F range」。式子裡**沒有濕球**。
    - **SPX 應用工程文件 AE-AS-24**：明寫用設計濕球算全年用水會高估、不具代表性，並附 Figure 1（40–90 °F 濕球的用水量曲線）。

    兩套都在流通，差別直接落在 WUE 報表與補水管徑上。→ **`water_estimate` 必須記 `method` 與 `assumed_env`**，兩個模型的數字不可以混在同一張表比較。

!!! warning "分歧二：清洗與檢驗頻率（地區差異，不是誰對誰錯）"
    - **美規口徑**（ASHRAE 188 水管理計畫 ＋ 各州法規）：常見要求為每 90 天培養檢驗、每週水質分析、每月檢查清洗。
    - **台灣業界指引口徑**（疾管署方向）：每年至少檢測一次、高風險區半年一次；**每季或每半年**排水去污、清洗消毒。

    頻率差一個數量級。**不要把美規排程硬編進工單系統。** 沿用 [dc-09c](lib-fire-compliance.md)：`MaintenanceRule` 要帶 `jurisdiction` ＋ `source` ＋ `version`。

**未查證**：台北 ASHRAE 0.4% 設計濕球的權威數字（本卡用 28 °C 當佔位，**不要直接引用**）；台灣有無冷卻水塔強制登記／稽查制度。

## 常見誤解

**以為銘牌噸數就是它能排的熱，但實際上那個數字綁死在一組條件上。** 95/85/78 °F 換成台灣的濕球就是另一個數字，而且是連續變的。把它存成 `capacity_kw` 這一個欄位，你就永久失去了它為什麼是這個值的資訊。

**以為水塔像冰機一樣有目標溫度可以設定，但實際上它的出水溫是「濕球 ＋ approach」。** 濕球是天氣給的，不是你設的。你能調的只有風扇轉速，而風扇轉到滿之後就沒了——**容量會在沒有任何設備故障的情況下不足**，這是前 16 張卡的模型完全表達不了的狀況。

**以為水塔只在冷卻那棵樹上，跟電力模型無關，但實際上它的風扇與泵是電力樹的葉負載。** A 側停電可能同時掉掉幾格風扇：**電力側的故障域會投影成冷卻側的容量損失**。兩張表若互不知道，這件事就沒有人看得到。

## 對資料模型的意涵

1. **容量從純量變成連續函數。** [dc-16](dual-corded-equipment.md) 讓容量多了離散的 `scenario`（3 個值）；水塔多的是**連續的環境自變數**：`capacity(wet_bulb, cold_water_setpoint, mode)`。`Dimension` 不能是 `limit: float`，要是 `limit(env) -> float`，且 `CapacityReport` 必須記 `evaluated_at_env`——**沒有環境條件的容量報表是不可複現的**。`Method` 因此新增 `curve`（廠商曲線查表／內插），與 `nameplate` / `measured` / `vector_sum` 並列。

2. **銘牌必須綁 rating condition。** 存 `rated_kw` 是錯的，要 `RatingPoint(wet_bulb_c, range_k, approach_k, flow_m3h, standard)`。這是繼 [dc-12](rpp-remote-power-panel.md) 的 `derating_basis`、[dc-15](power-meter.md) 的 `accuracy` 之後**第三個「不能是列舉、要能指向來源」的欄位**——而且這次連數字本身都得跟著條件走。

3. **第一個同時是兩棵樹節點的設備。** W35 收斂的「兩棵樹橫向邊」在這裡第一次有真實流量：`ThermalNode.power_loads: list[device_id]`。更重要的是**方向**——電力側的 `scenario`（`lose_a`）要能傳播成熱側的容量損失，所以 [dc-13](busway-and-tap-off-box.md) 立、[dc-16](dual-corded-equipment.md) 參數化的 `prefix_sum(edge, scenario)` 需要一個熱側對偶。

4. **濕球是站點級外生變數，不是設備遙測點。** 它同時被水塔、冰機、free cooling 切換判斷、CRAH 除濕四個地方消費。掛在某台水塔底下當 `MeasurementPoint` 是錯的——它屬於 `SiteEnvironment` 時間序列。這是繼 [dc-15](power-meter.md)「拓撲 vs 標註」之後的**第三類**：站點級外生變數。而且它常是推導值（乾球＋RH 算出來），要記 `derived_from`，RH 感測器失效時走 [dc-15](power-meter.md) 那條降級路徑。

5. **水是第二種要做容量會計的資源，這是對既有 code 最大的一刀。** 前 16 張全在算電。水有自己一整套維度：補水管流量上限、盆存量（斷水 ride-through）、排污的廢水許可上限、COC 設定值。所以 `Dimension` 要新增 `resource` 與 `unit`，而 **`binding()` 跨資源比大小沒有意義**（kW 不能跟 L/min 比）→ `binding()` 必須改成 per-resource 回傳。這一改會動到 dc-11 之後每一個實作者。

## 該問 facility 的問題

1. **「設計濕球用的是哪個數字、哪一年的氣象資料、哪個百分位（0.4% / 1% / 2%）？站址有沒有做過熱氣再循環修正？」** 這一問決定我表裡那個 28 °C 是真的還是我瞎猜的。
2. **「水塔的廠商性能曲線拿得到嗎？」** 拿不到我就只能存一個銘牌數字，而那個數字一年裡大概只有幾小時是對的。
3. **「補水從哪來？斷水時盆內存量撐幾分鐘？有沒有備援水源或儲水槽？排污有沒有排放許可的水量／水質上限？」** 這三問一起決定水的容量維度長什麼樣。

## 動手練習（40 分鐘）

繼續長同一份 code（[dc-16](dual-corded-equipment.md) 那份），**不要開新檔**。今天要做的是讓它第一次能表達「電以外的資源」與「隨環境變的容量」。

```python
from dataclasses import dataclass
from datetime import datetime
from typing import Literal, Callable

Resource = Literal["power_kw", "water_lpm", "thermal_kw"]
Mode = Literal["mechanical", "free_cooling"]

@dataclass(frozen=True)
class RatingPoint:
    wet_bulb_c: float
    range_k: float
    approach_k: float
    flow_m3h: float
    heat_rejection_kw: float
    standard: str                # 例 "CTI ATC-105"

@dataclass(frozen=True)
class SiteEnvironment:
    wet_bulb_c: float
    observed_at: datetime
    derived_from: Literal["measured_wb", "db_rh"] 
    valid: bool                  # RH 感測器失效時 False

@dataclass
class CoolingTowerCell:
    id: str
    rating: RatingPoint
    power_loads: list[str]       # 風扇／泵的 device_id（電力樹上的葉）
    in_service: bool

    def capacity_kw(self, env: SiteEnvironment,
                    cold_water_c: float, mode: Mode) -> "Bound":
        """一階近似：係數 = (cold_water_c - env.wet_bulb_c) / rating.approach_k，
        夾在 [0, 1.15]。env.valid 為 False 時退回設計濕球（保守端）並標降級。
        拿到廠商曲線後改走 Method.curve。"""
        ...
```

要實作的五件事：

1. **`Dimension` 加 `resource` 與 `unit`**，`binding()` 改成回傳 `dict[Resource, Dimension]`。跨資源比大小要在型別層擋掉。
2. **`capacity_kw()` 的一階近似 ＋ `Method.curve` 的掛勾**，回傳 [dc-15](power-meter.md) 的 `Bound` 值物件而不是點值。
3. **`env.valid == False` 的降級**：退回設計濕球，吐 `ENV_STALE` 的 `Finding`。
4. **水的維度**：`makeup_lpm(coc)` 實作 `E = flow × 1% × range_f/10`、`B = E/(COC−1)`、`C = E+B`，並比對補水管上限。
5. **電熱交叉**：`lose_a` 情境下把 `power_loads` 掉電的格子標 `in_service=False`，再算熱側容量。

**驗收表**（4 格 × 650 kW @ WB 28 °C / 冷水 32 °C，實需 1 850 kW，補水管上限 100 L/min）：

| 案例 | 期望 |
|---|---|
| WB 28 °C、4 格 | 2 600 kW，用率 71.2%，綠燈 |
| WB 28 °C、1 格保養 | 1 950 kW，用率 94.9%，綠燈但幾乎沒餘裕 |
| **WB 30 °C、4 格全在跑** | **1 300 kW，用率 142%，紅燈** — 零設備故障仍不足 |
| WB 30 °C ＋ 1 格保養 | 975 kW，用率 190% |
| `binding()` 同時看電與水 | 回傳兩筆：`thermal_kw` 142%、`water_lpm` 71.6/100 = 71.6%，**不可以只回一個最壞值** |
| `env.valid=False` | 退回 28 °C 計算，且 `Finding(code="ENV_STALE")` |

加分題：把 `mode="free_cooling"` 接上——排熱需求降到 1 600 kW，但冷水設定要從 32 °C 降到 15 °C 才餵得動板式熱交換器，於是 approach 在夏天直接變負值（不可能）。**寫出這個 `ValueError` 或 `Finding`，你就把「什麼時候能用免費冷卻」這條判斷式建進模型裡了。**

## 自我檢核

**Q1. 為什麼「這台水塔的容量是 650 kW」這句話是錯的？補齊它需要哪些資訊？**

??? note "答案"
    缺一組條件。至少要有設計濕球、冷水出水溫（或 approach）、range、循環水量，以及量測標準（CTI ATC-105 之類）。同一台水塔在 WB 28 °C 時 650 kW，在 WB 30 °C 而冷水設定不變時只剩約 325 kW。

**Q2. 濕球溫度這件事會讓你的資料模型長出什麼欄位？它該掛在哪一層？**

??? note "答案"
    長出 `SiteEnvironment` 這個**站點級**的時間序列，帶 `wet_bulb_c` / `observed_at` / `derived_from`（`measured_wb` 或 `db_rh`）/ `valid`。不能掛在水塔底下當 `MeasurementPoint`——它同時被水塔、冰機、free cooling 判斷、CRAH 除濕消費，掛在單一設備下會被複製四份且互相不一致。連帶：`Dimension.limit` 從 `float` 變成 `limit(env)`，`CapacityReport` 必須記 `evaluated_at_env` 才可複現。

**Q3. N+1 的四格水塔，一格排空清洗。你的容量報表要在哪一組條件下算才算數？**

??? note "答案"
    在**設計濕球**下算，不是在今天的濕球下算。涼天停一格看起來毫無壓力（容量係數高），但保養窗口若拖到熱天，同樣的三格會不足。所以維護排程的可行性判斷要吃 `RatingPoint.wet_bulb_c` 這個最壞條件，而不是即時遙測值——**這是「即時監控」與「容量規劃」第一次需要不同的輸入**。

## 相關概念

- `dc-18` 冰水主機 — 真正的約束在它身上（冷卻水溫爬高 → lift 上升 → 跳脫）
- `dc-20` 儲冷槽（熱慣量與 ride-through）、`dc-21` 板式熱交換器（free cooling 判斷式）
- `dc-38` BMS，與 [電力監測](power-meter.md) 的分工
- 法規版本化的既有做法：[鋰電消防合規](lib-fire-compliance.md)
