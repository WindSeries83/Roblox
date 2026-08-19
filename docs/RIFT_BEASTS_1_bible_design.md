# RIFT BEASTS — Bible de design

> Jeu Roblox de collection de créatures, orienté idle/optimisation, ciblant le public adulte.
> **Document 1/2.** Le *quoi*. Voir `RIFT_BEASTS_2_plan_production.md` pour le *comment*.
>
> **Audit (19/08/2026)** : chaque section porte un statut — ✅ implémenté · 🔶 partiel · ⛔ absent.
> Les écarts entre la vision et le code sont documentés en fin de document (§9 et §10).

---

## 0. Décisions actées

| Sujet | Décision |
|---|---|
| Plateforme | **Roblox** (Steam écarté) |
| Genre | Collection de créatures + idle/AFK + optimisation |
| Cible | Adultes (18+), joueurs à pouvoir d'achat |
| Direction artistique | Low poly stylisé, palette sombre, **pas** de pastel enfantin |
| Multijoueur | Serveurs partagés, sanctuaires visitables, trading |
| Statut | **P4 livré** (113/113 tests, playtest MCP bout en bout, migration v4) — pré-lancement P5 |

---

## 1. Pitch

Tu es un Dompteur. Tes créatures farment de l'Essence dans ton sanctuaire pendant que tu fais autre chose. Toi, tu ouvres des Failles pour ramener des œufs, des reliques et des mutations, tu croises tes lignées pour fabriquer la créature parfaite, et tu recommences à zéro quand tu plafonnes — en plus fort.

**Phrase de positionnement :** *un jeu de collection qui respecte ton temps.*

---

## 2. Boucle de jeu ✅

1. **Sanctuaire (AFK)** ✅ — Zone du joueurs, les créatures génèrent de l'Essence en continu. Rendement réduit hors ligne.
2. **Faille (action)** 🔶 — Combat simple contre gardiens + cristal. Drop : œufs, reliques. **Écart** : portail toutes les ~10 min (600 s) au lieu des ~3-4 min de la bible — rythme volontairement inchangé en P4.5 (écart §9.1). « Éclats de mutation » absents.
3. **Éclosion** ✅ — dépense d'Essence, tirage rareté × mutation. **Fusion ⛔** (prévue : fusion des reliques 3→1, §3.4).
4. **Élevage** ✅ — croisement de deux créatures, héritage des mutations, générations.
5. **Optimisation** ✅ — équipement, évolution, marché.
6. **Renaissance** ✅ au plafond (4 paliers chiffrés, sim 7 jours).

**Ratio cible : 80 % passif / 20 % actif.** ✅ (structure AFK + événements actifs)

Règle absolue (✅ appliquée) : 
- l'action ne doit **jamais** être obligatoire pour progresser. Elle multiplie. Le joueur y va parce que c'est rentable, pas parce qu'il est puni s'il n'y va pas.
- Le joueur qui ne dépense pas de sous, ne doit en aucun cas se sentir inutile et nul par rapport  àceux qui paye, il a la possibilité.

---

## 3. Systèmes

### 3.1 Rareté (axe 1) 🔶
`Commun (blanc) → Peu commun (vert) → Rare (bleu foncé) → Épique (violet) → Légendaire (doré) → Mythique (turquoise) → ULTRA RARE (rouge bordeaux et noir) → Secret (rose)`

- ✅ 8 raretés définies dans les données ; **10 espèces jouables** (Common/Uncommon/Rare uniquement — Epic+ sans espèces encore, §10).
- ✅ Annonce serveur (seuil Rare actuellement) ; Ultra Rare 1/250 000 000 pas encore atteignable (aucune espèce ni œuf ne la produit).
- Secret : non documenté, drop spécifique qui sorte du gameplay commun, découvert par la communauté. ⛔
- ✅ La rareté est **lisible visuellement** : taille, aura, particules, lévitation. Jamais besoin de lire le nom.

### 3.2 Mutations (axe 2, indépendant) 🔶
`Ombre ×2 · Givre ×5 · Doré ×15 · Prismatique ×50 · Corrompu ×200 · Céleste ×1000`

- ✅ 6 mutations définies ; **Ombre et Givre en jeu** (poids éclosion/élevage). Doré+ pas encore obtenables (§10).
- ✅ Multiplicatif avec la rareté → deux chasses parallèles.
- Une Mythique Céleste ≠ une Ultra Rare normale. C'est ce qui fait rouvrir un œuf déjà obtenu.
- **Système le plus rentable du jeu** : c'est là que se vend la chance.

### 3.3 Élevage génétique — différenciateur n°1 ✅
- ✅ Croisement de deux créatures → descendance héritant des mutations parentales selon probabilités.
- ✅ Chance de mutation nouvelle à chaque génération.
- 🔶 **Version adulte assumée** : pourcentages visibles ✅, arbres généalogiques (parents + génération ✅, affichage complet à venir), stats détaillées ✅, export des données ⛔.
- Objectif : que la communauté fasse ses propres tableurs et les partage. Marketing gratuit + signal de profondeur.
- ✅ Effet de marché : on n'achète plus une créature, on achète un **reproducteur** (le marché vend des créatures entières, parents inclus).

### 3.4 Objets équipables ✅
Slots par créature : 1 au départ, +1 par palier d'évolution. ✅

| Objet | Effet | Statut |
|---|---|---|
| Cœurs | XP / niveau max augmenté | ✅ |
| Colliers | Chance de mutation à l'éclosion | ✅ |
| Reliques | Débloquent l'évolution finale — **drop uniquement en Faille** | ✅ |

> Les Reliques sont la carotte qui justifie l'action. Ne pas les rendre achetables. ✅ (non achetables ; **fusion 3→1 ⛔** à faire)

🔶 à voir : objets bonus qui augmentent les multiplicateurs de certaines stats — non implémenté.

### 3.5 Évolution partout 🔶
- ✅ Créatures (4 stades)
- ⛔ Reliques (fusion 3→1)
- 🔶 Sanctuaire : capacité ✅, vitesse/slots d'équipe ⛔
- ⛔ Rang joueur
- ✅ Paliers d'Index (bonus par entrée + famille)

### 3.6 Index / Bestiaire ✅
Ce n'est **pas** une collection cosmétique — c'est la source des bonus permanents.

- ✅ Chaque espèce enregistrée = petit bonus global.
- ✅ Famille complétée = gros bonus (chance, vitesse de farm, slot).
- ✅ Une entrée par combinaison **espèce × rareté × mutation** → index quasi infini.
- ✅ **L'Index survit à la Renaissance.** C'est ce qui rend le reset acceptable.

### 3.7 Renaissance 🔶
- ✅ Perte : Essence, œufs, niveau de sanctuaire.
- 🔶 Conservation : Index ✅, reliques légendaires ✅, objets multiplicateurs ⛔ (inexistants), **créatures : la plus forte uniquement** (décision P3 — écart §9.2).
- 🔶 Gain : **Étoiles** = multiplicateur permanent ✅ ; déblocage d'une zone / d'un tier de rareté par palier ⛔.
- ✅ Rythme : Renaissance 1 en ~15 min, puis courbe exponentielle (`{50k, 250k, 1.25M, 6.25M}`).

### 3.8 Duel de sanctuaires — différenciateur n°2 ✅
Version adulte du raid : **consentie et avec mise**. ✅

- ✅ Les deux joueurs acceptent, misent de l'Essence, le gagnant prend.
- 🔶 « Les créatures non déployées défendent » → implémentation : **toutes** les créatures du défenseur défendent (pas de notion de déploiement — écart §9.3).
- ✅ **Jamais de vol subi par un joueur hors ligne.** (défis même-serveur uniquement, timeout/remboursement)

### 3.9 Trading ✅
Indispensable. C'est ce qui donne de la valeur aux drops rares, donc ce qui justifie l'achat de chance. ✅
- ✅ Place de marché en Essence, historique des ventes, protection anti-arnaque (double confirmation, délai 60 s, cap, frais 5 %).
- ⛔ Gate « niveau renaissance suffisant » : le marché est accessible dès le début (décision P4 — écart §9.4).
- Nota : pas de Robux joueur↔joueur (ToS) — le Robux entre par packs d'Essence DevProducts + gamepasses.

---

## 4. Maps 🔶

| Zone | Rôle | Statut |
|---|---|---|
| **Sanctuaires** (3–4, débloqués par Renaissance) | AFK, rendement stable, safe | 🔶 **1 sanctuaire** (les autres zones ⛔, §10) |
| **????** (zone public, débloqués par Renaissance) | AFK, rendement aléatoire, risqué (mais aucune perte) | ⛔ |
| **Failles** | Pas de revenu passif dedans, mais ×8 sur les drops → choix actif de sacrifier l'AFK | ✅ (portail cyclique, combat gardien + cristal) |
| **Éclipse** | Évènement serveur toutes les 2 h, 10 min, mutation exclusive | ⛔ |
| **Zone saisonnière** | 2 semaines, créature exclusive jamais rééditée → pic de revenus et de retours | ⛔ (le season pass est une piste de récompenses, pas une zone) |

---

## 5. Cible & positionnement ✅

**Données (Roblox, mars 2026, utilisateurs vérifiés) :** 36 % ont moins de 13 ans, 38 % ont 13–17 ans, **26 % sont majeurs**. Le segment 18+ croît de plus de 50 % par an et dépense ~40 % de plus par session. Sur ~132 M de joueurs quotidiens, l'audience adulte se compte en dizaines de millions.

**L'opportunité :** quasiment personne ne conçoit pour eux dans ce genre. Les collectionneurs de créatures sont tous calibrés pour des enfants de 10 ans.

**Ce que veut la cible :**
- De la profondeur et de l'optimisation (tableurs, méta, min-max)
- Un jeu qui tourne pendant qu'ils bossent — l'AFK est un argument, pas un compromis
- Une économie crédible : *est-ce que ma créature rare vaudra encore quelque chose dans 6 mois ?*
- Aucune perte de progression subie
- Une UI dense et propre, pas un tutoriel infantilisant

**Contrainte incontournable :** on ne peut pas filtrer l'audience sur Roblox. Des mineurs joueront quand même. Le jeu doit rester sûr et jouable pour eux, même s'il ne les vise pas.

**Constats d'implémentation :** UI dense ✅ mais **peu lisible/pratique** (tout passe par le menu, monde sans feedback) → lot P4.5 « Monde vivant » (couveuse, arche, créatures cliquables, bandeau d'objectifs) — voir §8bis.

---

## 6. Monétisation 🔶

**Principe : vendre du temps et du confort. Jamais l'accès au contenu.**

### Ce qui marche sur adultes
- **Permanent / confort** : slots ✅ (gamepass +2), automatisation 🔶 (auto-éclosion), gestion en masse ⛔, filtres d'inventaire ⛔, second sanctuaire ⛔
- **Gros packs bien valorisés** 🔶 — bundle StarterPack ✅ (2000 Essence + flags) ; packs Essence DevProducts ✅ (3 tiers) ; IDs assets à renseigner (placeholders 0)
- **Statut** : cosmétiques visibles ⛔, titres ✅ (season pass), classements ✅, sanctuaire décorable ⛔ / visitable 🔶 (aperçu snapshot, pas de téléport)
- **Season pass** ✅ (20 niveaux, 2 pistes, créature exclusive + titres)
- **Starter Pack** ✅ — donne de l'Essence + un pass combiné ; créature à mutation définie ⛔ (à faire)
- **bonus de chance** ⛔ (session) — non implémenté
- **Multiplicateur du serveur** ⛔ — non implémenté

### Ce qui ne marche pas (✅ respecté)
- Micro-consommables à 99 Robux → perçus comme de l'arnaque à la découpe
- Paywall de progression → départ définitif, pas de retour
- FOMO agressive → démolition en commentaires

### Santé de l'économie
- ✅ Sinks de monnaie réels (upgrade sanctuaire, éclosion, élevage, évolution, frais de marché)
- Pas d'inflation d'items limités (rééditions interdites) — sans objet (pas d'items limités en jeu)
- 🔶 **Taux de drop publiés publiquement** — présents dans le code (`Config`), pas encore exposés en jeu/docs

---

## 7. Checklist design (état 19/08/2026)

- [x] L'action n'est jamais obligatoire, seulement rentable
- [x] La rareté est lisible sans lire de texte
- [ ] Le drop Ultra Rare est un moment clippable (ralenti + son + annonce serveur) — annonce ✅, ralenti/son dédiés ⛔ (aucune espèce Ultra Rare en jeu)
- [x] L'Index survit à la Renaissance
- [x] Les Reliques ne s'achetent pas
- [x] Aucune perte de progression subie
- [ ] Taux de drop publiés (dans le code, pas encore exposés)
- [x] Pas de rééditions d'items limités
- [x] Vendre du confort, pas de l'accès

---

## 8. En suspens

- Nom définitif (RIFT BEASTS = provisoire, vérifier la disponibilité sur Roblox)
- Direction artistique précise : sombre/néon vs papier découpé vs ombres chinoises — en pratique : **crépuscule nocturne low-poly** acté en V1
- ~~Courbe économique chiffrée~~ ✅ résolu en P3 (voir doc 2)

---

## 8bis. Vie du monde (ajout P4.5 — game feel)

Retour joueur (19/08) : « à part éclore des œufs, il se passe rien. Pas vivant, pas lisible, pas pratique. »

**Lot « Monde vivant »** (spec : `docs/superpowers/specs/2026-08-19-p5-gamefeel-world-design.md`) :
- **Couveuse 3D** dans l'enclos : ProximityPrompt → panneau flottant (acheter/éclore) — l'éclosion sort du menu
- **Arche de faille permanente** : construite au démarrage, brille quand la faille est active, compte à rebours « Faille dans X:XX » (rythme inchangé : 600 s)
- **Créatures cliquables** : panneau contextuel (équiper, évoluer, vendre avec prix suggéré)
- **Feedbacks** : +N Essence flottants au tick, réaction au clic (saut + particules)
- **Bandeau d'objectif** : priorité faille active > quêtes prêtes > premier œuf > Renaissance

---

## 9. Écarts constatés (vision vs code, 19/08/2026)

| # | Sujet | Bible | Code actuel | Décision |
|---|---|---|---|---|
| 9.1 | Rythme faille | portail ~3-4 min | **600 s (10 min)** | **Inchangé en P4.5** (volontaire) — à réévaluer plus tard |
| 9.2 | Renaissance | conserve « créatures » | **garde la plus forte uniquement** | Décision P3 actée — bible alignée |
| 9.3 | Duel | « créatures non déployées défendent » | **toutes** les créatures du défenseur défendent | Approximation assumée (pas de déploiement) — à améliorer si le duel devient central |
| 9.4 | Trading | gate niveau renaissance | marché accessible dès le début | Décision P4 (anti-frustration) — bible alignée |
| 9.5 | Reliques | fusion 3→1 | absente | À faire (§10) |

## 10. Reste à faire (consolidé)

**Contenu :** espèces Epic→Secret (10 espèces C/U/R seulement) · mutations Doré+ (Ombre/Givre en jeu) · éclats de mutation (drop faille)

**Systèmes :** fusion reliques 3→1 · rang joueur · vitesse/slots d'équipe de sanctuaire · objets multiplicateurs · zone « ???? » · 2-3 sanctuaires rebirth · Éclipse (2 h) · zone saisonnière · export de données · gestion en masse / filtres d'inventaire · second sanctuaire · bonus de chance session · multiplicateur serveur · cosmétiques décor de sanctuaire · déploiement d'équipe (duel) · taux de drop exposés en jeu
