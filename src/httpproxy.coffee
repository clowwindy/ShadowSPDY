# a http to spdy proxy

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
url = require 'url'

agent = null

reloadAgent = ->
  agent = spdy.createAgent(
    host: '127.0.0.1',
    port: 1443,
    rejectUnauthorized: false,
    requestCert: true,
    spdy: {
      plain: false
      ssl: true
      version: 3 # Force SPDY version
    }
  )
  agent.on 'error', (e) ->
    console.error e

reloadAgent()

server = http.createServer (req, res) ->
  srvUrl = url.parse(req.url)
  console.log srvUrl
  remoteReq = http.get({
      agent:agent,
      method:req.method,
      hostname:srvUrl.hostname,
      port:(srvUrl.port or 80),
      path:srvUrl.href,
      headers:req.headers,
      trailers:req.trailers,
      httpVersion:req.httpVersion
  }, (remoteRes) ->
    console.log 'remote res'
    res.writeHead remoteRes.statusCode
    res.on 'data', (chunk) ->
      console.log 'res on data'
      remoteRes.write chunk
    remoteRes.on 'data', (chunk) ->
      console.log 'remote res on data'
      res.write chunk
    res.on 'end', ->
      console.log 'res on end'
      remoteRes.end()
    remoteRes.on 'end', ->
      console.log 'remote res on end'
      res.end()
  )
  console.log 'req'

server.on 'connect', (req, socket) ->
  console.log 'connect'
  srvUrl = url.parse('http://' + req.url)
  
server.listen 8080 


#agent = spdy.createAgent({
#  host: 'www.google.com',
#  port: 443,
#
#  # Optional SPDY options
#  spdy: {
#    plain: false
#    ssl: true
#    version: 3 # Force SPDY version
#  }
#});
#
#http.get({
#  host: 'www.google.com',
#  agent: agent
#}, (response) -> 
#  console.log('yikes')
#  console.log response
#  agent.close()
#).end()