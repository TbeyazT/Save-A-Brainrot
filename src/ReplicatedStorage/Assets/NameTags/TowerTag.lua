local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local RichTextComponent = require(Assets.Components.LabelComponent)
local RarityColors = require(Assets.Modules.RarityColors)

local module = {}
module.__index = module

function module.new()
	local self = setmetatable({}, module)
	return self
end

function module:Init()
	local Tag = script:FindFirstChildOfClass("BillboardGui")
	if not Tag then
		warn("[RarityTagModule] BillboardGui not found in script!")
		return
	end

	self.NameTag = Tag:Clone()
	self.NameTag.Enabled = true
end

function module:Set(Rarity)
	local textLabel = self.NameTag.NameTag.TextLabel
	self.RichText = RichTextComponent.new(textLabel)
	self.RichText:SetText(textLabel.Text)

	local baseColor = RarityColors[Rarity] or Color3.new(1, 1, 1)
	local hue, sat, val = baseColor:ToHSV()
	local time = 0

	self._conn = RunService.RenderStepped:Connect(function(dt)
		time += dt * 4

		local letters = self.RichText:GetLetters()
		for i, letter in ipairs(letters) do
			local lbl = letter.Label
			local phase = i * 0.2

			-- color smoothly pulses around rarity hue
			local hueShift = math.sin(time + phase) * 0.01
			local brightnessPulse = math.sin(time * 2 + phase) * 0.15 + 0.85

			local color = Color3.fromHSV(
				(hue + hueShift) % 1,
				sat,
				val * brightnessPulse
			)

			lbl.TextColor3 = color

			-- small flicker in transparency
			if math.random() < 0.03 then
				lbl.TextTransparency = math.random() < 0.5 and 0.2 or 0
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