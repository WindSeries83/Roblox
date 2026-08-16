# RIFT BEASTS

Jeu de collection de créatures orienté idle/optimisation pour Roblox (public adulte).
Vanilla Luau maison + ProfileStore. Voir `docs/` pour le design et le plan de production.

## Prérequis

- [Roblox Studio](https://create.roblox.com) à jour
- [Rokit](https://github.com/rojo-rbx/rokit) (gère Rojo, StyLua, selene, wally)
- Plugin Rojo installé dans Studio

## Démarrage

```bash
rokit install     # outils du projet (rojo, stylua, selene, wally)
wally install     # dépendances (ProfileStore -> ServerPackages/)
rojo build -o "Roblox.rbxlx"
```

Ouvrir `Roblox.rbxlx` dans Studio, puis :

```bash
rojo serve
```

Dans Studio : widget Rojo → **Connect** (localhost:34872).

## Qualité

```bash
stylua src    # format
selene src    # lint (std roblox)
```

## Tests unitaires

Les tests vivent dans `src/tests/unit/` (mappés sur `ServerStorage.UnitTest`).

1. Démarrer le Play dans Studio (le runner `UnitTestRunner` est désactivé par défaut).
2. Exécuter via MCP (datamodel Server) ou la barre de commandes :

```lua
require(game.ServerStorage.UnitTest.RunUnitTest)()
```

Attendu : `[SUMMARY] 26 run, 26 passed, 0 failed`.

## Architecture

```
src/
  server/
    init.server.luau      -> Bootstraps les services
    Bootstrap.luau        -> Registry vanilla (Init -> Start)
    Services/             -> Log, SaveService (ProfileStore), EssenceService,
                             HatchService, RiftService, PlayerDataService
  shared/
    Config.luau           -> Constantes d'équilibrage (à régler en P3)
    Gameplay.luau         -> Logique pure (rolls, création, taux) — testée
    Net.luau              -> Remotes typés
    Data/                 -> Rarités, Mutations, Espèces
  client/
    init.client.luau
    Ui.luau               -> UI générée en code (ScreenGui)
```

Règles :
- Toute logique d'argent/drop côté serveur uniquement.
- Toute transaction économique passe par `Log:Economy` (logs `[ECON]`).
- La logique pure va dans `shared/Gameplay.luau` pour rester testable sans Play.
