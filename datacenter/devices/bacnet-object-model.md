---
id: dc-42
title: BACnet 物件模型與 MS/TP vs IP（物件、優先序陣列、token 時間預算）
category: systems
written_at: 2026-10-19
sources:
  - https://docs.chipkin.com/protocols/bacnet/mstp/
  - https://store.chipkin.com/articles/bacnet-mstp-bandwidth-usage-how-many-devices-on-a-network
  - https://store.chipkin.com/articles/bacnet-what-is-a-bacnet-priority-array
  - https://docs.chipkin.com/protocols/bacnet/objects/binary-value/
  - https://docs.chipkin.com/articles/bacnet-discovery-network-architecture-reference/
  - https://csimn.com/MHelp-BB3-3101/bb3-3101-appendix-E.html
  - https://en.wikipedia.org/wiki/BACnet
related: [dc-37, dc-38, dc-39, dc-41, dc-43, dc-45]
---

# BACnet 物件模型與 MS/TP vs IP

[dc-41](modbus-rtu-tcp.md) 的 Modbus 只傳位元組，意義在表外。BACnet 反過來：**設備自己描述自己**——一台 Device 底下有一串物件，各有型別與有名字的屬性（[BMS](bms-building-management-system.md) 的 AI／AO／BI／BO）。難處在**語意**：同一個「數值」可能是量測、狀態，或被多方爭奪的命令。

## 六格

### 拓撲位置
上游：[CRAH](crah-chilled-water.md)、[冰水機](chiller.md)、VAV、DDC。下游：BMS 監督控制器、DCIM collector。觀察層傳輸邊，不在電力樹上。鏈路層有 MS/TP（RS-485 token passing）與 BACnet/IP（UDP）；兩者間靠路由器／閘道（`dc-45`）。

### 容量單位
物件數與**總線時間**（MS/TP，毫秒）。BACnet/IP 的瓶頸通常是**廣播可達範圍**而非頻寬。

### 冗餘表達
協定層無冗餘（來源未提）；多寫入者共存靠 16 級優先序陣列（計算二）。

### 遙測介面

| 物件型別 | 代碼 | 本卡 `role` |
|---|---|---|
| Analog Input / Value | 0 / 2 | measure（AV 若可命令則 command） |
| Binary Input / Value | 3 / 5 | status（BV 若可命令則 command） |
| Multi-state Input / Value | 13 / 19 | status（同上） |
| Analog / Binary / Multi-state Output | 1 / 4 / 14 | command |

共有屬性：`Object_Identifier`、`Present_Value`、`Status_Flags`（4 位元：in-alarm、fault、overridden、out-of-service）、`Event_State`、`Reliability`、`Out_Of_Service`；類比另有 `Units`、`COV_Increment`；**只有可命令物件**有 `Priority_Array`、`Relinquish_Default`。

### 故障域
MS/TP：整條 trunk（重複 MAC、極性、終端、鮑率不符）。BACnet/IP：子網路邊界——Who-Is 是 UDP 47808 廣播，無 BBMD 的子網路對監督者**隱形**。

### 維護特性
換控制器要保住 Device instance 與 MAC；覆寫（優先序 8）是常態，**忘記放開**是主要風險。

## 來源分歧

1. **`Event_State` 的值**：Chipkin 列 normal／off-normal／fault；csimn 某產品文件只列 normal(0)／fault(1)（產品子集）。未裁決，模型不得假設只有兩態。
2. **Device instance 上限**：Chipkin 寫「22 位元，0 至 4,194,302」；欄位本身最大是 2²²−1 = 4,194,303，差的一號來源沒解釋（推測是保留值，**未查證**）。卡片用 Chipkin 上界並做成參數。
3. **標準版本**：Wikipedia 說 135-2016 有 60 種物件型別、135-2020 有 62 種，同頁表格卻列 135-2024。型別集合是**標準版本的函數**，csimn 代碼表只是子集。
4. **來源獨立性**：Chipkin 五頁是同一家廠商，**只算一個來源**；其餘皆非規範，**ASHRAE 135 原文未讀到**。單一來源數字：token hold 上限 15 ms、開銷「常約 50%」、單次讀取約 30／40 位元組、token 框約 8 位元組。
5. **物件識別碼 10＋22 位元**：來源只確認 22 位元 instance；10 位元型別欄位未印出，驗收 #1 依通行配置，請核對。

## 關鍵數字與計算

**一、MS/TP 總線時間（下限）。**鮑率 9600–115200，同 trunk 必須一致（Chipkin）。每位元組約 10 位元（8N1），故 `bytes/s ≈ baud/10`。單次 ReadProperty：請求約 30＋回應約 40 = 70 位元組；token 框約 8 位元組。9600 baud：

- RP = 70×10/9600 = **72.92 ms**；token 一次 = 80/9600 = **8.33 ms**。
- 監督者要讀 100 個屬性（一個一次 RP），trunk 上共 11 個 master，每次 token 只送 1 框（`Max_Info_Frames`=1）：100 輪 × 11 次 token × 8.33 = **9167 ms** 的 token 開銷，加 100 × 72.92 = **7292 ms** 的讀取，合計 **16.46 s**。
- 每次到手可送 4 框：25 輪 → 2292 + 7292 = **9.58 s**。10 框：**8.21 s**。
- 38400 baud、每次 1 框：2292 + 1823 = **4.11 s**。
- 在 60 s 內 9600／1 框最多讀 **364** 個屬性；要 5 s 內讀完，只剩 **30** 個。
- master 從 11 增為 32（9600、1 框）：總時間 **33.96 s**。

這是**下限**：假設只有一個 master 有待送訊框，不含 poll-for-master、回應延遲、重送；`Max_Info_Frames` 是設備相依。改善：ReadPropertyMultiple、COV 訂閱、降輪詢頻率、`Max_Master` 設為實際最高 MAC。

**二、優先序陣列。**可命令物件有 16 格，索引小者優先；**有效值 = 最小索引的非 NULL 格，全空則回 `Relinquish_Default`**。具名者：1 manual-life safety、2 automatic-life safety、5 critical equipment control、6 minimum on/off、8 manual operator（Chipkin）。例：CRAH 冰水閥 AO，`Relinquish_Default`=0 %。BMS 排程寫 16 級=40 %，某腳本寫 10 級=60 %，值班員手動寫 8 級=100 %：

- 有效值 = **100 %（優先序 8）**。BMS 之後再寫 16 級 = 40 %，依標準語意成功但**有效值不變**。
- 放開 8 → **60 %（10）**；再放開 10 → **40 %（16）**；再放開 16 → **0 %（default）**，閥全關。

沒人命令時設備退到 `Relinquish_Default`，它是設計時決定的安全位置，要登錄。

**三、BACnet/IP 可達性。**Who-Is 是子網路廣播；BBMD 把廣播轉給其廣播分配表（BDT）的每一筆；外來設備註冊讓不在 BBMD 子網路的設備也收得到轉發。3 個子網路、BBMD 只裝在 2 個：沒有的那個，I-Am 到不了監督者。Device instance 在同網際網路內不可重複（Chipkin）。

## 常見誤解

**以為 AI／AO／AV 是接線端子的類型，但實際上它們是物件抽象，能不能被命令取決於實例有沒有 `Priority_Array`**：AV 可以是軟體算出的值，BV 可以是可命令的開關；`role` 要由「型別＋有無優先序陣列」推導。

**以為讀到 `Present_Value` 就是現場量測，但實際上 `Out_Of_Service` 為真時它與物理脫鉤，輸入物件的值甚至可被人寫入**：有人把風溫鎖在 22.0 °C 後忘了放開，值新鮮、不報錯。要同時看 `Status_Flags` 與 `Reliability`。

**以為 WriteProperty 回成功就代表閥門到了那個位置，但實際上只有最高優先序的非 NULL 格生效**：排程寫 16 級，被留在 8 級的覆寫蓋住，寫入成功、有效值不動。「命令」是一疊有主人的堆疊。

## 對資料模型的意涵

1. **`role` 是實例屬性，不是型別屬性。**`role_of(type, has_priority_array)`：AO／BO／MO 恆為 command；AV／BV／MV 有陣列才是 command，否則 AV→measure、BV／MV→status。`Point.native_ref` 存 `"type,instance"`，型別集合要記 `standard_revision`（來源分歧 3）。
2. **品質由 `Status_Flags`／`Reliability` 推導，餵給 `live()`。**fault、out-of-service、`Reliability` 異常→BAD；overridden→SUSPECT；in-alarm 是值的條件、非資料品質→GOOD（設計選擇）。如此 dc-37 的 `RACK_INLET_UNCOVERED` 不會被「被鎖定的感測器」放行（W42 🔴2）。
3. **命令是 `CommandSlot{point, priority, value, writer, written_ts_s}` 的集合，不是 `Point.value`。**有效值是查詢結果。新告警：`COMMAND_OVERRIDE_STALE`（優先序 ≤ 8 超過 N 小時未放開）、`RELINQUISH_DEFAULT_UNDECLARED`。
4. **Trunk 與 Subnet 是資源，帶約束。**`MstpTrunk{baud, masters[], max_master}`：`max_master` ≥ 最高 master MAC（太低→設備永不出現，太高→浪費 poll-for-master）；`mac` 在 trunk 內唯一；`cycle_ms` 派生，`Point.interval_s` 有效值 = `max(設定, cycle_ms)`（同 [dc-41](modbus-rtu-tcp.md)）。`Device.instance` 全網際網路唯一。
5. **第十二個「缺東西」：`SUBNET_NO_BBMD`**——有設備的子網路，既不在監督者的可達集合內、自己也沒有 BBMD。配對 `BDT_MISSING_ENTRY`（有 BBMD 卻不在轉發表）、`MAX_MASTER_TOO_LOW`、`DUPLICATE_MAC`、`DEVICE_INSTANCE_DUPLICATE`。

## 該問 facility 的問題

1. 每條 MS/TP trunk 掛幾台 master？`Max_Master` 與鮑率多少？量過實際輪詢週期嗎？
2. 哪些物件的優先序 ≤ 8 還有值？誰、何時寫的？可命令物件的 `Relinquish_Default` 各是多少？
3. BACnet/IP 設備分布在幾個子網路？BBMD 在哪、BDT 誰維護？

## 動手練習（40 分鐘）

**第 0 步（15 分鐘，W42 週報交辦）**：先收斂 `core.py`／`points.py`。

```python
# core.py 只增補，不重寫：不確定只剩一態，原因放 reason
class Reason(Enum): MISSING_INPUT; UNSOURCED; PRECISION_INSUFFICIENT; ORDER_AMBIGUOUS
@dataclass Result: check: Check; reason: Reason | None = None; detail: str = ""
# points.py：全軌跡唯一的 Point（Equip 一律改名 Asset，外鍵只叫 asset_id）
class Role(Enum): MEASURE; STATUS; COMMAND
class Quality(Enum): GOOD; SUSPECT; BAD          # 原 UNCERTAIN 改 SUSPECT
@dataclass Point: id, asset_id, role, protocol, native_ref, interval_s,
                  last_attempt_ts_s, last_good_ts_s, quality, time_basis="poll", clock_id=None
def live(p, now_s, k=2):   # GOOD 且 last_good 非空且 now-last_good <= k*interval；不看 last_attempt
```

**第 1 步（25 分鐘）**：`bacnet.py`；`Finding(code, subject)` 有現成的就換掉。

```python
TYPES = {0:"AI",1:"AO",2:"AV",3:"BI",4:"BO",5:"BV",13:"MI",14:"MO",19:"MV"}
def oid(t, inst) -> int; def split_oid(v) -> (t, inst)     # (t<<22)|inst
def role_of(t, has_pa) -> Role
def effective(pa, rd) -> (value, priority|None)   # pa: 16 格 list，索引0=優先序1
def release(pa, prio) -> list; def manual_overrides(pa, upto=8) -> [(prio, value)]
def quality_of(flags, reliability_ok=True) -> Quality   # flags=(in_alarm, fault, overridden, oos)
def rp_ms(baud, req=30, resp=40); def token_ms(baud, frame=8)
def poll_ms(baud, masters, n_reads, frames_per_token=1)  # ceil(n/F)*masters*token + n*rp
def max_reads(baud, masters, frames, interval_ms)
def check_mstp(devs, maxm)       # devs=[(name, mac, is_master)]；maxm={master: Max_Master}
def check_instances(devs, hi=4194302)
def check_subnets(subnets, sup, bbmds, bdt, fd_at=None)
# reach = {sup} ∪ (bdt[sup] 若 sup 有 BBMD) ∪ {fd_at 若有 BBMD}；不在 reach 且有設備→告警
```

測試資料：`pa=[None]*16; pa[15]=40; pa[9]=60; pa[7]=100`；`devs = [("DDC-1",0,T),("DDC-2",1,T),("DDC-3",1,T),("VAV-9",130,F),("DDC-4",9,T)]`、`maxm = {"DDC-1":127,"DDC-2":9,"DDC-3":5,"DDC-4":9}`；`subnets = {"10.1.0.0/24":["a"],"10.2.0.0/24":["b"],"10.3.0.0/24":["c"],"10.4.0.0/24":[]}`，`sup="10.1.0.0/24"`，`bbmds={"10.1.0.0/24","10.2.0.0/24"}`。

### 驗收表

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | `oid(0,1)`；`oid(8,1234)`；`split_oid(33555666)` | **1**；**33555666**；**(8,1234)** |
| 2 | `role_of(0,F)`、`role_of(1,T)`、`role_of(5,T)`、`role_of(5,F)`、`role_of(2,F)` | measure／command／command／status／measure |
| 3 | `effective(pa, 0)` | **(100, 8)** |
| 4 | 依序 `release` 8、10、16 後各取 `effective`；`manual_overrides(pa)` | **(60,10)**、**(40,16)**、**(0,None)**；**[(8,100)]** |
| 5 | `quality_of` 輸入 (0,0,0,0)／(1,0,0,0)／(0,0,1,0)／(0,0,0,1)／(0,1,0,0) | GOOD／GOOD／SUSPECT／BAD／BAD |
| 6 | `rp_ms(9600)`；`token_ms(9600)`；`rp_ms(38400)` | **72.917**；**8.333**；**18.229** |
| 7 | `poll_ms(9600,11,100,1)`；`(9600,11,100,4)`；`(9600,11,100,10)` | **16458.3**；**9583.3**；**8208.3** |
| 8 | `poll_ms(38400,11,100,1)`；`poll_ms(9600,32,100,1)` | **4114.6**；**33958.3** |
| 9 | `max_reads(9600,11,1,60000)`；`(9600,11,1,5000)` | **364**；**30** |
| 10 | `check_mstp(devs, maxm)` | DUPLICATE_MAC `DDC-2=DDC-3`；MAX_MASTER_LOOSE `DDC-1`；MAX_MASTER_TOO_LOW `DDC-3` |
| 11 | `check_instances([("A",1001),("B",1002),("C",1001),("D",4194303),("E",4194302)])` | DEVICE_INSTANCE_DUPLICATE `A=C`；INSTANCE_OUT_OF_RANGE `D` |
| 12 | `check_subnets(…, bdt={"10.1.0.0/24":set()})` | BDT_MISSING_ENTRY `10.2.0.0/24`；SUBNET_NO_BBMD `10.3.0.0/24` |
| 13 | 同上但 `bdt={"10.1.0.0/24":{"10.2.0.0/24"}}` | 只剩 SUBNET_NO_BBMD `10.3.0.0/24` |
| 14 | `live(Point(…interval 60, last_good 100, GOOD), 220)`；`now=221`；`last_attempt=300` 但 `last_good=100`、`now=220` | **True**；**False**；**True**（只看 last_good） |

## 自我檢核

**Q1. 某 BV 物件被 BMS 週期性寫入，另有一個維運人員寫過同一物件。你的模型要多存什麼才能回答「現在是誰在控制它」？這會讓資料模型長出什麼欄位？**

??? note "答案"
    `CommandSlot{point_id, priority(1–16), value, writer, written_ts_s}` 以及 `Point.relinquish_default`。有效值是查詢結果，不存成 `Point.value`；`COMMAND_OVERRIDE_STALE` 由 `priority ≤ 8` 與 `written_ts_s` 推導。

**Q2. 9600 baud、11 個 master、`Max_Info_Frames`=1，監督者要在 5 秒內讀完 40 個屬性（單次 RP），可以嗎？**

??? note "答案"
    40×(91.67 + 72.92) = **6583 ms > 5000**，不行；上限是 30 個。換 38400 baud：40×(22.92+18.23) = **1646 ms**，可以。這是下限；改 RPM 或 COV 也是選項。

**Q3. 一台新 DDC 接上 trunk 後從未出現在 Who-Is 結果。列出你會在資料模型裡查的三件事。**

??? note "答案"
    (1) MAC 是否超過任一 master 的 `Max_Master`（`MAX_MASTER_TOO_LOW`）；(2) MAC 是否重複（`DUPLICATE_MAC`）、鮑率是否一致；(3) 若是 IP 設備，子網路是否在監督者可達集合內（`SUBNET_NO_BBMD`／`BDT_MISSING_ENTRY`）。

**未查證**：ASHRAE 135 原文、台灣法規與 CNS、MS/TP 線長與每段節點數、poll-for-master 時序、`Max_Info_Frames` 預設值、BDT 機制細節、foreign device TTL、COV 存活時間。

**下一張**：`dc-43` SNMP 與 MIB（練習第 0 步：`Coverage`＋`effective()`）
