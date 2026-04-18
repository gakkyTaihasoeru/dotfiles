#!/usr/bin/env python3
"""PreToolUse hook: block Read of sensitive files (credentials, private keys).

Input: JSON on stdin with tool_input.file_path.
Exit 0 = allow. Exit 2 = block (stderr shown to Claude).
"""
import json
import os
import re
import sys

SENSITIVE_PATTERNS = [
    re.compile(r"(?:^|/)\.env(?:\.[A-Za-z0-9_-]+)?$"),
    re.compile(r"(?:^|/)\.aws/credentials$"),
    re.compile(r"(?:^|/)\.aws/config$"),
    re.compile(r"(?:^|/)\.ssh/id_[^/.]+$"),
    re.compile(r"(?:^|/)\.ssh/[^/]*_rsa$"),
    re.compile(r"(?:^|/)\.ssh/[^/]*_ed25519$"),
    re.compile(r"(?:^|/)\.ssh/[^/]*_ecdsa$"),
    re.compile(r"(?:^|/)\.ssh/[^/]*_dsa$"),
    re.compile(r"(?:^|/)\.kube/config$"),
    re.compile(r"(?:^|/)\.netrc$"),
    re.compile(r"(?:^|/)\.npmrc$"),
    re.compile(r"(?:^|/)\.pypirc$"),
    re.compile(r"(?:^|/)\.dockercfg$"),
    re.compile(r"(?:^|/)\.docker/config\.json$"),
    re.compile(r"^/etc/shadow$"),
    re.compile(r"^/etc/gshadow$"),
    re.compile(r"^/etc/sudoers(?:\.d/.*)?$"),
    re.compile(r"(?:^|/)secrets?\.ya?ml$", re.IGNORECASE),
    re.compile(r"(?:^|/)[^/]*service[-_]account[^/]*\.json$", re.IGNORECASE),
]

ALLOW_PATTERNS = [
    re.compile(r"\.env\.(example|sample|template|dist)$", re.IGNORECASE),
    re.compile(r"\.pub$"),
    re.compile(r"sealed-?secret", re.IGNORECASE),
]


def main() -> None:
    try:
        event = json.load(sys.stdin)
    except Exception as e:
        print(f"sensitive-read: failed to parse hook input: {e}", file=sys.stderr)
        sys.exit(0)

    tool_input = event.get("tool_input") or {}
    path = tool_input.get("file_path", "") or ""
    if not path:
        sys.exit(0)

    norm = os.path.expanduser(path)

    for pat in ALLOW_PATTERNS:
        if pat.search(norm):
            sys.exit(0)

    for pat in SENSITIVE_PATTERNS:
        if pat.search(norm):
            print(
                f"sensitive-read: BLOCKED read of {path} — file may contain credentials "
                "or private keys.\nIf intentionally needed, ask the user to run the Bash "
                "command directly, or add a targeted permission in settings.local.json.",
                file=sys.stderr,
            )
            sys.exit(2)

    sys.exit(0)


if __name__ == "__main__":
    main()
