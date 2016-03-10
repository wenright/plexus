local server = require('server')

function love.update(dt)
  server.update()
end

function love.keypressed(key)
  if key == 'escape' then love.event.quit() end
end
