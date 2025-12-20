---
description: Display content in the Vantage Point dashboard
---

# Show Content

Display content in the Vantage Point browser viewer.

## Usage

Use the `mcp__vantage-point__show` tool with:

- `content` - The content to display (markdown, HTML, or plain text)
- `pane_id` - Target pane: "main" (default), "left", or "right"
- `content_type` - Format: "markdown" (default), "html", or "log"
- `append` - Set to true to append instead of replace

## Examples

```
# Show markdown in main pane
mcp__vantage-point__show(content: "# Hello", pane_id: "main")

# Append to right pane
mcp__vantage-point__show(content: "New info", pane_id: "right", append: true)
```
