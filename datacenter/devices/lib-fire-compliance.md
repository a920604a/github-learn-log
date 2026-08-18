---
id: dc-09c
title: 鋰電消防合規（NFPA 855 能量閘門、UL 9540A、off-gas 偵測與台灣指引）
category: power
written_at: 2026-08-18
sources:
  - https://www.telgian.com/nfpa-855-changes-in-2026/
  - https://www.mayfield.energy/technical-articles/code-corner-nfpa-855-ess-unit-spacing-limitations/
  - https://www.ul.com/services/ul-9540a-test-method
  - https://law.nfa.gov.tw/MOBILE/law.aspx?lsid=FL099497
  - https://internationalfireandsafetyjournal.com/bess-fire-safety-standards/
  - https://hillerfire.com/insights/satisfying-explosion-prevention-for-nfpa-855/
  - https://www.nafpe-roc.org.tw/NewsPage/b541b9db-aa31-407a-8bab-f4d826762f08
related: [dc-09, dc-09b, dc-08]
---

# 鋰電消防合規（lithium-ion fire code compliance）

[UPS 電池組](ups-battery.md)回答「怎麼算它」，[電池測試制度](battery-testing-regime.md)回答「你憑什麼說它還行」。這張回答第三個問題：**你憑什麼把它放在這裡。** 前兩張的欄位都掛在電力樹上——誰餵誰、誰在誰下游。消防合規不看電力樹，它問的是「這個**空間**裡堆了多少可燃能量」。同一批電池被兩套規則管，**兩棵樹共用節點、邊完全不同**。這是資料模型第一次被迫長出第二個父層級。

## 六格

### 拓撲位置

不在電力鏈上，而在**空間鏈**上：`Site → Building → Floor → FireCompartment（防火區劃）→ ESS unit → module → cell`。

電力樹上並排的 A、B 兩路 UPS，在消防樹上可能同屬一個電池室、也可能被 2 小時防火牆分成兩個節點。**這在單線圖上看不出來**，只在建築平面圖上看得到。

### 容量單位

**kWh 銘牌最大儲能（nameplate / maximum stored energy），不是可用容量、不是 kVA。** 消防合規唯一的計量單位，且**逐防火區劃聚合**。

| 化學 | 觸發門檻（每一區劃空間） |
|---|---|
| 鋰系 | **20 kWh** |
| 鉛酸（含 VRLA）／鎳系 | **70 kWh** |

台灣「提升儲能系統消防安全管理指引」與 NFPA 855／IFC 的鋰電門檻**數字一致（20 kWh）**——少數美規台規對得上的地方。

### 冗餘表達

**消防合規裡沒有 N+1。** 電力樹上「2N 比 N 安全」，消防樹上 **2N 是把同一空間的可燃能量翻倍**——安全性的方向在兩棵樹上相反。唯一同時滿足兩者的做法是**把冗餘路徑放進不同防火區劃**（見 `topic-05`）。

### 遙測介面

四類偵測，**時間尺度差三到四個數量級**，不能混成同一張告警表：

| 偵測類別 | 量測對象 | 量級 | 觸發動作 | 相對時序 |
|---|---|---|---|---|
| off-gas | 電解液蒸氣／VOC | **ppm–ppb** | 停充、隔離、排風 | 熱失控**前**，可達數十分鐘 |
| 可燃氣體（LFL） | H₂、CO | **% vol** | 25% LFL 排風／警報 | 已在排氣中 |
| 偵煙／熱成像 | 煙、表面溫度 | — | 火警、滅火系統 | 已起火 |
| BMS | cell 電壓／溫度／SOC | mV／°C | 停充、跳脫 | 電氣異常時 |

### 故障域

**防火區劃就是故障域邊界，且與電力故障域正交。** 區劃內一發生熱失控，該區劃內**所有**設備同時落入排風、滅火與人員禁入範圍，不管電力上屬 A 路還 B 路。恢復尺度也不同：電力故障域用秒到分鐘算，消防故障域用**小時到天**算（餘燼復燃、氣體清除、結構檢查）。

### 維護特性

制度性維護，不是設備維護：緊急應變計畫（ERP）**每年審查、每年複訓**並通知轄區消防單位（2026 版新增 §4.3.3）；偵測器定期測試；現場備 SDS；台灣端另需消防設備師簽證與竣工查驗。

## 關鍵數字與計算

### 演算 1：dc-09 的機組會不會踩線

沿用 [UPS 電池組](ups-battery.md)的 bank：`energy_kwh() = 28.0 kWh`（**可用值**，已扣 80% DoD）。

- 銘牌值 = 28.0 / 0.8 = **35.0 kWh**（合規用這個，見誤解 3）
- 2N、每路 2 個 bank → 4 × 35.0 = **140 kWh**
- 對鋰系門檻 20 kWh：**7 倍**，毫無疑問落入管制

若換成同容量 VRLA：門檻 70 kWh，仍超標但只有 2 倍。**換化學不是換規格書，是換一整套適用法規**——dc-09 選型決策裡最容易被漏掉的成本項。

### 演算 2：NFPA 855（2023 版）的三道能量閘門怎麼切 140 kWh

2023 版 Chapter 9 規定性表格（非住宅）：

| 層級 | 上限 | 140 kWh 的結果 |
|---|---|---|
| 單一 ESS unit | 50 kWh | 35 kWh／unit，**過** |
| 一個 group（array） | 250 kWh | 4 unit 共 140 kWh，**過** |
| 一個 fire area 總量 | 600 kWh | 140 kWh，**過** |
| unit 間距 | **≥ 3 ft（0.9 m）** | 4 台之間各留 0.9 m |

**規定性路徑上是過的**，代價是那 0.9 m——四台一列多吃約 2.7 m，**是消防規則吃掉的機房面積，不是電氣需求**。反算天花板：600 ÷ 35 ≈ **17 個 bank**，超過就要開第二個防火區劃或走 HMA（危害減緩分析）。

### 演算 3：25% LFL 到底是多早（本卡最重要的換算）

氫氣 LFL ≈ **4 vol%**。

$$25\%\ \text{LFL} = 0.25 \times 4\% = 1\ \text{vol}\% = \mathbf{10{,}000\ ppm}$$

off-gas 偵測器工作在 **ppm 到 ppb**，兩者相差 **3–4 個數量級**。等 LFL 偵測器叫，房裡的氫氣已累積到 off-gas 門檻的一萬倍——**電池早就在排氣了**。

**25% LFL 不是早期預警，是防爆的最後緩衝（4:1 安全係數）。** 把它當早期預警寫進告警規則，就是把「快爆了」誤標成「注意一下」。

### 演算 4：排風量

連續機械排風 **≥ 1 CFM/ft²** 樓地板。60 m² 電池室 → 646 ft² → **≈ 1,100 m³/h**。

替代作法是平時不轉、**由 25% LFL 觸發**間歇排風——省電費，但把安全押在偵測器與風機上。2026 版 §4.10 因此要求這類關鍵安全系統要有 NFPA 110／111 緊急電源：**排風機必須掛在發電機盤上**（見 [柴油發電機](diesel-generator.md)）。

### 演算 5：台灣的間距，跟美規不是同一個數字

| 規則 | 距離 | 量誰到誰 |
|---|---|---|
| NFPA 855 §15.5 | **3 ft（0.9 m）** | ESS **unit 與 unit 之間** |
| 台灣指引（基準） | **30 m** | ESS 與周邊建物、道路、停車場、公共危險物品 |
| 台灣指引（縮短條件） | **3 m** | 具 2 小時防火牆 **+** 自動滅火設備 |
| 台灣・廠內建築物內設置 | — | **必須 2 小時防火區劃** |

**0.9 m 與 30 m 差 33 倍，因為量的根本不是同一件事。** 把 NFPA 的 3 ft 當成「離牆 3 呎就好」搬到台灣案子上，是這題最典型的誤讀。

## 來源分歧

**NFPA 855 2023 版與 2026 版對「能量閘門」的處理方式相反，兩種說法目前都在市面上流通：**

- **2023 版**：Chapter 9 有 Maximum Stored Energy 表（50／250／600 kWh），守住表格就不必做 HMA。
- **2026 版**：**該表已移除**，**HMA 成為幾乎所有 ESS 安裝的預設要求**（僅鉛酸與水系鎳基豁免），且須由具 ESS 經驗的註冊專業技師（PE）主導；另新增 UL 9540A 之外**須做大型燃燒試驗（LSFT）**。

兩版會並存好幾年——**IFC 2024 引用的仍是 2023 版文字**，各地 AHJ 採用哪一版也不一樣。**這不是誰對誰錯，是同一份規範的兩個時間切面：模型必須把「這條約束來自哪一版」當資料存。**

## 常見誤解

**以為裝了 25% LFL 可燃氣體偵測器就有早期預警，但實際上那是防爆的最後緩衝。** 演算 3 算過：25% LFL = 10,000 ppm，off-gas 偵測工作在 ppm–ppb。NFPA 75（2024 版）首次為鋰電 UPS 加入 off-gas 偵測要求，正因傳統可燃氣體感測器看不到熱失控前的微量電解液蒸氣。**兩者是不同的偵測類別，不是同一件事的兩種精度。**

**以為「有 UL 9540A 報告」就等於整套系統測過，但實際上它是 test method 不是認證，分四層且可提早停止。** UL 9540A 依序測 cell → module → unit → installation，**任一層未觀察到火焰傳播就可停止**。所以一份合法報告完全可能只做到 module 層——整櫃從未被燒過。2026 版新增 LSFT 補的就是這個洞。另：UL 9540（產品安全標準／listing）與 UL 9540A（測試方法）是兩份不同文件。

**以為 kWh 就是 kWh，但合規用銘牌最大儲能，你模型裡存的多半是可用容量。** dc-09 的 `energy_kwh()` 已乘過 0.8 DoD，是**運維**的數字；消防要 35.0 不是 28.0。差 20% 剛好足以讓一個「算起來 580 kWh、以為過了 600」的設計實際上是 725 kWh。

## 對資料模型的意涵

1. **`FireCompartment` 是第二棵樹，不是設備的一個欄位。** `DeviceRegistry` 要支援兩種父關係：`upstream(device)`（電力樹，dc-09b 已建）與 `fire_compartment(device)`（空間樹）。兩棵樹**共用節點、邊不同、目的不同**——電力樹往上找源頭，消防樹往上聚合能量。把 `fire_zone` 塞成字串欄位，遇到「區劃有階層」就崩。

2. **能量必須存兩個欄位。** `nameplate_energy_kwh`（合規、樓板承重、運輸法規）與 `usable_energy_kwh`（runtime）。只存一個並在使用端各自換算，等於把誤解 3 寫進資料庫。

3. **法規門檻是版本化的策略資料，不是常數。** `CodeRule(edition, jurisdiction, scope, chemistry, limit_kwh, effective_from)`，`edition ∈ {NFPA855_2023, NFPA855_2026, TW_ESS_GUIDE}`。同一區劃要能同時對多套規則求值產出多筆判定——跟 [dc-09b](battery-testing-regime.md) 的 `ThresholdPolicy` 是**同一個形狀**。

4. **間距是 pairwise 幾何約束，不是設備欄位，且可被測試報告 override。** `SeparationRule(min_m, applies_to)` + `TestReport(kind='UL9540A', level, approved_separation_m)`。schema 要能表達「這條約束被哪份文件放寬到多少」，而不是硬編一個 0.9。

5. **偵測器要有 `detector_class`（`off_gas | lfl | smoke | thermal | bms`），告警動作與時間預算綁在 class 上。** 同一顆「氣體偵測」告警，off-gas 給你數十分鐘，LFL 給你的是疏散時間。**塞進同一張 alarm 表用同一套嚴重度分級，等於把最有價值的那三十分鐘丟掉。**

## 該問 facility 的問題

1. **AHJ 採用哪一版——855 的 2023、2026，還是只走台灣指引？** 決定我們是守 50／250／600 表格還是一定要做 HMA，預算與時程差很多。
2. **A 路與 B 路的電池在不在同一個防火區劃？時效幾小時、圖在哪？** 若同區劃，2N 在消防事故上其實是 1N。
3. **排風機與 off-gas 偵測盤掛在哪一路電源、有沒有進發電機盤？**（2026 版 §4.10）

## 動手練習（30–40 分鐘）

在 [dc-09b](battery-testing-regime.md) 的 `DeviceRegistry` 上**加第二種遍歷**，讓同一個 registry 能回答兩個問題：「這台的上游是誰」與「這空間裡堆了多少能量」。

```python
from dataclasses import dataclass, field
from enum import Enum

Edition = Enum("Edition", "NFPA855_2023 NFPA855_2026 TW_ESS_GUIDE")
Chem = Enum("Chem", "LI_ION VRLA FLOW")

@dataclass
class FireCompartment:
    id: str
    parent_id: str | None = None      # 區劃有階層：Building > Floor > Room
    fire_rating_hours: float = 0.0    # 台灣廠內設置要求 2.0

@dataclass
class EssUnit:
    id: str
    chemistry: Chem
    nameplate_energy_kwh: float       # ★ 合規用；不是 usable
    dod: float = 0.8
    compartment_id: str = ""
    def usable_energy_kwh(self) -> float:
        return self.nameplate_energy_kwh * self.dod

@dataclass
class CodeRule:
    edition: Edition
    chemistry: Chem
    scope: str                        # unit | group | compartment | applicability
    limit_kwh: float | None           # None = 該版本已移除此表（2026）
    requires_hma: bool = False

@dataclass
class TestReport:                     # UL 9540A：可放寬間距的那份文件
    unit_model: str
    highest_level: str                # cell | module | unit | installation
    approved_separation_m: float | None

# TODO aggregate_energy(registry, compartment_id, recursive=True) -> float
#      沿 parent_id 遞迴收集 EssUnit，加總 nameplate_energy_kwh
#      ★ 用 nameplate 不是 usable，否則結果會小 20%
#
# TODO evaluate_gates(registry, compartment_id, rules) -> list[Finding]
#      對每條 rule 求值，一個區劃可同時產出多版本判定
#      未達 applicability(20 kWh, LI_ION) -> NOT_IN_SCOPE 並跳過其餘
#      limit_kwh is None（2026 版）-> 不比大小，直接 REQUIRES_HMA
#
# TODO check_separation(units, reports, default_m=0.9144) -> list[Finding]
#      pairwise：同 compartment 內任兩台的 required_m
#      highest_level in {"unit","installation"} -> 用 approved_separation_m
#      只做到 "module" -> 不可放寬，退回 default_m   ← 誤解 2 的可執行版本
#
# TODO tw_setback_m(compartment) -> float
#      基準 30.0；fire_rating_hours >= 2.0 且有自動滅火 -> 3.0
```

**驗收標準**

| 情境 | 期望 |
|---|---|
| 4 台 `nameplate=35.0` 同一區劃 | `aggregate_energy` = **140.0**（不是 112.0） |
| 若誤用 `usable_energy_kwh()` | 112.0 ← 跑出這個就是踩到誤解 3 |
| 同上，`NFPA855_2023` 三道門檻 | unit／group／compartment **全過** |
| 同上，`NFPA855_2026`（`limit_kwh=None`） | **REQUIRES_HMA**，不是 PASS |
| 18 台（630 kWh），2023 版 | compartment 層 **FAIL**（>600） |
| 同上但換成 `VRLA` | 門檻 70 kWh 仍在管制內；HMA 依 2026 版**豁免** |
| 1 台 18 kWh，`LI_ION` | **NOT_IN_SCOPE**，其餘規則不求值 |
| 無 TestReport 的兩台 | **0.9144 m** |
| unit-level 報告、`approved=0.3` | **0.3 m** |
| 只有 module-level 報告、`approved=0.3` | **仍是 0.9144 m** ← 本題重點 |
| `fire_rating_hours=2.0` + 自動滅火 | `tw_setback_m` = **3.0**（否則 30.0） |

**加分題**：在 `Finding` 上加 `source_edition`，印一張「同一座機房、三套規則」的對照表。同一份資料在 2023 版是綠的、2026 版是黃的、台灣指引下又多一條區劃時效要求——**這就是門檻不能是常數的理由。**

## 自我檢核

**Q1. 你們的 UPS 電池室裝了 25% LFL 氫氣偵測器並接進 BMS 告警。有人說「這樣早期預警就有了」。哪裡不對？**

??? note "答案"
    量級差三到四個數量級。25% LFL 對氫氣是 **1 vol% = 10,000 ppm**，熱失控前的電解液蒸氣則是 **ppm 到 ppb**。等 LFL 偵測器動作，電池已經在排氣——那顆偵測器的用途是**防止累積到爆炸下限**（4:1 安全係數），不是提前告訴你哪顆 cell 快壞了。

    NFPA 855 Annex G 指出 LEL 感測器與電壓監測的侷限，NFPA 75（2024 版）首次為鋰電 UPS 加入 off-gas 偵測要求，並註明傳統可燃氣體感測器**不是合適的替代品**。真正的早期預警窗口可達數十分鐘，用來停充、隔離、啟動排風——而只有 ppm 級 off-gas 偵測看得到它。

**Q2. 廠商拿來一份 UL 9540A 報告，說「測過了，可以貼牆放」。你要追問什麼？**

??? note "答案"
    追問**測到第幾層**。UL 9540A 是 test method 不是認證，依序測 cell → module → unit → installation，**任一層沒觀察到傳播就可以停止**。所以報告可能只做到 module 層——整櫃從來沒被燒過，卻常被當成「整套系統通過」。

    只有 unit 或 installation 層的結果，才足以支撐廠商在安裝手冊上宣告小於 3 ft 的間距，也才是 AHJ 願意接受的放寬依據。NFPA 855 **2026 版新增大型燃燒試驗（LSFT）**，須由認可實驗室執行或見證、證明單一 unit 起火不會延燒到相鄰 unit——補的正是這個洞。

**Q3.「同一批電池被兩套規則管」這件事，會讓你的資料模型長出什麼？**

??? note "答案"
    **第二個父層級**：`FireCompartment`，與電力樹的上游關係並存。`DeviceRegistry` 要提供兩種遍歷——`upstream()` 往上找電源，`fire_compartment()` 往上聚合能量。兩棵樹共用節點但邊不同，所以區劃**不能**是 device 上的字串欄位。

    **第二個能量欄位**：`nameplate_energy_kwh` 與 `usable_energy_kwh` 必須分開，合規看銘牌、runtime 看可用，差一個 DoD。

    **一張版本化規則表**：`CodeRule(edition, jurisdiction, scope, chemistry, limit_kwh, requires_hma)`——2023 版有能量表、2026 版移除改成 HMA 預設、台灣指引又是另一套間距與區劃邏輯，三者並存好幾年。

    最深的一層跟 [dc-09b](battery-testing-regime.md) 是同一句話：**判定不是事實的屬性，是事實與判準的笛卡爾積**——那裡的判準是 IEEE 門檻與保固，這裡是法規版本與轄區。這次多出來的是：**連「聚合的範圍」本身都由另一棵樹決定。**
