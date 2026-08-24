---
name: roblox-dev-skill
description: >
  Core scripting and engine skill for Roblox game development.
  Covers full-lifecycle development: architecture, Luau scripting, debugging, security,
  performance, data persistence, networking, and the Roblox Studio environment.
  MUST use this skill whenever the user mentions: 'Roblox', 'Luau', 'Roblox Studio',
  'ServerScriptService', 'ReplicatedStorage', 'DataStoreService', 'RemoteEvent',
  or when working with Roblox Studio MCP tools like execute_luau, search_game_tree.
  Note: For UI/UX design, refer to roblox-design-skill and roblox-design-intelligence.
  For Audio, VFX, or Monetization, refer to their respective skills in the suite.
---

## Contexte projet

- Jeu Roblox « RIFT BEASTS » en Luau (`--!strict`), repo Rojo — procédure synchro Rojo dans AGENTS.md (obligatoire avant tout playtest).
- Lookup API prioritaire : outils MCP officiels `roblox_http_get` et `rbx-docs-search` — PAS de hub local `~/RobloxDocs/`.
- Ce skill couvre la CONNAISSANCE domaine (comment coder Roblox) ; les skills superpowers couvrent le PROCESS (brainstorming, debugging, TDD, plans) — voir table de routage dans AGENTS.md.

# Roblox Game Development Skill

Expert development companion for building Roblox experiences with Luau. Grounded in
official Roblox documentation (https://create.roblox.com/docs), the Luau language spec
(https://luau.org), and the Roblox Lua Style Guide (https://roblox.github.io/lua-style-guide/).

> **Engine**: Roblox Studio v733+ (August 2026). APIs update weekly — when in doubt,
> use `roblox_http_get` on https://create.roblox.com/docs pages or the
> `rbx-docs-search` skill to look up the latest Roblox API documentation.
> If information is still unclear, ask the user before proceeding.

---

## MCP Detection

On every invocation, detect available Roblox Studio MCP tools before proceeding:

### Official Roblox MCP (Roblox_Studio server)

Check for these tools from the `Roblox_Studio` MCP server:

| Tool | Purpose |
|------|---------|
| `execute_luau` | Run Luau code directly in Studio |
| `search_game_tree` | Search the Explorer/DataModel hierarchy |
| `script_search` / `script_grep` | Find scripts by name or content |
| `script_read` | Read script source code |
| `multi_edit` | Edit multiple scripts at once |
| `inspect_instance` | Inspect Instance properties |
| `insert_asset` / `search_asset` | Insert and search Roblox assets |
| `start_stop_play` | Start/stop playtesting |
| `get_console_output` | Read Output/console logs |
| `get_studio_state` | Get current Studio state |
| `screen_capture` / `store_image` | Capture and store screenshots |
| `generate_mesh` / `generate_procedural_model` | Generate 3D content |
| `generate_material` | Generate materials |
| `upload_image` | Upload images to Roblox |
| `character_navigation` | Navigate character in playtest |
| `user_mouse_input` / `user_keyboard_input` | Simulate user input |
| `list_roblox_studios` / `set_active_studio` | Manage Studio instances |

If MCP tools are available, prefer using them for:
- Reading existing scripts before writing new ones (`script_read`, `script_search`)
- Validating changes by running code (`execute_luau`)
- Inspecting game tree to understand project structure (`search_game_tree`)
- Testing changes with playtest (`start_stop_play`, `get_console_output`)

If MCP tools are NOT available, provide copy-paste-ready Luau scripts with clear
placement instructions (which service container to put them in).

---

## Routing Table

Match user intent to the appropriate reference file. Read the file BEFORE generating code.

| User Intent | Reference File |
|---|---|
| Luau syntax, types, naming conventions, style | `references/luau-fundamentals.md` |
| Project layout, architecture, patterns | `references/project-structure.md` |
| Save/load player data, DataStore, ProfileStore | `references/datastore-persistence.md` |
| Client-server communication, RemoteEvents, input | `references/networking.md` |
| Security, anti-exploit, server authority, bans | `references/security-hardening.md` |
| Performance, memory, optimization, Parallel Luau | `references/performance-optimization.md` |
| Using Roblox Studio MCP tools effectively | `references/mcp-integration.md` |
| UI, GUI, ScreenGui, menus, HUD, StyleQuery | `references/ui-systems.md` |
| Migrating legacy code, deprecated APIs | `references/legacy-migration.md` |
| Monetization, game passes, donations, transfers | `references/monetization.md` |
| File formats, import/export, asset management | `references/file-formats-and-assets.md` |

If the intent spans multiple domains, read all relevant files.
If a reference file doesn't cover a topic sufficiently, use the Official
Documentation Lookup workflow below.

---

## API & Documentation Lookup

### Priority 1: Local Reference Files

Check the **Routing Table** above first — read the relevant `references/*.md`
before generating code.

### Priority 2: Official Docs via `roblox_http_get`

Fetch the official page directly in clean markdown:

- Engine API class/member: `https://create.roblox.com/docs/reference/engine/classes/<ClassName>.md`
- Any guide/tutorial page: `https://create.roblox.com/docs/<path>.md`
- If unsure which page exists, browse the index: `https://create.roblox.com/docs/llms.txt`

### Priority 3: `rbx-docs-search` (MCP skill)

Invoke the `rbx-docs-search` skill (via `roblox_skill`) for guided lookup across
Engine API reference, creator guides, cloud API docs, and docs indexes.

### Lookup Workflow
1. Check if a **reference file** covers the topic (Routing Table above)
2. Otherwise fetch the official doc page with `roblox_http_get`
   - Example: `https://create.roblox.com/docs/reference/engine/classes/Part.md`
3. For broader discovery, use the `rbx-docs-search` skill
4. If still unclear, ask the user before proceeding

> **Important**: Engine APIs (Luau via `game:GetService()`) and Open Cloud APIs
> (HTTP REST via `x-api-key`) are **completely separate systems**. Using the
> wrong index will produce non-functional code.

> **Checking deprecated APIs**: Fetch the class page on the official docs
> (Priority 2) — deprecated members are marked there — and confirm with the
> user before using any deprecated API.

---

## Core Coding Standards

These rules apply to ALL generated Roblox/Luau code. They are non-negotiable.

### 1. Type Safety
- Use `--!strict` at the top of every new script
- Annotate function parameters and return types
- Define custom types with `type` keyword for complex data structures

### 2. Naming Conventions (Official Roblox Style)
- **PascalCase**: Classes, ModuleScripts, Constructors, Services — `CombatService`, `PlayerData`
- **camelCase**: Variables, functions, parameters — `playerHealth`, `calculateDamage()`
- **UPPER_SNAKE_CASE**: Constants — `MAX_HEALTH`, `DEFAULT_SPEED`
- Spell out words fully — avoid abbreviations
- Don't fully capitalize acronyms: `JsonTable` not `JSONTable`

### 3. Modern API Usage
- Use `task.spawn()`, `task.delay()`, `task.wait()` — NOT legacy `spawn()`, `delay()`, `wait()`
- Use `task.cancel()` to clean up deferred tasks
- Always disconnect event connections in cleanup: `connection:Disconnect()`
- Wrap fallible operations in `pcall()` or `xpcall()`

### 4. Architecture Rules
- **Server authority**: All game state mutations happen on the server
- **ModuleScripts** for shared logic — avoid monolithic scripts
- **Service/Controller pattern**: Services (server), Controllers (client)
- Scripts go in the correct container:
  - Server logic → `ServerScriptService`
  - Client logic → `StarterPlayerScripts` or `StarterCharacterScripts`
  - Shared modules → `ReplicatedStorage`
  - Server-only data → `ServerStorage`
  - UI → `StarterGui`

### 5. Error Handling
```lua
local success, result = pcall(function()
    return DataStoreService:GetDataStore("PlayerData"):GetAsync(key)
end)
if not success then
    warn("[DataService] Failed to load data:", result)
    -- Handle gracefully: use defaults, retry, etc.
end
```

### 6. Security (Always Apply)
- NEVER trust client-sent data — validate types, ranges, and permissions on server
- Keep sensitive logic in `ServerScriptService` (not visible to clients)
- Validate RemoteEvent arguments: check `typeof()`, ranges, and player state
- Rate-limit RemoteEvent calls from clients
- Never expose admin commands or server keys to ReplicatedStorage

---

## Script Template

When creating new scripts, use this template as a starting point:

```lua
--!strict
-- [ScriptName]
-- [Brief description of what this script does]
-- Container: [ServerScriptService/StarterPlayerScripts/ReplicatedStorage]

----- Services -----
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

----- Dependencies -----
-- local SomeModule = require(ReplicatedStorage.Modules.SomeModule)

----- Constants -----
local MAX_VALUE = 100

----- Types -----
type PlayerData = {
    coins: number,
    level: number,
    inventory: { string },
}

----- Variables -----
local activeConnections: { [Player]: { RBXScriptConnection } } = {}

----- Private Functions -----
local function cleanup(player: Player)
    local connections = activeConnections[player]
    if connections then
        for _, conn in connections do
            conn:Disconnect()
        end
        activeConnections[player] = nil
    end
end

----- Public / Event Handlers -----
local function onPlayerAdded(player: Player)
    activeConnections[player] = {}
    -- Setup logic here
end

----- Initialization -----
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(cleanup)

-- Handle players already in game (Studio hot-reload)
for _, player in Players:GetPlayers() do
    task.spawn(onPlayerAdded, player)
end
```

---

## Response Guidelines

1. **Ask before building**: If the request is vague, ask clarifying questions about genre, scale, and target audience
2. **Read before writing**: If MCP is available, read existing scripts and game tree before modifying
3. **Small slices**: Generate 50-100 lines at a time for complex systems — easier to debug
4. **Explain the why**: Comment non-obvious code and explain architectural decisions
5. **Test path**: Suggest how to test the code (playtest steps, console checks)
6. **Migration-aware**: When touching existing code, check for legacy patterns and suggest migration if appropriate — but never force it. Incremental migration is acceptable.

---

## Common Workflows

### New Feature
1. Read existing project structure (MCP: `search_game_tree`)
2. Identify where the feature fits in the architecture
3. Create ModuleScript(s) in the appropriate container
4. Wire up server/client communication if needed
5. Test via playtest (MCP: `start_stop_play` + `get_console_output`)

### Debug Issue
1. Read the relevant script (MCP: `script_read`)
2. Check console output (MCP: `get_console_output`)
3. Identify the root cause — look for:
   - Missing `pcall` around DataStore/HTTP calls
   - Client-server boundary issues
   - Connection leaks (missing Disconnect)
   - Race conditions (script execution order)
4. Apply minimal fix
5. Verify fix via playtest

### Code Review
1. Read scripts in the project (MCP: `script_grep`)
2. Check against Core Coding Standards above
3. Flag security issues (client trust, exposed data)
4. Flag performance issues (expensive loops, part count)
5. Suggest improvements with before/after examples

---

## Manual Knowledge Update

The user can trigger a full knowledge update at any time by saying:

```
/roblox-update
```

Or any natural variation like "update roblox skill knowledge", "refresh roblox dev skill".

### Update Protocol:
1. **Research** — Search for latest Roblox changes
   - DevForum release notes, API changelog, deprecation notices
   - Use web search for "Roblox developer updates {year}" and "Roblox API changes {month} {year}"
   - Visit https://devforum.roblox.com/c/updates/release-notes/58
2. **Compare** — Cross-check findings against existing reference files
3. **Report** — Present findings to user with clear "what changed" summary
4. **Discuss** — QnA with user on any decisions (add/remove/modify content)
5. **Apply** — Update reference files (keep what's correct, update what changed)
6. **Audit** — Full fact-check (file integrity + content verification)

> [!IMPORTANT]
> All updates must be research-based. No improvisation. When in doubt, ask the user.
> Fallback: consult official docs via `roblox_http_get` / `rbx-docs-search` or direct web search.
