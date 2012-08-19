root = exports ? this
qc = root.quickCheck

##
## Settings
##
sandboxID = 'sandbox'


# Very simple comparison function. It doesn't care about class names or hidden
# attributes.
deepeq = (a, b) ->
  return a == b unless a instanceof Object && b instanceof Object
  return false if Object.keys(a).length != Object.keys(b).length

  for own prop of a
    if a[prop] instanceof Object && b[prop] instanceof Object
      return false unless deepeq a[prop], b[prop]
    else
      return false unless a[prop] == b[prop]

  true

T = (args, res = undefined, name = "") -> args: args, expected: res, name: name
Tn = (args, name = "") -> args: args, expected: undefined, name: name

#
# Testing function, example of usage:
#
# examine.test {
#   name: "Test name"
#
#   code: "..."                       # users code to load before tests (optional)
#                                     # needs jQuery, use @user.fun(...) for
#                                     # users functions
#   environment:
#     log: console.log                # (optional) adds objects/functions to
#     alert: alert                    # property/testedFunction scope via @user
#     ...                             # (given example gives @user.log and
#                                     @ @user.alert functions)
#
#   property: somePropertyToTest
#   quickCheck: [generators in array] # if ommited dont use QuickCheck
#   quickCheckArgs: args              # if ommited use default
#   quickCheckExpected: true | false  # default true
#
#   testedFunction: someFunction      # if ommited use @property
#   testCases: [
#     T [1,2,3]      # args
#       6            # expected result
#       "Small ..."  # test case name (default "")
#
#     Tn [3,2,1]     # args
#        "Reversed"  # test case name (default "")
#     T or Tn ...
#   ]
# }
# Best use case:
# - use just property with QuickCheck and/or testCases (expecting true/false)
# - use just testedFunction with testCases and expected result always set
#
# Returns just true if test succeeded or object with fail informations

test = (settings) ->
  resObj = testName: settings.name

  try
    if 'code' of settings
      # Users code is sandboxed inside a iframe
      sandboxFrame = $ '<iframe/>', id: sandboxID
      $('body').append sandboxFrame
      user = sandboxFrame.get(0).contentWindow

      if 'environment' of settings
        setEnvironment user, settings.environment

      # Parse users code
      user.eval settings.code

    if 'quickCheck' of settings
      settings.quickCheckArgs = settings.quickCheckArgs ? qc.stdArgs
      settings.quickCheckArgs.user = user

      resObj.qcRes =
        qc.runWith settings.quickCheckArgs, settings.property, settings.quickCheck...

      if resObj.qcRes == true           && settings.quickCheckExpected == false ||
         resObj.qcRes instanceof Object && settings.quickCheckExpected != false
        resObj.quickCheckFailed = true
        return resObj

    if 'testCases' of settings

      for tc in settings.testCases
        logObj = user: user

        res = (settings.testedFunction ? settings.property).apply logObj, tc.args

        if not deepeq res, tc.expected ? true
          resObj.testsRes  = false
          resObj.testRes   = res
          resObj.epected   = tc.expected
          resObj.testCases = tc.args
          resObj.name      = tc.name
          resObj.logObj    = logObj
          return resObj

  catch err
    resObj.errorOccurred = true
    resObj.errObj = err
    resObj.reason = czechErrorName err

    return resObj
  finally
    stopExecution sandboxID

  true

czechErrorName = (err) ->
  # TODO lepe okomentovat, tzn rozepsat pripady kdy
  #  - se pouzije nedefinovana promenna
  #  - pristoupi se k neexistujici polozce v poli a neco s ni
  #  - vola se cislo jako funkce (pripadne undefined)
  #  - ...
  switch err.name
    when "RangeError"
      "Chyba mezí (#{err.message})."
    when "ReferenceError"
      "Použita neexistující proměnná nebo funkce." # TODO zkusit presah pole
    when "SyntaxError"
      "Syntaktická chyba (#{err.message})."
    when "TypeError"
      "Nesprávné použití hodnoty. Nevoláš funkci na nedefinované proměnné?"
    # when "EvalError"
    #   "Asi syntax error." # TODO podaří se vyvolat?
    else
      "Neznámá chyba (#{err.toString()})"

setEnvironment = (to, from) ->
  for i of from
    to[i] = ->
      throw Error 'Code stopped from outside.' if to.__STOP == true
      from[i] arguments...

  to.__STOP = -> to.__STOP = true

stopExecution = (iframeID = sandboxID) ->
  $("#"+iframeID)
    .detach().end()
    .get(0)?.contentWindow?.__STOP()


##
## Exports
##
(exports ? this).examine =
  deepeq: deepeq
  T: T
  Tn: Tn
  test: test
  sandboxID: sandboxID
  stopExecution: stopExecution
