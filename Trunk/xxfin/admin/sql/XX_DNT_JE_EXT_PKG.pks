create or replace
PACKAGE XX_DNT_JE_EXT_PKG
AS		
-- +============================================================================+
-- |                  Office Depot - Project Simplify                           |
-- |                                                                            |
-- +============================================================================+
-- | Name         : XX_DNT_JE_EXT_PKG                                           |
-- | RICE ID      : R7018                                                       |
-- | Description  : This package is used to extract General Ledger data from    |
-- |                both the US and CA ledgers for given dates to be sent to DNT|
-- |                The default format is .txt                                  |
-- |                                                                            |
-- | Change Record:                                                             |
-- |===============                                                             |
-- |Version   Date              Author              Remarks                     |
-- |======   ==========     =============        =======================        |
-- |  1.0    2015-02-10     Dhanishya Raman       Defect 33316 Initial version. |
-- +============================================================================+

-- +=====================================================================+
-- | Name :  DNT_JE_EXTRACT                                              |
-- | Description :This prodecure will return the required GL data based  | 
-- |              on the dates passed.								     |                                       
-- +=====================================================================+ 
							   
PROCEDURE DNT_JE_EXTRACT(
errbuff	OUT      VARCHAR2
,RETCODE	OUT NUMBER
,p_period_name               IN  VARCHAR2
,p_start_date                IN VARCHAR2
,p_end_date                  IN VARCHAR2
,p_Currency                  IN  VARCHAR2
,p_posted_date                      IN  VARCHAR2
,p_ledger_id                 IN  NUMBER
);
END XX_DNT_JE_EXT_PKG;
/