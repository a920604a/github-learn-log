---
id: dc-21
title: 板式熱交換器與免費冷卻（plate HX / free cooling）
category: cooling
written_at: 2026-09-10
sources:
  - https://mepacademy.com/how-waterside-economizers-work/
  - https://www.deppmann.com/blog/monday-morning-minutes/waterside-economizers-part-7-tower-side-temperatures/
  - https://www.alfalaval.us/industries/energy-and-utilities/data-centers/data-center-cooling/waterside-economizers/
  - https://masterflow.net.au/learning-centre/heat-exchangers/heat-exchanger-fouling-factors/
  - https://blog.se.com/datacenter/2016/08/17/water-temperatures-data-center-cooling/
  - https://up.codes/s/fluid-economizers
related: [dc-17, dc-18, dc-19, dc-20, dc-22]
---

# 板式熱交換器與免費冷卻（plate heat exchanger / waterside economizer）

冰機是靠壓縮機把熱從低溫搬到高溫，很耗電。但如果外面的濕球夠低、[冷卻水塔](cooling-tower.md) 送出來的水本來就比機房回水冷，那熱可以**自己往下坡流**——只要中間放一片薄薄的不鏽鋼板讓兩邊的水各走一側、不混合。這片板子就是板式熱交換器，這種運轉方式叫 free cooling／waterside economizer。它沒有壓縮機、沒有馬達，卻是整條冷卻鏈上最省錢的一段。

## 六格

### 拓撲位置
夾在兩個迴路之間，**兩側都是水**。冷側：塔冷水（並聯在 [冰機](chiller.md) 冷凝器旁）。熱側：冰水回水，接法分兩種——**integrated**（串在回水上預冷，冰機仍在線）／**non-integrated**（旁通冰機，全有全無）。

### 容量單位
kW（熱），但真正決定它的不是面積是**溫差**。三個量：`approach`（熱側出水 − 冷側進水，K）、`effectiveness` ε、`dp_kpa`（兩側各一）。

### 冗餘表達
單一板組是單點——**破板會讓兩迴路互相污染**（塔水進冰水系統）。N+1 常做成兩個較小板組並聯，或選 double-wall 板（犧牲約 10–20% 傳熱換洩漏可見）。

### 遙測介面
| 點位 | 型別 | 備註 |
|---|---|---|
| `t_hot_in` / `t_hot_out` | float, °C | 算 ε |
| `t_cold_in` / `t_cold_out` | float, °C | `t_cold_in` 即塔供水 |
| `dp_hot_kpa` / `dp_cold_kpa` | float | **髒污的主訊號**，要對應流量 |
| `flow` | float, L/s | 沒有它 ΔP 與 ε 都不能解釋 |
| `mode` | enum | mechanical / integrated / free |
| `bypass_valve_pos` | 0–100% | 閥才是故障點 |

### 故障域
板子本身幾乎不會突然壞，**壞的是閥**：切換閥卡死 → 卡在 free cooling 模式而外面變熱 → 冰水溫度一路爬升。破板則是慢性事故：水質交叉污染，數週後才在另一邊的水質報告上看到。

### 維護特性
可拆開清洗、可換墊片、**可整組隔離而不停機**（前提是冰機路徑仍在）——這是它跟 [冰機](chiller.md) 最大的差別。清洗觸發看 ΔP 不看日曆。

## 關鍵數字與計算

### 演算一：切換門檻濕球（本卡最重要的一條式子）

全 free cooling 要求 HX 熱側出水 ≤ 冰水設定值。以 ε 定義、負載側溫差 ΔT_load：

$$T_{wb,\max} = T_{chws} - a_{tower} - \Delta T_{load}\cdot\frac{1-\varepsilon}{\varepsilon}$$

取 [dc-17](cooling-tower.md) 的塔 approach `a_tower = 4 K`、ΔT_load = 6 K、ε = 0.75（則第三項 = 2.0 K，那也就是全 free cooling 時被逼到最寬的 HX approach）：

| 冰水設定 T_chws | 門檻濕球 T_wb,max |
|---|---|
| **7 °C**（傳統） | **1 °C** |
| 10 °C | 4 °C |
| 13 °C | 7 °C |
| **18 °C**（高溫水） | **12 °C** |
| 20 °C | 14 °C |

**這張表就是整張卡的結論：free cooling 小時數不是氣候的函數，是冰水設定值的函數。** 台北冬季最冷月的濕球典型仍在 10 °C 以上（未查證，需拿中央氣象署 TMY 資料驗）——**7 °C 冰水在台北是一年 0 小時；18 °C 冰水才開始有東西可拿。**

### 演算二：部分（integrated）貢獻——差別不是「少一點」是「零」

負載 1600 kW、ΔT 6 K ⇒ 質量流量 m = 1600/(4.18×6) = **63.8 kg/s**。
HX 貢獻 = ε·m·c_p·(T_chwr − T_cws)，T_cws = T_wb + 4。

| 情境 | T_cws | 可用溫差 | HX 貢獻 | 佔 1600 kW |
|---|---|---|---|---|
| 7/13 °C 冰水、WB 20 °C | 24 °C | −11 K | **0**（反而加熱）| 0% |
| 7/13 °C 冰水、WB 12 °C | 16 °C | −3 K | **0** | 0% |
| 7/13 °C 冰水、WB 8 °C | 12 °C | 1 K | 63.8×4.18×0.75 = **200 kW** | 12.5% |
| 18/24 °C 冰水、WB 18 °C | 22 °C | 2 K | **400 kW** | 25% |
| 18/24 °C 冰水、WB 22 °C | 26 °C | −2 K | **0** | 0% |

負值代表塔水比回水還熱——此時開 HX 是**把熱送進機房**，控制邏輯必須擋掉。

### 演算三：合規點 ≠ 出得了力（來源實例）

ASHRAE 90.1 6.5.1.2.1 要求 economizer 在 **50 °F DB / 45 °F WB** 提供 100% 負載（電腦機房例外：蒸發式走 40 °F DB / 35 °F WB，乾冷卻式走 35 °F DB）。Deppmann 的實例照這個點選型，指定 3 °F（≈1.7 K）HX approach：

- WB 33 °F、塔流量 800 GPM：塔供水 43.8 °F → CHWS = 43.8 + 3 = **46.8 °F**，CHWR 54.27 °F。可行。
- 同一組設備搬到 WB **45 °F**（法規起始點）：塔供水 53.2 °F → 冰水均溫 **59.1 °F**，該文估算末端盤管**顯熱出力掉到設計值 25% 以下、潛熱 0%**。

**法規保證的是「換熱器傳得動 100% 的熱」，不是「末端吐得出 100% 的冷」。** 真正在那一點失效的是盤管的 LMTD——那是 `dc-22` CRAH 的題目。

### 演算四：髒污的代價要用「小時數」計價

清潔基準 ΔP 45 kPa @ 63.8 L/s，業界清洗觸發是 **同流量下比 clean baseline 高 15–20%** ⇒ 51.8–54.0 kPa。
熱側則是 ε 從 0.75 掉到 0.68：第三項從 2.0 K 變 **2.8 K** ⇒ 門檻濕球下修 0.8 K。在台北那條本來就很窄的窗口裡，0.8 K 可能就是**整個一月**。

注意 ΔP ∝ Q^1.8 左右：VFD 把流量降到 70%，ΔP 掉到約 52% —— **不對齊流量就比較 ΔP，會把節流看成變乾淨。**

## 常見誤解

**以為 free cooling 是「氣候夠冷才有」的地區特權，但實際上它是冰水設定值買來的。** 同一座台北機房，7 °C 冰水門檻濕球 1 °C（全年 0 小時）、18 °C 冰水門檻 12 °C（冬季可觀）。決定權在伺服器進風溫度上限，不在天氣。

**以為板式 HX 要跟殼管式一樣加 fouling factor 保守選型，但實際上多加板片會反過來加速結垢。** 見來源分歧（二）：加大面積 → 通道流速下降 → 壁面剪應力下降 → 沉積更容易附著。

**以為切到 free cooling 是省電的純益，但實際上「切換」這個動作本身開了一個脆弱窗口。** 冰機一停，[dc-18](chiller.md) 的重啟要 10–15 分鐘，而 [dc-20](thermal-storage-tank.md) 的 ride-through 只有 5.2 分鐘。切過去之後外界濕球回升、又要切回來，中間這段沒有冰機。

## 對資料模型的意涵

1. **`OperatingMode` 是第一個「自變數是決策而非物理」的容量維度。** [dc-16](dual-corded-equipment.md) 的 `scenario`（故障情境）與 [dc-17](cooling-tower.md) 的 `env`（濕球）都是外生的；`mode ∈ {mechanical, integrated, free}` 是控制系統選的。而**跨模式 binding 完全不同**：free 模式下冰機根本不在圖上，binding 是 HX approach 與塔格數。`binding()` 已是 per-resource（dc-17）× per-kind（dc-20），現在再加 **per-mode**。
2. **模式切換要有遲滯與最短駐留時間——這是模型裡第一個帶記憶的約束。** 前 20 張所有約束都是當下狀態的純函數。`ModePolicy(enter_wb_c, exit_wb_c, min_dwell_s)` 的 enter ≠ exit，否則濕球在門檻附近抖動會讓冰機反覆起停。切換動作要吐 `CapacityReport.recovery_until`（[dc-20](thermal-storage-tank.md) 立的欄位第二次派上用場）。
3. **`free_cooling_hours` 不是站點屬性，是 `chws_setpoint` 的函數，而那個設定值的真正擁有者是 IT。** 這是 [dc-16](dual-corded-equipment.md) 「設施 vs IT 管理平面」的第三次穿越（前兩次：iDRAC 的 `psu_policy`、[dc-19](chilled-water-pump.md) 的 BMS 流量變化率）。IT 部門把機櫃進風上限從 27 °C 收到 22 °C，會在設施側直接砍掉整年的 free cooling，**而沒有任何一張設施表會顯示這件事發生過**。→ `chws_setpoint` 要帶 `derived_from`（ASHRAE class + 盤管選型）與 `changed_by`。
4. **`Dimension.proxy_for`：熱性能衰減只能從液壓側可靠地看見。** ΔP 有明確判準（同流量 +15–20% vs clean baseline），approach 則同時被流量、進水溫、負載污染。→ 必須存 `clean_baseline(dp_kpa, flow, water_temp, measured_at)`，而且**是曲線不是單點**（ΔP ∝ Q^1.8）。這是繼 [dc-09b](battery-testing-regime.md) 電池 baseline、dc-19 的 rate limiter 之後第三個「沒有 commissioning 產出就沒有告警規則」的欄位。
5. **HX 是熱鏈上第一個純被動、不吃電的主設備——但它的閥吃電。** 它不在電力樹上，`lose_a` 傳不進來；可是切換閥與致動器在。→ 兩棵樹的橫向邊第一次是「主設備不在電力樹、致動器在」，`fault_domain` 要指向閥的電源而不是設備本身。

## 該問 facility 的問題

1. 水路圖上有沒有 free cooling 板式 HX？塔側與冰水側各接在哪——**integrated（串回水預冷）還是 non-integrated（旁通冰機）**？
2. 冰水供水設定值是多少、**誰有權改**？機櫃進風上限對應哪一個 ASHRAE class？（這一題決定演算一那張表你落在哪一列）
3. commissioning 有沒有量 HX 的 **clean ΔP baseline**（含當時流量與水溫）？墊片材質與上次更換日期？

## 動手練習（30–40 分鐘）

接 [dc-19b](npsh-and-pump-placement.md) 的 `Dimension` / `Limit`，加上模式維度與帶記憶的切換。

```python
from dataclasses import dataclass
from enum import Enum

class Mode(Enum):
    MECHANICAL = "mechanical"; INTEGRATED = "integrated"; FREE = "free"

@dataclass
class PlateHX:
    effectiveness: float          # 0.75
    clean_dp_kpa: float           # 45.0 @ ref_flow
    ref_flow_ls: float            # 63.8
    dp_exponent: float = 1.8      # 意涵 #4：baseline 是曲線

    def dp_expected(self, flow_ls): ...          # clean_dp * (Q/Qref)**n
    def fouling_ratio(self, dp_meas, flow_ls): ...  # 量測/期望，>1.15 觸發

def wb_threshold(chws_c, tower_approach_k, dt_load_k, eps) -> float:
    return chws_c - tower_approach_k - dt_load_k * (1 - eps) / eps

def hx_duty_kw(wb_c, chwr_c, tower_approach_k, m_dot, eps) -> float:
    t_cws = wb_c + tower_approach_k
    return max(0.0, eps * m_dot * 4.18 * (chwr_c - t_cws))   # 負值要夾成 0

@dataclass
class ModePolicy:                 # 意涵 #2：第一個帶記憶的約束
    enter_wb_c: float; exit_wb_c: float; min_dwell_s: int
    def next_mode(self, cur: Mode, wb_c: float, dwell_s: int) -> Mode:
        ...  # dwell_s < min_dwell_s 一律維持 cur
```

**驗收表**（跑出這幾個數字才算做完）：

| 案例 | 期望值 |
|---|---|
| `wb_threshold(7, 4, 6, 0.75)` | 1.0 °C |
| `wb_threshold(18, 4, 6, 0.75)` | 12.0 °C |
| `wb_threshold(18, 4, 6, 0.68)` | ≈ 11.2 °C（髒污 −0.8 K）|
| `hx_duty_kw(8, 13, 4, 63.8, 0.75)` | ≈ 200 kW |
| `hx_duty_kw(20, 13, 4, 63.8, 0.75)` | **0**（不是負值）|
| `hx_duty_kw(18, 24, 4, 63.8, 0.75)` | ≈ 400 kW |
| `fouling_ratio(52.0, 63.8)` | ≈ 1.156 → 觸發清洗 |
| `dp_expected(44.7)`（70% 流量）| ≈ 23.7 kPa（**不是 45**）|

**加分**：把濕球在門檻附近 ±0.5 K 抖動的時間序列餵進 `ModePolicy`，數一數 `enter_wb == exit_wb` 時一天切換幾次，再加 1 K 遲滯 ＋ 30 分鐘駐留看剩幾次。那個差值就是冰機壽命。

## 自我檢核

**Q1. 老闆說「隔壁縣市的機房 free cooling 一年跑 2000 小時，我們一小時都沒有，是不是塔選小了？」怎麼回？**

??? note "答案"
    先問對方的冰水設定值。門檻濕球 = T_chws − a_tower − ΔT(1−ε)/ε，塔的 approach 只佔其中一項（4 K），冰水設定值的差距動輒 11 K（7 → 18 °C）。塔加大只能把 a_tower 從 4 壓到 2，門檻只往上 2 K；把冰水從 7 拉到 18 才是 11 K。**先確認自己在哪一列，再談設備。**

**Q2. 這件事會讓資料模型長出什麼欄位？**

??? note "答案"
    五個：(a) `CapacityReport.mode` 與 **per-mode 的 `binding()`**——free 模式下冰機不在圖上；(b) `ModePolicy(enter_wb_c, exit_wb_c, min_dwell_s)`，第一個帶記憶的約束，並在切換時吐 `recovery_until`；(c) `chws_setpoint` 要帶 `derived_from` 與 `changed_by`，因為它的真正擁有者在 IT 側；(d) `clean_baseline` 是**曲線**（`dp_kpa`, `ref_flow`, `exponent`, `measured_at`）＋ `Dimension.proxy_for`，熱衰減靠液壓訊號偵測；(e) `fault_domain` 指向**閥的電源**，因為 HX 本體不在電力樹上。

**Q3. 為什麼「濕球 20 °C、塔供水 24 °C、冰水回水 13 °C」時 `hx_duty_kw` 一定要夾成 0，不能讓它回負值？**

??? note "答案"
    數學上負值代表熱從塔側流進冰水側——那在物理上會發生（只要閥是開的），所以它不是計算錯誤而是**真實的危險狀態**。但容量報表把它當成「貢獻 −200 kW」會被上游的 `sum` 吃掉、變成看起來只是效率差一點。正確做法是夾成 0 **並且**吐一個 `Finding`（`REVERSE_HEAT_FLOW`），因為處置是關閥不是加設備——同 [dc-18](chiller.md) 立的「跳脫條件 ≠ 容量條件」。

## 來源分歧

**（一）「free cooling 門檻」這個詞至少指三件不同的事，數字差 18 K。** ASHRAE 90.1 6.5.1.2.1 給的是**法規最低能力要求**：50 °F DB / 45 °F WB 要能供 100% 負載（電腦機房例外 40/35 蒸發式、35 DB 乾冷卻式）；學術文獻（開放式塔間接冷卻）建議的**系統獲益上限**是濕球 16 °C；廠商文案（Alfa Laval）說「濕球低於 25 °C 的氣候就適合」，那是**市場適用性**。三者都沒錯，但寫進同一份規格書就會打架。→ `ModePolicy` 引用的門檻必須帶 standard + version + 語意（沿用 [dc-09c](lib-fire-compliance.md) 的 CodeRule 版本化）。

**（二）板式 HX 到底要不要給 fouling factor。** 殼管式傳統做法是給 0.0005 m²·K/W 之類的定值，換算成 30% 以上的額外面積；板式廠商（Masterflow）明確反對，理由是加板片會**降低通道流速與壁面剪應力，反而讓沉積更容易附著**，主張改用剪應力分析 ＋ 清潔度餘裕 ＋ 波紋角度選型。**後果很具體：同一個熱負荷、兩派選型出來的板數與 clean ΔP 都不同**，而你的髒污告警 baseline 正是建在那個 clean ΔP 上。

**（三）墊片壽命。** 一說 3–10 年；一說輕負荷 HVAC 5 年、嚴苛服務 12 個月、典型 3 年。共識只有「超過預期壽命 80% 就趁任何一次開機一併全換」。→ 沿用 [dc-17](cooling-tower.md) 的 `MaintenanceRule` 帶 jurisdiction + source + version，不要寫死一個年限。
