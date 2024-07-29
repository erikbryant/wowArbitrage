-- Enable script error reporting
C_CVar.SetCVar("scriptErrors", 1)

local Arbitrages = CreateFrame("Frame", "Arbitrages", UIParent)
Arbitrages:Hide()

-- Print a message with the addon name (in color) as a prefix
local function message(...)
    local prefix = WrapTextInColorCode("Arbitrages: ", "cfF00CCF")
    print(prefix, ...)
end

-- Create an AH favorite for each auction that is an arbitrage
-- This function is called from OnEvent, so it blocks the main
-- event loop. Get it done really quickly or the WoW binary will
-- crash. Inline as much as possible.
function Arbitrages:FindArbitrages()
    local foundArbitrage = false
    for i = 0, C_AuctionHouse.GetNumReplicateItems()-1 do
        local auction = {C_AuctionHouse.GetReplicateItemInfo(i)}
        local buyoutPrice = auction[10]
        local itemID = auction[17]
        if buyoutPrice < ItemCache.VendorSellPrice(itemID) and not ItemCache.ItemIsEquippable(itemID) and not ItemCache.UnknownID(itemID) then
            foundArbitrage = true
            C_AuctionHouse.SetFavoriteItem(C_AuctionHouse.MakeItemKey(itemID), true)
        end
    end
    if foundArbitrage then
        message("Items loaded into favorites. Enjoy! :)")
    else
        message("No arbitrages found this time. :(")
    end
end

-- Dispatch an incoming event
function Arbitrages:OnEvent(event)
    if event == "AUCTION_HOUSE_SHOW" then
        if C_AuctionHouse.HasFavorites() then
            message("*** Delete your AH favorites! ***")
        end
        message("Sending AH scan request...")
        self:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")
        C_AuctionHouse.ReplicateItems()
    elseif event == "REPLICATE_ITEM_LIST_UPDATE" then
        self:UnregisterEvent("REPLICATE_ITEM_LIST_UPDATE")
        self:FindArbitrages()
    end
end

Arbitrages:SetScript("OnEvent", Arbitrages.OnEvent)
Arbitrages:RegisterEvent("AUCTION_HOUSE_SHOW")

message("Loaded and ready to scan!")
