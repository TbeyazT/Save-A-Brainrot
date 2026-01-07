debug.setmemorycategory(script.Name.." OHA")

--[[
    ProfileController
    Client-side handler for ProfileService. Interfaces with ReplicaController.
]]

-------------------------- Roblox Services --------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-------------------------- Packages --------------------------
local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

-------------------------- Modules --------------------------
local ReplicaController = require(ReplicatedStorage:WaitForChild("ReplicaController"))

-------------------------- Constants --------------------------
local PROFILE_CLASS_TOKEN = "PlayerProfile" -- Must match Server Script

-------------------------- Controller --------------------------
local ProfileController = Knit.CreateController {
	Name = "ProfileController",
}

-------------------------- State --------------------------
-- Cache Replicas by Player for fast access
-- [Player] = Replica
ProfileController._replicas = {} 
ProfileController._replicaLoadedSignals = {} -- [Player] = Signal

-------------------------- Lifecycle --------------------------

function ProfileController:KnitStart()
	-- Listen for ANY Profile being created (ours or other players)
	ReplicaController.ReplicaOfClassCreated(PROFILE_CLASS_TOKEN, function(replica)
		local player = replica.Tags.Player
		if player then
			self:_setupReplica(player, replica)
		end
	end)
end

function ProfileController:KnitInit()
	ReplicaController.RequestData()
end

-------------------------- Public API --------------------------

-- Checks if a specific player's data is loaded on the client
function ProfileController:IsLoaded(player: Player?): boolean
	player = player or Players.LocalPlayer
	return self._replicas[player] ~= nil
end

-- Returns a Promise that resolves with the value of the key.
-- Usage: ProfileController:Get("Coins"):andThen(print)
function ProfileController:Get(key: string, player: Player?): "Promise"
	player = player or Players.LocalPlayer

	return self:_getReplica(player):andThen(function(replica)
		local value = replica.Data[key]

		if value == nil then
			-- Warn, but don't error, as nil might be a valid value for some keys
			warn(`Key '{key}' is nil for player {player}`)
		end

		-- Return a copy to prevent accidental mutation of the Replica
		return value
	end)
end

-- Returns a Signal that fires when the specified key changes.
-- Also optionally fires immediately with the current value.
-- Usage: ProfileController:Observe("Coins", function(newCoins) ... end)
function ProfileController:Observe(key: string, callback: (any, any) -> (), player: Player?)
	player = player or Players.LocalPlayer

	-- We wrap this in a Promise to ensure the Replica exists before we listen
	self:_getReplica(player):andThen(function(replica)

		-- 1. Call immediately with current value
		if replica.Data[key] ~= nil then
			task.spawn(callback, replica.Data[key], nil)
		end

		-- 2. Listen for SetValue (Standard changes)
		replica:ListenToChange(key, function(new, old)
			callback(new, old)
		end)

		-- 3. Listen for ArrayInsert (TableInsert)
		replica:ListenToArrayInsert(key, function(index, value)
			-- Replica data is updated in-place, so replica.Data[key] is the *new* list
			callback(replica.Data[key], nil)
		end)

		-- 4. Listen for ArrayRemove (TableRemove)
		replica:ListenToArrayRemove(key, function(index, oldVal)
			callback(replica.Data[key], nil)
		end)
	end)
end

-------------------------- Internal Helper Functions --------------------------

-- Registers a newly created Replica
function ProfileController:_setupReplica(player: Player, replica)
	self._replicas[player] = replica

	-- Fire any pending listeners waiting for this player
	if self._replicaLoadedSignals[player] then
		self._replicaLoadedSignals[player]:Fire(replica)
		self._replicaLoadedSignals[player]:Destroy()
		self._replicaLoadedSignals[player] = nil
	end

	-- Cleanup when replica is destroyed (Player leaves or data release)
	replica:AddCleanupTask(function()
		self._replicas[player] = nil
	end)
end

-- Waits for a specific player's Replica to exist
function ProfileController:_getReplica(player: Player): "Promise"
	-- 1. If we already have it, resolve immediately
	if self._replicas[player] then
		return Promise.resolve(self._replicas[player])
	end

	return Promise.new(function(resolve, reject, onCancel)
		if not self._replicaLoadedSignals[player] then
			self._replicaLoadedSignals[player] = Signal.new()
		end

		local connection = self._replicaLoadedSignals[player]:Connect(function(replica)
			resolve(replica)
		end)

		task.delay(30, function()
			if connection.Connected then
				connection:Disconnect()
				reject(`Timeout: Profile data for {player} never loaded.`)
			end
		end)

		onCancel(function()
			connection:Disconnect()
		end)
	end)
end

return ProfileController