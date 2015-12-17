


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
echo                      = CND.echo.bind CND
rainbow                   = CND.rainbow.bind CND
suspend                   = require 'coffeenode-suspend'
step                      = suspend.step
after                     = suspend.after
eventually                = suspend.eventually
immediately               = suspend.immediately
every                     = suspend.every
inquirer                  = require './Inquirer.js'

inquirer.prompt [ {
  type: 'checkbox'
  message: 'Select toppings'
  name: 'toppings'
  choices: [
    new inquirer.Separator "The usual:"
    { name: 'Peperonni' }
    {
      name: 'Cheese'
      checked: true
    }
    { name: 'Mushroom' }
    new (inquirer.Separator)('The extras:')
    { name: 'Pineapple' }
    { name: 'Bacon' }
    {
      name: 'Olives'
      disabled: 'out of stock'
    }
    { name: 'Extra cheese' }
  ]
  validate: (answer) ->
    if answer.length < 1
      return 'You must choose at least one topping.'
    true

} ], (answers) ->
  console.log JSON.stringify(answers, null, '  ')
  return
