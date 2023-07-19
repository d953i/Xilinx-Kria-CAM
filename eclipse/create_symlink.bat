@echo off
if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)

set source=D:\Projects\_github\Xilinx-Kria-CAM
set target=D:\Projects\Software-MinGW\Xilinx-Kria-CAM
set exclude=DoNotLinkThisDirectory

forfiles /P "%source%" /C "cmd /c if @isdir==TRUE (if not @file==\"%exclude%\" mklink /d \"%target%\@file\" @path ) else ( mklink \"%target%\@file\" @path )"

pause