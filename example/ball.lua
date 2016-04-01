local Ball = {}

local speed = 1000
local radius = 15

function Ball:new(properties)
  local ball = {
    position = {
      x = love.graphics.getWidth() / 2,
      y = love.graphics.getHeight() / 2
    },
    vx = love.math.random(),
    vy = love.math.random(),
    id = properties.id,
    isLocalPlayer = properties.isLocalPlayer
  }

  setmetatable(ball, self)
  self.__index = self

  return ball
end

function Ball:update(dt)
  if self.isLocalPlayer then
    -- Update position
    self.position.x, self.position.y = self.position.x + self.vx * dt * speed, self.position.y + self.vy * dt * speed

    -- Perform collision detection with top and bottom walls
    if self.position.y > love.graphics.getHeight() - radius or self.position.y < radius then
      self.vy = self.vy * -1
    end
  end
end

function Ball:draw()
  love.graphics.setColor(255, 255, 255)
  love.graphics.circle('fill', self.position.x, self.position.y, radius)
end

return Ball
