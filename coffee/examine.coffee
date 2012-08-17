root = exports ? this
qc = root.quickCheck

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

# Testing function, example of usage:
#
# examine.test {
#   name: "Test name"
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
    if 'quickCheck' of settings
      resObj.qcRes = if 'quickCheckArgs' of settings
        qc.runWith settings.quickCheckArgs, settings.property, settings.quickCheck...
      else
        qc.run settings.property, settings.quickCheck...

      if resObj.qcRes == true           && settings.quickCheckExpected == false ||
         resObj.qcRes instanceof Object && settings.quickCheckExpected != false
        resObj.quickCheckFailed = true
        return resObj

    if 'testCases' of settings

      for tc in settings.testCases
        logObj = {}
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

    resObj.reason = switch err.name
      when "RangeError"
        "Chyba mezí (#{err.message})"
      when "ReferenceError"
        "Použita neexistující proměnná nebo funkce" # TODO zkusit presah pole
      when "SyntaxError"
        "Syntaktická chyba (#{err.message})"
      when "TypeError"
        "Nesprávné použití hodnoty. Nevoláš funkci na nedefinované proměnné?"
      when "EvalError"
        "Asi syntax error" # TODO
      else
        "Neznámá chyba (#{err.message})"

    return resObj

  true

##
## Exports
##
(exports ? this).examine =
  deepeq: deepeq
  T: T
  Tn: Tn
  test: test
