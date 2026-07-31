---
id: dc-03b
title: LSC 服務連續性分級與抽出式斷路器互鎖
category: power
written_at: 2026-07-31
sources:
  - https://www.se.com/ie/en/faqs/FA402828/
  - https://productinfo.se.com/masterclad_mv_switchgear_ib/6055-30-masterclad-15kv-mv-switchgear-ib/English/6055-30%20Masterclad%20MV%20Switchgear%20Indoor%20(bookmap)_DD00646805.xml/$/Section6-CircuitBreakerSectionInter-58DD6EC7
  - https://chinadegatech.com/five-prevention-interlocks-of-medium-voltage-switchgear/
  - https://payapress.com/iec-62271-200-internal-arc-lsc-and-type-tests/
related: [dc-03, dc-04, dc-07]
---

# LSC 服務連續性分級與抽出式斷路器互鎖（LSC Category & Withdrawable CB Interlocks）

[中壓開關設備](mv-switchgear.md) 那張卡講的是「故障時多快被切斷」。這張講的是另一半：**平常要維護它時，得先關掉多少東西**，以及**櫃體用什麼機構強迫你按正確順序操作**。前者叫 LSC 分級，是採購時就固化的屬性；後者叫互鎖，是一台每天都在跑的狀態機。兩者合起來決定你的機房能不能「不停機做維護」。

## 六格

**拓撲位置**：不是新設備，是 `dc-03` 那台櫃子的**維護面向**。每個 functional unit（饋線間隔）各有自己的 LSC 分級與互鎖鏈。

**容量單位**：這裡的「容量」是**時間**——每年因維護而必須停電的小時數。LSC 分級直接乘進這個數字（見下方演算）。

**冗餘表達**：LSC2B 讓**單一匯流排**就具備 concurrent maintainability 的一半；LSC1 則逼你非得靠 2N 拓撲才能維護，等於**用 capex 買回櫃體省下的錢**。

**遙測介面**：位置與狀態靠兩組獨立輔助接點——**TOC**（truck-operated contacts，車體位置）與 **MOC**（mechanism-operated contacts，斷路器分合）。IEC 61850 對應 `XCBR.Pos`（斷路器）與 `CSWI` / 車體位置點。**兩組會不一致，不一致本身就是告警。**

**故障域**：互鎖失效不會立刻停電，它把風險延後到**下一次有人操作時**才爆。這是本卡跟其他設備最大的不同——**故障域是人與時間，不是電路**。

**維護特性**：互鎖機構本身是機械件，會磨損、會被人為 defeat（拆掉限位塊趕工期）。年度檢查必須**逐條驗證互鎖仍會擋**，不是看它還在。

## 關鍵數字與計算

**一、LSC 分級換算成年度停電小時**

假設一面板 12 個饋線間隔，每個間隔的斷路器每年做 1 次 4 小時保養：

```
LSC1  ：開任一可及隔室 → 其他 functional unit 也得停
        → 全盤停電 12 次 × 4 h = 48 h/年（整盤）
LSC2B ：匯流排、相鄰間隔、該回路電纜都可維持帶電
        → 全盤停電 0 h/年，每次只影響該饋線 4 h
```

換算可用度：

```
LSC1 全盤計畫停電 = 48 ÷ 8760 = 0.548%  →  可用度 99.452%
四個 9（99.99%）全年預算 = 8760 × 0.0001 = 0.876 h ≈ 52.6 分鐘
48 ÷ 0.876 ≈ 54.8
```

**LSC1 光是計畫性保養就吃掉四個 9 預算的 55 倍。** 這不是可靠度問題、不是故障率問題——是採購當天勾錯一個分類欄位的問題，而且十五年內無法修正。

**二、互鎖狀態空間：合法組合遠少於笛卡兒積**

三個獨立變數：車體位置（REMOVED / DISCONNECTED / TEST / CONNECTED）× 斷路器（OPEN / CLOSED）× 接地開關（OPEN / CLOSED）= `4 × 2 × 2 = 16` 種組合。

套上互鎖規則（見下表）後：

```
CONNECTED   ：接地開關必須開 → 合法 2（斷路器開/合）
TEST        ：ES 開 → 2；ES 合 → 斷路器只能開 → 1   小計 3
DISCONNECTED：同 TEST                                小計 3
REMOVED     ：抽出時彈簧強制洩放，斷路器只能開 → 2
合法 = 2 + 3 + 3 + 2 = 10 / 16   →  非法 6，佔 37.5%
```

**超過三分之一的組合是非法的**，所以這三個值**不能存成三個獨立欄位**——存成三欄就代表資料庫允許那 6 種物理上不可能發生的狀態被寫進去。必須是「複合狀態 + 轉換守衛」。

⚠️ 但這 10 這個數字**是我依下方規則推出來的，不是標準規定的**。`DISCONNECTED + 斷路器合閘` 是否允許各廠不同（Degatech 的敘述允許，Schneider Masterclad 因抽出時洩放彈簧而實質不允許）。**真正的教訓是：合法集合要從廠商的 interlock schedule 讀出來，不能寫死在你的程式裡。**

**三、抽拉操作的人身暴露時間**

```
12 間隔 × 每年 1 次保養 × 每次 2 趟（抽出＋插入）= 24 次抽拉/年
本地手搖每趟人站在櫃前約 2 分鐘 → 48 人·分鐘/年 曝露在電弧邊界內
```

抽拉是中壓現場**入射能量最高的例行動作**（櫃門雖關，但機構在動、接觸子在分合）。改用遙控抽拉裝置把人移到邊界外 → 曝露歸零。這與 `dc-03` 的入射能量計算是同一件事的兩個把手：**那邊降能量，這邊降暴露時間。**

⚠️ **地區差異**：台灣現場（承襲中國 GB 3906 / CNS 系統的用語）講的是**「五防」**——防帶負荷拉合隔離開關、防誤分合斷路器、防接地開關合閘時送電、防帶電合接地開關、防誤入帶電間隔。IEC / IEEE 文件裡沒有「五防」這個詞，只有逐條列出的 interlock schedule。**內容大致對應，但你去 IEC 62271-200 裡搜 "five prevention" 是搜不到的**——跟 facility 溝通時用五防，寫規格書時用互鎖條列。

## 互鎖規則表（守衛條件）

| 代號 | 規則 | 防的是 |
|---|---|---|
| R1 | 斷路器必須在 OPEN 才能移動車體 | 帶負荷插拔主接觸子 |
| R2 | 移動途中不得合閘 | 半接觸狀態下合閘 |
| R3 | CONNECTED 且合閘時不得抽出 | 帶負荷抽出 |
| R4 | 接地開關只能在 TEST 位置或更外側合閘 | 帶電合接地開關 |
| R5 | 接地開關合閘時不得合斷路器 | 對接地回路送電 |
| R6 | 車體抽離間隔時強制洩放分合閘彈簧 | 離櫃後的意外動作 |
| R7 | 抽出時遮板（shutter）自動落下遮蔽固定接觸子 | 誤入帶電間隔 |

R7 是 IEEE C37.20.2 對 **metal-clad** 的硬性構造要求；IEC 62271-200 則把它折進 **PM/PI 隔板等級**（PM＝金屬隔板，接地連續性最佳；PI＝絕緣材隔板）。

## 來源分歧：LSC2 的分類法，以及 metal-clad ≠ LSC2B

**分歧一：LSC2 是不是一個獨立等級**

- **Schneider FAQ（IEC 原文立場）**：等級是 LSC1 與 **LSC2**；只有當「連接隔室以外的隔室也可及」時，才加後綴成 LSC2A / LSC2B。**LSC2 本身是完整的答案**。
- **多數廠商型錄與工程文獻**：直接把 LSC1 / LSC2A / LSC2B 並列成三個等級，LSC2 消失。

實務影響：規格書若只寫「LSC2」，供應商可能交沒有獨立斷路器隔室的櫃子而仍然合規。**要寫就寫到後綴，並同時指定 PM/PI。**

**分歧二：metal-clad 等不等於 LSC2B**

- **廠商業務常見說法**：metal-clad 就是 LSC2B。
- **IEC 側說法**：IEC 62271-200 已**廢除**「metal-clad / compartmented / cubicle」這組構造分類，改用「隔室可及性」的 LSC 分類。兩套是不同的判定軸，metal-clad 是 IEEE 的構造規範（抽出式＋接地金屬隔板＋自動遮板），LSC 是 IEC 的後果分類。

**建議問法**：不要問「這是不是 metal-clad」，改問「**依 IEC 62271-200 標到哪一級 LSC、隔板是 PM 還是 PI、型式試驗報告在哪**」。

## 對資料模型的意涵

1. **`lsc_category` 是 functional unit 的屬性，不是整面板的屬性。** 同一面板裡進線間隔與饋線間隔可以不同級。欄位組：`lsc_category`（`LSC1` / `LSC2` / `LSC2A` / `LSC2B`）＋ `partition_class`（`PM` / `PI`）＋ `accessible_compartments`（集合）。三者缺一就無法回答「維護這格要停掉誰」。

2. **停電影響範圍是查詢，不是人腦。** `maintenance_impact(unit_id)` 應該從 `lsc_category` 推出受影響 unit 集合：LSC1 → 全盤；LSC2B → 只有自己。**這個查詢就是 concurrent maintainability（`topic-05`）的可執行定義**，也是變更審查時系統能自動反對人的地方。

3. **位置不是 boolean。** 千萬別用 `installed: bool`。要 `position: enum{REMOVED, DISCONNECTED, TEST, CONNECTED, TRANSIT}` ——**`TRANSIT` 不可省**，抽拉手把轉到一半那 90 秒是真實存在的狀態，且正是最危險的時刻。少了它，事件時間軸會出現無法解釋的空白。

4. **狀態轉換要有守衛，而且守衛是資料不是程式碼。** R1–R7 應該存成可查詢的規則列（`rule_id`, `guard_expr`, `vendor`, `verified_at`），因為**它們隨廠商而異**（見上方分歧）。寫死在 Python `if` 裡的那一刻，你就承諾了全廠只會有一家供應商。

5. **TOC 與 MOC 是兩個獨立點位，要能表達「互相矛盾」。** `position_source` 與 `breaker_state_source` 各自帶時戳與品質旗標。「TOC 說 CONNECTED、MOC 說 CLOSED，但電流量測是 0 A」——三取二的矛盾偵測只有在三者分開存時才寫得出來。

6. **互鎖驗證是有到期日的事實。** `interlock_verified_at` + `interlock_defeated`（布林＋原因＋核准人）。互鎖被人為 defeat 是真實會發生的事，模型裡沒有這個欄位不代表現場沒有這件事，只代表你看不見。

## 該問 facility 的問題

1. 每一格的 **LSC 等級與 PM/PI 隔板**分別是什麼？型式試驗報告有沒有實體？
2. 有沒有**遙控抽拉裝置**？沒有的話，抽拉時人站在哪、穿什麼等級的 PPE？
3. 互鎖**多久驗證一次**？有沒有「逐條測它真的會擋」的紀錄，還是只目視檢查機構還在？

## 動手練習（30–40 分鐘）

接續 `dc-03` 的 `MVFeederUnit`，把它從薄類別長成狀態機，並在 `MVSwitchgear` 上加 LSC 查詢。

```python
from enum import Enum
from dataclasses import dataclass, field

class Position(Enum):
    REMOVED = "removed"; DISCONNECTED = "disconnected"
    TEST = "test"; CONNECTED = "connected"; TRANSIT = "transit"

class LSC(Enum):
    LSC1 = "LSC1"; LSC2 = "LSC2"; LSC2A = "LSC2A"; LSC2B = "LSC2B"

@dataclass
class MVFeederUnit:
    id: str
    lsc: LSC = LSC.LSC2B
    partition_class: str = "PM"          # PM | PI
    position: Position = Position.CONNECTED
    breaker_closed: bool = False
    earth_switch_closed: bool = False
    downstream_id: str | None = None
    clearing_time_s: float = 0.2
    # TODO is_legal() -> bool                   套 R1–R7 判斷目前組合合不合法
    # TODO try_transition(**changes) -> bool    非法就拒絕並回傳原因，不要拋例外吞掉
    # TODO enumerate_legal_states() -> list     窮舉 16 種，回傳合法的
```

`MVSwitchgear` 上加：

```python
    # TODO maintenance_impact(unit_id) -> set[str]
    #      LSC1  → 回傳全部 unit id
    #      LSC2B → 回傳 {unit_id}
    # TODO annual_planned_outage_h(hours_per_unit=4.0) -> float
```

**驗收標準**

| 呼叫 | 期望 |
|---|---|
| `enumerate_legal_states()` 長度 | **10**（非法 6） |
| `try_transition(position=CONNECTED)` 當 `breaker_closed=True` | 拒絕，理由含 `R1` |
| `try_transition(earth_switch_closed=True)` 在 `CONNECTED` | 拒絕，理由含 `R4` |
| `try_transition(breaker_closed=True)` 當 `earth_switch_closed=True` | 拒絕，理由含 `R5` |
| 12 個 LSC1 unit 的 `annual_planned_outage_h()` | **48.0** |
| 同上 LSC2B，全盤停電時數 | **0.0** |
| `maintenance_impact("F3")`（LSC1／12 格） | 長度 **12** |

**加分題**：把 `try_transition` 每次呼叫寫進一個 `transitions` list（`from_state`, `to_state`, `rule_violated`, `ts`），然後印出從 CONNECTED 走到「可以動手維護」的完整合法路徑。答案應該是 `CONNECTED → (分閘) → TRANSIT → TEST → (合接地開關) → TRANSIT → REMOVED`——**六步，不是一步**。這串就是明天 `dc-04` ATS 切換序列的同一種結構。

## 自我檢核

**Q1. 一面 12 格的 LSC1 開關設備，每格每年保養 4 小時。為什麼這面板不可能達成 99.99% 可用度？**

??? note "答案"
    LSC1 開任一可及隔室都得停掉其他 functional unit，所以 12 次保養 = 12 次**全盤**停電 = 48 h/年，佔全年 0.548%，可用度上限 99.452%。四個 9 的全年預算只有 52.6 分鐘，**48 小時是它的 55 倍**。這是計畫性停電，跟故障率完全無關——買錯分級，可靠度工程救不回來。

**Q2. 為什麼「metal-clad」不能直接當成「LSC2B」寫進規格書？**

??? note "答案"
    兩者是不同標準的不同判定軸。metal-clad 是 IEEE C37.20.2 的**構造規範**（抽出式、接地金屬隔板、自動遮板）；LSC 是 IEC 62271-200 的**後果分類**（開某隔室時還有誰能保持帶電）。IEC 已廢除 metal-clad / compartmented / cubicle 這組構造分類改用 LSC。規格書要同時寫 **LSC 等級 + PM/PI 隔板 + 依據標準版本**，別靠業務口頭換算。

**Q3. 「抽出式斷路器有 10 種合法狀態、6 種非法」這件事，會讓你的資料模型長出什麼？**

??? note "答案"
    位置／斷路器／接地開關**不能是三個獨立欄位**——那等於允許 6 種物理不可能的狀態被寫進資料庫。要長出：(a) `position` 是 enum 且**必須含 `TRANSIT`**；(b) 一張可查詢的守衛規則表（R1–R7）而不是寫死的 `if`，因為合法集合隨廠商而異；(c) 一個 `try_transition()` 入口，所有狀態變更都得過它。
    **延伸**：這是「狀態不能脫離約束」第一次出現，跟 `dc-02` 的「銘牌值不能脫離量測條件」、`dc-03` 的「kA 不能脫離時間」是同一個母題的第三種變形——**單一欄位無法承載一個事實**。

---

**下一張**：`dc-04` 自動切換開關 ATS（automatic transfer switch）
