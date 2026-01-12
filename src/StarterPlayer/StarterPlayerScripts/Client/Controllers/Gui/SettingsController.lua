local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local GradientComponent = require(Assets.Components.GradientComponent)
local AnimationComponent = require(Assets.Components.AnimationComponent)

local Knit = require(Packages.Knit)
local TableUtil = require(Packages.TableUtil)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local MainGui = PlayerGui:WaitForChild("MainGui")

local Settings = MainGui.settings
local SFrame = Settings.settings

local temp = SFrame:FindFirstChild("Template")

local OnColor = ColorSequence.new({
	ColorSequenceKeypoint.new(0,Color3.fromRGB(0,255,8)),
	ColorSequenceKeypoint.new(1,Color3.fromRGB(42,173,68))
})

local OffColor = ColorSequence.new({
	ColorSequenceKeypoint.new(0,Color3.fromRGB(255,19,125)),
	ColorSequenceKeypoint.new(1,Color3.fromRGB(173,0,3))
})

local SettingsController = Knit.CreateController{
	Name = script.Name
}

function SettingsController:GetSetting(Name)
	return self.ProfileController:Get("Settings"):andThen(function(Data)
		return Data[Name]
	end)
end

function SettingsController:Init()
	self.ProfileController:Get("Settings"):andThen(function(Data)
		for Name,Bool in pairs(Data) do
			local Frame = temp:Clone()
			local button = Frame:FindFirstChildWhichIsA("GuiButton")
			
			if button then
				local gradient = button:FindFirstChildWhichIsA("UIGradient")
				local gradientClass 
				Frame.Name = Name
				Frame.TextLabel.Text = Name
				button.TextLabel.Text = Bool and "ON" or "OFF"
				if gradient then
					gradientClass = GradientComponent.new(gradient)
					gradient.Color = Bool and OnColor or OffColor
				end
				
				Frame.Parent = SFrame
				
				local class = AnimationComponent.new(button)
				class:Init(nil,function()
					self.ProfileService:ChangeSetting(Name):andThen(function(value)
						button.TextLabel.Text = value and "ON" or "OFF"
						if gradient then
							gradientClass:Lerp(gradient.Color,value and OnColor or OffColor,0.3)
						end
					end)
				end)
				
				Frame.Visible = true
			end
		end
	end)
end

function SettingsController:KnitInit()
	self.ProfileController = Knit.GetController("ProfileController")
	self.ProfileService = Knit.GetService("ProfileService")
end

function SettingsController:KnitStart()
	repeat task.wait(0.3) until self.ProfileController:IsLoaded()
	
	self:Init()
end

return SettingsController