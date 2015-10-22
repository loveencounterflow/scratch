




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
MKTS                      = require '../jizura/lib/MKTS.js'

# #-----------------------------------------------------------------------------------------------------------
# MKTS._escape_command_fences = ( text ) ->
#   R = text
#   R = R.replace /♎/g,       '♎0'
#   R = R.replace /☛/g,       '♎a'
#   R = R.replace /☚/g,       '♎b'
#   R = R.replace /\\<\\</g,  '♎1'
#   R = R.replace /\\<</g,    '♎2'
#   R = R.replace /<\\</g,    '♎3'
#   R = R.replace /<</g,      '♎4'
#   return R

# #-----------------------------------------------------------------------------------------------------------
# MKTS._unescape_command_fences_A = ( text ) ->
#   R = text
#   R = R.replace /♎4/g, '<<'
#   return R

# #-----------------------------------------------------------------------------------------------------------
# MKTS._unescape_command_fences_B = ( text ) ->
#   R = text
#   R = R.replace /♎3/g, '<<'
#   R = R.replace /♎2/g, '<<'
#   R = R.replace /♎1/g, '<<'

# #-----------------------------------------------------------------------------------------------------------
# MKTS._unescape_command_fences_C = ( text ) ->
#   R = text
#   R = R.replace /♎b/g, '☚'
#   R = R.replace /♎a/g, '☛'
#   R = R.replace /♎0/g, '♎'
#   return R

#-----------------------------------------------------------------------------------------------------------
### TAINT don't keep state here ###
MKTS.XXX_raw_content_by_ids    = new Map()
MKTS.XXX_raw_id_by_contents    = new Map()
MKTS.XXX_command_by_ids        = new Map()
MKTS.XXX_id_by_commands        = new Map()

#-----------------------------------------------------------------------------------------------------------
MKTS.XXX_raw_bracketed_pattern = ///
  (?: ( ^ | [^\\] ) <<\( raw >>               << raw \)>> ) |
  (?: ( ^ | [^\\] ) <<\( raw >> ( .*? [^\\] ) << raw \)>> )
  ///g
MKTS.XXX_raw_heredoc_pattern = ///
  ( ^ | [^\\] ) <<! raw: ( [^\s>]* )>> ( .*? ) \2
  ///g
MKTS.XXX_raw_id_pattern      = ///
  \x11 ( [ 0-9 ]+ ) \x13
  ///g
MKTS.XXX_command_id_pattern  = ///
  \x12 ( [ 0-9 ]+ ) \x13
  ///g
MKTS.XXX_command_pattern = ///
  ( ^ | [^\\] )
  (
    <<
    ( [     ! { [ (           ]?  )
    ( [^ \s ! { [ ( ) \] > }  ]+? )
    ( [              ) \]   } ]?  )
    >>
    )
  ///g

#-----------------------------------------------------------------------------------------------------------
MKTS.XXX_escape_raw_spans = ( text ) ->
  R = text
  R = @XXX_escape_escape_chrs R
  R = R.replace @XXX_raw_bracketed_pattern, ( _, $1, $2, $3 ) =>
    $1           ?= ''
    $2           ?= ''
    $1           += $2
    raw_content   = $3 ? ''
    id            = @XXX_raw_id_from_content 'raw', raw_content
    return "#{$1}\x11#{id}\x13"
  R = R.replace @XXX_raw_heredoc_pattern, ( _, $1, $2, $3 ) =>
    raw_content   = $3 ? ''
    id            = @XXX_raw_id_from_content 'raw', raw_content
    return "#{$1}\x11#{id}\x13"
  R = R.replace @XXX_command_pattern, ( _, $1, $2, $3, $4, $5 ) =>
    raw_content     = $2
    parsed_content  = [ $3, $4, $5, ]
    id              = @XXX_raw_id_from_content 'command', raw_content, parsed_content
    return "#{$1}\x12#{id}\x13"
  return R

#-----------------------------------------------------------------------------------------------------------
MKTS.XXX_raw_id_from_content = ( collection_name, raw_content, parsed_content = null ) ->
  switch collection_name
    when 'raw'
      fragment_by_ids = @XXX_raw_content_by_ids
      id_by_fragments = @XXX_raw_id_by_contents
    when 'command'
      fragment_by_ids = @XXX_command_by_ids
      id_by_fragments = @XXX_id_by_commands
    else throw new Error "unknown collection collection_name #{rpr collection_name}"
  unless ( R = id_by_fragments.get raw_content )?
    R = fragment_by_ids.size
    fragment_by_ids.set R, parsed_content ? raw_content
    id_by_fragments.set raw_content, R
  return R

#-----------------------------------------------------------------------------------------------------------
MKTS.XXX_expand_commands = ( text ) ->
  is_command  = yes
  R           = []
  for stretch in text.split @XXX_command_id_pattern
    is_command = not is_command
    if is_command
      id      = parseInt stretch, 10
      command = @XXX_command_by_ids.get id
      ### should never happen: ###
      throw new Error "unknown ID #{rpr stretch}"                 unless command?
      throw new Error "not registered correctly: #{rpr stretch}"  unless CND.isa_list command
      [ left_fence, name, right_fence, ] = command
      R.push CND.gold "#{left_fence}#{name}#{right_fence}"
    else
      R.push CND.steel stretch
  return R.join ''

#-----------------------------------------------------------------------------------------------------------
MKTS.XXX_unescape_raw_spans = ( text ) ->
  R = text
  R = text.replace @XXX_raw_id_pattern, ( _, id_txt ) =>
    id  = parseInt id_txt, 10
    R   = @XXX_raw_content_by_ids.get id
    throw new Error "unknown ID #{rpr id_txt}" unless R?
    return R
  R = @XXX_unescape_escape_chrs R
  return R

#-----------------------------------------------------------------------------------------------------------
MKTS.XXX_escape_escape_chrs = ( text ) ->
  R = text
  R = R.replace /\x10/g, '\x10a'
  R = R.replace /\x11/g, '\x10r'
  R = R.replace /\x12/g, '\x10c'
  R = R.replace /\x13/g, '\x10z'
  return R

#-----------------------------------------------------------------------------------------------------------
MKTS.XXX_unescape_escape_chrs = ( text ) ->
  R = text
  R = R.replace /\x10z/g, '\x13'
  R = R.replace /\x10r/g, '\x11'
  R = R.replace /\x10c/g, '\x12'
  R = R.replace /\x10a/g, '\x10'
  return R


############################################################################################################
test_MKTS_raw_escaper = ->
  md_parser   = MKTS._new_markdown_parser()
  source = """<<(raw>>first R0Z AaAbAz<<raw)>>
    abcdef0123zABCaZ R0Z B1Z
    A line with <<!raw:|>>a **raw** stretch| that ends here.
    Another <<!raw:line>>rawish line
    Another <<!raw:--->>rawish--- line
    helo <<(raw>>first R0Z AaAbAz<<raw)>>
    helo \\<<(raw>>first R0Z<<raw)>>
    helo <<(code>>*world*<<code)>>
    some <<(foo>>***emphasized stuff
    that runs across several** lines*<<foo)>>
    helo <<(raw>>do **not** parse this<<raw)>>
    \\n\\b
    A Command: <<!literally>>.
    <<(raw>>Not A Command: <<!literally>>.<<raw)>>
    """
  #   # a\x00\x01\x02\x03\x04\x05\x06\x07\x08z
  # source = """
  #   a\u0001,\u0002,\u0003,\u0004,\u0005,\u0006,\u000e,\u000f,\u0010,\u0011,\u0012,\u0013,\u0014,\u0015,\u0016,\u0017,\u0018,\u0019,\u001a,\u001b,\u001c,\u001d,\u001e,\u001fz
  #   \x01,\x02,\x03,\x04,\x05,\x06,\x0e,\x0f,\x10,\x11,\x12,\x13,\x14,\x15,\x16,\x17,\x18,\x19,\x1a,\x1b,\x1c,\x1d,\x1e,\x1f
  #   """
  help source
  # debug '©RJgXu', source.match MKTS.XXX_raw_heredoc_pattern
  log '©qnM1j', rainbow source = MKTS.XXX_escape_raw_spans source
  log '©Rg4pE', CND.plum  '©g8aFl raw_content ', MKTS.XXX_raw_content_by_ids
  log '©QP5XS', CND.steel '©g8aFl command     ', MKTS.XXX_command_by_ids
  log '©KLwNa', rainbow source = md_parser.render source
  log '©TsXcc', source.replace /([\x10-\x13])/g, ( _, $1 ) -> ( CND.red $1.codePointAt 0 ).toString 16
  log '©XsxGS', rainbow source = MKTS.XXX_expand_commands source
  log '©RdG7Y', rainbow source = MKTS.XXX_unescape_raw_spans source

test_MKTS_raw_escaper()

# help rpr ( String.fromCodePoint cid for cid in [ 0x00 .. 0x20 ] ).join ','
# debug '©Soare', md_parser.render "\\a,\\b,\\c,\\d,\\e,\\f,\\g,\\h,\\i,\\j,\\k,\\l,\\m,\\n,\\o,\\p,\\q,\\r,\\s,\\t,\\u,\\v,\\w,\\x,\\y,\\z,", {}





