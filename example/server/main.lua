local Server = require('server')

function love.load()
  Server.start()
end

function love.update(dt)
  Server.update()
end
