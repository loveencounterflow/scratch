




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

#-----------------------------------------------------------------------------------------------------------
MKTS._escape_command_fences = ( text ) ->
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
MKTS._unescape_command_fences_A = ( text ) ->
  R = text
  R = R.replace /♎4/g, '<<'
  return R

#-----------------------------------------------------------------------------------------------------------
MKTS._unescape_command_fences_B = ( text ) ->
  R = text
  R = R.replace /♎3/g, '<<'
  R = R.replace /♎2/g, '<<'
  R = R.replace /♎1/g, '<<'

#-----------------------------------------------------------------------------------------------------------
MKTS._unescape_command_fences_C = ( text ) ->
  R = text
  R = R.replace /♎b/g, '☚'
  R = R.replace /♎a/g, '☛'
  R = R.replace /♎0/g, '♎'
  return R

#-----------------------------------------------------------------------------------------------------------
### TAINT don't keep state here ###
MKTS._raw_content_by_ids    = new Map()
MKTS._raw_id_by_contents    = new Map()
MKTS._raw_bracketed_pattern = ///
  (?: ( ^ | [^\\] ) <<\( raw >>               << raw \)>> ) |
  (?: ( ^ | [^\\] ) <<\( raw >> ( .*? [^\\] ) << raw \)>> )
  ///g
MKTS._raw_heredoc_pattern = ///
  ( ^ | [^\\] ) <<! raw: ( [^\s>]* )>> ( .*? ) \2
  ///g
MKTS._raw_id_pattern        = ///
  B ( [ 0-9 ]+ ) Z
  ///g
MKTS._command_pattern = ///
  ( ^ | [^\\] )
  (
    <<
    [ !      { [ (        ]?
    [ ^ \s ! { [ ( ) \] } ]+?
    [              ) \] } ]?
    >>
    )
  ///g

#-----------------------------------------------------------------------------------------------------------
MKTS._escape_raw_spans = ( text ) ->
  R = text
  R = @_escape_raw_escapes R
  R = R.replace @_raw_bracketed_pattern, ( _, $1, $2, $3 ) =>
    $1           ?= ''
    $2           ?= ''
    $1           += $2
    raw_content   = $3 ? ''
    id            = @_raw_id_from_content raw_content
    return "#{$1}B#{id}Z"
  R = R.replace @_raw_heredoc_pattern, ( _, $1, $2, $3 ) =>
    raw_content   = $3 ? ''
    id            = @_raw_id_from_content raw_content
    return "#{$1}B#{id}Z"
  R = R.replace @_command_pattern, ( _, $1, $2 ) =>
    raw_content   = $2 ? ''
    id            = @_raw_id_from_content raw_content
    return "#{$1}B#{id}Z"
  return R

#-----------------------------------------------------------------------------------------------------------
MKTS._raw_id_from_content = ( raw_content ) ->
  unless ( R = @_raw_id_by_contents.get raw_content )?
    R = @_raw_content_by_ids.size
    @_raw_content_by_ids.set R, raw_content
    @_raw_id_by_contents.set raw_content, R
  return R

#-----------------------------------------------------------------------------------------------------------
MKTS._unescape_raw_spans = ( text ) ->
  R = text
  R = text.replace @_raw_id_pattern, ( _, id_txt ) =>
    id = parseInt id_txt, 10
    throw new Error "unknown ID #{rpr id_txt}" unless ( R = @_raw_content_by_ids.get id )?
    return R
  R = @_unescape_raw_escapes R
  return R

#-----------------------------------------------------------------------------------------------------------
MKTS._escape_raw_escapes = ( text ) ->
  R = text
  R = R.replace /A/g, 'Aa'
  R = R.replace /B/g, 'Ab'
  R = R.replace /Z/g, 'Az'
  return R

#-----------------------------------------------------------------------------------------------------------
MKTS._unescape_raw_escapes = ( text ) ->
  R = text
  R = R.replace /Az/g, 'Z'
  R = R.replace /Ab/g, 'B'
  R = R.replace /Aa/g, 'A'
  return R


############################################################################################################
test_MKTS_raw_escaper = ->
  md_parser   = MKTS._new_markdown_parser()
  source = """<<(raw>>first B0Z AaAbAz<<raw)>>
    abcdef0123zABCaZ B0Z B1Z
    A line with <<!raw:|>>a **raw** stretch| that ends here.
    Another <<!raw:line>>rawish line
    Another <<!raw:--->>rawish--- line
    helo <<(raw>>first B0Z AaAbAz<<raw)>>
    helo \\<<(raw>>first B0Z<<raw)>>
    helo <<(code>>*world*<<code)>>
    some <<(foo>>*emphasized stuff
      that runs across several lines*<<foo)>>
    helo <<(raw>>do **not** parse this<<raw)>>
    <<(raw>><<raw)>>
    """
  #   # a\x00\x01\x02\x03\x04\x05\x06\x07\x08z
  # source = """
  #   a\u0001,\u0002,\u0003,\u0004,\u0005,\u0006,\u000e,\u000f,\u0010,\u0011,\u0012,\u0013,\u0014,\u0015,\u0016,\u0017,\u0018,\u0019,\u001a,\u001b,\u001c,\u001d,\u001e,\u001fz
  #   """
  help source
  # debug '©RJgXu', source.match MKTS._raw_heredoc_pattern
  log rainbow source = MKTS._escape_raw_spans source
  debug '©g8aFl', MKTS._raw_content_by_ids
  log rainbow source = md_parser.render source
  log rainbow source = MKTS._unescape_raw_spans source
test_MKTS_raw_escaper()

# help rpr ( String.fromCodePoint cid for cid in [ 0x00 .. 0x20 ] ).join ','





