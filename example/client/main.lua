local network = require('network')

network.connect('localhost', 3000)

function love.update(dt)
  network.update()
end

function love.keypresesd(key)
  if key == 'escape' then love.event.quit() end
end
