local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

PhysicsService:RegisterCollisionGroup("Balls")
PhysicsService:RegisterCollisionGroup("NpcCollideable")
PhysicsService:CollisionGroupSetCollidable("NpcCollideable","NpcCollideable",false)
PhysicsService:CollisionGroupSetCollidable("Balls", "NpcCollideable", false)

local function setCollisionGroup(Character:Instance)
	for _,Part in pairs(Character:GetDescendants()) do
		if Part:IsA("BasePart") then
			Part.CollisionGroup = "NpcCollideable"
		end
	end
end
for _,Tower in pairs(ReplicatedStorage:GetDescendants()) do
	if Tower:FindFirstChild("Humanoid") then
		setCollisionGroup(Tower)
	end
end
Players.PlayerAdded:Connect(function(player)
	local character = player.Character or player.CharacterAdded:Wait()
	setCollisionGroup(character)
	player.CharacterAdded:Connect(function(character)
		setCollisionGroup(character)
	end)
end)