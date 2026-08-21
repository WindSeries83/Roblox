# RIFT BEASTS — Spec « FTUE & Monde vivant » (Lots A+B)

> Design validé le 21/08/2026 après diagnostic joueur. Complète la bible (`RIFT_BEASTS_1_bible_design.md`) et réordonne les priorités du plan P5.
> Problème racine : **la boucle est complète mais le feeling est mauvais — abandon dans les 5 premières minutes.**

---

## 0. Diagnostic acté

Retour joueur brut : « en tant que joueur, je ne veux pas continuer de jouer ». Six hypothèses confirmées :

| # | Hypothèse | Cause racine |
|---|---|---|
| H1 | Sanctuaire mort | Créatures immobiles en grille, rien à regarder pendant l'AFK |
| H2 | Faille sans impact | Combat = nombres, zéro animation/feedback physique |
| H3 | Jeu de menus | L'essentiel se passe dans des panneaux UI, pas dans l'île |
| H4 | Trous de rythme | Faille toutes les 3-4 min, rien entre deux beats |
| H5 | Pas de faim | Aucun teasing, aucun « encore un » |
| H6 | Pouvoir invisible | La progression ne se voit pas dans le monde |

**Moment d'abandon : les 5 premières minutes.** Le tutoriel actuel = 6 étapes de menus ; le joueur lit au lieu de jouer. La bible §4 (« l'écran est vivant ») n'existe nulle part dans le parcours initial.

**Direction retenue : A « Le monde d'abord » + pincée de C « boucle active ».**
B « juice pass » seul est insuffisant (H3/H4 structurels) ; C seul contredit la promesse 80 % passif.

---

## 1. Séquence FTUE cible (minute par minute)

- **T+0 s — Naissance dans un monde vivant.** Spawn sans aucun panneau bloquant. Un œuf est posé dans un nid près du spawn, dans le monde. Prompt contextuel unique : « Approche-toi de l'œuf ».
- **T+10 s — Première éclosion spectaculaire.** Interaction avec l'œuf → cinématique courte (tremblement, lumière, craquement), la créature jaillit, vient se placer à côté du joueur. Pity `FIRST_HATCH_WEIGHTS` conservé. Son + burst + succès FirstHatch (+50). Première récompense < 15 s.
- **T+20 s — Le farm devient visible.** La créature suit le joueur et travaille sous ses yeux (creuse/ramasse/patrouille selon rôle), pépite dorée qui vole, « +N Essence » flottant. Zéro menu ouvert jusqu'ici.
- **T+60-90 s — Première faille accélérée.** Ouverture anticipée pour les nouveaux joueurs (`FIRST_RIFT_DELAY`), cadence normale ensuite. Combat court et juteux : créatures qui accompagnent, ruée d'attaque, impact gardien, flash PV, shake caméra à la riposte. Victoire → explosion de récompenses ×8.
- **T+2-3 min — Les menus arrivent en dernier.** Auto-ouverture unique sur l'onglet Œufs (« tu peux en avoir davantage »). Le tutoriel 6 étapes d'UI devient 3 prompts monde. L'expert peut tout ignorer.

**Critère d'acceptation :** un nouveau joueur voit sa créature travailler, éclot 1-2 œufs en monde, gagne une faille et sait quoi faire ensuite — sans jamais lire un tutoriel, en moins de 5 minutes.

## 2. Pincée active (C) — occupation continue sans casser le 80 % passif

- **Orbes d'Essence ambiantes** : ~toutes les 45 s, une pépite lumineuse apparaît dans le sanctuaire, cliquable → petit bonus (~2 % d'un tick de rendement, plafond serveur strict). Jamais obligatoire, toujours rentable (bible §2).
- **Clics sur créatures amplifiés** : combo visuel (burst + saut + son léger), easter egg cosmétique après 10 clics. Gain économique nul → zéro risque anti-triche.
- **Sécurité** : tout gain cliquable est attribué côté serveur uniquement, rate-limité (SE-5), plafonné par joueur. Le client ne fait qu'afficher.

## 3. Rythme & faim (H4+H5)

- Première faille accélérée (~90 s) pour nouveaux joueurs ; normale ensuite.
- Orbes ambiantes + comportements de farm comblent les plages mortes.
- **Teasing couveuse** : un œuf rare verrouillé affiché en permanence avec sa condition d'accès (« Reviens au rang de sanctuaire N »). L'envie naît du contenu vu mais fermé.
- `ObjectiveBanner` gagne un état « teasing » pointant vers le contenu verrouillé le plus proche quand rien d'urgent n'est actif.

## 4. Pouvoir visible (H6)

- Créatures : taille/aura étendues au niveau (croissance légère continue, visible à l'œil).
- Sanctuaire : chaque upgrade matérialise physiquement les +2 emplacements (socles au sol).
- Topbar : puissance d'équipe affichée en continu.
- Renaissance cinématique : flash + bascule immédiate du thème du nouveau monde (raccord Task 8 mondes réthémisés).

## 5. Réordonnancement des priorités

| Ordre | Lot | Contenu |
|---|---|---|
| 1 | **A · FTUE & Monde vivant** | Suivi (Task 10), farm behaviors (Task 11), anims combat (Task 12) + NEW : nid de spawn, première faille accélérée, orbes ambiantes, tutoriel 3 prompts, teasing couveuse |
| 2 | **B · Pouvoir visible** | Taille par niveau, socles d'emplacements, puissance topbar, renaissance cinématique |
| 3 | C · Profondeur (= ancien Lot 2) | Arbre de compétence, mondes/Rush, Éclipse (Tasks 7-9 du plan P5 existant) |
| 4 | D · Tech pré-lancement | Analytics (Task 14), re-layout UI (Task 15), audit sécurité (Task 16). Task 13 Rojo retirée (résolue le 21/08) |

## 6. Contraintes transversales

- Toute économie/drop côté serveur ; client = affichage uniquement (SE-2).
- Toute transaction passe `Log:Economy`.
- Logique pure dans `src/shared/*`, testée hors Play ; services dans `Bootstrap.ORDER`.
- Chaque tâche : stylua + selene + suite verte avant commit ; vérification visuelle MCP (capture + agent eyes) à chaque tâche rendant quelque chose de visible.
- Pas de publication ce cycle (IDs gamepasses à 0, DataStore mock Studio).
