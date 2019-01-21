SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_CDH_EBL_CONV_VALUES_V.vm                                 |
-- | Description : View to store PAPER to ePDF conversion default values.      |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks            	                   |
-- |======= =========== ============= =========================================|
-- |DRAFT 1 09-NOV-2010 Srini Ch      Initial draft version                    |
-- |    1.2 07-Mar-2016 Havish K      R12.2 Retrofit Changes                   |
-- |                                                                           |
-- +===========================================================================+

  CREATE OR REPLACE VIEW XX_CDH_EBL_CONV_VALUES_V (
       DELIVERY_METHOD,
       ASSOCIATE,
       FILE_PROC_METHOD,
       MAX_FILE_SIZE,
       MAX_TRANS_SIZE,
       ZIP_REQUIRED,
       COMPRESSION_UTILITY,
       COMPRESSION_EXT,
       FILE_EXTENSION,
       LOGO_REQUIRED,
       LOGO_TYPE,
       SALES_CONTACT_NAME,
       SALES_CONTACT_EMAIL,
       SALES_CONTACT_PHONE,
       FIELD_SELECTION,
       COMMENTS,
       NDT_REC_TYPE_CONST7,
       NDT_REC_TYPE_CONST8,
       NDT_REC_TYPE_CONST9,
       NDT_REC_TYPE_CONST10,
       NDT_REC_TYPE_CONST11,
       NDT_REC_TYPE_CONST12,
       NDT_REC_TYPE_CONST13,
       NDT_REC_TYPE_CONST14,
       NDT_REC_TYPE_CONST15,
       NDT_REC_TYPE_CONST16,
       NDT_REC_TYPE_CONST17,
       NDT_REC_TYPE_CONST18,
       NDT_REC_TYPE_CONST19,
       NDT_REC_TYPE_CONST20
       ) AS 
  SELECT 
       val.source_value1  DELIVERY_METHOD,
       val.source_value2  ASSOCIATE,
       val.source_value3  FILE_PROC_METHOD,
       val.source_value4  MAX_FILE_SIZE,
       val.source_value5  MAX_TRANS_SIZE,
       val.source_value6  ZIP_REQUIRED,
       val.source_value7  COMPRESSION_UTILITY,
       val.source_value8  COMPRESSION_EXT,
       val.source_value9  FILE_EXTENSION,
       val.source_value10 LOGO_REQUIRED,
       val.target_value1  LOGO_TYPE,
       val.target_value2  SALES_CONTACT_NAME,
       val.target_value3  SALES_CONTACT_EMAIL,
       val.target_value4  SALES_CONTACT_PHONE,
       val.target_value5  FIELD_SELECTION,
       val.target_value6  COMMENTS,
       val.target_value7  NDT_REC_TYPE_CONST7,
       val.target_value8  NDT_REC_TYPE_CONST8,
       val.target_value9  NDT_REC_TYPE_CONST9,
       val.target_value10 NDT_REC_TYPE_CONST10,
       val.target_value11 NDT_REC_TYPE_CONST11,
       val.target_value12 NDT_REC_TYPE_CONST12,
       val.target_value13 NDT_REC_TYPE_CONST13,
       val.target_value14 NDT_REC_TYPE_CONST14,
       val.target_value15 NDT_REC_TYPE_CONST15,
       val.target_value16 NDT_REC_TYPE_CONST16,
       val.target_value17 NDT_REC_TYPE_CONST17,
       val.target_value18 NDT_REC_TYPE_CONST18,
       val.target_value19 NDT_REC_TYPE_CONST19,
       val.target_value20 NDT_REC_TYPE_CONST20
FROM   XX_FIN_TRANSLATEDEFINITION def,
       XX_FIN_TRANSLATEVALUES val
where  def.translate_id     = val.translate_id
and    def.translation_name = 'XX_CDH_EBL_CONV_VALUES'
and    val.enabled_flag     = 'Y'
and    sysdate between val.START_DATE_ACTIVE and nvl(val.END_DATE_ACTIVE, sysdate +1);


SHOW ERRORS;
