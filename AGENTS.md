# Vision

Pour examiner une image ou une capture, utiliser d'abord la vision native. Utiliser `opencode-eyes` seulement si elle échoue et ne jamais déduire le contenu du nom de fichier.

# Roblox

Pour une tâche Roblox/Luau qui touche Studio, l'API Roblox, le réseau, la persistance, la sécurité ou le playtest, charger `.claude/skills/roblox-dev-skill/SKILL.md`, puis uniquement les références directement utiles. Pour une recherche statique de fichier ou une petite modification locale, ne pas charger ce skill. Les recherches d'API passent par les outils Roblox officiels disponibles.

## Studio et Rojo

- N'interroger Studio que si la tâche nécessite son état, une exécution ou un playtest. Une revue statique reste sur disque.
- Avant tout playtest, vérifier en mode Edit que Studio contient un marqueur de la dernière modification disque.
- Si le marqueur manque, vérifier qu'un seul `rojo serve default.project.json` tourne, le relancer si nécessaire, puis demander à l'humain de cliquer **Connect**.
- Ne jamais diagnostiquer le code depuis la copie Play, qui est figée au démarrage. Confirmer la source avant toute vérification visuelle.
- `[profilestore]: Roblox API services unavailable` est attendu dans un Studio non publié utilisant le mock.
- Garder les sessions et sorties Studio courtes.

# Priorités produit

Pour toute tâche gameplay, lire `docs/product/NORTH_STAR.md`, puis `docs/product/NON_GOALS.md` et `docs/product/ROADMAP.md`. Le vertical slice de `docs/production/VERTICAL_SLICE.md` est prioritaire. Ne pas ajouter de feature majeure sans problème joueur observé ou mesuré.

## Politique Luau

Tout fichier Luau nouveau ou modifié commence par `--!strict`. Les migrations de `src/` existant restent progressives.

## Orchestration

Pour un bug, tracer les appelants et corriger la racine partagée. Avant un playtest, vérifier la synchronisation Rojo en mode Edit; ne jamais diagnostiquer depuis une copie Play. Un seul `rojo serve default.project.json` doit tourner. Le message ProfileStore indiquant que les API Roblox sont indisponibles est attendu dans Studio non publié.

# Skills de process

Utiliser `playtest-report`, `bug-report`, `bug-triage`, `retrospective`, `scope-check` ou `balance-check` uniquement lorsque la demande correspond explicitement à leur finalité. Ne pas inventorier ni charger les autres skills par défaut.

Les modèles de documents sont dans `docs/templates/`. Les sources MIT sont listées dans `THIRD_PARTY_NOTICES.md`.

## Lecture économique

Ne pas lire par défaut `.superpowers/`, `.codex/`, les miroirs générés `.agents/`, `ServerPackages/`, `Packages/`, les builds Roblox, `sourcemap.json` et `docs/superpowers/`. Ouvrir la bible de design uniquement pour une tâche de gameplay, d'économie ou de direction créative. Charger les références du skill Roblox uniquement si la question les nécessite.
