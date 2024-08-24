-- Enable script error reporting
C_CVar.SetCVar("scriptErrors", 1)

-- Print a message with the addon name (in color) as a prefix
local function PrettyPrint(...)
    local prefix = WrapTextInColorCode("Arbitrages: ", "cfF00CCF")
    print(prefix, ...)
end

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
    local ownedLevel = PetCache.OwnedLevel(name)

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
    local valueForLevel = 3000000 + 2000000*(petLevel-1)/24
    if buyoutPrice <= valueForLevel then
        -- This pet is worth buying!
        local itemKey = {
            itemID = auction[17],
            itemLevel = 0,
            itemSuffix = 0,
            battlePetSpeciesID = PetCache.SpeciesId(name),
        }
        C_AuctionHouse.SetFavoriteItem(itemKey, true)
        PrettyPrint("Consider buying", name, ownedLevel, "->", petLevel, "@", GetCoinTextureString(buyoutPrice))
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
        if buyoutPrice > 0 and buyoutPrice < vendorSellPrice(itemID) then
            foundArbitrage = true
            local itemKey = {
                itemID = itemID,
                itemLevel = 0,
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
        PrettyPrint("Auction house is closed")
        return
    end

    local numAuctions = C_AuctionHouse.GetNumReplicateItems()

    if numAuctions == 0 or numAuctions == NumAuctionsFoundLastCheck then
        -- No [new] auction results. Ask for results.
        C_AuctionHouse.ReplicateItems()
    else
        -- numAuctions > 0 and not numAuctions == NumAuctionsFoundLastCheck
        -- Received some auction results!
        FindArbitrages(NumAuctionsFoundLastCheck, numAuctions)
        FindPetBargains(NumAuctionsFoundLastCheck, numAuctions)
    end

    NumAuctionsFoundLastCheck = numAuctions

    -- Keep checking for results
    C_Timer.After(30, CheckForAuctionResults)
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
