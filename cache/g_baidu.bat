::execLang=bat
@echo off
if /i "%~1"=="" call :chrome https://www.baidu.com/
call :chrome "https://www.baidu.com/s?wd=%~1"
:chrome
(start gg.lnk %1)& exit