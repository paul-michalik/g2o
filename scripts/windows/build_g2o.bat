@echo off

setlocal

set "conan_dir=%~d0\git\conan4vcpkg"

set "platform=x64"
set "BuildType=Release"

if NOT "%~1"=="" set "platform=%~1"
if NOT "%~2"=="" set "build_type=%~2"

set "VcPkgTriplet=%platform%-windows"
set "install_dir=%conan_dir%\installed\%VcPkgTriplet%"

if not exist "%conan_dir%" (
    echo conan not found, installing at %conan_dir%...
	git clone -q --depth=1 https://github.com/apattnaik0721013/conan4vcpkg.git "%conan_dir%"	
	pip install pyyaml colorama conan
)

pushd "%conan_dir%"
	call git pull
	call vcpkgbin.bat download vcpkg/0.0.81-7@had/vcpkg "eigen3 suitesparse clapack openblas ceres qt5-base" x64-windows
popd
	
if not exist "%install_dir%" echo %install_dir% does not exist, bailing out & exit /b 1

set "CMAKE_PREFIX_PATH=%install_dir%;%install_dir%;%CMAKE_PREFIX_PATH%"
set "CMAKE_LIBRARY_PATH=%install_dir%\lib;%install_dir%\lib\manual-link;%install_dir%\lib;%install_dir%\lib\manual-link;%CMAKE_LIBRARY_PATH%"
set "generator=Visual Studio 15 2017 Win64"

set "BuildDir=%~dp0..\..\products\cmake.msbuild.windows.%platform%.%toolset%"
if not exist "%BuildDir%" mkdir "%BuildDir%"
cd "%BuildDir%"

set "ThirdpartyPath=%~dp0..\..\Thirdparty"
set "QGLVIEWERROOT=%ThirdpartyPath%\QGLViewer\bin\%VcPkgTriplet%;%ThirdpartyPath%\QGLViewer\lib\%VcPkgTriplet%;%ThirdpartyPath%\QGLViewer\include"

call cmake.exe -G "%generator%" -DCMAKE_BUILD_TYPE=%BuildType% -DG2O_BUILD_APPS=ON -DG2O_BUILD_EXAMPLES=ON "%~dp0..\.."

call cmake.exe --build . --config %BuildType%


endlocal
