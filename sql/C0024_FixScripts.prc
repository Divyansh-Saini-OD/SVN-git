SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name             :C0024_FixScripts.pls                                |
-- | Description      :One Off Scripts for instance                        |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      12-Jul-2007 Rajeev Kamath      Drop Created View to rename    |
-- |1.1      12-Jul-2007 Rajeev Kamath      Drop generated view metadata   |
-- +=======================================================================+

-- 1.0
-- drop view apps.XX_CDH_AS_EXT_BILLDOCS;


--1.1
--update  
--apps.EGO_FND_DSC_FLX_CTX_EXT
--set agv_name = null where
--DESCRIPTIVE_FLEX_CONTEXT_CODE = 'BILLDOCS'
--and agv_name = 'XX_CDH_AS_EXT_BILLDOCS_V';

--update  
--apps.EGO_FND_DSC_FLX_CTX_EXT
--set agv_name = null where
--DESCRIPTIVE_FLEX_CONTEXT_CODE = 'BILLDOCS'
--and agv_name = 'XX_CDH_A_EXT_BILLDOCS_V';


--1.2
--DELETE FROM 	XXOD_HZ_IMP_ACCOUNTS_STG	WHERE BATCH_ID = 21057 ;
--DELETE FROM 	XXOD_HZ_IMP_ACCT_SITES_STG	WHERE BATCH_ID = 21057 ;
--DELETE FROM 	XXOD_HZ_IMP_ACCT_CNTTROLES_STG	WHERE BATCH_ID = 21057 ;
--DELETE FROM 	XXOD_HZ_IMP_ACCT_CONTACT_STG	WHERE BATCH_ID = 21057 ;
--DELETE FROM 	XXOD_HZ_IMP_ACCT_PAYMETH_STG	WHERE BATCH_ID = 21057 ;
--DELETE FROM 	XXOD_HZ_IMP_ACCOUNT_PROF_STG	WHERE BATCH_ID = 21057 ;
--DELETE FROM 	XXOD_HZ_IMP_ACCT_SITE_USES_STG	WHERE BATCH_ID = 21057 ;
--DELETE FROM 	HZ_IMP_ADDRESSES_INT	WHERE BATCH_ID = 21057 ;
--DELETE FROM 	HZ_IMP_ADDRESSUSES_INT	WHERE BATCH_ID = 21057 ;
--DELETE FROM 	HZ_IMP_CLASSIFICS_INT	WHERE BATCH_ID = 21057 ;
--DELETE FROM 	HZ_IMP_CONTACTPTS_INT	WHERE BATCH_ID = 21057 ;
--DELETE FROM 	XXOD_HZ_IMP_CONTACTPTS_STG	WHERE BATCH_ID = 21057 ;
--DELETE FROM 	HZ_IMP_CONTACTROLES_INT	WHERE BATCH_ID = 21057 ;
--DELETE FROM 	HZ_IMP_CONTACTS_INT	WHERE BATCH_ID = 21057 ;
--DELETE FROM 	HZ_IMP_CREDITRTNGS_INT	WHERE BATCH_ID = 21057 ;
--DELETE FROM 	XXOD_HZ_IMP_CUSTOMER_BANKS_STG	WHERE BATCH_ID = 21057 ;
--DELETE FROM 	XXOD_HZ_IMP_EXT_ATTRIBS_STG	WHERE BATCH_ID = 21057 ;
--DELETE FROM 	HZ_IMP_FINNUMBERS_INT	WHERE BATCH_ID = 21057 ;
--DELETE FROM 	HZ_IMP_FINREPORTS_INT	WHERE BATCH_ID = 21057 ;
--DELETE FROM 	HZ_IMP_PARTIES_INT	WHERE BATCH_ID = 21057 ;
--DELETE FROM 	HZ_IMP_RELSHIPS_INT	WHERE BATCH_ID = 21057 ;


--1.4
--update apps.hz_locations
--set province = 'ON'
--where location_id = 3331;

--delete from xxcrm.XX_CDH_CUST_ACCT_EXT_B
--where cust_account_id IN (
--select cust_account_id from (
--select cust_account_id,n_ext_attr2,c_ext_attr13 
--from XX_CDH_CUST_ACCT_EXT_B 
--group by cust_account_id,n_ext_attr2,c_ext_attr13 
--having count(*) > 1))
--and attr_group_id = 201

--drop index HZ_ORIG_SYS_REFERENCES_N3;
--drop index XXCNV.XXOD_HZ_CUSTOMER_BANKS_INT_N1;
--drop index XXCNV.XXOD_HZ_IMP_ACCT_PROF_INT_N1;
--drop index XXCNV.XXOD_HZ_IMP_ACCT_SITES_N1;
--drop index XXCNV.XXOD_HZ_IMP_ACCT_SUSES_INT_N5;
--drop index XXCNV.XXOD_HZ_IMP_ACCT_SU_INT_N1;
--drop index XXCNV.XXOD_HZ_IMP_ADDRESSES_INT_N1;
--drop index XXCNV.XXOD_HZ_IMP_ADDRESSES_INT_N4;
--drop index XXCNV.XXOD_HZ_IMP_ASU_INT_N2;
--drop index XXCNV.XXOD_HZ_IMP_AS_INT_N1;
--drop index XXCNV.XXOD_HZ_IMP_A_INT_N1;
--drop index XXFIN.XX_FIN_TRANSLATEVALUES_N4;
--drop index XXFIN.XX_FIN_TRANSLATEVALUES_N2;
--drop index XXFIN.XX_FIN_TRANSLATEVALUES_N5;

--drop index xxcnv.XXOD_HZ_IMP_ACCT_SITES_N1;
--drop index xxcnv.XXOD_HZ_IMP_ADDRESSES_INT_N4;
--drop index xxcnv.XXOD_HZ_IMP_ACCT_SUSES_INT_N5;
--drop index xxcnv.XXOD_HZ_IMP_ACCT_SU_INT_N1;

--drop index XXOD_HZ_IMP_CONTACTS_INT_N2;


-- update apps.hz_relationships
-- set status='I', end_Date=sysdate
-- where start_Date < to_Date('21-AUG-2007','DD-MON-YYYY')
-- and relationship_type = 'OD_FAMILY'
-- and rownum <= 1000;

/*
declare
    l_job dba_jobs.job%TYPE;
    p_instance_number    gv$instance.instance_number%TYPE;
    p_sid                v$session.SID%TYPE;
    p_serial             v$session.serial#%TYPE;

begin
    p_sid := 1920;
    p_serial := 59403;
for i in 1 .. 3 loop
DBMS_JOB.submit (job           => l_job
               , what          => 'BEGIN EXECUTE IMMEDIATE ''ALTER SYSTEM KILL SESSION '''''
                                        || p_sid
                                        || ','
                                        || p_serial
                                        || '''''''; '
                                        || '      COMMIT; END;'
                     , INSTANCE      => i
                     , FORCE         => FALSE
                 );
end loop;                               
commit;
end;
*/

/*
declare
    l_job dba_jobs.job%TYPE;
    p_instance_number    gv$instance.instance_number%TYPE;
    p_sid                v$session.SID%TYPE;
    p_serial             v$session.serial#%TYPE;

begin
for i in 1 .. 3 loop
DBMS_JOB.submit (job           => l_job
               , what          => 'BEGIN EXECUTE IMMEDIATE ''dbms_monitor.session_trace_enable(1915, 41814, FALSE, TRUE);'' END;'
                     , INSTANCE      => i
                     , FORCE         => FALSE
                 );
end loop;                               
commit;
end;
*/

/*
declare
    l_job dba_jobs.job%TYPE;
    p_instance_number    gv$instance.instance_number%TYPE;
    p_sid                v$session.SID%TYPE;
    p_serial             v$session.serial#%TYPE;

begin
for i in 1 .. 3 loop
DBMS_JOB.submit (job           => l_job
               , what          => 'begin EXECUTE IMMEDIATE ''begin dbms_monitor.session_trace_enable(1915, 41814, FALSE, TRUE); end;''; END;'
                     , INSTANCE      => i
                     , FORCE         => FALSE
                 );
end loop;
commit;
end;
*/


--update apps.ap_bank_account_uses_all
--set    start_date = to_date('01-JAN-1900','DD-MON-RRRR')
--where  customer_id is not null
--and    external_bank_account_id is not null
--and    request_id is not null
--and    created_by = 2590;

--Insert into apps.fnd_tables
--   (APPLICATION_ID, TABLE_ID, TABLE_NAME, USER_TABLE_NAME, LAST_UPDATE_DATE, LAST_UPDATED_BY, CREATION_DATE, CREATED_BY, LAST_UPDATE_LOGIN, AUTO_SIZE, TABLE_TYPE, INITIAL_EXTENT, NEXT_EXTENT, MIN_EXTENTS, MAX_EXTENTS, PCT_INCREASE, INI_TRANS, MAX_TRANS, PCT_FREE, PCT_USED, DESCRIPTION, HOSTED_SUPPORT_STYLE)
--Values
--   (222, 78670, 'HZ_CUST_SITE_USES_ALL', 'HZ_CUST_SITE_USES_ALL', TO_DATE('02/04/2005 00:00:00', 'MM/DD/YYYY HH24:MI:SS'), 2, TO_DATE('01/01/1990 00:00:00', 'MM/DD/YYYY HH24:MI:SS'), 1, 2, 'Y', 'T', 4, 2048, 1, 50, 0, 3, 255, 10, 40, 'Site uses or business purposes', 'LOCAL');

--create index xxcnv.xx_hz_cust_acct_sites_n8
--on hz_cust_acct_sites_all ( cust_account_id, cust_acct_site_id); 

--drop index xxcnv.xx_hz_cust_acct_sites_n8;

--commit;

/*
create index xxcnv.xx_hz_cust_site_uses_n1
on ar.hz_cust_site_uses_all ( location,site_use_code, status, org_id, cust_acct_site_id );

create index xxcnv.xx_hz_cust_acct_sites_n1
on ar.hz_cust_acct_sites_all ( cust_acct_site_id, cust_account_id, org_id );
*/

Update hz_cust_acconts
Set attribute18 = 'CONTRACT'
Where cust_account_id 
IN
(
65160   ,
64887   ,
93596   ,
107784  ,
75221   ,
93407   ,
77912   ,
69570   ,
65347   ,
77771   ,
69236   ,
51692   ,
88335   ,
87325   ,
93213   ,
108022  ,
103957  ,
107340  ,
67611   ,
71403   ,
102579  ,
51938   ,
51102   ,
74848   ,
95608   ,
95732   ,
64188   ,
91489   ,
52335   ,
2056    ,
85580   ,
108868  ,
101353  ,
96335   ,
79027   ,
100353  ,
79943   ,
53276   ,
2047    ,
73899   ,
78314   ,
90652   ,
78625   ,
65070   ,
95593   ,
96313   ,
76422   ,
85225   ,
91138   ,
77149   ,
84382   ,
84940   ,
93668   ,
64649   ,
52044   ,
78734   ,
63597   ,
108821  ,
95057   ,
99701   ,
71339   ,
88103   ,
63424   ,
63663   ,
71785   ,
51691   ,
68978   ,
98850   ,
89784   ,
87968   ,
73206   ,
74452   ,
84519   ,
63657   ,
66304   ,
75087
);

commit;


--commit;

-- alter system kill session '1912,20709' immediate;
-- alter system kill session '1932,787' immediate;

-- drop index xxcnv.XX_HZ_CUST_ASU_ALL_U1;

-- begin
-- dbms_monitor.session_trace_enable('1915','41814',false,true);
-- end;


-- begin
-- dbms_monitor.session_trace_disable('1915','41814');
-- end;

-- commit;
/
SHOW ERRORS;
