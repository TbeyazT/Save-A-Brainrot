debug.setmemorycategory(script.Name.." OHA")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)

local LocalPlayer = Players.LocalPlayer

local CharacterController = Knit.CreateController{
	Name = script.Name
}

function CharacterController:KnitInit()
	self.ProfileController = Knit.GetController("ProfileController")

	self.CharacterAdded = Signal.new()
	self.CharacterRemoving = Signal.new()

	self.PlayerData = {}

	self.Character = nil
	self.Humanoid = nil
	self.RootPart = nil
	self.Animator = nil
end

function CharacterController:GetPlayerData(player: Player)
	return self.PlayerData[player]
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

function CharacterController:OnCharacterAdded(player: Player, char: Model)
	local humanoid = char:WaitForChild("Humanoid", 10)
	local rootPart = char:WaitForChild("HumanoidRootPart", 10)
	local animator = humanoid:WaitForChild("Animator", 10)

	if not (humanoid and rootPart and animator) then return end

	self.PlayerData[player] = {
		Character = char,
		Humanoid = humanoid,
		RootPart = rootPart,
		Animator = animator
	}

	if player == LocalPlayer then
		self.Character = char
		self.Humanoid = humanoid
		self.RootPart = rootPart
		self.Animator = animator
	end

	for _, Part in pairs(char:GetDescendants()) do
		if Part:IsA("BasePart") then
			CollectionService:AddTag(Part, "SmartCollider")
		end
	end
	
	self.CharacterAdded:Fire(player, char, humanoid, rootPart, animator)
end

function CharacterController:OnCharacterRemoving(player: Player)
	self.PlayerData[player] = nil

	if player == LocalPlayer then
		self.Character = nil
		self.Humanoid = nil
		self.RootPart = nil
		self.Animator = nil
	end

	self.CharacterRemoving:Fire(player)
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
end

return CharacterController