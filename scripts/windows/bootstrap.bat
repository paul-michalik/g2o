@echo off

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

set "ThirdpartyPath=%~dp0..\..\Thirdparty"
set "QGLVIEWERROOT=%ThirdpartyPath%\bin\%VcPkgTriplet%;%ThirdpartyPath%\lib\%VcPkgTriplet%;%ThirdpartyPath%\include"


