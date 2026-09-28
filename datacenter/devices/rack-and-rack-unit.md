---
id: dc-29
title: 機櫃與 U 位（rack / rack unit / 盲板）
category: space
written_at: 2026-09-25
sources:
  - https://netboxlabs.com/docs/netbox/models/dcim/rack/
  - https://netboxlabs.com/docs/netbox/models/dcim/racktype/
  - https://www.racksolutions.com/news/data-center-optimization/eia-310-definition/
  - https://en.wikipedia.org/wiki/Open_Rack
  - https://www.4xem.com/products/4xem-44ou-ocp-open-rack-v3-21-inch-orv3-rack-3-527-lb-capacity
  - https://zenex.home.pl/pub/katalogi/schneider/6_systemy_zasilania_gwarantowanego_i_chlodzenia/6_9_dokumenty_white_paper/wp-49.pdf
  - http://m.softchoice.com/cms/brands/dell/pdf/rack_blanking_panels.pdf
  - https://www.upsite.com/blog/blanking-panels-sealing-small-gaps-can-lead-big-savings/
related: [dc-28, dc-25, dc-25b, dc-14, dc-27, dc-30, dc-31, topic-10]
---

# 機櫃與 U 位（rack / rack unit / 盲板）

[dc-28](space-hierarchy.md) 把機櫃當成空間樹的**葉子**：一個點、一個旋轉角、一個重量。今天往下拆一層：機櫃是一條**一維座標軸**（U 位），設備佔住其中一段；沒被佔又沒蓋盲板的那段，就是熱通道空氣倒灌回前面的洞。機櫃不只是鐵架，它是冷熱分隔的一部分。

## 六格

### 拓撲位置
空間：`Room → Aisle → Rack → U`。電力：上游 [機櫃 PDU](rack-pdu.md) 或 ORv3 的 48 V 匯流排。熱：前面板是**冷熱分隔面的一部分**，跟 [dc-25](aisle-containment.md) 的封閉板同一件事。

### 容量單位
**U**（EIA-310：1U = 1.75 in = 44.45 mm）或 **OU**（OCP Open Rack：48 mm）；安裝深度 mm；**承重 kg（靜態／動態兩個值）**；kW/櫃是引用電力與熱的結果，不是機櫃自己的量（NetBox v4.7 的 `cooling_capacity` 是設計宣告，不是量測）。

### 冗餘表達
機櫃本身沒有 N+1；冗餘住在它身上（A/B 兩條 PDU、叢集節點跨櫃反親和）。機櫃是**故障域的單位**，不是冗餘的單位。

### 遙測介面
機櫃本身零點位；以下都是掛在機櫃上的 `MeasurementPoint`：

| 點位 | 典型來源 | 用途 |
|---|---|---|
| 進風溫度（上／中／下） | PDU 附掛感測器 | ASHRAE 進風判定；**上層偏熱是缺盲板的特徵** |
| 前門／後門開關 | 門磁 | 稽核、與門禁（`dc-34`）對帳 |
| 機櫃功率 | 機櫃 PDU | 見 [dc-14](rack-pdu.md) |

### 故障域
一櫃 ＝ 一組 PDU ＋ 一台 ToR ＋ 一個碰撞範圍。**缺盲板的影響不止這一櫃**：Dell 指出漏出的排氣會被**相鄰機櫃**吸進去。

### 維護特性
結構件幾乎零維護；會變的是內容（MAC）。**盲板是唯一一種「維護動作會系統性地讓它消失」的元件**——下架一台就少一片，沒人為裝回去開工單。

## 關鍵數字與計算

### 演算一：同樣 2.1 m 高，U 和 OU 不能直接換

| 規格 | 單位高度 | 常見櫃高 | 可用高度 |
|---|---|---|---|
| EIA-310 19" | 44.45 mm | 42U | 42 × 44.45 = **1866.9 mm** |
| EIA-310 19" | 44.45 mm | 48U | 48 × 44.45 = 2133.6 mm |
| OCP ORv3 21" | 48 mm | 44OU | 44 × 48 = **2112 mm** |

1 OU = 48 / 44.45 = **1.0799 U**。44OU 的可用高度等於 **47.5 U**——兩種單位的格線**對不齊**，所以不存在「44OU = 幾 U」的整數答案。欄位只叫 `u_height` 的話，混用機房裡每一台的佔用高度都錯 7%。寬度也不同：EIA 前面板 19"（482.6 mm）、立柱孔距 465.1 mm、開口最小 450 mm；ORv3 設備寬約 21"（Wikipedia 同一頁寫了 537 與 533 mm 兩個數字，**未取得 OCP 原文核對**）。**外殼寬度卻一樣**（600 mm），所以從地板平面圖上看不出差別。

EIA-310 孔距是每 U 三孔、間距 **1/2″–5/8″–5/8″**，U 的邊界落在 1/2″ 那段的中點——這是「半 U」會出現的原因（NetBox 的 `u_height` 允許 0.5 遞增）。

### 演算二：一片盲板漏 1.6 mm，42 片就是 1.5U 的洞

Upsite：多數盲板片與片之間有 **1/16″（1.5875 mm）**以上的縫。一個 42U 櫃全裝滿盲板：

- 42 × 1.5875 = **66.7 mm = 2.625″ = 1.50 U**

也就是說，一個「全部蓋好」的機櫃，前面仍有等效一個半 U 的開口。另一種說法（Upsite 文下讀者留言，引 IEC 60297 面板高度公差 0.4 mm）：

- 42 × 0.4 = **16.8 mm = 0.38 U**

**兩個說法差 4 倍**，差別在盲板是不是照 IEC 60297 公差做的——這是**採購規格**，不是施工品質。見「來源分歧」一。

### 演算三：回流比例 r 與進風溫升——會自己餵自己

設冷通道供風 T_s = 22 °C、伺服器進出溫差 ΔT = 12 K、進風裡有比例 r 來自自己的排氣。天真算法：T_in = T_s + r·ΔT。但排氣溫度 = T_in + ΔT，而 T_in 本身已經被抬高了，所以要解方程式：

T_in = (1−r)·T_s + r·(T_in + ΔT) → **T_in = T_s + r·ΔT / (1−r)**

| r | 天真算法 | 正解 | 備註 |
|---|---|---|---|
| 0.05 | +0.60 K | **+0.63 K** | |
| 0.10 | +1.20 K | **+1.33 K** | |
| 0.19 | +2.28 K | **+2.81 K** | Upsite CFD 的「有縫盲板 19% 回流」 |
| 0.30 | +3.60 K | **+5.14 K** | |
| 0.40 | +4.80 K | **+8.00 K** | = Schneider WP49 的「8 °C 熱點」 |

兩件事：(1) r 越大，天真算法低估越多（r = 0.4 時低估 40%）；(2) WP49 說缺盲板「可能造成 **15 °F／8 °C** 溫升」，反推在 ΔT = 12 K 下相當於 **r ≈ 0.4**——四成進風是自己吐出來的。⚠ ΔT = 12 K 是本卡假設值；ΔT 越大，同樣的 r 溫升越高，**這也是 AI 機櫃（ΔT 常更大）對盲板更敏感的原因**。

### 演算四：機櫃承重有兩個上限，而且要扣掉自己

ORv3 櫃實例（4XEM 44OU，原文已核對）：**靜態 1600 kg、動態 1400 kg**、櫃體自重 **150 kg**、外殼 600 × 1068 mm。NetBox 的 `max_weight` 定義是「**含機櫃自身**」的總重上限。

- 靜態可掛設備：1600 − 150 = **1450 kg**
- 動態（整櫃預先上架、推進機房）可掛設備：1400 − 150 = **1250 kg**（**假設**動態上限也含自重——廠商頁面沒寫，見分歧二）

拿 [dc-28](space-hierarchy.md) 的 GB200 NVL72 整櫃 **1360 kg** 對照：靜態有 240 kg 餘裕；若它是用這種櫃**整櫃推進來**，動態只剩 **40 kg**（1400 − 1360）。⚠ NVL72 實際用的是 NVIDIA MGX 櫃不是這款，這裡只示範**同一個重量在兩個上限下一個寬鬆一個貼邊**。dc-28 算樓板、這裡算機櫃——兩者都要過，且用**同一個** `Rack.total_weight_kg`。

## 常見誤解

1. **以為 U 是通用單位，但實際上 EIA 的 U（44.45 mm）和 OCP 的 OU（48 mm）格線對不齊**，44OU = 47.5 U。欄位只寫 `u_height=2` 而不帶單位制，混用機房每一台都會算錯。
2. **以為熱空氣會往上飄走，缺一格盲板沒關係，但實際上排氣側是微正壓、進氣側被風扇吸成負壓**。WP49 原文：這個壓差效應「遠大於熱浮力」。所以缺口哪怕只有 1U 也會回流，Dell 也說 1U 的洞漏出的溫度跟大洞一樣熱。
3. **以為「盲板全裝了」就密封了，但實際上片與片之間的縫加起來可以到 1.5U**（Upsite 的說法），而且 Dell 說縫的影響比整台伺服器之間的縫更明顯，因為空氣走盲板縫的路徑很短。另外 WP49 列的其他洞：層板（shelf）擋住盲板裝不上、23″ 寬櫃立柱外側沒毛刷、櫃底走線孔沒毛刷——**都是「沒有缺盲板但一樣在回流」**。

## 對資料模型的意涵

1. **型號與實例分開，但有四個欄位必須留在實例上。** `RackType(unit_system, unit_mm, u_height, width_in, mounting_depth_mm, self_weight_kg, max_static_kg, max_dynamic_kg, cooling_capability, cooling_capacity_kw)`；`Rack(type_id, u_height?, starting_unit, desc_units, mounting_depth_mm?)`。這跟 NetBox v5.0 的方向一致：外形尺寸改由 RackType 推得，但 **U 高、起始 U、降序編號、安裝深度保留在實例上**，因為同型號的櫃子實際裝法可以不同（例如只建模 U13–U24 的共用櫃）。
2. **位置的標準形是「從底部算起的半 U 整數」，顯示編號是視圖。** `Mount(device_id, rack_id, pos_half_u: int, height_half_u: int, face: front|rear, full_depth: bool)`。`label(pos)` 由 `starting_unit` ＋ `desc_units` 推出，**不存**。好處：0.5U 不再是浮點數、降序櫃不用改資料、OU 櫃只改 `unit_mm`。約束：同一面同一半 U 只能被一台佔；`full_depth=True` 前後兩面都佔。
3. **空 U 要有狀態，而「open」是 Finding。** `USlot.state ∈ {occupied, blanked, reserved, open}`。**`open` 只在前面板上才是問題**：`Finding.OPEN_U_IN_FRONT_PLANE(rack, u_range)`，嚴重度隨 dc-28 的 `aisle_of(rack)`（在封閉冷通道裡更嚴重）與該櫃功率上升。這是**第一個由「沒有東西」觸發的告警**——前 28 張卡的告警都是某個量超標，這裡是某個物件不存在。
4. **機櫃重量變成推導值，承重上限帶語意。** `Rack.total_weight_kg = type.self_weight_kg + Σ device.weight_kg`（取代 dc-28 的固定 `weight_kg`）。`max_static_kg` / `max_dynamic_kg` 是 `Sourced[float]` 並帶 `includes_self: bool | unknown`；`Rack.move_state ∈ {static, in_transit}` 決定對哪個上限檢查，吐 `Finding.RACK_OVERWEIGHT`。同一個 `total_weight_kg` 再餵給 dc-28 的 `FLOOR_OVERLOAD`——**一個量、兩個消費者**，這正是 W38 #5 說的「被算兩次就該是函數」。
5. **NetBox 斷點第四條（記給 `topic-10`）。** NetBox 有 `max_weight`（單值、含自重）、有 `DeviceType.airflow`，但**沒有空 U 的狀態**（盲板只能做成假 Device 或 Rack Reservation）、**沒有靜態／動態兩個承重**、**U 單位制沒有顯式欄位**。→ 盲板走「0 W 的 blank DeviceType」或 custom field；動態承重自己補。

## 來源分歧

**一、盲板縫多大？** Upsite（盲板廠商，2025 部落格）：多數產品片間縫 ≥ 1/16″，42U 累積 1.5U；同文讀者留言：照 IEC 60297 做的面板公差 0.4 mm，累積只有 0.38U。**差 4 倍**。前者是廠商自家行銷（有推銷密封型產品的動機），後者是一則留言且**未取得 IEC 60297 原文核對**。→ 規格書該寫「盲板須符合 IEC 60297 公差」並現場抽量，不要引任何一個數字。

**二、回流造成多少溫升？** Schneider WP49（2003，引 WP44 實驗）：缺盲板最高 **8 °C**；Upsite CFD：有縫 vs 無縫盲板平均差 **3.9 °C**；Dell：縫隙「可能讓相鄰設備進風多幾度」。三者情境不同（整格缺 vs 片間縫），不是真矛盾，但**不能拿任一個當通用值**。**WP44 原文（含實驗條件）本次未取得。** 另：4XEM 的動態承重是否含櫃體自重，頁面未說明。

## 該問 facility 的問題

1. **機房標準機櫃是哪一款？靜態與動態承重各多少？動態值含不含櫃體自重？** 整櫃預先上架推進來的 AI 櫃要走哪一個值。
2. **盲板規格有沒有寫進採購標準（IEC 60297 公差、免工具卡扣、最大片是幾 U）？** 下架工單有沒有「裝回盲板」這一步？
3. **有沒有規劃 OCP 21″ 櫃？** 若有，資產系統的 U 位欄位怎麼區分 U 與 OU。

## 動手練習（30–40 分鐘）

接 [dc-28](space-hierarchy.md) 的 `space.py`，新建 `rack.py`。**目標：機櫃變成一條半 U 整數軸；佔用衝突、顯示編號、空 U 稽核、進風溫升、承重五件事由同一組物件算出來。**

```python
from dataclasses import dataclass, field

@dataclass(frozen=True)
class RackType:
    model: str; unit_mm: float; u_height: int
    self_weight_kg: float; max_static_kg: float; max_dynamic_kg: float

@dataclass(frozen=True)
class Mount:
    device: str; pos_half_u: int; height_half_u: int
    face: str = "front"; full_depth: bool = True; weight_kg: float = 0.0
    kind: str = "device"          # device | blank

@dataclass
class Rack:
    id: str; type: RackType; starting_unit: int = 1; desc_units: bool = False
    mounts: list[Mount] = field(default_factory=list)

    def label(self, pos_half_u: int) -> str: ...        # 該半 U 所在的 U，例 "U13"；desc 時從頂端數
    def mount(self, m: Mount) -> None: ...              # 衝突 → raise ValueError
    def open_front_ranges(self) -> list[tuple[str, str]]: ...  # 前面板沒被 device/blank 蓋住的區段
    def total_weight_kg(self) -> float: ...
    def check_weight(self, moving: bool) -> str | None: ...    # "RACK_OVERWEIGHT" 或 None

def height_mm(rack: Rack) -> float: ...
def inlet_temp(t_supply: float, dt_k: float, r: float) -> float: ...  # T_s + r·ΔT/(1−r)
```

測試資料：`EIA42 = RackType("EIA-42U", 44.45, 42, 120, 1360, 1130)`；`ORV3 = RackType("ORv3-44OU", 48, 44, 150, 1600, 1400)`。

### 驗收表

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | `height_mm(Rack("A", EIA42))` / `Rack("B", ORV3)` | **1866.9** / **2112.0** |
| 2 | `Rack("A", EIA42).label(24)`（第 25 個半 U） | **U13** |
| 3 | 同上但 `desc_units=True`，`label(0)` | **U42** |
| 4 | 先 mount `srv1` pos 0 高 4（2U），再 mount `srv2` pos 2 | **ValueError**（重疊 1U） |
| 5 | EIA42 只裝 `srv1`(pos 0, 2U) 與 `blank`(pos 80, 2U) | `open_front_ranges()` → **[("U3","U40")]** |
| 6 | `inlet_temp(22, 12, 0.19)` / `(22, 12, 0.40)` | **24.81** / **30.00** |
| 7 | ORV3 掛 1210 kg 設備（總重 1360），`check_weight(False)` / `(True)` | **None** / **None**（= NVL72 整櫃，動態餘裕 40 kg） |
| 8 | ORV3 掛 1260 kg 設備（總重 1410），同上 | **None** / **"RACK_OVERWEIGHT"** |

第 7、8 列只差 50 kg——**靜態綠、動態紅**，正是「同一台櫃子，推進來那一刻和站定之後是兩個答案」。

**加分題**：把 dc-28 `Rack.weight_kg` 換成 `rack.total_weight_kg()`，讓 `check()` 同時吐 `FLOOR_OVERLOAD` 與 `RACK_OVERWEIGHT`；再讓 `OPEN_U_IN_FRONT_PLANE` 的嚴重度在 `aisle_of(rack).kind == "cold"` 且封閉時升一級。**一個重量、一個位置、兩張卡的 Finding 同時出來，才算真的接上。**

## 自我檢核

**Q1. 為什麼 `u_height` 不能是一個裸整數？**

??? note "答案"
    因為 U 有兩種單位制：EIA 44.45 mm 與 OCP OU 48 mm，格線對不齊（44OU = 47.5U），而且 EIA 允許半 U。欄位要嘛帶 `unit_mm`（在 RackType 上），要嘛統一存成「半 U 整數＋單位制」，顯示編號（含降序、起始 U）由視圖推出。

**Q2. 一個 42U 櫃「盲板全部裝好」，為什麼上層進風還可能偏熱？**

??? note "答案"
    (1) 片間縫累積：每片 1/16″ 就累積 1.5U（Upsite），照 IEC 60297 公差也有 0.38U；(2) WP49 列的其他洞：立柱外側（寬櫃沒毛刷）、櫃底走線孔、層板；(3) 驅動力是前後壓差，不是熱浮力，所以小縫也會漏。而且回流會自我放大：T_in = T_s + r·ΔT/(1−r)。

**Q3. 這張卡會讓你的資料模型長出什麼欄位？**

??? note "答案"
    (1) `RackType(unit_mm, self_weight_kg, max_static_kg, max_dynamic_kg)` 與實例上的 `starting_unit / desc_units / u_height / mounting_depth`；(2) `Mount(pos_half_u, height_half_u, face, full_depth)`，`label()` 是推導；(3) `USlot.state ∈ {occupied, blanked, reserved, open}` 與 `Finding.OPEN_U_IN_FRONT_PLANE`——第一個由「缺東西」觸發的告警；(4) `Rack.total_weight_kg` 是推導值，同時餵 `RACK_OVERWEIGHT`（依 `move_state` 選靜態／動態）與 dc-28 的 `FLOOR_OVERLOAD`；承重上限帶 `includes_self`。

## 相關卡片

[空間層級](space-hierarchy.md)｜[冷熱通道封閉](aisle-containment.md)｜[氣流管理的度量](../topics/airflow-management-metrics.md)｜[機櫃 PDU](rack-pdu.md)｜[雙電源設備](dual-corded-equipment.md)｜[RDHx 與 DLC](rdhx-and-dlc.md)
