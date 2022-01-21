SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW XX_OM_DPSLINES_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        WIPRO Technologies                         |
-- +===================================================================+
-- | Name  :    XX_OM_DPSLINES_V                                       |
-- | Rice Id : I1148                                                   |
-- | Description      : This View is used to fetch Sales order         |
-- |                    information along with other required columns  |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0      05-MAR-2007  Aravind A        Initial draft version       |
-- |1.1      27-JUL-2007  Aravind A        Modified code to reflect    |                                                               
-- |                                       new attribute structure     |                                                              
-- +===================================================================+
AS
SELECT OOLA.line_id 
         ,'RosettaNet' glbadminauthoritycode 
         ,'V02.00' versionidentifier 
         ,'Yes' affirmationindicator 
         ,TO_CHAR (SYSDATE, 'yyyy.MM.dd hh:mi:ss:ssss') datetimestamp 
         ,'OD to '||XOLAA.vendor_site_id||' transact' freeformtext_recv
         ,XOLAA.vendor_site_id glblbizidentifier_recv
         ,NULL value_recv 
         ,'08:6123410000-GSODEP001' glblbizidentifier_send 
         ,NULL freeformtext_send 
         ,NULL value_send 
         ,NULL instanceidentifier_msg 
         ,NULL glbusagecode 
         ,NULL businessactivityidentifier 
         ,NULL glbpartroleclasscode 
         ,XOLAA.vendor_site_id glbbusinessservicecode 
         ,NULL glbmimetypequalcode 
         ,NULL universalresourceidentifier 
         ,NULL freeformtext 
         ,NULL countableamount 
         ,NULL glbbizactioncode 
         ,NULL glbpartroleclasscodeto 
         ,NULL glbbizservcodeto 
         ,NULL glbproindcode_pip 
         ,NULL instanceidentifier_pip 
         ,NULL versionidentifier_pip 
         ,NULL glblbizidentifier_sh 
         ,NULL freeformtext_sh 
         ,NULL value_sh 
         ,OOHA.order_number order_number 
         , (SELECT COUNT (DISTINCT xOOLA3.ext_top_model_line_id) 
              FROM oe_order_lines_all OOLA2 
                  ,xx_om_line_attributes_all xOOLA3 
                  ,fnd_lookup_values FLV 
             WHERE OOLA2.line_id =  xOOLA3.line_id 
               AND OOLA2.header_id = OOLA.header_id 
               AND xOOLA3.line_type = FLV.meaning 
               AND FLV.lookup_type = 'XX_OM_LINE_TYPES' 
               AND FLV.lookup_code = 'DPS' 
               AND FLV.language = 'US') totalbundlecount 
         ,NULL order_identifier 
         ,OOHA.ordered_date 
         ,OOSA.NAME channel 
         ,OOHA.transactional_curr_code 
         ,NULL cust_po_number 
         ,NULL description 
         ,OOHA.payment_type_code 
         ,NULL gift 
         ,NULL deliverycharge 
         , (SELECT SUM (NVL (unit_selling_price, 0) 
                        * NVL (ordered_quantity, 0)) 
              FROM oe_order_lines_all OOLA1 
                  ,xx_om_line_attributes_all XOLAA2 
             WHERE OOLA1.line_id = XOLAA2.line_id
               AND XOLAA2.ext_top_model_line_id = XOLAA.ext_top_model_line_id) totalprice 
         ,NULL taxes 
         ,OOLA.schedule_ship_date estimatedshipdate 
         ,NULL adjusmentamount 
         ,NULL adjustmentreason 
         ,NULL notessummary_hed 
         ,NULL notesdetails_hed 
         ,'AssociateID' key 
         ,OOSA.name value 
         ,'InvLocation' key1 
         ,OOD.organization_name value1 
         ,'Delivery Type' key2 
         ,decode(WCS.ship_method_meaning,'PICKUP','P','D') value2 
         ,NULL shiptoid 
         ,NULL shiptorep 
         ,NULL shiptocontactname 
         ,NULL ship_to_country 
         ,NULL ship_to_address1 
         ,NULL ship_to_address2 
         ,NULL ship_to_address3 
         ,NULL ship_to_address4 
         ,NULL ship_to_city 
         ,NULL ship_to_county 
         ,NULL ship_to_state 
         ,NULL ship_to_postal_code 
         ,NULL ship_to_fax 
         ,NULL ship_to_email_address 
         ,NULL ship_to_phone_number 
         ,NULL billtoid 
         ,NULL billtorep 
         ,NULL billtocontactname 
         ,NULL bill_to_country 
         ,NULL bill_to_address1 
         ,NULL bill_to_address2 
         ,NULL bill_to_address3 
         ,NULL bill_to_address4 
         ,NULL bill_to_city 
         ,NULL bill_to_county 
         ,NULL bill_to_state 
         ,NULL bill_to_postal_code 
         ,NULL bill_to_fax 
         ,NULL bill_to_email_address 
         ,NULL bill_to_phone_number 
         ,NULL soldtoid 
         ,NULL soldtorep 
         ,NULL soldtocontactname 
         ,NULL sold_to_country 
         ,NULL sold_to_address1 
         ,NULL sold_to_address2 
         ,NULL sold_to_address3 
         ,NULL sold_to_address4 
         ,NULL sold_to_city 
         ,NULL sold_to_county 
         ,NULL sold_to_state 
         ,NULL sold_to_postal_code 
         ,NULL sold_to_fax 
         ,NULL sold_to_email_address 
         ,NULL sold_to_phone_address 
         ,OOLA.line_id line_number 
         ,XOLAA.ext_top_model_line_id parent_line_id 
         ,OOLA.ordered_item product_id 
         ,OOLA.order_quantity_uom unitofmeasure 
         , NVL (OOLA.unit_selling_price, 0) * NVL (OOLA.ordered_quantity, 0) salesprice 
         ,XOLAA.vendor_config_id configurationcode 
         ,OOLA.ordered_quantity 
         ,NULL promotioncode 
         ,OOHA.transactional_curr_code line_curr_code 
         ,NULL notessummary_line 
         ,NULL notesdetails_line 
         ,OOHA.order_source_id source_id 
         ,NULL hold_name 
         ,XOLAA.trans_line_status line_status 
         ,XOLAA.line_type line_type 
         ,OOLA.header_id 
     FROM oe_order_sources OOSA 
         ,wsh_carrier_services_v WCS
         ,xx_om_line_attributes_all XOLAA          
         ,oe_order_headers_all OOHA 
         ,oe_order_lines_all OOLA           
         ,fnd_lookup_values FLV 
         ,org_organization_definitions OOD 
    WHERE OOLA.header_id = OOHA.header_id 
      AND XOLAA.line_id = OOLA.line_id             
      AND OOLA.shipping_method_code=WCS.ship_method_code(+)       
      AND XOLAA.line_type = FLV.meaning 
      AND FLV.lookup_type = 'XX_OM_LINE_TYPES' 
      AND FLV.lookup_code = 'DPS' 
      AND FLV.language = USERENV('LANG')
      AND OOD.ORGANIZATION_ID(+)=NVL(OOLA.ship_from_org_id ,0)
      AND OOHA.order_source_id = OOSA.order_source_id

/
SHOW ERROR
