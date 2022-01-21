-- +===========================================================================+
-- |                              Office Depot                                 |
-- |                                                                           |
-- +===========================================================================+
-- | Name         : XX_DEFECT36995_INS.sql                                     |
-- | Rice Id      : DEFECT 36995                                               | 
-- | Description  : C0705 Translation to start/stop conc program               |  
-- | Purpose      : Translation to start/stop exception conc program           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version    Date          Author               Remarks                      | 
-- |=======    ==========    =================    =============================+
-- |1.0        04-Apr-2016   Avinash Baddam       Initial Version              |
-- +===========================================================================+

WHENEVER SQLERROR CONTINUE
SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT SETTING CONTEXT XX_DEFECT36995_INS.sql
PROMPT

Declare
ln_definition_id  number;
begin

   dbms_output.put_line('getting translation id');

   SELECT    xftd.translate_id
     INTO    ln_definition_id
     FROM    xx_fin_translatedefinition xftd
    WHERE   xftd.translation_name = 'XX_PROGRAM_CONTROL';

dbms_output.put_line('ln_definition_id  '||ln_definition_id );

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
	     52300, 
	     NULL, 
	     SYSDATE,
             -1, 
	     SYSDATE, 
	     -1, 
             -1, 
	     XX_FIN_TRANSLATERESPONSIBIL_S.NEXTVAL
            );

dbms_output.put_line('inserting data into XX_FIN_TRANSLATEVALUES' );
INSERT INTO XX_FIN_TRANSLATEVALUES
            (translate_id,
             source_value1,
             source_value2,
             target_value1,
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
             'XX_C2T_CNV_CC_EXCEPTIONS', 
             'C0705',
             'N',
             SYSDATE, 
	     -1, 
             SYSDATE, 
	     -1, 
	     -1,
             SYSDATE, 
             'Y', 
             XX_FIN_TRANSLATEVALUES_S.NEXTVAL
            );
commit;
end;
/


SHOW ERR


--=================================================================================================
--                                   End Of Script
--=================================================================================================


