CREATE OR REPLACE
PACKAGE BODY XX_GI_MISSHIP_RECPT_PKG
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                  WIPRO Organization                                            |
-- +================================================================================+
-- | Name        :  XXGIMISSHIPRECPTPKGB.pkb                                        |
-- | Rice Id     :  E0346b_Add-on and Mis-ShipValidation for Receipt                |
-- | Description :  This script creates custom package body required for            |
-- |                Add-on and Mis-ShipValidation for Receipt                       |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author           Remarks                                  |
-- |=======   ==========  =============    ============================             |
-- |DRAFT 1A 16-MAY-2007  Rahul Bagul      Initial draft version                    |
-- |1.0      21-MAY-2007  Rahul Bagul      Baselined after testing                  |
-- |                                                                                |
-- +================================================================================+
AS
-- +================================================================================+
-- | Name        :  MAIN_ADD_SKU_RECPT_PROC                                         |
-- | Description :  This  custom procedure is main procedure and it will call       |
-- |                all other procedures for validations. It also check whether     |
-- |                item exists in item master or not                               |
-- | Parameters  :   x_errbuff,x_retcode                                            |
-- +================================================================================+
   gc_item_type          VARCHAR2(2):='T';
   gc_errbuff            VARCHAR2(100);
   gc_retcode            VARCHAR2(1000);
PROCEDURE MAIN_ADD_SKU_RECPT_PROC(
                                  x_errbuff        OUT  VARCHAR2
                                 ,x_retcode        OUT  VARCHAR2
                                 ,p_email_address  IN   VARCHAR2
                                 ,p_batch_id       IN   NUMBER
)
AS
CURSOR   lcu_rcv_po_dtl_curr
IS
 SELECT  HDR.expected_receipt_date
        ,DTL.quantity
        ,DTL.interface_transaction_id
        ,DTL.item_num
        ,DTL.to_organization_id
        ,DTL.document_num
        ,DTL.vendor_id
        ,DTL.vendor_site_id
        ,DTL.po_header_id
        ,DTL.po_line_id
        ,DTL.header_interface_id
        ,DTL.amount
        ,DTL.document_line_num
        ,DTL.E0342_status_flag
        ,DTL.E0346_status_flag
 FROM    xx_gi_rcv_po_dtl DTL
        ,xx_gi_rcv_po_hdr HDR
 WHERE   HDR.header_interface_id = DTL.header_interface_id
 AND     DTL.E0342_status_flag='E'
 AND     (DTL.E0346_status_flag='N'
         OR DTL.E0346_status_flag IS NULL);
             
--Declare local variables;
ln_interface_transaction_id   NUMBER;
lc_errbuff                    VARCHAR2(100);
lc_retcode                    VARCHAR2(1000);
ln_inventory_item_id          NUMBER;
ln_master_org_id              NUMBER;
             
   BEGIN
       FND_CLIENT_INFO.SET_ORG_CONTEXT(FND_PROFILE.VALUE('org_id'));
       gn_sqlpoint :='10';
       gc_email_address :=p_email_address;
       gc_batch_id      :=p_batch_id;
      -- opening  cursor lcu_rcv_po_dtl_curr
           FOR  lcu_rcv_po_dtl_curr_rec 
           IN lcu_rcv_po_dtl_curr 
           LOOP
           EXIT WHEN lcu_rcv_po_dtl_curr%NOTFOUND;
              gn_sqlpoint :='20';
              gc_status_flag              := 'SUCCESS';
              gn_quantity                 :=lcu_rcv_po_dtl_curr_rec.quantity;
              gn_interface_transaction_id :=lcu_rcv_po_dtl_curr_rec.interface_transaction_id;
              gc_item_num                 :=lcu_rcv_po_dtl_curr_rec.item_num;
              gn_org_id                   :=lcu_rcv_po_dtl_curr_rec.to_organization_id;
              gc_document_num             :=lcu_rcv_po_dtl_curr_rec.document_num;
              gn_vendor_id                :=lcu_rcv_po_dtl_curr_rec.vendor_id;
              gn_vendor_site_id           :=lcu_rcv_po_dtl_curr_rec.vendor_site_id;
              gn_po_header_id             :=lcu_rcv_po_dtl_curr_rec.po_header_id;
              gn_po_line_id               :=lcu_rcv_po_dtl_curr_rec.po_line_id;
              gn_header_interface_id      :=lcu_rcv_po_dtl_curr_rec.header_interface_id;
              gc_e0346_status_flag        :=lcu_rcv_po_dtl_curr_rec.E0346_status_flag;
              gc_e0346_flag               :=lcu_rcv_po_dtl_curr_rec.E0346_status_flag;
              gc_e0342_flag               :=lcu_rcv_po_dtl_curr_rec.E0342_status_flag;
              gd_receipt_date             :=lcu_rcv_po_dtl_curr_rec.expected_receipt_date;
              
              ln_inventory_item_id :=NULL;
                    
              IF gn_vendor_id IS NULL THEN
                 BEGIN
                    SELECT  vendor_id
                           ,vendor_site_id
                    INTO   gn_vendor_id
                          ,gn_vendor_site_id
                    FROM  po_headers_all
                    WHERE po_header_id = gn_po_header_id;
                 EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                    gc_status_flag  := 'ERROR';
                    gc_e0342_flag   := 'VE';
                    gc_e0346_flag   := 'Y';
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'PO '||gc_document_num||' DOES NOT EXISTS'||gn_sqlpoint);
                    x_retcode := SQLCODE;
                    x_errbuff :=SUBSTR (SQLERRM ,1,250);
                    FND_MESSAGE.SET_NAME ('xxptp','XX_GI_MISSHIP_RECEIPT_P001');
                    gc_error_message := FND_MESSAGE.GET;
                    gc_error_message_code :='XX_GI_MISSHIP_RECEIPT_P001';
                    gc_object_id         := gn_interface_transaction_id;
                    gc_object_type       :='Interface_transaction_id';
                    XX_COM_ERROR_LOG_PUB.LOG_ERROR(
                                                    NULL
                                                   ,NULL
                                                   ,'EBS'
                                                   ,'Procedure'
                                                   ,'MAIN_ADD_SKU_RECPT_PROC'
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
                                                   ,SYSDATE
                                                   ,FND_GLOBAL.USER_ID
                                                   ,SYSDATE
                                                   ,FND_GLOBAL.USER_ID
                                                   ,FND_GLOBAL.LOGIN_ID
                    );
                 END;
              END IF;
              IF gc_status_flag ='SUCCESS' THEN
                 BEGIN
                    -- get master inventory org
                   SELECT   master_organization_id
                   INTO     ln_master_org_id
                   FROM     mtl_parameters
                   WHERE    organization_id = gn_org_id;
                   gn_sqlpoint :='30';
                 EXCEPTION
                 WHEN NO_DATA_FOUND  THEN
                    gc_status_flag := 'ERROR';
                    gc_e0342_flag  := 'VE';
                    gc_e0346_flag  := 'Y';
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'master_organization_id does not exists'||gn_sqlpoint);
                    x_retcode := SQLCODE;
                    x_errbuff :=SUBSTR (SQLERRM ,1 ,250);
                    FND_MESSAGE.SET_NAME ('xxptp','XX_GI_MISSHIP_RECEIPT_99999');
                    gc_error_message := FND_MESSAGE.GET;
                    gc_error_message_code :='XX_GI_MISSHIP_RECEIPT_99999';
                    gc_object_id         := gn_interface_transaction_id;
                    gc_object_type       :='Interface_transaction_id';
                    XX_COM_ERROR_LOG_PUB.LOG_ERROR(
                                                   NULL
                                                  ,NULL
                                                  ,'EBS'
                                                  ,'Procedure'
                                                  ,'MAIN_ADD_SKU_RECPT_PROC'
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
                                                  ,SYSDATE
                                                  ,FND_GLOBAL.USER_ID
                                                  ,SYSDATE
                                                  ,FND_GLOBAL.USER_ID
                                                  ,FND_GLOBAL.LOGIN_ID
                    );
                 END;
              END IF;
              IF gc_status_flag = 'SUCCESS' THEN
                  -- check whether item exists in item master or not
                  BEGIN
                    SELECT inventory_item_id
                    INTO   ln_inventory_item_id
                    FROM   mtl_system_items_b
                    WHERE  organization_id = ln_master_org_id
                    AND    segment1        = gc_item_num ;
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      ln_inventory_item_id := NULL;
                    WHEN OTHERS THEN
                      ln_inventory_item_id := NULL;
                  END;
                  gn_inventory_item_id:=ln_inventory_item_id;
                  gn_sqlpoint :='40';
                IF ln_inventory_item_id IS NULL THEN
                    gn_sqlpoint:='40';
                    VAL_UPC_CODE_PROC(
                                      gc_item_num
                                     ,gn_org_id
                                     ,gn_interface_transaction_id
                                     ,ln_master_org_id
                    );
                    gn_sqlpoint:='50';
                ELSE
                    VAL_ITEM_RECEV_ORG_PROC(
                                            gc_item_num
                                           ,gn_org_id
                    );
                  gn_sqlpoint:='60';
                END IF;
              END IF;
              IF gc_status_flag = 'ERROR' THEN
                 gn_sqlpoint :='80';
                 -- Update  error out record in XX_GI_RCV_PO_DTL
                 UPDATE xx_gi_rcv_po_dtl
                 SET    e0342_status_flag = gc_e0342_flag
                       ,e0346_status_flag = gc_e0346_flag
                 WHERE interface_transaction_id =gn_interface_transaction_id;
                 COMMIT;
                 gn_sqlpoint :='90';
              END IF;
           END LOOP; --lcu_rcv_po_dtl_curr_rec
                  -- To send email notification 
                   
                   XX_GI_EXCEPTION_PKG.NOTIFY_PROC (gn_request_id
                                                   ,gc_item_type
                                                   ,gn_interface_transaction_id
                                                   ,gc_email_address
                                                   ,gc_errbuff
                                                   ,gc_retcode
                                                   );

   BEGIN
      INTERORG_ADD_SKU_PROC(
                            lc_retcode
                           ,lc_errbuff
      );
      gn_sqlpoint :='100';
   END INTERORG_ADD_SKU_PROC;
END MAIN_ADD_SKU_RECPT_PROC;
-- check whether item assigned to receiving organization or not
-- +================================================================================+
-- | Name        :  VAL_ITEM_RECEV_ORG_PROC                                         |
-- | Description :  This  procedure will check whether item is available on         |
-- |                receiving organization or not                                   |
-- | Parameters  :   p_item_num,p_org_id                                            |
-- +================================================================================+
PROCEDURE VAL_ITEM_RECEV_ORG_PROC(
                                  p_item_num  IN VARCHAR2
                                 ,p_org_id    IN NUMBER
                                 )
AS
--Declare Local Variables
ln_inventory_item_id  NUMBER;
lc_err_code           VARCHAR2(10);
lc_sqlcode            VARCHAR2(100);
lc_sqlerrm            VARCHAR2(2000);
lc_item_type          VARCHAR2(2):='T';
lc_errbuff            VARCHAR2(100);
lc_retcode            VARCHAR2(1000);
BEGIN
   gn_sqlpoint:='110';
   BEGIN
       SELECT inventory_item_id
       INTO   ln_inventory_item_id
       FROM   mtl_system_items_b
       WHERE  organization_id = p_org_id
       AND    segment1        = p_item_num ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
          ln_inventory_item_id := NULL;
      WHEN OTHERS THEN
          ln_inventory_item_id := NULL;
   END;
   gn_sqlpoint:='120';
   IF ln_inventory_item_id IS NULL THEN
      gc_status_flag := 'ERROR';
      gc_e0342_flag  := 'E';
      gc_e0346_flag  := 'N';
      IF gc_e0346_status_flag IS NULL THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'ITEM NOT ASSIGNED TO RECEIVING ORGANIZATION' );
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'ITEM NUM' ||'    '||'RECEIVING ORG');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gc_item_num ||'    '||gn_org_id);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'----------------------------------------------------------------');
          gn_sqlpoint:='130';
          gn_sqlpoint:='140';
      END IF;
      FND_MESSAGE.SET_NAME ('xxptp', 'XX_GI_MISSHIP_RECEIPT_I001');
      gc_error_message      := FND_MESSAGE.GET;
      gc_error_message_code := 'XX_GI_MISSHIP_RECEIPT_I001';
      gc_object_id          := gn_interface_transaction_id;
      gc_object_type        :='Interface_transaction_id';
      XX_COM_ERROR_LOG_PUB.LOG_ERROR(
                                     NULL
                                    ,NULL
                                    ,'EBS'
                                    ,'Procedure'
                                    ,'VAL_ITEM_RECEV_ORG_PROC'
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
                                    ,SYSDATE
                                    ,FND_GLOBAL.USER_ID
                                    ,SYSDATE
                                    ,FND_GLOBAL.USER_ID
                                    ,FND_GLOBAL.LOGIN_ID
      );
      gn_sqlpoint:='150';
   ELSE
     -- Check whether item and organization both matching with Purchase Order line
     VAL_PO_ITEM_ORG_PROC(
                          ln_inventory_item_id
                         ,gc_document_num
                         ,p_org_id
     );
     gn_sqlpoint:='160';
   END IF;
END VAL_ITEM_RECEV_ORG_PROC;
-- +================================================================================+
-- | Name        :  VAL_UPC_CODE_PROC                                               |
-- | Description :  This  procedure will check whether RTI item matches with the    |
-- |                 UPC code or not.If it matches then then Item num in RTI will   |
-- |                 be replace with this UPC code                                  |
-- | Parameters  :   p_item_num,p_org_id,p_interface_transaction_id,p_master_org_id |
-- +================================================================================+
PROCEDURE VAL_UPC_CODE_PROC(
                            p_item_num                 IN  VARCHAR2
                           ,p_org_id                   IN  NUMBER
                           ,p_interface_transaction_id IN  NUMBER
                           ,p_master_org_id            IN  NUMBER
                           )
AS
---Declare Local Variables
lc_upc     mtl_system_items.segment1%TYPE;
lc_retcode VARCHAR2(100);
lc_errbuff VARCHAR2(1000);
BEGIN
     gn_sqlpoint:='170';
     SELECT MSI.segment1
     INTO   lc_upc
     FROM   mtl_system_items     MSI
           ,mtl_cross_references MCR
     WHERE  MSI.inventory_item_id    = MCR.inventory_item_id
     AND    MSI.organization_id      = p_master_org_id
     AND    MCR.cross_reference_type = 'XX_GI_UPC'
     AND    MCR.cross_reference      = p_item_num;
     UPDATE  xx_gi_rcv_po_dtl
     SET     item_num = lc_upc
     WHERE  interface_transaction_id=p_interface_transaction_id;
     COMMIT;
     gn_sqlpoint:='180';
     --Check whether item exist in the receiving organization or not
     VAL_ITEM_RECEV_ORG_PROC(
                             lc_upc
                            ,p_org_id
                            );
EXCEPTION
     WHEN NO_DATA_FOUND THEN
        --call procedure VAL_VPC_CODE_PROC
        VAL_VPC_CODE_PROC(
                          p_item_num
                         ,p_org_id
                         ,p_interface_transaction_id
                         ,p_master_org_id
        );
END VAL_UPC_CODE_PROC;
-- +================================================================================+
-- | Name        :  VAL_VPC_CODE_PROC                                               |
-- | Description :  This  procedure will check whether RTI item matches with the    |
-- |                 VPC code or not.If it matches then then Item num in RTI will   |
-- |                 be replace with this VPC code                                  |
-- | Parameters  :   p_item_num,p_org_id,p_interface_transaction_id,p_master_org_id |
-- +================================================================================+
PROCEDURE VAL_VPC_CODE_PROC(
                            p_item_num                  IN  VARCHAR2
                           ,p_org_id                    IN  NUMBER
                           ,p_interface_transaction_id  IN  NUMBER
                           ,p_master_org_id             IN  NUMBER
                           )
AS
-- Declare Local variables
ln_inventory_item_id    NUMBER;
lc_item_num             VARCHAR2(81);
lc_sqlcode              VARCHAR2(100);
lc_sqlerrm              VARCHAR2(2000);
lc_errbuff              VARCHAR2(100);
lc_retcode              VARCHAR2(1000);
              
BEGIN
   gn_sqlpoint:='190';
          
   SELECT     MSI.SEGMENT1
   INTO       lc_item_num
   FROM       po_approved_supplier_list ASL
             ,mtl_system_items MSI
   WHERE      ASL.primary_vendor_item = p_item_num
   AND        ASL.item_id = MSI.inventory_item_id
   AND        MSI.organization_id = p_master_org_id;
   gn_sqlpoint:='200';
   UPDATE  xx_gi_rcv_po_dtl
   SET     item_num = lc_item_num
   WHERE  interface_transaction_id=p_interface_transaction_id;
   COMMIT;
   gn_sqlpoint:='210';
   --Check whether item exist in the receiving organization or not
   VAL_ITEM_RECEV_ORG_PROC(
                           lc_item_num
                           ,p_org_id
   );
   gn_sqlpoint:='220';
EXCEPTION
   WHEN NO_DATA_FOUND THEN
     gc_status_flag := 'ERROR';
     gc_e0342_flag  := 'VE';
     gc_e0346_flag  := 'Y';
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Item not exists in item master'||gn_sqlpoint);
     FND_MESSAGE.SET_NAME ('xxptp', 'XX_GI_MISSHIP_RECEIPT_I004');
     gc_error_message := FND_MESSAGE.GET;
     gc_error_message_code :='XX_GI_MISSHIP_RECEIPT_I004';
     gc_object_id         := gn_interface_transaction_id;
     gc_object_type       :='Interface_transaction_id';
     XX_COM_ERROR_LOG_PUB.LOG_ERROR(NULL
                                   ,NULL
                                   ,'EBS'
                                   ,'Procedure Exception'
                                   ,'VAL_VPC_CODE_PROC'
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
                                   ,SYSDATE
                                   ,FND_GLOBAL.USER_ID
                                   ,SYSDATE
                                   ,FND_GLOBAL.USER_ID
                                   ,FND_GLOBAL.LOGIN_ID
     );
END VAL_VPC_CODE_PROC;
-- Procedure to Check whether item and organization both matching with Purchase Order line
-- +================================================================================+
-- | Name        :  VAL_PO_ITEM_ORG_PROC                                            |
-- | Description :  This  procedure will Validate whether item and organization     |
-- |                both matching with Purchase Order line                          |
-- | Parameters  :   p_inventory_item_id,p_document_num,p_org_id                    |
-- +================================================================================+
PROCEDURE VAL_PO_ITEM_ORG_PROC(
                               p_inventory_item_id  IN NUMBER
                              ,p_document_num       IN VARCHAR2
                              ,p_org_id             IN NUMBER
                              )
AS
-- Declare local variables
    ln_quantity     NUMBER;
    lc_sqlcode      VARCHAR2(100);
    lc_sqlerrm      VARCHAR2(2000);
BEGIN
     SELECT  SUM(PLLA.quantity)
     INTO    ln_quantity
     FROM    po_headers_all       PHA
            ,po_lines_all          PLA
            ,po_line_locations_all PLLA
      WHERE  PHA.segment1                 = p_document_num
      AND    PHA.po_header_id             = PLA.po_header_id
      AND    PLA.item_id                  = p_inventory_item_id
      AND    PLA.po_line_id               = PLLA.po_line_id
      AND    PLLA.ship_to_organization_id = p_org_id;
      gn_sqlpoint:='230';
      IF NVL(ln_quantity,0) = 0 THEN
         --Check whether item and vendor are mapped in ASL
         VAL_PO_ITEM_VDR_ASL_PROC(
                                  p_inventory_item_id
                                 ,gn_vendor_id
                                 ,gn_vendor_site_id
                                 ,p_org_id
         );
      ELSIF ln_quantity < gn_quantity THEN
         gc_status_flag := 'ERROR';
         gc_e0342_flag  := 'VE';
         gc_e0346_flag  := 'Y';
      ELSE
         gn_sqlpoint:='210';
         --Check whether PO is open or not
         VAL_PO_OPEN_PROC(
                          gc_document_num
                         ,gn_po_header_id
         );
      END IF;
END VAL_PO_ITEM_ORG_PROC;
-- Validate whether item and vendor are mapped in ASL
-- +================================================================================+
-- | Name        :  VAL_PO_ITEM_VDR_ASL_PROC                                        |
-- | Description :  This  procedure will Validate whether item and vendor are       |
-- |                mapped in ASL                                                   |
-- | Parameters  :  p_inventory_item_id,p_vendor_id,p_vendor_site_id,               |
-- |                p_organization_id                                               |
-- +================================================================================+
PROCEDURE VAL_PO_ITEM_VDR_ASL_PROC(
                                   p_inventory_item_id  IN NUMBER
                                  ,p_vendor_id          IN NUMBER
                                  ,p_vendor_site_id     IN NUMBER
                                  ,p_organization_id    IN NUMBER
                                  )
AS
--Declare local variables
ln_unit_price        NUMBER;
ln_po_header_id      NUMBER;
lc_sqlcode           VARCHAR2(100);
lc_sqlerrm           VARCHAR2(2000);
BEGIN
     gn_sqlpoint:='260';
     SELECT    MAX(PHA.po_header_id)
     INTO      ln_po_header_id
     FROM      po_approved_supplier_list PASL
              ,po_lines_all    PLA
              ,po_headers_all  PHA
     WHERE     PASL.owning_organization_id = p_organization_id
     AND       PASL.item_id = p_inventory_item_id
     AND       PASL.asl_status_id = 2
     AND       PASL.disable_flag IS NULL
     AND       PASL.vendor_id = p_vendor_id
     AND       NVL(PASL.vendor_site_id, p_vendor_site_id) = p_vendor_site_id
     AND       PASL.item_id = PLA.item_id
     AND       PLA.po_header_id =PHA.po_header_id
     AND       PHA.vendor_id = p_vendor_id
     AND       PHA.vendor_site_id = p_vendor_site_id
     AND       PHA.type_lookup_code = 'QUOTATION'
     GROUP BY  PHA.po_header_id;
 
     SELECT  unit_price
     INTO    ln_unit_price 
     FROM    po_lines_all
     WHERE   po_header_id=ln_po_header_id
     AND     item_id=p_inventory_item_id;
     -- If item is available on ASL then it will add new PO line and
     -- auto-approve the PO using custom API  xx_gi_exception_pkg.insert_po_line_proc
     gn_sqlpoint:='270';
     IF gc_e0346_status_flag  IS NULL THEN
         gc_status_flag := 'ERROR';
         gc_e0342_flag  := 'E';
         gc_e0346_flag  := 'N';
         XX_GI_EXCEPTION_PKG.INSERT_PO_LINE_PROC(
                                                 gc_document_num
                                                ,gn_po_header_id
                                                ,gn_org_id
                                                ,gc_item_num
                                                ,'Goods'  -- p_line_type pls check with neeraj to check with PO team
                                                ,gn_quantity
                                                ,ln_unit_price
                                                ,SYSDATE
                                                ,gn_interface_transaction_id
                                                ,gn_inventory_item_id
                                                ,gc_batch_id
         );
         gn_sqlpoint:='271';
     END IF;
EXCEPTION
WHEN NO_DATA_FOUND THEN
    gc_status_flag := 'ERROR';
    gc_e0342_flag  := 'VE';
    gc_e0346_flag  := 'Y';
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid Vendor and item combination in ASL'||gn_sqlpoint);
    FND_MESSAGE.SET_NAME ('xxptp','XX_GI_MISSHIP_RECEIPT_I003');
    gc_error_message      := FND_MESSAGE.GET;
    gc_error_message_code := 'XX_GI_MISSHIP_RECEIPT_I003';
    gc_object_id          := gn_interface_transaction_id;
    gc_object_type        :='Interface_transaction_id';
    XX_COM_ERROR_LOG_PUB.LOG_ERROR(NULL
                                  ,NULL
                                  ,'EBS'
                                  ,'Procedure Body'
                                  ,'VAL_PO_ITEM_VDR_ASL_PROC'
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
                                  ,SYSDATE
                                  ,FND_GLOBAL.USER_ID
                                  ,SYSDATE
                                  ,FND_GLOBAL.USER_ID
                                  ,FND_GLOBAL.LOGIN_ID
    );
END VAL_PO_ITEM_VDR_ASL_PROC;
-- +================================================================================+
-- | Name        :  VAL_PO_OPEN_PROC                                                |
-- | Description :  This  procedure will Validate whether PO is open or not         |
-- | Parameters  :  p_document_num,p_po_header_id                                   |
-- +================================================================================+
PROCEDURE VAL_PO_OPEN_PROC (
                            p_document_num   IN VARCHAR2
                           ,p_po_header_id   IN NUMBER
                           )
AS
--Declare local variable
lc_closed_code  VARCHAR2(25);
lc_sqlcode      VARCHAR2(100);
lc_sqlerrm      VARCHAR2(2000);

BEGIN
    gn_sqlpoint:='300';
    SELECT closed_code
    INTO   lc_closed_code
    FROM   po_headers_all
    WHERE  po_header_id= p_po_header_id;
    gn_sqlpoint:='310';
    IF NVL(lc_closed_code,'OPEN')='OPEN' THEN
       --Check whether PO/INV period is open or not
       VAL_POINVPERIOD_PROC(
                            gn_interface_transaction_id
                           ,gc_document_num
       );
       gn_sqlpoint:='320';
    ELSE
        gc_status_flag := 'ERROR';
        gc_e0342_flag  := 'VE';
        gc_e0346_flag  := 'Y';
        FND_MESSAGE.SET_NAME ('xxptp','XX_GI_MISSHIP_RECEIPT_R001');
        gc_error_message      := FND_MESSAGE.GET;
        gc_error_message_code :='XX_GI_MISSHIP_RECEIPT_R001';
        gc_object_id          := gn_interface_transaction_id;
        gc_object_type        :='Interface_transaction_id';
        XX_COM_ERROR_LOG_PUB.LOG_ERROR(NULL
                                      ,NULL
                                      ,'EBS'
                                      ,'Procedure Body'
                                      ,'VAL_PO_OPEN_PROC'
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
                                      ,SYSDATE
                                      ,FND_GLOBAL.USER_ID
                                      ,SYSDATE
                                      ,FND_GLOBAL.USER_ID
                                      ,FND_GLOBAL.LOGIN_ID
        );
    END IF;
END VAL_PO_OPEN_PROC;
--Check whether PO/INV period is 'OPEN' for that date.
-- +================================================================================+
-- | Name        :  VAL_POINVPERIOD_PROC                                            |
-- | Description :  This  procedure will Validate whether PO/INV period is open     |
-- |                or not                                                          |
-- | Parameters  :  p_interface_transaction_id,p_document_num                       |
-- +================================================================================+
PROCEDURE VAL_POINVPERIOD_PROC(
                               p_interface_transaction_id  IN NUMBER
                              ,p_document_num              IN VARCHAR2
                              )
AS
-- Deaclare local variable
lc_closing_status VARCHAR2(10);
lc_errbuff           VARCHAR2(100);
lc_retcode           VARCHAR2(1000);
BEGIN
    gn_sqlpoint:='330';
    BEGIN
       SELECT STATUS
       INTO   lc_closing_status
       FROM   org_acct_periods_v
       WHERE  organization_id = gn_org_id
       AND    gd_receipt_date BETWEEN start_date AND end_date;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'STATUS NOT FOUND ');
    WHEN OTHERS THEN
      lc_retcode := SQLCODE;
      lc_errbuff :=SUBSTR (SQLERRM ,1 ,250);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Inside  WHEN OTHERS of select status '||lc_retcode||lc_errbuff);
    END;
    IF UPPER(lc_closing_status) ='OPEN' THEN
        UPDATE  xx_gi_rcv_po_dtl
        SET     e0342_status_flag='P'
               ,processing_request_id = NULL
               ,e0346_status_flag = 'Y'
        WHERE  interface_transaction_id= gn_interface_transaction_id;
        COMMIT;
        gn_sqlpoint:='370';
    ELSE
        gc_status_flag := 'ERROR';
        gc_e0342_flag  := 'VE';
        gc_e0346_flag  := 'Y';
        FND_MESSAGE.SET_NAME ('xxptp','XX_GI_MISSHIP_RECEIPT_R001');
        gc_error_message := FND_MESSAGE.GET;
        gc_error_message_code :='XX_GI_MISSHIP_RECEIPT_R001';
        gc_object_id         := gn_interface_transaction_id;
        gc_object_type       :='Interface_transaction_id';
        XX_COM_ERROR_LOG_PUB.LOG_ERROR(NULL
                                      ,NULL
                                      ,'EBS'
                                      ,'Procedure Body'
                                      ,'VAL_POINVPERIOD_PROC'
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
                                      ,SYSDATE
                                      ,FND_GLOBAL.USER_ID
                                      ,SYSDATE
                                      ,FND_GLOBAL.USER_ID
                                      ,FND_GLOBAL.LOGIN_ID
        );
    END IF;
END VAL_POINVPERIOD_PROC;
-- FOR INTERORG
-- +================================================================================+
-- | Name        :  INTERORG_ADD_SKU_PROC                                           |
-- | Description :  This  custom procedure is main procedure and it will call       |
-- |                all other procedures for validations. It also check whether     |
-- |                item exists in item master or not                               |
-- | Parameters  : x_errbuff,x_retcode                                              |
-- +================================================================================+
PROCEDURE INTERORG_ADD_SKU_PROC(
                                x_errbuff OUT VARCHAR2
                               ,x_retcode OUT VARCHAR2
                               )
AS
CURSOR lcu_interorg_curr
IS
SELECT   HDR.expected_receipt_date
        ,DTL.quantity
        ,DTL.interface_transaction_id
        ,DTL.item_num
        ,DTL.to_organization_id
        ,DTL.shipment_num
        ,DTL.header_interface_id
        ,DTL.E0342_status_flag
        ,DTL.E0346_status_flag
 FROM    xx_gi_rcv_str_dtl DTL
        ,xx_gi_rcv_str_hdr HDR
 WHERE   HDR.header_interface_id = DTL.header_interface_id
 AND     DTL.E0342_status_flag='E'
 AND     (DTL.E0346_status_flag='N'
         OR DTL.E0346_status_flag IS NULL);
--Declare local variables;
ln_master_org_id              NUMBER;
ln_inventory_item_id          NUMBER;
ln_interface_transaction_id   NUMBER;
BEGIN
   gn_sqlpoint:='380';
   -- opening  cursor lcu_interorg_curr
   FOR lcu_interorg_curr_rec 
   IN lcu_interorg_curr 
   LOOP
   EXIT WHEN lcu_interorg_curr%NOTFOUND;
   gc_status_flag               := 'SUCCESS';
   gn_quantity                  :=lcu_interorg_curr_rec.quantity;
   gn_interface_transaction_id  :=lcu_interorg_curr_rec.interface_transaction_id;
   gc_item_num                  :=lcu_interorg_curr_rec.item_num;
   gn_org_id                    :=lcu_interorg_curr_rec.to_organization_id;
   gc_document_num              :=lcu_interorg_curr_rec.shipment_num;
   gn_header_interface_id       :=lcu_interorg_curr_rec.header_interface_id;
   gc_e0346_status_flag         :=lcu_interorg_curr_rec.e0346_status_flag;
   gc_e0346_flag                :=lcu_interorg_curr_rec.e0346_status_flag;
   gc_e0342_flag                :=lcu_interorg_curr_rec.e0342_status_flag;
   gd_receipt_date              :=lcu_interorg_curr_rec.expected_receipt_date;
   ln_inventory_item_id :=NULL;
               
   BEGIN
     gn_sqlpoint:='390';
     -- get master inventory org
     SELECT   master_organization_id
     INTO     ln_master_org_id
     FROM     mtl_parameters
     WHERE    organization_id  = gn_org_id;
   EXCEPTION
   WHEN NO_DATA_FOUND  THEN
      gc_status_flag := 'ERROR';
      gc_e0342_flag  := 'VE';
      gc_e0346_flag  := 'Y';
      x_retcode := SQLCODE;
      x_errbuff := SQLERRM;
      FND_MESSAGE.SET_NAME ('xxptp', 'XX_GI_MISSHIP_RECEIPTS_INTERORG_99999');
      gc_error_message      := FND_MESSAGE.GET;
      gc_error_message_code :='XX_GI_MISSHIP_RECEIPTS_INTERORG_99999';
      gc_object_id          := gn_interface_transaction_id;
      gc_object_type        :='Interface_transaction_id';
      XX_COM_ERROR_LOG_PUB.LOG_ERROR(
                                     NULL
                                    ,NULL
                                    ,'EBS'
                                    ,'Procedure Exception'
                                    ,'INTERORG_ADD_SKU_PROC'
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
                                    ,SYSDATE
                                    ,FND_GLOBAL.USER_ID
                                    ,SYSDATE
                                    ,FND_GLOBAL.USER_ID
                                    ,FND_GLOBAL.LOGIN_ID
      );
   END;
   IF gc_status_flag = 'SUCCESS' THEN
      -- check whether item exists in item master or not
      BEGIN
         SELECT inventory_item_id
         INTO ln_inventory_item_id
         FROM mtl_system_items_b
         WHERE organization_id = ln_master_org_id
         AND segment1          = gc_item_num ;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ln_inventory_item_id := NULL;
      WHEN OTHERS THEN
        ln_inventory_item_id := NULL;
      END;
      gn_inventory_item_id:=ln_inventory_item_id;
      gn_sqlpoint:='400';
      IF ln_inventory_item_id IS NULL THEN
         gc_status_flag := 'ERROR';
         gc_e0342_flag  := 'VE';
         gc_e0346_flag  := 'Y';
         x_retcode := SQLCODE;
         x_errbuff := SQLERRM;
         FND_MESSAGE.SET_NAME('xxptp','XX_GI_MISSHIP_RECEIPTS_INTERORG_I004');
         gc_error_message      := FND_MESSAGE.GET;
         gc_error_message_code := 'XX_GI_MISSHIP_RECEIPTS_INTERORG_I004';
         gc_object_id          := gn_interface_transaction_id;
         gc_object_type        :='Interface_transaction_id';
         XX_COM_ERROR_LOG_PUB.LOG_ERROR(
                                         NULL
                                        ,NULL
                                        ,'EBS'
                                        ,'Procedure Body'
                                        ,'INTERORG_ADD_SKU_PROC'
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
                                        ,SYSDATE
                                        ,FND_GLOBAL.USER_ID
                                        ,SYSDATE
                                        ,FND_GLOBAL.USER_ID
                                        ,FND_GLOBAL.LOGIN_ID
         );
      ELSE
         INTERORG_VAL_RECEV_ORG_PROC(
                                     gc_item_num
                                    ,gn_org_id
                                    );
         gn_sqlpoint:='420';
      END IF;
   END IF;
   IF gc_status_flag = 'ERROR' THEN
      gn_sqlpoint :='80';
      -- Update  error out record in XX_GI_RCV_STR_DTL
      UPDATE xx_gi_rcv_str_dtl
      SET    e0342_status_flag = gc_e0342_flag
            ,e0346_status_flag = gc_e0346_flag
      WHERE interface_transaction_id =gn_interface_transaction_id;
      COMMIT;
      gn_sqlpoint :='90';
   END IF;
   END LOOP;-- loop for lcu_interorg_curr_rec
                  -- To send email notification 
                   
                   XX_GI_EXCEPTION_PKG.NOTIFY_PROC (gn_request_id
                                                   ,gc_item_type
                                                   ,gn_interface_transaction_id
                                                   ,gc_email_address
                                                   ,gc_errbuff
                                                   ,gc_retcode
                                                   );

END INTERORG_ADD_SKU_PROC;
-- check whether item assigned to receiving organization or not
-- +================================================================================+
-- | Name        :  INTERORG_VAL_RECEV_ORG_PROC                                     |
-- | Description :  This  procedure will check whether item is available on         |
-- |                receiving organization or not                                   |
-- | Parameters  :  p_item_num ,p_org_id                                            |
-- +================================================================================+
PROCEDURE INTERORG_VAL_RECEV_ORG_PROC(
                                      p_item_num VARCHAR2
                                     ,p_org_id   NUMBER
                                     )
AS
--Declare Local Variables
ln_inventory_item_id  NUMBER;
lc_err_code           VARCHAR2(10);
lc_sqlcode            VARCHAR2 (100);
lc_sqlerrm            VARCHAR2 (2000);
lc_item_type          VARCHAR2(2):='T';
lc_errbuff            VARCHAR2(100);
lc_retcode            VARCHAR2(1000);
BEGIN
   gn_sqlpoint:='430';
   BEGIN
      SELECT inventory_item_id
      INTO ln_inventory_item_id
      FROM mtl_system_items_b
      WHERE organization_id = p_org_id
      AND segment1          = p_item_num ;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
      ln_inventory_item_id := NULL;
   WHEN OTHERS THEN
      ln_inventory_item_id := NULL;
   END;
   IF ln_inventory_item_id IS NULL  THEN
      gc_status_flag := 'ERROR';
      gc_e0342_flag  := 'E';
      gc_e0346_flag  := 'N';
      IF gc_e0346_status_flag IS NULL THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'ITEM NOT ASSIGNED TO RECEIVING ORGANIZATION' );
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'ITEM NUM' ||'    '||'RECEVING ORG');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gc_item_num ||'    '||gn_org_id);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'----------------------------------------------------------------');
          gn_sqlpoint:='440';
      END IF;
      lc_sqlcode := SQLCODE;
      lc_sqlerrm :=SUBSTR (SQLERRM ,1 ,250);
      FND_MESSAGE.SET_NAME ('xxptp', 'XX_GI_MISSHIP_RECEIPTS_I001');
      gc_error_message := FND_MESSAGE.GET||lc_sqlcode||lc_sqlerrm;
      gc_error_message_code := 'XX_GI_MISSHIP_RECEIPTS_I001'; 
      gc_object_id         := gn_interface_transaction_id;
      gc_object_type       :='Interface_transaction_id';
      XX_COM_ERROR_LOG_PUB.LOG_ERROR(
                                     NULL
                                     ,NULL
                                     ,'EBS'
                                     ,'Procedure Body'
                                     ,'VAL_ITEM_RECEV_ORG_PROC'
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
                                     ,SYSDATE
                                     ,FND_GLOBAL.USER_ID
                                     ,SYSDATE
                                     ,FND_GLOBAL.USER_ID
                                     ,FND_GLOBAL.LOGIN_ID
      );
   ELSE
      UPDATE  xx_gi_rcv_str_dtl
      SET     e0342_status_flag='P'
             ,e0346_status_flag='Y'
      WHERE   interface_transaction_id= gn_interface_transaction_id;
      COMMIT;
   END IF;
END INTERORG_VAL_RECEV_ORG_PROC;

END XX_GI_MISSHIP_RECPT_PKG;
/

SHOW ERROR