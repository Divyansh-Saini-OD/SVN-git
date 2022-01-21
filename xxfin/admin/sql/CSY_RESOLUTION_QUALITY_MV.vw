SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  CSY_RESOLUTION_QUALITY_MV.vw                       |
-- | Description :                                                     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |                                                                   | 
-- +===================================================================+
CREATE MATERIALIZED VIEW CSY_RESOLUTION_QUALITY_MV (PERIOD_TYPE, PERIOD_NAME, OWNER_TYPE, INCIDENT_OWNER_ID, INCIDENT_SEVERITY_ID, TOTAL_SR_RESOLVED_1ST_TIME, TOTAL_SR_REOPENED, TOT_SR_REOPENED_ONCE_OR_MORE) REFRESH FORCE ON DEMAND
AS
  SELECT period_type,
    period_name,
    owner_type,
    incident_owner_id,
    incident_severity_id,
    SUM(total_sr_resolved_1st_time) total_sr_resolved_1st_time,
    SUM(total_sr_reopened) total_sr_reopened,
    SUM(tot_sr_reopened_once_or_more) tot_sr_reopened_once_or_more
  FROM csy_resolution_qlty resl,
    csy_periods_v per
  WHERE resl.summary_date BETWEEN per.start_date AND per.end_date
  GROUP BY period_type,
    period_name,
    incident_severity_id,
    owner_type,
    incident_owner_id ;
/



