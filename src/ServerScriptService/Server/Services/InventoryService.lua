local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Assets = ReplicatedStorage:FindFirstChild("Assets")
local Packages = ReplicatedStorage:FindFirstChild("Packages")

local Knit = require(Packages.Knit)

local InventoryService = Knit.CreateService{
	Name = script.Name,
	Client = {
		CallServer = Knit.CreateSignal(),
		RegisterHit = Knit.CreateSignal(),
		RegisterFunction = Knit.CreateSignal(),
	}
}

function InventoryService:GetToolProperties(Name)
	local Module = Assets.ToolProperties:FindFirstChild(Name)
	if Module and Module:IsA("ModuleScript") then 
		local ToolProperties = require(Module)
		return ToolProperties
	end
end

function InventoryService:GetToolModel(Name)
	local Module = Assets.ToolProperties:FindFirstChild(Name)
	if Module and Module:IsA("ModuleScript") then 
		local ToolModel = Module:FindFirstChildWhichIsA("Model")
		return ToolModel
	end
end

function InventoryService:GetToolInstance(character)
	return self.ActiveTools[character]
end

function InventoryService:KnitInit()
	self.ActiveTools = {}

	self.Client.RegisterHit:Connect(function(Player, Data)
		if not Player.Character then return end
		local toolInstance = self.ActiveTools[Player.Character] 
		if toolInstance then
			toolInstance:ProcessHit(Data)
		end
	end)

	self.Client.RegisterFunction:Connect(function(Player, Data)
		if not Player.Character then return end
		local toolInstance = self.ActiveTools[Player.Character]
		if toolInstance and typeof(toolInstance.ProcessFunction) == "function" then
			toolInstance:ProcessFunction(Data)
		end
	end)
end

function InventoryService:KnitStart()
	local CharacterService = Knit.GetService("CharacterService")

	CharacterService.CharacterAdded:Connect(function(data)
		local character = data.Model
		local player = data.Player
		
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") or child:IsA("Model") then
				task.defer(function()
					self:EquipTool(character, child)
				end)
			end
		end

		if data.Dumpster then
			data.Dumpster:Connect(character.ChildAdded, function(child)
				if child:IsA("Tool") or child:IsA("Model") then
					self:EquipTool(character, child)
				end
			end)

			data.Dumpster:Connect(character.ChildRemoved, function(child)
				local currentTool = self.ActiveTools[character]
				if currentTool and currentTool.Tool == child then
					self:UnequipTool(character)
				end
			end)
		end
	end)

	CharacterService.CharacterRemoved:Connect(function(model)
		self:UnequipTool(model)
	end)
end

function InventoryService:EquipTool(character, toolOrName)
	local toolModel
	
	if type(toolOrName) == "string" then
		local sourceModel = self:GetToolModel(toolOrName)
		if not sourceModel then 
			warn("InventoryService: Could not find model for " .. toolOrName)
			return 
		end
		
		toolModel = sourceModel:Clone()
		toolModel.Parent = character 
	else
		toolModel = toolOrName
	end
	
	local currentData = self.ActiveTools[character]
	if currentData and currentData.Tool == toolModel then 
		return 
	end

	self:UnequipTool(character)

	local RightArm = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand")

	if RightArm then
		if toolModel:IsA("Tool") then
			task.defer(function()
				local RightGrip = RightArm:FindFirstChild("RightGrip")
				if RightGrip then RightGrip:Destroy() end
			end)
		end

		local motor = toolModel:FindFirstChildWhichIsA("Motor6D", true)
		if motor then
			motor.Part0 = RightArm
			if not motor.Part1 and toolModel:FindFirstChild("Handle") then
				motor.Part1 = toolModel.Handle
			end
		end
	end

	local ToolClassModule = Assets.ToolClasses:FindFirstChild(toolModel.Name)
	if not ToolClassModule then return end
	local ToolClass = require(ToolClassModule)

	local player = Players:GetPlayerFromCharacter(character)

	local newInstance = ToolClass.new(player, toolModel, character) 
	
	self.ActiveTools[character] = newInstance
	return newInstance
end

function InventoryService:UnequipTool(character)
	local instance = self.ActiveTools[character]
	if instance then
		if instance.Destroy then
			instance:Destroy()
		end
		if instance.Tool and instance.Tool.Parent == character then
			instance.Tool:Destroy()
		end
		self.ActiveTools[character] = nil
	end
end

return InventoryService