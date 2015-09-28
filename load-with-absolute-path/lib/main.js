(function() {
  var $, $async, ASYNC, CACHE, CND, CS, D, OPTIONS, SEMVER, alert, badge, debug, echo, help, info, log, njs_cp, njs_fs, njs_os, njs_path, options_route, ref, rpr, step, suspend, urge, warn, whisper;

  njs_path = require('path');

  njs_fs = require('fs');

  njs_os = require('os');

  njs_cp = require('child_process');

  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'jizura-load-with-absolute-paths';

  log = CND.get_logger('plain', badge);

  info = CND.get_logger('info', badge);

  whisper = CND.get_logger('whisper', badge);

  alert = CND.get_logger('alert', badge);

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  echo = CND.echo.bind(CND);

  suspend = require('coffeenode-suspend');

  step = suspend.step;

  D = require('pipedreams');

  $ = D.remit.bind(D);

  $async = D.remit_async.bind(D);

  ASYNC = require('async');

  SEMVER = require('semver');

  CS = require('coffee-script');

  options_route = '../options.coffee';

  ref = require('./OPTIONS'), CACHE = ref.CACHE, OPTIONS = ref.OPTIONS;

  this.compile_options = function() {
    var cache_locator, cache_route, key, options_home, options_locator, ref1, route;
    options_locator = require.resolve(njs_path.resolve(__dirname, options_route));
    debug('©zNzKn', options_locator);
    options_home = njs_path.dirname(options_locator);
    this.options = OPTIONS.from_locator(options_locator);
    this.options['home'] = options_home;
    cache_route = this.options['cache']['route'];
    this.options['cache']['locator'] = cache_locator = njs_path.resolve(options_home, cache_route);
    if (!njs_fs.existsSync(cache_locator)) {
      this.options['cache']['%self'] = {};
      this._save_cache();
    }
    this.options['cache']['%self'] = require(cache_locator);
    this.options['locators'] = {};
    ref1 = this.options['routes'];
    for (key in ref1) {
      route = ref1[key];
      this.options['locators'][key] = njs_path.resolve(options_home, route);
    }
    return CACHE.update(options);
  };

  this.compile_options();

  this.write_mkts_settings = function(handler) {
    return step((function(_this) {
      return function*(resume) {
        var defs, filename, fontspec_version, home, i, len, lines, name, newcommands, ref1, ref2, settings_locator, texname, text, use_new_syntax, value;
        lines = [];
        settings_locator = _this.options['locators']['settings'];
        if (settings_locator == null) {

          /* TAINT or use default value */
          throw new Error("need option locators/settings");
        }
        help("writing " + settings_locator);
        lines.push("");
        lines.push("% " + settings_locator);
        lines.push("% do not edit this file");
        lines.push("% generated from options");
        lines.push("");
        defs = _this.options['defs'];
        lines.push("");
        lines.push("% DEFS");
        if (defs != null) {
          for (name in defs) {
            value = defs[name];
            lines.push("\\def\\" + name + "{" + value + "}");
          }
        }
        newcommands = _this.options['newcommands'];
        lines.push("");
        lines.push("% NEWCOMMANDS");
        if (newcommands != null) {
          for (name in newcommands) {
            value = newcommands[name];
            lines.push("\\newcommand{\\" + name + "}{" + value + "}");
          }
        }
        fontspec_version = (yield _this.read_texlive_package_version('fontspec', resume));
        use_new_syntax = SEMVER.satisfies(fontspec_version, '>=2.4.0');
        lines.push("");
        lines.push("% FONTS");
        lines.push("% assuming fontspec@" + fontspec_version);
        lines.push("\\usepackage{fontspec}");
        ref1 = _this.options['fonts']['declarations'];
        for (i = 0, len = ref1.length; i < len; i++) {
          ref2 = ref1[i], texname = ref2.texname, home = ref2.home, filename = ref2.filename;
          if (use_new_syntax) {

            /* TAINT should properly escape values */
            lines.push("\\newfontface\\" + texname + "{" + filename + "}[Path=" + home + "/]");
          } else {
            lines.push("\\newfontface\\" + texname + "[Path=" + home + "/]{" + filename + "}");
          }
        }
        lines.push("");
        lines.push("");
        text = lines.join('\n');
        whisper(text);
        return njs_fs.writeFile(settings_locator, text, handler);
      };
    })(this));
  };

  this.read_texlive_package_version = function(package_name, handler) {
    var key, method;
    key = "texlive-package-versions/" + package_name;
    method = (function(_this) {
      return function(done) {
        return _this._read_texlive_package_version(package_name, done);
      };
    })(this);
    CACHE.get(this.options, key, method, true, handler);
    return null;
  };

  this._read_texlive_package_version = function(package_name, handler) {

    /* Given a `package_name` and a `handler`, try to retrieve that package's info as reported by the TeX
    Live Manager command line tool (using `tlmgr info ${package_name}`), extract the `cat-version` entry and
    normalize it so it matches the [Semantic Versioning specs](http://semver.org/). If no version is found,
    the `handler` will be called with a `null` value instead of a string; however, if a version *is* found but
    does *not* match the SemVer specs after normalization, the `handler` will be called with an error.
    
    Normalization steps include removing leading `v`s, trailing letters, and leading zeroes.
     */
    var leading_zero_pattern, semver_pattern;
    leading_zero_pattern = /^0+(?!$)/;
    semver_pattern = /^([0-9]+)\.([0-9]+)\.?([0-9]*)$/;
    this.read_texlive_package_info(package_name, (function(_this) {
      return function(error, package_info) {
        var _, major, match, minor, o_version, patch, version;
        if (error != null) {
          return handler(error);
        }
        if ((version = o_version = package_info['cat-version']) == null) {
          warn("unable to detect version for package " + (rpr(package_name)));
          return handler(null, null);
        }
        version = version.replace(/[^0-9]+$/, '');
        version = version.replace(/^v/, '');
        if ((match = version.match(semver_pattern)) == null) {
          return handler(new Error("unable to parse version " + (rpr(o_version)) + " of package " + (rpr(name))));
        }
        _ = match[0], major = match[1], minor = match[2], patch = match[3];

        /* thx to http://stackoverflow.com/a/2800839/256361 */
        major = major.replace(leading_zero_pattern, '');
        minor = minor.replace(leading_zero_pattern, '');
        patch = patch.replace(leading_zero_pattern, '');
        major = major.length > 0 ? major : '0';
        minor = minor.length > 0 ? minor : '0';
        patch = patch.length > 0 ? patch : '0';
        return handler(null, major + "." + minor + "." + patch);
      };
    })(this));
    return null;
  };

  this.read_texlive_package_info = function(package_name, handler) {
    var Z, command, input, parameters, pattern;
    command = 'tlmgr';
    parameters = ['info', package_name];
    input = D.spawn_and_read_lines(command, parameters);
    Z = {};
    pattern = /^([^:]+):(.*)$/;
    input.pipe($((function(_this) {
      return function(line, send) {
        var _, match, name, value;
        if (line.length === 0) {
          return;
        }
        match = line.match(pattern);
        if (match == null) {
          return send.error(new Error("unexpected line: " + (rpr(line))));
        }
        _ = match[0], name = match[1], value = match[2];
        name = name.trim();
        value = value.trim();
        return Z[name] = value;
      };
    })(this))).pipe(D.$on_end(function() {
      return handler(null, Z);
    }));
    return null;
  };

  this.write_pdf = function(layout_info, handler) {
    var aux_locator, count, digest, last_digest, options_home, pdf_command, pdf_from_tex, tex_locator, tmp_home;
    options_home = this.options['home'];
    pdf_command = njs_path.join(options_home, 'bin/pdf-from-tex.sh');
    tmp_home = options_home;
    tex_locator = njs_path.join(options_home, 'load-with-absolute-path.tex');
    aux_locator = njs_path.join(options_home, 'load-with-absolute-path.aux');
    last_digest = null;
    if (njs_fs.existsSync(aux_locator)) {
      last_digest = CND.id_from_route(aux_locator);
    }
    digest = null;
    count = 0;
    pdf_from_tex = (function(_this) {
      return function(next) {
        count += 1;
        urge("run #" + count + " " + pdf_command);
        whisper("$1: " + tmp_home);
        whisper("$2: " + tex_locator);
        return CND.spawn(pdf_command, [tmp_home, tex_locator], function(error, data) {
          if (error === 0) {
            error = void 0;
          }
          if (error != null) {
            alert(error);
            return handler(error);
          }
          digest = CND.id_from_route(aux_locator);
          if (digest === last_digest) {
            echo(CND.grey(badge), CND.lime("done."));

            /* TAINT move pdf to layout_info[ 'source-home' ] */
            return handler(null);
          } else {
            last_digest = digest;
            return next();
          }
        });
      };
    })(this);
    return ASYNC.forever(pdf_from_tex);
  };

  this.test_versions = function() {
    var fn, i, len, name, package_names, tasks;
    tasks = [];
    package_names = "xcolor\nfontspec\nleading\npbox\npolyglossia\nbxjscls\npawpict\nbiblatex-juradiss\nlm\nametsoc\nbibleref-french\nxnewcommand\nsemantic\nmultiobjective\nshipunov\nsplitindex\nchkfloat\ncrbox\nsvgcolor\npstools\nsty2dtx\nreadarray\nlpic\nlhelp\nnewvbtm\nmathpazo\ndot2texi\nlcdftypetools\npst-fun\npst-tools\nmex\nflowchart\nhfoldsty\nlatex-git-log".split(/\s+/);
    fn = (function(_this) {
      return function(name) {
        return tasks.push(function(done) {
          return _this._read_texlive_package_version(name, function(error, version) {
            if (error != null) {
              throw error;
            }
            if (version != null) {
              urge(name, CND.cyan(version), CND.truth(SEMVER.valid(version)), CND.truth(SEMVER.satisfies(version, '>=2.4.0')));
            }
            return done();
          });
        });
      };
    })(this);
    for (i = 0, len = package_names.length; i < len; i++) {
      name = package_names[i];
      fn(name);
    }
    return ASYNC.parallelLimit(tasks, 10, function() {
      return help("ok");
    });
  };

  this.main = function() {
    return this.write_pdf(null, (function(_this) {
      return function(error) {
        if (error != null) {
          throw error;
        }
        return help("ok");
      };
    })(this));
  };

  if (module.parent == null) {
    step((function(_this) {
      return function*(resume) {
        var version;
        version = (yield _this.read_texlive_package_version('fontspec', resume));
        (yield _this.write_mkts_settings(resume));
        return _this.main();
      };
    })(this));
  }

}).call(this);

//# sourceMappingURL=../sourcemaps/main.js.map