---
id: dc-18
title: 冰水主機（chiller）
category: cooling
written_at: 2026-09-04
sources:
  - https://mepacademy.com/how-to-calculate-chiller-iplv/
  - https://www.buildings.com/building-systems-om/hvac/article/10185904/increase-chiller-efficiency-by-reducing-lift
  - https://www.csemag.com/sustainable-condenser-water-system-strategies/
  - https://www.cundall.com/ideas/blog/why-the-seconds-after-failure-matter-to-data-centre-cooling
  - https://datacentre.solutions/news/26717/ensuring-data-centre-cooling-in-a-power-outage
  - https://www.moeaea.gov.tw/ECW/populace/news/wHandNews_File.ashx?file_id=13293
  - https://up.codes/s/minimum-efficiency-requirement-listed-equipment-standard-rating-and-operating-co
  - https://aircondlounge.com/chiller-surge-symptoms-causes-preventions/
related: [dc-17, dc-19, dc-20, dc-21, dc-22, dc-05b, topic-07]
---

# 冰水主機（chiller）

把熱從 7 °C 的冰水「搬」到 32 °C 的冷卻水，再交給[冷卻水塔](cooling-tower.md)丟掉。它是整條熱鏈上唯一的**幫浦**——其他設備只把熱往下傳，只有它能讓熱從冷的地方跑到熱的地方，代價是壓縮機吃掉幾百 kW 的電。

[dc-17](cooling-tower.md) 說「真正的約束不在水塔，在冰機」。今天把這句話算出來，順便**推翻 dc-17 自己那張表**。

## 六格

### 拓撲位置
熱側上游：`dc-22` CRAH 回來的冰水、`dc-19` 泵；下游：[冷卻水塔](cooling-tower.md)（水冷）或大氣（氣冷）。同時是**電力樹上最大的單一非 IT 負載**——455 RT 機約 250 kW。

### 容量單位
冷凍噸 RT（1 RT = 3.517 kW）。跟水塔一樣**單獨一個數字沒有意義**，必須綁 lift。AHRI 550/590 標準點：蒸發器出水 44 °F、冷凝器進水 85 °F、2.4 gpm/ton。

### 冗餘表達
以整台機為單位，N+1 = 多一台。但**多開一台會把每台推到最小負載以下**（見下）。2N 做在兩組獨立環路。共用集管＝共同祖先，[dc-10b](sts-two-source-relationship.md) 的測試照樣成立。

### 遙測介面
BACnet/IP 或 Modbus TCP 上 BMS（`dc-38`）。

| 點位 | 為什麼要 |
|---|---|
| 蒸發器／冷凝器進出水溫 | 算 lift——效率與容量的自變數 |
| 壓縮機 kW、負載率 % | 即時 kW/ton；是否落在最小負載以下 |
| 導葉開度／VFD 轉速 | surge 前兆 |
| 冷凝器飽和壓力、逼近溫度 | 高壓跳脫餘裕、結垢 |
| 跳脫代碼、重啟計時器 | 停電後多久回得來 |

### 故障域
一台掉 → 冰水供水溫在幾十秒到幾分鐘內開始爬。停電更糟：冰機**不在 UPS 上**，發電機起來後還要走完重啟程序。整條鏈上唯一「掉了不會馬上回來」的設備。

### 維護特性
管束清洗（年度）、換油與油質分析、冷媒洩漏與震動檢測。**清洗必須整台停機並隔離水路** → concurrent maintainability 要求 N+1 **且**每台有獨立隔離閥。

## 關鍵數字與計算

沿用 [dc-17](cooling-tower.md) 的機房：IT **1 600 kW** ＝ 455 RT，0.55 kW/ton，冰水 7/12 °C，冷卻水 32 °C，水塔 4 格。

### 1. lift 與兩條經驗法則

```
lift = 冷凝器進水溫 − 蒸發器出水溫 = 32 − 7 = 25 K
```

兩條業界流通的一階法則：**冷凝側**冷卻水溫每降 1 °F，kW/ton 約降 **2%**；**蒸發側**冰水出水溫每升 1 °F，效率約改善 **1.5%**。1 K = 1.8 °F，所以冷卻水溫每升 1 K，kW/ton 約 **+3.6%**。

### 2. 推翻 dc-17：容量不是掉一半，而是系統自己找新平衡點

[dc-17](cooling-tower.md) 算過「濕球 30 °C 時 4 格只剩 1 300 kW、用率 142%、紅燈」。那張表**建立在冷卻水恆定 32 °C 的假設上**。真實系統水溫會往上浮直到水塔排得掉為止；水溫一浮，冰機更耗電、排熱更多——**正回饋迴路，只能解不能算**。

把 dc-17 的水塔模型（4 格 `Q = 650 × (T_cw − WB)`）跟冰機模型接起來：

```
Q_tower(T_cw) = 650 × (T_cw − WB)
P_comp(T_cw)  = 455 × 0.55 × (1 + 0.036 × (T_cw − 32))
Q_reject      = 1600 + P_comp
```

令兩邊相等解 `T_cw`（WB = 30 °C）：

```
650·x − 19500 = 1561.96 + 9.009·x
640.99·x      = 21061.96
x             = 32.86 °C
```

代回驗證：approach 2.86 K → 水塔排 1 859 kW；kW/ton 0.567 → 壓縮機 258 kW → 需排 1 858 kW ✔。

**濕球 30 °C 時系統不會停，它停在冷卻水 32.9 °C，代價是冰機多吃 8 kW。** dc-17 的 142% 是錯的。掃過各情境：

| 情境 | 平衡冷卻水溫 | 壓縮機 kW | 判定 |
|---|---|---|---|
| WB 28 °C、4 格 | 30.8 °C | 240 | 綠燈 |
| WB 28 °C、3 格（1 格保養） | 31.8 °C | 249 | 綠燈 |
| WB 30 °C、4 格 | 32.9 °C | 258 | 綠燈（dc-17 說紅燈） |
| WB 28 °C、2 格（保養 ＋ 故障） | 33.7 °C | 267 | 黃燈，逼近上限 |
| **WB 30 °C、2 格** | **35.8 °C** | — | **紅燈：超過冷凝器進水上限 35 °C，高壓跳脫** |

真正的紅燈條件**不是水塔容量不足，是解出來的平衡點超過 `max_condenser_entering_c`**。反推臨界濕球：4 格 32.1 °C、3 格 31.1 °C、2 格 **29.2 °C**——台北極端濕球就在這附近，所以「兩格水塔同時不可用」在夏天真的會掉機房，四格全開則再熱都撐得住。

沒有這個求解迴圈，你只會拿到 dc-17 那種錯誤前提下的紅燈，然後在該緊張的時候不緊張。

### 3. IPLV：兩台機誰比較好？

IPLV 是四個負載點的加權倒數平均（AHRI 550/590，權重 1 / 42 / 45 / 12%）：

```
IPLV = 1 / (0.01/A + 0.42/B + 0.45/C + 0.12/D)
```

A~D 是 100/75/50/25% 負載的 COP。兩台 1 200 kW 級水冷離心機：

| 機種 | 100% | 75% | 50% | 25% | IPLV |
|---|---|---|---|---|---|
| 甲 | 6.10 | 6.90 | 7.60 | 5.20 | **6.91** |
| 乙 | 5.90 | 7.50 | 8.60 | 6.00 | **7.69** |

```
乙：1 / (0.01/5.90 + 0.42/7.50 + 0.45/8.60 + 0.12/6.00) = 1/0.13002 = 7.69
```

乙的 IPLV 高 11%，資料中心幾乎全年在部分負載，理當選乙。**但乙在台灣不能賣**——能源署《蒸氣壓縮式冰水機組容許耗用能源基準》要求水冷離心 ≧1055 kW 全載 COP ≥ **6.10**，乙的 5.90 不合格；在美國走 ASHRAE 90.1 Path B 卻可能過關。

### 4. 最小負載：第一個「下界」約束

N+1 配 3 台 × 250 RT。新機房第一年只上 30% IT 負載 = 136 RT，三台全開（運轉時數均衡的天真做法）**每台只有 45 RT = 18% 額定**。

離心機典型最小負載 25–30%，低於此導葉關太小、擴壓段壓力不足 → **surge**（喘振）。防治靠熱氣旁通，把高壓氣放回蒸發器騙機器「還有負載」——**用純浪費的能量換不跳機**。

正解是只開一台跑 54%。但另兩台就成了冷備，重啟要好幾分鐘，**N+1 的「熱備」語意沒了**。這是前 17 張卡第一次出現「加冗餘反而讓事情變糟」。

### 5. 停電那幾分鐘：熱慣量夠不夠

冰機不在 UPS 上。設環路總水量 20 m³，允許回水從 12 爬到 18 °C：

```
可吸收熱 = 20 000 kg × 4.186 kJ/(kg·K) × 6 K = 502 320 kJ
撐得住   = 502 320 / 1 600 kW = 314 s ≈ 5.2 分鐘
```

要撐 15 分鐘需 `V = 1600 × 900 / (4.186 × 6) = 57 m³`，將近 3 倍——這就是 `dc-20` 儲冷槽存在的理由。**前提是泵在 UPS 上**：水不流動時那 20 m³ 送不到機房，有儲量不等於送得到。

## 來源分歧

!!! warning "分歧一：停電後冰機多久回來？"
    - **datacentre.solutions / Climaveneta**：超過四分之一週期的停電就要重啟，典型 **10–15 分鐘**；新機種快速重啟縮到 **4–5 分鐘**。
    - **Cundall（2026-07，附 L4 實測驗證，模型與實測差 0.2 °C 內）**：重啟計時器不是重點。他們在雪梨看到的是回水溫爬太高，冰機重啟後**蒸發器過壓、幾分鐘內二次跳脫**。

    差別是「常數 vs 條件函數」→ **`restart_time_s` 不能是設備欄位**，要是 `restart(return_water_temp, attempt_n)`，且必須能回傳「重啟會失敗」。

!!! warning "分歧二：法規只管全載，還是全載＋部分負載（地區差異）"
    - **台灣（能源署／CNS 12575 96 年版）**：只規定**全載 COP**。水冷離心 <528 / 528–1055 / ≥1055 kW 分別是 5.00 / 5.55 / 6.10；水冷容積式 4.45 / 4.90 / 5.50；**氣冷式全機種只要 2.79**（≈1.26 kW/ton）。沒有任何部分負載要求。
    - **美規（ASHRAE 90.1 表 6.8.1）**：full-load 與 IPLV.IP **兩者都要達標**，且分 Path A / Path B，擇一整套遵守，Path B 機器必須配需量限制控制。

    後果很實際：**只看全載 COP 會選到部分負載很爛的機器**，而那正是它一年 8 000 小時待的地方。→ 沿用 [dc-09c](lib-fire-compliance.md)，`EfficiencyRating` 要帶 `standard` ＋ `version` ＋ `jurisdiction`。

**未查證**：台灣有無資料中心專用冰水規範或 PUE 強制門檻；本卡的冷凝器進水上限 35 °C 是常見典型值，**各機型不同，要跟廠商拿**。

## 常見誤解

**以為冰機容量是固定的幾百 RT，但實際上它是 lift 的函數，而 lift 的一端不在它身上。** 冷凝器進水溫由水塔決定，水塔又吃濕球——**互為因果，必須求解**。前 17 張卡的容量全是沿路徑的純函數，這裡第一次不是。

**以為容量夠就不會跳機，但實際上跳機的是壓力不是容量。** 上表 WB 30 / 2 格那列，水塔「排得掉」1 877 kW，數字上不算超載；它跳是因為平衡點 35.8 °C 超過進水上限。**容量報表全綠、機器照跳。**

**以為冰機跟 UPS 一樣停電後自動接上，但實際上它是唯一會「消失好幾分鐘」的設備。** [UPS](ups-double-conversion.md) 毫秒、[ATS](ats-transfer-switch.md) 百毫秒、[發電機](diesel-generator.md)十秒，冰機是**分鐘**，且回水太熱時可能重啟失敗。這段只能靠水的熱慣量撐。

## 對資料模型的意涵

1. **容量計算從「沿樹求值」變成「解聯立」。** 冰機 `limit(env)` 的 `env` 除了站點濕球，還包含**上游設備的即時工況**（冷卻水溫），而那個工況又被冰機的排熱決定。→ `CapacityReport` 新增 `converged` / `iterations` / `residual_k`。**不收斂的報表要能明講自己不收斂**，而不是吐一個看起來很正常的數字。這是繼 [dc-17](cooling-tower.md) 把 `limit` 從純量變成函數後再往上一階。

2. **第一個「下界」維度。** 前 17 張所有 `Dimension` 都是上界。冰機有 `min_load_pct`，違反時吐 `UNDERLOADED`，處置方向相反（要**減少**在線設備）。它跟冗餘策略直接衝突 → `RedundancyPolicy` 要能表達「N+1 但備機不並聯」，並標出「熱備 vs 冷備」對 ride-through 的差別。

3. **跳脫條件與容量條件是兩回事，分開存。** `max_condenser_entering_c` / `min_evaporator_leaving_c` 是**保護設定值**不是容量。上表證明「沒超載但保護跳脫」會發生 → `Finding` 要有 `PROTECTION_TRIP_PREDICTED`，與 `OVERLOADED` 並列而非合併。

4. **ride-through 是系統推導值，不是設備屬性。** `f(loop_volume_m3, allowed_dt_k, load_kw, pumps_on_ups, restart_time)` 橫跨冰機、泵、儲槽、UPS 四類設備，而 `restart_time` 本身又是回水溫的函數（分歧一）。這是**第一個需要時間軸模擬而非穩態計算的量** → 要有 `TransientScenario`，`CapacityReport` 表達不了它。

5. **冰機回頭咬電力側。** 一台 250 kW，且重啟是 step load。[dc-05b](genset-start-and-transient.md) 的發電機暫態性能吃的就是這種階躍——時序沒排好，頻率下陷會連累別人。→ `PowerLoad` 要有 `startup_profile`（步階大小、允許延遲、可否分批），這份資料只有機械團隊有。

## 該問 facility 的問題

1. **「冷凝器進水上限與蒸發器低溫保護設定值是多少？出廠值有沒有被現場改過？」** 決定我表裡那個 35 °C 是真的還是抄來的。
2. **「停電後重啟時序是什麼？誰先起、間隔多久？回水太熱時會不會拒絕啟動或二次跳脫，實測過沒有？」** 直接決定儲冷槽要多大。
3. **「最小負載多少？低負載靠變頻還是熱氣旁通？運轉策略是輪流開一台還是全部並聯？」** 決定 `min_load_pct` 與 `RedundancyPolicy` 怎麼填。

## 動手練習（40 分鐘）

繼續長同一份 code（[dc-17](cooling-tower.md) 那份），**不要開新檔**。今天要讓它第一次能**解**而不只是算。

```python
from dataclasses import dataclass
from typing import Literal

@dataclass(frozen=True)
class EfficiencyRating:
    metric: Literal["cop_full", "iplv", "kw_per_ton"]
    value: float
    standard: str            # "CNS 12575:2007" / "AHRI 550/590-2023"
    version: str
    jurisdiction: str        # "TW" / "US"

@dataclass
class Chiller:
    id: str
    capacity_rt: float
    design_kw_per_ton: float          # @ lift 25 K
    min_load_pct: float               # 0.25
    max_condenser_entering_c: float   # 35.0
    ratings: list[EfficiencyRating]

    def kw_per_ton(self, t_cw_c: float) -> float:
        """一階近似：每高於 32 °C 1 K，+3.6%。有廠商曲線就改走 Method.curve。"""
        ...
```

要實作的五件事：

1. **`solve_condenser_loop(cells, chiller, load_rt, wet_bulb_c)`** — 固定點迭代求 `T_cw`，上限 20 次、容差 0.05 K；不收斂吐 `Finding("THERMAL_SOLVE_DIVERGED")`。
2. **`CapacityReport` 加 `converged` / `iterations` / `residual_k`**，`binding()` 未收斂時拒絕回報綠燈。
3. **保護跳脫判定**：`T_cw > max_condenser_entering_c` → `Finding("PROTECTION_TRIP_PREDICTED")`，**與容量用率分開回報**。
4. **`Dimension.lower_limit` 與 `UNDERLOADED`** — 三台跑 136 RT 要吐 Finding 並建議減為一台。
5. **`ride_through_s()`** — 實作第 5 節公式；`pumps_on_ups=False` 回 0 並吐 Finding。

**驗收表**（455 RT、水塔 `Q = 162.5 × cells × (T_cw − WB)`、`max_condenser_entering_c = 35`）：

| 案例 | 期望 |
|---|---|
| WB 28、4 格 | `T_cw ≈ 30.8 °C`，≈ 240 kW，綠燈，`converged=True` |
| WB 30、4 格 | `T_cw ≈ 32.9 °C`，≈ 258 kW，綠燈（**不是 dc-17 的 142%**） |
| WB 28、2 格 | `T_cw ≈ 33.7 °C`，≈ 267 kW，黃燈 |
| **WB 30、2 格** | `T_cw ≈ 35.8 °C` → `PROTECTION_TRIP_PREDICTED`，容量用率卻仍未超載 |
| 3 台並聯跑 136 RT | 每台 18% → `UNDERLOADED`，建議減為 1 台 |
| IPLV 甲乙比較 | 甲 6.91、乙 7.69；`jurisdiction="TW"` 時乙不合規 |
| `pumps_on_ups=False` | `ride_through_s == 0` ＋ Finding |

加分題：反推**臨界濕球**——給定格數，二分搜尋讓 `T_cw` 剛好 35 °C 的 WB，會得到 4 格 32.1 / 3 格 31.1 / 2 格 29.2 °C。**這三個數字就是這座機房的冷卻鏈風險地圖，而且是算出來的。**

## 自我檢核

**Q1. 為什麼冰機的容量不能用「沿電力樹往上查」那套方法算出來？**

??? note "答案"
    它的 `limit` 依賴冷凝器進水溫，那個溫度由水塔決定；水塔要排的熱又包含冰機自己的壓縮機功——**互為因果，形成正回饋迴路**。沿樹求值假設下游不影響上游，這個假設在這裡破了，必須改用固定點迭代。

**Q2. 「容量用率 92%、綠燈」但機器跳了。怎麼會這樣？這件事會讓資料模型長出什麼欄位？**

??? note "答案"
    跳的是保護不是容量。冷凝器進水溫解出來 35.8 °C，超過 `max_condenser_entering_c = 35` → 高壓保護動作。熱量「排得掉」，但排得掉的那個溫度機器受不了。→ 模型要把**保護設定值**跟**容量維度**分開存，`Finding` 要有 `PROTECTION_TRIP_PREDICTED`，不能併進 `OVERLOADED`；`CapacityReport` 還要記 `converged` / `iterations`，因為這數字是解出來的不是算出來的。

**Q3. 三台冰機 N+1，全部並聯運轉是不是最安全的做法？**

??? note "答案"
    不是。低負載時三台並聯會把每台推到最小負載（典型 25–30%）以下，觸發 surge 或逼機器開熱氣旁通純燒電。只開一台的話另兩台是冷備，跳機後要好幾分鐘才回得來，ride-through 需求就上升。**冗餘策略與最小負載直接衝突**，模型要能表達「熱備 vs 冷備」而不只是 N+1 這個標籤。

## 相關概念

- 上游：[冷卻水塔](cooling-tower.md)（今天推翻了它那張容量表的前提）
- 配套：`dc-19` 冰水泵、`dc-20` 儲冷槽（第 5 節算出的 57 m³）、`dc-21` free cooling
- 電力側回饋：[發電機起動時序](genset-start-and-transient.md)、[柴油發電機](diesel-generator.md)
- 法規版本化：[鋰電消防合規](lib-fire-compliance.md)；`topic-07` PUE — 冰機是分子裡最大的一塊
