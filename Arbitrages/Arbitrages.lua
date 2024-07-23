local Arbitrages = CreateFrame("Frame")
local initialQuery = false
local finishedQuery = false
local arbitrages = {}

-- Return true if this is an arbitrage opportunity
function Arbitrages:IsArbitrage(itemID, buyoutPrice)
    if ItemCache:UnknownID(itemID) or ItemCache:ItemIsEquippable(itemID) then
        return false
    end

    if itemID == 141293 then
        -- Is equippable, but not listed as such in the generate file.
        -- Don't know why.
        return false
    end

    if buyoutPrice < ItemCache:VendorSellPrice(itemID) then
        return true
    end

    return false
end

-- Print each arbitrage item name
function Arbitrages:PrintArbitrages()
    print("----- Arbitrages -----")
    local itemID, index = next(arbitrages, nil)
    while itemID do
        local auction = {C_AuctionHouse.GetReplicateItemInfo(index)}
        local name = auction[1]
        print(name)
        itemID, index = next(arbitrages, itemID)
    end
end

-- Make an AH favorite from each arbitrage item
function Arbitrages:SetAHFavorites()
    local itemID, index = next(arbitrages, nil)
    while itemID do
        local itemKey = C_AuctionHouse.MakeItemKey(itemID)
        C_AuctionHouse.SetFavoriteItem(itemKey, true)
        itemID, index = next(arbitrages, itemID)
    end
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

-- Scan ReplicateItems to see which qualify as arbitrages
function Arbitrages:FindArbitrages()
    for i = 0, C_AuctionHouse.GetNumReplicateItems()-1 do
        local auction = {C_AuctionHouse.GetReplicateItemInfo(i)}
        local buyoutPrice = auction[10]
        local itemID = auction[17]

        if self:IsArbitrage(itemID, buyoutPrice) then
            local name = auction[1]
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
        Arbitrages:ResetGlobals()
        Arbitrages:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")
        Arbitrages:RegisterEvent("AUCTION_HOUSE_CLOSED")
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
            Arbitrages:UnregisterEvent("REPLICATE_ITEM_LIST_UPDATE")
            self:PrintArbitrages()
            self:SetAHFavorites()
        end
    elseif event == "AUCTION_HOUSE_CLOSED" then
        Arbitrages:ResetGlobals()
        Arbitrages:UnregisterEvent("AUCTION_HOUSE_CLOSED")
    else
        print("Arbitrages: Unexpected event: ", event)
    end
end

Arbitrages:RegisterEvent("AUCTION_HOUSE_SHOW")
Arbitrages:SetScript("OnEvent", Arbitrages.OnEvent)

print("Arbitrages: Delete your AH favorites!")
print("Arbitrages: /console scriptErrors 1")
