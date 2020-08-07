
--------------------------------------------------
-- Update per SR 7702071.992  Defect# 1048
-- Created by:     P.Marco
-- Creation Date:  7/24/2009
-- Reason: Business unable to sweep invoice to next period
--------------------------------------------------




CREATE TABLE XX_AP_SR_7702071_992_BKUP 
AS (select * from ap.AP_INVOICE_DISTRIBUTIONS_ALL
where invoice_id = 314991
and distribution_line_number = 2);


update ap.AP_INVOICE_DISTRIBUTIONS_ALL set cancellation_flag = NULL
where invoice_id = 314991
and distribution_line_number = 2;

commit;