---
id: dc-05b
title: 發電機起動時序與暫態性能（ISO 8528-5）
category: power
written_at: 2026-08-05
sources:
  - https://techcomm.kohler.com/techcomm/pdf/ISO%208528-5%20and%20Generator%20Transient%20Performance_WP.pdf
  - https://www.cat.com/en_US/by-industry/electric-power/Articles/White-papers/transient-performance-specifications-for-diesel-generator-sets.html
  - https://www.curtispowersolutions.com/nfpa-110-acceptance-testing
related: [dc-04, dc-05, dc-05c, dc-08]
---

# 發電機起動時序與暫態性能（Genset Start Sequence & Transient Performance）

[dc-05](diesel-generator.md) 談「這台機能出多少 kW」，屬於**穩態**問題。這張卡談**時間軸**：從市電消失到負載被接住，中間那 10 秒裡發生了什麼；以及加載瞬間電壓與頻率會晃多大、多久回來。[dc-04](ats-transfer-switch.md) 的模型裡有一個 `genset_crank_to_stable_s = 6.5`——今天把它拆開，並說明為什麼它不該是一個欄位。

> 原 `dc-05b` 涵蓋三個主題，初稿 12348 字元超過上限。**本卡只談時序與暫態性能**；NFPA 110 定期測試、30% 門檻與 wet stacking 移到 `dc-05c`。

## 六格

**拓撲位置**：不是新設備，是 [dc-04](ats-transfer-switch.md) 與 [dc-05](diesel-generator.md) 之間那條**時間軸**。上游是 ATS 送出的 engine start 接點，下游是 ATS 判定「發電機 ready」的門檻。

**容量單位**：**秒**（起動各段、恢復時間）與 **%**（電壓／頻率偏差）。這張卡沒有 kW。

**冗餘表達**：起動路徑的冗餘＝**雙起動電池組 + 雙起動馬達**，不是多一台機。三台 N+1 機共用一組充電器，起動路徑仍是 N。

**遙測介面**：Modbus／控制器事件記錄。關鍵不是即時值，是**事件序列**。

| 點位 | 型別 | 為什麼要 |
|---|---|---|
| `ts_start_signal` | timestamp | 全鏈時間軸的原點 |
| `crank_time_ms` | int | **逐月拉長 = 電池衰退的最早訊號** |
| `time_to_load_accept_ms` | int | NFPA Type 10 要比的那個數字 |
| `crank_attempt_count` | int | >1 即代表本次合規失敗 |
| `min_freq_hz` / `min_voltage_pu` | float | 加載瞬間谷值，對 ISO 8528-5 判定 |

**故障域**：起動失敗不會讓任何東西「立刻」掉——UPS 正在撐。它是**延遲引爆**的故障，後果在電池耗盡時才出現。全鏈第一個「故障與後果不同時發生」的設備。

**維護特性**：這條時間軸唯一的驗證手段是**實際觸發**——日常運轉不會暴露它變慢了，只有測試會（制度在 `dc-05c`）。

## 關鍵數字與計算

### 一、把 6.5 秒拆開：NFPA 110 自己就要求分段記錄

`genset_crank_to_stable_s = 6.5` 不該是一個欄位——**NFPA 110 驗收條文 7.13.4.1.4 明文要求分開記錄四段**：起動延時、crank 時間、達額定轉速的時間、以及所有開關轉到 emergency 位置達穩態的時間。標準自己就在說「這是四個數字」。

示範性拆解（**實際值必須從 commissioning 記錄取，不要抄這張表**）：

| 段落 | 秒 | 誰決定 |
|---|---|---|
| 起動繼電器閉合 + 起動馬達嚙合 | 0.3 | 硬體 |
| Crank 到起火（crank time） | 1.5 | **電池 + 燃油 + 溫度，會隨老化拉長** |
| 加速到 1800 rpm | 2.5 | 引擎與慣量 |
| AVR 建立電壓至 90% 並穩定 | 1.5 | 激磁系統 |
| 控制器判定 ready（需連續在窗內） | 0.7 | **韌體參數，可調** |
| **小計 T2** | **6.5** | |

接回 dc-04 的總時序：`TDES 3.0 + T2 6.5 + TDNE 1.0 + 機械轉換 0.09 = 10.59 s` > 10 s。**能砍的只有 TDES 與 TDNE**（NFPA 8.4.5 規定起動延時最低 1 秒），把 TDES 降到 1.5 s → 9.09 s 才過關。

**中間那 6.5 秒是物理，不是設定。** 而它會**隨時間變長**——`crank_time` 從 1.5 s 漂到 2.5 s，Type 10 合規就悄悄失效，而沒有告警會告訴你，除非你存了這個欄位的歷史。

### 二、Crank 循環的算術：第一轉就出局

NFPA 110 Table 5.6.4.2 規定 crank 循環：**cycle crank 三個循環共 75 秒**，或**連續 crank 45 秒**，之後控制器進 overcrank lockout。

```
3 次 crank × 15 s + 2 次 rest × 15 s = 45 + 30 = 75 s
```

看出問題了嗎——**第一次 crank 的 15 秒上限，本身就已經超過 Type 10 的整個 10 秒預算。**

> **Type 10 合規隱含一個沒寫出來的前提：「第一轉就要起來」。** 只要進到第二次 crank，這次事件必然不合規，即使機組最後成功起動、即使 overcrank 從未觸發。

告警設計上：`overcrank_lockout` 是**太晚的告警**（75 秒後才響），真正該監控的是 `crank_attempt_count > 1`——一次「合規上已失敗、但技術上成功」的起動，傳統 BMS 通常完全看不到。

最壞情況 UPS 要撐 `TDES 3.0 + overcrank 75 ≈ 78 s`，期間 ATS 不會切；典型雙轉換 UPS 滿載後備 5–15 分鐘，撐得住。**問題不是撐不撐得住，是這 78 秒有沒有人知道。**

### 三、ISO 8528-5 效能等級：G3 到底承諾了什麼

ISO 8528-5 把機組分成 G1–G4 四個**暫態效能等級**（G4 為使用者自訂、須雙方議定）。多數工業級機組標 G3。

| 參數 | G1 | G2 | G3 |
|---|---|---|---|
| 穩態頻率帶 βf | ≤±2.5% | ≤±1.5% | **≤±0.5%** |
| 穩態電壓偏差 δUst | ≤±5% | ≤±2.5% | **≤±1%** |
| 暫態頻率下降（突加負載） | ≤−15% | ≤−10% | **≤−7%** |
| 暫態頻率上升（100% 卸載） | ≤+18% | ≤+12% | **≤+10%** |
| 暫態電壓下降 | ≤−25% | ≤−20% | **≤−15%** |
| 頻率恢復時間 | — | — | **≤3 s** |
| 電壓恢復時間 | — | — | **≤4 s** |

（G3 柴油機的電壓包絡另記為 −15% / +20%。G1／G2 的恢復時間未能確認，需查原文，此處留空而非猜測。）

**這張表最重要的一件事，是它跟 10 秒完全無關。** ISO 8528-5 管「加載瞬間晃多大、多久回來」；Type 10 管「多久接上負載」。兩者**度量的是不同的鐘**——一台機可以 G3 合規但 Type 10 不合規，反之亦然。規格書寫成「G3, 10 秒起動」很常見，但那是**兩條獨立的驗收條件**。

**第二件事更有殺傷力**：G3 允許電壓掉到 −15% 並花 4 秒恢復。IT 負載有 UPS 擋著看不到；但**冷卻鏈通常不在 UPS 後面**——冰水主機、CRAH 風扇、水泵直接吃這 4 秒。壓縮機低電壓保護的動作範圍與這個包絡有重疊，所以「G3 合規」不等於「切換時冷卻不會跳」。必須拿實際的保護電驛設定去對，不能推論。（`dc-18` 會回頭處理。）

### 四、加載步階：為什麼「0→100% 單步」會讓 G3 失效

ISO 8528-5 的等級判定不是對著任意負載步階測的，而是綁定標準自訂的 **BMEP 分級步階**——引擎制動平均有效壓力越高，允許的單步加載百分比越小，分六個 power stage。

```
規格書 A：「符合 ISO 8528-5 G3」                → 用標準的 BMEP 步階判定，OK
規格書 B：「符合 G3，且須單步接受 0→60% 負載」  → 自訂步階
         → G1／G2／G3 全部不適用，依定義落入 G4，而 G4 沒有預設限值
```

**兩句話同時出現，那份規格書就自我矛盾。** 以為「G3 再加一個更嚴格的單步要求」是加碼，實際上是把整個等級判定的基礎抽掉。這條規則**可以直接寫成 CHECK 約束**：`custom_steps` 非空 → `class` 只能是 `G4`。

## 常見誤解

**以為「G3 且 10 秒起動」是一句話，但實際上那是兩個獨立且不可互相推論的驗收條件。** G3 機組完全可能因 ATS 的 TDES 設太長而 Type 10 不合規，反之亦然。驗收要**分兩份記錄、分兩次簽收**。

**以為規格書寫「G3」再加一句「須能單步接受 0→100% 負載」是更嚴格的要求，但實際上那樣寫會讓 G3 自動失效。** 只要規格自訂步階，G1／G2／G3 全部不適用，依定義落入 **G4——而 G4 沒有預設值**。

**以為 overcrank 告警就是起動失敗告警，但實際上它是 75 秒之後才響的事後通知。** 只要 `crank_attempt_count > 1`，這次起動在合規上就已經失敗——即使最終成功。**該告警的是「第二次嘗試」，不是「三次都失敗」。**

## 來源分歧

**crank／rest 循環各多少秒？** 引用 NFPA 110 Table 5.6.4.2 的來源給的是 **cycle crank 三循環共 75 秒、連續 crank 45 秒**（推得 15 s crank / 15 s rest）；另有二手部落格寫成 **10 秒 crank / 10 秒 rest**。前者直接引標準表格編號，可信度較高，本卡採用；但**你們機組控制器的實際設定值必須自己讀出來**，因為它決定 `crank_attempt_count > 1` 這條告警要在第幾秒觸發。

**G1／G2 的恢復時間限值**：Kohler 白皮書的表格自 ISO 8528-5:2022 Table 4 轉繪，二手轉繪的欄位對位有歧義，只有 G3 的 3 s／4 s 在正文被明確複述。**未取得原文前不填**，這比填一個猜的數字安全。

## 對資料模型的意涵

1. **起動不是一個時長欄位，是一串時間戳。** 建 `start_event(genset_id, ts_signal, ts_crank_start, ts_fired, ts_at_speed, ts_voltage_ok, ts_load_accepted, crank_attempt_count, result)`，所有秒數 **derived**。NFPA 7.13.4.1.4 本身就要求分段記錄，而 `crank_time` 的**趨勢**是電池衰退最早的訊號。存一個總秒數等於把最有預警價值的欄位丟掉。

2. **這是全鏈第一個「必須存歷史序列」的欄位。** dc-02～dc-05 的欄位問「現在是什麼」；`crank_time` 問「這半年變慢了多少」。它也不是 dc-05 那種存量，而是**趨勢量**——單筆讀值沒有意義，只有序列有意義。告警語意隨之不同：不是「超過門檻」，是「斜率為正且外推會超過門檻」。

3. **效能等級是複合鍵，不是 enum。** `transient_spec(genset_id, class, custom_steps, agreed_with_vendor_ref)` 配一條 CHECK：`custom_steps` 非空 → `class = G4`，擋掉上面那個最常見的規格書錯誤。同理 `iso8528_class` 與 `nfpa110_type` 必須是**兩個獨立欄位**，合成一個「等級」會讓驗收無法追溯。

4. **合規是 derived，而且要能回答「對誰而言」。** `nfpa_type10_ok` 要同時看 `total_s <= 10` **與** `crank_attempt_count == 1`。更進一步，暫態包絡「可接受」與否，對 UPS 後的 IT 負載與對直吃發電機的冷卻設備是**不同答案**——所以 `transient_tolerance` 應該掛在下游負載群組上，不是掛在發電機上。

## 該問 facility 的問題

1. **驗收記錄有沒有分開記 crank time、time to rated speed、time to load acceptance？** 拿得到原始表單嗎？那三個數字是 `genset_crank_to_stable_s` 的真值來源，也是日後判斷「有沒有變慢」的基線。
2. **規格書寫了 G3 的同時，有沒有另外寫自訂的單步加載百分比？** 若有，依 ISO 8528-5 的判定邏輯那已經是 G4，須雙方另行議定——供應商照哪一份測的？
3. **冰水主機、冷卻水泵、CRAH 接在 UPS 後面還是直接吃發電機？** 它們的低電壓保護設定多少伏、延時多久？對上 G3 的 −15% / 4 秒包絡會不會每次切換都跳？

## 動手練習（30–40 分鐘）

接續 dc-05 的 `Genset`，長出**時序**這一塊。核心約束兩條，型別要能擋住：**(a) 起動記錄存時間戳、秒數一律 derived；(b) 自訂步階時 class 只能是 G4。**

```python
from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import Enum

TransientClass = Enum("TransientClass", "G1 G2 G3 G4")

@dataclass(frozen=True)
class TransientSpec:
    iso_class: TransientClass
    custom_steps: tuple[float, ...] = ()      # 空 = 用 ISO 的 BMEP 步階
    def __post_init__(self):
        # TODO custom_steps 非空但 iso_class != G4 → raise ValueError
        ...

@dataclass
class StartEvent:
    ts_signal: datetime          # ATS 送出 engine start 接點
    ts_crank_start: datetime
    ts_fired: datetime           # 起火
    ts_at_speed: datetime        # 達額定轉速
    ts_voltage_ok: datetime      # AVR 建壓完成
    ts_load_accepted: datetime | None = None   # None = 起動失敗
    crank_attempt_count: int = 1

    # TODO crank_time_s / time_to_speed_s / total_s 一律 @property，不要存欄位
    #      total_s = (ts_load_accepted - ts_signal).total_seconds()
    # TODO nfpa_type10_ok() -> bool
    #      total_s <= 10 且 crank_attempt_count == 1
    #      —— 兩個條件都要。只看秒數會漏掉「第二次才起來但剛好夠快」的案例
    # TODO worst_case_ups_hold_s(tdes: float) -> float
    #      起動失敗時 UPS 要撐多久 = tdes + 75（3×15 crank + 2×15 rest）

@dataclass
class StartHistory:
    events: list[StartEvent]
    # TODO crank_time_series() -> list[tuple[datetime, float]]
    # TODO drift_slope_s_per_month() -> float   # 對 crank_time 做最小平方線性迴歸
    # TODO months_until_noncompliant(fixed_overhead_s: float) -> float | None
    #      fixed_overhead = TDES + 加速 + 建壓 + TDNE + 機械轉換（除 crank 外的總和）
    #      外推 crank_time 何時會使 total_s 超過 10；斜率 <= 0 回 None
```

**驗收標準**

| 呼叫 | 期望 |
|---|---|
| `TransientSpec(G3, (0.0, 0.6))` | **raise ValueError** |
| `TransientSpec(G4, (0.0, 0.6))` | 建得起來 |
| 用「一、」的拆解表建 `StartEvent`，`total_s` | **6.5**（0.3+1.5+2.5+1.5+0.7） |
| 上題 `nfpa_type10_ok()` | **True** |
| 上題改 `crank_attempt_count=2` 後再問一次 | **False**（秒數沒變，但合規失敗） |
| `worst_case_ups_hold_s(3.0)` | **78.0** |
| 12 筆 crank_time 從 1.5 每月 +0.05，`drift_slope_s_per_month()` | **≈ 0.05** |
| 上題 `months_until_noncompliant(8.0)` | **≈ 10**（8.0 + crank ≥ 10 需 crank ≥ 2.0，從 1.5 起算） |
| 斜率為負（crank 逐月變快）時 | **None** |

**加分題**：把 `months_until_noncompliant` 接成告警規則——「預估 3 個月內失去 Type 10 合規」。這是本卡真正的產出：**合規不是布林值，是一條會漂的曲線**。dc-04 的 `compliance_timeline()` 問「曾經在哪段時間不合規」，這裡問「還有多久會不合規」。

## 自我檢核

**Q1. 供應商說「我們的機組是 ISO 8528-5 G3，符合你們規格書要求的 10 秒起動」。這句話有什麼問題？**

??? note "答案"
    它把兩個度量不同東西的規格講成一件事。**G3 管加載瞬間的擾動**（電壓 ≤−15%、頻率 ≤−7%、電壓 4 秒／頻率 3 秒內恢復），**Type 10 管從市電失去到負載被接住的總時間 ≤10 秒**。兩者無推論關係：G3 機組配上 TDES 設 3 秒的 ATS 照樣不合規（3.0+6.5+1.0+0.09 = 10.59 s）。
    追問第二層：**規格書有沒有另外寫自訂加載步階？** 若寫了「須單步接受 0→100%」，依 ISO 8528-5 的判定邏輯這已是 G4 而非 G3，那份規格書自我矛盾。

**Q2. 你的發電機三次 crank 都沒起來，控制器進 overcrank lockout。從 ATS 送出起動訊號到那一刻過了多久？期間誰在撐？**

??? note "答案"
    `TDES 3.0 s + cycle crank 75 s（3×15 s crank + 2×15 s rest）≈ 78 s`。期間 ATS 不切，全靠 UPS 撐——典型雙轉換 UPS 滿載後備 5–15 分鐘，撐得住。
    **重點在反方向**：第一次 crank 的 15 秒上限本身就超過 Type 10 的整個 10 秒預算。只要進到第二次嘗試，這次起動在合規上必然已經失敗，即使最後成功、即使 overcrank 從未觸發。**overcrank 是 75 秒後的事後通知，不是預警。**

**Q3.「crank time 會隨電池與噴油系統老化而逐月拉長」——這會讓你的資料模型長出什麼欄位？而它跟 dc-05 的 `runtime_hours_ytd` 在型別上有什麼根本差別？**

??? note "答案"
    長出 `start_event` 這張**事件表**（`ts_signal` / `ts_crank_start` / `ts_fired` / `ts_at_speed` / `ts_voltage_ok` / `ts_load_accepted` / `crank_attempt_count`），所有秒數都是 derived。NFPA 7.13.4.1.4 本身就要求分段記錄，所以這不是過度設計。
    **型別上的根本差別**：`runtime_hours_ytd` 是**存量**——單一筆讀值就有意義（「還剩多少配額」），告警語意是「超過門檻」。`crank_time` 是**趨勢量**——單一筆讀值幾乎沒有意義（今天 1.8 秒是好是壞？不知道），只有**序列**有意義，告警語意是「斜率為正且外推會超過門檻」。所以它不能是 device 表上的一個欄位，必須是時間序列，監控系統要能對它做迴歸而不只是比大小。
    **母題延伸**：dc-02 量測條件、dc-03 時間、dc-03b 互鎖約束、dc-04 變更者、dc-05 用途分級——這是第六種：**有些欄位的意義只存在於它的歷史裡，當前值單獨拿出來是空的。**

---

**下一張**：`dc-05c` NFPA 110 定期測試與 wet stacking —— 30% 門檻的分母是哪個 kW、年度 load bank 要多大、測試如何吃掉 dc-05 的 200 h 配額。
