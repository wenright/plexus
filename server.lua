--- Keeps clients up to date by sending messages back and forth
-- @module Server
-- @author Will
-- @release 0.0.1

local socket = require('socket')
local Serialize = require('lib.serialize')

--- Stores network variables and callbacks
-- @field udp The interface with the clients
-- @field callbacks A table filled with callbacks that the user creates
-- @field id The ID assigned to the server. Default: -1
-- @field players A table filled with player objects
-- @field numPlayers Keeps track of the number of players connected to the server
-- @field entities Keeps track of any entities spawned into the game with instantiate
-- @table Network
local Server = {
  udp = nil,
  callbacks = {},
  id = -1,
  players = {},
  numPlayers = 0,
  entities = {},
  Serialize = Serialize
}

local DEBUG = true

--- First call, used to initialize the server.  Sets up UDP to listen for clients
function Server.start()
  math.randomseed(os.time())

  Server.udp = socket.udp()
  assert(Server.udp, 'UDP creation failed')
  Server.udp:settimeout(0)

  Server.udp:setsockname('*', 3000)

  Server.log('Server started')
end

--- Used to set callbacks which are called when the clients send a certain command.
-- The function can return a string and a table as a parameter, which will then be broadcasted
--   to all players on the server.
-- @tparam string cmd The command to listen for. Ex: 'update'
-- @tparam function callback The function called when this command arrives
function Server.on(cmd, callback)
  Server.callbacks[cmd] = callback
end

--- Sends a message to the clients
-- @tparam string ip IP to send the command to
-- @tparam number port Port to send the command to
-- @tparam string cmd The command to send.  This should be the same as the listener on the client side
-- @tparam table params Parameters to send to the listeners.  It will be serialized to a string and deserialized later
-- @tparam number playerID The ID of the player sending the command
function Server.send(ip, port, cmd, params, playerID)
  local msg = playerID .. ' ' .. cmd .. ' ' .. params

  Server.udp:sendto(msg, ip, port)
end

--- Send a message from one player to every player on the server
-- @tparam string cmd The command to send.  This should be the same as the listener on the client side
-- @tparam table params Parameters to send to the listeners.  It will be serialized to a string and deserialized later
-- @tparam number playerID The ID of the player sending the command
function Server.broadcast(cmd, params, playerID)
  for i, player in pairs(Server.players) do
    Server.send(player.ip, player.port, cmd, params, playerID)
  end
end

--- Spawn an object accross all clients
-- @tparam table params Parameters to send to the listeners.  It will be serialized to a string and deserialized later
-- @tparam number senderID The ID of the player sending the command
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

--- Update the network.  Loops through all messages, handling them by calling their callbacks
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

--- Deserialize a string by running it with Lua
function Server.Deserialize(ser)
  return setfenv(loadstring(ser), {})()
end

--- Create a new ID used for either entities or players.  The ID is unique and ranges from [0, 999999]
-- @return number The newly created ID
function Server.newID()
  -- TODO better new id method
  local id
  repeat
    id = math.random(999999)
  until not Server.entities[id]
  return id
end

--- Print to the command line and log to a file
-- @tparam string str The string to log
-- @todo write string to a log file
function Server.log(str)
  -- TODO write to log file
  if DEBUG then
    print(str)
  end
end

return Server
