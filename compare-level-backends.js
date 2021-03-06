// Generated by CoffeeScript 1.9.1
(function() {
  var CND, alert, badge, debug, dump, echo, help, info, later, level_down_implementations, log, njs_path, rpr, step, suspend, try_proxy, urge, warn, whisper;

  njs_path = require('path');

  CND = require('cnd');

  rpr = CND.rpr.bind(CND);

  badge = 'SCRATCH/scratch';

  log = CND.get_logger('plain', badge);

  info = CND.get_logger('info', badge);

  alert = CND.get_logger('alert', badge);

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  urge = CND.get_logger('urge', badge);

  whisper = CND.get_logger('whisper', badge);

  help = CND.get_logger('help', badge);

  echo = CND.echo.bind(CND);

  suspend = require('coffeenode-suspend');

  step = suspend.step;

  later = suspend.immediately;

  CND.shim();

  dump = function(db, handler) {
    var D, input;
    D = require('pipedreams');
    input = db.createReadStream();
    return input.pipe(D.$show()).pipe(D.$on_end(function() {
      if (handler != null) {
        return handler();
      }
    }));
  };

  level_down_implementations = function(format) {
    return step((function(_this) {
      return function*(resume) {
        var $, $async, D, as_batch, backend, buffer, db, db_route, entry, extension, i, idx, j, jsondown, key, leveldown, levelup, memdown, n, nr, ref, ref1, sqldown, value;
        if (format == null) {
          format = 'level';
        }
        n = 100;
        as_batch = false;
        D = require('pipedreams');
        $ = D.remit.bind(D);
        $async = D.remit_async.bind(D);
        levelup = require('levelup');
        leveldown = require('leveldown');
        memdown = require('memdown');
        sqldown = require('sqldown');
        jsondown = require('jsondown');
        extension = null;
        backend = leveldown;
        switch (format) {
          case 'level':
            null;
            break;
          case 'json':
            backend = jsondown;
            break;
          case 'memory':
            backend = memdown;
            break;
          case 'sqlite':
            backend = sqldown;
            break;
          default:
            throw new Error("unknown DB format " + (rpr(format)));
        }
        db_route = njs_path.join(__dirname, "db." + (extension != null ? extension : format));
        db = levelup(db_route, {
          db: backend
        });
        if (as_batch) {
          buffer = [];
          db.put('helo', 'world');
          for (idx = i = 0, ref = n; 0 <= ref ? i < ref : i > ref; idx = 0 <= ref ? ++i : --i) {
            nr = CND.random_integer(100, 999);
            key = "key-" + nr + "-" + idx;
            value = idx;
            entry = {
              type: 'put',
              key: key,
              value: value
            };
            buffer.push(entry);
          }
          (yield db.batch(buffer, resume));
        } else {
          db.put('helo', 'world');
          for (idx = j = 0, ref1 = n; 0 <= ref1 ? j < ref1 : j > ref1; idx = 0 <= ref1 ? ++j : --j) {
            nr = CND.random_integer(100, 999);
            key = "key-" + nr + "-" + idx;
            value = idx;
            debug('©aK5n8', key, value);
            (yield db.put(key, value, resume));
          }
        }
        (yield dump(db, resume));
        debug('©YQ4oQ', 'end');
        return db.close();
      };
    })(this));
  };

  level_down_implementations('sqlite');

  try_proxy = function() {
    var handler, my_target, name, proxy, ref;
    if (((!global['Reflect']) != null) || (((ref = global['Proxy']) != null ? ref['create'] : void 0) != null)) {
      global['Reflect'] = require('harmony-reflect');
    }
    my_target = {
      foo: 42,
      f: function() {
        return my_target['foo'] * 2;
      }
    };
    handler = {
      get: function(target, key, receiver) {
        var name;
        warn('>>>', 'get', rpr(key));
        urge((function() {
          var results;
          results = [];
          for (name in receiver) {
            results.push(name);
          }
          return results;
        })());
        help(target === receiver);
        return target[key];
      }
    };
    proxy = new Proxy(my_target, handler);
    debug(proxy['foo']);
    debug(proxy['foo'] = 1234);
    debug(proxy.f());
    return debug((function() {
      var results;
      results = [];
      for (name in proxy) {
        results.push(name);
      }
      return results;
    })());
  };

}).call(this);
