




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
#...........................................................................................................
suspend                   = require 'coffeenode-suspend'
step                      = suspend.step
# TEXT                      = require 'coffeenode-text'
# Xregex                    = ( require 'xregexp' )[ 'XRegExp' ]
#...........................................................................................................
suspend                   = require 'coffeenode-suspend'
step                      = suspend.step
#...........................................................................................................
D                         = require 'pipedreams'
$                         = D.remit.bind D
$async                    = D.remit_async.bind D
#...........................................................................................................
Markdown_parser           = require 'markdown-it'
Htmlparser                = ( require 'htmlparser2' ).Parser
new_inline_plugin         = require 'markdown-it-regexp'


#-----------------------------------------------------------------------------------------------------------
@_new_mdx_parser = ->
  #.........................................................................................................
  ### https://markdown-it.github.io/markdown-it/#MarkdownIt.new ###
  # feature_set = 'commonmark'
  feature_set = 'zero'
  #.........................................................................................................
  settings    =
    html:           yes,            # Enable HTML tags in source
    xhtmlOut:       no,             # Use '/' to close single tags (<br />)
    breaks:         no,             # Convert '\n' in paragraphs into <br>
    langPrefix:     'language-',    # CSS language prefix for fenced blocks
    linkify:        yes,            # Autoconvert URL-like text to links
    typographer:    yes,
    quotes:         '“”‘’'
    # quotes:         '""\'\''
    # quotes:         '""`\''
    # quotes:         [ '<<', '>>', '!!!', '???', ]
    # quotes:   ['«\xa0', '\xa0»', '‹\xa0', '\xa0›'] # French
  #.........................................................................................................
  R = new Markdown_parser feature_set, settings
  # R = new Markdown_parser settings
  R
    .enable 'text'
    # .enable 'newline'
    .enable 'escape'
    .enable 'backticks'
    .enable 'strikethrough'
    .enable 'emphasis'
    .enable 'link'
    .enable 'image'
    .enable 'autolink'
    .enable 'html_inline'
    .enable 'entity'
    # .enable 'code'
    .enable 'fence'
    .enable 'blockquote'
    .enable 'hr'
    .enable 'list'
    .enable 'reference'
    .enable 'heading'
    .enable 'lheading'
    .enable 'html_block'
    .enable 'table'
    .enable 'paragraph'
    .enable 'normalize'
    .enable 'block'
    .enable 'inline'
    .enable 'linkify'
    .enable 'replacements'
    .enable 'smartquotes'
  #.......................................................................................................
  R.use require 'markdown-it-footnote'
  # R.use require 'markdown-it-mark'
  # R.use require 'markdown-it-sub'
  # R.use require 'markdown-it-sup'
  # #.......................................................................................................
  # ### sample plugin ###
  # user_pattern  = /@(\w+)/
  # user_handler  = ( match, utils ) ->
  #   url = 'http://example.org/u/' + match[ 1 ]
  #   return '<a href="' + utils.escape(url) + '">' + utils.escape(match[1]) + '</a>'
  # user_plugin = new_md_inline_plugin user_pattern, user_handler
  # R.use user_plugin
  #.......................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@_new_html_parser = ( stream ) ->
  settings =
    xmlMode:                 no   # Indicates whether special tags (<script> and <style>) should get special
                                  # treatment and if "empty" tags (eg. <br>) can have children. If false,
                                  # the content of special tags will be text only.
                                  # For feeds and other XML content (documents that don't consist of HTML),
                                  # set this to true. Default: false.
    decodeEntities:          no   # If set to true, entities within the document will be decoded. Defaults
                                  # to false.
    lowerCaseTags:           no   # If set to true, all tags will be lowercased. If xmlMode is disabled,
                                  # this defaults to true.
    lowerCaseAttributeNames: no   # If set to true, all attribute names will be lowercased. This has
                                  # noticeable impact on speed, so it defaults to false.
    recognizeCDATA:          yes  # If set to true, CDATA sections will be recognized as text even if the
                                  # xmlMode option is not enabled. NOTE: If xmlMode is set to true then
                                  # CDATA sections will always be recognized as text.
    recognizeSelfClosing:    yes  # If set to true, self-closing tags will trigger the onclosetag event even
                                  # if xmlMode is not set to true. NOTE: If xmlMode is set to true then
                                  # self-closing tags will always be recognized.
  #.........................................................................................................
  handlers =
    onopentag:  ( name, attributes )  -> stream.write [ 'open-tag',  name, attributes, ]
    ontext:     ( text )              -> stream.write [ 'text',      text, ]
    onclosetag: ( name )              -> stream.write [ 'close-tag', name, ]
    onerror:    ( error )             -> stream.error error
    oncomment:  ( text )              -> stream.write [ 'comment',   text, ]
    onend:                            -> stream.write [ 'end', ]; stream.end()
    # oncdatastart:            ( P... ) -> debug 'cdatastart           ', P  # 0
    # oncdataend:              ( P... ) -> debug 'cdataend             ', P  # 0
    # onprocessinginstruction: ( P... ) -> debug 'processinginstruction', P  # 2
  #.........................................................................................................
  return new Htmlparser handlers, settings

#-----------------------------------------------------------------------------------------------------------
@create_html_readstream_from_mdx_text = ( text, settings ) ->
  throw new Error "settings currently unsupported" if settings?
  #.........................................................................................................
  R = D.create_throughstream()
  R.pause()
  #.........................................................................................................
  setImmediate =>
    mdx_parser  = @_new_mdx_parser()
    #.......................................................................................................
    html        = mdx_parser.render text
    help '©YzNQP',  html
    environment = {}
    text = """

      a paragraph with *text*

      helo **world**[^1] etc[^1]

      [^1]: reference *here*
      """
    debug '©bg79r', tokens = mdx_parser.parse text, environment
    for token in tokens
      help token[ 'type' ], ( rpr token[ 'tag' ] ), ( token[ 'content' ] ), ( token[ 'meta' ] )
      # debug '©D1alR', ( JSON.stringify token )if token[ 'type' ].startsWith 'footnote'
      if ( sub_tokens = token[ 'children' ] )?
        for sub_token in sub_tokens
          urge '', sub_token[ 'type' ], ( rpr sub_token[ 'tag' ] ), ( sub_token[ 'content' ] ), ( sub_token[ 'meta' ] )
          # debug '©D1alR', ( JSON.stringify sub_token )if sub_token[ 'type' ].startsWith 'footnote'
    debug '©tt084', environment
    # process.exit()
    # html_parser = @_new_html_parser R
    # html_parser.write html
    # html_parser.end()
  #.........................................................................................................
  return R

source_route  = njs_path.resolve __dirname, '../jizura/texts/demo/demo.md'
source_md     = njs_fs.readFileSync source_route, encoding: 'utf-8'
debug '©3E4JY', source_md
input =  @create_html_readstream_from_mdx_text source_md
input
  .pipe D.$show()
input.resume()


