local Server = require 'server'

Server.start(3000)

Server.on('ping', function(params, id, ip, port)
  -- You can return a send command that will be sent to the client that issued this command
  return 'pong', params
end)

function love.update(dt)
  Server.update()
end

function love.draw()
  love.graphics.print(Server.numPlayers .. ' user(s) connected to the server.')
end
