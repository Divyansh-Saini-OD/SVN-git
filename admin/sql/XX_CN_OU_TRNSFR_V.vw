-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        : XX_CN_OU_TRNSFR_V.vw                                |
-- | Rice ID     : E1004A_CustomCollections_(TableDesign)              |
-- | Description : XX_CN_OU_TRNSFR Table - Multi Org View Creation     |
-- |               Script                                              |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======  ===========  =============    ============================|
-- |Draft 1a 03-Oct-2007  Vidhya Valantina Initial draft version       |
-- |1.0      04-Oct-2007  Vidhya Valantina Baselined after testing     |
-- |1.1      18-Oct-2007  Sarah Justina    Added PROCESSED_DATE to view|
-- +===================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

PROMPT
PROMPT Creating or Replacing View XX_CN_OU_TRNSFR_V....
PROMPT

CREATE OR REPLACE VIEW xx_cn_ou_trnsfr_v (
       ou_trnsfr_id
      ,salesrep_id
      ,rollup_date
      ,revenue_class_id
      ,revenue_type
      ,org_id
      ,resource_org_id
      ,division
      ,salesrep_division
      ,role_id
      ,comp_group_id
      ,processed_date
      ,processed_period_id
      ,transaction_amount
      ,trx_type
      ,quantity
      ,transaction_currency_code
      ,exchange_rate
      ,discount_percentage
      ,margin
      ,salesrep_number
      ,rollup_flag
      ,source_doc_type
      ,object_version_number
      ,ou_transfer_status
      ,attribute1
      ,attribute2
      ,attribute3
      ,attribute4
      ,attribute5
      ,conc_batch_id
      ,process_audit_id
      ,request_id
      ,program_application_id
      ,created_by
      ,creation_date
      ,last_updated_by
      ,last_update_date
      ,last_update_login
      )
AS
SELECT XCOT.ou_trnsfr_id
      ,XCOT.salesrep_id
      ,XCOT.rollup_date
      ,XCOT.revenue_class_id
      ,XCOT.revenue_type
      ,XCOT.org_id
      ,XCOT.resource_org_id
      ,XCOT.division
      ,XCOT.salesrep_division
      ,XCOT.role_id
      ,XCOT.comp_group_id
      ,XCOT.processed_date
      ,XCOT.processed_period_id
      ,XCOT.transaction_amount
      ,XCOT.trx_type
      ,XCOT.quantity
      ,XCOT.transaction_currency_code
      ,XCOT.exchange_rate
      ,XCOT.discount_percentage
      ,XCOT.margin
      ,XCOT.salesrep_number
      ,XCOT.rollup_flag
      ,XCOT.source_doc_type
      ,XCOT.object_version_number
      ,XCOT.ou_transfer_status
      ,XCOT.attribute1
      ,XCOT.attribute2
      ,XCOT.attribute3
      ,XCOT.attribute4
      ,XCOT.attribute5
      ,XCOT.conc_batch_id
      ,XCOT.process_audit_id
      ,XCOT.request_id
      ,XCOT.program_application_id
      ,XCOT.created_by
      ,XCOT.creation_date
      ,XCOT.last_updated_by
      ,XCOT.last_update_date
      ,XCOT.last_update_login
FROM   xx_cn_ou_trnsfr                 XCOT
WHERE  NVL( XCOT.org_id
           ,NVL( TO_NUMBER( DECODE( SUBSTRB(USERENV('CLIENT_INFO'),1,1) , ' '
                                   ,NULL, SUBSTRB(USERENV('CLIENT_INFO'),1,10) ) )
                ,-99) ) = NVL( TO_NUMBER( DECODE( SUBSTRB(USERENV('CLIENT_INFO'),1,1), ' '
                                                 ,NULL, SUBSTRB(USERENV('CLIENT_INFO'),1,10) ) )
                              ,-99 );
/
SHOW ERRORS;

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;
