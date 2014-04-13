###
  Copyright (c) 2014 clowwindy
 
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
 
  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.
 
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
###

fs = require 'fs'
util = require 'util'
argparse = require 'argparse'
path = require 'path'

utils = exports

exports.checkConfig = (config) ->
  if config.server in ['127.0.0.1', 'localhost']
    exports.warn "Server is set to #{config.server}, maybe it's not correct"
    exports.warn "Notice server will listen at #{config.server}:#{config.server_port}"
  if (config.method or '').toLowerCase() == 'rc4'
    exports.warn 'RC4 is not safe; please use a safer cipher, like AES-256-CFB'

exports.rawVersion = "0.1.5"
exports.version = "shadowspdy v#{exports.rawVersion}"

exports.EVERYTHING = 0
exports.DEBUG = 1
exports.INFO = 2
exports.WARN = 3
exports.ERROR = 4

_logging_level = exports.INFO

exports.config = (level) ->
  _logging_level = level

exports.log = (level, msg)->
  if level >= _logging_level
    util.log msg
    
exports.debug = (msg)->
  exports.log exports.DEBUG, msg
  
exports.info = (msg)->
  exports.log exports.INFO, msg 
  
exports.warn = (msg)->
  exports.log exports.WARN, msg 
  
exports.error = (msg)->
  exports.log exports.ERROR, msg
  
parseCommandLineArgs = (isServer) ->
  parser = new argparse.ArgumentParser {
    addHelp: true
  }

  parser.addArgument ['-c'], {
    dest: 'config_file'
    help: 'path to config file, default is ./config.json'
  }
  parser.addArgument ['-s'], {
    dest: 'server'
    help: 'server address'
  }
  parser.addArgument ['-p'], {
    dest: 'server_port'
    help: 'server port'
  }
  parser.addArgument ['-k'], {
    dest: 'password'
    help: 'password'
  }
  parser.addArgument ['-m'], {
    dest: 'method'
    help: 'encryption method, for example, aes-256-cfb'
  }

  if not isServer
    parser.addArgument ['-b'], {
      dest: 'local_address'
      help: 'local binding address, default is 127.0.0.1'
    }
    parser.addArgument ['-l'], {
      dest: 'local_port'
      help: 'local port'
    }
    parser.addArgument ['-n'], {
      dest: 'connections'
      help: 'max SPDY connections, default is 1'
    }
  
  parser.addArgument ['-v'], {
    dest: 'verbose'
    help: 'vebose mode'
    action: 'storeTrue'
  }

  return parser.parseArgs()

exports.parseArgs = (isServer) ->
  configFromArgs = parseCommandLineArgs isServer
  configPath = 'config.json'
  if configFromArgs.config_file
    configPath = configFromArgs.config_file
  if not fs.existsSync(configPath)
    configPath = path.resolve(__dirname, "config.json")
    if not fs.existsSync(configPath)
      configPath = path.resolve(__dirname, "../../config.json")
      if not fs.existsSync(configPath)
        configPath = null
  if configPath
    utils.info 'loading config from ' + configPath
    configContent = fs.readFileSync(configPath)
    try
      config = JSON.parse(configContent)
    catch e
      utils.error('found an error in config.json: ' + e.message)
      process.exit 1
  else
    config = {}
  for k, v of configFromArgs
    if v? and v not instanceof Function
      config[k] = v
  if config.verbose
    utils.config(utils.DEBUG)

  utils.checkConfig config

  if not (config.server? and config.server_port? and (isServer or config.local_port?) and config.password?)
    utils.warn 'config.json not found, you have to specify all config in commandline'
    process.exit 1
  return config
  
#setInterval(->
#  if global.gc
#    exports.debug(JSON.stringify(process.memoryUsage(), ' ', 2))
#    exports.debug 'GC'
#    gc()
#    exports.debug(JSON.stringify(process.memoryUsage(), ' ', 2))
#    cwd = process.cwd()
#    if _logging_level == exports.DEBUG
#      try
#        heapdump = require 'heapdump'
#        process.chdir '/tmp'
##        heapdump.writeSnapshot()
#        process.chdir cwd
#      catch e
#        exports.debug e
#, 1000)
