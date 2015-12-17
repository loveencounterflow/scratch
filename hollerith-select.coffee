




############################################################################################################
njs_util                  = require 'util'
njs_path                  = require 'path'
njs_fs                    = require 'fs'
#...........................................................................................................
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'scratch'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
rainbow                   = CND.rainbow.bind CND
suspend                   = require 'coffeenode-suspend'
step                      = suspend.step
after                     = suspend.after
eventually                = suspend.eventually
immediately               = suspend.immediately
every                     = suspend.every

ASYNC             = require 'async'
HOLLERITH         = require 'hollerith'
D                 = require 'pipedreams'
$                 = D.remit.bind D
$async            = D.remit_async.bind D
#.........................................................................................................
### https://github.com/dominictarr/level-live-stream ###
### Alternative: https://github.com/Raynos/level-livefeed ###
create_livestream = require 'level-live-stream'

#-----------------------------------------------------------------------------------------------------------
HOLLERITH.$decode = ( db ) ->
  ### TAINT should not require `db` as argument ###
  return $ ( batch_entry, send ) =>
    { key, value, } = batch_entry
    unless @_is_meta db, key
      batch_entry[ 'key'   ] = @_decode_key   db, key
      batch_entry[ 'value' ] = @_decode_value db, value unless value is undefined
      send batch_entry

#-----------------------------------------------------------------------------------------------------------
HOLLERITH.$count = ( part_of_speech ) ->
  unless part_of_speech in [ 's', 'p', 'o', ]
    throw new Error "expected one of 's', 'p', 'o', got #{rpr part_of_speech}"
  counts = {}
  return $ ( phrase, send, end ) =>
    if phrase?
      throw new Error "xxx" unless phrase[ 0 ] is 'pos'
      [ _, prd, obj, sbj, idx, ] = phrase
      value = switch part_of_speech
        when 's' then sbj
        when 'p' then prd
        when 'o' then obj
      ### TAINT should properly check for inner/outer codepoint ###
      unless sbj.startsWith '&'
        counts[ value ] = ( counts[ value ] ? 0 ) + 1
    if end?
      send [ value, count, ] for value, count of counts
      end()

#-----------------------------------------------------------------------------------------------------------
HOLLERITH.prune = ( me, prefix, filter, handler ) ->
  end_          = null
  db_substrate  = me[ '%self' ]
  query         = { prefix, star: '*', }
  input         = @create_phrasestream me, query
  input
    .pipe $async ( phrase, done ) =>
      unless filter phrase
        key     = phrase[ ... 3 ]
        key_bfr = @_encode_key db_substrate, key
        # debug "open process count: #{count}"
        db_substrate.batch [{ type: 'del', key: key_bfr, }], ( error ) =>
          throw error if error?
          # input.resume()
          done()
        # input.pause()
      else
        immediately => done phrase
    # .pipe D.$show()
    .pipe D.$count ( count ) => help "intersection: #{count}"
    .pipe D.$on_end ( end ) =>
      # debug "open process count: #{count}"
      # end_ = end
      immediately => handler null
      # setTimeout ( => handler null ), 2000
      # handler null
  return null

#-----------------------------------------------------------------------------------------------------------
@create_resultstream = ( db, predicate ) ->
  db_substrate  = db[ '%self' ]
  prefix        = [ 'pos', predicate, ]
  query         = HOLLERITH._query_from_prefix db, prefix, '*'
  #.........................................................................................................
  ### see https://github.com/dominictarr/level-live-stream/#options ###
  settings =
    tail: yes
    old : no
    min : query[ 'gte' ]
    max : query[ 'lte' ]
  #.........................................................................................................
  R = create_livestream db_substrate, settings
  R = R
    .pipe HOLLERITH.$decode db
    .pipe $ ( batch_entry, send ) =>
      if batch_entry[ 'type' ] is 'put'
        facet = batch_entry[ 'key' ]
        debug '©97307', facet
        facet.splice 0, 1
        facet.push batch_entry[ 'value' ]
        send facet
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@$add_lineups = ( S ) ->
  #.........................................................................................................
  return $async ( phrase, done ) =>
    [ sbj, prd, obj, ] = phrase
    prefix  = [ 'spo', sbj, 'guide/kwic/v3/sortcode', ]
    query   = { prefix: prefix, fallback: null, }
    HOLLERITH.read_one_phrase S.source_db, query, ( error, sub_phrase ) =>
      return done.error error if error?
      [ _, sbj, prd, obj, idx, ]  = sub_phrase
      done [ sbj, prd, obj, ]

      # send [ sbj, prd, obj, ]
      #     if result?
      #       result.splice 0, 1
      #       result[ 2 ] += +1
      #       done result
      #     else
      #       done [ sbj, prd, obj + 1, ]
      # .pipe D.$count ( count ) => help "#{rpr prefix}: #{count}"
      # .pipe HOLLERITH.$write S.target_db #, unique: no, solids: [ 'count', ]
      # .pipe D.$on_end => handler null
    # #.........................................................................................................
    # return null


#-----------------------------------------------------------------------------------------------------------
@search = ( source_db, target_db, prefix, hi, handler ) ->
  ### TAINT use of star not correct ###
  switch arity = arguments.length
    when 4
      handler   = hi
      lo        = null
      hi        = null
      query     = { prefix, star: '*', }
    when 5
      lo        = prefix
      prefix    = null
      query     = { lo, hi, }
    else
      return handler new Error "expected 4 or 5 arguments, got #{arity}"
  #.........................................................................................................
  input = HOLLERITH.create_phrasestream source_db, query
  #.........................................................................................................
  input
    .pipe D.$show()
    .pipe $ ( phrase, send ) =>
      [ _, prd, obj, sbj, idx, ] = phrase
      send [ sbj, prd, obj, ]
    # .pipe accumulator
    .pipe HOLLERITH.$write target_db
    .pipe D.$on_end => handler null
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@f = ->
  prefix              = 'rank/cjt'
  #.........................................................................................................
  S                   = {}
  S.home              = njs_path.resolve __dirname, '../jizura-datasources'
  S.source_route      = njs_path.resolve S.home, 'data/leveldb-v2'
  S.target_route      = njs_path.resolve S.home, '/tmp/results'
  S.target_db_size    = 1e6
  S.ds_options        = require njs_path.resolve S.home, 'options'
  S.source_db         = HOLLERITH.new_db S.source_route
  S.target_db         = HOLLERITH.new_db S.target_route, size: S.target_db_size, create: yes
  S.confluence        = @create_resultstream S.target_db, prefix
  #.........................................................................................................
  step ( resume ) =>
    yield HOLLERITH.clear S.target_db, resume
    #.......................................................................................................
    lo = [ 'pos', prefix, -Infinity, ]
    hi = [ 'pos', prefix, 5, ]
    #.......................................................................................................
    S.confluence
      .pipe D.$show()
      # .pipe $ ( phrase, send ) => urge phrase; send phrase
      # .pipe @$add_lineups S
      # .pipe HOLLERITH.$write S.target_db
    #.......................................................................................................
    yield @search S.source_db, S.target_db, lo, hi, resume
    return null


############################################################################################################
unless module.parent?
  @f()
