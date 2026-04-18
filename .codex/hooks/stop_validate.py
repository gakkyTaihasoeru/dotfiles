#!/usr/bin/env python3

from __future__ import annotations

import json
import subprocess
import sys


def respond(payload: dict) -> int:
    print(json.dumps(payload, ensure_ascii=False))
    return 0


def main() -> int:
    try:
        event = json.load(sys.stdin)
    except json.JSONDecodeError:
        return respond({"continue": True})

    if event.get("stop_hook_active"):
        return respond({"continue": True})

    proc = subprocess.run(
        ["bash", "bin/check.sh"],
        capture_output=True,
        text=True,
    )

    if proc.returncode == 0:
        return respond({"continue": True})

    output = (proc.stdout + "\n" + proc.stderr).strip()
    output = "\n".join(output.splitlines()[-20:])
    return respond(
        {
            "decision": "block",
            "reason": "Repository checks failed in dotfiles. Fix the issues before finishing.",
            "systemMessage": output,
        }
    )


if __name__ == "__main__":
    raise SystemExit(main())
