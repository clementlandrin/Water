@echo off
PUSHD .
cd %SHIRO_TOOLS%\hashlink\src\other\memory 
haxe memory.hxml
POPD
hl %SHIRO_TOOLS%\hashlink\src\other\memory\memory.hl ../wartales.hl