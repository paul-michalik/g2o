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
rem Prepare vendor folder. Mimics the vcpkg folder structure
rem ==============================
set "VendorDir=%~dp0..\..\.vendor"
if not exist "%VendorDir%" md "%VendorDir%"
if not exist "%VendorDir%\downloads" md "%VendorDir%\downloads"
if not exist "%VendorDir%\buildtrees" md "%VendorDir%\buildtrees"
if not exist "%VendorDir%\installed\%Platform%-windows" md "%VendorDir%\installed\%Platform%-windows"

call :InstallQGLViewer 
rem call :InstallOtherStuffNotInVcpkg

goto :eof

:InstallQGLViewer
setlocal
    if not exist "%VendorDir%\downloads\libQGLViewer-2.7.1.zip" (
        pushd "%VendorDir%\downloads"
        powershell.exe -NoProfile -ExecutionPolicy Bypass -command "Invoke-WebRequest 'http://www.libqglviewer.com/src/libQGLViewer-2.7.1.zip' -OutFile libQGLViewer-2.7.1.zip
        popd
    )

    if not exist "%VendorDir%\buildtrees\libQGLViewer-2.7.1" (
        pushd "%VendorDir%\buildtrees"
        rem Do we really have to be that conservative about the ancient Posh version?
        powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory('%VendorDir%\downloads\libQGLViewer-2.7.1.zip', '.'); }"
        popd
    )

    if not exist "%VendorDir%\buildtrees\libQGLViewer-2.7.1\%VcPkgTriplet%-rel" ( 
        pushd "%VendorDir%\buildtrees\libQGLViewer-2.7.1"
        md %VcPkgTriplet%-rel
        pushd %VcPkgTriplet%-rel
        call :BuildQGLViewer release "%VendorDir%\buildtrees\libQGLViewer-2.7.1\%VcPkgTriplet%-rel"
        popd
        popd
    )

    rem if not exist "%VendorDir%\buildtrees\libQGLViewer-2.7.1\%VcPkgTriplet%-dbg" ( 
    rem     pushd "%VendorDir%\buildtrees\libQGLViewer-2.7.1"
    rem     md %VcPkgTriplet%-dbg
    rem     pushd %VcPkgTriplet%-dbg
    rem     call :BuildQGLViewer debug
    rem     popd
    rem     popd
    rem )
endlocal & set "QGLVIEWERROOT="

goto :eof

:BuildQGLViewer 
setlocal
    set BuildType=%~1
    set BuildDir=%~2
    call "%PROGRAMFILES(x86)%\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" %Platform%
    set "Path=%VcPkgDir%\installed\%VcPkgTriplet%\tools\qt5;%Path%"
    qmake ..\libQGLViewer-2.7.1.pro -d CONFIG+=%BuildType% DESTDIR+="%BuildDir%"
    call nmake

    rem for /F "tokens=*" %%G in ('dir /b /s *.dll') do (
    rem     call xcopy "%%G" "%VendorDir%\%VcPkgTriplet%\bin\" /sy
    rem )
    rem for /F "tokens=*" %%G in ('dir /b /s *.lib') do (
    rem     call xcopy "%%G" "%VendorDir%\%VcPkgTriplet%\lib\" /sy
    rem )
    rem for /F "tokens=*" %%G in ('dir /b /s *.exp') do (
    rem     call xcopy "%%G" "%VendorDir%\%VcPkgTriplet%\lib\" /sy
    rem )
    rem for /F "tokens=*" %%G in ('dir /b /s *.h') do (
    rem     call xcopy "%%G" "%VendorDir%\%VcPkgTriplet%\include\QGLViewer" /sy
    rem )
endlocal

goto :eof

endlocal & set "VendorDir=%VendorDir%" & ^
           set "VcPkgDir=%VcPkgDir%" & ^
           set "VcPkgTriplet=%VcPkgTriplet%" & ^
           set "Platform=%Platform%" & ^
           set "Toolset=%Toolset%" & ^
           set "Platform=%Platform%"



