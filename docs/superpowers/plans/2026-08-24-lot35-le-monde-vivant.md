# Lot 3.5 « Le monde vivant » — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Corriger les 13 irritants de playtest : menu refermable, éclosion 100 % dans le monde (placement à la couveuse), compagnon choisi qui suit + créatures autonomes animées, Index Pokédex modulaire, Sanctuaire/Objectifs/Arbre lisibles et visuels, HUD possessions, eau terrain autour de l'île.

**Architecture:** Aucune refonte — le socle existe déjà (`HatchEggById(worldHatch)`, `CreaturePortrait`, `FollowController`, `FarmBehaviors`, `SkillService→SkillTree.CanBuy`). On généralise le chemin monde de l'éclosion via un nouveau service serveur `IncubationService` (œufs placés = parts répliquées + prompts), on centralise le lookup des templates (fix doublon), on passe les panels texte en cards/portraits, et on donne une structure graphe (`Requires`, `Row/Col`) au SKILL_TREE.

**Tech Stack:** Luau, Rojo (serve uniquement — jamais `rojo build`), ProfileStore, suite unitaire maison (`ServerStorage.UnitTest.RunUnitTest`), MCP Studio pour playtests.

**Spec:** `docs/RIFT_BEASTS_1_bible_design.md` §3.6, §3.7/§3.13, §4.A, §4.B, §10, §11.

## Global Constraints

- **JAMAIS de `rojo build -o`** : le monde (île ProceduralModels, Couveuse, templates) vit dans `Roblox.rbxlx` hors arborescence rojo → un build l'écraserait. Uniquement `rojo serve` + Connect.
- Avant tout playtest : vérifier marqueur sync rojo en Edit ; tests unitaires pendant le Play (VM fraîche), jamais en Edit.
- Suite verte (~210 tests) avant chaque commit. Style : tabs, commentaires français non triviaux, stylua + selene.
- Éco : toute transaction loggée `[ECON]` ; validation serveur systématique (jamais confiance client).
- Décisions actées : œufs achetés/gagnés → inventaire → **placement à la couveuse obligatoire** pour éclore ; AutoHatch (gamepass) auto-place+éclore ; **1 compagnon choisi par le joueur** suit, les autres vivent leur rôle ; eau = Terrain natif.
- Le message `[profilestore]: Roblox API services unavailable` est attendu en Studio non publié.

## Diagnostic (constaté en lecture, pré-exécution)

| # | Irritant | Cause racine |
|---|---|---|
| 1 | Menu inferrmable | `SetMenuOpen(false)` (Ui.luau:339) jamais appelée par l'UI |
| 2 | Créature en double | Templates d'espèces visibles dans `Workspace.Creatures` + clones display |
| 3 | Nom illisible post-éclosion | `Fx.FloatText` = billboard 120×30 px, disparu en 1 s (HatchCinematic:68) |
| 4 | Pas de suivi/animations | FollowController ne suit que la plus forte (non choisie) ; anims `CreatureMotion` dépendent de noms de parts absents des modèles IA → diagnostic runtime requis |
| 5 | Sanctuaire illisible | Rows texte brut `[RARITY] Nom — Stade — Niv — Pwr` (SanctuaryPanel:30) |
| 6 | Index non pokédex | N'affiche que `state.Index` découvert (IndexPanel:56) |
| 7 | Décimales renaissance | `×{preview.NextMult}` brut (RebirthPanel:82) |
| 8 | Possessions illisibles en jeu | TopBar = Essence + Rendement uniquement |
| 9 | Arbre = liste | `SKILL_TREE` sans prerequis ni positions ; panel en rows (SkillPanel:45) |
| 10 | Objectifs illisible | Cartes denses, tailles 12-15 px |
| 11 | UI/UX globale | UiKit minimaliste (pas de tokens/cards/badges cohérents) |
| 12 | Eau | Absente (aucune réf Water/Terrain dans src) |

---

### Task 1 : Mise à jour des docs (verrouiller avant de coder)

**Files:** Modify `docs/RIFT_BEASTS_1_bible_design.md` (le plan lui-même est déjà sauvegardé par le contrôleur)

- [ ] Bible §4.A « Hubs » : la Couveuse devient LE hub d'éclosion — inventaire d'œufs → placement physique → prompt Éclore in-world ; carte de révélation lisible (portrait + nom, ≥ 4 s).
- [ ] Bible §4.B : fermeture du menu (✕, toggle barre d'action, touche B/manette) ; HUD permanent des possessions (créatures n/max, étoiles, points d'arbre, quêtes prêtes).
- [ ] Bible §3.6 : Index = Pokédex — toutes espèces listées depuis `Species` (modulaire), 3 états : Possédée / Découverte / Inconnue (silhouette « ??? »), filtres familles.
- [ ] Bible §3.7+§3.13 : Arbre d'Étoiles = graphe visuel avec prerequis (`Requires`) ; gains approfondis plus tard.
- [ ] Bible §10 En suspens : ajouter « profondeur boucle de gameplay (post-lancement lot 3.5) », « valeurs gains arbre (sim) ».
- [ ] Bible §11 : insérer ligne Lot **3.5 · Le monde vivant** (correctifs playtest) entre Lot 3 et Lot 4.
- [ ] Commit `docs: lot 3.5 le monde vivant - retour playtest`.

### Task 2 : Fermeture du menu

**Files:** Modify `src/client/Ui.luau`

- [ ] Bouton ✕ coin haut-droit du frame `content` (32×32, TINTS.RED) → `SetMenuOpen(false)` (ZIndex au-dessus du contenu).
- [ ] Boutons ActionBar Œufs/Sanctuaire/Plus deviennent toggles : `SetMenuOpen(not menuOpen)` puis sélection onglet si ouverture.
- [ ] `UserInputService.InputBegan` : `Enum.KeyCode.ButtonB` et `Escape` → fermer si ouvert.
- [ ] Playtest MCP : ouvrir via barre, fermer via ✕ / re-clic / B. Commit `fix: menu refermable (x, toggle, manette)`.

### Task 3 : Doublon de créatures (templates cachés)

**Files:** Create `src/shared/CreatureTemplates.luau` (helper client) ; Modify serveur boot ; Modify `src/client/CreatureDisplay.luau`, `src/client/CreaturePortrait.luau`

- [ ] Serveur au boot : si `Workspace.Creatures` existe → déplacer vers `ReplicatedStorage.CreatureTemplates`.
- [ ] Helper partagé : `CreatureTemplates.Get(speciesId)` → cherche `ReplicatedStorage.CreatureTemplates.{id}` puis fallback `Workspace.Creatures`. Remplacer les 2 lookups directs (`CreatureDisplay.Refresh`, `CreaturePortrait.Show`).
- [ ] Vérifier en Edit que rien d'autre ne référence `Workspace.Creatures` (grep). Playtest : île propre, créature unique. Suite verte. Commit `fix: templates d'especes retires du decor (doublon sanctuaire)`.

### Task 4 : Éclosion dans le monde — placement à la couveuse

**Files:** Create `src/server/Services/IncubationService.luau`, `src/shared/Incubation.luau` (logique pure testée) ; Modify `src/shared/Net.luau` (+`PlaceEgg`) ; Modify `src/server/Bootstrap.luau` (registre) ; Modify `src/client/Panels/EggPanel.luau`, `src/client/CouveusePanel.luau` ; Modify `src/server/Services/HatchService.luau`

- [ ] Net : `Net.PlaceEgg = Event("PlaceEgg")`.
- [ ] Logique pure partagée `Incubation.SlotCFrame(origin, index)` (slots circulaires rayon 4 autour de la couveuse, angle régulier par index) + `Incubation.MAX_PLACED = 3`.
- [ ] IncubationService : au `PlaceEgg(player, eggId)` — vérif ownership (egg présent dans profile, pas déjà placé), cap placements simultanés ; spawn modèle œuf (Ball teinté par tier + PointLight + ProximityPrompt « Éclore » HoldDuration 0.5) ; `[ECON] Egg Placed`. Prompt triggered → `hatchService:HatchEggById(player, eggId, true)` → destruction part + libération slot.
- [ ] Cleanup : `PlayerRemoving` détruit les parts du joueur ; relog = tout non-placé (état session uniquement).
- [ ] AutoHatch : si `Entitlements.AutoHatch`, achat → place+hatch immédiat (chemin existant `worldHatch=true`).
- [ ] HatchService : handler `BuyEgg` délègue à IncubationService quand entitlement.
- [ ] EggPanel/CouveusePanel : bouton « Éclore » → « Placer » (`Net.PlaceEgg:FireServer(egg.Id)`) ; hint « Va à la couveuse pour éclore tes œufs ».
- [ ] Tests : unitaires sur `shared/Incubation.luau` (slot CFrame, cap). Playtest : achat → inventaire → placement → prompt → cinématique monde → œuf retiré. Commit `feat: eclosion dans le monde - placement des oeufs a la couveuse`.

### Task 5 : Carte de révélation d'éclosion lisible

**Files:** Modify `src/client/HatchCinematic.luau`

- [ ] Remplacer `Fx.FloatText` (ligne ~68) par BillboardGui persistant adossé au nid (260×120, AlwaysOnTop, MaxDistance 80) : portrait viewport (`CreaturePortrait.Create`), nom espèce (18px), rareté colorée + mutation (14px). Tween scale-in, hold 4 s, fade-out, destroy.
- [ ] Fallback ancre joueur conservé. Playtest : œuf commun ET rare. Commit `feat: carte de revelation d'eclosion lisible dans le monde`.

### Task 6 : Compagnon choisi + vie autonome + animations

**Files:** Modify `src/client/FollowController.luau`, `src/client/FarmBehaviors.luau`, `src/client/CreatureMotion.client.luau`, `src/client/CreatureHud.luau`, `src/shared/Net.luau` (+`SetCompanion`), `src/server/Services/DataSync.luau`, `src/server/Services/SanctuaryService.luau` (stocke `profile.Data.CompanionId`)

- [ ] **Diagnostic runtime d'abord** (playtest MCP) : inspecter `CreatureDisplay.Motion`, position modèle vs root après marche — consigner la cause dans le commit.
- [ ] CreatureHud : bouton toggle « Faire suivre / Rappeler » → `Net.SetCompanion:FireServer(creature.Id | nil)` ; serveur valide ownership → `profile.Data.CompanionId` (un seul ; en poser un autre remplace) ; DataSync expose `CompanionId`.
- [ ] FollowController : cible = `state.CompanionId` (plus « strongest ») ; lerp 0.18 ; oriente le modèle vers la direction du déplacement.
- [ ] FarmBehaviors : rôles inchangés, amplitudes élargies (Gatherer 2.6, Guardian ±3.2).
- [ ] Animations : fallback garanti quand aucun part wing/tail/fin/head — bob + roll existants ; squash-stretch léger (ScaleTo pulse ±4 %) pendant déplacement compagnon et creusage. Si le diagnostic révèle des noms exploitables, étendre `KindOf`.
- [ ] Test unitaire pur : règle « un seul compagnon, ownership requis » si logique extraite partagée. Playtest : choisir compagnon → suit partout ; rappel → réintègre la grille. Commit `feat: compagnon choisi + creatures autonomes animees`.

### Task 7 : Sanctuaire en cards visuelles

**Files:** Modify `src/client/Panels/SanctuaryPanel.luau` ; Modify `src/client/UiKit.luau` (+`UiKit.Card`)

- [ ] `UiKit.Card(parent, size)` : frame PANEL + corner 10 + padding + UIStroke subtile.
- [ ] Liste → `UIGridLayout` cards 150×170 : portrait viewport, bande rareté colorée (nom court), nom espèce (14px bold), `Niv X · Stade`, mini-barre XP 8px, puissance ⚔.
- [ ] Tri : rang rareté desc puis puissance desc. Sélection → `RenderDetail` conservé (restyle titres).
- [ ] Playtest compact + desktop. Commit `feat: sanctuaire en cards avec portraits`.

### Task 8 : Index Pokédex modulaire

**Files:** Modify `src/shared/Index.luau` (+`Catalog`, `EntryState`) ; Modify `src/client/Panels/IndexPanel.luau`

- [ ] `Index.Catalog()` : itère `Species` → liste triée (famille puis rareté desc) — futur-proof.
- [ ] `Index.EntryState(entries, speciesId)` → `"owned" | "discovered" | "unknown"` (owned = créature dans `state.Creatures` ; discovered = clé dans Index ; sinon unknown).
- [ ] Panel : header `X / total découvertes — Bonus +Y %` ; SubTabs familles générés depuis Catalog ; grille cards : owned = portrait couleur + count ; discovered = portrait couleur + badge « Découverte » ; unknown = silhouette noire + « ??? ».
- [ ] Famille complétée : ✓ doré sur l'onglet.
- [ ] Tests : `Index_Test.luau` étendu (états, catalog complet = Species). Commit `feat: index pokédex - toutes especes, etats possede/discovery/inconnu`.

### Task 9 : HUD possessions permanent

**Files:** Modify `src/client/Ui.luau` (TopBar)

- [ ] TopBar 2 lignes → 3 zones compactes : Essence (existant), Rendement/s (existant), possessions : `🐾 n/max · ★n · 🌟points` (badge vert cliquable points > 0 → onglet Arbre).
- [ ] Badge quêtes prêt (existant) reste. Compact via ApplyLayout. Commit `feat: hud permanent des possessions`.

### Task 10 : Renaissance — aperçu sans décimales

**Files:** Modify `src/client/Panels/RebirthPanel.luau`

- [ ] `×{math.floor(preview.NextMult + 0.5)}` (arrondi entier). Idem autres floats fuyants du panel. Commit `fix: multiplicateur de renaissance arrondi a l'unite`.

### Task 11 : Objectifs lisible

**Files:** Modify `src/client/Panels/QuestsPanel.luau`

- [ ] Cards ≥ 64px : titre 17px, desc 14px, barre progrès 16px pleine largeur avec `x/y` superposé, récompense badge accent.
- [ ] Succès : grille 2 colonnes, ✓ verte / 🔒 grise.
- [ ] Guide : steps numérotés puces accent. Commit `feat: objectifs lisible - cartes et grille de succes`.

### Task 12 : Arbre d'Étoiles en vrai arbre

**Files:** Modify `src/shared/Config.luau` (SKILL_TREE +`Requires`,+`Row`,`Col`) ; Modify `src/shared/SkillTree.luau` (CanBuy prerequis) ; Modify `src/client/Panels/SkillPanel.luau`

- [ ] Config : chaque nœud gagne `Requires = {...}` (vide = racine) et `Row/Col` — tronc commun bas, Ferme à gauche, Faille à droite, paliers descendants ; prerequis satisfait dès rank ≥ 1.
- [ ] `SkillTree.CanBuy` : refus si prerequis rank 0 → raison « nécessite {nom} ». Serveur validé gratis (SkillService passe par CanBuy).
- [ ] SkillPanel : ScrollingFrame canvas ; Row/Col → x,y fixes ; nœuds boutons circulaires 56px reliés par traits (Frames fins rotatés atan2) ; états verrouillé (gris 🔒) / disponible (accent pulse) / possédé (pips ●○, doré si max).
- [ ] Clic nœud → tooltip desc + effet + acheter (Net.SkillBuy inchangé).
- [ ] Tests : `SkillTree_Test.luau` étendu — refus sans prerequis, ok avec, raison correcte. Playtest desktop+mobile. Commit `feat: arbre d'etoiles en graphe avec prerequis`.

### Task 13 : Eau terrain autour de l'île

**Files:** Studio Edit via MCP (Terrain + Lighting) — persisté dans `Roblox.rbxlx` (PAS de rojo build)

- [ ] Mesurer l'emprise de l'île (inspecter ProceduralModels). `Terrain:FillBlock` Water en couronne, fond sable.
- [ ] Lighting : `WaterWaveSize 0.15, WaterWaveSpeed 8, WaterReflectance 0.25, WaterTransparency 0.6`.
- [ ] Vérifier spawn/nid/couveuse hors de l'eau ; capture écran avant/après. Commit du rbxlx `feat: eau terrain autour de l'ile du sanctuaire`.

### Task 14 : Pass UX transversal + audit final

**Files:** Modify `src/client/UiKit.luau` (tokens SPACING/RADIUS/TEXT, SECONDARY, `Badge()`, `SectionTitle()`) ; panels restés en style ancien (Marché/Boutique/Duels/Amis/Saison/Élevage)

- [ ] Tokens appliqués uniformément (rattrapage après Tasks 7-11).
- [ ] Audit Device Simulator (skill rbx-device-simulator-lua) : téléphone/tablette/desktop — safe areas, cibles ≥ 44px, contraste, overflow.
- [ ] Playtest bout en bout (spawn → éclosion monde → compagnon → sanctuaire → index → arbre → renaissance). Commit `feat: pass ux tokens + audit multi-device`.

## Ordre d'exécution

1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 11 → 12 → 13 → 14.

## Risques suivis

| Risque | Mitigation |
|---|---|
| Suivi invisible même après fix (Task 6) | Diagnostic runtime MCP AVANT code ; cause consignée |
| `rojo build` écraserait le monde | Interdit — sync serve uniquement ; Task 13 passe par Studio |
| Templates déplacés cassent portraits | Helper unique + fallback Workspace |
| Canvas arbre illisible mobile | Coordonnées relatives + scroll ; audit device Task 14 |
