-- Client

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local Knit = require(Packages.Knit)
local TableUtil = require(Packages.TableUtil)

local enemiesFolder = workspace:WaitForChild("Enemies")

local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(Data)
    local self = setmetatable({}, Enemy)

    self.EnemyController = Knit.GetController("EnemyController")
    self.InventoryController = Knit.GetController("InventoryController")
    self.Properties = TableUtil.Copy(require(script.Parent))

    self.Model = self.EnemyController:GetEnemyModel(self.Properties.Name):Clone()

    self.Health = self.Properties.Health or 100
    self.ID = Data.ID

    return self
end

function Enemy:Init()
    self.Model.Name = self.ID
    self.Model.Parent = enemiesFolder
    if self.Properties.SpawnLocation and typeof(self.Properties.SpawnLocation) == "CFrame" then
        self.Model:PivotTo(self.Properties.SpawnLocation)
    else
        self.Model:PivotTo(CFrame.new(0, 5, 0))
    end

    CollectionService:AddTag(self.Model, "NPC")

    self.Tool = self.InventoryController:EquipTool(self.Model,self.Properties.Sword,self.ID)

    task.spawn(function()
        while task.wait(3) do
                self.Tool:Swing()
            end
    end)
end

function Enemy:TakeDamage(Data)
    self.Health = Data.CurrentHealth
    warn("Enemy "..self.ID.." has "..self.Health.." health remaining.")
    if self.Health <= 0 then
        self:Destroy()
    end
end

function Enemy:Destroy()
    if self.Tool then
        self.InventoryController:UnequipTool(self.Model)
        self.Tool = nil
    end

    if self.Model then
        self.Model:Destroy()
        self.Model = nil
    end

    setmetatable(self, nil)
end

return Enemy