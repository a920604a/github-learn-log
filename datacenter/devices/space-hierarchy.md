---
id: dc-28
title: 站點／建築／樓層／機房區的空間層級
category: space
written_at: 2026-09-24
sources:
  - https://netboxlabs.com/docs/netbox/features/facilities/
  - https://netboxlabs.com/docs/netbox/models/dcim/location/
  - https://github.com/netbox-community/netbox/discussions/11972
  - https://www.cablinginstall.com/standards/article/55245177/tia-942-c-data-center-standard-brings-a-host-of-changes-and-updates
  - https://www.epi-ap.com/content/28/641/The_data_centre_is_not_meeting_the_12kPa_floor_loading_capability_as_per_TIA-942_Rated-3_Will_this_data_centre_fail_the_certification
  - https://lawplayer.com/article/6438f58fe800e5f0b933d8ae
  - https://www.sunbirddcim.com/blog/your-data-center-ready-nvidia-gb200-nvl72
related: [dc-19b, dc-23, dc-25, dc-25b, dc-27, dc-09c, dc-15, dc-29, dc-33, dc-34, topic-10]
---

# 站點／建築／樓層／機房區的空間層級（site / building / floor / room hierarchy）

前 27 張卡建的是兩棵**流的樹**：電往下流、熱往外流。空間層級回答的是另一個問題：**東西放在哪裡**。它本身不供電、不排熱，但 [dc-19b](npsh-and-pump-placement.md) 要標高、[dc-25](aisle-containment.md) 要通道歸屬、[dc-25b](../topics/airflow-management-metrics.md) 的 `AirBalance` 要掛在通道上、[dc-27](rdhx-and-dlc.md) 的跨實體約束只能住在房間層——**四張卡提前借用過它，今天把帳還上**。

## 六格

### 拓撲位置
包含樹：`Region → Site → Building → Floor → Room → (Row/Aisle) → Rack → U`。**與電力樹、熱樹正交**：設備錨在葉子上，但空間的父子關係不代表任何能量流向。另有多張覆蓋分區（防火區、冷卻區、門禁區、租戶籠）橫跨這棵樹。

### 容量單位
m²（白空間）、機櫃位數、**樓板活載重 kPa**（均佈）與點載重、m³（熱容用）、kW/櫃或 kW/m²（功率密度，引用電力／熱樹的結果，不是空間自己的量）。

### 冗餘表達
空間上的冗餘是**實體隔離**：A/B 路 UPS 放不同房間、不同防火區。「2N」若兩路在同一防火區，一次氣體釋放或一次淹水同時帶走兩路——**拓撲上獨立、空間上不獨立**（[dc-10b](sts-two-source-relationship.md) 的 common-ancestor 只算了電）。細節留 `topic-05` 與 `topic-06`。

### 遙測介面
空間本身零點位。所有感測器都是掛在某個空間節點上的 `MeasurementPoint`（[dc-15](power-meter.md) 立的「標註不是拓撲」）：

| 層級 | 掛在上面的量 | 來源卡 |
|---|---|---|
| Site | 乾球／濕球（配對時間序列） | [dc-17](cooling-tower.md)、[dc-23](crac-direct-expansion.md) |
| Room | 溫濕度、露點、熱容 | `dc-37`、dc-24、dc-27 |
| Aisle | 差壓、λ、RTI | [dc-25b](../topics/airflow-management-metrics.md) |
| Rack | 進風溫度、重量 | dc-22、本卡 |

### 故障域
建築（地震、外電）> 樓層（淹水，地下室尤甚）> **防火區**（氣體滅火一次釋放整區，`dc-33`）> 房間 > 通道（封閉頂板落下，dc-25）> 機櫃。

### 維護特性
結構幾乎不變；會變的是**名字與編號**（改建、租戶換手、重新排列）與機櫃位置（MAC）。所以：**主鍵用不可變 ID，名稱是屬性。**

## 關鍵數字與計算

### 演算一：樓板載重——同一台機櫃，分母不同差 2.1 倍

TIA-942 對電腦機房樓板：**最低 7.2 kPa（150 lbf/ft²）、建議 12 kPa（250 lbf/ft²）**；**942-C（2024-05）把 < 20 m² 的機房最低值降到 5 kPa**（100 lbf/ft²），並強調須由結構技師確認。換算 kgf/m²（÷ 9.80665 × 1000）：

| kPa | kgf/m² |
|---|---|
| 5 | 509.9 |
| 7.2 | 734.2 |
| 12 | 1223.7 |

一台 GB200 NVL72：**1.36 t、600 × 1068 mm**（Sunbird 引 Supermicro 規格表與 The Register，原文頁已核對）。

- **只除底面積**：0.6 × 1.068 = 0.6408 m² → 1360 / 0.6408 = **2122 kgf/m² = 20.8 kPa**
- **除分擔面積**（櫃寬 × (櫃深 + 半個冷通道 + 半個熱通道)，兩通道各 1.2 m）：0.6 × (1.068 + 0.6 + 0.6) = 1.3608 m² → **999 kgf/m² = 9.80 kPa**

兩個數字都「對」，但對到不同規格：kPa 是**均佈載重**，要拿分擔面積比——**9.80 kPa 超過 7.2 最低值、低於 12 建議值**；底面積那個數字是**點／集中載重**的問題，要另外對結構技師給的單點上限（本次沒有取得數值）。對照一台傳統 600 kg 機櫃同樣排列：**441 kgf/m² = 4.32 kPa**，連 5 kPa 都不到——**所以舊機房從來沒人算過，AI 櫃一進來第一次需要。**

⚠ 搜尋摘要另有「含冷卻液近 1500 kg」「點載重 1875 kg/m²」「傳統架高地板每櫃 500–750 kg」，**原文頁找不到原句，依 dc-26b 立的規則不寫入計算。**

**台灣：** 《建築技術規則建築構造編》第 17 條——活載重依樓地板用途不得小於表列；**不在表列之用途「應按實計算，並須詳列於結構計算書中」**。本次抓到的條文頁未含表格本體，機房是否在表內未能核對；但條文結構本身告訴你：**台灣機房的樓板容量，權威來源是這棟樓的結構計算書，不是 TIA。**

### 演算二：高程基準錯位 0.45 m，剛好等於一個 NPSH 餘裕

假設 Site 以 GL（室外地面）為 ±0，1F 完成面 FFL = GL + 0.45 m。一份圖說寫「冷卻水塔盤運轉水位 +24.00」是**相對 1F FFL**，另一份寫泵中心「−4.50」是**相對 GL**。若程式直接相減：24.00 − (−4.50) = 28.50 m；真值是 (24.00 + 0.45) − (−4.50) = **28.95 m，差 0.45 m**。

[dc-19b](npsh-and-pump-placement.md) 那台泵在 110% 流量時 margin 是 **−0.50 m**。**一個基準錯位就足以把紅燈翻綠或反過來**，而兩個數字各自都抄對了圖。→ 標高永遠是 `(value_m, datum_ref)` 對，不能是裸 float。

### 演算三：房間熱容從兩個手算常數變成一個函數

W38 #5 抓到 dc-23 與 dc-25「同一間機房、兩個熱容、差 9%」。有了空間層級，它就是 `Room` 上的函數（ρcp = 1.21 kJ/m³·K、1600 kW、允許溫升 8 K）：

| 呼叫 | 體積 | 熱容 | ride-through |
|---|---|---|---|
| `thermal_mass(room, include_underfloor=False)` | 1000 × 4 = 4000 m³ | 4840 kJ/K | **24.2 s**（= dc-23） |
| `thermal_mass(room, include_underfloor=True, exclude=[熱通道 230 m³])` | 4000 − 230 + 600 = 4370 m³ | 5287.7 kJ/K | **26.4 s**（= dc-25） |

**兩張卡都沒錯，差別只在兩個布林參數——而它們之前沒被寫下來。** 參數顯式化之後，這兩個數字不可能再被當成「同一個量」比大小。

## 常見誤解

1. **以為空間是一棵樹，但實際上是一棵包含樹加上多張互相交錯的覆蓋分區。** 防火區可以橫跨兩個房間，租戶籠可以只佔半個房間，門禁區跟著走道切。硬塞進一棵樹，就得選一種切法當主幹，其他全變成錯的父子關係。
2. **以為樓板載重就是機櫃重量除以底面積，但實際上 kPa 規格是均佈載重，要除分擔面積；底面積算出的是點載重，要對另一個上限。** 同一台 1.36 t 機櫃，9.80 kPa 與 20.8 kPa 都是對的，錯的是拿錯的那個去比錯的規格。
3. **以為機房編號（`R2-A-07`）可以當主鍵、標高可以存成一個數字，但實際上名稱會改、標高沒有基準就沒有意義。** 名稱是可變屬性；標高必須帶 datum；座標必須帶所屬房間與旋轉角。

## 對資料模型的意涵

1. **一棵嚴格包含樹 ＋ N 張覆蓋分區。** `Space(id, kind, parent_id, name, datum_ref)`：單一父節點、`kind ∈ {site, building, floor, room, aisle}`。`Zone(id, kind, members)`：`kind ∈ {fire, cooling, security, tenancy, containment}`。約束：**同一 `kind` 的 Zone 必須互斥**（一個機櫃不能同時在兩個防火區），**不同 `kind` 之間可任意交疊**。故障域查詢改成「沿包含樹往上 ∪ 所有覆蓋分區」，dc-25 立的 `fault_domain = {power, cooling, containment}` 在這裡多一個 `fire` 軸。
2. **通道歸屬是算出來的，不存。** `Rack.placement(room_id, x_m, y_m, rotation_deg)` ＋ `Aisle(kind=cold|hot, polygon)` → `aisle_of(rack)` 取機櫃前緣外 0.3 m 的點落在哪個通道。**前緣落在熱通道吐 `Finding.RACK_FACING_HOT_AISLE`**——這是裝錯方向的機櫃，而它在任何電力或容量報表上都是綠的。
3. **樓板容量是 `Sourced` 值，且要兩個上限。** `Room.floor_uniform_kpa: Sourced[float]`（source = 結構計算書／TIA／AHJ）＋ `Room.point_load_kg: Sourced[float] | unknown` ＋ `Rack.weight_kg`（`measured | estimated`）。檢查用分擔面積，吐 `Finding.FLOOR_OVERLOAD`；點載重未知時是 `UNDETERMINED` 不是綠燈（W38 立的第五態）。EPI 說稽核接受低於 12 kPa 的前提是「**每櫃現重有資產系統在追、搬遷前有評估流程**」——**`Rack.weight_kg` 是認證證據，不是備註欄。**
4. **`RoomReport` 終於有錨點。** 以 `Space.id`（kind = room）為鍵；`thermal_mass()`、dc-27 的 `Constraint(ewt ≥ room_dew_point + margin)`、dc-24 的 `ControlGroup` 都掛在這裡。W38 #3 要求的 `AisleAirBalance` / `RoomAirBalance` 也因此分得開：**鍵的 `kind` 不同，型別就不同。**
5. **NetBox 斷點第三條（記給 `topic-10`）。** NetBox 的 `Location` 是 Site 內**單一**自遞迴樹（可表 floor/room/cage），`RackGroup` 是**扁平**的第二軸（row/aisle/pod），機櫃只能各掛一個。它表達得了包含樹，**表達不了「同一機櫃同時屬於一個防火區、一個冷卻區、一個租戶籠」**；`Location` 也沒有高程、載重、幾何欄位。→ 覆蓋分區走 tag／custom field，幾何與載重自己補。

## 來源分歧

**一、12 kPa 是建議值還是等級要求？** 一般摘要把 TIA-942 寫成「最低 7.2、建議 12」，適用所有機房；EPI（認證稽核方）寫成「**Rated-3** 應為 12 kPa」，是綁在等級上的要求，並說稽核會以「適用即可」接受較低值，只要能出示結構技師聲明、每櫃重量追蹤與搬遷評估流程。**TIA 原文未取得**，兩說並列。

**二、Site 到底是什麼？** NetBox 官方文件：Site「通常代表一棟建築」；社群回覆（#11972）：有人一個校區一個 Site、建築全用 Location 表示，理由是 VLAN 與 Prefix 好綁 Site。**這不是誰對誰錯，是 Site 的粒度決定了 Location 樹從哪一層開始**——匯入 NetBox 前必須先定案，否則半年後要搬家。

## 該問 facility 的問題

1. **機房區的樓板設計活載重是多少 kPa？點載重上限多少？** 請給結構計算書的頁碼，不要口頭數字。
2. **全廠高程的 ±0 是 GL、1F FFL 還是海拔？** 機電圖與建築圖是否同一基準？
3. **防火區（氣體滅火區）的邊界圖在哪？** 有沒有哪一區同時包含 A、B 兩路的設備？

## 動手練習（30–40 分鐘）

接 [dc-27](rdhx-and-dlc.md) 的 `rdhx.py`，新建 `space.py`。**目標：把前四張卡借用過的空間概念一次落地，讓通道歸屬、樓板超載、熱容三件事都由同一個 `Room` 算出來。**

```python
import math
from dataclasses import dataclass, field

G = 9.80665
RHO_CP = 1.21   # kJ/m³·K

@dataclass(frozen=True)
class Rect:
    x0: float; y0: float; x1: float; y1: float
    def contains(self, x, y) -> bool: ...

@dataclass(frozen=True)
class Aisle:
    id: str; kind: str; rect: Rect; volume_m3: float

@dataclass(frozen=True)
class Rack:
    id: str; x: float; y: float; rotation_deg: int   # 0 = 前緣朝 +y
    w: float = 0.6; d: float = 1.068; weight_kg: float = 1360

@dataclass
class Room:
    id: str; area_m2: float; height_m: float; underfloor_m3: float
    floor_uniform_kpa: float; aisles: list[Aisle] = field(default_factory=list)

    def thermal_mass_kj_k(self, include_underfloor: bool,
                          exclude: tuple[str, ...] = ()) -> float: ...

def front_point(rack: Rack, probe_m=0.3) -> tuple[float, float]:
    ...  # 前緣中點再往外 probe_m；方向 (−sin θ, cos θ)

def aisle_of(room: Room, rack: Rack) -> Aisle | None: ...

def uniform_load_kpa(rack: Rack, cold_m=1.2, hot_m=1.2) -> float:
    ...  # weight / (w × (d + cold/2 + hot/2)) × G / 1000

def check(room: Room, racks: list[Rack]) -> list[str]:
    ...  # 回 Finding 名稱：RACK_FACING_HOT_AISLE / FLOOR_OVERLOAD
```

測試資料：`Room("R1", 1000, 4, 600, 7.2)`；通道 `HA-1` 熱 `Rect(0,1.266,40,2.466)`、`CA-1` 冷 `Rect(0,3.534,40,4.734)`、`HA-2` 熱 `Rect(0,5.802,40,7.002)`，熱通道體積各 230 m³（簡化，只算 HA-1）。

### 驗收表

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | `aisle_of(Rack("A-01", 0.3, 3.0, 0))` | **CA-1** |
| 2 | `aisle_of(Rack("B-01", 0.3, 5.268, 180))` | **CA-1**（面對面共用冷通道） |
| 3 | `aisle_of(Rack("B-02", 0.9, 5.268, 0))` | **HA-2** → `RACK_FACING_HOT_AISLE` |
| 4 | `uniform_load_kpa(Rack(..., weight_kg=1360))` | ≈ **9.80** → 對 7.2 吐 `FLOOR_OVERLOAD` |
| 5 | 同上 `weight_kg=600` | ≈ **4.32**，不吐 |
| 6 | `thermal_mass_kj_k(False)` / `(True, exclude=("HA-1",))` | **4840** / ≈ **5287.7** |

**加分題**：把 `floor_uniform_kpa` 改成 `Sourced`，`source="TIA-942 min"` 時 7.2、`"TIA-942 recommended"` 時 12——同一台機櫃在兩個 source 下一紅一綠。讓 `check()` 在 Finding 裡帶出 source，**不帶出處的 FLOOR_OVERLOAD 沒有人知道該去找誰。**

## 自我檢核

**Q1. 一台 1.36 t 的機櫃，你算出 20.8 kPa，同事算出 9.80 kPa，誰錯？**

??? note "答案"
    都沒錯，比的規格不同。20.8 kPa 是除底面積，屬點／集中載重，要對結構技師給的單點上限；9.80 kPa 是除分擔面積（含半個冷、熱通道），才是拿去對 TIA 7.2／12 kPa 均佈載重的數字。錯的是拿 20.8 去對 12，或拿 9.80 說「點載重沒問題」。

**Q2. 為什麼防火區不能當 `Location` 樹的一層？**

??? note "答案"
    因為它跟房間不是包含關係：一個防火區可能跨兩個房間，一個房間也可能被切成兩區。硬塞進樹就得選一種切法當主幹，另一種變成錯的父子關係。正解是包含樹只放嚴格包含的層級（site/building/floor/room），防火區、冷卻區、租戶籠都做成覆蓋分區，同類互斥、異類可交疊。

**Q3. 這張卡會讓你的資料模型長出什麼欄位？**

??? note "答案"
    (1) `Space(id, kind, parent_id, datum_ref)` ＋ `Zone(kind, members)`，同類互斥；(2) `Rack.placement(room_id, x, y, rotation_deg)`，`aisle_of()` 是推導不是欄位，並有 `Finding.RACK_FACING_HOT_AISLE`；(3) `Room.floor_uniform_kpa: Sourced` ＋ `point_load_kg` ＋ `Rack.weight_kg(measured|estimated)` ＋ `Finding.FLOOR_OVERLOAD`；(4) 標高一律 `(value_m, datum_ref)`；(5) `RoomReport` 以 `Space.id` 為鍵，`thermal_mass_kj_k(include_underfloor, exclude)` 取代兩處手算常數。

## 相關卡片

[NPSH 與泵的擺放高度](npsh-and-pump-placement.md)｜[冷熱通道封閉](aisle-containment.md)｜[氣流管理的度量](../topics/airflow-management-metrics.md)｜[CRAC 直膨式](crac-direct-expansion.md)｜[RDHx 與 DLC](rdhx-and-dlc.md)｜[鋰電消防合規](lib-fire-compliance.md)｜[電力監測儀表](power-meter.md)
