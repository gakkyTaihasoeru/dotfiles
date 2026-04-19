#!/bin/bash
# Apply Docker daemon.json template into ~/.docker/daemon.json with backup.
# Docker Desktop GUI can overwrite this file, so symlinking is unsafe.
# Run this manually after updating the template and restart Docker Desktop.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="${REPO_ROOT}/dotconfig/docker/daemon.json"
TARGET="${HOME}/.docker/daemon.json"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "Template not found: $TEMPLATE" >&2
  exit 1
fi

mkdir -p "$(dirname "$TARGET")"

if [[ -f "$TARGET" ]]; then
  if diff -q "$TEMPLATE" "$TARGET" >/dev/null 2>&1; then
    echo "Already in sync: $TARGET"
    exit 0
  fi
  echo "--- diff (current -> template) ---"
  diff -u "$TARGET" "$TEMPLATE" || true
  echo "----------------------------------"
  read -r -p "Overwrite $TARGET? [y/N] " answer
  case "$answer" in
    y | Y) ;;
    *)
      echo "Aborted."
      exit 1
      ;;
  esac
  backup="${TARGET}.bak.$(date +%Y%m%d%H%M%S)"
  cp "$TARGET" "$backup"
  echo "Backed up: $backup"
fi

cp "$TEMPLATE" "$TARGET"
echo "Applied: $TARGET"
echo "Restart Docker Desktop and recreate containers to pick up logging changes."
