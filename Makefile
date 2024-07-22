VENDOR_PRICES=ItemCache.lua
ADDON_DIR=/Applications/World\ of\ Warcraft/_retail_/Interface/AddOns

itemCache:
	cd ../wow/ ; go run listItems/listItems.go -lua > ../wowAddons/Arbitrages/$(VENDOR_PRICES)

publish: itemCache
	rm -rf $(ADDON_DIR)/Arbitrages
	cp -R Arbitrages $(ADDON_DIR)

# Targets that do not represent actual files
.PHONY: itemCache publish
