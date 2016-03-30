--- The network object.  Used on the client side to communicate with a server
-- @module Network
-- @author Will
-- @release 0.0.1

local socket = require('socket')
local Serialize = require('lib.serialize')

--- Stores network variables and callbacks
-- @field udp The interface with the server
-- @field callbacks A table filled with callbacks that the user creates
-- @field id The ID assigned to this client by the server
-- @field sendrate How often to send updates to the server
-- @field localVariables Variables that this client is remembering, and updating to the server
-- @field variables Network variables that this client does not own, they will be updated by the server (from other clients)
-- @table Network
local Network = {
  udp = nil,
  callbacks = {},
  id = 0,
  sendrate = 0.1,
  lastSend = 0,
  localVariables = {},
  variables = {}
}

--- Connect to the server at ip:port.  First function to be called once network is created
-- @tparam string ip IP address of the server
-- @tparam number port Port to connect to
function Network.connect(ip, port)
  Network.udp = socket.udp()
  assert(Network.udp, 'Failed setting up UDP socket')

  Network.udp:settimeout(0)
  Network.udp:setpeername(ip, port)

  Network.time = 0

  Network.send('join', { os.time() })

  Network.isConnected = false
  Network.on('acknowledgeJoin', function(msg)
    print("Connected to server")
    Network.isConnected = true
    Network.id = msg
  end)
end

--- Used to set callbacks which are called when the server sends a certain command
-- @tparam string cmd The command to listen for. Ex: 'update'
-- @tparam function callback The function called when this command arrives
function Network.on(cmd, callback)
  Network.callbacks[cmd] = callback
end

Network.on('update', function(params)
  for objectID, newValue in pairs(params) do
    local v = Network.variables[objectID]
    if v and v._listen then
      if v._interpolate then
        -- TODO add tween function
        -- Timer.tween(Network.sendrate, v[v._listen], newValue, 'linear')
        v[v._listen] = newValue
      else
        v[v._listen] = newValue
      end
    end
  end
end)

-- These two are ones that the client would have to implement
-- TODO remove from here and add an example
Network.on('instantiate', function(obj, playerID) end)
Network.on('destroy', function(msg) end)

--- Watch a local variable, updating it to the server and other clients
-- @tparam number objectID The objects ID, given by the server
-- @tparam table t This is the table that will be watched
function Network.watch(objectID, t)
  Network.localVariables[objectID] = t
end

--- Listen to an object over the server
-- @tparam number objectID The objects ID, given by the server
-- @tparam string name The key of the table to listen for
-- @tparam table t The table to listen to
-- @tparam bool interpolate Whether or not to interpolate between previous and new values
-- @warning Interpolate does not work currently, will be added later
function Network.listen(objectID, name, t, interpolate)
  Network.variables[objectID] = t
  Network.variables[objectID]._listen = name
  Network.variables[objectID]._interpolate = interpolate
end

--- Send a message to the server, it will be passed to clients
-- @tparam string cmd The command to send.  This should be the same as the listener on the client side
-- @tparam table params Parameters to send to the listeners.  It will be serialized to a string and deserialized later
function Network.send(cmd, params)
  local msg = Network.id .. ' ' .. cmd .. ' ' .. Serialize(params)

  Network.udp:send(msg)
end

--- instantiate an object accross the server.  This needs to be implemented by the user
-- @param t The type of object to instantiate
-- @tparam table properties Properties to spawn object with
function Network.instantiate(t, properties)
  Network.send('instantiate', {type = t, properties = properties})
end

--- Send a destroy command to the server.  Listener needs to be implemented by client
-- @tparam number id ID of object to destroy
function Network.destroy(id)
  Network.send('destroy', {id = id})
end


--- Update the network.  Loops through all messages (max of 500 per update), handling them by calling their callbacks
-- @treturn number -1 if a timeout error occurred, or nil
function Network.update()
  -- Receive data
  local data, err
  local maxReceives = 500

  repeat
    data, err = Network.udp:receive()

    if data then
      local id, cmd, params = data:match('^(%S*) (%S*) (.*)')

      if Network.callbacks[cmd] then
        Network.callbacks[cmd](Deserialize(params), tonumber(id))
      else
        Network.log('Unknown command "' .. cmd .. '"')
      end
    elseif err ~= 'timeout' then
      -- TODO show some kind of error message?
      print('Network error: ' .. tostring(err))
      return -1
    end

    maxReceives = maxReceives - 1
  until not data or maxReceives <= 0

  -- Send data
  if Network.lastSend - os.time() >= Network.sendrate then
    Network.send('update', Network.localVariables)

    Network.lastSend = os.time()
  end
end

--- Deserialize a string from the server by running the string and returning the result
-- @tparam string ser The string to be deserialized
function Deserialize(ser)
  return setfenv(loadstring(ser), {})()
end

--- Print to the command line and log to a file
-- @tparam string str The string to log
-- @todo write string to a log file
function Network.log(str)
  -- TODO write to file
  if DEBUG then
    print(str)
  end
end

return Network
