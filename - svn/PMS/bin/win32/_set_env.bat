SET DRV=%CD:~0,2%
CD ..\..
SET PMS_HOME=%cd%
SET PATH=%PMS_HOME%\bin\win32;%PATH%
%DRV%
PROMPT PMS) 
ECHO OFF
CLS
ECHO Current Directory is "%cd%"
ECHO ON

