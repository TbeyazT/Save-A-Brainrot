local Easing = {}

local Pow = math.pow

local function Sin(x)
	return math.sin(x)
end

local function Cos(x)
	return math.cos(x)
end

local function Abs(x)
	return math.abs(x)
end

local function PI()
	return math.pi
end

-- Basic Easing Functionsss
function Easing.easeInQuad(t)
	return t * t
end

function Easing.easeOutQuad(t)
	return 1 - (1 - t) * (1 - t)
end

function Easing.easeInOutQuad(t)
	return t < 0.5 and 2 * t * t or 1 - Pow(-2 * t + 2, 2) / 2
end

function Easing.easeInCubic(t)
	return t * t * t
end

function Easing.easeOutCubic(t)
	return 1 - Pow(1 - t, 3)
end

function Easing.easeInOutCubic(t)
	return t < 0.5 and 4 * t * t * t or 1 - Pow(-2 * t + 2, 3) / 2
end

-- Circular Functions
function Easing.circIn(t)
	return 1 - Pow(1 - t * t, 0.5)
end

function Easing.circOut(t)
	return Pow(1 - Pow(t - 1, 2), 0.5)
end

function Easing.circInOut(t)
	return t < 0.5 
		and (1 - Pow(1 - Pow(2 * t, 2), 0.5)) / 2 
		or (Pow(1 - Pow(-2 * t + 2, 2), 0.5) + 1) / 2
end

-- Exponential Functions
function Easing.expIn(t)
	return t == 0 and 0 or Pow(2, 10 * t - 10)
end

function Easing.expOut(t)
	return t == 1 and 1 or 1 - Pow(2, -10 * t)
end

function Easing.expInOut(t)
	if t == 0 or t == 1 then return t end
	return t < 0.5 
		and Pow(2, 20 * t - 10) / 2 
		or (2 - Pow(2, -20 * t + 10)) / 2
end

-- Back Functions
function Easing.backIn(t)
	local c1 = 1.70158
	return c1 * t * t * (t - c1)
end

function Easing.backOut(t)
	local c1 = 1.70158
	return 1 + c1 * Pow(t - 1, 3) + Pow(t - 1, 2)
end

function Easing.backInOut(t)
	local c1 = 1.70158 * 1.525
	return t < 0.5
		and (Pow(2 * t, 2) * ((c1 + 1) * 2 * t - c1)) / 2
		or (Pow(2 * t - 2, 2) * ((c1 + 1) * (t * 2 - 2) + c1) + 2) / 2
end

-- Bounce Functions
function Easing.bounceOut(t)
	if t < 1 / 2.75 then
		return 7.5625 * t * t
	elseif t < 2 / 2.75 then
		t = t - 1.5 / 2.75
		return 7.5625 * t * t + 0.75
	elseif t < 2.5 / 2.75 then
		t = t - 2.25 / 2.75
		return 7.5625 * t * t + 0.9375
	else
		t = t - 2.625 / 2.75
		return 7.5625 * t * t + 0.984375
	end
end

function Easing.bounceIn(t)
	return 1 - Easing.bounceOut(1 - t)
end

function Easing.bounceInOut(t)
	if t < 0.5 then
		return (1 - Easing.bounceOut(1 - 2 * t)) / 2
	else
		return (1 + Easing.bounceOut(2 * t - 1)) / 2
	end
end

-- Elastic Functions
function Easing.elasticIn(t)
	if t == 0 or t == 1 then return t end
	local p = 0.3
	return -Pow(2, 10 * (t - 1)) * Sin((t - 1 - p / (2 * PI())) * (2 * PI()) / p)
end

function Easing.elasticOut(t)
	if t == 0 or t == 1 then return t end
	local p = 0.3
	return Pow(2, -10 * t) * Sin((t - p / (2 * PI())) * (2 * PI()) / p) + 1
end

function Easing.elasticInOut(t)
	if t == 0 or t == 1 then return t end
	local p = 0.3 * 1.5
	t = t * 2
	if t < 1 then
		return -0.5 * Pow(2, 10 * (t - 1)) * Sin((t - 1 - p / (2 * PI())) * (2 * PI()) / p)
	else
		t = t - 1
		return Pow(2, -10 * t) * Sin((t - p / (2 * PI())) * (2 * PI()) / p) * 0.5 + 1
	end
end

-- Sine Functions
function Easing.sineIn(t)
	return 1 - Cos(t * PI() / 2)
end

function Easing.sineOut(t)
	return Sin(t * PI() / 2)
end

function Easing.sineInOut(t)
	return -0.5 * (Cos(PI() * t) - 1)
end

return Easing