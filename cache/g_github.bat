::execLang=bat
@echo off
if /i "%1"=="" call :chrome https://github.com/bjc5233?tab=repositories
call :chrome "https://github.com/search?q=%1"
:chrome
(start gg.lnk %~1)& exit