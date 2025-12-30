# Vantage Point

> **ブラウザビューアでリッチなコンテンツを表示する**

Vantage Pointは、Claude Codeセッション中にMarkdown、HTML、ログをブラウザウィンドウに表示するMCPサーバーです。

---

## クイックスタート

```bash
# MCPサーバーを起動
vp start

# 設定確認
vp config
```

---

## MCPツール

| ツール | 用途 |
|--------|------|
| `show` | コンテンツを表示（markdown/html/log） |
| `clear` | ペインをクリア |
| `toggle_pane` | サイドパネルの表示切り替え |
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
