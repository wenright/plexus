local Paddle = {}

function Paddle:new(properties)
  assert(properties.x, 'X value must be assigned when creating a new paddle')

  local p = {x = properties.x, y = love.graphics.getHeight() / 2}

  setmetatable(ball, self)
  self.__index = self

  return ball
end

function Paddle:update(dt)

end

function Paddle:draw()
  love.graphics.setColor(255, 200, 0)
end

return Paddle
