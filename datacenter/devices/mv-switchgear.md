---
id: dc-03
title: 中壓開關設備（MV Switchgear）— 額定與保護
category: power
written_at: 2026-07-30
sources:
  - https://payapress.com/iec-62271-200-internal-arc-lsc-and-type-tests/
  - https://www.csemag.com/criteria-for-selecting-arc-flash-protection-techniques-part-3/
related: [dc-01, dc-02, dc-04, dc-07]
---

# 中壓開關設備（MV Switchgear）— 額定與保護

從 [市電進線](utility-feed.md) 的責任分界點進來後，第一個**你擁有、你可以操作**的節點。它把一路進線分成數路饋線送去 [變壓器](transformer.md)、發電機或其他機房區。不改電壓也不改功率，卻決定**故障時多快被切斷**。

> 另一半——服務連續性分級 LSC 與抽出式斷路器互鎖——單獨寫成 [dc-03b](lsc-and-interlocks.md)。今天先講額定與保護。

## 六格

**拓撲位置**：上游責任分界點（`dc-01`），下游 [變壓器](transformer.md)與 `dc-04` ATS 的中壓來源。**它是電力鏈上第一個一對多的節點。**

**容量單位**：四個獨立額定，缺一個就不是規格——Ur（台灣 22.8 kV 用 **24 kV 級**，含 Ud / Up）、匯流排 Ir（630 / 1250 / 2500 A）、短時耐受 **Ik / tk（必成對**，例 25 kA 3 s）、內部電弧分級 **IAC**（例 `IAC A FLR 31.5 kA 1 s`）。

**冗餘表達**：單母線不可維護；**單母線分段**與 **main-tie-main**（雙進線＋常開母聯）才有 N+1 語意。但拓撲只是一半，另一半是 LSC（見 [dc-03b](lsc-and-interlocks.md)）。

**遙測介面**：主流 **IEC 61850**（MMS 給監控、GOOSE 給保護互鎖，< 3 ms），對外常再加一層 Modbus TCP。三種資料型態混在同一台設備：三相量測（time-series）、電驛旗標與操作次數（事件）、**事故波形 COMTRADE（blob）**。

**故障域**：匯流排故障最貴——整段饋線同時失電，且只有 **87B** 母線差動能在 10–30 週波內清除，過流協調要 30–60 週波。另一個常被忽略的故障域是**人**：電弧閃絡傷的是櫃前的維護者。

**維護特性**：PD 與紅外線帶電可做；真空斷路器本體幾乎免維護，負擔在**操作機構與二次電路**。

## 關鍵數字與計算

**一、由電業短路容量反推需要多少 Ik**

```
Isc = MVA_sc × 10⁶ ÷ (√3 × V)
假設 22.8 kV 側短路容量 500 MVA：
500,000,000 ÷ (1.732 × 22,800) ≈ 12,660 A ≈ 12.7 kA
```

25 kA 的櫃體餘裕充裕。但**電業擴充變電所會讓這個數字變大**——不是算一次就永久有效。

**二、kA 沒有時間就不是規格（I²t）**

```
I₁²t₁ = I₂²t₂  →  I₂ = I₁ × √(t₁ ÷ t₂)
25 kA 3 s 換到 1 s：25 × √3 ≈ 43.3 kA
「40 kA 1 s」換到 3 s：40 ÷ √3 ≈ 23.1 kA
```

**標示 40 kA 的那台換到同一基準後反而弱**，不同時間基準的 kA 不能直接比大小。

**三、保護協調時間直接換算成人身風險**

協調時間間隔取 0.3 s 級聯：`饋線 0.2 s → 主進線 0.5 s → 電業側 0.8 s`，母線電弧要等 **0.5 s**。改用光學電弧偵測電驛：`偵測 2.5 ms + 斷路器 60 ms ≈ 0.065 s`。IEEE 1584 的入射能量近似正比於電弧持續時間 → **能量降到約 1/8**。

⚠️ **地區差異**：台灣 22.8 kV 對應 IEC **24 kV 級**（Ud 50 kV / Up 125 kV），北美同級是 ANSI 27 kV 級。更關鍵的是 IEC 62271-200 的 **IAC** 與 IEEE C37.20.7 的 **arc-resistant** 判定條件不同（指示物 300 mm vs 914 mm、1 s vs 2 s 不起燃），**額定不可互換**——看到「arc resistant 40 kA」別自動當成 IAC 合格。

## 常見誤解

1. **以為「25 kA 耐受」是這台設備的能力值，但實際上**沒搭配時間就沒有意義（見 I²t）。規格表把時間寫在小字裡，比價時最常掉這一項。

2. **以為通過 IAC 電弧測試就不必擔心電弧，但實際上** IAC 保護的是**櫃外的人**，不保護櫃內設備、也**完全不縮短清除時間**，且測試前提是**門關著**。降能量只能靠電驛與電弧偵測。

3. **以為機房越大就要選電流更大的櫃，但實際上**中壓側電流小得驚人：10 MVA 在 22.8 kV 只有 `10,000,000 ÷ (1.732 × 22,800) ≈ 253 A`，630 A 匯流排綽綽有餘。**綁住選型的是 Ik 與 IAC，不是 Ir**——拿低壓側直覺（`dc-02` 1500 kVA 就 2,279 A）套過來會抓錯重點。

## 來源分歧：arc-resistant 算不算保護

- **顧問／工程文獻**（CSE 電弧防護系列）：arc-resistant 櫃體與電弧偵測電驛**互補**，IAC 只改變後果分佈，能量必須靠清除時間去壓。
- **部分廠商文獻**：把 arc-resistant 額定當成電弧風險的主要解方，較少同時要求光學偵測或 87B。

**建議問法**：要對方提出**入射能量計算報告**，而非只交 IAC 型式試驗證明——前者才回答「人站在櫃前會怎樣」。

## 對資料模型的意涵

1. **所有耐受額定都要存成 (值, 時間) 對**：`ik_ka` + `ik_duration_s`、`iac_ka` + `iac_duration_s` + `iac_sides` + **`iac_standard`（IEC / IEEE）**。比較前必須換算到同一基準，這個換算屬於模型的方法。

2. **這裡第一次出現分支，關係要能一對多。** `upstream_id` 保持單值、`units` 必須是集合；寫成一進一出，[dc-03b](lsc-and-interlocks.md) 與 `dc-04` 都會卡住。

3. **保護清除時間是欄位，不是文件。** `clearing_time_s` 要進模型且**能算出入射能量估計值**——它是「設定值變更會改變人身風險」的唯一可查詢載體。只存在電驛工程師筆電裡，系統就無法在變更審查時提出異議。

4. **`dc-01` 的 event/blob 路徑在這裡具體化。** COMTRADE 波形事件觸發、非等間隔、單筆數百 KB，與量測的 time-series 必須是兩條 pipeline，用同一個 `event_id` 關聯。

## 該問 facility 的問題

1. 電業給的 22.8 kV 短路容量幾 MVA？櫃體 **Ik 與時間**各多少、餘裕幾成？
2. IAC 依 **IEC 62271-200 還是 IEEE C37.20.7** 測？標到哪幾面、幾 kA 幾秒？
3. 有 87B 或光學電弧偵測嗎？主進線清除時間設幾秒——**有人算過入射能量嗎**？

## 動手練習（30–40 分鐘）

把 `MVSwitchgear` **插進** `UtilitySource` 與 `Transformer` 之間。第一次改動既有拓撲，也第一次讓節點有多個下游。

```python
@dataclass
class MVFeederUnit:
    id: str
    downstream_id: str | None = None   # → Transformer.id
    clearing_time_s: float = 0.2

@dataclass
class MVSwitchgear:
    id: str
    upstream_id: str                   # → UtilitySource.id（單值）
    ik_ka: float; ik_duration_s: float # 25, 3
    iac_ka: float | None = None
    iac_standard: str | None = None    # "IEC" | "IEEE"
    units: list[MVFeederUnit] = field(default_factory=list)
    # TODO ik_at(duration_s)                    I²t 換算
    # TODO validate_against_utility(mva_sc, kv)
    # TODO incident_energy_ratio(t_fast_s)      能量比
```

**驗收標準**：`ik_at(1)`（25 kA / 3 s）≈ **43.3 kA**；用在 40 kA / 1 s 的櫃上 `ik_at(3)` ≈ **23.1 kA**，且能判斷前者更強；`validate_against_utility(500, 22.8)` 合格並算出 **≈ 12.7 kA**；`incident_energy_ratio(0.065)` 對 0.5 s 基準回 **≈ 0.13**。

**加分題**：把 `Transformer.upstream_id` 改指向 `MVFeederUnit.id`（**不是** `MVSwitchgear.id`），再寫 `trace_upstream(device)` 回 `UtilitySource`。

> [dc-03b](lsc-and-interlocks.md) 會在 `MVFeederUnit` 上長出互鎖狀態機，今天先留薄類別。

## 自我檢核

**Q1. A 櫃標 25 kA 3 s，B 櫃標 40 kA 1 s。哪台短路耐受強？**

??? note "答案"
    換到 1 s：A 是 `25 × √3 ≈ 43.3 kA`，強過 B。**標示數字大的反而弱。**

**Q2. 裝了母線差動 87B，為什麼電弧入射能量會下降？**

??? note "答案"
    IEEE 1584 的入射能量近似正比於電弧持續時間。87B 在 10–30 週波清除母線故障，過流協調要 30–60 週波，時間差等比反映在能量上。**它降的是能量不是發生機率。**

**Q3. 「額定必須是 (值, 時間) 對」會讓你的資料模型長出什麼？**

??? note "答案"
    每個耐受額定都要**兩個欄位**（`ik_ka` / `ik_duration_s`）、一個依 I²t 換算的方法，加上 `iac_standard` 標明測試標準。單一 `ik_ka: 25` 欄位是 bug。
    **延伸**：這是「數字不能脫離量測條件」第二次出現——`dc-02` 的銘牌 kVA 綁 40 °C，這裡的 kA 綁時間。之後 UPS runtime 綁放電率、冰水主機 RT 綁進出水溫，同一結構。

---

**下一張**：[dc-03b LSC 服務連續性分級與抽出式斷路器互鎖](lsc-and-interlocks.md)
