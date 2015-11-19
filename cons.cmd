@ECHO OFF
setlocal
set _CMD_name=%~nx0
set _FolderPath=%~d0%~p0
SET PATH=%PATH%;%_FolderPath%SYSTEM
cd /d "%_FolderPath%"
cls
if NOT exist "%_FolderPath%\cons.exe" (echo.[!]ERROR: It's not a Consultant dir&ENDLOCAL&GOTO :ENDProc)
echo.# init
call :_init
call :clean

echo.# update base
START /W cons.exe /adm /base* /receive_inet /yes /process=2 /sendstt

echo.# collect stat
if exist "%_FolderPath%\adm\sts\" (
  cd "%_FolderPath%\adm\sts\"
echo  * find valid stat
  call :_xFor "' dir /A-D /B /OD *.stt'" "call :_CompareFile_DT "
) else (echo.[!]ERROR: Can't find STT dir&GOTO :ENDStep01)
echo  * send stat
cd "%_FolderPath%"
call :_init_ftp
ncftpput -v -P 9147 -f "%_FolderPath%_tmp\ftfill.txt" FTPSTT "%_FolderPath%_tmp\*.stt"
:ENDStep01
echo  * get stat
START /W cons.exe /usr
if exist "%FolderPath%RECEIVE\*.usr" (
  copy /V /Y "%FolderPath%RECEIVE\*.usr" "%_FolderPath%_tmp\" >Nul
  ) else (echo.[!]ERROR: Can't find USR file&GOTO :ENDStep02)
echo  * send stat
cd "%_FolderPath%"
call :_init_ftp
ncftpput -v -P 9147 -f "%_FolderPath%_tmp\ftfill.txt" FTPUSR "%_FolderPath%_tmp\*.usr"
:ENDStep02

call :clean
GOTO :ENDProc
::7z.exe a "%_FolderPath%_tmp\%DT_str_name%_cons.zip" "%_FolderPath%_tmp\*.stt" > %temp%\null
::  call :_xFor "' dir /A-D /B /OD *.stt'" "echo.call :_InstPck %_FolderPath% " 
::===========================================
::== TOOL
::===========================================

:clean
  md "%FolderPath%_tmp" 2>Nul
  del /F /Q "%FolderPath%_tmp\*"
exit /b /0

:_init
  set DT_str_name=%date:~8,2%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%
  set DT_str=%date%_%time:~0,-6%
  set DT_str=%DT_str:_= %
  call :_convertDT DT_int "%DT_str%"
  set /a DT_int_ex=%DT_int%-2000000
exit /b /0

:_init_ftp
  set _ftp_line01="host 91.208.84.68"
  set _ftp_line02="user cons"
  set _ftp_line03=":s:s$i@@@x@@@x@@@x/ot@x:x@!"
  call :DEcrypt _ftp_line03 "%_ftp_line03%"
  set _ftp_line03=pass %_ftp_line03%
  echo.%_ftp_line01:"=%>"%_FolderPath%_tmp\ftfill.txt"
  echo.%_ftp_line02:"=%>>"%_FolderPath%_tmp\ftfill.txt"
  echo.%_ftp_line03:"=%>>"%_FolderPath%_tmp\ftfill.txt"
exit /b /0

:_CompareFile_DT
  call :_GetDT _tmp01 "%~1"
  call :_convertDT _tmp01 "%_tmp01%"
  if /i %_tmp01% GEQ %DT_int_ex% ( copy /V /Y "%~1" "%_FolderPath%_tmp\" >Nul )
exit /b

:_GetDT
  for %%i in (%~2) do ( set %1=%%~ti )
exit /b

:_convertDT
  set tmp.result=%~2
  set tmp.result=%tmp.result:  = 0%
  set /a %1=%tmp.result:~8,2%%tmp.result:~3,2%%tmp.result:~0,2%%tmp.result:~11,2%%tmp.result:~14,2%
exit /b

:DEcrypt
  set tmp.result=%~2
  set tmp.result=%tmp.result:@x=p%
  set tmp.result=%tmp.result:/o=#%
  set tmp.result=%tmp.result:!z=@!@!%
  set tmp.result=%tmp.result:@!=0%
  set tmp.result=%tmp.result:$0=9%
  set tmp.result=%tmp.result:$o=8%
  set tmp.result=%tmp.result::s=7%
  set tmp.result=%tmp.result:$i=6%
  set tmp.result=%tmp.result::d=5%
  set tmp.result=%tmp.result::x=4%
  set tmp.result=%tmp.result::p=3%
  set tmp.result=%tmp.result:@p=2%
  set %1=%tmp.result:@2=1%
exit /b

:_xFor
  For /F "tokens=*" %%i in (%~1) do (%~2%%i%~3)
exit /b /0

:ENDProc
  echo.# end.
::  pause >Nul
  ENDLOCAL
exit /b /0