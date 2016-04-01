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
  -- Display connection option, allowing player to either host or join a game
  if love.window.showMessageBox("Host or join?",
    "Start a new game or connect to a server",
    {"Host", "Join"}) == 1 then
    -- Start a server on port 3000
    Server.start(port)
    isServer = true

    print("Starting server")

    -- Connect to the server
    Network.connect(ip, port)

    -- Spawn the server's paddle on the left side
    Network.instantiate('Paddle', {x = 20})

    -- Spawn the ball
    Network.instantiate('Ball', {})
  else
    print("Joining a server")

    -- Connect to the server
    Network.connect(ip, port)

    -- Spawn our player's paddle.  Client will be on right side, server on left
    Network.instantiate('Paddle', {x = love.graphics.getWidth() - 40})
  end

  -- Add a listener for the instantiate command
  Network.on('instantiate', function(obj, playerID)
    -- Instantiate an object of the same type as passed in by the callback
    local newObj = Objects[obj.type]:new(obj.properties)

    -- Check to see if we instantiated this object
    newObj.isLocalPlayer = (playerID == Network.id)

    -- Add it to the table of objects in our game
    table.insert(gameObjects, newObj)
  end)
end

function love.update(dt)
  for key, obj in pairs(gameObjects) do
    obj:draw()
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
