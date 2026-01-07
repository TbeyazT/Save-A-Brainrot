--[[
	// FileName: VipTagModule.lua
	// Description: Creates a rainbow-animated rich text nametag for VIP users with smooth ripple motion.
	@TbeyazT 2025
--]]

local RunService 			= game:GetService("RunService")
local ReplicatedStorage 	= game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Assets   = ReplicatedStorage:WaitForChild("Assets")

local RichTextComponent = require(Assets.Components.LabelComponent)

local module = {}
module.__index = module

--// Simple rainbow color function
local function rainbowColor(t: number)
	return Color3.fromHSV((t % 5) / 5, 1, 1)
end

function module.new()
	local self = setmetatable({}, module)
	return self
end

function module:Init()
	local Tag = script:FindFirstChildOfClass("BillboardGui")
	if not Tag then
		warn("[VipTagModule] BillboardGui not found in script!")
		return
	end

	self.NameTag = Tag:Clone()
	self.NameTag.Enabled = true
end

function module:Set()
	local textLabel = self.NameTag.NameTag.TextLabel

	self.RichText = RichTextComponent.new(textLabel)
	self.RichText:SetText(textLabel.Text)
	--textLabel.Visible = false

	local hueOffset = math.random()
	local time = 0

	self._conn = RunService.RenderStepped:Connect(function(dt)
		hueOffset += dt * 0.4
		time += dt * 6 -- controls wave speed

		local letters = self.RichText:GetLetters()
		local total = #letters

		for i, letter in ipairs(letters) do
			local h = hueOffset + (i / total)
			local color = rainbowColor(h)

			-- Ripple motion (wave)
			local wave = math.sin(time + i * 0.35) * 1.5 -- gentle ripple (1.5px amplitude)
			local pulse = 0.9 + math.sin(time * 1.5 + i * 0.4) * 0.1 -- subtle brightness pulse

			letter.Label.TextColor3 = Color3.new(
				color.R * pulse,
				color.G * pulse,
				color.B * pulse
			)

			-- Slight vertical wave offset
			local originalPos = letter.BasePosition or letter.Label.Position
			if not letter.BasePosition then
				letter.BasePosition = originalPos
			end

			letter.Label.Position = UDim2.new(
				originalPos.X.Scale,
				originalPos.X.Offset,
				originalPos.Y.Scale,
				originalPos.Y.Offset + wave
			)
		end
	end)
end

function module:Destroy()
	if self._conn then
		self._conn:Disconnect()
		self._conn = nil
	end
	if self.RichText then
		self.RichText:Destroy()
	end
	if self.NameTag then
		self.NameTag:Destroy()
	end
end

return module