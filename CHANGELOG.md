# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]

## [0.19.0] - 2026-07-11

### Added
- `dev-flow` skill (`skills/dev-flow/SKILL.md`): VP の Conductor × Performer × Memory orchestration による開発フロー — hearing → 議論 → spec memory → performer handoff → 並列追跡 → merge の 6 phase。 chronista-style stack と統合、 auto / HITL 2 mode + control surrender awareness (5 state FSM) を formalize。 canonical memory `mem_1CbUUzvguCptQPU4eWTKHx`
- dev-flow skill v0.3.1: VP v0.40+ 同期 — `flow_handoff` / `flow_progress` を推奨パスに、`lane_nudge` / `wire_inbox` / `wire_ack` / `body.category` を追記、 conductor/performer 用語に統一
- **SKILL.md に「MCP ↔ CLI pair invariant」 section を追加**: pair table + `list_lanes` vs `vp ps` vs `vp lane ls` の役割整理 (VP 本体 PR mcp-cli-audit)

### Changed
- `skills/vantage-point/SKILL.md` を VP v0.40+ に全面更新: conductor/performer 用語、`add_performer` / `flow_handoff` / `flow_progress` / `wire_inbox` / `wire_ack` / `delegate` 等の新ツール、廃止ツール (`tmux_*`, `add_wing`, `eval_ruby`, `open_canvas` 等) を明記
- `skills/vantage-point/reference/mcp-tools.md` を v0.40 向けに全面書き換え
- `README.md` を現行機能構成に整理 (Browser Mode / open_canvas / Heaven's Door 等の旧記述を削除)
- wiremsg 移行に doc を同期: `msg_send` 等 → `wire_send` / `wire_recv` / `wire_thread` / `wire_inbox` / `wire_ack` (VP 本体 PR #406〜#420)
- `vp mailbox` CLI → `vp wire watch` / `vp wire send` / `vp wire watch-supervised` に同期
- hooks スクリプトの用語を conductor/performer に更新 (`block-ask-in-worker.sh`, `lane-status.sh`)
- `commands/show.md`: browser viewer → Canvas (Paisley Park) 表記に修正


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
