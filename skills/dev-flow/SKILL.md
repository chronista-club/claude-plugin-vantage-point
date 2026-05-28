---
name: dev-flow
description: VP の Lead × Wing × Memory orchestration による開発フロー — hearing → 議論 → spec memory → wing handoff → 並列追跡 → merge の 6 phase。 「並列開発」 「lead wing」 「handoff」 「並列 wing」 「control surrender」 「dev flow」 等のキーワードで invoke
version: 0.2.0
tags:
  - dev-flow
  - orchestration
  - lead-wing
  - memory-first
  - parallel-dev
  - handoff
  - control-surrender
---

# VP Dev Flow — Lead × Wing × Memory

> **AI ネイティブ開発フロー** — VP の lane (= lead + wing) + wiremsg + creo memory が揃ったことで物理的に成立した「**lead で idea / 議論を練り、 wing に handoff、 lead が orchestrate**」 手法。 chronista-style と統合した formalization。

## 起点

伝統的 dev = code 書く / PR / merge、 spec は markdown / 議論は Slack / trail は git log で分散。 VP × creo は memory を背骨に、 lane を実行体に、 wire を transport にして 1 つの orchestrated stream に統合する。

詳細仕様: creo memory `mem_1CbUUzvguCptQPU4eWTKHx` (= 本 skill の canonical reference)

> **用語注**: VP は **wing** を 1 用語に統一する。 「worker」 は VP の文脈には存在しない — 役割 / 動的主体としても wing そのものが立つ (= 「wing が question を投げる」 「wing が completed を報告する」)。 wing = lane-cloned worktree + echoes claude session を含む環境 + 動的主体の合成体。

---

## principle 5 つ

### 1. Lead は idea / 議論 / orchestration の場
- `hearing` で要件抽出 (= chronista-style:hearing)
- `council` で多角検証 (= 4 voice)
- spec memory に decision を **stream** で trail (= status:spark → in-progress → done)
- wing handoff + 進捗追跡 + 最終統合 / merge

### 2. Wing は分解された task の実装主体 (= 2 mode)
- lane-clone された worktree + 独立 claude session (= echoes stand) の合成体
- **auto mode**: spec 1 回渡して自走、 完了報告で初回 interaction
- **human-in-the-loop (HITL)**: 進捗 / blocker / 判断で lead と thread 対話
- wing からの question wire → 自動的に HITL に shift する escalation

### 3. Wire は意思決定 + 状態の transport
- lead ↔ wing: 永続 inbox + thread (= reply_to で chain)
- lead ↔ lead (cross-project): API 変更通知 / 依存調整
- wing ↔ wing: 直接 collab
- 全 msg 永続化、 supersede / annotate で trail

### 4. Memory は decision lineage の永続化
- **spec memory** (= principle / decision / rationale)
- **feedback memory** (= correction / confirmation)
- **project memory** (= ongoing work / cycle)
- **reference memory** (= external pointer)
- supersede / annotate / derivedFrom / extends で trail 完全保持
- 「memory が canonical、 markdown は projection」

### 5. Control surrender awareness (= 「手放してる / 手放してない」 の見える化)
- lead は各 wing の **control 状態**を即把握:
  - **control 手放してる** (= autonomous) → wing は自走中、 lead 介入なし
  - **control 手放してない** (= interactive) → lead reply 待ち or 対話進行中
- wing 自身も task spec の `mode` field で自己認識
- mode shift は wire pattern で explicit 表現 (= worker question / lead reply / wing complete 等の `kind` field)
- 5 state FSM で derive (= 後述「control state machine」 section)

---

## control state machine (= 5 state、 wire pattern で derive)

```
        ┌─ idle (= echoes 起動済、 task 未受領)
        │
        ▼ lead 「task」 wire
   working (= wing 作業中、 lead 介入なし)  ← control 手放してる
        │
        ├─→ hitl_pending (= wing 「question」 wire 送信、 lead reply 待ち)  ← control 手放してない
        │        │ lead 「approve/modify/clarify」 wire
        │        ▼
        │   working (= 自走再開)  ← control 再 surrender
        │
        └─→ completed (= wing 「complete」 wire、 lead review 待ち)  ← lead に control 戻る
                │
                ▼ merge
            merged / closed
        │
   stuck (= dirty_count あり + last_commit なし、 詰まってる可能性)  ← lead 介入候補
```

### derivation logic (= metadata 追加ゼロ)

```rust
fn flow_state(wing: &WingState, thread: &[WireMsg]) -> FlowState {
    let last_msg = thread.last();
    match (last_msg, wing.dirty_count > 0, wing.last_commit) {
        (None, _, _) => FlowState::Idle,
        (Some(m), _, _) if m.from == lead && m.kind == "task" => FlowState::Working,
        (Some(m), _, _) if m.from == wing && m.kind == "question" => FlowState::HitlPending,
        (Some(m), _, _) if m.from == wing && m.kind == "complete" => FlowState::Completed,
        (Some(m), true, None) if m.from == lead => FlowState::Stuck,
        _ => FlowState::Working,
    }
}

// control_surrender = true iff state ∈ {Working, Completed} && (last_msg.from == wing || last_msg is None)
```

### wire msg `kind` taxonomy (= state derivation の入力)

| kind | from | 意味 |
|---|---|---|
| `task` | lead → wing | 初手 handoff spec |
| `question` | wing → lead | 質問 / decision 依頼 |
| `ack` | wing → lead | 受領 / progress |
| `decision` | wing → lead | 自己判断 表明 |
| `approve` / `modify` / `clarify` | lead → wing | reply |
| `complete` | wing → lead | 完了報告 |
| `request` | wing → lead | action 依頼 (= dogfood 等) |

---

## workflow 6 phase

```
Phase 1: idea / hearing  →  spark memory (status:spark)
   ↓
Phase 2: 議論 / refinement  →  status:in-progress + annotate trail (= voice)
   ↓
Phase 3: spec 確定  →  status:done memory (= derivedFrom / extends で lineage)
   ↓
Phase 4: 分解 + wing 作成  →  vp lane new + wire_send + tmux nudge (= mode 選択)
   ↓
Phase 5: 並列追跡  →  wire_recv + wing_status.last_commit + control state
   ↓                       ↑
   │                       │ HITL escalation (= wing question wire)
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
- wing question wire_send → auto → HITL に shift (= control が lead に戻る)
- wing complete wire_send → auto 完結 (= control が lead に戻る、 review へ)
- lead が approve/modify/clarify wire_send → HITL → auto 再 surrender

---

## tools (= 公式 8 セット)

| tool | layer | 用途 |
|---|---|---|
| `vp lane new <name> <branch>` | wing 作成 | dir + echoes spawn (= zero-config で 3 file auto-symlink) |
| `mcp__vantage-point__wire_send` | message | thread 化 inter-agent msg (= reply_to で chain) |
| `mcp__vantage-point__wire_recv` | message | inbox から msg 取得 (= read cursor 進む) |
| `tmux send-keys` | nudge | wing idle 時に wire を読ませる起動 prompt |
| `mcp__vantage-point__list_lanes` | state | wing progress 追跡 (= wing_status.last_commit / dirty_count) |
| `mcp__vantage-point__show` | view | PP (Paisley Park) に構想 visualize (= HTML / markdown / image) |
| `mcp__creo-memories-mito__remember` | persist | memory trail (= atlas + tags + supersedes) |
| `gh pr merge --auto --squash` | ship | CI 通過後自動 merge |

---

## chronista-style stack 統合

| skill | dev flow phase |
|---|---|
| `hearing` | P1 (= 要件抽出) |
| `codeflow` | P1-4 orchestrate (= ヒアリング → SDG → 実装) |
| `spec-design-guide` | P3 (= Why/What/How を memory に) |
| `council` | P2 (= 4 voice 合議) |
| `sex-pistols` | P4 (= 並列 wing dispatch、 6 unit coordinate) |
| `santa-method` | P6 (= 2 reviewer 独立検証) |
| `route` | P3-4 (= goal までの path 探索) |
| `agent-introspection` | P5 (= wing failure self-debug) |
| `size-stepper` | P4-5 (= $variables 演奏、 spec interaction = music) |

---

## handoff 標準 pattern

### 1. wing 作成
```
vp lane new <slug> <user>/<slug>
  → wing dir 作成 + echoes auto spawn
  → zero-config で .mcp.json / CLAUDE.local.md / .env auto-symlink
```

### 2. task spec を wire で送信
```
mcp__vantage-point__wire_send
  to: ["agent@<project>/<slug>"]
  body: {
    kind: "task",
    title: "...",
    task_spec: "<markdown 仕様>",
    mode: "auto" | "hitl",   // wing 自己認識用
    priority: "high",
    scope_outs: ["..."]
  }
```

### 3. tmux 経由で wing nudge
```
tmux send-keys -t vp-<project>-<slug>-echoes \
  "lead から task が届いています。 mcp__vantage-point__wire_recv で確認して着手。" \
  Enter
```

### 4. 並列追跡 (= control 状態も把握)
```
mcp__vantage-point__list_lanes  →  wing_status.last_commit + dirty_count
mcp__vantage-point__wire_recv   →  wing question / 完了報告
                                →  control state を derive (= 5 state FSM)
```

### 5. HITL reply (= 必要なら)
```
mcp__vantage-point__wire_send
  to: ["agent@<project>/<slug>"]
  reply_to: "<wing msg id>"
  body: { kind: "approve" | "modify" | "clarify", ... }
  → control 再 surrender (= wing 自走に戻る)
```

---

## flagship example: 2026-05-28 session

6 phase + control surrender awareness のフル一周実演:

| phase | 出来事 |
|---|---|
| P1 | dogfood 摩擦: VP repo で `vp lane new` が `.claude/wing-files.kdl` 不在で hard fail |
| P2 | ヒアリング: principle 8 個確定 (= visible-first / blocklist / toggle / search 全 file 等) → ultrathink で paradigm shift 議論 (= KDL Ruby × creo Schema Registry × Projection Engine) |
| P3 | spec 確定: 4 段 pivot を decision memory `mem_1CbUPuphWcEQq39MGX8k7z` で記録 |
| P4 | 4 wing handoff: nexus-server (= VP federation hub server scaffold) / pp-content-persist (= PP state SurrealDB 永続化) / mcp-cli-audit (= mcp ↔ cli pair gap 埋め) / flow-tools (= dev-flow primitives 実装) |
| P5 | 並列追跡: list_lanes で wing_status 確認、 wire_recv で question 受信、 thread reply で approve。 各 wing の control 状態を 5 state FSM で識別 |
| P6 | merge pending: PR #460 (XDG) + PR #461 (zero-config) auto-merge 仕掛け中、 nexus-server PR #466 merge 済 (= autonomous 完結) |

**特徴**:
- dogfood → paradigm shift → 形式化 の螺旋上昇
- HITL escalation 実例: pp-content-persist wing が「spec と現状 path 乖離」 の question wire → lead approve で auto に戻る (= control surrender → grab → surrender)
- 4 wing 並列で 4 軸同時進行、 nexus-server は full autonomous (= lead 介入ゼロ) で PR merge まで到達

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
新: idea → 議論 → spec → 実装 → review → learn が **全部 memory で trail**、 lead / wing / cross-project が同 memory graph に access、 AI agent が一級市民として参加。

### 「lane × wire × memory = AI cognition OS」
- lane = isolation (= 各 wing が独立 process / git context)
- wire = communication (= inter-wing msg + state machine event)
- memory = persistence (= decision trail + knowledge)

3 つ揃って「**人 + AI が pair で開発する environment**」 が物理的に成立。

### 「control surrender は orchestration の単位」
lead の orchestration = 「どの wing から control を手放し、 どこで握り直すか」 の判断連鎖。 5 state FSM で wire pattern から derive、 lead は wing 群の control 状態を一望し、 必要な wing にだけ介入する。 これは **「複数 wing を同時並走させながら lead の認知 cost を一定に保つ」** 構造で、 並列 dev の規模拡張を可能化。

---

## 関連 references

- canonical memory: `mem_1CbUUzvguCptQPU4eWTKHx` (= 本 skill の dev-flow overview)
- knowledge layer: `mem_1CbUPuphWcEQq39MGX8k7z` (= creo × KDL Ruby × Projection Engine 構想、 本 flow の future state)
- 実装基盤: PR #461 (= wing zero-config + port name resolution) / PR #460 (= XDG restructure)
- chronista-style: `hearing` / `codeflow` / `council` / `sex-pistols` / `santa-method` / `route` / `agent-introspection` / `size-stepper`

---

## 後追い (= 本 skill の child memory への分割)

scope 拡大時に hybrid 分割:
- phase 別 detail × 6
- mode 選択基準 detail
- tool セット detail
- chronista-style 各 skill との接続 detail
- 失敗 pattern / antipattern 集
- cross-project 拡張 (= LAN address book 経由の lead ↔ lead orchestration)
- 5 state FSM の transitional 検出 (= stuck → lead 介入 trigger、 hitl_pending の timeout 等)
