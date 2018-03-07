@echo off

call "%~dp0bootstrap.bat" %*
rem ==============================
rem Download and build QGLViewer.
rem ==============================

powershell.exe -NoProfile -ExecutionPolicy Bypass -command "Invoke-WebRequest 'http://www.libqglviewer.com/src/libQGLViewer-2.7.1.zip' -OutFile libQGLViewer-2.7.1.zip" 
powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory('libQGLViewer-2.7.1.zip', 'Temp'); }"
del libQGLViewer-2.7.1.zip

set "QGLViewerDownloadPath=%cd%\Temp"
set "QGLViewerPath=%cd%\Temp\libQGLViewer-2.7.1"

call "%PROGRAMFILES(x86)%\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" %Platform%

set Path=%VcPkgDir%\installed\%VcPkgTriplet%\tools\qt5;%Path%
pushd %QGLViewerPath%\QGLViewer
call qmake %QGLViewerPath%\libQGLViewer-2.7.1.pro -spec win32-msvc CONFIG+=%BuildType%
set "CL=/MP"
call nmake
popd

set "ThirdpartyPath=%~dp0..\..\Thirdparty"
if not exist %ThirdpartyPath%\NUL md %ThirdpartyPath%
if not exist %ThirdpartyPath%\QGLViewer\include\NUL md %ThirdpartyPath%\QGLViewer\include
if not exist %ThirdpartyPath%\QGLViewer\bin\%Platform%\NUL md %ThirdpartyPath%\QGLViewer\bin\%VcPkgTriplet%
if not exist %ThirdpartyPath%\QGLViewer\lib\%Platform%\NUL md %ThirdpartyPath%\QGLViewer\lib\%VcPkgTriplet%

xcopy %QGLViewerPath%\QGLViewer\*.dll %ThirdpartyPath%\QGLViewer\bin\%VcPkgTriplet% /sy
xcopy %QGLViewerPath%\QGLViewer\*.lib %ThirdpartyPath%\QGLViewer\lib\%VcPkgTriplet% /sy
xcopy %QGLViewerPath%\QGLViewer\*.exp %ThirdpartyPath%\QGLViewer\lib\%VcPkgTriplet% /sy
xcopy %QGLViewerPath%\QGLViewer\*.exp %ThirdpartyPath%\QGLViewer\lib\%VcPkgTriplet% /sy
xcopy %QGLViewerPath%\QGLViewer\*.h %ThirdpartyPath%\QGLViewer\include

set "QGLVIEWERROOT=%ThirdpartyPath%\QGLViewer\bin\%VcPkgTriplet%;%ThirdpartyPath%\QGLViewer\lib\%VcPkgTriplet%;%ThirdpartyPath%\QGLViewer\include"

rmdir /s /q %QGLViewerDownloadPath%