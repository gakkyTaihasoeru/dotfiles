#!/bin/bash
# Claude Code statusline: [model] context-bar PCT% $cost | 5h:X% 7d:X% | branch | dir
input=$(cat)

# 単一のjq呼び出しで全フィールドをタブ区切りで取得（効率化）
IFS=$'\t' read -r MODEL PCT COST FIVE_PCT WEEK_PCT CWD <<<"$(echo "$input" | jq -r '[
  (.model.display_name // "unknown"),
  ((.context_window.used_percentage // 0) | floor | tostring),
  (.session_cost_usd // .cost_usd // 0 | "$" + (. * 100 | round / 100 | tostring)),
  (.rate_limits.five_hour.used_percentage // "" | if . == "" then "" else (100 - (. | floor) | tostring) + "%" end),
  (.rate_limits.seven_day.used_percentage // "" | if . == "" then "" else (100 - (. | floor) | tostring) + "%" end),
  (.workspace.current_dir // .cwd // "")
] | @tsv')"

# コンテキストバー構築
BAR_WIDTH=10
FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && printf -v FILL "%${FILLED}s" && BAR="${FILL// /▓}"
[ "$EMPTY" -gt 0 ] && printf -v PAD "%${EMPTY}s" && BAR="${BAR}${PAD// /░}"

# レート制限セクション構築
RATE=""
[ -n "$FIVE_PCT" ] && RATE="5h:${FIVE_PCT}"
[ -n "$WEEK_PCT" ] && RATE="${RATE:+$RATE }7d:${WEEK_PCT}"
[ -n "$RATE" ] && RATE="| ${RATE} "

# Gitブランチ取得（オプションロックをスキップ）
BRANCH=""
if [ -n "$CWD" ] && [ -d "$CWD" ]; then
  BRANCH=$(GIT_OPTIONAL_LOCKS=0 git -C "$CWD" symbolic-ref --short HEAD 2>/dev/null \
    || GIT_OPTIONAL_LOCKS=0 git -C "$CWD" rev-parse --short HEAD 2>/dev/null)
fi
[ -n "$BRANCH" ] && BRANCH="| ${BRANCH} "

# カレントディレクトリ（ホームディレクトリを~に短縮）
DIR=""
if [ -n "$CWD" ]; then
  HOME_ESC="${HOME%/}"
  DIR="${CWD/#$HOME_ESC/\~}"
  DIR="| ${DIR}"
fi

echo "[$MODEL] $BAR ${PCT}% ${COST} ${RATE}${BRANCH}${DIR}"
