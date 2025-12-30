# Vantage Point MCPツール リファレンス

## 概要

Vantage PointはブラウザビューアにリッチコンテンツをMCPを表示するMCPサーバーです。

**MCPサーバー名**: `vantage-point`

---

## ツール一覧

### show

コンテンツをビューアに表示します。

```typescript
mcp__vantage-point__show({
  content: "表示するコンテンツ",   // 必須
  content_type: "markdown",        // オプション: markdown(デフォルト), html, log
  pane_id: "main",                 // オプション: main(デフォルト), left, right
  append: false                    // オプション: 追記モード
})
```

**パラメータ**:

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `content` | string | ✓ | 表示するコンテンツ |
| `content_type` | string | - | `markdown`(デフォルト), `html`, `log` |
| `pane_id` | string | - | `main`(デフォルト), `left`, `right` |
| `append` | boolean | - | `true`で既存コンテンツに追記 |

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

mcp__vantage-point__show({
  content: "[SUCCESS] Build complete\n",
  content_type: "log",
  append: true
})
```
