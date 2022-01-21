create or replace 
PACKAGE  XX_CE_ADHOC_RECONCILE_PKG AS

-- +=======================================================================================================+
-- |                            Office Depot - Project Simplify                                            |
-- |                                    Office Depot                                                       |
-- +=======================================================================================================+
-- | Name  : XX_CE_ADHOC_RECONCILE_PKG.pks                                                             |
-- | Description  : This package will update the status from FLOAT to CLEARED in xx_ce.statement_lines     |
-- |                     for given bank rec id                                                             |
-- |Change Record:                                                                                         |
-- |===============                                                                                        |
-- |Version    Date          Author             Remarks                                                    |
-- |=======    ==========    =================  ===========================================================|
-- |1.0        19-FEB-2018   VIVEK KUMAR        Initial version                                            |
-- +=======================================================================================================+


PROCEDURE STATUS_UPDATE (x_errbuff     OUT VARCHAR2
                        ,x_retcode     OUT NUMBER
                        ,p_count IN NUMBER);
                        

  
END XX_CE_ADHOC_RECONCILE_PKG ;
/
SHOW ERR;





