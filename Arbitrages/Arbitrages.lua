local Arbitrages = CreateFrame("Frame")
local initialQuery = false
local finishedQuery = false
local arbitrages = {}

-- Return true if this is an arbitrage opportunity
function Arbitrages:IsArbitrage(itemID, buyoutPrice)
    if ItemCache:UnknownID(itemID) or ItemCache:ItemIsEquippable(itemID) then
        return false
    end
    return buyoutPrice < ItemCache:VendorSellPrice(itemID)
end

-- Make an AH favorite from each arbitrage item
function Arbitrages:SetAHFavorites()
    local count = 0
    local itemID, index = next(arbitrages, nil)
    while itemID do
        local itemKey = C_AuctionHouse.MakeItemKey(itemID)
        C_AuctionHouse.SetFavoriteItem(itemKey, true)
        count = count + 1
        itemID, index = next(arbitrages, itemID)
    end
    print("Arbitrages: ", count, " items loaded as favorites. Enjoy! :)")
end

-- Return true if all names have been loaded
function Arbitrages:HaveAllNames()
    local itemID, index = next(arbitrages, nil)
    while itemID do
        local auction = {C_AuctionHouse.GetReplicateItemInfo(index)}
        local name = auction[1]
        if name == nil or name == "" then
            return false
        end
        itemID, index = next(arbitrages, itemID)
    end
    return true
end

-- Scan ReplicateItems to see which auctions qualify as arbitrages
function Arbitrages:FindArbitrages()
    for i = 0, C_AuctionHouse.GetNumReplicateItems()-1 do
        local auction = {C_AuctionHouse.GetReplicateItemInfo(i)}
        local buyoutPrice = auction[10]
        local itemID = auction[17]

        if self:IsArbitrage(itemID, buyoutPrice) then
            arbitrages[itemID] = i
        end
    end
end

-- Reset global variables
function Arbitrages:ResetGlobals()
    wipe(arbitrages)
    initialQuery = true
    finishedQuery = false
end

function Arbitrages:OnEvent(event)
    if event == "AUCTION_HOUSE_SHOW" then
        print("Arbitrages: Sending AH scan request...")
        if C_AuctionHouse.HasFavorites() then
            print("Arbitrages: *** Delete your AH favorites! ***")
        end
        Arbitrages:ResetGlobals()
        C_AuctionHouse.ReplicateItems()
    elseif event == "REPLICATE_ITEM_LIST_UPDATE" then
        if finishedQuery then
            return
        end
        if initialQuery then
            initialQuery = false
            self:FindArbitrages()
        end
        if self:HaveAllNames() then
            finishedQuery = true
            self:SetAHFavorites()
        end
    else
        print("Arbitrages: Unexpected event: ", event)
    end
end

Arbitrages:SetScript("OnEvent", Arbitrages.OnEvent)
Arbitrages:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")
Arbitrages:RegisterEvent("AUCTION_HOUSE_SHOW")

print("Arbitrages: Loaded and ready to scan!")

-- print("Arbitrages: /console scriptErrors 1")
