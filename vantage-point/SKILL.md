# Vantage Point

> **ブラウザビューアでリッチなコンテンツを表示する**

Vantage Pointは、Claude Codeセッション中にMarkdown、HTML、ログをブラウザウィンドウやネイティブCanvasに表示するMCPサーバーです。

Process（バックエンド）が起動していなくても、MCPツールを呼ぶと自動的にProcessが起動します。

---

## クイックスタート

```bash
# MCPサーバーを起動
vp start

# 設定確認
vp config
```

Process起動なしでも、MCPツールを使えばProcessが自動起動します。

---

## MCPツール

### コンテンツ表示

| ツール | 用途 |
|--------|------|
| `show` | コンテンツを表示（markdown/html/log/url） |
| `clear` | ペインをクリア |

### ペイン操作

| ツール | 用途 |
|--------|------|
| `toggle_pane` | ペインの表示/非表示切り替え |
| `split_pane` | ペインを水平/垂直に分割 |
| `close_pane` | ペインを閉じる |

### Canvas（ネイティブウィンドウ）

| ツール | 用途 |
|--------|------|
| `open_canvas` | ネイティブCanvasウィンドウを開く |
| `close_canvas` | Canvasウィンドウを閉じる |
| `capture_canvas` | CanvasのスクリーンショットをPNG保存（Readツールで閲覧可能） |

### ファイル監視

| ツール | 用途 |
|--------|------|
| `watch_file` | ログファイルをリアルタイム監視・表示 |
| `unwatch_file` | ファイル監視を停止 |

### Ruby VM（Heaven's Door）

| ツール | 用途 |
|--------|------|
| `eval_ruby` | Rubyコード/ファイルを実行し結果を表示（短命実行） |
| `run_ruby` | Rubyコード/ファイルをデーモンプロセスとして起動（長時間実行） |
| `stop_ruby` | 実行中のRubyデーモンプロセスを停止 |
| `list_ruby` | 実行中のRubyデーモンプロセス一覧を表示 |

### システム

| ツール | 用途 |
|--------|------|
| `restart` | サーバーを再起動 |
| `permission` | ツール実行の権限確認 |

---

## ペイン構成

Canvas はタブ付き統合ウィンドウで、各タブ内で split_pane による分割が可能です。

```
┌─[Tab 1]──[Tab 2]──[Tab 3]────────────────────┐
│                                                │
│  ┌──── main ────┐┌──── pane-xxxx ────┐        │
│  │              ││                    │        │
│  │              ││                    │        │
│  │              ││                    │        │
│  └──────────────┘└────────────────────┘        │
│                                                │
└────────────────────────────────────────────────┘
```

### ペインID

| ID | 用途 |
|----|------|
| `main` | メインコンテンツ（デフォルト） |
| `left` | 左サイドパネル |
| `right` | 右サイドパネル |

`split_pane` で分割すると `pane-xxxxxxxx` 形式の新しいペインが生成されます。
各ペインカードにはホバーで表示される × ボタンがあり、UI から直接閉じることもできます。

---

## 使用例

### Markdownを表示

```typescript
mcp__vantage-point__show({
  content: "# タイトル\n\n- 項目1\n- 項目2",
  content_type: "markdown",
  pane_id: "main"
})
```

### タブタイトル付きで表示

```typescript
mcp__vantage-point__show({
  content: "# 調査結果",
  pane_id: "right",
  title: "Research"
})
```

### HTMLを表示

```typescript
mcp__vantage-point__show({
  content: "<h1>タイトル</h1><p>段落</p>",
  content_type: "html"
})
```

### URLページを埋め込み表示

```typescript
mcp__vantage-point__show({
  content: "https://example.com",
  content_type: "url",
  pane_id: "right",
  title: "Preview"
})
```

### 追記モード

```typescript
mcp__vantage-point__show({
  content: "追加のログ行",
  content_type: "log",
  append: true
})
```

### ペイン分割

```typescript
// メインペインを垂直に分割
mcp__vantage-point__split_pane({
  direction: "vertical",
  source_pane_id: "main"
})
// → 新しいペインID "pane-xxxxxxxx" が返る
```

### Canvas（ネイティブウィンドウ）

```typescript
// Canvasウィンドウを開く
mcp__vantage-point__open_canvas()

// スクリーンショットを撮影（Readツールで画像確認可能）
mcp__vantage-point__capture_canvas({
  path: "/tmp/screenshot.png",  // 省略時は自動生成
  pane_id: "main"               // 省略時は全体キャプチャ
})

// 閉じる
mcp__vantage-point__close_canvas()
```

### ログファイル監視

```typescript
// トレースログをリアルタイムで表示
mcp__vantage-point__watch_file({
  path: "/path/to/trace.log",
  pane_id: "right",
  format: "json_lines",
  filter: "INFO|WARN|ERROR",
  title: "Trace Log"
})

// 監視を停止
mcp__vantage-point__unwatch_file({
  pane_id: "right"
})
```

### Ruby VM

```typescript
// コードを直接実行（短命）
mcp__vantage-point__eval_ruby({
  code: "puts 'Hello from Ruby!'\nputs 1 + 2",
  pane_id: "main"
})

// ファイルを実行（短命）
mcp__vantage-point__eval_ruby({
  file: "scripts/analyze.rb",
  pane_id: "right"
})

// デーモンとして起動（長時間実行、出力ストリーミング）
mcp__vantage-point__run_ruby({
  code: "loop { puts Time.now; sleep 1 }",
  name: "clock",
  pane_id: "right"
})
// → process_id "rb-0001" が返る

// 実行中プロセス一覧
mcp__vantage-point__list_ruby()

// デーモンを停止
mcp__vantage-point__stop_ruby({
  process_id: "rb-0001"
})
```

### ペイン表示切り替え

```typescript
// 任意のペインを非表示に（split 内では残りのペインが全幅に拡張）
mcp__vantage-point__toggle_pane({
  pane_id: "pane-abc12345",
  visible: false
})

// 再表示（split レイアウトに復帰）
mcp__vantage-point__toggle_pane({
  pane_id: "pane-abc12345",
  visible: true
})

// visible 省略でトグル
mcp__vantage-point__toggle_pane({
  pane_id: "main"
})
```

### ペインをクリア

```typescript
mcp__vantage-point__clear({
  pane_id: "main"
})
```

---

## コンテンツタイプ

| タイプ | 説明 |
|--------|------|
| `markdown` | Markdown形式（デフォルト） |
| `html` | HTML形式 |
| `log` | ログ形式（追記向け） |
| `url` | 外部URLをiframeで埋め込み表示 |

---

## 関連

- **詳細**: `reference/mcp-tools.md`
