---
id: dc-26
title: 液冷 CDU（coolant distribution unit）
category: cooling
written_at: 2026-09-21
sources:
  - https://blog.se.com/datacenter/2025/12/16/account-for-filtering-too-beware-of-how-cdu-rating-capacity-is-specified/
  - https://www.datacenterfrontier.com/sponsored/article/55245044/selecting-the-right-coolant-distribution-unit-for-your-ai-data-center
  - https://www.opencompute.org/documents/oai-system-liquid-cooling-guidelines-in-ocp-template-mar-3-2023-update-pdf
  - https://www.sciencedirect.com/science/article/pii/S2214157X24014928
related: [dc-17, dc-18, dc-19, dc-21, dc-23, dc-26b, dc-27]
---

# 液冷 CDU（coolant distribution unit）

CDU 是液冷機房裡的「翻譯機兼幫浦房」。它一邊接設施的冰水（FWS，facility water system），一邊接流進 GPU 冷板的那條乾淨迴路（TCS，technology cooling system），中間隔一個熱交換器讓兩邊的水**永遠不混在一起**；同時負責把 TCS 那側的流量、壓力、溫度與潔淨度維持在晶片廠商規定的窗口內。說穿了就是[板式熱交換器](plate-hx-free-cooling.md)＋[泵](chilled-water-pump.md)＋過濾與控制，裝進一個機櫃。

> 本卡處理**設備本體與它在熱鏈上的位置**。「額定值為什麼不可比較、濾網為什麼是容量維度」拆給 `dc-26b`。

## 六格

### 拓撲位置

FWS 側：[冰水主機](chiller.md) 或 [板式 HX](plate-hx-free-cooling.md) → [二次側泵](chilled-water-pump.md) → CDU 冷側。
TCS 側：CDU 熱側 → 立管 → 列／櫃分歧管（manifold）→ 快接頭 QD → 冷板 → 回 CDU。
電力側：CDU 是 [rack PDU](rack-pdu.md) 或 [RPP](rpp-remote-power-panel.md) 下游的**葉負載**（泵 ＋ VFD ＋ 控制），與 dc-19 的泵同一類。

### 容量單位

kW（排熱量）＋ L/min（TCS 流量）＋ kPa（TCS 可用外部揚程）＋ K（approach），**四個一起才成立**。單看 kW 沒有意義——理由整張留給 `dc-26b`。

### 冗餘表達

三層：**單元內**（N+1 泵、雙電源、熱插拔濾芯）／**單元間**（兩台並聯共餵一列）／**路徑**（分歧管雙進雙出）。CoolIT 另提內建 ultracapacitor ＋ ATS，等於設備自帶秒級後備。

### 遙測介面

| 類別 | 點位 |
|---|---|
| 溫度 | `tcs_supply_c`／`tcs_return_c`／`fws_supply_c`／`fws_return_c` |
| 流量壓力 | `tcs_flow_lpm`／`tcs_dp_kpa`／`filter_dp_kpa`／`fws_flow_lpm` |
| 設備 | `pump_n_speed_pct`／`pump_n_hours`／`psu_a_ok`／`leak_zone_n` |

水質（pH、導電度、抑制劑濃度）多半**離線採樣，不是點位**。協定：Redfish、Modbus、SNMP，另常見 SFTP／SSH／SMTP（CoolIT 口徑）。**Redfish 出現在冷卻設備上是新的**——它原本是 [dc-16](dual-corded-equipment.md) 的 IT 帶外管理協定。

### 故障域

TCS 全失 → 該 CDU 下游**所有**機櫃在秒級降頻或關機（演算三）。FWS 全失但泵仍轉 → 約一分鐘。濾網堵塞 → 不是掉，是容量慢慢縮，且在任何 kW 報表上看不見（`dc-26b`）。

### 維護特性

濾芯更換（二手口徑：穩定迴路的 50 µm 標準濾芯每 3–6 個月，每月目視）、水質採樣、泵輪替。有 N+1 泵 ＋ 熱插拔濾芯才談得上 concurrent maintainability，否則換濾芯 ＝ 停該列。QD 讓單台伺服器可抽出而不洩空迴路。

## 關鍵數字與計算

### 演算一：TCS 流量是 kW 與 ΔT 解出來的，不是查來的

ASHRAE 127-2020 **Addendum B**（制定中，以下條件經 Schneider 轉述）的標準 rating 條件：FWS 進水 **26 °C**、TCS 出水 **30 °C**、**approach 4 K**、TCS 回水 **39.6 °C**（100% 載點）→ TCS ΔT = **9.6 K**；TCS 側流體為 **PG25**（25% 丙二醇）。

假設廠商宣告 1000 kW @ 100%。PG25 在均溫 34.8 °C 取 ρ ≈ 1015 kg/m³、cp ≈ 3.87 kJ/(kg·K)（**假設值，實務要拿流體物性表**）：

- ṁ = 1000 ÷ (3.87 × 9.6) = **26.91 kg/s**
- V̇ = 26.91 ÷ 1015 = 0.02652 m³/s = **1591 L/min** → **1.59 L/min per kW**

對照 OCP OAI 液冷指引：10 K 升溫 ↔ **1.5 LPM/kW**，可接受帶 7.5–12 K ↔ **1.25–2.0 LPM/kW**（依 PG25 物性）。1.59 落在帶內 ✓。

同一台機、同樣 1000 kW、同樣 9.6 K，**改用純水**（cp 4.178、ρ 994）：

- ṁ = 1000 ÷ (4.178 × 9.6) = 24.93 kg/s → V̇ = **1505 L/min** = 1.50 LPM/kW

→ PG25 比純水多 **5.7%** 體積流量。而 PG25 動黏度約為水的 1.8 倍（25 °C），紊流區 ΔP ∝ Q^1.8·μ^0.2：流量貢獻 1.057^1.8 = ×1.105、黏度貢獻 1.8^0.2 = ×1.125 → **ΔP ≈ ×1.24**。**換流體不是換一個欄位，是同時換掉容量曲線與揚程曲線。**

### 演算二：approach 決定台北有沒有冰機

無冰機可行的條件是一條加法鏈（接 [dc-17](cooling-tower.md) 的塔 approach 與 [dc-21](plate-hx-free-cooling.md) 的 HX approach）：

`WB + a_tower + a_HX + a_CDU ≤ T_TCS 要求值`

取 a_tower = 4 K（dc-17 設計值）、a_HX = 2 K（dc-21）、a_CDU = 4 K（rating 值）：

| IT 要的 TCS 供水 | 允許濕球 | 台北（設計 WB 28 °C，dc-17 佔位值） |
|---|---|---|
| 30 °C（rating 那一列） | ≤ **20 °C** | 全年都要冰機 |
| 40 °C（W40 等級） | ≤ **30 °C** | **全年不需要冰機** |
| 40 °C 且省掉板式 HX | ≤ **32 °C** | 全年不需要冰機（但 FWS 直接吃塔水，要過水質與材料相容關） |

ASHRAE 熱環境第五版把水溫等級改名為 W17／W27／W32／W40／W45／W+，**數字就是該級的最高供水溫度（°C）**，下限一律 2 °C。

→ 結論與 dc-21 同型：**要不要冰機不是氣候決定的，是設定值決定的。** 而這次設定值的擁有者不是設施、也不是 IT 營運，是**晶片／冷板規格書**。連帶一個殘酷的算術：a_CDU 從 4 K 買到 2 K 只補 2 K，而 30 °C 那列要 20 → 28 得補 8 K——**買一台 approach 更小的 CDU 換不回一個溫度等級**，結構與 dc-21 的「塔加大只能 a_tower 4→2，冰水 7→18 是 +11 K」一模一樣。

### 演算三：ride-through 從分鐘掉到秒

**情境 A｜FWS 斷、TCS 泵仍轉。** 假設 TCS 迴路總容積 V = 1000 L（CDU 水箱 200 L ＋ 管路 ＋ 分歧管 ＋ 冷板，**假設值**）。PG25 體積熱容 = 1015 × 3.87 = 3928 kJ/(m³·K) = 3.93 kJ/(L·K)。

- C_loop = 1000 × 3.93 = 3928 kJ/K；1000 kW → dT/dt = **0.255 K/s ＝ 15.3 K/min**
- 從 30 °C 升到假設的冷板進水上限 45 °C：15 ÷ 0.255 ≈ **59 秒**

**情境 B｜TCS 泵停。** 只剩冷板裡的東西。一顆 1.2 kW 晶片的冷板假設：銅 1.0 kg（cp 0.385）＋ 冷媒 0.10 L（0.393 kJ/K）→ C = 0.778 kJ/K。

- dT/dt = 1.2 ÷ 0.778 = **1.54 K/s** → 30 → 45 °C 只有 **9.7 秒**

放進本軌跡的 ride-through 階梯：

| 緩衝 | 時間 | 出處 |
|---|---|---|
| 儲冷槽 | 15 分 | [dc-20](thermal-storage-tank.md) |
| 冰水環路 | 5.2 分 | [dc-18](chiller.md) |
| 機房空氣（CRAC） | 24 秒 | [dc-23](crac-direct-expansion.md) |
| **TCS 迴路（泵仍轉）** | **≈ 59 秒** | 本卡 |
| **冷板（泵停）** | **≈ 10 秒** | 本卡 |

而 [dc-05b](genset-start-and-transient.md) 的發電機起動是 **10 秒**。**冷板的 10 秒與發電機的 10 秒同一量級**——CDU 的 TCS 泵若不在 UPS 上，賭的是起動時間的抖動，而那一段沒有餘裕。dc-19 已把冰水泵放上 UPS，本卡再加 CDU 泵；CoolIT 另說 CDU 內建 ultracapacitor ＋ ATS，等於**設備自帶一台設施側看不見的小 UPS**。

## 常見誤解

**以為 CDU 是「液冷版的 CRAH」，掉一台補一台就好，但實際上 ride-through 差一到兩個數量級。** CRAH／CRAC 背後有房間空氣（[dc-23](crac-direct-expansion.md)，24 秒）與水環路（[dc-18](chiller.md)，5.2 分）當緩衝；DLC 只有迴路裡那幾百公升，泵一停只剩冷板裡的 0.1 L（演算三，≈10 秒）。**寫給分鐘級的 SOP 搬到秒級系統上等於沒有 SOP。**

**以為 TCS 流量是查得到的規格，但實際上它是 kW 與 ΔT 解出來的，換流體就變。** 同樣 1000 kW、9.6 K，PG25 要 1591 L/min、純水只要 1505——**差 5.7% 流量、約 24% 壓降**。拿型錄上 PG25 那列去算純水系統的泵，或反過來，兩次都錯。

**以為 approach 小就等於省電，但實際上它只換得到同等數量的濕球餘裕。** a_CDU 4 → 2 K 只補 2 K，而讓台北免冰機需要 8 K（演算二）。approach 是選型參數，**溫度等級卻是採購晶片時就定死的**，兩者不是同一個數量級的槓桿。

## 對資料模型的意涵

1. **`ride_through_s` 不能掛在設備上，要掛在 `(resource, failure_mode)` 對上。** 同一台 CDU：FWS 斷而泵仍轉 ≈ 59 秒，泵停 ≈ 10 秒，**差 6 倍且處置方向不同**（前者去看冰機／HX／FWS 泵，後者立刻降載）。→ `RideThrough(resource, failure_mode, seconds, basis)`；[dc-23](crac-direct-expansion.md) 立的 `Finding.RIDE_THROUGH_INSUFFICIENT` **必須帶 failure_mode 才判得出來**。

2. **冷卻設備第一次往電力模型裡長欄位（方向與前三次相反）。** CDU 內建 ATS ＋ ultracapacitor ＋ 雙電源 ＋ SCCR ＋ 諧波濾波器——全是 [dc-07b](lv-short-circuit-and-coordination.md)／[dc-10](static-transfer-switch.md)／[dc-16](dual-corded-equipment.md) 的語彙，卻長在冷卻設備肚子裡。→ `Device.embedded_power(ats, energy_storage_j, sccr_ka)`，且 dc-16 的 `scenario` 傳到熱側時，**CDU 那一格不是「掉了」而是「撐 N 秒」**——布林的掉電傳播在這裡會算錯。

3. **`Setpoint.owner` 要能是 `ite_vendor`，且 `mutable = False`。** [dc-16](dual-corded-equipment.md) 的 `psu_policy` 住 iDRAC、[dc-19](chilled-water-pump.md) 的 rate limiter 住 BMS、[dc-21](plate-hx-free-cooling.md) 的 `chws_setpoint` 擁有者是 IT——三者**都還能談**。冷板的允許進水溫採購當天就定死，而演算二證明它一個人決定台北要不要蓋冰機房。「設施 vs IT 管理平面」第四次穿越，也是第一次**穿不回來**。

4. **`fluid` 是模式欄位，不是標籤。** 它同時改變 `tcs_flow_lpm()` 的係數與壓降常數（演算一），結構同 [dc-14](rack-pdu.md) 的 `RackPdu.wiring`。任何把流量當設備常數存起來的 schema，在換冷媒配方那天會整批失效。

## 來源分歧

**「approach」跨兩個數量級，而且兩邊都叫 approach。** L2L 的 rating 條件是 **4 K**（ASHRAE 127 Add. B，經 Schneider 轉述，定義為 TCS 出水 − FWS 進水）；L2A 的實驗論文報 **ATD 18.3 K**（送風 31 °C、89 LPM → 89.9 kW，反推 0.99 LPM/kW、ΔT ≈ 15.4 K，已**超出 OCP 的 7.5–12 K 帶**）。兩邊都沒錯，是 liquid-to-liquid 與 liquid-to-air 同名不同物——結構與 [dc-16](dual-corded-equipment.md) 的「ATS 跨兩個數量級」一樣。→ `approach_k` 單獨存推不出任何東西，除非同時存 `sink_type ∈ {fws_water, room_air}`；規格書只寫「approach ≤ 5 K」不說哪一種，供應商兩邊都能交差。

（額定條件本身的兩條分歧——**同一台 CDU 有兩個合法的 rated 揚程**、**濾網孔徑差一個數量級**——留給 `dc-26b`。）

## 該問 facility 的問題

1. **冷板／晶片規格書上的 TCS 允許進水上限是幾度？** 那個數字決定台北要不要蓋冰機房（演算二），而它不在任何一張設施圖上，也不在我們能改的任何一個設定裡。
2. **CDU 的 TCS 泵接在哪一路、在不在 UPS 上、內建 ultracapacitor 撐幾秒？** 發電機起動 10 秒對上冷板 10 秒（演算三），這一題沒有安全餘裕。
3. **TCS 側用哪一種流體、誰負責配方與補充？** 換流體就換掉兩條曲線（演算一），而水質與抑制劑濃度多半是離線採樣，不在 BMS 上。

## 動手練習（30–40 分鐘）

接 [dc-25b](../topics/airflow-management-metrics.md) 的 `airflow_metrics.py`，新建 `cdu.py`。**核心目標：讓「流量」與「ride-through」都無法被當成設備常數讀出來。**

```python
FLUIDS = {                       # (cp kJ/kg·K, rho kg/m3, mu_ratio_vs_water)
    "PG25": (3.87, 1015, 1.8),
    "water": (4.178, 994, 1.0),
}

def tcs_flow_lpm(kw: float, dt_k: float, fluid: str = "PG25") -> float: ...
def dp_ratio(fluid_a: str, fluid_b: str, kw: float, dt_k: float) -> float:
    ...                          # (Q_a/Q_b)**1.8 * (mu_a/mu_b)**0.2

def free_cooling_ok(wb_c, tcs_lft_c, a_tower=4.0, a_hx=2.0, a_cdu=4.0) -> bool: ...

def ride_through_s(failure_mode: str, load_kw: float, *,
                   loop_l: float | None = None,
                   plate_c_kj_k: float | None = None,
                   t_start_c: float = 30.0, t_limit_c: float = 45.0) -> float:
    ...                          # failure_mode 缺席 -> raise，不可有預設值
```

### 驗收表

五列全過才算完成。

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | `tcs_flow_lpm(1000, 9.6, "PG25")` | ≈ **1591 L/min**（1.59 LPM/kW） |
| 2 | 同上改 `"water"` | ≈ **1505**；兩者比值 ≈ **1.057** |
| 3 | `dp_ratio("PG25", "water", 1000, 9.6)` | ≈ **1.24** |
| 4 | `free_cooling_ok(28, 30)` / `(28, 40)` | **False** / **True**；且 `a_cdu` 由 4 改 2 **仍不能**讓 30 °C 那列變 True |
| 5 | `ride_through_s("fws_lost", 1000, loop_l=1000)` vs `("tcs_pump_lost", 1.2, plate_c_kj_k=0.778)` | ≈ **59 s** vs ≈ **10 s**；且 `ride_through_s(load_kw=1000)` 少給 failure_mode 要 **raise** |

**加分題**：把 `RideThrough(resource, failure_mode, seconds, basis)` 建成型別，回頭把 [dc-23](crac-direct-expansion.md) 的 24 秒、[dc-18](chiller.md) 的 5.2 分、[dc-20](thermal-storage-tank.md) 的 15 分塞進同一張表——**看看有幾筆填不出 failure_mode**。那幾筆就是當時沒問清楚的地方。

## 自我檢核

**Q1. 一台 CDU 的 FWS 側斷水，另一台的 TCS 泵雙雙故障。兩者的告警優先序一樣嗎？**

??? note "答案"
    不一樣，差 6 倍。前者約 59 秒（迴路裡 1000 L 的熱慣量還在吸熱），處置是去看冰機／板式 HX／FWS 泵；後者約 10 秒（只剩冷板裡的 0.1 L），處置是立刻降載或關機——**人來不及到現場，只能是自動化**。所以 `ride_through_s` 掛在設備上一定錯，必須是 `(resource, failure_mode)` 的函數。

**Q2. 業主說「我們買 approach 更小的 CDU，就可以不蓋冰機房」。這句話哪裡有問題？**

??? note "答案"
    量級不對。演算二的鏈是 `WB + a_tower + a_HX + a_CDU ≤ T_TCS`。台北設計濕球 28 °C，若 IT 要 30 °C 供水，允許濕球只有 20 °C，缺 8 K；而 a_CDU 從 4 買到 2 只補 2 K。真正的槓桿是 `T_TCS`——30 → 40 °C（W40）一步補 10 K，全年免冰機。但那個值寫在晶片規格書裡，採購時就定死了。同型結論見 [dc-21](plate-hx-free-cooling.md)：塔加大只能 a_tower 4→2，冰水 7→18 是 +11 K。

**Q3. 這張卡會讓你的資料模型長出什麼欄位？**

??? note "答案"
    四類。(1) **`RideThrough(resource, failure_mode, seconds, basis)`** 取代設備上的 `ride_through_s`——同一台機兩個差 6 倍的值。(2) **`Device.embedded_power(ats, energy_storage_j, sccr_ka)`**：冷卻設備第一次往電力模型裡長欄位，[dc-16](dual-corded-equipment.md) 的 `scenario` 傳到 CDU 時不是布林掉電而是「撐 N 秒」。(3) **`Setpoint.owner = ite_vendor` ＋ `mutable = False`**：第一個設施與 IT 都談不動的設定值。(4) **`fluid` 是模式欄位**（同 [dc-14](rack-pdu.md) 的 `wiring`），它改變 `tcs_flow_lpm()` 的係數與壓降常數，所以流量**不可以**被存成設備常數。
