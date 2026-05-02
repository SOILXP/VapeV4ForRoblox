local vape = shared.vape
local realLoadstring = loadstring

local loadstring = function(...)
	local res, err = realLoadstring(...)
	if err and vape then
		vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end

local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end

local REPO = 'SOILXP/VapeV4ForRoblox'

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet(
				'https://raw.githubusercontent.com/'..REPO..'/'..
				readfile('newvape/profiles/commit.txt')..'/'..
				select(1, path:gsub('newvape/', '')),
				true
			)
		end)

		if not suc or res == '404: Not Found' then
			error(res)
		end

		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end

		writefile(path, res)
	end

	return (func or readfile)(path)
end

vape.Place = 6872274481

local targetPath = 'newvape/games/'..vape.Place..'.lua'

if isfile(targetPath) then
	loadstring(readfile(targetPath), 'bedwars')()
else
	if not shared.VapeDeveloper then
		local suc, res = pcall(function()
			return game:HttpGet(
				'https://raw.githubusercontent.com/'..REPO..'/'..
				readfile('newvape/profiles/commit.txt')..
				'/games/'..vape.Place..'.lua',
				true
			)
		end)

		if suc and res ~= '404: Not Found' then
			loadstring(downloadFile(targetPath), 'bedwars')()
		else
			warn('failed to fetch BedWars module:', res)
		end
	end
end
