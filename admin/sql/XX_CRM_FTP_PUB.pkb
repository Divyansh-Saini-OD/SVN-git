SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


create or replace
PACKAGE BODY XX_CRM_FTP_PUB 
-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                      Office Depot CDH Team                               |
-- +==========================================================================+
-- | Name        : XX_CRM_FTP_PUB                                             |
-- | Rice ID     : C0024 Conversions/Common View Loader                       |
-- | Description : Package Transferring ASCII File to Remote Machines         | 
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |1.0      13-Jan-2008  Indra Varada           Initial Version              |
-- |                                                                          |
-- +==========================================================================+
AS

  PROCEDURE transfer_file 
  (
   x_errbuf       OUT NOCOPY VARCHAR2,
   x_retcode      OUT NOCOPY VARCHAR2,
   p_host_dest    IN  VARCHAR2,
   p_from_dir     IN  VARCHAR2,
   p_from_file    IN  VARCHAR2,
   p_to_dir       IN  VARCHAR2,
   p_to_file      IN  VARCHAR2
  ) AS
    l_conn      UTL_TCP.connection;
    ftp_host    VARCHAR2(100);
    ftp_login   VARCHAR2(50);
    ftp_pass    VARCHAR2(50);
    v_directory varchar2(30):='CRM_FTP';
    l_from_dir   VARCHAR2(100);
  BEGIN
    fnd_file.put_line (fnd_file.log, 'Source File:' || p_from_dir || p_from_file);
    fnd_file.put_line (fnd_file.log, 'Destination Host Name:' || p_host_dest);
    fnd_file.put_line (fnd_file.log, 'Destination File:' || p_to_dir || p_to_file);
    fnd_file.put_line (fnd_file.log, 'Initiating File Transfer at: ' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
      
    SELECT user_name,user_password INTO ftp_login,ftp_pass
    FROM XX_CRM_FTP_HOST_DATA
    WHERE host_name = p_host_dest;
    
    l_from_dir := '''' || p_from_dir || '''';
    
    DBMS_OBFUSCATION_TOOLKIT.DES3Decrypt
    (
     input_string      => ftp_pass,
     key_string        => ftp_login || '@#$ODCRMCDHSFA$#@',
     decrypted_string  => ftp_pass
    );

    ftp_pass := TRIM(ftp_pass);
    EXECUTE IMMEDIATE 'create or replace directory '||v_directory||' as '||l_from_dir;
    l_conn := XX_CRM_FTP_PVT.login(p_host_dest, '21', ftp_login, ftp_pass);
    XX_CRM_FTP_PVT.ascii(p_conn => l_conn);
    XX_CRM_FTP_PVT.put(l_conn,v_directory,p_from_file,p_to_dir||p_to_file);
    XX_CRM_FTP_PVT.logout(l_conn);
    utl_tcp.close_all_connections;  
    
    fnd_file.put_line (fnd_file.log, 'File Transferred Complete at: ' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
  
  
 
  EXCEPTION 
  WHEN NO_DATA_FOUND THEN
      fnd_file.put_line (fnd_file.log, 'Host Information Not Available in the Setup Table - XX_CRM_FTP_HOST_DATA');
      x_retcode := 2;
  WHEN OTHERS THEN
     fnd_file.put_line (fnd_file.log, 'Unexpected Error in proecedure transfer_file - Error - '||SQLERRM);
     x_errbuf := 'Unexpected Error in proecedure transfer_file - Error - '||SQLERRM;
     x_retcode := 2;
  END transfer_file;
  
  PROCEDURE host_setup
  (
   x_errbuf       OUT NOCOPY VARCHAR2,
   x_retcode      OUT NOCOPY VARCHAR2,
   p_host_dest    IN  VARCHAR2
   ) AS
   
   l_setup_profile    VARCHAR2(100);
   l_user_name        VARCHAR2(50);
   l_user_password    VARCHAR2(50);
   l_password_len     NUMBER;
   l_exists           VARCHAR2(2);
   fnd_status         BOOLEAN;
   BEGIN
      l_setup_profile  := fnd_profile.value('XX_CRM_FTP_HOST_LOGIN');
      l_user_name      := SUBSTR(l_setup_profile,0,INSTR(l_setup_profile,'/')-1);
      l_user_password  := SUBSTR(l_setup_profile,instr(l_setup_profile,'/')+1,length(l_setup_profile));
      
      IF l_user_name IS NOT NULL AND l_user_password IS NOT NULL AND p_host_dest IS NOT NULL THEN
         
         fnd_file.put_line (fnd_file.log, 'Updating/Inserting Data.......');
         
         l_password_len := MOD(LENGTH(l_user_password),8);
         LOOP
           IF l_password_len=0 
             THEN EXIT;
           ELSE
             l_user_password := RPAD(l_user_password,LENGTH(l_user_password)+1);
             l_password_len := MOD(LENGTH(l_user_password),8);
           END IF;
         END LOOP;
              
         
         DBMS_OBFUSCATION_TOOLKIT.DES3Encrypt
         (
          input_string      => l_user_password,
          key_string        => l_user_name || '@#$ODCRMCDHSFA$#@',
          encrypted_string  => l_user_password
         );
          
          BEGIN
            SELECT '1' INTO l_exists
            FROM xx_crm_ftp_host_data
            WHERE host_name = p_host_dest;
            
            
            UPDATE xx_crm_ftp_host_data SET user_name = l_user_name, user_password = l_user_password,last_update_date = SYSDATE
            WHERE host_name = p_host_dest;
            
          EXCEPTION WHEN NO_DATA_FOUND THEN
            INSERT INTO xx_crm_ftp_host_data VALUES (TRIM(p_host_dest), l_user_name, l_user_password,SYSDATE,SYSDATE);
          END;
          fnd_file.put_line (fnd_file.log, 'Updating/Inserting Data Complete');
          fnd_status := fnd_profile.save('XX_CRM_FTP_HOST_LOGIN',NULL,'SITE');
          IF fnd_status THEN
            fnd_file.put_line (fnd_file.log,'Profile - XX_CRM_FTP_HOST_LOGIN set to NULL at Site Level');
          ELSE
            fnd_file.put_line (fnd_file.log,'Profile - XX_CRM_FTP_HOST_LOGIN Could Not Be Set To Null');
          END IF;
      ELSE
          fnd_file.put_line (fnd_file.log, 'UserName or Password or Host Is Null, Profile XX_CRM_FTP_HOST_LOGIN not setup');
          x_retcode := 2;
      END IF;
      
      COMMIT;
      
   EXCEPTION WHEN OTHERS THEN
     fnd_file.put_line (fnd_file.log, 'Unexpected Error in proecedure host_setup - Error - '||SQLERRM);
     x_errbuf := 'Unexpected Error in proecedure host_setup - Error - '||SQLERRM;
     x_retcode := 2;
   END host_setup;
END XX_CRM_FTP_PUB;
/
SHOW ERRORS;
EXIT;
