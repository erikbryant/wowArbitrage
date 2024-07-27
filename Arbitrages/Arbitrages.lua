local Arbitrages = CreateFrame("Frame")
local initialQuery = false

-- Print a message with the addon name (in color) as a prefix
function Arbitrages:Message(...)
    prefix = WrapTextInColorCode("Arbitrages: ", "cfF00CCF")
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
    favorites = 0
    for i = 0, C_AuctionHouse.GetNumReplicateItems()-1 do
        local auction = {C_AuctionHouse.GetReplicateItemInfo(i)}
        local buyoutPrice = auction[10]
        local itemID = auction[17]
        if self:IsArbitrage(itemID, buyoutPrice) then
            self:SetAHFavorite(itemID)
            favorites = favorites + 1
        end
    end
    self:Message(favorites, " items loaded as favorites. Enjoy! :)")
end

function Arbitrages:OnEvent(event)
    if event == "AUCTION_HOUSE_SHOW" then
        self:Message("Sending AH scan request...")
        if C_AuctionHouse.HasFavorites() then
            self:Message("*** Delete your AH favorites! ***")
        end
        initialQuery = true
        C_AuctionHouse.ReplicateItems()
    elseif event == "REPLICATE_ITEM_LIST_UPDATE" then
        if initialQuery then
            initialQuery = false
            self:FindArbitrages()
        end
    end
end

Arbitrages:SetScript("OnEvent", Arbitrages.OnEvent)
Arbitrages:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")
Arbitrages:RegisterEvent("AUCTION_HOUSE_SHOW")

Arbitrages:Message("Loaded and ready to scan!")
