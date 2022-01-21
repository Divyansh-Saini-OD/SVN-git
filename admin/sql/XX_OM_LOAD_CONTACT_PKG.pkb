SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_LOAD_CONTACT_PKG AS
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                                                                           |
-- +===========================================================================+
-- | Name  : XX_OM_LOAD_CONTACT_PKG.pkb                                        |
-- | Description: This package will load the service contacts for a vendor     |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author           Remarks                             |
-- |=======  ===========  =============    ====================================|
-- |1.0      02-May-2008  Matthew Craig    Initial draft version               |
-- |                                                                           |
-- +===========================================================================+

  v_cp_enabled            BOOLEAN ;

-- +===========================================================================+
-- | Name: service_contact_load                                                |
-- |                                                                           |
-- | Description: This prcodure will read records from a CSV formatted file    |
-- |              to load the service conatcts for a vendor                    |
-- |                                                                           |
-- | Parameters:  x_retcode                                                    |
-- |              x_errbuff                                                    |
-- |              p_contact_file                                               |
-- |              p_file_location                                              |
-- |                                                                           |
-- | Returns :    x_retcode                                                    |
-- |              x_errbuff                                                    |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+

PROCEDURE Service_contact_load (
     x_retcode                OUT NOCOPY VARCHAR2
    ,x_errbuff                 OUT NOCOPY VARCHAR2
    ,p_contact_file IN VARCHAR2
    ,p_file_location IN VARCHAR2 )
IS

    l_utl_filetype      UTL_FILE.FILE_TYPE;
    lc_contact_line     VARCHAR2(200);
    lc_aops_number      VARCHAR2(20);
    
    ln_vendor_conact_id NUMBER;
    ln_pos              NUMBER;
    ln_start            NUMBER;
    ln_end              NUMBER;
    found               NUMBER :=0;
   
    lc_last_name        po_vendor_contacts.last_name%TYPE;
    lc_first_name       po_vendor_contacts.first_name%TYPE;
    lc_email_address    po_vendor_contacts.email_address%TYPE;
    lc_area_code        po_vendor_contacts.area_code%TYPE;
    lc_phone            po_vendor_contacts.phone%TYPE;
    lc_fax_area_code    po_vendor_contacts.fax_area_code%TYPE;
    lc_fax              po_vendor_contacts.fax%TYPE;
    lc_department       po_vendor_contacts.department%TYPE := 'SERVICE';

    CURSOR c_aops_vendor (
         c_aops_number VARCHAR2 ) 
    IS
        SELECT 
            vendor_site_id
        FROM   
            po_vendor_sites_all
        WHERE  
                LTRIM(attribute9,'0') = c_aops_number
            AND purchasing_site_flag = 'Y'; 
BEGIN

    v_cp_enabled := TRUE;

    IF NOT UTL_FILE.IS_OPEN(l_utl_filetype) THEN
        l_utl_filetype := UTL_FILE.FOPEN( p_file_location, p_contact_file, 'R' );
    END IF;

    LOOP
        BEGIN
        
            UTL_FILE.GET_LINE(l_utl_filetype, lc_contact_line);
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
                EXIT;
           WHEN UTL_FILE.READ_ERROR THEN
               x_errbuff := 'ERROR:Could not read file';
               x_retcode := 2;
               EXIT;
        END;
        
        ln_start := 1;
        ln_end := LENGTH(lc_contact_line);
        ln_pos := INSTR(lc_contact_line,',',1,1);
        
        if ln_end > 7  AND ln_pos > ln_start THEN
        
            lc_last_name     := NULL;
            lc_first_name    := NULL;
            lc_email_address := NULL;
            lc_area_code     := NULL;
            lc_phone         := NULL;
            lc_fax_area_code := NULL;
            lc_fax           := NULL;
            found := -1;
            
            lc_aops_number := SUBSTR(lc_contact_line,ln_start, ln_pos-ln_start);

            ln_start := ln_pos + 1;
            ln_pos := INSTR(lc_contact_line,',',1,2);
            IF ln_pos > ln_start AND ln_pos > 0 THEN
                lc_last_name := SUBSTR(SUBSTR(lc_contact_line,ln_start, ln_pos-ln_start),1,20);
            ELSIF ln_pos = 0 AND found = -1 AND ln_end >= ln_start THEN
                lc_last_name := SUBSTR(SUBSTR(lc_contact_line,ln_start, ln_end-ln_start+1),1,20);
                found := 0;
            END IF;
            
            ln_start := ln_pos + 1;
            ln_pos := INSTR(lc_contact_line,',',1,3);
            
            IF ln_pos > ln_start AND ln_pos > 0 THEN
                lc_first_name := SUBSTR(SUBSTR(lc_contact_line,ln_start, ln_pos-ln_start),1,15);
            ELSIF ln_pos = 0 AND found = -1 AND ln_end >= ln_start THEN
                lc_first_name := SUBSTR(SUBSTR(lc_contact_line,ln_start, ln_end-ln_start+1),1,15);
                found := 0;
            END IF;
            
            ln_start := ln_pos + 1;
            ln_pos := INSTR(lc_contact_line,',',1,4);
            
            IF ln_pos > ln_start AND ln_pos > 0 THEN
                lc_email_address := SUBSTR(SUBSTR(lc_contact_line,ln_start, ln_pos-ln_start),1,1000);
            ELSIF ln_pos = 0 AND found = -1 AND ln_end >= ln_start THEN
                lc_email_address := SUBSTR(SUBSTR(lc_contact_line,ln_start, ln_end-ln_start+1),1,1000);
                found := 0;
            END IF;            

            ln_start := ln_pos + 1;
            ln_pos := INSTR(lc_contact_line,',',1,5);
            
            IF ln_pos > ln_start AND ln_pos > 0 THEN
                lc_area_code := SUBSTR(SUBSTR(lc_contact_line,ln_start, ln_pos-ln_start),1,10);
            ELSIF ln_pos = 0 AND found = -1 AND ln_end >= ln_start THEN
                lc_area_code := SUBSTR(SUBSTR(lc_contact_line,ln_start, ln_end-ln_start+1),1,10);
                found := 0;
            END IF;            
            
            ln_start := ln_pos + 1;
            ln_pos := INSTR(lc_contact_line,',',1,6);
            
            IF ln_pos > ln_start AND ln_pos > 0 THEN
                lc_phone := SUBSTR(SUBSTR(lc_contact_line,ln_start, ln_pos-ln_start),1,15);
            ELSIF ln_pos = 0 AND found = -1 AND ln_end >= ln_start THEN
                lc_phone := SUBSTR(SUBSTR(lc_contact_line,ln_start, ln_end-ln_start+1),1,15);
                found := 0;
            END IF;            

            ln_start := ln_pos + 1;
            ln_pos := INSTR(lc_contact_line,',',1,7);

            IF ln_pos > ln_start AND ln_pos > 0 THEN
                lc_fax_area_code := SUBSTR(SUBSTR(lc_contact_line,ln_start, ln_pos-ln_start),1,10);
            ELSIF ln_pos = 0 AND found = -1 AND ln_end >= ln_start THEN
                lc_fax_area_code := SUBSTR(SUBSTR(lc_contact_line,ln_start, ln_end-ln_start+1),1,10);
                found := 0;
            END IF;            

            ln_start := ln_pos + 1;
            
            IF ln_end >= ln_start  AND ln_pos > 0 THEN
                lc_fax := SUBSTR(SUBSTR(lc_contact_line,ln_start, ln_end-ln_start+1),1,15);
                found := 0;
            END IF; 
            
            IF found = 0 THEN
              FOR c_rec IN c_aops_vendor(lc_aops_number) LOOP
            
                found := 1;
            
                BEGIN
                
                    SELECT po_vendor_contacts_s.nextval INTO ln_vendor_conact_id FROM dual;
                    
                    INSERT INTO po_vendor_contacts (
                         vendor_contact_id
                        ,vendor_site_id
                        ,first_name
                        ,last_name
                        ,area_code
                        ,phone
                        ,fax_area_code
                        ,fax
                        ,email_address
                        ,department
                        ,last_update_date
                        ,last_updated_by
                        ,creation_date
                        ,created_by
                        ,last_update_login )
                    VALUES(
                         ln_vendor_conact_id
                        ,c_rec.vendor_site_id
                        ,lc_first_name
                        ,lc_last_name
                        ,lc_area_code
                        ,lc_phone
                        ,lc_fax_area_code
                        ,lc_fax
                        ,lc_email_address
                        ,lc_department
                        ,SYSDATE
                        ,-1
                        ,SYSDATE
                        ,-1
                        ,-1 );
                        
                    log_message('Inserted: VendContactId='||ln_vendor_conact_id||
                        ', VendSiteId='||c_rec.vendor_site_id||', LastName='||
                        lc_last_name||', FirstName='||lc_first_name);
                        
                EXCEPTION
                    WHEN OTHERS THEN
                        log_message('ERROR: Insert Failed, record=' ||lc_contact_line);
                END;
                
              END LOOP;
            END IF;
            
            IF found = 0 THEN
                log_message('ERROR: Invalid Record, record=' ||lc_contact_line);
            END IF;
        
        ELSE
            log_message('ERROR: Invalid Vendor, record=' ||lc_contact_line);
        END IF;

    END LOOP;

    IF UTL_FILE.IS_OPEN(l_utl_filetype) THEN
        UTL_FILE.FCLOSE(l_utl_filetype);
    END IF;
    
    COMMIT;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        x_errbuff := 'ERROR:No Records found';
        x_retcode := 2;
        log_message('ERROR:No Records found');
    WHEN UTL_FILE.INVALID_PATH THEN
        x_errbuff := 'ERROR:invalid path';
        x_retcode := 2;
        log_message('ERROR:invalid path');
    WHEN UTL_FILE.INVALID_MODE THEN
        x_errbuff := 'ERROR:invalid mode';
        x_retcode := 2;
        log_message('ERROR:invalid mode');
    WHEN UTL_FILE.INVALID_OPERATION THEN
        x_errbuff := 'ERROR:invalid operation';
        x_retcode := 2;
        log_message('ERROR:invalid operation');
    WHEN UTL_FILE.INTERNAL_ERROR THEN
        x_errbuff := 'ERROR:internal error';
        x_retcode := 2;
        log_message('ERROR:internal error');
    WHEN OTHERS THEN
        x_errbuff := 'ERROR:Untrapped error';
        x_retcode := 2;
        log_message('ERROR:Untrapped error');
        ROLLBACK;

END Service_contact_load;

PROCEDURE LOG_MESSAGE(pBUFF  IN  VARCHAR2) IS
BEGIN
  IF v_cp_enabled THEN
     IF fnd_global.conc_request_id > 0  THEN
         FND_FILE.PUT_LINE( FND_FILE.LOG, pBUFF);
     ELSE
         null;
     END IF;
  ELSE
    dbms_output.put_line(pbuff) ;
  END IF;
  EXCEPTION
     WHEN OTHERS THEN
        RETURN;
END LOG_MESSAGE;


END XX_OM_LOAD_CONTACT_PKG;
/
SHOW ERRORS PACKAGE BODY XX_OM_LOAD_CONTACT_PKG;
EXIT;
