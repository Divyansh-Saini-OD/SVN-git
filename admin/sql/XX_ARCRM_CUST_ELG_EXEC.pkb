CREATE OR REPLACE PACKAGE BODY XX_ARCRM_CUST_ELG_EXEC AS
--+=====================================================================+
--|      Office Depot - Project FIT                                     |
--|   Capgemini/Office Depot/Consulting Organization                    |
--+=====================================================================+
--|Name        :xx_arcrm_cust_elg_exec                                  |
--|RICE        : 							|
--|Description :This Package is used for insert data into staging       |
--|             table and fetch data from staging table to flat file    |
--|                                                                     |
--|            The STAGING xx_cdhar_cust_elg_pkg.will perform the following steps   |
--|                                                                     |
--|             1.It will fetch the records into staging table. The     |
--|               data will be either full or incremental               |
--|                                                                     |
--|             EXTRACT STAGING xx_cdhar_cust_elg_pkg.will perform the following    |
--|                steps                                                |
--|                                                                     |
--|              1.It will fetch the staging table data to flat file    |
--|                                                                     |
--|                                                                     |
--|                                                                     |
--|Change Record:                                                       |
--|==============                                                       |
--|Version    Date           Author                       Remarks       |
--|=======   ======        ====================          =========      |
--|1.00     30-Aug-2011   Balakrishna Bolikonda      Initial Version    |
--|                                                                     |
--|                                                                     |
--|                                                                     |
--|                                                                     |
--+=====================================================================+
--+=====================================================================+
--|  Name       : main                                                  |
--| Description:                                                        |
--|                                                                     |
--| Parameters :  p_actiontype,                                         |
--|               p_filepath                                            |
--|               p_batchlimitp_size                                    |
--|               p_size                                                |
--|               p_delimiter                                           |
--|                                                                     |
--|                                                                     |
--|                                                                     |
--| Returns :   x_return_message                                        |
--|             x_return_code                                           |
--|                                                                     |
--+=====================================================================+
   PROCEDURE main (
      p_errbuf       OUT      VARCHAR2,
      p_retcode      OUT      NUMBER,
      p_actiontype   IN       VARCHAR2,
      p_filepath     IN       VARCHAR2,
      p_batchlimit   IN       NUMBER,
      p_size	     IN       NUMBER,
      p_delimiter    IN       VARCHAR2   ,
      p_last_run_date in    VARCHAR2,
      p_to_run_date   in    VARCHAR2 ,
      p_sample_count  in    number ) IS
      ld_last_run_date date := nvl( to_date(p_last_run_date,'DD-MON-YYYY'), sysdate - 1);
      ld_to_run_date   date := nvl(to_date(p_to_run_date,'DD-MON-YYYY'), sysdate);
   BEGIN

   /***
     dbms_output.put_line ('Before find_Active_AB_cust_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));                 
     fnd_file.put_line (fnd_file.LOG, 'Before find_Active_AB_cust_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
       xx_cdhar_cust_elg_pkg.find_Active_AB_cust_proc (ld_last_run_date, ld_to_run_date, p_batchlimit, p_sample_count);
     fnd_file.put_line (fnd_file.LOG, 'After find_Active_AB_cust_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));
     dbms_output.put_line ('After find_Active_AB_cust_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));                 
      
      
      dbms_output.put_line ( 'Before find_open_balance_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
      fnd_file.put_line (fnd_file.LOG, 'Before find_open_balance_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
      xx_cdhar_cust_elg_pkg.find_open_balance_proc (ld_last_run_date, ld_to_run_date, p_batchlimit, p_sample_count);
      fnd_file.put_line (fnd_file.LOG, 'After find_open_balance_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));         
      dbms_output.put_line ('After find_open_balance_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
      


dbms_output.put_line  ( 'Before lupd_parties_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));
fnd_file.put_line (fnd_file.LOG, 'Before lupd_parties_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));
  xx_cdhar_cust_elg_pkg.lupd_parties_proc (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'After lupd_parties_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
dbms_output.put_line  ( 'After lupd_parties_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           


dbms_output.put_line ( 'Before lupd_ADJUSTMENTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));                                                                                   
fnd_file.put_line (fnd_file.LOG, 'Before lupd_ADJUSTMENTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));                                               
xx_cdhar_cust_elg_pkg.lupd_ADJUSTMENTS_proc (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'After lupd_ADJUSTMENTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));                                               
dbms_output.put_line ( 'After lupd_ADJUSTMENTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));                                               

dbms_output.put_line ( 'Before lupd_CONTACT_POINTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));                                               
fnd_file.put_line (fnd_file.LOG, 'Before lupd_CONTACT_POINTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));                                               
xx_cdhar_cust_elg_pkg.lupd_CONTACT_POINTS_proc (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'After lupd_CONTACT_POINTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
dbms_output.put_line  ( 'Ater lupd_CONTACT_POINTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));                                               


dbms_output.put_line  ( 'Before lupd_CUST_ACCT_SITES_PROC' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
fnd_file.put_line (fnd_file.LOG, 'Before lupd_CUST_ACCT_SITES_PROC' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
xx_cdhar_cust_elg_pkg.lupd_CUST_ACCT_SITES_PROC (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'After lupd_CUST_ACCT_SITES_PROC' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
dbms_output.put_line  ( 'After lupd_CUST_ACCT_SITES_PROC' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           

dbms_output.put_line  ('Before lupd_CUST_PROFILE_AMTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
fnd_file.put_line (fnd_file.LOG, 'Before lupd_CUST_PROFILE_AMTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
xx_cdhar_cust_elg_pkg.lupd_CUST_PROFILE_AMTS_proc (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'After lupd_CUST_PROFILE_AMTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
dbms_output.put_line  ( 'After lupd_CUST_PROFILE_AMTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           

dbms_output.put_line  ( 'Before lupd_CUST_SITE_USES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
fnd_file.put_line (fnd_file.LOG, 'Before lupd_CUST_SITE_USES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
xx_cdhar_cust_elg_pkg.lupd_CUST_SITE_USES_proc (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'After lupd_CUST_SITE_USES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
dbms_output.put_line  ( 'After lupd_CUST_SITE_USES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           

dbms_output.put_line  ( 'Before lupd_CUSTOMER_PROFILES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
fnd_file.put_line (fnd_file.LOG, 'Before lupd_CUSTOMER_PROFILES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
xx_cdhar_cust_elg_pkg.lupd_CUSTOMER_PROFILES_proc (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'After lupd_CUSTOMER_PROFILES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
dbms_output.put_line  ( 'After lupd_CUSTOMER_PROFILES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           


dbms_output.put_line ( 'Before lupd_ORG_CONTACTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
fnd_file.put_line (fnd_file.LOG, 'Before lupd_ORG_CONTACTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
xx_cdhar_cust_elg_pkg.lupd_ORG_CONTACTS_proc (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'After lupd_ORG_CONTACTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
dbms_output.put_line  ( 'After lupd_ORG_CONTACTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           

dbms_output.put_line ('Before lupd_PARTY_SITES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
fnd_file.put_line (fnd_file.LOG, 'Before lupd_PARTY_SITES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
xx_cdhar_cust_elg_pkg.lupd_PARTY_SITES_proc (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'After lupd_PARTY_SITES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
dbms_output.put_line  ( 'After lupd_PARTY_SITES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           

dbms_output.put_line  ( 'Before lupd_RS_GROUP_MEMBERS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
fnd_file.put_line (fnd_file.LOG, 'Before lupd_RS_GROUP_MEMBERS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
xx_cdhar_cust_elg_pkg.lupd_RS_GROUP_MEMBERS_proc (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'After lupd_RS_GROUP_MEMBERS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
dbms_output.put_line  ( 'After lupd_RS_GROUP_MEMBERS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           


dbms_output.put_line  ( 'Before lupd_RS_RESOURCE_EXTNS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
fnd_file.put_line (fnd_file.LOG, 'Before lupd_RS_RESOURCE_EXTNS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
xx_cdhar_cust_elg_pkg.lupd_RS_RESOURCE_EXTNS_proc (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'After lupd_RS_RESOURCE_EXTNS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
dbms_output.put_line  ( 'After lupd_RS_RESOURCE_EXTNS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           


dbms_output.put_line ( 'Before lupd_XX_TM_NAM_TERR_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
fnd_file.put_line (fnd_file.LOG, 'Before lupd_XX_TM_NAM_TERR_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
xx_cdhar_cust_elg_pkg.lupd_XX_TM_NAM_TERR_proc (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'lupd_XX_TM_NAM_TERR_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
dbms_output.put_line  ( 'After lupd_XX_TM_NAM_TERR_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));   

***/

dbms_output.put_line ('Before WJ find_Active_AB_cust_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));                 
     fnd_file.put_line (fnd_file.LOG, 'Before WJ find_Active_AB_cust_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
     xx_cdhar_cust_elg_wj_pkg.find_Active_AB_cust_proc (ld_last_run_date, ld_to_run_date, p_batchlimit, p_sample_count);
     fnd_file.put_line (fnd_file.LOG, 'After WJ find_Active_AB_cust_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));
     dbms_output.put_line ('After WJ find_Active_AB_cust_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));                 
      
      
      dbms_output.put_line ( 'Before WJ find_open_balance_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
      fnd_file.put_line (fnd_file.LOG, 'Before WJ find_open_balance_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
      xx_cdhar_cust_elg_wj_pkg.find_open_balance_proc (ld_last_run_date, ld_to_run_date, p_batchlimit, p_sample_count);
      fnd_file.put_line (fnd_file.LOG, 'After WJ find_open_balance_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));         
      dbms_output.put_line ('After WJ find_open_balance_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
      


dbms_output.put_line  ( 'Before WJ lupd_parties_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));
fnd_file.put_line (fnd_file.LOG, 'Before WJ lupd_parties_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));
  xx_cdhar_cust_elg_wj_pkg.lupd_parties_proc (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'After WJ lupd_parties_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
dbms_output.put_line  ( 'After WJ lupd_parties_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           


dbms_output.put_line ( 'Before WJ lupd_ADJUSTMENTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));                                                                                   
fnd_file.put_line (fnd_file.LOG, 'Before WJ lupd_ADJUSTMENTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));                                               
xx_cdhar_cust_elg_wj_pkg.lupd_ADJUSTMENTS_proc (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'After WJ lupd_ADJUSTMENTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));                                               
dbms_output.put_line ( 'After WJ lupd_ADJUSTMENTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));                                               

dbms_output.put_line ( 'Before WJ lupd_CONTACT_POINTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));                                               
fnd_file.put_line (fnd_file.LOG, 'Before WJ lupd_CONTACT_POINTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));                                               
xx_cdhar_cust_elg_wj_pkg.lupd_CONTACT_POINTS_proc (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'After WJ lupd_CONTACT_POINTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
dbms_output.put_line  ( 'Ater lupd_CONTACT_POINTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));                                               


dbms_output.put_line  ( 'Before WJ lupd_CUST_ACCT_SITES_PROC' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
fnd_file.put_line (fnd_file.LOG, 'Before WJ lupd_CUST_ACCT_SITES_PROC' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
xx_cdhar_cust_elg_wj_pkg.lupd_CUST_ACCT_SITES_PROC (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'After WJ lupd_CUST_ACCT_SITES_PROC' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
dbms_output.put_line  ( 'After WJ lupd_CUST_ACCT_SITES_PROC' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           

dbms_output.put_line  ('Before WJ lupd_CUST_PROFILE_AMTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
fnd_file.put_line (fnd_file.LOG, 'Before WJ lupd_CUST_PROFILE_AMTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
xx_cdhar_cust_elg_wj_pkg.lupd_CUST_PROFILE_AMTS_proc (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'After WJ lupd_CUST_PROFILE_AMTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
dbms_output.put_line  ( 'After WJ lupd_CUST_PROFILE_AMTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           

dbms_output.put_line  ( 'Before WJ lupd_CUST_SITE_USES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
fnd_file.put_line (fnd_file.LOG, 'Before WJ lupd_CUST_SITE_USES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
xx_cdhar_cust_elg_wj_pkg.lupd_CUST_SITE_USES_proc (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'After WJ lupd_CUST_SITE_USES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
dbms_output.put_line  ( 'After WJ lupd_CUST_SITE_USES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           

dbms_output.put_line  ( 'Before WJ lupd_CUSTOMER_PROFILES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
fnd_file.put_line (fnd_file.LOG, 'Before WJ lupd_CUSTOMER_PROFILES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
xx_cdhar_cust_elg_wj_pkg.lupd_CUSTOMER_PROFILES_proc (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'After WJ lupd_CUSTOMER_PROFILES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
dbms_output.put_line  ( 'After WJ lupd_CUSTOMER_PROFILES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           


dbms_output.put_line ( 'Before WJ lupd_ORG_CONTACTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
fnd_file.put_line (fnd_file.LOG, 'Before WJ lupd_ORG_CONTACTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
xx_cdhar_cust_elg_wj_pkg.lupd_ORG_CONTACTS_proc (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'After WJ lupd_ORG_CONTACTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
dbms_output.put_line  ( 'After WJ lupd_ORG_CONTACTS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           

dbms_output.put_line ('Before WJ lupd_PARTY_SITES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
fnd_file.put_line (fnd_file.LOG, 'Before WJ lupd_PARTY_SITES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
xx_cdhar_cust_elg_wj_pkg.lupd_PARTY_SITES_proc (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'After WJ lupd_PARTY_SITES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
dbms_output.put_line  ( 'After WJ lupd_PARTY_SITES_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           

dbms_output.put_line  ( 'Before WJ lupd_RS_GROUP_MEMBERS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
fnd_file.put_line (fnd_file.LOG, 'Before WJ lupd_RS_GROUP_MEMBERS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
xx_cdhar_cust_elg_wj_pkg.lupd_RS_GROUP_MEMBERS_proc (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'After WJ lupd_RS_GROUP_MEMBERS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
dbms_output.put_line  ( 'After WJ lupd_RS_GROUP_MEMBERS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           


dbms_output.put_line  ( 'Before WJ lupd_RS_RESOURCE_EXTNS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
fnd_file.put_line (fnd_file.LOG, 'Before WJ lupd_RS_RESOURCE_EXTNS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
xx_cdhar_cust_elg_wj_pkg.lupd_RS_RESOURCE_EXTNS_proc (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'After WJ lupd_RS_RESOURCE_EXTNS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
dbms_output.put_line  ( 'After WJ lupd_RS_RESOURCE_EXTNS_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           


dbms_output.put_line ( 'Before WJ lupd_XX_TM_NAM_TERR_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
fnd_file.put_line (fnd_file.LOG, 'Before WJ lupd_XX_TM_NAM_TERR_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
xx_cdhar_cust_elg_wj_pkg.lupd_XX_TM_NAM_TERR_proc (ld_last_run_date, ld_to_run_date, p_batchlimit);
fnd_file.put_line (fnd_file.LOG, 'lupd_XX_TM_NAM_TERR_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
dbms_output.put_line  ( 'After WJ lupd_XX_TM_NAM_TERR_proc' || to_char(sysdate, 'YYYY:MM:DD:HH24:MI:SS'));           
        

   END;
END;
/
show errors;
