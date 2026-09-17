---
id: dc-23
title: CRAC 精密空調（直膨式）
category: cooling
written_at: 2026-09-14
sources:
  - https://www.vertiv.com/4999c4/globalassets/products/thermal-management/room-cooling/liebert-ds-28-105kw-8-30-tons-system-design-manual_01.pdf
  - https://www.vertiv.com/globalassets/shared/liebert-mc-condensers-guide-specifications.pdf
  - https://mepacademy.com/crac-vs-crah-units-explained-data-center-cooling/
  - https://industrialmonitordirect.com/blogs/knowledgebase/refrigerant-riser-height-restrictions-resolving-the-trap-vs-max-rise-conflict
  - https://www.chientorn.com/article_d.php?lang=tw&tb=3&id=568
  - https://www.achrnews.com/articles/147372-epa-proposes-ban-on-r-410a-starting-in-2025
related: [dc-22, dc-18, dc-20, dc-17]
---

# CRAC 精密空調（直膨式）（Computer Room Air Conditioner, Direct Expansion）

跟 [CRAH](crah-chilled-water.md) 站在機房裡同一個位置、做同一件事：吸回風、吐冷風。差別只有一個——CRAH 的盤管裡走的是別人送來的冰水，CRAC 的盤管裡走的是**它自己的冷媒**，壓縮機就裝在那個機箱裡，熱直接由冷媒管送到屋頂的氣冷冷凝器排掉。沒有冰機、沒有冷卻水塔、沒有環路。聽起來是簡化，但它把[冰機](chiller.md)那整個「解聯立」的問題，複製了幾十份塞進機房裡。

## 六格

### 拓撲位置

上游：機房回風、電力樹上的專用迴路（同 [rack PDU](rack-pdu.md) 那層的 [RPP](rpp-remote-power-panel.md) 分路）、**以及屋頂的氣冷冷凝器（走冷媒管，不是水管）**。下游：送風靜壓箱、屋頂大氣。

它**不掛在冰水環路上**——跟 dc-22 唯一的拓撲差別，後果卻幾乎是這張卡的全部。

### 容量單位

`kW_total` / `kW_sensible` / SHR / 風量 / **冷媒充填量 kg**。最後一項是前 22 張都沒有的：它是合規與營運風險的計量單位，不是性能單位。

### 冗餘表達

比 CRAH 貴一層：室內機與冷凝器**一對一綁定**（除非做冷媒歧管，實務罕見），所以 N+1 加的是「一對」不是「一台」，白空間（dc-22 的 `footprint_m2`）與**屋頂面積**同時被吃。

### 遙測介面

| 點位 | 為什麼要 |
|---|---|
| 回風／送風溫濕度 | 容量的自變數（見下） |
| 吸氣／排氣壓力（換算飽和溫度） | 唯一能看見冷凝側惡化的量 |
| **冷凝器進風溫度** | 與氣象站乾球**不是同一個量** |
| 壓縮機累計運轉時數 ＋ **累計起停次數** | 壽命是起停次數，不是時數 |
| 冷媒高／低壓跳脫、洩漏偵測 | 跳脫條件 ≠ 容量條件（dc-18 立的） |

### 故障域

每台自己一套冷媒迴路 → 單機洩漏不影響別台，**故障域比 CRAH 小**。但共模換了位置：屋頂冷凝器區的**進風溫度**與**供電**。而 ride-through **歸零**。

### 維護特性

冷媒洩漏定檢（法規驅動，見來源分歧一）、冷凝器盤管清洗（濱海要 E-coat，Vertiv guide spec 要求 5% 鹽霧 2000 小時後衰減 < 10%）、壓縮機起停次數。低溫端的 Lee-Temp 受液器＋150 W 加熱器（支援 −34.4 °C 啟動）在台灣完全用不到，但型錄與規格書預設會寫進去。

## 關鍵數字與計算

### 一、總容量幾乎不動，動的是顯熱／潛熱的分配

Liebert DS105 下流式、數位渦卷、MCL110 冷凝器、**室外 35 °C**（露點固定 52 °F）：

| 回風乾球 | Total | Sensible | SHR |
|---|---|---|---|
| 23.9 °C（44% RH） | 97.4 kW | 82.2 kW | 0.844 |
| 26.7 °C（38% RH） | 101.3 kW | 92.2 kW | 0.910 |
| 29.4 °C（32% RH） | 105.6 kW | 101.1 kW | **0.957** |

回風 23.9 → 29.4 °C：**total 只 +8.4%，sensible +23.0%**。對照 dc-22 的 Liebert CW 305（冰水式）同樣的回風區間，顯熱是 228 → 323 kW（**+42%**）。

差別的原因是壓縮機就在箱子裡：**total 被壓縮機釘住**，回風變暖變乾並不會多買到冷量，它只是把原本花在除濕的潛熱容量**重新分配**成顯熱。CRAH 沒有這個天花板——冷量在冰機那邊，盤管要多少拿多少。

推論：**SHR 是運轉點的輸出，不是設備屬性。** 把加濕器開大、露點從 52 °F 升到 58 °F，潛熱吃掉一塊，顯熱就掉了——而型錄那格 101.1 kW 不會變。

### 二、冷凝器排氣再循環：dc-22 的旁通病在室外重演

氣象站乾球不是冷凝器看到的溫度。MCL110 排約 130 kW 熱、風量約 12 m³/s，`ρcp = 1.21 kJ/(m³·K)`：

`ΔT_排氣 = 130 / (12 × 1.21) = 8.95 K`

再循環比例 `r` 時，`T_進風 = T_站 + r × 8.95`。容量對環境溫度的敏感度取 **−1.6 %/K**（由「110 °F 時較 95 °F 低 20–30%」反推的粗略區間，**不是廠商曲線，不可用於選型**）：

| 情境 | T_進風 | 對 35 °C 的差 | Sensible |
|---|---|---|---|
| 氣象站 35 °C、無再循環 | 35.0 | 0 | 101.1 kW |
| 再循環 15% | 36.3 | +1.3 K | 99.0 kW |
| 圍牆井、再循環 40% | 38.6 | +3.6 K | 95.2 kW |
| 屋頂實測 40 °C ＋ 再循環 40% | 43.6 | +8.6 K | **87.2 kW** |

最後一列與型錄的 105.6 kW 差 **18.4 kW**——N+1 裡那個「+1」的餘裕，被一個沒有人量的溫度吃掉了。數學結構跟 dc-22 的旁通率完全一樣（冷熱氣流混合比例），只是換到室外，**而且沒有任何一張設施表會記錄冷凝器進風溫度**。

### 三、ride-through：機房只剩空氣自己的熱容

壓縮機停 = 冷量立刻歸零。機房 1000 m² × 4 m：

`C_room = 4000 m³ × 1.21 kJ/(m³·K) = 4840 kJ/K`
`dT/dt = 1600 kW / 4840 = 0.331 K/s = 19.8 K/min`

從 24 °C 到 ASHRAE A1 允許上限 32 °C 只有 8 K → **24 秒**。

而壓縮機的 anti-short-cycle timer 強制停機後休息 **3–5 分鐘**。市電掉、發電機 10 秒起來、ATS 切回，CRAC 仍在 rest period —— 那段空窗是 **300 秒對上 24 秒**。

⚠ 19.8 K/min 是**純空氣的上界**：伺服器鈑金、地板、牆體的熱容也在吸熱，實際會慢數倍。修正係數未查證。但數量級是**分鐘**，不是 dc-18 環路的 5.2 分鐘、更不是 [dc-20 儲冷槽](thermal-storage-tank.md)的 15 分鐘——那兩個都是**水側**的慣量，前提是泵還在轉、盤管還有冷水。CRAC 沒有那一層。

### 四、起停次數：由死區寬度決定，不是由負載決定

兩段式壓縮機（段位 {50%, 100%} × 101.1 kW 顯熱 = {50.6, 101.1} kW），`min_on = 180 s`、`min_off = 300 s`。

最短循環 `T_min = 180 + 300 = 480 s` → **7.5 starts/hr**，發生在負載恰為 `0.375 × 50.6 = 19.0 kW`（銘牌的 **18.8%**）時——**新機房頭一年正好就在那裡**。

若機組沒有 `min_on`（舊機常見），on-time 由溫度死區決定。死區 ±0.5 K（1 K 全寬）、超額冷量 `50.6 − 19.0 = 31.6 kW`：

`t_on = 4840 × 1.0 / 31.6 = 153 s` → `T = 453 s` → **7.9 starts/hr**

死區收到 ±0.2 K：`t_on = 61 s` → `T = 361 s` → **10.0 starts/hr**，已踩到渦卷壓縮機常見的 10–12 次/小時建議上限。

**一個控制參數（死區寬度）直接決定硬體壽命。** 結構跟 [dc-21 的 `ModePolicy`](plate-hx-free-cooling.md)（遲滯＋最短駐留）一模一樣，但這次被消耗的不是 ride-through 窗口，是壓縮機。

## 常見誤解

**以為 CRAC 與 CRAH 只差「有沒有壓縮機」，容量模型可以共用一套**，但實際上 CRAH 的 `limit` 由外部冰水系統給定（EWT 是輸入值），CRAC 的 `limit` 是壓縮機與室外冷凝器**互為因果的聯立解**——排熱不順 → 冷凝溫度升 → 容量降且更耗電 → 排熱更多。dc-18 在整廠只解一次的那個迴路，CRAC 是**每台各解各的，幾十份**。

**以為「改用 CRAC 就不必管冰機房，故障域變小所以更安全」**，但實際上故障域變小的同時 **ride-through 歸零**。CRAH 停了還有環路的水撐 5.2 分鐘、儲冷槽 15 分鐘；CRAC 停了機房只剩 4840 kJ/K 的空氣，而 anti-short-cycle 是 3–5 分鐘。**「單點故障影響範圍」與「故障後能撐多久」是兩個正交的指標，CRAC 是一好一壞。**

**以為容量表上的 kW 就是機房排得掉的熱**，但實際上那是 total（含潛熱）。能排掉伺服器顯熱的只有 sensible 那一列，而 SHR 是運轉點的輸出（0.844 → 0.957），**加濕器一開，顯熱容量就掉，而你的容量表不會變**。

## 對資料模型的意涵

1. **`Dimension` 第一次需要「分量」關係。** 前 22 張每個維度各自獨立。`sensible` 與 `latent` 是同一個 `total` 的兩個分量，受守恆式綁住，**不能各自設 limit**。把 `sensible_capacity_kw = 101.1` 存成獨立欄位，露點一變它就悄悄錯了 → 需要 `SplitDimension(total, sensible, latent)`，且 SHR 是 `derived_from` 不是欄位。

2. **`SiteEnvironment` 要存配對時間序列，不是兩個獨立統計量。** 蒸發式設備（[水塔](cooling-tower.md)）吃**濕球**，氣冷冷凝器吃**乾球**，而台北最熱的乾球日與最高濕球日不是同一天。各取 0.4% 值會過度保守；ASHRAE 設計資料本身就分 `DB with MCWB` 與 `WB with MCDB` 兩套表 → 同一個 `scenario` 下兩邊必須用**同一小時**的資料。

3. **`Device.env_offset(source_var, basis)`，預設 `unknown` 不是 0。** 站點變數與設備實際看到的值之間有一個**由幾何決定的偏移**（再循環 40% → +3.6 K → −5.8% 容量）。這是繼 dc-15「拓撲 vs 標註」、dc-17「站點級外生變數」之後的第三層：**站點量測點正確、設備仍拿到錯的輸入**。basis 指向 CFD 或現場實測。

4. **`Dimension.kind` 第三種：`cycles`。** dc-20 給了 `power | energy`。起停次數同時有**速率上限**（10–12 次/hr）與**累計壽命上限**，而它的值由死區寬度決定 → `DeadbandPolicy` 與 `ModePolicy` 應該是同一個抽象。另：`capacity_steps: list[float] | "continuous"` ——[dc-18 的 `lower_limit`](chiller.md) 是連續調節設備的下界，兩段式機的可達容量是**離散段位 × duty cycle** 組出來的集合，不是一個下界。

5. **`ride_through_s` 是拓撲的函數，且必須與 `restart_delay_s` 一起判。** CRAH 是 `loop_volume / load`（分鐘級），CRAC 是 `room_air_mass × cp / load`（秒級）。`restart_delay 300 s > ride_through 24 s` → `Finding.RIDE_THROUGH_INSUFFICIENT`，而**這個 Finding 在任何穩態容量報表上都是綠的**。接 dc-18 的 `TransientScenario`。

6. **`RefrigerantCircuit(refrigerant, charge_kg, rise_m, equiv_length_m, validated_against)`。** 冷媒是**會被法規配額限制的消耗品**，且換冷媒會回頭讓既有管路不合格（見分歧二）。沿用 [dc-09c](lib-fire-compliance.md) 的 `CodeRule` 版本化。

## 來源分歧

**（一）冷媒法規：美規管設備、台灣管總量——後果完全不同。**
美國 AIM Act：多數新製 comfort cooling 設備自 2025-01-01 起 **GWP 上限 700**，R-410A（GWP 2088）出局，R-454B（466）／R-32（675）接手，**兩者都是 A2L 微燃**；VRF 延到 2026-01-01；工業製程冷凍與半導體製程冰機延到 2030-01-01。台灣環境部依《氣候變遷因應法》，2024-07-01 起列管 18 種 HFCs（製造／輸入／輸出／販賣／使用／排放皆須核准），2025 年起實施**核配制度**（以 CO₂e 為基準的進口配額，2029／2035／2040／2045 分階段削減）。
**分歧的實質**：美規下**你買不到 R-410A 新機**；台灣下**你買得到新機，但十五年後補充冷媒會愈來愈貴、甚至買不到**——而 CRAC 設計壽命 15–20 年、單台充填量在數十 kg 等級。這是營運風險不是採購風險。另：「資料中心算不算 comfort cooling」在 AIM Act 下也有分歧——EPA 延後名單明列的是工業製程冷凍與半導體冰機，**沒有明列資料中心**，二手來源對 CRAC 落在哪一類說法不一。

**（二）冷媒立管的最大垂直高度，數字差 8 倍。**
傳統／ASHRAE 口徑：吸氣立管**每 25 ft 一個回油彎**，最大垂直升高 20 ft（小型機）至 50 ft（標準商用機）；Trane 新式機組**取消回油彎要求**（壓縮機油管理改良＋微通道降低充填量）；Mitsubishi Mr. Slim 做到 **164 ft**，但超過 25 ft 起降載。
「每 25 ft 一個彎」與「最大 20 ft」看似矛盾，實則管兩件事（彎防液壓縮、最大升高管全系統回油），**但需要一整篇文章來解釋這件事本身就說明現場常搞錯**。
最關鍵的連動：**最小回油流速隨冷媒而變**——R-22 約 7.6 m/s、R-410A 約 5.1 m/s、R-32 約 4.1–5.1 m/s。所以 `max_vertical_rise` 不是設備欄位，是 `f(refrigerant, pipe_diameter, min_capacity_step)`，而**分歧一的冷媒更換會讓原本合法的立管在新冷媒下不合格**。

**（三）地區差異：整套低溫配備台灣用不到，而真正的約束在高溫端。** Liebert MC 的 −34.4 °C 啟動能力、Lee-Temp 受液器、防凍轉風，以及「總設計溫差 ≤ 70 °C」的限制，都是為北美／北歐寫的。台灣最低溫在 5–10 °C，這些是**帳面成本與帳面複雜度**。反過來 MC 控制板上限 51.7 °C，看似寬鬆，但那是**控制板**的額定，不是容量曲線的有效範圍——夏日午後屋頂的局部進風（熱島＋自身排氣再循環）是真正該擔心的那一端。

## 該問 facility 的問題

1. 屋頂冷凝器區的設備間距與圍牆高度是多少？有沒有做過 CFD 或夏日實測進風溫度？氣象站乾球與冷凝器實際進風差幾度——這個數字決定上面那張表你落在哪一列。
2. 壓縮機是數位渦卷（連續）、兩段還是四段？頭一年 IT 只上 30% 時，最小可達容量與預期 starts/hr 是多少？機組的溫度死區出廠設多寬、誰有權改？
3. 用什麼冷媒、單台充填幾 kg、全廠總量多少？有沒有申請到環境部的 HFCs 核配量？未來十五年的補充來源與成本估過嗎？
4. 冷媒立管實際垂直高度與單向管長多少？當初驗算依據的是哪一版廠商文件、哪一種冷媒？

## 動手練習（30–40 分鐘）

接著 dc-22 留下的 `RoomReport` / `AirBalance` 往下長，今天補兩個純函數，**不碰 IO**。

**第 1 段（約 20 分）`env_offset` 與冷凝器進風**

```python
RHO_CP = 1.21          # kJ/(m3*K)
SENS_PER_K = -0.016    # 每 K 容量變化率；粗略區間，basis="derived_range"

def condenser_inlet_c(site_db_c: float, recirc: float,
                      reject_kw: float = 130.0, airflow_m3s: float = 12.0) -> float:
    return site_db_c + recirc * reject_kw / (airflow_m3s * RHO_CP)

def sensible_kw(rated_kw: float, inlet_c: float, rated_at_c: float = 35.0) -> float:
    return rated_kw * (1 + SENS_PER_K * (inlet_c - rated_at_c))
```

跑四個情境（35/0、35/0.15、35/0.40、40/0.40），輸出四個 sensible 與各自的 `basis`。驗收：最後一列落在 87 kW 附近，與型錄 105.6 kW 的差約 18 kW。

**第 2 段（約 20 分）`ride_through` 與 `restart_delay` 一起判**

```python
def ride_through_s(thermal_mass_kj_k: float, load_kw: float, allowed_rise_k: float) -> float:
    return thermal_mass_kj_k * allowed_rise_k / load_kw

def check(mass_kj_k, load_kw, allowed_k, restart_delay_s) -> str | None:
    rt = ride_through_s(mass_kj_k, load_kw, allowed_k)
    return None if restart_delay_s <= rt else f"RIDE_THROUGH_INSUFFICIENT: {rt:.0f}s < {restart_delay_s}s"
```

用**同一份 code** 跑兩次：CRAC（`mass = 4840`，房間空氣）與 CRAH（把環路水量換算成 kJ/K 代入）。

驗收表：

| 檢查 | 期望 |
|---|---|
| CRAC ride-through | 約 24 s |
| CRAH ride-through | 分鐘級（與 dc-18 的 5.2 min 同數量級） |
| CRAC `check(..., 300)` | 吐 `RIDE_THROUGH_INSUFFICIENT` |
| 兩者差距 | 約兩個數量級 |

**加分**：把第四段的起停模型也寫出來，掃死區 0.2 / 0.5 / 1.0 K，確認 starts/hr 隨死區收緊而上升，並在超過 10 時吐 `Finding`。

## 自我檢核

**Q1. 回風從 23.9 升到 29.4 °C，CRAH 的顯熱容量 +42%，CRAC 只 +23%、且 total 幾乎不動。為什麼？**

??? note "答案"
    壓縮機在機箱裡，total 被它釘住。回風變暖變乾不會多買到冷量，只是把潛熱容量重新分配成顯熱（SHR 0.844 → 0.957）。CRAH 的冷量在冰機那邊，盤管要多少拿多少，所以 total 跟著顯熱一起漲。

**Q2. 「CRAC 每台一套冷媒迴路，故障域比 CRAH 小，所以比較安全」——錯在哪？**

??? note "答案"
    「單點故障影響幾台」與「故障後能撐多久」是正交的兩件事。CRAC 前者較好、後者歸零：機房只剩 4840 kJ/K 的空氣熱容，1600 kW 下約 19.8 K/min（純空氣上界），而 anti-short-cycle 強制休息 3–5 分鐘。CRAH 停了還有環路的水與儲冷槽。

**Q3. 這張卡會讓你的資料模型長出哪些欄位？挑最會被漏掉的一個講。**

??? note "答案"
    最易漏的是 `Device.env_offset(source_var, basis)`，**預設值必須是 `unknown` 而非 0**。站點的乾球量測完全正確，設備仍可能拿到高 8.6 K 的輸入，而差異純由屋頂幾何決定、沒有任何設施表會記錄。其餘：`SplitDimension(total, sensible, latent)`（分量受守恆式綁住，不可各自設 limit）、`Dimension.kind = cycles`、`capacity_steps`、`ride_through_s` 與 `restart_delay_s` 成對判定、`RefrigerantCircuit`。

## 相關卡片

[CRAH 機房空調（冰水式）](crah-chilled-water.md)｜[冰水主機](chiller.md)｜[冷卻水塔](cooling-tower.md)｜[儲冷槽與 ride-through](thermal-storage-tank.md)｜[板式熱交換器與免費冷卻](plate-hx-free-cooling.md)｜[鋰電消防合規](lib-fire-compliance.md)
