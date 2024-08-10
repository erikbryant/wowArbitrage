-- Enable script error reporting
C_CVar.SetCVar("scriptErrors", 1)

-- Print a message with the addon name (in color) as a prefix
local function PrettyPrint(...)
    local prefix = WrapTextInColorCode("Arbitrages: ", "cfF00CCF")
    print(prefix, ...)
end

local function Pet(auction)
    local itemID = auction[17]

    if not itemID == 82800 then
        -- This is not a pet cage auction
        return false
    end

    local qualityID = auction[4]
    local buyoutPrice = auction[10]

    if buyoutPrice > 1000000 or qualityID < 3 then
        -- Not worth buying
        return false
    end

    local name = auction[1]
    local speciesID = PetCache.PetId(name)

    if speciesID == 0 then
        -- We don't need this pet species
        return false
    end

    -- We found a pet worth buying!
    local itemKey = {
        itemID = itemID,
        itemLevel = auction[6],
        itemSuffix = 0,
        battlePetSpeciesID = speciesID,
    }
    C_AuctionHouse.SetFavoriteItem(itemKey, true)

    return true
end

-- Create an AH favorite for each pet auction worth buying
local function FindPetBargains(firstAuction, numAuctions)
    local foundCheapPet = false

    -- Optimization: Create local function pointers so we only
    -- search for the function in the global namespace once,
    -- instead of on every call.
    local getReplicateItemInfo = C_AuctionHouse.GetReplicateItemInfo

    for i = firstAuction, numAuctions-1 do
        local auction = {getReplicateItemInfo(i)}
        local itemID = auction[17]
        if itemID == 82800 and Pet(auction) then
            foundCheapPet = true
        end
    end

    if foundCheapPet then
        PrettyPrint("Inexpensive pet auction(s) found and added to favorites!")
    end
end

-- Create an AH favorite for each auction that is an arbitrage
local function FindArbitrages(firstAuction, numAuctions)
    local foundArbitrage = false

    PrettyPrint("Searching for arbitrages in", firstAuction, "-", numAuctions,"auctions...")

    -- Optimization: Create local function pointers so we only
    -- search for the function in the global namespace once,
    -- instead of on every call.
    local getReplicateItemInfo = C_AuctionHouse.GetReplicateItemInfo
    local vendorSellPrice = PriceCache.VendorSellPrice

    for i = firstAuction, numAuctions-1 do
        local auction = {getReplicateItemInfo(i)}
        local buyoutPrice = auction[10]
        local itemID = auction[17]
        if buyoutPrice < vendorSellPrice(itemID) then
            foundArbitrage = true
            local itemKey = {
                itemID = itemID,
                itemLevel = auction[6],
                itemSuffix = 0,
                battlePetSpeciesID = 0,
            }
            C_AuctionHouse.SetFavoriteItem(itemKey, true)
        end
    end

    if foundArbitrage then
        PrettyPrint("Arbitrage auction(s) found and added to favorites!")
    end
end

local AuctionHouseOpen = false
local NumAuctionsFoundLastCheck = 0

-- Loop until the AH closes, processing new results as they become available
local function CheckForAuctionResults()
    if not AuctionHouseOpen then
        PrettyPrint("Auction house is closed. Aborting scan.")
        return
    end

    local numAuctions = C_AuctionHouse.GetNumReplicateItems()

    if numAuctions == 0 or numAuctions == NumAuctionsFoundLastCheck then
        -- No [new] auction results. Ask for results.
        C_AuctionHouse.ReplicateItems()
    else
        -- numAuctions > 0 and not numAuctions == NumAuctionsFoundLastCheck
        -- Received some auction results
        FindArbitrages(NumAuctionsFoundLastCheck, numAuctions)
        FindPetBargains(NumAuctionsFoundLastCheck, numAuctions)
    end

    NumAuctionsFoundLastCheck = numAuctions

    -- Keep checking for results
    C_Timer.After(10, CheckForAuctionResults)
end

-- Dispatch an incoming event
local function OnEvent(self, event)
    if event == "AUCTION_HOUSE_SHOW" then
        AuctionHouseOpen = true
        PrettyPrint("Welcome to the auction house. Starting scan...")
        C_Timer.After(1, CheckForAuctionResults)
        if C_AuctionHouse.HasFavorites() then
            PrettyPrint("*** Delete your AH favorites! ***")
        end
    elseif event == "AUCTION_HOUSE_CLOSED" then
        AuctionHouseOpen = false
   end
end

local Arbitrages = CreateFrame("Frame", "Arbitrages", UIParent)
Arbitrages:Hide()
Arbitrages:SetScript("OnEvent", OnEvent)
Arbitrages:RegisterEvent("AUCTION_HOUSE_SHOW")
Arbitrages:RegisterEvent("AUCTION_HOUSE_CLOSED")

PrettyPrint("Loaded and ready to scan!")
