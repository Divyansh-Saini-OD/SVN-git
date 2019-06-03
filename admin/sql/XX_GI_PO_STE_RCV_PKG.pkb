SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET FEEDBACK     OFF
SET TAB          OFF
SET TERM         ON
CREATE OR REPLACE
PACKAGE BODY XX_GI_PO_STE_RCV_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        :  XX_GI_PO_STE_RCV_PKG                               |
-- | Description : Implemented to perform the PO Online Receipts and   |
-- |               online  Interorg Receipts of the RICE ID            |
-- |                 E0342a Receiving is the process of receiving      |
-- |               inventory into a location or organization.          |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0      27-Jul-2007  Rahul Bagul           Initial version        |
-- |                                                                   |
-- +===================================================================+
AS
-- +===================================================================+
-- | Name        : xx_gi_ins_online_rcv_proc                           |
-- | Description : This procedure will be invoked by the external      |
-- |               process which will be validating record one by one  |
-- |               before inserting into receiving interface table     |
-- |               with all the mandatory columns                      |
-- | Parameters : x_error_buff, x_ret_code,p_ins_rec_tab               |
-- |              p_commingling_receipts                               |
-- +===================================================================+
gn_dup_keyrec  VARCHAR2(10);
gn_interface_transaction_id NUMBER;

PROCEDURE XX_GI_INS_ONLINE_RCV_PROC(
                        x_errbuff               OUT VARCHAR2
                       ,x_retcode               OUT NUMBER
                       ,x_error_msg             OUT VARCHAR2
                       ,p_ins_rec_tab           IN  OUT lt_ins_rec_online_tab
                       ,p_commingling_receipts  IN  VARCHAR2
          )
AS
lc_error_loc                             VARCHAR2(2000);
lc_error_msg                             VARCHAR2(2000);
lc_error_debug                           VARCHAR2(2000);
lc_error_flag                            VARCHAR2(1);
lc_organization_code                     org_organization_definitions.organization_code%TYPE;
lc_from_organization_code                org_organization_definitions.organization_code%TYPE;
ln_quantity                              NUMBER;
ln_num_cnt                               NUMBER;
ln_vendor_id                             NUMBER;
ln_vendor_site_id                        NUMBER;
lc_vendor_name                           VARCHAR2(240);
ln_shipment_header_id                    NUMBER;
ln_shipment_line_id                      NUMBER;
ln_from_organization_id                  NUMBER;
lc_pri_key                               VARCHAR2(20) := 0;
ln_head_nex_id                           NUMBER;
ln_grp_nex_id                            NUMBER;
ln_trx_nex_id                            NUMBER;
ln_tran_nex_id                           NUMBER;
lc_po_number                             VARCHAR2(20);
ln_count                                 NUMBER := 0;
--lc_error_message_code                    xx_com_error_log.error_message_code%TYPE;
--lc_object_id                             xx_com_error_log.object_id%TYPE;
--lc_object_type                           xx_com_error_log.object_type%TYPE;
lc_meaning                               fnd_lookup_values_vl.meaning%TYPE;
ln_rec_nex_id                            NUMBER;
ln_item_id                               NUMBER;
lc_ve_err_msg                            VARCHAR2(2000);
ln_commit_cnt                            NUMBER;
lc_rhi_attribute2                        VARCHAR2(150);
lc_rhi_attribute5                        VARCHAR2(150);
lc_rhi_attribute1                        VARCHAR2(150);
lc_rhi_attribute4                        VARCHAR2(150);
lc_rhi_attribute8                        VARCHAR2(150);
lc_E0342_flag                            VARCHAR2(10);
ln_po_header_id                          NUMBER;
ln_inventory_item_id                     NUMBER;
ln_vendor_id_comm                        NUMBER ;
ln_vendor_site_id_comm                   NUMBER ;
lc_attribute8_comm                       VARCHAR2(150);
lc_attribute8                            VARCHAR2(150);
lc_receipt_num                           VARCHAR2(150);
lc_keyrec                                VARCHAR2(150);
ln_received_qty                          NUMBER;
ln_invoiced_qty                          NUMBER;
ln_tran_id_deliver                       NUMBER;
ln_tran_id_receiving                     NUMBER;
ln_shortage_qty                          NUMBER;
ln_interface_transaction_id              NUMBER;
lc_rowid                                 VARCHAR2(150);
lc_transaction_type                      VARCHAR2(25);
lc_flag                                  VARCHAR2(1);
ln_receipt_num                           NUMBER;
ln_master_org_id                         NUMBER;
ln_sqlpoint                              NUMBER;
lc_segment1                              VARCHAR2(240);
lc_key_rec_flag                          VARCHAR2(1);
  
-- +===================================================================+
-- | Variables used for validation of INTERORG records                 |
-- +===================================================================+
ln_trx_quantity                          NUMBER;
lc_shipment_number                       VARCHAR2(50):= NULL;
gc_err_code                              xxptp.xx_gi_error_tbl.msg_code%type;
gc_err_desc                              xxptp.xx_gi_error_tbl.msg_desc%type;
lc_to_org_consgn_flag                    VARCHAR2(1); --  To Org Consignment flag
lc_from_org_consgn_flag                  VARCHAR2(1); --  From Org Consignment flag
ln_transaction_qty                       NUMBER;
ln_organization_id                       NUMBER;
ln_transfer_org_id                       NUMBER;
lc_transaction_type_hdr                  VARCHAR2(30) := 'NEW';
lc_auto_transact_code                    VARCHAR2(30)  := 'DELIVER';
BEGIN
-- +===================================================================+
-- | SET PROFILE VALUE FOR APPROPRIATE OPERATING UNIT (ORG ID)         |
-- +===================================================================+
     
     BEGIN
       FND_CLIENT_INFO.SET_ORG_CONTEXT(FND_PROFILE.VALUE('ORG_ID'));
     END;
  FOR i
  IN  p_ins_rec_tab.FIRST.. p_ins_rec_tab.LAST
  LOOP
ln_sqlpoint:=10;
dbms_output.put_line('Inside Main Begin '||ln_sqlpoint);
     ln_item_id                := NULL;
     lc_ve_err_msg             := NULL;
     lc_error_flag             := 'N';
     lc_meaning                := NULL;
     ln_vendor_id              := NULL;
     ln_vendor_site_id         := NULL;
     ln_vendor_id_comm         := NULL;
     ln_vendor_site_id_comm    := NULL;
     lc_key_rec_flag           := 'N';  -- flag for KEY type rec insert only to HDR tables
     ln_sqlpoint:=20;
         -- Assign from_organization_code and to_organization_code to a variable
         lc_from_organization_code := p_ins_rec_tab(i).rti_from_organization_code;
         lc_organization_code      := p_ins_rec_tab(i).rhi_ship_to_organization_code;
         lc_rhi_attribute1         := p_ins_rec_tab(i).rhi_attribute1;
         lc_rhi_attribute2         := p_ins_rec_tab(i).rhi_attribute2;
         lc_rhi_attribute4         := p_ins_rec_tab(i).rhi_attribute4;
         lc_rhi_attribute5         := p_ins_rec_tab(i).rhi_attribute5;
         lc_rhi_attribute8         := p_ins_rec_tab(i).rhi_attribute8;
         dbms_output.put_line('lc_from_organization_code '||lc_from_organization_code);
         dbms_output.put_line('lc_organization_code  '||lc_organization_code );
         dbms_output.put_line('lc_rhi_attribute2 '||lc_rhi_attribute2);
         dbms_output.put_line('lc_rhi_attribute1 '||lc_rhi_attribute1);
         
         IF (p_ins_rec_tab(i).rhi_ship_to_organization_code IS NULL 
             AND p_ins_rec_tab(i).rhi_attribute2 IS NULL) THEN
            lc_error_flag := 'Y';
            x_error_msg  := 'To_Organization_Code AND Source to location_code is NULL';
            dbms_output.put_line('Inside ship_to_organization_code and attribute2 null '||ln_sqlpoint);
            EXIT;
         ELSE
            IF (p_ins_rec_tab(i).rhi_ship_to_organization_code IS NULL) THEN
               -- calling the function for to get ship_to_organization_id
-- +===================================================================+
-- | GETTTING APPROPRIATE ID FOR BELOW FIELD  forORGANIZATION CODE     |
-- +===================================================================+
               gn_ship_to_organization_id := XX_GI_COMN_UTILS_PKG.GET_EBS_ORGANIZATION_ID(p_ins_rec_tab(i).rhi_attribute2);
               dbms_output.put_line('gn_ship_to_organization_id=  '||gn_ship_to_organization_id);
                    ln_sqlpoint:=30;
               BEGIN
                  SELECT organization_code
                  INTO   lc_organization_code
                  FROM   org_organization_definitions
                  WHERE  organization_id = NVL(gn_ship_to_organization_id,0);
                  dbms_output.put_line('lc_organization_code=  '||lc_organization_code);
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     lc_error_flag := 'Y';
                     x_error_msg  := 'Organization_Code is null';
                     dbms_output.put_line('organization_code not found--no data found '||ln_sqlpoint);
                     EXIT;
                  WHEN OTHERS THEN
                     lc_error_flag := 'Y';
                     x_error_msg  := 'Organization_Code is null';
                     dbms_output.put_line('organization_code not found--when others'||ln_sqlpoint);
                     EXIT;
               END;
            ELSE
                    ln_sqlpoint:=40;
               BEGIN
                  SELECT organization_id
                  INTO   gn_ship_to_organization_id
                  FROM   org_organization_definitions
                  WHERE  organization_code = NVL(lc_organization_code,0);
                  -- calling the function for legacy_organization_code (source to)
                  lc_rhi_attribute2 := XX_GI_COMN_UTILS_PKG.GET_LEGACY_LOC_ID(gn_ship_to_organization_id);
                  dbms_output.put_line('lc_rhi_attribute2=  '||lc_rhi_attribute2);
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     lc_error_flag := 'Y';
                     x_error_msg  := 'Organization_id is null';
                     dbms_output.put_line('organization_id not found--no data found'||ln_sqlpoint);
                     EXIT;
                  WHEN OTHERS THEN
                     lc_error_flag := 'Y';
                     x_error_msg  := 'Organization_id is null';
                     dbms_output.put_line('organization_id not found--when others'||ln_sqlpoint);
                     EXIT;
               END;
            END IF;
         END IF;
-- +=========================================================================================+
-- | IDENTIFYING TYPE OF INBOUND RECORD FOR APPROPRIATE PROCESSING (ATTRIBUTE 4)             |
-- | KEYR  - KEY REC CREATION     (INSERT ONLY STG HEADER)                                   |
-- | KEYM  - KEY REC MAINTENANCE  (UPDATE CARTON COUNT ALONE FOR KEYREC  DOC                 |
-- | KEYCL - KEY REC CLOSE        (UPDATE A4 FOR ALL KEYREC  DOC COMBINATION)                |
-- | OHDR  - KEY REC HDR  DTL    (INSERT BOTH HDR  DTL OF STG  RTI                           |
-- | RVSC  - KEY REC HDR  DTL    (ZERO RECEIPTS INSERT BOTH STG   RTI FOR CHARGE BACK        |
-- +=========================================================================================+
  
         -- Validation for Attribute4
         IF SUBSTR(p_ins_rec_tab(i).rhi_attribute4,1,4) NOT IN ('OHDR','KEYCL','OHRE', 'KEYM', 'KEYR','RVSC') THEN
                    ln_sqlpoint:=50;
            lc_error_flag := 'Y';
            x_error_msg  := 'Attribute4 not in OHDR,KEYCL,OHRE, KEYM, KEYR,RVSC';
           dbms_output.put_line('Attribute4 not in OHDR,KEYCL,OHRE, KEYM, KEYR,RVSC'||ln_sqlpoint);
            EXIT;
         END IF;
              -- check to change only KEY  
           IF SUBSTR(p_ins_rec_tab(i).rhi_attribute4,1,4) IN ('KEYCL','KEYM', 'KEYR') THEN
           lc_key_rec_flag :='Y';
           END IF;
-- +=========================================================================================+
-- | VALIDATION TO CHECK DTL HAS ALWAYS ITEM NUM AND QUANTITY APPLICABLE ONLY FOR A4         |
-- | OHDR  - KEY REC HDR   DTL    (INSERT BOTH HDR   DTL OF STG   RTI                        |
-- | RVSC  - KEY REC HDR   DTL    (ZERO RECEIPTS INSERT BOTH STG   RTI   CHARGE BACK         |
-- +=========================================================================================+
         -- Validation for Quantity, Item Num
         IF p_ins_rec_tab(i).rti_quantity IS NULL
             AND p_ins_rec_tab(i).rti_item_num IS NULL
             AND p_ins_rec_tab(i).rhi_attribute3 IS NULL THEN
                    ln_sqlpoint:=60;  
           dbms_output.put_line('quantity,rti_item_num,rhi_attribute3 IS NULL '||ln_sqlpoint);
            NULL;
                                                
         ELSIF p_ins_rec_tab(i).rti_quantity IS NOT NULL
                AND (p_ins_rec_tab(i).rti_item_num IS NOT NULL
                     OR p_ins_rec_tab(i).rhi_attribute3 IS NOT NULL) THEN
                    ln_sqlpoint:=70;                                                
            -- Copy Item_Num to P_RTI_Attribute3 or viceversa, whichever is null
            IF p_ins_rec_tab(i).rti_item_num IS NOT NULL 
                AND p_ins_rec_tab(i).rhi_attribute3 IS NULL THEN
                                                
                    p_ins_rec_tab(i).rhi_attribute3   := p_ins_rec_tab(i).rti_item_num;
                    dbms_output.put_line('p_ins_rec_tab(i).rhi_attribute3=  '||p_ins_rec_tab(i).rhi_attribute3);                                                
            END IF;
                                                
            IF p_ins_rec_tab(i).rti_item_num IS NULL 
                AND p_ins_rec_tab(i).rhi_attribute3 IS NOT NULL THEN
                                                
                    p_ins_rec_tab(i).rti_item_num   := p_ins_rec_tab(i).rhi_attribute3;
                    dbms_output.put_line('p_ins_rec_tab(i).rti_item_num =  '||p_ins_rec_tab(i).rti_item_num);  
            END IF;
                                          
            IF NOT p_ins_rec_tab(i).rti_quantity  >= 1 THEN--OR  p_ins_rec_tab(i).rti_quantity  < 0 THEN
               ln_sqlpoint:=80;                                 
               lc_error_flag := 'Y';
               x_error_msg  := 'Quantity is equal to 0 or negative';
               dbms_output.put_line('Quantity is equal to 0 or negative '||ln_sqlpoint);  
               EXIT;
            END IF;
            
         END IF;
-- +==========================================================================+
-- | VALIDATION FOR TO RELPLACE UPC/VPC IF EXISTS ELSE CHECK IN ITEM          | 
-- | MASTER AND GIVE APPROPRIATE MESSAGE - ITEM NOT IN ORG OR NOT IN MASTER G |
-- +===========================================================================+
                 -- get master inventory org
                 BEGIN
                   SELECT   master_organization_id
                   INTO     ln_master_org_id
                   FROM     mtl_parameters
                   WHERE    organization_id = gn_ship_to_organization_id;
                 EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                     lc_error_flag := 'Y';
                     x_error_msg  := 'Master_organization_id does not exist';
                     dbms_output.put_line('master_organization_id not found--no data found'||ln_sqlpoint);
                     EXIT;
                     WHEN OTHERS THEN
                     lc_error_flag := 'Y';
                     x_error_msg  := 'Master_organization_id does not exist';
                     dbms_output.put_line('Master_organization_id not found--when others'||ln_sqlpoint);
                     EXIT;
                 END;
                 -- check whether item exists in item master or not
                 BEGIN
                    SELECT inventory_item_id
                    INTO   ln_inventory_item_id
                    FROM   mtl_system_items_b
                    WHERE  organization_id = ln_master_org_id
                    AND    segment1        = p_ins_rec_tab(i).rti_item_num ;
                 EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                     lc_error_flag := 'Y';
                     x_error_msg  := 'Item  does not exists in Item Master';
                     dbms_output.put_line('Item  does not exists in Item Master--no data found'||ln_sqlpoint);
                     EXIT;
                    WHEN OTHERS THEN
                     lc_error_flag := 'Y';
                     x_error_msg  := 'Item  does not exists in Item Master';
                     dbms_output.put_line('Item  does not exists in Item Master--no data found'||ln_sqlpoint);
                     EXIT;
                 END;
-- +===================================================================+
-- | VALIDATION FOR RECEIPT NUMBER    ATTRIBUTE 8                      |
-- +===================================================================+
         
         IF p_ins_rec_tab(i).rhi_receipt_num IS NULL
             AND p_ins_rec_tab(i).rhi_attribute8 IS NULL THEN
            lc_error_flag := 'Y';
             ln_sqlpoint:=100;
           dbms_output.put_line('receipt_num,rhi_attribute8 IS NULL '||ln_sqlpoint);  
         END IF;
            
-- +===================================================================+
-- | PO RECIPTS  VALIDATION STARTS  HERE                               |
-- +===================================================================+
         IF p_ins_rec_tab(i).rhi_receipt_source_code = 'VENDOR' THEN
                    ln_sqlpoint:=110;                                                
                    dbms_output.put_line('Validation for PO receipts starts '||ln_sqlpoint);  
-- +===================================================================+
-- | ERROR OUT ONLINE PO RECORD IF DOC NUM AND ATTR5 NOT EXITS         |
-- +===================================================================+
            IF p_ins_rec_tab(i).rhi_attribute5 IS NULL 
                AND p_ins_rec_tab(i).rti_document_num IS NULL THEN
                    ln_sqlpoint:=120;
                    dbms_output.put_line('rhi_attribute5,rti_document_num IS NULL '||ln_sqlpoint);  
               lc_error_flag := 'Y';
               x_error_msg  := 'Attribute5 and Document_num is null';
               EXIT;
            ELSE
                  
               -- Copy Document Num to P_RTI_Attribute5 or viceversa, whichever is null
               IF p_ins_rec_tab(i).rhi_attribute5  IS NOT NULL 
                   AND p_ins_rec_tab(i).rti_document_num IS  NULL THEN
                                                
                       p_ins_rec_tab(i).rti_document_num   := p_ins_rec_tab(i).rhi_attribute5;
                      dbms_output.put_line('p_ins_rec_tab(i).rti_document_num= '||p_ins_rec_tab(i).rti_document_num);  
               END IF;
                                                          
               IF p_ins_rec_tab(i).rhi_attribute5  IS NULL 
                   AND p_ins_rec_tab(i).rti_document_num IS NOT NULL THEN
                                                
                       p_ins_rec_tab(i).rhi_attribute5 := p_ins_rec_tab(i).rti_document_num;
                    dbms_output.put_line('p_ins_rec_tab(i).rhi_attribute5 = '||p_ins_rec_tab(i).rhi_attribute5);  
               END IF;
                                                
            END IF;
-- +===================================================================+
-- | VALIDATION FOR VENDOR AND VENDOR SITE BASED ON DOC NUMBER         |
-- +===================================================================+
                    ln_sqlpoint:=130;
            BEGIN
               SELECT po_header_id
                     ,vendor_id
                     ,vendor_site_id 
               INTO   ln_po_header_id
                     ,ln_vendor_id
                     ,ln_vendor_site_id
               FROM   po_headers_all 
               WHERE  segment1 = p_ins_rec_tab(i).rti_document_num;
               
               SELECT LTRIM(RTRIM(vendor_name))
               INTO   lc_vendor_name
               FROM   po_vendors
               WHERE  vendor_id=ln_vendor_id;
               dbms_output.put_line('ln_po_header_id = '||ln_po_header_id);
               dbms_output.put_line('ln_vendor_id = '||ln_vendor_id);
               dbms_output.put_line('ln_vendor_site_id = '||ln_vendor_site_id);
               dbms_output.put_line('lc_vendor_name = '||lc_vendor_name);
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                 lc_error_flag := 'Y';
                 x_error_msg  := 'po_header_id,vendor_id and vendor_site_id does not exist';
                    ln_sqlpoint:=140;
                    dbms_output.put_line('po_header_id,vendor_id and vendor_site_id does not exist-no-data-found'||ln_sqlpoint); 
                 EXIT;
               WHEN OTHERS THEN
                 lc_error_flag := 'Y';
                 x_error_msg  := 'po_header_id,vendor_id and vendor_site_id does not exist';
                    ln_sqlpoint:=150;
                    dbms_output.put_line('po_header_id,vendor_id and vendor_site_id does not exist-when others'||ln_sqlpoint); 
                 EXIT;
            END;
-- +===================================================================+
-- | VALIDATION FOR ASL                                                |
-- +===================================================================+
                BEGIN
                    ln_sqlpoint:=160;
                   -- To check vendor and sku combination from PO exists in the ASL
                   SELECT    PHA.segment1
                   INTO      lc_segment1
                   FROM      po_approved_supplier_list PASL
                            ,po_lines_all    PLA
                            ,po_headers_all  PHA
                   WHERE     PASL.owning_organization_id = gn_ship_to_organization_id
                   AND       PASL.item_id = ln_inventory_item_id
                   AND       PASL.asl_status_id = 2
                   AND       PASL.disable_flag IS NULL
                   AND       PASL.vendor_id = ln_vendor_id
                   AND       NVL(PASL.vendor_site_id, ln_vendor_site_id) = ln_vendor_site_id
                   AND       PASL.item_id = PLA.item_id
                   AND       PLA.po_header_id =PHA.po_header_id
                   AND       PHA.po_header_id =ln_po_header_id
                   AND       PHA.vendor_id = ln_vendor_id
                   AND       PHA.vendor_site_id = ln_vendor_site_id;
                EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                      lc_error_flag  := 'Y';
                      x_error_msg  := 'vendor and sku combination from PO does not exists in the ASL';
                    ln_sqlpoint:=170;
                    dbms_output.put_line('vendor and sku combination from PO does not exists in the ASL-no data found'||ln_sqlpoint); 
                      EXIT;
                   WHEN OTHERS THEN
                      lc_error_flag  := 'Y';
                      x_error_msg  := 'vendor and sku combination from PO does not exists in the ASL';
                     ln_sqlpoint:=180;
                     dbms_output.put_line('vendor and sku combination from PO does not exists in the ASL-when others'||ln_sqlpoint); 
                      EXIT;
                END;
-- +===================================================================+
-- | VALIDATION FOR CO-MINGLING CONSIGNMENT AND NON-CONSIGNMENT        |
-- +===================================================================+
                  
                  IF (p_commingling_receipts = 'Y' 
                      AND lc_error_flag = 'N') THEN
                      -- Validation for Commingling Receipts
                    ln_sqlpoint:=190;
                       BEGIN
                          SELECT  vendor_id
                                 ,vendor_site_id
                          INTO    ln_vendor_id_comm
                                 ,ln_vendor_site_id_comm
                          FROM    po_asl_attributes 
                          WHERE   item_id                 =  ln_inventory_item_id
                          AND     UPPER(attribute15)      =  UPPER('Primary Vendor')
                          AND     using_organization_id   =  gn_ship_to_organization_id;
                          dbms_output.put_line('commingling receipts -ln_vendor_id_comm '||ln_vendor_id_comm); 
                          dbms_output.put_line('commingling receipts -ln_vendor_site_id_comm '||ln_vendor_site_id_comm);
                       EXCEPTION
                         WHEN NO_DATA_FOUND THEN
                          lc_error_flag  := 'Y';
                          x_error_msg  := 'vendor_id and vendor_site_id  does not exists for Primary vendor';
                     dbms_output.put_line('vendor_id and vendor_site_id  does not exists for Primary vendor-no data found'||ln_sqlpoint); 
                          ln_sqlpoint:=200;
                          EXIT;
                         WHEN OTHERS THEN
                          lc_error_flag  := 'Y';
                          x_error_msg  := 'vendor_id and vendor_site_id  does not exists for Primary vendor';
                          ln_sqlpoint:=210;
                     dbms_output.put_line('vendor_id and vendor_site_id  does not exists for Primary vendor-when others'||ln_sqlpoint); 
                          EXIT;
                       END;
                  
                       --  Checking vendor_id and vendor_site_id is same as that of primary vendor of the SKU
                       IF ln_vendor_id_comm =  ln_vendor_id 
                          AND ln_vendor_site_id_comm = ln_vendor_site_id THEN
                          ln_sqlpoint:=220;
                              NULL;
                       ELSE
                           -- If not same as of primary vendor then check for their consignment flag 
                           IF lc_error_flag     = 'N' THEN
                              lc_attribute8      := NULL;
                              lc_attribute8_comm := NULL;
                              ln_sqlpoint:=230;                                               
                             BEGIN
                               SELECT PVS.attribute8
                               INTO   lc_attribute8
                               FROM   po_vendor_sites_all       PVS
                               WHERE  PVS.vendor_id              = ln_vendor_id
                               AND    PVS.vendor_site_id         = ln_vendor_site_id;
                               dbms_output.put_line('lc_attribute8= '||lc_attribute8); 
                               SELECT PVS.attribute8
                               INTO   lc_attribute8_comm
                               FROM   po_vendor_sites_all       PVS
                               WHERE  PVS.vendor_id              = ln_vendor_id_comm
                               AND    PVS.vendor_site_id         = ln_vendor_site_id_comm;
                               dbms_output.put_line('lc_attribute8_comm= '||lc_attribute8_comm); 
                               ln_sqlpoint:=240;                                                        
                               IF lc_attribute8 <> lc_attribute8_comm then
                                  lc_error_flag  := 'Y';
                                  x_error_msg  := 'Attribute8 of receipts and Attribute8 of PO does not match';
                                  dbms_output.put_line('Attribute8 of receipts and Attribute8 of PO does not match'||ln_sqlpoint); 
                                  EXIT;
                               END IF;
                                   
                             EXCEPTION
                                WHEN NO_DATA_FOUND THEN
                                  lc_error_flag  := 'Y';
                                  x_error_msg  := 'Attribute8  does not exists';
                                  ln_sqlpoint:=250;
                                 dbms_output.put_line('Attribute8  does not exists -no data found'||ln_sqlpoint); 
                                  EXIT;
                                WHEN OTHERS THEN
                                  lc_error_flag  := 'Y';
                                  x_error_msg  := 'Attribute8  does not exists';
                                  dbms_output.put_line('Attribute8  does not exists -when others'||ln_sqlpoint); 
                                  ln_sqlpoint:=260;
                                  EXIT;
                             END;
                           END IF; -- for lc_error_flag
                       END IF; -- for ln_vendor_comm =  ln_vendor_id 
                  END IF;--for comingly records
-- +===================================================================+
-- | VALIDATION FOR RECEIPT NUMBER                                     |
-- +===================================================================+
                       --Validation for receipt number .
                       --If receipt num is already generated at header ,it should not generate for each line
                BEGIN    
                    SELECT receipt_num
                    INTO   ln_receipt_num
                    FROM   xx_gi_rcv_po_hdr
                    WHERE  header_interface_id= ln_head_nex_id;
                    dbms_output.put_line('ln_receipt_num = '||ln_receipt_num); 
                    dbms_output.put_line('ln_head_nex_id = '||ln_head_nex_id ); 
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN  
                      IF p_ins_rec_tab(i).rhi_receipt_num  IS NULL  THEN
                         ln_rec_nex_id := 0;    
                         lc_meaning    := 'XX_GI_RECEIPT_NUM_US_S'; 
                            -- Receipt Creation using FND LOOKUPS 
                                  ln_sqlpoint:=270;
                            BEGIN
                              SELECT  meaning
                              INTO    lc_meaning
                              FROM    fnd_lookup_values_vl
                              WHERE   tag = FND_PROFILE.VALUE('ORG_ID')
                              AND     UPPER(lookup_type) = 'RECEIVING PARAMETERS'
                              AND     SYSDATE BETWEEN TO_DATE(TO_CHAR(NVL(start_date_active,SYSDATE),'DDMMYYYY')
                                      ||'000000','DDMMYYYYHH24MISS')
                                              AND     TO_DATE(TO_CHAR(NVL(end_date_active,SYSDATE),'DDMMYYYY')
                                      ||'235959','DDMMYYYYHH24MISS')
                             AND    enabled_flag='Y';
                             dbms_output.put_line('lc_meaning = '||lc_meaning); 
                            EXCEPTION
                              WHEN NO_DATA_FOUND THEN
                                  lc_error_flag  := 'Y';
                                  x_error_msg  := 'Meaning for lookup_type  does not exists';
                                  ln_sqlpoint:=280;
                                  dbms_output.put_line('Meaning for lookup_type  does not exists -no data found'||ln_sqlpoint); 
                                  EXIT;
                              WHEN OTHERS THEN
                                  lc_error_flag  := 'Y';
                                  x_error_msg  := 'Meaning for lookup_type  does not exists';
                                  ln_sqlpoint:=290;
                                  dbms_output.put_line('Meaning for lookup_type  does not exists -when others'||ln_sqlpoint); 
                                  EXIT;
                            END;                           
                                                 
                              -- As per OD requirement, Creating  OU specific Receipt Number Sequence
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
                                   p_ins_rec_tab(i).rhi_receipt_num := ln_rec_nex_id;
                                   ln_sqlpoint:=300;
                             dbms_output.put_line('p_ins_rec_tab(i).rhi_receipt_num'||p_ins_rec_tab(i).rhi_receipt_num); 
                              END IF;
                      ELSE
                         IF p_ins_rec_tab(i).rhi_attribute8 IS NULL THEN
                            p_ins_rec_tab(i).rhi_attribute8 := p_ins_rec_tab(i).rhi_receipt_num;
                            x_error_msg  := 'RECEIPT NUMBER IS= '||p_ins_rec_tab(i).rhi_receipt_num;
                            ln_sqlpoint:=310;
                            dbms_output.put_line('p_ins_rec_tab(i).rhi_attribute8'||p_ins_rec_tab(i).rhi_attribute8); 
                         END IF;
                      END IF; --IF p_ins_rec_tab(i).rhi_receipt_num 
                END;
-- +===================================================================+
-- | VALIDATION FOR RECEIPT CORRECTION STARTS HERE                     |
-- +===================================================================+
                       IF    p_ins_rec_tab(i).rhi_attribute4        = 'OHRE' THEN
                             ln_sqlpoint:=320;
                         -- Validation for Received Qty  
                         BEGIN
                          SELECT SUM(transact_qty) 
                          INTO   ln_received_qty 
                          FROM   rcv_vrc_txs_v 
                          WHERE  EXISTS
                                      (
                                      SELECT 1
                                      FROM rcv_shipment_headers 
                                      WHERE attribute8 = p_ins_rec_tab(i).rhi_attribute8
                                      )
                          AND    item_id     = ln_inventory_item_id 
                          AND    transaction_type IN ('DELIVER','CORRECT');
                          dbms_output.put_line('ln_received_qty = '||ln_received_qty ); 
                         EXCEPTION
                              WHEN NO_DATA_FOUND THEN
                                  lc_error_flag  := 'Y';
                                  x_error_msg  := 'Transaction Qty does not exists';
                                  ln_sqlpoint:=330;
                                  dbms_output.put_line('Transaction Qty does not exists-no data found '||ln_sqlpoint); 
                                  EXIT;
                              WHEN OTHERS THEN
                                  lc_error_flag  := 'Y';
                                  x_error_msg  := 'Transaction Qty does not exists';
                                  ln_sqlpoint:=340;
                                  dbms_output.put_line('Transaction Qty does not exists-when others '||ln_sqlpoint); 
                                  EXIT;
                         END;
-- +======================================================================+
-- | VALIDATION FOR NOT TO ALLOW CORRECTION IF THE PO IS ALREADY INVOICED |
-- +======================================================================+
                         -- Validation for Invoiced Qty
                         BEGIN
                           SELECT SUM(quantity_invoiced) 
                           INTO   ln_invoiced_qty
                           FROM   ap_invoice_distributions_all 
                           WHERE  po_distribution_id IN
                                                      (
                                                       SELECT po_distribution_id 
                                                       FROM   rcv_shipment_lines 
                                                       WHERE  attribute8 = p_ins_rec_tab(i).rhi_attribute8 
                                                       AND    item_id    = ln_inventory_item_id 
                                                       );
                           dbms_output.put_line('ln_invoiced_qty = '||ln_invoiced_qty ); 
                         EXCEPTION
                            WHEN NO_DATA_FOUND THEN
                               lc_error_flag  := 'Y';
                               x_error_msg  := 'Invoiced Qty does not exists';
                                  ln_sqlpoint:=350;
                                  dbms_output.put_line('Invoiced Qty does not exists-no data found '||ln_sqlpoint); 
                               EXIT;
                            WHEN OTHERS THEN
                               lc_error_flag  := 'Y';
                               x_error_msg  := 'Invoiced Qty does not exists';
                                  ln_sqlpoint:=360;
                                  dbms_output.put_line('Invoiced Qty does not exists-when others '||ln_sqlpoint); 
                               EXIT;
                         END;
                            IF NVL(ln_invoiced_qty,0) = 0 THEN 
                              IF p_ins_rec_tab(i).rti_quantity > ln_received_qty THEN
                                 NULL;
                                  ln_sqlpoint:=370;
                              ELSE
                                BEGIN
                                 -- Validation for Deliver
                                   SELECT RT.parent_transaction_id 
                                   INTO  ln_tran_id_deliver
                                   FROM  rcv_shipment_headers RSH
                                       , rcv_shipment_lines   RSL
                                       , rcv_transactions     RT
                                   WHERE RSH.attribute8         =  p_ins_rec_tab(i).rhi_attribute8
                                   AND   RSH.shipment_header_id =  RSL.shipment_header_id 
                                   AND   RSL.item_id            =  ln_inventory_item_id
                                   AND   RT.shipment_header_id  =  RSL.shipment_header_id  
                                   AND   RT.shipment_line_id    =  RSL.shipment_line_id  
                                   AND   RT.transaction_type    = 'DELIVER';
                                   dbms_output.put_line('ln_tran_id_deliver = '||ln_tran_id_deliver); 
                                EXCEPTION
                                    WHEN NO_DATA_FOUND THEN
                                         lc_error_flag  := 'Y';
                                         x_error_msg  := 'Parent_transaction_id does not exists for DELIVER';
                                         ln_sqlpoint:=380;
                                         dbms_output.put_line('Parent_transaction_id does not exists for DELIVER-no data found '||ln_sqlpoint); 
                                         EXIT;
                                    WHEN OTHERS THEN
                                         lc_error_flag  := 'Y';
                                         x_error_msg  := 'Parent_transaction_id does not exists for DELIVER';
                                         ln_sqlpoint:=390;
                                         dbms_output.put_line('Parent_transaction_id does not exists for DELIVER-when others '||ln_sqlpoint); 
                                         EXIT;
                                END;
                              END IF;
                                -- Validation for Receiving
                                BEGIN
                                  SELECT RT.parent_transaction_id 
                                  INTO  ln_tran_id_receiving
                                  FROM  rcv_shipment_headers RSH
                                       ,rcv_shipment_lines   RSL
                                       ,rcv_transactions     RT
                                  WHERE RSH.attribute8         = p_ins_rec_tab(i).rhi_attribute8
                                  AND   RSH.shipment_header_id = RSL.shipment_header_id 
                                  AND   RSL.item_id            = ln_inventory_item_id
                                  AND   RT.shipment_header_id  = RSL.shipment_header_id  
                                  AND   RT.shipment_line_id    = RSL.shipment_line_id  
                                  AND   RT.transaction_type    = 'RECEIVING';
                                   dbms_output.put_line('ln_tran_id_receiving = '||ln_tran_id_receiving); 
                                EXCEPTION
                                   WHEN NO_DATA_FOUND THEN
                                     lc_error_flag  := 'Y';
                                     x_error_msg  := 'Parent_transaction_id does not exists for RECEIVING';
                                     ln_sqlpoint:=400;
                                     dbms_output.put_line('Parent_transaction_id does not exists for RECEIVING-No data found '||ln_sqlpoint); 
                                     EXIT;
                                   WHEN OTHERS THEN
                                     lc_error_flag  := 'Y';
                                     x_error_msg  := 'Parent_transaction_id does not exists for RECEIVING';
                                     ln_sqlpoint:=410;
                                     dbms_output.put_line('Parent_transaction_id does not exists for Receiving-when others '||ln_sqlpoint); 
                                     EXIT;
                                END;
                                 -- Assigning Variable with quantity
                               ln_shortage_qty  := ln_received_qty - p_ins_rec_tab(i).rti_quantity  * -1; 
                               dbms_output.put_line('ln_shortage_qty = '||ln_shortage_qty); 
                            END IF; -- for  NVL(ln_invoiced_qty,0)
   -- Insert Processed correction  Records into Staging Table 
           IF lc_error_flag = 'N' THEN
                  lc_E0342_flag := 'PL';
             ELSE
                  lc_E0342_flag := 'VE';
           END IF;
         IF  lc_error_flag = 'N' THEN
               IF  p_ins_rec_tab(i).rti_quantity IS NOT NULL
               AND p_ins_rec_tab(i).rti_item_num IS NOT NULL THEN
               
               SELECT rcv_transactions_interface_s.NEXTVAL
               INTO   ln_tran_nex_id
               FROM   sys.dual; 
               
               INSERT 
               INTO xx_gi_rcv_po_dtl(
                                     header_interface_id
                                   , group_id
                                   , interface_transaction_id
                                   , last_update_date
                                   , last_updated_by
                                   , last_update_login
                                   , creation_date
                                   , created_by
                                   , request_id
                                   , program_update_date
                                   , transaction_type
                                   , transaction_date
                                   , processing_status_code
                                   , processing_mode_code
                                   , transaction_status_code
                                   , quantity
                                   , unit_of_measure
                                   , interface_source_code
                                   , inv_transaction_id
                                   , item_description
                                   , item_revision
                                   , uom_code
                                   , auto_transact_code
                                   , primary_quantity
                                   , primary_unit_of_measure
                                   , receipt_source_code
                                   , from_subinventory
                                   , source_document_code
                                   , parent_transaction_id
                                   , po_revision_num
                                   , po_unit_price
                                   , currency_code
                                   , currency_conversion_type
                                   , currency_conversion_rate
                                   , currency_conversion_date
                                   , substitute_unordered_code
                                   , receipt_exception_flag
                                   , accrual_status_code
                                   , inspection_status_code
                                   , inspection_quality_code
                                   , destination_type_code
                                   , subinventory
                                   , department_code
                                   , wip_operation_seq_num
                                   , wip_resource_seq_num
                                   , shipment_num
                                   , freight_carrier_code
                                   , bill_of_lading
                                   , packing_slip
                                   , shipped_date
                                   , expected_receipt_date
                                   , actual_cost
                                   , transfer_cost
                                   , transportation_cost
                                   , num_of_containers
                                   , waybill_airbill_num
                                   , vendor_item_num
                                   , vendor_lot_num
                                   , rma_reference
                                   , comments
                                   , attribute_category
                                   , attribute1
                                   , attribute2
                                   , attribute3
                                   , attribute4
                                   , attribute5
                                   , attribute6
                                   , attribute7
                                   , attribute8
                                   , attribute9
                                   , attribute10
                                   , attribute11
                                   , attribute12
                                   , attribute13
                                   , attribute14
                                   , attribute15
                                   , ship_head_attribute_category
                                   , ship_head_attribute1
                                   , ship_head_attribute2
                                   , ship_head_attribute3
                                   , ship_head_attribute4
                                   , ship_head_attribute5
                                   , ship_head_attribute6
                                   , ship_head_attribute7
                                   , ship_head_attribute8
                                   , ship_head_attribute9
                                   , ship_head_attribute10
                                   , ship_head_attribute11
                                   , ship_head_attribute12
                                   , ship_head_attribute13
                                   , ship_head_attribute14
                                   , ship_head_attribute15
                                   , ship_line_attribute_category
                                   , ship_line_attribute1
                                   , ship_line_attribute2
                                   , ship_line_attribute3
                                   , ship_line_attribute4
                                   , ship_line_attribute5
                                   , ship_line_attribute6
                                   , ship_line_attribute7
                                   , ship_line_attribute8
                                   , ship_line_attribute9
                                   , ship_line_attribute10
                                   , ship_line_attribute11
                                   , ship_line_attribute12
                                   , ship_line_attribute13
                                   , ship_line_attribute14
                                   , ship_line_attribute15
                                   , ussgl_transaction_code
                                   , government_context
                                   , destination_context
                                   , source_doc_quantity
                                   , source_doc_unit_of_measure
                                   , vendor_cum_shipped_qty
                                   , item_num
                                   , document_num
                                   , po_header_id
                                   , document_line_num
                                   , truck_num
                                   , ship_to_location_code
                                   , container_num
                                   , substitute_item_num
                                   , notice_unit_price
                                   , item_category
                                   , location_code
                                   , vendor_id
                                   , vendor_num
                                   , vendor_site_id
                                   , vendor_site_code
                                   , from_organization_code
                                   , to_organization_id
                                   , to_organization_code
                                   , intransit_owning_org_code
                                   , routing_code
                                   , routing_step
                                   , release_num
                                   , document_shipment_line_num
                                   , document_distribution_num
                                   , deliver_to_person_name
                                   , deliver_to_location_code
                                   , use_mtl_lot
                                   , use_mtl_serial
                                   , locator
                                   , reason_name
                                   , validation_flag
                                   , quantity_shipped
                                   , quantity_invoiced
                                   , tax_name
                                   , tax_amount
                                   , req_num
                                   , req_line_num
                                   , req_distribution_num
                                   , wip_entity_name
                                   , wip_line_code
                                   , resource_code
                                   , shipment_line_status_code
                                   , barcode_label
                                   , transfer_percentage
                                   , country_of_origin_code
                                   , oe_order_header_id
                                   , oe_order_line_id
                                   , customer_item_num
                                   , lpn_id
                                   , mobile_txn
                                   , secondary_quantity
                                   , secondary_unit_of_measure
                                   , secondary_uom_code
                                   , qc_grade
                                   , from_locator
                                   , interface_available_qty
                                   , interface_transaction_qty
                                   , interface_available_amt
                                   , interface_transaction_amt
                                   , license_plate_number
                                   , source_transaction_num
                                   , order_transaction_id
                                   , customer_account_number
                                   , customer_party_name
                                   , oe_order_line_num
                                   , oe_order_num
                                   , amount
                                   , timecard_ovn
                                   , E0342_status_flag
                                   , E0342_error_description
                                   , E0342_first_rec_time
                                    )
                                    VALUES
                                    (
                                     ln_head_nex_id
                                   , ln_grp_nex_id
                                   , ln_tran_nex_id
                                   , p_ins_rec_tab(i).rti_last_update_date
                                   , fnd_global.user_id  
                                   , fnd_global.login_id 
                                   , p_ins_rec_tab(i).rti_creation_date
                                   , fnd_global.user_id  
                                   , p_ins_rec_tab(i).rti_request_id
                                   , p_ins_rec_tab(i).rti_program_update_date
                                   , p_ins_rec_tab(i).rti_transaction_type
                                   , p_ins_rec_tab(i).rti_transaction_date
                                   , p_ins_rec_tab(i).rti_processing_status_code
                                   , p_ins_rec_tab(i).rti_processing_mode_code
                                   , p_ins_rec_tab(i).rti_transaction_status_code 
                                   , p_ins_rec_tab(i).rti_quantity
                                   , p_ins_rec_tab(i).rti_unit_of_measure
                                   , p_ins_rec_tab(i).rti_interface_source_code
                                   , p_ins_rec_tab(i).rti_inv_transaction_id 
                                   , p_ins_rec_tab(i).rti_item_description
                                   , p_ins_rec_tab(i).rti_item_revision
                                   , p_ins_rec_tab(i).rti_uom_code
                                   , p_ins_rec_tab(i).rti_auto_transact_code
                                   , p_ins_rec_tab(i).rti_primary_quantity
                                   , p_ins_rec_tab(i).rti_primary_unit_of_measure
                                   , p_ins_rec_tab(i).rhi_receipt_source_code
                                   , p_ins_rec_tab(i).rti_from_subinventory
                                   , p_ins_rec_tab(i).rti_source_document_code
                                   , p_ins_rec_tab(i).rti_parent_transaction_id
                                   , p_ins_rec_tab(i).rti_po_revision_num 
                                   , p_ins_rec_tab(i).rti_po_unit_price
                                   , p_ins_rec_tab(i).rti_currency_code
                                   , p_ins_rec_tab(i).rti_currency_conversion_type
                                   , p_ins_rec_tab(i).rti_currency_conversion_rate
                                   , p_ins_rec_tab(i).rti_currency_conversion_date
                                   , p_ins_rec_tab(i).rti_substitute_unordered_code
                                   , p_ins_rec_tab(i).rti_receipt_exception_flag
                                   , p_ins_rec_tab(i).rti_accrual_status_code 
                                   , p_ins_rec_tab(i).rti_inspection_status_code
                                   , p_ins_rec_tab(i).rti_inspection_quality_code
                                   , p_ins_rec_tab(i).rti_destination_type_code
                                   , p_ins_rec_tab(i).rti_subinventory
                                   , p_ins_rec_tab(i).rti_department_code
                                   , p_ins_rec_tab(i).rti_wip_operation_seq_num 
                                   , p_ins_rec_tab(i).rti_wip_resource_seq_num 
                                   , p_ins_rec_tab(i).rti_shipment_num
                                   , p_ins_rec_tab(i).rti_freight_carrier_code 
                                   , p_ins_rec_tab(i).rti_bill_of_lading 
                                   , p_ins_rec_tab(i).rti_packing_slip
                                   , p_ins_rec_tab(i).rti_shipped_date
                                   , p_ins_rec_tab(i).rti_expected_receipt_date
                                   , p_ins_rec_tab(i).rti_actual_cost
                                   , p_ins_rec_tab(i).rti_transfer_cost
                                   , p_ins_rec_tab(i).rti_transportation_cost
                                   , p_ins_rec_tab(i).rti_num_of_containers
                                   , p_ins_rec_tab(i).rti_waybill_airbill_num
                                   , p_ins_rec_tab(i).rti_vendor_item_num 
                                   , p_ins_rec_tab(i).rti_vendor_lot_num
                                   , p_ins_rec_tab(i).rti_rma_reference
                                   , p_ins_rec_tab(i).rti_comments 
                                   , p_ins_rec_tab(i).rhi_attribute_category
                                   , p_ins_rec_tab(i).rhi_attribute1
                                   , p_ins_rec_tab(i).rhi_attribute2
                                   , p_ins_rec_tab(i).rhi_attribute3
                                   , p_ins_rec_tab(i).rhi_attribute4
                                   , p_ins_rec_tab(i).rhi_attribute5
                                   , p_ins_rec_tab(i).rhi_attribute6
                                   , p_ins_rec_tab(i).rhi_attribute7
                                   , p_ins_rec_tab(i).rhi_attribute8
                                   , p_ins_rec_tab(i).rhi_attribute9
                                   , p_ins_rec_tab(i).rhi_attribute10
                                   , p_ins_rec_tab(i).rhi_attribute11
                                   , p_ins_rec_tab(i).rhi_attribute12
                                   , p_ins_rec_tab(i).rhi_attribute13
                                   , p_ins_rec_tab(i).rhi_attribute14
                                   , p_ins_rec_tab(i).rhi_attribute15
                                   , p_ins_rec_tab(i).rti_sh_att_cat
                                   , p_ins_rec_tab(i).rti_sh_att1
                                   , p_ins_rec_tab(i).rti_sh_att2
                                   , p_ins_rec_tab(i).rti_sh_att3
                                   , p_ins_rec_tab(i).rti_sh_att4
                                   , p_ins_rec_tab(i).rti_sh_att5
                                   , p_ins_rec_tab(i).rti_sh_att6
                                   , p_ins_rec_tab(i).rti_sh_att7
                                   , p_ins_rec_tab(i).rti_sh_att8
                                   , p_ins_rec_tab(i).rti_sh_att9
                                   , p_ins_rec_tab(i).rti_sh_att10
                                   , p_ins_rec_tab(i).rti_sh_att11
                                   , p_ins_rec_tab(i).rti_sh_att12
                                   , p_ins_rec_tab(i).rti_sh_att13
                                   , p_ins_rec_tab(i).rti_sh_att14
                                   , p_ins_rec_tab(i).rti_sh_att15
                                   , p_ins_rec_tab(i).rti_sl_att_cat
                                   , p_ins_rec_tab(i).rti_sl_att1
                                   , p_ins_rec_tab(i).rti_sl_att2
                                   , p_ins_rec_tab(i).rti_sl_att3
                                   , p_ins_rec_tab(i).rti_sl_att4
                                   , p_ins_rec_tab(i).rti_sl_att5
                                   , p_ins_rec_tab(i).rti_sl_att6
                                   , p_ins_rec_tab(i).rti_sl_att7
                                   , p_ins_rec_tab(i).rti_sl_att8
                                   , p_ins_rec_tab(i).rti_sl_att9
                                   , p_ins_rec_tab(i).rti_sl_att10
                                   , p_ins_rec_tab(i).rti_sl_att11
                                   , p_ins_rec_tab(i).rti_sl_att12
                                   , p_ins_rec_tab(i).rti_sl_att13
                                   , p_ins_rec_tab(i).rti_sl_att14
                                   , p_ins_rec_tab(i).rti_sl_att15
                                   , p_ins_rec_tab(i).rti_ussgl_transaction_code
                                   , p_ins_rec_tab(i).rti_government_context
                                   , p_ins_rec_tab(i).rti_destination_context
                                   , p_ins_rec_tab(i).rti_source_doc_quantity
                                   , p_ins_rec_tab(i).rti_source_doc_unit_of_measure
                                   , p_ins_rec_tab(i).rti_vendor_cum_shipped_qty
                                   , p_ins_rec_tab(i).rti_item_num
                                   , p_ins_rec_tab(i).rti_document_num
                                   , ln_po_header_id
                                   , p_ins_rec_tab(i).rti_document_line_num
                                   , p_ins_rec_tab(i).rti_truck_num
                                   , p_ins_rec_tab(i).rti_ship_to_location_code
                                   , p_ins_rec_tab(i).rti_container_num
                                   , p_ins_rec_tab(i).rti_substitute_item_num
                                   , p_ins_rec_tab(i).rti_notice_unit_price
                                   , p_ins_rec_tab(i).rti_item_category 
                                   , p_ins_rec_tab(i).rti_location_code 
                                   , ln_vendor_id
                                   , p_ins_rec_tab(i).rti_vendor_num
                                   , ln_vendor_site_id
                                   , p_ins_rec_tab(i).rti_vendor_site_code
                                   , p_ins_rec_tab(i).rti_from_organization_code
                                   , gn_ship_to_organization_id
                                   , lc_organization_code -- rti_to_organization_code 
                                   , p_ins_rec_tab(i).rti_intransit_owning_org_code
                                   , p_ins_rec_tab(i).rti_routing_code
                                   , p_ins_rec_tab(i).rti_routing_step
                                   , p_ins_rec_tab(i).rti_release_num
                                   , p_ins_rec_tab(i).rti_document_shipment_line_num
                                   , p_ins_rec_tab(i).rti_document_distribution_num
                                   , p_ins_rec_tab(i).rti_deliver_to_person_name
                                   , p_ins_rec_tab(i).rti_deliver_to_location_code 
                                   , p_ins_rec_tab(i).rti_use_mtl_lot 
                                   , p_ins_rec_tab(i).rti_use_mtl_serial
                                   , p_ins_rec_tab(i).rti_locator
                                   , p_ins_rec_tab(i).rti_reason_name 
                                   , p_ins_rec_tab(i).rti_validation_flag
                                   , p_ins_rec_tab(i).rti_quantity_shipped 
                                   , p_ins_rec_tab(i).rti_quantity_invoiced
                                   , p_ins_rec_tab(i).rti_tax_name 
                                   , p_ins_rec_tab(i).rti_tax_amount
                                   , p_ins_rec_tab(i).rti_req_num
                                   , p_ins_rec_tab(i).rti_req_line_num 
                                   , p_ins_rec_tab(i).rti_req_distribution_num
                                   , p_ins_rec_tab(i).rti_wip_entity_name 
                                   , p_ins_rec_tab(i).rti_wip_line_code
                                   , p_ins_rec_tab(i).rti_resource_code
                                   , p_ins_rec_tab(i).rti_shipment_line_status_code
                                   , p_ins_rec_tab(i).rti_barcode_label
                                   , p_ins_rec_tab(i).rti_transfer_percentage
                                   , p_ins_rec_tab(i).rti_country_of_origin_code 
                                   , p_ins_rec_tab(i).rti_oe_order_header_id
                                   , p_ins_rec_tab(i).rti_oe_order_line_id
                                   , p_ins_rec_tab(i).rti_customer_item_num
                                   , p_ins_rec_tab(i).rti_lpn_id 
                                   , p_ins_rec_tab(i).rti_mobile_txn 
                                   , p_ins_rec_tab(i).rti_secondary_quantity
                                   , p_ins_rec_tab(i).rti_secondary_unit_of_measure
                                   , p_ins_rec_tab(i).rti_secondary_uom_code
                                   , p_ins_rec_tab(i).rti_qc_grade 
                                   , p_ins_rec_tab(i).rti_from_locator
                                   , p_ins_rec_tab(i).rti_interface_available_qty
                                   , p_ins_rec_tab(i).rti_interface_transaction_qty
                                   , p_ins_rec_tab(i).rti_interface_available_amt
                                   , p_ins_rec_tab(i).rti_interface_transaction_amt 
                                   , p_ins_rec_tab(i).rti_license_plate_number 
                                   , p_ins_rec_tab(i).rti_source_transaction_num
                                   , p_ins_rec_tab(i).rti_order_transaction_id
                                   , p_ins_rec_tab(i).rti_customer_account_number
                                   , p_ins_rec_tab(i).rti_customer_party_name
                                   , p_ins_rec_tab(i).rti_oe_order_line_num 
                                   , p_ins_rec_tab(i).rti_oe_order_num 
                                   , p_ins_rec_tab(i).rti_amount 
                                   , p_ins_rec_tab(i).rti_timecard_ovn
                                   , lc_E0342_flag
                                   , SUBSTR(lc_ve_err_msg,1,2000)
                                   , SYSDATE
                                   );
               END IF;
          COMMIT; 
                          -- Insert Records into RTI
-- +======================================================================+
-- | RTI INSERT FOR CORRECTION FOR DELEVER TO RECEIVE                     |
-- +======================================================================+
                          INSERT 
                          INTO rcv_transactions_interface( 
                                                          interface_transaction_id 
                                                         ,group_id 
                                                         ,last_update_date 
                                                         ,last_updated_by 
                                                         ,last_update_login 
                                                         ,creation_date 
                                                         ,created_by 
                                                         ,transaction_type 
                                                         ,transaction_date 
                                                         ,processing_status_code 
                                                         ,processing_mode_code 
                                                         ,transaction_status_code 
                                                         ,quantity
                                                         ,unit_of_measure 
                                                         ,item_id
                                                         ,shipment_header_id
                                                         ,shipment_line_id
                                                         ,receipt_source_code 
                                                         ,vendor_id
                                                         ,from_organization_id
                                                         ,from_subinventory
                                                         ,from_locator_id
                                                         ,source_document_code
                                                         ,parent_transaction_id
                                                         ,po_header_id
                                                         ,po_line_id
                                                         ,po_line_location_id
                                                         ,po_distribution_id
                                                         ,destination_type_code 
                                                         ,deliver_to_person_id
                                                         ,location_id
                                                         ,deliver_to_location_id
                                                         ,validation_flag
                                                          )
                                                         VALUES
                                                         (
                                                         ln_tran_nex_id
                                                        ,ln_grp_nex_id
                                                        ,p_ins_rec_tab(i).rti_last_update_date
                                                        ,fnd_global.user_id 
                                                        ,fnd_global.login_id 
                                                        ,p_ins_rec_tab(i).rti_creation_date
                                                        ,fnd_global.user_id 
                                                        ,'CORRECT'    --transaction_type , 
                                                        ,p_ins_rec_tab(i).rti_transaction_date
                                                        ,'PENDING'            --processing_status_code ,
                                                        ,'BATCH'             --processing_mode_code ,
                                                        ,'PENDING'             --transaction_status_code , 
                                                        ,ln_shortage_qty
                                                        ,p_ins_rec_tab(i).rti_unit_of_measure
                                                        ,ln_inventory_item_id
                                                        ,ln_shipment_header_id 
                                                        ,p_ins_rec_tab(i).rti_shipment_line_id
                                                        ,p_ins_rec_tab(i).rhi_receipt_source_code
                                                        ,ln_vendor_id
                                                        ,gn_ship_to_organization_id
                                                        ,'STOCK'      --from_subinventory
                                                        ,NULL -- from_locator_id
                                                        ,'PO'               --source_document_code 
                                                        ,ln_tran_id_deliver --p_ins_rec_tab(i).rti_parent_transaction_id
                                                        ,ln_po_header_id
                                                        ,p_ins_rec_tab(i).rti_po_line_id
                                                        ,p_ins_rec_tab(i).rti_po_line_location_id
                                                        ,p_ins_rec_tab(i).rti_po_distribution_id
                                                        ,'INVENTORY'--p_ins_rec_tab(i).rti_destination_type_code
                                                        ,p_ins_rec_tab(i).rti_deliver_to_person_id 
                                                        ,NULL
                                                        ,NULL
                                                        ,'Y' --validation_flag
                                                        );
-- +======================================================================+
-- | RTI INSERT FOR CORRECTION FOR RECEIVE TO OPEN                        |
-- +======================================================================+
                          INSERT 
                          INTO rcv_transactions_interface( 
                                                          interface_transaction_id 
                                                         ,group_id 
                                                         ,last_update_date 
                                                         ,last_updated_by 
                                                         ,last_update_login 
                                                         ,creation_date 
                                                         ,created_by 
                                                         ,transaction_type 
                                                         ,transaction_date 
                                                         ,processing_status_code 
                                                         ,processing_mode_code 
                                                         ,transaction_status_code 
                                                         ,quantity
                                                         ,unit_of_measure 
                                                         ,item_id
                                                         ,shipment_header_id
                                                         ,shipment_line_id
                                                         ,receipt_source_code 
                                                         ,vendor_id
                                                         ,from_organization_id
                                                         ,from_subinventory
                                                         ,from_locator_id
                                                         ,source_document_code
                                                         ,parent_transaction_id
                                                         ,po_header_id
                                                         ,po_line_id
                                                         ,po_line_location_id
                                                         ,po_distribution_id
                                                         ,destination_type_code 
                                                         ,deliver_to_person_id
                                                         ,location_id
                                                         ,deliver_to_location_id
                                                         ,validation_flag
                                                          )
                                                         VALUES
                                                         (
                                                         ln_tran_nex_id
                                                        ,ln_grp_nex_id
                                                        ,p_ins_rec_tab(i).rti_last_update_date
                                                        ,fnd_global.user_id 
                                                        ,fnd_global.login_id 
                                                        ,p_ins_rec_tab(i).rti_creation_date
                                                        ,fnd_global.user_id 
                                                        ,'CORRECT'    --transaction_type , 
                                                        ,p_ins_rec_tab(i).rti_transaction_date
                                                        ,'PENDING'            --processing_status_code ,
                                                        ,'BATCH'             --processing_mode_code ,
                                                        ,'PENDING'             --transaction_status_code , 
                                                        ,ln_shortage_qty
                                                        ,p_ins_rec_tab(i).rti_unit_of_measure
                                                        ,ln_inventory_item_id
                                                        ,ln_shipment_header_id 
                                                        ,p_ins_rec_tab(i).rti_shipment_line_id
                                                        ,p_ins_rec_tab(i).rhi_receipt_source_code
                                                        ,ln_vendor_id
                                                        ,gn_ship_to_organization_id
                                                        ,'STOCK'      --from_subinventory
                                                        ,NULL -- from_locator_id
                                                        ,'PO'               --source_document_code 
                                                        ,ln_tran_id_receiving -- p_ins_rec_tab(i).rti_parent_transaction_id
                                                        ,ln_po_header_id
                                                        ,p_ins_rec_tab(i).rti_po_line_id
                                                        ,p_ins_rec_tab(i).rti_po_line_location_id
                                                        ,p_ins_rec_tab(i).rti_po_distribution_id
                                                        ,'RECEIVING'--p_ins_rec_tab(i).rti_destination_type_code
                                                        ,p_ins_rec_tab(i).rti_deliver_to_person_id 
                                                        ,NULL
                                                        ,NULL
                                                        ,'Y' --validation_flag
                                                        );
                     COMMIT;
         END IF; -- IF lc_error_flag = 'N' THEN 
                       END IF; --for p_ins_rec_tab(i).rti_attribute4        = 'OHRE'
-- +===================================================================+
-- | VALIDATION FOR RECEIPT CORRECTION ENDS HERE                       |
-- +===================================================================+
-- +=========================================================================================+
-- | SET E0342 FLAG TO P  FOR VALIDATION PASSED RECORDS BEFORE INSERTING INTO STAGING        |
-- +=========================================================================================+
   -- Insert Processed PO Records into Staging Table 
           IF lc_error_flag = 'N' THEN
                  lc_E0342_flag := 'PL';
             ELSE
                  lc_E0342_flag := 'VE';
           END IF;
-- +=========================================================================================+
-- | INSERT INTO STAGING AND INTEFACE BEGINS HERE                                            |
-- | VALIDATION SHOULD BE AS BELOW                                                           |
-- +=========================================================================================+
-- | IDENTIFYING TYPE OF INBOUND RECORD FOR APPROPRIATE PROCESSING (ATTRIBUTE 4)             |
-- | KEYR  - KEY REC CREATION     (INSERT ONLY STG HEADER)                                   | 
-- |                              SCENARIO 1 (INSERT ONLY STG HEADER IF A4 DOC NOT EXISTS)   |
-- |                              SCENARIO 2 (SKIP   ERROR IF ALREADY KEYR   DOC EXISTS)     |
-- | KEYM  - KEY REC MAINTENANCE  (UPDATE CARTON COUNT ALONE FOR KEYREC   DOC                |
-- |                              SCENARIO 1 (INSERT ONLY STG HEADER IF A4 DOC NOT EXISTS)   |
-- |                              SCENARIO 2 (ERROR IF ALREADY EXISTS)                       |
-- | KEYCL - KEY REC CLOSE        (UPDATE A4 FOR ALL KEYREC   DOC COMBINATION)               |
-- | OHDR  - KEY REC HDR   DTL    (INSERT BOTH HDR   DTL OF STG   RTI                        |
-- | RVSC  - KEY REC HDR   DTL    (ZERO RECEIPTS INSERT BOTH STG   RTI FOR CHARGE BACK       |
-- +=========================================================================================+-- 
--   +===================================================================+
--   |  KEYR LOGIC BEGINS HERE                                           |
--   +===================================================================+

   -- Inserting Header records only
  
   
         IF lc_error_flag = 'N' THEN
         BEGIN
                  SELECT 1
                  INTO   gn_dup_keyrec
                  FROM   xx_gi_rcv_po_hdr
                  WHERE  attribute5 =lc_rhi_attribute5  
                  AND    attribute8 =lc_rhi_attribute8 
                  AND    attribute4 = 'KEYR';
         EXCEPTION
           WHEN NO_DATA_FOUND THEN
             
             BEGIN
               SELECT  header_interface_id
                      ,group_id 
               INTO    ln_head_nex_id
                      ,ln_grp_nex_id
               FROM    xx_gi_rcv_po_hdr 
               WHERE   attribute8 = p_ins_rec_tab(i).rhi_attribute8;
               dbms_output.put_line('ln_head_nex_id '||ln_head_nex_id);
               dbms_output.put_line('ln_grp_nex_id '||ln_grp_nex_id);
             EXCEPTION
               WHEN NO_DATA_FOUND THEN
                                     ln_sqlpoint:=420;
                  dbms_output.put_line('Before insert into HDR table '||ln_sqlpoint);
             
                  SELECT rcv_headers_interface_s.NEXTVAL
                  INTO   ln_head_nex_id 
                  FROM   sys.dual;
                           
                  SELECT rcv_interface_groups_s.NEXTVAL
                  INTO   ln_grp_nex_id
                  FROM   sys.dual;
                 
                  INSERT 
                  INTO xx_gi_rcv_po_hdr(
                                        header_interface_id
                                       ,group_id
                                       ,processing_status_code
                                       ,receipt_source_code
                                       ,asn_type
                                       ,transaction_type
                                       ,auto_transact_code
                                       ,last_update_date
                                       ,last_updated_by
                                       ,last_update_login
                                       ,creation_date
                                       ,created_by
                                       ,notice_creation_date
                                       ,shipment_num
                                       ,receipt_num
                                       ,receipt_header_id
                                       ,vendor_id
                                       ,vendor_num
                                       ,vendor_site_id
                                       ,vendor_site_code
                                       ,from_organization_code
                                       ,ship_to_organization_code
                                       ,ship_to_organization_id
                                       ,location_code
                                       ,bill_of_lading
                                       ,packing_slip
                                       ,shipped_date
                                       ,freight_carrier_code
                                       ,expected_receipt_date
                                       ,num_of_containers
                                       ,waybill_airbill_num
                                       ,comments
                                       ,gross_weight
                                       ,gross_weight_uom_code
                                       ,net_weight
                                       ,net_weight_uom_code
                                       ,tar_weight
                                       ,tar_weight_uom_code
                                       ,packaging_code
                                       ,carrier_method
                                       ,carrier_equipment
                                       ,special_handling_code
                                       ,hazard_code
                                       ,hazard_class
                                       ,hazard_description
                                       ,freight_terms
                                       ,freight_bill_number
                                       ,invoice_num
                                       ,invoice_date
                                       ,total_invoice_amount
                                       ,tax_name
                                       ,tax_amount
                                       ,freight_amount
                                       ,currency_code
                                       ,conversion_rate_type
                                       ,conversion_rate
                                       ,conversion_rate_date
                                       ,payment_terms_name
                                       ,attribute_category
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
                                       ,employee_name
                                       ,invoice_status_code
                                       ,validation_flag
                                       ,customer_account_number
                                       ,customer_party_name
                                       ,transaction_date
                                       ,E0342_status_flag
                                       ,E0342_first_rec_time
                                       )
                                       VALUES
                                       (
                                       ln_head_nex_id
                                      ,ln_grp_nex_id
                                      ,p_ins_rec_tab(i).rti_processing_status_code
                                      ,p_ins_rec_tab(i).rhi_receipt_source_code
                                      ,p_ins_rec_tab(i).rhi_asn_type
                                      ,p_ins_rec_tab(i).rti_transaction_type
                                      ,p_ins_rec_tab(i).rti_auto_transact_code
                                      ,p_ins_rec_tab(i).rti_last_update_date
                                      ,fnd_global.user_id  
                                      ,fnd_global.login_id 
                                      ,p_ins_rec_tab(i).rti_creation_date
                                      ,fnd_global.user_id  
                                      ,p_ins_rec_tab(i).rhi_notice_creation_date
                                      ,p_ins_rec_tab(i).rti_shipment_num
                                      ,p_ins_rec_tab(i).rhi_receipt_num
                                      ,p_ins_rec_tab(i).rhi_receipt_header_id
                                      ,ln_vendor_id
                                      ,p_ins_rec_tab(i).rti_vendor_num
                                      ,ln_vendor_site_id
                                      ,p_ins_rec_tab(i).rti_vendor_site_code
                                      ,lc_from_organization_code
                                      ,lc_organization_code 
                                      ,gn_ship_to_organization_id
                                      ,p_ins_rec_tab(i).rti_location_code
                                      ,p_ins_rec_tab(i).rti_bill_of_lading
                                      ,p_ins_rec_tab(i).rti_packing_slip
                                      ,p_ins_rec_tab(i).rti_shipped_date
                                      ,p_ins_rec_tab(i).rti_freight_carrier_code 
                                      ,p_ins_rec_tab(i).rti_expected_receipt_date
                                      ,p_ins_rec_tab(i).rti_num_of_containers
                                      ,p_ins_rec_tab(i).rti_waybill_airbill_num
                                      ,p_ins_rec_tab(i).rti_comments
                                      ,p_ins_rec_tab(i).rhi_gross_weight
                                      ,p_ins_rec_tab(i).rhi_gross_weight_uom_code
                                      ,p_ins_rec_tab(i).rhi_net_weight
                                      ,p_ins_rec_tab(i).rhi_net_weight_uom_code
                                      ,p_ins_rec_tab(i).rhi_tar_weight 
                                      ,p_ins_rec_tab(i).rhi_tar_weight_uom_code
                                      ,p_ins_rec_tab(i).rhi_packaging_code
                                      ,p_ins_rec_tab(i).rhi_carrier_method
                                      ,p_ins_rec_tab(i).rhi_carrier_equipment
                                      ,p_ins_rec_tab(i).rhi_special_handling_code
                                      ,p_ins_rec_tab(i).rhi_hazard_code
                                      ,p_ins_rec_tab(i).rhi_hazard_class
                                      ,p_ins_rec_tab(i).rhi_hazard_description
                                      ,p_ins_rec_tab(i).rhi_freight_terms
                                      ,p_ins_rec_tab(i).rhi_freight_bill_number
                                      ,p_ins_rec_tab(i).rhi_invoice_num
                                      ,p_ins_rec_tab(i).rhi_invoice_date
                                      ,p_ins_rec_tab(i).rhi_total_invoice_amount
                                      ,p_ins_rec_tab(i).rti_tax_name
                                      ,p_ins_rec_tab(i).rti_tax_amount
                                      ,p_ins_rec_tab(i).rhi_freight_amount
                                      ,p_ins_rec_tab(i).rti_currency_code
                                      ,p_ins_rec_tab(i).rhi_conversion_rate_type
                                      ,p_ins_rec_tab(i).rhi_conversion_rate 
                                      ,p_ins_rec_tab(i).rhi_conversion_rate_date
                                      ,p_ins_rec_tab(i).rhi_payment_terms_name 
                                      ,p_ins_rec_tab(i).rhi_attribute_category
                                      ,p_ins_rec_tab(i).rhi_attribute1
                                      ,p_ins_rec_tab(i).rhi_attribute2
                                      ,p_ins_rec_tab(i).rhi_attribute3
                                      ,p_ins_rec_tab(i).rhi_attribute4
                                      ,p_ins_rec_tab(i).rhi_attribute5
                                      ,p_ins_rec_tab(i).rhi_attribute6
                                      ,p_ins_rec_tab(i).rhi_attribute7
                                      ,p_ins_rec_tab(i).rhi_attribute8
                                      ,p_ins_rec_tab(i).rhi_attribute9
                                      ,p_ins_rec_tab(i).rhi_attribute10
                                      ,p_ins_rec_tab(i).rhi_attribute11
                                      ,p_ins_rec_tab(i).rhi_attribute12
                                      ,p_ins_rec_tab(i).rhi_attribute13
                                      ,p_ins_rec_tab(i).rhi_attribute14
                                      ,p_ins_rec_tab(i).rhi_attribute15
                                      ,p_ins_rec_tab(i).rhi_employee_name
                                      ,p_ins_rec_tab(i).rhi_invoice_status_code
                                      ,p_ins_rec_tab(i).rti_validation_flag 
                                      ,p_ins_rec_tab(i).rti_customer_account_number
                                      ,p_ins_rec_tab(i).rti_customer_party_name
                                      ,p_ins_rec_tab(i).rti_transaction_date 
                                      ,lc_E0342_flag
                                      ,SYSDATE
                                      );
            END;
         END;
--   +===================================================================+
--   |KEYR LOGIC ENDS HERE                                               |
--   +===================================================================+
--   +===================================================================+
--   |KEYM LOGIC BEGINS HERE                                             |
--   +===================================================================+
         BEGIN
                  SELECT 1
                  INTO   gn_dup_keyrec
                  FROM   xx_gi_rcv_po_hdr
                  WHERE  attribute5 =lc_rhi_attribute5
                  AND    attribute8 =lc_rhi_attribute8
                  AND    attribute4 ='KEYM';
             IF  gn_dup_keyrec IS  NOT NULL THEN
                 UPDATE  xx_gi_rcv_po_hdr
                 SET     num_of_containers= p_ins_rec_tab(i).rti_num_of_containers
                 WHERE   attribute5       =lc_rhi_attribute5  -- doc num
                 AND     attribute8       =lc_rhi_attribute8 ; --key rec num
             END IF;
         EXCEPTION
           WHEN NO_DATA_FOUND THEN
             BEGIN
               SELECT  header_interface_id
                      ,group_id 
               INTO    ln_head_nex_id
                      ,ln_grp_nex_id
               FROM    xx_gi_rcv_po_hdr 
               WHERE   attribute8 = p_ins_rec_tab(i).rhi_attribute8;
               dbms_output.put_line('ln_head_nex_id '||ln_head_nex_id);
               dbms_output.put_line('ln_grp_nex_id '||ln_grp_nex_id);
             EXCEPTION
               WHEN NO_DATA_FOUND THEN
                                     ln_sqlpoint:=420;
                  dbms_output.put_line('Before insert into HDR table '||ln_sqlpoint);
             
                  SELECT rcv_headers_interface_s.NEXTVAL
                  INTO   ln_head_nex_id 
                  FROM   sys.dual;
                           
                  SELECT rcv_interface_groups_s.NEXTVAL
                  INTO   ln_grp_nex_id
                  FROM   sys.dual;
                 
                  INSERT 
                  INTO xx_gi_rcv_po_hdr(
                                        header_interface_id
                                       ,group_id
                                       ,processing_status_code
                                       ,receipt_source_code
                                       ,asn_type
                                       ,transaction_type
                                       ,auto_transact_code
                                       ,last_update_date
                                       ,last_updated_by
                                       ,last_update_login
                                       ,creation_date
                                       ,created_by
                                       ,notice_creation_date
                                       ,shipment_num
                                       ,receipt_num
                                       ,receipt_header_id
                                       ,vendor_id
                                       ,vendor_num
                                       ,vendor_site_id
                                       ,vendor_site_code
                                       ,from_organization_code
                                       ,ship_to_organization_code
                                       ,ship_to_organization_id
                                       ,location_code
                                       ,bill_of_lading
                                       ,packing_slip
                                       ,shipped_date
                                       ,freight_carrier_code
                                       ,expected_receipt_date
                                       ,num_of_containers
                                       ,waybill_airbill_num
                                       ,comments
                                       ,gross_weight
                                       ,gross_weight_uom_code
                                       ,net_weight
                                       ,net_weight_uom_code
                                       ,tar_weight
                                       ,tar_weight_uom_code
                                       ,packaging_code
                                       ,carrier_method
                                       ,carrier_equipment
                                       ,special_handling_code
                                       ,hazard_code
                                       ,hazard_class
                                       ,hazard_description
                                       ,freight_terms
                                       ,freight_bill_number
                                       ,invoice_num
                                       ,invoice_date
                                       ,total_invoice_amount
                                       ,tax_name
                                       ,tax_amount
                                       ,freight_amount
                                       ,currency_code
                                       ,conversion_rate_type
                                       ,conversion_rate
                                       ,conversion_rate_date
                                       ,payment_terms_name
                                       ,attribute_category
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
                                       ,employee_name
                                       ,invoice_status_code
                                       ,validation_flag
                                       ,customer_account_number
                                       ,customer_party_name
                                       ,transaction_date
                                       ,E0342_status_flag
                                       ,E0342_first_rec_time
                                       )
                                       VALUES
                                       (
                                       ln_head_nex_id
                                      ,ln_grp_nex_id
                                      ,p_ins_rec_tab(i).rti_processing_status_code
                                      ,p_ins_rec_tab(i).rhi_receipt_source_code
                                      ,p_ins_rec_tab(i).rhi_asn_type
                                      ,p_ins_rec_tab(i).rti_transaction_type
                                      ,p_ins_rec_tab(i).rti_auto_transact_code
                                      ,p_ins_rec_tab(i).rti_last_update_date
                                      ,fnd_global.user_id  
                                      ,fnd_global.login_id 
                                      ,p_ins_rec_tab(i).rti_creation_date
                                      ,fnd_global.user_id  
                                      ,p_ins_rec_tab(i).rhi_notice_creation_date
                                      ,p_ins_rec_tab(i).rti_shipment_num
                                      ,p_ins_rec_tab(i).rhi_receipt_num
                                      ,p_ins_rec_tab(i).rhi_receipt_header_id
                                      ,ln_vendor_id
                                      ,p_ins_rec_tab(i).rti_vendor_num
                                      ,ln_vendor_site_id
                                      ,p_ins_rec_tab(i).rti_vendor_site_code
                                      ,lc_from_organization_code
                                      ,lc_organization_code 
                                      ,gn_ship_to_organization_id
                                      ,p_ins_rec_tab(i).rti_location_code
                                      ,p_ins_rec_tab(i).rti_bill_of_lading
                                      ,p_ins_rec_tab(i).rti_packing_slip
                                      ,p_ins_rec_tab(i).rti_shipped_date
                                      ,p_ins_rec_tab(i).rti_freight_carrier_code 
                                      ,p_ins_rec_tab(i).rti_expected_receipt_date
                                      ,p_ins_rec_tab(i).rti_num_of_containers
                                      ,p_ins_rec_tab(i).rti_waybill_airbill_num
                                      ,p_ins_rec_tab(i).rti_comments
                                      ,p_ins_rec_tab(i).rhi_gross_weight
                                      ,p_ins_rec_tab(i).rhi_gross_weight_uom_code
                                      ,p_ins_rec_tab(i).rhi_net_weight
                                      ,p_ins_rec_tab(i).rhi_net_weight_uom_code
                                      ,p_ins_rec_tab(i).rhi_tar_weight 
                                      ,p_ins_rec_tab(i).rhi_tar_weight_uom_code
                                      ,p_ins_rec_tab(i).rhi_packaging_code
                                      ,p_ins_rec_tab(i).rhi_carrier_method
                                      ,p_ins_rec_tab(i).rhi_carrier_equipment
                                      ,p_ins_rec_tab(i).rhi_special_handling_code
                                      ,p_ins_rec_tab(i).rhi_hazard_code
                                      ,p_ins_rec_tab(i).rhi_hazard_class
                                      ,p_ins_rec_tab(i).rhi_hazard_description
                                      ,p_ins_rec_tab(i).rhi_freight_terms
                                      ,p_ins_rec_tab(i).rhi_freight_bill_number
                                      ,p_ins_rec_tab(i).rhi_invoice_num
                                      ,p_ins_rec_tab(i).rhi_invoice_date
                                      ,p_ins_rec_tab(i).rhi_total_invoice_amount
                                      ,p_ins_rec_tab(i).rti_tax_name
                                      ,p_ins_rec_tab(i).rti_tax_amount
                                      ,p_ins_rec_tab(i).rhi_freight_amount
                                      ,p_ins_rec_tab(i).rti_currency_code
                                      ,p_ins_rec_tab(i).rhi_conversion_rate_type
                                      ,p_ins_rec_tab(i).rhi_conversion_rate 
                                      ,p_ins_rec_tab(i).rhi_conversion_rate_date
                                      ,p_ins_rec_tab(i).rhi_payment_terms_name 
                                      ,p_ins_rec_tab(i).rhi_attribute_category
                                      ,p_ins_rec_tab(i).rhi_attribute1
                                      ,p_ins_rec_tab(i).rhi_attribute2
                                      ,p_ins_rec_tab(i).rhi_attribute3
                                      ,p_ins_rec_tab(i).rhi_attribute4
                                      ,p_ins_rec_tab(i).rhi_attribute5
                                      ,p_ins_rec_tab(i).rhi_attribute6
                                      ,p_ins_rec_tab(i).rhi_attribute7
                                      ,p_ins_rec_tab(i).rhi_attribute8
                                      ,p_ins_rec_tab(i).rhi_attribute9
                                      ,p_ins_rec_tab(i).rhi_attribute10
                                      ,p_ins_rec_tab(i).rhi_attribute11
                                      ,p_ins_rec_tab(i).rhi_attribute12
                                      ,p_ins_rec_tab(i).rhi_attribute13
                                      ,p_ins_rec_tab(i).rhi_attribute14
                                      ,p_ins_rec_tab(i).rhi_attribute15
                                      ,p_ins_rec_tab(i).rhi_employee_name
                                      ,p_ins_rec_tab(i).rhi_invoice_status_code
                                      ,p_ins_rec_tab(i).rti_validation_flag 
                                      ,p_ins_rec_tab(i).rti_customer_account_number
                                      ,p_ins_rec_tab(i).rti_customer_party_name
                                      ,p_ins_rec_tab(i).rti_transaction_date 
                                      ,lc_E0342_flag
                                      ,SYSDATE
                                      );
            END;
      END;
-- +===================================================================+
-- |KEYM LOGIC ENDS HERE                                               |
-- +===================================================================+

-- +===================================================================+
-- |KEYCL LOGIC BEGINS HERE                                            |
-- +===================================================================+
      BEGIN
                  SELECT 1
                  INTO   gn_dup_keyrec
                  FROM   xx_gi_rcv_po_hdr
                  WHERE  attribute8 =lc_rhi_attribute8  -- key rec number
                  AND    attribute4 = 'KEYCL';
         EXCEPTION
           WHEN NO_DATA_FOUND THEN
                 UPDATE  xx_gi_rcv_po_hdr  
                 SET     attribute4 = 'KEYCL'
                 WHERE   attribute8 =lc_rhi_attribute8 ;
      END;

-- +===================================================================+
-- |KEYCL LOGIC ENDS HERE                                              |
-- +===================================================================+

-- +===================================================================+
-- |OHDR/RVSC LOGIC BEGINS HERE                                        |
-- +===================================================================+
            -- condition to check whether  OHDR record has all eligible column
            -- condition to already header exists for the same keyrec-doc combination
        BEGIN
                  SELECT 1
                  INTO   gn_dup_keyrec
                  FROM   xx_gi_rcv_po_hdr
                  WHERE  attribute8 =lc_rhi_attribute8  -- Keyrec number
                  AND    attribute5 =lc_rhi_attribute5  -- doc num 
                  AND      attribute4 <>'KEYCL';
             -- condition to insert both header and dtl   
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
          BEGIN
               SELECT  header_interface_id
                      ,group_id 
               INTO    ln_head_nex_id
                      ,ln_grp_nex_id
               FROM    xx_gi_rcv_po_hdr 
               WHERE   attribute8 = p_ins_rec_tab(i).rhi_attribute8;
               dbms_output.put_line('ln_head_nex_id '||ln_head_nex_id);
               dbms_output.put_line('ln_grp_nex_id '||ln_grp_nex_id);
          EXCEPTION
               WHEN NO_DATA_FOUND THEN
                                     ln_sqlpoint:=420;
                  dbms_output.put_line('Before insert into HDR table '||ln_sqlpoint);
             
                  SELECT rcv_headers_interface_s.NEXTVAL
                  INTO   ln_head_nex_id 
                  FROM   sys.dual;
                           
                  SELECT rcv_interface_groups_s.NEXTVAL
                  INTO   ln_grp_nex_id
                  FROM   sys.dual;
                 
                  INSERT 
                  INTO xx_gi_rcv_po_hdr(
                                        header_interface_id
                                       ,group_id
                                       ,processing_status_code
                                       ,receipt_source_code
                                       ,asn_type
                                       ,transaction_type
                                       ,auto_transact_code
                                       ,last_update_date
                                       ,last_updated_by
                                       ,last_update_login
                                       ,creation_date
                                       ,created_by
                                       ,notice_creation_date
                                       ,shipment_num
                                       ,receipt_num
                                       ,receipt_header_id
                                       ,vendor_id
                                       ,vendor_num
                                       ,vendor_site_id
                                       ,vendor_site_code
                                       ,from_organization_code
                                       ,ship_to_organization_code
                                       ,ship_to_organization_id
                                       ,location_code
                                       ,bill_of_lading
                                       ,packing_slip
                                       ,shipped_date
                                       ,freight_carrier_code
                                       ,expected_receipt_date
                                       ,num_of_containers
                                       ,waybill_airbill_num
                                       ,comments
                                       ,gross_weight
                                       ,gross_weight_uom_code
                                       ,net_weight
                                       ,net_weight_uom_code
                                       ,tar_weight
                                       ,tar_weight_uom_code
                                       ,packaging_code
                                       ,carrier_method
                                       ,carrier_equipment
                                       ,special_handling_code
                                       ,hazard_code
                                       ,hazard_class
                                       ,hazard_description
                                       ,freight_terms
                                       ,freight_bill_number
                                       ,invoice_num
                                       ,invoice_date
                                       ,total_invoice_amount
                                       ,tax_name
                                       ,tax_amount
                                       ,freight_amount
                                       ,currency_code
                                       ,conversion_rate_type
                                       ,conversion_rate
                                       ,conversion_rate_date
                                       ,payment_terms_name
                                       ,attribute_category
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
                                       ,employee_name
                                       ,invoice_status_code
                                       ,validation_flag
                                       ,customer_account_number
                                       ,customer_party_name
                                       ,transaction_date
                                       ,E0342_status_flag
                                       ,E0342_first_rec_time
                                       )
                                       VALUES
                                       (
                                       ln_head_nex_id
                                      ,ln_grp_nex_id
                                      ,p_ins_rec_tab(i).rti_processing_status_code
                                      ,p_ins_rec_tab(i).rhi_receipt_source_code
                                      ,p_ins_rec_tab(i).rhi_asn_type
                                      ,p_ins_rec_tab(i).rti_transaction_type
                                      ,p_ins_rec_tab(i).rti_auto_transact_code
                                      ,p_ins_rec_tab(i).rti_last_update_date
                                      ,fnd_global.user_id  
                                      ,fnd_global.login_id 
                                      ,p_ins_rec_tab(i).rti_creation_date
                                      ,fnd_global.user_id  
                                      ,p_ins_rec_tab(i).rhi_notice_creation_date
                                      ,p_ins_rec_tab(i).rti_shipment_num
                                      ,p_ins_rec_tab(i).rhi_receipt_num
                                      ,p_ins_rec_tab(i).rhi_receipt_header_id
                                      ,ln_vendor_id
                                      ,p_ins_rec_tab(i).rti_vendor_num
                                      ,ln_vendor_site_id
                                      ,p_ins_rec_tab(i).rti_vendor_site_code
                                      ,lc_from_organization_code
                                      ,lc_organization_code 
                                      ,gn_ship_to_organization_id
                                      ,p_ins_rec_tab(i).rti_location_code
                                      ,p_ins_rec_tab(i).rti_bill_of_lading
                                      ,p_ins_rec_tab(i).rti_packing_slip
                                      ,p_ins_rec_tab(i).rti_shipped_date
                                      ,p_ins_rec_tab(i).rti_freight_carrier_code 
                                      ,p_ins_rec_tab(i).rti_expected_receipt_date
                                      ,p_ins_rec_tab(i).rti_num_of_containers
                                      ,p_ins_rec_tab(i).rti_waybill_airbill_num
                                      ,p_ins_rec_tab(i).rti_comments
                                      ,p_ins_rec_tab(i).rhi_gross_weight
                                      ,p_ins_rec_tab(i).rhi_gross_weight_uom_code
                                      ,p_ins_rec_tab(i).rhi_net_weight
                                      ,p_ins_rec_tab(i).rhi_net_weight_uom_code
                                      ,p_ins_rec_tab(i).rhi_tar_weight 
                                      ,p_ins_rec_tab(i).rhi_tar_weight_uom_code
                                      ,p_ins_rec_tab(i).rhi_packaging_code
                                      ,p_ins_rec_tab(i).rhi_carrier_method
                                      ,p_ins_rec_tab(i).rhi_carrier_equipment
                                      ,p_ins_rec_tab(i).rhi_special_handling_code
                                      ,p_ins_rec_tab(i).rhi_hazard_code
                                      ,p_ins_rec_tab(i).rhi_hazard_class
                                      ,p_ins_rec_tab(i).rhi_hazard_description
                                      ,p_ins_rec_tab(i).rhi_freight_terms
                                      ,p_ins_rec_tab(i).rhi_freight_bill_number
                                      ,p_ins_rec_tab(i).rhi_invoice_num
                                      ,p_ins_rec_tab(i).rhi_invoice_date
                                      ,p_ins_rec_tab(i).rhi_total_invoice_amount
                                      ,p_ins_rec_tab(i).rti_tax_name
                                      ,p_ins_rec_tab(i).rti_tax_amount
                                      ,p_ins_rec_tab(i).rhi_freight_amount
                                      ,p_ins_rec_tab(i).rti_currency_code
                                      ,p_ins_rec_tab(i).rhi_conversion_rate_type
                                      ,p_ins_rec_tab(i).rhi_conversion_rate 
                                      ,p_ins_rec_tab(i).rhi_conversion_rate_date
                                      ,p_ins_rec_tab(i).rhi_payment_terms_name 
                                      ,p_ins_rec_tab(i).rhi_attribute_category
                                      ,p_ins_rec_tab(i).rhi_attribute1
                                      ,p_ins_rec_tab(i).rhi_attribute2
                                      ,p_ins_rec_tab(i).rhi_attribute3
                                      ,p_ins_rec_tab(i).rhi_attribute4
                                      ,p_ins_rec_tab(i).rhi_attribute5
                                      ,p_ins_rec_tab(i).rhi_attribute6
                                      ,p_ins_rec_tab(i).rhi_attribute7
                                      ,p_ins_rec_tab(i).rhi_attribute8
                                      ,p_ins_rec_tab(i).rhi_attribute9
                                      ,p_ins_rec_tab(i).rhi_attribute10
                                      ,p_ins_rec_tab(i).rhi_attribute11
                                      ,p_ins_rec_tab(i).rhi_attribute12
                                      ,p_ins_rec_tab(i).rhi_attribute13
                                      ,p_ins_rec_tab(i).rhi_attribute14
                                      ,p_ins_rec_tab(i).rhi_attribute15
                                      ,p_ins_rec_tab(i).rhi_employee_name
                                      ,p_ins_rec_tab(i).rhi_invoice_status_code
                                      ,p_ins_rec_tab(i).rti_validation_flag 
                                      ,p_ins_rec_tab(i).rti_customer_account_number
                                      ,p_ins_rec_tab(i).rti_customer_party_name
                                      ,p_ins_rec_tab(i).rti_transaction_date 
                                      ,lc_E0342_flag
                                      ,SYSDATE
                                      );
          END; --exception2
        END;--exception1
               IF  ( p_ins_rec_tab(i).rti_quantity IS NOT NULL
                     AND p_ins_rec_tab(i).rti_item_num IS NOT NULL
                     AND  lc_key_rec_flag ='N' )      THEN
               
               SELECT rcv_transactions_interface_s.NEXTVAL
               INTO   ln_tran_nex_id
               FROM   sys.dual;
              
               INSERT 
               INTO xx_gi_rcv_po_dtl(
                                     header_interface_id
                                   , group_id
                                   , interface_transaction_id
                                   , last_update_date
                                   , last_updated_by
                                   , last_update_login
                                   , creation_date
                                   , created_by
                                   , request_id
                                   , program_update_date
                                   , transaction_type
                                   , transaction_date
                                   , processing_status_code
                                   , processing_mode_code
                                   , transaction_status_code
                                   , quantity
                                   , unit_of_measure
                                   , interface_source_code
                                   , inv_transaction_id
                                   , item_description
                                   , item_revision
                                   , uom_code
                                   , auto_transact_code
                                   , primary_quantity
                                   , primary_unit_of_measure
                                   , receipt_source_code
                                   , from_subinventory
                                   , source_document_code
                                   , parent_transaction_id
                                   , po_revision_num
                                   , po_unit_price
                                   , currency_code
                                   , currency_conversion_type
                                   , currency_conversion_rate
                                   , currency_conversion_date
                                   , substitute_unordered_code
                                   , receipt_exception_flag
                                   , accrual_status_code
                                   , inspection_status_code
                                   , inspection_quality_code
                                   , destination_type_code
                                   , subinventory
                                   , department_code
                                   , wip_operation_seq_num
                                   , wip_resource_seq_num
                                   , shipment_num
                                   , freight_carrier_code
                                   , bill_of_lading
                                   , packing_slip
                                   , shipped_date
                                   , expected_receipt_date
                                   , actual_cost
                                   , transfer_cost
                                   , transportation_cost
                                   , num_of_containers
                                   , waybill_airbill_num
                                   , vendor_item_num
                                   , vendor_lot_num
                                   , rma_reference
                                   , comments
                                   , attribute_category
                                   , attribute1
                                   , attribute2
                                   , attribute3
                                   , attribute4
                                   , attribute5
                                   , attribute6
                                   , attribute7
                                   , attribute8
                                   , attribute9
                                   , attribute10
                                   , attribute11
                                   , attribute12
                                   , attribute13
                                   , attribute14
                                   , attribute15
                                   , ship_head_attribute_category
                                   , ship_head_attribute1
                                   , ship_head_attribute2
                                   , ship_head_attribute3
                                   , ship_head_attribute4
                                   , ship_head_attribute5
                                   , ship_head_attribute6
                                   , ship_head_attribute7
                                   , ship_head_attribute8
                                   , ship_head_attribute9
                                   , ship_head_attribute10
                                   , ship_head_attribute11
                                   , ship_head_attribute12
                                   , ship_head_attribute13
                                   , ship_head_attribute14
                                   , ship_head_attribute15
                                   , ship_line_attribute_category
                                   , ship_line_attribute1
                                   , ship_line_attribute2
                                   , ship_line_attribute3
                                   , ship_line_attribute4
                                   , ship_line_attribute5
                                   , ship_line_attribute6
                                   , ship_line_attribute7
                                   , ship_line_attribute8
                                   , ship_line_attribute9
                                   , ship_line_attribute10
                                   , ship_line_attribute11
                                   , ship_line_attribute12
                                   , ship_line_attribute13
                                   , ship_line_attribute14
                                   , ship_line_attribute15
                                   , ussgl_transaction_code
                                   , government_context
                                   , destination_context
                                   , source_doc_quantity
                                   , source_doc_unit_of_measure
                                   , vendor_cum_shipped_qty
                                   , item_num
                                   , document_num
                                   , po_header_id
                                   , document_line_num
                                   , truck_num
                                   , ship_to_location_code
                                   , container_num
                                   , substitute_item_num
                                   , notice_unit_price
                                   , item_category
                                   , location_code
                                   , vendor_id
                                   , vendor_num
                                   , vendor_site_id
                                   , vendor_site_code
                                   , from_organization_code
                                   , to_organization_id
                                   , to_organization_code
                                   , intransit_owning_org_code
                                   , routing_code
                                   , routing_step
                                   , release_num
                                   , document_shipment_line_num
                                   , document_distribution_num
                                   , deliver_to_person_name
                                   , deliver_to_location_code
                                   , use_mtl_lot
                                   , use_mtl_serial
                                   , locator
                                   , reason_name
                                   , validation_flag
                                   , quantity_shipped
                                   , quantity_invoiced
                                   , tax_name
                                   , tax_amount
                                   , req_num
                                   , req_line_num
                                   , req_distribution_num
                                   , wip_entity_name
                                   , wip_line_code
                                   , resource_code
                                   , shipment_line_status_code
                                   , barcode_label
                                   , transfer_percentage
                                   , country_of_origin_code
                                   , oe_order_header_id
                                   , oe_order_line_id
                                   , customer_item_num
                                   , lpn_id
                                   , mobile_txn
                                   , secondary_quantity
                                   , secondary_unit_of_measure
                                   , secondary_uom_code
                                   , qc_grade
                                   , from_locator
                                   , interface_available_qty
                                   , interface_transaction_qty
                                   , interface_available_amt
                                   , interface_transaction_amt
                                   , license_plate_number
                                   , source_transaction_num
                                   , order_transaction_id
                                   , customer_account_number
                                   , customer_party_name
                                   , oe_order_line_num
                                   , oe_order_num
                                   , amount
                                   , timecard_ovn
                                   , E0342_status_flag
                                   , E0342_error_description
                                   , E0342_first_rec_time
                                    )
                                    VALUES
                                    (
                                     ln_head_nex_id
                                   , ln_grp_nex_id
                                   , ln_tran_nex_id
                                   , p_ins_rec_tab(i).rti_last_update_date
                                   , fnd_global.user_id  
                                   , fnd_global.login_id 
                                   , p_ins_rec_tab(i).rti_creation_date
                                   , fnd_global.user_id  
                                   , p_ins_rec_tab(i).rti_request_id
                                   , p_ins_rec_tab(i).rti_program_update_date
                                   , p_ins_rec_tab(i).rti_transaction_type
                                   , p_ins_rec_tab(i).rti_transaction_date
                                   , p_ins_rec_tab(i).rti_processing_status_code
                                   , p_ins_rec_tab(i).rti_processing_mode_code
                                   , p_ins_rec_tab(i).rti_transaction_status_code 
                                   , p_ins_rec_tab(i).rti_quantity
                                   , p_ins_rec_tab(i).rti_unit_of_measure
                                   , p_ins_rec_tab(i).rti_interface_source_code
                                   , p_ins_rec_tab(i).rti_inv_transaction_id 
                                   , p_ins_rec_tab(i).rti_item_description
                                   , p_ins_rec_tab(i).rti_item_revision
                                   , p_ins_rec_tab(i).rti_uom_code
                                   , p_ins_rec_tab(i).rti_auto_transact_code
                                   , p_ins_rec_tab(i).rti_primary_quantity
                                   , p_ins_rec_tab(i).rti_primary_unit_of_measure
                                   , p_ins_rec_tab(i).rhi_receipt_source_code
                                   , p_ins_rec_tab(i).rti_from_subinventory
                                   , p_ins_rec_tab(i).rti_source_document_code
                                   , p_ins_rec_tab(i).rti_parent_transaction_id
                                   , p_ins_rec_tab(i).rti_po_revision_num 
                                   , p_ins_rec_tab(i).rti_po_unit_price
                                   , p_ins_rec_tab(i).rti_currency_code
                                   , p_ins_rec_tab(i).rti_currency_conversion_type
                                   , p_ins_rec_tab(i).rti_currency_conversion_rate
                                   , p_ins_rec_tab(i).rti_currency_conversion_date
                                   , p_ins_rec_tab(i).rti_substitute_unordered_code
                                   , p_ins_rec_tab(i).rti_receipt_exception_flag
                                   , p_ins_rec_tab(i).rti_accrual_status_code 
                                   , p_ins_rec_tab(i).rti_inspection_status_code
                                   , p_ins_rec_tab(i).rti_inspection_quality_code
                                   , p_ins_rec_tab(i).rti_destination_type_code
                                   , p_ins_rec_tab(i).rti_subinventory
                                   , p_ins_rec_tab(i).rti_department_code
                                   , p_ins_rec_tab(i).rti_wip_operation_seq_num 
                                   , p_ins_rec_tab(i).rti_wip_resource_seq_num 
                                   , p_ins_rec_tab(i).rti_shipment_num
                                   , p_ins_rec_tab(i).rti_freight_carrier_code 
                                   , p_ins_rec_tab(i).rti_bill_of_lading 
                                   , p_ins_rec_tab(i).rti_packing_slip
                                   , p_ins_rec_tab(i).rti_shipped_date
                                   , p_ins_rec_tab(i).rti_expected_receipt_date
                                   , p_ins_rec_tab(i).rti_actual_cost
                                   , p_ins_rec_tab(i).rti_transfer_cost
                                   , p_ins_rec_tab(i).rti_transportation_cost
                                   , p_ins_rec_tab(i).rti_num_of_containers
                                   , p_ins_rec_tab(i).rti_waybill_airbill_num
                                   , p_ins_rec_tab(i).rti_vendor_item_num 
                                   , p_ins_rec_tab(i).rti_vendor_lot_num
                                   , p_ins_rec_tab(i).rti_rma_reference
                                   , p_ins_rec_tab(i).rti_comments 
                                   , p_ins_rec_tab(i).rhi_attribute_category
                                   , p_ins_rec_tab(i).rhi_attribute1
                                   , p_ins_rec_tab(i).rhi_attribute2
                                   , p_ins_rec_tab(i).rhi_attribute3
                                   , p_ins_rec_tab(i).rhi_attribute4
                                   , p_ins_rec_tab(i).rhi_attribute5
                                   , p_ins_rec_tab(i).rhi_attribute6
                                   , p_ins_rec_tab(i).rhi_attribute7
                                   , p_ins_rec_tab(i).rhi_attribute8
                                   , p_ins_rec_tab(i).rhi_attribute9
                                   , p_ins_rec_tab(i).rhi_attribute10
                                   , p_ins_rec_tab(i).rhi_attribute11
                                   , p_ins_rec_tab(i).rhi_attribute12
                                   , p_ins_rec_tab(i).rhi_attribute13
                                   , p_ins_rec_tab(i).rhi_attribute14
                                   , p_ins_rec_tab(i).rhi_attribute15
                                   , p_ins_rec_tab(i).rti_sh_att_cat
                                   , p_ins_rec_tab(i).rti_sh_att1
                                   , p_ins_rec_tab(i).rti_sh_att2
                                   , p_ins_rec_tab(i).rti_sh_att3
                                   , p_ins_rec_tab(i).rti_sh_att4
                                   , p_ins_rec_tab(i).rti_sh_att5
                                   , p_ins_rec_tab(i).rti_sh_att6
                                   , p_ins_rec_tab(i).rti_sh_att7
                                   , p_ins_rec_tab(i).rti_sh_att8
                                   , p_ins_rec_tab(i).rti_sh_att9
                                   , p_ins_rec_tab(i).rti_sh_att10
                                   , p_ins_rec_tab(i).rti_sh_att11
                                   , p_ins_rec_tab(i).rti_sh_att12
                                   , p_ins_rec_tab(i).rti_sh_att13
                                   , p_ins_rec_tab(i).rti_sh_att14
                                   , p_ins_rec_tab(i).rti_sh_att15
                                   , p_ins_rec_tab(i).rti_sl_att_cat
                                   , p_ins_rec_tab(i).rti_sl_att1
                                   , p_ins_rec_tab(i).rti_sl_att2
                                   , p_ins_rec_tab(i).rti_sl_att3
                                   , p_ins_rec_tab(i).rti_sl_att4
                                   , p_ins_rec_tab(i).rti_sl_att5
                                   , p_ins_rec_tab(i).rti_sl_att6
                                   , p_ins_rec_tab(i).rti_sl_att7
                                   , p_ins_rec_tab(i).rti_sl_att8
                                   , p_ins_rec_tab(i).rti_sl_att9
                                   , p_ins_rec_tab(i).rti_sl_att10
                                   , p_ins_rec_tab(i).rti_sl_att11
                                   , p_ins_rec_tab(i).rti_sl_att12
                                   , p_ins_rec_tab(i).rti_sl_att13
                                   , p_ins_rec_tab(i).rti_sl_att14
                                   , p_ins_rec_tab(i).rti_sl_att15
                                   , p_ins_rec_tab(i).rti_ussgl_transaction_code
                                   , p_ins_rec_tab(i).rti_government_context
                                   , p_ins_rec_tab(i).rti_destination_context
                                   , p_ins_rec_tab(i).rti_source_doc_quantity
                                   , p_ins_rec_tab(i).rti_source_doc_unit_of_measure
                                   , p_ins_rec_tab(i).rti_vendor_cum_shipped_qty
                                   , p_ins_rec_tab(i).rti_item_num
                                   , p_ins_rec_tab(i).rti_document_num
                                   , ln_po_header_id
                                   , p_ins_rec_tab(i).rti_document_line_num
                                   , p_ins_rec_tab(i).rti_truck_num
                                   , p_ins_rec_tab(i).rti_ship_to_location_code
                                   , p_ins_rec_tab(i).rti_container_num
                                   , p_ins_rec_tab(i).rti_substitute_item_num
                                   , p_ins_rec_tab(i).rti_notice_unit_price
                                   , p_ins_rec_tab(i).rti_item_category 
                                   , p_ins_rec_tab(i).rti_location_code 
                                   , ln_vendor_id
                                   , p_ins_rec_tab(i).rti_vendor_num
                                   , ln_vendor_site_id
                                   , p_ins_rec_tab(i).rti_vendor_site_code
                                   , p_ins_rec_tab(i).rti_from_organization_code
                                   , gn_ship_to_organization_id
                                   , lc_organization_code -- rti_to_organization_code 
                                   , p_ins_rec_tab(i).rti_intransit_owning_org_code
                                   , p_ins_rec_tab(i).rti_routing_code
                                   , p_ins_rec_tab(i).rti_routing_step
                                   , p_ins_rec_tab(i).rti_release_num
                                   , p_ins_rec_tab(i).rti_document_shipment_line_num
                                   , p_ins_rec_tab(i).rti_document_distribution_num
                                   , p_ins_rec_tab(i).rti_deliver_to_person_name
                                   , p_ins_rec_tab(i).rti_deliver_to_location_code 
                                   , p_ins_rec_tab(i).rti_use_mtl_lot 
                                   , p_ins_rec_tab(i).rti_use_mtl_serial
                                   , p_ins_rec_tab(i).rti_locator
                                   , p_ins_rec_tab(i).rti_reason_name 
                                   , p_ins_rec_tab(i).rti_validation_flag
                                   , p_ins_rec_tab(i).rti_quantity_shipped 
                                   , p_ins_rec_tab(i).rti_quantity_invoiced
                                   , p_ins_rec_tab(i).rti_tax_name 
                                   , p_ins_rec_tab(i).rti_tax_amount
                                   , p_ins_rec_tab(i).rti_req_num
                                   , p_ins_rec_tab(i).rti_req_line_num 
                                   , p_ins_rec_tab(i).rti_req_distribution_num
                                   , p_ins_rec_tab(i).rti_wip_entity_name 
                                   , p_ins_rec_tab(i).rti_wip_line_code
                                   , p_ins_rec_tab(i).rti_resource_code
                                   , p_ins_rec_tab(i).rti_shipment_line_status_code
                                   , p_ins_rec_tab(i).rti_barcode_label
                                   , p_ins_rec_tab(i).rti_transfer_percentage
                                   , p_ins_rec_tab(i).rti_country_of_origin_code 
                                   , p_ins_rec_tab(i).rti_oe_order_header_id
                                   , p_ins_rec_tab(i).rti_oe_order_line_id
                                   , p_ins_rec_tab(i).rti_customer_item_num
                                   , p_ins_rec_tab(i).rti_lpn_id 
                                   , p_ins_rec_tab(i).rti_mobile_txn 
                                   , p_ins_rec_tab(i).rti_secondary_quantity
                                   , p_ins_rec_tab(i).rti_secondary_unit_of_measure
                                   , p_ins_rec_tab(i).rti_secondary_uom_code
                                   , p_ins_rec_tab(i).rti_qc_grade 
                                   , p_ins_rec_tab(i).rti_from_locator
                                   , p_ins_rec_tab(i).rti_interface_available_qty
                                   , p_ins_rec_tab(i).rti_interface_transaction_qty
                                   , p_ins_rec_tab(i).rti_interface_available_amt
                                   , p_ins_rec_tab(i).rti_interface_transaction_amt 
                                   , p_ins_rec_tab(i).rti_license_plate_number 
                                   , p_ins_rec_tab(i).rti_source_transaction_num
                                   , p_ins_rec_tab(i).rti_order_transaction_id
                                   , p_ins_rec_tab(i).rti_customer_account_number
                                   , p_ins_rec_tab(i).rti_customer_party_name
                                   , p_ins_rec_tab(i).rti_oe_order_line_num 
                                   , p_ins_rec_tab(i).rti_oe_order_num 
                                   , p_ins_rec_tab(i).rti_amount 
                                   , p_ins_rec_tab(i).rti_timecard_ovn
                                   , lc_E0342_flag
                                   , SUBSTR(lc_ve_err_msg,1,2000)
                                   , SYSDATE
                                   );
            END IF;
            
            COMMIT;
                         
      
 BEGIN
                     SELECT 'Y'
                     INTO lc_flag
                     FROM rcv_headers_interface 
                     WHERE header_interface_id = ln_head_nex_id;
                   EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                IF lc_key_rec_flag ='N' THEN 
                          INSERT 
                          INTO rcv_headers_interface( 
                                                     header_interface_id  
                                                    ,group_id 
                                                    ,processing_status_code 
                                                    ,receipt_source_code 
                                                    ,transaction_type 
                                                    ,last_update_date 
                                                    ,last_updated_by 
                                                    ,last_update_login
                                                    ,creation_date
                                                    ,created_by 
                                                    ,shipped_date
                                                    ,vendor_name
                                                    ,validation_flag 
                                                    ,ship_to_organization_code
                                                    ,expected_receipt_date
                                                    ,receipt_num
                                                    ,num_of_containers
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
                                                    )
                                                    VALUES
                                                    (
                                                      ln_head_nex_id 
                                                     ,ln_grp_nex_id 
                                                     ,'PENDING'            --processing_status_code
                                                     ,'VENDOR'--receipt_source_code
                                                     ,lc_transaction_type_hdr  --transaction_type 
                                                     ,p_ins_rec_tab(i).rti_last_update_date
                                                     ,fnd_global.user_id  
                                                     ,fnd_global.login_id
                                                     ,p_ins_rec_tab(i).rti_creation_date
                                                     ,fnd_global.user_id
                                                     ,SYSDATE--p_ins_rec_tab(i).rti_shipped_date
                                                     ,lc_vendor_name
                                                     ,'Y'                                 --validation_flag  
                                                     ,lc_organization_code 
                                                     ,SYSDATE +5 --p_ins_rec_tab(i).rti_expected_receipt_date
                                                     ,p_ins_rec_tab(i).rhi_receipt_num 
                                                     ,p_ins_rec_tab(i).rti_num_of_containers
                                                     ,p_ins_rec_tab(i).rhi_attribute1
                                                     ,p_ins_rec_tab(i).rhi_attribute2
                                                     ,p_ins_rec_tab(i).rhi_attribute3
                                                     ,p_ins_rec_tab(i).rhi_attribute4
                                                     ,p_ins_rec_tab(i).rhi_attribute5
                                                     ,p_ins_rec_tab(i).rhi_attribute6
                                                     ,p_ins_rec_tab(i).rhi_attribute7
                                                     ,p_ins_rec_tab(i).rhi_attribute8
                                                     ,p_ins_rec_tab(i).rhi_attribute9
                                                     ,p_ins_rec_tab(i).rhi_attribute10
                                                     ,p_ins_rec_tab(i).rhi_attribute11
                                                     ,p_ins_rec_tab(i).rhi_attribute12
                                                     ,p_ins_rec_tab(i).rhi_attribute13
                                                     ,p_ins_rec_tab(i).rhi_attribute14
                                                     ,p_ins_rec_tab(i).rhi_attribute15
                                                     );
                   END IF;
                   END; 
                 --To avoid duplicate value in RTI
               
               DELETE FROM rcv_transactions_interface RTI
               WHERE interface_transaction_id = ln_tran_nex_id;
                dbms_output.put_line('inside To avoid duplicate value in RTI');
               COMMIT;
                          -- Insert Records into RTI
                          INSERT 
                          INTO rcv_transactions_interface( 
                                                          interface_transaction_id 
                                                         ,header_interface_id 
                                                         ,group_id 
                                                         ,last_update_date 
                                                         ,last_updated_by 
                                                         ,last_update_login 
                                                         ,creation_date 
                                                         ,created_by 
                                                         ,transaction_type 
                                                         ,transaction_date 
                                                         ,processing_status_code 
                                                         ,processing_mode_code 
                                                         ,transaction_status_code 
                                                         ,quantity
                                                         ,unit_of_measure 
                                                         ,auto_transact_code
                                                         ,receipt_source_code 
                                                         ,source_document_code
                                                         ,document_num
                                                         ,document_line_num
                                                         ,document_shipment_line_num
                                                         ,validation_flag
                                                         ,subinventory
                                                         ,to_organization_code
                                                         ,item_num
                                                         ,parent_transaction_id
                                                          )
                                                         VALUES
                                                         (
                                                         ln_tran_nex_id
                                                        ,ln_head_nex_id
                                                        ,ln_grp_nex_id
                                                        ,p_ins_rec_tab(i).rti_last_update_date
                                                        ,fnd_global.user_id 
                                                        ,fnd_global.login_id 
                                                        ,p_ins_rec_tab(i).rti_creation_date
                                                        ,fnd_global.user_id 
                                                        ,lc_transaction_type    --transaction_type , 
                                                        ,p_ins_rec_tab(i).rti_transaction_date
                                                        ,'PENDING'            --processing_status_code ,
                                                        ,'BATCH'             --processing_mode_code ,
                                                        ,'PENDING'             --transaction_status_code , 
                                                        ,p_ins_rec_tab(i).rti_quantity 
                                                        ,p_ins_rec_tab(i).rti_unit_of_measure
                                                        ,lc_auto_transact_code       --auto_transact_code,
                                                        ,p_ins_rec_tab(i).rhi_receipt_source_code
                                                        ,'PO'               --source_document_code ,
                                                        ,p_ins_rec_tab(i).rti_document_num
                                                        ,p_ins_rec_tab(i).rti_document_line_num
                                                        ,p_ins_rec_tab(i).rti_document_shipment_line_num
                                                        ,'Y'                       --validation_flag,
                                                        ,'STOCK'                   --subinventory,
                                                        ,lc_organization_code
                                                        ,p_ins_rec_tab(i).rti_item_num
                                                        ,NULL--ln_tran_id_deliver
                                                        );
                     COMMIT;
         END IF; -- IF lc_error_code='N'
-- +===================================================================+
-- |PO RECIPT  VALIDATION ENDS HERE                                    |
-- +===================================================================+
-- +===================================================================+
-- | VALIDATION FOR INTERORG RECEIPTS STARTS  HERE                     |
-- +===================================================================+
  dbms_output.put_line (' Before InV part');
        ELSIF  p_ins_rec_tab(i).rhi_receipt_source_code = 'INVENTORY' THEN
  dbms_output.put_line (' ENTERED INV part');
               IF (p_ins_rec_tab(i).rhi_attribute5 IS NULL 
                   AND p_ins_rec_tab(i).rti_shipment_num IS NULL) THEN
                       lc_error_flag := 'Y';
                       x_error_msg  := 'Shipment Num Not Exits';
                       dbms_output.put_line('Shipment Num  not exists '); 
                                                            
               ELSE                   
-- +=====================================================================+
-- |Copy Document Num to P_RTI_Attribute5 or viceversa, whichever is null|
-- +=====================================================================+
                   IF p_ins_rec_tab(i).rhi_attribute5  IS NOT NULL 
                      AND p_ins_rec_tab(i).rti_shipment_num IS  NULL THEN
-- +===================================================================+
-- Assigning rhi_attribute5 to Shipment_num                            |
-- +===================================================================+
                          p_ins_rec_tab(i).rti_shipment_num   := p_ins_rec_tab(i).rhi_attribute5;
                   END IF;
                                                  
                   IF p_ins_rec_tab(i).rhi_attribute5  IS NULL 
                      AND p_ins_rec_tab(i).rti_shipment_num IS NOT NULL THEN
-- +===================================================================+
-- Assigning Shipment_num to rhi_attribute5                            |
-- +===================================================================+
                          p_ins_rec_tab(i).rhi_attribute5 := p_ins_rec_tab(i).rti_shipment_num;
                   END IF;
                                 
               END IF;
                                 
-- +===================================================================+
-- Validation for Shipment Number from EBS                             |
-- +===================================================================+
            BEGIN
              SELECT  SUM(ABS(transaction_quantity))
                     ,shipment_number
              INTO    ln_trx_quantity
                     ,lc_shipment_number
              FROM    mtl_material_transactions
              WHERE   attribute5 = p_ins_rec_tab(i).rhi_attribute5
              AND     transaction_type_id =
                                           (
                                           SELECT transaction_type_id 
                                           FROM   mtl_transaction_types 
                                           WHERE  UPPER(transaction_type_name)=UPPER('Intransit Shipment')
                                           AND    disable_date IS NULL
                                           )
              GROUP BY shipment_number;
            EXCEPTION 
              WHEN NO_DATA_FOUND THEN
                     lc_error_flag := 'Y';
                                               
-- +===================================================================+
-- |Send out error message  as No data found                           |
-- +===================================================================+
                     lc_sqlerrm := SUBSTR(SQLERRM,1,250);
                     gc_err_desc := lc_sqlerrm;
                     x_error_msg :='NO_DATA for Shipment Num in EBS'||lc_sqlerrm;
                     dbms_output.put_line('NO_DATA for Shipment Num in EBS'); 
                                                            
                  WHEN OTHERS THEN
                     lc_error_flag := 'Y';
                                                   
-- +===================================================================+
-- | Send out error msg as Others Exception                            |
-- +===================================================================+
                     lc_sqlerrm := SUBSTR(SQLERRM,1,250);
                     gc_err_desc := lc_sqlerrm;
                     x_error_msg :=('OTHERS for Shipment Num from EBS :')||lc_sqlerrm;
                     dbms_output.put_line('OTHERS for Shipment Num from EBS'); 
                                                            
               END;
-- +===================================================================+
-- Validation for Shipment Header                                      |
-- +===================================================================+
     dbms_output.put_line ( 'Shipment NUM :'||lc_shipment_number);
             IF lc_shipment_number IS NOT NULL THEN 
               BEGIN        
                  SELECT RSH.shipment_header_id 
                  INTO   ln_shipment_header_id 
                  FROM   rcv_shipment_headers  RSH
                  WHERE  shipment_num= lc_shipment_number;
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     lc_error_flag := 'Y';
                                              
-- +===================================================================+
-- |Send No data Error msg for Shipment Header id                      |
-- +===================================================================+
                     lc_sqlerrm := SUBSTR(SQLERRM,1,250);
                     gc_err_desc := lc_sqlerrm;
                     x_error_msg :='NO_DATA Shipment Header for Shipment Num ;'||lc_sqlerrm;
                     dbms_output.put_line('NO_DATA  Shipment Header for Shipment Num '); 
                                                            
                  WHEN OTHERS THEN
                     lc_error_flag := 'Y';
                                                   
-- +===================================================================+
-- | Send Others Exception for Shipment Header id                      |
-- +===================================================================+
                     lc_sqlerrm := SUBSTR(SQLERRM,1,250);
                     gc_err_code := 'XX_GI_ATTR5_SHIP_ID_99999';
                     gc_err_desc :=  lc_sqlerrm;
                     x_error_msg :='OTHER Err of Shipment Header for Shipment Num  :'||lc_sqlerrm;
                    dbms_output.put_line('OTHER Err of Shipment Header for Shipment Num');
               END; 
            ELSE
               x_error_msg:='EBS Shipment Num  is NULL';
               dbms_output.put_line('EBS Shipment Num  is NULL');
            END IF;
                                                  
-- +===================================================================+
-- | Validation for FROM ORGANIZATION CODE                              |
-- +===================================================================+
               IF p_ins_rec_tab(i).rti_from_organization_code IS NULL 
                  AND p_ins_rec_tab(i).rhi_attribute1 IS NULL THEN
                      lc_error_flag := 'Y';
                                                    
-- +===================================================================+
-- | Send error out msg as From Org Code is NULL                       |
-- +===================================================================+
               x_error_msg:='From_organization_code  is NULL';
               dbms_output.put_line('From_organization_code  is NULL');

                                                            
               ELSE 
                   IF p_ins_rec_tab(i).rti_from_organization_code IS NULL THEN
-- +===================================================================+
-- | Calling the common utility function for from_organization_id      |
-- +===================================================================+
                      gn_from_organization_id := XX_GI_COMN_UTILS_PKG.GET_EBS_ORGANIZATION_ID(p_ins_rec_tab(i).rhi_attribute1);
     dbms_output.put_line ( 'From Org ID :'||gn_from_organization_id);
                      BEGIN
                         SELECT organization_code
                         INTO   lc_from_organization_code
                         FROM   org_organization_definitions
                         WHERE  organization_id = NVL(gn_from_organization_id,0);
                                                        
                      EXCEPTION
                         WHEN NO_DATA_FOUND THEN
                           lc_error_flag := 'Y';
                                                    
-- +===================================================================+
-- | Displays No data Error msg for EBS From_Org                       |
-- +===================================================================+
                           lc_sqlerrm := SUBSTR(SQLERRM,1,250);
                           x_error_msg :='NO_DATA_FOUND for From Org_Code ;'||lc_sqlerrm;
                           dbms_output.put_line('NO_DATA_FOUND for From Org_Code');
                                                              
                         WHEN OTHERS THEN
                           lc_error_flag := 'Y';
                                                                   
-- +===================================================================+
-- | Displays Others Exception for From_Org                            |
-- +===================================================================+
                           lc_sqlerrm := SUBSTR(SQLERRM,1,250);
                           x_error_msg :='OTHERS EXCEP for From Org_Code ;'||lc_sqlerrm;
                           dbms_output.put_line('OTHERS EXCEP for From Org_Code');
                                                              
                      END;
                   ELSE
                                                  
                     BEGIN
                       SELECT organization_id
                       INTO   gn_from_organization_id
                       FROM   org_organization_definitions
                       WHERE  organization_code = NVL(lc_from_organization_code,0);
                                                           
-- +===================================================================+
-- Calling the function for legacy_organization_code                   |
-- +===================================================================+
                       lc_rhi_attribute1 := XX_GI_COMN_UTILS_PKG.GET_LEGACY_LOC_ID(gn_from_organization_id);
                                                        
                     EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                         lc_error_flag := 'Y';
                         lc_sqlerrm := SUBSTR(SQLERRM,1,250);
                         x_error_msg :='NODATA for From Org_ID ;'||lc_sqlerrm;
                         dbms_output.put_line('NODATA for From Org_ID');
                            
                       WHEN OTHERS THEN
                         lc_error_flag := 'Y';
                                                     
-- +===================================================================+
-- | Send out Error Msg as Other Excep for From Org ID                 |
-- +===================================================================+
                         lc_sqlerrm := SUBSTR(SQLERRM,1,250);
                         x_error_msg :='OTHERS EXP for From Org_ID ;'||lc_sqlerrm;
                         dbms_output.put_line('OTHERS EXP for From Org_ID');
                     END;
                   END IF;
               END IF;
                                     
-- +===================================================================+
-- Insert Processed STR Records into Staging Table                     |
-- +===================================================================+
               IF lc_error_flag = 'N' THEN
 -- +===================================================================+
--  | 1.Consignment Validation  for interorg records  ELSE ERR OUT      |
--  | 2.Equal Quantity check    for interorg records  ESLE  insert to   |
--  |                           staging with  POD error status          |
-- +===================================================================+
                 
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
          AND   MSI.segment1                                = p_ins_rec_tab(i).rti_item_num
          AND   MP.organization_code                        = lc_from_organization_code;
                 FND_FILE.PUT_LINE (FND_FILE.LOG,'Item NUM and ID'||p_ins_rec_tab(i).rti_item_num||
                                                  ln_inventory_item_id||'From Org Code :'||
                                                  lc_from_organization_code);
     dbms_output.put_line ( 'lc_from_org_consgn_flag Value :'||lc_from_org_consgn_flag);
       EXCEPTION
         WHEN OTHERS THEN
-- +=================================================================+++++++=====+
-- | Inserts Consignment Validation Error msg to Error table using pkg           |
-- | XX_GI_RCV_ERR_PKG.XX_GI_INS_CUST_EXCEP  with proper error msg  for From Org |
-- +=============================================================================+
                 lc_from_org_consgn_flag :='B';
                 lc_error_flag := 'Y';
                 lc_sqlerrm  := SUBSTR (SQLERRM
                                       ,1
                                       ,200
                                      );
                 lc_error_msg:= ('Item Name :'||p_ins_rec_tab(i).rti_item_num||
                                 'Org Code :'||lc_from_organization_code||' : '||lc_sqlerrm);
                 FND_FILE.PUT_LINE (FND_FILE.LOG,'Item level Consignment Validation From Org Err :'
                                   ||'Item Name :'||p_ins_rec_tab(i).rti_item_num || ln_inventory_item_id
                                   ||'Org Code :'||lc_from_organization_code||': '||lc_error_msg);
                 gc_err_code := 'XX_GI_STR1';
                 gc_err_desc := 'Item level Consignment From Org Err : '||lc_error_msg; 
                 XX_GI_RCV_ERR_PKG.XX_GI_INS_CUST_EXCEP( 
                                                        gc_err_code
                                                        ,'INTERFACE_TRANSACTION_ID'
                                                        ,0
                                                        ,gc_err_desc
                                                        ,'XX_GI_STR1'
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
          AND  MSI.segment1                                = p_ins_rec_tab(i).rti_item_num
         AND   MP.organization_code                        = lc_organization_code;
                 FND_FILE.PUT_LINE (FND_FILE.LOG,'Item NUM and ID :'||p_ins_rec_tab(i).rti_item_num||
                                     ln_inventory_item_id||'To Org Code :'||lc_organization_code);
     dbms_output.put_line ( 'lc_to_org_consgn_flag Value :'||lc_to_org_consgn_flag);
       EXCEPTION
          WHEN OTHERS THEN
-- +=================================================================+++++++=====+
-- | Inserts Consignment Validation Error msg to Error table using pkg           |
-- | XX_GI_RCV_ERR_PKG.XX_GI_INS_CUST_EXCEP  with proper error msg  for To Org   |
-- +=============================================================================+
                 lc_to_org_consgn_flag := 'C';
                 lc_error_flag := 'Y';
                 lc_sqlerrm := SUBSTR (SQLERRM
                                       ,1
                                       ,200
                                      );
                 lc_error_msg:= ('Item Name :'||p_ins_rec_tab(i).rti_item_num||
                                 'Org Code :'||lc_organization_code||' :'||lc_sqlerrm);
                 FND_FILE.PUT_LINE (FND_FILE.LOG,'Consignment Validation To Org Err :'||lc_error_msg);
                 gc_err_code := 'XX_GI_STR1';
                 gc_err_desc := 'Item level Consignment To Org Err : '||lc_error_msg; 
                 XX_GI_RCV_ERR_PKG.XX_GI_INS_CUST_EXCEP(
                                                        gc_err_code
                                                        ,'INTERFACE_TRANSACTION_ID'
                                                        ,0
                                                        ,gc_err_desc
                                                        ,'XX_GI_STR1'
                 );
       END;
       FND_FILE.PUT_LINE(FND_FILE.LOG,'To_Org_consignment Flag :'||lc_to_org_consgn_flag ||
                                      ' From_Org_consignment Flag :'||lc_from_org_consgn_flag);
                                                                          
     dbms_output.put_line ( ' MMT QTY ;' ||ln_trx_quantity);
     dbms_output.put_line ( 'lc_E0342_flag outside :'|| lc_E0342_flag);
  
          IF (NVL(lc_to_org_consgn_flag,'X')= NVL(lc_from_org_consgn_flag,'X') and lc_error_flag='N') THEN  
-- +=================================================================+++++++=====+
-- |Change the E0342 status flag after EQUAL Quantity check                      |
-- | Below case works only for Equal quantity case other Non-Equal Qty case      |
-- | governed in E342b part                                                      |
-- +=============================================================================+
                    IF (p_ins_rec_tab(i).rti_quantity = ln_trx_quantity) THEN  
                    lc_E0342_flag := 'PL';
                    ELSIF (p_ins_rec_tab(i).rti_quantity <> ln_trx_quantity) THEN  
                    lc_E0342_flag := 'POD';
                    END IF;
          ELSE
-- +=================================================================+++++++=====+
-- |Change the E0342 status flag to VE                                           |
-- +=============================================================================+
          lc_E0342_flag := 'VE';
          END IF;
               ELSE
                  lc_E0342_flag := 'VE';
               END IF;
                                           
-- +===================================================================+
-- Inserting Header records only                                       |
-- +===================================================================+
     dbms_output.put_line ( ' attribute8 Value :'|| p_ins_rec_tab(i).rhi_attribute8 );
     dbms_output.put_line ( 'E0342_flag Value Before Insert header :'||lc_E0342_flag);
                  BEGIN
                    SELECT header_interface_id
                          ,group_id 
                    INTO   ln_head_nex_id
                          ,ln_grp_nex_id
                    FROM   xx_gi_rcv_str_hdr 
                    WHERE  attribute8 = p_ins_rec_tab(i).rhi_attribute8;
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
-- +===================================================================+
-- | Inserting Header records only for one time for any number of lines|
-- +===================================================================+
-- +===================================================================+
-- | INTERFACE HEADER ID AND BATCH ID GENERATION                       |
-- |            FOR HEADER/LINE InterOrg record                        |
-- +===================================================================+
                       SELECT rcv_headers_interface_s.NEXTVAL
                       INTO   ln_head_nex_id 
                       FROM   sys.dual;
                                    
                       SELECT rcv_interface_groups_s.NEXTVAL
                       INTO   ln_grp_nex_id
                       FROM   sys.dual;
                                                 
                       INSERT 
                       INTO xx_gi_rcv_str_hdr(
                                              header_interface_id
                                            , group_id
                                            , processing_status_code
                                            , receipt_source_code
                                            , asn_type
                                            , transaction_type
                                            , auto_transact_code
                                            , last_update_date
                                            , last_updated_by
                                            , last_update_login
                                            , creation_date
                                            , created_by
                                            , notice_creation_date
                                            , shipment_num
                                            , receipt_num
                                            , receipt_header_id
                                            , vendor_id
                                            , vendor_num
                                            , vendor_site_id
                                            , vendor_site_code
                                            , from_organization_code
                                            , from_organization_id
                                            , ship_to_organization_code
                                            , ship_to_organization_id
                                            , location_code
                                            , bill_of_lading
                                            , packing_slip
                                            , shipped_date
                                            , freight_carrier_code
                                            , expected_receipt_date
                                            , num_of_containers
                                            , waybill_airbill_num
                                            , comments
                                            , gross_weight
                                            , gross_weight_uom_code
                                            , net_weight
                                            , net_weight_uom_code
                                            , tar_weight
                                            , tar_weight_uom_code
                                            , packaging_code
                                            , carrier_method
                                            , carrier_equipment
                                            , special_handling_code
                                            , hazard_code
                                            , hazard_class
                                            , hazard_description
                                            , freight_terms
                                            , freight_bill_number
                                            , invoice_num
                                            , invoice_date
                                            , total_invoice_amount
                                            , tax_name
                                            , tax_amount
                                            , freight_amount
                                            , currency_code
                                            , conversion_rate_type
                                            , conversion_rate
                                            , conversion_rate_date
                                            , payment_terms_name
                                            , attribute_category
                                            , attribute1
                                            , attribute2
                                            , attribute3
                                            , attribute4
                                            , attribute5
                                            , attribute6
                                            , attribute7
                                            , attribute8
                                            , attribute9
                                            , attribute10
                                            , attribute11
                                            , attribute12
                                            , attribute13
                                            , attribute14
                                            , attribute15
                                            , employee_name
                                            , invoice_status_code
                                            , validation_flag
                                            , customer_account_number
                                            , customer_party_name
                                            , transaction_date
                                            , E0342_status_flag
                                            )
                                            VALUES
                                            (
                                            ln_head_nex_id
                                            , ln_grp_nex_id
                                            ,'PENDING'-- p_ins_rec_tab(i).rti_processing_status_code
                                            , p_ins_rec_tab(i).rhi_receipt_source_code
                                            , p_ins_rec_tab(i).rhi_asn_type
                                            , p_ins_rec_tab(i).rti_transaction_type
                                            , p_ins_rec_tab(i).rti_auto_transact_code
                                            , p_ins_rec_tab(i).rti_last_update_date
                                            , fnd_global.user_id  
                                            , fnd_global.login_id 
                                            , p_ins_rec_tab(i).rti_creation_date
                                            , fnd_global.user_id  
                                            , p_ins_rec_tab(i).rhi_notice_creation_date
                                            , lc_shipment_number
                                            , ln_rec_nex_id
                                            , p_ins_rec_tab(i).rhi_receipt_header_id
                                            , ln_vendor_id
                                            , p_ins_rec_tab(i).rti_vendor_num
                                            , ln_vendor_site_id
                                            , p_ins_rec_tab(i).rti_vendor_site_code
                                            , lc_from_organization_code
                                            , gn_from_organization_id
                                            , lc_organization_code
                                            , gn_ship_to_organization_id
                                            , p_ins_rec_tab(i).rti_location_code
                                            , p_ins_rec_tab(i).rti_bill_of_lading
                                            , p_ins_rec_tab(i).rti_packing_slip
                                            , p_ins_rec_tab(i).rti_shipped_date
                                            , p_ins_rec_tab(i).rti_freight_carrier_code 
                                            , p_ins_rec_tab(i).rhi_expected_receipt_date
                                            , p_ins_rec_tab(i).rti_num_of_containers
                                            , p_ins_rec_tab(i).rti_waybill_airbill_num
                                            , p_ins_rec_tab(i).rti_comments
                                            , p_ins_rec_tab(i).rhi_gross_weight
                                            , p_ins_rec_tab(i).rhi_gross_weight_uom_code
                                            , p_ins_rec_tab(i).rhi_net_weight
                                            , p_ins_rec_tab(i).rhi_net_weight_uom_code
                                            , p_ins_rec_tab(i).rhi_tar_weight 
                                            , p_ins_rec_tab(i).rhi_tar_weight_uom_code
                                            , p_ins_rec_tab(i).rhi_packaging_code
                                            , p_ins_rec_tab(i).rhi_carrier_method
                                            , p_ins_rec_tab(i).rhi_carrier_equipment
                                            , p_ins_rec_tab(i).rhi_special_handling_code
                                            , p_ins_rec_tab(i).rhi_hazard_code
                                            , p_ins_rec_tab(i).rhi_hazard_class
                                            , p_ins_rec_tab(i).rhi_hazard_description
                                            , p_ins_rec_tab(i).rhi_freight_terms
                                            , p_ins_rec_tab(i).rhi_freight_bill_number
                                            , p_ins_rec_tab(i).rhi_invoice_num
                                            , p_ins_rec_tab(i).rhi_invoice_date
                                            , p_ins_rec_tab(i).rhi_total_invoice_amount
                                            , p_ins_rec_tab(i).rti_tax_name
                                            , p_ins_rec_tab(i).rti_tax_amount
                                            , p_ins_rec_tab(i).rhi_freight_amount
                                            , p_ins_rec_tab(i).rti_currency_code
                                            , p_ins_rec_tab(i).rhi_conversion_rate_type
                                            , p_ins_rec_tab(i).rhi_conversion_rate 
                                            , p_ins_rec_tab(i).rhi_conversion_rate_date
                                            , p_ins_rec_tab(i).rhi_payment_terms_name 
                                            , p_ins_rec_tab(i).rhi_attribute_category
                                            , p_ins_rec_tab(i).rhi_attribute1
                                            , p_ins_rec_tab(i).rhi_attribute2
                                            , NULL--p_ins_rec_tab(i).rhi_attribute3  -- no specific sku at header
                                            , p_ins_rec_tab(i).rhi_attribute4
                                            , p_ins_rec_tab(i).rhi_attribute5
                                            , p_ins_rec_tab(i).rhi_attribute6
                                            , p_ins_rec_tab(i).rhi_attribute7
                                            , p_ins_rec_tab(i).rhi_attribute8
                                            , p_ins_rec_tab(i).rhi_attribute9
                                            , p_ins_rec_tab(i).rhi_attribute10
                                            , p_ins_rec_tab(i).rhi_attribute11
                                            , p_ins_rec_tab(i).rhi_attribute12
                                            , p_ins_rec_tab(i).rhi_attribute13
                                            , p_ins_rec_tab(i).rhi_attribute14
                                            , p_ins_rec_tab(i).rhi_attribute15
                                            , p_ins_rec_tab(i).rhi_employee_name
                                            , p_ins_rec_tab(i).rhi_invoice_status_code
                                            , p_ins_rec_tab(i).rti_validation_flag 
                                            , p_ins_rec_tab(i).rti_customer_account_number
                                            , p_ins_rec_tab(i).rti_customer_party_name
                                            , p_ins_rec_tab(i).rti_transaction_date
                                            , lc_E0342_flag
                                            );
                         END;
                           IF  (p_ins_rec_tab(i).rti_quantity IS NOT NULL
                               AND p_ins_rec_tab(i).rti_item_num IS NOT NULL 
                               AND  lc_key_rec_flag ='N') THEN
                                                
-- +===================================================================+
-- | INTERFACE TRANSACTION ID GENERATION FOR LINE InterOrg record      |
-- +===================================================================+
                              SELECT rcv_transactions_interface_s.NEXTVAL
                              INTO   ln_tran_nex_id
                              FROM   sys.dual;
     dbms_output.put_line ( 'E0342_flag Value Before Insert Lines :'||lc_E0342_flag);
-- +===================================================================+
-- | Inserting Line records only for one time for that header info     |
-- +===================================================================+
                                        
                              INSERT 
                              INTO  xx_gi_rcv_str_dtl(
                                                      header_interface_id
                                                     , group_id
                                                     , interface_transaction_id 
                                                     , last_update_date 
                                                     , last_updated_by
                                                     , last_update_login
                                                     , creation_date
                                                     , created_by
                                                     , request_id
                                                     , program_update_date
                                                     , transaction_type
                                                     , transaction_date
                                                     , processing_status_code
                                                     , processing_mode_code
                                                     , transaction_status_code
                                                     , quantity
                                                     , unit_of_measure
                                                     , interface_source_code
                                                     , inv_transaction_id
                                                     , item_description
                                                     , item_revision
                                                     , uom_code
                                                     , auto_transact_code
                                                     , primary_quantity
                                                     , primary_unit_of_measure
                                                     , receipt_source_code
                                                     , from_subinventory
                                                     , source_document_code
                                                     , parent_transaction_id
                                                     , po_revision_num
                                                     , po_unit_price
                                                     , currency_code
                                                     , currency_conversion_type
                                                     , currency_conversion_rate
                                                     , currency_conversion_date
                                                     , substitute_unordered_code
                                                     , receipt_exception_flag
                                                     , accrual_status_code
                                                     , inspection_status_code
                                                     , inspection_quality_code
                                                     , destination_type_code
                                                     , subinventory
                                                     , department_code
                                                     , wip_operation_seq_num
                                                     , wip_resource_seq_num
                                                     , shipment_num
                                                     , freight_carrier_code
                                                     , bill_of_lading
                                                     , packing_slip
                                                     , shipped_date
                                                     , expected_receipt_date
                                                     , actual_cost
                                                     , transfer_cost
                                                     , transportation_cost
                                                     , num_of_containers
                                                     , waybill_airbill_num
                                                     , vendor_item_num
                                                     , vendor_lot_num
                                                     , rma_reference
                                                     , comments
                                                     , attribute_category
                                                     , attribute1
                                                     , attribute2
                                                     , attribute3
                                                     , attribute4
                                                     , attribute5
                                                     , attribute6
                                                     , attribute7
                                                     , attribute8
                                                     , attribute9
                                                     , attribute10
                                                     , attribute11
                                                     , attribute12
                                                     , attribute13
                                                     , attribute14
                                                     , attribute15
                                                     , ship_head_attribute_category
                                                     , ship_head_attribute1
                                                     , ship_head_attribute2
                                                     , ship_head_attribute3
                                                     , ship_head_attribute4
                                                     , ship_head_attribute5
                                                     , ship_head_attribute6
                                                     , ship_head_attribute7
                                                     , ship_head_attribute8
                                                     , ship_head_attribute9
                                                     , ship_head_attribute10
                                                     , ship_head_attribute11
                                                     , ship_head_attribute12
                                                     , ship_head_attribute13
                                                     , ship_head_attribute14
                                                     , ship_head_attribute15
                                                     , ship_line_attribute_category
                                                     , ship_line_attribute1
                                                     , ship_line_attribute2
                                                     , ship_line_attribute3
                                                     , ship_line_attribute4
                                                     , ship_line_attribute5
                                                     , ship_line_attribute6
                                                     , ship_line_attribute7
                                                     , ship_line_attribute8
                                                     , ship_line_attribute9
                                                     , ship_line_attribute10
                                                     , ship_line_attribute11
                                                     , ship_line_attribute12
                                                     , ship_line_attribute13
                                                     , ship_line_attribute14
                                                     , ship_line_attribute15
                                                     , ussgl_transaction_code
                                                     , government_context
                                                     , destination_context
                                                     , source_doc_quantity
                                                     , source_doc_unit_of_measure
                                                     , vendor_cum_shipped_qty
                                                     , item_num
                                                     , document_num
                                                     , document_line_num
                                                     , truck_num
                                                     , ship_to_location_code
                                                     , container_num
                                                     , substitute_item_num
                                                     , notice_unit_price
                                                     , item_category
                                                     , location_code
                                                     , vendor_id
                                                     , vendor_num
                                                     , vendor_site_id
                                                     , vendor_site_code
                                                     , from_organization_code
                                                     , from_organization_id
                                                     , to_organization_code
                                                     , to_organization_id
                                                     , intransit_owning_org_code
                                                     , routing_code
                                                     , routing_step
                                                     , release_num
                                                     , document_shipment_line_num
                                                     , document_distribution_num
                                                     , deliver_to_person_name
                                                     , deliver_to_location_code
                                                     , use_mtl_lot
                                                     , use_mtl_serial
                                                     , locator
                                                     , reason_name
                                                     , validation_flag
                                                     , quantity_shipped
                                                     , quantity_invoiced
                                                     , tax_name
                                                     , tax_amount
                                                     , req_num
                                                     , req_line_num
                                                     , req_distribution_num
                                                     , wip_entity_name
                                                     , wip_line_code
                                                     , resource_code
                                                     , shipment_line_status_code
                                                     , barcode_label
                                                     , transfer_percentage
                                                     , country_of_origin_code
                                                     , oe_order_header_id
                                                     , oe_order_line_id
                                                     , customer_item_num
                                                     , lpn_id
                                                     , mobile_txn
                                                     , secondary_quantity
                                                     , secondary_unit_of_measure
                                                     , secondary_uom_code
                                                     , qc_grade
                                                     , from_locator
                                                     , interface_available_qty
                                                     , interface_transaction_qty
                                                     , interface_available_amt
                                                     , interface_transaction_amt
                                                     , license_plate_number
                                                     , source_transaction_num
                                                     , order_transaction_id
                                                     , customer_account_number
                                                     , customer_party_name
                                                     , oe_order_line_num
                                                     , oe_order_num
                                                     , amount
                                                     , timecard_ovn
                                                     , E0342_status_flag
                                                     , shipment_header_id
                                                     )
                                                     VALUES
                                                     (
                                                       ln_head_nex_id
                                                     , ln_grp_nex_id	
                                                     , ln_tran_nex_id
                                                     , p_ins_rec_tab(i).rti_last_update_date
                                                     , fnd_global.user_id  
                                                     , fnd_global.login_id 
                                                     , p_ins_rec_tab(i).rti_creation_date
                                                     , fnd_global.user_id  
                                                     , p_ins_rec_tab(i).rti_request_id
                                                     , p_ins_rec_tab(i).rti_program_update_date
                                                     , p_ins_rec_tab(i).rti_transaction_type
                                                     , p_ins_rec_tab(i).rti_transaction_date
                                                     , 'PENDING' -- p_ins_rec_tab(i).rti_processing_status_code
                                                     , 'BATCH' -- p_ins_rec_tab(i).rti_processing_mode_code
                                                     ,'PENDING' -- p_ins_rec_tab(i).rti_transaction_status_code 
                                                     , p_ins_rec_tab(i).rti_quantity
                                                     , p_ins_rec_tab(i).rti_unit_of_measure
                                                     , p_ins_rec_tab(i).rti_interface_source_code
                                                     , p_ins_rec_tab(i).rti_inv_transaction_id 
                                                     , p_ins_rec_tab(i).rti_item_description
                                                     , p_ins_rec_tab(i).rti_item_revision
                                                     , p_ins_rec_tab(i).rti_uom_code
                                                     , p_ins_rec_tab(i).rti_auto_transact_code
                                                     , p_ins_rec_tab(i).rti_primary_quantity
                                                     , p_ins_rec_tab(i).rti_primary_unit_of_measure
                                                     , p_ins_rec_tab(i).rti_receipt_source_code
                                                     , p_ins_rec_tab(i).rti_from_subinventory
                                                     , p_ins_rec_tab(i).rti_source_document_code
                                                     , p_ins_rec_tab(i).rti_parent_transaction_id
                                                     , p_ins_rec_tab(i).rti_po_revision_num 
                                                     , p_ins_rec_tab(i).rti_po_unit_price
                                                     , p_ins_rec_tab(i).rti_currency_code
                                                     , p_ins_rec_tab(i).rti_currency_conversion_type
                                                     , p_ins_rec_tab(i).rti_currency_conversion_rate
                                                     , p_ins_rec_tab(i).rti_currency_conversion_date
                                                     , p_ins_rec_tab(i).rti_substitute_unordered_code
                                                     , p_ins_rec_tab(i).rti_receipt_exception_flag
                                                     , p_ins_rec_tab(i).rti_accrual_status_code 
                                                     , p_ins_rec_tab(i).rti_inspection_status_code
                                                     , p_ins_rec_tab(i).rti_inspection_quality_code
                                                     , p_ins_rec_tab(i).rti_destination_type_code
                                                     , p_ins_rec_tab(i).rti_subinventory
                                                     , p_ins_rec_tab(i).rti_department_code
                                                     , p_ins_rec_tab(i).rti_wip_operation_seq_num 
                                                     , p_ins_rec_tab(i).rti_wip_resource_seq_num 
                                                     , lc_shipment_number
                                                     , p_ins_rec_tab(i).rti_freight_carrier_code 
                                                     , p_ins_rec_tab(i).rti_bill_of_lading 
                                                     , p_ins_rec_tab(i).rti_packing_slip
                                                     , p_ins_rec_tab(i).rti_shipped_date
                                                     , p_ins_rec_tab(i).rhi_expected_receipt_date
                                                     , p_ins_rec_tab(i).rti_actual_cost
                                                     , p_ins_rec_tab(i).rti_transfer_cost
                                                     , p_ins_rec_tab(i).rti_transportation_cost
                                                     , p_ins_rec_tab(i).rti_num_of_containers
                                                     , p_ins_rec_tab(i).rti_waybill_airbill_num
                                                     , p_ins_rec_tab(i).rti_vendor_item_num 
                                                     , p_ins_rec_tab(i).rti_vendor_lot_num
                                                     , p_ins_rec_tab(i).rti_rma_reference
                                                     , p_ins_rec_tab(i).rti_comments 
                                                     , p_ins_rec_tab(i).rhi_attribute_category
                                                     , p_ins_rec_tab(i).rhi_attribute1
                                                     , p_ins_rec_tab(i).rhi_attribute2
                                                     , p_ins_rec_tab(i).rhi_attribute3
                                                     , p_ins_rec_tab(i).rhi_attribute4
                                                     , p_ins_rec_tab(i).rhi_attribute5
                                                     , p_ins_rec_tab(i).rhi_attribute6
                                                     , p_ins_rec_tab(i).rhi_attribute7
                                                     , p_ins_rec_tab(i).rhi_attribute8
                                                     , p_ins_rec_tab(i).rhi_attribute9
                                                     , p_ins_rec_tab(i).rhi_attribute10
                                                     , p_ins_rec_tab(i).rhi_attribute11
                                                     , p_ins_rec_tab(i).rhi_attribute12
                                                     , p_ins_rec_tab(i).rhi_attribute13
                                                     , p_ins_rec_tab(i).rhi_attribute14
                                                     , p_ins_rec_tab(i).rhi_attribute15
                                                     , p_ins_rec_tab(i).rti_sh_att_cat
                                                     , p_ins_rec_tab(i).rti_sh_att1
                                                     , p_ins_rec_tab(i).rti_sh_att2
                                                     , p_ins_rec_tab(i).rti_sh_att3
                                                     , p_ins_rec_tab(i).rti_sh_att4
                                                     , p_ins_rec_tab(i).rti_sh_att5
                                                     , p_ins_rec_tab(i).rti_sh_att6
                                                     , p_ins_rec_tab(i).rti_sh_att7
                                                     , p_ins_rec_tab(i).rti_sh_att8
                                                     , p_ins_rec_tab(i).rti_sh_att9
                                                     , p_ins_rec_tab(i).rti_sh_att10
                                                     , p_ins_rec_tab(i).rti_sh_att11
                                                     , p_ins_rec_tab(i).rti_sh_att12
                                                     , p_ins_rec_tab(i).rti_sh_att13
                                                     , p_ins_rec_tab(i).rti_sh_att14
                                                     , p_ins_rec_tab(i).rti_sh_att15
                                                     , p_ins_rec_tab(i).rti_sl_att_cat
                                                     , p_ins_rec_tab(i).rti_sl_att1
                                                     , p_ins_rec_tab(i).rti_sl_att2
                                                     , p_ins_rec_tab(i).rti_sl_att3
                                                     , p_ins_rec_tab(i).rti_sl_att4
                                                     , p_ins_rec_tab(i).rti_sl_att5
                                                     , p_ins_rec_tab(i).rti_sl_att6
                                                     , p_ins_rec_tab(i).rti_sl_att7
                                                     , p_ins_rec_tab(i).rti_sl_att8
                                                     , p_ins_rec_tab(i).rti_sl_att9
                                                     , p_ins_rec_tab(i).rti_sl_att10
                                                     , p_ins_rec_tab(i).rti_sl_att11
                                                     , p_ins_rec_tab(i).rti_sl_att12
                                                     , p_ins_rec_tab(i).rti_sl_att13
                                                     , p_ins_rec_tab(i).rti_sl_att14
                                                     , p_ins_rec_tab(i).rti_sl_att15
                                                     , p_ins_rec_tab(i).rti_ussgl_transaction_code
                                                     , p_ins_rec_tab(i).rti_government_context
                                                     , p_ins_rec_tab(i).rti_destination_context
                                                     , p_ins_rec_tab(i).rti_source_doc_quantity
                                                     , p_ins_rec_tab(i).rti_source_doc_unit_of_measure
                                                     , p_ins_rec_tab(i).rti_vendor_cum_shipped_qty
                                                     , p_ins_rec_tab(i).rti_item_num
                                                     , NULL--p_ins_rec_tab(i).rti_document_num  --Not comes for Interorg
                                                     , NULL--p_ins_rec_tab(i).rti_document_line_num
                                                     , p_ins_rec_tab(i).rti_truck_num
                                                     , p_ins_rec_tab(i).rti_ship_to_location_code
                                                     , p_ins_rec_tab(i).rti_container_num
                                                     , p_ins_rec_tab(i).rti_substitute_item_num
                                                     , p_ins_rec_tab(i).rti_notice_unit_price
                                                     , p_ins_rec_tab(i).rti_item_category 
                                                     , p_ins_rec_tab(i).rti_location_code 
                                                     , ln_vendor_id
                                                     , p_ins_rec_tab(i).rti_vendor_num
                                                     , ln_vendor_site_id
                                                     , p_ins_rec_tab(i).rti_vendor_site_code
                                                     , lc_from_organization_code
                                                     , gn_from_organization_id
                                                     , lc_organization_code 
                                                     , gn_ship_to_organization_id
                                                     , p_ins_rec_tab(i).rti_intransit_owning_org_code
                                                     , p_ins_rec_tab(i).rti_routing_code
                                                     , p_ins_rec_tab(i).rti_routing_step
                                                     , p_ins_rec_tab(i).rti_release_num
                                                     , p_ins_rec_tab(i).rti_document_shipment_line_num
                                                     , p_ins_rec_tab(i).rti_document_distribution_num
                                                     , p_ins_rec_tab(i).rti_deliver_to_person_name
                                                     , p_ins_rec_tab(i).rti_deliver_to_location_code 
                                                     , p_ins_rec_tab(i).rti_use_mtl_lot 
                                                     , p_ins_rec_tab(i).rti_use_mtl_serial
                                                     , p_ins_rec_tab(i).rti_locator
                                                     , p_ins_rec_tab(i).rti_reason_name 
                                                     , p_ins_rec_tab(i).rti_validation_flag
                                                     , p_ins_rec_tab(i).rti_quantity_shipped 
                                                     , p_ins_rec_tab(i).rti_quantity_invoiced
                                                     , p_ins_rec_tab(i).rti_tax_name 
                                                     , p_ins_rec_tab(i).rti_tax_amount
                                                     , p_ins_rec_tab(i).rti_req_num
                                                     , p_ins_rec_tab(i).rti_req_line_num 
                                                     , p_ins_rec_tab(i).rti_req_distribution_num
                                                     , p_ins_rec_tab(i).rti_wip_entity_name 
                                                     , p_ins_rec_tab(i).rti_wip_line_code
                                                     , p_ins_rec_tab(i).rti_resource_code
                                                     , p_ins_rec_tab(i).rti_shipment_line_status_code
                                                     , p_ins_rec_tab(i).rti_barcode_label
                                                     , p_ins_rec_tab(i).rti_transfer_percentage
                                                     , p_ins_rec_tab(i).rti_country_of_origin_code 
                                                     , p_ins_rec_tab(i).rti_oe_order_header_id
                                                     , p_ins_rec_tab(i).rti_oe_order_line_id
                                                     , p_ins_rec_tab(i).rti_customer_item_num
                                                     , p_ins_rec_tab(i).rti_lpn_id 
                                                     , p_ins_rec_tab(i).rti_mobile_txn 
                                                     , p_ins_rec_tab(i).rti_secondary_quantity
                                                     , p_ins_rec_tab(i).rti_secondary_unit_of_measure
                                                     , p_ins_rec_tab(i).rti_secondary_uom_code
                                                     , p_ins_rec_tab(i).rti_qc_grade 
                                                     , p_ins_rec_tab(i).rti_from_locator
                                                     , p_ins_rec_tab(i).rti_interface_available_qty
                                                     , p_ins_rec_tab(i).rti_interface_transaction_qty
                                                     , p_ins_rec_tab(i).rti_interface_available_amt
                                                     , p_ins_rec_tab(i).rti_interface_transaction_amt 
                                                     , p_ins_rec_tab(i).rti_license_plate_number 
                                                     , p_ins_rec_tab(i).rti_source_transaction_num
                                                     , p_ins_rec_tab(i).rti_order_transaction_id
                                                     , p_ins_rec_tab(i).rti_customer_account_number
                                                     , p_ins_rec_tab(i).rti_customer_party_name
                                                     , p_ins_rec_tab(i).rti_oe_order_line_num 
                                                     , p_ins_rec_tab(i).rti_oe_order_num 
                                                     , p_ins_rec_tab(i).rti_amount 
                                                     , p_ins_rec_tab(i).rti_timecard_ovn
                                                     , lc_E0342_flag   -- 'PL' OR 'VE' 
                                                     , ln_shipment_header_id
                                                     );
                           END IF;
-- +===================================================================+
-- Updating RTI Interface Transactions ID to Custom Error Table        |
-- intially interface_trns_id used as 0 (zero) replace orig            |
-- +===================================================================+
                         IF lc_error_flag = 'Y' THEN
                           UPDATE xx_gi_error_tbl
                           SET    entity_ref_id  =  ln_tran_nex_id
                           WHERE  entity_ref_id  =  0;
                         END IF;
             
             IF (lc_E0342_flag='PL' and lc_error_flag = 'N') THEN 
-- +====================================================================+
-- | Inserting only Header and line records inserted to STG in PL status|
-- +====================================================================+
             INSERT INTO apps.RCV_HEADERS_INTERFACE
                                                     (header_interface_id
                                                     , group_id
                                                     , processing_status_code
                                                     , receipt_source_code
                                                     , transaction_type
                                                     , auto_transact_code
                                                     , last_update_date
                                                     , last_updated_by
                                                     , last_update_login
                                                     , creation_date
                                                     , created_by
                                                     , shipment_num
                                                     , ship_to_organization_id
                                                     , expected_receipt_date
                                                     , validation_flag
                                                     , attribute1
                                                     , attribute2
                                                     , attribute3
                                                     , attribute4
                                                     , attribute5
                                                     , attribute6
                                                     , attribute7
                                                     , attribute8
                                                     , attribute9
                                                     , attribute10
                                                     , attribute11
                                                     , attribute12
                                                     , attribute13
                                                     , attribute14
                                                     , attribute15
                                                     )
                                                     SELECT 
                                                      header_interface_id
                                                     , group_id
                                                     , processing_status_code
                                                     , receipt_source_code
                                                     , transaction_type
                                                     , auto_transact_code
                                                     , last_update_date
                                                     , last_updated_by
                                                     , last_update_login
                                                     , creation_date
                                                     , created_by
                                                     , shipment_num
                                                     , ship_to_organization_id
                                                     , expected_receipt_date
                                                     , validation_flag
                                                     , attribute1
                                                     , attribute2
                                                     , attribute3
                                                     , attribute4
                                                     , attribute5
                                                     , attribute6
                                                     , attribute7
                                                     , attribute8
                                                     , attribute9
                                                     , attribute10
                                                     , attribute11
                                                     , attribute12
                                                     , attribute13
                                                     , attribute14
                                                     , attribute15
                                                     FROM  xx_gi_rcv_str_hdr
                                                     WHERE HEADER_INTERFACE_ID = ln_head_nex_id; 
--
                                         INSERT INTO apps.RCV_TRANSACTIONS_INTERFACE
                                                     ( interface_transaction_id
                                                     , group_id
                                                     , last_update_date
                                                     , last_updated_by
                                                     , creation_date
                                                     , created_by
                                                     , last_update_login
                                                     , transaction_type
                                                     , transaction_date
                                                     , processing_status_code
                                                     , processing_mode_code
                                                     , transaction_status_code
                                                     , quantity
                                                     , unit_of_measure
                                                     , interface_source_code
                                                     , item_num
                                                     , auto_transact_code
                                                     , shipment_header_id
                                                     , shipment_line_id
                                                     , receipt_source_code
                                                     , to_organization_id
                                                     , source_document_code
                                                     , destination_type_code
                                                     , subinventory
                                                     , expected_receipt_date
                                                     , header_interface_id
                                                     , validation_flag
                                                     , attribute1
                                                     , attribute2
                                                     , attribute3
                                                     , attribute4
                                                     , attribute5
                                                     , attribute6
                                                     , attribute7
                                                     , attribute8
                                                     , attribute9
                                                     , attribute10
                                                     , attribute11
                                                     , attribute12
                                                     , attribute13
                                                     , attribute14
                                                     , attribute15
                                                     )
                                                      SELECT 
                                                      interface_transaction_id
                                                     , group_id
                                                     , last_update_date
                                                     , last_updated_by
                                                     , creation_date
                                                     , created_by
                                                     , last_update_login
                                                     , transaction_type
                                                     , transaction_date
                                                     , processing_status_code
                                                     , processing_mode_code
                                                     , transaction_status_code
                                                     , quantity
                                                     , unit_of_measure
                                                     , interface_source_code
                                                     , item_num
                                                     , auto_transact_code
                                                     , shipment_header_id
                                                     , shipment_line_id
                                                     , receipt_source_code
                                                     , to_organization_id
                                                     , source_document_code
                                                     , destination_type_code
                                                     , subinventory
                                                     , expected_receipt_date
                                                     , header_interface_id
                                                     , validation_flag
                                                     , attribute1
                                                     , attribute2
                                                     , attribute3
                                                     , attribute4
                                                     , attribute5
                                                     , attribute6
                                                     , attribute7
                                                     , attribute8
                                                     , attribute9
                                                     , attribute10
                                                     , attribute11
                                                     , attribute12
                                                     , attribute13
                                                     , attribute14
                                                     , attribute15
                                                     FROM   xx_gi_rcv_str_dtl
                                                     WHERE  interface_transaction_id = ln_tran_nex_id;
        END IF; -- endif for Interorg record insertion into Interface tables
              COMMIT;
         END IF;-- for VENDOR or INVENTORY record check
END LOOP;
END XX_GI_INS_ONLINE_RCV_PROC;
  
   
-- +===================================================================+
                                                            
-- +===================================================================+
-- | Name        : xx_gi_cln_stg_po_rcv                                |
-- | Description : This procedure will check the RTI table for         |
-- |               successful records and delete the corresponding     |
-- |               detail record of XX_GI_RCV_PO_DTL table.            |
-- |             i.e., for cleaning of staging tables                  |
-- | Parameters : p_purge_days,x_error_buff, x_ret_code                |
-- +===================================================================+
                                                             
-- +===================================================================+
-- Procedure 2 Start for purging staging tables                        |
-- +===================================================================+
PROCEDURE XX_GI_CLN_STG_RCV_PO(
                               x_error_buff        OUT VARCHAR2
                              ,x_ret_code          OUT NUMBER
                              ,p_purge_days        IN  NUMBER
                               )
IS
                            
BEGIN                      
-- +===================================================================+
-- Delete records according to purge date for PO Records               |
-- +===================================================================+
   DELETE 
   FROM xx_gi_rcv_po_hdr 
   WHERE  NOT EXISTS 
                    (
                    SELECT 1 
                    FROM xx_gi_rcv_po_dtl
                    ) 
    AND SYSDATE - TO_DATE(attribute7) > p_purge_days;
-- +===================================================================+
-- Delete records according to purge date for STR Records              |
-- +===================================================================+
                                                
    DELETE FROM xx_gi_rcv_str_hdr 
    WHERE  NOT EXISTS 
                    (
                     SELECT 1
                     FROM xx_gi_rcv_str_dtl
                     )
    AND SYSDATE - TO_DATE(attribute7) > p_purge_days;
                                            
END XX_GI_CLN_STG_RCV_PO; 
  
-- +===================================================================+
-- | Name        : xx_gi_pop_rti_po_rcv                                |
-- | Description : This procedure will populate processed records from |
-- |             staging into standard receiving interface tables      |
-- | Parameters : x_error_buff, x_ret_code                             |
-- +===================================================================+
                                                             
-- +===================================================================+
-- Procedure 3 Starts                                                  |
-- +===================================================================+
PROCEDURE XX_GI_POP_RTI_RCV_PO(
                               x_err_buf   OUT VARCHAR2
                               ,x_ret_code OUT NUMBER
                              )
IS
                               
lc_error_flag                            VARCHAR2(1);
lc_status_flag                           VARCHAR2(4);
                                 
-- +===================================================================+
-- Cursor for Updating of staging table details                        |
-- +===================================================================+
   CURSOR lcu_cor_po_curr
   IS
   SELECT   XGRPD.interface_transaction_id
           , XGRPD.item_id
           , XGRPD.attribute7
           , XGRPD.header_interface_id
   FROM    xx_gi_rcv_po_dtl XGRPD
   WHERE  1=1 
   AND NOT EXISTS (
                   SELECT 1 
                   FROM rcv_transactions_interface RTI 
                   WHERE RTI.interface_transaction_id = XGRPD.interface_transaction_id
                   )
   AND  XGRPD.E0342_status_flag = 'PL';
                                                           
   TYPE lt_cor_po_ty IS TABLE OF lcu_cor_po_curr%ROWTYPE
   INDEX BY BINARY_INTEGER;
                          
   lt_cor_po_typ  lt_cor_po_ty;
                                     
-- +===================================================================+
-- Cursor for entrying to error table                                  |
-- +===================================================================+
   CURSOR lcu_err_po_curr
   IS
   SELECT XGRPD.interface_transaction_id
   FROM   xx_gi_rcv_po_dtl XGRPD
   WHERE  XGRPD.E0342_status_flag = 'VE'
   AND EXISTS (
               SELECT 1
               FROM rcv_transactions_interface RTI
               WHERE UPPER(RTI.processing_status_code) = 'ERROR'
               AND   UPPER(RTI.transaction_status_code) = 'PENDING' 
               AND   RTI.interface_transaction_id = XGRPD.interface_transaction_id
               )
   AND XGRPD.E0346_status_flag = 'Y'
   AND NOT EXISTS 
                (
                 SELECT 1 
                 FROM xx_gi_error_tbl XGERT
                 WHERE  XGERT.msg_code = 'XX_GI_UPD_VE_99999'  
                 AND    XGERT.entity_ref_id = XGRPD.interface_transaction_id
                 );
                                                           
   TYPE lt_err_po_ty IS TABLE OF lcu_err_po_curr%ROWTYPE
   INDEX BY BINARY_INTEGER;
                          
   lt_err_po_typ  lt_err_po_ty;
                                                
-- +===================================================================+
-- Cursor for Inserting Records in RHI and RTI                         |
-- +===================================================================+
   CURSOR lcu_po_int_curr
   IS
   SELECT   XGRPH.header_interface_id
          , XGRPH.group_id
          , XGRPH.last_update_date
          , XGRPH.last_updated_by
          , XGRPH.last_update_login
          , XGRPH.creation_date
          , XGRPH.created_by
          , XGRPH.shipment_num
          , XGRPH.vendor_name
          , XGRPH.vendor_site_code
          , XGRPH.from_organization_code
          , XGRPH.expected_receipt_date
          , XGRPH.shipped_date
          , XGRPH.ship_to_organization_code
          , XGRPH.transaction_date
          , XGRPH.currency_code
          , XGRPH.attribute1
          , XGRPH.attribute2
          , XGRPH.attribute3
          , XGRPH.attribute4
          , XGRPH.attribute5
          , XGRPH.attribute6
          , XGRPH.attribute7
          , XGRPH.attribute8
          , XGRPH.attribute9
          , XGRPH.attribute10
          , XGRPH.attribute11
          , XGRPH.attribute12
          , XGRPH.attribute13
          , XGRPH.attribute14
          , XGRPH.attribute15
          , XGRPH.asn_type
          , XGRPH.notice_creation_date
          , XGRPH.receipt_num
          , XGRPH.receipt_header_id
          , XGRPH.vendor_id
          , XGRPH.vendor_num
          , XGRPH.vendor_site_id
          , XGRPH.ship_to_organization_id
          , XGRPH.location_code
          , XGRPH.bill_of_lading
          , XGRPH.packing_slip
          , XGRPH.freight_carrier_code
          , XGRPH.num_of_containers
          , XGRPH.waybill_airbill_num
          , XGRPH.comments
          , XGRPH.gross_weight
          , XGRPH.gross_weight_uom_code
          , XGRPH.net_weight
          , XGRPH.net_weight_uom_code
          , XGRPH.tar_weight
          , XGRPH.tar_weight_uom_code
          , XGRPH.packaging_code
          , XGRPH.carrier_method
          , XGRPH.carrier_equipment
          , XGRPH.special_handling_code
          , XGRPH.hazard_code
          , XGRPH.hazard_class
          , XGRPH.hazard_description
          , XGRPH.freight_terms
          , XGRPH.freight_bill_number
          , XGRPH.invoice_num
          , XGRPH.invoice_date
          , XGRPH.total_invoice_amount
          , XGRPH.tax_name
          , XGRPH.tax_amount
          , XGRPH.freight_amount
          , XGRPH.conversion_rate_type
          , XGRPH.conversion_rate
          , XGRPH.conversion_rate_date
          , XGRPH.payment_terms_name
          , XGRPH.attribute_category
          , XGRPH.employee_name
          , XGRPH.invoice_status_code
          , XGRPH.customer_account_number
          , XGRPH.customer_party_name
          , XGRPH.E0342_status_flag
          , XGRPH.E0342_first_rec_time
          , XGRPH.receipt_source_code
          , XGRPD.transaction_type           typ
          , XGRPD.transaction_date           td
          , XGRPD.processing_status_code     psc
          , XGRPD.processing_mode_code       pmc
          , XGRPD.transaction_status_code    tsc
          , XGRPD.quantity
          , XGRPD.unit_of_measure
          , XGRPD.interface_source_code
          , XGRPD.inv_transaction_id
          , XGRPD.item_id
          , XGRPD.item_description
          , XGRPD.item_revision
          , XGRPD.uom_code                  
          , XGRPD.auto_transact_code        atc
          , XGRPD.primary_quantity          
          , XGRPD.primary_unit_of_measure    
          , XGRPD.receipt_source_code       rsc
          , XGRPD.from_subinventory         
          , XGRPD.source_document_code     
          , XGRPD.po_revision_num
          , XGRPD.po_unit_price
          , XGRPD.currency_code             cc
          , XGRPD.currency_conversion_type  cct
          , XGRPD.currency_conversion_rate  ccr
          , XGRPD.currency_conversion_date  ccd
          , XGRPD.substitute_unordered_code
          , XGRPD.receipt_exception_flag    
          , XGRPD.destination_type_code     
          , XGRPD.subinventory              
          , XGRPD.department_code           
          , XGRPD.shipment_num              sn
          , XGRPD.freight_carrier_code      fcc
          , XGRPD.bill_of_lading            bl
          , XGRPD.packing_slip              ps
          , XGRPD.shipped_date              sd
          , XGRPD.actual_cost               
          , XGRPD.transfer_cost             
          , XGRPD.transportation_cost       
          , XGRPD.num_of_containers         ncc
          , XGRPD.vendor_item_num           
          , XGRPD.comments                  c
          , XGRPD.attribute_category        ac
          , XGRPD.attribute1                a1
          , XGRPD.attribute2                a2
          , XGRPD.attribute3                a3
          , XGRPD.attribute4                a4
          , XGRPD.attribute5                a5
          , XGRPD.attribute6                a6
          , XGRPD.attribute7                a7
          , XGRPD.attribute8                a8
          , XGRPD.attribute9                a9
          , XGRPD.attribute10               a10
          , XGRPD.attribute11               a11
          , XGRPD.attribute12               a12
          , XGRPD.attribute13               a13
          , XGRPD.attribute14               a14
          , XGRPD.attribute15               a15
          , XGRPD.item_num
          , XGRPD.document_num
          , XGRPD.document_line_num
          , XGRPD.ship_to_location_code
          , XGRPD.item_category
          , XGRPD.location_code             lc
          , XGRPD.vendor_id                 vd
          , XGRPD.vendor_site_id            vsd
          , XGRPD.vendor_name               vn
          , XGRPD.vendor_num                vnu
          , XGRPD.vendor_site_code          vsc
          , XGRPD.from_organization_code    foc 
          , XGRPD.to_organization_code
          , XGRPD.to_organization_id
          , XGRPD.validation_flag           vf
          , XGRPD.E0342_status_flag         sf
          , XGRPD.E0342_first_rec_time      frt
          , XGRPD.po_header_id
          , XGRPD.po_line_id
          , XGRPD.po_line_location_id
          , XGRPD.po_distribution_id
          , XGRPD.shipment_header_id
          , XGRPD.shipment_line_id
          , XGRPD.currency_conversion_type
          , XGRPD.currency_conversion_rate
          , XGRPD.currency_conversion_date
          , XGRPD.deliver_to_location_id
          , XGRPD.interface_transaction_id
          , XGRPD.ship_head_attribute_category
          , XGRPD.category_id
          , XGRPD.charge_account_id
          , XGRPD.document_shipment_line_num
          , XGRPD.document_distribution_num
          , XGRPD.project_id
          , XGRPD.task_id
   FROM    xx_gi_rcv_po_hdr  XGRPH
          ,xx_gi_rcv_po_dtl  XGRPD
   WHERE   XGRPH.header_interface_id   =   XGRPD.header_interface_id  
   AND     XGRPD.E0342_status_flag     = 'P';
                                                        
   TYPE lt_po_int_ty IS TABLE OF lcu_po_int_curr%ROWTYPE
   INDEX BY BINARY_INTEGER;
                          
   lt_po_int_typ  lt_po_int_ty;
                                                
   ln_count                                 NUMBER := 0;
   lc_pri_key                               VARCHAR2(20) := 0;
   ln_head_nex_id                           NUMBER ;
   ln_grp_nex_id                            NUMBER ;
   lc_meaning                               fnd_lookup_values_vl.meaning%TYPE;
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
         OPEN lcu_cor_po_curr;
         FETCH lcu_cor_po_curr 
         BULK COLLECT INTO lt_cor_po_typ;
         FOR i 
         IN 1..lt_cor_po_typ.COUNT
         LOOP
                                                   
-- +===================================================================+
-- |Updating xx_gi_rcv_po_hdr table with time stamp which              |
-- |    will be used for mtl_system_items last receipt date            |

-- +===================================================================+
             UPDATE xx_gi_rcv_po_hdr 
             SET    E0342_first_rec_time = lt_cor_po_typ(i).attribute7 
             WHERE  header_Interface_id = lt_cor_po_typ(i).header_Interface_id;
         END LOOP;
         COMMIT;
                
-- +=====================================================================+
-- Delete records from xx_gi_error_tbl exists in xx_gi_rcv_po_dtl table  |
-- +=====================================================================+
            DELETE 
            FROM   xx_gi_error_tbl XGERT
            WHERE  1=1
            AND    EXISTS 
                         (
                          SELECT 1
                          FROM xx_gi_rcv_po_dtl XGRPD 
                          WHERE XGRPD.E0342_status_flag='PL'
                          AND   XGRPD.interface_transaction_id = XGERT.entity_ref_id
                          )
            AND    NOT EXISTS (
                               SELECT 1
                               FROM rcv_transactions_interface RTI 
                               WHERE RTI.interface_transaction_id = XGERT.entity_ref_id
                               );
                                                                         
-- +===================================================================================+
-- Delete records from xx_gi_rcv_po_dtl not exists in rcv_transactions_interface table |
-- +===================================================================================+
            DELETE 
            FROM   xx_gi_rcv_po_dtl XGRPD
            WHERE  1 = 1
            AND    NOT EXISTS (
                              SELECT 1
                              FROM rcv_transactions_interface RTI 
                              WHERE RTI.interface_transaction_id = XGRPD.interface_transaction_id
                              )
            AND XGRPD.E0342_status_flag='PL';
                                       
-- +===================================================================+
-- Updating status to 'P' FOR BATCH ERROR                              |
-- +===================================================================+
            UPDATE xx_gi_rcv_po_dtl XGRPD
            SET    XGRPD.E0342_status_flag = 'P' 
            WHERE  1 = 1
            AND EXISTS (
                        SELECT 1
                        FROM rcv_transactions_interface RTI
                        WHERE UPPER(RTI.processing_status_code) = 'COMPLETED'
                        AND RTI.interface_transaction_id = XGRPD.interface_transaction_id
                        AND   UPPER(RTI.transaction_status_code) = 'ERROR'
                        )
            AND XGRPD.E0342_status_flag = 'PL';
                                           
-- +===================================================================+
-- |     Updating status to 'E' FOR REAL ERROR                         |
-- |     which will be picked by  e346  program                        |
-- +===================================================================+
            UPDATE xx_gi_rcv_po_dtl XGRPD
            SET    XGRPD.E0342_status_flag = 'E' 
            WHERE  1 = 1
            AND EXISTS (
                        SELECT 1
                        FROM rcv_transactions_interface RTI
                        WHERE UPPER(RTI.processing_status_code) = 'ERROR'
                        AND RTI.interface_transaction_id = XGRPD.interface_transaction_id
                        AND UPPER(RTI.transaction_status_code) = 'PENDING' 
                        )
            AND XGRPD.E0342_status_flag = 'PL' 
            AND NVL(XGRPD.E0346_status_flag,'N') <> 'Y';
                                           
-- +===================================================================+
-- |     Updating status to 'VE' FOR REAL ERROR                        |
-- |     WHERE E346 VALIDATION  IS ALREADY   PASSED                    |
-- +===================================================================+
            UPDATE xx_gi_rcv_po_dtl XGRPD
            SET    XGRPD.E0342_status_flag = 'VE' 
            WHERE  1 = 1
            AND EXISTS (
                        SELECT 1
                        FROM rcv_transactions_interface RTI
                        WHERE UPPER(RTI.processing_status_code) = 'ERROR'
                        AND RTI.interface_transaction_id = XGRPD.interface_transaction_id
                        AND UPPER(RTI.transaction_status_code) = 'PENDING' 
                        )
            AND XGRPD.E0342_status_flag = 'PL' 
            AND NVL(XGRPD.E0346_status_flag,'N') = 'Y';
            COMMIT;
                                               
-- +===================================================================+
-- Cursor for entrying to error table                                  |
-- +===================================================================+
           OPEN lcu_err_po_curr;
           FETCH lcu_err_po_curr 
           BULK COLLECT INTO lt_err_po_typ;
           FOR i 
           IN 1..lt_err_po_typ.COUNT
           LOOP
                                           
-- +===================================================================+
-- Log errors in error table                                           |
-- +===================================================================+
              XX_GI_RCV_ERR_PKG.XX_GI_INS_CUST_EXCEP(
                                                    'XX_GI_UPD_VE_99999'
                                                   ,'interface_transaction_id'
                                                   ,lt_err_po_typ(i).interface_transaction_id
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
                       FROM xx_gi_rcv_po_dtl XGRPD
                       WHERE XGRPD.E0342_status_flag IN ('P','E','VE')
                       AND RTI.interface_transaction_id = XGRPD.interface_transaction_id
                       );
                        
-- +===================================================================+
-- | Delete all ASN errors for the PO and line number                  |
-- +===================================================================+
           DELETE FROM xx_gi_rcv_po_dtl XGRPD
           WHERE  XGRPD.attribute5||XGRPD.attribute3 IN (
                                                         SELECT XGRPD1.attribute5||XGRPD1.attribute3 
                                                         FROM xx_gi_rcv_po_dtl XGRPD1 
                                                         WHERE XGRPD1.E0342_status_flag = 'P'
                                                     AND EXISTS 
                                                         (
                                                          SELECT 1 FROM xx_gi_rcv_po_hdr XGRPH1
                                                          WHERE XGRPH1.header_interface_id =
                                                                XGRPD1.header_interface_id
                                                          AND   XGRPH1.asn_type = 'RECEIVE' 
                                                         )
                                                         )
                                                      AND EXISTS 
                                                         (
                                                          SELECT 1 FROM xx_gi_rcv_po_hdr XGRPH
                                                          WHERE XGRPH.header_interface_id =
                                                                XGRPD.header_interface_id
                                                          AND   XGRPH.asn_type = 'ASN' 
                                                         );
                                          
-- +===================================================================+
-- Cursor for Clearing of staging table details                        |
-- +===================================================================+
           OPEN lcu_po_int_curr;
           FETCH lcu_po_int_curr 
           BULK COLLECT INTO lt_po_int_typ;
           FOR i 
           IN 1..lt_po_int_typ.COUNT
           LOOP
                                         
-- +===================================================================+
-- Validation for Transactions Type                                    |
-- +===================================================================+
              IF lt_po_int_typ(i).asn_type = 'ASN' THEN
                 lc_transaction_type_hdr := 'SHIP';
                 lc_auto_transact_code   := 'SHIP';
                 lt_po_int_typ(i).receipt_num := NULL;
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
                     WHERE header_interface_id = lt_po_int_typ(i).header_interface_id;
                               
                       UPDATE rcv_headers_interface SET 
                              processing_status_code = 'PENDING'
                             ,processing_request_id = NULL
                       WHERE header_interface_id = lt_po_int_typ(i).header_interface_id;
                                                   
                   EXCEPTION
                      WHEN NO_DATA_FOUND THEN
-- +===================================================================+
-- Insert Records into RHI                                             |
-- +===================================================================+
                          INSERT 
                          INTO rcv_headers_interface( 
                                                     header_interface_id
                                                    ,group_id
                                                    ,processing_status_code
                                                    ,receipt_source_code
                                                    ,transaction_type
                                                    ,auto_transact_code
                                                    ,last_update_date 
                                                    ,last_updated_by 
                                                    ,last_update_login
                                                    ,creation_date
                                                    ,created_by 
                                                    ,shipment_num
                                                    ,receipt_num
                                                    ,vendor_id
                                                    ,vendor_site_id
                                                    ,bill_of_lading
                                                    ,shipped_date
                                                    ,freight_carrier_code
                                                    ,expected_receipt_date
                                                    ,freight_terms
                                                    ,currency_code
                                                    ,validation_flag
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
                                                    )
                                                     SELECT
                                                      lt_po_int_typ(i).header_interface_id --header_interface_id
                                                     ,lt_po_int_typ(i).group_id            -- group_id
                                                     ,'PENDING'                            --processing_status_code
                                                     ,lt_po_int_typ(i).receipt_source_code -- receipt_source_code
                                                     ,lc_transaction_type_hdr              --transaction_type 
                                                     ,lc_auto_transact_code
                                                     ,lt_po_int_typ(i).last_update_date 
                                                     ,lt_po_int_typ(i).last_updated_by 
                                                     ,lt_po_int_typ(i).last_update_login
                                                     ,lt_po_int_typ(i).creation_date
                                                     ,lt_po_int_typ(i).created_by 
                                                     ,lt_po_int_typ(i).shipment_num
                                                     ,lt_po_int_typ(i).receipt_num
                                                     ,lt_po_int_typ(i).vendor_id
                                                     ,lt_po_int_typ(i).vendor_site_id
                                                     ,lt_po_int_typ(i).bill_of_lading
                                                     ,lt_po_int_typ(i).shipped_date
                                                     ,lt_po_int_typ(i).freight_carrier_code
                                                     ,lt_po_int_typ(i).expected_receipt_date
                                                     ,lt_po_int_typ(i).freight_terms
                                                     ,lt_po_int_typ(i).currency_code
                                                     ,'Y'    --validation_flag  
                                                     ,lt_po_int_typ(i).attribute1
                                                     ,lt_po_int_typ(i).attribute2
                                                     ,lt_po_int_typ(i).attribute3
                                                     ,lt_po_int_typ(i).attribute4
                                                     ,lt_po_int_typ(i).attribute5
                                                     ,lt_po_int_typ(i).attribute6
                                                     ,lt_po_int_typ(i).attribute7
                                                     ,lt_po_int_typ(i).attribute8
                                                     ,lt_po_int_typ(i).attribute9
                                                     ,lt_po_int_typ(i).attribute10
                                                     ,lt_po_int_typ(i).attribute11
                                                     ,lt_po_int_typ(i).attribute12
                                                     ,lt_po_int_typ(i).attribute13
                                                     ,lt_po_int_typ(i).attribute14
                                                     ,lt_po_int_typ(i).attribute15
                                                    FROM sys.DUAL;
                                                      
                   END;
-- +===================================================================+
-- Validation for Transactions Type                                    |
-- +===================================================================+
                   IF lt_po_int_typ(i).asn_type = 'ASN' THEN
                      lc_transaction_type := 'SHIP';
                   ELSE
                     IF lt_po_int_typ(i).typ = 'CORRECT' THEN
                        lc_transaction_type := 'CORRECT';
                     ELSE		 
                        lc_transaction_type := 'RECEIVE';
                     END IF;
                   END IF;
-- +===================================================================+
-- |  Insert Records into RTI                                          |
-- +===================================================================+
                          INSERT
                          INTO rcv_transactions_interface( 
                                                          interface_transaction_id
                                                         ,header_interface_id
                                                         ,group_id
                                                         ,last_update_date 
                                                         ,last_updated_by 
                                                         ,last_update_login 
                                                         ,creation_date 
                                                         ,created_by 
                                                         ,transaction_type
                                                         ,transaction_date
                                                         ,processing_status_code
                                                         ,processing_mode_code
                                                         ,transaction_status_code
                                                         ,to_organization_id
                                                         ,item_num
                                                         ,category_id
                                                         ,location_code
                                                         ,quantity
                                                         ,uom_code
                                                         ,unit_of_measure
                                                         ,interface_source_code
                                                         ,auto_transact_code
                                                         ,receipt_source_code
                                                         ,source_document_code
                                                         ,po_unit_price
                                                         ,charge_account_id
                                                         ,subinventory
                                                         ,document_num
                                                         ,document_line_num
                                                         ,document_shipment_line_num
                                                         ,document_distribution_num
                                                         ,deliver_to_location_id
                                                         ,validation_flag
                                                         ,project_id
                                                         ,task_id
                                                         ,destination_type_code
                                                         ,currency_code
                                                         ,currency_conversion_type
                                                         ,currency_conversion_rate
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
                                                         )
                                                         SELECT
                                                         lt_po_int_typ(i).interface_transaction_id 
                                                        ,lt_po_int_typ(i).header_interface_id 
                                                        ,lt_po_int_typ(i).group_id 
                                                        ,lt_po_int_typ(i).last_update_date 
                                                        ,lt_po_int_typ(i).last_updated_by 
                                                        ,lt_po_int_typ(i).last_update_login 
                                                        ,lt_po_int_typ(i).creation_date 
                                                        ,lt_po_int_typ(i).created_by 
                                                        ,lc_transaction_type                --transaction_type
                                                        ,lt_po_int_typ(i).transaction_date 
                                                        ,'PENDING'            --processing_status_code ,
                                                        ,'BATCH'             --processing_mode_code ,
                                                        ,'PENDING'             --transaction_status_code , 
                                                        ,lt_po_int_typ(i).to_organization_id
                                                        ,lt_po_int_typ(i).item_num
                                                        ,lt_po_int_typ(i).category_id
                                                        ,lt_po_int_typ(i).location_code
                                                        ,lt_po_int_typ(i).quantity 
                                                        ,lt_po_int_typ(i).uom_code
                                                        ,lt_po_int_typ(i).unit_of_measure 
                                                        ,lt_po_int_typ(i).interface_source_code
                                                        ,lc_auto_transact_code       --auto_transact_code,
                                                        ,lt_po_int_typ(i).receipt_source_code 
                                                        ,'PO'               --source_document_code 
                                                        ,lt_po_int_typ(i).po_unit_price
                                                        ,lt_po_int_typ(i).charge_account_id
                                                        ,'STOCK'                   --subinventory,
                                                        ,lt_po_int_typ(i).document_num
                                                        ,lt_po_int_typ(i).document_line_num
                                                        ,lt_po_int_typ(i).document_shipment_line_num
                                                        ,lt_po_int_typ(i).document_distribution_num
                                                        ,lt_po_int_typ(i).deliver_to_location_id
                                                        ,'Y'       --validation_flag,
                                                        ,lt_po_int_typ(i).project_id
                                                        ,lt_po_int_typ(i).task_id
                                                        ,lt_po_int_typ(i).destination_type_code
                                                        ,lt_po_int_typ(i).currency_code
                                                        ,lt_po_int_typ(i).currency_conversion_type
                                                        ,lt_po_int_typ(i).currency_conversion_rate
                                                        ,lt_po_int_typ(i).a1
                                                        ,lt_po_int_typ(i).a2
                                                        ,lt_po_int_typ(i).a3
                                                        ,lt_po_int_typ(i).a4
                                                        ,lt_po_int_typ(i).a5
                                                        ,lt_po_int_typ(i).a6
                                                        ,lt_po_int_typ(i).a7
                                                        ,lt_po_int_typ(i).a8
                                                        ,lt_po_int_typ(i).a9
                                                        ,lt_po_int_typ(i).a10
                                                        ,lt_po_int_typ(i).a11
                                                        ,lt_po_int_typ(i).a12
                                                        ,lt_po_int_typ(i).a13
                                                        ,lt_po_int_typ(i).a14
                                                        ,lt_po_int_typ(i).a15
                                                        FROM sys.DUAL;
                                           
-- +===================================================================+
-- Updating 'PL' Records                                               |
-- +===================================================================+
                          UPDATE xx_gi_rcv_po_dtl  XGRPD
                          SET   XGRPD.E0342_status_flag  = 'PL' 
                          WHERE XGRPD.interface_transaction_id = lt_po_int_typ(i).interface_transaction_id;
            END LOOP;
                                                 
            COMMIT;
                                                                                    
  END    XX_GI_POP_RTI_RCV_PO; 
-- +===================================================================+
-- Procedure 3 End                                                     |
-- +===================================================================+
END XX_GI_PO_STE_RCV_PKG;
/
show err