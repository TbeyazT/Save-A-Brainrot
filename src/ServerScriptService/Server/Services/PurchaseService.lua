local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:FindFirstChild("Packages")

local Knit = require(Packages.Knit)

local PRODUCT_FUNCTIONS = {
	[12345678] = function(player, profile)
		profile.Data.Cash += 100
		print(player.Name .. " bought 100 Cash!")
		return true
	end,
	[87654321] = function(player, profile)
		local char = player.Character
		if char and char:FindFirstChild("Humanoid") then
			char.Humanoid.Health = char.Humanoid.MaxHealth
		end
		return true
	end,
}

local GAMEPASS_FUNCTIONS = {
	[11223344] = function(player, profile)
		print(player.Name .. " bought VIP Gamepass")
	end
}

local PurchaseService = Knit.CreateService{
	Name = script.Name,
	Client = {},
}

function PurchaseService:KnitInit()
	self.DataService = Knit.GetService("ProfileService")
end

function PurchaseService:KnitStart()
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return self:ProcessReceipt(receiptInfo)
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
		if wasPurchased then
			self:OnGamePassPurchased(player, passId)
		end
	end)
end

function PurchaseService:ProcessReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local profile = self.DataService:GetProfile(player)
	if not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local handler = PRODUCT_FUNCTIONS[receiptInfo.ProductId]

	if handler then
		local success, err = pcall(function()
			return handler(player, profile)
		end)

		if success then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		else
			warn("Product Error: " .. tostring(err))
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	else
		warn("No handler found for ProductId: " .. receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.PurchaseGranted 
	end
end

function PurchaseService:OnGamePassPurchased(player, passId)
	local handler = GAMEPASS_FUNCTIONS[passId]
	
	if handler then
		self.ProfileService:TableInsert(player,"Gamepasses",passId)
		handler(player, self.ProfileService)
	end
end

return PurchaseService