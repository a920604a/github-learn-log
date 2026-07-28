#!/bin/bash
# github-learn-log — 自動 push
#
# 為什麼需要這支：Cowork 排程任務跑在沙箱裡，沙箱沒有你的 SSH key，
# git push 一定失敗（Host key verification failed）。所以排程只負責
# 「爬 → 寫 → commit」，push 由這支在你 Mac 上的 launchd job 補完。
# 好處是不需要把任何 token 明碼存在任何地方。
#
# 安裝：
#   chmod +x scripts/auto-push.sh
#   cp scripts/com.github-learn-log.push.plist ~/Library/LaunchAgents/
#   launchctl load ~/Library/LaunchAgents/com.github-learn-log.push.plist
#
# 解除安裝：
#   launchctl unload ~/Library/LaunchAgents/com.github-learn-log.push.plist
#   rm ~/Library/LaunchAgents/com.github-learn-log.push.plist
#
# 手動測一次：
#   ./scripts/auto-push.sh && tail -20 /tmp/github-learn-log-push.log

set -uo pipefail

REPO="/Users/chenyuan/Desktop/side-projects/github-learn-log"
LOG="/tmp/github-learn-log-push.log"
BRANCH="main"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"; }

cd "$REPO" || { log "ERROR: 找不到 repo $REPO"; exit 1; }

# launchd 的環境沒有登入 shell 的 ssh-agent，把 keychain 裡的 key 載進來。
# 前提：~/.ssh/config 有設 UseKeychain yes，或曾跑過 ssh-add --apple-use-keychain
ssh-add --apple-load-keychain >/dev/null 2>&1

# 有沒有未 commit 的東西？有就記一筆但不擋 push（那是你手上的活）
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  log "NOTE: working tree 有未 commit 的改動，略過不管"
fi

git fetch origin "$BRANCH" --quiet 2>>"$LOG"

AHEAD=$(git rev-list --count "origin/${BRANCH}..${BRANCH}" 2>/dev/null || echo 0)

if [ "$AHEAD" -eq 0 ]; then
  log "沒有待 push 的 commit，結束"
  exit 0
fi

BEHIND=$(git rev-list --count "${BRANCH}..origin/${BRANCH}" 2>/dev/null || echo 0)
if [ "$BEHIND" -gt 0 ]; then
  log "WARN: 落後 origin $BEHIND 個 commit（可能在別台機器改過）→ 不自動 push，請手動處理"
  exit 1
fi

log "有 $AHEAD 個 commit 待 push → 開始"
if git push origin "$BRANCH" >>"$LOG" 2>&1; then
  log "OK: push 成功（$AHEAD commits）→ CF Pages 應該會自動 rebuild"
  # 需要 macOS 通知的話把下面這行取消註解
  # osascript -e "display notification \"push 了 $AHEAD 個 commit\" with title \"github-learn-log\""
else
  log "ERROR: push 失敗，詳見上方輸出"
  exit 1
fi
