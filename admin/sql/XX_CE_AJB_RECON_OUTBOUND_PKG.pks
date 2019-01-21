 
--WHENEVER SQLERROR CONTINUE 
REM ============================================================================
REM Create the package:
REM ============================================================================
PROMPT Creating package APPS.XX_CE_AJB_RECON_OUTBOUND_PKG . . . 
CREATE OR REPLACE PACKAGE XX_CE_AJB_RECON_OUTBOUND_PKG 
-- +===================================================================+ 
-- |                  Office Depot - Project Simplify                  | 
-- |                       Providge  Consulting                        | 
-- +===================================================================+ 
-- | Name             :   XX_CE_AJB_RECON_OUTBOUND_PKG                 | 
-- | Description      :                                                | 
-- |===============                                                    | 
-- |Version   Date         Author              Remarks                 | 
-- |=======   ===========  ================    ========================| 
-- |1.0       19-Mar-2008  Sarat Uppalapati    Initial version         | 
-- |                                                                   | 
-- |                                                                   | 
-- +===================================================================+ 
AS 
-- +===================================================================+ 
-- |         Name : XX_CE_RTD_998                                      | 
-- | Description :  This procedure is creating data file for           |    
-- |     Reconciliation Transaction Detail Records for 998             | 
-- |                                                                   | 
-- |                                                                   | 
-- | Program:                                                          | 
-- |   Parameters: p_errbuff, p_retcode ,p_trans_date,p_bank_rec_id    | 
-- |                                                                   | 
-- +===================================================================+   
PROCEDURE XX_CE_RTD_998 ( p_errbuf  VARCHAR2
                          ,p_retcode VARCHAR2 
                          ,p_trans_date VARCHAR2
                          ,p_bank_rec_id VARCHAR2);
                          
-- +===================================================================+ 
-- |         Name : XX_CE_RTD_998                                      | 
-- | Description :  This procedure is creating data file for           |    
-- |     Reconciliation Transaction Detail Records for 996             | 
-- |                                                                   | 
-- |                                                                   | 
-- | Program:                                                          | 
-- |   Parameters: p_errbuff, p_retcode ,p_trans_date, p_bank_rec_id   | 
-- |                                                                   | 
-- +===================================================================+   
PROCEDURE XX_CE_RTD_996 ( p_errbuf  VARCHAR2
                          ,p_retcode VARCHAR2 
                          ,p_trans_date VARCHAR2
                          ,p_bank_rec_id VARCHAR2);  
                          
-- +===================================================================+ 
-- |         Name : XX_CE_RTD_999                                      | 
-- | Description :  This procedure is creating data file for           |    
-- |     Reconciliation Store Fee Records for 999                      | 
-- |                                                                   | 
-- |                                                                   | 
-- | Program:                                                          | 
-- |   Parameters: p_errbuff, p_retcode ,p_trans_date, p_bank_rec_id   | 
-- |                                                                   | 
-- +===================================================================+   
PROCEDURE XX_CE_RTD_999 ( p_errbuf  VARCHAR2
                          ,p_retcode VARCHAR2 
                          --,p_trans_date VARCHAR2
                          ,p_bank_rec_id VARCHAR2
                          );                                                   
                       
END XX_CE_AJB_RECON_OUTBOUND_PKG;
/
