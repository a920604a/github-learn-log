---
id: dc-04
title: 自動切換開關 ATS（automatic transfer switch）
category: power
written_at: 2026-08-03
sources:
  - https://www.eaton.com/us/en-us/products/low-voltage-power-distribution-control-systems/automatic-transfer-switches/automatic-transfer-switch-fundamentals.html
  - https://www.se.com/us/en/faqs/FAQ000219583/
  - https://www.pnnl.gov/projects/om-best-practices/automatic-transfer-switches
  - https://www.onesto-ep.com/blog/complete-ats-transfer-time-specification-guide-with-codes/
  - https://www.onesto-ep.com/blog/pc-class-vs-cb-class-ats-iec-60947-6-1-selection-guide/
related: [dc-03b, dc-05, dc-08, dc-10]
---

# 自動切換開關（Automatic Transfer Switch, ATS）

前三張卡的設備都只有**一個**上游。ATS 是電力鏈上第一個**有兩個上游、但同時只有一個是活的**的設備：它盯著市電的電壓與頻率，掉了就叫發電機起動，等發電機穩了把負載甩過去，市電回來再甩回來。**它是整條鏈上第一個「拓撲會隨時間改變」的東西**——這件事會把你的資料模型從靜態圖打成有狀態機器。

## 六格

**拓撲位置**：上游兩路來源（市電／發電機、市電／市電、發電機／發電機，亦有三來源版）；下游是 LV 主配電盤 `dc-07` 或直接餵 UPS `dc-08`。

**容量單位**：安培（A），常見 100–5000 A。但真正該記的是**兩個時間**：轉換死區（ms）與全程轉換時間（s）。兩者差兩個數量級，混用是本卡最大的坑。

**冗餘表達**：ATS 是「把 N 變成 N+1」的裝置——但**它自己是 N**。真正 2N 要兩台各餵一條路徑；或用 bypass isolation ATS（旁路隔離型），本體可抽出維護而負載照供。

**遙測介面**：Modbus RTU/TCP 或 SNMP。

| 點位 | 型別 | 說明 |
|---|---|---|
| `source_available[N/E]` | bool | 各來源電壓／頻率是否在容許窗內 |
| `active_source` | enum | `NORMAL` / `EMERGENCY` / `NONE` |
| `position` | enum | 機構實際位置（與 `active_source` 可能不一致） |
| `last_transfer_ts` / `duration_ms` | ts / int | 事件時戳與實測死區 |
| `timer_TDES/TDNE/TDN/TDEN/TDEC` | int | 五個可程式計時器**設定值** |
| `engine_start_signal` | bool | 送給發電機的起動接點 |

**故障域**：**最反直覺之處**。上游兩條腿都健康時，ATS 自己壞掉照樣讓下游全滅——它把兩個獨立故障源合併成一個共同故障點。

**維護特性**：NFPA 110 要求每月 30 分鐘帶載測試、每年 4 小時 ≥30% 銘牌負載測試。ATS 是**「不定期演練就等於沒有」的設備**——它 99.9% 時間不動作，唯一驗證方式是主動觸發。

## 關鍵數字與計算

### 一、NFPA 110 Level 1 的 10 秒預算怎麼被吃掉

轉換時間不是一個數字，是五段計時器相加：

```
T1 感測延遲（起動前忽略窗 TDES）   0.5 – 3 s     可程式
T2 起動 + 爬速                     3 – 8 s（預熱）／up to 15 s（冷車）  硬體
T3 穩定判定（≥90% V、≥95% f）       0 – 60 s（TDNE）  可程式
T4 機構動作（死區）                 20 – 100 ms   硬體
──────────────────────────────────────────────
                                   合計必須 ≤ 10 s
```

代數字（現場常見設定）：

```
T1 = 3.0 s（原廠預設）
T2 = 6.5 s（預熱柴油機實測）
T3 = 1.0 s（原廠預設 TDNE）
T4 = 0.09 s
合計 = 10.59 s  →  超標 0.59 s
```

**只要把 T1 從 3.0 砍到 1.5 就回到 9.09 s。** 所有超標幾乎都出在**可程式參數**而非硬體：上面兩段硬體限制加起來最壞才 6.6 s，剩下 3.4 s 全是人設定的。**這意味著「這台 ATS 合不合規」不是設備屬性，是設定值屬性，而設定值會被韌體更新悄悄還原成原廠值。**

### 二、閉合轉換的 100 ms 窗口，台灣為什麼算得跟歐洲不一樣

閉合轉換（make-before-break）會讓兩個來源**短暫並聯**。ASCO 明寫「整段序列必須在 100 ms 內完成，以免影響台電側運轉」。原因不是電氣，是**法規身分**：並聯超過門檻，你就從「備援發電」變成「併網發電」，要簽併聯協議、加裝解聯保護。

```
台灣／美國 60 Hz：1 cycle = 1/60 = 16.67 ms  →  100 ms = 6.0 cycles
歐洲／中國 50 Hz：1 cycle = 1/50 = 20.00 ms  →  100 ms = 5.0 cycles
```

⚠️ **這就是為什麼「6 cycles」不能跨區搬。** 台灣是 60 Hz（亞洲少數），美規文獻的 cycle 數字可直接用；但看中國或歐洲資料時，同樣「6 cycles」是 120 ms，已經超窗。**資料模型裡 dead time 要存 ms，不要存 cycles。**

### 三、開放轉換的 8.5 秒，誰真的會痛

開放轉換有死區，但 ATS 通常在 UPS **上游**，所以 IT 負載完全無感（UPS 電池頂著）。真正吃到這 8.5 秒的是**沒進 UPS 的東西**——冰水主機、CRAH 風扇、水泵。

算一間 1 MW IT 負載的機房，若冷卻在轉換期間完全停擺：

```
房間 500 m² × 4 m 淨高 = 2000 m³
空氣密度 1.2 kg/m³      → 空氣質量 2400 kg
空氣比熱 1.005 kJ/(kg·K)
熱容量 = 2400 × 1.005 = 2412 kJ/K

8.5 秒內注入的熱 = 1000 kW × 8.5 s = 8500 kJ
ΔT = 8500 ÷ 2412 = 3.5 K
```

**8.5 秒漲 3.5 °C。** 進風 24 °C 會跳到 27.5 °C。但這是**只算空氣熱容、忽略機櫃金屬與地板熱慣量的下界估計**，實際慢一些。重點是方向：**冷卻鏈的痛點不在轉換瞬間，而在轉換後風扇重啟與冰水回溫的那幾分鐘。** 這也是為什麼 CRAH 風扇要不要進 UPS 是個真實的設計爭點。

### 四、回切延遲 TDEN 為什麼設 5–30 分鐘

市電剛恢復時往往不穩。若 TDEN = 0，市電在 10 分鐘內閃爍 5 次 → 5 次切出 + 5 次切回 = **10 次死區**，機械壽命也被啃掉 10 次（PC 級機構壽命約 6000–10000 次）。設 TDEN = 5 min 後，同樣 5 次閃爍只產生 1 次切出、1 次切回。

## 常見誤解

**以為 ATS 讓系統更可靠，但實際上它引入了一個新的單點故障。** 兩路上游各自健康，ATS 壞掉照樣全滅。它把「兩個獨立故障源」摺成「一個共同故障點」。要真的冗餘，得兩台 ATS 各走一條路徑，或用旁路隔離型。

**以為「轉換時間 100 ms」就是停電 100 ms，但實際上那只是機構死區。** 從市電掉到負載復電是 T1+T2+T3+T4，通常 6–10 秒；規格書上的 100 ms 是 T4。兩者差 100 倍，混用會讓 UPS 電池容量算錯兩個數量級。SENTOP 作者實測：控制器 log 報 87 ms，示波器在負載端量到 142 ms，差的 55 ms 來自下游接觸器跌落——**量測點不同，答案不同。**

**以為 ATS 的短路耐受是設備自己的屬性，但實際上它是「條件式」評等。** UL 1008 的 WCR 標示綁定**特定型式與額定的上游保護裝置**（該斷路器／熔絲額定不得低於 ATS 額定的 125%，除非有 100% 額定標示）。換了上游斷路器 WCR 就失效。這跟 `dc-03` 的「kA 不能脫離時間」是同一母題的第四種變形。

## 來源分歧

**分歧一：資料中心「必須」用閉合轉換嗎？**

- **部分廠商文案**：閉合轉換對資料中心、醫院、半導體廠是**強制**的。
- **Eaton / PNNL（中立來源）**：閉合轉換是**選項**之一，PNNL 用字是「usually found in applications such as data centers」——常見，不是必須。

實務判讀：ATS 在 UPS 上游時，開放轉換的死區被 UPS 電池吸收，IT 負載完全無感；此時閉合轉換買的是**機械／冷卻負載的無擾動**與**計畫性測試不擾動**，不是 IT 可用度。**把「強制」當真會多花冤枉錢；當純選配又會低估月度測試的擾動成本。**

**分歧二：PC 級的轉換時間到底幾毫秒？**

同一篇 SENTOP 文章裡出現三組互相打架的數字：`60–150 ms`、`80–150 ms`、`80–160 ms`；CB 級則有 `150–400 ms` 與 `200–500 ms` 兩組。**同一作者同一篇都對不起來，代表這些是體感區間不是型式試驗值。** 教訓：**任何 transfer time 進資料庫都必須帶來源（`nameplate`／`factory_test`／`field_measured`）與量測點**，否則你存的是傳聞。

**分歧三：兩套評等體系不能互換**

| | UL 1008（美規） | IEC 60947-6-1（國際／CNS 體系） |
|---|---|---|
| 分類軸 | 專用轉換開關 + WCR 標示 | **PC 級**（能載能切、不能斷故障）／**CB 級**（內建斷路器可斷故障） |
| 短路數字 | WCR（withstand & close-on） | PC 級看 Icw/Icm；CB 級看 Icu/Ics |

**WCR 與 Icw 不是同一件事**——WCR 要求「合閘進入故障」，比純靜態耐受嚴苛。台灣專案兩套標示可能同時出現在同一份型錄上，**規格書要指定依據哪一套標準與版本**。

## 對資料模型的意涵

1. **`active_source` 讓拓撲從靜態圖變成時間函數。** 前三張卡的上下游關係都是纜線（靜態）。ATS 之後不行了：下游的「我的電從哪來」隨時間變。NetBox 的 `PowerPort` 只能接一條 cable，**它結構上無法表達「A 或 B」**——這就是 `topic-10` 要處理的第一個真實斷點。你需要 `candidate_sources`（集合）+ `active_source`（當下）+ `source_history`（時間軸）三件套。

2. **五個計時器是「設定值」不是「屬性」，必須可版本控制。** `TDES/TDNE/TDN/TDEN/TDEC` 每一個都要帶 `value`、`set_by`、`set_at`、`rationale`。原因很具體：**韌體更新會把它們還原成原廠預設**，而原廠預設可能讓你從合規變違規（見上方 10.59 s 演算）。沒有變更歷史，你連「什麼時候開始不合規的」都答不出來。

3. **transfer 是一個有內部時間軸的事件，不是一次狀態變更。** 表 `transfer_event` 至少要有 `t0_source_loss`、`t1_engine_start`、`t2_source_stable`、`t3_transfer_complete`、`trigger`（`utility_fail`／`test`／`manual`）、`transition_type`。存成單一 `changed_at` 時戳，你就永遠算不出「這次是 T1 拖長還是 T2 拖長」——而修法完全取決於是哪一段。

4. **transfer time 欄位必須帶量測點與來源。** `transfer_time_ms` + `measurement_point`（`ats_output`／`load_bus`）+ `source` + `measured_at`。那 55 ms 的落差就是這組欄位存在的理由。

5. **`wcr_ka` 必須綁上游保護裝置。** 複合鍵：`wcr_ka` + `upstream_device_type` + `upstream_device_rating_a` + `standard`（`UL1008`／`IEC60947-6-1`）+ `class`（`PC`/`CB`）。上游斷路器一換，這筆評等就該被標記為 `stale` 而不是繼續顯示。

6. **故障域要能表達「合併」。** 前三張卡的故障域是樹狀往下傳播。ATS 是第一個**收斂節點**：兩個上游故障域在此合而為一。`fault_domain` 若只存 parent 指標會漏掉這件事，要能存「這個節點的下游可用度不高於自身可靠度，與上游數量無關」。這是 `topic-06` 的關鍵反例。

## 該問 facility 的問題

1. ATS 是 **PC 級還是 CB 級**、依 UL 1008 還是 IEC 60947-6-1 標示？WCR／Icw 綁的上游保護裝置型號是哪一顆？
2. 五個計時器**目前實際設定值**是多少？有紀錄嗎？**韌體更新後有沒有重新確認過**？
3. **CRAH 風扇與冰水泵有沒有進 UPS？** 沒有的話，轉換那 8.5 秒的溫升現場量過嗎？
4. 單台還是雙路徑？是不是旁路隔離型（維護時能不能不斷電）？

## 動手練習（30–40 分鐘）

接續 `dc-03b` 的 `MVFeederUnit` 狀態機，往下游長出 `TransferSwitch`。重點不是畫圖，是**把 10 秒預算變成可執行的斷言**。

```python
from dataclasses import dataclass, field
from enum import Enum

class Src(Enum):
    NORMAL = "normal"; EMERGENCY = "emergency"; NONE = "none"

class TsState(Enum):
    ON_NORMAL = "on_normal"; STARTING = "starting"
    TRANSFERRING = "transferring"; ON_EMERGENCY = "on_emergency"
    RETRANSFER_WAIT = "retransfer_wait"

@dataclass
class Timers:
    TDES: float = 3.0      # 起動前忽略窗 (s)
    TDNE: float = 1.0      # 發電機穩定後、轉換前 (s)
    TDN:  float = 0.5      # 開放轉換中性停留 (s)
    TDEN: float = 300.0    # 回切延遲 (s)
    TDEC: float = 300.0    # 無載冷卻 (s)
    set_by: str = "factory-default"
    set_at: str = "unknown"

@dataclass
class TransferSwitch:
    id: str
    timers: Timers = field(default_factory=Timers)
    transition_type: str = "open"          # open | closed | delayed
    mech_transfer_ms: float = 90.0         # T4，硬體
    genset_crank_to_stable_s: float = 6.5  # T2，硬體
    state: TsState = TsState.ON_NORMAL
    active_source: Src = Src.NORMAL

    # TODO total_transfer_time_s() -> float
    #      開放轉換 = TDES + crank + TDNE + TDN + mech/1000
    #      閉合轉換 = TDES + crank + TDNE + mech/1000（無中性停留）
    # TODO nfpa110_level1_compliant() -> tuple[bool, float, str]
    #      回傳 (是否 ≤10s, 實際秒數, 哪一段最該砍)
    # TODO parallel_window_cycles(hz: float) -> float
    #      閉合轉換才有意義；hz=60 台灣，hz=50 歐陸
    # TODO simulate(events) -> list[dict]
    #      吃 [("utility_loss", 0.0), ("utility_return", 420.0)]
    #      吐出 transfer_event 列，每列含 t0/t1/t2/t3 與 dead_time_ms
```

再寫一個純函式驗證第三段演算：

```python
def air_temp_rise_k(it_load_kw, outage_s, room_m3=2000.0,
                    rho=1.2, cp=1.005) -> float:
    ...  # 回傳 ΔT (K)
```

**驗收標準**

| 呼叫 | 期望 |
|---|---|
| `total_transfer_time_s()` 預設值 | **11.09**（3.0+6.5+1.0+0.5+0.09） |
| `nfpa110_level1_compliant()` 預設值 | `(False, 11.09, "TDES")` |
| `TDES=1.5, TDN=0.0` 後重算 | `(True, 9.09, ...)` |
| `transition_type="closed"` 預設值 | **10.59**（少掉 TDN） |
| `parallel_window_cycles(60)` 當 `mech_transfer_ms=100` | **6.0** |
| `parallel_window_cycles(50)` 同上 | **5.0** |
| `air_temp_rise_k(1000, 8.5)` | **≈ 3.5** |
| `simulate([...])` 回傳長度 | **2**（切出 + 回切） |

**加分題**：把 `Timers` 改成帶歷史的 `list[TimerSetting]`，每筆有 `set_at`／`set_by`／`values`，然後寫 `compliance_timeline()`，印出「這台 ATS 在哪些時間區間是不合規的」。**這才是 ATS 資料模型的真正產出**——不是它現在合不合規，而是**它曾經在哪段時間偷偷不合規過**。明天 `dc-05` 柴油發電機接在這裡：`genset_crank_to_stable_s` 那 6.5 秒是哪來的、憑什麼是這個數字。

## 自我檢核

**Q1. 規格書寫「transfer time < 100 ms」，你要不要據此把 UPS 電池最小放電時間設成 1 秒？**

??? note "答案"
    絕對不要。100 ms 是**機構死區 T4**，不是全程轉換時間。從市電掉到負載復電是 T1(感測) + T2(起動爬速) + T3(穩定判定) + T4，典型 6–10 秒，NFPA 110 Level 1 的硬上限就是 10 秒。差 100 倍。UPS 電池要頂的是**全程**，還要留發電機第一次起動失敗的重試餘裕。此外量測點也會改變答案——控制器 log 87 ms 但負載端示波器 142 ms 是實測過的落差。

**Q2. 兩路市電都健康、發電機也正常，為什麼加了 ATS 之後系統可用度反而可能變差？**

??? note "答案"
    因為 ATS 是**收斂節點**：兩個原本獨立的故障域在它這裡合併。上游再多條腿，只要都經過同一台 ATS，這台 ATS 的可靠度就是下游可用度的上限。前三張卡的故障域都是往下傳播的樹，ATS 是第一個把樹「收口」的設備。解法是雙路徑各配 ATS，或用旁路隔離型讓本體可抽出維護。**這是 `topic-06` 故障域建模最重要的反例：故障域不是只會分岔，也會匯流。**

**Q3.「同一台 ATS，昨天合規、今天不合規，硬體一顆螺絲都沒動」——這句話會讓你的資料模型長出什麼欄位？**

??? note "答案"
    長出**帶時間軸的設定值歷史**，而不是設定值本身。合規與否取決於 TDES/TDNE/TDN 三個可程式計時器（硬體 T2+T4 最壞才 6.6 s，剩下 3.4 s 全是人設的），而**韌體更新會把它們悄悄還原成原廠預設**。所以要 `timer_setting(ts_id, name, value, set_by, set_at, rationale, firmware_version)` 這種一列一次變更的表，配上 `compliance_timeline()` 查詢。
    **延伸**：這是「單一欄位無法承載一個事實」的第四種變形——`dc-02` 銘牌值不能脫離量測條件、`dc-03` kA 不能脫離時間、`dc-03b` 位置不能脫離互鎖約束，今天是**設定值不能脫離時間與變更者**。四張卡四種變形，同一個母題。

---

**下一張**：`dc-05` 柴油發電機（diesel generator）
