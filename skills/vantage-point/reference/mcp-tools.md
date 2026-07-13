# Vantage Point MCPツール リファレンス

## 概要

Vantage Point は vp-app 常駐 Canvas、 performer lane 管理、 wiremsg inter-agent 通信、 dev-flow orchestration を提供する MCP サーバーです。

**MCPサーバー名**: `vantage-point`
**対応 VP バージョン**: v0.45+（MCP tool surface は v0.44 から不変）
**実ツール数**: 20（SSOT = `crates/vantage-point/src/mcp{,.rs}` + `src/generated/agent_tools.rs`）

Process が起動していない場合、MCP ツール呼び出し時に自動的に Process を起動します（自動起動リレー）。

> **用語**: conductor (= 旧 lead)、 performer (= 旧 wing/worker)。 wire address: `agent@<project>` / `agent@<project>/<performer>`。 lane address: `<project>/conductor` / `<project>/performer/<name>`。

---

## ツール一覧 (カテゴリ別、 全 20 個)

| カテゴリ | ツール |
|----------|--------|
| Display / Canvas | `show`, `clear`, `read_pane`, `list_canvas`, `capture_canvas`, `switch_lane` |
| Performer Lane | `add_performer`, `delete_performer`, `list_lanes` |
| dev-flow | `flow_handoff`, `flow_progress` |
| wiremsg | `wire_send`, `wire_recv`, `wire_inbox`, `wire_ack`, `wire_thread` |
| Delegation | `delegate`, `complete`, `respond` |
| Process | `restart` |

**MCP には存在しない（CLI のみ）**: pane 操作 (`vp pane toggle/close/split`)、 file 監視 (`vp file watch/unwatch`)、 port 管理 (`vp port show/url/roles/layout/slot`)、 lane nudge / capture (`vp lane nudge` / `vp lane capture`)。 旧 doc の `toggle_pane` / `close_pane` / `watch_file` / `unwatch_file` / `port_*` / `permission` / `lane_nudge` (MCP) は #625 の tool 整理で撤去済み or 元から MCP には無い。

**廃止済**: `tmux_*`, `add_wing`/`add_worker`, `eval_ruby`/`run_ruby`/`stop_ruby`/`list_ruby`, `open_canvas`/`close_canvas`/`split_pane`(MCP), `capture_terminal`

---

## Display / Canvas

### show

```typescript
mcp__vantage-point__show({
  content: "表示するコンテンツ",
  content_type: "markdown",  // markdown(デフォルト), html, log, url
  title: "タブタイトル"
})
```

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `content` | string | ✓ | 表示するコンテンツ |
| `content_type` | string | - | `markdown`, `html`, `log`, `url` |
| `title` | string | - | ペインタブタイトル |
| `pane_id` | string | - | **現在無視される**（dead field、 後方互換のため残置） |

> ⚠️ vp-app の canvas-handler は `pane_id` を無視し、 全 show を現 lane の **PP body stack** に積む（doc 19 PP Canvas Stack Model）。 旧 3-pane (main/left/right) モデルは廃止。 `append` パラメータは存在しない（CLI `vp pane show --append` のみ）。

CLI pair: `vp pane show <content> [-f markdown|html|log|url] [--title] [--append]`

### clear

```typescript
mcp__vantage-point__clear({ pane_id: "main" })
```

CLI pair: `vp pane clear`

### read_pane / list_canvas

Canvas pane の内容を取得・一覧。 creo-memories 保存向け。

```typescript
mcp__vantage-point__list_canvas()
mcp__vantage-point__read_pane({ pane_id: "main" })
// pane_id 省略時、 pane が 1 つだけならそれを返す
```

### capture_canvas

vp-app GUI window 全体（sidebar + console + Canvas）を PNG 撮影。 Read tool で視認可能。

```typescript
mcp__vantage-point__capture_canvas({
  path: "/tmp/screenshot.png"  // 省略時 /tmp/vp-canvas-{timestamp}.png
})
```

> `pane_id` パラメータは現在無視される（window 全体撮影、 per-pane は将来対応）。

CLI pair: `vp shot -o /tmp/vp-shot.png`（canonical screenshot 機構）

### switch_lane

vp-app の active lane を切替。 人間の view を無断で切り替えない（ROTO / CLI 駆動の view 制御向け）。

```typescript
mcp__vantage-point__switch_lane({ lane: "conductor" })
mcp__vantage-point__switch_lane({ lane: "feat-api" })
```

CLI pair: `vp lane switch <name>`

---

## Performer Lane

### add_performer

performer lane を spawn (worktree + echoes)。 旧 `add_wing` / `add_worker`。

```typescript
mcp__vantage-point__add_performer({
  name: "feat-api",
  branch: "mako/feat-api",  // 省略時 auto-derive (<git-user>/<name>)
  stand: "echoes",          // echoes (default) or shell
  base: "origin/nightly",   // worktree 分岐元 ref (省略時 performer-files.kdl の base-ref → origin/HEAD → main)
  model: "sonnet"           // lane の claude model alias (省略時 claude default)
})
```

CLI pair: `vp lane new <name> <branch> [--isolation worktree|clone] [--base <ref>] [--model <alias>]`
（`--isolation` / `-f` は CLI のみ）

**戻り値**: lane address `<project>/performer/<name>`、 path、 git 状態。

> 同 addr への並行 create は creation reservation で reject される（v0.45、 二重 dispatch TOCTOU 根治）。

### delete_performer

```typescript
mcp__vantage-point__delete_performer({
  name: "feat-api",
  cleanup: true   // default: true。 false で workspace dir 残置 (debug / forensic 用途)
})
```

CLI pair: `vp lane rm <name>`

### list_lanes

```typescript
mcp__vantage-point__list_lanes({
  kind: "performer",   // conductor | performer (省略時 両方)
  state: "running"     // running | spawning | exiting | dead (省略時 全状態)
})
```

**戻り値** (各 lane): `address`, `kind` (conductor/performer), `state`, `stand`, `pid`, `cwd`, `performer_status`, `mailbox_addresses`

- `mailbox_addresses.agent` — wire 送信先 (例: `agent@vantage-point/feat-api`)
- `mailbox_addresses.canvas` — Canvas inbox (例: `canvas@vantage-point/feat-api`)

CLI pair: `vp lane ls --detail`

---

## dev-flow primitives

### flow_handoff

performer 作成 + wire_send + nudge を atomic 実行。 失敗時 rollback。 二重 dispatch は creation reservation で防止（v0.45）。

```typescript
mcp__vantage-point__flow_handoff({
  name: "feat-api",
  task_spec: "# Task\n...",
  mode: "auto",       // default: hitl
  branch: "mako/feat-api",
  stand: "echoes",    // echoes (default) or shell
  base: "origin/nightly",  // worktree 分岐元 ref (省略可)
  model: "opus",      // task 難度に合わせて (機械的=sonnet / 中核設計=opus)
  nudge: true         // false = send のみ (完全 async)
})
```

CLI pair: `vp flow handoff <name> --task-spec <file|-> [--mode auto|hitl] [--branch] [--stand] [--base] [--model] [--no-nudge]`

### flow_progress

全 performer の並列 work 集約 view。

```typescript
mcp__vantage-point__flow_progress()
```

**戻り値** (各 performer): `performer_status`, `unread_wire_count`, `flow_state`, `control_surrender`, `state_reason`

`flow_state` は 6 state FSM: `idle` / `working` / `hitl_pending` / `awaiting_user` / `completed` / `stuck`（詳細は dev-flow skill）

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
mcp__vantage-point__wire_recv({ timeout: 10 })  // default 5, max 30 (秒)
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

処理**後**に ack（受信 = wire_recv だけでは ack にならず、 command は再掲示され続ける）。

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

## Process

### restart

VP Process を再起動（session 状態保持）。 World の restart API に委譲される。

```typescript
mcp__vantage-point__restart()
```

CLI pair: `vp restart-all`（全 Process + TheWorld 再起動）

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
// nudge は CLI で (MCP に lane_nudge は無い):
//   vp lane nudge vantage-point/performer/feat-api "task 届きました。 wire_recv で確認。"

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
  title: "Research"
})
const panes = await mcp__vantage-point__list_canvas()
const src = await mcp__vantage-point__read_pane({ pane_id: panes[0].pane_id })
// → creo-memories remember
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
| `switch_lane` | `vp lane switch` |
| `wire_send` | `vp wire send` |
| `wire_recv` | `vp wire recv` |
| `wire_inbox` | `vp wire inbox` |
| `wire_ack` | `vp wire ack` |
| `wire_thread` | `vp wire thread` |
| `show` | `vp pane show` |
| `clear` | `vp pane clear` |
| `capture_canvas` | `vp shot` |
| `restart` | `vp restart-all` |

**CLI のみ（MCP pair なし）**: `vp lane nudge` / `vp lane capture` / `vp pane toggle|close|split` / `vp file watch|unwatch` / `vp port show|url|roles|layout|slot` / `vp wire watch|discover|hook-check|deleg-thread|watch-supervised`
