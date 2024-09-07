-- SlashUsage prints a usage message for the slash commands
local function SlashUsage()
    Util.Version()
    Util.PrettyPrint("Usage '/aha [command]' where command is:")
    Util.PrettyPrint("  favorites delete  - delete session favorites")
    Util.PrettyPrint("  debug 0/1           - debugging")
    Util.PrettyPrint("  status                 - dump internal state")
end

-- SlashHandler processes the slash command the player typed
local function SlashHandler(msg, ...)
    msg = string.lower(msg)
    if msg == "" then
        SlashUsage()
    elseif msg == "favorites delete" or msg == "fd" then
        RemoveFavorites()
    elseif msg == "debug 1" or msg == "d1" then
        C_CVar.SetCVar("scriptErrors", 1)
        Util.PrettyPrint("Debugging enabled")
    elseif msg == "debug 0" or msg == "d0" then
        C_CVar.SetCVar("scriptErrors", 0)
        Util.PrettyPrint("Debugging disabled")
    elseif msg == "status" or msg == "s" then
        Version()
        Util.PrettyPrint("AuctionHouseOpen:", AuctionHouseOpen)
        Util.PrettyPrint("NumAuctionsFoundLastCheck:", NumAuctionsFoundLastCheck)
        Util.PrettyPrint("#FavoritesCreated:", #FavoritesCreated)
    else
        Util.PrettyPrint("Unknown slash command:", msg)
        SlashUsage()
    end
end

-- Register the slash handlers
_G["SLASH_"..Global.ADDON_NAME.."1"] = Global.SLASH_CMD
SlashCmdList[Global.ADDON_NAME] = SlashHandler
