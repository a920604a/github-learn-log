---
id: dc-26b
title: CDU 的額定與可比較性（rating 條件、濾網 ΔP 與水質）
category: cooling
written_at: 2026-09-22
sources:
  - https://blog.se.com/datacenter/2025/12/16/account-for-filtering-too-beware-of-how-cdu-rating-capacity-is-specified/
  - https://www.vertiv.com/4995ec/globalassets/shared/vertiv-coolchip-cdu-600-guide-specifications-sl-80239.pdf
  - https://www.delltechnologies.com/asset/en-us/products/servers/industry-market/liquid-coolants-guidance-for-technology-cooling-system-and-facility-water-system-whitepaper.pdf
  - https://www.brotherfiltration.com/cdu-filter-pressure-drop-budget/
related: [dc-26, dc-19, dc-21, dc-09b, dc-25b, dc-27]
---

# CDU 的額定與可比較性（rating & filtration）

[dc-26](cdu.md) 回答「這台機器怎麼運作」。這張回答下一題：**型錄上那個 1 MW 是什麼條件下量出來的，你憑什麼拿它跟另一家的 1 MW 比。** 答案比想像的糟：標準留了一格給受測方自己填，而那一格恰好是濾網。

## 六格

### 拓撲位置

濾網在 CDU 機殼內，Vertiv CoolChip 原廠規格是**每台泵各一個**——這個細節等一下會把額定值翻掉。**額定本身不在拓撲上**：它跟 [dc-15](power-meter.md) 的 `MeasurementPoint` 一樣是標註不是節點。

### 容量單位

**kPa（TCS 可用外部揚程）與 L/min 是自變數，kW 是因變數。** 濾網吃掉 kPa，掉下來的卻是 kW（演算一）。

### 冗餘表達

Vertiv CDU 600 雙泵、CDU 1350 三泵，皆可配 **run/standby 或全部同時運轉**。濾芯可洗、熱插拔。但泵模式一換，**額定流量與濾網流速判準同時改變**（演算二）。

### 遙測介面

`filter_dp_kpa` 是全機唯一看得見耗材狀態的點位，原廠明說用來回報潔淨狀態並觸發清洗告警。水質三感測（導電度／濁度／pH）走 Modbus RS485——**但是選配**。這修正了 dc-26 的「水質多半離線採樣，不是點位」：可以是點位，要加錢。

### 故障域

堵塞**不是「掉」，是容量慢慢縮，且在任何 kW 報表上看不見**。唯一徵兆是 ΔP 上升，而 ΔP 要對齊流量才能解讀（同 [dc-21](plate-hx-free-cooling.md)）。

### 維護特性

可洗、熱插拔、每泵一個。**ΔP 告警觸發清洗而非日曆觸發**——本軌跡少見的狀態驅動維護規則。

## 關鍵數字與計算

### 演算一：同一台 CDU 兩個都合法的 rated 揚程

Schneider 原文（本次取得第一手）明寫 ASHRAE rating 的前提是「受測 CDU **依廠商指示設置**」，並舉例：若廠商要求測試室測試前拆掉濾網，ratings 會更漂亮。Addendum B 仍在制定中，沒有條文禁止這件事。

設一台 1 MW CDU 標稱可用外部揚程 **300 kPa @ 1591 L/min**（流量取自 dc-26 的 ASHRAE rating 點）。25 µm 濾芯乾淨 ΔP 取 **25 kPa**，更換門檻取 2× = **50 kPa**（假設值）。密閉迴路無靜揚程（[dc-19b](npsh-and-pump-placement.md) 已證），系統阻力 ∝ Q²，故 Q ∝ √(可用揚程)；固定 ΔT 下 kW ∝ Q：

| 測試組態 | 給 TCS 的揚程 | 流量 | 容量 |
|---|---|---|---|
| 濾網拆掉 | 300 kPa | 1591 L/min | **1000 kW** |
| 濾網裝上、乾淨 | 275 | 1523 | **957 kW** |
| 濾網裝上、堵到門檻 | 250 | 1452 | **913 kW** |

**乾淨狀態就差 43 kW（4.3%），堵到門檻共差 87 kW（8.7%）。** 一個 20 櫃 × 45 kW 的 AI 機廳，8.7% 就是接近兩個機櫃。

⚠ 這是把可用揚程當固定值、且假設 ΔT 不變的**一階估算**。真值要照 [dc-19](chilled-water-pump.md) 解泵曲線 × 系統曲線交點，而流量掉了 approach 也會變。

### 演算二：濾網面積被流速判準定死，而判準隨泵模式換分支

Vertiv 原廠規格給了一條硬判準：濾網面積要大到**濾材流速 < 0.5 m/s（1.6 ft/s）**，且零濾材旁通。

- 全流量 1591 L/min = 0.02652 m³/s → **A_min = Q / v = 0.02652 / 0.5 = 0.0530 m²**（530 cm²，等效直徑 26 cm 的圓盤——所以實務上一定是摺疊式）

但濾網是**每泵一個**。雙泵同時運轉時每個只吃一半流量，判準只要 **0.0265 m²**。於是：

**一顆照「雙泵同時運轉」選的 0.0265 m² 濾網，切到 run/standby 時流速變 1.0 m/s，是判準的 2 倍。** 紊流區 ΔP ∝ Q^1.8 → 同一顆濾網的乾淨 ΔP 從 25 kPa 跳到 25 × 2^1.8 = **87 kPa**——**全新濾芯就超過 50 kPa 的更換門檻**。告警規則會說它髒了，而它是新的。

→ `filter_installed: bool` 根本不夠。要的是 `(filter_installed, filter_area_m2, pump_mode)` 三者，缺任一格額定就不可比較。而 `pump_mode` 是**客戶下單時選的**，不是設備常數。

### 演算三：75% 載點不是「容量的 75%」，而 COP 在部分負載會騙你

ASHRAE rating 條件（Schneider 原文）：TCS 流量**在 100% 載點建立後，四個載點（100/75/50/25%）固定不變**；TCS 出水恆 30 °C、FWS 進水恆 26 °C。100% 時 TCS 回水 39.6 °C（ΔT 9.6 K），75% 時回水降到 **37.2 °C**（ΔT 7.2 K）。

7.2 ÷ 9.6 = 0.75 ✓ ——**「75% 容量」是同一流量下回水降到 37.2 °C 時量到的熱量**，不是把機器開到七成五。

後果在 COP 上。設 100% 時 CDU critical input power = 15 kW（泵 13 ＋ 控制 2，假設值）：

| 載點 | rating COP（流量凍結） | 現場 COP（泵降速） | 差距 |
|---|---|---|---|
| 100% | 1000 / 15 = **66.7** | 同上 | — |
| 50% | 500 / 15 = **33.3** | 500 / 5.03 = **99.4** | **3.0×** |
| 25% | 250 / 15 = **16.7** | 250 / 2.71 = **92.3** | **5.5×** |

現場欄用 [dc-19](chilled-water-pump.md) 的指數 2.1（遠端 DP 設定值撐出靜揚程，不是立方）：50% 流量 → 13 × 0.5^2.1 = 3.03 ＋ 2 = 5.03 kW。而 Vertiv 的控制模式正是 TCS 供回壓差決定泵速——就是 dc-19 描述的那個機制。

**ASHRAE 刻意凍結流量是為了可比較性，現場控制邏輯一定變速。所以部分負載的 rating COP 不是預測值，是比較值。** ⚠ 現場欄是上界：冷板有最低流量要求，真實系統降不到與負載成正比。

### 演算四：COP 的分母不含 FWS 泵，而那筆錢真的有人付

Schneider 原文明列：COP = 冷卻容量 ÷ CDU 輸入功率，且**FWS 側泵能耗不計入**。第五個 rating「CDU 引入 FWS 的壓損」就是為了補這個洞，但它跟 COP 是兩欄。

假設兩台 CDU 都標 1000 kW、輸入 15 kW（published COP 皆 66.7），FWS 流量同取 1591 L/min、泵組效率 0.7（假設值）：

- A 機 FWS 壓損 60 kPa → P = 0.02652 × 60000 ÷ 0.7 = **2.27 kW** → 實質 COP = 1000 ÷ 17.27 = **57.9**
- B 機 FWS 壓損 30 kPa → **1.14 kW** → 實質 COP = 1000 ÷ 16.14 = **62.0**

**published COP 兩台一模一樣，實質差 7%，而差額記在 [dc-19](chilled-water-pump.md) 的帳上。** 這是「成本被記到別人的表上」的第一個具體案例。

## 常見誤解

**以為 rating 是第三方量出來的客觀數字，但實際上「依廠商指示設置」是標準自己留的一格。** 廠商可要求拆掉濾網再測，數字就漂亮 4.3–8.7%（演算一），而 Addendum B 仍在制定中、沒有條文禁止。Schneider 的處方是要求揭露測試組態，或加錢做 FAT——原文那句「published ratings rarely match application ratings」值得抄進規格書。

**以為 COP 高就是省電，但實際上分母不含 FWS 側泵。** 一台把壓損丟給設施側的 CDU，published COP 反而好看（演算四）。COP 必須跟「CDU 引入 FWS 的壓損」兩欄一起讀，單看一欄會選到錯的機器。

**以為濾網是耗材、跟容量無關，但實際上它吃的就是容量。** 前 25 張卡的耗材都只住在 `MaintenanceRule` 裡；濾網 ΔP 直接從可用揚程扣，而揚程決定流量、流量決定 kW。**堵塞不會觸發任何 kW 告警，它只是讓紅線悄悄下移。**

## 對資料模型的意涵

1. **`Rating` 第一次要帶「測試時的機器組態」，而其中一格由受測方自選。** → `Rating(kw, head_kpa, standard, version, filter_installed, filter_area_m2, pump_mode, fluid, fluid_temp_c, load_pct, fws_eft_c, tcs_lft_c, tcs_dt_k)`，配 `comparable_to(other)` **回 `False` 而不是發警告**——不可比較的兩個數字不該讓人有機會忽略。這是「值＋出處」家族第七次（前六：[dc-12](rpp-remote-power-panel.md) `derating_basis`、[dc-15](power-meter.md) `accuracy`、[dc-09c](lib-fire-compliance.md) `CodeRule`、[dc-19](chilled-water-pump.md) `Limit.basis`、[dc-21](plate-hx-free-cooling.md) `EfficiencyRating`、[dc-25b](../topics/airflow-management-metrics.md) `Score`），**但第一次出處裡有一項是受測方可調的**。`derating_basis` 也多了第四種來源：不是外殼列名（dc-12）、不是環境溫度（[dc-13](busway-and-tap-off-box.md)）、不是內部導體與斷路器數（[dc-14](rack-pdu.md)），而是**測試室當天有沒有把濾網裝上去**。

2. **`Dimension.consumable_state`：耗材第一次本身就是容量維度。** → `CapacityReport.filter_dp_kpa` ＋ clean baseline。這是**第五個「沒有 commissioning 產出就沒有告警規則」的欄位**（前四：[dc-09b](battery-testing-regime.md) 電池 baseline、dc-19 rate limiter、dc-21 clean ΔP、dc-25b 差壓設定值）。**方向與 dc-21 相反**：dc-21 拿 ΔP 當熱性能的 `proxy_for`，這裡 ΔP 本身就是自變數。

3. **水質限值是 per-loop 的，而二手整理會把兩個迴路攪在一起。** Dell 白皮書（引 ASHRAE TC 9.9 ＋ OCP）的表是兩欄：TCS 的 PG25 是 pH 8.0–10.5、硬度 <50 ppm、氯 **<25** ppm、硫酸鹽 <25、銅 <2、鐵 <2；FWS 的水是 pH **7.0–9.0**、硬度 <200、氯 **<50**、硫化物 <10、硫酸鹽 <100。**我手上原本那份二手筆記寫的「氯 <50、硬度 <30」——氯是 FWS 的值、硬度兩邊都對不上。** → `WaterQualitySpec(loop, param, limit, source, version)`，一個 `chloride_ppm` 欄位裝兩個迴路會錯得非常安靜。

4. **`fluid` 光是模式欄位不夠，物性必須是 `props(fluid, temp_c)`。** [dc-26](cdu.md) 取黏度比 1.8（25 °C 口徑）算出 ΔP ≈ ×1.24；Dell 白皮書給 PG25 在 **20 °C 是 ~2.4 cP**（水約 1.0）→ 比值 2.4 → ×1.32。**差 6 個百分點，而 dc-26 沒有記下求值溫度。** 同一份白皮書順帶驗證了 dc-26 另外兩個假設值：cp ~3.9 kJ/kg·K、ρ 1.03 g/cm³ ✓。另：25 vol% 是**達成抑菌效果的最低濃度**，往上加濃度會同時降低容量、提高泵能耗——`glycol_pct` 是設計參數不是標籤。

## 來源分歧

**（一）濾網孔徑判準差一個數量級。** ASHRAE（經 Schneider 轉述）：孔徑不大於最小微流道尺寸的**一半**（50 µm 流道 → 25 µm）；Vertiv 原廠只給 **25 或 50 µm 兩個選項且是選配**；濾材廠商的整理則給設施側 150–500 µm、TCS 主濾 25–50 µm、冷板側旁流精濾 <5–10 µm。前兩者是設備上真的存在的選項，第三者**未取得 OCP 原文逐條核對，不要寫進規格書**。而演算一證明 ΔP 就是容量，孔徑選錯不只是過濾效果問題。

**（二）水質限值兩份表對不起來。** Dell 白皮書的表**沒有**導電度與菌落欄位，而手上的二手整理有（導電度 <1500 µS/cm、菌落 <100 CFU/mL）。兩份表**不可合併**——合併出來的那張表沒有任何一個來源背書。

**（三）濾網 ΔP 該佔多少預算，沒有標準只有慣例。** 濾材商原文給的是數字例（TCS 500 GPM、泵差壓 12 psi、其他損失 7.5 psi、留給濾網＋餘裕 4.5 psi、乾淨濾網 1.2 psi → 餘裕 3.3；堵到 2.5 psi → 餘裕 2.0）。**「clean ΔP 控制在可用差壓的 20–30%」這句出現在搜尋摘要而非本次抓到的原文頁，不要引用**；不過從它自己的例子反算是 27%（clean）與 56%（loaded），數量級一致。

## 該問 facility 的問題

1. **跟每家廠商要「測試時濾網裝了沒、面積多少、泵哪一種模式」。** 缺這三格，兩份型錄的 kW 不是同一個量（演算一、二）。
2. **CDU 引入 FWS 的壓損多少？** 它不在 COP 裡，卻每天記在 FWS 泵的電費上（演算四）。
3. **濾網 clean ΔP baseline 誰量、在哪個流量下量？** 沒這筆 commissioning 數據，告警門檻只能亂猜。

## 動手練習（30–40 分鐘）

接 [dc-26](cdu.md) 的 `cdu.py`，新增 `rating.py`。**核心目標：讓兩個不可比較的額定值在型別層就拒絕被比較。**

```python
from dataclasses import dataclass

@dataclass(frozen=True)
class Rating:
    kw: float
    head_kpa: float
    standard: str          # "ASHRAE 127"
    version: str           # "2020-AddB-draft"
    filter_installed: bool
    filter_area_m2: float | None
    pump_mode: str         # "simultaneous" | "run_standby"
    fluid: str
    fluid_temp_c: float    # dc-26 漏掉的那一格
    load_pct: float
    fws_eft_c: float
    tcs_lft_c: float
    tcs_dt_k: float

    def comparable_to(self, other: "Rating") -> bool:
        ...                # 任一測試條件不同 -> False，不是 warning

def capacity_from_head(base_kw, base_head_kpa, base_flow_lpm,
                       filter_dp_kpa) -> tuple[float, float]:
    ...                    # 回 (flow_lpm, kw)；Q ∝ sqrt(可用揚程)

def filter_area_ok(flow_lpm, area_m2, pump_mode,
                   v_max_ms=0.5) -> tuple[bool, float]:
    ...                    # 回 (是否合格, 實際流速)；pump_mode 決定每個濾網分到多少流量

def effective_cop(kw, cdu_input_kw, fws_dp_kpa, fws_flow_lpm,
                  pump_eff=0.70) -> float: ...
```

### 驗收表

五列全過才算完成。

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | `capacity_from_head(1000, 300, 1591, 0)` / `(…, 25)` / `(…, 50)` | **1000** / **957** / **913 kW**（±2） |
| 2 | 兩個 `Rating` 只差 `filter_installed` | `comparable_to` → **False** |
| 3 | `filter_area_ok(1591, 0.0265, "simultaneous")` vs `(…, "run_standby")` | **(True, 0.5)** vs **(False, 1.0)**——同一顆濾網兩個答案 |
| 4 | 承上，run_standby 的 clean ΔP＝25 × (1.0/0.5)^1.8 | ≈ **87 kPa**，**超過 50 kPa 更換門檻** |
| 5 | `effective_cop(1000, 15, 60, 1591)` vs `(…, 30, …)` | ≈ **57.9** vs **62.0**（published 皆 66.7） |

**加分題**：把 `Rating` 套回 dc-26 那張 ride-through 階梯與 dc-21 的 `EfficiencyRating`，看看有幾筆**填不出 `version`**。填不出來的那幾筆，就是當時只有二手轉述的地方。

## 自我檢核

**Q1. 兩家廠商都標 1 MW、300 kPa。你只能問一個問題來分辨哪家灌水，問什麼？**

??? note "答案"
    「測試時濾網裝上去了嗎？面積多少？」。ASHRAE rating 的前提是「依廠商指示設置」，拆掉濾網測出來的 300 kPa 全部給 TCS，裝上去要先扣 25 kPa（乾淨）→ 實際容量 957 kW。堵到更換門檻只剩 913 kW（演算一）。而面積不問清楚，泵模式一換流速就翻倍、ΔP 變 3.5 倍（演算二）。

**Q2. 濾網堵了，你的容量儀表板會變什麼顏色？**

??? note "答案"
    **不會變。** 堵塞吃掉的是可用揚程，掉下來的是流量與 kW 紅線，而儀表板顯示的是「目前負載 ÷ 銘牌容量」——分母是那個沒扣濾網的銘牌值。唯一的徵兆是 `filter_dp_kpa` 上升，而它要對齊流量才能解讀（同 [dc-21](plate-hx-free-cooling.md)）。這是 W38 母題「綠燈的四種死法」的第五種：**分母本身在變小而沒有人更新它。**

**Q3. 這張卡會讓你的資料模型長出什麼欄位？**

??? note "答案"
    四類。(1) **`Rating(..., filter_installed, filter_area_m2, pump_mode, fluid_temp_c, ...)` ＋ `comparable_to()` 回 `False`**——「值＋出處」家族第七次，第一次出處裡有一項是受測方可調的。(2) **`Dimension.consumable_state` ＋ `CapacityReport.filter_dp_kpa` ＋ clean baseline**，第五個「沒有 commissioning 產出就沒有告警規則」的欄位。(3) **`WaterQualitySpec(loop, param, limit, source, version)`**——TCS 氯 <25、FWS 氯 <50，一個 `chloride_ppm` 欄位裝不下兩個迴路。(4) **`props(fluid, temp_c)`**：[dc-26](cdu.md) 的 `fluid` 是模式欄位還不夠，黏度比 1.8（25 °C）與 2.4（20 °C）算出的 ΔP 差 6 個百分點，**求值溫度必須跟著存**。
