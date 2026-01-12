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

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

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
        while task.wait(3) and self and self.Tool do
            self.Tool:Swing()
        end
    end)

    task.spawn(function()
        self:InitPath()
    end)
end

function Enemy:InitPath()
    self.Pathway = PathwayComponent.new(self.Model)
    self.Pathway.Visualize = true

    while self.Pathway and typeof(self.Pathway.Run) == "function" do
        local data = self.CharacterController:GetPlayerData(LocalPlayer)
        if data and data.RootPart then
            self.Pathway:Run(data.RootPart)
        end
        task.wait()
    end
end

function Enemy:TakeDamage(Data)
    self.Health = Data.CurrentHealth
    if self.Health <= 0 then
        self:Destroy()
    end
end

function Enemy:Destroy()
    warn("Enemy "..self.ID.." has been destroyed.")
    if self.Pathway then
        self.Pathway:Destroy()
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