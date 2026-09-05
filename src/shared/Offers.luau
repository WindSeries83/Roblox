--!strict

local DAY = 86400
local PaidRandomPolicy = require(script.Parent.PaidRandomPolicy)

local Offers = {}

-- IDs/prices are intentionally empty until a human validates the commercial setup.
Offers.All = {
	StarterBundle = {
		Id = "StarterBundle",
		Sku = 0,
		ConfigKey = "FirstPurchaseOffer",
		Kind = "DeveloperProduct",
		Audience = "FirstHatch",
		Trigger = "AfterFirstCreature",
		Duration = 0,
		ValueText = "2000 Essence + 1 créature Rare Shadow",
		PriceText = "À définir",
		Enabled = false,
	},
	LuckPotionSmall = {
		Id = "LuckPotionSmall",
		Sku = 0,
		ConfigKey = "LuckPotionSmall",
		Kind = "DeveloperProduct",
		Audience = "All",
		Trigger = "Shop",
		Duration = 600,
		ValueText = "+15 % chance (plafond chance : +100 %)",
		PriceText = "À définir",
		Enabled = false,
	},
	LuckPotionBig = {
		Id = "LuckPotionBig",
		Sku = 0,
		ConfigKey = "LuckPotionBig",
		Kind = "DeveloperProduct",
		Audience = "All",
		Trigger = "Shop",
		Duration = 1800,
		ValueText = "+35 % chance (plafond chance : +100 %)",
		PriceText = "À définir",
		Enabled = false,
	},
	EssencePackSmall = {
		Id = "EssencePackSmall",
		Sku = 0,
		ConfigKey = "EssencePackSmall",
		Kind = "DeveloperProduct",
		Audience = "All",
		Trigger = "Shop",
		Duration = 0,
		ValueText = "500 Essence",
		PriceText = "À définir",
		Enabled = false,
	},
	EssencePackMedium = {
		Id = "EssencePackMedium",
		Sku = 0,
		ConfigKey = "EssencePackMedium",
		Kind = "DeveloperProduct",
		Audience = "All",
		Trigger = "Shop",
		Duration = 0,
		ValueText = "2500 Essence",
		PriceText = "À définir",
		Enabled = false,
	},
	EssencePackLarge = {
		Id = "EssencePackLarge",
		Sku = 0,
		ConfigKey = "EssencePackLarge",
		Kind = "DeveloperProduct",
		Audience = "All",
		Trigger = "Shop",
		Duration = 0,
		ValueText = "10000 Essence",
		PriceText = "À définir",
		Enabled = false,
	},
	ServerBoost = {
		Id = "ServerBoost",
		Sku = 0,
		ConfigKey = "ServerBoostProduct",
		Kind = "DeveloperProduct",
		Audience = "All",
		Trigger = "Shop",
		Duration = 900,
		ValueText = "+25 % Essence pour tout le serveur",
		PriceText = "À définir",
		Enabled = false,
	},
	Vip30Days = {
		Id = "Vip30Days",
		Sku = 0,
		ConfigKey = "Vip30Days",
		Kind = "DeveloperProduct",
		Audience = "All",
		Trigger = "Shop",
		Duration = 30 * DAY,
		ValueText = "VIP 30 jours : +10 % chance + cadeau quotidien de 300 Essence",
		PriceText = "À définir",
		Enabled = false,
	},
	ReturnD2 = {
		Id = "ReturnD2",
		Sku = 0,
		ConfigKey = "ReturnD2",
		Kind = "Free",
		Audience = "Returning",
		Trigger = "D2",
		Duration = 0,
		ValueText = "Cadeau de retour : 500 Essence",
		PriceText = "Gratuit",
		Enabled = false,
	},
	ReturnD7 = {
		Id = "ReturnD7",
		Sku = 0,
		ConfigKey = "ReturnD7",
		Kind = "Free",
		Audience = "Returning",
		Trigger = "D7",
		Duration = 0,
		ValueText = "Cadeau de retour : 2000 Essence",
		PriceText = "Gratuit",
		Enabled = false,
	},
	SeasonPremium = {
		Id = "SeasonPremium",
		Sku = 0,
		ConfigKey = "SeasonPremium",
		Kind = "GamePass",
		Audience = "Season",
		Trigger = "SeasonStart",
		Duration = 14 * DAY,
		ValueText = "Piste premium : récompenses Essence + CinderSeraph + titre Éclat de la Faille",
		PriceText = "À définir",
		Enabled = false,
	},
}

function Offers.IsAvailable(offer: any): boolean
	return type(offer) == "table"
		and offer.Enabled == true
		and type(offer.Id) == "string"
		and offer.Id ~= ""
		and offer.Id ~= "0"
		and type(offer.Sku) == "number"
		and offer.Sku > 0
		and offer.Sku == math.floor(offer.Sku)
		and type(offer.Audience) == "string"
		and offer.Audience ~= ""
		and type(offer.Trigger) == "string"
		and offer.Trigger ~= ""
		and type(offer.Duration) == "number"
		and offer.Duration >= 0
		and type(offer.ValueText) == "string"
		and offer.ValueText ~= ""
		and type(offer.PriceText) == "string"
		and offer.PriceText ~= ""
		and offer.PriceText ~= "À définir"
end

local function HasFirstCreature(data: any): boolean
	local stats = if data then data.Stats else nil
	if stats and type(stats.TotalHatched) == "number" and stats.TotalHatched > 0 then
		return true
	end
	return data ~= nil and type(data.Creatures) == "table" and #data.Creatures > 0
end

function Offers.IsVisible(offer: any, data: any, featureUnlocks: any, now: number?): boolean
	if not Offers.IsAvailable(offer) then
		return false
	end
	if offer.Trigger == "AfterFirstCreature" and not HasFirstCreature(data) then
		return false
	elseif offer.Trigger == "Shop" and (not featureUnlocks or featureUnlocks.Shop ~= true) then
		return false
	elseif offer.Trigger == "D2" or offer.Trigger == "D7" then
		local lastPlayed = if data and type(data.LastPlayed) == "number" then data.LastPlayed else 0
		local day = if lastPlayed > 0 then Offers.ReturnDay((now or os.time()) - lastPlayed) else nil
		if day ~= offer.Trigger or not Offers.ReturnGiftDue(data, day) then
			return false
		end
	elseif offer.Trigger == "SeasonStart" and not (data and data.Season ~= nil) then
		return false
	end
	return true
end

function Offers.VisibleFor(data: any, featureUnlocks: any, now: number?): { [string]: any }
	local visible = {}
	for key, offer in Offers.All do
		if Offers.IsVisible(offer, data, featureUnlocks, now) then
			visible[key] = {
				Id = offer.Id,
				Sku = offer.Sku,
				Kind = offer.Kind,
				Audience = offer.Audience,
				Trigger = offer.Trigger,
				Duration = offer.Duration,
				ValueText = offer.ValueText,
				PriceText = offer.PriceText,
				Enabled = offer.Enabled,
			}
		end
	end
	return visible
end

function Offers.FilterPaidRandom(
	catalog: { [string]: any },
	policy: any,
	products: { [string]: any }
): { [string]: any }
	local filtered = table.clone(catalog)
	for key in filtered do
		local definition = Offers.All[key]
		local product = definition and (products[definition.ConfigKey] or definition)
		if
			PaidRandomPolicy.RequiresEligibility(product)
			and (not policy or not policy.Loaded or policy.ArePaidRandomItemsRestricted)
		then
			filtered[key] = nil
		end
	end
	return filtered
end

-- Jour de retour : D2 dès 1 jour d'absence, D7 dès 6 jours.
function Offers.ReturnDay(elapsed: number): string?
	if elapsed >= 6 * DAY then
		return "D7"
	elseif elapsed >= DAY then
		return "D2"
	end
	return nil
end

function Offers.ReturnGiftDue(data: any, day: string): boolean
	local offerState = if data then data.Offers else nil
	local gifts = if offerState then offerState.ReturnGifts else nil
	return type(gifts) == "table" and gifts[day] ~= true
end

return Offers
