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
local function FindBargains(firstAuction, numAuctions)
    -- Optimization: Create local function pointers. This way we only
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

AhaPets = {
    FindBargains = FindBargains,
}