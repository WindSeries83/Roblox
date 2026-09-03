# Correctifs FTUE, monde, game feel et UI — Implementation Plan

> For agentic workers: execute tasks in order, keep each change minimal, and run the listed checks before moving on.

**Goal:** Rendre les cinq premières minutes lisibles et jouables, rétablir le contrat « monde d’abord », puis garantir que les écrans et le combat de Faille restent compréhensibles sur desktop et mobile.

**Architecture:** Une seule machine d’état d’objectif côté serveur/client alimente le tutoriel, la bannière et les prompts. Les interactions critiques restent validées par le serveur. La mise en page utilise une zone sûre et un modèle de densité commun ; le rendu de créature dispose d’un fallback déterministe sans dépendance à un nouvel asset.

**Tech Stack:** Luau, Roblox Studio, Rojo, RemoteEvents existants, `UiKit`, tests Luau, simulateur d’appareil Studio.

**Spec:** `docs/RIFT_BEASTS_1_bible_design.md`

**État d’exécution 26/08/2026 :** Tasks 1–3 livrées (objectif unique, gating menus, fallback portrait, chargement Rojo, difficulté Faille tutorielle). Task 4 est partiellement livrée (cibles tactiles et bannière contrainte) ; les captures portrait 390×844 et la validation visuelle `eyes` restent à faire dans un environnement réellement orienté portrait.

## Global Constraints

- Ne pas modifier les sauvegardes existantes ni contourner les validations serveur.
- Avant chaque Playtest : Edit, marqueur `SYNC_MARKER`, un seul serveur Rojo, puis nouvelle copie Play.
- Les corrections P3 (bloom, micro-animations, choix typographiques) restent hors de ce plan.
- Aucun nouveau framework UI ni asset payant : réutiliser les helpers déjà présents.

---

## Task 1 — Unifier l’objectif FTUE et différer les menus

**Files:** `src/shared/Objective.luau`, `src/client/Tutorial.luau`, `src/client/Ui.luau`, `src/client/ObjectiveBanner.luau` (si présent).

- [ ] Écrire un test qui démarre un profil neuf et vérifie qu’un seul objectif actif est répliqué à T+0, que l’œuf posé est l’action prioritaire et qu’aucun menu ne s’ouvre automatiquement.
- [ ] Faire de `Objective.luau` la source unique de l’étape active ; supprimer les libellés concurrents générés indépendamment par `Tutorial` et `ObjectiveBanner`.
- [ ] Déclencher l’étape suivante uniquement après `HatchResult` confirmé par le serveur ; le texte doit correspondre au bouton réellement présent (`Œufs`, `Faille`, `Sanctuaire` ou `Plus`).
- [ ] Masquer les menus et panneaux non requis jusqu’à la fin de la première éclosion, sans masquer le HUD d’Essence, le prompt de couveuse ni l’objectif.
- [ ] Vérifier en Play neuf : aucune double instruction, aucune ouverture intempestive, première action faisable sans lecture obligatoire, prochaine action non ambiguë à T+5 min.

**Minimal change:** supprimer les chemins d’affichage redondants et brancher les transitions sur l’événement de hatch déjà existant ; ne pas recréer un tutoriel parallèle.

**Regression test:** `src/tests/unit/*Objective*`, puis scénario Studio `T+0`, `T+15 s`, `T+90 s`, `T+5 min` avec capture des objectifs visibles.

## Task 2 — Rendre l’éclosion et la créature lisibles

**Files:** `src/client/CreaturePortrait.luau`, `src/client/HatchCinematic.luau`, `src/client/Panels/IndexPanel.luau`, `src/client/CreatureDisplay.luau`.

- [ ] Ajouter un test de révélation vérifiant une carte visible au moins quatre secondes, la rareté, le nom, la couleur et un repère visuel de créature.
- [ ] Remplacer le no-op de `CreaturePortrait.Show` par le fallback partagé (silhouette/forme colorée déterministe par espèce et rareté) tant qu’aucun portrait 3D approuvé n’est livré.
- [ ] Garantir que l’état `???`, découverte et possédée de l’Index conserve la même géométrie de cadre et un repère non trompeur.
- [ ] Rendre les effets Ultra Rare distincts et non dépendants d’un asset manquant ; ne pas afficher une créature sans représentation.
- [ ] Vérifier que la carte n’est pas masquée par les toasts, la hotbar ou le halo, et que le résultat serveur reste la seule source du nom et de la rareté.

**Minimal change:** réutiliser les couleurs/raretés de `Config` et les composants d’UI existants ; aucun système d’animation supplémentaire.

**Regression test:** cas HatchResult commun/épique/ultra rare injectés côté serveur, plus capture `audit-ftue-first-hatch-desktop` et une résolution tactile.

## Task 3 — Fiabiliser le parcours et le feedback de Faille

**Files:** `src/server/Services/RiftService.luau`, `src/client/Ui.luau` (`RiftHud`), `src/client/RiftFx.luau`, `src/shared/Net.luau` si un état manque.

- [ ] Ajouter un test d’état `Active → Combat → Defeat/Won → Cooldown` qui verrouille le cooldown anti-réentrée déjà livré et vérifie qu'il survit au cleanup.
- [ ] Rejouer une défaite en restant dans la hitbox ; confirmer qu'aucune session ne se recrée avant l'expiration de `RIFT_REENTRY_COOLDOWN` et qu'une nouvelle entrée volontaire fonctionne ensuite.
- [ ] Afficher une cible/guardian identifiable, une direction d’impact, des dégâts et un état de cooldown ; relier le feedback à l’action d’attaque confirmée par le serveur.
- [ ] Garantir que l’HUD des barres, le bouton d’attaque et le compteur restent dans la zone sûre, sans chevaucher les taux ni les objectifs.
- [ ] Vérifier victoire et défaite en Play : une seule récompense, aucune réentrée automatique, logs propres à l’entrée, l’attaque, la fin et la sortie.

**Minimal change:** conserver le calcul de dégâts, le cooldown et les remotes actuels ; compléter seulement les signaux visuels et le chemin d'input nécessaires au novice.

**Regression test:** `RiftService_Test`/`RiftSim` si présents, test d’attaque serveur, scénario Studio avec maintien dans la hitbox et capture Faille.

## Task 4 — Stabiliser la mise en page multi-appareils

**Files:** `src/client/Ui.luau`, `src/client/UiKit.luau`, panneaux concernés (`HatchCinematic`, `RiftHud`, `Panels/IndexPanel`, `Panels/SkillPanel`, `Panels/ShopPanel`, `Panels/RebirthPanel`).

- [ ] Ajouter un test de layout qui vérifie les bornes de la zone sûre, des boutons ≥44 px et l’absence de coordonnées négatives ou de débordement horizontal.
- [ ] Centraliser le padding sûr, les largeurs compactes et l’ancrage de la hotbar ; éviter que toasts, tutoriel et joystick occupent la même zone.
- [ ] Donner un défilement explicite aux listes longues (Index, arbre, boutique) et un bouton de fermeture cohérent (`✕`, re-clic, Échap/B).
- [ ] Réduire ou masquer les décorations qui coupent le champ de jeu sur 390×844 et 844×390 ; conserver le contraste et la lisibilité du texte sans `TextScaled` excessif.
- [ ] Vérifier desktop 1920×1080, téléphone portrait réel 390×844, téléphone paysage 844×390 et tablette 1024×768 ; le simulateur qui capture en paysage ne suffit pas pour valider le portrait.

**Minimal change:** étendre les helpers de dimensionnement déjà utilisés par `Ui.luau`; ne pas réécrire chaque panneau.

**Regression test:** captures eyes pour les quatre formats, avec contrôle des bornes et des actions tactiles avant toute validation produit.

## Order of execution

1. Task 1 (objectif unique et gating FTUE).
2. Task 3 (état de Faille, car il peut relancer la boucle et polluer les autres tests).
3. Task 2 (lisibilité de la récompense et de l’Index).
4. Task 4 (validation responsive et polish structurel).

## Definition of Done

- Le Play neuf atteint une première éclosion puis une prochaine action unique sans texte contradictoire.
- Une défaite de Faille ne réentre jamais automatiquement et chaque attaque a un feedback visible.
- Les captures des quatre formats restent dans les zones sûres, avec listes accessibles et contrôles tactiles utilisables.
- Les tests unitaires et le Playtest de non-régression passent ; aucun correctif P3 n’est ajouté à ce plan.
