::execLang=bat
@echo off
if /i "%~1"=="" call :chrome http://www.bilibili.com/
call :chrome "http://search.bilibili.com/all?keyword=%~1"
:chrome
(start gg.lnk %1)& exit