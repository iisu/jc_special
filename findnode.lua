local S = core.get_translator(core.get_current_modname())

core.register_chatcommand("findnode", {
  params = "<mod:nodename> <radius>",
  description = S("Find nodes within a square radius"),
  privs = { server = true },

  func = function(name, param)
    local player = core.get_player_by_name(name)

    if not player then
      return false, S("Player not found.")
    end

    local args = param:split(" ")

    local nodename = args[1]
    local radius = tonumber(args[2])

    if not nodename or nodename == "" then
      return false, S("Usage: /findnode <mod:nodename> <radius>")
    end

    if not radius then
      return false, S("Radius must be a number.")
    end

    if radius <= 0 then
      return false, S("Radius must be greater than 0.")
    end

    local max_radius = 100

    if radius > max_radius then
      return false, S("Radius cannot be greater than @1 nodes.", max_radius)
    end

    local pos = player:get_pos()

    if not pos then
      return false, S("Could not determine your position.")
    end

    if not core.registered_nodes[nodename] then
      return false, S("Unknown node: @1", nodename)
    end

    local minp = {
      x = math.floor(pos.x - radius),
      y = math.floor(pos.y - radius),
      z = math.floor(pos.z - radius)
    }

    local maxp = {
      x = math.floor(pos.x + radius),
      y = math.floor(pos.y + radius),
      z = math.floor(pos.z + radius)
    }

    local found = {}

    local positions = core.find_nodes_in_area(
      minp,
      maxp,
      {nodename}
    )

    for _, found_pos in ipairs(positions) do
      local dx = found_pos.x - pos.x
      local dy = found_pos.y - pos.y
      local dz = found_pos.z - pos.z

      local distance = math.sqrt(
        dx * dx +
        dy * dy +
        dz * dz
      )

      table.insert(found, {
        pos = found_pos,
        distance = distance
      })
    end

    if #found == 0 then
      return false, S("No @1 found within @2 nodes.", nodename, radius)
    end

    table.sort(found, function(a, b)
      return a.distance < b.distance
    end)

    core.chat_send_player(name, core.colorize("#FFFF00", S("Found @1 @2 within a @3 node square:", #found, nodename, radius ) ) )

    for _, entry in ipairs(found) do
      local p = entry.pos
      core.chat_send_player(name, "  " .. S("@1 - @2 nodes away", core.colorize("#FFFF00", string.format("(%d, %d, %d)", p.x, p.y, p.z) ), string.format("%.1f", entry.distance) ) )
    end

    return true
  end
})