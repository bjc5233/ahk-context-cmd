::execLang=bat
@echo off& setlocal enabledelayedexpansion
::当安装vmware等时, 会有多个网络适配器配置, 默认以第一个作为本地连接
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findStr "IPv4 地址"') do (
	set IP=%%i& set IP=!IP:~1!
	set /p"=!IP!"<nul|clip
	echo.& echo.& echo !IP!& echo [已复制到剪贴板]& pause>nul
)