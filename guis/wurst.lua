
local mainapi = {
	Connections = {},
	Categories = {},
	GUIColor = {Hue = 0.46, Sat = 0.96, Value = 0.52},
	Keybind = Enum.KeyCode.RightShift,
	Loaded = false,
	Libraries = {},
	Modules = {},
	Notifications = {Enabled = true},
	Place = game.PlaceId,
	Profile = 'default',
	Profiles = {},
	RainbowSpeed = {Value = 1},
	RainbowUpdateSpeed = {Value = 60},
	RainbowTable = {},
	Scale = {Value = 1},
	ToggleNotifications = {Enabled = true},
	ThreadFix = setthreadidentity and true or false,
	Version = '6.35.3',
	Windows = {},
	CategoryOrder = {}
}

local cloneref = cloneref or function(obj) return obj end
local tweenService = cloneref(game:GetService('TweenService'))
local inputService = cloneref(game:GetService('UserInputService'))
local textService = cloneref(game:GetService('TextService'))
local guiService = cloneref(game:GetService('GuiService'))
local runService = cloneref(game:GetService('RunService'))
local httpService = cloneref(game:GetService('HttpService'))

local fontsize = Instance.new('GetTextBoundsParams')
fontsize.Width = math.huge

local getcustomasset
local clickgui
local scaledgui
local scale
local gui
local columnsHolder
local expanded

local color = {}
local tween = {tweens = {}}
local uipallet = {
	Main = Color3.fromRGB(56, 56, 56),
	Text = Color3.fromRGB(230, 230, 230),
	Font = Font.fromEnum(Enum.Font.SourceSans),
	FontSemiBold = Font.fromEnum(Enum.Font.SourceSans, Enum.FontWeight.SemiBold),
	Tween = TweenInfo.new(0.16, Enum.EasingStyle.Linear),
	Header = Color3.fromRGB(95, 130, 190),
	Enabled = Color3.fromRGB(84, 218, 98),
	Border = Color3.fromRGB(30, 30, 30),
	SubText = Color3.fromRGB(205, 205, 205)
}

local getcustomassets = {}

local isfile = isfile or function(file)
	local suc, res = pcall(function() return readfile(file) end)
	return suc and res ~= nil and res ~= ''
end

local function getfontsize(text, size, font)
	fontsize.Text = text or ''
	fontsize.Size = size or 14
	if typeof(font) == 'Font' then fontsize.Font = font end
	return textService:GetTextBoundsAsync(fontsize)
end

local function randomString()
	local array = {}
	for i = 1, math.random(10, 100) do
		array[i] = string.char(math.random(32, 126))
	end
	return table.concat(array)
end

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet(
				'https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/'..
				readfile('newvape/profiles/commit.txt')..'/'..
				select(1, path:gsub('newvape/', '')),
				true
			)
		end)
		if not suc or res == '404: Not Found' then error(res) end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local realGetCustomAsset = getcustomasset
getcustomasset = function(path)
	if getcustomassets[path] then
		return getcustomassets[path]
	end
	if not inputService.TouchEnabled and realGetCustomAsset then
		local suc, res = pcall(function()
			return downloadFile(path, realGetCustomAsset)
		end)
		if suc and res then
			return res
		end
	end
	return ''
end

do
	local res = isfile("newvape/profiles/color.txt") and pcall(function()
		return httpService:JSONDecode(readfile("newvape/profiles/color.txt"))
	end)
	if type(select(2, res)) == 'table' then
		local data = select(2, res)
		uipallet.Main = data.Main and Color3.fromRGB(unpack(data.Main)) or uipallet.Main
		uipallet.Text = data.Text and Color3.fromRGB(unpack(data.Text)) or uipallet.Text
		uipallet.Font = data.Font and Font.new(data.Font:find('rbxasset') and data.Font or string.format('rbxasset://fonts/families/%s.json', data.Font)) or uipallet.Font
		uipallet.FontSemiBold = Font.new(uipallet.Font.Family, Enum.FontWeight.SemiBold)
	end
	fontsize.Font = uipallet.Font
end

do
	color.Dark = function(col, num)
		local h, s, v = col:ToHSV()
		local _, _, compare = uipallet.Main:ToHSV()
		return Color3.fromHSV(h, s, math.clamp(compare > 0.5 and v + num or v - num, 0, 1))
	end

	color.Light = function(col, num)
		local h, s, v = col:ToHSV()
		local _, _, compare = uipallet.Main:ToHSV()
		return Color3.fromHSV(h, s, math.clamp(compare > 0.5 and v - num or v + num, 0, 1))
	end
end

do
	function tween:Tween(obj, tweeninfo, goal)
		if self.tweens[obj] then
			self.tweens[obj]:Cancel()
		end
		if obj.Parent and obj.Visible then
			self.tweens[obj] = tweenService:Create(obj, tweeninfo, goal)
			self.tweens[obj].Completed:Once(function()
				self.tweens[obj] = nil
			end)
			self.tweens[obj]:Play()
		else
			for i, v in goal do
				obj[i] = v
			end
		end
	end
end

mainapi.Libraries = {
	color = color,
	getcustomasset = getcustomasset,
	getfontsize = getfontsize,
	tween = tween,
	uipallet = uipallet
}

function mainapi:UpdateTextGUI() end
function mainapi:UpdateGUI() end
function mainapi:Load() self.Loaded = true end
function mainapi:Save() end
function mainapi:CreateNotification() end

function mainapi:Clean(obj)
	if typeof(obj) == 'Instance' then
		table.insert(self.Connections, {
			Disconnect = function()
				obj:ClearAllChildren()
				obj:Destroy()
			end
		})
		return
	elseif type(obj) == 'function' then
		table.insert(self.Connections, {Disconnect = obj})
		return
	end
	table.insert(self.Connections, obj)
end

local function addStroke(obj, col, thickness, transparency)
	local stroke = Instance.new('UIStroke')
	stroke.Color = col or uipallet.Border
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = obj
	return stroke
end

local function createTextLabel(parent, text, size, bold)
	local label = Instance.new('TextLabel')
	label.BackgroundTransparency = 1
	label.Text = text or ''
	label.TextColor3 = uipallet.Text
	label.TextSize = size or 14
	label.FontFace = bold and uipallet.FontSemiBold or uipallet.Font
	label.Parent = parent
	return label
end

local function createOptionBase(kind, optionsettings, children, moduleapi)
	local optionapi = {
		Type = kind,
		Name = optionsettings.Name or kind,
		Object = nil,
		Value = optionsettings.Default,
		List = optionsettings.List,
		Function = optionsettings.Function or function() end
	}

	local holder = Instance.new('TextButton')
	holder.Name = optionapi.Name
	holder.Size = UDim2.new(1, -10, 0, 24)
	holder.BackgroundColor3 = Color3.fromRGB(71, 71, 71)
	holder.BackgroundTransparency = 0.15
	holder.BorderSizePixel = 0
	holder.AutoButtonColor = false
	holder.Text = ''
	holder.Parent = children
	addStroke(holder, uipallet.Border, 1, 0.35)

	local label = createTextLabel(holder, optionapi.Name, 14, false)
	label.Size = UDim2.new(1, -10, 1, 0)
	label.Position = UDim2.fromOffset(6, 0)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center

	optionapi.Object = holder
	optionapi.Label = label

	function optionapi:SetValue(val)
		self.Value = val
		pcall(self.Function, val)
	end

	table.insert(moduleapi.Options, optionapi)
	return optionapi
end

local components = {
	Divider = function(optionsettings, children, moduleapi)
		local holder = Instance.new('Frame')
		holder.Name = 'Divider'
		holder.Size = UDim2.new(1, -10, 0, optionsettings.Text and 22 or 8)
		holder.BackgroundTransparency = 1
		holder.Parent = children

		if optionsettings.Text then
			local text = createTextLabel(holder, optionsettings.Text, 13, true)
			text.Size = UDim2.new(1, -8, 0, 18)
			text.Position = UDim2.fromOffset(4, 0)
			text.TextXAlignment = Enum.TextXAlignment.Left
			text.TextColor3 = uipallet.SubText
		end

		local line = Instance.new('Frame')
		line.Size = UDim2.new(1, -4, 0, 1)
		line.Position = UDim2.new(0, 2, 1, -1)
		line.BackgroundColor3 = uipallet.Border
		line.BorderSizePixel = 0
		line.Parent = holder

		local optionapi = {Type = 'Divider', Object = holder, Name = optionsettings.Text or 'Divider'}
		table.insert(moduleapi.Options, optionapi)
		return optionapi
	end,

	Toggle = function(optionsettings, children, moduleapi)
		local optionapi = createOptionBase('Toggle', optionsettings, children, moduleapi)
		optionapi.Value = optionsettings.Default == true

		local box = Instance.new('Frame')
		box.Size = UDim2.fromOffset(12, 12)
		box.Position = UDim2.new(1, -20, 0.5, -6)
		box.BackgroundColor3 = optionapi.Value and uipallet.Enabled or Color3.fromRGB(40, 40, 40)
		box.BorderSizePixel = 0
		box.Parent = optionapi.Object
		addStroke(box, uipallet.Border, 1, 0.1)

		function optionapi:SetValue(val)
			self.Value = val == true
			box.BackgroundColor3 = self.Value and uipallet.Enabled or Color3.fromRGB(40, 40, 40)
			pcall(self.Function, self.Value)
		end

		optionapi.Object.MouseButton1Click:Connect(function()
			optionapi:SetValue(not optionapi.Value)
		end)

		return optionapi
	end,

	Slider = function(optionsettings, children, moduleapi)
		local optionapi = createOptionBase('Slider', optionsettings, children, moduleapi)
		optionapi.Min = optionsettings.Min or 0
		optionapi.Max = optionsettings.Max or 100
		optionapi.Value = optionsettings.Default or optionapi.Min
		optionapi.Decimal = optionsettings.Decimal or 1
		optionapi.Suffix = optionsettings.Suffix or ''

		local valueLabel = createTextLabel(optionapi.Object, tostring(optionapi.Value)..optionapi.Suffix, 14, false)
		valueLabel.Size = UDim2.new(0, 70, 1, 0)
		valueLabel.Position = UDim2.new(1, -74, 0, 0)
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		valueLabel.TextYAlignment = Enum.TextYAlignment.Center

		local bar = Instance.new('Frame')
		bar.Size = UDim2.new(1, -12, 0, 4)
		bar.Position = UDim2.new(0, 6, 1, -6)
		bar.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
		bar.BorderSizePixel = 0
		bar.Parent = optionapi.Object

		local fill = Instance.new('Frame')
		fill.Size = UDim2.new(0, 0, 1, 0)
		fill.BackgroundColor3 = uipallet.Enabled
		fill.BorderSizePixel = 0
		fill.Parent = bar

		local function updateVisual()
			local pct = math.clamp((optionapi.Value - optionapi.Min) / math.max(optionapi.Max - optionapi.Min, 1), 0, 1)
			fill.Size = UDim2.new(pct, 0, 1, 0)
			valueLabel.Text = tostring(optionapi.Value)..optionapi.Suffix
		end

		function optionapi:SetValue(val)
			val = math.clamp(tonumber(val) or optionapi.Min, optionapi.Min, optionapi.Max)
			if optionapi.Decimal ~= 1 then
				val = math.floor(val / optionapi.Decimal + 0.5) * optionapi.Decimal
			end
			self.Value = val
			updateVisual()
			pcall(self.Function, val)
		end

		local dragging = false
		local function updateFromInput(posX)
			local pct = math.clamp((posX - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
			optionapi:SetValue(optionapi.Min + ((optionapi.Max - optionapi.Min) * pct))
		end

		optionapi.Object.MouseButton1Down:Connect(function()
			dragging = true
			updateFromInput(inputService:GetMouseLocation().X)
		end)

		mainapi:Clean(inputService.InputChanged:Connect(function(inputObj)
			if dragging and inputObj.UserInputType == Enum.UserInputType.MouseMovement then
				updateFromInput(inputObj.Position.X)
			end
		end))

		mainapi:Clean(inputService.InputEnded:Connect(function(inputObj)
			if inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end))

		updateVisual()
		return optionapi
	end,

	Dropdown = function(optionsettings, children, moduleapi)
		local optionapi = createOptionBase('Dropdown', optionsettings, children, moduleapi)
		optionapi.List = optionsettings.List or {}
		optionapi.Value = optionsettings.Default or optionapi.List[1] or ''

		local valueLabel = createTextLabel(optionapi.Object, tostring(optionapi.Value), 14, false)
		valueLabel.Size = UDim2.new(0, 100, 1, 0)
		valueLabel.Position = UDim2.new(1, -104, 0, 0)
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		valueLabel.TextYAlignment = Enum.TextYAlignment.Center

		function optionapi:SetValue(val)
			self.Value = val
			valueLabel.Text = tostring(val)
			pcall(self.Function, val)
		end

		optionapi.Object.MouseButton1Click:Connect(function()
			if #optionapi.List <= 0 then return end
			local current = table.find(optionapi.List, optionapi.Value) or 0
			current = current + 1
			if current > #optionapi.List then current = 1 end
			optionapi:SetValue(optionapi.List[current])
		end)

		return optionapi
	end,

	Textbox = function(optionsettings, children, moduleapi)
		local optionapi = createOptionBase('Textbox', optionsettings, children, moduleapi)
		optionapi.Value = optionsettings.Default or ''

		local box = Instance.new('TextBox')
		box.Size = UDim2.new(0, 110, 0, 18)
		box.Position = UDim2.new(1, -116, 0.5, -9)
		box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		box.BorderSizePixel = 0
		box.Text = tostring(optionapi.Value)
		box.TextColor3 = uipallet.Text
		box.TextSize = 14
		box.FontFace = uipallet.Font
		box.ClearTextOnFocus = false
		box.Parent = optionapi.Object
		addStroke(box, uipallet.Border, 1, 0.15)

		function optionapi:SetValue(val)
			self.Value = val
			box.Text = tostring(val)
			pcall(self.Function, val)
		end

		box.FocusLost:Connect(function()
			optionapi:SetValue(box.Text)
		end)

		return optionapi
	end,

	ColorSlider = function(optionsettings, children, moduleapi)
		local optionapi = createOptionBase('ColorSlider', optionsettings, children, moduleapi)
		optionapi.Value = optionsettings.Default or Color3.fromHSV(0, 1, 1)

		local swatch = Instance.new('Frame')
		swatch.Size = UDim2.fromOffset(14, 14)
		swatch.Position = UDim2.new(1, -22, 0.5, -7)
		swatch.BackgroundColor3 = typeof(optionapi.Value) == 'Color3' and optionapi.Value or Color3.fromHSV(0, 1, 1)
		swatch.BorderSizePixel = 0
		swatch.Parent = optionapi.Object
		addStroke(swatch, uipallet.Border, 1, 0.15)

		function optionapi:SetValue(val)
			self.Value = val
			local c = typeof(val) == 'Color3' and val or Color3.fromHSV(type(val) == 'number' and val or 0, 1, 1)
			swatch.BackgroundColor3 = c
			pcall(self.Function, val)
		end

		optionapi.Object.MouseButton1Click:Connect(function()
			local h = tick() % 1
			optionapi:SetValue(Color3.fromHSV(h, 1, 1))
		end)

		return optionapi
	end,

	Button = function(optionsettings, children, moduleapi)
		local optionapi = createOptionBase('Button', optionsettings, children, moduleapi)
		optionapi.Label.Text = optionsettings.Name or 'Button'

		local valueLabel = createTextLabel(optionapi.Object, optionsettings.ButtonText or 'Run', 14, true)
		valueLabel.Size = UDim2.new(0, 70, 1, 0)
		valueLabel.Position = UDim2.new(1, -74, 0, 0)
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		valueLabel.TextYAlignment = Enum.TextYAlignment.Center
		valueLabel.TextColor3 = uipallet.Enabled

		optionapi.Object.MouseButton1Click:Connect(function()
			pcall(optionapi.Function)
		end)

		return optionapi
	end
}

mainapi.Components = setmetatable(components, {
	__newindex = function(self, ind, func)
		for _, v in mainapi.Modules do
			rawset(v, 'Create'..ind, function(_, settings)
				return func(settings, v.Children, v)
			end)
		end
		rawset(self, ind, func)
	end
})

local function relayoutCategories()
	if not columnsHolder then return end
	local width = columnsHolder.AbsoluteSize.X
	if width <= 0 then return end

	local windowWidth = 188
	local padding = 8
	local leftPad = 8
	local topPad = 8
	local columns = math.max(1, math.floor((width - leftPad * 2 + padding) / (windowWidth + padding)))
	columns = math.min(columns, 6)

	local heights = {}
	for i = 1, columns do
		heights[i] = topPad
	end

	for _, categoryapi in mainapi.CategoryOrder do
		if categoryapi.Window then
			local bestColumn = 1
			for i = 2, columns do
				if heights[i] < heights[bestColumn] then
					bestColumn = i
				end
			end

			local bodyHeight = categoryapi.Layout and categoryapi.Layout.AbsoluteContentSize.Y or 0
			local totalHeight = math.clamp(bodyHeight + 22, 22, 320)
			categoryapi.Window.Size = UDim2.fromOffset(windowWidth, totalHeight)
			categoryapi.Children.Size = UDim2.new(1, 0, 1, -22)
			categoryapi.Children.CanvasSize = UDim2.fromOffset(0, bodyHeight + 4)
			categoryapi.Window.Position = UDim2.fromOffset(leftPad + ((bestColumn - 1) * (windowWidth + padding)), heights[bestColumn])
			heights[bestColumn] += totalHeight + padding
		end
	end

	local maxHeight = topPad
	for _, v in heights do
		maxHeight = math.max(maxHeight, v)
	end
	columnsHolder.CanvasSize = UDim2.fromOffset(0, maxHeight + 8)
end

function mainapi:CreateCategory(categorysettings)
	if self.Categories[categorysettings.Name] then
		return self.Categories[categorysettings.Name]
	end

	local categoryapi = {Type = 'Category', Name = categorysettings.Name}

	local window = Instance.new('Frame')
	window.Name = categorysettings.Name..'Category'
	window.BackgroundColor3 = uipallet.Main
	window.BackgroundTransparency = 0.18
	window.BorderSizePixel = 0
	window.Size = UDim2.fromOffset(188, 60)
	window.Parent = columnsHolder
	addStroke(window, uipallet.Border, 1, 0.1)

	local header = Instance.new('Frame')
	header.Size = UDim2.new(1, 0, 0, 22)
	header.BackgroundColor3 = uipallet.Header
	header.BackgroundTransparency = 0.15
	header.BorderSizePixel = 0
	header.Parent = window
	addStroke(header, uipallet.Border, 1, 0.45)

	local title = createTextLabel(header, categorysettings.Name, 14, true)
	title.Size = UDim2.new(1, -16, 1, 0)
	title.Position = UDim2.fromOffset(6, 0)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextYAlignment = Enum.TextYAlignment.Center

	local children = Instance.new('ScrollingFrame')
	children.Name = categorysettings.Name..'Children'
	children.Position = UDim2.fromOffset(0, 22)
	children.Size = UDim2.new(1, 0, 1, -22)
	children.BackgroundTransparency = 1
	children.BorderSizePixel = 0
	children.ScrollBarImageTransparency = 1
	children.CanvasSize = UDim2.new()
	children.Parent = window

	local list = Instance.new('UIListLayout')
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 2)
	list.Parent = children

	categoryapi.Window = window
	categoryapi.Children = children
	categoryapi.Layout = list

	list:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(relayoutCategories)

	function categoryapi:CreateModule(modulesettings)
		local moduleapi = {
			Enabled = false,
			Options = {},
			Bind = '',
			Connections = {},
			Index = modulesettings.Index or 0,
			ExtraText = modulesettings.ExtraText,
			Name = modulesettings.Name,
			Category = categorysettings.Name
		}

		local modulebutton = Instance.new('TextButton')
		modulebutton.Name = modulesettings.Name
		modulebutton.Size = UDim2.new(1, -4, 0, 20)
		modulebutton.BackgroundColor3 = Color3.fromRGB(62, 62, 62)
		modulebutton.BackgroundTransparency = 0.1
		modulebutton.BorderSizePixel = 0
		modulebutton.AutoButtonColor = false
		modulebutton.Text = ''
		modulebutton.Parent = children
		addStroke(modulebutton, uipallet.Border, 1, 0.2)

		local label = createTextLabel(modulebutton, modulesettings.Name, 14, false)
		label.Size = UDim2.new(1, -34, 1, 0)
		label.Position = UDim2.fromOffset(6, 0)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.TextColor3 = uipallet.Text

		local sep = Instance.new('Frame')
		sep.Size = UDim2.fromOffset(1, 14)
		sep.Position = UDim2.new(1, -24, 0, 3)
		sep.BackgroundColor3 = color.Dark(uipallet.Text, 0.25)
		sep.BorderSizePixel = 0
		sep.Parent = modulebutton

		local triangle = Instance.new('TextButton')
		triangle.Size = UDim2.fromOffset(18, 18)
		triangle.Position = UDim2.new(1, -20, 0, 1)
		triangle.BackgroundTransparency = 1
		triangle.AutoButtonColor = false
		triangle.Text = '▶'
		triangle.TextColor3 = uipallet.Text
		triangle.TextSize = 16
		triangle.FontFace = uipallet.FontSemiBold
		triangle.Parent = modulebutton

		local modulechildren = Instance.new('ScrollingFrame')
		modulechildren.Name = modulesettings.Name..'Children'
		modulechildren.Size = UDim2.fromOffset(350, 310)
		modulechildren.Position = UDim2.fromScale(0.5, 0.5)
		modulechildren.AnchorPoint = Vector2.new(0.5, 0.5)
		modulechildren.BackgroundColor3 = uipallet.Main
		modulechildren.BackgroundTransparency = 0.08
		modulechildren.BorderSizePixel = 0
		modulechildren.Visible = false
		modulechildren.ScrollBarImageTransparency = 1
		modulechildren.CanvasSize = UDim2.new()
		modulechildren.Parent = clickgui
		addStroke(modulechildren, uipallet.Border, 1, 0.05)
		moduleapi.Children = modulechildren

		local top = Instance.new('Frame')
		top.Size = UDim2.new(1, 0, 0, 26)
		top.BackgroundColor3 = uipallet.Header
		top.BackgroundTransparency = 0.15
		top.BorderSizePixel = 0
		top.Parent = modulechildren

		local titleLabel = createTextLabel(top, modulesettings.Name, 16, true)
		titleLabel.Size = UDim2.new(1, -10, 1, 0)
		titleLabel.Position = UDim2.fromOffset(6, 0)
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.TextYAlignment = Enum.TextYAlignment.Center

		local inner = Instance.new('Frame')
		inner.BackgroundTransparency = 1
		inner.Position = UDim2.fromOffset(0, 26)
		inner.Size = UDim2.new(1, 0, 0, 0)
		inner.Parent = modulechildren

		local windowlist = Instance.new('UIListLayout')
		windowlist.SortOrder = Enum.SortOrder.LayoutOrder
		windowlist.Padding = UDim.new(0, 2)
		windowlist.Parent = inner

		local description = Instance.new('TextLabel')
		description.BackgroundTransparency = 1
		description.Text = 'Type: Module, Category: '..moduleapi.Category..'\n\nDescription:\n'..(modulesettings.Tooltip or 'None')..'\n'
		description.TextXAlignment = Enum.TextXAlignment.Left
		description.TextYAlignment = Enum.TextYAlignment.Top
		description.TextColor3 = uipallet.Text
		description.TextSize = 14
		description.FontFace = uipallet.Font
		description.Size = UDim2.new(1, -10, 0, getfontsize(description.Text, description.TextSize, description.FontFace).Y)
		description.Parent = inner

		function moduleapi:Clean(obj)
			if typeof(obj) == 'Instance' then
				table.insert(self.Connections, {
					Disconnect = function()
						obj:ClearAllChildren()
						obj:Destroy()
					end
				})
				return
			elseif type(obj) == 'function' then
				table.insert(self.Connections, {Disconnect = obj})
				return
			end
			table.insert(self.Connections, obj)
		end

		function moduleapi:Expand()
			if expanded and expanded ~= self and expanded.Children then
				expanded.Children.Visible = false
			end
			modulechildren.Visible = not modulechildren.Visible
			expanded = modulechildren.Visible and self or nil
			triangle.Text = modulechildren.Visible and '▼' or '▶'
		end

		function moduleapi:SetBind(val)
			self.Bind = val or ''
		end

		function moduleapi:Toggle(multiple)
			if mainapi.ThreadFix then setthreadidentity(8) end
			self.Enabled = not self.Enabled
			modulebutton.BackgroundColor3 = self.Enabled and uipallet.Enabled or Color3.fromRGB(62, 62, 62)
			label.TextColor3 = self.Enabled and Color3.fromRGB(22, 22, 22) or uipallet.Text
			triangle.TextColor3 = self.Enabled and Color3.fromRGB(22, 22, 22) or uipallet.Text
			sep.BackgroundColor3 = self.Enabled and Color3.fromRGB(22, 22, 22) or color.Dark(uipallet.Text, 0.25)
			if not self.Enabled then
				for _, v in self.Connections do
					v:Disconnect()
				end
				table.clear(self.Connections)
			end
			if not multiple then mainapi:UpdateTextGUI() end
			task.spawn(modulesettings.Function or function() end, self.Enabled)
		end

		local genericCreator = function(kind, optionsettings)
			local ctor = components[kind]
			if ctor then
				return ctor(optionsettings or {}, inner, moduleapi)
			end
			local optionapi = createOptionBase(kind, optionsettings or {}, inner, moduleapi)
			return optionapi
		end

		setmetatable(moduleapi, {
			__index = function(tab, ind)
				local raw = rawget(moduleapi, ind)
				if raw ~= nil then return raw end
				local comp = mainapi.Components[ind:match('^Create(.+)$') or '']
				if ind:match('^Create') then
					return function(_, optionsettings)
						return genericCreator(ind:sub(7), optionsettings)
					end
				end
				return nil
			end
		})

		modulebutton.MouseButton1Click:Connect(function()
			moduleapi:Toggle()
		end)
		modulebutton.MouseButton2Click:Connect(function()
			moduleapi:Expand()
		end)
		triangle.MouseButton1Click:Connect(function()
			moduleapi:Expand()
		end)
		windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			local content = windowlist.AbsoluteContentSize.Y + 4
			inner.Size = UDim2.new(1, 0, 0, content)
			modulechildren.CanvasSize = UDim2.fromOffset(0, content + 30)
		end)

		moduleapi.Object = modulebutton
		mainapi.Modules[modulesettings.Name] = moduleapi

		relayoutCategories()
		return moduleapi
	end

	self.Categories[categorysettings.Name] = categoryapi
	table.insert(self.CategoryOrder, categoryapi)
	relayoutCategories()
	return categoryapi
end

gui = Instance.new('ScreenGui')
gui.Name = randomString()
gui.DisplayOrder = 9999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.IgnoreGuiInset = true
gui.OnTopOfCoreBlur = true
if mainapi.ThreadFix then
	gui.Parent = (gethui and gethui()) or cloneref(game:GetService('CoreGui'))
else
	gui.Parent = cloneref(game:GetService('Players')).LocalPlayer.PlayerGui
	gui.ResetOnSpawn = false
end
mainapi.gui = gui

scaledgui = Instance.new('Frame')
scaledgui.Name = 'ScaledGui'
scaledgui.Size = UDim2.fromScale(1, 1)
scaledgui.BackgroundTransparency = 1
scaledgui.Parent = gui

clickgui = Instance.new('TextButton')
clickgui.Name = 'ClickGui'
clickgui.Size = UDim2.fromScale(1, 1)
clickgui.BackgroundTransparency = 1
clickgui.Text = ''
clickgui.Visible = false
clickgui.Parent = scaledgui

columnsHolder = Instance.new('ScrollingFrame')
columnsHolder.Name = 'Columns'
columnsHolder.Size = UDim2.new(1, -20, 1, -20)
columnsHolder.Position = UDim2.fromOffset(10, 10)
columnsHolder.BackgroundTransparency = 1
columnsHolder.BorderSizePixel = 0
columnsHolder.ScrollBarImageTransparency = 1
columnsHolder.CanvasSize = UDim2.new()
columnsHolder.Parent = clickgui

local modal = Instance.new('TextButton')
modal.BackgroundTransparency = 1
modal.Modal = true
modal.Text = ''
modal.Parent = clickgui

local cursor = Instance.new('ImageLabel')
cursor.Size = UDim2.fromOffset(64, 64)
cursor.BackgroundTransparency = 1
cursor.Visible = false
cursor.Image = 'rbxasset://textures/Cursors/KeyboardMouse/ArrowFarCursor.png'
cursor.Parent = gui

scale = Instance.new('UIScale')
scale.Scale = 1
scale.Parent = scaledgui
mainapi.guiscale = scale
scaledgui.Size = UDim2.fromScale(1 / scale.Scale, 1 / scale.Scale)

mainapi:Clean(columnsHolder:GetPropertyChangedSignal('AbsoluteSize'):Connect(relayoutCategories))

-- Default category set. Repeated CreateCategory calls simply reuse existing categories.
for _, v in {'Combat', 'Blatant', 'Render', 'Utility', 'World', 'Inventory', 'Minigames'} do
	mainapi:CreateCategory({Name = v})
end

mainapi:Clean(clickgui.MouseButton1Click:Connect(function()
	if expanded then
		expanded:Expand()
	end
end))

mainapi:Clean(gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
	scale.Scale = 1
	relayoutCategories()
end))

mainapi:Clean(scale:GetPropertyChangedSignal('Scale'):Connect(function()
	scaledgui.Size = UDim2.fromScale(1 / scale.Scale, 1 / scale.Scale)
	for _, v in scaledgui:GetDescendants() do
		if v:IsA('GuiObject') and v.Visible then
			v.Visible = false
			v.Visible = true
		end
	end
	relayoutCategories()
end))

mainapi:Clean(clickgui:GetPropertyChangedSignal('Visible'):Connect(function()
	if clickgui.Visible and inputService.MouseEnabled then
		repeat
			local visibleCheck = clickgui.Visible
			for _, v in mainapi.Windows do
				visibleCheck = visibleCheck or v.Visible
			end
			if not visibleCheck then break end

			cursor.Visible = not inputService.MouseIconEnabled
			if cursor.Visible then
				local mouseLocation = inputService:GetMouseLocation()
				cursor.Position = UDim2.fromOffset(mouseLocation.X - 31, mouseLocation.Y - 32)
			end

			task.wait()
		until mainapi.Loaded == nil
		cursor.Visible = false
	end
end))

mainapi:Clean(inputService.InputBegan:Connect(function(inputObj)
	if not inputService:GetFocusedTextBox() and inputObj.KeyCode ~= Enum.KeyCode.Unknown then
		if mainapi.Binding then
			mainapi.Binding:SetBind(mainapi.Binding.Bind == inputObj.KeyCode.Name and '' or inputObj.KeyCode.Name, true)
			mainapi.Binding = nil
			return
		end

		if inputObj.KeyCode == mainapi.Keybind then
			if mainapi.ThreadFix then setthreadidentity(8) end
			for _, v in mainapi.Windows do v.Visible = false end
			clickgui.Visible = not clickgui.Visible
		end

		local toggled = false
		for i, v in mainapi.Modules do
			if v.Bind == inputObj.KeyCode.Name then
				toggled = true
				if mainapi.ToggleNotifications.Enabled then
					mainapi:CreateNotification('Module Toggled', i.."<font color='#FFFFFF'> has been </font>"..(not v.Enabled and "<font color='#5AFF5A'>Enabled</font>" or "<font color='#FF5A5A'>Disabled</font>").."<font color='#FFFFFF'>!</font>", 0.75)
				end
				v:Toggle(true)
			end
		end
		if toggled then
			mainapi:UpdateTextGUI()
		end

		for _, v in mainapi.Profiles do
			if v.Bind == inputObj.KeyCode.Name and v.Name ~= mainapi.Profile then
				mainapi:Save(v.Name)
				mainapi:Load(true)
				break
			end
		end
	end
end))

task.defer(relayoutCategories)

return mainapi
