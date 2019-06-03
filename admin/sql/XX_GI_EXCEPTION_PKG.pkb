SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
 
CREATE OR REPLACE PACKAGE BODY XX_GI_EXCEPTION_PKG
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                  WIPRO Organization                                            |
-- +================================================================================+
-- | Name        :  XX_GI_EXCEPTION_PKG                                             |
-- | Rice Id     :  E0346c_Mis-Ship and Add SKU Error Handling                      |
-- | Description :  This script creates custom package body required for            |
-- |                Mis-Ship and Add SKU Error Handling                             |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author           Remarks                                  |
-- |=======   ==========  =============    ============================             |
-- |1.0      28-MAY-2007  Rahul Bagul      Initial draft version                    |
-- |                                                                                |
-- +================================================================================+
AS
-- +==================================================================================+
-- | Name        :  INSERT_PO_LINE_PROC                                               |
-- | Description :  This procedure is submitting  concurrent program ‘Import Standard |
-- |                Purchase Order’ to add new PO line on existing PO                 |
-- | Parameters   : p_po_number,p_po_header_id,p_org_id,p_item_number,p_line_type,    |
-- |                p_new_quantity,p_unit_price,p_promised_date,                      |
-- |                p_interface_transaction_id,p_inventory_item_id                    |
-- +==================================================================================+
PROCEDURE INSERT_PO_LINE_PROC(
                               p_po_number                IN VARCHAR2
                              ,p_po_header_id             IN NUMBER
                              ,p_org_id                   IN NUMBER
                              ,p_item_number              IN VARCHAR2
                              ,p_line_type                IN VARCHAR2
                              ,p_new_quantity             IN NUMBER
                              ,p_unit_price               IN NUMBER
                              ,p_promised_date            IN DATE
                              ,p_interface_transaction_id IN NUMBER
                              ,p_inventory_item_id        IN NUMBER
                              ,p_batch_id                 IN NUMBER 
                              )
AS
-- Declare local variables
 lc_vendor_name         po_vendors.vendor_name%TYPE;
 lc_vendor_site_code    po_vendor_sites.vendor_site_code%TYPE;
 lc_ship_to_location    hr_locations_all.location_code%TYPE;
 lc_bill_to_location    hr_locations_all.location_code%TYPE;
 lc_currency_code       po_headers_all.currency_code%TYPE; 
 ln_agent_id            po_headers_all.agent_id%TYPE;
 ln_ship_to_location_id po_headers_all.ship_to_location_id%TYPE;
 lc_ship_to_org_code    org_organization_definitions.organization_code%TYPE;
 ln_operating_unit      org_organization_definitions.operating_unit%TYPE;
 lc_uom_code            mtl_system_items.primary_uom_code%TYPE;
 ln_charge_account_id   mtl_parameters.material_account%TYPE;
 ln_line_num            NUMBER  :=0;
 ln_insert_line_req_id  NUMBER  :=0;
 lc_approval_status     VARCHAR2(30);
 ln_change_po_price     NUMBER ;
 ln_profile_value       NUMBER :=1000;-- remove hardcoded value when profile option will set
 ln_application_id      NUMBER;
 ln_quantity            NUMBER;
 lc_retcode             VARCHAR2(100);
 lc_errbuff             VARCHAR2(2000);
 lc_sqlcode             VARCHAR2(100);
 lc_sqlerrm             VARCHAR2(2000);
 ln_ou_id               NUMBER;
 lb_req_status          BOOLEAN;
 lc_status_create       VARCHAR2(50);
 lc_phase_insert        VARCHAR2(50);
 lc_status_insert       VARCHAR2(50);
 lc_devphase_insert     VARCHAR2(50);
 lc_devstatus_insert    VARCHAR2(50);
 lc_message_insert      VARCHAR2(50);
 --Cursor for error_message from table po_interface_errors
                CURSOR lcu_interface_error_curr (p_batch_id NUMBER)
                IS
                SELECT POIE.error_message
                     , POHI.document_num
                     , POHI.batch_id
                     , POLI.line_num
                     , POLI.item
                     , POIE.interface_line_id
                FROM  po_headers_interface POHI
                    , po_lines_interface POLI
                    , po_interface_errors POIE
                WHERE POHI.batch_id=p_batch_id
                AND   POHI.process_code NOT IN ('ACCEPTED')
                AND   POLI.interface_header_id = POHI.interface_header_id
                AND   POIE.interface_header_id = POHI.interface_header_id;

BEGIN
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Inside begin OF insert_po_line_proc');
   FND_CLIENT_INFO.SET_ORG_CONTEXT(FND_PROFILE.VALUE('org_id'));
          
         
   BEGIN
         
        SELECT PHA.currency_code
             , PHA.agent_id
             , LTRIM (RTRIM(PV.vendor_name)) 
             , PVS.vendor_site_code
             , PHA.ship_to_location_id
             , PHA.org_id
        INTO   lc_currency_code
             , ln_agent_id
             , lc_vendor_name
             , lc_vendor_site_code
             , ln_ship_to_location_id
             , ln_ou_id
        FROM   po_headers_all           PHA
             , po_vendors                 PV
             , po_vendor_sites_all  PVS
       WHERE   PHA.SEGMENT1=p_po_number
       AND     PHA.type_lookup_code      = 'STANDARD'
       AND     PV.VENDOR_ID              = PHA.VENDOR_ID 
       AND     PVS.VENDOR_ID             = PV.VENDOR_ID
       AND     PVS.vendor_site_id        =PHA.vendor_site_id
       AND     PVS.bill_to_location_id   = PHA.bill_to_location_id
       AND     PVS.ship_to_location_id   = PHA.ship_to_location_id;
     
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
     lc_retcode :=SQLCODE;
     lc_errbuff :=SUBSTR(SQLERRM,1,250);
     FND_FILE.PUT_LINE(FND_FILE.LOG, lc_retcode || lc_errbuff);
   WHEN TOO_MANY_ROWS THEN
     lc_retcode :=SQLCODE;
     lc_errbuff :=SUBSTR(SQLERRM,1,250);
     FND_FILE.PUT_LINE(FND_FILE.LOG, lc_retcode || lc_errbuff);
   WHEN OTHERS THEN
     lc_retcode := SQLCODE;
     lc_errbuff := SUBSTR(SQLERRM,1,250);
     FND_FILE.PUT_LINE(FND_FILE.LOG, lc_retcode || lc_errbuff);
   END;
   BEGIN
      SELECT MAX(line_num)+1
      INTO   ln_line_num
      FROM   po_lines_all
      WHERE  po_header_id=p_po_header_id;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
      lc_retcode :=SQLCODE;
      lc_errbuff :=SUBSTR(SQLERRM,1,250);
      FND_FILE.PUT_LINE(FND_FILE.LOG, lc_retcode || lc_errbuff);
   WHEN TOO_MANY_ROWS THEN
      lc_retcode :=SQLCODE;
      lc_errbuff :=SUBSTR(SQLERRM,1,250);
      FND_FILE.PUT_LINE(FND_FILE.LOG, lc_retcode || lc_errbuff);
   WHEN OTHERS THEN
     lc_retcode := SQLCODE;
     lc_errbuff := SUBSTR(SQLERRM,1,250);
     FND_FILE.PUT_LINE(FND_FILE.LOG, lc_retcode || lc_errbuff);

   END;
           
   BEGIN
      SELECT  primary_uom_code 
      INTO    lc_uom_code
      FROM    mtl_system_items_b 
      WHERE   segment1        = p_item_number
      AND     organization_id = p_org_id;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
      lc_retcode :=SQLCODE;
      lc_errbuff :=SUBSTR(SQLERRM,1,250);
      FND_FILE.PUT_LINE(FND_FILE.LOG, lc_retcode || lc_errbuff);
   WHEN TOO_MANY_ROWS THEN
      lc_retcode :=SQLCODE;
      lc_errbuff :=SUBSTR(SQLERRM,1,250);
      FND_FILE.PUT_LINE(FND_FILE.LOG, lc_retcode || lc_errbuff);
   WHEN OTHERS THEN
     lc_retcode := SQLCODE;
     lc_errbuff := SUBSTR(SQLERRM,1,250);
     FND_FILE.PUT_LINE(FND_FILE.LOG, lc_retcode || lc_errbuff);
   END;
           
   BEGIN
      SELECT   OOD.organization_code
               ,OOD.operating_unit
      INTO     lc_ship_to_org_code
               ,ln_operating_unit
      FROM     org_organization_definitions OOD
               ,hr_locations_all HRLA
      WHERE    HRLA.ship_to_location_id=ln_ship_to_location_id
      AND      OOD.organization_id(+)=HRLA.inventory_organization_id;
      EXCEPTION
   WHEN NO_DATA_FOUND THEN
      lc_retcode :=SQLCODE;
      lc_errbuff :=SUBSTR(SQLERRM,1,250);
      FND_FILE.PUT_LINE(FND_FILE.LOG,lc_retcode||lc_errbuff);
   WHEN TOO_MANY_ROWS THEN
      lc_retcode :=SQLCODE;
      lc_errbuff :=SUBSTR(SQLERRM,1,250);
      FND_FILE.PUT_LINE(FND_FILE.LOG, lc_retcode || lc_errbuff);
   WHEN OTHERS THEN
     lc_retcode := SQLCODE;
     lc_errbuff := SUBSTR(SQLERRM,1,250);
     FND_FILE.PUT_LINE(FND_FILE.LOG, lc_retcode || lc_errbuff);

   END;
          
   BEGIN
      SELECT material_account
      INTO   ln_charge_account_id
      FROM   mtl_parameters
      WHERE organization_id =p_org_id;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
      lc_retcode :=SQLCODE;
      lc_errbuff :=SUBSTR(SQLERRM,1,250);
      FND_FILE.PUT_LINE(FND_FILE.LOG, lc_retcode || lc_errbuff);
   WHEN TOO_MANY_ROWS THEN
      lc_retcode :=SQLCODE;
      lc_errbuff :=SUBSTR(SQLERRM,1,250);
      FND_FILE.PUT_LINE(FND_FILE.LOG, lc_retcode || lc_errbuff);
   WHEN OTHERS THEN
     lc_retcode := SQLCODE;
     lc_errbuff := SUBSTR(SQLERRM,1,250);
     FND_FILE.PUT_LINE(FND_FILE.LOG, lc_retcode || lc_errbuff);
   END;
   INSERT
   INTO po_headers_interface(interface_header_id
                             ,batch_id
                             ,action
                             ,org_id
                             ,document_type_code
                             ,document_num
                             ,currency_code
                             ,agent_id
                             ,vendor_name
                             ,vendor_site_code
                             ,ship_to_location
                             ,interface_source_code
                             ,approval_status
                             ,approved_date
                             ,creation_date 
                             ,created_by 
                             ,last_update_date 
                             ,last_updated_by
                             ,last_update_login)
                             VALUES
                            (
                             po_headers_interface_s.NEXTVAL
                             ,p_batch_id 
                             ,'UPDATE'
                             ,ln_ou_id
                             ,'STANDARD'
                             ,p_po_number
                             ,lc_currency_code
                             ,ln_agent_id
                             ,lc_vendor_name
                             ,lc_vendor_site_code
                             ,lc_ship_to_location
                             ,'GI'
                             ,'APPROVED'
                             ,SYSDATE
                             ,SYSDATE
                             ,FND_GLOBAL.USER_ID
                             ,SYSDATE
                             ,FND_GLOBAL.USER_ID
                             ,FND_GLOBAL.LOGIN_ID
                            );
              
   INSERT 
   INTO po_lines_interface(interface_line_id
                           ,interface_header_id
                           ,line_num
                           ,shipment_num
                           ,line_type
                           ,item
                           ,uom_code
                           ,quantity
                           ,unit_price
                           ,promised_date
                           ,ship_to_organization_code
                           ,ship_to_location
                           ,action
                           ,creation_date 
                           ,created_by 
                           ,last_update_date 
                           ,last_updated_by
                           ,last_update_login
                           )
                           VALUES
                           (
                            po_lines_interface_s.NEXTVAL
                            ,po_headers_interface_s.CURRVAL
                            ,ln_line_num
                            ,1
                            ,p_line_type
                            ,p_item_number
                            ,lc_uom_code
                            ,p_new_quantity
                            ,p_unit_price
                            ,p_promised_date
                            ,lc_ship_to_org_code
                            ,lc_ship_to_location
                            ,'ADD'
                            ,SYSDATE
                            ,FND_GLOBAL.USER_ID
                            ,SYSDATE
                            ,FND_GLOBAL.USER_ID
                            ,FND_GLOBAL.LOGIN_ID
                            );
         
   INSERT 
   INTO po_distributions_interface(interface_header_id
                                   ,interface_line_id
                                   ,interface_distribution_id
                                   ,distribution_num
                                   ,quantity_ordered
                                   ,charge_account_id
                                   ,creation_date 
                                   ,created_by 
                                   ,last_update_date 
                                   ,last_updated_by
                                   ,last_update_login
                                   )
                                   VALUES
                                  (
                                   po_headers_interface_s.CURRVAL
                                   ,po_lines_interface_s.CURRVAL
                                   ,po_distributions_interface_s.NEXTVAL
                                   ,1
                                   ,p_new_quantity
                                   ,ln_charge_account_id
                                   ,SYSDATE
                                   ,FND_GLOBAL.USER_ID
                                   ,SYSDATE
                                   ,FND_GLOBAL.USER_ID
                                   ,FND_GLOBAL.LOGIN_ID
                                  );
   COMMIT;
    ln_insert_line_req_id:=FND_REQUEST.SUBMIT_REQUEST(
                                                      APPLICATION  => 'PO'
                                                     ,PROGRAM      => 'POXPOPDOI'
                                                     ,DESCRIPTION  => NULL
                                                     ,START_TIME   => NULL
                                                     ,SUB_REQUEST  => NULL
                                                     ,ARGUMENT1    => NULL
                                                     ,ARGUMENT2    => 'STANDARD'
                                                     ,ARGUMENT3    => NULL
                                                     ,ARGUMENT4    => 'N'
                                                     ,ARGUMENT5    => NULL
                                                     ,ARGUMENT6    => lc_approval_status
                                                     ,ARGUMENT7    => NULL
                                                     ,ARGUMENT8    => p_batch_id
                                                     ,ARGUMENT9    => NULL
                                                     ,ARGUMENT10   => NULL
                                                     );
                                                     COMMIT;
                   IF (ln_insert_line_req_id =0) THEN
                       FND_FILE.PUT_LINE (FND_FILE.LOG,'Conc Prog Failed');
                   ELSE
                       FND_FILE.PUT_LINE (FND_FILE.LOG ,'Conc Prog Success'|| ln_insert_line_req_id);
                   END IF;

     lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST(
                                                      ln_insert_line_req_id
                                                     ,'15'
                                                     ,''
                                                     ,lc_phase_insert
                                                     ,lc_status_insert
                                                     ,lc_devphase_insert
                                                     ,lc_devstatus_insert
                                                     ,lc_message_insert
                                                     );
--Checking the status of the 'Import Items' program
                   IF (lc_status_insert = 'Warning')   OR (lc_status_insert = 'Error') THEN 
                        FOR lcu_interface_error_curr_rec
                        IN  lcu_interface_error_curr (p_batch_id)
                        LOOP
                        EXIT WHEN lcu_interface_error_curr%NOTFOUND;
                           gc_error_message      := lcu_interface_error_curr_rec.error_message||'For PO NUMBER= '||p_po_number||'For Item'||p_item_number;
                           gc_error_message_code :='';
                           gc_object_id          := p_interface_transaction_id;
                           gc_object_type        :='Interface_transaction_id';
                           XX_COM_ERROR_LOG_PUB.LOG_ERROR( NULL
                                                          ,NULL
                                                          ,'EBS'
                                                          ,'Procedure'
                                                          ,'INSERT PO LINE'
                                                          ,NULL
                                                          ,'GI'
                                                          ,gn_sqlpoint
                                                          ,NULL
                                                          ,gc_error_message_code
                                                          ,gc_error_message
                                                          ,'FATAL'
                                                          ,'LOG_ONLY'
                                                          ,NULL
                                                          ,NULL
                                                          ,gc_object_type 
                                                          ,gc_object_id 
                                                          ,NULL
                                                          ,NULL
                                                          ,NULL
                                                          ,NULL
                                                          ,NULL
                                                          ,NULL
                                                          ,NULL
                                                          ,NULL
                                                          ,NULL
                                                          ,NULL
                                                          ,NULL
                                                          ,NULL
                                                          ,NULL
                                                          ,NULL
                                                          ,NULL
                                                          ,NULL
                                                          ,NULL
                                                          ,NULL
                                                          ,NULL
                                                          ,NULL
                                                          , SYSDATE
                                                          , FND_GLOBAL.USER_ID
                                                          , SYSDATE
                                                          , FND_GLOBAL.USER_ID
                                                          , FND_GLOBAL.LOGIN_ID
                                                          );
                        END LOOP;
                   END IF;

END INSERT_PO_LINE_PROC;
 -- +==================================================================================+
 -- | Name        :  NOTIFY_PROC                                                       |
 -- | Description :  This procedure is submitting  concurrent program ‘OD:Concurrent   |
 -- |                Request output emailer program’ to send email notification to     |
 -- |                RMS group                                                         |
 -- | Parameters  :  p_request_id,p_item_type,p_interface_transaction_id               |
 -- |                ,p_email_address,x_errbuff,x_retcode                              |
 -- +==================================================================================+ 
PROCEDURE NOTIFY_PROC (
                        p_request_id                  IN   NUMBER
                        ,p_item_type                  IN   VARCHAR2
                        ,p_interface_transaction_id   IN   NUMBER
                        ,p_email_address              IN   VARCHAR2
                        ,x_errbuff                    OUT  VARCHAR2
                        ,x_retcode                    OUT  VARCHAR2
                        )
AS
--declaration of local variable
p_program_name    VARCHAR2(25) :='emailer notification';
p_mail_subject    VARCHAR2(50) :='testing email notification'; 
p_mail_body       VARCHAR2(50) := NULL;
p_attachment      VARCHAR2(50) := 'N';
ln_request_id     NUMBER       := 0;
lc_retcode        VARCHAR2(100);
lc_errbuff        VARCHAR2(2000);
      
BEGIN
    IF p_item_type='T' THEN
       ln_request_id := FND_REQUEST.SUBMIT_REQUEST
                        (application      => 'xxptp'
                         ,program          => 'XXODROEMAILER'
                         ,start_time       => NULL
                         ,sub_request      => FALSE
                         ,argument1        => p_program_name
                         ,argument2        => p_email_address
                         ,argument3        => p_mail_subject
                         ,argument4        => p_mail_body
                         ,argument5        => p_attachment
                         ,argument6        => p_request_id
                         );
    ELSIF p_item_type='NT' THEN
       ln_request_id := FND_REQUEST.SUBMIT_REQUEST
                        (application       =>'xxptp' 
                         ,program          =>'XXODROEMAILER'
                         ,start_time       => NULL
                         ,sub_request      => FALSE
                         ,argument1        => p_program_name
                         ,argument2        => p_email_address
                         ,argument3        => p_mail_subject
                         ,argument4        => p_mail_body
                         ,argument5        => p_attachment
                         ,argument6        => p_request_id
                         );
    END IF;
    IF  ln_request_id = 0 THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'sending email notification failed');
    ELSE
      FND_FILE.PUT_LINE(FND_FILE.LOG,'email notification successfully sent');
    END IF;
EXCEPTION
WHEN OTHERS THEN
     lc_retcode := SQLCODE;
     lc_errbuff := SUBSTR(SQLERRM,1,250);
     FND_FILE.PUT_LINE(FND_FILE.LOG, lc_retcode || lc_errbuff);
END NOTIFY_PROC;

END XX_GI_EXCEPTION_PKG;
/

SHOW ERROR
