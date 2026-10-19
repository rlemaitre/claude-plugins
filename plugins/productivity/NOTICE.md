# Notice

This plugin is a modified copy of the `productivity` plugin from
[anthropics/knowledge-work-plugins](https://github.com/anthropics/knowledge-work-plugins), version 1.3.1
(upstream folder tree `f51844e`, latest upstream commit `c71b6f3`, 2026-09-21), licensed under the Apache License 2.0 (see `LICENSE`).

Changes from upstream:

- `.mcp.json` removed: the plugin bundles no MCP servers. Its servers (Slack, Notion, Linear, Asana, Atlassian,
  monday.com, ClickUp, Google Calendar, Gmail) duplicated connectors already configured in Claude Code, and a plugin's
  MCP servers can only be disabled one project at a time.
- `CONNECTORS.md`: one sentence and one table header adjusted to say no servers are bundled.

Skills and the dashboard are unchanged.
