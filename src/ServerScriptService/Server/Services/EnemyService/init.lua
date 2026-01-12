debug.setmemorycategory(script.Name.." OHA")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players           = game:GetService("Players")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Dumpster = require(Packages.Dumpster)
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)

local EnemyClass = require(script.Base)

local EnemyService = Knit.CreateService {
    Name = script.Name,
    Client = {
        CreateEnemy = Knit.CreateSignal(),
        DamageEnemy = Knit.CreateSignal(),
    },
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

function EnemyService:GetEnemy(ID)
    return self._enemies[ID]
end

function EnemyService:CreateEnemy(Players,Data)
    local EnemyProperties = self:GetEnemyProperties(Data.Name)
    local enemyInstance = nil
    if EnemyProperties then
        local EnemyClass = require(EnemyProperties.Server)
        if EnemyClass then
            if typeof(Players) == "Instance" then
                enemyInstance = EnemyClass.new({
                    Player = Players,
                })
                self._enemies[enemyInstance.ID] = enemyInstance
                enemyInstance:Init()
                self.Client.CreateEnemy:Fire(Players,{
                    Name = Data.Name,
                    ID = enemyInstance.ID,
                    CFrame = Data.CFrame,
                })
            elseif typeof(Players) == "table" then  
                for _,player in pairs(Players) do
                    enemyInstance = EnemyClass.new({
                        Player = player,
                    })
                    self._enemies[enemyInstance.ID] = enemyInstance
                    enemyInstance:Init()
                    self.Client.CreateEnemy:Fire(player,{
                        Name = Data.Name,
                        ID = enemyInstance.ID,
                        CFrame = Data.CFrame or nil,
                    })
                end
            end
        end
    end
end

function EnemyService:KnitInit()
    self.ProfileService = Knit.GetService("ProfileService")
    self.InventoryService = Knit.GetService("InventoryService")
    self._registry = {}
    self._enemies = {}
end

function EnemyService:KnitStart()
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            task.wait(2)
            self:CreateEnemy(player,{
                Name = "TbeyazT",
                CFrame = nil,
            })
        end)
    end)
end

return EnemyService