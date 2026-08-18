# RIFT BEASTS 2 — Spec P4 + P5 : Social & monétisation (design)

> **Document d'entrée** du lot P4+P5 (exécution planifiée en 7 étapes). Complète
> `RIFT_BEASTS_1_bible_design.md` (concept) et `RIFT_BEASTS_2_plan_production.md` (planning).
> Date : 18/08/2026. Lot : Trading, Duels, Gamepasses, Season pass, Classements, Sanctuaires visitables.

---

## 0. Décisions techniques (ponytail)

| Sujet | Décision | Pourquoi |
|---|---|---|
| Duel | **Sim statique résolu serveur** (pas de combat temps réel) : score attaquant = Σ power de l'équipe déployée, score défense = Σ power des créatures non déployées du défenseur, ratio + petit aléa seedé | Zéro combat en temps réel à coder, logique pure testable |
| Marketplace | Listings en **Essence seulement**. Le Robux entre via packs d'Essence DevProducts (tiers fixes) + gamepasses | ToS : pas de Robux joueur↔joueur ; pas de Payouts OpenCloud en v1 |
| Sanctuaires visitables | **Aperçu affiché** (snapshot du top joueurs : niveau, créatures par rang, espèces phares), pas de téléport | Pas de serveurs réservés en v1 |
| Season pass | Niveaux linéaires, XP par actions existantes, 2 pistes, créature exclusive + titres | Pattern connu, réutilise les Stats existantes |
| Migration | `DATA_VERSION` 3 → 4 dans `SaveService.luau` | Le profil ajoute Season, Titles, Market history |

## 1. Fichiers créés (patterns existants)

### Serveur (`src/server/Services/`, ajoutés à `Bootstrap.luau` ORDER)

| Fichier | Rôle | DataStore |
|---|---|---|
| `MarketService.luau` | Listings, achat/vente/retrait, frais 5 % (`MarketFee`), double confirmation + délai 60 s de retrait, transfert atomique : `EssenceService:Spend/Add` + move créature + cap acheteur | `MarketStore` |
| `DuelService.luau` + `src/shared/DuelSim.luau` | Défi même-serveur, mise Essence, résolution, gains/pertes | — |
| `PurchaseService.luau` | `ProcessReceipt`, grant-then-`PurchaseGranted` (SE-3), IDs gamepasses dans `Config.luau` (placeholders), grants : +2 slots, +50 % passif, auto-éclosion (skip cooldown), bundle | Receipt history |
| `SeasonService.luau` + `src/shared/Season.luau` | XP par action (éclosion/faille/rebirth/quêtes/élevage), seuils, récompenses, premium track | — |
| `LeaderboardService.luau` | Classement par `Stats.TotalEssenceEarned`, `LeaderboardStore` + MessagingService (sync cross-serveur, refresh 5 min), snapshots pour visite | `LeaderboardStore` |

### Shared

- `Net.luau` : `MarketList`, `MarketBuy`, `MarketSell`, `MarketRemove`, `DuelChallenge`, `DuelAccept`, `DuelDecline`, `SeasonSync`, `SeasonClaim`, `LeaderboardSync`, `MarketSync`
- `Config.luau` : `MARKET_FEE`, `DUEL_MIN_WAGER`, `SEASON_CONFIG`, `GAMEPASSES`, `LEADERBOARD_TOP`

### Client (`src/client/Panels/`, requêtés dans `Ui.luau` — onglets Tab5 Marché, Tab6 Duels/Classements)

- `MarketPanel.luau`, `DuelPanel.luau`, `SeasonPanel.luau`, `LeaderboardPanel.luau` (+ aperçu sanctuaires)

### Tests (`src/tests/unit/Cases/`, pattern `t.test` + `expect`)

- `Market_Test.luau`, `Duel_Test.luau`, `Season_Test.luau`, `Leaderboard_Test.luau` → ~74 → ~95 tests

## 2. Ordre d'exécution (dépendances)

1. **Migration v4** : SaveService (Season, Titles, Stats.DuelsWon/Lost, Market history) + tests
2. **Trading** : MarketService + MarketPanel + remotes + tests → playtest MCP
3. **Duels** : DuelSim + DuelService + DuelPanel + tests → playtest MCP
4. **Gamepasses** : PurchaseService + Config IDs + tests mock
5. **Season pass** : Season + SeasonService + SeasonPanel + tests
6. **Classements** : LeaderboardService + LeaderboardPanel + tests → playtest MCP complet
7. **P5** : icônes/miniatures (3 variantes IA → tranche humaine) · Discord + playtest fermé = tâches humaines

## 3. Règles de sécurité (skill roblox-game)

- Tout l'argent serveur ; aucune mutation d'Essence côté client (pattern existant respecté)
- Rate-limiting sur remotes marché/duel (SE-5)
- Validation type/plage/possession sur chaque payload (SE-2)
- `ProcessReceipt` : grant avant `PurchaseGranted` (SE-3)
- Liste au cap : achat refusé, vendeur intact — transaction atomique

## 4. Vérifications

- `stylua src` + `selene src` + tests (~95/95 verts)
- Playtest MCP : tutoriel → achat → éclosion → vente marché → achat → duel → claim season → classement visible
