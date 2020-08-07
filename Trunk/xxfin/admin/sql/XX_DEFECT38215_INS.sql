-- +===========================================================================+
-- |                              Office Depot                                 |
-- |                                                                           |
-- +===========================================================================+
-- | Name         : XX_DEFECT38215_INS.sql                                     |
-- | Rice Id      : DEFECT 38215                                               | 
-- | Description  : Amex to Vantiv Exceptions                                  |  
-- | Purpose      : Translation for mapping exceptions                         |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version    Date          Author               Remarks                      | 
-- |=======    ==========    =================    =============================+
-- |1.0        13-Jul-2016   Avinash Baddam       Initial Version              |
-- +===========================================================================+

WHENEVER SQLERROR CONTINUE
SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT SETTING CONTEXT XX_DEFECT38215_INS.sql
PROMPT

Declare
ln_definition_id  number;
begin

   dbms_output.put_line('getting translation id');

   SELECT    xftd.translate_id
     INTO    ln_definition_id
     FROM    xx_fin_translatedefinition xftd
    WHERE   xftd.translation_name = 'OD_AR_SETTLE_CUST_EXCEPT';

   dbms_output.put_line('ln_definition_id  '||ln_definition_id );

dbms_output.put_line('inserting data into XX_FIN_TRANSLATEVALUES - EXCEPT11' );
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
             '43000865-00001-A0', 
             'EXCEPT11',
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
             '30660493-00001-A0', 
             'EXCEPT11',
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
             '68133400-00001-A0', 
             'EXCEPT11',
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
             '68808383-00001-A0', 
             'EXCEPT11',
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
             '18929267-00001-A0', 
             'EXCEPT11',
             SYSDATE, 
	     -1, 
             SYSDATE, 
	     -1, 
	     -1,
             SYSDATE, 
             'Y', 
             XX_FIN_TRANSLATEVALUES_S.NEXTVAL
            ); 
            
dbms_output.put_line('inserting data into XX_FIN_TRANSLATEVALUES - EXCEPT12');            
 
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
             '41145598-00001-A0', 
             'EXCEPT12',
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
             '41145612-00001-A0', 
             'EXCEPT12',
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
             '41145620-00001-A0', 
             'EXCEPT12',
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
             '41145624-00001-A0', 
             'EXCEPT12',
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
             '41145629-00001-A0', 
             'EXCEPT12',
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
             '41145636-00001-A0', 
             'EXCEPT12',
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
             '41145648-00001-A0', 
             'EXCEPT12',
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
             '41145656-00001-A0', 
             'EXCEPT12',
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
             '41145661-00001-A0', 
             'EXCEPT12',
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
             '41145668-00001-A0', 
             'EXCEPT12',
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
             '41145699-00001-A0', 
             'EXCEPT12',
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
             '41145705-00001-A0', 
             'EXCEPT12',
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
             '41145714-00001-A0', 
             'EXCEPT12',
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
             '41145724-00001-A0', 
             'EXCEPT12',
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
             '41145733-00001-A0', 
             'EXCEPT12',
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
             '41145739-00001-A0', 
             'EXCEPT12',
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
             '41145748-00001-A0', 
             'EXCEPT12',
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
             '41145759-00001-A0', 
             'EXCEPT12',
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
             '41145768-00001-A0', 
             'EXCEPT12',
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
             '41145774-00001-A0', 
             'EXCEPT12',
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
             '41145781-00001-A0', 
             'EXCEPT12',
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
             '41145785-00001-A0', 
             'EXCEPT12',
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
             '41526590-00001-A0', 
             'EXCEPT12',
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
             '41527257-00001-A0', 
             'EXCEPT12',
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
             '41592466-00001-A0', 
             'EXCEPT12',
             SYSDATE, 
	     -1, 
             SYSDATE, 
	     -1, 
	     -1,
             SYSDATE, 
             'Y', 
             XX_FIN_TRANSLATEVALUES_S.NEXTVAL
            );   

dbms_output.put_line('inserting data into XX_FIN_TRANSLATEVALUES - EXCEPT13');            
 
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
             '88545801-00001-A0', 
             'EXCEPT13',
             SYSDATE, 
	     -1, 
             SYSDATE, 
	     -1, 
	     -1,
             SYSDATE, 
             'Y', 
             XX_FIN_TRANSLATEVALUES_S.NEXTVAL
            );
            
dbms_output.put_line('inserting data into XX_FIN_TRANSLATEVALUES - EXCEPT14');            
 
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
             '31353093-00001-A0', 
             'EXCEPT14',
             SYSDATE, 
	     -1, 
             SYSDATE, 
	     -1, 
	     -1,
             SYSDATE, 
             'Y', 
             XX_FIN_TRANSLATEVALUES_S.NEXTVAL
            );            
 
dbms_output.put_line('inserting data into XX_FIN_TRANSLATEVALUES - EXCEPT15');            
 
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
             '30660493-00001-A0', 
             'EXCEPT15',
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
             '18929267-00001-A0', 
             'EXCEPT15',
             SYSDATE, 
	     -1, 
             SYSDATE, 
	     -1, 
	     -1,
             SYSDATE, 
             'Y', 
             XX_FIN_TRANSLATEVALUES_S.NEXTVAL
            );   
 
--commit;
end;
/

SHOW ERR

--=================================================================================================
--                                   End Of Script
--=================================================================================================


