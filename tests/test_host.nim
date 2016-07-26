import unittest, os, osproc, threadpool

template HOST_EXE: expr = "bin" / "host_d"

proc sendMsg(p: Process, msg: string) =
  var size = msg.len.int32
  var h: File
  assert open(h, p.inputHandle, fmWrite)
  discard h.writeBuffer(addr size, sizeof size)
  discard h.writeBuffer(msg.cstring, msg.len)
  h.flushFile

proc receiveMsg(p: Process): string =
  proc recv(f: File): string =
    var size = 0'i32
    assert f.readBuffer(addr size, sizeof size) == sizeof size
    var buff = newSeq[char](size + 1)
    assert f.readBuffer(addr buff[0], size) == size
    buff[size] = '\0'
    result = $cast[cstring](addr buff[0])
    
  var h: File
  assert open(h, p.outputHandle, fmRead)
  var res = spawn recv(h)
  result = ^res

suite "Host":
  test "Host - IPC":
    let p = HOST_EXE.startProcess(options = {})
    let msg = "Hello, world!"
    p.sendMsg(msg)
    check: p.receiveMsg == msg
