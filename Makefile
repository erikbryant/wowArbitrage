CACHE_DIR=../wow/generated
ADDON_DIR=/Applications/World\ of\ Warcraft/_retail_/Interface/AddOns

cacheFiles:
	cp $(CACHE_DIR)/*.lua ./Arbitrages/

publish: cacheFiles
	rm -rf $(ADDON_DIR)/Arbitrages
	cp -R Arbitrages $(ADDON_DIR)

# Targets that do not represent actual files
.PHONY: cacheFiles publish
