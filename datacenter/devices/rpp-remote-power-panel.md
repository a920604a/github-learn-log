---
id: dc-12
title: RPP 遠端配電盤（remote power panel）
category: power
written_at: 2026-08-28
sources:
  - https://www.layerzero.com/service-and-support/faqs/what-is-an-remote-power-panel-rpp/
  - https://www.iemfg.com/system/uploads/fae/file/asset/110/IEM_Product_Sheet_RPP_2025-05-15.pdf
  - https://www.eaton.com/content/dam/eaton/products/backup-power-ups-surge-it-power-distribution/power-distribution-for-it-equipment/eaton-remote-power-panel/eaton-remote-power-panel-brochure-RPP02FXA.pdf
  - https://library.e.abb.com/public/613ecc73ae5c423fa3ec04c9d7f42313/RPP_Catalougue_9AKK108466A4423.pdf
  - https://up.codes/s/determining-existing-loads
  - https://viox.com/80-vs-100-rated-circuit-breakers/
related: [dc-07, dc-10b, dc-11, dc-13, dc-14, topic-01, topic-02, topic-04]
---

# RPP 遠端配電盤（remote power panel）

把分路盤從 PDU 身上拆下來、推到機櫃旁邊的那個窄櫃子（IEM 那台 24″×12″×90″，比機櫃還瘦）。不降壓、不切換、不儲能——**唯一做的事是把一條粗的變成 84 條細的，並且量每一條**。[dc-11](pdu-floor.md) 說 PDU 是第一次分岔；RPP 是**分岔被搬到現場**。

## 六格

### 拓撲位置

上游：[PDU](pdu-floor.md) 的 subfeed、[STS](sts-two-source-relationship.md)，或直接吃 [LV 盤](lv-switchgear.md)。下游：`dc-13` busway、`dc-14` rack PDU 的 whip。

**來源分歧（本卡最大的一個）**：Schneider WP61 把「非變壓器型 PDU」直接**叫做 RPP**；LayerZero FAQ 明說 RPP **不是** PDU，是 PDU **下游**再一級。兩種都真實存在。**後果是拓撲深度不確定**——UPS→機櫃可能 2 跳也可能 3 跳，而 [dc-10b](sts-two-source-relationship.md) 的 common-ancestor 吃的正是跳數。**問清楚，不要從名字推。**

### 容量單位

**A（主開關）× pole 數 × 內部母線段**——比 dc-11 多第三維。ABB 一台 400 A 進線的 RPP，`Ina` 標 **2×250 A**（兩條 SMISSLINE 母線各 250 A）。主開關夠，不代表你要插的那條母線夠。

廠商實例：IEM 400 A / 84 單極 / **標配 100% rated**（80% 選配）；Eaton 450–900 A / 4×42 = **168 極** / 80% 或 100% 可選；ABB 250–800 A / 80–320 極 / 180–576 kW @415 V。

### 冗餘表達

跟 PDU 同：不做 N+1，做 A/B 兩台。ABB 賣點是把 A、B 裝進**同一個櫃子**（省 50% 佔地）——**這對故障域是壞消息**：共櫃 = 共火災、共淹水、共誤操作。冗餘在電氣上成立、空間上不成立，正是 [dc-10b](sts-two-source-relationship.md) 說的「獨立性要逐維度檢查」。

### 遙測介面

Modbus TCP / RTU、SNMP（ABB 支援 v3 加密）。RPP 是電力鏈上**第一個標配 BCMS（分路監測）的節點**——IEM「all circuits monitored」、0.5% 精度、true RMS；Eaton EMS 存 24 個月 load profile。dc-11 抱怨的「沒有 BCMS 就只能用推的」在這層被解決。

必收：每分路電流 / kWh、主入 kW·kVA·PF、每相電流、**中性線電流**、**電流 THD**，Eaton 還有 **ground current**（≠ 0 即絕緣劣化）。

### 故障域

主開關跳 → 該 RPP 下所有機櫃的**那一邊**沒電；單一分路跳 → 只死一條 whip。**故障域被切細**，這是 RPP 存在的第二個理由。

### 維護特性

紅外線熱像（IEM/Eaton 都給 IR 窗，帶電掃）、端子扭力複緊。**「加一條迴路要不要停電」是設備屬性不是通則**——bolt-on 要停整盤，ABB SMISSLINE 可帶電插拔 MCB（IP2XB 防指觸）不用。ABB 另明說溫升要做工程驗證：塞滿 84 極的窄櫃是熱問題不是電氣問題。

## 關鍵數字與計算

### 1. 80% vs 100% rated：同一顆 400 A，兩個答案

[dc-11](pdu-floor.md) 把 ×0.80 當常數用了。**錯的。** NEC 210.20(A) 要求 OCPD ≥ 125% 連續負載（80% 是倒數）；但其**例外**允許：斷路器**與外殼的組合**經 UL 489 §7.1.4 測試並標示 100% rated 時，直接用 100%。IEM 的 RPP **標配就是 100% rated LSI**。

380Y/220V、400 A 主開關：

| rating style | 計算 | 連續可用 |
|---|---|---|
| 80% rated | `√3 × 380 × 400 × 0.80` | **210.6 kVA** |
| 100% rated | `√3 × 380 × 400` | **263.3 kVA** |

差 **52.7 kVA ≈ 8.7 個 6 kW 機櫃**。把 0.80 寫死在 code 裡，等於在每台 100% rated 的 RPP 上**憑空丟掉 9 個機櫃**。

**且 100% 不是斷路器單獨的屬性**——不能拿一顆 100% 斷路器隨便丟進任何盤就當 100% 用，外殼必須一起被列名（通常還要求 90 °C 端子導線）。它是 `(breaker, enclosure)` 這個**組合**的屬性。

### 2. 分路銘牌總和 > 主開關，這是正常的

IEM 標配 (28) 30 A/3P 掛在 400 A 主下：`28 × 30 = 840 A`，是主開關的 **2.1 倍**。這**不是配置錯誤**——負載不同時滿載，這叫 diversity。寫一條 `sum(branches) <= main` 的驗證，等於把出廠標配判成違規。

那怎麼知道還能不能加？**用量的，不是用算的。** NEC 220.87（**美規；台灣走屋內線路裝置規則，數字要另查**）：有 1 年（或連續紀錄 30 天）實測資料時，既有負載 = **1.25 × 期間最大需量**。

400 A 100% rated 主，BCMS 顯示 30 天峰值 **180 A**：既有 = `180 × 1.25` = **225 A**；剩餘 = `400 − 225` = **175 A**；換算 `√3 × 380 × 175` = **115.2 kVA** ≈ **19 個 6 kW 機櫃**。

同一台盤：銘牌加總法說「840 > 400，滿了」，實測法說「還能加 19 櫃」。**兩個都不是 bug，是兩種 method。** 所以 `headroom()` 必須回「數字 + 用哪個 method 算的」。

### 3. 母線段與相鄰限制：sum 通過、segment 不通過

ABB 400 A 進線 = 2×250 A 母線。A 段掛 300 A、B 段 100 A → 總和 400 A ✓，**A 段超 250 A ✗**。

IEM 更細：單顆分路最大 125 A，**但並排相鄰兩顆總和上限 150 A**（散熱）。兩顆 100 A 各自合法（≤125），**並排就違規**（200 > 150）。這是**成對約束**——dc-11 的 `validate()` 只檢查位置重疊與越界，接不住它。

### 4. 中性線 200%

IEM 與 Eaton 都標 **Neutral Rating 200%**。400 A 主 → 中性排 **800 A**。這是 dc-11 那組 triplen 疊加（平衡三相、30% 三次諧波 → 相 104 A、中性 90 A）在硬體上的回答：**中性線不是「跟相導體一樣粗」，是兩倍。** 所以中性線告警門檻**不能沿用相電流門檻**，是獨立欄位。

## 常見誤解

**以為連續負載一律打 8 折，但實際上 0.80 是「80% rated 組合」的屬性，不是物理常數。** 100% rated（IEM 標配、Eaton 選配）不打折；寫成全域常數會系統性低估 25%。

**以為分路銘牌加總超過主開關就是配置錯誤，但實際上那是出廠標配（840 A on 400 A）。** 判斷還能不能加要用 30 天實測峰值 ×1.25。寫成 hard validation 會擋掉所有真實資料。

**以為 42 極是法規上限，但實際上 NEC 2008 就刪掉了「42 電路限制」**（只在 split-bus 等特例仍適用），Eaton 單台 168 極。極數上限是**廠商列名與盤體物理**，是 `Panelboard` 的欄位，不能 hard-code。

## 對資料模型的意涵

1. **降載係數必須帶出處，不能是常數。** `Breaker.rating_style: Literal["80_percent","100_percent"]`，**加上 `Panelboard.enclosure_listed_100pct: bool`**——因為 100% 是組合屬性。約束：宣告 100% 而外殼未列名 → **寫入時擋掉**。這修正 dc-11 的 `kva_derated()`：`_derated` 後綴不夠，還要 `derating_basis` 說明打折的**理由**。

2. **容量查詢要回 method，不只回數字。** `headroom(method="nameplate_sum" | "measured_125pct")` 回 `{amps, method, window_days, valid}`。資料不足 30 天時 **`valid=False`**——「我還不知道」必須可表達，不能靜默退回銘牌法。**跟 [dc-10b](sts-two-source-relationship.md) 的 `binding` 同形：算法選擇本身就是要存的結論。**

3. **約束有三種基數，schema 要分開放。** 單體（`amps ≤ 125`）、**成對相鄰**（`adjacent_sum ≤ 150`）、**分段**（`segment_sum ≤ Ina_segment`）。dc-11 只有第一種。成對約束需要 `Panelboard.adjacency(position)`——**相鄰是幾何關係**，NEMA 盤是左右、SMISSLINE 是沿母線，不一樣。

4. **「算得出來的一律不存」有例外，所以模式要是欄位。** SMISSLINE 多極裝置可任意插放、可帶電調相位平衡，**相位是插法不是位置**。所以 `Panelboard.phase_mode: Literal["by_position","explicit"]`，`explicit` 下 `Breaker.phase` 才合法。同理 `requires_outage_to_add_circuit: bool`（bolt-on 要、plug-in 不要）是設備欄位，直接決定變更單走不走維護窗口。**規則沒錯，錯在把它當無條件的。**

## 該問 facility 的問題

1. **「主開關是 80% 還是 100% rated？外殼有沒有跟著列名 100%？」** 兩題都要答，只答第一題等於沒答。這一問直接值 25% 的容量。
2. **「架構是 PDU→RPP→機櫃（3 跳）還是 RPP 就是 PDU（2 跳）？盤是 bolt-on 還是可帶電插拔？」** 前者決定冗餘計算，後者決定「加一條迴路」算不算變更窗口事件。
3. **「BCMS 分路資料保存多久？拿得到連續 30 天的最大需量嗎？」** Eaton 存 24 個月。若答案是「只有即時值」，實測法在你這裡**不可用**，容量規劃只能退回銘牌法且要在 schema 標明。

## 動手練習（30–40 分鐘）

接在 [dc-11](pdu-floor.md) 的 `Panelboard` / `Breaker` 下游。今天**回頭修 dc-11 的兩個錯**（寫死的 0.80、只有單體約束），再把 RPP 接上去。

```python
from dataclasses import dataclass, field
from typing import Literal

RatingStyle = Literal["80_percent", "100_percent"]

@dataclass
class Breaker:                       # ← dc-11 的，加這兩行
    id: str; position: int; poles: int; amps_nameplate: float
    rating_style: RatingStyle = "80_percent"   # ★ 不再是常數
    phase: str | None = None                   # ★ 只在 explicit 模式合法

@dataclass
class BusSegment:                    # ★ 新：ABB 的 2×250A
    id: str; ina_amps: float; positions: range

@dataclass
class Panelboard:
    id: str
    pole_count: int                              # ★ 不要寫死 42
    enclosure_listed_100pct: bool = False        # ★ 100% 是組合屬性
    phase_mode: Literal["by_position", "explicit"] = "by_position"
    numbering: Literal["nema", "sequential"] = "nema"
    max_breaker_amps: float = 125.0
    max_adjacent_pair_amps: float = 150.0
    segments: list[BusSegment] = field(default_factory=list)
    breakers: list[Breaker] = field(default_factory=list)

@dataclass
class DemandRecord:                  # ★ 新：實測才有的東西
    peak_amps: float; window_days: int

@dataclass
class Rpp:
    id: str; main_amps: float; main_rating_style: RatingStyle
    voltage_ll: float                            # 380
    panels: list[Panelboard] = field(default_factory=list)
    demand: DemandRecord | None = None
    neutral_rating_pct: float = 200.0

# TODO continuous_factor(style, enclosure_listed_100pct) -> float
#   宣告 100% 但外殼未列名 -> raise（不要靜默退回 0.8）
# TODO Rpp.main_continuous_amps()
# TODO Panelboard.phase_of(breaker)
#   by_position -> 用 dc-11 算法；explicit -> 回 breaker.phase，None 則 raise
# TODO Panelboard.adjacency(position) -> list[int]     ★ 幾何，非通用
# TODO Panelboard.validate() -> list[str]   三種基數各一條，外加 dc-11 的重疊／越界：
#   單體 amps > max_breaker_amps ／ 成對 相鄰兩顆總和 > max_adjacent_pair_amps
#   分段 同一 BusSegment 內 load 總和 > segment.ina_amps
# TODO Rpp.headroom(method) -> {"amps","method","valid","window_days"}
#   "nameplate_sum"   -> main_continuous_amps() - Σ amps_nameplate
#   "measured_125pct" -> main_amps - 1.25 * demand.peak_amps
#      demand is None 或 window_days < 30 -> valid=False, amps=None
# TODO Rpp.neutral_bus_amps()
```

### 驗收表

380Y/220V、400 A 主、單面 84 極盤、28 條 30 A/3P、30 天峰值 180 A：

| 情境 | 期望 |
|---|---|
| `continuous_factor` @(80%, False) ／ (100%, True) ／ (100%, **False**) | **0.80** ／ **1.00** ／ **raise**（不是 0.8） |
| `main_continuous_amps()` @80% ／ @100% | **320.0** ／ **400.0** → **210.6** ／ **263.3 kVA**（差 8.7 櫃） |
| `headroom("nameplate_sum")` @100% | **≈ −440 A**（840 − 400）→ 負值**不是錯誤** |
| `headroom("measured_125pct")` | **175.0 A**，`valid=True` |
| 同上但 `window_days=7` | `valid=False`, `amps=None`（**不准退回銘牌法**） |
| 兩顆 100 A 相鄰 ／ 不相鄰 | **成對違規**（各自合法） ／ **通過** |
| A 段 300 A、B 段 100 A（各 250 A Ina） | **分段違規**（總和 400 ≤ 400 卻仍違規） |
| `phase_of()` @`explicit` 且 `phase=None` | **raise**（不要猜） |
| `neutral_bus_amps()` | **800.0** |

**加分題（10 分鐘）**：寫 `capacity_verdict()` 回「該用哪個 method + 為什麼」。實測法 `valid` 就用它，否則用銘牌法**並標記 `confidence="low"`**——這個 flag 之後會一路傳到容量儀表板。

## 自我檢核

**Q1. 一台 400 A 主開關的 RPP，下面掛了 28 條 30 A 三極分路。有人說「840 A 掛在 400 A 上，這盤配錯了」。他錯在哪？**

??? note "答案"
    **沒配錯，那是 IEM 的出廠標配。** 分路銘牌總和大於主開關是常態，因為負載不會同時滿載（diversity）。斷路器保護的是**導線**，不是「總和不得超過」。

    真正判斷還能不能加，美規走 NEC 220.87：`1.25 × 連續 30 天最大需量`。峰值 180 A → 既有 225 A → 還有 175 A ≈ 115 kVA ≈ 19 個 6 kW 機櫃。**同一台盤兩種算法差 19 櫃，兩種都對。**

    注意這是**美規**；台灣走屋內線路裝置規則，數字要另查——不要把 1.25 當普世常數（跟 dc-11 把 208 V 當普世是同一個病）。

**Q2. dc-11 立了規則「凡是算得出來的東西一律不存」，並拿 `phase` 當例子。這條規則在 RPP 上還成立嗎？**

??? note "答案"
    **有例外，而例外必須在 schema 裡表達出來。** dc-11 的前提是「相位由盤面位置決定」——對 NEMA bolt-on 盤成立。但 ABB SMISSLINE 這類插拔式母線，多極裝置**可插在任何位置**，還能帶電移動做相位平衡。**相位是插法，位置算不出來。**

    正解不是推翻規則，是**把規則的前提變成欄位**：`Panelboard.phase_mode`。`by_position` 下 `phase` 是禁止欄位（存了會說謊）；`explicit` 下是必填欄位（不存就沒人知道）。**同一個欄位在兩種盤上，一個是 bug 一個是必要——所以模式必須先被記錄。**

**Q3.（建模）「這台 RPP 還剩多少容量」這個查詢，會讓你的資料模型長出哪些欄位與約束？**

??? note "答案"
    **欄位**：`Breaker.rating_style`、`Panelboard.enclosure_listed_100pct`（100% 是組合屬性，兩邊都要存）、`BusSegment.ina_amps` + `positions`、`Panelboard.max_breaker_amps` / `max_adjacent_pair_amps`、`DemandRecord{peak_amps, window_days}`。

    **回傳型別**：不是 `float`，是 `{amps, method, valid, window_days}`。**method 必須跟著值走**——同一台設備，銘牌法回負數、實測法回 +175 A。丟掉 method 的那一刻兩個數字就無法分辨（跟 dc-11 的 `voltage` 沒有參考系是**完全同一個錯**，這是第二次）。

    **約束**：宣告 100% 而外殼未列名 → 寫入時擋掉；`window_days < 30` → 實測法 `valid=False`，**不准靜默退回銘牌法**。

    **告警規則**：中性線門檻獨立於相電流門檻（中性排 200% 額定）；接地電流 > 0 是絕緣劣化，跟過載不同類，要分開的 rule。
