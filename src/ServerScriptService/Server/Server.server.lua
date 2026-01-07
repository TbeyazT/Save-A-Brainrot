local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameVersion = "0.1.0"

local Packages = ReplicatedStorage:FindFirstChild("Packages")

local Knit = require(Packages.Knit)

Knit.AddServicesDeep(script.Parent.Services)

Knit:Start():andThen(
    function()
        warn("Knit started successfully! {" .. GameVersion .. "}")
    end
):catch(
    function(err)
        warn("Knit failed to start: " .. tostring(err))
    end
)