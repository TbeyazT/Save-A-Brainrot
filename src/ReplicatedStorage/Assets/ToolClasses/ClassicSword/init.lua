debug.setmemorycategory(script.Name.." OHA")

local RunService = game:GetService("RunService")

if RunService:IsServer() then
	return require(script:WaitForChild("Server"))
else
	return require(script:WaitForChild("Client"))
end