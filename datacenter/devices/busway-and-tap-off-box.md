---
id: dc-13
title: 匯流排 busway 與插接箱（tap-off box）
category: power
written_at: 2026-08-28
sources:
  - https://www.osha.gov/laws-regs/standardinterpretations/2025-08-25
  - https://download.se.com/files?p_Doc_Ref=SPD_ACOS-9H6RPG_EN
  - https://www.newenglandlab.com/userfiles/files/resources/catalog%20sections/Media%20Ceiling/Starline-Track-Busway-PSG_T5-section_for-web-.pdf
  - https://www.vertiv.com/49ea63/globalassets/products/critical-power/busway-and-busduct/vertiv-powerbar-impb/optimizing-data-center-power-distribution-through-innovative-busway-design-white-paper.pdf
  - https://up.codes/s/reduction-in-ampacity-size-of-busway
related: [dc-11, dc-12, dc-14, dc-10b, topic-01, topic-02, topic-04]
---

# 匯流排 busway 與插接箱（tap-off box）

掛在機櫃列正上方那根鋁擠型長條，裡面是三條銅排＋中性線，外殼開一道槽。插接箱卡上去轉一下鎖住，就多出一路電。[dc-12](rpp-remote-power-panel.md) 的 RPP 是**把分岔搬到現場**；busway 再進一步，**把分岔攤成一條線**——分路不再是盤面第 37 格，而是「距饋入端 12.4 公尺處」。

## 六格

### 拓撲位置

上游：[RPP](rpp-remote-power-panel.md) 分路、[PDU](pdu-floor.md) subfeed，或直接吃 [LV 盤](lv-switchgear.md)（Vertiv 明說可整段取代 PDU）。下游：`dc-14` rack PDU——插接箱出來就是預做好的 drop cord（3/5/7 ft，接頭 15–60 A）。

### 容量單位

**A（整條 run）＋ A（單顆插接箱）＋ 位置**。Starline T5 250/400/800 A；Schneider iBusway 100/225/400 A；Vertiv iMPB 160–1000 A。**插接箱上限遠低於 run**：Schneider 100 A、Vertiv 每相 125 A。

### 冗餘表達

不做 N+1，做 A/B **兩條平行 run**。陷阱與 [dc-12](rpp-remote-power-panel.md) 的 ABB 共櫃同形：兩條若吊同一組吊架，電氣獨立而**空間共命運**。

### 遙測介面

Modbus TCP / SNMP / BACnet，**兩層**：饋入端與每顆插接箱。Vertiv 兩層都給電壓、每相電流、PF、頻率、kW/kvar/kVA、kWh、峰值需量、THD，饋入端另有中性線電流。Starline 饋入端 CPM **達滿載 80% 自動寄信**——廠商寫死的門檻，會跟你的規則打架。

### 故障域

**整列的一邊**。饋入斷路器跳 → 這條 run 上所有機櫃 A 側同時消失，比 RPP 更粗（RPP 每櫃各有分路，busway 整列共用一根導體）。單顆插接箱跳 → 只死那一櫃。

### 維護特性

接頭扭力複緊＋紅外線熱像（都留 IR 窗）。**接頭型式決定要不要複緊**：Starline 每段要 joint kit（螺栓式），Schneider spring-type 標 **maintenance-free**——`joint_type` 欄位，不是通則。支撐間距 Starline ≤10 ft、Schneider ≤5 ft。

## 關鍵數字與計算

### 1. 位置第一次變成計算的輸入：前綴和

RPP 裡第 3 格和第 81 格的斷路器電氣上等價。busway 不是——**離饋入端愈遠的插接箱，電流要流過前面所有段**。約束不是「總和 ≤ 額定」，是**每段的前綴和 ≤ 該段額定**。

端點饋入時最吃緊的永遠是第一段，前綴和退化成總和。但**中央饋入**讓它變成兩個約束：400 A 的 run 從中間灌入，左右各可到 400 A、合計 800 A，**但左 500 / 右 300 不合法**（總和 800 ✓、左段 500 > 400 ✗）。這與 [dc-12](rpp-remote-power-panel.md) `BusSegment` 同形，只是從離散段變成沿路徑的前綴和。

**NEC 368.17(B)**（美規）另允許工業場所接一段**額定較低**的 busway 而不加保護，條件是該段 **≤ 15 m（50 ft）**、額定 **≥ 上游保護裝置的 1/3**、不接觸可燃物。一條 run 的額定**可以中途變小**——`ampacity` 是段的屬性。

### 2. 位置數 ≫ 電流預算，差一個數量級

Schneider iBusway 一段 10 ft 有 **20 個插孔**（前後各一、每 11.4 in 一個）。60 ft 的一列＝6 段＝**120 個插孔**。

但整條 run 只有 400 A。380Y/220 V：`√3 × 380 × 400` = **263.3 kVA**。每櫃一路 30 A 三相（19.7 kVA）→ `400 ÷ 30` ≈ **13 顆**就把電流吃光。

**120 個孔，13 顆的預算。** 面板上的「剩餘插孔 107」是**看起來很有用但完全錯誤**的指標，跟 dc-11 的「U 空間還很多但電早就滿了」同病，比例更誇張（約 9 倍）。而 **連續槽式連孔都沒有**（Starline / Vertiv open channel 任意位置插）——這欄位**連型別都不成立**。

### 3. 降載掛在誰身上：接續 dc-12 的修正

[dc-12](rpp-remote-power-panel.md) 已釐清 ×0.80 是「80% rated 斷路器＋外殼」的屬性。放到 busway 要再分一次：**打折的是上游那顆饋線斷路器（NEC 210.20(A) / 215.3），不是 busway 本體**——busway 的 400 A 是 UL 857 熱測試結果。同一條 400 A busway：

| 上游饋線斷路器 | 連續電流 | kVA @380Y/220 | 6 kW 櫃數 |
|---|---|---|---|
| 400 A，80% rated | 320 A | 210.6 | 35 |
| 400 A，100% rated | 400 A | 263.3 | 43 |

**差 8 櫃，而差別完全不在 busway 上。** 故 `Busway.ampacity_a` 與 `Feeder.continuous_a` 是**兩個物件上的兩個數**，容量取 min；不可以把 0.8 塞進 busway 的欄位。

### 4. 環境溫度：額定的參考點與實際掛的位置不一樣

UL 857 額定測於 **40 °C 環境、55 K 溫升**；IEC 61439-1 給 busbar **70 K**、外接端子 **55 K**，參考環境 35 °C。**兩套標準基準溫度就不同**，同一條 400 A 在兩邊不是同一件事。

而 **busway 吊在機櫃正上方，熱通道封閉的天花板夾層是全機房最熱的空氣**，40–45 °C 完全可能。經驗值是超過 40 °C 每 5 °C 降 3–5%、垂直側立再乘 0.85——但只有二手來源，**不要直接用**，要跟廠商要降載曲線。這正是 `derating_basis` 的用途：降載可以有，但要說得出出處。

### 5. SCCR 是路徑上的最小值，不是設備的屬性

Schneider 400 A busway straight **35 kA**，標配 QOU 插接箱斷路器卻只有 **10 kA**（EDB 18 kA；22/35 kA 版要另指定）。原廠自己寫明：插接箱的短路額定**同時受 busway、drop cord 與接頭限制**。

若 RPP 端可用故障電流 22 kA：busway 35 kA ✓、tap 10 kA ✗。**系統 SCCR = 路徑 min = 10 kA < 22 kA → 誤用**，除非該組合有 series rating 列名。schema 要的是逐件 `sccr_ka` ＋ `series_rated_with`，驗證是「沿路徑取 min，比對該點可用故障電流」。

### 6. 電壓降算出來不是瓶頸——但位置仍要存

Starline 400T5 分佈負載三相 **1 V / 65 ft @0.8 PF**（滿載）。60 ft 的一列 ≈ **0.92 V**，佔 380 V 的 **0.24%**，離 3% 常見上限很遠。

集中負載約為分佈的兩倍 → 單位係數 `k ≈ 1/(400 × 32.5) = 7.7e-5 V/(A·ft)`。100 A 插接箱在 50 ft 處：`100 × 50 × 7.7e-5` = **0.39 V**；在 10 ft 處只有 **0.08 V**。**同一顆箱子，位置差 5 倍壓降。**

**今天電壓降不是 busway 的約束**（它取代的那條長電纜常常是）；**但位置必須存**——長 run 會讓它變成約束，而到那時位置資料補不回來。

## 常見誤解

**以為插接箱能熱插拔所以不算需要程序的事件，但實際上 OSHA 2025-08-25 解釋函明說不是。** 廠商文案講 hot swappable / zero downtime；OSHA 引 NFPA 70E (2021) table 130.5(C)：插入或移除 busway 插接裝置**不論運轉狀態都存在電弧閃絡可能**，適用 29 CFR 1910.333(c)。預設斷電，不斷電要先證明「斷電會引入額外危害或不可行」，並用合格人員＋PPE。**Schneider 型錄裡自己就印著這段。**「不用停機」是真的，「不用走流程」是假的。

**以為 busway 額定要打 8 折，但實際上打折的是上游那顆饋線斷路器。** busway 的 400 A 是 UL 857 熱測試出來的；0.8 寫進 busway 欄位會兩邊各扣一次，或在 100% rated 系統上憑空丟掉 8 櫃。

**以為「還有幾個插孔」就是還能加幾櫃，但實際上插孔數約是電流預算的 9 倍。** 120 孔、13 顆的預算。而連續槽式根本沒有「孔」這個離散實體，這欄位在它身上不存在。

## 對資料模型的意涵

1. **位置從裝飾欄位升級成計算輸入。** `TapOff.offset_m: float`（距饋入端）＋ `Busway.feed_position: Literal["end","center"]`。容量驗證從 dc-12 的「分段和」推廣成**沿路徑的前綴和**：對每個切點，`Σ(該側 tap 電流) ≤ 該段 ampacity`；中央饋入左右各算一次。

2. **接取模式是型別的分水嶺。** `tap_access: Literal["fixed_outlet","continuous_slot"]`。`fixed_outlet` 才有 `outlet_count` / `free_outlets` / `outlet_pitch_mm`；`continuous_slot` 下這些欄位**必須不存在**（不是設成 0）。這是 dc-12 `phase_mode` 教訓的第二次：**同一個欄位在兩種設備上，一個是必要一個是謊言，所以模式要先被記錄。**

3. **`ampacity` 掛在段上不是 run 上。** NEC 368.17(B) 允許 run 中途降額定，故 `BuswaySegment{from_m, to_m, ampacity_a}`，run 只是段的有序集合。驗證要能表達「該段額定 ≥ 上游 OCPD 的 1/3 且 ≤ 15 m」。

4. **告警門檻有兩個來源。** 設備內建（Starline CPM 寫死 80% 寄信）與平台自訂：`AlarmRule.origin` ＋ `mutable: bool`。不記，值班表會收到兩套不一致的門檻，而其中一套你改不動。

5. **能量作業狀態要三態，不能是布林。** dc-12 的 `requires_outage_to_add_circuit: bool` 不夠用，正解 `change_class: Literal["outage_required","energized_work_permit","no_permit"]`。加一顆插接箱是**中間那一態**：不停機，但要工單、合格人員、PPE。布林會把它錯分到「不用管」。

## 該問 facility 的問題

1. **「插接箱是連續槽還是固定插孔？固定的話節距多少、單段幾個孔？」** 決定 schema 分支，也決定「還能加幾櫃」的答案型別。
2. **「加一顆插接箱是斷電做還是走能量作業許可？誰簽？」** OSHA 解釋函之後這題有標準答案，但**你們實際怎麼做**才是要進 schema 的那個。
3. **「吊裝位置的環境溫度量過嗎？廠商降載曲線拿得到嗎？」** 銘牌測於 40 °C，天花板夾層不是。答不出來 → `derating_basis` 標 `unknown`，不要假設 1.0。

## 動手練習（30–40 分鐘）

接在 [dc-12](rpp-remote-power-panel.md) 的 `Rpp` 下游。新東西是**一維座標**與**前綴和驗證**——前三張卡的 `validate()` 只需看集合，今天第一次需要看順序。

```python
from dataclasses import dataclass, field
from typing import Literal

TapAccess = Literal["fixed_outlet", "continuous_slot"]
ChangeClass = Literal["outage_required", "energized_work_permit", "no_permit"]

@dataclass
class BuswaySegment:
    from_m: float; to_m: float
    ampacity_a: float                       # ★ 額定掛在段上（NEC 368.17(B)）

@dataclass
class TapOff:
    id: str; offset_m: float                # ★ 位置＝計算輸入
    amps: float; sccr_ka: float

@dataclass
class Busway:
    id: str; voltage_ll: float; length_m: float; sccr_ka: float
    feed_offset_m: float                     # 端點=0.0；中央=length/2
    tap_access: TapAccess
    outlet_pitch_mm: float | None = None      # 只有 fixed_outlet 合法
    upstream_ocpd_a: float = 400.0
    upstream_ocpd_style: Literal["80_percent", "100_percent"] = "80_percent"
    ambient_c: float = 40.0
    derating_basis: str = "unknown"           # ← dc-12 立的欄位，這裡真用上
    joint_type: Literal["bolted", "spring"] = "bolted"
    segments: list[BuswaySegment] = field(default_factory=list)
    taps: list[TapOff] = field(default_factory=list)

# TODO feed_continuous_a()  沿用 dc-12 的 continuous_factor（80%->×0.8）
# TODO prefix_load_a(x_m)   饋入端到 x 之間的 tap 電流和；中央饋入分左右各算
# TODO validate() -> list[str]   至少四條：
#   前綴和 每個 segment 邊界該側前綴和 > segment.ampacity_a
#   饋入   max(左總和, 右總和) > feed_continuous_a()
#   型別   continuous_slot 卻設了 outlet_pitch_mm
#   位置   tap.offset_m 不在 [0, length_m]
# TODO system_sccr_ka(tap_id)  回 min(busway, tap)，不是自己的值
# TODO voltage_drop_v(tap_id, k=7.7e-5)
#   Σ 段：該段承載電流 × 段長 × k（不是只算 tap 自己那段）
# TODO change_class()  加 tap -> "energized_work_permit"（見 OSHA 2025-08-25）
# TODO free_capacity() -> {"amps","racks_at_6kw","free_outlets"}
#   free_outlets 在 continuous_slot 下回 None，不准回 0
```

### 驗收表

380Y/220 V、400 A run、60 ft（18.3 m）、上游 400 A：

| 情境 | 期望 |
|---|---|
| `feed_continuous_a()` @80%／@100% | **320**／**400 A** → **210.6**／**263.3 kVA**（差 8 櫃） |
| 端點饋入、13 顆 30 A tap | **390 A**：@100% 通過、@80% **饋入違規** |
| 中央饋入、左 500／右 300 A | **前綴和違規**（總和 800 ≤ 800 卻仍違規） |
| `continuous_slot` 卻設 `outlet_pitch_mm` | **型別違規**（不是警告） |
| `system_sccr_ka()`：busway 35、tap 10 | **10.0**（不是 35） |
| `voltage_drop_v()` 100 A @50 ft／@10 ft | **≈0.39**／**≈0.08 V** |
| `change_class()` | **`"energized_work_permit"`** |
| `free_capacity()` @`continuous_slot` | `free_outlets` is **None** |

**加分題**：把 dc-12 的 `Rpp.headroom()` 接上來——RPP 一條分路餵這條 busway，算「整列還能加幾櫃」時取 `min(RPP 剩餘, busway 剩餘)`，並回報**哪一端先卡住**。`binding` 這個欄位 [dc-10b](sts-two-source-relationship.md) 出現過一次了。

## 自我檢核

**Q1. 廠商說插接箱可以熱插拔、零停機。你們的變更流程可以因此把「加一路電」歸類成不需要工單的日常操作嗎？**

??? note "答案"
    **不行。** OSHA 2025-08-25 解釋函引 NFPA 70E (2021) table 130.5(C)：插入／移除 busway 插接裝置**不論運轉狀態**都存在電弧閃絡可能，適用 29 CFR 1910.333(c)。預設斷電；要帶電做，雇主須先證明斷電會引入額外危害或不可行，再用合格人員（1910.332(b) 訓練）＋PPE。Schneider 型錄裡印了同樣的警語。

    **廠商講的「零停機」是負載不中斷，不是「不需要程序」。** 模型上代表 `requires_outage: bool` 不夠用——要三態 `change_class`，busway 落在中間那態。

**Q2. 一條 400 A busway 從中央饋入。有人說「左右加起來 800 A 以內就好」。他錯在哪？**

??? note "答案"
    **總和對，分佈錯。** 導體是每方向各 400 A，左 500 / 右 300 總和 800 合法，但左半段前綴和 500 > 400 已過載。

    正確約束是**沿路徑的前綴和**：對每個切點，該側 tap 電流和 ≤ 該段額定。這是 [dc-12](rpp-remote-power-panel.md) `BusSegment` 的推廣——RPP 的段離散且無序，busway 的段**有方向**，離饋入端的距離決定誰疊在誰上面。**這是這條電力鏈上第一個「順序有意義」的設備。**

**Q3.（建模）「這條 busway 還能掛幾櫃」這個查詢，會讓資料模型長出哪些欄位與約束？**

??? note "答案"
    **欄位**：`TapOff.offset_m`、`Busway.feed_offset_m`、`BuswaySegment{from_m, to_m, ampacity_a}`（額定在段上，NEC 368.17(B) 允許中途降額）、`tap_access` ＋條件欄位 `outlet_pitch_mm`、`upstream_ocpd_a` / `upstream_ocpd_style`（打折掛在上游斷路器，**不是** busway）、`ambient_c` ＋ `derating_basis`、逐件 `sccr_ka`。

    **回傳型別**：同 dc-12，不能是 `float`。至少 `{amps, racks_at_6kw, free_outlets, binding}`——`free_outlets` 在連續槽式必須是 `None`；`binding` 要說出是上游斷路器、某段前綴和、還是 SCCR 先卡住。

    **約束**：前綴和逐段檢查（有方向）；SCCR 沿路徑取 min 比對可用故障電流；`continuous_slot` 下 `outlet_pitch_mm` 必須為空。**告警**：饋入端與每顆 tap 是兩層點位，門檻不同；`AlarmRule.origin` 要能分辨設備內建（CPM 寫死 80%）與平台自訂——前者你改不動。
