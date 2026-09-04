# Métriques de la vertical slice

Ces mesures servent à décider si la boucle actuelle est compréhensible et satisfaisante avant d'ajouter de nouveaux systèmes.

## Mesures par session

À relever pour une session desktop et une session téléphone paysage, sur un compte vierge :

| Étape | Mesure | Seuil de lecture |
|---|---|---|
| Objectif initial | secondes avant la première action volontaire | objectif compris sans documentation externe |
| Premier œuf | secondes entre l'apparition et l'obtention | aucun blocage ni intervention humaine |
| Incubation | secondes entre placement et compréhension de l'éclosion | état en cours lisible |
| Première créature | réponse à « que produit-elle ? » | production identifiée |
| Parcours | réponse à « où aller ensuite ? » | prochain objectif formulable |
| Première Faille | temps jusqu'au premier combat | navigation et règle comprises |
| Récompense | réponse à « qu'ai-je gagné ? » | récompense identifiée visuellement |
| Optimisation | première décision prise | décision motivée par un bénéfice compris |

## Observations obligatoires

Noter les abandons, hésitations, mauvais menus, textes ignorés, erreurs d'achat, interventions du testeur et moments de plaisir. Capturer la session complète et conserver les captures avec le rapport QA correspondant.

## Critère de décision

La slice passe si chaque étape est réalisable sans aide développeur, si aucun achat ou récompense n'est ambigu, et si le joueur peut énoncer un prochain objectif clair à la fin. Sinon, corriger la compréhension ou le feedback observé avant d'étendre le périmètre.
