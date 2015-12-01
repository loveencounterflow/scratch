




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

###

Cloaking characters by chained replacements:

Assuming an alphabet `/[0-9]/`, cloaking characters starting from `0`.

To cloak only `0`, we have to free the string of all occurrences of that
character. In order to do so, we choose a primary escapement character, '1',
and a secondary escapement character, conveniently also `1`. With those, we
can replace all occurrences of `0` as `11`. However, that alone would produce
ambiguous sequences. For example,  the string `011` results in `1111`, but so
does the string `1111` itself (because it does not contain a `0`, it remains
unchanged when replacing `0`). Therefore, we have to escape the  secondary
escapement character itself, too; we choose the secondary replacement `1 ->
12`  which has to come *first* when cloaking and *second* when uncloaking.
This results in the following cloaking chain:

         0123456789
1 -> 12: 01223456789
0 -> 11: 111223456789

The resulting string is free of `0`s. Because all original `0`s and `1`s have
been preserved in disguise, we are now free to insert additional data into the
string.

Let's assume we have a text transformer `f`, say, `f ( x ) -> x.replace
/456/g, '15'`, and a more comprehensive text transformer `g` which includes
calls to `f` and other elementary transforms. Now, we would like to apply `g`
to our text `0123456789`, but specifically omit the transformation performed
by `f` (which would turn `0123456789` into `012315789`). We can do so by
choosing a cloaking character—`0` in this example—and one or more signal
characters that will pass unmodified through `g`. Assuming we cloak `456` as
`01`, we first escape `0123456789` to `111223456789` so that all `0`s are
removed. Then, we symbolize all occurrances of `456` as `01`, leading to
`11122301789`. This string may be fed to `g` and will pass through `f`
untouched. We can then reverse our steps: `11122301789` ... `111223456789` ...
`01223456789` ... `0123456789`—which is indeed the string we're started with.
Of course, this could not have worked if `g` had somehow transformed any of
our cloaking devices; therefore, it is important to choose codepoints that are
certain to be transparent to the intended text transformation.

In case more primary escapement characters are needed, the chain may be
expanded to include more replacement steps. In particular, it is interesting
to use exactly two primary escapements; that way, we can define cloaked
sequences of arbitrary lengths, using the two escapements—`0` and `1` in this
example—as start and stop brackets:

         0123456789
2 -> 24: 01243456789
1 -> 23: 023243456789
0 -> 22: 2223243456789

Using more than two primary escapements is possible, but less interesting:

         0123456789
3 -> 36: 01236456789
2 -> 35: 013536456789
1 -> 34: 0343536456789
0 -> 33: 33343536456789


###

#-----------------------------------------------------------------------------------------------------------
### from https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions ###
escre = ( text ) -> text.replace /[.*+?^${}()|[\]\\]/g, "\\$&"

# #-----------------------------------------------------------------------------------------------------------
# ### `mc`: 'meta character' ###
metaesc_mc_4              = 'D'
metaesc_mc_3              = 'C'
metaesc_mc_2              = 'B'
metaesc_mc_stop           = ';'
metaesc_mc_start          = '%'

# #-----------------------------------------------------------------------------------------------------------
# ### `mc`: 'meta character' ###
# metaesc_mc_4              = '\x14'
# metaesc_mc_3              = '\x13'
# metaesc_mc_2              = '\x12'
# metaesc_mc_stop           = '\x11'
# metaesc_mc_start          = '\x10'

#-----------------------------------------------------------------------------------------------------------
### `mcp`: 'meta character pattern' ###
metaesc_mcp_2             = /// #{escre metaesc_mc_2}      ///g
metaesc_mcp_stop          = /// #{escre metaesc_mc_stop}   ///g
metaesc_mcp_start         = /// #{escre metaesc_mc_start}  ///g

#-----------------------------------------------------------------------------------------------------------
### `tsc`: 'target sequence character' ###
metaesc_tsc_2             = "#{metaesc_mc_2}#{metaesc_mc_4}"
metaesc_tsc_stop          = "#{metaesc_mc_2}#{metaesc_mc_3}"
metaesc_tsc_start         = "#{metaesc_mc_2}#{metaesc_mc_2}"

#-----------------------------------------------------------------------------------------------------------
### `tsp`: 'target sequence pattern' ###
metaesc_tsp_2             = /// #{escre metaesc_tsc_2}       ///g
metaesc_tsp_stop          = /// #{escre metaesc_tsc_stop}    ///g
metaesc_tsp_start         = /// #{escre metaesc_tsc_start}   ///g

#-----------------------------------------------------------------------------------------------------------
### backslashes are dealt with in slightly different ways: ###
### `oc`: 'original character' ###
metaesc_oc_backslash      = '\\'
### `op`: 'original pattern' ###
metaesc_oce_backslash     = escre metaesc_oc_backslash
metaesc_mcp_backslash     = ///
  #{escre metaesc_oc_backslash}
  ( (?: [  \ud800-\udbff ] [ \udc00-\udfff ] ) | . ) ///g
metaesc_tsp_backslash     = /// #{metaesc_mc_bs} ( [ 0-9 a-f ]+ ) #{metaesc_mc_stop} ///g
### `rm`: 'remove' ###
metaesc_rm_backslash      = /// #{escre metaesc_oc_backslash} ( . ) ///g

#-----------------------------------------------------------------------------------------------------------
@cloak_escape_chrs = ( text ) =>
  R = text
  R = R.replace metaesc_mcp_2,        metaesc_tsc_2
  R = R.replace metaesc_mcp_stop,     metaesc_tsc_stop
  R = R.replace metaesc_mcp_start,    metaesc_tsc_start
  return R

#-----------------------------------------------------------------------------------------------------------
@uncloak_escape_chrs = ( text ) =>
  R = text
  R = R.replace metaesc_tsp_start,    metaesc_mc_start
  R = R.replace metaesc_tsp_stop,     metaesc_mc_stop
  R = R.replace metaesc_tsp_2,        metaesc_mc_2
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
# text = "% ; 2 3 \\ \\\\ \\𠄨"
text = "% ; A B C D E"
# text = "<<"
# text = "x"
# whisper rpr cloaked_text
DIFF = require 'coffeenode-diff'
cloaked_text = text
log '(1) -', CND.rainbow ( text )
log '(2) -', CND.rainbow ( cloaked_text   = @cloak_escape_chrs         cloaked_text )
# log '(3) -', CND.rainbow ( cloaked_text   = @cloak_backslashed_chrs    cloaked_text )
uncloaked_text = cloaked_text
# log '(4) -', CND.rainbow ( uncloaked_text = @uncloak_backslashed_chrs  uncloaked_text )
log '(5) -', CND.rainbow ( uncloaked_text = @uncloak_escape_chrs       uncloaked_text )
# log '(7) -', CND.rainbow '©79011', @remove_backslashes               uncloaked_text
if uncloaked_text isnt text
  log DIFF.colorize text, uncloaked_text

log CND.steel '########################################################################'
