# RIFT BEASTS - registre d'execution canonique

Ce fichier est la source de verite de l'etat d'execution. Les documents produit definissent l'intention ; les plans historiques ne constituent pas une preuve.

Regles : ne cocher qu'avec une preuve actuelle ; conserver les offres, SKU, prix et dates LiveOps desactives jusqu'a validation humaine.

## Etat global

| Phase | Etat | Preuve actuelle | Prochain verrou |
|---|---|---|---|
| 0 - vertical slice | En cours | Headless 267/267, 8 skips live ; CI 33966168926 verte sur ef2daff ; smoke Studio frais passe sur le parent 462aea4 (72/72 remotes, boucle oeuf, Rift, UI) | resynchroniser Studio et rejouer le smoke sur ef2daff ; timings 15-20/30-40 min ; focus/B/Echap manuel ; persistance publiee |
| 1 - soft launch | Partiel | offres bloquees ; boucles de retention et instrumentation locale branchees ; suite headless a 267/267, 8 skips live | cohorte/metriques reelles ; vrais SKU/prix ; prompts/receipts publies |
| 2 - quatre mondes | Partiel | contrat quatre mondes distincts, cinq etapes, boss et Rush persistant/idempotent ; 30 especes data ; selection de region, secret serveur et fallback creature/boss branches sur la candidate | modeles/portraits/animations artistiques, runtime UI et Rush publie/reconnexion |
| 3 - social/economie | Partiel | marche/ledger purs ; social session avec amis, invitations expirees, rejoindre/visiter et meute plafonnee ; duel transactionnel par ChallengeId localement valide ; VIP et classement leger branches | deux serveurs publies ; escrow duel et invitations en place publiee ; UI/appareils runtime |
| 4 - lignees/index | Partiel | lignee compatible legacy et index de base testes | arbre/ comparaison/validite cyclique et objectifs avances complets |
| 5 - Saison 1 | Partiel | catalogue/date/version et claims purs | dates/recompenses humaines, piste complete et migration live |

## Dernieres preuves

### Reprise du plan complet

Plan accepte : [COMPLETE_RELEASE.md](COMPLETE_RELEASE.md). Les lots contenu, beta et publication restent a realiser ; Studio n'est pas le seul travail restant.

- Dernier HEAD applicatif de la candidate : `ef2daff` (code) ; les commits documentaires suivants ne modifient pas le runtime.
- HEADLESS local : 267 passes, 0 echec, 8 skips live. Les skips concernent les modules qui exigent des services Studio/publication.
- CI GitHub Actions : [run 33966168926](https://github.com/WindSeries83/Roblox/actions/runs/33966168926), succes sur `ef2daff` ; StyLua, Selene, tests headless (267/267, 8 skips), Wally, build Rojo et Check diff passent. Le correctif `SafeStore` isole maintenant les donnees de Studio en memoire.
- Implementation candidate : secret gratuit persiste et autorise par victoires de boss, zone/coffre/oeuf VIP avec expiration et rollback, classement leger inter-serveurs, selection des quatre mondes, fallback procedural des creatures/boss, murs publics de reconnaissance, titres equipables, renommage de creature avec ticket, reglages audio/effets locaux, nettoyage serveur des remotes legacy/doublons et isolation SafeStore Studio/production.
- STUDIO : smoke frais execute apres synchronisation Rojo. Boot serveur/client sans erreur applicative ; `RemoteRegistry` = 72/72 `RemoteEvent`, aucun manquant, extra ou mauvaise classe. `Net.Sync.Policy` contient `Loaded=true`, `ArePaidRandomItemsRestricted=false`, `IsPaidItemTradingAllowed=true` (mock Studio permissif, pas un compte restreint reel). Achat/placement/incubation/hatch verifies avec reception de `HatchResult` ; taux visibles pour `CommonEgg` (rarete 75/20/5, mutations 88/10/1.7/0.2/0.07/0.02/0.01). Rift ouvert par helper dev temporaire, entree `TwilightGrove` et attaque verifiees (`GuardianHP` 57 -> 43). Gameplay, Oeufs et Boutique montes avec TopBar/ActionBar. Le ServerBoost n'est pas active : achats desactives, SKU 0 ; le code ne l'applique qu'au taux d'Essence, pas au contexte de probabilite. Les seuls messages attendus sont l'indisponibilite Roblox API/MemoryStore en place Studio non publiee.
- PUBLISHED/MULTI-SERVER : reception analytics, policy reelle, receipts, transactions et synchronisation distante non valides par ces tests purs.
- PLAYTEST HUMAIN : parcours Monde 1 et beta complete toujours requis.

### Preuves precedentes (ne valident pas les correctifs de la reprise)

- `lune run tests/run_tests.luau` : 267 passes, 0 echec, 8 skips live (preuve du 5 septembre 2026).
- CI precedent : `33951821124` sur `cbf8b48` ; conserve comme historique, remplace par le run de la candidate ci-dessus pour l'etat courant.
- Checks locaux : `selene src/ tests/` passe ; `wally install` passe ; `rojo build -o <fichier temporaire>` passe ; la CI Linux confirme le `--check` StyLua sur la candidate malgré les fins de ligne CRLF du checkout Windows.
- Studio Edit courant : le serveur Rojo unique écoute sur `localhost:34872`, mais le plugin n'est pas reconnecté ; la source Edit reste donc à resynchroniser vers `ef2daff`. La dernière preuve a réinjecté `HatchEgg`, un doublon `Sync` et une mauvaise classe `BuyEgg` ; `Net` les a automatiquement supprimés au boot serveur avant le Play frais du parent.
- Preuve Studio courante : le Play frais du parent reste valide pour le runtime précédent ; il ne couvre pas l'isolation SafeStore du HEAD `ef2daff`, la policy d'un vrai compte restreint, les achats/receipts publiés ni le multi-serveur.
- Migration/reconnexion : les profils v13 purgent aussi les incubateurs invalides ; test Studio cible `Migration_Test=12` et `Incubation_Test=9` passe.
- EconomySim : matrice AFK/attentif/payeur modere sur 1/7/14/30 jours ; panier payeur strictement simulation-only et plafonne ; metriques non modelisees signalees au lieu d'etre inventees.
- Receipts : un echec de sauvegarde restaure tout le profil et le replay accorde une seule fois ; test pur et test Studio cible passes.
- Marche : rollback vendeur et acheteur, reouverture durable du claim et reprise apres reconnexion testes ; validations deux serveurs encore requises.
- Vertical slice runtime : TwilightGrove etapes 1-5 puis boss checkpointes ; Renaissance corrigee pour exiger le monde indexe par `Rebirths`; resultat `Stars=1`, `Rebirths=1`, oeufs/incubateurs vides, creature/equipement conserves et point d'arbre accorde.
- Appareils : iPhone paysage, iPad paysage, desktop et Xbox mesurent 0 bouton sous 44 px et 0 bouton non selectable ; rendu/focus visuel et B/Echap restent a confirmer manuellement car viewport MCP 1x1 et CoreGUI bloque l'injection.
- Offres : flux unique `Offers.All -> snapshot visible -> ShopPanel -> prompt`; Starter, trois packs Essence, deux potions, Server Boost, VIP 30 jours, retour D2/D7 et piste saison couverts ; tous restent `Enabled=false`, `Sku=0`, prix a definir et `PURCHASES_ENABLED=false`.
- Conformite paid-random : Season Premium est classe sensible car sa piste peut donner Essence et creature ; le serveur refuse une nouvelle attribution quand la policy est restrictive ou indisponible, et le snapshot retire l'offre achetable sans masquer la piste gratuite.
- Retention : trois quetes quotidiennes data-driven avec reset/dedupe persistes ; streak cyclique 7 jours idempotent ; pity Rare+ a 20 ; ticker hebdomadaire avec queue/throttle, rollover et reprise apres echec d'ecriture ; retours D2/D7 a claim unique. Les événements de session, streak et retour sont maintenant contextualisés par joueur.
- Oeuf rotatif : catalogue hebdomadaire data-driven, fenetres calculees sur l'heure serveur, snapshot avec prix/taux/pity/caps, achat via le flux d'oeuf/incubation existant et evenements proposition/achat/hatch ; aucun champ commercial active.
- Analytics Phase 1 : les événements portent maintenant `user_id`, `session_id`, `at` et `schema_version`; `session_start` et `session_end` sont générés côté serveur, avec contexte joueur pour le funnel, hatch, `rare_drop`, élevage, marché, Rift, Rush, quêtes, achats et œuf rotatif. Les mesures D1/D7, conversion et ARPDAU restent des mesures de cohorte publiée.
- Mondes/Rush : schema `Boss` conforme, recompenses et rythmes propres aux quatre mondes ; Rush individuel sauvegarde au start/complete/claim, anti-double claim et snapshot. La revue principale a etendu le rollback a tout le profil afin d'annuler aussi les effets de quetes si la sauvegarde du claim echoue.
- Bestiaire data : 30 especes exactement ; raretes 8/8/5/4/3/2, familles 11/10/9, roles AFK 10/10/10 et repartition sur quatre mondes. Balance-check sans outlier ; assets premium encore non livres.
- Progression : Index, arbre, equipement, evolution et elevage ont des paliers explicites, raisons snapshot et guards serveur ; bonus Index neutralise avant revelation, equipement/evolution mesurables et elevage garde a Renaissance 3.
- Social : presence MemoryStore, invitations MessagingService 60 s, validation d'amitie serveur, rate limits, rejoindre via TeleportService, plots lecture seule et bonus de meute plafonne ; panneau Amis raccorde et helpers d'expiration testes. Deux serveurs publies restent requis.
- Duels transactionnels : `DuelTransaction` impose `Created -> ChallengerEscrowed -> Accepted -> Resolved -> WinnerApplied -> LoserApplied -> Settled`, avec branches `Declined/TimedOut -> RefundApplied -> Settled`. Escrow par profil `DuelLedger[ChallengeId]`, confirmation `SaveProfile`, snapshot/restore en cas d'echec, messages durables pour gagnant/perdant/remboursement hors ligne, scan `Active` borne a 256 et guards `FeatureUnlocks.Duels`. Etat saisonnier durable minimal (`DuelSeason` rating/wins/losses) expose dans le snapshot ; aucun faux classement public n'est declare. Tests purs courants : 267/267 ; le smoke Studio courant est valide pour le runtime local.

## Travail delegue

- GPT-5.6 Luna `Boole` (`01a04b09-2c27-7b81-94f6-5ae4ae6a9595`) : audit/correctif Phase 0 migration et reconnexion pendant incubation.
- GPT-5.6 Luna `Darwin` (`01a04b0c-5daa-7112-a9ff-47d53d71ccf6`) : mise a niveau EconomySim 1/7/30 jours et profils AFK/attentif/payeur modere.
- GPT-5.6 Luna `Lagrange` (`01a04b19-9807-7073-bde5-3bb336751109`) : rollback durable et replay exactement une fois des receipts.
- GPT-5.6 Luna `Godel` (`01a04b21-d896-7a73-9db9-17039bd1cfcc`) : checkpoints et rollbacks vendeur/acheteur du marche.
- GPT-5.6 Luna `Peirce` (`01a04b31-498b-7403-bcdc-31fe8e742f67`) : vertical slice Studio et correction du monde requis pour Renaissance.
- GPT-5.6 Luna `Kierkegaard` (`01a04c4b-575c-7d83-b3ca-4ad0c270be0c`) : contraintes tactiles et audit quatre formats appareil.
- GPT-5.6 Luna `Archimedes` (`01a04c5e-5e03-7c81-ac8c-abb1ead2f79b`) : catalogue et chemin de prompt des offres gated.
- GPT-5.6 Luna `Euclid` (`01a04c6c-12f5-7613-ba9f-a4669df25aad`) : audit/correctifs des quetes quotidiennes, streak, pity, ticker et retours D2/D7.
- GPT-5.6 Luna `Banach` (`01a04c75-ad9b-78b3-92d8-f506dbe050ca`) : oeuf rotatif autoritaire, snapshot/UI, flux d'achat existant et tests de frontiere.
- GPT-5.6 Luna `Schrodinger` (`01a04c7f-a5d0-71a1-877d-75bb7b7c77b3`) : enveloppe analytics et evenements streak, retour, tutoriel et jalons funnel.
- GPT-5.6 Luna `Gibbs` (`01a04c83-5c25-7282-8653-725afac6cf2c`) : contrat des quatre mondes, service Rush persistant, migration v14 et tests.
- GPT-5.6 Luna `Faraday` (`01a04c8f-add0-70e0-b701-96f411a4b626`) : catalogue data de 30 especes et validation de balance.
- GPT-5.6 Luna `Pascal` (`01a04c99-bb32-7812-89e0-b6fff54cd695`) : paliers, objectifs et guards serveur des systemes de progression.
- GPT-5.6 Luna `Gauss` (`01a04ca3-dfb9-7d71-9cee-219fa63addbc`) : socle social serveur, presence, invitations, visite et meute.
- GPT-5.6 Luna `Dalton` (`01a04cac-eba4-7cd3-a192-d4c66830f9d4`) : panneau Amis et tests purs des invitations/expirations.

## Decisions humaines encore requises

- nom final, IDs Roblox, SKU/prix, dates LiveOps et valeurs finales de l'arbre ;
- activation commerciale ;
- methode d'obtention des Secrets ;
- publication et acces a deux serveurs pour les validations live.
- validation manuelle du rendu/focus clavier et publication avec persistance reelle.
