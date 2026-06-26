#!/bin/sh
# Rename a Claude Code session the way /rename does — durably, no deps.
#
# Usage: claude-rename.sh <new-name> [session-id]
#
# Omit session-id to target the current session: uses $CLAUDE_SESSION_ID,
# else the most recently modified transcript.
#
# /rename's durable effect is one system/local_command event appended to the
# session transcript (~/.claude/projects/<encoded-cwd>/<id>.jsonl):
#   <local-command-stdout>Session renamed to: NAME</local-command-stdout>
# /resume reads the last such line as the name. The transcript IS the session,
# so only that line matters; the sessionId is taken from the filename. The pid
# registry file is owned/rewritten by the live CLI, so editing it doesn't stick.
set -eu

name=${1:-}
[ -n "$name" ] || { echo "usage: claude-rename.sh <new-name> [session-id]" >&2; exit 1; }
sid=${2:-${CLAUDE_SESSION_ID:-}}

base="$HOME/.claude/projects"

find_transcript() {
  if [ -n "$sid" ]; then
    set -- "$base"/*/"$sid".jsonl
    [ -f "$1" ] && { printf '%s\n' "$1"; return; }
    echo "no transcript found for session $sid" >&2; exit 1
  fi
  # most recently modified transcript
  ls -t "$base"/*/*.jsonl 2>/dev/null | head -1
}

path=$(find_transcript)
[ -n "$path" ] && [ -f "$path" ] || { echo "no transcripts found" >&2; exit 1; }

fname=$(basename "$path")
session_id=${fname%.jsonl}

# UUID, with fallbacks
if command -v uuidgen >/dev/null 2>&1; then
  uuid=$(uuidgen | tr 'A-Z' 'a-z')
elif [ -r /proc/sys/kernel/random/uuid ]; then
  uuid=$(cat /proc/sys/kernel/random/uuid)
else
  uuid=$(date -u +%s)-$$
fi

# ISO-8601 timestamp (millis are cosmetic; .000Z is portable across date impls)
ts=$(date -u +%Y-%m-%dT%H:%M:%S).000Z

# Escape the name for JSON (backslash and double-quote)
esc=$(printf '%s' "$name" | sed 's/\\/\\\\/g; s/"/\\"/g')

printf '{"type":"system","subtype":"local_command","content":"<local-command-stdout>Session renamed to: %s</local-command-stdout>","level":"info","timestamp":"%s","uuid":"%s","isMeta":false,"userType":"external","entrypoint":"cli","sessionId":"%s"}\n' \
  "$esc" "$ts" "$uuid" "$session_id" >> "$path"

echo "Session renamed to: $name"
echo "  transcript: $path"
echo "  (visible in /resume; live UI updates on reload)"
