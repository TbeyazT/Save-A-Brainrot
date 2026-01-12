-- StarterPlayerScripts/StoreStarsClient
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local CFG = {
	DEBUG = false,          -- true yaparsan hangi index gidiyor/geliyor Output'a yazar

	TransitionTime = 0.55,  -- giden+gelen gecis suresi
	HoldTime = 0.35,        -- gecis bitti, biraz bekle (0 yaparsan surekli degisir)

	RotateSpeedIn = 220,    -- deg/sn (gelen)
	RotateSpeedOut = 260,   -- deg/sn (giden) biraz daha hizli

	MovePixels = 4,         -- gidip gelme miktari (0 yaparsan hareket kapali)
	VisibleAlpha = 1.0,     -- 1.0 tam gorunur (istersen 0.9 yap)
}

local activeCleanup

local function findStoreButton(playerGui: PlayerGui)
	-- Once bilinen path
	local mainGui = playerGui:FindFirstChild("MainGui")
	if mainGui then
		local buttons = mainGui:FindFirstChild("buttons")
		if buttons then
			local store = buttons:FindFirstChild("store")
			if store and store:IsA("ImageButton") then
				return store
			end
		end
	end

	-- Path degismisse: descendant tara
	for _, d in ipairs(playerGui:GetDescendants()) do
		if d:IsA("ImageButton") and d.Name == "store" then
			return d
		end
	end
	return nil
end

local function collectStarsSorted(storeButton: Instance)
	local stars = {}
	for _, d in ipairs(storeButton:GetDescendants()) do
		if d:IsA("ImageLabel") and d.Name == "stars" then
			table.insert(stars, d)
		end
	end

	-- Stabil siralama: pozisyona gore (boylece "2 mi 3 mu" karismaz)
	table.sort(stars, function(a, b)
		local ap, bp = a.Position, b.Position
		if ap.X.Scale ~= bp.X.Scale then return ap.X.Scale < bp.X.Scale end
		if ap.X.Offset ~= bp.X.Offset then return ap.X.Offset < bp.X.Offset end
		if ap.Y.Scale ~= bp.Y.Scale then return ap.Y.Scale < bp.Y.Scale end
		return ap.Y.Offset < bp.Y.Offset
	end)

	return stars
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function smoothstep(t)
	-- 0..1 arasi daha dogal easing
	return t * t * (3 - 2 * t)
end

local function startStars(storeButton: ImageButton)
	local stars = collectStarsSorted(storeButton)
	if #stars < 2 then
		if CFG.DEBUG then
			warn("StoreStarsClient: stars 2'den az bulundu.")
		end
		return function() end
	end

	local running = true

	-- Orijinalleri sakla
	local originals = {}
	for i, s in ipairs(stars) do
		originals[s] = {
			Pos = s.Position,
			Rot = s.Rotation,
			Trans = s.ImageTransparency,
			Vis = s.Visible,
		}
		s.Visible = true
		s.ImageTransparency = 1
	end

	-- Baslangic: 1 gorunsun
	local current = 1
	local nextIdx = (current % #stars) + 1

	local phase = "hold"
	local timer = 0

	-- Aktif iki star (giden + gelen)
	local outIdx = current
	local inIdx = nextIdx

	-- Donme hizlari (aktif olana uygulanacak)
	local outRot = stars[outIdx].Rotation
	local inRot = stars[inIdx].Rotation

	-- Helper: log
	local function dbg(...)
		if CFG.DEBUG then
			print("[StoreStarsClient]", ...)
		end
	end

	-- Ilk gorunum
	stars[current].ImageTransparency = 1 - CFG.VisibleAlpha

	-- Render loop: surekli donme + crossfade
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		if not running then return end
		if not storeButton or not storeButton.Parent then return end

		-- dt spike yumusat
		if dt > 1/20 then dt = 1/20 end

		timer += dt

		-- State machine
		if phase == "hold" then
			-- Bu fazda sadece current gorunur
			local curStar = stars[current]
			for i, s in ipairs(stars) do
				if i == current then
					s.ImageTransparency = 1 - CFG.VisibleAlpha
					s.Position = originals[s].Pos
				else
					s.ImageTransparency = 1
					s.Position = originals[s].Pos
				end
			end

			-- current donsun (istersen kapatabilirsin)
			curStar.Rotation = curStar.Rotation + (CFG.RotateSpeedIn * dt)

			if timer >= CFG.HoldTime then
				timer = 0
				phase = "transition"

				outIdx = current
				inIdx = (current % #stars) + 1

				outRot = stars[outIdx].Rotation
				inRot = stars[inIdx].Rotation

				dbg("OUT index:", outIdx, "IN index:", inIdx)
			end

		elseif phase == "transition" then
			local t = math.clamp(timer / CFG.TransitionTime, 0, 1)
			local e = smoothstep(t)

			local outStar = stars[outIdx]
			local inStar = stars[inIdx]

			-- Alpha: out azalir, in artar
			local outAlpha = lerp(CFG.VisibleAlpha, 0, e)
			local inAlpha = lerp(0, CFG.VisibleAlpha, e)

			outStar.ImageTransparency = 1 - outAlpha
			inStar.ImageTransparency = 1 - inAlpha

			-- Digerleri tamamen kapali
			for i, s in ipairs(stars) do
				if i ~= outIdx and i ~= inIdx then
					s.ImageTransparency = 1
					s.Position = originals[s].Pos
				end
			end

			-- Move: out yukari dogru kayarak gitsin, in asagidan gelip yerine otursun
			local move = CFG.MovePixels
			if move ~= 0 then
				local outPos = originals[outStar].Pos + UDim2.new(0, 0, 0, -move * e)
				local inPos = originals[inStar].Pos + UDim2.new(0, 0, 0, move * (1 - e))
				outStar.Position = outPos
				inStar.Position = inPos
			else
				outStar.Position = originals[outStar].Pos
				inStar.Position = originals[inStar].Pos
			end

			-- Surekli donme: ikisi de gecis boyunca doner
			outRot += (CFG.RotateSpeedOut * dt)
			inRot += (CFG.RotateSpeedIn * dt)
			outStar.Rotation = outRot
			inStar.Rotation = inRot

			if t >= 1 then
				-- Gecis bitti: in -> current olur
				timer = 0
				phase = "hold"
				current = inIdx

				-- Out'u resetle
				outStar.ImageTransparency = 1
				outStar.Position = originals[outStar].Pos
			end
		end
	end)

	return function()
		running = false
		if conn then
			pcall(function() conn:Disconnect() end)
		end

		-- Restore
		for s, data in pairs(originals) do
			if s and s.Parent then
				pcall(function()
					s.Position = data.Pos
					s.Rotation = data.Rot
					s.ImageTransparency = data.Trans
					s.Visible = data.Vis
				end)
			end
		end
	end
end

local function bind()
	if activeCleanup then
		activeCleanup()
		activeCleanup = nil
	end

	local playerGui = player:WaitForChild("PlayerGui")

	-- Store gelene kadar bekle
	local store
	for _ = 1, 600 do
		store = findStoreButton(playerGui)
		if store then break end
		task.wait(0.05)
	end
	if not store then
		warn("StoreStarsClient: store bulunamadi.")
		return
	end

	-- Stars gelene kadar bekle
	for _ = 1, 600 do
		local stars = collectStarsSorted(store)
		if #stars >= 2 then break end
		task.wait(0.05)
	end

	activeCleanup = startStars(store)

	store.AncestryChanged:Connect(function(_, parent)
		if parent == nil and activeCleanup then
			activeCleanup()
			activeCleanup = nil
		end
	end)
end

local function boot()
	local playerGui = player:WaitForChild("PlayerGui")
	task.defer(bind)

	playerGui.DescendantAdded:Connect(function(inst)
		if inst:IsA("ImageButton") and inst.Name == "store" then
			task.defer(bind)
		elseif inst:IsA("ImageLabel") and inst.Name == "stars" then
			task.defer(bind)
		end
	end)
end

boot()