debug.setmemorycategory(script.Name.." OHA")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players           = game:GetService("Players")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Dumpster = require(Packages.Dumpster)
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)


local EnemyService = Knit.CreateService {
    Name = script.Name,
    Client = {},
}

function EnemyService:GetEnemyProperties(Name)
    local Module = Assets.Enemies:FindFirstChild(Name)
    if Module and Module:IsA("ModuleScript") then 
        local EnemyProperties = require(Module)
        return EnemyProperties
    end
end

function EnemyService:GetEnemyModel(Name)
    local Module = Assets.Enemies:FindFirstChild(Name)
    if Module and Module:IsA("ModuleScript") then 
        local Model = Module:FindFirstChildWhichIsA("Model")
        if Model then
            return Model
        end
    end
end

function EnemyService:SpawnNpc(Name)
    local EnemyProperties = self:GetEnemyProperties(Name)
    local EnemyModel = self:GetEnemyModel(Name)
    if EnemyProperties and EnemyModel then
        local npc = EnemyModel:Clone()
        npc:AddTag("NPC")
        warn("Cloned NPC Model")
        npc.Name = Name

        if EnemyProperties.SpawnLocation and typeof(EnemyProperties.SpawnLocation) == "CFrame" then
            npc:SetPrimaryPartCFrame(EnemyProperties.SpawnLocation)
        else
            npc:SetPrimaryPartCFrame(CFrame.new(0,5,0))
        end

        npc.Parent = workspace.Enemies

        return npc
    end
    return nil
end

function EnemyService:KnitInit()
    self.ProfileService = Knit.GetService("ProfileService")
    self.InventoryService = Knit.GetService("InventoryService")
    self._registry = {}
end

function EnemyService:KnitStart()
    task.wait(5)
    local npc = self:SpawnNpc("TbeyazT")
    local tool = self.InventoryService:EquipTool(npc, "ClassicSword")

    while task.wait(2) do
        if tool then
            tool:Attack()
        end
    end
end

return EnemyService