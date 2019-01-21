-- +===========================================================================+
-- |               Office Depot - Project Simplify                             |
-- |                                                                           |
-- +===========================================================================+
-- | NAME             :  XX_FIN_E0080_TRG                                      |
-- |                                                                           |
-- | DESCRIPTION      :  Create trigger in RA_INTERFACE_LINES_ALL for          |
-- |                     E0080 Performance handling                            |
-- |CHANGE HISTORY:                                                            |
-- |---------------                                                            |
-- |                                                                           |
-- |Version  Date         Author             Remarks                           |
-- |-------  -----------  -----------------  ----------------------------------|
-- |Draft    10-MAR-2008  Raghu              Initial Draft Version             |
-- |1.0      20-DEC-2009  M. Ayyappan        Added TAX additional condition    |
-- |                                         for Defect #2569                  |
-- |                                                                           |
-- |1.1      21-JUN-2011  R.Aldridge         Added new POS batch sources       |
-- |                                         for Defect #12211                 |
-- |                                                                           |
-- |2.0      24-OCT-2012  R.Aldridge         Defect 20687 - Add new Services   |
-- |                                         batch sources                     |
-- +===========================================================================+

CREATE OR REPLACE TRIGGER XX_FIN_E0080_TRG 
BEFORE INSERT
ON ra_interface_lines_all
FOR EACH ROW
   WHEN (NEW.batch_source_name IN ('SALES_ACCT_US', 'SALES_ACCT_CA','POS_US','POS_CA','OD_SERVICES_US','OD_SERVICES_CA') ) 
BEGIN
   IF :NEW.interface_line_attribute3 = 'SUMMARY' THEN  -- Prevents -1 request_id for summary invoices Defect 1221
      :NEW.request_id := NULL;
   ELSIF :NEW.line_type <> 'TAX' THEN                  --Added the TAX condition for defect#2569
      :NEW.request_id := -1;                           
   END IF;         
END;
/

