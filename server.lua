local socket = require('socket')
local Serialize = require('lib.serialize')

local Server = {
  callbacks = {},
  id = -1,
  players = {},
  numPlayers = 0,
  entities = {},
  udp = nil,
  Serialize = Serialize
}

local DEBUG = true

function Server.start()
  math.randomseed(os.time())

  Server.udp = socket.udp()
  assert(Server.udp, 'UDP creation failed')
  Server.udp:settimeout(0)

  Server.udp:setsockname('*', 3000)

  Server.log('Server started')
end

function Server.on(cmd, callback)
  Server.callbacks[cmd] = callback
end

function Server.send(ip, port, cmd, params, playerID)
  local msg = playerID .. ' ' .. cmd .. ' ' .. params

  Server.udp:sendto(msg, ip, port)
end

function Server.broadcast(cmd, params, playerID)
  for i, player in pairs(Server.players) do
    Server.send(player.ip, player.port, cmd, params, playerID)
  end
end

function Server.instantiate(params, senderID)
  local id
  repeat
    id = Server.newID()
  until not Server.entities[id]

  local t = Server.Deserialize(params)

  t.id = id
  t.ownerID = senderID
  Server.entities[id] = t

  params = Server.Serialize(t)

  -- TODO send to other clients with a delay?
  Server.broadcast('instantiate', params, senderID)
end

function Server.update()
  local data, ip, port = Server.udp:receivefrom()

  if data then
    local playerID, cmd, params = data:match('^(%S*) (%S*) (.*)')

    if Server.callbacks[cmd] then
      local msg, params = Server.callbacks[cmd](params, playerID, ip, port)
      if msg then
        Server.send(ip, port, msg, params, playerID)
      end
    else
      Server.broadcast('update', params, playerID)
    end
  elseif ip == 'closed' then
    -- This should mean that the player has disconnected
  elseif ip == 'timeout' then
    -- This could mean that no one is connected
  elseif ip == 'refused' then
    -- This probably just means there are no clients connected
  else
    error('Unknown network error: ' .. tostring(ip))
  end

  socket.sleep(1)
end

-- These are a few built-in listeners that the user can feel free to change
Server.on('join', function(params, nil_id, ip, port)
  -- When a new user joins the room, assign them a new ID
  local id = Server.newID()

  Server.players[id] = {
    ip = ip,
    port = port,
    id = id
  }

  Server.numPlayers = Server.numPlayers + 1

  -- Send this new player all of the things that are currently spawned in the Server
  for key, entity in pairs(Server.entities) do
    Server.send(ip, port, 'instantiate', Server.Serialize(entity), entity.ownerID)
  end

  Server.log('New player joined.  Assigning ID ' .. id)

  return 'acknowledgeJoin', Server.Serialize(id)
end)

Server.on('quit', function(params, id)
  Server.log('Player ' .. id .. ' is exiting')
  Server.players[id] = nil
  Server.numPlayers = Server.numPlayers - 1

  -- Remove all of a players objects when they leave
  for key, entity in pairs(Server.entities) do
    if entity.ownerID == id then
      Server.entities[entity.id] = nil
      Server.broadcast('destroy', Server.Serialize({id = entity.id}), id)
    end
  end

  -- Clear out the objects on the server if that last player leaves
  if Server.numPlayers == 0 then
    Server.entities = {}

    -- TODO Close down server after all players leave?
    Server.log('Closing server')
    love.event.quit()
  end
end)

Server.on('instantiate', function(params, senderID)
  Server.instantiate(params, senderID)
end)

function Server.Deserialize(ser)
  return setfenv(loadstring(ser), {})()
end

function Server.newID()
  -- TODO better new id method
  local id
  repeat
    id = math.random(999999)
  until not Server.entities[id]
  return id
end

function Server.log(str)
  -- TODO write to log file
  if DEBUG then
    print(str)
  end
end

return Server
