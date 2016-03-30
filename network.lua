local socket = require('socket')
local Serialize = require('lib.serialize')

local Network = {
  udp = nil,
  callbacks = {},
  id = 0,
  sendrate = 0.1,
  lastSend = 0,
  localVariables = {},
  variables = {}
}

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

function Network.watch(objectID, t)
  Network.localVariables[objectID] = t
end

function Network.listen(objectID, name, t, interpolate)
  Network.variables[objectID] = t
  Network.variables[objectID]._listen = name
  Network.variables[objectID]._interpolate = interpolate
end

function Network.send(cmd, params)
  local msg = Network.id .. ' ' .. cmd .. ' ' .. Serialize(params)

  Network.udp:send(msg)
end

function Network.instantiate(t, properties)
  Network.send('instantiate', {type = t, properties = properties})
end

function Network.destroy(id)
  Network.send('destroy', {id = id})
end

function Network.update(dt)
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

function Deserialize(ser)
  return setfenv(loadstring(ser), {})()
end

function Network.log(str)
  -- TODO write to file
  if DEBUG then
    print(str)
  end
end

return Network
