---
id: dc-41
title: Modbus RTU / TCP（暫存器位址、字序與總線時間預算）
category: systems
written_at: 2026-10-16
sources:
  - https://en.wikipedia.org/wiki/Modbus
  - https://umodbus.readthedocs.io/en/stable/functions.html
  - https://pymodbus.readthedocs.io/en/latest/source/client.html
  - https://industrialmonitordirect.com/blogs/knowledgebase/modbus-4-5-and-6-digit-addressing-complete-pdu-reference
  - https://industrialmonitordirect.com/blogs/knowledgebase/modbus-rtu-frame-detection-identifying-message-start
  - https://industrialmonitordirect.com/blogs/knowledgebase/modbus-tcp-sockets-unit-id-255-and-multi-master-architecture
  - https://industrialmonitordirect.com/blogs/knowledgebase/troubleshooting-em1000-meter-modbus-pdm-addressing-and-float
related: [dc-15, dc-38, dc-39, dc-40, dc-42, dc-43, dc-45]
---

# Modbus RTU / TCP（Modbus serial & TCP）

前面幾張卡反覆說設備「透過 Modbus 接進 EPMS／BMS」，這張卡打開那條線。Modbus 是 1979 年的主從式協定：主站問「某位址起的 N 個 16 位元暫存器」，從站回一串位元組。**它只傳位元組，不傳型別、單位、字序或時間。**重點因此不在封包，而在封包外面那張暫存器表，以及線上的時間成本。

## 六格

### 拓撲位置
上游：有暫存器表的設備，如[電錶](power-meter.md)、[UPS](ups-double-conversion.md)、[rack PDU](rack-pdu.md)、VFD、斷路器跳脫單元。下游：輪詢者（EPMS、BMS 監督控制器、DCIM collector；見 [dc-39](epms-electrical-power-monitoring.md)、[dc-38](bms-building-management-system.md)）。RTU 走 RS-485 菊鍊（單主站）；TCP 走乙太網；兩者間用 TCP↔RTU 閘道（`dc-45`）。它是觀察層的**傳輸邊**，不在電力樹上。

### 容量單位
暫存器 = 16 位元；一次讀最多 125 個（FC03/04）、寫最多 123 個（FC16）、線圈 2000 個。**真正稀缺的是總線時間**（毫秒），不是位元組數：見下方計算二。

### 冗餘表達
協定本身**沒有**冗餘機制（來源未提）。RTU 是單一主站、一條線：一顆壞收發器可拉走整條（[dc-15](power-meter.md) 已寫）。TCP 允許多個 client 但**沒有仲裁**，同一暫存器被兩個 master 寫入時最後寫入者勝。冗餘只能由架構補（雙閘道、雙輪詢者），協定不會告訴你。

### 遙測介面

| FC | 用途 | 表 | 單次上限 |
|---|---|---|---|
| 01 / 02 | 讀線圈／離散輸入 | 位元 | 2000 |
| 03 | 讀保持暫存器 | 16 位元 R/W | 125 |
| 04 | 讀輸入暫存器 | 16 位元 R | 125 |
| 05 / 06 | 寫單一線圈／暫存器 | — | 1 |
| 15 / 16 | 寫多個線圈／暫存器 | — | FC16 為 123 |

回應功能碼加 0x80 即為**例外**（01 非法功能、02 非法資料位址、03 非法資料值、04 從站故障、06 忙碌…）。位元組序為 big-endian。RTU 從站位址 1–247，0 為廣播（無回應）。

### 故障域
RTU：整條 RS-485（任一台短路／收發器故障、錯誤鮑率或奇偶設定的新設備）。TCP：交換器埠、閘道、設備的連線上限（嵌入式從站常見只收 4／8／16／32 條連線，單一來源）。**例外回應表示設備活著**，逾時才表示聯絡不上——兩者的處置完全不同。

### 維護特性
韌體升級可能改暫存器位址（版本不符時讀取回例外 02）；換電錶要重設 unit ID、鮑率、奇偶。暫存器表是**型號＋韌體版本**的屬性。

## 來源分歧

1. **RTU 框間靜默時間（19200 baud）**：同一網站兩篇文章給出兩個數字——RTU 文章以 11 位元字元算，字元時間 0.573 ms，3.5 字元即 **2.005 ms**；TCP 文章寫「約 1.83 ms」，與 **10 位元字元**（3.5×10/19200 = 1.823 ms）吻合。Wikipedia：每位元組 11 位元，高速率建議固定 1.750 ms。**未裁決**，卡片一律用 11 位元，並把 `bits_per_char` 做成欄位。
2. **浮點範例數值**：來源把 `7F 7F 00 00` 誤解成「約 1.7E+38」。實際解碼為 **3.39E+38**（1.7E+38 是 2¹²⁷）。二手數字要自己算過。
3. **pymodbus 簽名**：文件頁（4.0.0dev16）用 `device_id`；3.x 簽名**未查證**。練習以標準庫為主，pymodbus 只當加分題。
4. **規範原文未讀到**：modbus.org 兩份 PDF（應用協定、serial line）抓取失敗。本卡數字來自 Wikipedia、umodbus 文件與一家二手知識庫（後者是同一來源的多篇文章，**不算多個獨立來源**）。

## 關鍵數字與計算

**一、尺寸上限怎麼來的。** PDU 上限 253 位元組（Wikipedia）。FC03 回應 = 功能碼 1 + 位元組數 1 + 2n，n=125 → 252 ≤ 253；n=126 → 254，超過。FC16 請求 = 1+2+2+1+2n，n=123 → 252；n=124 → 254。RTU ADU = 位址 1 + PDU 252 + CRC 2 = 255 ≤ 256；TCP ADU = MBAP 7 + 252 = 259 ≤ 260。125 與 123 不是隨意的數字，是 253 的推論。

**二、一條 RS-485 的輪詢預算。** 每個字元 11 位元（1 起始＋8 資料＋1 同位＋1 停止）。讀 n 個暫存器：請求 8 位元組、回應 5+2n 位元組，加上前後各一個 3.5 字元靜默：

`t(n, baud) = (8 + 5 + 2n + 2×3.5) × 11 / baud`

- 9600 baud、n=10：(8+25+7)=40 字元 ×11/9600 = **45.83 ms**；30 台 = **1375 ms**。若需求間隔 1 s，**超標**；最多容納 ⌊1000/45.83⌋ = **21 台**。
- 19200 baud：**22.92 ms**，30 台 = **687.5 ms**，最多 **43 台**。
- 同一台 10 個暫存器改成 10 次單暫存器讀取：10 × (8+7+7=22 字元) → **252.1 ms**，是一次批次讀取的 **5.5 倍**。
- 這是**下限**：未含從站回應延遲、重試與閘道延遲（單一來源給 5–50 ms）。

**三、位址換算。** Modicon 慣例「40013」＝保持暫存器第 13 號（1 起算），線上 PDU 位址 = 13−1 = **12（0x000C）**；「30001」→ 0。前綴 4/3 只說明是哪張表，**不上線**。直接把 13 當 PDU 位址送出，在表的中段不會報錯，只會**回傳隔壁暫存器的值**（我的推論；來源說錯誤形式「通常」得到例外 02，那只發生在表尾或未實作處）。

**四、字序與型別。** 50.0 Hz 的 IEEE 754 為 `0x42480000`。ABCD 序：暫存器 `[0x4248, 0x0000]`；CDAB 序（低字先）：`[0x0000, 0x4248]`。拿 CDAB 的資料當 ABCD 解碼 → `0x00004248` = **2.38×10⁻⁴¹**（看起來像「頻率 0」，而且是一個成功的回應）。整數例：`[0x0001, 0xE240]` = 123456，÷1000 = **123.456 A**；`[0xFFFF, 0xFFFE]` 是 int32 的 **−2**、uint32 的 4294967294——有號與否也在表外。

## 常見誤解

**以為暫存器「40013」就是線上位址 40013，但實際上線上是 0 起算的 16 位元位置 12，前綴只是表的分類**：四位、五位、六位寫法（4013、40013、400013）送出的位元組都是 `00 0C`；最危險的是 off-by-one 在表中段不報錯，只讀到鄰居。

**以為讀得回數字就是讀對了，但實際上 Modbus 回的只是 16 位元原始值，型別、字序、scale、單位全在協定外**：字序錯得到 10⁻⁴¹ 或 10³⁸，scale 套兩次差 10 或 100 倍，這些全都是「成功的回應」。唯一的防線是表本身有版本、有欄位、有驗收。

**以為輪詢越快資料越新，但實際上總線時間是共享資源，且一個輪詢週期內各設備不是同一時刻的量測**：30 台、9600 baud 的一輪 1375 ms，第 1 台與第 30 台的值差 1.4 秒；把它們加總（如總電力、PUE）混了不同時刻。Modbus 沒有時間戳，時間戳是輪詢者讀到時打的。

## 對資料模型的意涵

1. **暫存器表是有版本的獨立實體，不是設備上的欄位。** `RegisterMap{id, model, firmware_range, version}`；`RegisterDef{name, table, fc, pdu_addr, doc_addr, doc_basis, count, dtype, word_order, scale, offset, unit, access}`。**以 `pdu_addr` 為正本**，`doc_addr` 與 `doc_basis`（`modicon5/modicon6/one/zero`）留作稽核——這樣廠商手冊與線上抓包永遠對得起來。`Asset.register_map_id` 為空即「看得見設備、看不懂它」。
2. **`count ≥ 2` 時 `word_order` 不得為空**——又一個「模式欄位改變基數」（同 [dc-14](rack-pdu.md) 的 `wiring` 之於 `Outlet.legs`）。字序預設值是 bug 來源，不是便利。
3. **Endpoint 與 Bus 是資源，不是標籤。** `Endpoint{transport: rtu|tcp, bus_id|host:port, unit_id, baud, bits_per_char}`；`unit_id` 在同一條 bus 內唯一，經閘道時是下游 RTU 位址（直連 TCP 常為 0xFF）。`Bus.cycle_ms` 是**派生值**（各端點 `t(n,baud)` 之和）；`Point.interval_s` 的**有效值**是 `max(設定值, cycle_ms)`，這直接約束 [dc-38](bms-building-management-system.md) 的 `interval_s ≤ min_duration_s / 2`——你想要的取樣率可能物理上做不到。
4. **時間基準沿用 [dc-39](epms-electrical-power-monitoring.md)：Modbus Point 的 `time_basis = poll`，不確定度 = 該 bus 的 `cycle_ms`**，`clock_id` 指向輪詢者的時鐘。跨設備加總要帶 `skew_ms`，否則 PUE 一類的比值在負載變動時帶著看不見的誤差。
5. **讀取結果是四態，不是值**：`OK / EXCEPTION(code) / TIMEOUT / CRC_ERROR`。`EXCEPTION 02` 全面出現＝表版本不符（設備活著）；`TIMEOUT`＝聯絡不上。dc-38 的 `POINT_STALE` 不能把兩者混為一談。
6. **第十一個「缺東西」告警：`ASSET_NO_REGISTER_MAP`**（資產宣稱走 Modbus 卻沒有表），配對 `WORD_ORDER_UNDECLARED`（雙暫存器型別缺字序）與 `POLL_BUDGET_EXCEEDED`（bus 週期超過需求間隔）。接在 [dc-40](dcim-scope-and-market.md) 的三集合差集之後。

## 該問 facility 的問題

1. 每條 RS-485 掛幾台、鮑率與同位設定（8N1／8E1／8N2）各是多少？有沒有 TCP↔RTU 閘道，unit ID 對照表在誰手上？
2. 每種設備的暫存器表（含韌體版本）從哪裡取得？換韌體時有沒有人驗過位址沒動？
3. EPMS、BMS、DCIM 是否各自輪詢同一台電錶？該電錶同時最多接受幾條 TCP 連線？

## 動手練習（35 分鐘）

**目標**：寫 `modbus.py`（標準庫即可），實作框、位址、字序解碼、總線時間預算，以及第十一個「缺東西」告警。**接在 [dc-40](dcim-scope-and-market.md) 的 `dcim.py` 後面**：沿用 `(code, subject)` 元組，`check_maps` 的輸出可以直接 append 到同一個 `findings`；`modbus_assets` 就取 `dcim.reconcile` 裡的已登記資產子集。

```python
# modbus.py（約 60 行；骨架）
def crc16(b: bytes) -> int            # init 0xFFFF，多項式 0xA001（反射）
def rtu_frame(unit, pdu) -> bytes     # unit + pdu + CRC（低位元組在前）
def mbap_frame(tid, unit, pdu) -> bytes   # >HHHB：tid, 0, len(pdu)+1, unit
LIMITS = {1: 2000, 2: 2000, 3: 125, 4: 125}
def read_pdu(fc, addr, qty)           # qty 不在 1..LIMITS[fc] -> ValueError
def pdu_addr(doc, basis)              # modicon5: doc%10000-1；modicon6: doc%100000-1；one: doc-1；zero: doc
def decode32(regs, order, kind="f")   # order: ABCD/CDAB/BADC/DCBA；kind: f/i/u
def txn_ms(n_regs, baud, bits=11, turn_ms=0.0)   # (8+5+2n+7)*bits/baud*1000 + turn
def max_slaves(baud, n_regs, interval_ms)        # 取整數
def check_bus(buses, interval_ms)     # buses={name:(baud,[各端點 n_regs])}；週期 > interval -> POLL_BUDGET_EXCEEDED
@dataclass Reg: name, addr, count, dtype, order=None
def check_maps(modbus_assets, maps)   # maps={asset:[Reg]}；空/缺 -> ASSET_NO_REGISTER_MAP；count==2 且 order None -> WORD_ORDER_UNDECLARED("asset.name")
```

測試資料：`buses = {"BUS-1": (9600, [10]*30), "BUS-2": (19200, [10]*30), "BUS-3": (9600, [125])}`；`maps = {"PM-1": [Reg("freq",3109,2,"f","CDAB"), Reg("kw",3000,2,"f",None)], "PM-2": [Reg("v",0,1,"u")], "UPS-A": [Reg("load",5,2,"i")], "PM-3": []}`；`modbus_assets = {PM-1, PM-2, PM-3, UPS-A, PDU-A}`。

### 驗收表

| # | 輸入 | 期望輸出 |
|---|---|---|
| 1 | `rtu_frame(0x11, bytes.fromhex("0100130025")).hex()` | `1101001300250e84`（CRC 低位元組在前＝`0E 84`） |
| 2 | `rtu_frame(0x11, bytes.fromhex("03006B0003")).hex()` | `1103006b00037687` |
| 3 | `mbap_frame(1, 0xFF, read_pdu(3, 0, 6)).hex()` | `000100000006ff0300000006` |
| 4 | `pdu_addr(40013,"modicon5")`；`(400013,"modicon6")`；`(13,"one")`；`(12,"zero")`；`(30001,"modicon5")` | 皆 **12**；最後一個 **0** |
| 5 | `read_pdu(3,0,125)`；`(3,0,126)`；`(3,0,0)`；`(1,0,2000)`；`(1,0,2001)` | 成功；ValueError；ValueError；成功；ValueError |
| 6 | `decode32([0x4248,0],"ABCD")`；`decode32([0,0x4248],"CDAB")` | 皆 **50.0** |
| 7 | `decode32([0,0x4248],"ABCD")`（字序用錯） | **2.38e-41**（不報錯，這就是重點） |
| 8 | `decode32([0x0001,0xE240],"ABCD","i")/1000` | **123.456** |
| 9 | `decode32([0xFFFF,0xFFFE],"ABCD","i")`；`"u"` | **−2**；**4294967294** |
| 10 | `decode32([0x4842,0],"BADC")`；`decode32([0,0x4842],"DCBA")` | 皆 **50.0** |
| 11 | `txn_ms(10,9600)`；`txn_ms(10,19200)`；`txn_ms(125,9600)` | **45.83**；**22.92**；**309.4** |
| 12 | `10*txn_ms(1,9600)`（十次單讀） | **252.1**（一次批次讀的 5.5 倍） |
| 13 | `max_slaves(9600,10,1000)`；`(19200,10,1000)` | **21**；**43** |
| 14 | `check_bus(buses,1000)` | `[("POLL_BUDGET_EXCEEDED","BUS-1")]` |
| 15 | `check_bus(buses,300)` | 三條皆超標 |
| 16 | `check_maps(modbus_assets, maps)` | `[("ASSET_NO_REGISTER_MAP","PDU-A"), ("ASSET_NO_REGISTER_MAP","PM-3"), ("WORD_ORDER_UNDECLARED","PM-1.kw"), ("WORD_ORDER_UNDECLARED","UPS-A.load")]` |

**加分題**：（一）`pip install pymodbus` 起 TCP server，把 `[0, 0x4248]` 放在位址 3109，client 讀回後丟給 `decode32`（API 先看 `help()`，別照舊範例抄）。（二）給 `Bus` 加 `bits_per_char`，用 10 位元重算 19200 baud 的框間時間（1.823 vs 2.005 ms），問：對 43 台的上限有影響嗎？

## 自我檢核

**Q1. 設備手冊寫「保持暫存器 40109，雙暫存器 IEEE 浮點」。你的 `RegisterDef` 至少要存哪些欄位，才能讓另一個人不看手冊也讀對？這會讓資料模型長出什麼欄位？**

??? note "答案"
    `pdu_addr`（= 108）、`doc_addr=40109` 與 `doc_basis=modicon5`、`fc`（03）、`count=2`、`dtype=f32`、`word_order`（ABCD／CDAB…，**不得為空**）、`scale/offset`、`unit`，再加指向 `RegisterMap.version` 的外鍵。缺字序就是 `WORD_ORDER_UNDECLARED`；缺整張表就是 `ASSET_NO_REGISTER_MAP`。

**Q2. 一條 9600 baud 的 RS-485 要在 1 秒內輪詢完，每台讀 10 個暫存器，22 台可以嗎？換成 19200 呢？**

??? note "答案"
    9600：22 × 45.83 = **1008.3 ms > 1000**，不行（上限 21 台）。19200：22 × 22.92 = **504.2 ms**，可以（上限 43 台）。這仍是下限。

**Q3. EPMS 對某台電錶所有讀取突然都回例外 02，而同一條 bus 上其他電錶正常。是設備掛了嗎？你的資料模型該怎麼反映？**

??? note "答案"
    不是。例外回應代表設備活著且在回應，02 是「位址未實作」，最常見原因是**韌體升級後暫存器表版本不符**。讀取結果應記成 `EXCEPTION(02)` 而非 `TIMEOUT`，告警應是「表版本不符」而非「設備離線」，並要求 `Asset.register_map_id` 的 `firmware_range` 與設備回報的韌體相符。

**下一張**：`dc-42` BACnet 物件模型
