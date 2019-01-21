-- $HeadURL: https://svn.na.odcorp.net/od/crm/branches/10.4/xxcrm/admin/sql/XXBI_SLS_OPP_SMRY_MV.tbl $

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE MATERIALIZED VIEW XXBI_SLS_OPP_SMRY_MV
BUILD DEFERRED
REFRESH FORCE
ON DEMAND
WITH  PRIMARY KEY AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_SLS_OPP_SMRY_MV.tbl                           |
-- | Description :  MV for Sales Leads                                 |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author           Remarks                   |
-- |=======   ==========    =============    ==========================|
-- |1.0       06-Apr-2010   Luis Mazuera     Initial version           |
-- |2.0       23-Dec-2010   Gokila T         Modified for CPD Lead     |
-- |                                         Report.                   |
-- |                                                                   |
-- +===================================================================+
SELECT
  mv.STATUS_CODE,
  mv.customer_type,
  trunc(mv.oppty_creation_date) oppty_creation_date,
  mv.CLOSE_REASON_ID,
  mv.SOURCE_PROMOTION_ID,
  AGE.id age_bucket_id,
  mv.resource_id,
  mv.role_id,
  mv.group_id,
  mv.win_probability,
  mv.oppty_created_by,
  mv.sales_stage_id,
  mv.competitor_party_id,
  AMR.id amt_range_id,
  FAMR.id forecast_amt_range_id,
  SRM.id  srm_bucket_id,
  CLS_DATE.id cls_date_bucket_id,
  cast( sum(mv.lead_line_total_amt) as integer ) lead_line_total_amount,
  cast( sum(mv.forecast_amt) as integer ) forecast_total_amount,
  count( distinct mv.lead_line_id) lead_line_count
  ,mv.store_number              -- Added for CPD Report Gokila
FROM XXBI_SALES_OPPTY_FCT_MV mv,
     APPS.XXBI_OPPTY_AGE_BUCKETS_MV AGE,
     APPS.XXBI_OPPTY_AMT_RANGES_DIM_V AMR,
     APPS.XXBI_OPP_FRCST_AMT_RANG_DIM_V FAMR,
     APPS.XXBI_OPP_SRM_RANG_DIM_V srm,
     APPS.XXBI_OPP_CLOSE_DATE_RANG_DIM_V CLS_DATE
WHERE
    ceil(sysdate-mv.oppty_creation_date) between AGE.low_val and AGE.high_val
AND mv.lead_line_total_amt between AMR.low_val and AMR.high_val
AND mv.forecast_amt between FAMR.low_val and FAMR.high_val
AND mv.srm between SRM.low_val and SRM.high_val
AND ceil(mv.decision_date-sysdate)  between CLS_DATE.low_val and CLS_DATE.high_val
AND mv.TERR_DEFN_START_DATE <= sysdate
AND nvl(mv.TERR_DEFN_END_DATE, sysdate+1) > sysdate
AND mv.TERR_RSC_START_DATE <= sysdate
AND nvl(mv.TERR_RSC_END_DATE, sysdate+1) > sysdate
AND mv.TERR_ENT_START_DATE <= sysdate
AND nvl(mv.TERR_ENT_END_DATE, sysdate+1) > sysdate
GROUP BY
  mv.STATUS_CODE,
  mv.customer_type,
  trunc(mv.oppty_creation_date),
  mv.CLOSE_REASON_ID,
  mv.SOURCE_PROMOTION_ID,
  AGE.id,
  mv.resource_id,
  mv.role_id,
  mv.group_id,
  mv.win_probability,
  mv.oppty_created_by,
  mv.sales_stage_id,
  mv.competitor_party_id,
  AMR.id,
  FAMR.id,
  SRM.id,
  CLS_DATE.id
  ,mv.store_number;   -- Added for CPD Report Gokila

----------------------------------------------------------
-- Grant to APPS
----------------------------------------------------------
--GRANT ALL ON XXCRM.XXBI_SLS_OPP_SMRY_MV        TO APPS; -- No need of this line the MV is in APPS Gokila.

SHOW ERRORS;
EXIT;  -- Should we have to comment this Gokila?