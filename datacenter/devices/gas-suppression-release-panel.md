---
id: dc-33
title: 氣體滅火系統與消防警報盤（釋放控制）
category: fire-security
written_at: 2026-10-05
sources:
  - https://retrotec.com/pub/media/mageworx/downloads/attachment/file/a/r/article-_clean_agent_enclosure_design_for_nfpa.pdf
  - https://fire-protection.com.au/wp-content/uploads/2022/02/Clean-Agent-enclosure-design-for-ISO14520AS4212_Final_RevA.pdf
  - https://www.vikinggroupinc.com/sites/default/files/documents/F_012319_19.1_932157_R00_V00_Design-Manual_VSH1230_en_NOVDS.pdf
  - https://docs.johnsoncontrols.com/simplex/api/khub/documents/tfbqGMXRrGq7MAxYJW_oMg/content
  - https://docs.johnsoncontrols.com/specialhazards/api/khub/documents/kZSnGDFb~cFEWwiRmmoP6g/content
  - https://firesafetycentral.com/clean-agent-suppression/data-center-fire-suppression-systems-nfpa-design/
related: [dc-32, dc-30, dc-22, dc-25b, dc-29]
---

# 氣體滅火系統與消防警報盤（Clean Agent Suppression & Releasing Panel）

機房失火不能灑水，所以把整個房間灌到某個氣體濃度，維持一段時間，火就熄了。**它不是一個設備，而是「偵測 → 釋放盤 → 鋼瓶／管網／噴頭」加上一個關得住氣的房間**。釋放盤是邏輯：什麼條件下放、放之前等多久、誰能喊停。它是 `dc-32` 偵測圖的下游。

## 六格

### 拓撲位置
上游：`dc-32` 的 VESDA 與點型偵煙器（各是一條偵測迴路）、手動拉桿、中止鈕。下游：鋼瓶組 → 管網 → 噴頭，以及**聯動輸出**（CRAH 停機、風門、門禁、警鈴）。放氣的單位是**防護區**（`Zone`），可含多個 [Space](space-hierarchy.md)（機房＋地板下＋天花板夾層）。

### 容量單位
**防護體積 × 設計濃度 → 藥劑質量**。體積含地板下與天花板夾層（[raised-floor](raised-floor.md) 的 plenum）。

### 冗餘表達
鋼瓶可有 main／reserve；釋放盤通常單一。常見的「冗餘」是偵測端的**交叉區域（cross-zone）**：兩條迴路都確認才放——用冗餘換**誤放抑制**，不是換可用度。

### 遙測介面
釋放盤對外多是**乾接點**，不是豐富資料：

| 點位 | 內容 | 來源 |
|---|---|---|
| Trouble relay | 故障時**失電**（fail-safe） | JCI 4004R 規格 |
| Common alarm relay | 通用警報 | 同上 |
| Supervisory／pressure switch relay | 管網壓力、監視 | 同上 |
| 釋放迴路 | 螺線管迴路有短路／斷路監督，單迴路 2 A 上限 | 同上 |

Modbus／BACnet 閘道的有無與點位表**本次未查證**，不假設。

### 故障域
拒動（該放沒放）與誤放（整區停冷、藥劑耗盡、恢復要數天）**兩個方向都貴**，所以門檻是取捨，不是越靈敏越好。

### 維護特性
次級網站列：月目視、半年稱重、年度功能測試、五年鋼瓶水壓測試、**圍封改動後重做密閉測試**——週期與條文**未對原文驗證**。維護時設「鎖定／旁路」，期間自動釋放不可達，這是 `RELEASE_*` 告警的來源。

## 來源分歧

- **保持時間**：Retrotec 與 Fire-protection.com.au 皆稱 NFPA 2001／ISO 14520 實務取 **10 分鐘**（NFPA 條文：10 分鐘或留給受訓人員回應的時間）；firesafetycentral 寫「A 類 10、B 類 5 分鐘」；JCI Inergen 規格寫**最少 30 分鐘**。保持時間是專案參數，不是常數。
- **Class A 設計濃度**：Viking 手冊：NFPA 2001 為 4.5%、ISO 14520-5 為 5.3%；Class B（正庚烷）皆 5.9%。同藥劑同房間，採哪套標準藥量就不同（見計算）。
- **洩漏模型**：Fire-protection.com.au 稱 ISO 14520 的「寬下降界面」比 NFPA 的「尖銳界面」預測保持時間最多短 **40%**，作者主張 NFPA 更貼近實驗——一位工程師的主張，非標準原文。
- **預放延遲**：4004R 可設 0–60 秒（5 秒一階、預設 60）；JCI Inergen 規格 0–30 秒；次級網站稱占用空間至少 15 秒、常見 30 秒。是面板能力 vs 規範要求，不可互相代替。
- NFPA 2001／NFPA 72／ISO 14520 原文與台灣法規本次均未取得。

## 關鍵數字與計算

**藥劑質量（鹵碳類）**：`W = V/S × C/(100−C)`；Novec 1230 的比容 `S = 0.0664 + 0.000274×T`（m³/kg，T 為 °C；Viking 手冊）。其他藥劑與惰性氣體（IG-541）的公式本次未取得，**不計算**。

**實例**：資料機房 10 m × 8 m × 3.0 m = 240 m³，加地板下 0.6 m（48 m³），防護體積 **V = 288 m³**，室溫 20 °C。
- `S(20) = 0.0664 + 0.00548 = 0.07188`，V/S = 4006.7 kg
- 採 ISO 14520（C = 5.3%）：`4006.7 × 5.3/94.7 =` **224.2 kg**
- 採 NFPA 2001（C = 4.5%）：`4006.7 × 4.5/95.5 =` **188.8 kg**，差 **35.4 kg（19%）**
- 溫度：同體積、5.3%，15 °C（S = 0.07051）→ **228.6 kg**；30 °C（S = 0.07462）→ **216.0 kg**。冷熱通道溫差大時房間溫度用哪個？要記 `design_temp_c`。

**85% 規則**：保持時間結束時，防護設備**頂部**濃度須 ≥ 設計濃度的 85%。設計 5.3% → 末端須 ≥ **4.505%**；4.51 過、4.50 不過。差 0.01 個百分點就翻盤。

**煙進孔到藥劑到位**：`t = t_transport + t_delay + t_discharge`（halocarbon 排放 7–10 秒，惰性約 60 秒）。接 `dc-32`：121.7 + 30 + 10 = **161.7 秒**；若用天真傳輸 41.6 秒則 **81.6 秒**，差 80 秒。保持時間從排放結束起算：30 + 10 + 600 = 結束於 **640 秒**。

## 常見誤解

**以為「偵測到火就放」，但實際上是「兩條獨立迴路都確認才放」**。交叉區域（JCI 規格：選項為「兩區警報才釋放」）是預設。單一偵測器告警只觸發預警（Stage 1：警鈴、聯動），**不放氣**。

**以為「中止鈕按了就不放」，但實際上要看中止型態與手動釋放**。4004R 有 UL、IRI（僅限 cross-zone）、NYC 等中止行為，而手動釋放輸入**會覆蓋中止鈕**（延遲 0–30 秒）。誰有最終決定權是設定，不是常識。

**以為「氣體對人安全，人在裡面沒關係」，但實際上要低於 NOAEL 且釋放前警示**。Novec 1230 的 NOAEL 為 10%（Viking），5.3% 在內；FM-200／IG-541 的 NOAEL 本次只來自次級摘要，**不可進計算**。

## 對資料模型的意涵

1. **防護區 `Zone` 是新聚合，不是 `Space`**。`Zone{id, space_ids, volume_m3, design_temp_c, agent, standard, hazard, hold_s, delay_s, arm}`。體積由 `space_ids` 加總，**地板下與夾層要算**；冷通道封閉是否獨立成區是 AHJ 裁量（`dc-25b`），要當專案輸入。
2. **偵測 → 釋放的映射是資料**：`Line{id, state, level}`＋`stage1_at`＋`stage2_at`＋`cross_zone`。Isolate／Urgent Fault 的迴路不算有效，與 `dc-32` 的 `DETECTION_COVERAGE_GAP` 同一條規則。
3. **第三個「缺東西」告警：`RELEASE_PATH_DEGRADED`／`RELEASE_LOCKED_OUT`**。cross-zone 需要 ≥ 2 條有效迴路；任一條被隔離，自動釋放就不可達，**但釋放盤仍顯示 Normal**。這是 W40 連鎖 B 的終點：偵測延遲＋釋放不可達，都沒有告警說它發生了。
4. **藥量是推導值，帶規範**：`mass_kg = f(volume, temp, concentration)`，`concentration` 是 `Sourced`，且 `standard` 欄位決定取哪一個。機櫃增減不影響體積，但**隔間、地板下高度、圍封改動會**——須觸發重算與重做密閉測試。
5. **聯動輸出是跨圖邊**：`Zone.interlocks`（CRAH 停機、風門、門禁、警鈴）。釋放會讓 `dc-22` 的冷卻停下，熱載荷沒被帶走。

## 該問 facility 的問題

1. 防護區邊界與體積計算書在哪？有沒有把**地板下、天花板夾層**算進去？採 NFPA 2001 還是 ISO 14520？
2. 最近一次圍封密閉測試（門風扇）的日期？之後有沒有隔間／開孔／管線貫穿的改動？
3. 預放延遲設幾秒？中止鈕在哪？維護時誰能設鎖定／旁路、有沒有起訖時間的工單？

## 動手練習（30–40 分鐘）

**第 0 步（約 15 分鐘，W40 交辦的三項收斂）**：建立 `core.py` 與 `rack.py`——**只有一份**，之後所有練習 `from core import ...`。

```python
# core.py（精簡）
class Check(Enum): OK; VIOLATED; NOT_APPLICABLE; INVALID; UNDETERMINED   # 全軌跡唯一
@dataclass(frozen=True)
class Result: check: Check; reason: str = ""            # 不再增態，原因放 reason
@dataclass(frozen=True)
class Sourced(Generic[T]):
    value: T; source: str; evidence: str; fetched_at: str = ""   # primary|vendor|snippet|assumed
    def usable(self): return self.evidence in {"primary", "vendor"}
def resolve(table, key):                                 # 查無與 snippet 走同一條路
    s = table.get(key); return s if (s and s.usable()) else None
@dataclass(frozen=True)
class Finding: code: str; space_id: str; reason: str = ""
```

`rack.py`：`RackType`（`outer_w_mm`）、`Placement(space_id,…)`、`Mount`、`Rack(…, mounts)`；`mount()` 檢查 U 範圍與重疊，`total_weight_kg() = 機櫃自重 + Σ mounts`，**不留 `device_kg`**。

**主體 `suppression.py`**（約 20 分鐘）：

```python
CONC = {("novec1230","iso14520","A"): Sourced(5.3,"Viking","vendor"),
        ("novec1230","nfpa2001","A"): Sourced(4.5,"Viking","vendor"),
        ("fm200","nfpa2001","A"):     Sourced(7.0,"摘要","snippet")}   # 填滿 5.9、NOAEL 等
def specific_volume(agent, t_c): ...          # 僅 novec1230，其餘 None
def design_mass(agent, std, hazard, v_m3, t_c): ...  # 查無／snippet／無公式 → UNDETERMINED
def check_occupied(agent, c_pct) -> Result: ...      # 對 NOAEL
def end_of_hold_ok(c_end_top, c_design) -> Result: ...# ≥ 0.85*設計
class Line: id, state(DState), level(Level)
def stage(lines, arm, cross_zone=True, stage1_at=ACTION, stage2_at=FIRE2): ...
def release_findings(zone_id, lines, arm, cross_zone=True): ...
def detect_to_agent_s(t_transport, t_delay, t_discharge): ...
```

### 驗收表（已用參考實作跑過）

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | `design_mass("novec1230","iso14520","A",288,20)`；`...nfpa2001...` | **224.2**；**188.8** |
| 2 | 同上但 15 °C／30 °C（ISO） | **228.6**／**216.0** |
| 3 | `design_mass("fm200","nfpa2001","A",288,20)`；hazard 填 `"C"` | 皆 **UNDETERMINED**（摘要不可進計算／查無） |
| 4 | `check_occupied("novec1230",5.3)`／`11`／`("fm200",7)` | **OK／VIOLATED／UNDETERMINED** |
| 5 | `end_of_hold_ok(4.51,5.3)`／`(4.50,5.3)` | **OK／VIOLATED** |
| 6 | A=FIRE2、B=NONE（皆 NORMAL）；A、B 皆 FIRE2；A=ACTION、B=NONE | **STAGE1／STAGE2／STAGE1** |
| 7 | A=FIRE2、B 被 ISOLATED（level FIRE2）；`auto_release_reachable` | **STAGE1**；**False**；告警 `RELEASE_PATH_DEGRADED` |
| 8 | 同 7 但 `cross_zone=False`、A、B 皆 FIRE2 | **STAGE2** |
| 9 | 兩迴路皆 FIRE2 但 `arm=MANUAL_ONLY`；`arm=LOCKED_OUT` 的告警 | **IDLE**；`RELEASE_LOCKED_OUT` |
| 10 | `detect_to_agent_s(121.7,30,10)`；`(41.6,30,10)` | **161.7／81.6** |
| 11 | `Rack` 在 42U 機櫃上 `mount` U1 高 2、U2 高 2（重疊）、U41 高 3 | **OK／VIOLATED／VIOLATED**；總重 **132 kg**（機櫃 120＋12） |

**加分題**：`check_delay(panel_range, delay_s, step=5)`：`(0,60)` 設 30 → OK；`(0,30)` 設 45 → INVALID。

## 自我檢核

**Q1. 同一個 288 m³ 機房，採 NFPA 2001 與 ISO 14520 的 Novec 藥量差多少？這代表資料模型要存什麼？**

??? note "答案"
    188.8 vs 224.2 kg，差 35.4 kg（約 19%）。要存 `standard` 欄位，濃度是 `Sourced` 並綁定它；不能把「設計濃度」存成一個藥劑的全域常數。

**Q2. 一條偵測迴路被隔離，釋放盤顯示 Normal。哪個告警該響、條件是什麼？**

??? note "答案"
    `RELEASE_PATH_DEGRADED`：cross-zone 且有效迴路數 < 2（有效 = Normal／Minor Fault；Isolate、Urgent Fault 不算）。與 `dc-32` 的 `DETECTION_COVERAGE_GAP` 同一類：「缺東西」告警，保護失效但狀態正常。

**Q3. 機房加了一道隔間牆，會讓資料模型長出什麼欄位與觸發什麼動作？**

??? note "答案"
    `Zone.volume_m3`（由 `space_ids` 重算）、`enclosure_test_at`（密閉測試日期）；告警 `ENCLOSURE_CHANGED_SINCE_TEST`（最近圍封改動工單晚於測試日期）與藥量重算。

---

**下一張**：`dc-34` 門禁控制器、讀卡機、人員通道閘（釋放時的門禁解鎖是今天 `Zone.interlocks` 的下游）
