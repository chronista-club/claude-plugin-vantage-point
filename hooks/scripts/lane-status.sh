#!/bin/bash
# SessionStart hook: VP lane (作業台) の状態をセッション開始時にコンテキスト注入
# vp CLI が使えない場合は静かに終了する
#
# 語彙は VP v0.56 命名エピック後に準拠 (lane = 作業台、repo = 場、agent = engine)。
# lane 配置は project-local `<repo>/.vp/lanes/` (VP 本体 lane/config.rs の
# `project_lanes_dir()` が SSOT)。

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

# 現在のディレクトリが lane 内かどうか判定
CURRENT_DIR=$(pwd)
IN_LANE=""
if echo "$CURRENT_DIR" | grep -q "/\.vp/lanes/"; then
  IN_LANE="true"
fi

# コンテキストを構築
if [ -n "$IN_LANE" ]; then
  CONTEXT="## VP Lane 環境\n\n現在 lane (作業台) 内で作業中です。\nパス: ${CURRENT_DIR}\n\n### この repo の lane 一覧\n\`\`\`\n${LANE_LIST}\n\`\`\`\n\nlane address は \`<repo>/root\` / \`<repo>/<name>\` (v0.56+ で \`/performer/\` は撤去)。\n管理: vp lane ls --detail / vp lane rm <name> / vp lane status"
else
  CONTEXT="## VP Lane 環境\n\nアクティブな lane があります。\n\n### lane 一覧\n\`\`\`\n${LANE_LIST}\n\`\`\`\n\nlane address は \`<repo>/root\` / \`<repo>/<name>\` (v0.56+ で \`/performer/\` は撤去)。\n管理: vp lane ls --detail / vp lane new <name> <branch> / vp lane rm <name>"
fi

cat <<EOF
{
  "additionalContext": "${CONTEXT}"
}
EOF
