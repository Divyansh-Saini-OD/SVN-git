SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

DROP TABLE xxcrm.xx_crm_wcelg_cust;
DROP TABLE xxcrm.xx_crm_open_bal_temp;
DROP TABLE xxcrm.xx_crm_hierarchy_temp;
DROP TABLE xxcrm.xx_crm_common_delta;
DROP TABLE XX_CRM_COMMON_DELTA_DETAILS;
DROP TABLE xxcrm.XX_CRMAR_INT_LOG;
DROP TABLE xxcrm.xx_crm_custaddr_stg;
DROP TABLE xxcrm.xx_crm_custmast_head_stg;
DROP SEQUENCE xxcrm.xx_crm_common_multithread_s;
DROP SEQUENCE xxcrm.XX_CRMAR_INT_LOG_s;







