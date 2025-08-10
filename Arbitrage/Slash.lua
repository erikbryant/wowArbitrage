-- SlashUsage prints a usage message for the slash commands
local function SlashUsage()
    AhaUtil.PrettyPrint(AhaUtil.Version(), GetRealmName())
    Utility.PrettyPrint("Usage '"..AhaGlobal.SLASH_CMD.." [command]' where command is:")
    AhaUtil.PrettyPrint("  favorites delete  - delete session favorites")
    AhaUtil.PrettyPrint("  debug 0/1           - debugging")
    AhaUtil.PrettyPrint("  status                 - dump internal state")
end

-- SlashHandler processes the slash command the player typed
local function SlashHandler(msg, ...)
    msg = string.lower(msg)
    if msg == "favorites delete" or msg == "fd" then
        AhaMain.RemoveFavorites()
    elseif msg == "debug 1" or msg == "d1" then
        C_CVar.SetCVar("scriptErrors", 1)
        AhaUtil.PrettyPrint("Debugging enabled")
    elseif msg == "debug 0" or msg == "d0" then
        C_CVar.SetCVar("scriptErrors", 0)
        AhaUtil.PrettyPrint("Debugging disabled")
    elseif msg == "status" or msg == "s" then
        AhaMain.Status()
    else
        if msg ~= "" then
            AhaUtil.PrettyPrint("Unknown slash command:", msg)
        end
        SlashUsage()
    end
end

-- Register the slash handlers
_G["SLASH_"..AhaGlobal.ADDON_NAME.."1"] = AhaGlobal.SLASH_CMD
SlashCmdList[AhaGlobal.ADDON_NAME] = SlashHandler
