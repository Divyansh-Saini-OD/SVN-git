SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_ONT_DELIVERY_TO_ROADNET_PKG
AS
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name   : XX_OM_DELIVERY_TO_ROADNET_PKG                                                  |
-- | Description      : Package Body containing procedure for DeliveryToRoadnet              |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   27-FEB-2007       Faiz Mohammad    Initial draft version                      |
-- |DRAFT 1B   24-MAY-2007       Sudharsana       Validating XML According                   |
-- |                                              to GetCarrierroute.xsd and formatted code  |
-- |                                              according to New MD040 Standards           |
-- |                                                                                         |
-- |DRAFT 1C   11-Jun-2007       Shashi Kumar     Altered the code to include the callto BPEL|
-- |                                              to GetCarrierroute.xsd and formatted code  |
-- |                                              according to New MD040 Standards.          |
-- |                                              Altered the XML that has been generated    |
-- |1.0        12-Jun-2007       Shashi Kumar     Baselined after testing.                   |
-- |                                                                                         |
-- +=========================================================================================+

gn_org_id           NUMBER := FND_GLOBAL.ORG_ID;
g_entity_ref        VARCHAR2(1000);
g_entity_ref_id     NUMBER;
g_error_description VARCHAR2(4000);
g_error_code        VARCHAR2(100);

PROCEDURE log_exceptions
  
AS

--Variables holding the values from the global exception framework package
--------------------------------------------------------------------------
x_errbuf                    VARCHAR2(1000);
x_retcode                   VARCHAR2(40);

BEGIN

   g_exception.p_error_code        := g_error_code;
   g_exception.p_error_description := g_error_description;
   g_exception.p_entity_ref        := g_entity_ref;
   g_exception.p_entity_ref_id     := g_entity_ref_id;

   BEGIN
       XX_OM_GLOBAL_EXCEPTION_PKG.insert_exception( g_exception
                                                   ,x_errbuf
                                                   ,x_retcode
                                                  );
   END; 

END log_exceptions;

-- +===================================================================+
-- | Name  : XX_OM_DELIVERY_TO_ROADNET                                 |
-- | Description:       This Procedure will be used to import the      |
-- |                    the deliveries to Roadnet                      |
-- |                                                                   |
-- +===================================================================+

PROCEDURE delivery_to_roadnet(p_delivery_id IN NUMBER, x_xml OUT NOCOPY XMLTYPE)

IS
  
    -- Varibles for the call to UTL_HTTP
   l_response             XMLTYPE;
   l_http_request         utl_http.req;
   l_http_response        utl_http.resp;
-- Need to Re-Visit
   lc_bpelproc_endpoint   VARCHAR2(200):= 'http://OSSI-0825:8888/orabpel/default/I1164_EBS_ROADNET_OUT/1.0';  -- BPEL end point 
   lc_bpelproc_wsdldoc    VARCHAR2(200):= 'http://ossi-0825:8888/orabpel/default/I1164_EBS_ROADNET_OUT/1.0/I1164_EBS_ROADNET_OUT?wsdl'; -- BPEL wsdl 
   lc_bpelproc_operation  VARCHAR2(200):= 'process'; -- default operation
   lc_soap_envelope       VARCHAR2(30000);
   lc_resp_back           VARCHAR2(30000);
   lc_rep_code            VARCHAR2(3) := -1;

   lc_region_id           VARCHAR2(20);
   lc_customer_id         VARCHAR2(20);
   lc_cust_type_ccd       VARCHAR2(20);
   ln_process_id          NUMBER;
   lc_error_code          VARCHAR2(10);
   lc_error_text          VARCHAR2(2000);
   ln_dlry_line_tot       NUMBER;
   lc_process_flag        VARCHAR2(10);
   lc_wholesale_flag      VARCHAR2(1);
   lc_returntypecd        VARCHAR2(10);
   lc_returntypedescr     VARCHAR2(20);
   lc_redeliveryind       VARCHAR2(20);
   lc_samedayind          VARCHAR2(1);
   lc_setpickup           VARCHAR2(5);
   lc_orig_sys_ref        VARCHAR2(30);
   lc_party_site_attr     VARCHAR2(30);
   lc_ship_to_cust_id     VARCHAR2(20);
   lc_cust_type_ccd_attr  VARCHAR2(20);
   lb_xml_structure       CLOB;
   lc_time_zone           VARCHAR2(20);
   lc_ordertypedescr      VARCHAR2(40);
   lc_selector            VARCHAR2(40);
   lc_order_lineid        NUMBER;
   lc_delivery_from       VARCHAR2(40);
   lc_delivery_to         VARCHAR2(40);
   lc_bulk_attr           VARCHAR2(40);
   lc_furniture_attr      VARCHAR2(40);
   lc_order_type          oe_order_headers_v.order_type%TYPE;
-- Need to Re-Visit
   lc_wholesaleind        oe_order_lines_all.attribute6%TYPE;--ATTRIBUTEXX
   
   g_excn                 EXCEPTION;

   --Delivery Details, Route ID,Gross Weight,earliest drop off date ,Service level,Number of lpn
   CURSOR lcu_delivery (p_del_id IN NUMBER)
   IS
   SELECT WND.delivery_id
         ,WND.name                              --Order Number
         ,WND.gross_weight                      --Gross Weight
         ,WND.ultimate_dropoff_date 
         --,WND.earliest_dropoff_date             --Earliest Drop Off Date
         ,WT.attribute1 route_id                -- Route id
         ,WT.attribute4 delivery_from_window    --Delivery from window
         ,WT.attribute5 delivery_to_window
         ,WND.attribute6 redelivery_flag        --redelivery_flag
         ,WND.service_level                     --Service level
         ,WND.number_of_lpn                     --Number of lpn
         ,WND.initial_pickup_location_id        --Initial pickup location id
         ,WND.ultimate_dropoff_location_id      --drop off location id
         ,WND.customer_id
         ,WND.organization_id
         ,WND.attribute6
   FROM   wsh_new_deliveries WND
         ,wsh_delivery_legs WDL
         ,wsh_trip_stops WTS
         ,wsh_trips WT
   WHERE  WND.delivery_id = WDL.delivery_id
   AND    WTS.stop_id     = WDL.pick_up_stop_id
   AND    WTS.trip_id     = WT.trip_id
   AND    WND.attribute1  = 'CARRIER_SELECTION_COMPLETED'
   AND    WT.attribute3   = 'Y'
   AND    WND.delivery_id = p_del_id
   ORDER BY WND.delivery_id;

   -- Furniture attribute--
   CURSOR lcu_furniture_attr (
                               p_inventory_item_id IN NUMBER
                              ,p_organization_id IN NUMBER
                              )IS
   SELECT MC.segment1
   FROM   mtl_categories MC,
          mtl_item_categories MIC,
          mtl_category_sets MCS
   WHERE  MIC.category_id=MC.category_id
   AND    MIC.category_set_id=MCS.category_set_id
   AND    MCS.category_set_name like 'ATP_CATEGORY'
   AND    MIC.inventory_item_id= p_inventory_item_id
   AND    MIC.organization_id  = p_organization_id;

   --Region Id--
   CURSOR lcu_region_id (
                         p_delivery_id   IN   NUMBER
                        ,p_organization_id IN NUMBER
                       )IS
   SELECT HAOU.attribute6 --attributexx
   FROM   hr_all_organization_units HAOU
        , wsh_new_deliveries WND
   WHERE HAOU.location_id = WND.initial_pickup_location_id
   AND   HAOU.organization_id = WND.organization_id
   AND   WND.delivery_id = p_delivery_id
   AND   HAOU.organization_id = p_organization_id;

   --Customer Id --
   CURSOR lcu_customer_id (
                           p_drop_off_location_id   IN   NUMBER
                          ,p_customer_id            IN   NUMBER
                          )IS
   SELECT HP.orig_system_reference
-- Need to Re-Visit
         ,HZP.attribute6  --attributexx
   FROM   hz_party_sites    HZP
         ,hz_parties        HP
         ,hz_cust_accounts  HCA
   WHERE HZP.location_id      = p_drop_off_location_id
   AND   HP.party_id          = HZP.party_id
   AND   HCA.party_id         = HP.party_id
   AND   HCA.cust_account_id  = p_customer_id;

      --to derive ODCustomertype
   CURSOR lcu_cust_type_ccd (
                             p_customer_id   IN   NUMBER
                            )IS
-- Need to Re-Visit
   SELECT HCA.attribute8 --attributexx
   FROM   hz_cust_accounts HCA
   WHERE  HCA.cust_account_id = p_customer_id;

   --SKU, SKU Description, SKU Quantity, Weight--
   CURSOR lcu_sku (
                   p_delivery_id   IN   NUMBER
                  )IS
   SELECT WND.NAME
         ,SUBSTR (
                  MSIB.segment1
                  || MSIB.segment2
                  || MSIB.segment3
                  || MSIB.segment4
                  || MSIB.segment5
                  || MSIB.segment6
                  || MSIB.segment7
                  || MSIB.segment8
                  || MSIB.segment9
                  || MSIB.segment10
                  || MSIB.segment11
                  || MSIB.segment12
                  || MSIB.segment13
                  || MSIB.segment14
                  || MSIB.segment15
                  ,1
                  ,32) sku
         ,MSIB.description
         ,MSIB.inventory_item_id
         ,MSIB.organization_id
-- Need to Re-Visit
         ,MSIB.attribute6  --Furniture attribute
         ,WDD.requested_quantity
         ,WDD.gross_weight
         ,WDD.unit_price
         ,NVL (WDD.requested_quantity,0)*
              NVL(apps.cst_cost_api.get_item_cost
                  (1,MSIB.inventory_item_id
                  ,MSIB.organization_id),0) delivery_lines_cogs
   FROM  wsh_delivery_details WDD
        ,wsh_delivery_assignments WDA
        ,wsh_new_deliveries WND
        ,mtl_system_items_b MSIB
   WHERE WDD.delivery_detail_id = WDA.delivery_detail_id
   AND   WDA.delivery_id = WND.delivery_id
   AND   WDD.inventory_item_id = MSIB.inventory_item_id
   AND   WDD.organization_id = MSIB.organization_id
   AND   WND.delivery_id = p_delivery_id;

   CURSOR lcu_line(p_delivery_id IN NUMBER)
   IS
   SELECT source_line_id 
   FROM   wsh_delivery_details wdd,
          wsh_delivery_assignments wda
   WHERE  wda.delivery_detail_id = wdd.delivery_detail_id
   AND    wda.delivery_id = p_delivery_id;

   --customer name,party_id
   CURSOR lcu_party(
                    p_cust_account_id IN NUMBER
                   )IS
   SELECT HP.party_name
         ,HP.party_id
         ,HCA.cust_account_id
   FROM   hz_parties       HP
         ,hz_cust_accounts HCA
   WHERE  HP.party_id         = HCA.party_id
   AND    HCA.cust_account_id = p_cust_account_id;

   -- customer address info
   CURSOR lcu_address(
                      p_party_id IN NUMBER,
                      p_ultimate_dropoff_location_id IN NUMBER
                     )IS
   SELECT  HL.address1 address_ln_1
      ,HL.address2
       || HL.address3
       || HL.address4 address_ln_2
      ,HL.address3
      ,HL.address4
      ,HL.city
      ,HL.state
      ,HL.postal_code
   FROM  hz_locations    HL
     ,hz_party_sites  HPS
   WHERE HPS.location_id      = HL.location_id
   AND HPS.party_id           = p_party_id
   AND HL.location_id         = p_ultimate_dropoff_location_id;

   -- phone_code, area_code--
   CURSOR lcu_phone(
                    p_party_id IN NUMBER
                   )IS
   SELECT HCP.phone_country_code
     ,HCP.phone_area_code
     ,(HCP.phone_country_code
      ||HCP.phone_area_code
      ||HCP.phone_number
      ||HCP.phone_extension) phone_number
     ,HCP.phone_extension
   FROM  hz_contact_points HCP
   WHERE HCP.owner_table_id        = p_party_id
   AND   HCP.primary_flag          = 'Y'
   AND   HCP.contact_point_type    = 'PHONE';

       ----sold_to_contact--
   CURSOR lcu_sold_to_contact(
                              p_party_id IN NUMBER
                             )IS
   SELECT HP.person_last_name ||
          DECODE(HP.person_first_name,
                NULL,
                NULL,
                ', ' ||
                HP.person_first_name)||
          DECODE(AL.meaning,
                NULL,
                NULL,
                ' '
                ||AL.meaning) Sold_To_Contact
          ,party_id
   FROM  hz_parties HP
        ,ar_lookups AL
   WHERE AL.lookup_code(+)     = HP.person_pre_name_adjunct
   AND   AL.lookup_type        = 'CONTACT_TITLE'
   AND   HP.party_id           = p_party_id;

      --To derive WholeSaleLineIndicator
   CURSOR lcu_wholesale_flag (
                              p_delivery_id   IN   NUMBER
                             )IS
   SELECT OOL.attribute6         --WholeSaleLineIndicator
         ,OOL.line_id            -- Order Line id
   FROM   oe_order_lines_all OOL
     ,wsh_delivery_details WDD
     ,wsh_delivery_assignments WDA
   WHERE  OOL.line_id             = WDD.source_line_id
   AND    WDD.delivery_detail_id  = WDA.delivery_detail_id
   AND    WDA.delivery_id         = p_delivery_id;

    -- To derive delivery from window and delivery to window
   CURSOR lcu_delivery_fromto(
                              p_line_id IN NUMBER
                             )IS
   SELECT KFF.segment9            -- Delivery From Window
         ,KFF.segment10           -- Delivery To Window
   FROM  oe_order_lines_all OOLA
        ,xx_om_lines_attributes_all KFF
        ,oe_order_lines_all_dfv DFV
        ,oe_order_headers_all OOHA
   WHERE KFF.combination_id = OOLA.attribute7
   AND   OOLA.rowid         = DFV.row_id
   AND   OOHA.header_id     = OOLA.header_id
   AND   OOLA.line_id       = p_line_id;

     -- To Derive bulk attribute
   CURSOR lcu_bulk_attr (
                         p_line_id IN NUMBER
                       )IS
   SELECT KFF.segment8            -- Bulk Attribute
   FROM  oe_order_lines_all OOLA
        ,xx_om_lines_attributes_all KFF
        ,oe_order_lines_all_dfv DFV
        ,oe_order_headers_all OOHA
   WHERE KFF.combination_id = OOLA.attribute6
   AND   OOLA.line_id       = p_line_id
   AND   OOLA.rowid         = DFV.row_id
   AND   OOHA.header_id     = OOLA.header_id;

        --To derive Ordertype
   CURSOR lcu_order_type (
                          p_delivery_id   IN   NUMBER
                         )IS
   SELECT OOHV.order_type         ---Ordertypecode
   FROM   oe_order_headers_v OOHV
         ,oe_order_lines_all OOL
         ,wsh_delivery_details WDD
         ,wsh_delivery_assignments WDA
   WHERE OOHV.header_id       = OOL.header_id
   AND   OOL.line_id             = WDD.source_line_id
   AND   WDD.delivery_detail_id  = WDA.delivery_detail_id
   AND   WDA.delivery_id         = p_delivery_id;

   -- To derive Returntypecd
   CURSOR lcu_returntypecd (
                            p_delivery_id   IN   NUMBER
                           )IS
   SELECT DECODE (
                  order_category_code
                 ,'RETURN'
                 ,'RT'
                 ,NULL)
   FROM   oe_order_lines_all OOL
         ,oe_order_headers_all OOH
         ,wsh_delivery_details WDD
         ,wsh_delivery_assignments WDA
   WHERE ool.line_id = wdd.source_line_id
   AND   WDD.delivery_detail_id = WDA.delivery_detail_id
   AND   OOH.header_id          = OOL.header_id
   AND   WDA.delivery_id        = p_delivery_id;

   lc_delivery_rec        lcu_delivery%ROWTYPE;
   lc_sold_to_contact     lcu_sold_to_contact%ROWTYPE;
   lc_sku_rec             lcu_sku%ROWTYPE;
   lc_party_rec           lcu_party%ROWTYPE;
   lc_address             lcu_address%ROWTYPE;
   lc_phone               lcu_phone%ROWTYPE;

   BEGIN

-- Need to Re-Visit
      -- Commented this code as the Profiles have to be created and    
/*    FND_PROFILE.Get('XX_ONT_DLVTORDNET_BPEL_EPT',lc_bpelproc_endpoint);
      FND_PROFILE.Get('XX_ONT_DLVTORDNET_BPEL_WSDL',lc_bpelproc_wsdldoc);
   
      IF lc_bpelproc_endpoint IS NULL 
         OR  lc_bpelproc_wsdldoc IS NULL THEN
         RAISE g_excn;
      ELSE   
 */   
          -- Get The LineID 
          OPEN lcu_line(p_delivery_id);
          FETCH lcu_line INTO lc_order_lineid;
          CLOSE lcu_line;

          --Delivery Header Data --
          OPEN lcu_delivery(p_delivery_id);
          FETCH lcu_delivery INTO lc_delivery_rec;
          CLOSE lcu_delivery;

          -- Open Region Id --
          OPEN lcu_region_id(
                 lc_delivery_rec.delivery_id
                ,lc_delivery_rec.organization_id);
          FETCH lcu_region_id INTO lc_region_id;
          CLOSE lcu_region_id;
          -- Open Customer_id--
          OPEN lcu_customer_id (
                lc_delivery_rec.ultimate_dropoff_location_id
               ,lc_delivery_rec.customer_id);
          FETCH lcu_customer_id INTO lc_orig_sys_ref, lc_party_site_attr;
          CLOSE lcu_customer_id;

          --Delivery Header Customer ID--
          lc_customer_id := lc_orig_sys_ref||lc_party_site_attr;
             --Ship_to Location Data--
          IF lc_party_site_attr is NULL THEN
             lc_ship_to_cust_id := lc_orig_sys_ref;
          END IF;

          -- Open cust_type_ccd--
          OPEN lcu_cust_type_ccd (
               lc_delivery_rec.customer_id);
          FETCH lcu_cust_type_ccd INTO lc_cust_type_ccd_attr;
          CLOSE lcu_cust_type_ccd;

          --Cust_type_ccd mapping--
          IF lc_cust_type_ccd_attr IN ('Contract', 'National', 'TAM') THEN
             lc_cust_type_ccd := 'C';
          ELSIF lc_cust_type_ccd_attr IN ('Direct', 'Other', 'Retail') THEN
             lc_cust_type_ccd := 'R';
          END IF;

          --open the cusor to fetch party_id,party_name
          OPEN lcu_party(lc_delivery_rec.customer_id);
          FETCH lcu_party INTO lc_party_rec;
          CLOSE lcu_party;

          --open the cursor to fetch address
          OPEN lcu_address(lc_party_rec.party_id,
                  lc_delivery_rec.ultimate_dropoff_location_id);
          FETCH lcu_address INTO lc_address;
          CLOSE lcu_address;

          --open the cursor to fetch phone information
          OPEN lcu_phone(lc_party_rec.party_id);
          FETCH lcu_phone INTO lc_phone;
          CLOSE lcu_phone;

          --open the curosr to fetch sold to
          OPEN lcu_sold_to_contact(lc_party_rec.party_id);
          FETCH lcu_sold_to_contact INTO lc_sold_to_contact;
          CLOSE lcu_sold_to_contact;

          ln_dlry_line_tot           := 0;

          -- Open the cursor for delivey lines total.
          OPEN lcu_sku (lc_delivery_rec.delivery_id);
          LOOP
             FETCH lcu_sku INTO lc_sku_rec;
             EXIT WHEN lcu_sku%NOTFOUND;
             ln_dlry_line_tot := ln_dlry_line_tot + lc_sku_rec.delivery_lines_cogs;
          END LOOP;
          CLOSE lcu_sku;

          -- Opening the cursor to check furniture attribute
          OPEN lcu_furniture_attr(
              lc_sku_rec.inventory_item_id
             ,lc_sku_rec.organization_id);
          FETCH lcu_furniture_attr INTO lc_furniture_attr;
          CLOSE lcu_furniture_attr;

          -- Checking for Furniture Attribute
          IF lc_furniture_attr <> 'FURNITURE' THEN
               lc_furniture_attr:='';
          END IF;

          --Opening Cursor lcu_wholesale_flag--
          OPEN lcu_wholesale_flag (lc_delivery_rec.delivery_id);
          FETCH lcu_wholesale_flag INTO lc_wholesaleind, lc_order_lineid;
          CLOSE lcu_wholesale_flag;

          -- Opening the cursor to fecth Delivery From Window and Delivery To Window
          OPEN lcu_delivery_fromto(lc_order_lineid);
          FETCH lcu_delivery_fromto INTO lc_delivery_from, lc_delivery_to;
          CLOSE lcu_delivery_fromto;

          -- Opening the cursor to fecth Bulk Attribute
          OPEN lcu_bulk_attr(lc_order_lineid);
          FETCH lcu_bulk_attr INTO lc_bulk_attr;
          CLOSE lcu_bulk_attr;

          -- Opening the cursor to fecth returntypecd
          OPEN lcu_returntypecd (lc_delivery_rec.delivery_id);
          FETCH lcu_returntypecd INTO lc_returntypecd;
          CLOSE lcu_returntypecd;

          -- Opening the cursor for order_type
          OPEN lcu_order_type (lc_delivery_rec.delivery_id);
          FETCH lcu_order_type INTO lc_order_type;
          CLOSE lcu_order_type;

          --To derive Wholesaleitem
          IF lc_wholesaleind= 'BACK-TO-BACK' THEN
             lc_wholesale_flag :='Y';
          ELSE
             lc_wholesale_flag :='N';
          END IF;

          --To derive OrdertypeDescr
          IF lc_order_type = 'RETURN ONLY' THEN
             lc_ordertypedescr :=  'Return - RO-E';
          ELSIF
             lc_order_type = 'RETURN - EXCHANGE' THEN
             lc_ordertypedescr :=   'Return - EX-E';
          ELSIF
             lc_order_type =  'RETURN - DELIVERY ONLY' THEN
             lc_ordertypedescr := 'Return - DO-E';
          ELSE
             lc_ordertypedescr := 'Regular -E';
          END IF;

          --TO derive Setpickup
          IF lc_order_type = 'RETURN ONLY' OR lc_order_type = 'RETURN - EXCHANGE' THEN
             lc_setpickup := 'TRUE';
          ELSE
             lc_setpickup := 'FALSE';
          END IF;

          -- To derive redeliveryind
          IF lc_delivery_rec.attribute6 = '<<REDELIVERY>>' THEN
             lc_redeliveryind  := 'Redelivery';
          ELSE
             lc_redeliveryind := NULL;
          END IF;

          -- To derive samedayind
          IF lc_delivery_rec.service_level = 'SAMEDAY' THEN
             lc_samedayind     := 'Y';
          ELSE
             lc_samedayind     := 'N';
          END IF;

          --Creating XML Structure for Header rec --
          BEGIN

             lb_xml_structure := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns0="http://www.openapplications.org/oagis/9">';
             lb_xml_structure := lb_xml_structure||'<soapenv:Body>';
             lb_xml_structure := lb_xml_structure||'<ns0:CarrierRoute xmlns="http://www.openapplications.org/oagis/9">';
             lb_xml_structure := lb_xml_structure||'<ns0:DocumentReference>';
             lb_xml_structure := lb_xml_structure||'<ns0:DocumentID>';
             lb_xml_structure := lb_xml_structure||'<ns0:ID>'||lc_delivery_rec.name||'</ns0:ID>';
             lb_xml_structure := lb_xml_structure||'</ns0:DocumentID>';
             lb_xml_structure := lb_xml_structure||'</ns0:DocumentReference>';
             lb_xml_structure := lb_xml_structure||'<ns0:RequiredDeliveryDateTime>'||TO_CHAR(lc_delivery_rec.ultimate_dropoff_date,'YYYY-MM-DD')||'</ns0:RequiredDeliveryDateTime>';
             lb_xml_structure := lb_xml_structure||'<ns0:GrossWeightMeasure unitCode="0">'||NVL(lc_delivery_rec.gross_weight, 0)||'</ns0:GrossWeightMeasure>';
             lb_xml_structure := lb_xml_structure||'<ns0:Party>';
             lb_xml_structure := lb_xml_structure||'<ns0:PartyIDs>';
             lb_xml_structure := lb_xml_structure||'<ns0:ID>'||lc_customer_id||'</ns0:ID>';
             lb_xml_structure := lb_xml_structure||'</ns0:PartyIDs>';
             lb_xml_structure := lb_xml_structure||'</ns0:Party>';
             lb_xml_structure := lb_xml_structure||'<ns0:RouteStop>';
             lb_xml_structure := lb_xml_structure||'<ns0:StopDetail>';
             lb_xml_structure := lb_xml_structure||'<ns0:ShipToParty>';
             lb_xml_structure := lb_xml_structure||'<ns0:Name>'||lc_party_rec.party_name||'</ns0:Name>';
             lb_xml_structure := lb_xml_structure||'<ns0:Location>';
             lb_xml_structure := lb_xml_structure||'<ns0:Address>';
             lb_xml_structure := lb_xml_structure||'<ns0:LineOne>'||lc_address.address_ln_1||'</ns0:LineOne>';
             lb_xml_structure := lb_xml_structure||'<ns0:LineTwo>'||NVL(lc_address.address_ln_2, '')||'</ns0:LineTwo>';
             lb_xml_structure := lb_xml_structure||'<ns0:LineThree>'||NVL(lc_address.address3, '')||'</ns0:LineThree>';
             lb_xml_structure := lb_xml_structure||'<ns0:LineFour>'||NVL(lc_address.address4, '')||'</ns0:LineFour>';
                --lb_xml_structure := lb_xml_structure||'<AddressLine>'||lc_address.address_ln_1||'</AddressLine>';
             lb_xml_structure := lb_xml_structure||'<ns0:CityName>'||lc_address.city||'</ns0:CityName>';
             lb_xml_structure := lb_xml_structure||'<ns0:CountrySubDivisionCode>'||lc_address.state||'</ns0:CountrySubDivisionCode>';
             lb_xml_structure := lb_xml_structure||'<ns0:PostalCode>'||lc_address.postal_code||'</ns0:PostalCode>';
             lb_xml_structure := lb_xml_structure||'</ns0:Address>';
             lb_xml_structure := lb_xml_structure||'</ns0:Location>';
             lb_xml_structure := lb_xml_structure||'<ns0:Contact>';
             lb_xml_structure := lb_xml_structure||'<ns0:Name>'||NVL(lc_sold_to_contact.sold_to_contact, '')||'</ns0:Name>';
             lb_xml_structure := lb_xml_structure||'</ns0:Contact>';
                --lb_xml_structure := lb_xml_structure||'<Name>'||lc_party_rec.party_name||'</Name>';
             lb_xml_structure := lb_xml_structure||'</ns0:ShipToParty>';
             lb_xml_structure := lb_xml_structure||'<ns0:Party>';
             lb_xml_structure := lb_xml_structure||'<ns0:Contact>';
             lb_xml_structure := lb_xml_structure||'<ns0:Communication>';
             lb_xml_structure := lb_xml_structure||'<ns0:CountryDialing>'||NVL(lc_phone.phone_country_code, 0)||'</ns0:CountryDialing>';
             lb_xml_structure := lb_xml_structure||'<ns0:AreaDialing>'||NVL(lc_phone.phone_area_code,0)||'</ns0:AreaDialing>';
             lb_xml_structure := lb_xml_structure||'<ns0:DialNumber>'||NVL(lc_phone.phone_number,0)||'</ns0:DialNumber>';
             lb_xml_structure := lb_xml_structure||'<ns0:Extension>'||NVL(lc_phone.phone_extension, 0)||'</ns0:Extension>';
             lb_xml_structure := lb_xml_structure||'<ns0:ContactPhoneNumber>'||NVL(lc_phone.phone_number,0)||'</ns0:ContactPhoneNumber>';
             lb_xml_structure := lb_xml_structure||'<ns0:UserArea/>';
             lb_xml_structure := lb_xml_structure||'</ns0:Communication>';
             lb_xml_structure := lb_xml_structure||'</ns0:Contact>';
             lb_xml_structure := lb_xml_structure||'</ns0:Party>';
             lb_xml_structure := lb_xml_structure||'<ns0:UserArea/>';

             OPEN lcu_sku (p_delivery_id);
                LOOP
                   FETCH lcu_sku INTO lc_sku_rec;
                   EXIT WHEN lcu_sku%NOTFOUND;
                   --Creating XML Structure for Header rec --
                   BEGIN

                    lb_xml_structure := lb_xml_structure||'<ns0:Item>'||lc_sku_rec.inventory_item_id||'</ns0:Item>';
                    lb_xml_structure := lb_xml_structure||'<ns0:ItemDesc>'||lc_sku_rec.description||'</ns0:ItemDesc>';
                    lb_xml_structure := lb_xml_structure||'<ns0:Quantity>'||lc_sku_rec.requested_quantity||'</ns0:Quantity>';
                    lb_xml_structure := lb_xml_structure||'<ns0:COGS>'||lc_sku_rec.delivery_lines_cogs||'</ns0:COGS>';
                    lb_xml_structure := lb_xml_structure||'<ns0:GrossWeightMeasure>'||NVL(lc_sku_rec.gross_weight, 0)||'</ns0:GrossWeightMeasure>';
                    lb_xml_structure := lb_xml_structure||'<ns0:FurnitureAttribute>'||NVL(lc_furniture_attr, ' ')||'</ns0:FurnitureAttribute>';
                    lb_xml_structure := lb_xml_structure||'<ns0:BulkAttribute>'||NVL(lc_bulk_attr, ' ')||'</ns0:BulkAttribute>';
                   END;
                 END LOOP;
             CLOSE lcu_sku;

             lb_xml_structure := lb_xml_structure||'</ns0:StopDetail>';
             lb_xml_structure := lb_xml_structure||'</ns0:RouteStop>';
             lb_xml_structure := lb_xml_structure||'<ns0:RegionID>'||NVL(lc_region_id, 0)||'</ns0:RegionID>';
             lb_xml_structure := lb_xml_structure||'<ns0:ODCustomerType>'||NVL(lc_cust_type_ccd_attr, '')||'</ns0:ODCustomerType>';
             lb_xml_structure := lb_xml_structure||'<ns0:Custtypecode>'||NVL(lc_cust_type_ccd, '')||'</ns0:Custtypecode>';
             lb_xml_structure := lb_xml_structure||'<ns0:LoadStatus>'||'L'||'</ns0:LoadStatus>';
             lb_xml_structure := lb_xml_structure||'<ns0:Selector>'||NVL(lc_selector, '')||'</ns0:Selector>';
             lb_xml_structure := lb_xml_structure||'<ns0:WholeSaleLineIndicator>'||NVL(lc_wholesaleind, '')||'</ns0:WholeSaleLineIndicator>';
             lb_xml_structure := lb_xml_structure||'<ns0:DeliveryFromWindow>'||NVL(lc_delivery_from,'')||'</ns0:DeliveryFromWindow>';
             lb_xml_structure := lb_xml_structure||'<ns0:DeliverToWindow>'||NVL(lc_delivery_to,'')||'</ns0:DeliverToWindow>';
             lb_xml_structure := lb_xml_structure||'<ns0:EstimatedCartons>'||NVL(lc_delivery_rec.number_of_lpn, 0)||'</ns0:EstimatedCartons>';
             lb_xml_structure := lb_xml_structure||'<ns0:COGS>'||ln_dlry_line_tot||'</ns0:COGS>';
             lb_xml_structure := lb_xml_structure||'<ns0:OrdertypeCode>'||NVL(lc_order_type, '')||'</ns0:OrdertypeCode>';
             lb_xml_structure := lb_xml_structure||'<ns0:OrdertypeDesc>'||NVL(lc_ordertypedescr, '')||'</ns0:OrdertypeDesc>';
             lb_xml_structure := lb_xml_structure||'<ns0:ServiceLevel>'||NVL(lc_delivery_rec.service_level, '')||'</ns0:ServiceLevel>';
             lb_xml_structure := lb_xml_structure||'<ns0:SamedayInd>'||NVL(lc_samedayind, '')||'</ns0:SamedayInd>';
             lb_xml_structure := lb_xml_structure||'<ns0:RedeliveryAttribute>'||NVL(lc_delivery_rec.attribute6, '')||'</ns0:RedeliveryAttribute>';
             lb_xml_structure := lb_xml_structure||'<ns0:RedeliveryInd>'||NVL(lc_redeliveryind, '')||'</ns0:RedeliveryInd>';
             lb_xml_structure := lb_xml_structure||'<ns0:ReturntypeCD>'||NVL(lc_returntypecd, '')||'</ns0:ReturntypeCD>';
             lb_xml_structure := lb_xml_structure||'<ns0:SetPickUp>'||NVL(lc_setpickup, '')||'</ns0:SetPickUp>';
             lb_xml_structure := lb_xml_structure||'</ns0:CarrierRoute>';
             lb_xml_structure := lb_xml_structure||'</soapenv:Body>';
             lb_xml_structure := lb_xml_structure||'</soapenv:Envelope>';

             INSERT INTO xmltest
             VALUES (lb_xml_structure); 
             x_xml := SYS.XMLTYPE.createXML(lb_xml_structure);

             COMMIT;

             IF x_xml IS NULL THEN

                lb_xml_structure :='<?xml version="1.0" encoding="UTF-8"?>';
                lb_xml_structure := lb_xml_structure||'<ns0:Error>XML structure cannot be built due to some unexpected error</ns0:Error>';
                x_xml := SYS.XMLTYPE.createXML(lb_xml_structure);

             END IF;

    /*      Commented this code as the MQ are not available in the system

            l_http_request   := utl_http.begin_request(lc_bpelproc_endpoint,'POST','HTTP/1.0');
            utl_http.set_persistent_conn_support(TRUE);

            utl_http.set_header(l_http_request, 'Content-Type', 'text/xml');
            utl_http.set_header(l_http_request, 'Content-Length', LENGTH(lc_soap_envelope));
            utl_http.set_header(l_http_request, 'SOAPAction', lc_bpelproc_operation);
            utl_http.write_text(l_http_request, lc_soap_envelope);
            l_http_response  := utl_http.get_response(l_http_request);

            utl_http.read_text(l_http_response, lc_soap_envelope);
            utl_http.end_response(l_http_response);

            l_response       := XMLTYPE.createxml(lc_soap_envelope);
            l_response       := l_response.EXTRACT('/soap:Envelope/soap:Body/client:DeliveryToRoadnetProcessResponse/client:result', 'xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:client="http://xmlns.oracle.com/I1164_EBS_ROADNET_OUT');
            lc_resp_back     := l_response.getstringval();
            lc_rep_code      := substr(lc_resp_back, instr(lc_resp_back, '>')+1, 1);

    */       
          IF lc_rep_code = 0 THEN

             UPDATE wsh_new_deliveries 
             SET    attribute1  = 'ROADNET_IMPORT_STARTED'
             WHERE  delivery_id = p_delivery_id;

          ELSE 

             UPDATE wsh_new_deliveries
             SET    attribute1 = 'ROADNET_IMPORT_FAILED'
             WHERE  delivery_id = p_delivery_id;

          END IF;

          COMMIT;

       EXCEPTION
          WHEN OTHERS THEN

             lb_xml_structure :='<?xml version="1.0" encoding="UTF-8"?>';
             lb_xml_structure := lb_xml_structure||'<Error>'||sqlerrm||'</Error>';
             x_xml := SYS.XMLTYPE.createXML(lb_xml_structure);

             g_entity_ref        := 'Unexpected Error in calling xx_om_delivery_to_roadnet procedure ';
             g_entity_ref_id     := 0;

             FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
             FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
             FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

             g_error_description:= FND_MESSAGE.GET;
             g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

             log_exceptions;    

       END;

  --  END IF;   

EXCEPTION
   WHEN g_excn THEN
   
      lb_xml_structure :='<?xml version="1.0" encoding="UTF-8"?>';
      lb_xml_structure := lb_xml_structure||'<Error>'||sqlerrm||'</Error>';
      x_xml := SYS.XMLTYPE.createXML(lb_xml_structure);

      g_entity_ref        := 'Unexpected Error Profile option BPEL Endpoint is not defined or BPEL wsdl location is not defined' ;
      g_entity_ref_id     := 0;
 
      FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      g_error_description:= FND_MESSAGE.GET;
      g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

      log_exceptions;   

   WHEN OTHERS THEN
         
      lb_xml_structure :='<?xml version="1.0" encoding="UTF-8"?>';
      lb_xml_structure := lb_xml_structure||'<Error>'||sqlerrm||'</Error>';
      x_xml := SYS.XMLTYPE.createXML(lb_xml_structure);

      g_entity_ref        := 'Unexpected Error in calling xx_om_delivery_to_roadnet procedure ';
      g_entity_ref_id     := 0;
 
      FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      g_error_description:= FND_MESSAGE.GET;
      g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');

      log_exceptions;    

END delivery_to_roadnet;

END XX_ONT_DELIVERY_TO_ROADNET_PKG;
/
SHOW ERRORS;
EXIT;