---
description: Initialize the Chronista Dashboard
---

# Dashboard Initialization

Initialize the full Chronista Dashboard with 3 panes.

## Pane Configuration

| Pane | Content | Update Trigger |
|------|---------|----------------|
| left | creo-memories | Session start, memory operations |
| main | Todos + Next Actions | TodoWrite, session start |
| right | Context, Research, SDG | On-demand, WebSearch/Fetch |

## Display Rules

- **Todos**: Always visible in main pane
- **Next Actions**: Shown when todo list is empty (from `gh issue list --label next`)
- **Context**: Toggle visibility on demand
- **Memories**: Auto-updated from creo-memories

## Usage

Call this command to initialize all panes with current state.
