--- Used on the client side to communicate with a server
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
-- @table Network
local Network = {
  udp = nil,
  callbacks = {},
  id = 0,
  sendrate = 0.1,
  lastSend = os.time(),
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

  Network.send('join', {})

  Network.isConnected = false
  Network.on('acknowledgeJoin', function(msg)
    Network.isConnected = true
    Network.id = msg

    if Network.callbacks['connected'] then
      Network.callbacks['connected']()
    end
  end)
end

--- Used to set callbacks which are called when the server sends a certain command
-- @tparam string cmd The command to listen for. Ex: 'update'
-- @tparam function callback The function called when this command arrives
function Network.on(cmd, callback)
  Network.callbacks[cmd] = callback
end

--- Send a message to the server, it will be passed to clients
-- @tparam string cmd The command to send.  This should be the same as the listener on the server side
-- @tparam table params Parameters to send to the listeners.  It will be serialized to a string and deserialized later
function Network.send(cmd, params)
  local msg = Network.id .. ' ' .. cmd .. ' ' .. Serialize(params)

  print(Network.udp:send(msg))
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
