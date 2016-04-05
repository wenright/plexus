local Network = require 'network'

Network.on('connected', function()
  print('This function is called as soon as the client connects to the server')
end)

Network.connect('127.0.0.1', 3000)

function love.update(dt)
  -- Update reads in any messages received from the server
  Network.update()
end

function love.draw()
  -- Network.isConnected is updated once the client receives an acknowledgement from the server
  if Network.isConnected then
    love.graphics.print('Connected to the server')
  else
    love.graphics.print('Connecting to the server...')
  end
end

function love.quit()
  -- You should call close on quit to let the server know that this client has left
  Network.close()
end
