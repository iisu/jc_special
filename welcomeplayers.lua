local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())

local greet_enabled = false
local join_queue = {}

welcome_players = {}

function welcome_players.play_sound(player, sound, parameters)
  if not player then
    return
  end

  if player:get_meta():get_string("welcome_players_sounds") == "off" then
    return
  end

  core.sound_play(sound, parameters)
end

core.register_chatcommand("greet", {
  params = "on | off",
  description = S("Enable or disable join greeter"),
  privs = {server = true},
  func = function(name, param)
    if name ~= "erstazi" then
      return false, S("Not allowed.")
    end

    if param == "on" then
      greet_enabled = true
      return true, S("Join greeter enabled")
    elseif param == "off" then
      greet_enabled = false
      return true, S("Join greeter disabled")
    else
      return false, S("Use: /greet on | off")
    end
  end
})

local new_players = {}

core.register_on_newplayer(function(player)
  local new_name = player:get_player_name()
  new_players[new_name] = true

  -- Notify staff
  core.after(2, function()
    for _, p in ipairs(core.get_connected_players()) do
      local staff_name = p:get_player_name()
      if core.check_player_privs(staff_name, {ban = true}) then
        core.chat_send_player(staff_name, core.colorize("#00FF00", S("*** NEW PLAYER: @1 has joined the server for the first time. Information about apartments already sent to new player.", new_name) ) )
      end
    end
  end)

  core.after(2, function()
    local p = core.get_player_by_name(new_name)
    if not p then
      new_players[new_name] = nil
      return
    end

    core.chat_send_player(new_name, core.colorize("#00FF88", "======================================================="))
    core.chat_send_player(new_name, core.colorize("#FFFF00", S("Welcome to the Just-Craft server, @1!", new_name) ))
    core.chat_send_player(new_name, "")
    core.chat_send_player(new_name, core.colorize("#FFFFFF", S("Type @1 to get your free apartment!", core.colorize("#FFFF00", "/apt") ) ) )
    core.chat_send_player(new_name, core.colorize("#00FF88", "======================================================="))

    -- core.sound_play("welcome_stranger", {
      -- to_player = new_name,
      -- gain = 1.0,
    -- })

    welcome_players.play_sound(p, "welcome_stranger", {
      to_player = new_name,
      gain = 1.0,
    })

    new_players[new_name] = nil
  end)
end)

core.register_on_joinplayer(function(player)
  local name = player:get_player_name()
  core.after(1, function()
    if not core.get_player_by_name(name) then
      return
    end

    -- core.sound_play("welcome", {
      -- gain = 1.0,
      -- exclude_player = name,
    -- })
    for _, p in ipairs(core.get_connected_players()) do
      local listener_name = p:get_player_name()

      if listener_name ~= name then
        welcome_players.play_sound(p, "welcome", {
          to_player = listener_name,
          gain = 1.0,
        })
      end
    end

    if not new_players[name] then
      -- core.sound_play("glockenspiel", {
        -- to_player = name,
        -- gain = 1.0,
      -- })
      welcome_players.play_sound(player, "glockenspiel", {
        to_player = name,
        gain = 1.0,
      })
    end
  end)
end)

local welcome_sounds = {
  welcome = true,
  glockenspiel = true,
  welcome_stranger = true,
}

core.register_chatcommand("welcome_sound", {
  params = "[welcome|glockenspiel|welcome_stranger]",
  description = S("Play a welcome sound for all connected players."),
  privs = {ban = true},

  func = function(name, param)
    param = (param or ""):trim()

    if param == "" then
      return true, S("Available sounds: welcome, glockenspiel, welcome_stranger\nUsage: /welcome_sound <sound>")
    end

    if not welcome_sounds[param] then
      return false, S("No sounds found with that name.\nAvailable: welcome, glockenspiel, welcome_stranger")
    end

    -- core.sound_play(param, {
      -- gain = 1.0,
    -- })

    for _, player in ipairs(core.get_connected_players()) do
      local player_name = player:get_player_name()

      welcome_players.play_sound(player, param, {
        to_player = player_name,
        gain = 1.0,
      })
    end

    core.log("action", name .. " played welcome sound: " .. param)

    return true, S("Playing '@1' for all connected players.", param)
  end,
})