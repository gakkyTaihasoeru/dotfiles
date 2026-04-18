#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_BREWFILE="${REPO_ROOT}/Brewfile"
LOCAL_BREWFILE="${REPO_ROOT}/Brewfile.local"

usage() {
  cat <<'EOF'
Usage: bash bin/brew-bundle.sh <install|cleanup> [--apply]

install  Apply Brewfile and optional Brewfile.local
cleanup  Preview removals for items not present in Brewfile and optional Brewfile.local
         Pass --apply to perform the removal
EOF
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Required command not found: $cmd" >&2
    exit 1
  fi
}

have_local_brewfile() {
  [[ -f "$LOCAL_BREWFILE" ]]
}

install_brewfiles() {
  brew bundle --file="$BASE_BREWFILE"

  if have_local_brewfile; then
    brew bundle --file="$LOCAL_BREWFILE"
  fi
}

cleanup_brewfiles() {
  local apply="${1:-false}"
  local tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/dotfiles-brewfile.XXXXXX")"
  # shellcheck disable=SC2064 # expand $tmp now; the file is owned by this invocation
  trap "rm -f '$tmp'" EXIT

  cat "$BASE_BREWFILE" >"$tmp"

  if have_local_brewfile; then
    printf '\n' >>"$tmp"
    cat "$LOCAL_BREWFILE" >>"$tmp"
  fi

  if [[ "$apply" == "true" ]]; then
    brew bundle cleanup --file="$tmp" --force
    return 0
  fi

  set +e
  brew bundle cleanup --file="$tmp"
  status=$?
  set -e

  case "$status" in
    0)
      echo "No cleanup candidates."
      ;;
    1)
      echo "Cleanup preview completed. Re-run with 'bash bin/brew-bundle.sh cleanup --apply' to remove the listed items."
      ;;
    *)
      return "$status"
      ;;
  esac
}

main() {
  require_cmd brew

  case "${1:-}" in
    install)
      install_brewfiles
      ;;
    cleanup)
      case "${2:-}" in
        "")
          cleanup_brewfiles false
          ;;
        --apply)
          cleanup_brewfiles true
          ;;
        *)
          usage >&2
          exit 1
          ;;
      esac
      ;;
    -h | --help | help)
      usage
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
