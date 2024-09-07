-- The buy quantify field goes blank after a purchase. Default it to 1.
local function SetMinBuy()
    if not AhaUtil.IsAHOpen() then
        return
    end

    -- This is OK to do even if the frame is not visible
    local quantityInput = AuctionHouseFrame.CommoditiesBuyFrame.BuyDisplay.QuantityInput
    if quantityInput:GetQuantity() == 0 then
        quantityInput:SetQuantity(1)
        quantityInput.InputBox:inputChangedCallback()
    end

    C_Timer.After(1, SetMinBuy)
end

-- When the commodities buy frame opens, if this is a favorite unfavorite it
-- This removes one manual step, speeding up the bulk buying process
local function Unfavorite()
    if not AhaUtil.IsAHOpen() then
        return
    end

    local itemDisplay = AuctionHouseFrame.CommoditiesBuyFrame.BuyDisplay.ItemDisplay
    if itemDisplay:IsVisible() then
        local favoriteButton = itemDisplay.FavoriteButton
        if favoriteButton:IsFavorite() then
            C_AuctionHouse.SetFavoriteItem(favoriteButton.itemKey, false)
            favoriteButton:UpdateFavoriteState()
        end
    end

    C_Timer.After(1, Unfavorite)
end

AhaPatches = {
    SetMinBuy = SetMinBuy,
    Unfavorite = Unfavorite,
}