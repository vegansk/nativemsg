import os, logging, future

var fl = newFileLogger(getAppDir() / "host.log", fmtStr = "$datetime [$levelname]: ")
logging.addHandler(fl)

proc readMessage: string =
  var size = 0'i32
  var read = stdin.readBuffer(addr size, sizeof(size))
  assert(read == sizeof(size))
  var buff = newSeq[char](size.int + 1)
  read = 0
  while read != size:
    let r = stdin.readBuffer(addr buff[read], size - read)
    assert(r != 0)
    read += r
  buff[size] = '\0'
  result = $cast[cstring](addr buff[0])

proc writeMessage(msg: string) =
  var size = msg.len.int32
  var written = stdout.writeBuffer(addr size, sizeof(size))
  assert(written == sizeof(size))
  written = stdout.writeBuffer(msg.cstring, size)
  assert(written == size)

proc main =
  info "Host process is running"
  addQuitProc(proc() {.noconv.} =
                info "Shutdown host process"
  )

  while true:
    let msg = readMessage()
    info("Received: " & msg)
    writeMessage(msg)

when isMainModule:
  main()
