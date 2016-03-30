local Server = require('server')

function love.load()
  Server.load()
end

function love.update(dt)
  Server.update()
end
