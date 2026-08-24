---
name: scope-check
description: "Compare current scope against the original plan, quantify creep, and recommend cuts."
argument-hint: "[feature-name or sprint-N]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
tier: light
---

## Contexte projet
- Roblox/Luau (`--!strict`), repo Rojo — procédure synchro dans AGENTS.md.
- Bible design : `docs/RIFT_BEASTS_1_bible_design.md` · Plans : `docs/superpowers/plans/`.
- Travail par lots : scope-check typiquement en fin de lot ou avant d'écrire un nouveau plan (« sprint » ci-dessous = « lot »).

Mode lean par défaut (ponytail) : saute toute cérémonie optionnelle sauf demande explicite de l'utilisateur.

# Scope Check

This skill is read-only — it reports findings but writes no files.

Compares original planned scope against current state to detect, quantify, and triage
scope creep.

**Argument:** `$ARGUMENTS[0]` — feature name, sprint number, or milestone name.

---

## Phase 1: Find the Original Plan

Locate the baseline scope document for the given argument:

- **Feature name** → read `docs/design/[feature].md` or matching file in `docs/design/`
  (ou le plan de lot correspondant dans `docs/superpowers/plans/`)
- **Sprint number** (e.g., `sprint-3`) → read `docs/production/sprints/sprint-03.md` or similar
- **Milestone** → read `docs/production/milestones/[name].md`

If the document is not found, report the missing file and stop. Do not proceed without
a baseline to compare against.

---

## Phase 2: Read the Current State

Check what has actually been implemented or is in progress:

- Scan the codebase (`src/`) for files related to the feature/sprint
- Read git log for commits related to this work (`git log --oneline --since=[start-date]`)
- Check for TODO/FIXME comments that indicate unfinished scope additions
- Check active lot plan if the feature is mid-lot

---

## Phase 3: Compare Original vs Current Scope

Produce the comparison report:

```markdown
## Scope Check: [Feature/Sprint Name]
Generated: [Date]

### Original Scope
[List of items from the original plan]

### Current Scope
[List of items currently implemented or in progress]

### Scope Additions (not in original plan)
| Addition | Source | When | Justified? | Effort |
|----------|--------|------|------------|--------|
| [item] | [commit/person] | [date] | [Yes/No/Unclear] | [S/M/L] |

### Scope Removals (in original but dropped)
| Removed Item | Reason | Impact |
|-------------|--------|--------|
| [item] | [why removed] | [what's affected] |

### Bloat Score
- Original items: [N]
- Current items: [N]
- Items added: [N] (+[X]%)
- Items removed: [N]
- Net scope change: [+/-N] ([X]%)

### Risk Assessment
- **Schedule Risk**: [Low/Medium/High] — [explanation]
- **Quality Risk**: [Low/Medium/High] — [explanation]
- **Integration Risk**: [Low/Medium/High] — [explanation]

### Recommendations
1. **Cut**: [Items that should be removed to stay on schedule]
2. **Defer**: [Items that can move to a future sprint/version]
3. **Keep**: [Additions that are genuinely necessary]
4. **Flag**: [Items that need a decision from the user]
```

---

## Phase 4: Verdict

Assign a canonical verdict based on net scope change:

| Net Change | Verdict | Meaning |
|-----------|---------|---------|
| ≤10% | **PASS** | On Track — within acceptable variance |
| 10–25% | **CONCERNS** | Minor Creep — manageable with targeted cuts |
| 25–50% | **FAIL** | Significant Creep — must cut or formally extend timeline |
| >50% | **FAIL** | Out of Control — stop, re-plan, flag to the user |

Output the verdict prominently:

```
**Scope Verdict: [PASS / CONCERNS / FAIL]**
Net change: [+X%] — [On Track / Minor Creep / Significant Creep / Out of Control]
```

---

## Phase 5: Next Steps

After presenting the report, offer concrete follow-up:

- **PASS** → no action required. Suggest re-running before next milestone.
- **CONCERNS** → offer to identify the 2–3 additions with best cut ratio. Reference revising the lot plan (`writing-plans`) to formally re-scope.
- **FAIL** → recommend flagging to the user before proceeding. Reference revising the lot plan (`writing-plans`) for re-planning or re-baselining the timeline.

Always end with:
> "Run `/scope-check [name]` again after cuts are made to verify the verdict improves."

---

### Rules

- Scope creep is additions without corresponding cuts or timeline extensions
- Not all additions are bad — some are discovered requirements. But they must be acknowledged and accounted for
- When recommending cuts, prioritize preserving the core player experience over nice-to-haves
- Always quantify scope changes — "it feels bigger" is not actionable, "+35% items" is

---

## Chaîne

Voir la table de routage dans AGENTS.md.
- retrospective → si lot majeur : compléter avec le template `docs/templates/post-mortem.md`
- scope-check → si GO : passer à `writing-plans` (superpowers)
- balance-check → si ajustements : mettre à jour la fiche système correspondante dans `docs/design/` ou la bible
