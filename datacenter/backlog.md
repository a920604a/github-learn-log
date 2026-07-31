---
track: datacenter
updated: 2026-07-31
---

# 學習佇列

> 每日排程從**最上面未完成的一項**取一項，產出一張卡，然後把它標成完成。
> 這是 syllabus-driven，不是 crawl-driven —— **佇列決定學什麼，不是當天爬到什麼決定學什麼。**

## 規則

- 每個工作日消耗 **1 項**（週六日不跑，週日產週報）
- 完成後把 `[ ]` 改成 `[x]` 並補上日期與卡片連結
- 卡片寫在 `devices/<slug>.md` 或 `topics/<slug>.md`
- 若某項在寫的過程中發現需要拆成兩張，就地插入新項目到佇列
- **順序可以改**：若你在公司剛好碰到某個設備（例如下週要看 UPS 測試），把它拉到最前面

## 第一輪：電力鏈（對應 roadmap 階段 2）

依實際電力流向排序，從上游往下游走。

- [x] `dc-01` 市電進線與受電設施（utility feed / 責任分界點） — 2026-07-28 [卡片](devices/utility-feed.md)
- [x] `dc-02` 變壓器（transformer） — 2026-07-29 [卡片](devices/transformer.md)
- [x] `dc-03` 中壓開關設備（MV switchgear）— 額定與保護 — 2026-07-30 [卡片](devices/mv-switchgear.md)
- [x] `dc-03b` LSC 服務連續性分級與抽出式斷路器互鎖 — 2026-07-31 [卡片](devices/lsc-and-interlocks.md)
- [ ] `dc-04` 自動切換開關 ATS（automatic transfer switch）
- [ ] `dc-05` 柴油發電機（diesel generator）
- [ ] `dc-06` 日用油箱與儲油槽（day tank / bulk fuel）
- [ ] `dc-07` 低壓主配電盤（LV switchgear / main distribution board）
- [ ] `dc-08` UPS 不斷電系統（雙轉換式）
- [ ] `dc-09` UPS 電池組（鉛酸 VRLA vs 鋰電 LiB）
- [ ] `dc-10` 靜態切換開關 STS（static transfer switch）
- [ ] `dc-11` PDU 配電單元（含變壓器型 / 非變壓器型）
- [ ] `dc-12` RPP 遠端配電盤（remote power panel）
- [ ] `dc-13` 匯流排 busway / 插接箱（tap-off box）
- [ ] `dc-14` 機櫃電源 rack PDU（basic / metered / switched）
- [ ] `dc-15` 電力監測儀表與電錶（power meter / EPMS 感測點）
- [ ] `dc-16` 設備端雙電源與單電源（dual-corded / single-corded + ATS PDU）

## 第二輪：冷卻鏈（對應 roadmap 階段 3）

- [ ] `dc-17` 冷卻水塔（cooling tower）
- [ ] `dc-18` 冰水主機（chiller，氣冷 vs 水冷）
- [ ] `dc-19` 一次側／二次側冰水泵（primary / secondary pump）
- [ ] `dc-20` 儲冷槽（thermal storage tank）與 ride-through
- [ ] `dc-21` 板式熱交換器與免費冷卻（plate HX / free cooling）
- [ ] `dc-22` CRAH 機房空調（冰水式）
- [ ] `dc-23` CRAC 精密空調（直膨式）
- [ ] `dc-24` 加濕與除濕（humidification / dehumidification）
- [ ] `dc-25` 冷熱通道封閉（containment）與氣流管理
- [ ] `dc-26` 液冷 CDU（coolant distribution unit）
- [ ] `dc-27` 後門熱交換器 RDHx 與直接晶片液冷 DLC

## 第三輪：空間、消防、安全（對應 roadmap 階段 1 補完）

- [ ] `dc-28` 站點／建築／樓層／機房區的空間層級
- [ ] `dc-29` 機櫃與 U 位（rack / rack unit / 盲板）
- [ ] `dc-30` 高架地板與線槽走線架
- [ ] `dc-31` 配線架與結構化布線（patch panel / structured cabling）
- [ ] `dc-32` 極早期偵煙 VESDA
- [ ] `dc-33` 氣體滅火系統與消防警報盤
- [ ] `dc-34` 門禁控制器、讀卡機、人員通道閘
- [ ] `dc-35` CCTV 與影像保存
- [ ] `dc-36` 漏水偵測（leak detection）
- [ ] `dc-37` 溫濕度感測器佈點策略

## 第四輪：系統與協定（對應 roadmap 階段 4）

- [ ] `dc-38` BMS 樓宇管理系統
- [ ] `dc-39` EPMS 電力監控系統（與 BMS 的分工與斷點）
- [ ] `dc-40` DCIM 的範疇與市場現況
- [ ] `dc-41` Modbus RTU / TCP 基礎與暫存器位址
- [ ] `dc-42` BACnet 物件模型與 MS/TP vs IP
- [ ] `dc-43` SNMP 與 MIB（UPS / rack PDU 常見 OID）
- [ ] `dc-44` Redfish / IPMI 伺服器帶外管理
- [ ] `dc-45` 閘道器與協定轉換（protocol gateway）

## 第五輪：主題卡（非設備，對應 roadmap 階段 4–5）

- [ ] `topic-01` 銘牌值 vs 降載值 vs 實測值
- [ ] `topic-02` 斷路器 80% 連續負載規則
- [ ] `topic-03` N / N+1 / 2N / 2N+1 的精確定義與差異
- [ ] `topic-04` 擱置容量 stranded capacity 的四種型態
- [ ] `topic-05` Tier I–IV 定義與 concurrent maintainability
- [ ] `topic-06` 故障域 fault domain 的建模方式
- [ ] `topic-07` PUE 定義、量測點、常見造假手法
- [ ] `topic-08` ASHRAE TC 9.9 熱環境 class 與告警門檻設計
- [ ] `topic-09` NetBox 電力模型逐欄位拆解（PowerPanel → PowerFeed → Rack → Device）
- [ ] `topic-10` NetBox 模型的斷點：上游 UPS/發電機該怎麼自己補
- [ ] `topic-11` 設施告警 vs 軟體 SLO：為什麼 error budget 不能照搬
- [ ] `topic-12` 四大黃金訊號在設施場景的對應物
- [ ] `topic-13` MOP / SOP / EOP 與變更窗口
- [ ] `topic-14` 工單與 CMMS 資料模型
- [ ] `topic-15` 事件分級與升級路徑
- [ ] `topic-16` Commissioning Level 1–5 各測什麼

---

## 進度

- 總項目：62（2026-07-30 從 dc-03 拆出 dc-03b）
- 已完成：4
- 預估完成：每週 5 項 → 約 13 週跑完第一到第四輪，加主題卡約 15–16 週（深度優先，慢一點沒關係）

> 完成第一輪（電力鏈 16 項）時應該回頭做一次檢查：
> **拿你們公司的單線圖，逐段對照你寫過的卡片，看有沒有哪一段是圖上有、但你的佇列裡沒有的設備。** 有的話就地補進佇列。
