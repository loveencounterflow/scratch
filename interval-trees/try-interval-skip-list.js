// Generated by CoffeeScript 1.9.1
(function() {
  var CND, IntervalSkipList, alert, badge, debug, echo, help, info, log, praise, rpr, test, urge, warn, whisper;

  CND = require('CND');

  rpr = CND.rpr.bind(CND);

  badge = 'BITSNPIECES/test';

  log = CND.get_logger('plain', badge);

  info = CND.get_logger('info', badge);

  whisper = CND.get_logger('whisper', badge);

  alert = CND.get_logger('alert', badge);

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  praise = CND.get_logger('praise', badge);

  echo = CND.echo.bind(CND);

  IntervalSkipList = require('interval-skip-list');

  test = function() {
    var hi, i, interval, intervals, label, len, lo, slist;
    slist = new IntervalSkipList();
    intervals = [[17, 19, 'A'], [5, 8, 'B'], [21, 24, 'C'], [4, 8, 'D'], [15, 18, 'E'], [7, 10, 'F'], [16, 22, 'G']];
    for (i = 0, len = intervals.length; i < len; i++) {
      interval = intervals[i];
      lo = interval[0], hi = interval[1], label = interval[2];
      slist.insert(label, lo, hi);
    }
    help(slist.findContaining.apply(slist, [21, 22, 23, 24]));
    help(slist.findIntersecting.apply(slist, [21, 22, 23, 24]));
    return help(slist.findIntersecting.apply(slist, [8, 9]));
  };

  test();

}).call(this);
