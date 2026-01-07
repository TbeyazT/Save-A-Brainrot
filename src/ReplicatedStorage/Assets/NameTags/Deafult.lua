local RunService = game:GetService("RunService")

local module = {}
module.__index = module

function module.new()
	local self = setmetatable({}, module)
	return self
end

function module:Init()
	local Tag = script:FindFirstChildOfClass("BillboardGui")
	self.NameTag = Tag:Clone()
end

function module:Destroy()
	self.NameTag:Destroy()
end


return module