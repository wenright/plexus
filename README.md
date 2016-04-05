# Plexus
A networking library for games in Lua.  Written for [LOVE](love2d.org) games, but can be used in any Lua program as long as LuaSockets are available.

# Usage
To start a server, simply call start with a port number
``` Lua
Server.start(3000)
```

To connect to that server, call connect with an ip and a port
``` Lua
Network.connect('127.0.0.1', 3000)
```

Plexus uses listeners to trigger messages received by the server. For example...
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

## Note
Currently, this library uses [knife.serialize](https://github.com/airstruck/knife/blob/master/readme/serialize.md).  I am working on a small serializer that will sit inside the library itself, so it does not require any other dependencies.  
