local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Knit = require(Packages.Knit)
local Trove = require(Packages.Trove)

local LocalPlayer = Players.LocalPlayer
local Audios = Assets.Sounds

local AudioController = Knit.CreateController{
    Name = script.Name
}

function AudioController:KnitInit()
    self._trove = Trove.new()
    
    self._activeLoops = {} 
end

function AudioController:KnitStart()
    local AudioService = Knit.GetService("AudioService")

    AudioService.PlayAudio:Connect(function(soundName, properties)
        self:PlaySound(soundName, properties)
    end)
end

--[[ 
    =============================================
    CORE FUNCTIONS
    =============================================
]]

-- 1. BASIC 2D SOUND
function AudioController:PlaySound(soundName, properties)
    local soundTemplate = self:_GetSound(soundName)
    if not soundTemplate then return end

    local sound = soundTemplate:Clone()
    self:_ApplyProperties(sound, properties)
    
    sound.Parent = SoundService
    sound:Play()
    
    sound.Ended:Connect(function() sound:Destroy() end)
    
    return sound
end

function AudioController:PlaySound3D(soundName, target, properties)
    local soundTemplate = self:_GetSound(soundName)
    if not soundTemplate then return end

    local sound = soundTemplate:Clone()
    self:_ApplyProperties(sound, properties)

    local attachment = nil

    if typeof(target) == "Instance" and target:IsA("BasePart") then
        sound.Parent = target
    elseif typeof(target) == "Vector3" then
        attachment = Instance.new("Attachment")
        attachment.WorldPosition = target
        attachment.Parent = Workspace.Terrain
        sound.Parent = attachment
    else
        warn("AudioController: Invalid target for 3D sound", target)
        return
    end

    sound:Play()

    sound.Ended:Connect(function()
        sound:Destroy()
        if attachment then attachment:Destroy() end
    end)

    return sound
end

function AudioController:StartLoop(soundName, properties)
    local soundTemplate = self:_GetSound(soundName)
    if not soundTemplate then return end

    local id = game:GetService("HttpService"):GenerateGUID(false)

    local sound = soundTemplate:Clone()
    self:_ApplyProperties(sound, properties)
    sound.Looped = true
    sound.Parent = SoundService
    sound:Play()

    self._activeLoops[id] = sound
    return id
end

function AudioController:StopLoop(loopId, fadeTime)
    local sound = self._activeLoops[loopId]
    if sound then
        self._activeLoops[loopId] = nil -- Remove from registry immediately
        
        if fadeTime then
            local tween = TweenService:Create(sound, TweenInfo.new(fadeTime), {Volume = 0})
            tween:Play()
            tween.Completed:Connect(function() sound:Destroy() end)
        else
            sound:Destroy()
        end
    end
end

function AudioController:PlayRandom(soundName, properties)
    properties = properties or {}
    
    local basePitch = properties.Pitch or 1
    local variance = 0.1
    properties.Pitch = basePitch + (math.random() * variance * 2 - variance)
    
    return self:PlaySound(soundName, properties)
end

function AudioController:BindButton(guiObject, hoverSoundName, clickSoundName)
    if not guiObject then return end
    
    local trove = Trove.new() 
    
    if hoverSoundName then
        trove:Connect(guiObject.MouseEnter, function()
            self:PlaySound(hoverSoundName)
        end)
    end
    
    if clickSoundName then
        trove:Connect(guiObject.Activated, function()
            self:PlaySound(clickSoundName)
        end)
    end
    
    trove:AttachToInstance(guiObject)
end


--[[ 
    =============================================
    INTERNAL HELPERS
    =============================================
]]

function AudioController:_GetSound(name)
    local sound = Audios:FindFirstChild(name, true)
    if not sound then
        warn("AudioController: Sound not found:", name)
        return nil
    end
    return sound
end

function AudioController:_ApplyProperties(soundInstance, props)
    if props then
        for k, v in pairs(props) do
            soundInstance[k] = v
        end
    end
end

return AudioController