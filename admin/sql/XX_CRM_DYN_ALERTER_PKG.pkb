SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CRM_DYN_ALERTER_PKG IS
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- +=========================================================================================+
-- | Name        : XX_CRM_DYN_ALERTER_PKG                                                    |
-- | Description : Dynamic Alerter Program                                                   |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author                 Remarks                                |
-- |=======    ==========      ================       =======================================|
-- |DRAFT 1a   21-JUL-2009     Sarah Maria Justina    Initial draft version                  |
-- +=========================================================================================+
----------------------------
--Declaring Global Constants
----------------------------
   G_PROG_APPLICATION      CONSTANT CHAR (5)      := 'XXCRM';
   G_YES                   CONSTANT CHAR (1)      := 'Y';
   G_NO                    CONSTANT CHAR (1)      := 'N';
   
   G_USER_ID               CONSTANT NUMBER        := fnd_global.user_id();
   G_LOGIN_ID              CONSTANT NUMBER        := fnd_global.login_id();

   G_CHILD_PROG_EXECUTABLE CONSTANT VARCHAR2 (30) := 'XX_CRM_DYN_ALERTER_CHILD';
   G_CHILD_PROG_NAME       CONSTANT VARCHAR2 (30) := 'OD: CRM Generic Report Program';
-- +====================================================================+
 -- | Name        :  DISPLAY_LOG
 -- | Description :  This procedure is invoked to print in the log file
 -- | Parameters  :  p_message IN VARCHAR2
 -- |                p_optional IN NUMBER
 -- +====================================================================+
   PROCEDURE display_log (p_message IN VARCHAR2)
   IS
   BEGIN
         fnd_file.put_line (fnd_file.LOG, p_message);    
   END display_log;
-- +====================================================================+
 -- | Name        :  DISPLAY_OUT
 -- | Description :  This procedure is invoked to print in the log file
 -- | Parameters  :  p_message IN VARCHAR2
 -- |                p_optional IN NUMBER
 -- +====================================================================+
   PROCEDURE display_out (p_message IN VARCHAR2)
   IS
   BEGIN
         fnd_file.put_line (fnd_file.OUTPUT, p_message);    
   END display_out;   

PROCEDURE RAISE_EMAIL_EVENT   
                        (
                         p_module_name            IN         VARCHAR2,
                         p_request_id             IN         NUMBER
                        )
IS
l_event_parameter_list    wf_parameter_list_t;
lc_event_name             VARCHAR2(100) := 'od.oracle.apps.xxcrm.dyn.ODEmailAlert';
l_param                   wf_parameter_t;
lc_event_key              VARCHAR2(100) := p_module_name||p_request_id||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS');
ln_parameter_index        NUMBER := 0;
BEGIN
  l_event_parameter_list := wf_parameter_list_t();
  --Adding the first value to the Event Parameter i.e. MODULE_NAME
  l_param := wf_parameter_t(NULL
                           ,NULL);
  l_event_parameter_list.EXTEND;
  l_param.setname('MODULE_NAME');
  l_param.setvalue(p_module_name);
  ln_parameter_index := ln_parameter_index + 1;
  l_event_parameter_list(ln_parameter_index) := l_param;
l_param := wf_parameter_t(NULL
                           ,NULL);
  l_event_parameter_list.EXTEND;
  l_param.setname('REQUEST_ID');
  l_param.setvalue(p_request_id);
  ln_parameter_index := ln_parameter_index + 1;
  l_event_parameter_list(ln_parameter_index) := l_param;  
  wf_event.RAISE(p_event_name => lc_event_name
                ,p_event_key  => lc_event_key
                ,p_parameters => l_event_parameter_list
                ,p_event_data => NULL
                );  
END;

PROCEDURE RAISE_BPEL_EVENT   
                        (
                         p_summary_id             IN         NUMBER
                        )
IS
l_event_parameter_list    wf_parameter_list_t;
lc_event_name             VARCHAR2(100) := 'od.cdh.rty.bpel';
l_param                   wf_parameter_t;
lc_event_key              VARCHAR2(100) := p_summary_id||to_char(sysdate,'DD-MON-RRRR HH24:MI:SS');
ln_parameter_index        NUMBER := 0;
BEGIN
  l_event_parameter_list := wf_parameter_list_t();
  --Adding the first value to the Event Parameter i.e. MODULE_NAME
  l_param := wf_parameter_t(NULL
                           ,NULL);
  l_event_parameter_list.EXTEND;
  l_param.setname('SUMMARY_ID');
  l_param.setvalue(p_summary_id);
  ln_parameter_index := ln_parameter_index + 1;
  l_event_parameter_list(ln_parameter_index) := l_param;  
  wf_event.RAISE(p_event_name => lc_event_name
                ,p_event_key  => lc_event_key
                ,p_parameters => l_event_parameter_list
                ,p_event_data => NULL
                );  
END;
-- +===================================================================+
-- | Name       : EMAIL_ALERT                                          |
-- | Description: Dynamic Alerter Program                              |
-- +===================================================================+   
FUNCTION EMAIL_ALERT 
                        (
                         p_subscription_guid  IN             RAW,
                         p_event              IN OUT NOCOPY  WF_EVENT_T
                        ) 
RETURN VARCHAR2
AS
lc_module_name          VARCHAR2(240);
lc_mailhost             VARCHAR2(64) := FND_PROFILE.VALUE('XX_CS_SMTP_SERVER');
lc_from                 VARCHAR2(64) := 'CRM_CONVERSIONS@OfficeDepot.com';
lc_mail_conn            UTL_SMTP.connection;
lc_send_as_page         VARCHAR2(1);
lc_mail_to              VARCHAR2(240);
lc_mail_subject         VARCHAR2(240);
lc_mail_header          VARCHAR2(240);
lc_mail_content         VARCHAR2(240);
lc_mail_footer          VARCHAR2(240);
lc_request_id           VARCHAR2(240);
ld_processed_date       DATE;
ln_record_count         NUMBER;


CURSOR lcu_get_email_list(p_module_name IN VARCHAR2) IS
SELECT xval.source_value2 send_as_page,
       xval.source_value3 mail_to,
       xval.source_value4 subject,
       xval.source_value5 mail_header,
	   xval.source_value6 mail_content,
	   xval.source_value7 mail_footer
  FROM xx_fin_translatedefinition xdef, xx_fin_translatevalues xval
 WHERE xdef.translation_name = 'XX_CRM_DYN_ALERTER_EMAIL'
   AND xdef.translate_id = xval.translate_id
   AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (xval.start_date_active,
                                           SYSDATE - 1)
                                     )
                           AND TRUNC (NVL (xval.end_date_active, SYSDATE + 1))
   AND xval.source_value1 = p_module_name;
BEGIN
lc_module_name := p_event.GetValueForParameter('MODULE_NAME');
lc_request_id  := p_event.GetValueForParameter('REQUEST_ID');

BEGIN
SELECT creation_date, record_count
  INTO ld_processed_date,ln_record_count
  FROM xx_crm_dyn_alerter
 WHERE request_id = lc_request_id;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  ld_processed_date:= NULL;
  ln_record_count := NULL;
WHEN TOO_MANY_ROWS THEN
  ld_processed_date:= NULL;
  ln_record_count := NULL;
END;
 
OPEN lcu_get_email_list(lc_module_name);
FETCH lcu_get_email_list INTO lc_send_as_page,lc_mail_to,lc_mail_subject,lc_mail_header,lc_mail_content,lc_mail_footer;
CLOSE lcu_get_email_list;

lc_mail_to := lc_mail_to||'@OfficeDepot.com';


lc_mail_conn := UTL_SMTP.open_connection(lc_mailhost, 25);
UTL_SMTP.helo(lc_mail_conn, lc_mailhost);
UTL_SMTP.mail(lc_mail_conn, lc_from);
UTL_SMTP.rcpt(lc_mail_conn, lc_mail_to);

UTL_SMTP.open_data(lc_mail_conn);


UTL_SMTP.WRITE_DATA(lc_mail_conn,'Date: '  ||TO_CHAR(SYSDATE,'DD MON RRRR hh24:mi:ss')||utl_tcp.CRLF);
UTL_SMTP.WRITE_DATA(lc_mail_conn,'From: '  ||lc_from||utl_tcp.CRLF);
UTL_SMTP.WRITE_DATA(lc_mail_conn,'To: '    ||lc_mail_to||utl_tcp.CRLF);   
IF(lc_send_as_page= 'Y') THEN
    UTL_SMTP.WRITE_DATA(lc_mail_conn,'Subject:'||'***page***'||lc_mail_subject||utl_tcp.CRLF);
ELSE
    UTL_SMTP.WRITE_DATA(lc_mail_conn,'Subject:'||lc_mail_subject||utl_tcp.CRLF);
END IF;  


UTL_SMTP.WRITE_DATA(lc_mail_conn,utl_tcp.CRLF); 
UTL_SMTP.write_data(lc_mail_conn, lc_mail_header|| Chr(13));
UTL_SMTP.write_data(lc_mail_conn, lc_mail_content|| Chr(13));
UTL_SMTP.write_data(lc_mail_conn, 'Module Name:'||lc_module_name|| Chr(13));
UTL_SMTP.write_data(lc_mail_conn, 'Processed Date:'||ld_processed_date|| Chr(13));
UTL_SMTP.write_data(lc_mail_conn, 'Total Number Of Records:'||ln_record_count|| Chr(13));
UTL_SMTP.write_data(lc_mail_conn, 'Please view the output of the Request ID:'||lc_request_id||' for more details.'|| Chr(13));
UTL_SMTP.write_data(lc_mail_conn, lc_mail_footer|| Chr(13));  
UTL_SMTP.close_data(lc_mail_conn);


UTL_SMTP.quit(lc_mail_conn);

UPDATE XX_CRM_DYN_ALERTER
   SET ALERT_FLAG='Y'
 WHERE REQUEST_ID=lc_request_id;

COMMIT;

RETURN 'SUCCESS';
END EMAIL_ALERT;
-- +===================================================================+
-- | Name       : BUILD_DYN_SQL                                        |
-- | Description: Dynamic Alerter Program                              |
-- +===================================================================+   
PROCEDURE BUILD_DYN_SQL (
                         p_module_name            IN         VARCHAR2,
                         p_bpel_query             IN         VARCHAR2,
                         p_exclude_errors         IN         VARCHAR2,
                         p_entity_type            IN         VARCHAR2,
                         p_print_output           IN         VARCHAR2,
                         x_summary_id            OUT NOCOPY  NUMBER,
                         x_rows_processed        OUT NOCOPY  NUMBER,
                         x_retcode               OUT NOCOPY  NUMBER,
                         x_errbuf                OUT NOCOPY  VARCHAR2
                        )
IS
lc_final_sql             VARCHAR2(7200);
lc_output_sql            VARCHAR2(7200);
lc_select_sql            VARCHAR2(8500);
lc_temp_sql              VARCHAR2(8500);
ln_cur_handle            INTEGER;        
ln_rows_processed        NUMBER;
ln_counter               NUMBER      := 0;
ln_outer_counter         NUMBER      := 0; 
ln_summary_id            NUMBER;
lt_dyn_var_tbl           xx_dyn_var_tbl_type;
lt_dyn_others_tbl        xx_dyn_others_tbl_type;
lt_dyn_final_tbl         xx_dyn_var_tbl_type;
lt_dyn_header            VARCHAR2(4000) := '';
lc_message_data          VARCHAR2 (4000); 
lc_bpel_column_name      VARCHAR2(240);
lc_err_column_name       VARCHAR2(240);
EX_INVALID_SQL_SETUP     EXCEPTION;
EX_TOO_MANY_SQL_SETUP    EXCEPTION;
EX_NO_BPEL_COLUMN_SET    EXCEPTION;
EX_MANY_BPEL_COLUMN_SET  EXCEPTION;
EX_NO_ERR_COLUMN_SET     EXCEPTION;
EX_MANY_ERR_COLUMN_SET   EXCEPTION;

CURSOR lcu_get_sql_struct IS
SELECT xval.source_value2 column_name,
       xval.source_value3 sequence_num,
       xval.source_value4 datatype_length,
       xval.source_value5 datatype
  FROM xx_fin_translatedefinition xdef, xx_fin_translatevalues xval
 WHERE xdef.translation_name = 'XX_CRM_DYN_ALERTER_COLLST'
   AND xdef.translate_id = xval.translate_id
   AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (xval.start_date_active,
                                           SYSDATE - 1)
                                     )
                           AND TRUNC (NVL (xval.end_date_active, SYSDATE + 1))
   AND xval.source_value1 = p_module_name
   order by xval.source_value3;
BEGIN
x_summary_id  := 0;
ln_cur_handle := dbms_sql.open_cursor;
BEGIN
SELECT    xval.source_value1
       || ' '
       || xval.source_value2
       || ' '
       || xval.source_value3
       || ' '
       || xval.source_value4
       || ' '
       || xval.source_value5
       || ' '
       || xval.source_value6
       || ' '
       || xval.source_value7
       || ' '
       || xval.source_value8
       || ' '
       || xval.source_value9
       || ' '
       || xval.source_value10
       || ' '
       || xval.target_value1
       || ' '
       || xval.target_value2
       || ' '
       || xval.target_value3
       || ' '
       || xval.target_value4
       || ' '
       || xval.target_value5
       || ' '
       || xval.target_value6
       || ' '
       || xval.target_value7
       || ' '
       || xval.target_value8
       || ' '
       || xval.target_value9
       || ' '
       || xval.target_value10
       || ' '
       || xval.target_value11
       || ' '
       || xval.target_value12
       || ' '
       || xval.target_value13
       || ' '
       || xval.target_value14
       || ' '
       || xval.target_value15
       || ' '
       || xval.target_value16
       || ' '
       || xval.target_value17
       || ' '
       || xval.target_value18
       || ' '
       || xval.target_value19
  INTO lc_select_sql
  FROM xx_fin_translatedefinition xdef, xx_fin_translatevalues xval
 WHERE xdef.translation_name = 'XX_CRM_DYN_ALERTER_SQLLST'
   AND xdef.translate_id = xval.translate_id
   AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (xval.start_date_active,
                                           SYSDATE - 1)
                                     )
                           AND TRUNC (NVL (xval.end_date_active, SYSDATE + 1))
   AND xval.target_value20 = p_module_name;
EXCEPTION
WHEN NO_DATA_FOUND THEN
   RAISE EX_INVALID_SQL_SETUP;
WHEN TOO_MANY_ROWS THEN
   RAISE EX_TOO_MANY_SQL_SETUP;
END;

  IF(p_bpel_query = 'Y') THEN
     BEGIN
     SELECT xval.source_value2 column_name
       INTO lc_bpel_column_name
       FROM xx_fin_translatedefinition xdef, xx_fin_translatevalues xval
      WHERE xdef.translation_name = 'XX_CRM_DYN_ALERTER_COLLST'
        AND xdef.translate_id = xval.translate_id
        AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (xval.start_date_active,
                                                SYSDATE - 1)
                                          )
                                AND TRUNC (NVL (xval.end_date_active, SYSDATE + 1))
        AND xval.source_value1 = p_module_name
        AND xval.source_value6 = 'Y';
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
       RAISE EX_NO_BPEL_COLUMN_SET;
     WHEN TOO_MANY_ROWS THEN
       RAISE EX_MANY_BPEL_COLUMN_SET;
     END;
     
     SELECT XXCRM.XXOD_HZ_SUMMARY_S.NEXTVAL
       INTO ln_summary_id
       FROM DUAL;
     
     x_summary_id  := ln_summary_id;
     
     display_log('SUMMARY ID:'||ln_summary_id);
     
     lc_temp_sql   := 'SELECT '||ln_summary_id||',SYSDATE,SYSDATE,'''||p_entity_type||''','||FND_GLOBAL.conc_request_id||','||lc_bpel_column_name||' '||SUBSTR(lc_select_sql,INSTR(UPPER(lc_select_sql),'FROM'));
     lc_final_sql  := 'INSERT INTO XXOD_HZ_SUMMARY (SUMMARY_ID,CREATION_DATE,LAST_UPDATE_DATE,ACCOUNT_ORIG_SYSTEM,PROGRAM_ID,ACCOUNT_ORIG_SYSTEM_REFERENCE) '||lc_temp_sql;
     display_log('FINAL BPEL Insert SQL:'||lc_final_sql);
  ELSE
     lc_final_sql := lc_select_sql;
     display_log('FINAL Select SQL:'||lc_final_sql);
  END IF;
  
  
  BEGIN
  dbms_sql.parse(ln_cur_handle, lc_final_sql, dbms_sql.native);
  EXCEPTION
  WHEN OTHERS THEN
    RAISE EX_INVALID_SQL_SETUP;
  END;
  
  IF(p_bpel_query = 'N') THEN  
  ln_counter := 0;
  FOR lt_get_sql_struct IN lcu_get_sql_struct
  LOOP
    lt_dyn_var_tbl(ln_counter):= '';
    lt_dyn_others_tbl(ln_counter):= '';
    ln_counter := ln_counter + 1;
  END LOOP;
  
  ln_counter := 0;
  FOR lt_get_sql_struct IN lcu_get_sql_struct
  LOOP
    IF(lt_get_sql_struct.datatype = 'VARCHAR2' OR
        lt_get_sql_struct.datatype = 'CHAR') then
    dbms_sql.define_column(ln_cur_handle, lt_get_sql_struct.sequence_num, lt_dyn_var_tbl(ln_counter), lt_get_sql_struct.datatype_length); 
    ELSE
    dbms_sql.define_column(ln_cur_handle, lt_get_sql_struct.sequence_num, lt_dyn_others_tbl(ln_counter),200); 
    END IF;
    ln_counter := ln_counter + 1;
  END LOOP;
  END IF;

  ln_rows_processed := dbms_sql.execute(ln_cur_handle);

/*
  IF(p_bpel_query = 'N') THEN   
  ln_outer_counter := 0;
  LOOP
    if DBMS_SQL.FETCH_ROWS(ln_cur_handle) = 0 then
      exit;
    else
      ln_counter := 0;
      FOR lt_get_sql_struct IN lcu_get_sql_struct
      LOOP
        IF(lt_get_sql_struct.datatype = 'VARCHAR2' OR
            lt_get_sql_struct.datatype = 'CHAR') then
        dbms_sql.column_value(ln_cur_handle, ln_counter+1, lt_dyn_var_tbl(ln_counter)); 
        ELSE
        dbms_sql.column_value(ln_cur_handle, ln_counter+1, lt_dyn_others_tbl(ln_counter)); 
        END IF;
        ln_counter := ln_counter + 1;
      END LOOP;
       ln_outer_counter := ln_outer_counter + 1;
       lt_dyn_final_tbl(ln_outer_counter) := '';
       ln_counter := 0;
       FOR lt_get_sql_struct IN lcu_get_sql_struct loop
         if (lt_get_sql_struct.datatype = 'VARCHAR2' OR
            lt_get_sql_struct.datatype = 'CHAR') then
           lt_dyn_final_tbl(ln_outer_counter) := lt_dyn_final_tbl(ln_outer_counter) || 
                            rtrim(lt_dyn_var_tbl(ln_counter)) || CHR(9);
         else
           lt_dyn_final_tbl(ln_outer_counter) := lt_dyn_final_tbl(ln_outer_counter) || 
                            rtrim(lt_dyn_others_tbl(ln_counter)) || CHR(9);
         end if;
         ln_counter := ln_counter + 1;
       end loop;

    end if;
  end loop;
  END IF;

IF(p_bpel_query = 'N') THEN   
  ln_counter := 1;
  FOR lt_get_sql_struct IN lcu_get_sql_struct 
  loop
  lt_dyn_header:=lt_dyn_header || lt_get_sql_struct.column_name|| CHR(9);
  ln_counter := ln_counter + 1;
  end loop;

  display_out(lt_dyn_header);
  
  FOR i in 1..lt_dyn_final_tbl.COUNT
  LOOP
        display_out(lt_dyn_final_tbl(i));
  END LOOP;
  
ln_rows_processed := lt_dyn_final_tbl.COUNT;
END IF;
*/

IF(p_bpel_query = 'Y' AND p_exclude_errors='Y') THEN
    BEGIN
        SELECT xval.source_value2 column_name
          INTO lc_err_column_name
          FROM xx_fin_translatedefinition xdef, xx_fin_translatevalues xval
         WHERE xdef.translation_name = 'XX_CRM_DYN_ALERTER_COLLST'
           AND xdef.translate_id = xval.translate_id
           AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (xval.start_date_active,
                                                   SYSDATE - 1)
                                             )
                                   AND TRUNC (NVL (xval.end_date_active, SYSDATE + 1))
           AND xval.source_value1 = p_module_name
           AND xval.source_value7 = 'Y';
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
        RAISE EX_NO_ERR_COLUMN_SET;
     WHEN TOO_MANY_ROWS THEN
        RAISE EX_MANY_ERR_COLUMN_SET;
     END;
     
     lc_final_sql:= 'DELETE FROM XXOD_HZ_SUMMARY WHERE SUMMARY_ID= '||ln_summary_id||' AND ACCOUNT_ORIG_SYSTEM ='''||p_entity_type||''' AND ACCOUNT_ORIG_SYSTEM_REFERENCE IN ('||
                    'SELECT '||lc_bpel_column_name||' '||SUBSTR(lc_select_sql,INSTR(UPPER(lc_select_sql),'FROM'))|| ' AND '||
                    'UPPER('||lc_bpel_column_name||') IN (SELECT upper(xval.source_value2) error FROM xx_fin_translatedefinition xdef, xx_fin_translatevalues xval'||
                    ' WHERE xdef.translation_name = ''XX_CRM_DYN_ALERTER_ERROR'' AND xdef.translate_id = xval.translate_id'||
                    ' AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (xval.start_date_active,SYSDATE - 1)) AND TRUNC (NVL (xval.end_date_active, SYSDATE + 1))'||
                    'AND xval.source_value1 = '''||p_module_name||'''))';
     display_log('FINAL Bpel Delete SQL:'||lc_final_sql);
    
     BEGIN
     dbms_sql.parse(ln_cur_handle, lc_final_sql, dbms_sql.native);
     EXCEPTION
     WHEN OTHERS THEN
       RAISE EX_INVALID_SQL_SETUP;
     END;
     ln_rows_processed := dbms_sql.execute(ln_cur_handle);
END IF;     
     
     
     /**
     New Change
     **/
IF(p_bpel_query = 'Y' AND p_exclude_errors='Y') THEN     
     lc_output_sql := lc_select_sql || 'AND '||
                      ' UPPER('||lc_bpel_column_name||') NOT IN (SELECT upper(xval.source_value2) error FROM xx_fin_translatedefinition xdef, xx_fin_translatevalues xval'||
		      ' WHERE xdef.translation_name = ''XX_CRM_DYN_ALERTER_ERROR'' AND xdef.translate_id = xval.translate_id'||
		      ' AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (xval.start_date_active,SYSDATE - 1)) AND TRUNC (NVL (xval.end_date_active, SYSDATE + 1))'||
                      ' AND xval.source_value1 = '''||p_module_name||''')';
ELSE
     lc_output_sql := lc_select_sql;
END IF;
     display_log('FINAL Output SQL:'||lc_output_sql);

   
     dbms_sql.parse(ln_cur_handle, lc_output_sql, dbms_sql.native);
     
       ln_counter := 0;
       FOR lt_get_sql_struct IN lcu_get_sql_struct
       LOOP
         lt_dyn_var_tbl(ln_counter):= '';
         lt_dyn_others_tbl(ln_counter):= '';
         ln_counter := ln_counter + 1;
       END LOOP;
       
       ln_counter := 0;
       FOR lt_get_sql_struct IN lcu_get_sql_struct
       LOOP
         IF(lt_get_sql_struct.datatype = 'VARCHAR2' OR
             lt_get_sql_struct.datatype = 'CHAR') then
         dbms_sql.define_column(ln_cur_handle, lt_get_sql_struct.sequence_num, lt_dyn_var_tbl(ln_counter), lt_get_sql_struct.datatype_length); 
         ELSE
         dbms_sql.define_column(ln_cur_handle, lt_get_sql_struct.sequence_num, lt_dyn_others_tbl(ln_counter),200); 
         END IF;
         ln_counter := ln_counter + 1;
       END LOOP;
  
     ln_rows_processed := dbms_sql.execute(ln_cur_handle);
     ln_outer_counter := 0;
       LOOP
         if DBMS_SQL.FETCH_ROWS(ln_cur_handle) = 0 then
           exit;
         else
           ln_counter := 0;
           FOR lt_get_sql_struct IN lcu_get_sql_struct
           LOOP
             IF(lt_get_sql_struct.datatype = 'VARCHAR2' OR
                 lt_get_sql_struct.datatype = 'CHAR') then
             dbms_sql.column_value(ln_cur_handle, ln_counter+1, lt_dyn_var_tbl(ln_counter)); 
             ELSE
             dbms_sql.column_value(ln_cur_handle, ln_counter+1, lt_dyn_others_tbl(ln_counter)); 
             END IF;
             ln_counter := ln_counter + 1;
           END LOOP;
            ln_outer_counter := ln_outer_counter + 1;
            lt_dyn_final_tbl(ln_outer_counter) := '';
            ln_counter := 0;
            FOR lt_get_sql_struct IN lcu_get_sql_struct loop
              if (lt_get_sql_struct.datatype = 'VARCHAR2' OR
                 lt_get_sql_struct.datatype = 'CHAR') then
                lt_dyn_final_tbl(ln_outer_counter) := lt_dyn_final_tbl(ln_outer_counter) || 
                                 rtrim(lt_dyn_var_tbl(ln_counter)) || CHR(9);
              else
                lt_dyn_final_tbl(ln_outer_counter) := lt_dyn_final_tbl(ln_outer_counter) || 
                                 rtrim(lt_dyn_others_tbl(ln_counter)) || CHR(9);
              end if;
              ln_counter := ln_counter + 1;
            end loop;
     
         end if;
  end loop;
  
    ln_counter := 1;
    FOR lt_get_sql_struct IN lcu_get_sql_struct 
    loop
    lt_dyn_header:=lt_dyn_header || lt_get_sql_struct.column_name|| CHR(9);
    ln_counter := ln_counter + 1;
    end loop;
  
IF(p_print_output = 'Y') THEN  
    display_out(lt_dyn_header);
    
    FOR i in 1..lt_dyn_final_tbl.COUNT
    LOOP
          display_out(lt_dyn_final_tbl(i));
    END LOOP;
    
    
END IF;
  
ln_rows_processed := lt_dyn_final_tbl.COUNT;

DBMS_SQL.CLOSE_CURSOR(ln_cur_handle);
x_rows_processed := ln_rows_processed;
EXCEPTION
WHEN EX_NO_ERR_COLUMN_SET THEN
  fnd_message.set_name           ('XXCRM', 'XX_CRM_0085_DYN_NO_ERR_COL');
  fnd_message.set_token          ('MODULE_NAME', p_module_name);
  lc_message_data                := fnd_message.get;
  x_retcode                      := 2;
  x_errbuf                       := 'Procedure: BUILD_DYN_SQL: ' || lc_message_data;
WHEN EX_MANY_ERR_COLUMN_SET THEN
  fnd_message.set_name           ('XXCRM', 'XX_CRM_0086_DYN_MANY_ERR_COL');
  fnd_message.set_token          ('MODULE_NAME', p_module_name);
  lc_message_data                := fnd_message.get;
  x_retcode                      := 2;
  x_errbuf                       := 'Procedure: BUILD_DYN_SQL: ' || lc_message_data;
WHEN EX_NO_BPEL_COLUMN_SET THEN
  fnd_message.set_name           ('XXCRM', 'XX_CRM_0082_DYN_NO_BPEL_COL');
  fnd_message.set_token          ('MODULE_NAME', p_module_name);
  lc_message_data                := fnd_message.get;
  x_retcode                      := 2;
  x_errbuf                       := 'Procedure: BUILD_DYN_SQL: ' || lc_message_data;
WHEN EX_MANY_BPEL_COLUMN_SET THEN
  fnd_message.set_name           ('XXCRM', 'XX_CRM_0083_DYN_MANY_BPEL_COL');
  fnd_message.set_token          ('MODULE_NAME', p_module_name);
  lc_message_data                := fnd_message.get;
  x_retcode                      := 2;
  x_errbuf                       := 'Procedure: BUILD_DYN_SQL: ' || lc_message_data;
WHEN EX_TOO_MANY_SQL_SETUP THEN
  fnd_message.set_name           ('XXCRM', 'XX_CRM_0084_DYN_TOO_MANY_SQL');
  fnd_message.set_token          ('MODULE_NAME', p_module_name);
  lc_message_data                := fnd_message.get;
  x_retcode                      := 2;
  x_errbuf                       := 'Procedure: BUILD_DYN_SQL: ' || lc_message_data;
WHEN EX_INVALID_SQL_SETUP THEN
  fnd_message.set_name           ('XXCRM', 'XX_CRM_0081_DYN_INVALID_SQL');
  fnd_message.set_token          ('MODULE_NAME', p_module_name);
  lc_message_data                := fnd_message.get;
  x_retcode                      := 2;
  x_errbuf                       := 'Procedure: BUILD_DYN_SQL: ' || lc_message_data;
WHEN OTHERS THEN
  fnd_message.set_name           ('XXCRM', 'XX_CRM_0080_DYN_ALRT_UNEXP_ERR');
  fnd_message.set_token          ('SQL_CODE', SQLCODE);
  fnd_message.set_token          ('SQL_ERR', SQLERRM);
  lc_message_data                := fnd_message.get;
  x_retcode                      := 2;
  x_errbuf                       := 'Procedure: BUILD_DYN_SQL: ' || lc_message_data;  
END;
-- +===================================================================+
-- | Name       : REPORT_CHILD                                         |
-- | Description: Dynamic Alerter Program                              |
-- +===================================================================+   
PROCEDURE REPORT_CHILD  (
                         x_errbuf                OUT         VARCHAR2,
                         x_retcode               OUT         NUMBER,
                         p_module_name            IN         VARCHAR2,
                         p_bpel_retry             IN         VARCHAR2,
                         p_exclude_exceptions     IN         VARCHAR2,
                         p_entity_type            IN         VARCHAR2
                        )
IS
ln_rows_processed             NUMBER;
ln_conc_request_id            NUMBER;
lc_message_data               VARCHAR2 (4000); 
lc_exclude_errors             VARCHAR2(1)      := 'N';
lc_print_output               VARCHAR2(1)      := 'N';
lc_autocorrect_proc           VARCHAR2 (240);
lc_autocorrect_prog           VARCHAR2 (240);
lc_autocorrect_app_code       VARCHAR2 (240);
ln_summary_id                 NUMBER;
ln_cur_handle                 INTEGER; 
EX_CORRUPT_SQL_SETUP          EXCEPTION;
EX_INVALID_AUTOCORRECT_PROC   EXCEPTION;
EX_INVALID_AUTOCORRECT_PROG   EXCEPTION;
EX_MANY_AUTOCORRECT_PARAMS    EXCEPTION;
BEGIN
IF(p_bpel_retry = 'Y') THEN
   lc_print_output := 'N';
ELSE
   lc_print_output := 'Y';
END IF;
BUILD_DYN_SQL(p_module_name,'N',lc_exclude_errors,p_entity_type,lc_print_output,ln_summary_id,ln_rows_processed,x_retcode,x_errbuf);
IF(x_retcode = 2) THEN
  RAISE EX_CORRUPT_SQL_SETUP;
END IF;
IF(ln_rows_processed>0) THEN
  
  INSERT INTO 
  XX_CRM_DYN_ALERTER
  (
    REQUEST_ID     
   ,MODULE_NAME    
   ,RECORD_COUNT   
   ,ALERT_FLAG      
   ,CREATION_DATE   
  )
  VALUES
  (
    fnd_global.conc_request_id
   ,p_module_name
   ,ln_rows_processed
   ,'N'
   ,sysdate
  );
  
 RAISE_EMAIL_EVENT(p_module_name,FND_GLOBAL.conc_request_id); 
  
 IF(p_bpel_retry = 'Y') THEN
         IF(p_exclude_exceptions = 'Y') THEN
            lc_exclude_errors := 'Y';
         END IF;
         BUILD_DYN_SQL(p_module_name,'Y',lc_exclude_errors,p_entity_type,'Y',ln_summary_id,ln_rows_processed,x_retcode,x_errbuf);
         IF(x_retcode = 2) THEN
            RAISE EX_CORRUPT_SQL_SETUP;
         END IF;
  END IF;

RAISE_BPEL_EVENT(ln_summary_id);

UPDATE xx_fin_translatevalues
   SET source_value5 = TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS')
 WHERE translate_id = (SELECT translate_id
                         FROM xx_fin_translatedefinition
                        WHERE translation_name = 'XX_CRM_DYN_ALERTER_MASTER')
   AND source_value1 = p_module_name;
   
BEGIN
   SELECT xval.source_value7 conc_prog_name,
	  xval.source_value8 stored_proc_name,
	  xval.source_value9 conc_prog_app_name
    INTO  lc_autocorrect_prog,lc_autocorrect_proc,lc_autocorrect_app_code
    FROM  xx_fin_translatedefinition xdef, xx_fin_translatevalues xval
   WHERE  xdef.translation_name = 'XX_CRM_DYN_ALERTER_MASTER'
     AND  xdef.translate_id = xval.translate_id
     AND  TRUNC (SYSDATE) BETWEEN TRUNC (NVL (xval.start_date_active,SYSDATE - 1))
     AND  TRUNC (NVL (xval.end_date_active, SYSDATE + 1))
     AND  xval.source_value1= p_module_name;

	IF(lc_autocorrect_proc IS NOT NULL AND lc_autocorrect_prog IS NOT NULL) THEN
	  RAISE EX_MANY_AUTOCORRECT_PARAMS;
	ELSIF(lc_autocorrect_proc IS NOT NULL) THEN
	BEGIN
		ln_cur_handle := dbms_sql.open_cursor;   
		dbms_sql.parse(ln_cur_handle, 'BEGIN '||lc_autocorrect_proc||';END;', dbms_sql.native);
		ln_rows_processed := dbms_sql.execute(ln_cur_handle);
		dbms_sql.close_cursor(ln_cur_handle);
		EXCEPTION
		WHEN OTHERS THEN
		 RAISE EX_INVALID_AUTOCORRECT_PROC;
	END;
        ELSIF(lc_autocorrect_prog IS NOT NULL) THEN
        BEGIN
            ln_conc_request_id          :=      
                                        fnd_request.submit_request
                                        (application      => lc_autocorrect_app_code,
                                         program          => lc_autocorrect_prog,
                                         sub_request      => FALSE
                                        ); 
            IF (ln_conc_request_id = 0)
            THEN
              RAISE EX_INVALID_AUTOCORRECT_PROG;
            END IF;                                        
        END;
        END IF;
   
EXCEPTION
WHEN NO_DATA_FOUND THEN
  NULL;
END;	 
COMMIT;  
END IF;

EXCEPTION
WHEN EX_MANY_AUTOCORRECT_PARAMS THEN
  ROLLBACK;
  fnd_message.set_name           ('XXCRM', 'XX_CRM_0089_DYN_AUTO_PARAMS');
  fnd_message.set_token          ('MODULE_NAME', p_module_name); 
  lc_message_data                := fnd_message.get;
  x_retcode                      := 2;
  x_errbuf                       := 'Procedure: REPORT_CHILD: ' || lc_message_data;
WHEN EX_INVALID_AUTOCORRECT_PROG THEN
  ROLLBACK;
  fnd_message.set_name           ('XXCRM', 'XX_CRM_0088_DYN_INVALID_PROG');
  fnd_message.set_token          ('PRG_NAME', lc_autocorrect_prog);
  fnd_message.set_token          ('SQL_CODE', SQLCODE);
  fnd_message.set_token          ('SQL_ERR', SQLERRM);
  fnd_message.set_token          ('MODULE_NAME', p_module_name); 
  lc_message_data                := fnd_message.get;
  x_retcode                      := 2;
  x_errbuf                       := 'Procedure: REPORT_CHILD: ' || lc_message_data;
WHEN EX_INVALID_AUTOCORRECT_PROC THEN
  ROLLBACK;
  fnd_message.set_name           ('XXCRM', 'XX_CRM_0087_DYN_INVALID_PROC');
  fnd_message.set_token          ('MODULE_NAME', p_module_name);
  lc_message_data                := fnd_message.get;
  x_retcode                      := 2;
  x_errbuf                       := 'Procedure: REPORT_CHILD: ' || lc_message_data;
WHEN EX_CORRUPT_SQL_SETUP THEN
  ROLLBACK;
WHEN OTHERS THEN
  ROLLBACK;
  fnd_message.set_name           ('XXCRM', 'XX_CRM_0080_DYN_ALRT_UNEXP_ERR');
  fnd_message.set_token          ('SQL_CODE', SQLCODE);
  fnd_message.set_token          ('SQL_ERR', SQLERRM);
  lc_message_data                := fnd_message.get;
  x_retcode                      := 2;
  x_errbuf                       := 'Procedure: REPORT_CHILD: ' || lc_message_data;
END;
-- +===================================================================+
-- | Name       : REPORT_MAIN                                          |
-- | Description: Dynamic Alerter Program                              |
-- +===================================================================+   
PROCEDURE REPORT_MAIN  (
                         x_errbuf                OUT         VARCHAR2,
                         x_retcode               OUT         NUMBER
                        )
IS
   ln_conc_request_id      NUMBER;
   lc_message_data         VARCHAR2 (4000);  
   
   CURSOR lcu_get_ready_to_run_programs 
   IS
   SELECT xval.source_value1 module_name,
          xval.source_value2 frequency,
          xval.source_value3 bpel_retry,
          xval.source_value4 exclude_exceptions,
          xval.source_value5 last_run_date,
          xval.source_value6 entity_type
    FROM  xx_fin_translatedefinition xdef, xx_fin_translatevalues xval
   WHERE  xdef.translation_name = 'XX_CRM_DYN_ALERTER_MASTER'
     AND  xdef.translate_id = xval.translate_id
     AND  TRUNC (SYSDATE) BETWEEN TRUNC (NVL (xval.start_date_active,SYSDATE - 1))
     AND  TRUNC (NVL (xval.end_date_active, SYSDATE + 1))
     AND  xval.source_value5 IS NULL
   UNION
   SELECT xval.source_value1 module_name,
          xval.source_value2 frequency,
          xval.source_value3 bpel_retry,
          xval.source_value4 exclude_exceptions,
          xval.source_value5 last_run_date,
          xval.source_value6 entity_type
    FROM  xx_fin_translatedefinition xdef, xx_fin_translatevalues xval
   WHERE  xdef.translation_name = 'XX_CRM_DYN_ALERTER_MASTER'
     AND  xdef.translate_id = xval.translate_id
     AND  TRUNC (SYSDATE) BETWEEN TRUNC (NVL (xval.start_date_active,SYSDATE - 1))
     AND  TRUNC (NVL (xval.end_date_active, SYSDATE + 1))
     AND  xval.source_value5 IS NOT NULL  
     AND  sysdate -(to_date(xval.source_value5,'DD-MON-RRRR HH24:MI:SS')+xval.source_value2/24)>0;
	 
BEGIN
      -------------------------------------------------------
      -- Launching Child Programs to extract Clawbacks
      -------------------------------------------------------
      FOR lt_programs IN lcu_get_ready_to_run_programs
      LOOP
         BEGIN
            ln_conc_request_id          :=      
                                        fnd_request.submit_request
                                        (application      => g_prog_application,
                                         program          => g_child_prog_executable,
                                         sub_request      => FALSE,
                                         argument1        => lt_programs.module_name,
                                         argument2        => lt_programs.bpel_retry,
                                         argument3        => lt_programs.exclude_exceptions,
                                         argument4        => lt_programs.entity_type
                                        );
            COMMIT;

            IF (ln_conc_request_id = 0)
            THEN
               ROLLBACK;
               fnd_message.set_name     ('XXCRM', 'XX_CRM_0079_DYN_ALRT_PRG_FAIL');
               fnd_message.set_token    ('PRG_NAME', G_CHILD_PROG_NAME);
               fnd_message.set_token    ('SQL_CODE', SQLCODE);
               fnd_message.set_token    ('SQL_ERR', SQLERRM);
               lc_message_data          := fnd_message.get;
               x_retcode                := 1;
               x_errbuf                 := 'Procedure: REPORT_MAIN: ' || lc_message_data;
            END IF;
         END;
      END LOOP;
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;
  fnd_message.set_name           ('XXCRM', 'XX_CRM_0080_DYN_ALRT_UNEXP_ERR');
  fnd_message.set_token          ('SQL_CODE', SQLCODE);
  fnd_message.set_token          ('SQL_ERR', SQLERRM);
  lc_message_data                := fnd_message.get;
  x_retcode                      := 2;
  x_errbuf                       := 'Procedure: REPORT_MAIN: ' || lc_message_data;
END;

END XX_CRM_DYN_ALERTER_PKG;
/

SHOW ERRORS
EXIT;
