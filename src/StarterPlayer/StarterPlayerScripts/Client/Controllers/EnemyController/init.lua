local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local PathwayComponent = require(Assets.Components.PathwayComponent)

local Knit = require(Packages.Knit)

local EnemyClass = require(script.Base)

local EnemyController = Knit.CreateController {
    Name = script.Name,
}

function EnemyController:GetEnemyProperties(Name)
    local Module = Assets:FindFirstChild("Enemies") and Assets.Enemies:FindFirstChild(Name)
    if Module and Module:IsA("ModuleScript") then 
        return require(Module)
    end
end

function EnemyController:GetEnemyModel(Name)
    local Module = Assets:FindFirstChild("Enemies") and Assets.Enemies:FindFirstChild(Name)
    if Module and Module:IsA("ModuleScript") then 
        return Module:FindFirstChildWhichIsA("Model")
    end
end

function EnemyController:GetEnemy(ID)
    return self._enemies[ID]
end

function EnemyController:SpawnNpc(Data)
    local EnemyProperties = self:GetEnemyProperties(Data.Name)
    if EnemyProperties then
        if EnemyClass then
            local enemyInstance = EnemyClass.new({
                Name = Data.Name,
                ID = Data.ID,
                CFrame = Data.CFrame
            })
            enemyInstance:Init()
            self._enemies[enemyInstance.ID] = enemyInstance
            return enemyInstance.Model
        end
    end
    return nil
end

function EnemyController:KnitInit()
    warn("Initializing EnemyController...")
    self.ProfileController = Knit.GetController("ProfileController")
    self.InventoryController = Knit.GetController("InventoryController")
    self.EnemyService = Knit.GetService("EnemyService")

    self._enemies = {}
end

function EnemyController:KnitStart()
    local attempts = 0
    while not self.ProfileController:IsLoaded() do
        task.wait(0.5)
        attempts += 1
        if attempts > 20 then
            warn("ProfileController took too long to load! forcing "..script.Name.." initialization.")
            break
        end
    end
    
    self.EnemyService.CreateEnemy:Connect(function(...)
        self:SpawnNpc(...)
    end)

    self.EnemyService.DamageEnemy:Connect(function(Data)
        local enemy = self:GetEnemy(Data.ID)
        if enemy then
            enemy:TakeDamage(Data)
        end
    end)
end

return EnemyController