::execLang=bat
@echo off& setlocal enabledelayedexpansion
::����װvmware��ʱ, ���ж����������������, Ĭ���Ե�һ����Ϊ��������
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findStr "IPv4 ��ַ"') do (
	set IP=%%i& set IP=!IP:~1!
	set /p"=!IP!"<nul|clip
	echo.& echo.& echo !IP!& echo [�Ѹ��Ƶ�������]& pause>nul
)