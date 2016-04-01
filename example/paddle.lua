local Paddle = {}

function Paddle:new(properties)
  assert(properties.x, 'X value must be assigned when creating a new paddle')

  local paddle = {x = properties.x, y = love.graphics.getHeight() / 2}

  setmetatable(paddle, self)
  self.__index = self

  return paddle
end

function Paddle:update(dt)
  if self.isLocalPlayer then
    -- Move our paddle here
  end
end

function Paddle:draw()
  love.graphics.setColor(255, 200, 0)
  love.graphics.rectangle('fill', self.x, self.y, 20, 100)
end

return Paddle
