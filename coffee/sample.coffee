root = exports ? this # hack abych zatim nemusel pouzivat zadny modulovac
qc = root.quickCheck

# console.log qc.arbArray((x) -> qc.arbSizedInt 40*x)(20)
# console.log qc.arbArrayOf(10,qc.arbBool)()
# console.log qc.frequency([[1,qc.arbSizedDouble], [3,qc.arbSizedInt], [4,qc.arbBool]])(500)
# console.log qc.oneOf([qc.arbSizedDouble, qc.arbSizedInt, qc.arbBool])(300)


##
## Sample tests of QuickCheck itself
##
testT = (testResult) -> console.assert testResult == true
testF = (testResult) -> console.assert testResult != true

try
  testT qc.run ((x,y) -> x != y), qc.arbBool, qc.arbInt
  testT qc.run ((x) -> typeof (x) == "number"), qc.arbInt
  testT qc.run ((x,y) -> x*y == y*x), qc.arbByte, qc.arbByte
  testF qc.run ((x) -> x % 2 == 0), qc.arbByte
  testF qc.run ((x) -> x), qc.arbBool
  console.assert (qc.run ((x) -> {}), qc.arbBool) == false
catch err
  console.log err.message.toString()
finally
  console.log "[DONE]"


# TODO
# - piskoviste
# - syntax check
# - check existence funkci --> viz Strict mode and/or try/catch/finally
# - pocesteni
# - shrinking
# - zbytek komentaru
