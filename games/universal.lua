repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end

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

local cloneref = cloneref or function(obj) return obj end
local playersService = cloneref(game:GetService('Players'))

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/SOILXP/VapeV4ForRoblox/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then error(res) end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function finishLoading()
	vape.Init = nil
	vape:Load()
	task.spawn(function()
		repeat vape:Save() task.wait(10) until not vape.Loaded
	end)
	local teleportedServers
	vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
		if (not teleportedServers) and (not shared.VapeIndependent) then
			teleportedServers = true
			local teleportScript = [[
shared.vapereload = true
if shared.VapeDeveloper then
	loadstring(readfile('newvape/loader.lua'), 'loader')()
else
	loadstring(game:HttpGet('https://raw.githubusercontent.com/SOILXP/VapeV4ForRoblox/'..readfile('newvape/profiles/commit.txt')..'/loader.lua', true), 'loader')()
end
]]
			if shared.VapeDeveloper then
				teleportScript = 'shared.VapeDeveloper = true\n'..teleportScript
			end
			if shared.VapeCustomProfile then
				teleportScript = 'shared.VapeCustomProfile = "'..shared.VapeCustomProfile..'"\n'..teleportScript
			end
			vape:Save()
			queue_on_teleport(teleportScript)
		end
	end))
	if not shared.vapereload then
		if not vape.Categories then return end
		if vape.Categories.Main.Options['GUI bind indicator'].Enabled then
			vape:CreateNotification('Finished Loading', vape.VapeButton and 'Press the button in the top right to open GUI' or 'Press '..table.concat(vape.Keybind, ' + '):upper()..' to open GUI', 5)
		end
	end
end

if not isfile('newvape/profiles/gui.txt') then
	writefile('newvape/profiles/gui.txt', 'new')
end

local gui = readfile('newvape/profiles/gui.txt')
if not isfolder('newvape/assets/'..gui) then
	makefolder('newvape/assets/'..gui)
end

-- 🔻 LOAD CLEAN BASE GUI (without modules)
vape = {
	Load = function() end,
	Save = function() end,
	Clean = function(_) end,
	CreateNotification = function(...) pcall(function() game.StarterGui:SetCore("SendNotification", {Title = tostring(...); Text = select(2, ...); Duration = select(3, ...)}) end) end,
	Keybind = {"RightShift"},
	Categories = {
		Main = {Options = {["GUI bind indicator"] = {Enabled = true}}}
	},
	VapeButton = true
}

shared.vape = vape

local connStamina
vape.Categories.World:CreateModule({
    Name = "InfiniteStamina",
    Tooltip = "Stamina bar Always Full",
    Function = function(callback)
        local connStamina
        local charConn

        local function setInfinite(char)
            local stats = char:WaitForChild("Stats", 5)
            if stats then
                local stamina = stats:FindFirstChild("Stamina")
                local staminaCheck = stats:FindFirstChild("StaminaCheck")
                local maxStamina = stats:FindFirstChild("MaxStamina")
                if stamina and staminaCheck and maxStamina then
                    connStamina = RunService.RenderStepped:Connect(function()
                        stamina.Value = 100
                        staminaCheck.Value = 100
                        maxStamina.Value = 100
                    end)
                end
            end
        end

        if callback then
            local char = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
            setInfinite(char)
            charConn = Players.LocalPlayer.CharacterAdded:Connect(function(newChar)
                if connStamina then connStamina:Disconnect() end
                setInfinite(newChar)
            end)
        else
            if connStamina then connStamina:Disconnect() connStamina = nil end
            if charConn then charConn:Disconnect() charConn = nil end
        end
    end
})

finishLoading()
