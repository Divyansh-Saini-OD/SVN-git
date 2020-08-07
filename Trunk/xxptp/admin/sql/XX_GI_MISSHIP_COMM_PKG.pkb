SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE BODY XX_GI_MISSHIP_COMM_PKG
 -- +===========================================================================+
 -- |                  Office Depot - Project Simplify                          |
 -- |             Oracle NAIO/WIPRO/Office Depot/Consulting Organization        |
 -- +===========================================================================+
 -- | Name             :  XX_GI_MISSHIP_COMM_PKG.pkb                            |
 -- | Description      :  This Package is used as a Custom API to Create an new |
 -- |                     PO line,Launch a workflow Notification,Get Item Price |
 -- | Change Record:                                                            |
 -- |===============                                                            |
 -- |Version   Date         Author           Remarks                            |
 -- |=======   ==========   =============    ===================================|
 -- |Draft 1a  22-Oct-2007  Chandan U H      Initial draft version              |
 -- | 1.0      31-Oct-2007  Chandan U H      Incorporated Review Comments       |
 -- +===========================================================================+
AS

-- ---------------------------
-- Global Variable Declaration
-- ---------------------------

G_PO_APPROVED_STATUS      CONSTANT VARCHAR2(30) := 'APPROVED';
G_STANDARD                CONSTANT VARCHAR2(30) := 'STANDARD';
G_PROGRAM_NAME            CONSTANT VARCHAR2(30) := 'POXPOPDOI';
G_PACKAGE_NAME            CONSTANT VARCHAR2(30) := 'XX_GI_MISSHIP_COMM_PKG';
G_PROGRAM_TYPE            CONSTANT VARCHAR2(30) := 'CUSTOM API';
G_PROGRAM_DESCRIPTION     CONSTANT VARCHAR2(30) := 'To Add a PO Line';
G_PROGRAM_APPLICATION     CONSTANT VARCHAR2(10) := 'PO';
G_LINE_ACTION             CONSTANT VARCHAR2(10) := 'ADD';
G_HEADER_ACTION           CONSTANT VARCHAR2(10) := 'UPDATE';
G_ITEM_INV_CATEGORY       CONSTANT mtl_category_sets.category_set_name%TYPE :='Inventory';
G_ITEM_PO_CATEGORY        CONSTANT mtl_category_sets.category_set_name%TYPE :='PO CATEGORY';
GN_BATCH_ID               CONSTANT PLS_INTEGER  := 0;
GN_PO_FOUND_FLAG          PLS_INTEGER           := 0;
GN_IDX                    PLS_INTEGER           := 1;

-----------------------------------
--Declaring Global Record Variables
-----------------------------------
TYPE po_header_rec IS RECORD (
                               po_header_id    po_headers_all.po_header_id%TYPE
                              ,new_line_num    po_lines_all.line_num%TYPE
                              );

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------
TYPE po_header_tbl_type IS  TABLE  OF  po_header_rec  INDEX BY BINARY_INTEGER;
gt_po_header_tbl   po_header_tbl_type;

-- +====================================================================+
-- | Name        : process_po                                           |
-- | Description : This procedure is invoked from the  procedure.       |
-- |               This procedure will submit the standard 'Import      |
-- |               Purchase Orders' concurrent to Create New PO line in |
-- |               an existing PO.                                      |
-- |                                                                    |
-- |  Parameters  : p_batch_id                                          |
-- |                x_errbuf                                            |
-- |                x_retcode                                           |
-- |                                                                    |
-- +====================================================================+
PROCEDURE  process_po(
                      p_batch_id      IN            NUMBER
                     ,x_errbuf        OUT  NOCOPY   VARCHAR2
                     ,x_retcode       OUT  NOCOPY   NUMBER
                     )
IS
----------------------------------------------
--  Local Variables and Exceptions Declaration
----------------------------------------------
EX_SUBMIT_FAIL              EXCEPTION;
EX_NORMAL_COMPLETION_FAIL   EXCEPTION;

lt_conc_request_id          FND_CONCURRENT_REQUESTS.request_id%TYPE;--conc_request_id of POXPDOI
lb_wait                     BOOLEAN;--wait time
lc_phase                    VARCHAR2(50);--phase of the program
lc_status                   VARCHAR2(50);--status of the program
lc_dev_phase                VARCHAR2(50);--dev phase of the program
lc_dev_status               VARCHAR2(50);--dev status of the program
lc_message                  VARCHAR2(1000);

BEGIN
    
    ---------------------------------------------------------------
    -- Submitting Standard Purchase Order Import concurrent program
    ---------------------------------------------------------------
      lt_conc_request_id := FND_REQUEST.submit_request(
                                                      application   => G_PROGRAM_APPLICATION
                                                     ,program       => G_PROGRAM_NAME
                                                     ,description   => G_PROGRAM_DESCRIPTION
                                                     ,start_time    => NULL
                                                     ,sub_request   => FALSE -- FALSE means is not a sub request
                                                     ,argument1     => NULL --Default Buyer
                                                     ,argument2     => G_STANDARD--Document Type
                                                     ,argument3     => NULL --Document SubType
                                                     ,argument4     => 'N'
                                                     ,argument5     => NULL -- Create Sourcing Rules
                                                     ,argument6     => G_PO_APPROVED_STATUS--Approval Status
                                                     ,argument7     => NULL--Release Generation Method
                                                     ,argument8     => GN_BATCH_ID --Batch Id
                                                     ,argument9     => NULL --Operating Unit
                                                     ,argument10    => NULL --Global Agreement
                                                 );

    IF lt_conc_request_id = 0 THEN
         x_errbuf  := fnd_message.get;
         fnd_file.put_line(fnd_file.LOG,'Standard program failed to submit ');
         RAISE EX_SUBMIT_FAIL;
    ELSE
         fnd_file.put_line(fnd_file.LOG,'Submitted with Req Id'||lt_conc_request_id);
         COMMIT;       
         ----------------------------------------------------------------
         --Wait till the standard import program completes for this Batch
         ----------------------------------------------------------------
        lb_wait := fnd_concurrent.wait_for_request(  request_id  => lt_conc_request_id
                                                    ,interval    => 20
                                                    ,phase       => lc_phase
                                                    ,status      => lc_status
                                                    ,dev_phase   => lc_dev_phase
                                                    ,dev_status  => lc_dev_status
                                                    ,message     => lc_message
                                                   );

         IF ((lc_dev_phase = 'COMPLETE') AND (lc_dev_status = 'NORMAL')) THEN
            NULL;
         ELSE
             RAISE EX_NORMAL_COMPLETION_FAIL;
         END IF;--IF ((lc_dev_phase = 'COMPLETE') AND (lc_dev_status = 'NORMAL'))

    END IF;--lt_conc_request_id = 0
    x_retcode := 0;
EXCEPTION
    WHEN EX_SUBMIT_FAIL THEN
       x_retcode := 2;
       x_errbuf  := 'Standard  program failed to submit: ' || x_errbuf;

    WHEN EX_NORMAL_COMPLETION_FAIL THEN
       x_retcode := 2;
       x_errbuf  := 'Standard program failed to Complete Normally' || x_errbuf;

    WHEN OTHERS THEN
       x_errbuf  := 'Unexpected Exception is raised in Procedure PROCESS_PO '||substr(SQLERRM,1,200);
       x_retcode := 2;
END process_po;

-- +========================================================================+
-- | Name        :  log_procedure                                           |
-- |                                                                        |
-- | Description :  This procedure is invoked to log the exceptions in      |
-- |                the common exception log table                          |
-- |                                                                        |
-- |                                                                        |
-- | Parameters  : p_program_type                                           |
-- |               p_program_name                                           |
-- |               p_error_location                                         |
-- |               p_error_message_code                                     |
-- |               p_error_message                                          |
-- |               p_error_message_severity                                 |
-- |               p_notify_flag                                            |
-- |               p_object_id                                              |
-- |               p_attribute1                                             |
-- +========================================================================+
PROCEDURE log_procedure(  p_program_name           IN VARCHAR2
                         ,p_error_location         IN VARCHAR2
                         ,p_error_message_code     IN VARCHAR2
                         ,p_error_message          IN VARCHAR2
                         ,p_error_message_severity IN VARCHAR2
                         ,p_notify_flag            IN VARCHAR2
                         ,p_object_id              IN VARCHAR2
                         ,p_attribute1             IN VARCHAR2
                         )
IS

   BEGIN
       -- -----------------------------------------------------------------
       -- Call the common package to log exceptions
       -- -----------------------------------------------------------------
       XX_COM_ERROR_LOG_PUB.log_error (
                                       p_program_type            => G_PROGRAM_TYPE
                                      ,p_program_name            => G_PACKAGE_NAME||'.'||p_program_name
                                      ,p_program_id              =>  NULL
                                      ,p_module_name             => G_PROGRAM_APPLICATION
                                      ,p_error_location          => p_error_location
                                      ,p_error_message_count     => NULL
                                      ,p_error_message_code      => p_error_message_code
                                      ,p_error_message           => p_error_message
                                      ,p_error_message_severity  => p_error_message_severity
                                      ,p_notify_flag             => p_notify_flag
                                      ,p_object_type             => G_PROGRAM_TYPE
                                      ,p_object_id               => p_object_id
                                      ,p_attribute1              => p_attribute1
                                      ,p_attribute2              => G_PROGRAM_TYPE
                                      ,p_return_code             => NULL
                                      ,p_msg_count               => NULL
                                      );
EXCEPTION
   WHEN OTHERS THEN
      log_procedure(  p_program_name           => 'log_procedure'
                     ,p_error_location         => 'WHEN OTHERS THEN'
                     ,p_error_message_code     =>  SQLCODE
                     ,p_error_message          => 'WHEN OTHERS THEN when calling Log Procedure'
                     ,p_error_message_severity => 'MINOR'
                     ,p_notify_flag            => 'Y'
                     ,p_object_id              =>  NULL
                     ,p_attribute1             =>  NULL
                 );
END log_procedure;
-- +========================================================================+
-- | Name        :  validate_po_line                                        |
-- |                                                                        |
-- | Description :  This procedure is invoked validate before inserting into|
-- |                PO Interface Table                                      |
-- |                                                                        |
-- | Parameters  : p_po_number                                              |
-- |               p_vendor_id                                              |
-- |               p_vendor_site_id                                         |
-- |               p_inv_item_id                                            |
-- |               p_line_ship_to_org_id                                    |
-- |               x_error_status                                           |
-- |               x_error_message                                          |
-- +========================================================================+
PROCEDURE validate_po_line(
                         p_po_number              IN            po_headers_all.segment1%TYPE
                        ,p_vendor_id              IN            po_headers_all.vendor_id%TYPE       
                        ,p_vendor_site_id         IN            po_headers_all.vendor_site_id%TYPE     
                        ,p_inv_item_id            IN            po_lines_interface.item_id%TYPE   
                        ,p_line_ship_to_org_id    IN            po_lines_interface.ship_to_organization_id%TYPE
                        ,x_error_status           OUT   NOCOPY  VARCHAR2
                        ,x_error_message          OUT   NOCOPY  VARCHAR2
                         )
IS
--------------------------------
--  Local Variables Declaration
-------------------------------
lc_valid_approved_po      VARCHAR2(1);
lc_valid_item_category    VARCHAR2(1);
lc_valid_asl              VARCHAR2(1);
lc_item_cat_err_msg       VARCHAR2(240);
lc_valid_po_err_msg       VARCHAR2(240);
lc_valid_asl_err_msg      VARCHAR2(240);

--------------------------------------------
--Cursor to check whether the PO is approved
--------------------------------------------
CURSOR lcu_valid_approved_po
IS
SELECT 'Y'
FROM   po_headers_all
WHERE  segment1 = p_po_number
AND    UPPER(authorization_status) = G_PO_APPROVED_STATUS;

--------------------------------------------
--Cursor to check the Category of the Item
--------------------------------------------
CURSOR lcu_valid_item_category
IS
SELECT 'Y'
FROM    mtl_category_sets       MCS
      , mtl_item_categories     MIC
      , mtl_system_items_b      MSIB
WHERE MSIB.inventory_item_id  = MIC.inventory_item_id
AND   MSIB.organization_id    = MIC.organization_id
AND   MCS.category_set_id     = MIC.category_set_id
AND   MSIB.organization_id    = p_line_ship_to_org_id
AND   MSIB.inventory_item_id  = p_inv_item_id
AND   MCS.CATEGORY_SET_NAME  IN (G_ITEM_INV_CATEGORY, G_ITEM_PO_CATEGORY );

------------------------------------------------------------
--Cursor to check if Vendor exists in Approved Supplier List
------------------------------------------------------------
CURSOR lcu_valid_asl
IS
SELECT 'Y'
FROM   po_approved_supplier_list PASL
WHERE  vendor_id              = p_vendor_id
AND    item_id                = p_inv_item_id
AND    asl_status_id          = 2
AND    NVL (disable_flag,'N') = 'N'
AND    using_organization_id  = p_line_ship_to_org_id;

BEGIN
   
   OPEN lcu_valid_approved_po;
   FETCH lcu_valid_approved_po INTO lc_valid_approved_po;
        IF lcu_valid_approved_po%NOTFOUND THEN
           lc_valid_po_err_msg :='No Data Found while selecting valid_approved_po';
           fnd_file.put_line(fnd_file.LOG,lc_valid_po_err_msg);
            --Adding error message to stack
            log_procedure(  p_program_name           => 'validate_po_line'
                           ,p_error_location         => 'NO_DATA_FOUND'
                           ,p_error_message_code     =>  SQLCODE
                           ,p_error_message          =>  lc_valid_po_err_msg
                           ,p_error_message_severity =>  'MINOR'
                           ,p_notify_flag            =>  'Y'
                           ,p_object_id              =>  NULL
                           ,p_attribute1             =>  NULL
                          );
         x_error_message := x_error_message || lc_valid_po_err_msg;

         END IF;
   CLOSE lcu_valid_approved_po;
   
   OPEN lcu_valid_asl;
   FETCH lcu_valid_asl INTO lc_valid_asl;
        IF lcu_valid_asl%NOTFOUND THEN
            lc_valid_asl_err_msg :='No Data Found while selecting valid_asl';
            fnd_file.put_line(fnd_file.LOG,lc_valid_asl_err_msg);
            --Adding error message to stack
            log_procedure(  p_program_name           => 'validate_po_line'
                           ,p_error_location         => 'NO_DATA_FOUND'
                           ,p_error_message_code     =>  SQLCODE
                           ,p_error_message          =>  lc_valid_asl_err_msg
                           ,p_error_message_severity =>  'MINOR'
                           ,p_notify_flag            =>  'Y'
                           ,p_object_id              =>  NULL
                           ,p_attribute1             =>  NULL
                          );
         x_error_message := x_error_message ||lc_valid_asl_err_msg;
        END IF;
   CLOSE lcu_valid_asl;

   OPEN lcu_valid_item_category;
   FETCH lcu_valid_item_category INTO lc_valid_item_category;
        IF lcu_valid_item_category%NOTFOUND THEN
            lc_item_cat_err_msg := 'No Data Found while selecting valid_item_category';
            fnd_file.put_line(fnd_file.LOG,lc_item_cat_err_msg);
            --Adding error message to stack
            log_procedure(  p_program_name           => 'validate_po_line'
                           ,p_error_location         => 'NO_DATA_FOUND'
                           ,p_error_message_code     =>  SQLCODE
                           ,p_error_message          =>  lc_item_cat_err_msg
                           ,p_error_message_severity =>  'MINOR'
                           ,p_notify_flag            =>  'Y'
                           ,p_object_id              =>  NULL
                           ,p_attribute1             =>  NULL
                          );
            x_error_message := x_error_message ||lc_item_cat_err_msg;
        END IF;
   CLOSE lcu_valid_item_category;

    --If all the Validations are successful,then set error status to 'S' else to 'E'
    
     IF     NVL(lc_valid_asl,'N') = 'Y'
        AND NVL(lc_valid_approved_po,'N') ='Y'
        AND NVL(lc_valid_item_category,'N') = 'Y' THEN
          x_error_status := 'S';
     ELSE
          x_error_status :=  'E';
     END IF;

EXCEPTION
   WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.LOG,'WHEN OTHERS THEN in validate_po_line'||SUBSTR(SQLERRM,1,240));
      x_error_status :=  'E';
         log_procedure(  p_program_name           => 'validate_po_line'
                        ,p_error_location         => 'WHEN OTHERS THEN'
                        ,p_error_message_code     =>  SQLCODE
                        ,p_error_message          =>  SUBSTR(SQLERRM,1,240)
                        ,p_error_message_severity =>  'MAJOR'
                        ,p_notify_flag            =>  'Y'
                        ,p_object_id              =>  NULL
                        ,p_attribute1             =>  NULL
                       );
END validate_po_line;

-- +========================================================================+
-- | Name        :  insert_po_line                                          |
-- |                                                                        |
-- | Description :  This procedure is invoked to insert the records into    |
-- |                PO Interface Tables.                                    |
-- |                                                                        |
-- | Parameters  : p_po_number                                              |
-- |               p_vendor_id                                              |
-- |               p_vendor_site_id                                         |
-- |               p_line_item                                              |
-- |               p_uom_code                                               |
-- |               p_org_id                                                 |
-- |               p_po_header_id                                           |
-- |               x_po_headers_interface_id                                |
-- |               x_error_status                                           |
-- |               x_error_message                                          |
-- |                                                                        |
-- +========================================================================+
PROCEDURE insert_po_line(
                         p_po_number                IN            po_headers_all.segment1%TYPE   
                        ,p_vendor_id                IN            po_headers_all.vendor_id%TYPE      
                        ,p_vendor_site_id           IN            po_headers_all.vendor_site_id%TYPE     
                        ,p_line_item                IN            po_lines_interface.item%TYPE 
                        ,p_item_description         IN            po_lines_interface.item_description%TYPE    
                        ,p_inv_item_id              IN            po_lines_interface.item_id%TYPE      
                        ,p_uom_code                 IN            po_lines_interface.uom_code%TYPE       
                        ,p_org_id                   IN            po_headers_all.org_id%TYPE        
                        ,p_po_header_id             IN            po_headers_all.po_header_id%TYPE                                         
                        ,p_ship_to_location_id      IN            po_lines_interface.ship_to_location_id%TYPE  
                        ,p_ship_to_organization_id  IN            po_lines_interface.ship_to_organization_id%TYPE    
                        ,p_line_quantity            IN            po_lines_interface.quantity%TYPE  
                        ,p_unit_price               IN            po_lines_interface.unit_price%TYPE     
                        ,x_po_headers_interface_id  OUT  NOCOPY   po_lines_interface.interface_header_id%TYPE  
                        ,x_error_status             OUT  NOCOPY   VARCHAR2
                        ,x_error_message            OUT  NOCOPY   VARCHAR2
                        )
IS
--------------------------------
--  Local Variables Declaration
-------------------------------
ln_new_item_line       NUMBER  :=0;
----------------------------------
--Cursor to get the New Item Line
----------------------------------
CURSOR lcu_new_item_line(p_po_header_id IN VARCHAR2)
IS
   SELECT MAX(line_num) + 1
   FROM   po_lines_all
   WHERE  po_header_id = p_po_header_id;

BEGIN

   fnd_file.put_line(fnd_file.LOG,'Inside For Insertion ');

   OPEN lcu_new_item_line(p_po_header_id);
   FETCH lcu_new_item_line INTO ln_new_item_line;
        IF lcu_new_item_line%NOTFOUND THEN
            --Adding error message to stack
            log_procedure(  p_program_name           => 'insert_po_line'
                           ,p_error_location         => 'NO_DATA_FOUND'
                           ,p_error_message_code     =>  SQLCODE
                           ,p_error_message          =>  'No Data Found while selecting new_item_line'
                           ,p_error_message_severity =>  'MINOR'
                           ,p_notify_flag            =>  'Y'
                           ,p_object_id              =>  NULL
                           ,p_attribute1             =>  NULL
                          );

        END IF;
   CLOSE lcu_new_item_line;
   
   --If the same PO number comes in,then the max(line number) returned
   --so,increment the line number if same PO number is sent in.
   
   gn_po_found_flag := 0;
   IF  gt_po_header_tbl.COUNT = 0 THEN
       gt_po_header_tbl(gn_idx).po_header_id := p_po_header_id;
       gt_po_header_tbl(gn_idx).new_line_num := ln_new_item_line;   
   ELSE
       FOR i IN gt_po_header_tbl.FIRST..gt_po_header_tbl.LAST
       LOOP         
           IF gt_po_header_tbl(i).po_header_id = p_po_header_id THEN
               ln_new_item_line := gt_po_header_tbl(gn_idx).new_line_num + 1;               
               gn_idx := gn_idx + 1;
               gt_po_header_tbl(gn_idx).new_line_num := ln_new_item_line;               
               gn_po_found_flag := 1;
               EXIT;
           END IF;
       END LOOP;
       
       IF  gn_po_found_flag = 0 THEN
           gn_idx := gn_idx + 1;
           gt_po_header_tbl(gn_idx).po_header_id := p_po_header_id;
           gt_po_header_tbl(gn_idx).new_line_num := ln_new_item_line;
       END IF;
   END IF; --IF gt_po_header_tbl.COUNT = 0

    SELECT po_headers_interface_s.NEXTVAL
    INTO   x_po_headers_interface_id
    FROM   DUAL;

      fnd_file.put_line(fnd_file.LOG,'Crossed all Blocks ');

       INSERT INTO po_headers_interface(
                                 interface_header_id
                                ,batch_id
                                ,action
                                ,org_id
                                ,document_type_code 
                                ,document_num                                                            
                                ,vendor_id                                
                                ,vendor_site_id
                                ,ship_to_location_id                                
                                ,approval_status
                                ,approved_date
                                ,creation_date
                                ,created_by
                                ,last_update_date
                                ,last_updated_by
                                ,last_update_login)
                        VALUES(
                                 x_po_headers_interface_id
                                ,GN_BATCH_ID
                                ,G_HEADER_ACTION
                                ,p_org_id
                                ,G_STANDARD
                                ,p_po_number                                                       
                                ,p_vendor_id                                
                                ,p_vendor_site_id
                                ,p_ship_to_location_id                               
                                ,G_PO_APPROVED_STATUS
                                ,SYSDATE
                                ,SYSDATE
                                ,FND_GLOBAL.USER_ID
                                ,SYSDATE
                                ,FND_GLOBAL.USER_ID
                                ,FND_GLOBAL.LOGIN_ID
                                );

  INSERT INTO po_lines_interface(
                                 interface_line_id
                                ,interface_header_id
                                ,line_num
                                ,shipment_num                                
                                ,item
                                ,item_description
                                ,item_id
                                ,uom_code
                                ,quantity
                                ,unit_price                                 
                                ,ship_to_location_id
                                ,ship_to_organization_id                                
                                ,action
                                ,creation_date
                                ,created_by
                                ,last_update_date
                                ,last_updated_by
                                ,last_update_login
                                )
                         VALUES(
                                 po_lines_interface_s.NEXTVAL
                                 ,x_po_headers_interface_id
                                 ,ln_new_item_line
                                 ,1                                
                                 ,p_line_item
                                 ,p_item_description
                                 ,p_inv_item_id
                                 ,p_uom_code
                                 ,p_line_quantity
                                 ,p_unit_price                                    
                                 ,p_ship_to_location_id
                                 ,p_ship_to_organization_id
                                 ,G_LINE_ACTION
                                 ,SYSDATE
                                 ,FND_GLOBAL.USER_ID
                                 ,SYSDATE
                                 ,FND_GLOBAL.USER_ID
                                 ,FND_GLOBAL.LOGIN_ID
                                 );

    INSERT INTO po_distributions_interface(
                                 interface_header_id
                                ,interface_line_id
                                ,interface_distribution_id
                                ,distribution_num
                                ,quantity_ordered   
                                ,creation_date
                                ,created_by
                                ,last_update_date
                                ,last_updated_by
                                ,last_update_login
                                )
                          VALUES(
                                 x_po_headers_interface_id
                                ,po_lines_interface_s.CURRVAL
                                ,po_distributions_interface_s.NEXTVAL
                                ,1
                                ,p_line_quantity
                                ,SYSDATE
                                ,FND_GLOBAL.USER_ID
                                ,SYSDATE
                                ,FND_GLOBAL.USER_ID
                                ,FND_GLOBAL.LOGIN_ID
                               );

             x_error_status := 'S';

 EXCEPTION
    WHEN OTHERS THEN
       x_error_status  := 'E';
       x_error_message := SUBSTR(SQLERRM,1,240);
       fnd_file.put_line(fnd_file.LOG,'WHEN OTHERS THEN in validate_po_line'||SUBSTR(SQLERRM,1,240));
       log_procedure(  p_program_name           => 'insert_po_line '
                      ,p_error_location         => 'WHEN OTHERS THEN'
                      ,p_error_message_code     =>  SQLCODE
                      ,p_error_message          =>  SUBSTR(SQLERRM,1,240)
                      ,p_error_message_severity =>  'MAJOR'
                      ,p_notify_flag            =>  'Y'
                      ,p_object_id              =>  NULL
                      ,p_attribute1             =>  NULL
                     );
END insert_po_line;

-- +================================================================================+
-- | Name        :  create_po_line                                                  |
-- | Description :  This procedure is makes a call to the procedures to validate and|
-- |                Insert successfully validated records into  PO Interface Tables.|
-- |                This Program also calls procedure to Launch the Standard "Import|
-- |                Purchase Orders" Program to create a new line on PO.            |
-- | Parameters  :  p_add_po_line_tbl                                               |
-- |                x_return_status                                                 |
-- |                x_return_message                                                |
-- +================================================================================+
PROCEDURE  create_po_line (
                             p_add_po_line_tbl   IN OUT    po_add_line_rec_tbl_type
                            ,x_return_status     OUT     NOCOPY    VARCHAR2
                            ,x_return_message    OUT     NOCOPY    VARCHAR2
                              )
AS
--------------------------------
--  Local Variables Declaration
-------------------------------
ln_succ_inserted       PLS_INTEGER:=0;
lc_errbuff             VARCHAR2(200);
ln_retcode             NUMBER;
lc_return_status       VARCHAR2(1);
lc_return_msg          VARCHAR2(2000);
lc_error_message       VARCHAR2(2000);
lc_error_status        VARCHAR2(1);

EX_PROCESS_PO_ERROR    EXCEPTION;

--------------------------------------
--Cursor to get the interface Errors
--------------------------------------

CURSOR lcu_interface_error (p_interface_header_id NUMBER)
IS
    SELECT POIE.error_message, 'E' error_status
    FROM   po_interface_errors POIE
    WHERE  POIE.interface_header_id = p_interface_header_id;

BEGIN   

   FOR idx IN p_add_po_line_tbl.FIRST..p_add_po_line_tbl.LAST
   LOOP
       

       validate_po_line(
                         p_po_number               =>  p_add_po_line_tbl(idx).header_po_number
                        ,p_vendor_id               =>  p_add_po_line_tbl(idx).header_vendor_id
                        ,p_vendor_site_id          =>  p_add_po_line_tbl(idx).header_vendor_site_id
                        ,p_inv_item_id             =>  p_add_po_line_tbl(idx).inv_item_id
                        ,p_line_ship_to_org_id     =>  p_add_po_line_tbl(idx).line_ship_to_org_id
                        ,x_error_status            =>  lc_return_status
                        ,x_error_message           =>  lc_return_msg
                        );       

       IF lc_return_status = 'S' THEN
       
           insert_po_line(
                         p_po_number               => p_add_po_line_tbl(idx).header_po_number
                        ,p_vendor_id               => p_add_po_line_tbl(idx).header_vendor_id
                        ,p_vendor_site_id          => p_add_po_line_tbl(idx).header_vendor_site_id
                        ,p_line_item               => p_add_po_line_tbl(idx).line_item
                        ,p_item_description        => p_add_po_line_tbl(idx).item_description
                        ,p_inv_item_id             => p_add_po_line_tbl(idx).inv_item_id
                        ,p_uom_code                => p_add_po_line_tbl(idx).uom_code
                        ,p_org_id                  => p_add_po_line_tbl(idx).org_id
                        ,p_po_header_id            => p_add_po_line_tbl(idx).po_header_id                        
                        ,p_ship_to_location_id     => p_add_po_line_tbl(idx).line_ship_to_location_id
                        ,p_ship_to_organization_id => p_add_po_line_tbl(idx).line_ship_to_org_id
                        ,p_line_quantity           => p_add_po_line_tbl(idx).line_quantity
                        ,p_unit_price              => p_add_po_line_tbl(idx).line_unit_price
                        ,x_po_headers_interface_id => p_add_po_line_tbl(idx).interface_header_id
                        ,x_error_status            => lc_return_status
                        ,x_error_message           => lc_return_msg
                        );
            
            IF lc_return_status = 'S' THEN                
                ln_succ_inserted := ln_succ_inserted + 1;
            ELSE -- If error in inserting
                 p_add_po_line_tbl(idx).error_status        := lc_return_status;
                 p_add_po_line_tbl(idx).error_message       := lc_return_msg;
                 p_add_po_line_tbl(idx).interface_header_id := NULL;
            END IF;
       ELSE  -- If error in validation
           p_add_po_line_tbl(idx).error_status        := lc_return_status;
           p_add_po_line_tbl(idx).error_message       := lc_return_msg;
           p_add_po_line_tbl(idx).interface_header_id := NULL;
       END IF;

   END LOOP;
  
   --Launch Standard Program if any record is inserted in the interface table
   IF ln_succ_inserted > 0 THEN
       COMMIT;       
       process_po(
                 p_batch_id   => GN_BATCH_ID
                ,x_errbuf     => lc_errbuff
                ,x_retcode    => ln_retcode
                 );
                 
       IF ln_retcode <> 0 THEN
          RAISE EX_PROCESS_PO_ERROR;
       END IF;
       
   END IF;--ln_succ_inserted > 0

   FOR idx IN p_add_po_line_tbl.FIRST..p_add_po_line_tbl.LAST
   LOOP
      IF p_add_po_line_tbl(idx).interface_header_id IS NOT NULL THEN
         FOR lcu_multiple_errors_rec in lcu_interface_error (p_add_po_line_tbl(idx).interface_header_id)
         LOOP
            lc_error_message := lc_error_message || lcu_multiple_errors_rec.error_message;
            lc_error_status  := lcu_multiple_errors_rec.error_status;
         END LOOP;
         
         p_add_po_line_tbl(idx).error_message := lc_error_message;
         p_add_po_line_tbl(idx).error_status  := lc_error_status;
         fnd_file.put_line(fnd_file.LOG,'After errors Cursor');
      END IF;
      
   END LOOP;
   
      x_return_status := 'S';

EXCEPTION
   WHEN EX_PROCESS_PO_ERROR THEN
       x_return_status := 'E';
       fnd_file.put_line(fnd_file.LOG,'EX_PROCESS_PO_ERROR in create_po_line'||SUBSTR(SQLERRM,1,240));
       log_procedure(  p_program_name           => 'create_po_line'
                      ,p_error_location         => 'EX_PROCESS_PO_ERROR'
                      ,p_error_message_code     =>  SQLCODE
                      ,p_error_message          =>  SUBSTR(SQLERRM,1,240)
                      ,p_error_message_severity =>  'MAJOR'
                      ,p_notify_flag            =>  'Y'
                      ,p_object_id              =>  NULL
                      ,p_attribute1             =>  NULL
                     );
   WHEN OTHERS THEN
       x_return_status := 'E';
       fnd_file.put_line(fnd_file.LOG,'WHEN OTHERS THEN in create_po_line'||SUBSTR(SQLERRM,1,240));
       log_procedure(  p_program_name           => 'create_po_line'
                      ,p_error_location         => 'WHEN OTHERS THEN'
                      ,p_error_message_code     =>  SQLCODE
                      ,p_error_message          =>  SUBSTR(SQLERRM,1,240)
                      ,p_error_message_severity =>  'MAJOR'
                      ,p_notify_flag            =>  'Y'
                      ,p_object_id              =>  NULL
                      ,p_attribute1             =>  NULL
                     );
END  create_po_line;
-- +================================================================================+
-- | Name        : po_get_item_price                                                |
-- | Description : This Procedure determines the Item Cost by calling another Custom|
-- |               function XX_PO_GET_ITEM_PRICE.                                   |
-- |                                                                                |
-- | Parameters  :  p_vendor_id                                                     |
-- |                p_item_id                                                       |
-- |                p_order_qty                                                     |
-- |                x_item_cost                                                     |
-- |                x_return_message                                                |
-- +================================================================================+
PROCEDURE   po_get_item_price(
                               p_vendor_id        IN           NUMBER
                              ,p_item_id          IN           NUMBER
                              ,p_order_qty        IN           NUMBER
                              ,p_vendor_site_id   IN OUT       NUMBER
                              ,x_item_cost        OUT  NOCOPY  NUMBER
                              ,x_return_message   OUT  NOCOPY  VARCHAR2
                              )
IS
   BEGIN
   
      x_item_cost:= XX_PO_GET_ITEM_PRICE(
                               p_vendor_id      => p_vendor_id
                              ,p_item_id        => p_item_id
                              ,p_order_qty      => p_order_qty
                              ,p_vendor_site_id => p_vendor_site_id
                              );

EXCEPTION
   WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.LOG,'WHEN OTHERS THEN in po_get_item_price'||SUBSTR(SQLERRM,1,240));
      log_procedure(  p_program_name           => 'po_get_item_price'
                     ,p_error_location         => 'WHEN OTHERS THEN'
                     ,p_error_message_code     =>  SQLCODE
                     ,p_error_message          =>  SUBSTR(SQLERRM,1,240)
                     ,p_error_message_severity =>  'MAJOR'
                     ,p_notify_flag            =>  'Y'
                     ,p_object_id              =>  NULL
                     ,p_attribute1             =>  NULL
                    );
      x_return_message := SUBSTR(SQLERRM,1,200);
END po_get_item_price;

-- +================================================================================+
-- | Name        : generate_message                                                 |
-- | Description : This Procedure generates the message body that needs to be sent  |
-- |               to the email recipient derived from Profile Option.              |
-- |                                                                                |
-- | Parameters  : p_document_id                                                    |
-- |               p_display_type                                                   |
-- |               p_document                                                       |
-- |               p_document_type                                                  |
-- |                                                                                |
-- +================================================================================+
PROCEDURE generate_message(
                            p_document_id   IN       CLOB
                           ,p_display_type  IN       VARCHAR2
                           ,p_document      IN OUT   CLOB
                           ,p_document_type IN OUT   VARCHAR2
                           )
IS
--------------------------------
--  Local Variables Declaration
-------------------------------
lc_document1 CLOB;

BEGIN

    lc_document1  :=  RPAD(' Office Depot',45,' ')||' Date : '||TO_CHAR(SYSDATE,'dd-Mon-yy hh24:mi:ss')||CHR(10);
    lc_document1  := lc_document1  ||p_document_id;

    --Generate your message text here
    p_document:= lc_document1;

EXCEPTION
   WHEN OTHERS THEN   
      fnd_file.put_line(fnd_file.LOG,'WHEN OTHERS THEN in  generate_message'||SUBSTR(SQLERRM,1,240));
      p_document:= 'Unexpected Error :'||SQLERRM;
      log_procedure(   p_program_name           => 'generate_message'
                      ,p_error_location         => 'WHEN OTHERS THEN'
                      ,p_error_message_code     =>  SQLCODE
                      ,p_error_message          =>  SUBSTR(SQLERRM,1,240)
                      ,p_error_message_severity =>  'MAJOR'
                      ,p_notify_flag            =>  'Y'
                      ,p_object_id              =>  NULL
                      ,p_attribute1             =>  NULL
                       );   
    

END generate_message;

-- +================================================================================+
-- | Name        : send_notification                                                |
-- | Description : This Procedure sends an email Notification to the appropriate    |
-- |               recipient derived from Profile Option.                           |
-- |                                                                                |
-- | Parameters  :  p_item_details                                                  |
-- |                                                                                |
-- +================================================================================+
PROCEDURE send_notification (
                              p_item_details      IN      item_details_rec_tbl_type
                             ,x_return_status     OUT     NOCOPY    VARCHAR2
                             ,x_return_message    OUT     NOCOPY    VARCHAR2
                             )
IS

--------------------------------
--  Local Variables Declaration
-------------------------------
lc_item_key_seq_no             NUMBER;
lc_send_notification           VARCHAR2(1);
lc_item_key                    VARCHAR2(1000) := NULL;
lc_role                        VARCHAR2(20)   :='MISSHIP';
lc_itemkey_prefix              VARCHAR2(20)   :='XX_GI_MISSHIP-';
lc_role_display_name           VARCHAR2(20)   :='MISSHIP';
lc_email_id                    VARCHAR2(240);
lc_role_name                   VARCHAR2(100);
lc_item_details_comman         VARCHAR2(400);
lc_itm_details_com_trd         VARCHAR2(400);
lc_itm_details_com_no_trd      VARCHAR2(400);
lc_item_details                CLOB           := NULL;
lc_trade_itm_dtls              CLOB           := NULL;
lc_non_trade_itm_dtls          CLOB           := NULL;
ln_non_trade_count             PLS_INTEGER:=0;
ln_trade_count                 PLS_INTEGER:=0;

-----------------------------------------------------------
--Cursor to get the Role asscociated with the email-address
-----------------------------------------------------------

CURSOR lcu_wf_role(p_email_address in VARCHAR2)
IS
   SELECT name
   FROM   wf_roles
   WHERE  email_address = (p_email_address)
   AND    notification_preference = 'MAILTEXT'
   ORDER  by start_date desc;

   BEGIN
           
      lc_item_details_comman := lc_item_details_comman ||RPAD('Loc',10,' ')    ||CHR(09);
      lc_item_details_comman := lc_item_details_comman ||RPAD('PO Number',15,' ') ||CHR(09);
      lc_item_details_comman := lc_item_details_comman ||RPAD('SKU',15,' ')||CHR(09);
      lc_item_details_comman := lc_item_details_comman ||RPAD('UPC/VPC',10,' ')||CHR(09);
      lc_item_details_comman := lc_item_details_comman ||RPAD('ASN Ref',10,' ')||CHR(10);
      lc_item_details_comman := lc_item_details_comman ||RPAD(' ',71,'-')||CHR(13)||CHR(10);
      
          FOR i in p_item_details.first..p_item_details.last    
            LOOP
             IF p_item_details(i).item_type = 'TRADE' THEN
                ln_trade_count := ln_trade_count + 1;                
                lc_trade_itm_dtls  := lc_trade_itm_dtls|| RPAD(p_item_details(i).loc,10,' ')    ||CHR(09);
                lc_trade_itm_dtls  := lc_trade_itm_dtls|| RPAD(p_item_details(i).po_number,15,' ') ||CHR(09);
                lc_trade_itm_dtls  := lc_trade_itm_dtls|| RPAD(p_item_details(i).sku,15,' ')||CHR(09);
                lc_trade_itm_dtls  := lc_trade_itm_dtls|| RPAD(p_item_details(i).upc_vpc,10,' ')||CHR(09);
                lc_trade_itm_dtls  := lc_trade_itm_dtls|| RPAD(p_item_details(i).asnref,10,' ')||CHR(13)||CHR(10);
   
             ELSE
                ln_non_trade_count := ln_non_trade_count + 1;                
                lc_non_trade_itm_dtls  := lc_non_trade_itm_dtls || RPAD(p_item_details(i).loc,10,' ')    ||CHR(09);
                lc_non_trade_itm_dtls  := lc_non_trade_itm_dtls || RPAD(p_item_details(i).po_number,10,' ') ||CHR(09);
                lc_non_trade_itm_dtls  := lc_non_trade_itm_dtls || RPAD(p_item_details(i).sku,10,' ')||CHR(09);
                lc_non_trade_itm_dtls  := lc_non_trade_itm_dtls || RPAD(p_item_details(i).upc_vpc,10,' ')||CHR(09);
                lc_non_trade_itm_dtls  := lc_non_trade_itm_dtls || RPAD(p_item_details(i).asnref,10,' ')||CHR(13)||CHR(10);
                   
             END IF;   
        END LOOP;
        
        --Loop twice for trade and Non trade
        
        FOR i IN 1..2
        LOOP        
           lc_email_id := NULL;
           lc_item_details := NULL;
           lc_send_notification :='N';
           lc_item_key := NULL;
        
           SELECT xx_gi_misship_itemkey_s.NEXTVAL
           INTO   lc_item_key_seq_no
           FROM   dual;        
        
           IF i = 1 THEN
               IF lc_trade_itm_dtls IS NOT NULL THEN
                   lc_send_notification :='S';
                   lc_email_id := FND_PROFILE.VALUE('OD: GI MISSHIP TRADE ITEM NOTIFICATION TEAM');
                   lc_itm_details_com_trd     := LPAD('OD GI Trade Items to be Modelled',50)||CHR(10)||CHR(10);
                   lc_itm_details_com_trd     := lc_itm_details_com_trd  ||LPAD('The following Trade Items are not defined in Item Master/Item Org: ',68)||CHR(10)||CHR(10);
                   lc_trade_itm_dtls          := lc_itm_details_com_trd  ||lc_item_details_comman|| lc_trade_itm_dtls||CHR(10);
                   lc_trade_itm_dtls          := lc_trade_itm_dtls ||'No of records to be modelled  :   '||ln_trade_count||CHR(10)||CHR(10);
                   lc_item_details            := lc_trade_itm_dtls||'*** End of Report - < OD GI Trade Items to be Modelled > ***';
                   lc_item_key                := lc_itemkey_prefix||lc_item_key_seq_no;
               END IF;
           ELSE
               IF lc_non_trade_itm_dtls IS NOT NULL THEN
                   lc_send_notification :='S';
                   lc_email_id := FND_PROFILE.VALUE('OD: GI MISSHIP NON-TRADE ITEM NOTIFICATION TEAM');                          
                   lc_itm_details_com_no_trd       := LPAD('OD GI Non-Trade Items to be Modelled',60)||CHR(10)||CHR(10);
                   lc_itm_details_com_no_trd       := lc_itm_details_com_no_trd ||LPAD('The following Non Trade Items are not defined in Item Master/Item Org: ',73)||CHR(10)||CHR(10);                       
                   lc_non_trade_itm_dtls           := lc_itm_details_com_no_trd ||lc_item_details_comman||lc_non_trade_itm_dtls||CHR(10);
                   lc_non_trade_itm_dtls           := lc_non_trade_itm_dtls ||'No of records to be modelled  :  '||ln_non_trade_count||CHR(10)||CHR(10);                                                            
                   lc_item_details                 := lc_non_trade_itm_dtls  ||'*** End of Report - < OD GI Trade Non-Items to be Modelled > ***';        
                   lc_item_key                     := lc_itemkey_prefix||lc_item_key_seq_no;
               END IF;
           END IF;
        
        
         IF lc_send_notification = 'S' THEN       
         
              wf_engine.createprocess   (
                                         itemtype                => 'XXMISSHP'
                                        ,itemkey                 =>  lc_item_key
                                        ,process                 => 'XX_GI_MISSHIP_PROCESS'
                                          );    
                                          
              OPEN lcu_wf_role(lc_email_id);       
              FETCH lcu_wf_role INTO lc_role_name;              
                 IF lcu_wf_role%NOTFOUND THEN                  
                    lc_role_name := lc_role || lc_item_key_seq_no;               
                    --Calling API to create a Role and associate that Role with the email-address derived
                    Wf_directory.createAdhocRole(
                                               role_name               => lc_role_name
                                              ,role_display_name       => lc_role_display_name
                                              ,email_address           => lc_email_id
                                              ,notification_preference => 'MAILTEXT'
                                               );    
                 END IF;               
              CLOSE lcu_wf_role;        
                                         
              wf_engine.setitemattrtext(
                                         itemtype                =>  'XXMISSHP'
                                        ,itemkey                 =>  lc_item_key
                                        ,aname                   =>  'XX_GI_PERFORMER'
                                        ,avalue                  =>  lc_role_name
                                       );                                        
              wf_engine.setitemattrtext(
                                         itemtype                =>  'XXMISSHP'
                                        ,itemkey                 =>  lc_item_key
                                        ,aname                   =>  'XX_GI_MISSHIP_DETAILS'
                                        ,avalue                  =>  'plsqlclob:xx_gi_misship_comm_pkg.generate_message/'||lc_item_details
                                       );        
              wf_engine.startprocess   (
                                         ItemType                =>  'XXMISSHP'
                                        ,ItemKey                 =>  lc_item_key
                                       );      
              
              COMMIT;
              
          END IF;--IF lc_send_notification = 'S'            
          
     END LOOP;--Looping Twice

EXCEPTION
   WHEN OTHERS THEN
      log_procedure(  p_program_name           => 'send_notification'
                     ,p_error_location         => 'WHEN OTHERS THEN'
                     ,p_error_message_code     =>  SQLCODE
                     ,p_error_message          =>  SUBSTR(SQLERRM,1,240)
                     ,p_error_message_severity =>  'MAJOR'
                     ,p_notify_flag            =>  'Y'
                     ,p_object_id              =>  NULL
                     ,p_attribute1             =>  NULL
                    );

END send_notification;

END XX_GI_MISSHIP_COMM_PKG;
/

SHOW ERRORS;
EXIT