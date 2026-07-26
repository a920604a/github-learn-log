# Panniantong/Agent-Reach — raw

- URL: https://github.com/Panniantong/Agent-Reach
- Description: Give your AI agent eyes to see the entire internet. Read & search Twitter, Reddit, YouTube, GitHub, Bilibili, XiaoHongShu — one CLI, zero API fees.
- Language: Python
- Topics: agent-infrastructure, ai-agent, ai-search, automation, bilibili, claude-code, cli, cursor, free-api, llm-tools, mcp, python, reddit-scraper, twitter-scraper, web-scraper, xiaohongshu, youtube-transcript
- Stars: 60895
- License: MIT
- Size: 1,776 KB
- Fetched: 2026-07-26 (catch-up)

## README (excerpt, 中文版原文)

**給你的 AI Agent 一鍵裝上互聯網能力。當下最穩的接入方式，替你選好、裝好、體檢好——接入方式會換代，你不用操心。**

### 問題陳述
AI Agent 能幫你寫代碼、改文檔、管項目，但你讓它去網上找點東西：
- YouTube 教程摘要 → 拿不到字幕
- Twitter 搜索 → API 要付費
- Reddit → 403 被封
- 小紅書 → 必須登錄
- B 站 → 通用工具被風控攔截
- 網頁 → 抓回一堆 HTML 標籤
- GitHub Issue → 認證配置很麻煩
- RSS → 要自己裝庫寫代碼

### 一句話部署
```
帮我安装 Agent Reach：https://raw.githubusercontent.com/Panniantong/agent-reach/main/docs/install.md
```
複製給你的 Agent，幾分鐘後它就能讀推特、搜 Reddit、看 YouTube、刷小紅書。

### 支持的平台
| 平台 | 裝好即用 | 配置後解鎖 |
|---|---|---|
| 網頁 | 讀取任意 URL | — |
| YouTube | 字幕 + 搜索 | — |
| RSS | Atom/RSS 訂閱 | — |
| 全網搜索 | — | MCP 語義搜索（免費） |
| GitHub | — | Issue/PR/代碼搜索 |
| Reddit | — | 帖子 + 評論 |
| Twitter | — | 用戶時間線 + 搜索 |
| Bilibili | — | 視頻字幕 |
| 小紅書 | — | 圖文筆記 |

### Primary + fallback routing
每個平台都是「首選 + 備選」多後端路由。例：
- YouTube：youtube-transcript-api（首選）→ yt-dlp（備選）
- Bilibili：yt-dlp（原首選，2026-06 被風控封）→ bili-cli（現首選，用戶零操作切換）

「平台封了我們修，有新渠道我們加，你不用自己盯」是產品承諾的核心。

### 完全免費 + 隱私安全
- 所有工具開源、所有 API 免費（可選付費代理 $1/月）
- Cookie 只存本地
- 代碼隨時可審查

### 自帶診斷
`agent-reach doctor` — 一條命令告訴你哪個通、哪個不通、怎麼修。

### MCP + CLI 雙介面
CLI 給人用，MCP 給 agent 用（Claude Code / OpenClaw / Cursor / Windsurf）。同一個底層工具集，兩種暴露方式。

### 架構亮點
- **Adapter Registry**：每個平台 = 一個 adapter 實例，統一介面（`fetch(url) → normalized_content`）
- **Backend rotation**：每個 adapter 內部有 primary + fallback backend list，failure 時自動切換
- **Health check**：`doctor` 命令對每個 adapter 跑 smoke test
- **Zero-config where possible**：能免登錄的就免登錄；需要 cookie 的走本地存取（不外傳）

_Fetched via api.github.com on 2026-07-26 for catch-up ingest. Full README (330 lines) covers 平台清單 / 快速上手 / 配置細節 / 設計理念 / 貢獻指南。_
