# iTerm2 Agent Summary

An [Amp](https://ampcode.com) skill that detects AI coding agents (Amp, Claude Code, Codex, Gemini) running across iTerm2 tabs by scraping terminal contents.

Ask "what agents are running?" and get a table showing each agent, its status, working directory, and current task.

<img width="800" height="368" alt="image" src="https://github.com/user-attachments/assets/cb6b2c58-b5fc-49a5-9f58-95ec3c7dcfdd" />


## How It Works

An AppleScript (`scripts/detect-agents.sh`) grabs the first and last 50 lines from every iTerm2 tab. The LLM then pattern-matches on known UI elements to identify which agent is running in each tab:

- **Amp** — bordered box UI (`╭╰├`), context percentage, mode indicator
- **Claude Code** — `⏺` bullets, `❯` prompt
- **Codex** — `• ` bullets, `› ` prompt, `% context left`
- **Gemini** — `gemini` in prompt

## Requirements

- macOS with iTerm2

## Installation

Copy the skill into your Amp skills directory:

```bash
mkdir -p ~/.config/agents/skills/agent-tabs
cp SKILL.md ~/.config/agents/skills/agent-tabs/
cp -r scripts ~/.config/agents/skills/agent-tabs/
chmod +x ~/.config/agents/skills/agent-tabs/scripts/detect-agents.sh
```

Then ask Amp "what agents are running?" and it will use the skill automatically.

## Alternatives Considered

### Self-reporting via AGENTS.md

We tried having agents report their own status by calling a shell script (`agent-status running amp "task"`) on every request, triggered by instructions in `~/AGENTS.md`. The agent would write a JSON file to `~/.agent-status/`, and a separate `agent-list` command would read those files and display a table.

This didn't work reliably. Agents frequently ignored the instruction, especially when busy with complex tasks or when context was tight. The status files would go stale and the table would show outdated information.

### iTerm2 Python API

We also tried using iTerm2's Python API (`iterm2` package) to read screen contents programmatically. This gives cleaner output than AppleScript but requires the iTerm2 Python runtime, which is slow to start (~2-3 seconds) and adds a dependency that's awkward to install. The AppleScript approach is instant and works out of the box.

## File Structure

```
iterm2-agent-summary/
├── README.md
├── SKILL.md          # Amp skill definition with detection patterns
└── scripts/
    └── detect-agents.sh   # AppleScript to scrape iTerm2 tab contents
```
