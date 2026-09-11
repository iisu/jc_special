-- homedecor_overrides.lua
local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())

minetest.register_alias("wardrobe:wardrobe", "homedecor:wardrobe")

local function update_clock(pos)
  local tod = core.get_timeofday()

  local hours = math.floor(tod * 24)
  local minutes = math.floor((tod * 1440) % 60)

  core.get_meta(pos):set_string(
    "infotext",
    S("Grandfather Clock\n@1", string.format("%02d:%02d", hours, minutes))
  )
end


-- local def = core.registered_nodes["homedecor:grandfather_clock"]

-- if def then
  -- core.override_item("homedecor:grandfather_clock", {
    -- on_construct = function(pos)
      -- if def.on_construct then
        -- def.on_construct(pos)
      -- end

      -- update_clock(pos)
      -- core.get_node_timer(pos):start(10)
    -- end,

    -- on_timer = function(pos, elapsed)
      -- update_clock(pos)

      -- if def.on_timer then
        -- return def.on_timer(pos, elapsed)
      -- end

      -- return true
    -- end,
  -- })
-- end


local function mailbox_formspec(pos)
  local spos = pos.x .. "," .. pos.y .. "," .. pos.z

  return
    "size[10,11]" ..

    "list[nodemeta:" .. spos .. ";main;1,0.5;8,4;]" ..

    "button[3,5.0;4,0.8;getitems;" .. core.formspec_escape( S("Get Mailbox Items") )  .. "]" ..

    "list[current_player;main;1,6.6;8,4;]" ..

    "listring[]"
end

local function update_mailbox_infotext(pos)
  local meta = core.get_meta(pos)
  local owner = meta:get_string("owner")

  if owner ~= "" then
    meta:set_string("infotext", S("Mailbox Owner: @1", owner ) )
  else
    meta:set_string("infotext", S("Mailbox\nUnowned") )
  end
end

-- Wait until ALL mods have registered their nodes.
core.register_on_mods_loaded(function()

  if not core.registered_nodes["homedecor:inbox"] then
    core.log("error", "[jc_special] homedecor:inbox not found!")
    return
  end

  local inbox_def = core.registered_nodes["homedecor:inbox"]
  local old_on_metadata_inventory_put = inbox_def.on_metadata_inventory_put
  local old_on_construct = inbox_def.on_construct

  core.override_item("homedecor:inbox", {
    on_construct = function(pos)
      if old_on_construct then
        old_on_construct(pos)
      end

      update_mailbox_infotext(pos)
    end,

    on_rightclick = function(pos, node, clicker, itemstack)
      update_mailbox_infotext(pos)

      local meta = core.get_meta(pos)
      local owner = meta:get_string("owner")
      local player = clicker:get_player_name()

      if player == owner or
        (core.check_player_privs(player, "protection_bypass")
        and clicker:get_player_control().aux1) then

        core.show_formspec(
          player,
          "jc_special:" .. core.pos_to_string(pos),
          mailbox_formspec(pos)
        )

      else
        -- Original deposit-only formspec
        local spos = pos.x .. "," .. pos.y .. "," .. pos.z

        -- core.show_formspec(
          -- player,
          -- "jc_special_insert",
          -- "size[8,9]" ..
          -- "list[nodemeta:"..spos..";drop;3.5,2;1,1;]" ..
          -- "list[current_player;main;0,5;8,4;]" ..
          -- "listring[]"
        -- )
        core.show_formspec(
          player,
          "jc_special_insert",
          "size[8,9]" ..
          "label[0.5,0.3;" .. S("Mailbox for: @1", core.formspec_escape(owner) ) .. "]" ..
          "list[nodemeta:"..spos..";drop;3.5,2;1,1;]" ..
          "list[current_player;main;0,5;8,4;]" ..
          "listring[]"
        )
      end

      return itemstack
    end,
    on_metadata_inventory_put = function(pos, listname, index, stack, player)

      -- Let HomeDecor do its original mailbox processing
      if old_on_metadata_inventory_put then
        old_on_metadata_inventory_put(pos, listname, index, stack, player)
      end

      local depositor = player:get_player_name()
      local owner = core.get_meta(pos):get_string("owner")
      local mailbox_pos = core.pos_to_string(pos)

      -- Sound for the person depositing
      core.sound_play("incoming_mailbox", {
        to_player = depositor,
        gain = 0.6,
      })

      -- Notify the mailbox owner if they are online
      if owner ~= "" and owner ~= depositor then
        local owner_player = core.get_player_by_name(owner)

        if owner_player then
          core.sound_play("incoming_mailbox", {
            to_player = owner,
            gain = 0.6,
          })

          core.chat_send_player(
            owner,
            S("[Mailbox] @1 has deposited mail for you at @2.",
              core.colorize("#55FF55", depositor),
              core.colorize("#AAAAAA", mailbox_pos))
          )
        end
      end
    end,
  })

  core.log("action", "[jc_special] Mailbox overridden successfully.")


  -- local def = core.registered_nodes["homedecor:grandfather_clock"]

  -- if not def then
    -- core.log("error", "[jc_special] homedecor:grandfather_clock not found!")
    -- return
  -- end

  -- core.override_item("homedecor:grandfather_clock", {
    -- on_rightclick = function(pos, node, clicker, itemstack)
      -- update_clock(pos)
      -- core.get_node_timer(pos):start(10)
    -- end,
    -- on_construct = function(pos)
      -- if def.on_construct then
        -- def.on_construct(pos)
      -- end

      -- update_clock(pos)
      -- core.get_node_timer(pos):start(10)
    -- end,
    -- on_timer = function(pos, elapsed)
      -- update_clock(pos)

      -- if def.on_timer then
        -- return def.on_timer(pos, elapsed)
      -- end

      -- return true
    -- end,
  -- })

  -- core.log("action", "[jc_special] grandfather_clock overridden successfully.")
end)

core.register_on_player_receive_fields(function(player, formname, fields)

  if not fields.getitems then
    return
  end

  local posstr = formname:match("^jc_special:(.*)$")
  if not posstr then
    return
  end

  local pos = core.string_to_pos(posstr)
  if not pos then
    return
  end

  local meta = core.get_meta(pos)

  if meta:get_string("owner") ~= player:get_player_name() then
    return
  end

  local mail = meta:get_inventory()
  local inv = player:get_inventory()

  for i = 1, mail:get_size("main") do
    local stack = mail:get_stack("main", i)

    if not stack:is_empty() then
      local leftover = inv:add_item("main", stack)
      mail:set_stack("main", i, leftover)
    end
  end

  core.sound_play("default_item_smoke", {
    to_player = player:get_player_name(),
    gain = 0.6,
  })

  core.show_formspec(
    player:get_player_name(),
    formname,
    mailbox_formspec(pos)
  )
end)
