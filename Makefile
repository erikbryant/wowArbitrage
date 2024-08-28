CACHE_DIR=../wow/generated
ADDON_DIR=/Applications/World\ of\ Warcraft/_retail_/Interface/AddOns

uninstall:
	rm -rf $(ADDON_DIR)/Arbitrages

cacheFiles:
	cp $(CACHE_DIR)/*.lua ./Arbitrages/

install: uninstall cacheFiles
	cp -R Arbitrages $(ADDON_DIR)

# Targets that do not represent actual files
.PHONY: uninstall cacheFiles install
