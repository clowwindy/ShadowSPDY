# test encryption

child_process = require('child_process')
local = child_process.spawn('bin/splocal', [])
server = child_process.spawn('bin/spserver', [])

curlRunning = false

local.on 'exit', (code)->
  server.kill()
  if !curlRunning
    process.exit code

server.on 'exit', (code)->
  local.kill()
  if !curlRunning
    process.exit code

localReady = false
serverReady = false
curlRunning = false

runCurl = ->
  curlRunning = true
  curl = child_process.spawn 'curl', ['-v', 'http://www.example.com/', '-L', '--socks5-hostname', '127.0.0.1:1081']
  curl.on 'exit', (code)->
    local.kill()
    server.kill()
    if code is 0
      console.log 'Test passed'
      process.exit 0
    else
      console.error 'Test failed'
      process.exit code

  curl.stdout.on 'data', (data) ->
    process.stdout.write(data)

  curl.stderr.on 'data', (data) ->
    process.stderr.write(data)

local.stderr.on 'data', (data) ->
  process.stderr.write(data)

server.stderr.on 'data', (data) ->
  process.stderr.write(data)

local.stdout.on 'data', (data) ->
  process.stdout.write(data)
  if data.toString().indexOf('listening at') >= 0
    localReady = true
    if localReady and serverReady and not curlRunning
      runCurl()

server.stdout.on 'data', (data) ->
  process.stdout.write(data)
  if data.toString().indexOf('listening at') >= 0
    serverReady = true
    if localReady and serverReady and not curlRunning
      runCurl()

