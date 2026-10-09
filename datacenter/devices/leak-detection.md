---
id: dc-36
title: 漏水偵測（感測線、點式感測器、距離定位與止漏回應鏈）
category: fire-security
written_at: 2026-10-09
sources:
  - https://iconprocon.com/blog-post/liquid-leak-detection-strategies-for-data-centers-and-mission-critical-facilities/
  - https://iconprocon.com/?p=89889
  - https://core.instrumart.com/assets/cablpro-series-manual.pdf
  - https://community.se.com/t5/EcoStruxure-IT-Forum/Is-there-any-additional-option-to-extend-leak-rope-beyond-100-m/td-p/224186
  - https://www.processingmagazine.com/home/article/55347527/detects-conductive-fluid-leaks-up-to-5000-ft
  - https://assets.kele.com/Catalog/11 Level/PDFs/LD2100 AE Spec Sheet.pdf
related: [dc-35, dc-34, dc-33, dc-32, dc-30, dc-28, dc-27, dc-26, dc-08]
---

# 漏水偵測（Leak Detection）

漏水偵測是機房裡**唯一一類「水在電的上面或旁邊」的防線**。前三張安全類卡片（[VESDA](vesda-aspirating-smoke-detection.md)、[氣體釋放盤](gas-suppression-release-panel.md)、[門禁](access-control-door-controller.md)）都在問「偵測到的東西能不能到達處置」；這張卡多一個問題：**偵測器躺在地上，它到底在守護哪一個水源**。感測線很長、很便宜、很容易被當成「地板上的一圈保險」，但它的覆蓋是對「某個盛水設備」的關係，不是對一塊地板的屬性。

## 六格

### 拓撲位置
上游（水源）：[CRAH](crah-chilled-water.md) 的盤管與冷凝水盤、冷水管的接頭與法蘭、[CDU](cdu.md)（泵浦軸封、閥接頭、內部管件）、[RDHx／直接液冷](rdhx-and-dlc.md) 的快接頭、軟管與機櫃歧管、浸沒式的槽縫與外循環管路（Icon 文章列舉）。下游：控制器 → 乾接點／Modbus／BACnet／SNMP → BMS、SCADA、DCIM；以及乾接點驅動的**閥門關閉或空調停機**（Icon：relay 可驅動 valve shut-off 或 HVAC shutdown，但邏輯細節未寫）。控制器本身要電：Icon 建議「備援電源」，即它要掛在某條 [UPS](ups-double-conversion.md) 分支上。

### 容量單位
三個。**線長（m／ft）**：每種控制器有最大感測線長度，各廠牌差到 50 倍（見來源分歧）。**輸入數／虛擬區（zone）**：控制器能分辨幾條獨立的感測線或幾段虛擬區。**距離定位精度（m）**：能定位的設備才有，精度是「固定誤差 + 線長百分比」。

### 冗餘表達
沒有 N+1 的通用形式。實務上的冗餘是**不同型態的感測器重疊**：水源正下方一顆點式感測器，加上沿管路一條感測線。重疊也是資料：兩個感測器都蓋住同一水源，才是「一個壞掉仍有一個活著」。

### 遙測介面
| 點位 | 內容 | 備註 |
|---|---|---|
| 乾接點 | 彙總告警 relay：LD2100 為 1 A @ 24 VDC／0.5 A @ 120 VAC（電阻性），可設 latched／non-latched、supervised／non-supervised | 規格表，本卡以它為「relay 行為」的例子 |
| 串列 | Modbus RTU、BACnet MS/TP（EIA-485） | LD2100 |
| 網路 | SNMP trap、SMTP（最多 4 位收件人）、Modbus TCP、BACnet IP、網頁 | LD2100 |
| 狀態燈 | 紅＝漏水；黃＝**感測線故障或污染** | 漏水與故障是**兩個不同的狀態** |
| 日誌 | 趨勢 288 筆（間隔 1–1440 分），事件 500 筆（FIFO） | LD2100，斷電不丟 |
| 距離 | 「距離漏水處」數值，單位公尺或英尺 | 僅限距離定位型（4 芯線／LeakPoint） |

### 故障域
一條感測線壞掉＝**該線覆蓋的所有水源同時失去防護**；一台控制器掉了＝它的所有輸入同時失效。漏水本身的故障域是**水往下流到哪**：高處的水源影響低處的電力與資訊設備（見資料模型第 1 條）。

### 維護特性
Icon：**每季測試**，並維持備援電源、清楚標示。CablPro 手冊：連接器濕了或污染就**要換**；絕緣測試要求兩條黑線之間電阻 > 20 MΩ。感測線被水浸過之後能不能直接重用，兩份來源**都沒說**，本卡不推論。

## 來源分歧

- **感測線最大長度**：Schneider 社群（官方人員）寫 NetBotz 漏水繩**總長上限 30.5 m（100 ft）**，「不可再延長」，更長只能改點式感測器、或感測盒（sensor pod）／4–20 mA 方案；RLE LD2100 規格表與一篇報導寫**最長 5,000 ft（1,524 m）**；CablPro 手冊寫 LeakDtec 的感測範圍 **9,000 ft**。差 **50–90 倍**（1,524 m ÷ 30.5 m ≈ 50；9,000 ft ≈ 2,743 m ≈ 90 倍）的**廠牌特性**，不是單位問題。**資料模型不能有全域預設的「最大線長」。**
- **定位精度**：Processing magazine 對 RLE LD5100 寫「長短線都 ±2 ft」；LD2100 規格表寫「**±2 ft ±0.5% 線長**，典型重複性 2 ft ±0.25%」。兩個是不同型號，也可能是行銷與規格表的落差；**規格表的版本比較保守，本卡以它計算。** Icon 手冊（2 芯通知線）只寫「可準到數公尺」，沒給公式。
- **區數**：LD5100 為 12 個虛擬區；LD2100 為 32 個虛擬區加 8 個顯示他機的區；CablPro LeakPoint 為最多 60 個感測輸入，LeakDtec 4 個輸入。不同型號，沒有通用數字。
- **同一頁面內不一致**：Icon 頁面一處寫 ProAlert 2 為 105 dB，另一處為 108 dB（無關資料模型，僅供提醒「廠商頁面會自相矛盾」）。
- **連接器電阻的單位缺漏**：CablPro 手冊寫「約 4000 per 1000 ft」，未標單位；若是 Ω，則為 4 Ω／ft，約 13.1 Ω／m，與同手冊 2 芯線的「13 ohms/m」吻合（見計算一）。這是我的換算推論。
- **未取得**：台灣或 NFPA／EN 50600 對漏水偵測的條文；各廠 relay 與閥門連動的實際邏輯；感測器反應時間；**哪些感測器偵測得到非導電冷卻液**（Icon 只說「有些方法靠導電、有些偵測液體實體存在」）。以上請改問 facility 與廠商。

## 關鍵數字與計算

**一、距離定位的原理與換算**（原理為我的推論，數字來自手冊）：Icon 手冊寫 2 芯通知線電阻 **13 Ω/m**，漏水位置由「告警後的電氣參數」算出。若迴路電阻與線長成正比，則：`R = d × ρ`。範例：45 m 的線 → `45 × 13 =` **585 Ω**；告警時量到 351 Ω → `351 ÷ 13 =` **27.0 m**。跨來源檢驗：連接器 4 Ω/ft ÷ 0.3048 = **13.12 Ω/m**，與 13 Ω/m 一致到 1%。

**二、距離是「線上距離」，不是「地板座標」**：感測線沿路徑鋪設。路徑 `(0,0)→(20,0)→(20,10)→(5,10)`，三段 20＋10＋15 = **45 m**。讀值 27 m：走完第一段 20 m，再往北 7 m → 地板座標 **(20, 7)**。若線鋪設時有收線圈、垂直落差，線長就大於地板距離，誤差**累積**：控制器不知道，必須由資料模型提供路徑（`route`）與預留的鬆弛率。

**三、定位精度**（LD2100 規格表）：`誤差 = 0.61 m + 0.5% × 線長`。45 m → `0.61 + 0.225 =` **±0.835 m**；滿線 1,524 m → `0.61 + 7.62 =` **±8.23 m**（約 27 ft）。對 45 m 的短線，誤差約一塊地板磚（600 mm）；對滿線，已是十幾塊磚。**精度不是常數。**

**四、一條 85 m 冷水管下方要幾條感測線？** 感測線上限 30.5 m：`⌈85 ÷ 30.5⌉ =` **3** 條；而 NetBotz 一台只有**一個漏水繩連接埠**（Schneider 人員）→ 要 **3 台**；換成上限 1,524 m 的型號則是 **1** 條。覆蓋同一段管，設備數差 3 倍。附帶：NBES0309 延長線一段 20 ft ＝ 6.1 m，100 ft ＝ 30.48 m。

**五、偵測到之後，漏掉多少水？**（回應鏈；漏水量 50 L/min 為**我假設的情境**，不是來源數字）：`釋放量 = q × (偵測 + 通知 + 閥關閉時間)`。感測 5 s、閥全關 60 s：
- 乾接點直接驅動閥（通知 0 s）：`50 × (5+0+60) ÷ 60 =` **54.2 L**
- 經 DCIM 輪詢 30 s 才下令（最差）：`50 × (5+30+60) ÷ 60 =` **79.2 L**
若排水盤或圍堰容量為 60 L，則**直接驅動不外溢、經輪詢外溢**——同一個感測器，答案由回應路徑決定。

## 常見誤解

**以為「導電式感測線偵測得到所有液體」，但實際上它偵測的是導電液體**。CablPro 手冊的原理是「導電液體接觸線，電流（約 2 mA）改變迴路電壓」；Icon 說可偵測水、乙二醇與許多滅火液。介電（非導電）冷卻液是否偵測得到，要看感測器的型態——本卡**未取得**哪些型號可以。液冷（[dc-26](cdu.md)、[dc-27](rdhx-and-dlc.md)）進機房後，「水源的導電性」與「感測器的偵測原理」**必須配對**，這是新的約束。（區分：線外層的「不導電、疏水 PE 螺旋」只是構造，不是它能偵測非導電液。）

**以為「感測器沒有告警，就代表沒有漏水」，但實際上黃燈（線故障／污染）與紅燈（漏水）是不同狀態**。LD2100 持續監督線的電氣與機械完整性並寫入日誌；而 relay 可設「supervised 或 non-supervised」。**未被監督的線斷了＝靜默失效**：畫面顯示正常、水源實際已無防護。這和 VESDA 的孔堵塞、門的無 DPS 同屬「缺東西」家族。

**以為「距離定位讀出來就是找到漏水位置」，但實際上讀值是線上距離**。位置還要加上路徑、鬆弛、精度三個東西（計算二、三）；沒有 `route` 的控制器只能告訴你「第 27 m」，而 27 m 在地板上的哪裡是**資料模型要回答的問題**。

## 對資料模型的意涵

1. **第六個「缺東西」告警：`LEAK_SOURCE_UNCOVERED`**。每個盛水設備（CRAH、CDU、管路接頭、冷凝水盤、RDHx 歧管）需要至少一個**活著的**感測器覆蓋。`WaterSource{asset, fluid: water|glycol|dielectric|suppression, conductive: bool, volume_l, above: list[Space|Asset]}`；`Sensor{covers: list[WaterSource], state: ok|leak|fault|contaminated|silenced}`。覆蓋只計 `state ≠ fault` 的感測器——**壞掉的感測器等於沒有感測器**。
2. **`LEAK_FLUID_UNDETECTABLE`：有感測器但看不見**。`Sensor.detects: conductive_only | any_liquid`，`WaterSource.conductive`；兩者不相容就是告警。與第 1 條不同：這裡「缺東西」的是**能力**，不是**設備**。同族：`DETECTION_COVERAGE_GAP`（dc-32）、`RELEASE_PATH_DEGRADED`（dc-33）、`DOOR_UNMONITORED`（dc-34）、`DOOR_NO_VIDEO_COVERAGE`（dc-35）。
3. **「水在電上面」是一條有方向的邊**：`WaterSource.above → Space`（水往下流）。查詢「哪些 UPS／PDU／配電盤位於某個水源的**下方**」是風險圖的核心，也是 [Space 層級](space-hierarchy.md)（dc-28）第一次被用來做**縱向**查詢，不只是包含關係。
4. **感測線是一條有幾何的物件**：`SensingCable{length_m, max_len_m (由 controller 型號決定), route: polyline, slack_ratio, rho_ohm_per_m, accuracy_fixed_m, accuracy_pct, locating: bool}`。約束：`length_m ≤ controller.max_len_m`（`LEAK_CABLE_TOO_LONG`）；`route` 必須在 Space 內；`locate(distance) → (x, y) ± uncertainty` 是從事件的 `distance_m` 派生。**事件存原始讀值，位置是派生值**（原始讀值＋當時的 route 版本）。
5. **回應鏈是設備資料**：`Response{path: relay|trap|poll, valve_close_s, notify_s, containment_l}`；`released_l = q × (detect + notify + valve_close)`；`LEAK_RELEASE_EXCEEDS_CONTAINMENT` 當 `released_l > containment_l`。`q` 是情境假設，必須存為 `assumption`，不得偽裝成量測值。
6. **維護與故障是狀態機，不是布林**：`state: ok → leak(latched) → ack → service_required`（濕過的連接器要換）；`last_test_at` 與 `test_interval_days = 90` 產生 `LEAK_TEST_OVERDUE`；控制器 `powered_from` 指向 UPS 分支，使「UPS 掉了 → 漏水偵測盲」成為可查詢的路徑。

## 該問 facility 的問題

1. 每一台 CRAH、CDU、冷水管接頭與冷凝水盤下面，是**點式還是感測線**？感測線是什麼型號、多長、有沒有距離定位？
2. 乾接點有沒有真的接到閥門或空調停機？還是只送到 BMS 顯示？通知路徑是 relay、trap，還是 DCIM 輪詢（以及輪詢週期）？
3. 液冷用的是水、乙二醇，還是介電液？現有感測器對那個液體**實測過**嗎？上次季度測試是哪一天？

## 動手練習（30–40 分鐘）

**目標**：把上面的計算寫成 `leak.py`，並讓它產生**第六個「缺東西」告警**。沿用 dc-35 慣例：不重寫 `core.py`，有 `Finding` 就匯入，沒有就用 `(code, subject)` 元組。

```python
# leak.py（約 70 行；骨架）
def route_length(route)                  # 折線長度
def locate(route, d)                     # 線上距離 -> (x, y)；超出線長 raise ValueError
def resistance(d_m, rho=13.0)            # d * rho
def distance_from_r(r_ohm, rho=13.0)     # r / rho
def accuracy_m(length_m, fixed_m=0.61, pct=0.005)
def ropes_needed(total_m, max_m)         # ceil
def released_l(q_lpm, detect_s, notify_s, valve_s)   # q * (sum) / 60
@dataclass Source:  name, fluid, conductive
@dataclass Sensor:  name, covers, detects_conductive_only=True, state="ok", length_m=0, max_len_m=1e9
def leak_findings(sources, sensors)      # SOURCE_UNCOVERED / FLUID_UNDETECTABLE / CABLE_TOO_LONG / SENSOR_FAULT
def release_findings(q, detect, notify, valve, containment_l, name)
```

### 驗收表（已用參考實作跑過）

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | `route=[(0,0),(20,0),(20,10),(5,10)]`；`route_length`；`locate(route,27)` | **45.0**；**(20.0, 7.0)** |
| 2 | `locate(route,0)`；`locate(route,45)`；`locate(route,50)` | **(0,0)**；**(5,10)**；**ValueError** |
| 3 | `resistance(45)`；`distance_from_r(351)` | **585.0**；**27.0** |
| 4 | `4 / 0.3048`（連接器 4 Ω/ft 換 Ω/m） | **13.12**（≈ 13，差 < 1%） |
| 5 | `accuracy_m(45)`；`accuracy_m(1524)` | **0.835**；**8.23** |
| 6 | `ropes_needed(85, 30.5)`；`ropes_needed(85, 1524)` | **3**；**1** |
| 7 | `released_l(50,5,0,60)`；`released_l(50,5,30,60)` | **54.17**；**79.17** |
| 8 | 兩者對 `containment_l=60` 的 `release_findings` | 第一個 `[]`；第二個 `[(LEAK_RELEASE_EXCEEDS_CONTAINMENT, ...)]` |
| 9 | 見下方資料集：`leak_findings` | 五項（見下） |

資料集（第 9 列）：水源 `crah1`(水)、`crah2`(水)、`cdu1`(介電)、`pipe_main`(乙二醇)、`crah3`(水)、`cdu2`(介電)；感測器 `s1` 蓋 crah1；`c1`（導電式）蓋 cdu1；`r1` 蓋 pipe_main（線長 40、上限 30.5）；`s2` 蓋 crah3 但 `state=fault`；`o1`（任意液體）蓋 cdu2。期望輸出（順序不拘）：`LEAK_CABLE_TOO_LONG(r1)`、`LEAK_SENSOR_FAULT(s2)`、`LEAK_SOURCE_UNCOVERED(crah2)`、`LEAK_FLUID_UNDETECTABLE(cdu1)`、`LEAK_SOURCE_UNCOVERED(crah3)`（**壞掉的感測器不算覆蓋**）。

**加分題**：加上 `above` 邊，寫 `exposed_below(source, spaces)`，回傳位於水源下方的 UPS／PDU 清單。

## 自我檢核

**Q1. 一條 45 m 的距離定位感測線（ρ = 13 Ω/m，LD2100 精度公式）量到 351 Ω。漏水在線上哪裡？誤差多大？**

??? note "答案"
    `351 ÷ 13 = 27.0 m`；誤差 `0.61 + 0.005 × 45 =` ±0.835 m。位置是「線上距離」，換成地板座標必須有 route。

**Q2. 同一個感測器、同一個 50 L/min 的洩漏，排水盤 60 L。乾接點直驅閥與 DCIM 每 30 秒輪詢，結果差在哪？**

??? note "答案"
    直驅：`50 × 65 ÷ 60 = 54.2 L`（不外溢）；輪詢最差：`50 × 95 ÷ 60 = 79.2 L`（外溢 19.2 L）。差別在**通知路徑**，不在感測器——所以 `Response.path` 與 `notify_s` 是資料。

**Q3. 新增一台 CDU 與它的感測線，會讓資料模型長出什麼欄位與約束？**

??? note "答案"
    `WaterSource{fluid, conductive, volume_l, above}`、`Sensor{covers, detects, state, last_test_at}`、`SensingCable{length_m, max_len_m, route, slack_ratio, accuracy_*}`、`Response{path, notify_s, valve_close_s, containment_l}`。約束：每個水源至少一個活著的感測器（`LEAK_SOURCE_UNCOVERED`）、感測器偵測原理與流體導電性相容（`LEAK_FLUID_UNDETECTABLE`）、`length_m ≤ max_len_m`、`released_l ≤ containment_l`、控制器必須有 `powered_from`。

---

**下一張**：`dc-37` 溫濕度感測器佈點策略
