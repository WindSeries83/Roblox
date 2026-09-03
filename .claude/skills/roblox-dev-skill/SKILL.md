---
name: roblox-dev-skill
description: Use for Roblox and Luau development, including Studio, Rojo, networking, persistence, security, performance, UI, monetization, and Roblox MCP operations.
---

# Roblox development

Use the repository's existing architecture and `--!strict` conventions. Read the smallest relevant code path before changing it. Keep game-critical decisions server-authoritative, validate remote input, and avoid yielding or expensive work in hot paths.

## Route only what the task needs

- Luau syntax or idioms: `references/luau-fundamentals.md`
- Project layout or architecture: `references/project-structure.md`
- Remotes and replication: `references/networking.md`
- DataStore/ProfileStore: `references/datastore-persistence.md`
- Trust boundaries or exploits: `references/security-hardening.md`
- Performance: `references/performance-optimization.md`
- UI: `references/ui-systems.md`
- Monetization: `references/monetization.md`
- Legacy conversion: `references/legacy-migration.md`
- Assets and file formats: `references/file-formats-and-assets.md`
- Studio MCP details: `references/mcp-integration.md`

Do not load unrelated references.

## Roblox Studio

Use Studio only when the task requires live game state, execution, scene inspection, device simulation, profiling, or playtesting. Static planning and code review stay on disk.

When Studio is required:

1. Call `list_roblox_studios` and pass the selected `studio_id` to later calls.
2. Read state with `get_studio_state` before acting.
3. Load only the relevant MCP capability, such as `rbx-unit-test`, `rbx-debug`, `rbx-device-simulator-lua`, `rbx-docs-search`, `rbx-scene-analysis`, or `rbx-perf-profiling`.
4. Prefer current tools such as `script_read`, `script_search`, `execute_luau`, `start_play`, `stop_play`, and `get_output`. Do not assume obsolete aliases such as `set_active_studio` or `roblox_start_stop_play` exist.

Before a playtest, follow the Rojo synchronization procedure in the repository `AGENTS.md`. Never infer code freshness from a running Play copy.

For API facts, prefer official Roblox documentation and the available `rbx-docs-search` or `roblox_http_get` capability.
