---
id: dc-34
title: 門禁控制器、讀卡機與人員通道閘（含 mantrap）
category: fire-security
written_at: 2026-10-07
sources:
  - https://getsafeandsound.com/blog/26-bit-wiegand-format/
  - https://wcm-cce.cldnet.analog.com/media/en/technical-documentation/tech-articles/hid-understanding_card_data_formats-wp-en.pdf
  - https://securitysales.com/access/what-security-integrators-need-know-about-osdp
  - https://www.securityinfowatch.com/access-identity/access-control/article/12103732/osdp-an-access-control-standard-with-staying-power
  - https://www.securityinfowatch.com/home/article/10517200/query-the-access-control-expert
  - https://help.kerisys.com/portal/en/kb/articles/setup-anti-passback-using-nxt-msc-controllers
  - https://orf.od.nih.gov/technicalresources/documents/technical%20bulletins/20tb/fail%20safe%20vs.%20fail%20secure%20electronic%20locksets%20june%202020%20-%20technical%20bulletin%20updated_508.pdf
  - https://nationallocksupply.com/blog/data-center-door-hardware-spec-guide/
  - https://blog.boonedam.com/en-us/secured-entrances-for-data-centers
related: [dc-33, dc-16, dc-08, dc-28]
---

# 門禁控制器、讀卡機與人員通道閘（Access Control: Door Controller, Reader, Mantrap）

門禁不是「刷卡開門」一個動作，而是一條鏈：**憑證 → 讀卡機 → 控制器（決定准不准）→ 鎖（執行）→ 門位開關（回報門真的開了／關了）**。控制器是決策者、鎖是執行者、門位開關是證人。這張卡把門當成**有狀態、有電源依賴、有逃生義務**的設備來建模，它是 `dc-33` 釋放盤 `Zone.interlocks`（聯動輸出）的下游：氣體釋放時，門要怎麼辦？

## 六格

### 拓撲位置
上游：電源（鎖與控制器的 DC 電源，最終掛在 [UPS](ups-double-conversion.md) 某條分支）、網路（控制器到伺服器）、`dc-33` 的聯動輸出、消防警報的釋放訊號。下游：每扇門（鎖、門位開關 DPS、出門按鈕 REX）。門屬於 [Space](space-hierarchy.md) 的**邊界**——它連接兩個 Space，不屬於其中一個。

### 容量單位
沒有 kW。容量是**門數／讀卡機數／卡片記錄數／通行吞吐（人／分）**。吞吐是真正會卡住營運的：交班時一次進來幾十人（見計算）。

### 冗餘表達
控制器通常把名單**下載到本地**，網路斷了仍能依本地名單判斷（行為因廠牌而異，未逐廠驗證）。鎖與讀卡機一般無冗餘；**冗餘是分層**（外門＋ mantrap ＋機櫃鎖），不是同一點雙套。

### 遙測介面
| 點位 | 內容 | 備註 |
|---|---|---|
| 讀卡事件 | 憑證資料（格式＋號碼）＋讀卡機位置 | Wiegand 單向、無加密；OSDP 雙向 |
| DPS（門位開關） | 門開／關 | **沒有它就沒有強闖／逾時未關事件** |
| REX | 內側要出門 | 觸發開鎖並**抑制**強闖警報 |
| 鎖狀態、tamper、電源 | 因控制器而異 | 本次未逐型號查證 |

### 故障域
一台控制器掛了＝它管的所有門失去決策能力（本地名單是否繼續運作因廠牌而異）。鎖掉電：**fail-safe 鎖開、fail-secure 鎖關**——兩個方向各有代價：前者是保全破口，後者是逃生阻礙。

### 維護特性
高頻設備：資料中心門每日 50–200 次循環（供應商文案）；電磁鎖 250–500 mA 連續耗電、約 10 年壽命，電動鎖舌 200–300 mA（僅在上鎖保持）、日 200+ 次循環下約 5 年換一輪（同一來源，次級來源）。

## 來源分歧

- **26 位元 Wiegand 的尾端同位位元**：getsafeandsound 寫第 1 與第 26 位元**皆為偶同位**；HID 白皮書寫前導為偶同位（覆蓋前 12 資料位）、**尾端為奇同位**（覆蓋後 13 位含自身）。以 HID（格式發明者）為準，並用練習驗證——但這是「兩個來源互相矛盾」的標準例子。
- **逃生門鎖型**：nationallocksupply 說逃生路徑必須 fail-safe **或**有自由機械逃生（panic bar）；NIH 技術公報說防火門依 NFPA 80 要用 fail-secure 電動鎖舌。兩句話表面衝突，實際是**兩種達成方式**：fail-secure 靠機械把手逃生，fail-safe 靠斷電釋放。NFPA 101／80 原文本次均未取得。
- **OSDP 距離**：securitysales 說 RS-485 線長「常達 4,000 ft（約 1,200 m）」；Wiegand 對應距離本次**未取得來源**，不引用。OSDP 版本：2015 年文章稱 2.0 引入 AES secure channel；目前版本與 IEC 標準編號本次未查證。
- **Boon Edam「消除 DFO／DHO 警報」**是供應商宣稱，不是量測；mantrap 只是把強闖和逾時**從門換成整個艙**，不是消除事件。

## 關鍵數字與計算

**一、Wiegand 26 位元的容量與同位**：1 + 8（設施碼）+ 16（卡號）+ 1 = 26 位元。理論 `256 × 65536 = 16,777,216`，但設施碼與卡號 **0 都不用**（HID：範圍 1–255、1–65535），所以可用 `255 × 65535 =` **16,711,425**（兩個來源一致）。

**實例編碼**：設施碼 123 = `01111011`，卡號 4567 = `0001000111010111`（0x11D7）。前 12 位資料 `011110110001` 有 7 個 1（奇數）→ 偶同位位元 = **1**；後 12 位 `000111010111` 有 7 個 1（奇數）→ 奇同位位元 = **0**。整串：`1 01111011 0001000111010111 0` = `10111101100010001110101110`。翻轉最後 1 位元就解不過尾端同位。

**同位只擋隨機錯誤，不擋偽造**：Wiegand 無加密、無認證；HID 明說 H10301「不記載、不限制重複」——兩家廠商可發相同的 (123, 4567)。**憑證身分是 (format, facility, number) 三元組，不是卡號。**

**二、門時序（以 DPS 為證）**：開鎖窗 `unlock_s = 5`，逾時未關 `propped_s = 30`（皆為假設的設定值，各廠牌欄位與起算點不同）。
- t=0 刷卡通過、t=3 開門、t=9 關門 → 無事件。
- t=0 通過、t=3 開門、一直不關：t=33 時開門持續 30 s（不 >30）無事件；**t=34 觸發 DOOR_HELD_OPEN**。
- 沒刷卡也沒按 REX，t=10 門被打開 → **DOOR_FORCED**。
- t=0 通過，但 t≥5 門始終沒開 → **GRANTED_NO_ENTRY**（Keri 的做法：視為沒進入，卡可重用）。
- **沒有 DPS**：以上全部不可能發生，**什麼事件都不會有**（見意涵 2）。

**三、吞吐與壽命**：mantrap 約 5 人／分（Boon Edam），即每人 **12 s**。交班 60 人：`60/5 =` **12 分鐘**；光學閘機 30+ 人／分 → **2 分鐘**。交班排隊 12 分鐘是營運問題，不是保全問題——但它會讓人想把門**頂開**。壽命：日 200 次 × 365 × 5 年 = **365,000 次循環**。

**四、fail-safe 的電源預算**：40 扇電磁鎖（fail-safe）每扇 500 mA → **20 A**（電壓來源未說，假設同一直流匯流排）。這 20 A 要靠後備電池撐多久，就是「斷電後門還能鎖多久」。若不在 UPS 上：市電中斷的那一刻，**40 扇門同時打開**。

## 常見誤解

**以為「斷電鎖死最安全」，但實際上逃生路徑必須能走出去**。要嘛 fail-safe（斷電釋放），要嘛 fail-secure 但有**自由機械逃生**。把逃生門裝成 fail-secure 又沒有把手，是違規與生命風險，不是保全加強。

**以為「門有讀卡機就有紀錄」，但實際上沒裝 DPS 就沒有強闖／逾時未關**。控制器只知道「有沒有刷卡」，不知道門實際開了沒。用跟隨（tailgating）進去的人，在沒有 DPS 的門上完全不存在。

**以為「卡號就是身分」，但實際上 26 位元格式不保證唯一**。H10301 不防重複；兩個設施的卡可能同號。身分鍵必須含格式與設施碼，且 Wiegand 讀卡機到控制器的線上資料可被讀取重放（無加密）。

## 對資料模型的意涵

1. **`Door` 是兩個 Space 之間的邊，不是 Space 的屬性**：`Door{id, from_space, to_space, lock_mode: fail_safe|fail_secure, is_egress_path, mech_egress: bool, dps: bool, rex: bool, tamper: bool}`。「這間房有幾扇門」是查詢，不是欄位。`lock_mode` 與 `is_egress_path`、`mech_egress` 三者有約束：**egress ∧ fail_secure ∧ ¬mech_egress** 違規（`EGRESS_BLOCKED_ON_POWER_LOSS`）。
2. **第四個「缺東西」告警：`DOOR_UNMONITORED`**（無 DPS）。與 `DETECTION_COVERAGE_GAP`（dc-32）、`RELEASE_PATH_DEGRADED`（dc-33）同類：沒有事件，所以沒有告警說它沒事件。要從資料推導「這扇門無法產生強闖／逾時事件」。
3. **鎖是電力鏈的消費者**：`Door.lock_power → PowerEdge`。fail-safe 的 `lock_ma` 會加總成 UPS 分支的負載（見計算四）；**`FAILSAFE_OPENS_ON_MAINS_LOSS`**：fail-safe 鎖不在後備電源上＝市電斷時整區開門。這是第一次出現「**斷電的失敗模式是資料，不是常識**」的設備。
4. **憑證身分鍵 `Credential{format, facility_code, number}`**，另有 `Reader.protocol: wiegand|osdp`、`osdp_secure_channel: bool`。`Reader.protocol = wiegand` 在週邊／機房門上要出 `CREDENTIAL_LINK_UNENCRYPTED`（資訊級，不是違規）。
5. **聯動輸出是 `dc-33` 的 `Zone.interlocks` 的下游邊**：`Interlock{zone_id, door_id, action: unlock|lock|none}`。釋放時哪些門解鎖、哪些鎖住（避免人進入已充氣區）**是資料，各規範的要求本次未查證**；只確定 fail-safe 門會因斷電而開，與聯動命令無關。
6. **APB 是 Area 狀態機**：`Area{id}`、`Reader{area_in, area_out}`、`Person.area`；violation 模式 `hard|soft`。見練習。

## 該問 facility 的問題

1. 資料中心所有**逃生路徑上的門**各是 fail-safe 還是 fail-secure？後者的機械逃生把手在哪？
2. 每扇門都有 DPS 嗎？機櫃區的門呢？強闖與逾時未關的告警誰收、閾值幾秒？
3. 鎖的電源掛在哪個 UPS 分支？斷市電時門禁控制器與鎖各撐多久？

## 動手練習（30–40 分鐘）

**目標**：把本卡的演算跑起來，接在 dc-33 的 `core.py`（`Check / Result / Sourced / Finding`）之上。**不要重寫** `core.py`，`from core import ...`。

```python
# access.py（約 90 行；骨架）
def wiegand26_encode(fc, cn):      # 0 或溢出 -> None
    # d = 24 位資料；even = parity(d[:12])；odd = 1 - parity(d[12:])
def wiegand26_decode(s) -> (Result, (fc, cn)|None):  # 長度/前導/尾端同位
def format_capacity() -> (255*65535, 256*65536)

class Door: id, has_dps, unlock_s=5, propped_s=30
def classify(door, granted_at, rex_at, opened_at, closed_at, now) -> [Ev]
   # NONE | FORCED | HELD(>propped_s) | GRANTED_NO_ENTRY；無 DPS -> [NONE]

def apb(state, card, area_in, area_out, direction, mode) -> (GRANT|DENY, "APB_VIOLATION"|None)
def mantrap_ok(outer_open, inner_open) -> bool   # 不可同時為 True
def drain_minutes(people, per_min); def cycles_lifetime(per_day, years)

class LockDoor: id, lock, egress, mech_egress, has_dps, lock_ma, on_ups
def door_findings(d) -> [Finding]   # EGRESS_BLOCKED_ON_POWER_LOSS / DOOR_UNMONITORED / FAILSAFE_OPENS_ON_MAINS_LOSS
def lock_load_a(doors) -> float     # 只加總 fail_safe
```

### 驗收表（已用參考實作跑過）

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | `wiegand26_encode(123, 4567)` | `10111101100010001110101110`（26 位） |
| 2 | `wiegand26_decode` 上列字串；最後一位翻轉 | **OK**, (123, 4567)；**VIOLATED**（尾端同位） |
| 3 | `wiegand26_encode(0, 5)`；`(1, 65536)` | 皆 **None** |
| 4 | `format_capacity()` | **(16711425, 16777216)** |
| 5 | `classify(D, granted=0, rex=None, open=3, close=9, now=40)` | **[NONE]** |
| 6 | 同上但永不關，`now=33`／`now=34` | **[NONE]**／**[HELD]** |
| 7 | 沒刷卡、`opened_at=10, closed_at=12, now=20` | **[FORCED]** |
| 8 | `granted=0`、門從未開、`now=10` | **[NO_ENTRY]** |
| 9 | 同第 7 列但 `has_dps=False` | **[NONE]**（blind） |
| 10 | REX 在 t=2、門 t=3 開 t=6 關 | **[NONE]**（REX 抑制強闖） |
| 11 | 同一卡連刷 in：HARD／HARD／SOFT，再刷 out HARD | **GRANT／DENY／GRANT+VIOLATION／GRANT** |
| 12 | `mantrap_ok(True,True)`／`(True,False)` | **False／True** |
| 13 | `drain_minutes(60,5)`／`(60,30)`；`cycles_lifetime(200,5)` | **12.0／2.0**；**365000** |
| 14 | 三扇門（fail_safe 非 UPS 逃生；fail_secure 逃生無機械；fail_secure 非逃生無 DPS） | `FAILSAFE_OPENS_ON_MAINS_LOSS`／`EGRESS_BLOCKED_ON_POWER_LOSS`／`DOOR_UNMONITORED` |
| 15 | 40 扇 fail_safe 各 500 mA 的 `lock_load_a` | **20.0** |

**加分題**：把 `Interlock{zone_id, door_id, action}` 接上 dc-33 的 `Zone`，寫 `release_unlocks(zone, doors)`，驗證 fail-secure 門在 `action=unlock` 時才開、fail-safe 不論命令都會因斷電而開——前提是你先去查規範要求。

## 自我檢核

**Q1. 兩家廠商各發一張 (設施碼 123, 卡號 4567) 的卡，資料模型要怎麼避免把它們當成同一個人？**

??? note "答案"
    HID H10301 不防重複。身分鍵 = (credential format, facility_code, number)，再以 `holder_id` 對到人；不能只存卡號。要更強的話，換支援 secure channel 的 OSDP 讀卡機與 PKI 憑證。

**Q2. 一扇門沒有 DPS，它仍然 Normal。這代表什麼？該有哪個告警？**

??? note "答案"
    它**無法產生強闖與逾時未關**事件，所以門被頂開、被卡住都不會有紀錄。告警 `DOOR_UNMONITORED`（`Door.dps = False`），與 `DETECTION_COVERAGE_GAP`、`RELEASE_PATH_DEGRADED` 同為「缺東西」告警。

**Q3. 新增一扇逃生門，會讓你的資料模型長出什麼欄位與約束？**

??? note "答案"
    `lock_mode`、`is_egress_path`、`mech_egress`、`dps`、`lock_power → PowerEdge`；約束：`is_egress_path ∧ fail_secure ∧ ¬mech_egress` 違規；fail-safe 的 `lock_ma` 要計入所在 UPS 分支負載，且該分支須在後備電源上。

---

**下一張**：`dc-35` CCTV 與影像保存（門的事件常要對應影像；保存天數是資料量與合規的交界）
