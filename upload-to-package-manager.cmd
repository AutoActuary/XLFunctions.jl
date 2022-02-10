@echo off
setlocal

:: Get current directory without trailing \
set "thisdir=%~dp0"
set "thisdir=%thisdir:~0,-1%

:: Get current directory and remove ".jl"
FOR /f "delims=?" %%i IN ("%thisdir%") DO set "package=%%~ni"
set "package=%package:.jl=%

cd "%~dp0"
julia -e "using Pkg; pkg\"dev .\"; using %package%; pth=dirname(pathof(%package%)); println(pth); cd(pth); using LocalRegistry; using %package%; register(%package%)"

:: Pause if directly run from explorer
if /i "%comspec% /c %~0 " equ "%cmdcmdline:"=%" pause