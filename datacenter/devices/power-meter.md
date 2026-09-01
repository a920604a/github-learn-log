---
id: dc-15
title: 電力監測儀表與電錶（power meter / EPMS 感測點）
category: power
written_at: 2026-09-01
sources:
  - https://www.electrical-installation.org/enwiki/Focus_on_IEC_61557-12_standard
  - https://cdn.standards.iteh.ai/samples/63451/87c396de9e76423088236bf87cdf73c1/ISO-IEC-30134-2-2016.pdf
  - https://www.eaton.com/us/en-us/products/low-voltage-power-distribution-control-systems/power-and-energy-monitoring-equipment-and-software/metering-accuracy-faq.html
  - https://product-help.schneider-electric.com/ION-Reference/content/ion%20reference/sliding-window-demand-module.htm
  - https://www.servertech.com/blog/why-pue-level-3-monitoring-is-within-reach
  - https://en.wikipedia.org/wiki/ANSI_C12.20
related: [dc-11, dc-12, dc-13, dc-14, dc-16, dc-39, dc-41, topic-01, topic-07]
---

# 電力監測儀表與電錶（power meter / EPMS sensing point）

前面十四張卡都在算「這條線能扛多少」——銘牌、降載、額定。今天這台東西不扛任何電流，只負責**告訴你實際跑了多少**。它是我的資料模型第一次真正接觸「量測值」，也是 `topic-01`（銘牌 vs 降載 vs 實測）三元組的最後一塊。它掛了不會停電，但會讓上面所有容量規劃瞬間變成猜的。

## 六格

### 拓撲位置

**本卡最大的結構轉折：電錶不在電力樹上。** 它的「上游」與「下游」是同一個——它是掛在某節點或某條邊上的**觀測器**。真正碰電的是感測器：CT（比流器）與 PT／VT（中壓才需要）；錶本體只吃 CT 二次側的 5 A／1 A 或 Rogowski 線圈的毫伏訊號。

典型佈點：市電進線 → 變壓器二次側 → 低壓主開關 → 饋出 → [PDU](pdu-floor.md) 輸入／輸出 → [RPP](rpp-remote-power-panel.md) 分路（BCM）→ [rack PDU](rack-pdu.md)。愈往下游愈多顆、愈便宜、愈不準。

### 容量單位

**它沒有容量。** 它有的是**量測範圍**（CT 變比決定，`400/5` ＝一次側 400 A 對二次側 5 A）與**精度等級**（IEC 61557-12 的 PMD class 0.2/0.5/1/2，或北美 ANSI C12.20 的 0.1/0.2/0.5）。兩者正交。

IEC 61557-12 的完整標示是 `PMD/SD/K70/0,2`——功能型別／安裝方式／溫度等級／精度等級。**整串要進資料庫，不能只留最後那個 0.2。**

### 冗餘表達

量測的冗餘和電力的冗餘是兩回事：2N 路徑上可能只有一顆錶，N 路徑上可能有三顆。實務上的冗餘是**交叉驗證**——上游讀數應約等於下游總和加損失，差太多代表某顆錶或 CT 壞了。這個檢查要我的系統做，設備不會做。

### 遙測介面

Modbus RTU（RS-485 盤內串接，最常見；一顆拉走整條）/ Modbus TCP（`dc-41`）/ SNMP（rack PDU、UPS 較多）/ BACnet/IP（`dc-42`）/ IEC 61850（[MV switchgear](mv-switchgear.md) 保護電驛）。

關鍵點位：`V_ln[3]` / `V_ll[3]` / `I[3]` / `I_neutral` / `P` / `Q` / `S` / `PF` / `f` / `Ea_import`（累積 kWh）/ `demand_P` / `THDi` / `THDv`。**其中 `Ea_import` 與 `demand_P` 的語意跟其他點位完全不同**——見「常見誤解」第 2 條。

### 故障域

錶掛掉的故障域是**資料**不是**電**。但有一個致命例外：**CT 二次側絕對不能開路**——運轉中拆線會在開路端產生極高電壓，可能致命也可能燒毀 CT。所以端子排上有短接棒，拆錶前一定先短接二次側。資料模型後果：換錶是**帶電作業**，`change_class` 不是 `no_permit`（沿用 [busway](busway-and-tap-off-box.md) 的三態）。

### 維護特性

校驗：計費用錶通常 1–5 年一次（看主管機關），非計費用錶多半只在 commissioning 做一次。韌體升級會中斷通訊。換錶不需停電（有短接棒），但**累積 kWh 計數器會從 0 開始**——這是我的資料庫要處理的事，不是設備的。

## 關鍵數字與計算

### 一、精度會沿著感測鏈累加（最容易被忽略的一條）

IEC 61557-12 明文規定：**帶外部感測器的 PMD，其性能等級算法與內建感測器的產品不同**，最終等級要把感測器的 IEC 61869-2 等級與 PMD 本身的等級**合併**。實例：class 0.2 的錶 ＋ class 0.5 的 CT。

```
最壞情況（線性相加）：0.2% + 0.5% = 0.7%
統計合成（RSS）：    √(0.2² + 0.5²) = √0.29 ≈ 0.54%
```

在 2 MW 的 IT 負載上，0.7% ＝ **14 kW**——比兩個 6 kW 機櫃還多；若這顆錶拿來跟客戶分帳，這 14 kW 每個月都在跑。**所以「我們的錶是 class 0.2」不構成任何保證**，資料庫要存的是鏈上每一段的等級。

### 二、CT 在低負載時比銘牌差得多

CT 精度等級是在**額定電流附近**定義的。IEC 61869-2 的驗證電流點是 1% / 5% / 20% / 100% / 120% 額定；class 0.5 在 100% 是 ±0.5%，在 5% 額定時容許誤差要放大好幾倍。實例：新機房第一年，一條裝了 `400/5` CT 的饋線平均只跑 60 A。

```
60 / 400 = 15% 額定
```

15% 落在 5%–20% 這一段，誤差比 ±0.5% 差。**而新機房頭一年正是最需要準確用電資料做容量規劃的時候**——CT 照最終負載選，你卻在初期低負載時讀它。這是系統性的坑，不是個案。

### 三、Demand 的算法會改變答案（fixed block vs sliding）

Schneider PowerLogic 系列預設是 **fixed block、15 分鐘**；同時也支援 sliding block / rolling block（例如 3 個 5 分鐘子區間組成 15 分鐘窗）。

實例：某日 1000 kW 持續 15 分鐘，但這 15 分鐘**跨在兩個固定區間的邊界上**（block #1 的後 7.5 分 ＋ block #2 的前 7.5 分），其餘時間 500 kW。

```
Fixed block #1 = (500×7.5 + 1000×7.5) / 15 = 750 kW
Fixed block #2 = (1000×7.5 + 500×7.5) / 15 = 750 kW
→ 系統報告的尖峰需量：750 kW

Rolling block（15 分鐘窗、5 分鐘步進）能對齊到真正那 15 分鐘：
→ 1000 kW
```

**差 250 kW，也就是 33%。** 同一批原始資料、同一顆錶，只因為聚合方式不同。台電的需量計費用哪一種、我的容量規劃用哪一種，必須是同一種，否則兩邊永遠對不起來。

### 四、PUE 量測點的數值影響

同一機房總用電 1500 kW，UPS 輸出量到 1000 kW；PDU 變壓器效率 98%、下游配電損失 1%，PDU 輸出只剩約 970 kW。

```
PUE₁（UPS 輸出）= 1500 / 1000 = 1.50
PUE₂（PDU 輸出）= 1500 / 970  ≈ 1.546
```

**同一天、同一座機房，差 0.046。** ISO/IEC 30134-2 因此規定 category 一定要當下標寫出來（`PUE₂ = 1,50`），單獨一個「1.5」是沒有意義的字串。

### 來源分歧：PUE 的 level／category 到底綁不綁量測頻率？

- **ISO/IEC 30134-2:2016 §6.1.2** 明寫：本標準**不規定量測頻率**，因為 PUE 是年度指標。Category 1/2/3 只定義**量測位置**（UPS 輸出／PDU 輸出／IT 設備輸入）。
- **The Green Grid 的 Level 1/2/3**（Basic / Intermediate / Advanced）則**同時綁位置與頻率**：Level 1 每月至每週、Level 2 每日、Level 3 連續且間隔 ≤ 15 分鐘。

後果很實際：宣稱「我們做到 PUE Level 3」在 Green Grid 定義下是一年 ≥ 35 040 個資料點，在 ISO 定義下可以是一年 12 個——**對遙測系統的儲存與輪詢設計差一個數量級。** 所以 `measurement_point` 與 `sampling_interval_s` 必須拆成兩個獨立欄位，不能合成一個 `pue_level` 列舉：那個列舉在兩套標準下不等價。

## 常見誤解

**以為輪詢愈密資料愈準，但實際上精度與取樣率完全無關。** Eaton 的比喻：精度是樂手唱得準不準，取樣率是你用 HD 還是舊 VHS 錄他。把輪詢從 5 分鐘改成 5 秒，只是更頻繁地拿到同一個 ±1% 的錯誤值。要更準只能換錶或換 CT。**這條對軟體工程師特別致命，因為「提高取樣頻率」是我們手上唯一能自己動的旋鈕。**

**以為每個點位都是瞬時值，但實際上 `demand` 與 `Ea` 是已聚合過的量。** `demand_P` 是 15 分鐘區間平均，時間戳是**區間結束時間**；`Ea_import` 是單調遞增計數器。把 `demand` 當 point sample 存進 time-series 再做 `avg_over_time`，就是**對平均值再取平均**，區間邊界不對齊時答案是錯的。`Ea` 更糟：會 rollover、會在換錶或韌體升級後歸零，直接存差值會出現巨大負數或假尖峰。這跟 Prometheus counter 的 reset 是同一個問題，解法也一樣（存 raw counter，查詢時偵測 reset）。

**以為 kVA 和 kW 只差一個功因、要哪個都行，但實際上 ISO/IEC 30134-2 §6.1.3 明文禁止用 kVA 算 PUE。** 標準要求用真有效值（true r.m.s.）的 kWh——電壓、電流、功因隨時間同步積分的結果；理由是頻率、相位差與負載反應會讓視在能量與實際能量產生差異，在交流配電上這誤差「本質上就很顯著」。順帶一提「revenue grade」不是規格：Eaton 在 FAQ 裡自承，廠商用 "revenue accurate" 這種泛稱**通常正表示它並不完全符合 ANSI C12.20**；而 C12.20 已於 2022 併入 ANSI C12.1。

## 對資料模型的意涵

1. **電錶不是電力樹上的節點，是掛在節點或邊上的觀測器——schema 第一次需要「標註」而不是「拓撲」。** 前十四張卡建的是一棵樹。錶不能塞進去，否則每插一顆錶深度就多一層，[dc-10b](sts-two-source-relationship.md) 的 common-ancestor 跳數會被污染。要的是 `MeasurementPoint(meter_id, observes_id, observes_kind: node|edge, position: input|output)`；一顆多迴路 BCM 會有 N 個 MeasurementPoint。

2. **每筆讀數必須帶著它的精度出身，值本身不夠。** `chain` 記的是「PMD 0.2 ＋ CT 0.5 ＠15% 額定」整串，因為第二節證明同一顆錶在不同負載率下不是同一個精度。這是 `derating_basis` 的孿生兄弟：又一個「不能是列舉、要能指向來源」的欄位。

3. **`aggregation` 是型別的一部分，不是欄位的裝飾。** `instant` 可以再平均，`max_demand` 不行（會是平均的平均），`energy_accum` 是 counter 必須先偵測 reset。混在同一張 `readings` 表只用 `metric_name` 區分，遲早有人對 demand 做 avg。**型別系統應該讓那件事編譯不過。**

4. **`Dimension.valid` 這個從 [dc-14](rack-pdu.md) 就存在卻一直沒用上的欄位，今天終於有用途。** 錶失聯時實測維度不是 0，是 **stale**。`CapacityReport` 要能表達「這一維我不知道」、自動退回 nameplate 法並吐一條降級 `Finding`。**回報 0 的系統會讓人以為機櫃是空的。**

5. **`measurement_point` 與 `sampling_interval_s` 必須分兩欄**（來源分歧的直接後果，見上）。任何把 PUE category 存成單一列舉的設計，都在兩套標準之間偷偷選了一邊。

## 該問 facility 的問題

1. **「對外報的 PUE 是 category 幾？量測點在哪顆錶上？用 ISO/IEC 30134-2 還是 Green Grid 的定義？」** 第三問決定要不要做連續量測，也決定儲存規模差多少。
2. **「每顆錶的 CT 變比與精度等級表給我；初期負載下這些 CT 實際跑在額定的百分之幾？」** 後半是殺手——CT 照滿載選，我讀它時機房是空的。
3. **「Demand 用 fixed block 還是 rolling？區間幾分鐘？跟台電帳單的計費區間對得上嗎？」** 對不上的話尖峰數字和帳單永遠差一截，而且差得看起來很合理。

## 動手練習（35 分鐘）

把「量測」接進既有的 `CapacityReport`。這是 [dc-14](rack-pdu.md) 那份 code 的直接下游，不要另開檔案。

```python
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Literal

Aggregation = Literal["instant", "avg", "max_demand", "energy_accum"]

@dataclass(frozen=True)
class AccuracyLink:          # 感測鏈上的一段
    kind: Literal["pmd", "ct", "pt"]
    cls: float               # 0.2 / 0.5 / 1.0
    note: str = ""           # 例："＠15% 額定，超出 class 定義點"

@dataclass(frozen=True)
class Reading:
    value: float
    unit: str
    ts: datetime             # max_demand 時＝區間「結束」時間
    aggregation: Aggregation
    interval_s: int | None   # instant 時為 None
    chain: tuple[AccuracyLink, ...]

    def accuracy_pct(self, mode: Literal["worst", "rss"] = "worst") -> float:
        """worst = 線性相加；rss = 平方和開根號。"""
        ...
    def band(self) -> tuple[float, float]:
        """回傳 (下界, 上界)。容量報表要用區間，不是點值。"""
        ...

@dataclass
class Meter:
    id: str
    pmd_marking: str         # 整串 "PMD/SD/K70/0,2"，不要只存 0.2
    ct_ratio: tuple[int, int] | None   # (400, 5)
    ct_class: float | None
    last_seen: datetime
    def is_stale(self, now: datetime, ttl: timedelta) -> bool: ...

@dataclass(frozen=True)
class MeasurementPoint:
    meter_id: str
    observes_id: str
    observes_kind: Literal["node", "edge"]
    position: Literal["input", "output"]
```

要實作的三個行為：

1. `accuracy_pct()` 與 `band()`——鏈式合成，兩種 mode 都要。
2. `Dimension` 新增 `method="measured"`；實測法的 `remaining` 用 `band()` 的**保守端**，不是中央值。
3. **降級路徑**：`is_stale()` 為真時 `measured` 維度 `valid=False`，`CapacityReport` 退回 `nameplate` 法並產出 `Finding(policy_id="METER_STALE", severity="WARNING")`。

**驗收表：**

| 案例 | 期望 |
|---|---|
| chain = (PMD 0.2, CT 0.5)，value=1000 kW | `accuracy_pct("worst") == 0.7`；`band() == (993.0, 1007.0)` |
| 同上，`mode="rss"` | `accuracy_pct` ≈ 0.539（±0.001） |
| `measured` 維度，量到 1000 kW、上限 1200 kW | `remaining` 用下界算 → `1200 - 1007 = 193`，**不是 200** |
| meter `last_seen` 是 2 小時前、ttl=15 min | `measured` 維度 `valid=False`；`binding()` 跳過它；吐出一條 `METER_STALE` |
| 對 `aggregation="max_demand"` 呼叫 `.mean_with(other)` | 拋 `TypeError`（**重點：讓錯誤的聚合在型別層就過不了**） |

**加分題**：`cross_check(upstream, downstreams, tol_pct)`——驗證上游讀數落在下游總和的誤差帶內。這就是「冗餘表達」那格講的交叉驗證，也是抓 CT 裝反／變比設錯最有效的方法。

## 自我檢核

**Q1. 你把某條饋線的 Modbus 輪詢從 5 分鐘改成 5 秒，資料變準了嗎？如果沒有，什麼情況下這件事仍然值得做？**

??? note "答案"
    **沒有。** 精度由 PMD 等級與 CT 等級決定，跟取樣率正交（Eaton 的樂手／攝影機比喻）。±1% 的錶輪詢再密還是 ±1%。

    但仍值得做的情況：**要抓的是短時事件而非穩態值**——[STS](static-transfer-switch.md) 切換暫態、[發電機](genset-start-and-transient.md) 起動時的電壓下陷、跨 block 邊界的真實尖峰（第三節那個 750 vs 1000 kW）。這些在 5 分鐘取樣下根本不存在。

    一句話：**取樣率決定你「看得到什麼事件」，精度決定你「數字有多可信」。** 兩者都要，但不能互相替代。

**Q2. 這張卡會讓你的資料模型長出什麼欄位？至少三個，並說明「不存會怎樣」。**

??? note "答案"
    - **`Reading.aggregation` ＋ `interval_s`**：不存則 `demand`（區間平均）和 `P`（瞬時）被當同一種東西，下游任何 `avg`／`max` 都在對聚合值再聚合；且 `demand` 的時間戳是區間**結束**時間，當 point sample 畫會整體右移一個區間。
    - **`Reading.chain`**：只存一個 `accuracy_pct` 會漏掉 CT（常是誤差大頭），也表達不了「同一顆錶在 15% 額定時比銘牌差」。
    - **`MeasurementPoint(observes_id, observes_kind, position)`**：不存則錶只能塞進電力樹當節點，common-ancestor 跳數被觀測器污染。
    - **`Meter.last_seen` ＋ `Dimension.valid`**：不存則失聯被當成「量到 0」，容量報表會宣告機櫃是空的。

    **反過來不該存的**：`accuracy_pct`（算得出來且依負載率而變）、`pue_level`（見來源分歧）。

**Q3. 有人拿一份「本季 PUE = 1.42」的報告給你。你要追問哪三件事才知道這個數字能不能跟去年比？**

??? note "答案"
    1. **Category 幾？** PUE₁ 和 PUE₂ 在同一座機房就差 0.04–0.05（第四節）。ISO/IEC 30134-2 §7.1.1 規定 category 必須當下標寫出來，沒寫的數字不合規也不可比。
    2. **量測期間多長、頻率多少？** ISO 的 PUE 定義在 12 個月上，不足一年的叫 iPUE，是不同指標；而 Green Grid 的 Level 還額外綁頻率。
    3. **量測點有沒有搬過家？** 去年在 UPS 輸出、今年改到 PDU 輸出的話，數字變大**不代表變差**，是量到了原本藏進 IT 項的損失。這種「改善導致指標變醜」正是 `measurement_point` 必須跟著每一筆歷史資料一起存的理由——存在設定檔裡不夠。
