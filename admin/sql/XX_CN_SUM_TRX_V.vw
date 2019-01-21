-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        : XX_CN_SUM_TRX_V.vw                                  |
-- | Rice ID     : E1004A_CustomCollections_(TableDesign)              |
-- | Description : XX_CN_SUM_TRX Table - Multi Org View Creation Script|
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======  ===========  =============    ============================|
-- |Draft 1a 03-Oct-2007  Vidhya Valantina Initial draft version       |
-- |1.0      04-Oct-2007  Vidhya Valantina Baselined after testing     |
-- |1.1      18-Oct-2007  Sarah Justina    Changed view definition to  |
-- |                                       reflect table changes       |
-- +===================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

PROMPT
PROMPT Creating or Replacing View XX_CN_SUM_TRX_V....
PROMPT

CREATE OR REPLACE VIEW xx_cn_sum_trx_v (
       sum_trx_id
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
      ,collect_eligible
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
SELECT XCST.sum_trx_id
      ,XCST.salesrep_id
      ,XCST.rollup_date
      ,XCST.revenue_class_id
      ,XCST.revenue_type
      ,XCST.org_id
      ,XCST.resource_org_id
      ,XCST.division
      ,XCST.salesrep_division
      ,XCST.role_id
      ,XCST.comp_group_id
      ,XCST.processed_date
      ,XCST.processed_period_id
      ,XCST.transaction_amount
      ,XCST.trx_type
      ,XCST.quantity
      ,XCST.transaction_currency_code
      ,XCST.exchange_rate
      ,XCST.discount_percentage
      ,XCST.margin
      ,XCST.salesrep_number
      ,XCST.rollup_flag
      ,XCST.source_doc_type
      ,XCST.object_version_number
      ,XCST.ou_transfer_status
      ,XCST.collect_eligible
      ,XCST.attribute1
      ,XCST.attribute2
      ,XCST.attribute3
      ,XCST.attribute4
      ,XCST.attribute5
      ,XCST.conc_batch_id
      ,XCST.process_audit_id
      ,XCST.request_id
      ,XCST.program_application_id
      ,XCST.created_by
      ,XCST.creation_date
      ,XCST.last_updated_by
      ,XCST.last_update_date
      ,XCST.last_update_login
FROM   xx_cn_sum_trx                   XCST
WHERE  NVL( XCST.org_id
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
