local NumAuctionsFoundLastCheck = 0
local FavoritesCreated = {}
local Timers = {}

-- Create an AH favorite for each auction that is an arbitrage
local function FindArbitrages(firstAuction, numAuctions)
    AhaUtil.PrettyPrint("Searching auctions", firstAuction, "-", numAuctions)

    -- Optimization: Create local function pointers. This way we only
    -- search for the function in the global namespace once,
    -- instead of on every call.
    local getReplicateItemInfo = C_AuctionHouse.GetReplicateItemInfo
    local vendorSellPrice = AhaPriceCache.VendorSellPrice
    local foundArbitrage = false

    for i = firstAuction, numAuctions-1 do
        local auction = {getReplicateItemInfo(i)}
        local buyoutPrice = auction[10]
        local itemID = auction[17]
        if buyoutPrice > 0 and buyoutPrice < vendorSellPrice(itemID) then
            foundArbitrage = true
            local itemKey = {
                itemID = itemID,
                itemLevel = 0,
                itemSuffix = 0,
                battlePetSpeciesID = 0,
            }
            C_AuctionHouse.SetFavoriteItem(itemKey, true)
            table.insert(FavoritesCreated, itemKey)
        end
    end

    if foundArbitrage then
        PlaySound(SOUNDKIT.AUCTION_WINDOW_CLOSE)
        AhaUtil.PrettyPrint("Arbitrage auctions found and added to favorites!")
    end
end

-- Process any new AH scan results
local function CheckForAuctionResults()
    local numAuctions = C_AuctionHouse.GetNumReplicateItems()

    if numAuctions == 0 or numAuctions == NumAuctionsFoundLastCheck then
        -- No [new] auction results. Ask for results.
        C_AuctionHouse.ReplicateItems()
    else
        -- numAuctions > 0 and not numAuctions == NumAuctionsFoundLastCheck
        -- Received some auction results!
        if NumAuctionsFoundLastCheck > numAuctions then
            NumAuctionsFoundLastCheck = 0
        end
        FindArbitrages(NumAuctionsFoundLastCheck, numAuctions)
    end

    NumAuctionsFoundLastCheck = numAuctions
end

-- RemoveFavorites removes all of the favorites that were created this login session
local function RemoveFavorites()
    for _, itemKey in pairs(FavoritesCreated) do
        C_AuctionHouse.SetFavoriteItem(itemKey, false)
    end
    FavoritesCreated = {}
end

-- Status displays debug information
local function Status()
    AhaUtil.PrettyPrint("NumAuctionsFoundLastCheck:", NumAuctionsFoundLastCheck)
    AhaUtil.PrettyPrint("#FavoritesCreated:", #FavoritesCreated)
    AhaUtil.PrettyPrint("#Timers:", #Timers)
end

-- CancelTimers cancels each timer StartTimers started
local function CancelTimers()
    for _, timer in pairs(Timers) do
        timer:Cancel()
    end
    Timers = {}
end

-- StartTimers creates recurring timers for each callback
local function StartTimers()
    CancelTimers()
    Timers[#Timers+1] = C_Timer.NewTicker(5, CheckForAuctionResults)
    Timers[#Timers+1] = C_Timer.NewTicker(1, AhaPatches.Unfavorite)
    Timers[#Timers+1] = C_Timer.NewTicker(1, AhaPatches.SetMinBuy)
end

-- Dispatch an incoming event
local function OnEvent(self, event)
    if event == "AUCTION_HOUSE_SHOW" then
        AhaUtil.PrettyPrint("Welcome to the auction house! Starting scan...")
        StartTimers()
        if C_AuctionHouse.HasFavorites() then
            AhaUtil.PrettyPrint("*** Delete your AH favorites! ***")
        end
    elseif event == "AUCTION_HOUSE_CLOSED" then
        CancelTimers()
        AhaUtil.PrettyPrint("Auction house is closed.")
   end
end

local Arbitrage = CreateFrame("Frame", "Arbitrage", UIParent)
Arbitrage:Hide()
Arbitrage:SetScript("OnEvent", OnEvent)
Arbitrage:RegisterEvent("AUCTION_HOUSE_SHOW")
Arbitrage:RegisterEvent("AUCTION_HOUSE_CLOSED")

AhaMain = {
    RemoveFavorites = RemoveFavorites,
    Status = Status,
}

AhaUtil.PrettyPrint(AhaUtil.Version(), "For help type:", AhaGlobal.SLASH_CMD)
