-- Enable script error reporting
C_CVar.SetCVar("scriptErrors", 1)

-- Print a message with the addon name (in color) as a prefix
local function message(...)
    local prefix = WrapTextInColorCode("Arbitrages: ", "cfF00CCF")
    print(prefix, ...)
end

-- Create an AH favorite for each auction that is an arbitrage
local function FindArbitrages()
    local numAuctions = C_AuctionHouse.GetNumReplicateItems()
    local foundArbitrage = false

    message("Searching for arbitrages in", numAuctions ,"auctions...")

    ---- Optimization: Create local function pointers so we only
    ---- search for the function in the global namespace once,
    ---- instead of on every call.
    local getReplicateItemInfo = C_AuctionHouse.GetReplicateItemInfo
    local itemIsEquippable = ItemCache.ItemIsEquippable
    local unknownID = ItemCache.UnknownID
    local vendorSellPrice = ItemCache.VendorSellPrice

    for i = 0, numAuctions-1 do
        local auction = {getReplicateItemInfo(i)}
        local buyoutPrice = auction[10]
        local itemID = auction[17]
        if buyoutPrice < vendorSellPrice(itemID) and not itemIsEquippable(itemID) and not unknownID(itemID) then
            foundArbitrage = true
            C_AuctionHouse.SetFavoriteItem(C_AuctionHouse.MakeItemKey(itemID), true)
        end
    end

    if foundArbitrage then
        message("Arbitrage auctions saved as favorites. Enjoy! :)")
    else
        message("No arbitrages found this time. :(")
    end
end

local AuctionHouseOpen
local NumAuctionsFoundSoFar

-- If AH scan results are done accumulating, queue processing. Otherwise, wait and check again.
local function CheckForResults()
    if not AuctionHouseOpen then
        message("Auction house is closed. Aborting scan.")
        return
    end

    -- It doesn't hurt to call this multiple times.
    C_AuctionHouse.ReplicateItems()

    local numAuctions = C_AuctionHouse.GetNumReplicateItems()

    if numAuctions <= 0 or numAuctions > NumAuctionsFoundSoFar then
        -- No results yet, or not done accumulating results
        NumAuctionsFoundSoFar = numAuctions
    else
        -- Done accumulating. Process the results.
        NumAuctionsFoundSoFar = -1
        C_Timer.After(1, FindArbitrages)
    end

    C_Timer.After(10, CheckForResults)
end

local Arbitrages = CreateFrame("Frame", "Arbitrages", UIParent)
Arbitrages:Hide()

-- Dispatch an incoming event
function Arbitrages:OnEvent(event)
    if event == "AUCTION_HOUSE_SHOW" then
        AuctionHouseOpen = true
        NumAuctionsFoundSoFar = -1
        C_Timer.After(1, CheckForResults)
        if C_AuctionHouse.HasFavorites() then
            message("*** Delete your AH favorites! ***")
        end
    elseif event == "AUCTION_HOUSE_CLOSED" then
        AuctionHouseOpen = false
   end
end

Arbitrages:SetScript("OnEvent", Arbitrages.OnEvent)
Arbitrages:RegisterEvent("AUCTION_HOUSE_SHOW")
Arbitrages:RegisterEvent("AUCTION_HOUSE_CLOSED")

message("Loaded and ready to scan!")
