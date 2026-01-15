local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players           = game:GetService("Players")

local Assets = ReplicatedStorage:FindFirstChild("Assets")
local Packages = ReplicatedStorage:FindFirstChild("Packages")

local Dumpster = require(Packages.Dumpster)
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)
local TableUtil = require(Packages.TableUtil)

export type CharacterData = {
	Model: Model,
	Humanoid: Humanoid,
	RootPart: BasePart,
	Animator: Animator?,
	Player: Player?,
	IsPlayer: boolean,
	Dumpster: any
}

local StageService = Knit.CreateService{ 
    Name = script.Name,
    Client = {
        GameEnd = Knit.CreateSignal()
    }
}

function StageService:GetPlayerState(Player:Player):table?
    return self._playerStates[Player]
end

function StageService:TakeDamage(Player,Amount)
    local _state = self:GetPlayerState(Player)
    warn("dealing damage")
    if _state.Health <= 0 then return end
    if _state then
        _state.Health -= Amount
        warn(_state.Health)
        if _state.Health <= 0 then
           if _state.Died then
               _state.Died:Fire()
           end
           task.spawn(function()
                task.wait(0.3)
                self:Respawn(Player)
           end)
        end
    end
end

function StageService:Respawn(Player:Player)
    local _state = self:GetPlayerState(Player)
    local health = self.ProfileService:Get(Player,"MaxHealth")
    if _state then
        _state.Health = health
    end
end

function StageService:StartPlayer(Player:Player)
    local PlayerState = self:GetPlayerState(Player)
    if PlayerState and not PlayerState.Playing then
        local world = self.ProfileService:Get(Player,"World")
        if world then
            PlayerState.Playing = true
            self:BeginWaves(Player)
            return true
        else
            self.NotificationService:Notify(Player,"")
            return false
        end
    else
        self.NotificationService:Notify(Player,"either your state doesnt exists or you are already in game")
        return false
    end
end

function StageService:BeginWaves(Player:Player)
    local world = self.ProfileService:Get(Player,"World")
    if world then
        local StartProperties = Assets.WorldProperties:FindFirstChild(world)
        if StartProperties then
            StartProperties = require(StartProperties)
            task.spawn(function()
                local lost = false
                for index, StageData in StartProperties.Waves do
                    local finished = false
                    local enemies = {}

                    local Stage = workspace.Stages:FindFirstChild(StageData.Stage)
                    local Character:CharacterData = self.CharacterService:GetCharacter(Player)
                    local PlayerState = self:GetPlayerState(Player)

                    if Stage then
                        local SpawnPoint = Stage:FindFirstChild("SpawnPoint")
                        if SpawnPoint and Character then
                            PlayerState.Died:Connect(function()
                                warn("diedlol")
                                finished = true
                                lost = true
                            end)
                            Character.RootPart.CFrame = SpawnPoint.CFrame
                            local deathCount = 0
                            for _,enemyData in pairs(StageData.Enemies) do
                                local enemyName = enemyData[1]
                                local spawnCount = enemyData[2]
                                local delay = enemyData[3]
                                if enemyName and spawnCount then
                                    for i = 1, spawnCount do
                                        local enemySpawnPoint = nil
                                        local partTable = {}
                                        for index, value in Stage.EnemiesSpawn:GetChildren() do
                                            if value:IsA("BasePart") then
                                                table.insert(partTable,value)
                                            end
                                        end 
                                        enemySpawnPoint = partTable[math.random(1,#partTable)]
                                        if enemySpawnPoint then
                                            local enemy = self.EnemyService:CreateEnemy(Player,{
                                                Name = enemyName,
                                                CFrame = enemySpawnPoint.CFrame
                                            })
                                            table.insert(enemies,enemy)
                                            if enemy then
                                                enemy.Died:Connect(function()
                                                    deathCount += 1
                                                    if deathCount >= spawnCount then
                                                        finished = true
                                                    end
                                                end)
                                            end
                                            task.wait(delay and delay or 0)
                                        end
                                    end
                                end
                            end
                        end
                    end

                    repeat
                        task.wait(0.3)
                    until finished
                    for i = #enemies, 1, -1 do
                        enemies[i]:Destroy()
                    end
                    table.clear(enemies)

                    if lost then
                        break
                    end
                end
                self.Client.GameEnd:Fire(Player,lost)
            end)
        end
    end
end

function StageService.Client:Start(...)
    return self.Server:StartPlayer(...)
end

function StageService:KnitInit()
    self.ProfileService = Knit.GetService("ProfileService")
    self.CharacterService = Knit.GetService("CharacterService")
    self.NotificationService = Knit.GetService("NotificationService")
    self.EnemyService = Knit.GetService("EnemyService")

    self._playerStates = {}

    self.ProfileService:ObservePlayerAdded(function(player)
        local health = self.ProfileService:Get(player,"MaxHealth")
        self._playerStates[player] = {
            Playing = false,
            Health = health,
            Died = Signal.new(),
        }
    end)
end

return StageService