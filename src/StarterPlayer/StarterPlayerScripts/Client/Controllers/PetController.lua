local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local TweenComponent = require(Assets.Components.TweenComponent)
local LabelComponent = require(Assets.Components.LabelComponent)

local Knit = require(Packages.Knit)
local Easing = require(Assets.Modules.Easing)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local MainGui = PlayerGui:WaitForChild("MainGui")

local TopNotifications = MainGui.TopNotifications
local TempText = TopNotifications.Template

local Camera = workspace.CurrentCamera

local PetController = Knit.CreateController {
	Name = script.Name
}

local PET_SMOOTHNESS = 0.1 
local HOVER_HEIGHT = 1 
local HOVER_BOUNCE = 0.5 
local BOUNCE_SPEED = 4 
local DISTANCE_BEHIND = 4
local SPACING = 3 

local ActivePets = {} -- Stores {Model = model, Data = petData}
local PetContainer = nil 

function PetController:GetPetModel(PetName)
	local Module = Assets.PetProperties:FindFirstChild(PetName)
	if Module then
		local Model = Module:FindFirstChildWhichIsA("Model")
		if Model then
			return Model:Clone()
		end
	end
	warn("Could not find model for: " .. PetName)
	return nil
end

function PetController:SpawnPet(PetData)
	local Model = self:GetPetModel(PetData.Name)
	if not Model then return end

	Model.Name = PetData.ID

	for _, part in pairs(Model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Anchored = true
			part.CastShadow = false
		end
	end

	Model.Parent = PetContainer

	table.insert(ActivePets, {
		Model = Model,
		Data = PetData
	})
end

function PetController:ClearPets()
	for _, petInfo in pairs(ActivePets) do
		if petInfo.Model then
			petInfo.Model:Destroy()
		end
	end
	ActivePets = {}
end

function PetController:MovePets(dt)
	local Character = LocalPlayer.Character
	if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end

	local RootPart = Character.HumanoidRootPart
	local TotalPets = #ActivePets

	local Time = time()
	local BobbleY = math.sin(Time * BOUNCE_SPEED) * HOVER_BOUNCE

	for index, petInfo in ipairs(ActivePets) do
		local Model = petInfo.Model
		if Model and Model.PrimaryPart then

			local OffsetX = (index - (TotalPets + 1) / 2) * SPACING

			local TargetCFrame = RootPart.CFrame 
				* CFrame.new(OffsetX, HOVER_HEIGHT + BobbleY, DISTANCE_BEHIND)

			local NewCFrame = Model.PrimaryPart.CFrame:Lerp(TargetCFrame, PET_SMOOTHNESS)

			Model:SetPrimaryPartCFrame(NewCFrame)
		end
	end
end

function PetController:SpawnEgg(Name, Amount)
	self.PetService:OpenEgg(Name, Amount):andThen(function(Result)
		for i = 1, #Result do
			local Opened = false
			local WonPetName = Result[i] 

			task.spawn(function()
				local Template = Assets.Models.Eggs:FindFirstChild(Name)
				if Template then
					local Egg: Model = Template:Clone()
					local BehindCamera: BasePart = Assets.Models.BehindEgg:Clone()
					local lightAttachment = Instance.new("Attachment")
					lightAttachment.Parent = workspace.Terrain
					local Light = Instance.new("PointLight")
					Light.Brightness = 1.54
					Light.Range = 15
					Light.Parent = lightAttachment

					local oldScale = Egg:GetScale()
					Egg:ScaleTo(0.01)

					local idleSpeed, idleIntensity, returnSpeed = 2.5, 8, 0.08
					local shakePower, clickScaleBoost, isOpening = 0, 1, false

					local firstTween = TweenComponent.new(1.2, function(alpha)
						local wobbleZ = math.sin(os.clock() * idleSpeed) * math.rad(idleIntensity)
						Egg:PivotTo(Camera.CFrame * CFrame.new(0, 0, -6) * CFrame.Angles(0, 0, wobbleZ))
						BehindCamera:PivotTo(Camera.CFrame * CFrame.new(0, 0, -12))
						lightAttachment.WorldCFrame = Camera.CFrame * CFrame.new(0, 0, -5)
						Egg:ScaleTo(oldScale * alpha)
					end, Easing.backOut)

					Egg.Parent = Camera
					BehindCamera.Parent = Camera
					firstTween:Play()
					firstTween.Completed:Wait()

					local connection: RBXScriptConnection
					local clickConnection: RBXScriptConnection
					local clickCount = 0

					connection = RunService.RenderStepped:Connect(function(dt)
						shakePower = math.lerp(shakePower, 0, returnSpeed)
						clickScaleBoost = math.lerp(clickScaleBoost, 1, returnSpeed)
						local xOffset = math.sin(os.clock() * 45) * 0.4 * shakePower
						local zRotationShake = math.cos(os.clock() * 40) * math.rad(15) * shakePower
						local idleWobble = math.sin(os.clock() * idleSpeed) * math.rad(idleIntensity)
						Egg:PivotTo(Camera.CFrame * CFrame.new(xOffset, 0, -6) * CFrame.Angles(0, 0, idleWobble + zRotationShake))
						Egg:ScaleTo(oldScale * clickScaleBoost)
						BehindCamera:PivotTo(Camera.CFrame * CFrame.new(0, 0, -12))
						lightAttachment.WorldCFrame = Camera.CFrame * CFrame.new(0, 0, -5)
					end)

					clickConnection = self.InputController.OnClick:Connect(function()
						if isOpening then return end
						clickCount += 1
						shakePower, clickScaleBoost = 1, 1.2

						if clickCount >= 3 then
							isOpening = true
							connection:Disconnect()
							clickConnection:Disconnect()

							local openTween = TweenComponent.new(0.8, function(alpha)
								local currentSpeed = idleSpeed + (alpha * 45)
								local currentIntensity = idleIntensity + (alpha * 20)
								local wobbleZ = math.sin(os.clock() * currentSpeed) * math.rad(currentIntensity)
								Egg:PivotTo(Camera.CFrame * CFrame.new(0, 0, -6) * CFrame.Angles(0, 0, wobbleZ))
								Egg:ScaleTo(oldScale * (1 + (0.4 * alpha)))
								BehindCamera:PivotTo(Camera.CFrame * CFrame.new(0, 0, -12))
								Light.Brightness = 1.54 + (15 * alpha)
								Light.Range = 15 + (25 * alpha)
								lightAttachment.WorldCFrame = Camera.CFrame * CFrame.new(0, 0, -5)
							end, Easing.linear)
							openTween:Play()
							openTween.Completed:Wait()

							local burstTween = TweenComponent.new(0.15, function(alpha)
								Egg:ScaleTo(math.max(0.01, (oldScale * 1.4) * (1 - alpha)))
								lightAttachment.WorldCFrame = Camera.CFrame * CFrame.new(0, 0, -5)
								Light.Brightness = 16 * (1 - alpha)
							end, Easing.quadIn)
							burstTween:Play()
							burstTween.Completed:Wait()

							Egg:Destroy()

							local PetModel = self:GetPetModel(WonPetName)
							if PetModel then
								PetModel = PetModel:Clone()
								for _,Part in pairs(PetModel:GetDescendants()) do
									if Part:IsA("BasePart") then
										Part.CanCollide = false
										Part.Anchored = true
									end
								end
								PetModel.Parent = Camera
								local petOldScale = PetModel:GetScale()
								PetModel:ScaleTo(0.01)

								Light.Brightness = 3
								Light.Range = 15

								local class = LabelComponent.new(TempText)

								class:SetText(`You got an "`..WonPetName..`"`)
								class:InvisibleLetters()

								task.spawn(function()
									for _,letterData in pairs(class:GetLetters()) do
										local letter = letterData.Label
										if letter then
											letter.TextStrokeTransparency = 0.3
											TweenService:Create(letter,TweenInfo.new(0.2,Enum.EasingStyle.Circular,Enum.EasingDirection.Out),{
												TextTransparency = 0
											}):Play()
											task.wait(0.05)
										end
									end
								end)

								local PetLetters = class:GetKeywordLetters(WonPetName)

								local petTween = TweenComponent.new(0.8, function(alpha)
									local rotation = CFrame.Angles(0, math.rad(alpha * 360), 0)
									PetModel:PivotTo(Camera.CFrame * CFrame.new(0, 0, -6) * rotation)
									BehindCamera:PivotTo(Camera.CFrame * CFrame.new(0, 0, -12))
									PetModel:ScaleTo(math.max(0.01, petOldScale * alpha))
									lightAttachment.WorldCFrame = Camera.CFrame * CFrame.new(0, 0, -5)
								end, Easing.backOut)

								petTween:Play()
								petTween.Completed:Wait()

								local canProceed = false
								local tempConnection
								tempConnection = self.InputController.OnClick:Connect(function()
									canProceed = true
									tempConnection:Disconnect()
								end)

								local waitStartTime = os.clock()

								-- Define wave settings
								-- Define Gradient and Rotation settings
								local COLOR_SPEED = 0.3      -- How fast colors change
								local COLOR_SPREAD = 0.05    -- How much the colors "spread" across letters
								local ROTATION_SPEED = 1    -- How fast letters tilt
								local ROTATION_ANGLE = 12    -- Max degrees to tilt left/right
								local ROT_OFFSET = 0.5       -- Timing offset between letters

								local con
								con = RunService.RenderStepped:Connect(function(dt)
									local currentTime = os.clock()
									local timeDelta = currentTime - waitStartTime

									local bob = math.sin(currentTime * 2) * 0.2
									PetModel:PivotTo(Camera.CFrame * CFrame.new(0, bob, -6) * CFrame.Angles(0, math.rad(timeDelta * 20), 0))
									BehindCamera:PivotTo(Camera.CFrame * CFrame.new(0, 0, -12))
									lightAttachment.WorldCFrame = Camera.CFrame * CFrame.new(0, 0, -5)

									if PetLetters then
										for index, letterData in ipairs(PetLetters) do
											local label = letterData.Label
											if label then
												local hue = (currentTime * COLOR_SPEED + index * COLOR_SPREAD) % 1
												label.TextColor3 = Color3.fromHSV(hue, 0.7, 1)

												local targetRotation = math.sin((currentTime * ROTATION_SPEED) + (index * ROT_OFFSET)) * ROTATION_ANGLE

												label.Rotation = math.lerp(label.Rotation, targetRotation, dt * 10)
											end
										end
									end

									if canProceed and con then
										con:Disconnect()
										con = nil
									end
								end)

								repeat task.wait(0.1) until canProceed

								local fadePet = TweenComponent.new(0.4, function(alpha)
									local a = petOldScale * (1 - alpha)
									PetModel:ScaleTo(math.max(0.01, a))
									Light.Brightness = 3 * (1 - alpha)

									local timeDelta = os.clock() - waitStartTime
									local bob = math.sin(os.clock() * 2) * 0.2
									PetModel:PivotTo(Camera.CFrame * CFrame.new(0, bob, -6) * CFrame.Angles(0, math.rad(timeDelta * 20), 0))
									BehindCamera:PivotTo(Camera.CFrame * CFrame.new(0, 0, -12))
									lightAttachment.WorldCFrame = Camera.CFrame * CFrame.new(0, 0, -5)

									for _, letterData in pairs(class:GetLetters()) do
										local letter = letterData.Label
										if letter then
											letter.TextTransparency = alpha
											letter.TextStrokeTransparency = 0.3 + (0.7 * alpha)

											if not letterData.FadeOriginY then
												letterData.FadeOriginY = letter.Position.Y.Scale
											end
											letter.Position = UDim2.new(
												letter.Position.X.Scale, 
												letter.Position.X.Offset, 
												letterData.FadeOriginY + (0.05 * alpha),
												letter.Position.Y.Offset
											)
										end
									end
								end, Easing.quadIn)

								fadePet:Play()
								fadePet.Completed:Wait()

								PetModel:Destroy()
								class:Destroy()
							end

							BehindCamera:Destroy()
							lightAttachment:Destroy()
							Opened = true
						end
					end)
				end
			end)
			repeat task.wait(0.1) until Opened
		end
	end)
end

function PetController:KnitInit()
	self.PetService = Knit.GetService("PetService")
	self.ProfileController = Knit.GetController("ProfileController")
	self.InputController = Knit.GetController("InputController")
end

function PetController:KnitStart()
	PetContainer = Instance.new("Folder")
	PetContainer.Name = "LocalPets"
	PetContainer.Parent = Workspace

	local function UpdatePets()
		self:ClearPets()

		self.ProfileController:Get("Pets"):andThen(function(Pets)
			for _, petData in pairs(Pets) do
				if petData.Equipped then
					self:SpawnPet(petData)
				end
			end
		end)
	end

	self.ProfileController:Observe("Pets",function(pets,old)
		UpdatePets()
	end)

	UpdatePets()

	RunService.RenderStepped:Connect(function(dt)
		self:MovePets(dt)
	end)

	task.wait(3)
end

return PetController