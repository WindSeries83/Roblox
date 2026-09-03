# RIFT BEASTS — Rebaselining design pré-lancement

## Promesse

RIFT BEASTS est un jeu de collection idle/optimisation où le joueur forme une équipe, franchit des parcours coopératifs, vainc des boss et renaît vers quatre mondes. L'élevage génétique est une couche de maîtrise endgame ; l'Index est une boucle de complétion secondaire.

## Espaces et progression

- Un seul place Roblox contient quatre régions streamées : Bosquet du Crépuscule, Fournaise de Cendre, Cimes des Bourrasques et Abîme de Nyx.
- Chaque joueur reçoit un plot privé dans le serveur. Les visites sont sur invitation et n'autorisent aucune mutation de la base visitée.
- Trois sanctuaires AFK partagés existent hors des mondes. Chaque joueur y déploie ses propres créatures ; les équipes des autres sont visibles mais ne bloquent jamais un poste.
- Les Mondes 2, 3 et 4 demandent respectivement les Renaissances 1, 2 et 3 ainsi que la victoire contre le boss précédent.
- Les sanctuaires partagés demandent une combinaison boss + Renaissance. Les seuils exacts sont fixés par simulation, pas par intuition.

## Parcours

- Chaque monde contient cinq étapes puis un boss alpha dérivé d'une créature existante.
- Trois gabarits d'étape sont réutilisés : vague tactique, choix de bonus et élite/endurance.
- Une fenêtre d'entrée coop ouvre toutes les cinq minutes pendant 60 à 90 secondes. La première entrée FTUE est accélérée.
- La fenêtre limite seulement l'entrée. Une expédition commencée peut être terminée librement.
- Les joueurs ayant le même monde et la même prochaine étape sont groupés. Sans pair, le parcours démarre en solo.
- Le combat est automatique ; le joueur choisit ponctuellement une cible ou un bonus. Il n'y a pas de spam de clics.
- Chaque étape terminée crée un checkpoint persistant. Défaite ou déconnexion ne supprime ni checkpoint ni récompense acquise.

## Première session et révélation

- L'œuf initial passe par la vraie couveuse avec une durée tutorielle de cinq secondes. La première créature doit être visible avant quinze secondes.
- Aucun menu plein écran n'est imposé avant cette première créature.
- La première Renaissance vise 30 à 40 minutes de jeu attentif, sans attente artificielle et après victoire du boss du Monde 1.
- Navigation permanente : `Œufs · Parcours · Sanctuaires · Plus`.
- Départ : Œufs et base privée ; Parcours apparaît après la première créature ; Plus reste masqué.
- Boss Monde 1 : Objectifs, Boutique, première offre et Renaissance.
- Renaissance 1 : Monde 2, Arbre d'Étoiles, Index, Marché et premier sanctuaire partagé.
- Renaissance 2 : Monde 3, Amis, classements et Duels.
- Renaissance 3 : Monde 4, Élevage expert et deuxième sanctuaire partagé.
- Renaissance 4 + boss final : troisième sanctuaire et endgame/live ops.

## Contraintes lean

- Aucun place secondaire, framework UI ou modèle de boss dédié au lancement.
- Un seul moteur de parcours et trois gabarits d'étapes pour les quatre mondes.
- Les postes AFK ne sont jamais rares ni compétitifs.
- Portrait mobile hors périmètre : le jeu reste `LandscapeSensor`.
- Boutique et systèmes avancés restent masqués jusqu'à leur déblocage, mais leur code existant est conservé.

## Critères d'acceptation

- Première créature en moins de quinze secondes ; boss Monde 1 vers 15–20 minutes ; première Renaissance médiane vers 30–40 minutes.
- Une prochaine action significative reste visible pendant toute attente de fenêtre.
- Checkpoint, récompense et affectation AFK survivent à la reconnexion sans duplication.
- Un joueur seul et un groupe opportuniste peuvent terminer chaque étape.
- Aucun chevauchement bloquant sur petit téléphone paysage, tablette, desktop ou console.
- Les seuils économiques et AFK passent EconomySim et `balance-check` avant validation.

