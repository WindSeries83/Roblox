# Correctifs social, monétisation et live ops — Implementation Plan

> For agentic workers: execute tasks in order, keep each change minimal, and run the listed checks before moving on.

**Goal:** Rendre les transactions récupérables et atomiques, aligner le VIP sur une durée de 30 jours, puis livrer les surfaces sociales et de classement prévues sans introduire de paywall de contenu.

**Architecture:** Chaque mutation économique possède une clé d’idempotence durable et un claim serveur unique. Les duels passent par un escrow récupérable. Les entitlements VIP sont des dates serveur, séparées des consommables. Les données sociales publiées sont traitées comme dépendances externes tant qu’elles ne sont pas validées dans un place publié.

**Tech Stack:** Luau, Roblox Studio, Rojo, DataStore/ProfileStore, MemoryStore/MessagingService en environnement publié, `PurchaseService`, `MarketService`, `DuelService`, tests Luau.

**Spec:** `docs/RIFT_BEASTS_1_bible_design.md`

**État d’exécution 26/08/2026 :** Tasks 1–4 sont livrées au niveau logique (états marché récupérables, receipts confirmés, défense duel déployée, VIP 30 jours daté). La publication multi-serveur, la zone VIP et les IDs réels restent volontairement non testées/non activées ; Task 5 social/classements reste à valider sur place publié.

## Global Constraints

- Aucun achat Robux réel pendant le développement ou l’audit.
- Ne jamais créditer un vendeur, gagnant ou acheteur avant un claim durable réussi.
- Les tests Studio non publiés doivent marquer clairement les dépendances cross-server/non testables ; la validation finale se fait en sandbox publiée.
- Conserver les fichiers et profils locaux préexistants ; aucune réinitialisation destructive.

---

## Task 1 — Atomicité du marché cross-server (P0)

**Files:** `src/server/Services/MarketService.luau`, helpers de store existants, `src/tests/unit/Market_Test.luau`.

- [ ] Écrire un test concurrent rouge : deux acheteurs réclament le même listing depuis deux caches et un seul claim gagne.
- [ ] Compléter le claim conditionnel durable existant (`UpdateAsync`) par un journal d’état `Open → Claimed → Settled` liant débit acheteur, transfert et crédit vendeur.
- [ ] Débiter l’acheteur, transférer la créature et créditer le vendeur à partir du claim ; rejouer une étape ne doit rien ajouter ni retirer deux fois.
- [ ] Conserver frais de 5 %, caps de prix/listings, délai de retrait de 60 s et double confirmation ; refuser au cap sans perte vendeur.
- [ ] Ajouter une récupération des claims orphelins après redémarrage, avec journal d’audit et limite de reprise.

**Minimal change:** utiliser le primitive de store déjà présent et une seule clé de listing ; ne pas introduire de broker ou de service distribué.

**Regression test:** deux workers de test sur la même clé, fault injection entre chaque étape, puis validation sur deux serveurs d’un place publié.

## Task 2 — Receipt idempotent et transactionnel (P0)

**Files:** `src/server/Services/PurchaseService.luau`, `src/server/Services/SaveService.luau`, tests Purchase/receipt.

- [ ] Écrire un test de replay du même `PurchaseId` après grant réussi, après erreur de store et après redémarrage ; l’effet final doit être exactement unique.
- [ ] Réserver le receipt et le grant dans une opération durable rejouable, ou persister une intention `Pending → Applied` avant de retourner `PurchaseGranted`.
- [ ] Retourner `NotProcessedYet` si la preuve durable du grant n’est pas disponible ; ne jamais acquitter un receipt dont l’état est incertain.
- [ ] Séparer les produits permanents, consommables et boosts dans des fonctions idempotentes ; journaliser le SKU et l’identifiant de receipt sans données sensibles.
- [ ] Tester les produits avec IDs de sandbox non nuls uniquement dans un environnement autorisé, sans appeler de prompt Robux pendant les tests locaux.

**Minimal change:** réutiliser le magasin de receipts existant et ses clés ; ne pas ajouter une file de paiements externe.

**Regression test:** suite Purchase avec fault injection et reprise automatique Roblox en place sandbox publié.

## Task 3 — Équipe défensive de duel conforme (P2)

**Files:** `src/server/Services/DuelService.luau`, `src/shared/DuelSim.luau`, tests Duel.

- [ ] Écrire un test rouge avec une équipe défensive déclarée et une créature de réserve plus puissante.
- [ ] Construire la puissance défensive uniquement avec l’équipe déployée/validée, pas avec toutes les créatures du profil.
- [ ] Vérifier que le résultat est indépendant des créatures de réserve et conserve consentement, mise bornée, propriété des créatures et absence de vol hors ligne.
- [ ] Rejouer refus, timeout et départ afin de verrouiller la régression de l’escrow déjà persisté par `UpdateAsync`.

**Minimal change:** conserver les remotes, l’escrow et le calcul de résolution ; filtrer uniquement la liste défensive avant `DuelSim.TeamPower`.

**Regression test:** test DuelSim avec réserve forte + équipe faible, puis duel à deux clients publié ; dans Studio à une instance, documenter `NON TESTABLE LOCALEMENT`.

## Task 4 — VIP 30 jours, offres et zone serveur (P1/P2)

**Files:** `src/shared/Config.luau`, `src/server/Services/PurchaseService.luau`, nouveau module minimal `src/server/Services/VipService.luau` seulement si aucun helper équivalent n’existe, `src/client/ShopPanel.luau`, `src/client/Ui.luau`, `src/server/Services/SaveService.luau`.

- [ ] Ajouter un test de date serveur : achat initial, prolongation empilée, expiration, reconnexion et horloge client falsifiée.
- [ ] Remplacer le gamepass permanent par un dev product VIP 30 jours ; stocker `VipExpiresAt` et conserver les gains déjà obtenus après expiration.
- [ ] Faire lire `IsVipActive` par les bonus, la boutique et la zone ; refuser l’accès au coffre/œuf VIP côté serveur même si le client force l’UI.
- [ ] Afficher timer, date d’expiration, valeur/taux et prix avant toute proposition ; limiter la modal FOMO à une fois par session.
- [ ] Déclarer uniquement les SKUs consommables remisés de 10 % ; aucun produit ne doit offrir une Relique ou verrouiller le contenu de base.
- [ ] Vérifier que la zone VIP est visible pour tous, que le refus non-VIP est explicite et que la prolongation ne réinitialise pas les achats permanents.

**Minimal change:** conserver `PassEffect` comme adaptateur, mais le faire dépendre d’une date et non d’un booléen permanent ; migration additive avec valeur absente traitée comme expirée.

**Regression test:** tests Vip/Purchase et capture boutique/zone en profils VIP actif et expiré, sans achat réel.

## Task 5 — Classements légers et surfaces sociales livrées

**Files:** services leaderboard/social existants, `src/shared/Config.luau`, `src/client/Panels/LeaderboardPanel.luau`, `src/client/Ui.luau`.

- [ ] Définir les deux axes autorisés par la bible (Essence totale et dépense cumulée) avec seuil Starter explicite, sans fabriquer de faux joueurs.
- [ ] Vérifier cap léger, refresh 5 min, priorité des hauts rangs et affichage de la jauge ; chaque valeur doit être calculée depuis les données serveur.
- [ ] Ajouter des tests de throttling ticker (≤10/min en charge), priorité et absence de duplication d’abonnements après plusieurs sessions.
- [ ] Pour le groupe Roblox, la visite de sanctuaire et rejoindre un ami, ajouter les garde-fous de publication et laisser l’état `NON TESTABLE LOCALEMENT` tant qu’un place publié n’est pas disponible.
- [ ] Vérifier le bonus meute +10 % par ami, cap trois et jauge lisible dans un test logique à plusieurs profils simulés.

**Minimal change:** étendre les services sociaux existants et leurs tests ; ne pas ajouter de réseau cross-server local de remplacement.

**Regression test:** unit tests de caps/throttle puis validation sandbox publiée pour MessagingService, DataStore cross-server, groupe et téléportation.

## Order of execution

1. Task 1 (marché P0).
2. Task 2 (receipts P0).
3. Task 3 (défense de duel P2).
4. Task 4 (VIP P1/P2 et zone).
5. Task 5 (classements et social P2, puis validation publiée).

## Definition of Done

- Un listing ne peut être acheté qu’une fois, un receipt ne peut produire qu’un effet et une mise de duel est toujours remboursable ou réglée exactement une fois.
- Le VIP expire après 30 jours, s’empile, affiche son timer, conserve les gains et ne donne aucun contenu interdit.
- Prix, taux, valeur et statut sont visibles avant proposition ; aucune modal ne force un achat.
- Les classements et bonus sociaux respectent caps et throttling ; les dépendances cross-server ont une procédure publiée reproductible.
