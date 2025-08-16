-- The buy quantify field goes blank after a purchase. Default it to 1.
local function SetMinBuy()
    -- This is OK to do even if the frame is not visible
    local quantityInput = AuctionHouseFrame.CommoditiesBuyFrame.BuyDisplay.QuantityInput
    if quantityInput:GetQuantity() == 0 then
        quantityInput:SetQuantity(1)
        quantityInput.InputBox:inputChangedCallback()
    end
end

-- When the commodities buy frame opens, if this is a favorite unfavorite it
-- This removes one manual step, speeding up the bulk buying process
local function Unfavorite()
    local itemDisplay = AuctionHouseFrame.CommoditiesBuyFrame.BuyDisplay.ItemDisplay
    if itemDisplay:IsVisible() then
        local favoriteButton = itemDisplay.FavoriteButton
        if favoriteButton:IsFavorite() then
            C_AuctionHouse.SetFavoriteItem(favoriteButton.itemKey, false)
            favoriteButton:UpdateFavoriteState()
        end
    end
end

AhaPatches = {
    SetMinBuy = SetMinBuy,
    Unfavorite = Unfavorite,
}