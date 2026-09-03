# Plan d'implémentation — Lot 4 : correctifs playtest du 24/08

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Corriger les 8 problèmes remontés au playtest (placement des œufs, créature dupliquée, synchro morte achats/réclamations, hotbar d'œufs, tri des raretés, portraits, lisibilité arbre).

**Architecture:** Le jeu est un repo Rojo Luau — Services serveur (`src/server/Services/*`) autoritaires, Controllers client (`src/client/*`), modules partagés (`src/shared/*`), remotes typés (`Net`). Les bugs 7+8 partagent la même racine structurelle (mutations serveur sans push de synchro + rejets silencieux) : un seul lot de correctifs les couvre. La synchro passe par la boucle Heartbeat d'`EssenceService` (1 Hz) → elle doit devenir incassable.

**Tech Stack:** Roblox Luau, Rojo, selene (lint), framework de tests maison `RunUnitTest` (`expect.equal/near/truthy/deepEqual…`), tests dans `src/tests/unit/Cases/<Module>_Test.luau`, exécution via MCP Studio (`roblox_execute_luau`).

**Spec:** Retour de playtest utilisateur du 24/08 (8 symptômes). Diagnostic complet intégré ci-dessous (fichiers:lignes vérifiés).

## Traçabilité symptôme → tâche

| # | Symptôme | Cause racine | Tâche |
|---|----------|--------------|-------|
| 7 | Réclamer objectifs : rien | `Ui.luau:932` refresh avec state périmé + pas de Sync après claim + tick sync fragile | T1, T2, T3 |
| 8 | Achat œufs bloqué ensuite | Rejets serveur silencieux (essence/verrou/cap/cooldown) + pas de Sync après BuyEgg | T2, T4 |
| 1 | Œufs à côté de la couveuse | `Incubation.SlotCFrame` = anneau r=4 autour ; raycast terrain au lieu du dessus couveuse | T5 |
| 2 | 2 créatures à l'éclosion | Suspect : régénération procédurale des clones (~3 s post-spawn) — investigation live + garde-fous | T6 |
| 4 | Raretés en désordre | Liste d'œufs rendue sans tri (ordre d'acquisition) | T7 |
| 3 | Hotbar absente | Feature nouvelle (remote `PlaceEgg` déjà prêt) | T8 |
| 5 | Portraits moches | ViewportFrames 3D via `CreaturePortrait` — neutralisation 1 fichier, 6 sites | T9 |
| 6 | Arbre illisible | Glyphes seuls, lignes ~10 % de contraste, pas d'en-têtes de branche | T10 |

## Global Constraints

- Repo Rojo : **un seul** processus `rojo serve default.project.json` (`Get-Process rojo` ≤ 2 PID parent/enfant).
- Avant tout playtest : vérifier la synchro Rojo en mode Edit (marqueur disque présent dans Studio) ; sinon relancer rojo + demander à l'humain de cliquer **Connect**.
- `[profilestore]: Roblox API services unavailable` en Studio non publié = mock attendu, pas une erreur.
- Sécurité : aucune nouvelle confiance au client ; validations serveur existantes conservées.
- Style repo : commentaires FR courts qui expliquent le *pourquoi* ; `task.*` (jamais `wait()` legacy) ; `pcall` autour des opérations faillibles.
- Lint obligatoire avant chaque commit : `selene src` (bash, racine repo).
- Tests : `roblox_execute_luau` (datamodel **Edit**) avec `require(game:GetService("ServerStorage").UnitTest.RunUnitTest)()` → attendu `[SUMMARY] N run, N passed, 0 failed`.
- Captures écran : toujours faire analyser par l'agent `eyes` (tool `task`) avant de conclure.

---

### Task 1: Tick de synchro incassable (EssenceService)

**Files:**
- Modify: `src/server/Services/EssenceService.luau:98-114`

**Interfaces:**
- Consumes: rien de nouveau.
- Produces: boucle Heartbeat où une erreur sur un profil n'empêche plus `dataSync:Send` pour les autres joueurs. Toutes les tâches suivantes reposent sur cette garantie.

- [ ] **Step 1: Appliquer le wrapper pcall par joueur**

Remplacer le corps de la boucle (lignes 105-114) :

```lua
		for player, profile in pairs(saveService.Profiles) do
			-- Un profil fautif ne doit pas couper la synchro globale : chaque joueur est isolé.
			pcall(function()
				local rate = EssenceService.GetRate(player)
				if rate > 0 then
					profile.Data.Essence += rate
					profile.Data.Stats.TotalEssenceEarned += rate
					profile.Data.LastPlayed = os.time()
					questService:OnEssenceGained(player, rate, "Passive")
				end
				dataSync:Send(player)
			end)
		end
```

- [ ] **Step 2: Vérifier lint**
Run: `selene src` — Expected: 0 warning.

- [ ] **Step 3: Commit**

```bash
git add src/server/Services/EssenceService.luau
git commit -m "fix(sync): tick essence résilient aux erreurs de profil"
```

---

### Task 2: Push de synchro après mutation serveur (BuyEgg + QuestClaim)

**Files:**
- Modify: `src/server/Services/HatchService.luau` (locals ~ligne 18-32, `Start()` ligne 247-277)
- Modify: `src/server/Services/QuestService.luau:241`

**Interfaces:**
- Produces: après un achat ou un claim réussi, le client reçoit `Net.Sync` immédiatement (≤ instantané) en plus du tick 1 s.

- [ ] **Step 1: HatchService — déclarer et résoudre dataSync**

Ajouter avec les autres locals (après ligne 30 `local incubationService`) :

```lua
local dataSync
```

Dans `HatchService:Start()`, après `eclipseService = ...` :

```lua
	dataSync = container:Get("DataSync")
```

- [ ] **Step 2: HatchService — envoyer la synchro après grant**

Dans le handler `Net.BuyEgg.OnServerEvent`, juste après le bloc `if profile and profile.Data.Entitlements.AutoHatch then ... end` (fin du chemin succès, avant la fermeture du handler) :

```lua
		-- Feedback immédiat : l'œuf et la déduction d'essence apparaissent sans attendre le tick 1 s.
		dataSync:Send(player)
```

- [ ] **Step 3: QuestService — idem après claim**

Dans le handler `Net.QuestClaim.OnServerEvent`, après `SyncQuests(player)` (ligne 241), ajouter :

```lua
				container:Get("DataSync"):Send(player)
```

- [ ] **Step 4: Vérifier lint + tests**
Run: `selene src` ; puis tests unitaires (Edit Luau) : `require(game:GetService("ServerStorage").UnitTest.RunUnitTest)()` — Expected: 0 failed (Purchase_Test, Objective_Test passent toujours).

- [ ] **Step 5: Commit**

```bash
git add src/server/Services/HatchService.luau src/server/Services/QuestService.luau
git commit -m "fix(sync): pousse une synchro après achat d'oeuf et réclamation de quête"
```

---

### Task 3: Refresh des quêtes avec données fraîches (bouton fantôme)

**Files:**
- Modify: `src/client/Ui.luau:928-935`

**Interfaces:**
- Produces: après `QuestsSync`, tous les panneaux se rafraîchissent avec les quêtes à jour → le bouton « Réclamer » devient « Récompense réclamée » instantanément.

- [ ] **Step 1: Fusionner payload.Quests dans le state affiché**

Remplacer :

```lua
	if payload.Quests then
		UpdateQuestBadge(payload.Quests)
		for _, panel in panels do
			if panel.module.Refresh then
				panel.module.Refresh(state)
			end
		end
	end
```

par :

```lua
	if payload.Quests and state then
		-- Le state local est périmé côté quêtes : fusionner avant refresh,
		-- sinon le bouton Réclamer reste affiché après un claim réussi.
		state.Quests = payload.Quests
		UpdateQuestBadge(payload.Quests)
		for _, panel in panels do
			if panel.module.Refresh then
				panel.module.Refresh(state)
			end
		end
	end
```

- [ ] **Step 2: Commit**

```bash
git add src/client/Ui.luau
git commit -m "fix(ui): rafraîchit les quêtes avec les données fraiches du QuestsSync"
```

---

### Task 4: Signaler l'essence insuffisante (affordance achat)

**Files:**
- Modify: `src/client/Panels/EggPanel.luau:27-38, 178-181`
- Modify: `src/client/CouveusePanel.luau:17-35`

**Interfaces:**
- Consumes: `state.Essence` (déjà synchronisé 1×/s), `Config.EGG_PRICES`.
- Produces: bouton rouge « essence insuffisante » quand le solde < prix — le joueur comprend enfin pourquoi « ça ne fait rien ».

- [ ] **Step 1: EggPanel — état essence courant**

Après la déclaration `lockedTiers` (ligne 16), ajouter :

```lua
local currentEssence = 0
```

Au début de `EggPanel.Refresh` (avant `RefreshBuyButtons()`), ajouter :

```lua
	currentEssence = math.floor(state.Essence or 0)
```

Remplacer `RefreshBuyButtons` par :

```lua
local function RefreshBuyButtons()
	for tier, button in buyButtons do
		local required = lockedTiers[tier]
		local price = Config.EGG_PRICES[tier]
		if required then
			button.Text = `{UiKit.EGG_TIER_NAMES[tier]} 🔒\nRang de sanctuaire {required} requis`
			button.TextColor3 = Color3.fromRGB(140, 140, 150)
		elseif currentEssence < price then
			button.Text = `{UiKit.EGG_TIER_NAMES[tier]}\n{price} Essence — insuffisant`
			button.TextColor3 = Color3.fromRGB(255, 120, 120)
		else
			button.Text = `{UiKit.EGG_TIER_NAMES[tier]}\n{price} Essence`
			button.TextColor3 = UiKit.TINTS.WHITE
		end
	end
end
```

- [ ] **Step 2: CouveusePanel — même logique**

Remplacer `RefreshBuyButtons` (utilise `lastState` déjà disponible) :

```lua
local function RefreshBuyButtons()
	local essence = math.floor(lastState and lastState.Essence or 0)
	for tier, button in buyButtons do
		local required = lockedTiers[tier]
		local price = Config.EGG_PRICES[tier]
		if required then
			button.Text = `{UiKit.EGG_TIER_NAMES[tier]} 🔒\nRang {required}`
			button.TextColor3 = Color3.fromRGB(140, 140, 150)
		elseif essence < price then
			button.Text = `{UiKit.EGG_TIER_NAMES[tier]}\n{price} — insuffisant`
			button.TextColor3 = Color3.fromRGB(255, 120, 120)
		else
			button.Text = `{UiKit.EGG_TIER_NAMES[tier]}\n{price}`
			button.TextColor3 = UiKit.TINTS.WHITE
		end
	end
end
```

- [ ] **Step 3: Commit**

```bash
git add src/client/Panels/EggPanel.luau src/client/CouveusePanel.luau
git commit -m "feat(ui): signale l'essence insuffisante sur les boutons d'achat d'oeufs"
```

---

### Task 5: Œufs posés SUR la couveuse

**Files:**
- Modify: `src/shared/Incubation.luau` (fichier entier)
- Modify: `src/server/Services/IncubationService.luau:68-102` (`GroundedOrigin`)
- Test: `src/tests/unit/Cases/Incubation_Test.luau` (réécriture)

**Interfaces:**
- Produces: `Incubation.SLOT_RADIUS` (nombre, calibrage visuel) ; `SlotCFrame(origin, index)` renvoie des slots compactes sur le plateau ; `GroundedOrigin` renvoie le Y du dessus réel de la couveuse.

- [ ] **Step 1: Écrire le test (échouant)** — remplacer tout `Incubation_Test.luau` :

```lua
return function(t)
	local expect = t.expect
	local Incubation = require(game.ReplicatedStorage.Shared.Incubation)

	t.test("MAX_PLACED vaut 3", function()
		expect.equal(Incubation.MAX_PLACED, 3)
	end)

	-- Slots compactes posés sur le plateau : rayon constant, angles réguliers, à plat.
	t.test("slots à rayon constant, angles réguliers, y constant", function()
		local origin = Vector3.new(10, 5, -3)
		local positions = {}
		for i = 1, Incubation.MAX_PLACED do
			local pos = Incubation.SlotCFrame(origin, i).Position
			expect.near((pos - origin).Magnitude, Incubation.SLOT_RADIUS, 0.01)
			expect.near(pos.Y, origin.Y, 0.01)
			table.insert(positions, pos)
		end
		local d12 = (positions[1] - positions[2]).Magnitude
		local d23 = (positions[2] - positions[3]).Magnitude
		local d31 = (positions[3] - positions[1]).Magnitude
		expect.near(d12, d23, 0.01)
		expect.near(d23, d31, 0.01)
	end)

	-- Pas de chevauchement : distance centre-à-centre > diamètre coquille (1,4).
	t.test("distance inter-slots supérieure au diamètre d'un oeuf", function()
		local a = Incubation.SlotCFrame(Vector3.zero, 1).Position
		local b = Incubation.SlotCFrame(Vector3.zero, 2).Position
		expect.truthy((a - b).Magnitude > 1.4)
	end)

	t.test("index 4 == index 1 (cycle complet)", function()
		local first = Incubation.SlotCFrame(Vector3.zero, 1).Position
		local wrapped = Incubation.SlotCFrame(Vector3.zero, Incubation.MAX_PLACED + 1).Position
		expect.near((first - wrapped).Magnitude, 0, 0.01)
	end)
end
```

- [ ] **Step 2: Run test → FAIL attendu** (`SLOT_RADIUS` absent, rayon actuel = 4)

- [ ] **Step 3: Implémenter** — remplacer tout `src/shared/Incubation.luau` :

```lua
local Incubation = {}

Incubation.MAX_PLACED = 3

-- Rayon du triangle de slots, calibrable après capture écran si la couveuse
-- s'avère plus petite que prévu.
Incubation.SLOT_RADIUS = 1.2

-- Slots compacts posés SUR le plateau : triangle régulier, chaque œuf face au centre.
function Incubation.SlotCFrame(origin: Vector3, index: number): CFrame
	local angle = (index - 1) * (2 * math.pi / Incubation.MAX_PLACED) - math.pi / 2
	local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * Incubation.SLOT_RADIUS
	return CFrame.lookAt(origin + offset, origin)
end

return Incubation
```

- [ ] **Step 4: GroundedOrigin — Y du dessus de la couveuse**

Remplacer le bloc raycast (lignes 87-101 de `GroundedOrigin`, entre le garde `if not base` et le return final) par :

```lua
	-- La couveuse étant partiellement enterrée, on vise son propre dessus :
	-- raycast vertical restreint AU modèle (sinon on touche le terrain autour).
	if model then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { model }
		local hit = Workspace:Raycast(Vector3.new(base.X, base.Y + 50, base.Z), Vector3.new(0, -200, 0), params)
		if hit then
			return Vector3.new(base.X, hit.Position.Y, base.Z)
		end
	end

	-- Fallback historique : sol sous la couveuse.
	local from = Vector3.new(base.X, base.Y + 50, base.Z)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = {}
	if player.Character then
		table.insert(exclude, player.Character)
	end
	for _, eggs in placed do
		for _, eggModel in eggs do
			table.insert(exclude, eggModel)
		end
	end
	params.FilterDescendantsInstances = exclude
	local hit = Workspace:Raycast(from, Vector3.new(0, -100, 0), params)
	return if hit then Vector3.new(base.X, hit.Position.Y, base.Z) else base + Vector3.new(0, 4, 0)
```

- [ ] **Step 5: Run test → PASS** + lint `selene src`

- [ ] **Step 6: Vérification visuelle (playtest)** — placer 3 œufs, capture écran de la couveuse, analyse par agent `eyes`. Si les œufs débordent du plateau : ajuster `SLOT_RADIUS` et rejouer la capture.

- [ ] **Step 7: Commit**

```bash
git add src/shared/Incubation.luau src/server/Services/IncubationService.luau src/tests/unit/Cases/Incubation_Test.luau
git commit -m "fix(monde): pose les oeufs sur le plateau de la couveuse"
```

---

### Task 6: Créature en double — garde-fous + instrumentation

**Files:**
- Modify: `src/client/CreatureDisplay.luau:96-109` (`PrepareClone`), `~192-197` (boucle création)

**Interfaces:**
- Produces: clones d'affichage sans scripts procéduraux (plus de régénération post-spawn) + dédup workspace par `CreatureId`.

- [ ] **Step 1: PrepareClone — retirer les scripts procéduraux**

```lua
local function PrepareClone(model: Model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BaseScript") then
			-- Les scripts procéduraux régénèrent les parts ~3 s après spawn et peuvent
			-- dupliquer le visuel : les clones d'affichage doivent rester inertes.
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
		end
	end
	if not model.PrimaryPart then
		local first = model:FindFirstChildWhichIsA("BasePart", true)
		if first then
			model.PrimaryPart = first
		end
	end
end
```

- [ ] **Step 2: Dédup avant création** — dans `CreatureDisplay.Refresh`, au début du bloc `if not model or not model.Parent then`, insérer avant `CreatureTemplates.Get` :

```lua
			-- Garde-fou : un doublon résiduel (ex-régénération procédurale) est recyclé.
			for _, other in sanctuary:GetChildren() do
				if other ~= model and other:GetAttribute("CreatureId") == creature.Id then
					other:Destroy()
				end
			end
```

- [ ] **Step 3: Instrumentation de repro (playtest)** — démarrer le jeu, acheter + éclore 3 œufs, puis mesurer l'écart données/visuel :
  - Serveur (execute Luau **Server**) :
```lua
local Players = game:GetService("Players")
local player = Players:GetPlayers()[1]
local bootstrap = require(game.ServerScriptService.Bootstrap)
local profile = bootstrap.Services.SaveService.Profiles[player]
print("[diag] creatures en data:", #profile.Data.Creatures)
for _, c in profile.Data.Creatures do print(" ", c.Id, c.SpeciesId) end
```
  - Client (execute Luau **Client**) :
```lua
local folder = workspace:FindFirstChild("SanctuaryDisplay")
local count = 0
if folder then
	for _, m in folder:GetChildren() do
		count += 1
		print(m.Name, m:GetAttribute("CreatureId"))
	end
end
print("[diag] modeles affiches:", count)
```
  - **Attendu après fix : les deux compteurs sont égaux et stables dans le temps** (re-vérifier 10 s après l'éclosion). S'il reste un doublon hors `SanctuaryDisplay`, chercher dans `workspace` un modèle porteur du même attribut `CreatureId` et rapporter sa position/parent — c'est la donnée manquante pour le vrai root cause.

- [ ] **Step 4: Capture écran sanctuaire → analyse `eyes`** (une seule créature visible par œuf éclos).

- [ ] **Step 5: Commit**

```bash
git add src/client/CreatureDisplay.luau
git commit -m "fix(monde): garde-fou contre la duplication visuelle des creatures"
```

---

### Task 7: Tri de l'inventaire d'œufs

**Files:**
- Modify: `src/shared/Sanctuary.luau` (après `EGG_TIERS`, ligne 31)
- Modify: `src/client/Panels/EggPanel.luau:184`
- Modify: `src/client/CouveusePanel.luau:37`
- Test: `src/tests/unit/Cases/Sanctuary_Test.luau` (ajout d'un cas)

**Interfaces:**
- Produces: `Sanctuary.SortEggs(eggs: { any }): { any }` — palier croissant (même ordre que la boutique), ancienneté au sein d'un palier. Consommé aussi par la Task 8.

- [ ] **Step 1: Écrire le test (échouant)** — ajouter dans la fonction retournée de `Sanctuary_Test.luau` :

```lua
	t.test("SortEggs : palier croissant puis ancienneté", function()
		local eggs = {
			{ Id = "b", Tier = "RareEgg", Timestamp = 10 },
			{ Id = "a", Tier = "CommonEgg", Timestamp = 20 },
			{ Id = "c", Tier = "CommonEgg", Timestamp = 5 },
		}
		local sorted = Sanctuary.SortEggs(eggs)
		expect.equal(sorted[1].Id, "c")
		expect.equal(sorted[2].Id, "a")
		expect.equal(sorted[3].Id, "b")
	end)
```

(`Sanctuary` déjà requis en tête du fichier ; sinon ajouter le require local au test.)

- [ ] **Step 2: Run → FAIL** (`SortEggs` nil)

- [ ] **Step 3: Implémenter** dans `src/shared/Sanctuary.luau` :

```lua
-- Tri déterministe de l'inventaire : palier croissant (ordre boutique),
-- puis ancienneté. table.sort n'est pas stable -> tiebreak explicite.
function Sanctuary.SortEggs(eggs: { any }): { any }
	local tierRank = {}
	for rank, tier in Sanctuary.EGG_TIERS do
		tierRank[tier] = rank
	end
	local sorted = table.clone(eggs)
	table.sort(sorted, function(a, b)
		local ra, rb = tierRank[a.Tier] or 0, tierRank[b.Tier] or 0
		if ra ~= rb then
			return ra < rb
		end
		return (a.Timestamp or 0) < (b.Timestamp or 0)
	end)
	return sorted
end
```

- [ ] **Step 4: Consommer** — remplacer dans `EggPanel.Refresh` :
`for i, egg in state.Eggs do` → `for i, egg in Sanctuary.SortEggs(state.Eggs) do`
et dans `CouveusePanel.Refresh` :
`for i, egg in lastState.Eggs do` → `for i, egg in Sanctuary.SortEggs(lastState.Eggs) do`

- [ ] **Step 5: Run tests → PASS** + lint

- [ ] **Step 6: Commit**

```bash
git add src/shared/Sanctuary.luau src/client/Panels/EggPanel.luau src/client/CouveusePanel.luau src/tests/unit/Cases/Sanctuary_Test.luau
git commit -m "feat(ui): trie l'inventaire d'oeufs par palier puis ancienneté"
```

---

### Task 8: Barre d'œufs permanente (hotbar)

**Files:**
- Create: `src/client/EggHotbar.luau`
- Modify: `src/client/Ui.luau:976-977` (wiring `RequireWithRetry`)

**Interfaces:**
- Consumes: `Sanctuary.SortEggs` (T7), `Net.PlaceEgg:FireServer(eggId)` (existant, validé serveur), pattern self-mounting de `CouveusePanel`.
- Produces: placement d'œuf sans ouvrir le menu. Position bas-GAUCHE (le bas-centre est occupé par actionBar 424 px + riftHud).

- [ ] **Step 1: Créer `src/client/EggHotbar.luau`** :

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Sanctuary = require(ReplicatedStorage.Shared.Sanctuary)
local UiKit = require(script.Parent.UiKit)

-- Barre d'œufs en bas à gauche : clique = place l'œuf à la couveuse (Net.PlaceEgg),
-- sans passer par le menu. Se reconstruit à chaque Net.Sync (Clear garde le layout).
local EggHotbar = {}

local SHELL_COLORS = {
	CommonEgg = Color3.fromRGB(235, 230, 215),
	UncommonEgg = Color3.fromRGB(140, 200, 170),
	RareEgg = Color3.fromRGB(90, 150, 230),
	EpicEgg = Color3.fromRGB(160, 90, 220),
	LegendaryEgg = Color3.fromRGB(230, 190, 80),
}

local MAX_SHOWN = 8

function EggHotbar.Start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local ui = playerGui:WaitForChild("RiftBeastsUi", 60)
	if not ui then
		return
	end

	local bar = UiKit.Create("Frame", {
		Name = "EggHotbar",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 12, 1, -12),
		Size = UDim2.fromOffset(0, 46),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Parent = ui,
	})
	UiKit.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = bar,
	})

	Net.Sync.OnClientEvent:Connect(function(state)
		UiKit.Clear(bar)
		local eggs = Sanctuary.SortEggs(state and state.Eggs or {})
		UiKit.Create("TextLabel", {
			Name = "HotbarHint",
			BackgroundTransparency = 1,
			TextColor3 = UiKit.TINTS.WHITE,
			TextTransparency = 0.35,
			Font = Enum.Font.Gotham,
			TextSize = 11,
			Size = UDim2.fromOffset(0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = if #eggs > 0 then `Œufs ({#eggs}) →` else "",
			LayoutOrder = 0,
			Parent = bar,
		})
		for i, egg in eggs do
			if i > MAX_SHOWN then
				break
			end
			local slot = UiKit.Create("TextButton", {
				Name = `Hotbar_{egg.Id}`,
				BackgroundColor3 = SHELL_COLORS[egg.Tier] or SHELL_COLORS.CommonEgg,
				Size = UDim2.fromOffset(44, 44),
				Text = "",
				LayoutOrder = i,
				Parent = bar,
			})
			UiKit.Corner(slot)
			slot.Activated:Connect(function()
				Net.PlaceEgg:FireServer(egg.Id)
			end)
		end
	end)
end

task.spawn(function()
	EggHotbar.Start()
end)

return EggHotbar
```

- [ ] **Step 2: Wiring** — dans `Ui.luau`, après `RequireWithRetry(script.Parent.CouveusePanel)` (ligne 977), ajouter :

```lua
RequireWithRetry(script.Parent.EggHotbar)
```

- [ ] **Step 3: Vérification (playtest)** — avoir 4+ œufs : pastilles visibles bas-gauche triées par rareté ; clic → œuf apparaît sur la couveuse (T5) ; slots plein (3) → clic suivant sans effet visible = comportement actuel accepté (le compteur `Œufs (N)` montre le stock réel). Capture écran → `eyes`. Aucun chevauchement avec actionBar/riftHud.

- [ ] **Step 4: Commit**

```bash
git add src/client/EggHotbar.luau src/client/Ui.luau
git commit -m "feat(ui): barre d'oeufs permanente pour placer sans ouvrir le menu"
```

---

### Task 9: Neutraliser les portraits 3D

**Files:**
- Modify: `src/client/CreaturePortrait.luau:65-108` (corps de `Show` uniquement)

**Interfaces:**
- Signature inchangée (`Show(state, speciesId?, rarity?, mutation?, silhouette?)`) → les 6 appels (Ui reveal ×2, HatchCinematic, IndexPanel, SanctuaryPanel) continuent de fonctionner ; remise en service future = restaurer le corps (git).

- [ ] **Step 1: Remplacer le corps de `Show`** (garder la ligne de signature telle quelle, paramètres préfixés `_` pour selene) :

```lua
function CreaturePortrait.Show(_state: any, _speciesId: string?, _rarity: string?, _mutation: any, _silhouette: boolean?)
	-- ponytail: portraits 3D retirés (assets provisoires jugés moches).
	-- Restaurer l'ancien corps de Show (git log) quand la vraie DA arrive.
	if _state and _state.model then
		_state.model:Destroy()
		_state.model = nil
	end
	if _state and _state.vp then
		_state.vp.BackgroundTransparency = 1
	end
end
```

(Cadres invisibles mais présents : les mises en page IndexPanel/SanctuaryPanel restent stables.)

- [ ] **Step 2: Vérification (playtest)** — éclosion + index + sanctuaire : aucun portrait 3D nulle part, aucune erreur console (`get_console_output`).

- [ ] **Step 3: Lint + commit**

```bash
selene src
git add src/client/CreaturePortrait.luau
git commit -m "chore(ui): neutralise les portraits 3D en attendant la DA"
```

---

### Task 10: Arbre d'étoiles lisible

**Files:**
- Modify: `src/client/Panels/SkillPanel.luau:11, 21-22, 130, 173, buildGraph`

**Interfaces:**
- Aucun changement d'API. Trois leviers : contraste des liens, nom sous chaque nœud, en-tête de colonne = branche.

- [ ] **Step 1: Contraste + marge** — remplacer les lignes 11, 21-22 :

```lua
local CANVAS_PAD = 56
```
```lua
local COLOR_LINE_OWNED = Color3.fromRGB(150, 150, 190)
local COLOR_LINE_LOCKED = Color3.fromRGB(85, 85, 110)
```

et la taille des liens (ligne 130) : `Size = UDim2.fromOffset(length, 3)` → `Size = UDim2.fromOffset(length, 4)`.

- [ ] **Step 2: En-têtes de colonnes** — dans `buildGraph`, juste après `UiKit.Clear(canvas)` :

```lua
	-- En-têtes de branches : une colonne = une branche, nommée d'après son premier nœud.
	local seenCols = {}
	for _, node in SkillTree.Nodes() do
		if not seenCols[node.Col] then
			seenCols[node.Col] = true
			UiKit.Create("TextLabel", {
				Name = `ColHeader_{node.Col}`,
				BackgroundTransparency = 1,
				TextColor3 = UiKit.TINTS.ACCENT,
				Font = Enum.Font.GothamBold,
				TextSize = 12,
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromOffset(nodeCenter(node), 8),
				Size = UDim2.fromOffset(COL_STEP - 10, 16),
				Text = node.Branch,
				ZIndex = 2,
				Parent = canvas,
			})
		end
	end
```

- [ ] **Step 3: Nom sous chaque nœud** — après le bloc `UICorner` (ligne 173), dans la boucle des nœuds :

```lua
		UiKit.Create("TextLabel", {
			Name = `NodeLabel_{node.Id}`,
			BackgroundTransparency = 1,
			TextColor3 = if maxed then COLOR_MAX elseif locked then COLOR_LOCKED_TEXT else UiKit.TINTS.WHITE,
			Font = Enum.Font.Gotham,
			TextSize = 10,
			TextWrapped = true,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromOffset(x, y + NODE_SIZE / 2 + 2),
			Size = UDim2.fromOffset(COL_STEP - 20, 24),
			Text = node.Name,
			ZIndex = 2,
			Parent = canvas,
		})
```

- [ ] **Step 4: Vérification (playtest)** — ouvrir l'Arbre : chaque nœud porte son nom, les liens verrouillés restent visibles, les 4 branches sont titrées. CanvasSize suit `CANVAS_PAD` automatiquement (formule existante). Capture → `eyes`.

- [ ] **Step 5: Lint + commit**

```bash
selene src
git add src/client/Panels/SkillPanel.luau
git commit -m "feat(ui): arbre d'étoiles lisible (noms, lignes contrastées, en-tetes)"
```

---

### Task 11: Vérification finale — checklist des 8 symptômes

**Files:** aucun (validation seule).

- [ ] **Step 1: Synchro Rojo OK** (procédure AGENTS.md, mode Edit).
- [ ] **Step 2: Suite complète** — `require(game:GetService("ServerStorage").UnitTest.RunUnitTest)()` → `0 failed` ; `selene src` → clean.
- [ ] **Step 3: Playtest scénario complet** : acheter œuf (solde suffisant ET insuffisant → bouton rouge), hotbar → placer ×3 sur le plateau, éclore (1 créature neuve, comptes data/visuel égaux), réclamer une quête quotidienne (passe verte instantané, essence crédité), menu œufs trié, index/sanctuaire sans portraits, arbre lisible.
- [ ] **Step 4: Console propre** — `get_console_output` : aucune erreur nouvelle (mock ProfileStore attendu).
- [ ] **Step 5: Rapport** à l'utilisateur avec captures validées par `eyes` + demande de re-test manuel.
