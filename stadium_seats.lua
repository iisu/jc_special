-- stadium_seats.lua

local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())

local cushion_alt_players = {
  crisdan = true,
  erstazi = true,
  MrPhil = true,
  iisu = true,
  talamh = true,
  istie = true,
}

local cushion_cycles = {}

local function stadium_seat_rightclick(pos, node, clicker, itemstack, pointed_thing)
  if not clicker:is_player() then
    return itemstack
  end

  local was_attached = clicker:get_attach()

  local result = lrfurn.sit(pos, node, clicker, itemstack, pointed_thing, 1)

  local is_attached = clicker:get_attach()
  local name = clicker:get_player_name()

  if not was_attached and is_attached then
    if cushion_alt_players[name] then
      cushion_cycles[name] = (cushion_cycles[name] or 0) + 1

      if cushion_cycles[name] % 3 == 1 then
        core.sound_play("chair_cushion_down_alt", {
          pos = pos,
          gain = 1.0,
          max_hear_distance = 20,
        })
      else
        core.sound_play("chair_cushion_down", {
          pos = pos,
          gain = 0.2,
          max_hear_distance = 20,
        })
      end
    else
      core.sound_play("chair_cushion_down", {
        pos = pos,
        gain = 0.2,
        max_hear_distance = 20,
      })
    end
  elseif was_attached and not is_attached then
    core.sound_play("chair_cushion_up", {
      pos = pos,
      gain = 0.2,
      max_hear_distance = 20,
    })
  end

  return result
end

local colors_table = {
  {"white",      S("White") },
  {"grey",       S("Grey") },
  {"dark_grey",  S("Dark Grey") },
  {"black",      S("Black") },
  {"violet",     S("Violet") },
  {"blue",       S("Blue") },
  {"cyan",       S("Cyan") },
  {"dark_green", S("Dark Green") },
  {"green",      S("Green") },
  {"yellow",     S("Yellow") },
  {"brown",      S("Brown") },
  {"orange",     S("Orange") },
  {"red",        S("Red") },
  {"magenta",    S("Magenta") },
  {"pink",       S("Pink") },
}

for _, dye in ipairs(colors_table) do
  local color = dye[1]
  local color_name = dye[2]

  core.register_node("jc_special:stadium_seat_general_" .. color, {
    description = S("General Stadium Seat (@1)", color_name),
    drawtype = "mesh",
    mesh = "stadium_seat.obj",
    tiles = {
      "jc_special_seat_leg_black.png",
      "wool_white.png",
      "wool_" .. color .. ".png",
    },
    paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = true,
    groups = {
    choppy = 2,
    oddly_breakable_by_hand = 2,
    furniture = 1,
    },
    collision_box = {
      type = "fixed",
      fixed = {-0.34, -0.52, -0.40, 0.34, 0.52, 0.40},
    },
    selection_box = {
      type = "fixed",
      fixed = {-0.34, -0.52, -0.40, 0.34, 0.52, 0.40},
    },
    on_rightclick = stadium_seat_rightclick,
    on_destruct = lrfurn.on_seat_destruct,
  })
end

for _, dye in ipairs(colors_table) do
  local color = dye[1]
  local color_name = dye[2]

  core.register_node("jc_special:dugout_seat_" .. color, {
    description = S("Dugout Seat (@1)", color_name),
    drawtype = "mesh",
    mesh = "dugout_seat.obj",
    tiles = {
      "jc_special_seat_leg_black.png",
      "wool_" .. color .. ".png",
      "wool_" .. color .. ".png",
    },
    paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = true,
    groups = {choppy = 2, oddly_breakable_by_hand = 2, furniture = 1},
    collision_box = {
      type = "fixed",
      fixed = {-0.32, -0.55, -0.36, 0.32, 0.55, 0.36},
    },
    selection_box = {
      type = "fixed",
      fixed = {-0.32, -0.55, -0.36, 0.32, 0.55, 0.36},
    },
    on_rightclick = stadium_seat_rightclick,
    on_destruct = lrfurn.on_seat_destruct,
  })
end