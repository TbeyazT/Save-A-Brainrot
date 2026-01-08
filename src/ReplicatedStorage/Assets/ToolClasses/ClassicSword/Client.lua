local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local Trove = require(Packages.Trove) 
local Knit = require(Packages.Knit)
local ShapeCast = require(Assets.Modules.ShapecastHitbox)

local Client = {}
Client.__index = Client

function Client.new(Player: Player, Tool: Model, Character: Model)
	local self = setmetatable({}, Client)

	self.Trove = Trove.new()

	self.Player = Player
	self.Character = Character or Player.Character or Player.CharacterAdded:Wait()
	self.Humanoid = self.Character:WaitForChild("Humanoid")
	self.Animator = self.Humanoid:WaitForChild("Animator")

	self.InputController = Knit.GetController("InputController")
	
	self.InventoryService = Knit.GetService("InventoryService")

	self.Tool = Tool
	self.ToolProperties = require(Assets.ToolProperties:FindFirstChild(Tool.Name))

	self.AnimationTracks = {} 
	self.IsAttacking = false
	self.HitList = {}

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {self.Character}

	self.Hitbox = ShapeCast.new(Tool, rayParams)
	
	self.Trove:Add(self.Hitbox, "Destroy") 

	return self
end

function Client:LoadAnimation(name)
	if self.AnimationTracks[name] then
		return self.AnimationTracks[name]
	end

	local animId = self.ToolProperties.Animations[name]
	if self.Animator and animId then
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. tostring(animId)
		
		local track = self.Animator:LoadAnimation(anim)
		track.Priority = name == "Attack" and Enum.AnimationPriority.Action4 or Enum.AnimationPriority.Movement
		
		anim:Destroy()
		
		self.AnimationTracks[name] = track
		return track
	end
	return nil
end

function Client:Init()
	if not self.Trove then return end

	self.Trove:Add(self.Hitbox:OnHit(function(raycastResult: RaycastResult)
		if not raycastResult or not self.IsAttacking then return end
		
		local hitInstance = raycastResult.Instance
		local hitModel = hitInstance:FindFirstAncestorOfClass("Model")
		local hitHumanoid = hitModel and hitModel:FindFirstChild("Humanoid")

		if hitHumanoid and hitHumanoid ~= self.Humanoid then
			if not self.HitList[hitHumanoid] then
				self.HitList[hitHumanoid] = true
				
				self.InventoryService.RegisterHit:Fire({
					Humanoid = hitHumanoid,
					Position = raycastResult.Position,
				})
			end
		end
	end))

	local EquipAnimation = self:LoadAnimation("Equip")
	local IdleAnimation = self:LoadAnimation("Idle")

	if EquipAnimation then
		EquipAnimation:Play()
		task.wait(EquipAnimation.Length)
		if not self.Trove then return end
	end

	if IdleAnimation then
		IdleAnimation:Play()
	end

	self.Trove:Connect(self.InputController.OnClick, function(source, input, gpe)
		if not gpe and not self.IsAttacking then
			self:Swing()
		end
	end)
end

function Client:Swing()
	if self.IsAttacking then return end
	self.IsAttacking = true
	table.clear(self.HitList)

	local AttackAnim = self:LoadAnimation("Attack")
	if AttackAnim then
		AttackAnim:Play()
		self.Hitbox:HitStart()
	end

	self.Trove:Add(task.delay(self.ToolProperties.Cooldown, function()
		if self.Hitbox then
			self.Hitbox:HitStop()
		end
		self.IsAttacking = false
	end))
end

function Client:Destroy()
	for _, track in pairs(self.AnimationTracks) do
		if track.IsPlaying then
			track:Stop()
		end
		track:Destroy()
	end
	table.clear(self.AnimationTracks)

	if self.Trove then
		self.Trove:Destroy()
		self.Trove = nil
	end

	self.HitList = nil
	self.Tool = nil
	self.Hitbox = nil
	self.IsAttacking = false
	
	setmetatable(self, nil)
end

return Client