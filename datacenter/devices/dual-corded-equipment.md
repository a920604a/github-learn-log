---
id: dc-16
title: 設備端雙電源與單電源（dual-corded / single-corded + rack ATS）
category: power
written_at: 2026-09-02
sources:
  - https://www.se.com/us/en/product/AP4423A/apc-netshelter-rack-automatic-transfer-switch-1u-16a-230v-2-c20-in-8-c13-1-c19-out-50-60hz/
  - https://epcas.com.tr/en/sts-vs-ats-transfer-time-the-itic-curve-and-which-one-belongs-where
  - https://www.dell.com/support/kbdoc/en-us/000202926/poweredge-power-settings
  - https://www.belden.com/blog/exploring-dual-power-feeds-in-data-centers
  - https://netboxlabs.com/docs/netbox/features/power-tracking/
  - https://github.com/netbox-community/netbox/discussions/12837
  - https://www.trgdatacenters.com/resource/rack-mounted-ats-power-redundancy/
related: [dc-10, dc-10b, dc-14, dc-15, topic-03, topic-04, topic-06, topic-10]
---

# 設備端雙電源與單電源（dual-corded / single-corded + rack ATS）

伺服器後面那兩條 C13／C19 電源線，一條插 A 側 rack PDU、一條插 B 側。這是整條電力鏈的**終點**——再往下就是主機板了。

但它也是整條鏈上第一個**有兩個父節點的東西**。前面 15 張卡建的是一棵樹：每個節點一個上游。[dc-10](static-transfer-switch.md) 的 STS 有兩個源，但 STS 只有幾台。雙電源設備一來就是幾千個多父節點的葉子——**樹在最後一跳變成 DAG**，而所有沿樹寫的容量演算法都得重寫。

## 六格

### 拓撲位置
上游：**兩個**，A／B 兩側 [rack PDU](rack-pdu.md) 的插座（單電源設備則是 → rack ATS → 兩側）。下游：無，這是葉節點。

### 容量單位
不是一個數字，是**一組情境下的數字**：`normal` 每側各吃多少、`failover` 單側吃多少。PSU 銘牌 W 在這裡幾乎沒用——那是 PSU 的輸出上限，不是伺服器的需求。

### 冗餘表達
2N ＝兩條線接到**上游沒有共同祖先**的兩側。N ＝單電源直插。中間態是單電源＋rack ATS，它把兩個父節點收斂回一個——**ATS 本身變成新的單點**。

### 遙測介面
| 來源 | 點位 |
|---|---|
| Redfish `Chassis/Power`／iDRAC | 每顆 PSU 輸入功率、線電壓型別（high/low line）、PSU 狀態 |
| Redfish `PowerSubsystem` | `PowerSupplyRedundancy` 政策、hot spare 開關、primary PSU |
| rack PDU outlet 計量（[dc-14](rack-pdu.md)） | 從設施側看到的同一顆 PSU 吃電 |
| rack ATS SNMP | 目前來源（A/B）、轉換次數、來源電壓 |

**同一件事有兩個真相來源**（伺服器量的 vs PDU 量的）且會不一致——正是 [dc-15](power-meter.md) 交叉驗證的著力點。

### 故障域
單電源直插：上游任一段掉 → 死。單電源＋ATS：ATS 死 → 死，任一側死 → 活。
雙電源：任一側死 → 活，但**整櫃的另一側瞬間吃雙倍**——故障域從「這台機器」變成「這一側全部機器同時加倍」。

### 維護特性
雙電源是 concurrent maintainability（`topic-05`）的實體基礎：A 側整段可停機檢修。前提是 B 側單獨扛得住 100%——**這是容量問題不是拓撲問題**。

## 關鍵數字與計算

### 1. 為什麼是「每側 ≤ 50%」——這個數字是推出來的，不是規定

約束只有一條：**單側必須扛得住全機櫃負載**。

```
P_rack ≤ C_side        （C_side = 單側 rack PDU 的 derated 容量）
```

正常時兩側平分，所以每側的日常讀數是 `P_rack / 2 ≤ C_side / 2`，也就是 50%。**50% 是結論不是前提**——若 PSU 政策不是平分（見下），50% 這個數字立刻失效，但上面那條約束永遠成立。

代數字。承 [dc-14](rack-pdu.md)：兩條 208 V delta 30 A rack PDU，derated 24 A，單側容量

```
C_side = √3 × 208 × 24 = 8 646 VA
```

- 機櫃 8 kW（PF 0.99 → 8 081 VA）：正常每側 4 040 VA＝**46.7%**；failover 8 081 VA＝**93.5%**，過但沒餘裕。
- 機櫃 10 kW（10 101 VA）：正常每側 50.5% 看起來還好，failover **116.8%** → 斷路器跳。**日常儀表板一片綠，事故當下才發現。**

所以容量報表**必須在 failover 情境下算**，不能只算今天的讀數。這是 [dc-10b](sts-two-source-relationship.md)「枚舉配置取 max」從 STS 推廣到每一個葉節點。

### 2. Hot spare：50/50 這個假設是伺服器的設定，不是物理

Dell 的 PSU 政策有三種（`Not Redundant` / `A/B Grid Redundant` / `PSU Redundant`），另有 **Hot Spare** 開關：啟用時一顆 PSU 進睡眠、**幾乎全部負載壓在 active 那顆**，並可用 `Primary PSU` 指定是哪一顆。Dell 自己寫明「若客戶需要負載平均分配，最好關掉 hot spare」。

同一個 8 kW 機櫃：

| 政策 | A 側 | B 側 | failover 後 |
|---|---|---|---|
| 平分 | 4 040 VA（46.7%） | 4 040 VA（46.7%） | 8 081 VA（93.5%） |
| Hot spare，primary=PSU1（全在 A） | 8 081 VA（**93.5%**） | ≈0 | 8 081 VA（93.5%） |

總量一樣，**設施側看到的是完全不同的兩張圖**。更糟的是若整櫃伺服器都用出廠預設 `Primary PSU = 1`，A 側天天貼著 93.5% 跑，而這個事實**不在設施的任何一張表裡**——它在 iDRAC。

### 3. 8 ms 夠不夠：rack ATS 的餘裕比帳面小

APC AP4423 標稱轉換時間 **典型 8 ms／< 10 ms**。ITIC 曲線要求 IT 設備能撐過 **20 ms** 完全失壓，這 20 ms 來自 PSU 直流匯流排電容的 hold-up。

```
餘裕 = hold-up − 轉換時間 = 20 − 8 = 12 ms
```

但 **hold-up 是在滿載條件下標的**。EPC 指出負載到 90% 的 PSU 可能只撐 12 ms：

```
餘裕 = 12 − 8 = 4 ms
```

而 failover 當下正好是負載最高的時刻。這 4 ms 沒有任何監控看得到。

!!! warning "來源分歧：「ATS」這個詞跨了兩個數量級"
    - **EPC Energy**：接觸器式 ATS 約 **100–500 ms**，馬達操作斷路器對更慢；只有 SCR 式 STS 才做得到 4–8 ms。並直言「UPS 下游放 ATS 餵伺服器，不是保護它們，是重開它們」。
    - **Schneider/APC**：機櫃級 AP4423 這類產品掛 "ATS" 名，實測典型 **8 ms**。
    - **TRG Datacenters**：行銷文案只寫「seamless、no noticeable downtime」，不給數字。

    兩邊都沒錯——**機櫃級「ATS」與設施級 ATS 是不同的東西共用一個名字**。後果直接落在資料模型上：`device_role == "ats"` **推不出**轉換時間。

### 4. 地區差異：PSU 額定隨輸入電壓變

Dell 明寫：14G 以後的 PSU 會偵測 high line（~220 V）／low line（~110 V）並切換輸出瓦數。1100 W 的 PSU 在低線只給 1050 W；**更極端的例子是 2000 W PSU 在低線只剩 1000 W**。

台灣機櫃常見 220 V，屬 high line，通常拿得到銘牌值——但**具體型號的對應表未查證**，不要把「台灣＝滿額」當通則。這也解釋了 Dell 的排障建議：機器搬家後開不了機，先關掉 PSU 冗餘讓所有 PSU 都出力。

## 常見誤解

**以為兩條電源線就是 2N，但實際上冗餘可能只存在於線纜這一層。** 兩條線若最後匯到同一台 UPS、同一面 RPP、甚至同一條 busway，[dc-10b](sts-two-source-relationship.md) 的 common-ancestor 測試會失敗。以前這個測試只要對幾台 STS 跑，現在要對**每一台伺服器**跑。

**以為雙電源設備每側各吃一半，但實際上分配比例是伺服器的設定，設施側看不到。** Hot spare 開著時是 100/0 不是 50/50，而這個設定住在 iDRAC。設施看到的「A 側嚴重不平衡」可能完全是設計行為。

**以為單電源接上 rack ATS 就等於雙電源，但實際上你只是把單點從電源路徑搬到 ATS 上。** 而且能不能撐過去取決於 PSU 的 hold-up——高負載時餘裕可能只剩 4 ms。ATS 是妥協方案，不是等價替代。

## 對資料模型的意涵

1. **樹在葉節點變成 DAG，`load` 不能是純量。** `PowerEdge` 需要 `share_normal` 與 `share_failover` 兩組值，而 failover 的值取決於「哪一側掛了」——所以它不是欄位是**情境函數** `load(scenario)`。所有沿樹的前綴和（[dc-13](busway-and-tap-off-box.md) 立的）都要參數化成 `prefix_sum(edge, scenario)`。

2. **容量報表要多一維：`scenario`。** [dc-14](rack-pdu.md) 的 `CapacityReport` 目前是四維（input_current／bank／outlet／rack_u），現在每一維都要在 `normal` 與 `lose_a`／`lose_b` 三個情境下各算一次，`binding()` 取跨情境的最壞值。**這是第五種容量報表，也是第一個會讓既有數字變壞的**——10 kW 機櫃從「50.5%，綠燈」變成「116.8%，紅燈」。

3. **`psu_policy` 的真相在 IT 管理平面，不在設施側。** 這是繼 [dc-15](power-meter.md)「拓撲 vs 標註」之後的第二條分界：**設施資料模型有一部分欄位必須從 Redfish／iDRAC 匯入**，且會被伺服器管理員在設施完全不知情的情況下改掉。所以 `psu_policy` 要帶 `source="redfish"` 與 `fetched_at`，並且**改變時要觸發容量重算**，不是靜態設定。

4. **`redundancy_class` 是三態不是布林。** `dual_corded` / `single_corded_on_ats` / `single_corded`。中間態特殊在它**新增一個節點到拓撲上**——rack ATS 是真的在電力樹上（不像 [dc-15](power-meter.md) 的電錶是標註），它是那台設備的新共同祖先，故障域要把它算進去。

5. **NetBox 斷點第二條（記給 `topic-10`）。** NetBox 有 `PowerFeed.type = primary|redundant`，但**機櫃用電率計算不看這個欄位**：雙電源設備兩個 power port 各填 500 W，機櫃就顯示 1000 W。社群 discussion #12837 的結論是「需要一個 flag 讓冗餘連線不被重複計算」，至今未實作。第一條斷點（[dc-14](rack-pdu.md) 的 `feed_leg` 不支援 delta）是**表達不了**，這一條是**算錯**——後者更危險，因為它會給你一個看起來合理的數字。

## 該問 facility 的問題

1. **「機櫃內的伺服器 PSU 冗餘政策是什麼？hot spare 開著嗎？primary PSU 是哪一顆？」** 這一問決定你的 A/B 平衡報表是不是在報一個不存在的問題。答案在伺服器團隊手上不在 facility 手上——**這一問可能要兩邊一起問**。
2. **「現場有多少單電源設備？各接在哪裡？有 rack ATS 嗎？型號與標稱轉換時間多少？」** [dc-10](static-transfer-switch.md) 那張卡問的是設施級 STS，這一問是機櫃級。EPC 指出「Tier III 設計為了省錢砍掉 STS，後來才發現三分之一的機櫃是單電源」——這個盤點越早做越好。
3. **「A/B 兩側往上追，最近的共同祖先在哪一層？」** 若答案是「同一台 UPS」，那機櫃裡所有雙電源設備的第二條線都只是裝飾。

## 動手練習（40 分鐘）

把「情境」加進 [dc-15](power-meter.md) 那份 code。**不要開新檔案**——這是同一個模型長出來的第五層。

```python
from dataclasses import dataclass
from datetime import datetime
from typing import Literal

Scenario = Literal["normal", "lose_a", "lose_b"]
RedundancyClass = Literal["dual_corded", "single_corded_on_ats", "single_corded"]

@dataclass(frozen=True)
class PsuPolicy:
    mode: Literal["not_redundant", "grid_redundant", "psu_redundant"]
    hot_spare: bool
    primary_psu: int | None      # hot_spare=False 時必須為 None
    source: Literal["redfish", "manual"]
    fetched_at: datetime         # manual 時是人輸入的時間

@dataclass(frozen=True)
class PowerCord:
    device_id: str
    psu_index: int               # 1, 2, ...
    outlet_id: str               # 接到 dc-14 的哪個 outlet
    side: Literal["A", "B"]      # 由 outlet 往上追出來的，不是人填的

@dataclass
class ItDevice:
    id: str
    total_draw_w: float          # 實測；沒有實測時退回 nameplate 並標降級
    redundancy_class: RedundancyClass
    cords: list[PowerCord]
    psu_policy: PsuPolicy | None      # single_corded 時為 None

    def draw_on(self, side: Literal["A", "B"], sc: Scenario) -> float:
        """回傳該情境下這台機器從該側吃走多少 W。
        平分 → total/2；hot_spare → 幾乎全在 primary 那側；
        失效側 → 0，另一側 → total。"""
        ...

    def validate(self, reg: "DeviceRegistry") -> list[Finding]: ...
```

要實作的四個行為：

1. **`draw_on()` 的三條分支**：平分／hot spare／failover。這是 [dc-14](rack-pdu.md) `wiring` 之後**第二個「模式欄位改變演算法」**。
2. **`CapacityReport` 加 `scenario` 維度**，`binding()` 取跨三情境的最壞值。
3. **`check_path_independence()`**：用 [dc-10b](sts-two-source-relationship.md) 的 `DeviceRegistry` 對每條 cord 往上追，求兩條路徑的最近共同祖先。祖先若不是站點根節點 → 吐 `Finding`，`severity` 依祖先層級（rack PDU＞RPP＞UPS＞site）。
4. **`psu_policy` 過期偵測**：`fetched_at` 超過 TTL → `valid=False` 並吐 `PSU_POLICY_STALE`，沿用 [dc-15](power-meter.md) 的降級路徑。

**驗收表：**

| 案例 | 期望 |
|---|---|
| 8 kW 雙電源、平分、單側 8 646 VA | `normal` 每側 46.7%；`lose_b` 的 A 側 93.5%；`binding().scenario == "lose_b"` |
| 10 kW 同上 | `normal` 50.5% 綠燈，但 `binding()` 回 116.8% 並吐 `OVERLOAD_ON_FAILOVER` |
| hot_spare=True, primary_psu=1（A 側） | `draw_on("A","normal") == total`；`draw_on("B","normal") ≈ 0`；**`lose_b` 與 `normal` 數字相同** |
| `hot_spare=False` 但 `primary_psu=2` | 建構時拋 `ValueError`（不一致的設定在型別層擋掉） |
| 兩條 cord 追到同一台 rack PDU | `Finding(policy_id="NO_PATH_INDEPENDENCE", severity="CRITICAL")` |
| 兩條 cord 追到同一台 UPS、不同 RPP | 同 policy 但 `severity="WARNING"` |
| `single_corded_on_ats`，ATS 掛掉 | 該設備在**兩個**情境下都是 0（ATS 是新的共同祖先） |

**加分題**：對整個機房跑一次 `check_path_independence()`，統計有多少台設備的獨立性只到 rack PDU 層。這個數字就是你進 commissioning 前最該修的清單。

## 自我檢核

**Q1. 一個機櫃日常兩側各 50.5%，儀表板全綠。為什麼這是紅燈？**

??? note "答案"
    因為 50% 是**推論**不是規定。真正的約束是「單側扛得住全機櫃」，50.5% × 2 = 101% 已經超過單側容量。任一側掉電時剩下那側要吃 116.8%（含 PF 換算），斷路器跳，整櫃死——**冗餘設計反而造成全損**。日常讀數永遠看不到這件事，只有在 failover 情境下重算才看得到。

**Q2. 你的資料模型要長出哪些欄位，才能表達「這台伺服器的 A/B 分配比例不是 50/50」？這些欄位的真相來源在哪裡？**

??? note "答案"
    需要 `PsuPolicy{mode, hot_spare, primary_psu}` 掛在 `ItDevice` 上，並讓 `draw_on(side, scenario)` 依它分岔。關鍵是**真相來源在 Redfish／iDRAC，不在設施側**——所以還要 `source` 與 `fetched_at`，且伺服器管理員改設定時設施側不會收到通知。因此它必須（a）定期輪詢、（b）過期時降級為 `valid=False`、（c）**變動時觸發容量重算**。這是設施模型第一次必須向 IT 管理平面借欄位。

**Q3. rack ATS 標稱 8 ms，ITIC 允許 20 ms，看起來餘裕 12 ms 很充裕。哪裡不對？**

??? note "答案"
    20 ms 的 hold-up 是**滿載條件下的規格值**。負載約 90% 時實際可能只有 12 ms（EPC），餘裕縮到 4 ms——而 failover 發生的時刻正好是負載最高的時刻。另外要注意名字陷阱：設施級接觸器 ATS 是 100–500 ms，放在 UPS 下游餵伺服器等於定期重開機，所以 `transfer_time_ms` 必須是實測或型錄值。
