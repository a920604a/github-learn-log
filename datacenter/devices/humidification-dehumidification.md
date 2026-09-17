---
id: dc-24
title: 加濕與除濕（humidification / dehumidification）
category: cooling
written_at: 2026-09-15
sources:
  - https://datacenters.lbl.gov/sites/default/files/Humidity%20Control%20in%20Data%20Centers.03242017_0.pdf
  - https://www.stulz.com/newsroom/detail/dehumidification-in-data-centers-when-using-cw-units-at-high-temperature-levels-1-1/
  - https://www.energystar.gov/products/data_center_equipment/16-more-ways-cut-energy-waste-data-center/make-humidification-adjustments
  - https://blog.stulz-usa.com/adiabatic-vs-isothermal-humidification
  - https://up.codes/s/simultaneous-heating-and-cooling-limitation
  - https://www.cwa.gov.tw/V8/C/C/Statistics/monthlymean.html
related: [dc-22, dc-23, dc-21, dc-15]
---

# 加濕與除濕（humidification / dehumidification）

[dc-23](crac-direct-expansion.md) 演算一那三列把露點釘在 52 °F，SHR 從 0.844 漲到 0.957 完全是那個被釘住的數字造成的。今天的題目就是：**那個露點是誰維持的、代價多少**。答案出乎意料——維持它的通常不是任何一台機器，而是門縫與補氣風門；而最大的代價也不是能耗，是**好幾台機同時往相反方向動**。

## 六格

### 拓撲位置

**本卡是第一張「設備可能根本不存在」的卡。** 加濕器是裝在 [CRAH](crah-chilled-water.md)／[CRAC](crac-direct-expansion.md) 機箱內的一個選配模組，或裝在補氣機（DOAS）上；**除濕則完全沒有對應設備**——它是「盤管表面溫度低於室內露點」這個條件的副產品，外加一段 reheat。上游是自來水（或 RO/DI 水）與補氣風門，下游是房間空氣本身。

### 容量單位

`kg/h`（北美 `lb/h`）水蒸氣，**不是 kW**。除濕端是 kg/h 凝結水。這是模型裡的**第四種 resource：`moisture`**（前三種：power、water、air_flow），而且它是第一個**房間層級狀態變數**而非流過設備的通量。

### 冗餘表達

幾乎沒有意義。加濕器停 8 小時，房間露點不會動——時間常數以天計（見演算一）。N+1 加濕器是純浪費；**真正的冗餘是死區寬度**：死區 16–59 °F DP 有 24 K 可漂移，設備全掛也撐得過一個週末。

### 遙測介面

| 點位 | 為什麼要 |
|---|---|
| 溫度／RH **成對**（≥ 3 組） | 露點是算出來的，兩者不成對就沒有意義 |
| 各組推算露點 ＋ **群體平均** | 控制量是平均值，不是任一支（見演算四） |
| 加濕器輸出 kg/h、累計耗水 | WUE 的分子之一 |
| 凝水盤流量／有無排水 | **唯一能直接看見「正在除濕」的訊號** |
| RO/DI 水導電度 | 超音波式的壽命與白粉風險 |
| 補氣風門開度／補氣風量 | 真正決定房間露點的自變數 |

### 故障域

加濕器掛掉的故障域是「天」等級，幾乎不影響可用性。**但 RH 感測器漂移的故障域是整個房間**——它會讓所有啟用濕度控制的機器同時動作且方向不一致。**故障域的中心第一次不是設備，是感測器。**

### 維護特性

電極式蒸汽筒是自耗品（依水質數月一換，**需要一定導電度的水**）；超音波與噴霧式**必須用 DI/RO 水**（礦物質會變成落在主機板上的白粉），濾心與水路要定檢；濕潤介質式與噴霧式有軍團菌風險，沿用 [dc-17](cooling-tower.md) 的 `MaintenanceRule`（帶 jurisdiction + source + version）。

## 關鍵數字與計算

### 一、房間露點是補氣決定的，不是房間決定的

LBNL 的論證：一間**盤管全乾、無人員、無內部加濕**的機房，露點全室均勻，且它唯一的驅動源是**引進的室外空氣**。所以加濕／除濕負荷 = 補氣量 × Δw，跟機房多大、IT 多少 kW 都沒有直接關係。

取 1000 m²（10 764 ft²）機房，壓力平衡用 **0.06 CFM/ft²**（ASHRAE 62.1 面積項的實務值）：

- 補氣量 = 10 764 × 0.06 = **646 CFM = 0.305 m³/s**
- 乾空氣質量流量（30 °C，ρ ≈ 1.165）= 0.305 × 1.165 = 0.355 kg/s = **1 278 kg/h**
- 台北七月室外 29.6 °C / 70% RH → 露點 **23.6 °C**，`w = 18.4 g/kg`
- 目標室內露點 15.0 °C（ASHRAE 建議上限 59 °F），`w = 10.6 g/kg` → `Δw = 7.8 g/kg`
- 除濕量 = 1 278 × 7.8 g = **約 10.0 kg/h 凝結水**
- 潛熱負荷 = 10.0 × 2 450 kJ/kg ÷ 3 600 = **6.8 kW**

對 1 600 kW IT 負載是 **0.43%**。就算房間漏得厲害、把補氣抓成 0.5 ACH（4 000 m³ × 0.5 = 2 000 m³/h，是上式的 6.6 倍），也只有 18 kW 凝水、12.4 kW，**0.78%**。

**結論很反直覺：濕度控制的能量本身小到可以忽略。真正會痛的是下面三段。**

### 二、台北全年不需要加濕——加濕器是死重

用中央氣象署台北站月均溫濕（Magnus 式推算，**月均值推導、非 TMY 小時級，不可用於選型**）：

| 月 | T / RH | 露點 | vs ASHRAE 死區 16–59 °F DP（−9 ~ 15 °C） |
|---|---|---|---|
| 1 月 | 16.3 °C / 78% | 12.5 °C | 在死區內 |
| 3 月 | 18.5 °C / 78% | 14.6 °C | 貼著上緣 |
| 4 月 | 22.0 °C / 77% | 17.8 °C | **超上限** |
| 7 月 | 29.6 °C / 70% | 23.6 °C | **超上限 8.6 K** |
| 11 月 | 21.2 °C / 76% | 16.8 °C | **超上限** |
| 12 月 | 17.7 °C / 76% | 13.4 °C | 在死區內 |

**4–11 月（八個月）室外露點高於 15 °C；沒有任何一個月接近下限。** LBNL 全篇的擔心是「過度加濕浪費水電」，[dc-22](crah-chilled-water.md) 已推測台灣的約束會反過來——**今天把它算出來了**：在台北，加濕器一年 0 小時，除濕是全年八個月都在跑的那一邊。照美規文獻買來的濕度控制套裝，一半的錢買的是死重。

### 三、最貴的一段：冰水溫度買不到除濕

Stulz 講得最直白：舊式高低溫機組是靠「把水閥全開、降風扇轉速」讓盤管掉到露點以下；**冰水一拉高，這條路直接消失**——溫度整體水準太高，根本降不到露點以下。

物理上限很乾淨：**室內露點的下限 ≈ 盤管表面溫度 ≈ `T_chws` + approach。**

- `T_chws` = 7 °C → 盤管面約 9–10 °C → 室內露點壓得到 10 °C，合規
- `T_chws` = 18 °C → 盤管面約 20 °C → **室內露點的下限就是 20 °C，永遠壓不到 15 °C**

而 [dc-21](plate-hx-free-cooling.md) 的實務結論正是「free cooling 小時數是冰水設定值的函數，7 °C 冰水台北一年 0 小時、18 °C 冰水冬季可觀」。**兩張卡的建議正面衝突，而衝突點只有在台北才會爆**：在乾燥氣候室外露點本來就低於 15 °C，18 °C 冰水一樣合規；在台北室外露點八個月高於 15 °C，18 °C 冰水等於放棄 ASHRAE 建議區的濕度上限。

解法都要錢，而且落點完全不同（見來源分歧一）：一條是 LBNL 的 **DOAS 走 DX 盤管**（補氣路徑上多一個小節點），一條是 Stulz 的 **dual-fluid GCW 機組**（既有 CRAH 長出第二條冷源，多一個 mode）。

### 四、死區、節流帶與 reheat

LBNL 給的具體控制數字：死區 16–59 °F DP；節流帶 4 °F——除濕在 61 °F DP 出力 100%、57 °F 出力 0%；加濕設 35 °F DP 時，33 °F 出力 100%、37 °F 出力 0%。**兩條節流帶不可重疊**，重疊即 crossover。

對照舊制的可怕之處：把死區設成 2004 版的 45–55% RH，在 24 °C 室溫下換算是露點 11.9–14.6 °C，**寬度只有 2.7 K**；ASHRAE 2015 的死區是 **24 K**。差將近 10 倍——這就是為什麼老機房的加濕器與除濕永遠在跑。

**reheat 的代價在資料中心會縮水，這點跟舒適空調不一樣。** 上式 10 kg/h 那組，把補氣從 29.6 °C/18.4 g/kg 冷卻到 13 °C 飽和需 `Δh` ≈ 40.3 kJ/kg × 0.355 kg/s = **14.3 kW**（潛熱 8.1、顯熱 6.2）。若這是 DOAS，13 °C 的風送進要冷卻的機房是**有用的冷量，不是損失**；但若是 CRAC 內建除濕模式，機器必須同時守住房間溫度設定值，就得把過冷的風電加熱回 24 °C：11 K × 1.006 × 0.355 = **3.9 kW 電熱，而那 3.9 kW 還要再被冷走一次**（COP 4 → 再 1.0 kW），合計約 4.9 kW，**是除濕本身的 +34%**。ASHRAE 90.1 因此明文禁止用 reheat 做濕度控制（例外：熱氣旁通 reheat，或 ≥ 90% 來自現場回收熱）。

## 常見誤解

**以為 RH 是房間的性質，但實際上只有露點是。** 同一團空氣，冷通道 22 °C 量到 55% RH、熱通道 35 °C 量到 24% RH，露點都是 12.5 °C。後果很具體：控制量若是 RH，那麼你**只調高送風溫度、一滴水都沒動**，機器就會判定「太乾」開始加濕。[dc-21](plate-hx-free-cooling.md) 那條「把 `chws_setpoint` 拉高換 free cooling」的建議，在 RH 控制的機房裡會順便把加濕器叫醒。

**以為加濕器和除濕不會同時開，但實際上在多台獨立控制的機房裡它們每天同時開。** LBNL 的比喻是同時踩油門和煞車。原因不是邏輯寫錯——是每台機看自己的 RH 感測器，而**感測器漂移 ±3% RH 就足以讓兩台相鄰機器方向相反**。ENERGY STAR 的處方直接得近乎粗暴：把大部分機組的加濕除濕功能**關掉**，只留兩台且彼此拉遠。

**以為除濕是一台設備的功能，但實際上它是一個條件的副產品。** 把冰水溫度調高之後，除濕功能會**無聲消失**：型錄上那台機還是印著除濕模式，控制面板上還是按得下去，按了只是把水閥開到底、風扇降速，然後什麼都不發生——**凝水盤沒有水，而沒有任何告警會為此亮起**。

## 對資料模型的意涵

1. **`resource` 第四種 `moisture`，且它是第一個「不流過任何設備」的資源。** 露點屬於 [dc-22](crah-chilled-water.md) 立的 `RoomReport`，不屬於任何設備的 `CapacityReport`。連帶 `aggregation` 第六種 **`mean_of_converted`**：**不可對 RH 取平均**（各點溫度不同），必須先各自換算成露點再平均。這是五種既有聚合（`sum` / `vector_sum` / `parallel_pump` / `shared_plenum` / 槽幾何）之外，第一種**在聚合前要做單位換算**的。

2. **`ControlGroup` —— 模型第一次需要「誰有權動這個量」。** 前 23 張每個致動器管自己那台設備。濕度只有一個房間層級的量，卻有 N 台機各自能動它：
   `ControlGroup(variable="dew_point_c", actuators=[...], sensors=[...], arbitration="single_master"｜"averaged")`
   並新增 `Finding.OPPOSING_ACTUATION`（同群組內同時存在 +1 與 −1 動作）。**這個 Finding 在任何單一設備的報表上都看不見**——它只存在於群組層級。這是繼 `AirBalance` 之後**第二個只有房間層級才看得見的病**，而且它每天都在發生。

3. **控制輸入第一次需要多感測器共識。** LBNL 要求 ≥ 3 對、先確認彼此一致、取平均、**不可控制在單一支**。→ `SensorGroup(min_valid=3, outlier_policy)`，且**「單支讀數正常但與群體不一致」是一種新的 invalid**：繼 [dc-15](power-meter.md) 的 stale（錶失聯）、[dc-19b](npsh-and-pump-placement.md) 的適用域失效（公式不成立）之後**第三種**。三者都不是「感測器壞了」，而 `Dimension.valid: bool` 三種都裝不下。

4. **同一個設備在兩棵樹上的符號可以相反。** 20 kg/h 的需求下，蒸汽式吃 **0.75 kW/(kg/h)** → 電力樹 **+15 kW**、空氣乾球幾乎不動；超音波式約 0.05 kW/(kg/h) → 電力樹 **+1 kW**，而蒸發吸熱讓熱樹 **−12.5 kW**（等於白拿的冷量）。[dc-22](crah-chilled-water.md) 的 `FanHeat` 是同一個量出現在兩棵樹，這裡是**同一個量在兩棵樹上異號**。任何把熱側貢獻寫成 `abs()` 或假設非負的程式碼都會算錯。另：`min_achievable_dew_point_c` 是**路徑的推導值**不是設備欄位——改 `chws_setpoint` 會讓整個能力消失，而設備表上什麼都不會變。

## 來源分歧

**（一）除濕該搬到哪裡，兩個方案的拓撲完全不同。** LBNL：把所有 CRAH/CRAC 的濕度控制**全部關掉**，交給一台小 DOAS（並註明 DOAS 的盤管常得用 DX 才夠冷）；Stulz：改用 **dual-fluid GCW** 機組，在既有 CRAH 裡塞一套水冷冷凝的 DX 迴路，需要除濕時切到 DX 模式。兩邊都在解同一個問題，但前者在補氣路徑上**多一個設備節點**、後者在既有設備上**多一個 mode**（沿用 [dc-21](plate-hx-free-cooling.md) 的 `ModePolicy`）。資本支出落點與模型結構都不同，**規格書裡混用兩套詞會直接打架**。

**（二）加濕水質的要求互相排斥。** 超音波與噴霧式**必須**用 DI/RO 水（LBNL 給兩個理由：礦物質落在電路板上、水垢縮短設備壽命）；而電極式蒸汽筒**需要**一定導電度的自來水，餵 DI 水根本不導電、不產氣。同一棟樓兩種並存 = **兩條水路**。這不是取捨問題，是規劃階段沒想到就要重拉管。

**（三）要不要在有電的房間裡噴水。** LBNL 明講機房內直接加濕有凝結風險，建議加在 DOAS；部分噴霧廠商的文案則主張直接在機房內噴霧兼作蒸發冷卻。這是風險胃口的分歧，不是技術分歧。

**（四）地區差異／未查證。** ASHRAE 90.1 禁止 reheat 做濕度控制（例外：熱氣旁通、≥ 90% 現場回收熱）；**台灣有無對應條文未查證**。ASHRAE 濕度下限跨版本差約 15 K 露點（2004 的 40% RH → 2008 的 41.9 °F DP → 2015 的 15.8 °F DP，2021 五版二手說法仍分歧）——承 [dc-22](crah-chilled-water.md) 已記的 `EnvelopeRule(standard, edition, class)`，**五版原文仍未取得**。

## 該問 facility 的問題

1. **補氣是專用 DOAS 還是靠 CRAH 自己吸進來？風量多少 CFM，怎麼量的？** 這個數字決定整棟樓的加濕／除濕負荷，而它常常從來沒人量過。
2. **每台 CRAH/CRAC 的加濕與除濕功能是全開，還是只留兩台？溫濕度感測器有幾支、上次校正是什麼時候？** 若答案是「全開、沒校正過」，crossover 幾乎是必然。
3. **冰水設定值定案了嗎？若要走 18 °C 高溫冰水換 free cooling，除濕靠哪一條路徑（DOAS 的 DX 盤管？dual-fluid 機？），這筆錢在預算裡嗎？**

## 動手練習（30–40 分鐘）

延續 [dc-22](crah-chilled-water.md) 的 `RoomReport`。目標是把「濕度只有一個房間層級的量、卻有 N 台機能動它」寫成能跑的東西。

```python
from dataclasses import dataclass, field
from enum import Enum
import math

class Check(Enum):                      # dc-19b 立的三態
    OK = "ok"; VIOLATED = "violated"; NOT_APPLICABLE = "n/a"; INVALID = "invalid"

def dew_point_c(t_c: float, rh_pct: float) -> float:
    """Magnus。RH ≤ 0 時無定義 —— 不要回 0。"""
    g = math.log(rh_pct / 100) + 17.625 * t_c / (243.04 + t_c)
    return 243.04 * g / (17.625 - g)

@dataclass
class SensorPair:
    id: str; t_c: float; rh_pct: float; calibrated_at: str
    def dp(self) -> float: return dew_point_c(self.t_c, self.rh_pct)

@dataclass
class SensorGroup:
    pairs: list[SensorPair]
    min_valid: int = 3
    spread_limit_k: float = 1.5
    def consensus(self) -> tuple[float | None, Check, str]:
        """回 (露點平均, 狀態, 理由)。單支正常但與群體不一致 → INVALID，不是 OK。"""
        ...   # TODO: 剔除離群 → 檢查剩餘數量 ≥ min_valid → 回平均

@dataclass
class ControlGroup:
    variable: str = "dew_point_c"
    actuators: list[str] = field(default_factory=list)
    humidify_at_c: float = 1.7          # 35 °F DP
    dehumidify_at_c: float = 15.0       # 59 °F DP
    throttle_k: float = 2.2             # 4 °F
    def action(self, dp_c: float) -> int: ...          # +1 加濕 / 0 / −1 除濕
    def arbitrate(self, per_device_dp: dict[str, float]) -> list[str]:
        """每台各看自己的感測器時會怎麼動 → 同時出現 +1 與 −1 就吐 OPPOSING_ACTUATION。"""
        ...

def moisture_load_kg_h(oa_m3_s: float, w_oa: float, w_target: float,
                       rho: float = 1.165) -> float: ...

def min_achievable_dp_c(chws_c: float, approach_k: float = 2.0) -> float:
    """除濕能力的下限 —— 路徑的函數，不是設備欄位。"""
    return chws_c + approach_k
```

**驗收表**（五列都要跑出來，數字對得上才算過）：

| 情境 | 輸入 | 期望輸出 |
|---|---|---|
| 台北七月補氣 | 0.305 m³/s，`w_oa` 18.4、`w_target` 10.6 g/kg | ≈ 10.0 kg/h |
| 台北一月 | 室外露點 12.5 °C | 動作 = 0（**在死區內，兩邊都不開**） |
| 感測器漂移 | 三支露點 12.4 / 12.6 / **17.9** | `consensus` 回 INVALID 或剔除後 12.5；**不可回 14.3** |
| crossover | 甲機看到 16.2、乙機看到 1.2 | 吐 `OPPOSING_ACTUATION` |
| 高溫冰水 | `chws_c = 18` | `min_achievable_dp_c` = 20 °C > 15 → 吐 `CANNOT_MEET_LIMIT` |

**加分題（10 分鐘）**：把加濕器同時掛上電力樹與熱樹，蒸汽式填 `(+15.0, 0.0)`、超音波式填 `(+1.0, −12.5)`，然後檢查你既有的熱側加總函式會不會因為那個負號而算錯。

## 自我檢核

**Q1. 一間 1 600 kW 的機房，除濕潛熱負荷只有 6.8 kW（0.43%）。那為什麼濕度控制值得寫一整張卡？**

??? note "答案"
    因為代價不在那 6.8 kW，在三個地方：(1) **crossover** —— 多台機同時加濕與除濕，浪費的是加濕器電力 ＋ 被冷凝掉又補回去的水，而且沒有任何單一設備的報表會顯示異常；(2) **冰水設定值的隱性衝突** —— 拉高 `chws_setpoint` 換 free cooling，會讓除濕能力無聲消失，而設備表上什麼都不會變；(3) **買錯設備** —— 台北一年 0 小時需要加濕，照美規文獻配的加濕套裝有一半是死重，還多一條 DI 水路要維護。

**Q2. 為什麼不能對三支感測器的 RH 讀數取平均，卻可以對露點取平均？這會讓資料模型長出什麼欄位？**

??? note "答案"
    RH 是相對量，同一團空氣在 22 °C 與 35 °C 會讀到 55% 與 24%，平均出來的 39.5% 不對應任何真實狀態；露點是絕對量，盤管全乾時全室均勻，平均才有物理意義。→ `Dimension.aggregation` 新增 `mean_of_converted`（**第一種要在聚合前做單位換算的聚合**），`MeasurementPoint` 必須記錄自己回報的是哪個量，而且溫度與 RH 必須成對綁定（分開存就換算不出露點）。連帶 `SensorGroup(min_valid=3, outlier_policy)`，以及第三種 invalid：**單支讀數在合理範圍內、但與群體不一致**——不是壞掉，是不可信。

**Q3. 「這台 CRAH 有除濕功能」這句話，在你的 schema 裡該存成什麼？**

??? note "答案"
    **不能存成 `can_dehumidify: bool`。** 除濕不是設備能力，是「盤管表面溫度 < 室內露點」這個條件的副產品 → 要存成推導值 `min_achievable_dew_point_c = f(chws_setpoint, approach)`，並且它依賴一個**住在別人手上的參數**（`chws_setpoint` 的真正擁有者在 IT 側，見 [dc-21](plate-hx-free-cooling.md)）。布林欄位會在有人把冰水從 7 °C 調到 18 °C 那天變成謊言，而**沒有任何告警會為此亮起**——凝水盤只是從此沒有水。
