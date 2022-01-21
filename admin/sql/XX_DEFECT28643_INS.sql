-- +===========================================================================+
-- |                              Office Depot                                 |
-- |                                                                           |
-- +===========================================================================+
-- | Name         : XX_DEFECT28643_INS.sql                                     |
-- | Rice Id      : DEFECT 28643                                               | 
-- | Description  :                                                            |  
-- | Purpose      : For POD URL translation setup                              |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version    Date          Author               Remarks                      | 
-- |=======    ==========    =================    =============================+
-- |1.0        4-Mar-2014   Sridevi K            Initial Version               |
-- |2.0        6-Mar-2014   Sridevi K            As suggested by Suresh using  |
-- |                                             Old URL for prod              |
-- +===========================================================================+

WHENEVER SQLERROR CONTINUE
SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT SETTING CONTEXT XX_DEFECT28643_INS.sql
PROMPT

Declare
ln_definition_id  number;
begin

dbms_output.put_line('getting translation definition sequence');

SELECT XX_FIN_TRANSLATEDEFINITION_S.NEXTVAL
   INTO   ln_definition_id 
   FROM   DUAL;

dbms_output.put_line('ln_definition_id  '||ln_definition_id );

dbms_output.put_line('inserting data into xx_fin_translatedefinition' );

INSERT INTO xx_fin_translatedefinition
            (translate_id, 
             translation_name, 
             translate_description, 
             related_module, 
             source_field1,
             source_field2, 
             creation_date, 
             created_by,
             last_update_date, 
             last_updated_by, 
             last_update_login,
             start_date_active, 
             enabled_flag, 
             do_not_refresh
            )
     VALUES (ln_definition_id, 
             'XXOD_AR_POD_URL', 
             'Url used in PODCO.java', 
             'AR', 
             'POD_DEV_URL',
             'POD_PROD_URL', 
             SYSDATE, 
             -1, --1870722,
             SYSDATE, 
             -1, --1870722, 
	     -1, --37906601,
             SYSDATE, 
             'Y', 
             'N'
            );

dbms_output.put_line('inserting data into XX_FIN_TRANSLATERESPONSIBILITY' );
INSERT INTO XX_FIN_TRANSLATERESPONSIBILITY
            (translate_id, 
	     responsibility_id, 
	     read_only_flag, 
	     creation_date,
             created_by, 
	     last_update_date, 
	     last_updated_by,
             last_update_login, 
	     security_value_id
            )
     VALUES (ln_definition_id, 
	     52046, 
	     NULL, 
	     SYSDATE,
             -1, --1870722, 
	     SYSDATE, 
	     -1, --1870722,
             -1, --37906601, 
	     XX_FIN_TRANSLATERESPONSIBIL_S.NEXTVAL
            );

dbms_output.put_line('inserting data into XX_FIN_TRANSLATERESPONSIBILITY' );
INSERT INTO XX_FIN_TRANSLATERESPONSIBILITY
            (translate_id, 
	     responsibility_id, 
	     read_only_flag, 
	     creation_date,
             created_by, 
	     last_update_date, 
	     last_updated_by,
             last_update_login, 
	     security_value_id
            )
     VALUES (ln_definition_id, 
             52270, 
	     NULL, 
	     SYSDATE,
             -1, --1870722, 
	     SYSDATE, 
	     -1, --1870722,
             -1, --37906601, 
	     XX_FIN_TRANSLATERESPONSIBIL_S.NEXTVAL
            );

dbms_output.put_line('inserting data into XX_FIN_TRANSLATEVALUES' );
INSERT INTO XX_FIN_TRANSLATEVALUES
            (translate_id,
             source_value1,
             source_value2,
             creation_date, 
             created_by,
             last_update_date, 
             last_updated_by, 
             last_update_login,
             start_date_active, 
             enabled_flag, 
             translate_value_id
            )
     VALUES (ln_definition_id,
             'http://sigcapdev80.uschecomrnd.net/SignatureCapture/BSDInquiry?data=summary|00000000|', 
             'http://sigcap.officedepot.com/SignatureCapture/BSDInquiry?data=summary|00000000|',
             SYSDATE, 
	     -1, --1870722,
             SYSDATE, 
	     -1, --3024347, 
	     -1, --37906634,
             SYSDATE, 
             'Y', 
             XX_FIN_TRANSLATEVALUES_S.NEXTVAL
            );
commit;
end;
/


SHOW ERR


REM=================================================================================================
REM                                   End Of Script
REM=================================================================================================


