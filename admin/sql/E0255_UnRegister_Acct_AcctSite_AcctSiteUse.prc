SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_CDH_ADD_ATTR_ENT_REG_B.pls                      |
-- | Description :  CDH Additional Attributes Registration Data Fixes  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       06-Jul-2007 Rajeev Kamath      Initial version - Data Fix|
-- |1.1       25-Jul-2007 Rajeev Kamath      Table Name Changes        |
-- +===================================================================+

-- Delete data for extended attributes related to Customer Account 
delete apps.fnd_objects WHERE obj_name = 'XX_CDH_CUST_ACCOUNT';
delete apps.fnd_tables WHERE table_name = 'XX_CUST_ACCT_EXT_B';
delete apps.fnd_tables WHERE table_name = 'XX_CUST_ACCT_EXT_TL';
delete apps.EGO_OBJECT_EXT_TABLES_B WHERE object_id NOT IN (SELECT object_id FROM fnd_objects);
delete apps.FND_DESCRIPTIVE_FLEXS where descriptive_flexfield_name='XX_CDH_CUST_ACCOUNT';
delete apps.FND_DESCRIPTIVE_FLEXS_TL where descriptive_flexfield_name='XX_CDH_CUST_ACCOUNT';
delete from apps.EGO_FND_DESC_FLEXS_EXT where DESCRIPTIVE_FLEXFIELD_NAME= 'XX_CDH_CUST_ACCOUNT';
delete from apps.EGO_FND_OBJECTS_EXT  where object_name = 'XX_CDH_CUST_ACCOUNT';
delete from apps.FND_LOOKUP_VALUES where LOOKUP_CODE='XX_CDH_CUST_ACCOUNT';


-- Delete data for extended attributes related to Customer Account Sites
delete apps.fnd_objects WHERE obj_name = 'XX_CDH_CUST_ACCT_SITE';
delete apps.fnd_tables WHERE table_name = 'XX_ACCT_SITE_EXT_B';
delete apps.fnd_tables WHERE table_name = 'XX_ACCT_SITE_EXT_TL';
delete apps.EGO_OBJECT_EXT_TABLES_B WHERE object_id NOT IN (SELECT object_id FROM fnd_objects);
delete apps.FND_DESCRIPTIVE_FLEXS where descriptive_flexfield_name='XX_CDH_CUST_ACCT_SITE';
delete apps.FND_DESCRIPTIVE_FLEXS_TL where descriptive_flexfield_name='XX_CDH_CUST_ACCT_SITE';
delete from apps.EGO_FND_DESC_FLEXS_EXT where DESCRIPTIVE_FLEXFIELD_NAME= 'XX_CDH_CUST_ACCT_SITE';
delete from apps.EGO_FND_OBJECTS_EXT  where object_name = 'XX_CDH_CUST_ACCT_SITE';
delete from apps.FND_LOOKUP_VALUES where LOOKUP_CODE='XX_CDH_CUST_ACCT_SITE';




-- Delete data for extended attributes related to Customer Account Site Uses
delete apps.fnd_objects WHERE obj_name = 'XX_CDH_ACCT_SITE_USES';
delete apps.fnd_tables WHERE table_name = 'XX_SITE_USES_EXT_B';
delete apps.fnd_tables WHERE table_name = 'XX_SITE_USES_EXT_TL';
delete apps.EGO_OBJECT_EXT_TABLES_B WHERE object_id NOT IN (SELECT object_id FROM fnd_objects);
delete apps.FND_DESCRIPTIVE_FLEXS where descriptive_flexfield_name='XX_CDH_ACCT_SITE_USES';
delete apps.FND_DESCRIPTIVE_FLEXS_TL where descriptive_flexfield_name='XX_CDH_ACCT_SITE_USES';
delete from apps.EGO_FND_DESC_FLEXS_EXT where DESCRIPTIVE_FLEXFIELD_NAME= 'XX_CDH_ACCT_SITE_USES';
delete from apps.EGO_FND_OBJECTS_EXT  where object_name = 'XX_CDH_ACCT_SITE_USES';
delete from apps.FND_LOOKUP_VALUES where LOOKUP_CODE='XX_CDH_ACCT_SITE_USES';


commit;
/
