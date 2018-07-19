::execLang=bat
@echo off
if /i "%1"=="" call :dir D:\theme
if /i "%1"=="c" call :dir %systemdrive%\Windows\Resources\Themes
exit
:dir
(start "" %1)& exit