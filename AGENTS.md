# Vision

Dès qu'une image, capture d'écran ou screenshot doit être examinée, décrite ou vérifiée visuellement, délègue systématiquement à l'agent `eyes` (outil `task`, avec le chemin exact du fichier) avant de répondre. Ne la décris jamais toi-même en premier. Base-toi uniquement sur ce que `eyes` rapporte ; s'il dit « je ne vois pas », rapporte-le tel quel.

# Roblox

Toute tâche liée à Roblox, Luau, Studio, au MCP `roblox` (outils `roblox_*`) ou au développement de ce jeu : charge **toujours** le skill `roblox-game` (outil `skill`, nom `roblox-game`) et suis-le. Tout le code et l'orchestration des outils `roblox_*` passent par ses références (`references/`, `workflows/`, `templates/`), en particulier `references/mcp-orchestration.md` pour la correspondance des outils.

## Synchro Rojo — procédure obligatoire

1. Avant TOUTE session de playtest : vérifier la synchro via un execute Luau **Edit** (ex. lire `ReplicatedStorage.Shared.Config.Source` et chercher le marqueur de la dernière modification disque). Si absent → rojo est mort : relancer `rojo serve default.project.json` (un seul processus), puis demander à l'humain de cliquer **Connect** dans le plugin Studio.
2. Ne jamais diagnostiquer depuis une copie Play : Play est une copie figée au spawn. Les vérifications de code se font en Edit ; les vérifications visuelles uniquement après confirmation que la copie Play contient la dernière source.
3. Un seul processus `rojo serve` à la fois (`Get-Process rojo` doit montrer ≤ 2 PID parent/enfant).
4. Le message `[profilestore]: Roblox API services unavailable` est **attendu** en Studio non publié (mock) — ne pas le traiter comme une erreur.
5. Sessions courtes : éviter les dumps complets de logs/captures dans les tours ; les longues boucles de diagnostic saturent le contexte et coupent la session.
