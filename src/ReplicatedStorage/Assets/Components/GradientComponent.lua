local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages",30)

local Signal = require(Packages.Signal)

local GradientLerpComponent = {}
GradientLerpComponent.__index = GradientLerpComponent

local SAMPLE_TIMES = {0, 0.25, 0.5, 0.75, 1}

local function LerpColor(c1, c2, t)
	return Color3.new(
		c1.R + (c2.R - c1.R) * t,
		c1.G + (c2.G - c1.G) * t,
		c1.B + (c2.B - c1.B) * t
	)
end

local function EvaluateColorSequence(sequence: ColorSequence, time: number): Color3
	local keypoints = sequence.Keypoints
	if time <= keypoints[1].Time then
		return keypoints[1].Value
	end
	if time >= keypoints[#keypoints].Time then
		return keypoints[#keypoints].Value
	end

	for i = 1, #keypoints - 1 do
		local k0 = keypoints[i]
		local k1 = keypoints[i + 1]
		if time >= k0.Time and time <= k1.Time then
			local alpha = (time - k0.Time) / (k1.Time - k0.Time)
			return LerpColor(k0.Value, k1.Value, alpha)
		end
	end

	return keypoints[#keypoints].Value
end

function GradientLerpComponent.new(uiGradient: UIGradient)
	local self = setmetatable({}, GradientLerpComponent)
	self.UIGradient = uiGradient
	self.Connection = nil
	
	self.Finished = Signal.new()
	
	self.UIGradient.Destroying:Connect(function()
		self:Destroy()
	end)
	return self
end

function GradientLerpComponent:Lerp(fromSeq: ColorSequence, toSeq: ColorSequence, duration: number)
	if self.Connection then
		self.Connection:Disconnect()
	end

	local startTime = tick()

	self.Connection = RunService.Heartbeat:Connect(function()
		local now = tick()
		local alpha = math.clamp((now - startTime) / duration, 0, 1)

		local newKeypoints = {}
		for _, t in ipairs(SAMPLE_TIMES) do
			local colorFrom = EvaluateColorSequence(fromSeq, t)
			local colorTo = EvaluateColorSequence(toSeq, t)
			local finalColor = LerpColor(colorFrom, colorTo, alpha)

			table.insert(newKeypoints, ColorSequenceKeypoint.new(t, finalColor))
		end

		self.UIGradient.Color = ColorSequence.new(newKeypoints)

		if alpha >= 1 then
			self.Connection:Disconnect()
			self.Connection = nil
			self.Finished:Fire()
		end
	end)
end

function GradientLerpComponent:CrossFade(oneSeq: ColorSequence, secSeq: ColorSequence, duration: number)
	if self.Connection then
		self.Connection:Disconnect()
	end

	local startTime = tick()

	self.Connection = RunService.Heartbeat:Connect(function()
		local now = tick()
		local alpha = math.clamp((now - startTime) / duration, 0, 1)

		local newKeypoints = {}
		for _, t in ipairs(SAMPLE_TIMES) do
			local blue = EvaluateColorSequence(oneSeq, t)
			local fadedBlue = LerpColor(blue, Color3.new(0,0,0), alpha)

			local red = EvaluateColorSequence(secSeq, t)
			local appearedRed = LerpColor(Color3.new(0,0,0), red, alpha)

			local finalColor = Color3.new(
				math.clamp(fadedBlue.R + appearedRed.R, 0, 1),
				math.clamp(fadedBlue.G + appearedRed.G, 0, 1),
				math.clamp(fadedBlue.B + appearedRed.B, 0, 1)
			)

			table.insert(newKeypoints, ColorSequenceKeypoint.new(t, finalColor))
		end

		self.UIGradient.Color = ColorSequence.new(newKeypoints)

		if alpha >= 1 then
			self.Connection:Disconnect()
			self.Connection = nil
		end
	end)
end

function GradientLerpComponent:Destroy()
	if self.Connection then
		self.Connection:Disconnect()
	end
	if self.Finished then
		self.Finished:Destroy()
	end
end

return GradientLerpComponent