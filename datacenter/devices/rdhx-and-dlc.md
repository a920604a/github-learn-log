---
id: dc-27
title: 後門熱交換器 RDHx 與直接晶片液冷 DLC
category: cooling
written_at: 2026-09-23
sources:
  - https://www.vertiv.com/4939ac/globalassets/products/thermal-management/high-density-solutions/vertiv-liebert-dcd-25-50kw-water-cooled-rear-door-heat-exchanger-guide-specification-sl-70960.pdf
  - https://www.chatsworth.com/en-us/resources/blogs/2026/5-misunderstood-facts-about-direct-to-chip-liquid-cooling/
  - https://spectrum.ieee.org/fanless-liquid-cooled-ai-servers-coolit
related: [dc-26, dc-26b, dc-24, dc-23, dc-25b, dc-37]
---

# 後門熱交換器 RDHx 與直接晶片液冷 DLC

**RDHx** 是裝在機櫃後門位置的一片水冷盤管：伺服器吹出來的熱風穿過它，出門時已被冷回室溫，機房「感覺不到」這櫃的熱。**DLC** 是把冷板直接貼在 CPU/GPU 上，由 [CDU](cdu.md) 的 TCS 迴路把晶片熱帶走。兩者常一起出現：**DLC 吃掉大部分熱，剩下的空氣熱由 RDHx 或房間空調收**。這張卡的主角是那條「剩下的」——它決定一台混合機櫃到底要兩套冷卻各做多大。

## 六格

### 拓撲位置

RDHx：冷水源（FWS 或專用二次迴路）→ 旋轉接頭 → 門上盤管 → 回水。空氣側**串在伺服器風扇下游**。DLC：[CDU](cdu.md) TCS → 分歧管 → 快接頭 → 冷板。**同一櫃兩條水路、兩個溫度等級**（演算三）。

### 容量單位

RDHx：**顯熱 kW**，在指定的 (室溫, 進水溫, RH, 風量) 下成立。Vertiv DCD35 原廠：**35 kW @ 21 °C 室溫、12 °C 進水、50% RH**。DLC：kW ＋ **捕獲率**（液體帶走的比例）。

### 冗餘表達

被動門**沒有可冗餘的東西**——沒有風扇、沒有控制器，只有盤管與閥。主動門的風扇模組標 **N+1 時 6300 m³/h、無冗餘時 7400 m³/h**：**冗餘是用額定風量換的**。A/B 電源切換為選配。

### 遙測介面

| 型式 | 點位 |
|---|---|
| 被動門 | **無**（選配外接閥組才有閥位） |
| 主動門 | Modbus TCP：風扇轉速／故障乾接點、門內外各 2 支溫度、門磁、漏水（**監控包為選配**） |
| DLC | 走 CDU（見 dc-26）；櫃內分歧管多半無點位 |

**被動門是遙測黑盒**，它壞了只能從房間感測器（`dc-37`）間接看出來。

### 故障域

水斷 → 門變成一片 35 Pa 的阻力，42 °C 排風直接進房間：**不是這櫃掛，是整個房間多了 35 kW 沒人預期的熱**。主動門控制器或感測器故障 → 風扇**強制 100%**（原廠規格）。DLC 流量斷 → 見 dc-26 的 10 秒。

### 維護特性

旋轉接頭讓門**不拆水管就能打開**維修伺服器；但開門那段時間該櫃熱風直排房間。凝結水盤原廠明寫「**只供偶發凝結**」，接排水不代表可以除濕。

## 關鍵數字與計算

### 演算一：把 35 kW 拆開，它藏了一個「別人的」風量

原廠水側：5 m³/h、12 → 18 °C。驗算 Q = ṁ·cp·ΔT = (5/3.6 × 0.998) × 4.19 × 6 = **34.8 kW** ✓。

空氣側壓損規格是 **35 Pa @ 4900 m³/h**——這就是額定背後的風量。空氣熱容率 C_air = 4900/3600 × 1.2 × 1.005 = **1.64 kW/K**，於是伺服器排風溫升 = 35 / 1.64 = **21.3 K**，排風 **42.3 °C** 被冷回 21 °C。

用 ε-NTU 反推盤管效能（固定兩側流量下 ε 為常數，空氣側是 C_min）：
`Q = ε · C_air · (T_排風 − T_進水)` → 35 = ε × 1.64 × (42.3 − 12) → **ε = 0.703**

**被動門自己沒有風扇**，那 4900 m³/h 是**伺服器風扇**推的；原廠也明寫使用前要確認伺服器風扇的升壓足以克服門的阻力。→ 門的容量是**另一台設備的運轉點**的函數。

### 演算二：台灣機房的進水溫窗口，是空集合

進水溫有兩條邊界：

- **下限（不凝結）**：`EWT ≥ T_露點(室) + margin`。原廠給的是露點上限 10.5 °C、額定進水 12 °C → **margin 1.5 K**，本卡沿用。
- **上限（房間中性，出風 = 室溫）**：代回演算一，`ε·(T_室 + ΔT − EWT) = ΔT` → **`EWT ≤ T_室 − ΔT·(1/ε − 1)` = T_室 − 9.0 K**

| 室內條件 | 露點（Magnus） | 下限 | 上限 | 窗口 |
|---|---|---|---|---|
| 21 °C / 50%（額定點） | 10.2 °C | 11.7 | 12.0 | **0.3 K** |
| 24 °C / 50% | 12.9 | 14.4 | 15.0 | 0.6 K |
| 24 °C / 60% | 15.8 | **17.3** | **15.0** | **空集合（差 2.3 K）** |

**24 °C / 60% RH 下，滿載的被動門不可能同時不凝結又房間中性。** 退而求其次取 EWT = 17.3 °C：門只收 0.703 × 1.64 × (45.3 − 17.3) ≈ **32.4 kW**，**約 2.6 kW 留給房間**，出風約 25.6 °C。要保住窗口，室內 RH 必須壓到 **≤ 51.9%**（24 °C 時露點 ≤ 13.5 °C）——這件事是 [dc-24 除濕](humidification-dehumidification.md) 的 CRAH 在做，不是門。

⚠ ε 固定是一階近似；風量或水量一變 ε 就變。台灣室內 RH 取 60% 是假設的潮濕工況。

### 演算三：DLC 的 30 °C 水不能直接餵門

[dc-26](cdu.md) 的 ASHRAE rating 點 TCS 出水 **30 °C**。把同一條水接到門上（室溫 24 °C、滿載 35 kW）：
`Q = 0.703 × 1.64 × (45.3 − 30) = 17.7 kW`，**一半的熱留在房間**，出風 **34.5 °C**。

門要的是 ≤ 15 °C 的水，冷板要的是 30 °C 以上（越高越能免費冷卻，dc-26 的加法鏈）。**同一個機櫃需要兩個溫度等級的迴路**；「一條 CDU 迴路全包」只在門另有 CDU 或降溫級時成立。

### 演算四：捕獲率的不確定，讓兩邊合計要準備 120%

取 130 kW 機櫃，捕獲率三種說法（見來源分歧）：

| 捕獲率 | 液側 | 空氣側 |
|---|---|---|
| 60% | 78 kW | **52 kW** |
| 80% | **104 kW** | 26 kW |
| 95% | 123.5 kW | 6.5 kW |

**兩側最壞情況來自區間的相反端**：液側要按高捕獲率配（80% → 104），空氣側要按低捕獲率配（60% → 52）。合計 **156 kW 給 130 kW 的機櫃 = 120%**。這不是浪費，是對一個由 **伺服器韌體與進風溫度決定、設施不能控制**的比例的保險。而 CoolIT 的算術給了上限感：250 kW 機櫃 × 30% 空氣 = **75 kW**，已超過任何一片門的額定。

## 常見誤解

**以為 RDHx 是「一台 35 kW 的冷卻設備」，但實際上它的 35 kW 是伺服器風扇推 4900 m³/h 時才成立。** 被動門自己不產生風量，換一批風扇曲線不同的伺服器，同一片門的容量就變了——而那個參數寫在 IT 的規格書裡。

**以為 DLC 機櫃不需要空調，但實際上 20–40% 的熱仍然進空氣。** 記憶體、網卡、電源、硬碟沒有冷板。捕獲率還會隨負載與進風溫度變，所以空氣側不能按「剩下的零頭」配。

**以為進水溫越低門越強就越好，但實際上低於露點 + margin 就開始凝結，而門不是除濕機。** 凝結水盤原廠明寫只供偶發凝結。拿 [dc-18](chiller.md) 的 7 °C 冰水直接餵門，在 24 °C / 60% 的房間裡每一片門都在滴水。

## 對資料模型的意涵

1. **`SplitDimension` 終於接上了，而且第一次的語意是「分量被約束釘死」。** W38 交辦、[dc-23](crac-direct-expansion.md) 發明、dc-26 接不上的 `SplitDimension(total, sensible, latent)`：RDHx 的 `latent` **不是容量是約束**——必須恆為 0，由 `Constraint(ewt_c ≥ room_dew_point_c + margin_k)` 保證。這條約束**跨實體**：左邊是門的水、右邊是房間的空氣，只能住在 [dc-25b](../topics/airflow-management-metrics.md) 之後的 `RoomReport` 層。
2. **`SplitDimension` 第二種切法：按介質切（`liquid` / `air`），不是按顯潛熱切。** → `HybridLoad(total_kw, capture_ratio: Sourced[Range])`，`liquid_kw` / `air_kw` 是 property，**不可存成兩個常數**；容量檢查要 `binding()` 分別取區間相反端（演算四）。這跟 [dc-16](dual-corded-equipment.md) 的「跨情境取最壞」是同一個模式：**最壞值不在同一個情境裡**。
3. **`Dimension.limit` 的自變數第一次屬於另一台設備。** 門容量 = f(EWT, T_室, **server_airflow**)，而 server_airflow 由 ITE 決定 → `depends_on: [ite_device_id]`，`owner = ite_vendor`（dc-26 的 `Setpoint.owner` 第二次出現）。
4. **`WaterTempWindow(floor, ceiling, basis)` ＋ `Finding.INFEASIBLE_WINDOW`。** 窗口是兩個不同來源的約束交集（房間濕度 vs 房間中性目標），**可以為空**，而為空時每一個單獨的約束都是綠的。同時 `CoolingLoop.temp_class` 必須是欄位：30 °C 的 TCS 與 15 °C 的門迴路不可掛同一個 `loop_id`。
5. **被動門 `telemetry = none`。** → `Device.observability ∈ {direct, inferred, none}`，被動門的狀態只能從 `dc-37` 的房間溫度推，**告警規則必須掛在房間層，不是設備層**。

## 來源分歧

**捕獲率三種說法，而且都是廠商。** Chatsworth（機櫃廠）：液體通常帶走 **60–80%**，空氣 20–40%；CoolIT（冷板廠，**贊助文章**）：70/30 在低密度可行，超過 ~250 kW 應走「近全捕獲」、空氣 **< 1%**，並自承嚴格意義的 100% 幾乎做不到；搜尋摘要另有「70–90%」、「單櫃 53 kW 測得 94%」兩說，**未取得原文，不引用**。三者都有商業立場，**沒有第三方標準定義捕獲率在什麼進風溫度、什麼負載下量**——跟 [dc-26b](cdu-rating-and-filtration.md) 的 rating 條件是同一種洞。

**RDHx 露點上限 vs ASHRAE 推薦區間。** Vertiv DCD 規格：室內露點上限 **10.5 °C**、絕對濕度 ≤ 8 g/kg。ASHRAE TC 9.9 推薦區間上限露點為 **15 °C**（依第 5 版，**本次未重新取得原文核對**）。若兩者屬實，**一間完全符合 ASHRAE 推薦區間的機房仍可能違反門的規格**。另 nVent 在搜尋摘要中有「14 °C 進水 68 kW、24 °C 進水 44 kW」，產品頁抓不到內文，**依 dc-26b 立的規則不寫入計算**。

## 該問 facility 的問題

1. **門的進水來自哪條迴路、設計溫度多少？** 若跟 DLC 同一條 TCS，演算三說一半熱留房間。
2. **設計室內露點上限多少，由誰控？** 門的窗口在 24 °C 時只有 RH ≤ 52% 才存在。
3. **採購的伺服器風扇在門的 35 Pa 阻力下風量多少？** 這是門容量的輸入，IT 那邊要給。

## 動手練習（30–40 分鐘）

接 [dc-26b](cdu-rating-and-filtration.md) 的 `rating.py`，新建 `rdhx.py`。**核心目標：讓「窗口為空」與「捕獲率不確定」都變成可被程式偵測的 Finding，而不是註解。**

```python
import math
from dataclasses import dataclass

def dew_point_c(t_c: float, rh: float) -> float: ...   # Magnus: a=17.62, b=243.12

def air_c_kw_k(flow_m3h: float) -> float: ...          # ρ=1.2, cp=1.005

def door_eps(rated_kw, flow_m3h, t_room_c, ewt_c) -> float: ...

def door_removed_kw(eps, flow_m3h, t_room_c, load_kw, ewt_c) -> float:
    ...  # ε · C_air · (T_room + load/C_air − EWT)

def ewt_window(t_room_c, rh, load_kw, flow_m3h, eps,
               margin_k=1.5) -> tuple[float, float] | None:
    ...  # (floor, ceiling)；floor > ceiling -> None

@dataclass(frozen=True)
class HybridLoad:
    total_kw: float
    capture_lo: float
    capture_hi: float
    source: str
    def liquid_design_kw(self) -> float: ...           # 取 hi
    def air_design_kw(self) -> float: ...              # 取 lo
```

### 驗收表

六列全過才算完成。

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | `dew_point_c(21, .5)` / `(24, .6)` | ≈ **10.2** / **15.8** °C |
| 2 | `door_eps(35, 4900, 21, 12)` | ≈ **0.703** |
| 3 | `ewt_window(21, .5, 35, 4900, .703)` | ≈ **(11.7, 12.0)** |
| 4 | `ewt_window(24, .6, 35, 4900, .703)` | **None** |
| 5 | `door_removed_kw(.703, 4900, 24, 35, 30)` | ≈ **17.7 kW**（一半留給房間） |
| 6 | `HybridLoad(130, .6, .8, "vendor")` 兩側合計 ÷ total | **1.20** |

**加分題**：用二分法找出 24 °C 時窗口剛好存在的最大 RH（應 ≈ **51.9%**），再把結果寫成 `Finding(kind="INFEASIBLE_WINDOW", fix="room_rh <= 0.519")`——**修正動作的對象是房間的 CRAH，不是門**。

## 自我檢核

**Q1. 一片被動 RDHx 標 35 kW。換了一批風扇較弱的伺服器，負載一樣 35 kW，會發生什麼？**

??? note "答案"
    風量下降 → C_air 變小 → 排風溫升變大、ε 也跟著變（NTU 變了）。門實際收的熱不再是 35 kW，出風可能高於室溫，多出來的熱進房間。**門自己沒有風扇**，它的額定建立在伺服器推 4900 m³/h 的前提上，而這個參數在 IT 的規格書裡（演算一）。

**Q2. 你的機房 24 °C / 60% RH，全部符合設計。為什麼 RDHx 還是會滴水或者漏熱？**

??? note "答案"
    因為進水溫窗口是空的：不凝結要 EWT ≥ 17.3 °C，房間中性要 EWT ≤ 15.0 °C。兩條約束各自都合理、各自都可以是綠燈，交集卻是空的（演算二）。解法在房間：把 RH 壓到 ≤ 52%，這是 CRAH 除濕的事。

**Q3. 這張卡會讓你的資料模型長出什麼欄位？**

??? note "答案"
    (1) **`SplitDimension` 接上**，RDHx 的 `latent` 由跨實體 `Constraint(ewt ≥ room_dew_point + margin)` 釘成 0，住 `RoomReport`；(2) **`HybridLoad(total, capture_ratio: Sourced[Range])`**，液／氣兩側是 property，設計值取區間相反端；(3) **`Dimension.limit` 的 `depends_on` 指向 ITE 設備**；(4) **`WaterTempWindow` ＋ `Finding.INFEASIBLE_WINDOW` ＋ `CoolingLoop.temp_class`**；(5) **`Device.observability`**，被動門為 `none`，告警掛房間層。

## 相關卡片

[液冷 CDU](cdu.md)｜[CDU 額定與可比較性](cdu-rating-and-filtration.md)｜[加濕與除濕](humidification-dehumidification.md)｜[CRAC 直膨式](crac-direct-expansion.md)｜[氣流管理的度量](../topics/airflow-management-metrics.md)｜[冰水主機](chiller.md)
