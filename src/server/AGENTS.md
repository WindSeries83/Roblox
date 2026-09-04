# Server rules

- Le serveur est l'autorité unique sur état, économie, drops, achats et récompenses.
- Valider type, propriété, état, bornes et cooldown de chaque remote; rate-limit les appels.
- Les transactions importantes sont idempotentes et ne yieldent pas inutilement dans les hot paths.
- Attendre `SaveService.ProfileLoaded` avant toute logique dépendant du profil.
- Ne pas ajouter de délai arbitraire pour masquer une race.
