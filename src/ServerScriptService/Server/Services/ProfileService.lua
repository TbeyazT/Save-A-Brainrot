--[[
    ProfileService
    Manages Player Data using ProfileStore (Data persistence) and ReplicaService (Replication).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local HTTPService = game:GetService("HttpService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Dumpster = require(ReplicatedStorage.Packages.Dumpster)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

local ProfileStore = require(script.Parent.Parent.ProfileStore) 
local ReplicaService = require(ServerScriptService:FindFirstChild("ReplicaService"))

local STORE_NAME = "FullStarStudios"
local STORE_VERSION = 4

local DATA_TEMPLATE = {
	Cash = 200,
	LastLogin = 0,
	MaxHealth = 200,
	Settings = {
		["Game Musics"] = true
	},
	Gamepasses = {},
	Pets = {
		{
			Name = "67",
			ID = HTTPService:GenerateGUID(),
			Equipped = true,
			Level = 0,
		}
	},
	DiscoveredWorlds = {
		"Starting"
	},
	World = "Starting",
}

if RunService:IsStudio() then
	STORE_NAME = "STUDIO_DATA"
end

local FinalStoreName = `{STORE_NAME}_v{STORE_VERSION}`
local PlayerStore = ProfileStore.New(FinalStoreName, DATA_TEMPLATE)

if RunService:IsStudio() and ServerStorage:GetAttribute("MOCK_DATA_STORE") then
	PlayerStore = PlayerStore.Mock
	warn("⚠️ ProfileService: Using Mock DataStore")
end

local ProfileClassToken = ReplicaService.NewClassToken("PlayerProfile")

local ProfileService = Knit.CreateService {
	Name = "ProfileService",
	Client = {},

	PlayerLoaded = Signal.new(),
	PlayerRemoving = Signal.new(),

	_profiles = {},
	_replicas = {},
	_loadedPlayers = {},
}

function ProfileService:KnitStart()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function() self:_onPlayerAdded(player) end)
	end

	Players.PlayerAdded:Connect(function(player)
		self:_onPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_onPlayerRemoving(player)
	end)
end

function ProfileService:KnitInit()
end

function ProfileService:IsLoaded(player: Player): boolean
	local profile = self._profiles[player]
	return profile ~= nil and profile:IsActive()
end

function ProfileService:Get(player: Player, key: string): any
	local profile = self._profiles[player]
	if not profile then return nil end

	return profile.Data[key]
end

function ProfileService:GetProfile(player:Player): table
	local profile = self._profiles[player]
	if not profile then return nil end

	return profile
end

function ProfileService:GetAllData(player: Player): table?
	local profile = self._profiles[player]
	if not profile then return nil end
	return TableUtil.Copy(profile.Data)
end

function ProfileService:Set(player: Player, key: string, value: any)
	return Promise.new(function(resolve, reject)
		local replica = self._replicas[player]
		if not replica then 
			return reject("Player data not loaded") 
		end

		replica:SetValue(key, value)
		resolve(value)
	end)
end

function ProfileService:Increment(player: Player, key: string, amount: number)
	return Promise.new(function(resolve, reject)
		local replica = self._replicas[player]
		if not replica then return reject("Player data not loaded") end

		local currentVal = replica.Data[key] or 0
		if type(currentVal) ~= "number" then
			return reject(`Key '{key}' is not a number`)
		end

		local newVal = currentVal + amount
		replica:SetValue(key, newVal)
		resolve(newVal)
	end)
end

function ProfileService:Update(player: Player, key: string, callback: (any) -> any)
	return Promise.new(function(resolve, reject)
		local replica = self._replicas[player]
		if not replica then return reject("Player data not loaded") end

		local currentVal = replica.Data[key]
		local newVal = callback(currentVal)

		replica:SetValue(key, newVal)
		resolve(newVal)
	end)
end

function ProfileService:TableInsert(player: Player, key: string, valueToInsert: any)
	return Promise.new(function(resolve, reject)
		local replica = self._replicas[player]
		if not replica then return reject("Player data not loaded") end

		replica:ArrayInsert(key, valueToInsert)
		resolve()
	end)
end

function ProfileService:TableRemove(player: Player, key: string, index: number)
	return Promise.new(function(resolve, reject)
		local replica = self._replicas[player]
		if not replica then return reject("Player data not loaded") end

		replica:ArrayRemove(key, index)
		resolve()
	end)
end

function ProfileService:ChangeSetting(Player,key)
	local profile = self._profiles[Player]
	if not profile then return end
	local Settings = profile.Data.Settings
	if typeof(Settings[key]) ~= "nil" then
		Settings[key] = not Settings[key]
		return Settings[key]
	end
end

function ProfileService:Save(player: Player)
	local profile = self._profiles[player]
	if profile then
		profile:Save()
	end
end

function ProfileService.Client:GetData(player: Player, key: string)
	return self.Server:Get(player, key)
end

function ProfileService.Client:IsLoaded(player: Player)
	return self.Server:IsLoaded(player)
end

function ProfileService.Client:ChangeSetting(...)
	return self.Server:ChangeSetting(...)
end

-------------------------- Internal Implementation --------------------------

function ProfileService:_onPlayerAdded(player: Player)
	local profile = PlayerStore:StartSessionAsync(`Player_{player.UserId}`, {
		Cancel = function()
			return not player:IsDescendantOf(Players)
		end,
	})

	if not profile then
		-- Profile failed to load (likely locked by another server)
		player:Kick("Profile load failed. Please rejoin.")
		return
	end

	-- 1. Setup Profile
	profile:AddUserId(player.UserId)
	profile:Reconcile() -- Fill missing template values

	-- 2. Handle Session End (Force release)
	profile.OnSessionEnd:Connect(function()
		self:_cleanupPlayer(player)
		player:Kick("Profile session ended. Please rejoin.")
	end)

	if not player:IsDescendantOf(Players) then
		profile:EndSession()
		return
	end

	-- 3. Setup Replication
	self._profiles[player] = profile
	self:_setupReplica(player, profile)

	table.insert(self._loadedPlayers, player)

	player:SetAttribute("DATA_LOADED", true)

	-- 4. Fire Loaded Event
	self.PlayerLoaded:Fire(player, profile)
end

function ProfileService:ObservePlayerAdded(observer)
	for _, player in ipairs(self._loadedPlayers) do
		local profile = self._profiles[player]
		if profile then
			task.spawn(observer, player, profile)
		end
	end

	return self.PlayerLoaded:Connect(observer)
end

function ProfileService:_onPlayerRemoving(player: Player)
	
	local profile = self._profiles[player]
	if profile then
		profile:EndSession()
	end
end

function ProfileService:_setupReplica(player: Player, profile)
	local replica = ReplicaService.NewReplica({
		ClassToken = ProfileClassToken,
		Tags = { Player = player },
		Replication = "All",
		Data = profile.Data,
	})

	self._replicas[player] = replica

	local dumpster = Dumpster.new()

	dumpster:Add(function()
		if self._replicas[player] then
			self._replicas[player]:Destroy()
			self._replicas[player] = nil
		end
	end)

	dumpster:AttachTo(player)
end

function ProfileService:_cleanupPlayer(player: Player)
	self._profiles[player] = nil
	self._replicas[player] = nil

	local index = table.find(self._loadedPlayers, player)
	if index then
		table.remove(self._loadedPlayers, index)
	end

	self.PlayerRemoving:Fire(player)
end

return ProfileService