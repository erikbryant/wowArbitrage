# World of Warcraft Auction House Addon

Arbitrages searches the auction house for arbitrage opportunities. When it finds them it sets them as favorites in the auction house.

## Development links, tips

https://warcraft.wiki.gg/wiki/World_of_Warcraft_API

Slash commands usable in the chat window
* /console scriptErrors 1
* /reload - reload the UI
* /dump - general debugging
* /etrace - showing events
* /fstack - debugging visible UI elements
* /tableinspect - interactive table inspection

## Single Threaded

The WoW UI appears to be single threaded. We can create callbacks and have those
run whenever, but they still block the main UI thread. Keep the time spent in any
given callback very short.

You can see this effect by watching the UI freeze while the callback is running
if the callback takes any moderate length of time.

## Lua Script Debugging

`C_CVar.SetCVar("scriptErrors", 1)`

`DevTools_Dump(itemKey)`

Get latest UI version number:

```shell
/run print((select(4, GetBuildInfo())))
```
