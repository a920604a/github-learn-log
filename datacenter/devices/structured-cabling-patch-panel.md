---
id: dc-31
title: 配線架與結構化布線（patch panel / structured cabling：permanent link、channel、跳線降額、前後埠對應）
category: space
written_at: 2026-10-01
sources:
  - https://en.wikipedia.org/wiki/Structured_cabling
  - https://tiaonline.org/wp-content/uploads/2024/05/TIA-942-C-DC-infrastructure-stadard_TIA-white-paper.pdf
  - https://www.cablinginstall.com/standards/article/55245177/tia-942-c-data-center-standard-brings-a-host-of-changes-and-updates
  - https://www.ieee802.org/3/hssg/public/nov06/diminico_01_1106.pdf
  - https://www.cablinginstall.com/home/article/16467062/a-standards-based-design-in-the-data-center
  - https://www.flukenetworks.com/blog/cabling-chronicles/skinny-28-awg-patch-cords
  - https://www.telegaertner.com/en/knowledge-center/facts-about-25/40gbase-t-and-category-8
  - https://netboxlabs.com/docs/netbox/models/dcim/frontport/
  - https://netboxlabs.com/docs/netbox/models/dcim/rearport/
related: [dc-30b, dc-30, dc-29, dc-28, dc-32, topic-10]
---

# 配線架與結構化布線（patch panel / structured cabling）

[dc-30b](cable-tray-and-pathway.md) 算了電纜**走哪條槽**，這張補上電纜**兩端接到什麼**：配線架是一塊「被動、沒有 IP、卻決定整條連線長什麼樣」的面板。它把一條連線切成「固定的長線（permanent link）」加「可換的跳線（patch cord）」，使資料中心的網路變更變成**在配線架上拔插跳線**，而不是重拉線。對資料模型來說，它是 NetBox `FrontPort` / `RearPort` 的原型，也是**「連線」不等於「一條線」**的第一個實例。

## 六格

### 拓撲位置
伺服器 NIC →（跳線）→ 機櫃內／列尾配線架 →（水平固定線，走 dc-30b 的線槽）→ 區域或水平配線區的配線架 →（跳線）→ 交換器。TIA-942 的空間命名：MDA（主配線區，放 main cross-connect）、HDA（水平配線區，放 horizontal cross-connect）、ZDA（區域配線區，放 zone outlet 或 consolidation point）、EDA（設備配線區，放機櫃）。

### 容量單位
**埠數**（口／U）與**長度預算**（m）。長度是主要約束：固定線 ≤ 90 m、含跳線的 channel ≤ 100 m（銅纜通用上限；Cat 8 只有 30 m，見下）。機櫃空間以 U 計，由 [dc-29](rack-and-rack-unit.md) 的 `Rack` 管。

### 冗餘表達
沒有 N+1，冗餘靠**拓撲**：TIA-942 支援星形拓撲加選配的區間冗餘。2N 的兩路若走**同一個配線架／同一條線槽**，路由並不獨立——這是 dc-30b 的 `route_independence` 往上延伸一層（配線架本身也要算進路由）。

### 遙測介面
配線架本身**沒有遙測**。連線是否存在只能靠兩端設備的 link 狀態（SNMP／LLDP，→ `dc-43`）與人工盤點對帳。標示標準 TIA-606-A 被 TIA-942 建議遵循（來源只說「建議遵循」，內容未取得）。

### 故障域
一個配線架掛掉（實際是被人誤拔、被誤標）→ 該面板所有埠。更常見的是**標示錯誤**造成的人為故障：跳線插錯口，拓撲圖還以為是對的。

### 維護特性
變更頻繁（每次上架／下架／換交換器）。每次變更是一次**沒有工單就會悄悄發生的資料漂移**：資料庫說 A 口接 X，現場是 B 口。維護的重點是對帳，不是保養。

## 關鍵數字與計算

### (1) permanent link、channel 與跳線降額

- **標準情境**（多源一致）：固定線 90 m ＋ 兩端跳線合計 10 m ＝ channel 100 m。
- **降額**（來源：Fluke，轉述 TIA-568.2-D）：28 AWG 細跳線導體電阻大、衰減高，固定線上限要打折：

```
perm_max = 102 − 1.95 × L_cord      （28 AWG；L_cord = 跳線合計長度 m；結果上限 90）
```

代入：

| 跳線合計 | 計算 | perm_max | channel 總長 |
|---|---|---|---|
| 6 m | 102 − 11.70 = 90.30 → 封頂 90 | 90 | 96 |
| 10 m | 102 − 19.50 | **82.5** | 92.5 |
| 15 m | 102 − 29.25 | **72.75** | 87.75 |

注意 Fluke 文章把 15 m 那列寫成「73 m」。**72.75 四捨五入成 73 就超標了**：固定線必須往下取整（floor），不能四捨五入。這是資料模型裡一個真實的「舍入方向」約束。

### (2) Category 8 的 30 m

來源：Telegärtner。Cat 8 channel 上限 **30 m ＝ 24 m 水平線 ＋ 兩端各最多 3 m 跳線**，且**最多 2 個連接點**（2-connector channel）。比 Cat 6A 的 100 m 小得多，所以 25/40GBASE-T 只適合機櫃列內、交換器到伺服器的短距離。實例：24 + 3 + 3 = 30 剛好 OK；水平 25 m 就 31 > 30，違規；多插一個配線架（3 個連接點）也違規。

### (3) ZDA 與直連

- ZDA 內**不得有 cross-connect**、一條水平線路徑上**最多一個 ZDA**、**ZDA 最多 144 個連接**（來源：IEEE 802.3 簡報轉述 TIA-942 原版；942-C 是否沿用**未驗證**）。
- 直接連（DAC 等）只適用於**同一機櫃或相鄰機櫃**（來源：cablinginstall 轉述 TIA-942-C 指引），其餘要走結構化布線。

### (4) 空間估算（假設數字，非標準值）

24 台伺服器 × 每台 2 個銅纜口 = 48 口。設 24 口/U（假設），需 **2U** 配線架。cablinginstall 提到「十個地板下配線箱可省出 40U＝一整個機櫃」，意思是配線架的 U 數是**真實的機櫃空間成本**，要回寫 dc-29 的 `Rack`。942-C 另要求放交換器的區域**機櫃寬至少 800 mm**（舊版 600 mm 對高密度跳線不實用）→ `RackType.width_mm` 要能約束。

### 來源分歧與疑點

1. **「100 m」不是通用常數**：Wikipedia 說 90 m ＋ 合計 10 m 跳線；IEEE 簡報說 channel 含設備跳線 100 m；Fluke 說有降額公式，channel 可以是 92.5 或 87.75。三者在標準情境不衝突，但**跳線不是標準情境時結論不同**。
2. **cross-connect / interconnect 的定義**：IEEE 簡報的摘要把 interconnect 描述成「配線區內連接主動設備的點」，與業界常見用法（interconnect＝設備直接接到配線架、不經第二組跳線）不同；因為是 AI 摘要轉述，**暫不採用**，兩者差在 channel 內的連接點數，要看 TIA-568 原文。
3. **連接點怎麼算**（設備端插孔算不算）本卡來源**都沒說**，Cat 8 的「2 個連接」依 Telegärtner 的字面。
4. **Fluke 的 28 AWG 跳線「<15 m」** 與它自己的 15 m 範例互相矛盾；練習用 ≤ 15。
5. TIA-568、TIA-942-C、ISO/IEC 11801 原文**皆未取得**；ISO 系統另有 Cat 8.1／8.2（Class I／II），8.2 的連接器與 RJ45 不相容。**先問 facility 採哪一套標準**（TIA／ISO／EN 50173），不要把任一套的數字當通用。

## 常見誤解

**以為 100 m 就是「一條網路線的最大長度」，但實際上 90 m 是固定線、100 m 是含跳線的 channel，而且跳線換成 28 AWG 或拉長就要降額，Cat 8 更只有 30 m**——資料庫只存「Cable.length」會讓三種情況混成同一個數字。

**以為配線架是被動的，不需要建模，反正兩端設備都有記錄，但實際上它是路徑的中繼點**——前埠到後埠的對應是資料（NetBox 的 `rear_port_position`），一個 12 芯 MPO 後埠可以對應 12 個 LC 前埠；兩端面板若位置對應不一樣（反轉），A 面板的 LC3 會出現在 B 面板的 LC10。不建模就追不到「這條連線另一頭到底在哪」。

**以為機櫃之間直接拉條跳線或 DAC 最省事，但實際上直連只限同機櫃或相鄰機櫃**，跨列要走結構化布線；否則每次搬機櫃都要重拉一條不在任何圖上的「野線」，而且它也不在 dc-30b 的線槽填充計算裡。

## 對資料模型的意涵

1. **Panel 是 Device，有 `RearPort(positions)` 與 `FrontPort(rear_port, rear_port_position)`**（NetBox 官方模型）。約束：`rear_port_position` ∈ [1, positions]，且 `(rear_port, position)` 對每個 front port **唯一**。MPO 卡匣是 positions = 12 的後埠。
2. **Channel 是推導物件，不是欄位**：沿 `Cable` → 後埠 → 位置 → 前埠 → `Cable` 走完整條路徑，累加「固定線長、跳線長、跳線 AWG、連接點數」。`Cable` 要補 `kind`（patch／horizontal／trunk）、`awg`（跳線導體規格）、`category`；規格不明則 `UNDETERMINED`，不補預設值。
3. **規則表帶來源**：`ChannelRule(standard, category, max_total_m, max_perm_m, max_connections, derate_formula)`，每個數字用 dc-30 的 `Sourced` 包起來，24 AWG 跳線 > 10 m 這種**來源沒說**的情況回 `UNDETERMINED`，不回 `OK`。舍入規則寫進程式（floor）。
4. **對 dc-29／dc-30b 的回寫**：配線架佔 `Rack` 的 U（1U 24 口是假設值，存在 `PanelType.ports_per_u`）；`RackType.width_mm ≥ 800` 對「放交換器的機櫃」是約束；水平 `Cable.route` 的路徑長度加兩端餘量必須 ≤ `perm_max`——**線槽的實體長度終於跟長度預算接上**。
5. **告警規則**：`CHANNEL_TOO_LONG`、`CONNECTOR_COUNT_EXCEEDED`、`DIRECT_ATTACH_NOT_ADJACENT`、`ZDA_OVER_144`、`PATCH_MISMATCH`（現場 link 與資料庫對不上，靠 LLDP 比對）。

## 該問 facility 的問題

1. 本站布線依哪一套標準（TIA-568／942、ISO/IEC 11801、EN 50173）？跳線是 24 AWG 還是 28 AWG？
2. 配線架放在機櫃頂（TOR）、列尾（EOR）還是有獨立的 HDA／ZDA？ZDA 一個服務幾個機櫃？
3. 標示是否遵循 TIA-606 之類的規則，誰負責對帳，多久一次？

## 動手練習（30–40 分鐘）

新建 `channel.py`，接 dc-30b 的 `pathway.py`（`Check` 沿用，這裡為獨立執行放精簡版；水平線長度預算就是 `Cable.route` 的實體長度）。**先寫長度預算，再寫前後埠追蹤，最後用 `trace` 找出反轉面板的對端**。

```python
import math
from dataclasses import dataclass
from enum import Enum
class Check(Enum):            # 與 dc-30b 同一個
    OK="ok"; VIOLATED="violated"; NOT_APPLICABLE="not_applicable"
    INVALID="invalid"; UNDETERMINED="undetermined"

def derated_perm_max(cord_m: float, awg: int) -> float | None: ...   # 28: 102−1.95L 封頂 90，floor 到 0.01；24: ≤10 m → 90；其餘 None
def check_channel(perm_m, cord_m, awg) -> Check: ...                 # 28 AWG 跳線 >15 m → VIOLATED；None → UNDETERMINED
def check_cat8(perm_m, cord_m, connections) -> Check: ...            # 總長 ≤30 且連接點 ≤2
def check_zda(connections, zdas_in_run, has_cross_connect) -> Check: ...   # ≤144、≤1 ZDA、無 cross-connect
def check_direct_attach(row_a, idx_a, row_b, idx_b) -> Check: ...    # 同列且相鄰
@dataclass
class Panel:
    name: str
    rear: dict     # 後埠名 -> positions
    front: dict    # 前埠名 -> (後埠名, position)
    def validate(self) -> Check: ...                                 # 越界或 (rear,pos) 重複 → INVALID
    def front_at(self, rear, pos) -> str | None: ...
def trace(start_panel, start_front, trunks, panels): ...             # trunks: [((panel,rear),(panel,rear),length_m)]
                                                                     # 回 (終點面板, 終點前埠, 固定線長) 或 None
```

### 驗收表（已用參考實作跑過）

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | `check_channel(90,10,24)` | **OK** |
| 2 | `check_channel(90,6,28)`；`derated_perm_max(6,28)` | **OK**；**90.0**（90.3 封頂） |
| 3 | `check_channel(90,10,28)`；`derated_perm_max(10,28)` | **VIOLATED**；**82.5** |
| 4 | `check_channel(82.5,10,28)` | **OK** |
| 5 | `check_channel(73,15,28)` / `(72.75,15,28)` | **VIOLATED**（Fluke 的 73 超標）/ **OK** |
| 6 | `check_channel(60,12,24)` | **UNDETERMINED**（來源沒說） |
| 7 | `check_channel(70,16,28)` | **VIOLATED**（跳線 >15） |
| 8 | `check_cat8(24,6,2)` / `(24,6,3)` / `(25,6,2)` | **OK / VIOLATED / VIOLATED** |
| 9 | `check_zda(144,1,False)` / `(145,1,False)` / `(100,2,False)` / `(100,1,True)` | **OK / VIOLATED / VIOLATED / VIOLATED** |
| 10 | `check_direct_attach("A",3,"A",4)` / `("A",3,"A",5)` / `("A",3,"B",3)` | **OK / VIOLATED / VIOLATED** |
| 11 | A：`LC1..12 → MPO1 位置 1..12`；B：`LC(13−i) → MPO1 位置 i`；重複對應；越界對應 | **OK**、**OK**、**INVALID**、**INVALID** |
| 12 | A–B 與 A–C 兩條 80 m 幹線；`trace("A","LC3",…)` 走 B／走 C／無幹線；`trace("B","LC10",…)` | `("B","LC10",80.0)`／`("C","LC3",80.0)`／`None`；`("A","LC3",80.0)` |

第 5 列同一個 73 m，**四捨五入看是 OK、floor 看是違規**；第 12 列同一條幹線，終點是 LC10 還是 LC3 取決於面板的對應表——**沒有把對應存成資料就沒有答案**。

**加分題**：(a) 把 dc-30b 的 `Cable.route` 接進來：`perm_m = sum(pathway.length_m) + 兩端餘量`，超過 `derated_perm_max` 時吐 `CHANNEL_TOO_LONG`；(b) 讓 `Panel` 帶 `ports_per_u`，呼叫 dc-29 的 `Rack.mount`，並在機櫃寬 < 800 mm 且機櫃裝了交換器時吐 `RACK_TOO_NARROW`。

## 自我檢核

**Q1. 跳線是 28 AWG、兩端合計 12 m，固定線最長多少？**

??? note "答案"
    102 − 1.95 × 12 = 102 − 23.4 = 78.6 m（低於 90 的封頂）。channel 總長 90.6 m。若要在 12 m 跳線下用到 90 m 固定線，就得改用 24 AWG——但 24 AWG 超過 10 m 時本卡來源沒給數字，應回 `UNDETERMINED` 去查原文，而不是照 90 m 放行。

**Q2. 為什麼 A 面板的 LC3 追到 B 面板是 LC10？資料庫要存什麼才能追得到？**

??? note "答案"
    因為 B 面板的前埠到後埠位置的對應是反轉的（`LC(13−i) → 位置 i`），位置 3 的前埠是 LC10。要存的是每個面板的 `FrontPort.rear_port` 與 `rear_port_position`，並驗證 `(rear_port, position)` 唯一且在 [1, positions] 內；追蹤時依「後埠＋位置」換面板的前埠，不是依「名稱相同」。

**Q3. 這張卡會讓你的資料模型長出什麼欄位？**

??? note "答案"
    (1) `Cable.kind / awg / category`，`Panel` 的 `RearPort.positions` 與 `FrontPort.rear_port_position`（唯一約束）；(2) `ChannelRule(standard, category, max_total_m, max_perm_m, max_connections, derate_formula)`，數字用 `Sourced`，來源沒說回 `UNDETERMINED`，降額後固定線往下取整；(3) `PanelType.ports_per_u` 與 `RackType.width_mm ≥ 800` 的約束；(4) `CHANNEL_TOO_LONG`、`CONNECTOR_COUNT_EXCEEDED`、`DIRECT_ATTACH_NOT_ADJACENT`、`ZDA_OVER_144`、`PATCH_MISMATCH` 五種告警。

## 相關卡片

[線槽走線架](cable-tray-and-pathway.md)｜[高架地板](raised-floor.md)｜[機櫃與 U 位](rack-and-rack-unit.md)｜[空間層級](space-hierarchy.md)｜下一張：`dc-32` 極早期偵煙 VESDA
