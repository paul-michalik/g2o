@echo off

setlocal

call "%~dp0configure.bat" %*
if errorlevel 1 echo configure error, bailing out & exit /b 1
echo BuildDir = %BuildDir%
echo BuildType= %BuildType%

call cmake.exe --build "%BuildDir%" --config %BuildType%

popd
endlocal
