@ECHO OFF
SET BETBOT_HOME=%LRUN_SRC_HOME%\apps\betbot
SET LUA_PATH=%BETBOT_HOME%\lua\?.lua
%LRUN_SRC_HOME%\config\lrun.cmd "%LRUN_SRC_HOME%\modules\lua\lrun\start.lua" betbot.main -c "%BETBOT_HOME%/etc/test.conf" %*
REM SET LUA_PATH=
