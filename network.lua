local socket = require('socket')
local Serialize = require('lib.serialize')

local Network = {
  callbacks = {},
  id = 0,
  sendrate = 0.1,
  lastSend = 0,
  localVariables = {},
  variables = {}
}

local udp = socket.udp()
assert(udp, 'Failed setting up UDP socket')
udp:settimeout(0)

function Network.connect(ip, port)
  udp:setpeername(ip, port)

  Network.time = 0

  Network.send('join', { os.time() })

  Network.isConnected = false
  Network.on('acknowledgeJoin', function(msg)
    print("Connected to server")
    Network.isConnected = true
    Network.id = msg
  end)

  -- Continuously try to connect to server, give up after 5 seconds
  local startTime = os.time()
  local maxWaitTime = 5 * 1000
  repeat
    local response = Network.update() or 1

    if os.time() - startTime >= maxWaitTime then
      error('Failed to connect to server')
    end
  until Network.isConnected or response == -1

  if Network.isConnected then
    Network.log('Connected to server')

    Network.lastSend = os.time()

    Network.instantiate('Player', {x = 0, y = 0})
  else
    Network.log('Unable to connect to server')
  end
end

function Network.on(cmd, callback)
  Network.callbacks[cmd] = callback
end

Network.on('update', function(params)
  for objectID, newValue in pairs(params) do
    local v = Network.variables[objectID]
    if v and v._listen then
      if v._interpolate then
        Timer.tween(Network.sendrate, v[v._listen], newValue, 'linear')
      else
        v[v._listen] = newValue
      end
    end
  end
end)

Network.on('instantiate', function(obj, playerID)
  assert(Objects[obj.type], 'Object of type ' .. tostring(obj.type) .. ' does not exist.')
  assert(obj.properties, 'Must assign properties when instantiating a new object')

  obj.properties.isLocalPlayer = playerID == Network.id
  obj.properties.id = obj.id

  Game.entities:add(obj.id, Objects[obj.type](obj.properties))
end)

Network.on('destroy', function(msg)
  Game.entities:remove(msg.id)
end)

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

  udp:send(msg)
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
    data, err = udp:receive()

    if data then
      local id, cmd, params = data:match('^(%S*) (%S*) (.*)')

      if Network.callbacks[cmd] then
        Network.callbacks[cmd](Deserialize(params), tonumber(id))
      else
        Network.log('Unknown command "' .. cmd .. '"')
      end
    elseif err ~= 'timeout' then
      -- TODO show some kind of toast to tell user there was an error
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
