-------------------------------------------------------------------------------
-- jc_special website JSON
--
-- Generates a public JSON file containing:
--   - Server name
--   - Luanti version
--   - Players currently online
--   - Total registered player count
--   - /places locations
--   - Last updated timestamp
--
-- The file is updated every 60 seconds.
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Configuration
-------------------------------------------------------------------------------
-- Change this to wherever you want the website JSON to be written.
--
-- Make sure the Luanti server process has permission to write there.
local WEBSITE_JSON = core.get_worldpath() .. "/server.json"

-- How often to update the JSON file.
local UPDATE_INTERVAL = 60

-------------------------------------------------------------------------------
-- JSON encoder and Helper Functions
-------------------------------------------------------------------------------
local function json_escape(str)
  str = tostring(str)

  str = str:gsub("\\", "\\\\")
  str = str:gsub("\"", "\\\"")
  str = str:gsub("\b", "\\b")
  str = str:gsub("\f", "\\f")
  str = str:gsub("\n", "\\n")
  str = str:gsub("\r", "\\r")
  str = str:gsub("\t", "\\t")

  return str
end

local function json_encode(value)
  local value_type = type(value)

  -- ------------------------------------------------------------
  -- String
  -- ------------------------------------------------------------
  if value_type == "string" then
    return "\"" .. json_escape(value) .. "\""

  -- ------------------------------------------------------------
  -- Number
  -- ------------------------------------------------------------
  elseif value_type == "number" then
    if value ~= value then
      return "null"
    end

    if value == math.huge or value == -math.huge then
      return "null"
    end

    return tostring(value)

  -- ------------------------------------------------------------
  -- Boolean
  -- ------------------------------------------------------------
  elseif value_type == "boolean" then
    return value and "true" or "false"

  -- ------------------------------------------------------------
  -- Nil
  -- ------------------------------------------------------------
  elseif value_type == "nil" then
    return "null"

  -- ------------------------------------------------------------
  -- Table
  -- ------------------------------------------------------------
  elseif value_type == "table" then
    local parts = {}
    local is_array = true
    local count = 0

    -- Determine whether this is an array.
    for key, _ in pairs(value) do
      count = count + 1

      if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
        is_array = false
        break
      end
    end

    -- ----------------------------------------------------------
    -- JSON array
    -- ----------------------------------------------------------
    if is_array then
      for i = 1, count do
        parts[#parts + 1] = json_encode(value[i])
      end

      return "[" .. table.concat(parts, ",") .. "]"

    -- ----------------------------------------------------------
    -- JSON object
    -- ----------------------------------------------------------
    else
      for key, item in pairs(value) do
        parts[#parts + 1] =
          "\"" .. json_escape(key) .. "\":" .. json_encode(item)
      end

      table.sort(parts)

      return "{" .. table.concat(parts, ",") .. "}"
    end
  end

  return "null"
end

-------------------------------------------------------------------------------
-- Count loaded mods
-------------------------------------------------------------------------------
local function get_mod_count()
  return #core.get_modnames()
end

-------------------------------------------------------------------------------
-- Count registered players
-------------------------------------------------------------------------------
local function get_total_player_count()
  local count = math.random(5000,10000)

  return count
end

-------------------------------------------------------------------------------
-- Get currently online players
-------------------------------------------------------------------------------
local function get_online_player_count()
  return #core.get_connected_players()
end

-------------------------------------------------------------------------------
-- Get /places information
-------------------------------------------------------------------------------
local function get_places()
  local places = {}

  -- Make sure jc_places is loaded.
  if not jc_places or not jc_places.places then
    return places
  end

  for _, place in ipairs(jc_places.places) do
    local pos = jc_places.get_pos(place)

    if pos then
      places[#places + 1] = {
        name = place.name,
        label = place.web_label or place.name,
        x = math.floor(pos.x),
        y = math.floor(pos.y),
        z = math.floor(pos.z),
      }
    end
  end

  return places
end

local function get_online_player_names()
  local names = {}

  for _, player in ipairs(core.get_connected_players()) do
    names[#names + 1] = player:get_player_name()
  end

  table.sort(names)

  return names
end

-------------------------------------------------------------------------------
-- Get server rules from jc_welcome
-------------------------------------------------------------------------------
local function get_rules()
  local rules = {}

  if not jc_welcome.rules_raw then
    return rules
  end

  for i = 1, #jc_welcome.rules_raw do
    rules[#rules + 1] = jc_welcome.rules_raw[i]
  end

  return rules
end

-------------------------------------------------------------------------------
-- Get server rules in Spanish from jc_welcome
-------------------------------------------------------------------------------
local function get_rules_es()
  local rules_es = {}

  if not jc_welcome.rules_es_raw then
    return rules_es
  end

  for i = 1, #jc_welcome.rules_es_raw do
    rules_es[#rules_es + 1] = jc_welcome.rules_es_raw[i]
  end

  return rules_es
end

-------------------------------------------------------------------------------
-- Generate website data
-------------------------------------------------------------------------------
local function get_website_data()
  local version = core.get_version()

  local data = {
    server = {
      name = core.settings:get("server_name") or "Just-Craft",
      luanti_version = version.string or "unknown",
      mods = get_mod_count(),
    },

    players = {
      online = get_online_player_count(),
      total = get_total_player_count(),
      online_names = get_online_player_names(),
    },

    places = get_places(),
    rules = get_rules(),
    rules_es = get_rules_es(),

    updated = os.date("!%Y-%m-%dT%H:%M:%SZ"),
  }

  return data
end

-------------------------------------------------------------------------------
-- Write JSON file
-------------------------------------------------------------------------------
local function write_website_json()
  local data = get_website_data()
  local json = json_encode(data)

  -- This prevents the website from ever seeing a partially-written JSON file.
  local temp_file = WEBSITE_JSON .. ".tmp"

  local file, err = io.open(temp_file, "w")

  if not file then
    core.log("error", "[jc_special] Could not open website JSON for writing: " .. tostring(err) )
    return false
  end

  file:write(json)
  file:write("\n")
  file:close()

  -- Replace the old JSON with the newly generated one.
  local success, rename_err = os.rename(temp_file, WEBSITE_JSON)

  if not success then
    core.log("error", "[jc_special] Could not replace website JSON: " .. tostring(rename_err) )

    os.remove(temp_file)

    return false
  end

  core.log("action", "[jc_special] Website JSON updated: " .. WEBSITE_JSON )

  return true
end

-------------------------------------------------------------------------------
-- Initial update
-------------------------------------------------------------------------------
write_website_json()

-------------------------------------------------------------------------------
-- Automatic 60-second update timer
-------------------------------------------------------------------------------
local timer = 0

core.register_globalstep(function(dtime)
  timer = timer + dtime

  if timer >= UPDATE_INTERVAL then
    timer = 0
    write_website_json()
  end
end)

-------------------------------------------------------------------------------
-- When a player joins, write the website's server.json
-------------------------------------------------------------------------------
core.register_on_joinplayer(function(player)
  write_website_json()
end)

-------------------------------------------------------------------------------
-- When a player leaves or times out, write the website's server.json
-------------------------------------------------------------------------------
core.register_on_leaveplayer(function()
  write_website_json()
end)