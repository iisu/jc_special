-- prison.lua in jc_special
local S = core.get_translator(core.get_current_modname())
local storage = core.get_mod_storage()

local spawn_spawnpos = core.settings:get_pos("static_spawnpoint") or { x = 0, y = 0, z = 0 }
local prison_pos = core.settings:get_pos("prison_pos") or { x = -300, y = 7, z = -48 }

prison = {}
prison.players = {}

local released_players = {}

----------------------------------------------------------------
-- PRISON STORAGE
----------------------------------------------------------------

local function load_prison_data()
  local data = storage:get_string("prison_players")

  if data ~= "" then
    prison.players = core.deserialize(data) or {}
  else
    prison.players = {}
  end
end

local function save_prison_data()
  storage:set_string(
    "prison_players",
    core.serialize(prison.players)
  )
end

load_prison_data()

----------------------------------------------------------------
-- PRISON NODE PROTECTION
----------------------------------------------------------------
local function prison_on_dig(pos, node, digger, sound)
  if not digger or not digger:is_player() then
    return
  end

  local name = digger:get_player_name()

  --------------------------------------------------------------
  -- Server players can remove prison nodes normally.
  --------------------------------------------------------------
  if core.check_player_privs(name, {server = true}) then
    core.node_dig(pos, node, digger)
    return
  end

  --------------------------------------------------------------
  -- Anyone else gets hurt trying to break them.
  --------------------------------------------------------------
  digger:set_hp(
    math.max(0, digger:get_hp() - 5),
    {
      type = "punch",
      from = digger,
      direct = true,
    }
  )

  --------------------------------------------------------------
  -- Play the appropriate material sound.
  --------------------------------------------------------------
  core.sound_play(sound, {
    pos = pos,
    gain = 1.0,
    max_hear_distance = 10,
  })
end

----------------------------------------------------------------
-- PRISON BARS
----------------------------------------------------------------
if core.get_modpath("xpanes") then
  xpanes.register_pane("prison_bars", {
    description = S("Prison Bars"),

    tiles = {"prison_bars.png"},

    drawtype = "airlike",
    paramtype = "light",

    textures = {
      "prison_bars.png",
      "prison_bars.png",
      "prison_bars.png",
    },

    inventory_image = "prison_bars.png",
    wield_image = "prison_bars.png",

    sounds = default.node_sound_metal_defaults(),

    groups = {
      cracky = 1,
      pane = 1,
      flow_through = 1,
    },

    recipe = {
      {"jc_special:infotext_wand", "jc_special:infotext_wand", "jc_special:infotext_wand"},
      {"jc_special:infotext_wand", "default:steel_ingot", "jc_special:infotext_wand"},
      {"jc_special:infotext_wand", "jc_special:infotext_wand", "jc_special:infotext_wand"},
    },

    on_dig = function(pos, node, digger)
      prison_on_dig(
        pos,
        node,
        digger,
        "default_metal_footstep"
      )
    end,
  })
end


----------------------------------------------------------------
-- PRISON STONE / FLOOR NODES
----------------------------------------------------------------
local prison_nodes = {
  {
    name = "prison_floor",
    description = S("Prison Floor"),
    texture = "prison_floor.png",
    sounds = default.node_sound_stone_defaults(),
    dig_sound = "default_dig_cracky",
  },

  {
    name = "prison_stone",
    description = S("Prison Stone"),
    texture = "prison_stone.png",
    sounds = default.node_sound_stone_defaults(),
    dig_sound = "default_dig_cracky",
  },

  {
    name = "prison_stone_bricks",
    description = S("Prison Stone Bricks"),
    texture = "prison_stone_bricks.png",
    sounds = default.node_sound_stone_defaults(),
    dig_sound = "default_dig_cracky",
  },
}

for _, def in ipairs(prison_nodes) do
  core.register_node("jc_special:" .. def.name, {
    description = S(def.description),

    tiles = {def.texture},

    groups = {
      cracky = 1,
      stone = 1,
    },
    sounds = def.sounds,
    on_dig = function(pos, node, digger)
      prison_on_dig(pos, node, digger, def.dig_sound)
    end,
    on_construct = function(pos)
      -- Nothing needed here.
    end,
  })
end

function prison.sendToJail(name, param)
  local player_name, reason = param:match("(%S+)%s+(.+)")

  if not player_name or not reason then
    core.chat_send_player(name, S("Invalid syntax! Usage: /jail <player> <reason>") )
    return false
  end

  local player = core.get_player_by_name(player_name)

  if not player then
    core.chat_send_player(name, S("Player @1 not found.", player_name) )
    return false
  end

  if prison.players[player_name] then
    core.chat_send_player(name, S("Player @1 is already jailed.", player_name) )
    return false
  end

  --------------------------------------------------------------
  -- Save original spawn
  --------------------------------------------------------------
  local original_spawn = beds.spawn[player_name] or spawn_spawnpos

  --------------------------------------------------------------
  -- Save COMPLETE original privilege table
  --------------------------------------------------------------
  local original_privs = core.get_player_privs(player_name)

  --------------------------------------------------------------
  -- Save everything needed to restore the player
  --------------------------------------------------------------
  prison.players[player_name] = {
    spawn = original_spawn,
    privs = original_privs,
  }

  save_prison_data()

  --------------------------------------------------------------
  -- Add jail record
  --------------------------------------------------------------
  xban.add_record(player_name, {
    source = name,
    time = os.time(),
    expires = nil,
    reason = reason,
    type = "jail",
  })

  xban.add_property(player_name, "jailed", true)

  --------------------------------------------------------------
  -- Set prison spawn
  --------------------------------------------------------------
  beds.spawn[player_name] = prison_pos
  beds.save_spawns()

  --------------------------------------------------------------
  -- Move player to prison
  --------------------------------------------------------------
  player:set_pos(prison_pos)

  --------------------------------------------------------------
  -- Restrict privileges while jailed
  --------------------------------------------------------------
  core.set_player_privs(player_name, { interact = true, shout = true, })

  core.chat_send_player(name, S("Player @1 has been jailed", player_name) )
  return true
end


function prison.releaseFromJail(name, param)
  local player_name, reason = param:match("(%S+)%s+(.+)")

  if not player_name or not reason then
    core.chat_send_player(name, S("Invalid syntax! Usage: /unjail <player> <reason>") )
    return false
  end

  local prison_data = prison.players[player_name]

  if not prison_data then
    core.chat_send_player(name, S("Player @1 was never jailed", player_name) )
    return false
  end

  local player = core.get_player_by_name(player_name)

  --------------------------------------------------------------
  -- Add unjail record
  --------------------------------------------------------------
  xban.add_record(player_name, {
    source = name,
    time = os.time(),
    expires = nil,
    reason = reason,
    type = "unjail",
  })

  xban.add_property(player_name, "jailed", nil)

  --------------------------------------------------------------
  -- Restore original spawn
  --------------------------------------------------------------
  if prison_data.spawn then
    beds.spawn[player_name] = prison_data.spawn
    beds.save_spawns()
  end

  --------------------------------------------------------------
  -- Restore COMPLETE original privileges
  --------------------------------------------------------------
  if prison_data.privs then
    core.set_player_privs(player_name, prison_data.privs)
  end

  --------------------------------------------------------------
  -- Move player out of prison if online
  --------------------------------------------------------------
  if player and prison_data.spawn then
    player:set_pos(prison_data.spawn)
  end

  --------------------------------------------------------------
  -- Remove jail data from ModStorage
  --------------------------------------------------------------
  prison.players[player_name] = nil
  if not player then
    released_players[player_name] = true
  end
  save_prison_data()

  --------------------------------------------------------------
  -- Notify the jail administrator
  --------------------------------------------------------------
  core.chat_send_player(name, S("Player @1 has been unjailed", player_name) )

  return true
end

core.register_chatcommand("jail", {
   description = S("Jails Players"),
   privs = {kick=true},
   params = "<player> <reason>",
   func = function(name, param)
      prison.sendToJail(name, param)
   end,
})

core.register_chatcommand("unjail", {
   description = S("Unjails players"),
   privs = {kick=true},
   params = "<player> <reason>",
   func = function(name, param)
      prison.releaseFromJail(name, param)
   end,
})

----------------------------------------------------------------
-- KEEP JAILED PLAYERS IN PRISON AFTER JOINING
----------------------------------------------------------------
core.register_on_joinplayer(function(player)
  local player_name = player:get_player_name()
  local prison_data = prison.players[player_name]

  --------------------------------------------------------------
  -- PLAYER IS JAILED
  --------------------------------------------------------------
  if prison_data then

    ------------------------------------------------------------
    -- Make sure their spawn is the prison.
    ------------------------------------------------------------
    beds.spawn[player_name] = prison_pos

    ------------------------------------------------------------
    -- Make sure their restricted privileges are still active.
    ------------------------------------------------------------
    core.set_player_privs(player_name, {
      interact = true,
      shout = true,
    })

    ------------------------------------------------------------
    -- Force the jailed player back to the prison.
    ------------------------------------------------------------
    player:set_pos(prison_pos)

    return
  end

  --------------------------------------------------------------
  -- PLAYER WAS RELEASED WHILE OFFLINE
  --------------------------------------------------------------
  if released_players[player_name] then

    released_players[player_name] = nil

    ------------------------------------------------------------
    -- Get their normal bed spawn.
    ------------------------------------------------------------
    local home_pos = beds.spawn[player_name]

    ------------------------------------------------------------
    -- If they don't have a bed spawn, use the normal spawn.
    ------------------------------------------------------------
    if not home_pos then
      home_pos = spawn_spawnpos
    end

    ------------------------------------------------------------
    -- Move them home after they finish joining.
    ------------------------------------------------------------
    core.after(0.2, function()
      if player and player:is_player() then
        player:set_pos(home_pos)
      end
    end)

    return
  end
end)

----------------------------------------------------------------
-- KEEP JAILED PLAYERS IN PRISON AFTER DEATH
----------------------------------------------------------------
core.register_on_respawnplayer(function(player)
  local player_name = player:get_player_name()
  local prison_data = prison.players[player_name]

  if not prison_data then
    return false
  end

  --------------------------------------------------------------
  -- Make sure their spawn is still the prison.
  --------------------------------------------------------------
  beds.spawn[player_name] = prison_pos

  --------------------------------------------------------------
  -- Make sure their restricted privileges are still active.
  --------------------------------------------------------------
  core.set_player_privs(player_name, {
    interact = true,
    shout = true,
  })

  --------------------------------------------------------------
  -- Force the jailed player back to the prison.
  --------------------------------------------------------------
  player:set_pos(prison_pos)

  return true
end)

----------------------------------------------------------------
-- PREVENT JAILED PLAYERS FROM ENTERING RESTRICTED AREAS
----------------------------------------------------------------
if core.get_modpath("areas") then

  local restricted_area_ids_for_prisoners = {
    [75] = true, -- VISITOR_AREA
    [77] = true, -- RESTRICTED
    [78] = true, -- RESTRICTED
    [79] = true, -- RESTRICTED
    [80] = true, -- RESTRICTED
    [81] = true, -- RESTRICTED
    [82] = true, -- RESTRICTED
    [83] = true, -- RESTRICTED
    [84] = true, -- RESTRICTED
  }

  local restricted_area_check_timer = 0

  core.register_globalstep(function(dtime)

    restricted_area_check_timer = restricted_area_check_timer + dtime

    if restricted_area_check_timer < 0.5 then
      return
    end

    restricted_area_check_timer = 0

    for player_name, prison_data in pairs(prison.players) do

      local player = core.get_player_by_name(player_name)

      if player then

        local pos = player:get_pos()

        if pos then

          local areas_here = areas:getAreasAtPos(pos)

          ------------------------------------------------------
          -- getAreasAtPos() returns a table keyed by area ID.
          ------------------------------------------------------
          for area_id, area in pairs(areas_here) do

            if restricted_area_ids_for_prisoners[area_id] then

              --------------------------------------------------
              -- Jailed player entered a restricted area.
              --------------------------------------------------
              player:set_pos(prison_pos)

              core.chat_send_player(
                player_name,
                S("You cannot enter this area while jailed.")
              )

              break
            end
          end
        end
      end
    end
  end)

end