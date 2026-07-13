# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]

### Changed
- **skill docs を VP v0.44 実サーフェスに全面同期** (`skills/vantage-point/SKILL.md` / `reference/mcp-tools.md` / `skills/dev-flow/SKILL.md` / `README.md`)。 SSOT = `crates/vantage-point/src/mcp{,.rs}` + `src/generated/agent_tools.rs`、 実 MCP tool は 20 個:
  - 存在しない tool の記述を削除: `toggle_pane` / `close_pane` / `watch_file` / `unwatch_file` / `port_show|url|roles|layout` / `permission` (#625 tool 整理で撤去) + `lane_nudge` (MCP には元から無い、 CLI `vp lane nudge` のみ)。 main に残っていた `tmux_*` / `eval_ruby` 系 / `add_wing` / `capture_terminal` / `open_canvas` 系も一掃
  - `show`: `append` param は存在しない / `pane_id` は dead field (全 show は現 lane の PP body stack に集約、 doc 19) — 旧 3-pane (main/left/right) モデルの記述を撤去
  - `delete_performer`: param は `force` でなく `cleanup`。 `add_performer` / `flow_handoff` に `stand` / `base` / `model` を追記
  - dev-flow: control state machine を 5 → 6 state に更新 (`awaiting_user` 追加、 2026-07-11 VP 本体) + wire kind `needs_user` を taxonomy に追加。 `mcp__creo-memories-mito__remember` → `mcp__creo-memories__remember`
  - 用語を conductor / performer に統一 (未 merge branch `docs/sync-vp-v0.40-conductor-performer` の同期内容を土台に取り込み)
  - `vp app` → `vp app start`、 対応バージョン v0.40+ → v0.44+、 dogfooding tip を現行化 (XDG log path / `mise run app:swap`)

### Fixed
- **hooks/lane-status.sh の lane 判定が silent no-op だったのを修正**: 判定 pattern `/vp/lanes/` が現 lane 配置 `<repo>/.vp/lanes/` (project-local、 旧 `vp_data_dir()/lanes/` から移動) に不一致で、 in-lane 分岐が常に不発だった。 pattern を `/\.vp/lanes/` に更新


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
