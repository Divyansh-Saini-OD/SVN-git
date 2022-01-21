REM $Header: XXPORCVDSC.sql $ 
REM dbdrv: none
SET DOC OFF
-- +============================================================================+
-- |                  Office Depot - Project Simplify                  		|
-- |           Oracle NAIO/WIPRO/Office Depot/Consulting Organization 		|      
-- +============================================================================|		
-- | FILENAME 									|
-- |    XXPORCVDSC.sql 								|       
-- | Description:                                                     		|
-- |  	This sqlplus script produces the OD: PO ASN discrepant receipt report 	|
-- |										|
-- |										|                                                                
-- | PARAMETERS    								|
-- |       Start_Date 								|
-- |       end_Date 								|
-- |       PO_Type								|
-- |       									|
-- |  										|    
-- |Change Record:                                                     		|
-- |===============                                                    		|
-- |Version   Date        Author           Remarks                     		|
-- |=======   ==========  =============    ============================		|
-- |1.0      19-Apr-2007  Tharageswari     Seeded pl/sql report RCVDSC.sql  	|
-- |					   has been modified to add PO Type 	|
-- |					   parameter per R0278 requirement	|				
-- |										|
-- |										|
-- +============================================================================+

-- set serveroutput on; 

-- execute fnd_client_info.set_org_context ('129');

 
DECLARE 
  CURSOR x_Shipment IS 
    SELECT shipment_header_id, shipment_num, receipt_num, 
 	   shipped_date, expected_receipt_date, 
	   asn_type, asn_status, vendor_id, vendor_site_id
    FROM   rcv_shipment_headers 
    WHERE   (NVL(asn_type, 'a') IN ('ASN','ASBN'))
            AND (NVL(asn_status,'a') <> 'CANCELLED')
     AND    ship_to_org_id in (select hoi.organization_id 
                               from hr_organization_information hoi,
            financials_system_parameters fsp 
                               where hoi.org_information3 = to_char(fsp.org_id)) ;
                                                          
 
  TYPE t_ShipmentLine IS REF CURSOR; 
 
  x_ShipLine t_ShipmentLine; 
  
  x_Line_ShipLineID       NUMBER; 
  x_Line_ShipHeadID       NUMBER; 
  x_Line_QtyShip          NUMBER; 
  x_Line_QtyRcvd          NUMBER; 
  x_Line_UOM              VARCHAR2(25); 
  x_Line_LineLocID        NUMBER; 
  x_Line_ItemID           NUMBER; 
  x_Trans_SumRtn          NUMBER:= 0; -- total quantity
  x_Trans_PrimUOM	  VARCHAR2(25); 
  x_PO_NeedByDate         DATE; 
  x_PO_PromisedDate       DATE; 
  x_PO_Days_Late          NUMBER;   
  x_Vendor_Num            VARCHAR2(30);
  x_Vendor_Name           VARCHAR2(80);
  x_Vendor_Site_Code      VARCHAR2(15);
  x_Dum_Flag              VARCHAR2(5) := 'Y';
  x_IsDiscrepant          BOOLEAN := FALSE; 
  x_Interface_Header      RCV_Shipment_Header_SV.HeaderRecType; 
  x_start                 DATE;
  x_end                   DATE;
  x_dum                   DATE;
  x_PO_type               VARCHAR2(30); 

 
BEGIN 

  -- DBMS_OUTPUT.ENABLE (100000); 

  x_start := fnd_date.canonical_to_date('&1');

   --dbms_output.put_line('Start Date : ' || x_start);
  x_end := nvl(fnd_date.canonical_to_date('&2'),SYSDATE);

   --dbms_output.put_line('End Date : ' || x_end);

  x_PO_type:= '&3';

 
  FOR x_Head_Data IN x_Shipment LOOP 
 
     x_IsDiscrepant := FALSE;
      --dbms_output.put_line('ASN_TYPE ' || x_Head_Data.asn_type); 
      --dbms_output.put_line('Shipment_header_id ' || x_Head_Data.shipment_header_id); 


--Added Parameter x_PO_type to Ref Cursor

--     OPEN x_ShipLine FOR 
--     SELECT shipment_line_id, shipment_header_id, quantity_shipped,  
--	      quantity_received, unit_of_measure, item_id, po_line_location_id 
--       FROM   rcv_shipment_lines 
--     WHERE shipment_header_id = x_Head_Data.shipment_header_id 
--             AND NVL(shipment_line_status_code, 'a') <> 'CANCELLED';

     OPEN x_ShipLine FOR 
       SELECT shipment_line_id, shipment_header_id, quantity_shipped,  
	      quantity_received, unit_of_measure, item_id, po_line_location_id 
       FROM   rcv_shipment_lines  rsl,
      po_headers_all poh 
     WHERE   shipment_header_id = x_Head_Data.shipment_header_id
      AND    rsl.po_header_id = poh.po_header_id
      AND    poh.attribute_category = x_PO_type
      AND NVL(shipment_line_status_code, 'a') <> 'CANCELLED';
 
 --End of Changes

     LOOP 
       FETCH x_ShipLine INTO x_Line_ShipLineID, x_Line_ShipHeadID, x_Line_QtyShip,  
             x_Line_QtyRcvd, x_Line_UOM, x_Line_ItemID,x_Line_LineLocID; 
 
       EXIT WHEN x_ShipLine%NOTFOUND; 
 
        --dbms_output.put_line('shipment_line_id ' || x_Line_ShipLineId); 
        --dbms_output.put_line('Qty received ' || x_Line_QtyRcvd); 
        --dbms_output.put_line('Qty shipped ' || x_Line_QtyShip); 
 
       SELECT NVL(SUM(primary_quantity),0) 
       INTO   x_Trans_SumRtn 
       FROM   rcv_transactions 
       WHERE  NVL(transaction_type, 'dum') = 'RETURN TO VENDOR' 
	      AND shipment_line_id = x_Line_ShipLineID; 
 
        
        --dbms_output.put_line('x_trans_sumrtn ' || x_Trans_SumRtn); 
 
       SELECT NVL(MAX(primary_unit_of_measure),x_Line_UOM) 
       INTO   x_Trans_PrimUOM 
       FROM   rcv_transactions 
       WHERE  NVL(transaction_type, 'dum') = 'RETURN TO VENDOR' 
	      AND shipment_line_id = x_Line_ShipLineID; 
 
        --dbms_output.put_line('X_Line_LineLocID ' || x_Line_LineLocID); 

       SELECT MAX(need_by_date), MAX(promised_date), MAX(days_late_receipt_allowed) 
       INTO   x_PO_NeedByDate, x_PO_PromisedDate, x_PO_Days_Late 
       FROM   PO_LINE_LOCATIONS 
       WHERE  line_location_id = x_Line_LineLocID; 

--dbms_output.put_line ('expected receipt date ' || 	 x_Head_Data.expected_receipt_date);
        --dbms_output.put_line ('promised date ' || x_PO_PromisedDate);
        --dbms_output.put_line('need by date ' ||  x_PO_NeedByDate);

       
       x_dum := TRUNC(NVL(x_Head_Data.expected_receipt_date, 
                      NVL(x_PO_PromisedDate + NVL(x_PO_Days_Late, 0), 
                      NVL(x_PO_NeedByDate, TRUNC(SYSDATE)))));  

       IF TRUNC(NVL(x_Head_Data.expected_receipt_date, 
                NVL(x_PO_PromisedDate + NVL(x_PO_Days_Late, 0), 
                    NVL(x_PO_NeedByDate, TRUNC(SYSDATE))) 
                )) BETWEEN TRUNC (x_start) AND TRUNC(x_end)   
	    THEN   
 
	 IF(x_Trans_PrimUOM <> x_Line_UOM) THEN 
 
            --dbms_output.put_line('primary UOM' || x_Trans_PrimUOM); 
            --dbms_output.put_line('Line UOM' || x_Line_UOM); 



           PO_UOM_S.UOM_CONVERT(x_Trans_SumRtn, x_Trans_PrimUOM,  
                                x_Line_ItemID,  x_Line_UOM, x_Trans_SumRtn); 
 
           x_Trans_SumRtn := ROUND(x_Trans_SumRtn, 6); 
 
            --dbms_output.put_line ('After convert x_Trans_SumRtn is ' ||   TO_CHAR (x_Trans_SumRtn)); 
 
         END IF; 
 
         IF ((x_Trans_SumRtn + x_Line_QtyRcvd) <> x_Line_QtyShip) THEN 
            --dbms_output.put_line ('Shipment_line_id ' || TO_CHAR (x_Line_ShipLineID) || ' Not Equal!'); 

           x_IsDiscrepant:= TRUE;
delete from po_interface_errors where interface_header_id =   x_Line_ShipHeadID;

           po_interface_errors_sv1.handle_interface_errors( 
                                            'RCV-856', 
                                            'WARNING', 
                                            0, -- dummy value since it has no batch no. 
                                            x_Line_ShipHeadID, 
                                            x_Line_ShipLineID, 
                                            'RCV_ASN_DISCREPANT_SHIPMENT', 
                                            'RCV_SHIPMENT_LINES', 
                                            'QUANTITY_RECEIVED', 
                                            'QTY_SHIPPED',       -- First token 
                                            'QTY_RCVD',          -- Second token 
                                            NULL,NULL,NULL,NULL, 
                                            TO_CHAR(x_Line_QtyShip), 
                                            TO_CHAR(x_Line_QtyRcvd), 
                                            NULL,NULL,NULL,NULL, 
                                            x_Dum_Flag); 

	 END IF; 
       END IF; 
  
    END LOOP; 
 
    CLOSE x_ShipLine; 


    IF x_IsDiscrepant THEN

      SELECT vendor_name, segment1
      INTO   x_Vendor_Name, x_Vendor_Num
      FROM   po_vendors
      WHERE  vendor_id = x_Head_Data.vendor_id;
  
       --dbms_output.put_line ('Vendor Name ' || x_Vendor_Name);
       --dbms_output.put_line ('Vendor Num ' || x_Vendor_Num);

       --dbms_output.put_line ('Vendor Site ID ' || x_Head_Data.vendor_site_id);

      IF (x_Head_Data.vendor_site_id IS NOT NULL) THEN
        SELECT vendor_site_code
        INTO   x_Vendor_Site_Code
        FROM   po_vendor_sites
        WHERE  vendor_site_id = x_Head_Data.vendor_site_id;
      END IF;

      x_Interface_Header.header_record.header_interface_id    :=  x_Line_ShipHeadID; 
      x_Interface_Header.header_record.vendor_num             :=  x_Vendor_Num; 
      x_Interface_Header.header_record.vendor_name            :=  x_Vendor_Name; 
      x_Interface_Header.header_record.transaction_type       := 'RECEIVE';  
      x_Interface_Header.header_record.shipment_num           :=  
      x_Head_Data.shipment_num; 
      x_Interface_Header.header_record.vendor_site_code       := x_Vendor_Site_Code; 
      x_Interface_Header.header_record.invoice_num            :=  NULL; 
      x_Interface_Header.header_record.processing_status_code:= 'COMPLETED'; 
x_Interface_Header.header_record.vendor_site_id         :=             x_Head_Data.vendor_site_id; 
   
-- dbms_output.put_line(x_Line_ShipHeadID || ' ' || x_Vendor_Num || ' ' || x_Vendor_Name || 
--                           ' ' || x_Head_Data.shipment_num || ' ' || x_Vendor_Site_Code || 
--                           ' ' ||  x_Head_Data.vendor_site_id);
  
      rcv_824_sv.rcv_824_insert(x_Interface_Header,'DISCREPANT_SHIPMENT'); 

    END IF;

  END LOOP; 

END; 
/ 

exit;

