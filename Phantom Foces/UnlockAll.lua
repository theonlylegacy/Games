--[[
Before using:

Make sure that you open roblox player as file location until you reach the files.
If there isn't already, create a new folder called ClientSettings
Inside clientappsettings, create a JSON file called ClientAppSettings (ClientAppSettings.json)
Enable FFlagDebugRunParallelLuaOnMainThread inside of the JSOn file.

{
    "FFlagDebugRunParallelLuaOnMainThread": true
}
]]

local Require = rawget(getrenv().shared, "require")
local Spawn = task.spawn

--//Slooooooooooooooooooooooooooow
local PlayerDataUtils = Require("PlayerDataUtils")
local SkinCaseUtils = Require("SkinCaseUtils")
local PageLoadoutMenuDisplayWeaponSelection = Require("PageLoadoutMenuDisplayWeaponSelection")
--\\Slooooooooooooooooooooooooooow

local UpdateList = getupvalue(PageLoadoutMenuDisplayWeaponSelection._init, 33)
if not isourclosure(PlayerDataUtils.ownsWeapon) and not isourclosure(PlayerDataUtils.ownsAttachment) and not isourclosure(SkinCaseUtils.ownsWeaponSkin) then
    PlayerDataUtils.ownsWeapon = function()
        return true
    end
    
    PlayerDataUtils.ownsAttachment = function()
        return true
    end
    
    SkinCaseUtils.ownsWeaponSkin = function()
        return true
    end

    pcall(UpdateList)
end
