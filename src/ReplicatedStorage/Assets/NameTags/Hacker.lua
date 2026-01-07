--[[
	// FileName: OwnerTagModule.lua
	// Description: Hacker-style "Owner" tag with aggressive green flicker, glitch, and wave distortion.
	@TbeyazT 2025
--]]

local RunService 			= game:GetService("RunService")
local ReplicatedStorage 	= game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Assets   = ReplicatedStorage:WaitForChild("Assets")

local RichTextComponent = require(Assets.Components.LabelComponent)

local module = {}
module.__index = module

--// Base hacker color
local function hackerColor(t: number)
	local baseHue = 0.33 -- green
	local pulse = math.sin(t * 4) * 0.05
	return Color3.fromHSV(baseHue + pulse, 1, 1)
end

function module.new()
	local self = setmetatable({}, module)
	return self
end

function module:Init()
	local Tag = script:FindFirstChildOfClass("BillboardGui")
	if not Tag then
		warn("[OwnerTagModule] BillboardGui not found in script!")
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

	local time = 0
	local glitchTimer = 0

	self._conn = RunService.RenderStepped:Connect(function(dt)
		time += dt * 6
		glitchTimer += dt

		local letters = self.RichText:GetLetters()
		local total = #letters

		for i, letter in ipairs(letters) do
			local lbl = letter.Label
			local phase = i * 0.15
			local col = hackerColor(time + phase)

			-- independent flicker speed for each letter
			local flicker = (math.noise(time * 3, i * 0.4) + 1) / 2
			local intensity = 0.7 + flicker * 0.3
			local isGlitch = math.random() < 0.02

			-- random transparency flicker
			if math.random() < 0.1 then
				lbl.TextTransparency = math.random() < 0.4 and 0.6 or 0
			end

			-- rotate and shift slightly for chaotic glitch motion
			if isGlitch then
				lbl.Rotation = math.random(-15, 15)
				lbl.Position = lbl.Position + UDim2.new(0, math.random(-2, 2), 0, math.random(-2, 2))
			else
				lbl.Rotation = math.sin(time * 2 + phase) * 3
			end

			lbl.TextColor3 = Color3.new(col.R * intensity, col.G * intensity, col.B * intensity)
		end

		-- massive screen-wide glitch burst occasionally
		if glitchTimer > 0.2 then
			glitchTimer = 0
			if math.random() < 0.25 then
				for _, letter in ipairs(letters) do
					if math.random() < 0.5 then
						letter.Label.TextTransparency = 0.8
					end
				end
				task.delay(0.05, function()
					for _, letter in ipairs(letters) do
						letter.Label.TextTransparency = 0
					end
				end)
			end
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