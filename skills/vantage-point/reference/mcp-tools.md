# Vantage Point MCPツール リファレンス

## 概要

Vantage Pointはブラウザビューアやネイティブ Canvas にリッチコンテンツを表示するMCPサーバーです。

**MCPサーバー名**: `vantage-point`

Process が起動していない場合、MCPツール呼び出し時に自動的に Process を起動します（自動起動リレー）。

---

## ツール一覧

### show

コンテンツをビューアに表示します。

```typescript
mcp__vantage-point__show({
  content: "表示するコンテンツ",   // 必須
  content_type: "markdown",        // オプション: markdown(デフォルト), html, log, url
  pane_id: "main",                 // オプション: main(デフォルト), left, right, pane-*
  append: false,                   // オプション: 追記モード
  title: "タブタイトル"            // オプション: ペインのタブ表示名
})
```

**パラメータ**:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `content` | string | ✓ | 表示するコンテンツ |
| `content_type` | string | - | `markdown`(デフォルト), `html`, `log`, `url`（iframe埋め込み） |
| `pane_id` | string | - | `main`(デフォルト), `left`, `right`, または `split_pane` で生成されたID |
| `append` | boolean | - | `true`で既存コンテンツに追記 |
| `title` | string | - | ペインのタブに表示するタイトル。省略時はpane_idを使用 |

---

### clear

指定したペインのコンテンツをクリアします。

```typescript
mcp__vantage-point__clear({
  pane_id: "main"    // オプション: クリアするペインID
})
```

**パラメータ**:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `pane_id` | string | - | `main`(デフォルト), `left`, `right` |

---

### toggle_pane

ペインの表示/非表示を切り替えます。Canvas 内の任意のペイン（`main`, `split_pane` で生成されたペイン等）に対応します。

```typescript
mcp__vantage-point__toggle_pane({
  pane_id: "main",   // 必須: 対象のペインID
  visible: true      // オプション: 明示的に表示/非表示を指定
})
```

**パラメータ**:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `pane_id` | string | ✓ | 対象のペインID（`main`, `left`, `right`, `pane-*`） |
| `visible` | boolean | - | `true`=表示, `false`=非表示, 省略=トグル |

Split レイアウト内のペインを非表示にすると、残りのペインが全幅に拡張されます。再表示で split レイアウトに復帰します。

---

### close_pane

ペインを閉じます。

```typescript
mcp__vantage-point__close_pane({
  pane_id: "pane-abc12345"   // 必須: 閉じるペインのID
})
```

**パラメータ**:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `pane_id` | string | ✓ | 閉じるペインのID |

---

### capture_canvas

Canvas ウィンドウのスクリーンショットを PNG ファイルとして保存します。Canvas が起動していない場合は自動起動します。保存されたファイルは Claude の Read ツールで画像として閲覧できます。

```typescript
mcp__vantage-point__capture_canvas({
  path: "/tmp/screenshot.png",   // オプション: 保存先パス（デフォルト: /tmp/vp-canvas-{timestamp}.png）
  pane_id: "main"                // オプション: 特定ペインのみキャプチャ
})
```

**パラメータ**:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `path` | string | - | PNG ファイルの保存先パス。省略時は `/tmp/vp-canvas-{timestamp}.png` |
| `pane_id` | string | - | 特定のペインのみキャプチャする場合のペインID |

**戻り値**:

```json
{
  "path": "/tmp/vp-canvas-20260224-123456.png",
  "width": 1920,
  "height": 1080,
  "size_bytes": 123456
}
```

---

### watch_file

ログファイルを監視し、新しい行をリアルタイムでペインに表示します。

```typescript
mcp__vantage-point__watch_file({
  path: "/path/to/file.log",       // 必須: 監視するファイルの絶対パス
  pane_id: "right",                // 必須: 表示先のペインID
  format: "json_lines",            // オプション: json_lines(デフォルト), plain
  filter: "INFO|WARN|ERROR",       // オプション: レベルフィルタ（正規表現）
  exclude_targets: ["noisy_mod"],  // オプション: 除外するターゲット名
  title: "App Log",                // オプション: ペインのタブタイトル
  style: "terminal"                // オプション: terminal(デフォルト), plain
})
```

**パラメータ**:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `path` | string | ✓ | 監視するログファイルの絶対パス |
| `pane_id` | string | ✓ | 表示先のペインID |
| `format` | string | - | `json_lines`(デフォルト) または `plain` |
| `filter` | string | - | ログレベルのフィルタ正規表現（例: `INFO\|WARN\|ERROR`） |
| `exclude_targets` | string[] | - | 表示から除外するターゲット名のリスト |
| `title` | string | - | ペインのタブに表示するタイトル |
| `style` | string | - | `terminal`(デフォルト) または `plain` |

---

### unwatch_file

ペインのファイル監視を停止します。

```typescript
mcp__vantage-point__unwatch_file({
  pane_id: "right"   // 必須: 監視を停止するペインID
})
```

**パラメータ**:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `pane_id` | string | ✓ | 監視を停止するペインID |

---

### eval_ruby

Rubyコードまたはファイルを実行し、結果をペインに表示します。短命実行（スクリプト、データ処理）向け。

```typescript
mcp__vantage-point__eval_ruby({
  code: "puts 'Hello'",    // code または file のどちらか必須
  file: "scripts/run.rb",  // code と排他
  pane_id: "main"           // オプション: 結果の表示先ペイン
})
```

**パラメータ**:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `code` | string | △ | 実行するRubyコード（`file` と排他） |
| `file` | string | △ | 実行するRubyファイルパス（プロジェクトディレクトリ相対、`code` と排他） |
| `pane_id` | string | - | 結果の表示先ペインID（デフォルト: `main`） |

**戻り値**: stdout, stderr, exit_code, 実行時間を含むテキスト。

---

### run_ruby

Rubyコードまたはファイルをデーモンプロセスとして起動します。出力はペインにリアルタイムストリーミングされます。

```typescript
mcp__vantage-point__run_ruby({
  code: "loop { puts Time.now; sleep 1 }",  // code または file のどちらか必須
  file: "scripts/server.rb",                 // code と排他
  name: "my-server",                         // オプション: プロセス表示名
  pane_id: "right"                           // オプション: 出力先ペイン
})
```

**パラメータ**:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `code` | string | △ | デーモンとして実行するRubyコード（`file` と排他） |
| `file` | string | △ | デーモンとして実行するRubyファイルパス（`code` と排他） |
| `name` | string | - | プロセスの表示名（デフォルト: ファイル名 or `daemon`） |
| `pane_id` | string | - | 出力ストリーミング先ペインID（デフォルト: `main`） |

**戻り値**: プロセスID（`rb-0001` 形式）。`stop_ruby` で停止に使用。

---

### stop_ruby

実行中のRubyデーモンプロセスを停止します。

```typescript
mcp__vantage-point__stop_ruby({
  process_id: "rb-0001"   // 必須: 停止するプロセスID
})
```

**パラメータ**:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `process_id` | string | ✓ | 停止するRubyプロセスID（`list_ruby` で確認可能） |

---

### list_ruby

実行中のRubyデーモンプロセス一覧を表示します。

```typescript
mcp__vantage-point__list_ruby()
```

**パラメータ**: なし

**戻り値**: プロセスID、名前、ペインID、ステータスの一覧。

---

### tmux_split

tmux ウィンドウを分割して新しいペインを作成します。worker 起動や並列 Claude Code セッション作成に使います。

```typescript
mcp__vantage-point__tmux_split({
  horizontal: true,                        // オプション: 水平分割(true, デフォルト) or 垂直分割(false)
  command: "claude --dangerously-skip-permissions"  // オプション: 新ペインで実行するコマンド
})
```

**パラメータ**:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `horizontal` | boolean | - | `true`(デフォルト)=水平分割, `false`=垂直分割 |
| `command` | string | - | 新しいペインで実行するコマンド。省略時はデフォルトシェル |

**戻り値**: 新しいペインID（例: `%1`）とコマンド名。

---

### tmux_capture

tmux ペインのターミナル出力をテキストとしてキャプチャします。AI エージェントが他のペインの状態を把握するのに使います。

```typescript
mcp__vantage-point__tmux_capture({
  pane_id: "%0"    // オプション: ペインID。省略すると全ペインをキャプチャ
})
```

**パラメータ**:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `pane_id` | string | - | tmux ペインID（例: `%0`）。省略時は全ペインをキャプチャ |

**戻り値**: 各ペインのID・コマンド名・ターミナル出力テキスト。

---

### tmux_dashboard

全 tmux ペインをキャプチャして Canvas に markdown ダッシュボードとして表示します。並列ワーカーの監視に最適です。

```typescript
mcp__vantage-point__tmux_dashboard()
```

**パラメータ**: なし

**戻り値**: Canvas に表示されたペイン数。

---

### switch_lane

Canvas の表示プロジェクト（Lane）を切り替えます。

```typescript
mcp__vantage-point__switch_lane({
  lane: "vantage-point"   // 必須: 切り替え先のプロジェクト名
})
```

**パラメータ**:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `lane` | string | ✓ | プロジェクト名（例: `vantage-point`, `creo-memories`） |

---

### capture_terminal

VantagePoint.app のターミナルウィンドウを PNG スクリーンショットとして保存します。保存されたファイルは Claude の Read ツールで画像として閲覧できます。

```typescript
mcp__vantage-point__capture_terminal({
  path: "/tmp/vp-terminal.png"   // オプション: 保存先パス
})
```

**パラメータ**:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `path` | string | - | PNG ファイルの保存先パス。省略時は `/tmp/vp-terminal-{timestamp}.png` |

---

### tmux_agent_deploy

Stand エージェント（Moody Blues, Sticky Fingers 等）を新しい tmux ペインにデプロイします。

```typescript
mcp__vantage-point__tmux_agent_deploy({
  label: "Moody Blues",                                      // 必須: エージェントラベル
  command: "claude --dangerously-skip-permissions",          // オプション: 実行コマンド
  task_description: "PR #42 のコードレビュー"                // オプション: タスク説明
})
```

**パラメータ**:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `label` | string | ✓ | エージェント名（例: `Moody Blues`, `Sticky Fingers`） |
| `command` | string | - | 新ペインで実行するコマンド |
| `task_description` | string | - | エージェントが実行するタスクの説明 |

---

### tmux_agent_status

デプロイ済みの Stand エージェント一覧を表示します。

```typescript
mcp__vantage-point__tmux_agent_status()
```

**パラメータ**: なし

---

### tmux_agent_send

デプロイ済みエージェントにテキストコマンドを送信します。

```typescript
mcp__vantage-point__tmux_agent_send({
  pane_id: "%1",           // 必須: 送信先 tmux ペイン ID
  text: "レビューを開始"    // 必須: 送信テキスト
})
```

**パラメータ**:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `pane_id` | string | ✓ | tmux ペイン ID（例: `%1`） |
| `text` | string | ✓ | 送信するテキスト |

---

### restart

Vantage Pointサーバーを再起動します。セッション状態は保持されます。

```typescript
mcp__vantage-point__restart({
  open_viewer: false   // オプション: 再起動後にビューアを開く
})
```

**パラメータ**:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `open_viewer` | boolean | - | `true`でビューア自動オープン |

---

### permission

ツール実行の権限をユーザーに確認します（Claude CLI --permission-prompt-tool用）。

```typescript
mcp__vantage-point__permission({
  tool_name: "実行するツール名",   // 必須
  input: { ... }                   // 必須: ツールの入力パラメータ
})
```

**戻り値**:

```json
{
  "behavior": "allow",        // allow または deny
  "updatedInput": { ... },    // 更新された入力（オプション）
  "message": "..."            // メッセージ（オプション）
}
```

---

### add_worker / delete_worker (v0.17.0)

Worker workspace の lifecycle 管理。 `ccws` (clone-based isolated workspace) を MCP 経由で操作。

```typescript
mcp__vantage-point__add_worker({
  name: "feature-x",        // 必須: workspace 名 (Lane address 一部)
  branch: "mako/feature-x"  // オプション: 起動 branch
})

mcp__vantage-point__delete_worker({
  name: "feature-x",        // 必須
  force: false              // オプション: dirty/unmerged を上書き削除
})
```

**戻り値 (`add_worker`)**: spawn された Lane address、 path、 状態 (branch/ahead-behind/dirty)。

---

### list_lanes (v0.17.0)

project 内の Lane 一覧取得 (Lead + Worker)。 sidebar UI / Frame Engine の lookup と整合。

```typescript
mcp__vantage-point__list_lanes()
```

**戻り値**: Lane address・branch・git 状態 (ahead-behind/dirty/merged) の配列。

---

### msg_* (Msgbox / inter-agent 通信、 旧 ccwire 置換)

actor address `{actor}@{project}` 形式で project 跨ぎ通信。 `mem_1CaBRBdh1PGop2iGLAnwSY` 参照。

| Tool | 主要パラメータ | 用途 |
|------|---------------|------|
| `msg_send` | `address`, `message`, `manual_ack?`, `reply_to?` | 送信 (default fire-and-forget、 `manual_ack: true` で persistent) |
| `msg_recv` | `timeout?`, `actor?` | 受信 (default 0s 即時、 timeout 指定で blocking poll) |
| `msg_ack` | `message_id` | manual_ack message を ack (persistent message のみ) |
| `msg_broadcast` | `message`, `actor_filter?` | 全 peer に broadcast (best-effort) |
| `msg_thread` | `message_id` | reply_to chain 全体取得 (persistent message のみ) |
| `msg_peers` | (なし) | 同 process の addresses |
| `msg_directory` | (なし) | 全 process の actor 一覧 (TheWorld registry 経由) |

```typescript
// 代表例: send + recv
mcp__vantage-point__msg_send({
  address: "agent@creo-memories",
  message: "review request"
})
mcp__vantage-point__msg_recv({ timeout: 10 })
```

---

### port_* (Port 管理、 slot × lane × role 決定論)

| Tool | 主要パラメータ | 用途 |
|------|---------------|------|
| `port_show` | `slot`, `lane`, `role` | port 番号を計算 (deterministic) |
| `port_url` | `slot`, `lane`, `role` | localhost URL を生成 (`http://localhost:{port}`) |
| `port_roles` | (なし) | role → offset table (`agent`/`dev_server`/`db_admin`/`canvas`/`preview`) |
| `port_layout` | `slot` | 1 slot の全 port 配置を Markdown 表で取得 |

```typescript
mcp__vantage-point__port_show({ slot: 0, lane: "lead", role: "dev_server" })
// → { port: 33010, ... }
```

---

## 使用シナリオ

### Frame Engine Scene 切替 (v0.17.0)

```typescript
// PP body markdown を表示 (B 達成 pipeline)
mcp__vantage-point__show({
  content: "# 進捗\n- A 完了\n- B 着手",
  pane_id: "main",
  content_type: "markdown"
})
// → show-subscriber 経由で vpPP.renderPP に届き、 #pp-content に innerHTML 反映

// Frame Engine Scene の切替は vp-app の keyboard shortcut:
//   Ctrl+Shift+1 → lead-focus
//   Ctrl+Shift+2 → side-review
//   Ctrl+Shift+3 → pp-overlay
//   Ctrl+Shift+4 → pp-focus
//   Ctrl+Shift+] / [ → cycle
// Lane 切替で per-Lane Scene state が保持される。
```

### ログストリーミング

```typescript
// 初期化
mcp__vantage-point__show({
  content: "=== Build Log ===\n",
  content_type: "log",
  pane_id: "main"
})

// ログを追記
mcp__vantage-point__show({
  content: "[INFO] Compiling...\n",
  content_type: "log",
  append: true
})
```

### リアルタイムログ監視

```typescript
// ペインを分割してログを表示
mcp__vantage-point__split_pane({ direction: "vertical" })
// → "pane-abc12345" が返る

// 分割したペインでログファイルを監視
mcp__vantage-point__watch_file({
  path: "/tmp/app-trace.log",
  pane_id: "pane-abc12345",
  format: "json_lines",
  filter: "WARN|ERROR",
  title: "App Trace"
})

// 監視を停止して閉じる
mcp__vantage-point__unwatch_file({ pane_id: "pane-abc12345" })
mcp__vantage-point__close_pane({ pane_id: "pane-abc12345" })
```

### tmux で並列ワーカー管理

```typescript
// 新しいペインを作成して Claude Code を起動
mcp__vantage-point__tmux_split({
  horizontal: true,
  command: "claude --dangerously-skip-permissions"
})
// → "New pane created: %1 (claude)"

// 全ペインの出力を確認
mcp__vantage-point__tmux_capture()

// Canvas にダッシュボードとして可視化
mcp__vantage-point__tmux_dashboard()
```

### Ruby VM でデータ処理

```typescript
// Rubyスクリプトを実行してCanvasに結果表示
mcp__vantage-point__eval_ruby({
  code: "require 'json'\ndata = {a: 1, b: 2}\nputs JSON.pretty_generate(data)",
  pane_id: "right"
})

// 長時間実行のサーバーを起動
mcp__vantage-point__run_ruby({
  file: "scripts/watcher.rb",
  name: "file-watcher",
  pane_id: "right"
})

// プロセス一覧で確認
mcp__vantage-point__list_ruby()

// 停止
mcp__vantage-point__stop_ruby({ process_id: "rb-0001" })
```
