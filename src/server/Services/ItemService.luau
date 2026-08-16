local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Equipment = require(ReplicatedStorage.Shared.Data.Equipment)
local Evolution = require(ReplicatedStorage.Shared.Evolution)
local Net = require(ReplicatedStorage.Shared.Net)

local ItemService = {}

local log
local saveService
local essenceService
local dataSync

local function FindCreature(creatures: { any }, creatureId: string)
	for i, creature in creatures do
		if creature.Id == creatureId then
			return creature, i
		end
	end
	return nil, nil
end

local function FindItem(items: { any }, itemId: string)
	for i, item in items do
		if item.Id == itemId then
			return item, i
		end
	end
	return nil, nil
end

local function ItemDef(itemType: string, tier: number)
	local def = Equipment[itemType]
	if not def then
		return nil
	end
	return def.Tiers[tier]
end

function ItemService:GrantItem(player: Player, itemType: string, tier: number, source: string): boolean
	local profile = saveService:GetProfile(player)
	if not profile then
		return false
	end
	if not ItemDef(itemType, tier) then
		return false
	end
	local item = {
		Id = HttpService:GenerateGUID(false),
		Type = itemType,
		Tier = tier,
	}
	table.insert(profile.Data.Items, item)
	profile.Data.LastPlayed = os.time()
	log:Economy(
		"Items",
		"Grant",
		{ Player = player.Name, Type = itemType, Tier = tier, Source = source, ItemId = item.Id }
	)
	return true
end

function ItemService:Init(container)
	log = container:Get("Log")
	saveService = container:Get("SaveService")
	essenceService = container:Get("EssenceService")
	dataSync = container:Get("DataSync")
end

function ItemService:Start()
	Net.BuyItem.OnServerEvent:Connect(function(player: Player, itemType: string, tier: number)
		local def = ItemDef(itemType, tier)
		if not def or def.DropOnly or Equipment[itemType].DropOnly then
			return
		end
		if not def.Price then
			return
		end
		if not essenceService:Spend(player, def.Price, `BuyItem_{itemType}T{tier}`) then
			return
		end
		self:GrantItem(player, itemType, tier, "Purchase")
		dataSync:Send(player)
	end)

	Net.EquipItem.OnServerEvent:Connect(function(player: Player, creatureId: string, itemId: string)
		local profile = saveService:GetProfile(player)
		if not profile then
			return
		end
		local creature = FindCreature(profile.Data.Creatures, creatureId)
		local item, itemIndex = FindItem(profile.Data.Items, itemId)
		if not creature or not item or not itemIndex then
			return
		end
		if #creature.Equipment >= Evolution.SlotsForStage(creature.Stage) then
			return
		end
		table.remove(profile.Data.Items, itemIndex)
		table.insert(creature.Equipment, item)
		creature.MaxLevel = Evolution.MaxLevelFor(creature)
		profile.Data.LastPlayed = os.time()
		log:Economy(
			"Items",
			"Equip",
			{ Player = player.Name, Creature = creature.Id, Type = item.Type, Tier = item.Tier }
		)
		dataSync:Send(player)
	end)

	Net.UnequipItem.OnServerEvent:Connect(function(player: Player, creatureId: string, itemId: string)
		local profile = saveService:GetProfile(player)
		if not profile then
			return
		end
		local creature = FindCreature(profile.Data.Creatures, creatureId)
		if not creature then
			return
		end
		local item, index = FindItem(creature.Equipment, itemId)
		if not item or not index then
			return
		end
		table.remove(creature.Equipment, index)
		table.insert(profile.Data.Items, item)
		creature.MaxLevel = Evolution.MaxLevelFor(creature)
		profile.Data.LastPlayed = os.time()
		log:Economy(
			"Items",
			"Unequip",
			{ Player = player.Name, Creature = creature.Id, Type = item.Type, Tier = item.Tier }
		)
		dataSync:Send(player)
	end)
end

return ItemService
