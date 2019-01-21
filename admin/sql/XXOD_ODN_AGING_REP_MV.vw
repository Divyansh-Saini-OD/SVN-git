-- +==========================================================================+
-- |                  Office Depot - OD North Conversion                      |
-- +==========================================================================+
-- | NAME        : XXOD_ODN_AGING_REP_MV.vw                                   |
-- | RICE#       :                                                            |                                          
-- | DESCRIPTION : Create the MAteralized view for OD North Aging Report for  |
-- |               better    performance                                      |
-- |                            .                                             |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ===========  =============        ==============================|
-- | V1.0     19-FEB-2018  Punit Gupta          Initial version               |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

CREATE MATERIALIZED VIEW XXOD_ODN_AGING_REP_MV
BUILD IMMEDIATE
USING INDEX
ENABLE QUERY REWRITE
AS SELECT distinct HCA.cust_account_id
FROM AR.HZ_CUST_ACCOUNTS HCA , XXFIN.XXOD_OMX_CNV_AR_TRX_STG_HIST STG
WHERE HCA.ORIG_SYSTEM_REFERENCE = STG.ACCT_NO||'-CONV';
   
   COMMENT ON MATERIALIZED VIEW XXOD_ODN_AGING_REP_MV  IS 'snapshot table for snapshot APPS.XXOD_ODN_AGING_REP_MV';

SHOW ERRORS;
EXIT;