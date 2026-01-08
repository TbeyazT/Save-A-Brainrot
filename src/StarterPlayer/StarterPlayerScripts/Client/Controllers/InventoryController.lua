debug.setmemorycategory(script.Name)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local Knit = require(Packages.Knit)
local LocalPlayer = Players.LocalPlayer

local InventoryController = Knit.CreateController {
	Name = script.Name
}

function InventoryController:KnitInit()
	self.ProfileController = Knit.GetController("ProfileController")
	self.ToolService = Knit.GetService("InventoryService")
	self.CurrentToolClass = nil
end

function InventoryController:KnitStart()
	if LocalPlayer.Character then
		self:OnCharacterAdded(LocalPlayer.Character)
	end
	
	LocalPlayer.CharacterAdded:Connect(function(Char)
		self:OnCharacterAdded(Char)
	end)
	
	LocalPlayer.CharacterRemoving:Connect(function()
		self:CleanupCurrentTool()
	end)
end

function InventoryController:OnCharacterAdded(Character)
	for _, child in pairs(Character:GetChildren()) do
		if child:IsA("Tool") then
			self:EquipTool(child)
		end
	end

	Character.ChildAdded:Connect(function(Child)
		if Child:IsA("Tool") then
			self:EquipTool(Child)
		end
	end)

	Character.ChildRemoved:Connect(function(Child)
		if self.CurrentToolClass and self.CurrentToolClass.Tool == Child then
			self:CleanupCurrentTool()
		end
	end)
end

function InventoryController:EquipTool(Tool)
	self:CleanupCurrentTool()

	local ToolModuleName = Tool.Name
	local ToolModule = Assets.ToolClasses:FindFirstChild(ToolModuleName)

	if ToolModule then
		local Class = require(ToolModule)
		
		local success, result = pcall(function()
			return Class.new(LocalPlayer, Tool)
		end)

		if success and result then
			self.CurrentToolClass = result
			
			if Tool.Parent ~= LocalPlayer.Character then
				self:CleanupCurrentTool()
				return
			end
			
			self.CurrentToolClass:Init()
		else
			warn("Failed to load tool class for:", ToolModuleName, result)
		end
	end
end

function InventoryController:CleanupCurrentTool()
	if self.CurrentToolClass then
		if type(self.CurrentToolClass.Destroy) == "function" then
			self.CurrentToolClass:Destroy()
		end
		self.CurrentToolClass = nil
	end
end

return InventoryController