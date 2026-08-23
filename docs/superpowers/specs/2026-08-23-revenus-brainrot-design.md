# RIFT BEASTS — Spec « Revenus & Brain Rot » (refonte pré-lancement)

> Design validé le 23/08/2026 en session collaborative. Complète la bible (`RIFT_BEASTS_1_bible_design.md`) et le plan P5.
> **Objectif n°1 réaffirmé : les revenus.** Levier retenu : coque « brain rot » virale posée sur la profondeur existante — attirer la masse, la garder par la chasse et le social.

---

## 0. Décisions actées

| Sujet | Décision |
|---|---|
| Positionnement | **Hybride** — surface brain rot (dopamine rapide, drops visibles, moments clippables) sur cœur profond (élevage, index, mutations). Pattern Adopt Me / Pet Sim : simple en surface, profond au cœur. La cible adulte de la bible reste servie par la profondeur |
| Périmètre | **Compléter le socle** (écarts bible/code) **+ couche virale** — pas de refonte des systèmes existants (170 tests verts protègent) |
| Ton | **Humour en surface** : répliques absurdes data-driven, événements décalés ; fond crépuscule/mystère inchangé ; pas de renommage meme des créatures |
| Monétisation | **Aggressif soft** : potions de chance, Server Boost social, offres timées, VIP, FOMO léger informatif. Jamais de paywall, jamais de compteur agressif (bible §7 conservée comme socle) |
| Cadence | ~10 h/semaine → hebdo léger data-driven + un gros chantier mensuel |
| Population | Vivant garanti à toute échelle (§3) : jamais de faux joueurs, données globales réelles rendues visibles |
| Social | Amis : rejoindre + bonus meute ; Groupe Roblox officiel : bonus membre (§5) |

---

## 1. Systèmes & contenu (le fond)

### 1.1 Chemins de rareté complets — LA priorité

Constat : les œufs plafonnent à `Rare` alors que 8 raretés sont définies (`Rarities.luau`). Toute l'économie de la chance repose sur une chasse haut de gamme qui n'existe pas encore.

- Nouveaux œufs : **Œuf Épique** (~2 000 Essence) et **Œuf Légendaire** (~8 000 Essence), prix finaux validés par sim (§2.4)
- Chaque palier d'œuf peut dropper au-dessus avec de faibles poids (l'espoir à chaque éclosion)
- **La Faille = source exclusive des hauts rangs** : Mythique / UltraRare / Secret ne tombent que via faille (+ mutations). Les Reliques restent non achetables (bible §3.4)
- UltraRare ≈ 1/250 M conservé, annonce serveur existante ; Secret sans chemin documenté (drop path caché, mur VIP au Lot 4)

### 1.2 Vague d'espèces 10 → 30

- Génération IA low-poly (pipeline V2 déjà éprouvé), données pures dans `Species.luau` (famille, rôle, taux, puissance)
- Post-lancement : +3-5 espèces/semaine via le même pipeline (live ops tenable)

### 1.3 Arbre d'Étoiles (arbre de compétence version pragmatique, bible §3.7)

- +1 point par renaissance, grille de ~12 nœuds permanents, 3 branches : Farm / Faille / Économie
- `Shared/SkillTree.luau` data-driven + panneau UiKit. Rien n'y est vendable (bible)

### 1.4 Mondes = thèmes, pas nouvelles cartes

- Monde N+1 = même île, décor/recoloration via `DecorTemplates`, multiplicateurs ×N, espèces exclusives
- **Mode Rush** : objectif chronométré simple par monde (ex. « faille < 90 s »), récompense unique + bonus Index

### 1.5 Éclipse — évènement serveur

- Toutes les 2 h, 10 min : changement de ciel, annonce serveur, mutation boostée ×10, créature exclusive de l'événement
- Horloge serveur, **jamais conditionnée à la population**. Réutilise les patterns OrbService/RiftService

### 1.6 Couche humour (surface assumée)

- Table data-driven de répliques absurdes : bulles au clic créature, noms d'attaques ridicules en faille, textes d'événements décalés
- Zéro impact système — pur flavor clippable

---

## 2. Économie & monétisation (« aggressive soft »)

### 2.1 Gamme de produits (prix indicatifs — validés par sim avant code)

| Produit | Prix | Rôle |
|---|---|---|
| Starter Pack | 149 R$ | Créature Rare mutée + 1 000 Essence + potion ×2 30 min. Seuil du classement léger (bible §8) |
| Potion Chance ×1,5 / 10 min | 49 R$ | Consommable vedette des jeux d'éclosion |
| Potion Chance ×2 / 30 min | 149 R$ | idem |
| Server Boost | 99 R$ | +50 % chance pour tout le serveur, 15 min, annoncé + jauge visible. Dépense sociale/statut, empilable jusqu'à un cap affiché |
| VIP Pass (30 j) | ~399 R$ | ×1,25 chance, tag doré, aura, prix soldés −10 % sur les consommables vedettes + Zone VIP de luxe (coffre journalier, œuf VIP, statut) — détail §2.5 |
| Auto-Éclosion / +Slots / Rendement | 249 / 199 / 199 R$ | Confort (existants, repricing) |
| Offre 1er achat | −50 % une fois | Déclenchée après le 1er drop Épic+ OU au retour J2 |
| Offres de retour | J2/J7 | Cadeau + bundle temporaire |
| Packs Essence (existants) | — | Valve de confort conservée |
| Season Premium (existant) | — | Conservé |
| Rename ticket | 49 R$ | Renommer une créature — cosmétique pur (§2.6) |
| Cosmétiques purs | 49–199 R$ | Skins/recolors créatures, effets de particules, déco sanctuaire — zéro gameplay (§2.6) |
| Bundle mensuel thématique | ~499 R$ | Rotation mensuelle, valeur réelle affichée vs à l'unité (§2.6) |
| Mur des soutiens (tip jar) | 99 / 499 / 999 R$ | Don volontaire unique, nom gravé sur le mur d'accueil (§2.6) |
| Bonus Roblox Premium natifs | gratuit (pour eux) | Cadeau quotidien membres Premium Roblox — reversement Roblox (§2.6) |

### 2.2 FOMO léger

- **Boutique rotative** : 1 œuf limité/semaine (thème, timer visible, jamais réédité à l'identique) + créature exclusive saisonnière 2 semaines (bible §5)
- Timers informatifs, jamais menaçants ; modal d'offre max 1×/session

### 2.3 Sinks ajoutés

- Reroll de mutation (objet Essence), fusion d'œufs (3 communs → 1 supérieur), décor de sanctuaire (Essence ET Robux cosmétique)
- `MARKET_MAX_PRICE` relevé (50 k devient trop bas avec les hauts rangs)

### 2.4 Validation obligatoire

- Extension `tools/EconomySim.luau` : simuler F2P / Starter seul / whale léger sur 14 jours ×3 runs avec le panier complet (multiplicateurs empilés §5 inclus, plafond global borné)
- **Aucun prix ni multiplicateur codé avant la sim.**

### 2.5 VIP Pass & Zone VIP

**Modèle — Pass 30 jours (~399 R$, prix validé par sim avant code)** :

- Dev product ; achat → `VipExpiresAt = max(maintenant, expiration actuelle) + 30 j` — les achats s'empilent
- Timer d'expiration visible en boutique (« encore 12 j ») — FOMO léger informatif, jamais menaçant
- À l'expiration : perte de l'accès zone/œuf/coffre ; **tout ce qui a été gagné est conservé** (cosmétiques, titres, créatures écloses)
- Bonus pendant le pass : ×1,25 chance (déjà câblé via `VIP_LUCK_BONUS`), tag doré, aura

**Remise VIP — vrais prix soldés −10 % en Robux** :

- Les prix dev products sont fixes et identiques pour tous (aucune API de prix par joueur) → chaque consommable vedette existe en **deux SKUs** : standard + « VIP » soldé −10 % (potions 49/149 R$ → 44/134 R$, Server Boost 99 → 89 R$, packs Essence −10 %). La boutique affiche les SKUs standards aux non-VIP (badge « −10 % avec le Pass VIP ») et les SKU soldés aux VIP
- Périmètre strict : ce qui se rachète en boucle uniquement — potions, Server Boost, packs Essence. Jamais les gamepasses permanents (double passe = conflit), jamais le mur des soutiens ni les cosmétiques unitaires
- Fuite connue et acceptée : `PromptProductPurchase` est appelable côté client (doc officielle) — un non-VIP qui découvre l'ID d'un SKU soldé peut l'acheter lui-même ; il paie des Robux réels pour le même produit, perte marginale bornée aux exploitants
- Boucle voulue : la remise rend le pass rentable pour qui dépense déjà → le pass multiplie les achats au lieu d'être un achat unique et figé

**Zone VIP — îlot flottant de luxe, contraste volontaire avec l'île crépusculaire sombre : or poli, marbre, néons chauds, tapis doré depuis le portail, statues de créatures légendaires, aura de particules — scintillante et visible depuis le sol ; accès par portail doré, barrière validée serveur (jamais client)** :

1. **Coffre journalier** — le cadeau quotidien devient un coffre physique à ouvrir dans la zone : Essence + potion chance courte + petit drop aléatoire. 1×/jour calendaire (réutilise `VipGiftDate`)
2. **Œuf VIP** — mêmes espèces que le jeu (pool des meilleurs œufs accessibles), taux ~×1,5 sur Rare+, prix Essence élevé. On vend de la chance, **zéro espèce exclusive** — les exclusives restent l'apanage du Season Premium (règle bible : F2P fait 100 % du contenu)
3. **Statut** — piédestal d'aura, déco sanctuaire exclusive, titre « VIP »

Le non-VIP voit la zone depuis le sol (levier bible §7 « le statut se regarde ») avec panneau listant le contenu.

Code impacté : `Shared/Vip.luau` (pur : `IsActive`, `Extend`, testable), champ `VipExpiresAt` (migration v7), gate téléporteur + coffre dans un `VipService`, SKUs VIP soldés dans `Config.DEV_PRODUCTS` + routage receipts existant étendu.

### 2.6 Monétisation honnête — ajouts

- **Cosmétiques purs** : skins/recolors de créatures, effets de particules, déco sanctuaire. Zéro impact gameplay — pipeline `DecorTemplates`. Rotation hebdo alignée FOMO léger (§2.2)
- **Rename ticket** : renommer une créature, 49 R$ — micro-achat cosmétique, attachement émotionnel à la bête
- **Bundle mensuel thématique** : ~499 R$, valeur réelle affichée vs à l'unité, rotation mensuelle (live ops post-lancement)
- **Bonus Roblox Premium natifs** : petit cadeau quotidien aux membres Premium Roblox (`PlayerMembershipType`, check serveur mis en cache) — Roblox reverse sur leur engagement, le joueur ne paie pas deux fois
- **Mur des soutiens** : 3 paliers de don uniques (99 / 499 / 999 R$), nom gravé en permanence sur le vrai mur de la zone d'accueil (plateau de spawn existant, visible par tous — pas une zone séparée). Pur statut social, honnêteté totale

Garde-fous anti-« prise pour des cons » : taux de drop publiés partout · jamais de faux soldes · timers informatifs jamais menaçants · tout ce qui est gagné est conservé à l'expiration des passes · jamais deux paywalls différents derrière la même exclusive gameplay · micro-prix réservés aux cosmétiques, jamais à la découpe de consommables (bible §7).

---

## 3. Vivant à toutes les échelles de population

Principe : **jamais de faux joueurs** (ToS + détection). Des données globales réelles rendues visibles.

### 3.A Densité avant volume

- **MaxPlayers 12-16** (pas 30+) → Roblox remplit les serveurs existants avant d'en ouvrir ; 8/12 paraît plein, 8/40 mort
- Sanctuaires visibles les uns des autres (déjà le cas géographiquement) → les créatures qui suivent leurs maîtres = preuve de vie gratuite

### 3.B Quand il y a peu de joueurs (cold start)

1. **Ticker de drops GLOBAL** : drops Rare+ de tous les serveurs agrégés via MessagingService (pattern LeaderboardService existant) → un joueur solo voit défiler l'activité mondiale réelle
2. **Compteurs mondiaux vivants** : « X œufs éclos cette semaine » (DataStore agrégé) en haut du menu
3. **Créatures sauvages PNJ** dans la zone publique : bestioles qui errent et farment visiblement — animation permanente sans prétendre être des joueurs
4. **Marché cross-serveur** (refonte nécessaire : `MarketService.listings` est aujourd'hui local au serveur) : listings persistés DataStore + propagation MessagingService → marché crédible même sur serveur vide
5. **Éclipse sur horloge serveur** → rendez-vous fixe toutes les 2 h même à 1 joueur

### 3.C Quand il y a beaucoup de joueurs

- Ticker throttlé (~10/min max, priorité aux hauts rangs) ; UltraRare+ plein écran, Épic en ticker seulement
- Server Boost : jauge partagée qui monte quand quelqu'un paie → effet boule de neige
- Duels/marché/visites s'activent naturellement avec la densité

### 3.D Boucles anti-solitude (existantes, conservées)

Streak quotidien, quêtes journalières, pity counter, season pass — raisons de revenir indépendantes du social.

Conséquence lancement : **peu de serveurs denses** (soft launch restreint, amis remplissant les premiers serveurs) avant d'élargir.

---

## 4. UI/UX (mobile-first)

### 4.A Hiérarchie refondue

- **Barre d'action permanente en bas** : Œufs · Faille · Sanctuaire — les 3 gestes du jeu, jamais à chercher
- Onglets avancés (Marché, Duels, Index, Quêtes, Saison, Renaissance, Boutique) derrière un bouton « Plus »
- Fix connu : re-layout dynamique au redimensionnement du viewport
- Audit Device Simulator complet : safe areas, TextScaled, cibles tactiles ≥ 44 px

### 4.B Boucle visuelle de récompense

- Ticker global (§3.B) coin haut-droit, toujours vivant
- Pyramide de célébration : Épic = burst + son · Légendaire+ = slow-mo cinématique (existe) · UltraRare+ = plein écran + annonce serveur
- Jauges visibles : pity (existe), jauge Éclipse, jauge Server Boost

### 4.C Boutique dédiée

- Onglet unique : potions, packs, Pass VIP (avec timer d'expiration), Server Boost, rename, cosmétiques, bundle mensuel, offres à timer — prix clairs, valeur affichée

### 4.D Amis

- Bouton **« Rejoindre un ami »** : amis en ligne dans le jeu → téléport direct vers leur serveur (`TeleportService`)
- Toast « PlayerX (ami) a rejoint » + raccourci visite de sanctuaire depuis la liste d'amis

---

## 5. Social — bonus de groupe et de meute

### 5.A Groupe Roblox officiel

- Check `IsInGroup` au join (côté serveur, mis en cache) :
  - **+10 % Essence permanent**, tag coloré au-dessus du pseudo
  - **1 œuf commun gratuit/jour** réservé aux membres
- Le groupe = canal d'annonces updates/événements (boucle rétention gratuite)
- Norme acceptée du genre à +10 %, jamais perçue comme agressive

### 5.B Bonus meute (amis stackés)

- **+10 % Essence par ami actif dans le serveur, cap ×3** (+30 % max) — anti ferme de comptes, F2P compétitif
- Jauge visible près du pseudo (« Meute ×2 ») → incite à inviter
- Synergie Server Boost : cumul boost + meute → moment « tout le monde gagne » clippable

Garde-fous : bonus jamais achetables, caps affichés, multiplicateurs entrent dans la sim (§2.4) avec **plafond global** (groupe + meute + boost + potion + VIP + session luck).

---

## 6. Lots d'exécution (~10 h/sem)

| Lot | Semaines | Contenu | Sortie |
|---|---|---|---|
| **1 · La chasse** | S1-2 | Œufs Épique/Légendaire + tables Mythic→Secret, potions chance + Server Boost + boutique v1, ticker global, marché cross-serveur | Jeu vendable, testable |
| **2 · Le moteur** | S3-4 | Arbre d'Étoiles, Éclipse, offres 1er achat/retour, VIP complet, instrumentation analytics | Rétention + mesure |
| **3 · L'écran** | S5 | Pass mobile-first complet, barre d'action, boutique dédiée, amis (rejoindre/toast/bonus meute), célébrations, fix resize | Jouable partout |
| **4 · Le monde** | S6-8 | Espèces 10→30 (pipeline IA), Monde 2 thématique + Mode Rush, mur VIP Secrets, mur des soutiens (accueil), cosmétiques + rename, PNJ sauvages, bonus groupe Roblox | Profondeur |
| **5 · Lancement** | S9-10 | Icône/thumbnails A/B, IDs produits réels, playtest fermé 20-30 joueurs, publication | Revenus |

Process transversal à chaque lot : extension EconomySim avant tout prix/courbe · tests unitaires étendus · playtest MCP bout en bout · commit.

Live ops post-lancement : hebdo = œuf rotatif + wave espèces + balance (data-driven) · bi-hebdo = mini-événement (variante Éclipse) · mensuel = monde ou grosse feature · revue métriques chaque semaine.

---

## 7. Analytics (instrumentation dès le Lot 2)

`AnalyticsService`, events custom :

- `hatch(rarity, mutation, source)` · `rift_complete(win, duration)` · `purchase(productId, price)` · `market_sale(price)`
- Funnel : temps jusqu'au 1er œuf / 1er drop Rare+ / 1er achat
- Cohortes D1/D7/D30, ARPDAU, temps avant premier achat — revue hebdomadaire, décisions data

Checklist plan P4 « métriques instrumentées dès P1 » : rattrapée ici.

---

## 8. Risques techniques suivis

| Risque | Mitigation |
|---|---|
| Marché cross-serveur : cohérence DataStore/MessagingService (ordering, rate limits) | Listings propriétaire = DataStore unique source de vérité, Messaging = notification only, throttling ticker |
| Multiplicateurs empilés (groupe+meute+boost+potion+VIP+luck) inflation | Plafond global borné, validé en sim avant code, caps affichés |
| Cache require Rojo après sync module requis en Edit | Tests en VM fraîche (play) ou run fantôme (procédure connue) |
| Cadence live ops intenable | Tout data-driven : œufs rotatifs/répliques/tables = fichiers de config, pas de code |

---

## 9. Tâches humaines (notes/listes fournies par l'IA)

- Créer le groupe Roblox officiel
- Créer les gamepasses/dev products (liste exacte noms + prix fournie au Lot 1) et renseigner les IDs dans `Config.luau`
- Icône + thumbnails A/B (Lot 5)
- Discord ouvert avant sortie
- Recrutement playtest fermé 20-30 adultes (Discord/Reddit)

## 10. En suspens (validés par sim/décision ultérieure)

- Prix finaux œufs Épique/Légendaire, potions, bundles, Pass VIP 30 j, bundle mensuel (sim §2.4)
- Valeurs chiffrées des 12 nœuds d'Arbre d'Étoiles (sim)
- Objectifs Mode Rush précis par monde (avec la carte des mondes, Lot 4)
- Nom définitif du jeu (RIFT BEASTS provisoire)
- Chemin d'obtention du Secret (décidé tard, jamais documenté)
