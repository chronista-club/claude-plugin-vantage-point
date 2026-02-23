# Vantage Point

> **ブラウザビューアでリッチなコンテンツを表示する**

Vantage Pointは、Claude Codeセッション中にMarkdown、HTML、ログをブラウザウィンドウやネイティブCanvasに表示するMCPサーバーです。

Stand（バックエンド）が起動していなくても、MCPツールを呼ぶと自動的にStandが起動します。

---

## クイックスタート

```bash
# MCPサーバーを起動
vp start

# 設定確認
vp config
```

Stand起動なしでも、MCPツールを使えばStandが自動起動します。

---

## MCPツール

### コンテンツ表示

| ツール | 用途 |
|--------|------|
| `show` | コンテンツを表示（markdown/html/log） |
| `clear` | ペインをクリア |

### ペイン操作

| ツール | 用途 |
|--------|------|
| `toggle_pane` | サイドパネルの表示切り替え |
| `split_pane` | ペインを水平/垂直に分割 |
| `close_pane` | ペインを閉じる |

### Canvas（ネイティブウィンドウ）

| ツール | 用途 |
|--------|------|
| `open_canvas` | ネイティブCanvasウィンドウを開く |
| `close_canvas` | Canvasウィンドウを閉じる |

### ファイル監視

| ツール | 用途 |
|--------|------|
| `watch_file` | ログファイルをリアルタイム監視・表示 |
| `unwatch_file` | ファイル監視を停止 |

### システム

| ツール | 用途 |
|--------|------|
| `restart` | サーバーを再起動 |
| `permission` | ツール実行の権限確認 |

---

## ペイン構成

```
+------------------+----------------------+--------------------+
| LEFT             | MAIN                 | RIGHT              |
+------------------+----------------------+--------------------+
| (memories等)     | (メインコンテンツ)    | (コンテキスト等)   |
+------------------+----------------------+--------------------+
```

### ペインID

| ID | 用途 |
|----|------|
| `main` | メインコンテンツ（デフォルト） |
| `left` | 左サイドパネル |
| `right` | 右サイドパネル |

`split_pane` で分割すると `pane-xxxxxxxx` 形式の新しいペインが生成されます。

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

### サイドパネル制御

```typescript
// 左パネルを表示
mcp__vantage-point__toggle_pane({
  pane_id: "left",
  visible: true
})

// 右パネルを非表示
mcp__vantage-point__toggle_pane({
  pane_id: "right",
  visible: false
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

---

## 関連

- **詳細**: `reference/mcp-tools.md`
