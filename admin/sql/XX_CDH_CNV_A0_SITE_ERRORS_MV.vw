SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        WIPRO Technologies                         |
-- +===================================================================+
-- | Name             : XX_CDH_CNV_A0_SITE_ERRORS_MV.vw                |
-- | Rice ID          : C0024 Customer Conversion - AOPS               |
-- | Description      : This scipt creates view                        |
-- |                    XX_CDH_CNV_A0_SITE_ERRORS_MV                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       03-Jun-2008 Rajeev Kamath    Intial Version              |
-- |1.1       09-Jun-2008 Rajeev Kamath    Additional Columns          |
-- |1.2       07-Mar-2016 Havish Kasina    R12.2 Retrofit Changes      |
-- +===================================================================+

-- ---------------------------------------------------------------------
--      Create view XX_CDH_CNV_A0_SITE_ERRORS_MV    --
-- ---------------------------------------------------------------------
declare
ct number;
sql_stmt varchar2 (1000);
begin
  sql_stmt := 'drop MATERIALIZED VIEW XX_CDH_CNV_A0_SITE_ERRORS_MV';
  select count(1) into ct
  from dba_mviews where mview_name = 'XX_CDH_CNV_A0_SITE_ERRORS_MV';
  if (ct >= 1) then
      execute immediate sql_stmt;
  end if;
end;
/


CREATE MATERIALIZED VIEW 
XX_CDH_CNV_A0_SITE_ERRORS_MV
PARALLEL 4
NOLOGGING
BUILD DEFERRED
REFRESH 
NEXT ROUND(SYSDATE + 1) + 5/24
AS 
SELECT /*+ PARALLEL */
HA.ADDRESS_LINES_PHONETIC
, HA.ADDRESS1
, HA.ADDRESS2
, HA.ADDRESS3
, HA.ADDRESS4
, HA.CITY
, HA.COUNTRY
, HA.COUNTY
, HA.ATTRIBUTE2
, HA.CREATION_DATE ADDRESS_INT_CREATION_DATE
, HA.DATE_VALIDATED
, HA.LAST_UPDATE_DATE ADDRESS_INT_LAST_UPDATE_DATE
, HA.LAST_UPDATED_BY ADDRESS_INT_LAST_UPDATED_BY
, HA.PARTY_ORIG_SYSTEM_REFERENCE
, HA.POSTAL_CODE
, HA.PRIMARY_FLAG
, HA.PROVINCE
, HA.SITE_ORIG_SYSTEM_REFERENCE
, HA.STATE
, HA.TIMEZONE_CODE
, HA.BATCH_ID EBS_BATCH_ID
, SOCS.AOPS_BATCH_ID
, he.interface_table_name || ' ' || he.message_name || ' ' || he.token1_name || ' ' || he.token1_value ADDRESS_IMPORT_ERROR
, XCL.EXCEPTION_LOG ACCOUNT_SITE_ERROR
, XA.CREATED_BY_MODULE
, XA.CREATION_DATE    ACCOUNT_STG_CREATION_DATE
, XA.LAST_UPDATE_DATE ACCOUNT_STG_LAST_UPDATED_DATE
, XA.LAST_UPDATED_BY ACCOUNT_STG_LAST_UPDATED_BY
, XA.REQUEST_ID
, XA.PARTY_ORIG_SYSTEM
, XA.ACCOUNT_ORIG_SYSTEM_REFERENCE
, XA.CUSTOMER_ATTRIBUTE_CATEGORY
, XA.CUSTOMER_ATTRIBUTE6
, XA.CUSTOMER_ATTRIBUTE8
, XA.CUSTOMER_ATTRIBUTE18
, XA.CUSTOMER_ATTRIBUTE19
, XA.ACCOUNT_NAME
, XA.CUSTOMER_TYPE
, XA.ACCOUNT_ORIG_SYSTEM
, XA.SALES_CHANNEL_CODE
, XA.ORG_ID
, HIBS.CREATION_DATE BATCH_CREATION_DATE
, HCASA.LAST_UPDATE_DATE ACCT_SITE_LAST_UPDATE_DATE
, HCASA.LAST_UPDATED_BY ACCT_SITE_LAST_UPDATED_BY
, HPS.LAST_UPDATE_DATE PARTY_STE_LAST_UPDATE_DATE
, HPS.LAST_UPDATED_BY PARTY_SITE_LAST_UPDATED_BY
FROM
  HZ_IMP_ADDRESSES_INT HA
, HZ_IMP_ERRORS HE
, XXOD_HZ_IMP_ACCOUNTS_STG XA
, XXOD_HZ_IMP_ACCT_SITES_STG XAS
, XX_OWB_CRMBATCH_STATUS SOCS
, HZ_IMP_BATCH_SUMMARY HIBS
, XX_COM_EXCEPTIONS_LOG_CONV XCL
, HZ_CUST_ACCT_SITES_ALL HCASA
, HZ_PARTY_SITES HPS
--, XXOD_HZ_IMP_EXT_ATTRIBS_STG XE
WHERE XA.ACCOUNT_ORIG_SYSTEM_REFERENCE = XAS.ACCOUNT_ORIG_SYSTEM_REFERENCE
AND XAS.PARTY_SITE_ORIG_SYS_REFERENCE = HA.SITE_ORIG_SYSTEM_REFERENCE
AND XA.PARTY_ORIG_SYSTEM_REFERENCE = HA.PARTY_ORIG_SYSTEM_REFERENCE
-- AND XAS.SITE_ORIG_SYSTEM_REFERENCE = XE.INTERFACE_ENTITY_REFERENCE
--AND XE.INTERFACE_ENTITY_NAME = ***
--AND XE.ATTRIBUTE_GROUP_CODE = ***
AND XAS.ACCT_SITE_ORIG_SYS_REFERENCE = HCASA.ORIG_SYSTEM_REFERENCE (+)
AND XAS.PARTY_SITE_ORIG_SYS_REFERENCE = HPS.ORIG_SYSTEM_REFERENCE (+)
AND HA.ERROR_ID = HE.ERROR_ID (+)
AND HA.BATCH_ID = HE.BATCH_ID (+)
AND XAS.INTERFACE_STATUS = 6
AND XAS.RECORD_ID = XCL.RECORD_CONTROL_ID
AND HIBS.BATCH_ID = HA.BATCH_ID
AND HIBS.BATCH_ID = XCL.BATCH_ID
AND HIBS.BATCH_ID = SOCS.EBS_BATCH_ID
AND HIBS.BATCH_ID = XA.BATCH_ID
AND HIBS.BATCH_ID = XAS.BATCH_ID
-- AND HIBS.BATCH_ID = XE.BATCH_ID
AND HA.BATCH_ID = HE.BATCH_ID(+)
AND HE.INTERFACE_TABLE_NAME = 'HZ_IMP_ADDRESSES_INT'
AND HIBS.ORIGINAL_SYSTEM = 'A0'
AND XCL.STAGING_TABLE_NAME = 'XXOD_HZ_IMP_ACCT_SITES_STG'
AND XCL.EXCEPTION_ID = (SELECT MAX(EXCEPTION_ID) FROM XX_COM_EXCEPTIONS_LOG_CONV IXCL
                        WHERE IXCL.BATCH_ID = HIBS.BATCH_ID
                        AND IXCL.STAGING_TABLE_NAME = 'XXOD_HZ_IMP_ACCT_SITES_STG'
                        AND IXCL.RECORD_CONTROL_ID = XCL.RECORD_CONTROL_ID);

SHOW ERROR;