---
id: dc-05c
title: NFPA 110 定期測試制度、30% 門檻與 wet stacking
category: power
written_at: 2026-08-07
sources:
  - https://www.curtispowersolutions.com/nfpa-110-maintenance-testing
  - https://www.csemag.com/a-close-look-at-wet-stacking/
  - https://generatorsource.com/generator-maintenance/wet-stacking-and-how-to-eliminate-it/
related: [dc-04, dc-05, dc-05b, dc-06]
---

# NFPA 110 定期測試制度、30% 門檻與 wet stacking

[dc-05](diesel-generator.md) 談這台機能出多少 kW，[dc-05b](genset-start-and-transient.md) 談它多快出得來。這張卡談第三件事：**你怎麼知道它還行**。答案不是監控——一台停著的發電機所有讀值都正常。唯一的驗證手段是定期叫它起來帶載跑，而這件事有一套制度、一個數字（30%），以及不遵守就會慢慢吃掉引擎的物理現象。

## 六格

**拓撲位置**：沒有設備。這是掛在 [dc-05](diesel-generator.md) 與 [dc-04](ats-transfer-switch.md) 上的**制度層**。上游是廠商手冊 + NFPA 110 Ch.8 + 當地 AHJ；下游是運轉時數配額、`dc-06` 的燃料消耗與一筆 load bank 費用。

**容量單位**：**分鐘**（達標負載下的連續時長）、**% 銘牌 kW**、**°C**（排氣溫度）、**kW**（load bank 規格）。

**冗餘表達**：沒有 N+1。§8.1.2 反而建議測試期間考慮臨時電源——**測試是刻意製造的降級時段**。

**遙測介面**：不是即時值問題，是事件 + 時間序列問題。

| 點位 | 型別 | 為什麼要 |
|---|---|---|
| `output_kw`（測試期間高頻取樣） | timeseries | 「≥30% 連續多久」要積分，不是看峰值 |
| `exhaust_gas_temp_c` | float | 走替代路徑時**唯一**的合規證據 |
| `initiating_ats_id` | FK | §8.4.3 要求逐月輪替起動的 ATS |
| `runtime_hours_total` | float | 引擎時數，**與合規分鐘數不是同一個鐘** |

**故障域**：測試不合格**不讓任何東西掉電**。後果落在 AHJ 稽核、保固條件，以及引擎在你不知情下逐年劣化。全鏈第一個「故障域不在電力拓撲上」的項。

**維護特性**：四層週期。**週**：目視 + 電池。**月**：帶載 30 min + ATS 動作 + 電池比重。**年**：燃料品質（ASTM）、斷路器操作、（月測不達標時）load bank 補充測試。**36 月**：Level 1 長時測試。

## 關鍵數字與計算

### 一、30% 的分母是哪個 kW

§8.4.2 原文是「不少於 **EPS standby nameplate kW rating** 的 30%」。兩個修飾詞都關鍵：**standby**（就是 ESP，[dc-05](diesel-generator.md) 五個額定裡**最大**的）、**nameplate**（**不套場址降載**）。代 Cummins DQLF：

```
正解  ESP 銘牌   2750 × 30% = 825 kW
誤用 COP        2100 × 30% = 630 kW   → 少 195 kW
誤用場址額定    2393 × 30% = 718 kW   → 少 107 kW
```

**誤差方向永遠偏小**——ESP 是最大的額定、銘牌又大於場址值。所以選錯分母不是保守，是**你以為合規、實際長期輕載**，正是 wet stacking 的成因。dc-05 的母題在這裡付出最貴的代價：**同一個誤解，在容量規劃上讓你高估 23.6%，在測試合規上讓你少載 23.6%。**

### 二、兩條互斥路徑，與月測不達標的分支

| 路徑 | 條件 | 代價 |
|---|---|---|
| A. 負載百分比 | 30 min 且 **≥30% ESP 銘牌** | 多數機房負載不夠，要補 load bank |
| B. 排氣溫度 | 30 min 且達 **廠商建議最低排氣溫度** | 每次都要量測留記錄，**事前不確定會不會過** |

CSE 明說：**很多機組在低於 30% 銘牌時就已達到廠商建議排氣溫度**，所以 B 對既有機房最不擾動。但 B 的隱藏成本是——資料庫裡必須有「廠商建議最低排氣溫度」，而它只存在於原廠手冊。**沒有那個數字，路徑 B 在制度上不存在。**

兩條都不過時，NFPA 不判違規，而是**觸發另一條義務**：月測照跑（用可用負載），另外每年做一次補充測試 `50% × 30 min + 75% × 60 min = 1.5 連續小時`。**這是分支邏輯不是罰則**，適合寫成 derived 規則，也很容易被人工排程遺漏。

### 三、load bank 要租多大：決定規格的是 75% 段

IT 400 kW、PUE 1.4 的機房，發電機帶的是**整廠**不是只有 IT：

```
發電機側 = 400 × 1.4 = 560 kW → 560/2750 = 20.4% < 30%，路徑 A 不過

月測補到 30%： 825    − 560 = 265   kW
年度 50% 段： 1375    − 560 = 815   kW
年度 75% 段： 2062.5  − 560 = 1502.5 kW  ← 決定規格
```

**取三者的 max，不是 30% 那段。** 直覺抓 265 kW 去問報價，實際要租 1500 kW 級，差 5.7 倍。而 1.5 MW 電阻式 load bank 就是一台 1.5 MW 電暖器，**排熱與擺放才是真瓶頸**。

反過來：IT 長到 1000 kW 時發電機側 1400 kW = 50.9%，路徑 A 直接過，年度義務自動消失。**新建機房的爬坡期正是最難合規、最花錢的階段。**

### 四、測試吃掉多少配額，與兩個不同的鐘

ESP 只給 200 h/年（Class 48 > 4 h，依 §8.4.9.2 可於 4 連續小時終止）：

```
月測 0.5×12 = 6.00 h；年度補充 1.50 h；36 月測試 4h÷3 = 1.33 h
                                 合計 ≈ 8.83 h/年 = 配額 4.4%
```

§8.4.9.6 允許**把 36 月測試與一次月測、一次年度測試合併**（前 3 h ≥30%、末 1 h ≥75%）。三年總帳 `26.5 h → 24.5 h`，年均 8.83 → **8.17 h**。省的不多，但**這條對資料模型殺傷力極大**：一次事件同時滿足三條要求，只要 `test_event` 上放了 `test_type` enum，這條就無法表達。

再一個隱蔽差距：§8.4.5 規定 **shutdown 延時最少 5 分鐘**（冷卻），加起動與加載，每次事件的**引擎時間**比**合規計時**多約 6 分鐘。三年 40 次 × 0.1 h ≈ 4.0 h → **引擎 10.2 h/年 vs 合規 8.83 h/年**。**合規以「達標負載下的分鐘數」計，配額以「引擎運轉小時」計**，兩個方向互相代用都會錯。

### 五、wet stacking 與治療的帳單

原理（CSE，Tom Divine）：柴油機沒火星塞，靠壓縮高溫空氣點燃霧化燃油。輕載時汽缸內壁遠低於設計溫度，壓縮行程漏熱變多，**燒不完全 → 未燃油氣與碳煙進排氣系統**，冷凝成像機油的黑液滲出。**關鍵是它會正回饋**（原文稱 "progressive condition"）：碳煙同時堵噴油嘴 → 霧化變差 → 更燒不完全。長期可能需大修，費用高到換新機較划算。

治療帳單（2750 kW ESP，75% 銘牌連續 3 h）：

```
能量 = 2750 × 0.75 × 3 = 6187.5 kWh
75% 效率 ≈36% → SFC = 3.6/0.36/35.53 = 0.2814 L/kWh（公式見 dc-05）
柴油 = 6187.5 × 0.2814 ≈ 1741 L
該機 Class 48 儲油 = 1925 × 0.267 × 48 ≈ 24,671 L
→ 一次治療燒掉 48 小時儲備的 7.1%，並吃掉年度配額 1.5%
```

⚠️ 安全（CSE 原文）：75% 負載的排氣溫度**高於柴油自燃點**，積碳嚴重的機組治療時排氣系統內起火雖罕見但確有發生。長期輕載或無近期帶載記錄者，**治療必須交專業維護商**。

## 常見誤解

**以為 30% 的分母是「這台機的容量」，但實際上是 ESP standby 銘牌 kW——五個額定裡最大的、且不套場址降載。** 用 COP 或降載值當分母會系統性少載 20% 以上，而你手上的測試報告會說「合規」。這是全鏈唯一一個**合規文件本身會掩蓋物理劣化**的地方。

**以為排氣溫度法是「比較寬鬆的替代路徑」，但實際上它是兩條互斥路徑之一，且事前不確定會不會過。** 選它就要每次測試量排氣溫度並留記錄，前提是手上有原廠給的最低溫度值。它不是 30% 的降級版，是**另一套證據要求**。

**以為 75% 的治療負載違反 ESP「24 小時平均不得超過 70%」，但實際上那是 24 h 平均而非瞬時上限。** 3 小時 75% 的 24 h 平均只有 `2062.5 × 3 / 24 = 258 kW = 9.4%`。「不得超過 70%」與「不得超過 2750 kW」是兩種不同的約束——**混用會讓你在該跑的時候不敢跑。**

## 來源分歧

**分歧一：避免 wet stacking 的最低負載是 30% 還是 40%？** NFPA §8.4.2 與引述它的來源（Curtis、CSE）一致寫 **30%**；廠商與維護商的 wet stacking 專文普遍寫「低於 **40%** 無法達到完全燃燒溫度」。兩邊不是誰錯——**30% 是法規最低門檻，40% 是工程建議值**。實務含意：**照 30% 測是合規的，但不保證不 wet stacking。** 該向原廠要的是「最低建議連續負載」與「最低排氣溫度」兩個數字。

**分歧二：NFPA 110 在台灣有沒有法定強制力？** 它是美國標準，台灣法定依據是消防與電業法規及 CNS 體系，兩者不自動等同；實務上國際 colo 客戶、Uptime 認證與外商租戶合約常直接引用它。**本卡所有條文編號應視為「合約要求」而非「當地法令」，除非法規顧問另行確認。**

## 對資料模型的意涵

1. **`test_event` 上不能有 `test_type` enum。** §8.4.9.6 允許一次測試同時滿足三條要求，所以測試事件與合規要求是**多對多**。正確形狀是 `test_event(id, ts_start, ts_end, initiating_ats_id, compliance_path, exhaust_temp_c, min_exhaust_temp_ref_c)` 加一張 `requirement_satisfaction(test_event_id, requirement_id, verdict)`。合規查詢因此是**覆蓋問題**（過去 12 個月每條要求有沒有被至少一個事件滿足），不是查最近一筆記錄。

2. **判定是兩條互斥路徑的 OR，而每條要求不同欄位存在。** `compliance_path ∈ {LOAD_PCT, EXHAUST_TEMP}` 配 CHECK：前者要 `loaded_minutes_at_threshold NOT NULL`，後者要 `exhaust_temp_c` **與** `min_exhaust_temp_ref_c` 都 NOT NULL。後者意味 `genset` 表上必須先有 `min_exhaust_temp_c`（來自原廠手冊）——**資料庫沒有那個數字，路徑 B 就不存在**。合規能力被欄位存在性決定。

3. **兩個鐘分開存。** `loaded_minutes_at_or_above(threshold)` 是從 `output_kw` 時序**積分出的 derived 值**，不是操作員填的 30；`runtime_hours` 是含冷卻的引擎時數，用來扣 ESP 配額。延續 dc-05 的分組累計，`trigger` 擴充為 `{TEST_MONTHLY, TEST_ANNUAL_SUP, TEST_36M, OUTAGE, COMMISSIONING, WET_STACK_CURE}`——最後一個要獨立，它是**非計畫**消耗，出現本身就是異常訊號。

4. **§8.4.3 的 ATS 輪替讓合規對象變成一組邊，不是一個節點。** 「這台發電機月測合規」是沒有意義的斷言，正確的是「(genset, ats) 配對在過去 N 個月被驗證過」。`initiating_ats_id` 必填，並要有覆蓋查詢：**此 EPSS 的每一台 ATS 是否都當過起動者。** 全鏈第一個掛在圖的**邊**上而非頂點上的約束。

## 該問 facility 的問題

1. **月測走 30% 負載還是排氣溫度路徑？** 走溫度的話，原廠手冊的最低值幾度、量測點在哪、誰記錄？走 30% 的話請調最近三次月測記錄對分母。
2. **年度補充 load bank 測試怎麼做？** 租還是常設？多大？排熱擺哪？爬坡期前兩年幾乎必然要租，預算編了嗎？
3. **NFPA 110 對我們是法令還是合約？** 誰是 AHJ？租戶合約有沒有引用條文編號？

## 動手練習（30–40 分鐘）

接續 dc-05 的 `Genset` 與 dc-05b 的 `StartEvent`，長出**合規引擎**。要擋住三件事：**(a) 30% 的分母只能是 ESP 銘牌；(b) 合規分鐘數從時序積分而非直接填；(c) 一個事件可滿足多條要求。**

```python
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum

Req  = Enum("Req",  "MONTHLY ANNUAL_SUPPLEMENTAL TRIENNIAL")
Path = Enum("Path", "LOAD_PCT EXHAUST_TEMP")
COOLDOWN_MIN = 5.0                              # NFPA 8.4.5 shutdown 延時下限

@dataclass
class TestEvent:
    ts_start: datetime
    samples: list[tuple[datetime, float]]       # (時間, output_kw)，每分鐘一點
    initiating_ats_id: str
    path: Path
    load_bank_kw: float = 0.0
    exhaust_temp_c: float | None = None
    min_exhaust_temp_ref_c: float | None = None

    # TODO __post_init__：path == EXHAUST_TEMP 但兩個溫度欄位任一為 None → ValueError
    # TODO loaded_minutes_at_or_above(kw) -> int
    #      「連續」達標的最長分鐘數，中途掉下門檻要重新計時
    #      —— "30 continuous minutes" 是字面意思，累計 30 分鐘不算
    # TODO engine_minutes() -> float          # 含 COOLDOWN_MIN

@dataclass
class ComplianceEngine:
    esp_nameplate_kw: float                     # 唯一合法的分母
    events: list[TestEvent] = field(default_factory=list)

    # TODO threshold_kw()  = esp_nameplate_kw * 0.30
    # TODO satisfies(ev, req) -> bool
    #      MONTHLY:    連續 30 min 且 (≥threshold 或 排氣溫度達標)
    #      ANNUAL_SUP: ≥50% 連續 30 min 且 ≥75% 連續 60 min
    #      TRIENNIAL:  ≥30% 連續 240 min，或合併版 前 180 min ≥30% + 後 60 min ≥75%
    # TODO annual_supplemental_required(recent_months=12) -> bool
    # TODO load_bank_kw_required(available_kw)：三段缺口取 max，不是取 30% 那段
    # TODO ats_rotation_gaps(all_ats_ids, months=12) -> list[str]
    # TODO annual_runtime_hours(combine_triennial: bool)
    #      三年攤提後的年均，接回 dc-05 的 runtime_quota_status()
```

**驗收標準**

| 呼叫 | 期望 |
|---|---|
| `threshold_kw()`（ESP 2750） | **825.0** |
| 誤用 COP 2100 建立後同一呼叫 | **630.0**——註解寫明這是錯的分母 |
| `load_bank_kw_required(560)` / `(1400)` | **1502.5**（不是 265）/ **662.5** |
| 前 20 min 達標、掉 1 min、再 25 min，`loaded_minutes_at_or_above` | **25**（不是 45） |
| 上題 `satisfies(ev, MONTHLY)` | **False** |
| `TestEvent(path=EXHAUST_TEMP, exhaust_temp_c=None)` | **raise ValueError** |
| `annual_runtime_hours(False)` / `(True)` | **≈ 8.83 / 8.17** |
| 同上換算引擎時數 | **≈ 10.2 h/年**（兩個鐘要差得出來） |
| 4 台 ATS、12 個月只有 2 台當過起動者 | 回傳**另外 2 台 id** |

**加分題**：寫 `wet_stack_cure_cost(0.75, 3)` 回傳 `(kwh, litres, quota_hours)`，比對 `dc-06` 的儲油量 → **一次治療燒掉 48 小時儲備的 7.1%**。真正的產出是：**wet stacking 的成本不是維修費，是它同時吃掉燃料儲備與年度運轉配額，而這兩樣都是停電時要救命的。**

## 自我檢核

**Q1. 維護商回報「本月測試完成，帶 700 kW 跑了 45 分鐘，合規」。這台是 Cummins DQLF（ESP 2750 / COP 2100）。合規嗎？**

??? note "答案"
    **不合規。** 門檻是 **ESP 銘牌** 2750 × 30% = **825 kW**，700 kW 只有 25.5%。維護商很可能拿 COP 2100 當分母（× 30% = 630，700 就過了），或拿場址降載的 2393（= 718，仍差）。跑 45 分鐘不能補償負載不足——**時間與負載是 AND**。
    第二層：若 700 kW 已達**廠商建議最低排氣溫度**，走路徑 B 一樣合規。所以正確追問是「走哪條路徑？量到幾度、原廠要求幾度、記錄在哪？」——**沒有排氣溫度記錄就只剩路徑 A，那就是不合規。**
    第三層：不合規的後果不是罰款，是**觸發年度補充 load bank 測試義務**。

**Q2. 機房 IT 400 kW、PUE 1.4。要準備多大的 load bank？為什麼直覺答案會少五倍？**

??? note "答案"
    發電機側 = 400 × 1.4 = **560 kW** = 銘牌 20.4%，月測過不了，因此**每年**必須做補充測試。三段缺口：30% 段 265 kW、50% 段 815 kW、**75% 段 1502.5 kW**，取 **max = 1502.5 kW**（實務租 1600 kW 級）。
    直覺抓 265 kW，因為那是「月測不合規」直接看到的數字——但月測不合規觸發的是**年度測試**，年度測試最高段是 75%，規格由它決定，差 5.7 倍。

**Q3.「一次 36 月測試可以同時算作一次月測與一次年度測試」——這會讓你的資料模型長出什麼欄位？它跟前六張卡的建模問題有什麼結構性不同？**

??? note "答案"
    它讓 `test_event` **不能有 `test_type` 欄位**，並長出 `requirement_satisfaction(test_event_id, requirement_id, verdict)` 中介表。事件與要求是**多對多**：一個事件滿足多條要求，一條要求也可被不同事件在不同月份滿足。合規查詢因此是「過去 12 個月每條要求是否被至少一個事件覆蓋」的**覆蓋問題**。
    **結構性不同**：前六張卡的難題都是**欄位語意不足**——dc-02 量測條件、dc-03 時間、dc-03b 互鎖約束、dc-04 變更者、dc-05 用途分級、dc-05b 只存在於歷史裡的當前值，都在說「這個欄位需要更多脈絡」。這一張說的是另一件事：**事實與規則之間不是一對一。** 同一筆事實可同時是三條規則的證據，所以「規則」必須被實體化成資料列（`requirement` 表），不能寫死在 if 分支或 enum 值裡。
    **延伸**：§8.4.3 的 ATS 輪替讓合規對象變成 `(genset, ats)` 這組**邊**——全鏈第一個掛在圖的邊上而非頂點上的約束。

---

**下一張**：`dc-06` 日用油箱與儲油槽 —— 接住 dc-05 的 13.4 m³ 與本卡的 24,671 L，處理兩級油箱結構、補油邏輯與燃料劣化。
