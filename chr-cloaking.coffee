




############################################################################################################
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





#-----------------------------------------------------------------------------------------------------------
escape_for_re = ( text ) ->
  ### from https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions ###
  return text.replace /[.*+?^${}()|[\]\\]/g, "\\$&"

# #-----------------------------------------------------------------------------------------------------------
# ### `mc`: 'meta character' ###
# metaesc_mc_master         = '%'
# metaesc_mc_bs             = '&'
# metaesc_mc_macro          = '!'
# metaesc_mc_stop           = ';'

#-----------------------------------------------------------------------------------------------------------
### `mc`: 'meta character' ###
metaesc_mc_master         = '\x10'
metaesc_mc_bs             = '\x11'
metaesc_mc_macro          = '\x12'
metaesc_mc_stop           = '\x13'

#-----------------------------------------------------------------------------------------------------------
### `mce`: 'meta character escaped' ###
metaesc_mce_master        = escape_for_re metaesc_mc_master
metaesc_mce_bs            = escape_for_re metaesc_mc_bs
metaesc_mce_macro         = escape_for_re metaesc_mc_macro
metaesc_mce_stop          = escape_for_re metaesc_mc_stop

#-----------------------------------------------------------------------------------------------------------
### `mcp`: 'meta character pattern' ###
metaesc_mcp_master        = /// #{metaesc_mce_master}     ///g
metaesc_mcp_bs            = /// #{metaesc_mce_bs}         ///g
metaesc_mcp_macro         = /// #{metaesc_mce_macro}      ///g
metaesc_mcp_stop          = /// #{metaesc_mce_stop}       ///g

#-----------------------------------------------------------------------------------------------------------
### `tsc`: 'target sequence character' ###
metaesc_tsc_master        = "#{metaesc_mc_master}A"
metaesc_tsc_bs            = "#{metaesc_mc_master}B"
metaesc_tsc_macro         = "#{metaesc_mc_master}M"
metaesc_tsc_stop          = "#{metaesc_mc_master}S"

#-----------------------------------------------------------------------------------------------------------
### `tsp`: 'target sequence pattern' ###
metaesc_tsp_master        = /// #{metaesc_tsc_master}    ///g
metaesc_tsp_bs            = /// #{metaesc_tsc_bs}        ///g
metaesc_tsp_macro         = /// #{metaesc_tsc_macro}     ///g
metaesc_tsp_stop          = /// #{metaesc_tsc_stop}      ///g

#-----------------------------------------------------------------------------------------------------------
### backslashes are dealt with in slightly different ways: ###
### `oc`: 'original character' ###
metaesc_oc_backslash      = '\\'
### `op`: 'original pattern' ###
metaesc_oce_backslash     = escape_for_re metaesc_oc_backslash
metaesc_mcp_backslash     = /// #{metaesc_oce_backslash} ( (?: [  \ud800-\udbff ] [ \udc00-\udfff ] ) | . ) ///g
metaesc_tsp_backslash     = /// #{metaesc_mc_bs} ( [ 0-9 a-f ]+ ) #{metaesc_mc_stop} ///g
### `rm`: 'remove' ###
metaesc_rm_backslash      = /// #{metaesc_oce_backslash} ( . ) ///g

#-----------------------------------------------------------------------------------------------------------
@cloak_escape_chrs = ( text ) =>
  R = text
  R = R.replace metaesc_mcp_master,    metaesc_tsc_master
  R = R.replace metaesc_mcp_bs,        metaesc_tsc_bs
  R = R.replace metaesc_mcp_macro,     metaesc_tsc_macro
  R = R.replace metaesc_mcp_stop,      metaesc_tsc_stop
  return R

#-----------------------------------------------------------------------------------------------------------
@uncloak_escape_chrs = ( text ) =>
  R = text
  R = R.replace metaesc_tsp_macro,       metaesc_mc_macro
  R = R.replace metaesc_tsp_bs,          metaesc_mc_bs
  R = R.replace metaesc_tsp_master,      metaesc_mc_master
  R = R.replace metaesc_tsp_stop,        metaesc_mc_stop
  return R

#-----------------------------------------------------------------------------------------------------------
@cloak_backslashed_chrs = ( text ) =>
  R = text
  R = R.replace metaesc_mcp_backslash, ( _, $1 ) ->
    cid = ( $1.codePointAt 0 ).toString 16
    return "#{metaesc_mc_bs}#{cid}#{metaesc_mc_stop}"
  return R

#-----------------------------------------------------------------------------------------------------------
@uncloak_backslashed_chrs = ( text ) =>
  R = text
  R = R.replace metaesc_tsp_backslash, ( _, $1 ) ->
    chr = String.fromCodePoint parseInt $1, 16
    return "#{metaesc_oc_backslash}#{chr}"
  return R

#-----------------------------------------------------------------------------------------------------------
@remove_backslashes = ( text ) =>
  return text.replace metaesc_rm_backslash, '$1'

text = """
  % & ! ;
  some <<unlicensed>> stuff here. \\𠄨 &%!%A&123;
  some more \\\\<<unlicensed\\\\>> stuff here.
  some \\<<licensed\\>> stuff here, and <\\<
  The <<<\\LaTeX{}>>> Logo: `<<<\\LaTeX{}>>>`
  """
# debug '©94643', metaesc_mcp_backslash
# text = "% & ! ; \\ \\\\ \\𠄨"
# text = "<<"
# text = "x"
# whisper rpr cloaked_text
DIFF = require 'coffeenode-diff'
cloaked_text = text
log '1', CND.rainbow ( text )
log '2', CND.rainbow ( cloaked_text   = @cloak_escape_chrs         cloaked_text )
log '3', CND.rainbow ( cloaked_text   = @cloak_backslashed_chrs    cloaked_text )
uncloaked_text = cloaked_text
log '4', CND.rainbow ( uncloaked_text = @uncloak_backslashed_chrs  uncloaked_text )
log '5', CND.rainbow ( uncloaked_text = @uncloak_escape_chrs       uncloaked_text )
# log '7', CND.rainbow '©79011', @remove_backslashes               uncloaked_text
if uncloaked_text isnt text
  log DIFF.colorize text, uncloaked_text

log CND.steel '########################################################################'
