




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
esc_re = ( text ) -> text.replace /[.*+?^${}()|[\]\\]/g, "\\$&"

#-----------------------------------------------------------------------------------------------------------
@new = ( cloaked_chrs ) ->
  unless cloaked_chrs?
    cloaked_chrs = [ '\x10', '\x11', '\x12', '\x13', '\x14', ]
  else if CND.isa_text cloaked_chrs
    cloaked_chrs = Array.from cloaked_chrs
  else unless CND.isa_list cloaked_chrs
    throw new Error "expected a text or a list, got a #{CND.type_of cloaked_chrs}"
  switch chr_count = cloaked_chrs.length
    when 5
      # #---------------------------------------------------------------------------------------------------
      # # ### `mc`: 'meta character' ###
      # mc_4              = 'D'
      # mc_3              = 'C'
      # mc_2              = 'B'
      # mc_stop           = ';'
      # mc_start          = '%'
      #-----------------------------------------------------------------------------------------------------------
      ### `mc`: 'meta character' ###
      mc_4              = cloaked_chrs[ 4 ]
      mc_3              = cloaked_chrs[ 3 ]
      mc_2              = cloaked_chrs[ 2 ]
      mc_stop           = cloaked_chrs[ 1 ]
      mc_start          = cloaked_chrs[ 0 ]

      #---------------------------------------------------------------------------------------------------
      ### `mcp`: 'meta character pattern' ###
      mcp_2             = /// #{esc_re mc_2}      ///g
      mcp_stop          = /// #{esc_re mc_stop}   ///g
      mcp_start         = /// #{esc_re mc_start}  ///g

      #---------------------------------------------------------------------------------------------------
      ### `tsc`: 'target sequence character' ###
      tsc_2             = "#{mc_2}#{mc_4}"
      tsc_stop          = "#{mc_2}#{mc_3}"
      tsc_start         = "#{mc_2}#{mc_2}"

      #---------------------------------------------------------------------------------------------------
      ### `tsp`: 'target sequence pattern' ###
      tsp_2             = /// #{esc_re tsc_2}       ///g
      tsp_stop          = /// #{esc_re tsc_stop}    ///g
      tsp_start         = /// #{esc_re tsc_start}   ///g

      #---------------------------------------------------------------------------------------------------
      cloak = ( text ) =>
        R = text
        R = R.replace mcp_2,        tsc_2
        R = R.replace mcp_stop,     tsc_stop
        R = R.replace mcp_start,    tsc_start
        return R

      #---------------------------------------------------------------------------------------------------
      uncloak = ( text ) =>
        R = text
        R = R.replace tsp_start,    mc_start
        R = R.replace tsp_stop,     mc_stop
        R = R.replace tsp_2,        mc_2
        return R
    else
      throw new Error "expected 5 characters, got #{chr_count}"
  return { cloak, uncloak, }

# #-----------------------------------------------------------------------------------------------------------
# ### backslashes are dealt with in slightly different ways: ###
# ### `oc`: 'original character' ###
# @_oc_backslash      = '\\'
# ### `op`: 'original pattern' ###
# @_oce_backslash     = esc_re @_oc_backslash
# @_mcp_backslash     = ///
#   #{esc_re @_oc_backslash}
#   ( (?: [  \ud800-\udbff ] [ \udc00-\udfff ] ) | . ) ///g
# @_tsp_backslash     = /// #{@_mc_bs} ( [ 0-9 a-f ]+ ) #{@_mc_stop} ///g
# ### `rm`: 'remove' ###
# @_rm_backslash      = /// #{esc_re @_oc_backslash} ( . ) ///g

# #-----------------------------------------------------------------------------------------------------------
# @cloak_backslashed_chrs = ( text ) =>
#   R = text
#   R = R.replace @_mcp_backslash, ( _, $1 ) ->
#     cid = ( $1.codePointAt 0 ).toString 16
#     return "#{@_mc_bs}#{cid}#{@_mc_stop}"
#   return R

# #-----------------------------------------------------------------------------------------------------------
# @uncloak_backslashed_chrs = ( text ) =>
#   R = text
#   R = R.replace @_tsp_backslash, ( _, $1 ) ->
#     chr = String.fromCodePoint parseInt $1, 16
#     return "#{@_oc_backslash}#{chr}"
#   return R

# #-----------------------------------------------------------------------------------------------------------
# @remove_backslashes = ( text ) =>
#   return text.replace @_rm_backslash, '$1'

CLOAK = @
text = """
  % & ! ;
  some <<unlicensed>> stuff here. \\𠄨 &%!%A&123;
  some more \\\\<<unlicensed\\\\>> stuff here.
  some \\<<licensed\\>> stuff here, and <\\<
  The <<<\\LaTeX{}>>> Logo: `<<<\\LaTeX{}>>>`
  """
# debug '©94643', @_mcp_backslash
# text = "% ; 2 3 \\ \\\\ \\𠄨"
text = "% ; A B C D E"
# text = "<<"
# text = "x"
# whisper rpr cloaked_text
DIFF = require 'coffeenode-diff'
{ cloak, uncloak, } = CLOAK.new 'ABCDE'
cloaked_text = text
log '(1) -', CND.rainbow ( text )
log '(2) -', CND.rainbow ( cloaked_text   = cloak cloaked_text )
# log '(3) -', CND.rainbow ( cloaked_text   = @cloak_backslashed_chrs    cloaked_text )
uncloaked_text = cloaked_text
# log '(4) -', CND.rainbow ( uncloaked_text = @uncloak_backslashed_chrs  uncloaked_text )
log '(5) -', CND.rainbow ( uncloaked_text = uncloak uncloaked_text )
# log '(7) -', CND.rainbow '©79011', @remove_backslashes               uncloaked_text
if uncloaked_text isnt text
  log DIFF.colorize text, uncloaked_text

log CND.steel '########################################################################'
