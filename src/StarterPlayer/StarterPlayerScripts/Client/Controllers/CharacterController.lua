debug.setmemorycategory(script.Name.." OHA")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)

local LocalPlayer = Players.LocalPlayer
local NPC_TAG = "NPC"

local CharacterController = Knit.CreateController{
	Name = script.Name
}

function CharacterController:KnitInit()
	self.ProfileController = Knit.GetController("ProfileController")

	self.CharacterAdded = Signal.new()
	self.CharacterRemoving = Signal.new()

	self.PlayerData = {} -- Keys: Player Instance
	self.NPCData = {}    -- Keys: Model Instance

	self.Character = nil
	self.Humanoid = nil
	self.RootPart = nil
	self.Animator = nil
end

function CharacterController:GetPlayerData(player: Player)
	return self.PlayerData[player]
end

function CharacterController:GetNPCData(model: Model)
	return self.NPCData[model]
end

function CharacterController:LoadAnimation(ID, Animator)
	if Animator then
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. ID
		local loaded = Animator:LoadAnimation(anim)
		anim:Destroy()
		return loaded
	end
end

function CharacterController:Push(targetModel, direction, power, duration)
	local rootPart = targetModel:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	local flatDirection = Vector3.new(direction.X, 0, direction.Z)
	
	if flatDirection.Magnitude < 0.001 then
		flatDirection = -rootPart.CFrame.LookVector
	else
		flatDirection = flatDirection.Unit
	end

	local forceMultiplier = 30 
	local impulse = flatDirection * (power * forceMultiplier) * rootPart.AssemblyMass

	rootPart:ApplyImpulse(impulse)
end

function CharacterController:OnHit(character: Model, hitData: any)
	local PlayerData = self.PlayerData[LocalPlayer]
	if not PlayerData then return end

	if character then
		local direction = (character.PrimaryPart.Position - PlayerData.RootPart.Position).Unit
		self:Push(character, direction, 2, 0.4)
		local Highlight = Instance.new("Highlight")
		Highlight.Adornee = character
		Highlight.FillColor = Color3.fromRGB(255, 0, 0)
		Highlight.FillTransparency = 0.5
		TweenService:Create(Highlight, TweenInfo.new(0.4), {FillTransparency = 1, OutlineTransparency = 1}):Play()
		Highlight.Parent = workspace.Terrain
		task.delay(0.4, function()
			Highlight:Destroy()
		end)
	end
end

function CharacterController:OnCharacterAdded(player: Player?, char: Model)
	local humanoid = char:WaitForChild("Humanoid", 10)
	local rootPart = char:WaitForChild("HumanoidRootPart", 10)
	local animator = humanoid and humanoid:WaitForChild("Animator", 10)

	if not (humanoid and rootPart and animator) then return end

	local data = {
		Character = char,
		Humanoid = humanoid,
		RootPart = rootPart,
		Animator = animator
	}

	if player then
		self.PlayerData[player] = data

		if player == LocalPlayer then
			self.Character = char
			self.Humanoid = humanoid
			self.RootPart = rootPart
			self.Animator = animator
		end
	else
		self.NPCData[char] = data
	end

	for _, Part in pairs(char:GetDescendants()) do
		if Part:IsA("BasePart") then
			CollectionService:AddTag(Part, "SmartCollider")
		end
	end
	
	self.CharacterAdded:Fire(player, char, humanoid, rootPart, animator)
end

function CharacterController:OnCharacterRemoving(target)
	if target:IsA("Player") then
		self.PlayerData[target] = nil

		if target == LocalPlayer then
			self.Character = nil
			self.Humanoid = nil
			self.RootPart = nil
			self.Animator = nil
		end
		self.CharacterRemoving:Fire(target, nil)
	elseif target:IsA("Model") then
		self.NPCData[target] = nil
		self.CharacterRemoving:Fire(nil, target)
	end
end

function CharacterController:KnitStart()
	local function SetupPlayer(player)
		player.CharacterAdded:Connect(function(char)
			self:OnCharacterAdded(player, char)
		end)

		player.CharacterRemoving:Connect(function()
			self:OnCharacterRemoving(player)
		end)

		if player.Character then
			task.spawn(self.OnCharacterAdded, self, player, player.Character)
		end
	end

	Players.PlayerAdded:Connect(SetupPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		SetupPlayer(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		self.PlayerData[player] = nil
	end)

	local function SetupNPC(model)
		if not model:IsDescendantOf(game) then 
			model.AncestryChanged:Wait()
		end
		
		task.spawn(function()
			self:OnCharacterAdded(nil, model)
		end)

		local conn
		conn = model.AncestryChanged:Connect(function(_, parent)
			if not parent then
				conn:Disconnect()
				self:OnCharacterRemoving(model)
			end
		end)
	end

	CollectionService:GetInstanceAddedSignal(NPC_TAG):Connect(SetupNPC)
	
	for _, npc in pairs(CollectionService:GetTagged(NPC_TAG)) do
		SetupNPC(npc)
	end
end

return CharacterController