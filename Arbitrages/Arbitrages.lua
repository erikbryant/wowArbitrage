-- Enable script error reporting
C_CVar.SetCVar("scriptErrors", 1)

-- Print a message with the addon name (in color) as a prefix
local function PrettyPrint(...)
    local prefix = WrapTextInColorCode("Arbitrages: ", "cfF00CCF")
    print(prefix, ...)
end

-- Create an AH favorite for each auction that is an arbitrage
local function FindArbitrages()
    local numAuctions = C_AuctionHouse.GetNumReplicateItems()
    local foundArbitrage = false

    PrettyPrint("Searching for arbitrages in", numAuctions ,"auctions...")

    ---- Optimization: Create local function pointers so we only
    ---- search for the function in the global namespace once,
    ---- instead of on every call.
    local getReplicateItemInfo = C_AuctionHouse.GetReplicateItemInfo
    local vendorSellPrice = ItemCache.VendorSellPrice

    for i = 0, numAuctions-1 do
        local auction = {getReplicateItemInfo(i)}
        local buyoutPrice = auction[10]
        local itemID = auction[17]
        if buyoutPrice < vendorSellPrice(itemID) then
            foundArbitrage = true
            C_AuctionHouse.SetFavoriteItem(C_AuctionHouse.MakeItemKey(itemID), true)
        end
    end

    if foundArbitrage then
        PrettyPrint("Arbitrage auctions saved as favorites. Enjoy! :)")
    else
        PrettyPrint("No arbitrages found this time. :(")
    end
end

local AuctionHouseOpen = false
local NumAuctionsFoundLastCheck = 0
local AuctionsHaveBeenProcessed = false

-- Loop until AH closes. Each time new results are available process them.
local function CheckForAuctionResults()
    if not AuctionHouseOpen then
        PrettyPrint("Auction house is closed. Aborting scan.")
        return
    end

    local numAuctions = C_AuctionHouse.GetNumReplicateItems()

    if numAuctions == 0 then
        -- No auction results. Ask for results.
        C_AuctionHouse.ReplicateItems()
    elseif numAuctions == NumAuctionsFoundLastCheck then
        -- Auction results are done accumulating
        if not AuctionsHaveBeenProcessed then
            AuctionsHaveBeenProcessed = true
            FindArbitrages()
            -- Ask for new results
            C_AuctionHouse.ReplicateItems()
        end
    else
        -- Something changed, these are new auction results
        AuctionsHaveBeenProcessed = false
        PrettyPrint("Accumulating auctions", numAuctions)
    end

    NumAuctionsFoundLastCheck = numAuctions

    -- The AH is slow to accumulate results, give it some time before checking again
    C_Timer.After(8, CheckForAuctionResults)
end

-- Dispatch an incoming event
local function OnEvent(self, event)
    if event == "AUCTION_HOUSE_SHOW" then
        AuctionHouseOpen = true
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
