# Vantage Point Plugin

Claude Code plugin for rich dashboard display during development sessions.

## Features

- **3-Pane Dashboard** - Left (memories), Main (todos), Right (context)
- **Canvas Mode** - ネイティブWebViewウィンドウでダッシュボードを表示
- **Browser Mode** - ブラウザでダッシュボードを表示（`vp start` で起動）
- **Auto-update Hooks** - SessionStart フックでダッシュボードを自動初期化
- **Flexible Display** - Markdown, HTML, log 形式をサポート

## Canvas vs Browser モード

| モード | 起動方法 | 特徴 |
|--------|----------|------|
| Canvas | `open_canvas` MCPツール | ネイティブWebViewウィンドウ。ブラウザ不要 |
| Browser | `vp start` CLI | ブラウザで `http://localhost:<port>` にアクセス |

どちらのモードでも同じペインレイアウトとコンテンツ表示機能が使える。

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

Claude Code スラッシュコマンド:

| Command | Description |
|---------|-------------|
| `/vantage-point:show` | ペインにコンテンツを表示 |
| `/vantage-point:dashboard` | フルダッシュボードを初期化（3ペイン） |
| `/vantage-point:clear` | ペインのコンテンツをクリア |

## MCP ツール

| ツール | 説明 |
|--------|------|
| `show` | コンテンツを表示（markdown/html/log） |
| `clear` | ペインをクリア |
| `toggle_pane` | サイドパネルの表示/非表示切り替え |
| `split_pane` | ペインを水平/垂直に分割 |
| `close_pane` | ペインを閉じる |
| `open_canvas` | ネイティブCanvasウィンドウを開く |
| `close_canvas` | Canvasウィンドウを閉じる |
| `restart` | Standサーバーを再起動（セッション状態は保持） |
| `permission` | ツール実行の権限をユーザーに確認（`--permission-prompt-tool` 用） |

## Requirements

- Vantage Point CLI (`vp`) がインストール済み
- Canvas モードまたは Browser モードで Stand が起動中

## License

MIT
