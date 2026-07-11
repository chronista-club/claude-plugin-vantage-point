---
name: vantage-point
description: AI ネイティブ開発環境 — Canvas 視覚化、並列 performer 展開、wiremsg inter-agent 通信、dev-flow orchestration を実現する MCP server。Claude Code 用 dashboard tool
version: 0.19.0
tags:
  - dashboard
  - canvas
  - mcp
  - inter-agent
  - conductor-performer
  - dev-flow
---

# Vantage Point

> **AI ネイティブ開発環境** — Claude Code セッション中に Canvas 視覚化、 並列 performer 展開、 wiremsg inter-agent 通信、 dev-flow orchestration を実現する MCP server。

VP は単なる「ブラウザビューア」 ではなく、 開発体験そのものを構成する 5 つの柱を提供する:

1. **Canvas** (Paisley Park 🧭) — markdown / HTML / URL / ログを視覚化
2. **Performer Lane** (Stone Free 🧵) — conductor + performer の並列開発環境
3. **wiremsg** — project 跨ぎ inter-agent 通信 (ccwire / msgbox 廃止、 wiremsg に一本化)
4. **dev-flow primitives** — `flow_handoff` / `flow_progress` で Conductor × Performer orchestration
5. **Screenshot** — `vp shot` / `capture_canvas` で UI 状態を PNG 化、 Read tool で AI が視認

詳細 architecture: 関連 memory `mem_1CaVnfJRgWtuRgZD9yQSoV` (舞台-役者-演目 mental model)

> **用語注** (VP v0.40+): orchestration 側は **conductor** (= 旧 lead)、 実装主体は **performer** (= 旧 wing / worker)。 lane address は `<project>/conductor` / `<project>/performer/<name>`、 wire address は `agent@<project>` / `agent@<project>/<performer-name>`。

---

## クイックスタート

```bash
# vp-app GUI を起動 (TheWorld:32000 が無ければ auto-launch)
vp app

# project SP の起動は vp-app sidebar から expand → auto-spawn
```

VP Process が起動していなくても、 MCP ツールを呼ぶと自動的に Process を起動する。

---

## 5 つの典型シナリオ

### 1. Canvas に Markdown を表示

```
mcp__vantage-point__show
  content: "# 進捗\n- A 完了\n- B 着手"
  pane_id: "main"
  content_type: "markdown"
```

### 2. ログをリアルタイム監視

```
mcp__vantage-point__watch_file
  path: "/tmp/build.log"
  pane_id: "right"
  format: "json_lines"
  filter: "INFO|WARN|ERROR"
```

→ 新規行が出るたびに Canvas pane に追記、 level filter / target exclusion 可能。

### 3. 並列 performer 展開 + handoff

```
# 推奨: atomic handoff
mcp__vantage-point__flow_handoff
  name: "feat-api"
  task_spec: "<markdown 仕様>"
  mode: "auto" | "hitl"   # default: hitl

# 低レベル fallback
mcp__vantage-point__add_performer
  name: "feat-api"
  branch: "user/feat-api"
mcp__vantage-point__wire_send
  to: ["agent@<project>/feat-api"]
  body: { kind: "task", category: "command", task_spec: "..." }
mcp__vantage-point__lane_nudge
  lane: "<project>/performer/feat-api"
  text: "task が届いています。 wire_recv で確認して着手。"
```

`flow_progress` で全 performer の git status + unread wire + `flow_state` / `control_surrender` を 1 view で監視。

### 4. project 跨ぎ inter-agent 通信 (wiremsg)

```
# 送信 (reply_to なし = 新規 thread の root)
mcp__vantage-point__wire_send
  to: ["agent@creo-memories"]
  body: { text: "review request", category: "command" }

# 受信 (自分が参加する全 wire thread の未読 message、 timeout 待ち)
mcp__vantage-point__wire_recv
  timeout: 10

# 未読数だけ確認 (cursor 不触り)
mcp__vantage-point__wire_inbox

# 処理後 ack (category: command の再掲示を止める)
mcp__vantage-point__wire_ack
  message_id: "<id>"

# thread 系譜の取得
mcp__vantage-point__wire_thread
  message_id: "<message id>"
```

ccwire / msgbox は廃止、 wiremsg に一本化。 thread は `prev` parent-pointer で表現される (`thread_id` は無い)。

### 5. UI スクショで AI 自身が視認

```bash
vp shot -o /tmp/vp-shot.png
# or
mcp__vantage-point__capture_canvas
  path: "/tmp/vp-canvas.png"
```

→ Read tool で PNG を視覚 review 可能。

---

## MCP Tools 一覧 (VP v0.40+)

### Display / Canvas (Paisley Park 🧭)

| Tool | 用途 |
|------|------|
| `show` | コンテンツ表示 (markdown/html/log/url) |
| `clear` | pane content clear |
| `toggle_pane` | pane 表示/非表示切替 |
| `close_pane` | pane を閉じる |
| `read_pane` | Canvas pane の full source を取得 (memory 保存向け) |
| `list_canvas` | Canvas 上の pane 一覧 (title / content_type / preview) |
| `switch_lane` | vp-app の active lane 切替 (`conductor` or performer name) |
| `watch_file` | ログ file をリアルタイム表示 |
| `unwatch_file` | 監視停止 |
| `capture_canvas` | Canvas window の PNG capture |

### Performer Lane (Stone Free 🧵)

| Tool | 用途 |
|------|------|
| `add_performer` | performer lane を spawn (worktree clone + echoes)。 旧名 `add_wing` / `add_worker` |
| `delete_performer` | performer lane を片付け (PTY/tmux/workspace cleanup)。 旧名 `delete_wing` / `delete_worker` |
| `list_lanes` | project 内全 Lane 一覧 (Conductor + Performers、`performer_status` / `mailbox_addresses` 付き) |
| `lane_nudge` | lane に text + Enter 注入。 旧 `tmux send-keys` / `vp directmsg` |

### dev-flow primitives

| Tool | 用途 |
|------|------|
| `flow_handoff` | performer 作成 + wire_send + lane_nudge を atomic (= 失敗時 rollback) |
| `flow_progress` | 全 performer の git status + unread wire + `flow_state` / `control_surrender` 集約 |

### wiremsg (inter-agent 通信)

| Tool | 用途 |
|------|------|
| `wire_send` | wire address に送信。 `reply_to` なし = 新規 thread root |
| `wire_recv` | 未読 message 受信 (読むと cursor 前進) |
| `wire_inbox` | 未読数だけ確認 (cursor 不触り) |
| `wire_ack` | `category: command` msg の受領確認 |
| `wire_thread` | message 系譜 trace (root-first、 cursor 不触り) |

### Delegation (async future primitive)

| Tool | 用途 |
|------|------|
| `delegate` | task を doer lane に委譲し turn を park (= spin-wait 不要) |
| `complete` | 委譲された task の outcome 報告 (`done` / `failed` / `needs_input`) |
| `respond` | doer の `needs_input` question への回答 |

### Port management (slot × lane × role)

| Tool | 用途 |
|------|------|
| `port_show` | slot × lane × role → port (deterministic) |
| `port_url` | localhost URL 生成 |
| `port_roles` | role → offset table |
| `port_layout` | 1 project slot の全 port 配置 |

### Process

| Tool | 用途 |
|------|------|
| `restart` | VP Process restart (session 状態保持) |
| `permission` | tool 実行 permission 要求 (`--permission-prompt-tool` 用) |

**廃止済** (v0.40 以前の doc に残っていたもの):
- `tmux_split` / `tmux_capture` / `tmux_dashboard` / `tmux_agent_*` → `lane_nudge` / `vp lane capture`
- `add_wing` / `delete_wing` → `add_performer` / `delete_performer`
- `open_canvas` / `close_canvas` / `split_pane` (MCP) → vp-app 常駐 Canvas + Frame Engine
- `eval_ruby` / `run_ruby` / `stop_ruby` / `list_ruby` → 削除
- `capture_terminal` → `vp shot`

---

## MCP ↔ CLI pair invariant

VP は **「同じ logic を MCP (= AI agent 用) + CLI (= human 用) 両方から expose する」** を invariant として持つ。

### pair table (主要)

| MCP tool | CLI subcommand | 備考 |
|---|---|---|
| `show` | `vp pane show <content>` | `--pane-id` / `--format` / `--append` / `--title` |
| `clear` | `vp pane clear` | `--pane-id` |
| `toggle_pane` | `vp pane toggle <pane_id>` | `--visible` |
| `close_pane` | `vp pane close <pane_id>` | |
| `switch_lane` | `vp lane switch <name>` | `conductor` or performer name |
| `add_performer` | `vp lane new <name> <branch>` | `--isolation worktree\|clone` |
| `delete_performer` | `vp lane rm <name>` | |
| `list_lanes` | `vp lane ls --detail` | default `vp lane ls` は fs scan 簡易出力 |
| `lane_nudge` | `vp lane nudge <lane> <text>` | lane address 形式 |
| `flow_handoff` | `vp flow handoff <name> --task-spec <file>` | `--mode auto\|hitl` (default hitl) |
| `flow_progress` | `vp flow progress` | `--format json\|table` |
| `wire_send` | `vp wire send` | `--to` / `--body` / `--reply-to` / `--category` / `--world` |
| `wire_recv` | `vp wire recv` | 連続 subscribe は `vp wire watch` |
| `wire_inbox` | `vp wire inbox` | read-only |
| `wire_ack` | `vp wire ack` | |
| `wire_thread` | `vp wire thread` | |
| `capture_canvas` | `vp shot` | CLI は canonical screenshot |
| `watch_file` / `unwatch_file` | `vp file watch` / `vp file unwatch` | |
| `port_*` | `vp port show\|url\|roles\|layout` | |
| `restart` | `vp restart-all` | 全 Process + TheWorld 再起動 |

### `list_lanes` vs `vp ps` vs `vp lane ls`

- **`list_lanes`** = 現 project の **全 Lane (Conductor + Performers)**。 `performer_status` / `mailbox_addresses` 詳細付き
- **`vp ps`** = TheWorld 配下の **全 project SP** 一覧 (port + pid + project_name)
- **`vp lane ls`** = fs scan 簡易表示 (`name<TAB>branch<TAB>path`)。 SP 不要
- **`vp lane ls --detail`** = `list_lanes` の CLI pair。 SP 稼働中のみ

---

## アーキテクチャ概要

```
TheWorld 👑 (32000) — 常駐 daemon、 全 SP を管理
  │
  ├── Hermit Purple 🍇 — External Control (MIDI / MCP)
  │
  └── Star Platinum ⭐ (project SP, 33xxx) — Project 単位の容器
        ├── Echoes 💬 — Coding Assistant (Claude CLI / 任意 LLM)
        ├── Paisley Park 🧭 — Information Navigator (Canvas / WebView + Frame Engine)
        ├── Gold Experience 🌿 — Code Runner (process 管理)
        └── (per slot) Lane — PTY セッション (Conductor + Performers)
              ├── The Hand 🤚 — 素 shell base
              └── Echoes 💬 — 任意 LLM auto-launch
```

詳細メンタルモデル: `mem_1CaVnfJRgWtuRgZD9yQSoV` (舞台-役者-演目)

---

## ペイン構成 (Canvas 内部)

Canvas は **vp-app 常駐の統合ウィンドウ**。 project ごとにタブ、 タブ内に複数 pane:

| Pane ID | 用途 |
|----|------|
| `main` | メインコンテンツ (default) |
| `left` | 左サイドパネル (常用: creo-memories 等) |
| `right` | 右サイドパネル (常用: ログ / preview) |

`switch_lane` で conductor / performer 切替、 `toggle_pane` で表示切替。

---

## コンテンツタイプ (`show` の content_type)

| タイプ | 説明 |
|--------|------|
| `markdown` | Markdown 形式 (**デフォルト・推奨**) |
| `html` | HTML 形式 |
| `log` | ログ形式 (追記向け、 `append: true` と組合せ) |
| `url` | 外部 URL を iframe で埋め込み表示 |

---

## wiremsg delivery policy

`wire_send` の `body.category` で delivery を制御:

| category | 挙動 |
|----------|------|
| `command` | **default**。 受信者が `wire_ack` するまで再掲示 (= nudge loop) |
| `event` / `data` / `state` / `log` | fire-and-forget。 再掲示なし |

---

## トラブルシューティング

| 症状 | 対処 |
|------|------|
| SP が「stale」 (sidebar 緑だが console 壊れ) | vp-app sidebar の 🔄 (Restart SP) ボタン |
| Lane が dead 化 (claude zombie) | Lifecycle monitor が 5s 以内に検知 → sidebar 赤 dot → 手動 respawn |
| `mcp_call timeout` | `restart` / `vp restart-all` で復旧 |
| `wire_*` が動かない | SP 起動確認 (`vp app` → sidebar expand)、 wire address 再確認 (`agent@<project>` / `agent@<project>/<performer>`) |
| command msg が何度も nudge される | 受信側が `wire_ack` を忘れている |

---

## 使用例 (詳細)

### flow_handoff (推奨 handoff)

```typescript
mcp__vantage-point__flow_handoff({
  name: "feat-api",
  task_spec: "# Task\nImplement API endpoint X",
  mode: "auto",
  branch: "mako/feat-api"
})
```

### flow_progress (並列追跡)

```typescript
mcp__vantage-point__flow_progress()
// → performers[].flow_state, control_surrender, performer_status, unread_wire_count
```

### delegate (単発委譲)

```typescript
mcp__vantage-point__delegate({
  doer: "agent@vantage-point/feat-api",
  task: "Fix the failing test in src/api.rs. Report result via complete()."
})
// → delegation id。 turn を park し、 doer の complete で再開
```

### Canvas pane を memory に保存

```typescript
mcp__vantage-point__list_canvas()
mcp__vantage-point__read_pane({ pane_id: "main" })
// → creo-memories remember に流す
```

---

## 関連 memory (詳細設計)

- VP Roadmap Phase 5→9 (`mem_1CaVeQEKXd8U2XHn75RD4M`)
- Mental model 舞台-役者-演目 (`mem_1CaVnfJRgWtuRgZD9yQSoV`)
- Hub federation 仕様 (`mem_1CaVeTysipdgVHoxwxUcPj`)
- 4 scope architecture (`mem_1CaSugEk1W2vr5TAdfDn5D`)
- dev-flow overview (`mem_1CbUUzvguCptQPU4eWTKHx`)
- wire address spec — `agent@<project>` (conductor) / `agent@<project>/<performer>`、`canvas@<project>/<performer>`、`notify@<project>` 等

---

## 開発・dogfooding tip

- VP dogfooding: `mr app` (mise) で起動、`~/Library/Logs/Vantage/vp-{world,app}.kdl.log` を tail
- SP のみ再起動: sidebar 🔄 or `mise run sp-kill` → expand で auto-respawn
- 全部 fresh start: `VP_FORCE_RESTART_DAEMON=1 VP_FORCE_RESTART_SP=1 mr app`

---

## 関連

- **dev-flow skill**: `skills/dev-flow/SKILL.md` — Conductor × Performer orchestration 6 phase
- **詳細リファレンス**: `reference/mcp-tools.md`
- **VP リポジトリ**: https://github.com/chronista-club/vantage-point
