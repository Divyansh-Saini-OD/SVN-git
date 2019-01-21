REM================================================================================================
REM                                 Start Of Script
REM================================================================================================
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +=========================================================================+
-- |               Office Depot - Project Simplify                           |
-- +=========================================================================+
-- | Name        :XX_FA_LOOKUPS                                              |
-- | Description : Script to create lookup definitions                       |
-- |Change History:                                                          |
-- |---------------                                                          |
-- |                                                                         |
-- |Version  Date        Author             Remarks                          |
-- |-------  ----------- -----------------  ---------------------------------|
-- | 1.0     22-JAN-2015 Mark Schmit        Original                         |
-- +=========================================================================+

PROMPT
PROMPT Creating Index....
PROMPT

dbms_output.put_line('Creating Lookup Definitions');

SELECT XX_FIN_TRANSLATEDEFINITION_S.NEXTVAL
   INTO   ln_definition_id 
   FROM   DUAL;

dbms_output.put_line('ln_definition_id  '||ln_definition_id );

dbms_output.put_line('inserting data into xx_fin_translatedefinition' );

INSERT INTO xx_fin_translatedefinition
            (translate_id, 
             translation_name, 
             translate_description, 
             source_field1,
             target_field1,
             target_field2,
             target_field3,
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
             'XXFA_CLASS_CATEGORY', 
             'From the Christina SS', 
             'SAP Class',
             'Major',
             'Minor',
             'SubMinor',
             SYSDATE, 
             -1,
             SYSDATE, 
             -1,
	     -1,
             SYSDATE, 
             'Y', 
             'N'
            );

INSERT INTO xx_fin_translatedefinition
            (translate_id, 
             translation_name, 
             translate_description, 
             source_field1,
             source_field2,
             target_field1,
             target_field2,
             target_field3,
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
             'XXFA_PWC_DEPRN', 
             'From the Richard Tax SS', 
             'Rate',
             'Life',
             'DEPRN_METHOD_CODE',
             'LIFE_IN_MONTHS',
             'PRORATE_CONV_CODE',
             SYSDATE, 
             -1,
             SYSDATE, 
             -1,
	     -1,
             SYSDATE, 
             'Y', 
             'N'
            );

INSERT INTO xx_fin_translatedefinition
            (translate_id, 
             translation_name, 
             translate_description, 
             source_field1,
             source_field2,
             target_field1,
             target_field2,
             target_field3,
             target_field4,
             target_field5,
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
             'XXFA_SAP_EXP_LOCATIONS', 
             'From the BR1425 SS', 
             'Company Code',
             'Cost Center',
             'Location Value',
             'Company Segment',
             'Cost Center Segment',
             'Location Segment',
             'LOB Segment',
             SYSDATE, 
             -1,
             SYSDATE, 
             -1,
	     -1,
             SYSDATE, 
             'Y', 
             'N'
            );
             
insert into XX_COM_CONVERSIONS_CONV (  
             CONVERSION_ID,
             CONVERSION_CODE,
             BATCH_SIZE,
             EXTRACT_OR_LOAD,
             SYSTEM_CODE,
             CREATED_BY,
             CREATION_DATE,
             LAST_UPDATED_BY,
             LAST_UPDATED_DATE)
     values (2000, 
             'C0626', 
             5000, 
             'L', 
             'U1SAP',
             -1, 
             sysdate, 
             -1, 
             sysdate
            );
             
insert into XX_COM_SYSTEM_CODES_CONV (
             system_code, 
             system_name, 
             description, 
             system_platform, 
             country_code, 
             application, 
             created_by, 
             creation_date, 
             last_updated_by, 
             last_update_date)
     values ('U1SAP',
             'SAP',
             'OD North SAP Fixed Asset Management System',
             'Oracle/Linux',
             'U1',
             'EBS',
             -1, 
             sysdate, 
             -1, 
             sysdate
            );

SHOW ERRORS;

REM================================================================================================
REM                                 Start Of Script
REM================================================================================================