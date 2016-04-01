local Ball = {}

function Ball:new()
  local ball = {
    x = love.graphics.getWidth() / 2,
    y = love.graphics.getHeight() / 2,
    vx = love.math.random(),
    vy = love.math.random()
  }

  setmetatable(ball, self)
  self.__index = self

  return ball
end

function Ball:update(dt)
  if self.isLocalPlayer then
    -- Update position
    self.x, self.y = self.x + self.vx * dt * speed, self.y + self.vy * dt * speed
  end
end

function Ball:draw()
  love.graphics.setColor(255, 255, 255)
  love.graphics.circle('fill', self.x, self.y, 15, 25)
end

return Ball
