---
name: agent-tabs
description: "Shows which AI agents are running in iTerm2 tabs. Use when asked: what agents are running, show agents, list tabs, which tab."
---

# Agent Tabs

Shows AI coding agents running across iTerm2 tabs.

## How to Use

Run `scripts/detect-agents.sh` and present the results as a table.

The script outputs the first 50 lines (contains original prompt) and last 50 lines (current status) of each tab, separated by `---RECENT---`.

## Agent Detection Patterns

| Agent | Indicators |
|-------|------------|
| **amp** | Box UI with `╭`, `╰`, `├─X% of 168k`, `smart`/`rush`/`deep`, `skills─┤` in footer |
| **claude** | `⏺` bullets, `❯` prompt, `bypass permissions`, `brew upgrade claude-code` |
| **codex** | `• ` bullets, `› ` prompt, `% context left` but NO box UI (no `╭╰├`) |
| **gemini** | `gemini` in prompt, Google Gemini CLI indicators |

**Key distinction**: Amp has the bordered box UI. Codex has similar bullets but no box.

## Status Detection

- **running**: Contains `esc to interrupt`, `Working`, `Running tools`, spinner characters
- **waiting**: Has prompt visible (`›`, `❯`, `>`) without running indicators

## Output Format

Present as a markdown table with emoji:

| TAB | AGENT | STATUS | CWD | TASK |
|-----|-------|--------|-----|------|
| 1 | 🔷 codex | 🟢 running | cfo | Steel browser automation for OTP (52m) |
| 2 | ⚡ amp | 🟡 waiting | agent-manager-2 | Installed agent-tabs skill |
| 3 | 🟣 claude | 🟡 waiting | website | Deployed article to production |

**Agent emoji:**
- ⚡ amp
- 🟣 claude
- 🔷 codex
- 💎 gemini

**Status emoji:**
- 🟢 running
- 🟡 waiting

**Guidelines:**
- **CWD**: Extract from the terminal footer or path shown. Show just the project folder name, not full path.
- **TASK**: Focus on the **user's original prompt/request**. Look for lines starting with `>`, `›`, or user messages. If the original prompt scrolled away, **infer the task from context** (file names, project descriptions, what the agent is building). Never use generic descriptions like "Running tools" or "Python installation". Include elapsed time if shown.
- Only show tabs with detected agents. Skip empty/bash-only tabs.
- Add a summary line focusing on the tasks by initial prompt, e.g.: "Summary: 3 agents - OTP automation, agent-tabs skill, deployment"

## Empty Tab Detection

A tab is empty/non-agent if:
- Content is mostly whitespace or just a bash prompt (`$`, `%`)
- No agent-specific UI elements present
- Very short content with no tool output
