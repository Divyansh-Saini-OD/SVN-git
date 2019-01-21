SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

drop index xxcrm.xxcrm_wcelg_cust_n1;
drop index xxcrm.xxcrm_wcelg_cust_n2;
drop index xxcrm.xxcrm_wcelg_cust_n3;
