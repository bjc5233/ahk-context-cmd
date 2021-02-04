::execLang=bat
@echo off
if /i "%~1"=="" call :chrome 127.0.0.1:8080
call :chrome "127.0.0.1:%~1"
:chrome
(start gg.lnk %1)& exit