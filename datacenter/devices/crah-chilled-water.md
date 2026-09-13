---
id: dc-22
title: CRAH 機房空調（冰水式）
category: cooling
written_at: 2026-09-11
sources:
  - https://www.vertiv.com/492d8e/globalassets/products/thermal-management/room-cooling/sl-70373_rev0_web.pdf
  - https://journal.uptimeinstitute.com/data-center-cooling-redundancy-capacity-selection-metrics/
  - https://www.facilitiesnet.com/datacenters/article/Understanding-the-Metrics-for-Chilled-Air-in-Data-Centers--11486
  - https://datacenters.lbl.gov/sites/default/files/Humidity%20Control%20in%20Data%20Centers.03242017_0.pdf
  - https://www.ahrinet.org/advocacy/regulatory/energy-efficiency/commercial-products/computer-room-air-conditioners
related: [dc-19, dc-20, dc-21, dc-23, dc-25]
---

# CRAH 機房空調（冰水式）（Computer Room Air Handler）

一個大鐵櫃，裡面就三樣東西：濾網、冰水盤管、風扇。它把機房的熱空氣吸進來，吹過泡在 7 °C 冰水裡的盤管，變冷之後吹進高架地板。它是整條冷卻鏈的**最後一棒**——前面 [冰機](chiller.md)、[泵](chilled-water-pump.md)、[水塔](cooling-tower.md) 做的所有努力，都要靠它交到伺服器手上。

## 六格

### 拓撲位置
水側：二次側[冰水泵](chilled-water-pump.md) → 盤管 → 回水 → [冰機](chiller.md)蒸發器。風側：熱通道回風 → 機組 → 高架地板靜壓箱 → 穿孔地磚 → 機櫃進風。電側：`rpp` 或 [PDU](pdu-floor.md) 餵風扇／控制／加濕器。**它同時是熱樹節點與電力樹葉負載。**

### 容量單位
`sensible_kw` 為主，但單一數字無意義——必須綁 **(回風乾球, EWT, 水側溫升, 外部靜壓 ESP, 風量)**。另有三個獨立維度：`air_flow_m3h`、`water_l_s`、`water_dp_kpa`。

### 冗餘表達
N+1 / N+2 以台數計，但**風量冗餘 ≠ 容量冗餘**：停機那台的機殼仍是一個洞，沒有逆止風門（backdraft damper）時運轉機組會從死機組倒抽風，5 台掉 1 台損失的有效風量大於 20%。共用地板靜壓箱的機組彼此耦合，不能各自獨立加總。

### 遙測介面
BACnet MS/TP / BACnet IP / Modbus RTU / TCP（機型而異）。

| 點位 | 用途 |
|---|---|
| `supply_air_temp` | **控制點應該用它**（見常見誤解二） |
| `return_air_temp` | 容量的自變數，且能反推旁通率 |
| `return_air_rh` / `dew_point` | 濕度控制；走露點不要走 RH |
| `valve_position_pct` | 二通閥開度，低 ΔT 症候群的線索 |
| `fan_speed_pct` | EC 風扇，功率約 3 次方 |
| `filter_dp_pa` | 濾網髒污，對照 clean baseline |
| `ewt` / `lwt` | 盤管實際 ΔT |
| `condensate_alarm` | 盤管在除濕＝在浪費 |

### 故障域
單台掉的影響半徑就是它的**送風投射距離**（Uptime 實務值 10–18 m）。半徑外不受影響，半徑內幾乎立刻受影響——機房空氣熱容極小，**秒到分鐘等級**，比[冰機](chiller.md)的 ride-through 短一個數量級。

### 維護特性
濾網（Vertiv 規格：4 in 深摺、ASHRAE 52.2 MERV8 或 MERV11）定期更換，不停機但要開門；盤管清洗、加濕器罐更換需停該台；EC 風扇無皮帶。替代路徑＝鄰近機組補風，**前提是有冗餘且風門會關**。

## 關鍵數字與計算

基本式（SI，海平面標準空氣 ρcp ≈ 1.21 kW 每 m³/s 每 K）：

`Q_sensible(kW) = 1.21 × V(m³/s) × ΔT_air(K)`

### 演算一：回風溫度就是容量（Liebert CW 305，35 000 ACFM，EWT 7.2 °C，水側 5.5 K 升）

35 000 ACFM = 59 465 m³/h = 16.52 m³/s，故 `1.21 × 16.52 = 19.99 kW/K`。

| 回風乾球 | 型錄顯熱 | 推得 ΔT_air | 推得送風溫 | 對 EWT 的 approach |
|---|---|---|---|---|
| 23.9 °C (75 °F) | **228 kW** | 11.4 K | 12.5 °C | 5.3 K |
| 26.7 °C (80 °F) | **276 kW** | 13.8 K | 12.9 °C | 5.7 K |
| 29.4 °C (85 °F) | **323 kW** | 16.2 K | 13.2 °C | 6.0 K |

同一台機、同樣的冰水、同樣的風量，**回風從 23.9 升到 29.4 °C，顯熱容量 +42%**。而送風溫度只動了 0.7 K——因為離風溫度被 EWT ＋ approach 釘住了。**容量幾乎純粹是回風溫度的函數。**

回風溫度是誰決定的？空氣怎麼混回來的。旁通率（bypass，出風未經伺服器就回到機組）由三個可量測的溫度給出：

`BP = (T_exhaust − T_return) / (T_exhaust − T_supply)`

取送風 12.5 °C、伺服器溫升 20 K（出風 32.5 °C）、回風 23.9 °C：`BP = (32.5 − 23.9)/20 = 0.43`。

反過來從風量看：228 kW 的 IT 負載在 20 K 溫升下只要 `228/(1.21×20) = 9.42 m³/s`，而機組在吹 16.52 m³/s，比值 **1.75**，多出來的 43% 就是旁通。**兩條路算出同一個數字——旁通率和回風溫度是同一件事的兩種寫法。**

所以：**型錄那一列「75 °F 回風」的招牌數字，本身就是一間旁通 43% 的機房。** Salim & Tozer 的現場調查結論是平均約一半的 CRAC 風量旁通、約一半的伺服器進風是自己的排氣——和這裡的算術對得上。

做好封閉把回風推到 29.4 °C 之後，同樣 228 kW 只需要 0.71 台：風扇降到 71% 轉速 → 風量 11.7 m³/s，旁通降到 19%；風扇功率約 `0.71³ ≈ 36%`。**注意指數 3 是理想值**——[dc-19](chilled-water-pump.md) 已證實實機是擬合值（泵在定壓揚程下低到 2.09）。風機在靜壓箱裡以動壓損失為主，比泵接近 3 次方，但仍應以實測為準。

### 演算二：兩份型錄都寫「net sensible」，意思不一樣

Vertiv 每張表的註腳 2 寫「Net capacity data has fan motor heat factored in」——已扣。可以從水側反推扣了多少（`1 GPM × 1 °F = 500 BTU/h`）：

| 表 | 水流量 | 水溫升 | 水側帶走 | 型錄總容量 | 差額＝風扇熱 |
|---|---|---|---|---|---|
| 2.1 | 175 GPM | 10 °F | 256.4 kW | 242 kW | **14.4 kW** |
| 2.2 | 132 GPM | 12 °F | 232.1 kW | 217 kW | **15.1 kW** |

兩列各自獨立算出 14–15 kW，互相吻合，與註腳說法一致（推導值，非公布值）。

而 Uptime 那篇用的機型，附錄 C 的註記是：「Net sensible cooling will be reduced by 7.5 kW × 3 = 22.5 kW for fans」——**那份型錄標的 90 kW 還要再扣 22.5 kW，實際只剩 67.5 kW（扣掉 25%）。**

**同一個詞，一邊已扣一邊沒扣。** 拿兩家型錄並排比容量、或把型錄數字直接寫進容量表，就是這樣錯的。

### 演算三：水側溫升是買來的，不是調來的（同機型、同回風 23.9 °C）

| 水側溫升 | 顯熱 | 水流量 | 機組壓降 |
|---|---|---|---|
| 5.5 K (10 °F) | 228 kW | 175 GPM (11.0 L/s) | 57 kPa |
| 6.7 K (12 °F) | 214 kW (**−6.1%**) | 132 GPM (**−24.6%**) | 33 kPa (**−42%**) |

要求盤管把水溫拉開 1.2 K，代價是 6% 的顯熱容量，換到的是 **25% 的水流量**——以 [dc-19](chilled-water-pump.md) 實測的 2.5 次方估，泵功率剩約 `0.754^2.5 ≈ 49%`。這就是低 ΔT 症候群的另一端：**ΔT 是在盤管選型時定下來的採購決定，不是事後能用控制調回來的。**

## 常見誤解

**以為「CRAH 容量不夠就多買一台」，但實際上先該做的是把回風弄熱。** 演算一：封閉做好，同一台機多給 42% 容量，零採購。反過來，在旁通 43% 的機房裡加第五台 CRAH，會讓回風更冷、每台容量更低——**加設備讓每台變弱**。

**以為 CRAH 顯示「回風 24 °C、正常」代表機房溫度合格，但實際上那個讀數與合格判定無關。** ASHRAE Thermal Guidelines 明文：規範只針對**進入 IT 設備的空氣**，機殼內、排氣、回風、送風靜壓箱的量測「與 IT 設備的運作與可靠度無關」。機組全綠而某一櫃頂進風 38 °C，兩件事完全相容。

**以為機房總 kW 夠就不會有熱點，但實際上風量是另一條獨立的約束。** Uptime 講得很直白：被動式排熱設備「不可能排掉比 CRAC 送來的冷風更多的熱」。kW 帳面充足而風量短缺時，缺口只能由**回流（recirculation）**補上——伺服器吸自己的排氣，容量報表全綠、機櫃過熱。

## 對資料模型的意涵

1. **`limit` 第一次依賴「負載自己造出來的狀態」。** [dc-17](cooling-tower.md) 的 `env`（濕球）是站點外生的、[dc-21](plate-hx-free-cooling.md) 的 `mode` 是控制系統選的，兩者都不受負載影響。CRAH 的 `limit` 是回風溫度的函數，而回風溫度取決於封閉品質、盲板、地磚開孔率——**取決於營運習慣，不取決於硬體**。→ `Dimension.limit(return_air_c)` ＋ `CapacityReport.assumed_return_air_c` 與其 `basis`（實測／假設）。**規劃中的機房量不到它，只能假設，所以這個假設必須被記錄而不是被寫死。**

2. **`resource` 的第三種：`air_flow`。** [dc-17](cooling-tower.md) 讓 `binding()` 變成 per-resource（kW 不能跟 L/min 比），這裡再加一個 m³/s，而且是第一次**同一個設備上兩個資源被一個設計決定（ΔT）綁在一起**：選 11 K 還是 16 K 同時決定了 kW 與 CFM 的比例。另外需要房間層級的 `AirBalance(bypass, recirculation, balance)`——**它推導不出來自任何設備的銘牌**，只能由三個溫度算（見演算一）。

3. **同一筆 kW 同時出現在兩棵樹上，符號相反。** 風扇熱 14–22 kW：在電力樹是葉負載（掛 UPS 就吃 [dc-19](chilled-water-pump.md) 記下的 UPS 容量），在熱樹是這台機自己要再排掉的熱。[dc-17](cooling-tower.md) 的橫向邊至今傳的是「影響」，這裡傳的是**同一個量**。→ `FanHeat` 不能各記一份，要是同一實體被兩棵樹引用，否則改轉速時兩邊不同步。連帶 `capacity_basis` 必須記「風扇熱扣了沒」——繼 [dc-12](rpp-remote-power-panel.md) 的 `derating_basis`、[dc-15](power-meter.md) 的 `accuracy` 之後第三個「不能是數字、要能指向文件」的欄位。

4. **`MeasurementPoint.role` 要分 `control` 與 `compliance`。** CRAH 回風感測器是控制點不是合規點，合規點在機櫃進風。[dc-15](power-meter.md) 的「拓撲 vs 標註」在這裡多一個面向：**同樣是標註，用途不同不可互換**。告警建在 CRAH 讀數上會對熱點完全沉默。

5. **`RedundancyPolicy` 要帶 `footprint_m2`。** Uptime 模型：一台 CRAC 連維修空間與投射緩衝佔 14 m²。同機房、同樣 4 台機，N+2 → 40 櫃 × 4.5 kW = 180 kW；N+1 → 52 櫃 × 5.2 kW = 270 kW——**少一台備援多 50% IT 容量，零額外資本支出。** 電力側沒有設備會這樣：備援 UPS 佔機電室，CRAH 備援吃的是**要賣的白空間本身**。

## 來源分歧

**（一）ASHRAE 建議濕度下限跨版本差約 15 K 露點，而 2021 版的數字兩個二手來源就對不上。**
LBNL/FEMP 整理：2004 一版 40% RH → 2008 二版 41.9 °F DP（5.5 °C）→ 2011 三版幾乎不變 → 2015 四版降到 15.8 °F DP（≈ −9 °C、約 8% RH）。2021 五版的二手說法則分歧：一說「−9 °C DP 與 8% RH 取較濕者」，一說「−12 °C DP 與 8% RH，約在 25 °C 交會」。上限同樣在動：2008/2015 是 59 °F DP（15 °C）且 ≤ 60% RH，2021 的二手說法是 A1 級 17 °C DP、A2 級 21 °C DP。
**後果具體**：加濕器的容量、告警門檻、乃至「今年加濕器該不該跑」全建在這個下限上。照 2008 的 5.5 °C DP 選型，加濕器整年在跑；照 2015/2021 選型，它幾乎不動。→ 沿用 [dc-09c](lib-fire-compliance.md) 的 `CodeRule` 版本化：`EnvelopeRule` 必須帶 standard + edition + class（A1–A4 / H1），**不可以只存一組數字**。五版原文本次未取得，上述 2021 數字不要直接引用。

**（二）「net sensible cooling capacity」不指同一個量**（見演算二）。AHRI Standard 1360 以 NSenCOP（net sensible capacity ÷ 機組總輸入功率）為評等基礎，理論上該統一口徑，但標準原文本次抓不到（PDF 回空內容），且那是北美法規體系，台灣有無對應標示制度未查證。

**（三）控制點：回風 vs 送風。** Salim & Tozer 明講「CRAC 系統應以送風而非回風控制，可惜少有機房這樣運轉」，而多數機組出廠預設就是回風控制。這不是學說對立而是**最佳實務與安裝基數的落差**，但對模型結果一樣：`control_variable` 必須是欄位，它決定同一台機在同一室溫下的行為。

## 該問 facility 的問題

1. **CRAH 選型表是按幾度回風選的？** 若是 24 °C，全廠容量表的分母就是一間旁通 43% 的機房；若是 29 °C，代表設計時已假設封閉會做到位——那封閉是誰的工單？
2. **型錄上的 sensible capacity 扣過風扇熱了嗎？ESP 設幾 Pa？** 這兩個問題決定同一份表要不要再打 8 折。
3. **濕度走 RH 還是露點？加濕／除濕集中在 DOAS 還是每台 CRAH 自己來？** 後者保證會出現一台加濕一台除濕。

## 動手練習（30–40 分鐘）

延續 [dc-21](plate-hx-free-cooling.md) 的 per-mode `binding()`。今天要做的是**讓 `binding()` 在同一個節點上同時回報兩種資源，並讓其中一種綠、另一種紅**。

```python
from dataclasses import dataclass

RHO_CP = 1.21  # kW per (m^3/s * K)

# Liebert CW 305 @ 35,000 ACFM, EWT 7.2 C, 5.5 K water rise
CURVE = [(23.9, 228.0), (26.7, 276.0), (29.4, 323.0)]
V_FULL = 16.52   # m^3/s
FAN_KW_FULL = 14.4

def sensible_limit_kw(return_air_c: float) -> float:
    """Method.curve (dc-17)。超出型錄範圍吐 not_applicable，不要外推。"""

def bypass_ratio(t_supply, t_return, t_exhaust) -> float:
    """BP = (T_exhaust - T_return) / (T_exhaust - T_supply)"""

@dataclass
class RoomReport:
    heat_used_pct: float       # resource="heat",     kind=power
    air_used_pct: float        # resource="air_flow", kind=power
    binding: dict              # per-resource，不可互相比大小（dc-17）
    bypass: float
    fan_kw: float              # 同時是電力樹葉負載（意涵 3）
    assumed_return_air_c: float
    basis: str                 # "measured" | "assumed_containment"

def room_report(it_kw, server_rise_k, n_units, fan_speed_pct, return_air_c, basis):
    ...
```

**驗收表**（自己算一次，再讓 code 吐同樣的數字）：

| 情境 | 回風 | 台數×轉速 | heat 用率 | 風量比 | 旁通 | 風扇 kW |
|---|---|---|---|---|---|---|
| A 無封閉，228 kW | 23.9 °C | 1 × 100% | 100% | 1.75 | 0.43 | 14.4 |
| B 封閉，228 kW | 29.4 °C | 1 × 71% | ? | ? | ? | ? |
| C **kW 綠、風量紅** | 29.4 °C | 1 × 45% | <100% | **<1.0** | 0 | ? |

情境 C 是重點：把轉速降到風量低於伺服器需求，`heat` 維度仍在 limit 之內（因為 limit 是查回風溫度得到的），但 `air_flow` 維度已經違規。**若 `binding()` 只回一個值，這間機房會是綠的。**

**加分題**：情境 A 加第五台 CRAH，把回風混得更冷（用旁通公式反算新的 `T_return`），證明每台的 `sensible_limit_kw` 下降——**加設備讓總容量的增幅小於一台的銘牌值**。這是 `Dimension.aggregation` 的第五種，不是 `sum`。

## 自我檢核

**Q1. 同一台 CRAH、同一組冰水，型錄上 24 °C 回風 228 kW、29.4 °C 回風 323 kW。為什麼容量會跟回風溫度走，而送風溫度幾乎不動？**

??? note "答案"
    離風溫度被進水溫度 ＋ 盤管 approach 釘住（7.2 °C ＋ 約 5–6 K），幾乎與回風無關。容量 = `1.21 × 風量 × (回風 − 送風)`，風量固定、送風固定，所以容量就是回風溫度的線性函數。實務結論：**要容量先把回風弄熱**（封閉、盲板、堵地磚），這比再買一台便宜得多，而且再買一台會把回風弄得更冷。

**Q2. 這張卡會讓你的資料模型長出哪些欄位？至少說出三個，並說明沒有它會算錯什麼。**

??? note "答案"
    (1) `Dimension.limit(return_air_c)` ＋ `CapacityReport.assumed_return_air_c` / `basis`：容量的自變數是負載自己造出來的室內狀態，規劃階段量不到只能假設，不記下來就沒人知道那張表是按哪種封閉品質算的。
    (2) `resource="air_flow"` 與房間層級 `AirBalance`：kW 與 CFM 是同一節點上兩條獨立約束，只看 kW 會在風量不足時報綠燈。
    (3) `capacity_basis`（風扇熱扣了沒）：兩份型錄都寫 net sensible，一份已扣一份未扣，差到 25%。
    (4) `MeasurementPoint.role = control | compliance`：CRAH 回風讀數不是合規點，告警建在它上面會對機櫃熱點沉默。
    (5) `RedundancyPolicy.footprint_m2`：CRAH 備援吃的是可販售的白空間。

**Q3. 為什麼「把每台 CRAH 各自設定 45% RH」保證會出現一台加濕、另一台同時除濕？**

??? note "答案"
    RH 是相對量。各處回風溫度不同（靠熱通道的機組回風熱、角落的冷），**同樣的絕對含濕量**在熱回風那台算出的 RH 較低、冷回風那台較高。於是熱回風那台判定「太乾」開始加濕，冷回風那台判定「太濕」開始除濕（往往還要再熱）。露點在無加減濕的機房裡是全室均勻的，所以應量測 RH ＋ 溫度、換算露點、多點平均後**集中**判斷（LBNL 建議至少三組感測器對、用平均值，不要單點控制）。更徹底的作法是把加濕／除濕全交給一台小 DOAS，CRAH 一律選在高送風溫度、盤管表面溫度高於室內露點，**根本不產生凝水**。

## 相關概念

- [冰水主機](chiller.md)／[冰水泵](chilled-water-pump.md)：水側上游；演算三是低 ΔT 症候群在盤管端的樣子
- [板式熱交換器與免費冷卻](plate-hx-free-cooling.md)：dc-21 留下的「換熱器過關、末端盤管不過關」就是這裡的 LMTD 問題；那張門檻濕球表的 `T_chws` 來自盤管選型
- `dc-23` CRAC（直膨式）、`dc-25` 冷熱通道封閉、`topic-08` ASHRAE TC 9.9 熱環境 class
