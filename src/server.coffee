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
spdy = require 'spdy'
http = require 'http'
net = require 'net'
url = require 'url'

conn = null

server = net.createServer (socket) ->
  console.log 'socket'
  conn = new spdy.Connection(socket, {
    isServer: true,
    client: false
  }, server)
 
  conn._setVersion(3.1)
  
  conn.on 'error', (err) ->
    console.error err
    
  conn.on 'stream', (stream) ->
    console.log 'stream'
    stream.on 'data', (data) ->
      console.log data.toString('binary')
      stream.write 'hello world!\n'
      stream.end()
       
    stream.on 'end', ->
      stream.end()
      console.log 'end'
      
    stream.on 'close', ->
      console.log 'close'
      stream.close()
  
server.listen 8488


