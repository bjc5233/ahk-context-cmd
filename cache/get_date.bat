::execLang=bat
@echo off& setlocal enabledelayedexpansion
set date=%date:~0,10%
set date=!date:/=-!
set /p"=!date!"<nul|clip