# Baseline de consolidation

Audit effectué le 2026-09-04 sur le commit `d5b102106dfa611ea422592d8e02696559a81d72`.

## État réel

- Dépôt Rojo Luau organisé en `src/server`, `src/shared`, `src/client` et `src/tests`.
- Le bootstrap charge 30 services dans `src/server/Services`; la persistance repose sur ProfileStore, version de profil 7.
- La bible `docs/RIFT_BEASTS_1_bible_design.md` est le seul document qui se déclare explicitement « source unique du design ».
- Aucun `docs/production/execution-status.md`, `docs/product/`, `docs/technical/`, `tests/` ou workflow `.github/workflows/` n'existe.
- Les plans de `docs/superpowers/plans/` sont des plans d'exécution datés sans marqueur d'archivage.
- 134 fichiers Luau, dont 0 commencent actuellement par `--!strict`.
- `src/shared/Net.luau` crée à la volée 56 remotes; `default.project.json` en déclare également une liste statique. Les deux listes peuvent dériver.
- `PurchaseService` et plusieurs autres services écoutent directement `Players.PlayerAdded`; `PurchaseService` vérifie les game passes en tâche asynchrone sans attendre un signal explicite de profil chargé.
- Aucun appel à `PolicyService:GetPolicyInfoForPlayerAsync` n'a été trouvé.
- Le calcul actuel des drops est dans `Gameplay.RollEgg`/`MutationWeights`; les bonus de chance sont combinés par `shared/Luck`, mais aucun contrat unique roll/UI/disclosure n'est documenté.

## Validations avant consolidation

| Contrôle | Résultat | Observation |
|---|---|---|
| StyLua | ÉCHEC | `stylua --check src tests` retourne des différences de formatage; le chemin `tests` n'existe pas. |
| Selene | ÉCHEC | `selene src tests` signale le chemin `tests` absent et 1 erreur dans `src/client/Ui.luau:635` (plus 1 warning). |
| Lune | NON EXÉCUTÉ | `lune` n'est pas installé dans le manifeste Rokit; `tests/run_tests.luau` n'existe pas. |
| Wally | PASS | Installation de ProfileStore réussie; elle a régénéré `ServerPackages` et normalisé l'état de fin de ligne de `wally.lock`. |
| Rojo build | ÉCHEC | `ServerPackages` est référencé par `default.project.json` mais son dossier n'était pas constructible avant installation Wally. |
| `git diff --check` | PASS | Aucun whitespace error détecté. |

## Dettes documentaires

- Vision produit, non-goals, roadmap durable, vertical slice et définition of done absents.
- Hiérarchie canonique entre bible, roadmap, milestone, état d'exécution et plans historiques non définie.
- README contient un nombre de tests figé et une architecture partiellement obsolète (`init.client.luau`).
- Aucun protocole de playtest humain ni schéma canonique d'analytics/contrats techniques.

## Dette technique et risques

- **P0** : aucune validation runtime Studio/live établie dans le dépôt; achats, persistance publiée et cross-server non prouvés.
- **P1** : source des remotes dupliquée; lifecycle profil implicite; politique d'items aléatoires payants non implémentée; pipeline Rojo/CI non vert.
- **P2** : strictness non adoptée; documentation des probabilités, invariants économiques et événements analytics dispersée ou absente; anciens plans susceptibles d'être lus comme tâches actives.

Cette baseline décrit l'état observé, pas une affirmation de fonctionnalité terminée. Les fichiers historiques restent à comparer au code avant archivage.
