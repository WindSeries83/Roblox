# RIFT BEASTS — Plan de production (IA-first)

> **Document 2/2.** Le *comment*. Voir `RIFT_BEASTS_1_bible_design.md` pour le concept et les systèmes.
> Production solo, assistée par IA via MCP Roblox Studio.

---

## 0. Décisions actées

| Sujet | Décision |
|---|---|
| Framework | **Vanilla Luau maison** — modules de services + Bootstrap minimal, pas de framework tiers |
| Sauvegarde | **ProfileStore** (`lm-loleris/profilestore@1.0.3`) via Wally, realm `server` → `ServerPackages/` |
| MCP | **MCP intégré de Studio** seul (pas de MCP communautaire pour l'instant) |
| Scope | **P0 enchaîné sur P1** (vertical slice) |
| Outillage | Rojo 7.7 + rokit (StyLua, selene avec `std = "roblox"`, wally) |

---

## 1. Stack de production IA

### 1.1 Options disponibles

| Outil | Rôle |
|---|---|
| **MCP intégré à Roblox Studio** | Voie recommandée par Roblox. `Assistant → ⋯ → Manage MCP Servers → Enable Studio as MCP server`, puis quick connect vers le client (Claude, Cursor…). Serveur local, transport stdio. |
| **Assistant Roblox** | Intégré à Studio, supporte désormais des LLM externes. Bon pour les tâches courtes in-context et l'automatisation de playtest. |
| `Roblox/studio-rust-mcp-server` | Serveur standalone open source. Roblox a déplacé son investissement vers le MCP intégré — à ne garder que si besoin spécifique. |
| MCP communautaires (`robloxstudio-mcp`, WEPPY…) | Plus d'outils : multi-Studio, génération et upload d'assets via Open Cloud. À auditer avant usage. |

### 1.2 Workflow retenu
1. **Agent de code externe** (Claude Code) connecté au **MCP intégré de Studio** → lecture du DataModel, écriture de Luau, refactor de masse.
2. **Assistant Roblox** pour l'itération rapide dans l'éditeur et l'automatisation des playtests.
3. **Git obligatoire** (Rojo + repo externe). Le MCP modifie le place directement : sans versioning, une mauvaise commande coûte une journée.
4. Travailler sur une **copie** du place, jamais sur la production.

### 1.3 Garde-fous
- `Allow HTTP Requests` activé uniquement pendant les sessions IA
- Relire tout script généré touchant à **DataStore, économie, achats, anti-triche**. L'IA écrit très bien du gameplay et très mal de la sécurité serveur.
- Toute logique d'argent et de drop **côté serveur uniquement**. Aucune exception.
- Auditer tout MCP communautaire avant installation (il a accès à ton place).

### 1.4 Répartition IA / humain

| L'IA fait bien | À faire soi-même |
|---|---|
| Boilerplate de services, UI, refactor de masse | Équilibrage et courbe économique |
| Systèmes de gameplay isolés | Sécurité serveur et anti-triche |
| Génération de variantes de créatures | Direction artistique et identité visuelle |
| Migration et renommage à grande échelle | Décisions de design (ce qui reste, ce qui saute) |

---

## 2. Phases de développement

### P0 — Socle technique · 1–2 semaines
- [x] Studio à jour, MCP intégré activé, agent connecté
- [x] Rojo + repo Git en place, place de dev séparé du place de prod
- [x] Architecture serveur/client posée : ProfileStore pour la sauvegarde, modules de services (Bootstrap, SaveService, Log)
- [x] Log serveur pour tout ce qui touche à l'économie (`[ECON]` ring buffer + print)

**Sortie :** un place vide mais propre, où l'IA peut travailler sans casser la sauvegarde.

### P1 — Vertical slice · 3–4 semaines
Le minimum qui prouve que la boucle est amusante.
- [x] 1 sanctuaire, génération d'Essence AFK (tick 1 s, gains hors ligne à 50 %, cap 12 h)
- [x] 10 créatures, 3 raretés, 2 mutations (données complètes 8 raretés / 6 mutations prêtes pour P2)
- [x] 1 type de Faille avec combat simple (portail cyclique, gardien, cristal, récompenses ×8)
- [x] Éclosion d'œufs + effet de drop rare (flash + bannière + annonce serveur — son à ajouter)
- [x] Sauvegarde fiable (playtest MCP complet exécuté : join, starter, achats, éclosions, faille victoire/défaite, récompenses — en mode mock Studio ; à revalider sur place publié avec accès DataStore)

**Test de vérité :** est-ce que *toi* tu as envie de relancer le lendemain ? Si non, ne pas continuer — corriger la boucle.

### P2 — Systèmes de profondeur · 4–6 semaines
- [x] Index complet avec bonus permanents
- [x] Équipement (Cœurs / Colliers / Reliques) + slots
- [x] Évolution des créatures (4 stades)
- [x] Élevage génétique + arbres généalogiques
- [x] Renaissance et Étoiles

**Sortie :** un joueur peut faire 20 h sans plafonner. ✓ (tests 59/59 → 64/64)

### P3 — Économie & équilibrage · 2–3 semaines
- [x] Courbe chiffrée complète : coût des œufs, rendement d'Essence, temps avant Renaissance 1, 2, 3
- [x] Tables de drop finalisées et **publiées** (voire §7)
- [x] Sinks de monnaie (upgrade du sanctuaire : +2 places, coût base 1000 ×4 par niveau)
- [x] Simulation **avant** implémentation (EconomySim, 7 jours simulés ×3 runs, joueur connecté)
- [x] Cap de créatures : 10 au niveau 1, +2 par niveau de sanctuaire
- [x] Renaissance garde la créature la plus forte

**Résultats de simulation (courbe retenue `{50 000, 250 000, 1 250 000, 6 250 000}`) :**
Renaissance 1 ~13–18 min · Renaissance 2 ~30–40 min · Renaissance 3 ~1h10–1h20 · Renaissance 4 ~2h48–3h31. **4 rebirths en 7 jours** — plus de mur (l'ancienne courbe 10k/100k/1M ne permettait jamais rebirth 4). Taux de fin de semaine ~1700–2300/s (inflation contenue par le cap 10).

**Sortie :** aucune progression bloquée, aucune inflation prévisible. ✓ (64/64 tests verts, playtest remotes : cap, upgrade, rebirth)

### P4 — Social & monétisation · 3–4 semaines
- [x] Trading + place de marché + anti-arnaque
- [x] Duels de sanctuaires
- [x] Gamepasses et bundles
- [x] Season pass v1
- [x] Classements et sanctuaires visitables

### P4.5 — Monde vivant (game feel) · fait
- [x] Arche de faille permanente (construite au démarrage, s'illumine à l'ouverture) + payload `RiftWorld.NextAt` → compte à rebours client
- [x] Couveuse 3D dans le monde (socle + œuf + ProximityPrompt) et `CouveusePanel` (achat/éclosion sans ouvrir le menu)
- [x] Créatures cliquables dans l'enclos → `CreatureHud` (équiper / évoluer / vendre avec prix suggéré)
- [x] Feedbacks : `Fx.FloatText` (+N Essence flottant), burst + saut au clic créature
- [x] `ObjectiveBanner` directionnel (faille active > quêtes prêtes > premier œuf > renaissance) — fonctions pures dans `Shared/Objective` testées

**Playtest MCP bout en bout ✓** (121/121 tests) : achat œuf (100→50), éclosion ×5, équipement Cœur (+5 niveau max), mise au marché (listing créé), entrée faille par marche réelle, combat gardien (dégâts selon puissance d'équipe), victoire + récompenses (~+1900 Essence), cycle faille 15 s/180 s via attribut de test, bandeau directionnel actif pendant la faille, badge quêtes « 2 ». Divers : suppression de `init.client.luau` (vestige) qui bloquait la synchro Rojo du dossier client ; BOM réapparu sur `default.project.json` retiré ; anti-rebond sur le toggle du prompt couveuse ; `CouveuseGui.AlwaysOnTop=false` (le pass AlwaysOnTop ne se rend pas dans cette session Studio — occlusion possible par le décor, acceptable).

### P5 — Pré-lancement · 2 semaines
- [ ] Icône et miniatures : **le poste le plus rentable du projet**. Tester plusieurs variantes. (3 variantes IA à générer → l'humain tranche)
- [x] Rétention des 3 premières minutes : premier drop rare dans les 60 s — **pity au premier œuf** (`FIRST_HATCH_WEIGHTS` 40/40/20 au lieu de 75/20/5), appliqué au premier œuf commun éclos
- [ ] Discord ouvert **avant** la sortie (tâche humaine — notes fournies)
- [ ] Playtest fermé avec 20–30 joueurs adultes recrutés sur Discord / Reddit (tâche humaine — notes fournies)
- [x] Anti-triche : vérifier que rien de monétaire ne passe par le client — **audité : 0 mutation d'Essence côté client** (affichage uniquement, toute la monnaie est serveur)

### P6 — Lancement & live ops · permanent
- [ ] **Update hebdomadaire non négociable.** Sans ça, le jeu meurt en trois semaines.
- [ ] Évènement saisonnier toutes les 2 semaines
- [ ] Suivi : rétention J1 / J7 / J30, ARPDAU, temps avant premier achat
- [ ] Communication publique sur les changements d'équilibrage

---

## 3. Acquisition

L'algorithme Roblox pousse ce qui performe auprès de la masse, c'est-à-dire des ados. **Un jeu à esthétique adulte aura un CTR médiocre sur la page d'accueil.**

Conséquence : l'acquisition doit venir de **l'extérieur**, et être prévue dès P0.
- **Discord** — cœur de la communauté adulte
- **YouTube long format** — guides d'optimisation, tier lists
- **Reddit** — r/roblox, communautés de jeux idle
- **TikTok / Shorts** — clips de drops Ultra Rare

Plus lent que le trafic Roblox natif, mais bien plus fidèle.

---

## 4. Checklist technique & business

**Technique**
- [ ] Toute logique économique côté serveur
- [ ] Sauvegarde testée contre les crashs et les rejoins rapides
- [ ] Git + place de dev séparé
- [ ] Scripts IA relus sur tout ce qui touche DataStore / achats
- [ ] Anti-exploit vérifié avant lancement

**Business**
- [ ] Icône testée en A/B
- [ ] Discord ouvert avant le lancement
- [ ] Cadence d'update hebdo tenable en solo
- [ ] Métriques instrumentées dès P1 (pas après)

---

## 5. Risques identifiés

| Risque | Gravité | Mitigation |
|---|---|---|
| Découverte faible (algo Roblox défavorable au public adulte) | **Élevé** | Acquisition externe planifiée dès P0 |
| Cadence d'update intenable en solo | **Élevé** | Réduire le scope de P2/P4 plutôt que le rythme de live ops |
| Genre saturé | Moyen | Les deux différenciateurs (élevage + duel consenti) doivent être visibles dès la miniature |
| Inflation de l'économie | Moyen | Simulation tableur avant implémentation, sinks dès P3 |
| Code IA non sécurisé sur l'économie | Moyen | Relecture obligatoire, tout côté serveur |
| Perte de travail via commande MCP destructive | Moyen | Git + place de dev séparé dès P0 |
| Mineurs dans une audience visée adulte | Faible | Contenu sûr par défaut, pas de mécanique de pression à l'achat |

---

## 6. En suspens

- Budget temps réel disponible par semaine → conditionne la durée réelle des phases
- Direction artistique P1 : placeholder parts simples — génération de meshes/visuels à planifier
- [x] Sons (éclosion, drop rare, faille, upgrade, évolution, rebirth, clic) : 8 assets Creator Store insérés dans le place + module `Audio.luau` (IDs en dur dans le repo)
- Sauvegarde DataStore : à revalider sur place **publié** (Studio : « Roblox API services unavailable » attendu)
- Place Studio : sauvegarder le fichier (`Ctrl+S`) après toute synchro MCP — les remotes sont désormais déclarées dans `default.project.json`
- [x] **Faille testée de bout en bout** (playtest réel, RiftInterval=30s temporaire) : ouverture cyclique, entrée par Touched, combat (dégâts `floor(power×0.8)`, gardien 12 PV/2,5 s), GuardianDown → cristal, win par proximité <6 studs ou Touched, récompenses (essence `rate×60×mult` source RiftCrystal + œuf RIFT_EGG_WEIGHTS), compteur `RiftsCompleted`. Edge case : un joueur sans créatures (power 0) ne peut pas gagner — perte rapide, pas de softlock.
- [x] **Bug display corrigé** : `FindFirstChildOfClass("BasePart")` ne matche pas les `MeshPart` (className exact) → `PrimaryPart` jamais défini sur les clones → PivotTo/grid/anim jamais exécutés (créatures display superposées aux templates, d'où « les créatures alignées » visibles en Edit). Fix : `FindFirstChildWhichIsA("BasePart")`. Les 10 templates déplacés sous la map (y=-500) dans le place **et** `default.project.json` (54 parts).
- [x] **LOT A — Tutoriel joué de bout en bout (MCP)** : Continuer → Menu → onglet Œufs → Éclore (MossCrawler, succès FirstHatch +50) → Récompense (+50), 74/74 tests verts. Fixes : chat Roblox désactivé (recouvrait les 3 premiers onglets et bloquait les clics), positions explicites des onglets, fix crash nil des barres de progression des quêtes.
- [x] **À trancher (étape 3 tutoriel)** : résolu — les étapes 3 et 5 exigent désormais un clic explicite sur l'onglet (Œufs puis Sanctuaire) via `TutorialBridge.SetActive` + `TutorialBridge.state.ActiveTab` (LOT B).
- [x] **À trancher (chat Roblox)** : décidé — chat moderne TextChatService bas-gauche (`ChatWindowConfiguration.VerticalAlignment = Bottom` dans `Ui.luau`). Tant que `ChatVersion = LegacyChatService`, l'ancien chat est désactivé/détruit (il bloquait les clics de l'UI). **Résolu** : flip `ChatVersion = TextChatService` effectué dans l'Explorer + `Ctrl+S` (persisté dans `Roblox.rbxlx`). Playtest MCP : clics UI OK, canaux `RBXGeneral`/`RBXSystem` créés, zéro erreur. Notes : (1) la frappe de message n'est pas testable en playtest Studio (pas de `PlayerChat` en solo) — à vérifier sur place publié ; (2) la déclaration `TextChatService` a été retirée de `default.project.json` (propriété verrouillée pour l'API plugin : Rojo ne peut pas l'appliquer et alertait à chaque sync — le flip vit uniquement dans le `.rbxlx`, non versionné, à refaire si le place est régénéré).
- [x] **V1 — Monde & atmosphère (place)** : île sculptée (~120 studs, plateau h=8, herbe sombre, plages rocheuses), eau sombre (WriteVoxels + FillBlock, `Terrain.WaterColor` bleu nuit), chemins en terre (spawn → enclos, spawn → portail), zone d'enclos plate. Décor low-poly généré (`DecorTemplates/` + clones `Decor/`) : 12 arbres, 9 rochers, 10 lanternes dorées (PointLight ambre), clôture d'enclos (portail côté chemin), plateforme de spawn cylindrique + anneau lumineux, portail de faille (arche de pierres + cristaux Neon violets + émetteur de brume). Éclairage : crépuscule nocturne (ClockTime 19.5, Atmosphere, ColorCorrection, Bloom doux, brouillard violet), 2 lunes (lune par défaut du ciel + « MoonAzur » Neon), lucioles à prévoir en V3. Grille des créatures relevée sur le plateau (`GridPosition` y 3→11), spawn sur la plateforme.
- [x] **LOT B — fonctionnel (code + playtest MCP)** : tutoriel reformulé (étapes 3/5 = clic d'onglet), chat moderne configuré bas-gauche (flip manuel restant), positions explicites MCP-compatibles (BuyCommon/Uncommon/Rare, BuyHeart1-3, BuyCollar1-3, EggRow{i}/HatchButton{i}, CreatureRow{i}, QuestRow_{id}, Claim_{id}, SubTab1-3, Tab1-6). Playtest complet dans le nouveau décor : tutoriel 6/6, achat œuf + éclosion (HatchDaily 2/2 + réclamation +100), achat Cœur T1 + équipement (1/1), upgrade sanctuaire refusé proprement (fonds insuffisants, chemin réussi couvert par les tests), 74/74 tests verts. Fix : `{target}` substitué dans les descriptions de quêtes.
- **Connu (non bloquant)** : le layout compact de l'UI est figé au spawn (pas de re-layout au redimensionnement du viewport) — visible uniquement quand le viewport change en cours de partie (fenêtre Studio redimensionnée).
- [x] **V2 — Créatures** : 10 espèces régénérées en low-poly texturé « crépuscule » (generate_mesh, ~2-3 studs) et remplacées dans `Workspace.Creatures` (y=-500). Nettoyage requis : les maillages générés contenaient des copies libres à l'origine (54 supprimées) qui ne suivaient pas PivotTo, et `PrimaryPart` devait être défini récursivement (`FindFirstChildWhichIsA("BasePart", true)`) — même correction dans `CreatureDisplay`. Lisibilité de rareté (bible §3.1) dans `CreatureDisplay` : taille (1 → 1.9 × par rang × stade × mutation log10), aura Neon + PointLight colorés (rang ≥ 2), particules ambiantes (rate 4 → 60 par rang), lévitation amplifiée par rang. Vérifié en playtest : CinderSeraph Rare muté Ombre (pity 1er œuf) — grille, aura, particules, taille 1.25×, annonce serveur.
- [x] **V3 — UI & game feel** : animation d'ouverture/fermeture du menu (TweenService : scale 0.96→1 + transparence), hover des boutons (UIScale 1.05 sur MouseEnter/Leave, aucun impact layout), barre supérieure avec dégradé, lucioles ambiantes (20 points Neon client-only dérivant sur l'île), caméra au spawn (CameraType Scriptable 1,2 s → Custom). `default.project.json` : `Workspace` réduit à `$properties` + `SpawnLocation` (Baseplate/Creatures retirés → place-owned, sinon rojo restaurerait l'ancien monde).
- [x] **Restes V3** : flip `ChatVersion = TextChatService` (Explorer) + `Ctrl+S` du place + validation visuelle finale — tout clôturé le 18/08. L'alerte Rojo sur `ChatVersion` (propriété verrouillée) est éliminée par le retrait de la déclaration dans `default.project.json`.
- [x] **P4 — Social & monétisation (18/08, 113/113 tests)** : migration v4 (Season, Titles, Entitlements, Stats.DuelsWon/Lost/MarketSales, MarketHistory), marché d'Essence (frais 5 %, cap 5 listings, retrait double confirmation + 60 s, crédits différés si vendeur déconnecté), duels statiques seedés (mise en escrow, remboursement sur refus/timeout 60 s), gamepasses (MoreSlots +2, PassiveBoost +50 %, AutoHatch, StarterBundle, SeasonPremium — **IDs placeholder 0 à renseigner**), season pass (XP par éclosion/faille/rebirth/quêtes/élevage, 20 niveaux, 2 pistes, créature exclusive CinderSeraph+Shadow au niv. max premium), classements (Essence totale, refresh 5 min, snapshots, MessagingService cross-serveur **à valider sur place publié**). Playtest MCP : 8 onglets UI, vente/retrait/auto-achat-refusé, claim season, classement + aperçu sanctuaire. 2 bugs serveur trouvés en playtest : `MessagingService:SubscribeAsync` bloque indéfiniment en Studio non publié (fix : guard `RunService:IsStudio()`), et script serveur doublon « Main » du .rbxlx (supprimé — reste `ServerScriptService` de Rojo comme unique point d'entrée). **Ctrl+S du place requis** pour persister la suppression de « Main ».
- [x] **Rojo cassé le 18/08** : l'installation Rojo ne propageait plus les fichiers dans Studio (panels/remotes non créés) — diagnostic : le serveur `rojo serve` voyait les fichiers (sourcemap OK) mais le plugin Studio ne recevait rien. Solution de contournement : push manuel via MCP (multi_edit + recréation d'instances). **RÉSOLU le 21/08** : l'outillage était intact (rokit 1.2.0, Rojo 7.7.0) — c'est le processus `rojo serve` qui n'était plus lancé. Redémarré, propagation vérifiée par marqueur (`SYNC_MARKER` dans Config.luau visible côté Studio en < 5 s). Procédure : `rojo serve` en tâche de fond au début de chaque session, plugin Studio → Connect si besoin.
- [x] **Rétention brain rot (23/08, 173/173 tests)** : migration v5 (`LoginStreak`, `LastLoginDate`, `Stats.HatchesSinceRare`). **Série de connexion** — récompense quotidienne croissante sur 7 jours `{100, 150, 250, 400, 600, 900, 1500}` puis cycle, reset si un jour manqué, logique pure dans `Shared/Streak.luau` testée, évaluée au join dans PlayerDataService, toast client via pipeline QuestsSync Notice (délai 5 s pour laisser l'UI monter). **Pity Rare** — Rare garanti à la 20e éclosion sans Rare+ (`PITY_THRESHOLD`), upgrade du roll dans HatchService avant compteur, compteur visible dans l'onglet Œufs (« Garantie Rare : X/20 », doré sous 5). Playtest MCP : boot propre, `[ECON] Essence | Streak Day:1 Amount:100` au join, toast affiché, label pitié « 0/20 ». Note : après synchro Rojo d'un module déjà requis en Edit, le cache require sert la vieille version — lancer les tests en VM fraîche (play) ou compter un run fantôme.

## 7. Décisions P3 actées

| Sujet | Décision |
|---|---|
| Courbe de renaissance | `{ 50000, 250000, 1250000, 6250000 }` — rebirth 1 ≈ 15 min, rebirth 4 ≈ 3 h (sim 7 j) |
| Cap créatures | 10 au niveau 1 (`MAX_CREATURES_BASE`), +2 par niveau de sanctuaire (`SANCTUARY_SLOTS_PER_LEVEL`) |
| Coût upgrade sanctuaire | base 1000 Essence, ×4 par niveau — reset à 1 au rebirth |
| Renaissance | garde la créature la plus forte + Index + Reliques légendaires ; perd œufs, Essence, niveau de sanctuaire |
| Compteur de renaissance | `TotalEssenceEarned` **cumulatif** (jamais remis à 0) |
| Rejets au cap | éclosion : l'œuf n'est pas consommé ; élevage : vérifié **avant** le paiement (aucune perte) |
