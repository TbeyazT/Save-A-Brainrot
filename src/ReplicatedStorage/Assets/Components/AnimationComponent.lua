local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Knit = require(Packages.Knit)

local AnimateComponent = {}

_G.ActiveFrame = nil

function AnimateComponent.new(UI,TI)
	local self = setmetatable({}, {
		__index = AnimateComponent
	})

	self.UI = UI
	self.Enabled = true
	self.CanAnimate = true
	self.SfxEnabled = true
	self.OriSize = self.UI.Size

	self.UpScale = 1.1
	self.DownScale = 0.8
	-- Callbacks (user can override these later)
	self.OnHover = nil
	self.OnUnHover = nil
	self.OnMouseDown = nil
	self.OnMouseUp = nil
	
	self.TI = TI and TI or TweenInfo.new(0.3, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)

	self.HoverTween = TweenService:Create(UI, self.TI, {
		Size = UDim2.fromScale(self.UI.Size.X.Scale * self.UpScale, self.UI.Size.Y.Scale * self.UpScale)
	})

	self.HoverLeaveTween = TweenService:Create(UI, self.TI, {
		Size = UDim2.fromScale(self.OriSize.X.Scale, self.OriSize.Y.Scale)
	})

	self.MouseDownTween = TweenService:Create(UI, self.TI, {
		Size = UDim2.fromScale(self.UI.Size.X.Scale * self.DownScale, self.UI.Size.Y.Scale * self.DownScale)
	})

	self.MouseUpTween = TweenService:Create(UI, self.TI, {
		Size = UDim2.fromScale(self.OriSize.X.Scale, self.OriSize.Y.Scale)
	})

	self.Connections = {}
	
	self.UI.Destroying:Connect(function()
		if self.destroy then
			self:destroy()
		end
	end)

	return self
end

function AnimateComponent:Enable()
	self.Enabled = true
end

function AnimateComponent:Disable()
	self.Enabled = false
end

function AnimateComponent:UpdateTweens()
	self.HoverTween = TweenService:Create(self.UI, self.TI, {
		Size = UDim2.fromScale(self.UI.Size.X.Scale * self.UpScale, self.UI.Size.Y.Scale * self.UpScale)
	})
	self.HoverLeaveTween = TweenService:Create(self.UI, self.TI, {
		Size = UDim2.fromScale(self.OriSize.X.Scale, self.OriSize.Y.Scale)
	})
	self.MouseDownTween = TweenService:Create(self.UI, self.TI, {
		Size = UDim2.fromScale(self.UI.Size.X.Scale * self.DownScale, self.UI.Size.Y.Scale * self.DownScale)
	})
	self.MouseUpTween = TweenService:Create(self.UI, self.TI, {
		Size = UDim2.fromScale(self.OriSize.X.Scale, self.OriSize.Y.Scale)
	})
end

function AnimateComponent:Hover()
	if self.CanAnimate then
		self.HoverTween:Play()
	end
	local hoverSound = Assets.Sounds.UI:FindFirstChild("Hover")
	if hoverSound then
		if self.SfxEnabled then
			hoverSound:Play()
		end
	end
	-- Custom callback
	if self.OnHover then
		self.OnHover(self.UI)
	end
end

function AnimateComponent:UnHover()
	if self.CanAnimate then
		self.HoverLeaveTween:Play()
	end
	-- Custom callback
	if self.OnUnHover then
		self.OnUnHover(self.UI)
	end
end

function AnimateComponent:MouseDown()
	if self.CanAnimate then
		self.MouseDownTween:Play()
	end
	if self.OnMouseDown then
		self.OnMouseDown(self.UI)
	end
end

function AnimateComponent:MouseUp()
	if self.CanAnimate then
		self.MouseUpTween:Play()
	end
	local clickSound = Assets.Sounds.UI:FindFirstChild("Click")
	if clickSound and self.SfxEnabled then
		clickSound:Play()
	end
	if self.OnMouseUp then
		self.OnMouseUp(self.UI)
	end
end

function AnimateComponent:Init(KeyCode:Enum.KeyCode, func)
	for i, connection in ipairs(self.Connections) do
		connection:Disconnect()
		self.Connections[i] = nil
	end
	self.Connections = {}
	table.insert(self.Connections, self.UI.MouseEnter:Connect(function()
		if not self.Enabled then return end
		self:Hover()
	end))

	table.insert(self.Connections, self.UI.MouseLeave:Connect(function()
		if not self.Enabled then return end
		self:UnHover()
	end))

	if self.UI:IsA("GuiButton") then
		table.insert(self.Connections, self.UI.MouseButton1Down:Connect(function()
			if not self.Enabled then return end
			self:MouseDown()
		end))

		table.insert(self.Connections, self.UI.MouseButton1Up:Connect(function()
			if not self.Enabled then return end
			self:MouseUp()
			if func and type(func) == "function" then
				func()
			end
		end))
	end

	if KeyCode then
		table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
			if gpe or not self.Enabled then return end
			if input.KeyCode == KeyCode then
				self:MouseDown()
			end
		end))

		table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input, gpe)
			if gpe or not self.Enabled then return end
			if input.KeyCode == KeyCode then
				self:MouseUp()
				if func and type(func) == "function" then
					func()
				end
			end
		end))
	end
end

function AnimateComponent:destroy()
	for i, connection in ipairs(self.Connections) do
		connection:Disconnect()
		self.Connections[i] = nil
	end
	self.Connections = {}

	if self.HoverTween then
		self.HoverTween:Cancel()
		self.HoverTween:Destroy()
		self.HoverTween = nil
	end

	if self.HoverLeaveTween then
		self.HoverLeaveTween:Cancel()
		self.HoverLeaveTween:Destroy()
		self.HoverLeaveTween = nil
	end

	if self.MouseDownTween then
		self.MouseDownTween:Cancel()
		self.MouseDownTween:Destroy()
		self.MouseDownTween = nil
	end

	if self.MouseUpTween then
		self.MouseUpTween:Cancel()
		self.MouseUpTween:Destroy()
		self.MouseUpTween = nil
	end

	self.UI.Size = self.OriSize

	setmetatable(self,nil)
end

return AnimateComponent