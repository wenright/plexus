# Plexus
A networking library for games in Lua.  Written for [LOVE](love2d.org) games, but can be used in any Lua program as long as [LuaSockets](http://w3.impa.br/~diego/software/luasocket/) are available.

# Usage
To start a server
``` Lua
Server.start(3000)
```

To connect to that server
``` Lua
Network.connect('127.0.0.1', 3000)
```

Plexus uses listeners to trigger messages received from the server. For example...
``` Lua
Network.on('ping', function(message)
  print('Received a message!")
end)
```
... will tell the network to call that function once it receives a 'ping' command.  To execute that command, use...
``` Lua
Server.send('ping', Network.getTime())
```
... On the server side.  The second parameter is the message you are sending.  This can be anything from a number to a table.

`send` will be called immediately, but the callbacks for `on` are only triggered in `update`.  So, make sure to have some sort of an infinite loop calling `Network.update()`. 
