---
id: dc-43
title: SNMP 與 MIB（UPS-MIB、rack PDU 的 OID、scale、counter 與 trap）
category: systems
written_at: 2026-10-20
sources:
  - https://www.rfc-editor.org/rfc/rfc1628.html
  - https://www.rfc-editor.org/errata/rfc1628
  - https://mibs.observium.org/mib/UPS-MIB
  - https://apc.com/nl/en/faqs/FA156179
  - https://cdn1.raritan.com/download/pdu-g4/4.4.0/MIB_Usage_4.4.0_52884.pdf
  - https://www.netdata.cloud/guides/network/network-snmp-counter-discontinuity/
  - https://en.wikipedia.org/wiki/Simple_Network_Management_Protocol
  - https://net-snmp.sourceforge.io/docs/man/snmpbulkwalk.html
related: [dc-11, dc-14, dc-38, dc-40, dc-41, dc-42, dc-44, dc-45]
---

# SNMP 與 MIB

[Modbus](modbus-rtu-tcp.md) 只傳位元組，[BACnet](bacnet-object-model.md) 把語意塞在設備裡。SNMP 介於兩者之間：**語意寫在一份獨立的 MIB 文件裡**，設備只回 OID 與型別化的值。[UPS](ups-double-conversion.md)、[rack PDU](rack-pdu.md)、網路設備幾乎都講 SNMP，所以它是 DCIM collector 第一個要接的協定。難處不在協定，在 **MIB 是一份有版本、會出錯、廠商各自延伸的文件**。

## 六格

### 拓撲位置
上游：UPS 網卡（NMC）、rack PDU 控制器、交換器。下游：DCIM／NMS collector、trap receiver。觀察層傳輸邊；同一台 UPS 常同時有 SNMP（給 IT）與 Modbus／BACnet（給 [BMS](bms-building-management-system.md)）。

### 容量單位
每次請求的 varbind 數、往返次數（RTT）、逾時成本。agent 必須接受至少 **484 位元組**的訊息（RFC 1157，實務上更大）。

### 冗餘表達
協定層沒有。可設多個 trap 目的地；UPS 本體冗餘與 NMC 冗餘無關——NMC 重開機時 UPS 照常供電但**看不見**。

### 遙測介面

| 物件 | OID | 型別／單位 |
|---|---|---|
| `upsBatteryStatus` | 1.3.6.1.2.1.33.1.2.1 | unknown(1)／batteryNormal(2)／batteryLow(3)／batteryDepleted(4) |
| `upsSecondsOnBattery` | …33.1.2.2 | 秒；不在電池上回 0 |
| `upsEstimatedMinutesRemaining` | …33.1.2.3 | 分鐘 |
| `upsInputFrequency` | …33.1.3.3.1.2.*i* | **0.1 Hz** |
| `upsOutputSource` | …33.1.4.1 | other(1)／none(2)／normal(3)／bypass(4)／battery(5)／booster(6)／reducer(7) |
| `upsOutputCurrent`／`Power`／`PercentLoad` | …33.1.4.4.1.3／.4／.5 | **0.1 A**／W／% |
| `upsAlarmsPresent` | …33.1.6.1 | Gauge32，現存告警數 |
| `rPDU2BankStatusCurrent` | 1.3.6.1.4.1.318.1.1.26.8.3.1.5 | **0.1 A**（APC） |
| `rPDU2DeviceStatusPower` | …318.1.1.26.4.3.1.5 | **0.01 kW** |
| `rPDU2DeviceStatusEnergy` | …318.1.1.26.4.3.1.9 | **0.1 kWh，使用者可歸零** |
| `measurementsInletSensorValue` | 1.3.6.1.4.1.13742.6.5.2.3.1.4.*pdu.inlet.type* | 整數，除以 10^`DecimalDigits`（Raritan） |

1.3.6.1.2.1 是標準 MIB-2（UPS-MIB 在 .33）；1.3.6.1.4.1 是 enterprises（318 = APC、13742 = Raritan）。UDP 161 收請求、162 收 trap／inform。

### 故障域
單台 agent（NMC 當機＝那台 UPS 全盲）；community／v3 帳號錯誤則是**一整批同設定的設備**同時消失；trap receiver 掛掉則所有設備的主動通知全失，而輪詢照常——儀表板看起來正常。

### 維護特性
NMC 韌體升級會改 MIB（廠商要求 MIB 檔不得比韌體舊，Raritan）；換 NMC 要重設 v3 帳號、trap 目的地。

## 來源分歧

1. **`upsOutputSource` 的值**：RFC 1628 的 SYNTAX 是 normal(3)、battery(5)；同一份 RFC 的三個 MODULE-COMPLIANCE 卻寫 normal(2)、battery(4)。RFC Errata **4831**（2016 驗證）裁定 SYNTAX 正確。observium 的 MIB 瀏覽器照抄了錯的 compliance 文字，頁面上 bypass 與 battery 同為 4。**照錯表寫對照，「旁路」會被顯示成「電池」。**本卡採 SYNTAX。
2. **SNMPv3 加密演算法**：Wikipedia 只列 CBC-DES 與 CFB-AES-128（標準 USM）；Raritan 支援 AES-192／AES-256 與 SHA-224～512。前兩者不在標準 USM 裡，**跨廠商 collector 不一定支援**，要逐台確認。
3. **單一來源數字**：1 Gbps 介面 Counter32 約 34 s 繞回（netdata，本卡計算吻合）；Net-SNMP 預設逾時與重試次數**未查證**，下文的 1 s／5 次是假設。

## 關鍵數字與計算

**一、scale 是每個物件的事實，不是協定的。**同一個「電流」：

- UPS-MIB `upsOutputCurrent` = 523 → ×0.1 = **52.3 A**；`upsInputFrequency` = 600 → **60.0 Hz**。
- APC `rPDU2DeviceStatusPower` = 345 → ×0.01 = **3.45 kW**；`Energy` = 12345 → **1234.5 kWh**。
- Raritan `rmsCurrent` = 1424、`DecimalDigits` = 3 → **1.424 A**；`rmsVoltage` = 397、digits 0 → **397 V**（三相線電壓的例子；台灣常見等級以實際設備為準）。

三種慣例：固定寫在 MIB 文字裡（UPS-MIB、APC）、**由設備另一個 OID 動態告知**（Raritan）。後者表示 scale 也是要被輪詢、會變的點位。

**二、counter 的差值有四種結果。**

- Counter32 前值 4,294,967,000、本值 200，`sysUpTime` 上升 → 繞回，差值 = 200 + 2³² − 4,294,967,000 = **496**。
- `sysUpTime` 下降（重開機）→ 差值**丟棄**，重新取基準；要分辨繞回與重開機就看它。
- APC 能量 12345 → 12391：**4.6 kWh**。之後讀到 3：不是繞回而是**被人歸零**，差值丟棄。
- 繞回時間 = 2³² ÷ 速率。1 Gbps（1.25×10⁸ B/s）= **34.4 s**；10 Gbps **3.4 s**——5 分鐘輪詢會跨好幾圈，要用 Counter64。反過來，8 kW 機櫃若以 Wh 為單位的 Counter32 計能，繞回要 **61 年**：電力計量的風險是**歸零與重開機**，不是繞回。

**三、走表的往返次數。**24 孔 PDU、每孔 5 個欄位 = 120 個 varbind。GetNext 每次一個，需 121 次（最後一次確認走出子樹）；GetBulk `max-repetitions`=10（Net-SNMP 預設）約 ⌈121/10⌉ = **13** 次，=25 則 **5** 次。RTT 4 ms：**484 ms／52 ms／20 ms**。300 台串行輪詢：**145.2 s／15.6 s／6.0 s**——60 s 週期下 GetNext 根本跑不完。SNMPv1 沒有 GetBulk。

**四、死設備比慢設備貴。**逾時 1 s、重試 5 次（假設）→ 每台死設備每次請求 **6 s**。300 台裡 10 台離線 = 串行多 **60 s**。所以 collector 必須並行，且逾時本身是設定資料。

**五、trap 與輪詢的偵測延遲。**`upsTrapOnBattery` 是持續性 trap，在電池上**每分鐘重送**；RFC 另要求同一通知對同一接收者不超過每 5 s 一次。UDP 遺失率假設 1%：第一封漏掉 **1%**，加上第一次重送仍漏 **0.01%**。只靠輪詢時，最壞延遲 = 輪詢週期。`upsEstimatedMinutesRemaining` = 8 分鐘：60 s 輪詢吃掉 **12.5%** 的續航預算，300 s 吃掉 **62.5%**，15 s 為 3.1%。

## 常見誤解

**以為 OID 就是點位的完整定義，但實際上 OID 只是位址，scale、單位、enum 對照都在 MIB 文字或另一個 OID 裡**：同樣是「電流」，UPS-MIB 是 0.1 A、APC 是 0.1 A、Raritan 要先讀 `DecimalDigits`。少了這層，數值差 10 倍或 1000 倍而且**不報錯**。

**以為標準 MIB 文字一定對，但實際上 RFC 1628 自己的 compliance 段把 battery 寫成 4**：要對照 errata，並記下自己用的是哪一版、哪個來源。這跟 [dc-41](modbus-rtu-tcp.md) 的「暫存器表是有版本的實體」同一件事。

**以為設定了 trap 就有告警，但實際上 trap 走 UDP 不保證送達、沒有確認，receiver 掛了也沒人知道**：要嘛用 inform、要嘛輪詢補位、要嘛定期做 trap 實測。「設定了」不等於「驗證過」（[dc-40](dcim-scope-and-market.md)）。

## 對資料模型的意涵

1. **MIB 是有版本的實體，跟 `RegisterMap` 平行。**`MibModule{name, revision, source, errata_applied}`、`MibObject{module, oid, syntax, units, scale | scale_oid, enum_map, resettable}`。`Point.native_ref` 存數字 OID 加 instance（`1.3.6.1.2.1.33.1.4.4.1.3.1`），不存名字。新告警 `MIB_REVISION_UNDECLARED`。
2. **counter 的差值是三態結果，不是減法。**`counter_delta()` 回 `OK`／`WRAP`／`DISCONTINUITY(REBOOT|RESET)`；DISCONTINUITY 的區間在能量帳本裡標為缺口，不補零。這要求每台 agent 一起存 `sysUpTime`（或 `snmpEngineTime`），作為 `Point` 以外的 `AgentState{asset_id, uptime_ticks, ts_s}`。
3. **認證方式是資產的屬性，帶告警。**`SnmpAgent{asset_id, version, sec_level, auth_proto, priv_proto, trap_targets[], timeout_s, retries}`。`SNMP_CLEARTEXT_AUTH`（v1／v2c 或 noAuthNoPriv）、`SNMP_V1_NO_BULK`（表大卻只能 GetNext）。`timeout_s`／`retries` 是 `Sourced(evidence="assumed")` 直到量過（W42 🟡5）。
4. **第十三個「缺東西」：`UPS_NO_NOTIFICATION_PATH`。**一台 UPS 必須有一條有效的「轉電池」觀察路徑：輪詢點 `live` 且 `interval_s` ≤ 允許延遲，或 trap 路徑在 N 天內實測過。這是第一個用通用 `Coverage`＋`effective()` 寫的告警，兩種 `kind` 對同一個 target。
5. **enum 對照是資料。**`upsOutputSource` 4 = bypass、5 = battery；顯示層一律查 `MibObject.enum_map`，不寫死在程式。

## 該問 facility 的問題

1. UPS／PDU 的 NMC 跑哪版韌體？用的 MIB 檔從哪裡來、什麼版本？
2. SNMP 是 v2c 還是 v3？community／帳號誰管？trap 送到哪幾台，上次實測是何時？
3. PDU 能量計數器有沒有被人歸零過？帳單或 PUE 用的是哪個值？

## 動手練習（40 分鐘）

**第 0 步（20 分鐘，W42 🔴1）**：`coverage.py`。四個舊覆蓋查詢收斂成一個。

```python
@dataclass(frozen=True)
class Coverage: observer_id: str; target_id: str; kind: str
EFFECTIVE: dict[str, Callable[..., Result]  # (Coverage, state, now_s)] = {}
def kind(name): ...                       # decorator：註冊 EFFECTIVE[name]
def effective(c, state, now_s) -> Result  # 查表分派
def uncovered(targets, covs, state, now_s) -> list[(target_id, Result)]
#   任一 OK → 跳過；否則有 UNDETERMINED 回它，否則 VIOLATED，detail 串起各路徑原因；沒有路徑 → "no observer"
```

把 dc-37 的 `uncovered(racks, sensors…)` 改寫成 `kind("inlet_sensor")`＋十行以內 wrapper，原驗收表跑過即可（dc-38／39／41 留到週報）。

**第 1 步（20 分鐘）**：`snmp.py`。

```python
UPS_SOURCE = {1:"other",2:"none",3:"normal",4:"bypass",5:"battery",6:"booster",7:"reducer"}
def decode(raw, scale=None, digits=None)   # 恰好給一個，否則 raise
def counter_delta(prev, cur, bits=32, up_prev=None, up_cur=None, resettable=False) -> (delta|None, code)
def wrap_s(rate_per_s, bits=32); def trips_next(n); def trips_bulk(n, m)   # ceil((n+1)/m)
def dead_cost_s(timeout_s, retries); def lag_fraction(poll_s, runtime_min); def miss_prob(p, k)  # p**(k+1)
@kind("snmp_poll")  # live(point) 且 interval_s <= state["max_lag_s"]
@kind("snmp_trap")  # state["trap_tested_ts_s"] 無值→UNDETERMINED(MISSING_INPUT)；超過 max_age→VIOLATED
def check_snmp(agents) -> list[(code, name)]
```

測試資料：`now=10000`，`max_lag_s=60`，`trap_test_max_age_s=90*86400`。pA：interval 30、last_good 9990、GOOD；pB：interval 300、last_good 9800；pE：同 pA 但 BAD。tC 實測於 10 天前、tD 沒測過、tF 200 天前。覆蓋：A←pA、B←pB、C←tC、D←tD、E←pE、F←tF＋pB、G 無。

### 驗收表

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | `decode(523,scale=.1)`；`decode(345,scale=.01)`；`decode(1424,digits=3)`；`decode(1,scale=.1,digits=1)` | **52.3**；**3.45**；**1.424**；raise |
| 2 | `counter_delta(4294967000,200,32,1000,7000)` | **(496, WRAP)** |
| 3 | `counter_delta(500,100,32,90000,1200)` | **(None, REBOOT)** |
| 4 | `counter_delta(12345,12391,resettable=True)`；`(12391,3,resettable=True)` | **(46, OK)**；**(None, RESET)** |
| 5 | `wrap_s(1.25e8)`；`wrap_s(1.25e9)`；`wrap_s(8000/3600)/86400/365` | **34.4**；**3.44**；**61.3** |
| 6 | `trips_next(120)`；`trips_bulk(120,10)`；`trips_bulk(120,25)` | **121**；**13**；**5** |
| 7 | 上列 ×4 ms×300 台（秒） | **145.2**；**15.6**；**6.0** |
| 8 | `dead_cost_s(1,5)`；×10 台 | **6**；**60** |
| 9 | `lag_fraction(60,8)`；`(300,8)`；`miss_prob(.01,1)` | **0.125**；**0.625**；**0.0001** |
| 10 | `UPS_SOURCE[4]`、`UPS_SOURCE[5]` | **bypass**、**battery** |
| 11 | `uncovered(A…G)` | B VIOLATED（interval 300>60）；D UNDETERMINED(MISSING_INPUT)；E VIOLATED（not live）；F VIOLATED（兩條都失效）；G VIOLATED（no observer）；A、C 不出現 |
| 12 | `check_snmp`：PDU-1 v2c；UPS-1 v3 authPriv 無 mib_rev；PDU-2 v1、120 列；UPS-2 v3 noAuthNoPriv | CLEARTEXT PDU-1；MIB_REVISION_UNDECLARED UPS-1；CLEARTEXT＋V1_NO_BULK PDU-2；CLEARTEXT UPS-2 |

**加分**：`pip install pysnmp`，用 `snmpsim` 或本機 snmpd 起一個 agent，對 1.3.6.1.2.1.1 做 bulkwalk，把真實往返次數與 `trips_bulk` 對照。

## 自我檢核

**Q1. 一台 PDU 的能量值從 98,000 跳到 12。你的模型要多存什麼，才能分辨「繞回」「重開機」「有人歸零」？這會讓資料模型長出什麼欄位？**

??? note "答案"
    `AgentState.uptime_ticks`（看重開機）、`MibObject.syntax`（Counter32／64 才可能繞回）、`MibObject.resettable`（廠商文字說可歸零）。差值結果存成三態 `OK／WRAP／DISCONTINUITY(reason)`，能量帳本把該區間標為缺口。

**Q2. 監控說某 UPS `upsOutputSource` = 4，值班員以為在電池上。誰對？**

??? note "答案"
    依 RFC 1628 SYNTAX 與 Errata 4831，4 = **bypass**，battery 是 5。誤會來自照抄 compliance 段或錯的 MIB 瀏覽頁。enum 對照要存成有出處的 `MibObject.enum_map`。

**Q3. 某 UPS 設了 trap 但從未實測，輪詢 300 s 一次，續航估 8 分鐘。`UPS_NO_NOTIFICATION_PATH` 應判什麼？**

??? note "答案"
    輪詢路徑 VIOLATED（300 > 允許延遲，且吃掉 62.5% 續航），trap 路徑 UNDETERMINED(MISSING_INPUT)，整體回 **UNDETERMINED**——不是 OK。處置：做一次 trap 實測或把輪詢縮到 ≤ 60 s。

**未查證**：RFC 3416／3414 原文、Counter64 與 HC 計數器在 PDU MIB 的使用、APC `Energy` 物件的 SMI 型別、Net-SNMP 預設逾時與重試、各廠商 trap 重送行為、台灣法規與 CNS。

**下一張**：`dc-44` Redfish / IPMI 伺服器帶外管理
