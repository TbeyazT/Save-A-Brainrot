-- Server

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local Knit = require(Packages.Knit)
local TableUtil = require(Packages.TableUtil)
local Signal = require(Packages.Signal)

local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(Data)
    local self = setmetatable({}, Enemy)

    self.EnemyService = Knit.GetService("EnemyService")
    self.InventoryService = Knit.GetService("InventoryService")
    self.Properties = TableUtil.Copy(require(script.Parent))

    self.ID = HttpService:GenerateGUID(false)
    self.Player = Data.Player

    self.Died = Signal.new()

    self.Health = self.Properties.Health or 100

    return self
end

function Enemy:TakeDamage(Amount)
    self.Health = self.Health - Amount
    self.EnemyService.Client.DamageEnemy:Fire(self.Player,{
        ID = self.ID,
        TakenDamage = Amount,
        CurrentHealth = self.Health,
    })
    if self.Health <= 0 then
        self:Destroy()
    end
end

function Enemy:Init()
    self.Tool = self.InventoryService:EquipTool(nil,self.Properties.Sword,self)
end

function Enemy:Destroy()
    if self.Tool then
        self.InventoryService:UnequipTool(nil,self.Tool,self)
        self.Tool = nil
    end

    if self.Died then
        self.Died:Fire()
        self.Died:Destroy()
    end

    setmetatable(self, nil)
end

return Enemy