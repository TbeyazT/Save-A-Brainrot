local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local InputController = Knit.CreateController {
	Name = script.Name
}

function InputController:GetMousePosition2D()
	local mousePos = UserInputService:GetMouseLocation()
	local viewportSize = workspace.CurrentCamera.ViewportSize
	local x = mousePos.X / viewportSize.X
	local y = mousePos.Y / viewportSize.Y
	return Vector2.new(x, y)
end

function InputController:GetMouseWorldRay(BlackList)
	local screenMousePos = UserInputService:GetMouseLocation()
	local unitRay = Camera:ViewportPointToRay(screenMousePos.X, screenMousePos.Y)

	local filterTable = {}

	if LocalPlayer.Character then
		table.insert(filterTable, LocalPlayer.Character)
	end

	if BlackList then
		if typeof(BlackList) == "table" then
			for _, item in ipairs(BlackList) do
				table.insert(filterTable, item)
			end
		else
			table.insert(filterTable, BlackList)
		end
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = filterTable
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)

	return result
end

function InputController:IsMobile()
	return UserInputService.TouchEnabled 
end

function InputController:IsPC()
	return not UserInputService.TouchEnabled
end

function InputController:HasKeyboard()
	return UserInputService.KeyboardEnabled
end

function InputController:InitHoverDetection()
	self.OnHover = Signal.new()
	self.HoveredInstance = nil

	RunService.RenderStepped:Connect(function()
		local result = self:GetMouseWorldRay({})
		local hit = result and result.Instance or nil

		if hit ~= self.HoveredInstance then
			self.HoveredInstance = hit
			self.OnHover:Fire(hit)
		end
	end)
end

function InputController:InitKeybinds()
	UserInputService.InputBegan:Connect(function(input, gpe)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.OnClick:Fire("Mouse", input, gpe)
		end

		if input.UserInputType == Enum.UserInputType.Keyboard then
			self.InputBegan:Fire(input.KeyCode, gpe)
		end

		if input.UserInputType == Enum.UserInputType.Gamepad1 then
			self.InputBegan:Fire(input.KeyCode, gpe)
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gpe)
		if gpe then return end

		if input.UserInputType == Enum.UserInputType.Keyboard then
			self.InputEnded:Fire(input.KeyCode, gpe)
		end

		if input.UserInputType == Enum.UserInputType.Gamepad1 then
			self.InputEnded:Fire(input.KeyCode, gpe)
		end
	end)

	UserInputService.TouchTap:Connect(function(touchPositions, gpe)
		if tick() - self.LastMobileClick > self.MobileClickDebounce then
			self.LastMobileClick = tick()
			self.OnClick:Fire("Touch", touchPositions, gpe)
		end
	end)

	UserInputService.TouchEnded:Connect(function(touch, gpe)
		if not gpe then
			-- warn("Touch ended", gpe)
		end
	end)

	UserInputService.InputChanged:Connect(function(input, gpe)
		if gpe then return end

		if input.UserInputType == Enum.UserInputType.Gamepad1 then
			if input.KeyCode == Enum.KeyCode.Thumbstick1 or input.KeyCode == Enum.KeyCode.Thumbstick2 then
				self.OnThumbstick:Fire(input.KeyCode, input.Position)
			end
		end

		if input.UserInputType == Enum.UserInputType.Touch then
			self.OnTouchMoved:Fire(input.Position)
		end
	end)
end

function InputController:KnitInit()
	self.OnClick = Signal.new()
	self.InputBegan = Signal.new()
	self.InputEnded = Signal.new()
	self.OnThumbstick = Signal.new()
	self.OnTouchMoved = Signal.new()

	self.LastMobileClick = tick()
	self.MobileClickDebounce = 0.1

	self:InitHoverDetection()
	self:InitKeybinds()
end

return InputController