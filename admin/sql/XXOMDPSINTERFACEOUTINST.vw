SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW xx_om_dpslines_v
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        WIPRO Technologies                         |
-- +===================================================================+
-- | Name  :    XX_OM_DPSLINES_V                                       |
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
-- |DRAFT 1A 05-MAR-2007  Aravind A        Initial draft version       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
AS
SELECT oola.line_id
         ,'RosettaNet' glbadminauthoritycode
         ,'V02.00' versionidentifier
         ,'Yes' affirmationindicator
         ,TO_CHAR (SYSDATE, 'yyyy.MM.dd hh:mi:ss:ssss') datetimestamp
         ,'OD to '||xolaa1.segment4||' transact'  glblbizidentifier_recv
         ,xolaa1.segment4 freeformtext_recv
         ,NULL value_recv
         ,'08:6123410000-GSODEP001' glblbizidentifier_send
         ,NULL freeformtext_send
         ,NULL value_send
         ,NULL instanceidentifier_msg
         ,NULL glbusagecode
         ,NULL businessactivityidentifier
         ,NULL glbpartroleclasscode
         ,xolaa1.segment4 glbbusinessservicecode
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
         ,ooha.order_number order_number
         , (SELECT COUNT (DISTINCT xoola3.segment14)
              FROM oe_order_lines_all oola2
                  ,xx_om_lines_attributes_all xoola3
                  ,fnd_lookup_values flv
             WHERE oola2.attribute6 = TO_CHAR (xoola3.combination_id)
               AND oola2.header_id = oola.header_id
               AND xoola3.segment7 = flv.meaning
               AND flv.lookup_type = 'XX_OM_LINE_TYPES'
               AND flv.lookup_code = 'DPS'
               AND flv.language = 'US') totalbundlecount
         ,NULL order_identifier
         ,ooha.ordered_date
         ,oosa.NAME channel
         ,ooha.transactional_curr_code
         ,NULL cust_po_number
         ,NULL description
         ,ooha.payment_type_code
         ,NULL gift
         ,NULL deliverycharge
         , (SELECT SUM (NVL (unit_selling_price, 0)
                        * NVL (ordered_quantity, 0))
              FROM oe_order_lines_all oola1
                  ,xx_om_lines_attributes_all xolaa2
             WHERE oola1.attribute6 = TO_CHAR (xolaa2.combination_id)
               AND xolaa2.segment14 = xolaa.segment14) totalprice
         ,NULL taxes
         ,oola.schedule_ship_date estimatedshipdate
         ,NULL adjusmentamount
         ,NULL adjustmentreason
         ,NULL notessummary_hed
         ,NULL notesdetails_hed
         ,'AssociateID' key
         ,oosa.name value
         ,'InvLocation' key1
         ,ood.organization_name value1
         ,'Delivery Type' key2
         ,decode(oola.shipping_method_code,'PICKUP','P','D') value2
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
         ,oola.line_id line_number
         ,xolaa.segment14 parent_line_id
         ,oola.ordered_item product_id
         ,oola.order_quantity_uom unitofmeasure
         , NVL (unit_selling_price, 0) * NVL (ordered_quantity, 0) salesprice
         ,xolaa1.segment3 configurationcode
         ,oola.ordered_quantity
         ,NULL promotioncode
         ,ooha.transactional_curr_code line_curr_code
         ,NULL notessummary_line
         ,NULL notesdetails_line
         ,ooha.order_source_id source_id
         ,NULL hold_name
         ,xolaa.segment10 line_status
         ,xolaa.segment7 line_type
         ,oola.header_id
     FROM oe_order_sources oosa
         ,xx_om_lines_attributes_all xolaa
         ,xx_om_lines_attributes_all xolaa1
         ,oe_order_headers_all ooha
         ,oe_order_lines_all oola
         ,fnd_lookup_values flv
         ,org_organization_definitions ood
     WHERE oola.header_id = ooha.header_id
      AND oola.attribute6 = TO_CHAR (xolaa.combination_id)
      AND oola.attribute7 = TO_CHAR (xolaa1.combination_id)
      AND xolaa.segment7 = flv.meaning
      AND flv.lookup_type = 'XX_OM_LINE_TYPES'
      AND flv.lookup_code = 'DPS'
      AND flv.language = 'US'
      AND ood.ORGANIZATION_ID=oola.ship_from_org_id
      AND ooha.order_source_id = oosa.order_source_id

/
SHOW ERROR

