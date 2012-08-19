##
## Imports
##
root = exports ? this # hack abych zatim nemusel pouzivat zadny modulovac
qc = root.quickCheck
ex = root.examine

T = ex.T
Tn = ex.Tn


##
## Sample tests of QuickCheck itself
##
testT = (testResult) -> console.assert testResult == true     # succeeded
testF = (testResult) -> console.assert 'values' of testResult # is fail report
testG = (testResult) -> console.assert testResult == false    # gave up

try
  console.log "[START] (all test should pass)"

  # Test basic functions
  testT qc.run ((x,y) -> x != y), qc.arbBool, qc.arbInt
  testT qc.run ((x) -> typeof (x) == "number"), qc.arbInt
  testT qc.run ((x,y) -> x*y == y*x), qc.arbByte, qc.arbByte
  testF qc.run ((x) -> x % 2 == 0), qc.arbByte
  testF qc.run ((x) -> x), qc.arbBool
  testG qc.run ((x) -> {}), qc.arbBool

  testT qc.run ((size) -> qc.arbArrayOf(size,qc.arbBool)().length == size),
    ((size) -> size*size)

  # Test shrinking
  customGen = qc.makeShrinking
    create: (size) -> ("|" for i in [1..size] by 1).join ""
    shrink: (arr) -> if arr.length > 0 then [arr.slice 1] else []

  P = (x,y) -> gen: x, res: y
  sTests = [
    P qc.arbArrayOf(5, customGen), (len,size) -> if size > 0 then 5 else 0
    P qc.arbArray(customGen), (len) -> len*2
    P customGen, (len) -> if len > 0 then 1 else 0
  ]

  for t in sTests
    testT qc.run (size) ->
      generated = t.gen size
      (t.gen.shrink generated).length == t.res generated.length, size
    , qc.arbByte
catch err
  console.log err.message
finally
  console.log "[DONE]"


##
## Examples of using helper functions to create custom generator
##
# qc.frequency([[1,qc.arbSizedDouble], [3,qc.arbSizedInt], [4,qc.arbBool]])(500)
# qc.oneOf([qc.arbSizedDouble, qc.arbSizedInt, qc.arbBool])(300)
# qc.elements([101,220,300])(100)
#
# TODO show some complex generator

##
## Example of Incorrect QuickSort
##
IQS = (arr) ->
  return [] if arr.length == 0
  bigger = []; lower = []
  pivot = arr[0]

  for i in [1..arr.length-1] by 1
    if arr[i] > pivot
      bigger.push arr[i]
    else if arr[i] < pivot  # should be just `else`
      lower.push arr[i]

  (IQS lower).concat [pivot], IQS bigger

sorted = (arr) ->
  for i in [1..arr.length-1] by 1
    return false if arr[i-1] > arr[i]
  true

propWQS = (arr) ->
  newArr = IQS arr
  if arr.length != newArr.length
    @failReason = "Result is shorter"
    return false
  if not sorted newArr
    @failReason = "Array is not sorted"
    return false
  true
  # simple test, not controlling elements of newArr

try
  # console.dump qc.run propWQS, qc.arbArray qc.arbByte
catch err
  console.log err.message.toString()


##
## Examples of tests by examine.test
##
try
  # Helper:
  check = (testObject) ->
    console.assert ex.test testObject

  # Examples:
  check
    name: "Deepeq"
    testedFunction: ex.deepeq
    testCases: [
      Tn [{a:1,c:[1,2,{q:1}], b:2}, {b:2, a:1, c:[1,2,{q:1}]}], "nested structure"
      Tn [null, null], "nulls eq"
      Tn [0, -0]
    ]

  check
    name: "Addition"
    property: (x, y) -> x+y == y+x
    quickCheck: [qc.arbInt, qc.arbInt]
    testCases: [
      T  [1,2]
      T  [0,0]
      Tn [-1,1], "Two opposite ones"
    ]

  check
    name: "Missing property"
    testedFunction: (arr,i, res) -> arr[i] == res
    testCases: [
      T [{a: 1}, 'a', 1]
      T [{}, 'b', undefined]
    ]

  # Testing user code
  check
    name: "User code"
    code: "function f(a) {return a*2};"
    property: (x) -> @user.f x == x*2
    quickCheck: [qc.arbInt]

  check
    name: "User code with environment"
    code: """
      function f(x) {
        return 2*g(x);
      }
      """
    environment:
      g: (x) -> 2*x
    property: (x) -> 2*2*x == @user.f x
    quickCheck: [qc.arbInt]

  # Failing tests:
  check
    name: "Missing variable (should fail)"
    property: (x,y) -> x+y == z+x
    quickCheck: [qc.arbInt, qc.arbInt]

  check
    name: "Eval syntax error (should fail)"
    property: -> eval "1 ++ 2"
    testCases: [
      T [], 3
    ]

catch err
  console.log "Outer catch:"
  console.log "============"
  console.log err.message
finally
  console.log "[DONE]"


# TODO
# - piskoviste
# - syntax check
# - check existence funkci --> viz Strict mode and/or try/catch/finally
# - zbytek komentaru

# Diskuze nad pouzivanim [0..length-1], vs [0...length] a pouzivani "by 1"
