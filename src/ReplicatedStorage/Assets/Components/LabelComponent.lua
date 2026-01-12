--[[
	// FileName: RichTextComponent.lua
	// Description: Converts TextLabel into Word Frames containing Letter Labels.
	// Fixes: Uses Cumulative Measurement for 100% accurate wrapping and positioning.
	@TbeyazT 2026
--]]

local ReplicatedStorage 	= game:GetService("ReplicatedStorage")
local TextService			= game:GetService("TextService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Signal = require(Packages.Signal) 

local RichTextComponent = {}
RichTextComponent.__index = RichTextComponent

--// Types
export type Letter = { Char: string, Label: TextLabel, Index: number }
export type WordObject = { WordString: string, Frame: Frame, Letters: { Letter }, Index: number }

--// Helper: Calculate the exact Font Size to fit the frame
local function calculateBestFontSize(text: string, font: Enum.Font, frameSize: Vector2, template: TextLabel): number
	if not template.TextScaled then
		return template.TextSize
	end

	local minSize = 1
	local maxSize = 100 
	local bestSize = minSize
	
	-- We create a huge vector for Y to strictly test X, and vice versa
	local layoutConstraint = Vector2.new(frameSize.X, 10000)
	
	while minSize <= maxSize do
		local mid = math.floor((minSize + maxSize) / 2)
		local bounds = TextService:GetTextSize(text, mid, font, layoutConstraint)
		
		-- STRICT check: Must fit X and Y exactly. No tolerance multipliers.
		if bounds.X <= frameSize.X and bounds.Y <= frameSize.Y then
			bestSize = mid
			minSize = mid + 1
		else
			maxSize = mid - 1
		end
	end
	
	return bestSize
end

function RichTextComponent.new(template: TextLabel)
	local self = setmetatable({}, RichTextComponent)

	local frame = Instance.new("Frame")
	frame.Name = template.Name .. "_RichContainer"
	frame.Size = template.Size
	frame.Position = template.Position
	frame.AnchorPoint = template.AnchorPoint
	frame.BackgroundTransparency = 1
	frame.ZIndex = template.ZIndex
	frame.ClipsDescendants = template.ClipsDescendants -- Important for slight overflows
	frame.Parent = template.Parent

	self.Frame = frame
	self.Text = ""
	self.Font = template.Font
	self.TextColor3 = template.TextColor3
	self.TextXAlignment = template.TextXAlignment
	self.TextYAlignment = template.TextYAlignment
	self.Changed = Signal.new()
	
	self.Words = {}
	self.Letters = {}
	self._Template = template
	self._UpdateDebounce = false

	template.BackgroundTransparency = 1
	template.TextTransparency = 1 
	local stroke = template:FindFirstChildWhichIsA("UIStroke")
	if stroke then stroke.Enabled = false end

	self.TextSize = template.TextSize

	frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:UpdateScale() end)
	
	return self
end

function RichTextComponent:SetText(text: string)
	self:Clear()
	self.Text = text
	self._Template.Text = text

	local frameSize = self.Frame.AbsoluteSize
	if frameSize.X <= 1 or frameSize.Y <= 1 then return end

	-- 1. CALCULATE EXACT SIZE
	self.TextSize = calculateBestFontSize(text, self.Font, frameSize, self._Template)
	self.LineHeight = self.TextSize * 1.0 -- Tight fit like native Roblox
	
	-- 2. Tokenize (Word by Word)
	local words = {}
	for word in text:gmatch("%S+") do
		table.insert(words, word)
	end
	
	-- We need to preserve manual newlines logic, so we split by newlines first
	local rawLines = text:split("\n")
	
	-- 3. Logical Layout (Cumulative Measurement)
	local lines = {}
	local bigVector = Vector2.new(math.huge, math.huge)
	
	for _, rawLineStr in ipairs(rawLines) do
		-- If line is empty (double newline), just add an empty placeholder
		if rawLineStr == "" then
			table.insert(lines, { Width = 0, Tokens = {} })
			continue
		end

		local currentLine = { Width = 0, Tokens = {} }
		local currentLineString = ""
		
		-- Extract tokens (Words and Spaces) from this specific line
		local tokens = {}
		local tempStr = ""
		for first, last in utf8.graphemes(rawLineStr) do
			local char = string.sub(rawLineStr, first, last)
			if char == " " then
				if tempStr ~= "" then table.insert(tokens, {Text = tempStr, IsSpace = false}) tempStr = "" end
				table.insert(tokens, {Text = " ", IsSpace = true})
			else
				tempStr = tempStr .. char
			end
		end
		if tempStr ~= "" then table.insert(tokens, {Text = tempStr, IsSpace = false}) end

		-- Process wrapping
		for _, token in ipairs(tokens) do
			local textToAdd = token.Text
			
			-- Measure what the line WOULD look like with this new token
			local testString = currentLineString .. textToAdd
			local testBounds = TextService:GetTextSize(testString, self.TextSize, self.Font, bigVector)
			
			-- Wrap check (ignore if line is empty, must fit at least one word)
			if testBounds.X > frameSize.X and #currentLine.Tokens > 0 then
				-- Finalize current line
				currentLine.Width = TextService:GetTextSize(currentLineString, self.TextSize, self.Font, bigVector).X
				table.insert(lines, currentLine)
				
				currentLine = { Width = 0, Tokens = {} }
				currentLineString = ""
				
				if token.IsSpace then 
					continue 
				end
			end
			
			table.insert(currentLine.Tokens, token)
			currentLineString = currentLineString .. textToAdd
		end
		
		if #currentLine.Tokens > 0 then
			currentLine.Width = TextService:GetTextSize(currentLineString, self.TextSize, self.Font, bigVector).X
			table.insert(lines, currentLine)
		end
	end

	local totalContentHeight = #lines * self.LineHeight
	local startYOffset = 0
	
	if self.TextYAlignment == Enum.TextYAlignment.Center then
		startYOffset = (frameSize.Y - totalContentHeight) / 2
	elseif self.TextYAlignment == Enum.TextYAlignment.Bottom then
		startYOffset = frameSize.Y - totalContentHeight
	end

	local globalWordIndex = 1
	local globalLetterIndex = 1

	for lineIndex, lineData in ipairs(lines) do
		local startXOffset = 0
		if self.TextXAlignment == Enum.TextXAlignment.Center then
			startXOffset = (frameSize.X - lineData.Width) / 2
		elseif self.TextXAlignment == Enum.TextXAlignment.Right then
			startXOffset = frameSize.X - lineData.Width
		end
		
		local currentX = startXOffset
		local currentY = startYOffset + ((lineIndex - 1) * self.LineHeight)
		
		local lineBuildString = ""
		
		for _, token in ipairs(lineData.Tokens) do
			local prevWidth = 0
			if lineBuildString ~= "" then
				prevWidth = TextService:GetTextSize(lineBuildString, self.TextSize, self.Font, bigVector).X
			end
			
			local tokenWidth = TextService:GetTextSize(token.Text, self.TextSize, self.Font, bigVector).X
			
			if token.IsSpace then
				lineBuildString = lineBuildString .. token.Text
			else
				local wScale = tokenWidth / frameSize.X
				local hScale = self.TextSize / frameSize.Y
				local xScale = (startXOffset + prevWidth) / frameSize.X
				local yScale = currentY / frameSize.Y
				
				local wordFrame = Instance.new("Frame")
				wordFrame.Name = "Word_" .. globalWordIndex
				wordFrame.BackgroundTransparency = 1
				wordFrame.Size = UDim2.new(wScale, 0, hScale, 0)
				wordFrame.Position = UDim2.new(xScale, 0, yScale, 0)
				wordFrame.Parent = self.Frame
				
				local wordObj = { WordString = token.Text, Frame = wordFrame, Letters = {}, Index = globalWordIndex }

				local localXCursor = 0
				for first, last in utf8.graphemes(token.Text) do
					local char = string.sub(token.Text, first, last)
					local charSize = TextService:GetTextSize(char, self.TextSize, self.Font, bigVector)
					
					local charScaleRel = charSize.X / tokenWidth
					local xPosRel = localXCursor / tokenWidth
					
					local label = Instance.new("TextLabel")
					label.Name = "Char_" .. char
					label.Text = char
					label.Font = self.Font
					label.TextColor3 = self.TextColor3
					label.TextSize = self.TextSize
					label.TextScaled = false
					label.BackgroundTransparency = 1
					label.TextTransparency = 0
					label.Size = UDim2.new(charScaleRel, 0, 1, 0)
					label.Position = UDim2.new(xPosRel, 0, 0, 0)
					label.TextXAlignment = Enum.TextXAlignment.Center
					label.TextYAlignment = Enum.TextYAlignment.Center
					label.ZIndex = self._Template.ZIndex
					label.Parent = wordFrame
					
					local letterObj = { Char = char, Label = label, Index = globalLetterIndex }
					table.insert(wordObj.Letters, letterObj)
					table.insert(self.Letters, letterObj)
					
					localXCursor += charSize.X
					globalLetterIndex += 1
				end
				
				table.insert(self.Words, wordObj)
				lineBuildString = lineBuildString .. token.Text
				globalWordIndex += 1
			end
		end
	end

	self.Changed:Fire(self.Words)
end

function RichTextComponent:UpdateScale()
	if self._UpdateDebounce then return end
	if not self.Frame or not self.Frame.Parent then return end
	if self.Frame.AbsoluteSize.X <= 1 then return end
	
	self._UpdateDebounce = true
	task.defer(function()
		if self.Frame then self:SetText(self.Text) end
		self._UpdateDebounce = false
	end)
end

function RichTextComponent:GetWords() return self.Words end
function RichTextComponent:GetLetters() return self.Letters end
function RichTextComponent:InvisibleLetters()
	for _, letter in ipairs(self.Letters) do letter.Label.TextTransparency = 1 end
end

function RichTextComponent:GetKeywordLetters(keyword: string, ignoreCase: boolean?)
	local results = {}
	if not keyword or keyword == "" then return results end
	local keywordChars = {}
	for first, last in utf8.graphemes(keyword) do
		local char = string.sub(keyword, first, last)
		if ignoreCase then char = string.lower(char) end
		table.insert(keywordChars, char)
	end
	local keyLen = #keywordChars
	if keyLen == 0 then return results end
	local i = 1
	while i <= #self.Letters do
		if (i + keyLen - 1) > #self.Letters then break end
		local match = true
		for k = 1, keyLen do
			local letterObj = self.Letters[i + k - 1]
			local letterChar = letterObj.Char
			if ignoreCase then letterChar = string.lower(letterChar) end
			if letterChar ~= keywordChars[k] then match = false break end
		end
		if match then
			for k = 1, keyLen do table.insert(results, self.Letters[i + k - 1]) end
			i = i + keyLen
		else
			i = i + 1
		end
	end
	return results
end

function RichTextComponent:Clear()
	for _, word in ipairs(self.Words) do if word.Frame then word.Frame:Destroy() end end
	self.Words = {} self.Letters = {}
end

function RichTextComponent:Destroy()
	self:Clear()
	if self.Changed then self.Changed:Destroy() end
	if self.Frame then self.Frame:Destroy() end
	setmetatable(self, nil)
end

return RichTextComponent