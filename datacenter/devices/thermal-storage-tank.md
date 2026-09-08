---
id: dc-20
title: 儲冷槽（thermal storage tank）與 ride-through
category: cooling
written_at: 2026-09-08
sources:
  - https://www.azuraconsultancy.com/wise-efficient-use-of-thermal-energy-storage-tanks-in-data-centers/
  - https://www.azuraconsultancy.com/thermal-energy-storage-diffuser-design-and-cfd-verification/
  - https://www.relres.com/news/79/thermal-storage-for-data-centers
  - https://uptimeinstitute.com/resources/asset/accredited-tier-designer-technical-paper-series-continuous-cooling
related: [dc-18, dc-19, dc-09, dc-22]
---

# 儲冷槽（thermal storage tank / TES tank）

一個裝滿冰水的大桶子，冷水沉在下面、溫水浮在上面，中間一層過渡帶叫 **thermocline（溫躍層）**。冰機正常時把它充滿；冰機掉了，就靠這桶水撐到發電機起來、冰機重啟為止。它是 [dc-18](chiller.md) 那條 ride-through 假設的實體。

## 六格

**拓撲位置**｜熱側：上游[冰機](chiller.md)（充）／下游二次側環路（放），掛在一次與二次環路的解耦位置。常壓開放式時**同時是定壓點與膨脹箱**，要高於最高盤管 ≥ 2 m；放地下室需維持閥＋專用泵。電側：**它自己不耗電**，卻強迫電力樹長出一片新葉子（專用小泵必須掛 UPS，承 [dc-19](chilled-water-pump.md) 的 +5.6%）——第一個「在熱樹上是節點、在電樹上不是、卻改變電樹容量」的設備。

**容量單位**｜**兩個獨立維度**：能量 kWh_th／RT-hr（撐多久）＋ 功率 kW（供不供得上）。銘牌是幾何容積；可用能量 = V × ρ·c_p·ΔT × `usable_fraction`，而後者要用溫度陣列量，不是設計值。

**冗餘表達**｜**第一個冗餘無法靠加大單體達成的設備。** 兩倍大的槽仍是單一容器。只能多槽並聯，管路與控制也要 concurrently maintainable。N+1 在這裡是「多一個容器」不是「多存一份水」。

**遙測介面**｜BACnet / Modbus，關鍵在**陣列**不是單點。

| 點位 | 型別 | 備註 |
|---|---|---|
| `T[1..n]` 沿高度溫度 | 有序陣列 | 間距 300–600 mm；頂底兩點量不出 thermocline |
| 進／出水溫、流量、閥位 | 純量 | 充放電功率的實測來源 |
| `thermocline_position` / `_thickness` | 推導 | 取梯度極值；厚度是劣化指標 |
| `tilt` | 推導 | 需 ≥ 2 方位陣列；配水不均首發症狀 |
| `soc` | 推導 | 剖面積分，**不是** thermocline 位置 |

**故障域**｜**隱性故障**：槽失效時穩態運轉毫無異狀，事故當天才發現沒東西可用。若又兼定壓點，破管會從「沒有 ride-through」升級成「立刻停冷」。唯一能證明它有效的是放電測試。

**維護特性**｜水質／清洗、保溫（牆底頂 ≥ 100 mm）、感測器校正。熱損約 **1%/day**。放電測試做完要數小時充回，**期間 ride-through 是降級的**——維護動作本身製造脆弱窗口。

## 關鍵數字與計算

沿用 dc-18／dc-19 的同一座廠：負載 **1 600 kW**，冰水 7/13 °C（ΔT = 6 K），目標撐 **15 分鐘**。

### 一、為什麼非要水不可

完全失去冷卻時，機房 1 000 m² × 4 m = 4 000 m³ 空氣（4 800 kg，熱容 4 824 kJ/K）：`1600 ÷ 4824 = 0.332 K/s = 19.9 K/min`。ASHRAE TC 9.9 對非磁帶 IT 的門檻是 **≤ 20 °C/hr 且任 15 分鐘內 ≤ 5 °C**（磁帶 ≤ 5 °C/hr）。**5 K 在 15 秒內用完，超標 60 倍。** 空氣的熱質量在這尺度等於零——這就是儲冷槽存在的理由。

### 二、能量法（撐多久）

```
E = 1600 kW × 900 s = 1 440 000 kJ = 400 kWh_th = 113.7 RT-hr
V = E / (ρ·c_p·ΔT) = 1 440 000 / (1000 × 4.186 × 6) = 57.3 m³
```

與 [dc-18](chiller.md) 算的 57 m³ 一致。但 **57.3 m³ 是「水」不是「槽」**：冷、溫擴散器各約 450 mm，thermocline 典型 600 mm，合計 **約 1.5 m 不可用水柱**。

| 槽型 | 高 H | 不可用比例 | `usable_fraction` | 幾何容積 V_geo |
|---|---|---|---|---|
| 細高 | 10 m | 1.5/10 = 15% | 85% | 57.3/0.85 = **67.4 m³**（D ≈ 2.93 m）|
| 矮胖 | 4 m | 1.5/4 = 37.5% | 62.5% | 57.3/0.625 = **91.7 m³**（D ≈ 5.40 m）|

**同一個 400 kWh_th 需求，槽從 10 m 高改成 4 m 高，要多裝 36% 的水。** `usable_fraction` 是幾何的函數，不是 0.9 這種常數（85% 落在來源給的「80–90%」內，自洽）。

### 三、功率法（供不供得上）

擴散器不能想放多快就放多快，判準是**入口 Froude 數**與**入口 Reynolds 數**（Wildin 的設計程序），其中 `q` 是單位擴散器長度的流量（m²/s）、`h` 是開口高：

```
Fr = q / √(g'·h³) ，g' = g·Δρ/ρ           Re = q / ν
7 vs 13 °C：Δρ/ρ ≈ 5.2e-4 → g' = 5.10e-3 m/s²；取 h = 0.15 m
√(g'·h³) = 4.149e-3  →  Fr≤0.5: q ≤ 2.075e-3 ｜ Fr≤1.0: q ≤ 4.149e-3
                        Re≤2000: q ≤ 2000 × 1.31e-6 = 2.62e-3
```

需求流量 `Q = 1600/(4.186×6) = 63.7 L/s = 0.0637 m³/s`。單環擴散器的長度就是圓周：

| 槽型 | 擴散器長 L | 判準 | 可放出功率 | 用率（需 1 600 kW）|
|---|---|---|---|---|
| 細高 D=2.93 | 9.2 m | Fr ≤ 0.5 | **480 kW** | 334% 🔴 |
| 細高 D=2.93 | 9.2 m | Re ≤ 2000 | 606 kW | 264% 🔴 |
| 矮胖 D=5.40 | 17.0 m | Fr ≤ 0.5 | **884 kW** | 181% 🔴 |
| 矮胖 D=5.40 | 17.0 m | Fr ≤ 1.0 | 1 768 kW | **90% 🟢** |
| 矮胖 D=5.40 | 17.0 m | Re ≤ 2000 | **1 116 kW** | 143% 🔴 |

三個結論：**(1)** 細高槽存得下 400 kWh，功率維度卻已 334%——**一個 `capacity` 欄位表達不了兩個維度**。**(2)** 矮胖槽雖要多裝 36% 的水，卻是唯一有機會過的，因為 Fr ∝ 1/L。**(3) binding 是誰取決於採哪套判準**：Fr ≤ 1.0 → binding 是 Re（1 116 kW）；Fr ≤ 0.5 → binding 是 Fr（884 kW）。**兩者處置方向相反**：Fr 擋住 → 加大開口 h（Fr ∝ h^−1.5）；Re 擋住 → 只能加長 L（Re 與 h 無關）。**修錯地方等於白花錢。**

### 四、迭代：兩個約束互相咬

要讓矮胖槽同時過 Fr ≤ 0.5 與 Re ≤ 2000，需 `L ≥ 0.0637/2.62e-3 = 24.3 m`（單環只有 17 m → 得做雙環或分歧管），並把 h 從 0.15 加到 0.22 m（此時 Fr = 0.35 ✅、Re = 2000 ✅）。但 h 加大 0.07 m × 兩個擴散器 = 不可用高度 1.5 → 1.64 m，4 m 槽的 `usable_fraction` 從 62.5% 掉到 59% → V_geo 從 91.7 變 **97.1 m³（+6%）**。

**為了讓功率過關而加大擴散器，回頭吃掉可用比例，於是能量要多存，於是槽更大。** 繼 [dc-18](chiller.md) 的運轉態聯立之後，**dc-20 是第二個要迭代的設備——這次迭代的是設計參數，不是運轉狀態。**

### 五、熱損：thermocline 沒動，容量卻掉了

1%/day = 4 kWh/day；把 57.3 t 冷層升溫 0.5 K 要 `57 300 × 4.186 × 0.5 = 33.3 kWh` → **約 8.3 天**。之後 ΔT 從 6.0 掉到 5.5 K，可用能量 400 → 367 kWh，ride-through **15 → 13.75 分鐘**。而 **thermocline 位置一格都沒動，SoC 顯示 100%。**

### 六、地區差異（經濟面）

美規的動機通常是尖峰需量電費；台灣查到的是**台電對儲冷式空調系統的冷凍機及附帶用電器具，離峰流動電費按適用電價 60% 計收**——但**只有二手轉述，未在原文查證**。若成立，槽就從「只做 ride-through 的保險」變成「每天充放的省錢工具」，兩種用法的 SoC 下限完全不同。

## 來源分歧

**分歧一：Fr 與 Re 的判準值。** ASHRAE（HVAC Applications）給 **Fr < 1.0**，業界實務收緊到 **Fr < 0.5** 以求更薄的 thermocline。Re 更亂：一般引用 **< 2000**，也有說法指出**短槽應接近 200，深度 > 12.2 m 才用 2000**——亦即 **Re 上限本身是槽高的函數**，又一個「`Limit` 不是常數是函數」（同 [dc-19](chilled-water-pump.md) 的 `min_flow`）。後果如上表：**binding 換人，處置方向相反。**

**分歧二：該做多大——10–15 分鐘 vs 4 小時 vs 8 小時。** 三方講的不是同一件事：Azura 說**慣例是 10–15 分鐘**、主張改做 4 小時（4 000 kW IT → 5 600 kW 冷卻 × 4 h = 22 400 kWh = 6 370 RT-hr）兼做削峰；Reliable Resources 說**最多可提供 8 小時**（能力上限不是需求）；Uptime Tier IV 要的是「機械系統完整重啟並回到額定出力所需的時間」且該期間任何 15 分鐘符合 ASHRAE 熱指引——**是推導值不是固定數字**。→ `ride_through_target_s` **必須記 basis**，否則審查時三方各講各的都「有出處」。

**分歧三：適用範圍。** 一致的是 **Tier IV 是唯一明文要求 continuous cooling 的等級**；分歧在 Tier III——顧問文說 Uptime 對 >5 kW/rack「高度建議」裝 TES，但建議不是條文，合規論述裡不能混談。

## 常見誤解

**以為容量就是「體積 × ΔT」那個數字，但實際上那只是能量上限，旁邊還有一個完全獨立的功率上限。** 細高槽存得下 400 kWh_th（能量 100%），擴散器卻只放得出 480 kW（功率 334%）——不是撐不到 15 分鐘，是撐 0 秒。

**以為 thermocline 沒動就代表 SoC 100%，但實際上熱損是均勻升溫，位置不動容量照掉。** 1%/day 約 8 天把冷層從 7.0 推到 7.5 °C，ΔT 6 → 5.5 K，ride-through 15 → 13.75 分鐘，而位置一格沒動、儀表全綠。只判位置的告警永遠不會響。

**以為「放得急只是放得快」，但實際上放得急會把 Fr 推高、thermocline 變厚，下一次能用的就變少。** 第一個**容量隨使用強度自我劣化**的設備：[dc-17](cooling-tower.md) 讓容量成為環境的函數、[dc-18](chiller.md) 讓它要解聯立，這裡讓它成為**路徑的函數**。

## 對資料模型的意涵

1. **`Dimension` 第一次要成對：`kind = "power" | "energy"`。** 前 19 張所有維度都是速率（kW、A、L/min、kVA）。儲冷槽同時受兩者約束且互相獨立。`binding()` 在 [dc-17](cooling-tower.md) 已經 per-resource，現在還要 **per-kind**，且兩種 `Finding` 處置不同：能量不足＝撐不夠久，功率不足＝**撐 0 秒**。
2. **`usable_fraction` 是三個不同 basis 的推導值，且會時變。** 扣除項來自擴散器死區（幾何）、thermocline 厚度（量測）、實際達成 ΔT（運轉），而厚度會隨循環變大 → basis 這次要指向**量測結果**而非文件（延續 [dc-12](rpp-remote-power-panel.md) 的 `derating_basis`）。
3. **`MeasurementPoint` 要有陣列型別。** SoC 是沿高度的**有序**溫度剖面積分出來的，不是一個點位；頂底兩點也量不到 tilt。→ `SensorArray(positions_m, values)`，`soc` 要記 `derived_from` 與演算法版本（同 [dc-17](cooling-tower.md) 的 `SiteEnvironment`）。
4. **告警規則要把「絕對溫度」與「thermocline 位置」分開判**，兩者都在門檻內才算綠——否則熱損造成的 8% 衰退不會響。
5. **容量是路徑的函數 → `CapacityReport` 要有 `recovery_until`。** 放電後充回期間第二次事件不可存活，放電測試本身也開一樣的窗口。第一個「昨天做了什麼」會改變今天容量的設備，也是 [dc-18](chiller.md) `TransientScenario` 的另一半。

## 該問 facility 的問題

1. **ride-through 目標是幾分鐘，basis 是哪一種？** 慣例 10–15 分？冰機實測重啟時間？還是 ASHRAE 15 分鐘變溫率反推？[dc-18](chiller.md) 的 Cundall 案例說重啟時間是回水溫的函數，「型錄寫 5 分鐘」不能當答案。
2. **擴散器的 Fr 判準用 1.0 還是 0.5？有沒有 CFD 驗收？報告裡 thermocline 幾 mm？** 這一個數字決定 `usable_fraction` 是 85% 還是 62%。
3. **溫度感測是幾點、間距多少、有沒有量 tilt？** 只有頂底兩點的話上面第 4 條告警規則寫不出來。另問：有沒有申請儲冷式空調的離峰優惠——那決定 SoC 下限要不要另外守。

## 動手練習（35 分鐘）

昨天 [dc-19](chilled-water-pump.md) 做出了 `Dimension.aggregation` 與 `RateConstraint`。今天加上 **`kind` 這一維，並讓 `binding()` per-(resource, kind) 回傳**，用本卡兩個槽型跑出「能量過、功率不過」。

```python
@dataclass(frozen=True)
class Limit:
    value: float
    basis: str        # froude_0.5 | froude_1.0 | reynolds_2000 | geometry
    source: str

@dataclass
class Dimension:
    name: str
    resource: str     # thermal | electrical | water
    kind: str         # NEW: power | energy
    unit: str         # kW | kWh
    value: float
    limits: list[Limit] = field(default_factory=list)

    def binding_limit(self) -> Limit:      # 多上界取最小（dc-19 立的）
        return min(self.limits, key=lambda L: L.value)

CP, NU, G_PRIME = 4.186, 1.31e-6, 9.81 * 5.2e-4    # kJ/kg·K ; m²/s ; 7 vs 13 °C

def q_max(h, criterion): ...   # froude: Fr·√(G_PRIME·h³)；reynolds: Re·NU

def tank_dims(height_m, diameter_m, h_open, dT, load_kw, duration_s):
    """回傳 [能量 Dimension, 功率 Dimension]；功率的三條 limits 全掛上，
    讓 binding_limit() 自己挑"""

def binding(dims) -> dict[tuple[str, str], Dimension]:
    """key = (resource, kind)。跨 kind 比大小沒有意義——kWh 不能跟 kW 比"""
```

驗收表：

| 槽型 | H / D | L | 能量 | 功率 | binding basis |
|---|---|---|---|---|---|
| 細高 | 10 / 2.93 | 9.2 m | 400/400 kWh，100% | 1600/480 kW，**334%** | `froude_0.5` |
| 矮胖 | 4 / 5.40 | 17.0 m | 400/400 kWh，100% | 1600/884 kW，**181%** | `froude_0.5` |
| 矮胖＋ASHRAE | 4 / 5.40 | 17.0 m | 100% | 1600/1116 kW，**143%** | `reynolds_2000` |

**驗收重點不是數字對，是三件事成立**：(a) 能量與功率**分開回報**，不被壓成一個百分比；(b) 換判準時 `binding basis` 會**換人**；(c) 兩個 kind 沒有被拿來比大小。

加分題（10 分鐘）：寫 `solve_geometry(load_kw, duration_s, height_m)` 把第四節的迭代跑出來——加大 h → 死區變高 → `usable_fraction` 下降 → V_geo 上升 → L 變長 → Fr 又鬆了。**看它幾次收斂，有沒有某個 H 讓它根本不收斂。**

## 自我檢核

**Q1. 一個 67 m³ 的槽存得下 400 kWh_th，為什麼還是撐不住 1 600 kW 的負載 15 分鐘？**

??? note "答案"
    能量與功率是兩個獨立約束。入口 Froude 數限制單位擴散器長度的流量，細高槽圓周只有 9.2 m，Fr ≤ 0.5 時最多放 480 kW——**不是撐不到 15 分鐘，是一開始就供不上**。能量維度 100% 的同時功率維度已經 334%。這也是為什麼矮胖槽雖然要多裝 36% 的水，卻是唯一可能過的。

**Q2. 熱損造成的容量衰退，會讓資料模型長出什麼欄位與什麼告警規則？**

??? note "答案"
    熱損是**均勻升溫**不是 thermocline 移動：冷層 7.0 → 7.5 °C（約 8 天），ΔT 6 → 5.5 K，ride-through 15 → 13.75 分鐘，而位置與 SoC 都正常。所以 (a) `SensorArray` 要留絕對溫度不能只留推導值；(b) `cold_layer_temp` 要有獨立的絕對值門檻，與 `thermocline_position` 分開判、兩者皆綠才算綠；(c) `usable_energy` 要用**實測 ΔT** 重算——沿用 [dc-15](power-meter.md) 的 `Method.measured`。

**Q3. 為什麼這是第一個「冗餘不能靠加大單體達成」的設備？**

??? note "答案"
    前 19 張的容量冗餘多半能靠放大或並聯同型設備解決（多一台冰機、多一組電池串）。儲冷槽的能量確實隨體積線性長，但**容器本身是單一故障點**：破管、汙染、清洗停用時 ride-through 一次歸零，而且是隱性的——穩態運轉看不出來。所以 `RedundancyPolicy` 除了 [dc-18](chiller.md) 的熱備／冷備，還要能表達「同一標籤下容器數 ≠ 容量份數」。

## 未查證

- **台電對儲冷式空調的離峰優惠（流動電費按 60% 計收）。** 只有二手轉述，台電電價表原文與 Q&A 頁本次都抓不到，**不要直接引用**。
- 機房 1 000 m² × 4 m、擴散器各 450 mm、thermocline 600 mm、h = 0.15 m、熱損 1%/day 全是**典型值或假設值**，只用來把公式走通；實際數字要跟廠商與 CFD 驗收報告拿。
- 「Fr ∝ h^−1.5」由定義直接推，未考慮擴散器型式差異（環形孔口／穿孔管格柵／徑向底盤的有效開口定義不同）。

## 相關概念

上游 [冰水主機](chiller.md)、[冷卻水塔](cooling-tower.md)；ride-through 鏈上的 [冰水泵](chilled-water-pump.md)、[UPS](ups-double-conversion.md)、[電池組](ups-battery.md)；下游 `dc-22`。量測面 [電錶](power-meter.md)。主題卡 `topic-01`／`topic-04`／`topic-05`／`topic-08`。
