# Vision

Dès qu'une image ou capture doit être examinée ou vérifiée visuellement, délègue à l'agent `eyes` avec le chemin exact du fichier avant de répondre. Base-toi uniquement sur son rapport ; s'il dit « je ne vois pas », rapporte-le tel quel.

# Roblox

Pour toute tâche liée à Roblox, Luau, Studio, au MCP Roblox ou à ce jeu, charge le skill projet `.claude/skills/roblox-dev-skill/`. Utilise `http_get` pour consulter la documentation Roblox officielle.

## Synchro Rojo obligatoire avant tout playtest

1. En mode **Edit**, exécuter du Luau pour vérifier que `ReplicatedStorage.Shared.Config.Source` contient le marqueur de la dernière modification disque.
2. Si le marqueur manque, relancer un seul `rojo serve default.project.json`, puis demander à l'humain de cliquer **Connect** dans le plugin Studio.
3. Ne jamais diagnostiquer le code depuis une copie Play figée. Ne vérifier visuellement qu'après confirmation que Play contient la dernière source.
4. `Get-Process rojo` doit montrer au plus deux PID parent/enfant.
5. `[profilestore]: Roblox API services unavailable` est attendu dans un Studio non publié utilisant le mock.
6. Garder les sessions courtes et éviter les dumps complets de logs ou captures.

# Process

Priorité : demande utilisateur → Superpowers → skills projet → Ponytail pour le style lean.

| Déclencheur | Chaîne minimale |
|---|---|
| Nouvelle feature | brainstorming → GDD si nécessaire → writing-plans |
| Bug | bug-report → bug-triage → systematic-debugging → fix → verification-before-completion |
| Fin de lot | retrospective ; post-mortem seulement si le lot est majeur |
| Validation de lot | scope-check |
| Playtest Studio | playtest-report |
| Économie ou revenus | balance-check |

Les skills projet sont dans `.claude/skills/` et les templates dans `docs/templates/`. Sauter toute cérémonie optionnelle en mode lean.

Sources tierces MIT : `THIRD_PARTY_NOTICES.md`.
