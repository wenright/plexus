local socket = require('socket')

local server = {}

local udp = socket.udp()
assert(udp, 'UDP creation failed')
udp:settimeout(0)

udp:setsockname('*', 3000)

print('Server started')

local data, msg, port
  
function server.update()
  data, ip, port = udp:receivefrom()

  if data then
    local id, cmd, params = data:match('^(%S*) (%S*) (.*)')

    print('Message received from a client')
    print('ID: ' .. id)
    print('Command: ' .. cmd)
    print('Parameters: ' .. params)
  
    -- Respond to the client
    udp:sendto('0 test parameters_go_here', ip, port)
  elseif ip ~= 'timeout' then
    error('Unknown network error: ' .. tostring(ip))
  end
end

return server
