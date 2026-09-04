# Definition of Done

## Toute fonctionnalité

Comportement défini, test pertinent rouge puis vert, StyLua, Selene et absence de régression.

## Pure logic

La logique est déterministe quand possible et testée headless.

## Client/UI

Comportement observé dans Studio sur desktop et téléphone paysage; tablette/console si applicable; focus clavier/manette; aucun contrôle critique inaccessible; preuve runtime capturée.

## Persistence

Migration, reconnexion, données invalides, rollback transactionnel si nécessaire, sauvegarde et reprise après erreur vérifiés.

## Réseau/économie

Serveur autoritaire, payload validé, propriété et état vérifiés, rate limit, double appel/idempotence, reconnexion et multi-client vérifiés. Cross-server seulement avec test publié approprié.

## Gameplay majeur

En plus des tests : preuve runtime, objectif compréhensible, feedback visuel/audio, résultat observé et playtest humain. Des tests verts seuls ne suffisent pas.
