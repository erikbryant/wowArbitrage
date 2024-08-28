ADDON=Arbitrage
CACHE_DIR=../wow/generated
ADDON_DIR=/Applications/World\ of\ Warcraft/_retail_/Interface/AddOns

uninstall:
	rm -rf $(ADDON_DIR)/$(ADDON)

cache:
	cp $(CACHE_DIR)/*.lua ./$(ADDON)
	git diff $(ADDON)

install: uninstall
	cp -R $(ADDON) $(ADDON_DIR)

# Targets that do not represent actual files
.PHONY: uninstall cache install
