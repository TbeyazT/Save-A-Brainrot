debug.setmemorycategory(script.Name .. " OHA")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local TextChatService = game:GetService("TextChatService")
local Lighting = game:GetService("Lighting")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local Knit = require(Packages.Knit)
local Easing = require(Assets.Modules.Easing)
local Signal = require(Packages.Signal)

local AnimationComponent = require(Assets.Components.AnimationComponent)
local FrameOpenComponent = require(Assets.Components.FrameOpenComponent)
local ParticleComponent = require(Assets.Components.ParticleComponent)
local LabelComponent = require(Assets.Components.LabelComponent)
local GradientComponent = require(Assets.Components.GradientComponent)
local TweenComponent = require(Assets.Components.TweenComponent)

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local MainGui = PlayerGui:WaitForChild("MainGui", 30)

local CurrencyFrame = MainGui.currency

local RNG = Random.new(69)

local GuiController = Knit.CreateController {Name = "GuiController"}

function GuiController:InitXButton(Frame: Frame, GivenFrameClass, func)
	local function getFrameClass()
		return GivenFrameClass or self.FrameComponents[Frame]
	end

	local function bind(btn: GuiButton)
		if not btn then return end
		local component = AnimationComponent.new(btn)
		component:Init(Enum.KeyCode.X, function()
			local FrameClass = getFrameClass()
			if FrameClass and Frame.Visible then
				if type(func) == "function" then func() end
				FrameClass:Visible(false)
			end
		end)
	end

	local XButton = Frame:FindFirstChild("xbutton",true)
	if XButton and XButton:IsA("GuiButton") then
		bind(XButton)
	else
		local XFrame = Frame:FindFirstChild("XFrame",true)
		if XFrame then
			bind(XFrame:FindFirstChildWhichIsA("GuiButton"))
		end
	end
end

function GuiController:InitSideButtons()
	local function IsPlayerGui(Frame)
		return Frame:IsDescendantOf(PlayerGui)
	end

	for _,Button in pairs(CollectionService:GetTagged("SideButtons","Buttons")) do
		local Gui = Button:FindFirstChild("Type")
		local KeyCode = Button:FindFirstChild("KeyBind")
		if Gui and Gui.Value then
			Gui = Gui.Value
			if not IsPlayerGui(Gui) then continue end

			self:InitXButton(Gui)
			if not self.FrameComponents[Gui] then
				local FrameComponent = FrameOpenComponent.new(Gui,
					TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
				)
				self.FrameComponents[Gui] = FrameComponent
				FrameComponent:Visible(false)
			end
			local effect = Button:FindFirstChild("gloweffect")
			if effect then
				table.insert(self.GlowEffects,effect)
			end

			local Component = AnimationComponent.new(Button)
			local rot = {10, -10}
			rot = rot[math.random(1, 2)]

			Component.OnHover = function()
				if Button:FindFirstChild("Display") then
					TweenService:Create(Button.Display, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
						Rotation = rot
					}):Play()
				end
			end

			Component.OnUnHover = function()
				if Button:FindFirstChild("Display") then
					TweenService:Create(Button.Display, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
						Rotation = 0
					}):Play()
				end
			end

			Component:Init(KeyCode and Enum.KeyCode[KeyCode.Value] or nil,function()
				if Gui then
					if not self.CanUseButtons then return end
					if not self.CurrentFrame or self.CurrentFrame ~= Gui then
						if self.CurrentFrame and self.CurrentFrame.Visible == true then
							self.FrameComponents[self.CurrentFrame]:Visible(false)
						end
						self.CurrentFrame = Gui
						if self.FrameComponents[Gui] then
							self.FrameComponents[Gui]:Visible(true)
						else
							local FrameComponent = FrameOpenComponent.new(Gui,
								TweenInfo.new(0.3,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out)
							)
							self.FrameComponents[Gui] = FrameComponent
							FrameComponent:Visible(true)
						end
					elseif self.CurrentFrame == Gui then
						if self.FrameComponents[Gui] then
							if Gui.Visible == true then
								self.FrameComponents[Gui]:Visible(false)
							else
								self.FrameComponents[Gui]:Visible(true)
							end
						end
					end
				end
			end)
			self.ButtonClasses[Button] = Component
		end
	end
end

function GuiController:CloseCurrentGui()
	if self.CurrentFrame then
		if self.FrameComponents[self.CurrentFrame] then
			self.FrameComponents[self.CurrentFrame]:Visible(false)
		end
		self.CurrentFrame = nil
	end
end

function GuiController:CloseAllGui()
	self:CloseCurrentGui()
	for _,Component in pairs(self.FrameComponents) do
		if Component and Component.UI.Visible then
			Component:Visible(false)
		end
	end
end

function GuiController:SetGui(Frame)
	if Frame then
		self:CloseCurrentGui()
		if self.FrameComponents[Frame] then
			self.FrameComponents[Frame]:Visible(true)
		end
		self.CurrentFrame = Frame
	end
end

function GuiController:OpenSideGuis()
	if self.SideButtonsTweening or not self.SideButtonsHidden then return end
	self.SideButtonsTweening = true

	local TI = TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut)

	for _, Button in pairs(CollectionService:GetTagged("SideButtons","Buttons")) do
		if Button:IsA("Frame") or Button:IsA("ImageButton") or Button:IsA("TextButton") then
			local original = Button:GetAttribute("OriginalPos")
			if original then
				local target = UDim2.new(original.X.Scale, original.X.Offset, original.Y.Scale, original.Y.Offset)
				local tween = TweenService:Create(Button, TI, { Position = target })
				tween:Play()
			end
		end
	end

	task.delay(0.5, function()
		self.SideButtonsHidden = false
		self.SideButtonsTweening = false
	end)
end

function GuiController:GetOffscreenPosition(frame)
	local pos = frame.Position
	local size = frame.Size

	local centerX = pos.X.Scale + size.X.Scale / 2
	local centerY = pos.Y.Scale + size.Y.Scale / 2

	local sides = {
		Left = centerX, -- distance to left
		Right = 1 - centerX, -- distance to right
		Top = centerY, -- distance to top
		Bottom = 1 - centerY -- distance to bottom
	}

	local closestSide = "Left"
	for side, dist in pairs(sides) do
		if dist < sides[closestSide] then
			closestSide = side
		end
	end

	if closestSide == "Left" then
		return UDim2.new(-size.X.Scale - 0.1, 0, pos.Y.Scale, 0)
	elseif closestSide == "Right" then
		return UDim2.new(1 + size.X.Scale + 0.1, 0, pos.Y.Scale, 0)
	elseif closestSide == "Top" then
		return UDim2.new(pos.X.Scale, 0, -size.Y.Scale - 0.1, 0)
	elseif closestSide == "Bottom" then
		return UDim2.new(pos.X.Scale, 0, 1 + size.Y.Scale + 0.1, 0)
	end
end

function GuiController:CacheOriginalPositions()
	for _, frame in pairs(CollectionService:GetTagged("ScreenFrames")) do
		if not self.OriginalPositions[frame] then
			self.OriginalPositions[frame] = frame.Position
		end
	end
end

function GuiController:OpenScreenFrames()
	self:CacheOriginalPositions()
	for _, frame in pairs(CollectionService:GetTagged("ScreenFrames")) do
		local tween = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Cubic,Enum.EasingDirection.Out), {Position = self.OriginalPositions[frame]})
		tween:Play()
	end
end

function GuiController:CloseScreenFrames()
	self:CacheOriginalPositions()
	for _, frame in pairs(CollectionService:GetTagged("ScreenFrames")) do
		local offscreenPos = self:GetOffscreenPosition(frame)
		local tween = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Cubic,Enum.EasingDirection.Out), {Position = offscreenPos})
		tween:Play()
	end
end

--Misc--
function GuiController:UpdateCash(New, Old)
	if not New or not Old then return end

	local TextLabel = CurrencyFrame.moneycount
	local UIScale = TextLabel:FindFirstChild("UIScale") or Instance.new("UIScale", TextLabel)

	local function PopText(isFinal)
		UIScale.Scale = 1.2 
		local popInfo = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		TweenService:Create(UIScale, popInfo, {Scale = 1}):Play()

		local originalColor = Color3.fromRGB(0, 255, 0)
		local flashColor = Color3.fromRGB(73, 144, 6)

		TextLabel.TextColor3 = flashColor
		task.delay(0.1, function()
			TweenService:Create(TextLabel, TweenInfo.new(0.2), {TextColor3 = originalColor}):Play()
		end)
	end

	if New - Old > 0 then
		local rootPart = self.CharacterController.RootPart
		if not rootPart then return end

		task.spawn(function()
			local orbs = {}
			local totalIncrease = New - Old

			for i = 1, math.random(10, 17) do
				local CloneOrb = Assets.Models.Orb:Clone()
				table.insert(orbs, CloneOrb)
				CloneOrb.CanCollide = false
				CloneOrb.Parent = workspace.Debris
				CloneOrb.CFrame = (rootPart.CFrame * CFrame.Angles(0, math.rad(math.random(0, 360)), 0)) * CFrame.new(math.random(-2, 2), 0, math.random(-2, 2))

				CloneOrb:ApplyImpulse(Vector3.new(RNG:NextNumber(-10, 10), 20, RNG:NextNumber(-10, 10)))
				task.wait(0.02)
				CloneOrb.CanCollide = true
			end

			task.wait(0.9)
			local orbCount = #orbs
			local collectedCount = 0
			local amountPerOrb = totalIncrease / orbCount

			for _, orb in pairs(orbs) do
				if not orb or not orb.Parent then 
					collectedCount += 1 
					continue 
				end

				task.spawn(function()
					orb.CanCollide = false
					orb.Anchored = true

					local startPos = orb.Position
					local midPoint = (startPos + rootPart.Position) / 2
					local controlPoint = midPoint + Vector3.new(RNG:NextNumber(-15, 15), RNG:NextNumber(10, 20), RNG:NextNumber(-15, 15))

					local flyTween = TweenComponent.new(
						0.6, 
						function(alpha) 
							if not orb or not orb.Parent or not rootPart or not rootPart.Parent then return end

							local currentTarget = rootPart.Position
							local newPos = Easing.QuadraticBezier(alpha, startPos, controlPoint, currentTarget)
							orb.CFrame = CFrame.new(newPos, currentTarget)
						end,
						Easing.circOut
					)

					flyTween.Completed:Connect(function()
						flyTween:Destroy()
						if orb then orb:Destroy() end

						collectedCount += 1

						if collectedCount >= orbCount then
							TextLabel.Text = tostring(math.floor(New))
							PopText(true)
						else
							local currentDisplayValue = Old + (amountPerOrb * collectedCount)
							TextLabel.Text = tostring(math.floor(currentDisplayValue))
							PopText(false)
						end
					end)

					flyTween:Play()
				end)

				task.wait(0.03)
			end
		end)
	else
		TextLabel.Text = tostring(New)
		PopText(true)
	end
end
--Misc--

function GuiController:Init() 
    for _,Frame in pairs(CollectionService:GetTagged("SideButtons")) do
        if Frame:IsDescendantOf(StarterGui) then
            Frame:RemoveTag("SideButtons")
        end
    end
    task.spawn(function()
        self:InitSideButtons()
    end)
    for _, Button in pairs(CollectionService:GetTagged("SideButtons","Buttons")) do
        if Button:IsA("GuiObject") then
            Button:SetAttribute("OriginalPos", Button.Position)
        end
    end

    self.ProfileController:Get("Cash"):andThen(function(cash)
        CurrencyFrame.moneycount.Text = cash
    end)

    self.ProfileController:Observe("Cash",function(...)
        self:UpdateCash(...)
    end)

    RunService.RenderStepped:Connect(function(dt)
        for _,Effect in pairs(self.GlowEffects) do
            Effect.Rotation += dt * self.GradientSpeed
        end
    end)
    warn("Well i mean the gui controller initialized")
 end

function GuiController:KnitInit()
    self.InputController = Knit.GetController("InputController")
    self.CharacterController = Knit.GetController("CharacterController")
    self.ProfileController = Knit.GetController("ProfileController")

    self.GradientSpeed = 20
    self.CanUseButtons = true
    
    self.CurrentFrame = nil
    self.FrameComponents = {}
    self.OriginalPositions = {}
    self.ButtonClasses = {}
    self.GlowEffects = {}

    task.spawn(function()
        if not RunService:IsStudio() then
			repeat
				local success = pcall(function()
					StarterGui:SetCore("ResetButtonCallback", false)
				end)
				task.wait(1)
			until success
			print("SUCCESS | Reset button core GUI disabled!")
        end
    end)
end

function GuiController:KnitStart()
    local attempts = 0
    while not self.ProfileController:IsLoaded() do
        task.wait(0.5)
        attempts += 1
        if attempts > 20 then
            warn("ProfileController took too long to load! forcing "..script.Name.." initialization.")
            break
        end
    end
    self:Init()
    --[[
    local skybox = Lighting:FindFirstChildWhichIsA("Sky")
    if skybox then 
        RunService.RenderStepped:Connect(function()
            skybox.SkyboxOrientation = Vector3.new(tick() * 10 % 360, tick() * 10 % 360, tick() * 10 % 360)
        end)
    end
    ]]
end

return GuiController
