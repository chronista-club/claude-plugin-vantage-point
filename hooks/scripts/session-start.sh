#!/bin/bash
# Vantage Point: Lightweight session start context injection
# Replaces the previous type: "prompt" hook to avoid consuming agent context

# Git context
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "N/A")
REPO=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || basename "$(pwd)")

cat <<EOF
{
  "additionalContext": "Vantage Point ダッシュボードが利用可能です。\`/vantage-point:dashboard\` で初期化できます。\nContext: ${REPO} (${BRANCH})"
}
EOF
