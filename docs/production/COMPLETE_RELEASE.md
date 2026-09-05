# Version complete : plan accepte

Reference de depart : ffa300bbd6dccd45ab82bb2415b7853626b1c300.
Decision utilisateur : quatre mondes, 30 creatures, progression, social et boutique ; beta fermee de 20-30 joueurs avant ouverture publique.
Ce plan reste incomplet tant que tous les lots ne disposent pas de leurs preuves.

## Implementation livree dans la candidate courante

- Le parcours des quatre mondes expose la selection de region cote client et conserve les guards serveur, les boss et les checkpoints.
- Le secret gratuit est branche sur les victoires de boss : quatre decouvertes persistees, indices emis par le serveur, autel et recompense unique.
- Le VIP couvre l'expiration serveur, le respawn, la zone, le coffre quotidien, l'oeuf VIP et le suivi des achats.
- Le classement distant accepte les resumees inter-serveurs et expose le classement leger « gratuit ou Starter seul ».
- Le schema de donnees passe en v18 ; les templates proceduraux de secours rendent les creatures et boss visibles sans assets importes.
- Les reglages locaux audio/effets reduits sont accessibles depuis l'interface, sans masquer les informations critiques.
- Le mur public des Secrets et le mur des soutiens sont persistants, bornes et affiches dans la zone d'accueil ; les SKU de soutien restent desactives jusqu'a validation.

Ces points decrivent l'implementation sur disque ; ils ne remplacent pas les preuves STUDIO, PUBLISHED/MULTI-SERVER et PLAYTEST HUMAIN ci-dessous.

## 1. Socle et Monde 1

- [x] Rejeter les SKU payants nuls, negatifs, non entiers et non finis ; distinguer cadeaux gratuits et prompts payants.
- [x] Corriger la signature de LogCustomEvent et transmettre les dimensions supportees ; rendre les echecs visibles.
- [ ] Verifier la coherence catalogue/prompt/receipt avec des produits configures et la reception analytics publiee.
- [ ] Synchroniser Studio Edit avec les sources disque, puis demarrer un Play neuf.
- [ ] Smoke : boot client/serveur, RemoteRegistry, Policy Sync, achat/placement/incubation/hatch et HatchResult, taux rarete/mutation, ServerBoost Essence sans hatch luck, Rift et interfaces Eggs/Shop/HUD.
- [ ] Compte vierge sans helpers : creature, production comprise, Faille, recompense, retour, optimisation, prochain objectif. Enregistrer desktop et telephone paysage.

## 2. Contenu apres validation humaine du Monde 1

- [ ] Quatre regions abouties : acces, cinq etapes, boss, recompenses, retour et reprise ; identites visuelles et sonores.
- [ ] Modeles, portraits et animations des 30 especes ; mutations, compagnons, activites du sanctuaire, celebrations et transitions.
- [ ] Equipement, evolution, arbre, elevage et Index : prerequis, couts, benefices, comparaisons, parents connus et generations.
- [ ] Quatre Rush et conservation de la progression lors des renaissances et reconnexions.
- [ ] Secret gratuit : un indice accessible apres chaque boss, quatre decouvertes persistees, rituel au sanctuaire et recompense unique serveur. Aucun achat ni tirage payant ; solution absente des modules repliques.

## 3. Economie, social et commerce

- [ ] Simulations reproductibles gratuit/Starter/modere sur 1/7/14/30 jours ; finaliser courbes avant prix.
- [ ] Experience privee publiee : migrations, interruptions de sauvegarde, incubation, replay, saturation et reprise transactionnelle.
- [ ] Amis, invitations, visites, meute, marche et duels avec plusieurs clients et deux serveurs ; concurrence, timeout et paiements hors ligne.
- [ ] Classement distant ; classement leger durable « gratuit ou Starter seul », excluant tout autre achat.
- [ ] Statut social, titres, soutiens et reconnaissance des Secrets.
- [ ] VIP date complet : activation, expiration en session, respawn, renouvellement, zone/coffre, gains conserves.
- [ ] Offres de confort, consommables, variantes VIP et cosmetiques : avantages livres, identifiants reels, prix valides et receipts verifies.
- [ ] Probabilites affichees conformes aux resultats possibles ; policy permissive/restrictive/indisponible, en distinguant simulations et comptes reels.
- [ ] Saison 1 : deux pistes, calendrier, claims, changement de saison et conservation.

## 4. Qualite et beta

- [ ] Desktop, telephone paysage, tablette et manette : lisibilite, focus, fermeture, defilement et zones sures.
- [ ] Reglages audio/reduction des effets ; informations critiques autrement que par couleur seule.
- [ ] Mesures appareils reels : cibles initiales 30 FPS telephone, 60 FPS PC, absence de croissance memoire persistante sur parcours repetes.
- [ ] Payloads invalides/repetes, propriete, distance, etat et idempotence sur reseau et economie.
- [ ] Beta fermee de sept jours, 20-30 joueurs ; zero perte/duplication connue ou blocage, au moins 80 % de parcours initiaux sans aide.
- [ ] Retours D1/D7 et observations de comprehension ; ne pas confondre petit echantillon et preuve statistique commerciale.

## 5. Publication

- [ ] Nom, description, icone/thumbnails fideles ; droits et permissions des assets.
- [ ] Configuration Roblox, produits/prix et appareils ; donnees de test separees de production.
- [ ] Candidate identifiee par SHA avec CI, Studio, tests publies et rapport beta.
- [ ] Retour arriere compatible avec les sauvegardes ; desactivation achats/echanges et procedure incident.
- [ ] Validation de la candidate, ouverture publique et surveillance des premieres 48 heures.

Les IDs Roblox, prix, validation artistique et ouverture publique exigent des valeurs ou decisions reelles. Leur absence ne vaut pas validation.
Les preuves HEADLESS/CI, STUDIO, PUBLISHED/MULTI-SERVER et PLAYTEST HUMAIN sont distinctes dans execution-status.md.
