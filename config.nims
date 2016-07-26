srcDir = "src"

import ospaths, strutils

template dep(name: untyped): untyped =
  exec "nim " & astToStr(name)

template dep(name: untyped, params: string): untyped =
  exec "nim " & params & " " & astToStr(name)

proc checkDirExists(file: string) =
  let dir = file.splitPath[0]
  if not dir.dirExists:
    dir.mkDir
  
proc mkExe(srcFile, exeFile: string; debug = true) =
  checkDirExists exeFile
  switch("out", exeFile.toExe)
  --nimcache: build
  if not debug:
    --forceBuild
    --define: release
    --opt: size
  else:
    --define: debug
    --debuginfo
    --debugger: native
    --linedir: on
    --stacktrace: on
    --linetrace: on
    --verbosity: 1

    switch("NimblePath", srcDir)
    
  setCommand "c", srcFile

proc mkJs(srcFile, jsFile: string; debug = true) =
  checkDirExists jsFile
  switch("out", jsFile)
  --nimcache: build
  if not debug:
    --forceBuild
    --define: release
    --opt: size
  else:
    --define: debug
    --debuginfo
    --debugger: native
    --linedir: on
    --stacktrace: on
    --linetrace: on
    --verbosity: 1

    switch("NimblePath", srcDir)
    
  setCommand "js", srcFile

when defined(debug):
  const DEBUG = true
else:
  const DEBUG = false
proc HOST_APP: string = (thisDir() / "bin" / "host" & (if DEBUG: "_d" else: "")).toExe
const APP_ID = "org.acme.test_host"
const EXTENSION_ID = "nokipbkffkbijoiefiejfoohdnmpcmmm"

proc registerHostApp =
  let manifest = """
{
  "name": "$#",
  "description": "Test host application",
  "path": "$#",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://$#/"
  ]
}
""" % [APP_ID, HOST_APP(), EXTENSION_ID]
  when defined(linux):
    let dir = "~/.config/google-chrome/NativeMessagingHosts".expandTilde
    dir.mkDir
    writeFile dir / APP_ID & ".json", manifest

task build_host, "Build host application":
  mkExe("tests/host/main", HOST_APP(), debug = DEBUG)
  registerHostApp()

task test_host, "Test host application":
  dep build_host, "-d:debug"
  --run
  --threads:on
  mkExe("tests/test_host", "bin/test_host", debug = true)

proc chromeCopyStatic =
  for f in listFiles("tests" / "chrome"):
    cpFile f, "build_ext" / f.splitPath[1]

task build_chrome_extension, "Build chrome extension":
  mkDir "build_ext"
  chromeCopyStatic()
  mkJs("tests/chrome_src/main.nim", "build_ext/background.js", debug = DEBUG)

task pack_chrome_extension, "Pack chrome extension":
  dep build_chrome_extension
  exec "google-chrome".toExe & " --pack-extension=" & thisDir() / "build_ext" & " --pack-extension-key=tests/chrome_src/ext_key.pem"
  mvFile "build_ext.crx", "bin/test_extension.crx"

task run_chrome_extension, "Run chrome extension":
  dep build_chrome_extension
  dep build_host
  exec "google-chrome".toExe & " --load-and-launch-app=" & thisDir() / "build_ext"

