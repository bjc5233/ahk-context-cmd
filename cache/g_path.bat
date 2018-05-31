::execLang=bat
@echo off
if /i "%1"=="" call :dir %systemdrive%\path
if exist %systemdrive%\path\%1 call :dir %systemdrive%\path\%1
exit
:dir
(start "" %1)& exit