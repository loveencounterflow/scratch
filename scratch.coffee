




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


#===========================================================================================================
mkts_backslash_escaping = ->
  @escape = {}

  #-----------------------------------------------------------------------------------------------------------
  @escape.escape_chrs = ( S, text ) =>
    R = text
    R = R.replace /// \x10 ///g, '\x10A' # ASCII DLE, Master escape
    R = R.replace /// \x11 ///g, '\x10B' # ASCII DC1, Backslash Character escape
    R = R.replace /// \x15 ///g, '\x10X' # ASCII NAK, Macro escape
    R = R.replace /// \\ ( (?: [  \ud800-\udbff ] [ \udc00-\udfff ] ) | . ) ///g, ( _, $1 ) ->
      cid = ( $1.codePointAt 0 ).toString 16
      return "\x11#{cid};"
    return R

  #-----------------------------------------------------------------------------------------------------------
  @escape.unescape_escape_chrs = ( S, text ) =>
    R = text
    R = R.replace /// \x11 ( [ 0-9 a-f ]+ ) ; ///g, ( _, $1 ) ->
      chr = String.fromCodePoint parseInt $1, 16
      return "\\#{chr}"
    R = R.replace /// \x10X ///g, '\x15'
    R = R.replace /// \x10C ///g, '\x12'
    R = R.replace /// \x10B ///g, '\x11'
    R = R.replace /// \x10A ///g, '\x10'
    return R

  #-----------------------------------------------------------------------------------------------------------
  @escape.remove_escaping_backslashes = ( S, text ) =>
    return text.replace /// \\ ( . ) ///g, '$1'

  # #-----------------------------------------------------------------------------------------------------------
  # @escape.escape_chrs = ( S, text ) =>
  #   R = text
  #   R = R.replace /// % ///g, '%A' # ASCII DLE, Master escape
  #   R = R.replace /// & ///g, '%B' # ASCII DC1, Backslash Character escape
  #   R = R.replace /// ! ///g, '%X' # ASCII NAK, Macro escape
  #   R = R.replace /// \\ ( (?: [  \ud800-\udbff ] [ \udc00-\udfff ] ) | . ) ///g, ( _, $1 ) ->
  #     cid = ( $1.codePointAt 0 ).toString 16
  #     return "&#{cid};"
  #   return R

  # #-----------------------------------------------------------------------------------------------------------
  # @escape.unescape_escape_chrs = ( S, text ) =>
  #   R = text
  #   R = R.replace /// & ( [ 0-9 a-f ]+ ) ; ///g, ( _, $1 ) ->
  #     chr = String.fromCodePoint parseInt $1, 16
  #     return "\\#{chr}"
  #   R = R.replace /// %X ///g, '!'
  #   R = R.replace /// %C ///g, '\x12'
  #   R = R.replace /// %B ///g, '&'
  #   R = R.replace /// %A ///g, '%'
  #   return R

  # ### TAINT not compatible with 32bit codepoins ###
  # @backslash_pattern = /// \\ ( . ) ///g
  # ,
  #   ///
  #   ( \\<< )
  #   ///g
  # ,
  #   ///
  #   ( <\\< )
  #   ///g
  # ,
  #   ///
  #   ( \\>> )
  #   ///g
  # ,
  #   ///
  #   ( >\\> )
  #   ///g
  # ,
  #   ///
  #   ( \\ )
  #   ///g
    # ]
  text = """
    some <<unlicensed>> stuff here. \\𠄨 &%!%A&123;
    some more \\\\<<unlicensed\\\\>> stuff here.
    some \\<<licensed\\>> stuff here, and <\\<
    The <<<\\LaTeX{}>>> Logo: `<<<\\LaTeX{}>>>`
    """
  # text = ""
  # text = "<<"
  # text = "x"
  debug text
  help cloaked_text   = @escape.escape_chrs null, text
  whisper rpr cloaked_text
  urge uncloaked_text = @escape.unescape_escape_chrs null, cloaked_text
  warn '©79011', uncloaked_text if uncloaked_text isnt text
  help '©79011', @escape.remove_escaping_backslashes null, uncloaked_text
  # _ = []
  # text = text.replace @backslash_pattern, ( _, $1 ) ->
  #   cid = ( $1.codePointAt 0 ).toString 16
  #   return "^#{cid};"
  # log text
  # for pattern, pattern_idx in @backslash_patterns
  #   is_plain  = no
  #   stretches = []
  #   for stretch in text.split pattern
  #     is_plain = not is_plain
  #     _.push ( if is_plain then CND.white else CND.rainbow ) stretch
  #   _.push '\n'
  #   _.push '\n'
  # log '\n' + ( _.join '' ) + '\n'
  # for pattern, pattern_idx in @backslash_patterns
  #   text = text.replace pattern, "##{pattern_idx};"
  # log '\n' + text

mkts_backslash_escaping()

#===========================================================================================================
mkts_illegal_patterns = ->
  @illegal_patterns = [
    ///                           # After applying all other macro patterns, treat as error: pattern that
    ( ^ | [^ \\ ] )               # starts either at the first chr or a chr other than backslash
    ( << | >> )                   # then: either two left or two right pointy brackets.
    ///g
    ]
  text = """
    some << unlicensed >> stuff here.

    some \\<< licensed \\>> stuff here.
    """
  # text = ""
  # text = "<<"
  # text = "x"
  for pattern in @illegal_patterns
    is_plain  = no
    stretches = []
    for raw_stretch, idx in text.split pattern
      if ( idx % 3 ) is 1
        stretches[ stretches.length - 1 ] += raw_stretch
      else
        stretches.push raw_stretch
    is_plain  = no
    for stretch in stretches
      is_plain = not is_plain
      info '©54249', is_plain, rpr stretch
      # if is_plain

# mkts_illegal_patterns()

#===========================================================================================================
interactive_cli = ->
  inquirer = require './Inquirer.js'
  console.log 'Hi, welcome to Node Pizza'
  filenames = njs_fs.readdirSync njs_path.resolve __dirname, './node_modules/'
  dialogue = [
  #   type: 'confirm'
  #   name: 'toBeDelivered'
  #   message: 'Is it for a delivery'
  #   default: false
  # ,
    # type: 'list'
    type: 'checkbox'
    name: 'size'
    message: 'Select files'
    choices: filenames
    pageSize: 10
    disabled: ( P... ) -> debug '©ΥΡΠΣΤ', P; return true
    # filter: (val) ->
    #   val.toLowerCase()
  ]
  prompt = inquirer.prompt dialogue, ( answers ) ->
    debug '©ΞΕΡΒΧ', answers
  onEachAnswer  = ( P... ) -> help 'onEachAnswer', P
  onError       = ( P... ) -> warn 'onError', P
  onComplete    = ( P... ) -> urge 'onComplete', P
  prompt.process.subscribe onEachAnswer, onError, onComplete
  CND.dir prompt
  # { Rx } = require 'rx-lite'
  # prompts = Rx.Observable.create(( obs ) ->
  #   obs.onNext {}
  #   setTimeout ->
  #     obs.onNext {}
  #     obs.onCompleted()
  #     return
  #   return
  # )
  # inquirer.prompt prompts
  # inquirer.prompt(prompts).process.subscribe onEachAnswer, onError, onComplete

# interactive_cli()


#===========================================================================================================
HOLLERITH_select = ->
  ASYNC             = require 'async'
  HOLLERITH         = require '../hollerith'
  D                 = require '../pipedreams'
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
  create_resultstream = ( db ) ->
    db_substrate  = db[ '%self' ]
    query         = HOLLERITH._query_from_prefix db, [ 'spo', ]
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
      # .pipe $ ( batch_entry, send ) =>
        # unless batch_entry[ 'type' ] in [ 'del', ]
        #   send batch_entry
      .pipe HOLLERITH.$decode db
      .pipe $ ( facet, send ) =>
        facet = [ facet[ 'key' ], facet[ 'value' ], ] if facet[ 'type' ]?
        [ [ _, sbj, _, ], _, ] = facet
        send sbj
    return R

  #-----------------------------------------------------------------------------------------------------------
  search = ( source_db, target_db, prefix, handler ) ->
    ### TAINT use of star not correct ###
    query             = { prefix, star: '*', }
    input             = HOLLERITH.create_phrasestream source_db, query
    accumulator       = D.create_throughstream()
    # accumulator.on 'end', =>
    accumulator
      .pipe $async ( [ sbj, prd, obj, ], done ) =>
        sub_prefix  = [ 'spo', sbj, prd, ]
        sub_query   = { prefix: sub_prefix, fallback: null, }
        HOLLERITH.read_one_phrase target_db, sub_query, ( error, result ) =>
          return done.error error if error?
          if result?
            result.splice 0, 1
            result[ 2 ] += +1
            done result
          else
            done [ sbj, prd, obj + 1, ]
      .pipe D.$count ( count ) => help "#{rpr prefix}: #{count}"
      .pipe HOLLERITH.$write target_db, unique: no, solids: [ 'count', ]
      # .pipe HOLLERITH.$write target_db, unique: no, solids: [ 'count', ], loners: [ 'count', ]
      .pipe D.$on_end => handler null
    #.........................................................................................................
    input
      # .pipe HOLLERITH.$count 'o'
      # .pipe D.$sort ( [ value_a, count_a, ], [ value_b, count_b, ] ) =>
      #   return -1 if count_a > count_b
      #   return +1 if count_a < count_b
      #   return -1 if value_a > value_b
      #   return +1 if value_a < value_b
      #   return  0
      # .pipe D.$show()
      .pipe $ ( phrase, send ) =>
        [ _, prd, obj, sbj, idx, ] = phrase
        return if sbj.startsWith '&'
        ### TAINT count must go to value ###
        send [ sbj, 'count', 0, ]
      .pipe accumulator

  #-----------------------------------------------------------------------------------------------------------
  step ( resume ) =>
    #.........................................................................................................
    home              = njs_path.resolve __dirname, '../jizura-datasources'
    source_route      = njs_path.resolve home, 'data/leveldb-v2'
    target_route      = njs_path.resolve home, '/tmp/results'
    target_db_size    = 1e6
    ds_options        = require njs_path.resolve home, 'options'
    source_db         = HOLLERITH.new_db source_route
    target_db         = HOLLERITH.new_db target_route, size: target_db_size, create: yes
    yield HOLLERITH.clear target_db, resume
    #.........................................................................................................
    tasks = []
    # tasks.push ( done ) => search source_db, target_db, [ 'pos', 'guide/has/uchr', ], done
    # tasks.push ( done ) => search source_db, target_db, [ 'pos', 'guide/has/uchr', '氵', ], done
    # tasks.push ( done ) => search source_db, target_db, [ 'pos', 'guide/has/uchr', '土', ], done
    # tasks.push ( done ) => search source_db, target_db, [ 'pos', 'guide/has/uchr', '亻', ], done
    # tasks.push ( done ) => search source_db, target_db, [ 'pos', 'guide/has/uchr', '口', ], done
    tasks.push ( done ) => search source_db, target_db, [ 'pos', 'guide/has/uchr', '井', ], done
    # tasks.push ( done ) => search source_db, target_db, [ 'pos', 'guide/has/uchr', '太', ], done
    # tasks.push ( done ) => search source_db, target_db, [ 'pos', 'guide/has/uchr', '𠦒', ], done
    # tasks.push ( done ) => search source_db, target_db, [ 'pos', 'guide/has/uchr', '爻', ], done
    tasks.push ( done ) => search source_db, target_db, [ 'pos', 'guide/has/uchr', '鳥', ], done
    ASYNC.parallel tasks, ( error ) =>
      filter = ( phrase ) =>
        [ phrasetype, sbj, prd, count, ] = phrase
        unless ( phrasetype is 'spo' ) and ( prd is 'count' ) and ( CND.isa_number count )
          throw new Error "expected SPO phrase with predicate 'count', got #{rpr phrase}"
        return count >= tasks.length
      HOLLERITH.prune target_db, [ 'spo', ], filter, ( error ) =>
        debug '©ΖΛΜΤΞ'
    #.........................................................................................................
    confluence        = create_resultstream target_db
    # confluence
    #   .pipe D.$show()
    #.........................................................................................................
    return null


# HOLLERITH_select()

#===========================================================================================================
PIPEDREAMS_collect = ->
  D                         = require 'pipedreams'
  $                         = D.remit.bind D
  $async                    = D.remit_async.bind D
  text = """
    Just in order to stress it, a 'character’ in this chart is equivalent to 'a Unicode
    codepoint’, so for example 馬 and 马 count as two characters, and 關, 关, 関, 闗, 𨶹 count
    as five characters. Dictionaries will list 馬马 as 'one character with two variants’
    and 關关関闗𨶹 as 'one character with five variants’, but that’s not what we’re counting
    here.
    """
  #-----------------------------------------------------------------------------------------------------------
  input = D.stream_from_text text
  input.pipe D.$show()
  input.resume()

  #-----------------------------------------------------------------------------------------------------------
  input = D.stream_from_text text
  input
    .pipe D.$split()
    .pipe D.$join '--\n'
    .pipe D.$observe ( data ) -> urge data
  input.resume()

# PIPEDREAMS_collect()

#===========================================================================================================
nice_text_rpr = ->
  text = """
    foo \u0010\u0012\u0015
    bar""\"
    """
  debug '©ehFoE', rpr text
  R = text
  R = R.replace /[\x00-\x09\x0b-\x19]/g, ( $0 ) ->
    cid_hex = ( $0.codePointAt 0 ).toString 16
    cid_hex = '0' + cid_hex if cid_hex.length is 1
    return "\\x#{cid_hex}"
  R = R.replace /"/g, '\\"'
  R = '"""' + R + '"""'
  probe = """foo \x10\x12\x15
    bar\"\"\""""
  debug '©0sWgm', text is probe
  # debug '©4JQls', '\n'.codePointAt 0
  echo CND.white R

# nice_text_rpr()

#===========================================================================================================
content_addressable_storage = ->
  #-----------------------------------------------------------------------------------------------------------
  misfit              = Symbol 'misfit'

  #-----------------------------------------------------------------------------------------------------------
  CAS = {}
  CAS.new_store = ->
    R               =
      '~isa':           'CAS/store'
      'id-by-content':  new Map()
      'index':          []
    return R

  #-----------------------------------------------------------------------------------------------------------
  CAS.set = ( me, content ) ->
    return R if ( R = me[ 'id-by-content' ].get content )?
    R = me[ 'index' ].length
    me[ 'id-by-content' ].set content, R
    me[ 'index' ].push content
    return R

  #-----------------------------------------------------------------------------------------------------------
  CAS.get = ( me, id, fallback = misfit ) ->
    return R if ( R = me[ 'index' ][ id ] )?
    return fallback unless fallback is misfit
    throw new Error "unknown ID #{rpr id}"

  debug '©HpxVZ', store = CAS.new_store()
  debug '©FU7LE (1)', CAS.set store, 42
  debug '©FU7LE (2)', CAS.set store, 'more'
  debug '©FU7LE (3)', CAS.set store, 'more of this'
  debug '©FU7LE (4)', CAS.set store, 'more of this'
  debug '©FU7LE (5)', CAS.set store, [ 32, ]
  debug '©FU7LE (6)', CAS.set store, [ 32, ]
  debug '©FU7LE (7)', CAS.set store, d = [ 32, ]
  debug '©FU7LE (8)', CAS.set store, d
  debug '©FU7LE (9)', CAS.set store, 'new'
  debug '©n9l1r (10)', store
  debug '©ZsxDc (11)', CAS.get store, 1
  # debug '©ZsxDc (12)', CAS.get store, [ 32, ], 'XXX'
  # debug '©ZsxDc (13)', CAS.get store, d
  debug '©ZsxDc (14)', CAS.get store, 10, 'XXX'
  debug '©ZsxDc (15)', CAS.get store, 10

# content_addressable_storage()

#===========================================================================================================
pipedreams_duplex = ->
  #-----------------------------------------------------------------------------------------------------------
  D                         = require 'pipedreams'
  $                         = D.remit.bind D
  $async                    = D.remit_async.bind D

  #-----------------------------------------------------------------------------------------------------------
  do ->
    create_frob_fitting = ( settings ) ->
      multiply      = $ ( data, send ) => send data * 2
      add           = $ ( data, send ) => send data + 2
      square        = $ ( data, send ) => send data ** 2
      unsquared     = D.create_throughstream()
      #.......................................................................................................
      inputs        = { add, }
      outputs       = { unsquared, }
      transforms    = [ multiply, add, unsquared, square, ]
      #.......................................................................................................
      return D.create_fitting transforms, { inputs, outputs, }

    #---------------------------------------------------------------------------------------------------------
    fitting = create_frob_fitting()
    { input, output, inputs, outputs, } = fitting
    outputs[ 'unsquared' ].pipe $ ( data, send ) -> help '@unsquared:', data
    output
      .pipe $ ( data, send ) ->
        inputs[ 'add' ].write -10 if data is 100
        send data
      .pipe D.$show()
    input.write n for n in [ 1 ... 10 ]

# pipedreams_duplex()

#===========================================================================================================
pipedreams_with_fittings = ->
  #-----------------------------------------------------------------------------------------------------------
  D                         = require 'pipedreams'
  $                         = D.remit.bind D
  $async                    = D.remit_async.bind D

  #-----------------------------------------------------------------------------------------------------------
  do ->
    create_frob_fitting = ( settings ) ->
      multiply      = $ ( data, send ) => send data * 2
      add           = $ ( data, send ) => send data + 2
      square        = $ ( data, send ) => send data ** 2
      unsquared     = D.create_throughstream()
      #.......................................................................................................
      inputs        = { add, }
      outputs       = { unsquared, }
      transforms    = [ multiply, add, unsquared, square, ]
      #.......................................................................................................
      return D.create_fitting transforms, { inputs, outputs, }

    #---------------------------------------------------------------------------------------------------------
    fitting = create_frob_fitting()
    { input, output, inputs, outputs, } = fitting
    outputs[ 'unsquared' ].pipe $ ( data, send ) -> help '@unsquared:', data
    output
      .pipe $ ( data, send ) ->
        inputs[ 'add' ].write -10 if data is 100
        send data
      .pipe D.$show()
    input.write n for n in [ 1 ... 10 ]

# pipedreams_with_fittings()


#===========================================================================================================
exec_and_eval_coffeescript = ->
  CS                        = require 'coffee-script'
  VM                        = require 'vm'
  local_filename            = 'myfile.js'
  definitions               = new Map()
  sandbox = {
    d:            108
    e:            "a variable"
    urge:         CND.get_logger 'urge', '!!!'
    help:         CND.get_logger 'help', '!!!'
    # __filename:   local_filename
    define:       ( pod ) ->
      for key, value of pod
        definitions.set key, value
    }
  sandbox[ '__sandbox' ] = sandbox
  VM.createContext sandbox
  cs_source = """
    urge "helo from #{__filename}"
    urge Array
    d = 42
    define
      x:      'some value'
    """
  js_source = CS.compile cs_source, bare: true
  debug '©U4Zmb', VM.runInContext js_source, sandbox, { filename: local_filename, }
  debug '©YMF7F', sandbox
  debug '©YMF7F', definitions

# exec_and_eval_coffeescript()

#===========================================================================================================
caller_identity = ->
  caller = null
  f = ->
    debug '©YRo3i', arguments.callee
    debug '©YRo3i', arguments.callee is caller_identity
    debug '©YRo3i', arguments.callee is f
    # debug '©YRo3i', arguments.callee.caller.caller
    # debug '©YRo3i', arguments.callee.caller.caller.caller
    caller = arguments.callee.caller
    while caller?
      debug '©1oA2s', caller.name, caller.length
      # CND.dir caller
      caller = caller.caller
    # debug '©gVdzx', arguments.callee.caller, caller is arguments.callee.caller
    # caller = arguments.callee.caller
  g = ->
    f()
  g()
  g()
  g()
# caller_identity()



############################################################################################################
test_markdown_it_footnotes = ->
  md_source = """
  Here is a footnote reference,[^1] and another,[^longnote]
  and a third[^3] one.

  [^1]: Here is the footnote.

  [^3]: Third footnote.

  [^longnote]: Here's one with multiple blocks.

      Subsequent paragraphs are indented to show that they
  belong to the previous footnote.

  Here is an inline note.^[Inlines notes are easier to write, since
  you don't have to pick an identifier and move down to type the
  note.]
  """
  MKTS        = require '../jizura/lib/MKTS.js'
  md_parser   = MKTS._new_markdown_parser()
  environment = {}
  urge md_parser.parse md_source, environment
  help environment
# test_markdown_it_footnotes()

############################################################################################################
test_MKTS_raw_escaper = ->
  MKTS        = require '../jizura/lib/MKTS.js'
  md_parser   = MKTS._new_markdown_parser()
  #-----------------------------------------------------------------------------------------------------------
  @_escape_command_fences = ( text ) ->
    R = text
    R = R.replace /♎/g,       '♎0'
    R = R.replace /☛/g,       '♎a'
    R = R.replace /☚/g,       '♎b'
    R = R.replace /\\<\\</g,  '♎1'
    R = R.replace /\\<</g,    '♎2'
    R = R.replace /<\\</g,    '♎3'
    R = R.replace /<</g,      '♎4'
    return R

  #-----------------------------------------------------------------------------------------------------------
  @_unescape_command_fences_A = ( text ) ->
    R = text
    R = R.replace /♎4/g, '<<'
    return R

  #-----------------------------------------------------------------------------------------------------------
  @_unescape_command_fences_B = ( text ) ->
    R = text
    R = R.replace /♎3/g, '<<'
    R = R.replace /♎2/g, '<<'
    R = R.replace /♎1/g, '<<'

  #-----------------------------------------------------------------------------------------------------------
  @_unescape_command_fences_C = ( text ) ->
    R = text
    R = R.replace /♎b/g, '☚'
    R = R.replace /♎a/g, '☛'
    R = R.replace /♎0/g, '♎'
    return R

  #-----------------------------------------------------------------------------------------------------------
  @_replace_raw_spans = ( source ) ->
    return source.replace raw_command_pattern, ( _, raw_content ) =>
      id = raw_contents.length
      raw_content  ?= ''
      raw_content   = @_unescape_command_fences_A raw_content
      raw_content   = @_unescape_command_fences_B raw_content
      raw_content   = @_unescape_command_fences_C raw_content
      raw_contents.push raw_content
      return "☛#{id}☚"
  raw_contents = []

  source = """
    helo <<(raw>>first<<raw)>>
    helo <<(code>>*world*<<code)>>
    helo <<(raw>>do **not** parse this<<raw)>>
    <<(raw>><<raw)>>
    """
  raw_command_pattern = ///
    (?: <<\(raw>>               <<raw\)>> ) |
    (?: <<\(raw>> ( .*? [^\\] ) <<raw\)>> )
    ///g
  raw_id_pattern = ///
    ☛ ( [ 0-9 ]+ ) ☚
    ///g
  source = @_escape_command_fences source
  debug source  = md_parser.render source
  help source   = @_replace_raw_spans source
  source = @_unescape_command_fences_A source
  source = @_unescape_command_fences_B source
  # debug source
  urge raw_contents
  source = source.replace raw_id_pattern, ( _, id_txt ) =>
    id = parseInt id_txt, 10
    ### TAINT check for existence ###
    R = raw_contents[ id ]
    raw_contents[ id ] = 0
    return R
  source = @_unescape_command_fences_C source
  help source
# test_MKTS_raw_escaper()


#===========================================================================================================
MKTS_copy = ->
  MKTS = require '/Volumes/Storage/io/jizura/src/MKTS.coffee'
  meta  = { foo: 'bar', }
  d     = [ 1,2,3,meta, ]
  dd    = MKTS.copy d
  debug '©IcEM4', d, dd
  debug '©IcEM4', d is dd
  debug '©IcEM4', d[ 3 ] is dd[ 3 ]
  meta2   = MKTS.copy meta
  debug '©LRVAf', meta, meta2
  debug '©LRVAf', meta is meta2
# MKTS_copy()

#===========================================================================================================
find_duplicated_guides = ->
  D = require 'pipedreams'
  $ = D.remit.bind D
  input   = njs_fs.createReadStream '/Volumes/Storage/io/jizura-datasources/data/5-derivatives/guide-pairs.txt'
  output  = njs_fs.createWriteStream '/Volumes/Storage/io/jizura-datasources/data/5-derivatives/guide-pairs-duplicated.txt'
  input
    .pipe D.$split()
    # .pipe D.$parse_csv headers: no
    .pipe $ ( line, send ) => send line unless line.length is 0
    .pipe $ ( line, send ) => send line unless line.startsWith '#'
    .pipe $ ( line, send ) => send [ line, ( line.split '\t' )... ]
    .pipe $ ( [ line, _, guides, glyph, ], send ) => send [ line, glyph, guides, ]
    .pipe $ ( fields, send ) =>
      [ line, glyph, guides, ] = fields
      unless CND.isa_text guides
        warn line, fields
      send fields
    .pipe $ ( [ line, glyph, guides, ], send ) =>
      send [ line, glyph, ( Array.from guides )... ]
    .pipe $ ( fields, send ) =>
      [ line, glyph, guide_0, guide_1, ] = fields
      send fields unless guide_0 is '一' or guide_1 is '一'
    .pipe $ ( fields, send ) =>
      [ line, glyph, guide_0, guide_1, ] = fields
      send fields if guide_0 is guide_1
    # .pipe D.$show()
    .pipe $ ( [ line, glyph, guide_0, guide_1, ], send ) => send line + '\n'
    .pipe output
# find_duplicated_guides()

#===========================================================================================================
test_permutations = ->
  get_pairs = ( list ) ->
    ### TAINT allow or eliminate duplicates? ###
    ### TAINT use all pairs and reversed pairs? ###
    length  = list.length
    R       = []
    # return []             if length is 0
    # return [ list[ 0 ], ] if length is 1
    for i in [ 0 ... length - 1 ]
      for j in [ i + 1 ... length ]
        tuple = [ list[ i ], list[ j ], ]
        ### TAINT should be sorted acc to strokeorder / guide nr, not codepoint ###
        tuple.sort()
        key = tuple.join ''
        R.push key unless key in R
        key = tuple[ 1 ] + tuple[ 0 ]
        R.push key unless key in R
    R.sort()
    return R
  help get_pairs [ '馬', '口', '冂', '口' ]
  help get_pairs [ '馬', '口', ]
  help get_pairs [ '馬', ]
  help get_pairs []
# test_permutations()

#===========================================================================================================
test_require_coffee = ->
  CS                       = require 'coffee-script'
  route = '/Volumes/Storage/io/SCRATCH/load-with-absolute-path/options.coffee'
  debug '©SOE29', rqr_route = require.resolve route
  source = njs_fs.readFileSync rqr_route, encoding: 'utf-8'
  # CND.dir CS
  # source = """
  #   @x = 42
  #   """
  debug '©jEOZd', CS.compile source, bare: true
  # debug '©U4Zmb', eval CS.compile source, bare: true
  debug '©U4Zmb', CS.eval source, bare: true
  # debug '©YMF7F', CS.require route

# test_require_coffee()

#===========================================================================================================
test_chr = ->
  CHR                       = require 'coffeenode-chr'
  debug '©K6tf7', CHR.as_rsg '&cdp#x8deb;', input: 'xncr'
  debug '©K6tf7', CHR.as_rsg '&#x21b7a;', input: 'xncr'
  debug '©K6tf7', CHR.as_rsg '鿉', input: 'xncr'
# test_chr()

#===========================================================================================================
f = ->
  a = arguments[ ... arguments.length - 1 ]
  if ( not global[ 'Reflect' ] )? or global[ 'Proxy' ]?[ 'create' ]?
    ### https://github.com/tvcutsem/harmony-reflect ###
    global[ 'Reflect' ] = require 'harmony-reflect'
  handler =
    get: ( target, key ) ->
      warn '>>>', key
      return target[ key ]
  demofs = new Proxy ( require './demofs' ), handler
  return null

#===========================================================================================================
fix_remarkably = ->
  # process.chdir '/Volumes/Storage/io/jizura-datasources'
  process.chdir '/Volumes/Storage/io/remarkably'
  debug '©pPhY8', require '.'
# fix_remarkably()




#===========================================================================================================
try_lazy_require = ->
  # CND.require = ( target, name, )
  D = {}
  Object.defineProperty D, 'FOO', get: -> urge 'XXXXXXX'; require 'pipedreams'
  # debug '©x7Tof', ( name for name of D )
  # debug '©x7Tof', ( name for name of D.FOO)
  D.FOO = D.FOO
  debug '©x7Tof', ( name for name of D.FOO)
# try_lazy_require()


#===========================================================================================================
try_slicing_html = ->
  HOTMETAL = require '../hotmetal'
  # CND.dir HOTMETAL
  document_html       = """
    <p>some words</p>
    <p>b</p>
    <p></p>
    """
  document_hotml      = HOTMETAL.HTML.parse document_html
  blocks_hotml        = HOTMETAL.slice_toplevel_tags document_hotml
  urge '©l9k4h', HOTMETAL.as_html document_hotml
  debug '©l9k4h', blocks_hotml
  debug '©l9k4h', blocks_hotml.length
  debug '©l9k4h', HOTMETAL.as_html blocks_hotml[ 1 ]
  # for idx in [ 1 .. block_hotml.length ]
  #   debug '©vrJcg', HOTMETAL.slice block_hotml, 0, idx
  #   help HOTMETAL.as_html HOTMETAL.slice block_hotml, 0, idx
  # help HOTMETAL.HTML.split "<p>helo world</p>"
  # for part, idx in HOTMETAL.HTML.parse "<p>helo world word for word</p>"
  #   help idx, part
  # # line_hotml          = HOTMETAL.slice block_hotml, line_start_idx, line_stop_idx

# try_slicing_html()

#===========================================================================================================
dynamic_buffer = ->
  buffer = new Buffer 3
  buffer.fill 0
  # buffer[ 0 ] = 255
  # buffer[ 10 ] = 255
  buffer.writeUIntBE 0xa1, 0, 1
  buffer.writeUIntBE 0xa2, 1, 1
  buffer.writeUIntBE 0xa3, 2, 1
  try
    buffer.writeUIntBE 0xa4, 3, 1
    # debug '©ipr2G', Buffer.byteLength 'abcdef', 'utf-8'
    # buffer.write 'abcdef', 3
  catch error
    debug '©FpHyj', rpr error::
    debug '©FpHyj', rpr error[ 'message' ]
    debug '©FpHyj', rpr error[ 'code' ]
    throw error
  debug '©zZZo2', buffer
# dynamic_buffer()

#===========================================================================================================
test_symbol_as_error = ->
  s = Symbol 'xxx'
  try
    throw s
  catch error
    help error
    help error is s

# test_symbol_as_error()

#===========================================================================================================
test_hollerith_codec = ->
  CODEC = require '/Volumes/Storage/io/hollerith-codec'
  debug '©sjAHS', CODEC.encode [ 'helo', ]
  long_text   = ( new Array 1025 ).join '#'
  debug '©sjAHS', CODEC.encode [ 'foo', [ long_text, long_text, long_text, long_text, ], 42, ]
# test_hollerith_codec()


#===========================================================================================================
test_codepoints = ->
  help chr for chr in 'äö𪜀'
# test_codepoints()

#===========================================================================================================
test_bloem = ->
  D = require 'pipedreams'
  $ = D.remit.bind D
  njs_zlib = require 'zlib'
  PSON = require 'pson'
  BLOOM = CND.BLOOM
  #.........................................................................................................
  settings =
    size:     10
  old_bloom = new BLOOM.new_filter settings
  BLOOM.add old_bloom, new Buffer 'helo world'
  BLOOM.add old_bloom, new Buffer 'how are you'
  BLOOM.report old_bloom
  help '©pOGr6', old_bloom
  bloom_data = BLOOM.as_buffer old_bloom
  debug '©pOGr6', bloom_data.length
  initialDictionary = [ 'foo', ]
  pson = new PSON.ProgressivePair initialDictionary
  data = { "hello": "world!" }
  # buffer = pson.encode data
  buffer = pson.toBuffer JSON.stringify old_bloom
  debug '©Pmfq1', buffer
  debug '©Pmfq1', buffer.length
  urge '©RTDLw', pson.decode buffer
  # new_bloom = BLOEM.ScalingBloem.destringify bloom_data
  # debug '©pOGr6', new_bloom
  zlib_settings =
    # level: njs_zlib.Z_BEST_COMPRESSION
    level: njs_zlib.Z_NO_COMPRESSION
  debug '©KdT6C', njs_zlib.deflateSync 'helo'
  debug '©KdT6C', njs_zlib.deflateSync 'dddddddddddddddddddddddd'
  debug '©KdT6C', ( njs_zlib.deflateSync bloom_data ).length
  debug '©KdT6C', ( njs_zlib.deflateSync bloom_data, zlib_settings ).length

# test_bloem()

#===========================================================================================================
test_archiver = ->
  #.........................................................................................................
  archiver  = require 'archiver'
  archive   = archiver.create 'zip', {}
  #.........................................................................................................
  archive.pipe $ ( data, send ) =>
    # whisper data.toString()
    whisper rpr data
    send data
  #.........................................................................................................
  archive.on 'end', =>
    help archive.pointer()
  #.........................................................................................................
  archive.on 'error', ( error ) =>
    throw error
  #.........................................................................................................
  # archive.append """
  #   some input
  #   ===================

  #   helo world!
  #   """, name: 'my-text'
  archive.append 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', name: 'my-text'
  archive.finalize()

#===========================================================================================================
test_keys = ->
  #---------------------------------------------------------------------------------------------------------
  @create_facetstream = ( db, settings ) ->
    lo_hint = null
    hi_hint = null
    #.......................................................................................................
    if settings?
      keys = Object.keys settings
      switch arity = keys.length
        when 1
          switch key = keys[ 0 ]
            when 'lo', 'prefix'
              lo_hint = settings[ key ]
            when 'hi'
              hi_hint = settings[ key ]
            else
              throw new Error "unknown hint key #{rpr key}" unless key in [ 'prefix', 'lo', 'hi', ]
        when 2
          keys.sort()
          if keys[ 0 ] is 'hi' and keys[ 1 ] is 'lo'
            lo_hint = settings[ 'lo' ]
            hi_hint = settings[ 'hi' ]
          else if keys[ 0 ] is 'prefix' and keys[ 1 ] is 'star'
            lo_hint = settings[ 'prefix' ]
            hi_hint = settings[ 'star' ]
          else
            throw new Error "illegal hint keys #{rpr keys}"
        else
          throw new Error "illegal hint arity #{rpr arity}"
    debug '©KaWp7', lo_hint, hi_hint
    # return @_create_facetstream db, lo_hint, hi_hint
  #.........................................................................................................
  db = null
  @create_facetstream db
  @create_facetstream db, lo: [ 'bar', ]
  @create_facetstream db, hi: [ 'foo', ]
  @create_facetstream db, lo: [ 'bar', ], hi: [ 'foo', ]
  @create_facetstream db, prefix: [ 'foo', ]
  @create_facetstream db, prefix: [ 'foo', ], star: '*'

# test_keys()



#===========================================================================================================
test_bloom_stream2 = ->
  ƒ           = CND.format_number
  HOLLERITH   = require '/Volumes/Storage/io/hollerith2'
  Bloom       = require 'bloom-stream'
  D           = require 'pipedreams'
  encode      = ( data ) -> new Buffer ( JSON.stringify data )
  $           = D.remit.bind D
  ### Bloom.forCapacity(capacity, errorRate, seed, hashType, streamOpts) ###
  bloom       = Bloom.forCapacity 1e6, 0.01
  seen        = {}
  # bloom       = Bloom.forCapacity 100, 0.1
  input       = D.create_throughstream()
  # level       = require 'level'
  # leveldb     = level '/tmp/test-db'
  input
    .pipe $ ( data, send ) ->
      seen[ data ] = 1
      debug '©rAv0J', data
      send data
    .pipe $ ( data, send ) ->
      send encode data
    .pipe bloom
  #.........................................................................................................
  bloom.on 'finish', ->
    # debug '©T3t5d', data
    for idx in [ 0 .. 20 ]
      d = bloom.has encode idx
      color = if d then CND.green else CND.red
      log color idx, d
    help "filter size: #{ƒ ( new Buffer JSON.stringify bloom.export() ).length} bytes"
    registers = bloom.export()[ 'registers' ]
    for register, register_idx in registers
      registers[ register_idx ] = null unless register?
    registers_bfr = HOLLERITH._encode_key null, registers
    help "filter size: #{ƒ registers_bfr.length} bytes"
    help "1:1 storage size: #{ƒ ( new Buffer JSON.stringify ( s for s of seen ) ).length} bytes"
    t0 = new Date()
    yield leveldb.put 'x', 'y'
    t1 = new Date()
    debug '©8yyXq', t1 - t0
    return
  #.........................................................................................................
  # step ( resume ) =>
    # for idx in [ 0 .. 1e5 ] by 3
  for idx in [ 0 .. 10 ] by 3
    key = "abcdefghijklmnop/#{idx}"
    # yield input.write key, resume
    input.write key
    debug '©0QQhI', 'd'
  input.end()

# test_bloom_stream2()

#===========================================================================================================
test_bloom_stream = ->
  Bloom   = require 'bloom-stream'
  D       = require 'pipedreams'
  encode  = ( data ) -> new Buffer ( JSON.stringify data )
  $       = D.remit.bind D
  ### Bloom.forCapacity(capacity, errorRate, seed, hashType, streamOpts) ###
  bloom   = Bloom.forCapacity 1e1, 1
  input   = D.create_throughstream()
  input
    .pipe $ ( data, send ) ->
      send encode data
    .pipe bloom
  #.........................................................................................................
  bloom.on 'finish', ->
    for idx in [ 0 .. 20 ]
      d = bloom.has encode idx
      color = if d then CND.green else CND.red
      log color idx, d
    debug '©fpWF8', bloom.export()
    return
  #.........................................................................................................
  for idx in [ 0 .. 10 ] by 3
    input.write idx
  input.end()

# test_bloom_stream()

g = ->
  #===========================================================================================================
  test_yargs = ->
    argv = require 'yargs'
      .usage('Usage: $0 <command> [options]')
      .command( "count", 'Count the lines in a file')
      .command( "foo", 'Foo the lines in a file')
      .demand(1)
      .example('$0 count -f foo.js', 'count the lines in the given file')
      .demand('f')
      .alias('f', 'file')
      .nargs('f', 1)
      .describe('f', 'Load a file')
      .help('h')
      .alias('h', 'help')
      .epilog('copyright 2015')
      .argv
    debug '©vRlET', argv
  test_yargs()

  #===========================================================================================================
  test_todolist_tsort = ->
    TS = CND.TSORT
    settings =
      strict:   yes
      # prefixes: [ 'f|', 'g|', ]
    g = TS.new_graph settings
    # help ( TS.link_down g, 'eat',               'go to bank'          ).join ' > '
    help ( TS.link_down g, 'buy food',          'cook'                ).join ' > '
    help ( TS.link_down g, 'fetch money',       'buy food'            ).join ' > '
    help ( TS.link_down g, 'do some reading',   'go to exam'          ).join ' > '
    help ( TS.link_down g, 'cook',              'eat'                 ).join ' > '
    help ( TS.link_down g, 'go to bank',        'fetch money'         ).join ' > '
    help ( TS.link_down g, 'fetch money',       'buy books'           ).join ' > '
    help ( TS.link_down g, 'buy books',         'do some reading'     ).join ' > '
    help ( TS.link_down g, 'go to market',      'buy food'            ).join ' > '
    help()
    help ( TS.link_down g, 'buy food',          'go home'             ).join ' > '
    help ( TS.link_down g, 'buy books',         'go home'             ).join ' > '
    help ( TS.link_down g, 'go home',           'cook'                ).join ' > '
    help ( TS.link_down g, 'eat',               'go to exam'          ).join ' > '

  #===========================================================================================================
  test_tsort = ->
    TS = CND.TSORT
    settings =
      strict:   yes
      prefixes: [ 'f|', 'g|', ]
    graph = TS.new_graph settings

    # TS.link_down graph, 'id', '$'
    # TS.link_up graph, '$', 'id'
    # TS.link graph, '$', '>', 'id'
    # debug '©TJLyH', TS.link graph, '$', '<', 'id'
    # debug '©TJLyH', TS.link graph, 'id', '<', '$'
    # help TS.sort graph
    urge '1', TS.link graph, 'id', '-', 'id'
    urge '2', TS.link graph, 'id', '>', '+'
    urge '3', TS.link graph, 'id', '>', '*'
    urge '4', TS.link graph, 'id', '>', '$'
    urge '5', TS.link graph, '+',  '<', 'id'
    urge '6', TS.link graph, '+',  '>', '+'
    urge '7', TS.link graph, '+',  '<', '*'
    urge '8', TS.link graph, '+',  '>', '$'
    urge '9', TS.link graph, '*',  '<', 'id'
    urge '10', TS.link graph, '*',  '>', '+'
    urge '11', TS.link graph, '*',  '>', '*'
    urge '12', TS.link graph, '*',  '>', '$'
    urge '13', TS.link graph, '$',  '<', 'id'
    urge '14', TS.link graph, '$',  '<', '+'
    urge '15', TS.link graph, '$',  '<', '*'
    urge '16', TS.link graph, '$',  '-', '$'
    debug '©DE1h1', graph

    help nodes = TS.sort graph
    matcher = [ 'f|id', 'g|id', 'f|*', 'g|*', 'f|+', 'g|+', 'g|$', 'f|$' ]
    unless CND.equals nodes, matcher
      throw new Error """is: #{rpr nodes}
        expected:  #{rpr matcher}"""
    help TS.get_precedences graph
    help TS.precedence_of graph, 'f|id'
    help TS.precedence_of graph, 'f|$'
    # urge '©TBjSx', ( nodes.indexOf 'f|id' ) > ( nodes.indexOf 'g|id' )
    # nodes.reverse()
    urge '1', ( TS.precedence_of graph, 'f|id' ) > ( TS.precedence_of graph, 'g|+' )
    urge '2', ( TS.precedence_of graph, 'f|id' ) > ( TS.precedence_of graph, 'g|*' )
    urge '3', ( TS.precedence_of graph, 'f|id' ) > ( TS.precedence_of graph, 'g|$' )
    urge '4', ( TS.precedence_of graph, 'f|+' ) < ( TS.precedence_of graph, 'g|id' )
    urge '5', ( TS.precedence_of graph, 'f|+' ) > ( TS.precedence_of graph, 'g|+' )
    urge '6', ( TS.precedence_of graph, 'f|+' ) < ( TS.precedence_of graph, 'g|*' )
    urge '7', ( TS.precedence_of graph, 'f|+' ) > ( TS.precedence_of graph, 'g|$' )
    urge '8', ( TS.precedence_of graph, 'f|*' ) < ( TS.precedence_of graph, 'g|id' )
    urge '9', ( TS.precedence_of graph, 'f|*' ) > ( TS.precedence_of graph, 'g|+' )
    urge '10', ( TS.precedence_of graph, 'f|*' ) > ( TS.precedence_of graph, 'g|*' )
    urge '11', ( TS.precedence_of graph, 'f|*' ) > ( TS.precedence_of graph, 'g|$' )
    urge '12', ( TS.precedence_of graph, 'f|$' ) < ( TS.precedence_of graph, 'g|id' )
    urge '13', ( TS.precedence_of graph, 'f|$' ) < ( TS.precedence_of graph, 'g|+' )
    urge '14', ( TS.precedence_of graph, 'f|$' ) < ( TS.precedence_of graph, 'g|*' )
  #   # add graph, '$', '-', '$'
  #   try
  #     TS.link_dual graph, '$', '>', '$'
  #     TS.link_dual graph, '$', '<', '$'
  #   catch error
  #     { message } = error
  #     if /^detected cycle involving node/.test message
  #       warn error
  #     else
  #       throw error
  #   # help nodes = TS.sort graph
  # test_tsort()
  # test_todolist_tsort()

  # `for ( var chr of 'ab𠀀cd' ) { debug( chr ); };`

### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###
iterate_over_maps = ->

  list_from_iterator = ( iterator ) ->
    R = []
    `for ( x of iterator ){ R.push( x ); }`
    return R

  d = new Map()
  k = [ 1, 2, ]
  d.set k, 42
  d.set [ 1, 2, ], 33
  debug '©ZUwOO', d.get k
  debug '©ZUwOO', d.get [ 1, 2, ]
  CND.dir d
  debug '©g60BV', d.size
  debug '©Vdchi', d.entries()
  debug '©Vdchi', d.entries().length
  debug '©Vdchi', list_from_iterator d.keys()
  debug '©Vdchi', list_from_iterator d.entries()
  debug '©Vdchi', list_from_iterator d.values()
  debug '©KzfCH', d.keys()
  debug '©GreeH', typeof d.values()
  debug '©GreeH', CND.type_of d.values()
  debug '©GreeH', Object::toString.call d.values()
  debug '©GreeH', Symbol.iterator


#===========================================================================================================
test_xregexp3 = ->
  ### See:
    https://github.com/loveencounterflow/xregexp3
    https://github.com/slevithan/xregexp/wiki/Roadmap
    https://gist.github.com/slevithan/2630353
    http://blog.stevenlevithan.com/archives/javascript-regex-and-unicode
  ###
  XRegExp                    = require 'xregexp3'
  #...........................................................................................................
  ### Always allow expressions like `\p{...}` to match beyond the Unicode BMP: ###
  # XRegExp.install 'astral'
  #...........................................................................................................
  ### Always allow new extensions: ###
  #  //L: "Letter", // Included in the Unicode Base addon
  # Ll: "Lowercase_Letter",
  # Lu: "Uppercase_Letter",
  # Lt: "Titlecase_Letter",
  # Lm: "Modifier_Letter",
  # Lo: "Other_Letter",
  # M: "Mark",
  # Mn: "Nonspacing_Mark",
  # Mc: "Spacing_Mark",
  # Me: "Enclosing_Mark",
  # N: "Number",
  # Nd: "Decimal_Number",
  # Nl: "Letter_Number",
  # No: "Other_Number",
  # P: "Punctuation",
  # Pd: "Dash_Punctuation",
  # Ps: "Open_Punctuation",
  # Pe: "Close_Punctuation",
  # Pi: "Initial_Punctuation",
  # Pf: "Final_Punctuation",
  # Pc: "Connector_Punctuation",
  # Po: "Other_Punctuation",
  # S: "Symbol",
  # Sm: "Math_Symbol",
  # Sc: "Currency_Symbol",
  # Sk: "Modifier_Symbol",
  # So: "Other_Symbol",
  # Z: "Separator",
  # Zs: "Space_Separator",
  # Zl: "Line_Separator",
  # Zp: "Paragraph_Separator",
  # C: "Other",
  # Cc: "Control",
  # Cf: "Format",
  # Co: "Private_Use",
  # Cs: "Surrogate",
  # Cn: "Unassigned"

  XRegExp.install 'extensibility'
  # debug '©YPaVu', pattern = XRegExp '(\\p{Sc}\\p{N}+)' # Sc: currency symbol, N: number
  # debug '©9Vi4k', "I have $五六 with me".match pattern
  # debug '©9Vi4k', "I have $789 with me".match pattern
  token_patterns = [
    XRegExp """('{3}|"{3}|\\p{L}+|\\p{Z}+|\\p{N}+|\\p{P}|\\p{S}|.+)"""
    # XRegExp """(\\s+)"""
    ]

  #.........................................................................................................
  insert = ( me, value, position = 'last', probe ) ->
    arity = arguments.length
    #   when 2
    #     value = position
    #     position = 'last'
    #   when 3
    #     null
    #   else
    #     throw new Error "expected 2 or 3 arguments, got #{arity}"
    switch position
      when 'first'
        me.splice 0, 0, value
        R = 0
      when 'last'
        me.push value
        R = me.length - 1
      when 'before', 'after'
        throw new Error "expected 4 arguments, got #{arity}" unless arity is 4
        R = me.indexOf probe
        throw new Error "unable to find #{rpr value} in list" unless R >= 0
        me.splice R, 0, value
    return R

  d = []
  debug '©U08qy', insert d, '+'
  debug '©Gz6lh', insert d, '*'
  debug '©I23qn', insert d, '-', 'before', '*'
  debug '©U08qy', insert d, '~'
  debug '©BlRvr', d

  #.........................................................................................................
  topmost_of      = ( stack ) -> stack[ stack.length - 1 ]

  #.........................................................................................................
  base_tokens_of  = ( text  ) -> ( t for t in text.split topmost_of token_patterns when t isnt '' )

  #.........................................................................................................
  show = ( tokens ) ->
    # help rpr token for token in tokens
    # help JSON.stringify tokens
    # log ( ( CND.lime token ) for token in tokens ).join CND.grey '_'
    # colors = [ CND.white, CND.gold, ]
    colors = [ CND.lime, CND.orange, ]
    log ( ( colors[ i % 2 ] t.replace /\s/g, '␣' ) for t, i in tokens ).join ' '
    return null

  #.........................................................................................................
  recognize_assignments = ( tokens ) ->
    R = []
    skip = 0
    for token, token_idx in tokens
      if skip > 0
        skip += -1
        continue
      if token.length > 1 and /:$/.test token
        R.push token[ .. token.length - 2 ]
        R.push token[ token.length - 1 ]
        continue
      R.push token
    return R

  #.........................................................................................................
  recognize_eos_mark = ( tokens ) ->
    R = []
    skip = 0
    for token, token_idx in tokens
      if skip > 0
        skip += -1
        continue
      if token.length > 1 and /;$/.test token
        R.push token[ .. token.length - 2 ]
        R.push token[ token.length - 1 ]
        continue
      R.push token
    return R

  #.........................................................................................................
  text            = """helo 345world(d) '''34 great''' (,sw x"""
  text            = """d: foo/bar/$baz + /k += 3"""
  text            = """3+1*2*4+5"""
  text            = """foo: 34e3 + 1 ** +bar; baz: 42"""
  tokens = base_tokens_of text
  show tokens
  tokens = recognize_assignments tokens
  show tokens
  tokens = recognize_eos_mark tokens
  show tokens

  #.........................................................................................................
  # XRegExp.exec(str, regex, [pos], [sticky])
  position      = 0
  matches       = []
  match         = null
  token_pattern = topmost_of token_patterns
  while match = XRegExp.exec text, token_pattern, position, 'sticky'
    # debug '©LrjEq', match
    matches.push match[ 1 ]
    position = match.index + match[ 0 ].length
  show matches

  #.........................................................................................................
  new_parse = require 'tdop'
  parse       = new_parse()

  help parse 'var a = 1 + 1;'
  urge parse """
    var f = function(){};
    var x = f(8);"""


# test_xregexp3()



f = ->

  #===========================================================================================================
  test_cs_lexer = ->
    { Lexer } = require 'coffee-script/lib/coffee-script/lexer'
    lexer = new Lexer()
    source = """
    f 'helo'
      """
    settings =
      sourceMap:  false
    debug '©2LYns', lexer.tokenize source, settings

  test_cs_lexer()


  #===========================================================================================================
  test_error = ->
    require 'es6-symbol/implement'
    x0 = Symbol 'x'
    x1 = Symbol 'x'
    y0 = Symbol.for 'y'
    y1 = Symbol.for 'y'
    debug '©s7yDl', x0 is x1
    debug '©s7yDl', y0 is y1
    @codes = {}

    add_symbol = ( host, name ) ->
      return R if ( R = host[ name ] )?
      R             = Symbol name
      host[ name  ] = R
      host[ R     ] = name
      return R

    new_error = ( host, code, message ) ->
      R           = new Error message
      code        = add_symbol host, code
      R[ 'code' ] = code
      return R

    for name in [ 'not implemented', 'division by zero', ]
      add_symbol @, name

    error = @new_error @codes, 'unknown name', "unknown name: 'xy'"
    debug '©c9Pf5', @codes
    debug '©c9Pf5', error
    debug '©EDcXf', error[ 'code' ]
    debug '©EDcXf', error[ 'code' ] is @[ 'codes' ][ 'unknown name' ]
    throw error

  test_error()


  #===========================================================================================================
  test_hummus = ->
    hummus    = require 'hummus'
    `
    var pdfWriter = hummus.createWriterToModify(
                                         '/tmp/kwic-all-excerpts.pdf',
                                         {modifiedFilePath:'/tmp/kwic-all-excerpts-mod.pdf'});
    var pageModifier = new hummus.PDFPageModifier(pdfWriter,0);
    var cxt = pageModifier.startContext().getContext();
    cxt.drawCircle(
                  centerX,
                  centerY,
                  radius,
                  {
                      type:stroke,
                      width:1,
                      color:'black'
                  });
    pageModifier.endContext().writePage();
    pdfWriter.end();
    `
    # debug '©WFjIM', pageModifier

    # pdf_route = '/Volumes/Storage/io/SCRATCH/node_modules/hummus/tests/BasicJPGImagesTest.js'
    # pdfWriter = hummus.createWriterToModify pdf_route, modifiedFilePath: modified_route
    # pageModifier = new ( hummus.PDFPageModifier )( pdfWriter, 0 )
    # pageModifier.startContext().getContext().writeText 'Test Text', 75, 805,
    #   font: pdfWriter.getFontForFile('/Volumes/Storage/io/SCRATCH/node_modules/hummus/tests/TestMaterials/fonts/Couri.ttf')
    #   size: 14
    #   colorspace: 'gray'
    #   color: 0x00
    # pageModifier.endContext().writePage()
    # pdfWriter.end()
    # console.log 'done - ok'

  test_hummus()
  # process.exit()

  #===========================================================================================================
  show_inherited_names = ->
    ### http://stackoverflow.com/a/8024294/256361 ###
    get_all_property_names = ( x ) ->
      R = []
      loop
        R.push name for name in ( Object.getOwnPropertyNames x ) unless name in R
        break unless ( x = Object.getPrototypeOf x )?
      return R
    debug '©A3bXj', get_all_property_names []
    debug '©A3bXj', get_all_property_names [ 1, 2, 3, ]
    debug '©qAxof', get_all_property_names {}
    debug '©smLj8', get_all_property_names { 'foo': 'bar', }
    debug '©smLj8', { 'foo': 'bar', }[ 'constructor' ]
    debug '©smLj8', ( Object.getPrototypeOf { 'foo': 'bar', } )?
    debug '©smLj8', Object.getOwnPropertyNames Object.getPrototypeOf { 'foo': 'bar', }
    # debug '©qpIQe', get_all_property_names Object.create()
    debug '©034vW', get_all_property_names Object.create null
    CND.dir {}

  show_inherited_names()
  # process.exit()

  #===========================================================================================================
  test_gm = ->
    new_pdf   = require 'gm'
    pdf_route = '/Volumes/Storage/io/jizura-datasources/data/4-pdf/kwic-all.pdf'
    pdf       = new_pdf pdf_route
    pdf.identify pdf_route, ( error, data ) ->
      throw error if error?
      debug '©oP284', data

  test_gm()

  #===========================================================================================================
  test_pdfinfo = ->
    njs_cp    = require 'child_process'
    pdf_route = '/Volumes/Storage/io/jizura-datasources/data/4-pdf/kwic-all.pdf'
    command   = "pdfinfo -meta #{pdf_route}"
    pattern   = /\nPages:\s+([0-9]+)\n/
    njs_cp.exec command, ( error, stdout, stderr ) ->
      throw error if error?
      warn stderr
      help stdout
      unless ( match = stdout.match pattern )?
        throw new Error "unable to read pdfinfo output #{rpr stdout}"
      debug '©KJayE', rpr match[ 1 ]
      page_count = parseInt match[ 1 ], 10
      debug '©1Dkzn', rpr page_count

  test_pdfinfo()
  # process.exit()

  #===========================================================================================================
  test_regex_safeness = ->
    ### https://github.com/substack/safe-regex ###
    regex_is_safe = require 'safe-regex'
    # matcher = /^\n?‡(\S+?)\n$/
    # probe   = '\n‡foobar\n'
    matcher = /^\n?‡(\S+?)\n$/
    debug '©Md6b4', regex_is_safe /(a+){10}/
    debug '©Jdjoh', regex_is_safe /^(\S+)\s+(.+)$/
    debug '©6UvDi', regex_is_safe matcher
    probe   = '\n‡abc\n'
    debug '©32VzH', probe.match matcher

  test_regex_safeness()
  process.exit()

  #===========================================================================================================
  match_newlines = ->
    # matcher = /^\n?‡(\S+?)\n$/
    # probe   = '\n‡foobar\n'
    matcher = /^\n?‡(\S+?)\n$/
    probe   = '\n‡abc\n'
    debug '©32VzH', probe.match matcher

  match_newlines()
  process.exit()

  #===========================================================================================================
  isolate_content = ->
    register_intro_route  = '/Volumes/Storage/io/jizura-datasources/data/3-tex-generated/kwic-register-intro.tex'
    register_intro_tex    = njs_fs.readFileSync register_intro_route, 'utf-8'
    matcher               = ///
      ^
      [\s\S]*
      \\begin\{document\}
      ([\s\S]+)
      \\end\{document\}
      [\s\S]*
      $ ///
    register_intro_tex    = register_intro_tex.replace matcher, '$1'
    debug '©dJ32E', register_intro_tex
  isolate_content()
  process.exit()


  #===========================================================================================================
  symbols_as_attributes = ->
    d       = { foo: 42, }
    s       = Symbol 'magic'
    debug '©RedP2', ( Symbol 'magic' ) is ( Symbol 'magic' )
    debug '©RedP2', ( Symbol.for 'magic' ) is ( Symbol.for 'magic' )
    d[ s ]  = "it's magic"
    debug '©VbITC', rpr d
    debug '©VbITC', rpr s
    debug '©LFg8G', ( Object.keys d )
    debug '©LFg8G', ( [ name, value, ] for name, value of d )


  symbols_as_attributes()
  process.exit()



  #===========================================================================================================
  write_numbers = ->
    cids = [
      0x0020
      0x00A0
      0x1680
      0x180E
      0x2000
      0x2001
      0x2002
      0x2003
      0x2004
      0x2005
      0x2006
      0x2007
      0x2008
      0x2009
      0x200A
      0x200B
      0x202F
      0x205F
      0x3000
      0xFEFF
      ]
    number = "100'000'000'000'000'000'000'000'000'000'000'000'000'000'000'000'000"
    echo number.replace /'/g, ''
    for cid in cids
      echo ( number.replace /'/g, String.fromCharCode cid ), "0x#{cid.toString 16}"
      # echo ( number.replace /'/g, String.fromCodePoint cid ), "0x#{cid.toString 16}"
  write_numbers()
  process.exit()

  #===========================================================================================================
  parse_md = ->
    settings =
      html:         true
      linkify:      false
      breaks:       false
      langPrefix:   'codelang-'
      typographer:  true
      quotes:       '“”‘’'
      source_references: true
    # parser = ( require 'markdown-it' ) settings
    source_references = require 'coffeenode-markdown-it/lib/rules_core/source_references'
    R = ( require 'coffeenode-markdown-it' ) settings
    R = R.use source_references, { template: "<rf loc='${start},${stop}'></rf>", }
    md = """
    # hello

    <!--#123-->

    world

    yet *another* paragraph

    ```
    some code
    ```

    """
    ###
    { type: 'inline',
        content: 'world<!-- 123 -->',
        level: 1,
        lines: [ 2, 3 ],
        children:
         [ { type: 'text', content: 'world', level: 0 },
           { type: 'html_inline', content: '<!-- 123 -->', level: 0 } ] },
    ###
    # CND.dir parser
    # urge elements = parser.parse md
    # md = ( "#{line}<!-- #{idx} -->" for line, idx in md.split '\n' ).join '\n'
    help R.render md



  parse_md()
  process.exit()
