::execLang=bat
@echo off
if /i "%1"=="" (shutdown -r -t 0) else (shutdown -r -t %1)