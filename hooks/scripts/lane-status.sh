#!/bin/bash
# SessionStart hook: VP lane (worker 環境) の状態をセッション開始時にコンテキスト注入
# vp CLI が使えない場合は静かに終了する
#
# 旧 ccnav plugin の session-start.sh を統合・現行化 (ccws → vp lane、 ccwire → wiremsg)。

set -euo pipefail

# vp コマンドの存在チェック
if ! command -v vp &>/dev/null; then
  exit 0
fi

# lane 一覧を取得
LANE_LIST=$(vp lane ls 2>/dev/null || echo "")

# lane が 0 件なら何もしない
if [ -z "$LANE_LIST" ]; then
  exit 0
fi

# 現在のディレクトリが lane (worker 環境) 内かどうか判定
# lane データディレクトリは vp_data_dir()/lanes/ — macOS/Linux 共通で `/vp/lanes/` を含む
CURRENT_DIR=$(pwd)
IN_LANE=""
if echo "$CURRENT_DIR" | grep -q "/vp/lanes/"; then
  IN_LANE="true"
fi

# コンテキストを構築
if [ -n "$IN_LANE" ]; then
  CONTEXT="## VP Lane 環境\n\n現在 worker lane 内で作業中です。\nパス: ${CURRENT_DIR}\n\n### 全 lane 一覧\n\`\`\`\n${LANE_LIST}\n\`\`\`\n\nlane の管理: vp lane ls / vp lane rm <name>"
else
  CONTEXT="## VP Lane 環境\n\nアクティブな lane があります。\n\n### lane 一覧\n\`\`\`\n${LANE_LIST}\n\`\`\`\n\nlane の管理: vp lane ls / vp lane new <name> <branch> / vp lane rm <name>"
fi

cat <<EOF
{
  "additionalContext": "${CONTEXT}"
}
EOF
