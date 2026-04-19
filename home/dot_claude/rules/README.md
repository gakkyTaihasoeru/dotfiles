# ~/.claude/rules/

Long-form personal rules that are too large for `~/.claude/CLAUDE.md`.

Keep `CLAUDE.md` under 200 lines (遵守率が下がるため). Split specific topics here
and reference from `CLAUDE.md` using `@rules/<file>.md` when the ruleset grows.

## Usage

```markdown
# in ~/.claude/CLAUDE.md
@rules/terraform-conventions.md
@rules/incident-response.md
```

## Current state

Empty — keep CLAUDE.md itself until it exceeds ~150 lines. Add topic-specific
files here only when justified by actual content volume.
