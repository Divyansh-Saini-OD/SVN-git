Rem    -- +=======================================================================+
Rem    -- |               Office Depot - Project Simplify                         |
Rem    -- +=======================================================================+
Rem    -- | Name             : Alter_C0024_Partitioned_Tables_Defaults.sql        |
Rem    -- | Description      : Updates "creation_date".                           |
Rem    -- |                    Needed for partitions to work                      |
rem    -- |                                                                       |
Rem    -- |Change History:                                                        |
Rem    -- |---------------                                                        |
Rem    -- |                                                                       |
Rem    -- |Change Record:                                                         |
Rem    -- |===============                                                        |
Rem    -- |Version   Date         Author             Remarks                      |
Rem    -- |=======   ===========  =================  =============================|
Rem    -- |1.0       02-Dec-2008  Rajeev Kamath      Initial Version              |
Rem    -- +=======================================================================+

update  AR.HZ_IMP_PARTIES_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  AR.HZ_IMP_FINREPORTS_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  AR.HZ_IMP_FINNUMBERS_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  AR.HZ_IMP_CREDITRTNGS_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  AR.HZ_IMP_CONTACTPTS_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  AR.HZ_IMP_ADDRESSES_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  AR.HZ_IMP_ADDRESSUSES_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  AR.HZ_IMP_CLASSIFICS_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  AR.HZ_IMP_RELSHIPS_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  AR.HZ_IMP_CONTACTROLES_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  AR.HZ_IMP_CONTACTS_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_CUSTOMER_BANKS_STG o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_FINNUMBERS_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_FINREPORTS_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_RELSHIPS_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_RELSHIPS_STG o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_CREDITRTNGS_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_ACCOUNT_SITES_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_ACCT_PAYMETH_STG o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_ACCT_PAYMTHD_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_ACCT_PROFILES_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_ACCOUNT_PROF_STG o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_ACCOUNTS_STG o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_ACCOUNTS_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_CUSTOMER_BANKS_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_CONTACTS_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_EXT_ATTRIBS_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_EXT_ATTRIBS_STG o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_PARTIES_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_CONTACTPTS_STG o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_ACCT_CNTROLES_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_ACCT_CNTTROLES_STG o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_ACCT_CONTACTS_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_ACCT_CONTACT_STG o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_ACCT_SITES_STG o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_ACCT_SITEUSES_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_ACCT_SITE_USES_STG o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_ADDRESSES_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_ADDRESSUSES_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_CONTACTROLES_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_CONTACTPTS_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;
update  XXCNV.XXOD_HZ_IMP_CLASSIFICS_INT o set creation_date = (select creation_date from apps.hz_imp_batch_summary hibs where hibs.batch_id = o.batch_id);
commit;



