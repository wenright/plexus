--- Client example
-- Run with `love example/client`
-- @module ClientExample

local Network = require 'network'

Network.on('connected', function()
  -- Do things here
end)

Network.connect('127.0.0.1', 3000)

function love.update(dt)
  Network.update()
end

function love.draw()
  if Network.isConnected then
    love.graphics.print('Connected to the server')
  else
    love.graphics.print('Connecting to the server...')
  end
end

function love.quit()
  Network.close()
end
