


############################################################################################################
# njs_util                  = require 'util'
# njs_path                  = require 'path'
# njs_fs                    = require 'fs'
#...........................................................................................................
CND                       = require 'CND'
rpr                       = CND.rpr.bind CND
badge                     = 'BITSNPIECES/test'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
praise                    = CND.get_logger 'praise',    badge
echo                      = CND.echo.bind CND

IntervalSkipList = require 'interval-skip-list'

# debug '©9wQ4t', slist.insert('a', 2, 7)
# debug '©Gc2fu', slist.insert('b', 1, 5)
# debug '©InUiR', slist.insert('c', 8, 8)
# debug '©zeUj2', slist.findContaining(1) # => ['b']
# debug '©0PHYP', slist.findContaining(2) # => ['b', 'a']
# debug '©j1gsq', slist.findContaining(8) # => ['c']
# debug '©RDX6c', slist.remove('b')
# debug '©Qlanx', slist.findContaining(2) # => ['a']
# # debug '©aki0P', slist

test = ->
  slist = new IntervalSkipList()
  intervals = [
    [ 17, 19, 'A', ]
    [  5,  8, 'B', ]
    [ 21, 24, 'C', ]
    [  4,  8, 'D', ]
    [ 15, 18, 'E', ]
    [  7, 10, 'F', ]
    [ 16, 22, 'G', ]
    ]
  for interval in intervals
    [ lo, hi, label, ] = interval
    slist.insert label, lo, hi
  help slist.findContaining [ 21 .. 24 ]...
  help slist.findIntersecting [ 21 .. 24 ]...
  help slist.findIntersecting [ 8 .. 9 ]...
  # debug rpr find tree, [ 8, 9, ] # 'B,D,F'
  # debug rpr find tree, [  5,  8, ]
  # debug rpr find tree, [ 21, 24, ]
  # debug rpr find tree, [  4,  8, ]

test()



