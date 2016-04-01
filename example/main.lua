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

    -- Spawn the server's paddle on the left side
    Network.instantiate('Paddle', {x = 20})

    -- Spawn the ball
    Network.insantiate('Ball', {})
  else
    print("Joining a server")

    -- Spawn our player's paddle.  Client will be on right side, server on left
    Network.instantiate('Paddle', {x = love.graphics.getWidth() - 20})
  end

  -- Connect to the server
  Network.connect(ip, port)

  -- Add a listener for the instantiate command
  Network.on('instantiate', function(properties)
    -- Instantiate an object of the same type as passed in by the callback
    table.insert(gameObjects, Objects[properties.type]:new(properties))
  end)
end

function love.update(dt)
  -- Update server and network.  These will receive messages and call the respective callback functions
  if isServer then
    Server.update()
  end
  Network.update()
end

function love.draw()

end

function love.keypressed(key)
  -- Quit on escape key
  if key == 'escape' then love.event.quit() end
end
