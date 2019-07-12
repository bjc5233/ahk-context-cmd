::execLang=bat
@echo off& call load.bat _parseBlockNum& setlocal enabledelayedexpansion
set num=%1
(%_call% ("num numStr numLine") %_parseBlockNum%)
(for /l %%i in (1,1,!numLine!) do echo.!numStr_%%i!)>%temp%\getBlock.txt& clip<%temp%\getBlock.txt