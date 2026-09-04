# RIFT BEASTS

Jeu Roblox de collection de créatures orienté idle/optimisation. Le chantier actuel valide le vertical slice du Monde 1 avant toute expansion.

Commencer par `AGENTS.md`, puis [`docs/product/NORTH_STAR.md`](docs/product/NORTH_STAR.md).

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

La validation Studio est la source de vérité du runner actuel; aucun nombre de tests n'est figé ici.

## Architecture réelle

```
src/
  server/
    Main.server.luau       -> Bootstraps les services (enfant du service)
    Bootstrap.luau        -> Registry vanilla (Init -> Start)
    Services/             -> Log, SaveService (ProfileStore), EssenceService,
                             HatchService, RiftService, PlayerDataService
  shared/
    Config.luau           -> Constantes d'équilibrage (à régler en P3)
    Gameplay.luau         -> Logique pure (rolls, création, taux) — testée
    Net.luau              -> Remotes typés
    Data/                 -> Rarités, Mutations, Espèces
  client/                  -> contrôleurs, UI et présentation
```

Règles :
- Toute logique d'argent/drop côté serveur uniquement.
- Toute transaction économique passe par `Log:Economy` (logs `[ECON]`).
- La logique pure va dans `shared/Gameplay.luau` pour rester testable sans Play.

## Documentation canonique

- Produit : [`NORTH_STAR.md`](docs/product/NORTH_STAR.md), [`NON_GOALS.md`](docs/product/NON_GOALS.md), [`ROADMAP.md`](docs/product/ROADMAP.md)
- Validation : [`VERTICAL_SLICE.md`](docs/production/VERTICAL_SLICE.md), [`DEFINITION_OF_DONE.md`](docs/production/DEFINITION_OF_DONE.md), [`execution-status.md`](docs/production/execution-status.md)
- Technique : [`docs/technical/`](docs/technical/)

## For AI agents

Read `AGENTS.md` first. For gameplay/product work, read the North Star and check the feature freeze before editing code.
