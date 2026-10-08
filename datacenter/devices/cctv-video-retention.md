---
id: dc-35
title: CCTV 與影像保存（儲存估算、保存期間、PoE 預算與事件對影像）
category: fire-security
written_at: 2026-10-08
sources:
  - https://www.forasoft.com/learn/video-surveillance/articles-vms/surveillance-storage-retention-math
  - https://videos.cctvcamerapros.com/video-storage-calculator.md
  - https://www.forasoft.com/learn/video-surveillance/articles-vms/retention-policy-how-long-to-keep-footage
  - https://its.uiowa.edu/support/article/100324
  - https://ce.prod.cloudaware.com/frameworks/pci-dss-v3.2.1/09/01/01/
  - https://www.omnitron-systems.com/blog/what-is-a-poe-power-budget-and-how-do-i-calculate-it
  - https://www.trendnet.com/press/resource-library/how-poe-device-class-affects-your-poe-budget
  - https://www.videoexpertsgroup.com/glossary/onvif-profile-g
related: [dc-34, dc-33, dc-32, dc-08, dc-31]
---

# CCTV 與影像保存（CCTV and Video Retention）

CCTV 在機房裡的角色是**事後的證人**：門禁（[dc-34](access-control-door-controller.md)）告訴你「誰刷了卡、門開了多久」，攝影機告訴你「門口當時實際站了幾個人」。它同時是三種資源的消費者：**PoE 電力**（攝影機供電）、**網路頻寬**、最大宗的是**儲存空間 × 保存天數**。這張卡把「保存幾天」從一句政策，變成一條可以算、可以被違反的約束。

## 六格

### 拓撲位置
上游：電源（PoE 交換器，最終掛在 [UPS](ups-double-conversion.md) 的某條分支）、網路（攝影機 → PoE 交換器 → 錄影主機 NVR／儲存陣列）、時間源（NTP）。下游：影像被誰用——保全人員即時監看、稽核人員事後調閱、與 `dc-34` 門事件關聯。攝影機的**視野**覆蓋哪些門與走道，是它和 [Space](space-hierarchy.md) 之間的關係，不是它的位置屬性。

### 容量單位
兩個：**Mbps（每支攝影機的碼率）** 與 **TB（保存量）**。換算常數：1 Mbps 連續錄一天 = **10.8 GB**（十進位）。PoE 側的容量單位是 **W**（交換器預算）。

### 冗餘表達
儲存層冗餘是 RAID（5／6／10，容量損失不同，見計算二）。攝影機層冗餘是**邊緣儲存**（camera 本機 SD 卡，網路斷線時繼續錄、連線後回補，ONVIF Profile G 涵蓋錄影／搜尋／重播）。覆蓋冗餘是**兩支攝影機看同一扇門**。三者各自獨立，不是同一種 N+1。

### 遙測介面
| 點位 | 內容 | 備註 |
|---|---|---|
| 串流與設定 | ONVIF Profile S（H.264／MJPEG 即時串流、基本 PTZ）、Profile T（H.265、移動偵測、metadata） | 即時畫面 |
| 錄影搜尋 | Profile G：連續／排程／事件錄影、依時間日期事件搜尋、`MaximumRetentionTime` | 儲存與重播，**不含即時串流** |
| PoE 狀態 | 每埠功率、等級、是否被拒絕供電 | 依交換器型號，SNMP 或廠商介面（本次未查證 MIB） |
| 系統健康 | 錄影中斷、磁碟故障、NTP 偏移 | 因 NVR 而異，本次未逐型號查證 |

### 故障域
一支攝影機掉了＝一個視野盲區（但門禁仍運作）。一台 PoE 交換器掉了＝它供電的**所有**攝影機同時消失，若沒有 UPS 分支則市電一斷整層黑掉。NVR 或陣列掉了＝**新影像無處可去**；有邊緣儲存的攝影機可撐到 SD 卡寫滿（見計算四），沒有的就是永久缺口。

### 維護特性
硬碟是消耗品（陣列重建期間風險集中）；韌體與 NTP 需定期檢查；鏡頭要清潔與對焦驗證。**驗證影像真的可以調出來**，是比「錄影燈亮著」更重要的例行項目。

## 來源分歧

- **PCI DSS 是否規定影像保存期**：forasoft 說 PCI DSS 對影像**沒有**保存期，「90 天」是從無關的日誌保存要求借來的迷思；cloudaware 轉載的 PCI DSS v3.2.1 §9.1.1 寫的是「Store for at least three months, unless otherwise restricted by law」（至少三個月，除非法律限制）。兩者可能是**版本差異**（v4.0 的措辭本次未取得），也可能一方在轉述上有誤，**不裁決**，PCI DSS 原文本次未取得。
- **同一節裡的算術不一致**：forasoft 說陣列容量不要超過 80%，但它自己的範例用 `÷0.75` 再 `×1.1`（約 39 TB），而照 80% 上限算是 `÷0.75÷0.8` ≈ 43 TB。差 10% 以上。
- **PoE 等級 7 的 PSE 輸出**：Omnitron 表列 70 W，TRENDnet 表列 75 W。IEEE 802.3bt 原文本次未取得，不裁決。
- **保存期間沒有通用數字**：愛荷華大學（University of Iowa）政策寫「最少 14 天、最多 90 天，或依法規」；EDPB 指引講「幾天」就夠；內華達博弈規則常規 7 天、可疑事件至少 60 天。**每個轄區、每個用途不同，卡片不給預設值**。
- **台灣法規本次未取得**：搜尋只得到零散新聞與地方政府文件，沒有可引用的條文，不推論。資料中心的保存天數請改問合規窗口與契約。

## 關鍵數字與計算

**一、單機儲存量**：`GB/天 = 碼率(Mbps) × 10.8 × 錄影係數`。10.8 的來源：1 Mbps = 125,000 B/s，× 86,400 s = 10.8×10⁹ B。範例：4 MP、H.265、2 Mbps 連續錄影 → `2 × 10.8 =` **21.6 GB／天**。cctvcamerapros 的計算器改用查表（4MP 7501 kbps、H.265 = 0.5、幀率除數）得同量級結果，但示範算術有微小偏差（79,081 vs 79,112）、1000／1024 換算只處理一次。**實務上：單位慣例造成的誤差（約 2–5%）遠小於場景造成的誤差**——碼率是 VBR，擁擠場景落在區間上緣，forasoft 給 4 MP H.265 為 2.2–4.2 Mbps，差近一倍。

**二、整個系統與陣列**：40 支 4 MP H.265、2 Mbps、連續、30 天：`21.6 × 40 × 30 =` **25,920 GB ≈ 25.92 TB（原始）**。陣列容量上限取 80%：需要可用空間 `25.92 ÷ 0.8 =` **32.4 TB**。用 8 TB 硬碟，各 RAID 層級最少幾顆？
- RAID 5（n−1 顆可用）：5 顆只有 32 TB < 32.4，**6 顆** → 40 TB。
- RAID 6（n−2）：6 顆 = 32 TB（差 0.4 TB 不夠）→ **7 顆** → 40 TB。
- RAID 10（n/2）：**10 顆** → 40 TB。
邊界情況：**差 0.4 TB 就多買一顆**，這是 80% 上限的代價；forasoft 的「1.4–1.6 倍」經驗法則給 `25.92×1.5 =` 38.9 TB，與 40 TB 同量級。寫入吞吐：`40 × 2 Mbps = 80 Mbps =` **10 MB/s**，對陣列不是問題；真正的風險是**重建期間**寫入與重建搶頻寬。

**三、分群保存的省量**（本卡最重要的一個計算）：不是每支攝影機都需要一樣久。
- 入口／mantrap 8 支、4 Mbps、連續、90 天：`4×10.8×8×90 =` **31,104 GB**。
- 機房走道 32 支、2 Mbps、事件錄影（係數 0.4）、30 天：`2×10.8×0.4×32×30 =` **8,294 GB**。
- 合計 **39,398 GB ≈ 39.4 TB**。若全部統一「連續、90 天」：入口 31,104 + 走道 `2×10.8×32×90 =` 62,208 = **93,312 GB**。分群省 **57.8%**。→ 保存期間必須是**攝影機群組的屬性**，不是全域設定。事件錄影的代價是可能漏錄（forasoft 提到天氣或光線造成誤觸或漏觸）。

**四、邊緣儲存能撐多久**：128 GB SD 卡、2 Mbps：`128×10⁹ ÷ (2×10⁶/8) ÷ 3600 =` **142.2 小時 ≈ 5.9 天**（未計檔案系統與索引開銷，實際較短）。這是「NVR／網路斷了之後，這支攝影機的盲區多久才真正出現」。

**五、PoE 預算**：標準值（IEEE 802.3af/at 的 PSE→PD，兩個來源一致）：class 3 → PSE 15.4 W、PD 12.95 W；class 4 → PSE 30 W、PD 25.5 W。**電纜損耗**就是兩者的差（約 16%）。TRENDnet 指出：交換器可能依**等級**預留功率，而不是依實際用量。範例：24 埠、預算 250 W，攝影機實際 7.5 W 但是 class 3：
- 依等級預留：`250 ÷ 15.4 = 16.2` → 只能接 **16 支**（24 埠預留 369.6 W，超標）。
- 依實際用量（或交換器支援 LLDP 動態配置）：`24 × 7.5 = 180 W`，**24 支都行**。
同一台交換器、同一批攝影機，**答案是 16 還是 24 取決於預留模式**——所以 `allocation_mode` 是資料，不是細節。

**六、事件對影像的時間窗**：門禁在 t=100 s 告警，攝影機與門禁的時鐘偏移 8 s，預錄 5 s、後錄 10 s：安全窗 = `(100−5−8, 100+10+8) =` **(87, 118)**。若只取預錄 5 s 且偏移 8 s，則 `skew_ok(5, 8) = False`——**窗口根本沒涵蓋到事件**。

## 常見誤解

**以為「保存期間越長越安全」，但實際上它同時是儲存成本和隱私負債**。GDPR 要求「不長於必要」，EDPB 說例行影像幾天就夠；保存期間有**上限**（法律義務）與**下限**（合規或契約，如 PCI DSS 三個月說法、博弈規則 60 天），且被**法律保全**（legal hold）覆蓋時不能刪。這是一個區間加一個覆寫，不是一個數字。

**以為「錄影燈亮著就有證據」，但實際上要證據可用，必須能在保存期內被調出來**。如果稽核每 14 天才看一次門禁告警，而這群攝影機只保留 7 天，那麼第 8 天以後的事件**永遠沒有影像**，系統卻全程顯示「正常錄影」。這是第五個「缺東西」類問題。

**以為「PoE 交換器標 370 W，24 個 15 W 的攝影機就沒問題」，但實際上要看預留模式**。依等級預留時，class 3 的 7.5 W 攝影機佔 15.4 W 預算；而 PSE 的 15.4 W 在攝影機端只剩 12.95 W。算預算要同時說明「預留值」和「實際值」。

## 對資料模型的意涵

1. **`CameraGroup`：保存期間是一個區間，不是一個數字**。`CameraGroup{retention_days_min, retention_days_max, legal_hold: bool, record_mode: continuous|event|scheduled, activity_factor, bitrate_mbps}`。約束：`min ≤ max`；`legal_hold = true` 時 `max` 不生效；`activity_factor` 只在 `record_mode = event` 時有意義（又一個「模式欄位改變欄位意義」）。來源（法規、契約、政策）要放進 `Sourced`：這個 90 天是從哪來的。
2. **儲存是查詢，不是欄位**。`required_tb(array) = Σ_group gb_per_day × cams × days_max ÷ fill_ratio ÷ raid_efficiency`。`Array{raid_level, disks, disk_tb, fill_cap=0.8}`；`raid_level` 決定 `parity_disks`，與 [PDU](pdu-floor.md) 的 `wiring` 一樣是「模式欄位改變基數」。`STORAGE_SHORT` 告警：需求 > 陣列可用 × `fill_cap`。
3. **第五個「缺東西」告警：`DOOR_NO_VIDEO_COVERAGE`**。與 `DETECTION_COVERAGE_GAP`（dc-32）、`RELEASE_PATH_DEGRADED`（dc-33）、`DOOR_UNMONITORED`（dc-34）同類：沒有影像就沒有影像告警。資料模型要有 `Door.cameras: list[CameraRef]`（含 `view: outside|inside|both`），查詢「哪些門沒有攝影機」。延伸：`DOOR_VIDEO_EVENT_ONLY`（所有鏡頭都是事件錄影，漏錄風險）。
4. **`EVIDENCE_WINDOW_EXPIRED`**：`audit_lag_days ≥ retention_days_max` 時，門禁事件沒有可用影像。`audit_lag_days` 是**流程的屬性**（稽核週期），與設備無關，卻約束設備設定；這是設備資料第一次被**人員流程**約束。
5. **PoE 是電力鏈的消費者，且有預留模式**：`PoeSwitch{budget_w, allocation_mode: class|lldp|actual}`、`Camera{poe_class, max_pd_w, max_pse_w}`；`POE_BUDGET_EXCEEDED` = Σ（依模式取預留值或實際值）> `budget_w`。交換器的總功率要計入 UPS 分支負載（接 dc-08）。
6. **時鐘是資料**：`Camera.ntp_offset_s` 與 `Clip{camera, start, end, source: nvr|edge}`；`CLIP_TIME_SKEW`：`|offset| ≥ preroll`。把事件對到影像的唯一鍵是**時間**，時間不準就是整條關聯斷掉。

## 該問 facility 的問題

1. 每一扇門（尤其資料機房入口與 mantrap）有幾支攝影機看？是連續還是事件錄影？保存幾天，依據是哪份政策或契約？
2. 稽核人員多久看一次門禁告警與影像（`audit_lag_days`）？比最短的保存天數短嗎？
3. 攝影機的 PoE 交換器掛在哪個 UPS 分支、預留模式是依等級還是 LLDP？攝影機與門禁控制器的 NTP 來源是不是同一個？

## 動手練習（30–40 分鐘）

**目標**：把上述計算做成 `video.py`，並接上 dc-34 的 `Door`。**不要重寫** `core.py`；有則 `from core import Finding`，沒有就用 `(code, subject)` 元組代替。

```python
# video.py（約 70 行；骨架）
GB_PER_MBPS_DAY = 10.8
def gb_per_day(mbps, factor=1.0)           # mbps * 10.8 * factor
class Group: name, cams, mbps, factor, days;  def gb(self)
def total_gb(groups)
def raid_usable_disks(n, level)             # raid5: n-1, raid6: n-2, raid10: n//2
def min_disks(required_tb, disk_tb, level, fill=0.8)
def edge_buffer_hours(card_gb, mbps)
def poe_reserved_w(ports, mode)             # ports: [(class_max_w, actual_w)]；mode: "class"|"actual"
def poe_ok(ports, budget_w, mode)
def max_ports(budget_w, per_port_w)
def clip_window(t, pre, post, skew)         # (t-pre-|skew|, t+post+|skew|)
def skew_ok(pre, skew)                      # |skew| < pre
def evidence_expired(audit_lag_days, retention_days)   # lag >= retention
def door_video_findings(doors, cameras, groups, audit_lag_days)
   # DOOR_NO_VIDEO_COVERAGE / DOOR_VIDEO_EVENT_ONLY / EVIDENCE_WINDOW_EXPIRED / CLIP_TIME_SKEW
```

### 驗收表（已用參考實作跑過）

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | `gb_per_day(2)`；`gb_per_day(2) * 40 * 30` | **21.6**；**25920.0** GB |
| 2 | `min_disks(25.92, 8, "raid6")`；`"raid5"`；`"raid10"` | **7**；**6**；**10** |
| 3 | `raid_usable_disks(6,"raid6") * 8`；`(7,"raid6") * 8` | **32**（< 32.4 不足）；**40** |
| 4 | 入口 `Group(8, 4, 1.0, 90)`＋走道 `Group(32, 2, 0.4, 30)` 的 `total_gb` | **39398.4** |
| 5 | 同兩群改全部 `factor=1.0, days=90` | **93312.0**（省 **57.8%**） |
| 6 | `edge_buffer_hours(128, 2)`；`(256, 4)` | **142.2**；**142.2** |
| 7 | `max_ports(250, 15.4)`；`250 / 7.5` | **16**；**33.3**（受 24 埠限制，實際 24） |
| 8 | 24 埠 `(15.4, 7.5)`，預算 250：`poe_ok(..., "class")`／`"actual"` | **False**（369.6 W）／**True**（180 W） |
| 9 | `clip_window(100, 5, 10, 8)`；`skew_ok(5, 8)`；`skew_ok(10, 8)` | **(87, 118)**；**False**；**True** |
| 10 | `evidence_expired(7, 7)`；`(3, 7)` | **True**；**False** |
| 11 | 三扇門（d1：camera c1，A 群連續 90 天；d2：無攝影機；d3：camera c2，B 群事件錄影 7 天、NTP 偏移 8 s），`audit_lag=7` | `CLIP_TIME_SKEW(c2)`、`DOOR_NO_VIDEO_COVERAGE(d2)`、`DOOR_VIDEO_EVENT_ONLY(d3)`、`EVIDENCE_WINDOW_EXPIRED(d3)`（四項） |

**加分題**：把 `legal_hold` 加進 `Group`，寫 `effective_retention(group)`：hold 時回 `None`（不刪）。

## 自我檢核

**Q1. 40 支 2 Mbps 攝影機連續錄 30 天，用 8 TB 硬碟、RAID 6、80% 上限，最少要幾顆？**

??? note "答案"
    原始 `21.6×40×30 = 25,920 GB`；上限 80% → 需要可用 `25.92/0.8 = 32.4 TB`；RAID 6 可用 `(n−2)×8`，n=6 只有 32 TB 不夠，**n=7**（40 TB）。

**Q2. 一個資料中心要求保存 30 天，但稽核每 45 天才看一次告警。這會出什麼問題？**

??? note "答案"
    `audit_lag_days (45) ≥ retention_days (30)`，於是每個告警被看到時，影像已被覆寫。要改的是保存天數或稽核週期，不是儲存設備。告警 `EVIDENCE_WINDOW_EXPIRED`。

**Q3. 新增一扇門與它的攝影機，會讓你的資料模型長出什麼欄位與約束？**

??? note "答案"
    `Door.cameras`（含 `view`）、攝影機所屬 `CameraGroup`（`retention_days_min/max`、`record_mode`、`bitrate_mbps`）、`poe_class`／`max_pd_w`、`ntp_offset_s`。約束：每扇門至少一支攝影機（否則 `DOOR_NO_VIDEO_COVERAGE`）；`retention_days_max > audit_lag_days`；`|ntp_offset_s| < preroll`；PoE 預留總和 ≤ 交換器預算；陣列需求 ≤ 可用 × 0.8。

---

**下一張**：`dc-36` 漏水偵測（leak detection）
