---
name: vantage-point
description: AI ネイティブ開発環境 — Canvas 視覚化、並列 performer 展開、wiremsg inter-agent 通信、dev-flow orchestration を実現する MCP server。Claude Code 用 dashboard tool
version: 0.20.0
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
vp app start

# project SP の起動は vp-app sidebar から expand → auto-spawn
```

VP Process が起動していなくても、 MCP ツールを呼ぶと自動的に Process を起動する。

---

## 5 つの典型シナリオ

### 1. Canvas に Markdown を表示

```
mcp__vantage-point__show
  content: "# 進捗\n- A 完了\n- B 着手"
  content_type: "markdown"
  title: "進捗"
```

### 2. ログをリアルタイム監視 (CLI のみ)

```bash
vp file watch /tmp/build.log right --format json_lines --filter "INFO|WARN|ERROR"
# 停止: vp file unwatch right
```

→ 新規行が出るたびに Canvas pane に追記。 MCP tool (`watch_file`) は撤去済み、 CLI のみ。

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
# nudge は CLI で (MCP に lane_nudge は無い):
#   vp lane nudge <project>/performer/feat-api "task が届いています。 wire_recv で確認して着手。"
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

## MCP Tools 一覧 (VP v0.45+、 全 20 個 — surface は v0.44 から不変)

### Display / Canvas (Paisley Park 🧭)

| Tool | 用途 |
|------|------|
| `show` | コンテンツ表示 (markdown/html/log/url)。 全 show は現 lane の PP body stack に積まれる |
| `clear` | pane content clear |
| `read_pane` | Canvas pane の full source を取得 (memory 保存向け) |
| `list_canvas` | Canvas 上の pane 一覧 (title / content_type / preview) |
| `switch_lane` | vp-app の active lane 切替 (`conductor` or performer name) |
| `capture_canvas` | vp-app window 全体の PNG capture |

### Performer Lane (Stone Free 🧵)

| Tool | 用途 |
|------|------|
| `add_performer` | performer lane を spawn (worktree + echoes)。 `stand` / `base` / `model` 指定可。 旧名 `add_wing` / `add_worker` |
| `delete_performer` | performer lane を片付け (PTY/workspace cleanup、 `cleanup: false` で dir 残置)。 旧名 `delete_wing` / `delete_worker` |
| `list_lanes` | project 内全 Lane 一覧 (Conductor + Performers、`performer_status` / `mailbox_addresses` 付き)。 `kind` / `state` filter 可 |

> lane への text 注入 (`lane_nudge`) と console 読み取りは **CLI のみ**: `vp lane nudge <lane> <text>` / `vp lane capture <lane>`

### dev-flow primitives

| Tool | 用途 |
|------|------|
| `flow_handoff` | performer 作成 + wire_send + nudge を atomic (= 失敗時 rollback)。 `mode` (hitl default / auto)、 `stand` / `base` / `model` / `nudge` 指定可 |
| `flow_progress` | 全 performer の git status + unread wire + `flow_state` (6 state) / `control_surrender` 集約 |

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

### Process

| Tool | 用途 |
|------|------|
| `restart` | VP Process restart (session 状態保持) |

**MCP には存在しない（CLI のみ）**: pane 操作 (`vp pane toggle/close/split`)、 file 監視 (`vp file watch/unwatch`)、 port 管理 (`vp port`)、 lane nudge / capture (`vp lane nudge` / `vp lane capture`)

**廃止済** (旧 doc に残っていたもの、 #625 tool 整理ほか):
- `tmux_split` / `tmux_capture` / `tmux_dashboard` / `tmux_agent_*` → `vp lane nudge` / `vp lane capture`
- `add_wing` / `delete_wing` → `add_performer` / `delete_performer`
- `open_canvas` / `close_canvas` / `split_pane` (MCP) → vp-app 常駐 Canvas + Frame Engine
- `eval_ruby` / `run_ruby` / `stop_ruby` / `list_ruby` → 削除
- `capture_terminal` → `vp shot`
- `toggle_pane` / `close_pane` / `watch_file` / `unwatch_file` / `port_*` / `permission` (MCP) → CLI 側に集約 or 削除

---

## MCP ↔ CLI pair invariant

VP は **「同じ logic を MCP (= AI agent 用) + CLI (= human 用) 両方から expose する」** を invariant として持つ。

### pair table (主要)

| MCP tool | CLI subcommand | 備考 |
|---|---|---|
| `show` | `vp pane show <content>` | `--format` / `--title`。 `--append` は CLI のみ |
| `clear` | `vp pane clear` | `--pane-id` |
| `switch_lane` | `vp lane switch <name>` | `conductor` or performer name |
| `add_performer` | `vp lane new <name> <branch>` | `--isolation worktree\|clone` は CLI のみ |
| `delete_performer` | `vp lane rm <name>` | |
| `list_lanes` | `vp lane ls --detail` | default `vp lane ls` は fs scan 簡易出力 |
| `flow_handoff` | `vp flow handoff <name> --task-spec <file>` | `--mode auto\|hitl` (default hitl) / `--no-nudge` |
| `flow_progress` | `vp flow progress` | `--format json\|table` |
| `wire_send` | `vp wire send` | `--to` / `--body` / `--reply-to` / `--category` / `--world` |
| `wire_recv` | `vp wire recv` | 連続 subscribe は `vp wire watch` |
| `wire_inbox` | `vp wire inbox` | read-only |
| `wire_ack` | `vp wire ack` | |
| `wire_thread` | `vp wire thread` | |
| `capture_canvas` | `vp shot` | CLI は canonical screenshot |
| `restart` | `vp restart-all` | 全 Process + TheWorld 再起動 |

**CLI のみ（MCP pair なし）**: `vp lane nudge <lane> <text>` / `vp lane capture <lane>` / `vp pane toggle|close|split` / `vp file watch|unwatch` / `vp port show|url|roles|layout|slot`

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
        ├── Echoes 💬 — Coding Assistant (Claude CLI。 Act I = TUI console / Act II = chat GUI + HITL 4 面: 質問 / 中断 / permission / plan 承認 — v0.45)
        ├── Paisley Park 🧭 — Information Navigator (Canvas / WebView + Frame Engine)
        ├── Gold Experience 🌿 — Code Runner (process 管理)
        └── (per slot) Lane — PTY セッション (Conductor + Performers)
              ├── The Hand 🤚 — 素 shell base
              └── Echoes 💬 — 任意 LLM auto-launch
```

詳細メンタルモデル: `mem_1CaVnfJRgWtuRgZD9yQSoV` (舞台-役者-演目)

---

## Canvas の表示モデル (PP Canvas Stack)

Canvas は **vp-app 常駐の統合ウィンドウ**。 lane ごとに PP (Paisley Park) body を持ち、 `show` されたコンテンツは現 lane の **PP body stack に積まれる**（doc 19 PP Canvas Stack Model）。

- `show` の `pane_id` は**現在無視される**（dead field、 後方互換で残置）。 旧 3-pane (main/left/right) モデルは廃止
- `append` パラメータは MCP には無い（CLI `vp pane show --append` のみ）
- lane の切替は `switch_lane`（conductor / performer name）

---

## コンテンツタイプ (`show` の content_type)

| タイプ | 説明 |
|--------|------|
| `markdown` | Markdown 形式 (**デフォルト・推奨**) |
| `html` | HTML 形式 |
| `log` | ログ形式 (追記向け) |
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
| `wire_*` が動かない | SP 起動確認 (`vp app start` → sidebar expand)、 wire address 再確認 (`agent@<project>` / `agent@<project>/<performer>`) |
| command msg が何度も nudge される | 受信側が `wire_ack` を忘れている |
| 1 lane に claude session が 2 つ並走 (二重 dispatch) | v0.45 で根治 (create の reservation が同 addr の並行 create を reject)。 v0.44 以前なら VP を更新 |

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

## 開発・dogfooding tip (maintainer 向け)

- GUI 変更の実機確認は `mise run app:swap`（DRY build → `/Applications/VantagePoint.app` 差し替え → 起動）
- log は XDG state zone: `~/.local/state/vp/log/`（旧 `~/Library/Logs/Vantage/` は撤去済み）
- daemon 再起動は 2 種: `vp daemon stop` = gentle（SP 温存）/ cascade（daemon + SP 全停止）— lane 内から検証する時は gentle 側

---

## 関連

- **dev-flow skill**: `skills/dev-flow/SKILL.md` — Conductor × Performer orchestration 6 phase
- **詳細リファレンス**: `reference/mcp-tools.md`
- **VP リポジトリ**: https://github.com/chronista-club/vantage-point
