# RIFT BEASTS — Bible de design

> Jeu Roblox de collection de créatures, orienté idle/optimisation, ciblant le public adulte.
> **Document 1/2.** Le *quoi*. Voir `RIFT_BEASTS_2_plan_production.md` pour le *comment*.
> Dernière révision : 20/08/2026.

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
Ce n'est **pas** une collection cosmétique — c'est la source des bonus permanents et **le contenu de fin de jeu**.

- Chaque espèce enregistrée = petit bonus global.
- Famille complétée = gros bonus (chance, vitesse de farm, slot).
- Une entrée par combinaison **rareté × mutation** → index quasi infini.
- **L'Index survit à la Renaissance.** C'est ce qui rend le reset acceptable.
- **C'est par l'Index que le jeu est « infini »** : les mondes se finissent en quelques heures, mais compléter l'Index prend des dizaines d'heures — c'est le curseur entre joueur pressé et collectionneur.

### 3.7 Arbre de compétence du joueur
3 branches, points gagnés à chaque renaissance, **permanent** (survit à la renaissance).

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

**Mode Rush** — le défi chronométré de chaque monde :
- Objectif propre au monde (ex. « terminer la faille en moins de 2 min », « 3 éclosions d'affilée »).
- Récompense : créature/relique/insigne liée au monde + bonus d'Index.
- C'est le terrain des rushers : un but clair, chrono visible, rejouable.

**Rythme cible (courbe P3) :** Renaissance 1 ≈ 15 min · 2 ≈ 35 min · 3 ≈ 1 h 15 · 4 ≈ 3 h. En rushant fort, les 4 mondes + la 4ᵉ renaissance se finissent en **une session de quelques heures**. Ensuite : l'Index.

### 3.9 Duel de sanctuaires — différenciateur n°2
Version adulte du raid : **consentie et avec mise**.

- Les deux joueurs acceptent, misent quelque chose, le gagnant prend.
- Les créatures non déployées défendent → arbitrage réel : partir en Faille avec sa meilleure équipe, ou la laisser garder la maison.
- **Jamais de vol subi par un joueur hors ligne.** Un adulte qui a investi 40 h ne le tolère pas.

### 3.10 Trading
Indispensable. C'est ce qui donne de la valeur aux drops rares, donc ce qui justifie l'achat de chance.
Prévoir : place de marché, historique des échanges, protection anti-arnaque (double confirmation, délai).
Être à un niveau renaissance suffisant avant le trading pour éviter le step up de nouveau joueur.

---

## 4. Game feel & lisibilité

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

---

## 5. Maps

| Zone | Rôle |
|---|---|
| **Sanctuaires** (3–4, un par monde débloqué par Renaissance) | AFK, rendement stable, safe |
| **????** (zone publique, débloquée par Renaissance) | AFK, rendement aléatoire, risqué (mais aucune perte) |
| **Failles** | Pas de revenu passif dedans, mais ×8 sur les drops → choix actif de sacrifier l'AFK |
| **Éclipse** | Évènement serveur toutes les 2 h, 10 min, mutation exclusive |
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

### Les produits
- **Starter Pack** — le produit d'entrée. Donne une créature moyenne avec une bonne mutation définie (pas céleste) + un petit boost. *C'est aussi le seuil du classement léger (voir §8) : la majorité des joueurs qui s'engagent le prennent.*
- **Permanent / confort** : slots, automatisation, gestion en masse, filtres d'inventaire, second sanctuaire.
- **Gros packs bien valorisés** — un bundle à 2000 Robux qui débloque clairement quelque chose bat dix micro-achats.
- **Chance** : bonus de chance de session (augmente chaque heure connectée, pendant la session uniquement), multiplicateur de serveur temporaire.
- **Statut** : cosmétiques visibles, titres, sanctuaire décorable et visitable.
- **Season pass** (35–45 jours) — format connu et accepté, créature exclusive au sommet.

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

**Règles communes :** refresh périodique, snapshot des sanctuaires visitables, un seul compteur (Essence totale cumulée, jamais remise à 0).

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

---

## 10. En suspens

- Nom définitif (RIFT BEASTS = provisoire, vérifier la disponibilité sur Roblox)
- Répartition fine des points d'arbre de compétence (valeurs chiffrées, dans le plan de production)
- Contenu exact des Modes Rush par monde (objectifs et récompenses, à boucler avec la carte des mondes)
- Détail du seuil Starter Pack (prix final du pack → plafond du classement léger)
