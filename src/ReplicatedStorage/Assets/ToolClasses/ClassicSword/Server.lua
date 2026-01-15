local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:FindFirstChild("Packages")
local Assets = ReplicatedStorage:FindFirstChild("Assets")

local Knit = require(Packages.Knit)
local Trove = require(Packages.Trove)
local TableUtil = require(Packages.TableUtil)
local ShapeCast = require(Assets.Modules.ShapecastHitbox) 

local Server = {}
Server.__index = Server

function Server.new(Player: Player?, Tool: Model, Character: Model)
	local self = setmetatable({}, Server)
	
	self.Trove = Trove.new()

	self.Player = Player
	self.Character = Character
	self.Tool = Tool
	
	self.IsNPC = (Player == nil)

	self.CharacterService = Knit.GetService("CharacterService")
	self.EnemyService = Knit.GetService("EnemyService")
	self.StageService = Knit.GetService("StageService")
	
	self.ToolProperties = self.IsNPC and require(Assets.ToolProperties:FindFirstChild(Tool)) or 
		require(Assets.ToolProperties:FindFirstChild(Tool.Name))

	self.MaxDistance = 12 
	self.Damage = self.ToolProperties.Damage or 10 
	
	if self.IsNPC then
		--self:_setupNPC()
	end

	return self
end

function Server:Attack()
	if self.IsAttacking then return end
	
	self.IsAttacking = true

	self.Trove:Add(task.delay(self.ToolProperties.Cooldown, function()
		self.IsAttacking = false
	end))
end

function Server:ProcessHit(Data)
	if not self.IsNPC then
		if not self.Tool or not self.Tool.Parent or self.Tool.Parent ~= self.Character then
			warn(self.Player.Name .. " tried to hit without the tool equipped!")
			return
		end
	end

	if not self.IsNPC then
		self:_applyDamage(Data.ID)
	else
		local hitHumanoid = Data.Humanoid
		local victimRoot = hitHumanoid.Parent:FindFirstChild("HumanoidRootPart")
		if not victimRoot then return end
		self:_applyDamage(hitHumanoid)
	end
end

function Server:_applyDamage(targetHumanoid)
	local attackerData = self.IsNPC and self.CharacterService:GetCharacter(self.Character)
	local victimData = self.IsNPC and self.CharacterService:GetCharacter(targetHumanoid.Parent)

	if not self.IsNPC then
		local enemy = self.EnemyService:GetEnemy(targetHumanoid) -- target humanoid is an id cause the player attacks the npcs!!
		if enemy then
			enemy:TakeDamage(self.Damage)
		end
	else
		if victimData.Player then
			local playerState = TableUtil.Copy(self.StageService:GetPlayerState(victimData.Player))
			if playerState and playerState.Health <= 0 then return end
			warn("dealing")
			self.StageService:TakeDamage(victimData.Player,self.Damage)
		end
	end
end

function Server:Destroy()
	if self.Trove then
		self.Trove:Destroy()
	end
	
	if self.AnimationTracks then
		for _, track in pairs(self.AnimationTracks) do
			track:Stop()
		end
	end

	self.CharacterService = nil
	self.Player = nil
	self.Tool = nil
	setmetatable(self, nil)
end

return Server