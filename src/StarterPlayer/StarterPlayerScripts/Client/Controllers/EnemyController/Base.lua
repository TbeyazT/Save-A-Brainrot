-- Client
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local PathwayComponent = require(Assets.Components.PathwayComponent)

local LocalPlayer = Players.LocalPlayer

local Knit = require(Packages.Knit)
local TableUtil = require(Packages.TableUtil)

local enemiesFolder = workspace:WaitForChild("Enemies")

local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(Data)
    local self = setmetatable({}, Enemy)

    self.EnemyController = Knit.GetController("EnemyController")
    self.InventoryController = Knit.GetController("InventoryController")
    self.CharacterController = Knit.GetController("CharacterController")
    self.Properties = TableUtil.Copy(self.EnemyController:GetEnemyProperties(Data.Name))

    self.Model = self.EnemyController:GetEnemyModel(self.Properties.Name):Clone()

    self.Data = Data
    self.Health = self.Properties.Health or 100
    self.ID = Data.ID
    self.Alive = true

    self.Connections = {}

    return self
end

function Enemy:Init()
    if not self.Alive then return end
    
    self.Model.Name = self.ID
    self.Model.Parent = enemiesFolder
    
    if typeof(self.Data.CFrame) then
        self.Model:PivotTo(self.Data.CFrame)
    else
        if self.Properties.SpawnLocation and typeof(self.Properties.SpawnLocation) == "CFrame" then
            self.Model:PivotTo(self.Properties.SpawnLocation)
        else
            self.Model:PivotTo(CFrame.new(0, 5, 0))
        end
    end

    CollectionService:AddTag(self.Model, "NPC")

    self.Tool = self.InventoryController:EquipTool(self.Model, self.Properties.Sword, self.ID)

    task.spawn(function()
        while self.Alive and self.Tool do
            self.Tool:Swing()
            task.wait(3)
        end
    end)

    self:InitPath()
end

function Enemy:InitPath()
    self.Pathway = PathwayComponent.new(self.Model)
    self.Pathway.Visualize = true
    
    local function MoveToPlayer()
        if not self.Alive or not self.Pathway or not self.Model then return end
        
        local data = self.CharacterController:GetPlayerData(LocalPlayer)
        
        if data and data.RootPart then
            pcall(function()
                self.Pathway:Run(data.RootPart)
            end)
        end
    end

    table.insert(self.Connections, self.Pathway.Blocked:Connect(MoveToPlayer))
    
    task.spawn(function()
        while self.Alive do
            MoveToPlayer()
            task.wait(0.02)
        end
    end)
end

function Enemy:TakeDamage(Data)
    self.Health = Data.CurrentHealth
    if self.Health <= 0 then
        self:Destroy()
    end
end

function Enemy:Destroy()
    if not self.Alive then return end
    self.Alive = false

    for _, conn in ipairs(self.Connections) do
        if conn then conn:Disconnect() end
    end
    self.Connections = nil

    if self.Pathway then
        if self.Pathway._status ~= "idle" then
            self.Pathway:Stop()
        end
        self.Pathway:Destroy()
        self.Pathway = nil 
    end

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