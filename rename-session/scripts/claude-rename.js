#!/usr/bin/env node
// Rename a Claude Code session the way /rename does — durably, cross-platform.
//
// Usage: node claude-rename.js <new-name> [session-id]
//
// Omit session-id to target the current session: uses $CLAUDE_SESSION_ID,
// else the most recently modified transcript.
//
// /rename's durable effect is one system/local_command event appended to the
// session transcript (<claude-home>/projects/<encoded-cwd>/<id>.jsonl):
//   <local-command-stdout>Session renamed to: NAME</local-command-stdout>
// /resume reads the last such line as the name. The transcript file IS the
// session, so only that line matters; the sessionId comes from the filename.
// The pid registry file is owned/rewritten by the live CLI, so editing it
// doesn't stick. Node ships with Claude Code, so this runs anywhere it does
// (macOS, Linux, native Windows).
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');
const crypto = require('crypto');

const name = process.argv[2];
if (!name) {
  console.error('usage: claude-rename.js <new-name> [session-id]');
  process.exit(1);
}
const sid = process.argv[3] || process.env.CLAUDE_SESSION_ID || '';

const base = path.join(os.homedir(), '.claude', 'projects');

function listTranscripts() {
  let out = [];
  let dirs;
  try { dirs = fs.readdirSync(base); } catch { return out; }
  for (const d of dirs) {
    const dir = path.join(base, d);
    let files;
    try { files = fs.readdirSync(dir); } catch { continue; }
    for (const f of files) {
      if (f.endsWith('.jsonl')) out.push(path.join(dir, f));
    }
  }
  return out;
}

let transcript;
if (sid) {
  transcript = listTranscripts().find(p => path.basename(p) === sid + '.jsonl');
  if (!transcript) { console.error(`no transcript found for session ${sid}`); process.exit(1); }
} else {
  const all = listTranscripts();
  if (!all.length) { console.error('no transcripts found'); process.exit(1); }
  transcript = all.sort((a, b) => fs.statSync(b).mtimeMs - fs.statSync(a).mtimeMs)[0];
}

const sessionId = path.basename(transcript).replace(/\.jsonl$/, '');

const rec = {
  type: 'system',
  subtype: 'local_command',
  content: `<local-command-stdout>Session renamed to: ${name}</local-command-stdout>`,
  level: 'info',
  timestamp: new Date().toISOString(),
  uuid: crypto.randomUUID(),
  isMeta: false,
  userType: 'external',
  entrypoint: 'cli',
  sessionId,
};

fs.appendFileSync(transcript, JSON.stringify(rec) + '\n');

console.log(`Session renamed to: ${name}`);
console.log(`  transcript: ${transcript}`);
console.log('  (visible in /resume; live UI updates on reload)');
