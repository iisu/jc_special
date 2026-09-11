local S = core.get_translator(core.get_current_modname())
local monster_sounds_storage = core.get_mod_storage()

--------------------------------------------------------
-- SOUND SETTINGS
--------------------------------------------------------
jc_special_sounds = {}

jc_special_sounds.sound_settings = {
  {
    name = "welcome_sounds",
    meta_key = "welcome_players_sounds",
    label = S("Welcome Sounds"),
  },
  {
    name = "memorial_sounds",
    meta_key = "memorial_sounds",
    label = S("Memorial Block Sounds"),
  },
  {
    name = "monster_sounds",
    meta_key = "jc_special_sounds_monsters",
    label = S("Monster Sounds"),
  },
  {
    name = "party_sounds",
    meta_key = "jc_party_sounds",
    label = S("Party Instrument Sounds"),
  },
}

--------------------------------------------------------
-- PENDING SOUND SETTINGS
--------------------------------------------------------
jc_special_sounds.pending_sound_settings = {}

--------------------------------------------------------
-- SET SOUND SETTING
--------------------------------------------------------
function jc_special_sounds.set_sound_setting(player, sound, enabled)
  local name = player:get_player_name()
  local meta = player:get_meta()

  if enabled then
    meta:set_string(sound.meta_key, "on")

    if sound.name == "monster_sounds" then
      monster_sounds_storage:set_string("disabled:" .. name, "")
    end

    core.log("action", "[SOUNDS] " .. name .. " turned ON " .. sound.name)
  else
    meta:set_string(sound.meta_key, "off")

    if sound.name == "monster_sounds" then
      monster_sounds_storage:set_string("disabled:" .. name, "off")
    end

    core.log("action", "[SOUNDS] " .. name .. " turned OFF " .. sound.name)
  end
end

--------------------------------------------------------
-- SHOW SOUNDS FORMSPEC
--------------------------------------------------------
function jc_special_sounds.show_sounds_formspec(player)
  local name = player:get_player_name()
  local meta = player:get_meta()

  jc_special_sounds.pending_sound_settings[name] = {}

  local formspec =
    "formspec_version[4]"
    .. "size[8,6]"
    .. "label[0.5,0.4;" .. core.formspec_escape(S("Sound Settings")) .. "  " .. core.formspec_escape(core.colorize("#FFFF00", "/sounds")) .. "]"

  local y = 1.2

  for _, sound in ipairs(jc_special_sounds.sound_settings) do
    local enabled = meta:get_string(sound.meta_key) ~= "off"

    jc_special_sounds.pending_sound_settings[name][sound.name] = enabled

    formspec = formspec
      .. "checkbox[0.7," .. y .. ";" .. sound.name .. ";" .. core.formspec_escape(sound.label) .. ";" .. tostring(enabled) .. "]"

    y = y + 0.8
  end

  formspec = formspec
    .. "button_exit[4.0," .. (y + 0.5) .. ";1.7,0.8;sounds_cancel;" .. core.formspec_escape(S("Cancel")) .. "]"
    .. "button[5.8," .. (y + 0.5) .. ";1.7,0.8;sounds_save;" .. core.formspec_escape(S("Save")) .. "]"

  core.show_formspec(name, "jc_special:sounds", formspec)
end

--------------------------------------------------------
-- /sounds
--------------------------------------------------------
core.register_chatcommand("sounds", {
  description = S("Configure your sound settings."),

  func = function(name)
    local player = core.get_player_by_name(name)

    if not player then
      return false, S("Player not found.")
    end

    jc_special_sounds.show_sounds_formspec(player)

    return true
  end,
})

--------------------------------------------------------
-- SOUNDS FORMSPEC RECEIVE
--------------------------------------------------------
core.register_on_player_receive_fields(function(player, formname, fields)
  if formname ~= "jc_special:sounds" then
    return false
  end

  local name = player:get_player_name()

  if not jc_special_sounds.pending_sound_settings[name] then
    jc_special_sounds.pending_sound_settings[name] = {}
  end

  ------------------------------------------------------
  -- CHECKBOX CHANGED
  ------------------------------------------------------
  for _, sound in ipairs(jc_special_sounds.sound_settings) do
    if fields[sound.name] then
      jc_special_sounds.pending_sound_settings[name][sound.name] = fields[sound.name] == "true"
    end
  end

  ------------------------------------------------------
  -- CANCEL
  ------------------------------------------------------
  if fields.sounds_cancel then
    jc_special_sounds.pending_sound_settings[name] = nil
    return true
  end

  ------------------------------------------------------
  -- SAVE
  ------------------------------------------------------
  if fields.sounds_save then
    for _, sound in ipairs(jc_special_sounds.sound_settings) do
      local enabled = jc_special_sounds.pending_sound_settings[name][sound.name] == true
      jc_special_sounds.set_sound_setting(player, sound, enabled)
    end

    jc_special_sounds.pending_sound_settings[name] = nil

    core.chat_send_player(name, S("Sound settings saved."))

    core.close_formspec(name, "jc_special:sounds")

    return true
  end

  return true
end)

--------------------------------------------------------
-- CLEAN UP WHEN PLAYER LEAVES
--------------------------------------------------------
core.register_on_leaveplayer(function(player)
  jc_special_sounds.pending_sound_settings[player:get_player_name()] = nil
end)