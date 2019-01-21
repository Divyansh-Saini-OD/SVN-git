Rem    -- +=======================================================================+
Rem    -- |               Office Depot - Project Simplify                         |
Rem    -- +=======================================================================+
Rem    -- | Name             : Alter_C0024_Partitioned_Tables_Defaults.sql        |
Rem    -- | Description      : Creates a default on "creation_date".              |
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


alter table AR.HZ_IMP_PARTIES_INT modify (creation_date default sysdate);
alter table AR.HZ_IMP_FINREPORTS_INT modify (creation_date default sysdate);
alter table AR.HZ_IMP_FINNUMBERS_INT modify (creation_date default sysdate);
alter table AR.HZ_IMP_CREDITRTNGS_INT modify (creation_date default sysdate);
alter table AR.HZ_IMP_CONTACTPTS_INT modify (creation_date default sysdate);
alter table AR.HZ_IMP_ADDRESSES_INT modify (creation_date default sysdate);
alter table AR.HZ_IMP_ADDRESSUSES_INT modify (creation_date default sysdate);
alter table AR.HZ_IMP_CLASSIFICS_INT modify (creation_date default sysdate);
alter table AR.HZ_IMP_RELSHIPS_INT modify (creation_date default sysdate);
alter table AR.HZ_IMP_CONTACTROLES_INT modify (creation_date default sysdate);
alter table AR.HZ_IMP_CONTACTS_INT modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_CUSTOMER_BANKS_STG modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_FINNUMBERS_INT modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_FINREPORTS_INT modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_RELSHIPS_INT modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_RELSHIPS_STG modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_CREDITRTNGS_INT modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_ACCOUNT_SITES_INT modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_ACCT_PAYMETH_STG modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_ACCT_PAYMTHD_INT modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_ACCT_PROFILES_INT modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_ACCOUNT_PROF_STG modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_ACCOUNTS_STG modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_ACCOUNTS_INT modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_CUSTOMER_BANKS_INT modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_CONTACTS_INT modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_EXT_ATTRIBS_INT modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_EXT_ATTRIBS_STG modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_PARTIES_INT modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_CONTACTPTS_STG modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_ACCT_CNTROLES_INT modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_ACCT_CNTTROLES_STG modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_ACCT_CONTACTS_INT modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_ACCT_CONTACT_STG modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_ACCT_SITES_STG modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_ACCT_SITEUSES_INT modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_ACCT_SITE_USES_STG modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_ADDRESSES_INT modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_ADDRESSUSES_INT modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_CONTACTROLES_INT modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_CONTACTPTS_INT modify (creation_date default sysdate);
alter table XXCNV.XXOD_HZ_IMP_CLASSIFICS_INT modify (creation_date default sysdate);
