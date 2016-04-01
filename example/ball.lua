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
  -- Update position
  self.x, self.y = self.x + self.vx * dt * speed, self.y + self.vy * dt * speed
end

function Ball:draw()

end

return Ball
