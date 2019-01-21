-- +===========================================================================+
-- |                              Office Depot                                 |
-- |                                                                           |
-- +===========================================================================+
-- | Name         : XX_DEFECT38317_INS.sql                                     |
-- | Rice Id      : DEFECT 38317                                               | 
-- | Description  :                                                            |  
-- | Purpose      : I3101_WMS_Tracking_Data_Interface                          |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version    Date          Author               Remarks                      | 
-- |=======    ==========    =================    =============================+
-- |1.0        06-Mar-2017   Avinash Baddam       Initial Version              |
-- +===========================================================================+

WHENEVER SQLERROR CONTINUE
SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT SETTING CONTEXT XX_DEFECT38317_INS.sql
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

INSERT INTO XX_FIN_TRANSLATEDEFINITION
            (translate_id, 
             translation_name, 
             source_field1,
             target_field1,
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
             'OD_SHIP_OUTBOUND_SERVICE', 
             'SERVICE_PARAM', 
             'SERVICE_VALUE', 
             SYSDATE, 
             -1, 
             SYSDATE, 
             -1, 
	     -1, 
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
	     52308, 
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
             'URL', 
             'http://osbdev01.na.odcorp.net:80/eai/OrderManagement/NoneTradeShipmentTrackingService',
             SYSDATE, 
	     -1, 
             SYSDATE, 
	     -1, 
	     -1,
             SYSDATE, 
             'Y', 
             XX_FIN_TRANSLATEVALUES_S.NEXTVAL
            );
            
INSERT INTO XX_FIN_TRANSLATEVALUES
            (translate_id,
             source_value1,
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
             'USERNAME', 
             'SVC-EBSWS',
             SYSDATE, 
	     -1, 
             SYSDATE, 
	     -1, 
	     -1,
             SYSDATE, 
             'Y', 
             XX_FIN_TRANSLATEVALUES_S.NEXTVAL
            );    
            
INSERT INTO XX_FIN_TRANSLATEVALUES
            (translate_id,
             source_value1,
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
             'PASSWORD', 
             'R8xdw2bs',
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


REM=================================================================================================
REM                                   End Of Script
REM=================================================================================================


