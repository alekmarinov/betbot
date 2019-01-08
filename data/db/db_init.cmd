@ECHO OFF
call %LRUN_SRC_HOME%\config\lrun.cmd "%LRUN_SRC_HOME%\modules\lua\lrun\start.lua" "lrun.tool.schema2sql" betbot.schema

REM echo Initializing MySQL DB...
REM mysql -u root -e "create database betbot"
REM mysql -u root betbot < betbot_mysql.sql

echo Initializing SQLite DB...
echo .quit | sqlite3 -init betbot_sqlite.sql betbot_sqlite.db
echo .quit | sqlite3 -init betbot_sqlite.sql update.db
