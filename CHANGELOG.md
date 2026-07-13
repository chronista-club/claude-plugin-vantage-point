# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]

### Changed
- **VP v0.45 実サーフェスに追随** (v0.44.0 → v0.45.0 の全 diff 確認):
  - MCP tool surface は **v0.44 から無変更** (`src/mcp{,.rs}` / `generated/agent_tools.rs` に diff ゼロ、 20 個のまま)。 対応バージョン表記を v0.44+ → v0.45+ に更新
  - **Act II HITL 4 面完成** (#748 質問 / #752 中断 / #753 permission / #754 plan 承認) を skill docs に反映 — performer echoes (Act II chat GUI) の native `AskUserQuestion` / permission prompt / `ExitPlanMode` が PromptCard / PermissionCard / PlanCard として直接ユーザに届き sidebar needs-you が点灯。 dev-flow skill には wire `needs_user` rail (conductor 経由) と並存する GUI 直通 rail として記述 (dev-flow v0.3.3)
  - **二重 dispatch TOCTOU 根治** (#750、 `create_performer_orchestrated` の creation reservation — `add_performer` / `flow_handoff` / `vp lane new` 共通 core) を tool 説明 + troubleshooting に追記
  - SKILL.md pair table の崩れを修正: `restart` 行と MCP に存在しない `port_*` 行が table 外 (「CLI のみ」段落直後) に漏出していた — `restart` を pair table 内に戻し、 `port_*` 行を削除
- **skill docs を VP v0.44 実サーフェスに全面同期** (`skills/vantage-point/SKILL.md` / `reference/mcp-tools.md` / `skills/dev-flow/SKILL.md` / `README.md`)。 SSOT = `crates/vantage-point/src/mcp{,.rs}` + `src/generated/agent_tools.rs`、 実 MCP tool は 20 個:
  - 存在しない tool の記述を削除: `toggle_pane` / `close_pane` / `watch_file` / `unwatch_file` / `port_show|url|roles|layout` / `permission` (#625 tool 整理で撤去) + `lane_nudge` (MCP には元から無い、 CLI `vp lane nudge` のみ)。 main に残っていた `tmux_*` / `eval_ruby` 系 / `add_wing` / `capture_terminal` / `open_canvas` 系も一掃
  - `show`: `append` param は存在しない / `pane_id` は dead field (全 show は現 lane の PP body stack に集約、 doc 19) — 旧 3-pane (main/left/right) モデルの記述を撤去
  - `delete_performer`: param は `force` でなく `cleanup`。 `add_performer` / `flow_handoff` に `stand` / `base` / `model` を追記
  - dev-flow: control state machine を 5 → 6 state に更新 (`awaiting_user` 追加、 2026-07-11 VP 本体) + wire kind `needs_user` を taxonomy に追加。 `mcp__creo-memories-mito__remember` → `mcp__creo-memories__remember`
  - 用語を conductor / performer に統一 (未 merge branch `docs/sync-vp-v0.40-conductor-performer` の同期内容を土台に取り込み)
  - `vp app` → `vp app start`、 対応バージョン v0.40+ → v0.44+、 dogfooding tip を現行化 (XDG log path / `mise run app:swap`)

### Fixed
- **hooks/lane-status.sh の lane 判定が silent no-op だったのを修正**: 判定 pattern `/vp/lanes/` が現 lane 配置 `<repo>/.vp/lanes/` (project-local、 旧 `vp_data_dir()/lanes/` から移動) に不一致で、 in-lane 分岐が常に不発だった。 pattern を `/\.vp/lanes/` に更新
- **`plugin.json` description を刷新**: 「Rich dashboard display - show memories, todos...」(旧 3-pane dashboard 前提) から「AI-native development environment — Canvas visualization, performer lanes, wiremsg inter-agent messaging, and dev-flow orchestration」へ。 keywords も同期 (`dashboard`/`memories`/`todos`/`context` → `canvas`/`performer-lane`/`wiremsg`/`dev-flow`/`orchestration`)

### Removed
- **`commands/show.md` / `commands/clear.md`**: MCP tool `show` / `clear` の薄い wrapper。 `show.md` は存在しない `append` param を記載していた。 MCP tool 自体は現存、 CLI からは直接 tool 呼び出しで代替可能
- **`commands/dashboard.md`**: 前提の 3-pane (main/left/right) モデルが崩壊 (`pane_id` は dead field、 全 show は PP body stack に集約) + `gh issue list --label next` が現運用 (GitHub Issues 不使用、 creo-memories に一本化) と矛盾
- **`hooks/scripts/session-start.sh`**: 案内していた `/vantage-point:dashboard` が削除済み (リンク切れ) + git repo/branch context は Claude Code 標準 context と重複。 「VP Lane 環境 / lane 一覧」出力は元々 `hooks/scripts/lane-status.sh` の責務であり、 削除後も維持される
- **`hooks/scripts/block-ask-in-worker.sh`** + `hooks.json` の `PreToolUse` entry: (a) lane 判定 pattern が `/vp/lanes/` のままで現配置 `<repo>/.vp/lanes/` に不一致、 常に no-op と化していた、 (b) VP 本体が doc 35 で Act II HITL (`AskUserQuestion` を control protocol 経由で復活させる方向) を進めており、 本 hook の「worker で AskUserQuestion を block する」方針自体が現行の設計方向と逆行するため確定で削除


## [0.19.1] - 2026-07-13

### Fixed
- **lane session 蘇り bug**: SessionStart hook に `vp wire hook-check` を追加し、 lane の CC session id 記録 (VP 本体 R3-b、 `cc_session` state file) の書き手を plugin が担う。 旧方式 (= global `~/.claude/settings.json` への手動設置、 new-machine-setup 依存) は settings 掃除で silent に消え、「lane で New Session しても daemon/app 再起動で古い session が `--resume` される」不具合の根因だった (実機で `cc_sessions/` の state file が 3 週間 mtime 凍結を確認)。 plugin 同梱により install に追従して自動修復。 `vp` 不在マシンは `command -v` guard で silent skip (fail-open)。 VP 本体側の root fix は別途追跡

### Added
- `rename` command (`commands/rename.md`): ローカル LLM (LM Studio) で日本語セッション名を生成 (#8)
- `dev-flow` skill (`skills/dev-flow/SKILL.md`): VP の Lead × Wing × Memory orchestration による開発フロー — hearing → 議論 → spec memory → wing handoff → 並列追跡 → merge の 6 phase。 chronista-style stack (= hearing / codeflow / council / sex-pistols / santa-method 等) と統合、 auto / human-in-the-loop の 2 mode + 動的 shift trigger を formalize。 canonical memory `mem_1CbUUzvguCptQPU4eWTKHx`
- dev-flow skill v0.2.0: **principle 5 「control surrender awareness」 追加** + 「worker」 用語撤去 (= VP は wing 1 用語に統一、 役割 / 動的主体としても wing が立つ)。 5 state FSM (idle / working / hitl_pending / completed / stuck) を wire pattern で derive、 metadata 追加ゼロで「control 手放してる / 手放してない」 を可視化。 lead が複数 wing の control 状態を一望して必要な wing にだけ介入する構造を formalize
- **SKILL.md に「MCP ↔ CLI pair invariant」 section を追加**: VP の規約 (= 同じ logic を MCP / CLI 両方から expose) を明文化、 pair table + invariant の守り方 + `list_lanes` vs `vp ps` vs `vp lane ls` の役割整理を追記 (VP 本体 PR mcp-cli-audit)


## [0.18.0] - 2026-05-22

### Changed
- wiremsg 移行に doc を同期: `msg_send` / `msg_recv` / `msg_ack` / `msg_peers` / `msg_thread` / `msg_directory` / `msg_broadcast` を `wire_send` / `wire_recv` / `wire_thread` に差し替え (VP 本体 PR #406〜#420)
- `vp mailbox` CLI → `vp wire watch` / `vp wire send` / `vp wire watch-supervised` に同期
- ccwire / msgbox は廃止、 inter-agent 通信は wiremsg に一本化。 thread は `prev` parent-pointer で表現 (`thread_id` は無い)
- SKILL.md / reference/mcp-tools.md / hooks スクリプトの inter-agent 通信記述を wiremsg に更新
- SKILL.md の旧 Worker workspace section を Wing Lane (Whitesnake 🐍 連動) に rename: `add_worker` / `delete_worker` 表記を `add_wing` / `delete_wing` に更新 (VP 本体 lane refactor `worker→wing` 2026-05-17 と同期、 doc rot 解消)


## [0.17.0] - 2026-05-08

### Added
- `add_worker` / `delete_worker` ツール: Worker workspace の lifecycle 管理 (ccws clone-based isolated workspace)
- `list_lanes` ツール: project 内 Lane 一覧取得 (Lead + Worker、 Frame Engine 連動)
- 3D Frame Layout Engine (PR-ε-1): Pane を portable 3D オブジェクトとして inversion、 4 default Scene + Ctrl+Shift+1..4 で切替
- PP body markdown 表示 = B 達成 (PR-ε-3): `mcp__show` → state.hub.broadcast → /ws → show-subscriber → vpPP.renderPP の 6 段 pipeline 物理化
- Live Token pattern 体系化 (#300, #301): terminal 5 token (fontSize / line-height / letter-spacing / font-family / cursor-style) を creo-ui-editor-host から runtime 編集可能
- per-Lane Scene state preservation: Lane 切替で Scene layout を維持 (`Map<LaneAddress, SceneId>`)

### Changed
- 35 tools (旧 28 から +7)。 SKILL.md / reference/mcp-tools.md を v0.17.0 状態に同期
- `Heaven's Door 📖 (HD)` → `Echoes 💬` rename (VP-118): Coding Assistant Stand 名称変更、 actor address `hd@*` → `echoes@*`
- `Hermit Purple 🍇` を World 階層に物理移管 (LSCM PR-α series): `hermit_purple@world` rewire
- `Paisley Park 🧭` を Lane 階層に物理移管 (LSCM PR-β series): cardinality 1 → N (Lane あたり独立 instance)

### Removed
- `split_pane` ツール: 削除 (Frame Engine の portable オブジェクト inversion により不要に)
- `open_canvas` / `close_canvas` ツール: 削除 (Canvas は vp-app の常駐 view component に統合)


## [0.15.2] - 2026-05-02

### Fixed
- `skills/vantage-point/SKILL.md` に YAML frontmatter 不在で `/reload-plugins` が「1 error」 を出していた問題を解消
- 公式 spec 必須: skill の SKILL.md 先頭に `name` / `description` / `version` / `tags` の frontmatter


## [0.15.1] - 2026-05-02

### Changed
- Skill tree refactor: `vantage-point/SKILL.md` → `skills/vantage-point/SKILL.md` (公式 spec 準拠)

## [0.15.0] - 2026-05-02

### Changed
- Spec compliance: license/homepage fields, CHANGELOG, dropped legacy skills.txt
