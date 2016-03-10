local socket = require('socket')

local server = {
  callbacks = {},
  id = -1
}

local udp = socket.udp()
assert(udp, 'UDP creation failed')
udp:settimeout(0)

udp:setsockname('*', 3000)

print('Server started')

function server.on(cmd, callback)
  server.callbacks[cmd] = callback
end
  
function server.send(ip, port, cmd, params)
  local msg = server.id .. ' ' .. cmd
  for i, param in pairs(params) do
    msg = msg .. ' ' .. param
  end

  udp:sendto(msg, ip, port)
end

function server.update()
  local data, ip, port = udp:receivefrom()

  if data then
    local id, cmd, params = data:match('^(%S*) (%S*) (.*)')

    print('Message received from a client')
    print('ID: ' .. tostring(id))
    print('Command: ' .. tostring(cmd))
    print('Parameters: ' .. tostring(params))

    if server.callbacks[cmd] then
      local msg, params = server.callbacks[cmd](id, ip, params)
      if msg then
        server.send(ip, port, msg, params or {})
      end
    end
  elseif ip ~= 'timeout' then
    error('Unknown network error: ' .. tostring(ip))
  end
end

return server
