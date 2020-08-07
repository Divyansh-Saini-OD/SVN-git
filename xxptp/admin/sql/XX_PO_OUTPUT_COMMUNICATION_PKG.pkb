create or replace PACKAGE BODY   XX_PO_OUTPUT_COMMUNICATION_PKG
AS
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- |      		Office Depot Organization                        |
  -- +===================================================================+
  -- | Name  : XX_PO_OUTPUT_COMMUNICATION_PKG                            |
  -- |         Custom pachage to fax Purchase Orders to the Right Fax    |
  -- |         server Defect 1438 - PO: FAX Functionality                |   
  -- |Version   Date        Author           Remarks                     |
  -- |=======   ==========  =============    ============================|
  -- |DRAFT 1A  17-May-2010 P.Marco          Initial draft version       |
  -- +===================================================================+

  ---------------------
  -- Global Variables
  ---------------------
  gc_current_step       VARCHAR2(500);
  gn_user_id            NUMBER   := FND_PROFILE.VALUE('USER_ID');
  gn_org_id             NUMBER   := FND_PROFILE.VALUE('ORG_ID');
  gn_request_id         NUMBER   := FND_GLOBAL.CONC_REQUEST_ID();


  gc_errbuff            VARCHAR2(500);
  gc_retcode            VARCHAR2(1);

  

  -----------------------------------------------
  -- Functions to pass return code and error code
  -- Back to Form Personalization
  ----------------------------------------------

  FUNCTION GET_RETURN_CODE  RETURN VARCHAR2
    IS
     BEGIN
             RETURN gc_retcode;

     END GET_RETURN_CODE;



  FUNCTION GET_ERRCODE_CODE RETURN VARCHAR2
   IS
     BEGIN
             RETURN gc_errbuff;

     END  GET_ERRCODE_CODE;




    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |      		Office Depot Organization   		                         |
    -- +===================================================================+
    -- | Name  : XX_SEND_EMAIL                                             |
    -- | Description :  Local Procedure to call OD: Emailer program         |
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks            	   |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  25-MAR-2010 P.Marco          Initial draft version       |
    -- |                                                                   |
    -- +===================================================================+

  PROCEDURE XX_SEND_EMAIL    (p_email_address  IN VARCHAR2 
                             ,p_email_title IN VARCHAR2 
                             ,p_email_body IN VARCHAR2 )
  AS
  
       ln_conc_id                NUMBER;
       
  BEGIN
             ln_conc_id := fnd_request.submit_request(
                       application => 'XXFIN'
                       ,program     => 'XXODEMAILER'
                       ,description => NULL
                       ,start_time  => SYSDATE
                       ,sub_request => FALSE
                       ,argument1   => p_email_address
                       ,argument2   => p_email_title
                       ,argument3   => p_email_body
                                                );  
              COMMIT;        
  
  END  XX_SEND_EMAIL;




    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |      		Office Depot Organization   		           |
    -- +===================================================================+
    -- | Name  : XX_VOID_PAYMENT                                           |
    -- | Description : Procedure to call standard po_output communication  |
    -- |               program.  Procedure will be called from form person-|
    -- |               alization form POXPOEPO
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks            	   |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  25-MAR-2010 P.Marco          Initial draft version       |
    -- |                                                                   |
    -- +===================================================================+





  PROCEDURE XX_PO_FAX_DOCUMENT   (p_po_number  IN NUMBER 
                                 ,p_po_vendor_id IN NUMBER 
                                 ,p_po_vendor_site_id IN NUMBER 
                                 ,p_lookup_code IN VARCHAR2
                                 ,p_release_num IN NUMBER DEFAULT NULL)
  AS 
         -------------------
         -- Define exception
         -------------------
          phone_number_format      EXCEPTION;
          submit_program           EXCEPTION;

          ln_payment_cnt            NUMBER;
          ln_check_id               NUMBER; 
          lc_current_step           VARCHAR2(500);
          lc_email_adds             VARCHAR2(250);
          lc_pay_grp_lkup_code      VARCHAR2(50);
          
          lc_email_address          fnd_user.email_address%TYPE;
          lc_email_title            VARCHAR2(50);
          
          ln_conc_id                NUMBER;
          ln_req_id                 NUMBER;
          lc_fax_area               po_vendor_sites_all.fax_area_code%TYPE;
          lc_fax_number             po_vendor_sites_all.fax%TYPE;
          lc_concat_fax             VARCHAR2(30);
          
          lc_vendor_site_code       po_vendor_sites_all.vendor_site_code%TYPE;  
          lc_vendor_name            PO_VENDORS.vendor_name%TYPE;    
          lc_vendor_info            VARCHAR2(250); 
          
          lc_template_code          VARCHAR2(50);
          lc_Blanket_Lines          VARCHAR2(1);
          
          lb_bool2                  BOOLEAN;
          lc_phase2                 VARCHAR2(80);
          lc_status2                VARCHAR2(80);
          lc_dev_phase2             VARCHAR2(30);
          lc_dev_status2            VARCHAR2(30);
          lc_message2               VARCHAR2(240); 
          
          l_user_id                 NUMBER;
          l_application_id          NUMBER;
          l_responsibility_id       NUMBER;
          w_style                   VARCHAR2 (100);
          
          lc_result                 BOOLEAN;
    BEGIN
    
        ----------------------
        -- intialize variables
        ----------------------
        lc_Blanket_Lines := 'Y';
                                              
        SELECT  email_address
          INTO  lc_email_address
          FROM  fnd_user 
         WHERE  user_id = gn_user_id;
    
        ---------------------------------------------------
        -- Determine the template type for the PO document
        ---------------------------------------------------
        IF p_lookup_code = 'STANDARD' THEN
              lc_template_code := 'XX_STD_PO_FAX_RTF';
              
        ELSIF p_lookup_code = 'BLANKET' THEN

           IF p_release_num IS NULL THEN       
                lc_template_code := 'XX_BLNK_PA_FAX_RTF';
           ELSE
                lc_template_code := 'XX_BLNK_REL_FAX_RTF';
                lc_Blanket_Lines := 'N';
                
           END IF;
           
           lc_Blanket_Lines := 'N';     

        ELSIF  p_lookup_code = 'CONTRACT' THEN
            lc_template_code := 'XX_CONTRACT_PA_FAX_RTF'; 

        END IF;
   
        --------------------------------------------------
        -- Get fax number from the supplier's site used to
        -- submit po_output communication program
        --------------------------------------------------
          SELECT  pvsa.fax
                 ,pvsa.fax_area_code 
                 ,vendor_site_code
                 ,Vendor_name
            INTO lc_fax_number
                 ,lc_fax_area
                 ,lc_vendor_site_code
                 ,lc_vendor_name
            FROM PO_VENDOR_SITES_ALL pvsa
                ,PO_VENDORS          pva
           WHERE pvsa.Vendor_id      = p_po_vendor_id
             AND pvsa.Vendor_site_id = p_po_vendor_site_id
             AND pva.vendor_id       = pvsa.Vendor_id
             AND pvsa.org_id         = gn_org_id;   
          
          
          lc_concat_fax  :=  '1'||lc_fax_area|| lc_fax_number; 
          
          lc_vendor_info :=  ' VENDOR NAME:'|| SUBSTR(lc_vendor_name,1,35)||','
                           ||' VENDOR SITE:'|| SUBSTR(lc_vendor_site_code,1,25)
                          ||',' ||' DOC NUMBER:'||p_po_number ||' ';
                           
                           
          
          IF (lc_fax_area IS NULL) OR (lc_fax_number IS NULL) THEN
          
               gc_errbuff := 'Fax area code or fax number is missing from '
                           || lc_vendor_info;
           
               RAISE phone_number_format;
               
          END IF;
          
          IF length(lc_concat_fax) < 11 THEN

               gc_errbuff := 'Fax area code or fax number is in a invalid '||
                             'format for '|| lc_vendor_info; 
                             
               RAISE phone_number_format;
               
          END IF;     
          

          
          ----------------------
          -- Set Printer options
          ----------------------
          lc_result := apps.FND_REQUEST.SET_PRINT_OPTIONS('HFPS'  --printer name
                                                          ,'LANDSCAPE'   --style
                                                         ,1
                                                        ,TRUE
                                                         ,'N');
          
          COMMIT;
          -----------------------------------------------------------
          lc_current_step := 'Submit POXPOPDF for:'; 
          -----------------------------------------------------------
          ln_req_id := fnd_request.submit_request('PO'
                                                ,'POXPOPDF'
                                                ,''
                                                ,'01-OCT-04 00:00:00'
                                                , FALSE
                                                ,'R'
                                                ,NULL 
                                                ,p_po_number
                                                ,p_po_number
                                                ,p_release_num
                                                ,p_release_num
                                                ,NULL
                                                ,NULL
                                                ,NULL
                                                ,'N'
                                                ,'Y'
                                                ,NULL
                                                ,gn_user_id
                                                ,'Y'
                                                ,lc_concat_fax
                                                ,lc_Blanket_Lines
                                                ,'Communicate'
                                                ,'N'
                                                ,'N'
                                                ,'Y'
                                                ,NULL
                                                ,NULL
                                                ,NULL
                                                ,p_lookup_code
                                                ,lc_template_code
                                                ,NULL
                                                ,NULL); 


           
          COMMIT; 
          -------------------------------------------------------	
          --'Waiting for POXPOPDF Report '
          --------------------------------------------------------  
           
          IF ln_req_id > 0  THEN  
          
               lb_bool2 := fnd_concurrent.wait_for_request
                                              (ln_req_id
                                               ,5
                                               ,5000
                                               ,lc_phase2
                                               ,lc_status2
                                               ,lc_dev_phase2
                                               ,lc_dev_status2
                                               ,lc_message2
                                               );  
                                    
             
            IF (lc_dev_phase2 = 'COMPLETE') AND (lc_dev_status2 = 'NORMAL') THEN
 
                  lc_email_title := 'PO Document:'|| p_po_number ||
                                          ' sent to fax server';
                                          
                  gc_errbuff := ' Document was sent to fax server for ' 
                               || lc_vendor_info ||'See Request ID:'||ln_req_id
                               ||' for details';                 
           
                  XX_SEND_EMAIL(lc_email_address, lc_email_title, gc_errbuff);
                          
                  gc_retcode := 0;         
                             
             ELSE
                   gc_errbuff := ' Please check log file of Request ID ' 
                             || ln_req_id || '. Fax may not have been sent for '
                             || lc_vendor_info;
                             
                   gc_retcode := 1; 
                   RAISE submit_program;

             END IF;
             
         ELSE
         
              gc_errbuff :=' Error is submission of PO Output communication '
                           ||'program occured.  Fax was not sent to '
                           || lc_vendor_info;

              gc_retcode := 1;                            
              RAISE submit_program;
              
         END IF;

    EXCEPTION
        WHEN submit_program THEN
 
            lc_email_title :=  'PO Document:'|| p_po_number 
                                         ||' Faxing errors occured';
   
           
            XX_SEND_EMAIL(lc_email_address, lc_email_title, gc_errbuff);
            
            gc_retcode := 1;        
        
        WHEN phone_number_format THEN
        
            lc_email_title :='Faxing errors occured '
                               || 'for PO Document:'|| p_po_number;        


            XX_SEND_EMAIL(lc_email_address, lc_email_title,
                                             substr(gc_errbuff,1,239));
            gc_retcode := 1;

        WHEN OTHERS THEN

            lc_email_title :='Faxing PO Document:'
                                || p_po_number ||' Error occured';
                                
            gc_errbuff := SUBSTR('Others Error:'
                                 || SQLERRM () ,1,200);
                                
          
            XX_SEND_EMAIL(lc_email_address, lc_email_title, gc_errbuff);             
            gc_retcode := 1;                    
        
         
    END XX_PO_FAX_DOCUMENT ; 

END  XX_PO_OUTPUT_COMMUNICATION_PKG;
/

