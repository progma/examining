root = exports ? this # hack abych zatim nemusel pouzivat zadny modulovac
qc = root.quickCheck

##
## Examples of using helper functions to create custom generator
##
# console.log qc.frequency([[1,qc.arbSizedDouble], [3,qc.arbSizedInt], [4,qc.arbBool]])(500)
# console.log qc.oneOf([qc.arbSizedDouble, qc.arbSizedInt, qc.arbBool])(300)
# console.log qc.elements([101,220,300])(100)

##
## Incorrect QuickSort example
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
  console.dump qc.run propWQS, qc.arbArray qc.arbByte
catch err
  console.log err.message.toString()

# #################################################### #

##
## Sample tests of QuickCheck itself
##
testT = (testResult) -> console.assert testResult == true     # succeeded
testF = (testResult) -> console.assert 'values' of testResult # is fail report
testG = (testResult) -> console.assert testResult == false    # gave up

try
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

  T = (x,y) -> {gen: x, res: y}
  sTests = [
    T qc.arbArrayOf(5, customGen), (len,size) -> if size > 0 then 5 else 0
    T qc.arbArray(customGen), (len) -> len*2
    T customGen, (len) -> if len > 0 then 1 else 0
  ]

  for t in sTests
    testT qc.run (size) ->
      generated = t.gen size
      (t.gen.shrink generated).length == t.res generated.length, size
    , qc.arbByte
catch err
  console.log err.message.toString()
finally
  console.log "[DONE]"


# TODO
# - piskoviste
# - syntax check
# - check existence funkci --> viz Strict mode and/or try/catch/finally
# - pocesteni
# - zbytek komentaru

# Diskuze nad pouzivanim [0..length-1], vs [0...length] a pouzivani "by 1"
