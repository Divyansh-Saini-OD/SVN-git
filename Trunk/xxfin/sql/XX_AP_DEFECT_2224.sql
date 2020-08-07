
--------------------------------------------------
-- Update per Defect# 2224  
-- Created by:     P.Marco
-- Creation Date:  7/24/2009
-- Reason: Business unable to sweep invoice to next period
-- Same issue orginally reported in SR 7702071.992
--------------------------------------------------




CREATE TABLE XX_AP_DEFECT_2224_BKUP 
AS (select * from ap.AP_INVOICE_DISTRIBUTIONS_ALL
where invoice_id IN (887829,1040240,1296901,1402720)
and distribution_line_number = 2);


update ap.AP_INVOICE_DISTRIBUTIONS_ALL set cancellation_flag = NULL
where invoice_id IN (887829,1040240,1296901,1402720)
and distribution_line_number = 2;

commit;