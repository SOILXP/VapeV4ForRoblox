
local mainapi = {
	Connections = {},
	Categories = {},
	CategoryAliases = {},
	CategoryOrder = {},
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
	Version = 'Wurst v7.53.1 MC26.1.2',
	Windows = {}
}

local cloneref = cloneref or function(obj) return obj end
local tweenService = cloneref(game:GetService('TweenService'))
local inputService = cloneref(game:GetService('UserInputService'))
local textService = cloneref(game:GetService('TextService'))
local guiService = cloneref(game:GetService('GuiService'))
local httpService = cloneref(game:GetService('HttpService'))
local playersService = cloneref(game:GetService('Players'))

local lplr = playersService.LocalPlayer
local fontsize = Instance.new('GetTextBoundsParams')
fontsize.Width = math.huge

local gui
local scaledgui
local clickgui
local columnsHolder
local logoFrame
local activeList
local scale
local expanded
local getcustomasset

local color = {}
local tween = {tweens = {}}
local uipallet = {
	Main = Color3.fromRGB(64, 71, 86),
	MainAlpha = 0.18,
	Header = Color3.fromRGB(92, 126, 181),
	HeaderAlpha = 0.05,
	Text = Color3.fromRGB(240, 240, 240),
	DarkText = Color3.fromRGB(12, 12, 12),
	Enabled = Color3.fromRGB(73, 224, 97),
	Border = Color3.fromRGB(28, 31, 37),
	Accent = Color3.fromRGB(0, 180, 0),
	Font = Font.fromEnum(Enum.Font.Code),
	FontSemiBold = Font.fromEnum(Enum.Font.Code, Enum.FontWeight.Bold),
	Tween = TweenInfo.new(0.08, Enum.EasingStyle.Linear)
}

local getcustomassets = {
	['newvape/assets/wurst/wurst_128.png'] = '',
	['newvape/assets/wurst/icon.png'] = ''
}

local WURST_ORDER = {'Combat', 'Render', 'Blocks', 'Movement', 'Other', 'Fun', 'Items', 'Chat'}
local CATEGORY_ALIASES = {
	Combat = 'Combat',
	Blatant = 'Combat',
	Render = 'Render',
	Blocks = 'Blocks',
	World = 'Blocks',
	Movement = 'Movement',
	Utility = 'Other',
	Other = 'Other',
	Fun = 'Fun',
	Minigames = 'Fun',
	Items = 'Items',
	Inventory = 'Items',
	Chat = 'Chat',
	Main = 'Other',
	Legit = 'Other'
}

local function safeCall(func, ...)
	if type(func) ~= 'function' then return end
	local ok, res = pcall(func, ...)
	if not ok then warn('[Wurst UI]', res) end
	return res
end

local isfile = isfile or function(file)
	local suc, res = pcall(function() return readfile(file) end)
	return suc and res ~= nil and res ~= ''
end

local function loadJson(path)
	local suc, res = pcall(function() return httpService:JSONDecode(readfile(path)) end)
	return suc and type(res) == 'table' and res or nil
end

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet(
				'https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')),
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
	if getcustomassets[path] and getcustomassets[path] ~= '' then
		return getcustomassets[path]
	end
	if not inputService.TouchEnabled and realGetCustomAsset then
		local ok, res = pcall(function()
			return downloadFile(path, realGetCustomAsset)
		end)
		if ok and res then return res end
	end
	return ''
end

local function getfontsize(text, size, font)
	fontsize.Text = text or ''
	fontsize.Size = size or 12
	if typeof(font) == 'Font' then fontsize.Font = font end
	local ok, bounds = pcall(function() return textService:GetTextBoundsAsync(fontsize) end)
	return ok and bounds or Vector2.zero
end

local function randomString()
	local array = {}
	for i = 1, math.random(10, 100) do
		array[i] = string.char(math.random(32, 126))
	end
	return table.concat(array)
end

function color.Dark(col, num)
	local h, s, v = col:ToHSV()
	return Color3.fromHSV(h, s, math.clamp(v - num, 0, 1))
end

function color.Light(col, num)
	local h, s, v = col:ToHSV()
	return Color3.fromHSV(h, s, math.clamp(v + num, 0, 1))
end

function mainapi:Color(h)
	local s = 0.75 + (0.15 * math.min(h / 0.03, 1))
	if h > 0.57 then s = 0.9 - (0.4 * math.min((h - 0.57) / 0.09, 1)) end
	if h > 0.66 then s = 0.5 + (0.4 * math.min((h - 0.66) / 0.16, 1)) end
	if h > 0.87 then s = 0.9 - (0.15 * math.min((h - 0.87) / 0.13, 1)) end
	return h, s, 1
end

function mainapi:TextColor(h, s, v)
	if v < 0.7 then return Color3.new(1, 1, 1) end
	if s < 0.6 or h > 0.04 and h < 0.56 then return Color3.new(0.19, 0.19, 0.19) end
	return Color3.new(1, 1, 1)
end

function tween:Tween(obj, tweeninfo, goal)
	if self.tweens[obj] then self.tweens[obj]:Cancel() end
	if obj and obj.Parent and obj.Visible then
		self.tweens[obj] = tweenService:Create(obj, tweeninfo, goal)
		self.tweens[obj].Completed:Once(function() self.tweens[obj] = nil end)
		self.tweens[obj]:Play()
	else
		for i, v in goal do obj[i] = v end
	end
end

mainapi.Libraries = {
	color = color,
	getcustomasset = getcustomasset,
	getfontsize = getfontsize,
	tween = tween,
	uipallet = uipallet
}

local function stroke(obj, thickness, transparency, col)
	local s = Instance.new('UIStroke')
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Color = col or uipallet.Border
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.Parent = obj
	return s
end

local function makeText(parent, txt, size, bold)
	local label = Instance.new('TextLabel')
	label.BackgroundTransparency = 1
	label.Text = txt or ''
	label.TextColor3 = uipallet.Text
	label.TextSize = size or 11
	label.FontFace = bold and uipallet.FontSemiBold or uipallet.Font
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local function makeShadowedText(parent, txt, size, pos, textCol)
	local shadow = makeText(parent, txt, size, true)
	shadow.Position = pos + UDim2.fromOffset(1, 1)
	shadow.Size = UDim2.new(1, 0, 0, size + 4)
	shadow.TextColor3 = Color3.new()
	local label = makeText(parent, txt, size, true)
	label.Position = pos
	label.Size = UDim2.new(1, 0, 0, size + 4)
	label.TextColor3 = textCol or uipallet.Text
	return label
end

local function canonicalCategoryName(name)
	return CATEGORY_ALIASES[name] or name or 'Other'
end

local function sortCategoryRows(categoryapi)
	local rows = {}
	for _, moduleapi in mainapi.Modules do
		if moduleapi.Category == categoryapi.Name and moduleapi.Object then
			table.insert(rows, moduleapi)
		end
	end
	table.sort(rows, function(a, b) return a.Name:lower() < b.Name:lower() end)
	for i, moduleapi in rows do
		moduleapi.Index = i
		moduleapi.Object.LayoutOrder = i
	end
end

local function relayoutCategories()
	if not columnsHolder then return end
	local windowWidth = 92
	local gap = 6
	local x = 166
	local y = 6
	local maxW = math.max(columnsHolder.AbsoluteSize.X - 10, 1)
	for _, categoryapi in mainapi.CategoryOrder do
		local window = categoryapi.Window
		if window then
			local bodyHeight = categoryapi.Layout.AbsoluteContentSize.Y
			local height = math.clamp(12 + bodyHeight + 2, 12, 190)
			if x + windowWidth > maxW then
				x = 166
				y += 184
			end
			window.Position = UDim2.fromOffset(x, y)
			window.Size = UDim2.fromOffset(windowWidth, height)
			categoryapi.Children.Size = UDim2.new(1, 0, 1, -12)
			categoryapi.Children.CanvasSize = UDim2.fromOffset(0, bodyHeight + 2)
			x += windowWidth + gap
		end
	end
end

local function updateHackList()
	if not activeList then return end
	local enabled = {}
	for _, moduleapi in mainapi.Modules do
		if moduleapi.Enabled then table.insert(enabled, moduleapi.Name) end
	end
	table.sort(enabled)
	activeList.Text = table.concat(enabled, '\n')
end

local components = {}

local function createOptionBase(kind, optionsettings, children, moduleapi)
	optionsettings = optionsettings or {}
	local optionapi = {
		Type = kind,
		Name = optionsettings.Name or kind,
		Value = optionsettings.Default,
		Function = optionsettings.Function or function() end,
		Object = nil
	}
	local row = Instance.new('TextButton')
	row.Name = optionapi.Name
	row.Size = UDim2.new(1, -6, 0, 14)
	row.BackgroundColor3 = Color3.fromRGB(72, 78, 93)
	row.BackgroundTransparency = 0.05
	row.BorderSizePixel = 0
	row.AutoButtonColor = false
	row.Text = ''
	row.Parent = children
	stroke(row, 1, 0.35)
	local label = makeText(row, optionapi.Name, 11, false)
	label.Size = UDim2.new(1, -8, 1, 0)
	label.Position = UDim2.fromOffset(3, 0)
	optionapi.Object = row
	optionapi.Label = label
	function optionapi:SetValue(val)
		self.Value = val
		safeCall(self.Function, val)
	end
	table.insert(moduleapi.Options, optionapi)
	return optionapi
end

components.Divider = function(optionsettings, children, moduleapi)
	local frame = Instance.new('Frame')
	frame.Name = 'Divider'
	frame.Size = UDim2.new(1, -6, 0, optionsettings and optionsettings.Text and 14 or 5)
	frame.BackgroundTransparency = 1
	frame.Parent = children
	if optionsettings and optionsettings.Text then
		local label = makeText(frame, tostring(optionsettings.Text), 10, true)
		label.Size = UDim2.new(1, 0, 1, 0)
		label.Position = UDim2.fromOffset(3, 0)
	end
	local api = {Type = 'Divider', Name = optionsettings and optionsettings.Text or 'Divider', Object = frame}
	table.insert(moduleapi.Options, api)
	return api
end

components.Toggle = function(optionsettings, children, moduleapi)
	local api = createOptionBase('Toggle', optionsettings, children, moduleapi)
	api.Value = optionsettings and optionsettings.Default == true
	local box = Instance.new('Frame')
	box.Size = UDim2.fromOffset(8, 8)
	box.Position = UDim2.new(1, -11, 0.5, -4)
	box.BackgroundColor3 = api.Value and uipallet.Enabled or Color3.fromRGB(40, 43, 52)
	box.BorderSizePixel = 0
	box.Parent = api.Object
	stroke(box, 1, 0.1)
	function api:SetValue(val)
		self.Value = val == true
		box.BackgroundColor3 = self.Value and uipallet.Enabled or Color3.fromRGB(40, 43, 52)
		safeCall(self.Function, self.Value)
	end
	api.Object.MouseButton1Click:Connect(function() api:SetValue(not api.Value) end)
	return api
end

components.Slider = function(optionsettings, children, moduleapi)
	local api = createOptionBase('Slider', optionsettings, children, moduleapi)
	api.Min = optionsettings.Min or 0
	api.Max = optionsettings.Max or 100
	api.Decimal = optionsettings.Decimal or 1
	api.Value = optionsettings.Default or api.Min
	api.Suffix = optionsettings.Suffix or ''
	local value = makeText(api.Object, tostring(api.Value)..api.Suffix, 10, false)
	value.Size = UDim2.new(0, 38, 1, 0)
	value.Position = UDim2.new(1, -40, 0, 0)
	value.TextXAlignment = Enum.TextXAlignment.Right
	local bar = Instance.new('Frame')
	bar.Size = UDim2.new(1, -8, 0, 2)
	bar.Position = UDim2.new(0, 4, 1, -3)
	bar.BorderSizePixel = 0
	bar.BackgroundColor3 = Color3.fromRGB(38, 42, 52)
	bar.Parent = api.Object
	local fill = Instance.new('Frame')
	fill.BorderSizePixel = 0
	fill.BackgroundColor3 = Color3.fromRGB(210, 150, 0)
	fill.Parent = bar
	local function update()
		local pct = math.clamp((api.Value - api.Min) / math.max(api.Max - api.Min, 1), 0, 1)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		value.Text = tostring(math.floor(api.Value * 100) / 100)..api.Suffix
	end
	function api:SetValue(val)
		val = math.clamp(tonumber(val) or api.Min, api.Min, api.Max)
		if api.Decimal ~= 1 then val = math.floor(val / api.Decimal + 0.5) * api.Decimal end
		self.Value = val
		update()
		safeCall(self.Function, val)
	end
	local dragging = false
	local function setFromX(x)
		local pct = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		api:SetValue(api.Min + (api.Max - api.Min) * pct)
	end
	api.Object.MouseButton1Down:Connect(function() dragging = true setFromX(inputService:GetMouseLocation().X) end)
	mainapi:Clean(inputService.InputChanged:Connect(function(inputObj)
		if dragging and inputObj.UserInputType == Enum.UserInputType.MouseMovement then setFromX(inputObj.Position.X) end
	end))
	mainapi:Clean(inputService.InputEnded:Connect(function(inputObj)
		if inputObj.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end))
	update()
	return api
end

components.Dropdown = function(optionsettings, children, moduleapi)
	local api = createOptionBase('Dropdown', optionsettings, children, moduleapi)
	api.List = optionsettings.List or {}
	api.Value = optionsettings.Default or api.List[1] or ''
	local value = makeText(api.Object, tostring(api.Value), 10, false)
	value.Size = UDim2.new(0, 54, 1, 0)
	value.Position = UDim2.new(1, -58, 0, 0)
	value.TextXAlignment = Enum.TextXAlignment.Right
	function api:SetValue(val)
		self.Value = val
		value.Text = tostring(val)
		safeCall(self.Function, val)
	end
	api.Object.MouseButton1Click:Connect(function()
		if #api.List == 0 then return end
		local i = table.find(api.List, api.Value) or 0
		i += 1
		if i > #api.List then i = 1 end
		api:SetValue(api.List[i])
	end)
	return api
end

components.Textbox = function(optionsettings, children, moduleapi)
	local api = createOptionBase('Textbox', optionsettings, children, moduleapi)
	api.Value = optionsettings.Default or ''
	local box = Instance.new('TextBox')
	box.Size = UDim2.new(0, 58, 0, 12)
	box.Position = UDim2.new(1, -61, 0.5, -6)
	box.BackgroundColor3 = Color3.fromRGB(40, 43, 52)
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.Text = tostring(api.Value)
	box.TextColor3 = uipallet.Text
	box.TextSize = 10
	box.FontFace = uipallet.Font
	box.Parent = api.Object
	stroke(box, 1, 0.2)
	function api:SetValue(val)
		self.Value = val
		box.Text = tostring(val)
		safeCall(self.Function, val)
	end
	box.FocusLost:Connect(function() api:SetValue(box.Text) end)
	return api
end

components.Button = function(optionsettings, children, moduleapi)
	local api = createOptionBase('Button', optionsettings, children, moduleapi)
	local text = makeText(api.Object, optionsettings.ButtonText or 'Run', 10, true)
	text.Size = UDim2.new(0, 40, 1, 0)
	text.Position = UDim2.new(1, -43, 0, 0)
	text.TextXAlignment = Enum.TextXAlignment.Right
	text.TextColor3 = uipallet.Enabled
	api.Object.MouseButton1Click:Connect(function() safeCall(api.Function) end)
	return api
end

components.ColorSlider = function(optionsettings, children, moduleapi)
	local api = createOptionBase('ColorSlider', optionsettings, children, moduleapi)
	api.Value = optionsettings.Default or Color3.fromHSV(0, 1, 1)
	local swatch = Instance.new('Frame')
	swatch.Size = UDim2.fromOffset(8, 8)
	swatch.Position = UDim2.new(1, -11, 0.5, -4)
	swatch.BackgroundColor3 = typeof(api.Value) == 'Color3' and api.Value or Color3.fromHSV(0, 1, 1)
	swatch.BorderSizePixel = 0
	swatch.Parent = api.Object
	stroke(swatch, 1, 0.15)
	function api:SetValue(val)
		self.Value = val
		swatch.BackgroundColor3 = typeof(val) == 'Color3' and val or Color3.fromHSV(type(val) == 'number' and val or 0, 1, 1)
		safeCall(self.Function, val)
	end
	api.Object.MouseButton1Click:Connect(function() api:SetValue(Color3.fromHSV(tick() % 1, 1, 1)) end)
	return api
end

mainapi.Components = setmetatable(components, {
	__newindex = function(self, ind, func)
		for _, v in mainapi.Modules do
			rawset(v, 'Create'..ind, function(_, settings)
				return func(settings, v.SettingsList or v.Children, v)
			end)
		end
		rawset(self, ind, func)
	end
})

local function makeSettingsWindow(moduleapi, settingsFrame)
	local holder = Instance.new('Frame')
	holder.Name = moduleapi.Name..'SettingsWindow'
	holder.Size = UDim2.fromOffset(170, 160)
	holder.Position = UDim2.fromOffset(360, 80)
	holder.BackgroundColor3 = uipallet.Main
	holder.BackgroundTransparency = 0.05
	holder.BorderSizePixel = 0
	holder.Visible = false
	holder.Parent = clickgui
	stroke(holder, 1, 0.05)
	local header = Instance.new('Frame')
	header.Size = UDim2.new(1, 0, 0, 12)
	header.BackgroundColor3 = uipallet.Header
	header.BackgroundTransparency = 0.05
	header.BorderSizePixel = 0
	header.Parent = holder
	local title = makeText(header, moduleapi.Name, 10, true)
	title.Size = UDim2.new(1, -4, 1, 0)
	title.Position = UDim2.fromOffset(3, 0)
	local list = Instance.new('ScrollingFrame')
	list.Position = UDim2.fromOffset(0, 14)
	list.Size = UDim2.new(1, 0, 1, -14)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 2
	list.CanvasSize = UDim2.new()
	list.Parent = holder
	local layout = Instance.new('UIListLayout')
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 2)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = list
	layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		list.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 4)
	end)
	moduleapi.SettingsWindow = holder
	moduleapi.SettingsList = list
	return holder, list
end

function mainapi:CreateCategory(categorysettings)
	categorysettings = categorysettings or {}
	local original = categorysettings.Name or 'Other'
	local canonical = canonicalCategoryName(original)

	if self.Categories[canonical] then
		self.Categories[original] = self.Categories[canonical]
		return self.Categories[canonical]
	end

	local categoryapi = {Type = 'Category', Name = canonical, OriginalName = original, Modules = {}}

	local window = Instance.new('Frame')
	window.Name = canonical..'Window'
	window.BackgroundColor3 = uipallet.Main
	window.BackgroundTransparency = uipallet.MainAlpha
	window.BorderSizePixel = 0
	window.Size = UDim2.fromOffset(92, 12)
	window.Parent = columnsHolder
	stroke(window, 1, 0.05)

	local header = Instance.new('TextButton')
	header.Name = 'Header'
	header.Size = UDim2.new(1, 0, 0, 12)
	header.BackgroundColor3 = uipallet.Header
	header.BackgroundTransparency = uipallet.HeaderAlpha
	header.BorderSizePixel = 0
	header.Text = ''
	header.AutoButtonColor = false
	header.Parent = window
	stroke(header, 1, 0.45)

	local title = makeText(header, canonical, 10, true)
	title.Size = UDim2.new(1, -24, 1, 0)
	title.Position = UDim2.fromOffset(3, 0)

	local pinBox = Instance.new('TextLabel')
	pinBox.Size = UDim2.fromOffset(7, 7)
	pinBox.Position = UDim2.new(1, -18, 0, 2)
	pinBox.BackgroundColor3 = Color3.fromRGB(150, 35, 35)
	pinBox.BorderSizePixel = 0
	pinBox.Text = ''
	pinBox.Parent = header
	stroke(pinBox, 1, 0.1)

	local minBox = Instance.new('TextLabel')
	minBox.Size = UDim2.fromOffset(7, 7)
	minBox.Position = UDim2.new(1, -9, 0, 2)
	minBox.BackgroundColor3 = Color3.fromRGB(34, 150, 45)
	minBox.BorderSizePixel = 0
	minBox.Text = ''
	minBox.Parent = header
	stroke(minBox, 1, 0.1)

	local children = Instance.new('ScrollingFrame')
	children.Name = canonical..'Children'
	children.Position = UDim2.fromOffset(0, 12)
	children.Size = UDim2.new(1, 0, 1, -12)
	children.BackgroundTransparency = 1
	children.BorderSizePixel = 0
	children.ScrollBarImageTransparency = 1
	children.CanvasSize = UDim2.new()
	children.Parent = window

	local layout = Instance.new('UIListLayout')
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 1)
	layout.Parent = children

	categoryapi.Window = window
	categoryapi.Header = header
	categoryapi.Children = children
	categoryapi.Layout = layout
	categoryapi.Minimized = false

	function categoryapi:SetMinimized(state)
		self.Minimized = state
		children.Visible = not state
		relayoutCategories()
	end

	function categoryapi:CreateModule(modulesettings)
		modulesettings = modulesettings or {}
		local name = modulesettings.Name or ('Module'..tostring(#self.Modules + 1))
		if mainapi.Modules[name] and mainapi.Modules[name].Object and mainapi.Modules[name].Object.Parent then
			local existing = mainapi.Modules[name]
			existing.Function = modulesettings.Function or existing.Function
			existing.Tooltip = modulesettings.Tooltip or existing.Tooltip
			return existing
		end

		local moduleapi = {
			Enabled = false,
			Options = {},
			Bind = '',
			Connections = {},
			Index = modulesettings.Index or (#self.Modules + 1),
			ExtraText = modulesettings.ExtraText,
			Name = name,
			Category = canonical,
			Function = modulesettings.Function or function() end,
			Tooltip = modulesettings.Tooltip
		}

		local row = Instance.new('TextButton')
		row.Name = name
		row.Size = UDim2.new(1, 0, 0, 11)
		row.BackgroundColor3 = uipallet.Main
		row.BackgroundTransparency = 0.18
		row.BorderSizePixel = 0
		row.AutoButtonColor = false
		row.Text = ''
		row.Parent = children
		stroke(row, 1, 0.48)

		local text = makeText(row, name, 9, false)
		text.Size = UDim2.new(1, -15, 1, 0)
		text.Position = UDim2.fromOffset(2, 0)
		text.TextXAlignment = Enum.TextXAlignment.Center

		local settingsStrip = Instance.new('TextButton')
		settingsStrip.Size = UDim2.fromOffset(11, 11)
		settingsStrip.Position = UDim2.new(1, -11, 0, 0)
		settingsStrip.BackgroundColor3 = uipallet.Main
		settingsStrip.BackgroundTransparency = 0.18
		settingsStrip.BorderSizePixel = 0
		settingsStrip.Text = '▾'
		settingsStrip.TextSize = 9
		settingsStrip.TextColor3 = uipallet.Enabled
		settingsStrip.FontFace = uipallet.FontSemiBold
		settingsStrip.Parent = row
		stroke(settingsStrip, 1, 0.48)

		local settingsWindow, settingsList = makeSettingsWindow(moduleapi)

		function moduleapi:Clean(obj)
			if typeof(obj) == 'Instance' then
				table.insert(self.Connections, {Disconnect = function()
					obj:ClearAllChildren()
					obj:Destroy()
				end})
				return
			elseif type(obj) == 'function' then
				table.insert(self.Connections, {Disconnect = obj})
				return
			end
			table.insert(self.Connections, obj)
		end

		function moduleapi:Expand()
			if expanded and expanded ~= self and expanded.SettingsWindow then
				expanded.SettingsWindow.Visible = false
			end
			settingsWindow.Visible = not settingsWindow.Visible
			expanded = settingsWindow.Visible and self or nil
			settingsStrip.Text = settingsWindow.Visible and '▴' or '▾'
			if settingsWindow.Visible then
				local pos = row.AbsolutePosition / scale.Scale
				settingsWindow.Position = UDim2.fromOffset(math.floor(pos.X + row.AbsoluteSize.X + 6), math.floor(pos.Y))
			end
		end

		function moduleapi:SetBind(val)
			if type(val) == 'table' then
				self.Bind = val[1] or ''
			else
				self.Bind = val or ''
			end
		end

		function moduleapi:Toggle(multiple)
			if mainapi.ThreadFix then setthreadidentity(8) end
			self.Enabled = not self.Enabled
			row.BackgroundColor3 = self.Enabled and uipallet.Enabled or uipallet.Main
			settingsStrip.BackgroundColor3 = self.Enabled and uipallet.Enabled or uipallet.Main
			text.TextColor3 = self.Enabled and uipallet.DarkText or uipallet.Text
			settingsStrip.TextColor3 = self.Enabled and uipallet.DarkText or uipallet.Enabled
			if not self.Enabled then
				for _, v in self.Connections do
					v:Disconnect()
				end
				table.clear(self.Connections)
			end
			if not multiple then mainapi:UpdateTextGUI() end
			safeCall(self.Function, self.Enabled)
		end

		for i, v in components do
			moduleapi['Create'..i] = function(_, optionsettings)
				return v(optionsettings or {}, settingsList, moduleapi)
			end
		end

		setmetatable(moduleapi, {
			__index = function(_, ind)
				local comp = ind:match('^Create(.+)$')
				if comp then
					return function(_, optionsettings)
						local maker = components[comp]
						return maker and maker(optionsettings or {}, settingsList, moduleapi) or createOptionBase(comp, optionsettings or {}, settingsList, moduleapi)
					end
				end
				return nil
			end
		})

		row.MouseButton1Click:Connect(function()
			moduleapi:Toggle()
		end)
		row.MouseButton2Click:Connect(function()
			moduleapi:Expand()
		end)
		settingsStrip.MouseButton1Click:Connect(function()
			moduleapi:Expand()
		end)

		settingsWindow:GetPropertyChangedSignal('Visible'):Connect(function()
			if not settingsWindow.Visible then settingsStrip.Text = '▾' end
		end)

		self.Modules[name] = moduleapi
		mainapi.Modules[name] = moduleapi
		sortCategoryRows(self)
		relayoutCategories()
		return moduleapi
	end

	header.MouseButton1Click:Connect(function()
		categoryapi:SetMinimized(not categoryapi.Minimized)
	end)

	layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		sortCategoryRows(categoryapi)
		relayoutCategories()
	end)

	self.Categories[canonical] = categoryapi
	self.Categories[original] = categoryapi
	for alias, target in CATEGORY_ALIASES do
		if target == canonical then
			self.Categories[alias] = categoryapi
		end
	end
	table.insert(self.CategoryOrder, categoryapi)
	relayoutCategories()
	return categoryapi
end

function mainapi:UpdateTextGUI()
	updateHackList()
end

function mainapi:UpdateGUI() end
function mainapi:Load() self.Loaded = true end
function mainapi:Save() end
function mainapi:CreateNotification(_, text)
	warn('[Wurst UI Notification]', text or '')
end

function mainapi:Clean(obj)
	if typeof(obj) == 'Instance' then
		table.insert(self.Connections, {
			Disconnect = function()
				if obj then
					pcall(function()
						obj:ClearAllChildren()
						obj:Destroy()
					end)
				end
			end
		})
		return
	end

	if typeof(obj) == 'RBXScriptConnection' then
		table.insert(self.Connections, obj)
		return
	end

	if type(obj) == 'function' then
		table.insert(self.Connections, {Disconnect = obj})
		return
	end

	if type(obj) == 'table' and type(obj.Disconnect) == 'function' then
		table.insert(self.Connections, obj)
		return
	end
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
	gui.Parent = lplr and lplr.PlayerGui or cloneref(game:GetService('CoreGui'))
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

columnsHolder = Instance.new('Frame')
columnsHolder.Name = 'WurstColumns'
columnsHolder.Size = UDim2.fromScale(1, 1)
columnsHolder.BackgroundTransparency = 1
columnsHolder.Parent = clickgui

logoFrame = Instance.new('Frame')
logoFrame.Name = 'WurstLogo'
logoFrame.Size = UDim2.fromOffset(160, 120)
logoFrame.Position = UDim2.fromOffset(5, 5)
logoFrame.BackgroundTransparency = 1
logoFrame.Parent = clickgui

local logo = Instance.new('ImageLabel')
logo.Name = 'LogoImage'
logo.Size = UDim2.fromOffset(124, 32)
logo.Position = UDim2.fromOffset(0, 0)
logo.BackgroundTransparency = 1
logo.Image = getcustomasset('newvape/assets/wurst/wurst_128.png')
logo.ScaleType = Enum.ScaleType.Fit
logo.Parent = logoFrame

local fallback = makeShadowedText(logoFrame, 'WURST', 24, UDim2.fromOffset(0, -2), Color3.fromRGB(255, 140, 0))
fallback.Visible = logo.Image == ''

local version = makeShadowedText(logoFrame, 'v7.53.1 MC26.1.2', 11, UDim2.fromOffset(126, 6), uipallet.Text)
version.Size = UDim2.fromOffset(140, 18)

activeList = makeText(logoFrame, '', 13, false)
activeList.Size = UDim2.fromOffset(155, 90)
activeList.Position = UDim2.fromOffset(0, 34)
activeList.TextYAlignment = Enum.TextYAlignment.Top
activeList.TextXAlignment = Enum.TextXAlignment.Left
activeList.TextColor3 = Color3.new(1, 1, 1)

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

for _, v in WURST_ORDER do
	mainapi:CreateCategory({Name = v})
end

mainapi:Clean(clickgui.MouseButton1Click:Connect(function()
	if expanded and expanded.SettingsWindow then
		expanded.SettingsWindow.Visible = false
		expanded = nil
	end
end))

mainapi:Clean(gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
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
		relayoutCategories()
		repeat
			cursor.Visible = not inputService.MouseIconEnabled
			if cursor.Visible then
				local mouseLocation = inputService:GetMouseLocation()
				cursor.Position = UDim2.fromOffset(mouseLocation.X - 31, mouseLocation.Y - 32)
			end
			task.wait()
		until mainapi.Loaded == nil or not clickgui.Visible
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
				v:Toggle(true)
			end
		end
		if toggled then mainapi:UpdateTextGUI() end
	end
end))

task.defer(relayoutCategories)
return mainapi
