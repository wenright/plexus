local socket = require('socket')

local server = {
  callbacks = {},
  id = -1
}

math.randomseed(os.time())

local udp = socket.udp()
assert(udp, 'UDP creation failed')
udp:settimeout(0)

udp:setsockname('*', 3000)

print('Server started')

function server.on(cmd, callback)
  server.callbacks[cmd] = callback
end

server.on('join', function(id, ip)
  -- When a new user joins the room, assign them an ID
  -- TODO make sure that this ID doesn't already exist
  return 'assignID', { math.random(999999) }
end)

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
