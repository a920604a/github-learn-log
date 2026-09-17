---
id: dc-25
title: 冷熱通道封閉（containment）
category: cooling
written_at: 2026-09-17
sources:
  - https://www.facilitiesnet.com/whitepapers/pdfs/APC_011112.pdf
  - https://www.upsite.com/blog/hot-aisle-containment-vs-cold-aisle-containment-better-data-center/
  - https://www.knews.com.tw/news/CB3A885A77139DDA75355AAFBA9D372C
  - https://title24stakeholders.com/measures/cycle-2022/data-center-efficiency/
related: [dc-22, dc-23, dc-25b, dc-29]
---

# 冷熱通道封閉（aisle containment）

一排門、一片頂板、幾塊盲板。沒有壓縮機、沒有泵、銘牌上沒有 kW，整套買回來不到一台 CRAH 的錢。但它是整條冷卻鏈上唯一能同時鬆開三個設定值的東西——送風溫度、風扇轉速、冰水設定值。[dc-22](crah-chilled-water.md) 算出「型錄那列 75 °F 回風本身就是一間旁通 43% 的機房」，封閉就是把那 43% 從**營運習慣的後果**變成**設計變數**。

> 初稿超過字數上限，度量的部分（λ / RTI / RCI、合規判準、差壓設定值）拆給 `dc-25b`。

## 六格

| 格 | 內容 |
|---|---|
| **拓撲位置** | **不在任何一棵樹上。** 它是**房間的邊界條件**，改變的是 [dc-22](crah-chilled-water.md) 的 `AirBalance`，不是任何一條邊的流量。繼 [dc-15](power-meter.md) 的「標註」、[dc-17](cooling-tower.md) 的「站點外生變數」、dc-22 的「房間層級」之後第四類非樹物件：**幾何**。唯一掛在樹上的是端門與 drop-away 頂板的致動器 |
| **容量單位** | 沒有 kW，是**無因次比值**：`λ = CRAH 風量 / IT 風量`、洩漏率。WP135 基準：高架地板洩漏典型 25–50%，封閉系統 3–10%。**前 24 張卡第一次容量單位不是物理量**，詳見 `dc-25b` |
| **冗餘表達** | N / N+1 **沒有定義**。它不會壞掉，它會**降級**——門被撐開、盲板被抽走、地磚被挪去別排、頂板沒裝回去，而且是連續的不是二元的。對偶是 `integrity` |
| **遙測介面** | `aisle_dp_pa`（對房間差壓，控風扇轉速；設定值分歧見 `dc-25b`）／`door_state[]`（磁簧，多數現場沒接）／`intake_temp[]`（[dc-20](thermal-storage-tank.md) 的 `SensorArray`，頂點才看得到再循環）／`ceiling_panel_state`（**幾乎沒廠商提供**）。無統一協定，散在 BMS、門禁與消防盤三處 |
| **故障域** | **一條通道 ＝ 一個故障域，且與電力故障域正交。** 同一通道的機櫃可能吃不同 [rack PDU](rack-pdu.md)、不同 UPS 母線。前 24 張卡的 `fault_domain` 全沿接線推導；封閉的是**用尺量出來的** |
| **維護特性** | **沒有維護週期。** 退化由 MAC 次數驅動不由時間驅動——每次上架、拉線、挪地磚都是一次退化事件。本軌跡第一個 `MaintenanceRule` 無法用 cron 表達的 |

---

## 關鍵數字與計算

### 演算一：HACS 比 CACS 省 43%，而那 43% 全部來自一次減法的方向

APC WP135（Rev 2，Chicago，700 kW IT、100 櫃、伺服器溫升 25 °F ＝ 13.9 K）常被引用成「熱通道封閉比較有效率」。**它不是。** 把三個情境的溫度反推一遍：

| 情境 | 未封閉區上限 | CACS 的 IT 進風 | HACS 的 IT 進風 |
|---|---|---|---|
| 1. 不限制未封閉區 | — | 27（熱通道 27 ＋ 13.9 ＝ **40.9**）| 27 |
| 2. 未封閉區 ≤ 27 °C | 27 | 27 − 13.9 ＝ **13.1** | 27 |
| 3. 未封閉區 ≤ 24 °C | 24 | 24 − 13.9 ＝ **10.1** | 24 |

三列全對得上 WP135 表 1 印的 41 / 13 / 10 °C。**CACS 的懲罰就是這一個減號**：冷通道封閉時房間＝熱通道，人的約束與 IT 的約束被伺服器溫升隔開；熱通道封閉時房間＝冷通道，兩者是同一個溫度。

結果：情境 1（不管人）兩者 economizer 都是 6 218 小時、PUE 都是 1.65，**完全相同**；情境 3 的 HACS 是 5 319／1.69，CACS 是 **0 小時／1.98**，比完全不封閉的基準（2 814／1.84）**還糟**。

**所以 43% 不是熱力學性質，是 OSHA 的價格。** 綁住它的是 WBGT（`0.7 × 自然濕球 ＋ 0.3 × 黑球`，機房可用乾球代黑球）：OSHA 連續作業上限 30 °C、25% 工作 75% 休息上限 32.2 °C，WP135 據此算出 HACS 熱通道可放到 47 °C。**一個人因法規的門檻，沿著上表那個減號一路傳到冰水設定值。**

**而懲罰隨伺服器溫升放大。** WP135 自己明說這一點。[dc-22](crah-chilled-water.md)／[dc-23](crac-direct-expansion.md) 用的現代溫升是 20 K：

```
CACS，房間維持 24 °C  →  IT 進風 = 24 − 20 = 4 °C
```

送風 4 °C 意味冰水設定值約 0 °C。**無解。** 在 dc-22 那間機房裡，「封閉冷通道 ＋ 房間維持 24 °C」這個組合根本不存在，不是比較差。

順帶驗證 [dc-21](plate-hx-free-cooling.md) 的門檻式：情境 3 CACS 的冰水 2.4 °C 代進 `WB_門檻 = T_chws − a_tower − ΔT(1−ε)/ε`（取 4 K、6 K、0.75）得 `−3.6 °C`，與 WP135 那個 0 小時一致。**但 WP135 是 Chicago 的研究，5 319 小時在台北拿不到——台北的封閉買到的是風扇能耗與機櫃密度。**（代入推導，非原文結論。）

### 演算二：封閉讓 ride-through 變短，而且短到撐不過發電機起動

沿用 [dc-23](crac-direct-expansion.md) 的機房（1000 m² × 4 m、1600 kW IT、`ρcp = 1.21 kJ/(m³·K)`）。停電瞬間 CRAH 風扇停、伺服器風扇（在 UPS 上）繼續抽，**能用的冷空氣只有伺服器抽得到的那一塊**。假設 4 條通道各 `1.2 × 20 × 2.4 = 57.6 m³`（合計 230），高架地板 `1000 × 0.6 = 600 m³`：

| 配置 | 冷空氣庫存 | 熱容 | 升溫率 | 24 → 32 °C |
|---|---|---|---|---|
| 熱通道封閉（房間即冷側） | 3 770 ＋ 600 ＝ 4 370 m³ | 5 288 kJ/K | 18.2 K/min | **26 秒** |
| 冷通道封閉（只有通道＋地板下） | 230 ＋ 600 ＝ 830 m³ | 1 004 kJ/K | 95.6 K/min | **5.0 秒** |

差 5.3 倍。而 [dc-23](crac-direct-expansion.md) 的參考時間是：發電機起動約 10 秒、CRAC anti-short-cycle 休息 300 秒。

**冷通道封閉的 5 秒連發電機起動都撐不過。** 這不是「要不要裝儲冷槽」的問題——[dc-20](thermal-storage-tank.md) 的 15 分鐘與 [dc-18](chiller.md) 的 5.2 分鐘都是**水側**慣量，前提是泵還在轉、風扇還在吹；風扇一停，水側再多的冷量也送不進通道。**CRAH 風扇上不上 UPS 在這裡不是節能選項，是可用性前提。**

（純空氣上界，機櫃鈑金與樓板熱容會讓實際慢數倍，修正係數未查證；但 5 對 26 的**比值**只跟幾何有關。）

---

## 常見誤解

**以為封閉是節能措施，但實際上封閉本身不省任何一度電。** 它只是把三個被鎖死的設定值解鎖：送風溫度、風扇轉速、冰水設定值。Upsite 的說法是兩種封閉都「創造出一個可以降低風扇轉速或關掉機組的環境」，省電來自後續的**調整動作**。**裝完封閉沒有人去改設定值的機房，買到的是純成本。** 而改設定值要跨設施與 IT 兩個平面（[dc-21](plate-hx-free-cooling.md) 記的第三次穿越），經常沒發生。

**以為供風多一點（λ > 1）是安全裕度，但實際上封閉把失效模式從漸進變成懸崖。** 未封閉時 `λ < 1` 的症狀是機櫃頂部先熱、由上往下漸進；封閉冷通道時 `λ < 1` 會讓通道轉為**負壓**，熱空氣從每一道縫、每一個沒裝盲板的 U 位、每一個沒封的線孔同時倒灌，**整條通道一起失效而不是由上往下**。而 `λ > 1` 封閉後也不再是裕度——它只是正壓。封閉把 λ 從軟性指標變成一個有懸崖的硬約束。

**以為封閉是一次性工程，但實際上它每天在退化，而且會被別的系統實體拆掉。** 兩種退化都不在維護排程上：日常 MAC 讓 `integrity` 連續下滑；消防動作（fusible link 熔斷或煙偵觸發）讓 drop-away 頂板**整片落下**。後者是本軌跡第一個「另一個系統有權即時改寫容量模型前提」的耦合，而它通常沒有回授點位。

---

## 對資料模型的意涵

**1. `fault_domain` 第一次不是單一欄位，是不同軸上的集合。** 封閉通道是幾何邊界，rack → aisle 的歸屬靠座標算不靠接線。同一通道的櫃子可分屬不同 [rack PDU](rack-pdu.md)／不同 UPS 母線，所以要拆成 `{power, cooling, containment}`。壓成單一字串的話，「一條通道整條熱掉」這個封閉機房最典型的事件會被歸到錯的故障域。這也讓 [dc-19b](npsh-and-pump-placement.md) 提前叫出來的空間層級（`dc-28`）再欠一次：沒有座標就算不出通道歸屬。

**2. `Containment.integrity` 是 `Dimension` 的第四種 invalid，而且觸發者在模型外。** drop-away 頂板落下後 [dc-22](crah-chilled-water.md) 的 `CapacityReport.assumed_return_air_c` 當場失效，**而沒有任何 BMS 點位會說「頂板掉了」**。`integrity` 要是可觀測狀態（門接點 ＋ 頂板狀態 ＋ 盲板稽核日期），`AirBalance` 標 `valid_while(integrity == intact)` 並吐 `Finding.CONTAINMENT_DEGRADED`。前三種 invalid：[dc-15](power-meter.md) 錶失聯 stale、[dc-19b](npsh-and-pump-placement.md) 公式適用域失效、[dc-24](humidification-dehumidification.md) 群體不一致。**這第四種最麻煩：前三種是感測或模型的問題，這一種是物理世界真的變了。**

**3. `MaintenanceRule` 第一次不能是時間排程。** 退化由 MAC 次數驅動 → `MaintenanceRule(trigger: schedule | event_count)`，稽核掛在異動流程上不是 CMMS 日曆上。

**4. `CodeRule.threshold` 要是 `(metric, scope, value)` ＋ `edition` ＋ `jurisdiction`**（見來源分歧四）：缺一就會把「每機房 10 kW」跟「站點 5 MW」塞進同一欄比大小。沿用 [dc-09c](lib-fire-compliance.md)。

---

## 來源分歧

**（一）HACS 比 CACS 好多少：43% vs 沒有顯著差異。** APC WP135 Rev 2 給 43% 冷卻能耗、15% PUE；Intel 與 T-Systems 在德國實驗機房的第三方實測論文標題直接是《Hot-Aisle and Cold-Aisle Containment Efficiencies Reveal No Significant Differences》（經 Upsite 引述）。**兩邊都沒錯**——WP135 情境 1 兩者 PUE 完全相同，43% 全部來自情境 3 那個「房間要維持 24 °C 給人待」的約束。**差別在有沒有把人因約束算進去，不在設備。** 規格書要指名情境。

**（二）封閉型式與 ride-through 的方向相反。** Upsite 把「提供更多冷源表面積供停電時 ride-through」列為**冷通道封閉的優點**；演算二的空氣質量帳結論相反（冷通道封閉的庫存只有熱通道封閉的 1/5）。可能的調和是 Upsite 指的是地板與樓板的**固體**熱質量（兩種封閉都有）。**未能確認，兩說並列。**

**（三）消防要把封閉當獨立防護區還是障礙物。** Upsite：**冷**通道封閉構成 NFPA 所稱的「separate volume」，整室滅火之外還要再給通道一套，或讓封閉在煙偵動作時自行解除；**熱**通道封閉因結構通常頂到天花，只是**障礙物**，滿足撒水頭淨空即可。APC WP135 則說 NFPA 75 對此**不表示意見**，只給兩條可援引的規定，並直接寫「應向當地 AHJ 確認」。→ **這是 AHJ 的裁量，必須當成專案輸入而不是設計常識。**

**（四）法規門檻跨轄區不可比，而且度量的不是同一件事。**

| | 加州 Title 24 §140.9(a)6 | 台灣（能源署，2025-11 修法） |
|---|---|---|
| 要求 | 規範性路徑須設**氣流阻隔**，使排氣無顯著路徑不經冷卻系統即回到進風 | 新設／擴建前提「能源使用先期規劃」送審，7 大檢核項目第 4 項為「冷卻系統：設計冷熱通道，採用液冷技術」 |
| 門檻度量 | **每機房 ITE 設計負載 kW** | **站點能源使用數量 MW** |
| 門檻值 | 2016 版 175 kW → **2022 版降到 10 kW** | 5 MW |
| 附帶 | 例外：擴建、每櫃 < 1 kW、CFD 證明等效 | PUE 上限：超大型 1.3／主機代管 1.4 |

**10 kW 與 5 MW 不能比大小**——一個是單一機房的 IT 負載，一個是整站的能源使用量；而加州自己在兩版之間把門檻降了 17.5 倍。台灣的法源是《能源管理法》第 16 條授權修正的三項子法。

**實務結論**：站點用電未達 5 MW 時台灣目前**沒有**強制封閉的條文；同一間機房搬到加州，10 kW 就要裝。所以封閉在台灣是**自己的工程決定**，論證要靠演算一與演算二，不能靠「法規要求」。

---

## 該問 facility 的問題

1. **設計的是熱通道封閉還是冷通道封閉？伺服器設計溫升抓多少？** 若是冷通道封閉且溫升 20 K，請對方當場算 `房間目標 − 20`（演算一）。
2. **CRAH／CRAC 風扇在不在 UPS 上？** 冷通道封閉時這是 5 秒對 10 秒（演算二），不是節能問題。
3. **消防把封閉當獨立防護區還是障礙物？頂板是 drop-away 還是固定？若是，動作後有回授點位進 BMS 嗎？**

---

## 動手練習（30–40 分鐘）

接 [dc-24](humidification-dehumidification.md) 的 `RoomReport`。今天做**幾何與完整性**這一半，度量那一半（λ / RTI / RCI）明天在 `dc-25b` 接上。建 `containment.py`：

```python
@dataclass
class Containment:
    aisle_id: str
    kind: str                    # "hot" | "cold" | "none"
    doors_closed: bool
    ceiling_intact: bool | None  # None = 沒有回授點位（多數現場）
    blanking_audited_on: str | None
    @property
    def integrity(self) -> str:  # 任一項 None → "unknown"，不可當 "intact"
        ...

@dataclass
class Aisle:
    id: str
    racks: list[str]             # 靠座標算出來的，不是靠接線
    containment: Containment
    def fault_domains(self, registry) -> dict[str, set[str]]:
        ...  # {"power": 沿電力樹回推、**通常不只一個**, "cooling", "containment"}

def ride_through_s(cold_volume_m3, load_kw, dt_allowed_k, rho_cp=1.21): ...
def evaluate(aisle, ride_s, gen_start_s=10.0, restart_s=300.0) -> list[Finding]: ...
```

`evaluate()` 至少要吐這三種 `Finding`，互不合併：

- `CONTAINMENT_DEGRADED` — `integrity != "intact"`；`unknown` 也算，理由要分（缺點位 vs 已知壞掉）
- `RIDE_THROUGH_INSUFFICIENT` — [dc-23](crac-direct-expansion.md) 定義的，今天第一次有第二個來源餵它
- `FAULT_DOMAIN_SPLIT` — 同一通道的機櫃分屬 2 個以上電力故障域。不是錯誤，是**該被記錄的事實**

### 驗收表

四列全過才算完成。

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | 冷通道封閉，`cold_volume=830`、1600 kW、`dt=8` | `≈ 5.0` 秒、`RIDE_THROUGH_INSUFFICIENT` |
| 2 | 熱通道封閉，`cold_volume=4370`，其餘同上 | `≈ 26.4` 秒；**仍應吐 `RIDE_THROUGH_INSUFFICIENT`**，因 26.4 < 300。兩個門檻寫成 `list[Limit]`，`basis` 分別是 `generator_start` 與 `crac_restart_delay`——`Limit.basis` 第一次用在**時間**維度上 |
| 3 | `ceiling_intact = None` | `integrity == "unknown"`、`CONTAINMENT_DEGRADED(reason="no_feedback_point")`，下游要拿到 invalid 而非 `False` |
| 4 | 通道 10 櫃分屬 2 條 UPS 母線 | `fault_domains()["power"]` 長度 2、吐 `FAULT_DOMAIN_SPLIT`，`containment` 那組恆為 1 |

---

## 自我檢核

**Q1. 為什麼「冷通道封閉 ＋ 房間維持 24 °C」在現代高溫升機房裡是無解的，而不只是比較差？**

??? note "答案"
    冷通道封閉時房間就是熱通道，`房間溫度 = IT 進風 + 伺服器溫升`。要房間 24 °C，IT 進風就得是 `24 − ΔT`。WP135 的 13.9 K 溫升下是 10.1 °C（economizer 歸零、PUE 1.98 比不封閉還差）；現代 20 K 溫升下是 **4 °C**，冰水設定值約 0 °C，冰機做不到。熱通道封閉沒有這個減法——房間就是冷通道，人的約束與 IT 的約束是同一個溫度。**43% 的全部來源就是這個減號，而它隨溫升放大。**

**Q2. 封閉做好之後，停電時的 ride-through 變長還是變短？為什麼這件事跟儲冷槽無關？**

??? note "答案"
    冷通道封閉會**變短**且是數量級的：冷空氣庫存從整個房間（4 370 m³）縮到通道加地板下（830 m³），24 → 32 °C 從 26 秒掉到 5 秒。跟儲冷槽無關是因為 [dc-20](thermal-storage-tank.md) 的 15 分鐘與 [dc-18](chiller.md) 的 5.2 分鐘都是**水側**慣量，前提是泵還在轉、**風扇還在吹**。風扇一停，冷水再冰也送不進通道。所以結論不是「加儲冷槽」，是「CRAH 風扇上 UPS」。這是 [dc-18](chiller.md) 之後第二個「加強某一項反而讓另一項變糟」的案例。

**Q3. 封閉這件事會讓你的資料模型長出哪些欄位？挑最容易被漏掉的兩個講。**

??? note "答案"
    (a) **`Containment.integrity` 與 `AirBalance.valid_while`。** drop-away 頂板在煙偵動作後會落下，而 BMS 沒有任何點位說這件事發生了；少了它，`CapacityReport.assumed_return_air_c` 會在火警演練後靜默變錯。它必須三態：沒有回授點位時是 `unknown`，**不可當成 `intact`**。
    
    (b) **`fault_domain` 要拆成多軸的集合。** 通道邊界是幾何不是接線，同一通道的櫃子可分屬不同 UPS 母線。壓成單一字串的話，「一條通道整條熱掉」會被歸到錯的故障域，[dc-16](dual-corded-equipment.md) 的 `scenario` 分析也會在通道層級失真。
    
    另外兩個：`MaintenanceRule.trigger` 要能表達 MAC 次數；`CodeRule.threshold` 要帶 `metric` 與 `scope`。
