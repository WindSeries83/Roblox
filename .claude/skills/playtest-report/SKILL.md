---
name: playtest-report
description: "Structure playtest feedback into a report, or produce a collection template."
argument-hint: "[new|analyze path-to-notes]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
tier: standard
---

## Contexte projet

- Roblox/Luau (`--!strict`), repo Rojo — procédure synchro dans AGENTS.md.
- Bible design : `docs/RIFT_BEASTS_1_bible_design.md` · Plans : `docs/superpowers/plans/`.
- Playtests via MCP Studio (outils `roblox_*`) : captures + console pour les preuves.

> Mode lean par défaut (ponytail) : saute toute cérémonie optionnelle sauf demande explicite de l'utilisateur.

## Phase 1: Parse Arguments

Determine the mode:

- `new` → generate a blank playtest report template
- `analyze [path]` → read raw notes and fill in the template with structured findings

If no argument is provided, ask the user which mode to use before proceeding.

---

## Phase 2A: New Template Mode

Generate this template and output it to the user:

```markdown
# Playtest Report

## Session Info
- **Date**: [Date]
- **Build**: [Version/Commit]
- **Duration**: [Time played]
- **Tester**: [Name/ID]
- **Platform**: [PC/Mobile/Console]
- **Input Method**: [KB+M / Gamepad / Touch]
- **Session Type**: [First time / Returning / Targeted test]

## Test Focus
[What specific features or flows were being tested]

## First Impressions (First 5 minutes)
- **Understood the goal?** [Yes/No/Partially]
- **Understood the controls?** [Yes/No/Partially]
- **Emotional response**: [Engaged/Confused/Bored/Frustrated/Excited]
- **Notes**: [Observations]

## Gameplay Flow
### What worked well
- [Observation 1]

### Pain points
- [Issue 1 -- Severity: High/Medium/Low]

### Confusion points
- [Where the player was confused and why]

### Moments of delight
- [What surprised or pleased the player]

## Bugs Encountered
| # | Description | Severity | Reproducible |
|---|-------------|----------|-------------|

## Feature-Specific Feedback
### [Feature 1]
- **Understood purpose?** [Yes/No]
- **Found engaging?** [Yes/No]
- **Suggestions**: [Tester suggestions]

## Quantitative Data (if available)
- **Deaths**: [Count and locations]
- **Time per area**: [Breakdown]
- **Items used**: [What and when]
- **Features discovered vs missed**: [List]

## Overall Assessment
- **Would play again?** [Yes/No/Maybe]
- **Difficulty**: [Too Easy / Just Right / Too Hard]
- **Pacing**: [Too Slow / Good / Too Fast]
- **Session length preference**: [Shorter / Good / Longer]

## Top 3 Priorities from this session
1. [Most important finding]
2. [Second priority]
3. [Third priority]
```

---

## Phase 2B: Analyze Mode

Read the raw notes at the provided path. Cross-reference with existing design documents (start with the bible design: `docs/RIFT_BEASTS_1_bible_design.md`). Fill in the template above with structured findings. Flag any playtest observations that conflict with design intent. Attach MCP Studio evidence (captures via `roblox_screen_capture`, console output via `roblox_get_console_output`) where relevant.

---

## Phase 3: Action Routing

Categorize all findings into four buckets:

- **Design changes needed** — fun issues, player confusion, broken mechanics, observations that conflict with the bible design's intended experience
- **Balance adjustments** — numbers feel wrong, difficulty too spiked or too flat
- **Bug reports** — clear implementation defects that are reproducible
- **Polish items** — not blocking progress, but friction or feel issues for later

Present the categorized list, then route:

- **Design changes:** check downstream impacts against the bible design (`docs/RIFT_BEASTS_1_bible_design.md`) before making changes.
- **Balance adjustments:** verify the full balance picture before tuning values.
- **Bugs:** "Use `/bug-report` to formally track these."
- **Polish items:** "Add to the polish backlog in `docs/production/` when you reach that phase."

---

## Phase 4: Save Report

Ask: "May I write this playtest report to `docs/production/qa/playtests/playtest-[date]-[tester].md`?"

If yes, write the file, creating the directory if needed.

---

## Phase 5: Next Steps

Verdict: **COMPLETE** — playtest report generated.

- Act on the highest-priority finding category first.
- After addressing design changes: re-check the updated sections of the bible design.
- After fixing bugs: re-run `/bug-triage` to update priorities.

---

## Chaîne

Voir la table de routage dans AGENTS.md.

- playtest-report → skill suivant : `bug-report`
- bug-report → skill suivant : `bug-triage`
- bug-triage → skill suivant : `systematic-debugging` (superpowers) pour la correction racine
