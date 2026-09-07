---
id: dc-19
title: 一次側／二次側冰水泵（primary / secondary pump）
category: cooling
written_at: 2026-09-07
sources:
  - https://docs.johnsoncontrols.com/chillers/api/khub/documents/J0n4M7IPtbVDbIZKQKeWFQ/content
  - https://www.trane.com/content/dam/Trane/Commercial/global/learning-center/ashrae-articles/Variable-Primary-Flow%20Systems.pdf
  - https://mepacademy.com/chilled-water-pumping-options/
  - https://www.tekworx.us/blog/pumping-up-efficiency-variable-primary-chilled-water-systems-explained/
  - https://www.sciencedirect.com/science/article/pii/S1359431123014941
  - https://journal.uptimeinstitute.com/implications-of-economizers-in-tier-certified-data-centers/
  - https://www.ashrae.org/file%20library/technical%20resources/standards%20and%20guidelines/standards%20addenda/90_1_2019_bt_20220630.pdf
related: [dc-17, dc-18, dc-20, dc-22, dc-08, dc-16]
---

# 一次側／二次側冰水泵（primary / secondary pump）

[冰機](chiller.md)產生的冷量存在冰水裡，但**冷量不會自己走路**。泵把它送到機櫃、再把熱端回水拖回蒸發器。它是整條冷卻鏈上功率最小、卻能在**幾秒內**把整座機房打掉的設備——冰機失去流量的反應是跳脫，不是降載。[dc-18](chiller.md) 那段 ride-through 整段建立在「泵在 UPS 上」這個假設，今天查證它的代價。

## 六格

### 拓撲位置
`dc-22` CRAH／`dc-26` CDU 回水 → **二次側泵** → 共通管（decoupler）→ **一次側泵** → 冰機蒸發器。VPF 把兩組合成一組，靠旁通閥保最小流量。同時是**電力樹上的葉負載**。

### 容量單位
**流量（L/s 或 gpm）＋ 揚程（m 或 ft），缺一不可。** 泵的容量不是一個數是一條曲線；運轉點 = 泵曲線 ∩ 系統曲線。銘牌流量的完整讀法是「在銘牌揚程下的流量」。

### 冗餘表達
**專用（dedicated）**——每台冰機綁一台泵，泵掉等於冰機掉；**集管（headered）**——任一台可餵任一台冰機，N+1 多一台即可。台數冗餘 ≠ 流量冗餘（見第 3 節）。2N 做在兩組獨立環路。

### 遙測介面
VFD 走 BACnet/IP 或 Modbus TCP 上 BMS（`dc-38`）。

| 點位 | 為什麼要 |
|---|---|
| 轉速 Hz、輸出 kW | 算實際運轉點；VFD 是最便宜的電錶 |
| 遠端 DP 與設定值 | 泵速的被控變數；設定值決定系統曲線的靜揚程 |
| 環路流量計 | VPF 最小流量保護靠它；[dc-15](power-meter.md) 的誤差帶問題原封搬到水側 |
| **共通管流向** | 逆流 = deficit flow = 低 ΔT 症候群發作 |
| 吸入／吐出壓力、旁通閥開度、運轉時數 | NPSH 餘裕與濾網堵塞；最小流量是否靠旁通硬撐；備援泵有沒有真的輪替 |

（**NPSH 與泵的擺放高度**本卡未展開：冰水閉式環路加壓後餘裕充足，但水塔集水盤是開放水面、泵擺在塔上方就逼近 NPSHr——最自然的一張補充卡。）

### 故障域
**秒級，比冰機還快。** 泵掉 → 流量開關動作 → 冰機低流量跳脫，再走完 [dc-18](chiller.md) 的重啟程序（10–15 分鐘），而 ride-through 只有 5.2 分鐘。**冰水還在管裡不等於冷量到得了機櫃。**

### 維護特性
軸封更換、軸承潤滑、對心、濾網清洗。有隔離閥＋備援泵可線上更換，但**抽出泵殼要排掉那一段水**——停機範圍由隔離閥位置決定，不是泵決定。

## 關鍵數字與計算

沿用 [dc-17](cooling-tower.md)／[dc-18](chiller.md) 的機房：IT **1 600 kW**（455 RT），冰水 7/12 °C（ΔT = 5 K）。

### 1. 流量與軸功率（兩套單位互相驗算）

```
Q = P / (ρ · c · ΔT) = 1600 / (4.187 × 5) = 76.4 kg/s ≈ 76.4 L/s = 1 212 gpm
```

美制對照 `gpm = tons × 24 / ΔT(°F)`：ΔT 5 K = 9 °F → `455 × 24 / 9 = 1 213 gpm` ✓

取總揚程 H = 30 m（98.4 ft），泵效率 0.80、馬達 0.94：

```
P_shaft = ρgQH/η = 999.7 × 9.81 × 0.0764 × 30 / 0.80 = 28.1 kW
BHP     = gpm × ft / (3960 × η) = 1212 × 98.4 / (3960 × 0.80) = 37.6 hp = 28.1 kW ✓
電端     = 28.1 / 0.94 = 29.9 kW  →  24.7 W/gpm
```

對照 ASHRAE 90.1 附錄 G 冰水基準（一次側 9 ＋ 二次側 13 = **22 W/gpm，全部冰水泵的合計**）：一台泵就 24.7 W/gpm，把預算吃光——30 m 揚程對這規模偏高。台灣未查到對應門檻。

### 2. 親和定律的指數是擬合值，不是 3

流量降到 60%：

| 假設 | 指數 | 功率比 | 28.1 kW 變成 |
|---|---|---|---|
| 教科書立方 | 3.00 | 0.216 | 6.07 kW |
| Trane 實測擬合 | 2.85 | 0.233 | 6.55 kW |
| **含靜揚程的真實系統** | **≈ 2.09** | **0.344** | **9.67 kW** |

第三列才是重點。系統曲線 `H = H_static + kQ²`，`H_static` 由**遠端 DP 設定值**撐著（設 10 m of 30 m）。60% 流量時 `H = 10 + 20 × 0.36 = 17.2 m`，不是立方假設隱含的 10.8 m；功率 ∝ Q×H = `0.6 × 17.2/30 = 0.344`，反推指數 2.09。

**用立方公式報節能會高估 59%**（6.07 vs 9.67 kW）。而 DP 設定值是控制參數不是硬體參數——調它就改了這台泵的指數。

### 3. 兩台並聯不是兩倍流量

系統 `H = 10 + 0.003422 Q²`，單台泵曲線 `H = 39 − 0.001540 Q_p²`（兩者都通過設計點 76.4 L/s @ 30 m）。兩台並聯 `Q = 2Q_p`：

```
39 − 0.001540 Q_p² = 10 + 0.003422 × (2Q_p)²
29 = 0.015228 Q_p²  →  Q_p = 43.6 L/s
總流量 = 87.3 L/s（+14.2%），揚程升到 36.1 m
每台功率 = 9807 × 0.0436 × 36.1 / 0.80 = 19.3 kW，兩台 = 38.6 kW（+37%）
```

**多開一台泵：流量 +14%，電 +37%。** 把兩台銘牌流量相加（152.9 L/s）高估實際 **75%**——這跟 [dc-16](dual-corded-equipment.md) 記下的 NetBox 斷點是**同一種錯誤在水側再犯一次**：把冗餘設備的銘牌值當可加量。（每台跑 57% 設計流量已偏離最佳效率點，38.6 kW 是樂觀值。）

### 4. 最小流量是**負載的函數**，不是常數

Johnson Controls 160.00-AD9：滿載最小流量對應管內流速 3 ft/s；**負載每降 10% 最小流量跟著降 10%，但在 50% 負載觸底**（1.5 ft/s），再低也不能更低。原廠例子：

| 蒸發器負載 | 最小流量 | 管內流速 |
|---|---|---|
| 100% | 320 gpm | 3.0 ft/s |
| 70% | 224 gpm | 2.1 ft/s |
| 50%（及以下） | **157 gpm**（觸底） | 1.5 ft/s |

套到我們三台冰機（各設計 404 gpm、滿載最小 162 gpm）：70% 負載時 113 gpm；30% 負載時**不是 49 而是 81 gpm**。寫成線性外推的程式，低負載時旁通閥會開太小 → 低壓跳脫，長期凍裂管束。**這是一個寫錯會弄壞硬體的欄位。**

上界則有**兩個來源不同的限制**：管內流速 12 ft/s（侵蝕與熱傳）與**水箱隔板墊片壓降 22.5 ft H₂O／每 pass**（純機械；兩 pass 機 = 45 ft = 134.5 kPa）。哪個先 binding 看機型，不能只存一個 `max_flow`。

### 5. 流量變化率：第一個約束在「時間導數」上的量

1 212 gpm 從 100% 降到 40%（降幅 485 gpm）：

| 速率上限 | 允許耗時 |
|---|---|
| 10%/min（121 gpm/min） | **4.0 分鐘** |
| 30%/min（364 gpm/min） | 1.3 分鐘 |

一整排機櫃斷電時 CRAH 二通閥一起關、遠端 DP 衝高，控制器會要求泵**立刻**減速。rate limiter 沒設或設錯 → 泵幾秒內掉下去 → 冰機低流量跳脫 → 10–15 分鐘才回得來，而 ride-through 只有 5.2 分鐘。**一個住在控制序列裡、銘牌上完全看不到的參數，能把整座機房打掉。**

### 6. 掛 UPS 的代價（回答 dc-18 的假設）

三台 30 kW 泵 = 90 kW。原本只餵 IT 的 [UPS](ups-double-conversion.md) 從 1 600 kW 變 1 690 kW（**+5.6%**），10 分鐘 runtime 掉到約 9.5 分鐘（線性近似；[電池](ups-battery.md)的 Peukert 效應讓實際更短）。而且**只掛泵不夠**——CRAH 風扇不在 UPS 上，水冷了也送不進機櫃。Uptime 的 Tier IV 是唯一明文要求 continuous cooling 的等級，業界作法正是「小型冰水泵掛 UPS ＋ `dc-20` 儲冷槽」。

**這是本軌跡第一次「為了熱側的可用性去吃電側的容量」。** [dc-17](cooling-tower.md) 建立的兩棵樹橫向邊，今天變成雙向。

## 常見誤解

**以為兩台泵並聯給兩倍流量，但實際上只給 1.1–1.3 倍。** 系統阻力隨流量平方上升，流量一多揚程就爬，把每台泵推回曲線左邊（第 3 節：+14.2% 流量、+37% 電）。備援泵保的是「壞一台還有流量」，不是加大流量。

**以為最小流量是設備上一個固定數字，但實際上它是蒸發器負載的函數而且有地板。** 70% 負載時是滿載值的 70%，30% 負載時仍是 50% 那格的值。線性外推會凍裂管束；寫成常數則部分負載時白白多跑旁通、多燒泵電。

**以為泵掉了冰機還能撐一下，但實際上流量一停冰機幾秒內就跳。** 電側有 UPS 撐、有 [STS](static-transfer-switch.md) 的 4–8 ms 切換窗；水側沒有等價物，唯一的「電池」是管內水的熱容量，而它需要**泵還在轉**才拿得到。

## 對資料模型的意涵

1. **`Pump` 的容量不能是 scalar，解法也跟 [dc-18](chiller.md) 不同。** 運轉點是兩條曲線的交點，但有**封閉解**（二次式）不需迭代 → `Method` 的 `curve` 要分得出「查曲線」與「解交點」，`converged` 對這條路徑不適用。

2. **聚合方式必須是欄位（`Dimension.aggregation`）。** 已有三種：`sum`（[dc-12](rpp-remote-power-panel.md) 分路）、`vector_sum`（[dc-14](rack-pdu.md) delta 相電流）、`parallel_pump`（今天）。程式裡任何一處寫死 `sum(...)` 都是還沒發現的 bug。

3. **`Constraint` 第一次要作用在時間導數上。** 前 18 張卡所有約束都是 `value ≤ limit`；流量變化率是 `|d(value)/dt| ≤ limit`。而且它住在 **BMS 控制序列**裡不在銘牌上 → 沿用 [dc-16](dual-corded-equipment.md) 的 `psu_policy` 模式，帶 `source="bms_sequence"` ＋ `fetched_at`，被改動時重算。

4. **`Limit` 要帶 `basis`，且同一個維度可以有多個上界。** 蒸發器最大流量同時受管內流速（12 ft/s，熱傳／侵蝕）與水箱墊片壓降（22.5 ft H₂O/pass，機械破壞）約束，來源與後果完全不同。這是 `derating_basis`（dc-12）、`accuracy`（[dc-15](power-meter.md)）之後第三個「不能是列舉、要能指向文件」的欄位。

5. **`on_ups: bool` 在冷卻設備上會改寫電側的容量報表**（負載 +5.6%、runtime −5%）。電力樹的葉負載清單**必須包含冷卻設備**，否則 UPS 的 `CapacityReport` 是錯的。

## 該問 facility 的問題

1. 我們是 VPF 還是一次側／二次側？若是 VPF，旁通閥最小流量設定值是多少、依據哪張廠商表的哪一列？（真正想知道的是有沒有人算過部分負載那一段）
2. **BMS 的流量變化率限制器設多少 %/min？誰在 commissioning 時定的、有沒有紀錄？**（分歧見下）
3. 冰水泵、冷卻水泵、CRAH 風扇哪些在 UPS 上？UPS 容量報表有沒有把它們算進負載？

## 來源分歧

**（一）流量變化率上限：10%/min vs 30%/min。**
Trane（HPAC 2000）：需要嚴格冰水溫控時限制在 **10%/min 以下**，「放寬到 30%/min 在多數**舒適空調**應用是可以的」，同篇稍後又建議「具備先進冰機控制的應用，30%/min 應該可行」。
Johnson Controls 160.00-AD9（2022）：**10% 或更少、在 60 秒內**，且必須**連續調變**而非階梯式下降；此值要靠每個系統實測建立，閥的全行程時間建議 1.5–2 分鐘。
**關鍵是「資料中心算不算舒適空調」。** Trane 同篇明列「冰水溫度很關鍵時（無塵室、製程）不要用 VPF」，資料中心夾在中間，而選錯的代價是整廠跳機。→ 必須存成**帶出處與 commissioning 日期的欄位**，不能是程式裡的常數。

**（二）低 ΔT 症候群的因與果。** 文獻（Energy & Buildings 系統性回顧）把共通管逆流（deficit flow）列為低 ΔT 的**症狀**；部分廠商文件當成**原因**、主張限制二次側泵速就解決。壓住泵速只是藏起症狀，末端閥全開、盤管髒污、三通閥旁通這些真因還在。→ 告警規則要把逆流標成 `symptom` 而非 `root_cause`，不然工單會一直派給泵。

## 動手練習（35 分鐘）

> ⚠️ 先做完 [W36 週報](../weekly/2026-W36.md) 的 #1 與 #2——**dc-19 是第六個實作者**，先做 30 分鐘，後做是六張卡一起改。今天只夠做那兩項的話本練習順延，不要兩件事都做一半。

繼續同一份 code。

```python
@dataclass(frozen=True)
class PumpCurve:      # H = h0 - a*Q²（二次近似；有原廠曲線就改點集+插值）
    h0_m: float; a: float

@dataclass(frozen=True)
class SystemCurve:    # H = h_static + k*Q²；h_static 來自遠端 DP 設定值
    h_static_m: float; k: float

@dataclass(frozen=True)
class Limit:          # 同一維度可有多個，basis 不同
    value: float
    basis: str        # "tube_velocity_12fps" / "waterbox_gasket_22.5ft_per_pass"
    source: str       # 文件編號 + 版本
    fetched_at: str

@dataclass(frozen=True)
class RateConstraint: # 第一個作用在時間導數上的約束
    max_pct_per_min: float
    source: Literal["bms_sequence", "vendor_doc"]
    commissioned_at: str | None
```

要實作的五件事：

1. **`operating_point(pump, system, n_parallel=1)`** — 解交點（封閉解），回傳 `(總流量, 揚程, 每台流量)`。
2. **`Dimension.aggregation`** 新增 `"parallel_pump"`，讓 `binding()` 走它；驗證 `sum` 會給錯答案。
3. **`min_flow(load_pct, full_load_min)`** — JCI 規則（線性 ＋ 50% 地板）。
4. **`RateConstraint.time_to_change(from_pct, to_pct)`** — 回傳分鐘數；短於 `chiller.restart_time_s` 時吐 `Finding(kind="RATE_LIMIT_UNSAFE")`。
5. **`ups_load_with_cooling(it_kw, pumps_on_ups)`** — 把泵加進 UPS 負載並重算 runtime。

**驗收表**：

| 案例 | 期望 |
|---|---|
| 單台，`h_static=10, k=0.003422, h0=39, a=0.001540` | Q = 76.4 L/s、H = 30.0 m |
| 兩台並聯 | **Q = 87.3 L/s（不是 152.9）**、H = 36.1 m、每台 43.6 L/s |
| 用 `sum` 聚合兩台 | 152.9 L/s → 高估 75%，測試必須抓到 |
| 60% 流量、含靜揚程 | 功率比 0.344（不是 0.216）；反推指數 ≈ 2.09 |
| `min_flow(0.70, 162)` / `min_flow(0.30, 162)` | 113 gpm／**81 gpm**（觸底，不是 49） |
| 100%→40% 在 10%／30%/min 下 | 4.0 分鐘／1.3 分鐘 ＋ `RATE_LIMIT_UNSAFE` |
| `pumps_on_ups=True` | UPS 負載 1 690 kW，runtime 10 → 9.5 分鐘 |

加分題：把 `max_pct_per_min` 掃 5→40，找出「泵減速耗時 = 冰機重啟時間」的交叉點——**那就是這座機房控制序列的安全邊界，而且是算出來的。**

## 自我檢核

**Q1. 為什麼「N+1 台泵」不等於「N+1 倍流量餘裕」？**

??? note "答案"
    系統阻力隨流量平方上升。兩台並聯總流量只到單台的 1.14 倍，揚程從 30 爬到 36.1 m，每台被推回曲線左邊只跑 43.6 L/s。台數冗餘保的是「壞一台還有流量」，不是流量加倍；相加銘牌值會高估 75%。

**Q2. 蒸發器最小流量這件事，會讓資料模型長出什麼欄位？**

??? note "答案"
    三件事。(a) 它不是欄位是函數：`min_flow(load_pct)`，線性下降並在 50% 負載觸底。(b) 最大流量同時有兩個來源不同的上界（流速 12 ft/s 的熱傳／侵蝕、墊片 22.5 ft H₂O/pass 的機械破壞），一個 `max_flow` 欄位裝不下。(c) 兩者都要能指向出處而非列舉值——延續 `derating_basis`（dc-12）與 `accuracy`（dc-15）。

**Q3. 泵的流量變化率上限，和前 18 張卡的所有約束有什麼結構性差異？**

??? note "答案"
    前 18 張全是瞬時值約束 `value ≤ limit`；這是第一個作用在**時間導數**上的 `|dQ/dt| ≤ limit`。而且它不在銘牌上，住在 BMS 控制序列裡、是 commissioning 時人調出來的——會被改掉且設施側可能不知情（同 dc-16 的 `psu_policy`）。所以 `RateConstraint` 要帶 `source` 與 `commissioned_at`，被改動時觸發重算。

## 未查證

- **台灣有無對應 ASHRAE 90.1 W/gpm 的輸送能耗門檻。** 抓到的「建築物節約能源設計技術規範」全文只有外殼指標，無水側條文；二手說法提到「冰水泵總動力超過 7.5 kW 須符合水管壓降規定」，**未在原文查證，不要引用**。
- 30 m 揚程、`h_static = 10 m`、效率 0.80、三台冰機各 404 gpm／滿載最小 162 gpm，全是**假設或推算值**，只用來把公式走通。

## 相關概念

上游 [冰水主機](chiller.md)、[冷卻水塔](cooling-tower.md)；下游 `dc-20`、`dc-22`；電力側 [UPS](ups-double-conversion.md)、[電池組](ups-battery.md)。同類錯誤：[雙電源設備](dual-corded-equipment.md)（冗餘銘牌值不可加）、[rack PDU](rack-pdu.md)（`vector_sum`）。主題卡 `topic-01`／`topic-03`／`topic-05`。
