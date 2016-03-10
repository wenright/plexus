local socket = require('socket')

local network = {
  callbacks = {},
  id = 0
}

local udp = socket.udp()
assert(udp, 'Failed setting up UDP socket')
udp:settimeout(0)

function network.connect(ip, port, callback)
  udp:setpeername(ip, port)

  network.send('join', { os.time() })

  if callback then callback() end
end

function network.on(cmd, callback)
  network.callbacks[cmd] = callback
end

network.on('assignID', function(params)
  network.id = tonumber(params:match("%d*"))
end)


function network.send(cmd, params)
  local msg = network.id .. ' ' .. cmd
  
  for i, param in pairs(params) do
    msg = msg .. ' ' .. tostring(param)
  end

  udp:send(msg)
end

function network.update()
  local data, err

  repeat
    data, err = udp:receive()

    if data then
      print(data)
      local id, cmd, params = data:match('^(%S*) (%S*) (.*)')

      print('Message received from server')
      print('ID: ' .. tostring(id))
      print('Command: ' .. tostring(cmd))
      print('Parameters: ' .. tostring(params))

      if network.callbacks[cmd] then
        network.callbacks[cmd](params)
      end
    elseif err ~= 'timeout' then
      error('Network error: ' .. tostring(err))
    end
  until not data
end

return network
