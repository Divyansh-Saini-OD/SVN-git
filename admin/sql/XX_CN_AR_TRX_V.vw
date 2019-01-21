-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        : XX_CN_AR_TRX_V.vw                                   |
-- | Rice ID     : E1004A_CustomCollections_(TableDesign)              |
-- | Description : XX_CN_AR_TRX Table - Multi Org View Creation Script |
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
PROMPT Creating or Replacing View XX_CN_AR_TRX_V....
PROMPT

CREATE OR REPLACE VIEW xx_cn_ar_trx_v (
       ar_trx_id
      ,booked_date
      ,order_date
      ,salesrep_id
      ,customer_id
      ,inventory_item_id
      ,order_number
      ,line_number
      ,order_hdr_id
      ,order_line_id
      ,invoice_number
      ,invoice_date
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
      ,payment_schedule_id
      ,receivable_application_id
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
SELECT XCAT.ar_trx_id
      ,XCAT.booked_date
      ,XCAT.order_date
      ,XCAT.salesrep_id
      ,XCAT.customer_id
      ,XCAT.inventory_item_id
      ,XCAT.order_number
      ,XCAT.line_number
      ,XCAT.order_hdr_id
      ,XCAT.order_line_id
      ,XCAT.invoice_number
      ,XCAT.invoice_date
      ,XCAT.processed_date
      ,XCAT.processed_period_id
      ,XCAT.org_id
      ,XCAT.event_id
      ,XCAT.revenue_type
      ,XCAT.ship_to_address_id
      ,XCAT.party_site_id      -- Added Party_Site_Id, by Vidhya Valantina Tamilmani on 07-Nov-2007
      ,XCAT.rollup_date
      ,XCAT.source_doc_type
      ,XCAT.source_trx_id
      ,XCAT.source_trx_line_id
      ,XCAT.payment_schedule_id
      ,XCAT.receivable_application_id
      ,XCAT.quantity
      ,XCAT.transaction_amount
      ,XCAT.transaction_currency_code
      ,XCAT.trx_type
      ,XCAT.class_code
      ,XCAT.department_code
      ,XCAT.private_brand
      ,XCAT.cost
      ,XCAT.division
      ,XCAT.revenue_class_id
      ,XCAT.drop_ship_flag
      ,XCAT.margin
      ,XCAT.discount_percentage
      ,XCAT.exchange_rate
      ,XCAT.return_reason_code
      ,XCAT.original_order_source
      ,XCAT.summarized_flag
      ,XCAT.salesrep_assign_flag
      ,XCAT.batch_id
      ,XCAT.trnsfr_batch_id
      ,XCAT.summ_batch_id
      ,XCAT.process_audit_id
      ,XCAT.request_id
      ,XCAT.program_application_id
      ,XCAT.created_by
      ,XCAT.creation_date
      ,XCAT.last_updated_by
      ,XCAT.last_update_date
      ,XCAT.last_update_login
FROM   xx_cn_ar_trx                    XCAT
WHERE  NVL( XCAT.org_id
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
