#!/bin/bash
# PreToolUse hook: performer lane 環境では AskUserQuestion をブロック
# performer は conductor agent に wiremsg (wire_send) で問い合わせる
#
# 旧 ccnav plugin の block-ask-in-worker.sh を統合・現行化:
# - performer 判定パスを vp_data_dir()/lanes/ (= `/vp/lanes/`) に追従
# - ccwire / msgbox は廃止、 wiremsg (wire_send) に一本化済み

CURRENT_DIR=$(pwd)

# lane (performer 環境) 内のときだけブロック。lane データディレクトリは
# vp_data_dir()/lanes/ — macOS/Linux 共通で `/vp/lanes/` を含む。
if echo "$CURRENT_DIR" | grep -q "/vp/lanes/"; then
  cat <<'EOF'
{
  "decision": "block",
  "reason": "performer lane 環境では AskUserQuestion は使用できません。\n質問は conductor agent に wiremsg で送信してください:\n  mcp__vantage-point__wire_send で宛先 \"agent@<project>\" (conductor address) に問い合わせる。"
}
EOF
else
  echo '{}'
fi
