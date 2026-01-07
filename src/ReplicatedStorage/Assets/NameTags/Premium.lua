--[[
	// FileName: PremiumTagModule.lua
	// Description: Creates a dark purple-animated rich text nametag for Premium users with smooth pulsing motion.
	@TbeyazT 2025
--]]

local RunService 			= game:GetService("RunService")
local ReplicatedStorage 	= game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Assets   = ReplicatedStorage:WaitForChild("Assets")

local RichTextComponent = require(Assets.Components.LabelComponent)

local module = {}
module.__index = module

--// Dark purple gradient function
local function purpleColor(t: number)
	-- Shifts between deep violet, royal purple, and magenta tones
	local hue = 0.76 + math.sin(t * 0.6) * 0.04  -- 0.72–0.80 range
	local saturation = 0.9 + math.sin(t * 0.8) * 0.05
	local value = 0.6 + math.sin(t * 0.5) * 0.1
	return Color3.fromHSV(hue % 1, saturation, value)
end

function module.new()
	local self = setmetatable({}, module)
	return self
end

function module:Init()
	local Tag = script:FindFirstChildOfClass("BillboardGui")
	if not Tag then
		warn("[PremiumTagModule] BillboardGui not found in script!")
		return
	end

	self.NameTag = Tag:Clone()
	self.NameTag.Enabled = true
end

function module:Set()
	local textLabel = self.NameTag.NameTag.TextLabel

	self.RichText = RichTextComponent.new(textLabel)
	self.RichText:SetText(textLabel.Text)

	local time = 0

	self._conn = RunService.RenderStepped:Connect(function(dt)
		time += dt * 5 -- overall animation speed

		local letters = self.RichText:GetLetters()
		local total = #letters

		for i, letter in ipairs(letters) do
			local color = purpleColor(time + i * 0.15)

			-- Gentle pulse (brightness shift)
			local pulse = 0.85 + math.sin(time * 1.2 + i * 0.4) * 0.15

			-- Slight shimmer motion (subtle)
			local shimmer = math.sin(time * 1.8 + i * 0.35) * 1.0

			letter.Label.TextColor3 = Color3.new(
				color.R * pulse,
				color.G * pulse,
				color.B * pulse
			)

			-- Smooth vertical shimmer offset
			local originalPos = letter.BasePosition or letter.Label.Position
			if not letter.BasePosition then
				letter.BasePosition = originalPos
			end

			letter.Label.Position = UDim2.new(
				originalPos.X.Scale,
				originalPos.X.Offset,
				originalPos.Y.Scale,
				originalPos.Y.Offset + shimmer
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