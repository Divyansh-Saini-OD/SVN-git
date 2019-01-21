create or replace
PACKAGE BODY XX_CDH_SYNC_SITES_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_CDH_ACCOUNT_STATUS_PKG.pkb                      |
-- | Description :  Inactivate account site and usages                 |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |Draft 1a  28-Mar-2013 Dheeraj V          Initial draft version     |
-- |                                         for QC 22822              |
-- |1.2       08-MAR-2014 Arun Gannarapu       Made changes as per R12 retrofit     |
-- |                                                defect # 28030
-- +===================================================================+
 
 gc_commit VARCHAR2(1);
  
  PROCEDURE siteuse_proc
  (
    p_cust_acct_site_id IN hz_cust_acct_sites_all.cust_acct_site_id%TYPE,
    x_return_status OUT VARCHAR2
  )
  IS
  
  CURSOR siteuse_cur (ln_cust_acct_site_id IN hz_cust_acct_sites_all.cust_acct_site_id%TYPE) 
  IS
  SELECT site_use_id , cust_acct_site_id, object_version_number ovn FROM
  hz_cust_site_uses_all
  WHERE cust_acct_site_id = ln_cust_acct_site_id
  AND status = 'A';
  
  lr_siteuse hz_cust_account_site_v2pub.cust_site_use_rec_type;
  lc_ret_status VARCHAR2 (1);
  ln_msg_count NUMBER;
  lc_msg_data VARCHAR2(4000);  
  
  BEGIN
   
   x_return_status := 'S';
   
   FOR i in siteuse_cur(p_cust_acct_site_id)
   LOOP
    
    BEGIN  
      lr_siteuse := NULL;
      lr_siteuse.site_use_id := i.site_use_id;
      lr_siteuse.cust_acct_site_id := i.cust_acct_site_id;
      lr_siteuse.status := 'I';
        
       hz_cust_account_site_v2pub.update_cust_site_use
        (
          p_init_msg_list => FND_API.G_TRUE,
          p_cust_site_use_rec => lr_siteuse,
          p_object_version_number => i.ovn,
          x_return_status => lc_ret_status,
          x_msg_count => ln_msg_count,
          x_msg_data => lc_msg_data
        );
               
         IF lc_ret_status <> FND_API.G_RET_STS_SUCCESS THEN                
                  lc_msg_data:=NULL;                   
                    IF (ln_msg_count>0) THEN                    
                      FOR counter IN 1 .. ln_msg_count
                      LOOP
                      lc_msg_data := lc_msg_data || ' ' || fnd_msg_pub.GET(counter,   fnd_api.g_false);
                      END LOOP;                    
                    END IF;
                                      
        						fnd_msg_pub.DELETE_MSG;
                    fnd_file.put_line(fnd_file.log, 'Error for site_use_id : '||i.site_use_id||CHR(13)||lc_msg_data);
                    x_return_status := 'E';
                    RETURN;
                    
         ELSE
            fnd_file.put_line(fnd_file.log, 'Successfully inactivated site use with site_use_id : '||i.site_use_id);
         END IF;
        
    EXCEPTION 
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log, 'Error for site_use_id : '||i.site_use_id||CHR(13)||lc_msg_data);
      x_return_status := 'E';
    END;
                  
   END LOOP; --FOR i in siteuse_cur(p_cust_acct_site_id)
   
  EXCEPTION 
  WHEN OTHERS THEN
  
  fnd_file.put_line(fnd_file.log, 'Error occured in siteuse_proc for cust_acct_site_id :'||p_cust_acct_site_id);
  x_return_status := 'E';
    
  END siteuse_proc;
  
  
  
  PROCEDURE site_proc
  (
    p_summary_id NUMBER    
  )
  IS
  
  CURSOR site_cur 
  IS
  SELECT site.cust_acct_site_id, site.object_version_number ovn, site.orig_system_reference osr FROM
  hz_cust_acct_sites_all site, xxod_hz_summary summ
  WHERE site.orig_system_reference = summ.account_orig_system_reference
  AND site.status = 'A'
  AND summary_id = p_summary_id;
  
   
  TYPE site_tab_type IS TABLE OF site_cur%ROWTYPE;
  site_tab site_tab_type;
  
  g_limit NUMBER := 10000;
  
  lr_site hz_cust_account_site_v2pub.cust_acct_site_rec_type;
  lc_ret_status VARCHAR2 (1);
  ln_msg_count NUMBER;
  lc_msg_data VARCHAR2(4000);
  
  ln_error NUMBER := 0;
  ln_success NUMBER := 0;
  ln_processed NUMBER := 0;
  
  x_return_status VARCHAR2(1);
  
  BEGIN
    
    fnd_file.put_line(fnd_file.log,'starting site_proc procedure');
    
    OPEN site_cur;
    LOOP
    FETCH site_cur BULK COLLECT INTO site_tab LIMIT g_limit;
    EXIT WHEN site_tab.COUNT = 0;
    
      FOR i in site_tab.FIRST..site_tab.LAST
      LOOP
      
      BEGIN
      
        fnd_file.put_line(fnd_file.log, 'Processing cust_acct_site_id : '||site_tab(i).cust_acct_site_id||','||'Site_OSR :'||site_tab(i).osr);

        ln_processed := ln_processed + 1;
        lr_site :=  NULL;
        
        lr_site.cust_acct_site_id := site_tab(i).cust_acct_site_id;
        lr_site.status := 'I';
        
        hz_cust_account_site_v2pub.update_cust_acct_site
        (
          p_init_msg_list => FND_API.G_TRUE,
          p_cust_acct_site_rec => lr_site,
          p_object_version_number => site_tab(i).ovn,
          x_return_status => lc_ret_status,
          x_msg_count => ln_msg_count,
          x_msg_data => lc_msg_data
        );
               
         IF lc_ret_status <> FND_API.G_RET_STS_SUCCESS THEN                
                  lc_msg_data:=NULL;                   
                    IF (ln_msg_count>0) THEN                    
                      FOR counter IN 1 .. ln_msg_count
                      LOOP
                      lc_msg_data := lc_msg_data || ' ' || fnd_msg_pub.GET(counter,   fnd_api.g_false);
                      END LOOP;                    
                    END IF;
                                      
        						fnd_msg_pub.DELETE_MSG;
                    ln_error := ln_error + 1;
                    fnd_file.put_line(fnd_file.log, 'Error for cust_acct_site_id : '||site_tab(i).cust_acct_site_id||CHR(13)||lc_msg_data);
                    
         ELSE
            
            fnd_file.put_line(fnd_file.log, 'Successfully inactivated cust_acct_site_id : '||site_tab(i).cust_acct_site_id);
            
              siteuse_proc(site_tab(i).cust_acct_site_id,x_return_status);
              
              IF (x_return_status = 'S') 
              THEN
                ln_success := ln_success + 1;
              ELSE
                ln_error := ln_error + 1;
              END IF;
            
         END IF;
        
        EXCEPTION 
        WHEN OTHERS THEN
        ln_error := ln_error + 1;
        fnd_file.put_line(fnd_file.log, 'Error for cust_acct_site_id : '||site_tab(i).cust_acct_site_id||CHR(13)||lc_msg_data);        
        
        END;

        IF gc_commit = 'Y' AND (mod(ln_processed,100) = 0)
        THEN
          COMMIT;
        END IF;
        
      END LOOP; --FOR i in site_tab.FIRST..site_tab.LAST
    
    END LOOP; --OPEN site_cur;
    
    CLOSE site_cur;
    
    fnd_file.put_line(fnd_file.output, 'Summary of sites processed '||chr(13));
    
    fnd_file.put_line(fnd_file.output, 'Processed : '||ln_processed);
    fnd_file.put_line(fnd_file.output, 'Success : '||ln_success);
    fnd_file.put_line(fnd_file.output, 'Error : '||ln_error);
    
    
  EXCEPTION
  WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'Error occurred in site_proc :'||SQLERRM);  
    
  END site_proc;


  PROCEDURE siteuse_force
  (
    p_cust_acct_site_id IN hz_cust_acct_sites_all.cust_acct_site_id%TYPE,
    x_return_status OUT VARCHAR2
  )
  IS
  
  CURSOR siteuse_cur (ln_cust_acct_site_id IN hz_cust_acct_sites_all.cust_acct_site_id%TYPE) 
  IS
  SELECT site_use_id , object_version_number ovn FROM
  hz_cust_site_uses_all
  WHERE cust_acct_site_id = ln_cust_acct_site_id
  AND status = 'A';
  
  
  BEGIN
   
   x_return_status := 'S';
   
   FOR i in siteuse_cur(p_cust_acct_site_id)
   LOOP
    
    BEGIN  
          
        UPDATE hz_cust_site_uses_all 
        SET status = 'I',
        last_updated_by = hz_utility_v2pub.last_updated_by,
        last_update_date = hz_utility_v2pub.last_update_date
        WHERE site_use_id = i.site_use_id;
        
          IF SQL%ROWCOUNT = 1
          THEN
            fnd_file.put_line(fnd_file.log, 'Successfully inactivated site use with site_use_id : '||i.site_use_id);
          ELSE  
            fnd_file.put_line(fnd_file.log, 'Error for site_use_id : '||i.site_use_id);
          END IF;
            
    EXCEPTION 
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log, 'Error for site_use_id : '||i.site_use_id||CHR(13)||SQLERRM);
      x_return_status := 'E';
    END;
                  
   END LOOP; --FOR i in siteuse_cur(p_cust_acct_site_id)
   
  EXCEPTION 
  WHEN OTHERS THEN
  
  fnd_file.put_line(fnd_file.log, 'Error occured in siteuse_proc for cust_acct_site_id :'||p_cust_acct_site_id);
  x_return_status := 'E';
    
  END siteuse_force;



  
  PROCEDURE site_force
  (
    p_summary_id NUMBER    
  )
  IS
  
  CURSOR site_cur 
  IS
  SELECT site.cust_acct_site_id, site.object_version_number ovn, site.orig_system_reference osr FROM
  hz_cust_acct_sites_all site, xxod_hz_summary summ
  WHERE site.orig_system_reference = summ.account_orig_system_reference
  AND site.status = 'A'
  AND summary_id = p_summary_id;
  
   
  TYPE site_tab_type IS TABLE OF site_cur%ROWTYPE;
  site_tab site_tab_type;
  
  g_limit NUMBER := 10000;

 
  ln_error NUMBER := 0;
  ln_success NUMBER := 0;
  ln_processed NUMBER := 0;
  
  x_return_status VARCHAR2(1);
  
  BEGIN
    
    fnd_file.put_line(fnd_file.log,'starting site_force procedure');
    
    OPEN site_cur;
    LOOP
    FETCH site_cur BULK COLLECT INTO site_tab LIMIT g_limit;
    EXIT WHEN site_tab.COUNT = 0;
    
      FOR i in site_tab.FIRST..site_tab.LAST
      LOOP
      
      BEGIN
      
        fnd_file.put_line(fnd_file.log, 'Processing cust_acct_site_id : '||site_tab(i).cust_acct_site_id||','||'Site_OSR :'||site_tab(i).osr);

        ln_processed := ln_processed + 1;
        
        UPDATE hz_cust_acct_sites_all 
        SET status = 'I',
        last_updated_by = hz_utility_v2pub.last_updated_by,
        last_update_date = hz_utility_v2pub.last_update_date
        WHERE cust_acct_site_id = site_tab(i).cust_acct_site_id;
      
        IF SQL%ROWCOUNT = 1
        THEN

            fnd_file.put_line(fnd_file.log, 'Successfully inactivated cust_acct_site_id : '||site_tab(i).cust_acct_site_id);
            
            siteuse_force(site_tab(i).cust_acct_site_id,x_return_status);
            
              IF (x_return_status = 'S') 
              THEN
                ln_success := ln_success + 1;
              ELSE
                ln_error := ln_error + 1;
              END IF;
            
        ELSE
            ln_error := ln_error + 1;
            fnd_file.put_line(fnd_file.log, 'Error for cust_acct_site_id : '||site_tab(i).cust_acct_site_id);    
            
        END IF;
        
        EXCEPTION 
        WHEN OTHERS THEN
        ln_error := ln_error + 1;
        fnd_file.put_line(fnd_file.log, 'Error for cust_acct_site_id : '||site_tab(i).cust_acct_site_id||CHR(13)||SQLERRM);        
        
        END;
        
        IF gc_commit = 'Y' AND (mod(ln_processed,100) = 0)
        THEN
          COMMIT;
        END IF;
        
      END LOOP; --FOR i in site_tab.FIRST..site_tab.LAST
    
    END LOOP; --OPEN site_cur;
    
    CLOSE site_cur;
    
    fnd_file.put_line(fnd_file.log, 'Summary of sites processed '||chr(13));
    
    fnd_file.put_line(fnd_file.log, 'Processed : '||ln_processed);
    fnd_file.put_line(fnd_file.log, 'Success : '||ln_success);
    fnd_file.put_line(fnd_file.log, 'Error : '||ln_error);
    
    
  EXCEPTION
  WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'Error occurred in site_proc :'||SQLERRM);  
    
  END site_force;
  
  
  procedure main_proc
  (
    p_errbuff OUT NOCOPY VARCHAR2,
    p_retcode OUT NOCOPY VARCHAR2,
    p_summary_id IN NUMBER,
    p_commit IN VARCHAR2,
    p_force IN VARCHAR2
  )
 IS 
  
  
  BEGIN
    
    gc_commit := p_commit;
    
    fnd_file.put_line(fnd_file.log,'starting main_proc');
    
      IF NVL(p_force,'N') = 'N'
      THEN
        site_proc(p_summary_id);
      ELSE
        site_force(p_summary_id);
      END IF;
  
    IF p_commit = 'Y'
    THEN
      COMMIT;
      fnd_file.put_line(fnd_file.log,'All changes Committed');
    ELSE
      ROLLBACK;
      fnd_file.put_line(fnd_file.log,'All changes Rolledback');
    END IF;
  
  EXCEPTION 
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log, 'Error occurred in main_proc :'||SQLERRM);
  END main_proc;

END XX_CDH_SYNC_SITES_PKG;
/
SHOW ERRORS;