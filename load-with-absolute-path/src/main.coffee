






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
options_route             = '../options.coffee'
{ CACHE, OPTIONS, }       = require './OPTIONS'


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@compile_options = ->
  ### TAINT must insert '../' when used from `lib/` ###
  options_locator                   = require.resolve njs_path.resolve __dirname, options_route
  debug '©zNzKn', options_locator
  options_home                      = njs_path.dirname options_locator
  @options                          = OPTIONS.from_locator options_locator
  @options[ 'home' ]                = options_home
  cache_route                       = @options[ 'cache' ][ 'route' ]
  @options[ 'cache' ][ 'locator' ]  = cache_locator = njs_path.resolve options_home, cache_route
  #.........................................................................................................
  unless njs_fs.existsSync cache_locator
    @options[ 'cache' ][ '%self' ] = {}
    @_save_cache()
  #.........................................................................................................
  @options[ 'cache' ][ '%self' ]    = require cache_locator
  #.........................................................................................................
  @options[ 'locators' ] = {}
  for key, route of @options[ 'routes' ]
    @options[ 'locators' ][ key ] = njs_path.resolve options_home, route
  #.........................................................................................................
  debug '©ed8gv', JSON.stringify @options, null, '  '
  CACHE.update options
#...........................................................................................................
@compile_options()

#-----------------------------------------------------------------------------------------------------------
@write_mkts_settings = ( handler ) ->
  step ( resume ) =>
    lines             = []
    settings_locator  = @options[ 'locators' ][ 'settings' ]
    #.......................................................................................................
    unless settings_locator?
      ### TAINT or use default value ###
      throw new Error "need option locators/settings"
    help "writing #{settings_locator}"
    #-------------------------------------------------------------------------------------------------------
    lines.push ""
    lines.push "% #{settings_locator}"
    lines.push "% do not edit this file"
    lines.push "% generated from options"
    lines.push ""
    #-------------------------------------------------------------------------------------------------------
    # DEFS
    #.......................................................................................................
    defs = @options[ 'defs' ]
    lines.push ""
    lines.push "% DEFS"
    if defs?
      lines.push "\\def\\#{name}{#{value}}" for name, value of defs
    #-------------------------------------------------------------------------------------------------------
    # NEWCOMMANDS
    #.......................................................................................................
    newcommands = @options[ 'newcommands' ]
    lines.push ""
    lines.push "% NEWCOMMANDS"
    if newcommands?
      lines.push "\\newcommand{\\#{name}}{#{value}}" for name, value of newcommands
    #-------------------------------------------------------------------------------------------------------
    # FONTS
    #.......................................................................................................
    fontspec_version  = yield @read_texlive_package_version 'fontspec', resume
    use_new_syntax    = SEMVER.satisfies fontspec_version, '>=2.4.0'
    #.......................................................................................................
    lines.push ""
    lines.push "% FONTS"
    lines.push "% assuming fontspec@#{fontspec_version}"
    lines.push "\\usepackage{fontspec}"
    #.......................................................................................................
    for { texname, home, filename, } in @options[ 'fonts' ][ 'declarations' ]
      if use_new_syntax
        ### TAINT should properly escape values ###
        lines.push "\\newfontface\\#{texname}{#{filename}}[Path=#{home}/]"
      else
        lines.push "\\newfontface\\#{texname}[Path=#{home}/]{#{filename}}"
    #-------------------------------------------------------------------------------------------------------
    lines.push ""
    lines.push ""
    #-------------------------------------------------------------------------------------------------------
    text = lines.join '\n'
    whisper text
    njs_fs.writeFile settings_locator, text, handler

#-----------------------------------------------------------------------------------------------------------
@read_texlive_package_version = ( package_name, handler ) ->
  key     = "texlive-package-versions/#{package_name}"
  method  = ( done ) => @_read_texlive_package_version package_name, done
  CACHE.get @options, key, method, yes, handler
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
  options_home        = @options[ 'home' ]
  pdf_command         = njs_path.join options_home, 'pdf-from-tex.sh' # layout_info[ 'pdf-command'          ]
  tmp_home            = options_home # layout_info[ 'tmp-home'             ]
  tex_locator         = njs_path.join options_home, 'load-with-absolute-path.tex' # layout_info[ 'tex-locator'          ]
  aux_locator         = njs_path.join options_home, 'load-with-absolute-path.aux' # layout_info[ 'aux-locator'          ]
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
  @write_pdf null, ( error ) =>
    throw error if error?
    help "ok"



############################################################################################################
unless module.parent?
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
    yield @write_mkts_settings resume
    @main()
    # help "ok"








