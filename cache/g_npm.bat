::execLang=bat
@echo off
if /i "%~1"=="" call :chrome https://www.npmjs.com
call :chrome "https://www.npmjs.com/search?q=%~1"
:chrome
(start gg.lnk %1)& exit