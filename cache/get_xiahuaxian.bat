::execLang=bat
@echo off& call load.bat _downcase& setlocal enabledelayedexpansion
set "word=%1"
set out_word=
for /l %%i in (0,1,200) do (
	set "char=!word:~%%i,1!"
	if "!char!"=="" set /p"=!out_word!"<nul|clip& goto :EOF
	(call :isUpChar !char! flag)
	if !flag!==0 set out_word=!out_word!!char!
	if !flag!==1 (
		(%_call% ("char new_char") %_downcase%)
		if "!out_word!"=="" (set out_word=!new_char!) else (set out_word=!out_word!_!new_char!)
	)
)
goto :EOF

:isUpChar
for %%i in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
	if "%%i"=="%1" set %2=1& goto :EOF
)
set %2=0& goto :EOF