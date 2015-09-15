// Generated by CoffeeScript 1.9.1
(function() {
  var $, $async, CND, D, Htmlparser, Markdown_parser, alert, badge, debug, help, info, input, log, new_inline_plugin, njs_fs, njs_path, njs_util, rpr, source_md, source_route, step, suspend, urge, warn, whisper;

  njs_util = require('util');

  njs_path = require('path');

  njs_fs = require('fs');

  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'scratch';

  log = CND.get_logger('plain', badge);

  info = CND.get_logger('info', badge);

  whisper = CND.get_logger('whisper', badge);

  alert = CND.get_logger('alert', badge);

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  suspend = require('coffeenode-suspend');

  step = suspend.step;

  suspend = require('coffeenode-suspend');

  step = suspend.step;

  D = require('pipedreams');

  $ = D.remit.bind(D);

  $async = D.remit_async.bind(D);

  Markdown_parser = require('markdown-it');

  Htmlparser = (require('htmlparser2')).Parser;

  new_inline_plugin = require('markdown-it-regexp');

  this._new_mdx_parser = function() {

    /* https://markdown-it.github.io/markdown-it/#MarkdownIt.new */
    var R, feature_set, settings;
    feature_set = 'zero';
    settings = {
      html: true,
      xhtmlOut: false,
      breaks: false,
      langPrefix: 'language-',
      linkify: true,
      typographer: true,
      quotes: '“”‘’'
    };
    R = new Markdown_parser(feature_set, settings);
    R.enable('text').enable('escape').enable('backticks').enable('strikethrough').enable('emphasis').enable('link').enable('image').enable('autolink').enable('html_inline').enable('entity').enable('fence').enable('blockquote').enable('hr').enable('list').enable('reference').enable('heading').enable('lheading').enable('html_block').enable('table').enable('paragraph').enable('normalize').enable('block').enable('inline').enable('linkify').enable('replacements').enable('smartquotes');
    R.use(require('markdown-it-footnote'));
    return R;
  };

  this._new_html_parser = function(stream) {
    var handlers, settings;
    settings = {
      xmlMode: false,
      decodeEntities: false,
      lowerCaseTags: false,
      lowerCaseAttributeNames: false,
      recognizeCDATA: true,
      recognizeSelfClosing: true
    };
    handlers = {
      onopentag: function(name, attributes) {
        return stream.write(['open-tag', name, attributes]);
      },
      ontext: function(text) {
        return stream.write(['text', text]);
      },
      onclosetag: function(name) {
        return stream.write(['close-tag', name]);
      },
      onerror: function(error) {
        return stream.error(error);
      },
      oncomment: function(text) {
        return stream.write(['comment', text]);
      },
      onend: function() {
        stream.write(['end']);
        return stream.end();
      }
    };
    return new Htmlparser(handlers, settings);
  };

  this.create_html_readstream_from_mdx_text = function(text, settings) {
    var R;
    if (settings != null) {
      throw new Error("settings currently unsupported");
    }
    R = D.create_throughstream();
    R.pause();
    setImmediate((function(_this) {
      return function() {
        var environment, html, i, j, len, len1, mdx_parser, sub_token, sub_tokens, token, tokens;
        mdx_parser = _this._new_mdx_parser();
        html = mdx_parser.render(text);
        help('©YzNQP', html);
        environment = {};
        text = "\na paragraph with *text*\n\nhelo **world**[^1] etc[^1]\n\n[^1]: reference *here*";
        debug('©bg79r', tokens = mdx_parser.parse(text, environment));
        for (i = 0, len = tokens.length; i < len; i++) {
          token = tokens[i];
          help(token['type'], rpr(token['tag']), token['content'], token['meta']);
          if ((sub_tokens = token['children']) != null) {
            for (j = 0, len1 = sub_tokens.length; j < len1; j++) {
              sub_token = sub_tokens[j];
              urge('', sub_token['type'], rpr(sub_token['tag']), sub_token['content'], sub_token['meta']);
            }
          }
        }
        return debug('©tt084', environment);
      };
    })(this));
    return R;
  };

  source_route = njs_path.resolve(__dirname, '../jizura/texts/demo/demo.md');

  source_md = njs_fs.readFileSync(source_route, {
    encoding: 'utf-8'
  });

  debug('©3E4JY', source_md);

  input = this.create_html_readstream_from_mdx_text(source_md);

  input.pipe(D.$show());

  input.resume();

}).call(this);
