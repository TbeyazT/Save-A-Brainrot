--[[
	// FileName: VisibleComponent.lua
	// Written by: TbeyazT
	// Description: Handles tween-based visibility for UI components with signals.
	@TbeyazT 2025
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local Packages = ReplicatedStorage:WaitForChild("Packages")

local Signal = require(Packages.Signal)

--== Visible Component ==--
local VisibleComponent = {}
VisibleComponent.__index = VisibleComponent

export type VisibleComponentType = {
	UI: GuiObject,
	OriSize: UDim2,
	VisibleTween: Tween,
	VisibleFalseTween: Tween,
	OnVisible: RBXScriptSignal,
	OnInvisible: RBXScriptSignal,
	Visible: (VisibleComponentType, boolean) -> (),
	Destroy: (VisibleComponentType) -> (),
}

-- constructor
function VisibleComponent.new(UI: GuiObject, info: TweenInfo?): VisibleComponentType
	local self: VisibleComponentType = setmetatable({}, VisibleComponent)

	self.UI = UI
	self.OriSize = self.UI.Size

	local tweenInfo = info or TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	self.VisibleTween = TweenService:Create(UI, tweenInfo, {
		Size = self.OriSize,
	})

	self.VisibleFalseTween = TweenService:Create(UI, tweenInfo, {
		Size = UDim2.fromScale(0, 0),
	})

	-- signals
	local visibleEvent = Signal.new()
	local invisibleEvent = Signal.new()
	self.OnVisible = visibleEvent
	self.OnInvisible = invisibleEvent
	self._visibleEvent = visibleEvent
	self._invisibleEvent = invisibleEvent

	self.UI.Size = UDim2.fromScale(0, 0)
	self.UI.Visible = false
	
	self.UI.Destroying:Connect(function()
		if typeof(self.Destroy) == "function" then
			self:Destroy()
		end
	end)

	return self
end

--== Public Methods ==--

function VisibleComponent:Visible(value: boolean)
	if not self.UI then return end

	if value then
		self.UI.Visible = true
		self.VisibleTween:Play()
		self.VisibleTween.Completed:Wait()
		if self._visibleEvent then
			self._visibleEvent:Fire(self.UI)
		end
	else
		self.VisibleFalseTween:Play()
		self.VisibleFalseTween.Completed:Wait()
		self.UI.Visible = false
		if self._invisibleEvent then
			self._invisibleEvent:Fire(self.UI)
		end
	end
end

function VisibleComponent:Destroy()
	if self.VisibleTween then
		self.VisibleTween:Cancel()
		self.VisibleTween:Destroy()
		self.VisibleTween = nil
	end

	if self.VisibleFalseTween then
		self.VisibleFalseTween:Cancel()
		self.VisibleFalseTween:Destroy()
		self.VisibleFalseTween = nil
	end

	if self._visibleEvent then
		self._visibleEvent:Destroy()
		self._visibleEvent = nil
	end

	if self._invisibleEvent then
		self._invisibleEvent:Destroy()
		self._invisibleEvent = nil
	end

	setmetatable(self, nil)
end

return VisibleComponent