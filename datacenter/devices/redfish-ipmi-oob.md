---
id: dc-44
title: Redfish / IPMI 伺服器帶外管理（BMC、SDR 換算、DCMI 功率、schema 遷移）
category: systems
written_at: 2026-10-21
sources:
  - https://www.dmtf.org/sites/default/files/Redfish_Release_2020.4_Overview.pdf
  - https://redfish.dmtf.org/schemas/v1/Power.json
  - https://redfish.dmtf.org/schemas/v1/Sensor.v1_12_0.json
  - https://redfish.dmtf.org/schemas/v1/EnvironmentMetrics.v1_2_1.json
  - https://grok.openbmc.org/xref/openbmc/bmcweb/Redfish.md?r=daadfb2e
  - https://lists.ozlabs.org/pipermail/openbmc/2019-March/015405.html
  - https://www.openubmc.cn/docs/en/development/specifications/ipmi/details/PICMG-2Ch/02h-get-power-reading
  - https://thehackernews.com/2026/07/24650-internet-exposed-bmcs-disclose.html
  - https://pubs.lenovo.com/xcc-restapi/sse_subscription
related: [dc-14, dc-16, dc-37, dc-40, dc-43, dc-45]
---

# Redfish / IPMI 伺服器帶外管理

每台伺服器裡藏著第二台小電腦 **BMC**（baseboard management controller）：吃待機電源、走自己的網口，伺服器關機時仍醒著，能讀 PSU 功率、進風溫度、風扇，能開關機。對 DCIM 這是**機櫃裡最密的電力與溫度感測器**。舊協定是 IPMI（二進位、UDP），新協定是 Redfish（HTTPS＋JSON）。跟 [SNMP](snmp-and-mib.md) 一樣，難處不在傳輸，在**讀值的語意與版本**。

## 六格

### 拓撲位置
上游：PSU（經 PMBus）、主機板感測器。下游：DCIM／帶外管理 collector。觀察層傳輸邊；同一個瓦數在 [rack PDU](rack-pdu.md) outlet 上又被量一次——**兩個觀察者看同一條電**。

### 容量單位
IPMI：每感測器一次指令、讀值 **1 byte**。Redfish：每資源一次 GET，成本＝GET 數×回應時間。

### 冗餘表達
協定層無。`PowerSubsystem` 帶 PSU 冗餘群組——那是**伺服器內部**的 N+1，與機房 A/B 路（[dc-16](dual-corded-equipment.md)）是兩件事。

### 遙測介面

| 協定 | 位置 | 內容 |
|---|---|---|
| IPMI SDR | 感測器編號＋SDR 換算參數 | 1 byte 原始值，y=(M·x + B·10^bExp)·10^rExp |
| DCMI Get Power Reading | NetFn 2Ch／Cmd 02h | 目前／最小／最大／平均功率（各 2 byte，W）、時間戳、統計期間、bit 6 是否有效 |
| Redfish（舊，已棄用） | `/Chassis/{id}/Power`、`/Thermal` | `PowerControl.PowerConsumedWatts`、`PowerSupplies[].PowerInputWatts`、`Temperatures[].ReadingCelsius` |
| Redfish（新） | `/Chassis/{id}/PowerSubsystem/PowerSupplies/{n}/Metrics`、`/ThermalSubsystem`、`/Sensors/{id}`、`/EnvironmentMetrics` | `Sensor.Reading`、`ReadingUnits`（UCUM）、`ReadingTime`、`LifetimeReading`、`SensorResetTime`、`Thresholds` |

IPMI over LAN 走 **UDP 623**（RMCP+）。

### 故障域
單台 BMC 當機＝那台失明、伺服器照跑；帳密錯誤則整批同設定的同時消失；管理網被打穿則能開關機——故障域是**整個管理網**。

### 維護特性
BMC 韌體升級可能換掉 schema 路徑（`Power` → `PowerSubsystem`），點位對照要重驗；通常不需停伺服器，但 BMC 重開期間無遙測。

## 來源分歧

1. **舊 schema 還能不能用**：DMTF 2020.4 宣布 `Power`、`Thermal` 棄用（`Power.json` 標 `versionDeprecated: v1_7_0`），「新實作應使用新 schema」；但 OpenBMC bmcweb 文件仍同時列出 `Power#/PowerControl/...` 與 `PowerSubsystem`，DMTF 自己也說服務可兩者並存作為遷移路徑。**結論：新韌體多半兩份都給，舊韌體只有舊的**——collector 要偵測並記下讀的是哪一份。
2. **DCMI 統計期間的單位**：openUBMC 的 byte 定義寫 bytes 15–18 是**毫秒**；同頁 ipmitool 範例印 `Sampling period: 00010824 Seconds`。差 1000 倍，本卡不裁決（見計算三）。
3. **二手來源**：IPMI 換算式只讀到 OpenBMC 郵件串轉述（L[] 線性化函式未定義）；曝險數字是 The Hacker News 轉述單一研究。

## 關鍵數字與計算

**一、IPMI 的 1 byte：解析度與飽和都是 SDR 的設計選擇。**

- 12 V 電壓軌：M=7、B=0、rExp=−2，x=172 → 7×172×10⁻² = **12.04 V**；步階 **0.07 V**，上限 x=255 → **17.85 V**。
- 溫度：M=1、B=−40、bExp=0，x=65 → 65−40 = **25 °C**；B 讓 256 階對到 −40～215 °C。
- 功率：M=4 → 步階 4 W、上限 **1020 W**；1600 W PSU 滿載時讀值卡在 1020 而**不報錯**。改 M=10 → 上限 **2550 W**，但步階變 **10 W**，每台最壞量化誤差 ±5 W，20 台加總最壞 **±100 W**。
- DCMI 功率用 2 byte 整數瓦，沒有這個問題——**同一台伺服器的「功率」走 SDR 與走 DCMI 精度不同**。

**二、對帳：PDU 看到的 vs BMC 說的。**一櫃 20 台伺服器，BMC 回報 PSU 輸入合計 **7600 W**；rack PDU 讀 **8050 W**；兩台無 BMC 的交換器以估計值 150 W×2 = 300 W 計。殘差 = 8050 − 7600 − 300 = **150 W（1.86%）**，容差 3% = 241.5 W 內 → 對得上。

陷阱：若 BMC 給的是 PSU **輸出**（DC 側）7600 W，效率 94% → 輸入 7600 ÷ 0.94 = **8085.1 W**，殘差變 **−335.1 W**——「BMC 比 PDU 還多」不是物理，是**讀錯側**。Redfish 舊 schema 同時有 `PowerInputWatts` 與 `PowerOutputWatts`，side 必須是欄位。另一個陷阱：容差 1% = 80.5 W，小於量化誤差 100 W → 這次比較**無法判定**，不是通過也不是失敗。

**三、DCMI 平均功率的窗。**原始值 10824：若是毫秒 → **10.8 s**；若是秒 → **3.01 h**。3 小時窗內有 10 分鐘 900 W、170 分鐘 500 W，平均 = (10×900 + 170×500) ÷ 180 = **522.2 W**——尖峰完全被抹平。拿這個值做 [rack PDU](rack-pdu.md) 斷路器餘裕，會低估 377.8 W。**平均值的窗長是點位的屬性**，不知道窗就不能用。

**四、Redfish 的請求數。**新 schema：service root → Chassis 集合 → Chassis → PowerSubsystem → PowerSupplies 集合 → 2×PSU → 2×Metrics = **9 次 GET**。舊 `Power` 一份資源全包：root → 集合 → Chassis → Power = **4 次**。新 schema 結構較好，**請求反而變多**。若再逐一讀 60 個 `Sensors`，一台約 70 次。

假設 BMC 每次 150 ms（**假設值**，未量測）、500 台、20 併發：70 次 → **262.5 s**；9 次 → **33.75 s**；支援 `$expand` 壓到 2 次 → **7.5 s**。60 s 輪詢週期下，只有後兩者可行。

**五、曝險。**CVE-2013-4786（CVSS 7.5）是 IPMI 2.0 **規格本身**的缺陷：未登入者可要求 BMC 回 RAKP 訊息中的 HMAC-SHA1，離線猜密碼；Dell 表示無修補。2026-05 掃描：36,872 台 IPMI 對外曝露，24,650 台（**66.9%**）會吐出可離線破解的材料。這不是韌體能修的，**只能靠網路隔離**——所以隔離狀態是資料。

## 常見誤解

**以為 IPMI 讀到的數字跟 Redfish 一樣精確，但實際上 SDR 讀值只有 256 階，精度與上限由 M／B／exp 決定，超過上限時靜默飽和**：1600 W 的伺服器可能永遠顯示 1020 W。點位要帶 `resolution` 與 `range_max`，就像 [dc-37](temperature-humidity-sensor-placement.md) 的讀值是區間。

**以為 Redfish 的 URI 是固定路徑可以寫死，但實際上 Redfish 是 hypermedia，要從 `/redfish/v1` 循 `@odata.id` 走下去；而且 `Power`／`Thermal` 已於 2020.4 棄用**：同一台 BMC 可能新舊並存、數值來源不同。寫死 `/Chassis/1/Power` 的 collector，韌體升級後會讀到 404 或舊資料。

**以為伺服器關機 BMC 就離線、BMC 掛了伺服器就有事，但實際上兩者生命週期獨立**：BMC 吃待機電源，關機的伺服器仍有活的管理介面（也仍是攻擊面）；BMC 重開時伺服器照跑但看不見——「沒有遙測」不等於「沒有負載」。

## 對資料模型的意涵

1. **BMC 是資產上的管理控制器實體。**`Bmc{asset_id, mgmt_ip, network(oob|prod), firmware, ipmi_lan_enabled, redfish_version, power_schema(PowerSubsystem|Power|None), default_credential_rotated}`。告警：`IPMI_LAN_EXPOSED`（啟用 IPMI LAN 且不在帶外網，因為 CVE-2013-4786 無修補）、`BMC_DEFAULT_CREDENTIAL`、`REDFISH_LEGACY_ONLY`（只有棄用 schema，升級風險）、`BMC_SCHEMA_UNDECLARED`。
2. **點位的 `native_ref` 是發現出來的，不是寫死的。**Redfish 存 `@odata.id` 加 JSON pointer（`.../PowerSupplies/0/Metrics#/InputPowerWatts/Reading`）與 `discovered_at`、`schema_path`；IPMI 存感測器編號，並把換算參數存成 `SdrDef{M, B, bExp, rExp}`——與 `RegisterDef`（[dc-41](modbus-rtu-tcp.md)）、`MibObject`（dc-43）平行。`resolution = |M|·10^rExp`、`range_max` 由 x=255 推出，寫回 `Point` 的不確定度。
3. **讀值可能是窗口聚合。**`Point.aggregation{kind: instant|avg|min|max, window_s}`。DCMI 平均功率的 `window_s` 是設定資料，單位未宣告時 `Result(UNDETERMINED, MISSING_INPUT)`。Redfish 有 `ReadingTime` → `time_basis="device"`、`clock_id` 指向該 BMC（[dc-39](epms-electrical-power-monitoring.md) 的時鐘來源）。`LifetimeReading`＋`SensorResetTime` 讓能量計數像 dc-43 的 `resettable` 一樣可被歸零。
4. **電力側是欄位。**`Point.side ∈ {input, output}`。`reconcile(pdu, Σbmc, unmanaged)` 回 `Result`：side 未知 → UNSOURCED；output 側但沒有有出處的效率 → MISSING_INPUT；量化誤差大於容差 → PRECISION_INSUFFICIENT。對帳失敗告警 `RACK_POWER_UNRECONCILED`。
5. **第十四個「缺東西」：`SERVER_POWER_UNATTRIBUTED`。**一台伺服器的功率必須至少有一條有效觀察路徑：`bmc_psu`（BMC 點位 live 且 side 已知）或 `pdu_outlet`（所在 outlet 有計量）。兩個 `Coverage.kind` 對同一個 target，沿用 dc-43 的 `effective()`。沒有路徑的伺服器，容量帳本只能用銘牌（`topic-01`）。

## 該問 facility 的問題

1. BMC 走獨立帶外網嗎？IPMI over LAN 有沒有關？出廠密碼在上架時有沒有換？
2. 伺服器 BMC 韌體版本是否一致？collector 用 IPMI 還是 Redfish、讀新還是舊 schema？
3. BMC 進風溫度有沒有被當成機櫃進風感測器？跟實裝感測器對照過嗎？

## 動手練習（40 分鐘）

接在 dc-43 的 `coverage.py`（`Coverage`＋`effective`＋`uncovered`）與 dc-42 的 `core.Result` 下游，新檔 `bmc.py`。

```python
def ipmi_convert(x, M, B=0, bexp=0, rexp=0)   # x 不在 0..255 → raise
def ipmi_step(M, rexp); def ipmi_saturates(expected_max, M, B=0, bexp=0, rexp=0)
def dcmi_window_s(raw, unit)                  # unit ∈ {"ms","s"}，其他 → raise
def win_avg(segs)                             # [(minutes, watts)]
def crawl(tree) -> (points, n_get)            # tree: dict[uri, json]，模擬 BMC
#   從 /redfish/v1 循 @odata.id；Chassis 有 PowerSubsystem 走新、否則走 Power
#   points: (native_ref, reading, schema_path)；每讀一個 uri n_get+=1
def fleet_s(gets, lat_s, servers, conc)
def reconcile(pdu_w, pts, unmanaged_w, tol, eff=None, quant_w=0) -> (Result, residual|None)
@kind("bmc_psu")     # state: side None → UNDETERMINED；quality GOOD → OK；否則 VIOLATED
@kind("pdu_outlet")  # state["metered"]
def check_bmc(bmcs) -> list[(code, id)]
```

模擬樹：`NEW` = 1 個 Chassis，同時有 `PowerSubsystem` 與 `Power` 連結，2 顆 PSU 的 `Metrics.InputPowerWatts.Reading` 為 212、198；`OLD` = 只有 `Power`，`PowerSupplies[]` 內嵌同兩個值。

### 驗收表

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | `ipmi_convert(172,7,rexp=-2)`；`ipmi_step(7,-2)`；`ipmi_convert(255,7,rexp=-2)`；`ipmi_convert(65,1,-40)` | **12.04**；**0.07**；**17.85**；**25** |
| 2 | `ipmi_saturates(1600,4)`；`ipmi_convert(255,4)`；`ipmi_saturates(1600,10)`；`ipmi_convert(255,10)` | **True**；**1020**；**False**；**2550** |
| 3 | `ipmi_convert(256,1)` | raise |
| 4 | `dcmi_window_s(10824,"ms")`；`dcmi_window_s(10824,"s")/3600`；`win_avg([(10,900),(170,500)])`；`dcmi_window_s(10824,None)` | **10.824**；**3.01**；**522.2**；raise |
| 5 | `crawl(NEW)` | **9** 次 GET，2 點，schema_path **PowerSubsystem**，合計 **410** |
| 6 | `crawl(OLD)` | **4** 次 GET，2 點，schema_path **Power(deprecated)** |
| 7 | `fleet_s(70,.15,500,20)`；`(9,…)`；`(2,…)` | **262.5**；**33.75**；**7.5** |
| 8 | `reconcile(8050,[(380,"input")]*20,300,.03)` | OK，殘差 **150** |
| 9 | 同上但 side=`"output"`、無 eff | UNDETERMINED(**MISSING_INPUT**) |
| 10 | 同 9，`eff=.94` | VIOLATED，殘差 **−335.1** |
| 11 | 同 8，`tol=.01, quant_w=100` | UNDETERMINED(**PRECISION_INSUFFICIENT**) |
| 12 | 伺服器 S1～S5：S1←bA（input、GOOD）；S2←bB（BAD）＋oB（metered）；S3←bC（side None）；S4←oD（未計量）；S5 無 | S3 UNDETERMINED；S4 VIOLATED（not metered）；S5 VIOLATED（no observer）；S1、S2 不出現 |
| 13 | B1：IPMI LAN on、prod 網、PowerSubsystem；B2：IPMI on、oob、預設密碼、Power；B3：power_schema None；B4：乾淨 | IPMI_LAN_EXPOSED B1；BMC_DEFAULT_CREDENTIAL B2；REDFISH_LEGACY_ONLY B2；BMC_SCHEMA_UNDECLARED B3 |

**加分**：用 `sushy-tools`（Redfish 模擬器）起假 BMC，把 `tree` 換成真的 GET，比對請求數。

## 自我檢核

**Q1. 某櫃 BMC 合計比 PDU 讀值多 335 W。在下結論「PDU 壞了」之前，資料模型應該已經有哪些欄位，才能排除其他解釋？**

??? note "答案"
    `Point.side`（input／output，讀錯側最常見）、`SdrDef` 或 resolution（量化誤差是否已超過容差）、`Point.aggregation.window_s`（平均窗不同不能直接相減）、`Point.last_good_ts_s`（兩邊是否同一時刻）、未管理設備的估計值與其 `evidence`。全部齊備仍對不上，才是 `RACK_POWER_UNRECONCILED`。

**Q2. 為什麼 CVE-2013-4786 要寫成告警規則，而不是「升級韌體」的待辦？**

??? note "答案"
    它是 IPMI 2.0 規格的缺陷，RAKP 流程本身會在登入前吐出可離線破解的 HMAC，廠商表示無修補。唯一的控制是網路隔離與關閉 IPMI LAN，所以 `Bmc.network` 與 `ipmi_lan_enabled` 是要持續檢查的狀態 → `IPMI_LAN_EXPOSED`。

**Q3. 一台 BMC 同時提供 `/Power` 與 `/PowerSubsystem`，兩邊瓦數差 3%。collector 應該怎麼記？**

??? note "答案"
    兩者都是發現到的點位，各帶 `schema_path`；以新 schema 為主、舊的標 deprecated，不平均、不覆蓋，並在 `Bmc.power_schema` 宣告採用哪份。差異拿去問廠商（量測點或平均方式可能不同）。

**未查證**：IPMI 2.0／DCMI 1.5 規範原文、SDR 線性化函式 L[] 的種類、BMC 實際回應時間（150 ms 為假設）、`$expand` 支援度、BMC 進風溫度與機櫃進風的偏差、`PowerSupplyMetrics` 各版本欄位、台灣法規與 CNS。

**下一張**：`dc-45` 閘道器與協定轉換（protocol gateway）
