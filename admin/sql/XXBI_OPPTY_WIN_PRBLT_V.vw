-- $Id: XXBI_OPPTY_AGE_BUCKETS_MV.vw 69444 2009-04-09 14:44:38Z Indra Varada $
-- $Rev: 69444 $
-- $HeadURL: https://svn.na.odcorp.net/od/crm/trunk/xxcrm/admin/sql/XXBI_OPPTY_WIN_PRBLT_V.vw $
-- $Author: Indra Varada $
-- $Date: 2009-04-09 10:44:38 -0400 (Thu, 09 Apr 2009) $

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW XXBI_OPPTY_WIN_PRBLT_V
AS
SELECT probability_value id, probability_value value
FROM AS_FORECAST_PROB_ALL_VL 
WHERE enabled_flag = 'Y';

/
SHOW ERRORS;
EXIT;