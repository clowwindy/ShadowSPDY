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
  
events = require 'events'
utils = require './utils'

# strategies to detect connection lost
# https://github.com/clowwindy/ShadowSPDY/issues/3

class LocalStrategy extends events.EventEmitter
  constructor: (connections, options) ->
    @_connections = connections
    super()

time = ->
  result = process.hrtime()
  result[0] + result[1] * 1e-9
  
class WindowSizeStrategy extends LocalStrategy
  constructor: (connections, options) ->
    super(connections, options)
    if not options?
      options = {}
    self = @
    @_t1 = options.t1 or 10
    @_t2 = options.t2 or 5
    setInterval (->
                   self._sweep()
                ), options.sweepInterval or 1000
  
  _sweep: ->
    # If windowSize has not changed for 3 seconds, but sinkSize has 
    # changed 1.5 seconds ago, sweep that connection.
    keys = Object.keys(@_connections)
    now = time()
    for key in keys
      connection = @_connections[key]
#      utils.debug "windowSize: #{connection._spdyState.windowSize}, sinkSize: #{connection._spdyState.sinkSize}"
      if not connection._spState?
        state = {}
        connection._spState = state
        state.lastWindowSizeChange = now
        state.lastSinkSizeChangeSatisfyingT1 = now
      state = connection._spState
      if state.lastWindowSize != connection._spdyState.windowSize
        state.lastWindowSize = connection._spdyState.windowSize
        state.lastWindowSizeChange = now
        utils.debug "updating lastWindowSizeChange"
        
      if state.lastSinkSize != connection._spdyState.sinkSize
        state.lastSinkSize = connection._spdyState.sinkSize
        if now - state.lastWindowSizeChange >= @_t1
          utils.debug "now - state.lastWindowSizeChange >= @_t1"
          if state.lastSinkSizeChangeSatisfyingT1 < state.lastWindowSizeChange
            state.lastSinkSizeChangeSatisfyingT1 = now
            utils.debug "updating lastSinkSizeChangeSatisfyingT1"
      
      if state.lastWindowSizeChange < state.lastSinkSizeChangeSatisfyingT1 and 
          now - state.lastSinkSizeChangeSatisfyingT1 > @_t2
        # remove
        utils.warn "removing dead connection for #{now - state.lastWindowSizeChange} seconds but wrote on #{now - state.lastSinkSizeChangeSatisfyingT1} ago"
        connection = @_connections[key]
        
#        setTimeout ->
#          try
#            TODO check if windowSize has changed
        connection.socket.destroy()
#          catch e
#            utils.error "error when destroying connection: #{e}"
#        , 5 * 60 * 1000
        
        delete @_connections[key]
 

exports.WindowSizeStrategy = WindowSizeStrategy
