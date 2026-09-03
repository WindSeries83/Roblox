# Incubation, FTUE et élevage — Plan d’implémentation

> **Pour Luna :** utiliser `superpowers:subagent-driven-development` ou `superpowers:executing-plans` et traiter les tâches dans l’ordre. Cocher chaque étape après preuve. Ne pas écraser les changements déjà présents dans le workspace.

**Objectif :** remplacer l’éclosion immédiate par une incubation persistante et claire, remettre le tutoriel et l’élevage en état, puis corriger les incohérences d’inventaire et de renaissance.

**Architecture :** le serveur reste autoritaire. Une incubation est une donnée persistée avec une échéance absolue (`StartedAt`, `ReadyAt`) ; les modèles 3D et l’interface ne sont que des projections de cette donnée. Le résultat de l’œuf est réservé au placement afin que la durée puisse réellement dépendre de la créature, de sa puissance, de sa rareté et du tier de l’œuf.

**Tech stack :** Roblox/Luau strict, Rojo, ProfileStore, remotes existants de `Net`, tests Luau exécutés dans Studio.

**Spécification :** demande utilisateur du 27 août 2026 et audit disque HEAD `c8866e5`.

## Contraintes globales

- Avant chaque playtest, vérifier en mode Edit que Studio contient le marqueur de la dernière modification disque ; sinon relancer un seul `rojo serve default.project.json` et demander **Connect** dans Studio.
- Ne jamais diagnostiquer le code depuis la copie Play.
- Toute mutation d’œuf, incubation, créature, essence ou élevage est validée et appliquée par le serveur.
- Réutiliser `Net.ActionResult` pour les retours d’échec ; ne créer un nouveau remote que si le contrat ne peut pas être exprimé proprement.
- La V1 possède une seule couveuse logique et aucun achat, file d’attente ou auto-éclosion payante. Le record persistant doit seulement permettre d’ajouter ces capacités plus tard.
- Utiliser `os.time()` et une échéance absolue pour que le timer continue hors ligne.
- L’arrondi d’essence affiché est un entier supérieur (`math.ceil`) afin de ne jamais annoncer qu’il manque 0 alors que la renaissance est refusée.

---

### Tâche 1 — Stabiliser les contrats et tests du socle

**Fichiers :**
- Modifier : `src/server/Services/SaveService.luau`
- Modifier : `src/server/Services/DataSync.luau`
- Modifier : `src/shared/Net.luau`
- Modifier : `default.project.json`
- Test : `tests/Incubation_Test.luau`
- Test : `tests/Migration_Test.luau`

**Produit :** un type d’incubation versionné et synchronisé :

```luau
type ReservedHatch = {
    Species: string,
    Rarity: string,
    Mutation: string?,
    Power: number,
}

type IncubatorRecord = {
    IncubatorId: string,
    EggId: string,
    StartedAt: number,
    ReadyAt: number,
    QueueIndex: number,
    ReservedHatch: ReservedHatch,
}
```

- [ ] Ajouter d’abord des tests de migration : ancien profil sans `Incubators`, record invalide ignoré, record valide conservé.
- [ ] Exécuter le runner Studio et constater l’échec avant modification.
- [ ] Ajouter les valeurs par défaut/migrations minimales et inclure `Incubators` dans le payload de `DataSync`.
- [ ] Aligner `PlaceEgg` entre `Net.luau` et `default.project.json`; supprimer uniquement les déclarations réellement orphelines après `rg` de tous les consommateurs.
- [ ] Vérifier aussi le double mapping de `UiLoader.client.luau`; ne le changer que si le build confirme deux exécutions.
- [ ] Exécuter les tests ciblés, `rojo build default.project.json`, `stylua --check src` et `selene src`.
- [ ] Commit suggéré : `feat: persist incubation records`.

### Tâche 2 — Rendre placement et réclamation atomiques

**Fichiers :**
- Modifier : `src/shared/Incubation.luau`
- Modifier : `src/server/Services/IncubationService.luau`
- Modifier : `src/server/Services/HatchService.luau`
- Modifier : `src/server/Services/NestService.luau`
- Test : `tests/Incubation_Test.luau`

**Interfaces :**

```luau
Incubation.Duration(eggTier: string, creatureRarity: string, power: number): number
IncubationService:Place(player: Player, eggId: string): (boolean, string?)
IncubationService:Claim(player: Player, incubatorId: string): (boolean, string?)
IncubationService:ClearPlayer(player: Player): ()
```

- [ ] Écrire les cas qui échouent : propriété, double placement, slot plein, claim anticipé, double claim, reconnexion, plafond de créatures et rollback en cas d’échec.
- [ ] Réserver une seule fois le résultat RNG lors de `Place`, calculer `ReadyAt`, puis retirer l’œuf et créer le record dans une seule opération logique ; en cas d’échec, ne modifier ni l’inventaire ni les incubations.
- [ ] Remplacer le plafond contradictoire actuel de `120` secondes par des bornes configurées et testées. Point de départ d’équilibrage : durée du tier d’œuf, multiplicateur de rareté de créature, puis bonus de puissance monotone et plafonné.
- [ ] Faire de `Claim` l’unique chemin d’éclosion : vérifier propriétaire et échéance, matérialiser exactement le résultat réservé, retirer le record, mettre à jour statistiques/index, puis appeler `DataSync:Send(player)`.
- [ ] Faire passer l’auto-éclosion existante par `Place` puis `Claim`; aucun chemin ne doit contourner la limite ni ignorer un retour d’échec.
- [ ] Reconstruire les modèles monde depuis `Incubators` à la connexion; les détruire à la déconnexion.
- [ ] Si aucune couveuse n’existe dans un build Rojo propre, générer le proxy minimal côté serveur ou ajouter l’asset déjà utilisé par le projet; ne pas maintenir deux sources.
- [ ] Vérifier les tests ciblés et le scénario Studio achat → placement → reconnexion → attente → claim → créature visible.
- [ ] Commit suggéré : `feat: add timed server-authoritative incubation`.

### Tâche 3 — Créer l’interface propre de la couveuse

**Fichiers :**
- Restaurer ou recréer : `src/client/Panels/CouveusePanel.luau`
- Modifier : `src/client/Panels/EggPanel.luau`
- Modifier : `src/client/Ui.luau`
- Modifier : `src/client/HatchCinematic.luau`

**Comportement :** le panneau reste ouvert après « Placer ». Il affiche l’œuf sélectionné, la durée prévue, l’état (`Vide`, `En incubation`, `Prêt`), un compte à rebours local dérivé de `ReadyAt`, et le bouton contextuel `Lancer l’incubation` ou `Récupérer`.

- [ ] Écrire un test/petit harness client couvrant les quatre états UI et l’actualisation après `DataSync`.
- [ ] Réutiliser `UiKit` et les patterns de panneaux existants; aucune nouvelle bibliothèque UI.
- [ ] Après `PlaceEgg`, conserver le panneau, désactiver immédiatement l’œuf envoyé, puis remplacer l’état optimiste par le prochain `DataSync` ou afficher `ActionResult` en cas de rejet.
- [ ] Empêcher tout second clic pendant une requête et retirer définitivement la carte d’un œuf qui n’est plus dans le snapshot serveur.
- [ ] Attacher la cinématique au modèle d’incubation concerné, pas à `Workspace.Nest.NestEgg`; conserver l’ancrage le temps de la séquence avant cleanup.
- [ ] Tester souris, tactile et manette, puis petites/grandes résolutions avec le skill MCP `rbx-device-simulator-lua`.
- [ ] Commit suggéré : `feat: add persistent incubator panel`.

### Tâche 4 — Remettre le tutoriel sur le vrai parcours

**Fichiers :**
- Modifier : `src/shared/Objective.luau`
- Modifier : `src/client/ObjectiveBanner.luau`
- Modifier : `src/shared/Tutorial.luau`
- Modifier : `src/server/Services/QuestService.luau`
- Modifier : `src/server/Services/RiftService.luau`
- Test : `tests/Objective_Test.luau`

- [ ] Formaliser le parcours actuel : placer l’œuf initial → lancer l’incubation → réclamer la créature → entrer dans une Faille → gagner → réclamer la récompense.
- [ ] Écrire les transitions attendues et le test de sécurité interdisant `TutorialComplete` avant satisfaction serveur de l’objectif.
- [ ] Faire dériver la bannière exclusivement du snapshot serveur synchronisé; déclencher `DataSync` après hatch et victoire de Faille.
- [ ] Supprimer le bouton « Passer » s’il accorde la récompense; si le skip est conservé, il masque seulement l’aide locale.
- [ ] Garantir une récompense unique et idempotente côté serveur.
- [ ] Playtest avec profil neuf, reconnexion à chaque étape et profil déjà avancé.
- [ ] Commit suggéré : `fix: align tutorial with current first session`.

### Tâche 5 — Réparer l’élevage à la racine

**Fichiers :**
- Modifier : `src/server/Services/BreedingService.luau`
- Modifier si le contrat pur l’exige : `src/shared/Breeding.luau`
- Modifier : `src/client/Panels/BreedingPanel.luau`
- Test : `tests/Breeding_Test.luau`

- [ ] Ajouter les tests serveur : deux parents possédés, même espèce, parents distincts, coût, cooldown, capacité du sanctuaire, types remote invalides, mutation/génération et rollback.
- [ ] Corriger la statistique : une naissance d’élevage incrémente `TotalBred` uniquement; `TotalHatched` reste inchangé.
- [ ] Vérifier tous les appelants avant de modifier la signature partagée; appliquer la correction au chemin commun, pas seulement au bouton UI.
- [ ] Retourner chaque rejet par `ActionResult` et synchroniser les données après succès.
- [ ] Playtest : cas valide puis chaque refus, sans retrait d’essence ni création partielle lors d’un échec.
- [ ] Commit suggéré : `fix: restore breeding transaction`.

### Tâche 6 — Nettoyer renaissance et affichage numérique

**Fichiers :**
- Modifier : `src/server/Services/RebirthService.luau`
- Modifier : `src/shared/Rebirth.luau`
- Modifier : `src/client/Panels/RebirthPanel.luau`
- Modifier : `src/server/Services/IncubationService.luau`
- Test : `tests/Rebirth_Test.luau`

- [ ] Ajouter un test qui exige `math.ceil(requiredEssence - earnedEssence)` dans le message utilisateur et interdit toute décimale.
- [ ] Ajouter un test de renaissance pendant incubation : œufs et records supprimés, modèles monde/slots nettoyés, aucun claim possible ensuite.
- [ ] Appeler `IncubationService:ClearPlayer` depuis le reset plutôt que dupliquer le cleanup.
- [ ] Préserver exactement les données déjà prévues par `Rebirth.ApplyReset` : créatures, objets, compagnon, index et arbre.
- [ ] Vérifier un refus puis un succès en Studio et la resynchronisation immédiate du panneau.
- [ ] Commit suggéré : `fix: clean incubation on rebirth`.

### Tâche 7 — Validation du lot et garde-fous futurs

**Fichiers :**
- Créer : `docs/production/qa/playtests/2026-08-27-incubation-ftue-elevage.md`
- Modifier seulement si les valeurs ont changé : données d’équilibrage concernées dans `src/shared`

- [ ] Lancer `scope-check`; reporter les files, plusieurs couveuses, passes et auto-hatch payant dans un lot séparé.
- [ ] Lancer `balance-check` sur les durées avec un tableau tier × rareté × puissance (minimum, médiane, maximum) et vérifier progression monotone/bornes.
- [ ] Exécuter `rojo build default.project.json`, `stylua --check src`, `selene src`, puis les tests dans Studio (le runner Lune est actuellement bloqué par `yield across metamethod/C-call boundary`).
- [ ] Après vérification Rojo en Edit, playtester sur profil neuf et existant : achat/placement, persistance hors ligne, claim, inventaire, tutoriel, élevage et renaissance.
- [ ] Produire le `playtest-report` avec captures seulement pour les anomalies visuelles, puis lancer `verification-before-completion`.
- [ ] Commit suggéré : `test: verify incubation progression fixes`.

## Hors périmètre volontaire

- Plusieurs couveuses, files d’attente, auto-éclosion et monétisation : le schéma `IncubatorId`/`QueueIndex` les prépare, mais aucune UI, entitlement ou boucle automatique n’est créée dans ce lot.
- Refonte générale de l’inventaire : la correction reste dans `EggPanel` et la synchronisation commune.
- Refonte visuelle globale : seul le panneau couveuse et ses états sont concernés.

## Ordre de livraison

Les tâches 1 et 2 forment le socle obligatoire. Les tâches 3 à 6 deviennent ensuite indépendantes et peuvent être confiées séparément à Luna, avec revue entre chaque tâche. La tâche 7 ne commence qu’après intégration de toutes les précédentes.
