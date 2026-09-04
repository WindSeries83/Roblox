--!strict

local PaidRandomPolicy = {}

function PaidRandomPolicy.RequiresEligibility(product: any): boolean
	if type(product) ~= "table" then
		return false
	end
	if product.Kind == "LuckPotion" or product.Kind == "Vip" or product.Kind == "FirstOffer" then
		return true
	end
	return product.Amount ~= nil or product.Creature ~= nil
end

return PaidRandomPolicy
