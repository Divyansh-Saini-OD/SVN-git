SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XXOD_CDH_AOPS_CUST_PKG
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                Oracle NAIO Consulting Organization                  |
-- +=====================================================================+
-- | Name        :  XXOD_CDH_AOPS_CUST_PKG.pkb                           |
-- | Description :  Retrieving AOPS Customer Information                 |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version     Date          Author              Remarks                |
-- |========  ===========  ==================  ==========================|
-- |DRAFT 1a  03-Mar-2009  Sathya Prabha Rani   Initial draft version    |
-- |1.1       05-Jan-2016  Manikant Kasu        Removed schema alias as  | 
-- |                                             part of GSCC R12.2.2    |
-- |                                              Retrofit               |
-- +=====================================================================+
AS
-----------------------------
--Declaring global variables
-----------------------------
     v_rowcount_aops                     PLS_INTEGER;
     v_bulk_coll_lmt_aops_cust           PLS_INTEGER := 100;
     gc_db_link                          VARCHAR2(2000);
     gn_custcnt                          NUMBER :=0;
     gn_custsitecnt                      NUMBER :=0;
     gn_created_by                       NUMBER := fnd_global.user_id;
     gn_last_updated_by                  NUMBER := fnd_global.user_id;
     gn_batch_id                         NUMBER := to_number(to_char(sysdate,'MMDDYY'));
     gd_creation_date                    DATE := sysdate;
     gd_last_update_date                 DATE := sysdate;
-- +===================================================================+
-- | Name  : WRITE_OUT                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program output file                            |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE write_out(
                    p_message IN VARCHAR2
                   )
IS
BEGIN
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);
END write_out;
-- +===================================================================+
-- | Name  : WRITE_LOG                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program log file                               |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE write_log(
                    p_message IN VARCHAR2
                   )
IS
BEGIN
   FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);
END write_log;
PROCEDURE insert_acct_data (
 lt_aops_cust_info_tab lt_racoondta_fcu000p
)
AS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
FOR i in lt_aops_cust_info_tab.first..lt_aops_cust_info_tab.last
 LOOP
INSERT INTO xxod_hz_summary (batch_id,
                                       account_number,
                                       account_name,
                                       account_status,
                                       creation_date,
                                       last_update_date,
                                       created_by,
                                       last_updated_by)
                       VALUES (gn_batch_id,
                               lt_aops_cust_info_tab(i).fcu000p_customer_id,
                               lt_aops_cust_info_tab(i).fcu000p_business_name,
                               'A',
                               gd_creation_date,
                               gd_last_update_date,
                               gn_created_by,
                               gn_last_updated_by);
END LOOP;
COMMIT;
END insert_acct_data;
PROCEDURE insert_cdh_inactive_cust (
 lt_aops_cust_info_tab lt_racoondta_cust,
 p_status              varchar2
)
AS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
FOR i in lt_aops_cust_info_tab.first..lt_aops_cust_info_tab.last
 LOOP
INSERT INTO xxod_hz_summary (batch_id,
                                       account_number,
                                       account_name,
                                       account_status,
				       customer_type,
                                       creation_date,
                                       last_update_date,
                                       created_by,
                                       last_updated_by)
                       VALUES (gn_batch_id,
                               lt_aops_cust_info_tab(i).fcu000p_customer_id,
                               lt_aops_cust_info_tab(i).fcu000p_business_name,
                               p_status,
                               decode(lt_aops_cust_info_tab(i).FCU000P_CONT_RETAIL_CODE,
				      'C', 'CONTRACT',
				      'R', 'DIRECT'),
                               gd_creation_date,
                               gd_last_update_date,
                               gn_created_by,
                               gn_last_updated_by);
END LOOP;
COMMIT;
END insert_cdh_inactive_cust;
-- +===================================================================+
-- | Name  : Get_AOPS_Cust_Info_Proc                                   |
-- |                                                                   |
-- | Description:       This Procedure will get the active AOPS        |
-- |                    customers that are not present in ebiz         |
-- |                    and update the xxod_summary table with the     |
-- |                    information and returns the count.             |
-- +===================================================================+
PROCEDURE get_aops_cust_info_proc
     (x_errbuf          OUT NOCOPY  VARCHAR2 ,
      x_retcode         OUT NOCOPY  VARCHAR2
     )
AS
----------------------------
--Declaring local Variables
----------------------------
     TYPE gt_aops_cur_type        IS REF CURSOR;
     gt_aops_cur                  gt_aops_cur_type;
     l_sql_query                  VARCHAR2(4000);
     ln_count                     NUMBER := 0;
BEGIN
       -- March 22nd changed order of cols selected: business_name followed by retail_code
       l_sql_query := q'[SELECT  RFCUST.fcu000p_customer_id, RFCUST.fcu000p_business_name , RFCUST.fcu000p_cont_retail_code FROM RACOONDTA.FCU000P@]';
       l_sql_query := l_sql_query||gc_db_link;
       l_sql_query := l_sql_query||q'[ RFCUST
               WHERE  RFCUST.fcu000p_delete_flag = 'A'
               AND NOT EXISTS (
                  SELECT  1  FROM  hz_cust_accounts
                  WHERE  orig_system_reference = to_char(LPAD(RFCUST.fcu000p_customer_id,8,0) || '-00001-A0')
                  AND status = 'A')]';
  OPEN gt_aops_cur FOR l_sql_query;
  LOOP
   FETCH gt_aops_cur BULK COLLECT
   INTO lt_racoondta_cust_tab LIMIT 500;
    ln_count := ln_count + lt_racoondta_cust_tab.count;
    IF lt_racoondta_cust_tab.COUNT = 0 THEN
        EXIT;
    END IF;
       insert_cdh_inactive_cust (
          lt_racoondta_cust_tab,
          'A'
        );
    END LOOP;
    CLOSE gt_aops_cur;
  COMMIT;
  gn_custcnt := ln_count;
  WRITE_LOG('Active AOPS Inactive EBS Cust Count: ' || gn_custcnt);
  NULL;
 EXCEPTION
   WHEN OTHERS THEN
       WRITE_LOG('Unexpected Error in procedure Get_AOPS_Cust_Info_Proc - Error - '||SQLERRM);
       x_errbuf := 'Unexpected Error in procedure Get_AOPS_Cust_Info_Proc - Error - '||SQLERRM;
       x_retcode := 2;
END Get_AOPS_Cust_Info_Proc;

PROCEDURE Insert_Acct_Site_Data (
                                  lt_aops_cust_site_tab   lt_racoondta_fcu001p,
                                  p_status                varchar2
                                 )
 AS
 
   lv_st_cntry                     VARCHAR2(60);
  
 PRAGMA AUTONOMOUS_TRANSACTION;
 
 BEGIN
 
       FOR i in lt_aops_cust_site_tab.first..lt_aops_cust_site_tab.last
       LOOP
           
           lv_st_cntry := lt_aops_cust_site_tab(i).fcu001p_state ||' , '||lt_aops_cust_site_tab(i).fcu001p_country_code;
 
       
           INSERT INTO xxod_hz_summary (batch_id,
                                             account_number,
                                             account_name,
                                             attribute3,
                                             address1,
                                             address2,
                                             city,
                                             state,
                                             postal_code,
                                             creation_date,
                                             last_update_date,
                                             created_by,
                                             last_updated_by)
                VALUES (gn_batch_id,
                        lt_aops_cust_site_tab(i).fcu001p_customer_id,
                        lt_aops_cust_site_tab(i).fcu001p_business_name,
                        p_status, -- status
                        lt_aops_cust_site_tab(i).fcu001p_street_address1,
                        lt_aops_cust_site_tab(i).fcu001p_street_address2,
                        lt_aops_cust_site_tab(i).fcu001p_city,
                        lv_st_cntry, 
                        lt_aops_cust_site_tab(i).fcu001p_zip,
                        gd_creation_date,
                        gd_last_update_date,
                        gn_created_by,
                        gn_last_updated_by);
                       
                       lv_st_cntry := null;
       END LOOP;
       
       COMMIT;
       
 END Insert_Acct_Site_Data;
-- +===================================================================+
-- | Name  : Get_AOPS_Cust_Site_Info_Proc                              |
-- |                                                                   |
-- | Description:       This Procedure will get the active AOPS        |
-- |                    customers that are not present in ebiz         |
-- |                    and update the xxod_summary table with the     |
-- |                    information and returns the count.             |
-- +===================================================================+


PROCEDURE Get_AOPS_Cust_Site_Info_Proc
     (x_errbuf          OUT NOCOPY  VARCHAR2 ,
      x_retcode         OUT NOCOPY  VARCHAR2
     )

AS

----------------------------
--Declaring local Variables
----------------------------


  TYPE gt_aops_site_cur_type          IS REF CURSOR;
  gt_aops_site_cur                    gt_aops_site_cur_type;

  ln_row                              NUMBER := 0;
  ln_count                            NUMBER := 0;
  l_sql_query                         VARCHAR2(4000);
 

 BEGIN

   
       l_sql_query := 
            q'[SELECT 
              RFCUST.fcu001p_customer_id,
              RFCUST.fcu001p_business_name,
              RFCUST.fcu001p_street_address1,
              RFCUST.fcu001p_street_address2,
              RFCUST.fcu001p_city,
              RFCUST.fcu001p_state,
              RFCUST.fcu001p_country_code,
              to_char(RFCUST.fcu001p_zip)  
              FROM   RACOONDTA.FCU001P@]';
              
       l_sql_query :=   l_sql_query||gc_db_link ;

       l_sql_query :=   l_sql_query|| q'[ RFCUST 
                       WHERE  nvl(trim(RFCUST.FCU001P_SHIPTO_STS),'A') = 'A'
                       AND    NOT EXISTS (
                           SELECT  1  FROM  HZ_CUST_ACCT_SITES_ALL
                           WHERE  orig_system_reference = to_char(LPAD(RFCUST.fcu001p_customer_id,8,0) || '-00001-A0')
                           AND status = 'A')]'; 
                           
                         
                      
 
  
       OPEN gt_aops_site_cur FOR l_sql_query;
     
       LOOP
        
         FETCH gt_aops_site_cur BULK COLLECT
         INTO lt_aops_cust_site_tab LIMIT 500;
            ln_count := ln_count + lt_aops_cust_site_tab.count; 
         IF lt_aops_cust_site_tab.COUNT = 0 THEN
             EXIT;
         END IF; 
     
         Insert_Acct_Site_Data ( lt_aops_cust_site_tab, 'A' );
        
      
       END LOOP;
       CLOSE gt_aops_site_cur;
    
       gn_custsitecnt := ln_count;
    
       WRITE_LOG('ln_count : '||ln_count);
       WRITE_LOG('gn_custsitecnt: ' || gn_custsitecnt);
     
 
       COMMIT;
  
   
   EXCEPTION
     WHEN OTHERS THEN
         WRITE_LOG('Unexpected Error in procedure Get_AOPS_Cust_Site_Info_Proc - Error - '||SQLERRM);
         x_errbuf := 'Unexpected Error in procedure Get_AOPS_Cust_Site_Info_Proc - Error - '||SQLERRM;
         x_retcode := 2;

 END Get_AOPS_Cust_Site_Info_Proc;
 
 PROCEDURE Get_AOPS_ISite_Info_Proc
     (x_errbuf          OUT NOCOPY  VARCHAR2 ,
      x_retcode         OUT NOCOPY  VARCHAR2
     )

AS

----------------------------
--Declaring local Variables
----------------------------


  TYPE gt_aops_site_cur_type          IS REF CURSOR;
  gt_aops_site_cur                    gt_aops_site_cur_type;

  ln_row                              NUMBER := 0;
  ln_count                            NUMBER := 0;
  l_sql_query                         VARCHAR2(4000);
 

 BEGIN

         l_sql_query := q'[select 1
			  from   RACOONDTA.FCU001P@]';
        l_sql_query := l_sql_query || gc_db_link ; 
        l_sql_query := l_sql_query || q'[ RFADR
                       WHERE nvl(trim(RFADR.FCU001P_SHIPTO_STS),'A') = 'A'
                       AND   cas.orig_system_reference = to_char(LPAD(RFADR.fcu001p_customer_id,8,0) || '-00001-A0') )]' ; 

        l_sql_query := q'[select hca.account_number,
                                 hzp.party_name,
                                 hzl.address1,
                                 hzl.address2,
                                 hzl.city,
                                 hzl.state,
                                 hzl.country,
                                 hzl.postal_code
        		  from	HZ_CUST_ACCT_SITES_ALL   cas,
                                hz_parties               hzp,
                                hz_party_sites           hps,
                                hz_locations             hzl,
                                hz_cust_accounts         hca
                          where cas.status = 'A'
                          and   cas.cust_account_id = hca.cust_account_id
                          and   cas.party_site_id   = hps.party_site_id
                          and   hps.party_id        = hzp.party_id
                          and   hps.location_id     = hzl.location_id
                          and	not exists (]' || l_sql_query;
   
  
       OPEN gt_aops_site_cur FOR l_sql_query;
     
       LOOP
        
         FETCH gt_aops_site_cur BULK COLLECT
         INTO lt_aops_cust_site_tab LIMIT 500;
            ln_count := ln_count + lt_aops_cust_site_tab.count; 
         IF lt_aops_cust_site_tab.COUNT = 0 THEN
             EXIT;
         END IF; 
     
         Insert_Acct_Site_Data ( lt_aops_cust_site_tab, 'I' );
         
       END LOOP;
       CLOSE gt_aops_site_cur;
    
       gn_custsitecnt := ln_count;
    
       WRITE_LOG('ln_count : '||ln_count);
       WRITE_LOG('gn_custsitecnt: ' || gn_custsitecnt);
     
       COMMIT;
  
   EXCEPTION
     WHEN OTHERS THEN
         WRITE_LOG('Unexpected Error in procedure Get_AOPS_ISite_Info_Proc - Error - '||SQLERRM);
         x_errbuf := 'Unexpected Error in procedure Get_AOPS_ISite_Info_Proc - Error - '||SQLERRM;
         x_retcode := 2;

 END Get_AOPS_ISite_Info_Proc;
 
--- Added by Kalyan  active AOPS - inactive CDH  customers  Start
PROCEDURE get_cdh_inactive_cust
     (x_errbuf          OUT NOCOPY  VARCHAR2 ,
      x_retcode         OUT NOCOPY  VARCHAR2
     )
AS
----------------------------
--Declaring local Variables
----------------------------
     TYPE gt_aops_cur_type        IS REF CURSOR;
     gt_aops_cur                  gt_aops_cur_type;
     l_sql_query                  VARCHAR2(4000);
     ln_count                     NUMBER := 0;
BEGIN
       l_sql_query := q'[SELECT  RFCUST.fcu000p_customer_id, RFCUST.fcu000p_business_name, RFCUST.fcu000p_cont_retail_code FROM RACOONDTA.FCU000P@]';
       l_sql_query := l_sql_query||gc_db_link;
       l_sql_query := l_sql_query||q'[ RFCUST
               WHERE  ( RFCUST.fcu000p_delete_flag = 'I' or RFCUST.fcu000p_delete_flag = 'P' )
               AND EXISTS (
                  SELECT  1  FROM  hz_cust_accounts
                  WHERE  orig_system_reference = to_char(LPAD(RFCUST.fcu000p_customer_id,8,0) || '-00001-A0')
                  AND status = 'A')]';
  OPEN gt_aops_cur FOR l_sql_query;
  LOOP
   FETCH gt_aops_cur BULK COLLECT
   INTO lt_racoondta_cust_tab LIMIT 500;
    ln_count := ln_count + lt_racoondta_cust_tab.count;
    IF lt_racoondta_cust_tab.COUNT = 0 THEN
        EXIT;
    END IF;
       insert_cdh_inactive_cust (
          lt_racoondta_cust_tab,
          'I'
        );
    END LOOP;
    CLOSE gt_aops_cur;
  COMMIT;
  gn_custcnt := ln_count;
  WRITE_LOG('Inactive AOPS Active EBS Cust Count: ' || gn_custcnt);
  NULL;
 EXCEPTION
   WHEN OTHERS THEN
       WRITE_LOG('Unexpected Error in procedure get_cdh_inactive_cust- Error - '||SQLERRM);
       x_errbuf := 'Unexpected Error in procedure get_cdh_inactive_cust- Error - '||SQLERRM;
       x_retcode := 2;
END get_cdh_inactive_cust;
--- Added by Kalyan  active AOPS - inactive CDH  customers  End
-- +===================================================================+
-- | Name  : Get_AOPS_Info_Proc                                        |
-- |                                                                   |
-- | Description:       This Procedure will invoke the procedures      |
-- |                    Get_AOPS_Cust_Info_Proc                        |
-- |                    Get_AOPS_Cust_Site_Info_Proc                   |
-- |                    and insert the count into summary table        |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_AOPS_Info_Proc
     (x_errbuf          OUT NOCOPY  VARCHAR2 ,
      x_retcode         OUT NOCOPY  VARCHAR2
     )
AS
BEGIN
 DBMS_SESSION.free_unused_user_memory;
 ---------------------------
 -- Retrieving the DB link
 -----------------------------
  gc_db_link := substr(fnd_profile.value('XX_CDH_OWB_AOPS_DBLINK_NAME'),instr(fnd_profile.value('XX_CDH_OWB_AOPS_DBLINK_NAME'),'@')+1);
  WRITE_LOG('gc_db_link: ' || gc_db_link);
  WRITE_LOG('gn_batch_id: ' || gn_batch_id);
  ---------------------------
  -- Invoking the methods
  -----------------------------
  Get_AOPS_Cust_Info_Proc(x_errbuf => x_errbuf,
                          x_retcode => x_retcode);
  Get_cdh_inactive_cust(x_errbuf => x_errbuf,
                          x_retcode => x_retcode);
  Get_AOPS_Cust_Site_Info_Proc(x_errbuf => x_errbuf,
                              x_retcode => x_retcode);
  Get_AOPS_ISite_Info_Proc(x_errbuf => x_errbuf,
                              x_retcode => x_retcode);
  --------------------------------------------
   -- Inserting the counts into summary table
  --------------------------------------------
 WRITE_LOG('Get_AOPS_Info_Proc: gn_custcnt: ' || gn_custcnt);
 WRITE_LOG('Get_AOPS_Info_Proc: gn_custsitecnt: ' || gn_custsitecnt);
  IF gn_custcnt > 0 AND gn_custsitecnt > 0 THEN
  --IF NVL(gn_custcnt,0) > 0 OR NVL(gn_custsitecnt,0) > 0 THEN
   BEGIN
       INSERT INTO xxod_hz_summary (summary_id,
                                          batch_id,
                                          attribute1,
                                          attribute2,
                                          creation_date,
                                          last_update_date,
                                          created_by,
                                          last_updated_by)
                  VALUES (gn_batch_id,
                          gn_batch_id,
                          gn_custcnt,
                          gn_custsitecnt,
                          gd_creation_date,
                          gd_last_update_date,
                          gn_created_by,
                          gn_last_updated_by);
          commit;
     EXCEPTION
        WHEN OTHERS THEN
           WRITE_LOG('Get_AOPS_Info_Proc: Customer Count Insertion Failed for the batch ' || gn_batch_id);
   END;
  END IF;
END Get_AOPS_Info_Proc;
END XXOD_CDH_AOPS_CUST_PKG;
/
SHOW ERRORS;
