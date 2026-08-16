# RIFT BEASTS — Bible de design

> Jeu Roblox de collection de créatures, orienté idle/optimisation, ciblant le public adulte.
> **Document 1/2.** Le *quoi*. Voir `RIFT_BEASTS_2_plan_production.md` pour le *comment*.

---

## 0. Décisions actées

| Sujet | Décision |
|---|---|
| Plateforme | **Roblox** (Steam écarté) |
| Genre | Collection de créatures + idle/AFK + optimisation |
| Cible | Adultes (18+), joueurs à pouvoir d'achat |
| Direction artistique | Low poly stylisé, palette sombre, **pas** de pastel enfantin |
| Multijoueur | Serveurs partagés, sanctuaires visitables, trading |
| Statut | Pré-production |

---

## 1. Pitch

Tu es un Dompteur. Tes créatures farment de l'Essence dans ton sanctuaire pendant que tu fais autre chose. Toi, tu ouvres des Failles pour ramener des œufs, des reliques et des mutations, tu croises tes lignées pour fabriquer la créature parfaite, et tu recommences à zéro quand tu plafonnes — en plus fort.

**Phrase de positionnement :** *un jeu de collection qui respecte ton temps.*

---

## 2. Boucle de jeu

1. **Sanctuaire (AFK)** — les créatures génèrent de l'Essence en continu. Rendement réduit hors ligne.
2. **Faille (action, 2–4 min)** — portail toutes les ~10–15 min. Combat simple contre gardiens + cristal. Drop : œufs, reliques, éclats de mutation.
3. **Éclosion / fusion** — dépense d'Essence, tirage rareté × mutation.
4. **Élevage** — croisement de deux créatures, héritage des mutations.
5. **Optimisation** — équipement, évolution, remplacement des vieilles créatures.
6. **Renaissance** au plafond.

**Ratio cible : 80 % passif / 20 % actif.**

Règle absolue : l'action ne doit **jamais** être obligatoire pour progresser. Elle multiplie. Le joueur y va parce que c'est rentable, pas parce qu'il est puni s'il n'y va pas.

---

## 3. Systèmes

### 3.1 Rareté (axe 1)
`Commun → Peu commun → Rare → Épique → Légendaire → Mythique → ULTRA RARE → Secret`

- Ultra Rare ≈ 1/250 000 → **annonce sur tout le serveur** avec le pseudo.
- Secret : non documenté, découvert par la communauté.
- La rareté doit être **lisible visuellement** : taille, aura, particules, lévitation. Jamais besoin de lire le nom.

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
Créatures (4 stades) · Reliques (fusion 3→1) · Sanctuaire (capacité, vitesse, slots d'équipe) · Rang joueur · Paliers d'Index.

### 3.6 Index / Bestiaire
Ce n'est **pas** une collection cosmétique — c'est la source des bonus permanents.

- Chaque espèce enregistrée = petit bonus global.
- Famille complétée = gros bonus (chance, vitesse de farm, slot).
- Une entrée par combinaison **rareté × mutation** → index quasi infini.
- **L'Index survit à la Renaissance.** C'est ce qui rend le reset acceptable.

### 3.7 Renaissance
- Perte : créatures, Essence, améliorations de sanctuaire.
- Conservation : Index, reliques légendaires.
- Gain : **Étoiles** = multiplicateur permanent + déblocage d'une zone / d'un tier de rareté par palier.
- Rythme : Renaissance 1 atteignable en **2–3 h**, puis courbe qui s'allonge.

### 3.8 Duel de sanctuaires — différenciateur n°2
Version adulte du raid : **consentie et avec mise**.

- Les deux joueurs acceptent, misent quelque chose, le gagnant prend.
- Les créatures non déployées défendent → arbitrage réel : partir en Faille avec sa meilleure équipe, ou la laisser garder la maison.
- **Jamais de vol subi par un joueur hors ligne.** Un adulte qui a investi 40 h ne le tolère pas.

### 3.9 Trading
Indispensable. C'est ce qui donne de la valeur aux drops rares, donc ce qui justifie l'achat de chance.
Prévoir : place de marché, historique des échanges, protection anti-arnaque (double confirmation, délai).

---

## 4. Maps

| Zone | Rôle |
|---|---|
| **Sanctuaires** (3–4, débloqués par Renaissance) | AFK, rendement stable, safe |
| **Failles** | Pas de revenu passif dedans, mais ×8 sur les drops → choix actif de sacrifier l'AFK |
| **Éclipse** | Évènement serveur toutes les 2 h, 10 min, mutation exclusive |
| **Zone saisonnière** | 2 semaines, créature exclusive jamais rééditée → pic de revenus et de retours |

---

## 5. Cible & positionnement

**Données (Roblox, mars 2026, utilisateurs vérifiés) :** 36 % ont moins de 13 ans, 38 % ont 13–17 ans, **26 % sont majeurs**. Le segment 18+ croît de plus de 50 % par an et dépense ~40 % de plus par session. Sur ~132 M de joueurs quotidiens, l'audience adulte se compte en dizaines de millions.

**L'opportunité :** quasiment personne ne conçoit pour eux dans ce genre. Les collectionneurs de créatures sont tous calibrés pour des enfants de 10 ans.

**Ce que veut la cible :**
- De la profondeur et de l'optimisation (tableurs, méta, min-max)
- Un jeu qui tourne pendant qu'ils bossent — l'AFK est un argument, pas un compromis
- Une économie crédible : *est-ce que ma créature rare vaudra encore quelque chose dans 6 mois ?*
- Aucune perte de progression subie
- Une UI dense et propre, pas un tutoriel infantilisant

**Contrainte incontournable :** on ne peut pas filtrer l'audience sur Roblox. Des mineurs joueront quand même. Le jeu doit rester sûr et jouable pour eux, même s'il ne les vise pas.

---

## 6. Monétisation

**Principe : vendre du temps et du confort. Jamais l'accès au contenu.**

### Ce qui marche sur adultes
- **Permanent / confort** : slots, automatisation, gestion en masse, filtres d'inventaire, second sanctuaire
- **Gros packs bien valorisés** — un bundle à 2000 Robux qui débloque clairement quelque chose bat dix micro-achats
- **Statut** : cosmétiques visibles, titres, classements, sanctuaire décorable et visitable
- **Season pass** (35–45 jours) — format connu et accepté

### Ce qui ne marche pas
- Micro-consommables à 99 Robux → perçus comme de l'arnaque à la découpe
- Paywall de progression → départ définitif, pas de retour
- FOMO agressive → démolition en commentaires

### Santé de l'économie
- Sinks de monnaie réels
- Pas d'inflation d'items limités (rééditions interdites)
- **Taux de drop publiés publiquement** — condition de confiance qui déclenche la première dépense

---

## 7. Checklist design

- [ ] L'action n'est jamais obligatoire, seulement rentable
- [ ] La rareté est lisible sans lire de texte
- [ ] Le drop Ultra Rare est un moment clippable (ralenti + son + annonce serveur)
- [ ] L'Index survit à la Renaissance
- [ ] Les Reliques ne s'achètent pas
- [ ] Aucune perte de progression subie
- [ ] Taux de drop publiés
- [ ] Pas de rééditions d'items limités
- [ ] Vendre du confort, pas de l'accès

---

## 8. En suspens

- Nom définitif (RIFT BEASTS = provisoire, vérifier la disponibilité sur Roblox)
- Direction artistique précise : sombre/néon vs papier découpé vs ombres chinoises
- Courbe économique chiffrée (voir doc 2, phase P3)
