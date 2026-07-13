---
name: dev-flow
description: VP の Conductor × Performer × Memory orchestration による開発フロー — hearing → 議論 → spec memory → performer handoff → 並列追跡 → merge の 6 phase。 「並列開発」 「conductor performer」 「handoff」 「並列 performer」 「control surrender」 「dev flow」 等のキーワードで invoke
version: 0.3.2
tags:
  - dev-flow
  - orchestration
  - conductor-performer
  - memory-first
  - parallel-dev
  - handoff
  - control-surrender
---

# VP Dev Flow — Conductor × Performer × Memory

> **AI ネイティブ開発フロー** — VP の lane (= conductor + performer) + wiremsg + creo memory が揃ったことで物理的に成立した「**conductor で idea / 議論を練り、 performer に handoff、 conductor が orchestrate**」 手法。 chronista-style と統合した formalization。

## 起点

伝統的 dev = code 書く / PR / merge、 spec は markdown / 議論は Slack / trail は git log で分散。 VP × creo は memory を背骨に、 lane を実行体に、 wire を transport にして 1 つの orchestrated stream に統合する。

詳細仕様: creo memory `mem_1CbUUzvguCptQPU4eWTKHx` (= 本 skill の canonical reference)

> **用語注**: VP は **performer** を 1 用語に統一する。 「worker」 / 「wing」 は旧称 — VP の文脈には存在しない。 役割 / 動的主体としても performer そのものが立つ (= 「performer が question を投げる」 「performer が completed を報告する」)。 performer = lane-cloned worktree + echoes claude session を含む環境 + 動的主体の合成体。 orchestration 側は **conductor** (= 旧 lead)。
>
> **address 注** (VP v0.40+):
> - **wire address** (= `wire_send` 宛先): `agent@<project>` (conductor) / `agent@<project>/<performer-name>` (performer)
> - **lane address** (= `lane_nudge` / `switch_lane`): `<project>/conductor` / `<project>/performer/<name>`

---

## principle 5 つ

### 1. Conductor は idea / 議論 / orchestration の場
- `hearing` で要件抽出 (= chronista-style:hearing)
- `council` で多角検証 (= 4 voice)
- spec memory に decision を **stream** で trail (= status:spark → in-progress → done)
- performer handoff + 進捗追跡 + 最終統合 / merge

### 2. Performer は分解された task の実装主体 (= 2 mode)
- lane-clone された worktree + 独立 claude session (= echoes stand) の合成体
- **auto mode**: spec 1 回渡して自走、 完了報告で初回 interaction
- **human-in-the-loop (HITL)**: 進捗 / blocker / 判断で conductor と thread 対話
- performer からの question wire → 自動的に HITL に shift する escalation

### 3. Wire は意思決定 + 状態の transport
- conductor ↔ performer: 永続 inbox + thread (= reply_to で chain)
- conductor ↔ conductor (cross-project): API 変更通知 / 依存調整
- performer ↔ performer: 直接 collab
- 全 msg 永続化、 supersede / annotate で trail

### 4. Memory は decision lineage の永続化
- **spec memory** (= principle / decision / rationale)
- **feedback memory** (= correction / confirmation)
- **project memory** (= ongoing work / cycle)
- **reference memory** (= external pointer)
- supersede / annotate / derivedFrom / extends で trail 完全保持
- 「memory が canonical、 markdown は projection」

### 5. Control surrender awareness (= 「手放してる / 手放してない」 の見える化)
- conductor は各 performer の **control 状態**を即把握:
  - **control 手放してる** (= autonomous) → performer は自走中、 conductor 介入なし
  - **control 手放してない** (= interactive) → conductor reply 待ち or 対話進行中
- performer 自身も task spec の `mode` field で自己認識
- mode shift は wire pattern で explicit 表現 (= performer question / conductor reply / performer complete 等の `kind` field)
- 6 state FSM で derive (= 後述「control state machine」 section)

---

## control state machine (= 6 state、 wire pattern で derive)

```
        ┌─ idle (= echoes 起動済、 task 未受領)
        │
        ▼ conductor 「task」 wire
   working (= performer 作業中、 conductor 介入なし)  ← control 手放してる
        │
        ├─→ hitl_pending (= performer 「question」 wire 送信、 conductor reply 待ち)  ← control 手放してない
        │        │ conductor 「approve/modify/clarify」 wire
        │        ▼
        │   working (= 自走再開)  ← control 再 surrender
        │
        ├─→ awaiting_user (= performer 「needs_user」 wire、 **ユーザ本人**の回答待ち)  ← sidebar needs-you (magenta diamond)
        │        │ user 回答 → conductor reply
        │        ▼
        │   working (= 自走再開)
        │
        └─→ completed (= performer 「complete」 wire、 conductor review 待ち)  ← conductor に control 戻る
                │
                ▼ merge
            merged / closed
        │
   stuck (= dirty_count あり + last_commit なし、 詰まってる可能性)  ← conductor 介入候補
```

> `awaiting_user` は 2026-07-11 追加 (= `hitl_pending` が conductor 待ちなのに対し、 conductor では代答できない**ユーザ本人**待ちの別軸)。

### derivation logic

VP v0.40+ では `flow_progress` (= MCP `mcp__vantage-point__flow_progress` / CLI `vp flow progress`) が server 側で derive し、 各 performer に `flow_state` / `control_surrender` / `state_reason` / `performer_status` / `unread_wire_count` を返す。 下記は概念 model (= wire pattern からの derive 規則) であり、 手動で組み立てる場合の reference:

```rust
fn flow_state(performer: &PerformerState, thread: &[WireMsg]) -> FlowState {
    let last_msg = thread.last();
    match (last_msg, performer.dirty_count > 0, performer.last_commit) {
        (None, _, _) => FlowState::Idle,
        (Some(m), _, _) if m.from == conductor && m.kind == "task" => FlowState::Working,
        (Some(m), _, _) if m.from == performer && m.kind == "question" => FlowState::HitlPending,
        // 未 ack の needs_user が存在 → ユーザ本人待ち (conductor 待ちの HitlPending とは別軸)
        (Some(m), _, _) if m.from == performer && m.kind == "needs_user" => FlowState::AwaitingUser,
        (Some(m), _, _) if m.from == performer && m.kind == "complete" => FlowState::Completed,
        (Some(m), true, None) if m.from == conductor => FlowState::Stuck,
        _ => FlowState::Working,
    }
}

// control_surrender = true iff state ∈ {Working, Completed} && (last_msg.from == performer || last_msg is None)
```

### wire msg `kind` taxonomy (= state derivation の入力)

| kind | from | 意味 |
|---|---|---|
| `task` | conductor → performer | 初手 handoff spec |
| `question` | performer → conductor | 質問 / decision 依頼 |
| `needs_user` | performer → conductor | **ユーザ本人**の判断/回答が要る (conductor では代答不可)。 未 ack で `awaiting_user` が立つ |
| `ack` | performer → conductor | 受領 / progress |
| `decision` | performer → conductor | 自己判断 表明 |
| `approve` / `modify` / `clarify` | conductor → performer | reply |
| `complete` | performer → conductor | 完了報告 |
| `request` | performer → conductor | action 依頼 (= dogfood 等) |

---

## workflow 6 phase

```
Phase 1: idea / hearing  →  spark memory (status:spark)
   ↓
Phase 2: 議論 / refinement  →  status:in-progress + annotate trail (= voice)
   ↓
Phase 3: spec 確定  →  status:done memory (= derivedFrom / extends で lineage)
   ↓
Phase 4: 分解 + performer handoff  →  flow_handoff (= 推奨) or lane new + wire_send + lane_nudge
   ↓
Phase 5: 並列追跡  →  flow_progress (+ wire_recv / wire_inbox で詳細)
   ↓                       ↑
   │                       │ HITL escalation (= performer question wire)
   ↓
Phase 6: 統合 + merge  →  PR review (moody-blues / santa-method) → merge → retrospect memory
   │
   └→ learnings → Phase 1 へ feedback loop
```

各 phase が memory に **stream で trail**、 後 session が context-engine 経由で auto-load。

---

## mode 選択基準

| mode | 条件 | 例 |
|---|---|---|
| **auto** (= control 手放す) | spec 明確 / ambiguity 少 / test-driven / 既知 pattern | fmt fix、 単純 refactor、 docs update、 schema migration boilerplate |
| **HITL** (= control 握る) | 設計判断含む / spec 内 ambiguity / dogfood feedback 要 | 新 architecture、 schema 設計、 UX 判断、 API 変更 |

**動的 shift trigger**:
- performer question wire_send → auto → HITL に shift (= control が conductor に戻る)
- performer complete wire_send → auto 完結 (= control が conductor に戻る、 review へ)
- conductor が approve/modify/clarify wire_send → HITL → auto 再 surrender

---

## tools (= VP v0.40+ core セット)

| tool | layer | 用途 |
|---|---|---|
| `mcp__vantage-point__flow_handoff` / `vp flow handoff` | handoff | performer 作成 + wire_send + lane_nudge を atomic (= 失敗時 rollback) |
| `mcp__vantage-point__flow_progress` / `vp flow progress` | state | 全 performer の git status + unread wire + `flow_state` / `control_surrender` 集約 view |
| `mcp__vantage-point__add_performer` / `vp lane new` | performer 作成 | lane clone + echoes spawn (handoff 使わない場合の低レベル操作) |
| `mcp__vantage-point__wire_send` / `vp wire send` | message | thread 化 inter-agent msg (= `reply_to` で chain、`body.category` で delivery policy) |
| `mcp__vantage-point__wire_recv` / `vp wire recv` | message | inbox から msg 取得 (= read cursor 進む) |
| `mcp__vantage-point__wire_inbox` / `vp wire inbox` | message | 未読数だけ確認 (= cursor 不触り、 P5 の軽量ポーリング向け) |
| `mcp__vantage-point__wire_ack` / `vp wire ack` | message | `category: command` msg の受領確認 (= delivery loop 再掲示を止める) |
| `vp lane nudge` (CLI のみ、 MCP tool は無い) | nudge | performer / conductor に text + Enter 注入 (旧 `tmux send-keys`) |
| `mcp__vantage-point__list_lanes` / `vp lane ls --detail` | routing | Lane 一覧 + `performer_status` / `mailbox_addresses` (wire 宛先解決) |
| `mcp__vantage-point__show` | view | PP (Paisley Park) に構想 visualize (= HTML / markdown / image) |
| `mcp__creo-memories__remember` | persist | memory trail (= atlas + tags + supersedes) |
| `gh pr merge --auto --squash` | ship | CI 通過後自動 merge |

**補助 primitive** (単発委譲向け、 wire handoff と併用可):
- `delegate` / `complete` / `respond` — async future 型の task 委譲 (= doer が `complete` で報告、 requester は spin-wait 不要)

---

## chronista-style stack 統合

| skill | dev flow phase |
|---|---|
| `hearing` | P1 (= 要件抽出) |
| `codeflow` | P1-4 orchestrate (= ヒアリング → SDG → 実装) |
| `spec-design-guide` | P3 (= Why/What/How を memory に) |
| `council` | P2 (= 4 voice 合議) |
| `sex-pistols` | P4 (= 並列 performer dispatch、 6 unit coordinate) |
| `santa-method` | P6 (= 2 reviewer 独立検証) |
| `route` | P3-4 (= goal までの path 探索) |
| `agent-introspection` | P5 (= performer failure self-debug) |
| `size-stepper` | P4-5 (= $variables 演奏、 spec interaction = music) |

---

## handoff 標準 pattern

### A. 推奨: `flow_handoff` (1 call)

```
vp flow handoff <slug> --task-spec <file-or->
  # or mcp__vantage-point__flow_handoff
  #   name: "<slug>"
  #   task_spec: "<markdown 仕様>"
  #   mode: "auto" | "hitl"   # default: hitl
  #   branch: "<user>/<slug>" # 省略可 (auto-derive)
  #   nudge: true             # false = 完全 async (CLI flag は --no-nudge)
```

→ `add_performer` + `wire_send` + `lane_nudge` を atomic 実行。 失敗時は performer rollback。

### B. 低レベル fallback (3 step 手動)

#### 1. performer 作成
```
vp lane new <slug> <user>/<slug>
  → performer dir 作成 + echoes auto spawn
  → zero-config で .mcp.json / CLAUDE.local.md / .env auto-symlink
```

#### 2. task spec を wire で送信
```
mcp__vantage-point__wire_send
  to: ["agent@<project>/<slug>"]
  body: {
    kind: "task",
    category: "command",     // default: command (= wire_ack まで再掲示)
    title: "...",
    task_spec: "<markdown 仕様>",
    mode: "auto" | "hitl",
    priority: "high",
    scope_outs: ["..."]
  }
```

#### 3. lane nudge
```
vp lane nudge <project>/performer/<slug> \
  "conductor から task が届いています。 mcp__vantage-point__wire_recv で確認して着手。"
```

### 4. 並列追跡 (= control 状態も把握)
```
mcp__vantage-point__flow_progress          →  flow_state / control_surrender / performer_status / unread_wire_count
mcp__vantage-point__wire_inbox             →  未読数だけ軽量確認 (cursor 不触り)
mcp__vantage-point__wire_recv              →  performer question / 完了報告の本文取得
mcp__vantage-point__wire_ack               →  command msg 処理後に ack
```

### 5. HITL reply (= 必要なら)
```
mcp__vantage-point__wire_send
  to: ["agent@<project>/<slug>"]
  reply_to: "<performer msg id>"
  body: { kind: "approve" | "modify" | "clarify", category: "command", ... }
  → control 再 surrender (= performer 自走に戻る)
```

---

## flagship example: 2026-05-28 session

6 phase + control surrender awareness のフル一周実演:

| phase | 出来事 |
|---|---|
| P1 | dogfood 摩擦: VP repo で `vp lane new` が `.claude/wing-files.kdl` 不在で hard fail |
| P2 | ヒアリング: principle 8 個確定 (= visible-first / blocklist / toggle / search 全 file 等) → ultrathink で paradigm shift 議論 (= KDL Ruby × creo Schema Registry × Projection Engine) |
| P3 | spec 確定: 4 段 pivot を decision memory `mem_1CbUPuphWcEQq39MGX8k7z` で記録 |
| P4 | 4 performer handoff: nexus-server (= VP federation hub server scaffold) / pp-content-persist (= PP state SurrealDB 永続化) / mcp-cli-audit (= mcp ↔ cli pair gap 埋め) / flow-tools (= dev-flow primitives 実装) |
| P5 | 並列追跡: list_lanes で performer_status 確認、 wire_recv で question 受信、 thread reply で approve。 各 performer の control 状態を 5 state FSM で識別 |
| P6 | merge pending: PR #460 (XDG) + PR #461 (zero-config) auto-merge 仕掛け中、 nexus-server PR #466 merge 済 (= autonomous 完結) |

**特徴**:
- dogfood → paradigm shift → 形式化 の螺旋上昇
- HITL escalation 実例: pp-content-persist performer が「spec と現状 path 乖離」 の question wire → conductor approve で auto に戻る (= control surrender → grab → surrender)
- 4 performer 並列で 4 軸同時進行、 nexus-server は full autonomous (= conductor 介入ゼロ) で PR merge まで到達

---

## 「memory-first」 統合

memory は dev flow の **背骨**:
- 各 phase で memory 残す → 後 session が context auto-load
- session を跨いだ continuity (= 「前回どこまでやったか」 即把握)
- AI agent (= Claude / 他) が同 memory を context で参照
- cross-project でも同 spec memory を共有 (= 将来 visibility:public + EntId URL)

---

## 真の paradigm shift

### 「dev = orchestrated stream of memories」
従来: spec は markdown / 議論は Slack / trail は git log で分散。
新: idea → 議論 → spec → 実装 → review → learn が **全部 memory で trail**、 conductor / performer / cross-project が同 memory graph に access、 AI agent が一級市民として参加。

### 「lane × wire × memory = AI cognition OS」
- lane = isolation (= 各 performer が独立 process / git context)
- wire = communication (= inter-performer msg + state machine event)
- memory = persistence (= decision trail + knowledge)

3 つ揃って「**人 + AI が pair で開発する environment**」 が物理的に成立。

### 「control surrender は orchestration の単位」
conductor の orchestration = 「どの performer から control を手放し、 どこで握り直すか」 の判断連鎖。 6 state FSM で wire pattern から derive、 conductor は performer 群の control 状態を一望し、 必要な performer にだけ介入する。 これは **「複数 performer を同時並走させながら conductor の認知 cost を一定に保つ」** 構造で、 並列 dev の規模拡張を可能化。

---

## 関連 references

- canonical memory: `mem_1CbUUzvguCptQPU4eWTKHx` (= 本 skill の dev-flow overview)
- knowledge layer: `mem_1CbUPuphWcEQq39MGX8k7z` (= creo × KDL Ruby × Projection Engine 構想、 本 flow の future state)
- 実装基盤: PR #461 (= performer zero-config + port name resolution) / PR #460 (= XDG restructure)
- chronista-style: `hearing` / `codeflow` / `council` / `sex-pistols` / `santa-method` / `route` / `agent-introspection` / `size-stepper`

---

## 後追い (= 本 skill の child memory への分割)

scope 拡大時に hybrid 分割:
- phase 別 detail × 6
- mode 選択基準 detail
- tool セット detail
- chronista-style 各 skill との接続 detail
- 失敗 pattern / antipattern 集
- cross-project 拡張 (= LAN address book 経由の conductor ↔ conductor orchestration)
- 6 state FSM の transitional 検出 (= stuck → conductor 介入 trigger、 hitl_pending の timeout 等。 awaiting_user は 2026-07-11 実装済)
