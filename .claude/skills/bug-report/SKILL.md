---
name: bug-report
description: "Write a structured bug report with repro steps, severity, and context."
argument-hint: "[description] | analyze [path-to-file]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash
tier: standard
---

## Contexte projet

- Roblox/Luau (`--!strict`), repo Rojo — procédure synchro dans AGENTS.md.
- Bible design : `docs/RIFT_BEASTS_1_bible_design.md` · Plans : `docs/superpowers/plans/`.
- Playtests via MCP Studio (outils `roblox_*`) : captures + console pour les preuves.

> Mode lean par défaut (ponytail) : saute toute cérémonie optionnelle sauf demande explicite de l'utilisateur.

## Phase 1: Parse Arguments

Determine the mode from the argument:

- No keyword → **Description Mode**: generate a structured bug report from the provided description
- `analyze [path]` → **Analyze Mode**: read the target file(s) and identify potential bugs
- `verify [BUG-ID]` → **Verify Mode**: confirm a reported fix actually resolved the bug
- `close [BUG-ID]` → **Close Mode**: mark a verified bug as closed with resolution record

If no argument is provided, ask the user for a bug description before proceeding.

---

## Phase 2A: Description Mode

1. **Parse the description** for key information: what broke, when, how to reproduce it, and what the expected behavior is.

2. **Search the codebase** for related files using Grep/Glob to add context (affected system, likely files).

3. **Draft the bug report**:

```markdown
# Bug Report

## Summary
**Title**: [Concise, descriptive title]
**ID**: BUG-[NNNN]
**Severity**: [S1-Critical / S2-Major / S3-Minor / S4-Trivial]
**Priority**: [P1-Immediate / P2-Next Sprint / P3-Backlog / P4-Wishlist]
**Status**: Open
**Reported**: [Date]
**Reporter**: [Name]

## Classification
- **Category**: [Gameplay / UI / Audio / Visual / Performance / Crash / Network]
- **System**: [Which game system is affected]
- **Frequency**: [Always / Often (>50%) / Sometimes (10-50%) / Rare (<10%)]
- **Regression**: [Yes/No/Unknown -- was this working before?]

## Environment
- **Build**: [Version or commit hash]
- **Platform**: [Studio Play / Live — device if relevant]
- **Scene/Level**: [Where in the game (Workspace path, place)]
- **Game State**: [Relevant state -- inventory, quest progress, etc.]

## Reproduction Steps
**Preconditions**: [Required state before starting]

1. [Exact step 1]
2. [Exact step 2]
3. [Exact step 3]

**Expected Result**: [What should happen]
**Actual Result**: [What actually happens]

## Technical Context
- **Likely affected files**: [List of files based on codebase search (Luau sources under `src/`)]
- **Related systems**: [What other systems might be involved]
- **Possible root cause**: [If identifiable from the description]

## Evidence
- **Logs**: [Relevant console output if available (`roblox_get_console_output`)]
- **Visual**: [Description of visual evidence — capture via `roblox_screen_capture`]

## Related Issues
- [Links to related bugs or design documents]

## Notes
[Any additional context or observations]
```

---

## Phase 2B: Analyze Mode

1. **Read the target file(s)** specified in the argument.

2. **Identify potential bugs**: null references, off-by-one errors, race conditions, unhandled edge cases, resource leaks, incorrect state transitions.

3. **For each potential bug**, generate a bug report using the template above, with the likely trigger scenario and recommended fix filled in.

---

## Phase 2C: Verify Mode

Read `docs/production/qa/bugs/[BUG-ID].md`. Extract the reproduction steps and expected result.

1. **Re-run reproduction steps** — launch the game via MCP Studio (`roblox_start_stop_play`) and replay the repro steps if they're launch/state-reachable; use `roblox_execute_luau`, game tree inspection and console output as evidence. Otherwise fall back to using Grep/Glob to check whether the root cause code path still exists as described. If the fix removed or changed it, note the change.
2. **Run the related test** — if the bug's system has an automated test, run it via Bash and report pass/fail.
3. **Check for regression** — grep the codebase for any new occurrence of the pattern that caused the bug.

Produce a verification verdict:

- **VERIFIED FIXED** — reproduction steps no longer produce the bug; related tests pass
- **STILL PRESENT** — bug reproduces as described; fix did not resolve the issue
- **CANNOT VERIFY** — automated checks inconclusive; manual playtest required

Ask: "May I update `docs/production/qa/bugs/[BUG-ID].md` to set Status: Verified Fixed / Still Present / Cannot Verify?"

If STILL PRESENT: reopen the bug, set Status back to Open, and suggest a new root-cause pass via `systematic-debugging`.

---

## Phase 2D: Close Mode

Read `docs/production/qa/bugs/[BUG-ID].md`. Confirm Status is `Verified Fixed` before closing. If status is anything else, stop: "Bug [ID] must be Verified Fixed before it can be closed. Run `/bug-report verify [BUG-ID]` first."

Append a closure record to the bug file:

```markdown
## Closure Record
**Closed**: [date]
**Resolution**: Fixed — [one-line description of what was changed]
**Fix commit / PR**: [if known]
**Verified by**: l'agent
**Closed by**: [user]
**Regression test**: [test file path, or "Manual verification"]
**Status**: Closed
```

Update the top-level `**Status**: Open` field to `**Status**: Closed`.

Ask: "May I update `docs/production/qa/bugs/[BUG-ID].md` to mark it Closed?"

After closing, check `docs/production/qa/bug-triage-*.md` — if the bug appears in an open triage report, note: "Bug [ID] is referenced in the triage report. Run `/bug-triage` to refresh the open bug count."

---

## Phase 3: Save Report

Present the completed bug report(s) to the user.

Ask: "May I write this to `docs/production/qa/bugs/BUG-[NNNN].md`?"

If yes, write the file, creating the directory if needed. Verdict: **COMPLETE** — bug report filed.

If no, stop here. Verdict: **BLOCKED** — user declined write.

---

## Phase 4: Next Steps

After saving, suggest based on mode:

**After filing (Description/Analyze mode):**
- Run `/bug-triage` to prioritize alongside existing open bugs
- If S1 or S2: fix immediately — root cause via `systematic-debugging`, closure via `verification-before-completion`

**After fixing the bug (developer confirms fix is in):**
- Run `/bug-report verify [BUG-ID]` — confirm the fix actually works before closing
- Never mark a bug closed without verification — a fix that doesn't verify is still Open

**After verify returns VERIFIED FIXED:**
- Run `/bug-report close [BUG-ID]` — write the closure record and update status
- Run `/bug-triage` to refresh the open bug count and remove it from the active list

---

## Chaîne

Voir la table de routage dans AGENTS.md.

- playtest-report → skill suivant : `bug-report`
- bug-report → skill suivant : `bug-triage`
- bug-triage → skill suivant : `systematic-debugging` (superpowers) pour la correction racine
