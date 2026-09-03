# RIFT BEASTS — Pré-lancement rebaseliné Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Livrer une première session forte, quatre mondes à parcours et trois sanctuaires AFK partagés en conservant les systèmes existants derrière des déblocages progressifs.

**Architecture:** La logique pure vit dans `src/shared`, les états persistants dans le profil, et le serveur reste autoritaire. `RiftService` devient un moteur d'expédition générique piloté par les données des mondes ; `SanctuaryService` réutilise le profil pour les affectations AFK et garde les plots/invitations en mémoire de session.

**Tech Stack:** Roblox, Luau strict, Rojo, ProfileStore, harness de tests Studio existant.

**Spec:** `docs/superpowers/specs/2026-08-28-prelaunch-design-rebaseline.md`

## Global Constraints

- Préserver le WIP incubation/FTUE et l'autorité serveur.
- TDD obligatoire pour chaque contrat pur et chaque migration.
- Un seul place, un seul moteur de parcours, trois gabarits d'étapes.
- Aucun nouveau framework UI ni modèle de boss.
- Vérifier Rojo en Edit avant chaque Play.

---

### Task 1: Contrats de monde et déblocages

**Files:** créer `src/shared/Worlds.luau`, `src/shared/FeatureUnlocks.luau` et leurs cas de test.

**Interfaces:** `Worlds.Get(id)`, `Worlds.NextStage(progress, id)`, `Worlds.CanEnter(progress, stars, id)` et `FeatureUnlocks.For(data)`.

- [ ] Écrire les tests des quatre mondes, des cinq étapes, des boss et des paliers R1/R2/R3.
- [ ] Exécuter les tests ciblés et constater l'absence des modules.
- [ ] Ajouter les tables minimales et les fonctions pures.
- [ ] Rejouer les tests ciblés puis la suite complète.

### Task 2: Progression persistée

**Files:** modifier `SaveService`, `DataSync`, `Rebirth` et les tests de migration.

**Interfaces:** `WorldProgress[worldId] = { HighestStage: number, BossDefeated: boolean }` et `SanctuaryAssignments[sanctuaryId] = { CreatureIds: {string}, LastCollectedAt: number }`.

- [ ] Écrire les migrations défaillantes pour ancien profil, valeurs invalides et données valides.
- [ ] Ajouter les defaults, la normalisation et le payload client.
- [ ] Exiger le boss courant dans `Rebirth.CanRebirth`.
- [ ] Rejouer migrations, Renaissance et suite complète.

### Task 3: Moteur d'expédition Monde 1

**Files:** généraliser `RiftCombat`, `RiftDifficulty`, `RiftService`, `Net` et les tests de Faille.

**Interfaces:** `ExpeditionCombat.Start`, `Advance`, `ChooseTarget`, `ChooseBonus`; remotes `ExpeditionRequest`, `ExpeditionAction`, `ExpeditionSync`, `ExpeditionEnded`.

- [ ] Écrire les tests de checkpoint, progression d'étape, victoire boss, défaite et reprise.
- [ ] Remplacer l'attaque par clic par l'auto-combat tactique minimal.
- [ ] Grouper les joueurs de même monde/étape avec fallback solo et récompenses individuelles.
- [ ] Conserver une première fenêtre accélérée puis une cadence de cinq minutes.
- [ ] Rejouer les tests ciblés et le parcours Studio complet.

### Task 4: Plots et sanctuaires partagés

**Files:** étendre `Sanctuary`, `SanctuaryService`, `DataSync` et leurs tests.

**Interfaces:** `AssignCreatures`, `CollectOffline`, `CanVisit`, `Invite`; les invitations restent non persistées.

- [ ] Écrire les tests de cap personnel, propriété, production hors ligne bornée et absence de double collecte.
- [ ] Allouer un plot par joueur et exposer une invitation lecture seule.
- [ ] Ajouter trois sanctuaires configurés et les affectations persistantes.
- [ ] Vérifier reconnexion et deux joueurs sans blocage mutuel.

### Task 5: Navigation et FTUE progressifs

**Files:** modifier `Ui`, `Objective`, `ObjectiveBanner`, les panneaux concernés et leurs tests purs.

**Interfaces:** toute visibilité provient de `FeatureUnlocks.For(data)`.

- [ ] Écrire les tests des paliers départ, premier hatch, boss 1, R1, R2, R3 et endgame.
- [ ] Renommer `Faille` en `Parcours` et `Sanctuaire` en `Sanctuaires`.
- [ ] Masquer `Plus` et les systèmes avancés avant leur palier.
- [ ] Appliquer l'incubation tutorielle de cinq secondes et supprimer les identifiants techniques visibles.
- [ ] Vérifier desktop et iPhone paysage via captures Studio.

### Task 6: Régions et boss alpha

**Files:** ajouter les quatre régions sous `Workspace.Worlds` et relier les assets existants à `Worlds.luau`.

- [ ] Construire les quatre régions dans le même place avec StreamingEnabled.
- [ ] Réutiliser les créatures existantes pour les quatre boss alpha.
- [ ] Instancier cinq ancres d'étape et une arène de boss par région.
- [ ] Exécuter SceneAnalysisService et corriger uniquement les limites mesurées.

### Task 7: Portes pré-lancement

- [ ] Exécuter EconomySim et `balance-check` sur progression, fenêtres et production AFK.
- [ ] Exécuter build Rojo, StyLua, Selene et tous les tests Studio.
- [ ] Playtester desktop, téléphone paysage, tablette et console.
- [ ] Valider coopération, persistance, marché et invitations sur deux serveurs publiés.
- [ ] Produire le playtest report et appliquer `verification-before-completion`.

