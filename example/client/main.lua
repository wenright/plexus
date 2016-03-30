local network = require('network')

network.connect('localhost', 3000)

function love.update(dt)
  -- network.update()
end

function love.keypressed(key)
  if key == 'escape' then love.event.quit() end
end
