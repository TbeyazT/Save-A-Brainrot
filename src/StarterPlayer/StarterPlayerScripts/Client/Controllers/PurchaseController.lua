local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local Knit = require(Packages.Knit)

local LocalPlayer = Players.LocalPlayer

local PurchaseController = Knit.CreateController {
	Name = script.Name
}

-- Call this from your UI Buttons for Dev Products (Gold, Potions)
function PurchaseController:PromptProduct(productId)
	local success, err = pcall(function()
		MarketplaceService:PromptProductPurchase(LocalPlayer, productId)
	end)
	
	if not success then
		warn("Failed to prompt product purchase: " .. tostring(err))
	end
end

-- Call this from your UI Buttons for Gamepasses (VIP, Double Speed)
function PurchaseController:PromptGamePass(gamePassId)
	local success, err = pcall(function()
		MarketplaceService:PromptGamePassPurchase(LocalPlayer, gamePassId)
	end)

	if not success then
		warn("Failed to prompt gamepass purchase: " .. tostring(err))
	end
end

function PurchaseController:KnitInit()
	self.ProfileController = Knit.GetController("ProfileController")
end

function PurchaseController:KnitStart()
	-- Wait for data to load
	local attempts = 0
	while not self.ProfileController:IsLoaded() do
		task.wait(0.5)
		attempts += 1
		if attempts > 20 then
			warn("ProfileController took too long to load! forcing "..script.Name.." initialization.")
			break
		end
	end
	
	print("PurchaseController Initialized")
end

return PurchaseController