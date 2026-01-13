local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Assets = ReplicatedStorage:FindFirstChild("Assets")
local Packages = ReplicatedStorage:FindFirstChild("Packages")

local EggRarities = require(Assets.Modules.Weights.EggRarities)

local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)
local TableUtil = require(Packages.TableUtil)

local PetService = Knit.CreateService{
	Name = script.Name
}

function PetService:GetPetProperties(Name)
	local Module = Assets.PetProperties:FindFirstChild(Name)
	if Module then
		return require(Module)
	end
	return nil
end

function PetService:GetPetModel(Name)
	local Module = Assets.PetProperties:FindFirstChild(Name)
	if Module then
		local Model = Module:FindFirstChildWhichIsA("Model")
		if Model then
			return Model
		end
	end
	return nil
end

function PetService:CreatePet(Name)
	local Properties = self:GetPetProperties(Name)
	if Properties then
		local Table = {
			Name = Name,
			ID = HttpService:GenerateGUID(),
			Equipped = false,
			Level = 0,
		}
		return Table
	end
end

function PetService:GivePet(Player:Player,Name,Equip)
	local CreatedPet = self:CreatePet(Name)
	if CreatedPet then
		if Equip then
			CreatedPet.Equipped = true
		end
		self.ProfileService:TableInsert(Player,"Pets",CreatedPet)
	end
end

local function GetWeightedRarity(Weights)
	local TotalWeight = 0
	for _, Weight in pairs(Weights) do
		TotalWeight += Weight
	end

	local RandomNum = math.random() * TotalWeight
	local CurrentWeight = 0

	for Rarity, Weight in pairs(Weights) do
		CurrentWeight += Weight
		if RandomNum <= CurrentWeight then
			return Rarity
		end
	end
end

function PetService:OpenEgg(Player, EggName, Amount)
	local Weights = EggRarities[EggName]
	if not Weights then 
		warn("Egg weights not found for: " .. tostring(EggName))
		return 
	end

	local PetsInEgg = {}

	for _, Module in ipairs(Assets.PetProperties:GetChildren()) do
		if Module:IsA("ModuleScript") then
			local Props = require(Module)
			if Props.Egg == EggName then
				if not PetsInEgg[Props.Rarity] then
					PetsInEgg[Props.Rarity] = {}
				end
				table.insert(PetsInEgg[Props.Rarity], Props.Name)
			end
		end
	end

	local Results = {}

	for i = 1, (Amount or 1) do
		local PickedRarity = GetWeightedRarity(Weights)

		local PossiblePets = PetsInEgg[PickedRarity]

		if not PossiblePets or #PossiblePets == 0 then
			PossiblePets = PetsInEgg["Common"]
		end

		if PossiblePets and #PossiblePets > 0 then
			local ChosenPetName = PossiblePets[math.random(1, #PossiblePets)]

			self:GivePet(Player, ChosenPetName, false)

			table.insert(Results, ChosenPetName)
		end
	end

	return Results
end

function PetService.Client:OpenEgg(...)
	warn(self)
	return self.Server:OpenEgg(...)
end

function PetService:KnitInit ()
	self.ProfileService = Knit.GetService("ProfileService")
end

return PetService