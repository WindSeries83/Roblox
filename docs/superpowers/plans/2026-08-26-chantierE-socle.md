# Plan — Chantier E : socle transactionnel & intégrité

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Éliminer les 3 P0 transactionnels de l'audit + les P1 progression/faille, sans régression (suite verte étendue).

**Architecture:** Repo Rojo Luau strict. Services serveur autoritaires (`src/server/Services/*`), logique pure partagée testable (`src/shared/*`), tests `src/tests/unit/Cases/*_Test.luau` exécutés via `RunUnitTest` en MCP Studio (contrôleur). Persistance via `SafeStore` (DataStore réel publié, stub Studio sinon — `UpdateAsync` disponible dans les deux cas).

**Tech Stack:** Roblox Luau `--!strict`, Rojo, selene, stylua, framework maison `RunUnitTest` (`expect.equal/near/truthy/falsy…`).

**Spec:** `docs/RIFT_BEASTS_1_bible_design.md` (rév. 26/08) + `docs/production/qa/playtests/2026-08-26-audit-integral-bible-design.md` (AUD-P0-01/02/03, AUD-P1-04/06/07, B3.3, B3.26, B3.41, B5.3).

## Global Constraints

- Un seul processus `rojo serve` (≤ 2 PID parent/enfant) ; vérifier synchro Edit (marqueur dans `ReplicatedStorage.Shared.Config.Source`) avant tout playtest.
- `[profilestore]: Roblox API services unavailable` en Studio non publié = mock attendu.
- Aucune nouvelle confiance au client ; validations serveur conservées ; commentaires FR courts (le *pourquoi*) ; `task.*` jamais `wait()` ; `pcall` autour des opérations faillibles.
- Chaque tâche : test rouge→vert quand c'est du pur, `selene src` clean, commit dédié. Suite complète verte en fin de chantier.
- Captures écran toujours analysées par agent `eyes`.
- Les sous-tâches n'exécutent JAMAIS la suite Luau elles-mêmes : le contrôleur la lance via MCP Studio après le rapport DONE.

---

### Task 1: `Gameplay.ConsumeOnce` — dédoublonnage pur

**Files:** Modify `src/shared/Gameplay.luau` · Test `src/tests/unit/Cases/Gameplay_Test.luau`

**Interfaces:** Produces `Gameplay.ConsumeOnce(map: { [string]: boolean }, key: string): boolean` — consommé par Task 2.

- [ ] **Step 1: Test échouant** — ajouter dans `Gameplay_Test.luau` :

```lua
	t.test("ConsumeOnce : premier appel true, replay false", function()
		local map = {}
		expect.truthy(Gameplay.ConsumeOnce(map, "a_b"))
		expect.falsy(Gameplay.ConsumeOnce(map, "a_b"))
		expect.truthy(Gameplay.ConsumeOnce(map, "a_c"))
	end)
```

- [ ] **Step 2: Run → FAIL** (`ConsumeOnce` absent).
- [ ] **Step 3: Implémentation** — fin de `Gameplay.luau` :

```lua
-- Consomme une clé une seule fois : true au premier appel, false aux replays.
function Gameplay.ConsumeOnce(map: { [string]: boolean }, key: string): boolean
	if map[key] then
		return false
	end
	map[key] = true
	return true
end
```

- [ ] **Step 4: Lint `selene src`.**
- [ ] **Step 5: Commit** `feat(core): ConsumeOnce pour grants idempotents`

---

### Task 2: Receipts d'achat — claim-first + effet dédoublonné profil

**Files:** Modify `src/server/Services/PurchaseService.luau:150-226` · Modify migration des données (champ défaut) · Test `src/tests/unit/Cases/Purchase_Test.luau` (extension)

**Interfaces:** Consumes `Gameplay.ConsumeOnce` (T1). Produces flux ProcessReceipt : claim DataStore avant effet, `profile.Data.PurchaseReceipts[receiptKey]` comme garde-fou durable.

- [ ] **Step 1: Champ défaut** — localiser le bloc de valeurs par défaut du profil (grep `Entitlements =` dans `src/server`) ; y ajouter `PurchaseReceipts = {}` et incrémenter la version de migration si le fichier en porte une (cf. `Migration_Test`).
- [ ] **Step 2: Réécrire `ProcessReceipt`** :

```lua
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local receiptKey = PurchaseService.ReceiptKey(receiptInfo.PlayerId, receiptInfo.PurchaseId)

		-- Claim atomique AVANT tout effet : deux replays concurrents -> un seul passage.
		local state
		local okClaim = pcall(function()
			state = ReceiptsStore:UpdateAsync(receiptKey, function(old)
				return if old == "done" then "done" else "pending"
			end)
		end)
		if okClaim and state == "done" then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		local product = PurchaseService.ResolveProduct(receiptInfo.ProductId)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		local profile = if player then saveService:GetProfile(player) else nil
		if not product or not player or not profile then
			-- Claim conservé ("pending") : retry Roblox reprendra le traitement.
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		-- Garde-fou durable : si l'effet est déjà dans le profil (crash après
		-- grant, avant le flag "done"), on ne re-grante pas.
		if not Gameplay.ConsumeOnce(profile.Data.PurchaseReceipts, receiptKey) then
			pcall(function()
				ReceiptsStore:UpdateAsync(receiptKey, function()
					return "done"
				end)
			end)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		local okGrant, grantedOk = pcall(function()
			return PurchaseService.GrantProduct(player, product, receiptInfo.ProductId)
		end)
		if not okGrant or not grantedOk then
			LogPurchase("ReceiptGrantFailed", { PlayerId = receiptInfo.PlayerId, ProductId = receiptInfo.ProductId })
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		dataSync:Send(player)

		pcall(function()
			ReceiptsStore:UpdateAsync(receiptKey, function()
				return "done"
			end)
		end)
		LogPurchase("Receipt", { PlayerId = receiptInfo.PlayerId, ProductId = receiptInfo.ProductId, Kind = product.Kind or "Essence" })
		analyticsService:Event("purchase", { ProductId = receiptInfo.ProductId, Kind = product.Kind or "Essence" })
		analyticsService:Funnel(profile, "FirstPurchaseAt")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
```

Ajouter `local Gameplay = require(ReplicatedStorage.Shared.Gameplay)` en tête ; supprimer l'ancien bloc get/SetAsync et l'ancien commentaire « Grant-then-ack ». **Limite actée (commentaire `ponytail:` dans le code)** : crash entre le grant en mémoire et la sauvegarde profil reste une fenêtre résiduelle — bornée, détectable au log `Receipt` dupliqué.
- [ ] **Step 3: Tests** — étendre `Purchase_Test` : cas `ResolveProduct(0)` retourne nil (déjà présent sinon ajouter), plus un cas documentant `ReceiptKey`.
- [ ] **Step 4: Vérification runtime** (contrôleur) — suite verte ; console propre au démarrage.
- [ ] **Step 5: Commit** `fix(economie): receipts claim-first + effet dédoublonné par profil`

---

### Task 3: Marché — stockage par-listing + claim atomique d'achat

**Files:** Modify `src/server/Services/MarketService.luau` (persistance 102-134 + achat 257-302 + Start 362-389) · Test `src/tests/unit/Cases/Market_Test.luau`

**Interfaces:** Produces `MarketService.CanClaim(listing: any?, buyerUserId: number): (boolean, string?)` (pur). Clés store : `Listing_{id}`, index `Index` = `{ Ids = { string } }`.

- [ ] **Step 1: Test échouant** — dans `Market_Test.luau` :

```lua
	t.test("CanClaim refuse listing vendu, soi-même, inexistant ; accepte sinon", function()
		expect.truthy(Market.CanClaim({ SellerUserId = 1, Price = 100 }, 2))
		local ok = Market.CanClaim({ SellerUserId = 2 }, 2)
		expect.falsy(ok)
		local ok2 = Market.CanClaim({ SellerUserId = 1, SoldAt = os.time() }, 2)
		expect.falsy(ok2)
		expect.falsy(Market.CanClaim(nil, 2))
		local ok3 = Market.CanClaim({ SellerUserId = 1, WithdrawAt = os.time() + 60 }, 2)
		expect.falsy(ok3)
	end)
```

- [ ] **Step 2: Run → FAIL.**
- [ ] **Step 3: Pure `CanClaim`** (section pure, vers ligne 55) :

```lua
function MarketService.CanClaim(listing: any, buyerUserId: number): (boolean, string?)
	if not listing then
		return false, "Listing introuvable"
	end
	if listing.SellerUserId == buyerUserId then
		return false, "Tu ne peux pas acheter ta propre créature"
	end
	if listing.SoldAt then
		return false, "Déjà vendu"
	end
	if listing.WithdrawAt then
		return false, "Retrait en cours"
	end
	return true
end
```

- [ ] **Step 4: Persistance par-listing** — remplacer `PersistListings`/`LoadListings` :

```lua
local function notifyOtherServers()
	-- propagation live aux autres serveurs (guard Studio : PublishAsync bloque non publié)
	if not RunService:IsStudio() then
		pcall(function()
			MessagingService:PublishAsync(Config.MARKET_TOPIC, { UpdatedAt = os.time() })
		end)
	end
end

local function IndexIds(): { string }
	local data
	pcall(function()
		data = Store:GetAsync("Index")
	end)
	return if type(data) == "table" and type(data.Ids) == "table" then data.Ids else {}
end

local function WriteIndex(ids: { string })
	pcall(function()
		Store:SetAsync("Index", { Ids = ids })
	end)
end

local function PersistListing(listing: any)
	pcall(function()
		Store:SetAsync(`Listing_{listing.Id}`, listing)
	end)
	local ids = IndexIds()
	if not table.find(ids, listing.Id) then
		table.insert(ids, listing.Id)
		WriteIndex(ids)
	end
	notifyOtherServers()
end

local function RemoveListing(id: string)
	pcall(function()
		Store:SetAsync(`Listing_{id}`, nil)
	end)
	local ids = IndexIds()
	local pos = table.find(ids, id)
	if pos then
		table.remove(ids, pos)
		WriteIndex(ids)
	end
	notifyOtherServers()
end

local function LoadListings(replace: boolean?)
	if replace then
		table.clear(listings)
	end
	for _, id in IndexIds() do
		local data
		pcall(function()
			data = Store:GetAsync(`Listing_{id}`)
		end)
		if type(data) == "table" and type(data.Id) == "string" and not data.SettledAt then
			listings[data.Id] = data
		end
	end
end
```

- [ ] **Step 5: Achat atomique** — remplacer le cœur de `OnMarketBuy` après validations `CanBuy` :

```lua
	-- 1) Claim atomique cross-serveur : un seul acheteur peut marquer SoldAt.
	local claimed
	local okClaim = pcall(function()
		claimed = Store:UpdateAsync(`Listing_{listingId}`, function(old)
			local ok, _reason = MarketService.CanClaim(old, player.UserId)
			if not ok then
				return nil -- abandonne l'écriture
			end
			local updated = table.clone(old)
			updated.SoldAt = os.time()
			updated.SoldBy = player.UserId
			return updated
		end)
	end)
	if not okClaim or type(claimed) ~= "table" or claimed.SoldBy ~= player.UserId then
		log:Economy("Market", "BuyRejected", { Player = player.Name, Reason = "Listing déjà pris" })
		LoadListings(true)
		BroadcastListings()
		return
	end

	-- 2) Créature d'abord, débit ensuite, règlement enfin (ordre le moins perdeur).
	table.insert(profile.Data.Creatures, claimed.Creature)
	if not essenceService:Spend(player, claimed.Price, `MarketBuy_{claimed.Id}`) then
		table.remove(profile.Data.Creatures)
		pcall(function()
			Store:UpdateAsync(`Listing_{claimed.Id}`, function(old)
				old.SoldAt = nil
				old.SoldBy = nil
				return old
			end)
		end)
		return
	end
	profile.Data.LastPlayed = os.time()
	dataSync:Send(player)

	-- 3) Règlement vendeur puis suppression du listing.
	pcall(function()
		Store:UpdateAsync(`Listing_{claimed.Id}`, function(old)
			old.SettledAt = os.time()
			return old
		end)
	end)
	listings[claimed.Id] = nil
	RemoveListing(claimed.Id)
	CreditSeller(claimed)

	log:Economy("Market", "Buy", {
		Player = player.Name,
		Listing = claimed.Id,
		Seller = claimed.SellerName,
		Species = claimed.Creature.SpeciesId,
		Price = claimed.Price,
	})
	BroadcastListings()
```

Supprimer l'ancien `listings[listing.Id] = nil; PersistListings()` du chemin d'achat. Adapter `OnMarketList`/`OnMarketRemove` : remplacer `PersistListings()` par `PersistListing(listing)` / `RemoveListing(id)` (dans Remove, les deux appels existants deviennent `RemoveListing(listing.Id)`).
- [ ] **Step 6: Balayage des ventes abandonnées** — dans la boucle 60 s existante, avant `LoadListings(true)` :

```lua
			-- ponytail: crash entre claim et règlement -> on règle le vendeur
			-- (fenêtre minuscule, favorable acheteur ; à durcir seulement si exploité).
			for _, listing in listings do
				if listing.SoldAt and not listing.SettledAt and os.time() - listing.SoldAt > 120 then
					listing.SettledAt = os.time()
					PersistListing(listing)
					CreditSeller(listing)
					listings[listing.Id] = nil
					RemoveListing(listing.Id)
				end
			end
```

- [ ] **Step 7: Migration legacy** — début de `Start()` avant `LoadListings()` :

```lua
	-- Migration v1 -> par-listing : l'ancien snapshot unique devient des clés individuelles.
	local legacy
	pcall(function()
		legacy = Store:GetAsync(ListingsKey)
	end)
	if type(legacy) == "table" then
		for _, listing in legacy do
			if type(listing.Id) == "string" and not listing.SoldAt then
				PersistListing(listing)
			end
		end
		pcall(function()
			Store:SetAsync(ListingsKey, nil)
		end)
	end
```

- [ ] **Step 8: Lint + playtest smoke (contrôleur)** — lister, acheter, retirer ; console propre ; listings persistés après stop/start play.
- [ ] **Step 9: Commit** `fix(marche): claim atomique par listing, DataStore source de vérité`

---

### Task 4: Duel — escrow durable

**Files:** Modify `src/server/Services/DuelService.luau` (locals, `Refund` 20-23, création 88-103, accept 126-139, removing 202-213)

**Interfaces:** Store `RiftBeastsDuels_v1`, clés `Escrow_{userId}`. Helpers internes `EscrowAdjust(userId, delta)`, `TakeEscrow(userId): number`, `CreditEscrowIfOnline(userId, source)`, `ReleaseEscrow(challenge)`.

- [ ] **Step 1: Helpers** (après les locals) :

```lua
local EscrowStore = SafeStore.Get("RiftBeastsDuels_v1", 0)

-- L'escrow vit dans le DataStore : un challenger qui quitte le jeu est
-- remboursé exactement une fois, même hors ligne (AUD-P0-03).
local function EscrowAdjust(userId: number, delta: number)
	pcall(function()
		EscrowStore:UpdateAsync(`Escrow_{userId}`, function(old)
			return math.max(0, (old or 0) + delta)
		end)
	end)
end

local function TakeEscrow(userId: number): number
	local taken = 0
	pcall(function()
		EscrowStore:UpdateAsync(`Escrow_{userId}`, function(old)
			taken = old or 0
			return 0
		end)
	end)
	return taken
end

local function CreditEscrowIfOnline(userId: number, source: string)
	local player = Players:GetPlayerByUserId(userId)
	local amount = TakeEscrow(userId)
	if player and amount > 0 then
		essenceService:Add(player, amount, source)
		dataSync:Send(player)
	end
end

local function ReleaseEscrow(challenge: any)
	challenges[challenge.Id] = nil
	-- En ligne : remboursement immédiat. Hors ligne : l'escrow reste en store,
	-- crédité à la reconnexion (PlayerAdded).
	CreditEscrowIfOnline(challenge.ChallengerUserId, "DuelRefund")
end
```

Ajouter `local SafeStore = require(script.Parent.SafeStore)`. Remplacer l'ancien `Refund` partout (accept-fonds-insuffisants → `ReleaseEscrow(challenge)` sans double remboursement d'essence : vérifier que le cas « fonds insuffisants à l'accept » ne fait qu'appeler ReleaseEscrow).
- [ ] **Step 2: Wiring** — création : après `essenceService:Spend(player, wager, "DuelWager")` réussi → `EscrowAdjust(player.UserId, wager)`. Résolution (accept, après paiement du vainqueur) → `TakeEscrow(challenge.ChallengerUserId)` (escrow soldé par le pot). `PlayerRemoving` branche challenger : remplacer `challenges[challenge.Id] = nil` par `ReleaseEscrow(challenge)`. Ajouter dans le flux existant des joueurs (PlayerRemoving voisin ou un PlayerAdded dédié) : `CreditEscrowIfOnline(player.UserId, "DuelEscrowRejoin")` à la connexion.
- [ ] **Step 3: Lint + suite verte** (`Duel_Test` inchangé, logique sim intacte).
- [ ] **Step 4: Playtest scénario audit (contrôleur)** — execute Luau Server pour lire `Escrow_{uid}` après un défi scripté ; stop/restart play → crédit `DuelEscrowRejoin` dans logs. Critère : départ/refus/timeout remboursent exactement une fois.
- [ ] **Step 5: Commit** `fix(duel): escrow persistant remboursé exactement une fois`

---

### Task 5: Renaissance — conservation totale

**Files:** Modify `src/shared/Rebirth.luau:25-61` · Test `src/tests/unit/Cases/Rebirth_Test.luau` · Copy `src/client/Panels/RebirthPanel.luau`

**Interfaces:** `ApplyReset(data)` conserve créatures/items/companion ; ne touche que Eggs, SanctuaryLevel, Stars, Rebirths, SkillPoints, Essence. `KeepBestCreature` supprimée (grep préalable : aucun autre appelant).

- [ ] **Step 1: Tests réécrits** :

```lua
	t.test("ApplyReset conserve toutes les créatures et tous les objets", function()
		local data = {
			Creatures = { { Id = "a", Power = 10 }, { Id = "b", Power = 50 } },
			Items = { { Type = "Relic", Tier = 1 }, { Type = "Relic", Tier = 3 }, { Type = "Collar", Tier = 2 } },
			CompanionId = "b",
			Eggs = { { Id = "e" } },
			SanctuaryLevel = 4,
			Stars = 1,
			Rebirths = 0,
			SkillPoints = 0,
			Essence = 99999,
		}
		Rebirth.ApplyReset(data)
		expect.equal(#data.Creatures, 2)
		expect.equal(#data.Items, 3)
		expect.equal(data.CompanionId, "b")
		expect.equal(#data.Eggs, 0)
		expect.equal(data.SanctuaryLevel, 1)
		expect.equal(data.Stars, 2)
		expect.equal(data.Rebirths, 1)
		expect.equal(data.SkillPoints, 1)
		expect.equal(data.Essence, Config.STARTER_ESSENCE)
	end)
```

Supprimer les cas testant `KeepBestCreature` / filtre légendaire.
- [ ] **Step 2: Run → FAIL.**
- [ ] **Step 3: Implémentation** :

```lua
function Rebirth.KeepItems(items: { any }): { any }
	-- Tout l'équipement est permanent (bible §3.8) : reliques, cœurs, colliers.
	return table.clone(items or {})
end

function Rebirth.ApplyReset(data: any)
	-- Conservation actée (rév. 26/08) : TOUTES les créatures, tous les objets,
	-- compagnon inclus. Perte limitée : Essence, sanctuaire, œufs (consommables).
	data.Eggs = {}
	data.SanctuaryLevel = 1
	data.Items = Rebirth.KeepItems(data.Items)
	data.Stars += 1
	data.Rebirths += 1
	data.SkillPoints = (data.SkillPoints or 0) + 1
	data.Essence = Config.STARTER_ESSENCE
end
```

(`CompanionId` non touché : sa créature survit.) Supprimer `KeepBestCreature`.
- [ ] **Step 4: Grep `KeepBestCreature`** repo entier → références résiduelles supprimées. Grep texte « meilleure » dans `RebirthPanel.luau` → copie adaptée (« Tu gardes toutes tes créatures et ton équipement »).
- [ ] **Step 5: Run → PASS**, lint, commit `fix(progression): la renaissance conserve toutes les creatures et objets`

---

### Task 6: Faille — anti-réinscription, essence coupée, relique en défaite, vraie durée

**Files:** Modify `src/shared/Config.luau` (bloc RIFT ~42-59) · Modify `src/server/Services/RiftService.luau` · Modify `src/server/Services/EssenceService.luau:105-117` · Create Test `src/tests/unit/Cases/Rift_Test.luau`

**Interfaces:** Config ajoute `RIFT_REENTRY_COOLDOWN = 6`, `RIFT_RELIC_WEIGHTS_DEFEAT`. Attribute joueur `InRiftCombat` (bool) produit par RiftService, consommé par EssenceService.

- [ ] **Step 1: Test échouant** — `src/tests/unit/Cases/Rift_Test.luau` :

```lua
local Config = require(game.ReplicatedStorage.Shared.Config)

return function(t)
	t.test("relique en défaite = 25 % du taux victoire", function()
		for _, tier in { "T1", "T2", "T3" } do
			expect.near(Config.RIFT_RELIC_WEIGHTS_DEFEAT[tier], Config.RIFT_RELIC_WEIGHTS[tier] * 0.25, 0.01)
		end
	end)

	t.test("cooldown de réentrée présent et positif", function()
		expect.truthy(Config.RIFT_REENTRY_COOLDOWN >= 1)
	end)
end
```

Enregistrer ce nouveau fichier de cas dans le runner si le framework l'exige (voir comment les autres `_Test` sont découverts).
- [ ] **Step 2: Run → FAIL.**
- [ ] **Step 3: Config** — après `RIFT_RELIC_WEIGHTS` :

```lua
	RIFT_RELIC_WEIGHTS_DEFEAT = { None = 97, T1 = 2, T2 = 0.75, T3 = 0.25 },
	RIFT_REENTRY_COOLDOWN = 6,
```

- [ ] **Step 4: RiftService** —
  a) locals : `local reentryBlocked: { [Player]: number } = {}`
  b) `CleanupCombat` : en tête `reentryBlocked[player] = os.clock() + Config.RIFT_REENTRY_COOLDOWN` puis `player:SetAttribute("InRiftCombat", nil)`.
  c) `JoinRift` : après le garde `Combat[player]` :

```lua
	if (reentryBlocked[player] or 0) > os.clock() then
		return
	end
	player:SetAttribute("InRiftCombat", true)
```

  d) `Combat[player].StartedAt = os.time()` dans la construction ; `WinRift`/`LoseRift` : `Duration = os.time() - combat.StartedAt` dans les deux événements `rift_complete`.
  e) `LoseRift`, avant `CleanupCombat` :

```lua
	-- Défaite non punitive (décision bible 26/08) : roll de relique réduit.
	local defeatRoll = Gameplay.WeightedRoll(Config.RIFT_RELIC_WEIGHTS_DEFEAT)
	local defeatTier = nil
	if defeatRoll and defeatRoll ~= "None" then
		defeatTier = tonumber(defeatRoll:sub(2))
		if defeatTier then
			itemService:GrantItem(player, "Relic", defeatTier, "RiftDefeat")
		end
	end
	Net.RiftEnded:FireClient(player, { Win = false, RelicTier = defeatTier })
```

  f) `Players.PlayerRemoving` : `reentryBlocked[player] = nil`.
- [ ] **Step 5: EssenceService** — boucle Heartbeat :

```lua
				-- Aucune essence passive pendant un combat de faille (bible §5, B5.3).
				local inRift = player:GetAttribute("InRiftCombat") == true
				local rate = if inRift then 0 else EssenceService.GetRate(player)
```

(le `dataSync:Send` reste inconditionnel.)
- [ ] **Step 6: Run → PASS** + lint.
- [ ] **Step 7: Playtest audit AUD-P1-06/B5.3 (contrôleur)** — entrer en faille, mourir sur le portail : logs montrent **un seul** `Defeat`, aucun `Enter` pendant 6 s ; `PassiveMinute Rate=0` pendant combat ; durée non nulle dans `rift_complete`. Capture → `eyes`.
- [ ] **Step 8: Commit** `fix(faille): anti-reentree, essence passive coupee, relique en defaite, duree reelle`

---

### Task 7: Mythic banni des œufs achetables + ascension bridée par source

**Files:** Modify `src/shared/Config.luau:17-23` · Modify `src/shared/Ascension.luau` · Modify `src/server/Services/HatchService.luau:167-184` · Test `Data_Test.luau` + `Ascension_Test.luau`

**Interfaces:** Produces `Ascension.ClampToSource(rarity: string, source: string): string`. Invariant : au-dessus de Légendaire ⇒ source `"Rift"` uniquement (le Secret passe par `SecretTrigger` et n'est PAS affecté).

- [ ] **Step 1: Tests échouants** —

```lua
	t.test("aucune table d'œuf achetable ne propose Mythic", function()
		for _tier, weights in Config.EGG_RARITY_WEIGHTS do
			expect.equal(weights.Mythic, nil)
		end
	end)
```
```lua
	t.test("ClampToSource plafonne à Legendary hors Faille", function()
		expect.equal(Ascension.ClampToSource("Legendary", "Purchase"), "Legendary")
		expect.equal(Ascension.ClampToSource("Mythic", "Purchase"), "Legendary")
		expect.equal(Ascension.ClampToSource("Mythic", "Rift"), "Mythic")
		expect.equal(Ascension.ClampToSource("Rare", "Purchase"), "Rare")
	end)
```

- [ ] **Step 2: Run → FAIL.**
- [ ] **Step 3: Config** :

```lua
	EGG_RARITY_WEIGHTS = {
		CommonEgg = { Common = 75, Uncommon = 20, Rare = 5 },
		UncommonEgg = { Uncommon = 80, Rare = 20 },
		RareEgg = { Rare = 100 },
		EpicEgg = { Epic = 80, Legendary = 20 },
		LegendaryEgg = { Legendary = 100 },
	},
```

- [ ] **Step 4: Ascension** — après `RollFrom` :

```lua
-- Mythique et au-delà : source Faille exclusive (bible §3.11, B3.41).
function Ascension.ClampToSource(rarity: string, source: string): string
	if Gameplay.RarityRank(rarity) <= Gameplay.RarityRank("Legendary") then
		return rarity
	end
	if source == "Rift" then
		return rarity
	end
	return "Legendary"
end
```

- [ ] **Step 5: HatchService** — entre l'ascension et le Secret :

```lua
	if egg.AscendChance then
		roll.Rarity = Ascension.RollFrom(roll.Rarity, luck, egg.AscendChance)
	end
	roll.Rarity = Ascension.ClampToSource(roll.Rarity, egg.Source or "Purchase")
```

- [ ] **Step 6: Run → PASS** + lint + commit `fix(chasse): mythique exclusif a la faille, ascension bridee par source`

---

### Task 8: Secret — mécanisme côté serveur uniquement

**Files:** Create `src/server/Services/SecretGate.luau` · Modify `src/shared/Ascension.luau` (suppression `SecretTrigger`) · Modify `src/server/Services/HatchService.luau:175-184` (+ Init)

- [ ] **Step 1: Grep `SecretTrigger`** repo entier — recenser tous les appelants (attendu : HatchService serveur uniquement ; si un client référence, noter et traiter).
- [ ] **Step 2: Créer `SecretGate.luau`** :

```lua
--!strict
-- Mécanisme du Secret : résolu CÔTÉ SERVEUR uniquement (bible B3.3/B3.7).
-- Ne jamais déplacer en Shared : le client ne doit pas pouvoir décompiler le procédé.
local SecretGate = {}

function SecretGate.Triggered(eggTier: string, eclipseActive: boolean, relicTier: string?, omen: boolean?): boolean
	if eclipseActive ~= true or relicTier ~= "T3" then
		return false
	end
	if eggTier == "RareEgg" then
		return true
	end
	return omen == true and (eggTier == "EpicEgg" or eggTier == "LegendaryEgg")
end

return SecretGate
```

- [ ] **Step 3: HatchService** — local `secretGate`, résolu dans `Init` via `cont:Get("SecretGate")` ; vérifier que le container enregistre tous les enfants du dossier Services (cf. `Bootstrap.luau`) ; appel remplaçant `Ascension.SecretTrigger(...)` par `secretGate.Triggered(...)`.
- [ ] **Step 4: Supprimer `SecretTrigger`** de `Ascension.luau` + ses cas dans `Ascension_Test.luau` (couverture devient runtime : éclosion RareEgg sous Éclipse + relique T3 → `Hatch Success Rarity=Secret`).
- [ ] **Step 5: Vérification** — grep zéro occurrence `SecretTrigger` restante ; suite verte.
- [ ] **Step 6: Commit** `securite(secret): mecanisme resolu cote serveur uniquement`

---

### Task 9: Portes finales du chantier

- [ ] **Step 1:** `stylua --check src` → corriger tout diff (commit séparé si besoin). **Step 2:** `selene src` → 0 warning (dont `Ui.luau:635`). **Step 3:** suite complète via MCP → `N run, N passed, 0 failed`. **Step 4:** playtest 10 min bout-en-bout (achat → pose → éclosion → faille gagnée ET perdue → renaissance avec 2+ créatures conservées) + console propre. **Step 5:** rapport final avec captures validées `eyes`.
