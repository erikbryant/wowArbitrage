-- Enable script error reporting
C_CVar.SetCVar("scriptErrors", 1)

-- Print a message with the addon name (in color) as a prefix
local function PrettyPrint(...)
    local prefix = WrapTextInColorCode("Arbitrages: ", "cfF00CCF")
    print(prefix, ...)
end

-- Create an AH favorite for each auction that is an arbitrage
local function FindArbitrages()
    local numAuctions = C_AuctionHouse.GetNumReplicateItems()
    local foundArbitrage = false

    PrettyPrint("Searching for arbitrages in", numAuctions ,"auctions...")

    ---- Optimization: Create local function pointers so we only
    ---- search for the function in the global namespace once,
    ---- instead of on every call.
    local getReplicateItemInfo = C_AuctionHouse.GetReplicateItemInfo
    local vendorSellPrice = ItemCache.VendorSellPrice

    for i = 0, numAuctions-1 do
        local auction = {getReplicateItemInfo(i)}
        local buyoutPrice = auction[10]
        local itemID = auction[17]
        if buyoutPrice < vendorSellPrice(itemID) then
            foundArbitrage = true
            C_AuctionHouse.SetFavoriteItem(C_AuctionHouse.MakeItemKey(itemID), true)
        end
    end

    if foundArbitrage then
        PrettyPrint("Arbitrage auctions saved as favorites. Enjoy! :)")
    else
        PrettyPrint("No arbitrages found this time. :(")
    end
end

local initialQuery

local function OnEvent(self, event)
    if event == "AUCTION_HOUSE_SHOW" then
        PrettyPrint("Sending scan...")
        C_AuctionHouse.ReplicateItems()
        initialQuery = true
        if C_AuctionHouse.HasFavorites() then
            PrettyPrint("*** Delete your AH favorites! ***")
        end
    elseif event == "REPLICATE_ITEM_LIST_UPDATE" then
        if initialQuery then
            initialQuery = false
            FindArbitrages()
        end
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("AUCTION_HOUSE_SHOW")
f:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")
f:SetScript("OnEvent", OnEvent)

PrettyPrint("Loaded and ready to scan!")
