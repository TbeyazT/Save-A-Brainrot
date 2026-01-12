debug.setmemorycategory(script.Name)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)

local LocalPlayer = Players.LocalPlayer

local InventoryController = Knit.CreateController {
	Name = script.Name
}

function InventoryController:GetToolProperties(name)
	local module = Assets.ToolProperties:FindFirstChild(name)
	if module and module:IsA("ModuleScript") then
		return require(module)
	end
	return nil
end

function InventoryController:GetToolModel(name)
	local module = Assets.ToolProperties:FindFirstChild(name)
	if module and module:IsA("ModuleScript") then 
		return module:FindFirstChildWhichIsA("Model")
	end
	return nil
end

function InventoryController:TrackCharacter(character)
	if not character then return end
	
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") or child:IsA("Model") then
			task.defer(function()
				self:EquipTool(character, child)
			end)
		end
	end

	local childAdded = character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") or child:IsA("Model") then
			self:EquipTool(character, child)
		end
	end)

	local childRemoved = character.ChildRemoved:Connect(function(child)
		local currentInstance = self.ActiveTools[character]
		if currentInstance and currentInstance.Tool == child then
			self:UnequipTool(character)
		end
	end)
	
	local destroying; destroying = character.Destroying:Connect(function()
		self:UnequipTool(character)
		if childAdded then childAdded:Disconnect() end
		if childRemoved then childRemoved:Disconnect() end
		if destroying then destroying:Disconnect() end
	end)
end

function InventoryController:CreateTool(Name)
	local sourceModel = self:GetToolModel(Name)
	if not sourceModel then 
		warn("InventoryController: Could not find model for " .. Name)
		return 
	end
	
	local toolInstance = sourceModel:Clone()
	
	return toolInstance
end

function InventoryController:EquipTool(character, Tool,ID)
	local toolInstance
	
	if type(Tool) == "string" then
		local sourceModel = self:GetToolModel(Tool)
		if not sourceModel then 
			warn("InventoryController: Could not find model for " .. Tool)
			return 
		end
		
		toolInstance = sourceModel:Clone()
		toolInstance.Parent = character
	else
		toolInstance = Tool
	end
	
	local currentData = self.ActiveTools[character]
	if currentData and currentData.Tool == toolInstance then 
		return 
	end

	self:UnequipTool(character)
	
	local rightArm = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand")
	if rightArm then
		if toolInstance:IsA("Tool") then
			task.defer(function()
				local rightGrip = rightArm:FindFirstChild("RightGrip")
				if rightGrip then rightGrip:Destroy() end
			end)
		end

		local motor = toolInstance:FindFirstChildWhichIsA("Motor6D", true)
		if motor then
			motor.Part0 = rightArm
			if not motor.Part1 and toolInstance:FindFirstChild("Handle") then
				motor.Part1 = toolInstance.Handle
			end
		end
	end

	local toolModuleName = toolInstance.Name
	local toolModule = Assets.ToolClasses:FindFirstChild(toolModuleName)

	if not toolModule then return end

	local ToolClass = require(toolModule)
	local ownerPlayer = Players:GetPlayerFromCharacter(character)
	
	local success, result = pcall(function()
		return ToolClass.new(ownerPlayer or ID, toolInstance, character)
	end)

	if success and result then
		self.ActiveTools[character] = result

		if toolInstance.Parent ~= character then
			self:UnequipTool(character)
			return
		end

		if type(result.Init) == "function" then
			result:Init()
		end
	else
		warn("InventoryController: Failed to load class for", toolModuleName, result)
	end
	
	return result
end

function InventoryController:UnequipTool(character)
	local instance = self.ActiveTools[character]
	
	if instance then
		if type(instance.Destroy) == "function" then
			instance:Destroy()
		end
		
		-- If we created the tool via String (Client side clone), we should probably clean up the physical tool too
		-- Checks if the tool is still parented to the character
		if instance.Tool and instance.Tool.Parent == character then
			-- Optional: Logic to destroy the tool model if the Controller was the one who made it.
			-- For now, we leave it to Roblox replication or the caller, unless it's strictly local.
			-- If you called EquipTool("Name"), you might want to Destroy it here:
			-- instance.Tool:Destroy() 
		end
		
		self.ActiveTools[character] = nil
	end
end

function InventoryController:KnitInit()
	self.InventoryService = Knit.GetService("InventoryService")
	self.ActiveTools = {} -- [Character] = ToolClass

	self.ActivatedTool = Signal.new()
end

function InventoryController:KnitStart()
	if LocalPlayer.Character then
		self:TrackCharacter(LocalPlayer.Character)
	end
	LocalPlayer.CharacterAdded:Connect(function(char)
		self:TrackCharacter(char)
	end)

	for _, npc in ipairs(CollectionService:GetTagged("NPC")) do
		self:TrackCharacter(npc)
	end
	
	CollectionService:GetInstanceAddedSignal("NPC"):Connect(function(npc)
		self:TrackCharacter(npc)
	end)

	self.ActivatedTool:Connect(function(character, tool)
		if character ~= LocalPlayer.Character then
			return 
		end

		local Properties = self:GetToolProperties(tool.Name)
	end)
end

return InventoryController