::execLang=bat
@echo off& set base=F:\����\
if /i "%1"=="kindle" call :dir kindle����
if /i "%1"=="beifen" call :dir ��������
if /i "%1"=="backup" call :dir ��������
if /i "%1"=="back" call :dir ��������
if /i "%1"=="gongsi" call :dir ��������
if /i "%1"=="company" call :dir ��������
if /i "%1"=="code" call :dir ��������
if /i "%1"=="jishu" call :dir ��������
if /i "%1"=="finance" call :dir ��������
if /i "%1"=="other" call :dir ������Ŀ����
if /i "%1"=="life" call :dir ��������
if /i "%1"=="shouji" call :dir �ֻ�����
if /i "%1"=="mobile" call :dir �ֻ�����
if /i "%1"=="video" call :dir Ӱ������
call :dir
:dir
(start "" %base%%1)& exit