local Network = require 'network'

Network.on('connected', function()
  print('This function is called as soon as the client connects to the server')
end)

local start = Network.getTime()
Network.on('pong', function(params)
  print('Ping took ' .. Network.getTime() - start .. ' seconds')
end)

Network.connect('127.0.0.1', 3000)

Network.send('ping', {Network.getTime()})

function love.update(dt)
  -- Update reads in any messages received from the server
  Network.update()
end

function love.draw()
  -- Network.connected is updated once the client receives an acknowledgement from the server
  if Network.connected then
    love.graphics.print('Connected to the server')
  else
    love.graphics.print('Connecting to the server...')
  end
end

function love.quit()
  -- You should call close on quit to let the server know that this client has left
  Network.close()
end
