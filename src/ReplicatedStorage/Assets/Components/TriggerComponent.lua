local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Signal = require(Packages.Signal)

local HitPartComponent = {}
HitPartComponent.__index = HitPartComponent

local activeComponents = {}
local runServiceConnection = nil

function HitPartComponent.new(part: BasePart)
	local self = setmetatable({}, HitPartComponent)

	self.part = part
	self.currentPlayers = {} -- format: { [Player] = true }

	self.OnTouched = Signal.new()      
	self.OnTouchEnded = Signal.new()   

	self.overlapParams = OverlapParams.new()
	self.overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	self.overlapParams.FilterDescendantsInstances = {part}

	table.insert(activeComponents, self)

	if not runServiceConnection then
		runServiceConnection = RunService.Heartbeat:Connect(HitPartComponent.updateAll)
	end

	return self
end

function HitPartComponent.updateAll()
	for i = #activeComponents, 1, -1 do
		activeComponents[i]:checkProximity()
	end
end

function HitPartComponent:checkProximity()
	if not self.part then
		self:Destroy()
		return
	end

	if not self.part.Parent then
		for player, _ in pairs(self.currentPlayers) do
			self.currentPlayers[player] = nil
			self.OnTouchEnded:Fire(player)
		end
		return
	end

	local foundPlayers = {}

	local partsInPart = workspace:GetPartsInPart(self.part, self.overlapParams)

	for _, hitPart in ipairs(partsInPart) do
		local character = hitPart.Parent
		if character then
			local player = Players:GetPlayerFromCharacter(character)
			if player then
				foundPlayers[player] = true
			end
		end
	end

	for player, _ in pairs(foundPlayers) do
		if not self.currentPlayers[player] then
			self.currentPlayers[player] = true
			self.OnTouched:Fire(player)
		end
	end

	for player, _ in pairs(self.currentPlayers) do
		if not foundPlayers[player] or not player.Parent then
			self.currentPlayers[player] = nil
			self.OnTouchEnded:Fire(player)
		end
	end
end

function HitPartComponent:Destroy()
	for i, component in ipairs(activeComponents) do
		if component == self then
			table.remove(activeComponents, i)
			break
		end
	end

	self.OnTouched:DisconnectAll()
	self.OnTouchEnded:DisconnectAll()

	self.part = nil
	self.currentPlayers = nil
	self.overlapParams = nil

	setmetatable(self, nil)

	if #activeComponents == 0 and runServiceConnection then
		runServiceConnection:Disconnect()
		runServiceConnection = nil
	end
end

return HitPartComponent