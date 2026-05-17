#!/bin/bash
# PreToolUse hook: worker lane 環境では AskUserQuestion をブロック
# worker は lead agent に VP Mailbox (msg_send) で問い合わせる
#
# 旧 ccnav plugin の block-ask-in-worker.sh を統合・現行化:
# - worker 判定パスを vp_data_dir()/lanes/ (= `/vp/lanes/`) に追従
# - 廃止された ccwire (wire_send) → VP Mailbox (msg_send) に案内を更新

CURRENT_DIR=$(pwd)

# lane (worker 環境) 内のときだけブロック。lane データディレクトリは
# vp_data_dir()/lanes/ — macOS/Linux 共通で `/vp/lanes/` を含む。
if echo "$CURRENT_DIR" | grep -q "/vp/lanes/"; then
  cat <<'EOF'
{
  "decision": "block",
  "reason": "worker lane 環境では AskUserQuestion は使用できません。\n質問は lead agent に VP Mailbox で送信してください:\n  msg_send tool で宛先 \"agent@<project>\" (lead address) に問い合わせる。"
}
EOF
else
  echo '{}'
fi
