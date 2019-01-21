SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- +===========================================================================+
-- | Name        : XX_CDH_EBL_TXT_TRL_FIELDS_V.vw                              |
-- | Description : View on FINTRANS table for eBilling TRL TXT Fields.         |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks            	                   |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 01-APR-2016 Havish K      Initial draft version                   |                                                                     
-- +===========================================================================+

  CREATE OR REPLACE VIEW XX_CDH_EBL_TXT_TRL_FIELDS_V (
       FIELD_ID,
       FIELD_NAME,
       SOURCE_TABLE,
       SOURCE_COLUMN,
       FUNCTION,
       AGGREGATABLE,
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
       NONDT_LINE_FIELD_IND,
       RESERVED_1,
       RESERVED_2,
       HEADER_DETAIL,
       AVAI_IN_DATA_EXTRACT,
       REC_TYPE,
       STAGING_TABLE,
	   ENABLE_CONCATENATE,
	   ENABLE_SPLIT,
	   DEFAULT_SEQ_NUM
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
       val.target_value14 NONDT_LINE_FIELD_IND,
       val.target_value15 RESERVED_1,
       val.target_value16 RESERVED_2,
       val.target_value17 HEADER_DETAIL,
       val.target_value18 AVAI_IN_DATA_EXTRACT,
       val.target_value19 REC_TYPE,
       val.target_value20 STAGING_TABLE,
	   val.target_value21 ENABLE_CONCATENATE,
	   val.target_value22 ENABLE_SPLIT,
	   val.target_value23 DEFAULT_SEQ_NUM
FROM   XX_FIN_TRANSLATEDEFINITION def,
       XX_FIN_TRANSLATEVALUES val
where  def.translate_id     = val.translate_id
and    def.translation_name = 'XX_CDH_EBL_TXT_TRL_FIELDS'
and    val.enabled_flag     = 'Y';

SHOW ERRORS;
