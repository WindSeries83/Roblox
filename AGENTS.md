# Vision

Dès qu'une image, capture d'écran ou screenshot doit être examinée, décrite ou vérifiée visuellement, délègue systématiquement à l'agent `eyes` (outil `task`, avec le chemin exact du fichier) avant de répondre. Ne la décris jamais toi-même en premier. Base-toi uniquement sur ce que `eyes` rapporte ; s'il dit « je ne vois pas », rapporte-le tel quel.

# Roblox

Toute tâche liée à Roblox, Luau, Studio, au MCP `roblox` (outils `roblox_*`) ou au développement de ce jeu : charge **toujours** le skill `roblox-game` (outil `skill`, nom `roblox-game`) et suis-le. Tout le code et l'orchestration des outils `roblox_*` passent par ses références (`references/`, `workflows/`, `templates/`), en particulier `references/mcp-orchestration.md` pour la correspondance des outils.
