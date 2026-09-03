# Playtest Report — Pré-lancement final

## Session Info
- **Date**: 2026-08-29
- **Build**: `c8866e5`
- **Tester**: Codex via Roblox Studio MCP
- **Plateforme**: Studio Play, viewport Xbox One pour la passe console
- **Input**: clavier, souris, manette simulée
- **Type**: validation ciblée pré-lancement

## Test Focus
FTUE œuf → couveuse → hatch → Parcours, combat automatique et postures, sanctuaires, régions, navigation manette, tests Studio et analyse de scène.

## Résultats

| Zone | Résultat | Preuve / limite |
|---|---|---|
| Achat/obtention d’œuf | PASS | Achat d’un œuf commun, essence passée de 200 à 150, œufs visibles dans l’inventaire |
| Incubation tutorielle | PASS | Sélection puis lancement ; état `En cours`, puis `Prêt` après 6 s ; durée configurée à 5 s pour le premier œuf |
| Hatch | PASS | Récupération, révélation et disparition de la cinématique |
| Déblocage Parcours | PASS | Bouton `PARCOURS !` visible et objectif mis à jour après le hatch |
| Première victoire | PASS | Combat automatique terminé, cristal récupéré, récompense `+1260 Essence` et œuf accordé |
| Six victoires, boss, renaissance | NON VALIDÉ ENTIÈREMENT | La fenêtre de Parcours s’est fermée pendant la session ; la simulation pure couvre les checkpoints/boss et la renaissance mais pas le parcours live complet |
| Postures / RiftAttack | PASS logique | Cadence 0,75 s respectée ; second tick à +0,1 s inflige 0 ; Power raccourcit seulement via son bonus, Guard réduit les dégâts reçus |
| Sanctuaires | PASS logique / PARTIEL live | Affectation, cap, collecte bornée et anti-double-collecte passent ; invitation/reconnexion/multi-joueur non disponibles dans cette session mono-client |
| Navigation manette | PARTIEL | Entrées `ButtonA`/D-pad acceptées sans erreur ; aucun `SelectedObject` n’était initialisé automatiquement, donc focus console non démontré de bout en bout |
| Quatre régions | PASS runtime | `Workspace.Worlds` contient TwilightGrove, AshForge, GalePeaks, NyxAbyss ; chacune possède Ground, Stage1–5, BossArena et BossAlpha |

## Bugs / points d’attention

| # | Description | Sévérité | Reproductible |
|---|---|---|---|
| 1 | Le focus manette démarre à `nil` dans Studio ; navigation D-pad acceptée, mais sélection initiale automatique non prouvée. | Medium | Oui dans cette session |
| 2 | La validation des six victoires live dépend de la fenêtre d’entrée du Parcours (90 s initiales puis cycles de 5 min). | Medium | Oui, contrainte de test |
| 3 | `SceneAnalysisService` rapporte 14,97 MB audio côté client, dominés par `SoundService.Rift` (5,76 MB), `ReplicatedStorage.Sounds` (6,24 MB) et les sons de personnage. | Low | Oui |

## Quantitative Data
- Tests Studio : **267 exécutés, 267 réussis, 0 échec**.
- StyLua : `stylua --check src` — **PASS**.
- Selene : **0 erreur, 0 warning, 0 parse error**.
- SceneAnalysis : serveur **0 objet non parenté** ; client **80 unités**, principalement `UIScale`, `PlayerModule`, `TutorialBridge` et objets internes attendus.
- Animation memory : **139 803 octets** côté client/serveur, dont 138 901 octets pour l’animation Roblox standard.
- Rojo build et Lune headless : bloqués par la stratégie de contrôle d’application Windows (`os error 4551`), pas par une erreur de projet observée.
- Studio : `[profilestore]: Roblox API services unavailable` et MemoryStore indisponible sont attendus pour une place non publiée avec mock.

## Revue Roblox / sécurité
- Autorité serveur conservée pour achats, hatch, combat, renaissance, affectations et marché.
- Remotes critiques observés avec validation de type, propriété, cap, cooldown ou état serveur selon le flux.
- Marché doté de transitions atomiques et ledger idempotent ; aucun signal de double-crédit dans les tests.
- Les invitations sont explicitement en mémoire de session et la visite est en lecture seule.
- Aucun TODO/FIXME dans `src`.

## Addendum - validation apres resynchronisation Rojo

- La source Edit contient le correctif de focus avant le Play.
- Ouverture de `Bar_Oeufs` : `GuiService.SelectedObject` pointe sur `Content.TabBar.Tab2`.
- Fermeture par `CloseMenu` : le focus revient sur `ActionBar.Bar_Oeufs` et `Content.Visible` devient faux.
- Lune headless : **221/221 reussis**, 8 cas live ignores.
- StyLua, Selene et build Rojo : **PASS** ; build produit a 661 706 octets.
- ButtonB/Echap restent a confirmer manuellement : l'outil d'injection Studio refuse ces touches reservees a CoreGUI.

## Verdict
**Pré-lancement conditionnel.** Le socle logique, le FTUE initial, la première victoire, les quatre régions, la suite Studio et les analyses statiques sont verts. La validation finale reste conditionnée à une session avec fenêtre de Parcours ouverte pour jouer les 6 victoires jusqu’au boss et à une vraie session publiée pour marché, persistance réelle, coop et invitations multi-serveurs.

## Top 3 priorités
1. Refaire le parcours live complet dans une fenêtre ouverte et confirmer les 5 étapes + boss puis renaissance.
2. Initialiser explicitement `GuiService.SelectedObject` et vérifier le focus manette sur Xbox/console réelle ou simulateur.
3. Vérifier la taille audio avant publication, en priorité la musique Rift et les sons de personnage.
