@echo off

cd %cd%
rmdir /s /q Library
rmdir /s /q obj
del *.csproj
del *.sln
del *.userprefs

@pause