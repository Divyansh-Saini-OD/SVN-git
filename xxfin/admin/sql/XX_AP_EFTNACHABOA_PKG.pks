
CREATE OR REPLACE PACKAGE APPS.XX_AP_EFTNACHABOA_PKG   
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      		Office Depot Organization   		       |
-- +===================================================================+
-- | Name  : XX_AP_EFTNACHABOA_PKG                                     |
-- | Description      :  Package to format EFT NACHA file that will be |
-- |                     sent to Bank of America. This program replaces|
-- |                     XXAPXEFTNACHABOA.rpt                          |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  07-JUN-2008 P.Marco          Initial draft version       |
-- |                                                                   |
-- +===================================================================+

-- +===================================================================+
-- | Name  : EFT_NACHA820_FORMAT                                       |
-- | Description      :                                                |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :p_pay_batch                                           |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

  PROCEDURE  EFT_NACHA820_FORMAT( errbuff OUT varchar2, 
                                  retcode OUT varchar2, 
                                 p_pay_batch IN VARCHAR2);


END XX_AP_EFTNACHABOA_PKG;
/

