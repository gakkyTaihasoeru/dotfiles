#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<EOF
Usage: bash bin/install.sh [--skip-brew] [--skip-mise] [--skip-macos]

Bootstrap this dotfiles repository on macOS.

Options:
  --skip-brew   Skip \`brew bundle --file=Brewfile\`
  --skip-mise   Skip \`mise install\`
  --skip-macos  Skip \`bin/setup.sh\`
  -h, --help    Show this help
EOF
}

SKIP_BREW=false
SKIP_MISE=false
SKIP_MACOS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-brew)
      SKIP_BREW=true
      shift
      ;;
    --skip-mise)
      SKIP_MISE=true
      shift
      ;;
    --skip-macos)
      SKIP_MACOS=true
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
  echo "This installer currently supports macOS only." >&2
  exit 1
fi

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Required command not found: $cmd" >&2
    exit 1
  fi
}

link_file() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
  echo "Linked: $dst -> $src"
}

if [[ "$SKIP_BREW" == false ]]; then
  require_cmd brew
  brew bundle --file="${REPO_ROOT}/Brewfile"
fi

if [[ "$SKIP_MISE" == false ]]; then
  require_cmd mise
  mise install
fi

if [[ "$SKIP_MACOS" == false ]]; then
  bash "${REPO_ROOT}/bin/setup.sh"
fi

link_file "${REPO_ROOT}/zsh/.zshrc" "${HOME}/.zshrc"
link_file "${REPO_ROOT}/git/.gitconfig" "${HOME}/.gitconfig"
link_file "${REPO_ROOT}/dotconfig/ghostty/config" "${HOME}/.config/ghostty/config"
link_file "${REPO_ROOT}/dotconfig/mise/config.toml" "${HOME}/.config/mise/config.toml"
link_file "${REPO_ROOT}/vscode/settings.json" "${HOME}/Library/Application Support/Code/User/settings.json"

cat <<'EOF'

Installation steps completed.
Restart your shell to apply the new configuration:
  exec zsh
EOF
