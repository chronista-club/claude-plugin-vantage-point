---
name: vantage-point
description: AI ネイティブ開発環境 — Canvas 視覚化、並列 worker 展開、inter-agent 通信を実現する MCP server。Claude Code 用 dashboard tool
version: 0.17.0
tags:
  - dashboard
  - canvas
  - tmux
  - mcp
  - inter-agent
---

# Vantage Point

> **AI ネイティブ開発環境** — Claude Code セッション中に Canvas 視覚化、 並列 worker 展開、 inter-agent 通信を実現する MCP server。

VP は単なる「ブラウザビューア」 ではなく、 開発体験そのものを構成する 5 つの柱を提供する:

1. **Canvas** で markdown / HTML / URL / ログを視覚化 (Paisley Park 🧭)
2. **tmux 統合** で並列 worker / agent を展開・監視 (Hermit Purple 🍇)
3. **wiremsg** で project 跨ぎ inter-agent 通信 (ccwire / msgbox は廃止、 wiremsg に一本化)
4. **Port 管理** で project slot × lane × role の決定論的 port 配置
5. **Screenshot** で UI 状態を PNG 化、 Read tool で AI が視認

詳細 architecture: 関連 memory `mem_1CaVnfJRgWtuRgZD9yQSoV` (舞台-役者-演目 mental model)

---

## クイックスタート

```bash
# vp-app GUI を起動 (TheWorld:32000 が無ければ auto-launch)
vp app

# project SP の起動は vp-app sidebar から expand → auto-spawn
```

VP Process が起動していなくても、 MCP ツールを呼ぶと自動的に Process が起動する。

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

### 3. 並列 worker 展開 (tmux pane に Claude 等を起こす)

```
mcp__vantage-point__tmux_split
  command: "claude --continue"
  label: "worker-A"
mcp__vantage-point__tmux_capture
  pane_id: "<返ってきた pane id>"
```

`tmux_dashboard` で全 pane を Canvas markdown dashboard 化、 worker 進捗を 1 view で監視。

### 4. project 跨ぎ inter-agent 通信 (wiremsg)

```
# 送信 (reply_to なし = 新規 thread の root)
mcp__vantage-point__wire_send
  to: ["agent@creo-memories"]
  body: { "text": "review request" }

# 受信 (自分が参加する全 wire thread の未読 message、 timeout 待ち)
mcp__vantage-point__wire_recv
  timeout: 10

# thread 系譜の取得 (指定 message から prev を root まで辿る)
mcp__vantage-point__wire_thread
  message_id: "<message id>"
```

ccwire / msgbox は廃止、 wiremsg に一本化。 wire address は `agent@<project>` (lead) /
`agent@<project>/<lane>` (wing) 形式。 thread は `prev` parent-pointer で表現される (`thread_id` は無い)。

### 5. UI スクショで AI 自身が視認

```
mcp__vantage-point__capture_terminal
  output_path: "/tmp/vp-shot.png"
```

→ Read tool で PNG を視覚 review 可能、 UI 変更の review / debug に有用。

---

## MCP Tools 一覧 (31 個、 wiremsg 移行後の状態)

### Display / Canvas (Paisley Park 🧭)

| Tool | 用途 |
|------|------|
| `show` | コンテンツ表示 (markdown/html/log/url)、 v0.17.0 で show-subscriber 経由 PP body markdown 表示が landing |
| `clear` | pane content clear |
| `toggle_pane` | left/right pane 表示切替 |
| `close_pane` | pane を閉じる |
| `switch_lane` | Canvas の表示プロジェクト切替 |
| `watch_file` | ログ file をリアルタイム表示 (JSON Lines / plain text) |
| `unwatch_file` | 監視停止 |
| `list_lanes` | project 内 Lane 一覧取得 (Lead + Worker、 Frame Engine 連動) |

### tmux 並列開発 (Hermit Purple 🍇)

| Tool | 用途 |
|------|------|
| `tmux_split` | pane 分割で worker 展開 (任意 command 起動) |
| `tmux_capture` | pane 出力を text 取得 (1 pane or 全 pane) |
| `tmux_dashboard` | 全 pane を Canvas markdown dashboard 化 |
| `tmux_agent_deploy` | agent metadata (label/status/task) 付きで pane 展開 |
| `tmux_agent_status` | agent status 更新 (running/waiting/done/error) |
| `tmux_agent_send` | pane に input 送信 (`\n` で Enter) |

### Screenshot

| Tool | 用途 |
|------|------|
| `capture_canvas` | Canvas window の PNG capture |
| `capture_terminal` | VantagePoint.app terminal window の PNG capture |

### Ruby VM (Gold Experience 🌿)

| Tool | 用途 |
|------|------|
| `eval_ruby` | 短命 Ruby 実行 (script / data processing) |
| `run_ruby` | 長期 Ruby daemon (Canvas pane に streaming) |
| `stop_ruby` | daemon 停止 (graceful shutdown) |
| `list_ruby` | 実行中 daemon 一覧 |

### Process / Permission

| Tool | 用途 |
|------|------|
| `permission` | tool 実行 permission 要求 (user 確認 dialog) |
| `restart` | VP Process restart (session 状態保持) |

### Worker workspace (Whitesnake 🐍 連動)

| Tool | 用途 |
|------|------|
| `add_worker` | Worker workspace を spawn (branch + ahead-behind + dirty 状態 sidebar 表示) |
| `delete_worker` | Worker workspace を片付け (merge 確認・dirty 警告込み) |

### wiremsg (inter-agent 通信、 ccwire / msgbox 廃止 → wiremsg に一本化)

| Tool | 用途 |
|------|------|
| `wire_send` | wire address (`agent@<project>` / `agent@<project>/<lane>`) に送信。 `reply_to` なし = 新規 thread の root、 あり = その thread への reply (reply-all 展開) |
| `wire_recv` | 自分が参加する全 wire thread の未読 message を受信 (timeout 指定可、 読むと cursor 前進) |
| `wire_thread` | 指定 message から `prev` を root まで辿った系譜 (ancestor-chain、 root-first) を取得。 cursor は触らない |

### Port management (slot × lane × role)

| Tool | 用途 |
|------|------|
| `port_show` | slot × lane × role → port (deterministic) |
| `port_url` | localhost URL 生成 (`http://localhost:{port}`) |
| `port_roles` | role → offset table (agent/dev_server/db_admin/canvas/preview) |
| `port_layout` | 1 project slot の全 port 配置 (Markdown) |

---

## アーキテクチャ概要

```
TheWorld 👑 (32000) — 常駐 daemon、 全 SP + HP を管理
  │
  ├── Hermit Purple 🍇            — External Control (MIDI / tmux / MCP) ← LSCM PR-α で World 階層に物理移管
  │
  └── Star Platinum ⭐ (project SP, 33xxx) — Project 単位の容器
        ├── Echoes 💬 (旧 HD)        — Coding Assistant (Claude CLI / 任意 LLM、 v0.17.0 で `Heaven's Door 📖` から rename)
        ├── Paisley Park 🧭          — Information Navigator (Canvas / WebView、 v0.17.0 で Lane 階層に物理移管 + Frame Engine)
        ├── Gold Experience 🌿       — Code Runner (Ruby VM)
        └── (per slot) Lane          — PTY セッション (Lead + Worker)
              ├── The Hand 🤚        — 素 shell base
              └── Echoes 💬          — 任意 LLM auto-launch (init_script 駆動、 doc 11)
```

詳細メンタルモデル: `mem_1CaVnfJRgWtuRgZD9yQSoV` (舞台-役者-演目)

---

## ペイン構成 (Canvas 内部)

Canvas は **タブ付き統合ウィンドウ**。 各タブが project を表し、 タブ内に複数の pane が並ぶ:

```
┌─[Tab: project A]──[Tab: project B]──┐
│                                      │
│  ┌── main ──┐  ┌── right ──┐         │
│  │ markdown │  │ logs      │         │
│  └──────────┘  └───────────┘         │
│                                      │
└──────────────────────────────────────┘
```

### Pane ID

| ID | 用途 |
|----|------|
| `main` | メインコンテンツ (default) |
| `left` | 左サイドパネル (常用: creo-memories 等) |
| `right` | 右サイドパネル (常用: ログ / preview) |

`switch_lane` で別 project のタブに切替、 `toggle_pane` で left/right 表示切替。

---

## コンテンツタイプ (`show` の content_type)

| タイプ | 説明 |
|--------|------|
| `markdown` | Markdown 形式 (**デフォルト・推奨**) |
| `html` | HTML 形式 (精密なレイアウトが必要な場合のみ) |
| `log` | ログ形式 (追記向け、 `append: true` と組合せ) |
| `url` | 外部 URL を iframe で埋め込み表示 |

> **ベストプラクティス**: `show` では `content_type='markdown'` をデフォルトとして使用。 Markdown は Canvas で見やすく描画される。 `html` は精密なビジュアル (ダッシュボード、色付きダイアグラム、インタラクティブ要素) が必要な場合のみ使う。

---

## トラブルシューティング

| 症状 | 対処 |
|------|------|
| SP が「stale」 (sidebar 緑だが console 壊れ) | vp-app sidebar の hover で出る 🔄 (Restart SP) ボタン |
| Lane が dead 化 (claude zombie) | Lifecycle monitor が 5s 以内に検知 → sidebar 赤 dot 表示 → 手動 respawn |
| ghost characters (xterm.js 残留文字) | known issue (`mem_1CaVpvsBKR3ckieRXo1nwr`)、 Phase 6+ で対処予定 |
| `mcp_call timeout` | Process restart で復旧、 5s timeout は QUIC 経路で発生 |
| `wire_*` 系 commands が動かない | SP が起動しているか確認 (`vp app` で sidebar から expand → auto-spawn)、 宛先 wire address の表記を再確認 (`agent@<project>` / `agent@<project>/<lane>`) |

---

## Phase 5-D 以降の変更点

### v0.17.0 (2026-05-08): Frame Engine + Live Token + B 達成

- **3D Frame Layout Engine** (PR-ε-1, #292): Pane を「subdivision」 ではなく **portable 3D オブジェクト** として inversion。 4 default Scene (lead-focus / side-review / pp-overlay / pp-focus) + Ctrl+Shift+1..4 で切替、 ]/[ で cycle
- **PP body markdown 表示 = B 達成** (PR-ε-3, #298): `mcp__show` → state.hub.broadcast → `/ws` → show-subscriber → `vpPP.renderPP` → `#pp-content innerHTML` の 6 段 pipeline 物理化。 doc 13 「PP は Information Router」 概念の最 minimal 実装が landing
- **Live Token pattern** 体系化 (#300, #301): `--frame-transition-ms` で確立した CSS variable + MutationObserver pattern を terminal 5 token (fontSize / line-height / letter-spacing / font-family / cursor-style) に展開、 creo-ui-editor-host から runtime 編集可能
- **per-Lane Scene state preservation** (#294): Lane 切替で Scene layout を維持 (`Map<LaneAddress, SceneId>`)
- **deps upgrade**: Rust 1.94 → 1.95 + 13 crate latest bump (#296) + rmcp 0.16 → 1.6 (#297)
- **DX flush** (#295): mise task `vp:*` → `app:*` rename、 daemon:start 完全 background detach、 cargo install --path で codesigned binary を `~/.cargo/bin/` 配置
- **vp mcp critical fix** (#302): `port_roles` tool の inputSchema を schemars 1.x `{const:null}` 拒否対応 (rmcp 1.6 strict validation 適合)

### Phase 5-D (2026-04-28)

- **Worker workspace lifecycle UI**: sidebar の Worker 行に branch / ahead-behind / dirty / merged の git 状態を inline 表示
- **dual-stack listen**: TheWorld + SP が IPv4 + IPv6 両対応 (`http://[::1]:32000` も使える)
- **claude --continue fallback**: lane spawn で early exit 検知 → 新規 session で respawn
- **Lane lifecycle monitor**: post-spawn zombie 検知 (5s 間隔)
- **Restart SP UI**: sidebar の 🔄 button から SP 再起動 (vp-app は落ちない)

---

## 使用例 (詳細)

### Markdown を表示 (タブタイトル付き)

```typescript
mcp__vantage-point__show({
  content: "# 調査結果\n\n- 項目1\n- 項目2",
  pane_id: "right",
  title: "Research"
})
```

### URL ページを iframe 埋め込み

```typescript
mcp__vantage-point__show({
  content: "https://example.com",
  content_type: "url",
  pane_id: "right",
  title: "Preview"
})
```

### 追記モード (ログ等)

```typescript
mcp__vantage-point__show({
  content: "追加のログ行",
  content_type: "log",
  append: true
})
```

### ログファイル監視

```typescript
mcp__vantage-point__watch_file({
  path: "/path/to/trace.log",
  pane_id: "right",
  format: "json_lines",
  filter: "INFO|WARN|ERROR",
  title: "Trace Log"
})
```

### Ruby VM (Gold Experience 🌿)

```typescript
// 短命: 直接実行
mcp__vantage-point__eval_ruby({
  code: "puts 'Hello from Ruby!'\nputs 1 + 2",
  pane_id: "main"
})

// 長期: デーモン起動 (出力 streaming)
mcp__vantage-point__run_ruby({
  code: "loop { puts Time.now; sleep 1 }",
  name: "clock",
  pane_id: "right"
})
// → process_id "rb-0001" が返る

// 一覧 + 停止
mcp__vantage-point__list_ruby()
mcp__vantage-point__stop_ruby({ process_id: "rb-0001" })
```

### Pane visibility 操作

```typescript
// 任意のペインを非表示に
mcp__vantage-point__toggle_pane({
  pane_id: "right",
  visible: false
})

// visible 省略でトグル
mcp__vantage-point__toggle_pane({ pane_id: "main" })
```

---

## 関連 memory (詳細設計)

- VP Roadmap Phase 5→9 (`mem_1CaVeQEKXd8U2XHn75RD4M`) — implementation 計画
- Mental model 舞台-役者-演目 (`mem_1CaVnfJRgWtuRgZD9yQSoV`) — TH/HD/Profile の関係性
- Hub federation 仕様 (`mem_1CaVeTysipdgVHoxwxUcPj`, chronista-club Atlas) — Phase 7+
- 4 scope architecture (`mem_1CaSugEk1W2vr5TAdfDn5D`) — App/Project/Lane/Pane
- wire address spec — `agent@<project>` (lead) / `agent@<project>/<lane>` (wing)、 `notify@<project>` 等の actor slot

---

## 開発・dogfooding tip

- VP 自体の dogfooding は `mr app` (mise) で起動、 `~/Library/Logs/Vantage/vp-{world,app}.kdl.log` を tail
- SP のみ再起動: `mise run sp-kill` で全 SP graceful kill、 expand すれば auto-respawn
- 全部 fresh start: `VP_FORCE_RESTART_DAEMON=1 VP_FORCE_RESTART_SP=1 mr app`

---

## 関連

- **詳細リファレンス**: `reference/mcp-tools.md` (TODO: 各 tool の引数 schema)
- **VP リポジトリ**: https://github.com/chronista-club/vantage-point
