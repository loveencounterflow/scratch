

### Hint: do not use `require` statements in this file unless they refer to built in modules. ###

module.exports = options =
  fonts:
    route:      './.mkts-fonts.tex'
    declarations: [
        texname:    'mktsFontsDejavuserifregular'
        home:       'mktsPathsFontsHome'
        filename:   'DejaVuSerif.ttf'
      ,
        texname:    'mktsFontsUbunturegular'
        home:       'mktsPathsFontsHome'
        filename:   'Ubuntu-R.ttf'
      ,
        texname:    'mktsFontsSunexta'
        home:       'mktsPathsFontsHome'
        filename:   'sun-exta.ttf'
      ]
  #.........................................................................................................
  cache:
    # route:          './tmp/.cache.json'
    route:          './.cache.json'



