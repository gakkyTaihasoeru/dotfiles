#!/bin/bash

set -euo pipefail

DRY_RUN=false

usage() {
  cat <<'EOF'
Usage: bash bin/setup.sh [--dry-run]

Apply macOS defaults managed by this repository.

Options:
  --dry-run  Show the commands without applying changes
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "${OSTYPE:-}" != darwin* ]]; then
  echo "This script only supports macOS." >&2
  exit 1
fi

run() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '[dry-run] %q' "$1"
    shift
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

restart_if_running() {
  local process="$1"
  if pgrep -x "$process" >/dev/null 2>&1; then
    run killall "$process"
  else
    echo "Skip restarting ${process}: not running"
  fi
}

# 拡張子を常に表示
run defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# ダークモード
run defaults write NSGlobalDomain AppleInterfaceStyle -string Dark

# Fnキーを標準のファンクションキーとして使用
run defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true

# 文頭の自動大文字化を無効
run defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# 設定を反映させるためにFinderとSystemUIServerを再起動
restart_if_running Finder
restart_if_running SystemUIServer
