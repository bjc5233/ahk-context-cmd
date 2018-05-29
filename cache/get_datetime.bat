::execLang=bat
@echo off& setlocal enabledelayedexpansion
set date=%date:~0,10%
set date=!date:/=-!
set /p"=!date! %time:~0,8%"<nul|clip