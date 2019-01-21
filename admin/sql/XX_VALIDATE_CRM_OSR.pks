create or replace
PACKAGE xx_validate_crm_osr AS

  /*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- |                                        Oracle Consulting                                           |
-- +====================================================================================================+
-- | Name        : XX_VALIDATE_CRM_OSR                                                                  |
-- | Description : This package performs a lookup to ensure the OSR values from AOPS exist              |
-- |               											|
-- |                                                                                                    |
-- |Change Record:                                                                                      |
-- |===============                                                                                     |
-- |Version   Date        Author             Remarks                                                    |
-- |========  =========== ================== ===========================================================|
-- |1.0       03-18-2008  Yusuf Ali          Initial Draft                                              |
-- |                                                                                                    |
-- +====================================================================================================+
*/

  TYPE T_OSR_REC IS RECORD(
      OSR        hz_orig_sys_references.orig_system%TYPE
    , TABLE_NAME hz_orig_sys_references.orig_system_reference%TYPE
  );

  TYPE T_OSR_TABLE IS TABLE OF T_OSR_REC
    INDEX BY BINARY_INTEGER;

   PROCEDURE get_entity_id(
      p_orig_system IN hz_orig_sys_references.orig_system%TYPE
  ,   p_osr_record IN T_OSR_TABLE
  ,   x_owner_table_id OUT hz_orig_sys_references.owner_table_id%TYPE
  ,   x_no_osr OUT VARCHAR2
  ,   x_no_osr_table OUT VARCHAR2
  ,   x_return_status OUT VARCHAR2
  ,   x_msg_count OUT NUMBER
  ,   x_msg_data OUT VARCHAR2
  );

END xx_validate_crm_osr;
/
