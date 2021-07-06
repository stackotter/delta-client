# TODO

- [ ] Remove need for `Server`.
- [ ] Remove event manager if possible and just use proper error handling. DeltaCore should just throw when there's an error and it's up to DeltaClient to handle it.
- [ ] `Client` should have a proper shutdown method and should allow a shutdown handler to be added.
- [ ] Packets should be passed `Client` instead of `Server`.
- [ ] `Client` should store the world and all that, the `ServerConnection` just does the networking.
- [ ] Use weak self in handlers and all that.
- [ ] Change ping message to 'Server Offline' instead of pinging when server has responded to ping and is offline