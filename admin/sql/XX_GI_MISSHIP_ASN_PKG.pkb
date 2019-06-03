SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
 
CREATE OR REPLACE PACKAGE BODY XX_GI_MISSHIP_ASN_PKG
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                  WIPRO Organization                                            |
-- +================================================================================+
-- | Name        :  XXGIMISSHIPPKGB.pkb                                             |
-- | Rice Id     :  E0346a_Add-on and Mis-ShipValidation for ASN Data               |
-- | Description :  This script creates custom package body required for            |
-- |                Add-on and Mis-ShipValidation for ASN Data                      |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author           Remarks                                  |
-- |=======   ==========  =============    ============================             |
-- |1.0      21-MAY-2007  Rahul Bagul      Initial draft version                    |
-- |                                                                                |
-- +================================================================================+
AS
-- +================================================================================+
-- | Name        :  MAIN_ADD_SKU_PROC                                               |
-- | Description :  This  custom procedure is main procedure and it will call       |
-- |                all other procedures for validations. It also check whether     |
-- |                item exists in item master or not                               |
-- | Parameters   : x_err_buf,x_ret_code                                            |
-- +================================================================================+
   gc_item_type          VARCHAR2(2):='T';
   gc_errbuff            VARCHAR2(100);
   gc_retcode            VARCHAR2(1000);
PROCEDURE MAIN_ADD_SKU_PROC(
                             x_errbuff        OUT  VARCHAR2
                            ,x_retcode        OUT  VARCHAR2
                            ,p_email_address  IN   VARCHAR2
                            ,p_batch_id       IN   NUMBER
                            )
AS
CURSOR lcu_rcv_lines_curr
IS
SELECT  RHI.expected_receipt_date
        ,RTI.quantity
        ,RTI.interface_transaction_id
        ,RTI.item_num
        ,RTI.to_organization_id
        ,RTI.document_num
        ,RTI.vendor_id
        ,RTI.vendor_site_id
        ,RTI.po_header_id
        ,RTI.po_line_id
        ,RTI.header_interface_id
        ,RTI.amount
        ,RTI.document_line_num
FROM    rcv_headers_interface       RHI
       ,rcv_transactions_interface  RTI
WHERE   RHI.asn_type ='ASN'
AND     (RTI.processing_status_code ='ERROR'
         OR RTI.transaction_status_code = 'ERROR')
AND     RHI.header_interface_id = RTI.header_interface_id
ORDER BY RTI.document_num DESC;
          
--Declare local variables;
ln_master_org_id              NUMBER;
ln_inventory_item_id          NUMBER;
ln_interface_transaction_id   NUMBER;
ln_email_cnt                  NUMBER:=0;
lc_sqlcode                    VARCHAR2(100);
lc_sqlerrm                    VARCHAR2(2000);
          
BEGIN
      FND_CLIENT_INFO.SET_ORG_CONTEXT(FND_PROFILE.VALUE('org_id'));
      -- opening  header cursor check naming convention
      gn_sqlpoint:='10';
      gc_email_address :=p_email_address;
      gc_batch_id      :=p_batch_id;
             
      FOR lcu_rcv_lines_curr_rec 
      IN lcu_rcv_lines_curr 
      LOOP
      EXIT WHEN lcu_rcv_lines_curr%NOTFOUND;
      gc_status_flag               := 'SUCCESS';
      gd_receipt_date              := lcu_rcv_lines_curr_rec.expected_receipt_date;
      gn_quantity                  := lcu_rcv_lines_curr_rec.quantity;
      gn_interface_transaction_id  :=lcu_rcv_lines_curr_rec.interface_transaction_id;
      gc_item_num                  :=lcu_rcv_lines_curr_rec.item_num;
      gn_org_id                    :=lcu_rcv_lines_curr_rec.to_organization_id;
      gc_document_num              :=lcu_rcv_lines_curr_rec.document_num;
      gn_vendor_id                 :=lcu_rcv_lines_curr_rec.vendor_id;
      gn_vendor_site_id            :=lcu_rcv_lines_curr_rec.vendor_site_id;
      gn_po_header_id              :=lcu_rcv_lines_curr_rec.po_header_id;
      gn_po_line_id                :=lcu_rcv_lines_curr_rec.po_line_id;
      gn_header_interface_id       :=lcu_rcv_lines_curr_rec.header_interface_id; 
      gn_po_line_num               :=lcu_rcv_lines_curr_rec.document_line_num;
          
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
           x_retcode := SQLCODE;
           x_errbuff := SUBSTR(SQLERRM,1,250);
           FND_MESSAGE.SET_NAME ('xxptp','XX_GI_MISSHIP_ASN_P001');
           gc_error_message      := FND_MESSAGE.GET;
           gc_error_message_code :='XX_GI_MISSHIP_ASN_P001';
           gc_object_id          := gn_interface_transaction_id;
           gc_object_type        :='Interface_transaction_id';
           XX_COM_ERROR_LOG_PUB.LOG_ERROR( NULL
                                          ,NULL
                                          ,'EBS'
                                          ,'Procedure'
                                          ,'MAIN_ADD_SKU_PROC'
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
         END;
      END IF;
      ln_inventory_item_id :=NULL;
                             
      IF gc_status_flag ='SUCCESS' THEN
         BEGIN
             gn_sqlpoint:='20';
             --fnd_global.apps_initialize(2515, 50300,201);
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
                 x_errbuff := SUBSTR(SQLERRM,1,250);
                 FND_MESSAGE.SET_NAME('xxptp','XX_GI_MISSHIP_ASN_99999');
                 gc_error_message      := FND_MESSAGE.GET;
                 gc_error_message_code :='XX_GI_MISSHIP_ASN_99999';
                 gc_object_id          := gn_interface_transaction_id;
                 gc_object_type        :='Interface_transaction_id';
                 XX_COM_ERROR_LOG_PUB.LOG_ERROR(NULL
                                                ,NULL
                                                ,'EBS'
                                                ,'Procedure'
                                                ,'MAIN_ADD_SKU_PROC'
                                                , NULL
                                                , 'GI'
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
         gn_sqlpoint:='30';
         IF ln_inventory_item_id IS NULL THEN
           gn_sqlpoint:='40';
           VAL_UPC_CODE_PROC(gc_item_num
                             ,gn_org_id
                             ,gn_interface_transaction_id
                             ,ln_master_org_id
                             );
                          
           gn_sqlpoint:='50';
         ELSE
           VAL_ITEM_RECEV_ORG_PROC(gc_item_num
                                   ,gn_org_id
                                   );
           gn_sqlpoint:='60';
         END IF;
      END IF;
     IF gc_status_flag = 'ERROR' THEN
      -- Insert error out record from RHI to apps.XX_GI_RCV_PO_HDR to reduce load on RHI table
      INSERT 
      INTO xx_gi_rcv_po_hdr(HEADER_INTERFACE_ID
                           ,GROUP_ID
                           ,EDI_CONTROL_NUM
                           ,PROCESSING_STATUS_CODE
                           ,RECEIPT_SOURCE_CODE
                           ,ASN_TYPE
                           ,TRANSACTION_TYPE
                           ,AUTO_TRANSACT_CODE
                           ,TEST_FLAG
                           ,LAST_UPDATE_DATE
                           ,LAST_UPDATED_BY
                           ,LAST_UPDATE_LOGIN
                           ,CREATION_DATE
                           ,CREATED_BY
                           ,NOTICE_CREATION_DATE
                           ,SHIPMENT_NUM
                           ,RECEIPT_NUM
                           ,RECEIPT_HEADER_ID
                           ,VENDOR_NAME
                           ,VENDOR_NUM
                           ,VENDOR_ID
                           ,VENDOR_SITE_CODE
                           ,VENDOR_SITE_ID
                           ,FROM_ORGANIZATION_CODE
                           ,FROM_ORGANIZATION_ID
                           ,SHIP_TO_ORGANIZATION_CODE
                           ,SHIP_TO_ORGANIZATION_ID
                           ,LOCATION_CODE
                           ,LOCATION_ID
                           ,BILL_OF_LADING
                           ,PACKING_SLIP
                           ,SHIPPED_DATE
                           ,FREIGHT_CARRIER_CODE
                           ,EXPECTED_RECEIPT_DATE
                           ,RECEIVER_ID
                           ,NUM_OF_CONTAINERS
                           ,WAYBILL_AIRBILL_NUM
                           ,COMMENTS
                           ,GROSS_WEIGHT
                           ,GROSS_WEIGHT_UOM_CODE
                           ,NET_WEIGHT
                           ,NET_WEIGHT_UOM_CODE
                           ,TAR_WEIGHT
                           ,TAR_WEIGHT_UOM_CODE
                           ,PACKAGING_CODE
                           ,CARRIER_METHOD
                           ,CARRIER_EQUIPMENT
                           ,SPECIAL_HANDLING_CODE
                           ,HAZARD_CODE
                           ,HAZARD_CLASS
                           ,HAZARD_DESCRIPTION
                           ,FREIGHT_TERMS
                           ,FREIGHT_BILL_NUMBER
                           ,INVOICE_NUM
                           ,INVOICE_DATE
                           ,TOTAL_INVOICE_AMOUNT
                           ,TAX_NAME
                           ,TAX_AMOUNT
                           ,FREIGHT_AMOUNT
                           ,CURRENCY_CODE
                           ,CONVERSION_RATE_TYPE
                           ,CONVERSION_RATE
                           ,CONVERSION_RATE_DATE
                           ,PAYMENT_TERMS_NAME
                           ,PAYMENT_TERMS_ID
                           ,ATTRIBUTE_CATEGORY
                           ,ATTRIBUTE1
                           ,ATTRIBUTE2
                           ,ATTRIBUTE3
                           ,ATTRIBUTE4
                           ,ATTRIBUTE5
                           ,ATTRIBUTE6
                           ,ATTRIBUTE7
                           ,ATTRIBUTE9
                           ,ATTRIBUTE10
                           ,ATTRIBUTE11
                           ,ATTRIBUTE12
                           ,ATTRIBUTE13
                           ,ATTRIBUTE14
                           ,ATTRIBUTE15
                           ,USGGL_TRANSACTION_CODE
                           ,EMPLOYEE_NAME
                           ,EMPLOYEE_ID
                           ,INVOICE_STATUS_CODE
                           ,VALIDATION_FLAG
                           ,PROCESSING_REQUEST_ID
                           ,CUSTOMER_ACCOUNT_NUMBER
                           ,CUSTOMER_ID
                           ,CUSTOMER_SITE_ID
                           ,CUSTOMER_PARTY_NAME
                           ,REMIT_TO_SITE_ID
                           ,TRANSACTION_DATE
                           ,ORG_ID
                           ,OPERATING_UNIT
                           ,SHIP_FROM_LOCATION_ID
                           ,PERFORMANCE_PERIOD_FROM
                           ,PERFORMANCE_PERIOD_TO
                           ,REQUEST_DATE
                           ,SHIP_FROM_LOCATION_CODE
                           ,E0342_STATUS_FLAG
                           ,E0342_FIRST_REC_TIME
                           ,E0346_STATUS_FLAG
                           ,ATTRIBUTE8
                          )
                          SELECT
                           HEADER_INTERFACE_ID
                           ,GROUP_ID
                           ,EDI_CONTROL_NUM
                           ,PROCESSING_STATUS_CODE
                           ,RECEIPT_SOURCE_CODE
                           ,ASN_TYPE
                           ,TRANSACTION_TYPE
                           ,AUTO_TRANSACT_CODE
                           ,TEST_FLAG
                           ,LAST_UPDATE_DATE
                           ,LAST_UPDATED_BY
                           ,LAST_UPDATE_LOGIN
                           ,CREATION_DATE
                           ,CREATED_BY
                           ,NOTICE_CREATION_DATE
                           ,SHIPMENT_NUM
                           ,RECEIPT_NUM
                           ,RECEIPT_HEADER_ID
                           ,VENDOR_NAME
                           ,VENDOR_NUM
                           ,VENDOR_ID
                           ,VENDOR_SITE_CODE
                           ,VENDOR_SITE_ID
                           ,FROM_ORGANIZATION_CODE
                           ,FROM_ORGANIZATION_ID
                           ,SHIP_TO_ORGANIZATION_CODE
                           ,SHIP_TO_ORGANIZATION_ID
                           ,LOCATION_CODE
                           ,LOCATION_ID
                           ,BILL_OF_LADING
                           ,PACKING_SLIP
                           ,SHIPPED_DATE
                           ,FREIGHT_CARRIER_CODE
                           ,EXPECTED_RECEIPT_DATE
                           ,RECEIVER_ID
                           ,NUM_OF_CONTAINERS
                           ,WAYBILL_AIRBILL_NUM
                           ,COMMENTS
                           ,GROSS_WEIGHT
                           ,GROSS_WEIGHT_UOM_CODE
                           ,NET_WEIGHT
                           ,NET_WEIGHT_UOM_CODE
                           ,TAR_WEIGHT
                           ,TAR_WEIGHT_UOM_CODE
                           ,PACKAGING_CODE
                           ,CARRIER_METHOD
                           ,CARRIER_EQUIPMENT
                           ,SPECIAL_HANDLING_CODE
                           ,HAZARD_CODE
                           ,HAZARD_CLASS
                           ,HAZARD_DESCRIPTION
                           ,FREIGHT_TERMS
                           ,FREIGHT_BILL_NUMBER
                           ,INVOICE_NUM
                           ,INVOICE_DATE
                           ,TOTAL_INVOICE_AMOUNT
                           ,TAX_NAME
                           ,TAX_AMOUNT
                           ,FREIGHT_AMOUNT
                           ,CURRENCY_CODE
                           ,CONVERSION_RATE_TYPE
                           ,CONVERSION_RATE
                           ,CONVERSION_RATE_DATE
                           ,PAYMENT_TERMS_NAME
                           ,PAYMENT_TERMS_ID
                           ,ATTRIBUTE_CATEGORY
                           ,ATTRIBUTE1
                           ,ATTRIBUTE2
                           ,ATTRIBUTE3
                           ,ATTRIBUTE4
                           ,ATTRIBUTE5
                           ,ATTRIBUTE6
                           ,ATTRIBUTE7
                           ,ATTRIBUTE9
                           ,ATTRIBUTE10
                           ,ATTRIBUTE11
                           ,ATTRIBUTE12
                           ,ATTRIBUTE13
                           ,ATTRIBUTE14
                           ,ATTRIBUTE15
                           ,USGGL_TRANSACTION_CODE
                           ,EMPLOYEE_NAME
                           ,EMPLOYEE_ID
                           ,INVOICE_STATUS_CODE
                           ,VALIDATION_FLAG
                           ,PROCESSING_REQUEST_ID
                           ,CUSTOMER_ACCOUNT_NUMBER
                           ,CUSTOMER_ID
                           ,CUSTOMER_SITE_ID
                           ,CUSTOMER_PARTY_NAME
                           ,REMIT_TO_SITE_ID
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,NULL
                           ,gc_e0342_flag
                           ,SYSDATE
                           ,gc_e0346_flag
                           ,ATTRIBUTE8
     FROM  rcv_headers_interface
     WHERE header_interface_id =gn_header_interface_id;
      -- Insert error out record from RTI to apps.XX_GI_RCV_PO_DTL to redure load on RTI table
      INSERT
      INTO XX_GI_RCV_PO_DTL(INTERFACE_TRANSACTION_ID
                            ,GROUP_ID
                            ,LAST_UPDATE_DATE
                            ,LAST_UPDATED_BY
                            ,CREATION_DATE
                            ,CREATED_BY
                            ,LAST_UPDATE_LOGIN
                            ,REQUEST_ID
                            ,PROGRAM_APPLICATION_ID
                            ,PROGRAM_ID
                            ,PROGRAM_UPDATE_DATE
                            ,TRANSACTION_TYPE
                            ,TRANSACTION_DATE
                            ,PROCESSING_STATUS_CODE
                            ,PROCESSING_MODE_CODE
                            ,PROCESSING_REQUEST_ID
                            ,TRANSACTION_STATUS_CODE
                            ,CATEGORY_ID
                            ,QUANTITY
                            ,UNIT_OF_MEASURE
                            ,INTERFACE_SOURCE_CODE
                            ,INTERFACE_SOURCE_LINE_ID
                            ,INV_TRANSACTION_ID
                            ,ITEM_ID
                            ,ITEM_DESCRIPTION
                            ,ITEM_REVISION
                            ,UOM_CODE
                            ,EMPLOYEE_ID
                            ,AUTO_TRANSACT_CODE
                            ,SHIPMENT_HEADER_ID
                            ,SHIPMENT_LINE_ID
                            ,SHIP_TO_LOCATION_ID
                            ,PRIMARY_QUANTITY
                            ,PRIMARY_UNIT_OF_MEASURE
                            ,RECEIPT_SOURCE_CODE
                            ,VENDOR_ID
                            ,VENDOR_SITE_ID
                            ,FROM_ORGANIZATION_ID
                            ,FROM_SUBINVENTORY
                            ,TO_ORGANIZATION_ID
                            ,INTRANSIT_OWNING_ORG_ID
                            ,ROUTING_HEADER_ID
                            ,ROUTING_STEP_ID
                            ,SOURCE_DOCUMENT_CODE
                            ,PARENT_TRANSACTION_ID
                            ,PO_HEADER_ID
                            ,PO_REVISION_NUM
                            ,PO_RELEASE_ID
                            ,PO_LINE_ID
                            ,PO_LINE_LOCATION_ID
                            ,PO_UNIT_PRICE
                            ,CURRENCY_CODE
                            ,CURRENCY_CONVERSION_TYPE
                            ,CURRENCY_CONVERSION_RATE
                            ,CURRENCY_CONVERSION_DATE
                            ,PO_DISTRIBUTION_ID
                            ,REQUISITION_LINE_ID
                            ,REQ_DISTRIBUTION_ID
                            ,CHARGE_ACCOUNT_ID
                            ,SUBSTITUTE_UNORDERED_CODE
                            ,RECEIPT_EXCEPTION_FLAG
                            ,ACCRUAL_STATUS_CODE
                            ,INSPECTION_STATUS_CODE
                            ,INSPECTION_QUALITY_CODE
                            ,DESTINATION_TYPE_CODE
                            ,DELIVER_TO_PERSON_ID
                            ,LOCATION_ID
                            ,DELIVER_TO_LOCATION_ID
                            ,SUBINVENTORY
                            ,LOCATOR_ID
                            ,WIP_ENTITY_ID
                            ,WIP_LINE_ID
                            ,DEPARTMENT_CODE
                            ,WIP_REPETITIVE_SCHEDULE_ID
                            ,WIP_OPERATION_SEQ_NUM
                            ,WIP_RESOURCE_SEQ_NUM
                            ,BOM_RESOURCE_ID
                            ,SHIPMENT_NUM
                            ,FREIGHT_CARRIER_CODE
                            ,BILL_OF_LADING
                            ,PACKING_SLIP
                            ,SHIPPED_DATE
                            ,EXPECTED_RECEIPT_DATE
                            ,ACTUAL_COST
                            ,TRANSFER_COST
                            ,TRANSPORTATION_COST
                            ,TRANSPORTATION_ACCOUNT_ID
                            ,NUM_OF_CONTAINERS
                            ,WAYBILL_AIRBILL_NUM
                            ,VENDOR_ITEM_NUM
                            ,VENDOR_LOT_NUM
                            ,RMA_REFERENCE
                            ,COMMENTS
                            ,ATTRIBUTE_CATEGORY
                            ,ATTRIBUTE1
                            ,ATTRIBUTE2
                            ,ATTRIBUTE3
                            ,ATTRIBUTE4
                            ,ATTRIBUTE5
                            ,ATTRIBUTE6
                            ,ATTRIBUTE7
                            ,ATTRIBUTE9
                            ,ATTRIBUTE10
                            ,ATTRIBUTE11
                            ,ATTRIBUTE12
                            ,ATTRIBUTE13
                            ,ATTRIBUTE14
                            ,ATTRIBUTE15
                            ,SHIP_HEAD_ATTRIBUTE_CATEGORY
                            ,SHIP_HEAD_ATTRIBUTE1
                            ,SHIP_HEAD_ATTRIBUTE2
                            ,SHIP_HEAD_ATTRIBUTE3
                            ,SHIP_HEAD_ATTRIBUTE4
                            ,SHIP_HEAD_ATTRIBUTE5
                            ,SHIP_HEAD_ATTRIBUTE6
                            ,SHIP_HEAD_ATTRIBUTE7
                            ,SHIP_HEAD_ATTRIBUTE8
                            ,SHIP_HEAD_ATTRIBUTE9
                            ,SHIP_HEAD_ATTRIBUTE10
                            ,SHIP_HEAD_ATTRIBUTE11
                            ,SHIP_HEAD_ATTRIBUTE12
                            ,SHIP_HEAD_ATTRIBUTE13
                            ,SHIP_HEAD_ATTRIBUTE14
                            ,SHIP_HEAD_ATTRIBUTE15
                            ,SHIP_LINE_ATTRIBUTE_CATEGORY
                            ,SHIP_LINE_ATTRIBUTE1
                            ,SHIP_LINE_ATTRIBUTE2
                            ,SHIP_LINE_ATTRIBUTE3
                            ,SHIP_LINE_ATTRIBUTE4
                            ,SHIP_LINE_ATTRIBUTE5
                            ,SHIP_LINE_ATTRIBUTE6
                            ,SHIP_LINE_ATTRIBUTE7
                            ,SHIP_LINE_ATTRIBUTE8
                            ,SHIP_LINE_ATTRIBUTE9
                            ,SHIP_LINE_ATTRIBUTE10
                            ,SHIP_LINE_ATTRIBUTE11
                            ,SHIP_LINE_ATTRIBUTE12
                            ,SHIP_LINE_ATTRIBUTE13
                            ,SHIP_LINE_ATTRIBUTE14
                            ,SHIP_LINE_ATTRIBUTE15
                            ,USSGL_TRANSACTION_CODE
                            ,GOVERNMENT_CONTEXT
                            ,REASON_ID
                            ,DESTINATION_CONTEXT
                            ,SOURCE_DOC_QUANTITY
                            ,SOURCE_DOC_UNIT_OF_MEASURE
                            ,MOVEMENT_ID
                            ,HEADER_INTERFACE_ID
                            ,VENDOR_CUM_SHIPPED_QTY
                            ,ITEM_NUM
                            ,DOCUMENT_NUM
                            ,DOCUMENT_LINE_NUM
                            ,TRUCK_NUM
                            ,SHIP_TO_LOCATION_CODE
                            ,CONTAINER_NUM
                            ,SUBSTITUTE_ITEM_NUM
                            ,NOTICE_UNIT_PRICE
                            ,ITEM_CATEGORY
                            ,LOCATION_CODE
                            ,VENDOR_NAME
                            ,VENDOR_NUM
                            ,VENDOR_SITE_CODE
                            ,FROM_ORGANIZATION_CODE
                            ,TO_ORGANIZATION_CODE
                            ,INTRANSIT_OWNING_ORG_CODE
                            ,ROUTING_CODE
                            ,ROUTING_STEP
                            ,RELEASE_NUM
                            ,DOCUMENT_SHIPMENT_LINE_NUM
                            ,DOCUMENT_DISTRIBUTION_NUM
                            ,DELIVER_TO_PERSON_NAME
                            ,DELIVER_TO_LOCATION_CODE
                            ,USE_MTL_LOT
                            ,USE_MTL_SERIAL
                            ,LOCATOR
                            ,REASON_NAME
                            ,VALIDATION_FLAG
                            ,SUBSTITUTE_ITEM_ID
                            ,QUANTITY_SHIPPED
                            ,QUANTITY_INVOICED
                            ,TAX_NAME
                            ,TAX_AMOUNT
                            ,REQ_NUM
                            ,REQ_LINE_NUM
                            ,REQ_DISTRIBUTION_NUM
                            ,WIP_ENTITY_NAME
                            ,WIP_LINE_CODE
                            ,RESOURCE_CODE
                            ,SHIPMENT_LINE_STATUS_CODE
                            ,BARCODE_LABEL
                            ,TRANSFER_PERCENTAGE
                            ,QA_COLLECTION_ID
                            ,COUNTRY_OF_ORIGIN_CODE
                            ,OE_ORDER_HEADER_ID
                            ,OE_ORDER_LINE_ID
                            ,CUSTOMER_ID
                            ,CUSTOMER_SITE_ID
                            ,CUSTOMER_ITEM_NUM
                            ,CREATE_DEBIT_MEMO_FLAG
                            ,PUT_AWAY_RULE_ID
                            ,PUT_AWAY_STRATEGY_ID
                            ,LPN_ID
                            ,TRANSFER_LPN_ID
                            ,COST_GROUP_ID
                            ,MOBILE_TXN
                            ,MMTT_TEMP_ID
                            ,TRANSFER_COST_GROUP_ID
                            ,SECONDARY_QUANTITY
                            ,SECONDARY_UNIT_OF_MEASURE
                            ,SECONDARY_UOM_CODE
                            ,QC_GRADE
                            ,FROM_LOCATOR
                            ,FROM_LOCATOR_ID
                            ,PARENT_SOURCE_TRANSACTION_NUM
                            ,INTERFACE_AVAILABLE_QTY
                            ,INTERFACE_TRANSACTION_QTY
                            ,INTERFACE_AVAILABLE_AMT
                            ,INTERFACE_TRANSACTION_AMT
                            ,LICENSE_PLATE_NUMBER
                            ,SOURCE_TRANSACTION_NUM
                            ,TRANSFER_LICENSE_PLATE_NUMBER
                            ,LPN_GROUP_ID
                            ,ORDER_TRANSACTION_ID
                            ,CUSTOMER_ACCOUNT_NUMBER
                            ,CUSTOMER_PARTY_NAME
                            ,OE_ORDER_LINE_NUM
                            ,OE_ORDER_NUM
                            ,PARENT_INTERFACE_TXN_ID
                            ,CUSTOMER_ITEM_ID
                            ,AMOUNT
                            ,JOB_ID
                            ,TIMECARD_ID
                            ,TIMECARD_OVN
                            ,ERECORD_ID
                            ,PROJECT_ID
                            ,TASK_ID
                            ,ASN_ATTACH_ID
                            ,ORG_ID
                            ,OPERATING_UNIT
                            ,REQUESTED_AMOUNT
                            ,MATERIAL_STORED_AMOUNT
                            ,AMOUNT_SHIPPED
                            ,MATCHING_BASIS
                            ,REPLENISH_ORDER_LINE_ID
                            ,E0342_STATUS_FLAG
                            ,E0342_FIRST_REC_TIME
                            ,E0346_STATUS_FLAG
                            ,E0342_ERROR_CODE
                            ,E0342_ERROR_DESCRIPTION
                            ,ATTRIBUTE8
                           )
                           SELECT
                            INTERFACE_TRANSACTION_ID
                            ,GROUP_ID
                            ,LAST_UPDATE_DATE
                            ,LAST_UPDATED_BY
                            ,CREATION_DATE
                            ,CREATED_BY
                            ,LAST_UPDATE_LOGIN
                            ,REQUEST_ID
                            ,PROGRAM_APPLICATION_ID
                            ,PROGRAM_ID
                            ,PROGRAM_UPDATE_DATE
                            ,TRANSACTION_TYPE
                            ,TRANSACTION_DATE
                            ,PROCESSING_STATUS_CODE
                            ,PROCESSING_MODE_CODE
                            ,PROCESSING_REQUEST_ID
                            ,TRANSACTION_STATUS_CODE
                            ,CATEGORY_ID
                            ,QUANTITY
                            ,UNIT_OF_MEASURE
                            ,INTERFACE_SOURCE_CODE
                            ,INTERFACE_SOURCE_LINE_ID
                            ,INV_TRANSACTION_ID
                            ,ITEM_ID
                            ,ITEM_DESCRIPTION
                            ,ITEM_REVISION
                            ,UOM_CODE
                            ,EMPLOYEE_ID
                            ,AUTO_TRANSACT_CODE
                            ,SHIPMENT_HEADER_ID
                            ,SHIPMENT_LINE_ID
                            ,SHIP_TO_LOCATION_ID
                            ,PRIMARY_QUANTITY
                            ,PRIMARY_UNIT_OF_MEASURE
                            ,RECEIPT_SOURCE_CODE
                            ,VENDOR_ID
                            ,VENDOR_SITE_ID
                            ,FROM_ORGANIZATION_ID
                            ,FROM_SUBINVENTORY
                            ,TO_ORGANIZATION_ID
                            ,INTRANSIT_OWNING_ORG_ID
                            ,ROUTING_HEADER_ID
                            ,ROUTING_STEP_ID
                            ,SOURCE_DOCUMENT_CODE
                            ,PARENT_TRANSACTION_ID
                            ,PO_HEADER_ID
                            ,PO_REVISION_NUM
                            ,PO_RELEASE_ID
                            ,PO_LINE_ID
                            ,PO_LINE_LOCATION_ID
                            ,PO_UNIT_PRICE
                            ,CURRENCY_CODE
                            ,CURRENCY_CONVERSION_TYPE
                            ,CURRENCY_CONVERSION_RATE
                            ,CURRENCY_CONVERSION_DATE
                            ,PO_DISTRIBUTION_ID
                            ,REQUISITION_LINE_ID
                            ,REQ_DISTRIBUTION_ID
                            ,CHARGE_ACCOUNT_ID
                            ,SUBSTITUTE_UNORDERED_CODE
                            ,RECEIPT_EXCEPTION_FLAG
                            ,ACCRUAL_STATUS_CODE
                            ,INSPECTION_STATUS_CODE
                            ,INSPECTION_QUALITY_CODE
                            ,DESTINATION_TYPE_CODE
                            ,DELIVER_TO_PERSON_ID
                            ,LOCATION_ID
                            ,DELIVER_TO_LOCATION_ID
                            ,SUBINVENTORY
                            ,LOCATOR_ID
                            ,WIP_ENTITY_ID
                            ,WIP_LINE_ID
                            ,DEPARTMENT_CODE
                            ,WIP_REPETITIVE_SCHEDULE_ID
                            ,WIP_OPERATION_SEQ_NUM
                            ,WIP_RESOURCE_SEQ_NUM
                            ,BOM_RESOURCE_ID
                            ,SHIPMENT_NUM
                            ,FREIGHT_CARRIER_CODE
                            ,BILL_OF_LADING
                            ,PACKING_SLIP
                            ,SHIPPED_DATE
                            ,EXPECTED_RECEIPT_DATE
                            ,ACTUAL_COST
                            ,TRANSFER_COST
                            ,TRANSPORTATION_COST
                            ,TRANSPORTATION_ACCOUNT_ID
                            ,NUM_OF_CONTAINERS
                            ,WAYBILL_AIRBILL_NUM
                            ,VENDOR_ITEM_NUM
                            ,VENDOR_LOT_NUM
                            ,RMA_REFERENCE
                            ,COMMENTS
                            ,ATTRIBUTE_CATEGORY
                            ,ATTRIBUTE1
                            ,ATTRIBUTE2
                            ,ATTRIBUTE3
                            ,ATTRIBUTE4
                            ,ATTRIBUTE5
                            ,ATTRIBUTE6
                            ,ATTRIBUTE7
                            ,ATTRIBUTE9
                            ,ATTRIBUTE10
                            ,ATTRIBUTE11
                            ,ATTRIBUTE12
                            ,ATTRIBUTE13
                            ,ATTRIBUTE14
                            ,ATTRIBUTE15
                            ,SHIP_HEAD_ATTRIBUTE_CATEGORY
                            ,SHIP_HEAD_ATTRIBUTE1
                            ,SHIP_HEAD_ATTRIBUTE2
                            ,SHIP_HEAD_ATTRIBUTE3
                            ,SHIP_HEAD_ATTRIBUTE4
                            ,SHIP_HEAD_ATTRIBUTE5
                            ,SHIP_HEAD_ATTRIBUTE6
                            ,SHIP_HEAD_ATTRIBUTE7
                            ,SHIP_HEAD_ATTRIBUTE8
                            ,SHIP_HEAD_ATTRIBUTE9
                            ,SHIP_HEAD_ATTRIBUTE10
                            ,SHIP_HEAD_ATTRIBUTE11
                            ,SHIP_HEAD_ATTRIBUTE12
                            ,SHIP_HEAD_ATTRIBUTE13
                            ,SHIP_HEAD_ATTRIBUTE14
                            ,SHIP_HEAD_ATTRIBUTE15
                            ,SHIP_LINE_ATTRIBUTE_CATEGORY
                            ,SHIP_LINE_ATTRIBUTE1
                            ,SHIP_LINE_ATTRIBUTE2
                            ,SHIP_LINE_ATTRIBUTE3
                            ,SHIP_LINE_ATTRIBUTE4
                            ,SHIP_LINE_ATTRIBUTE5
                            ,SHIP_LINE_ATTRIBUTE6
                            ,SHIP_LINE_ATTRIBUTE7
                            ,SHIP_LINE_ATTRIBUTE8
                            ,SHIP_LINE_ATTRIBUTE9
                            ,SHIP_LINE_ATTRIBUTE10
                            ,SHIP_LINE_ATTRIBUTE11
                            ,SHIP_LINE_ATTRIBUTE12
                            ,SHIP_LINE_ATTRIBUTE13
                            ,SHIP_LINE_ATTRIBUTE14
                            ,SHIP_LINE_ATTRIBUTE15
                            ,USSGL_TRANSACTION_CODE
                            ,GOVERNMENT_CONTEXT
                            ,REASON_ID
                            ,DESTINATION_CONTEXT
                            ,SOURCE_DOC_QUANTITY
                            ,SOURCE_DOC_UNIT_OF_MEASURE
                            ,MOVEMENT_ID
                            ,HEADER_INTERFACE_ID
                            ,VENDOR_CUM_SHIPPED_QTY
                            ,ITEM_NUM
                            ,DOCUMENT_NUM
                            ,DOCUMENT_LINE_NUM
                            ,TRUCK_NUM
                            ,SHIP_TO_LOCATION_CODE
                            ,CONTAINER_NUM
                            ,SUBSTITUTE_ITEM_NUM
                            ,NOTICE_UNIT_PRICE
                            ,ITEM_CATEGORY
                            ,LOCATION_CODE
                            ,VENDOR_NAME
                            ,VENDOR_NUM
                            ,VENDOR_SITE_CODE
                            ,FROM_ORGANIZATION_CODE
                            ,TO_ORGANIZATION_CODE
                            ,INTRANSIT_OWNING_ORG_CODE
                            ,ROUTING_CODE
                            ,ROUTING_STEP
                            ,RELEASE_NUM
                            ,DOCUMENT_SHIPMENT_LINE_NUM
                            ,DOCUMENT_DISTRIBUTION_NUM
                            ,DELIVER_TO_PERSON_NAME
                            ,DELIVER_TO_LOCATION_CODE
                            ,USE_MTL_LOT
                            ,USE_MTL_SERIAL
                            ,LOCATOR
                            ,REASON_NAME
                            ,VALIDATION_FLAG
                            ,SUBSTITUTE_ITEM_ID
                            ,QUANTITY_SHIPPED
                            ,QUANTITY_INVOICED
                            ,TAX_NAME
                            ,TAX_AMOUNT
                            ,REQ_NUM
                            ,REQ_LINE_NUM
                            ,REQ_DISTRIBUTION_NUM
                            ,WIP_ENTITY_NAME
                            ,WIP_LINE_CODE
                            ,RESOURCE_CODE
                            ,SHIPMENT_LINE_STATUS_CODE
                            ,BARCODE_LABEL
                            ,TRANSFER_PERCENTAGE
                            ,QA_COLLECTION_ID
                            ,COUNTRY_OF_ORIGIN_CODE
                            ,OE_ORDER_HEADER_ID
                            ,OE_ORDER_LINE_ID
                            ,CUSTOMER_ID
                            ,CUSTOMER_SITE_ID
                            ,CUSTOMER_ITEM_NUM
                            ,CREATE_DEBIT_MEMO_FLAG
                            ,PUT_AWAY_RULE_ID
                            ,PUT_AWAY_STRATEGY_ID
                            ,LPN_ID
                            ,TRANSFER_LPN_ID
                            ,COST_GROUP_ID
                            ,MOBILE_TXN
                            ,MMTT_TEMP_ID
                            ,TRANSFER_COST_GROUP_ID
                            ,SECONDARY_QUANTITY
                            ,SECONDARY_UNIT_OF_MEASURE
                            ,SECONDARY_UOM_CODE
                            ,QC_GRADE
                            ,FROM_LOCATOR
                            ,FROM_LOCATOR_ID
                            ,PARENT_SOURCE_TRANSACTION_NUM
                            ,INTERFACE_AVAILABLE_QTY
                            ,INTERFACE_TRANSACTION_QTY
                            ,INTERFACE_AVAILABLE_AMT
                            ,INTERFACE_TRANSACTION_AMT
                            ,LICENSE_PLATE_NUMBER
                            ,SOURCE_TRANSACTION_NUM
                            ,TRANSFER_LICENSE_PLATE_NUMBER
                            ,LPN_GROUP_ID
                            ,ORDER_TRANSACTION_ID
                            ,CUSTOMER_ACCOUNT_NUMBER
                            ,CUSTOMER_PARTY_NAME
                            ,OE_ORDER_LINE_NUM
                            ,OE_ORDER_NUM
                            ,PARENT_INTERFACE_TXN_ID
                            ,CUSTOMER_ITEM_ID
                            ,AMOUNT
                            ,JOB_ID
                            ,TIMECARD_ID
                            ,TIMECARD_OVN
                            ,ERECORD_ID
                            ,PROJECT_ID
                            ,TASK_ID
                            ,ASN_ATTACH_ID
                            ,NULL
                            ,NULL
                            ,NULL
                            ,NULL
                            ,NULL
                            ,NULL
                            ,NULL
                            ,gc_e0342_flag
                            ,SYSDATE
                            ,gc_e0346_flag
                            ,NULL
                            ,NULL
                            ,ATTRIBUTE8
      FROM  rcv_transactions_interface
      WHERE interface_transaction_id=gn_interface_transaction_id;
      DELETE 
      FROM  rcv_transactions_interface
      WHERE interface_transaction_id=gn_interface_transaction_id;
      COMMIT;
     END IF;
    END LOOP;-- loop for lcu_rcv_lines_curr_rec
    -- To send email notification 
                       
                   XX_GI_EXCEPTION_PKG.NOTIFY_PROC (gn_request_id
                                                   ,gc_item_type
                                                   ,gn_interface_transaction_id
                                                   ,gc_email_address
                                                   ,gc_errbuff
                                                   ,gc_retcode
                                                   );
END MAIN_ADD_SKU_PROC;-- MAIN PROC
-- +================================================================================+
-- | Name        :  VAL_ITEM_RECEV_ORG_PROC                                         |
-- | Description :  This  procedure will check whether item is available on         |
-- |                receiving organization or not                                   |
-- | Parameters   : p_item_num,p_org_id                                             |
-- +================================================================================+
-- check whether item assigned to receiving organization or not 
PROCEDURE VAL_ITEM_RECEV_ORG_PROC(
                                  p_item_num VARCHAR2
                                  ,p_org_id   NUMBER
                                  )
AS
--Declare Local Variables
ln_inventory_item_id  NUMBER;
lc_sqlcode            VARCHAR2 (100);
lc_sqlerrm            VARCHAR2 (2000);
lc_item_type          VARCHAR2(2):='T';
lc_errbuff            VARCHAR2(100);
lc_retcode            VARCHAR2(1000);
BEGIN
    gn_sqlpoint:='70';
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
    IF ln_inventory_item_id is NULL THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'ITEM NOT ASSIGNED TO RECEIVING ORGANIZATION' );
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'ITEM NUM' ||'    '||'RECEVING ORG');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gc_item_num ||'    '||gn_org_id);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'----------------------------------------------------------------');
      gc_status_flag := 'ERROR';
      gc_e0342_flag := 'E'; 
      gc_e0346_flag := 'N';
      lc_sqlcode := SQLCODE;
      lc_sqlerrm := SUBSTR(SQLERRM,1,250);
      FND_MESSAGE.SET_NAME('xxptp','XX_GI_MISSHIP_ASN_I001');
      gc_error_message      := FND_MESSAGE.GET||lc_sqlcode||lc_sqlerrm;
      gc_error_message_code := 'XX_GI_MISSHIP_ASN_I001'; --‘Item not assigned to receiving organization’
      gc_object_id          := gn_interface_transaction_id;
      gc_object_type        :='Interface_transaction_id';
      XX_COM_ERROR_LOG_PUB.LOG_ERROR(NULL
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
    ELSE 
     -- Check whether item and organization both matching with Purchase Order line 
       VAL_PO_ITEM_ORG_PROC(ln_inventory_item_id
                            ,gc_document_num
                            ,p_org_id
                           );
    END IF;
END VAL_ITEM_RECEV_ORG_PROC;
-- +================================================================================+
-- | Name        :  VAL_UPC_CODE_PROC                                               |
-- | Description :  This  procedure will check whether RTI item matches with the    |
-- |                 UPC code or not.If it matches then then Item num in RTI will   |
-- |                 be replace with this UPC code                                  |
-- | Parameters  : p_item_num,p_org_id,p_interface_transaction_id,p_master_org_id   |
-- +================================================================================+
-- Procedure VAL_UPC_CODE_PROC
PROCEDURE VAL_UPC_CODE_PROC(
                           p_item_num                  VARCHAR2
                           ,p_org_id                   NUMBER
                           ,p_interface_transaction_id NUMBER
                           ,p_master_org_id            NUMBER
                           )
AS
---Declare Local Variables
lc_upc     mtl_system_items.segment1%TYPE;
lc_sqlcode VARCHAR2(100);
lc_sqlerrm VARCHAR2(2000);
BEGIN
     gn_sqlpoint:='80';
     SELECT MSI.segment1
     INTO   lc_upc
     FROM   mtl_system_items      MSI
           , mtl_cross_references MCR
     WHERE  MSI.inventory_item_id    = MCR.inventory_item_id
     AND    MSI.organization_id      = p_master_org_id
     AND    MCR.cross_reference_type = 'XX_GI_UPC'
     AND    MCR.cross_reference      = p_item_num;
                    
     UPDATE  rcv_transactions_interface
     SET     item_num = lc_upc
     WHERE   interface_transaction_id=p_interface_transaction_id;
     gn_sqlpoint:='81';
     COMMIT;
     gn_sqlpoint:='90';
     --Check whether item exist in the receiving organization or not
     VAL_ITEM_RECEV_ORG_PROC(lc_upc
                             ,p_org_id
                             );
     gn_sqlpoint:='100';
EXCEPTION
   WHEN NO_DATA_FOUND THEN
   --call procedure VAL_VPC_CODE_PROC
   VAL_VPC_CODE_PROC(p_item_num
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
-- | Parameters  : p_item_num,p_org_id,p_interface_transaction_id,p_master_org_id   |
-- +================================================================================+
-- Procedure VAL_VPC_CODE_PROC
PROCEDURE VAL_VPC_CODE_PROC(
                            p_item_num                  VARCHAR2
                            ,p_org_id                   NUMBER
                            ,p_interface_transaction_id NUMBER
                            ,p_master_org_id            NUMBER
                            )
AS
-- Declare Local variables
ln_inventory_item_id    NUMBER;
lc_item_num             VARCHAR2(81);
lc_item_type            VARCHAR2(20) :='T';
ln_email_cnt            NUMBER;
lc_sqlcode              VARCHAR2(100);
lc_sqlerrm              VARCHAR2(2000);
lc_errbuff              VARCHAR2(100);
lc_retcode              VARCHAR2(1000);
BEGIN
      gn_sqlpoint:='110';
      SELECT     MSI.SEGMENT1
      INTO       lc_item_num
      FROM       po_approved_supplier_list ASL
                 ,mtl_system_items MSI
      WHERE      ASL.primary_vendor_item = p_item_num
      AND        ASL.item_id = MSI.inventory_item_id
      AND        MSI.organization_id = p_master_org_id;
      gn_sqlpoint:='130';
      UPDATE    rcv_transactions_interface 
      SET       item_num = lc_item_num 
      WHERE     interface_transaction_id= p_interface_transaction_id;
      COMMIT;
      gn_sqlpoint:='140';
      --Check whether item exist in the receiving organization or not
      VAL_ITEM_RECEV_ORG_PROC(lc_item_num
                              ,p_org_id
                             );
      gn_sqlpoint:='150';
EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gc_status_flag := 'ERROR';
        gc_e0342_flag := 'VE';
        gc_e0346_flag := 'Y';
      
      /*Print error message in fnd output file*/
        FND_FILE.PUT_LINE(FND_FILE.LOG,'ITEM DOES NOT MATCH UPC/VPC' ||gn_sqlpoint);
        lc_sqlcode := SQLCODE;
        lc_sqlerrm := SUBSTR(SQLERRM,1,250);
        FND_MESSAGE.SET_NAME('xxptp', 'XX_GI_MISSHIP_ASN_I004');
        gc_error_message      := FND_MESSAGE.GET||lc_sqlcode||lc_sqlerrm;
        gc_error_message_code := 'XX_GI_MISSHIP_ASN_I004'; 
        gc_object_id          := gn_interface_transaction_id;
        gc_object_type        :='Interface_transaction_id';
        XX_COM_ERROR_LOG_PUB.LOG_ERROR(NULL
                                       ,NULL
                                       ,'EBS'
                                       ,'Procedure'
                                       ,'VAL_UPC_CODE_PROC'
                                       , NULL
                                       , 'GI'
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
-- +================================================================================+
-- | Name        :  VAL_PO_ITEM_ORG_PROC                                            |
-- | Description :  This  procedure will Validate whether item and organization     |
-- |                both matching with Purchase Order line                          |
-- | Parameters  :  p_inventory_item_id,p_document_num,p_org_id                     |
-- +================================================================================+
-- Procedure to Check whether item and organization both matching with Purchase Order line
PROCEDURE VAL_PO_ITEM_ORG_PROC(
                              p_inventory_item_id NUMBER
                              ,p_document_num     VARCHAR2
                              ,p_org_id           NUMBER
                              )
AS
-- Declare local variables
ln_quantity     NUMBER;
lc_sqlcode      VARCHAR2(100);
lc_sqlerrm      VARCHAR2(2000);
BEGIN 
     gn_sqlpoint:='160';
     SELECT  SUM(PLLA.quantity)
     INTO    ln_quantity
     FROM    po_headers_all          PHA
            ,po_lines_all            PLA
            ,po_line_locations_all   PLLA
     WHERE  PHA.segment1                 = p_document_num
     AND    PHA.po_header_id             = PLA.po_header_id
     AND    PLA.item_id                  = p_inventory_item_id
     AND    PLA.po_line_id               = PLLA.po_line_id
     AND    PLLA.ship_to_organization_id = p_org_id;
     gn_sqlpoint:='170';
     IF NVL(ln_quantity,0) = 0 THEN
      --Check whether item and vendor are mapped in ASL
        VAL_PO_ITEM_VDR_ASL_PROC(p_inventory_item_id
                                 ,gn_vendor_id
                                 ,gn_vendor_site_id
                                 ,p_org_id
                                );
     ELSIF ln_quantity < gn_quantity THEN
        gc_status_flag := 'ERROR';
        gc_e0342_flag  := 'VE';
        gc_e0346_flag  := 'Y';
     ELSE
        --Check whether PO is open or not
        VAL_PO_OPEN_PROC(gc_document_num
                         ,gn_po_header_id
                         );
        gn_sqlpoint:='210';
     END IF;
END VAL_PO_ITEM_ORG_PROC;
-- +================================================================================+
-- | Name        :  VAL_PO_ITEM_VDR_ASL_PROC                                        |
-- | Description :  This  procedure will Validate whether item and vendor are       |
-- |                mapped in ASL                                                   |
-- | Parameters  : p_inventory_item_id,p_vendor_id,p_vendor_site_id,                |
-- |               p_organization_id                                                |
-- +================================================================================+
-- Validate whether item and vendor are mapped in ASL 
PROCEDURE VAL_PO_ITEM_VDR_ASL_PROC(
                                  p_inventory_item_id NUMBER
                                  ,p_vendor_id        NUMBER
                                  ,p_vendor_site_id   NUMBER
                                  ,p_organization_id  NUMBER
                                  )
AS
--Declare local variables 
ln_unit_price   NUMBER;
ln_po_header_id   NUMBER;
lc_sqlcode      VARCHAR2(100);
lc_sqlerrm      VARCHAR2(2000);
BEGIN
     gn_sqlpoint:='220';
     
     SELECT    MAX(PHA.po_header_id)
     INTO      ln_po_header_id
     FROM      po_approved_supplier_list PASL
              ,po_lines_all    PLA
              ,po_headers_all  PHA
     WHERE     PASL.owning_organization_id = p_organization_id
     AND      PASL.item_id = p_inventory_item_id
     AND      PASL.asl_status_id = 2
     AND      PASL.disable_flag IS NULL
     AND      PASL.vendor_id = p_vendor_id
     AND      NVL(PASL.vendor_site_id, p_vendor_site_id) = p_vendor_site_id
     AND      PASL.item_id = PLA.item_id
     AND      PLA.po_header_id =PHA.po_header_id
     AND      PHA.vendor_id = p_vendor_id
     AND      PHA.vendor_site_id = p_vendor_site_id
     AND      PHA.type_lookup_code = 'QUOTATION'
     GROUP BY PHA.po_header_id;
     
    SELECT  unit_price
    INTO    ln_unit_price
    FROM    po_lines_all
    WHERE   po_header_id = ln_po_header_id
    AND     item_id      = p_inventory_item_id;
     -- If item is available on ASL then it will add new PO line and
     -- auto-approve the PO using custom API  xx_gi_exception_pkg.insert_po_line_proc
     gc_status_flag := 'ERROR'; 
     gc_e0342_flag  := 'E'; 
     gc_e0346_flag  := 'N';
     xx_gi_exception_pkg.insert_po_line_proc(gc_document_num
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
     gn_sqlpoint:='230';
EXCEPTION
   WHEN NO_DATA_FOUND THEN
     gc_status_flag  := 'ERROR';
     gc_e0342_flag   := 'VE';
     gc_e0346_flag   := 'Y';
     lc_sqlcode := SQLCODE;
     lc_sqlerrm := SUBSTR(SQLERRM,1,250);
     FND_FILE.PUT_LINE(FND_FILE.LOG,lc_sqlcode||lc_sqlerrm);
     FND_MESSAGE.SET_NAME('xxptp', 'XX_GI_MISSHIP_ASN_I003');
     gc_error_message      := FND_MESSAGE.GET||lc_sqlcode||lc_sqlerrm;
     gc_error_message_code :='XX_GI_MISSHIP_ASN_I003';
     gc_object_id          := gn_interface_transaction_id;
     gc_object_type        :='Interface_transaction_id';
     XX_COM_ERROR_LOG_PUB.LOG_ERROR(NULL
                                    ,NULL
                                    ,'EBS'
                                    ,'Procedure'
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
-- |                                                                                |
-- | Parameters  : p_document_num,p_po_header_id                                    |
-- +================================================================================+
PROCEDURE VAL_PO_OPEN_PROC (
                            p_document_num  VARCHAR2
                            ,p_po_header_id  NUMBER
                            )
AS
--Declare local variable
lc_closed_code  VARCHAR2(25);
lc_sqlcode      VARCHAR2(100);
lc_sqlerrm      VARCHAR2(2000);
BEGIN
     gn_sqlpoint:='250';
     SELECT closed_code
     INTO   lc_closed_code
     FROM   po_headers_all
     WHERE  po_header_id= p_po_header_id;
     gn_sqlpoint:='260';
     IF NVL(lc_closed_code,'OPEN')='OPEN' THEN
        --Check whether PO/INV period is open or not
        VAL_POINVPERIOD_PROC(
                             gn_interface_transaction_id
                             ,gc_document_num
                             );
        gn_sqlpoint:='270';
     ELSE
        gc_status_flag := 'ERROR';
        gc_e0342_flag  := 'VE';
        gc_e0346_flag  := 'Y';
        lc_sqlcode := SQLCODE;
        lc_sqlerrm := SUBSTR(SQLERRM,1,250);
        FND_FILE.PUT_LINE(FND_FILE.LOG,lc_sqlcode || lc_sqlerrm);
        FND_MESSAGE.SET_NAME('xxptp','XX_GI_MISSHIP_ASN_99999');
        gc_error_message      := FND_MESSAGE.GET||lc_sqlcode||lc_sqlerrm;
        gc_error_message_code :='XX_GI_MISSHIP_ASN_99999';--‘PO is not open to receive’
        gc_object_id          := gn_interface_transaction_id;
        gc_object_type        :='Interface_transaction_id';
        XX_COM_ERROR_LOG_PUB.LOG_ERROR(NULL
                                       ,NULL
                                       ,'EBS'
                                       ,'Procedure'
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
-- +================================================================================+
-- | Name        :  VAL_POINVPERIOD_PROC                                            |
-- | Description :  This  procedure will Validate whether PO/INV period is open     |
-- |                or not                                                          |
-- | Parameters  : p_interface_transaction_id,p_document_num                        |
-- +================================================================================+
--Check whether INV period is ‘OPEN’ for the receipt date.
PROCEDURE VAL_POINVPERIOD_PROC(
                               p_interface_transaction_id NUMBER
                               ,p_document_num            VARCHAR2
                               )
AS
-- Deaclare local variable
lc_closing_status VARCHAR2(10);
lc_errbuff        VARCHAR2(100);
lc_retcode        VARCHAR2(1000);
BEGIN
      gn_sqlpoint:='280';
      BEGIN
         SELECT status
         INTO   lc_closing_status
         FROM   org_acct_periods_v
         WHERE  organization_id = gn_org_id
         AND    gd_receipt_date BETWEEN start_date AND end_date;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid Vendor and item combination in ASL for item_num '||gc_item_num||gn_sqlpoint);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'STATUS NOT FOUND ');
      WHEN OTHERS THEN
        lc_retcode := SQLCODE;
        lc_errbuff :=SUBSTR (SQLERRM ,1 ,250);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid Vendor and item combination in ASL for item_num '||gc_item_num||gn_sqlpoint);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Inside  WHEN OTHERS of select status '||lc_retcode||lc_errbuff);
      END;
      IF UPPER(lc_closing_status) ='OPEN' THEN
         gn_sqlpoint:='300';
          UPDATE  rcv_transactions_interface
         SET     processing_status_code     ='PENDING'
                 ,processing_mode_code      ='BATCH'
                 ,transaction_status_code   ='PENDING'
                 ,last_update_date          =SYSDATE
                 ,processing_request_id     =NULL
         WHERE interface_transaction_id    = p_interface_transaction_id;
         COMMIT;
         gn_sqlpoint:='310';
      ELSE
         gc_status_flag := 'ERROR';
         gc_e0342_flag  := 'VE';
         gc_e0346_flag  := 'Y';
         lc_retcode := SQLCODE;
         lc_errbuff :=SUBSTR (SQLERRM ,1 ,250);
         FND_MESSAGE.SET_NAME('xxptp', 'XX_GI_MISSHIP_ASN_R001');
         gc_error_message      := FND_MESSAGE.GET||lc_retcode||lc_errbuff;
         gc_error_message_code :='XX_GI_MISSHIP_ASN_R001';
         gc_object_id          := gn_interface_transaction_id;
         gc_object_type        :='Interface_transaction_id';
         XX_COM_ERROR_LOG_PUB.LOG_ERROR(NULL
                                        ,NULL
                                        ,'EBS'
                                        ,'Procedure'
                                        ,'VAL_POINVPERIOD_PROC'
                                        , NULL
                                        , 'GI'
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

END XX_GI_MISSHIP_ASN_PKG;
/
SHOW ERROR



















