

### Hint: do not use `require` statements in this file unless they refer to built in modules. ###


module.exports = options =

  #.........................................................................................................
  defs:
    foobar:   "this variable has been set in `options`"

  #.........................................................................................................
  newcommands:
    ### TAINT use relative routes ###
    mktsPathsMktsHome:    '/Volumes/Storage/io/jizura/tex-inputs'
    mktsPathsFontsHome:   '/Volumes/Storage/io/jizura-fonts/fonts'

  #.........................................................................................................
  routes:
    settings:       './.mkts-settings.sty'

  #.........................................................................................................
  fonts:
    # route:      './.mkts-fonts.sty'
    declarations: [
        texname:    'mktsFontsDejavuserifregular'
        home:       '\\mktsPathsFontsHome'
        filename:   'DejaVuSerif.ttf'
      ,
        texname:    'mktsFontsUbunturegular'
        home:       '\\mktsPathsFontsHome'
        filename:   'Ubuntu-R.ttf'
      ,
        texname:    'mktsFontsSunexta'
        home:       '\\mktsPathsFontsHome'
        filename:   'sun-exta.ttf'
      ]

  #.........................................................................................................
  cache:
    # route:          './tmp/.cache.json'
    route:          './.cache.json'



