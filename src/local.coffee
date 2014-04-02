# Copyright (c) 2014 clowwindy
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

fs = require 'fs'
net = require 'net'
spdy = require 'spdy'
#http = require 'http'

socket = net.connect {port: 8488}, ->
  connection = new spdy.Connection(socket, {
    isServer: false
  })
  connection._setVersion(3.0)
  connection.on 'error', (err) ->
    console.error err
    
  stream = new spdy.Stream(connection, {
    id: 1,
    priority: 7
  })
  
  # a silly patch to send SYN_STREAM frame
  headers = {}
  state = stream._spdyState
  connection._lock ->
    state.framer.streamFrame state.id, 0, {
      priority: 7
    }, headers, (err, frame) ->
      if (err) 
        connection._unlock()
        return self.emit('error', err)
      connection.write(frame)
      connection._unlock()
      connection._addStream(stream)
  
      stream.emit('_spdyRequest')
      state.initialized = true
  
  stream.on 'error', (err) ->
    console.error err
    
  stream.on 'data', (data) ->
    console.log data.toString('binary')
    
  stream.on 'end', ->
    stream.end()
    console.log 'end'
    
  stream.on 'close', ->
    console.log 'close'
    stream.close()
    
  stream.write('hi!\n')
  
