# Vantage Point Plugin

Claude Code plugin for AI-native development — Canvas visualization, parallel performer lanes, wiremsg inter-agent communication, and dev-flow orchestration.

## Features

- **vp-app Canvas** — Markdown, HTML, log, URL を Paisley Park に表示
- **Performer Lanes** — conductor + performer の並列開発環境 (`vp lane`, `add_performer`)
- **wiremsg** — project 跨ぎ inter-agent 通信 (`wire_send` / `wire_recv` / `wire_inbox` / `wire_ack`)
- **dev-flow primitives** — `flow_handoff` / `flow_progress` で Conductor × Performer orchestration
- **Auto-update Hooks** — SessionStart で lane 状態をコンテキスト注入、 performer lane で AskUserQuestion をブロック
- **Screenshot** — `vp shot` / `capture_canvas` で UI を PNG 化

## Requirements

- Vantage Point CLI (`vp`) v0.40+ がインストール済み
- Process が未起動でも MCP ツール呼び出し時に自動起動

## Installation

```bash
# From GitHub marketplace
/plugin marketplace add chronista-club/claude-plugins
claude plugin install vantage-point@chronista-plugins
```

## Quick Start

```bash
# vp-app GUI を起動
vp app

# performer handoff (atomic)
vp flow handoff feat-api --task-spec task.md --mode auto

# 並列追跡
vp flow progress
```

## Commands

Claude Code スラッシュコマンド:

| Command | Description |
|---------|-------------|
| `/vantage-point:show` | ペインにコンテンツを表示 |
| `/vantage-point:dashboard` | フルダッシュボードを初期化（3ペイン） |
| `/vantage-point:clear` | ペインのコンテンツをクリア |

## Skills

| Skill | Description |
|-------|-------------|
| `vantage-point` | MCP ツール一覧、アーキテクチャ、典型シナリオ |
| `dev-flow` | Conductor × Performer × Memory orchestration 6 phase 開発フロー |

## MCP Tools (主要)

### Canvas / Display

| ツール | 説明 |
|--------|------|
| `show` | コンテンツ表示 (markdown/html/log/url) |
| `read_pane` / `list_canvas` | Canvas pane 内容の取得・一覧 |
| `watch_file` / `unwatch_file` | ログファイルのリアルタイム監視 |
| `capture_canvas` | Canvas スクリーンショット (PNG) |

### Performer Lane

| ツール | 説明 |
|--------|------|
| `add_performer` / `delete_performer` | performer lane の作成・削除 |
| `list_lanes` | Lane 一覧 (`performer_status`, `mailbox_addresses`) |
| `lane_nudge` | lane に text + Enter 注入 |

### dev-flow

| ツール | 説明 |
|--------|------|
| `flow_handoff` | performer 作成 + wire_send + nudge を atomic 実行 |
| `flow_progress` | 全 performer の git status + flow_state 集約 |

### wiremsg

| ツール | 説明 |
|--------|------|
| `wire_send` / `wire_recv` | inter-agent message 送受信 |
| `wire_inbox` / `wire_ack` | 未読確認 / command 受領確認 |
| `wire_thread` | thread 系譜 trace |
| `delegate` / `complete` / `respond` | async future 型 task 委譲 |

詳細: `skills/vantage-point/reference/mcp-tools.md`

## Dashboard Layout

```
+------------------+----------------------+--------------------+
| LEFT (memories)  | MAIN (tasks)         | RIGHT (context)    |
+------------------+----------------------+--------------------+
| Recent Memories  | Current Todos        | Context            |
| - Design: ...    | - [ ] Task 1         | pwd: /path/to      |
| - Decision: ...  | - [x] Task 2         | branch: main       |
+------------------+----------------------+--------------------+
```

## License

MIT
