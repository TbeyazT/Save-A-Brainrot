local RunService = game:GetService("RunService")

local ParticleComp = {}
ParticleComp.__index = ParticleComp

local Frame = nil
do
	local player = game.Players.LocalPlayer
	local gui = player:WaitForChild("PlayerGui")
	local mainGui = gui:WaitForChild("MainGui")

	Frame = Instance.new("Frame")
	Frame.Size = UDim2.fromScale(1, 1)
	Frame.BackgroundTransparency = 1
	Frame.ZIndex = 100
	Frame.Parent = mainGui
end

-- Default settings
local DEFAULT_CONFIG = {
	Image = "rbxassetid://10723345580",
	Position = Vector2.new(200, 200),
	SpawnRadius = 0,
	Lifetime = 1,
	Size = NumberRange.new(10, 20),
	Transparency = NumberRange.new(0, 1),
	RotationSpeed = NumberRange.new(-90, 90),
	Color = Color3.new(1, 1, 1),

	-- Physics
	UsePhysics = false,
	Speed = NumberRange.new(50, 150),
	Gravity = Vector2.new(0, 0),
	Drag = 0,
	
	MaxFps = 60,
}

local pool = {}

local function getFromPool()
	if #pool > 0 then
		local inst = table.remove(pool)
		inst.Visible = true
		return inst
	end
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Parent = Frame
	return img
end

local function returnToPool(inst)
	inst.Visible = false
	inst.Parent = Frame
	table.insert(pool, inst)
end

local function randBetween(range)
	if typeof(range) == "NumberRange" then
		return math.random() * (range.Max - range.Min) + range.Min
	end
	return range
end

function ParticleComp.new()
	local self = setmetatable({}, ParticleComp)
	self.Particles = {}
	self.Running = false
	self.EmitLooping = false
	self.Paused = false
	self.Frame = Frame
	
	self.MaxFps = DEFAULT_CONFIG.MaxFps
	self._accum = 0
	return self
end

function ParticleComp:Emit(amount, config)
	config = config and table.clone(config) or table.clone(DEFAULT_CONFIG)
	for k, v in pairs(DEFAULT_CONFIG) do
		if config[k] == nil then config[k] = v end
	end

	for _ = 1, amount do
		local img = getFromPool()
		img.Image = config.Image
		img.ImageColor3 = config.Color

		local startSize = randBetween(config.Size)
		local endSize = randBetween(config.Size)
		img.Size = UDim2.fromOffset(startSize, startSize)

		local startT = config.Transparency.Min
		local endT = config.Transparency.Max
		img.ImageTransparency = startT

		img.Rotation = math.random(0, 360)

		local offset = Vector2.zero
		if config.SpawnRadius > 0 then
			local angle = math.random() * math.pi * 2
			local dist = math.random() * config.SpawnRadius
			offset = Vector2.new(math.cos(angle), math.sin(angle)) * dist
		end
		img.Position = UDim2.fromOffset(config.Position.X + offset.X, config.Position.Y + offset.Y)

		local velocity = Vector2.zero
		if config.UsePhysics then
			local angle = math.random() * math.pi * 2
			local speed = randBetween(config.Speed)
			velocity = Vector2.new(math.cos(angle) * speed, math.sin(angle) * speed)
		end

		table.insert(self.Particles, {
			Instance = img,
			Lifetime = config.Lifetime * (0.8 + math.random() * 0.4),
			Age = 0,
			Velocity = velocity,
			Gravity = config.Gravity,
			Drag = config.Drag,
			RotationSpeed = randBetween(config.RotationSpeed),

			StartSize = startSize,
			EndSize = endSize,
			DeltaSize = endSize - startSize,

			StartTransparency = startT,
			EndTransparency = endT,
			DeltaTransparency = endT - startT,
		})
	end
end

function ParticleComp:Start()
	if self.Running then return end
	self.Running = true
	self._accum = 0

	self.Connection = RunService.RenderStepped:Connect(function(dt)
		if self.Paused then return end

		local frameTime = 1 / self.MaxFps
		self._accum += dt
		if self._accum < frameTime then
			return
		end
		dt = self._accum
		self._accum = 0

		for i = #self.Particles, 1, -1 do
			local p = self.Particles[i]
			p.Age += dt

			if p.Age >= p.Lifetime then
				returnToPool(p.Instance)
				table.remove(self.Particles, i)
			else
				local t = p.Age / p.Lifetime

				p.Velocity += p.Gravity * dt
				p.Velocity *= (1 - p.Drag * dt)
				local pos = p.Instance.Position
				p.Instance.Position = UDim2.fromOffset(
					pos.X.Offset + p.Velocity.X * dt,
					pos.Y.Offset + p.Velocity.Y * dt
				)

				p.Instance.Rotation += p.RotationSpeed * dt

				local size = p.StartSize + p.DeltaSize * t
				p.Instance.Size = UDim2.fromOffset(size, size)

				p.Instance.ImageTransparency = p.StartTransparency + p.DeltaTransparency * t
			end
		end
	end)
end

function ParticleComp:EmitOverTime(rate, duration, config)
	task.spawn(function()
		local elapsed = 0
		while elapsed < duration and self.Running do
			if not self.Paused then
				self:Emit(rate, config)
				elapsed += 1 / rate
			end
			task.wait(1 / rate)
		end
	end)
end

function ParticleComp:EmitLoop(rate, config)
	self.EmitLooping = true
	task.spawn(function()
		while self.Running and self.EmitLooping do
			if not self.Paused then
				self:Emit(1, config)
			end
			task.wait(1 / rate)
		end
	end)
end

function ParticleComp:StopLoop()
	self.EmitLooping = false
end

function ParticleComp:Stop()
	self.Running = false
	self.EmitLooping = false
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
end

function ParticleComp:Pause()
	if not self.Running then return end
	self.Paused = true
end

function ParticleComp:Resume()
	if not self.Running then return end
	self.Paused = false
end

function ParticleComp:Clear()
	for _, p in ipairs(self.Particles) do
		if p.Instance then returnToPool(p.Instance) end
	end
	self.Particles = {}
end

return ParticleComp