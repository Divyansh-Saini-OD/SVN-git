create or replace
package  XX_DBMS_TUNE_PKG
AS
procedure XX_DBMS_TUNE;

procedure PROCESS_REQUEST(p_sql_text CLOB
                          ,p_sql_id VARCHAR2
                          ,p_time_limit VARCHAR2
                          ,p_action VARCHAR2);

END;
/
SHOW ERR;