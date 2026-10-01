---
id: dc-30b
title: 線槽與走線架（cable tray / pathway：填充率、NEMA 載重、電力與資料分離）
category: space
written_at: 2026-09-29
sources:
  - https://www.toolgrit.com/guides/cable-tray-fill-guide
  - https://www.eaton.com/content/dam/eaton/products/support-systems/cable-management/redi-rail-cable-tray/RediRail-Masterformat-2004.pdf
  - https://www.goagilix.com/blog/understanding-nema-standards-for-cable-tray-systems/
  - https://www.upsite.com/blog/data-center-cable-management-and-airflow-management/
  - https://paigedatacom.com/news-article/right-sizing-your-pathwaysfrom-tray-to-conduit
  - https://heathertechnologies.com/pages/cable-pathway-design-for-compliance-with-tia-569-d-standards
related: [dc-30, dc-29, dc-28, dc-25b, dc-31, topic-10]
---

# 線槽與走線架（cable tray / pathway）

[dc-30](raised-floor.md) 算了磚與洞，這張補上**洞裡面走的東西**：線槽是電纜的**實體路由**，同時是一個**兩個上限**的容器——資料線先撞「面積」上限，電力線先撞「重量」上限。它也是 NetBox 的下一個斷點：`Cable` 只知道兩端，不知道中間走哪。

## 六格

### 拓撲位置
機櫃／RPP／配線架 →（線槽：地板下或機櫃上方）→ 對端。它不在電力單線圖上，卻決定電纜**實際**經過哪些空間。

### 容量單位
兩個獨立上限：**填充**（截面積比、或填充深度）與**承重**（kg/m，NEMA VE 1 等級＝跨距 ft＋字母）。

### 冗餘表達
沒有 N+1。**2N 的兩路電纜走同一條槽＝實體路由不獨立**，拓撲上看不出來（→ dc-28 的 fault_domain 再多一個「路由」軸）。

### 遙測介面
幾乎沒有；靠竣工圖與盤點。承重與填充是**設計時**算出來、之後只會被悄悄加線改掉的數字。

### 故障域
一條槽起火或塌陷 → 該槽所有電纜；一條槽同時承載 A、B 兩路 → 兩路同死。

### 維護特性
加線是常態（TIA 因此建議 25% 起始）；**每次加線都是一次沒有工單的承重／填充變更**。

## 關鍵數字與計算

單位換算：1 lb/ft = 1.4882 kg/m。NEMA VE 1 等級（Eaton 規格原文）：**A/B/C = 50/75/100 lb/ft = 74.4/111.6/148.8 kg/m**，支撐跨距 8/12/16/20 ft，安全係數 1.5；等級 = 跨距＋字母，例如「20C」＝跨距 20 ft 時承 100 lb/ft（goagilix）。

### 演算一：資料槽——面積先滿，重量遠遠沒到

300 × 100 mm 網格槽，Cat6A 外徑 **7.5 mm（假設）**、**0.06 kg/m 每條（假設）**。單條截面積 π/4 × 7.5² = 44.2 mm²；槽截面 30000 mm²。

| 填充率 | 可放條數 | 重量 |
|---|---|---|
| 25%（TIA 設計值） | 7500 / 44.2 = **169** | 10.1 kg/m |
| 40%（TIA 上限） | 12000 / 44.2 = **271** | 16.3 kg/m |
| 50%（NEC 常見說法） | 15000 / 44.2 = **339** | **20.3 kg/m** |

50% 也只有 A 級（74.4）的 27%。**25% 起始留了 271/169 = 1.6 倍的加線空間**——這是 TIA 這條規則存在的理由：資料槽的瓶頸是**將來加線**，不是現在。

### 演算二：電力槽——重量先滿（並更正 backlog 的一個結論）

600 × 100 mm 梯架，4C 185 mm² 電力電纜，**OD 52 mm、8.5 kg/m（假設）**。185 mm² > 4/0 AWG（107 mm²），適用 NEC 392.22 的**單層規則**：直徑和不得超過槽寬（toolgrit 原文）。

- 條數：⌊600 / 52⌋ = **11 條**；重量 11 × 8.5 = **93.5 kg/m = 62.8 lb/ft**
- A 級 74.4 → **VIOLATED**；B 級 111.6 → **OK（餘裕 19%）**

⚠ **backlog 的備註寫「超 A 級要 C 級」是錯的**：93.5 < 111.6，B 級就夠。（該備註未計槽體自重；NEMA 等級是**電纜負載**，是否含槽自重、以及跨距，原文未逐條核對。）

**兩種線走同一種槽，瓶頸不同**：資料 339 條才 20 kg/m，電力 11 條就 93 kg/m。toolgrit 說網格槽的顧慮主要是重量而非熱——對**電力槽**成立，對資料槽方向相反，兩者不矛盾。

### 演算三：兩種「填充率」根本不是同一個分母

Paige 轉述：TIA-569 設計 25%、上限 40%，分母是**槽截面積（寬 × 深）**；NEC「實際最大 50%」。Heather 轉述 TIA-569-D 卻是另一種寫法：**填充深度 ≤ 側板高度的 50%**。

代入 300 × 100 槽、339 條：填充深度 = 339 × 44.2 / 300 = **49.9 mm ≤ 50 → OK**；340 條 = **50.07 mm → VIOLATED**。「深度 50%」與「面積 50%」在平鋪時剛好相等，但**一堆成圓錐就分道揚鑣**。

NEC 對 4/0 以下多芯電力線又是第三種：不是百分比，是**查表的面積**（toolgrit：24″ 梯架欄一 **28 in²**）。若以 100 mm 深比較，600 mm 寬 × 100 mm = 93 in²，28 in² 約 **30%**——**表的深度基準未核對，僅供量級**。

### 演算四：地板下的槽，改的是截面而不是體積

機房 200 m²、地板下 0.6 m（`underfloor_m3` = 120 m³）。40 m 長 300 × 100 槽體積 = 1.2 m³ → 剩 **118.8 m³（−1%）**——對熱容幾乎沒影響。但**對氣流**：

- 槽**垂直**於送風方向、跨 10 m：擋 0.1 × 10 = 1.0 m² / (0.6 × 10 = 6 m²) = **16.7% 的截面**
- 槽**平行**於送風方向：0.1 × 0.3 / 6 = **0.5%**

（BICSI 002 經 Upsite 轉述：地下通道應**平行於機櫃列與氣流**——這就是量化理由。）同一條槽，方向不同，影響差 33 倍。

## 常見誤解

1. **以為線槽的容量是「放幾條線」，但實際上有兩個獨立上限，哪個先到看線種。** 資料線面積先滿（169–339 條）、電力線重量先滿（11 條）。存一個 `capacity_cables` 欄位是錯的。
2. **以為 NEC 一律 50%，但實際上 NEC 對 4/0 以下多芯電力電纜按 Table 392.22(A) 的面積、對 4/0 以上按單層規則。** 「50%」是資料線的簡化說法；TIA 又是 25%／40%／深度 50% 三種寫法（來源分歧）。
3. **以為線槽只是機電圖上的一條線，但實際上它是氣流障礙物。** 演算四：垂直擋 16.7%、平行 0.5%。這與 dc-30 的「洞比線更傷風」是同一件事的兩面。

## 對資料模型的意涵

1. **`Pathway` 是實體，`Cable` 經過它。** `Pathway(id, kind: mesh|ladder|solid, width_mm, depth_mm, length_m, service: data|power|mixed, layer: underfloor|overhead, material, load_class: Sourced[NemaClass]|None)`；`Cable.route: list[pathway_id]`。**NetBox 斷點第五條**：`Cable` 只有兩端 termination 與 length，沒有實體路由 → 自己補，用 custom field 掛 `pathway_ids`。
2. **兩條約束、兩種單位、三個消費者。** `fill_ratio(p)` 與 `load_kg_m(p)` 由掛在槽上的 cable 推導；`FILL_EXCEEDED`（資料）、`TRAY_OVERLOAD`（電力）分開告警。**`Cable.od_mm`、`Cable.kg_per_m` 變成必填欄位**——`total_weight_kg` 家族的第四個成員（電纜總重進槽、槽進樓板）。
3. **`NemaClass` 帶跨距。** `NemaClass(letter, span_ft, rated_kg_m)`；若實際支撐跨距 > 額定跨距 → `UNDETERMINED`，不是 OK。額定未知或只有摘要 → 也是 `UNDETERMINED`。
4. **分隔是一條規則，不是一個常數。** `SeparationRule(source: NEC725|TIA569|BICSI, power_band, shielded, conduit, min_mm)`，`check_separation()` 同時吐多條規則的結果，**衝突時全列**，不自己挑（來源分歧五）。
5. **2N 的兩路不可同槽。** `route_independence(a, b)` 檢查 A 路 B 路有無共用 `Pathway`，與 dc-28 的 fire 軸並列成 `fault_domain` 的第二個非拓撲軸。**這是拓撲圖上最看不到的共因故障。**
6. **地板下的槽回饋 `underfloor_m3` 與 `blockage_fraction`。** 前者改熱容（−1% 量級），後者改氣流（16.7% vs 0.5%）——`Pathway.orientation_deg` 因此是必要欄位。

## 來源分歧

**一、填充率的定義不只數字，連分母都不同。** Paige（轉述 TIA-569）：設計 25%、上限 40%，分母是槽截面積；NEC「實際最大 50%」。Heather（轉述 TIA-569-D）：填充**深度 ≤ 側板高度 50%**。toolgrit：NEC 對 4/0 以下多芯電力電纜按**表格面積**（24″ 梯架 28 in²），4/0 以上按**單層**——「NEC 一律 50%」是簡化。BICSI 002（Upsite 轉述）：地板下槽 ≤ 50%。**TIA-569、NEC 392、BICSI 002 原文皆未取得。**

**二、電力與資料的分隔。** toolgrit：NEC 725.136 最少 **2 in（50.8 mm）或固定隔板**。Heather（轉述 TIA-569-D）：依電力量級 <2 kVA 305 mm、2–5 kVA 610 mm、>5 kVA 1219 mm（非遮蔽線；遮蔽線 76／152／305 mm），兩者都在接地金屬導管內則不限。**差 12–24 倍，且不確定適用範圍相同**（NEC 是安全規則，TIA 是雜訊抑制）；業界常見 12 in，來源未核。

**三、電力走哪條通道。** Upsite（BICSI 002）：地板下資料線走熱通道、電力走冷通道，以減少擾流；淨距 BICSI 2 in vs TIA-942 ¾ in 到樓板（皆為 Upsite 轉述）。

## 該問 facility 的問題

1. **A 路與 B 路電纜在哪一段共用同一條線槽？** 竣工圖上有沒有 `Pathway` 這一層？
2. **線槽等級與支撐跨距？** 電力槽是否計入槽自重？
3. **加線有沒有工單，誰核算填充與重量？**

## 動手練習（30–40 分鐘）

新建 `pathway.py`，接 dc-30 的 `floor.py`（`Sourced`、`Check` 沿用，不重定義；下面為了可獨立執行放一份精簡 `Check`）。**先實作兩個上限與分隔，再用 `underfloor_free_m3` 把 dc-28 的 `Room.underfloor_m3` 改為推導值**。

```python
import math
from dataclasses import dataclass
from enum import Enum
LB_FT_TO_KG_M = 1.48816
class Check(Enum):            # 與 dc-30 同一個
    OK="ok"; VIOLATED="violated"; NOT_APPLICABLE="not_applicable"
    INVALID="invalid"; UNDETERMINED="undetermined"

NEMA = {"A": 50, "B": 75, "C": 100}          # lb/ft（Eaton 規格原文）
def nema_kg_m(letter: str) -> float: ...
def cable_area_mm2(od_mm: float) -> float: ...
def max_count_by_fill(w_mm, d_mm, od_mm, ratio) -> int: ...      # 面積分母 w×d
def single_layer_count(w_mm, od_mm) -> int: ...                  # NEC 392.22, ≥4/0
def fill_depth_mm(n, od_mm, w_mm) -> float: ...
def check_depth(n, od_mm, w_mm, d_mm, limit=0.5) -> Check: ...
def check_load(load_kg_m, letter: str | None) -> Check: ...      # None → UNDETERMINED
def required_class(load_kg_m) -> str | None: ...
def underfloor_free_m3(area_m2, h_m, trays: list[tuple[float, float, float]]) -> float: ...
def blockage(plenum_mm, depth_mm, span_m, width_mm, perpendicular: bool) -> float: ...
SEP = {"lt2": (305, 76), "2to5": (610, 152), "gt5": (1219, 305)}   # mm（非遮蔽, 遮蔽）
def check_sep(band, shielded, dist_mm, conduit=False) -> Check: ...
```

### 驗收表

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | `max_count_by_fill(300,100,7.5, 0.25/0.4/0.5)` | **169 / 271 / 339** |
| 2 | `nema_kg_m("A"/"B"/"C")` | **74.4 / 111.6 / 148.8** |
| 3 | `n=single_layer_count(600,52)`；`L=n*8.5` | n = **11**、L = **93.5** |
| 4 | `check_load(93.5,"A")` / `("B")` / `required_class(93.5)` | **VIOLATED** / **OK** / **"B"** |
| 5 | `check_load(93.5, None)` | **UNDETERMINED** |
| 6 | `check_depth(339,7.5,300,100)` / `(340,…)` | **OK**（49.92 mm）/ **VIOLATED**（50.07 mm） |
| 7 | `underfloor_free_m3(200,0.6,[(0.3,0.1,40)])` | **118.8** |
| 8 | `blockage(600,100,10,300, True/False)` | **0.1667 / 0.005** |
| 9 | `check_sep("2to5", False/True, 300)`；`conduit=True` | **VIOLATED / OK**；**NOT_APPLICABLE** |

第 4 列同一個 93.5 一紅一綠；第 9 列同一個 300 mm 一紅一綠——**沒有選定「哪個標準」就沒有答案**，這是來源分歧的程式碼版。

**加分題**：(a) 讓 `Cable` 帶 `route: list[str]`，寫 `route_independence(a, b)`，兩條 2N 電纜共用一條槽時吐 `SHARED_PATHWAY`；(b) `blockage` 餵 dc-25b 的 `AirBalance`，比較 dc-30 的旁通與槽阻塞誰大。

## 自我檢核

**Q1. 為什麼 300 × 100 的資料槽放 339 條線重量還遠低於 NEMA A 級，而電力槽只放 11 條就可能超？**

??? note "答案"
    資料線每條約 0.06 kg/m（假設），339 條 20.3 kg/m；4C 185 mm² 電纜 8.5 kg/m，11 條 93.5 kg/m。資料槽瓶頸是面積，電力槽瓶頸是重量。

**Q2. TIA 的「40%」與 NEC 的「50%」為什麼不能直接比？**

??? note "答案"
    分母不同：TIA 是槽截面積（寬 × 深），另有「填充深度 ≤ 側板 50%」的寫法；NEC 對 4/0 以下多芯電力電纜是查表面積，4/0 以上是單層規則。要先確定標準、分母、線種。

**Q3. 這張卡會讓你的資料模型長出什麼欄位？**

??? note "答案"
    (1) `Pathway(kind, width_mm, depth_mm, service, layer, orientation_deg, load_class: Sourced[NemaClass])` 與 `Cable.route`、`Cable.od_mm`、`Cable.kg_per_m`；(2) `FILL_EXCEEDED` 與 `TRAY_OVERLOAD` 兩種分開的告警，跨距未知 → `UNDETERMINED`；(3) `SeparationRule(source, band, shielded, conduit, min_mm)`，衝突全列；(4) `route_independence()` 讓 2N 的兩路不共槽。

## 相關卡片

[高架地板](raised-floor.md)｜[機櫃與 U 位](rack-and-rack-unit.md)｜[空間層級](space-hierarchy.md)｜[氣流管理的度量](../topics/airflow-management-metrics.md)｜下一張：`dc-31` 配線架與結構化布線
