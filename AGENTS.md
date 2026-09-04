# Vision

## Priorités produit

Lire `docs/product/NORTH_STAR.md`, puis `docs/product/NON_GOALS.md` et `docs/product/ROADMAP.md` pour toute tâche gameplay. Le vertical slice de `docs/production/VERTICAL_SLICE.md` est prioritaire. Ne pas implémenter une nouvelle feature majeure sans problème joueur observé ou mesuré.

## Politique Luau

Tout nouveau fichier Luau et tout fichier Luau modifié doit commencer par `--!strict`. La migration de `src/` existant est progressive; ne pas l'imposer aveuglément.

Dès qu'une image, capture d'écran ou screenshot doit être examinée, décrite ou vérifiée visuellement, délègue systématiquement à l'agent `eyes` (outil `task`, avec le chemin exact du fichier) avant de répondre. Ne la décris jamais toi-même en premier. Base-toi uniquement sur ce que `eyes` rapporte ; s'il dit « je ne vois pas », rapporte-le tel quel.

# Roblox

Toute tâche liée à Roblox, Luau, Studio, au MCP `roblox` (outils `roblox_*`) ou au développement de ce jeu : charge **toujours** le skill projet `roblox-dev-skill` (`.claude/skills/roblox-dev-skill/`) — connaissances domaine Luau/Rojo/réseau/sécurité/perf. Le lookup API passe par les outils MCP officiels (`roblox_http_get`, `rbx-docs-search`).

## Synchro Rojo — procédure obligatoire

1. Avant TOUTE session de playtest : vérifier la synchro via un execute Luau **Edit** (ex. lire `ReplicatedStorage.Shared.Config.Source` et chercher le marqueur de la dernière modification disque). Si absent → rojo est mort : relancer `rojo serve default.project.json` (un seul processus), puis demander à l'humain de cliquer **Connect** dans le plugin Studio.
2. Ne jamais diagnostiquer depuis une copie Play : Play est une copie figée au spawn. Les vérifications de code se font en Edit ; les vérifications visuelles uniquement après confirmation que la copie Play contient la dernière source.
3. Un seul processus `rojo serve` à la fois (`Get-Process rojo` doit montrer ≤ 2 PID parent/enfant).
4. Le message `[profilestore]: Roblox API services unavailable` est **attendu** en Studio non publié (mock) — ne pas le traiter comme une erreur.
5. Sessions courtes : éviter les dumps complets de logs/captures dans les tours ; les longues boucles de diagnostic saturent le contexte et coupent la session.

# Orchestration des process

## Skills projet (`.claude/skills/`)

- **Connaissance domaine** : `roblox-dev-skill` (+ `references/` — datastore, networking, sécurité, perf, UI, migration, monétisation).
- **Process** : `playtest-report`, `bug-report`, `bug-triage`, `retrospective`, `scope-check`, `balance-check`.
- **Templates** : `docs/templates/` — game-design-document, systems-index, milestone-definition, sprint-plan, post-mortem, prototype-report.

## Précédence

1. Demandes directes de l'utilisateur
2. Superpowers (process) : brainstorming, writing-plans, systematic-debugging, test-driven-development, verification-before-completion
3. Skills projet ci-dessus (domaine)
4. Ponytail gouverne uniquement le style de sortie (lean, YAGNI)

## Routage

| Déclencheur | Chaîne |
|---|---|
| Nouvelle feature / système | brainstorming → fiche GDD (`docs/templates/game-design-document.md`) si méritée → writing-plans |
| Bug | bug-report → bug-triage → systematic-debugging → fix → verification-before-completion |
| Fin de lot | retrospective (+ template post-mortem si lot majeur) |
| Avant validation d'un lot | scope-check |
| Session playtest MCP Studio | playtest-report |
| Équilibrage économie / revenus | balance-check |

Mode lean par défaut : les skills projet sautent leur cérémonie optionnelle sauf demande explicite.

Sources tierces MIT : voir `THIRD_PARTY_NOTICES.md`.
