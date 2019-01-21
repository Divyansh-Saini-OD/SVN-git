-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_CDH_UPD_EGO_Tablels_Script.sql                           |
-- | Description :                                                             |
-- | This script is used to update EGO Tables (new columns) with Default       |
-- | values. Table Names are XX_CDH_CUST_ACCT_EXT_B and XX_CDH_ACCT_SITE_EXT_B.|
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 06-APR-2010 Srini         Initial draft version                   |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+

-------------------------------------------------------------------------------
-- Update Billing Documents New Columns
-------------------------------------------------------------------------------
update XX_CDH_CUST_ACCT_EXT_B xxext set
N_EXT_ATTR18	                       -- BILLDOCS_TERM_ID
  = (select term_id from apps.ra_terms
     where  name = xxext.C_EXT_ATTR14)
, N_EXT_ATTR17 = 0	                      -- IS_PARENT
, N_EXT_ATTR16 = 0	                      -- SEND_TO_PARENT         -- , N_EXT_ATTR15  -- PARENT_DOC_ID
, C_EXT_ATTR16 = 'COMPLETE'	              -- BILLDOCS_STATUS
, N_EXT_ATTR19 = 0                            -- BILLDOC_PROCESS_FLAG
, D_EXT_ATTR9	 = trunc(xxext.creation_date) -- CUST_DOC_REQ_ST_DATE   -- , D_EXT_ATTR10  -- CUST_REQ_END_DATE
, D_EXT_ATTR1	 = trunc(xxext.creation_date) -- BILLDOCS_EFF_FROM_DATE -- , D_EXT_ATTR2   -- BILLDOCS_EFF_TO_DATE
WHERE attr_group_id = 166;

commit;


-------------------------------------------------------------------------------
-- Update Account Sites Extension
-------------------------------------------------------------------------------
update XX_CDH_ACCT_SITE_EXT_B set
C_EXT_ATTR20 = 'Y'
where attr_group_id = 173;

commit;

