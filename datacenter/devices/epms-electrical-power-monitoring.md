---
id: dc-39
title: EPMS 電力監控系統（事件時間基準、斷路器狀態點與 BMS 的斷點）
category: systems
written_at: 2026-10-14
sources:
  - https://datacenterfrontier.com/benefits-of-integrating-bms-and-epms
  - https://www.siemens.com/en-us/industries/data-centers/bms-epms-integration
  - https://www.trystar.com/wp-content/uploads/document-library/How-Precision-Time-Protocol-Saved-a-Data-Center-From-Frequent-Power-Losses-Trystar-Case-Study.pdf
  - https://www.trystar.com/wp-content/uploads/Handout_Sequence_of_Events_Recording.pdf
  - https://www.trystar.com/wp-content/uploads/document-library/EPMS-HD.pdf
  - https://endruntechnologies.com/node/246
related: [dc-38, dc-15, dc-16, dc-40, dc-41, dc-43, topic-06]
---

# EPMS 電力監控系統（Electrical Power Monitoring System）

[dc-38](bms-building-management-system.md) 說 BMS 是「第三張圖」，管機電設施的控制迴圈。EPMS 是它的電力對應物，但關鍵差別不是「管的設備不同」，而是**它回答的問題不同**：BMS 問「現在是多少」，EPMS 問「**這幾件事誰先誰後**」。跳脫、轉換、電壓驟降在幾毫秒內接連發生，事後能不能還原順序，取決於每一筆紀錄帶的**時間戳有多可信**。這張卡的主角因此不是點位，而是**時間基準**。

## 六格

### 拓撲位置
上游（被監看的東西）：[MV 開關](mv-switchgear.md)、[變壓器](transformer.md)、[LV 開關](lv-switchgear.md)的斷路器、[UPS](ups-double-conversion.md)、[ATS](ats-transfer-switch.md)／[STS](static-transfer-switch.md)、[發電機](diesel-generator.md)，以及掛在其中的[電錶](power-meter.md)。下游：操作員介面、事件記錄、波形分析、帳單與容量報表，若整合則進 BMS／DCIM。Trystar 把它拆成三層：**計量**（電錶）、**狀態與事件**（斷路器接點、SER）、**時間同步**。**它也不在電力樹上**，而是掛在電力樹每個節點旁邊的觀察層，與 dc-38 的控制圖並列。

### 容量單位
沒有 kW。三個量：**數位輸入通道數**（Trystar SER 每台 32 點）、**每台設備需佔用的接點數**、**時間同步精度（µs 或 ms）**。一台斷路器完整監看要「輔助接點 a、b 與跳脫接點」，我讀成 3 點，所以一台 SER 最多約 10 台斷路器（計算二）。**這個每台 3 點是我從來源「a/b 與 trip 接點」的列法推出，非來源明列的數字。**

### 冗餘表達
來源**沒有討論 EPMS 本身的冗餘**（EPMS-HD 明寫未涉及）。能確定的只有被監看設備的冗餘：N+1、2N+1 的容量與餘裕是 EPMS 要報的內容之一（Schneider 贊助文）。時間源是單點：案例中的 GPS 主時鐘一個壞，全站事件順序同時失準，**而且不會有任何點位變紅**。

### 遙測介面
| 層 | 協定／介面（來源實際提到的） | 備註 |
|---|---|---|
| 現場狀態 | 乾接點（斷路器 a／b／trip、ATS 位置、UPS 狀態、發電機運轉） | 進 SER 數位輸入 |
| 整合 | Modbus TCP（支援多個 master） | EPMS-HD 提到；BACnet、SNMP **未提** |
| 時間同步 | PTP（IEEE 1588）、IRIG-B、DCF77、1per10、NTP | 見下方分歧；NTP 在 EPMS-HD 只用來設初始時間 |
| 事件觸發 | SER 可觸發相容電錶擷取事件前後的電壓電流波形 | 電錶即使沒有高精度對時，仍可用 SER 時間戳對齊波形 |

協定細節留給 `dc-41`、`dc-43`。

### 故障域
分三種，彼此不同。**斷路器本身**：掉了之後下游斷電，與 EPMS 無關。**EPMS 的量測／事件通道**：掉了不影響供電，只失去「事後還原順序」的能力。**時間源**：掉了之後設備仍在記，但時間戳逐漸漂移，**事件仍然寫入，順序卻已不可信**——這是「沉默的失效」的最乾淨版本：資料看起來完整，其實不能互相比較。

### 維護特性
電錶與接點校驗、SER 時鐘檢查、對時源驗證。更新對時設定不一定停電，但**做錯會讓之後所有事件的順序無法使用**，因此是「誰、何時、改了什麼」的資料。

## 來源分歧

- **PTP 能到多準**：Trystar 案例稱 PTP 在乙太網路上「sub-microsecond」；Trystar SER 手冊稱 EPMS 裝置時鐘可同步到「under 100 µs」；Trystar EPMS-HD 稱 Simple profile 為 100 µs、IEEE C37.238 Power Profile 為 1 µs（需 PTP 相容交換器）；EndRun（時間伺服器廠商）稱奈秒到微秒。**四份說法相差兩個數量級**，差異來自 profile 與網路設備，不是誰錯。卡片兩個值都用（計算一）。**NTP**：EndRun 稱「毫秒範圍」，無單一數字。
- **BMS 與 EPMS 該不該合併**：Schneider（贊助文）：不主張自動雙向控制，只要聚合視圖，並建議單一整合廠商；Siemens（廠商頁）：同一平台、single pane of glass。與 dc-38 相同，兩家都有賣東西的立場，沒有獨立裁決。
- **BMS 的邊界**：Schneider 稱 BMS 一般不為毫秒級事件設計；Siemens 稱 EPMS 偵測「毫秒級」事件但沒給 BMS 的數字。「BMS 做不到」的說法兩家都沒有量測。
- **適用範圍**：EPMS-HD 是一般商業與工業的資料表，**不是資料中心專用**；Trystar 案例是美國西南部單一站點。本卡數字不代表台灣標準。
- **未查證**：IEC 61850、IEEE C37.118、C37.238 原文、台灣電力法規與 CNS、EPMS 本身的 Uptime／EN 50600 要求、SER 與電錶的實際事件記憶容量、Siemens「30% 更快上手」（無方法學，不採用）。

## 關鍵數字與計算

**一、兩個時間戳能不能排先後（時間不確定度預算）**。我的模型（非來源公式）：每個事件的時間不確定度 ＝ 時鐘誤差 ε ＋ 解析度 r。兩個事件只有在 `|Δt| > (εA + rA) + (εB + rB)` 時才能判定先後，否則是 `INDETERMINATE`。取來源數字：SER 事件解析度 **1 ms**（CyTime SER 手冊）、PTP Simple profile **100 µs**、NTP 取 **1 ms**（EndRun「毫秒範圍」，我取整數）。

| 組合 | 門檻 |
|---|---|
| PTP SER vs PTP SER | 0.1 + 1 + 0.1 + 1 = **2.2 ms** |
| PTP SER vs NTP 電錶 | 0.1 + 1 + 1 + 1 = **3.1 ms** |
| NTP vs NTP | 1 + 1 + 1 + 1 = **4.0 ms** |

實例：UPS 輸入斷路器在 1000.0 ms 跳脫（PTP SER），電錶在 1002.5 ms 記到電壓驟降（NTP）。Δt = 2.5 < 3.1 → **不能說是跳脫造成驟降，也不能說相反**。把電錶也換成 PTP 同步，門檻降到 2.2，仍判不出；Δt 要 ≥ 3.2 ms 才能分先後。**對照 60 Hz 的四分之一週期**（台灣市電 60 Hz，我的背景知識）：1000/60/4 = **4.17 ms**；SER 手冊說斷路器狀態變化可在「四分之一週期或更短」發生。NTP 對 NTP 的門檻 4.0 ms 幾乎等於這個時間尺度——**用 NTP 對時的設備，無法分辨一個四分之一週期內發生的因果**。（50 Hz 為 5 ms，標註地區差異。）

**二、一台 SER 能看幾台斷路器**。32 點 ÷ 每台 3 點（a、b、trip，我的讀法）＝ **10.67 → 10 台**。案例站點裝了 30 台以上 SER，上限約 **300 台**斷路器。若某台斷路器只接 a、b 而沒接 trip，一台 SER 可看到 16 台（32 ÷ 2），**但代價是看不出「跳脫」與「人為開啟」的差別**（見常見誤解第三條）。

**三、時鐘失聯後多久不能用（holdover）**。假設自由運行晶振漂移 **20 ppm**（我的假設值，非來源），即每秒漂移 0.02 ms。PTP 剛同步時誤差 0.1 ms，之後誤差 `ε(t) = 0.1 + 0.02 × t`（ms，t 為秒）。

- 失聯 60 s → **1.3 ms**；600 s → **12.1 ms**（已超過 4.17 ms 的四分之一週期）。
- 誤差碰到 4.17 ms 的時間：(4.17 − 0.1) ÷ 0.02 ≈ **203 s**。50 Hz 的 5 ms 則 **245 s**。

三分多鐘的對時失聯，就足以讓這台裝置的時間戳在週期尺度上不可信。**EPMS 的對時不是一次設定，是連續的健康狀態。**

**四、線路延遲其實不是問題**。案例中某些對時線超過 2000 ft（≈ 610 m）。訊號傳播速度取 0.66 倍光速（我的假設）：610 m ÷ (0.66 × 3×10⁸) ≈ **3.1 µs**，遠小於 GPS 主時鐘的 ±50 µs。案例換掉線路是因為**原本對時訊號電壓低了 80% 加裝繼電器後引入雜訊**，不是延遲。這提醒你：對時失效的原因通常是電氣品質，不是物理距離。

**五、BMS 與 EPMS 的尺度**。BMS 趨勢 15 分鐘（dc-38 的 UFGS 預設）對 SER 1 ms：900 s ÷ 0.001 s ＝ **900,000 倍**。Trystar 的「約 100 台電錶」對上「數千個未監看點」，意思是電錶永遠是稀疏取樣，**事件靠 SER 補**。

## 常見誤解

**以為「所有紀錄都有時間戳，所以能按時間排序」，但實際上時間戳只在所有時鐘同源且同步時才可比**。每台設備都會記時間，記的是「它自己以為的時間」。兩台用 NTP 的電錶可能差幾毫秒，這個差正好是跳脫與驟降的因果順序。排序之前必須先知道每筆紀錄的時鐘來源與誤差。

**以為「EPMS 就是比較快的 BMS」，但實際上差別是事件導向與趨勢導向**。BMS 取樣，EPMS 的 SER 記**狀態變化的時刻**，不管有沒有人在看。把毫秒事件塞進 15 分鐘趨勢，那個事件在資料裡不存在（dc-38 的 PHENOMENON_UNOBSERVABLE）。

**以為「斷路器開了就是跳脫了」，但實際上沒有 trip 接點就分不出跳脫與人為開啟**。只接 a／b 的斷路器，「開」的原因是保護動作還是有人按了鈕，資料裡不存在。對事故還原，這是兩種完全不同的故事。

## 對資料模型的意涵

1. **事件不是「數值＋時間」，是「數值＋時間＋時間來源」**：`Event{id, source_device, ts_utc, clock_id, resolution_ms, kind}`；`Clock{id, kind: gps|ptp|ntp|free, err_ms, last_sync_ts, drift_ppm}`。時間不確定度是**派生值**：`uncertainty(event, now) = clock.err_ms + drift × (now − last_sync) + resolution`。**`last_sync_ts` 為 None 時不確定度為無限大**，不是 0。
2. **排序是三態，不是二態**：`order(a, b) ∈ {A_FIRST, B_FIRST, INDETERMINATE}`。事故還原報告在 `INDETERMINATE` 時必須這樣寫，不得顯示成排好的時間線。與 dc-37 的 `IN/OUT/UNCERTAIN` 同構。
3. **第九個「缺東西」告警：`BREAKER_NO_STATUS`，配對 `BREAKER_STATUS_INCOMPLETE`**。電力樹上每個斷路器節點至少要有一個狀態點；沒有就是 EPMS 看不見它。有 a／b 但缺 trip → `INCOMPLETE`（看得見開關，看不出原因）。另加 `CLOCK_SYNC_STALE`（`last_sync_ts` 超過 holdover 上限）與 `STATUS_CONTACT_INCONSISTENT`（a、b 應互補，兩者同值＝接點或接線故障）。這是[電力樹](lv-short-circuit-and-coordination.md)×觀察層的新交叉查詢。
4. **跨系統登記：`Scope` 加時間基準**。dc-38 的 `Point.owner_system` 讓同一台 UPS 被 BMS 與 EPMS 各量一次；現在還要 `time_basis: trend|event` 與 `clock_id`，否則兩邊的同一個量只能比較「值」，無法比較「發生時刻」。**BMS-EPMS 的斷點就在這裡**：不是資料量，是 BMS 的點位沒有 `clock_id`。
5. **可觀測性約束沿用**：`interval_s ≤ min_duration_s / 2`（dc-38）。EPMS 的事件通道天然滿足，趨勢通道不滿足；所以「電力品質事件」的需求應綁定到 SER／事件通道，不得綁到趨勢點。

## 該問 facility 的問題

1. 全站的時間源是什麼（GPS？NTP 伺服器？）？每台 SER、電錶、保護電驛各自用什麼協定對時？有沒有哪些設備**只能用 NTP**？
2. 每台斷路器是否都接了 a、b **和 trip** 接點進 SER？哪些斷路器（發電機、ATS）目前完全沒有狀態點？
3. 對時源失聯時，現場有沒有告警？上一次驗證各設備時鐘差是什麼時候？

## 動手練習（35 分鐘）

**目標**：寫 `epms.py`，把「事件順序三態」「對時 holdover」「斷路器狀態覆蓋」三件事實作出來，並**接在 [dc-38](bms-building-management-system.md) 的 `bms.py` 後面**：沿用 `(code, subject)` 元組，加進同一個 `findings` 清單，延續第九個「缺東西」告警。

```python
# epms.py（約 70 行；骨架）
@dataclass Clock:  id, kind, err_ms, res_ms, last_sync_s: float | None, drift_ppm=20
    def error_ms(self, now_s) -> float   # last_sync_s is None -> inf
                                         # 否則 err_ms + drift_ppm*1e-6*(now_s-last_sync_s)*1000
@dataclass Event:  id, clock, ts_ms, at_s
def order(a, b, clocks) -> (verdict, thr)
    # thr = (A 時鐘誤差 + A 解析度) + (B 時鐘誤差 + B 解析度)
    # |ts_b - ts_a| <= thr -> INDETERMINATE（含等號）
def breakers_per_ser(inputs=32, per=3) -> int          # 整數除法
def holdover_limit_s(err0_ms, drift_ppm, limit_ms) -> float
def check_breakers(breakers, mon) -> list[(code, subject)]
    # mon: {breaker: [接點名稱]}；沒有項目 -> BREAKER_NO_STATUS
    # 有項目但不含 "trip" -> BREAKER_STATUS_INCOMPLETE
```

測試資料：七台斷路器 `CB-MV1、CB-TX1、CB-LV1、CB-UPSA-IN` 各接 `a、b、trip`；`CB-UPSA-OUT` 只接 `a、b`；`CB-GEN`、`CB-ATS` 沒有項目。時鐘：`PTP_SER = Clock(kind="ptp", err_ms=0.1, res_ms=1)`、`NTP_MTR = Clock(kind="ntp", err_ms=1.0, res_ms=1)`，皆剛同步（`at_s` 等於 `last_sync_s`）。

### 驗收表

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | `order`：PTP_SER@1000.0 vs NTP_MTR@1002.5 | **INDETERMINATE**，門檻 **3.1** |
| 2 | 同上，但電錶為 1003.2 | **A_FIRST**，門檻 **3.1** |
| 3 | 兩個 PTP SER：1000 vs 1001.5；1000 vs 1003；1003 vs 1000 | **INDETERMINATE**；**A_FIRST**；**B_FIRST**（門檻 **2.2**） |
| 4 | 兩個 NTP：1000 vs 1004；1000 vs 1004.2 | **INDETERMINATE**；**A_FIRST**（門檻 **4.0**） |
| 5 | 兩個 PTP SER，兩台皆已失聯 600 s，1000 vs 1003 | **INDETERMINATE**，門檻 **26.2** |
| 6 | `Clock.last_sync_s=None` 的 `error_ms(5)` | **inf**（不是 0） |
| 7 | 失聯 60 s、600 s 的 `error_ms`（PTP） | **1.3、12.1** |
| 8 | `holdover_limit_s(0.1, 20, 1000/60/4)`；改 50 Hz | **203.3**；**245.0** |
| 9 | `breakers_per_ser()`；乘以 30 台 | **10**；**300** |
| 10 | `check_breakers(上述七台)` | `[("BREAKER_STATUS_INCOMPLETE","CB-UPSA-OUT"), ("BREAKER_NO_STATUS","CB-GEN"), ("BREAKER_NO_STATUS","CB-ATS")]` |
| 11 | 2000 ft 線路延遲（0.66c） | **3.08 µs** |

**加分題**：把 dc-38 `Point` 加上 `clock_id` 與 `time_basis`，寫 `cross_system_conflict(points)`：找出「同一台設備同時被 BMS 趨勢點與 EPMS 事件點登記，但兩邊 `clock_id` 不同」的組合，各自回報 `DUAL_OWNER_TIME_MISMATCH`。再用表 5 的情形回答：此時事故報告能不能放進時間線？

## 自我檢核

**Q1. 兩台設備都用 NTP 對時，一台記到斷路器跳脫、另一台記到電壓驟降，間隔 4 ms。能判斷因果嗎？**

??? note "答案"
    不能。NTP 對 NTP 的門檻為 (1+1)+(1+1) = 4.0 ms，Δt ≤ 4.0 就是 INDETERMINATE（也接近 60 Hz 的四分之一週期 4.17 ms）。要判斷需把其中至少一端換成 PTP，或兩端都換成 PTP 把門檻降到 2.2 ms。

**Q2. 為什麼說「EPMS 就是比較快的 BMS」是錯的？**

??? note "答案"
    BMS 取固定間隔樣本（趨勢導向），EPMS 的 SER 記狀態變化的時刻（事件導向）。15 分鐘趨勢對 1 ms 事件解析度差 900,000 倍，毫秒事件在趨勢資料裡不存在。兩者不是速度差，是資料型態差。

**Q3. 這張卡會讓資料模型長出什麼欄位與告警？**

??? note "答案"
    `Event.clock_id`、`Clock{kind, err_ms, last_sync_ts, drift_ppm}`、派生的 `uncertainty`、三態 `order()`；每個斷路器的狀態點集合（a／b／trip）；告警 `BREAKER_NO_STATUS`（第九個「缺東西」）、`BREAKER_STATUS_INCOMPLETE`、`CLOCK_SYNC_STALE`、`STATUS_CONTACT_INCONSISTENT`；跨系統的 `Point.time_basis` 與 `DUAL_OWNER_TIME_MISMATCH`。約束：`last_sync_ts` 為 None 時不確定度為無限大。

---

**下一張**：`dc-40` DCIM 的範疇與市場現況
