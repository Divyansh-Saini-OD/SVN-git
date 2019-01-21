-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  ALTER_TABLE_SCRIPT.sql                                                              |
-- |  Description:  OD: PA Month End Balances Report                                            |
-- |  RICE ID : R1196                                                                           |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         15-JUL-2014  Kiran Maddala     nitial version                                  |
-- +============================================================================================+
 
--Step 1:

ALTER TABLE xxfin.xx_pa_month_end_bal_rpt_tbl DROP COLUMN organization_id number (15);
commit;

--Step 2:
ALTER TABLE xxfin.xx_pa_month_end_bal_rpt_tbl DROP COLUMN name varchar2(240);
commit;
/
