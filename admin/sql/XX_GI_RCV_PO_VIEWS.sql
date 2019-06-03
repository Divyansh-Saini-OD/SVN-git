1.) XX_GI_RCV_STG_PO_V 
    -------------------

CREATE OR REPLACE VIEW xx_gi_rcv_stg_po_v AS
SELECT XGRPD.attribute8             keyrec
      ,XGRPH.receipt_num               
      ,XGRPD.attribute5             doc_num
      ,XGRPH.E0342_first_rec_time   
      ,XGRPD.source_document_code   
      ,XGRPD.E0342_status_flag      status
      ,XGRPD.document_num
      ,XGRPD.document_line_num  
      ,XGRPH.vendor_id                       
      ,XGRPH.attribute1             from_loc_id
      ,XGRPH.num_of_containers      cartons     
      ,XGRPH.comments               
      ,XGRPD.attribute3             sku  		
      ,XGET.msg_code                err_code
      ,XGET.msg_desc                err_desc
FROM   xx_gi_rcv_po_hdr             XGRPH
      ,xx_gi_rcv_po_dtl             XGRPD
      ,xx_gi_error_tbl              XGET
WHERE XGRPH.header_interface_id      = XGRPD.header_interface_id
AND   XGRPD.interface_transaction_id = XGET.entity_ref_id; 



2.)XX_GI_RCV_TRN_PO_V
   -------------------
CREATE OR REPLACE VIEW xx_gi_rcv_trn_po_v AS
SELECT  RSH.receipt_num 
       ,RSH.attribute8                 keyrec
       ,PH.segment1                    document_num
       ,RSL.line_num                   document_line_num                      
       ,RSL.source_document_code       
       ,RSL.shipment_line_status_code  
       ,PV.vendor_name                 
       ,HOU.attribute1                 from_loc_id             
       ,RSH.num_of_containers          
       ,RSH.comments                    
       ,MSI.segment1                   sku
       ,RSL.item_description           
       ,RSL.quantity_received          qty_received
       ,PL.quantity                    qty_shipped 
       ,RSL.unit_of_measure            uom
FROM    rcv_shipment_headers      RSH
       ,rcv_shipment_lines        RSL
       ,po_headers_all            PH
       ,po_lines_all              PL
       ,po_vendors                PV
       ,mtl_system_items_b        MSI
       ,hr_all_organization_units HOU
WHERE   RSL.source_document_code = 'PO'
AND     RSL.shipment_line_status_code IN ('PARTIALLY RECEIVED', 'FULLY RECEIVED')
AND     RSH.shipment_header_id = RSL.shipment_header_id 
AND     RSL.po_header_id       = PH.po_header_id
AND     RSL.po_line_id         = PL.po_line_id
AND     RSH.vendor_id          = PV.vendor_id
AND     RSL.item_id            = MSI.Inventory_item_id
AND     RSL.to_organization_id = MSI.organization_id
AND     RSL.to_organization_id = HOU.organization_id;



View based on 1 and 2 above
3.) XX_GI_RCV_COND_PO_V
    -------------------
    
 
CREATE OR REPLACE VIEW xx_gi_rcv_cond_po_v AS
SELECT  XGRPD.attribute8                keyrec
       ,XGRPH.receipt_num                  
       ,XGRPD.document_num              
       ,XGRPD.document_line_num            
       ,XGRPD.source_document_code             
       ,XGRPH.vendor_name                      
       ,XGRPH.num_of_containers          
       ,XGRPD.attribute3                sku  		
       ,XGRPD.item_description           
       ,XGRPD.shipment_line_status_code  
       ,XGRPD.Attribute1                from_loc_id        
       ,decode(XGRPD.E0342_status_flag,'VE','Error','P','Success','Inprocess')  Status
       ,XGET.msg_code                err_code
       ,XGET.msg_desc                err_desc       
 FROM   xx_gi_rcv_po_hdr             XGRPH
       ,xx_gi_rcv_po_dtl             XGRPD
       ,xx_gi_error_tbl              XGET
WHERE XGRPH.header_interface_id      = XGRPD.header_interface_id
AND   XGRPD.interface_transaction_id = XGET.entity_ref_id
UNION
SELECT  RSH.attribute8                 keyrec
       ,RSH.receipt_num 
       ,PH.segment1                    document_num
       ,RSL.line_num                   document_line_num                    
       ,RSL.source_document_code       
       ,PV.vendor_name                 
       ,RSH.num_of_containers          
       ,MSI.Segment1                   sku
       ,RSL.item_description           
       ,RSL.shipment_line_status_code         
       ,HOU.Attribute1                 from_loc_id                    
       ,'Success'                      Status
       ,''                             err_code 
       ,''                             err_desc  
FROM    rcv_shipment_headers      RSH
       ,rcv_shipment_lines        RSL
       ,po_headers_all            PH
       ,po_lines_all              PL
       ,po_vendors                PV
       ,mtl_system_items_b        MSI
       ,hr_all_organization_units HOU
WHERE   RSL.source_document_code = 'PO'
AND     RSL.shipment_line_status_code IN ('PARTIALLY RECEIVED', 'FULLY RECEIVED')
AND     RSH.shipment_header_id = RSL.shipment_header_id 
AND     RSL.po_header_id       = PH.po_header_id
AND     RSL.po_line_id         = PL.po_line_id
AND     RSH.vendor_id          = PV.vendor_id
AND     RSL.item_id            = MSI.Inventory_item_id
AND     RSL.to_organization_id = MSI.organization_id
AND     RSL.to_organization_id = HOU.organization_id;




4.) XX_GI_RCV_ADJ_PO_V 
    ------------------

CREATE OR REPLACE VIEW xx_gi_rcv_adj_po_v AS   
SELECT  XGRPH.attribute8      keyrec
       ,RT.attribute5        document_num  
       ,''                    err_code
       ,''                    err_desc
FROM    xx_gi_rcv_po_hdr    XGRPH
       ,rcv_transactions RT
WHERE   XGRPH.attribute8 = RT.attribute8 
AND     XGRPH.attribute2 = RT.attribute2 
AND     RT.po_distribution_id NOT IN (
                                       SELECT po_distribution_id 
                                       FROM   ap_invoice_distributions_all
                                       )
UNION
SELECT  XGRPH.attribute8      keyrec
       ,XGRPD.attribute5      document_num
       ,XGET.msg_code         err_code
       ,XGET.msg_desc         err_desc
FROM    xx_gi_rcv_po_hdr      XGRPH
       ,xx_gi_rcv_po_dtl      XGRPD
       ,xx_gi_error_tbl       XGET
WHERE  XGRPH.header_interface_id = XGRPD.header_interface_id 
AND    XGRPD.interface_transaction_id = XGET.entity_ref_id
AND    XGRPH.asn_type <> 'ASN';   



5.) XX_GI_RCV_ADJ_ST_V
    ------------------

CREATE OR REPLACE VIEW xx_gi_rcv_adj_st_v AS        
SELECT  XGRSH.attribute8      keyrec
       ,RSL.attribute5        document_num
       ,''                    err_code
       ,''                    err_desc       
FROM    xx_gi_rcv_str_hdr         XGRSH
       ,rcv_shipment_lines        RSL
WHERE   XGRSH.attribute8 = RSL.attribute8 
AND     XGRSH.attribute2 = RSL.attribute2 
AND    (SYSDATE - XGRSH.e0342_first_rec_time) < 15  --PROFILE.NO_OF_DAYS
UNION
SELECT  XGRSH.attribute8        keyrec
       ,XGRSH.attribute5        document_num
       ,XGET.msg_code         err_code
       ,XGET.msg_desc         err_desc       
FROM    xx_gi_rcv_str_hdr             XGRSH
       ,xx_gi_rcv_str_dtl             XGRSD
       ,xx_gi_error_tbl               XGET
WHERE   XGRSH.header_interface_id = XGRSD.header_interface_id 
AND     XGRSD.interface_transaction_id = XGET.entity_ref_id
AND    (SYSDATE - XGRSH.e0342_first_rec_time) < 15 --PROFILE.NO_OF_DAYS;


6.) XX_GI_RCV_STG_ST_V 
    ------------------

CREATE OR REPLACE VIEW xx_gi_rcv_stg_st_v AS    
SELECT XGRSD.attribute8             keyrec
      ,XGRSH.receipt_num               
      ,XGRSD.attribute5             doc_num
      ,XGRSH.E0342_first_rec_time   
      ,XGRSD.source_document_code   
      ,XGRSD.E0342_status_flag      Status
      ,XGRSD.document_num
      ,XGRSD.document_line_num  
      ,XGRSH.vendor_id                       
      ,XGRSH.attribute1             from_loc_id
      ,XGRSH.num_of_containers      cartons
      ,XGRSH.comments               
      ,XGRSD.attribute3             sku  		
      ,XGET.msg_code                err_code
      ,XGET.msg_desc                err_desc
FROM   xx_gi_rcv_str_hdr            XGRSH
      ,xx_gi_rcv_str_dtl            XGRSD
      ,xx_gi_error_tbl              XGET
WHERE XGRSH.header_interface_id      = XGRSD.header_interface_id
AND   XGRSD.interface_transaction_id = XGET.entity_ref_id; 



7.) XX_GI_RCV_TRN_ST_V
    ------------------

CREATE OR REPLACE VIEW xx_gi_rcv_trn_st_v AS   
SELECT  RSH.receipt_num 
       ,RSH.attribute8                   leg_doc_num
       ,RSL.line_num                     document_line_num       
       ,RSH.shipment_num                 
       ,RSL.source_document_code         
       ,RSL.shipment_line_status_code    
       ,HOU.Attribute1                   from_loc_id
       ,RSH.num_of_containers            
       ,RSH.comments                     
       ,MSI.Segment1                     document_num 
       ,RSL.item_description
       ,RSL.quantity_received            qty_received
       ,MMT.transaction_quantity * -1    qty_shipped
       ,RSL.unit_of_measure              uom
FROM    rcv_shipment_headers      RSH
       ,rcv_shipment_lines        RSL
       ,mtl_system_items_b        MSI
       ,mtl_material_transactions MMT
       ,hr_all_organization_units HOU
WHERE   RSL.source_document_code = 'INVENTORY'
AND     RSL.shipment_line_status_code IN ('PARTIALLY RECEIVED', 'FULLY RECEIVED')
AND     RSH.shipment_header_id   = RSL.shipment_header_id 
AND     RSL.item_id              = MSI.Inventory_item_id
AND     RSL.to_organization_id   = MSI.organization_id
AND     RSL.mmt_transaction_id   = MMT.transaction_id
AND     RSL.from_organization_id = HOU.organization_id;


    