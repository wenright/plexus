describe('Plexus', function()
  it('must have sockets installed', function()
    assert.truthy(require 'socket')
  end)

  describe('Client: ', function()
    local Network = require 'network'

    it('Unable to locate plexus.network', function()
      assert.truthy(Network)
    end)

    Network.on('connected', function()
      print('This function is called as soon as the client connects to the server')
    end)

    local start = Network.getTime()
    Network.on('pong', function(params)
      print('Ping took ' .. Network.getTime() - start .. ' seconds')
    end)

    Network.connect('127.0.0.1', 3000)

    Network.send('ping', Network.getTime())
  end)

end)
