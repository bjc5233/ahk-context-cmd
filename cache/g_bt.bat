::execLang=bat
@echo off
if /i "%1"=="" call :chrome http://cntorrentkitty.com
call :chrome "http://cntorrentkitty.com/tk/%1/1-0-0.html"
:chrome
(start gg.lnk %~1)& exit