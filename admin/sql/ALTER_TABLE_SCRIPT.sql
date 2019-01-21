-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  ALTER_TABL_SCRIPT.sql                                                              |
-- |  Description:  OD: PA Month End Balances Report                                            |
-- |  RICE ID : R1196                                                                           |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         07-Apr-2010  Joe Klein        Initial version                                  |
-- +============================================================================================+
 
--Step 1:

alter table xxfin.xx_pa_month_end_bal_rpt_tbl add task_org_id VARCHAR2(10);
commit;

--Step 2:
alter table xxfin.xx_pa_month_end_bal_rpt_tbl add task_org_name varchar2(100);
commit;

--Step 3:
--alter table xxfin.xx_pa_month_end_bal_rpt_tbl ADD ORGANIZATION_ID NUMBER(15);
--step2:
COMMIT;
--step 4:
--alter table xxfin.xx_pa_month_end_bal_rpt_tbl add NAME VARCHAR2(240);
--Step 5:
COMMIT;
