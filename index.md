---
title: github-learn-log
---

# github-learn-log

個人資料庫：GitHub trending 專案的架構 / 資料設計學習軌跡。

每天由 [Claude Code routine](https://claude.ai/code/routines) 自動掃 GitHub trending，挑 1–2 個「架構深度 + 週末可重造」的專案，寫成鐵人日誌風的 markdown 網絡（entity 頁 × 累加式概念頁 × 日/週報）。

## 從哪裡開始逛

- [本站索引 (Home)](Home.md) — 分類標籤、學習軌跡、日報 / 週報 / 專案 / 概念清單（自動更新）
- 日報：從左側 nav 的「日報」進，選當日看兩張 repo 卡片
- 週報：週日產出，內含當週橫向比較
- 專案（Repos）：每個 800–1000 字，含系統架構 mermaid、資料設計、為什麼這樣做
- 概念（Concepts）：跨 repo 累加的模式頁，同一模式被 ≥ 2 個專案觸及才開頁
- [詞彙表 (Glossary)](glossary.md) — 比喻 ↔ 技術對照

## 設計哲學

套用 [Karpathy 的 llm_wiki 三層](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)：

- **raw sources** — GitHub API 抓的原料，不動（不 publish 到本站）
- **wiki** — LLM 依 schema 寫的整理層（就是你看到的這裡）
- **schema (CLAUDE.md)** — 由人維護的寫作 / 累加規則
