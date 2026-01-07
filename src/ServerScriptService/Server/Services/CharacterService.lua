debug.setmemorycategory(script.Name.." OHA")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local Dumpster = require(Packages.Dumpster)
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)

local NPC_TAG = "NPC"
local CharacterService = Knit.CreateService {
	Name = script.Name,
	Client = {},
}

function CharacterService:KnitInit()
	self.ProfileService = Knit.GetService("ProfileService")
	self._registry = {}

	self.CharacterAdded = Signal.new()
	self.CharacterRemoved = Signal.new()
end

function CharacterService:KnitStart()
	self.ProfileService:ObservePlayerAdded(function(player)
		player.CharacterAdded:Connect(function(character)
			self:RegisterCharacter(character, player)
		end)

		if player.Character then
			self:RegisterCharacter(player.Character, player)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		if player.Character then
			self:UnregisterCharacter(player.Character)
		end
	end)

	CollectionService:GetInstanceAddedSignal(NPC_TAG):Connect(function(npc)
		self:RegisterCharacter(npc, nil) 
	end)

	for _, npc in ipairs(CollectionService:GetTagged(NPC_TAG)) do
		self:RegisterCharacter(npc, nil)
	end
end

function CharacterService:RegisterCharacter(model, player)
	if self._registry[model] then return end

	local humanoid = model:FindFirstChildWhichIsA("Humanoid")
	local rootPart = model:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart then
		return 
	end

	local dumpster = Dumpster.new()

	local container = {
		Model = model,
		Humanoid = humanoid,
		RootPart = rootPart,
		Animator = humanoid:FindFirstChild("Animator") or humanoid:WaitForChild("Animator", 5),
		Player = player, -- Will be nil for NPCs
		IsPlayer = (player ~= nil),
		Dumpster = dumpster
	}

	self._registry[model] = container
	
	dumpster:Connect(model.AncestryChanged, function(_, parent)
		if parent == nil then
			self:UnregisterCharacter(model)
		end
	end)

	dumpster:Connect(humanoid.Died, function()

	end)

	self.CharacterAdded:Fire(container)

	return container
end

function CharacterService:UnregisterCharacter(model)
	local container = self._registry[model]
	if container then
		container.Dumpster:Destroy()
		self._registry[model] = nil
		self.CharacterRemoved:Fire(model)
	end
end

function CharacterService:GetCharacter(target)
	if not target then return nil end

	local model

	if target:IsA("Player") then
		model = target.Character
	elseif target:IsA("Model") then
		model = target
	elseif target:IsA("BasePart") then
		model = target.Parent
	end

	if model then
		return self._registry[model]
	end

	return nil
end

function CharacterService:PushCharacter(target, direction, force, duration)
	local charData = self:GetCharacter(target)
	if not charData then return end

	local rootPart = charData.RootPart

	local attachment = Instance.new("Attachment")
	attachment.Name = "PushAttachment"
	attachment.Parent = rootPart

	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "PushVelocity"
	velocity.Attachment0 = attachment
	velocity.MaxForce = math.huge 
	velocity.VectorVelocity = direction.Unit * force 
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.Parent = attachment

	task.delay(duration or 0.2, function()
		if attachment and attachment.Parent then
			attachment:Destroy()
		end
	end)
end

return CharacterService