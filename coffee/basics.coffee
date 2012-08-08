root = exports ? this
aCount = 0

root.console =
  log: (msg) -> document.write msg + '\n'
  assert: (bool) ->
    aCount++
    document.write "~> #{aCount}. assert failed!\n" unless bool

root.exports = {}
