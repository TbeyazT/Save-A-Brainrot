local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local GoodSignal = require(Assets.Modules.GoodSignal)

local HitPartComponent = {}

local activeComponents = {}
local runServiceConnection = nil
local isServer = RunService:IsServer()

function HitPartComponent.new(part: BasePart)
	local self = setmetatable({}, {__index = HitPartComponent})
	self.part = part
	self.isTouched = false
	self.currentPlayers = {} -- Track multiple players
	self.DumpTouched = nil
	self.OnTouched = GoodSignal.new()      -- Fires: player
	self.OnTouchEnded = GoodSignal.new()   -- Fires: player

	table.insert(activeComponents, self)

	if not self.part:IsA("TouchTransmitter") then
		self.DumpTouched = self.part.Touched:Connect(function() end)
	end

	if not runServiceConnection then
		runServiceConnection = RunService.Heartbeat:Connect(HitPartComponent.updateAll)
	end

	return self
end

function HitPartComponent.updateAll()
	for _, component in ipairs(activeComponents) do
		component:checkProximity()
	end
end

function HitPartComponent:checkProximity()
	if not self.part then return end

	local currentlyTouching = {}
	local touchingParts = self.part:GetTouchingParts()

	for _, touchingPart in ipairs(touchingParts) do
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			if character and touchingPart:IsDescendantOf(character) then
				currentlyTouching[player] = true
			end
		end
	end

	for player in pairs(currentlyTouching) do
		if not self.currentPlayers[player] then
			self.currentPlayers[player] = true
			print("Touched:", player)
			self.OnTouched:Fire(player)
		end
	end

	for player in pairs(self.currentPlayers) do
		if not currentlyTouching[player] then
			self.currentPlayers[player] = nil
			print("UnTouched:", player)
			self.OnTouchEnded:Fire(player)
		end
	end
end

function HitPartComponent:destroy()
	for i, component in ipairs(activeComponents) do
		if component == self then
			table.remove(activeComponents, i)
			break
		end
	end

	self.OnTouched:DisconnectAll()
	self.OnTouchEnded:DisconnectAll()
	if self.DumpTouched then
		self.DumpTouched:Disconnect()
	end
	setmetatable(self, nil)

	if #activeComponents == 0 and runServiceConnection then
		runServiceConnection:Disconnect()
		runServiceConnection = nil
	end
end

return HitPartComponent