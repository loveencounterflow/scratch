





############################################################################################################
# njs_util                  = require 'util'
# njs_path                  = require 'path'
# njs_fs                    = require 'fs'
#...........................................................................................................
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'try-russ-cox-re2'
log                       = CND.get_logger 'plain',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
ƒ                         = CND.format_number.bind CND
#...........................................................................................................
# suspend                   = require 'coffeenode-suspend'
# step                      = suspend.step
Regex                     = require 're2'
# TIMER                     = require '/Volumes/Storage/io/coffeenode-timer'


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
times = {}

#-----------------------------------------------------------------------------------------------------------
start = ( name ) ->
  whisper "start #{name}"
  times[ name ] = process.hrtime()
  return null

#-----------------------------------------------------------------------------------------------------------
stop = ( name ) ->
  dt = process.hrtime times[ name ]
  times[ name ] = dt[ 0 ] + dt[ 1 ] / 1e9
  return null

#-----------------------------------------------------------------------------------------------------------
report = ( n, min_name ) ->
  columnify_settings =
    config:
      dt:     { align: 'right' }
      rel:    { align: 'right' }
      max:    { align: 'right' }
  if min_name?
    min = times[ min_name ]
  else
    min = Math.min ( dt for _, dt of times )...
  max = Math.max ( dt for _, dt of times )...
  debug '©q6yuS', min, max
  data = []
  for name, dt of times
    # nanos = "000000000#{dt[ 1 ]}"
    # nanos = nanos[ nanos.length - 9 .. nanos.length - 1 ]
    # urge "#{dt[ 0 ]}.#{nanos} #{name}"
    entry =
      name:     name
      dt:       ( dt.toFixed 9 )
      rel:      "#{( dt / min ).toFixed 2}"
      max:      "#{( dt / max ).toFixed 2}"
    data.push entry
  urge "time needed to process #{ƒ n} probes (lower is better):"
  help '\n' + CND.columnify data, columnify_settings


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
n = 1e4

#-----------------------------------------------------------------------------------------------------------
@test_1 = ->
  pattern_1 = /(\S*x\S*)/g
  pattern_2 = new Regex pattern_1
  text      = 'foo bar fox xaver'
  # debug '©wvnC0', pattern.match     text
  # debug '©bxW9X', pattern.test      text
  # debug '©aNozp', pattern.exec      text
  # debug '©sjwJL', pattern.search    text
  # debug '©JLubT', pattern.split     text
  # debug '©fq0hZ', pattern.replace   text, '*'
  #.........................................................................................................
  start "match with standard RegExp"
  for _ in [ 1 .. n ]
    text.match pattern_1
  stop "match with standard RegExp"
  #.........................................................................................................
  start "match with Re2"
  for _ in [ 1 .. n ]
    pattern_2.match text
  stop "match with Re2"
  #.........................................................................................................
  report n

#-----------------------------------------------------------------------------------------------------------
@test_2 = ->
  pattern_1 = /(x+x+)+y/g
  pattern_2 = new Regex pattern_1
  text      = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxy'
  #.........................................................................................................
  start "match with standard RegExp"
  t0 = +new Date()
  for _ in [ 1 .. n ]
    text.match pattern_1
  t1 = +new Date()
  stop "match with standard RegExp"
  #.........................................................................................................
  start "match with Re2"
  t0 = +new Date()
  for _ in [ 1 .. n ]
    pattern_2.match text
  t1 = +new Date()
  stop "match with Re2"
  #.........................................................................................................
  report n

#-----------------------------------------------------------------------------------------------------------
@test_3 = ->
  pattern_1 = /xxxxxxxxxy/g
  pattern_2 = new Regex pattern_1
  texts     = []
  for _ in [ 1 .. n ]
    text = []
    for __ in [ 0 ... 10000 ]
      text.push if ( Math.random() > 0.5 ) then 'x' else 'y'
    texts.push text.join ''
  #.........................................................................................................
  start "match with standard RegExp"
  t0 = +new Date()
  for text in texts
    text.match pattern_1
  t1 = +new Date()
  stop "match with standard RegExp"
  #.........................................................................................................
  start "match with Re2"
  t0 = +new Date()
  for text in texts
    pattern_2.match text
  t1 = +new Date()
  stop "match with Re2"
  #.........................................................................................................
  report n, "match with Re2"
  report n, "match with standard RegExp"


############################################################################################################
unless module.parent?
  log '----------------------------------------'
  @test_1()
  log '----------------------------------------'
  @test_2()
  log '----------------------------------------'
  @test_3()
  log '----------------------------------------'
  help "ok"
