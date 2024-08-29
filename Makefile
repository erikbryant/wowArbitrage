ADDON=Arbitrage
CACHE=../wow/generated
CACHE_PET=PetCache.lua
CACHE_PRICE=PriceCache.lua
WOW=/Applications/World\ of\ Warcraft/_retail_/Interface/AddOns

$(ADDON)/$(CACHE_PET): $(CACHE)/$(CACHE_PET)
	cp $(CACHE)/$(CACHE_PET) $(ADDON)
	git diff $@

$(ADDON)/$(CACHE_PRICE): $(CACHE)/$(CACHE_PRICE)
	cp $(CACHE)/$(CACHE_PRICE) $(ADDON)
	git diff $@

uninstall:
	rm -rf $(WOW)/$(ADDON)

install: uninstall
	cp -R $(ADDON) $(WOW)

upgrade: $(ADDON)/$(CACHE_PET) $(ADDON)/$(CACHE_PRICE) install

# Targets that do not represent actual files
.PHONY: uninstall cache install upgrade
