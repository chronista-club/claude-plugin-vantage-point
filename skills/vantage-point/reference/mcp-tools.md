# Vantage Point MCPツール リファレンス

## 概要

Vantage Point は vp-app 常駐 Canvas、 performer lane 管理、 wiremsg inter-agent 通信、 dev-flow orchestration を提供する MCP サーバーです。

**MCPサーバー名**: `vantage-point`  
**対応 VP バージョン**: v0.40+

Process が起動していない場合、MCP ツール呼び出し時に自動的に Process を起動します（自動起動リレー）。

> **用語**: conductor (= 旧 lead)、 performer (= 旧 wing/worker)。 wire address: `agent@<project>` / `agent@<project>/<performer>`。 lane address: `<project>/conductor` / `<project>/performer/<name>`。

---

## ツール一覧 (カテゴリ別)

| カテゴリ | ツール |
|----------|--------|
| Display / Canvas | `show`, `clear`, `toggle_pane`, `close_pane`, `read_pane`, `list_canvas`, `switch_lane`, `watch_file`, `unwatch_file`, `capture_canvas` |
| Performer Lane | `add_performer`, `delete_performer`, `list_lanes`, `lane_nudge` |
| dev-flow | `flow_handoff`, `flow_progress` |
| wiremsg | `wire_send`, `wire_recv`, `wire_inbox`, `wire_ack`, `wire_thread` |
| Delegation | `delegate`, `complete`, `respond` |
| Port | `port_show`, `port_url`, `port_roles`, `port_layout` |
| Process | `restart`, `permission` |

**廃止済**: `tmux_*`, `add_wing`/`add_worker`, `eval_ruby`/`run_ruby`, `open_canvas`/`close_canvas`/`split_pane`(MCP), `capture_terminal`

---

## Display / Canvas

### show

```typescript
mcp__vantage-point__show({
  content: "表示するコンテンツ",
  content_type: "markdown",  // markdown(デフォルト), html, log, url
  pane_id: "main",
  append: false,
  title: "タブタイトル"
})
```

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `content` | string | ✓ | 表示するコンテンツ |
| `content_type` | string | - | `markdown`, `html`, `log`, `url` |
| `pane_id` | string | - | `main`(デフォルト), `left`, `right` |
| `append` | boolean | - | 追記モード |
| `title` | string | - | ペインタブタイトル |

### clear / toggle_pane / close_pane

```typescript
mcp__vantage-point__clear({ pane_id: "main" })
mcp__vantage-point__toggle_pane({ pane_id: "right", visible: false })
mcp__vantage-point__close_pane({ pane_id: "pane-id" })
```

### read_pane / list_canvas

Canvas pane の内容を取得・一覧。 creo-memories 保存向け。

```typescript
mcp__vantage-point__list_canvas()
mcp__vantage-point__read_pane({ pane_id: "main" })
// pane_id 省略時、 pane が 1 つだけならそれを返す
```

### switch_lane

vp-app の active lane を切替。

```typescript
mcp__vantage-point__switch_lane({ lane: "conductor" })
mcp__vantage-point__switch_lane({ lane: "feat-api" })
```

### watch_file / unwatch_file

```typescript
mcp__vantage-point__watch_file({
  path: "/path/to/file.log",
  pane_id: "right",
  format: "json_lines",
  filter: "INFO|WARN|ERROR",
  title: "App Log"
})
mcp__vantage-point__unwatch_file({ pane_id: "right" })
```

### capture_canvas

```typescript
mcp__vantage-point__capture_canvas({
  path: "/tmp/screenshot.png",
  pane_id: "main"
})
```

CLI pair: `vp shot -o /tmp/vp-shot.png`

---

## Performer Lane

### add_performer

performer lane を spawn (worktree clone + echoes)。 旧 `add_wing` / `add_worker`。

```typescript
mcp__vantage-point__add_performer({
  name: "feat-api",
  branch: "mako/feat-api"  // 省略時 auto-derive
})
```

CLI pair: `vp lane new <name> <branch> [--isolation worktree|clone]`

**戻り値**: lane address `<project>/performer/<name>`、 path、 git 状態。

### delete_performer

```typescript
mcp__vantage-point__delete_performer({
  name: "feat-api",
  force: false
})
```

CLI pair: `vp lane rm <name>`

### list_lanes

```typescript
mcp__vantage-point__list_lanes()
```

**戻り値** (各 lane): `address`, `kind` (conductor/performer), `state`, `stand`, `pid`, `cwd`, `performer_status`, `mailbox_addresses`

- `mailbox_addresses.agent` — wire 送信先 (例: `agent@vantage-point/feat-api`)
- `mailbox_addresses.canvas` — Canvas inbox (例: `canvas@vantage-point/feat-api`)

CLI pair: `vp lane ls --detail`

### lane_nudge

lane に text + Enter を注入。 旧 `tmux send-keys`。

```typescript
mcp__vantage-point__lane_nudge({
  lane: "vantage-point/performer/feat-api",
  text: "wire_recv で task を確認して着手"
})
```

CLI pair: `vp lane nudge <lane> <text>`

---

## dev-flow primitives

### flow_handoff

performer 作成 + wire_send + lane_nudge を atomic 実行。 失敗時 rollback。

```typescript
mcp__vantage-point__flow_handoff({
  name: "feat-api",
  task_spec: "# Task\n...",
  mode: "auto",       // default: hitl
  branch: "mako/feat-api",
  stand: "echoes",    // echoes (default) or shell
  nudge: true         // false = 完全 async
})
```

CLI pair: `vp flow handoff <name> --task-spec <file> [--mode auto|hitl]`

### flow_progress

全 performer の並列 work 集約 view。

```typescript
mcp__vantage-point__flow_progress()
```

**戻り値** (各 performer): `performer_status`, `unread_wire_count`, `flow_state`, `control_surrender`, `state_reason`

CLI pair: `vp flow progress [--format json|table]`

---

## wiremsg

wire address: `agent@<project>` (conductor) / `agent@<project>/<performer>`。 thread は `prev` parent-pointer。

### wire_send

```typescript
mcp__vantage-point__wire_send({
  to: ["agent@vantage-point/feat-api"],
  body: { kind: "task", category: "command", text: "..." },
  reply_to: "<message id>"  // 省略 = 新規 thread root
})
```

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `to` | string[] | ✓ | 宛先 wire address |
| `body` | object | ✓ | message 本文。 `category` で delivery policy |
| `reply_to` | string | - | reply 先 message id |

**body.category**:

| category | 挙動 |
|----------|------|
| `command` | default。 `wire_ack` まで再掲示 |
| `event` / `data` / `state` / `log` | fire-and-forget |

### wire_recv

```typescript
mcp__vantage-point__wire_recv({ timeout: 10 })
```

読むと cursor 前進。 各 message: `id`, `prev`, `from`, `to`, `body`, `created_at`, `local_seq`

CLI pair: `vp wire recv` / 連続は `vp wire watch`

### wire_inbox

未読数だけ確認 (cursor 不触り)。

```typescript
mcp__vantage-point__wire_inbox()
// → { total, by_thread: { "<root_id>": <count> } }
```

CLI pair: `vp wire inbox`

### wire_ack

```typescript
mcp__vantage-point__wire_ack({ message_id: "<id>" })
```

CLI pair: `vp wire ack`

### wire_thread

```typescript
mcp__vantage-point__wire_thread({ message_id: "<id>" })
```

root-first 系譜。 cursor 不触り。

CLI pair: `vp wire thread`

---

## Delegation (async future)

### delegate

task を doer に委譲し turn を park。 spin-wait 不要。

```typescript
mcp__vantage-point__delegate({
  doer: "agent@vantage-point/feat-api",
  task: "Fix test in src/api.rs. Report via complete()."
})
// → delegation id
```

### complete

委譲 task の outcome 報告 (doer 側)。

```typescript
mcp__vantage-point__complete({
  id: "dlg-...",
  outcome: "done",       // done | failed | needs_input
  result: "Test fixed, PR ready"
})
```

### respond

doer の `needs_input` への回答 (requester 側)。

```typescript
mcp__vantage-point__respond({
  id: "dlg-...",
  answer: "Use approach B"
})
```

---

## Port management

```typescript
mcp__vantage-point__port_show({ slot: 0, lane: "conductor", role: "dev_server" })
mcp__vantage-point__port_url({ slot: 0, lane: "conductor", role: "canvas" })
mcp__vantage-point__port_roles()
mcp__vantage-point__port_layout({ slot: 0 })
```

CLI pair: `vp port show|url|roles|layout`

---

## Process

### restart

```typescript
mcp__vantage-point__restart({ open_viewer: false })
```

CLI pair: `vp restart-all`

### permission

`--permission-prompt-tool` 用の user 確認 dialog。

---

## 使用シナリオ

### dev-flow handoff + 追跡

```typescript
// 1. atomic handoff
mcp__vantage-point__flow_handoff({
  name: "feat-api",
  task_spec: "# Implement endpoint X\n...",
  mode: "auto"
})

// 2. 並列追跡
mcp__vantage-point__flow_progress()

// 3. 未読確認 (軽量)
mcp__vantage-point__wire_inbox()

// 4. 本文取得 + ack
const msgs = await mcp__vantage-point__wire_recv({ timeout: 5 })
await mcp__vantage-point__wire_ack({ message_id: msgs[0].id })
```

### wire thread 対話

```typescript
mcp__vantage-point__wire_send({
  to: ["agent@vantage-point/feat-api"],
  body: { kind: "task", category: "command", task_spec: "..." }
})
mcp__vantage-point__lane_nudge({
  lane: "vantage-point/performer/feat-api",
  text: "task 届きました。 wire_recv で確認。"
})

// performer からの reply
const reply = await mcp__vantage-point__wire_recv({ timeout: 30 })
mcp__vantage-point__wire_send({
  to: ["agent@vantage-point/feat-api"],
  reply_to: reply[0].id,
  body: { kind: "approve", category: "command" }
})
```

### Canvas + memory 保存

```typescript
mcp__vantage-point__show({
  content: "# 調査結果\n...",
  pane_id: "right",
  title: "Research"
})
const panes = await mcp__vantage-point__list_canvas()
const src = await mcp__vantage-point__read_pane({ pane_id: panes[0].pane_id })
// → creo-memories remember
```

### リアルタイムログ監視

```typescript
mcp__vantage-point__watch_file({
  path: "/tmp/app-trace.log",
  pane_id: "right",
  format: "json_lines",
  filter: "WARN|ERROR",
  title: "App Trace"
})
mcp__vantage-point__unwatch_file({ pane_id: "right" })
```

---

## MCP ↔ CLI pair 早見表

| MCP | CLI |
|-----|-----|
| `flow_handoff` | `vp flow handoff` |
| `flow_progress` | `vp flow progress` |
| `add_performer` | `vp lane new` |
| `delete_performer` | `vp lane rm` |
| `list_lanes` | `vp lane ls --detail` |
| `lane_nudge` | `vp lane nudge` |
| `switch_lane` | `vp lane switch` |
| `wire_send` | `vp wire send` |
| `wire_recv` | `vp wire recv` |
| `wire_inbox` | `vp wire inbox` |
| `wire_ack` | `vp wire ack` |
| `wire_thread` | `vp wire thread` |
| `show` | `vp pane show` |
| `capture_canvas` | `vp shot` |
| `watch_file` | `vp file watch` |
