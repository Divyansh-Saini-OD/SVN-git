SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_CDH_ACCOUNT_STATUS_PKG 

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_CDH_ACCOUNT_STATUS_PKG.pkb                      |
-- | Description :  Code to Modify Account and Site Status             |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |Draft 1a  02-Feb-2009 Indra Varada       Initial draft version     |
-- |1.1       10-Jan-2014 Avinash Baddam     Defect 27273              |
-- |1.2       11-Dec-2015 Vasu Raparla       Removed Schema References |
-- |                                         for R.12.2                |
-- +===================================================================+

AS

   
   PROCEDURE update_customer_account
   (
    p_status          VARCHAR2,
    p_cust_id         NUMBER,
    p_ovn             NUMBER,
    x_ret_status  OUT VARCHAR2
   );
   
   PROCEDURE update_customer_site
   (
    p_status                VARCHAR2,
    p_cust_site_id          NUMBER,
    p_ovn                   NUMBER,
    x_ret_status       OUT  VARCHAR2
   );
   
   --Added new param defect 27273
   PROCEDURE update_site_use
   (
    p_status          	VARCHAR2,
    p_site_use_id     	NUMBER,
    p_cust_acct_site_id NUMBER,
    p_ovn             	NUMBER,
    x_ret_status  OUT 	VARCHAR2
   );


  PROCEDURE STATUS_MAIN(
                  p_errbuf             OUT NOCOPY VARCHAR2,
                  p_retcode            OUT NOCOPY VARCHAR2,
                  p_summary_batch_id   IN VARCHAR2,
                  p_activation_flag    IN VARCHAR2,
                  p_db_link_name       IN VARCHAR2,
                  p_commit_flag        IN VARCHAR2
                ) AS
                
   CURSOR activate_accounts 
   IS
   SELECT astg.account_orig_system_reference,acc.cust_account_id,acc.object_version_number
   FROM XXOD_HZ_IMP_ACCOUNTS_STG astg, XXOD_HZ_SUMMARY asum, HZ_CUST_ACCOUNTS acc
   WHERE asum.summary_id = p_summary_batch_id 
   AND   astg.BATCH_ID = asum.batch_id
   AND   acc.orig_system_reference = astg.account_orig_system_reference
   AND   astg.customer_status = 'I'
   AND   astg.interface_status = 7;
   
   TYPE lt_aops_cur_type             IS REF CURSOR;

   lt_aops_cur                       lt_aops_cur_type;
   
   l_cust_account_id              NUMBER;
   l_object_version_number        NUMBER;
   l_success_count                NUMBER  := 0;
   l_error_count                  NUMBER  := 0;
   l_total_records                NUMBER  :=0;
   l_return_status                VARCHAR2(1);
   l_acct_status                  VARCHAR2(1) := NULL;
   l_sql_query                    VARCHAR2(2000);
   
   BEGIN
   
      fnd_file.put_line(fnd_file.log, 'Running Procedure STATUS_MAIN .......');
      
      IF p_activation_flag = 'A' THEN
         fnd_file.put_line(fnd_file.log, 'Force Activating Accounts');
      ELSE
         fnd_file.put_line(fnd_file.log, 'Synchronizing Account Status From AOPS');
      END IF;   
      
         FOR l_acct IN activate_accounts
         LOOP        
           l_total_records   := l_total_records  + 1;
          IF p_activation_flag <> 'A' THEN

              l_acct_status := NULL;
    
              l_sql_query := 'SELECT FCU000P_DELETE_FLAG' ||
                              ' FROM RACOONDTA.FCU000P@' || p_db_link_name ||
                              ' WHERE FCU000P_CUSTOMER_ID= ''' 
                              || SUBSTR(l_acct.account_orig_system_reference,0,8) || '''';
               
               
               OPEN lt_aops_cur FOR l_sql_query;
               FETCH lt_aops_cur INTO l_acct_status;
               CLOSE lt_aops_cur;

               IF TRIM(l_acct_status) = 'P' OR TRIM(l_acct_status) = 'I' THEN
                  l_acct_status  := 'I';
               END IF;
           ELSE
               l_acct_status  := 'A';
           END IF;
           
            update_customer_account
              (
                p_status      =>   l_acct_status,
                p_cust_id     =>   l_acct.cust_account_id,
                p_ovn         =>   l_acct.object_version_number,
                x_ret_status  =>   l_return_status
              );
              
              IF l_return_status = 'S' THEN
                 l_success_count   := l_success_count  + 1;
              ELSE
                 l_error_count  := l_error_count  + 1;
              END IF;
           
           IF MOD(l_success_count,200) = 0 AND p_commit_flag = 'Y' THEN
              COMMIT;
           END IF;
          
          END LOOP;
        
        IF p_commit_flag = 'Y' THEN
           COMMIT;
        ELSE
           ROLLBACK;
        END IF;
        
     fnd_file.put_line(fnd_file.output, ' Total Records To Process : ' || l_total_records );
     fnd_file.put_line(fnd_file.output, ' Total Records Successful : ' || l_success_count);
     fnd_file.put_line(fnd_file.output, ' Total Records Failed     : ' || l_error_count);
     
     fnd_file.put_line(fnd_file.log, 'Procedure STATUS_MAIN Completed');
        
  EXCEPTION WHEN OTHERS THEN
      fnd_file.put_line (fnd_file.log, 'Unexpected Error in proecedure status_main - Error - '||SQLERRM);
      P_errbuf := 'Unexpected Error in proecedure status_main - Error - '||SQLERRM;
      p_retcode := 2;
  END STATUS_MAIN;
  
   
   PROCEDURE update_customer_account
   (
    p_status          VARCHAR2,
    p_cust_id         NUMBER,
    p_ovn             NUMBER,
    x_ret_status  OUT VARCHAR2
   )
  AS
   l_msg_count                    NUMBER;
   l_msg_data                     VARCHAR2(4000);
   l_msg_text                     VARCHAR2(4200);
   l_cust_acct_rec                HZ_CUST_ACCOUNT_V2PUB.cust_account_rec_type;
   l_ovn                          NUMBER;
   
  BEGIN
             l_cust_acct_rec.cust_account_id   := p_cust_id;
             l_cust_acct_rec.status            := p_status;
             l_ovn                             := p_ovn;
             HZ_CUST_ACCOUNT_V2PUB.update_cust_account
             (
               p_init_msg_list           =>  FND_API.G_TRUE,
               p_cust_account_rec        =>  l_cust_acct_rec,
               p_object_version_number   =>  l_ovn,
               x_return_status           =>  x_ret_status,
               x_msg_count               =>  l_msg_count,
               x_msg_data                =>  l_msg_data
             );
   
         IF x_ret_status <> 'S' THEN
            
             IF l_msg_count >= 1 THEN
                fnd_file.put_line(fnd_file.log,'------------------------------------------------------------');
                fnd_file.put_line(fnd_file.log, 'Error In Call TO Update Account API - Cust Account ID,Object Version Number,Status  : ' || l_cust_acct_rec.cust_account_id || ',' || l_ovn || ',' || l_cust_acct_rec.status);
                FOR I IN 1..l_msg_count
                LOOP
                    l_msg_text := l_msg_text||' '||FND_MSG_PUB.Get(I, FND_API.G_FALSE);
                    fnd_file.put_line(fnd_file.log,'Error - '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE));
                END LOOP;
                fnd_file.put_line(fnd_file.log,'------------------------------------------------------------'||CHR(10));
              END IF;
             END IF;
      END update_customer_account;
      
   PROCEDURE update_customer_site
   (
    p_status          VARCHAR2,
    p_cust_site_id    NUMBER,
    p_ovn             NUMBER,
    x_ret_status  OUT VARCHAR2
   )
  AS
   l_msg_count                    NUMBER;
   l_msg_data                     VARCHAR2(4000);
   l_msg_text                     VARCHAR2(4200);
   l_cust_acct_site_rec           HZ_CUST_ACCOUNT_SITE_V2PUB.cust_acct_site_rec_type;
   l_ovn                          NUMBER;
  BEGIN
             l_cust_acct_site_rec.cust_acct_site_id   := p_cust_site_id;
             l_cust_acct_site_rec.status              := p_status;
             l_ovn                                    := p_ovn;
             
             HZ_CUST_ACCOUNT_SITE_V2PUB.update_cust_acct_site
             (
               p_init_msg_list           =>  FND_API.G_TRUE,
               p_cust_acct_site_rec      =>  l_cust_acct_site_rec,
               p_object_version_number   =>  l_ovn,
               x_return_status           =>  x_ret_status,
               x_msg_count               =>  l_msg_count,
               x_msg_data                =>  l_msg_data
             );
         
         IF x_ret_status <> 'S' THEN
            
             IF l_msg_count >= 1 THEN
                fnd_file.put_line(fnd_file.log,'------------------------------------------------------------');
                fnd_file.put_line(fnd_file.log, 'Error In Call TO Update Account Site API - Cust Account Site ID,Object Version Number,Status  : ' || l_cust_acct_site_rec.cust_acct_site_id || ',' || l_ovn || ',' || l_cust_acct_site_rec.status);
                FOR I IN 1..l_msg_count
                LOOP
                    l_msg_text := l_msg_text||' '||FND_MSG_PUB.Get(I, FND_API.G_FALSE);
                    fnd_file.put_line(fnd_file.log,'Error - '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE));
                END LOOP;
                fnd_file.put_line(fnd_file.log,'------------------------------------------------------------'||CHR(10));
              END IF;
             END IF;
      END update_customer_site;
      
  --Added new param defect 27273    
  PROCEDURE update_site_use
   (
    p_status            VARCHAR2,
    p_site_use_id       NUMBER,
    p_cust_acct_site_id NUMBER,
    p_ovn               NUMBER,
    x_ret_status  OUT   VARCHAR2
   )
  AS
   l_msg_count                    NUMBER;
   l_msg_data                     VARCHAR2(4000);
   l_msg_text                     VARCHAR2(4200);
   l_site_use_rec                 HZ_CUST_ACCOUNT_SITE_V2PUB.cust_site_use_rec_type;
   l_ovn                          NUMBER;
  BEGIN
             l_site_use_rec.site_use_id         := p_site_use_id;
             l_site_use_rec.cust_acct_site_id   := p_cust_acct_site_id; --Added for defect 27273
             l_site_use_rec.status              := p_status;             
             l_ovn                              := p_ovn;
             
             HZ_CUST_ACCOUNT_SITE_V2PUB.update_cust_site_use
             (
               p_init_msg_list           =>  FND_API.G_TRUE,
               p_cust_site_use_rec       =>  l_site_use_rec,
               p_object_version_number   =>  l_ovn,
               x_return_status           =>  x_ret_status,
               x_msg_count               =>  l_msg_count,
               x_msg_data                =>  l_msg_data
             );
   
         IF x_ret_status <> 'S' THEN
            
             IF l_msg_count >= 1 THEN
                fnd_file.put_line(fnd_file.log,'------------------------------------------------------------');
                fnd_file.put_line(fnd_file.log, 'Error In Call TO Update Site Use API - Site Use ID,Object Version Number,Status  : ' || l_site_use_rec.site_use_id || ',' || l_ovn || ',' || l_site_use_rec.status);
                FOR I IN 1..l_msg_count
                LOOP
                    l_msg_text := l_msg_text||' '||FND_MSG_PUB.Get(I, FND_API.G_FALSE);
                    fnd_file.put_line(fnd_file.log,'Error - '|| FND_MSG_PUB.Get(I, FND_API.G_FALSE));
                END LOOP;
                fnd_file.put_line(fnd_file.log,'------------------------------------------------------------'||CHR(10));
              END IF;
             END IF;
      END update_site_use;

PROCEDURE update_site_and_acct_status (
                  p_errbuf             OUT NOCOPY VARCHAR2,
                  p_retcode            OUT NOCOPY VARCHAR2,
                  p_entity_type        IN VARCHAR2,
                  p_summary_batch_id   IN VARCHAR2,
                  p_activation_flag    IN VARCHAR2,
                  p_db_link_name       IN VARCHAR2,
                  p_commit_flag        IN VARCHAR2
                 )
AS
CURSOR accounts_cur 
   IS
   SELECT acc.orig_system_reference,
          acc.cust_account_id,
          acc.object_version_number
   FROM XXOD_HZ_SUMMARY asum, HZ_CUST_ACCOUNTS acc
   WHERE asum.summary_id = p_summary_batch_id 
   AND   acc.orig_system_reference = trim(replace(REPLACE((asum.account_orig_system_reference),CHR(13),''),'"',''));   
   
CURSOR sites_cur 
   IS
   SELECT sites.orig_system_reference,
          sites.cust_acct_site_id,
          sites.object_version_number,
          sites.org_id
   FROM XXOD_HZ_SUMMARY asum, HZ_CUST_ACCT_SITES_ALL sites, HZ_ORIG_SYS_REFERENCES osr
   WHERE asum.summary_id = p_summary_batch_id 
   AND   osr.owner_table_id = sites.cust_acct_site_id
   AND   osr.orig_system = 'A0'
   AND   osr.status  = 'A'
   AND   osr.owner_table_name = 'HZ_CUST_ACCT_SITES_ALL'
   AND   sites.orig_system_reference = trim(replace(REPLACE((asum.acct_site_orig_sys_reference),CHR(13),''),'"',''));

--added cust_acct_site_id for defect 27273    
CURSOR uses_cur (p_site_id   NUMBER)
  IS
  SELECT site_use_id,cust_acct_site_id,object_version_number
  FROM HZ_CUST_SITE_USES_ALL
  WHERE cust_acct_site_id = p_site_id
  AND   status = 'I';

   TYPE lt_aops_cur_type             IS REF CURSOR;

   lt_aops_cur                       lt_aops_cur_type;
   
   l_cust_account_id              NUMBER;
   l_object_version_number        NUMBER;
   l_success_count                NUMBER  := 0;
   l_error_count                  NUMBER  := 0;
   l_total_records                NUMBER  :=0;
   l_site_use_error_count         NUMBER  := 0;
   l_site_use_succ_count          NUMBER   := 0;
   l_return_status                VARCHAR2(1);
   l_status                       VARCHAR2(1) := NULL;
   l_sql_query                    VARCHAR2(2000);
   l_sync_back_aops_time          NUMBER;
   lt_conc_request_id             NUMBER :=0;
   l_user_id                      NUMBER;
   l_resp_id                      NUMBER;
   l_resp_appl_id                 NUMBER;
BEGIN
      fnd_file.put_line(fnd_file.log, 'Running Procedure update_site_and_acct_status .......');
      
      IF p_activation_flag = 'A' THEN
         fnd_file.put_line(fnd_file.output, '******** Force Activating - ' || p_entity_type || ' ********');
      ELSE
         fnd_file.put_line(fnd_file.output, '******** Synchronizing ' || p_entity_type || ' Status From AOPS ********');
      END IF;   
      
    IF p_entity_type = 'ACCOUNT' THEN
      
         FOR l_acct IN accounts_cur
         LOOP  
            l_total_records   := l_total_records  + 1;
          IF p_activation_flag <> 'A' THEN

              l_status := NULL;
    
              l_sql_query := 'SELECT FCU000P_DELETE_FLAG' ||
                              ' FROM RACOONDTA.FCU000P@' || p_db_link_name ||
                              ' WHERE FCU000P_CUSTOMER_ID= ''' 
                              || SUBSTR(l_acct.orig_system_reference,0,8) || '''';
               
               
               OPEN lt_aops_cur FOR l_sql_query;
               FETCH lt_aops_cur INTO l_status;
               CLOSE lt_aops_cur;

               IF TRIM(l_status) IN ('P','I')  THEN
                  l_status  := 'I';
               END IF;
           ELSE
               l_status  := 'A';
           END IF;
           
            update_customer_account
              (
                p_status      =>   l_status,
                p_cust_id     =>   l_acct.cust_account_id,
                p_ovn         =>   l_acct.object_version_number,
                x_ret_status  =>   l_return_status
              );
              
              IF l_return_status = 'S' THEN
                 l_success_count   := l_success_count  + 1;
              ELSE
                 l_error_count  := l_error_count  + 1;
              END IF;
           
           IF MOD(l_success_count,200) = 0 AND p_commit_flag = 'Y' THEN
              COMMIT;
           END IF;
          
          END LOOP;
          
      ELSE -- Updating Sites/Uses
      
         FOR l_sites IN sites_cur
         LOOP  
            l_total_records   := l_total_records  + 1;
          IF p_activation_flag <> 'A' THEN

              l_status := NULL;
    
              l_sql_query := 'SELECT NVL(TRIM(FCU001P_SHIPTO_STS),''A'')' ||
                              ' FROM RACOONDTA.FCU001P@' || p_db_link_name ||
                              ' WHERE FCU001P_CUSTOMER_ID= ''' 
                              || SUBSTR(l_sites.orig_system_reference,0,8) || ''''
                              || ' AND FCU001P_ADDRESS_SEQ= ''' || LTRIM(substr(l_sites.orig_system_reference,10,5),0) || '''';
               
               
               OPEN lt_aops_cur FOR l_sql_query;
               FETCH lt_aops_cur INTO l_status;
      
                IF lt_aops_cur%NOTFOUND OR TRIM(l_status) IN ('I','P') THEN
                  l_status  := 'I';
                END IF;
               CLOSE lt_aops_cur;
            
            ELSE
                  l_status  := 'A';
            END IF;
         
         /* An API Call cannot be used to update site status 
            because the sites are being moved around
            using the OU change Data Fix Script, 
            as a result of which accout site and party site sync is not in place. 
            
            The below code should be used once
            the changes for the OU have been implemented.*/
           
          /*  FND_CLIENT_INFO.SET_ORG_CONTEXT (l_sites.org_id);
           
              update_customer_site
              (
                p_status        =>   l_status,
                p_cust_site_id  =>   l_sites.cust_acct_site_id,
                p_ovn           =>   l_sites.object_version_number,
                x_ret_status    =>   l_return_status
              ); */
              
              BEGIN
              
               UPDATE hz_cust_acct_sites_all
               SET status = l_status, 
                  last_update_date = SYSDATE
               WHERE cust_acct_site_id = l_sites.cust_acct_site_id; 
                              
                l_success_count   := l_success_count  + 1;
                

                    FOR l_site_use IN uses_cur (l_sites.cust_acct_site_id) LOOP
                        update_site_use
                          (
                            p_status        =>   l_status,
                            p_site_use_id  =>   l_site_use.site_use_id,
                            p_cust_acct_site_id => l_site_use.cust_acct_site_id, --added for defect 27273
                            p_ovn           =>   l_site_use.object_version_number,
                            x_ret_status    =>   l_return_status
                          );
                        IF l_return_status <> 'S' THEN
                           l_site_use_error_count := l_site_use_error_count + 1;
                           fnd_file.put_line(fnd_file.log,'Reactivation Site Uses For Account Site: ' || l_sites.cust_acct_site_id || ' Failed');
                        ELSE
                           l_site_use_succ_count := l_site_use_succ_count + 1;
                        END IF;
                    END LOOP;

              
              EXCEPTION WHEN OTHERS THEN
                l_error_count  := l_error_count  + 1;
                fnd_file.put_line(fnd_file.log, 'Account Site Failed Updation :' || l_sites.cust_acct_site_id );
              END;
           
           IF MOD(l_success_count,200) = 0 AND p_commit_flag = 'Y' THEN
              COMMIT;
           END IF;
          
          END LOOP;
      END IF;
      
        IF p_commit_flag = 'Y' THEN
           COMMIT;
        ELSE
           ROLLBACK;
        END IF;
      
     fnd_file.put_line(fnd_file.output, '  ----------- Statistics For Entity : ' || p_entity_type || ' -----------');   
     fnd_file.put_line(fnd_file.output, ' Total Records To Process : ' || l_total_records );
     fnd_file.put_line(fnd_file.output, ' Total Records Successful : ' || l_success_count);
     fnd_file.put_line(fnd_file.output, ' Total Records Failed     : ' || l_error_count);
     
     IF p_entity_type = 'ACCOUNT SITE' THEN
        fnd_file.put_line(fnd_file.output, '');
        fnd_file.put_line(fnd_file.output, '  ----------- Statistics For Entity : Account Site Uses ' || '-----------');   
        fnd_file.put_line(fnd_file.output, ' Total Records Successful : ' || l_site_use_succ_count);
        fnd_file.put_line(fnd_file.output, ' Total Records Failed     : ' || l_site_use_error_count);
     END IF;
     
     IF l_success_count > 0 AND p_activation_flag = 'A' THEN
     
        l_sync_back_aops_time    := NVL(fnd_profile.value('XX_CDH_SYNC_BACK_AOPS_STATUS'),8);
         
         BEGIN
           SELECT user_id INTO l_user_id
           FROM FND_USER
           WHERE user_name = 'ODCDH';
         
           SELECT responsibility_id,application_id INTO l_resp_id,l_resp_appl_id
           FROM fnd_responsibility_vl
           WHERE responsibility_name = 'OD (US) Customer Conversion';
           
          FND_GLOBAL.APPS_INITIALIZE( l_user_id , l_resp_id , l_resp_appl_id);
         
         lt_conc_request_id := FND_REQUEST.submit_request
                                          (   application => 'XXCNV',
                                              program     => 'XX_CDH_ACTIVATE_SITES_ACCOUNTS',
                                              description => NULL,
                                              start_time  => TO_CHAR(SYSDATE+(l_sync_back_aops_time/24), 'DD-MON-YYYY HH24:MI:SS'),
                                              sub_request => FALSE,
                                              argument1   => p_entity_type,
                                              argument2   => p_summary_batch_id,
                                              argument3   => 'AOPS STATUS',
                                              argument4   => p_db_link_name,
                                              argument5   => p_commit_flag
                                          );
                                          
           IF lt_conc_request_id > 0 THEN
            fnd_file.put_line(fnd_file.log, 'Program To Revert Changes Scheduled to Run at : ' || TO_CHAR(SYSDATE+(l_sync_back_aops_time/24),'DD-MON-YYYY HH24:MI:SS'));
            fnd_file.put_line(fnd_file.output, '');
            fnd_file.put_line(fnd_file.output, 'The Changes Would Be Reverted (If Commit Flag is Set to Y) On : ' || TO_CHAR(SYSDATE+(l_sync_back_aops_time/24),'DD-MON-YYYY HH24:MI:SS') );
           ELSE
            fnd_file.put_line(fnd_file.log, 'Program To Automatically Revert Changes Failed during Submition, Please Revert the Changes Manually');
            p_retcode  := 1;
          END IF;
        
        EXCEPTION WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log, 'Program To Automatically Revert Changes Failed : ' || SQLERRM);
        END;
      
      
      END IF;
      

     fnd_file.put_line(fnd_file.log, 'Procedure STATUS_MAIN Completed');
        
  EXCEPTION WHEN OTHERS THEN
      fnd_file.put_line (fnd_file.log, 'Unexpected Error in proecedure status_main - Error - '||SQLERRM);
      P_errbuf := 'Unexpected Error in proecedure status_main - Error - '||SQLERRM;
      p_retcode := 2;

 END update_site_and_acct_status;
      

END XX_CDH_ACCOUNT_STATUS_PKG;
/
SHOW ERRORS;
--EXIT;