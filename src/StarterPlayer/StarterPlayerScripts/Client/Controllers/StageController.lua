local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local TweenComponent = require(Assets.Components.TweenComponent)
local LabelComponent = require(Assets.Components.LabelComponent)
local TriggerComponent = require(Assets.Components.TriggerComponent)
local TweenComponent = require(Assets.Components.TweenComponent)

local React = require(Packages.React)
local Knit = require(Packages.Knit)
local Trove = require(Packages.Trove)
local Easing = require(Assets.Modules.Easing)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local CurrentCamera = workspace.CurrentCamera

local MainGui = PlayerGui:WaitForChild("MainGui")

local Worlds:Folder = workspace.Worlds

local StageController = Knit.CreateController { Name = script.Name }

function StageController:CheckStarting()
	local function InitHitbox(value)
		local startHitbox = value:FindFirstChild("StartHitbox")
		if startHitbox then
			local billboardLabel = startHitbox:FindFirstChildOfClass("BillboardGui")
						
			if startHitbox and billboardLabel then
				local lable = billboardLabel:FindFirstChildWhichIsA("TextLabel")
				local triggerClass = TriggerComponent.new(startHitbox)
		
				local originalText = lable.Text 
				local originalRotation = lable.Rotation
				local originalSize = lable.TextSize
				
				local countdownTask = nil
				local currentTween = nil
				local COUNTDOWN_TIME = 3 
		
				triggerClass.OnTouched:Connect(function(player:Player)
					if player ~= LocalPlayer then return end
					if countdownTask then return end
		
					countdownTask = task.spawn(function()
						for i = COUNTDOWN_TIME, 1, -1 do
							lable.Text = i
		
							self.AudioController:PlaySound("Time Tick")
							
							if currentTween then currentTween:Destroy() end
		
							currentTween = TweenComponent.new(0.8, function(alpha)
								local wobble = math.sin(alpha * math.pi * 8) 
								local decay = (1 - alpha) 
								local rotationOffset = wobble * decay * 15
								
								lable.Rotation = originalRotation + rotationOffset
								
								local sizeOffset = (1 - alpha) * (originalSize * 0.5) 
								lable.TextSize = originalSize + sizeOffset
							end, Easing.OutQuad)
							
							currentTween:Play()
							task.wait(1)
						end
		
						if currentTween then currentTween:Destroy() end
						
						lable.Text = "Starting!"
						lable.Rotation = originalRotation
						lable.TextSize = originalSize
		
						self.StageService:Start():andThen(function(value)
							if value then
								self.Playing = true
							end
						end)
		
						countdownTask = nil
						task.wait(1)
						lable.Text = originalText
					end)
				end)
		
				triggerClass.OnTouchEnded:Connect(function(player:Player)
					if player ~= LocalPlayer then return end
		
					if countdownTask then
						task.cancel(countdownTask)
						countdownTask = nil
					end
					
					if currentTween then
						currentTween:Destroy()
						currentTween = nil
					end
		
					lable.Text = originalText 
					lable.Rotation = originalRotation
					lable.TextSize = originalSize
				end)
		
				self.Clean:Add(triggerClass, "Destroy")
			end
		end
	end

	for index, value:Folder in Worlds:GetChildren() do
		InitHitbox(value)
		value.ChildAdded:Connect(function(child)
			if child.Name == "StartHitbox" then
				InitHitbox(value)
			end
		end)
	end
end

function StageController:KnitInit()
    self.ProfileController = Knit.GetController("ProfileController")
    self.StageService = Knit.GetService("StageService")
	self.AudioController = Knit.GetController("AudioController")

    self.Playing = false
    self.StageService.GameEnd:Connect(function()
        self.Playing = false
    end)

    self.Clean = Trove.new()
end

function StageController:KnitStart()
    local attempts = 0
    while not self.ProfileController:IsLoaded() do
        task.wait(0.5)
        attempts += 1
        if attempts > 20 then
            warn("ProfileController took too long to load! forcing "..script.Name.." initialization.")
            break
        end
    end

    self:CheckStarting()
end

return StageController