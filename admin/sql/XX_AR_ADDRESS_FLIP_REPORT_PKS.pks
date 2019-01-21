SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  XX_AR_ADDRESS_FLIP_REPORT_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PACKAGE XX_AR_ADDRESS_FLIP_REPORT_PKG
 AS
 -- +===============================================================================+
-- |                  Office Depot - Project Simplify                              |
-- |                       WIPRO Technologies                                      |
-- +===============================================================================+
-- | Name :      Address flip report for sales tax compliance                      |
-- | Description :   Address flip report for sales tax compliance                  |
-- |                                                                               |
-- |                                                                               |
-- |                                                                               |
-- |Change Record:                                                                 |
-- |===============                                                                |
-- |Version   Date          Author              Remarks                            |
-- |=======   ==========   =============        ===================================|
-- |1.0       02-SEP-2009  Usha Ramachandran        Initial version                |
-- |                                          Created this package for defect #2019|
-- +===============================================================================+
-- +===================================================================+
-- | Name : XX_AR_ADDRESS_FLIP_REPORT_PRC                              |
-- | Description : inseting into temp table                            |
-- |                                                                   |
-- | Parameters : p_process_date_from,p_process_date_to                |
-- |                                                                   |
-- +===================================================================+


   PROCEDURE XX_AR_ADDRESS_FLIP_REPORT_PRC(p_process_date_from  IN DATE
                                          ,p_process_date_to    IN DATE);

END  XX_AR_ADDRESS_FLIP_REPORT_PKG;
/
SHO ERR;