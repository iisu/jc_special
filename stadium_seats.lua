-- stadium_seats.lua

local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())

local multidecor_sitting = multidecor and multidecor.sitting

local seat_on_construct = multidecor_sitting and multidecor_sitting.on_construct
local seat_on_destruct = multidecor_sitting and multidecor_sitting.on_destruct
local seat_on_rightclick = multidecor_sitting and multidecor_sitting.on_rightclick

local function seat_sitting_data(pos, rot, y)
  if not multidecor_sitting then
    return nil
  end

  return {
    pos = vector.new(pos.x, y, pos.z),
    rot = rot,
    model = multidecor_sitting.standard_model,
    anims = {"sit1", "sit2"},
  }
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
    add_properties = {
      seat_data = seat_sitting_data({x = 0, y = 0, z = 0}, vector.new(0, 0, 0), -0.05),
    },
    on_construct = seat_on_construct,
    on_destruct = seat_on_destruct,
    on_rightclick = seat_on_rightclick,
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
    add_properties = {
      seat_data = seat_sitting_data({x = 0, y = 0, z = 0}, vector.new(0, 0, 0), -0.14),
    },
    on_construct = seat_on_construct,
    on_destruct = seat_on_destruct,
    on_rightclick = seat_on_rightclick,
  })
end