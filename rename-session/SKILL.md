---
name: rename-session
description: "Rename the current Claude Code session from within the agent, the same way the user's /rename slash command does. Use when asked to name, rename, or retitle this session, or to set the label shown in the /resume picker."
---

# Rename Session

Lets the agent rename its own Claude Code session — the equivalent of the user typing `/rename <name>`, but runnable as a tool call.

## How to Use

Run the script with the new name:

```bash
scripts/claude-rename.py "<new-name>" [session-id]
```

- Omit `session-id` to target the current session. The script uses `$CLAUDE_SESSION_ID` if set, otherwise the most recently modified transcript.
- The name appears in the `/resume` picker immediately. The live terminal header updates on reload.

## How It Works

`/rename`'s durable effect is a single `system` / `local_command` event appended to the session transcript (`~/.claude/projects/<encoded-cwd>/<session-id>.jsonl`):

```
<local-command-stdout>Session renamed to: NAME</local-command-stdout>
```

The `/resume` picker reads the last such line as the session name (last-one-wins). The script appends exactly this event with a fresh UUID, current timestamp, and the transcript's own `sessionId` / `cwd` / `version` / `gitBranch`, chaining `parentUuid` to the previous record.

The pid registry (`~/.claude/sessions/<pid>.json`) holds a `name` field only while the process runs, and the CLI rewrites that file from its own in-memory state — so writing it externally does not stick. The transcript event is the source of truth, which is why this approach is reliable.

POSIX guarantees atomic appends for a single write under PIPE_BUF (4 KB), so appending the one-line event is safe even while the CLI is concurrently appending to the same transcript.
