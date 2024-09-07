-- Dump is a wrapper for DevTools_Dump
local function Dump(maxEntryCutoff, maxDepthCutoff, ...)
    local oldMaxEntryCutoff = _G["DEVTOOLS_MAX_ENTRY_CUTOFF"]
    local oldMaxDepthCutoff = _G["DEVTOOLS_DEPTH_CUTOFF"]

    _G["DEVTOOLS_MAX_ENTRY_CUTOFF"] = maxEntryCutoff
    _G["DEVTOOLS_DEPTH_CUTOFF"] = maxDepthCutoff
    DevTools_Dump(...)
    _G["DEVTOOLS_MAX_ENTRY_CUTOFF"] = oldMaxEntryCutoff
    _G["DEVTOOLS_DEPTH_CUTOFF"] = oldMaxDepthCutoff
end

-- Print a message with the addon name (in color) as a prefix
local function PrettyPrint(...)
    local prefix = WrapTextInColorCode(AhaGlobal.ADDON_NAME, "cfF00CCF")
    print(prefix, ...)
end

-- Version returns the addon version and whether it is in debug mode
local function Version()
    local debug = ""
    if C_CVar.GetCVar("scriptErrors") == "1" then
        debug = "(debug)"
    end
    return "v"..AhaGlobal.ADDON_VERSION.." "..debug
end

AhaUtil = {
    Dump = Dump,
    PrettyPrint = PrettyPrint,
    Version = Version,
}