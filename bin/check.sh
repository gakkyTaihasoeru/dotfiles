#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

choose_python() {
  local candidates=()
  local path=""

  if command -v python3 >/dev/null 2>&1; then
    candidates+=("$(command -v python3)")
  fi

  if [[ -x /opt/homebrew/bin/python3 ]]; then
    candidates+=("/opt/homebrew/bin/python3")
  fi

  for path in "$HOME"/.local/share/mise/installs/python/*/bin/python3; do
    [[ -x "$path" ]] && candidates+=("$path")
  done

  for path in "${candidates[@]}"; do
    if "$path" -c 'import tomllib' >/dev/null 2>&1; then
      echo "$path"
      return 0
    fi
  done

  if command -v python3 >/dev/null 2>&1; then
    echo "$(command -v python3)"
    return 0
  fi

  echo "python3 not found" >&2
  return 1
}

PYTHON_BIN="$(choose_python)"

have_python_yaml() {
  "$PYTHON_BIN" -c 'import yaml' >/dev/null 2>&1
}

validate_json() {
  while IFS= read -r -d '' f; do
    echo "JSON  $f"
    "$PYTHON_BIN" ./scripts/validate_json.py "$f"
  done < <(find . -name '*.json' -not -path './.git/*' -not -path './node_modules/*' -print0)
}

validate_toml() {
  while IFS= read -r -d '' f; do
    echo "TOML  $f"
    "$PYTHON_BIN" ./scripts/validate_toml.py "$f"
  done < <(find . -name '*.toml' -not -path './.git/*' -not -path './node_modules/*' -print0)
}

validate_yaml() {
  while IFS= read -r -d '' f; do
    echo "YAML  $f"
    if have_python_yaml; then
      "$PYTHON_BIN" ./scripts/validate_yaml.py "$f"
    else
      ruby -e 'require "yaml"; YAML.safe_load(File.read(ARGV[0]), aliases: true);' "$f" >/dev/null
    fi
  done < <(find . \( -name '*.yml' -o -name '*.yaml' \) -not -path './.git/*' -not -path './node_modules/*' -print0)
}

validate_shell_syntax() {
  while IFS= read -r -d '' f; do
    echo "SH    $f"
    bash -n "$f"
  done < <(find ./bin -type f -name '*.sh' -print0)
}

validate_brewfiles() {
  local f

  if ! command -v brew >/dev/null 2>&1; then
    echo "WARN  brew not found; skipping Brewfile validation"
    return 0
  fi

  for f in ./Brewfile ./Brewfile.local.example ./Brewfile.local; do
    if [[ -f "$f" ]]; then
      echo "BREW  $f"
      brew bundle list --file="$f" >/dev/null
    fi
  done
}

run_shellcheck_if_available() {
  if ! command -v shellcheck >/dev/null 2>&1; then
    echo "WARN  shellcheck not found; skipping"
    return 0
  fi

  while IFS= read -r -d '' f; do
    echo "SC    $f"
    shellcheck "$f"
  done < <(find ./bin -type f -name '*.sh' -print0)
}

validate_chezmoi_apply() {
  if ! command -v chezmoi >/dev/null 2>&1; then
    echo "WARN  chezmoi not found; skipping chezmoi dry-run"
    return 0
  fi

  local tmp_home
  tmp_home="$(mktemp -d)"
  trap 'rm -rf "$tmp_home"' RETURN

  echo "CHEZ  chezmoi apply --dry-run (destination=$tmp_home)"
  chezmoi apply --dry-run \
    --source "${REPO_ROOT}/home" \
    --destination "$tmp_home" >/dev/null
}

validate_json
validate_toml
validate_yaml
validate_shell_syntax
validate_brewfiles
run_shellcheck_if_available
validate_chezmoi_apply

echo "OK    repository checks passed"
