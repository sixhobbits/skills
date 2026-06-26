# rename-session

A Claude Code skill that lets the agent rename its own session — the programmatic equivalent of the user typing `/rename <name>`.

## Why

`/rename` is a slash command only the user can type; the agent has no tool for it. This skill closes that gap by replicating `/rename`'s durable effect.

## Usage

```bash
node scripts/claude-rename.js "my-session-name"          # current session
node scripts/claude-rename.js "my-session-name" <uuid>   # a specific session
```

Node only, standard library — no npm install, no Python, no shell. Runs on macOS, Linux, and native Windows, since Node ships with Claude Code.

Without a session id it uses `$CLAUDE_SESSION_ID`, falling back to the most recently modified transcript.

## Mechanism

The session name persists as a `system`/`local_command` event in the transcript jsonl:

```
<local-command-stdout>Session renamed to: NAME</local-command-stdout>
```

`/resume` reads the last such line. The script appends one matching event. The pid registry file is owned and rewritten by the live CLI process, so external edits there don't persist — the transcript event is the real store. The single-line append is atomic under POSIX (write < 4 KB), so it's safe alongside the CLI's own writes.

The name shows in `/resume` immediately; the live terminal header updates on reload.
