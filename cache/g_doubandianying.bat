::execLang=bat
@echo off
if /i "%~1"=="" call :chrome https://movie.douban.com/
call :chrome "https://movie.douban.com/subject_search?search_text=%~1"
:chrome
(start gg.lnk %1)& exit