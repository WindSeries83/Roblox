> STATUS: ARCHIVED
> SUPERSEDED BY: docs/product/ROADMAP.md and docs/production/VERTICAL_SLICE.md
> Historical document. Do not implement tasks directly without checking current code and execution-status.

# RIFT BEASTS — Plan « FTUE & Monde vivant » (Lots A+B)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rendre les 5 premières minutes jouables — le monde est la scène, les menus arrivent en dernier — puis rendre le pouvoir visible.

**Architecture:** Logique pure dans `src/shared/*` (testée hors Play), services serveur dans `Bootstrap.ORDER`, remotes dans `Net.luau`, effets client-only dans `src/client/*`. `CreatureDisplay` reste le propriétaire du pivot des modèles ; FollowController/FarmBehaviors s'enregistrent comme « motion owners » pour éviter les conflits de pivot.

**Tech Stack:** Luau vanilla maison, ProfileStore, Rojo/StyLua/selene/wally (rokit), tests via `require(game.ServerStorage.UnitTest.RunUnitTest)()` en Play (MCP, datamodel Server).

**Spec:** `docs/superpowers/specs/2026-08-21-ftue-monde-vivant-design.md`

## Global Constraints

- Toute économie/drop côté serveur ; client = affichage uniquement (SE-2)
- Tout gain cliquable : validation + rate limit serveur (SE-5), plafonné
- Toute transaction passe `Log:Economy`
- Chaque tâche : stylua + selene + suite verte avant commit
- Chaque tâche rendant du visuel : capture MCP + revue agent eyes avant commit
- Pas de publication ce cycle (IDs gamepasses à 0, DataStore mock Studio)
- Écart spec acté : orbe = **5 s de rendement** (`ORB_REWARD_SECONDS`, le « ~2 % d'un tick » de la spec était imperceptible ; 5 s reste négligeable vs faille ×8)

---

## Lot A — FTUE & Monde vivant

### Task 1: FollowController (les créatures suivent le joueur)

**Files:** Create `src/client/FollowController.luau` · Modify `src/client/CreatureDisplay.luau`

**Interfaces:** `CreatureDisplay.Models(): { [string]: Model }`, `CreatureDisplay.Creatures(): {any}`, `CreatureDisplay.Motion: { [string]: string }` (registre partagé ; le heartbeat de CreatureDisplay saute les ids présents). `FollowController.Start()` — top 3 créatures par Power suivent le HumanoidRootPart (offsets triangle 3/4 studs, lerp 0,15), désactivé quand `RiftSync.InRift`.

- [ ] CreatureDisplay : exposer `Models()`, `Creatures()`, `Motion` ; heartbeat skip ids dans `Motion`
- [ ] FollowController : sélection top 3 par Power, offsets triangle fixes par rang, lerp position + orientation vers la direction de déplacement, bob existant conservé
- [ ] Désactivation en faille (`Net.RiftSync` InRift true → retour grille)
- [ ] stylua/selene/tests → capture MCP (créature près du joueur après déplacement) → revue eyes → commit `feat: créatures d'équipe qui suivent le joueur`

### Task 2: FarmBehaviors (farm AFK visible par rôle)

**Files:** Modify `src/shared/Data/Species.luau` (champ `Role`) · Create `src/client/FarmBehaviors.luau`

**Interfaces:** `Species[id].Role ∈ {"Digger","Gatherer","Guardian"}` (défaut `"Digger"` si absent). `FarmBehaviors.Start()` — pour chaque modèle NON follower : cycle 6-10 s aléatoire — Digger : plongeon y −0,5 + particule terre + pépite dorée qui vole vers le joueur (Fx.Confetti doré) ; Gatherer : orbite ellipse autour de l'enclos (rayon 8-12) ; Guardian : va-et-vient le long de la clôture. Zéro économie.

- [ ] Species : Role sur les 10 espèces (mix réaliste : Feral=Digger, Wild=Gatherer, etc.)
- [ ] FarmBehaviors : enregistre `Motion[id]="farm"`, anime via PivotTo relatif à `CreatureDisplay` base, particules + nugget
- [ ] stylua/selene/tests → capture MCP (2 comportements distincts visibles) → revue eyes → commit `feat: comportements de farm visibles (rôles)`

### Task 3: Animations d'attaque en faille

**Files:** Create `src/client/RiftFx.luau` · Modify `src/client/Ui.luau` (hooks RiftSync/RiftEnded existants lignes 599-697)

**Interfaces:** `RiftFx.OnAttack(guardianPart)` — lunge de la plus proche créature follower vers le gardien (tween aller 0,15 s / retour 0,15 s) + `Fx.Burst` rouge sur gardien + flash label PV ; `RiftFx.OnGuardianHit()` — shake caméra léger (0,2 s, amplitude 0,4) ; `RiftFx.OnWin(position)` — Confetti + burst cristal.

- [ ] Hook : envoi `RiftAttack` côté client → jouer OnAttack (le client connaît sa propre action) ; réception RiftSync avec PlayerHP < précédent → OnGuardianHit ; GuardianHP chute → flash barre
- [ ] RiftEnded Win=true → OnWin à la position du cristal (`Workspace.Crystal_{player}`)
- [ ] stylua/selene/tests → playtest MCP faille complète avec captures attaque/gardien/victoire → revue eyes → commit `feat: animations de combat en faille`

### Task 4: Nid de spawn + éclosion spectaculaire en monde

**Files:** Create `src/server/Services/NestService.luau` · Modify `Bootstrap.ORDER` (+NestService après HatchService), `src/server/Services/HatchService.luau` (extraire `HatchEggById(player, eggId): boolean` réutilisable), `src/server/Services/PlayerDataService.luau` (starter egg `Source="Nest"`), `src/client/HatchCinematic.luau` (new), `src/client/Ui.luau` ou HatchResult hook (déclencher cinématique si payload.WorldHatch)

**Interfaces:** NestService construit nid (socle pierre + œuf décor + ProximityPrompt « Éclore ») près du SpawnLocation (~8 studs). Prompt.Triggered → trouve l'œuf Source="Nest" du joueur → `hatchService:HatchEggById` → payload `HatchResult` + champ `WorldHatch=true`. Client : `HatchCinematic.Play(creatureInfo)` — camera punch FOV, flash lumière, tremblement œuf (tween scale x3), Burst + Confetti couleur rareté, son éclosion (Audio.luau), FloatText nom + rareté.

- [ ] Test d'abord : extraction `HatchEggById` — hatch d'un eggId inexistant → false sans erreur ; cooldown/cap inchangés (étendre Gameplay_Test ou nouveau Nest_Test pur sur la logique de recherche d'œuf Nest)
- [ ] NestService : construction monde + prompt + branchement HatchEggById
- [ ] HatchCinematic client + branchement sur `WorldHatch`
- [ ] Playtest MCP : join neuf → prompt visible → éclosion en monde → cinématique → capture → revue eyes → commit `feat: nid de spawn, première éclosion dans le monde`

### Task 5: Première faille accélérée

**Files:** Modify `src/shared/Config.luau` (`FIRST_RIFT_DELAY = 90`), `src/server/Services/RiftService.luau` (première itération de la boucle utilise FIRST_RIFT_DELAY)

**Interfaces:** aucune nouvelle — premier cycle serveur : `task.wait(FIRST_RIFT_DELAY)` au lieu de `RIFT_INTERVAL`, ensuite intervalles normaux.

- [ ] Config + boucle RiftService (première ouverture seulement)
- [ ] Vérif playtest : attribut test `RiftInterval` toujours prioritaire ; log `[ECON] Rift Opened` < 90 s après start serveur neuf
- [ ] stylua/selene/tests → commit `feat: première faille accélérée (90 s)`

### Task 6: Orbes d'Essence ambiantes

**Files:** Create `src/shared/Orbs.luau`, `src/server/Services/OrbService.luau`, test `src/tests/unit/Cases/Orbs_Test.luau` · Modify `Bootstrap.ORDER` (+OrbService), `src/shared/Net.luau` (`OrbClaimed` broadcast)

**Interfaces (pures):** `Orbs.NextSpawnAt(lastAt, now, interval): number` ; `Orbs.Reward(rate): number` = `math.max(1, math.floor(rate * Config.ORB_REWARD_SECONDS))` ; `Orbs.CanClaim(playerClaims, now, maxPerHour): boolean, reason`.

- [ ] Test d'abord : NextSpawnAt futur/passé ; Reward min 1 ; CanClaim refus au-delà du plafond horaire
- [ ] Config : `ORB_INTERVAL = 45`, `ORB_MAX_CONCURRENT = 3`, `ORB_REWARD_SECONDS = 5`, `ORB_MAX_PER_HOUR = 20`
- [ ] OrbService : spawn pépite Neon dorée dans l'enclos (positions pseudo-aléatoires seedées), ClickDetector → validation serveur (distance < 30, plafond) → `essenceService:Add(source "Orb")` → `Net.OrbClaimed:FireAllClients({Position, Amount})` → destroy
- [ ] Client (dans OrbService? non — petit bloc dans `Fx` ou module `OrbView`) : FloatText +N au claim
- [ ] Relancer EconomySim 7 j ×3 — rebirth 1 ≈ 15 min intact (orbes ≈ +5 s/min max, négligeable)
- [ ] stylua/selene/tests → capture orbe + claim → revue eyes → commit `feat: orbes d'essence ambiantes (serveur-validées)`

### Task 7: Tutoriel 3 prompts monde + menus en dernier

**Files:** Modify `src/client/Tutorial.luau` (STEPS), `src/shared/TutorialBridge.luau` (clé `RiftEntered`), `src/client/Ui.luau` (auto-open unique post-première victoire de faille si `!TutorialDone`)

**Interfaces:** STEPS v2 : 1. « Approche-toi de l'œuf et touche-le. » Need=`Hatch` (existant) · 2. « Ta créature te suit et farm pour toi. Ouvre le Menu pour en faire plus. » Need=`MenuOpen` · 3. « La Faille s'est ouverte ! Entre dans l'arche violette. » Need=`RiftEntered` (set depuis ShowRiftSync InRift=true) · bouton Réclamer final inchangé. Auto-open : sur `RiftEnded.Win && !TutorialDone && !autoOpenedOnce` → SetMenuOpen(true) + onglet Œufs.

- [ ] TutorialBridge : `Set("RiftEntered", true)` consommé par Tutorial.Check
- [ ] STEPS remplacés, avance sur HatchResult/RiftSync/MenuOpen
- [ ] Auto-open post-victoire (une seule fois par session)
- [ ] Playtest MCP : parcours complet 0→faille→menu auto → captures → revue eyes → commit `feat: tutoriel 3 prompts monde + menu révélé après la faille`

### Task 8: Couveuse teasing verrouillé + bannière teasing

**Files:** Modify `src/shared/Sanctuary.luau` (`EggGate(level): {UncommonEgg=2, RareEgg=3}`), `src/server/Services/HatchService.luau` (BuyEgg valide le gate), `src/client/Panels/EggPanel.luau` + `CouveusePanel.luau` (rangée verrouillée), `src/shared/Objective.luau` + `src/client/ObjectiveBanner.luau` (état teasing)

**Interfaces:** `Sanctuary.EggGate(sanctuaryLevel)` → table `{UncommonEgg=2, RareEgg=3}` ; achat refus serveur si niveau insuffisant (log Economy "EggLocked"). UI : œufs verrouillés affichés grisés + cadenas + « Rang de sanctuaire N requis ». Objective : si rien d'urgent → `{Kind="Teasing", Label="Œuf rare verrouillé — Rang 3", Target="Couveuse"}`.

- [ ] Test d'abord : EggGate niveaux 1/2/3+ ; BuyEgg refusé proprement (étendre Purchase_Test ou Sanctuary_Test)
- [ ] EconomySim re-run (gate retarde RareEgg ~2-3 min early game — vérifier rebirth 1 ≈ 15 min)
- [ ] Panels + banner teasing
- [ ] stylua/selene/tests → capture couveuse verrouillée → revue eyes → commit `feat: œufs verrouillés par rang de sanctuaire (teasing) + bannière teasing`

### Task 9: Playtest séquence 0→5 min bout en bout

- [ ] Serveur neuf → join → T+10 s éclosion nid → T+20 s farm visible → T+90 s faille → victoire → menu auto → orbe claimée → captures à chaque beat → revue eyes globale
- [ ] Suite verte complète (~140+ tests attendus avec Lots C/D existants ? non — baseline actuelle + nouveaux) ; journaliser les écarts

## Lot B — Pouvoir visible

### Task 10: Taille par niveau + puissance topbar

**Files:** Modify `src/shared/Gameplay.luau` (`TeamPowerOf(state): number`), `src/client/CreatureDisplay.luau` (scale × `(1 + Level*0.008)` cap 1,1), `src/client/Ui.luau` (topbar : puissance à côté de l'Essence), test étendu `Gameplay_Test.luau`

**Interfaces:** `Gameplay.TeamPowerOf(state)` = somme `creature.Power` (réutilisé client ; RiftService garde sa version serveur profil-based).

- [ ] Test d'abord : TeamPowerOf vide=0, somme simple
- [ ] Scale niveau + label topbar « ⚡ N »
- [ ] stylua/selene/tests → capture → revue eyes → commit `feat: pouvoir visible (taille par niveau, puissance topbar)`

### Task 11: Socles d'emplacements sanctuaire

**Files:** Modify `src/client/CreatureDisplay.luau` (rendre `MaxCreatures(level)` socles)

**Interfaces:** pour i > #creatures jusqu'à MaxCreatures : disque pierre discret (Cylinder 2,6×0,1) à GridPosition(i), transparence 0,6 — l'enclos paraît prêt à grandir.

- [ ] Socles générés/détruits selon SanctuaryLevel (source state.Sync)
- [ ] Capture avant/après upgrade → revue eyes → commit `feat: emplacements de sanctuaire matérialisés`

### Task 12: Renaissance cinématique

**Files:** Modify `src/server/Services/RebirthService.luau` (payload RebirthResult existe ? vérifier — sinon ajouter), `src/client/Cinematic.luau` (fonction `RebirthFlash()`)

**Interfaces:** `Cinematic.RebirthFlash()` — ColorCorrection blanc 0,4 s + Confetti doré plein écran + son rebirth (Audio.luau) ; déclenché sur confirmation renaissance réussie.

- [ ] Brancher confirmation → flash ; capture pendant playtest rebirth → revue eyes → commit `feat: renaissance cinématique (flash + son)`
