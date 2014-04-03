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


# table encryption is not supported now

crypto = require("crypto")
tls = require("tls")
util = require("util")
stream = require('stream')
int32Max = Math.pow(2, 32)


bytes_to_key_results = {}

EVP_BytesToKey = (password, key_len, iv_len) ->
  password = to_buffer password
  if bytes_to_key_results[password]
    return bytes_to_key_results[password]
  m = []
  i = 0
  count = 0
  while count < key_len + iv_len
    md5 = crypto.createHash('md5')
    data = password
    if i > 0
      data = Buffer.concat([m[i - 1], password])
    md5.update(data)
    d = to_buffer md5.digest()
    m.push(d)
    count += d.length
    i += 1
  ms = Buffer.concat(m)
  key = ms.slice(0, key_len)
  iv = ms.slice(key_len, key_len + iv_len)
  bytes_to_key_results[password] = [key, iv]
  return [key, iv]

to_buffer = (input) ->
  if input.copy?
    return input
  else
    return new Buffer(input, 'binary')

method_supported =
  'aes-128-cfb': [16, 16]
  'aes-192-cfb': [24, 16]
  'aes-256-cfb': [32, 16]
  'bf-cfb': [16, 8]
  'camellia-128-cfb': [16, 16]
  'camellia-192-cfb': [24, 16]
  'camellia-256-cfb': [32, 16]
  'cast5-cfb': [16, 8]
  'des-cfb': [8, 8]
  'idea-cfb': [16, 8]
  'rc2-cfb': [16, 8]
  'rc4': [16, 0]
  'seed-cfb': [16, 16]

getCipherLen = (method) ->
  method = method.toLowerCase()
  m = method_supported[method]
  return m

  
DuplexStream = stream.Duplex

ShadowStream = (source, method, password) ->
  DuplexStream.call this
  
  if method not of method_supported
    throw new Error("method #{method} not supported")
    
  method = method.toLowerCase()
  
  @_source = source
  @_method = method
  @_password = password
  @_IVSent = false
  @_IVBytesReceived = 0

  m = getCipherLen(method)
  [@_key, iv_] = EVP_BytesToKey password, m[0], m[1]
  @_sendIV = crypto.randomBytes m[1]
  @_cipher = crypto.createCipheriv method, @_key, @_sendIV
  @_receiveIV = new Buffer(m[1])
  @_IVBytesToReceive = m[1]
  
  @timeout = source.timeout
  
  self = this
  
  source.on 'connect', ->
    self.emit 'connect'
  
  source.on 'end', ->
    console.log 'source on end'
    self.push null
  
  source.on 'readable', ->
    console.log 'source on readable'
    self.read(0)
    
  source.on 'error', (err) ->
    console.log 'self error'
    self.emit 'error', err
    
  source.on 'timeout', ->
    self.emit 'timeout'
  
  source.on 'close', ->
    self.emit 'close'
    
  return this

util.inherits(ShadowStream, DuplexStream)

ShadowStream.prototype._read = (bytes) ->
  chunk = @_source.read()
  if chunk == null
    return @push('')
  
  decipherStart = 0
  if @_IVBytesReceived < @_IVBytesToReceive
    # copy IV from chunk into @_receiveIV
    # the data left starts from decipherStart
    decipherStart = chunk.copy @_receiveIV, @_IVBytesReceived
    @_IVBytesReceived += decipherStart 
  if @_IVBytesReceived < @_IVBytesToReceive
    return
  if not @_decipher?
    @_decipher = crypto.createDecipheriv @_method, @_key, @_receiveIV
  if decipherStart > 0
    cipher = chunk.slice decipherStart
  if cipher.length > 0
    plain = @_decipher.update cipher
    @push plain

ShadowStream.prototype._write = (chunk, encoding, callback) ->
  if chunk instanceof String
    chunk = new Buffer(chunk, encoding)
  try
    cipher = @_cipher.update chunk
    if not @_IVSent
      cipher = Buffer.concat [@_sendIV, cipher]
    @_source.write cipher
  catch e
    return callback(e)
  callback()

ShadowStream.prototype.end = (data) ->
  @_source.end data
  
ShadowStream.prototype.destroy = ->
  @_source.destroy()

ShadowStream.prototype.setTimeout = (timeout) ->
  @_source.setTimeout(timeout)

exports.ShadowStream = ShadowStream

test = ->
  net = require 'net'
  server = net.createServer (conn) ->
    s = new ShadowStream(conn, 'aes-256-cfb', 'foobar')
    s.on 'data', (data) ->
      console.log data.toString()
    s.on 'end', ->
      console.log 'server end'
      s.end()
      server.close()
  server.listen 8888
  cli = net.connect 8888, 'localhost',  ->
    s = new ShadowStream(cli, 'aes-256-cfb', 'foobar')
    s.write 'hello'
    s.end('world')
  cli.on 'end', ->
    console.log 'cli end'
    cli.end()
    

