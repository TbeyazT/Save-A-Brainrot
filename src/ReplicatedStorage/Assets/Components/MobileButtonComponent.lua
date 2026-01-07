--[[
	// FileName: MobileButtonComponent.lua
	// Written by: TbeyazT
	// Description: Code for mobile touch controls with debug warnings.
	@TbeyazT 2025
--]]

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local Knit = require(Packages.Knit)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5)

if not PlayerGui then
	print("[MobileButtonComponent] ❌ PlayerGui not found — buttons will not appear.")
end

--== UI Stuff ==--
local ScreenGui: ScreenGui = PlayerGui:WaitForChild("MainGui",10) or Instance.new("ScreenGui")
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Name = "MainGui"
if not PlayerGui:FindFirstChild("MainGui") then
	ScreenGui.Parent = PlayerGui
	warn("[MobileButtonComponent] ℹ️ Created new MainGui (was missing).")
end

local ParentFrame: Frame = ScreenGui:WaitForChild("MobileButtons",10) or Instance.new("Frame")
ParentFrame.Size = UDim2.fromScale(1, 1)
ParentFrame.BackgroundTransparency = 1
ParentFrame.Name = "MobileButtons"
if not ScreenGui:FindFirstChild("MobileButtons") then
	ParentFrame.Parent = ScreenGui
	warn("[MobileButtonComponent] ℹ️ Created new MobileButtons frame (was missing).")
end

local Template = script:FindFirstChildWhichIsA("Frame")
if not Template then
	warn("[MobileButtonComponent] ⚠️ No Frame found inside script! Buttons cannot be created.")
end
--== UI Stuff ==--

local MobileButtonComponent = {}
MobileButtonComponent.__index = MobileButtonComponent

-- registry for all created buttons
local ButtonRegistry: { [string]: MobileButton } = {}

export type MobileButton = {
	ActionName: string,
	Callback: () -> (),
	Position: UDim2?,
	Size: UDim2?,
	Text: string?,
	Button: Frame,
	Destroy: (MobileButton) -> (),
}

-- constructor
function MobileButtonComponent.CreateActionButton(
	actionName: string,
	callback: () -> (),
	position: UDim2?,
	size: UDim2?,
	text: string?
): MobileButton
	if not Template then
		warn(`[MobileButtonComponent] ❌ Cannot create button "{actionName}" — template missing.`)
		return
	end

	local self: MobileButton = setmetatable({}, MobileButtonComponent)
	self.Button = Template:Clone()
	self.Button.Visible = true
	self.Button.ZIndex = 50
	self.ActionName = actionName
	self.Callback = callback
	self.Position = position or Template.Position
	self.Size = size or Template.Size
	self.Text = text

	self:BindButton()

	ButtonRegistry[self.ActionName] = self
	print(`[MobileButtonComponent] ✅ Created button "{self.ActionName}" successfully.`)

	return self
end

function MobileButtonComponent:BindButton()
	if not self.Button or not ParentFrame then
		warn(`[MobileButtonComponent] ⚠️ Failed to bind button "{self.ActionName}" — missing frame or parent.`)
		return
	end

	self.Button.Parent = ParentFrame
	self.Button.Name = self.ActionName

	local textLabel = self.Button:FindFirstChild("TextLabel")
	local buttonPart = self.Button:FindFirstChild("Button")

	if not textLabel then
		warn(`[MobileButtonComponent] ⚠️ "{self.ActionName}" is missing a TextLabel child.`)
	end

	if not buttonPart then
		warn(`[MobileButtonComponent] ⚠️ "{self.ActionName}" is missing a Button (TextButton/ImageButton).`)
	end

	if self.Text and textLabel then
		textLabel.Text = self.Text
	end

	self.Button.Size = self.Size
	self.Button.Position = self.Position

	if buttonPart then
		buttonPart.MouseButton1Down:Connect(function()
			if self.Callback then
				self.Callback()
			else
				warn(`[MobileButtonComponent] ⚠️ "{self.ActionName}" pressed but no callback assigned.`)
			end
		end)
	end
end

function MobileButtonComponent:SetText(text: string)
	if text then
		self.Text = text
		local label = self.Button:FindFirstChild("TextLabel")
		if label then
			label.Text = self.Text
		else
			warn(`[MobileButtonComponent] ⚠️ Tried to set text on "{self.ActionName}" but no TextLabel found.`)
		end
	end
end

function MobileButtonComponent:Destroy()
	ButtonRegistry[self.ActionName] = nil
	if self.Button then
		self.Button:Destroy()
		print(`[MobileButtonComponent] 🗑️ Destroyed button "{self.ActionName}".`)
	else
		warn(`[MobileButtonComponent] ⚠️ Tried to destroy "{self.ActionName}" but button is nil.`)
	end
end

--== Global Utility Functions ==--

function MobileButtonComponent.GetActionButton(actionName: string): MobileButton?
	return ButtonRegistry[actionName]
end

function MobileButtonComponent.DestroyActionButton(actionName: string)
	local button = ButtonRegistry[actionName]
	if button then
		button:Destroy()
	else
		warn(`[MobileButtonComponent] ⚠️ Tried to destroy non-existent button "{actionName}".`)
	end
end

function MobileButtonComponent.DestroyAllActionButtons()
	for _, button in pairs(ButtonRegistry) do
		button:Destroy()
	end
	ButtonRegistry = {}
	warn("[MobileButtonComponent] 🧹 All mobile buttons destroyed.")
end

function MobileButtonComponent.GetAllButtons(): { [string]: MobileButton }
	return ButtonRegistry
end

return MobileButtonComponent