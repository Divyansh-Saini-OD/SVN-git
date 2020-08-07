CREATE OR REPLACE PACKAGE XXEXCELFORMAT AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XXEXCELFORMAT Package Specification                                                |
-- |  Description:     OD: AR Flat Discount Table - Excel                                       |
-- |  Description:     OD: AR Receipt Posting Timing Variances - Excel                          |
-- |  Description:     OD: AR WC Failed Transactions Report - Excel                             |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         05-FEB-2013  DIVYA SIDHAIYAN        Initial version                            |
-- +============================================================================================+

-- +============================================================================================+
-- |  Name: XXEXCELFORMAT.XX_AR_FDT_PROC                                                        |
-- |  Description: This pkg.procedure will extract the report in excel format                   |
-- |  for concurrent program OD: AR Flat Discount Table                                         |
-- |  Name: XXEXCELFORMAT.XX_AR_RPTVRPT_PROC                                                    |
-- |  Description: This pkg.procedure will extract the report in excel format                   |
-- |  for concurrent program OD: AR Receipt Posting Timing Variances                            |
-- |  Name: XXEXCELFORMAT.XXARWCRPT_PROC                                                        |
-- |  Description: This pkg.procedure will extract the report in excel format                   |
-- |  for concurrent program OD: AR WC Failed Transactions Report                               |
-- =============================================================================================|

PROCEDURE XX_AR_FDT_PROC( x_err_buff      OUT VARCHAR2
                         ,x_ret_code      OUT NUMBER
                        );
                        
                        
PROCEDURE XX_AR_RPTVRPT_PROC( x_err_buff      OUT VARCHAR2
                             ,x_ret_code      OUT NUMBER
                             ,p_period_name   IN  VARCHAR2
                             ,p_receipt_type  IN  VARCHAR2
                            );

PROCEDURE XXARWCRPT_PROC(x_err_buff      OUT VARCHAR2
                        ,x_ret_code      OUT NUMBER	
                        ,P_START_DATE IN VARCHAR2
                        ,P_END_DATE IN VARCHAR2						
                         );

                                      

END XXEXCELFORMAT ;

/
SHOW ERROR

