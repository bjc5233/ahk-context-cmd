::execLang=bat
@echo off
if /i "%~1"=="" call :chrome http://www.coolapk.com/
call :chrome "http://www.coolapk.com/search?q=%~1"
:chrome
(start gg.lnk %1)& exit