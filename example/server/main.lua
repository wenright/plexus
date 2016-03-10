local server = require('server')

math.randomseed(os.time())

server.on('join', function(id, ip)
  -- When a new user joins the room, assign them an ID
  -- TODO make sure that this ID doesn't already exist
  return 'assignID', { math.random(999999) }
end)

function love.update(dt)
  server.update()
end
