---
id: dc-45
title: 閘道器與協定轉換（protocol gateway：兩段輪詢、timeout 協調、離線語意）
category: systems
written_at: 2026-10-22
sources:
  - https://moxa.com/en/articles/speed-up-scada-performance-with-modbus-gateway
  - https://docs.chipkin.com/articles/modbus-gateway-data-validity-and-offline-device-handling/
  - https://docs.chipkin.com/articles/modbus-exception-codes-and-error-handling-reference/
  - https://info.csimn.com/docs/Remotely%20Detecting%20Offline%20Device.pdf
  - https://industrialmonitordirect.com/de/blogs/knowledgebase/modbus-tcp-gateway-poll-rate-timeout-timing-specifications
  - https://en.wikipedia.org/wiki/Modbus
related: [dc-16, dc-38, dc-41, dc-42, dc-43, dc-44]
---

# 閘道器與協定轉換（Protocol gateway）

設備講 RS-485 Modbus RTU／MS/TP，BMS 要 Modbus TCP／BACnet/IP。閘道器一邊當 client 輪詢設備、一邊當 server 讓上層讀——不是透明的管子，是**有自己輪詢週期的第二個觀察者**。它把語意弄丟的方式有三種：資料年齡、離線訊號、故障域。

## 六格

### 拓撲位置
上游：BMS／DCIM collector（[dc-38](bms-building-management-system.md)）。下游：RS-485 上的電表、UPS、CRAH。觀察層的中繼節點。

### 容量單位
埠數 × 每埠總線時間；對照表大小；TCP 連線數。先見底的是總線時間（[dc-41](modbus-rtu-tcp.md)）。

### 冗餘表達
多為 N；2N 需設備有雙通訊埠或兩條總線，少見。

### 遙測介面

| 層 | 內容 |
|---|---|
| 下游（client） | 輪詢規則＝(埠, 從站位址, 功能碼, 起始暫存器, 數量, 週期) |
| 上游（server） | Unit ID → (埠, 從站位址)；Unit ID 即閘道器後方設備的位址，255＝不使用 |
| 錯誤 | 例外碼 10（Path Unavailable，路由錯）、11（Target Failed to Respond，序列側沒回）；BACnet 側 `Reliability`；廠商錯誤暫存器（CSI 從 9001 起每條規則一個） |

模式（Moxa）：**透通**（每個請求即時轉一筆序列交易，一次一筆）／**代理**（agent，獨立輪詢、上層讀快取）。

### 故障域
閘道器掉了＝後面整條總線失明，設備照跑。

### 維護特性
改對照表或韌體需重開，期間全盲；對照表要版本控制（同 `RegisterMap`）。

## 來源分歧

1. **下游離線時 Modbus 側回什麼。**規格有例外碼 11「Target Device Failed to Respond」（Wikipedia、Chipkin 例外碼頁）；Chipkin 資料有效性文章卻建議回 **4（Server Device Failure）**；CSI 則在 N 次失敗後把暫存器設成預設值（例 −99）、另開錯誤暫存器。**三種慣例並存**，collector 必須逐台宣告。
2. **預設行為。**Chipkin 說「保留最後一筆值」是許多閘道器的預設、也最危險；CSI 的失敗次數設 0 即停用預設值（停用後是否保留舊值，**未查證**）。
3. **「retries」含不含第一次。**Chipkin：離線門檻＝timeout × retries，未說明是否含首次。本卡用 `attempts`；兩種解讀差一個 timeout（驗收 #4）。
4. **術語倒置。**Moxa 把主動輪詢的序列埠叫「RTU server」、設備叫「clients」，與 Modbus 命名相反。以「誰發問」判斷。
5. **時序數字單一來源。**500 ms 預設 timeout、透通 9600 baud 100–200 ms 只見於 industrialmonitordirect。

## 關鍵數字與計算

沿用 dc-41：9600 baud 讀 10 暫存器一次交易 **45.83 ms**。一條總線 20 台設備。

**一、代理模式下資料年齡是兩段輪詢相加。**閘道器輪下游一輪 20 × 45.83 = **916.7 ms**；上層每 5 s 讀快取。最壞：值在閘道器剛讀完後改變，等 916.7 ms 進快取、再等 5 s 被讀到 → **5.92 s**。上層的 `last_good_ts` 是**它讀閘道器的時間**，少算一整段下游週期。

透通模式年齡小，但**所有 client 共用一條序列佇列**（見計算三）。

**二、一台死設備拖慢整條總線。**timeout 500 ms、attempts 3 → 每輪在死設備上花 **1500 ms**。

- 1 台死：19 × 45.83 + 1500 = **2370.8 ms**，健康時的 **2.59 倍**
- 3 台死：17 × 45.83 + 4500 = **5279.2 ms**，超過上層 5 s → 其餘 17 台**健康設備**的最壞年齡變成 5.28 + 5 = **10.28 s**
- 臨界：916.7 + n × (1500 − 45.83) ≤ 5000 → n ≤ 2.81，**最多容忍 2 台**

（假設不對離線設備降頻，**未查證**。）

**三、timeout 必須由內往外遞增。**閘道器要 500 × 3 = **1500 ms** 才放棄並回例外碼 11。

- collector 1000 ms → 先放棄，記成 **TIMEOUT**，排查方向變成「網路掛了」
- collector 2000 ms → 收到例外碼 11，正確指向序列側
- 透通模式下若別的 client 正卡在死設備，對**健康設備**的請求要等 1500 + 45.83 = **1545.8 ms** → 健康設備也報 TIMEOUT

約束：`collector_timeout > gw_timeout × attempts + 佇列中最長等待`。

**四、Unit ID 是路由表，不是設備屬性。**兩個埠各有一台位址 7 的電表，要用兩個 Unit ID 區分（7→(1,7)、8→(2,7)）。若 7、8 都指向 (1,7)，讀 8 會**成功回傳另一台的值**——跟 dc-41 字序錯一樣是「成功的錯誤」；找不到對應才回例外碼 10。

**五、保留最後一筆值＝看不見的停滯。**UPS 在 t=0 失聯，閘道器策略 hold-last。t=3600 s 時上層每 5 s 照常成功讀到值，`last_good_ts` 永遠在 5 s 內，[dc-38](bms-building-management-system.md) 的 `POINT_STALE` 不會響；真實年齡 **3600 s**。Chipkin 的折衷：hold 5–10 s 撐過雜訊，再切換到哨兵值。

**六、哨兵值必須落在物理範圍外。**int16、scale 0.1 的溫度點，範圍 −40～85 °C：

- 原始值 9999 → 999.9 °C，範圍外 ✔
- −99（CSI 範例）若是原始值 → −9.9 °C，**在範圍內** ✘；若是工程值 −99 °C 則範圍外 ✔——哨兵要宣告是原始值還是工程值
- UPS 輸出電流哨兵 0 → 0.0 A，與「負載真的掉了」無法區分 ✘（Chipkin 也不建議 0）

## 常見誤解

**以為閘道器只換封包格式、是透明的，但實際上它是有自己輪詢週期與快取的觀察者**：年齡＝下游＋上游週期；一台死設備每輪吃掉 timeout × attempts，同總線健康設備一起變舊。

**以為設備離線一定會讓上層讀取失敗，但實際上許多閘道器預設保留最後一筆值並回成功**：Modbus 沒有品質旗標，上層看到格式完美、數值合理、永遠不變的讀值。BACnet 側至少有 `Reliability = COMMUNICATION_FAILURE`，前提是閘道器有對映。

**以為 A 路與 B 路 UPS 分屬兩個故障域、監控也是兩個，但實際上它們常接在同一條 RS-485 或同一顆閘道器上**：電力 2N（[dc-16](dual-corded-equipment.md)），可觀測性 N。

## 對資料模型的意涵

1. **閘道器是實體，點位要帶路徑。**`Gateway{id, asset_id, mode(agent|transparent), timeout_ms, attempts, config_version}`、`GatewayRoute{gateway_id, unit_id, port, slave_addr}`：`(gateway_id, unit_id)` 與 `(gateway_id, port, slave_addr)` 皆唯一，違反出 `DUPLICATE_ROUTE`。`Point.via: list[gateway_id]`（多跳依序）。
2. **資料年齡累加每一跳。**`Point.age_bound_s = Σ hop.poll_cycle_s`，`time_basis = "gateway_poll"`，不確定度＝`age_bound_s`。`poll_cycle_s` **是算出來的**：依輪詢規則與目前 BAD 設備數重算，超過上層週期出 `POLL_BUDGET_EXCEEDED`（dc-41）。
3. **timeout 協調是可檢查的約束。**`collector.timeout_ms > gateway.timeout_ms × attempts`，否則 `TIMEOUT_NOT_NESTED`——錯誤被歸到錯的層。
4. **故障域查詢要走觀察層。**「哪些冗餘配對共用同一顆閘道器」＝`Asset.redundancy_peer` ⨝ `Point.via` → `GATEWAY_SPANS_REDUNDANT_PAIR`：電力圖與觀察圖第一次 join。

5. **離線策略是欄位，不是常識。**`Gateway.offline_policy ∈ {hold_last, sentinel, exception, reliability}`、`hold_s`、`sentinel{basis: raw|eng, value}`、`exception_code ∈ {4, 11}`。由此推導 `Point.quality`：例外碼 → BAD；讀值等於哨兵 → BAD；`Reliability ≠ NO_FAULT_DETECTED` → BAD；`hold_last` 且無其他訊號 → `Result(UNDETERMINED, UNSOURCED)`。哨兵落在 `RegisterDef` 量測範圍內 → `SENTINEL_IN_RANGE`。
6. **第十五個「缺東西」：`POINT_VALIDITY_UNSIGNALED`。**經閘道器的點位至少要有一條「失效會被看見」的路徑：`gw_exception`、`bacnet_reliability`、`gw_status_register`（錯誤暫存器有被讀）、`sentinel`（已宣告且在範圍外）。四種 `Coverage.kind` 對同一個 target，沿用 dc-43 的 `effective()`。全沒有＝壞了也一直是綠的。

## 該問 facility 的問題

1. A／B 路 UPS 的通訊是否走同一條 RS-485 或同一顆閘道器？
2. 閘道器是透通還是代理？序列側 timeout／重試多少，重試含不含第一次？
3. BMS 讀閘道器的 timeout 與週期？對照表放哪、誰改過？
4. 設備離線時每顆閘道器回什麼（舊值／哨兵／例外碼幾號）、hold 多久？

## 動手練習（40 分鐘）

接在 dc-43 的 `coverage.py`、dc-42 的 `core.Result` 與 `points.Point` 下游，新檔 `gateway.py`。

```python
T_OK = (8+5+2*10+7)*11/9600*1000              # 45.83 ms，dc-41
def cycle_ms(n_ok, n_dead, t_ok=T_OK, timeout_ms=500, attempts=3)
def worst_age_s(hops_ms: list[float])          # 每跳週期相加，回秒
def max_dead(n, upstream_ms, t_ok=T_OK, timeout_ms=500, attempts=3)
def client_sees(client_ms, gw_timeout_ms, attempts, queued_ms=0) -> "EXC_11" | "TIMEOUT"
class GatewayPathUnavailable(Exception): code = 10
def route(gw, unit_id) -> (port, slave)        # 無對應 → raise GatewayPathUnavailable
def age_bound_s(point, gateways, n_dead_by_gw) # 依 via 逐跳以 cycle_ms 重算
def sentinel_ok(value, basis, scale, lo, hi)   # basis ∈ {"raw","eng"}，其他 → raise
def quality(read, gw) -> Result                 # read: {exc, value, reliability}
@kind("gw_exception"); @kind("bacnet_reliability"); @kind("gw_status_register"); @kind("sentinel")
def check_gateways(gws, assets, points, collector) -> list[(code, id)]
```

### 驗收表

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | `cycle_ms(20,0)`；`cycle_ms(19,1)`；`cycle_ms(17,3)` | **916.7**；**2370.8**；**5279.2** |
| 2 | `cycle_ms(19,1)/cycle_ms(20,0)`；`max_dead(20,5000)` | **2.59**；**2** |
| 3 | `worst_age_s([916.7,5000])`；`worst_age_s([5279.2,5000])` | **5.92**；**10.28** |
| 4 | `cycle_ms(19,1,attempts=4)`（retries 不含首次） | **2870.8**，比 #1 多 500 |
| 5 | `client_sees(1000,500,3)`；`client_sees(2000,500,3)` | **TIMEOUT**；**EXC_11** |
| 6 | 健康設備，`client_sees(1000,0,1,queued_ms=1545.8)` | **TIMEOUT** |
| 7 | 對照表 {7:(1,7), 8:(2,7)}：`route(gw,7)`；`route(gw,9)` | **(1,7)**；raise，`code == 10` |
| 8 | 點位經 G1（20 台、2 台 BAD）、上層 5 s：`age_bound_s` | 18×45.83+3000＝3825 ms → **8.825** |
| 9 | UPS-A、UPS-B 互為 `redundancy_peer`，點位都經 G1；collector timeout 1000，G1 500×3 | GATEWAY_SPANS_REDUNDANT_PAIR G1；TIMEOUT_NOT_NESTED G1 |
| 10 | G2 對照表 unit 7、8 都指向 (1,7) | DUPLICATE_ROUTE G2 |
| 11 | collector timeout 2000，G3 500×3，UPS-A 經 G3、UPS-B 經 G4 | 無告警 |
| 12 | `sentinel_ok(9999,"raw",.1,-40,85)`；`(-99,"raw",…)`；`(-99,"eng",…)`；`(-99,None,…)` | **True**；**False**；**True**；raise |
| 13 | `quality({"exc":11},gw)`；`({"value":9999},gw_sentinel)`；`({"reliability":"COMMUNICATION_FAILURE"},gw)`；`({"value":231.0},gw_hold)` | BAD；BAD；BAD；UNDETERMINED(**UNSOURCED**) |
| 14 | P1 經 G1（exception 11）；P2 經 G2（hold＋讀錯誤暫存器）；P3 經 G3（哨兵 0、範圍 0–400 A）；P4 經 G4（hold、無暫存器）；P5 直連 | P3 VIOLATED（SENTINEL_IN_RANGE）；P4 VIOLATED（**POINT_VALIDITY_UNSIGNALED**）；P1、P2、P5 不出現 |

**加分**：用 `pymodbus` 起兩個 RTU 模擬從站（一個不回應）＋ TCP 前端，實測 #5 兩種 collector timeout 各收到什麼；再把你們實際閘道器手冊的 `offline_policy` 填進 `Gateway`——填不出來就是給 facility 的第一題。

## 自我檢核

**Q1. BMS 上某台 UPS 輸出電流連續兩天恰好 231.0 A，`POINT_STALE` 沒響。資料模型要先有哪些欄位，才能分辨是真的穩定還是閘道器在保留舊值？**

??? note "答案"
    `Point.via`、`Gateway.offline_policy` 與 `hold_s`、四種失效訊號的 Coverage（例外碼／Reliability／錯誤暫存器／哨兵）、`Point.age_bound_s`（年齡要加下游週期）。policy 是 `hold_last` 且四條路徑全無 → `POINT_VALIDITY_UNSIGNALED`：這個讀值本身答不了問題，只能查閘道器錯誤暫存器或現場面板。

**Q2. 為什麼冷水機控制器斷線，會讓同總線電表的資料「變舊」？用什麼數字判斷是否已影響上層？**

??? note "答案"
    總線一次一筆，死設備每輪耗 1500 ms。判斷 `cycle_ms(n_ok, n_dead) > upstream_poll_ms`；第 3 台死就超過 5 s，其他設備最壞年齡 10.28 s。

**Q3. collector timeout 1000 ms、閘道器 500 ms × 3 次，現場說「閘道器常斷線」。先改哪個欄位？**

??? note "答案"
    多半是 collector 比閘道器先放棄，把例外碼 11 記成 TIMEOUT。把 `collector.timeout_ms` 調到 > 1500 ms 加佇列等待；`TIMEOUT_NOT_NESTED` 在設定階段就抓得到。

**未查證**：Modbus 規範原文中例外碼 10／11 條文、各廠離線預設行為、各廠閘道器是否對離線設備降頻輪詢、500 ms 預設 timeout（單一來源）、BACnet MS/TP ↔ IP 路由器（非協定轉換）的延遲、台灣法規與 CNS。

**下一張**：`topic-01` 銘牌值 vs 降載值 vs 實測值（第四輪收尾，第五輪主題卡開工）
