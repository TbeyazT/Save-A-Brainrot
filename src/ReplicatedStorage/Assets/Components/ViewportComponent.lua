--!nonstrict
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Knit = require(Packages.Knit)

local ViewportComponent = {}
ViewportComponent.__index = ViewportComponent

local function GetModelCFrame(model: Model, options:{})
	local primary = model.PrimaryPart
	if not primary then return CFrame.new() end
	
	local halfBody = CFrame.new(0, -0.8, -3)*CFrame.Angles(0,math.rad(180),0)
	local fullBody = CFrame.new(0, 0.5, -4)*CFrame.Angles(0,math.rad(180),0)
	
	local targetCFrame
	
	if options then
		targetCFrame = options.fullBody and fullBody or halfBody
	else
		targetCFrame = halfBody
	end

	return targetCFrame
end

function ViewportComponent.new(viewportFrame: ViewportFrame, TowerName)
	local self = setmetatable({}, ViewportComponent)

	self.PlayerController = Knit.GetController("PlayerController")
	self.InputController = Knit.GetController("InputController")

	self.ViewportFrame = viewportFrame
	self.WorldModel = viewportFrame:FindFirstChildOfClass("WorldModel") or Instance.new("WorldModel")
	self.WorldModel.Parent = viewportFrame
	self.TowerName = TowerName

	self.Camera = Instance.new("Camera")
	self.Camera.FieldOfView = 70
	self.Camera.Parent = viewportFrame
	self.Camera.CFrame = CFrame.new(0,0,0)
	self.Camera.Focus = CFrame.new(0,0,0)
	self.ViewportFrame.CurrentCamera = self.Camera

	self.Model = nil
	self.RotationY = 0
	self.IsDragging = false
	self.LastMouseX = 0
	self.Connections = {}

	return self
end

function ViewportComponent:SetParent(newParent: ViewportFrame?)
	if not newParent then
		self.ViewportFrame = nil
		self.WorldModel.Parent = nil
		self.Camera.Parent = nil
		return
	end

	self.ViewportFrame = newParent
	self.WorldModel.Parent = newParent
	self.Camera.Parent = newParent

	if newParent:IsA("ViewportFrame") then
		newParent.CurrentCamera = self.Camera
	end
end

function ViewportComponent:Clear()
	if self.WorldModel then
		self.WorldModel:ClearAllChildren()
	end
	self.Model = nil
end

function GetHumanoid(instance: Instance)
	if not instance then return nil end

	local current = instance
	while current and current ~= workspace do
		if current:IsA("Model") then
			local humanoid = current:FindFirstChildWhichIsA("Humanoid")
			if humanoid then
				return humanoid
			end
		end
		current = current.Parent
	end

	return nil
end

function ViewportComponent:SetModel(model: Model, options: {[string]: any}?)
	self:Clear()

	local clone = model:Clone()
	local humanoid = GetHumanoid(clone)
	clone.Parent = workspace
	if humanoid then
		humanoid:BuildRigFromAttachments()
	end
	clone.Parent = self.WorldModel
	self.Model = clone
	self.RotationEnabled = false
	clone:PivotTo(GetModelCFrame(clone, options))

	return clone
end

function ViewportComponent:PlayAnimation(ID)
	if not self.Model then return end
	local humanoid = self.Model:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end
	local Animation = self.PlayerController:LoadAnimation(ID, animator)
	if Animation then
		Animation:Play()
	else
		print("no anim")
	end
end

function ViewportComponent:EnableRotation()
	if self.RotationEnabled then return end
	self.RotationEnabled = true

	-- Disconnect old connections
	for _, conn in ipairs(self.Connections) do
		if typeof(conn) == "RBXScriptConnection" then
			conn:Disconnect()
		end
	end
	self.Connections = {}

	if not self.Model or not self.Model.PrimaryPart then return end

	local function isInsideFrame(pos: Vector2)
		local absPos = self.ViewportFrame.AbsolutePosition
		local absSize = self.ViewportFrame.AbsoluteSize
		return pos.X >= absPos.X and pos.X <= absPos.X + absSize.X
			and pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y
	end

	-- Mouse/touch press inside frame
	table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		local pos = (input.Position and input.Position) or UserInputService:GetMouseLocation()
		if isInsideFrame(pos) and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			self.IsDragging = true
			self.LastMouseX = pos.X
		end
	end))

	-- Mouse/touch move
	table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input, gp)
		if not self.IsDragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local pos = input.Position or UserInputService:GetMouseLocation()
			if isInsideFrame(pos) then
				local deltaX = pos.X - self.LastMouseX
				self.LastMouseX = pos.X
				self.RotationY += deltaX * 0.4

				if self.Model and self.Model.PrimaryPart then
					self.Model:SetPrimaryPartCFrame(
						CFrame.new(self.Model.PrimaryPart.Position) * CFrame.Angles(0, math.rad(self.RotationY), 0)
					)
				end
			end
		end
	end))

	-- Mouse/touch release
	table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self.IsDragging = false
		end
	end))
end

function ViewportComponent:Destroy()
	for _, conn in ipairs(self.Connections) do
		if typeof(conn) == "RBXScriptConnection" then
			conn:Disconnect()
		end
	end
	self.Connections = {}
	self:Clear()
	self.Camera:Destroy()
	self.WorldModel:Destroy()
	setmetatable(self, nil)
end

return ViewportComponent