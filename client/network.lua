local socket = require('socket')

math.randomseed(os.time())

local network = {
  -- TODO a better way of creating an id (hash, MD5?)
  id = math.random(99999999),
  callbacks = {}
}

local udp = socket.udp()
assert(udp, 'Failed setting up UDP socket')
udp:settimeout(0)

function network.connect(ip, port)
  udp:setpeername(ip, port)

  -- Send the server a message
  udp:send(string.format('%s %s %d', network.id, 'join', os.time()))
end

function network.on(cmd, callback)
  network.callbacks[cmd] = calllback
end

function network.update()
  local data, err

  repeat
    data, err = udp:receive()

    if data then
      print(data)
      local id, cmd, params = data:match('^(%S*) (%S*) (.*)')

      print('Message received from server')
      print('ID: ' .. id)
      print('Command: ' .. cmd)
      print('Parameters: ' .. params)

      if network.callbacks[cmd] then
        network.callbacks[cmd](id, params)
      end
    elseif err ~= 'timeout' then
      error('Network error: ' .. tostring(err))
    end
  until not data
end

return network
