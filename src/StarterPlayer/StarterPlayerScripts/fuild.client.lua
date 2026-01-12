--!native
--!optimize 2
--!strict
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- // CONFIGURATION //
local COLS: number = 70          -- Increased resolution slightly due to optimization
local ROWS: number = 70 
local PART_SIZE: number = 1
local DAMPING: number = 0.985
local THRESHOLD: number = 0.005  -- Minimum movement to trigger a visual update

-- // VARIABLES //
local totalCells = COLS * ROWS
local buffer1 = table.create(totalCells, 0)
local buffer2 = table.create(totalCells, 0)
local visualParts = table.create(totalCells)

-- Pre-calculated coordinates to save math in the loop
local xCoords = table.create(totalCells, 0)
local zCoords = table.create(totalCells, 0)

-- Reusable tables for BulkMoveTo (prevents memory leaks)
local dirtyParts = table.create(totalCells)
local dirtyCFrames = table.create(totalCells)

local container = Instance.new("Folder")
container.Name = "FluidSim_Optimized"
container.Parent = workspace

local origin = Vector3.new(0, 5, 0)
local originY = origin.Y

-- // SETUP //
local template = Instance.new("Part")
template.Size = Vector3.new(PART_SIZE, PART_SIZE, PART_SIZE)
template.Anchored = true
template.CanCollide = false
template.TopSurface = Enum.SurfaceType.Smooth
template.Material = Enum.Material.Glass
template.Color = Color3.fromRGB(0, 110, 200)
template.Transparency = 0.2
template.CastShadow = false -- Shadows are expensive, turn off

print("Generating Grid...")

for z = 0, ROWS - 1 do
    for x = 0, COLS - 1 do
        local i = (z * COLS) + x + 1
        local part = template:Clone()
        
        local posX = origin.X + (x * PART_SIZE)
        local posZ = origin.Z + (z * PART_SIZE)
        
        part.Position = Vector3.new(posX, originY, posZ)
        part.Parent = container
        
        visualParts[i] = part
        
        -- Cache coordinates for the loop
        xCoords[i] = posX
        zCoords[i] = posZ
    end
end
template:Destroy()

-- // UTILITY //
local function getIndex(x: number, z: number): number?
    if x < 0 or x >= COLS or z < 0 or z >= ROWS then return nil end
    return (z * COLS) + x + 1
end

local function splash(x: number, z: number, strength: number)
    local index = getIndex(x, z)
    if index then
        buffer1[index] = -strength
    end
end

-- // INTERACTION //
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = {container}

local function interact()
    -- Mouse Interaction
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        local mouseLoc = UserInputService:GetMouseLocation()
        local ray = workspace.CurrentCamera:ViewportPointToRay(mouseLoc.X, mouseLoc.Y)
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, rayParams)
        
        if result then
            local relative = result.Position - origin
            local gridX = math.floor((relative.X / PART_SIZE) + 0.5)
            local gridZ = math.floor((relative.Z / PART_SIZE) + 0.5)
            splash(gridX, gridZ, 10)
        end
    end
    
    -- Character Interaction
    local char = Players.LocalPlayer.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart") :: BasePart
        if root then
            local pos = root.Position
            if math.abs(pos.Y - originY) < 3 then
                local vel = root.AssemblyLinearVelocity
                if vel.Magnitude > 2 then
                    local gridX = math.floor(((pos.X - origin.X) / PART_SIZE) + 0.5)
                    local gridZ = math.floor(((pos.Z - origin.Z) / PART_SIZE) + 0.5)
                    splash(gridX, gridZ, math.clamp(vel.Magnitude * 0.5, 1, 10))
                end
            end
        end
    end
end

-- // MAIN LOOP //
-- Localize math functions for speed
local math_abs = math.abs
local cf_new = CFrame.new

RunService.RenderStepped:Connect(function()
    interact()
    
    -- Clear dirty lists (Reuse capacity to avoid allocation)
    table.clear(dirtyParts)
    table.clear(dirtyCFrames)
    local dirtyCount = 0

    -- Inner Loop Optimized
    for z = 1, ROWS - 2 do
        -- Pre-calculate row offset
        local rowOffset = (z * COLS)
        
        for x = 1, COLS - 2 do
            local i = rowOffset + x + 1
            
            -- Neighbor averaging
            local val = (
                buffer1[i - 1] + 
                buffer1[i + 1] + 
                buffer1[i - COLS] + 
                buffer1[i + COLS]
            ) * 0.5 - buffer2[i]
            
            val = val * DAMPING
            buffer2[i] = val
            
            -- OPTIMIZATION: "Sleeping"
            -- Only update CFrame if the water has moved significantly OR if it was previously moving
            -- We check a threshold to stop jittering at 0.00001 height
            if math_abs(val) > THRESHOLD then
                dirtyCount += 1
                dirtyParts[dirtyCount] = visualParts[i]
                -- Using cached X/Z coordinates prevents Vector3 creation
                dirtyCFrames[dirtyCount] = cf_new(xCoords[i], originY + val, zCoords[i])
            elseif math_abs(buffer1[i]) > THRESHOLD then
                -- It just settled this frame, force it back to EXACT 0 one last time
                dirtyCount += 1
                dirtyParts[dirtyCount] = visualParts[i]
                dirtyCFrames[dirtyCount] = cf_new(xCoords[i], originY, zCoords[i])
            end
        end
    end

    -- Only send the modified parts to the physics engine
    if dirtyCount > 0 then
        workspace:BulkMoveTo(dirtyParts, dirtyCFrames, Enum.BulkMoveMode.FireCFrameChanged)
    end

    -- Swap Buffers
    local temp = buffer1
    buffer1 = buffer2
    buffer2 = temp
end)