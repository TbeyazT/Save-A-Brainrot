--made by @Kebondy
local PointerModule = {}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

PointerModule.conf = {
    TweenTime = 0.25,
    TweenStyle = Enum.EasingStyle.Quint,
    TweenDirection = Enum.EasingDirection.Out,
    DefaultSize = UDim2.new(5, 0, 5, 0),
    DefaultPosition = UDim2.new(0, 0, 0, 0),
    DefaultRotation = 0
}

local pointerGUI = script.ScreenPointer:Clone()
pointerGUI.Parent = player.PlayerGui
local pointerFrame = pointerGUI.Frame

local currentTarget = nil
local currentTween = nil
local connections = {}

local function calculateLocalPosition(parent, targetPos, targetSize, anchor)
    local parentAbsPos = parent.AbsolutePosition
    return UDim2.new(
        0, targetPos.X - parentAbsPos.X - anchor.X * targetSize.X,
        0, targetPos.Y - parentAbsPos.Y - anchor.Y * targetSize.Y
    )
end

local function shortestRotation(current, target)
    local diff = (target - current) % 360
    if diff > 180 then
        diff = diff - 360
    end
    return current + diff
end

local function updatePointer()
    local goal = {}

    if currentTarget then
        local targetPos = currentTarget.AbsolutePosition
        local targetSize = currentTarget.AbsoluteSize
        local targetRot = currentTarget.AbsoluteRotation
        local parent = pointerFrame.Parent

        goal = {
            Position = calculateLocalPosition(parent, targetPos, targetSize, pointerFrame.AnchorPoint),
            Size = UDim2.new(0, targetSize.X, 0, targetSize.Y),
            Rotation = shortestRotation(pointerFrame.Rotation, targetRot)
        }
    else
        goal = {
            Position = PointerModule.conf.DefaultPosition,
            Size = PointerModule.conf.DefaultSize,
            Rotation = math.floor((pointerFrame.Rotation / 180) + 0.5) * 180
        }
    end

    local tweenInfo = TweenInfo.new(
        PointerModule.conf.TweenTime,
        PointerModule.conf.TweenStyle,
        PointerModule.conf.TweenDirection
    )

    if currentTween then
        currentTween:Cancel()
    end

    currentTween = TweenService:Create(pointerFrame, tweenInfo, goal)
    currentTween:Play()
end

local function clearConnections()
    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end
    connections = {}
end

local function connectTargetSignals(target)
    clearConnections()
    if not target then return end

    table.insert(connections, target:GetPropertyChangedSignal("AbsolutePosition"):Connect(updatePointer))
    table.insert(connections, target:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePointer))
    table.insert(connections, target:GetPropertyChangedSignal("AbsoluteRotation"):Connect(updatePointer))

    if pointerFrame.Parent then
        table.insert(connections, pointerFrame.Parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePointer))
    end
end

function PointerModule:MoveIt(frame)
    currentTarget = frame
    updatePointer()
    connectTargetSignals(frame)
end

return PointerModule