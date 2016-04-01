-- Network objects
Server = require('server')
Network = require('network')

-- Game objects
Objects = {
  Ball = require('ball'),
  Paddle = require('paddle')
}

-- Network variables, which ip/port to connect to
local ip, port = '127.0.0.1', 3000
local isServer = false

-- A table used to keep track of game objects
local gameObjects = {}

function love.load()
  local paddleLocationX

  -- Display connection option, allowing player to either host or join a game
  if love.window.showMessageBox("Host or join?",
    "Start a new game or connect to a server",
    {"Host", "Join"}) == 1 then
    -- Start a server on port 3000
    Server.start(port)
    isServer = true

    print("Starting server")
    paddleLocationX = 20
  else
    print("Joining a server")
    paddleLocationX = love.graphics.getWidth() - 40
  end

  -- Set some listeners.  Listen for 'connected' and 'instantiate' commands.
  Network.on('connected', function()
    -- Spawn our player's paddle.  Client will be on right side, server on left
    Network.instantiate('Paddle', {x = paddleLocationX})

    -- Only the server should spawn the ball
    if isServer then
      -- Spawn the ball
      Network.instantiate('Ball', {})
    end
  end)

  -- Add a listener for the instantiate command
  Network.on('instantiate', function(obj, playerID)
    -- Add a few variables to the properties value
    obj.properties.isLocalPlayer = (playerID == Network.id)
    obj.properties.id = obj.id

    -- Add it to the table of objects in our game
    table.insert(gameObjects, Objects[obj.type]:new(obj.properties))
  end)

  -- Connect to the server
  Network.connect(ip, port)
end

function love.update(dt)
  for key, obj in pairs(gameObjects) do
    obj:update(dt)
  end

  -- Update server and network.  These will receive messages and call the respective callback functions
  if isServer then
    Server.update()
  end
  Network.update()
end

function love.draw()
  for key, obj in pairs(gameObjects) do
    obj:draw()
  end
end

function love.keypressed(key)
  -- Quit on escape key
  if key == 'escape' then love.event.quit() end
end
