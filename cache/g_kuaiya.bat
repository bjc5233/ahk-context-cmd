::execLang=bat
@echo off
if /i "%1"=="" call :chrome 192.168.2.100:9999
call :chrome "192.168.2.%1:9999"
:chrome
(start gg.lnk %~1)& exit