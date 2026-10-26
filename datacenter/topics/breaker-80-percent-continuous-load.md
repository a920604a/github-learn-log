---
id: topic-02
title: 斷路器 80% 連續負載規則（125% 與 80% 是同一條規則的兩種寫法，但只在全連續時相等）
category: topic
written_at: 2026-10-26
sources:
  - https://iaeimagazine.org/magazine/2016/may2016/100-vs-80-choosing-the-right-ocpd-solution
  - https://www.ecmweb.com/basics/sizing-circuit-breaker
  - https://library.e.abb.com/public/dfd81f0d5f1f4f09b89a42b4b67d1fc4/61914333_circuit_breaker_ratings3-5.pdf
  - https://blog.se.com/datacenter/2014/06/12/clearing-confusion-80-vs-100-rated-circuit-breakers/
  - https://viox.com/80-vs-100-rated-circuit-breakers/
  - https://www.optifuse.com/doc-for-web/Catalog/UL-Circuit-Breakers.pdf
  - https://law.moea.gov.tw/LawContent.aspx?id=FL011045
  - https://www.6laws.net/6law/law3/%E7%94%A8%E6%88%B6%E7%94%A8%E9%9B%BB%E8%A8%AD%E5%82%99%E8%A3%9D%E7%BD%AE%E8%A6%8F%E5%89%87.htm
  - https://www.voltimum.co.uk/articles/overload-protection-requirements
  - https://www.eng-tips.com/viewthread.cfm?qid=482465
related: [dc-07, dc-12, dc-13, dc-14, dc-16, topic-01, topic-03, topic-04]
---

# 斷路器 80% 連續負載規則（continuous load / 80% vs 100% rated）

80% 在電力鏈出現過四次——[低壓盤](../devices/lv-switchgear.md)、[RPP](../devices/rpp-remote-power-panel.md)、[PDU](../devices/pdu-floor.md)、[rack PDU](../devices/rack-pdu.md)——每次都當係數直接乘。這張卡把它拆開：**它限制的是熱不是跳脫；只乘連續的那部分；單位是每相安培；台灣、美國、IEC 三套寫法不同。** 它就是 [topic-01](nameplate-derated-measured.md)「供給側降載」的完整定義。

## 定義

**連續負載**：最大電流預期持續 **3 小時以上**。NEC Article 100 與台灣《用戶用電設備裝置規則》第 6 條第 15 款同義。機房 IT 負載 24×7，**幾乎全是連續負載**。

同一條規則有兩種寫法：

| 寫法 | 公式 | 出處 |
|---|---|---|
| **選型式**（sizing） | `OCPD ≥ 非連續 + 1.25 × 連續` | NEC 210.20(A)、215.3、230.42；台灣第 29-12 條（導線） |
| **載量式**（loading） | `連續負載 ≤ 0.80 × 分路額定` | 舊版 NEC 384-16(c)；台灣第 29-11 條第 4 款 |

`1/1.25 = 0.80`，所以**全連續時兩式等價；混合負載時不等價**（演算二）。

**100% 額定（100% rated）**：例外，可用 `OCPD ≥ 連續 + 非連續`。條件不在斷路器本體，在**組合**：

- **列名的是組合**：標示「只有裝在指定型號外殼或最小尺寸空間內才適合 100% 連續運轉」（IAEI 引 UL 489）；外殼有最小尺寸與通風（ABB 逐框架列，例 XT1 370×216×72.5 mm）。
- **框架**：≤250 V 時 ≥250 A，或多極且 >250 V（IAEI 引 UL 489）。
- **導線**：端子溫升超過 50 °C 須用 **90 °C 線、以 75 °C 欄取容量**（EC&M、ABB）。

**為什麼是熱**：UL 489 的基準試驗是**開放空氣、40 °C**，斷路器要能無限期承載 100% 額定不跳（EC&M、ABB、VIOX 一致）。盤內有其他發熱元件——80% 是給盤內溫升留的空間。

**跳脫曲線不會替你執行這條規則**：UL 489 校正點是 **100% hold、135% 在 1 小時內跳（≤50 A）、200% 在 2 分鐘內跳（≤30 A）**（Optifuse 型錄表）。85%、110% 長時間運轉都不會跳，**違規是靜默的**。

**IEC 世界沒有 80%**：IEC 60364-4-43（英國 BS 7671 433.1.1）要求 `Ib ≤ In ≤ Iz` 且 `I2 ≤ 1.45 Iz`，IEC 60947-2／60898 斷路器前兩式成立即視為滿足第三式（Voltimum）。盤內溫升交給 [dc-07](../devices/lv-switchgear.md) 的 **RDF**（IEC 61439）——**降載還在，寫在另一本標準裡。**

## 為什麼重要

### 演算一：全連續 300 A，兩種斷路器差兩級線徑（IAEI，美規 75 °C 欄）

| | 80% 設計 | 100% 設計 |
|---|---|---|
| 需要的 OCPD | `1.25 × 300 = 375` → 標準 **400 A** | **300 A**（100% rated） |
| 導線 | 500 kcmil（380 A） | 350 kcmil（310 A） |

ABB 例：360 A 連續 → 80% 要 450 A，落到 **600 A 框架**；100% 用 400 A 框架。VIOX 稱 100% 斷路器貴 10–30% 但整組可能更省——**單一來源，未驗證**。

### 演算二：混合負載時，「總負載 ≤ 80%」算錯

EC&M 例：50 A 連續 + 125 A 非連續。

| 算法 | 計算 | 結果 |
|---|---|---|
| 正確（選型式） | `125 + 1.25 × 50 = 187.5` | **200 A** |
| 常見錯誤：總負載 ÷ 0.8 | `175 / 0.8 = 218.75` | 225 A——多一級 |
| 100% rated | `125 + 50 = 175` | 175 A |

**係數只乘連續部分。** 機房 IT 側少見混合負載，機電空間（照明、維修插座、間歇泵）有。

### 演算三：同一個 32 A 三相分路，三套規則三個容量

台灣 380Y/220 V、32 A 三相分路：

| 依據 | 可用連續電流 | 三相容量 `√3 × 380 × I` |
|---|---|---|
| 台灣第 29-11 條 第 4 款（80%） | 25.6 A | **16 849 VA** |
| IEC 60364（`Ib ≤ In`，無 80%） | 32 A | 21 062 VA |
| 差 | 6.4 A | **4 212 VA ≈ 一個 4 kW 櫃** |

topic-01 演算四的 NetBox `available_power` 16 849 就是第一列——**NetBox 的 `max_utilization` 預設 80% 是把美規假設寫進了預設值**。台灣機房多用 IEC 規格 32 A rack PDU，**設備是 IEC 的、裝置規則是 NEC 血統的**，用哪一列要問電機技師。

### 演算四：80% 是每相安培，不是總 kVA

208 V 三相 30 A rack PDU，降載 24 A／相（[dc-14](../devices/rack-pdu.md)），容量 `√3 × 208 × 24 = 8 646 VA`。三相實測 26／18／20 A：

- 總 kVA：平均 21.33 A → 7 686 VA，88.9%，**「合規」**
- 每相：**L1 = 26 A > 24 A，違規**——不平衡就這樣被平均掉

### 演算五：2N 下，單邊的有效上限是 40%

雙電源設備平時各吃一半（[dc-16](../devices/dual-corded-equipment.md)）。A 路斷電後 B 路扛全部，而且只要修復超過 3 小時，**失效後的負載就是連續負載**。所以：

```
單邊平時上限 = 0.80 × 30 A ÷ 2 = 12 A = 額定的 40%
```

A 13 A、B 12 A：平時 43%／40%；A 斷 → B 25 A > 24 A。**平時沒違規，失效後才違規**——要用兩路的和檢查，單看一邊永遠不響。`topic-03` 接手。

### 來源分歧

1. **100% 額定的框架下限**。IAEI 引 UL 489：≤250 V 時 ≥250 A，或多極 >250 V。VIOX：「典型 400 A 以上」，但自己的例子用 225／250 A。ABB：**XT1 100% 額定到 100 A**——看似牴觸，其實 XT1 是多極 480 V，走「>250 V」那支。**VIOX 是離群值。**
2. **「IEC 斷路器 100%、北美 80%」**。Schneider 部落格留言者這樣說；eng-tips 新加坡工程師指出 IEC 60947-2 的 Iu 也是**開放空氣 40 °C** 標的，進盤一樣降額。差別在**降額寫在哪本標準**（NEC 裝置規則 vs IEC 61439 RDF）。
3. **台灣 100% 例外由誰確認**。NEC 要組合「listed」；台灣第 29-12 條第 2 款經轉述為「經設計者確認以全額定負載運作者」——設計者而非認證機構。**轉述，未取得逐字原文。**
4. **條號**。上引台灣條號是民國 110-03-17 版；114-05-09 全文修正為 1014 條（6laws 沿革），**新條號未查證**。

**未查證**：台灣幹線（feeder）是否有對應 125% 條文、NEC 240.6(A) 標準額定級距（練習裡的清單取自我記憶，未在本次來源中核對）、UL 489 >50 A 的 135% 跳脫時間（型錄表只列 ≤50 A）。

## 常見誤解

**以為斷路器沒跳就代表沒超過 80%，但實際上 UL 489 要求 100% 額定時「hold」不跳、135% 才在 1 小時內跳。** 85% 跑一年也不跳，熱在端子和絕緣上累積。**沒有硬體會替你執行這條規則**，只能靠軟體拿每相時間序列去算。

**以為 80% 規則是「總負載 ≤ 額定 × 0.8」，但實際上只有連續部分乘 1.25，而且單位是每相安培。** 混合負載用總量去除會多選一級（演算二）；三相用總 kVA 會把最重那一相的違規平均掉（演算四）。

**以為換一顆 100% 額定斷路器就能用到 100%，但實際上列名的是「斷路器＋外殼＋導線」組合。** 缺一項就回到 80%。而且元件只是限制之一——[dc-07](../devices/lv-switchgear.md) 的 400 A 換成 100% 額定，綁死的仍是盤體 Ing **284 A**。

## 對資料模型的意涵

1. **80% 不是斷路器的欄位，是一個推導函式。** `continuous_limit_a(circuit) -> Figure(kind=DERATED, side=SUPPLY, basis=…)`，輸入：`rating_a`、`code_basis ∈ {NEC, TW, IEC}`（乘不乘 0.8）、`hundred_pct_listing: Listing(enclosure_model, conductor_c, ampacity_col_c) | None`。實裝外殼不等於列名的 → 退回 80% 並發 `HUNDRED_PCT_UNVERIFIED`（DATA_QUALITY）。再與 dc-07 的 `Ing`、溫度降額取 min，保留 `bound_by`。**不存 `max_continuous_a`**（[dc-02](../devices/transformer.md) 規則）。

2. **負載長出 `duty ∈ {CONTINUOUS, NONCONTINUOUS}`，必填無預設。** 選型式要把負載分兩堆；沒填的當 CONTINUOUS，但要標 `evidence="assumed"`，不是靜默預設參數（W43 🟡5）。

3. **「持續 3 小時」需要一個可判定的實作。** NEC 的「expected to continue」是設計意圖，不是量測定義。本卡採 **3 h 滾動視窗最小值 > 限值 → VIOLATION**（不誤報）。已知漏報：25 A 跑 2 h 50 min、23 A 10 分鐘循環，滾動最小值恆 ≤ 24 A，平均卻 24.89 A——寫進文件。GOOD 樣本不足 3 h → `Result(UNDETERMINED, MISSING_INPUT)`，**不得當通過**。

4. **四條告警、兩種 `FindingKind`**（W43 🔴1 的試金石）：
    - `CONTINUOUS_LOAD_OVER_LIMIT` — 任一相滾動 3 h 最小值 > 限值，**VIOLATION**
    - `FAILOVER_OVER_LIMIT` — 冗餘對 `Σ 兩路同相電流 > 任一路限值`，**VIOLATION**（預測性，平時就該響）
    - `ALLOCATION_OVER_CONTINUOUS` — topic-01 的 ALLOCATED 總和 > 連續限值，**VIOLATION**（帳本層）
    - `CONTINUOUS_LIMIT_UNDETERMINED` — 缺相、缺時窗、`code_basis` 未填，**DATA_QUALITY**

    同一電路可同時有 DATA_QUALITY（L3 沒點位）與 VIOLATION（L1 超限）——`kind` 分得開，元組做不到。

## 該問的問題

1. **分路依台灣裝置規則的 80%，還是 IEC 32 A 全額？** 電機技師簽的是哪個數字？
2. **主盤與 RPP 有沒有 100% 額定斷路器？列名外殼和現場一致嗎？**
3. **2N 單邊負載政策是 40% 還是 50%？** 修復時間假設多長？

## 動手練習（40 分鐘）

### 第 0 步（20 分鐘，W43 週報交辦 🔴1＋🔴3）

```python
# core.py —— Finding 定形，刪 space_id
class FindingKind(Enum): VIOLATION; MISSING_PROTECTION; DATA_QUALITY; FACT
@dataclass(frozen=True)
class Finding: code: str; subject_kind: str; subject_id: str; result: Result; kind: FindingKind
def from_uncovered(code, subject_kind, pairs) -> list[Finding]   # kind = MISSING_PROTECTION
```

- 7 個 `check_*`（dc-42～45、topic-01）改回 `list[Finding]`
- 改名：`bacnet.effective` → `effective_command`；`@kind` → `@observer_kind`；dc-45 `quality()` → `quality_of(read, gw) -> Quality`（hold-last 無訊號回 `SUSPECT`）
- 驗收：`grep -rn "return \[(" *.py` 為空；舊測試全綠

### 第 1 步（20 分鐘）：`breaker80.py`

```python
class Duty(Enum): CONTINUOUS; NONCONTINUOUS
class CodeBasis(Enum): NEC; TW; IEC
STANDARD_A = [15,20,25,30,35,40,45,50,60,70,80,90,100,110,125,150,175,200,
              225,250,300,350,400,450,500,600,700,800,1000,1200,1600,2000]  # NEC 240.6(A)，未查證
@dataclass(frozen=True) Listing: enclosure_model: str; conductor_c: int; ampacity_col_c: int

def required_ocpd_a(cont_a, noncont_a, hundred_pct: bool) -> float
def next_standard(a) -> int
def continuous_limit(rating_a, basis, listing, installed_enclosure) -> tuple[Figure, list[Finding]]
def sustained_min(samples: list[float], interval_s, window_s=10800) -> Result | float
def check_circuit(cid, rating_a, basis, phases: dict[str, list[float]], interval_s,
                  partner: dict[str, list[float]] | None = None) -> list[Finding]
```

`sustained_min` 回滾動視窗最小值的最大者，跨度不足回 `UNDETERMINED`；`continuous_limit` 回 topic-01 的 `Figure`。

### 驗收表

| # | 呼叫 | 期望 |
|---|---|---|
| 1 | `next_standard(required_ocpd_a(300, 0, False))` | 375 → **400** |
| 2 | `required_ocpd_a(300, 0, True)` | **300** |
| 3 | `next_standard(required_ocpd_a(50, 125, False))` | 187.5 → **200**；**不是** 225 |
| 4 | `required_ocpd_a(16, 30, False)` | **50** |
| 5 | `continuous_limit(400, NEC, None, None)` | 320 A，`kind=DERATED, side=SUPPLY` |
| 6 | 同上，`listing.enclosure_model="E1"`、裝的是 `"E2"` | 320 A ＋ `HUNDRED_PCT_UNVERIFIED`（DATA_QUALITY） |
| 7 | `continuous_limit(32, TW, …)` vs `IEC` | 25.6 vs 32.0 |
| 8 | 三相 180 樣本／60 s，L1 全 25 A，限值 24 | `CONTINUOUS_LOAD_OVER_LIMIT`，VIOLATION，subject 為 L1 |
| 9 | 基線 20 A，中間 10 分鐘 28 A | **無 Finding** |
| 10 | L1／L2／L3 = 26／18／20 A 各 3 h | 只有 **L1** 一筆 VIOLATION |
| 11 | 只有 150 個樣本（2.5 h） | `CONTINUOUS_LIMIT_UNDETERMINED`，DATA_QUALITY，`result.reason=MISSING_INPUT`；**不得**有 VIOLATION |
| 12 | 25 A×170 樣本、23 A×10 樣本循環 6 h | **無 Finding**（已知漏報，意涵 3；在測試裡寫註解釘住） |
| 13 | A 路 L1 13 A、B 路 L1 12 A，`partner=B` | `FAILOVER_OVER_LIMIT`（25 > 24），VIOLATION；兩路各自檢查皆無 Finding |
| 14 | 一次 `check_circuit`：L1 超限、L3 缺資料 | 回兩筆，`{f.kind for f in out} == {VIOLATION, DATA_QUALITY}`；`all(isinstance(f, Finding))` |

**加分題**：[busway](../devices/busway-and-tap-off-box.md) 的 `feed_continuous_a()` TODO 改呼叫 `continuous_limit()`，驗 400 A @80%／@100% = 320／400 A。

## 自我檢核

**Q1. 一個 225 A 標準斷路器上，150 A 的 IT 負載 24×7 運轉了半年，從沒跳過。合規嗎？還差什麼資訊？**

??? note "答案"
    150/225 = 66.7%，依元件**合規**；但「沒跳」不是證據（100% 都要 hold）。還要：(1) 是**每相**最大值還是平均？(2) 盤體 `Ing` 或溫度降額有沒有比 180 A 更緊（dc-07）？(3) 若是 2N 一邊，失效後 300 A 遠超 180 A。

**Q2. 50 A 連續＋125 A 非連續，為什麼不是選 225 A？**

??? note "答案"
    1.25 只乘連續部分：`125 + 1.25×50 = 187.5` → 200 A。用「總負載 175 ÷ 0.8 = 218.75」等於把非連續負載也乘了 1.25，多選一級。兩式只在全連續時等價。

**Q3. 這張卡會讓你的資料模型長出什麼欄位？哪個欄位**不該**長？**

??? note "答案"
    **長出**：負載 `duty`（必填）；電路 `code_basis ∈ {NEC, TW, IEC}`；`hundred_pct_listing: Listing(...)` 與實裝 `enclosure_model`；冗餘對 `partner_feed_id`；`Finding.kind`。**不該長**：存起來的 `max_continuous_a`——它由額定、規則、列名、Ing、溫度推導，存了就會跟任一項的變更脫鉤。
