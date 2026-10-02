---
id: dc-32
title: 極早期偵煙 VESDA（吸氣式偵煙）
category: fire-security
written_at: 2026-10-02
sources:
  - https://xtralis.com/file/7504
  - https://xtralis.com/file/868
  - https://xtralis.com/file/725
  - https://xtralis.com/resources/article_level1/873/Article_IFP_Feb2009_-_Xtralis_technology_delivers_reliable_detection_and_early_warning.pdf
  - https://cdn.thefirepanel.com/docs/system-sensor/System%20Sensor%20-%20Aspirating%20Smoke%20Detection.pdf
  - https://eurofyre.co.uk/news/understanding-en-54-20-aspirating-smoke-detection-sensitivity-classes/
  - https://www.asdvconsultant.com/blog/aspirating-smoke-detection-vesda
related: [dc-28, dc-29, dc-33, dc-22]
---

# 極早期偵煙 VESDA（Aspirating Smoke Detection）

天花板上的點型偵煙器是「等煙飄過來」；VESDA 是主動抽風：一條穿孔管網把空氣一路抽回偵測主機，用雷射測煙霧濃度。它比傳統偵煙器靈敏 100 倍以上，目的是在**還只是過熱、還沒起火**時就發出第一級警報。**它不是一顆感測器，而是一張「孔 → 管 → 主機」的取樣網路**，偵測能力住在網路的幾何裡，這是軟體工程師最容易忽略的地方。

## 六格

### 拓撲位置

不在電力樹也不在冷卻樹上，是**第三棵：防火／偵測圖**。孔（hole）分布在空間裡（機櫃列、CRAH 回風格柵、天花板、地板下），管網匯到主機，主機輸出分級警報給消防受信總機（FACP）與 `dc-33` 的氣體滅火控制盤。它的掛載點是 [空間層級](space-hierarchy.md) 的 `Space`，不是設備的父子鏈。

### 容量單位

**不是 kW 也不是 kVA，是「覆蓋」**：每台主機幾條管、每條管幾公尺、幾個孔、涵蓋幾 m²，加上靈敏度（%obs/m，每公尺煙霧遮光率）。VESDA-E 官方規格：VEU 4 管、每管直線 400 m／分岔 800 m，Class A 最多 80 孔，涵蓋 6,500 m²；VES／VEP-4 每管 280 m、40 孔、2,000 m²；VEP-1 1 管 100 m、30 孔、1,000 m²。

### 冗餘表達

偵測本身沒有 N+1 的概念，通常用**空間重疊**：主偵測（回風側）＋次偵測（機櫃列或天花板）兩張網各自獨立。氣體滅火常見做法是分兩級（FIA 規範：Action 可觸發 Stage 1、Fire 2 通常觸發 Stage 2），所以冗餘更像「訊號的分級確認」，不是「備援一台」。

### 遙測介面

| 點位 | 內容 | 備註 |
|---|---|---|
| 煙霧濃度 | %obs/m，即時 | Modbus HLI 的值**以 Fire 1 門檻正規化**，見下方計算 |
| 警報狀態 | Alert／Action／Fire 1／Fire 2 | 四級是 Xtralis 用語 |
| 門檻設定 | 各級 %obs/m，日／夜兩套 | VEU/VEP 8 組、VES 32 組（欄位語意文件未展開） |
| 故障 | Minor／Urgent／Isolate | Isolate＝火警輸出被關掉 |
| 氣流／濾網 | 流量故障、濾網壽命 | 流量改變＝傳輸時間改變 |

協定：官方 VESDA-E 規格頁列 Ethernet／USB／VESDAnet／繼電器；**Modbus 由另一個 HLI 閘道器提供**（一台最多 200 個 VESDA 裝置，含最多 40 台偵測器）。BACnet／SNMP 本次未查到原文。

### 故障域

主機掉了（Isolate）＝該分區**沒有偵煙**，而且沒有任何東西「壞掉」的聲音——這是第二個「缺東西」型告警（上一個是 `dc-29` 的空 U 盲板）。管路被堵或孔被封會讓**靈敏度悄悄變差**，主機可能仍顯示正常。

### 維護特性

至少每年檢查一次（FIA 規範 §15.1）；濾網在辦公室環境最長約 3 年，工業環境更短（§12.1.8）。**維護時常需將主機設為 Isolate**——這段時間機房沒有早期偵測，需要工單與替代巡檢。

## 關鍵數字與計算

**一、孔稀釋：一個孔看到的煙，主機只看到 1/N**

所有孔的空氣在主機入口混在一起，N 個孔、其中 k 個孔有煙：

```
單孔等效靈敏度 = 主機門檻 × N ÷ k
```

System Sensor 的例子（主機門檻 0.25 %/ft、10 孔）：k=1 → 2.5 %/ft；k=2 → 1.25；k=3 → 0.833；k=10 → 0.25，「10 孔全有煙時系統靈敏度就是主機本身」。換成 VESDA-E VEU 的 Class A 上限 80 孔、Fire 1 門檻假設 0.1 %obs/m：

```
單一孔要看到 0.1 × 80 ÷ 1 = 8.0 %obs/m 才會觸發 Fire 1
```

**同一台主機，加孔就是減靈敏度**——這與 EN 54-20 各級孔數上限不同（Class A 通常最少，見下方分歧）方向一致，但標準原文未取得，因果為推論。

**二、傳輸時間：最遠的孔決定一切（自行推導，需廠商軟體驗證）**

管內徑 21 mm（Xtralis 規範），截面積 A = 3.46×10⁻⁴ m²。假設主機總抽氣量 Q = 30 L/min（每孔約 3 L/min × 10 孔，落在文獻「每孔 1–4 L/min」內；**主機實際流量為假設值**）。

天真算法：管長 60 m ÷ 入口流速 → `t = L·A/Q = 41.6 s`，看起來綠燈。

但空氣沿途被各孔吸走，**離主機越遠的管段流量越小、流速越慢**。若 N 個孔等間距、每孔吸氣相同，最遠孔的煙要依序通過載流量 1q、2q…Nq 的各段：

```
t = (L·A/Q) × H_N ，H_N = 1 + 1/2 + … + 1/N（調和級數）
N=10：H_10 = 2.929 → t = 41.6 × 2.929 ≈ 121.7 s
```

**同一條管、天真算 41.6 秒、理想化算 121.7 秒，差 2.9 倍。** 把管縮短到 30 m（或總流量加倍到 60 L/min）則 ≈ 60.9 s。這是理想化模型（等流量、忽略壓降），**不能用於設計**，真值要用 Xtralis 的 ASPIRE／PipeCAD 軟體算；但它說明了為什麼規範要求用軟體算每個孔的傳輸時間，而不是量管長。

**三、傳輸時間的容許值有三套（見「來源分歧」）：** NFPA 72/76（System Sensor 轉述）一般 120 s、EWFD 90 s、VEWFD 60 s；Xtralis／FIA 規範上限 120 s、理想 < 60 s。把上面 121.7 s 代進去：對 120 s 上限**差一點超標**，對 60 s 目標則**差一倍**。

**四、總反應時間 = 傳輸 + 偵測 + 警報延遲。** 警報延遲每個門檻最多可設 60 s（FIA §12.1.5，可累加或同時）。傳輸 60 s ＋ 延遲 60 s，從「煙進孔」到「Alert 發出」就是 2 分鐘——這不是 bug，是設定。

**地區差異：** NFPA 76 的 VEWFD 覆蓋 200 ft²（18.6 m²）／孔（System Sensor 轉述），UK FIA 的次偵測基準 25 m²／孔（依環境調整，BS 6266）；**台灣消防法規的對應條文本次未查證**，卡片不套用任何一套。

## 常見誤解

1. **以為 VESDA 是「更靈敏的偵煙器」，但實際上**它是一張取樣網路。靈敏度、反應時間、可覆蓋面積都是**管網幾何的函數**（孔數、管長、流量），換個孔數同一台主機的等效靈敏度就差幾十倍。資料庫裡只存「型號＝VESDA-E VEU」等於什麼都沒存。
2. **以為警報門檻是標準、換機器不變，但實際上**Alert／Action／Fire 1／Fire 2 是 Xtralis 的分級語彙，**門檻數值全部可程式**，且可日夜兩套。NFPA 與 EN 54-20 都沒規定「Action 是 0.xx %obs/m」。不同現場同名等級的數值不同，告警規則不能寫死。
3. **以為主機顯示「正常」就是有在偵煙，但實際上**Isolate（火警輸出被關）與 Urgent Fault（可能偵測不到煙）都是「裝置還活著、但保護已失效」。更隱蔽的是管路被封或氣流改變——靈敏度退化、傳輸時間拉長，主機仍說正常。

## 來源分歧：傳輸時間的上限是多少

- **System Sensor 應用指南**：NFPA 72/76 的 SFD 120 s、EWFD 90 s、VEWFD 60 s；EN 54-20 A/B/C 三級「最大傳輸時間 60 s」。
- **Xtralis／FIA Code of Practice §9.3.3**：上限 120 s，理想 < 60 s。
- **Xtralis IFP 文章（2009）**：EN 54-20（2006）§6.15.4 是「**傳輸終點後 60 秒內**要反應」，**並沒有**獨立的最大傳輸時間；舊標準 CEA4022 才是 120 s 上限。同文另列 ASPIRE 對 B 級要求 < 90 s。

三方說的 60 s 可能不是同一個量（傳輸時間 vs 傳輸後的反應時間），**原標準全文（NFPA 72/76、EN 54-20）本次均未取得，不裁決**。資料模型要記的是 `limit_s` **加上它的 regime 與出處**，不能存成一個全域常數。

另有兩點：Eurofyre 列 EN 54-20 的 A／B／C 孔數上限依機型而異（EF-FT1：16/72/72；EF-FTP：12/36/36；EF-LASD：3/6/18），並寫「0.04 %obs/m（A、B）／0.10 %obs/m（C）」，其意義與 VESDA-E 規格頁的 Class A 孔數（VEU 80、VES 40…）無法直接對照，**不引用該靈敏度數字**。「單偵測器最多 2000 m²」（FIA，英國防火分區）與 VEU 的 6,500 m² 是不同口徑，後者是廠商規格頁。

## 對資料模型的意涵

1. **取樣網路要有身分，孔是一等公民。** `Detector`（型號、class、靈敏度範圍）、`Pipe`（inlet、長度、內徑）、`Hole`（所屬 pipe、位置、`space_id`、覆蓋面積、吸氣流量）。`effective_sensitivity(hole_set_with_smoke)` 是**推導值**（公式一），不能存。孔掛在 [空間層級](space-hierarchy.md) 的 `Space` 上，不掛在電力節點上。
2. **`transport_time_s` 是從幾何與流量推導的值，不是設備欄位**，且要帶 `method`（`naive` / `harmonic` / `vendor_software`）與 `limit_regime`（`nfpa_vewfd` / `fia_max` / …）。這是繼 `dc-18` 冰機重啟時間之後又一個「不能是常數」的量；流量改變（孔被封）要觸發重算。
3. **警報門檻是設定，不是設備屬性**：`Thresholds{level, mode(day|night), pct_obs_m}`，並帶 `source`、`fetched_at`——消防承包商改了門檻，設施模型不會知道（又一次「設施 vs 管理平面」，前三次：`dc-16` iDRAC、`dc-19` BMS 流量變化率、`dc-21` 冰水設定值）。
4. **新 Finding：`DETECTION_COVERAGE_GAP`——第二個「缺東西」告警。** 某 `Space` 沒有任何**有效**偵測器（狀態 ∈ {Normal, Minor Fault}）時發出；Isolate 與 Urgent Fault 不算有效。維護窗口開 Isolate 必須是**有開始與結束時間的工單狀態**，不是隨手一個布林。
5. **跨圖邊：偵測 → 滅火。** Action／Fire 2 可對應氣體滅火的 Stage 1／Stage 2（FIA 規範：Action 可能觸發 Stage 1、Fire 2 通常觸發 Stage 2），所以 `dc-33` 會需要 `Detector.level → ReleaseStage` 的映射；今天先在 `Alert.triggers` 留一個可為空的欄位。

## 該問 facility 的問題

1. 每個孔的位置、所屬空間與傳輸時間，**有沒有 PipeCAD／ASPIRE 的計算報告**？報告日期是否早於最近一次機櫃增減？
2. Alert／Action／Fire 1／Fire 2 目前各設幾個 %obs/m？日夜兩套是否不同？誰有權限改、改過沒？
3. 年度維護時主機要不要設 Isolate？設多久？期間的替代巡檢是誰？

## 動手練習（30–40 分鐘）

新建 `vesda.py`，接 `dc-28` 的 `Space`（沒有就用字串 id 代替）。**先寫公式與查表，再寫 `Check` 與覆蓋缺口，最後寫 Modbus 解碼**：

```python
import math
from enum import Enum
class Check(Enum):            # 與 dc-30b / dc-31 同一個
    OK="ok"; VIOLATED="violated"; NOT_APPLICABLE="not_applicable"
    INVALID="invalid"; UNDETERMINED="undetermined"
class DState(Enum):
    NORMAL="normal"; MINOR="minor_fault"; URGENT="urgent_fault"; ISOLATED="isolated"

LIMITS = {"nfpa_sfd":120, "nfpa_ewfd":90, "nfpa_vewfd":60, "fia_max":120, "fia_ideal":60}
HOLES  = {("VES","A"):40, ("VEU","A"):80, ("EF-LASD","A"):3, ...}   # 見上方

def hole_sensitivity(s_det, n, k): ...                    # s_det * n / k
def transport_naive(L_m, q_lpm, id_mm=21): ...            # L*A/Q，單位秒
def transport_far(L_m, q_lpm, n, id_mm=21): ...           # naive * H_n
def check_transport(t_s, regime) -> Check: ...            # 查無 regime → UNDETERMINED
def check_holes(model, cls, n) -> Check: ...              # 查無 → UNDETERMINED
def check_thresholds(alert, action, fire1, fire2) -> Check: ...   # 嚴格遞增，否則 INVALID（本卡自加的健全性規則）
def level(smoke, thr) -> str | None: ...                  # 回最高被達到的級別
def real_smoke(reported, fire1_thr) -> float: ...         # reported * fire1 / 20（HLI 文件公式）
def coverage_gaps(spaces, detectors) -> set: ...          # detectors: [(state, covered_spaces)]
```

### 驗收表（已用參考實作跑過）

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | `hole_sensitivity(0.25,10,k)`，k=1,2,3,10 | **2.5 / 1.25 / 0.8333 / 0.25** |
| 2 | `hole_sensitivity(0.1,80,1)` | **8.0** |
| 3 | `transport_naive(60,30)`；`transport_far(60,30,10)` | **41.6 s**；**121.7 s** |
| 4 | `transport_far(30,30,10)`；`transport_far(60,60,10)` | 皆 **≈ 60.9 s** |
| 5 | `check_transport(90, r)`，r = sfd／ewfd／vewfd／fia_max／fia_ideal／`en54_20` | **OK／OK／VIOLATED／OK／VIOLATED／UNDETERMINED** |
| 6 | `check_transport(60.87,"nfpa_vewfd")` | **VIOLATED**（差 0.87 s 也算超標） |
| 7 | `check_holes("VES","A",40)` / `41`；`("EF-LASD","A",3)` / `4`；`("XYZ","A",5)` | **OK／VIOLATED／OK／VIOLATED／UNDETERMINED** |
| 8 | `check_thresholds(0.05,0.1,0.2,0.4)`；`(0.05,0.2,0.1,0.4)` | **OK**；**INVALID** |
| 9 | 門檻 (0.05,0.1,0.2,0.4)；`level(s)`，s=0.03／0.05／0.15／0.2／0.5 | **None／ALERT／ACTION／FIRE1／FIRE2** |
| 10 | `real_smoke(10,2)`；`real_smoke(20,0.1)` | **1.0**；**0.1** |
| 11 | D1 NORMAL 涵蓋 S1,S2；D2 ISOLATED 涵蓋 S2,S3 | gaps = **{S3}** |
| 12 | 同上，但 D1 改 URGENT；再把 D2 改 MINOR 而 D1 維持 NORMAL | **{S1,S2,S3}**；**∅** |

第 3 列同一條管天真算 41.6 秒、理想化算 121.7 秒；第 5 列同一個 90 秒，**答案取決於你採哪個 regime**，查不到時回 UNDETERMINED 而不是挑一個。

**加分題**：(a) 給 `Hole` 加 `blocked: bool`，被封時 `n_effective` 減一、各孔流量重分配，重算 `transport_far`；(b) 在 `coverage_gaps` 再加一個條件——主偵測孔位於 `dc-22` 的 CRAH 回風格柵時，CRAH 停機的 `Space` 也算「覆蓋存疑」（**這是依 FIA §8.3.3.1「回風側取樣」做的推論，來源沒直接說**）。

## 自我檢核

**Q1. 一台主機 40 孔、Fire 1 門檻 0.1 %obs/m。只有一個孔進煙，煙濃度要多高才會觸發 Fire 1？**

??? note "答案"
    `0.1 × 40 ÷ 1 = 4.0 %obs/m`。若有 4 個孔同時進煙，只需 1.0 %obs/m。結論：**靈敏度是孔數的函數**，同一台主機孔越多，單點小火越不容易被偵測到。

**Q2. 傳輸時間為什麼不能用「管長 ÷ 入口流速」算？**

??? note "答案"
    空氣沿途被各孔吸走，遠端管段流量小、流速慢。等流量等間距時總傳輸時間是天真值乘 `H_N`（調和級數），N=10 約 2.9 倍。實務要用廠商軟體算每個孔，且**孔被封、氣流改變後數字就失效**。

**Q3. 「消防承包商把 Fire 1 門檻從 0.1 改成 0.5 %obs/m」會讓你的資料模型長出什麼欄位與告警？**

??? note "答案"
    `Thresholds{level, mode, pct_obs_m, source, fetched_at, changed_by}`，以及一條「門檻值與上次記錄不同」的 `THRESHOLD_CHANGED` Finding，並觸發 `dc-33` 放氣聯動的重新確認。門檻是**設定**，住在消防系統，設施模型不會被通知，所以必須定期抓取並比對。

---

**下一張**：`dc-33` 氣體滅火系統與消防警報盤（接 Action／Fire 2 → Stage 1／Stage 2）
