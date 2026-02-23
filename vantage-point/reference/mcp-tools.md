# Vantage Point MCPツール リファレンス

## 概要

Vantage Pointはブラウザビューアやネイティブ Canvas にリッチコンテンツを表示するMCPサーバーです。

**MCPサーバー名**: `vantage-point`

Stand が起動していない場合、MCPツール呼び出し時に自動的に Stand を起動します（自動起動リレー）。

---

## ツール一覧

### show

コンテンツをビューアに表示します。

```typescript
mcp__vantage-point__show({
  content: "表示するコンテンツ",   // 必須
  content_type: "markdown",        // オプション: markdown(デフォルト), html, log
  pane_id: "main",                 // オプション: main(デフォルト), left, right, pane-*
  append: false,                   // オプション: 追記モード
  title: "タブタイトル"            // オプション: ペインのタブ表示名
})
```

**パラメータ**:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `content` | string | ✓ | 表示するコンテンツ |
| `content_type` | string | - | `markdown`(デフォルト), `html`, `log` |
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

サイドパネルの表示/非表示を切り替えます。

```typescript
mcp__vantage-point__toggle_pane({
  pane_id: "left",   // 必須: left または right
  visible: true      // オプション: 明示的に表示/非表示を指定
})
```

**パラメータ**:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `pane_id` | string | ✓ | `left` または `right` |
| `visible` | boolean | - | `true`=表示, `false`=非表示, 省略=トグル |

---

### split_pane

既存のペインを水平または垂直に分割し、新しいペインを作成します。

```typescript
mcp__vantage-point__split_pane({
  direction: "vertical",      // 必須: horizontal または vertical
  source_pane_id: "main"      // オプション: 分割元のペインID（デフォルト: main）
})
```

**パラメータ**:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `direction` | string | ✓ | `horizontal`(`h`) または `vertical`(`v`) |
| `source_pane_id` | string | - | 分割元のペインID（デフォルト: `main`） |

**戻り値**: 新しいペインIDが返されます（`pane-xxxxxxxx` 形式）。このIDを `show` の `pane_id` に指定してコンテンツを表示できます。

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

### open_canvas

ネイティブWebViewウィンドウ（Canvas）を開きます。ブラウザビューアと同じコンテンツを表示します。

```typescript
mcp__vantage-point__open_canvas()
```

**パラメータ**: なし

---

### close_canvas

Canvasウィンドウを閉じます。

```typescript
mcp__vantage-point__close_canvas()
```

**パラメータ**: なし

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

## 使用シナリオ

### ダッシュボード表示

```typescript
// 左パネルにメモリ一覧
mcp__vantage-point__toggle_pane({ pane_id: "left", visible: true })
mcp__vantage-point__show({
  content: "## Recent Memories\n- Memory 1\n- Memory 2",
  pane_id: "left"
})

// メインにタスク一覧
mcp__vantage-point__show({
  content: "## Tasks\n- [ ] Task 1\n- [x] Task 2",
  pane_id: "main"
})

// 右パネルにコンテキスト
mcp__vantage-point__toggle_pane({ pane_id: "right", visible: true })
mcp__vantage-point__show({
  content: "## Context\n- Branch: main\n- CWD: /project",
  pane_id: "right"
})
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
