#!/usr/bin/env python3

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


DIRECT_BLOCK_PATTERNS = [
    re.compile(r"\bbrew\s+bundle\b[^\n]*\s--cleanup\b"),
    re.compile(r"\bbrew\s+bundle\s+cleanup\b[^\n]*\s--force\b"),
    re.compile(r"\bbash\s+bin/brew-bundle\.sh\s+cleanup\b[^\n]*\s--apply\b"),
    re.compile(r"\bmise\s+run\s+brew-reconcile-apply\b"),
]

TASK_COMMAND_PATTERNS = [
    re.compile(r"\bmise\s+run\s+maintenance\b"),
    re.compile(r"\bmise\s+run\s+brew-update\b"),
]

OVERRIDE_ENV_PATTERN = re.compile(r"\bCODEX_ALLOW_BREW_RECONCILE=1\b")
TASK_NAME_PATTERN = re.compile(r"\bmise\s+run\s+([A-Za-z0-9._-]+)\b")
TASK_HEADER_PATTERN = re.compile(r"^\[tasks\.([A-Za-z0-9._-]+)\]\s*$")
QUOTED_STRING_PATTERN = re.compile(r'"([^"]+)"')


def respond(payload: dict) -> int:
    print(json.dumps(payload, ensure_ascii=False))
    return 0


def allow() -> int:
    return respond({"continue": True})


def block(reason: str) -> int:
    return respond(
        {
            "decision": "block",
            "reason": reason,
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            },
        }
    )


def load_event() -> dict | None:
    try:
        return json.load(sys.stdin)
    except json.JSONDecodeError:
        return None


def is_directly_dangerous(command: str) -> bool:
    return any(pattern.search(command) for pattern in DIRECT_BLOCK_PATTERNS)


def is_task_command(command: str) -> bool:
    return any(pattern.search(command) for pattern in TASK_COMMAND_PATTERNS)


def extract_task_name(command: str) -> str | None:
    match = TASK_NAME_PATTERN.search(command)
    if not match:
        return None
    return match.group(1)


def parse_task_blocks(text: str) -> dict[str, list[str]]:
    blocks: dict[str, list[str]] = {}
    current_task: str | None = None

    for line in text.splitlines():
        match = TASK_HEADER_PATTERN.match(line.strip())
        if match:
            current_task = match.group(1)
            blocks[current_task] = []
            continue

        if current_task is not None:
            blocks[current_task].append(line)

    return blocks


def parse_array_values(block_lines: list[str], key: str) -> list[str]:
    values: list[str] = []
    collecting = False

    for line in block_lines:
        stripped = line.strip()

        if not collecting:
            if not stripped.startswith(f"{key} ="):
                continue
            if "[" not in stripped:
                continue
            collecting = True

        values.extend(QUOTED_STRING_PATTERN.findall(stripped))

        if "]" in stripped:
            break

    return values


def task_tree_is_dangerous(task_name: str, blocks: dict[str, list[str]], seen: set[str] | None = None) -> bool:
    if seen is None:
        seen = set()

    if task_name in seen:
        return False

    seen.add(task_name)
    block = blocks.get(task_name)
    if block is None:
        return False

    run_commands = parse_array_values(block, "run")
    if any(is_directly_dangerous(cmd) for cmd in run_commands):
        return True

    for dependency in parse_array_values(block, "depends"):
        if task_tree_is_dangerous(dependency, blocks, seen):
            return True

    return False


def mise_task_is_dangerous(cwd: str, command: str) -> bool:
    task_name = extract_task_name(command)
    if not task_name:
        return False

    mise_toml = Path(cwd) / "mise.toml"
    if not mise_toml.is_file():
        return False

    try:
        text = mise_toml.read_text(encoding="utf-8")
    except OSError:
        return False

    return task_tree_is_dangerous(task_name, parse_task_blocks(text))


def main() -> int:
    event = load_event()
    if not event:
        return allow()

    if event.get("hook_event_name") != "PreToolUse":
        return allow()

    if event.get("tool_name") != "Bash":
        return allow()

    tool_input = event.get("tool_input") or {}
    command = tool_input.get("command", "")
    cwd = event.get("cwd", "")

    if not command:
        return allow()

    if OVERRIDE_ENV_PATTERN.search(command):
        return allow()

    if is_directly_dangerous(command):
        return block(
            "Destructive Homebrew cleanup is blocked by repo hook. "
            "Use CODEX_ALLOW_BREW_RECONCILE=1 only when you intentionally want Brewfile-driven removals."
        )

    if is_task_command(command) and mise_task_is_dangerous(cwd, command):
        return block(
            "This mise task resolves to destructive Homebrew cleanup in the current repository. "
            "Fix mise.toml first, or rerun with CODEX_ALLOW_BREW_RECONCILE=1 if removal is intentional."
        )

    return allow()


if __name__ == "__main__":
    raise SystemExit(main())
