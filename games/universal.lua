repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end

-- Executor fix
if identifyexecutor then
	if table.find({'Argon', 'Wave'}, ({identifyexecutor()})[1]) then
		getgenv().setthreadidentity = nil
	end
end

local vape
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end

local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/SOILXP/VapeV4ForRoblox/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then error(res) end
		if path:find('.lua') then
			res = '--Watermark\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local run = function(func)
	func()
end

local cloneref = cloneref or function(obj)
	return obj
end

-- Service refs
local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local lightingService = cloneref(game:GetService('Lighting'))
local marketplaceService = cloneref(game:GetService('MarketplaceService'))
local teleportService = cloneref(game:GetService('TeleportService'))
local httpService = cloneref(game:GetService('HttpService'))
local guiService = cloneref(game:GetService('GuiService'))
local groupService = cloneref(game:GetService('GroupService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local contextService = cloneref(game:GetService('ContextActionService'))
local coreGui = cloneref(game:GetService('CoreGui'))

-- Executor-specific behavior
local isnetworkowner = identifyexecutor and table.find({'AWP', 'Nihon'}, ({identifyexecutor()})[1]) and isnetworkowner or function()
	return true
end

local gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
local lplr = playersService.LocalPlayer
local assetfunction = getcustomasset

-- Shared Vape libraries
vape = shared.vape
vape.Libraries.entity = loadstring(downloadFile('newvape/libraries/entity.lua'), 'entitylibrary')()
vape.Libraries.hash = loadstring(downloadFile('newvape/libraries/hash.lua'), 'hash')()
vape.Libraries.prediction = loadstring(downloadFile('newvape/libraries/prediction.lua'), 'prediction')()

-- === MODULE LOADING START ===
-- put your custom modules here using:
-- run(function()
--     local MyModule = vape.Categories.<Category>:CreateModule({
--         Name = 'MyModule',
--         Function = function(callback)
--             -- your logic here
--         end
--     })
-- end)
-- === MODULE LOADING END ===
