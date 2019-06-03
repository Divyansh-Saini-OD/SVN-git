SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


create or replace
PACKAGE BODY XX_QA_SC_VEN_ADT_RESULT_PKG AS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : XX_QA_SC_ADUIT_RESULT_PKG                                       |
-- | Description      : This Program will load all SC Audit data             |
-- |                    into EBIZ                                            |
-- +=========================================================================+
PROCEDURE Log_Exception ( p_error_location     IN  VARCHAR2
                         ,p_error_message_code IN  VARCHAR2
                         ,p_error_msg          IN  VARCHAR2 )
IS
  ln_login     PLS_INTEGER           := FND_GLOBAL.Login_Id;
  ln_user_id   PLS_INTEGER           := FND_GLOBAL.User_Id;
BEGIN
  XX_COM_ERROR_LOG_PUB.log_error
     (
      p_return_code             => FND_API.G_RET_STS_ERROR
     ,p_msg_count               => 1
     ,p_application_name        => 'XX_QA'
     ,p_program_type            => 'Custom Messages'
     ,p_program_name            => 'XX_QA_SC_VEN_AUDIT_PKG'
     ,p_program_id              => null
     ,p_module_name             => 'QASC'
     ,p_error_location          => p_error_location
     ,p_error_message_code      => p_error_message_code
     ,p_error_message           => p_error_msg
     ,p_error_message_severity  => 'MAJOR'
     ,p_error_status            => 'ACTIVE'
     ,p_created_by              => 500904 --ln_user_id
     ,p_last_updated_by         => 500904 --ln_user_id
     ,p_last_update_login       => 500904 --ln_login
     );
END Log_Exception;
PROCEDURE VENDOR_AUDIT_RESULT_PUB(p_header_rec    IN XX_QA_SC_VEN_AUDIT_BPEL_PKG.header_match_rec       
                             ,p_audit_rec         IN XX_QA_SC_VEN_AUDIT_BPEL_PKG.audit_Rec_Type
                             ,p_vendor_tbl        IN XX_QA_SC_VEN_AUDIT_BPEL_PKG.vendor_tbl_Type
                             ,p_auditor_tbl       IN XX_QA_SC_VEN_AUDIT_BPEL_PKG.auditors_tbl_type
                             ,p_findings_tbl      IN XX_QA_SC_VEN_AUDIT_BPEL_PKG.findings_tbl_type
                             ,p_violation_tbl     IN XX_QA_SC_VEN_AUDIT_BPEL_PKG.violation_tbl_type
                             ,x_lc_return_cd         OUT VARCHAR2
                             ,x_lc_return_msg        OUT VARCHAR2
                            )
IS
-- Constant variables

lc_log_profile_value VARCHAR2(10) := fnd_profile.value('XX_QA_SC_AUDIT_LOG');
lc_prcoess_status     VARCHAR2(2) := '1';
lc_org_code           VARCHAR2(10) := 'PRJ';
lc_plan_name          VARCHAR2(50) := 'OD_SC_VENDOR_AUDIT';
lc_insert_type        VARCHAR2(2) := '1';
lc_matching_elements  VARCHAR2(50) := 'OD_SC_INSPECTION_N0,OD_SC_INSERT_IFACE_ID';
ln_vio_count          NUMBER := 0;
ln_find_count         NUMBER := 0;
ln_count              NUMBER := 0;
ln_audit_count        number := 0;
lc_vend_exists_count  NUMBER := 0;
ln_rec_count          NUMBER := 0;
ln_update_rec_count   NUMBER := 0;
-- ******* temporary variables for Header Record *********************
lc_message_invoke_for VARCHAR2(100);
lc_vendor_id          NUMBER; --VARCHAR2(150);
lc_vendor_name        VARCHAR2(150);
lc_msg_time           DATE;
-- *******temporary variables for Audit Record ***********************
lc_trans_status                VARCHAR2(150) ;
lc_client                      VARCHAR2(150) ;
lc_inspection_no               VARCHAR2(150) ;
lc_inspection_id               VARCHAR2(150) ;
lc_inspection_type             VARCHAR2(150) ;
lc_service_type                VARCHAR2(150) ;
lc_qa_profile                  VARCHAR2(150) ;
lc_status                      VARCHAR2(150) ;
ld_complete_by_start_date      DATE ;
ld_complete_by_end_date        DATE ;
ld_audit_schduled_date         DATE ;
ld_inspection_date             DATE ;
lc_inspection_time_in          VARCHAR2(10) ;
lc_inspection_time_out         VARCHAR2(10) ;
ld_inspection_schduled_date    DATE ;
ld_initial_inspection_date     DATE ;
lc_relationships               VARCHAR2(150) ;
ld_inspectors_schduled         VARCHAR2(150); 
lc_inspection_month            VARCHAR2(10) ;
lc_inspection_year             VARCHAR2(4) ;
-- ************temporary variables for VEMDOR Record table type**************
-- *****Not using for this release ******
lc_od_vendor_no                VARCHAR2(150); 
lc_sc_vendor                   VARCHAR2(150);
--lc_vendor_address        contact_add_Rec_Type;
--lc_vendor_contact      vend_contact_Rec_Type;
lc_entity_id                   VARCHAR2(150);
lc_od_factory_no               VARCHAR2(150);
lc_factory_name                 VARCHAR2(150);
lc_base_address                VARCHAR2(150);
lc_city                        VARCHAR2(150);
lc_state                       VARCHAR2(150);
lc_country                     VARCHAR2(150); 
--lc_factory_contacts          vend_contact_Rec_Type;
lc_factory_status              VARCHAR2(150);
lc_factory_contacts            VARCHAR2(150);
lc_invoice_no                  VARCHAR2(150);
ld_invoice_date                DATE ;
lc_invoice_amount              VARCHAR2(150);
lc_payment_method              VARCHAR2(150);
ld_payment_date                DATE;
lc_payment_amount              VARCHAR2(150);
lc_grade                       VARCHAR2(150);
lc_region                      VARCHAR2(150);
lc_sub_region                  VARCHAR2(150);
lc_ven_contact_name            VARCHAR2(150);
lc_ven_address_1               VARCHAR2(150);
lc_ven_address_2               VARCHAR2(150);
lc_ven_address_3               VARCHAR2(150);
lc_ven_address_4               VARCHAR2(150);
lc_ven_address_city            VARCHAR2(150);
lc_ven_address_state           VARCHAR2(150);
lc_ven_address_country         VARCHAR2(150);
lc_ven_contact_type            VARCHAR2(150);
lc_ven_contact_no              VARCHAR2(150);
lc_contact_address             VARCHAR2(150);
lc_contact_address_1           VARCHAR2(150);
lc_contact_address_2           VARCHAR2(150);
lc_contact_ddress_3            VARCHAR2(150);
lc_contact_address_4           VARCHAR2(150);
lc_contact_address_city        VARCHAR2(150);
lc_contact_address_state       VARCHAR2(150);
lc_contact_address_country     VARCHAR2(150);
lc_ven_contact                 VARCHAR2(150);
lc_agent                       VARCHAR2(150);
lc_rush_audit                  VARCHAR2(150); 
lc_factory_phone               VARCHAR2(150);
-- ***************temporary variables for AUDITORS Record table type ***********
-- *****Not using for this release ******
lc_od_sc_auditor_name      VARCHAR2(150) := '';
lc_od_sc_auditor_level     VARCHAR2(150):= '';  
-- temporary variables for FINDINGS Record table type
lc_question_code        VARCHAR2(150);
lc_section              VARCHAR2(150);
lc_sub_section          VARCHAR2(150); 
lc_question             VARCHAR2(150); 
lc_answer               VARCHAR2(150);
lc_nayn                 VARCHAR2(40);
lc_auditor_comments     VARCHAR2(150);
-- temporary variables for VIOLATIONS Record table type
lc_viol_code            VARCHAR2(150);
lc_viol_flag            VARCHAR2(150);
lc_viol_text            VARCHAR2(150);
lc_viol_section         VARCHAR2(150);
lc_viol_sub_section     VARCHAR2(150);
lc_viol_question        VARCHAR2(150);
lc_viol_auditor_comments VARCHAR2(150);
lc_interface_error_status   VARCHAR2(3):= NULL;
--lx_return_cd VARCHAR2(100);
--lx_return_msg VARCHAR2(100);
lc_dft_vendor_id        VARCHAR2(150);
lc_dft_region           VARCHAR2(150);
lc_dft_region_sub       VARCHAR2(150);
lc_dft_service_type     Q_OD_SC_VENDOR_AUDIT_V.OD_SC_SERVICE_TYPE%TYPE; --VARCHAR2(150);
lc_dft_factory_id       VARCHAR2(150);
lc_dft_agent            VARCHAR2(150);
lc_dft_grade            VARCHAR2(150);
ld_dft_inspect_date     DATE;
lc_match_flag           VARCHAR2(1) := 'Y';
lc_match_msg            VARCHAR2(2500):= 'Final Data was not matched with Drfat for';
v_request_id            NUMBER;
v_user_id               NUMBER := fnd_global.user_id;
lc_log_msg              VARCHAR2(2000);
x_return_cd     VARCHAR2(100);
x_return_msg    VARCHAR2(2000);
ld_sysdate      DATE;
lc_sysdate     VARCHAR2(40);
BEGIN -- begin 1
-- ************* Audit Log************************************************************************************
-- #############################################################################################################
              IF lc_log_profile_value = 'Y' THEN
                select to_char(sysdate,'MM-DD-YYYY HH24:MI:SS') into lc_sysdate from dual;
                  lc_log_msg := 'STEP-1 ' || p_audit_rec.transmission_status || ' message Received at '|| lc_sysdate ||  ' For Inspection No ' || p_audit_rec.Inspection_No;    
                    Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_PKG'
                                    ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                    ,p_error_msg          =>   lc_log_msg);
                --   dbms_output.put_line('Log message' || lc_log_msg);                    
                END IF; 
-- #############################################################################################################                
x_return_cd := 'Y';
ln_find_count :=  p_findings_tbl.count;
ln_vio_count  :=  p_violation_tbl.count ;
lc_trans_status := p_audit_rec.transmission_status;
-- *************************Logic to set the process status either Insert or Update*************************
-- #############################################################################################################
 If TRIM(UPPER(lc_trans_status)) = 'DRAFT' then
            lc_prcoess_status := '1';
        -- Audit Log
                          IF lc_log_profile_value = 'Y' THEN
                            lc_log_msg := 'STEP-2' || ' Draft Version.process status is: ' || lc_prcoess_status;
                            Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_PKG'
                                            ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                            ,p_error_msg          =>   lc_log_msg);
                           END IF; 
 Else
            Select count(*) Into ln_audit_count from Q_OD_GSO_VENDOR_MASTER_V
            Where od_sc_vendor_number = p_header_rec.vendor_id; 
                If ln_audit_count > 0 then
                    lc_prcoess_status := '2';
                                -- Audit Log
                                    IF lc_log_profile_value = 'Y' THEN
                                          lc_log_msg := 'STEP-2A' || ' Final Version , Draft recird exists.process status: ' || lc_prcoess_status;
                                          Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_PKG'
                                                         ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                          ,p_error_msg          =>   lc_log_msg);
                                     END IF; 
                Else
                      lc_prcoess_status := '1';
                                -- Audit Log 
                                     IF lc_log_profile_value = 'Y' THEN
                                            lc_log_msg := 'STEP-2B' || ' Final Version But No Draft recird exists.process status: ' || lc_prcoess_status;
                                            Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_PKG'
                                                            ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                            ,p_error_msg          =>   lc_log_msg);
                                     END IF; 
                End if;
 End if;
--**************************************End for Process status*************************************************
-- #############################################################################################################
-- ************************************** Checking the Vendor is exists are not in the system ******************
-- #############################################################################################################
        Begin  --Begin 2
          SELECT count(*) 
          --od_sc_vendor_no,od_sc_vendor_name 
          INTO lc_vend_exists_count 
          --lc_venodr_id,lc_venodr_name 
          FROM Q_OD_GSO_VENDOR_MASTER_V           
          WHERE od_sc_vendor_number =  p_header_rec.vendor_id    
          -- AND TRIM(UPPER(p_header_rec.vendor_name))
          ;
 -- **********************************Setting process status as  Error(3) if vendor doesn't exists********************       
        IF lc_vend_exists_count = 0 then
           lc_interface_error_status := 'E';
           lc_prcoess_status := '3';
              -- Audit Log
                          IF lc_log_profile_value = 'Y' THEN
                            lc_log_msg := 'STEP-3' || ' Vendor does not exists. Received Vendo Id is  ' || p_header_rec.vendor_id;
                            Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_PKG'
                                           ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                           ,p_error_msg          =>   lc_log_msg);
                           END IF;                   
         END IF;       
        Exception -- Exception for begin 2
            WHEN OTHERS THEN
                x_return_msg := 'Unexpected Error in Querying Vendor for ' || p_header_rec.vendor_id;
                x_return_cd := 'N';
                          -- Audit Log  
                           IF lc_log_profile_value = 'Y' THEN
                              x_return_msg := 'EXCEPTION-2' || x_return_msg;     
                              Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_PKG'
                                              ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                              ,p_error_msg          =>   x_return_msg);
                            END IF; 
         End; -- End for Begin 2
-- *************************************************************************************************************
-- #############################################################################################################
-- *********** Lookinf for the count of Findings and Violations ************************************************
-- #############################################################################################################
        SELECT greatest(
               ( SELECT ln_find_count from dual )
              , ( SELECT ln_vio_count from dual )
         ) INTO ln_count from dual;
-- *******************************************************************************               
-- ***************Header Rec************************************* **********************************************
-- #############################################################################################################
              lc_message_invoke_for := p_header_rec.message_invoke_for;
              lc_vendor_id := p_header_rec.vendor_id;
              lc_vendor_name := p_header_rec.vendor_name;
              lc_msg_time := p_header_rec.msg_date_time;
--  ************Audit Rec****************************************
              lc_trans_status              := p_audit_rec.transmission_status;
              lc_client                    := p_audit_rec.client;
              lc_inspection_no             := p_audit_rec.inspection_no;
              lc_inspection_id             := p_audit_rec.inspection_id;
              lc_inspection_type           := p_audit_rec.inspection_type;
              lc_service_type              := p_audit_rec.service_type;
              lc_qa_profile                := p_audit_rec.qa_profile;
              lc_status                    := p_audit_rec.status;
              ld_complete_by_start_date    := p_audit_rec.complete_by_start_date;
              ld_complete_by_end_date      := p_audit_rec.complete_by_end_date;
              ld_audit_schduled_date       := p_audit_rec.audit_schduled_date;
              ld_inspection_date           := p_audit_rec.inspection_date;
              lc_inspection_time_in        := p_audit_rec.inspection_time_in;
              lc_inspection_time_out       := p_audit_rec.inspection_time_out;
              ld_inspection_schduled_date  := p_audit_rec.inspection_schduled_date;
              ld_initial_inspection_date   := p_audit_rec.initial_inspection_date ;
              lc_relationships             := p_audit_rec.relationships;
              ld_inspectors_schduled       := p_audit_rec.inspectors_schduled;
              lc_inspection_month          := p_audit_rec.inspection_month ;
              lc_inspection_year           := p_audit_rec.inspection_year;
-- Expecting One record only for this release 11.3
                  For j in 1..p_vendor_tbl.count Loop
                      lc_od_vendor_no := p_vendor_tbl(j).od_vendor_no;
                      lc_sc_vendor    := p_vendor_tbl(j).vendor; 
                      lc_entity_id    := p_vendor_tbl(j).entity_id;   
                      lc_od_factory_no := p_vendor_tbl(j).od_factory_no; 
                      lc_factory_name  := p_vendor_tbl(j).vendor_attribute1; 
                      lc_base_address  := p_vendor_tbl(j).base_address; 
                      lc_city          := p_vendor_tbl(j).city;  
                      lc_state         := p_vendor_tbl(j).state  ;
                      lc_country       := p_vendor_tbl(j).country  ;
                      lc_factory_status   := p_vendor_tbl(j).factory_status;      
--lc_factory_contacts := p_vendor_tbl(j).           
                      lc_invoice_no       := p_vendor_tbl(j).invoice_no;           
                      ld_invoice_date     := p_vendor_tbl(j).invoice_date;          
                      lc_invoice_amount   := p_vendor_tbl(j).invoice_amount ;         
                      lc_payment_method   := p_vendor_tbl(j).payment_method ;         
                      ld_payment_date     := p_vendor_tbl(j).payment_date;          
                      lc_payment_amount   := p_vendor_tbl(j).payment_amount;
                      lc_grade            := p_vendor_tbl(j).grade;         
                      lc_region           := p_vendor_tbl(j).region;          
                      lc_sub_region       := p_vendor_tbl(j).sub_region;
                      lc_ven_address_1 := p_vendor_tbl(j).vendor_address.address_1;
                      lc_ven_contact_name :=p_vendor_tbl(j).vendor_contact.contact_name;
                      lc_factory_contacts := p_vendor_tbl(j).factory_contacts.contact_name;
--lc_ven_contact_type := p_vendor_tbl(j).vendor_contact.contact_phone.contact_type;
--lc_ven_contact_no := p_vendor_tbl(j).vendor_contact.contact_phone.contact_no;
                End Loop;
                For  k in 1..p_auditor_tbl.count Loop
                      lc_od_sc_auditor_name := p_auditor_tbl(k).od_sc_auditor_name;
                      lc_od_sc_auditor_level := p_auditor_tbl(k).od_sc_auditor_level;
                      --lc_od_sc_auditor_name := lc_od_sc_auditor_name + p_auditor_tbl(k).od_sc_auditor_name + ',';
                      --lc_od_sc_auditor_level := lc_od_sc_auditor_level + p_auditor_tbl(k).od_sc_auditor_level + ',';
                End Loop;
-- *************************** Looping Findings and Violations Tbl type ***************************************
-- #############################################################################################################
--dbms_output.put_line('**********Finding Table*****************');
                For i IN 1..ln_count Loop  -- Loop for Insert     
                    --dbms_output.put_line('---------count ....' || i);
                    IF i <= p_findings_tbl.count then
                        --dbms_output.put_line('---------In Finding Loop count ....' || i);
                          lc_question_code     := p_findings_tbl(i).question_code;
                          lc_question          := p_findings_tbl(i).question;
                          lc_answer            := p_findings_tbl(i).answer; 
                          lc_section           := p_findings_tbl(i).section;
                          lc_sub_section       := p_findings_tbl(i).sub_section; 
                          lc_nayn              := p_findings_tbl(i).nayn;
                          lc_auditor_comments  := p_findings_tbl(i).auditor_comments;
                    END IF; 
                    IF i <= p_violation_tbl.count then
                          --dbms_output.put_line('---------In violation Loop count ....' || i);
                          lc_viol_code         := p_violation_tbl(i).viol_code;
                          lc_viol_question     := p_violation_tbl(i).viol_question;
                          lc_viol_text         := p_violation_tbl(i).viol_text;
                          lc_viol_flag         := p_violation_tbl(i).viol_flag ;
                          lc_viol_section      := p_violation_tbl(i).viol_section;
                          lc_viol_sub_section  := p_violation_tbl(i).viol_sub_section   ;
                          lc_viol_auditor_comments := p_violation_tbl(i).viol_auditor_comments;
                          --dbms_output.put_line('vio_question_code ....' || lc_viol_code);
                          --dbms_output.put_line('vio_question ....' || lc_find_question);
                          --dbms_output.put_line('vio_anser ....' || lc_find_answer);   
                    END IF;
 -- *************************** Inserting Data into IV **********************************************************    
 -- #############################################################################################################
                INSERT INTO apps.Q_OD_SC_VENDOR_AUDIT_IV
                          (  PROCESS_STATUS 
                            ,ORGANIZATION_CODE   
                            ,PLAN_NAME 
                            ,INSERT_TYPE 
                            ,MATCHING_ELEMENTS   
                            ,QA_CREATED_BY_NAME
                            ,QA_LAST_UPDATED_BY_NAME
                            ,OD_SC_TRANSMISSION_STATUS
                            ,OD_SC_CLIENT
                            ,OD_SC_INSPECTION_N0
                            ,OD_SC_INSPECTION_ID
                            ,OD_SC_INSPECTION_TYPE
                            ,OD_SC_SERVICE_TYPE
                            ,OD_SC_QAPROFILE
                            ,OD_SC_STATUS
                            ,OD_SC_COMPLETE_BY_START_DATE
                            ,OD_SC_COMPLETE_BY_END_DATE
                            ,OD_SC_SCHEDULED_DATE
                            ,OD_SC_INSPECT_DATE
                            ,OD_SC_TIME_IN
                            ,OD_SC_TIME_OUT
                            ,OD_SC_SCHEDULED_TIME
                            ,OD_SC_INIT_INSPECTION_DATE
                            ,OD_SC_RELATIONSHIPS
                            ,OD_SC_NO_INSPECTORS_SCHD
                            ,OD_SC_INSPECTION_MONTH
                            ,OD_SC_INSPECTION_YEAR
                            ,OD_SC_RUSH_AUDIT_YN
                            ,OD_SC_OD_VENDOR_ID
                            ,OD_SC_VENDOR
                            ,OD_SC_VENDOR_ADDRESS
                            ,OD_SC_VENDOR_CONTACTS
                            ,OD_SC_VENDOR_PHONES
                            ,OD_SC_ENTITY_ID
                            ,OD_SC_FACTORY_ID
                            ,OD_SC_FACTORY
                            ,OD_SC_FACTORY_ADDR
                            ,OD_SC_FACT_CITY
                            ,OD_SC_FACTORY_STATE
                            ,OD_SC_ORIGIN_COUNTRY
                            ,OD_SC_FACTORY_CONTACTS
                            ,OD_SC_FACT_PHONE
                            ,OD_SC_FACTORY_STATUS
                            ,OD_SC_VENDOR_INVOICE_NO
                            ,OD_SC_VENDOR_INVOICE_DATE
                            ,OD_SC_VENDOR_INVOICE_AMT
                            ,OD_SC_PAYMENT_METHOD
                            ,OD_SC_VEN_INVOICE_PAYMENT_DATE
                            ,OD_SC_VEN_INVOICE_PAYMENT_AMT
                            ,OD_SC_GRADE
                            ,OD_SC_REGION
                            ,OD_SC_REGION_SUB
                            ,OD_SC_AGENT
                            ,OD_SC_AUDITOR_NAME
                            ,OD_SC_AUDITOR_LEVEL
                            ,OD_SC_QUESTION_CODE
                            ,OD_SC_SECTION
                            ,OD_SC_SUB_SECTION
                            ,OD_SC_QUESTION
                            ,OD_SC_ANSWER
                            ,OD_SC_QUESTION_APPLICABLE
                            ,OD_SC_AUDITOR_COMMENTS
                            ,OD_SC_VIOLATION_CODE
                            ,OD_SC_VIOLAT
                            ,OD_SC_VIOLATION_TEXT
                            ,OD_SC_VIOLATION_SECTION
                            ,OD_SC_VIOLATION_SUB_SECTION
                            ,OD_SC_VIOLATION_QUESTION
                            ,OD_SC_AUDITOR_COMMENTS_VIOL
                            ,OD_SC_INSERT_IFACE_ID
                         )
                VALUES
                            (
                             '1'
                             ,lc_org_code
                            ,lc_plan_name
                            , lc_prcoess_status --1 for INSERT
                            ,lc_matching_elements
                            , '500904'
                            , '500904'
                            ,  lc_trans_status                
                            ,  lc_client                      
                            ,  lc_inspection_no               
                            ,  lc_inspection_id               
                            ,  lc_inspection_type             
                            ,  lc_service_type                
                            ,  lc_qa_profile                  
                            ,  lc_status                      
                            ,  ld_complete_by_start_date      
                            ,  ld_complete_by_end_date        
                            ,  ld_audit_schduled_date         
                            ,  ld_inspection_date             
                            ,  lc_inspection_time_in          
                            ,  lc_inspection_time_out         
                            ,  ld_inspection_schduled_date    
                            ,  ld_initial_inspection_date     
                            ,  lc_relationships               
                            ,  ld_inspectors_schduled         
                            ,  lc_inspection_month            
                            ,  lc_inspection_year 
                            ,   lc_rush_audit 
                            ,   lc_od_vendor_no
                            ,   lc_sc_vendor
                            ,   lc_ven_address_1   
                            ,   lc_ven_contact_name
                            ,   lc_ven_contact 
                            ,   lc_entity_id
                            ,   lc_od_factory_no
                            ,   lc_factory_name
                            ,   lc_base_address
                            ,   lc_city
                            ,   lc_state
                            ,   lc_country
                            ,   lc_factory_contacts
                            ,   lc_factory_phone
                            ,   lc_factory_status
                            ,   lc_invoice_no
                            ,   ld_invoice_date
                            ,   lc_invoice_amount
                            ,   lc_payment_method
                            ,   ld_payment_date
                            ,   lc_payment_amount
                            ,   lc_grade
                            ,   lc_region
                            ,   lc_sub_region
                            ,   lc_agent
                            ,   lc_od_sc_auditor_name
                            ,   lc_od_sc_auditor_level
                            ,   lc_question_code 
                            ,   lc_section
                            ,   lc_sub_section 
                            ,   lc_question
                            ,   lc_answer  
                            ,   lc_nayn 
                            ,   lc_auditor_comments
                            ,   lc_viol_code
                            ,   lc_viol_flag
                            ,   lc_viol_text 
                            ,   lc_viol_section
                            ,   lc_viol_sub_section
                            ,   lc_viol_question
                            ,   lc_viol_auditor_comments
                            ,   i
                          );
                          commit;
--                    
                    lc_question_code     := '';
                    lc_question          := '';
                    lc_answer            := ''; 
                    lc_section           := '';
                    lc_sub_section       := ''; 
                    lc_nayn              := '';
                    lc_auditor_comments  := '';
                    lc_viol_code         := '';
                    lc_viol_question     := '';
                    lc_viol_text         := '';
                    lc_viol_flag         := '' ;
                    lc_viol_section      := '';
                    lc_viol_sub_section  := ''   ;
                    lc_viol_auditor_comments := '';
                    ln_rec_count := ln_rec_count + 1;
         
               End Loop; --  End Loop for Insert 
--- *****************************END INSERT *******************************************************    
-- #############################################################################################################         
                        -- Audit Log
                            IF lc_log_profile_value = 'Y' THEN
                                select to_char(sysdate,'DD-MM-YYYY HH24:MI:SS') into lc_sysdate from dual;
                                lc_log_msg := 'STEP-4 Inserted Record count is: ' || ln_rec_count ||' With mode '|| lc_prcoess_status || ' at ' || lc_sysdate || ' Process Status is: ' || lc_prcoess_status;
                                Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_PKG'
                                                 ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                  ,p_error_msg          =>   lc_log_msg);
                            END IF; 
-- *************************** Process continues If the Transmission Status is Final Call Import prgogram ************
-- ###################################################################################################################
--************************************************************************************************************

     IF lc_prcoess_status = 2 THEN
                          -- Audit Log
                             IF lc_log_profile_value = 'Y' THEN
                                  select to_char(sysdate,'DD-MM-YYYY HH24:MI:SS') into lc_sysdate from dual;
                                  lc_log_msg := 'STEP-5 Veifying the Draft Data ' || ' at ' || lc_sysdate;
                                  Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_PKG'
                                                ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                ,p_error_msg          =>   lc_log_msg);
                             END IF; 
        BEGIN -- Begin 3
 -- **************** Before calling Import Match the data with approved Draft version****************************
 -- #############################################################################################################
                      SELECT
                            OD_SC_OD_VENDOR_ID
                            ,OD_SC_REGION 
                            ,OD_SC_REGION_SUB
                            ,OD_SC_SERVICE_TYPE
                            ,OD_SC_FACTORY_ID
                            ,OD_SC_AGENT
                            ,OD_SC_GRADE
                            ,OD_SC_INSPECT_DATE 
                      INTO
                            lc_dft_vendor_id
                            ,lc_dft_region
                            ,lc_dft_region_sub
                            ,lc_dft_service_type
                            ,lc_dft_factory_id
                            ,lc_dft_agent
                            ,lc_dft_grade
                            ,ld_dft_inspect_date 
                      FROM
                            APPS.Q_OD_SC_VENDOR_AUDIT_V auditRes
                      WHERE TRIM(auditRes.OD_SC_INSPECTION_N0) = TRIM(lc_inspection_no)
                      AND UPPER(TRIM(auditRes.PLAN_NAME)) = UPPER(TRIM(lc_plan_name))  
                      AND rownum < 2; 
                            IF lc_match_flag = 'Y' THEN
                                              -- Audit Log      
                                                IF lc_log_profile_value = 'Y' THEN
                                                    select to_char(sysdate,'DD-MM-YYYY HH24:MI:SS') into lc_sysdate from dual;
                                                    lc_log_msg := 'STEP-6 Matching the draft data at ' || lc_sysdate;
                                                    Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_PKG'
                                                                    ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                                    ,p_error_msg          =>   lc_log_msg);
                                                 END IF;      
 -- **************************** Comparing the Draft values With Fial***********************************
-- #############################################################################################################
-- #############################################################################################################
-- Verification of Approved Draft 'Vendor ID' with Final data
-- #############################################################################################################
                                  If TRIM(lc_dft_vendor_id) != TRIM(lc_od_vendor_no) Then          
                                          lc_match_flag := 'N';
                                          lc_match_msg := lc_match_msg || ' Vendor ID ' || lc_dft_vendor_id || ' and ' || lc_od_vendor_no;
                                                -- Audit Log  
                                                  IF lc_log_profile_value = 'Y' THEN
                                                        lc_log_msg := 'STEP-7 Data Matched? ' || lc_match_flag ;
                                                        Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_BPEL_PKG'
                                                                         ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                                         ,p_error_msg          =>   lc_match_msg);
                                                    END IF;
             
             
                                  End if;      
-- #############################################################################################################                                  
-- Verification of Approved Draft 'Region' with Final data        
-- #############################################################################################################
                                  If UPPER(TRIM(lc_dft_region)) != UPPER(TRIM(lc_region)) Then 
                                          lc_match_flag := 'N';
                                           lc_match_msg := lc_match_msg || ' Region ' || lc_dft_region || ' and ' || lc_region;
                                                  -- Audit Log
                                                       IF lc_log_profile_value = 'Y' THEN
                                                            
                                                            Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_BPEL_PKG'
                                                                          ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                                          ,p_error_msg          =>   lc_match_msg);
                                                        END IF;
           
                      
                                  End if;
-- #############################################################################################################                                  
-- Verification of Approved Draft 'Region Sub' with Final data                                  
-- #############################################################################################################                                  
                                  If NVL(UPPER(TRIM(lc_dft_region_sub)),'NA') != NVL(UPPER(TRIM(lc_sub_region)),'NA') Then 
                                            lc_match_flag := 'N';
                                            lc_match_msg := lc_match_msg || ' Sub Region ' ||  lc_dft_region_sub || ' and ' || lc_sub_region;
                                                      -- Audit Log        
                                                          IF lc_log_profile_value = 'Y' THEN
                                                               Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_BPEL_PKG'
                                                                            ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                                            ,p_error_msg          =>   lc_match_msg);
                                                           END IF;
                                   End if;
 -- #############################################################################################################                                  
-- Verification of Approved Draft 'Service Type' with Final data   
-- #############################################################################################################
                                      If NVL(UPPER(TRIM(lc_dft_service_type)),'NA') != NVL(UPPER(TRIM(lc_service_type)),'NA') Then 
                                     --If TRIM(lc_dft_service_type) != TRIM(lc_service_type) Then 
                                        lc_match_flag := 'N';
                                        lc_match_msg := lc_match_msg || ' Service Type ' ||  lc_dft_service_type || ' ' || lc_service_type;    
                                                          -- Audit Log  
                                                             IF lc_log_profile_value = 'Y' THEN
                                                                 -- lc_log_msg := 'STEP-7 Data Matched? ' || lc_match_flag ;
                                                                  Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_BPEL_PKG'
                                                                                  ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                                                  ,p_error_msg          =>   lc_match_msg);
                                                              END IF;
                    
                                       End if;
-- #############################################################################################################                                  
 -- Verification of Approved Draft 'Factory ID' with Final data  
-- ############################################################################################################# 
                                  If NVL(UPPER(TRIM(lc_dft_factory_id)),'NA') != NVL(UPPER(TRIM(lc_od_factory_no)),'NA') Then 
                                          lc_match_flag := 'N';
                                          lc_match_msg := lc_match_msg || ' Factory Id ' ||  lc_dft_factory_id || ' and ' || lc_od_factory_no; 
                                                          -- Audit Log    
                                                             IF lc_log_profile_value = 'Y' THEN
                                                                
                                                                Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_BPEL_PKG'
                                                                                ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                                                ,p_error_msg          =>   lc_match_msg);
                                                              END IF;
                                   End if;
-- #############################################################################################################                                   
  -- Verification of Approved Draft 'AGENT' with Final data                                    
-- #############################################################################################################                                   
                                  If NVL(UPPER(TRIM(lc_dft_agent)),'NA') != NVL(UPPER(TRIM(lc_agent)),'NA') Then 
                                        lc_match_flag := 'N';
                                        lc_match_msg := lc_match_msg || ' Agent ' ||  lc_dft_agent || ' and ' || lc_agent; 
                                                       -- Audit Log 
                                                           IF lc_log_profile_value = 'Y' THEN
                                                                  
                                                                  Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_BPEL_PKG'
                                                                                  ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                                                  ,p_error_msg          =>   lc_match_msg);
                                                             END IF;
                                    End if;    
        
-- #############################################################################################################
 -- Verification of Approved Draft 'GRADE' with Final data          
-- #############################################################################################################
                                    If NVL(UPPER(TRIM(lc_dft_grade)),'NA') != NVL(UPPER(TRIM(lc_grade)),'NA') Then 
                                            lc_match_flag := 'N';
                                            lc_match_msg := lc_match_msg || ' Grade ' ||  lc_dft_grade || ' and ' || lc_grade; 
                                                            -- Audit Log    
                                                              IF lc_log_profile_value = 'Y' THEN
                                                    
                                                                  Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_BPEL_PKG'
                                                                                ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                                                ,p_error_msg          =>   lc_match_msg);
                                                               END IF;
                                     End if;      
-- #############################################################################################################                                     
-- Verification of Approved Draft 'INSPECT DATE' with Final data                                      
 -- #############################################################################################################
                                     
                                     If TRUNC(ld_dft_inspect_date) != TRUNC(ld_inspection_date) Then 
                                              lc_match_flag := 'N';
                                              lc_match_msg := lc_match_msg || ' Inspection Date ' || ld_dft_inspect_date || ' and ' || ld_inspection_date;                
                                                               IF lc_log_profile_value = 'Y' THEN
                                                     
                                                                    Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_BPEL_PKG'
                                                                                    ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                                                    ,p_error_msg          =>   lc_match_msg);
                                                                END IF;
                                      End if;         
-- *********************************** End Comparison **********************************************************
-- #############################################################################################################
                                                                      -- Audit Log
                                                                                  IF lc_log_profile_value = 'Y' THEN
                                                                                      lc_log_msg := 'STEP-7 Data Matched? ' || lc_match_flag ;
                                                                                      Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_BPEL_PKG'
                                                                                                      ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                                                                      ,p_error_msg          =>   lc_log_msg);
                                                                                  END IF;
          END IF;  -- End of If process status   
                BEGIN  -- Begin 4
                
-- #############################################################################################################                
-- ********** If the Final Data matches with Draft data SUBMIT IMPORT PROGRAM *********************************       
-- #############################################################################################################

                         IF lc_match_flag = 'Y' THEN
                              --lc_match_flag := 'N';
                                  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('QA','QLTTRAMB','Collection Import Manager',NULL,FALSE,
                                                                         	'200','2',TO_CHAR(V_user_id),'Yes');
                                                  -- Audit Log
                                                            IF lc_log_profile_value = 'Y' THEN
                                                                  select to_char(sysdate,'DD-MM-YYYY HH24:MI:SS') into lc_sysdate from dual;
                                                                  lc_log_msg := 'STEP-9 Submitted Import Program at: ' || lc_sysdate ;
                                                                  Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_BPEL_PKG'
                                                                                      ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                                                  ,p_error_msg          =>   lc_log_msg);
                                                            END IF;
-- ********** Verfify Status of Import program ************************************************************        
-- #########################################################################################################
                                           IF v_request_id>0 THEN  -- Import Program Successul        
                                                 COMMIT;       
                                                              -- Audit Log          
                                                                    IF lc_log_profile_value = 'Y' THEN
                                                                       select to_char(sysdate,'DD-MM-YYYY HH24:MI:SS') into lc_sysdate from dual;
                                                                       lc_log_msg := 'STEP-10 Import Program completed Successfully at: ' || lc_sysdate ;
                                                                       Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_BPEL_PKG'
                                                                                          ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                                                          ,p_error_msg          =>   lc_log_msg);
                                                                         END IF;
                         
          -- ********** Uodated vendor master ***********************************************************************  
          -- #########################################################################################################                         
          
                                                BEGIN -- Begin 5
                                                         -- Audit Log          
                                                                          IF lc_log_profile_value = 'Y' THEN
                                                                              select to_char(sysdate,'DD-MM-YYYY HH24:MI:SS') into lc_sysdate from dual;
                                                                                 lc_log_msg := 'STEP-11 Update Vendor Master for Vendor Number : '|| lc_od_vendor_no ||' and Factory No: ' || lc_od_factory_no || 'wtih status: '|| lc_status || 'at ' ||lc_sysdate ;
                           
                                                                                Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_BPEL_PKG'
                                                                                                  ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                                                                 ,p_error_msg          =>   lc_log_msg);
                                                                            END IF;
         
          
                                                    Select count(*) into ln_update_rec_count from Q_OD_PB_SC_VENDOR_MASTER_V
                                                    where OD_SC_VENDOR_NUMBER = lc_od_vendor_no
                                                    and OD_SC_FACTORY_NUMBER = lc_od_factory_no;
          
                                                    If ln_update_rec_count > 0 then
                                                          UPDATE Q_OD_PB_SC_VENDOR_MASTER_V
                                                          SET 
                                                          OD_SC_VENDOR_STATUS = lc_status
                                                          WHERE OD_SC_VENDOR_NUMBER = lc_od_vendor_no
                                                          AND OD_SC_FACTORY_NUMBER = lc_od_factory_no;             
                                                          COMMIT;
                  
          
                                                                          -- Audit Log          
                                                                            IF lc_log_profile_value = 'Y' THEN
                                                                                select to_char(sysdate,'DD-MM-YYYY HH24:MI:SS') into lc_sysdate from dual;
                                                                                lc_log_msg := 'STEP-12 Updated Vendor Master at ' ||lc_sysdate ;
                               
                                                                                 Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_BPEL_PKG'
                                                                                              ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                                                              ,p_error_msg          =>   lc_log_msg);
                                                                              END IF;
                         
                         
                                                    Else
                                                        x_return_cd := 'N';
                                                         x_return_msg := 'Vendor Not found in Vendor Master for Update';
                                    
                                                                           -- Audit Log          
                                                                                IF lc_log_profile_value = 'Y' THEN
                                                                                       lc_log_msg := 'STEP-13 Vendo Not found in Vendor Master for Update';
                           
                                                                                      Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_BPEL_PKG'
                                                                                                      ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                                                                      ,p_error_msg          =>   lc_log_msg);
                                                                              END IF;
                    
                                                    End if;             
                                                   EXCEPTION  -- Exception for Begin 5
                                                      WHEN OTHERS THEN
                                                          x_return_cd := 'N';
                                                          x_return_msg := 'Unexpected Error occured while updating vendor master';
                                                                            -- Audit Log 
                                                                                IF lc_log_profile_value = 'Y' THEN
                                                                                  lc_log_msg := 'EXCEPTION-4 '|| x_return_msg ;
                                                                                  Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_BPEL_PKG'
                                                                                                  ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                                                                  ,p_error_msg          =>   lc_log_msg);
                                                                                END IF;
                      
          
                                                    END; -- End of Begin 5
                                            ELSE -- Import program not successful
                                                                            -- Audit Log
                                                                                     IF lc_log_profile_value = 'Y' THEN
                                                                                      select to_char(sysdate,'DD-MM-YYYY HH24:MI:SS') into lc_sysdate from dual;
                                                                                      lc_log_msg := 'STEP-10 Import Program Fialed at: ' || lc_sysdate ;
                                                                                      Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_BPEL_PKG'
                                                                                                          ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                                                                          ,p_error_msg          =>   lc_log_msg);
                                            END IF;
                                    END IF;   
-- ***********************************End Status of Import Progrm*******************************************    
-- #############################################################################################################
                           ELSE
                                             -- Audit Log 
                                                 IF lc_log_profile_value = 'Y' THEN
                                                         lc_log_msg := 'STEP-8 Draft data Match Flag is: ' || lc_match_flag ;
                                                           Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_BPEL_PKG'
                                                                           ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                                            ,p_error_msg          =>   lc_log_msg);
                                                  END IF;
-- ***********************************************************************************************************    
                          END IF;
                EXCEPTION -- Exception for begin 4
                      WHEN OTHERS THEN
                            x_return_cd := 'Y';
                            x_return_msg := 'Error in Executing Concurrent Program';
                                        -- Audit Log 
                                                IF lc_log_profile_value = 'Y' THEN
                                                  lc_log_msg := 'EXCEPTION-4 '|| x_return_msg ;
                                                  Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_BPEL_PKG'
                                                                  ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                                  ,p_error_msg          =>   lc_log_msg);
                                                 END IF;
                 END; -- End for Begin 4
          EXCEPTION -- Exception for Begin 3
                     WHEN NO_DATA_FOUND THEN
                          x_return_cd := 'Y';
                         x_return_msg := 'Received Final Audit report no draft record found';
                                        -- Audit Log 
                                          IF lc_log_profile_value = 'Y' THEN
                                                lc_log_msg := 'EXCEPTION-3 '|| x_return_msg ;
                                                Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_BPEL_PKG'
                                                                ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                                  ,p_error_msg          =>   lc_log_msg);
                                           END IF;
                     WHEN OTHERS THEN
                        x_return_cd := 'N';
                        x_return_msg := 'Unexpected Error occured while matching the data with Draft' || SQLERRM;
                                          -- Audit Log 
                                          IF lc_log_profile_value = 'Y' THEN
                                              lc_log_msg := 'EXCEPTION-3 '|| x_return_msg ;
                                              Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_BPEL_PKG'
                                                              ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                                              ,p_error_msg          =>   lc_log_msg);
                                          END IF;
          END; -- End for Begin 3
       x_return_cd := lc_match_flag;
      x_return_msg := lc_match_msg;
   END IF;  -- End if for Process status is 2
 
 
   x_lc_return_cd := 'Y';
   x_lc_return_cd := 'success';
--dbms_output.put_line('Return Code....' ||  x_return_cd);
EXCEPTION -- Exception for Begin 1
  WHEN OTHERS THEN
  x_lc_return_cd := 'N';
  x_lc_return_msg := 'Unexpected Error in Executing the Audit Result Pacakge' || lc_od_sc_auditor_name || sqlerrm;
                    -- Audit Log 
                     IF lc_log_profile_value = 'Y' THEN
                        lc_log_msg := 'EXCEPTION-1 '|| x_return_msg ;
                        Log_Exception ( p_error_location     =>  'XX_QA_SC_VEN_AUDIT_BPEL_PKG'
                                        ,p_error_message_code =>  'XX_QA_LOG_MSG'
                                        ,p_error_msg          =>   lc_log_msg);
                      END IF;
END   VENDOR_AUDIT_RESULT_PUB;  -- End for begin 1                     
END XX_QA_SC_VEN_ADT_RESULT_PKG;
/
SHOW ERRORS;

--EXIT

