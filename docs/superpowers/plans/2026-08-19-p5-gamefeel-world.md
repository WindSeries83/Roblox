# Rift Beasts — Monde vivant (P4.5) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rendre le monde vivant et pratique (couveuse, arche de faille permanente, créatures cliquables, feedbacks, direction) et consolider la bible de design en audit à statuts.

**Architecture:** 100 % client + 1 modification serveur localisée (RiftService : arche persistante + payload `NextAt`). Nouveaux modules client (`CouveusePanel`, `CreatureHud`, `ObjectiveBanner`, `Fx.FloatText`) branchés sur les remotes existantes. Objets 3D créés dans le place (place-owned, règle du décor V1). La couveuse vit dans Workspace (créée via MCP), l'arche est construite par le serveur au démarrage.

**Tech Stack:** Luau vanilla, UiKit maison, remotes existantes (`BuyEgg`, `HatchEgg`, `EquipItem`, `UnequipItem`, `EvolveCreature`, `MarketList`, `RiftWorld`), ProximityPrompt + ClickDetector, ParticleEmitter.

**Spec:** `docs/superpowers/specs/2026-08-19-p5-gamefeel-world-design.md`

## Global Constraints

- Aucune nouvelle logique d'économie serveur ; aucune mutation d'Essence côté client
- Réutiliser les remotes existantes — zéro nouveau RemoteEvent
- **Rythme faille inchangé : `RIFT_INTERVAL = 600`, `RIFT_ACTIVE_SECONDS = 180`** (aucune modif de ces constantes)
- Objets 3D place-owned (perdus si place régénéré — même règle que le décor V1)
- stylua + selene propres ; tests en pattern `t.test` + `expect` (RunUnitTest)
- Rojo peut être désynchronisé : pousser les scripts dans Studio via `roblox_multi_edit` / recréation d'instance quand la sync ne suit pas

---

### Task 0: Spec + audit bible design (docs)

**Files:**
- Create: `docs/superpowers/specs/2026-08-19-p5-gamefeel-world-design.md`
- Modify: `docs/RIFT_BEASTS_1_bible_design.md`
- Create: `docs/superpowers/plans/2026-08-19-p5-gamefeel-world.md`

**Interfaces:**
- Produces: la spec (source de vérité du lot), la bible auditée (statuts ✅/🔶/⛔, §8bis Vie du monde, §9 écarts, §10 reste à faire)

- [ ] **Step 1: Écrire la spec** (fait — ce plan s'appuie dessus)
- [ ] **Step 2: Auditer la bible** : statuts par section, §0 « P4 livré », §8bis, §9, §10 (fait)
- [ ] **Step 3: Commit docs**

```bash
git add docs/superpowers/specs docs/superpowers/plans docs/RIFT_BEASTS_1_bible_design.md
git commit -m "docs: spec + plan P4.5 monde vivant, audit bible design (statuts, écarts, vie du monde)"
```

---

### Task 1: RiftService — arche permanente + RiftWorld NextAt

**Files:**
- Modify: `src/server/Services/RiftService.luau`
- Modify: `src/client/Ui.luau` (affichage compte à rebours via RiftWorld.NextAt)
- Verify: Studio via `roblox_execute_luau`/`roblox_multi_edit`

**Interfaces:**
- Consumes: `Config.RIFT_PORTAL_POSITION`, `Net.RiftWorld`
- Produces: `RiftWorld` payload `{ Active: boolean, EndsAt: number, NextAt: number }` — NextAt = `os.clock() + interval` quand inactif, 0 quand actif. L'arche existe en permanence dans Workspace (nom `RiftArch`).

- [ ] **Step 1: Remplacer BuildPortal par une arche permanente**

RiftService garde le cycle existant mais construit l'arche UNE fois au `Start()` et ne la détruit plus :

```lua
local arch: Model? = nil

local function BuildArch()
	local model = Instance.new("Model")
	model.Name = "RiftArch"
	local arch = Instance.new("Part")
	arch.Name = "Arch"
	arch.Shape = Enum.PartType.Cylinder
	arch.Size = Vector3.new(12, 20, 6)
	arch.Material = Enum.Material.Stone
	arch.Color = Color3.fromRGB(40, 40, 55)
	arch.Anchored = true
	arch.CanCollide = false
	arch.CanQuery = false
	arch.CanTouch = false
	arch.CastShadow = false
	arch.Parent = model
	local light = Instance.new("PointLight")
	light.Name = "Veille"
	light.Color = Color3.fromRGB(140, 60, 255)
	light.Brightness = 0.5
	light.Range = 12
	light.Parent = arch
	model.PrimaryPart = arch
	model:PivotTo(CFrame.new(Config.RIFT_PORTAL_POSITION))
	model.Parent = Workspace
	return model
end
```

- [ ] **Step 2: Cycle actif/inactif sans destroy**

Dans la boucle du `Start()` : remplacer `portal = BuildPortal()` par un état d'illumination sur `arch` (mettre `Veille.Brightness` à 3 + burst de particules à l'ouverture, retour à 0.5 à la fermeture), et garder `portal.PrimaryPart.Touched` branché sur l'arche (une seule fois au Start).

- [ ] **Step 3: RiftWorld.NextAt**

```lua
local nextAt = 0
-- dans la boucle, avant task.wait(interval) :
nextAt = os.clock() + interval
-- à l'ouverture :
nextAt = 0
Net.RiftWorld:FireAllClients({ Active = worldActive, EndsAt = worldEndsAt, NextAt = nextAt })
```

- [ ] **Step 4: Ui.luau — compte à rebours**

Dans le handler `Net.RiftWorld` existant de `Ui.luau` : si `world.Active`, afficher « Faille active — entre dans l'arche ! » ; sinon si `world.NextAt > 0`, afficher « Prochaine faille dans M:SS » (mis à jour par une boucle 1 s tant que le label est visible, via `FormatCountdown` local).

- [ ] **Step 5: Playtest MCP** — arche visible en Edit/Play, cycle actif/inactif, NextAt correct, compte à rebours affiché

- [ ] **Step 6: stylua + selene sur les fichiers modifiés, commit**

---

### Task 2: Feedbacks — Fx.FloatText + delta Essence + réaction clic

**Files:**
- Modify: `src/client/Fx.luau`
- Modify: `src/client/CreatureDisplay.luau`

**Interfaces:**
- Produces: `Fx.FloatText(worldPos: Vector3, text: string, color: Color3)` — BillboardGui texte qui monte de ~2 studs et fade sur 1 s puis se détruit

- [ ] **Step 1: `Fx.FloatText`**

```lua
function Fx.FloatText(worldPos: Vector3, text: string, color: Color3)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.CFrame = CFrame.new(worldPos)
	part.Parent = game:GetService("Workspace")
	local gui = Instance.new("BillboardGui")
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(120, 30)
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.Size = UDim2.fromScale(1, 1)
	label.Text = text
	label.Parent = gui
	local start = os.clock()
	task.spawn(function()
		while os.clock() - start < 1 and part.Parent do
			part.CFrame = CFrame.new(worldPos + Vector3.new(0, (os.clock() - start) * 2, 0))
			label.TextTransparency = (os.clock() - start)
			task.wait()
		end
		part:Destroy()
	end)
end
```

- [ ] **Step 2: Delta Essence → +N flottant** dans `CreatureDisplay.luau` : garder `lastEssence` ; sur `Net.Sync`, si `state.Essence > lastEssence`, `Fx.FloatText(compteur world position ou position du joueur, "+N", TINTS.ACCENT)` puis `lastEssence = state.Essence`.

- [ ] **Step 3: Réaction au clic créature** : ajouter un `ClickDetector` sur chaque clone (enveloppe invisible, `MaxActivationDistance` ~40) ; au clic : `Fx.Burst(primary, displayColor, 26)` + amplifie le bob une fois (flag `popUntil`).

- [ ] **Step 4: stylua + selene + playtest MCP (les +N apparaissent au tick, le clic fait saut + particules)**

- [ ] **Step 5: Commit**

---

### Task 3: Couveuse 3D + CouveusePanel

**Files:**
- Create: `src/client/Panels/CouveusePanel.luau`
- Modify: place (via MCP) : socle + œuf + ProximityPrompt dans Workspace

**Interfaces:**
- Consumes: `state.Eggs`, `Net.BuyEgg`, `Net.HatchEgg`, `Config.EGG_PRICES`, `Config.EGG_RARITY_WEIGHTS`
- Produces: panneau BillboardGui « CouveusePanel » ouvert par `ProximityPrompt.Triggered`

- [ ] **Step 1: Objet couveuse dans le place (MCP, Edit)** : socle cylindrique (Neon violet) ~(x=-12, y=0, z=3), œuf sphérique Neon au-dessus, `ProximityPrompt` (ActionText « Ouvrir la couveuse », MaxActivationDistance 8), `BillboardGui` (taille 260×220, `StudsOffsetWorldSpace` au-dessus de la couveuse) — le tout dans un Model `Couveuse` (place-owned, comme le décor).

- [ ] **Step 2: `CouveusePanel.luau`** : module client écoutant `ProximityPrompt.Triggered` → construit l'UI dans le BillboardGui : titre « Couveuse », liste des œufs (depuis le dernier state Sync) avec bouton « Éclore » (`Net.HatchEgg:FireServer(egg.Id)`), rangée d'achat Common/Uncommon/Rare (prix de `Config.EGG_PRICES`, `Net.BuyEgg:FireServer(tier)`). Refresh sur `Net.Sync`.

- [ ] **Step 3: stylua + selene + playtest MCP** : s'approcher → prompt → panneau → acheter/éclore → créature apparaît dans l'enclos

- [ ] **Step 4: Commit**

---

### Task 4: Créatures cliquables — CreatureHud

**Files:**
- Create: `src/client/CreatureHud.luau`
- Modify: `src/client/CreatureDisplay.luau` (ClickDetector déjà posé en Task 2 → lier le panneau)

**Interfaces:**
- Consumes: `state.Creatures`, `state.Items`, `Net.EquipItem`, `Net.UnequipItem`, `Net.EvolveCreature`, `Net.MarketList`, `Evolution.CanEvolve`, `Sanctuary.MaxCreatures`
- Produces: panneau contextuel (ScreenGui ancré) ouvert par clic sur une créature

- [ ] **Step 1: `CreatureHud.luau`** : `Open(creature, state)` → ScreenGui centré-bas : titre (rareté colorée + nom), stade/niveau, barre XP, bouton Équiper (cycle dans `state.Items` → `Net.EquipItem`), bouton Évoluer (si `Evolution.CanEvolve` → `Net.EvolveCreature`), champ prix pré-rempli (suggéré : `math.max(10, math.floor(EGG_PRICES.CommonEgg * (1 + (RarityRank-1)*2)))`) + bouton Vendre → `Net.MarketList(creature.Id, price)`. Fermeture au clic hors panneau (`MouseButton1Click` sur un overlay transparent).

- [ ] **Step 2: Liaison dans `CreatureDisplay.luau`** : au clic du ClickDetector, appeler `CreatureHud.Open(creature, lastState)` (garder `lastState` depuis `Net.Sync`).

- [ ] **Step 3: stylua + selene + playtest MCP** : clic → panneau → équiper un Cœur → évoluer → vendre (prix suggéré) → la créature quitte la grille et le listing apparaît

- [ ] **Step 4: Commit**

---

### Task 5: ObjectiveBanner + tests

**Files:**
- Create: `src/client/ObjectiveBanner.luau`
- Create: `src/tests/unit/Cases/Objective_Test.luau`
- Modify: `src/client/Ui.luau` (instancier le banner, refresh sur Sync)

**Interfaces:**
- Produces: `ObjectiveBanner.Pick(state) -> { Text: string, Priority: number } | nil` et `ObjectiveBanner.FormatCountdown(seconds: number) -> string`
- Priority : faille active (100) > quêtes réclamables (80) > premier œuf jamais éclos (60) > Renaissance atteignable (40)

- [ ] **Step 1: écrire `Objective_Test.luau`** (priorités, formatage « 9:32 », cas vides, premier œuf)

- [ ] **Step 2: run test → FAIL attendu** (module absent)

- [ ] **Step 3: implémenter `ObjectiveBanner.luau`** : fonctions pures `Pick`/`FormatCountdown` + `Mount(parent)`/`Refresh(state)` qui gèrent le bandeau bas d'écran (Frame translucide + texte, ZIndex 40, hors menu).

- [ ] **Step 4: run test → PASS**

- [ ] **Step 5: `Ui.luau`** : `ObjectiveBanner.Mount(ui)` après création de l'UI ; `ObjectiveBanner.Refresh(state)` dans `RefreshAll` ; pour la faille, utiliser `RiftWorld` (state fourni par le banner via son propre écouteur `Net.RiftWorld`).

- [ ] **Step 6: stylua + selene + run complet des tests (tous verts) + commit**

---

### Task 6: Vérifications finales + playtest bout en bout

- [ ] **Step 1: stylua src + selene src** (0 erreur)
- [ ] **Step 2: run complet des tests** (~118, 0 échec)
- [ ] **Step 3: playtest MCP bout en bout** : tutoriel → couveuse (éclosion dans le monde) → clic créature (équiper/évoluer/vendre) → arche + compte à rebours → faille active (entrer, gagner) → +N Essence visibles → bandeau direction → marché/duels inchangés
- [ ] **Step 4: mise à jour `docs/RIFT_BEASTS_2_plan_production.md`** (coche P4.5, note playtest)

### Task 7: Commit

- [ ] Commit unique « P4.5: monde vivant (couveuse, arche, clics créatures, feedbacks, direction) + audit bible design »
