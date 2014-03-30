# a spdy to http proxy

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

encodeHeaders = (headers) ->
  newHeaders = {}
  for k, v of headers
    k = k.toLowerCase()
    if k in ["transfer-encoding", "connection", 'content-encoding']
      newHeaders["sp-#{k}"] = v
    else
      newHeaders[k] = v
  console.log newHeaders
  newHeaders

filterHeaders = (headers) ->
  newHeaders = {}
  for k, v of headers
    ks = k.split('-')
    newKs = []
    for sep in ks
      if sep.length > 0
        sep = sep.charAt(0).toUpperCase() + sep.slice(1)
      newKs.push sep
    k = newKs.join '-'
    newHeaders[k] = v
  console.log newHeaders
  newHeaders
    
options = {
#  ssl: false,
#  plain: true,
  key: fs.readFileSync('key.pem'),
  cert: fs.readFileSync('cert.pem'),
#  ca: fs.readFileSync(__dirname + '/keys/spdy-ca.pem'),
  windowSize: 1024 * 1024, #

# **optional** if true - server will send 3.1 frames on 3.0 *plain* spdy
  autoSpdy31: false
}

server = spdy.createServer options, (req, res) ->
  console.log 'req'
  srvUrl = url.parse(req.url)
  console.log srvUrl
  remoteReq = http.get({
      hostname:srvUrl.hostname,
      path:srvUrl.path,
      port:(srvUrl.port or 80),
      headers:filterHeaders(req.headers),
      trailers:req.trailers,
      httpVersion:req.httpVersion
    }, (remoteRes) ->
      console.log 'remote res'
      res.writeHead remoteRes.statusCode, encodeHeaders(remoteRes.headers)
      res.on 'data', (chunk) ->
        console.log 'res on data'
        remoteRes.write chunk
      remoteRes.on 'data', (chunk) ->
        console.log 'remote res on data'
        console.log chunk.length
        res.write chunk
#      res.on 'end', ->
#        console.log 'res on end'
#        remoteRes.end()
      remoteRes.on 'end', ->
        console.log 'remote res on end'
        res.end()
  )



server.on 'connect', (req, socket) ->
  console.log 'connect'
#  console.log req, socket
  
server.listen 1443 

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