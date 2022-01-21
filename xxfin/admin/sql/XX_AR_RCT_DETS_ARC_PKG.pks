SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package xx_ar_rct_dets_arc_pkg
PROMPT Program exits if the creation is not successful

create or replace
PACKAGE XX_AR_RCT_DETS_ARC_PKG AS
-- +===================================================================================+
-- |                    Oracle Consulting                                              |
-- +===================================================================================+
-- | Name       : XXARORDRCTDTLPKS.pls                                                 |
-- | Description: Order Receipt Details Archiving Program                              |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record                                                                      |
-- |==============                                                                     |
-- |Version   Date         Authors              Remarks                                |
-- |========  ===========  ===============      ============================           |
-- |Draft 1A  20-Apr-2011  Sreenivasa Tirumala  Intial Draft Version                   |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- +===================================================================================+

PROCEDURE lp_print (lp_line IN VARCHAR2, lp_both IN VARCHAR2);

-- +=================================================================================+
-- | Name        : ARCHIVING_PROC                                                    |
-- | Description : This procedure will be used to Archive the Order Receipt Details  |
-- |               records based on the Start and End date provided                  |
-- |                                                                                 |
-- | Parameters  : p_date_from                                                       |
-- |               p_date_to                                                         |
-- |                                                                                 |
-- | Returns     : x_errbuf                                                          |
-- |               x_retcode                                                         |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE archiving_proc ( x_errbuf    OUT NOCOPY   VARCHAR2
                         , x_retcode   OUT NOCOPY   NUMBER
                         , p_date_from        VARCHAR2
                         , p_date_to          VARCHAR2
                         , p_no_of_days       NUMBER DEFAULT 720);
                                        
END XX_AR_RCT_DETS_ARC_PKG; 
/
exit;