# RIFT BEASTS — Plan « parfait & jouable » (P5)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Combler l'écart bible ↔ code pour rendre le jeu complet, profond et monétisable — sans publication ce cycle.

**Architecture:** Logique pure dans `src/shared/*` (testée hors Play), services serveur enregistrés dans `Bootstrap.ORDER`, migrations `SaveService.Migrate`, remotes déclarées dans `Net.luau`, UI client générée en code. Monde = réthème de l'île par renaissance (décision actée).

**Tech Stack:** Luau vanilla maison, ProfileStore, Rojo/StyLua/selene/wally (rokit), tests via `require(game.ServerStorage.UnitTest.RunUnitTest)()` en Play (MCP, datamodel Server).

**Spec:** `docs/RIFT_BEASTS_1_bible_design.md` + `docs/RIFT_BEASTS_2_plan_production.md`

## Global Constraints

- Toute économie/drop côté serveur ; client = affichage uniquement
- Toute transaction passe `Log:Economy` ; logique pure testable dans `shared/`
- Pas de publication : IDs gamepasses restent à 0, DataStore mock Studio
- Chaque tâche : stylua + selene + suite verte avant commit
- Découvertes d'audit : `Mutations.luau` a déjà les 6 multiplicateurs (2→1000) mais `Config.MUTATION_WEIGHTS` n'en roule que 3 ; espèces limitées à Common/Uncommon/Rare → les hautes raretés passent par **ascension**, pas par nouvelles espèces (l'index rareté×mutation de la bible le permet)

---

## Lot 1 — Boucle & revenus (priorité)

### Task 1: Ascension de rareté (Légendaire → Ultra Rare atteignables)

**Files:** Create `src/shared/Ascension.luau`, `src/tests/unit/Cases/Ascension_Test.luau` · Modify `Config.luau`, `Breeding.luau` (RollChild), `RiftService.luau` (récompense cristal)

**Interfaces:** `Ascension.RollFrom(baseRarity: string, luck: number?): string` — monte de +1 rang avec proba configurable, plafonnée Mythic ; `Ascension.Rank(rarity)` délègue à `Gameplay.RarityRank`.

- [ ] Test d'abord : ascension jamais au-delà de Mythic ; proba 0 → inchangé ; distribution approximative sur 10 000 rolls
- [ ] Config : `BREED_ASCEND = { [rank]=0.03 }` (+1 rang, cumulatif 0.3 % pour +2), `RIFT_ASCEND = 0.08`, `ULTRARARE_ASCEND = 1/25000` depuis Mythic
- [ ] `Breeding.RollChild` : après tirage héritage, tenter ascension ; `RiftService` : œuf récompense peut monter d'un rang
- [ ] **Secret (caché, bible §3.1)** : condition serveur non documentée — éclosion d'un RareEgg pendant une Éclipse active avec relique T3 équipée → rang Secret. Aucune mention en UI. Code silencieux + test unitaire du prédicat `Ascension.SecretTrigger(eggTier, eclipseActive, relicTier)`
- [ ] stylua/selene/tests → commit `feat: ascension de rareté (élevage+faille), secret caché`

### Task 2: Mutations 6/6 roulables

**Files:** Modify `Config.luau` (MUTATION_WEIGHTS, BREED_MUTATION_WEIGHTS)

- [ ] Poids éclosion : `{None=88, Shadow=10, Frost=1.7, Golden=0.2, Prismatic=0.07, Corrupted=0.02, Celestial=0.01}` ; élevage : même échelle ÷2
- [ ] Test : `Gameplay.MutationWeights(collier)` amplifie bien toutes les mutations non-None ; somme > 0
- [ ] Relancer `src/tools/EconomySim.luau` (7 j ×3 runs) — vérifier rebirth 1 ≈ 15 min intact ; ajuster si inflation
- [ ] commit `feat: mutations 6/6 roulables + sim éco revalidée`

### Task 3: Taux de drop affichés partout (levier n°1 bible §3.1/§7)

**Files:** Modify `Gameplay.luau`, `client/Panels/EggPanel.luau`, `CouveusePanel.luau`, `BreedingPanel.luau` · Create test `GameplayRates_Test.luau`

**Interfaces:** `Gameplay.DropRates(weights: {[string]: number}): {{Id: string, Percent: number}}` triée décroissante, arrondie 2 décimales.

- [ ] Test pur : somme des percent ≈ 100 ; tri décroissant ; format %
- [ ] EggPanel/Couveuse : sous chaque bouton d'achat, ligne « Commun 75 % · Peu commun 20 % · Rare 5 % » (+ couleurs Rarities)
- [ ] BreedingPanel : afficher `BREED_INHERIT_*` et poids de mutation réels
- [ ] Panneau Faille (rift) : taux œufs `RIFT_EGG_WEIGHTS` + reliques `RIFT_RELIC_WEIGHTS`
- [ ] commit `feat: taux de drop affichés (éclosion, couveuse, élevage, faille)`

### Task 4: Hover info partout (bible §4)

**Files:** Create `src/client/HoverCard.luau` · Modify `CreatureHud.luau`, panels lignes créatures/Index

**Interfaces:** `HoverCard.Show(container, entry: {SpeciesId, Rarity, Mutation, Level, Power, SuggestedPrice})` / `.Hide()` — un seul BillboardGui réutilisé, suit la souris (panel) ou ancre (monde).

- [ ] Carte : nom espèce, pastille rareté colorée, mutation ×mult, niveau/puissance, prix marché suggéré (fonction vente existante)
- [ ] Monde : hover sur ClickDetector des clones (via `Mouse.Target` + attribut `CreatureId`) → carte
- [ ] Panels (Sanctuaire/Index/Market) : MouseEnter/MouseLeave sur chaque row → carte
- [ ] commit `feat: hover info créatures (monde + panneaux)`

### Task 5: Starter Pack réel + chance de session

**Files:** Modify `PurchaseService.luau`, `Config.luau`, `SaveService.luau`, `Ui.luau` (affichage chance)

**Interfaces:** `PassEffect("StarterBundle")` → `{Essence=2000, Creature={Rarity="Rare", Mutation="Shadow"}}` ; `SessionLuck.For(player): number` (0–0.25).

- [ ] Grant : création créature Rare mutée Shadow via `Gameplay.CreateCreature` + cap respecté (rejet propre si plein)
- [ ] Chance session : +5 %/h connecté, cap 25 %, reset à chaque join, **jamais sauvegardée** ; injectée dans `MutationWeights(bonus)` et `Ascension.RollFrom(luck)`
- [ ] Topbar : « Chance +X % » quand > 0
- [ ] Tests : Purchase_Test étendu (créature accordée, cap plein → refus propre) ; luck plafonnée
- [ ] commit `feat: starter pack réel (créature+essence) + chance de session`

### Task 6: Ultra Rare cinématique (moment clippable, bible §4)

**Files:** Create `src/client/Cinematic.luau` · Modify flux `RareDrop` client

- [ ] Sur `RareDrop` avec rang ≥ Mythic : Blur+ColorCorrection punch 1,5 s, FOV 70→60→70, WalkSpeed 8→3→8, son épique (asset existant Audio.luau), cadre doré plein écran fade
- [ ] Annonce serveur existe déjà (`ANNOUNCE_MIN_RARITY`) — vérifier payload contient pseudo + rareté
- [ ] commit `feat: cinématique drop mythique+ (slow-mo, son, cadre)`

## Lot 2 — Méta (profondeur)

### Task 7: Arbre de compétence (bible §3.7)

**Files:** Create `src/shared/SkillTree.luau`, `server/Services/SkillTreeService.luau`, `client/Panels/SkillTreePanel.luau`, test `SkillTree_Test.luau` · Modify `Config.luau`, `SaveService.luau` (**migration v5**: `SkillPoints`, `SkillTree`), `Net.luau` (`SkillTreeSync`, `SkillTreeUnlock`), `Bootstrap.ORDER`, `RebirthService` (+1 point), `Ui.luau` (onglet)

**Interfaces (pures):** `SkillTree.Def` (3 branches × 3 paliers, coûts croissants) ; `SkillTree.CanUnlock(tree, branch, tier, points): boolean, reason` ; `SkillTree.EffectFor(tree): {RateMult, RiftDamageMult, MarketFeeMult}` consommé par EssenceService/RiftService/MarketService.

- [ ] Branches : Farm (rendement +5 %/palier, AFK, auto-récolte), Faille (dégâts +10 %, drop, reliques), Économie (frais −1 %/palier, mise duel, XP season)
- [ ] Test : débloquer sans points → refus ; ordre des paliers respecté ; effets cumulés corrects ; survit au rebirth
- [ ] Service : remote validée côté serveur (branche/tier connus, points suffisants, pas double-dépense) ; +1 point par renaissance dans RebirthService
- [ ] Panel : 3 colonnes, nœuds cliquables, coût affiché, état possédé/verrouillé
- [ ] commit `feat: arbre de compétence (3 branches, permanent, migration v5)`

### Task 8: Mondes par réthème + Mode Rush (bible §3.8)

**Files:** Create `src/shared/Worlds.luau`, `server/Services/WorldService.luau`, `client/WorldTheme.luau`, test `Worlds_Test.luau` · Modify `Net.luau` (`WorldSync`, `RushResult`), `Bootstrap.ORDER`, `RebirthService`, `ObjectiveBanner`

**Interfaces:** `Worlds.For(rebirths: number): WorldDef` ; `WorldDef = {Index, Name, Theme={ClockTime, FogColor, AtmosphereDensity}, EssenceMult, Rush={Goal, TargetSeconds, Reward}}` ; `Worlds.EvaluateRush(world, stats): boolean`.

- [ ] 4 mondes : Île du Crépuscule (×1) / Forêt de Givre (×2, ClockTime 22, brouillard bleu) / Cendres (×3, rouge sombre) / Néant (×5, violet noir)
- [ ] Application thème : Lighting/Atmosphere/Terrain teinte côté serveur au join + au rebirth (preset par monde, pas de nouvelle map)
- [ ] Mode Rush : objectif chronométré par monde (W1 « faille gagnée <90 s », W2 « 3 éclosions < 3 min », W3 « 1 ascension », W4 « rebirth < 45 min »), chrono UI, récompense = titre + bonus Index permanent (`Stats.RushClears`)
- [ ] Tests purs : For(n) retourne le bon monde, cap au dernier ; EvaluateRush cas limites
- [ ] commit `feat: mondes réthémisés + mode rush chronométré`

### Task 9: Éclipse (évènement serveur, bible §5)

**Files:** Create `server/Services/EclipseService.luau`, test `Eclipse_Test.luau` · Modify `Net.luau` (`EclipseSync`), `Bootstrap.ORDER`, `Config.luau`, `ObjectiveBanner`, thème lumière client

**Interfaces:** `EclipseService.State(): {Active: boolean, EndsAt: number, NextAt: number}` ; cycle 2 h / 10 min.

- [ ] Pendant Éclipse : poids Corrompu/Prismatique ×10 (injecté dans `MutationWeights`), ascension ×2, ciel assombri
- [ ] Déclenche aussi le trigger Secret de la Task 1 (état lu via Bootstrap)
- [ ] Bandeau `ObjectiveBanner` priorité haute pendant l'évènement
- [ ] Test pur : calcul NextAt/Active depuis os.time fictif ; fenêtre de 600 s exacte
- [ ] commit `feat: évènement Éclipse (2h/10min, mutations boostées)`

## Lot 3 — Monde vivant

### Task 10: L'équipe suit le joueur

**Files:** Create `src/client/FollowController.luau` · Modify `CreatureDisplay.luau`

- [ ] Les 3 meilleures créatures équipées suivent le joueur (offsets triangle, lerp + bob existant), client-only, désactivé en Faille combat
- [ ] commit `feat: créatures d'équipe qui suivent le joueur`

### Task 11: Farm AFK visible par rôle

**Files:** Modify `src/shared/Data/Species.luau` (champ `Role`), Create `src/client/FarmBehaviors.luau`

- [ ] Digger : creuse (tween bas + particule terre + pépite dorée) ; Gatherer : circule autour de l'enclos ; Guardian : patrouille la clôture
- [ ] Cycle 6–10 s aléatoire par créature, client-only, zéro économie
- [ ] commit `feat: comportements de farm visibles (rôles)`

### Task 12: Animations d'attaque en faille

**Files:** Modify `src/client/Fx.luau`, vue faille existante

- [ ] À chaque `RiftAttack` réussi : lunge créature (tween aller/retour 0,3 s) + burst d'impact sur le gardien + flash rouge PV gardien ; riposte gardien = tremblement caméra léger
- [ ] commit `feat: animations de combat en faille`

## Lot 4 — Tech & pré-lancement

### Task 13: Réparation Rojo

- [ ] `rokit install`, `rojo serve`, Connect plugin, vérifier sync sans diff (fichier témoin), noter la procédure dans README ; sinon fallback MCP push documenté
- [ ] commit `chore: rojo réinstallé + procédure documentée`

### Task 14: Analytics instrumentées

**Files:** Modify `Log.luau` (`Log:Analytics(event, params)` wrapper AnalyticsService, pcall silencieux en Studio), appels dans HatchService/PurchaseService/RebirthService/RiftService

- [ ] Événements : `session_start`, `first_hatch`, `purchase`, `rebirth`, `rift_win` — inactifs en Studio (guard IsStudio)
- [ ] commit `feat: analytics instrumentation (prête pour publication)`

### Task 15: Re-layout UI au resize

**Files:** Modify `src/client/Ui.luau`

- [ ] Extraire la fonction de positionnement existante ; `Camera.ViewportSize:GetPropertyChangedSignal` → re-run (throttle 0,2 s)
- [ ] Vérif manuelle : redimensionner la fenêtre Studio en Play → onglets/panels restent alignés
- [ ] commit `fix: re-layout UI au redimensionnement du viewport`

### Task 16: Audit sécurité + répétition générale

- [ ] Passer `workflows/security-audit.md` sur toutes les remotes Net.luau (validation type/range/cooldown serveur, rate limiting SE-5)
- [ ] Playtest MCP bout en bout complet (join → tutoriel → éclosion → ascension → faille → marché → duel → season → skill tree → rush → éclipse forcée par attribut de test)
- [ ] Suite verte attendue : ~140+ tests ; `stylua`/`selene` propres
- [ ] Cocher les cases dans `docs/RIFT_BEASTS_2_plan_production.md` + journaliser les écarts restants

## Prérequis humains (hors périmètre IA)

Créer les gamepasses/devproducts sur le Creator Hub → remplir `Config.GAMEPASSES/DEV_PRODUCTS` · icône/miniatures (3 variantes IA proposées, choix humain) · Discord · recrutement 20–30 playtesters.
