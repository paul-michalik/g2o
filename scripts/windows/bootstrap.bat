@echo off
setlocal
set "Platform=x64"
set "Toolset=v141"
set "BuildType=Release"

if NOT "%~1"=="" set "Platform=%~1"
if NOT "%~2"=="" set "Toolset=%~2"
if NOT "%~3"=="" set "BuildType=%~3"

rem ----------------------------------
rem Locate vcpkg using environment variables
rem ----------------------------------
set "VcPkgDir=%~d0\Software\vcpkg\vcpkg"
set "VcPkgTriplet=%Platform%-windows"
if defined VCPKG_ROOT_DIR if /i not "%VCPKG_ROOT_DIR%"=="" set "VcPkgDir=%VCPKG_ROOT_DIR%"
if defined VCPKG_DEFAULT_TRIPLET if /i not "%VCPKG_DEFAULT_TRIPLET%"=="" set "VcPkgTriplet=%VCPKG_DEFAULT_TRIPLET%"

rem ----------------------------------
rem Try to look for vcpkg at default locations
rem ----------------------------------
if not exist "%VcPkgDir%" set "VcPkgDir=%~d0\Software\vcpkg\vcpkg"
if not exist "%VcPkgDir%" set "VcPkgDir=%~d0\.vcpkg\vcpkg"
if not exist "%VcPkgDir%" set "VcPkgDir=C:\Software\vcpkg\vcpkg"
if not exist "%VcPkgDir%" set "VcPkgDir=C:\.vcpkg\vcpkg"
if not exist "%VcPkgDir%" set "VcPkgDir=%USERPROFILE%\.vcpkg\vcpkg"
if not exist "%VcPkgDir%" (
    echo vcpkg not found, installing at %VcPkgDir%...
    git clone --recursive https://github.com/Microsoft/vcpkg.git "%VcPkgDir%"
    call "%VcPkgDir%\bootstrap-vcpkg.bat"
) 
    
echo vcpkg at %VcPkgDir%...

rem
rem Check whether we have a difference in the toolsrc folder. If non empty, %errorlevel% should be 0  
rem git diff --name-only origin/HEAD remotes/origin/HEAD | find "toolsrc/" > NUL & echo %errorlevel%
rem Put this to local function or better script...
rem

pushd "%VcPkgDir%"
git fetch origin 51e8b5da7cd8fd1273a99dac953de1aa193e7ac9
git checkout FETCH_HEAD
rem git pull --all --prune
popd

rem
rem only invoke when changes to "toolsrc/" were made
rem 
rem call "%VcPkgDir%\bootstrap-vcpkg.bat"

rem ==============================
rem Upgrade and Install packages.
rem ==============================
set "VcPkgDeps=eigen3 suitesparse clapack openblas ceres qt5-base"
call "%VcPkgDir%\vcpkg.exe" upgrade %VcPkgDeps% --no-dry-run --triplet %VcPkgTriplet%
call "%VcPkgDir%\vcpkg.exe" install %VcPkgDeps% --triplet %VcPkgTriplet%

rem ==============================
rem Prepare external folder. Mimics the vcpkg structure
rem ==============================

set "ExtDir=%~dp0..\..\ext"
set "ExtDir=%~dp0..\..\ext"
echo if not exist "%ExtDir%" md "%ExtDir%"
echo if not exist "%ExtDir%\downloads" md "%ExtDir%\downloads"
echo if not exist "%ExtDir%\buildtrees" md "%ExtDir%\buildtrees"
echo if not exist "%ExtDir%\installed\%Platform%-windows" md "%ExtDir%\installed\%Platform%-windows"

exit /b 0

rem ==============================
rem Download and build QGLViewer.
rem ==============================
call :InstallQGLViewer 

goto :eof

:InstallQGLViewer
setlocal
    if not exist "%ExtDir%\downloads\libQGLViewer-2.7.1.zip" (
        pushd "%ExtDir%\downloads"
        powershell.exe -NoProfile -ExecutionPolicy Bypass -command "Invoke-WebRequest 'http://www.libqglviewer.com/src/libQGLViewer-2.7.1.zip' -OutFile libQGLViewer-2.7.1.zip
        popd
    )

    if not exist "%ExtDir%\buildtrees\libQGLViewer-2.7.1" (
        pushd "%ExtDir%\buildtrees"
        rem Do we really have to be that conservative about the ancient Posh version?
        powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory('libQGLViewer-2.7.1.zip', 'libQGLViewer-2.7.1'); }"
        popd
    )

    if not exist "%ExtDir%\buildtrees\libQGLViewer-2.7.1\%VcPkgTriplet%-rel" ( 
        pushd "%ExtDir%\buildtrees\libQGLViewer-2.7.1"
        md %VcPkgTriplet%-rel
        pushd %VcPkgTriplet%-rel
        call :BuildQGLViewer Release
        popd

        md %VcPkgTriplet%-dbg
        pushd %VcPkgTriplet%-dbg
        call :BuildQGLViewer Debug
        popd
    )
endlocal & set "QGLVIEWERROOT="

goto :eof

:BuildQGLViewer 
setlocal
    set BuildType=%~1
    call "%PROGRAMFILES(x86)%\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" %Platform%
    set "Path=%VcPkgDir%\installed\%VcPkgTriplet%\tools\qt5;%Path%"
    call qmake ..\libQGLViewer-2.7.1.pro -spec win32-msvc CONFIG+=%BuildType%
    set "CL=/MP"
    call nmake

    for /F "tokens=*" %%G in ('dir /b /s *.dll') do (
        xcopy "%%G" "%ExtDir%\%VcPkgTriplet%\bin\" /sy
    )
    for /F "tokens=*" %%G in ('dir /b /s *.lib') do (
        xcopy "%%G" "%ExtDir%\%VcPkgTriplet%\lib\" /sy
    )
    for /F "tokens=*" %%G in ('dir /b /s *.exp') do (
        xcopy "%%G" "%ExtDir%\%VcPkgTriplet%\lib\" /sy
    )
    for /F "tokens=*" %%G in ('dir /b /s *.h') do (
        xcopy "%%G" "%ExtDir%\%VcPkgTriplet%\include\QGLViewer" /sy
    )
endlocal

goto :eof

endlocal & set "VcPkgDir=%VcPkgDir%" & set "VcPkgTriplet=%VcPkgTriplet%" & set "Platform=%Platform%" & set "Toolset=%Toolset%" & set "Platform=%Platform%"



