--!strict
--https://devforum.roblox.com/t/-/3271288

local module = {}


export type Properties = {
	--Appearance
	CellPadding : UDim2?,
	CellSize : UDim2?,

	--Data
	AbsoluteCellCount : Vector2?,
	AbsoluteCellSize: Vector2?,
	AbsoluteContentSize : Vector2?,

	Parent : GuiObject | boolean?, -- this boolean is purely so that it is inside the property table, otherwise itwill warn.

	--Behavior
	FillDirection : Enum.FillDirection?,
	FillDirectionMaxCells : number?,
	SortOrder : Enum.SortOrder?,
	StartCorner : Enum.StartCorner?,

	--Alignment
	HorizontalAlignment : Enum.HorizontalAlignment?,
	VerticalAlignment : Enum.VerticalAlignment?,

	--Extra Properties
	ForceSize : boolean?,
	OnPositionChange : (Object : GuiObject, Position : UDim2) -> ()?,
	OnCellInsert : (Onbject : GuiObject, Position : UDim2) -> ()?,
	AffectedGuiObjectsType : "Whitelist" | "BlackList" | "Auto" ?,
	AffectedGuiObjects : {[number] : GuiObject}?,
}


local PropertyTable : Properties = {
	--Apprearance
	["CellPadding"] = UDim2.new(0,5,0,5),
	["CellSize"] = UDim2.new(0,100,0,100),

	--Data
	["AbsoluteCellCount"] = Vector2.zero,
	["AbsoluteCellSize"] = Vector2.zero,
	["AbsoluteContentSize"] = Vector2.zero,

	["Parent"] = false, --look at line 18

	--Behavior
	["FillDirection"] = Enum.FillDirection.Horizontal,
	["FillDirectionMaxCells"] = 0,
	["SortOrder"] = Enum.SortOrder.LayoutOrder,
	["StartCorner"] = Enum.StartCorner.TopLeft,

	--Alignment
	["HorizontalAlignment"] = Enum.HorizontalAlignment.Left,
	["VerticalAlignment"] = Enum.VerticalAlignment.Top,

	--Custom
	["ForceSize"] = true,
	["OnPositionChange"] = function(Onbject : GuiObject, Position : UDim2) Onbject.Position = Position return end,
	["OnCellInsert"] = function(Onbject : GuiObject, Position : UDim2) Onbject.Position = Position return end,

	["AffectedGuiObjectsType"] = "Auto",
	["AffectedGuiObjects"] = {},
}


function ScaleToOffset(Axis : UDim2, Parent : GuiObject | ScreenGui) : Vector2
	local AbsoluteSize : Vector2 = Parent.AbsoluteSize

	local x = Axis.X.Offset + AbsoluteSize.X * Axis.X.Scale
	local y = Axis.Y.Offset + AbsoluteSize.Y * Axis.Y.Scale

	return Vector2.new(x, y)
end


function module.new(UiGridLayout : UIGridLayout?, OtherProperties : Properties?)
	local self = setmetatable({},{__index = module})

	if UiGridLayout then
		--Appearance
		self.CellPadding = UiGridLayout.CellPadding :: UDim2
		self.CellSize = UiGridLayout.CellSize :: UDim2

		--Data
		self.AbsoluteCellCount = UiGridLayout.AbsoluteCellCount :: Vector2
		self.AbsoluteCellSize = UiGridLayout.AbsoluteCellSize :: Vector2
		self.AbsoluteContentSize = UiGridLayout.AbsoluteContentSize :: Vector2

		self.Parent = UiGridLayout.Parent :: GuiObject

		--Behavor
		self.FillDirection = UiGridLayout.FillDirection  :: Enum.FillDirection
		self.FillDirectionMaxCells = UiGridLayout.FillDirectionMaxCells  :: number
		self.SortOrder = UiGridLayout.SortOrder :: Enum.SortOrder
		self.StartCorner = UiGridLayout.StartCorner :: Enum.StartCorner

		--Alignment
		self.HorizontalAlignment = UiGridLayout.HorizontalAlignment :: Enum.HorizontalAlignment
		self.VerticalAlignment = UiGridLayout.VerticalAlignment :: Enum.VerticalAlignment


		--Other
		self.__UiGridLayout = UiGridLayout
		self.__UiGridLayout.Parent = nil
	end

	-- Aply any other proprty.
	if OtherProperties then
		for Property, Value in PropertyTable do
			if OtherProperties[Property] ~= nil then
				self[Property] = OtherProperties[Property]
			else
				if not self[Property] then
					self[Property] = PropertyTable[Property]
				end
			end
		end
	end

	if self.Parent == nil then return error("Parent is nil") end

	self.Setup = false

	return self
end


function module:OrganizeGuiObjects()

	local GuiObjectArray : {[number] : GuiObject} = self.Parent:GetChildren()

	if self.AffectedGuiObjectsType == "BlackList" then
		if not self.AffectedGuiObjects or typeof(self.AffectedGuiObjects) ~= "table" then return error("AffectedGuiObjects is nil, please give a correct value.") end
		for Index, Value in self.AffectedGuiObjects do
			local OtherIndex = table.find(GuiObjectArray, Value)
			if OtherIndex then table.remove(GuiObjectArray, OtherIndex) end
		end
	elseif self.AffectedGuiObjectsType == "Whitelist" then
		if not self.AffectedGuiObjects or typeof(self.AffectedGuiObjects) ~= "table" then return error("AffectedGuiObjects is nil, please give a correct value.") end
		GuiObjectArray = self.AffectedGuiObjects
	end

	for Index = #GuiObjectArray, 1, -1 do
		if
			(not GuiObjectArray[Index]:IsA("GuiObject")) or
			(GuiObjectArray[Index].Parent ~= self.Parent) or
			(GuiObjectArray[Index].Visible == false)
		then
			table.remove(GuiObjectArray, Index)
		end

	end

	local CountOfGuiObjects : number = #GuiObjectArray

	local Parent : GuiObject = self.Parent
	local ParentAbsoluteSize : Vector2 = Parent.AbsoluteSize

	local AbsoluteCellPadding = ScaleToOffset(self.CellPadding :: UDim2,Parent)
	local AbsoluteCellSize = ScaleToOffset(self.CellSize :: UDim2,Parent)
	local AbsoluteCellTotalSize = AbsoluteCellSize + AbsoluteCellPadding
	local AbsoluteContentPosition : Vector2 = Vector2.new()


	local MaxPrimaryAxisCellCount : number
	local SecondaryAxisCellCount : number
	local AbsoluteCellCount : Vector2
	local AbsoluteContentSize : Vector2


	if self.FillDirection == Enum.FillDirection.Horizontal then
		if ParentAbsoluteSize.X % AbsoluteCellTotalSize.X >= AbsoluteCellSize.X then
			MaxPrimaryAxisCellCount = math.max(1,math.ceil(ParentAbsoluteSize.X/AbsoluteCellTotalSize.X))
		else
			MaxPrimaryAxisCellCount = math.max(1,math.floor(ParentAbsoluteSize.X/AbsoluteCellTotalSize.X))
		end
	elseif self.FillDirection == Enum.FillDirection.Vertical then
		if ParentAbsoluteSize.Y % AbsoluteCellTotalSize.Y >= AbsoluteCellSize.Y then
			MaxPrimaryAxisCellCount = math.max(1,math.ceil(ParentAbsoluteSize.Y/AbsoluteCellTotalSize.Y))
		else
			MaxPrimaryAxisCellCount = math.max(1,math.floor(ParentAbsoluteSize.Y/AbsoluteCellTotalSize.Y))
		end
	end

	if self.FillDirectionMaxCells ~= 0 then
		MaxPrimaryAxisCellCount = math.clamp(self.FillDirectionMaxCells,1,MaxPrimaryAxisCellCount)
	end

	SecondaryAxisCellCount = math.ceil(CountOfGuiObjects/MaxPrimaryAxisCellCount)

	if self.FillDirection == Enum.FillDirection.Horizontal then
		AbsoluteCellCount = Vector2.new(MaxPrimaryAxisCellCount, SecondaryAxisCellCount)
		AbsoluteContentSize = Vector2.new(MaxPrimaryAxisCellCount * AbsoluteCellTotalSize.X - AbsoluteCellPadding.X, SecondaryAxisCellCount * AbsoluteCellTotalSize.Y - AbsoluteCellPadding.Y)
	else
		AbsoluteCellCount = Vector2.new(SecondaryAxisCellCount, MaxPrimaryAxisCellCount)
		AbsoluteContentSize = Vector2.new(SecondaryAxisCellCount * AbsoluteCellTotalSize.X - AbsoluteCellPadding.X, MaxPrimaryAxisCellCount * AbsoluteCellTotalSize.Y - AbsoluteCellPadding.Y)
	end



	if self.HorizontalAlignment == Enum.HorizontalAlignment.Left then
		AbsoluteContentPosition = Vector2.new(0, AbsoluteContentPosition.Y)
	elseif self.HorizontalAlignment == Enum.HorizontalAlignment.Right then
		AbsoluteContentPosition = Vector2.new(ParentAbsoluteSize.X - AbsoluteContentSize.X, AbsoluteContentPosition.Y)
	elseif self.HorizontalAlignment == Enum.HorizontalAlignment.Center then
		if AbsoluteCellCount.X % 2 == 0 then
			AbsoluteContentPosition = Vector2.new(math.floor((ParentAbsoluteSize.X - AbsoluteContentSize.X)/2), AbsoluteContentPosition.Y)
		else
			AbsoluteContentPosition = Vector2.new(math.ceil((ParentAbsoluteSize.X - AbsoluteContentSize.X)/2),AbsoluteContentPosition.Y)
		end
	end

	if self.VerticalAlignment == Enum.VerticalAlignment.Top then
		AbsoluteContentPosition = Vector2.new(AbsoluteContentPosition.X, 0)
	elseif self.VerticalAlignment == Enum.VerticalAlignment.Bottom then
		AbsoluteContentPosition= Vector2.new(AbsoluteContentPosition.X, ParentAbsoluteSize.Y - AbsoluteContentSize.Y)
	elseif self.VerticalAlignment == Enum.VerticalAlignment.Center then
		if AbsoluteCellCount.Y % 2 == 0 then
			AbsoluteContentPosition = Vector2.new(AbsoluteContentPosition.X, math.ceil((ParentAbsoluteSize.Y - AbsoluteContentSize.Y)/2))
		else
			AbsoluteContentPosition = Vector2.new(AbsoluteContentPosition.X, math.floor((ParentAbsoluteSize.Y - AbsoluteContentSize.Y)/2))
		end
	end

	if self.SortOrder == Enum.SortOrder.LayoutOrder then
		table.sort(GuiObjectArray, function(A : GuiObject, B : GuiObject)
			return A.LayoutOrder < B.LayoutOrder
		end)
	else
		table.sort(GuiObjectArray, function(A : GuiObject, B : GuiObject)
			return A.Name < B.Name
		end)
	end

	if self.ForceSize then
		for _, GuiObject in GuiObjectArray do
			GuiObject.Size = self.CellSize
		end
	end

	local Data = {}

	for Index = 0, CountOfGuiObjects - 1 do
		local GuiObject = GuiObjectArray[Index + 1]

		local X : number
		local Y : number

		local Offset = UDim2.new()

		if GuiObject.AbsoluteSize.X % 2 then
			Offset = UDim2.fromOffset(math.ceil(GuiObject.AnchorPoint.X * AbsoluteCellSize.X),0)
		else
			Offset = UDim2.fromOffset(math.floor(GuiObject.AnchorPoint.X * AbsoluteCellSize.X), 0)
		end

		if GuiObject.AbsoluteSize.Y % 2 then
			Offset = UDim2.fromOffset(Offset.X.Offset, math.floor(GuiObject.AnchorPoint.Y * AbsoluteCellSize.Y))
		else
			Offset = UDim2.fromOffset(Offset.X.Offset, math.ceil(GuiObject.AnchorPoint.Y * AbsoluteCellSize.Y))
		end


		if self.StartCorner == Enum.StartCorner.TopLeft then
			if self.FillDirection == Enum.FillDirection.Horizontal then
				X = AbsoluteContentPosition.X + Index % MaxPrimaryAxisCellCount * AbsoluteCellTotalSize.X
				Y = AbsoluteContentPosition.Y + math.floor(Index/MaxPrimaryAxisCellCount) * AbsoluteCellTotalSize.Y
			else
				X = AbsoluteContentPosition.X + math.floor(Index/MaxPrimaryAxisCellCount) * AbsoluteCellTotalSize.X
				Y = AbsoluteContentPosition.Y + Index % MaxPrimaryAxisCellCount * AbsoluteCellTotalSize.Y
			end
		elseif self.StartCorner == Enum.StartCorner.BottomLeft then

			if self.FillDirection == Enum.FillDirection.Horizontal then
				X = AbsoluteContentPosition.X + Index % MaxPrimaryAxisCellCount * AbsoluteCellTotalSize.X
				Y = AbsoluteContentPosition.Y + AbsoluteContentSize.Y - AbsoluteCellSize.Y - math.floor(Index/MaxPrimaryAxisCellCount) * AbsoluteCellTotalSize.Y
			else
				X = AbsoluteContentPosition.X + math.floor(Index/MaxPrimaryAxisCellCount) * AbsoluteCellTotalSize.X
				Y = AbsoluteContentPosition.Y + AbsoluteContentSize.Y - AbsoluteCellSize.Y - Index % MaxPrimaryAxisCellCount * AbsoluteCellTotalSize.Y
			end
		elseif self.StartCorner == Enum.StartCorner.TopRight then

			if self.FillDirection == Enum.FillDirection.Horizontal then
				X = AbsoluteContentPosition.X + AbsoluteContentSize.X - AbsoluteCellSize.X - Index % MaxPrimaryAxisCellCount * AbsoluteCellTotalSize.X
				Y = AbsoluteContentPosition.Y + math.floor(Index/MaxPrimaryAxisCellCount) * AbsoluteCellTotalSize.Y
			else
				X = AbsoluteContentPosition.X + AbsoluteContentSize.X - AbsoluteCellSize.X - math.floor(Index/MaxPrimaryAxisCellCount) * AbsoluteCellTotalSize.X
				Y = AbsoluteContentPosition.Y + Index % MaxPrimaryAxisCellCount * AbsoluteCellTotalSize.Y 
			end
		elseif self.StartCorner == Enum.StartCorner.BottomRight then
			if self.FillDirection == Enum.FillDirection.Horizontal then
				X = AbsoluteContentPosition.X + AbsoluteContentSize.X - AbsoluteCellSize.X - Index % MaxPrimaryAxisCellCount * AbsoluteCellTotalSize.X
				Y = AbsoluteContentPosition.Y + AbsoluteContentSize.Y - AbsoluteCellSize.X - math.floor(Index/MaxPrimaryAxisCellCount) * AbsoluteCellTotalSize.Y
			else
				X = AbsoluteContentPosition.X + AbsoluteContentSize.X - AbsoluteCellSize.X - math.floor(Index/MaxPrimaryAxisCellCount) * AbsoluteCellTotalSize.X
				Y = AbsoluteContentPosition.Y + AbsoluteContentSize.Y - AbsoluteCellSize.Y - Index % MaxPrimaryAxisCellCount * AbsoluteCellTotalSize.Y
			end
		end

		local EndPosition = UDim2.fromOffset(X,Y) + Offset

		if self.PreviousData then
			if not self.PreviousData.ObjectData[GuiObject] then
				self.OnCellInsert(GuiObject, EndPosition)
			elseif EndPosition ~= self.PreviousData.ObjectData[GuiObject] then
				self.OnPositionChange(GuiObject, EndPosition)
			end


		else
			if GuiObject.Position ~= EndPosition and self.Setup then
				self.OnPositionChange(GuiObject, EndPosition)
			else
				GuiObject.Position = EndPosition
			end
		end

		Data[GuiObject] = EndPosition

	end

	if not self.Setup then
		self.Setup = true
	end

	self.PreviousData = {
		ObjectData = Data
	}

	self.AbsoluteCellCount = AbsoluteCellCount
	self.AbsoluteCellSize = ScaleToOffset(self.CellSize, Parent)
	self.AbsoluteContentSize = AbsoluteContentSize

end

function module:Void()
	if self.__UiGridLayout then
		self.__UiGridLayout.Parent = self.Parent
	end
	table.clear(self)
	setmetatable(self, nil)
end

return module