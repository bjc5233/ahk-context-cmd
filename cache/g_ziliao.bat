::execLang=bat
@echo off& set base=F:\资料\
if /i "%1"=="kindle" call :dir kindle资料
if /i "%1"=="beifen" call :dir 备份资料
if /i "%1"=="backup" call :dir 备份资料
if /i "%1"=="back" call :dir 备份资料
if /i "%1"=="gongsi" call :dir 工作资料
if /i "%1"=="company" call :dir 工作资料
if /i "%1"=="code" call :dir 技术资料
if /i "%1"=="jishu" call :dir 技术资料
if /i "%1"=="finance" call :dir 金融资料
if /i "%1"=="other" call :dir 其他项目资料
if /i "%1"=="life" call :dir 生活资料
if /i "%1"=="shouji" call :dir 手机资料
if /i "%1"=="mobile" call :dir 手机资料
if /i "%1"=="video" call :dir 影音资料
call :dir
:dir
(start "" %base%%1)& exit