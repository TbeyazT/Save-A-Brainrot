local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:FindFirstChild("Packages")
local Assets = ReplicatedStorage:FindFirstChild("Assets")

local Knit = require(Packages.Knit)
local Trove = require(Packages.Trove)
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
	
	self.ToolProperties = require(Assets.ToolProperties:FindFirstChild(Tool.Name))

	self.MaxDistance = 12 
	self.Damage = self.ToolProperties.Damage or 10 
	
	if self.IsNPC then
		self:_setupNPC()
	end

	return self
end

function Server:_setupNPC()
	self.HitList = {}
	self.IsAttacking = false
	self.AnimationTracks = {}
	
	local humanoid = self.Character:FindFirstChild("Humanoid")
	self.Animator = humanoid:FindFirstChild("Animator")
	if not self.Animator then
		self.Animator = Instance.new("Animator")
		self.Animator.Parent = humanoid
	end
	
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {self.Character} 

	self.Hitbox = ShapeCast.new(self.Tool, rayParams)
	self.Trove:Add(self.Hitbox, "Destroy")
	
	self.Trove:Add(self.Hitbox:OnHit(function(raycastResult)
		if not self.IsAttacking then return end
		local hitInstance = raycastResult.Instance
		local hitModel = hitInstance:FindFirstAncestorOfClass("Model")
		local hitHumanoid = hitModel and hitModel:FindFirstChild("Humanoid")
		if hitHumanoid and hitHumanoid.Parent ~= self.Character then
			if not self.HitList[hitHumanoid] then
				self.HitList[hitHumanoid] = true
				self:_applyDamage(hitHumanoid)
			end
		end
	end))

	task.spawn(function()
		local equipAnim = self:_loadAnimation("Equip")
		local idleAnim = self:_loadAnimation("Idle")

		if equipAnim then
			equipAnim:Play()
			task.wait(equipAnim.Length)
		end
		
		if idleAnim and self.Tool and self.Tool.Parent then
			idleAnim:Play()
		end
	end)
end

function Server:_loadAnimation(name)
	if self.AnimationTracks[name] then return self.AnimationTracks[name] end
	
	local animId = self.ToolProperties.Animations[name]
	if self.Animator and animId then
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. tostring(animId)
		local track = self.Animator:LoadAnimation(anim)
		
		if name == "Attack" then
			track.Priority = Enum.AnimationPriority.Action4
		elseif name == "Equip" then
			track.Priority = Enum.AnimationPriority.Action
		else
			track.Priority = Enum.AnimationPriority.Movement
		end
		
		anim:Destroy()
		self.AnimationTracks[name] = track
		return track
	end
end

function Server:Attack()
	if not self.IsNPC or self.IsAttacking then return end
	
	self.IsAttacking = true
	table.clear(self.HitList)
	
	local attackAnim = self:_loadAnimation("Attack")
	if attackAnim then
		attackAnim:Play()
	end
	
	if self.Hitbox then
		self.Hitbox:HitStart()
	end
	
	self.Trove:Add(task.delay(self.ToolProperties.Cooldown, function()
		if self.Hitbox then self.Hitbox:HitStop() end
		self.IsAttacking = false
	end))
end

function Server:ProcessHit(Data)
	if self.IsNPC then return end 
	local hitHumanoid = Data.Humanoid
	if not self.Tool or not self.Tool.Parent or self.Tool.Parent ~= self.Character then
		warn(self.Player.Name .. " tried to hit without the tool equipped!")
		return
	end

	local attackerRoot = self.Character:FindFirstChild("HumanoidRootPart")
	local victimRoot = hitHumanoid.Parent:FindFirstChild("HumanoidRootPart")
	
	if not attackerRoot or not victimRoot then return end
	
	local distance = (attackerRoot.Position - victimRoot.Position).Magnitude
	if distance > self.MaxDistance then
		warn(self.Player.Name .. " hit rejected (Too far)")
		return
	end

	self:_applyDamage(hitHumanoid)
end

function Server:_applyDamage(targetHumanoid)
	warn("Applying damage to target humanoid")
	local attackerData = self.CharacterService:GetCharacter(self.Character)
	local victimData = self.CharacterService:GetCharacter(targetHumanoid.Parent)
	warn(attackerData, victimData)
	if not attackerData or not victimData then return end
	warn("Attacker and victim data found")
	if attackerData.Model == victimData.Model then return end
	warn("Attacker and victim are different")
	if victimData.Humanoid.Health <= 0 then return end
	warn("Victim is alive, proceeding with damage application")

	local directionVector = (victimData.RootPart.Position - attackerData.RootPart.Position)
	local flatDirection = Vector3.new(directionVector.X, 0, directionVector.Z) 

	if flatDirection.Magnitude < 0.1 then
		flatDirection = -attackerData.RootPart.CFrame.LookVector
	end

	local finalDirection = flatDirection.Unit
	warn("Pushing victim back with direction:", finalDirection)
	self.CharacterService:PushCharacter(victimData.RootPart, finalDirection, 10,0.5)
	warn("Dealing", self.Damage, "damage to target humanoid")
	targetHumanoid:TakeDamage(self.Damage)

	local attackerName = self.IsNPC and "NPC" or self.Player.Name
	local victimName = victimData.IsPlayer and victimData.Player.Name or "NPC"
	print(attackerName .. " dealt " .. self.Damage .. " damage to " .. victimName)
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