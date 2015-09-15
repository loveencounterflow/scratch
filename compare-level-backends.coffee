





############################################################################################################
njs_path                  = require 'path'
# njs_fs                    = require 'fs'
#...........................................................................................................
CND                       = require 'cnd'
rpr                       = CND.rpr.bind CND
badge                     = 'SCRATCH/scratch'
log                       = CND.get_logger 'plain',   badge
info                      = CND.get_logger 'info',    badge
alert                     = CND.get_logger 'alert',   badge
debug                     = CND.get_logger 'debug',   badge
warn                      = CND.get_logger 'warn',    badge
urge                      = CND.get_logger 'urge',    badge
whisper                   = CND.get_logger 'whisper', badge
help                      = CND.get_logger 'help',    badge
echo                      = CND.echo.bind CND
#...........................................................................................................
suspend                   = require 'coffeenode-suspend'
step                      = suspend.step
later                     = suspend.immediately
#...........................................................................................................
CND.shim()

#-----------------------------------------------------------------------------------------------------------
dump = ( db, handler ) ->
  D             = require 'pipedreams'
  input = db.createReadStream()
  input
    .pipe D.$show()
    .pipe D.$on_end ->
      handler() if handler?

#-----------------------------------------------------------------------------------------------------------
level_down_implementations = ( format ) ->
  step ( resume ) =>
    format       ?= 'level'
    n             = 100
    as_batch      = no
    D             = require 'pipedreams'
    #.........................................................................................................
    $             = D.remit.bind D
    $async        = D.remit_async.bind D
    levelup       = require 'levelup'
    leveldown     = require 'leveldown'
    memdown       = require 'memdown'
    sqldown       = require 'sqldown'
    jsondown      = require 'jsondown'
    extension     = null
    backend       = leveldown
    #.........................................................................................................
    switch format
      when 'level'
        null
      when 'json'
        backend     = jsondown
      when 'memory'
        backend     = memdown
      when 'sqlite'
        backend     = sqldown
      else
        throw new Error "unknown DB format #{rpr format}"
    #.........................................................................................................
    db_route      = njs_path.join __dirname, "db.#{extension ? format}"
    db            = levelup db_route, db: backend
    #.......................................................................................................
    if as_batch
      buffer        = []
      db.put 'helo', 'world'
      for idx in [ 0 ... n ]
        nr    = CND.random_integer 100, 999
        key   = "key-#{nr}-#{idx}"
        value = idx
        entry = { type: 'put', key, value, }
        buffer.push entry
      yield db.batch buffer, resume
    #.......................................................................................................
    else
      db.put 'helo', 'world'
      for idx in [ 0 ... n ]
        nr    = CND.random_integer 100, 999
        key   = "key-#{nr}-#{idx}"
        value = idx
        debug '©aK5n8', key, value
        yield db.put key, value, resume
    #.......................................................................................................
    yield dump db, resume
    debug '©YQ4oQ', 'end'
    db.close()

#...........................................................................................................
# level_down_implementations 'level'
# level_down_implementations 'json'
level_down_implementations 'sqlite'

#-----------------------------------------------------------------------------------------------------------
try_proxy = ->
  # Proxy = require 'harmony-proxy' if global.Proxy.create?
  if ( not global[ 'Reflect' ] )? or global[ 'Proxy' ]?[ 'create' ]?
    global[ 'Reflect' ] = require 'harmony-reflect'
  #.........................................................................................................
  my_target =
    foo:    42
    f:      -> my_target[ 'foo' ] * 2
  #.........................................................................................................
  handler =
    get: ( target, key, receiver ) ->
      warn '>>>', 'get', ( rpr key )
      urge (name for name of receiver)
      help target is receiver
      # return 108
      return target[ key ]
      # return Reflect.get target, key, receiver
  #.........................................................................................................
  # proxy = Proxy.create handler
  proxy = new Proxy my_target, handler
  debug proxy[ 'foo' ]
  debug proxy[ 'foo' ] = 1234
  debug proxy.f()
  debug ( name for name of proxy )

# try_proxy()
# debug Object.observe