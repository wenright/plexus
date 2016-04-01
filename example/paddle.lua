local Paddle = {}

function Paddle:new(properties)
  assert(properties.x, 'X value must be assigned when creating a new paddle')
  assert(properties.id, 'Paddle must have a network ID')

  local paddle = {
    position = {
      x = properties.x,
      y = love.graphics.getHeight() / 2 - 50
    },
    id = properties.id,
    isLocalPlayer = properties.isLocalPlayer
  }

  Paddle.sync(paddle)

  setmetatable(paddle, self)
  self.__index = self

  return paddle
end

function Paddle:sync()
  if self.isLocalPlayer then
    -- Watch for changes and update the server with them
    Network.watch(self.id, self.position)
  else
    -- Listen to the server for changes
    Network.listen(self.id, 'position', self, true)
  end
end

function Paddle:update(dt)
  if self.isLocalPlayer then
    -- Move our paddle here
    if love.keyboard.isDown('w', 'up') then
      self.position.y = self.position.y + 1000 * dt
    elseif love.keyboard.isDown('s', 'down') then
      self.position.y = self.position.y - 1000 * dt
    end
  end
end

function Paddle:draw()
  love.graphics.setColor(255, 200, 0)
  love.graphics.rectangle('fill', self.position.x, self.position.y, 20, 100)
end

return Paddle
