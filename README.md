# Vantage Point Plugin

Claude Code plugin for rich dashboard display during development sessions.

## Features

- **3-Pane Dashboard** - Left (memories), Main (todos), Right (context)
- **Auto-update Hooks** - Dashboard updates automatically during Claude Code sessions
- **Flexible Display** - Markdown, HTML, and log format support

## Dashboard Layout

```
+------------------+----------------------+--------------------+
| LEFT (memories)  | MAIN (tasks)         | RIGHT (context)    |
+------------------+----------------------+--------------------+
| Recent Memories  | Current Todos        | Context            |
| - Design: ...    | - [ ] Task 1         | pwd: /path/to      |
| - Decision: ...  | - [x] Task 2         | branch: main       |
|                  |                      |                    |
| Related          | Next Actions         | Research           |
| - Memory 1       | (from gh issues)     | - Bike Boy results |
| - Memory 2       | - #12 Feature X      |                    |
|                  | - #15 Bug fix        | SDG                |
|                  |                      | - current design   |
+------------------+----------------------+--------------------+
```

## Installation

```bash
# From official marketplace (coming soon)
claude plugin install vantage-point@claude-plugins-official

# Or from GitHub
/plugin marketplace add chronista-club/claude-plugins
claude plugin install vantage-point@chronista-plugins
```

## Commands

| Command | Description |
|---------|-------------|
| `/vantage-point:show` | Display content in the dashboard |
| `/vantage-point:dashboard` | Initialize the full dashboard |
| `/vantage-point:clear` | Clear dashboard panes |

## Requirements

- Vantage Point MCP server must be running
- Browser window for dashboard display

## License

MIT
