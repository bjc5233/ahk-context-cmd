::execLang=bat
@echo off
if /i "%~1"=="" call :chrome https://www.taobao.com/
call :chrome "https://s.taobao.com/search?q=%~1"
:chrome
(start gg.lnk %1)& exit