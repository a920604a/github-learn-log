---
id: dc-14
title: 機櫃電源 rack PDU（basic / metered / switched）
category: power
written_at: 2026-08-31
sources:
  - https://www.se.com/ph/en/faqs/FA156194/
  - https://www.raritan.com/blog/detail/how-to-calculate-current-on-a-3-phase-208v-rack-pdu-power-strip
  - https://netboxlabs.com/docs/netbox/models/dcim/poweroutlet/
  - https://github.com/netbox-community/netbox/discussions/8028
  - https://www.eaton.com/us/en-us/catalog/backup-power-ups-surge-it-power-distribution/eaton-metered-outlet-rack-pdu.html
related: [dc-11, dc-12, dc-13, dc-15, dc-16, topic-01, topic-04, topic-09, topic-10]
---

# 機櫃電源 rack PDU（rack power distribution unit）

機櫃後方那根直立的插座條（0U，貼著側柱），或橫躺在 1U／2U 的那條。上游一條 whip 從 [dc-12](rpp-remote-power-panel.md) 的 RPP 分路或 [dc-13](busway-and-tap-off-box.md) 的插接箱下來，下游是伺服器電源供應器。**電力鏈到這裡走完了**——再往下就是 IT 資產，不再是設施。

而它是整條鏈上第一個**電流不能相加**的設備。

## 六格

### 拓撲位置
上游：RPP 分路 → whip → rack PDU 進線（NEMA L21-30P／CS8365C／IEC 60309），或 busway 插接箱直接下來。
下游：伺服器 PSU（C13／C19 跳線）。0U 垂直式貼機櫃側柱不佔 U；1U／2U 水平式佔 U，且**佔的那幾 U 是機櫃容量的另一個維度**。

### 容量單位
**四個維度，互不換算**：進線每相電流（A）／每 bank 斷路器電流（A）／每插座電流（A）／插座數與 U 空間（個、U）。
銘牌與可用值的關係見下節——**同一個插頭型號可能對應兩個不同的 derated 值**。

### 冗餘表達
2N 在櫃內＝ A、B 兩條 rack PDU 接不同上游。**關鍵是容量規劃時要假設另一條離線**（Raritan 明寫這一點）：兩條各 50% 看起來很健康，實際上任一條掉電就是 100% 落在剩下那條。
N+1 在這一層通常不成立——rack PDU 沒有「備援的第三條」這種東西，只有 A／B。

### 遙測介面
| 協定 | 典型點位 |
|---|---|
| SNMP v3 | 每相電流／電壓、每 bank 電流、每插座電流與 kWh、進線斷路器狀態 |
| Redfish（`PowerEquipment/RackPDUs`） | 同上，物件化；outlet on/off/cycle 是 **write** |
| Modbus TCP | 部分機型，暫存器對應各廠商自訂 |

計量等級：outlet-metered 機型宣稱 billing-grade ±1%，對應 **IEC 62053-21 class 1**。ANSI C12.20 的 class 0.2／0.5 更嚴，是電錶等級——**兩套標準的 class 數字不可互相比較**。

### 故障域
- 單一插座（switched 機型遠端關閉或內部故障）→ 一台伺服器
- **bank 斷路器跳 → 該 bank 的所有插座**，不是整台。這一級最容易被漏掉
- 整台掉 → 該櫃 A 側全部；若對側 B 條也在同一上游分路下，就是整櫃

### 維護特性
更換必須逐條拔跳線，實質等於整櫃 A 側停電。0U 垂直式換裝需要側邊淨空。韌體升級時 **switched 機型的 outlet 狀態是否保持**是採購要問的問題（多數保持，但要書面確認）。

## 關鍵數字與計算

### 一、線間負載的電流不能相加（本卡的核心）

北美 208 V 三相 rack PDU 的插座是**線間（line-to-line）**接法，分成三個 bank：L1-L2（XY）、L2-L3（YZ）、L3-L1（XZ）。

在 L1-L2 掛 10 A、在 L2-L3 掛 10 A，L2 上的電流**不是 20 A**：

```
兩個線間負載的相位差 120°，共用相的電流是向量差：
I_L2 = √(I₁₂² + I₂₃² + I₁₂·I₂₃)          （功率因數 1）
     = √(10² + 10² + 10×10) = √300 = 17.32 A
```

L1 仍是 10 A、L3 是 10 A、L2 是 17.32 A。**這個數字用心算算不出來，用簡單的 Excel 加總也算不出來**，Raritan 為此做了一份試算表工具。

三個 bank 都平衡時退化成熟悉的形式：每 bank 16 A → 每相 √3 × 16 = **27.71 A**。

### 二、binding 是誰：兩台機器，兩個答案

**30 A 機型**（NEMA L21-30P，3 個 20 A bank 斷路器）：

```
進線側：√3 × 208 × 24 A（30 derated）= 8 646 VA
斷路器側：3 × 208 × 16 A（20 derated）= 9 984 VA
min → 8 646 VA，binding = 進線線材
```

**50 A 機型（APC AP8868，CS8365C，3 個 20 A bank）**：

```
進線側：√3 × 208 × 40 A = 14 411 VA
斷路器側：3 × 208 × 16 A = 9 984 VA  ← Schneider 明寫「容量受輸出斷路器限制，不是進線插頭」
min → 9 984 VA ≈ 10.0 kW，binding = bank 斷路器
```

**同一個 `binding` 欄位，兩台機器指向兩個不同的維度。** 這正是 W35 連貫性檢視 #1 要的東西。

### 三、同一顆插頭，兩個 derated 值

| 進線插頭 | 銘牌 | derated | 差別在哪 |
|---|---|---|---|
| NEMA L21-30P / L15-30P | 30 A | 24 A | — |
| Hubbell CS8365C | 50 A | **35 A** | 只有 3 個分路斷路器 |
| Hubbell CS8365C | 50 A | **40 A** | 有 6 個分路斷路器 |
| IEC 60309 60 A | 60 A | **45 A** | 進線導體 6 AWG（16.2 kVA） |
| IEC 60309 60 A | 60 A | **48 A** | 進線導體 4 AWG（17.3 kVA） |

**插頭型號推不出容量。** 後兩列差的是一個從外觀完全看不到的線規，而它值 1.1 kVA。

### 四、UL 規則改變讓同一台硬體掉了 20%

AP7868 標 12.5 kW（3 × 208 × 20），AP8868 標 10.0 kW（3 × 208 × 16）。Schneider 自己說明：**內部斷路器是同一型（20 A、UL 489、branch rated、hydraulic-magnetic），連時間延遲曲線都一樣**，差別只是 UL 後來強制所有元件依 80% 連續負載降載。

**這是 `derating_basis` 最乾淨的一個例子**：兩台實體相同的機器，銘牌差 2.5 kW，理由不在硬體上，在一份規範的版本裡。

### 五、不平衡的代價

30 A 機型（8.6 kVA），若所有伺服器都插在 L1-L2 那個 bank：

```
bank 斷路器 16 A × 208 V = 3 328 VA
3 328 / 8 646 = 38.5%
```

**儀表板顯示「利用率 38%」，而你已經不能再插了。** L3 完全沒有負載。這是 [dc-11](pdu-floor.md) 的 pole 故事在機櫃層的重演，只是這次擱置的不是極數而是相。

> **地區差異**：以上皆為北美 208 V delta 情境。台灣機房常見 380Y/220V wye，插座是**相對中性**（單相 220 V），此時電流可以直接相加，向量問題不存在——**但 wiring mode 決定用哪套算法，這件事必須是欄位**。插座本體：IEC 60320 C13 國際額定 10 A、C19 額定 16 A；北美 UL 列名常見標到 15 A／20 A。台灣走 CNS 對應 IEC，**但實際採購品的標示要逐張看**，本卡未查證 CNS 條號。

## 常見誤解

**以為插座上的電流可以相加得到每相電流，但實際上線間負載要向量加法。** 10 A + 10 A 共用相是 17.32 A，不是 20 A，也不是 15 A。相反地，wye 接法（220 V 對中性）就是直接相加——**兩種算法都對，錯的是不知道自己在哪一種**。

**以為 rack PDU 的「A／B」是三相的 A 相 B 相，但實際上在雙路供電語境裡 A／B 是兩條饋線。** 這兩個命名空間在同一張表上會撞：一個機櫃有 `A 側 rack PDU`，它自己內部有 `feed_leg A/B/C`。NetBox 的 `feed_leg` 恰好也用 A/B/C，社群裡已經有人提議改成 L1/L2/L3。**在 schema 裡不要讓這兩個字共用一個列舉。**

**以為「50 A 的 PDU 就能給 50 A」，但實際上要過兩道閘。** 先被 UL 的 80% 降載扣一次，再被內部 bank 斷路器扣一次——AP8868 每相實際上限 27.7 A。而且**同一顆 CS8365C 插頭依內部斷路器數量有 35 A 與 40 A 兩種答案**。

## 對資料模型的意涵

1. **`feed_leg` 必須是一對，不是一個——而基數由 wiring mode 決定。** NetBox 至今（v4.6.9 文件）只有單一 `feed_leg: A|B|C`，官方例子也是 wye 式的「1–16 接 A、17–32 接 B」。discussion #8028（2021-12）明確要求加上 A-B／B-C／C-A，四年多後仍未實作，社群的結論是「只能用 custom field」。**這是 `topic-10`（NetBox 模型的斷點）的第一個具體條目**：`Outlet.legs: tuple[Leg,...]`，`wiring="delta"` 時長度必須是 2、`"wye"` 時必須是 1。又一個 W35 判準下的模式欄位——**它改變的是欄位的基數，不是值**。

2. **每相電流不能存，要算，而且算法依賴 wiring mode。** `line_currents()` 是向量和的結果；存成欄位會在有人把伺服器換一個 bank 那天靜默說謊，而**沒有任何遙測會變**（PDU 自己量到的是對的，你的資料庫是錯的）。這是「算得出來的一律不存」的第 N 次，但這次的新意是：**算法本身是分岔的**，所以 `wiring` 不是裝飾欄位而是計算的前提。

3. **第四種 `CapacityReport`，而 binding 會跑。** 四個維度：`input_line_current` / `bank_breaker` / `outlet_count` / `rack_u`。30 A 機 binding 是進線、50 A 機 binding 是斷路器，**同一份 code 兩個答案**——證明 binding 必須是查詢結果而不是設定值。W35 #1 預言「dc-14 會是第四種容量報表」，兌現了。

4. **`derating_basis` 出現第三種來源。** [dc-12](rpp-remote-power-panel.md) 是外殼列名、[dc-13](busway-and-tap-off-box.md) 是環境溫度，這裡是**內部導體線規與斷路器數量**，而且 AP7868→AP8868 那個例子說明它還可以是**規範版本**。所以 `basis` 不能是列舉，要能指向一份文件：`Rating(nameplate_a, derated_a, basis: str, authority: str)`。

5. **switched 機型帶來 write 能力，而 outlet 狀態不是告警。** `control_capability: none|outlet_switch|outlet_meter|both` 決定 API 是否暴露危險動作。outlet 被關閉是 **latched 狀態**（沿用 [dc-10](static-transfer-switch.md) 的結論），住在 `Outlet.state` 上，`Alarm` 是它的下游且**不得 ack 掉它**。遠端關一個 outlet 在 `change_class` 上不是 `no_permit`——它會弄掉一台生產伺服器。

## 該問 facility 的問題

1. **「機櫃內是 208 V line-to-line（delta）還是 220 V line-to-neutral（wye）？rack PDU 型錄給我。」** 這一問決定容量計算用哪套算法，答錯整個機房的每相電流都是錯的。
2. **「rack PDU 的分路斷路器幾個、額定多少？進線導體線規多少？」** 這三個數字決定 binding 是進線還是斷路器，以及同一顆插頭是 35 A 還是 40 A。型錄封面上不會有。
3. **「outlet-level 計量是哪一個 class？IEC 62053-21 class 1 還是只是『大概準』？資料保存多久？」** 延續 W35 Q3——沒有保存期就不能用實測法做容量規劃。

## 動手練習（35 分鐘）

**這一題就是 W35 連貫性檢視 #1 ＋ #2**，用 rack PDU 當第四個實作者一次做完。

```python
from dataclasses import dataclass
from typing import Literal
import math

Method = Literal["nameplate","measured_125pct","pole_count","prefix_sum",
                 "outlet_count","vector_sum"]          # ★ 新增 vector_sum

@dataclass(frozen=True)
class Dimension:
    name: str                  # "input_current"|"bank"|"outlet"|"rack_u"
    remaining: float | None    # None = 這台設備沒有這個維度
    used_pct: float | None
    method: Method
    valid: bool = True

@dataclass(frozen=True)
class Finding:
    id: str
    policy_id: str             # "UL489_80PCT" | "NEC_210_20A" | "PDU_UNBALANCE"
    severity: Literal["CRITICAL","WARNING","INFO"]
    entity_ids: list[str]
    message: str
    # 不得有 acked —— Finding 是設計期事實

@dataclass(frozen=True)
class CapacityReport:
    entity_id: str
    dims: list[Dimension]
    def binding(self) -> Dimension: ...        # remaining 最小的那一維

@dataclass
class RackPdu:
    id: str
    wiring: Literal["delta_208","wye_380y220"]      # ★ 決定算法的模式欄位
    input_nameplate_a: float
    input_derated_a: float
    derating_basis: str                              # 例："UL 80% + 6AWG 進線"
    bank_breaker_a: float                            # 銘牌
    banks: dict[str, list[float]]                    # {"L1L2":[6.0,4.0], ...}

    def line_currents(self) -> dict[str, float]:
        """delta：向量和；wye：直接相加。"""
        ...
    def capacity(self) -> CapacityReport: ...
    def validate(self) -> list[Finding]: ...
```

**驗收表**（三個案例都要跑出來）：

| 案例 | 期望 |
|---|---|
| delta，L1L2=10 A、L2L3=10 A | `line_currents()["L2"] ≈ 17.32`（±0.01） |
| delta 30 A 機，三 bank 各 16 A | `binding().name == "input_current"`，總量 8 646 VA |
| delta 50 A 機（AP8868），三 bank 各 16 A | `binding().name == "bank"`，總量 9 984 VA |
| 全部負載塞在 L1L2、共 16 A | `used_pct` 顯示 38.5%，同時吐一條 `PDU_UNBALANCE` 的 `Finding` |
| wye 機型，同樣負載 | `line_currents()` 走加總分支，**不得呼叫向量公式** |

**加分題**：把 `CapacityReport.chain_min()` 補完，串起 [dc-13](busway-and-tap-off-box.md) 的 busway 與這台 rack PDU，回報整條鏈是誰先卡住。

## 自我檢核

**Q1. 一台 delta 接法的 rack PDU，L1-L2 掛 12 A、L2-L3 掛 8 A、L3-L1 掛 0 A。三條線的電流各是多少？**

??? note "答案"
    L1 與 L3 各只被一個負載使用，等於該負載本身：**L1 = 12 A、L3 = 8 A**。
    L2 被兩個共用，走向量和：

    ```
    I_L2 = √(12² + 8² + 12×8) = √(144 + 64 + 96) = √304 = 17.44 A
    ```

    注意 **L2 比任何一個負載都大，也比它們的算術平均大很多**，但小於 20 A。直覺上「平均一下」與「加起來」都會給錯答案。

**Q2. 這張卡會讓你的資料模型長出什麼欄位？至少講三個，並說明每一個的「不存會怎樣」。**

??? note "答案"
    - **`RackPdu.wiring`**（模式欄位）：不存就不知道 `line_currents()` 該走向量還是加總，**兩個分支都會靜默給出看起來合理的數字**。
    - **`Outlet.legs: tuple[Leg,...]`**（基數由 wiring 決定）：NetBox 的單一 `feed_leg` 表達不了 delta，存進去等於宣告「這個插座只吃一相」，每相電流全錯。
    - **`Rating(nameplate_a, derated_a, basis, authority)`**：只存一個數字，三個月後沒人知道 40 A 是怎麼來的；而同一顆 CS8365C 有 35 A 與 40 A 兩個正確答案。
    - **`control_capability`**：不存就無法在 API 層區分「這台只能讀」與「這台能關掉生產伺服器」。

    **反過來不該存的**：`line_current_l2`（算得出來，且會在有人換 bank 那天靜默說謊）、`is_balanced: bool`（又一個假是非題——不平衡是程度，且門檻依機型不同）。

**Q3. 有人說「我們兩條 rack PDU 各只用 45%，很安全」。這句話錯在哪？**

??? note "答案"
    **2N 的容量規劃要假設另一條離線**（Raritan 在其容量工具的說明中明寫這一點）。A 掉電時 B 要扛 90%，若考慮 UL 80% 降載後的可用值，90% 可能已經越過 bank 斷路器門檻。

    更糟的是**負載不會平均落回去**：伺服器 PSU 的兩路輸入未必接在對側 PDU 的同一 bank，所以轉移後**單一 bank 可能瞬間翻倍而其他兩個不變**——總量還在 90%，但某一個 bank 已經跳了。

    所以 `redundancy_ok()` 不能比對總 kVA，要**逐 bank 模擬對側失效後的重分佈**，而它需要知道每個 PSU 的兩路各接在哪個 bank——那是 `dc-16` 的題目。
