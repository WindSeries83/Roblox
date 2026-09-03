# Correctifs boucle principale, progression et économie — Implementation Plan

> For agentic workers: execute tasks in order, keep each change minimal, and run the listed checks before moving on.

**Goal:** Rétablir les invariants de progression, rendre l’économie cohérente avec les sources de récompense de la bible et supprimer les gains ou tirages qui contournent la boucle principale.

**Architecture:** Les gains d’Essence sont décidés côté serveur à partir d’un état de session autoritatif. Les présentations de l’arbre lisent les mêmes prérequis que la validation serveur ; la simulation économique reste un outil de diagnostic séparé.

**Tech Stack:** Luau, Roblox Studio, Rojo, `SaveService`, services serveur de gameplay, `Config`, tests Luau et EconomySim.

**Spec:** `docs/RIFT_BEASTS_1_bible_design.md`

**État d’exécution 26/08/2026 :** le garde serveur de revenu passif et le plafond Luck existaient déjà et sont conservés ; la migration transactionnelle, les tests de frontière et la Faille tutorielle sont livrés dans le workspace. Le graphe visuel et la simulation économique 14 jours restent diagnostics à exécuter, sans inventer de valeurs manquantes.

## Global Constraints

- Ne pas réinitialiser les profils réels pendant le développement ; utiliser des profils Play temporaires.
- Toute mutation Essence, œuf, créature, relique ou arbre reste serveur-authoritative.
- Une Relique ne doit avoir qu’une source livrée : la Faille ; aucun correctif ne doit l’ajouter à la boutique.
- Les valeurs encore explicitement « à valider par sim » restent documentées comme non testables tant qu’une simulation reproductible n’est pas disponible.

---

## Task 1 — Prouver le garde de revenu passif en Faille

**Files:** `src/server/Services/EssenceService.luau`, `src/server/Services/RiftService.luau`, `src/shared/Net.luau` si l’état de session doit être répliqué.

- [ ] Ajouter un test qui place un joueur en `RiftCombat`, avance le heartbeat et vérifie qu’aucun `Essence` ni `TotalEssenceEarned` passif n’est ajouté.
- [ ] Exposer un état de session minimal (`InRift`, `RiftCombat`, `RiftEnd`) consommé par `EssenceService`, sans faire confiance à un booléen client.
- [ ] Reprendre le tick exactement après sortie/fin de Faille, sans rattrapage caché ni double gain.
- [ ] Vérifier dans les logs et le profil temporaire : rendement visible, valeur serveur et `TotalEssenceEarned` restent alignés avant, pendant et après la Faille.

**Minimal change:** durcir le garde serveur déjà présent dans le chemin commun du tick passif et couvrir son état par test ; conserver les récompenses explicites de victoire et le multiplicateur ×8.

**Regression test:** test heartbeat + Playtest combat de 30 s, avec assertion de delta zéro pendant le combat puis delta normal après sortie.

## Task 2 — Aligner arbre, fusion et plafonds économiques

**Files:** `src/shared/Config.luau`, `src/shared/SkillTree.luau`, `src/server/Services/SkillService.luau`, `src/server/Services/EssenceService.luau`, `src/client/Panels/SkillPanel.luau`, services d’éclosion/fusion concernés.

- [ ] Ajouter un test de graphe qui vérifie 12 nœuds, trois branches, chaque `Requires`, le rang maximal et le refus serveur d’un achat hors prérequis.
- [ ] Rendre les liens et coordonnées du graphe visibles dans l’UI à partir des mêmes données que le serveur ; afficher les effets effectifs après achat.
- [ ] Définir et tester le sink de fusion prévu (œufs/reliques) uniquement si le lot de livraison l’inclut ; sinon le conserver explicitement `PRÉVU NON LIVRÉ` dans le rapport, sans inventer un coût.
- [ ] Introduire un plafond global documenté pour les multiplicateurs de chance/rendement, appliquer ce plafond au calcul serveur et afficher sa valeur à côté du rendement.
- [ ] Vérifier les caps d’orbes, pity et SessionLuck avec des tests de frontière ; aucun bonus ne doit dépasser le plafond par combinaison.

**Minimal change:** réutiliser les définitions de `Config` et les validateurs existants ; le client ne fait que présenter le graphe et le cap.

**Regression test:** `SkillTree_Test`, tests de calcul Essence/Luck et capture arbre + HUD avant/après achat.

## Order of execution

1. Task 1 (revenu passif en Faille, P2).
2. Task 2 (arbre et plafonds, P2).

## Definition of Done

- Aucun tick passif ne survient pendant le combat de Faille ; la récompense de victoire reste atomique et visible.
- L’arbre affiche ses liens et applique les mêmes prérequis côté client et serveur ; les multiplicateurs respectent un plafond explicite.
