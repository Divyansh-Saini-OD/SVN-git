SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_PO_XMLG_MOD_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/Office Depot/Consulting Organization             |
-- +===================================================================+
-- | Name       : XX_PO_XMLG_MOD_PKG.pkb                               |
-- | Description: This package is used to select all the PO, which     |
-- |got modified without revision.This package also raises the poxml   |
-- |event for the corrosponding PO's using standard package proc.      |
-- |PO_XML_UTILS_GRP.regenandsend and generates XML file for the same. |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 11-APR-2007  Seemant Gour     Initial draft version       |
-- |DRAFT 1b 28-APR-2007  Vikas Raina      Updated after review        |
-- |1.0      03-MAY-2007  Seemant Gour     Baseline for Release        |
-- |1.1      02-NOV-2007  Seemant Gour     Updated as per Onsite Review|
-- |                                       comments from Paul-Dsouza:  |
-- |                                       Removed the reference to    |
-- |                                       'Closed for Receiving' from code|
-- |1.2      27-NOV-2007  Lalitha Budithi  Query change to order the results|
-- |                                       by last_update_date         |
-- |                                                                   |
-- +===================================================================+
AS                             
    lc_err_buf  VARCHAR2(5000);
    
-- +====================================================================+
-- | Name         : GET_UPDATED_PO                                      |
-- | Description  : This procedure select the headers and lines details |
-- | for all the inscope PO's which are revision less modified for all  |
-- | APPROVED purchase orders.                                          |
-- |                                                                    |
-- |                                                                    |
-- | Parameters   : x_err_buf    OUT  VARCHAR2  Error Message           |
-- |                x_retcode    OUT  NUMBER    Error Code              |
-- |                                                                    |
-- | Returns      : None                                                |
-- +====================================================================+
                                                   
   PROCEDURE GET_UPDATED_PO(                       
                      x_err_buf      OUT   VARCHAR2
                     ,x_retcode      OUT   NUMBER  
                     )                             
                                                   
   IS                                              
               
-- Declaring Local variables 
      lb_ret           BOOLEAN;
      p_last_run_date  DATE;           -- Capture last run date in date format
      p_last_run_date1 VARCHAR2(100);  -- Capture last run date in Varchar initially      
      lb_chk_for_data  BOOLEAN := FALSE ; -- Captures if any record was picked for processing
      ln_org_id        NUMBER := FND_PROFILE.VALUE('ORG_ID') ; -- Get the org id
      --
      -- Declaring Cursor
      --

      CURSOR lcu_fetch_po (p_last_run_date DATE) 
      IS
      SELECT PHA1.po_header_id 
           , PHA1.segment1 
           , PHA1.type_lookup_code 
           , PHA1.attribute_category 
           , PHA1.revision_num 
           , PHA1.attribute6 
           , PHA1.attribute7 
           , PHA1.attribute8 
           , PHA1.attribute9 
           , PHA1.closed_code 
           , PHA1.last_updated_by 
           ,(SELECT GREATEST(pha1.last_update_date 
                           , MAX(pl1.last_update_date)) 
             FROM  po_lines pl1 
             WHERE pha1.po_header_id = pl1.po_header_id) 
             last_update_date 
      FROM  po_headers         PHA1 
          , po_headers_archive PHAA 
      WHERE PHA1.po_header_id         = PHAA.po_header_id 
      AND   PHA1.authorization_status = 'APPROVED' 
      AND   PHA1.revision_num         = PHAA.revision_num 
      AND   PHA1.last_update_date     > p_last_run_date
      AND ((NVL(PHA1.closed_code,0) <> NVL(PHAA.closed_code,0) 
      AND   PHA1.closed_code        IN ('OPEN', 'CLOSED')) 
      OR   (PHA1.attribute_category  <> PHAA.attribute_category) 
      OR   (PHA1.attribute_category  = 'Trade-Import' 
      AND  (NVL(PHA1.attribute6,0)   <> NVL(PHAA.attribute6,0) 
      OR    NVL(PHA1.attribute7,0)   <> NVL(PHAA.attribute7,0) 
      OR    NVL(PHA1.attribute8,0)   <> NVL(PHAA.attribute8,0) 
      OR    NVL(PHA1.attribute9,0)   <> NVL(PHAA.attribute9,0)))) 
      UNION 
      SELECT PHA2.po_header_id 
           , PHA2.segment1 
           , PHA2.type_lookup_code 
           , PHA2.attribute_category 
           , PHA2.revision_num 
           , PHA2.attribute6 
           , PHA2.attribute7 
           , PHA2.attribute8 
           , PHA2.attribute9 
           , PHA2.closed_code 
           , PHA2.last_updated_by 
           ,(SELECT GREATEST (pha2.last_update_date 
                  , MAX (pl.last_update_date)) 
             FROM  po_lines pl 
             WHERE pl.po_header_id = pha2.po_header_id) 
             last_update_date 
      FROM  po_headers       PHA2 
          , po_lines         PLA 
          , po_lines_archive PLAA 
      WHERE PHA2.po_header_id         = PLA.po_header_id 
      AND   PLA.po_header_id          = PLAA.po_header_id 
      AND   PLA.po_line_id            = PLAA.po_line_id 
      AND   PLA.last_update_date      > p_last_run_date
      AND   PHA2.authorization_status = 'APPROVED' 
      AND   PHA2.revision_num         = PLAA.revision_num 
      AND ((NVL(PLA.closed_code,0) <> NVL(PLAA.closed_code,0) 
      AND   PLA.closed_code IN ('OPEN', 'CLOSED')) 
      OR    NVL(PLA.attribute6,0)  <> NVL(PLAA.attribute6,0)) 
      ORDER BY 12 ASC ;-- ORDER BY 11 ASC;        Changed by Lalitha Budithi on 27-NOV-2007.
      
   --
   -- Begining of the Procedure
   --
   BEGIN
           
      -- Get the last run date of the concurrent program from the profile.
         p_last_run_date1 := fnd_profile.VALUE_SPECIFIC(name  => 'XX_PO_XML_LASTRUNDATE',
                                                        responsibility_id => FND_PROFILE.VALUE('RESP_ID')  ,
                                                        application_id => fnd_profile.value('RESP_APPL_ID'),
                                                        org_id => ln_org_id);
                 
      --
      -- To print report in the OUTPUT file
      --
                                                                                            
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,                                                            
        'Office Depot Project Simplify                                                     DATE:'|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                       ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                          POXML REPORT');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                      -----------------------');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                       ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'PO Numbers                 Last Update date');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '------------------------------------------------');
      
      IF p_last_run_date1 IS NULL THEN
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    ');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'OD: PO Last Run Date profile is NULL');
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'OD: PO Last Run Date profile is NULL');
         x_err_buf   := 'OD: PO Last Run Date profile is NULL';
         x_retcode   := 1 ;
         RETURN;
      END IF;
      
      p_last_run_date :=  to_date(p_last_run_date1,'DD-MON-YY HH24:MI:SS');         
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Last Run date : '||p_last_run_date);
      
      FOR lcu_fetch_po_cur IN lcu_fetch_po(p_last_run_date)
      LOOP
         
         /*
         Fnd_File.PUT_LINE(Fnd_File.LOG, 'p_po_header_id1: ' ||lcu_fetch_po_cur.po_header_id);                      
         Fnd_File.PUT_LINE(Fnd_File.LOG, 'p_po_type1: '      ||lcu_fetch_po_cur.type_lookup_code );                           
         Fnd_File.PUT_LINE(Fnd_File.LOG, 'p_po_revision1: '  ||lcu_fetch_po_cur.revision_num);                       
         Fnd_File.PUT_LINE(Fnd_File.LOG, 'lc_user_name1: '   ||lcu_fetch_po_cur.last_updated_by); 
         Fnd_File.PUT_LINE(Fnd_File.LOG, '************************************************** '); 
         Fnd_File.PUT_LINE(Fnd_File.LOG, 'Before calling to the std. regenandsend API procedure '); 
         */
         
         -- Set lb_chk_for_data to TRUE which means atleast one record is picked up.
            lb_chk_for_data :=  TRUE ;
         --                                                                                         
         -- Calling INVOKE_POXML_WF_PROCESS procedure to raise the poxml event.for each purchase order                                                                                                    
         --                                                                                         
         INVOKE_POXML_WF_PROCESS(p_po_header_id       => lcu_fetch_po_cur.po_header_id              
                               , p_po_type            => lcu_fetch_po_cur.type_lookup_code          
                               , p_po_revision        => lcu_fetch_po_cur.revision_num              
                               , p_user_id            => lcu_fetch_po_cur.last_updated_by);         
         --                                                                                         
         -- Updating PO's in the archive table with the value from PO HEADERS and PO LINES            
         -- tables so that its not picked in the next run.                                          
         --                                                                                         
         BEGIN                                                                                      
                                                                                                    
            UPDATE po_headers_archive                                                               
            SET    closed_code        = lcu_fetch_po_cur.closed_code                                
                 , attribute_category = lcu_fetch_po_cur.attribute_category                         
                 , attribute6         = lcu_fetch_po_cur.attribute6                                 
                 , attribute7         = lcu_fetch_po_cur.attribute7                                 
                 , attribute8         = lcu_fetch_po_cur.attribute8                                 
                 , attribute9         = lcu_fetch_po_cur.attribute9                                 
            WHERE po_header_id        = lcu_fetch_po_cur.po_header_id;                              
                                                                                                    
         EXCEPTION                                                                                  
            WHEN OTHERS THEN                                                                        
             --Fnd_File.PUT_LINE(Fnd_File.LOG, 'Error in Updating Headers archive table: ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255));                                                                    
              lc_err_buf := lc_err_buf ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255);                    
              lc_err_buf := 'Error in Updating Headers archive table.'|| lc_err_buf;               
         END;                                                                                       
                                                                                                    
         BEGIN                                                                                      
                                                                                                    
            UPDATE po_lines_archive PLAA                                                            
            SET closed_code = (SELECT closed_code                                                   
                               FROM   po_lines PL                                                   
                               WHERE  PL.po_line_id     = PLAA.po_line_id                           
                               AND    PLAA.po_header_id = PL.po_header_id                           
                               AND    PLAA.revision_num = lcu_fetch_po_cur.revision_num)            
              , attribute6 =  (SELECT attribute6                                                    
                               FROM   po_lines PL                                                   
                               WHERE  PL.po_line_id     = PLAA.po_line_id                           
                               AND    PLAA.po_header_id = PL.po_header_id                           
                               AND    PLAA.revision_num = lcu_fetch_po_cur.revision_num)            
            WHERE PLAA.po_header_id = lcu_fetch_po_cur.po_header_id;                                
                                                                                                    
         EXCEPTION                                                                                  
            WHEN OTHERS THEN                                                                        
             --Fnd_File.PUT_LINE(Fnd_File.LOG, 'Error in Updating Lines archive table: ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255));                                                                      
               lc_err_buf := lc_err_buf ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255);                    
               lc_err_buf := 'Error in Updating Lines archive table.'|| lc_err_buf;                 
         END;                                                                                       
                                                                                                    
         --                                                                                         
         -- Updating profile value 'XX_PO_XML_LASTRUNDATE' with the last_update of the PO at organization level.          
         --                                                                                                                                                                                         
         
         BEGIN
         
            --lb_ret := FND_PROFILE.SAVE_USER('XX_PO_XML_LASTRUNDATE', TO_CHAR((lcu_fetch_po_cur.last_update_date),'DD-MON-YYYY HH24:MI:SS'));
            -- Updating profile for the organization
            lb_ret := FND_PROFILE.SAVE('XX_PO_XML_LASTRUNDATE',TO_CHAR((lcu_fetch_po_cur.last_update_date),'DD-MON-YYYY HH24:MI:SS'),'ORG',ln_org_id);
         
         END;
                                                                                                    
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT, lcu_fetch_po_cur.segment1 ||'                 '||TO_CHAR(lcu_fetch_po_cur.last_update_date,'DD-MON-YYYY HH24:MI:SS'));         
       --Fnd_File.put_line(Fnd_File.LOG, 'In report writing position. segment1 is : '   ||lcu_fetch_po_cur.segment1);                                                                                   
                                                                                                    
                                                                                                    
      END LOOP;                                                                                     
      COMMIT;
      
      IF (NOT lb_chk_for_data) THEN
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,' ');  
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'---------------------------------------------------------'); 
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'No rows selected for processing ');
      END IF;
      
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT,' ');  
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'---------------------------------------------------------'); 
      
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'Program completed successfully ');                                                                                                      
   EXCEPTION                                                                                        
      WHEN OTHERS THEN                                                                              
            x_retcode := 2;                                                                         
            --Logging error as per the standards;                                                   
            Fnd_File.PUT_LINE(Fnd_File.LOG, 'Error in XX_PO_XMLG_MOD_PKG.GET_UPDATED_PO: ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255));                                                                    
                                                                                                    
            lc_err_buf := lc_err_buf ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255);                       
            lc_err_buf := 'Error in XX_PO_XMLG_MOD_PKG.GET_UPDATED_PO.'|| lc_err_buf;               
            x_err_buf  := lc_err_buf ;
   END GET_UPDATED_PO;                                                                              
                                                                                                    
-- +====================================================================+                           
-- | Name         : INVOKE_POXML_WF_PROCESS                             |                           
-- | Description  : This procedure calls the standard package           |                           
-- |procedure to raise poxml event for the POXML workflow.              |                           
-- |                                                                    |                           
-- | Parameters   : p_po_header_id        IN NUMBER                     |                           
-- |                p_po_type             IN VARCHAR2                   |                           
-- |                p_po_revision         IN NUMBER                     |                           
-- |                p_user_id             IN NUMBER                     |                           
-- |                                                                    |                           
-- |                                                                    |                           
-- | Returns      : None                                                |                           
-- +====================================================================+                           
                                                                                                    
   PROCEDURE INVOKE_POXML_WF_PROCESS(p_po_header_id       IN NUMBER                                 
                                   , p_po_type            IN VARCHAR2                               
                                   , p_po_revision        IN NUMBER                                 
                                   , p_user_id            IN NUMBER                                 
                                                                   )                                
   IS                                                                                               
                                                                                                    
   --                                                                                               
   -- Declaring local variables                                                                     
   --                                                                                               
      lc_user_name FND_USER.user_name%TYPE; -- Variable to declare user name                                                                  
                                                                                                    
   --                                                                                               
   -- Begining of the Procedure                                                                     
   --                                                                                               
   BEGIN                                                                                            
                                                                                                    
      BEGIN                                                                                         
                                                                                                    
         SELECT USER_NAME                                                                           
         INTO   lc_user_name                                                                        
         FROM   fnd_user                                                                            
         WHERE  user_id = p_user_id;                                                                
                                                                                                    
      EXCEPTION                                                                                     
         WHEN NO_DATA_FOUND THEN                                                                    
            --Logging error as per the standards;                                                   
            Fnd_File.PUT_LINE(Fnd_File.LOG, 'No data found for getting the user name for the user_id: '||p_user_id ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255));                                            
            lc_err_buf := lc_err_buf ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255);                       
            lc_err_buf := 'NO DATA FOUND for getting the user name. '|| lc_err_buf;                 
                                                                                                    
         WHEN OTHERS THEN                                                                           
            --Logging error as per the standards;                                                   
            Fnd_File.PUT_LINE(Fnd_File.LOG, 'When other error for getting the user name: '||p_user_id ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255));                                                         
            lc_err_buf := lc_err_buf ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255);                       
            lc_err_buf := 'WHEN OTHER ERROR for getting the user name. '|| lc_err_buf;              
                                                                                                    
      END;                                                                                          
                                                                                                    
                                                                                                    
      --                                                                                            
      -- Calling Standard package procedure to raise poxml event.                                   
      --                                                                                            
      BEGIN                                                                                         
         
         /*
         Fnd_File.PUT_LINE(Fnd_File.LOG, 'p_po_header_id: ' ||p_po_header_id);                      
         Fnd_File.PUT_LINE(Fnd_File.LOG, 'p_po_type: '      ||p_po_type);                           
         Fnd_File.PUT_LINE(Fnd_File.LOG, 'p_po_revision: '  ||p_po_revision);                       
         Fnd_File.PUT_LINE(Fnd_File.LOG, 'USER_ID: '        ||Fnd_Profile.value('USER_ID'));        
         Fnd_File.PUT_LINE(Fnd_File.LOG, 'RESP_ID: '        ||Fnd_Profile.Value('RESP_ID'));        
         Fnd_File.PUT_LINE(Fnd_File.LOG, 'RESP_APPL_ID: '   ||Fnd_Profile.value('RESP_APPL_ID'));   
         Fnd_File.PUT_LINE(Fnd_File.LOG, 'lc_user_name: '   ||lc_user_name);                        
         */
                                                                                                    
         Po_Xml_Utils_Grp.regenandsend (p_po_header_id                                              
                                      , p_po_type                                                   
                                      , p_po_revision                                               
                                      , Fnd_Profile.value('USER_ID')                                
                                      , Fnd_Profile.Value('RESP_ID')                                
                                      , Fnd_Profile.value('RESP_APPL_ID')                           
                                      , lc_user_name                                                
                                      );                                                            
                                                                                                             
      EXCEPTION                                                                                     
         WHEN OTHERS THEN                                                                           
           --Logging error as per the standards;                                                  
             Fnd_File.PUT_LINE(Fnd_File.LOG, 'Error in calling PO_XML_UTILS_GRP.regenandsend package proc.: ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255));                                                 
             lc_err_buf := lc_err_buf ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255);                      
             lc_err_buf := 'Error in calling PO_XML_UTILS_GRP.regenandsend.'|| lc_err_buf;           
      END;                                                                                                                                                                                             
                                                                                                    
   EXCEPTION                                                                                        
      WHEN OTHERS THEN                                                                              
            --Logging error as per the standards;                                                   
            Fnd_File.PUT_LINE(Fnd_File.LOG, 'Error in XX_PO_XMLG_MOD_PKG.INVOKE_POXML_WF_PROCESS: '||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255));                                                           
            lc_err_buf := lc_err_buf ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 255);                       
            lc_err_buf := 'Error in XX_PO_XMLG_MOD_PKG.INVOKE_POXML_WF_PROCESS.'|| lc_err_buf;      
                                                                                                    
   END INVOKE_POXML_WF_PROCESS;  

END XX_PO_XMLG_MOD_PKG;

/

SHOW ERRORS;

EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
