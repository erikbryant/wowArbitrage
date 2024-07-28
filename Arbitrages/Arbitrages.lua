local Arbitrages = CreateFrame("Frame")
local waitingForResponse = true

-- Print a message with the addon name (in color) as a prefix
function Arbitrages:Message(...)
    local prefix = WrapTextInColorCode("Arbitrages: ", "cfF00CCF")
    print(prefix, ...)
end

-- Return true if this is an arbitrage opportunity
function Arbitrages:IsArbitrage(itemID, buyoutPrice)
    if ItemCache:UnknownID(itemID) or ItemCache:ItemIsEquippable(itemID) then
        return false
    end
    return buyoutPrice < ItemCache:VendorSellPrice(itemID)
end

-- Make an AH favorite of the item
function Arbitrages:SetAHFavorite(itemID)
    local itemKey = C_AuctionHouse.MakeItemKey(itemID)
    C_AuctionHouse.SetFavoriteItem(itemKey, true)
end

-- Scan ReplicateItems to see which auctions qualify as arbitrages
function Arbitrages:FindArbitrages()
    local foundAny = false
    for i = 0, C_AuctionHouse.GetNumReplicateItems()-1 do
        local auction = {C_AuctionHouse.GetReplicateItemInfo(i)}
        local buyoutPrice = auction[10]
        local itemID = auction[17]
        if self:IsArbitrage(itemID, buyoutPrice) then
            foundAny = true
            self:SetAHFavorite(itemID)
        end
    end
    if foundAny then
        self:Message("Items loaded into favorites. Enjoy! :)")
    else
        self:Message("No arbitrages found this time. :(")
    end
end

-- Dispatch an incoming event
function Arbitrages:OnEvent(event)
    if event == "AUCTION_HOUSE_SHOW" then
        self:Message("Sending AH scan request...")
        if C_AuctionHouse.HasFavorites() then
            self:Message("*** Delete your AH favorites! ***")
        end
        waitingForResponse = true
        C_AuctionHouse.ReplicateItems()
    elseif event == "REPLICATE_ITEM_LIST_UPDATE" then
        if waitingForResponse then
            waitingForResponse = false
            self:FindArbitrages()
        end
    end
end

Arbitrages:SetScript("OnEvent", Arbitrages.OnEvent)
Arbitrages:RegisterEvent("AUCTION_HOUSE_SHOW")
Arbitrages:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")

Arbitrages:Message("Loaded and ready to scan!")
