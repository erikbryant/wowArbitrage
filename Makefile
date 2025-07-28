ADDON=Arbitrage
CACHE=../wow/generated
CACHE_PRICE=PriceCache.lua
WOW=/Applications/World\ of\ Warcraft/_retail_/Interface/AddOns

$(ADDON)/$(CACHE_PRICE): $(CACHE)/$(CACHE_PRICE)
	cp $(CACHE)/$(CACHE_PRICE) $(ADDON)
	git --no-pager diff $@

uninstall:
	rm -rf $(WOW)/$(ADDON)

install: uninstall
	git pull
	cp -R $(ADDON) $(WOW)

cache: $(ADDON)/$(CACHE_PRICE) install

# Targets that do not represent actual files
.PHONY: uninstall install cache
