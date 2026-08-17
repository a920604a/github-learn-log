---
id: dc-09b
title: 電池測試制度（IEEE 1188 內阻／容量門檻與 commissioning baseline）
category: power
written_at: 2026-08-17
sources:
  - https://eepowersolutions.com/resources/tech-notes/ohmic-measurements-and-ieee-standard-1188-2005/
  - https://criticalpowerbatterysolutions.com/ups-battery-testing-guide/
  - https://eepowersolutions.com/resources/white-papers/battery-inspection-maintenance-and-testing/
related: [dc-09, dc-08, dc-09c, dc-05c]
---

# 電池測試制度（battery testing regime）

[UPS 電池組](ups-battery.md)那張卡回答「怎麼算它」。這張回答下一個問題：**你憑什麼說它現在還行。** 電池是整條電力鏈唯一平時不在電流路徑上的東西，所以它沒有「用起來怪怪的」這種徵兆——只有一套量測制度，以及這套制度留下的歷史紀錄。而那套制度的資料需求，跟你熟悉的高頻遙測幾乎完全相反。

## 六格

### 拓撲位置

**不在電力鏈上。** 掛在 [BatteryBank](ups-battery.md) 旁邊：往前接 commissioning 建立的基準線，往後接汰換決策與保固索賠。它是一條**時間軸上的鏈**，不是空間上的鏈。

### 容量單位

制度的單位是**百分比**，而且是相對量：% of baseline（內阻）、% of rated capacity（容量）。**沒有絕對門檻**——同一個 4.35 mΩ 在不同 baseline 下是健康或該汰換。

### 冗餘表達

**測試期間的冗餘是負的。** 容量測試要把串拉離線做真實放電；量內阻時，並聯串會讓測試訊號繞路，IEEE 1188 也建議把待測串離線才準。N+1 的 UPS 群組做電池測試時，實際上是 N+1 的 UPS 配 N−1 的電池；2N 的價值到這裡才兌現。

### 遙測介面

兩種取樣率差六個數量級的資料源，必須分開建模：

| 來源 | 頻率 | 內容 | 通道 |
|---|---|---|---|
| BMS 連續遙測 | 秒／分 | cell 電壓、溫度、SOC/SOH | Modbus TCP / SNMP |
| **人工定期量測** | **季／年** | **內阻、扭力、容量測試結果** | **人 + 儀器 + 試算表** |

中間那列最容易被漏掉：**它沒有協定，只有一台手持儀器和一個工程師**。但能預測失效的資訊全在那列。自建系統的第一個實際價值，往往就是把那張試算表變成資料表。

### 故障域

測試制度的故障域是**資料的**：baseline 遺失或儀器換掉，整條 trend 作廢，而且**不可回溯補救**。這跟設備故障域不同——沒有告警會告訴你它壞了。

### 維護特性

VRLA 三層週期：月目視與環境、季內阻＋熱像、年扭力抽查＋容量測試。但容量測試的週期**不固定，是一台狀態機**（演算 2）。鋰電把季測那層交給 BMS，換來的是消防合規與 BMS 韌體版本管理（見 `battery-fire-compliance`）。

## 關鍵數字與計算

### 演算 1：內阻的三個門檻，數字打架而且必須全存

內阻沒有絕對意義，只有**相對基準線的偏差**有意義：`deviation% = (R_now − R_baseline) / R_baseline × 100`。

某 12 V block 的 baseline 是 3.20 mΩ，本季量到 4.35 mΩ：

`(4.35 − 3.20) / 3.20 = 35.9%`

這個 35.9% 是好是壞？取決於你問誰（見下方「來源分歧」）：

| 門檻 | 出處 | 對 35.9% 的判定 | 動作 |
|---|---|---|---|
| **20%** | CPBS 引 IEEE 1188 較新版本，作為汰換觸發 | 超標 | 排汰換 |
| **30–50%** | IEEE 1188-2005 Annex C.4：「typically a change of 30% to 50% from a baseline is considered significant」 | 落在灰帶 | 加測、追趨勢 |
| **50%（vs baseline 或 string average）** | 廠商保固索賠門檻 | 未超標 | **索賠會被打回** |

**同一筆讀值同時是「該換了」與「不能索賠」。** 這不是資料品質問題，是三個門檻服務三個目的：安全裕度、工程指引、商業契約。塞進同一個 `threshold` 欄位的系統，回答不了「我們現在能不能跟廠商要錢」。

分母也分歧：部分廠商改用**串平均**而非 baseline 當分母。若這串平均是 3.80 mΩ，則同一筆讀值變成 `(4.35 − 3.80) / 3.80 = 14.5%`——**換個分母，35.9% 變 14.5%，判定完全翻轉。** 分母必須是欄位。

### 演算 2：容量測試週期是狀態機，不是 cron

IEEE 系列（450 / 1188）的週期規則是**條件觸發**的，三個條件任一成立就升為年測，年測到容量掉到 80% 就汰換：

```
每 2 年（或依廠商）測一次
  ├─ 已達 85% 預期服務壽命            ─┐
  ├─ 容量 < 額定 90%                   ├→ 改為「每年測」
  └─ 較上次下降 > 10%                 ─┘
                                        └→ 容量 ≤ 80% → 汰換
```

代數字：接 [dc-09 演算 2](ups-battery.md)，型錄 design life 10 年、電池間月均 32°C，估得 service life ≈ 5.8 年。

- 85% 門檻 = `5.8 × 0.85 = 4.9 年` → **第 5 年起改年測**
- 但若第 3 年那次測出 88%（< 90%），**年測從第 3 年就開始**，不必等 4.9

**注意這裡的分母是估算值不是型錄值。** 用 10 年去算，85% 落在第 8.5 年——比實際該加密的時間晚了三年半，而那三年半正好是電池最可能掉下去的時段。這就是 dc-09 堅持 `design_life_years` 與 `service_life_est_years` 要分兩欄的實際後果：**排程演算法讀錯欄位，會安靜地遲到三年**，而且不會有任何告警。

### 演算 3：baseline 的六個月，以及它為什麼不能在驗收日量

IEEE 1188 Annex C.4 與廠商保固程序一致要求：**baseline 在電池投入服務約 6 個月後量，不是安裝當天**——新電池尚未完全化成（fully formed），出廠讀值與穩定後差異大。型錄上的內阻值也不能當 baseline，那是實驗室新品平均值。

配套條件全部都是資料模型欄位：同一台儀器、同一種量測法、同樣的探棒接觸點（要直接壓在極柱上，不是壓在螺栓五金）；量測時記錄 **cell 表面溫度（量負極柱）、浮充電壓、充電電流**；異常讀值一定複量；保固索賠需要 **baseline + 至少 3 筆週期讀值**的完整趨勢。讀值也要**校正到 25°C** 才可比，溫度對內阻影響很大。

換一台儀器 = baseline 作廢。所以 `instrument_id` 不是稽核欄位，**它是 trend 的分組鍵**。

### 演算 4：測試窗口要鎖多久

一次年度容量測試的實際不可用時間：

| 階段 | 時長 | 電池狀態 |
|---|---|---|
| 準備、接 DC load bank | 1–2 h | 已離線 |
| 恆功率放電至 EOD | 依額定，8 min 率的 bank 約 0.5–1 h | 離線 |
| 再充電至額定容量 | **8–24 h** | 在線但容量不足 |

**總窗口 10–27 小時，而放電本身只佔其中 1 小時。** 只鎖放電那一段的排程系統，會在再充電期間允許另一路做維護——那時兩路都沒有電池。這也是為什麼窗口實體需要 `recharge_until` 這個獨立於 `end` 的欄位。

## 常見誤解

**以為 BMS 綠燈或浮充電壓正常就代表通過測試，但實際上這兩者跟「制度上合格」是不同判準。** 制度要的是**帶 baseline 的趨勢**：沒有 6 個月後量的那筆基準線，後面所有內阻讀值幾乎無法解讀（IEEE 1188 原文 "difficult to interpret and of limited value"）。你可以有一整年的高頻遙測，卻在索賠時被打回，因為缺一筆兩年前該量而沒量的數字。

**以為容量測試是「量一下」，但實際上它是一次真實的滿載放電，失去保護的窗口比測試本身長一個數量級**（演算 4）。排程要鎖的是**放電 + 再充電**的總窗口。

**以為量內阻是非侵入式的、隨時可做，但實際上並聯串會互相汙染量測。** 測試訊號會從其他並聯串繞路，串數少（48 V 只有 4 個 block）時誤差最明顯，IEEE 1188 建議把待測串拉離線才準——於是**量內阻這件事本身也會降級冗餘**，它跟容量測試只有程度差別，沒有本質差別。

## 來源分歧

**內阻汰換門檻：20% vs 30–50% vs 50%。**

- [CPBS](https://criticalpowerbatterysolutions.com/ups-battery-testing-guide/) 稱 IEEE 1188 較新版本以**高於 commissioning baseline 20%** 作為可辯護的汰換觸發。
- [IEEE 1188-2005 Annex C.4 原文](https://eepowersolutions.com/resources/tech-notes/ohmic-measurements-and-ieee-standard-1188-2005/)：「typically, a change of **30% to 50%** from a baseline is considered significant」，且明講汰換準則是 application specific。
- 同一份 Eagle Eye 技術文件：幾乎所有廠商保固索賠要求**偏離 50% 以上**，且部分改用 string average 而非 baseline 當分母。

三個數字不是誰對誰錯，是**保守營運 / 工程指引 / 商業契約**三種立場，分母也分歧。**資料模型必須把門檻當資料存，且允許多筆並存。** 這也正是拿去問廠商的好題目：你們的保固究竟認哪個分母。

## 對資料模型的意涵

1. **量測是時序事實表，不是設備上的欄位。** `OhmicReading(cell_id, ts, milliohm, instrument_id, method, cell_temp_c, float_v, is_retest)`。`instrument_id` 與 `method` **不是稽核欄位，是 trend 的分組鍵**——跨儀器比較無效，查詢層要能拒絕。
2. **baseline 是版本化實體，不是常數。** `BaselineSet(bank_id, established_at, instrument_id, superseded_by)`。換電池、換儀器、大修都要開新版本。存成 `BatteryString.baseline_mohm` 的設計，第一次換儀器就靜默失真。
3. **門檻是策略資料，不是常數。** `ThresholdPolicy(kind, source, denominator, pct, action)`，`source ∈ {ieee, vendor_warranty, internal}`、`denominator ∈ {baseline, string_avg}`。一筆讀值要能同時對多條策略求值，產出多筆 `Finding`。
4. **排程是衍生值，不是欄位。** `next_test_due` 必須由狀態機算出（演算 2），輸入是 `service_life_est_years` 與測試歷史。存成固定欄位，就等於把「安靜遲到三年」寫死進資料庫。
5. **維護窗口要能表達暫時性冗餘降級。** `MaintenanceWindow(start, end, recharge_until, effective_redundancy_delta)`——`recharge_until` 獨立於 `end`（演算 4）。告警規則要在窗口內改用降級後的冗餘等級判定。

## 該問 facility 的問題

1. **這批電池的 baseline 是誰量的、哪一天、用哪台儀器？投入服務滿 6 個月那筆有沒有？** 沒有的話保固從第一天就是空的，而且補不回來。
2. **廠商保固認的分母是 baseline 還是 string average、門檻幾 %？** 這決定我們的內部門檻要不要比它更嚴。
3. **容量測試那天的替代供電路徑寫在哪份 MOP 裡？窗口算到放電結束還是算到充飽？**

## 動手練習（30–40 分鐘）

接 [dc-09](ups-battery.md) 的 `BatteryString` / `BatteryBank`，長出**測試層**。要擋住三件事：**(a) 沒有 baseline 的讀值不能判定；(b) 跨儀器的比較必須拒絕；(c) 判定是「讀值 × 策略」的笛卡爾積，不是讀值的屬性。**

```python
from dataclasses import dataclass, field
from datetime import date
from enum import Enum

Src = Enum("Src", "IEEE VENDOR_WARRANTY INTERNAL")
Den = Enum("Den", "BASELINE STRING_AVG")

@dataclass
class BaselineSet:
    bank_id: str
    established_at: date              # 應為 install_date + ~180 天
    instrument_id: str
    values_mohm: dict[str, float] = field(default_factory=dict)   # cell_id -> mΩ
    superseded_by: str | None = None

@dataclass
class OhmicReading:
    cell_id: str
    ts: date
    milliohm: float
    instrument_id: str
    cell_temp_c: float
    float_v: float
    is_retest: bool = False

@dataclass
class ThresholdPolicy:
    kind: str                         # "ohmic" | "capacity"
    source: Src
    denominator: Den
    pct: float                        # ohmic: 偏離上限；capacity: 下限
    action: str                       # replace | investigate | warranty_claim

@dataclass
class CapacityTest:
    bank_id: str
    ts: date
    measured_pct: float               # 佔額定容量的 %

# TODO deviation_pct(reading, baseline, string_avg, denominator) -> float
#      baseline 缺該 cell            -> raise（不可用型錄值或串平均頂替）
#      reading.instrument_id != baseline.instrument_id -> raise
#      ★ 這兩個 raise 是本題重點：「無法判定」跟「判定為好」是兩件事
# TODO evaluate(reading, baseline, string_avg, policies) -> list[Finding]
#      對每條 policy 求值，denominator 決定分母
#      同一筆讀值可同時產出 replace(IEEE 20%) 與落空的 warranty_claim(50%)
# TODO next_capacity_test(bank, history: list[CapacityTest], today) -> date | None
#      base = 2 年；任一條件成立改 1 年：
#        (a) age >= 0.85 * bank.service_life_years()   ← 用估算值不是型錄值
#        (b) history[-1].measured_pct < 90
#        (c) history[-1] - history[-2] < -10
#      history[-1].measured_pct <= 80 -> 回傳 None 並標 REPLACE
# TODO window_hours(bank) -> tuple[float, float]
#      回傳 (放電窗口, 含再充電的總窗口)；總窗口 = 放電 + 8~24h
```

**驗收標準**

| 情境 | 期望 |
|---|---|
| baseline 3.20、本次 4.35、同儀器、分母 BASELINE | `≈ 35.9` |
| 同上但分母 STRING_AVG（串平均 3.80） | `≈ 14.5` ← 判定翻轉 |
| 本次讀值換了另一台儀器 | **raise**（不是回傳 0 或忽略） |
| baseline 沒有該 cell | **raise** |
| 35.9% 對三條 policy（IEEE 20 / internal 40 / warranty 50） | **2 筆 Finding**：replace、investigate；warranty **不觸發** |
| `service_life=5.8`、age 5.0、上次 95% | 年測（條件 a） |
| `design_life=10` 誤填進 service_life、age 5.0 | **仍是 2 年測** ← 重現「安靜遲到三年」 |
| 上次 88%、age 3.0 | 年測（條件 b） |
| 前次 99%、上次 92%（跌 7） | **仍是 2 年測**（條件 c 未觸發） |
| 前次 99%、上次 87%（跌 12） | 年測（條件 c） |
| 上次 79% | `None` + REPLACE |
| `window_hours` | 放電 ≈ 1 h、總窗口 ≥ 9 h |

**加分題（清三週欠款）**：把散在 dc-05 ~ dc-09b 的 `Genset` / `Ups` / `BatteryBank` 收進一個 `DeviceRegistry`，提供 `upstream(device)` 遍歷。明天的消防合規卡會在同一個 registry 上加第二種遍歷（沿防火區聚合能量）——**兩棵樹共用節點但邊不同**，那是 `dc-10` STS 之前必須先有的地基。

## 自我檢核

**Q1. 稽核員問「你們的電池健康嗎」，你手上有整年的 BMS 每分鐘遙測，但沒有內阻 baseline。你能回答嗎？**

??? note "答案"
    **不能**——而且要精確說清楚不能的是哪一半。BMS 遙測能證明「沒有發生即時異常」（電壓、溫度、SOC 都在範圍內），這是**排除法**。但制度上的健康判準是容量與內阻**趨勢**，兩者都需要基準：容量比額定值，內阻比投入服務約 6 個月後量的那筆 baseline。IEEE 1188 明講沒有 baseline 的內阻讀值 "difficult to interpret and of limited value"。

    更痛的是這不可回溯：baseline 必須在電池完全化成後、劣化開始前那個窗口量，錯過就永遠補不回來——現在量到的是「已經劣化過的狀態」，之後所有偏差都以它為零點。**這是整條學習軌跡裡少數幾件真正有時效性的事**，跟 commissioning 同一類。

**Q2. 你把年度容量測試排在週日 02:00–04:00 的維護窗口，同一個窗口另一路要換 ATS 控制器。這樣排有什麼問題？**

??? note "答案"
    放電本身只佔 0.5–1 小時，但**再充電要 8–24 小時**（演算 4）。02:00 開始的話，這路的電池要到當天下午甚至隔天才恢復額定容量。窗口關閉、儀表板轉綠，但實際保護仍未回來——**而另一路的 ATS 正在被拆**。這是典型的「兩個維護窗口在紙上不重疊、在物理上重疊」。

    正確做法是窗口實體要有 `recharge_until` 且獨立於 `end`，衝突檢查用 `recharge_until` 而不是 `end`。順帶一提：量內阻也不是免費的（誤解 3），並聯串要離線才準，所以季測也該進同一套衝突檢查。

**Q3.「同一筆內阻讀值可以同時是『該汰換』與『不能索賠』」這件事，會讓你的資料模型長出什麼？**

??? note "答案"
    **一張策略表**：`ThresholdPolicy(kind, source, denominator, pct, action)`，多筆並存——因為 20% / 30–50% / 50% 是三種立場（保守營運、工程指引、商業契約），不是三個候選答案。**一張結果表**：`Finding(reading_id, policy_id, verdict)`，一筆讀值 fan-out 成多筆判定。**一個分母欄位**：`denominator ∈ {baseline, string_avg}`，同一筆讀值換分母就從 35.9% 變 14.5%。

    最深的一層是：**判定不是量測的屬性，是量測與策略的笛卡爾積。** 把 `status: "bad"` 寫進 `OhmicReading` 就等於把當下這套策略燒進歷史資料——之後改門檻，舊資料要嘛全部重算、要嘛跟新資料不可比。這跟軟體監控裡「把告警狀態寫進 metric 而不是留在規則引擎」是同一個錯誤：**事實與判準必須分開存，判準才能演進。**
