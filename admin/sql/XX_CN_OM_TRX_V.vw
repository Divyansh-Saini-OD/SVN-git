-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        : XX_CN_OM_TRX_V.vw                                   |
-- | Rice ID     : E1004A_CustomCollections_(TableDesign)              |
-- | Description : XX_CN_OM_TRX Table - Multi Org View Creation Script |
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
PROMPT Creating or Replacing View XX_CN_OM_TRX_V....
PROMPT

CREATE OR REPLACE VIEW xx_cn_om_trx_v (
       om_trx_id
      ,booked_date
      ,order_date
      ,salesrep_id
      ,customer_id
      ,inventory_item_id
      ,order_number
      ,line_number
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
SELECT XCOT.om_trx_id
      ,XCOT.booked_date
      ,XCOT.order_date
      ,XCOT.salesrep_id
      ,XCOT.customer_id
      ,XCOT.inventory_item_id
      ,XCOT.order_number
      ,XCOT.line_number
      ,XCOT.processed_date
      ,XCOT.processed_period_id
      ,XCOT.org_id
      ,XCOT.event_id
      ,XCOT.revenue_type
      ,XCOT.ship_to_address_id
      ,XCOT.party_site_id       -- Added Party_Site_Id, by Vidhya Valantina Tamilmani on 07-Nov-2007
      ,XCOT.rollup_date
      ,XCOT.source_doc_type
      ,XCOT.source_trx_id
      ,XCOT.source_trx_line_id
      ,XCOT.quantity
      ,XCOT.transaction_amount
      ,XCOT.transaction_currency_code
      ,XCOT.trx_type
      ,XCOT.class_code
      ,XCOT.department_code
      ,XCOT.private_brand
      ,XCOT.cost
      ,XCOT.division
      ,XCOT.revenue_class_id
      ,XCOT.drop_ship_flag
      ,XCOT.margin
      ,XCOT.discount_percentage
      ,XCOT.exchange_rate
      ,XCOT.return_reason_code
      ,XCOT.original_order_source
      ,XCOT.summarized_flag
      ,XCOT.salesrep_assign_flag
      ,XCOT.batch_id
      ,XCOT.trnsfr_batch_id
      ,XCOT.summ_batch_id
      ,XCOT.process_audit_id
      ,XCOT.request_id
      ,XCOT.program_application_id
      ,XCOT.created_by
      ,XCOT.creation_date
      ,XCOT.last_updated_by
      ,XCOT.last_update_date
      ,XCOT.last_update_login
FROM   xx_cn_om_trx                    XCOT
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
