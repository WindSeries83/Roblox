# RIFT BEASTS — Bible de design

> Jeu Roblox de collection de créatures, orienté idle/optimisation, ciblant le public adulte.
> **Document unique** — le *quoi* et le *comment*. Dernière révision : 23/08/2026.
> Consolide les specs antérieures (18–23/08) et remplace le plan de production — source unique du design.

---

## 0. Décisions actées

| Sujet | Décision |
|---|---|
| Plateforme | **Roblox** (Steam écarté) |
| Genre | Collection de créatures + idle/AFK + optimisation |
| Cible | Adultes (18+), joueurs à pouvoir d'achat ; les mineurs doivent rester jouables sans être ciblés |
| Direction artistique | Low poly stylisé, crépuscule nocturne, **pas** de pastel enfantin |
| Multijoueur | Serveurs partagés, sanctuaires visitables, trading |
| Objectif n°1 | **Revenus** — donner envie, jamais forcer |
| Rythme | Rush fort = mondes + renaissance en quelques heures ; Index = très long |
| Statut | P4/P5 — social & monétisation implémentés, pré-lancement |
| Positionnement | **Hybride** — surface « brain rot » virale (dopamine rapide, drops visibles, moments clippables) sur cœur profond (élevage, index, mutations). La cible adulte reste servie par la profondeur |
| Ton | Humour en surface, data-driven (répliques absurdes) ; fond crépuscule/mystère inchangé |
| Monétisation | **Aggressive soft** — potions, Server Boost social, offres timées, VIP Pass, FOMO léger informatif. Jamais de paywall, jamais de compteur agressif |
| FTUE | « Le monde d'abord » — boucle complète vécue en < 5 min sans tutoriel lu |
| Population | Vivante garantie à toute échelle : jamais de faux joueurs, données globales réelles rendues visibles |
| Cadence | ~10 h/semaine → hebdo léger data-driven + un gros chantier mensuel |

---

## 1. Pitch

Tu es un Dompteur. Tes créatures farment de l'Essence dans ton sanctuaire pendant que tu fais autre chose. Toi, tu ouvres des Failles pour ramener des œufs, des reliques et des mutations, tu croises tes lignées pour fabriquer la créature parfaite, et tu recommences à zéro quand tu plafonnes — en plus fort.

**Phrase de positionnement :** *un jeu de collection qui respecte ton temps.*

**Le contrat avec le joueur :**
- Le rusher peut tout finir (mondes + renaissance) en **quelques heures** s'il joue fort.
- Le joueur tranquille peut tout obtenir en y allant à son rythme, sans punition.
- Personne n'est jamais perdu : le jeu dit toujours quoi faire ensuite.
- L'écran est vivant : tes créatures font des choses, partout, visiblement.

---

## 2. Boucle de jeu

1. **Sanctuaire (AFK)** — Zone du joueur, les créatures génèrent de l'Essence en continu. Rendement réduit hors ligne.
2. **Faille (action, 2–4 min)** — portail toutes les ~3-4 min. Combat simple contre gardiens + cristal. Drop : œufs, reliques, éclats de mutation.
3. **Éclosion / fusion** — dépense d'Essence, tirage rareté × mutation.
4. **Élevage** — croisement de deux créatures, héritage des mutations.
5. **Optimisation** — équipement, arbre de compétence, évolution, remplacement des vieilles créatures.
6. **Renaissance** au plafond — nouveau monde, nouveau Mode Rush, plus d'Étoiles.

**Ratio cible : 80 % passif / 20 % actif.**

Règles absolues :
- L'action ne doit **jamais** être obligatoire pour progresser. Elle multiplie. Le joueur y va parce que c'est rentable, pas parce qu'il est puni s'il n'y va pas.
- Le joueur qui ne dépense pas de sous ne doit **en aucun cas** se sentir inutile face à ceux qui paient : le F2P fait tout le contenu, il va juste plus lentement sur le haut de la courbe.

---

## 3. Systèmes

### 3.1 Rareté (axe 1)
`Commun (blanc) → Peu commun (vert) → Rare (bleu foncé) → Épique (violet) → Légendaire (doré) → Mythique (turquoise) → ULTRA RARE (rouge bordeaux et noir) → Secret (rose)`

- Ultra Rare ≈ 1/250 000 000 → **annonce sur tout le serveur** avec le pseudo.
- Secret : non documenté, drop spécifique qui sort du gameplay commun, découvert par la communauté.
- La rareté doit être **lisible visuellement** : taille, aura, particules, lévitation. Jamais besoin de lire le nom.
- **Les taux de drop sont affichés partout** (dans l'UI d'éclosion, de faille, d'élevage). C'est une condition de confiance **et** un déclencheur d'achat : voir 1/250 M en face, c'est ce qui donne envie d'acheter de la chance.

**Secrets — mur VIP :**
- La liste publique des détenteurs d'une créature Secret est affichée (mur VIP, pseudo + créature).
- Le procédé d'obtention n'est documenté nulle part, ni dans le jeu, ni par nous.
- Aucun partage dans le jeu : le détenteur garde l'astuce, la partage gratuitement, ou l'échange (info contre info) sur Discord. C'est la communauté qui fabrique le lore.

### 3.2 Mutations (axe 2, indépendant)
`Ombre ×2 · Givre ×5 · Doré ×15 · Prismatique ×50 · Corrompu ×200 · Céleste ×1000`

- Multiplicatif avec la rareté → deux chasses parallèles.
- Une Mythique Céleste ≠ une Ultra Rare normale. C'est ce qui fait rouvrir un œuf déjà obtenu.
- **Système le plus rentable du jeu** : c'est là que se vend la chance.

### 3.3 Élevage génétique — différenciateur n°1
- Croisement de deux créatures → descendance héritant des mutations parentales selon probabilités.
- Chance de mutation nouvelle à chaque génération.
- **Version adulte assumée** : pourcentages visibles, arbres généalogiques, stats détaillées, export des données.
- Objectif : que la communauté fasse ses propres tableurs et les partage. Marketing gratuit + signal de profondeur.
- Effet de marché : on n'achète plus une créature, on achète un **reproducteur**.

### 3.4 Objets équipables
Slots par créature : 1 au départ, +1 par palier d'évolution.

| Objet | Effet |
|---|---|
| Cœurs | XP / niveau max augmenté |
| Colliers | Chance de mutation à l'éclosion |
| Reliques | Débloquent l'évolution finale — **drop uniquement en Faille** |

> Les Reliques sont la carotte qui justifie l'action. Ne pas les rendre achetables.

### 3.5 Évolution partout
Créatures (4 stades) · Reliques (fusion 3→1) · Sanctuaire (capacité, vitesse, slots d'équipe) · Arbre de compétence · Rang joueur · Paliers d'Index.

### 3.6 Index / Bestiaire
Présenté comme un **Pokédex** : TOUTES les espèces du jeu sont listées depuis la table Species (modulaire — toute future espèce apparaît seule) avec 3 états : **Possédée** (portrait couleur + compteur), **Découverte non possédée** (portrait couleur + badge), **Inconnue** (silhouette sombre + « ??? », nom masqué). Filtres par famille ; bonus famille affiché quand complétée.

Ce n'est **pas** une collection cosmétique — c'est la source des bonus permanents et **le contenu de fin de jeu**.

- Chaque espèce enregistrée = petit bonus global.
- Famille complétée = gros bonus (chance, vitesse de farm, slot).
- Une entrée par combinaison **rareté × mutation** → index quasi infini.
- **L'Index survit à la Renaissance.** C'est ce qui rend le reset acceptable.
- **C'est par l'Index que le jeu est « infini »** : les mondes se finissent en quelques heures, mais compléter l'Index prend des dizaines d'heures — c'est le curseur entre joueur pressé et collectionneur.

### 3.7 Arbre de compétence du joueur
3 branches, points gagnés à chaque renaissance, **permanent** (survit à la renaissance). Présentation en **graphe visuel** : nœuds reliés entre eux, tronc commun puis branches Farm / Faille / Économie, avec prérequis entre nœuds (un nœud exige le rang ≥ 1 d'un nœud parent) ; les gains/valeurs seront approfondis plus tard (déjà couvert par §10).

- **+1 point par renaissance** (bonus de points si performance : renaissance rapide).
- L'Index récompense la collection ; **l'arbre récompense le style de jeu**. On peut tout débloquer en jouant — rien n'y est à vendre.

| Branche | Effets typiques |
|---|---|
| **Farm** | Taux d'Essence, gain AFK, capacité hors ligne, auto-récolte |
| **Faille** | Dégâts, chance de drop, reliques |
| **Économie** | Frais de marché réduits, mises de duel, XP season, bonus de revente |

### 3.8 Renaissance & Mondes
- Perte : Essence, améliorations de sanctuaire.
- Conservation : Index, reliques légendaires, objets multiplicateurs, créatures, **arbre de compétence**.
- Gain : **Étoiles** = multiplicateur permanent + déblocage du monde suivant.
- **Chaque renaissance débloque un monde** : une zone propre (sanctuaire + faille + quêtes) **et un Mode Rush**.
- **Mondes = thèmes, pas nouvelles cartes** : Monde N+1 = même île recolorée via `DecorTemplates`, multiplicateurs ×N, espèces exclusives. Mode Rush : objectif chronométré simple par monde (ex. « faille < 90 s »), récompense unique + bonus Index.

**Mode Rush** — le défi chronométré de chaque monde :
- Objectif propre au monde (ex. « terminer la faille en moins de 2 min », « 3 éclosions d'affilée »).
- Récompense : créature/relique/insigne liée au monde + bonus d'Index.
- C'est le terrain des rushers : un but clair, chrono visible, rejouable.

**Rythme cible (courbe P3) :** Renaissance 1 ≈ 15 min · 2 ≈ 35 min · 3 ≈ 1 h 15 · 4 ≈ 3 h. En rushant fort, les 4 mondes + la 4ᵉ renaissance se finissent en **une session de quelques heures**. Ensuite : l'Index.

### 3.9 Duel de sanctuaires — différenciateur n°2
Version adulte du raid : **consentie et avec mise**.

- Les deux joueurs acceptent, misent quelque chose, le gagnant prend.
- **Résolution : sim statique serveur** — score attaquant = Σ power de l'équipe déployée, défense = Σ power des créatures non déployées du défenseur, ratio + petit aléa seedé. Zéro combat temps réel, logique pure testable.
- Mise en escrow ; remboursement sur refus ou timeout 60 s.
- Les créatures non déployées défendent → arbitrage réel : partir en Faille avec sa meilleure équipe, ou la laisser garder la maison.
- **Jamais de vol subi par un joueur hors ligne.** Un adulte qui a investi 40 h ne le tolère pas.

### 3.10 Trading
Indispensable. C'est ce qui donne de la valeur aux drops rares, donc ce qui justifie l'achat de chance.
Prévoir : place de marché, historique des échanges, protection anti-arnaque (double confirmation, délai).
Être à un niveau renaissance suffisant avant le trading pour éviter le step up de nouveau joueur.

**Règles marché (actées) :**
- Listings en **Essence uniquement** — pas de Robux joueur↔joueur (ToS).
- Frais de vente 5 %, cap de listings par joueur, retrait avec double confirmation + délai 60 s.
- Transferts atomiques (`EssenceService:Spend/Add` + move créature) ; achat refusé au cap → vendeur intact.
- Marché cross-serveur visé : listings persistés DataStore + propagation MessagingService → marché crédible même sur serveur vide.

### 3.11 Œufs & chasse haut de gamme
- Les premiers paliers d'œufs plafonnent à Rare : **Œuf Épique** (~2 000 Essence) et **Œuf Légendaire** (~8 000 Essence) ouvrent la chasse haut de gamme, prix finaux validés par sim.
- Chaque palier peut dropper au-dessus avec de faibles poids → l'espoir à chaque éclosion.
- **La Faille = source exclusive des hauts rangs** : Mythique / UltraRare / Secret ne tombent que via faille (+ mutations). Prix indicatifs validés par sim avant code.

### 3.12 Espèces & live ops de contenu
- Vague 10 → 30 espèces via le pipeline IA low-poly éprouvé, données pures dans `Species.luau` (famille, rôle, taux, puissance).
- Post-lancement : +3-5 espèces/semaine par le même pipeline — cadence tenable.

### 3.13 Arbre d'Étoiles
Version pragmatique de l'arbre de compétence (§3.7) : +1 point par renaissance, grille d'environ **12 nœuds permanents**, 3 branches Farm / Faille / Économie. Même présentation en **graphe visuel** (nœuds reliés, tronc commun, branches Farm/Faille) avec prérequis entre nœuds (rang ≥ 1 du nœud parent) ; les gains/valeurs seront approfondis plus tard (déjà couvert par §10). Data-driven (`Shared/SkillTree.luau`). **Rien n'y est vendable.**

### 3.14 FTUE — « Le monde d'abord »
Problème racine acté : la boucle est complète mais l'abandon se joue dans les 5 premières minutes (monde mort, jeu de menus, pas de direction).

Séquence cible :
- **T+0 s** — Naissance dans un monde vivant : spawn sans panneau bloquant, œuf dans un nid près du spawn, prompt contextuel unique (« Approche-toi de l'œuf »).
- **T+10 s** — Première éclosion spectaculaire : cinématique courte (tremblement, lumière, craquement), créature qui suit le joueur. Pity `FIRST_HATCH_WEIGHTS` conservé. Première récompense < 15 s.
- **T+20 s** — Le farm devient visible sous les yeux (creuse/ramasse/patrouille selon rôle), « +N Essence » flottant. Zéro menu ouvert jusque-là.
- **T+60-90 s** — Première faille accélérée pour les nouveaux (`FIRST_RIFT_DELAY`), cadence normale ensuite ; combat juteux, victoire → récompenses ×8.
- **T+2-3 min** — Les menus arrivent en dernier : tutoriel 6 étapes d'UI remplacé par 3 prompts monde + auto-ouverture unique onglet Œufs. L'expert peut tout ignorer.

**Critère d'acceptation :** un nouveau joueur voit sa créature travailler, éclot 1-2 œufs en monde, gagne une faille et sait quoi faire ensuite — sans jamais lire un tutoriel, en moins de 5 minutes.

Pincée active (sans casser le ratio 80/20) :
- **Orbes d'Essence ambiantes** ~toutes les 45 s, cliquables, plafond serveur strict — jamais obligatoires, toujours rentables.
- Clics créatures amplifiés : combo visuel + easter egg cosmétique après 10 clics, gain économique nul.
- Tout gain cliquable attribué côté serveur, rate-limité, plafonné par joueur.

### 3.15 Vivant à toutes les échelles de population
Principe : **jamais de faux joueurs** (ToS + détection). Des données globales réelles rendues visibles.

- **Densité avant volume** : MaxPlayers 12-16 — Roblox remplit les serveurs existants avant d'en ouvrir ; sanctuaires visibles les uns des autres.
- **Quand il y a peu de joueurs** : ticker de drops global (Rare+ agrégé MessagingService, pattern LeaderboardService), compteurs mondiaux (« X œufs éclos cette semaine »), créatures sauvages PNJ qui farment visiblement, marché cross-serveur, Éclipse sur horloge serveur.
- **Quand il y en a beaucoup** : ticker throttlé (~10/min max, priorité hauts rangs), UltraRare+ plein écran, Server Boost en jauge partagée, duels/marché/visites s'activent naturellement.
- Boucles anti-solitude conservées : streak quotidien, quêtes journalières, pity counter, season pass.
- Conséquence lancement : peu de serveurs denses (soft launch restreint, amis remplissant les premiers serveurs) avant d'élargir.

---

## 4. Game feel, UI & social

**L'écran est vivant.** Le joueur doit ressentir le jeu, pas le lire.

- **Hover partout** : survoler une créature (la sienne, celle d'un autre joueur, une espèce d'Index) affiche ses infos — espèce, rareté, mutation, stats, valeur marché. Les gens sont curieux : la curiosité est le moteur de découverte.
- **Les créatures font des choses, visiblement :**
  - Elles **suivent le joueur** quand il se déplace (dans le sanctuaire, en Faille).
  - Le farm AFK est **visible** : le Farmeur déterre des pépites, le Cueilleur ramasse autour du sanctuaire, le Gardien patrouille. Le joueur voit *pourquoi* il gagne.
  - En Faille : animations d'attaque et d'impact, pas juste des nombres.
- **Guidage anti-perte :**
  - Quêtes qui pointent vers la prochaine action utile (acheter un œuf, éclore, équiper, ouvrir une faille).
  - Badge « prochaine étape » sur l'onglet concerné.
  - Jamais deux objectifs contradictoires à l'écran.
  - Un nouveau joueur sait quoi faire à chaque instant ; un expert peut tout ignorer.
- **Sensation de jeu maximale, pour le plus de joueurs possible :**
  - Sons à chaque moment clé (éclosion, drop rare, upgrade, faille, rebirth).
  - Le drop Ultra Rare est un moment clippable (ralenti + son + annonce serveur).
  - Options de confort : vitesse d'UI, densité d'info (UI dense par défaut, sans infantilisation).

### 4.A Hubs dans le monde & pouvoir visible
- **Couveuse = LE hub d'éclosion** : objet 3D dans l'enclos. Les œufs achetés/gagnés vont dans l'inventaire ; le joueur les **place physiquement** autour de la couveuse (max 3 posés) ; chaque œuf posé porte un prompt « Éclore » in-world. L'éclosion déclenche une **cinématique dans le monde** ET une **carte de révélation** lisible (portrait de la créature + nom + rareté, visible ≥ 4 s). Le gamepass AutoHatch place et éclore automatiquement.
- **Arche de faille permanente** construite au démarrage serveur : brille quand la faille est active, compte à rebours « Faille dans X:XX ». Rythme inchangé (`RIFT_INTERVAL = 600`, actif 180 s).
- **Créatures cliquables** : panneau contextuel équiper / évoluer / vendre avec prix suggéré pré-rempli modifiable (passe par `MarketList`).
- **Feedbacks** : `Fx.FloatText` (+N Essence au tick), saut + burst au clic.
- **ObjectiveBanner** (bandeau bas d'écran) : priorité faille active > quêtes prêtes > premier œuf > Renaissance, + état « teasing » vers le contenu verrouillé le plus proche.
- **Pouvoir visible** : taille/aura des créatures étendues au niveau, socles physiques par +2 emplacements de sanctuaire, puissance d'équipe en topbar, renaissance cinématique avec bascule immédiate du thème du nouveau monde.

### 4.B UI mobile-first
- **Barre d'action permanente en bas** : Œufs · Faille · Sanctuaire — les 3 gestes du jeu, jamais à chercher.
- Onglets avancés (Marché, Duels, Index, Quêtes, Saison, Renaissance, Boutique) derrière un bouton « Plus ».
- Fix connu : re-layout dynamique au redimensionnement du viewport ; audit Device Simulator complet (safe areas, TextScaled, cibles tactiles ≥ 44 px).
- **Boucle visuelle de récompense** : ticker global coin haut-droit, pyramide de célébration (Épic = burst + son · Légendaire+ = slow-mo · UltraRare+ = plein écran + annonce), jauges visibles (pity, Éclipse, Server Boost).
- **Boutique dédiée** : onglet unique — potions, packs, Pass VIP (avec timer d'expiration), Server Boost, rename, cosmétiques, bundle mensuel, offres à timer — prix clairs, valeur affichée.
- **Amis** : bouton « Rejoindre un ami » (téléport direct `TeleportService`), toast « X (ami) a rejoint », raccourci visite de sanctuaire depuis la liste d'amis.
- **Fermeture du menu** : bouton ✕ sur le panneau, re-clic sur le bouton de la barre d'action (toggle), touche B (manette) / Échap.
- **HUD permanent des possessions** sur l'écran de base : créatures n/max, étoiles de renaissance, points d'Arbre d'Étoiles non dépensés (badge cliquable), quêtes prêtes.

### 4.C Social — bonus de groupe et de meute
- **Groupe Roblox officiel** (check `IsInGroup` serveur mis en cache) : +10 % Essence permanent, tag coloré, 1 œuf commun gratuit/jour. Canal d'annonces updates/événements.
- **Bonus meute** : +10 % Essence par ami actif dans le serveur, cap ×3 (+30 % max) — anti ferme de comptes, F2P compétitif. Jauge visible près du pseudo (« Meute ×2 »).
- Garde-fous : bonus jamais achetables, caps affichés, multiplicateurs entrent dans la sim avec **plafond global borné** (groupe + meute + boost + potion + VIP + session luck).

---

## 5. Maps

| Zone | Rôle |
|---|---|
| **Sanctuaires** (3–4, un par monde débloqué par Renaissance) | AFK, rendement stable, safe |
| **????** (zone publique, débloquée par Renaissance) | AFK, rendement aléatoire, risqué (mais aucune perte) |
| **Failles** | Pas de revenu passif dedans, mais ×8 sur les drops → choix actif de sacrifier l'AFK |
| **Éclipse** | Évènement serveur toutes les 2 h, 10 min : ciel modifié, annonce serveur, mutation boostée ×10, créature exclusive — horloge serveur, **jamais conditionnée à la population** (réutilise les patterns OrbService/RiftService) |
| **Zone saisonnière** | 2 semaines, créature exclusive jamais rééditée → pic de revenus et de retours |

---

## 6. Cible & positionnement

**Données (Roblox, mars 2026, utilisateurs vérifiés) :** 36 % ont moins de 13 ans, 38 % ont 13–17 ans, **26 % sont majeurs**. Le segment 18+ croît de plus de 50 % par an et dépense ~40 % de plus par session. Sur ~132 M de joueurs quotidiens, l'audience adulte se compte en dizaines de millions.

**L'opportunité :** quasiment personne ne conçoit pour eux dans ce genre. Les collectionneurs de créatures sont tous calibrés pour des enfants de 10 ans.

**Ce que veut la cible :**
- De la profondeur et de l'optimisation (tableurs, méta, min-max)
- Un jeu qui tourne pendant qu'ils bossent — l'AFK est un argument, pas un compromis
- Une économie crédible : *est-ce que ma créature rare vaudra encore quelque chose dans 6 mois ?*
- Aucune perte de progression subie
- Une UI dense et propre, pas un tutoriel infantilisant
- Du statut : montrer ce qu'on a (les créatures visibles, le mur VIP des secrets, les classements)

**Contrainte incontournable :** on ne peut pas filtrer l'audience sur Roblox. Des mineurs joueront quand même. Le jeu doit rester sûr et jouable pour eux, même s'il ne les vise pas.

---

## 7. Monétisation

> **Objectif n°1 du jeu : les revenus.** Pas en forçant — en **donnant envie**. Le joueur doit avoir envie de payer *avant* que l'achat ne soit proposé.

**Principe : vendre du temps, du confort et de la chance. Jamais l'accès au contenu.**
Le F2P fait 100 % du contenu. Ce qu'on vend, c'est d'aller plus vite, plus confortablement, avec plus de chance — jamais de la progression bloquée.

### La gamme de produits (23/08 — prix indicatifs, validés par sim avant code)

| Produit | Prix | Rôle |
|---|---|---|
| Starter Pack | 149 R$ | Créature Rare mutée + 1 000 Essence + potion ×2 30 min. Seuil du classement léger (§8) |
| Potion Chance ×1,5 / 10 min | 49 R$ | Consommable vedette des jeux d'éclosion |
| Potion Chance ×2 / 30 min | 149 R$ | idem |
| Server Boost | 99 R$ | +50 % chance pour tout le serveur, 15 min, annoncé + jauge visible. Dépense sociale/statut, empilable jusqu'à un cap affiché |
| VIP Pass (30 j) | ~399 R$ | ×1,25 chance, tag doré, aura, prix soldés −10 % sur les consommables vedettes + Zone VIP de luxe (coffre journalier, œuf VIP, statut) — détail ci-dessous |
| Auto-Éclosion / +Slots / Rendement | 249 / 199 / 199 R$ | Confort (existants) |
| Offre 1er achat | −50 % une fois | Déclenchée après le 1er drop Épic+ OU au retour J2 |
| Offres de retour | J2/J7 | Cadeau + bundle temporaire |
| Packs Essence | — | Valve de confort |
| Season Premium | — | Existant : 20 niveaux, 2 pistes, créature exclusive CinderSeraph+Shadow au sommet premium, XP par éclosion/faille/rebirth/quêtes/élevage |
| Rename ticket | 49 R$ | Renommer une créature — cosmétique pur |
| Titres rotatifs | 49–99 R$ | Titres cosmétiques en rotation hebdo — statut pur, réutilise le système de titres existant |
| Cosmétiques purs | 49–199 R$ | Skins/recolors créatures, effets de particules, déco sanctuaire — zéro gameplay, rotation hebdo alignée FOMO léger |
| Bundle mensuel thématique | ~499 R$ | Rotation mensuelle, valeur réelle affichée vs à l'unité (live ops post-lancement) |
| Mur des soutiens (tip jar) | 99 / 499 / 999 R$ | Don volontaire unique, nom gravé en permanence sur le vrai mur de la zone d'accueil (plateau de spawn, visible par tous — pas une zone séparée). Pur statut social |
| Bonus Roblox Premium natifs | gratuit (pour eux) | Petit cadeau quotidien aux membres Premium Roblox (`PlayerMembershipType`, check serveur mis en cache) — reversement Roblox sur leur engagement |

FOMO léger : boutique rotative (1 œuf limité/semaine jamais réédité à l'identique, créature exclusive saisonnière 2 semaines), timers informatifs jamais menaçants, modal d'offre max 1×/session.
Sinks ajoutés : reroll de mutation (objet Essence), fusion d'œufs (3 communs → 1 supérieur), décor de sanctuaire (Essence ET Robux cosmétique), `MARKET_MAX_PRICE` relevé.

**Validation obligatoire :** extension `tools/EconomySim.luau` — simuler F2P / Starter seul / whale léger sur 14 jours ×3 runs avec le panier complet (multiplicateurs empilés inclus, plafond global borné). **Aucun prix ni multiplicateur codé avant la sim.**

### VIP Pass & Zone VIP

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
2. **Œuf VIP** — mêmes espèces que le jeu (pool des meilleurs œufs accessibles), taux ~×1,5 sur Rare+, prix Essence élevé. On vend de la chance, **zéro espèce exclusive** — les exclusives restent l'apanage du Season Premium (règle : F2P fait 100 % du contenu)
3. **Statut** — piédestal d'aura, déco sanctuaire exclusive, titre « VIP »

Le non-VIP voit la zone depuis le sol (levier « le statut se regarde ») avec panneau listant le contenu.

Code impacté : `Shared/Vip.luau` (pur : `IsActive`, `Extend`, testable), champ `VipExpiresAt` (migration v7), gate téléporteur + coffre dans un `VipService`, SKUs VIP soldés dans `Config.DEV_PRODUCTS` + routage receipts existant étendu.

Garde-fous anti-« prise pour des cons » : taux de drop publiés partout · jamais de faux soldes · timers informatifs jamais menaçants · tout ce qui est gagné est conservé à l'expiration des passes · jamais deux paywalls différents derrière la même exclusive gameplay · micro-prix réservés aux cosmétiques, jamais à la découpe de consommables.

Piste post-lancement : pub récompensée (AdService) → Essence uniquement, cap strict 2-3 vues/jour, jamais de potion ni d'objet premium en récompense (cannibalisation interdite). Décision sur données ARPDAU réelles.

### Ce qui ne marche pas
- Micro-consommables à 99 Robux → perçus comme de l'arnaque à la découpe
- Paywall de progression → départ définitif, pas de retour
- FOMO agressive → démolition en commentaires

### Les leviers qui donnent envie (et qui déclenchent la première dépense)
- **Taux de drop affichés partout** : voir la probabilité d'une Ultra Rare en face, c'est ce qui donne envie d'acheter de la chance.
- **Les créatures des autres joueurs sont visibles** (suivi, sanctuaires visitables, mur VIP) : le statut se regarde, et l'envie se copie.
- **Une économie crédible** : si ma créature vaut quelque chose sur le marché, acheter de la chance est un investissement, pas une dépense.

### Santé de l'économie
- Sinks de monnaie réels
- Pas d'inflation d'items limités (rééditions interdites)
- Taux de drop publiés publiquement — condition de confiance qui déclenche la première dépense
- Le F2P n'est jamais humilié : il joue la même partie, juste à son rythme

---

## 8. Classements

Deux classements pour deux ambitions, **un plafond de dépense clairement communiqué** :

- **Classement général** — tout le monde, quelle que soit la dépense. La cour des grands.
- **Classement « plafond léger »** — éligible si **dépense cumulée < prix du Starter Pack**.
  - Prendre le Starter Pack seul ne disqualifie pas ; tout achat **en plus** sort du classement léger.
  - Le plafond est **affiché explicitement** dans l'UI du classement (« Ce classement inclut les joueurs ayant dépensé moins que le Starter Pack ») — cette visibilité est un levier : les gros joueurs prennent au moins le Starter Pack pour rester honnêtes, et les F2P purs ont leur vitrine.
  - Les gros joueurs passent largement devant un joueur au Starter Pack seul : le classement léger récompense le temps et le talent, pas l'argent.

**Règles communes :** compteur unique `Stats.TotalEssenceEarned` (jamais remis à 0), refresh périodique (5 min) avec sync cross-serveur MessagingService, snapshot des sanctuaires visitables pour l'aperçu (top joueurs : niveau, créatures par rang, espèces phares).

---

## 9. Checklist design

- [ ] L'action n'est jamais obligatoire, seulement rentable
- [ ] Le F2P fait 100 % du contenu ; on vend du temps, du confort, de la chance
- [ ] Les taux de drop sont affichés partout
- [ ] Le rusher finit mondes + renaissance en quelques heures ; l'Index est le contenu long
- [ ] Le joueur tranquille n'est jamais puni
- [ ] Le joueur n'est jamais perdu : une prochaine étape visible à chaque instant
- [ ] L'écran est vivant : créatures qui suivent, agissent, et montrent leurs infos au hover
- [ ] La rareté est lisible sans lire de texte
- [ ] Le drop Ultra Rare est un moment clippable (ralenti + son + annonce serveur)
- [ ] L'Index survit à la Renaissance ; l'arbre de compétence aussi
- [ ] Les Reliques ne s'achètent pas
- [ ] Aucune perte de progression subie
- [ ] Pas de rééditions d'items limités
- [ ] Le classement plafond léger est affiché avec son plafond explicite
- [ ] Les Secrets : mur VIP des détenteurs, procédé non documenté, zéro partage in-game
- [ ] Le pass VIP conserve tout ce qui est gagné à l'expiration
- [ ] Jamais deux paywalls différents derrière la même exclusive gameplay
- [ ] Taux publiés avant tout code de prix (validation sim)

---

## 10. En suspens

- Nom définitif (RIFT BEASTS = provisoire, vérifier la disponibilité sur Roblox)
- Prix finaux œufs Épique/Légendaire, potions, bundles, Pass VIP 30 j, bundle mensuel (validation sim obligatoire)
- Valeurs chiffrées des 12 nœuds d'Arbre d'Étoiles (sim) ; répartition fine des points d'arbre de compétence
- Objectifs Mode Rush précis par monde (à boucler avec la carte des mondes)
- Activation pub récompensée (AdService) : décision post-lancement sur ARPDAU réel
- Chemin d'obtention du Secret (décidé tard, jamais documenté)
- Détail du seuil Starter Pack (prix final du pack → plafond du classement léger)
- Profondeur de la boucle de gameplay (à retravailler après le lot 3.5 — contenu mi-session, objectifs long terme)
- Valeurs des gains de l'Arbre d'Étoiles (sim avant code)

**Instrumentation analytics (dès le Lot 2 « moteur »)** : `AnalyticsService`, events custom — `hatch(rarity, mutation, source)` · `rift_complete(win, duration)` · `purchase(productId, price)` · `market_sale(price)` ; funnel temps jusqu'au 1er œuf / 1er drop Rare+ / 1er achat ; cohortes D1/D7/D30, ARPDAU, temps avant premier achat — revue hebdomadaire, décisions data.

---

## 11. Exécution — lots pré-lancement & suivi

| Lot | Semaines | Contenu | Sortie |
|---|---|---|---|
| **1 · La chasse** | S1-2 | Œufs Épique/Légendaire + tables Mythic→Secret, potions chance + Server Boost + boutique v1, ticker global, marché cross-serveur | Jeu vendable, testable |
| **2 · Le moteur** | S3-4 | Arbre d'Étoiles, Éclipse, offres 1er achat/retour, VIP complet (Pass + Zone), instrumentation analytics | Rétention + mesure |
| **3 · L'écran** | S5 | Pass mobile-first complet, barre d'action, boutique dédiée, amis (rejoindre/toast/bonus meute), célébrations, fix resize | Jouable partout |
| **3.5 · Le monde vivant** | S5+ | Correctifs playtest : menu refermable, éclosion 100 % dans le monde (placement couveuse), compagnon choisi + créatures autonomes animées, Index pokédex, Sanctuaire/Objectifs/Arbre lisibles, HUD possessions, eau terrain | Qualité perçue |
| **4 · Le monde** | S6-8 | Espèces 10→30 (pipeline IA), Monde 2 thématique + Mode Rush, mur VIP Secrets, mur des soutiens (accueil), cosmétiques + rename + titres, PNJ sauvages, bonus groupe Roblox | Profondeur |
| **5 · Lancement** | S9-10 | Icône/thumbnails A/B, IDs produits réels, playtest fermé 20-30 joueurs, publication | Revenus |

Process transversal à chaque lot : extension EconomySim avant tout prix/courbe · tests unitaires étendus · playtest MCP bout en bout · commit.

Live ops post-lancement : hebdo = œuf rotatif + wave espèces + balance (data-driven) · bi-hebdo = mini-événement (variante Éclipse) · mensuel = monde ou grosse feature · revue métriques chaque semaine.

### Risques techniques suivis

| Risque | Mitigation |
|---|---|
| Marché cross-serveur : cohérence DataStore/MessagingService (ordering, rate limits) | Listings propriétaire = DataStore unique source de vérité, Messaging = notification only, throttling ticker |
| Multiplicateurs empilés (groupe+meute+boost+potion+VIP+luck) inflation | Plafond global borné, validé en sim avant code, caps affichés |
| Cache require Rojo après sync module requis en Edit | Tests en VM fraîche (play) ou run fantôme (procédure connue) |
| Cadence live ops intenable | Tout data-driven : œufs rotatifs/répliques/tables = fichiers de config, pas de code |

### Tâches humaines

- Créer le groupe Roblox officiel
- Créer les gamepasses/dev products (liste exacte noms + prix fournie au Lot 1, incluant les SKUs VIP soldés) et renseigner les IDs dans `Config.luau`
- Icône + thumbnails A/B (Lot 5)
- Discord ouvert avant sortie
- Recrutement playtest fermé 20-30 adultes (Discord/Reddit)
