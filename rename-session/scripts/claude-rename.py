#!/usr/bin/env python3
"""Rename a Claude Code session the way /rename does — durably.

Usage:
    claude-rename <new-name> [session-id]

If session-id is omitted, uses $CLAUDE_SESSION_ID, else the most recently
modified session transcript.

Mechanism: /rename's durable effect is a single system/local_command event
appended to the session's <uuid>.jsonl transcript:
    <local-command-stdout>Session renamed to: NAME</local-command-stdout>
The /resume picker reads the LAST such line as the session name. The live
pid registry (~/.claude/sessions/<pid>.json) holds "name" only while the
process runs and is rewritten by the CLI from its own state, so writing it
externally does not stick — the transcript event is the source of truth.
"""
import json, os, sys, glob, uuid, datetime

def die(msg):
    print(msg, file=sys.stderr); sys.exit(1)

def find_transcript(session_id):
    base = os.path.expanduser("~/.claude/projects")
    if session_id:
        hits = glob.glob(f"{base}/*/{session_id}.jsonl")
        if not hits:
            die(f"no transcript found for session {session_id}")
        return hits[0]
    sid = os.environ.get("CLAUDE_SESSION_ID")
    if sid:
        hits = glob.glob(f"{base}/*/{sid}.jsonl")
        if hits:
            return hits[0]
    # fallback: most recently modified transcript
    all_t = glob.glob(f"{base}/*/*.jsonl")
    if not all_t:
        die("no transcripts found")
    return max(all_t, key=os.path.getmtime)

def last_record(path):
    last = None
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    last = json.loads(line)
                except json.JSONDecodeError:
                    pass
    return last or {}

def main():
    if len(sys.argv) < 2:
        die("usage: claude-rename <new-name> [session-id]")
    name = sys.argv[1]
    session_id = sys.argv[2] if len(sys.argv) > 2 else None

    path = find_transcript(session_id)
    sid = os.path.basename(path)[:-len(".jsonl")]
    prev = last_record(path)

    rec = {
        "parentUuid": prev.get("uuid"),
        "isSidechain": False,
        "type": "system",
        "subtype": "local_command",
        "content": f"<local-command-stdout>Session renamed to: {name}</local-command-stdout>",
        "level": "info",
        "timestamp": datetime.datetime.now(datetime.timezone.utc)
            .strftime("%Y-%m-%dT%H:%M:%S.") +
            f"{datetime.datetime.now(datetime.timezone.utc).microsecond//1000:03d}Z",
        "uuid": str(uuid.uuid4()),
        "isMeta": False,
        "userType": "external",
        "entrypoint": prev.get("entrypoint", "cli"),
        "cwd": prev.get("cwd", os.getcwd()),
        "sessionId": sid,
        "version": prev.get("version", ""),
        "gitBranch": prev.get("gitBranch", ""),
    }

    # POSIX guarantees atomic append for a single write < PIPE_BUF (4KB),
    # so this is safe even while the CLI is appending to the same file.
    with open(path, "a") as f:
        f.write(json.dumps(rec) + "\n")

    print(f"Session renamed to: {name}")
    print(f"  transcript: {path}")
    print("  (visible in /resume; live UI updates on reload)")

if __name__ == "__main__":
    main()
