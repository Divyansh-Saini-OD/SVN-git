-- $HeadURL: https://svn.na.odcorp.net/od/crm/trunk/xxcrm/admin/sql/XXBI_GROUP_MBR_INFO_MV.vw $

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE MATERIALIZED VIEW APPS.XXBI_SALES_LEADS_MV
  BUILD IMMEDIATE
  USING INDEX 
  REFRESH FAST
  WITH ROWID 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_SALES_LEADS_MV.vw                          |
-- | Description :  MV for Sales Leads                            |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author           Remarks                   |
-- |=======   ==========    =============    ==========================|
-- |1.0       16-Mar-2010   Luis Mazuera     Initial version           |
-- |                                                                   | 
-- +===================================================================+
  AS SELECT
  asl.rowid lead_rowid,
  asl.sales_lead_id,
  asl.lead_number,
  asl.description lead_name,
  asl.customer_id,
  asl.address_id,
  NVL(asl.status_code, 'XX') status_code,
  DECODE(asl.status_open_flag,'Y','O','C') status_category,
  NVL(asl.channel_code, 'XX') channel_code,
  NVL(asl.lead_rank_id, -1)  lead_rank_code,
  NVL(asl.close_reason, 'XX') close_reason,
  asl.currency_code,
  op.opportunity_id,
  op.rowid opportunity_rowid,
  op.creation_date  lead_conversion_date,
  asl.creation_date,
  asl.created_by,
  asl.last_update_date,
  asl.last_updated_by,
  asl.total_amount,
  NVL(asl.source_promotion_id,-1) source_promotion_id
FROM as_sales_leads asl,
     as_sales_lead_opportunity op
WHERE asl.sales_lead_id = op.sales_lead_id (+);
----------------------------------------------------------
-- Grant to XXCRM
----------------------------------------------------------
GRANT ALL ON APPS.XXBI_SALES_LEADS_MV TO XXCRM;

SHOW ERRORS;
EXIT;