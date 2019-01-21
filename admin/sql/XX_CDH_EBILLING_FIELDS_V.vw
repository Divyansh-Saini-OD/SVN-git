SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_CDH_EBILLING_FIELDS_V.vm                                 |
-- | Description : View on FINTRANS table for eBilling Fields.                 |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks            	                   |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 15-MAR-2010 Srini Ch      Initial draft version                   |
-- |1.0      19-Jan-2016 Sridevi K     Updated MOD4BR3 - Added Default_Seq     |
-- |1.1      07-Mar-2016 Havish K      R12.2 Retrofit Changes                  | 
-- |1.2      26-MAR-2017 Thilak Ethiraj(CG)  Initial version                   |                                                                        
-- +===========================================================================+

  CREATE OR REPLACE VIEW XX_CDH_EBILLING_FIELDS_V (
       FIELD_ID,
       FIELD_NAME,
       SOURCE_TABLE,
       SOURCE_COLUMN,
       FUNCTION,
       AGGEGATABLE,
       SORTABLE,
       INCLUDE_IN_STANDARD,
       INCLUDE_IN_CORE,
       INCLUDE_IN_DETAIL,
       DATA_TYPE,
       DATA_FORMAT,
       FIELD_LENGTH,
       NON_STD_RECORD_LEVEL,
       USE_IN_FILE_NAME,
       COMMENTS,
       NDT_REC_TYPE_CONST1,
       NDT_REC_TYPE_CONST2,
       NDT_REC_TYPE_CONST3,
       NDT_REC_TYPE_CONST4,
       NDT_REC_TYPE_CONST5,
       NDT_REC_TYPE_CONST6,
       REC_ORDER,
       TARGET_VALUE14,
       TARGET_VALUE15,
       TARGET_VALUE16,
       HEADER_DETAIL,
       AVAI_IN_DATA_EXTRACT,
       REC_TYPE,
       STAGING_TABLE,
	   DEFAULT_SEQ,
	   TARGET_VALUE25
       ) AS 
  SELECT 
       val.source_value1  Field_ID,
       val.source_value2  Field_Name,
       val.source_value3  Source_Table,
       val.source_value4  Source_Column,
       val.source_value5  Function,
       val.source_value6  Aggegatable,
       val.source_value7  Sortable,
       val.source_value8  Include_in_Standard,
       val.source_value9  Include_in_Core,
       val.source_value10 Include_in_Detail,
       val.target_value1  Data_Type,
       val.target_value2  Data_Format,
       val.target_value3  Field_Length,
       val.target_value4  Non_STD_Record_Level,
       val.target_value5  Use_In_File_Name,
       val.target_value6  Comments,
       val.target_value7  NDT_REC_TYPE_CONST1,
       val.target_value8  NDT_REC_TYPE_CONST2,
       val.target_value9  NDT_REC_TYPE_CONST3,
       val.target_value10 NDT_REC_TYPE_CONST4,
       val.target_value11 NDT_REC_TYPE_CONST5,
       val.target_value12 NDT_REC_TYPE_CONST6,
       val.target_value13 REC_ORDER,
       val.target_value14 target_value14,
       val.target_value15 target_value15,
       val.target_value16 target_value16,
       val.target_value17 HEADER_DETAIL,
       val.target_value18 AVAI_IN_DATA_EXTRACT,
       val.target_value19 REC_TYPE,
       val.target_value20 STAGING_TABLE,
	   val.target_value23 DEFAULT_SEQ,
	   val.target_value25 target_value25
FROM   XX_FIN_TRANSLATEDEFINITION def,
       XX_FIN_TRANSLATEVALUES val
where  def.translate_id     = val.translate_id
and    def.translation_name = 'XX_CDH_EBILLING_FIELDS'
and    val.enabled_flag     = 'Y';


SHOW ERRORS;
