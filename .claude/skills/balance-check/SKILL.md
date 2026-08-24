---
name: balance-check
description: "Find outliers, broken progressions, and economy imbalances in balance data. Use after changing balance values."
argument-hint: "[system-name|path-to-data-file]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion
tier: standard
---

## Contexte projet
- Roblox/Luau (`--!strict`), repo Rojo — procédure synchro dans AGENTS.md.
- Bible design : `docs/RIFT_BEASTS_1_bible_design.md` · Plans : `docs/superpowers/plans/`.
- Travail par lots : balance-check typiquement après l'implémentation jouable d'un système.

Mode lean par défaut (ponytail) : saute toute cérémonie optionnelle sauf demande explicite de l'utilisateur.

## Phase 1: Identify Balance Domain

Determine the balance domain from `$ARGUMENTS[0]`:

- **Combat** → weapon/ability DPS, time-to-kill, damage type interactions
- **Economy** → resource faucets/sinks, acquisition rates, item pricing
- **Progression** → XP/power curves, dead zones, power spikes
- **Loot** → rarity distribution, pity timers, inventory pressure
- **File path given** → load that file directly and infer domain from content

If no argument, ask the user which system to check.

---

## Phase 2: Read Data Files

Read relevant files from `src/` (données de jeu côté Roblox, ex. modules sous `ReplicatedStorage.Shared.Config`) and `docs/design/balance/` for the identified domain.
Note every file read — they will appear in the Data Sources section of the report.

---

## Phase 3: Read Design Document

Read the system's design sheet from `docs/design/` (et la bible `docs/RIFT_BEASTS_1_bible_design.md`) to understand intended design targets,
tuning knobs, and expected value ranges. This is the baseline for "correct" behaviour.

---

## Phase 4: Perform Analysis

Run domain-specific checks:

**Combat balance:**
- Calculate DPS for all weapons/abilities at each power tier
- Check time-to-kill at each tier
- Identify any options that dominate all others (strictly better)
- Check if defensive options can create unkillable states
- Verify damage type/resistance interactions are balanced

**Economy balance:**
- Map all resource faucets and sinks with flow rates
- Project resource accumulation over time
- Check for infinite resource loops
- Verify currency sinks scale with currency generation
- Check if any items are never worth purchasing

**Progression balance:**
- Plot the XP curve and power curve
- Check for dead zones (no meaningful progression for too long)
- Check for power spikes (sudden jumps in capability)
- Verify content gates align with expected player power
- Check if skip/grind strategies break intended pacing

**Loot balance:**
- Calculate expected time to acquire each rarity tier
- Check pity timer math
- Verify no loot is strictly useless at any stage
- Check inventory pressure vs acquisition rate

---

## Phase 5: Output the Analysis

```
## Balance Check: [System Name]

### Data Sources Analyzed
- [List of files read]

### Health Summary: [HEALTHY / CONCERNS / CRITICAL ISSUES]

### Outliers Detected
| Item/Value | Expected Range | Actual | Issue |
|-----------|---------------|--------|-------|

### Degenerate Strategies Found
- [Strategy description and why it is problematic]

### Progression Analysis
[Graph description or table showing progression curve health]

### Recommendations
| Priority | Issue | Suggested Fix | Impact |
|----------|-------|--------------|--------|

### Values That Need Attention
[Specific values with suggested adjustments and rationale]
```

---

## Phase 6: Fix & Verify Cycle

After presenting the report, use the platform's question UI:
- Prompt: "Balance check complete. What would you like to do next?"
- Options:
  - `[A] Fix highest-priority issue now — walk me through it`
  - `[B] Save report to docs/design/balance/balance-check-[system]-[date].md`
  - `[C] Stop here — I'll review the findings manually`

If [A]:
- Ask which issue to address first (refer to the Recommendations table by priority row)
- Guide the user to update the relevant data file in `src/` or formula in `docs/design/balance/`
- After each fix, offer to re-run the relevant balance checks to verify no new outliers were introduced
- If the fix changes a tuning knob defined in a design sheet or the bible, remind the user:
  > "This value is defined in a design document. Check downstream impacts on affected systems before committing."

If [B]:
- Write the report to `docs/design/balance/balance-check-[system]-[date].md` (create the directory if needed). Use the current date for [date] in YYYY-MM-DD format.
- Confirm the file was written, then end with: "Re-run `/balance-check` after fixes to verify."

If [C]:
- Summarize open issues and end with: "Re-run `/balance-check` after fixes to verify."

---

## Chaîne

Voir la table de routage dans AGENTS.md.
- retrospective → si lot majeur : compléter avec le template `docs/templates/post-mortem.md`
- scope-check → si GO : passer à `writing-plans` (superpowers)
- balance-check → si ajustements : mettre à jour la fiche système correspondante dans `docs/design/` ou la bible
