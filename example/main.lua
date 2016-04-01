Server = require('server')
Network = require('network')

Ball = require('ball')
Paddle = require('paddle')

local ball = Ball:new()

function love.load()
  
end

function love.update(dt)
end

function love.keypressed(key)
  -- Quit on escape key
  if key == 'escape' then love.event.quit() end
end
