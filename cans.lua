local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())

local tmp = {}

local function set_can_wear(itemstack, level, max_level)
  local wear

  if level == 0 then
    wear = 0
  else
    wear = 65536 - math.floor(level / max_level * 65535)

    if wear > 65535 then
      wear = 65535
    end

    if wear < 1 then
      wear = 1
    end
  end

  itemstack:set_wear(wear)
end


local function get_can_level(itemstack)
  local meta = itemstack:get_meta()
  local level = meta:get_int("level")

  return level
end

function jc_special.register_can(data)
  core.register_tool(data.name, {
    description = data.description,
    inventory_image = data.inventory_image,
    stack_max = 1,

    wear_represents = "content_level",
    liquids_pointable = true,

    groups = {
      jc_special_can = 1,
    },

    on_use = function(itemstack, user, pointed_thing)
      if pointed_thing.type ~= "node" then
        return itemstack
      end

      local node = core.get_node(pointed_thing.under)

      -- Allow special nodes to handle punching with the can.
      local def = core.registered_nodes[node.name]

      if node.name ~= data.source then
        if def and def.on_punch then
          local result = def.on_punch(
            pointed_thing.under,
            node,
            user,
            pointed_thing
          )

          if result then
            return result
          end
        end

        return itemstack
      end

      local charge = get_can_level(itemstack)

      if charge >= data.capacity then
        return itemstack
      end

      local player_name = user:get_player_name()

      if core.is_protected(pointed_thing.under, player_name) then
        core.log(
          "action",
          player_name ..
          " tried to take " .. data.description ..
          " at protected position " ..
          core.pos_to_string(pointed_thing.under)
        )

        return itemstack
      end

      core.remove_node(pointed_thing.under)

      charge = charge + 1

      -- itemstack:set_metadata(tostring(charge))
      itemstack:get_meta():set_int("level", charge)
      set_can_wear(itemstack, charge, data.capacity)

      return itemstack
    end,

    on_place = function(itemstack, user, pointed_thing)
      if pointed_thing.type ~= "node" then
        return itemstack
      end

      local pos = pointed_thing.under
      local node = core.get_node(pos)
      local def = core.registered_nodes[node.name] or {}

      -- Let the pointed node handle its own right-click.
      if def.on_rightclick
          and user
          and not user:get_player_control().sneak then
        return def.on_rightclick(
          pos,
          node,
          user,
          itemstack,
          pointed_thing
        )
      end

      -- If the pointed node isn't buildable_to,
      -- try placing the liquid above it.
      if not def.buildable_to then
        pos = pointed_thing.above
        node = core.get_node(pos)
        def = core.registered_nodes[node.name] or {}

        if not def.buildable_to then
          return itemstack
        end
      end

      local charge = get_can_level(itemstack)

      if charge <= 0 then
        return itemstack
      end

      local player_name = user:get_player_name()

      if core.is_protected(pos, player_name) then
        core.log(
          "action",
          player_name ..
          " tried to place " .. data.description ..
          " at protected position " ..
          core.pos_to_string(pos)
        )

        return itemstack
      end

      core.set_node(pos, {
        name = data.source
      })

      charge = charge - 1

      itemstack:get_meta():set_int("level", charge)
      set_can_wear(itemstack, charge, data.capacity)

      return itemstack
    end,

    on_refill = function(itemstack)
      -- itemstack:set_metadata(tostring(data.capacity))
      itemstack:get_meta():set_int("level", data.capacity)
      set_can_wear(itemstack, data.capacity, data.capacity)

      return itemstack
    end,
  })
end

jc_special.register_can({
  name = "jc_special:water_can",
  description = S("Water Can"),
  inventory_image = "jc_special_water_can.png",
  capacity = 15,
  source = "default:water_source",
})

jc_special.register_can({
  name = "jc_special:water_jumbo_can",
  description = S("Jumbo Water Can"),
  inventory_image = "jc_special_water_can_jumbo.png",
  capacity = 35,
  source = "default:water_source",
})

jc_special.register_can({
  name = "jc_special:freshwater_can",
  description = S("Freshwater Can"),
  inventory_image = "jc_special_freshwater_can.png",
  capacity = 15,
  source = "default:river_water_source",
})

jc_special.register_can({
  name = "jc_special:lava_can",
  description = S("Lava Can"),
  inventory_image = "jc_special_lava_can.png",
  capacity = 10,
  source = "default:lava_source",
})

core.register_craft({
  output = "jc_special:water_can",
  recipe = {
    {"default:steel_ingot", "default:tin_ingot",   "default:steel_ingot"},
    {"default:steel_ingot", "",                    "default:steel_ingot"},
    {"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
  },
})

core.register_craft({
  output = "jc_special:water_jumbo_can",
  recipe = {
    {"default:steel_ingot", "multidecor:wolfram_ingot", "default:steel_ingot"},
    {"default:steel_ingot", "",                        "default:steel_ingot"},
    {"default:steel_ingot", "default:steel_ingot",     "default:steel_ingot"},
  },
})

core.register_craft({
  output = "jc_special:freshwater_can",
  recipe = {
    {"default:steel_ingot", "moreores:silver_ingot", "default:steel_ingot"},
    {"default:steel_ingot", "",                        "default:steel_ingot"},
    {"default:steel_ingot", "default:steel_ingot",     "default:steel_ingot"},
  },
})

core.register_craft({
  output = "jc_special:lava_can",
  recipe = {
    {"default:steel_ingot", "multidecor:zinc_ingot", "default:steel_ingot"},
    {"default:steel_ingot", "",                    "default:steel_ingot"},
    {"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
  },
})


-- homedecor:well compatibility
if core.get_modpath("homedecor_exterior")
    and core.registered_nodes["homedecor:well"] then

  local well_cans = {
    ["jc_special:water_can"] = 15,
    ["jc_special:water_jumbo_can"] = 35,
  }

  for can_name, capacity in pairs(well_cans) do
    local old_on_use = core.registered_items[can_name].on_use

    core.override_item(can_name, {
      on_use = function(itemstack, user, pointed_thing)
        if pointed_thing.type == "node"
            and core.get_node(pointed_thing.under).name == "homedecor:well" then

          local charge = get_can_level(itemstack)
          local sneak = user and user:get_player_control().sneak

          if charge >= capacity then
            return itemstack
          end

          if sneak then
            charge = capacity
          else
            charge = charge + 1
          end

          itemstack:get_meta():set_int("level", charge)
          set_can_wear(itemstack, charge, capacity)

          return itemstack
        end

        if old_on_use then
          return old_on_use(itemstack, user, pointed_thing)
        end

        return itemstack
      end,
    })
  end
end

-- Wine barrel compatibility
if core.get_modpath("wine") then
  local wine_cans = {
    ["jc_special:water_can"] = 15,
    ["jc_special:water_jumbo_can"] = 35,
    ["jc_special:freshwater_can"] = 15,
  }

  local barrel = core.registered_nodes["wine:wine_barrel"]

  if barrel then
    local old_allow_put = barrel.allow_metadata_inventory_put
    local old_inventory_put = barrel.on_metadata_inventory_put

    core.override_item("wine:wine_barrel", {
      allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "src_b" and wine_cans[stack:get_name()] then
          local level = tonumber(stack:get_meta():get_int("level")) or 0
          local water = core.get_meta(pos):get_int("water")

          if level <= 0 or water >= 100 then
            return 0
          end

          return 1
        end

        if old_allow_put then
          return old_allow_put(pos, listname, index, stack, player)
        end

        return 0
      end,

      on_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "src_b" and wine_cans[stack:get_name()] then
          local meta = core.get_meta(pos)
          local inv = meta:get_inventory()
          local can = inv:get_stack("src_b", 1)

          -- local level = tonumber(can:get_metadata()) or 0
          local level = tonumber(can:get_meta():get_int("level")) or 0

          if level > 0 then
            local water = meta:get_int("water")

            -- One can charge = one bucket = 20 Wine water.
            -- A full barrel holds 5 buckets = 100 water.
            local needed = 100 - water
            local charges_used = math.min(level, math.ceil(needed / 20))

            local water_added = charges_used * 20

            if water_added > needed then
              water_added = needed
            end

            water = water + water_added
            level = level - charges_used

            -- can:set_metadata(tostring(level))
            can:get_meta():set_int("level", level)

            -- Update can wear.
            local capacity = wine_cans[can:get_name()]

            if level == 0 then
              can:set_wear(0)
            else
              local wear = 65536 - math.floor(
                level / capacity * 65535
              )

              if wear > 65535 then
                wear = 65535
              elseif wear < 1 then
                wear = 1
              end

              can:set_wear(wear)
            end

            inv:set_stack("src_b", 1, can)
            meta:set_int("water", water)

            return
          end
        end

        if old_inventory_put then
          old_inventory_put(pos, listname, index, stack, player)
        end
      end,
    })
  end
end

-- Cottage freshwater can compatibility
core.register_on_mods_loaded(function()
  if not core.get_modpath("cottages") then
    return
  end

  local well = core.registered_nodes["cottages:water_gen"]

  if not well then
    return
  end

  local old_on_punch = well.on_punch

  core.override_item("cottages:water_gen", {
    on_punch = function(pos, node, puncher, pointed_thing)
      if not puncher then
        return
      end

      local name = puncher:get_player_name()
      local wielded = puncher:get_wielded_item()

      local meta = core.get_meta(pos)
      local bucket = meta:get_string("bucket")

      -- If the well contains our freshwater can, handle retrieval
      -- regardless of what the player is currently holding.
      if bucket == "jc_special:freshwater_can" then
        local stored_level = meta:get_int("can_level")

        if stored_level < 15 then
          core.chat_send_player(name, S("Please wait until your can has been filled.") )
          return
        end

        local can = ItemStack("jc_special:freshwater_can")
        -- can:set_metadata("15")
        can:get_meta():set_int("level", 15)
        set_can_wear(can, 15, 15)

        local inv = puncher:get_inventory()

        if not inv:room_for_item("main", can) then
          core.chat_send_player(
            name,
            S("Inventory full.")
          )

          return
        end

        for _, obj in ipairs(core.get_objects_inside_radius(pos, 0.5)) do
          local ent = obj:get_luaentity()

          if ent and ent.name == "cottages:bucket_entity" then
            obj:remove()
          end
        end

        inv:add_item("main", can)

        meta:set_string("bucket", "")
        meta:set_string("fillstarttime", "")
        meta:set_string("can_owner", "")
        meta:set_int("can_level", 0)

        return
      end

      -- If this is not our stored can, only intercept a freshwater
      -- can being punched into the well.
      if wielded:get_name() ~= "jc_special:freshwater_can" then
        if old_on_punch then
          return old_on_punch(pos, node, puncher, pointed_thing)
        end

        return
      end

      local meta = core.get_meta(pos)
      local owner = meta:get_string("owner")
      local public = meta:get_string("public")
      local bucket = meta:get_string("bucket")
      local level = wielded:get_meta():get_int("level")


      -- Respect Cottage's public/private setting.
      if name ~= owner and public ~= "public" then
        core.chat_send_player(name, S("This well is owned by @1. You can't use it.", owner) )
        return
      end

      -- Something else is already in the well.
      if bucket ~= "" then
        core.chat_send_player(name, S("The well is already being used.") )
        return
      end

      -- Don't fill an already-full can.
      if level >= 15 then

        core.chat_send_player(name, S("Your can is already full."))
        return
      end

      -- Put the can into the well.
      meta:set_string("bucket", "jc_special:freshwater_can")
      meta:set_int("can_level", level)
      meta:set_string("can_owner", name)
      meta:set_string(
        "fillstarttime",
        tostring(core.get_us_time() / 1000000)
      )

      -- Remove the can from the player's hand.
      wielded:take_item()
      -- puncher:set_wielded_item(wielded)

      -- Show the freshwater can in the well.
      local entity = core.add_entity(
        {
          x = pos.x,
          y = pos.y + (4 / 16),
          z = pos.z
        },
        "cottages:bucket_entity"
      )

      if entity then
        entity:set_properties({
          textures = {"jc_special:freshwater_can"}
        })

        local ent = entity:get_luaentity()

        if ent then
          ent.nodename = "jc_special:freshwater_can"
          ent.texture = "jc_special:freshwater_can"
        end
      end

      -- Fill the can after Cottage's normal fill time.
      core.after(cottages.water_fill_time, function()
        local meta = core.get_meta(pos)
        local bucket = meta:get_string("bucket")

        if bucket ~= "jc_special:freshwater_can" then
          return
        end

        local owner = meta:get_string("can_owner")

        meta:set_int("can_level", 15)

        if owner ~= "" then
          core.chat_send_player(owner, S("Your can is now full!") )
        end

        core.add_particlespawner({
          amount = 20,
          time = 0.5,
          minpos = {
            x = pos.x - 0.25,
            y = pos.y + 0.2,
            z = pos.z - 0.25,
          },
          maxpos = {
            x = pos.x + 0.25,
            y = pos.y + 0.6,
            z = pos.z + 0.25,
          },
          minvel = {
            x = -0.3,
            y = 0.5,
            z = -0.3,
          },
          maxvel = {
            x = 0.3,
            y = 1.0,
            z = 0.3,
          },
          minacc = {
            x = 0,
            y = -0.5,
            z = 0,
          },
          maxacc = {
            x = 0,
            y = -0.5,
            z = 0,
          },
          minexptime = 0.5,
          maxexptime = 1.0,
          minsize = 1,
          maxsize = 2,
          texture = "default_water.png",
          glow = 2,
        })
      end)

      return wielded
    end,
  })

  core.log("action", "[jc_special] Cottage freshwater can override installed")
end)
