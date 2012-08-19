root = exports ? this
aCount = 0

root.console =
  log: (msg) -> document.write msg + '\n'
  assert: (bool) ->
    aCount++
    unless bool == true
      console.log "~> #{aCount}. assert failed!"
      console.dump bool
  dump: (obj, depth = 0, index = "DUMP") ->
    indent = ""
    indent += "  " for i in [1..depth] by 1
    console.log "#{indent}#{index}: #{obj} (type: #{typeof obj})"

    for i of obj
      if obj[i] instanceof Object
        console.dump obj[i], depth + 1, i
      else
        console.log "#{indent}  #{i}: #{obj[i]}"
