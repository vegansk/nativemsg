type
  Port {.importc.} = object

proc connectPort(name: cstring): Port =
  {.emit: """
  `result` = chrome.runtime.connectNative(`name`);
""".}

proc onMessage(p: Port, cb: proc (rsp: cstring) {.noconv.}) =
  {.emit: """
  `p`.onMessage.addListener(`cb`);
""".}

proc postMessage(p: Port, msg: cstring) =
  {.emit: """
  `p`.postMessage(`msg`);
""".}
var p = connectPort("org.acme.test_host")

p.onMessage(proc (msg: cstring) {.noconv.} =
  {.emit: """
  console.log("Received message: " + `msg`);
""".}
)

p.postMessage("Hello, world!")
