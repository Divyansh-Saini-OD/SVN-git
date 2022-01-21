@ECHO OFF
SET ORACLE_HOME=C:\Oracle\product\10.2.0\client_3
SET PATH=C:\Oracle\product\10.2.0\client_3\BIN;%PATH%
SET TNS_ADMIN=C:\Oracle\product\10.2.0\client_3\NETWORK\ADMIN
SET SCRIPT_HOME=.

SET ConnectString=twe60trdb/twe60trdb123@twedev01

sqlplus -s %ConnectString% @%SCRIPT_HOME%\CreateTabs.sql

SQLLDR CONTROL=%SCRIPT_HOME%\Client_goodsvc_mapping.ctl, USERID=%ConnectString% errors=10000

sqlplus -s %ConnectString% @%SCRIPT_HOME%\CreateProcs.sql

sqlplus -s %ConnectString% @%SCRIPT_HOME%\ExecuteProcs.sql

sqlplus -s %ConnectString% @%SCRIPT_HOME%\CleanUp.sql

NOTEPAD import.log