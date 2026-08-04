---
id: dc-05
title: 柴油發電機（diesel generator）— 額定、降載與容量
category: power
written_at: 2026-08-04
sources:
  - https://www.cummins.com/sites/default/files/2018-08/201707%20PowerHour_Understanding%20ISO%208528%20GeneratorSetRatings.pdf
  - https://www.cummins.com/sites/default/files/2020-02/C1350N6%20-%20D-6453.pdf
  - https://www.curtispowersolutions.com/nfpa-110-classification-of-epss
related: [dc-04, dc-05b, dc-06, dc-07]
---

# 柴油發電機（Diesel Generator）— 額定、降載與容量

發電機是電力鏈上第一個**不是把電轉手、而是把電造出來**的設備，也因此是第一個**容量會隨天氣、海拔、甚至自己機房通風設計而縮水**的設備。前四張卡的容量都是「一個數字加一組條件」；發電機是**一台機同時有五個合法的 kW 數字**——選錯一個，整份容量規劃就錯。

> 這台設備太大，拆成兩張。**本卡只談容量：額定分級、場址降載、油耗。** 起動時序（[dc-04](ats-transfer-switch.md) 留下的 6.5 秒）、ISO 8528-5 暫態性能、NFPA 110 定期測試與 wet stacking 移到 `dc-05b`。

## 六格

**拓撲位置**：上游不是電，是**燃料 + 起動能量 + 空氣**——日用油箱 `dc-06`、起動電池、進排氣、冷卻水路。下游是 ATS 的 emergency 側，或先進並聯盤匯流再餵 LV 主盤 `dc-07`。**全鏈唯一一台「上游斷了不會馬上停、但幾小時後一定停」的設備。**

**容量單位**：kWe（不是 kWm 機械功率）與 kVA。坑在於**同一台機有五個額定**：ESP／LTP／PRP／COP／DCC，再乘場址降載 = 第六個數字。

**冗餘表達**：N+1 靠並聯盤 + 負載分擔（isochronous 等轉速調速）；2N 是兩組獨立機組 + 獨立油路 + 獨立並聯盤。**「三台機」不等於 N+1，要看它們共用什麼。**

**遙測介面**：Modbus RTU/TCP 為主，部分控制器另供 SNMP。

| 點位 | 型別 | 為什麼要 |
|---|---|---|
| `engine_state` | enum | `STOPPED`/`CRANKING`/`RUNNING`/`COOLDOWN`/`FAULT` |
| `output_kw` / `pf` | float | 並機時看負載分擔是否均衡 |
| `runtime_hours_total` | float | **有年度配額，非單純 counter** |
| `failed_start_count` | int | 起動失敗率最有預警價值 |
| `battery_voltage` / `charger_ok` | float/bool | 發電機不起動的頭號原因 |
| `air_filter_inlet_temp` | float | **降載係數的實際輸入** |
| `not_in_auto` | bool | 最被低估的告警：切到 MANUAL 忘了切回 |

**故障域**：引擎本身通常不是瓶頸，真正的共因是**附屬系統**——起動電池、日用油總管、並聯盤、共用進排氣井。ATS 是「兩個上游收斂成一點」；發電機是**「N+1 三台透過共用附屬系統偷偷變回 N」**。

**維護特性**：月測、年度負載測試、長時測試——**測試會吃掉年度運轉時數配額**（見演算三）。制度細節在 `dc-05b`。

## 關鍵數字與計算

### 一、一台機的五個額定：Cummins DQLF 實例

ISO 8528-1 §13 定義四種額定，廠商可再自訂第五種。以 Cummins DQLF 為例：

| 額定 | kWe | 年運轉上限 | 24 h 平均負載上限 | 24 h 可用平均 kW |
|---|---|---|---|---|
| **ESP** 緊急備援 | 2750 | 200 h | 70% | 1925 |
| **PRP** 主用可變負載 | 2500 | 無限 | 70% | 1750 |
| **LTP** 限時主用 | 2500 | 500 h | 100% | 2500 |
| **COP** 連續定負載 | 2100 | 無限 | 100% | 2100 |
| **DCC** 資料中心連續（廠商自訂） | 2500 | 無限 | 100% | 2500 |

```
ESP 峰值 2750 kW − COP 峰值 2100 kW = 650 kW = 23.6%
```

**同一顆引擎、同一張型錄，可用容量差 23.6%。** 差在你打算怎麼用它：ESP 賭「一年只跑 200 小時、平均只用七成」，用壽命換峰值；COP 假設天天滿載，峰值只好壓低。

更陰險的是 **ESP 的 70% 平均負載限制**。若照 2750 kW 規劃、長時間拉到 2400 kW，你不是「還在額定內」，是**違反了 ESP 額定的定義**，壽命與保固假設全部失效。「這台機還剩多少餘裕」，**在沒指定 rating class 之前根本沒有答案。**

### 二、場址降載：兩個算法差 4.5 個百分點

型錄基準是 ISO 3046 參考條件：**15 °C（部分廠商用 25 °C）、101.325 kPa、30% RH**。實際場址要降載，而業界有兩套算法：

**A（拇指法則）**：海拔每 300 m 降 3%（150 m 以上起算）；溫度超過 40 °C 後每 5 °C 降 3%。
**B（廠商降載表）**：查原廠 Table A 直接讀係數。

代同一組條件（海拔 1000 m、進氣 40 °C）：

```
A：海拔 (1000−150)/300 = 2.833 檔 × 3% = 8.50%；溫度 40 °C 未超過 40 → 0%
   係數 0.915 → 2750 × 0.915 = 2516 kW
B：Cummins D-6453 Table A（off-grid）1000 m / 40 °C = 0.87 → 2750 × 0.87 = 2393 kW
差距 = 123 kW ≈ 4.5 個百分點
```

⚠️ **台灣情境的重點不在海拔，在量測點。** 台灣的資料中心幾乎都在海拔 100 m 以下，海拔項基本為零。但原廠降載表的橫軸標的是 **air filter inlet temperature（空氣濾清器入口溫度），不是室外溫度**——室內型發電機房通風不良時，進氣可比室外高 10 °C 以上（該資料另註明進氣超過 35 °C 需洽原廠）。**你可能是自己的機房通風把自己的發電機降載了，而型錄與氣象站都不會告訴你。**

### 三、運轉小時是配額，不是計數器

ESP 額定只給 **200 h/年**，而這個配額被**測試**先吃掉一塊：

```
月測 30 min × 12 = 6.0 h；年度負載測試 1.5 h；長時測試 4 h ÷ 36 月攤提 ≈ 1.3 h/年
測試小計 ≈ 8.8 h/年（配額 4.4%）+ 真實停電 3 次 × 2 h = 6.0 h
commissioning 首年另計，可輕易吃掉 40–80 h
```

**首年 commissioning 加上幾次大停電，200 h 是會見底的。** EPA 對 stationary emergency 引擎的「非緊急運轉時數」另有獨立上限，兩套配額要分開計。**這是前五張卡第一個「用掉就沒了」的欄位**：kVA、kA、開關位置、計時器設定都是**狀態**，`runtime_hours` 是**存量**。

### 四、油耗：從效率推，不要抄網路表

網路油耗表彼此差 20% 以上，因為基準不同（kW 或 kVA、standby 或 prime、含不含冷卻風扇寄生損失）。從熱值自己推：

```
柴油 LHV ≈ 42.7 MJ/kg × 密度 0.832 kg/L = 體積熱值 35.53 MJ/L
滿載發電效率 ≈ 38%；1 kWh = 3.6 MJ
每 kWh 燃料能量 = 3.6 / 0.38 = 9.47 MJ → 體積 = 9.47 / 35.53 = 0.267 L/kWh
50% 負載時效率降到約 34%：3.6 / 0.34 / 35.53 = 0.298 L/kWh
```

0.267 L/kWh 落在業界經驗區間 **0.20–0.30 L/kWh** 中間，可信。而 **低負載的每度電油耗更高，不是更低**——任何一張「低負載 L/kWh 更省」的表都是錯的或基準不同。

算 NFPA 110 **Class 48** 的儲油量（1500 kW ESP 機，實際帶 70%）：

```
負載 1500 × 0.70 = 1050 kW → 油耗 1050 × 0.267 = 280 L/h
48 h 需油 = 280 × 48 = 13,440 L ≈ 13.4 m³
```

（NFPA 110 用 **Type–Class–Level** 三軸分類，資料中心常見 **Type 10 / Class 48 / Level 1** ＝「10 秒內接上負載、不補油撐 48 小時、失效會致命」。Type 10 的時序拆解在 `dc-05b`。）明天 `dc-06` 從 13.4 m³ 接下去。

## 常見誤解

**以為發電機的「2750 kW」是一個容量數字，但實際上它是五個數字裡最寬鬆的那個。** 加上場址降載後還有第六個。規格書若只寫「2750 kW 發電機」而沒寫 rating class，那份規格書沒有指定任何東西。這是 `topic-01`（銘牌值 vs 降載值 vs 實測值）最強的實例。

**以為低負載比較省油，但實際上低負載每度電更耗油。** 滿載 0.267 L/kWh、半載 0.298 L/kWh——摩擦與泵損失幾乎不隨負載變，攤到更少度數上單位油耗自然升高。方向搞反，儲油量在「N+1 三台各帶 33%」下會嚴重低估：**冗餘配置本身會推高總油耗。**

**以為 N+1 三台機就有冗餘，但實際上冗餘度取決於它們不共用什麼。** 共用一條日用油總管、一面並聯盤、一個進排氣井、一組電池充電器——任一失效就同時帶走三台。可靠度瓶頸幾乎都在附屬系統而非引擎本體，其中**起動電池排第一**。這是 `topic-06` 故障域建模的第二個反例：[dc-04](ats-transfer-switch.md) 是「收斂」，`dc-05` 是「共因」。

## 來源分歧

**分歧一：降載用拇指法則還是廠商表？** 兩者差 **123 kW ≈ 4.5 個百分點**（見演算二）。**採購與驗收文件必須指定用哪一種、溫度取自哪個量測點。**

**分歧二：「資料中心額定」是不是 ISO 標準的一部分？** **Cummins 2017 教材**明說 ISO 8528-1 §13 只定義 ESP／LTP／PRP／COP 四種，**DCC 是廠商自訂、超出 ISO 的額定**；但**較新的二手資料**聲稱 ISO 8528-1:**2018** 已納入 **DCP（Data Centre Power）** 類別。

沒能取得 ISO 8528-1:2018 原文核對。**這正是拿去問供應商的好問題：「你標的 DCC 是貴司自訂還是 ISO 8528-1:2018 的 DCP？定義一樣嗎？」** 資料模型裡 `rating_class` 這個 enum 必須配 `standard_ref`，否則你無法判斷兩個廠牌上同名的額定是不是同一件事。

## 對資料模型的意涵

1. **`rated_power_kw` 這個欄位本身就是 bug。** 額定要獨立成子表：`genset_rating(genset_id, rating_class, power_kw, max_hours_per_year, max_avg_load_factor_24h, overload_allowed, standard_ref)`。連帶地，**「這台機還有多少餘裕」的查詢必須帶 `rating_class` 參數，沒帶就該報錯而不是回預設值**。本卡的母題形態：**額定不能脫離用途分級。**

2. **場址額定是 derived，不是 stored。** `site_rating_kw = nameplate_kw × derate_factor`，而 `derate_factor` 要存 `method`、`source`、`altitude_m`、`ambient_c`——**其中 `ambient_c` 必須帶 `measurement_point`（`outdoor` / `genset_room` / `air_filter_inlet`）**，否則會**系統性往樂觀方向偏**。`dc-04` 的 `measurement_point` 教訓第二次出現。

3. **運轉小時是有限配額，要當存量建模。** `runtime_hours_ytd` + `quota_hours`（由 rating_class 決定）+「YTD > 配額 80%」告警，且**必須按 trigger 分組累計**（測試 / 真實停電 / commissioning）——EPA 的非緊急運轉時數是第二套獨立配額。

4. **故障域需要「共用依賴」的邊，不只是父子樹。** 除 parent 指標外還要 `shared_dependency(component_id, dependency_id, dependency_type)`，type ∈ `{fuel_header, paralleling_switchgear, air_intake_plenum, battery_charger}`。有這條邊，「三台 N+1 的實際冗餘度」才是**查得出來**的。

## 該問 facility 的問題

1. **照哪個 rating class 採購的？** 規格書寫 ESP、PRP 還是 DCC？若寫 DCC，是廠商自訂還是 ISO 8528-1:2018 的 DCP？年度運轉時數配額誰在追蹤，commissioning 會不會吃掉 ESP 的 200 h？
2. **場址額定用拇指法則還是原廠降載表算的？** 拿得到 Table A 嗎？計算用的溫度是**室外**還是**發電機房進氣**？機房通風的設計溫升多少？
3. **三台機共用什麼？** 日用油一條總管分三支還是各自獨立？並聯盤一面還是兩面？進排氣井與電池充電器呢？

## 動手練習（30–40 分鐘）

接續 `dc-04` 的 `TransferSwitch` 往上游長出 `Genset`。核心是**用型別強迫「額定必須帶 class」**——若你的 `Genset` 有一個叫 `rated_kw` 的裸欄位，這個練習就失敗了。

```python
from dataclasses import dataclass, field
from enum import Enum

RatingClass  = Enum("RatingClass",  "ESP LTP PRP COP DCC")
DerateMethod = Enum("DerateMethod", "RULE_OF_THUMB MANUFACTURER_TABLE")
TempPoint    = Enum("TempPoint",    "OUTDOOR GENSET_ROOM AIR_FILTER_INLET")

@dataclass(frozen=True)
class Rating:
    rating_class: RatingClass
    power_kw: float
    max_hours_per_year: float | None      # None = 無限
    max_avg_load_factor_24h: float        # 0.70 或 1.00
    standard_ref: str                     # "ISO 8528-1 §13" / "vendor-defined"

@dataclass
class SiteConditions:                     # temp_point 存錯 = 系統性高估容量
    altitude_m: float; ambient_c: float; temp_point: TempPoint

@dataclass
class Genset:
    id: str
    ratings: dict[RatingClass, Rating] = field(default_factory=dict)

    # TODO rating(rc)：查無該 class 要 raise，不要回 None、更不要回預設值
    # TODO site_rating_kw(rc, cond, method)
    #   RULE_OF_THUMB: 海拔 (alt-150)/300 檔 ×3%、溫度 (t-40)/5 檔 ×3%（負值取 0）
    #   MANUFACTURER_TABLE: 查 DERATE_TABLE 雙線性內插；若 cond.temp_point
    #     != AIR_FILTER_INLET → 照算但發 warning
    # TODO usable_avg_kw(rc, cond, method) = site_rating × max_avg_load_factor_24h
    # TODO runtime_quota_status(rc, hours_ytd) -> ("ok"|"warn"|"exceeded", 剩餘)
    #   warn 門檻 = 配額 × 0.8；無限額度回 ("ok", float("inf"))

DERATE_TABLE = {   # Cummins D-6453 Table A (off-grid)：(海拔 m, 進氣 °C) -> 係數
    (0, 20): 1.00, (0, 40): 0.99, (1000, 20): 0.92,
    (1000, 40): 0.87, (2000, 20): 0.80, (2000, 40): 0.74,
}

# TODO sfc_l_per_kwh(load_fraction)：效率內插 100→38%、75→36%、50→34%，
#      再除以 35.53 MJ/L
# TODO fuel_for_class_hours(site_kw, load_fraction, hours) -> 公升（dc-06 的輸入）
```

**驗收標準**

| 呼叫 | 期望 |
|---|---|
| `usable_avg_kw(ESP / COP, 海平面 20 °C, 表)` | **1925**（2750×0.70）/ **2100** |
| `site_rating_kw(ESP, 1000 m/40 °C, RULE_OF_THUMB)` | **≈ 2516** |
| 同上改 `MANUFACTURER_TABLE` | **≈ 2393**（差 123 kW / 4.5%） |
| 用 `TempPoint.OUTDOOR` 查廠商表 | **回值照算 + 發出 warning** |
| `runtime_quota_status(ESP, 165)` / `(PRP, 5000)` | **("warn", 35.0)** / **("ok", inf)** |
| `sfc_l_per_kwh(1.0)` / `(0.5)` | **≈ 0.267 / 0.298**（半載**必須更高**） |
| `fuel_for_class_hours(1500, 0.70, 48)` | **≈ 13,440 L** |

**加分題**：寫 `redundancy_fuel_penalty()`，比較「1 台帶 100%」與「3 台各帶 33%（N+1）」在 48 小時下的總耗油。你會算出**冗餘配置本身要多帶油**——每台都掉進低負載高 SFC 區。這是很多機房儲油量算不夠的原因。

## 自我檢核

**Q1. 供應商報價單上寫「Cummins DQLF，2750 kW」。你要不要照 2750 kW 規劃 IT 容量？**

??? note "答案"
    不要，而且這張報價單其實沒有指定容量。2750 是 **ESP** 額定，附帶兩個限制：一年最多 200 小時、24 h 平均負載不得超過 **70%**（＝ 1925 kW）；同一台機的 COP 額定只有 2100 kW。正確做法：先問 rating class → 乘場址降載係數 → 再乘該 class 的平均負載上限。**規格書沒寫 rating class，就等於沒寫容量。**

**Q2. 機房室外氣溫 32 °C，你查原廠降載表得到係數 0.99，於是回報「幾乎不用降載」。這個結論可能錯在哪？**

??? note "答案"
    錯在**量測點**。原廠 Table A 的橫軸是 **air filter inlet temperature**，不是室外溫度。機房通風不良時進氣可比室外高 10 °C 以上——32 °C 的室外可能對應 42 °C 的進氣，係數就不是 0.99。**你可能是自己的機房通風把自己的發電機降載了**，而型錄與氣象站都不會告訴你。所以 `ambient_c` 單獨存在沒有意義，必須綁 `measurement_point`。

**Q3.「這台機一年只能跑 200 小時」——這句話會讓你的資料模型長出什麼欄位，而且是什麼型別的欄位？**

??? note "答案"
    長出 `runtime_hours_ytd` + `quota_hours`（由 rating_class 決定）+ 按 `trigger` 分組累計（測試 / 真實停電 / commissioning）+「YTD > 配額 80%」告警。EPA 的非緊急運轉時數是第二套配額，所以分組累計是必要而非優化。
    **型別上的關鍵**：這是前五張卡第一個**存量**而非**狀態**的欄位。kVA、kA、開關位置、計時器設定都是「當下是什麼」，可覆寫可重讀；運轉小時是「已經消耗多少」，只增不減且跨年度重置。告警語意也不同：狀態欄位問「現在對不對」，存量欄位問「還剩多少、燒得多快」。
    **延伸**：本卡的母題變形是「額定不能脫離用途分級與場址條件」——接在 `dc-02` 量測條件、`dc-03` 時間、`dc-03b` 互鎖約束、`dc-04` 變更者之後，這是第五種。

---

**下一張**：`dc-05b` 起動時序、暫態性能與定期測試 —— 把 `genset_crank_to_stable_s = 6.5` 拆開，並處理 ISO 8528-5 G3 與 ATS 判定門檻對不齊的問題。
