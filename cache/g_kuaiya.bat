::execLang=bat
@echo off
if /i "%1"=="" call :chrome 192.168.1.4:9999
call :chrome "192.168.1.%1:9999"
:chrome
(start gg.lnk %~1)& exit