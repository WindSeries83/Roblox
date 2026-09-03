---
name: roblox-dev-skill
description: Roblox and Luau development for this Rojo game, including Studio MCP, architecture, networking, persistence, security, performance, UI, assets, migration, and monetization. Use for every Roblox, Luau, Studio, or Roblox MCP task.
---

# Roblox Development

This repository is the Roblox game **RIFT BEASTS**, written in strict Luau and synchronized with Rojo. Follow the playtest and Rojo rules in `AGENTS.md`.

## Start with the existing game

- Detect the available `Roblox_Studio` MCP tools on every invocation.
- Read existing scripts and inspect the DataModel before proposing or applying changes.
- Prefer `script_search`, `script_grep`, `script_read`, `search_game_tree`, and `inspect_instance` for discovery; use `multi_edit` for Studio edits and `execute_luau` for focused checks.
- If Studio MCP is unavailable, provide copy-paste-ready Luau with its exact service/container.

## Invariants

- Use `--!strict` for new scripts and follow the official Roblox Lua style.
- Keep game-state mutation and trust decisions server-authoritative. Validate client types, ranges, permissions, and rate limits.
- Keep secrets and sensitive logic server-side. Never expose them through `ReplicatedStorage`.
- Use modern `task.*` APIs, disconnect event connections during cleanup, and wrap fallible yielding APIs in `pcall` or `xpcall`.
- Put server, client, shared, server-only, and UI code in their appropriate Roblox services.
- Fix shared root causes and leave the smallest relevant executable check for non-trivial logic.

## Load only the needed reference

| Need | Reference |
|---|---|
| Luau types, syntax, naming, modern APIs | `references/luau-fundamentals.md` |
| Layout and architecture | `references/project-structure.md` |
| DataStore or ProfileStore | `references/datastore-persistence.md` |
| RemoteEvents, input, client/server | `references/networking.md` |
| Exploit resistance, authority, bans | `references/security-hardening.md` |
| Performance, memory, Parallel Luau | `references/performance-optimization.md` |
| Studio MCP workflows | `references/mcp-integration.md` |
| GUI, HUD, menus | `references/ui-systems.md` |
| Deprecated APIs or legacy migration | `references/legacy-migration.md` |
| Purchases, passes, subscriptions | `references/monetization.md` |
| Import, export, and assets | `references/file-formats-and-assets.md` |

Read every reference that materially applies, but no unrelated reference.

## Official documentation

Use local references first. When current API details are needed, fetch official markdown with `http_get`:

- Engine member: `https://create.roblox.com/docs/reference/engine/classes/<ClassName>.md`
- Guide: `https://create.roblox.com/docs/<path>.md`
- Index: `https://create.roblox.com/docs/llms.txt`

Engine APIs and Open Cloud REST APIs are separate systems. Confirm deprecated members in the official class page. If official sources remain unclear, ask before relying on an uncertain API.

For `/roblox-update`, research current official release notes and documentation, compare them with the relevant references, report the differences, then update only confirmed facts.
