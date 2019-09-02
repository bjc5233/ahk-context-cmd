::execLang=bat execWinMode=normal
@echo off
if /i "%~1"=="" (
    set url=www.baidu.com
) else (
    set url=%~1
)
title ²âÊÔÁ´: %url%
call ping %url%& pause>nul