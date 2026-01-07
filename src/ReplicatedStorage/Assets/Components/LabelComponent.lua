--[[
	// FileName: RichTextComponent.lua
	// Description: Converts TextLabel into Word Frames containing Letter Labels.
	// Update: Adds Binary Search for accurate TextScaled emulation.
	@TbeyazT 2025
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
	-- If TextScaled is OFF, just use the set size
	if not template.TextScaled then
		return template.TextSize
	end

	-- If TextScaled is ON, we must find the largest size that fits
	local minSize = 1
	local maxSize = 100 -- Cap at 100 to prevent massive text, or use frameSize.Y
	local bestSize = minSize
	
	-- Binary search for the perfect size
	local textWidthLimit = frameSize.X
	
	while minSize <= maxSize do
		local mid = math.floor((minSize + maxSize) / 2)
		
		-- Ask Roblox: "If I use this font size, how big is the text?"
		local bounds = TextService:GetTextSize(text, mid, font, Vector2.new(textWidthLimit, 10000))
		
		-- Check if it fits vertically inside the frame
		if bounds.Y <= frameSize.Y then
			bestSize = mid
			minSize = mid + 1
		else
			maxSize = mid - 1
		end
	end
	
	return bestSize
end

--// Constructor
function RichTextComponent.new(template: TextLabel)
	local self = setmetatable({}, RichTextComponent)

	local frame = Instance.new("Frame")
	frame.Name = template.Name .. "_RichContainer"
	frame.Size = template.Size
	frame.Position = template.Position
	frame.AnchorPoint = template.AnchorPoint
	frame.BackgroundTransparency = 1
	frame.ZIndex = template.ZIndex
	frame.ClipsDescendants = template.ClipsDescendants
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

	-- Hide the template but keep it for reference
	template.BackgroundTransparency = 1
	template.TextTransparency = 1 
	local stroke = template:FindFirstChildWhichIsA("UIStroke")
	if stroke then stroke.Enabled = false end

	-- Initial Size calculation
	self.TextSize = template.TextSize

	frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:UpdateScale() end)
	
	return self
end

--// Core Logic
function RichTextComponent:SetText(text: string)
	self:Clear()
	self.Text = text
	self._Template.Text = text -- Keep template in sync

	local frameSize = self.Frame.AbsoluteSize
	if frameSize.X <= 1 or frameSize.Y <= 1 then return end

	-- 1. CALCULATE EXACT SIZE
	self.TextSize = calculateBestFontSize(text, self.Font, frameSize, self._Template)
	self.LineHeight = self.TextSize -- Use 1.0 for tighter fit, or 1.1 if needed

	-- 2. Tokenize
	local tokens = {} 
	local currentToken = { Text = "", IsSeparator = false }
	
	for first, last in utf8.graphemes(text) do
		local char = string.sub(text, first, last)
		if char:match("%s") then -- Matches space, tab, newline
			if #currentToken.Text > 0 then table.insert(tokens, currentToken) end
			table.insert(tokens, { Text = char, IsSeparator = true })
			currentToken = { Text = "", IsSeparator = false }
		else
			currentToken.Text = currentToken.Text .. char
		end
	end
	if #currentToken.Text > 0 then table.insert(tokens, currentToken) end

	-- 3. Render Loop
	local xCursor = 0
	local yCursor = 0
	local lineHeightScale = self.LineHeight / frameSize.Y
	local totalHeight = lineHeightScale
	
	local spaceWidth = TextService:GetTextSize(" ", self.TextSize, self.Font, Vector2.new(math.huge, math.huge)).X
	local spaceScale = spaceWidth / frameSize.X
	
	local wordIndex = 1
	local globalLetterIndex = 1

	for _, token in ipairs(tokens) do
		if token.Text == "\n" then
			xCursor = 0
			yCursor += lineHeightScale
			totalHeight += lineHeightScale
			continue
		end

		if token.IsSeparator and token.Text == " " then
			xCursor += spaceScale
			continue
		end
		
		if token.IsSeparator then continue end -- Skip other whitespace

		-- Measure Word
		local wordPixelSize = TextService:GetTextSize(token.Text, self.TextSize, self.Font, Vector2.new(math.huge, math.huge))
		local wordWidthScale = wordPixelSize.X / frameSize.X
		local wordHeightScale = self.TextSize / frameSize.Y

		-- Wrap
		if xCursor > 0 and (xCursor + wordWidthScale) > 1 then
			xCursor = 0
			yCursor += lineHeightScale
			totalHeight += lineHeightScale
		end

		-- Create Word Frame
		local wordFrame = Instance.new("Frame")
		wordFrame.Name = "Word_" .. wordIndex
		wordFrame.BackgroundTransparency = 1
		wordFrame.Size = UDim2.new(wordWidthScale, 0, wordHeightScale, 0)
		wordFrame.Position = UDim2.new(xCursor, 0, yCursor, 0)
		wordFrame.Parent = self.Frame
		
		local wordObj = { WordString = token.Text, Frame = wordFrame, Letters = {}, Index = wordIndex }

		local localXCursor = 0
		
		for first, last in utf8.graphemes(token.Text) do
			local char = string.sub(token.Text, first, last)
			local charSize = TextService:GetTextSize(char, self.TextSize, self.Font, Vector2.new(math.huge, math.huge))
			
			local charScaleRel = charSize.X / wordPixelSize.X 
			local xPosRel = localXCursor / wordPixelSize.X

			local label = Instance.new("TextLabel")
			label.Name = "Char_" .. char
			label.Text = char
			label.Font = self.Font
			label.TextColor3 = self.TextColor3
			label.TextSize = self.TextSize
			label.TextScaled = false -- Must be false, we manually sized it
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
		xCursor += wordWidthScale
		wordIndex += 1
	end

	self:ApplyAlignment(totalHeight)
	self.Changed:Fire(self.Words)
end

function RichTextComponent:ApplyAlignment(totalHeightScale)
	if not self.Frame or #self.Words == 0 then return end
	
	local frame = self.Frame
	local lineTolerance = (self.LineHeight / frame.AbsoluteSize.Y) * 0.5 -- Increased tolerance slightly
	local lines = {}

	for _, wordObj in ipairs(self.Words) do
		local yScale = wordObj.Frame.Position.Y.Scale
		local found = false
		for _, line in ipairs(lines) do
			if math.abs(line.Y - yScale) < lineTolerance then
				table.insert(line.Words, wordObj)
				found = true
				break
			end
		end
		if not found then table.insert(lines, { Y = yScale, Words = { wordObj } }) end
	end

	table.sort(lines, function(a, b) return a.Y < b.Y end)

	local offsetYScale = 0
	if self.TextYAlignment == Enum.TextYAlignment.Center then
		offsetYScale = (1 - totalHeightScale) / 2
	elseif self.TextYAlignment == Enum.TextYAlignment.Bottom then
		offsetYScale = 1 - totalHeightScale
	end

	for i, line in ipairs(lines) do
		local firstWord = line.Words[1]
		local lastWord = line.Words[#line.Words]
		local lineWidthScale = (lastWord.Frame.Position.X.Scale + lastWord.Frame.Size.X.Scale) - firstWord.Frame.Position.X.Scale
		
		local offsetXScale = 0
		if self.TextXAlignment == Enum.TextXAlignment.Center then
			offsetXScale = (1 - lineWidthScale) / 2
		elseif self.TextXAlignment == Enum.TextXAlignment.Right then
			offsetXScale = 1 - lineWidthScale
		end
		
		local startX = line.Words[1].Frame.Position.X.Scale
		local shiftX = offsetXScale - startX
		local lineYPos = offsetYScale + (i - 1) * (self.LineHeight / frame.AbsoluteSize.Y)

		for _, wordObj in ipairs(line.Words) do
			local currentX = wordObj.Frame.Position.X.Scale
			wordObj.Frame.Position = UDim2.new(currentX + shiftX, 0, lineYPos, 0)
		end
	end
end

function RichTextComponent:UpdateScale()
	if self._UpdateDebounce then return end
	if not self.Frame or not self.Frame.Parent then return end
	if self.Frame.AbsoluteSize.X <= 1 then return end

	local newSize = calculateBestFontSize(self.Text, self.Font, self.Frame.AbsoluteSize, self._Template)
	
	-- Only update if size changed significantly
	if math.abs(newSize - self.TextSize) > 1 or #self.Words == 0 then
		self._UpdateDebounce = true
		task.defer(function()
			if self.Frame then self:SetText(self.Text) end
			self._UpdateDebounce = false
		end)
	end
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