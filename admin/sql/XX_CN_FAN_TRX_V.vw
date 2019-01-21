-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        : XX_CN_FAN_TRX_V.vw                                  |
-- | Rice ID     : E1004A_CustomCollections_(TableDesign)              |
-- | Description : XX_CN_FAN_TRX Table - Multi Org View Creation Script|
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
-- |1.2      07-Nov-2007  Vidhya Valantina Changes due to addition of  |
-- |                                       new column 'Party_Site_Id'  |
-- |                                       in the Extract Tables.      |
-- |                                                                   |
-- +===================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

PROMPT
PROMPT Creating or Replacing View XX_CN_FAN_TRX_V....
PROMPT

CREATE OR REPLACE VIEW xx_cn_fan_trx_v (
       fan_trx_id
      ,booked_date
      ,order_date
      ,salesrep_id
      ,customer_id
      ,inventory_item_id
      ,processed_date
      ,processed_period_id
      ,org_id
      ,event_id
      ,revenue_type
      ,ship_to_address_id
      ,party_site_id       -- Added Party_Site_Id, by Vidhya Valantina Tamilmani on 07-Nov-2007
      ,rollup_date
      ,source_doc_type
      ,source_trx_id
      ,source_trx_line_id
      ,quantity
      ,transaction_amount
      ,transaction_currency_code
      ,trx_type
      ,class_code
      ,department_code
      ,private_brand
      ,cost
      ,division
      ,revenue_class_id
      ,drop_ship_flag
      ,margin
      ,discount_percentage
      ,exchange_rate
      ,return_reason_code
      ,original_order_source
      ,summarized_flag
      ,salesrep_assign_flag
      ,batch_id
      ,trnsfr_batch_id
      ,summ_batch_id
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
SELECT XCFT.fan_trx_id
      ,XCFT.booked_date
      ,XCFT.order_date
      ,XCFT.salesrep_id
      ,XCFT.customer_id
      ,XCFT.inventory_item_id
      ,XCFT.processed_date
      ,XCFT.processed_period_id
      ,XCFT.org_id
      ,XCFT.event_id
      ,XCFT.revenue_type
      ,XCFT.ship_to_address_id
      ,XCFT.party_site_id       -- Added Party_Site_Id, by Vidhya Valantina Tamilmani on 07-Nov-2007
      ,XCFT.rollup_date
      ,XCFT.source_doc_type
      ,XCFT.source_trx_id
      ,XCFT.source_trx_line_id
      ,XCFT.quantity
      ,XCFT.transaction_amount
      ,XCFT.transaction_currency_code
      ,XCFT.trx_type
      ,XCFT.class_code
      ,XCFT.department_code
      ,XCFT.private_brand
      ,XCFT.cost
      ,XCFT.division
      ,XCFT.revenue_class_id
      ,XCFT.drop_ship_flag
      ,XCFT.margin
      ,XCFT.discount_percentage
      ,XCFT.exchange_rate
      ,XCFT.return_reason_code
      ,XCFT.original_order_source
      ,XCFT.summarized_flag
      ,XCFT.salesrep_assign_flag
      ,XCFT.batch_id
      ,XCFT.trnsfr_batch_id
      ,XCFT.summ_batch_id
      ,XCFT.process_audit_id
      ,XCFT.request_id
      ,XCFT.program_application_id
      ,XCFT.created_by
      ,XCFT.creation_date
      ,XCFT.last_updated_by
      ,XCFT.last_update_date
      ,XCFT.last_update_login
FROM   xx_cn_fan_trx                   XCFT
WHERE  NVL( XCFT.org_id
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
