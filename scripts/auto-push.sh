#!/bin/bash
# github-learn-log — 自動 push
#
# 為什麼需要這支：Cowork 排程任務跑在沙箱裡，沙箱沒有你的 SSH key，
# git push 一定失敗（Host key verification failed）。所以排程只負責
# 「爬 → 寫 → commit」，push 由這支在你 Mac 上的 launchd job 補完。
# 好處是不需要把任何 token 明碼存在任何地方。
#
# 2026-07-29 修正：原本排 08:10 單次執行，但排程任務 08:12 才啟動、
# 08:31 才 commit 完 —— push job 比 commit 早跑了 21 分鐘，於是漏推。
# 改成每 30 分鐘檢查一次。沒東西可推時直接結束且不寫 log，成本趨近於零。
#
# 安裝：
#   chmod +x scripts/auto-push.sh
#   cp scripts/com.github-learn-log.push.plist ~/Library/LaunchAgents/
#   launchctl load ~/Library/LaunchAgents/com.github-learn-log.push.plist
#
# 重新安裝（改過 plist 之後）：
#   launchctl unload ~/Library/LaunchAgents/com.github-learn-log.push.plist
#   cp scripts/com.github-learn-log.push.plist ~/Library/LaunchAgents/
#   launchctl load ~/Library/LaunchAgents/com.github-learn-log.push.plist
#
# 確認有裝成功：
#   launchctl list | grep github-learn-log
#
# 手動測一次：
#   ./scripts/auto-push.sh; tail -20 /tmp/github-learn-log-push.log

set -uo pipefail

REPO="/Users/chenyuan/Desktop/side-projects/github-learn-log"
LOG="/tmp/github-learn-log-push.log"
BRANCH="main"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"; }

cd "$REPO" || { log "ERROR: 找不到 repo $REPO"; exit 1; }

# --- 第一關：用本機 ref 判斷有沒有待推，不連網 ---
# 每 30 分鐘跑一次，絕大多數時候這裡就結束了，不留 log、不打網路。
AHEAD=$(git rev-list --count "origin/${BRANCH}..${BRANCH}" 2>/dev/null || echo 0)
[ "$AHEAD" -eq 0 ] && exit 0

log "偵測到 $AHEAD 個待 push 的 commit"

# --- 第二關：確定有東西要推了，才載入 SSH key 並連網 ---
# launchd 的環境沒有登入 shell 的 ssh-agent，把 keychain 裡的 key 載進來。
# 前提：~/.ssh/config 有設 UseKeychain yes，或曾跑過 ssh-add --apple-use-keychain
ssh-add --apple-load-keychain >/dev/null 2>&1

if ! git fetch origin "$BRANCH" --quiet 2>>"$LOG"; then
  log "WARN: fetch 失敗（可能沒網路），這輪跳過，30 分鐘後再試"
  exit 0
fi

# fetch 後重算——遠端可能已經有人推過了
AHEAD=$(git rev-list --count "origin/${BRANCH}..${BRANCH}" 2>/dev/null || echo 0)
if [ "$AHEAD" -eq 0 ]; then
  log "fetch 後發現已同步（可能在別台機器推過了），結束"
  exit 0
fi

BEHIND=$(git rev-list --count "${BRANCH}..origin/${BRANCH}" 2>/dev/null || echo 0)
if [ "$BEHIND" -gt 0 ]; then
  log "WARN: 落後 origin $BEHIND 個 commit（可能在別台機器改過）→ 不自動 push，請手動處理"
  exit 1
fi

# 有未 commit 的東西不擋 push，那是你手上的活
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  log "NOTE: working tree 有未 commit 的改動，略過不管"
fi

if git push origin "$BRANCH" >>"$LOG" 2>&1; then
  log "OK: push 成功（$AHEAD commits）→ CF Pages 應該會自動 rebuild"
  # 需要 macOS 通知的話把下面這行取消註解
  # osascript -e "display notification \"push 了 $AHEAD 個 commit\" with title \"github-learn-log\""
else
  log "ERROR: push 失敗，詳見上方輸出"
  exit 1
fi
