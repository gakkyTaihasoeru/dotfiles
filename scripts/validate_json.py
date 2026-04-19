#!/usr/bin/env python3

import json
import pathlib
import re
import sys


def strip_jsonc(text: str) -> str:
    stripped = "\n".join(
        line for line in text.splitlines() if not re.match(r"^\s*//", line)
    )
    return re.sub(r",(\s*[}\]])", r"\1", stripped)


def looks_like_vscode_settings(path: pathlib.Path) -> bool:
    parts = path.parts
    return path.name == "settings.json" and (
        "Code" in parts or "vscode" in parts or ".vscode" in parts
    )


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: validate_json.py <path>", file=sys.stderr)
        return 2

    path = pathlib.Path(sys.argv[1])
    text = path.read_text(encoding="utf-8")
    if looks_like_vscode_settings(path):
        text = strip_jsonc(text)
    json.loads(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
