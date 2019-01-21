SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_SFA_TERR_CORRECTION_PKG AUTHID CURRENT_USER
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- +=========================================================================================+
-- | Name        : XX_SFA_TERR_CORRECTION_PKG                                                |
-- | Description : Custom package for data corrections                                       |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0        17-Sep-2007     Sreekanth Rao        Initial version to correct group id in   |
-- |                                                AS_ACCESSES_ALL and as_sales_leads data  |
-- +=========================================================================================+


AS
-- +===================================================================+
-- | Name        : P_Main                                              |
-- |                                                                   |
-- | Description : he procedure to be invoked from the                 |
-- |               concurrent program to fix the data issues           |
-- | Parameters  :                                                     |
-- |               p_from_lead_id                                      |
-- |               p_to_lead_id                                        |
-- |               p_source_system                                     |
-- |               p_commit                                            |
-- +===================================================================+

PROCEDURE P_Main
    (
         x_errbuf            OUT     VARCHAR2
        ,x_retcode           OUT     VARCHAR2
        ,p_commit            IN      VARCHAR2
    );

-- +===================================================================+
-- | Name        : P_Fix_Grp_as_accesses_all                           |
-- |                                                                   |
-- | Description : The procedure to be invoked from the                |
-- |               concurrent program to fix problem with multiple     |
-- |               primary acct-site-uses caused by workers            |
-- |                                                                   |
-- | Parameters  : p_commit                                            |
-- +===================================================================+

END XX_SFA_TERR_CORRECTION_PKG;
/

SHOW ERRORS
--EXIT;
