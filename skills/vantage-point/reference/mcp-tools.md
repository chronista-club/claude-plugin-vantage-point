# Vantage Point MCP ツール リファレンス

## 概要

Vantage Point は **board（貼る台）**、 **lane（作業台）** 管理、 **wire** inter-agent 通信、 **dev-flow** orchestration、 **GUI live tuning** を提供する MCP サーバーです。

**MCP サーバー名**: `vantage-point`
**対応 VP バージョン**: **v0.57+**
**実ツール数**: **26**（SSOT = `crates/vantage-point/src/mcp.rs` + `src/mcp/{editor,layout}.rs` + `src/generated/agent_tools.rs`。後者の SSOT は `crates/vantage-point/schema/vp-agent.kdl`）

repo runtime が起動していない場合、MCP ツール呼び出し時に自動的に起動します（自動起動リレー）。

---

## 語彙（v0.56 命名エピックで確定）

JoJo 由来の愛称は **PR #936〜#946 で全廃**され、機能名へ移行しました。SSOT = VP 本体 `CLAUDE.md`「アーキテクチャ命名体系」。

```
daemon ⚙️  (Process Manager / 常駐デーモン)
  ├── repo 📦  (Repo Runtime / 各機能が同居する場)
  │     ├── conversation 💬  (AI との会話層 — host / 翻訳 / transcript)
  │     ├── board 🧭  (Information Navigator / 貼る台)
  │     └── runner 🌿  (Code Runner)
  ├── devices 🧲  (machine scope / device registry)
  └── device_io 🌫️  (lane scope / device I/O)

軸: agent（claude / codex / grok / opencode / shell）× mode（tui / gui）
GUI 容器 = Pane（app 専用語）。部品 = component / 常駐 = service。総称「Stand」は廃止。
```

**旧名 → 現行名**（skill / doc の読み替え表）:

| 旧 | 現行 |
|---|---|
| Paisley Park / PP / Canvas | **board** |
| Gold Experience / GE | **runner** |
| Star Platinum / SP / project（容器の義） | **repo** |
| TheWorld / World | **daemon** |
| Echoes | **conversation** |
| Stand / stand | **agent**（engine 軸）/ component / service に分解 |
| The Hand | **shell**（agent の一種） |
| Hermit Purple / Stone Free | 消滅（義ごとに分解） |
| `@world` | **`@machine`** |
| act（chat / tui） | **mode**（gui / tui） |

### address

| 種別 | 形 | 例 |
|---|---|---|
| **lane address** | `<repo>/root` / `<repo>/<name>` | `vantage-point/root` / `vantage-point/feat-api` |
| **wire address** | `agent@<repo>` / `agent@<repo>/<name>` | `agent@vantage-point` / `agent@vantage-point/feat-api` |
| **board inbox** | `board@<repo>/<name>` | `board@vantage-point/feat-api` |
| **repo scope** | `runner@<repo>` | `runner@vantage-point` |
| **machine scope** | `devices@machine` | `devices@machine` |

> ⚠️ **lane address から `/performer/` セグメントが消えました**（doc 44 P2）。旧 `<repo>/performer/<name>` / `<repo>/conductor` は `LanePool::parse_address` が受理して新形へ正規化しますが、**新規に書く記述は新形で**。
>
> `root` は **役割ではなく予約名** です。`LaneKind`（Conductor / Performer）は撤去され、「lane は役割状態を持たない」(doc 44 D4) になりました。root lane はたまたま開発起点である lane、という関係に退化しています。wire address 側は不変。

---

## ツール一覧（カテゴリ別、全 26 個）

| カテゴリ | ツール | 数 |
|----------|--------|---|
| Board | `show`, `clear`, `read_board`, `update`, `capture_window`, `switch_lane` | 6 |
| Lane | `add_performer`, `delete_performer`, `list_lanes` | 3 |
| dev-flow | `flow_handoff`, `flow_progress` | 2 |
| wire | `wire_send`, `wire_recv`, `wire_inbox`, `wire_ack`, `wire_thread` | 5 |
| Delegation | `delegate`, `complete`, `respond` | 3 |
| GUI live tuning | `editor_fields`, `editor_values`, `editor_set`, `layout_get`, `layout_set`, `layout_history` | 6 |
| Process | `restart` | 1 |

---

## Board

lane ごとに **board**（貼る台）を 1 枚持ちます。`show` した内容は現 lane の board に **item として積まれ**、各 item は **id** を持ちます。

### show

```typescript
mcp__vantage-point__show({
  content: "# 進捗\n- A 完了",
  content_type: "markdown",   // markdown(default) / html / log / url
  title: "進捗"
})
```

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `content` | string | ✓ | 表示するコンテンツ |
| `content_type` | string | - | `markdown`（default）/ `html` / `log` / `url`（iframe 埋め込み） |
| `title` | string | - | board item のタイトル（history strip に出る） |
| `scope` | string | - | 貼る board。**`lane`（default）のみ対応** |

> `pane_id` パラメータは **撤去されました**（v0.45 までの dead field）。現行は `scope` のみで、値は `lane` 一択です。`append` は MCP に無く CLI (`vp pane show --append`) のみ。

CLI pair: `vp pane show <content> [-f markdown|html|log|url] [--title] [--append] [--pane-id]`

### read_board

現 lane の board を読む。各 item の **id / title / content_type / 全文**を newest-first で返します。

```typescript
mcp__vantage-point__read_board({ scope: "lane" })
```

用途は 2 つ:
1. `update` に渡す **id を取る**
2. item の全文を取り出して他所に保存する（例: `mcp__creo-memories__remember`）

> id が安定ハンドルです。**title / 内容で「どの item か」を人間的に認識してから、id で操作する**のが想定フロー。

CLI pair: **なし**（MCP 専用）

### update

board item を **id 指定で in-place 置換**。位置と title は保たれます。

```typescript
mcp__vantage-point__update({
  id: "<read_board で得た id>",
  content: "# 進捗\n- A 完了\n- B 完了",
  content_type: "markdown"   // 省略で現在の型を維持
})
```

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `id` | string | ✓ | 置換対象。`read_board` で取得 |
| `content` | string | ✓ | 新しい内容 |
| `content_type` | string | - | 省略時は現在の型を維持（**描画を変えたい時だけ渡す**） |
| `scope` | string | - | `lane`（default）のみ |

> 未知の id は **意図的に loud fail** します（黙って重複を作らないため）。
>
> **これは運用を変える tool です**: 進捗表・テスト結果・設計の現行形は、`show` で積み増すのではなく **1 枚を `update` で書き換える**。board が「流れるログ」から「現在の状態を映す面」になります。

CLI pair: **なし**（MCP 専用）

### clear

```typescript
mcp__vantage-point__clear({ scope: "lane" })
```

CLI pair: `vp pane clear`

### capture_window

vp-app GUI window 全体（sidebar + console + board）を PNG 撮影。Read tool で視認できます。

```typescript
mcp__vantage-point__capture_window({
  path: "/tmp/vp-window.png"   // 省略時 /tmp/vp-window-{timestamp}.png
})
```

> **旧名 `capture_canvas` から改名**。

CLI pair: `vp shot`（**CLI が上位互換**: `--region sidebar|main|full` / `--rect x,y,w,h` / `--series --interval --count|--duration` / `--list` / `--window` / `--title`。canonical screenshot 機構は CLI 側）

### switch_lane

現 repo の vp-app の active lane を切り替え。

```typescript
mcp__vantage-point__switch_lane({ lane: "root" })      // 開発起点 lane
mcp__vantage-point__switch_lane({ lane: "feat-api" })  // performer lane
```

`lane` は lane token: **`root`** または performer 名。

> 人間の view を無断で切り替えないこと（ROTO / CLI 駆動の view 制御向け）。

CLI pair: `vp lane switch <name>`

---

## Lane

### add_performer

performer lane を作成（lane clone + spawn）。cwd から repo を解決します。

```typescript
mcp__vantage-point__add_performer({
  name: "feat-api",
  branch: "mako/feat-api",   // 省略時 `<git-user>/<sanitized-name>` を auto-derive
  agent: "claude",           // claude(default) / codex / grok / opencode / shell
  base: "origin/nightly",    // worktree 分岐元 ref
  model: "opus"              // lane の claude model alias
})
```

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `name` | string | ✓ | performer 名（短い slug）。lane address の `<name>` 部分 |
| `branch` | string | - | 省略時 server が `git config user.name` から auto-derive |
| `agent` | string | - | **engine**: `claude`（default）/ `codex` / `grok` / `opencode` / `shell` |
| `base` | string | - | 分岐元 ref。**未 push の local branch も可**（root の feature branch 上の未 merge 土台を配れる）。省略時 `performer-files.kdl` の base-ref → `origin/HEAD` → `main` |
| `model` | string | - | claude model alias（`opus` / `sonnet` / `haiku` / `claude-fable-5`）。省略時は config の `default-lane-model`、無記録なら engine 側の user 既定 |

> ⚠️ **`stand` パラメータは `agent` に改名され、値 `echoes` は `claude` になりました**（v0.56 命名エピック 6/9）。`agent` は engine の選択であり、**engine は働き手の不変属性**です（engine を替える操作は存在しない — 会話の文脈は engine 間を移動できないため。乗り換えたければ新しい lane を立てる）。

CLI pair: `vp lane new <name> <branch> [--isolation worktree|clone] [--base <ref>] [--model <alias>]`（`--isolation` は CLI のみ）

### delete_performer

repo pool removal + child PTY kill + tmux session kill + workspace dir cleanup を 1 call で完結。

```typescript
mcp__vantage-point__delete_performer({
  name: "feat-api",
  cleanup: true   // default true。false で dir 残置（debug / forensic）
})
```

CLI pair: `vp lane rm <name>`

### list_lanes

現 repo の全 lane を routing 情報つきで列挙。

```typescript
mcp__vantage-point__list_lanes({
  kind: "performer",   // "root" | "performer"（省略時 両方）
  state: "running"     // running | spawning | exiting | dead（省略時 全状態）
})
```

**各 lane の戻り値**: `address`, `kind`, `state`, `agent`, `pid`, `cwd`, tmux session, `performer_status`, `mailbox_addresses`

- `mailbox_addresses.agent` — その lane の会話 inbox（例: `agent@vantage-point/feat-api`）
- `mailbox_addresses.board` — その lane の board inbox（例: `board@vantage-point/feat-api`）

**top-level の戻り値**: `repo_addresses`（例: `runner@vantage-point`）、`machine_addresses`（例: `devices@machine`）

> ⚠️ `kind` の値が **`conductor` → `root`**、mailbox の **`canvas` → `board`** に変わりました。

CLI pair: `vp lane ls --detail`

---

## dev-flow

### flow_handoff

**(1)** performer lane 作成 → **(2)** task_spec を `wire_send`（= thread root）→ **(3)** nudge、を atomic 実行。失敗時は performer 削除で rollback。

```typescript
mcp__vantage-point__flow_handoff({
  name: "feat-api",
  task_spec: "# Task\nImplement endpoint X",
  mode: "auto",            // "hitl"(default) / "auto"
  branch: "mako/feat-api",
  agent: "claude",         // claude(default) / codex / grok / opencode / shell
  base: "origin/nightly",
  model: "opus",           // 機械的作業=sonnet / 中核設計=opus
  nudge: true              // false = send のみ（完全 async）
})
```

CLI pair: `vp flow handoff <name> --task-spec <file|-> [--mode auto|hitl] [--branch] [--agent] [--base] [--model] [--no-nudge]`

### flow_progress

全 lane（root + performers）の `performer_status`（git ahead/behind/dirty/merged）と per-lane 未読 wire 数を 1 view で返す read-only 集約。cursor は触りません。

```typescript
mcp__vantage-point__flow_progress()
```

**各 lane の戻り値**: `performer_status`, `unread_wire_count`, `flow_state`, `control_surrender`, `state_reason`, `last_state_transition_at`

`flow_state` は 6 state（server 側で derive）:

| state | 表示 | 意味 |
|---|---|---|
| `idle` | ⏸ idle | 起動済・task 未受領 |
| `working` | 🤖 auto-running | 作業中、介入なし |
| `hitl_pending` | 🤝 hitl-pending | question 送信済、reply 待ち |
| `awaiting_user` | 🙋 needs-you | **ユーザ本人**の回答待ち |
| `completed` | ✅ completed | 完了報告済、review 待ち |
| `stuck` | ⚠ stuck | dirty あり + commit なし |

CLI pair: `vp flow progress [--format json|table]`

---

## wire

thread は `prev` parent-pointer で表現されます（`thread_id` は無い）。thread の identity は root message id（`prev` が null の message）。

### wire_send

```typescript
mcp__vantage-point__wire_send({
  to: ["agent@vantage-point/feat-api"],
  body: { kind: "task", category: "command", task_spec: "..." },
  reply_to: "<message id>"   // 省略 = 新規 thread root
})
```

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `to` | string[] | ✓ | 宛先 wire address |
| `body` | object | ✓ | 本文。`category` で delivery policy |
| `reply_to` | string | - | reply 先 message id。省略で新規 thread |

**body.category**:

| category | 挙動 |
|----------|------|
| `command` | **default**。受信者が `wire_ack` するまで再 nudge |
| `event` / `data` / `state` / `log` | fire-and-forget |

> 送信者は自分の root message を未読として受け取りません。

CLI pair: `vp wire send --to --body [--reply-to] [--category] [--world]`

### wire_recv

```typescript
mcp__vantage-point__wire_recv({ timeout: 10 })   // default 5, max 30（秒）
```

未読があれば即時返却、無ければ timeout まで待機。読むと **cursor が前進**します。
各 message: `id`, `prev`, `from`, `to`, `body`, `created_at`, `local_seq`

CLI pair: `vp wire recv` / 連続 subscribe は `vp wire watch`（supervisor 付きは `vp wire watch-supervised`）

### wire_inbox

未読数だけ確認（**cursor 不触り**、何度呼んでも安全）。

```typescript
mcp__vantage-point__wire_inbox()
// → { total, by_thread: { "<root message id>": <count> } }
```

> task の開始/終了など自然な区切りで呼び、reply を放置しないために使います。

CLI pair: `vp wire inbox`

### wire_ack

**処理した後**に ack。`wire_recv` で受信しただけでは ack にならず、未 ack の `command` は delivery loop が再掲示し続けます。

```typescript
mcp__vantage-point__wire_ack({ message_id: "<id>" })
// → { acked: true }（既 ack なら false、冪等）
```

CLI pair: `vp wire ack`

### wire_thread

root-first（時系列）の系譜を返す read-only。cursor 不触り。

```typescript
mcp__vantage-point__wire_thread({ message_id: "<id>" })
```

> thread の途中から参加した時（reply だけ受信して経緯が要る時）の backlog 取得に使います。返るのは指定 message の**系譜**であって branch 全体ではありません。

CLI pair: `vp wire thread`

---

## Delegation（async future）

`delegate` → doer が `complete` → requester が起こされる、という **spin-wait 不要**の委譲 primitive（doc 28 §4）。

### delegate

```typescript
mcp__vantage-point__delegate({
  doer: "agent@vantage-point/feat-api",
  task: "Fix the failing test in src/api.rs. Report result via complete()."
})
// → delegation id
```

> `task` は **self-contained** に書くこと（doer はこの文だけで起こされ、他の文脈を持たない可能性がある）。呼んだら **turn を終える** — 結果とともに再度起こされます。

### complete

委譲された側が結果を報告。

```typescript
mcp__vantage-point__complete({
  id: "dlg-...",
  outcome: "done",         // done | failed | needs_input
  result: "Test fixed, PR ready"
})
```

- `done` / `failed` → requester の future を **解決**（起こして再開させる）
- `needs_input` → future を **一時停止**。`result` を質問として requester に届け、`respond` で再開

### respond

`needs_input` への回答（委譲した側）。

```typescript
mcp__vantage-point__respond({ id: "dlg-...", answer: "Use approach B" })
```

CLI 補助: `vp wire deleg-thread`（daemon 中央 store の全委譲を markdown 化 → `show` に流して board で観測）

---

## GUI live tuning

**AI が GUI を直接調律する HITL surface**（doc 48 / doc 49）。vp-app 稼働が前提。

### editor_fields

GUI に bind されている live-tunable な design knob を列挙。

```typescript
mcp__vantage-point__editor_fields()
// → [{ id, label, type, cssVar, constraints: { min, max, step, unit } }, ...]
```

### editor_values

現在値を読む — **ユーザーが slider で手動調整した値も含む**。

```typescript
mcp__vantage-point__editor_values()
```

> 設計上の要（doc 48 D-B）: **書き戻し専用 tool は作られていません**。ユーザーが GUI で探索 → AI が `editor_values` で読む → **AI 自身の Edit で source に落とす**、が正規経路です。これで探索結果が `git diff` に出ます。

### editor_set

```typescript
mcp__vantage-point__editor_set({ id: "sb.text.base", value: 1.75 })
mcp__vantage-point__editor_set({ id: "sb.accent", value: "#7C3AED" })
```

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `id` | string | ✓ | `editor_fields` が返す field id |
| `value` | number \| boolean \| string | ✓ | slider は数値 / toggle は bool / color・select は文字列 |

即座に画面へ反映（live CSS var 更新、**永続化はしない**）。範囲は `editor_fields` で先に確認すること。

### layout_get

pane layout（creo-ui-layout の attention field）を読む。

```typescript
mcp__vantage-point__layout_get({ scope: "app" })
// → { scope, notation, attention, shares, locks }
```

| scope | 対象 |
|---|---|
| `gallery` | **default**。component gallery mode |
| `app` | main workspace panes（conversation=console / runner / devices / preview） |

`notation` が人間可読なトポロジ文字列（例: `a | b/c ~ d`）。

### layout_set

```typescript
mcp__vantage-point__layout_set({
  scope: "app",
  notation: "console | board/runner",
  attention: { console: 2.0, runner: 0 },   // 0 = 隠す
  locks: { console: 0.6 }                    // 列幅の固定（0..1 の share）
})
```

| パラメータ | 説明 |
|---|---|
| `notation` | 構造記法。`\|` = 列区切り / `/` = 列内の縦積み / `~` = floating。**サイズは書かない**（attention の領分） |
| `attention` | pane id → 0 以上の raw 値の**部分**上書き。未指定 id は現状維持。0 で非表示。構造外の id に > 0 を与えると floating 化 |
| `locks` | pane id → 列幅 share (0,1)。渡すと **lock map 全体を置換**（維持したいなら省略） |
| `scope` | `gallery`（default、spring transition）/ `app`（CSS transition） |

即座に適用され（**ユーザーが画面で見ている＝これが HITL ループ**）、author `ai` として settle-log に記録されます。全 pane が隠れる結果になる指定は reject。`layout_get` で現状を見てから使うこと。

### layout_history

```typescript
mcp__vantage-point__layout_history({ scope: "app", limit: 10 })
// → [{ author: "human" | "ai" | "scene", at, notation }, ...]（newest last）
```

ユーザーが手で組んだ形を読む / AI の変更を監査する / 復元したい形を探す、に使います。

> **GUI live tuning 6 本はいずれも CLI pair がありません**（MCP 専用）。対象が「画面上の生きた状態」で、CLI の一発実行モデルでは掴めないためです。

---

## Process

### restart

```typescript
mcp__vantage-point__restart({ open_viewer: false })
```

session 状態は保持されます。

CLI pair: `vp restart-all`（全 repo runtime + daemon 再起動）

---

## MCP ↔ CLI pair

VP は「同じ logic を MCP（AI 用）と CLI（人間用）の両方から expose する」を invariant として持ちます。**ただし現在 2 方向に例外があります**。

### pair のあるもの

| MCP | CLI |
|-----|-----|
| `show` | `vp pane show` |
| `clear` | `vp pane clear` |
| `capture_window` | `vp shot`（CLI が上位互換） |
| `switch_lane` | `vp lane switch` |
| `add_performer` | `vp lane new` |
| `delete_performer` | `vp lane rm` |
| `list_lanes` | `vp lane ls --detail` |
| `flow_handoff` | `vp flow handoff` |
| `flow_progress` | `vp flow progress` |
| `wire_send` / `recv` / `inbox` / `ack` / `thread` | `vp wire send` / `recv` / `inbox` / `ack` / `thread` |
| `restart` | `vp restart-all` |

### MCP のみ（CLI pair なし）

`read_board` / `update` / `editor_fields` / `editor_values` / `editor_set` / `layout_get` / `layout_set` / `layout_history`

→ いずれも **GUI の生きた状態**（board item の id、画面上の CSS var、pane の attention field）が対象。

### CLI のみ（MCP pair なし）

| CLI | 用途 |
|---|---|
| `vp lane nudge <lane> <text>` | lane の agent / shell に text + Enter を注入 |
| `vp lane capture <lane>` | lane console の現在画面を読む |
| `vp lane fork` / `status` / `cleanup` / `history` / `origin` | lane の派生・棚卸し・帳簿 |
| `vp lane slots` / `slot-new` / `slot-close` | console slot（session ごとの窓）の増減 |
| `vp lane last-session` / `resume-failed` | conversation resume の id 取得・失敗記録 |
| `vp pane split` / `close` / `toggle` | pane 操作 |
| `vp file watch` / `unwatch` | ログの実時間監視 |
| `vp wire watch` / `watch-supervised` / `discover` / `hook-check` / `deleg-thread` | 購読・federation discovery・hook・委譲観測 |
| `vp now` | session の「今なにを」を 1 行報告（サブタスクの切れ目ごとに打つ想定） |
| `vp events` | event log（agent の episodic memory） |
| `vp repos` / `vp sync` | 登録 repo 管理・ghost repo 除去 |
| `vp auth` | Creo ID 認証 |
| `vp ps` / `vp config` / `vp daemon` / `vp app` / `vp db` / `vp midi` | 運用 |

### `list_lanes` vs `vp ps` vs `vp lane ls`

- **`list_lanes`** — 現 repo の全 lane（root + performers）。`performer_status` / `mailbox_addresses` 付き
- **`vp ps`** — daemon 配下の全 repo runtime 一覧
- **`vp lane ls`** — fs scan の簡易表示（runtime 不要）
- **`vp lane ls --detail`** — `list_lanes` の CLI pair（runtime 稼働中のみ）

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

// 2. 並列追跡（read-only、cursor 不触り）
mcp__vantage-point__flow_progress()

// 3. 未読の在庫確認（軽量）
mcp__vantage-point__wire_inbox()

// 4. 本文取得 → 処理 → ack
const msgs = await mcp__vantage-point__wire_recv({ timeout: 5 })
// ...実際に処理してから...
await mcp__vantage-point__wire_ack({ message_id: msgs[0].id })
```

### board を「現在の状態を映す面」として使う

```typescript
// 初回: 貼る
mcp__vantage-point__show({ content: renderTable(state), title: "並列進捗" })

// 2 回目以降: 同じ item を書き換える（積み増さない）
const board = await mcp__vantage-point__read_board()
const item = board.find(i => i.title === "並列進捗")
mcp__vantage-point__update({ id: item.id, content: renderTable(newState) })
```

### GUI 調律ループ（HITL）

```typescript
// 1. 何を弄れるか
const fields = await mcp__vantage-point__editor_fields()

// 2. AI が試す → ユーザーが画面で見る
mcp__vantage-point__editor_set({ id: "sb.text.base", value: 1.75 })

// 3. ユーザーが slider で更に手調整 → その値を回収
const tuned = await mcp__vantage-point__editor_values()

// 4. AI が自分の Edit で source に落とす（← 書き戻し tool は無い。これが正規経路）
//    → git diff に出て、探索が成果になる
```

### 画面を見て確かめる

```typescript
mcp__vantage-point__capture_window({ path: "/tmp/vp.png" })
// → Read tool で PNG を視覚 review
```

---

## 廃止済み（旧 doc からの移行表）

| 旧 | 現行 |
|---|---|
| `read_pane` / `list_canvas` | **`read_board`**（id + 全文を一括） |
| `capture_canvas` | **`capture_window`** |
| `show` の `pane_id` | **`scope`**（`lane` のみ） |
| `add_performer` / `flow_handoff` の `stand: "echoes"` | **`agent: "claude"`** |
| `list_lanes` の `kind: "conductor"` | **`kind: "root"`** |
| `mailbox_addresses.canvas` | **`mailbox_addresses.board`** |
| lane address `<repo>/conductor` / `<repo>/performer/<name>` | **`<repo>/root` / `<repo>/<name>`** |
| `add_wing` / `add_worker` / `delete_wing` | `add_performer` / `delete_performer` |
| `tmux_split` / `tmux_capture` / `tmux_dashboard` / `tmux_agent_*` | `vp lane nudge` / `vp lane capture` |
| `open_canvas` / `close_canvas` / `split_pane`（MCP） | vp-app 常駐 board + `vp pane split` |
| `toggle_pane` / `close_pane` / `watch_file` / `unwatch_file` / `port_*` / `permission`（MCP） | CLI へ集約（`vp pane` / `vp file` / `vp port`） |
| `eval_ruby` / `run_ruby` / `stop_ruby` / `list_ruby` | 削除 |
| `capture_terminal` | `vp shot` |
| `lane_nudge`（MCP） | 元から CLI のみ（`vp lane nudge`） |
