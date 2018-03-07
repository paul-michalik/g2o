@echo off

setlocal

set "conan_dir=%~d0\git\conan4vcpkg"
set "platform=x64"
set "BuildType=Release"
set "g2o_file="

if NOT "%~1"=="" set "platform=%~1"
if NOT "%~2"=="" set "build_type=%~2"
if NOT "%~3"=="" set "g2o_file=%~3"

set "install_dir=%conan_dir%\installed\%platform%-windows"

if not exist "%install_dir%" echo %install_dir% does not exist, bailing out & exit /b 1

set "ThirdpartyPath=%~dp0..\..\Thirdparty\QGLViewer\bin\x64-windows"

set "Path=%install_dir%\bin;%ThirdpartyPath%;%Path%"

set "g2o_viewer_app=%~dp0..\..\bin\%BuildType%\g2o_viewer.exe"
%g2o_viewer_app% %g2o_file%

endlocal
