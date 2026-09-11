-- bones_override.lua
local S = core.get_translator(core.get_current_modname())
local ESC = core.formspec_escape

local function is_owner(pos, name)
  local owner = core.get_meta(pos):get_string("owner")
  return owner == "" or owner == name or core.check_player_privs(name, "protection_bypass")
end

local function drop(pos, itemstack)
  local obj = core.add_item(pos, itemstack:take_item(itemstack:get_count()))
  if obj then
    obj:set_velocity({
      x = math.random(-10, 10) / 9,
      y = 5,
      z = math.random(-10, 10) / 9,
    })
  end
end

local function drop_contents(pos)
  local inv = core.get_meta(pos):get_inventory()

  for i = 1, inv:get_size("main") do
    local stack = inv:get_stack("main", i)
    if not stack:is_empty() then
      drop(pos, stack)
    end
  end

  drop(pos, ItemStack("bones:bones"))

  core.remove_node(pos)
end

local function get_items(pos, player)
  local meta = core.get_meta(pos)
  local inv = meta:get_inventory()
  local player_inv = player:get_inventory()

  for i = 1, inv:get_size("main") do
    local stack = inv:get_stack("main", i)

    if not stack:is_empty() then
      if player_inv:room_for_item("main", stack) then
        inv:set_stack("main", i, ItemStack(nil))
        player_inv:add_item("main", stack)
      else
        return false
      end
    end
  end

  local bones = ItemStack("bones:bones")

  if player_inv:room_for_item("main", bones) then
    player_inv:add_item("main", bones)
  else
    drop(pos, bones)
  end

  core.remove_node(pos)

  return true
end

function special_bones_get_hotbar_bg(x,y)
  local out = ""
  for i=0,8,1 do
    out = out .."image["..x+i..","..y..";1.1,1;gui_hb_bg.png]"
  end
  return out
end

local function show_bones_formspec(player, pos)
  local player_name = player:get_player_name()

  player:get_meta():set_string("jc_special_bones_pos", core.serialize(pos) )

  local bones_labels_x = 0.6

  local formspec =
    "formspec_version[7]" ..
    "size[11,13]" ..
    "label[" .. bones_labels_x .. ",0.5;" .. ESC(S("Bones")) .. "]" ..
    "list[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main;" .. bones_labels_x .. ",0.8;8,4;]" ..
    "button[" .. bones_labels_x .. ",5.8;3,1;get_items;" .. ESC(S("Get Items")) .. "]" ..
    -- "button[7.3,5.8;3,1;drop_items;" .. ESC(S("Drop Items")) .. "]" ..
    "button[" .. bones_labels_x + 6.8 .. ",5.8;3,1;drop_items;" .. ESC(S("Drop Items")) .. "]" ..
    "label[" .. bones_labels_x .. ",7.2;" .. ESC(S("Your Inventory")) .. "]" ..
    "list[current_player;main;" .. bones_labels_x .. ",7.5;8,4;]" ..
    "listring[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main]" ..
    "listring[current_player;main]" ..
    -- special_bones_get_hotbar_bg(bones_labels_x,7.5) ..
    ""

  core.show_formspec(player_name, "jc_special:bones", formspec)
end

core.override_item("bones:bones", {
  on_rightclick = function(pos, node, clicker)
    if not clicker or not clicker:is_player() then
      return
    end

    local owner = core.get_meta(pos):get_string("owner")

    if owner == "" then
      return
    end

    if not is_owner(pos, clicker:get_player_name()) then
      return
    end

    show_bones_formspec(clicker, pos)
  end,
})

core.register_on_player_receive_fields(function(player, formname, fields)
  if formname ~= "jc_special:bones" then
    return
  end

  if fields.quit then
    return
  end

  local pos = core.deserialize(player:get_meta():get_string("jc_special_bones_pos") )

  if not pos then
    return
  end

  local node = core.get_node_or_nil(pos)

  if not node or node.name ~= "bones:bones" then
    core.close_formspec(player:get_player_name(), formname)
    return
  end

  if not is_owner(pos, player:get_player_name() ) then
    core.close_formspec(player:get_player_name(), formname)
    return
  end

  if fields.get_items then
    if get_items(pos, player) then
      player:get_meta():set_string("jc_special_bones_pos", "")
      core.close_formspec(player:get_player_name(), formname)
    end
  elseif fields.drop_items then
    drop_contents(pos)
    player:get_meta():set_string("jc_special_bones_pos", "")
    core.close_formspec(player:get_player_name(), formname)
  end
end)
