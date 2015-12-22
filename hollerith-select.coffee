




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
        { key, value, }             = batch_entry
        [ _, prd, obj, sbj, ]       = key
        send [ sbj, prd, obj, ]
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
      if sub_phrase is null
        warn "no sortcode found for glyph #{rpr sbj}"
        return
      [ _, sbj, prd, obj, idx, ]  = sub_phrase
      done [ sbj, prd, obj, ]

#-----------------------------------------------------------------------------------------------------------
@$add_sortcode_derivates = ( S ) ->
  last_glyph = null
  #.........................................................................................................
  return $ ( phrase, send ) =>
    [ sbj, prd, obj, ]          = phrase
    return if sbj is last_glyph
    last_glyph = sbj
    [ sortcodes, affixes..., ]  = obj
    [ infix, suffix, prefix, ]  = affixes
    factors                     = [ infix, suffix..., ]
    sortcodes.pop()
    #.......................................................................................................
    unless prefix.length is 0
      return send.error new Error "expected empty prefix, got #{rpr phrase}"
    unless sortcodes.length is factors.length
      return send.error new Error "expected factors and sortcodes of equal lengths, got #{rpr phrase}"
    #.......................................................................................................
    for factor, factor_idx in factors
      sortcode = sortcodes[ factor_idx ]
      # 再 [["0226f---",null],"再",[],[]]
      send [ factor, 'guide/kwic/v3/sortcode', [ [ [ sortcode, null, ], factor, [], [], ] ], ]

#-----------------------------------------------------------------------------------------------------------
@create_searchwrite_tee = ( source_db, target_db, prefix, hi, handler ) ->
  ### TAINT not yet a 'create stream' method ###
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
  source        = HOLLERITH.create_phrasestream source_db, query
  readstream    = D.create_throughstream()
  writestream   = D.create_throughstream()
  R             = D.TEE.from_readwritestreams readstream, writestream #, settings
  { input }     = R.tee
  #.........................................................................................................
  source.pause()
  input.pause()
  #.........................................................................................................
  source.pipe input
  source.on 'end',    => help "source has ended"; input.end()
  input.on  'resume', => source.resume()
  #.........................................................................................................
  input
    .pipe D.$show()
    .pipe $ ( phrase, send ) =>
      [ _, sbj, prd, obj, idx, ] = HOLLERITH.normalize_phrase source_db, phrase
      send [ sbj, prd, obj, ]
    .pipe HOLLERITH.$write target_db
    .pipe D.$on_end =>
      help "query #{rpr query} completed"
      handler null
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@f = ( max_rank = 50 ) ->
  S                   = {}
  S.home              = njs_path.resolve __dirname, '../jizura-datasources'
  S.source_route      = njs_path.resolve S.home, 'data/leveldb-v2'
  S.target_route      = njs_path.resolve S.home, '/tmp/results'
  S.target_db_size    = 1e4
  S.ds_options        = require njs_path.resolve S.home, 'options'
  S.source_db         = HOLLERITH.new_db S.source_route
  S.target_db         = HOLLERITH.new_db S.target_route, size: S.target_db_size, create: yes
  S.confluence_A      = @create_resultstream S.target_db, 'rank/cjt'
  S.confluence_B      = @create_resultstream S.target_db, 'guide/kwic/v3/sortcode'
  #.........................................................................................................
  phase_1 = =>
    step ( resume ) =>
      yield HOLLERITH.clear S.target_db, resume
      #.....................................................................................................
      S.confluence_A
        .pipe $ ( phrase, send ) => urge 'confluence_A', phrase; send phrase
        .pipe @$add_lineups S
        .pipe HOLLERITH.$write S.target_db
        .pipe D.$on_end =>
          help "confluence_A has ended"
          S.confluence_B.end()
      #.....................................................................................................
      S.confluence_B
        # .pipe $ ( phrase, send ) => urge 'confluence_B', phrase; send phrase
        .pipe D.$show(), '97342 confluence_B'
        .pipe @$add_sortcode_derivates S
        .pipe HOLLERITH.$write S.target_db, { unique: no, }
        .pipe D.$on_end =>
          help "confluence_B has ended"
          phase_2()
      #.....................................................................................................
      lo = [ 'pos', 'rank/cjt', -Infinity, ]
      hi = [ 'pos', 'rank/cjt', max_rank, ]
      #.....................................................................................................
      tee_A               = @create_searchwrite_tee S.source_db, S.target_db, lo, hi, resume
      { input, output, }  = tee_A.tee
      output.on 'end', =>
        help "output has ended"
      input.on 'end', =>
        help "input has ended"
        S.confluence_A.end()
      input.resume()
      return null
  #.........................................................................................................
  phase_2 = =>
    debug '923847', phase_2
    # step ( resume ) =>
    #   prefix = [ 'spo', ]
      # yield @create_searchwrite_tee S.source_db, S.target_db, prefix, resume
  #.........................................................................................................
  phase_1()


############################################################################################################
unless module.parent?
  @f 5
