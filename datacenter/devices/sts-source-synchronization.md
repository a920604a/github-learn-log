---
id: dc-10c
title: STS 的兩源關係（二）相位同步窗與頻率漂移
category: power
written_at: 2026-08-27
sources:
  - https://www.vertiv.com/497729/globalassets/products/critical-power/static-transfer-switches/liebert-sts2-static-transfer-switch/vertiv-liebert-sts2-1200a--1850a-3p-chassis-guide-specifications-sl-20603.pdf
  - https://journal.uptimeinstitute.com/dual-corded-power-details-change-theme-remains/
  - https://www.csemag.com/managing-risks-benefits-with-closed-transition-transfer-switches/
  - https://www.iecee.org/certification/iec-standards/iec-62310-32008
related: [dc-02, dc-08, dc-10, dc-10b, dc-16]
---

# 兩源關係（二）：相位同步窗與頻率漂移

[dc-10b](sts-two-source-relationship.md) 處理了兩源關係的**圖性質**（共祖）與**集合極值**（雙母線容量）。第三件事住在**時間軸**上：兩個源的電壓波形對不對得起來。它跟前兩件是不同的數學——前兩件算完就固定，這一件**每秒都在變，或者更糟：永遠不變**。

> 數字取自 Vertiv Liebert STS2（1200–1850 A，2023 版規格書）。**同步窗是廠商可調設定，不是通用常數**，換廠商要重查。

## 六格

### 拓撲位置

主體是**一對邊**，不是一台設備。決定它們同不同步的東西在更上游：兩條路徑各自經過的[變壓器向量組](transformer.md)、是否同源。**STS 只是這個關係的觀測者與受害者。**

### 容量單位

**電氣度（°）與 Hz。** 三個數字量三件事，絕對不能混：使用者可調**同步窗**（Vertiv 上限 ±30°）／設備**可容忍失相轉換能力**（保證 30°，買 Optimized Transfer 後 ±180°）／MBB 重疊導通的**物理安全條件**（約 5°）。

### 冗餘表達

同步不是冗餘，但**同步失敗會讓已買單的冗餘無法兌現**：兩源都健康、帳面 2N，轉換就是按不下去。這是 dc-10「會讓冗餘歸零」清單的第五項。

### 遙測介面

| 點位 | 意義 |
|---|---|
| `Synchronization phase angle`（Vertiv 列為常規計量值） | 即時相位差。**全卡唯一直接可觀測的兩源關係數字**，務必進歷史記錄 |
| `Sources Out of Sync` | 超出同步窗 → 手動轉換被拒 |
| `Source 1/2 Over/Under Frequency` | 各自的屬性，**推不出關係**（見誤解 1） |
| `Source 1/2 Phase Rotation Error` | 相序錯 = **接線缺陷**，不是運行狀態 |

### 故障域

同步失效**當下不會讓任何人掉電**——這正是它危險的原因。它只在「需要轉換的那一刻」兌現成停電，而那一刻通常是別的東西已經壞掉的時刻。

### 維護特性

**這是設計期缺陷，不是運維狀態。** commissioning 要專門測：兩源實際相位差、手動轉換能不能真的按下去。錯過就是在事故報告裡才發現。

## 關鍵數字與計算

### 演算 1：頻率差決定窗多久開一次，而 Δf = 0 可能代表永遠不開

相位差以 **360° × Δf 度／秒**滑動。同步窗寬 60°（±30°）：

```
滑動率   = 360 × Δf        (°/s)
窗內時間 = 60 / (360 × Δf)  窗重現週期 = 1 / Δf
```

| Δf | 滑動率 | 每次窗內時間 | 多久開一次 |
|---|---|---|---|
| 0.5 Hz | 180 °/s | **0.33 s** | 2.0 s |
| 0.1 Hz | 36 °/s | **1.67 s** | 10.0 s |
| **0 Hz（兩源同接市電）** | 0 | **0 或 ∞** | **永不改變** |

最後一列是全卡重點。Δf = 0 不代表同步，代表相位差**凍結**：落在窗內永遠能切，落在窗外**永遠切不了**，且不會隨時間變好。

**什麼造成凍結的偏移？向量組。** Dyn11 與 Dyn1 的時鐘數差 2，每格 30°：

```
相位差 = |11 − 1| × 30° = 60°（固定）

60° > 同步窗上限 30°          → 手動轉換永遠被拒
60° > 保證可容忍失相 30°      → 緊急轉換超出廠商保證範圍
```

**驗收當天兩個源都是綠燈**，因為每個源各自都在規格內。壞的是關係，成因是**兩台變壓器銘牌上的一個字串**——不在 STS 身上、也不在任何電氣量測裡。這是「A 的欄位決定 B 的合法性」在本軌跡的**第三次**（[dc-02](transformer.md) 阻抗決定 [dc-07b](lv-short-circuit-and-coordination.md) 合法性；接地系統決定極數）。

**對照組**：ATS 切「市電 vs 發電機」時 Δf ≠ 0（發電機在調速），窗會週期性打開，同步檢查是**等待**問題；STS 切兩條市電母線時 Δf = 0，同步檢查是**是非**問題。**同一個名詞，兩種行為。**

### 演算 2：`transfer_time_ms` 是個有歧義的欄位——證明如下

買了 Optimized Transfer 後可在任意相位轉換，代價是轉換時間拉到「typically less than one line cycle」。拿 dc-10 那個 18 ms 重載 SMPS 實測 ride-through 硬減：

```
60 Hz：18 − 16.67 =  1.33 ms
50 Hz：18 − 20.00 = −2.00 ms   ← 負的
```

**但這個減法不成立。** Vertiv 明寫 optimized transfer 期間會 pulse-fire 對側 SCR，**負載電壓全程維持在 ITIC 曲線內**——那一個週期不是「一個週期的 0 V」。

價值不在數字，而在它證明了：**`transfer_time_ms` 到底是「離開舊源到接上新源」還是「負載看到的斷電時間」？** 兩者在快速 BBM 下幾乎相等（所以前十張卡沒出事），在 optimized transfer 下差一個數量級。**存成一個 float 的系統，會在有人為了下游變壓器打開這個選項那天開始說謊——而且往「看起來比實際更快」的方向說謊。** 跟 [dc-11](pdu-floor.md) 的命名規約同一個病根。

## 常見誤解

**以為兩源頻率相同就是同步，但實際上頻率是各自的屬性、同步是關係的屬性，前者推不出後者。** 兩條饋線同接市電時 Δf 必為 0，兩個 `Frequency` 讀值一模一樣——而相位差可能凍結在 60° 永遠切不過去。**要看 `Synchronization phase angle` 這個成對點位，不是兩個各自的頻率。**

**以為雙路設備需要兩個源同步才安全，但實際上真正雙路的設備完全不在乎。** Uptime 的 Fault-Tolerant Power Compliance Spec 白紙黑字：兩個 AC 源**可以**不同步，電壓、頻率、相序、相位角各不相同都行，只要各自在規格內。同一份規格更狠——**設備內外的主動切換裝置（機械式或電子式轉換開關）不被接受**為容錯手段。**同步是 STS 的需求，不是負載的需求。** 為少數單路設備引進一台 STS，等於把「兩條路必須同相」強加到整個 A/B 系統的設計上，代價由所有負載共同承擔。

**以為同步窗是一個「這台 STS 能容忍多少度」的數字，但實際上那是三個不同的數字**（見「容量單位」格）。混用會做出「窗口設 180 度」這種 UI 上看似合法、實際上是拿負載去撞失相轉換的設定。

## 來源分歧

**分歧一：BBM 還是 MBB —— 本卡取得的新證據讓它收斂了一半。**

- **Socomec**：預設且建議 **BBM**；MBB「技術上可行但很少用，重疊兩個獨立源會產生不受控的環流」。
- **Vertiv STS2（2023）**：措辭沒有模糊空間——「All transfers shall be **a fast break-before-make with no overlap** in conduction」、「The switching action **shall not connect together the two sources** that would allow backfeeding」。

**兩份獨立來源在「獨立兩源之間的 STS」上一致：BBM。** 那些講 MBB 重疊導通的資料，講的很可能是 **UPS 內部**的靜態開關（逆變器↔旁路，同一台 UPS 主動同步）——同名，同步前提完全不同。**仍未收斂的是**：Optimized Transfer 會 pulse-fire 對側 SCR 以維持電壓，功能上介於兩者之間，規格書仍稱它是 BBM。該問的是「**pulse firing 期間兩側 SCR 是否曾同時導通**」。

**分歧二：修正 dc-10b 的一筆記載。** dc-10b 寫「Vertiv 邊界未明說」。**2023 版規格書其實明說了**：MTBF 定義為「the actual arithmetic average time between failures of **the critical AC output bus**」——跟 PDI/Eaton 幾乎逐字相同的邊界，數字卻是 >100 萬 h vs >200 萬 h。

所以「分歧來自邊界」只成立一部分：**邊界敘述相同的兩家仍差 2 倍，剩下的差異來自各自的計算方法，而沒有一家公開它。** dc-10b 演算 3 的結論不受影響，因為那算的是比值。

## 對資料模型的意涵

1. **`SourcePair` 要是一等公民。** 同步不是 `Sts` 的欄位，是 `(edge_a, edge_b)` 這一對的衍生值。`SourcePair` 掛在 dc-10b 的 `DeviceRegistry` 上，`phase_offset_deg()` 從兩條路徑的向量組累加算出。**STS 只是這對關係的消費者**——`dc-16` 的設備端雙電源會是第二個。

2. **三個角度是三個欄位，型別不同。** `sync_window_deg`（設定，可寫）／`emergency_tolerance_deg`（能力，唯讀）／`mbb_safe_deg`（物理常數）。三者同為 float 就一定有人填錯——沿用 W34 的 `Bound` 值物件，把「這是哪一種角度」變成型別的一部分。

3. **`transfer_time_ms` 拆成 `switch_time_ms` 與 `load_dead_time_ms`。** 演算 2 證明兩者可差一個數量級，且合成誤差永遠往安全方向。套 [dc-11](pdu-floor.md) 的規約精神：**量測基準必須跟值住在一起。**

4. **`vector_group` 要進 `Transformer`，並成為可求值的 `Policy`：** `SourcePair` 兩側路徑向量組不一致 → `Finding(CRITICAL)`。**這是設計期稽核不是告警**——不會隨時間消失，也不該能被 ack（沿用 dc-10b「`is_redundant` 不准存成欄位、改出稽核報表」）。

5. **`Sources Out of Sync` 與 `Phase Rotation Error` 生命週期不同，不能同一張表。** 前者是狀態（Δf ≠ 0 時每秒在變），後者是接線缺陷（改接線前永遠為真）。混在同一個告警流，前者的噪音會淹掉後者。

## 該問 facility 的問題

1. **「兩條源上游的變壓器向量組分別是什麼？把兩張銘牌照片給我。」** 五分鐘可答，且它決定演算 1 是「窗週期性打開」還是「窗永遠關著」。
2. **「同步窗設幾度？有沒有買 Optimized Transfer？`Synchronization phase angle` 現在讀值多少、穩定嗎？」** 第三問是即時診斷：穩定停在某個非零值 = Δf 為 0 的凍結偏移。
3. **「commissioning 有沒有排『兩源實際相位差量測 + 手動轉換實測』？」** 錯過就要等事故。

## 動手練習（30–40 分鐘）

**接在 [dc-10b](sts-two-source-relationship.md) 的 `DeviceRegistry` 下游**：那次建好圖與 `ancestors()`，今天在同一張圖上長出 `SourcePair`。

```python
from dataclasses import dataclass
from enum import Enum

class AngleKind(Enum):                 # ★ 三種角度不同型別（意涵 2）
    SYNC_WINDOW = "setting"            # 可寫，Vertiv 上限 30
    EMERGENCY_TOLERANCE = "capability" # 唯讀，30 或 180
    MBB_SAFE = "physics"               # 常數 ~5

@dataclass(frozen=True)
class Angle:                           # W34 的 Bound 值物件用在角度上
    deg: float
    kind: AngleKind
    # TODO __post_init__: SYNC_WINDOW 且 deg > 30 -> raise
    # TODO 不同 kind 之間禁止比較（__lt__ 檢查 kind 相同，否則 TypeError）

@dataclass
class SourcePair:
    id: str
    a_edge_id: str
    b_edge_id: str
    sync_window: Angle
    emergency_tolerance: Angle
    # TODO phase_offset_deg(reg) -> float
    #   沿兩條路徑各自累加 Transformer.vector_group 的時鐘數 × 30，取差、正規化到 (-180, 180]
    # TODO freq_delta_hz(reg) -> float          兩源頻率差（同源回 0.0）
    # TODO slip_rate_deg_s()  -> float          360 * freq_delta_hz
    # TODO window_open_period_s() -> float | None   1/Δf；Δf==0 回 None（永不重現）
    # TODO time_in_window_s()    -> float | None   (2*window)/slip；Δf==0 時
    #      → 依 phase_offset 落在窗內回 inf、窗外回 0.0   ★ 這一格是全卡的重點
    # TODO manual_transfer_allowed(reg) -> bool
    # TODO audit(reg) -> list[Finding]
    #   規則 4：|phase_offset| > sync_window.deg 且 Δf == 0
    #           -> CRITICAL「同步窗永不開啟」，policy_id="VECTOR_GROUP_MISMATCH"
    #   規則 5：|phase_offset| > emergency_tolerance.deg -> CRITICAL

# TODO effective_dead_time_ms(algorithm, line_hz, itic_compliant: bool) -> float
#   "POG": 0.25 cycle ／ "VSS": 0.75 cycle ／ "OPTIMIZED": 1.0 cycle
#   ★ itic_compliant=True 時 dead time 不等於 switch time —— 回 0.0 並在 docstring
#     寫清楚為什麼（演算 2）。這兩個值就是意涵 3 要拆的兩個欄位
```

**建圖**：沿用 dc-10b 那張，`xfmr1` 標 `vector_group="Dyn11"`，新增 `xfmr2` 標 `"Dyn1"` 供 `ups_B`。

**驗收**

| 情境 | 期望 |
|---|---|
| `phase_offset_deg()`（Dyn11 vs Dyn1） | **60.0** |
| 兩側都改 `Dyn11` 後 | **0.0** |
| `freq_delta_hz()`（兩源同追市電） | **0.0** |
| `window_open_period_s()`，Δf=0 ／ Δf=0.1 | **None** ／ **10.0** |
| `time_in_window_s()`，offset=60 且 Δf=0 | **0.0**（永遠切不了） |
| 同上但 offset=10 | **inf**（永遠切得了） |
| `manual_transfer_allowed()`，offset=60 | **False** |
| `audit()`，offset=60 | 含規則 4 **與** 規則 5 兩條 CRITICAL |
| `Angle(45, SYNC_WINDOW)` | **raise**（超過廠商上限） |
| `Angle(30, SYNC_WINDOW) < Angle(180, EMERGENCY_TOLERANCE)` | **TypeError**（不同 kind 不可比） |
| `effective_dead_time_ms("VSS", 50, False)` ／ `("OPTIMIZED", 50, True)` | **15.0** ／ **0.0** |

**最後兩列是練習的目的**：讓型別系統擋掉「拿設定值跟能力值比大小」，讓 dead time 與 switch time 在簽章上就分得開。

**加分題**：把 `time_in_window_s()` 的 `inf` / `0.0` 改成 `Literal["always","never"] | float`，數一數**呼叫端有幾處被迫處理三種情況**——那就是「Δf = 0 是特例」的真實成本。

## 自我檢核

**Q1. 儀表板：Source 1 頻率 60.00 Hz、Source 2 頻率 60.00 Hz、兩源電壓皆正常。運維說手動轉換按下去永遠是 `Sources Out of Sync`。診斷方向？把數字算出來。**

??? note "答案"
    **頻率相同正是壞消息。** Δf = 0 → 相位差凍結，不會隨時間滑進窗口。頻率是各自的屬性，同步是關係的屬性。

    最可能成因是**上游兩台變壓器向量組不同**：Dyn11 vs Dyn1 時鐘數差 2 → 固定 `2 × 30° = 60°`，同時超過同步窗上限 30° 與可容忍失相 30°，**手動與緊急轉換都不保證**。

    **診斷順序**：先看 `Synchronization phase angle`（穩定停在 ~60° 即確診）→ 核對兩台變壓器銘牌向量組 → 最後才懷疑設定值。**這是設計期缺陷，驗收當天兩個源都是綠燈。**

**Q2. 有人提議「把同步窗從 30° 調到 180°，這樣就永遠不會 Out of Sync 了」。這個提議錯在哪？**

??? note "答案"
    **它把三個不同的數字當成同一個。** 180° 是**買了 Optimized Transfer 後的設備能力**，不是**使用者可調同步窗**的合法值——Vertiv 明訂該窗上限 ±30°。

    更根本的是：`Sources Out of Sync` 不是要消除的噪音，**它是唯一會告訴你「這兩條路對不齊」的訊號**。把窗開到 180° 等於關掉偵測，然後在某次真的需要手動轉換時拿整區負載去撞任意相位。正確做法是**修成因**（向量組）而非**放寬判準**——W34 那條規律：**讓標準變嚴的錯誤會立刻誤報、有人來查；讓標準變鬆的錯誤沒有人會發現。**

**Q3.（建模）「同步」這件事會讓你的資料模型長出什麼欄位、什麼約束、什麼查詢？跟 dc-10b 的獨立性與容量在結構上有什麼差別？**

??? note "答案"
    **欄位**：`Transformer.vector_group`（成因住在這裡，不在 STS 上）；`SourcePair(a_edge_id, b_edge_id, sync_window, emergency_tolerance)`；三種 `Angle` 各帶 `kind`；`switch_time_ms` 與 `load_dead_time_ms` 分開。**`phase_offset_deg` 不是欄位**——存下來就會在有人換變壓器那天說謊。

    **約束**：`Angle(kind=SYNC_WINDOW).deg ≤ 30`；不同 `kind` 禁止比較；兩側向量組不一致 → `Finding(CRITICAL)` 進**稽核報表**而非告警流。

    **查詢**：沿 dc-10b 建好的圖走兩條路徑——**今天沒有新建圖，是在既有的圖上加了第二種遍歷**（第一種是 `ancestors()`）。

    **結構差別**：

    ```
    dc-10b 獨立性  ：圖的性質      → 算完就固定，改接線才變
    dc-10b 容量    ：配置集合極值   → 算完就固定，加負載才變
    dc-10c 同步    ：時間的函數     → 每秒都在變 …… 除非 Δf = 0，那就永遠不變
    ```

    第三種的麻煩在於**它的「靜態」與「動態」是同一個欄位的兩種模式**，而危險的恰好是靜態那一種。所以 `time_in_window_s()` 必須能回傳 `always` / `never` 這種非數值答案——**把 Δf = 0 當成除以零去擋掉的實作，會剛好漏掉唯一真正致命的情況。**
