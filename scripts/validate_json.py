#!/usr/bin/env python3

import json
import pathlib
import re
import sys


def load_content(path: pathlib.Path) -> str:
    text = path.read_text(encoding="utf-8")
    is_jsonc = path.parts[:1] in [("vscode",), (".vscode",)]
    if not is_jsonc:
        return text

    return "\n".join(
        line for line in text.splitlines() if not re.match(r"^\s*//", line)
    )


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: validate_json.py <path>", file=sys.stderr)
        return 2

    path = pathlib.Path(sys.argv[1])
    json.loads(load_content(path))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
