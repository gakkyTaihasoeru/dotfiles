#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DRY_RUN=false
RUN_BREW=false
RUN_MISE=false

usage() {
  cat <<EOF
Usage: bash bin/install.sh [--dry-run] [--brew] [--mise]

Bootstrap this dotfiles repository on macOS via chezmoi.

The script is intentionally thin. It only handles steps that cannot be expressed
as chezmoi state:

  1. Install Homebrew if missing (chezmoi itself depends on it)
  2. Install chezmoi if missing
  3. Write a minimal bootstrap ~/.config/chezmoi/chezmoi.toml on first run
  4. Run \`chezmoi apply\` (which then manages ~/.config/chezmoi/chezmoi.toml itself)

Brewfile sync and \`mise install\` stay opt-in because they are slow and the
user controls when to reconcile them.

Options:
  --dry-run  Print the chezmoi commands without applying changes
  --brew     Also run \`brew bundle\` against ./Brewfile after apply
  --mise     Also run \`mise install\` after apply
  -h, --help Show this help
EOF
}

run() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --brew)
      RUN_BREW=true
      shift
      ;;
    --mise)
      RUN_MISE=true
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

if [[ ! -x /opt/homebrew/bin/brew ]]; then
  echo "==> Installing Homebrew"
  if [[ "$DRY_RUN" == true ]]; then
    echo '[dry-run] /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  else
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

if ! command -v chezmoi >/dev/null 2>&1; then
  echo "==> Installing chezmoi"
  run brew install chezmoi
fi

CHEZMOI_CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/chezmoi"
CHEZMOI_CONFIG_FILE="${CHEZMOI_CONFIG_DIR}/chezmoi.toml"
EXPECTED_SOURCEDIR_LINE="sourceDir = \"${REPO_ROOT}\""

write_bootstrap_chezmoi_config() {
  cat <<EOF
sourceDir = "${REPO_ROOT}"

[data.git]
name = "gakkyTaihasoeru"
email = "gakky.taihasoeru@gmail.com"
signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPEdA62Ic8Ss32IkYxOCLM0bpJ5CxzFXNKn1zOSQ3MgO"

[data.paths]
ghqRoot = "${HOME}/work/ghq"

[diff]
pager = "delta"

[edit]
command = "nvim"
EOF
}

if [[ -f "$CHEZMOI_CONFIG_FILE" ]] && ! grep -Fq "$EXPECTED_SOURCEDIR_LINE" "$CHEZMOI_CONFIG_FILE" 2>/dev/null; then
  echo "Existing ${CHEZMOI_CONFIG_FILE} points to a different sourceDir." >&2
  echo "Refusing to overwrite unrelated chezmoi state." >&2
  echo "Expected: ${EXPECTED_SOURCEDIR_LINE}" >&2
  exit 1
fi

if [[ ! -f "$CHEZMOI_CONFIG_FILE" ]]; then
  echo "==> Writing ${CHEZMOI_CONFIG_FILE}"
  if [[ "$DRY_RUN" == true ]]; then
    echo "[dry-run] mkdir -p ${CHEZMOI_CONFIG_DIR}"
    echo "[dry-run] write bootstrap chezmoi config to ${CHEZMOI_CONFIG_FILE}"
  else
    mkdir -p "$CHEZMOI_CONFIG_DIR"
    write_bootstrap_chezmoi_config >"$CHEZMOI_CONFIG_FILE"
  fi
fi

echo "==> chezmoi apply"
if [[ "$DRY_RUN" == true ]]; then
  run chezmoi apply --dry-run --verbose
else
  run chezmoi apply --verbose
fi

if [[ "$RUN_BREW" == true ]]; then
  echo "==> brew bundle"
  run bash "${REPO_ROOT}/bin/brew-bundle.sh" install
fi

if [[ "$RUN_MISE" == true ]]; then
  echo "==> mise install"
  if ! command -v mise >/dev/null 2>&1; then
    echo "mise not found; install with --brew first or add it manually." >&2
    exit 1
  fi
  run mise install
fi

cat <<'EOF'

Bootstrap complete. Restart your shell to apply the new configuration:
  exec zsh
EOF
