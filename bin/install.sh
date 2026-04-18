#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DRY_RUN=false
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

usage() {
  cat <<EOF
Usage: bash bin/install.sh [--dry-run] [--skip-brew] [--skip-mise] [--skip-macos]

Bootstrap this dotfiles repository on macOS.

Options:
  --dry-run    Show the commands without applying changes
  --skip-brew   Skip applying Brewfile and optional Brewfile.local
  --skip-mise   Skip \`mise install\`
  --skip-macos  Skip \`bin/setup.sh\`
  -h, --help    Show this help
EOF
}

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

SKIP_BREW=false
SKIP_MISE=false
SKIP_MACOS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
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
    -h | --help)
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
  local backup_path=""
  local backup_label="Backed up"
  local link_label="Linked"

  run mkdir -p "$(dirname "$dst")"

  if [[ "$DRY_RUN" == true ]]; then
    backup_label="Would back up"
    link_label="Would link"
  fi

  if [[ -e "$dst" || -L "$dst" ]]; then
    if [[ -L "$dst" ]] && [[ "$(readlink "$dst")" == "$src" ]]; then
      echo "Already linked: $dst -> $src"
      return
    fi

    backup_path="${dst}${BACKUP_SUFFIX}"
    run mv "$dst" "$backup_path"
    echo "${backup_label}: $dst -> $backup_path"
  fi

  run ln -sfn "$src" "$dst"
  echo "${link_label}: $dst -> $src"
}

if [[ "$SKIP_BREW" == false ]]; then
  require_cmd brew
  run bash "${REPO_ROOT}/bin/brew-bundle.sh" install
fi

if [[ "$SKIP_MISE" == false ]]; then
  require_cmd mise
  run mise install
fi

if [[ "$SKIP_MACOS" == false ]]; then
  if [[ "$DRY_RUN" == true ]]; then
    run bash "${REPO_ROOT}/bin/setup.sh" --dry-run
  else
    run bash "${REPO_ROOT}/bin/setup.sh"
  fi
fi

# Shell (zsh)
link_file "${REPO_ROOT}/zsh/.zshrc" "${HOME}/.zshrc"
link_file "${REPO_ROOT}/zsh/.zshenv" "${HOME}/.zshenv"
link_file "${REPO_ROOT}/zsh/.zprofile" "${HOME}/.zprofile"

# Git
link_file "${REPO_ROOT}/git/.gitconfig" "${HOME}/.gitconfig"
link_file "${REPO_ROOT}/git/.gitignore_global" "${HOME}/.gitignore_global"

# Terminal / multiplexer
link_file "${REPO_ROOT}/dotconfig/ghostty/config" "${HOME}/.config/ghostty/config"
link_file "${REPO_ROOT}/tmux/.tmux.conf" "${HOME}/.tmux.conf"

# CLI tools
link_file "${REPO_ROOT}/dotconfig/mise/config.toml" "${HOME}/.config/mise/config.toml"
link_file "${REPO_ROOT}/dotconfig/atuin/config.toml" "${HOME}/.config/atuin/config.toml"
link_file "${REPO_ROOT}/dotconfig/bat/config" "${HOME}/.config/bat/config"

# Neovim
link_file "${REPO_ROOT}/dotconfig/nvim/init.lua" "${HOME}/.config/nvim/init.lua"
link_file "${REPO_ROOT}/dotconfig/nvim/lazy-lock.json" "${HOME}/.config/nvim/lazy-lock.json"

# VS Code
link_file "${REPO_ROOT}/vscode/settings.json" "${HOME}/Library/Application Support/Code/User/settings.json"

# AI agents: Claude Code
link_file "${REPO_ROOT}/claude/CLAUDE.md" "${HOME}/.claude/CLAUDE.md"
link_file "${REPO_ROOT}/claude/settings.json" "${HOME}/.claude/settings.json"
link_file "${REPO_ROOT}/claude/statusline.sh" "${HOME}/.claude/statusline.sh"
link_file "${REPO_ROOT}/claude/rules/README.md" "${HOME}/.claude/rules/README.md"
link_file "${REPO_ROOT}/claude/hooks/secret-scan.py" "${HOME}/.claude/hooks/secret-scan.py"
link_file "${REPO_ROOT}/claude/hooks/sensitive-read.py" "${HOME}/.claude/hooks/sensitive-read.py"

# AI agents: Gemini CLI
link_file "${REPO_ROOT}/gemini/GEMINI.md" "${HOME}/.gemini/GEMINI.md"
link_file "${REPO_ROOT}/gemini/settings.json" "${HOME}/.gemini/settings.json"
link_file "${REPO_ROOT}/gemini/policies/sre_policy.toml" "${HOME}/.gemini/policies/sre_policy.toml"

# AI agents: Codex CLI (global config)
link_file "${REPO_ROOT}/codex/AGENTS.md" "${HOME}/.codex/AGENTS.md"
link_file "${REPO_ROOT}/codex/config.toml" "${HOME}/.codex/config.toml"

cat <<'EOF'

Installation steps completed.
Restart your shell to apply the new configuration:
  exec zsh
EOF
