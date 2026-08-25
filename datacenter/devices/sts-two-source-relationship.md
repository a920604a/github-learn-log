---
id: dc-10b
title: STS 的兩源關係（一）拓撲獨立性與雙母線容量會計
category: power
written_at: 2026-08-24
sources:
  - https://www.vertiv.cn/4970b4/globalassets/products/critical-power/power-transfer-switches/liebert-sts2-100a-1000a-guide-specifications.pdf
  - https://www.socomec.co.uk/en-gb/news/rethinking-data-centre-design-catcher-architecture
  - https://northernlink.com/distributed-redundancy-3n-2-model-in-data-center-design/
  - https://uptimeinstitute.com/tiers
  - https://www.socomec.us/en-us/solutions/business/data-centers/data-center-redundancy-definition-reliability-best-practices
related: [dc-01, dc-07b, dc-08, dc-09c, dc-10, dc-10c, dc-11]
---

# 兩源關係（一）：拓撲獨立性與雙母線容量會計

[dc-10](static-transfer-switch.md) 講一台 STS 內部：SCR、轉換速度、故障狀態機。這張卡的兩件事**都不住在任何一台設備裡**——兩條上游路徑是不是真的獨立、兩條母線各自要留多少容量。前者是**圖的性質**，後者是**配置集合上的極值**，都不是欄位，都得算。

> **範圍**：第三件事（**相位同步窗與頻率漂移**）拆到 `dc-10c`——它住在時間軸上，跟本卡的圖／集合運算是兩種數學。**順帶澄清**（W34 檢視 #4）：dc-10 Q3 那句「告警反過來成為狀態計算的來源」照字面實作會做出循環依賴；**正確方向是 latched 故障狀態住在 `scr` / `breaker_open` 上，`Alarm` 與 `redundancy_effective()` 都是它的下游。**

## 六格（有一格答不出來，那正是重點）

### 拓撲位置

**主體不是節點，是一段圖**：從 STS 兩個輸入往上回溯，直到兩條路徑相交。交點叫**最低共同祖先（lowest common ancestor, LCA）**，它決定「兩個源」在多深的層級才真的分家——可能是同一面 LV 盤，或遠到同一座變電所（[dc-01](utility-feed.md)）。

### 容量單位

不是一個數字，是一個**映射**：`配置 → (母線 A 負載, 母線 B 負載)`，容量取所有配置的最大值。**單獨看「這條母線現在多少 kW」推不出夠不夠。**

### 冗餘表達

per-bus 上限**不是常數 50%**，是拓撲的函數：2N 全雙電源 → 50%；3N/2 catcher → 66.7%；混入單電源設備 → 靠枚舉算。

### 遙測介面

**答不出來——拓撲獨立性沒有任何點位。** 它是設計事實，只能由圖比對產出**稽核報表**。dc-10 Q1 的第四項（兩條輸入在上游合流）就是這個，也是四項裡唯一無法靠設備發現的。

### 故障域

**LCA 就是故障域的邊界。** LCA 以下的單一故障，兩條路徑至少一條活著；LCA 以上（含它本身）的故障，兩條同時死——**下游再做幾條並聯路徑都消不掉它**。

### 維護特性

**LCA 的維護窗口 = 兩個源同時失效的窗口。** W34 Q4 說衝突檢查看的是「冗餘疊加後是否歸零」而非時間重疊；今天多一種——**單一窗口落在 LCA 上就足以致命**。

## 關鍵數字與計算

### 演算 1：雙母線容量會計——枚舉配置取 max

**場景**（刻意混入單電源設備，那正是 STS 存在的理由）：20 台雙電源機櫃 × 6 kW = **120 kW**；4 台單電源設備 × 5 kW = **20 kW** 掛在 STS 下游，`preferred_source = A`。總負載 **140 kW**，A / B 兩條母線 2N。

| 配置 | 母線 A | 母線 B | 說明 |
|---|---|---|---|
| **正常** | 60 + 20 = **80 kW** | **60 kW** | 雙電源對半，STS 吃 preferred |
| **B 失效** | 120 + 20 = **140 kW** | 0 | STS 仍在 A，不需轉換 |
| **A 失效** | 0 | 120 + 20 = **140 kW** | STS 轉到 B |

$$P_{\text{bus,min}} = \max(80,\ 60,\ 140,\ 140) = \mathbf{140\ kW}$$

裝機 2 × 140 = **280 kW**，正常運轉率 `(80+60)/280 = 50%`。**兩條母線的正常負載不相等（80 vs 60），但容量下限相等。** 不對稱來自 `preferred_source`——一個平常被當成「偏好」的設定，其實是容量會計的輸入。

**再加一層現實**：dual-PSU 設備在單邊失效時，剩下那顆 PSU 從約 50% 負載跳到約 100%，效率曲線不同，實測**每櫃 +2~10%**。這只影響雙電源那 120 kW：

```
雙電源：120 × 1.10 = 132.0 kW
單電源：            20.0    ← 沒有第二顆 PSU，不受影響
required_bus_kw    = 152.0 kW   ← 而不是 140
```

**用 140 選盤會在最需要的那一刻超載 8.6%**，而這 12 kW 正常運轉時任何儀表板都看不到。

### 演算 2：per-bus 上限是拓撲的函數，不是 2N 的定義

| 架構 | 每單元 | 裝機 | 正常運轉率 |
|---|---|---|---|
| **2N**（任一台吃全部） | 140 × 2 | **280 kW** | 50% |
| **3N/2 catcher**（任兩台吃全部） | 70 × 3 | **210 kW** | 66.7%（catcher 平時 0%） |

一般式：**M 台承載 K 台份 → 每台上限 = K/M**，裝機 = 負載 × M/K。Socomec 另宣稱 catcher 對比 2N 的 CAPEX −42%、佔地 −38%（廠商數字，僅當量級參考）。

> `max_load_pct = 50` 是「**2N ＋ 全部雙電源**」這個特定拓撲的產物，不是 2N 的定義。它必須是 `worst_case_bus_load(configs)` 的衍生值。

### 演算 3：加一台 STS 划不划算，答案是 LCA 的函數

用 Socomec 給的失效率（λ，FIT = 每十億小時失效次數）：λ_STS ≈ **150**、λ_UPS ≈ **2860**。**共同祖先是串聯元件**，失效率直接相加：

```
A：兩路真獨立（LCA 在市電進線，該段已由發電機覆蓋）
   λ ≈ 150 + ~0  = 150 FIT → MTBF ≈ 6.67e6 h
B：LCA 是同一面 LV 盤（保守假設 λ_panel = 500 FIT）
   λ ≈ 150 + 500 = 650 FIT → MTBF ≈ 1.54e6 h  ← 掉到 23%
```

**STS 一點沒變、帳面上仍然「有兩個源」，可靠度卻少了四分之三。** 共祖失效率一高，STS 的改善就從一個數量級塌到接近 1——而你付了設備錢、多了一個單點（dc-10 誤解 1）。

這也解釋了 Uptime **Tier IV** 為什麼不只要求 2N，而是**多重、獨立、實體隔離**的系統與多條獨立的主動配送路徑，外加**實體區劃**防止故障擴散到冗餘那側。**「實體隔離」就是在規範層要求 LCA 夠高。**

## 常見誤解

**以為 2N 就是每條母線 50%，但實際上 50% 是「2N ＋ 全部雙電源」這個特定拓撲的產物。** 混進單電源設備最壞配置就不再對稱；換 catcher 上限變 66.7%；再算進 dual-PSU 單邊多吃的 2–10%，實際下限是 **152 kW 而不是 140**。**per-bus 上限是枚舉出來的，不是查表查來的。**

**以為在單線圖上分兩條線畫就是獨立，但實際上共同祖先永遠存在，問題只在於它在哪一層。** 最遠可以遠到同一座變電所（dc-01）、同一條供油管（dc-06）、同一個防火區劃（[dc-09c](lib-fire-compliance.md)）。這是「用數量冒充獨立性」在本軌跡的**第五次**現身。

**以為 LCA 只存在於電力樹，但實際上空間樹上也有 LCA，而且它在單線圖上完全看不見。** A、B 兩路電池若在同一防火區劃，那就是空間樹上 depth = 0 的共祖——**電力樹上的 2N 在消防樹上是 1N**。所以 `lowest_common_ancestor()` 要在兩組邊上各跑一次（見 Q3）。

## 來源分歧

**STS 的 MTBF 現在有四個版本，跨十一年、四家廠商，差 16 倍**：WP 62（2010）40–100 萬 h、Vertiv STS2（2021）> 100 萬 h（兩者邊界皆未明說）；PDI/Eaton（2017）> 200 萬 h（明寫「關鍵交流輸出匯流排」）；Socomec λ=150 FIT ≈ 667 萬 h（元件層 λ，不含輸出斷路器與人為操作）。

**只有兩個說了自己在算什麼，而那兩個剛好差最多**——分歧來自邊界而非品質。演算 3 用了最樂觀的那個，**所以它算出的是比值而非絕對值**。可驗證的問法是「**你報的邊界畫在哪**」。

## 對資料模型的意涵

1. **`PowerEdge` 要有身分，且需要圖查詢（第五次要求，今天兌現）。** `ancestors()` 與 `lowest_common_ancestor()` 是 `DeviceRegistry` 的 method，不是 `Sts` 的。**獨立性是查詢結果不是欄位**——`is_redundant: bool` 會在有人改接線那天開始說謊。

2. **`max_load_pct` 不能是欄位，`Configuration` 必須是一等公民。** 形狀是「枚舉失效配置 → 各算母線負載 → 取 max → 比對額定」，跟 [dc-07b](lv-short-circuit-and-coordination.md) 的「`Isc(config) > Icw` 是可算型違規」同形——**都該在設計審查／互鎖層擋掉，不是掛一條會被 ack 掉的告警**（W33 已定案）。`preferred_source` 是這個枚舉的**輸入**。

3. **LCA 是同一個演算法在兩棵樹上跑——兩棵樹第一次真的統一。** 遍歷必須**參數化「走哪一種邊」**，不能把 `upstream_id` 寫死。W34 #5 要的 `FireCompartment.safety_system_feeds` 先留位置——`dc-22` CRAH 會第二次撞上同一形狀。

4. **`MaintenanceWindow` 要有 `subject_id`，衝突檢查要能對它跑 `ancestors()`**——單一窗口落在 LCA 上冗餘就歸零（W34 Q4 的補充條款）。

## 該問 facility 的問題

1. **「S1 與 S2 往上追到第幾層才分家？路徑逐節點列給我。LCA 那個節點有沒有維護窗口？」** 不要問「獨立嗎」。第二問是關鍵：**LCA 進維護＝兩源同時失效，行事曆上卻只是一筆單一作業。**

2. **「容量計算書枚舉了哪幾個失效配置？dual-PSU 單邊的功耗增量算了嗎？單電源設備的 kW 掛在哪一條上算？」** 第三問其實是在問 `preferred_source` 有沒有進計算——**若計算書把單電源負載對半分，那份是錯的。**

## 動手練習（30–40 分鐘）

**這就是欠了四週的 `DeviceRegistry`**（W33 檢視 #3）。把「獨立性是圖查詢」「容量是配置集合上的極值」寫成 code，並讓兩棵樹**共用同一份遍歷**。

```python
from dataclasses import dataclass, field

@dataclass(frozen=True)
class PowerEdge:                       # ★ 邊終於有身分（第五次要求）
    id: str; src_id: str; dst_id: str  # src=上游, dst=下游
    role: str = "primary"              # primary | alternate | bypass
    energized: bool = True

@dataclass
class Device:
    id: str; kind: str                 # utility|xfmr|lv_panel|ups|sts|rack
    compartment_id: str | None = None  # ← 進入空間樹的入口（dc-09c）

@dataclass
class FireCompartment:
    id: str; parent_id: str | None = None
    safety_system_feeds: list[str] = field(default_factory=list)  # ← W34 #5 留位置

@dataclass
class DeviceRegistry:
    devices: dict[str, Device]               = field(default_factory=dict)
    edges:   list[PowerEdge]                 = field(default_factory=list)
    compartments: dict[str, FireCompartment] = field(default_factory=dict)

    # TODO _parents(node_id, tree)   ★ 換一組 parent 就換一棵樹
    #   power: e.src_id where e.dst_id==node_id and e.role!="bypass"
    #   space: device.compartment_id -> compartment.parent_id 往上
    # TODO ancestors(node_id, tree="power")            由近到遠、去重
    # TODO lowest_common_ancestor(a, b, tree="power") -> (id|None, depth)
    # TODO independence_report(sts_id) -> dict
    #   {"lca","depth_s1","depth_s2","same_compartment","verdict"}
    #   depth<=1 -> NO_INDEPENDENCE ／ LCA.kind in (ups,lv_panel) -> SHALLOW_LCA
    #   ★ verdict 不是二元的：LCA 永遠存在，問題是它在第幾層

@dataclass
class DualCordedLoad:   id: str; kw: float; single_side_uplift: float = 0.10
@dataclass
class SingleCordedLoad: id: str; kw: float; sts_id: str

# TODO bus_load(config, dual, single, preferred) -> dict[str, float]
#   normal: dual 對半、single 全掛 preferred
#   A_down/B_down: 全到另一條，dual ×(1+uplift)，single 隨 STS 走
# TODO required_bus_kw(...)             所有 config × bus 取 max
# TODO required_unit_kw(load_kw, m, k)  M 台承載 K 台份的通用式
```

### 驗收表

用一張「看起來 2N、其實共祖很淺」的圖——`utility → xfmr1 → lv_panel_A →` 分岔出 `ups_A` 與 `ups_B`，兩者再一起餵 `sts1`（下掛 4 台單電源 × 5 kW），20 台雙電源機櫃 × 6 kW 直接吃 `ups_A` / `ups_B`：

| 情境 | 期望 |
|---|---|
| `lowest_common_ancestor("ups_A","ups_B")` | `("lv_panel_A", 1)` → verdict **`NO_INDEPENDENCE`** |
| `ups_B` 改接 `lv_panel_B`（上游 `xfmr2`）後重跑 | LCA → `utility`，**`OK`** |
| 同上但 `lv_panel_B` 仍吃 `xfmr1` | LCA → `xfmr1`，**`SHALLOW_LCA`** ← 三級判定的意義 |
| 加一條 `role="bypass"` 邊從 `lv_panel_A` 到 `sts1` | LCA **不變**（bypass 不算進獨立性） |
| 兩組電池 `compartment_id` 相同 | `same_compartment` = **True**（同一份 LCA 跑空間樹） |
| `bus_load("normal", preferred="A")` | **`{"A":80.0,"B":60.0}`** ← 不相等 |
| `required_bus_kw(uplift=0.0)` ／ `(0.10)` | **140.0** ／ **152.0**（跑出 154 是 uplift 誤套到單電源） |
| `required_unit_kw(140, m=3, k=2)` ／ `(140, m=2, k=1)` | **70.0** ／ **140.0** |

**加分題（10 分鐘）**：catcher 是第三條路徑，把簽章改成吃 `(*nodes)`，並回答**三條路徑的 LCA 深度該取 min 還是 max**。

## 自我檢核

**Q1. 一區 140 kW IT 負載，2N。有人說「每條母線做 140 kW 就好，反正 2N 嘛」。哪裡不夠？**

??? note "答案"
    **不夠，正確答案是 152 kW**（`120 × 1.10 + 20`）。140 把「單邊失效 → 全部壓到另一邊」算對了，但漏掉 dual-PSU 設備單邊時的功耗增量（機制見演算 1；單電源設備沒有第二顆 PSU，不受影響）。**缺的那 12 kW 只在單邊失效時出現，正常運轉時任何儀表板都看不到。**

    **兩個順帶的結論**：正常運轉時兩條母線**不相等**（A=80、B=60）**但容量下限相同**——所以看儀表板推不出容量夠不夠，**必須枚舉配置**；而 50% 不是 2N 的定義，換 catcher 上限變 66.7%，裝機從 280 降到 210 kW。

**Q2. 有人拿單線圖給你看，A、B 兩路從頭到尾畫成兩條分開的線，說「這是 2N，完全獨立」。你問哪一個問題就能判斷真假？**

??? note "答案"
    **問「這兩條線往上追，在哪一個節點交會？」** **LCA 永遠存在**，所以這不是是非題，是**深度題**：

    - 「同一面 LV 盤／同一台 UPS」→ `NO_INDEPENDENCE`：這不是 2N，只是兩條線
    - 「同一台變壓器／同一條進線」→ `SHALLOW_LCA`：是 2N，但故障域邊界比宣稱的低
    - 「同一座變電所以上」→ `OK`：對 STS 這個層級夠了
    - 「不會交會」→ **對方沒懂問題**：兩條線供電給同一組負載，圖上必然有共祖

    **再追問兩件單線圖上看不見的事**：LCA 有沒有維護窗口；兩路設備在不在同一防火區劃（空間樹上的 depth-0 共祖，只在平面圖看得見，dc-09c）。

**Q3.（建模）「這台 STS 的兩個源獨立嗎」與「這兩組電池在不在同一防火區劃」，在你的模型裡是兩個功能還是一個？這會讓 `DeviceRegistry` 長出什麼簽章、什麼約束？**

??? note "答案"
    **是同一個演算法跑在兩組邊上——電力樹與空間樹第一次真的統一。** 差別只在「往上走」的定義：**電力樹**是 `[e.src_id for e in edges if e.dst_id == node]`，LCA 的意義是**故障域邊界**；**空間樹**是 `device.compartment_id → compartment.parent_id`，LCA 的意義是**消防聚合範圍**（dc-09c）。

    **簽章**：`lowest_common_ancestor(a, b, tree="power")`，遍歷邏輯參數化，**不能把 `upstream_id` 寫死**；加分題再推一步要能吃 `(*nodes)`，深度取 **min**。

    **會長出的欄位與約束：**

    - `PowerEdge(id, src_id, dst_id, role, energized)`。`role` 要區分 primary / alternate / **bypass**——bypass 邊平時不導通卻會建立共祖路徑，算進去會把 verdict 誤判成 `NO_INDEPENDENCE`。
    - **禁止 `is_redundant: bool` / `independent_feeds: bool`。** 它們是查詢結果，存下來就會在有人改接線那天靜默說謊，而**沒有任何遙測會變**。正確做法是排程跑 `independence_report()`。
    - `FireCompartment.safety_system_feeds: list[str]`（兩棵樹之間的**橫向邊**，W34 #5）與 `MaintenanceWindow.subject_id`（衝突檢查要能對它跑 `ancestors()`）。

    **最容易漏的一條**：verdict **不該只有 OK / FAIL 兩種**。LCA 永遠存在，問題是「共祖在第幾層」，所以至少三級，而且**深度本身就是要存進報表的數字**，不是判斷完就丟。
