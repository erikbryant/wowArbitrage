local NumAuctionsFoundLastCheck = 0
local FavoritesCreated = {}
local Timers = {}

-- If this pet auction is a good bargain, add it as an AH favorite
local function IsCheapPet(auction)
    local qualityID = auction[4]
    if qualityID < 3 then
        -- Not worth buying anything less than Rare(3)
        return false
    end

    local name = auction[1]
    local petLevel = auction[6]
    local buyoutPrice = auction[10]
    local ownedLevel = AhaPetCache.OwnedLevel(name)

    -- Is this pet an upgrade?
    --if petLevel <= ownedLevel then
    --    -- We already have a better pet
    --    return
    --end
    if ownedLevel > 0 then
        -- We already have this pet
        return
    end

    -- The pet is of interest, but is it cheap?
    local valueForLevel = 4000000 + 2000000*(petLevel-1)/24
    if buyoutPrice <= valueForLevel then
        -- This pet is worth buying!
        local itemKey = {
            itemID = auction[17],
            itemLevel = 0,
            itemSuffix = 0,
            battlePetSpeciesID = AhaPetCache.SpeciesId(name),
        }
        C_AuctionHouse.SetFavoriteItem(itemKey, true)
        table.insert(FavoritesCreated, itemKey)
        AhaUtil.PrettyPrint("Consider buying", name, ownedLevel, "->", petLevel, "@", GetCoinTextureString(buyoutPrice))
    end
end

-- Create an AH favorite for each pet auction worth buying
local function FindPetBargains(firstAuction, numAuctions)
    -- Optimization: Create local function pointers so we only
    -- search for the function in the global namespace once,
    -- instead of on every call.
    local getReplicateItemInfo = C_AuctionHouse.GetReplicateItemInfo

    for i = firstAuction, numAuctions-1 do
        local auction = {getReplicateItemInfo(i)}
        -- auction[17] is the itemID
        if auction[17] == 82800 then
            IsCheapPet(auction)
        end
    end
end

-- Create an AH favorite for each auction that is an arbitrage
local function FindArbitrages(firstAuction, numAuctions)
    -- How loaded is the AH? At its lightest load it can do almost 200,000 auctions
    -- in 30 seconds (the current delay between calls to this function).
    local ahCapacity = string.format("[%0.2f]", (numAuctions - firstAuction) / 200000)
    AhaUtil.PrettyPrint("Searching auctions", firstAuction, "-", numAuctions, ahCapacity)

    -- Optimization: Create local function pointers so we only
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
            PlaySound(SOUNDKIT.AUCTION_WINDOW_CLOSE);
        end
    end

    if foundArbitrage then
        AhaUtil.PrettyPrint("Arbitrage auctions found and added to favorites!")
    end
end

-- Loop until the AH closes, processing new results as they become available
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
        -- Disabled because I am not searching for pets right now
        --FindPetBargains(NumAuctionsFoundLastCheck, numAuctions)
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
    Timers[#Timers+1] = C_Timer.NewTicker(30, CheckForAuctionResults)
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
