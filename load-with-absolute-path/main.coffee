






############################################################################################################
njs_path                  = require 'path'
njs_fs                    = require 'fs'
njs_os                    = require 'os'
njs_cp                    = require 'child_process'
#...........................................................................................................
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'jizura-load-with-absolute-paths'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
suspend                   = require 'coffeenode-suspend'
step                      = suspend.step
#...........................................................................................................
D                         = require 'pipedreams'
$                         = D.remit.bind D
$async                    = D.remit_async.bind D
#...........................................................................................................
ASYNC                     = require 'async'
# #...........................................................................................................
# ƒ                         = CND.format_number.bind CND
# HELPERS                   = require './HELPERS'
# TYPO                      = HELPERS[ 'TYPO' ]
# options                   = require './options'
SEMVER                    = require 'semver'
CS                        = require 'coffee-script'
options_route             = './options.coffee'


#===========================================================================================================
# OPTIONS, CACHE
#-----------------------------------------------------------------------------------------------------------
@options = null

#-----------------------------------------------------------------------------------------------------------
@_eval_coffee_file = ( route ) ->
  rqr_route = require.resolve route
  source    = njs_fs.readFileSync rqr_route, encoding: 'utf-8'
  return CS.eval source, bare: true

#-----------------------------------------------------------------------------------------------------------
@_update_cache = ->
  cache             = @options[ 'cache' ][ '%self' ]
  cache[ 'sysid' ]  = sysid = @_get_sysid()
  unless cache[ sysid ]?
    sys_cache         = {}
    cache[ sysid ]    = sys_cache
  @_save_cache()

#-----------------------------------------------------------------------------------------------------------
@_set_cache = ( key, value, save = yes ) ->
  target          = @options[ 'cache' ][ '%self' ][ @options[ 'cache' ][ '%self' ][ 'sysid' ] ]
  target[ key ]  = value
  @_save_cache() if save?
  return null

#-----------------------------------------------------------------------------------------------------------
@_get_cache = ( key, method, save = yes, handler = null ) ->
  cache   = @options[ 'cache' ][ '%self' ]
  sysid   = cache[ 'sysid' ]
  target  = cache[  sysid  ]
  R       = target[ key ]
  if handler?
    if R is undefined
      method ( error, R ) =>
        return handler error if error?
        @_set_cache key, R, save
        handler null, R
    else
      handler null, R
  else
    if R is undefined
      @_set_cache key, ( R = method() ), save
    return R

#-----------------------------------------------------------------------------------------------------------
@_save_cache = ->
  locator = @options[ 'cache' ][ 'locator' ]
  cache   = @options[ 'cache' ][ '%self' ]
  njs_fs.writeFileSync locator, JSON.stringify cache, null, '  '

#-----------------------------------------------------------------------------------------------------------
@_get_sysid = -> "#{njs_os.hostname()}:#{njs_os.platform()}"

#-----------------------------------------------------------------------------------------------------------
@_compile_options = ->
  ### TAINT code duplication ###
  ### TAINT must insert '../' when used from `lib/` ###
  @options                          = @_eval_coffee_file options_route
  cache_route                       = @options[ 'cache' ][ 'route' ]
  @options[ 'cache' ][ 'locator' ]  = cache_locator = njs_path.resolve __dirname, cache_route
  #.........................................................................................................
  unless njs_fs.existsSync cache_locator
    @options[ 'cache' ][ '%self' ] = {}
    @_save_cache()
  #.........................................................................................................
  @options[ 'cache' ][ '%self' ]    = require cache_locator
  #.........................................................................................................
  fonts_route                       = @options[ 'fonts' ][ 'route' ]
  @options[ 'fonts' ][ 'locator' ]  = fonts_locator = njs_path.resolve __dirname, fonts_route
  #.........................................................................................................
  @options[ 'locators' ] = {}
  for key, route of @options[ 'routes' ]
    @options[ 'locators' ][ key ] = njs_path.resolve __dirname, route
  #.........................................................................................................
  debug '©ed8gv', JSON.stringify @options, null, '  '
  @_update_cache()
#...........................................................................................................
@_compile_options()

#-----------------------------------------------------------------------------------------------------------
@write_font_declarations = ( handler ) ->
  step ( resume ) =>
    fontspec_version  = yield @read_texlive_package_version 'fontspec', resume
    fonts_locator     = @options[ 'fonts' ][ 'locator' ]
    help "writing #{fonts_locator}"
    help "for fontspec@#{fontspec_version}"
    use_new_syntax    = SEMVER.satisfies fontspec_version, '>=2.4.0'
    lines             = []
    #.......................................................................................................
    for { texname, home, filename, } in @options[ 'fonts' ][ 'declarations' ]
      if use_new_syntax
        ### TAINT should properly escape values ###
        lines.push "\\newfontface\\#{texname}{#{filename}}[Path=#{home}/]"
      else
        lines.push "\\newfontface\\#{texname}[Path=#{home}/]{#{filename}}"
    #.......................................................................................................
    njs_fs.writeFile fonts_locator, ( lines.join '\n' ), handler

#-----------------------------------------------------------------------------------------------------------
@read_texlive_package_version = ( package_name, handler ) ->
  key     = "texlive-package-versions/#{package_name}"
  method  = ( done ) => @_read_texlive_package_version package_name, done
  @_get_cache key, method, yes, handler
  return null

#-----------------------------------------------------------------------------------------------------------
@_read_texlive_package_version = ( package_name, handler ) ->
  ### Given a `package_name` and a `handler`, try to retrieve that package's info as reported by the TeX
  Live Manager command line tool (using `tlmgr info ${package_name}`), extract the `cat-version` entry and
  normalize it so it matches the [Semantic Versioning specs](http://semver.org/). If no version is found,
  the `handler` will be called with a `null` value instead of a string; however, if a version *is* found but
  does *not* match the SemVer specs after normalization, the `handler` will be called with an error.

  Normalization steps include removing leading `v`s, trailing letters, and leading zeroes. ###
  leading_zero_pattern  = /^0+(?!$)/
  semver_pattern        = /^([0-9]+)\.([0-9]+)\.?([0-9]*)$/
  @read_texlive_package_info package_name, ( error, package_info ) =>
    return handler error if error?
    #.......................................................................................................
    unless ( version = o_version = package_info[ 'cat-version' ] )?
      warn "unable to detect version for package #{rpr package_name}"
      return handler null, null
      # return handler new Error "unable to detect version for package #{rpr package_name}"
    #.......................................................................................................
    version = version.replace /[^0-9]+$/, ''
    version = version.replace /^v/, ''
    #.......................................................................................................
    unless ( match = version.match semver_pattern )?
      return handler new Error "unable to parse version #{rpr o_version} of package #{rpr name}"
    #.......................................................................................................
    [ _, major, minor, patch, ] = match
    ### thx to http://stackoverflow.com/a/2800839/256361 ###
    major = major.replace leading_zero_pattern, ''
    minor = minor.replace leading_zero_pattern, ''
    patch = patch.replace leading_zero_pattern, ''
    major = if major.length > 0 then major else '0'
    minor = if minor.length > 0 then minor else '0'
    patch = if patch.length > 0 then patch else '0'
    #.......................................................................................................
    handler null, "#{major}.#{minor}.#{patch}"
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@read_texlive_package_info = ( package_name, handler ) ->
  command     = 'tlmgr'
  parameters  = [ 'info', package_name, ]
  input       = D.spawn_and_read_lines command, parameters
  Z           = {}
  pattern     = /^([^:]+):(.*)$/
  #.........................................................................................................
  input
    #.......................................................................................................
    .pipe $ ( line, send ) =>
      return if line.length is 0
      match = line.match pattern
      return send.error new Error "unexpected line: #{rpr line}" unless match?
      [ _, name, value, ] = match
      name                = name.trim()
      value               = value.trim()
      Z[ name ]           = value
    #.......................................................................................................
    .pipe D.$on_end -> handler null, Z
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@write_pdf = ( layout_info, handler ) ->
  #.........................................................................................................
  pdf_command         = njs_path.join __dirname, 'pdf-from-tex.sh' # layout_info[ 'pdf-command'          ]
  tmp_home            = __dirname # layout_info[ 'tmp-home'             ]
  tex_locator         = njs_path.join __dirname, 'load-with-absolute-path.tex' # layout_info[ 'tex-locator'          ]
  aux_locator         = njs_path.join __dirname, 'load-with-absolute-path.aux' # layout_info[ 'aux-locator'          ]
  # pdf_source_locator  = layout_info[ 'pdf-source-locator'   ]
  # pdf_target_locator  = layout_info[ 'pdf-target-locator'   ]
  last_digest         = null
  last_digest         = CND.id_from_route aux_locator if njs_fs.existsSync aux_locator
  digest              = null
  count               = 0
  #.........................................................................................................
  pdf_from_tex = ( next ) =>
    count += 1
    urge "run ##{count} #{pdf_command}"
    whisper "$1: #{tmp_home}"
    whisper "$2: #{tex_locator}"
    CND.spawn pdf_command, [ tmp_home, tex_locator, ], ( error, data ) =>
      error = undefined if error is 0
      if error?
        alert error
        return handler error
      digest = CND.id_from_route aux_locator
      if digest is last_digest
        echo ( CND.grey badge ), CND.lime "done."
        # layout_info[ 'latex-run-count' ] = count
        ### TAINT move pdf to layout_info[ 'source-home' ] ###
        handler null
      else
        last_digest = digest
        next()
  #.........................................................................................................
  ASYNC.forever pdf_from_tex

#-----------------------------------------------------------------------------------------------------------
@test_versions = ->
  tasks = []
  package_names = """
    xcolor
    fontspec
    leading
    pbox
    polyglossia
    bxjscls
    pawpict
    biblatex-juradiss
    lm
    ametsoc
    bibleref-french
    xnewcommand
    semantic
    multiobjective
    shipunov
    splitindex
    chkfloat
    crbox
    svgcolor
    pstools
    sty2dtx
    readarray
    lpic
    lhelp
    newvbtm
    mathpazo
    dot2texi
    lcdftypetools
    pst-fun
    pst-tools
    mex
    flowchart
    hfoldsty
    latex-git-log
    """.split /\s+/
  for name in package_names
    do ( name ) =>
      tasks.push ( done ) => @_read_texlive_package_version name, ( error, version ) =>
        throw error if error?
        if version?
          urge name, ( CND.cyan version ), ( CND.truth SEMVER.valid version ), ( CND.truth SEMVER.satisfies version, '>=2.4.0' )
        done()
  # for name in package_names
  #   do ( name ) =>
  #     tasks.push ( done ) => @read_texlive_package_info name, ( error, package_info ) =>
        # throw error if error?
  #       urge name
  #       help package_info
  #       done()
  ASYNC.parallelLimit tasks, 10, -> help "ok"
  # ASYNC.series tasks, -> help "ok"

#-----------------------------------------------------------------------------------------------------------
@main = ->
  settings_tex_route = njs_path.join __dirname, 'mkts-settings.tex'
  settings_tex = """
  \\def\\foobar{example for a TeX-def macro}
  \\newcommand{\\mktsPathsMktsHome}{/Volumes/Storage/io/jizura/tex-inputs}
  \\newcommand{\\mktsPathsFontsHome}{/Volumes/Storage/io/jizura-fonts/fonts}
  """
  njs_fs.writeFileSync settings_tex_route, settings_tex
  @write_pdf null, ( error ) =>
    throw error if error?
    help "ok"



############################################################################################################
unless module.parent?
  # help @_get_sysid()
  # @test_versions()
  # debug '©q9kwu', cached_settings = @_get_cached_settings()
  # help @_eval_coffee_file options_route
  # debug '©DWBBg', @options[ 'cache' ][ '%self' ][ @options[ 'cache' ][ '%self' ][ 'sysid' ] ]
  # @_read_texlive_package_version 'fontspec', ( error, version ) =>
  #   throw error if error?
  #   if version?
  #     @options[ 'cache' ][ '%self' ][ @options[ 'cache' ][ '%self' ][ 'sysid' ] ]

  # @_get_cache 'foobar', ( -> 42 )
  step ( resume ) =>
    version = yield @read_texlive_package_version 'fontspec', resume
    # help "fontspec@#{version}"
    yield @write_font_declarations resume
    @main()
    # help "ok"









