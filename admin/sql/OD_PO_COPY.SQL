declare

interface_header_id integer;
interface_line_id integer;
interface_distribution_id integer;
uom_code varchar(3);
p_PO_HEADER_ID integer;
p_Inc_NON_REPL_ITEMS varchar(1);
rtc varchar(1);
p_SHIP_TO_ORG integer;
cursor po_header_cursor is
    select * from po_headers_all h where h.PO_HEADER_ID = :p_PO_HEADER_ID; --PARAMETER !!!!CHANGEME!!!!
    
cursor po_lines_cursor is
    select   l.LINE_NUM
            ,loc.po_line_id
            ,loc.line_location_id
            ,loc.SHIPMENT_NUM
            ,l.ITEM_ID
            ,l.VENDOR_PRODUCT_NUM
            ,l.UNIT_MEAS_LOOKUP_CODE 
            ,l.QUANTITY          
            ,l.UNIT_PRICE            
            ,l.UN_NUMBER_ID
            ,l.HAZARD_CLASS_ID
            ,l.NOTE_TO_VENDOR
            ,l.TAXABLE_FLAG
            ,l.TAX_NAME
            ,loc.INSPECTION_REQUIRED_FLAG
            ,loc.RECEIPT_REQUIRED_FLAG
            ,loc.INVOICE_CLOSE_TOLERANCE
            ,loc.RECEIVE_CLOSE_TOLERANCE
            ,loc.DAYS_EARLY_RECEIPT_ALLOWED
            ,loc.DAYS_LATE_RECEIPT_ALLOWED
            ,loc.ENFORCE_SHIP_TO_LOCATION_CODE
            ,loc.ALLOW_SUBSTITUTE_RECEIPTS_FLAG
            ,loc.RECEIVING_ROUTING_ID
            ,loc.QTY_RCV_TOLERANCE
            ,loc.QTY_RCV_EXCEPTION_CODE
            ,loc.RECEIPT_DAYS_EXCEPTION_CODE
            ,loc.NEED_BY_DATE
            ,loc.PROMISED_DATE
            ,loc.ACCRUE_ON_RECEIPT_FLAG            
            ,l.ATTRIBUTE_CATEGORY LINE_ATTRIBUTE_CATEGORY
            ,l.ATTRIBUTE1 LINE_ATTRIBUTE1 
            ,l.ATTRIBUTE2 LINE_ATTRIBUTE2
            ,l.ATTRIBUTE3 LINE_ATTRIBUTE3
            ,l.ATTRIBUTE4 LINE_ATTRIBUTE4
            ,l.ATTRIBUTE5 LINE_ATTRIBUTE5
            ,l.ATTRIBUTE6 LINE_ATTRIBUTE6
            ,l.ATTRIBUTE7 LINE_ATTRIBUTE7
            ,l.ATTRIBUTE8 LINE_ATTRIBUTE8
            ,l.ATTRIBUTE9 LINE_ATTRIBUTE9
            ,l.ATTRIBUTE10 LINE_ATTRIBUTE10
            ,l.ATTRIBUTE11 LINE_ATTRIBUTE11
            ,l.ATTRIBUTE12 LINE_ATTRIBUTE12
            ,l.ATTRIBUTE13 LINE_ATTRIBUTE13
            ,l.ATTRIBUTE14 LINE_ATTRIBUTE14
            ,l.ATTRIBUTE15 LINE_ATTRIBUTE15
            ,loc.ATTRIBUTE_CATEGORY SHIPMENT_ATTRIBUTE_CATEGORY
            ,loc.ATTRIBUTE1 SHIPMENT_ATTRIBUTE1
            ,loc.ATTRIBUTE2 SHIPMENT_ATTRIBUTE2
            ,loc.ATTRIBUTE3 SHIPMENT_ATTRIBUTE3
            ,loc.ATTRIBUTE4 SHIPMENT_ATTRIBUTE4
            ,loc.ATTRIBUTE5 SHIPMENT_ATTRIBUTE5
            ,loc.ATTRIBUTE6 SHIPMENT_ATTRIBUTE6
            ,loc.ATTRIBUTE7 SHIPMENT_ATTRIBUTE7
            ,loc.ATTRIBUTE8 SHIPMENT_ATTRIBUTE8
            ,loc.ATTRIBUTE9 SHIPMENT_ATTRIBUTE9
            ,loc.ATTRIBUTE10 SHIPMENT_ATTRIBUTE10
            ,loc.ATTRIBUTE11 SHIPMENT_ATTRIBUTE11
            ,loc.ATTRIBUTE12 SHIPMENT_ATTRIBUTE12
            ,loc.ATTRIBUTE13 SHIPMENT_ATTRIBUTE13
            ,loc.ATTRIBUTE14 SHIPMENT_ATTRIBUTE14
            ,loc.ATTRIBUTE15 SHIPMENT_ATTRIBUTE15
            ,loc.TAX_CODE_ID
            ,loc.NOTE_TO_RECEIVER
from po_lines_all l, po_line_locations_all loc  
where l.PO_HEADER_ID = :p_PO_HEADER_ID --!!!!parameter!!!
and l.po_header_id = loc.po_header_id;
    
header_val  po_header_cursor%ROWTYPE;



begin
    select PO_HEADERS_INTERFACE_S.nextval into interface_header_id from dual;
    open po_header_cursor;
    fetch po_header_cursor into header_val;    
    insert into po_headers_interface
    (INTERFACE_HEADER_ID
    ,BATCH_ID
    ,ACTION
    ,ORG_ID
    ,DOCUMENT_TYPE_CODE
    ,CURRENCY_CODE
    ,RATE_TYPE
    ,RATE_DATE
    ,RATE
    ,AGENT_ID
    ,VENDOR_ID
    ,VENDOR_SITE_ID
    ,VENDOR_CONTACT_ID
    ,SHIP_TO_LOCATION_ID
    ,BILL_TO_LOCATION_ID
    ,TERMS_ID
    ,FREIGHT_CARRIER
    ,FOB
    ,FREIGHT_TERMS
    ,APPROVAL_STATUS
    ,NOTE_TO_VENDOR
    ,NOTE_TO_RECEIVER
    ,CONFIRMING_ORDER_FLAG
    ,COMMENTS
    ,ACCEPTANCE_REQUIRED_FLAG
    ,ACCEPTANCE_DUE_DATE
    ,FIRM_FLAG
    ,VENDOR_DOC_NUM
    ,ATTRIBUTE_CATEGORY
    ,ATTRIBUTE1
    ,ATTRIBUTE2
    ,ATTRIBUTE3
    ,ATTRIBUTE4
    ,ATTRIBUTE5
    ,ATTRIBUTE6
    ,ATTRIBUTE7
    ,ATTRIBUTE8
    ,ATTRIBUTE9
    ,ATTRIBUTE10
    ,ATTRIBUTE11
    ,ATTRIBUTE12
    ,ATTRIBUTE13
    ,ATTRIBUTE14
    ,ATTRIBUTE15
    ,CREATION_DATE
    ,CREATED_BY
    ,REFERENCE_NUM)
    values
    (interface_header_id
    ,header_val.SEGMENT1
    ,'NEW'
    ,header_val.ORG_ID--PARAMETER!!!!CHANGE ME!!!
    ,'STANDARD'
    ,header_val.CURRENCY_CODE    
    ,header_val.RATE_TYPE
    ,header_val.RATE_DATE
    ,header_val.RATE
    ,header_val.AGENT_ID
    ,header_val.VENDOR_ID
    ,header_val.VENDOR_SITE_ID
    ,header_val.VENDOR_CONTACT_ID
    ,header_val.SHIP_TO_LOCATION_ID
    ,header_val.BILL_TO_LOCATION_ID
    ,header_val.TERMS_ID
    ,header_val.SHIP_VIA_LOOKUP_CODE
    ,header_val.FOB_LOOKUP_CODE
    ,header_val.FREIGHT_TERMS_LOOKUP_CODE
    ,'Incomplete' --!!!PARAMETER!!!
    ,header_val.NOTE_TO_VENDOR
    ,header_val.NOTE_TO_RECEIVER
    ,header_val.CONFIRMING_ORDER_FLAG
    ,'Comments here' --!!PARAMETER!!
    ,header_val.ACCEPTANCE_REQUIRED_FLAG
    ,header_val.ACCEPTANCE_DUE_DATE
    ,header_val.FIRM_STATUS_LOOKUP_CODE
    ,header_val.VENDOR_ORDER_NUM
    ,header_val.ATTRIBUTE_CATEGORY
    ,header_val.ATTRIBUTE1
    ,header_val.ATTRIBUTE2
    ,header_val.ATTRIBUTE3
    ,header_val.ATTRIBUTE4
    ,header_val.ATTRIBUTE5
    ,header_val.ATTRIBUTE6
    ,header_val.ATTRIBUTE7
    ,header_val.ATTRIBUTE8
    ,header_val.ATTRIBUTE9
    ,header_val.ATTRIBUTE10
    ,header_val.ATTRIBUTE11
    ,header_val.ATTRIBUTE12
    ,header_val.ATTRIBUTE13
    ,header_val.ATTRIBUTE14
    ,header_val.ATTRIBUTE15
    ,SYSDATE
    ,header_val.CREATED_BY --PARAMETER!!! CHANGETHIS
    ,header_val.REFERENCE_NUM);
    
    close po_header_cursor;
    
    for lines_val in po_lines_cursor
        loop
           --Need check to see if non-repl items should be included
           if :p_Inc_NON_REPL_ITEMS = 'N' then
           SELECT MCAT.SEGMENT7 into rtc
            FROM  
             MTL_ITEM_CATEGORIES I,
             MTL_CATEGORIES_B MCAT,
             MTL_CATEGORY_SETS S 
            WHERE 
           I.INVENTORY_ITEM_ID = lines_val.item_id
           AND I.ORGANIZATION_ID = 450
      --ship_TO_organization_id
            AND MCAT.CATEGORY_ID = I.CATEGORY_ID
            AND S.CATEGORY_SET_NAME = 'RMS Location Traits Attributes'
            AND S.STRUCTURE_ID = MCAT.STRUCTURE_ID;
           end if; 
            
            select PO_LINES_INTERFACE_S.nextval into interface_line_id from dual;
            select UOM_CODE into uom_code from MTL_UNITS_OF_MEASURE_TL where UNIT_OF_MEASURE = lines_val.UNIT_MEAS_LOOKUP_CODE;
            INSERT INTO PO_LINES_INTERFACE
            (INTERFACE_LINE_ID
            ,INTERFACE_HEADER_ID
            ,ACTION
            ,LINE_NUM
            ,SHIPMENT_NUM
            ,ITEM_ID
            ,VENDOR_PRODUCT_NUM
            ,UOM_CODE
            ,UNIT_OF_MEASURE
            ,QUANTITY
            ,UNIT_PRICE
            ,UN_NUMBER_ID
            ,HAZARD_CLASS_ID
            ,NOTE_TO_VENDOR
            ,TAXABLE_FLAG
            ,TAX_NAME
            ,INSPECTION_REQUIRED_FLAG
            ,RECEIPT_REQUIRED_FLAG
            ,INVOICE_CLOSE_TOLERANCE
            ,RECEIVE_CLOSE_TOLERANCE
            ,DAYS_EARLY_RECEIPT_ALLOWED
            ,DAYS_LATE_RECEIPT_ALLOWED
            ,ENFORCE_SHIP_TO_LOCATION_CODE
            ,ALLOW_SUBSTITUTE_RECEIPTS_FLAG
            ,RECEIVING_ROUTING_ID
            ,QTY_RCV_TOLERANCE
            ,QTY_RCV_EXCEPTION_CODE
            ,RECEIPT_DAYS_EXCEPTION_CODE
            ,SHIP_TO_ORGANIZATION_ID
            ,SHIP_TO_LOCATION_ID
            ,NEED_BY_DATE
            ,PROMISED_DATE
            ,ACCRUE_ON_RECEIPT_FLAG
           -- ,EXPIRATION_DATE
            ,LINE_ATTRIBUTE_CATEGORY_LINES
            ,LINE_ATTRIBUTE1
            ,LINE_ATTRIBUTE2
            ,LINE_ATTRIBUTE3
            ,LINE_ATTRIBUTE4
            ,LINE_ATTRIBUTE5
            ,LINE_ATTRIBUTE6
            ,LINE_ATTRIBUTE7
            ,LINE_ATTRIBUTE8
            ,LINE_ATTRIBUTE9
            ,LINE_ATTRIBUTE10
            ,LINE_ATTRIBUTE11
            ,LINE_ATTRIBUTE12
            ,LINE_ATTRIBUTE13
            ,LINE_ATTRIBUTE14
            ,LINE_ATTRIBUTE15
            ,SHIPMENT_ATTRIBUTE1
            ,SHIPMENT_ATTRIBUTE2
            ,SHIPMENT_ATTRIBUTE3
            ,SHIPMENT_ATTRIBUTE4
            ,SHIPMENT_ATTRIBUTE5
            ,SHIPMENT_ATTRIBUTE6
            ,SHIPMENT_ATTRIBUTE7
            ,SHIPMENT_ATTRIBUTE8
            ,SHIPMENT_ATTRIBUTE9
            ,SHIPMENT_ATTRIBUTE10
            ,SHIPMENT_ATTRIBUTE11
            ,SHIPMENT_ATTRIBUTE12
            ,SHIPMENT_ATTRIBUTE13
            ,SHIPMENT_ATTRIBUTE14
            ,SHIPMENT_ATTRIBUTE15
            ,CREATION_DATE
            ,CREATED_BY
            ,TAX_CODE_ID
            ,NOTE_TO_RECEIVER)
            VALUES
            (interface_line_id
            ,interface_header_id
            ,'NEW'
            ,lines_val.LINE_NUM
            ,lines_val.SHIPMENT_NUM
            ,lines_val.ITEM_ID
            ,lines_val.VENDOR_PRODUCT_NUM
            ,uom_code
            ,lines_val.UNIT_MEAS_LOOKUP_CODE
            ,lines_val.QUANTITY
            ,lines_val.UNIT_PRICE
            ,lines_val.UN_NUMBER_ID
            ,lines_val.HAZARD_CLASS_ID
            ,lines_val.NOTE_TO_VENDOR
            ,lines_val.TAXABLE_FLAG
            ,lines_val.TAX_NAME
            ,lines_val.INSPECTION_REQUIRED_FLAG
            ,lines_val.RECEIPT_REQUIRED_FLAG
            ,lines_val.INVOICE_CLOSE_TOLERANCE
            ,lines_val.RECEIVE_CLOSE_TOLERANCE
            ,lines_val.DAYS_EARLY_RECEIPT_ALLOWED
            ,lines_val.DAYS_LATE_RECEIPT_ALLOWED
            ,lines_val.ENFORCE_SHIP_TO_LOCATION_CODE
            ,lines_val.ALLOW_SUBSTITUTE_RECEIPTS_FLAG
            ,lines_val.RECEIVING_ROUTING_ID
            ,lines_val.QTY_RCV_TOLERANCE
            ,lines_val.QTY_RCV_EXCEPTION_CODE
            ,lines_val.RECEIPT_DAYS_EXCEPTION_CODE
            ,427--PARAMETER org_id!!!!
            ,427--SHIP_TO_LOCATION_ID  lookup parameter!!!
            ,lines_val.NEED_BY_DATE
            ,lines_val.PROMISED_DATE
            ,lines_val.ACCRUE_ON_RECEIPT_FLAG
          --  ,lines_val.EXPIRATION_DATE
            ,lines_val.LINE_ATTRIBUTE_CATEGORY
            ,lines_val.LINE_ATTRIBUTE1
            ,lines_val.LINE_ATTRIBUTE2
            ,lines_val.LINE_ATTRIBUTE3
            ,lines_val.LINE_ATTRIBUTE4
            ,lines_val.LINE_ATTRIBUTE5
            ,lines_val.LINE_ATTRIBUTE6
            ,lines_val.LINE_ATTRIBUTE7
            ,lines_val.LINE_ATTRIBUTE8
            ,lines_val.LINE_ATTRIBUTE9
            ,lines_val.LINE_ATTRIBUTE10
            ,lines_val.LINE_ATTRIBUTE11
            ,lines_val.LINE_ATTRIBUTE12
            ,lines_val.LINE_ATTRIBUTE13
            ,lines_val.LINE_ATTRIBUTE14
            ,lines_val.LINE_ATTRIBUTE15
            ,lines_val.SHIPMENT_ATTRIBUTE1
            ,lines_val.SHIPMENT_ATTRIBUTE2
            ,lines_val.SHIPMENT_ATTRIBUTE3
            ,lines_val.SHIPMENT_ATTRIBUTE4
            ,lines_val.SHIPMENT_ATTRIBUTE5
            ,lines_val.SHIPMENT_ATTRIBUTE6
            ,lines_val.SHIPMENT_ATTRIBUTE7
            ,lines_val.SHIPMENT_ATTRIBUTE8
            ,lines_val.SHIPMENT_ATTRIBUTE9
            ,lines_val.SHIPMENT_ATTRIBUTE10
            ,lines_val.SHIPMENT_ATTRIBUTE11
            ,lines_val.SHIPMENT_ATTRIBUTE12
            ,lines_val.SHIPMENT_ATTRIBUTE13
            ,lines_val.SHIPMENT_ATTRIBUTE14
            ,lines_val.SHIPMENT_ATTRIBUTE15
            ,SYSDATE
            ,123  --PARAMETER!!! CHANGETHIS created_by
            ,lines_val.TAX_CODE_ID
            ,lines_val.NOTE_TO_RECEIVER
            );
            
             for distributions_val in (SELECT * FROM PO_DISTRIBUTIONS_ALL)
             
                loop
                select PO_DISTRIBUTIONS_INTERFACE_S.nextval into interface_distribution_id from dual;
                INSERT INTO PO_DISTRIBUTIONS_INTERFACE
                    (INTERFACE_HEADER_ID
                    ,INTERFACE_LINE_ID
                    ,INTERFACE_DISTRIBUTION_ID
                    ,ORG_ID
                    ,QUANTITY_ORDERED
                    ,DELIVER_TO_LOCATION_ID
                    ,DELIVER_TO_PERSON_ID
                    ,DESTINATION_TYPE_CODE
                    ,DESTINATION_ORGANIZATION_ID
                    ,CHARGE_ACCOUNT_ID
                    ,ACCRUE_ON_RECEIPT_FLAG
                    ,ACCRUED_FLAG
                    ,CREATION_DATE
                    ,CREATED_BY) values
                    (INTERFACE_HEADER_ID
                    ,INTERFACE_LINE_ID
                    ,INTERFACE_DISTRIBUTION_ID
                    ,distributions_val.ORG_ID
                    ,distributions_val.QUANTITY_ORDERED
                    ,distributions_val.DELIVER_TO_LOCATION_ID
                    ,distributions_val.DELIVER_TO_PERSON_ID
                    ,distributions_val.DESTINATION_TYPE_CODE
                    ,distributions_val.DESTINATION_ORGANIZATION_ID --PARAMETER!!!
                    
                    ,1 --LOOKUP FIELD CHARGE_ACCOUNT_ID 
                    ,distributions_val.ACCRUE_ON_RECEIPT_FLAG
                    ,distributions_val.ACCRUED_FLAG
                    ,SYSDATE
                    ,distributions_val.CREATED_BY) ;--PARAMETER!!!
                    
                    
                    
             end loop;
            
           
           
            
        
        end loop;
    
end;

