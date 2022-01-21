SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_om_delivery_to_roadnet_pkg
AS
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name   : XX_OM_DELIVERY_TO_ROADNET_PKG                                                  |
-- | RICE ID: I1164_DeliveryToRoadNet                                                        |
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
-- |1.1        22-Jun-2007       Sudharsana       Alter the package/procudure name           |
-- |                                              Modified Global Exception part             |
-- |1.2        03-Jul-2007       Sudharsana       Added Load Status, Selector                |
-- |1.3        24-Jul-2007       Vidhya Valantina Changes due to KFF-DFF Setup               |
-- +=========================================================================================+


-- +===================================================================+
-- | Name  : log_exceptions                                            |
-- | Description : Procedure to log exceptions from this package using |
-- |               the Common Exception Handling Framework             |
-- |                                                                   |
-- | Parameters :       Error_Code                                     |
-- |                    Error_Description                              |
-- |                    Entity_Reference_Id                            |
-- |                                                                   |
-- +===================================================================+

PROCEDURE log_exceptions ( p_error_code        IN  VARCHAR2
                          ,p_error_description IN  VARCHAR2
                          ,p_entity_ref_id     IN  NUMBER
                         )

AS

--Variables holding the values from the global exception framework package
--------------------------------------------------------------------------
x_errbuf                    VARCHAR2(1000);
x_retcode                   VARCHAR2(40);

BEGIN

   g_exception.p_error_code        := p_error_code;
   g_exception.p_error_description := p_error_description;
   g_exception.p_entity_ref_id     := p_entity_ref_id;

   XX_OM_GLOBAL_EXCEPTION_PKG.insert_exception( g_exception
                                               ,x_errbuf
                                               ,x_retcode
                                              );

END log_exceptions;

-- +===================================================================+
-- | Name  :      delivery_to_roadnet                                  |
-- | Description: This procedure is used to import the deliveries      |
-- |              to roadnet                                           |
-- |                                                                   |
-- | Parameters:      p_delivery_id                                    |
-- | Returns :        x_xml                                            |
-- |                                                                   |
-- +===================================================================+

PROCEDURE delivery_to_roadnet( p_delivery_id IN NUMBER
                              ,x_xml OUT NOCOPY XMLTYPE )

IS

   l_response             XMLTYPE;
   l_http_request         utl_http.req;  -- Varibles for the call to UTL_HTTP
   l_http_response        utl_http.resp; -- Varibles for the call to UTL_HTTP
   lc_bpelproc_endpoint   VARCHAR2(200):= 'http://OSSI-0825:8888/orabpel/default/I1164_EBS_ROADNET_OUT/1.0';  -- BPEL end point
   lc_bpelproc_wsdldoc    VARCHAR2(200):= 'http://ossi-0825:8888/orabpel/default/I1164_EBS_ROADNET_OUT/1.0/I1164_EBS_ROADNET_OUT?wsdl'; -- BPEL wsdl
   lc_bpelproc_operation  VARCHAR2(200):= 'process'; -- default operation
   lc_soap_envelope       VARCHAR2(30000);
   lc_resp_back           VARCHAR2(30000);
   lc_rep_code            VARCHAR2(3) := -1;
   lc_region_id           hr_all_organization_units.attribute6%TYPE;      -- ATTRIBUTEXX has to be confirmed
   lc_customer_id         VARCHAR2(20);
   lc_cust_type_ccd       hz_cust_accounts.attribute8%TYPE;               -- ATTRIBUTEXX has to be confirmed
   ln_dlry_line_tot       NUMBER;
   lc_wholesale_flag      VARCHAR2(1);
   lc_redeliveryind       VARCHAR2(20);
   lc_samedayind          VARCHAR2(1);
   lc_setpickup           VARCHAR2(5);
   lc_orig_sys_ref        hz_parties.orig_system_reference%TYPE;
   lc_party_site_attr     hz_party_sites.attribute6%TYPE;                 -- ATTRIBUTEXX has to be confirmed
   lc_ship_to_cust_id     hz_parties.orig_system_reference%TYPE;
   lc_cust_type_ccd_attr  hz_cust_accounts.attribute8%TYPE;               -- ATTRIBUTEXX has to be confirmed
   lb_xml_structure       CLOB;
   lc_ordertypedescr      VARCHAR2(40);
   lc_selector            VARCHAR2(40);
   lc_order_lineid        wsh_delivery_details.source_line_id%TYPE;
   lc_delivery_from       xx_om_line_attributes_all.delivery_date_from%TYPE;
   lc_delivery_to         xx_om_line_attributes_all.delivery_date_to%TYPE;
   lc_bulk_attr           xx_om_line_attributes_all.line_modifier%TYPE;
   lc_furniture_attr      mtl_categories.segment1%TYPE;
   lc_order_type          oe_order_headers_v.order_type%TYPE;
   lc_returntypecd        oe_order_headers_all.order_category_code%TYPE;
   lc_load_status         VARCHAR2(1);
   lc_wholesaleind        oe_order_lines_all.attribute6%TYPE;             -- ATTRIBUTEXX has to be confirmed
   lc_error_code          VARCHAR2(40);
   lc_error_msg           VARCHAR2(1000);
   lc_entity_ref          VARCHAR2(40);
   lc_entity_ref_id       NUMBER;
   g_excn                 EXCEPTION;

--
-- Start of Changes made by Vidhya Valantina Tamilmani on 24-Jul-2007
--

   lc_errbuf              VARCHAR2(4000);
   lc_return_status       VARCHAR2(100);

   lr_delivery_attributes xx_wsh_delivery_att_t := xx_wsh_delivery_att_t(NULL
                                                                       , NULL
                                                                       , NULL
                                                                       , NULL
                                                                       , NULL
                                                                       , NULL
                                                                       , NULL
                                                                       , NULL
                                                                       , NULL
                                                                       , NULL
                                                                       , NULL
                                                                       , NULL
                                                                       , NULL
                                                                       , NULL
                                                                       , NULL
                                                                       , NULL
                                                                       , NULL
                                                                       , NULL
                                                                       , NULL
                                                                       , NULL
                                                                       , NULL
                                                                      );

--
-- End of Changes made by Vidhya Valantina Tamilmani on 24-Jul-2007
--

   --Delivery Details, Route ID,Gross Weight,earliest drop off date ,Service level,EstimatedCartons
   CURSOR lcu_delivery (p_del_id IN NUMBER)
   IS
   SELECT WND.delivery_id
         ,WND.name                              --Order Number
         ,WND.gross_weight                      --Gross Weight
         ,WND.ultimate_dropoff_date
         --,WND.earliest_dropoff_date             --Earliest Drop Off Date
         ,WT.attribute1 route_id                -- Route id
         ,XWDAA.redelivery_flag                 --redelivery_flag
         ,WND.service_level                     --Service level
         ,WND.number_of_lpn                     --Estimated Cartons
         ,WND.initial_pickup_location_id        --Initial pickup location id
         ,WND.ultimate_dropoff_location_id      --drop off location id
         ,WND.customer_id
         ,WND.organization_id
   FROM   wsh_new_deliveries WND
         ,wsh_delivery_legs WDL
         ,wsh_trip_stops WTS
         ,wsh_trips WT
         ,xx_wsh_delivery_att_all XWDAA
   WHERE  WND.delivery_id = WDL.delivery_id
   AND    WTS.stop_id     = WDL.pick_up_stop_id
   AND    WTS.trip_id     = WT.trip_id
   AND    WND.delivery_id = XWDAA.delivery_id
   AND    XWDAA.od_internal_delivery_status  = 'CARRIER_SELECTION_COMPLETED'
   AND    WT.attribute3   = 'Y'
   AND    WND.delivery_id = p_del_id
   ORDER BY WND.delivery_id;

   -- Furniture attribute
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

   --Region Id
   CURSOR lcu_region_id (
                         p_delivery_id   IN   NUMBER
                        ,p_organization_id IN NUMBER
                       )IS
   SELECT HAOU.attribute6                                       -- ATTRIBUTEXX has to be confirmed
   FROM   hr_all_organization_units HAOU
        , wsh_new_deliveries WND
   WHERE HAOU.location_id = WND.initial_pickup_location_id
   AND   HAOU.organization_id = WND.organization_id
   AND   WND.delivery_id = p_delivery_id
   AND   HAOU.organization_id = p_organization_id;

   --To derive Customer Id

    CURSOR lcu_customer_id (
                           p_drop_off_location_id   IN   NUMBER
                          ,p_customer_id            IN   NUMBER
                          )IS
   SELECT HP.orig_system_reference
         ,HZP.attribute6                                        -- ATTRIBUTEXX has to be confirmed
   FROM   hz_party_sites    HZP
         ,hz_parties        HP
         ,hz_cust_accounts  HCA
   WHERE HZP.location_id      = p_drop_off_location_id
   AND   HP.party_id          = HZP.party_id
   AND   HCA.party_id         = HP.party_id
   AND   HCA.cust_account_id  = p_customer_id;

   --To derive ODCustomertype
   CURSOR lcu_cust_type_ccd (
                             p_customer_id   IN   NUMBER
                            )IS
   SELECT HCA.attribute8                                        -- ATTRIBUTEXX has to be confirmed
   FROM   hz_cust_accounts HCA
   WHERE  HCA.cust_account_id = p_customer_id;

   -- To derive SKU,SKU Description, SKU Quantity, Weight, COGS
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

   -- To derive Source Line id
   CURSOR lcu_line(p_delivery_id IN NUMBER)
   IS
   SELECT WDD.source_line_id
   FROM   wsh_delivery_details WDD,
          wsh_delivery_assignments WDA
   WHERE  WDA.delivery_detail_id = WDD.delivery_detail_id
   AND    WDA.delivery_id = p_delivery_id;

   --To derive customer name,party_id
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

   -- To derive customer address info
   CURSOR lcu_address(
                      p_party_id IN NUMBER,
                      p_ultimate_dropoff_location_id IN NUMBER
                     )IS
   SELECT HL.address1 address_ln_1
         ,HL.address2
          || HL.address3
          || HL.address4 address_ln_2
         ,HL.address3
         ,HL.address4
         ,HL.city
         ,HL.state
         ,HL.postal_code
   FROM hz_locations    HL
       ,hz_party_sites  HPS
   WHERE HPS.location_id      = HL.location_id
   AND   HPS.party_id           = p_party_id
   AND   HL.location_id         = p_ultimate_dropoff_location_id;

   -- phone_code, area_code
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

   --To derive sold_to_contact
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
   SELECT OOL.attribute14                                      -- ATTRIBUTEXX has to be confirmed
         ,OOL.line_id            -- Order Line id
   FROM   oe_order_lines_all OOL
         ,wsh_delivery_details WDD
         ,wsh_delivery_assignments WDA
   WHERE OOL.line_id             = WDD.source_line_id
   AND   WDD.delivery_detail_id  = WDA.delivery_detail_id
   AND   WDA.delivery_id         = p_delivery_id;

--
-- Start of Changes made by Vidhya Valantina Tamilmani on 24-Jul-2007
--

-- To derive delivery from window and delivery to window
-- Commented the SQL Cursor

/* CURSOR lcu_delivery_fromto(
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
   AND   OOLA.line_id       = p_line_id; */

-- To derive delivery from window and delivery to window
-- Changes due to KFF-DFF Setup

   CURSOR lcu_delivery_fromto( p_line_id IN NUMBER ) IS
   SELECT XOLAA.delivery_date_from -- Delivery From Window
         ,XOLAA.delivery_date_to   -- Delivery To Window
   FROM   oe_order_lines_all          OOLA
         ,xx_om_line_attributes_all   XOLAA
   WHERE  XOLAA.line_id  = OOLA.line_id
   AND    OOLA.line_id   = p_line_id;

-- To Derive Bulk Attribute
-- Commented the SQL Cursor

/* CURSOR lcu_bulk_attr (
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
   AND   OOHA.header_id     = OOLA.header_id; */

-- To Derive Bulk Attribute
-- Changes due to KFF-DFF Setup

   CURSOR lcu_bulk_attr ( p_line_id IN NUMBER ) IS
   SELECT XOLAA.line_modifier     -- Bulk Attribute
   FROM   oe_order_lines_all         OOLA
         ,xx_om_line_attributes_all  XOLAA
   WHERE  XOLAA.line_id  = OOLA.line_id
   AND    OOLA.line_id   = p_line_id;

--
-- End of Changes made by Vidhya Valantina Tamilmani on 24-Jul-2007
--

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

   --To derive Returntypecd, Load Status
   CURSOR lcu_returntypecd (
                            p_delivery_id   IN   NUMBER
                           )IS
   SELECT DECODE ( OOH.order_category_code
                    ,'RETURN'
                    ,'RT'
                    ,NULL),
      DECODE ( OOH.flow_status_code,
               'CANCELLED',
               'V',
               'L')
   FROM   oe_order_lines_all OOL
         ,oe_order_headers_all OOH
         ,wsh_delivery_details WDD
         ,wsh_delivery_assignments WDA
   WHERE ool.line_id = wdd.source_line_id
   AND   WDD.delivery_detail_id = WDA.delivery_detail_id
   AND   OOH.header_id          = OOL.header_id;

   lc_delivery_rec        lcu_delivery%ROWTYPE;
   lc_sold_to_contact     lcu_sold_to_contact%ROWTYPE;
   lc_sku_rec             lcu_sku%ROWTYPE;
   lc_party_rec           lcu_party%ROWTYPE;
   lc_address             lcu_address%ROWTYPE;
   lc_phone               lcu_phone%ROWTYPE;

   BEGIN

    -- Need to Re-Visit
      -- Commented this code as the Profiles have to be created and
/*    FND_PROFILE.Get('XX_OM_DLVTORDNET_BPEL_EPT',lc_bpelproc_endpoint);
      FND_PROFILE.Get('XX_OM_DLVTORDNET_BPEL_WSDL',lc_bpelproc_wsdldoc);

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
          IF  lc_furniture_attr='FURNITURE' THEN
              lc_furniture_attr:='Y';
          ELSE
              lc_furniture_attr:='N';
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
          FETCH lcu_returntypecd INTO lc_returntypecd,lc_load_status;
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
          IF lc_delivery_rec.redelivery_flag = '<<REDELIVERY>>' THEN
             lc_redeliveryind  := 'Y';
          ELSE
             lc_redeliveryind := NULL;
          END IF;

          -- To derive samedayind
          IF lc_delivery_rec.service_level = 'SAMEDAY' THEN
             lc_samedayind     := 'Y';
          ELSE
             lc_samedayind     := 'N';
          END IF;

          -- To derive selector
          IF lc_redeliveryind='Y' THEN
             lc_selector:='R';
          ELSIF lc_wholesale_flag='Y' THEN
             lc_selector:='C';
          ELSIF lc_bulk_attr='BULK' THEN
             lc_selector:='B';
          ELSIF lc_furniture_attr='Y' THEN
             lc_selector:='F';
          ELSE
             lc_selector:='S';
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
             lb_xml_structure := lb_xml_structure||'<ns0:LoadStatus>'||lc_load_status||'</ns0:LoadStatus>';
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
             lb_xml_structure := lb_xml_structure||'<ns0:RedeliveryAttribute>'||NVL(lc_delivery_rec.redelivery_flag, '')||'</ns0:RedeliveryAttribute>';
             lb_xml_structure := lb_xml_structure||'<ns0:RedeliveryInd>'||NVL(lc_redeliveryind, '')||'</ns0:RedeliveryInd>';
             lb_xml_structure := lb_xml_structure||'<ns0:ReturntypeCD>'||NVL(lc_returntypecd, '')||'</ns0:ReturntypeCD>';
             lb_xml_structure := lb_xml_structure||'<ns0:SetPickUp>'||NVL(lc_setpickup, '')||'</ns0:SetPickUp>';
             lb_xml_structure := lb_xml_structure||'</ns0:CarrierRoute>';
             lb_xml_structure := lb_xml_structure||'</soapenv:Body>';
             lb_xml_structure := lb_xml_structure||'</soapenv:Envelope>';

             x_xml := SYS.XMLTYPE.createXML(lb_xml_structure);

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

             lr_delivery_attributes.delivery_id                 :=  p_delivery_id;
             lr_delivery_attributes.od_internal_delivery_status := 'ROADNET_IMPORT_STARTED';

             xx_wsh_delivery_attributes_pkg.update_row (
                                                         x_return_status          => lc_return_status
                                                        ,x_errbuf                 => lc_errbuf
                                                        ,p_delivery_attributes    => lr_delivery_attributes
                                                       );

          ELSE

             lr_delivery_attributes.delivery_id                 :=  p_delivery_id;
             lr_delivery_attributes.od_internal_delivery_status := 'ROADNET_IMPORT_FAILED';

             xx_wsh_delivery_attributes_pkg.update_row (
                                                         x_return_status          => lc_return_status
                                                        ,x_errbuf                 => lc_errbuf
                                                        ,p_delivery_attributes    => lr_delivery_attributes
                                                       );

          END IF;

          IF ( lc_return_status = FND_API.G_RET_STS_SUCCESS ) THEN

             COMMIT;

          END IF;

       EXCEPTION
          WHEN OTHERS THEN

             lb_xml_structure :='<?xml version="1.0" encoding="UTF-8"?>';
             lb_xml_structure := lb_xml_structure||'<Error>'||sqlerrm||'</Error>';
             x_xml := SYS.XMLTYPE.createXML(lb_xml_structure);

             FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
             FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
             FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
             lc_error_msg        := FND_MESSAGE.GET;
             lc_error_code       := 'XX_OM_65100_UNEXPECTED_ERROR1';
             lc_entity_ref_id    := p_delivery_id;

             --Calling  Procedure to insert into Global Exception Table
             log_exceptions (p_error_code =>lc_error_code
                            ,p_error_description=>lc_error_msg
                            ,p_entity_ref_id=>lc_entity_ref_id
                            );

       END;

  --  END IF;

EXCEPTION
   WHEN g_excn THEN

      lb_xml_structure :='<?xml version="1.0" encoding="UTF-8"?>';
      lb_xml_structure := lb_xml_structure||'<Error>'||sqlerrm||'</Error>';
      x_xml := SYS.XMLTYPE.createXML(lb_xml_structure);

      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
      lc_error_msg        := FND_MESSAGE.GET;
      lc_error_code       := 'XX_OM_65100_UNEXPECTED_ERROR2';
      lc_entity_ref_id    := p_delivery_id;

      --Calling  Procedure to insert into Global Exception Table
      log_exceptions (p_error_code =>lc_error_code
                     ,p_error_description=>lc_error_msg
                     ,p_entity_ref_id=>lc_entity_ref_id
                     );

   WHEN OTHERS THEN

      lb_xml_structure :='<?xml version="1.0" encoding="UTF-8"?>';
      lb_xml_structure := lb_xml_structure||'<Error>'||sqlerrm||'</Error>';
      x_xml := SYS.XMLTYPE.createXML(lb_xml_structure);

      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
      lc_error_msg        := FND_MESSAGE.GET;
      lc_error_code       := 'XX_OM_65100_UNEXPECTED_ERROR3';
      lc_entity_ref_id    := p_delivery_id;

      --Calling  Procedure to insert into Global Exception Table
      log_exceptions (p_error_code =>lc_error_code
                     ,p_error_description=>lc_error_msg
                     ,p_entity_ref_id=>lc_entity_ref_id
                     );
END delivery_to_roadnet;

END xx_om_delivery_to_roadnet_pkg;
/

SHOW ERRORS;
