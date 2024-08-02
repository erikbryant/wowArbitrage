-- Enable script error reporting
C_CVar.SetCVar("scriptErrors", 1)

-- Print a message with the addon name (in color) as a prefix
local function PrettyPrint(...)
    local prefix = WrapTextInColorCode("Arbitrages: ", "cfF00CCF")
    print(prefix, ...)
end

-- Create an AH favorite for each auction that is an arbitrage
local function FindArbitrages(firstAuction, numAuctions)
    local foundArbitrage = false

    PrettyPrint("Searching for arbitrages in", firstAuction, "-", numAuctions,"auctions...")

    ---- Optimization: Create local function pointers so we only
    ---- search for the function in the global namespace once,
    ---- instead of on every call.
    local getReplicateItemInfo = C_AuctionHouse.GetReplicateItemInfo
    local vendorSellPrice = ItemCache.VendorSellPrice

    for i = firstAuction, numAuctions -1 do
        local auction = {getReplicateItemInfo(i)}
        local buyoutPrice = auction[10]
        local itemID = auction[17]
        if buyoutPrice < vendorSellPrice(itemID) then
            foundArbitrage = true
            C_AuctionHouse.SetFavoriteItem(C_AuctionHouse.MakeItemKey(itemID), true)
        end
    end

    if foundArbitrage then
        PrettyPrint("Arbitrage auction(s) found and added to favorites!")
    end
end

local AuctionHouseOpen = false
local NumAuctionsFoundLastCheck = 0

-- Loop until AH closes. Each time new results are available process them.
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
    end

    NumAuctionsFoundLastCheck = numAuctions

    -- Keep checking for results
    C_Timer.After(8, CheckForAuctionResults)
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
