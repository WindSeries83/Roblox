> STATUS: ARCHIVED
> SUPERSEDED BY: docs/product/ROADMAP.md and docs/production/VERTICAL_SLICE.md
> Historical document. Do not implement tasks directly without checking current code and execution-status.

# Lot 1 « La chasse » — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rendre la chasse haut de gamme réelle (œufs Épique/Légendaire, espèces Épic+, Mythic→Secret atteignables), vendre de la chance (potions + Server Boost + boutique v1), et rendre le monde vivant à toute population (ticker global, marché live).

**Architecture:** Tout est data-driven dans `Shared/Config.luau` / `Shared/Data/`. Logique pure testée dans `Shared/*.luau` + `tests/unit/Cases/`. Services serveur minces qui branchent la logique pure. Réseau via `Shared/Net.luau`. Le client n'affiche jamais de monnaie (SE-2).

**Tech Stack:** Vanilla Luau maison, ProfileStore, Rojo, suite de tests maison (`tests/unit/`), MessagingService/DataStore avec mocks Studio (pattern `storeOk` existant).

**Spec:** `docs/superpowers/specs/2026-08-23-revenus-brainrot-design.md` (§1.1, §2.1-2.4, §3.B.1/3.B.4)

## Global Constraints

- Monnaie/drops 100 % côté serveur ; le client affiche uniquement (SE-2, bible)
- Tests verts obligatoires avant chaque commit (`173/173` actuel — le compte montera)
- Prix indicatifs de la spec = hypothèses ; validés par EconomySim (Task 3) AVANT d'être figés dans Config
- Studio non publié : DataStore/Messaging mockés via guard `RunService:IsStudio()` ou pcall `storeOk` (patterns existants MarketService:21, LeaderboardService:14)
- Après synchro Rojo d'un module requis en Edit : tester en VM fraîche (play), sinon vieux cache
- Pas de commentaires sauf demande explicite ; pas de sur-ingénierie (ponytail)

---

### Task 1: Espèces Épiques/Légendaires/Mythiques (données + invariant)

**Files:**
- Modify: `src/shared/Data/Species.luau`
- Test: `tests/unit/Cases/Data_Test.luau`

**Interfaces:**
- Produces: 4 speciesIds utilisables par `Gameplay.RollEgg` : `EmberColossus` (Épique), `VoidManta` (Épique), `AuroraLeviathan` (Légendaire), `NyxWarden` (Mythique). Champs identiques aux existants (`Name`, `Rarity`, `BaseRate`, `BasePower`, `Family`, `Role`).
- Raison des valeurs : BaseRate suit la progression ×~2 par rang (Rare actuel 2.5-2.8) ; BasePower suit (Rare 22-24 → Épique ~35, Légendaire ~55, Mythique ~85).

- [ ] **Step 1: Écrire le test d'invariant (échoue d'abord)**

Dans `tests/unit/Cases/Data_Test.luau`, ajouter :

```lua
function TestData.TestEveryRarityHasSpecies()
	local seen = {}
	for _, def in pairs(Species) do
		seen[def.Rarity] = true
	end
	for rarity in pairs(Rarities) do
		if rarity ~= "UltraRare" and rarity ~= "Secret" then
			assert(seen[rarity], `No species for rarity {rarity}`)
		end
	end
	return true
end
```

(UltraRare/Secret exclus : ils s'obtiennent par ascension/déclencheur secret sur une créature existante, pas par espèce dédiée — cf. `Ascension.luau`.)

- [ ] **Step 2: Lancer les tests, vérifier l'échec**

Playtest MCP → console : échec attendu sur `No species for rarity Epic`.

- [ ] **Step 3: Ajouter les 4 espèces dans `Species.luau`**

```lua
	EmberColossus = {
		Name = "Colosse de braise",
		Rarity = "Epic",
		BaseRate = 3.6,
		BasePower = 34,
		Family = "Feral",
		Role = "Guardian",
	},
	VoidManta = {
		Name = "Raie du vide",
		Rarity = "Epic",
		BaseRate = 3.8,
		BasePower = 32,
		Family = "Mystic",
		Role = "Gatherer",
	},
	AuroraLeviathan = {
		Name = "Léviathan d'aurore",
		Rarity = "Legendary",
		BaseRate = 5.5,
		BasePower = 52,
		Family = "Mystic",
		Role = "Guardian",
	},
	NyxWarden = {
		Name = "Gardien de Nyx",
		Rarity = "Mythic",
		BaseRate = 8.0,
		BasePower = 80,
		Family = "Wild",
		Role = "Guardian",
	},
```

- [ ] **Step 4: Tests verts**

- [ ] **Step 5: Commit** `feat: especes epic+/mythique (invariant rarete x espece teste)`

---

### Task 2: Œufs Épique/Légendaire (config + gating)

**Files:**
- Modify: `src/shared/Config.luau` (EGG_PRICES, EGG_RARITY_WEIGHTS, RIFT_EGG_WEIGHTS, ANNOUNCE_MIN_RARITY inchangé)
- Modify: `src/shared/Sanctuary.luau` (EggGate)
- Test: `tests/unit/Cases/Sanctuary_Test.luau`, `tests/unit/Cases/DropRates_Test.luau`

**Interfaces:**
- Produces: tiers `EpicEgg`, `LegendaryEgg` consommés par `HatchService:Start` (Net.BuyEgg passe déjà `tier` librement — aucun changement serveur nécessaire hors config), `Sanctuary.EggLocked(tier, level)`.
- Poids (hypothèses sim, ajustées Task 3) :
  - `EpicEgg = { Epic = 78, Legendary = 20, Mythic = 2 }` prix 2000
  - `LegendaryEgg = { Legendary = 75, Mythic = 24, UltraRare = 1 }` prix 8000
  - `RIFT_EGG_WEIGHTS` devient `{ CommonEgg = 50, UncommonEgg = 30, RareEgg = 15, EpicEgg = 4.7, LegendaryEgg = 0.3 }` — la faille reste LA source haut de gamme (spec §1.1)
- Gating sanctuaire : EpicEgg rang 3, LegendaryEgg rang 4 (aligné sur le pattern `EggGate` existant — lire la fonction pour les rangs actuels Common=1, Uncommon=2, Rare=3 puis décaler si conflit).

- [ ] **Step 1: Tests d'abord** — dans `DropRates_Test`, ajouter : chaque entrée de `EGG_RARITY_WEIGHTS` somme à ~100 et ne référence que des raretés ayant ≥1 espèce (réutilise l'invariant Task 1). Dans `Sanctuary_Test` : `EggLocked("EpicEgg", 3)` nil, `EggLocked("EpicEgg", 2)` non-nil, idem Legendary 4/3.
- [ ] **Step 2: Vérifier échec**
- [ ] **Step 3: Implémenter** Config + EggGate
- [ ] **Step 4: Tests verts**
- [ ] **Step 5: Commit** `feat: oeufs epique/legendaire + gating sanctuaire + poids faille haut rang`

---

### Task 3: EconomySim étendu → validation des prix

**Files:**
- Modify: `tools/EconomySim.luau`

**Interfaces:**
- Consomme: `Config.EGG_PRICES`, `EGG_RARITY_WEIGHTS`, `RIFT_EGG_WEIGHTS`, courbe renaissance existante.
- Produces: rapport console (essence/jour, temps avant rebirth, panier F2P vs Starter vs whale léger avec potion ×2 quotidienne) — décide OUI/NON sur les prix des Tasks 2/6/7.

- [ ] **Step 1: Ajouter au sim** : profils joueur (F2P, Starter+potion×2/30min/jour, whale léger = potion + boost serveur fréquent), nouveau multiplicateur luck appliqué au rendement faille ET aux poids d'éclosion (via `SessionLuck.For` équivalent sim), coût œufs nouveaux inclus dans la stratégie d'achat (achète le meilleur œuf abordable).
- [ ] **Step 2: Exécuter** (`require(ReplicatedStorage.Tools.EconomySim)` en play ou via runner existant — suivre le mode d'exécution actuel du fichier).
- [ ] **Step 3: Critères d'acceptation** : F2P atteint toujours rebirth 4 en < 7 jours ; Starter réduit le grind de ~15-25 % (pas plus — pas de paywall déguisé) ; inflation fin de semaine contenue (< ×3 du taux J1). Si KO : ajuster prix/poids dans Config et rejouer jusqu'au vert.
- [ ] **Step 4: Noter les valeurs finales retenues** dans le rapport de commit.
- [ ] **Step 5: Commit** `feat: economysim panier lot1 (prix valides f2p/starter/whale)`

---

### Task 4: Meshes des 4 nouvelles espèces (Studio)

**Files:** Workspace.Creatures (place), aucune source Luau.

- [ ] **Step 1:** Pour chaque nouvelle espèce : `roblox_generate_mesh` low-poly texturé crépuscule (~2-4 studs, plus grands que les communs — lisibilité de rareté bible §3.1), insérer sous `Workspace.Creatures` à y=-500 comme les 10 templates existants, nommer exactement comme le speciesId.
- [ ] **Step 2:** Vérifier `PrimaryPart` défini récursivement (`FindFirstChildWhichIsA("BasePart", true)` — piège connu V2) ; corriger à la main si besoin.
- [ ] **Step 3:** `Ctrl+S` du place (persistance, procédure AGENTS.md).
- Pas de test unitaire ; vérifié visuellement au playtest final (Task 12).

---

### Task 5: Panneau œufs — lignes Épique/Légendaire

**Files:**
- Modify: `src/client/Panels/EggPanel.luau` (deux listes de tiers ~lignes 88 et 119-120)
- Modify: `src/client/UiKit.luau` (EGG_TIER_NAMES si table statique)

**Interfaces:**
- Consomme: `Config.EGG_PRICES.EpicEgg/LegendaryEgg`, `UiKit.DropRatesText(Config.EGG_RARITY_WEIGHTS[tier])` (déjà générique).
- Produces: boutons nommés `BuyEpic`/`BuyLegendary` dans le scroll (pattern `tierNames` ligne 119 : ajouter `EpicEgg = "BuyEpic", LegendaryEgg = "BuyLegendary"`), lignes `EggRow{4}`/`EggRow{5}`.

- [ ] **Step 1:** Remplacer les deux littéraux `{ "CommonEgg", "UncommonEgg", "RareEgg" }` par une seule constante locale en tête de fichier : `local TIER_ORDER = { "CommonEgg", "UncommonEgg", "RareEgg", "EpicEgg", "LegendaryEgg" }` et l'utiliser aux deux endroits (dédoublonnage, pas de duplication).
- [ ] **Step 2:** Vérifier le layout scroll (5 lignes tiennent ? sinon `CanvasSize` automatique existant — inspecter et adapter).
- [ ] **Step 3:** Playtest MCP : acheter un Œuf Épique (crédit essence test), vérifier taux affichés et verrouillage selon rang sanctuaire.
- [ ] **Step 4: Commit** `feat: ui oeufs epic/legendaire (taux affiches, gating visible)`

---

### Task 6: Module pur `Shared/Luck.luau`

**Files:**
- Create: `src/shared/Luck.luau`
- Test: `tests/unit/Cases/Luck_Test.luau`

**Interfaces:**
- Produces (consommé par LuckService Task 7 + BoostService Task 8) :
```lua
Luck.Stack(personalMult: number?, serverMult: number?, vipMult: number?): number
-- produit borné : math.min(personal * server * vip, LUCK_HARD_CAP), défaut 1
Luck.Active(expiryAt: number?, now: number): boolean
Luck.Expiry(now: number, durationSeconds: number): number -- now + durée
```
- Config ajoute : `LUCK_POTION_SMALL = { Mult = 1.5, Duration = 600 }`, `LUCK_POTION_BIG = { Mult = 2, Duration = 1800 }`, `SERVER_BOOST = { Mult = 1.5, Duration = 900, Cap = 2 }` (stack serveur max ×2), `LUCK_HARD_CAP = 6`.

- [ ] **Step 1: Test** — stack par défaut 1 ; potion 1.5 × boost 1.5 = 2.25 ; dépassement → cap 6 ; `Active(nil, t)` false ; `Active(t-1, t)` false, `Active(t+1, t)` true.
- [ ] **Step 2: Échec → implémentation → vert.**
- [ ] **Step 3: Commit** `feat: module luck pur (stack borne, expirations)`

---

### Task 7: LuckService (potions achetables, serveur-autoritaire)

**Files:**
- Create: `src/server/Services/LuckService.luau` (enregistrer dans Bootstrap comme les autres services)
- Modify: `src/server/Services/PurchaseService.luau` (route 2 dev products vers LuckService)
- Modify: `src/server/Services/SessionLuck.luau` (le bonus potion s'ajoute à la luck de session existante)
- Modify: `src/server/PlayerDataService.luau` ou migration ProfilStore (champ `Data.LuckPotionUntil` + `Data.LuckPotionMult` — persiste à travers rejoin, expire tout seul via horodatage)
- Test: `tests/unit/Cases/Luck_Test.luau` (partie intégration minimale)

**Interfaces:**
- Consomme: `Luck.*`, `Config.DEV_PRODUCTS.LuckPotionSmall/Big` (IDs ajoutés à Config, `Id = 0` placeholder comme les autres).
- Produces: `LuckService:PersonalMult(player): number` appelé par SessionLuck ; payload client `Net.LuckSync` `{ Mult, ExpiresAt }` pour l'affichage boutique/HUD.

- [ ] **Step 1:** Migration profil v6 (suivre le pattern Migration_Test existant : version+1, champs par défaut nil-safe).
- [ ] **Step 2:** ProcessReceipt → `profile.Data.LuckPotionUntil = Luck.Expiry(os.time(), cfg.Duration)` ; `PersonalMult` retourne `cfg.Mult` si `Luck.Active(...)`. Grant AVANT `PurchaseGranted` (SE-3).
- [ ] **Step 3:** Brancher dans SessionLuck (additif au calcul existant, plafond global via `Luck.Stack`).
- [ ] **Step 4:** Tests verts + playtest : achat simulé (produit ID 0 → utiliser l'API de test existante du PurchaseService si présente, sinon attribut de test comme en P4.5), vérifier `[ECON]` log + mult appliqué à un roll.
- [ ] **Step 5: Commit** `feat: potions chance serveur (persistantes, plafonnees, integrees session luck)`

---

### Task 8: ServerBoost (multiplicateur serveur partagé)

**Files:**
- Create: `src/server/Services/BoostService.luau`
- Modify: `src/shared/Net.luau` (events `BoostState`)
- Modify: `src/server/Services/PurchaseService.luau` (route dev product `ServerBoost`)
- Test: partie pure dans `Luck_Test` (cap cumulé serveur)

**Interfaces:**
- Produces: `Workspace:SetAttribute("BoostActiveUntil", t)`, `Workspace:SetAttribute("BoostMult", m)` (le pattern attribut existe : `EclipseActive`), broadcast `Net.BoostState:FireAllClients({ Mult, EndsAt })`. Hatch/Rift lisent l'attribut via `Luck.Stack(personal, boostAttr, 1)`.
- Cumul serveur : boosts successifs additionnent les durées, mult plafonné `Config.SERVER_BOOST.Cap` (×2).

- [ ] **Step 1:** Logique pure : `Boost.Add(currentUntil, currentMult, now, mult, duration) -> (until, mult)` avec cumul durée + cap mult. Test d'abord.
- [ ] **Step 2:** Service : ProcessReceipt → Add → attributs + FireAllClients + annonce serveur (« PlayerX a activé le Boost ! » via Net.RareDrop payload dédié ou event texte existant — réutiliser le canal d'annonce).
- [ ] **Step 3:** Intégration roll : HatchService line ~139 `local luck = sessionLuck.For(player)` → multiplier par boost attribut (via Luck.Stack). Rift rewards idem (RiftService — localiser le calcul `rate×60×mult`).
- [ ] **Step 4:** Tests verts + playtest (attribut forcé + vérif gain faille multiplié).
- [ ] **Step 5: Commit** `feat: server boost partage (cumul duree, cap x2, annonces)`

---

### Task 9: Ticker global cross-serveur

**Files:**
- Create: `src/server/Services/TickerService.luau`
- Modify: `src/server/Services/HatchService.luau` (Announce → publie aussi au ticker)
- Modify: `src/client/Ui.luau` ou nouveau petit composant UiKit (feed coin haut-droit)
- Test: partie pure throttle dans `Luck_Test` ou nouveau `Ticker_Test.luau`

**Interfaces:**
- Pure : `Ticker.ShouldShow(queueCount, osTime, lastShownAt, minIntervalSeconds, rarityRank) -> boolean` — throttle ~10/min global, bypass si rank ≥ Legendary.
- Serveur : publie `{ PlayerName, SpeciesName, RarityName, Rarity, MutationName, ServerId }` sur topic Messaging `"RBXTicker_v1"` à chaque drop Rare+ (déjà collectés dans `Announce`) + compteur mondial d'éclosions (incrément local, flush DataStore agrégé 60 s, clé hebdo `Week:{year}-W{week}`).
- Client : souscription relayée par le serveur local (le serveur agrège Messaging → `Net.RareDrop` existant + nouvel event `Net.GlobalStats`), UI = liste max 5 items fade-out, compteur « X éclos cette semaine » en tête de menu.

- [ ] **Step 1:** Test pure throttle (échec → impl → vert).
- [ ] **Step 2:** TickerService : subscribe Messaging (guard IsStudio), queue locale triée par rank, dispatch FireAllClients throttlé ; hook depuis `Announce` (un appel : `ticker:Publish(payload)`).
- [ ] **Step 3:** Compteur mondial : incrément local par éclosion, flush périodique GetAsync/SetAsync merge max() (mocké Studio), `Net.GlobalStats` au join + toutes les 60 s.
- [ ] **Step 4:** UI feed (réutiliser UiKit helpers, style bannière existante).
- [ ] **Step 5:** Tests verts + playtest : forcer un roll Rare (attribut test), voir l'item dans le feed local ; Messaging réel à valider sur place publié (connu).
- [ ] **Step 6: Commit** `feat: ticker drops global + compteur mondial eclosions`

---

### Task 10: Marché live sync inter-serveurs

**Files:**
- Modify: `src/server/Services/MarketService.luau` (BroadcastListings existe déjà ligne ~165 — le brancher sur Messaging + subscribe reload)
- Modify: `src/shared/Config.luau` (`MARKET_MAX_PRICE` → valeur retenue par sim Task 3, ex. 250000)
- Test: existants `Market_Test` restent verts (logique pure inchangée)

**Interfaces:**
- Consomme: pattern Messaging LeaderboardService (subscribe guard IsStudio, republish throttle 5 s).
- Produces: listings frais sur tous les serveurs ≤ 60 s après un list/buy/retrait.

- [ ] **Step 1:** Après chaque mutation (list/buy/remove) : `PersistListings()` (existant) puis PublishAsync topic `"RBXMarket_v1"` payload léger `{ UpdatedAt = os.time() }`.
- [ ] **Step 2:** Subscribe → si `UpdatedAt > lastApplied` : `LoadListings()` + `BroadcastListings()` (FireAllClients existant). Fallback : refresh complet 60 s.
- [ ] **Step 3:** Bump `MARKET_MAX_PRICE` selon sim ; vérifier `ValidatePrice` test borne haute mis à jour.
- [ ] **Step 4:** Tests verts + playtest local (list → buy sur même serveur, régression).
- [ ] **Step 5: Commit** `feat: marche live inter-serveurs (messaging + refresh) + plafond prix releve`

---

### Task 11: Boutique v1 (onglet Shop)

**Files:**
- Create: `src/client/Panels/ShopPanel.luau`
- Modify: `src/client/Ui.luau` (onglet « Boutique » dans le menu existant, icône 🛒 — suivre le pattern des 8 onglets actuels)
- Modify: `src/shared/Net.luau` (`RequestPurchase(productId)` → PurchaseService.ProcessReceipt flow standard MarketplaceService)

**Interfaces:**
- Consomme: `Config.DEV_PRODUCTS` complet (noms/prix Robux affichés côté client, achat via `MarketplaceService:PromptProductPurchase`), `Net.LuckSync`/`Net.BoostState` pour jauges actives.
- Contenu v1 : 2 potions (timer restant affiché si active), Server Boost (jauge serveur), packs Essence (existants), VIP grisé « bientôt » (Lot 2). Offre 1er achat : NON (Lot 2, analytics d'abord).

- [ ] **Step 1:** ShopPanel (réutiliser UiKit.SubTabs : sections Chance / Confort / Essence).
- [ ] **Step 2:** PromptPurchase câblé ; boutons désactivés pendant potion active (affiche temps restant).
- [ ] **Step 3:** Playtest : prompts s'ouvrent (achat réel impossible en Studio — vérifier le prompt seulement), jauges se mettent à jour via events.
- [ ] **Step 4: Commit** `feat: boutique v1 (potions, boost, essence) avec jauges actives`

---

### Task 12: Playtest bout en bout + suite verte

> **Statut 23/08 : gameplay e2e VALIDÉ, un blocant visuel découvert (voir Known Issue).**

Validé en playtest réel :
- Boot propre, 188/188 tests
- Gating serveur : EpicEgg refusé au rang 1 (`[ECON] Eggs | EggLocked`) puis accordé au rang 4 après 3 upgrades réelles (1000+4000+16000)
- Achat EpicEgg → éclosion → **Léviathan d'aurore Légendaire**, `Hatch Success` + `Announce` publiés au ticker, annoncé=true côté client
- Fix critique trouvé par le playtest : **dépendance circulaire Bootstrap** EssenceService ↔ QuestService → référence questService nil à jamais (latente : n'explosait qu'au premier gain d'Essence avec rate > 0). Résolue en résolvant QuestService au Start() d'EssenceService.

**Known Issue — meshes IA absents en Play :**
Les 4 modèles générés par Assistant (`generate_mesh`) existent en Edit et dans le .rbxlx sauvegardé, mais **disparaissent à chaque passage en Play**. Test décisif : un clone de Riftling survit, les 4 générés non → leur contenu mesh est lié à la session Assistant (asset interne non publié), non sérialisable vers l'environnement de jeu.
Deux voies de fix :
- **A (recommandé)** : régénérer les 4 créatures via `generate_procedural_model` (primitives Part pures → sérialisables), pipeline V1 éprouvé
- **B (humain)** : uploader les 4 meshes via Asset Manager (publish) et reparenter les modèles uploadés dans Workspace.Creatures

- [x] Synchro Rojo vérifiée (marqueur < 5 s)
- [x] Suite complète : 188/188 tests
- [x] Parcours MCP complet : crédits test → upgrades sanctuaire → achat EpicEgg → éclosion Legendary + annonce serveur → ticker alimenté ([ECON] Hatch | Announce) → zéro erreur console
- [ ] Visuel des 4 nouvelles créatures en jeu (bloqué par Known Issue)
- [x] Console propre : zéro erreur Lua hors mocks attendus
- [ ] `Ctrl+S` place après résolution du Known Issue

---

## Self-review

1. **Spec coverage Lot 1** : §1.1 (Tasks 1-5), §2.1 potions/boost/boutique (Tasks 6-8, 11), §2.4 sim (Task 3), §2.3 plafond marché (Task 10), §3.B.1 ticker+compteur (Task 9), §3.B.4 marché live (Task 10). Hors périmètre Lot 1 (documenté) : offres 1er achat/retour + VIP (Lot 2), mur VIP Secrets (Lot 4).
2. **Placeholders** : IDs gamepasses restent `0` volontairement (tâche humaine documentée). Aucun TBD dans les steps.
3. **Types cohérents** : `Luck.Stack/Active/Expiry` définis Task 6, consommés Tasks 7-8 ; tiers `EpicEgg/LegendaryEgg` définis Task 2, consommés Tasks 3/5 ; `BuyEpic/BuyLegendary` Task 5 alignés sur le mapping `tierNames` existant.
