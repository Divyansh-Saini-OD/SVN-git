CREATE OR REPLACE PACKAGE APPS.XX_AR_WC_DISPUTES_TAX_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project FIT                         |
-- |                       Cap Gemini                                    |
-- +=====================================================================+
-- | Name : XX_AR_WC_DISPUTES_TAX_PKG                                    |
-- | RICE ID :  R0536                                                    |
-- | Description :This package is the executable of the wrapper program  |
-- |              that used for submitting the OD: AR Disputes for       |
-- |          Sales Tax Reporting - Webcollect with the desirable    |
-- |              format of the user, and the                            |
-- |              default format is EXCEL and also does the necessary    |
-- |              validations and processing needed for the report R0536 |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1  14-DEC-11      Maheswararao         Initial version         |
-- |                                                                     |
-- +=====================================================================+

   -- +=====================================================================+
-- | Name :  XX_AR_WC_DISPUTES_TAX_PKG                                   |
-- | Description : The procedure will submit the OD: AR Disputes for     |
-- |           Sales Tax Reporting - Webcollect report in the        |
-- |               specified format                                      |
-- | Parameters : p_period_from, p_period_to                             |
-- | Returns :  x_err_buff,x_ret_code                                    |
-- +=====================================================================+
   PROCEDURE DISPUTES_SALES_TAX_PROC (
      x_err_buff      OUT      VARCHAR2
     ,x_ret_code      OUT      NUMBER
     ,p_period_from   IN       VARCHAR2
     ,p_period_to     IN       VARCHAR2
   );
END XX_AR_WC_DISPUTES_TAX_PKG;
/