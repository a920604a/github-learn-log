---
id: dc-25b
title: 氣流管理的度量（λ / RTI / RCI、合規判準 vs 指數判準、差壓設定值）
category: topic
written_at: 2026-09-18
sources:
  - http://www.ancis.us/images/SL-08-018_Final.pdf
  - http://www.ancis.us/images/New_York_08_Web.pdf
  - https://www.akcp.com/2021/06/10/cold-aisle-containment-s-air-pressure/
  - https://datacentremagazine.com/articles/differential-air-pressure-in-your-data-centre
related: [dc-22, dc-23, dc-25]
---

# 氣流管理的度量（airflow management metrics）

[dc-25](../devices/aisle-containment.md) 做的是封閉的**幾何與完整性**——誰在哪條通道、封閉還在不在。這張卡做另一半：**做完之後怎麼知道有沒有效**。答案是三個指標：λ（風量比）、RTI（回風溫度指數）、RCI（機櫃冷卻指數）。前兩個其實是同一個數字，第三個會在有機櫃違規的時候給你高分。

> 這是本軌跡第一張主題卡（`topics/`），原排第五輪，因 [dc-25](../devices/aisle-containment.md) 拆卡而提前。

## 定義

| 指標 | 定義 | 出處 |
|---|---|---|
| λ | 空調送風量 ÷ IT 總抽風量 | [dc-22](../devices/crah-chilled-water.md) 自己取的名字 |
| RTI | `(T_回風 − T_送風) / ΔT_設備 × 100%` | Herrlin 2007，SL-08-018 式 (2) |
| BP（旁通率） | 送風未經伺服器直接回到機組的比例 | [dc-22](../devices/crah-chilled-water.md) |
| RCI_HI | `[1 − 總超溫量 / 最大允許超溫量] × 100%` | Herrlin 2005，NY-08-004 式 (1) |

RTI 的判讀（SL-08-018 表 2）：**100% 是標的，>100% 主要是再循環，<100% 主要是旁通。**

## 為什麼重要

### 演算一：λ、RTI、BP 是同一個數字的三個名字

穩態下 IT 發的熱等於空調收的熱：

`ṁ_送 · cp · (T_回 − T_送) = ṁ_IT · cp · ΔT_設備`

兩邊除一下就得到 **RTI = ṁ_IT / ṁ_送 = 1/λ**。這不是經驗關係，是能量守恆，沒有例外。

驗證：[dc-22](../devices/crah-chilled-water.md) 那間機房風量比 1.75 → RTI = 57.1% → BP = 1 − 0.571 = **42.9%**，而那張卡是從三個溫度獨立算出 **0.43**。兩條路同一個數字 ✓。[dc-25](../devices/aisle-containment.md) 引的 APC WP135 未封閉基準 λ = 1.49 → RTI = 67.1%、BP = 32.9%。

**所以三者只能存一個。** 存可直接量的 λ（一個風量比，不需要 ΔT_設備 這個難量的加權平均），其餘降為 `derived_from`。這是「兩張卡各自替同一個量發明名字」的首例——不是同名不同義，是**同義不同名**。

### 演算二：RTI 100% 不代表沒有混合

同時有旁通與再循環時，對通道做質量平衡（`BP = ṁ_旁通/ṁ_送`、`R = ṁ_再循環/ṁ_IT`）：

`BP = 1 − (1 − R)/λ`

R = 0 時退化成 `BP = 1 − 1/λ`。但取 **λ = 1、R = 0.4**：BP = 0.4，而 **RTI = 100%，滿分**。一間每台伺服器都在吸 40% 自己排氣的機房，RTI 給滿分。

**λ 管「多少」，封閉管「去哪」，RTI 只看得到前者。** 要把 BP 與 R 分開，得有第二個獨立量測——[dc-22](../devices/crah-chilled-water.md) 的三溫度法正是它：對回風做混合平衡可得 `BP = (T_排 − T_回)/(T_排 − T_送)`，**與 R 無關**。兩個量測聯立才解得出 `R = 1 − λ(1 − BP)`。

### 演算三：RCI 是相對於某一版指引的分數，而且不排序風險

40 櫃，39 櫃進風 24 °C，1 櫃 33 °C（**超過 A1 允許上限 32 °C**）：

| 套用版本 | 建議上限 | 帶寬 | 總超溫 | 最大允許超溫 | RCI_HI |
|---|---|---|---|---|---|
| ASHRAE 2011 A1 | 27 °C | 5 K | 6 K | 5 × 40 = 200 | **97.0%** |
| ASHRAE 2004 Class 1 | 25 °C | 7 K | 8 K | 7 × 40 = 280 | **97.1%** |

SL-08-018 表 1 的評級是「≥96% Good」→ **兩版都判「良好」，而機房裡有一櫃在允許範圍外。**

更糟的是**分母有機櫃數**。同一櫃 33 °C 放進 200 櫃的機房：最大允許超溫 = 5 × 200 = 1000 → RCI_HI = **99.4%**。危險完全沒變，分數更漂亮。**RCI 不可跨房間比大小。**

這不是我編的邊界案例。NY-08-004 表 1 是已發表的原始數據：

| 送風量 | 55 °F | 70 °F |
|---|---|---|
| 80% | **88** | 56* |
| 100% | 100 | **91\*** |

星號的定義（原文）：**一個或多個進風溫度落在允許範圍外**。所以 **91\* 的那間比 88 的那間更危險，而 SL-08-018 的評級表把 91 列為 Acceptable、88 列為 Poor——排序是反的。**

### 演算四：差壓設定值直接買走風扇功率

漏氣走孔口式 `Q = C·A·√(2ΔP/ρ)`。取 ρ = 1.2、C = 0.6、有效洩漏面積 A = 0.5 m²（**假設值**：門縫、頂板接縫、線槽開孔），一條通道 10 櫃 × 6 kW、ΔT_設備 20 K → `ṁ_IT = 60/(1.21×20) = 2.479 m³/s`：

| ΔP 設定值 | 漏氣 m³/s | 需要的 λ | RTI | 風扇功率（相對 2 Pa） |
|---|---|---|---|---|
| 20 Pa | 1.73 | 1.70 | 58.9% | **×2.69** |
| 5 Pa | 0.87 | 1.35 | 74.1% | ×1.35 |
| 2 Pa | 0.55 | 1.22 | 81.9% | ×1.00 |

**漏氣量比 = √(ΔP 比) = √10 = 3.16，這一項與洩漏面積無關**；λ 與功率的絕對值才依賴 A 的假設。風扇功率用理想三次方（[dc-19](../devices/chilled-water-pump.md) 已證實實機指數是擬合值，這裡只作量級比較）。

**結論：差壓設定值不是控制細節，是每天在燒的錢，而且它決定了你的 RTI。**

### 來源分歧：差壓設定值橫跨一個數量級，且全是二手

AKCP（2021）**同一篇文章內**：「冷熱通道間維持 20 Pa 的壓差」，但稍後又寫「理想的資料中心是以零差壓運轉」。同一作者 2023 在 Data Centre Magazine 的圖說是「風扇加速以維持 20 Pa」，內文卻是「目標是冷通道極輕微的正壓」。專利文獻常見「冷通道高於熱通道 1–5 Pa」。

**三個數字（20 / 1–5 / ≈0 Pa）沒有任何一個來自標準**——ASHRAE、Uptime 都查不到規定值，全是廠商與專利口徑。而依演算四，20 Pa 與 2 Pa 之間差 2.7 倍風扇功率。

**第二個分歧（Herrlin 自己跟自己）**：RCI 合格門檻在 NY-08-004 寫「≥95% 是良好系統設計的表徵」；同年同卷 SL-08-018 表 1 卻是「Ideal 100% / Good ≥96% / Acceptable 91–95% / Poor ≤90%」。**95% 在一份文件裡是「良好」，在另一份裡是「可接受」的下半段。** 二手文獻另有 ≥90% 的說法。規格書寫 RCI 門檻時必須指名是哪一份。

## 常見誤解

**以為 λ、RTI、旁通率是三個獨立指標所以三個都要量、都要存，但實際上能量守恆讓 RTI ≡ 1/λ、BP ≡ 1 − RTI（無再循環時）。** 存三份的唯一後果是三份會不一致，然後有人花一個下午查為什麼。

**以為 RTI = 100% 代表氣流管理做得好，但實際上 λ = 1 只說總量相等，完全沒說空氣去了哪裡。** 演算二的 λ=1、R=0.4 機房 RTI 滿分。RTI 是**能耗**指標不是**熱環境**指標，Herrlin 原文也是這樣分工的（RCI 管熱環境、RTI 管能耗）。

**以為 RCI 高就代表沒有設備在危險溫度，但實際上 RCI 是對機櫃數正規化的平均分，可以在有機櫃違規時給高分。** 演算三的 97%*、Herrlin 自己表 1 的 91*。**唯一能回答「有沒有設備超出允許範圍」的是那個星號，不是那個數字。**

## 對資料模型的意涵

1. **這是第一個「後面的卡把前面的欄位刪掉」而不是疊加的建議。** [dc-22](../devices/crah-chilled-water.md) 的 `AirBalance.bypass` 改存 `lam`（可直接量），`rti` / `bypass` 降為 `@property`。之前 24 張卡全是擴充，這張是**收斂**——對照 W37 記的「值＋出處家族第五次」是同一種病的新變種：**同義不同名**。

2. **一個 `AirBalance` 有三個概念，但只有兩個獨立量測維度。** λ 給 RTI，三溫度法給 BP，兩個一起才解得出 R。**只量到一個時 `recirculation` 必須是 `unknown` 而非 `0`**——同 [dc-25](../devices/aisle-containment.md) 的 `Containment.integrity` 三態、[dc-15](../devices/power-meter.md) 的「錶失聯是 stale 不是 0」。填 0 會宣告一間再循環 40% 的機房沒有再循環。

3. **`rci_hi(intakes, envelope)` 的第二參數不可省，且分數要記機櫃數。** 分數依賴 envelope 版本（2004 vs 2011，帶寬 7 K vs 5 K）與 class，接 [dc-22](../devices/crah-chilled-water.md) 的 `EnvelopeRule`；而演算三證明**同一個危險在大房間得高分**，所以 `Score(value, envelope_ref, n_intakes)`，缺一不可比較。這是「值＋出處」家族第六次。

4. **雙判準的兩個 `Finding` 並列不可合併。** `RCI_DEGRADED`（指數判準，處置是調全房設定值）與 `INTAKE_ABOVE_ALLOWABLE`（合規判準，處置是派人去看那一櫃）——處置方向不同，且**後者可以在前者全綠時發生**。結構同 [dc-18](../devices/chiller.md) 的 `PROTECTION_TRIP_PREDICTED` 與 `OVERLOADED`。

5. **差壓設定值是第四個「沒有 commissioning 產出就沒有告警規則」的欄位**（前三：[dc-09b](../devices/battery-testing-regime.md) 電池 baseline、[dc-19](../devices/chilled-water-pump.md) rate limiter、[dc-21](../devices/plate-hx-free-cooling.md) clean ΔP）。`Setpoint(value, basis, source, commissioned_at)`——沒有 basis 的 20 Pa 跟沒有 basis 的 2 Pa 在資料庫裡長得一模一樣，但差 2.7 倍風扇功率。

## 該問 facility 的問題

1. **BMS 上的差壓設定值是多少，誰定的，依據是什麼？** 如果答案是「廠商預設」，那就是演算四那張表上的一列，而沒有人選過它。
2. **CRAH 的 ΔT_設備 是量出來的還是假設的？** RTI 的分母是「跨伺服器溫升的加權平均」——現場幾乎沒有人真的量，通常拿一個 20 K 塞進去，而 [dc-22](../devices/crah-chilled-water.md) 已經指出舊機 10 K、新刀鋒 28 K 都有。
3. **驗收規格書寫的 RCI 門檻引的是哪一份、哪一版 envelope？** 95% 在 NY-08-004 是良好、在 SL-08-018 是可接受的下半段。

## 動手練習（30–40 分鐘）

接 [dc-25](../devices/aisle-containment.md) 昨天做的 `Aisle` / `Containment`，建 `airflow_metrics.py`。**只存可量的，其餘算出來。**

```python
@dataclass
class AirBalance:
    aisle_id: str
    lam: float                      # 唯一存的比值：送風量 / IT 抽風量
    bp: float | None = None         # 三溫度法量到才有；None = 未量測
    @property
    def rti(self) -> float: ...     # 1/lam
    @property
    def recirculation(self):        # bp is None -> "unknown"，不可回 0.0
        ...                         # 否則 1 - lam*(1-bp)

def rci_hi(intakes_c: list[float], envelope) -> "Score": ...
    # envelope 帶 max_recommended_c / max_allowable_c / ref（版本字串）
    # 回 Score(value, envelope_ref, n_intakes, flagged: bool)

def leak_m3s(dp_pa, area_m2=0.5, c=0.6, rho=1.2) -> float: ...
def evaluate(balance, intakes_c, envelope) -> list[Finding]: ...
```

### 驗收表

五列全過才算完成。

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | `lam=1.75` | `rti ≈ 0.571`；`bp=None` → `recirculation == "unknown"` |
| 2 | `lam=1.75, bp=0.43` | `recirculation ≈ 0.00`（驗證與 dc-22 自洽） |
| 3 | `lam=1.0, bp=0.4` | `rti == 1.0` **且** `recirculation ≈ 0.4` → 吐 `RECIRCULATION_HIGH`，**證明滿分 RTI 不擋這個 Finding** |
| 4 | 39×24 °C ＋ 1×33 °C，2011 A1 | `value ≈ 0.970`、`flagged == True`；**同時**吐 `RCI_DEGRADED` 與 `INTAKE_ABOVE_ALLOWABLE`，兩者不得合併。換 2004 envelope → `≈0.971` 且 `envelope_ref` 不同 |
| 5 | 同上但 200 櫃（199×24 ＋ 1×33） | `value ≈ 0.994`，`flagged` 仍為 True。**加分題**：寫一個 `assert` 拒絕比較 `n_intakes` 不同的兩個 `Score` |

`leak_m3s(20)/leak_m3s(2)` 應 ≈ 3.16 且**與 `area_m2` 無關**——用兩個不同的 area 各跑一次驗證。

## 自我檢核

**Q1. 一間機房量到 RTI = 100%。氣流管理是不是做好了？**

??? note "答案"
    不知道。RTI = 1/λ 只說送風量等於 IT 抽風量，完全沒說空氣去了哪裡。λ = 1、再循環 40% 的機房 RTI 也是 100%（演算二）。要判斷得再有一個獨立量測——三溫度法給的 BP。RTI 是能耗指標，熱環境要看 RCI 與那個星號。

**Q2. 驗收報告寫「RCI_HI = 97%，符合良好設計」。這句話缺了什麼？**

??? note "答案"
    缺三樣。(1) **envelope 版本**：2004 與 2011 的建議上限差 2 K、帶寬差 2 K，同一批溫度算出不同分數，而「良好」的門檻本身在 Herrlin 兩篇文章裡就是 95% 與 96%。(2) **星號**：97% 完全可以同時有機櫃超出允許上限（演算三）。(3) **機櫃數**：分母含 N，同一個危險在 200 櫃房間是 99.4%。

**Q3. 這張卡會讓你的資料模型長出什麼欄位——以及刪掉什麼欄位？**

??? note "答案"
    **刪**：`AirBalance.bypass` 與 `rti` 不再是儲存欄位，降為 `@property`，只存可直接量的 `lam`（＋量得到時的 `bp`）。這是第一次後面的卡刪前面的欄位。
    **長出**：`AirBalance.recirculation` 的第三態 `unknown`（一個量測解不出兩個未知數）；`Score(value, envelope_ref, n_intakes, flagged)` 取代裸 float；`Finding.RCI_DEGRADED` 與 `Finding.INTAKE_ABOVE_ALLOWABLE` 並列；`Setpoint(value, basis, source, commissioned_at)` 給差壓設定值。
