---
id: dc-30
title: 高架地板（raised floor：地板磚載重、送風、走線開口）
category: space
written_at: 2026-09-28
sources:
  - https://wecosysgroup.com/wp-content/uploads/2015/04/SADE-5TNQYN_R3_EN1.pdf
  - https://www.techtarget.com/it-infrastructure/tip/Selecting-raised-floors-panels-for-the-data-center
  - https://www.upsite.com/blog/data-center-cable-management-and-airflow-management/
  - https://jasminefloor.com/products/%E5%90%88%E9%87%91%E9%8B%BC%E9%AB%98%E6%9E%B6%E5%9C%B0%E6%9D%BF/
related: [dc-28, dc-29, dc-25, dc-25b, dc-22, dc-30b, topic-10]
---

# 高架地板（raised floor：地板磚載重、送風、走線開口）

[dc-28](space-hierarchy.md) 算**樓板**、[dc-29](rack-and-rack-unit.md) 算**機櫃**，中間夾著高架地板：**第三個承重面**＋**送風風道**＋**走線空間**，三個角色搶同一個夾層。核心：**機櫃用四個輪子壓在某幾塊 600 mm 磚上；每個走線挖的洞都在跟風口磚搶風。**（線槽拆到 `dc-30b`。）

## 六格

### 拓撲位置
樓板 → 支柱＋橫樑（stringer）→ 地板磚 → 機櫃腳輪。夾層是 CRAH 送風靜壓箱（[dc-22](crah-chilled-water.md)）兼走線空間。

### 容量單位
磚：**集中載重**（kg/lb）、滾動載重、極限載重。風口磚：開孔率＋**某靜壓下的風量**。夾層高度（WP19：5–10 kW/櫃要 **≥ 1 m 且無阻礙**）。

### 冗餘表達
沒有 N+1；共用基礎設施，只能局部加支柱或換高載磚。

### 遙測介面
只有**地板下靜壓**（差壓計，Pa）；風口磚風量靠 commissioning 手持風罩。其餘全是**狀態**：磚掀了沒、開口封了沒。

### 故障域
一塊磚壓垮 → 該櫃＋共用磚的鄰櫃；同時掀多塊 → 整區送風（WP19：>6 kW/櫃尤甚）；地震 → WP19 引 1995 阪神，宣稱耐震的地板挫屈、停機約 5 週（**台灣是地震區**，廠商有全面斜撐選項）。

### 維護特性
地板下需專業清潔（WP19：廢線長年堆積）；掀磚是日常動作，但**會改變結構強度與氣流**。

## 關鍵數字與計算

### 演算一：1360 kg 的機櫃，壓在單一塊磚上是 816 kg

沿用 NVL72：1360 kg、600 × 1068 mm。**假設**：四輪距邊 50 mm；前重後輕 60/40（McFarlane：重量通常偏前）。

- 前輪每顆：1360 × 0.6 / 2 = **408 kg**；後輪每顆：1360 × 0.4 / 2 = **272 kg**
- 機櫃寬 600 mm = 一塊磚寬，**兩顆前輪落在同一塊磚** → **816 kg**；兩顆後輪 → 544 kg

**錯開半格救不了**：挪 300 mm 後自己的前輪分到兩塊磚，但隔壁機櫃的前輪補進來——**整排中間每塊仍是 816 kg**（驗收表第 2 列）。McFarlane 的算例同構：前腳各 850 lb、同磚 1700 lb → 換 2000 lb 級磚或**磚下加支柱**。

| 來源 | 額定 | 換算 kg | 816 kg 過不過 |
|---|---|---|---|
| 台灣廠商 700 型（600×600×35 mm） | 中心點 700 kgf、撓度 < 3 mm | 700 | **不過** |
| 美系常見範圍（McFarlane） | 集中／設計載重 1000–3000 lb | 454–1361 | 視等級 |

⚠ 兩者**不能直接比**（來源分歧一）。600 kg 傳統機櫃前輪同磚只有 **360 kg**——舊機房碰不到這題。

### 演算二：一塊風口磚能餵幾 kW——它不是常數

McFarlane 引 Tate 原廠數字，靜壓 **0.1 in. w.c.（24.9 Pa）**；ρcp = 1.21、ΔT = 12 K（同 dc-29）：

| 磚 | 風量 @ 24.9 Pa | m³/s | 可帶走 |
|---|---|---|---|
| 25% 開孔、無風門 | 746 cfm | 0.352 | **5.11 kW** |
| 25% 開孔、**風門全開** | 515 cfm | 0.243 | **3.53 kW** |
| 56% 格柵、無風門 | 2096 cfm | 0.989 | **14.36 kW** |

1. **全開的風門也讓出風少 31%**（等效開孔 25% → 17.4%；格柵 56% → 30.5%）。
2. 孔口流 `Q ∝ √ΔP`：靜壓減半，出風剩 **70.7%**（0.352 → 0.249 m³/s）。「每塊磚幾 kW」是 **(磚型號, 風門, 當下靜壓)** 的函數。
3. Upsite：12 kW 機櫃約要 **1860 cfm**。只用一塊 25% 磚硬供，要的靜壓是 `(1860/746)² × 24.9 = 155 Pa`——不現實；高密度櫃要多塊磚、格柵，或乾脆不靠地板送風（WP19）。

### 演算三：從面積比反推 Upsite 的旁通表——四格全對上

Upsite（Seaton）給了一張表：機櫃下的走線開口沒封會造成多少旁通，原文沒寫算法。我假設「開口和風口磚同一靜壓、同一流量係數」，旁通比就是**面積比** `bypass = A_leak / (A_leak + A_supply)`。24″ 磚 = 576 in²：

| 情境 | A_leak | A_supply | 我算的 | Upsite 表 |
|---|---|---|---|---|
| 6″×9″ 開口 ¼ 被線填、25% 磚 | 54 × 0.75 = 40.5 in² | 144 | **21.9%** | 22% ✓ |
| 同上、50% 格柵 | 40.5 | 288 | **12.3%** | 12% ✓ |
| 整塊磚挖空、1/10 被線填、25% 磚 | 576 × 0.9 = 518.4 | 144 | **78.3%** | 78% ✓ |
| 同上、50% 格柵 | 518.4 | 288 | **64.3%** | 64% ✓ |

這張表背後就是面積比，可以寫成函數。⚠ 但**同表「風扇節能」欄重現不出來**：照文內 `P ∝ Q³`，22% 旁通應省 52.5%（表寫 45%）、78% 應省 98.9%（表寫 82%），四格無一致指數 → **不引用**。600 mm 磚下第一列變 22.5%，可忽略。

### 演算四：「一塊開口」吃掉幾個機櫃的冷量

一列 10 櫃、每櫃一塊 25% 磚（24.9 Pa 合計 3.52 m³/s），每櫃底下一個 ¼ 滿沒封的 6″×9″ 開口（旁通 21.9%）：

- 要讓磚仍出 3.52 m³/s，總送風須 3.52 / (1 − 0.219) = **4.51 m³/s**，多送 **0.99 m³/s**
- 0.99 m³/s × 14.52 kW/(m³/s) = **14.4 kW** 的送風能力被開口吃掉 ≈ **這一列近 3 個 5 kW 機櫃**

封上毛刷就收回來——WP19「高密度機房電源線別走地板下」的量化版：**線本身不是問題，線穿過的洞才是。**

## 常見誤解

1. **以為地板承重看 kPa（均布載重），但實際上機櫃站在四個輪子上，要看單塊磚的集中載重。** McFarlane：均布載重在機房「沒有意義」。9.80 kPa 是**樓板**、816 kg 是**磚**，兩層都要過。
2. **以為掀一塊磚只是「打開檢修口」，但實際上它改變三件事**：(a) WP19：地板的側向挫屈強度**依賴磚都在位**，額定只在全部裝好時成立；(b) 高密度機房同時掀多塊會擾亂整區送風；(c) 高地板的開口有墜落風險。掀磚是**狀態變更**，不是動作。
3. **以為風口磚的開孔率決定出風量，但實際上出風由 (磚、風門、靜壓、旁通開口) 一起決定。** 風門全開就少 31%；每個沒封的走線口都跟風口磚**搶同一個靜壓**。所以 λ（[dc-25b](../topics/airflow-management-metrics.md)）裡的旁通，有一大塊不在通道，在機櫃底下。

## 對資料模型的意涵

1. **地板給房間一張格網，機櫃載重要落到格子上。** `FloorSystem(room_id, height_mm, tile_mm=600, stringer: bolted|none, seismic_bracing, rating_requires_all_tiles: bool)`；`Tile(i, j, kind: solid|perf|grate|cutout, rating: PanelRating, reinforced: bool)`。`tile_loads()` 由**合一後的** `Rack(type.outer_w_mm/outer_d_mm, placement, total_weight_kg())` ＋ 腳輪幾何（`inset_mm`、`front_ratio: Sourced`）**推導**，吐 `TILE_OVERLOAD`。**`total_weight_kg` 現在有三個消費者**：`RACK_OVERWEIGHT`（dc-29）、`FLOOR_OVERLOAD`（dc-28）、`TILE_OVERLOAD`（今天）——這就是 W39 要求兩個 `Rack` 合一的理由。
2. **`PanelRating` 必須帶測法，否則不可比。** `PanelRating(kind: concentrated|design|center_point|rolling_10|rolling_10k|ultimate, value_kg, test_location, deflection_mm, support: test_blocks|understructure, wheel_spec?)`。`comparable_to()` 測法不同時回 **`False`**——[dc-26b](cdu-rating-and-filtration.md) `Rating.comparable_to()` 的第二次出現（「值＋出處」家族第八次）。`ultimate` **永遠不可**當檢查門檻。
3. **掀起的磚是 Finding——第二個「缺東西」的告警。** `Tile.state ∈ {installed, lifted}` ＋ `lifted_at` ＋ `work_order_id`。嚴重度隨同區掀起數、房間 kW/櫃、是否超過工單時窗上升。與 dc-29 的 `OPEN_U_IN_FRONT_PLANE` 同形：**物件不在，比某個量超標更危險**。
4. **開口是氣流物件，不是線纜的屬性。** `Opening(tile, kind: cable_cutout|perf|grate, area_m2, fill_ratio, seal: none|brush|grommet)`；`bypass_fraction(room) = Σ A_leak / Σ(A_leak + A_supply)`，回饋 dc-25b 的 `AirBalance`——**第一次有一個 BP 值從幾何算出來、而不是從溫度量出來**，兩者可互相驗證。風口磚 `flow(dp) = q_ref·√(dp/dp_ref)`，`q_ref` 是 `Sourced`（含不含風門）。夾層阻塞與 `underfloor_m3` 由 `dc-30b` 接。

## 來源分歧

**一、地板磚的「載重」不是同一個量。** McFarlane：集中載重 = 施加在**最弱一平方英吋**、撓度不超過定值；另有廠商用「設計載重」= 在**實際下部結構**上測、再乘安全係數。台灣廠商（傑斯曼 700 型）：**中心點** 700 kgf、撓度 < 3 mm。測點、支撐、判準都不同。搜尋摘要另有「至少 Class 4（≥ 8 kN 極限）」，原文未取得且以極限載重當門檻，不採用。**CISCA 原文未取得。**

**二、滾動載重的 10 次與 10,000 次常用不同輪子測**，所以會出現「10,000 次比 10 次還強」的資料表（McFarlane）→ `wheel_spec` 必填。

## 該問 facility 的問題

1. **磚的額定是哪種測法？** AI 櫃列下有沒有加支柱？整櫃推入路徑上的滾動載重多少、用什麼輪子測？
2. **地板多高、有沒有送風？** 機櫃底下的走線開口是否全加毛刷／氣密護套？
3. **掀磚有沒有工單與時窗？** 同區最多同時掀幾塊？額定是否以全部磚在位為前提？

## 動手練習（30–40 分鐘）

新建 `floor.py`。**先還 [W39](../weekly/2026-W39.md) 掛在本卡的兩筆債，再算磚**：(1) dc-28 與 dc-29 兩個 `Rack` 合一——外形進 `RackType`、座標進 `Placement`，長度一律帶 `_mm`／`_m` 後綴；(2) `Sourced[T]` 與 `Check` 五態定案。**兩者今天都被真的用到**：磚載重要外形與總重，磚額定是廠商出處、可能未知。

```python
import math
from dataclasses import dataclass, field
from enum import Enum
from typing import Generic, Literal, TypeVar
from space import RHO_CP                 # 不再自己定義常數（W39 #5）
T = TypeVar("T"); CFM = 0.000471947

@dataclass(frozen=True)
class Sourced(Generic[T]):
    value: T; source: str
    evidence: Literal["first_hand", "relayed", "snippet"]   # 必填、無預設
    def usable(self) -> T: ...          # evidence == "snippet" → raise

class Check(Enum):
    OK = "ok"; VIOLATED = "violated"; NOT_APPLICABLE = "not_applicable"
    INVALID = "invalid"; UNDETERMINED = "undetermined"

@dataclass(frozen=True)
class RackType:
    model: str; rail_standard: Literal["EIA-310", "ORv3"]; unit_mm: float
    u_height: int; outer_w_mm: float; outer_d_mm: float; self_weight_kg: float

@dataclass(frozen=True)
class Placement:
    room_id: str; x_m: float; y_m: float; rotation_deg: int   # 中心；0 = 前緣朝 +y

@dataclass
class Rack:                              # 全軌跡唯一的 Rack
    id: str; type: RackType; placement: Placement
    device_kg: float = 0.0               # dc-29 的 mounts 加總，這裡先簡化
    def total_weight_kg(self) -> float: ...

@dataclass(frozen=True)
class PanelRating:
    kind: str; value_kg: float; test_location: str
    def comparable_to(self, other: "PanelRating") -> bool: ...

def casters(rack, front_ratio=0.6, inset_mm=50) -> list[tuple[float, float, float]]: ...
def tile_loads(racks, tile_m=0.6) -> dict[tuple[int, int], float]: ...
def check_tile(load_kg, rating: Sourced[PanelRating] | None) -> Check: ...
    # None 或 snippet → UNDETERMINED；kind == "ultimate" → INVALID；超過 → VIOLATED
def tile_kw(q_m3s, dt_k=12) -> float: ...
def tile_flow(q_ref_m3s, dp_pa, dp_ref=24.9) -> float: ...
def bypass_fraction(a_leak, a_supply) -> float: ...
def stolen_kw(q_tiles_m3s, bypass, dt_k=12) -> float: ...
```

測試資料：`NVL = RackType("MGX", "ORv3", 48, 44, 600, 1068, 150)`，`Rack("A-01", NVL, Placement("R1", 0.3, 3.0, 0), device_kg=1210)`（總重 1360）；`TW700 = Sourced(PanelRating("center_point", 700, "center"), "傑斯曼 700 型型錄", "first_hand")`。

### 驗收表

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | `tile_loads([A-01])` | `{(0,5): 816, (0,4): 544}`；`check_tile(816, TW700)` → **VIOLATED** |
| 2 | 兩櫃 `x_m=0.6` 與 `1.2`，同 y | `(1,5)` = **816**（錯開半格沒用） |
| 3 | 同 #1 但 `device_kg=450`（總重 600） | 最大 **360** → **OK** |
| 4 | `Placement("R1", 0.3, 5.268, 180)` | `{(0,7): 816, (0,9): 544}`（前緣朝 −y；1068 mm 跨三格） |
| 5 | `check_tile(816, None)` / 同 TW700 但 `evidence="snippet"` | **UNDETERMINED** / **UNDETERMINED** |
| 6 | rating `kind="ultimate"`、1361 kg | **INVALID**（極限載重不可當門檻） |
| 7 | `tile_kw(746*CFM)` / `515*CFM` / `2096*CFM` | **5.11** / **3.53** / **14.36** |
| 8 | `tile_flow(746*CFM, 12.45)` | **0.249** m³/s |
| 9 | `bypass_fraction(40.5, 144)` / `(518.4, 144)` | **0.2195** / **0.7826** |
| 10 | `stolen_kw(10*746*CFM, 0.2195)` | ≈ **14.4** kW |

第 1 與第 3 列同一塊磚一紅一綠；第 5 列兩種「不知道」都不是綠燈——**「沒有資料」和「資料不能用」處置不同，但都不能放行**。

**加分題**：(a) 讓 dc-28 的 `uniform_load_kpa()` 改吃新 `Rack`（用 `outer_w_mm`／`outer_d_mm`），一台機櫃同時吐樓板、機櫃、磚三個 `Check`；(b) 第 9 列旁通比餵 dc-25b 的 `AirBalance`，跟三溫度法的 BP 比對。

## 自我檢核

**Q1. 為什麼「把機櫃錯開半塊磚」不能解決 816 kg 的問題？**

??? note "答案"
    整排並排時，隔壁機櫃的前輪會補進同一塊磚，中間每塊仍吃兩顆前輪（408 × 2 = 816 kg）。解法是換高載磚或磚下加支柱。

**Q2. 一塊 25% 開孔磚標 746 cfm，為什麼不能在模型裡存成「這塊磚 5.11 kW」？**

??? note "答案"
    那是 24.9 Pa、無風門的值。風門全開剩 515 cfm；靜壓減半剩 70.7%；沒封的開口按面積比搶風。出風是 `(磚型號, 風門, 靜壓, 旁通開口)` 的函數。

**Q3. 這張卡會讓你的資料模型長出什麼欄位？**

??? note "答案"
    (1) `Tile(i, j, kind, rating: Sourced[PanelRating], state)`，`tile_loads()` 由合一後的 `Rack`（外形、`Placement`、`total_weight_kg`）推導；額定未知或只有摘要 → `UNDETERMINED`；(2) `PanelRating(kind, test_location, wheel_spec)` 與 `comparable_to()`，`ultimate` → `INVALID`；(3) `Tile.state = lifted` → 第二個「缺東西」告警；(4) `Opening(area, fill, seal)` 與 `bypass_fraction()`，第一個從幾何算出的 BP。

## 相關卡片

[空間層級](space-hierarchy.md)｜[機櫃與 U 位](rack-and-rack-unit.md)｜[冷熱通道封閉](aisle-containment.md)｜[氣流管理的度量](../topics/airflow-management-metrics.md)｜[CRAH](crah-chilled-water.md)｜下一張：`dc-30b` 線槽走線架
