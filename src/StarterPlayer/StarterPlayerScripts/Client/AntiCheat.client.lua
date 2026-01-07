--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local isStudio = RunService:IsStudio()
local isXbox = GuiService:IsTenFootInterface()
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled

local function Detected(action, info, nocrash)
	if action == "kick" then
		if not RunService:IsStudio() then
			if nocrash then
				LocalPlayer:Kick("Anti Cheat: " .. info)
			else
				for _,Sound in pairs(game:GetService("SoundService"):GetDescendants()) do
					if Sound:IsA("Sound") then
						Sound:Stop()
					end
				end
				if script:FindFirstChild("...") then
					script["..."]:Play()
				end
				task.wait(1)
				if not isStudio then
					task.spawn(pcall, function()
						task.wait(5)
						while true do
							pcall(task.spawn, function()
								task.spawn(Detected("crash","31"))
							end)
						end
					end)
				end
			end
		end
	elseif action == "crash" then
		for _,Sound in pairs(game:GetService("SoundService"):GetDescendants()) do
			if Sound:IsA("Sound") then
				Sound:Stop()
			end
		end
		if script:FindFirstChild("...") then
			script["..."]:Play()
		end
		if not isStudio then
			task.spawn(pcall, function()
				task.wait(5)
				while true do
					pcall(task.spawn, function()
						task.spawn(Detected("crash","31"))
					end)
				end
			end)
		end
	end
	return true
end

_G.detected = function()
	Detected("crash","lol")
end

local function compareTables(t1, t2)
	if #t1 ~= #t2 then
		return false
	end
	for k, v in pairs(t1) do
		if t1[k] ~= t2[k] then
			return false
		end
	end
	return true
end

local function proxyMethodDetected(methodName)
	Detected("crash", "Proxy metaMethod " .. methodName)
	task.wait(9e9)
end

local proxyDetector = newproxy(true)
local proxyMt = getmetatable(proxyDetector)
proxyMt.__index = function() proxyMethodDetected("index") end
proxyMt.__newindex = function() proxyMethodDetected("newindex") end
proxyMt.__tostring = function() proxyMethodDetected("tostring") end
proxyMt.__unm = function() proxyMethodDetected("unm") end
proxyMt.__add = function() proxyMethodDetected("add") end
proxyMt.__sub = function() proxyMethodDetected("sub") end
proxyMt.__mul = function() proxyMethodDetected("mul") end
proxyMt.__div = function() proxyMethodDetected("div") end
proxyMt.__mod = function() proxyMethodDetected("mod") end
proxyMt.__pow = function() proxyMethodDetected("pow") end
proxyMt.__len = function() proxyMethodDetected("len") end
proxyMt.__metatable = "The metatable is locked"

local callStacks = {
	indexInstance = {},
	newindexInstance = {},
	namecallInstance = {},
	indexEnum = {},
	namecallEnum = {},
	eqEnum = {},
}

local function checkStack(method)
	local firstTime = #callStacks[method] <= 0

	for i = 3, 4 do
		local func = debug.info(i, "f")

		if firstTime then
			callStacks[method][i] = func
		elseif callStacks[method][i] ~= func then
			return true
		end
	end

	return false
end

local function Wrapped(object)
	if type(getmetatable(object)) == "table" and rawget(getmetatable(object), "__WRAPPED") or getmetatable(object) == "TbeyazT_Proxy" then
		return true
	elseif (type(object) == "table" or typeof(object) == "userdata") and object.IsProxy and object:IsProxy() then
		return true
	else
		return false
	end
end

local function UnWrap(object)
	local OBJ_Type = typeof(object)

	if OBJ_Type == "Instance" then
		return object
	elseif OBJ_Type == "table" then
		local tab = {}
		for i, v in pairs(object) do
			tab[i] = UnWrap(v)
		end
		return tab
	elseif Wrapped(object) then
		return object:GetObject()
	else
		return object
	end
end

local function isMethamethodValid(metamethod)
	return metamethod and type(metamethod) == "function" and debug.info(metamethod, "s") == "[C]" and debug.info(metamethod, "l") == -1 and debug.info(metamethod, "n") == "" and debug.info(metamethod, "a") == 0
end

local rawGame = UnWrap(game)
local errorMessages = {}

local detectors = table.freeze{
	indexInstance = table.freeze{"kick", function()
		local callstackInvalid = false
		local metamethod

		local success, err = xpcall(function()
			local c = rawGame.____________
			warn(c)
		end, function()
			metamethod = debug.info(2, "f")
			if callstackInvalid or checkStack("indexInstance") then
				callstackInvalid = true
			end
		end)

		if not isMethamethodValid(metamethod) then
			return true
		end

		local success3, err3 = pcall(metamethod, rawGame)
		local success2, err2 = pcall(metamethod)
		pcall(metamethod, proxyDetector, "GetChildren")
		pcall(metamethod, proxyDetector)
		pcall(metamethod, rawGame, proxyDetector)

		if callstackInvalid or success or success2 or success3 then
			return true
		elseif not errorMessages["indexInstance"] then
			errorMessages["indexInstance"] = {err, err2, err3}
		end

		return not compareTables(errorMessages["indexInstance"], {err, err2, err3})
	end},
	newindexInstance = table.freeze{"kick", function()
		local callstackInvalid = false
		local metamethod

		local success, err = xpcall(function()
			rawGame.____________ = 5
		end, function()
			metamethod = debug.info(2, "f")
			if callstackInvalid or checkStack("newindexInstance") then
				callstackInvalid = true
			end
		end)

		if not isMethamethodValid(metamethod) then
			return true
		end

		local success3, err3 = pcall(metamethod, rawGame)
		local success2, err2 = pcall(metamethod)
		pcall(metamethod, proxyDetector, "GetChildren")
		pcall(metamethod, proxyDetector)
		pcall(metamethod, rawGame, proxyDetector)
		pcall(metamethod, rawGame, "AllowThirdPartySales", proxyDetector)

		if callstackInvalid or success or success2 or success3 then
			return true
		elseif not errorMessages["newindexInstance"] then
			errorMessages["newindexInstance"] = {err, err2, err3}
		end

		return not compareTables(errorMessages["newindexInstance"], {err, err2, err3})
	end},
	namecallInstance = table.freeze{"kick", function()
		local callstackInvalid = false
		local metamethod

		local success, err = xpcall(function()
			local c = rawGame:____________()
		end, function()
			metamethod = debug.info(2, "f")
			if callstackInvalid or checkStack("namecallInstance") then
				callstackInvalid = true
			end
		end)

		if not isMethamethodValid(metamethod) then
			return true
		end

		local success3, err3 = pcall(metamethod, rawGame)
		local success2, err2 = pcall(metamethod)
		pcall(metamethod, proxyDetector)
		pcall(metamethod, rawGame, proxyDetector)

		if callstackInvalid or success or success2 or success3 then
			return true
		elseif not errorMessages["namecallInstance"] then
			errorMessages["namecallInstance"] = {err, err2, err3}
		end

		return not compareTables(errorMessages["namecallInstance"], {err, err2, err3})
	end},
	indexEnum = table.freeze{"kick", function()
		local callstackInvalid = false
		local metamethod

		local success, err = xpcall(function()
			local c = Enum.HumanoidStateType.____________
		end, function()
			metamethod = debug.info(2, "f")
			if callstackInvalid or checkStack("indexEnum") then
				callstackInvalid = true
			end
		end)

		if not isMethamethodValid(metamethod) then
			return true
		end

		local success3, err3 = pcall(metamethod, Enum.HumanoidStateType)
		local success2, err2 = pcall(metamethod)
		pcall(metamethod, proxyDetector, "Name")
		pcall(metamethod, proxyDetector)
		pcall(metamethod, Enum.HumanoidStateType, proxyDetector)

		if callstackInvalid or success or success2 or success3 then
			return true
		elseif not errorMessages["indexEnum"] then
			errorMessages["indexEnum"] = {err, err2, err3}
		end

		return not compareTables(errorMessages["indexEnum"], {err, err2, err3})
	end},
	namecallEnum = table.freeze{"kick", function()
		local callstackInvalid = false
		local metamethod

		local success, err = xpcall(function()
			local c = Enum.HumanoidStateType:____________()
		end, function()
			metamethod = debug.info(2, "f")
			if callstackInvalid or checkStack("namecallEnum") then
				callstackInvalid = true
			end
		end)

		if not isMethamethodValid(metamethod) then
			return true
		end

		local success3, err3 = pcall(metamethod, Enum.HumanoidStateType)
		local success2, err2 = pcall(metamethod)
		pcall(metamethod, proxyDetector)
		pcall(metamethod, Enum.HumanoidStateType, proxyDetector)

		if callstackInvalid or success or success2 or success3 then
			return true
		elseif not errorMessages["namecallEnum"] then
			errorMessages["namecallEnum"] = {err, err2, err3}
		end

		return not compareTables(errorMessages["namecallEnum"], {err, err2, err3})
	end},
	eqEnum = table.freeze{"kick", function()
		return not (Enum.HumanoidStateType.Running == Enum.HumanoidStateType.Running)
	end},
}

RunService.RenderStepped:Connect(function()
	for method, detector in pairs(detectors) do
		local action, callback = detector[1], detector[2]

		local success, value = pcall(callback)
		if not success or value ~= false and value ~= true then
			Detected("crash", "ih")
			task.wait(1)
		elseif value then
			Detected("crash", string.format("%s detector detected", method))
		end
	end
	task.wait(0.1)
end)