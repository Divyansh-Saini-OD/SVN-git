SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET FEEDBACK     OFF
SET TAB          OFF
SET TERM         ON
SET AUTOCOMMIT   ON
PROMPT 'Creating Package Body  - XX_GI_RCV_STR_PKG'
  
CREATE OR REPLACE PACKAGE BODY XX_GI_RCV_STR_PKG  
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : XX_GI_RCV_STR_PKG                                   |
-- | Description : To convert the 'GI InterOrg RECEIPTS' that are fully|
-- |               received as well as partially received              |
-- |               from the OD Legacy system to Oracle EBS.            |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       18-MAY-2007  Thilak Daniel         Initial version       |
-- |1.1       12-JUN-2007  Thilak Daniel    Added mmt attr5 for Shipnum|
-- |1.2       27-JUN-2007  Thilak Daniel    Changed to custom exception|
-- |1.3       17-JUL-2007  Thilak Daniel   Used for rowid in table type|
--                                            to improve performance   |
-- +===================================================================+
AS
-- +===================================================================+
-- | Name          : XX_GI_VAL_ASSDET_STR_RCV                          |
-- | Description   : This is the procedure which is used to perform    |
-- |                  assumed/detailed validation.                     |
-- |               Concurrent program  Name is                         |
-- |    "OD : Inventory Assumed-Detailed Receipts Validation Program"  |
-- | Parameters     : x_err_buf,x_ret_code                             |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE  XX_GI_VAL_ASSDET_STR_RCV (x_err_buf  OUT VARCHAR2
                                        ,x_ret_code OUT NUMBER
                                       )
   AS
   ln_conc_request_id                  NUMBER; 
   lc_assumed_detail_flag              VARCHAR2(1);
   lc_attribute7                       VARCHAR2(1); -- Org level Assumed Detail flag
   lc_to_org_consgn_flag               VARCHAR2(1); --  To Org Consignment flag
   lc_from_org_consgn_flag             VARCHAR2(1); --  From Org Consignment flag
   ln_to_organization_id               NUMBER;
   lc_fr_organization_id               NUMBER;
   ln_count_flag                       NUMBER;  -- flag used to check Item Assumed Detail Validation for all lines
   lc_shipment_number                  VARCHAR2(30);
   lc_sqlcode                          VARCHAR2(20);
   lc_sqlerrm                          VARCHAR2(250);
   lc_error_msg                        VARCHAR2(2000);
  
-- +======================================================================+
-- |   cursor to fetch all HEADER only records to insert lines from mmtl  |
-- +======================================================================+
   CURSOR lcu_str_hdr_curr 
   IS
   SELECT   --+FIRST_ROWS
          XGRSH.ship_to_organization_code
          ,XGRSH.shipment_num
          ,XGRSH.header_interface_id
          ,XGRSH.group_id
          ,XGRSH.ship_to_organization_id
          ,XGRSH.attribute8
   FROM   xx_gi_rcv_str_hdr  XGRSH
   WHERE  e0342_status_flag ='POL' 
   AND    NOT EXISTS(
                     SELECT 1 
                     FROM xx_gi_rcv_str_dtl XGRSD 
                     WHERE XGRSH.header_interface_id = XGRSD.header_interface_id
                    ); 
                                                                                       
-- +======================================================================+
-- |   cursor to fetch shipment details for given shipment number         |
-- +======================================================================+
   CURSOR lcu_ship_dtl_curr(
                            p_shipment_num VARCHAR2
                           ,p_to_organization_id NUMBER
                           )
   IS
   SELECT SUM(ABS(transaction_quantity))
          ,shipment_number
          ,inventory_item_id 
          ,organization_id 
          ,transfer_organization_id
   FROM  mtl_material_transactions
   WHERE shipment_number          = p_shipment_num  -- EBS shipment Number fetched by P1 program 
   AND   transfer_organization_id =p_to_organization_id
   AND   transaction_type_id =
                              (
                               SELECT  transaction_type_id 
                               FROM    mtl_transaction_types 
                               WHERE   UPPER(transaction_type_name) = UPPER('Intransit Shipment')
                               AND     disable_date IS NULL
                           )
   GROUP BY shipment_number
            ,inventory_item_id
            ,organization_id
            ,transfer_organization_id;
                                                                                       
-- +====================================================================== ============+
 --  cursor to fetch all records having both HEADER and LINES with initial POL status  |
-- +====================================================================== ============+
   CURSOR lcu_str_dtl_curr
   IS 
   SELECT  --+FIRST_ROWS 
          XGRSD.ROWID
          ,XGRSD.item_num
          ,XGRSD.item_id
          ,XGRSD.from_organization_code
          ,XGRSD.to_organization_code
          ,XGRSD.interface_transaction_id
          ,XGRSD.shipment_num
   FROM   xx_gi_rcv_str_hdr  XGRSH
          ,xx_gi_rcv_str_dtl XGRSD 
   WHERE  XGRSH.header_interface_id = XGRSD.header_interface_id
   AND    XGRSD.e0342_status_flag   = 'POL';

   TYPE lcu_str_dtl_curr_tbl IS TABLE OF lcu_str_dtl_curr%ROWTYPE
   INDEX BY BINARY_INTEGER;
                                         
   lcu_str_dtl_curr_rec  lcu_str_dtl_curr_tbl;
                                                                                       
   BEGIN
    FND_FILE.PUT_LINE(FND_FILE.LOG
         ,'===========================================================================');
           ---- Assumed detailed check for only HDR without DTL records---------------   
                                                                                         
      FND_FILE.PUT_LINE(FND_FILE.LOG
                 ,'        Procedure to check Assumed Detailed Validation  Started');
-- +======================================================================+
-- |   open  HEADER only record cursor  and do assumed detail validation  |
-- +======================================================================+
   FOR lcu_str_hdr_curr_rec 
     IN lcu_str_hdr_curr
   LOOP
     -- Org level Assumed Detail Validation
       lc_error_msg         := NULL;
       lc_attribute7        := NULL;
       ln_to_organization_id:= NULL;
       lc_fr_organization_id:= NULL;
       lc_shipment_number   := NULL;
       ln_count_flag        := 0; 
     BEGIN
-- +=================================================================+++++++==+
-- |         ASSUMED  DETAILED   VALIDATION  AT  ORG  LEVEL                   |
-- |              BY PASSING   ORGANIZATION_CODE                              |
-- +==========================================================================+
       BEGIN
         SELECT attribute7
               ,organization_id
         INTO   lc_attribute7
               ,ln_to_organization_id
         FROM   mtl_parameters 
         WHERE  organization_code = LTRIM(RTRIM(lcu_str_hdr_curr_rec.ship_to_organization_code));
                                                 
         FND_FILE.PUT_LINE (FND_FILE.LOG,'ATTRIBUTE7 :'|| lc_attribute7);
         FND_FILE.PUT_LINE (FND_FILE.LOG,'ship_to_organization_id :'||ln_to_organization_id);
       EXCEPTION
         WHEN OTHERS THEN
-- +======================================================================+
-- |   Capturing error into error tables using exception pkg              |
-- +======================================================================+
           lc_sqlerrm := SUBSTR (SQLERRM
                                ,1
                                ,200
                                );
           lc_error_msg :=lc_sqlerrm;
           XX_GI_RCV_ERR_PKG.XX_GI_INS_CUST_EXCEP(
                                                  'STR1_ORG_ASS_DET'
                                                  ,'HEADER_INTERFACE_ID'
                                                  ,lcu_str_hdr_curr_rec.header_interface_id
                                                  ,lc_error_msg
                                                  ,'XX_GI_ST1'
           );
       END; 
                                      
        -- Item level Assumed Detail Validation
           IF NVL(lc_attribute7,'X') = 'A' THEN
            ln_count_flag := 0;
           FND_FILE.PUT_LINE (FND_FILE.LOG,'Shipment_num :'||lcu_str_hdr_curr_rec.shipment_num ||
                                           ' ln_to_organization_id : '||ln_to_organization_id);
             FOR lcu_ship_dtl_curr_rec 
                  IN lcu_ship_dtl_curr(
                                       lcu_str_hdr_curr_rec.shipment_num
                                       ,ln_to_organization_id
                                      )
             LOOP
               lc_assumed_detail_flag := NULL;
               FND_FILE.PUT_LINE (FND_FILE.LOG,'Item level shipment_num :'||lcu_str_hdr_curr_rec.shipment_num 
                                                                          ||ln_to_organization_id);
               FND_FILE.PUT_LINE (FND_FILE.LOG,'Item ID :'||lcu_ship_dtl_curr_rec.inventory_item_id);
-- +=================================================================+++++++==+
-- |         ASSUMED  DETAILED   VALIDATION  AT  ITEM  LEVEL                  | 
-- |       BY PASSING  INVENTORY_ITEM_ID AND  TO  ORGANIZATION_ID             |
-- +==========================================================================+
               BEGIN
                 SELECT  attribute15
                 INTO    lc_assumed_detail_flag
                 FROM    mtl_system_items_b 
                 WHERE   mtl_transactions_enabled_flag = 'Y' 
                 AND     enabled_flag = 'Y'
                 AND     inventory_item_status_code IN ('Active','A')
                 AND     SYSDATE BETWEEN NVL (start_date_active, SYSDATE) AND NVL (end_date_active, SYSDATE)
                 AND     inventory_item_id = lcu_ship_dtl_curr_rec.inventory_item_id
                 AND     organization_id   = ln_to_organization_id;
                                                                
                  FND_FILE.PUT_LINE (FND_FILE.LOG,'mtl_system_items_b  Flag:'|| lc_assumed_detail_flag);
               EXCEPTION
                 WHEN OTHERS THEN
-- +======================================================================+
-- |   Capturing error into error table  using exception pkg              |
-- +======================================================================+
                 lc_sqlerrm := SUBSTR (SQLERRM
                                       ,1
                                       ,200
                                      );
                 lc_assumed_detail_flag:='B';
                 lc_error_msg:=  lc_sqlerrm;
                 FND_FILE.PUT_LINE (FND_FILE.LOG,'Item level Assumed Detail Validation Err :'||lc_error_msg);
                 gc_err_code := 'XX_GI_ST001';
                 gc_err_desc := 'Item level Assumed Detail Validation Err : '||lc_error_msg; 
                 XX_GI_RCV_ERR_PKG.XX_GI_INS_CUST_EXCEP( 
                                                        gc_err_code
                                                        ,'HEADER_INTERFACE_ID'
                                                        ,lcu_str_hdr_curr_rec.header_interface_id
                                                        ,gc_err_desc
                                                        ,'XX_GI_ST1'
                 );
               END;
                 lc_shipment_number := lcu_ship_dtl_curr_rec.shipment_number;
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Shipment_Number : '||lc_shipment_number);
                 IF NVL(lc_assumed_detail_flag,'X') <>'A' THEN
-- +======================================================================+
-- |   Check for Assumed detail flag for all lines one by one              |
-- +======================================================================+
                   ln_count_flag      :=1; 
                   lc_shipment_number :=NULL; 
                   FND_FILE.PUT_LINE (FND_FILE.LOG,'Item Assumed Detail flag is not unique:'
                                                    ||lc_sqlerrm||'Flag is :'||lc_assumed_detail_flag);
                   EXIT;
                 END IF;
             END LOOP;  --    lcu_ship_dtl_curr
                FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_count_flag value is :'||ln_count_flag);
              -- All records from shipment lines are in assumed status 
              IF ln_count_flag = 0 THEN
-- +======================================================================+
-- |  Check for Assumed detail flag sucess at all lines for a header      |
-- +======================================================================+
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Before Insert in Assumed Detailed Validation');
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Shipment_Number :'||lc_shipment_number||' : '
                                                ||ln_to_organization_id);
               BEGIN
-- +====================================================================== ============+
--  INSERT  LINE RECORDS FOR validated HDR only record                                 |
-- +====================================================================== ============+
                INSERT     --+APPEND
                INTO xx_gi_rcv_str_dtl (
                                        interface_transaction_id
                                       ,group_id
                                       ,last_update_date
                                       ,last_updated_by 
                                       ,creation_date
                                       ,created_by
                                       ,last_update_login
                                       ,transaction_type
                                       ,transaction_date
                                       ,processing_status_code
                                       ,processing_mode_code
                                       ,transaction_status_code
                                       ,quantity
                                       ,unit_of_measure
                                       ,item_id
                                       ,item_description
                                       ,item_revision
                        --               ,uom_code  -- no such column to map
                                       ,auto_transact_code
                                       ,shipment_header_id
                                       ,shipment_line_id
                                       ,ship_to_location_id
                                       ,primary_quantity
                                       ,primary_unit_of_measure
                                       ,from_organization_id
                                       ,from_subinventory
                                       ,to_organization_id
                                       ,source_document_code
                                       ,e0342_status_flag 
                                       ,header_interface_id
                                       ,from_organization_code -- get_organization_code
                                       ,to_organization_code   -- get_organization_code
                                       ,shipment_num
                                       ,item_num
                                       ,attribute4
                                       ,attribute8
                                       ,subinventory
                                       ,expected_receipt_date
                                      )
                                       SELECT
                                        rcv_transactions_interface_s.NEXTVAL
                                       ,lcu_str_hdr_curr_rec.group_id -- rcv_interface_groups_s
                                       ,SYSDATE
                                       ,FND_GLOBAL.USER_ID
                                       ,SYSDATE
                                       ,FND_GLOBAL.USER_ID
                                       ,FND_GLOBAL.LOGIN_ID
                                       ,'NEW'  --transaction_type
                                       ,NULL   --transaction_date
                                       ,'PENDING' --processing_status_code
                                       ,'BATCH'  -- processing_mode_code
                                       ,'PENDING'  -- transaction_status_code
                                       ,RSL.quantity_shipped -- quantity
                                       ,RSL.unit_of_measure
                                       ,RSL.item_id
                                       ,RSL.item_description
                                       ,RSL.item_revision
                       --              ,RSL.uom_code   -- uom_code
                                       ,NULL   -- auto_transact_code
                                       ,RSL.shipment_header_id --shipment_header_id
                                       ,RSL.shipment_line_id  -- shipment_line_id
                                       ,RSL.deliver_to_location_id --ship_to_location_id 
                                       ,RSL.quantity_shipped    -- primary_quantity
                                       ,RSL.unit_of_measure     --primary_unit_of_measure
                                       ,RSL.from_organization_id -- FROM_ORGANIZATION_ID
                                       ,NULL  --from_subinventory                      
                                       ,RSL.to_organization_id                    
                                       ,NULL  --source_document_code                   
                                       ,'POL'
                                       ,lcu_str_hdr_curr_rec.header_interface_id 
                                       ,GET_ORGANIZATION_CODE(RSL.from_organization_id)
                                       ,GET_ORGANIZATION_CODE(RSL.to_organization_id)
                                       ,lcu_str_hdr_curr_rec.shipment_num
                                       ,GET_ITEM_CODE(RSL.item_id,RSL.to_organization_id)
                                       ,'OHDR'
                                       ,lcu_str_hdr_curr_rec.attribute8
                                       ,RSL.to_subinventory
                                       ,SYSDATE 
                                      FROM  rcv_shipment_lines RSL
                                            ,rcv_shipment_headers RSH
                                      WHERE RSL.shipment_header_id        = RSH.shipment_header_id
                                      AND   RSL.shipment_line_status_code ='EXPECTED' --'PARTIALLY RECEIVED'
                                      AND   RSH.shipment_num              = lc_shipment_number
                                      AND   RSL.to_organization_id        = ln_to_organization_id;
                COMMIT;
                 FND_FILE.PUT_LINE (FND_FILE.LOG,'After Insert in Assumed Detailed Validation');
               EXCEPTION
                WHEN OTHERS THEN
                 lc_sqlcode := SQLCODE;
                 lc_sqlerrm := SUBSTR (SQLERRM
                                       ,1
                                       ,200
                                      );
                 lc_error_msg:=lc_sqlerrm;
                 FND_FILE.PUT_LINE (FND_FILE.LOG,'After Insert Excep :'||lc_error_msg);
                 FND_FILE.PUT_LINE (FND_FILE.LOG,'Shipment_Num Err :'||lc_shipment_number
                                                 ||' : '||ln_to_organization_id);
-- +======================================================================+
-- |   Capturing error into error table  using exception pkg              |
-- +======================================================================+
                 XX_GI_RCV_ERR_PKG.XX_GI_INS_CUST_EXCEP(
                                                        'STR1_INS_OTHERS'
                                                        ,'HEADER_INTERFACE_ID'
                                                        ,lcu_str_hdr_curr_rec.header_interface_id
                                                        ,lc_error_msg
                                                        ,'XX_GI_ST1'
                 );
               END;
              END IF;
              COMMIT;
           ELSE
           FND_FILE.PUT_LINE (FND_FILE.LOG,'Shipment_Num :'||lcu_str_hdr_curr_rec.shipment_num||' : '
                                                           ||' has no valid Lines');
           END IF;
     EXCEPTION
       WHEN OTHERS THEN
         lc_sqlerrm := SUBSTR (SQLERRM
                               ,1
                               ,200
                              );
         lc_error_msg := lc_sqlerrm;
-- +======================================================================+
-- |   Capturing error into error table  using exception pkg              |
-- +======================================================================+
         XX_GI_RCV_ERR_PKG.XX_GI_INS_CUST_EXCEP(
                                                'STR1_OTHERS'
                                                ,'HEADER_INTERFACE_ID'
                                                ,lcu_str_hdr_curr_rec.header_interface_id
                                                ,lc_error_msg
                                                ,'XX_GI_ST1'
         );
         FND_FILE.PUT_LINE (FND_FILE.LOG,'Org level Assumed Detail Validation Err '|| lc_error_msg);
     END;              
-- +======================================================================+
-- |   ASSUMED DETAIL  VALIDATION STARTS HERE                             |
-- +======================================================================+
   END LOOP; -- lcu_str_hdr_curr
                                                   
      FND_FILE.PUT_LINE(FND_FILE.LOG,'     Procedure to check Assumed Detailed Validation  Completed');
-- +======================================================================+
-- |   CONSIGNMENT VALIDATION STARTS HERE                                 |
-- +======================================================================+
    BEGIN
   -- open all line records with initial POL status 
       OPEN  lcu_str_dtl_curr;
       FETCH lcu_str_dtl_curr 
       BULK COLLECT INTO lcu_str_dtl_curr_rec;
       FOR i 
          IN 1..lcu_str_dtl_curr_rec.COUNT
     LOOP
                                                                                              
-- +=================================================================+++++++==+
-- |                  CONSIGNMENT  VALIDATION  CHECK                          |
-- |       BY PASSING  INVENTORY_ITEM_NUM AND  FROM ORGANIZATION_CODE         |
-- +==========================================================================+
       BEGIN
          SELECT pvs.attribute15 
          INTO   lc_from_org_consgn_flag
          FROM   po_approved_supplier_list PASL
                ,po_vendor_sites_all PVS
                ,mtl_system_items MSI
                ,mtl_parameters MP
          WHERE MSI.inventory_item_id                       = PASL.item_id
          AND   MSI.organization_id                         = PASL.owning_organization_id
          AND   PVS.vendor_id                               = PASL.vendor_id
          AND   NVL(PASL.vendor_site_id,PVS.vendor_site_id) = PVS.vendor_site_id
          AND   PASL.owning_organization_id                 = MP.organization_id
          AND   UPPER(PASL.attribute15)                     = UPPER('Primary Vendor')
          AND   MSI.segment1                                = lcu_str_dtl_curr_rec(i).item_num
          AND   MP.organization_code                        = lcu_str_dtl_curr_rec(i).from_organization_code;
                 FND_FILE.PUT_LINE (FND_FILE.LOG,'Item NUM and ID'||lcu_str_dtl_curr_rec(i).item_num||
                                                 lcu_str_dtl_curr_rec(i).item_id||'From Org Code :'||
                                                 'From Org :'||lcu_str_dtl_curr_rec(i).from_organization_code);
       EXCEPTION
         WHEN OTHERS THEN
-- +====================================================================================+
-- |   Capturing CONSIGNMENT error into error table  using exception pkg FOR FROM ORG   |
-- +====================================================================================+
                 lc_from_org_consgn_flag:='B';
                 lc_sqlcode  := SQLCODE;
                 lc_sqlerrm  := SUBSTR (SQLERRM
                                       ,1
                                       ,200
                                      );
                 lc_error_msg:= ('Item Name :'||lcu_str_dtl_curr_rec(i).item_num||
                                 'Org Code :'||lcu_str_dtl_curr_rec(i).from_organization_code||' :'||
                                  lc_sqlerrm);
                 FND_FILE.PUT_LINE (FND_FILE.LOG,'Item level Consignment Validation From Org Err :'
                                   ||'Item Name :'||lcu_str_dtl_curr_rec(i).item_num
                                   ||'Org Code :'||lcu_str_dtl_curr_rec(i).from_organization_code||lc_error_msg);
                 gc_err_code := 'XX_GI_ST001';
                 gc_err_desc := 'Item level Consignment From Org Err : '||lc_error_msg; 
                 XX_GI_RCV_ERR_PKG.XX_GI_INS_CUST_EXCEP( 
                                                        gc_err_code
                                                        ,'INTERFACE_TRANSACTION_ID'
                                                        ,lcu_str_dtl_curr_rec(i).interface_transaction_id
                                                        ,gc_err_desc
                                                        ,'XX_GI_ST1'
                 );
       END;
                                                                                                         
-- +=================================================================+++++++==+
-- |                  CONSIGNMENT  VALIDATION  CHECK                          |
-- |       BY PASSING  INVENTORY_ITEM_NUM AND  TO ORGANIZATION_CODE           |
-- +==========================================================================+
       BEGIN
         SELECT pvs.attribute15
         INTO   lc_to_org_consgn_flag
         FROM   po_approved_supplier_list PASL
               ,po_vendor_sites_all PVS
               ,mtl_system_items MSI
               ,mtl_parameters MP 
         WHERE MSI.inventory_item_id                       = PASL.item_id
         AND   MSI.organization_id                         = PASL.owning_organization_id
         AND   PVS.vendor_id                               = PASL.vendor_id
         AND   NVL(PASL.vendor_site_id,PVS.vendor_site_id) = PVS.vendor_site_id
         AND   PASL.owning_organization_id                 = MP.organization_id
         AND   UPPER(PASL.attribute15)                     = UPPER('Primary Vendor')
          AND  MSI.segment1                                = lcu_str_dtl_curr_rec(i).item_num
         AND   MP.organization_code                        = lcu_str_dtl_curr_rec(i).to_organization_code;
                 FND_FILE.PUT_LINE (FND_FILE.LOG,'Item NUM and ID'||lcu_str_dtl_curr_rec(i).item_num||
                                                 lcu_str_dtl_curr_rec(i).item_id||'To Org Code :'||
                                                 lcu_str_dtl_curr_rec(i).to_organization_code);
       EXCEPTION
          WHEN OTHERS THEN
-- +====================================================================================+
-- |   Capturing CONSIGNMENT error into error table  using exception pkg FOR TO ORG     |
-- +====================================================================================+
                 lc_to_org_consgn_flag:='C';
                 lc_sqlerrm := SUBSTR (SQLERRM
                                       ,1
                                       ,200
                                      );
                 lc_error_msg:= ('Item Name :'||lcu_str_dtl_curr_rec(i).item_num||
                                 'Org Code :'||lcu_str_dtl_curr_rec(i).from_organization_code||' :'||
                                 lc_sqlerrm);
                 FND_FILE.PUT_LINE (FND_FILE.LOG,'Consignment Validation To Org Err :'||lc_error_msg);
                 gc_err_code := 'XX_GI_ST001';
                 gc_err_desc := 'Item level Consignment To Org Err : '||lc_error_msg; 
                 XX_GI_RCV_ERR_PKG.XX_GI_INS_CUST_EXCEP( 
                                                        gc_err_code
                                                        ,'INTERFACE_TRANSACTION_ID'
                                                        ,lcu_str_dtl_curr_rec(i).interface_transaction_id
                                                        ,gc_err_desc
                                                        ,'XX_GI_ST1'
                 );
       END;
-- +======================================================================+
-- |   CONSIGNMENT VALIDATION ENDS   HERE                                 |
-- +======================================================================+
       FND_FILE.PUT_LINE(FND_FILE.LOG,'To_Org_consignment Flag :'||lc_to_org_consgn_flag ||
                                      ' From_Org_consignment Flag :'||lc_from_org_consgn_flag);
                                                                          
          IF NVL(lc_to_org_consgn_flag,'X')= NVL(lc_from_org_consgn_flag,'X') THEN  
-- +======================================================================+
-- |   STATUS FLAG UPDATION USING CONSIGNMENT FLAGS                       |
-- +======================================================================+
            UPDATE xx_gi_rcv_str_dtl XGRSD
            SET    XGRSD.e0342_status_flag  = 'POD'
            WHERE  XGRSD.e0342_status_flag  = 'POL'
            AND    interface_transaction_id = lcu_str_dtl_curr_rec(i).interface_transaction_id; 
          ELSE
            UPDATE xx_gi_rcv_str_dtl XGRSD
            SET    XGRSD.e0342_status_flag  = 'VE'
            WHERE  XGRSD.e0342_status_flag  = 'POL'
            AND    interface_transaction_id = lcu_str_dtl_curr_rec(i).interface_transaction_id; 
                                             
             gc_err_desc := 'Consignment Validation Error :'||lc_error_msg;
             XX_GI_RCV_ERR_PKG.XX_GI_INS_CUST_EXCEP (
                                                     'XX_GI_ST001'
                                                     ,'INTERFACE_TRANSACTION_ID'
                                                     ,lcu_str_dtl_curr_rec(i).interface_transaction_id
                                                     ,gc_err_desc
                                                     ,'XX_GI_ST1'
             );
          END IF;
     END LOOP;
     COMMIT; 
    END;
   END XX_GI_VAL_ASSDET_STR_RCV;
-------------------------------------------------------------------------------------------------
-- +===================================================================+
-- |Name            : XX_GI_VAL_STR_RCV                                |
-- |Description     : This is the procedure which is used to perform   |
-- |                   Store Transfer Receipts Validation includes     |
-- |                        shortage and overage cases                 |
-- |               Concurrent program  Name is                         |
-- |    "OD: Inventory Store Transfer Receipts Validation Program"     |
-- |Parameters      : x_err_buf,x_ret_code                             |
-- |                                                                   |
-- +===================================================================+
  PROCEDURE XX_GI_VAL_STR_RCV (x_err_buf  OUT VARCHAR2
                               ,x_ret_code OUT NUMBER
                              )
   AS
                                                                                              
     lt_mtl_line_rec_type   mtl_material_transactions%ROWTYPE;
     ln_end_of_day          NUMBER; -- varable used to store end of day value 
     ln_commit_cnt          NUMBER;
     lc_attr8               mtl_material_transactions.attribute8%TYPE :=NULL;
     lc_dummy_attr8         mtl_material_transactions.attribute8%TYPE :=NULL;
     lc_receipt_num         VARCHAR2(150);
     lc_keyrec              VARCHAR2(150);
     lc_rowid               VARCHAR2(150);
     lc_meaning             VARCHAR2(50);
     ln_rec_nex_id          NUMBER;
     lc_attribute8          VARCHAR2(150);
     lc_attribute8_curr     VARCHAR2(150);
     lc_sqlcode             NUMBER;
     lc_sqlerrm             VARCHAR2 (2000);
     lc_error_message       VARCHAR2 (1000);
     ln_transaction_qty     NUMBER;
     lc_shipment_number     VARCHAR2 (30);
     ln_inventory_item_id   NUMBER;
     ln_organization_id     NUMBER;
     ln_transfer_org_id     NUMBER;
  -- variable used to do specific set of validation esp to include 'OHDS' records
     ln_ohds_flag           NUMBER :=0;   
  -- variable used to	check whetehr 'STRDL' records entered into base table or not 
     ln_strdl_flag           NUMBER :=0;
     ln_transaction_id       NUMBER :=0;
                                                        
        -- Define cursor with various statusses   
-- +======================================================================+
-- | Cursor to fetch all lines with 'POD' status to process               |
-- +======================================================================+

   CURSOR lcu_dtl_podc_curr
   IS 
   SELECT ROWID     --+FIRST_ROWS
          ,group_id
          ,last_update_date
          ,last_updated_by
          ,creation_date
          ,created_by
          ,last_update_login
          ,transaction_type
          ,transaction_date
          ,processing_status_code	
          ,transaction_status_code
          ,unit_of_measure
          ,item_description
          ,item_revision
          ,uom_code
          ,auto_transact_code
          ,shipment_header_id
          ,shipment_line_id
          ,ship_to_location_id
          ,from_subinventory
          ,subinventory
          ,shipment_num
          ,expected_receipt_date
          ,item_num          -- sku 
          ,to_organization_id
          ,from_organization_id
          ,attribute1
          ,attribute2
          ,attribute3
          ,attribute4   -- txn type
          ,attribute5    -- shipment number
          ,attribute6
          ,attribute7
          ,attribute8   -- keyrec number
          ,quantity
          ,item_id
          ,from_organization_code
          ,to_organization_code
          ,e0342_status_flag
          ,e0342_first_rec_time
          ,header_interface_id
          ,interface_transaction_id
          ,processing_mode_code
   FROM   xx_gi_rcv_str_dtl  
   WHERE  e0342_status_flag ='POD'
   AND    attribute4        IN ('OHDR','RVSC')
   ORDER BY shipment_num;
   --   BULK COLLECT
                                          
   TYPE lcu_dtl_podc_curr_tbl IS TABLE OF lcu_dtl_podc_curr%ROWTYPE
   INDEX BY BINARY_INTEGER;
                                         
   lcu_dtl_podc_curr_rec  lcu_dtl_podc_curr_tbl;
                                        
-- +====================================================================================+
-- | Cursor to fetch all shortage qty records with 'W' status for end of day validation |
-- +====================================================================================+
   CURSOR lcu_dtl_w_curr
   IS 
   SELECT  interface_transaction_id
          ,e0342_status_flag
          ,subinventory
          ,quantity
          ,e0342_first_rec_time
   FROM  xx_gi_rcv_str_dtl 
   WHERE e0342_status_flag ='W' 
   AND   attribute4        ='OHDS'
   ORDER BY shipment_num
   FOR UPDATE OF e0342_status_flag,subinventory,quantity,attribute4;
                                                 
-- +====================================================================================+
-- |Cursor to fetch all shortage qty records with 'STRD' status for direct org transfer |
-- +====================================================================================+
   CURSOR lcu_dtl_strd_curr
   IS 
   SELECT item_num
          ,item_id
          ,quantity
          ,to_organization_id
          ,from_organization_id
          ,from_subinventory
          ,subinventory
          ,unit_of_measure
          ,header_interface_id
          ,interface_transaction_id
          ,attribute4
          ,attribute8
          ,e0342_status_flag 
          ,shipment_num
          ,uom_code
   FROM   xx_gi_rcv_str_dtl 
   WHERE  e0342_status_flag ='STRD'
   AND    attribute4        IN ('OHDR','OHRE','OHDS')
   FOR UPDATE OF e0342_status_flag,subinventory,quantity,attribute4;
                           
-- +====================================================================================+
-- |Cursor to fetch all overage qty records with 'STR' status for Intransit transfer    |
-- +====================================================================================+
   CURSOR lcu_dtl_str_curr
   IS 
   SELECT item_num
          ,item_id
          ,quantity
          ,to_organization_id
          ,from_organization_id
          ,from_subinventory
          ,subinventory
          ,unit_of_measure
          ,header_interface_id
          ,interface_transaction_id
          ,attribute4
          ,attribute8
          ,e0342_status_flag 
          ,shipment_num
          ,uom_code
   FROM  xx_gi_rcv_str_dtl 
   WHERE e0342_status_flag ='STR'
   AND   attribute4        ='STOS'
   FOR UPDATE OF e0342_status_flag,subinventory,quantity,attribute4;
                                      
-- +====================================================================================+
-- |  Cursor to fetch all overage qty records with 'STRL' status                       |
-- |                   whether Intransit transfer done or not                           |
-- +====================================================================================+
   CURSOR lcu_dtl_strl_curr
   IS 
   SELECT item_num
          ,item_id
          ,quantity
          ,to_organization_id
          ,from_organization_id
          ,from_subinventory
          ,subinventory
          ,unit_of_measure
          ,header_interface_id
          ,interface_transaction_id
          ,attribute4
          ,attribute8
          ,e0342_status_flag 
          ,shipment_num 
   FROM xx_gi_rcv_str_dtl 
   WHERE e0342_status_flag ='STRL'
   AND   attribute4        IN ('OHDR','OHRE','STOS')
   FOR UPDATE OF e0342_status_flag,subinventory,quantity,attribute4;
                             
-- +====================================================================================+
-- |Cursor to fetch 'STRDL' status cursor to check whether direct transfer done or not  |
-- +====================================================================================+
   CURSOR lcu_dtl_strdl_curr
   IS 
   SELECT item_num
          ,item_id
          ,quantity
          ,to_organization_id
          ,from_organization_id
          ,from_subinventory
          ,subinventory
          ,unit_of_measure
          ,header_interface_id
          ,interface_transaction_id
          ,attribute4
          ,attribute8
          ,e0342_status_flag 
          ,shipment_num 
   FROM xx_gi_rcv_str_dtl 
   WHERE e0342_status_flag ='STRDL'
   AND   attribute4        IN ('OHDR','OHRE','OHDS')
   FOR UPDATE OF e0342_status_flag,subinventory,quantity,attribute4;
 -- +====================================================================================+
-- | Cursor to fetch all Shortage qty inserted records with 'W' status                   |
-- | to be checked  first for the same shipement , item and keyrec combination           |
-- +====================================================================================+
   CURSOR lcu_podc_ohds_curr(
                             p_shipment_num IN VARCHAR2
                             ,p_item_num     IN VARCHAR2
                             ,p_keyrec      IN VARCHAR2
                             ,p_to_org_id   IN NUMBER
                            )
   IS 
   SELECT  ROWID 
          ,shipment_num
          ,item_id
          ,to_organization_id
          ,from_organization_id
          ,quantity
          ,item_num
          ,interface_transaction_id
          ,attribute8
   FROM  xx_gi_rcv_str_dtl
   WHERE e0342_status_flag  = 'W'
   AND   attribute4         = 'OHDS'
   AND   shipment_num       = p_shipment_num
   AND   attribute8         = p_keyrec
   AND   item_num           = p_item_num
   AND   to_organization_id = p_to_org_id
   FOR UPDATE OF e0342_status_flag,subinventory,quantity,attribute4;
                                               
-- +====================================================================================+
-- |Cursor to fetch records from mmt for the corresponding shipment and items for an org|
-- +====================================================================================+
   CURSOR lcu_mtl_trans_curr(
                             p_shipment_num IN VARCHAR2
                             ,p_item_num    IN VARCHAR2
                             ,p_to_org_id   IN NUMBER
                            )
   IS   
   SELECT SUM(ABS(transaction_quantity))   transaction_quantity
          ,shipment_number
          ,inventory_item_id
          ,organization_id 
          ,transfer_organization_id
   FROM mtl_material_transactions
   WHERE shipment_number =  p_shipment_num   
   AND transfer_organization_id=  p_to_org_id
   AND transaction_type_id =
                           (SELECT
                                   transaction_type_id 
                            FROM   mtl_transaction_types 
                            WHERE  UPPER(transaction_type_name)=UPPER('Intransit Shipment')
                            AND    disable_date IS NULL
                           )
   AND  inventory_item_id = GET_ITEM_ID(p_item_num,p_to_org_id)  
   GROUP BY shipment_number
            ,inventory_item_id
            ,organization_id
            ,transfer_organization_id;  
    
-- +====================================================================================+
-- |Cursor to check whether qtys received in base tables after Intransit shipments      |
-- +====================================================================================+
   CURSOR lcu_rcv_shipm_curr(
                             p_shipment_num IN VARCHAR2
                             ,p_item_id     IN NUMBER
                             ,p_to_org_id   IN NUMBER
                             ,p_fr_org_id   IN NUMBER
                            )
   IS  
   SELECT  RSL.item_id
          ,SUM(RSL.quantity_shipped)  quantity_shipped
          ,SUM(RSL.quantity_received) quantity_received
   FROM  rcv_shipment_headers RSH
         ,rcv_shipment_lines  RSL
   WHERE RSH.shipment_num         = p_shipment_num 
   AND   RSL.item_id              = p_item_id
   AND   RSL.to_organization_id   = p_to_org_id 
   AND   RSL.from_organization_id = p_fr_org_id 
   AND   RSH.shipment_header_id   = RSL.shipment_header_id  
   GROUP BY RSL.item_id;
                            
-- +====================================================================================+
-- |Cursor to fetch all 'PRCP' records for receipt generation and to process            |
-- +====================================================================================+
    CURSOR lcu_dtl_prcp_curr
    IS
    SELECT   XGRD.ROWID xgrd_rowid
           , XGRD.header_interface_id
           , XGRD.to_organization_id
           , XGRD.interface_transaction_id
           , XGRD.item_id
           , XGRD.attribute4
           , XGRD.attribute8
           , XGRD.item_num
           , XGRD.vendor_id
           , XGRD.vendor_site_id
           , XGRD.e0342_status_flag
    FROM   xx_gi_rcv_str_dtl  XGRD
    WHERE  XGRD.attribute4            =   'OHDR'
    AND    XGRD.E0342_status_flag     =   'PRCP'
    ORDER BY XGRD.header_interface_id;
                                      
   TYPE lcu_dtl_prcp_curr_tbl IS TABLE OF lcu_dtl_prcp_curr%ROWTYPE
   INDEX BY BINARY_INTEGER;
   lcu_dtl_prcp_curr_rec  lcu_dtl_prcp_curr_tbl;
                                            
  -- +====================================================================================+
--   | Cursor to check  correction records with 'OHRE' status                             |
-- +====================================================================================  +
    CURSOR lcu_dtl_ohre_curr 
    IS
    SELECT   XGRD.ROWID
             ,XGRD.attribute4
             ,XGRD.e0342_status_flag
             ,XGRD.interface_transaction_id
             ,XGRD.quantity 
             ,XGRD.shipment_num
             ,XGRD.item_num
             ,XGRD.to_organization_id
             ,XGRD.from_organization_id
    FROM   xx_gi_rcv_str_dtl  XGRD
    WHERE  XGRD.attribute4            = 'OHRE'
    AND    XGRD.E0342_status_flag     = 'POD'
    ORDER BY XGRD.header_interface_id;
  
   BEGIN
     ln_commit_cnt:=0;
  -- opening  first cursor with 'OHDR' status 
       OPEN  lcu_dtl_podc_curr;
       FETCH lcu_dtl_podc_curr 
       BULK COLLECT INTO lcu_dtl_podc_curr_rec; 
       FOR i 
          IN 1..lcu_dtl_podc_curr_rec.COUNT
       LOOP  --lcu_dtl_podc_curr
          ln_commit_cnt:=ln_commit_cnt+1;
          FND_FILE.PUT_LINE(FND_FILE.LOG
                              ,'lcu_dtl_podc_curr_rec cursor qty : '||lcu_dtl_podc_curr_rec(i).quantity||
                               ' lcu_dtl_podc_curr_rec cursor itemid : '||lcu_dtl_podc_curr_rec(i).item_id);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Shipment Num : '||lcu_dtl_podc_curr_rec(i).shipment_num||
                            ' ItemNum :'||lcu_dtl_podc_curr_rec(i).item_num||
                            ' To_org :'||lcu_dtl_podc_curr_rec(i).to_organization_id||
                            ' From_org :'||lcu_dtl_podc_curr_rec(i).from_organization_id);
            --Validation to find whether staging line quantity is zero 
              ln_ohds_flag:=0;
-- +=========================================================================================+
-- | VALIDATION TO CHECK DTL WITH RVSC TRANSACTION TYPE WITH ZERO QUANTITIES                 |
-- | RVSC  - KEY REC HDR  DTL    (ZERO RECEIPTS INSERT BOTH STG  RTI AS  CHARGE BACK         |
-- +=========================================================================================+
              IF lcu_dtl_podc_curr_rec(i).attribute4 = 'RVSC' THEN
                IF lcu_dtl_podc_curr_rec(i).quantity=0 THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered RVSC status cursor');
                  OPEN lcu_mtl_trans_curr(
                                          lcu_dtl_podc_curr_rec(i).shipment_num
                                          ,lcu_dtl_podc_curr_rec(i).item_num
                                          ,lcu_dtl_podc_curr_rec(i).to_organization_id
                                         );
                  FETCH  lcu_mtl_trans_curr
                   INTO  ln_transaction_qty
                         ,lc_shipment_number
                         ,ln_inventory_item_id
                         ,ln_organization_id
                         ,ln_transfer_org_id;
                  CLOSE lcu_mtl_trans_curr;
               FND_FILE.PUT_LINE(FND_FILE.LOG,'MTL material transactions Values : ');
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Transaction_qty : '||ln_transaction_qty ||
                                              'Shipment_number : '||lc_shipment_number ||
                                              'Organization_id : '||ln_organization_id ||
                                              ' Inventory_item_id : '||ln_inventory_item_id ||
                                              ' To_org_id : '||ln_transfer_org_id
                           );
-- +=========================================================================================+
-- | Insert Staging table line records to CHARGEBACK for RVSC records                        |
-- | RVSC  - KEY REC HDR  DTL    (ZERO RECEIPTS INSERT BOTH STG  RTI AS  CHARGE BACK         |
-- +=========================================================================================+
                   INSERT      --+APPEND
                    INTO xx_gi_rcv_str_dtl
                                          (interface_transaction_id
                                           ,group_id
                                           ,last_update_date
                                           ,last_updated_by
                                           ,creation_date
                                           ,created_by
                                           ,last_update_login
                                           ,transaction_type
                                           ,transaction_date
                                           ,processing_status_code	
                                           ,transaction_status_code
                                           ,quantity
                                           ,unit_of_measure
                                           ,item_id
                                           ,item_description
                                           ,item_revision
                                           ,uom_code
                                           ,auto_transact_code
                                           ,shipment_header_id
                                           ,shipment_line_id
                                           ,ship_to_location_id
                                           ,primary_quantity
                                           ,from_organization_id
                                           ,from_subinventory
                                           ,to_organization_id
                                           ,subinventory
                                           ,shipment_num
                                           ,expected_receipt_date
                                           ,attribute4
                                           ,attribute5
                                           ,attribute6
                                           ,attribute7
                                           ,attribute8
                                           ,header_interface_id
                                           ,item_num
                                           ,from_organization_code
                                           ,to_organization_code
                                           ,validation_flag
                                           ,e0342_status_flag
                                           ,e0342_first_rec_time
                                          )
                                           VALUES
                                          (rcv_transactions_interface_s.NEXTVAL
                                           ,lcu_dtl_podc_curr_rec(i).group_id
                                           ,lcu_dtl_podc_curr_rec(i).last_update_date
                                           ,lcu_dtl_podc_curr_rec(i).last_updated_by
                                           ,lcu_dtl_podc_curr_rec(i).creation_date
                                           ,lcu_dtl_podc_curr_rec(i).created_by
                                           ,lcu_dtl_podc_curr_rec(i).last_update_login
                                           ,lcu_dtl_podc_curr_rec(i).transaction_type
                                           ,lcu_dtl_podc_curr_rec(i).transaction_date
                                           ,lcu_dtl_podc_curr_rec(i).processing_status_code	
                                           ,lcu_dtl_podc_curr_rec(i).transaction_status_code
                                           ,ln_transaction_qty -- quantity
                                           ,lcu_dtl_podc_curr_rec(i).unit_of_measure
                                           ,ln_inventory_item_id
                                           ,lcu_dtl_podc_curr_rec(i).item_description
                                           ,lcu_dtl_podc_curr_rec(i).item_revision
                                           ,lcu_dtl_podc_curr_rec(i).uom_code
                                           ,lcu_dtl_podc_curr_rec(i).auto_transact_code
                                           ,lcu_dtl_podc_curr_rec(i).shipment_header_id
                                           ,lcu_dtl_podc_curr_rec(i).shipment_line_id
                                           ,lcu_dtl_podc_curr_rec(i).ship_to_location_id
                                           ,ln_transaction_qty -- primary_quantity
                                           ,ln_organization_id
                                           ,'CHARGEBACK'   -- lcu_dtl_podc_curr_rec(i).from_subinventory
                                           ,ln_transfer_org_id --to_organization_id
                                           ,'CHARGEBACK'
                                           ,lcu_dtl_podc_curr_rec(i).shipment_num
                                           ,NVL(lcu_dtl_podc_curr_rec(i).expected_receipt_date,SYSDATE)
                                           ,'OHDR' -- attribute4
                                           ,lcu_dtl_podc_curr_rec(i).shipment_num
                                           ,lcu_dtl_podc_curr_rec(i).attribute6
                                           ,lcu_dtl_podc_curr_rec(i).attribute7
                                           ,lcu_dtl_podc_curr_rec(i).attribute8
                                           ,lcu_dtl_podc_curr_rec(i).header_interface_id
                                           ,lcu_dtl_podc_curr_rec(i).item_num
                                           ,lcu_dtl_podc_curr_rec(i).from_organization_code
                                           ,lcu_dtl_podc_curr_rec(i).to_organization_code
                                           ,'N'  -- validation_flag
                                           ,'PRCP' -- e0342_status_flag
                                           ,SYSDATE -- e0342_first_rec_time
                                           ); 
                       
                        UPDATE xx_gi_rcv_str_dtl 
                        SET    e0342_status_flag          = 'STRD' 
                               ,attribute4                = 'OHDR'            --even if attribute4='RVSC'
                               ,subinventory              = 'CHARGEBACK'
                               ,quantity                  = ln_transaction_qty 
                        WHERE  shipment_num               = lcu_dtl_podc_curr_rec(i).shipment_num  
                        AND    attribute8                 = lcu_dtl_podc_curr_rec(i).attribute8
                        AND    item_num                   = lcu_dtl_podc_curr_rec(i).item_num
                        AND    to_organization_id         = lcu_dtl_podc_curr_rec(i).to_organization_id
                        AND    interface_transaction_id   = lcu_dtl_podc_curr_rec(i).interface_transaction_id
                        AND    ROWID                      = lcu_dtl_podc_curr_rec(i).ROWID;
              END IF;   --  zero qty cursor
              ELSE 
-- +=========================================================================================+
-- | RVSC records  without  zero quantities to be updated 'VE' records and insert it         |
-- | into error tables by calling exception pkg  XX_GI_RCV_ERR_PKG.XX_GI_INS_CUST_EXCEP      |
-- +=========================================================================================+
              UPDATE xx_gi_rcv_str_dtl
              SET    e0342_status_flag  = 'VE'
              WHERE  interface_transaction_id   = lcu_dtl_podc_curr_rec(i).interface_transaction_id
              AND    ROWID                      = lcu_dtl_podc_curr_rec(i).ROWID;
                 
                 XX_GI_RCV_ERR_PKG.XX_GI_INS_CUST_EXCEP (
                                                         'XX_GI_ST002'
                                                         ,'INTERFACE_TRANSACTION_ID'
                                                         ,lcu_dtl_podc_curr_rec(i).interface_transaction_id
                                                         ,'RVSC records without zero quantity'
                                                         ,'XX_GI_ST2'
                 );
              END IF;   --  RVSC  cursor 
                                                                                                   
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Before Entering Main IF '||lcu_dtl_podc_curr_rec(i).attribute4 || ' : '|| lcu_dtl_podc_curr_rec(i).interface_transaction_id); 
-- +=========================================================================================+
-- | Compare OHDR records  with  non-zero quantities  and continue for correction            |
-- +=========================================================================================+
              IF (lcu_dtl_podc_curr_rec(i).attribute4 = 'OHDR'
                  AND lcu_dtl_podc_curr_rec(i).quantity <> 0)THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG,' Entered OHDR main cursor ');
                 FND_FILE.PUT_LINE(FND_FILE.LOG,' Shipment Num : '||lcu_dtl_podc_curr_rec(i).shipment_num||
                                                ' Itemnum : '||lcu_dtl_podc_curr_rec(i).item_num||
                                                ' To_org : '||lcu_dtl_podc_curr_rec(i).to_organization_id||
                                                ' Attribute8 : '||lcu_dtl_podc_curr_rec(i).attribute8);
                -- Existance of OHDS
                  FOR lcu_podc_ohds_curr_rec 
                     IN lcu_podc_ohds_curr(
                                            lcu_dtl_podc_curr_rec(i).shipment_num
                                            ,lcu_dtl_podc_curr_rec(i).item_num
                                            ,lcu_dtl_podc_curr_rec(i).attribute8
                                            ,lcu_dtl_podc_curr_rec(i).to_organization_id
                                           )
                    LOOP
-- +=========================================================================================+
-- |    Compare OHDR records  for  existing OHDS records and equal quantities  match         |
-- +=========================================================================================+
                      IF (lcu_dtl_podc_curr_rec(i).quantity = lcu_podc_ohds_curr_rec.quantity) THEN
                         ln_ohds_flag:= 1;
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered OHDS status cursor equal qty part');
                                UPDATE xx_gi_rcv_str_dtl   -- Equal Quantity Case
                                 SET e0342_status_flag   = 'PRCP' 
                                     ,subinventory       = 'STOCK'
                                     ,quantity           = lcu_dtl_podc_curr_rec(i).quantity
                                     ,attribute4         = 'OHDR'    --OHDS record
                                WHERE shipment_num       = lcu_dtl_podc_curr_rec(i).shipment_num
                                AND   attribute8         = lcu_dtl_podc_curr_rec(i).attribute8
                                AND   item_num           = lcu_dtl_podc_curr_rec(i).item_num
                                AND   to_organization_id = lcu_dtl_podc_curr_rec(i).to_organization_id
                                AND   ROWID              = lcu_dtl_podc_curr_rec(i).ROWID;
                                
                                DELETE FROM xx_gi_rcv_str_dtl -- OHDR records
                                WHERE ROWID=lcu_podc_ohds_curr_rec.ROWID;
  
-- +=========================================================================================+
-- |    Compare OHDR records  for  existing OHDS records and Shortage  match                 |
-- +=========================================================================================+
                      ELSIF (lcu_dtl_podc_curr_rec(i).quantity < lcu_podc_ohds_curr_rec.quantity) THEN 
                                                          --- Shortage Case 
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Shorage OHDS qty :'||lcu_podc_ohds_curr_rec.quantity);
                                ln_ohds_flag:= 1;
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered OHDS status cursor Shortage qty part');
                                UPDATE xx_gi_rcv_str_dtl                                
                                SET e0342_status_flag    = 'PRCP' 
                                    ,subinventory        = 'STOCK'
                                    ,quantity            = lcu_dtl_podc_curr_rec(i).quantity
                                    ,attribute4          = 'OHDR'
                                WHERE shipment_num       = lcu_dtl_podc_curr_rec(i).shipment_num
                                AND   attribute8         = lcu_dtl_podc_curr_rec(i).attribute8
                                AND   item_num           = lcu_dtl_podc_curr_rec(i).item_num
                                AND   to_organization_id = lcu_dtl_podc_curr_rec(i).to_organization_id
                                AND   ROWID              = lcu_dtl_podc_curr_rec(i).ROWID;
                                                                                       
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Shorage OHDS qty after update :'||
                                            lcu_podc_ohds_curr_rec.quantity);
                                UPDATE xx_gi_rcv_str_dtl   
                                SET    e0342_status_flag = 'W' -- check whether STRD
                                       ,subinventory     = 'CHARGEBACK'
                                       ,quantity         =(lcu_podc_ohds_curr_rec.quantity - lcu_dtl_podc_curr_rec(i).quantity )
                                WHERE  attribute4        = 'OHDS' 
                                AND    shipment_num      =lcu_podc_ohds_curr_rec.shipment_num
                                AND    attribute8        = lcu_podc_ohds_curr_rec.attribute8
                                AND    item_num          = lcu_podc_ohds_curr_rec.item_num
                                AND    ROWID             = lcu_podc_ohds_curr_rec.ROWID;
                                                 
-- +========================================================================================+
-- |    Compare OHDR records  for  existing OHDS records and Overage  match                 |
-- +========================================================================================+
                      ELSIF (lcu_dtl_podc_curr_rec(i).quantity > lcu_podc_ohds_curr_rec.quantity) THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered OHDS status cursor Overage qty part');
                                                                    
                                ln_ohds_flag:= 1;
                                UPDATE  xx_gi_rcv_str_dtl               -- Overage Case
                                SET     e0342_status_flag ='PRCP' 
                                        ,quantity         = lcu_podc_ohds_curr_rec.quantity 
                                WHERE   e0342_status_flag ='W' 
                                AND    ROWID              = lcu_dtl_podc_curr_rec(i).ROWID;
                                                     
                                UPDATE xx_gi_rcv_str_dtl 
                                SET    e0342_status_flag  ='STR'
                                       ,attribute4        = 'STOS'
                                       ,quantity          = (lcu_dtl_podc_curr_rec(i).quantity-lcu_podc_ohds_curr_rec.quantity)
                                WHERE   ROWID             = lcu_podc_ohds_curr_rec.ROWID;
                                                                            
                      END IF;
                    END LOOP;
              END IF;
               
-- +===========================================================================================+
-- |both overage and shortage cases are considered here  without any OHDS (wait status records)|
-- +===========================================================================================+
              IF (lcu_dtl_podc_curr_rec(i).attribute4 = 'OHDR' 
                   AND lcu_dtl_podc_curr_rec(i).quantity <> 0 
                   AND ln_ohds_flag = 0) THEN 
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered OHDR status first time records part');
                  OPEN lcu_mtl_trans_curr(
                                           lcu_dtl_podc_curr_rec(i).shipment_num
                                          ,lcu_dtl_podc_curr_rec(i).item_num
                                          ,lcu_dtl_podc_curr_rec(i).to_organization_id
                                         );
                  FETCH  lcu_mtl_trans_curr 
                   INTO  ln_transaction_qty
                         ,lc_shipment_number
                         ,ln_inventory_item_id
                         ,ln_organization_id 
                         ,ln_transfer_org_id;
                  CLOSE lcu_mtl_trans_curr;
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'Shipment Num :'||lc_shipment_number||
                            'ItemID :'||ln_inventory_item_id||
                            ' To_org :'||ln_transfer_org_id||
                            ' From_org :'||ln_organization_id);
                                         
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'DTL Quantity Check : '||lcu_dtl_podc_curr_rec(i).quantity ||
                                                  ' Transaction_qty :'||ln_transaction_qty);
                    IF ( lcu_dtl_podc_curr_rec(i).quantity > ln_transaction_qty 
                         AND ln_ohds_flag=0 ) THEN 
-- +=========================================================================================+
-- |    Compare OHDR records  Overage  quantity  by inserting 'STR' status records           |
-- +=========================================================================================+
    -- overage case
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered firsttime OHDR status cursor OVERAGE qty part');
                      INSERT      --+APPEND
                         INTO xx_gi_rcv_str_dtl
                                               (interface_transaction_id
                                                ,group_id
                                                ,last_update_date
                                                ,last_updated_by
                                                ,creation_date
                                                ,created_by
                                                ,last_update_login
                                                ,transaction_type
                                                ,transaction_date
                                                ,processing_status_code	
                                                ,processing_mode_code	
                                                ,transaction_status_code 
                                                ,quantity
                                                ,unit_of_measure
                                                ,item_id
                                                ,item_description
                                                ,item_revision
                                                ,uom_code
                                                ,auto_transact_code
                                                ,shipment_header_id
                                                ,shipment_line_id
                                                ,ship_to_location_id
                                                ,primary_quantity
                                                ,from_organization_id
                                                ,from_subinventory
                                                ,to_organization_id
                                                ,subinventory
                                                ,shipment_num
                                                ,expected_receipt_date	
                                                ,attribute4
                                                ,attribute5
                                                ,attribute6
                                                ,attribute7
                                                ,attribute8
                                                ,header_interface_id
                                                ,item_num
                                                ,from_organization_code
                                                ,to_organization_code
                                                ,validation_flag
                                                ,e0342_status_flag
                                                ,e0342_first_rec_time
                                                 )
                                                VALUES
                                                (rcv_transactions_interface_s.NEXTVAL
                                                ,lcu_dtl_podc_curr_rec(i).group_id
                                                ,lcu_dtl_podc_curr_rec(i).last_update_date
                                                ,lcu_dtl_podc_curr_rec(i).last_updated_by
                                                ,lcu_dtl_podc_curr_rec(i).creation_date
                                                ,lcu_dtl_podc_curr_rec(i).created_by
                                                ,lcu_dtl_podc_curr_rec(i).last_update_login
                                                ,lcu_dtl_podc_curr_rec(i).transaction_type
                                                ,lcu_dtl_podc_curr_rec(i).transaction_date
                                                ,lcu_dtl_podc_curr_rec(i).processing_status_code
                                                ,lcu_dtl_podc_curr_rec(i).processing_mode_code
                                                ,lcu_dtl_podc_curr_rec(i).transaction_status_code
                                                ,(lcu_dtl_podc_curr_rec(i).quantity - ln_transaction_qty)
                                                ,lcu_dtl_podc_curr_rec(i).unit_of_measure
                                                ,ln_inventory_item_id
                                                ,lcu_dtl_podc_curr_rec(i).item_description
                                                ,lcu_dtl_podc_curr_rec(i).item_revision
                                                ,lcu_dtl_podc_curr_rec(i).uom_code
                                                ,lcu_dtl_podc_curr_rec(i).auto_transact_code
                                                ,lcu_dtl_podc_curr_rec(i).shipment_header_id
                                                ,lcu_dtl_podc_curr_rec(i).shipment_line_id
                                                ,lcu_dtl_podc_curr_rec(i).ship_to_location_id
                                                ,(lcu_dtl_podc_curr_rec(i).quantity - ln_transaction_qty)
                                                ,lcu_dtl_podc_curr_rec(i).from_organization_id
                                                ,'STOCK'
                                                ,ln_organization_id --to_organization_id
                                                ,'STOCK'
                                                ,lcu_dtl_podc_curr_rec(i).shipment_num
                                                ,NVL(lcu_dtl_podc_curr_rec(i).expected_receipt_date,SYSDATE)
                                                ,'STOS' -- attribute4 --'OHDS' 'STOS'
                                                ,lcu_dtl_podc_curr_rec(i).shipment_num
                                                ,lcu_dtl_podc_curr_rec(i).attribute6
                                                ,lcu_dtl_podc_curr_rec(i).attribute7
                                                ,lcu_dtl_podc_curr_rec(i).attribute8
                                                ,lcu_dtl_podc_curr_rec(i).header_interface_id
                                                ,lcu_dtl_podc_curr_rec(i).item_num 
                                                ,lcu_dtl_podc_curr_rec(i).from_organization_code
                                                ,lcu_dtl_podc_curr_rec(i).to_organization_code
                                                ,'N'  -- validation_flag
                                                ,'STR' -- e0342_status_flag
                                                ,SYSDATE -- e0342_first_rec_time
                                                );
                      UPDATE xx_gi_rcv_str_dtl    
                      SET    e0342_status_flag  = 'PRCP' 
                             ,subinventory      ='STOCK'
                             ,quantity          = ln_transaction_qty
                      WHERE  ROWID              = lcu_dtl_podc_curr_rec(i).ROWID;
                                               
                    ELSIF (lcu_dtl_podc_curr_rec(i).quantity < ln_transaction_qty 
                           AND ln_ohds_flag=0 ) THEN
-- +=========================================================================================+
-- |    Compare OHDR records  Shortage  quantity  by inserting 'W' status records            |
-- +=========================================================================================+
                                                                 --shortage
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered firsttime OHDR status cursor SHORTAGE qty part');
                        INSERT      --+APPEND
                        INTO xx_gi_rcv_str_dtl(
                                               interface_transaction_id
                                               ,group_id
                                               ,last_update_date
                                               ,last_updated_by
                                               ,creation_date
                                               ,created_by
                                               ,last_update_login
                                               ,transaction_type
                                               ,transaction_date
                                               ,processing_status_code	
                                               ,processing_mode_code	
                                               ,transaction_status_code
                                               ,quantity
                                               ,unit_of_measure
                                               ,item_id
                                               ,item_description
                                               ,item_revision
                                               ,uom_code
                                               ,auto_transact_code
                                               ,shipment_header_id
                                               ,shipment_line_id
                                               ,ship_to_location_id
                                               ,primary_quantity
                                               ,from_organization_id
                                               ,from_subinventory
                                               ,to_organization_id
                                               ,subinventory
                                               ,shipment_num
                                               ,expected_receipt_date	
                                               ,attribute1
                                               ,attribute2
                                               ,attribute3
                                               ,attribute4
                                               ,attribute5
                                               ,attribute6
                                               ,attribute7
                                               ,attribute8
                                               ,header_interface_id
                                               ,item_num
                                               ,from_organization_code
                                               ,to_organization_code
                                               ,validation_flag
                                               ,e0342_status_flag
                                               ,e0342_first_rec_time
                                               )
                                               VALUES
                                               (rcv_transactions_interface_s.NEXTVAL
                                               ,lcu_dtl_podc_curr_rec(i).group_id
                                               ,lcu_dtl_podc_curr_rec(i).last_update_date
                                               ,lcu_dtl_podc_curr_rec(i).last_updated_by
                                               ,lcu_dtl_podc_curr_rec(i).creation_date
                                               ,lcu_dtl_podc_curr_rec(i).created_by
                                               ,lcu_dtl_podc_curr_rec(i).last_update_login
                                               ,lcu_dtl_podc_curr_rec(i).transaction_type
                                               ,lcu_dtl_podc_curr_rec(i).transaction_date
                                               ,lcu_dtl_podc_curr_rec(i).processing_status_code
                                               ,lcu_dtl_podc_curr_rec(i).processing_mode_code
                                               ,lcu_dtl_podc_curr_rec(i).transaction_status_code
                                               ,(ln_transaction_qty - lcu_dtl_podc_curr_rec(i).quantity)
                                               ,lcu_dtl_podc_curr_rec(i).unit_of_measure
                                               ,ln_inventory_item_id
                                               ,lcu_dtl_podc_curr_rec(i).item_description
                                               ,lcu_dtl_podc_curr_rec(i).item_revision
                                               ,lcu_dtl_podc_curr_rec(i).uom_code
                                               ,lcu_dtl_podc_curr_rec(i).auto_transact_code
                                               ,lcu_dtl_podc_curr_rec(i).shipment_header_id
                                               ,lcu_dtl_podc_curr_rec(i).shipment_line_id
                                               ,lcu_dtl_podc_curr_rec(i).ship_to_location_id
                                               ,(ln_transaction_qty - lcu_dtl_podc_curr_rec(i).quantity)
                                               ,lcu_dtl_podc_curr_rec(i).from_organization_id
                                               ,'CHARGEBACK'
                                               ,ln_organization_id --to_organization_id
                                               ,'CHARGEBACK'
                                               ,lcu_dtl_podc_curr_rec(i).shipment_num
                                               ,lcu_dtl_podc_curr_rec(i).expected_receipt_date
                                               ,lcu_dtl_podc_curr_rec(i).attribute1
                                               ,lcu_dtl_podc_curr_rec(i).attribute2
                                               ,lcu_dtl_podc_curr_rec(i).attribute3
                                               ,'OHDS' -- attribute4
                                               ,lcu_dtl_podc_curr_rec(i).attribute5
                                               ,lcu_dtl_podc_curr_rec(i).attribute6
                                               ,lcu_dtl_podc_curr_rec(i).attribute7
                                               ,lcu_dtl_podc_curr_rec(i).attribute8
                                               ,lcu_dtl_podc_curr_rec(i).header_interface_id
                                               ,lcu_dtl_podc_curr_rec(i).item_num 
                                               ,lcu_dtl_podc_curr_rec(i).from_organization_code
                                               ,lcu_dtl_podc_curr_rec(i).to_organization_code
                                               ,'N'  -- validation_flag
                                               ,'W' -- e0342_status_flag
                                               ,SYSDATE -- e0342_first_rec_time
                                               );
                        UPDATE xx_gi_rcv_str_dtl 
                        SET  e0342_status_flag  = 'PRCP' 
                             ,subinventory      = 'STOCK'
                             ,quantity          = lcu_dtl_podc_curr_rec(i).quantity
                        WHERE  ROWID            = lcu_dtl_podc_curr_rec(i).ROWID;
                                                               
                    ELSIF (lcu_dtl_podc_curr_rec(i).quantity = ln_transaction_qty 
                           AND ln_ohds_flag=0 ) THEN
-- +=========================================================================================+
-- |    Compare OHDR records  Equal  quantity  by inserting 'PRCP' status records            |
-- +=========================================================================================+
                    --Validation to find whether both quantities are equal 
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered firsttime OHDR status cursor EQUAL qty part');
                   FND_FILE.PUT_LINE(FND_FILE.LOG
                                       ,'Shipment Num :'||lcu_dtl_podc_curr_rec(i).shipment_num||
                                       ' ItemID :'||ln_inventory_item_id||
                                       ' To_org :'||ln_transfer_org_id||
                                       ' Fr_org :'||ln_organization_id||
                                       ' MTL Transaction_qty'||ln_transaction_qty||
                                       ' DTL qty'||lcu_dtl_podc_curr_rec(i).quantity);
                             UPDATE xx_gi_rcv_str_dtl
                               SET    e0342_status_flag = 'PRCP'
                                      ,subinventory     = 'STOCK'
                             WHERE  shipment_num        = lcu_dtl_podc_curr_rec(i).shipment_num
                             AND    attribute8          = lcu_dtl_podc_curr_rec(i).attribute8
                             AND    item_num            = lcu_dtl_podc_curr_rec(i).item_num
                             AND    to_organization_id  = lcu_dtl_podc_curr_rec(i).to_organization_id
                             AND    ROWID               = lcu_dtl_podc_curr_rec(i).ROWID;
                    END IF;
              END IF; 
                                                       
                IF ln_commit_cnt = 1000 THEN
                COMMIT; 
                ln_commit_cnt := 0;
                END IF;
       END LOOP;  -- for lcu_dtl_podc_curr
           COMMIT;  
     -------- Error Status flag 'W"     
  -- open 'W' status cursor to check end of day validation 
   FOR lcu_dtl_w_curr_rec 
      IN lcu_dtl_w_curr
   LOOP
   -- End of Day Validation  
-- +=========================================================================================+
-- |    Compare OHDR records 'W' status records for end of day validation                    |
-- +=========================================================================================+
     SELECT (SYSDATE -TO_DATE(lcu_dtl_w_curr_rec.e0342_first_rec_time, 'DD-MON-RR HH24:MI:SS'))
     INTO ln_end_of_day
     FROM   xx_gi_rcv_str_dtl  
     WHERE  interface_transaction_id=lcu_dtl_w_curr_rec.interface_transaction_id;
  
     IF ln_end_of_day > 1 THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'End Of Day Validation Pass');
        UPDATE xx_gi_rcv_str_dtl 
        SET e0342_status_flag         = 'STRD' 
        ,subinventory                 = 'CHARGEBACK'
        ,quantity                     = lcu_dtl_w_curr_rec.quantity
        ,attribute4                   = 'OHDS'
        WHERE e0342_status_flag       = 'W' 
        AND  interface_transaction_id = lcu_dtl_w_curr_rec.interface_transaction_id; 
     END IF;
   END LOOP;
   COMMIT;
     -------- Error Status flag 'STRD'   
-- +==========================================================================+
-- | open 'STRD' status cursor to perform direct Org transfer                 |
-- +==========================================================================+
   FOR lcu_dtl_strd_curr_rec  
      IN lcu_dtl_strd_curr  -- shortage case
   LOOP
  -- CALL DIRECT ORG TRANSFER SCRIPT   FROM TO_ORG TO FROM_ORG  With same qtyg with CHARGEBACK subinv
  IF lcu_dtl_strd_curr_rec.attribute4 IN ('OHDR','OHDS') THEN 
     FND_FILE.PUT_LINE(FND_FILE.LOG,'STRD Direct transfer for Shipment Num: '||lcu_dtl_strd_curr_rec.shipment_num);
-- +=========================================================================================+
-- |      Call Direct Org transfer script for shortage quantity  to populate M M T           |
-- +=========================================================================================+
    XX_GI_DIRECTORG_TRANSFER( 
                             lcu_dtl_strd_curr_rec.item_num   -- p_itemnum,
                             ,lcu_dtl_strd_curr_rec.quantity   --p_trans_qty 
                             ,lcu_dtl_strd_curr_rec.to_organization_id  --from_organization_id
                             ,lcu_dtl_strd_curr_rec.from_organization_id   --to_organization_id
                             ,'CHARGEBACK'
                             ,'CHARGEBACK'
                             ,lcu_dtl_strd_curr_rec.uom_code -- p_uom -- 'EA' 
                             ,lcu_dtl_strd_curr_rec.header_interface_id
                             ,lcu_dtl_strd_curr_rec.interface_transaction_id
                             ,lcu_dtl_strd_curr_rec.shipment_num
    );
-- +==========================================================================+
-- | After  Direct transfer change the status to 'PRCP'                       |
-- +==========================================================================+
        UPDATE xx_gi_rcv_str_dtl 
        SET e0342_status_flag            ='STRDL' 
            ,subinventory                = 'CHARGEBACK'
        WHERE e0342_status_flag          = 'STRD' 
        AND  interface_transaction_id    = lcu_dtl_strd_curr_rec.interface_transaction_id; 
  ELSIF lcu_dtl_strd_curr_rec.attribute4 = 'OHRE' THEN 
     FND_FILE.PUT_LINE(FND_FILE.LOG,'STRD Direct transfer for Shipment Num'||lcu_dtl_strd_curr_rec.shipment_num);
    XX_GI_DIRECTORG_TRANSFER( 
                             lcu_dtl_strd_curr_rec.item_num   -- p_itemnum,
                             ,lcu_dtl_strd_curr_rec.quantity   --p_trans_qty 
                             ,lcu_dtl_strd_curr_rec.to_organization_id  --from_organization_id
                             ,lcu_dtl_strd_curr_rec.from_organization_id   --to_organization_id
                             ,'STOCK'
                             ,'CHARGEBACK'
                             ,lcu_dtl_strd_curr_rec.uom_code -- p_uom   -- 'EA'
                             ,lcu_dtl_strd_curr_rec.header_interface_id
                             ,lcu_dtl_strd_curr_rec.interface_transaction_id
                             ,lcu_dtl_strd_curr_rec.shipment_num
    );
-- +==========================================================================+
-- | After  Direct transfer change the status to 'PRCP'                       |
-- +==========================================================================+
        UPDATE xx_gi_rcv_str_dtl 
        SET e0342_status_flag         = 'STRDL' 
            ,subinventory             = 'CHARGEBACK'
        WHERE e0342_status_flag       = 'STRD' 
        AND  interface_transaction_id = lcu_dtl_strd_curr_rec.interface_transaction_id; 
  END IF;
  
   END LOOP;
   COMMIT;
-- +==========================================================================+
-- | Error Status flag  'STR'     Overage Case records                        |
-- | open 'STR' status cursor to perform Intransit transfer                   |
-- +==========================================================================+
    FOR lcu_dtl_str_curr_rec  
       IN lcu_dtl_str_curr
    LOOP
    --Call 341 extension to create intransit shipments  XX_GI_STORE_TRNSFR_PKG.CREATE_DATA
-- +=========================================================================================+
-- |      Call Intransit Org transfer script for overage quantity  by populating mmt         |
-- +=========================================================================================+
            XX_GI_INTERORG_TRANSFER(
                                    lcu_dtl_str_curr_rec.item_num
                                   ,lcu_dtl_str_curr_rec.quantity
                                   ,lcu_dtl_str_curr_rec.from_organization_id
                                   ,lcu_dtl_str_curr_rec.to_organization_id
                                   ,'STOCK'
                                   ,'STOCK'
                                   ,lcu_dtl_str_curr_rec.uom_code
                                   ,lcu_dtl_str_curr_rec.header_interface_id
                                   ,lcu_dtl_str_curr_rec.interface_transaction_id
                                   ,lcu_dtl_str_curr_rec.shipment_num 
            );
  
        UPDATE xx_gi_rcv_str_dtl 
        SET    e0342_status_flag        = 'STRL' 
               ,subinventory            = 'STOCK' 
        WHERE  e0342_status_flag        = 'STR' 
        AND    attribute4               = 'STOS'
        AND    interface_transaction_id = lcu_dtl_str_curr_rec.interface_transaction_id;
    END LOOP;
    COMMIT;
            -- Error Status flag 'STRDL'
   -- open 'STRDL' status cursor to check whether direct transfer done or not
    FOR lcu_dtl_strdl_curr_rec
        IN  lcu_dtl_strdl_curr
     LOOP
-- +=========================================================================================+
-- |      Script to check whether Direct Org transfer is done or not                         |
-- +=========================================================================================+
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered STRDL status cursor');
     ln_strdl_flag        := 0;
     ln_transaction_id    := 0;
      BEGIN
       SELECT transaction_id 
       INTO   ln_transaction_id
       FROM   mtl_material_transactions 
       WHERE  source_code             = 'STRD Direct Transfer'
       AND   transfer_subinventory    = 'CHARGEBACK'
       AND   organization_id          = lcu_dtl_strdl_curr_rec.to_organization_id
       AND   source_line_id           = lcu_dtl_strdl_curr_rec.interface_transaction_id
       AND   transfer_organization_id = lcu_dtl_strdl_curr_rec.from_organization_id
       AND   attribute5               = lcu_dtl_strdl_curr_rec.shipment_num;
     EXCEPTION
       WHEN OTHERS THEN
        ln_strdl_flag        := 1;
        ln_transaction_id    := 0;
      END;
  
             IF (ln_strdl_flag = 0 
                 AND ln_transaction_id = 0 ) THEN
               UPDATE xx_gi_rcv_str_dtl 
               SET    e0342_status_flag        = 'PRCP' 
               WHERE  e0342_status_flag        = 'STRDL' 
               AND    interface_transaction_id = lcu_dtl_strdl_curr_rec.interface_transaction_id;
             END IF;
     END LOOP;
  
           -- Error Status flag 'STRL'
-- +=========================================================================================+
-- |      open 'STRL' status cursor to check whether Intransit transfer done or not          |
-- +=========================================================================================+
    FOR lcu_dtl_strl_curr_rec
       IN lcu_dtl_strl_curr
    LOOP   -- Get the corresponding EBS shipment number and pass here
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered STRL status cursor');
     OPEN lcu_mtl_trans_curr(
                             lcu_dtl_strl_curr_rec.shipment_num
                             ,lcu_dtl_strl_curr_rec.item_num
                             ,lcu_dtl_strl_curr_rec.to_organization_id
                            );
     FETCH lcu_mtl_trans_curr 
     INTO  ln_transaction_qty
           ,lc_shipment_number
           ,ln_inventory_item_id
           ,ln_organization_id 
           ,ln_transfer_org_id;
     CLOSE lcu_mtl_trans_curr;
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'Shipment Num :'||lc_shipment_number||
                            'ItemID :'||ln_inventory_item_id||
                            ' To_org :'||ln_transfer_org_id||
                            ' From_org :'||ln_organization_id);
      FOR  lcu_rcv_shipm_curr_rec
         IN lcu_rcv_shipm_curr(
                               lc_shipment_number 
                               ,lcu_dtl_strl_curr_rec.item_num
                               ,lcu_dtl_strl_curr_rec.to_organization_id
                               ,lcu_dtl_strl_curr_rec.from_organization_id
                               )
      LOOP
      -- TO CHECK WHETHER SHIPMENTS CREATED OR NOT
-- +=========================================================================================+
-- |      Check for equal quantity match and change to 'PRCP' status                         |
-- +=========================================================================================+
      IF ln_transaction_qty=lcu_rcv_shipm_curr_rec.quantity_received THEN  -- check this 
        UPDATE xx_gi_rcv_str_dtl 
        SET    e0342_status_flag        = 'PRCP' 
               ,subinventory            = 'STOCK' 
        WHERE  e0342_status_flag        = 'STRL' 
        AND    interface_transaction_id = lcu_dtl_strl_curr_rec.interface_transaction_id;
      END IF;
      END LOOP;
    END LOOP;
    -- Receipt Number generation
         OPEN lcu_dtl_prcp_curr;
           FETCH lcu_dtl_prcp_curr BULK COLLECT INTO lcu_dtl_prcp_curr_rec;
             FOR i IN 1..lcu_dtl_prcp_curr_rec.COUNT
             LOOP
-- +=========================================================================================+
-- |      Script to check for recept num generation and update to 'P'                        |
-- +=========================================================================================+
               BEGIN
                 SELECT XGRH.ROWID  XGRH_ROWID
                      , XGRH.receipt_num
                      , XGRH.attribute8
                 INTO   lc_rowid 
                      , lc_receipt_num
                      , lc_keyrec
                 FROM  xx_gi_rcv_str_hdr XGRH 
                 WHERE XGRH.header_interface_id = lcu_dtl_prcp_curr_rec(i).header_interface_id;
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Receipt No. Gen :'||lc_receipt_num||' KeyRec :'||lc_keyrec);
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    lc_rowid       := 0;
                    lc_receipt_num := NULL;
                    lc_keyrec      := NULL;
                  WHEN OTHERS THEN
                    lc_rowid       := 0;
                    lc_receipt_num := NULL;
                    lc_keyrec      := NULL;
               END;
                      IF lc_receipt_num IS NULL THEN
                         ln_rec_nex_id := 0;    
                         lc_meaning    := 'XX_GI_RECEIPT_NUM_US_S'; 
                            -- Receipt Creation from FND LOOKUPS
                            BEGIN
                              SELECT  meaning
                              INTO    lc_meaning
                              FROM    fnd_lookup_values_vl
                              WHERE   tag = FND_PROFILE.VALUE('ORG_ID')
                              AND     lookup_type  = 'RECEIVING PARAMETERS';
                            EXCEPTION
                              WHEN NO_DATA_FOUND THEN
                                -- Log errors in error table 
                                lc_sqlerrm := SUBSTR(SQLERRM,1,250);
                                fnd_message.set_name ('FND', 'XX_GI_NULL_MEANING_99999');
                                lc_error_message := fnd_message.get;
                                gc_err_code := 'XX_GI_NULL_MEANING_99999';
                                gc_err_desc := lc_error_message || lc_sqlerrm;
                                XX_GI_RCV_ERR_PKG.XX_GI_INS_CUST_EXCEP(
                                                                      'XX_GI_NULL_MEANING_99999'
                                                                     ,'fnd_Meaning'
                                                                     ,99999
                                                                     ,gc_err_desc
                                                                     ,'XX_GI_ST2'
                                );
                                                            
                              WHEN OTHERS THEN
                                -- Log errors in error table 
                                lc_sqlerrm := SUBSTR(SQLERRM,1,250);
                                fnd_message.set_name ('FND', 'XX_GI_NULL_MEANING_99999');
                                lc_error_message := fnd_message.get;
                                gc_err_code := 'XX_GI_NULL_MEANING_99999';
                                gc_err_desc := lc_error_message || lc_sqlerrm;
                                XX_GI_RCV_ERR_PKG.XX_GI_INS_CUST_EXCEP(
                                                                       'XX_GI_NULL_MEANING_99999'
                                                                      ,'FND_MEANING'
                                                                      ,99999
                                                                      ,gc_err_desc
                                                                      ,'XX_GI_ST2'
                                );
                                                            
                            END;                           
                                                 
-- +=========================================================================================+
-- |           Inserting Receipt Sequence according to OU specific                           |
-- +=========================================================================================+
                              IF lc_meaning = 'XX_GI_RECEIPT_NUM_US_S' THEN
                                           
                                  SELECT xx_gi_receipt_num_us_s.NEXTVAL
                                  INTO   ln_rec_nex_id
                                  FROM   sys.dual;
                                              
                              ELSIF lc_meaning = 'XX_GI_RECEIPT_NUM_CA_S' THEN
                                         
                                   SELECT xx_gi_receipt_num_ca_s.NEXTVAL
                                   INTO   ln_rec_nex_id
                                   FROM   sys.dual;
                                              
                              ELSIF lc_meaning = 'XX_GI_RECEIPT_NUM_EU_S' THEN
                                         
                                   SELECT xx_gi_receipt_num_eu_s.NEXTVAL
                                   INTO   ln_rec_nex_id
                                   FROM   sys.dual;
                                          
                              END IF;      
                                                         
                              IF ln_rec_nex_id <> 0 THEN
                               -- Updating status = 'P' on Line level
                                IF lc_keyrec IS NULL THEN
                                   lc_keyrec := ln_rec_nex_id;
                                END IF;            
                                                                        
                                 UPDATE  xx_gi_rcv_str_hdr XGRH
                                 SET     XGRH.receipt_num       = ln_rec_nex_id
                                       , XGRH.attribute8        = lc_keyrec
                                       ,XGRH.e0342_status_flag  = 'P'
                                 WHERE  XGRH.ROWID              = lc_rowid;
                                                     
                                 UPDATE  xx_gi_rcv_str_dtl XGRD
                                 SET     XGRD.E0342_status_flag  = 'P' 
                                       , XGRD.attribute8         = lc_keyrec
                                 WHERE  XGRD.ROWID               = lcu_dtl_prcp_curr_rec(i).xgrd_rowid;
                                     
                              END IF;
                                     
                      ELSE
                         IF lc_keyrec IS NULL THEN
                            lc_keyrec := lc_receipt_num;
                         END IF;
                                            
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Header and Line P status update: Keyrec'||lc_keyrec);
                          UPDATE xx_gi_rcv_str_hdr XGRH
                          SET    XGRH.attribute8          = lc_keyrec
                                 ,XGRH.e0342_status_flag  = 'P'
                          WHERE  XGRH.ROWID               = lc_rowid;
                                                 
                          UPDATE xx_gi_rcv_str_dtl XGRD
                          SET    XGRD.e0342_status_flag   = 'P'
                                 ,XGRD.attribute8         = lc_keyrec
                        WHERE    XGRD.ROWID               = lcu_dtl_prcp_curr_rec(i).xgrd_rowid;
                      END IF;
             END LOOP;
-- +=========================================================================================+
-- |     Open 'OHRE' record cursor to perform corrections                                    |
-- +=========================================================================================+
         FOR lcu_dtl_ohre_curr_rec 
           IN  lcu_dtl_ohre_curr 
           LOOP
-- +=========================================================================================+
-- |  'OHRE' record cursor to perform corrections both shortage and overage cases            |
-- +=========================================================================================+
                  OPEN lcu_mtl_trans_curr(
                                          lcu_dtl_ohre_curr_rec.shipment_num
                                          ,lcu_dtl_ohre_curr_rec.item_num
                                          ,lcu_dtl_ohre_curr_rec.to_organization_id
                                         );
                  FETCH  lcu_mtl_trans_curr 
                   INTO  ln_transaction_qty
                         ,lc_shipment_number
                         ,ln_inventory_item_id
                         ,ln_organization_id 
                         ,ln_transfer_org_id;
                  CLOSE lcu_mtl_trans_curr;
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'OHRE Loop rec :'||' Qty :'||ln_transaction_qty
                 ||' Shipment Num :'||lc_shipment_number||' Item :'||ln_inventory_item_id
                 ||'To Org ID '||ln_transfer_org_id);
                    FOR  lcu_rcv_shipm_curr_rec
                      IN lcu_rcv_shipm_curr(
                                            lc_shipment_number 
                                            ,lcu_dtl_ohre_curr_rec.item_num
                                            ,lcu_dtl_ohre_curr_rec.to_organization_id
                                            ,lcu_dtl_ohre_curr_rec.from_organization_id
                                           )
                    LOOP    -- OHRE equal case  -- assume that OHRE(corrections) records have already receipt done 
-- +=========================================================================================+
-- |  'OHRE' equal case cursor records match                                                 |
-- +=========================================================================================+
                     IF ((lcu_rcv_shipm_curr_rec.quantity_shipped = lcu_rcv_shipm_curr_rec.quantity_received) 
                         AND  (lcu_rcv_shipm_curr_rec.quantity_received = lcu_dtl_ohre_curr_rec.quantity))  THEN  
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'OHRE Equal Quantity:'||lcu_rcv_shipm_curr_rec.quantity_received
                                 ||' : '||lcu_rcv_shipm_curr_rec.quantity_shipped);
                        DELETE FROM xx_gi_rcv_str_dtl 
                        WHERE interface_transaction_id = lcu_dtl_ohre_curr_rec.interface_transaction_id
                        AND   attribute4               = 'OHRE';
                        -- OHRE shortage case
-- +=========================================================================================+
-- |  'OHRE' shortage case cursor records and updation                                       |
-- +=========================================================================================+
                     ELSIF ((lcu_rcv_shipm_curr_rec.quantity_shipped = lcu_rcv_shipm_curr_rec.quantity_received) 
                           AND  (lcu_rcv_shipm_curr_rec.quantity_received > lcu_dtl_ohre_curr_rec.quantity)) THEN
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'OHRE Shortage Quantity'||'RCV Qty'||lcu_rcv_shipm_curr_rec.quantity_received
                                                      ||' Correction Qty : '||lcu_dtl_ohre_curr_rec.quantity);
                        UPDATE xx_gi_rcv_str_dtl
                        SET  e0342_status_flag ='STRD' 
                             ,subinventory     = 'CHARGEBACK'
                             ,quantity         = (lcu_rcv_shipm_curr_rec.quantity_received - lcu_dtl_ohre_curr_rec.quantity)
                        WHERE  ROWID           = lcu_dtl_ohre_curr_rec.ROWID;
                       -- OHRE overage case
-- +=========================================================================================+
-- |  'OHRE' overage  case cursor records and updation                                       |
-- +=========================================================================================+
                     ELSIF ((lcu_rcv_shipm_curr_rec.quantity_shipped=lcu_rcv_shipm_curr_rec.quantity_received) 
                            AND  (lcu_rcv_shipm_curr_rec.quantity_received<lcu_dtl_ohre_curr_rec.quantity)) THEN
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'OHRE Overage Quantity'||'RCV Qty'||lcu_rcv_shipm_curr_rec.quantity_received
                                                     ||' Correction Qty : '||lcu_dtl_ohre_curr_rec.quantity);
                      UPDATE xx_gi_rcv_str_dtl
                      SET    e0342_status_flag   = 'STR'
                             ,subinventory       = 'STOCK'
                             ,quantity           = (lcu_dtl_ohre_curr_rec.quantity-lcu_rcv_shipm_curr_rec.quantity_received)
                      WHERE  ROWID               = lcu_dtl_ohre_curr_rec.ROWID;
                     END IF;
                    END LOOP;
           END LOOP;
        COMMIT;
  END XX_GI_VAL_STR_RCV;
--------------------------------------------------------------------------------------------
-- +===================================================================+
-- |Name            :XX_GI_DIRECTORG_TRANSFER                          |
-- |Description     :This is the private  procedure which to perform   |
-- |                  Direct Org transfers                             |
-- |Parameters      :itemnum, trans_qty ,from_organization_id,         |
-- |                 to_organization_id,from_subinventory, uom,        |
-- |                 to_subinventory,uom,header_id,line_id             |
-- +===================================================================+
   PROCEDURE XX_GI_DIRECTORG_TRANSFER
                                  (
                                   p_itemnum   NUMBER
                                   ,p_trans_qty   NUMBER
                                   ,p_fr_organization_id   NUMBER
                                   ,p_to_organization_id   NUMBER
                                   ,p_from_subinventory   VARCHAR2
                                   ,p_to_subinventory   VARCHAR2
                                   ,p_uom   VARCHAR2
                                   ,p_header_id   NUMBER
                                   ,p_line_id   NUMBER
                                   ,p_shipment_num  VARCHAR2
                                  )
   IS
   PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
        INSERT      --+APPEND
        INTO mtl_transactions_interface( 
                                        source_code
                                        ,source_header_id
                                        ,source_line_id
                                        ,process_flag
                                        ,transaction_mode
                                        ,validation_required
                                        ,last_update_date
                                        ,last_updated_by
                                        ,creation_date
                                        ,created_by
                                        ,last_update_login
                                        ,organization_id
                                        ,transaction_quantity
                                        ,transaction_uom
                                        ,transaction_date
                                        ,transaction_type_id
                                        ,item_segment1   -- inventory_item_id
                                        ,subinventory_code
                                        ,transfer_subinventory
                                        ,transfer_organization
                                        ,attribute5
                                        )
                                         VALUES
                                        ('WMOS',  -- 'STRD Direct Transfer'
                                         p_header_id
                                         ,p_line_id  
                                         ,1
                                         ,3
                                         ,1 -- validation_required
                                         ,SYSDATE
                                         ,FND_GLOBAL.USER_ID
                                         ,SYSDATE
                                         ,FND_GLOBAL.USER_ID
                                         ,FND_GLOBAL.LOGIN_ID
                                         ,p_fr_organization_id  -- organization_id
                                         ,ABS(p_trans_qty)    --transaction_quantity
                                         ,nvl(p_uom,'EA')
                                         ,SYSDATE
                                         ,3
                                         ,p_itemnum --  itemnum  or inventory_item_id
                                         ,p_from_subinventory
                                         ,p_to_subinventory
                                         ,p_to_organization_id  --transfer_organization
                                         ,p_shipment_num
                                        );
                                        COMMIT;
   END XX_GI_DIRECTORG_TRANSFER;
-----------------------------------------------------------------------------------            
-- +===================================================================+
-- |Name            :XX_GI_INTERORG_TRANSFER                           |
-- |Description     :This is the private  procedure which to perform   |
-- |                  Intransit shipments                              |
-- |Parameters      :itemnum, trans_qty ,from_organization_id,         |
-- |                 to_organization_id,from_subinventory,             |
-- |                 to_subinventory,uom,header_id,line_id,shipment_num|
-- +===================================================================+
   PROCEDURE XX_GI_INTERORG_TRANSFER(p_itemnum     NUMBER
                                     ,p_trans_qty   NUMBER
                                     ,p_fr_organization_id   NUMBER
                                     ,p_to_organization_id   NUMBER
                                     ,p_from_subinventory    VARCHAR2
                                     ,p_to_subinventory      VARCHAR2
                                     ,p_uom           VARCHAR2
                                     ,p_header_id     NUMBER
                                     ,p_line_id       NUMBER
                                     ,p_shipment_num  VARCHAR2
                                    )
   IS
   ln_transaction_type_id     mtl_transaction_types.transaction_type_id%TYPE;
   PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
   SELECT transaction_type_id
   INTO   ln_transaction_type_id
   FROM   mtl_transaction_types 
   WHERE  UPPER(transaction_type_name) = UPPER('Intransit Shipment');
  
     INSERT      --+APPEND
     INTO mtl_transactions_interface 
                                   (source_code
                                    ,source_header_id
                                   ,source_line_id
                                    ,process_flag
                                    ,transaction_mode
                                    ,validation_required
                                    ,last_update_date
                                    ,last_updated_by
                                    ,creation_date
                                    ,created_by
                                    ,last_update_login
                                    ,organization_id
                                    ,transaction_quantity
                                    ,transaction_uom
                                    ,transaction_date
                                    ,transaction_type_id
                                    ,item_segment1
                                    ,subinventory_code
                                    ,transfer_subinventory
                                    ,transfer_organization
                                    ,attribute5
                                    )
                                    VALUES
                                    ('STR RTV Receipts' --source_code
                                    ,p_header_id --source_header_id
                                    ,p_line_id --source_line_id
                                    ,1--process_flag  
                                    ,3--transaction_mode
                                    ,1  -- Validation_required
                                    ,SYSDATE
                                    ,FND_GLOBAL.USER_ID
                                    ,SYSDATE
                                    ,FND_GLOBAL.USER_ID
                                    ,FND_GLOBAL.LOGIN_ID
                                    ,p_fr_organization_id-- organization_id
                                    ,ABS(p_trans_qty) --transaction_quantity
                                    ,nvl(p_uom,'EA') --transaction_uom
                                    ,SYSDATE --transaction_date 
                                    ,ln_transaction_type_id -- transaction_type_id 
                                    ,p_itemnum --item_segment1
                                    ,'CHARGEBACK' --subinventory_code
                                    ,'STOCK' --transfer_subinventory
                                    ,p_to_organization_id --transfer_organization
                                    ,p_shipment_num --shipment_number 
                                    );
                                    COMMIT;
   END XX_GI_INTERORG_TRANSFER;
-----------------------------------------------------------------------------------------------------
-- +===================================================================+
-- | Name           : GET_ORGANIZATION_CODE                            |
-- |Description     : This is the internal  Function  which to get     |
-- |                  organization code from given organization id     |
-- |Paramater       : organization_id                                  |
-- | Return         : organization_code                                |
-- +===================================================================+
 FUNCTION GET_ORGANIZATION_CODE(p_organization_id NUMBER)
      RETURN VARCHAR2
   AS
      lc_org_code              mtl_parameters.organization_code%TYPE := NULL;
   BEGIN
      BEGIN
         SELECT organization_code
         INTO   lc_org_code
         FROM   mtl_parameters
         WHERE  organization_id = p_organization_id;
      EXCEPTION
         WHEN OTHERS THEN
            lc_org_code                  :=NULL;
      END;
      RETURN (lc_org_code);
 END GET_ORGANIZATION_CODE;
------------------------------------------------------------------------------------------------------
-- +===================================================================+
-- |Name            : GET_ITEM_CODE                                    |
-- |Description     : This is the internal  function  which to get     |
-- |                   item name from given item id                    |
-- |Paramater       :  item_id,organization_id                         |
-- | Return         : item_name                                        |
-- +===================================================================+
 FUNCTION GET_ITEM_CODE(
                        p_item_id NUMBER
                        ,p_org_id NUMBER
                       )
      RETURN VARCHAR2
   AS
      lc_item_num    mtl_system_items_b.segment1%TYPE := NULL;
      lc_sqlcode     VARCHAR2(50);
      lc_sqlerrm     VARCHAR2(2000);
      lc_error_msg   VARCHAR2(2000);
   BEGIN
      BEGIN
         SELECT segment1
         INTO   lc_item_num
         FROM   mtl_system_items
         WHERE  inventory_item_id= p_item_id
         AND    organization_id=p_org_id;
      EXCEPTION
         WHEN OTHERS THEN
           lc_item_num:=NULL;
           lc_sqlerrm := SUBSTR (SQLERRM
                                ,1
                                ,200
                                );
           lc_error_msg:= 'Item ID ' ||p_item_id|| ' Not in Org '||p_org_id
                           ||' :  '||lc_sqlerrm;
           XX_GI_RCV_ERR_PKG.XX_GI_INS_CUST_EXCEP(
                                                  'STR_ITEM_OTHERS'
                                                  ,'ITEM_ID'
                                                  ,p_item_id
                                                  ,lc_error_msg
                                                  ,'XX_GI_ST'
           );
      END;
      RETURN (lc_item_num);
   END GET_ITEM_CODE;
   --------------------------------------------------------------------------------------------------------
-- +===================================================================+
-- |Name            : GET_ITEM_ID                                      |
-- |Description     : This is the internal  function  which to get     |
-- |                  item name from given item id                     |
-- |Paramater       : item_num,organization_id                         |
-- | Return         : item_id                                          |
-- +===================================================================+
   FUNCTION GET_ITEM_ID(
                         p_item_num VARCHAR2
                         ,p_org_id NUMBER
                        )
      RETURN NUMBER
   AS
      lc_item_id     mtl_system_items_b.inventory_item_id%TYPE := NULL;
      lc_sqlcode     VARCHAR2(50);
      lc_sqlerrm     VARCHAR2(2000);
      lc_error_msg   VARCHAR2(2000);
   BEGIN
      BEGIN
         SELECT inventory_item_id
         INTO   lc_item_id
         FROM   mtl_system_items
         WHERE  segment1= p_item_num
         AND    organization_id=p_org_id;
      EXCEPTION
         WHEN OTHERS THEN
           lc_item_id := NULL;
           lc_sqlerrm := SUBSTR (SQLERRM
                                 ,1
                                 ,200
                                );
           lc_error_msg:= ('Item Num ' ||p_item_num|| ' Not in Org '||p_org_id
                           ||' :  '||lc_sqlerrm);
           XX_GI_RCV_ERR_PKG.XX_GI_INS_CUST_EXCEP(
                                                  'STR_ITEM_OTHERS'
                                                  ,'ITEM_NUM'
                                                  ,p_item_num
                                                  ,lc_error_msg
                                                  ,'XX_GI_ST'
           );
      END;
      RETURN (lc_item_id);
   END GET_ITEM_ID;
   --------------------------------------------------------------------------------------------------------
-- +===================================================================+
-- | Name        : xx_gi_pop_rti_str_rcv                                |
-- | Description : This procedure will populate the standard oracle    |
-- |               receiving interface table.                          |
-- | Parameters : x_error_buff, x_ret_code                             |
-- +===================================================================+
                                                             
    -- Procedure 3 starts
  PROCEDURE XX_GI_POP_RTI_STR_RCV(
                                   x_err_buf         OUT VARCHAR2
                                  ,x_ret_code        OUT NUMBER
                                 )
    IS
                               
      lc_error_flag                            VARCHAR2(1);
      lc_status_flag                           VARCHAR2(4);
                                 
-- +===================================================================+
-- Cursor for Updating of staging table details                        |
-- +===================================================================+
   CURSOR lcu_cor_str_curr
   IS
   SELECT   XGRSD.interface_transaction_id
            ,XGRSD.item_id
            ,XGRSD.attribute7
            ,XGRSD.header_interface_id
   FROM xx_gi_rcv_str_dtl XGRSD
   WHERE 1=1 
   AND NOT EXISTS (
                   SELECT 1 
                   FROM rcv_transactions_interface RTI 
                   WHERE RTI.interface_transaction_id = XGRSD.interface_transaction_id
                   )
   AND E0342_status_flag = 'PL';
                                                           
   TYPE lt_cor_str_ty IS TABLE OF lcu_cor_str_curr%ROWTYPE
   INDEX BY BINARY_INTEGER;
                          
   lt_cor_str_typ  lt_cor_str_ty;
                                             
-- +===================================================================+
-- Cursor for entrying to error table                                  |
-- +===================================================================+
   CURSOR lcu_err_str_curr
   IS
   SELECT XGRSD.interface_transaction_id
   FROM   xx_gi_rcv_str_dtl XGRSD
   WHERE  XGRSD.E0342_status_flag = 'VE'
   AND EXISTS (
               SELECT 1
               FROM rcv_transactions_interface RTI
               WHERE upper(RTI.processing_status_code) = 'ERROR'
               AND   upper(RTI.transaction_status_code) = 'PENDING' 
               AND   RTI.interface_transaction_id = XGRSD.interface_transaction_id
               )
    AND XGRSD.E0346_status_flag = 'Y'
    AND NOT EXISTS 
                 (
                  SELECT 1 
                  FROM xx_gi_error_tbl XGERT
                  WHERE  XGERT.msg_code = 'XX_GI_UPD_VE_99999'  
                  AND    XGERT.entity_ref_id = XGRSD.interface_transaction_id
                  );
                                                           
    TYPE lt_err_str_ty IS TABLE OF lcu_err_str_curr%ROWTYPE
    INDEX BY BINARY_INTEGER;
                          
    lt_err_str_typ  lt_err_str_ty;
                                                
-- +===================================================================+
-- Cursor for Inserting Records in RHI and RTI                         |
-- +===================================================================+
    CURSOR lcu_str_int_curr
    IS
    SELECT   XGRSH.header_interface_id
           , XGRSH.group_id
           , XGRSH.last_update_date
           , XGRSH.last_updated_by
           , XGRSH.last_update_login
           , XGRSH.creation_date
           , XGRSH.created_by
           , XGRSH.shipment_num
           , XGRSH.vendor_name
           , XGRSH.vendor_site_code
           , XGRSH.from_organization_code
           , XGRSH.expected_receipt_date
           , XGRSH.shipped_date
           , XGRSH.ship_to_organization_code
           , XGRSH.transaction_date
           , XGRSH.currency_code
           , XGRSH.attribute1
           , XGRSH.attribute2
           , XGRSH.attribute3
           , XGRSH.attribute4
           , XGRSH.attribute5
           , XGRSH.attribute6
           , XGRSH.attribute7
           , XGRSH.attribute8
           , XGRSH.attribute9
           , XGRSH.attribute10
           , XGRSH.attribute11
           , XGRSH.attribute12
           , XGRSH.attribute13
           , XGRSH.attribute14
           , XGRSH.attribute15
           , XGRSH.asn_type
           , XGRSH.notice_creation_date
           , XGRSH.receipt_num
           , XGRSH.receipt_header_id
           , XGRSH.vendor_id
           , XGRSH.vendor_num
           , XGRSH.vendor_site_id
           , XGRSH.ship_to_organization_id
           , XGRSH.location_code
           , XGRSH.bill_of_lading
           , XGRSH.packing_slip
           , XGRSH.freight_carrier_code
           , XGRSH.num_of_containers
           , XGRSH.waybill_airbill_num
           , XGRSH.comments
           , XGRSH.gross_weight
           , XGRSH.gross_weight_uom_code
           , XGRSH.net_weight
           , XGRSH.net_weight_uom_code
           , XGRSH.tar_weight
           , XGRSH.tar_weight_uom_code
           , XGRSH.packaging_code
           , XGRSH.carrier_method
           , XGRSH.carrier_equipment
           , XGRSH.special_handling_code
           , XGRSH.hazard_code
           , XGRSH.hazard_class
           , XGRSH.hazard_description
           , XGRSH.freight_terms
           , XGRSH.freight_bill_number
           , XGRSH.invoice_num
           , XGRSH.invoice_date
           , XGRSH.total_invoice_amount
           , XGRSH.tax_name
           , XGRSH.tax_amount
           , XGRSH.freight_amount
           , XGRSH.conversion_rate_type
           , XGRSH.conversion_rate
           , XGRSH.conversion_rate_date
           , XGRSH.payment_terms_name
           , XGRSH.attribute_category
           , XGRSH.employee_name
           , XGRSH.invoice_status_code
           , XGRSH.customer_account_number
           , XGRSH.customer_party_name
           , XGRSH.E0342_status_flag
           , XGRSH.E0342_first_rec_time
           , XGRSD.transaction_type           typ
           , XGRSD.transaction_date           td
           , XGRSD.processing_status_code     psc
           , XGRSD.processing_mode_code       pmc
           , XGRSD.transaction_status_code    tsc
           , XGRSD.quantity
           , XGRSD.unit_of_measure
           , XGRSD.interface_source_code
           , XGRSD.inv_transaction_id
           , XGRSD.item_id
           , XGRSD.item_description
           , XGRSD.item_revision
           , XGRSD.uom_code                  
           , XGRSD.auto_transact_code        atc
           , XGRSD.primary_quantity          
           , XGRSD.primary_unit_of_measure    
           , XGRSD.receipt_source_code       rsc
           , XGRSD.from_subinventory         
           , XGRSD.source_document_code     
           , XGRSD.po_revision_num
           , XGRSD.po_unit_price
           , XGRSD.currency_code             cc
           , XGRSD.currency_conversion_type  cct
           , XGRSD.currency_conversion_rate  ccr
           , XGRSD.currency_conversion_date  ccd
           , XGRSD.substitute_unordered_code
           , XGRSD.receipt_exception_flag    
           , XGRSD.destination_type_code     
           , XGRSD.subinventory              
           , XGRSD.department_code           
           , XGRSD.shipment_num              sn
           , XGRSD.freight_carrier_code      fcc
           , XGRSD.bill_of_lading            bl
           , XGRSD.packing_slip              ps
           , XGRSD.shipped_date              sd
           , XGRSD.expected_receipt_date     erd
           , XGRSD.actual_cost               
           , XGRSD.transfer_cost             
           , XGRSD.transportation_cost       
           , XGRSD.num_of_containers         ncc
           , XGRSD.vendor_item_num           
           , XGRSD.comments                  c
           , XGRSD.attribute_category        ac
           , XGRSD.attribute1                a1
           , XGRSD.attribute2                a2
           , XGRSD.attribute3                a3
           , XGRSD.attribute4                a4
           , XGRSD.attribute5                a5
           , XGRSD.attribute6                a6
           , XGRSD.attribute7                a7
           , XGRSD.attribute8                a8
           , XGRSD.attribute9                a9
           , XGRSD.attribute10               a10
           , XGRSD.attribute11               a11
           , XGRSD.attribute13               a12
           , XGRSD.attribute14               a13
           , XGRSD.attribute15               a14
           , XGRSD.item_num
           , XGRSD.document_num
           , XGRSD.document_line_num
           , XGRSD.ship_to_location_code
           , XGRSD.item_category
           , XGRSD.location_code             lc
           , XGRSD.vendor_id                 vd
           , XGRSD.vendor_site_id            vsd
           , XGRSD.vendor_name               vn
           , XGRSD.vendor_num                vnu
           , XGRSD.vendor_site_code          vsc
           , XGRSD.from_organization_code    foc 
           , XGRSD.to_organization_code
           , XGRSD.to_organization_id
           , XGRSD.validation_flag           vf
           , XGRSD.E0342_status_flag         sf
           , XGRSD.E0342_first_rec_time      frt
           , XGRSD.po_header_id
           , XGRSD.po_line_id
           , XGRSD.po_line_location_id
           , XGRSD.po_distribution_id
           , XGRSD.shipment_header_id
           , XGRSD.shipment_line_id
           , XGRSD.currency_conversion_type
           , XGRSD.currency_conversion_rate
           , XGRSD.currency_conversion_date
           , XGRSD.deliver_to_location_id
           , XGRSD.interface_transaction_id
    FROM    xx_gi_rcv_str_hdr  XGRSH
           ,xx_gi_rcv_str_dtl  XGRSD
    WHERE   XGRSH.header_interface_id   =   XGRSD.header_interface_id  
    AND     XGRSD.E0342_status_flag = 'P';
                                                           
     TYPE lt_str_int_ty IS TABLE OF lcu_str_int_curr%ROWTYPE
     INDEX BY BINARY_INTEGER;
                          
     lt_str_int_typ  lt_str_int_ty;
                                                
     ln_count                                 NUMBER := 0;
     lc_pri_key                               VARCHAR2(20) := 0;
     ln_head_nex_id                           NUMBER ;
     ln_grp_nex_id                            NUMBER ;
     lc_meaning                               apps.fnd_lookup_values_vl.meaning%TYPE;
     ln_rec_nex_id                            NUMBER ;
     ln_tran_nex_id                           NUMBER ;
     lc_flag                                  VARCHAR2(1);
     lc_transaction_type                      VARCHAR2(25);
     lc_auto_transact_code                    VARCHAR2(25);
     lc_transaction_type_hdr                  VARCHAR2(25);
                                             
    BEGIN
-- +===================================================================+
-- Cursor for Updating of staging table details  for PL records        |
-- +===================================================================+
       OPEN lcu_cor_str_curr;
         FETCH lcu_cor_str_curr BULK COLLECT INTO lt_cor_str_typ;
          FOR i IN 1..lt_cor_str_typ.COUNT
          LOOP
-- +===================================================================+
-- |Updating xx_gi_rcv_po_hdr table with time stamp which              |
-- | This is required for Auto reciept after 24 hrs                    |
-- |    changing 'OHDS' to 'P'  status for Interorg reciepts           |
-- +===================================================================+
              UPDATE xx_gi_rcv_str_hdr 
              SET    E0342_first_rec_time = lt_cor_str_typ(i).attribute7 
              WHERE  header_Interface_id = lt_cor_str_typ(i).header_Interface_id;
          END LOOP;
          COMMIT;             
                                               
-- +=====================================================================+
-- Delete records from xx_gi_error_tbl exists in xx_gi_rcv_po_dtl table  |
-- +=====================================================================+
             DELETE 
             FROM xx_gi_error_tbl XGERT
             WHERE  1=1
             AND    EXISTS 
                           (
                            SELECT 1
                            FROM xx_gi_rcv_str_dtl XGRSD 
                            WHERE XGRSD.E0342_status_flag='PL'
                            AND   XGRSD.interface_transaction_id = XGERT.entity_ref_id
                            )
             AND    NOT EXISTS (
                                SELECT 1
                                FROM rcv_transactions_interface RTI 
                                WHERE RTI.interface_transaction_id = XGERT.entity_ref_id
                                );
                                                                         
-- +=================================================================================== +
-- | Delete records from xx_gi_rcv_po_dtl not exists in rcv_transactions_interface table|
-- |   at the time of re-submission                                                     |
-- +=================================================================================== +

              DELETE 
              FROM   xx_gi_rcv_str_dtl XGRSD
              WHERE  1 = 1
              AND    NOT EXISTS (
                                SELECT 1
                                FROM rcv_transactions_interface RTI 
                                WHERE RTI.interface_transaction_id = XGRSD.interface_transaction_id
                                )
              AND XGRSD.E0342_status_flag='PL';
-- +===================================================================+
-- Updating status to 'P' FOR BATCH ERROR                              |
-- +===================================================================+
              UPDATE xx_gi_rcv_str_dtl XGRSD
              SET    XGRSD.E0342_status_flag = 'P' 
              WHERE  1 = 1
              AND EXISTS (
                          SELECT 1
                          FROM rcv_transactions_interface RTI
                          WHERE upper(RTI.processing_status_code) = 'COMPLETED'
                          AND RTI.interface_transaction_id = XGRSD.interface_transaction_id
                          AND   upper(RTI.transaction_status_code) = 'ERROR'
                          )
              AND XGRSD.E0342_status_flag = 'PL';
                                            
-- +===================================================================+
-- |     Updating status to 'E' FOR REAL ERROR                         |
-- |     which will be picked by  e346  program                        |
-- +===================================================================+
               UPDATE xx_gi_rcv_str_dtl XGRSD
               SET    XGRSD.E0342_status_flag = 'E' 
               WHERE  1 = 1
               AND EXISTS (
                           SELECT 1
                            FROM rcv_transactions_interface RTI
                            WHERE upper(RTI.processing_status_code) = 'ERROR'
                            AND RTI.interface_transaction_id = XGRSD.interface_transaction_id
                            AND upper(RTI.transaction_status_code) = 'PENDING' 
                            )
                AND XGRSD.E0342_status_flag = 'PL' 
                AND XGRSD.E0346_status_flag <> 'Y';
                                           
-- +===================================================================+
-- |     Updating status to 'VE' FOR REAL ERROR                        |
-- |     WHERE E346 VALIDATION  IS ALREADY   PASSED                    |
-- +===================================================================+
                UPDATE xx_gi_rcv_str_dtl XGRSD
                SET    XGRSD.E0342_status_flag = 'VE' 
                WHERE  1 = 1
                AND EXISTS (
                            SELECT 1
                            FROM rcv_transactions_interface RTI
                            WHERE upper(RTI.processing_status_code) = 'ERROR'
                            AND RTI.interface_transaction_id = XGRSD.interface_transaction_id
                            AND upper(RTI.transaction_status_code) = 'PENDING' 
                            )
                AND XGRSD.E0342_status_flag = 'PL' 
                AND XGRSD.E0346_status_flag = 'Y';
                COMMIT;
                                                                   
-- +===================================================================+
-- Cursor for entrying to error table                                  |
-- +===================================================================+
         OPEN lcu_err_str_curr;
           FETCH lcu_err_str_curr BULK COLLECT INTO lt_err_str_typ;
            FOR i IN 1..lt_err_str_typ.COUNT
            LOOP
                                           
-- +===================================================================+
-- Log errors in error table                                           |
-- +===================================================================+
               XX_GI_RCV_ERR_PKG.XX_GI_INS_CUST_EXCEP(
                                                    'XX_GI_UPD_VE_99999'
                                                   ,'interface_transaction_id'
                                                   ,lt_err_str_typ(i).interface_transaction_id
                                                   ,'RTI Errored Records'
                                                   ,'XX_GI_PO3'
               );
                                                            
            END LOOP;
-- +=========================================================================+
-- Delete Records from rcv_transactions_interface exists in xx_gi_rcv_po_dtl |
-- +=========================================================================+
             DELETE FROM rcv_transactions_interface RTI
             WHERE 1 = 1
             AND EXISTS (
                        SELECT 1
                        FROM xx_gi_rcv_str_dtl XGRSD
                        WHERE XGRSD.E0342_status_flag = 'P'
                        AND RTI.interface_transaction_id = XGRSD.interface_transaction_id
                        );
                        
             -- Delete all ASN errors for the STR and line number  for ASN record only 
               DELETE FROM xx_gi_rcv_str_hdr XGRSH
               WHERE  XGRSH.attribute5||XGRSH.attribute3 IN (
                                                             SELECT XGRP1.attribute5||XGRP1.attribute3 
                                                             FROM xx_gi_rcv_str_hdr XGRP1 
                                                             WHERE XGRP1.asn_type = 'RECEIVE' 
                                                             AND XGRP1.E0342_status_flag = 'P'
                                                            ) 
               AND  XGRSH.asn_type = 'ASN';
                                          
-- +===================================================================+
-- Cursor for Clearing of staging table details                        |
-- +===================================================================+
         OPEN lcu_str_int_curr;
           FETCH lcu_str_int_curr BULK COLLECT INTO lt_str_int_typ;
            FOR i IN 1..lt_str_int_typ.COUNT
            LOOP
                                         
              IF lt_str_int_typ(i).asn_type = 'ASN' THEN
                 lc_transaction_type_hdr := 'SHIP';
                 lc_auto_transact_code   := 'SHIP';
                  lt_str_int_typ(i).receipt_num := NULL;
              ELSE
                 lc_transaction_type_hdr := 'NEW';
                 lc_auto_transact_code   := 'DELIVER';
              END IF; 
                 lc_meaning  := NULL;
                                     
-- +===================================================================+
-- Inserting Header records only                                       |
-- +===================================================================+
                   BEGIN
                     SELECT 'Y'
                     INTO lc_flag
                     FROM rcv_headers_interface 
                     WHERE header_interface_id = lt_str_int_typ(i).header_interface_id;
                   EXCEPTION
                      WHEN NO_DATA_FOUND THEN	
                          -- Insert Records into RHI
                          INSERT 
                          INTO rcv_headers_interface( 
                                                     header_interface_id   -- NOT NULL 
                                                    ,group_id 
                                                    ,processing_status_code  -- NOT NULL 
                                                    ,receipt_source_code    
                                                    ,transaction_type 
                                                    ,last_update_date     -- NOT NULL
                                                    ,last_updated_by      -- NOT NULL
                                                    ,last_update_login    
                                                    ,creation_date        -- NOT NULL
                                                    ,created_by           -- NOT NULL 
                                                    ,shipment_num
                                                    ,shipped_date 
                                                    ,validation_flag 
                                                    ,ship_to_organization_code
                                                    ,from_organization_code
                                                    ,auto_transact_code
                                                    ,expected_receipt_date
                                                    ,receipt_num
                                                    ,attribute1
                                                    ,attribute2
                                                    ,attribute3
                                                    ,attribute4
                                                    ,attribute5
                                                    ,attribute6
                                                    ,attribute7
                                                    ,attribute8
                                                    ,attribute9
                                                    ,attribute10
                                                    ,attribute11
                                                    ,attribute12
                                                    ,attribute13
                                                    ,attribute14
                                                    ,attribute15
                                                    ,asn_type
                                                    ,receipt_header_id
                                                    ,ship_to_organization_id
                                                    )
                                                     SELECT
                                                      lt_str_int_typ(i).header_interface_id 
                                                     ,lt_str_int_typ(i).group_id
                                                     ,'PENDING'            --processing_status_code
                                                     ,'INVENTORY'
                                                     ,lc_transaction_type_hdr  --transaction_type  'NEW' 
                                                     ,lt_str_int_typ(i).last_update_date 
                                                     ,lt_str_int_typ(i).last_updated_by 
                                                     ,lt_str_int_typ(i).last_update_login
                                                     ,lt_str_int_typ(i).creation_date
                                                     ,lt_str_int_typ(i).created_by 
                                                     ,lt_str_int_typ(i).shipment_num
                                                     ,lt_str_int_typ(i).shipped_date 
                                                     ,'N'                                 --validation_flag  
                                                     ,lt_str_int_typ(i).ship_to_organization_code
                                                     ,lt_str_int_typ(i).from_organization_code 
                                                     ,lc_auto_transact_code  --auto_transact_code 'DELIVER'
                                                     ,NVL(lt_str_int_typ(i).expected_receipt_date,SYSDATE) 
                                                     ,lt_str_int_typ(i).receipt_num
                                                     ,lt_str_int_typ(i).attribute1
                                                     ,lt_str_int_typ(i).attribute2
                                                     ,lt_str_int_typ(i).attribute3
                                                     ,lt_str_int_typ(i).attribute4
                                                     ,lt_str_int_typ(i).attribute5
                                                     ,lt_str_int_typ(i).attribute6
                                                     ,lt_str_int_typ(i).attribute7
                                                     ,lt_str_int_typ(i).attribute8
                                                     ,lt_str_int_typ(i).attribute9
                                                     ,lt_str_int_typ(i).attribute10
                                                     ,lt_str_int_typ(i).attribute11
                                                     ,lt_str_int_typ(i).attribute12
                                                     ,lt_str_int_typ(i).attribute13
                                                     ,lt_str_int_typ(i).attribute14
                                                     ,lt_str_int_typ(i).attribute15
                                                     ,lt_str_int_typ(i).asn_type
                                                     ,lt_str_int_typ(i).receipt_header_id
                                                     ,lt_str_int_typ(i).ship_to_organization_id
                                                    FROM sys.DUAL;
                                                      
                   END;
                   IF lt_str_int_typ(i).asn_type = 'ASN' THEN
                      lc_transaction_type := 'SHIP';
                   ELSE
                      lc_transaction_type := 'RECEIVE';
                   END IF; 
-- +===================================================================+
-- Insert Records into RHI                                             |
-- +===================================================================+
                          INSERT 
                          INTO rcv_transactions_interface( 
                                                          interface_transaction_id  -- NOT NULL 
                                                         ,header_interface_id 
                                                         ,group_id 
                                                         ,last_update_date        -- NOT NULL
                                                         ,last_updated_by         -- NOT NULL 
                                                         ,last_update_login 
                                                         ,creation_date           -- NOT NULL
                                                         ,created_by              -- NOT NULL 
                                                         ,transaction_type        -- NOT NULL 
                                                         ,transaction_date        -- NOT NULL 
                                                         ,processing_status_code  -- NOT NULL 
                                                         ,processing_mode_code    -- NOT NULL 
                                                         ,transaction_status_code -- NOT NULL 
                                                         ,quantity 
                                                         ,unit_of_measure 
                                                         ,receipt_source_code  -- This is not in the table
                                                         ,source_document_code
                                                         ,destination_type_code
                                                         ,shipment_header_id
                                                         ,shipment_line_id 
                                                         ,validation_flag
                                                         ,auto_transact_code
                                                         ,subinventory
                                                         ,currency_code
                                                         ,currency_conversion_type
                                                         ,currency_conversion_rate
                                                         ,currency_conversion_date
                                                         ,deliver_to_location_id
                                                         ,attribute1
                                                         ,attribute2
                                                         ,attribute3
                                                         ,attribute4
                                                         ,attribute5
                                                         ,attribute6
                                                         ,attribute7
                                                         ,attribute8
                                                         ,attribute9
                                                         ,attribute10
                                                         ,attribute11
                                                         ,attribute12
                                                         ,attribute13
                                                         ,attribute14
                                                         ,attribute15
                                                         ,expected_receipt_date
                                                         )       
                                                         SELECT
                                                         lt_str_int_typ(i).interface_transaction_id 
                                                        ,lt_str_int_typ(i).header_interface_id 
                                                        ,lt_str_int_typ(i).group_id 
                                                        ,lt_str_int_typ(i).last_update_date 
                                                        ,lt_str_int_typ(i).last_updated_by 
                                                        ,lt_str_int_typ(i).last_update_login 
                                                        ,lt_str_int_typ(i).creation_date 
                                                        ,lt_str_int_typ(i).created_by 
                                                        ,lc_transaction_type                --transaction_type , 
                                                        ,NVL(lt_str_int_typ(i).transaction_date,SYSDATE) 
                                                        ,'PENDING'            --processing_status_code ,
                                                        ,'BATCH'             --processing_mode_code ,
                                                        ,'PENDING'             --transaction_status_code , 
                                                        ,lt_str_int_typ(i).quantity 
                                                        ,lt_str_int_typ(i).unit_of_measure 
                                                        ,'INVENTORY' -- receipt_source_code 
                                                        ,'INVENTORY'               --source_document_code , 
                                                        ,'INVENTORY'
                                                        ,lt_str_int_typ(i).shipment_header_id
                                                        ,lt_str_int_typ(i).shipment_line_id
                                                        ,'N'                       --validation_flag,
                                                        ,lc_auto_transact_code       --auto_transact_code,
                                                        ,'STOCK'                   --subinventory,
                                                        ,lt_str_int_typ(i).currency_code
                                                        ,lt_str_int_typ(i).currency_conversion_type
                                                        ,lt_str_int_typ(i).currency_conversion_rate
                                                        ,lt_str_int_typ(i).currency_conversion_date
                                                        ,lt_str_int_typ(i).deliver_to_location_id
                                                        ,lt_str_int_typ(i).attribute1
                                                        ,lt_str_int_typ(i).attribute2
                                                        ,lt_str_int_typ(i).attribute3
                                                        ,lt_str_int_typ(i).attribute4
                                                        ,lt_str_int_typ(i).attribute5
                                                        ,lt_str_int_typ(i).attribute6
                                                        ,lt_str_int_typ(i).attribute7
                                                        ,lt_str_int_typ(i).attribute8
                                                        ,lt_str_int_typ(i).attribute9
                                                        ,lt_str_int_typ(i).attribute10
                                                        ,lt_str_int_typ(i).attribute11
                                                        ,lt_str_int_typ(i).attribute12
                                                        ,lt_str_int_typ(i).attribute13
                                                        ,lt_str_int_typ(i).attribute14
                                                        ,lt_str_int_typ(i).attribute15
                                                        ,NVL(lt_str_int_typ(i).expected_receipt_date,SYSDATE)
                                                        FROM sys.DUAL;
                                           
-- +===================================================================+
-- Updating 'PL' Records                                               |
-- +===================================================================+
                          UPDATE xx_gi_rcv_str_dtl  XGRSD
                          SET   XGRSD.E0342_status_flag  = 'PL' 
                          WHERE XGRSD.interface_transaction_id = lt_str_int_typ(i).interface_transaction_id;
            END LOOP;
                                                 
            COMMIT; 
  END    XX_GI_POP_RTI_STR_RCV;
END XX_GI_RCV_STR_PKG;
/
SHOW ERR