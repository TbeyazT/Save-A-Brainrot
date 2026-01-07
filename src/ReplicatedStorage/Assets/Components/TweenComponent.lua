local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local Signal = require(Packages.Signal)

local TweenComponent = {}
TweenComponent.__index = TweenComponent

export type Tween = {
	Connection: RBXScriptConnection?,
	Playing: boolean,
	Elapsed: number,
	Duration: number,
	Easing: (number) -> number,
	Step: (number) -> (),
	Completed: BindableEvent,
	Play: (Tween) -> (),
	Stop: (Tween) -> (),
	Destroy: (Tween) -> (),
}

-- default easing (linear)
local function linear(t: number): number
	return t
end

function TweenComponent.new(duration: number, stepCallback: (alpha: number) -> (), easing: ((number) -> number)?): Tween
	local self: Tween = setmetatable({}, TweenComponent)

	self.Duration = duration
	self.Step = stepCallback
	self.Elapsed = 0
	self.Easing = easing or linear
	self.Playing = false
	self.Completed = Signal.new()

	return self
end

function TweenComponent:Play()
	if self.Playing then return end
	self.Playing = true
	self.Elapsed = 0

	self.Connection = RunService.RenderStepped:Connect(function(dt)
		self.Elapsed += dt
		local alpha = math.clamp(self.Elapsed / self.Duration, 0, 1)
		alpha = self.Easing(alpha)

		self.Step(alpha)

		if self.Elapsed >= self.Duration then
			self:Stop()
			self.Completed:Fire()
		end
	end)
end

function TweenComponent:Stop()
	if not self.Playing then return end
	self.Playing = false
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
end

function TweenComponent:Destroy()
	self:Stop()
	if self.Completed then
		self.Completed:Destroy()
	end
end

return TweenComponent