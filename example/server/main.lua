local Server = require 'server'

Server.start(3000)

function love.update(dt)
  Server.update()
end

function love.draw()
  love.graphics.print(Server.numPlayers .. ' user(s) connected to the server.')
end
