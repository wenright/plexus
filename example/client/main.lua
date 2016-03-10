local network = require('network')

network.connect('localhost', 3000, function()	
  network.send('join', {os.time()})
end)

network.on('assignID', function(id, params)
  network.setID(params.id)
end)

network.on('test', function(id, params)
  print('test from '..id)
end)

function love.update(dt)
  network.update()
end

function love.keypresesd(key)
  if key == 'escape' then love.event.quit() end
end
