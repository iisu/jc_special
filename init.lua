local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())
local http = core.request_http_api and core.request_http_api()

if http then
    core.log("action", "[jc_special] HTTP API access ENABLED")
else
    core.log("error", "[jc_special] HTTP API access DISABLED")
end

jc_special = {}

dofile(modpath .. "/prison.lua")
dofile(modpath .. "/daybutton.lua")
dofile(modpath .. "/welcomeplayers.lua")
-- dofile(modpath .. "/player_lookup.lua")
dofile(modpath .. "/infotext.lua")
dofile(modpath .. "/sneakjump.lua")
dofile(modpath .. "/findnode.lua")
dofile(modpath .. "/cans.lua")
dofile(modpath .. "/paste2chat.lua")
dofile(modpath .. "/snowball.lua")
dofile(modpath .. "/homedecor_overrides.lua")
dofile(modpath .. "/unified_inventory_overrides.lua")
dofile(modpath .. "/animalworld_cleanup.lua")
dofile(modpath .. "/misc_overrides.lua")
dofile(modpath .. "/mobs_monsters.lua")
dofile(modpath .. "/direct_mob_spawner.lua")
-- dofile(modpath .. "/mobs_monster_trooper.lua")
-- dofile(modpath .. "/mobs_monster_castle_guard.lua")
dofile(modpath .. "/dumpnodes.lua")
dofile(modpath .. "/sounds.lua")
dofile(modpath .. "/bones_override.lua")
dofile(modpath .. "/website.lua")