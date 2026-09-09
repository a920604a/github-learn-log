---
id: dc-19b
title: NPSH 與泵的擺放高度（吸入條件與汽蝕）
category: cooling
written_at: 2026-09-09
sources:
  - https://www.pumps.org/2025/03/18/understanding-the-2024-updates-to-ansi-hi-9-6-1-rotodynamic-pumps-guideline-for-npsh-margin/
  - https://jmpcoblog.com/hvac-blog/cooling-tower-suction-piping-guidelines
  - https://blog.ansi.org/ansi/ansi-hi-96-1-2017-rotodynamic-pumps-npsh/
  - https://www.xylem.com/siteassets/brand/goulds-water-technology/resources/guideline/d200a05---minimum-submergence---3.25.2021-pdf.pdf
  - https://insights.globalspec.com/article/12400/minimizing-pump-cavitation-what-is-the-ideal-nsph-margin
related: [dc-17, dc-18, dc-19, dc-20]
---

# NPSH 與泵的擺放高度（NPSH and pump placement）

泵能不能把水推出去，看的是揚程；泵會不會把自己啃壞，看的是**吸入端還剩多少壓力**。水在泵入口被葉輪甩開的瞬間壓力會掉到全系統最低點，一旦低於當下水溫的飽和蒸氣壓，水就在管內沸騰、氣泡進到高壓區再爆掉——汽蝕。這張卡處理的不是泵的型號，而是**它被放在幾樓**。

## 六格

### 拓撲位置
不是新設備，是 [dc-19](chilled-water-pump.md) 那些泵的**安裝條件**。上游：開放迴路是 [冷卻水塔](cooling-tower.md) 冷水盤（自由液面）；密閉迴路是膨脹水箱定壓點。下游：[冰機](chiller.md) 冷凝器／蒸發器。

### 容量單位
公尺水柱（m）。四個量：`NPSHa`（系統給的）、`NPSHr`（泵要的）、`margin = NPSHa − NPSHr`、以及吸入淹沒深度 `S`（m，獨立判準）。

### 冗餘表達
**NPSH 不能靠加台數解決**——並聯反而讓共用吸入母管流速上升、`h_f` 變大，每台的 NPSHa 一起變差。備援泵放同一個吸入坑就是共同故障點。

### 遙測介面
| 點位 | 型別 | 備註 |
|---|---|---|
| `suction_pressure` | float, kPa **g**（可負） | 必須是 compound gauge |
| `basin_level` / `tank_fill_pressure` | float | 決定 Z 與定壓 |
| `water_temp` | float, °C | 決定 Pv |
| `pump_flow` | float | `h_f` 與 `NPSHr` 都是它的函數 |

### 故障域
汽蝕不會馬上停機，會先掉揚程、出現碎石聲與振動，數月內吃掉葉輪與機封。真正的急性故障是**失去灌注**（suction lift 配置液位掉下去）→ 泵空轉 → 冷卻鏈整條斷。

### 維護特性
擺放高度是**開工前的決定**，事後只能加大吸入管、降流量、換低 NPSHr 的泵——三者都是幾公尺等級的補救，補不回一層樓。

## 關鍵數字與計算

$$\mathrm{NPSHa} = \frac{P_{atm}}{\rho g} + Z_{static} - h_f - \frac{P_v}{\rho g}$$

常數（台北、海平面、冷卻水 32 °C，ρ≈995）：$P_{atm}/\rho g = 10.38$ m，$P_v/\rho g = 0.49$ m。

### 演算一：同一顆泵、兩個擺放高度

`NPSHr(r) = 6.0 r²`（r = Q/Q設計，簡化擬合，實務要拿廠商曲線）；`h_f ∝ r²`（[dc-19](chilled-water-pump.md) 的系統阻力）；margin 判準 `max(1.0 m, 0.1×NPSHr)`。

| | Z_static | h_f(r=1) | NPSHa(r) | r=1 時 NPSHa | margin |
|---|---|---|---|---|---|
| **A 泵在地面層** | +18.0 m | 3.0 m | 27.89 − 3.0r² | **24.89 m** | 18.9 m |
| **B 泵在屋頂與塔並排** | −1.2 m | 1.5 m | 8.58 − 1.5r² | **7.08 m** | 1.08 m |

（B 用 [dc-18](chiller.md) 解出的擾動水溫 35.8 °C：$P_v/\rho g = 0.61$ m、$P_{atm}/\rho g = 10.39$ m。）

**最大可運轉流量 = NPSHa(r) 與 NPSHr(r)+margin 的交點**：

- B：`8.58 − 1.5r² ≥ 6r² + 1.0` → `7.58 ≥ 7.5r²` → **r ≤ 1.005**
- A：高流量下 `0.1×NPSHr` 反超 1.0 m，判準換分支 → `27.89 − 3r² ≥ 6.6r²` → **r ≤ 1.704**

**同一顆泵、同一個系統，只是擺放高度不同，最大流量從 100.5% 變成 170.4%。** B 在 r=1.1 時 NPSHa 6.77 < NPSHr 7.26——**負 margin，直接汽蝕**。而 dc-19 的系統曲線交點根本不在這裡。

### 演算二：吸入淹沒深度（ANSI/HI 9.8）

$$S = D\,(1 + 2.3\,\mathrm{Fr}),\qquad \mathrm{Fr} = \frac{v}{\sqrt{gD}}$$

喇叭口 D = 0.35 m、v = 1.5 m/s → Fr = 0.810 → **S = 1.00 m**。冷水盤有效水深常只有 0.3–0.5 m ⇒ **必須做集水坑或獨立吸水槽**，「接在盤底」不成立。

加大喇叭口只買到一點點：D = 0.45 → v = 0.91、Fr = 0.432 → S = 0.90 m（−10 cm）。**Fr 擋住主要只能拉水位**——同 [dc-20](thermal-storage-tank.md) 的 basis 決定改善動作。

**適用域**：該關聯式只在 v > 0.61 m/s（2 fps）成立。VFD 降到 41% 流量以下，這條約束不是「滿足」，是**不適用**。

### 演算三：為什麼 [dc-19](chilled-water-pump.md) 整張卡沒提 NPSH

密閉冰水迴路，7 °C（$P_v/\rho g$ = 0.10 m），膨脹水箱接**吸入側**、定壓 200 kPa g：

NPSHa = (200 + 101.3)/9.81 − 0.10 = **30.6 m**。高程沿迴路互相抵消，怎麼算都過。

唯一會出事的方式是**接錯邊**：水箱接在出口側時，泵自己的揚程從吸入壓力裡**減掉**。定壓 50 kPa g（5.1 m）、揚程 30 m → 吸入絕對水頭 10.33 + 5.1 − 30 = **−14.6 m**，物理上不可能，水在泵入口就閃蒸。定壓值也不是誰挑的：迴路最高點高 18 m ⇒ 至少 18 + 0.1 + 3 ≈ **207 kPa g**。

## 常見誤解

**以為 NPSHr 是「低於它才會汽蝕」的門檻，但實際上 NPSHr 就是 NPSH3——揚程已經被汽蝕拉掉 3% 的那一點。** 真正無汽蝕的 NPSHi 是它的數倍（見來源分歧）。NPSHa 剛好等於 NPSHr 不是勉強及格，是已經在啃葉輪。

**以為水溫是 NPSHa 的主角，但實際上在冷卻水的 32 → 35.8 °C 區間蒸氣壓只值 0.12 m。** 吃掉 NPSHa 的是高程（±18 m）與隨 Q² 走的吸入摩擦。溫度要到 90 °C 才變主角（$P_v/\rho g$ = 7.40 m）。

**以為 NPSH 是選型問題，換一顆 NPSHr 小的就好，但實際上它是土建問題。** 配置 B 把 NPSHr 從 6.0 壓到 4.5 也只把上限推到 1.12；把泵從屋頂搬到地面直接變 1.70。而搬泵的機會只有一次。

## 對資料模型的意涵

1. **`Device.elevation_m` ＋ `datum_ref` 是必要欄位——前 20 張卡沒有一張需要知道設備在幾樓。** 拓撲回答「誰接誰」，NPSH 是**幾何**：同一張單線圖、同一份型錄，搬層樓答案就翻倍。第三輪的空間層級（`dc-28`）被提前需要了，而且要定義基準（泵中心線？底座？）與冷水盤的**運轉水位**（不是溢流水位）。
2. **`Limit.basis = "npsh_crossover"` 且 `solved=True`：`max_flow` 是解出來的，不是查出來的。** NPSHa(Q) 遞減、NPSHr(Q) 遞增，交點才是上限；它同時依賴 elevation、`h_f`、水溫，所以 [dc-17](cooling-tower.md) 的 `limit(env)` 與 [dc-19](chilled-water-pump.md) 的 `Limit.basis` 在這裡第一次疊在同一個維度上。**而 margin 判準本身會換分支**（1.0 m vs 0.1×NPSHr），basis 要記到判準層級。
3. **`Constraint` 必須三態，不能是布林。** HI 9.8 淹沒公式在 v < 0.61 m/s 不適用 → `satisfied / violated / not_applicable`。`Dimension.valid`（dc-14 定義、[dc-15](power-meter.md) 首次用於錶失聯）第一次因為**公式的適用域**而失效——感測器好好的，是模型不成立。壓成布林會在 VFD 低速時回報綠燈。
4. **`MeasurementPoint.range_min` 要存，且量程表達不了時要吐 `SENSOR_CANNOT_REPRESENT`。** 吸入端裝普通壓力錶，負壓時讀 **0**——BMS 收到的是「正常」。這是 dc-15「錶失聯是 stale 不是 0」的孿生錯誤：**這次錶是好的，是量程說不出危險。**
5. **`expansion_tank_connection_point` 是拓撲欄位，它決定泵自身揚程在算式裡的正負號。** 同一組設備、同一組數字，接管位置一換，NPSHa 從 30.6 m 變成負值。

## 該問 facility 的問題

1. 冷卻水泵中心線標高、與冷水盤**運轉水位**標高各是多少？兩者差就是 Z_static，這個數字不在任何型錄裡。
2. 吸入端是普通壓力錶還是 compound gauge？量程下限多少？（決定 BMS 看不看得見負壓）
3. 冰水側膨脹水箱接吸入側還是出口側？補水定壓幾 kPa？迴路最高點標高？

## 動手練習（30–40 分鐘）

接昨天 [dc-20](thermal-storage-tank.md) 的 `Dimension`，加上高程與求解型上限。

```python
from dataclasses import dataclass
from enum import Enum

class Check(Enum):          # 意涵 #3：三態，不是 bool
    SATISFIED = "satisfied"; VIOLATED = "violated"; NOT_APPLICABLE = "not_applicable"

@dataclass
class SuctionGeometry:
    pump_elev_m: float          # 意涵 #1
    source_level_m: float       # 冷水盤運轉水位
    datum_ref: str              # "pump_centerline" | "base_plate"
    hf_design_m: float
    bell_dia_m: float
    design_velocity_ms: float

def npsh_available(g: SuctionGeometry, r: float, water_c: float) -> float:
    atm, pv = 10.38, vapor_head_m(water_c)     # 自己查表，32→0.49、35.8→0.61
    return atm + (g.source_level_m - g.pump_elev_m) - g.hf_design_m * r**2 - pv

def npsh_required(r: float) -> float: return 6.0 * r**2
def margin_required(nr: float) -> float: return max(1.0, 0.1 * nr)   # 判準會換分支

def solve_max_flow_ratio(g, water_c, lo=0.2, hi=3.0, tol=1e-4) -> float:
    ...  # 二分搜尋 npsh_available − npsh_required − margin_required = 0

def submergence_check(g: SuctionGeometry, r: float) -> tuple[Check, float]:
    v = g.design_velocity_ms * r
    if v < 0.61: return Check.NOT_APPLICABLE, float("nan")   # HI 9.8 適用域
    ...  # S = D(1 + 2.3 * v / sqrt(9.81*D))
```

**驗收表**（跑出這幾個數字才算做完）：

| 案例 | 期望值 |
|---|---|
| A 配置 r=1、32 °C | NPSHa ≈ 24.89 m |
| B 配置 r=1、35.8 °C | NPSHa ≈ 7.08 m |
| B 配置 r=1.1 | margin ≈ −0.50 m（VIOLATED）|
| `solve_max_flow_ratio` A / B | ≈ 1.704 / 1.005 |
| `submergence_check` r=1 | SATISFIED 判準值 S ≈ 1.00 m |
| `submergence_check` r=0.4 | **NOT_APPLICABLE**（不是 SATISFIED）|

**加分**：把 B 配置的 `CapacityReport` 印出來，確認 `binding` 的 basis 是 `npsh_crossover` 而不是 dc-19 的 `system_curve`。

## 自我檢核

**Q1. 一顆 NPSHr = 6.0 m 的泵，算出 NPSHa = 6.5 m。過關嗎？**

??? note "答案"
    不過。margin 只有 0.5 m，判準 `max(1.0 m, 0.1×6.0)` = 1.0 m，需要 NPSHa ≥ 7.0 m。而且 NPSHr 就是 NPSH3——那是**已經掉 3% 揚程**的點，不是安全邊界。高 suction energy 的冷卻水泵在 HI 的建議裡還要更寬。

**Q2. 這件事會讓資料模型長出什麼欄位？**

??? note "答案"
    五個：(a) `Device.elevation_m` ＋ `datum_ref`——第一次需要空間座標；(b) `Limit.basis="npsh_crossover"` ＋ `solved=True`，`max_flow` 是兩條曲線的交點；(c) `Constraint` 三態 `satisfied/violated/not_applicable`，因為 HI 9.8 有適用域；(d) `MeasurementPoint.range_min`，普通壓力錶在負壓讀 0；(e) `expansion_tank_connection_point`，決定泵揚程在算式裡的符號。

**Q3. 為什麼 [dc-19](chilled-water-pump.md) 整張卡都沒提 NPSH，這張卻說它是冷卻水泵的頭號約束？**

??? note "答案"
    密閉迴路的高程沿環路抵消，NPSHa 由定壓值決定：200 kPa g、7 °C 水 → 30.6 m，怎麼配都過。開放迴路的自由液面沒有這個保護，NPSHa 直接等於「水面比泵高多少」減掉摩擦，屋頂並排配置只剩 7.08 m。**密閉迴路唯一的 NPSH 事故是膨脹水箱接錯邊**，而那是接管拓撲的錯，不是設備的錯。

## 來源分歧

**（一）margin 判準是比值還是絕對值。** HI 的 NPSHA Margin 工作組給的是**比值**：NPSHA/NPSHR 從 1 到 5，依 suction energy（吸入口徑 × 轉速 × 吸入比速）分級；業界廣泛流傳的則是「**3.3 ft（1.0 m）或 1.1 倍取大者**」這個絕對值／比值混合式。兩者在低 NPSHr 的泵上差很多：NPSHr = 2 m 時 1.1× 只要 2.2 m，絕對值判準要 3.0 m。→ 這就是為什麼 `Limit.basis` 要記到判準層級。

**（二）NPSHi 是 NPSH3 的幾倍。** 一說 4–6 倍、吸入設計良好的葉輪 2–3 倍；一說 3–5 倍；也有實例是 19 ft → 107 ft（5.6 倍）。**共識是 NPSH3 不等於無汽蝕，分歧只在倍數**，而要完全抑制汽蝕的 NPSHa 是不切實際的高。

**（三）標準自己在兩版之間換了基準。** 2017 版用 **NPSH3** 算 margin；2024 版改用 **NPSHR**，理由是不是所有廠商都公布 NPSH3，並要求廠商給的 NPSHR ≥ 實測 NPSH3。→ 沿用 dc-09c 的做法，`Limit` 引用的判準要帶 standard + version，否則兩份設計文件寫同一個詞卻指不同的量。
