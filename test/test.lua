describe('Plexus', function()
  local Network = require 'network'
  local Server = require 'server'

  it('must have sockets installed', function()
    assert.truthy(require 'socket')
  end)

  it('Unable to locate plexus.network', function()
    assert.truthy(Network)
  end)

  it('Unable to locate plexus.server', function()
    assert.truthy(Server)
  end)

  Server.start(3000)

  local pingCalled = false
  Server.on('ping', function(params, id, ip, port)
    pingCalled = true
    return 'pong', params
  end)

  local connectedCalled = false
  Network.on('connected', function()
    connectedCalled = true
  end)

  local pongCalled = false
  Network.on('pong', function(params)
    pongCalled = true
  end)

  Network.connect('127.0.0.1', 3000)

  Network.send('ping', Network.getTime())

  local start = os.time()
  repeat
    Network.update()
    Server.update()
  until os.time() - start > 5 or (pingCalled and connectedCalled and pongCalled)

  it('server should have called ping', function()
    assert.truthy(pingCalled)
  end)

  it('client should have called connected', function()
    assert.truthy(connectedCalled)
  end)

  it('client should have called pong', function()
    assert.truthy(pongCalled)
  end)
end)
