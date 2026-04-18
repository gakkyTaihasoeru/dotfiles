#!/usr/bin/env python3
"""PreToolUse / BeforeTool hook: block writes that contain secrets.

Shared by Claude Code (Write/Edit/MultiEdit/NotebookEdit) and
Gemini CLI (write_file/replace). Input: JSON on stdin with tool_name +
tool_input. Exit 0 = allow. Exit 2 = block (stderr shown to the agent).
"""
import json
import re
import sys

PATTERNS = [
    ("AWS Access Key ID", re.compile(r"\bAKIA[0-9A-Z]{16}\b")),
    ("AWS Session Token ID", re.compile(r"\bASIA[0-9A-Z]{16}\b")),
    ("PEM private key", re.compile(
        r"-----BEGIN (?:RSA |EC |DSA |OPENSSH |ENCRYPTED |PGP |)PRIVATE KEY-----")),
    ("GCP service account JSON", re.compile(
        r'"type"\s*:\s*"service_account"', re.IGNORECASE)),
    ("GitHub personal token", re.compile(r"\bghp_[A-Za-z0-9]{36}\b")),
    ("GitHub OAuth token", re.compile(r"\bgho_[A-Za-z0-9]{36}\b")),
    ("GitHub app token", re.compile(r"\bghs_[A-Za-z0-9]{36}\b")),
    ("GitHub fine-grained PAT", re.compile(r"\bgithub_pat_[A-Za-z0-9_]{82}\b")),
    ("Slack token", re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{10,}\b")),
    ("Google API key", re.compile(r"\bAIza[0-9A-Za-z_\-]{35}\b")),
    ("Stripe live secret key", re.compile(r"\bsk_live_[0-9a-zA-Z]{20,}\b")),
    ("JWT", re.compile(r"\beyJ[A-Za-z0-9_\-]{10,}\.eyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}\b")),
    ("Anthropic API key", re.compile(r"\bsk-ant-[A-Za-z0-9_\-]{20,}\b")),
]

PLACEHOLDER_MARKERS = ("example", "dummy", "fake", "placeholder", "xxxxxxxx", "redacted")


def is_obvious_placeholder(match_text: str) -> bool:
    lowered = match_text.lower()
    return any(m in lowered for m in PLACEHOLDER_MARKERS)


def extract_content(event: dict) -> str:
    tool_name = event.get("tool_name", "")
    tool_input = event.get("tool_input") or {}
    # Claude Code tool names
    if tool_name == "Write":
        return tool_input.get("content", "") or ""
    if tool_name == "Edit":
        return tool_input.get("new_string", "") or ""
    if tool_name == "MultiEdit":
        edits = tool_input.get("edits") or []
        return "\n".join((e.get("new_string") or "") for e in edits)
    if tool_name == "NotebookEdit":
        return tool_input.get("new_source", "") or ""
    # Gemini CLI tool names (write_file = Write, replace = Edit)
    if tool_name == "write_file":
        return tool_input.get("content", "") or ""
    if tool_name == "replace":
        return tool_input.get("new_string", "") or ""
    return ""


def main() -> None:
    try:
        event = json.load(sys.stdin)
    except Exception as e:
        print(f"secret-scan: failed to parse hook input: {e}", file=sys.stderr)
        sys.exit(0)

    content = extract_content(event)
    if not content:
        sys.exit(0)

    hits = []
    for name, pattern in PATTERNS:
        for m in pattern.finditer(content):
            if is_obvious_placeholder(m.group(0)):
                continue
            hits.append(name)
            break

    if hits:
        path = (event.get("tool_input") or {}).get("file_path", "<unknown>")
        print(
            f"secret-scan: BLOCKED write to {path} — detected: {', '.join(hits)}.\n"
            "Move the value to a secret store (1Password, Vault, AWS SSM, K8s Secret) "
            "and reference it via env var or secret manager.\n"
            "If this is a test fixture, include 'EXAMPLE' or 'DUMMY' in the value to bypass.",
            file=sys.stderr,
        )
        sys.exit(2)

    sys.exit(0)


if __name__ == "__main__":
    main()
