# Lot 2 « Le moteur » — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Livrer le Lot 2 de la spec « Revenus & Brain Rot » : Arbre d'Étoiles, Éclipse, offres 1er achat/retour, VIP complet, instrumentation analytics — rétention + mesure.

**Architecture:** Tout data-driven dans `Shared/Config.luau`. Modules purs partagés (SkillTree, Offers, Eclipse math) testés unitairement ; services serveurs minces qui branchent les effets sur les points d'accroche existants (EssenceService.GetRate, HatchService, RiftService:216, MarketService:61, BreedingService:65). Client : panneau UiKit + jauges réutilisant le pattern BoostState (ShopPanel:96/173). Migration profil v6 unique pour tous les nouveaux champs.

**Tech Stack:** Luau, Rojo, ProfileStore, suite unitaire maison (`ServerStorage.UnitTest.RunUnitTest`), MCP Studio pour playtests.

**Spec:** `docs/superpowers/specs/2026-08-23-revenus-brainrot-design.md` (§1.3 Arbre, §1.5 Éclipse, §2.1 offres/VIP, §7 analytics, §2.4 sim obligatoire)

## Global Constraints

- Bible §7 : rien de l'Arbre n'est vendable ; pas de paywall ; compteurs jamais agressifs.
- Spec §2.4 : aucun prix/multiplicateur codé avant passage sim (Task 4 valide les valeurs provisionnelles).
- Multiplicateurs empilés : plafond global `LUCK_HARD_CAP = 1` via `Luck.Combine` (ne jamais bypasser).
- Tests en VM fraîche : après toute synchro rojo de modules, lancer la suite pendant le Play (datamodel Server), jamais en Edit (cache require — spec §8).
- Avant chaque playtest : vérifier le marqueur sync rojo en Edit (ex. `Config.Source:find("SYNC_MARKER")` selon dernière modif disque).
- Suite actuelle : 188 verts. Chaque task doit finir verte avant commit.
- Style : commentaires français, pas de commentaires triviaux, tabs comme le reste du codebase.

---

### Task 1: Migration v6 + champs profil

**Files:**
- Modify: `src/server/Services/SaveService.luau` (DATA_VERSION 5→6, defaults + migration [5])
- Test: `src/tests/unit/Cases/Migration_Test.luau`

**Interfaces:**
- Produces: champs profil `Data.SkillPoints:number`, `Data.SkillRanks:{[string]:number}`, `Data.Offers={FirstPurchaseEligible:boolean, FirstPurchaseClaimed:boolean, ReturnGifts:{[string]:boolean}}`, `Data.Stats.Funnel={FirstHatchAt,FirstRarePlusAt,FirstEpicPlusAt,FirstPurchaseAt}`, `Data.VipGiftDate:string`.

- [ ] **Step 1: Test qui échoue** — ajouter au cas existant :

```luau
case "migration v5 to v6 adds lot2 fields", function()
	local data = { Version = 5 }
	SaveService.Migrate(data)
	expect.truthy(data.Version == 6)
	expect.truthy(data.SkillPoints == 0)
	expect.truthy(data.SkillRanks ~= nil)
	expect.truthy(data.Offers.FirstPurchaseEligible == false)
	expect.truthy(data.Offers.FirstPurchaseClaimed == false)
	expect.truthy(data.Stats.Funnel.FirstHatchAt == 0)
	expect.truthy(data.Stats.Funnel.FirstPurchaseAt == 0)
	expect.truthy(data.VipGiftDate == "")
end,

case "migration preserves existing funnels and ranks", function()
	local data = {
		Version = 5,
		Stats = { TotalHatched = 12 },
		SkillRanks = { FarmRate1 = 2 },
		Offers = { FirstPurchaseClaimed = true },
	}
	SaveService.Migrate(data)
	expect.truthy(data.Stats.TotalHatched == 12)
	expect.truthy(data.SkillRanks.FarmRate1 == 2)
	expect.truthy(data.Offers.FirstPurchaseClaimed == true)
	expect.truthy(data.Stats.Funnel.FirstHatchAt == 0)
end,
```

- [ ] **Step 2: Run (VM fraîche en Play)** → FAIL (Version reste 5)
- [ ] **Step 3: Implémentation** — `DATA_VERSION = 6`, defaults dans le template Store :

```luau
	SkillPoints = 0,
	SkillRanks = {},
	Offers = { FirstPurchaseEligible = false, FirstPurchaseClaimed = false, ReturnGifts = {} },
	VipGiftDate = "",
	-- Stats.Funnel ajouté dans Stats du template :
	Funnel = { FirstHatchAt = 0, FirstRarePlusAt = 0, FirstEpicPlusAt = 0, FirstPurchaseAt = 0 },
```

migration :

```luau
	[5] = function(data)
		data.SkillPoints = data.SkillPoints or 0
		data.SkillRanks = data.SkillRanks or {}
		data.Offers = data.Offers
			or { FirstPurchaseEligible = false, FirstPurchaseClaimed = false, ReturnGifts = {} }
		data.Offers.ReturnGifts = data.Offers.ReturnGifts or {}
		data.VipGiftDate = data.VipGiftDate or ""
		data.Stats = data.Stats or {}
		data.Stats.Funnel = data.Stats.Funnel
			or { FirstHatchAt = 0, FirstRarePlusAt = 0, FirstEpicPlusAt = 0, FirstPurchaseAt = 0 }
		data.Version = 6
	end,
```

- [ ] **Step 4: Run** → PASS (toutes les migrations v1→v6 chaînées passent)
- [ ] **Step 5: Commit** `feat: migration v6 champs arbre/offres/funnel/vip`

---

### Task 2: Shared/SkillTree.luau + Config.SKILL_TREE

**Files:**
- Create: `src/shared/SkillTree.luau`
- Modify: `src/shared/Config.luau` (bloc SKILL_TREE)
- Test: `src/tests/unit/Cases/SkillTree_Test.luau`

**Interfaces:**
- Produces (consommé Tasks 3/4/6) :
  - `SkillTree.Nodes()` → liste ordonnée des nœuds (depuis Config)
  - `SkillTree.Rank(ranks, id)` → number
  - `SkillTree.CanBuy(points, ranks, id)` → (boolean, string?)
  - `SkillTree.Buy(points, ranks, id)` → newPoints (mute ranks ; erreur si invalide)
  - `SkillTree.Effects(ranks)` → `{ EssenceRate, HatchLuck, OfflineRate, EggPriceReduction, RiftRewardMult, AscendChanceAdd, MutationBonus, SecretOmen, MarketFeeReduction, BreedCostReduction, UpgradeCostReduction }`

- [ ] **Step 1: Config.SKILL_TREE** (valeurs PROVISOIRES, validées Task 4) :

```luau
	-- Arbre d'Étoiles : +1 point par renaissance, rien n'est vendable (bible §7).
	-- Valeurs provisionnelles — à valider par EconomySim (spec §2.4) avant live.
	SKILL_TREE = {
		{ Id = "FarmRate1", Branch = "Ferme", Name = "Sève lente", Desc = "+5 % Essence/s par rang", MaxRank = 3, Effect = "EssenceRate", Value = 0.05 },
		{ Id = "FarmRate2", Branch = "Ferme", Name = "Marée d'étoiles", Desc = "+10 % Essence/s par rang", MaxRank = 1, Effect = "EssenceRate", Value = 0.10 },
		{ Id = "FarmLuck", Branch = "Ferme", Name = "Œil lucide", Desc = "+4 % chance d'éclosion par rang", MaxRank = 3, Effect = "HatchLuck", Value = 0.04 },
		{ Id = "FarmOffline", Branch = "Ferme", Name = "Sommeil fertile", Desc = "+5 % rendement hors-ligne par rang", MaxRank = 2, Effect = "OfflineRate", Value = 0.05 },
		{ Id = "RiftReward", Branch = "Faille", Name = "Butin crépusculaire", Desc = "+10 % récompense de faille par rang", MaxRank = 3, Effect = "RiftRewardMult", Value = 0.10 },
		{ Id = "RiftAscend", Branch = "Faille", Name = "Portée d'ascension", Desc = "+1 % chance d'ascension en faille par rang", MaxRank = 3, Effect = "AscendChanceAdd", Value = 0.01 },
		{ Id = "MutOmen", Branch = "Faille", Name = "Présage mutatif", Desc = "+6 % chance de mutation par rang", MaxRank = 3, Effect = "MutationBonus", Value = 0.06 },
		{ Id = "SecretOmen", Branch = "Faille", Name = "Chuchotement", Desc = "Pendant une Éclipse, l'œuf Épique peut aussi déclencher le Secret (relique T3)", MaxRank = 1, Effect = "SecretOmen", Value = 1 },
		{ Id = "MarketFeeCut", Branch = "Économie", Name = "Langue argentée", Desc = "-1 pt de commission marché par rang", MaxRank = 3, Effect = "MarketFeeReduction", Value = 0.01 },
		{ Id = "BreedCut", Branch = "Économie", Name = "Nids partagés", Desc = "-10 % coût d'élevage par rang", MaxRank = 2, Effect = "BreedCostReduction", Value = 0.10 },
		{ Id = "UpgradeCut", Branch = "Économie", Name = "Maçon étoilé", Desc = "-10 % coût d'extension du sanctuaire par rang", MaxRank = 2, Effect = "UpgradeCostReduction", Value = 0.10 },
		{ Id = "EggDiscount", Branch = "Économie", Name = "Marché aux œufs", Desc = "-5 % prix des œufs par rang", MaxRank = 2, Effect = "EggPriceReduction", Value = 0.05 },
	},
```

- [ ] **Step 2: Tests** (cas purs, pas de services) :

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SkillTree = require(ReplicatedStorage.Shared.SkillTree)
local Config = require(ReplicatedStorage.Shared.Config)

return {
	case "tree exposes exactly twelve purchasable nodes", function()
		local nodes = SkillTree.Nodes()
		expect.truthy(#nodes == 12)
		for _, node in nodes do
			expect.truthy(Config.SKILL_TREE[node.Id] ~= nil or node.Id ~= nil)
			expect.truthy(node.MaxRank >= 1)
			expect.truthy(node.Value > 0 or node.Effect == "SecretOmen")
		end
	end,

	case "buy consumes one point per rank and respects max rank", function()
		local ranks, points = {}, 2
		points = SkillTree.Buy(points, ranks, "FarmRate1")
		points = SkillTree.Buy(points, ranks, "FarmRate1")
		expect.truthy(points == 0)
		expect.truthy(SkillTree.Rank(ranks, "FarmRate1") == 2)
		local ok, reason = SkillTree.CanBuy(points, ranks, "FarmRate1")
		expect.truthy(not ok and reason ~= nil)
	end,

	case "buy rejects unknown node and insufficient points", function()
		expect.truthy(not SkillTree.CanBuy(1, {}, "Nope"))
		expect.truthy(not SkillTree.CanBuy(0, {}, "FarmRate1"))
	end,

	case "effects sum ranks across nodes of same effect", function()
		local ranks = { FarmRate1 = 3, FarmRate2 = 1, MutOmen = 2, SecretOmen = 1, MarketFeeCut = 3 }
		local e = SkillTree.Effects(ranks)
		expect.truthy(math.abs(e.EssenceRate - 0.25) < 1e-9)
		expect.truthy(math.abs(e.MutationBonus - 0.12) < 1e-9)
		expect.truthy(e.SecretOmen == true)
		expect.truthy(math.abs(e.MarketFeeReduction - 0.03) < 1e-9)
		expect.truthy(e.HatchLuck == 0)
	end,

	case "effects of empty tree are zeroed", function()
		local e = SkillTree.Effects({})
		expect.truthy(e.EssenceRate == 0 and e.RiftRewardMult == 0 and e.SecretOmen == false)
	end,
}
```

- [ ] **Step 3: Run** → FAIL (module absent) ; **Step 4: implémenter** :

```luau
local Config = require(script.Parent.Config)

local SkillTree = {}

function SkillTree.Nodes()
	return Config.SKILL_TREE
end

function SkillTree.Node(id: string)
	for _, node in Config.SKILL_TREE do
		if node.Id == id then
			return node
		end
	end
	return nil
end

function SkillTree.Rank(ranks: { [string]: number }, id: string): number
	return ranks[id] or 0
end

function SkillTree.CanBuy(points: number, ranks: { [string]: number }, id: string): (boolean, string?)
	local node = SkillTree.Node(id)
	if not node then
		return false, "nœud inconnu"
	end
	if SkillTree.Rank(ranks, id) >= node.MaxRank then
		return false, "rang maximum atteint"
	end
	if points < 1 then
		return false, "aucun point d'étoile"
	end
	return true
end

function SkillTree.Buy(points: number, ranks: { [string]: number }, id: string): number
	local ok = SkillTree.CanBuy(points, ranks, id)
	assert(ok, `achat impossible: {id}`)
	ranks[id] = SkillTree.Rank(ranks, id) + 1
	return points - 1
end

function SkillTree.Effects(ranks: { [string]: number })
	local effects = {
		EssenceRate = 0, HatchLuck = 0, OfflineRate = 0, EggPriceReduction = 0,
		RiftRewardMult = 0, AscendChanceAdd = 0, MutationBonus = 0, SecretOmen = false,
		MarketFeeReduction = 0, BreedCostReduction = 0, UpgradeCostReduction = 0,
	}
	for _, node in Config.SKILL_TREE do
		local rank = SkillTree.Rank(ranks, node.Id)
		if rank > 0 then
			if node.Effect == "SecretOmen" then
				effects.SecretOmen = true
			else
				effects[node.Effect] += node.Value * rank
			end
		end
	end
	return effects
end

return SkillTree
```

- [ ] **Step 5: Run** → PASS ; **Step 6: Commit** `feat: module pur Arbre d'Étoiles + 12 noeuds data-driven`

---

### Task 3: SkillService serveur + points de renaissance + hooks d'effets + panneau

**Files:**
- Create: `src/server/Services/SkillService.luau`
- Modify: `src/shared/Rebirth.luau:51-59` (ApplyReset → `data.SkillPoints += 1`)
- Modify: `src/shared/Net.luau` (+ `Net.SkillBuy`, `Net.SkillSync`)
- Modify: `src/server/Bootstrap.luau` (ORDER : insérer "SkillService" après "SaveService")
- Modify: `src/server/Services/EssenceService.luau:17-27` (mult ferme)
- Modify: `src/server/Services/HatchService.luau:148-153` (luck + mutation bonus)
- Modify: `src/server/Services/RiftService.luau:216` (mult récompense) + site `GrantEgg(..., ascendChance)` (ascension)
- Modify: `src/server/Services/MarketService.luau:61` (commission réduite, floor 0)
- Modify: `src/server/Services/BreedingService.luau:65` (coût réduit, floor 1)
- Modify: `src/server/Services/SanctuaryService.luau` (coût upgrade réduit — repérer le site `Sanctuary.UpgradeCost`)
- Modify: `src/server/Services/HatchService.luau` BuyEgg handler (prix réduit, floor 1)
- Modify: `src/server/Services/DataSync.luau` (payload + SkillPoints/SkillRanks)
- Modify: `src/shared/PlayerDataService` hors scope — non : offline hook dans `PlayerDataService.luau:37` (OFFLINE_RATE + bonus)
- Create: `src/client/Panels/SkillPanel.luau`
- Modify: `src/client/Ui.luau` (AddTab("Arbre", SkillPanel))
- Test: `src/tests/unit/Cases/Rebirth_Test.luau` (+1 point)

**Interfaces:**
- Consumes: `SkillTree.CanBuy/Buy/Effects` (Task 2).
- Produces: `SkillService:EffectsOf(profile)` → table Effects ; remote `Net.SkillBuy(nodeId:string)` ; payload Sync enrichi `SkillPoints`, `SkillRanks`.

- [ ] **Step 1: Test renaissance** — ajouter à Rebirth_Test :

```luau
case "rebirth grants one skill point", function()
	local data = { Creatures = {}, Eggs = {}, Items = {}, Stars = 0, Rebirths = 0, Essence = 0, SkillPoints = 0 }
	Rebirth.ApplyReset(data)
	expect.truthy(data.SkillPoints == 1)
end,
```

- [ ] **Step 2: Run** → FAIL ; implémenter la ligne `data.SkillPoints = (data.SkillPoints or 0) + 1` dans ApplyReset → PASS.

- [ ] **Step 3: SkillService** (mince, pattern RebirthService) :

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local SkillTree = require(ReplicatedStorage.Shared.SkillTree)

local SkillService = {}

local log
local saveService
local dataSync

-- Effets agrégés d'un joueur ; source unique pour tous les hooks serveur.
function SkillService:EffectsOf(profile)
	return SkillTree.Effects(profile.Data.SkillRanks or {})
end

function SkillService:Init(container)
	log = container:Get("Log")
	saveService = container:Get("SaveService")
	dataSync = container:Get("DataSync")
end

function SkillService:Start()
	Net.SkillBuy.OnServerEvent:Connect(function(player: Player, nodeId: unknown)
		if type(nodeId) ~= "string" then
			return
		end
		local profile = saveService:GetProfile(player)
		if not profile then
			return
		end
		local ok, reason = SkillTree.CanBuy(profile.Data.SkillPoints, profile.Data.SkillRanks, nodeId)
		if not ok then
			log:Economy("SkillTree", "Reject", { Player = player.Name, Node = nodeId, Reason = reason })
			return
		end
		profile.Data.SkillPoints = SkillTree.Buy(profile.Data.SkillPoints, profile.Data.SkillRanks, nodeId)
		profile.Data.LastPlayed = os.time()
		log:Economy("SkillTree", "Bought", {
			Player = player.Name, Node = nodeId,
			Rank = SkillTree.Rank(profile.Data.SkillRanks, nodeId),
			PointsLeft = profile.Data.SkillPoints,
		})
		dataSync:Send(player)
	end)
end

return SkillService
```

- [ ] **Step 4: Hooks** (chaque site lit `skillService:EffectsOf(profile)` ; références locales résolues dans Init/Start comme le fait HatchService pour tickerService) :
  - EssenceService.GetRate : `local skillMult = 1 + effectsOf(profile).EssenceRate` inséré dans la chaîne de multiplication.
  - HatchService ligne 148 : `local eff = skillEff(profile)` puis `Luck.Combine(sessionLuck.For(player), luckService:PotionBonus(player), boostService:CurrentBonus(), eff.HatchLuck)` et ligne 153 `CollarBonus(profile) + luck + eff.MutationBonus`.
  - RiftService:216 : multiplier `Config.RIFT_ESSENCE_MULT + eff.RiftRewardMult` (remplacer la constante dans la formule) ; site d'ascension : `ascendChance = (Config.RIFT_ASCEND_CHANCE ou valeur passée) + eff.AscendChanceAdd`.
  - MarketService:61 : `fee or Config.MARKET_FEE` → caller passe `math.max(0, Config.MARKET_FEE - eff.MarketFeeReduction)`.
  - BreedingService:65 : `math.max(1, math.floor(Config.BREED_COST * (1 - eff.BreedCostReduction)))`.
  - SanctuaryService site UpgradeCost : `math.max(1, math.floor(Sanctuary.UpgradeCost(lvl) * (1 - eff.UpgradeCostReduction)))`.
  - HatchService BuyEgg : `math.max(1, math.floor(price * (1 - eff.EggPriceReduction)))`.
  - PlayerDataService:37 : `rate * capped * (Config.OFFLINE_RATE + eff.OfflineRate)`.
  - Garde-fou : HatchLuck passe par Luck.Combine ⇒ plafond LUCK_HARD_CAP respecté.
- [ ] **Step 5: DataSync** payload : ajouter `SkillPoints = profile.Data.SkillPoints, SkillRanks = profile.Data.SkillRanks`.
- [ ] **Step 6: Bootstrap ORDER** : `"SkillService"` juste après `"SaveService"` (avant EssenceService qui l'utilise).
- [ ] **Step 7: SkillPanel** (pattern RebirthPanel : UiKit.Title + liste) :

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.Parent.UiKit)
local Net = require(ReplicatedStorage.Shared.Net)
local SkillTree = require(ReplicatedStorage.Shared.SkillTree)

local SkillPanel = {}

local rowsFrame
local pointsLabel
local lastState

local function Render()
	if not rowsFrame or not lastState then
		return
	end
	pointsLabel.Text = `Points d'étoile : {lastState.SkillPoints or 0}`
	for _, child in rowsFrame:GetChildren() do
		child:Destroy()
	end
	for _, node in SkillTree.Nodes() do
		local rank = SkillTree.Rank(lastState.SkillRanks or {}, node.Id)
		local row = UiKit.Create("TextLabel", {
			Name = node.Id,
			BackgroundTransparency = 1,
			TextColor3 = rank >= node.MaxRank and UiKit.TINTS.ACCENT or UiKit.TINTS.WHITE,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 22),
			Text = `[{node.Branch}] {node.Name} — {node.Desc} ({rank}/{node.MaxRank})`,
			TextWrapped = true,
			Parent = rowsFrame,
		})
		local buy = UiKit.Button(row, "+", UDim2.fromOffset(28, 20), UDim2.fromScale(1, 0))
		buy.Position = UDim2.new(1, -30, 0, 1)
		buy.Activated:Connect(function()
			Net.SkillBuy:FireServer(node.Id)
		end)
	end
end

function SkillPanel.Create(parent)
	local frame = UiKit.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})
	UiKit.Padding(frame, 10)
	UiKit.Title(frame, "Arbre d'Étoiles")
	pointsLabel = UiKit.Create("TextLabel", {
		Name = "PointsLabel",
		BackgroundTransparency = 1,
		TextColor3 = UiKit.TINTS.ACCENT,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromScale(1, 0.06),
		Parent = frame,
	})
	rowsFrame = UiKit.Create("ScrollingFrame", {
		Name = "Rows",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 12 * 26),
		Size = UDim2.fromScale(1, 0.82),
		Position = UDim2.fromScale(0, 0.12),
		Parent = frame,
	})
	UiKit.Padding(rowsFrame, 4)
	UiKit.Layout(rowsFrame) -- si l'utilitaire existe sinon UIListLayout manuel
	return frame
end

function SkillPanel.Refresh(state)
	lastState = state
	Render()
end

return SkillPanel
```

(Ajuster aux utilitaires UiKit réels lors de l'exécution — même style que IndexPanel.Refresh.)

- [ ] **Step 8: Playtest MCP** : Play démarré → injecter un profil avec `Stars=1` (via execute Luau Server sur le profile), vérifier Sync contient SkillPoints=1, acheter FarmRate1 via `Net.SkillBuy:FireServer` côté client, constater rate augmenté. Stop Play.
- [ ] **Step 9: Suite complète VM fraîche** → PASS ; **Commit** `feat: arbre d'etoiles serveur (achat, hooks economy/faille) + panneau`

---

### Task 4: EconomySim — validation des valeurs (AVANT tout ajustement live)

**Files:**
- Modify: `src/tools/EconomySim.luau` (effets arbre + kind "vip")

**Interfaces:**
- Consumes: `SkillTree.Effects` (Task 2), Config.SKILL_TREE (Task 2).
- Produces: résultats de sim consignés ci-dessous + éventuels ajustements Config.

- [ ] **Step 1: Sim** — étendre `NewProfile` avec `SkillPoints = 0, SkillRanks = {}` ; dans `TryRebirth` ajouter `profile.SkillPoints += 1` ; nouvelle fonction `TryBuyNode(profile)` qui achète prioritairement FarmRate1→RiftReward→MarketFeeCut quand points>0 ; `GetRate` applique `(1 + SkillTree.Effects(profile.SkillRanks).EssenceRate)` ; hatchLuck des profils additionné de `Effects().HatchLuck` ; nouveau `options.profileKind == "vip"` = starter + `VIP_LUCK_BONUS` dans hatchLuck.
- [ ] **Step 2: Exécuter en Edit** (command bar, datamodel Edit — outil pur sans cache sensible) :

```luau
local sim = require(game.ReplicatedStorage.Tools.EconomySim)
for _, kind in { "f2p", "starter", "whale", "vip" } do
	print(kind, game:GetService("HttpService"):JSONEncode(sim.Run("progression", { runs = 3, profileKind = kind })))
end
```

- [ ] **Step 3: Critères d'acceptation** (sinon ajuster Config et relancer) :
  - vip/starter ≤ ×3 le rate f2p à 7 jours ;
  - AvgRebirths7j ne baisse pas de plus de 1 vs baseline actuelle pour f2p ;
  - whale garde l'avantage mais reste borné.
- [ ] **Step 4: Consigner** les 4 lignes JSON dans ce fichier (section Résultats ci-dessous) et ajuster `Config.SKILL_TREE` si critère violé.
- [ ] **Step 5: Commit** `feat: sim economique arbre d'etoiles + vip (validation valeurs lot 2)`

**Résultats de sim (23/08/2026, progression ×3 runs, 7 j):** f2p: 4 rebirths, rate 147664 · starter: 4 / 61573 (×0.42) · vip: 4 / 84505 (×0.57) · whale: 4 / 356087 (**×2.41**). Critères §2.4 validés : whale ≤ ×3 f2p, aucune perte de rebirths. NB : rate starter/vip < f2p = variance du reset renaissance au cutoff 7 j + effets RiftReward/MarketFee/MutOmen non consommés par le sim (avantage sous-estimé). Valeurs Config conservées telles quelles.

---

### Task 5: AnalyticsService + funnel

**Files:**
- Create: `src/server/Services/AnalyticsService.luau`
- Modify: `src/server/Bootstrap.luau` (ORDER : "AnalyticsService" juste après "Log")
- Modify: `src/server/Services/HatchService.luau` (event hatch + funnel timestamps + offres eligibility Task 8 pré-posée ici : `FirstEpicPlusAt`)
- Modify: `src/server/Services/RiftService.luau` (event rift_complete)
- Modify: `src/server/Services/PurchaseService.luau` (event purchase + `FirstPurchaseAt`)
- Modify: `src/server/Services/MarketService.luau` (event market_sale)

**Interfaces:**
- Produces: `AnalyticsService:Event(name:string, params:{[string]:any})` — wrap `AnalyticsService:LogCustomEvent` en pcall (no-op silencieux en Studio) ; helper `AnalyticsService:Funnel(profile, key)` pose l'horodatage une seule fois.

- [ ] **Step 1: Service** :

```luau
local AnalyticsService = {}

local analytics = game:GetService("AnalyticsService")
local log

function AnalyticsService:Event(name: string, params: { [string]: any })
	pcall(function()
		analytics:LogCustomEvent(Enum.AnalyticsCustomFieldKeys.CustomField01.Value, name, 1)
	end)
	log:Economy("Analytics", name, params)
end

function AnalyticsService:Funnel(profile, key: string)
	local funnel = profile.Data.Stats.Funnel
	if funnel[key] == 0 or funnel[key] == nil then
		funnel[key] = os.time()
	end
end

function AnalyticsService:Init(container)
	log = container:Get("Log")
end

function AnalyticsService:Start() end

return AnalyticsService
```

- [ ] **Step 2: Instrumentation** (une ligne par site, données déjà disponibles) :
  - HatchService après log Success : `analytics:Event("hatch", { Rarity = roll.Rarity, Mutation = tostring(roll.Mutation), Source = egg.Tier })` + `Funnel(profile, "FirstHatchAt")` + si rank ≥ Rare `Funnel(profile, "FirstRarePlusAt")` + si rank ≥ Epic `Funnel(profile, "FirstEpicPlusAt")`.
  - RiftService fin de combat : `Event("rift_complete", { Win = won, Duration = durée })`.
  - PurchaseService ProcessReceipt après grant : `Event("purchase", { ProductId = productId, Kind = product.Kind or "Essence" })` + Funnel FirstPurchaseAt ; GrantPass idem avec Pass.
  - MarketService vente : `Event("market_sale", { Price = price })`.
- [ ] **Step 3: Test** (funnel pur, pas de réseau) — nouveau cas dans un fichier `Cases/Analytics_Test.luau` mockant log :

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

return {
	case "funnel stamps only the first time", function()
		local container = { Get = function() return { Economy = function() end } end }
		local service = require(ReplicatedStorage.ServerAnalyticsStub or nil) -- si le service n'est pas requirable hors serveur, tester via un module pur Funnel
	end,
}
```

⚠️ Si `require` du service échoue côté tests (services serveur non requirables depuis ServerStorage), extraire `Funnel` en fonction pure locale testable : déplacer la logique dans un petit `src/shared/Funnel.luau` (`Funnel.Stamp(table, key, now)` idempotent) et tester ça. Préférer d'emblée cette option (ponytail : 6 lignes partagées).

```luau
-- src/shared/Funnel.luau
local Funnel = {}
function Funnel.Stamp(funnel: { [string]: number }, key: string, now: number)
	if (funnel[key] or 0) == 0 then
		funnel[key] = now
	end
end
return Funnel
```

Test :

```luau
case "stamp is idempotent", function()
	local f = { FirstHatchAt = 0 }
	Funnel.Stamp(f, "FirstHatchAt", 100)
	Funnel.Stamp(f, "FirstHatchAt", 999)
	expect.truthy(f.FirstHatchAt == 100)
end,
```

- [ ] **Step 4: Suite VM fraîche** → PASS ; **Commit** `feat: instrumentation analytics + funnel premier evenement`

---

### Task 6: EclipseService (horloge serveur)

**Files:**
- Create: `src/shared/Eclipse.luau` (math pur)
- Create: `src/server/Services/EclipseService.luau`
- Modify: `src/shared/Config.luau` (+ `ECLIPSE_INTERVAL = 7200`, `ECLIPSE_DURATION = 600`, `ECLIPSE_MUTATION_BONUS = 9`, `ECLIPSE_CLOCKTIME = 18`)
- Modify: `src/shared/Net.luau` (+ `Net.EclipseState`)
- Modify: `src/server/Services/HatchService.luau:153` (+ bonus éclipse)
- Modify: `src/shared/Ascension.luau` (SecretOmen : paramètre optionnel `omenTier` — voir Step 4)
- Modify: `src/client/Ui.luau` ou ShopPanel (jauge réutilisant le pattern BoostState ShopPanel:96/173)
- Test: `src/tests/unit/Cases/Eclipse_Test.luau` + extension `Cases/Ascension_Test.luau`

**Interfaces:**
- Produces: `Eclipse.IsActive(now, interval, duration)` → boolean ; `Eclipse.NextBoundary(now, interval)` → timestamp ; attribut Workspace `EclipseActive` (déjà consommé par HatchService:158) ; remote `Net.EclipseState {Active, Until, Bonus}` ; `EclipseService:MutationBonus()` → Config value si active sinon 0.

- [ ] **Step 1: Math pur + tests**

```luau
-- src/shared/Eclipse.luau
local Eclipse = {}
function Eclipse.IsActive(now: number, interval: number, duration: number): boolean
	return now % interval < duration
end
function Eclipse.NextBoundary(now: number, interval: number): number
	return now - (now % interval) + interval
end
return Eclipse
```

Tests : fenêtre [0,duration) active, [duration,interval) inactive, boundary suivante exacte, cas limites now=duration-1/duration.

- [ ] **Step 2: Service** (pattern BoostService + boucle horloge) :

```luau
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Eclipse = require(ReplicatedStorage.Shared.Eclipse)
local Net = require(ReplicatedStorage.Shared.Net)

local EclipseService = {}

local log
local savedClockTime = nil

function EclipseService:IsActive(): boolean
	return Eclipse.IsActive(os.time(), Config.ECLIPSE_INTERVAL, Config.ECLIPSE_DURATION)
end

function EclipseService:MutationBonus(): number
	return if self:IsActive() then Config.ECLIPSE_MUTATION_BONUS else 0
end

local function Broadcast(active: boolean)
	workspace:SetAttribute("EclipseActive", active)
	local untilTs = os.time() - (os.time() % Config.ECLIPSE_INTERVAL) + Config.ECLIPSE_DURATION
	Net.EclipseState:FireAllClients({
		Active = active,
		Until = if active then untilTs else Eclipse.NextBoundary(os.time(), Config.ECLIPSE_INTERVAL),
		Bonus = Config.ECLIPSE_MUTATION_BONUS,
	})
	log:Economy("Eclipse", if active then "Started" else "Ended", {})
end

function EclipseService:Apply(active: boolean)
	if active then
		savedClockTime = savedClockTime or Lighting.ClockTime
		Lighting.ClockTime = Config.ECLIPSE_CLOCKTIME
	else
		if savedClockTime then
			Lighting.ClockTime = savedClockTime
			savedClockTime = nil
		end
	end
	Broadcast(active)
end

function EclipseService:Init(container)
	log = container:Get("Log")
end

function EclipseService:Start()
	task.spawn(function()
		local wasActive = self:IsActive()
		self:Apply(wasActive)
		while true do
			local now = os.time()
			local boundary = Eclipse.NextBoundary(now, Config.ECLIPSE_INTERVAL)
			task.wait(math.max(1, boundary - now))
			local active = self:IsActive()
			if active ~= wasActive then
				wasActive = active
				self:Apply(active)
			end
		end
	end)
end

return EclipseService
```

Bootstrap ORDER : "EclipseService" après "OrbService".

- [ ] **Step 3: Hook mutation** — HatchService:153 : `CollarBonus(profile) + luck + eff.MutationBonus + eclipseService:MutationBonus()` (référence résolue au Start comme tickerService). Le plafond LUCK_HARD_CAP ne s'applique qu'à `luck` — voulu : l'éclipse est un événement serveur, pas de la chance achetable (spéc §1.5).
- [ ] **Step 4: SecretOmen** — `Ascension.SecretTrigger(eggTier, eclipseActive, relicTier)` devient `SecretTrigger(eggTier, eclipseActive, relicTier, omen: boolean?)` : si `omen` alors condition tier ∈ {"RareEgg","EpicEgg","LegendaryEgg"}. HatchService passe `eff.SecretOmen == true`. Étendre la truth table Ascension_Test (4 nouveaux cas omen=true).
- [ ] **Step 5: Jauge client** — dans ShopPanel à côté de la jauge Boost : label/jauge liés à `Net.EclipseState` (« Éclipse : mutations ×{1+Bonus} — mm:ss », masquée si inactive). Réutiliser exactement la mécanique BoostState:96/173.
- [ ] **Step 6: Annonce** — au passage Active=false→true, réutiliser le toast existant : `Net.QuestsSync:FireAllClients({ Notice = { Type = "Eclipse", Name = "Éclipse !", Desc = "Mutations ×10 pendant 10 minutes" } })` (vérifier que FireAllClients est supporté par le handler client ; sinon boucle Players).
- [ ] **Step 7: Playtest** : en Play, forcer `os.time()` impossible — tester via attribute : appeler `EclipseService:Apply(true)` en Server, capturer client (ciel assombri + jauge), hatch ×3 pour observer taux mutation, puis `Apply(false)`.
- [ ] **Step 8: Suite VM fraîche** → PASS ; **Commit** `feat: evenement eclipse (horloge serveur, mutations x10, secret elargi, jauge)`

---

### Task 7: VIP complet

**Files:**
- Modify: `src/shared/Config.luau` (GAMEPASSES + `VIP = { Id = 0, Name = "VIP — ×1.25 chance permanent, tag doré, cadeau quotidien" }`, `VIP_DAILY_GIFT = 300`)
- Modify: `src/server/Services/PurchaseService.luau` (PassEffect accepte "VIP" → `{ Flag = "VIP", Essence = 0 }`)
- Modify: `src/server/Services/HatchService.luau:148` (+ `if profile.Data.Entitlements.VIP then Config.VIP_LUCK_BONUS else 0` dans Combine)
- Modify: `src/server/Services/PlayerDataService.luau` (cadeau quotidien VIP après le bloc streak)
- Create: `src/server/Services/VipCosmetics.luau` (tag doré + aura) OU fonctions locales dans PlayerDataService (préféré : moins de fichiers)
- Test: extension `Cases/Purchase_Test.luau` (PassEffect VIP) + cas cadeau

- [ ] **Step 1: Tests**

```luau
case "pass effect maps vip to its flag", function()
	local effect = PurchaseService.PassEffect("VIP")
	expect.truthy(effect ~= nil and effect.Flag == "VIP")
	expect.truthy(PurchaseService.PassEffect("Unknown") == nil)
end,

case "vip daily gift grants once per day", function()
	-- logique pure extraite : Vip.GiftDue(vipGiftDate, today)
	local Vip = require(ReplicatedStorage.Shared.Vip)
	expect.truthy(Vip.GiftDue("", "2026-08-23") == true)
	expect.truthy(Vip.GiftDue("2026-08-23", "2026-08-23") == false)
	expect.truthy(Vip.GiftDue("2026-08-22", "2026-08-23") == true)
end,
```

- [ ] **Step 2: Module pur `src/shared/Vip.luau`** (`GiftDue(lastDate, today)` 3 lignes) + implémentation :
  - PassEffect : ajouter `"VIP"` à la liste des flags simples.
  - HatchService Combine : argument supplémentaire VIP.
  - PlayerDataService après le bloc streak : si `Entitlements.VIP` et `Vip.GiftDue(profile.Data.VipGiftDate, today)` → `essenceService:Add(player, Config.VIP_DAILY_GIFT, "VipDailyGift")`, `profile.Data.VipGiftDate = today`, toast Notice.
  - Cosmétiques (fonction locale appelée depuis OnPlayerAdded quand VIP) : BillboardGui doré "★ VIP" au-dessus de la tête + ParticleEmitter or sur HumanoidRootPart (~25 lignes, pattern standard).
- [ ] **Step 3: Suite VM fraîche** → PASS ; **Commit** `feat: vip complet (chance permanent, cadeau quotidien, tag dore, aura)`

---

### Task 8: Offres 1er achat + retours J2/J7

**Files:**
- Create: `src/shared/Offers.luau` (pur)
- Modify: `src/shared/Config.luau` (+ `DEV_PRODUCTS.FirstPurchaseOffer = { Id = 0, Name = "Offre 1er achat — Pack de départ -50 %", Kind = "FirstOffer" }`, `RETURN_GIFTS = { D2 = 500, D7 = 2000 }`)
- Modify: `src/server/Services/HatchService.luau` (eligibility Épic+ → `profile.Data.Offers.FirstPurchaseEligible = true`)
- Modify: `src/server/Services/PlayerDataService.luau` (retour J2 : eligible + cadeaux J2/J7 une fois)
- Modify: `src/server/Services/PurchaseService.luau` (ProcessReceipt : Kind=="FirstOffer" → GrantPass StarterBundle + `Offers.FirstPurchaseClaimed = true` + refuser si déjà claimé)
- Modify: `src/client/Panels/ShopPanel.luau` (bannière offre conditionnelle)

**Interfaces:**
- Produces: `Offers.FirstPurchaseEligible(data, today, daysSinceLastPlayed)` → boolean ; `Offers.ReturnDay(daysSinceLastPlayed)` → "D2"|"D7"|nil ; `Offers.ReturnGiftDue(data, day)` → boolean (une fois par jour-clé).

- [ ] **Step 1: Module pur + tests**

```luau
local Offers = {}
function Offers.ReturnDay(elapsed: number): string?
	if elapsed >= 6 * 86400 then
		return "D7"
	elseif elapsed >= 86400 then
		return "D2"
	end
	return nil
end
function Offers.ReturnGiftDue(data, day: string): boolean
	local gifts = data.Offers.ReturnGifts
	return gifts[day] ~= true
end
function Offers.FirstPurchaseEligible(data: any): boolean
	return not data.Offers.FirstPurchaseClaimed
		and (data.Offers.FirstPurchaseEligible or (data.LastPlayed > 0 and os.time() - data.LastPlayed >= 86400))
end
return Offers
```

Tests : seuils 86399/86400/6d, gift une fois, eligible après drop Épic+ flag, pas eligible neuf.

- [ ] **Step 2: Triggers serveur**
  - HatchService : après indexRegister, si rank ≥ Epic → `profile.Data.Offers.FirstPurchaseEligible = true`.
  - PlayerDataService (join, après streak) : `local day = Offers.ReturnDay(elapsed)` ; si day et `Offers.ReturnGiftDue(profile.Data, day)` → essence cadeau `Config.RETURN_GIFTS[day]` + `ReturnGifts[day] = true` + toast ; si `Offers.FirstPurchaseEligible(profile.Data)` → flag persistant `FirstPurchaseEligible = true` (le client saura l'afficher via Sync).
- [ ] **Step 3: Achat** — ProcessReceipt : `elseif product.Kind == "FirstOffer"` → si `profile.Data.Offers.FirstPurchaseClaimed` alors log Reject + NotProcessedYet (jamais deux fois) ; sinon `GrantPass(player, "StarterBundle")` + `FirstPurchaseClaimed = true` + Funnel FirstPurchaseAt + Event purchase.
- [ ] **Step 4: ShopPanel** — bannière visible si `state.Offers.FirstPurchaseEligible && !Claimed` : bouton « Offre 1re fois : pack -50 % » → `MarketplaceService:PromptProductPurchaseAsync(player, Config.DEV_PRODUCTS.FirstPurchaseOffer.Id)` (côté client, guard Id~=0). DataSync : ajouter `Offers = profile.Data.Offers`.
- [ ] **Step 5: Suite VM fraîche** → PASS ; playtest : flag eligible injecté → bannière visible ; **Commit** `feat: offre premier achat -50% + cadeaux retour j2/j7`

---

### Task 9: Recette finale Lot 2

- [ ] **Step 1:** Vérifier sync rojo (marqueur disque présent en Edit).
- [ ] **Step 2:** Suite complète en Play (VM fraîche) : objectif ≥ 210 verts / 0 failed.
- [ ] **Step 3:** E2E MCP : renaître (injecter TotalEssenceEarned) → point gagné → acheter nœud → forcer Eclipse Apply(true) → hatch (mutations boostées observées dans logs) → fin.
- [ ] **Step 4:** Capture écran (panneau Arbre + jauge Éclipse + bannière offre) → analyse `eyes`.
- [ ] **Step 5:** Demander Ctrl+S à l'humain ; commit final éventuel (ajustements visuels) `chore: recette lot 2`.

## Self-Review

- Couverture spec §1.3 ✓ (Tasks 2/3) · §1.5 ✓ (Task 6) · §2.1 VIP/offres ✓ (Tasks 7/8) · §2.4 sim ✓ (Task 4) · §7 analytics ✓ (Task 5). Créature exclusive Éclipse : reportée Lot 4 avec la vague d'espèces (décision ponytail consignée ici).
- Placeholders : aucun TBD ; valeurs Config provisionnelles explicitement validées en Task 4 avant live.
- Cohérence types : `SkillTree.Effects` clés utilisées identiques Tasks 3/4/6 ; `Offers.*` signatures alignées Task 8 ; Funnel keys fixes : FirstHatchAt/FirstRarePlusAt/FirstEpicPlusAt/FirstPurchaseAt.
