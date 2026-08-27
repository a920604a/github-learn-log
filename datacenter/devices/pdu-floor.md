---
id: dc-11
title: PDU 配電單元（變壓器型 vs 非變壓器型）
category: power
written_at: 2026-08-27
sources:
  - https://www.lorisweb.com/CMGT235/DIS21/VAVR-8W4MEX_R1_EN.pdf
  - https://netboxlabs.com/docs/netbox/models/dcim/powerfeed
  - https://github.com/netbox-community/netbox/issues/8738
  - https://becoming-an-electrician.com/how-circuit-numbers-work-in-a-three-phase-electrical-panel/
  - https://3dfs.com/wp-content/uploads/2015/11/WP55_DataCenterPowerSystemHarmonics.pdf
  - https://www.strongpilab.com/electric-power-distribution/
related: [dc-02, dc-07, dc-08, dc-10b, dc-12, dc-14]
---

# PDU 配電單元（power distribution unit，落地型）

電力鏈走到這裡第一次**分岔成很多條**。上游全是「一條粗的」——一台變壓器、一台 UPS、一條母線；PDU 之後變成幾十條細分路，每條進一個機櫃。它做兩件事：**（可選）降壓到 IT 設備吃的等級**，以及**把一大塊容量切成很多小塊並各自加保護**。第二件事才是重點——切完之後，容量突然變成**兩個維度**。

> 本卡講**落地型 PDU**（地板上的櫃子）。機櫃裡那條插座排是 rack PDU，額定與遙測完全不同，是 `dc-14`。

## 六格

### 拓撲位置

上游：[UPS](ups-double-conversion.md) 輸出配電盤、[STS](sts-two-source-relationship.md)，或直接吃 [LV 盤](lv-switchgear.md)。下游：RPP（`dc-12`）、busway（`dc-13`）、rPDU（`dc-14`）。

**兩種型態**（Schneider WP61）：**變壓器型** = 主入開關 + 降壓變壓器 + 分路盤；**非變壓器型** = 主入開關 + 分路盤（美規叫 RPP，約一塊 2'×2' 高架地板大）。差別不只是體積——變壓器型會**產生一個新的接地中性點**（separately derived system），故障電流的參考點在這裡重新開始。

### 容量單位

**兩個維度，會分別耗盡**：**kVA / A**（變壓器銘牌 + 輸出主開關）與 **pole 數**（分路盤實體位置，單盤標準 42 pole，落地型常見 72 pole 雙盤）。

**來源分歧（單位）**：WP61 標 PDU 為 **50 kW–500 kW**，廠商型錄多半標 kVA（150 / 225 / 300）。兩者差一個 PF，比型錄前先問清楚是哪一個。

### 冗餘表達

PDU 幾乎不做 N+1，做的是 **2N：兩台各餵機櫃的 A、B 邊**。所以這一層的冗餘不住在設備身上，住在[兩源關係](sts-two-source-relationship.md)裡。部分 PDU 內建 STS 給單電源設備用。

### 遙測介面

Modbus TCP / SNMP。關鍵點位：

| 點位 | 為什麼要 |
|---|---|
| 輸入 kW / kVA / PF | kVA 才是對變壓器的約束，kW 不是 |
| 每相電流 L1/L2/L3 | 不平衡只能從這裡算，總量看不出來 |
| **中性線電流** | 三次諧波的唯一證據，且常常沒接點位 |
| 變壓器繞組溫度 | 變壓器型才有（[dc-02](transformer.md) 的溫升邏輯） |
| 每分路電流（BCM） | **沒有 BCM 就沒有分路層資料，機櫃用電只能用推的** |

### 故障域

整台掉 → 下游機櫃**那一邊**沒電。雙電源機櫃活著（另一邊功耗上升），單電源機櫃死。變壓器本體故障**不可熱修**，換機是週級。

### 維護特性

紅外線熱像（帶電、年度）、端子扭力複緊（需停電）。**有無 maintenance bypass 決定停電範圍**——沒有的話換一顆分路開關就要整台停。

## 關鍵數字與計算

### 1. 三相容量：公式沒錯，錯的是參考系

$$S = \sqrt{3} \times V_{LL} \times I_L = 3 \times V_{LN} \times I_{phase}$$

208Y/120V、30 A 分路：`√3 × 208 × 30 = 10 807 VA` ／ `3 × 120 × 30 = 10 800 VA`——**兩式相等**（`V_LL = √3 × V_LN`）。

**來源分歧（真實案例）**：NetBox issue #8738 報 bug 說 `available_power` 用 `× 1.732` 是錯的、該用 `× 3`。他沒錯也沒對——**真正的缺陷是 NetBox 的 `voltage` 欄位沒有參考系**：填 208 還是 120，欄位名一模一樣。issue 被關掉了，欄位到今天仍然沒有參考系。

**台灣**（`dc-11` 的實際場景）：台電新建案以 **380Y/220V 三相四線**供電，MV 側 11.4 kV / 22.8 kV。同樣 30 A 分路：`√3 × 380 × 30 = 19.7 kVA`——**是美規 208V 的 1.83 倍**。而且 IT 設備吃 100–240V，220V 線對中性可以**直接用**，所以台灣機房的 PDU 常常**根本不含變壓器**。北美文獻裡「PDU = 480→208 降壓」那條等式，在這裡不成立。

### 2. 疊乘打折：225 kVA 的 PDU 給不出 225 kVA

380Y/220V、變壓器 225 kVA、輸出主開關 400 A：

| 步驟 | 計算 | 結果 |
|---|---|---|
| 變壓器銘牌 | — | 225 kVA |
| 銘牌對應電流 | `225 000 / (√3 × 380)` | **341.8 A** |
| 主開關連續額定（80%） | `400 × 0.80` | **320 A** |
| 主開關換算 kVA | `√3 × 380 × 320` | **210.6 kVA** |
| 取兩者小者 | `min(225, 210.6)` | **210.6 kVA** |
| ×PF 0.99 | | **≈ 208 kW** |

**綁住你的不是那顆 225 kVA 變壓器，是 400 A 主開關的 80% 規則。** 銘牌比可用值大 8%——剛好一整個機櫃。

### 3. Pole 會計：另一個維度先耗盡

同一台 PDU，72 pole 分路盤，每個機櫃取 1 條 3-pole 32 A 迴路（A 邊）：

- pole 上限：`72 / 3 = 24 條迴路` → **24 個機櫃**
- kVA 上限：`208 kW / 6 kW 每櫃` → **34.7 個機櫃**

**pole 先用完，34.7 − 24 = 10.7 個機櫃份的容量（約 64 kW，31%）永遠賣不掉。** 這是擱置容量的一種型態（`topic-04`），而且**只看 kW 的儀表板看不見它**——它會顯示「利用率 69%，還有空間」。

### 4. 中性線：平衡也救不了三次諧波

三相平衡、每相基波 100 A → 中性線電流理論上 0。加入 30% 三次諧波（每相 30 A）：三次諧波是 triplen，三相**同相位、算術相加**：

- 中性線 = `3 × 30 = 90 A`
- 每相 RMS = `√(100² + 30²) = 104.4 A`

**相電流 104 A、中性線 90 A。** 中性線若照「等於相導體」設計，此時已在 86% 而沒有任何告警——因為多數 PDU 的中性線電流**根本沒接點位**。這也是 K 係數變壓器（K-13 等）存在的理由；**K 值是諧波耐受能力，不是效率指標**。

### 5. 空載損失（變壓器型才有）

鐵損只要通電就存在，24×7 不隨負載變。225 kVA 級乾式變壓器空載損約 1 kW 量級 → **每年約 9 MWh 純損耗**，且它落在 PUE 的分子。最大效率點在**額定的 35–45%**——「買大一號比較安全」在能耗上是有代價的。

## 常見誤解

**以為 PDU 的容量是一個數字，但實際上是二維的（kVA × pole），而且通常是 pole 先用完。** 只追蹤 kW 利用率的系統會在 24 個機櫃時說「還有 31% 空間」，然後現場發現沒位置裝開關了。

**以為 208V/480V 是通用常識，但實際上那是北美規格。** 台灣是 380Y/220V，IT 設備直接吃 220V 線對中性，**PDU 多半不含變壓器**。照抄美規白皮書會把一台不存在的變壓器畫進單線圖。

**以為三相平衡是「總量分配平均」，但實際上相位是盤面「位置」的函數。** NEMA 編號下 1、2 號位在 A 相，3、4 在 B，5、6 在 C。你沒辦法把某條迴路「指派」到 C 相——只能把它裝在 5、11、17… 這些位置上。平衡是**排位問題**。

## 對資料模型的意涵

1. **`voltage` 沒有參考系就是壞欄位。** 必須拆成 `voltage_ll` / `voltage_ln`，或加 `voltage_reference: Literal["LL","LN"]`。NetBox issue #8738 是這缺陷的化石——**兩個人對同一欄位兩種讀法，系統無法分辨。** 規則：**任何相對於某基準的量，基準必須跟值住在一起。**

2. **容量是二維的，`utilization: float` 是壞欄位。** `capacity_report()` 要回 `{"kva_pct", "pole_pct", "binding"}`。**瓶頸是哪一維本身就是結論**，跟 [dc-10b](sts-two-source-relationship.md)「LCA 深度本身就是報表數字」同形。

3. **命名規約該立了（第二次撞上）。** NetBox 的 `available_power` 已乘過 `max_utilization`（預設 80%），名字卻像絕對額定；[dc-09](ups-battery.md) 的 `energy_kwh()` 是**一模一樣的錯**。**規約：打過折的量一律 `_derated` 後綴，未打折的一律 `_nameplate`，不准有無後綴的版本。** 這條要回頭套用到 dc-09。

4. **`Breaker.position: int` 是欄位，`phase` 不是。** `phase_of(position, numbering)` 是純函數，存 `phase` 欄位就會在有人重排盤面那天靜默說謊——**這是第三次遇到同一個形狀**（dc-10b 的 `is_redundant`、dc-07b 的 `Isc`）。而 `numbering` 必須是參數：**來源分歧**——NEMA 慣例（奇左偶右、每列同相）與部分歐規／流水號慣例不同，跨廠商時 `phase_of` 會給出不同答案。

## 該問 facility 的問題

1. **「PDU 含不含變壓器？若含，一次／二次側各多少、K 值幾？若不含，新的接地中性點在哪一台設備上？」** 第三問是關鍵——**接地參考點決定故障電流的計算起點**，在單線圖上通常只是一個小符號。

2. **「每面分路盤幾 pole、用掉幾？panel schedule 有沒有電子檔？」** 若答案是「門上一張手寫表」，你的 pole 維度**永遠不會準**，這件事要現在就知道。

3. **「中性線電流有沒有接點位？分路層有沒有 BCM？」** 都沒有的話，模型裡機櫃用電只能是設計值——要在 schema 裡誠實標成 `source: "design"`。

## 動手練習（30–40 分鐘）

接在 [dc-10b](sts-two-source-relationship.md) 的 `DeviceRegistry` 下游。PDU 是第一個**內部有結構**的節點：把「二維容量」與「相位是位置的函數」寫成 code。

```python
from dataclasses import dataclass, field
from typing import Literal

@dataclass(frozen=True)
class Voltage:                      # ★ 基準跟值住在一起（意涵 1）
    volts: float
    reference: Literal["LL", "LN"]
    def line_to_line(self) -> float: ...   # TODO LN -> ×√3

@dataclass
class Breaker:
    id: str
    position: int                   # ★ 起始 pole 位置（1-based）
    poles: int                      # 1 | 2 | 3
    amps_nameplate: float           # ★ 未打折（意涵 3）
    continuous: bool = True         # True -> 連續額定 = ×0.80
    load_kw: float = 0.0

@dataclass
class Panelboard:
    id: str
    pole_count: int                 # 42 | 72
    numbering: Literal["nema", "sequential"] = "nema"
    breakers: list[Breaker] = field(default_factory=list)

@dataclass
class Pdu:
    id: str
    has_transformer: bool
    kva_nameplate: float | None      # 非變壓器型為 None
    main_breaker_amps: float
    output_voltage: Voltage
    panels: list[Panelboard] = field(default_factory=list)
    pf: float = 0.99

# TODO phase_of(position, numbering) -> "A"|"B"|"C"
#   nema: row = ceil(position/2); phase = "ABC"[(row-1) % 3]
#   sequential: phase = "ABC"[(position-1) % 3]   ★ 同一塊盤兩種答案
# TODO occupied_poles(breaker) -> list[int]   ★ 3-pole 佔 p, p+2, p+4（同一列）
# TODO Panelboard.pole_usage() -> (used, total, pct)
# TODO Panelboard.validate() -> list[str]
#   重疊位置 / 超出 pole_count / 3-pole 起始位置不合法
# TODO Pdu.kva_derated() -> float
#   min(kva_nameplate or ∞, √3 × V_LL × main_breaker_amps × 0.80)
# TODO Pdu.capacity_report() -> dict
#   {"kva_pct","pole_pct","binding","stranded_kw"}   ★ binding 是結論不是副產品
# TODO phase_loads(panel) -> {"A":kw,"B":kw,"C":kw}   3-pole 均分三相
# TODO imbalance_pct(loads) -> float   (max - min) / mean × 100
# TODO neutral_current_est(phase_amps, thd3_pct) -> float
#   平衡分量抵銷；triplen 算術相加 = 3 × I_3rd
```

### 驗收表

一台 380Y/220V、225 kVA、主開關 400 A、單面 72-pole 盤的 PDU，裝 24 條 3-pole 32 A 迴路，每櫃 6 kW：

| 情境 | 期望 |
|---|---|
| `Voltage(220,"LN").line_to_line()` | **≈ 381.0**（不是 220） |
| `phase_of(1,"nema")` ／ `phase_of(3,"nema")` ／ `phase_of(7,"nema")` | **A** ／ **B** ／ **A** |
| `phase_of(3,"sequential")` | **C** ← 同位置、兩種慣例、兩種答案 |
| `occupied_poles(Breaker(position=1, poles=3))` | **[1, 3, 5]**（不是 [1,2,3]） |
| `pdu.kva_derated()` | **≈ 210.6**（不是 225；被主開關 80% 綁住） |
| `capacity_report()["pole_pct"]` ／ `["kva_pct"]` | **100.0** ／ **≈ 69.2** |
| `capacity_report()["binding"]` | **`"pole"`** |
| `capacity_report()["stranded_kw"]` | **≈ 64**（賣不掉的那 31%） |
| 把第 25 條迴路裝在 position 73 | `validate()` 回 **超出 pole_count** |
| 24 條 3-pole 迴路 → `imbalance_pct()` | **0.0**（3-pole 本來就跨三相）|
| 改 12 條 1-pole 全裝在 1,2,7,8,13,14… | **> 100** ← 位置決定相位 |
| `neutral_current_est([100,100,100], thd3_pct=30)` | **90.0**（相電流才 104.4） |

**加分題（10 分鐘）**：把非變壓器型 PDU（`kva_nameplate=None`）餵進 `capacity_report()`，確認 `kva_pct` 改用主開關算而不是丟 `TypeError`——**台灣機房大多長這樣，這才是主路徑。**

## 自我檢核

**Q1. 一台 PDU 的儀表板顯示「利用率 69%」，你要不要在它下面再加機櫃？**

??? note "答案"
    **不知道——69% 是哪一維的？** 上面的例子裡 kVA 是 69.2%、pole 是 100%，同一台設備兩個答案。單一 `utilization` 數字在 PDU 這一層**必然是錯的或至少是不完整的**，因為容量在這裡分岔成兩個維度。

    正確的問法是 `capacity_report()["binding"]`。**而且 `binding` 是要存進報表的結論**——「幾台 pole-bound、幾台 kVA-bound」直接決定下一批採購買 72-pole 還是更大 kVA。

**Q2. 有人拿 225 kVA 銘牌的 PDU 說「這台可以帶 225 kVA」。錯在哪？至少講出兩層。**

??? note "答案"
    **第一層**：輸出主開關 400 A 的連續額定是 `400 × 0.80 = 320 A`，換算 `√3 × 380 × 320 = 210.6 kVA` < 225。**綁住的是開關不是變壓器**，這一層在銘牌上完全看不到。

    **第二層**：kVA ≠ kW，還要乘 PF（≈ 0.99 → 208 kW）；而下游機櫃的規劃用的是 kW。

    **第三層（多數人漏的）**：即使 kVA 夠，**pole 可能先用完**——上例只能裝 24 條迴路，等於 144 kW，離 208 kW 還差 64 kW。

    **第四層**：變壓器型還有 24×7 的空載損失——**買大一號不是免費的保險。**

**Q3.（建模）「這條分路在哪一相」這件事，在你的 schema 裡是欄位還是函數？決定之後，`Breaker` 與 `Panelboard` 各要長出什麼？**

??? note "答案"
    **是函數，不是欄位。** `phase = phase_of(breaker.position, panel.numbering)`。存成欄位的話，有人把開關從 position 3 移到 position 5，**相位變了但欄位不會變，也沒有任何遙測會抗議**——這是第三次遇到同一個形狀（[dc-10b](sts-two-source-relationship.md) 的 `is_redundant`、[dc-07b](lv-short-circuit-and-coordination.md) 的 `Isc`）。三次之後應該當成規則：**凡是「從別的欄位算得出來」的東西，一律不存。**

    **`Breaker` 要長出**：`position: int`（1-based 起始位置）、`poles: int`、`amps_nameplate`（**不是 `amps`**——見下）、`continuous: bool`。**不要有 `phase`。**

    **`Panelboard` 要長出**：`pole_count`、**`numbering: Literal["nema","sequential"]`**——因為 `phase_of` 的答案依慣例而不同，慣例不是全域常數而是**每面盤的屬性**（跨廠商時真的會不一樣）。還要有 `validate()`：3-pole 開關佔 `p, p+2, p+4`，位置重疊與越界都是**可算型違規**，該在寫入時擋掉，不是掛告警（跟 [dc-07b](lv-short-circuit-and-coordination.md) 的結論一致）。

    **順帶的規約**：`amps_nameplate` / `kva_derated()` 的後綴不是潔癖。NetBox 的 `available_power` 乘過 80% 卻叫「available」，[dc-09](ups-battery.md) 的 `energy_kwh()` 同病——**打過折的數字取絕對值的名字，聚合時靜默少 20% 且不會報錯。**
