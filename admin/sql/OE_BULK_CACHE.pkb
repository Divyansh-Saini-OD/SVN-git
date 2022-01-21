SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY OE_BULK_CACHE AS
/* $Header: OEBUCCHB.pls 115.15.11510.5 2005/07/01 20:51:11 xding ship $ */
/* Commented SQL call in Load_Sold_To function for Performance improvement by NB*/

G_PKG_NAME         CONSTANT     VARCHAR2(30):='OE_BULK_CACHE';

PROCEDURE Get_Address(
           p_address_type_in      IN  VARCHAR2,
           p_org_id_in            IN  NUMBER,
           p_address_id_in        IN NUMBER,
           p_tp_location_code_in     IN  VARCHAR2,
           p_tp_translator_code_in   IN  VARCHAR2,
l_addr1 OUT NOCOPY VARCHAR2,

l_addr2 OUT NOCOPY VARCHAR2,

l_addr3 OUT NOCOPY VARCHAR2,

l_addr4 OUT NOCOPY VARCHAR2,

l_addr_alt OUT NOCOPY VARCHAR2,

l_city OUT NOCOPY VARCHAR2,

l_county OUT NOCOPY VARCHAR2,

l_state OUT NOCOPY VARCHAR2,

l_zip OUT NOCOPY VARCHAR2,

l_province OUT NOCOPY VARCHAR2,

l_country OUT NOCOPY VARCHAR2,

l_region1 OUT NOCOPY VARCHAR2,

l_region2 OUT NOCOPY VARCHAR2,

l_region3 OUT NOCOPY VARCHAR2,

x_return_status OUT NOCOPY VARCHAR2)

IS

     l_entity_id                   NUMBER;
     l_msg_count                   NUMBER;
     l_msg_data                    VARCHAR2(80);
     l_status_code                 NUMBER;
     l_return_status               VARCHAR2(20);
     l_address_type                NUMBER;
     l_org_id                      NUMBER;
     l_tp_location_code            VARCHAR2(3200);
     l_tp_translator_code          VARCHAR2(3200);
     l_tp_location_name            VARCHAR2(3200);
     l_addr_id                     VARCHAR2(3200);

--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'ADDRESS TYPE = '||P_ADDRESS_TYPE_IN ) ;
  END IF;
  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'ORG = '||P_ORG_ID_IN ) ;
  END IF;
  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'ADDRESS ID = '||P_ADDRESS_ID_IN ) ;
  END IF;

  IF p_address_type_in = 'CUSTOMER' THEN
    l_address_type := 1;
  ELSIF p_address_type_in = 'HR_LOCATION' THEN
    l_address_type := 2;
  END IF;

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'BEFORE CALLING EC ADDRESS DERIVATION API' ) ;
    END IF;
    ece_trading_partners_pub.ece_Get_Address_wrapper(
      p_api_version_number   => 1.0,
      x_return_status        => l_return_status,
      x_msg_count            => l_msg_count,
      x_msg_data             => l_msg_data,
      x_status_code          => l_status_code,
      p_address_type         => l_address_type,
      p_transaction_type     => 'POAO',
      p_org_id_in            => p_org_id_in,
      p_address_id_in        => p_address_id_in,
      p_tp_location_code_in  => p_tp_location_code_in,
      p_translator_code_in   => p_tp_translator_code_in,
      p_tp_location_name_in  => l_tp_location_name,
      p_address_line1_in     => l_addr1,
      p_address_line2_in     => l_addr2,
      p_address_line3_in     => l_addr3,
      p_address_line4_in     => l_addr4,
      p_address_line_alt_in  => l_addr_alt,
      p_city_in              => l_city,
      p_county_in            => l_county,
      p_state_in             => l_state,
      p_zip_in               => l_zip,
      p_province_in          => l_province,
      p_country_in           => l_country,
      p_region_1_in          => l_region1,
      p_region_2_in          => l_region2,
      p_region_3_in          => l_region3,
      x_entity_id_out        => l_entity_id,
      x_org_id_out           => l_org_id,
      x_address_id_out       => l_addr_id,
      x_tp_location_code_out => l_tp_location_code,
      x_translator_code_out  => l_tp_translator_code,
      x_tp_location_name_out => l_tp_location_name,
      x_address_line1_out    => l_addr1,
      x_address_line2_out    => l_addr2,
      x_address_line3_out    => l_addr3,
      x_address_line4_out    => l_addr4,
      x_address_line_alt_out => l_addr_alt,
      x_city_out             => l_city,
      x_county_out           => l_county,
      x_state_out            => l_state,
      x_zip_out              => l_zip,
      x_province_out         => l_province,
      x_country_out          => l_country,
      x_region_1_out         => l_region1,
      x_region_2_out         => l_region2,
      x_region_3_out         => l_region3);

  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'ADDR1 = '||SUBSTR ( L_ADDR1 , 0 , 240 ) ) ;
  END IF;
  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'CITY = '||L_CITY ) ;
  END IF;
  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'ZIP = '||L_ZIP ) ;
  END IF;
  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'COUNTRY = '||L_COUNTRY ) ;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
    IF OE_BULK_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
    THEN
       OE_BULK_MSG_PUB.Add_Exc_Msg
        (G_PKG_NAME, 'Get_Address');
    END IF;
END Get_Address;


FUNCTION Load_Order_Type
( p_key                     IN NUMBER
, p_default_attributes       IN VARCHAR2
)
RETURN NUMBER
IS
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN

   IF G_ORDER_TYPE_TBL.EXISTS(p_key)
      AND ( p_default_attributes = 'N'
            OR (p_default_attributes = 'Y'
                 AND G_ORDER_TYPE_TBL(p_key).default_attributes = 'Y'))
   THEN

      RETURN p_key;

   END IF;


   IF p_default_attributes = 'Y' THEN

      SELECT o.transaction_type_id
            ,otl.name
            ,o.order_category_code
            ,o.warehouse_id
            ,o.agreement_required_flag
            ,o.po_required_flag
            ,o.entry_credit_check_rule_id
            ,o.start_date_active
            ,o.end_date_active
            ,i.rule_id
            ,a.rule_id
            ,pl.list_header_id
            ,sp.lookup_code
            ,sm.lookup_code
            ,fp.lookup_code
            ,ft.lookup_code
            ,dc.lookup_code
            ,lt.transaction_type_id
            ,o.conversion_type_code
            ,o.tax_calculation_event_code
            ,o.auto_scheduling_flag
            ,o.scheduling_level_code
            ,'Y'
	    ,rl.QUICK_CR_CHECK_FLAG
            ,rtrx.tax_calculation_flag
            ,o.cust_trx_type_id
     INTO   G_ORDER_TYPE_TBL(p_key).order_type_id
            ,G_ORDER_TYPE_TBL(p_key).name
            ,G_ORDER_TYPE_TBL(p_key).order_category_code
            ,G_ORDER_TYPE_TBL(p_key).ship_from_org_id
            ,G_ORDER_TYPE_TBL(p_key).agreement_required_flag
            ,G_ORDER_TYPE_TBL(p_key).require_po_flag
            ,G_ORDER_TYPE_TBL(p_key).entry_credit_check_rule_id
            ,G_ORDER_TYPE_TBL(p_key).start_date_active
            ,G_ORDER_TYPE_TBL(p_key).end_date_active
            ,G_ORDER_TYPE_TBL(p_key).invoicing_rule_id
            ,G_ORDER_TYPE_TBL(p_key).accounting_rule_id
            ,G_ORDER_TYPE_TBL(p_key).price_list_id
            ,G_ORDER_TYPE_TBL(p_key).shipment_priority_code
            ,G_ORDER_TYPE_TBL(p_key).shipping_method_code
            ,G_ORDER_TYPE_TBL(p_key).fob_point_code
            ,G_ORDER_TYPE_TBL(p_key).freight_terms_code
            ,G_ORDER_TYPE_TBL(p_key).demand_class_code
            ,G_ORDER_TYPE_TBL(p_key).default_outbound_line_type_id
            ,G_ORDER_TYPE_TBL(p_key).conversion_type_code
            ,G_ORDER_TYPE_TBL(p_key).tax_calculation_event
            ,G_ORDER_TYPE_TBL(p_key).auto_scheduling_flag
            ,G_ORDER_TYPE_TBL(p_key).scheduling_level_code
            ,G_ORDER_TYPE_TBL(p_key).default_attributes
	   ,G_ORDER_TYPE_TBL(p_key).quick_cr_check_flag
           ,G_ORDER_TYPE_TBL(p_key).tax_calculation_flag
           ,G_ORDER_TYPE_TBL(p_key).cust_trx_type_id
     FROM oe_transaction_types_all o
         ,oe_transaction_types_tl otl
         ,oe_ra_rules_v i
         ,oe_ra_rules_v a
         ,qp_list_headers_vl pl
         ,oe_lookups sp
         ,oe_ship_methods_v sm
         ,oe_ar_lookups_v fp
         ,oe_lookups ft
         ,oe_fnd_common_lookups_v dc
         ,oe_transaction_types_all lt
	 ,oe_credit_check_rules rl
         ,ra_cust_trx_types rtrx
     WHERE o.transaction_type_id = p_key
       AND o.invoicing_rule_id = i.rule_id(+)
       AND i.status(+) = 'A'
       AND i.type(+) = 'I'
       AND o.accounting_rule_id = a.rule_id(+)
       AND a.status(+) = 'A'
       AND a.type(+) = 'A'
       AND o.price_list_id = pl.list_header_id(+)
       AND nvl(pl.active_flag(+),'Y') = 'Y'
       AND o.shipment_priority_code = sp.lookup_code(+)
       AND sp.lookup_type(+) = 'SHIPMENT_PRIORITY'
       AND sp.enabled_flag(+) = 'Y'
       AND sysdate between nvl(sp.start_date_active(+),sysdate)
                   and nvl(sp.end_date_active(+),sysdate)
       AND o.shipping_method_code = sm.lookup_code(+)
       AND sm.lookup_type(+) = 'SHIP_METHOD'
       AND sm.enabled_flag(+) = 'Y'
       AND sysdate between nvl(sm.start_date_active(+),sysdate)
                   and nvl(sm.end_date_active(+),sysdate)
       AND o.fob_point_code = fp.lookup_code(+)
       AND fp.lookup_type(+) = 'FOB'
       AND fp.enabled_flag(+) = 'Y'
       AND sysdate between nvl(fp.start_date_active(+),sysdate)
                   and nvl(fp.end_date_active(+),sysdate)
       AND o.freight_terms_code = ft.lookup_code(+)
       AND ft.lookup_type(+) = 'FREIGHT_TERMS'
       AND ft.enabled_flag(+) = 'Y'
       AND sysdate between nvl(ft.start_date_active(+),sysdate)
                   and nvl(ft.end_date_active(+),sysdate)
       AND o.demand_class_code = dc.lookup_code(+)
       AND dc.lookup_type(+) = 'DEMAND_CLASS'
       AND dc.enabled_flag(+) = 'Y'
       AND sysdate between nvl(dc.start_date_active(+),sysdate)
                   and nvl(dc.end_date_active(+),sysdate)
       AND lt.transaction_type_id(+) = o.default_outbound_line_type_id
       AND sysdate between nvl(lt.start_date_active(+),sysdate)
                   and nvl(lt.end_date_active(+),sysdate)
       AND otl.transaction_type_id = o.transaction_type_id
       AND otl.language = userenv('LANG')
       AND o.entry_credit_check_rule_id = rl.credit_check_rule_id(+)
       AND o.cust_trx_type_id = rtrx.cust_trx_type_id(+)
       AND sysdate between nvl(rl.start_date_active(+),sysdate)
                   and nvl(rl.end_date_active(+),sysdate);


   ELSE

     SELECT o.transaction_type_id
            ,otl.name
            ,o.order_category_code
            ,o.warehouse_id
            ,o.agreement_required_flag
            ,o.po_required_flag
            ,o.entry_credit_check_rule_id
            ,o.start_date_active
            ,o.end_date_active
            ,o.tax_calculation_event_code
            ,o.auto_scheduling_flag
            ,o.scheduling_level_code
	    ,rl.quick_cr_check_flag
            ,rtrx.tax_calculation_flag
            ,o.cust_trx_type_id
       INTO G_ORDER_TYPE_TBL(p_key).order_type_id
            ,G_ORDER_TYPE_TBL(p_key).name
            ,G_ORDER_TYPE_TBL(p_key).order_category_code
            ,G_ORDER_TYPE_TBL(p_key).ship_from_org_id
            ,G_ORDER_TYPE_TBL(p_key).agreement_required_flag
            ,G_ORDER_TYPE_TBL(p_key).require_po_flag
            ,G_ORDER_TYPE_TBL(p_key).entry_credit_check_rule_id
            ,G_ORDER_TYPE_TBL(p_key).start_date_active
            ,G_ORDER_TYPE_TBL(p_key).end_date_active
            ,G_ORDER_TYPE_TBL(p_key).tax_calculation_event
            ,G_ORDER_TYPE_TBL(p_key).auto_scheduling_flag
            ,G_ORDER_TYPE_TBL(p_key).scheduling_level_code
	    ,G_ORDER_TYPE_TBL(p_key).quick_cr_check_flag
            ,G_ORDER_TYPE_TBL(p_key).tax_calculation_flag
            ,G_ORDER_TYPE_TBL(p_key).cust_trx_type_id
     FROM  OE_TRANSACTION_TYPES_ALL o
          ,oe_transaction_types_tl otl
	  ,oe_credit_check_rules rl
          ,ra_cust_trx_types rtrx
     WHERE o.transaction_type_id = p_key
       AND otl.transaction_type_id = o.transaction_type_id
       AND otl.language = userenv('LANG')
       AND o.entry_credit_check_rule_id = rl.credit_check_rule_id(+)
       AND o.cust_trx_type_id = rtrx.cust_trx_type_id(+)
       AND sysdate between nvl(rl.start_date_active(+),sysdate)
                   and nvl(rl.end_date_active(+),sysdate);

   END IF;

    -- Set the Global OE_BULK_ORDER_PVT.G_CC_REQUIRED if the cc rule exists
   -- for one of the Order Types in a batch

   IF G_ORDER_TYPE_TBL(p_key).entry_credit_check_rule_id IS NOT NULL
   THEN
       IF OE_BULK_ORDER_PVT.G_CC_REQUIRED = 'N' THEN
           OE_BULK_ORDER_PVT.G_CC_REQUIRED := 'Y';
       END IF;

   -- Set the Global OE_BULK_ORDER_PVT.G_REALTIME_CC_REQUIRED if any one
   -- order in a batch requires real time credit checking. If this flag
   -- is set then orders will get inserted with booked_flag = 'N' to allow
   -- Real Time CC to happen order by order.

       IF ( G_ORDER_TYPE_TBL(p_key).quick_cr_check_flag IS NULL OR
            G_ORDER_TYPE_TBL(p_key).quick_cr_check_flag = 'N')
       THEN
           IF OE_BULK_ORDER_PVT.G_REALTIME_CC_REQUIRED = 'N' THEN
               OE_BULK_ORDER_PVT.G_REALTIME_CC_REQUIRED := 'Y';
           END IF;
       END IF;
   END IF;


   RETURN p_key;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
     IF G_ORDER_TYPE_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_ORDER_TYPE_TBL.DELETE(p_key);
     END IF;
     RAISE NO_DATA_FOUND;
  WHEN OTHERS THEN
     IF G_ORDER_TYPE_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_ORDER_TYPE_TBL.DELETE(p_key);
     END IF;
    OE_BULK_MSG_PUB.Add_Exc_Msg
      (   G_PKG_NAME
        ,'Load_Order_Type'
       );
  RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Load_Order_Type;

FUNCTION Load_Line_Type
( p_key                     IN NUMBER
, p_default_attributes       IN VARCHAR2
)
RETURN NUMBER
IS
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN

   IF G_LINE_TYPE_TBL.EXISTS(p_key) THEN

      RETURN p_key;

   END IF;

     SELECT o.transaction_type_id
            ,o.order_category_code
            ,o.start_date_active
            ,o.end_date_active
            ,o.cust_trx_type_id
            ,ct.tax_calculation_flag
            ,o.scheduling_level_code
     INTO   G_LINE_TYPE_TBL(p_key).line_type_id
            ,G_LINE_TYPE_TBL(p_key).order_category_code
            ,G_LINE_TYPE_TBL(p_key).start_date_active
            ,G_LINE_TYPE_TBL(p_key).end_date_active
            ,G_LINE_TYPE_TBL(p_key).cust_trx_type_id
            ,G_LINE_TYPE_TBL(p_key).tax_calculation_flag
            ,G_LINE_TYPE_TBL(p_key).scheduling_level_code
     FROM oe_transaction_types_all o
           ,ra_cust_trx_types ct
     WHERE o.transaction_type_id = p_key
       AND o.cust_trx_type_id = ct.cust_trx_type_id(+);

   RETURN p_key;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
     IF G_LINE_TYPE_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_LINE_TYPE_TBL.DELETE(p_key);
     END IF;
    RAISE NO_DATA_FOUND;
  WHEN OTHERS THEN
     IF G_LINE_TYPE_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_LINE_TYPE_TBL.DELETE(p_key);
     END IF;
    OE_BULK_MSG_PUB.Add_Exc_Msg
      (   G_PKG_NAME
        ,'Load_Line_Type'
       );
  RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Load_Line_Type;

FUNCTION Load_Agreement
( p_key                     IN NUMBER
, p_default_attributes       IN VARCHAR2
)
RETURN NUMBER
IS
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN

   IF G_AGREEMENT_TBL.EXISTS(p_key)
      AND ( p_default_attributes = 'N'
            OR (p_default_attributes = 'Y'
                 AND G_AGREEMENT_TBL(p_key).default_attributes = 'Y'))
   THEN

      RETURN p_key;

   END IF;

   IF p_default_attributes = 'Y' THEN

     SELECT a.agreement_id
            ,a.name
            ,a.start_date_active
            ,a.end_date_active
            ,a.revision
            ,a.sold_to_org_id
            ,a.price_list_id
            ,i.rule_id
            ,ac.rule_id
            ,term.term_id
            ,s.salesrep_id
            ,a.purchase_order_num
            ,a.invoice_contact_id
            ,a.invoice_to_org_id
            ,'Y'
       INTO G_AGREEMENT_TBL(p_key).agreement_id
            ,G_AGREEMENT_TBL(p_key).name
            ,G_AGREEMENT_TBL(p_key).start_date_active
            ,G_AGREEMENT_TBL(p_key).end_date_active
            ,G_AGREEMENT_TBL(p_key).revision
            ,G_AGREEMENT_TBL(p_key).sold_to_org_id
            ,G_AGREEMENT_TBL(p_key).price_list_id
            ,G_AGREEMENT_TBL(p_key).invoicing_rule_id
            ,G_AGREEMENT_TBL(p_key).accounting_rule_id
            ,G_AGREEMENT_TBL(p_key).payment_term_id
            ,G_AGREEMENT_TBL(p_key).salesrep_id
            ,G_AGREEMENT_TBL(p_key).cust_po_number
            ,G_AGREEMENT_TBL(p_key).invoice_to_contact_id
            ,G_AGREEMENT_TBL(p_key).invoice_to_org_id
            ,G_AGREEMENT_TBL(p_key).default_attributes
       FROM oe_agreements_vl a
            ,oe_ra_rules_v i
            ,oe_ra_rules_v ac
            ,oe_ra_terms_v term
            ,ra_salesreps s
       WHERE a.agreement_id = p_key
         AND a.invoicing_rule_id = i.rule_id(+)
         AND i.status(+) = 'A'
         AND i.type(+) = 'I'
         AND a.accounting_rule_id = ac.rule_id(+)
         AND ac.status(+) = 'A'
         AND ac.type(+) = 'A'
         AND a.term_id = term.term_id(+)
         AND sysdate between nvl(term.start_date_active(+),sysdate)
                   and nvl(term.end_date_active(+),sysdate)
         AND a.salesrep_id = s.salesrep_id(+)
         AND sysdate between nvl(s.start_date_active(+),sysdate)
                   and nvl(s.end_date_active(+),sysdate)
         ;

   ELSE

     SELECT a.agreement_id
            ,a.name
            ,a.start_date_active
            ,a.end_date_active
            ,a.revision
            ,a.sold_to_org_id
            ,a.price_list_id
       INTO G_AGREEMENT_TBL(p_key).agreement_id
            ,G_AGREEMENT_TBL(p_key).name
            ,G_AGREEMENT_TBL(p_key).start_date_active
            ,G_AGREEMENT_TBL(p_key).end_date_active
            ,G_AGREEMENT_TBL(p_key).revision
            ,G_AGREEMENT_TBL(p_key).sold_to_org_id
            ,G_AGREEMENT_TBL(p_key).price_list_id
       FROM oe_agreements_vl a
       WHERE a.agreement_id = p_key;

   END IF;

   RETURN p_key;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
     IF G_AGREEMENT_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_AGREEMENT_TBL.DELETE(p_key);
     END IF;
     RAISE NO_DATA_FOUND;
  WHEN OTHERS THEN
     IF G_AGREEMENT_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_AGREEMENT_TBL.DELETE(p_key);
     END IF;
    OE_BULK_MSG_PUB.Add_Exc_Msg
      (   G_PKG_NAME
        ,'Load_Agreement'
       );
  RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Load_Agreement;

FUNCTION Load_Item
( p_key1             IN NUMBER
, p_key2             IN NUMBER
, p_default_attributes       IN VARCHAR2
)
RETURN NUMBER
IS
l_key2               NUMBER;
     --OPM 02/JUN/00 BEGIN
     --===================
     CURSOR c_opm_item ( discrete_org_id  IN NUMBER
                       , discrete_item_id IN NUMBER) IS
       SELECT dualum_ind
       	    , item_id
            , item_um
            , item_um2
            , grade_ctl -- OPM HVOP
       FROM  ic_item_mst
       WHERE delete_mark = 0
       AND   item_no in (SELECT segment1
         	 FROM mtl_system_items
     	        WHERE organization_id   = discrete_org_id
                  AND inventory_item_id = discrete_item_id);
     --OPM 02/JUN/00 END
     --=================
     --
     l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
     --
BEGIN

   IF G_ITEM_TBL.EXISTS(p_key1)
      AND ( p_default_attributes = 'N'
            OR (p_default_attributes = 'Y'
                 AND G_ITEM_TBL(p_key1).default_attributes = 'Y')) AND
      G_ITEM_TBL(p_key1).organization_id
      = nvl(p_key2, G_ITEM_TBL(p_key1).organization_id)
   THEN

      RETURN p_key1;

   END IF;

   l_key2 := OE_BULK_ORDER_PVT.G_ITEM_ORG;

   IF p_key1 IS NOT NULL AND
      NOT G_ITEM_TBL.EXISTS(p_key1) THEN

      /* Always load values based on the validation org
      for the below attributes. In future please add here for the columns
      which need to get loaded based on validation org */
      /* Shippable_item_flag will be loaded into cache here and
      later the same will be reloaded based on the ship_from_org_id.
      This is because shippable_flag_item need to be loaded based on
      the validation_org if ship_from_org is null*/

      SELECT  msi.INVENTORY_ITEM_ID
             ,msi.ORGANIZATION_ID
             ,msi.CUSTOMER_ORDER_ENABLED_FLAG
             ,msi.INTERNAL_ORDER_ENABLED_FLAG
             ,msi.INVOICING_RULE_ID
             ,msi.ACCOUNTING_RULE_ID
             ,msi.DEFAULT_SHIPPING_ORG
             ,msi.SHIP_MODEL_COMPLETE_FLAG
             ,msi.BUILD_IN_WIP_FLAG
             ,msi.BOM_ITEM_TYPE
             ,msi.REPLENISH_TO_ORDER_FLAG
             ,msi.PRIMARY_UOM_CODE
             ,msi.PICK_COMPONENTS_FLAG
             ,msi.SHIPPABLE_ITEM_FLAG
             ,msi.SERVICE_ITEM_FLAG
             ,msi.OVER_SHIPMENT_TOLERANCE
             ,msi.UNDER_SHIPMENT_TOLERANCE
             ,msi.description
             ,msi.hazard_class_id
             ,msi.weight_uom_code
             ,msi.volume_uom_code
             ,msi.unit_volume
             ,msi.unit_weight
             ,DECODE(msi.mtl_transactions_enabled_flag, 'Y', 'Y', 'N')
              pickable_flag
             --bug 3798477
             ,DECODE(msi.ONT_PRICING_QTY_SOURCE, 'P', 0, 'S',1,NULL)
             ,msi.TRACKING_QUANTITY_IND
             --bug 3798477
	     ,msi.CONFIG_MODEL_TYPE
             ,msi.PLANNING_MAKE_BUY_CODE
	     ,kfv.concatenated_segments
	     ,msi.full_lead_time
	     ,msi.fixed_lead_time
	     ,msi.variable_lead_time
     INTO   G_ITEM_TBL(p_key1).inventory_item_id
           ,G_ITEM_TBL(p_key1).organization_id
           ,G_ITEM_TBL(p_key1).customer_order_enabled_flag
           ,G_ITEM_TBL(p_key1).internal_order_enabled_flag
           ,G_ITEM_TBL(p_key1).invoicing_rule_id
           ,G_ITEM_TBL(p_key1).accounting_rule_id
           ,G_ITEM_TBL(p_key1).default_shipping_org
           ,G_ITEM_TBL(p_key1).ship_model_complete_flag
           ,G_ITEM_TBL(p_key1).build_in_wip_flag
           ,G_ITEM_TBL(p_key1).bom_item_type
           ,G_ITEM_TBL(p_key1).replenish_to_order_flag
           ,G_ITEM_TBL(p_key1).primary_uom_code
           ,G_ITEM_TBL(p_key1).pick_components_flag
           ,G_ITEM_TBL(p_key1).shippable_item_flag
           ,G_ITEM_TBL(p_key1).service_item_flag
           ,G_ITEM_TBL(p_key1).ship_tolerance_above
           ,G_ITEM_TBL(p_key1).ship_tolerance_below
           ,G_ITEM_TBL(p_key1).item_description
           ,G_ITEM_TBL(p_key1).hazard_class_id
           ,G_ITEM_TBL(p_key1).weight_uom_code
           ,G_ITEM_TBL(p_key1).volume_uom_code
           ,G_ITEM_TBL(p_key1).unit_volume
           ,G_ITEM_TBL(p_key1).unit_weight
           ,G_ITEM_TBL(p_key1).pickable_flag
           --bug 3798477
           ,G_ITEM_TBL(p_key1).ont_pricing_qty_source
           ,G_ITEM_TBL(p_key1).tracking_quantity_ind
           --bug 3798477
           ,G_ITEM_TBL(p_key1).config_model_type
	   ,G_ITEM_TBL(p_key1).planning_make_buy_code
	   ,G_ITEM_TBL(p_key1).ordered_item
	   ,G_ITEM_TBL(p_key1).full_lead_time
	   ,G_ITEM_TBL(p_key1).fixed_lead_time
	   ,G_ITEM_TBL(p_key1).variable_lead_time
     FROM   MTL_SYSTEM_ITEMS 		msi,
	    MTL_SYSTEM_ITEMS_KFV 	kfv
     WHERE  msi.INVENTORY_ITEM_ID = p_key1
     AND    msi.ORGANIZATION_ID = l_key2
     AND    kfv.INVENTORY_ITEM_ID = p_key1
     AND    kfv.ORGANIZATION_ID = l_key2;

     /* OPM 02/JUN/00 - OPM item master characteristics */

     IF OE_Bulk_Order_PVT.G_PROCESS_INSTALLED_FLAG = 'Y' THEN

        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'PROCESS INSTALLED' ) ;
        END IF;

        IF INV_GMI_RSV_BRANCH.G_PROCESS_INV_INSTALLED = 'I' THEN
           OPEN c_opm_item( l_key2
                           , p_key1);
           FETCH c_opm_item INTO
                G_ITEM_TBL(p_key1).dualum_ind
                , G_ITEM_TBL(p_key1).opm_item_id
            	, G_ITEM_TBL(p_key1).opm_item_um
            	, G_ITEM_TBL(p_key1).opm_item_um2
            	, G_ITEM_TBL(p_key1).opm_grade_ctl;  -- OPM HVOP

         	/*OPM HVOP need this in case of process warehouse and discrete item - Fully clear the process cache */
           	IF c_opm_item%NOTFOUND THEN

           	IF l_debug_level  > 0 THEN
	            oe_debug_pub.add(  'OPM item not found ', 1 ) ;
                END IF;
               	   G_ITEM_TBL(p_key1).opm_item_id  := NULL;
	           G_ITEM_TBL(p_key1).opm_item_um  := NULL;
	           G_ITEM_TBL(p_key1).opm_item_um2 := NULL;
                   G_ITEM_TBL(p_key1).dualum_ind   := NULL;
	           G_ITEM_TBL(p_key1).opm_grade_ctl    := NULL;
               END IF;
           CLOSE c_opm_item;
        END IF;

     END IF;

     /* When p_key2 is not null ie. ship_from_org_id is not null then
     load the shippable_item_flag based on the ship_from_org. In future
     please add the attributes here that needs to be loaded based on the
     ship_from_org_id */

     IF (p_key2 IS NOT NULL) THEN

       IF (G_ITEM_TBL(p_key1).organization_id <> p_key2) THEN

         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'QUERYING BASED ON SHIP_FROM_ORG' , 3 ) ;
         END IF;

         IF OE_Bulk_Order_PVT.G_PROCESS_INSTALLED_FLAG <> 'Y' THEN    -- OPM HVOP added for error to test

         SELECT shippable_item_flag
               ,organization_id
               ,primary_uom_code
               ,description
               ,hazard_class_id
               ,weight_uom_code
               ,volume_uom_code
               ,unit_volume
               ,unit_weight
               ,DECODE(mtl_transactions_enabled_flag, 'Y', 'Y', 'N')
                pickable_flag
         INTO   G_ITEM_TBL(p_key1).shippable_item_flag
               ,G_ITEM_TBL(p_key1).organization_id
               ,G_ITEM_TBL(p_key1).primary_uom_code
               ,G_ITEM_TBL(p_key1).item_description
               ,G_ITEM_TBL(p_key1).hazard_class_id
               ,G_ITEM_TBL(p_key1).weight_uom_code
               ,G_ITEM_TBL(p_key1).volume_uom_code
               ,G_ITEM_TBL(p_key1).unit_volume
               ,G_ITEM_TBL(p_key1).unit_weight
               ,G_ITEM_TBL(p_key1).pickable_flag
         FROM   MTL_SYSTEM_ITEMS
         WHERE  INVENTORY_ITEM_ID = p_key1
         AND    ORGANIZATION_ID = p_key2; -- ship from org

         END IF; -- OPM HVOP added for error to test

         --bug 3798477
         SELECT wms_enabled_flag
         INTO   G_ITEM_TBL(p_key1).wms_enabled_flag
         FROM mtl_parameters
         WHERE organization_id = p_key2;
         --bug 3798477


         /* OPM - check for process warehouse */
         IF INV_GMI_RSV_BRANCH.Is_Org_Process_Org(p_key2) THEN
            G_ITEM_TBL(p_key1).process_warehouse_flag := 'Y';
         ELSE
            G_ITEM_TBL(p_key1).process_warehouse_flag := NULL;
         END IF;
            IF l_debug_level  > 0 THEN
                oe_debug_pub.add(  'OPM IN OE_ORDER_CACHE.LOAD_ITEM PROCESS WAREHOUSE FLAG IS ' || G_ITEM_TBL ( P_KEY1 ) .PROCESS_WAREHOUSE_FLAG ) ;
            END IF;
         /* OPM END */

        END IF; -- if item tbl.org_id <> p_key2

      END IF; -- End if p_key2 is not null

   END IF; -- End if p_key1 is not null

   RETURN p_key1;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'NO DATA FOUND IN LOAD ITEM' ) ;
     END IF;
     IF G_ITEM_TBL.EXISTS(p_key1) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_ITEM_TBL.DELETE(p_key1);
     END IF;

      IF OE_Bulk_Order_PVT.G_PROCESS_INSTALLED_FLAG = 'Y' -- PAL HVOP
        AND INV_GMI_RSV_BRANCH.Is_Org_Process_Org(p_key2)  THEN
         FND_MESSAGE.SET_NAME('ONT', 'OE_INVALID_ITEM_WHSE');
        OE_BULK_MSG_PUB.add('Y','ERROR');
      RAISE NO_DATA_FOUND;
      END IF;

  WHEN OTHERS THEN

     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'OPM when others ' ) ;
         END IF;
     IF G_ITEM_TBL.EXISTS(p_key1) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_ITEM_TBL.DELETE(p_key1);
     END IF;
    OE_BULK_MSG_PUB.Add_Exc_Msg
      (   G_PKG_NAME
       , 'Load_Item'
       );
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END Load_Item;


FUNCTION Load_Ship_To
( p_key                     IN NUMBER
, p_default_attributes       IN VARCHAR2
, p_edi_attributes           IN VARCHAR2
)
RETURN NUMBER
IS
  l_addr_alt                    VARCHAR2(3200) := NULL;
  l_region1                     VARCHAR2(3200) := NULL;
  l_region2                     VARCHAR2(3200) := NULL;
  l_region3                     VARCHAR2(3200) := NULL;
  l_return_status               VARCHAR2(30);
  --
  l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
  --
BEGIN

   IF G_SHIP_TO_TBL.EXISTS(p_key)
      AND ( p_default_attributes = 'N'
            OR (p_default_attributes = 'Y'
                 AND G_SHIP_TO_TBL(p_key).default_attributes = 'Y'))
      AND ( p_edi_attributes = 'N'
            OR (p_edi_attributes = 'Y'
                 AND G_SHIP_TO_TBL(p_key).address_id IS NOT NULL))
   THEN

      RETURN p_key;

   END IF;


   IF p_default_attributes = 'N' THEN

      SELECT s.site_use_id
            ,a.cust_account_id
      INTO   G_SHIP_TO_TBL(p_key).ship_to_org_id
            ,G_SHIP_TO_TBL(p_key).customer_id
      FROM  hz_cust_site_uses s
           ,hz_cust_acct_sites a
      WHERE s.site_use_id = p_key
        AND s.site_use_code = 'SHIP_TO'
        AND s.cust_acct_site_id = a.cust_acct_site_id
        AND s.status = 'A'
	AND a.status ='A'; --bug 2752321

   ELSIF p_default_attributes = 'Y' THEN

      IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'SHIP TO :'||P_KEY ) ;
      END IF;
      SELECT s.site_use_id
            ,a.cust_account_id
            ,s.warehouse_id
            ,s.OVER_SHIPMENT_TOLERANCE
            ,s.UNDER_SHIPMENT_TOLERANCE
            ,s.ITEM_CROSS_REF_PREF
            ,s.dates_positive_tolerance
            ,s.date_type_preference
            ,o.transaction_type_id
            ,sm.lookup_code
            ,fp.lookup_code
            ,ft.lookup_code
            ,dc.lookup_code
            ,'Y'
     INTO   G_SHIP_TO_TBL(p_key).ship_to_org_id
            ,G_SHIP_TO_TBL(p_key).customer_id
            ,G_SHIP_TO_TBL(p_key).ship_from_org_id
            ,G_SHIP_TO_TBL(p_key).ship_tolerance_above
            ,G_SHIP_TO_TBL(p_key).ship_tolerance_below
            ,G_SHIP_TO_TBL(p_key).item_identifier_type
            ,G_SHIP_TO_TBL(p_key).latest_schedule_limit
            ,G_SHIP_TO_TBL(p_key).order_date_type_code
            ,G_SHIP_TO_TBL(p_key).order_type_id
            ,G_SHIP_TO_TBL(p_key).shipping_method_code
            ,G_SHIP_TO_TBL(p_key).fob_point_code
            ,G_SHIP_TO_TBL(p_key).freight_terms_code
            ,G_SHIP_TO_TBL(p_key).demand_class_code
            ,G_SHIP_TO_TBL(p_key).default_attributes
     FROM hz_cust_site_uses s
         ,hz_cust_acct_sites a
         ,oe_transaction_types_all o
         ,oe_ship_methods_v sm
         ,oe_ar_lookups_v fp
         ,oe_lookups ft
         ,oe_fnd_common_lookups_v dc
     WHERE s.site_use_id = p_key
       AND a.cust_acct_site_id = s.cust_acct_site_id
       AND s.site_use_code = 'SHIP_TO'
       AND s.status = 'A'
       AND a.status ='A' --bug 2752321
       AND s.order_type_id = o.transaction_type_id(+)
       AND sysdate between nvl(o.start_date_active(+),sysdate)
                   and nvl(o.end_date_active(+),sysdate)
       AND s.ship_via = sm.lookup_code(+)
       AND sm.lookup_type(+) = 'SHIP_METHOD'
       AND sm.enabled_flag(+) = 'Y'
       AND sysdate between nvl(sm.start_date_active(+),sysdate)
                   and nvl(sm.end_date_active(+),sysdate)
       AND s.fob_point = fp.lookup_code(+)
       AND fp.lookup_type(+) = 'FOB'
       AND fp.enabled_flag(+) = 'Y'
       AND sysdate between nvl(fp.start_date_active(+),sysdate)
                   and nvl(fp.end_date_active(+),sysdate)
       AND s.freight_term = ft.lookup_code(+)
       AND ft.lookup_type(+) = 'FREIGHT_TERMS'
       AND ft.enabled_flag(+) = 'Y'
       AND sysdate between nvl(ft.start_date_active(+),sysdate)
                   and nvl(ft.end_date_active(+),sysdate)
       AND s.demand_class_code = dc.lookup_code(+)
       AND dc.lookup_type(+) = 'DEMAND_CLASS'
       AND dc.enabled_flag(+) = 'Y'
       AND sysdate between nvl(dc.start_date_active(+),sysdate)
                   and nvl(dc.end_date_active(+),sysdate);

   END IF;

   IF p_edi_attributes = 'Y' THEN

      SELECT b.cust_acct_site_id
            ,a.ece_tp_location_code
            ,b.location
      INTO  G_SHIP_TO_TBL(p_key).address_id
            ,G_SHIP_TO_TBL(p_key).edi_location_code
            ,G_SHIP_TO_TBL(p_key).location
      FROM hz_cust_acct_sites_all a
           , hz_cust_site_uses_all b
      WHERE a.cust_acct_site_id = b.cust_acct_site_id
       AND b.site_use_id = p_key
       AND b.site_use_code='SHIP_TO';

      Get_Address
          (p_address_type_in      => 'CUSTOMER',
           p_org_id_in            => OE_BULK_ORDER_PVT.G_ITEM_ORG,
           p_address_id_in        => G_SHIP_TO_TBL(p_key).address_id,
           p_tp_location_code_in  => NULL,
           p_tp_translator_code_in => NULL,
           l_addr1                => G_SHIP_TO_TBL(p_key).address1,
           l_addr2                => G_SHIP_TO_TBL(p_key).address2,
           l_addr3                => G_SHIP_TO_TBL(p_key).address3,
           l_addr4                => G_SHIP_TO_TBL(p_key).address4,
           l_addr_alt             => l_addr_alt,
           l_city                 => G_SHIP_TO_TBL(p_key).city,
           l_county               => G_SHIP_TO_TBL(p_key).county,
           l_state                => G_SHIP_TO_TBL(p_key).state,
           l_zip                  => G_SHIP_TO_TBL(p_key).zip,
           l_province             => G_SHIP_TO_TBL(p_key).province,
           l_country              => G_SHIP_TO_TBL(p_key).country,
           l_region1              => l_region1,
           l_region2              => l_region2,
           l_region3              => l_region3,
           x_return_status        => l_return_status);

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;
   END IF;

   RETURN p_key;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
     IF G_SHIP_TO_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_SHIP_TO_TBL.DELETE(p_key);
     END IF;
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'NO DATA FOUND IN LOAD SHIP TO' ) ;
     END IF;
     RAISE NO_DATA_FOUND;
  WHEN OTHERS THEN
     IF G_SHIP_TO_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_SHIP_TO_TBL.DELETE(p_key);
     END IF;
    OE_BULK_MSG_PUB.Add_Exc_Msg
      (   G_PKG_NAME
       , 'Load_Ship_To'
       );
  RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Load_Ship_To;

FUNCTION Load_Sold_To
( p_key                     IN NUMBER
, p_default_attributes       IN VARCHAR2
, p_edi_attributes           IN VARCHAR2
)
RETURN NUMBER
IS
  l_tp_ret             BOOLEAN;
  l_tp_ret_status      VARCHAR2(30);
  l_msg_count          NUMBER;
  l_msg_data           VARCHAR2(2000);
  --
  l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
  --
BEGIN

   IF G_SOLD_TO_TBL.EXISTS(p_key)
      AND ( p_default_attributes = 'N'
            OR (p_default_attributes = 'Y'
                 AND G_SOLD_TO_TBL(p_key).default_attributes = 'Y'))
      AND ( p_edi_attributes = 'N'
            OR (p_edi_attributes = 'Y'
                 AND G_SOLD_TO_TBL(p_key).address_id IS NOT NULL))
   THEN

      RETURN p_key;

   END IF;

   IF p_edi_attributes = 'Y' THEN
   
     BEGIN

-- Commented out by NB 01-OCT-09
 /*    SELECT a.cust_acct_site_id
     INTO   G_SOLD_TO_TBL(p_key).address_id
     FROM   hz_cust_site_uses_all b, hz_cust_acct_sites_all a
     WHERE  a.cust_acct_site_id = b.cust_acct_site_id
     AND    a.cust_account_id = p_key
     AND    NVL(a.org_id,NVL(TO_NUMBER(DECODE(SUBSTRB(USERENV('CLIENT_INFO'),
           1,1),' ',NULL,SUBSTRB(USERENV('CLIENT_INFO'),1,10))),-99)) =
           NVL(TO_NUMBER(DECODE( SUBSTRB(USERENV('CLIENT_INFO'),1,1),
           ' ',NULL,SUBSTRB(USERENV('CLIENT_INFO'),1,10))),-99)
     AND    b.site_use_code = 'SOLD_TO'
     AND    b.primary_flag = 'Y'
     AND    b.status = 'A'
     AND    a.status = 'A';--bug 2752321

     l_tp_ret := EC_TRADING_PARTNER_PVT.Is_Entity_Enabled (
         p_api_version_number   => 1.0
        ,p_init_msg_list        => null
        ,p_simulate             => null
        ,p_commit               => null
        ,p_validation_level     => null
        ,p_transaction_type     => 'POAO'
        ,p_transaction_subtype  => null
        ,p_entity_type          => EC_TRADING_PARTNER_PVT.G_CUSTOMER
        ,p_entity_id            => G_SOLD_TO_TBL(p_key).address_id
        ,p_return_status        => l_tp_ret_status
        ,p_msg_count            => l_msg_count
        ,p_msg_data             => l_msg_data);

                            IF l_debug_level  > 0 THEN
                                oe_debug_pub.add(  'AFTER CALL TO THE EDI API , RET STATUS: ' ||L_TP_RET_STATUS ) ;
                            END IF;

     IF l_tp_ret = FALSE then
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'TP SETUP FALSE FOR :'||P_KEY ) ;
        END IF;
        G_SOLD_TO_TBL(p_key).tp_setup := FALSE;
     ELSE
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'TP SETUP TRUE FOR :'||P_KEY ) ;
        END IF;
        G_SOLD_TO_TBL(p_key).tp_setup := TRUE;
     END IF; */
     
     G_SOLD_TO_TBL(p_key).address_id := -1;
     G_SOLD_TO_TBL(p_key).tp_setup := FALSE;

     EXCEPTION
     WHEN NO_DATA_FOUND THEN
          G_SOLD_TO_TBL(p_key).address_id := -1;
          G_SOLD_TO_TBL(p_key).tp_setup := FALSE;
     END;

  END IF;

  RETURN p_key;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
     IF G_SOLD_TO_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_SOLD_TO_TBL.DELETE(p_key);
     END IF;
     RAISE NO_DATA_FOUND;
  WHEN OTHERS THEN
     IF G_SOLD_TO_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_SOLD_TO_TBL.DELETE(p_key);
     END IF;
    OE_BULK_MSG_PUB.Add_Exc_Msg
      (   G_PKG_NAME
       ,  'Load_Sold_To'
       );
  RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Load_Sold_To;

/*end customer changes */

FUNCTION Load_End_Customer
( p_key                     IN NUMBER
, p_default_attributes       IN VARCHAR2
, p_edi_attributes           IN VARCHAR2
)
RETURN NUMBER
IS
  l_tp_ret             BOOLEAN;
  l_tp_ret_status      VARCHAR2(30);
  l_msg_count          NUMBER;
  l_msg_data           VARCHAR2(2000);
  --
  l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
  --
Cursor End_Customer_site(p_site_use_code VARCHAR,p_key NUMBER) IS
      SELECT a.cust_acct_site_id
     FROM   hz_cust_site_uses_all b, hz_cust_acct_sites_all a
     WHERE  a.cust_acct_site_id = b.cust_acct_site_id
     AND    a.cust_account_id = p_key
     AND  NVL(a.org_id,NVL(TO_NUMBER(DECODE(SUBSTRB(USERENV('CLIENT_INFO'),1,1),' ',NULL,SUBSTRB(USERENV('CLIENT_INFO'),1,10))),-99)) =
           NVL(TO_NUMBER(DECODE( SUBSTRB(USERENV('CLIENT_INFO'),1,1),' ',NULL,SUBSTRB(USERENV('CLIENT_INFO'),1,10))),-99)
     AND    b.site_use_code = p_site_use_code
     AND    b.primary_flag = 'Y'
     AND    b.status = 'A'
     AND    a.status = 'A';

BEGIN

   IF G_END_CUSTOMER_TBL.EXISTS(p_key)
      AND ( p_default_attributes = 'N'
            OR (p_default_attributes = 'Y'
                 AND G_END_CUSTOMER_TBL(p_key).default_attributes = 'Y'))
      AND ( p_edi_attributes = 'N'
            OR (p_edi_attributes = 'Y'
                 AND G_END_CUSTOMER_TBL(p_key).address_id IS NOT NULL))
   THEN

      RETURN p_key;

   END IF ;

   IF p_edi_attributes = 'Y' THEN


        OPEN End_customer_site('SOLD_TO',p_key);
      FETCH End_customer_site
	 INTO G_END_CUSTOMER_TBL(p_key).address_id;
      IF End_customer_site%FOUND then
	 CLOSE End_customer_site;
	 oe_debug_pub.add('found sold to site use id');
          goto site_found;
      ELSE
	 CLOSE End_customer_site;
	 END IF;

	 OPEN End_customer_site('SHIP_TO',p_key);
      FETCH End_customer_site
	 INTO G_END_CUSTOMER_TBL(p_key).address_id;
      IF End_customer_site%FOUND then
	 CLOSE End_customer_site;
	 oe_debug_pub.add('found sold to site use id');
          goto site_found;
      ELSE
	 CLOSE End_customer_site;
	 END IF;

	 OPEN End_customer_site('BILL_TO',p_key);
      FETCH End_customer_site
	 INTO G_END_CUSTOMER_TBL(p_key).address_id;
      IF End_customer_site%FOUND then
	 CLOSE End_customer_site;
	 oe_debug_pub.add('found sold to site use id');
          goto site_found;
      ELSE
	 CLOSE End_customer_site;
	 END IF;

	 OPEN End_customer_site('DELIVER_TO',p_key);
      FETCH End_customer_site
	 INTO G_END_CUSTOMER_TBL(p_key).address_id;
      IF End_customer_site%FOUND then
	 CLOSE End_customer_site;
	 oe_debug_pub.add('found sold to site use id');
          goto site_found;
      ELSE
	 CLOSE End_customer_site;
	 END IF;

     <<site_found>>

     l_tp_ret := EC_TRADING_PARTNER_PVT.Is_Entity_Enabled (
         p_api_version_number   => 1.0
        ,p_init_msg_list        => null
        ,p_simulate             => null
        ,p_commit               => null
        ,p_validation_level     => null
        ,p_transaction_type     => 'POAO'
        ,p_transaction_subtype  => null
        ,p_entity_type          => EC_TRADING_PARTNER_PVT.G_CUSTOMER
        ,p_entity_id            => G_SOLD_TO_TBL(p_key).address_id
        ,p_return_status        => l_tp_ret_status
        ,p_msg_count            => l_msg_count
        ,p_msg_data             => l_msg_data);

                            IF l_debug_level  > 0 THEN
                                oe_debug_pub.add(  'AFTER CALL TO THE EDI API , RET STATUS: ' ||L_TP_RET_STATUS ) ;
                            END IF;

     IF l_tp_ret = FALSE then
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'TP SETUP FALSE FOR :'||P_KEY ) ;
        END IF;
        G_END_CUSTOMER_TBL(p_key).tp_setup := FALSE;
     ELSE
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'TP SETUP TRUE FOR :'||P_KEY ) ;
        END IF;
        G_END_CUSTOMER_TBL(p_key).tp_setup := TRUE;
     END IF;


  END IF;

  RETURN p_key;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
     IF G_END_CUSTOMER_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_END_CUSTOMER_TBL.DELETE(p_key);
     END IF;
     RAISE NO_DATA_FOUND;
  WHEN OTHERS THEN
     IF G_END_CUSTOMER_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_END_CUSTOMER_TBL.DELETE(p_key);
     END IF;
    OE_BULK_MSG_PUB.Add_Exc_Msg
      (   G_PKG_NAME
       ,  'Load_End_Customer_To'
       );
  RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Load_End_customer;

/*end customer changes */

FUNCTION Load_End_Customer_Site
( p_key                      IN NUMBER
, p_default_attributes       IN VARCHAR2
, p_edi_attributes           IN VARCHAR2
)
RETURN NUMBER
IS
  l_addr_alt                    VARCHAR2(3200) := NULL;
  l_region1                     VARCHAR2(3200) := NULL;
  l_region2                     VARCHAR2(3200) := NULL;
  l_region3                     VARCHAR2(3200) := NULL;
  l_return_status               VARCHAR2(30);
  --
  l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
  --
Cursor End_customer_site_use (p_site_use_code varchar2) IS
  SELECT s.site_use_id
            ,a.cust_account_id
	 from hz_cust_site_uses s
           ,hz_cust_acct_sites a
      WHERE s.site_use_id = p_key
        AND s.site_use_code =p_site_use_code
        AND s.cust_acct_site_id = a.cust_acct_site_id
        AND s.status = 'A'
	AND a.status ='A';

Cursor End_customer_address(p_site_use_code varchar2,p_key number) IS
  SELECT b.cust_acct_site_id
            ,a.ece_tp_location_code
            ,b.location
      FROM hz_cust_acct_sites_all a
           , hz_cust_site_uses_all b
      WHERE a.cust_acct_site_id = b.cust_acct_site_id
       AND b.site_use_id = p_key
       AND b.site_use_code=p_site_use_code;
BEGIN

   IF G_END_CUSTOMER_SITE_TBL.EXISTS(p_key)
      AND ( p_default_attributes = 'N'
            OR (p_default_attributes = 'Y'
                 AND G_END_CUSTOMER_SITE_TBL(p_key).default_attributes = 'Y'))
   THEN

      RETURN p_key;

   END IF;

    IF p_default_attributes = 'N' THEN

     OPEN End_customer_site_use('SOLD_TO');
      FETCH End_customer_site_use
	 INTO G_END_CUSTOMER_SITE_TBL(p_key).sold_to_site_use_id,
	      G_END_CUSTOMER_SITE_TBL(p_key).customer_id;
      IF End_customer_site_use%FOUND then
	 CLOSE End_customer_site_use ;
	 oe_debug_pub.add('found sold to site use id');
          goto site_found;
      ELSE
	 CLOSE End_customer_site_use;
        END IF;
	 OPEN End_customer_site_use('SHIP_TO');
      FETCH End_customer_site_use
	 INTO G_END_CUSTOMER_SITE_TBL(p_key).sold_to_site_use_id,
	      G_END_CUSTOMER_SITE_TBL(p_key).customer_id;
      IF End_customer_site_use%FOUND then
	 CLOSE End_customer_site_use ;
	 oe_debug_pub.add('found ship to site use id');
          goto site_found;
      ELSE
	 CLOSE End_customer_site_use;
        END IF;
	 OPEN End_customer_site_use('BILL_TO');
      FETCH End_customer_site_use
	 INTO G_END_CUSTOMER_SITE_TBL(p_key).sold_to_site_use_id,
	      G_END_CUSTOMER_SITE_TBL(p_key).customer_id;
      IF End_customer_site_use%FOUND then
	 CLOSE End_customer_site_use ;
	 oe_debug_pub.add('found bill to site use id');
          goto site_found;
      ELSE
	 CLOSE End_customer_site_use;
	 END IF;
         OPEN End_customer_site_use('DELIVER_TO');
      FETCH End_customer_site_use
	 INTO G_END_CUSTOMER_SITE_TBL(p_key).sold_to_site_use_id,
	      G_END_CUSTOMER_SITE_TBL(p_key).customer_id;
      IF End_customer_site_use%FOUND then
	 CLOSE End_customer_site_use ;
	 oe_debug_pub.add('found deliver to site use id');
          goto site_found;
      ELSE
	 CLOSE End_customer_site_use;
	END IF;

	END IF; -- if default attribute is N

	<<site_found>>

   IF p_edi_attributes = 'Y' THEN

      OPEN End_customer_address('SOLD_TO',p_key);
      FETCH End_customer_address
	  INTO G_SOLD_TO_SITE_TBL(p_key).address_id
	       ,G_SOLD_TO_SITE_TBL(p_key).edi_location_code
	       ,G_SOLD_TO_SITE_TBL(p_key).location;

      IF End_customer_address%FOUND then
	 CLOSE End_customer_address;
	 oe_debug_pub.add('found sold to site use id');
	 goto address_found;
      ELSE
	 CLOSE End_customer_address;
      END IF;

      OPEN End_customer_address('SHIP_TO',p_key);
      FETCH End_customer_address
	  INTO G_SOLD_TO_SITE_TBL(p_key).address_id
	       ,G_SOLD_TO_SITE_TBL(p_key).edi_location_code
	       ,G_SOLD_TO_SITE_TBL(p_key).location;

      IF End_customer_address%FOUND then
	 CLOSE End_customer_address;
	 oe_debug_pub.add('found ship to site use id');
	 goto address_found;
      ELSE
	 CLOSE End_customer_address;
      END IF;

      OPEN End_customer_address('BILL_TO',p_key);
      FETCH End_customer_address
	  INTO G_SOLD_TO_SITE_TBL(p_key).address_id
	       ,G_SOLD_TO_SITE_TBL(p_key).edi_location_code
	       ,G_SOLD_TO_SITE_TBL(p_key).location;

      IF End_customer_address%FOUND then
	 CLOSE End_customer_address;
	 oe_debug_pub.add('found bill to site use id');
	 goto address_found;
      ELSE
	 CLOSE End_customer_address;
      END IF;

      OPEN End_customer_address('DELIVER_TO',p_key);
      FETCH End_customer_address
	  INTO G_SOLD_TO_SITE_TBL(p_key).address_id
	       ,G_SOLD_TO_SITE_TBL(p_key).edi_location_code
	       ,G_SOLD_TO_SITE_TBL(p_key).location;

      IF End_customer_address%FOUND then
	 CLOSE End_customer_address;
	 oe_debug_pub.add('found deliver to site use id');
	 goto address_found;
      ELSE
	 CLOSE End_customer_address;
      END IF;



	 <<address_found>>

      Get_Address
          (p_address_type_in      => 'CUSTOMER',
           p_org_id_in            => OE_BULK_ORDER_PVT.G_ITEM_ORG,
           p_address_id_in        => G_SOLD_TO_SITE_TBL(p_key).address_id,
           p_tp_location_code_in  => NULL,
           p_tp_translator_code_in => NULL,
           l_addr1                => G_SOLD_TO_SITE_TBL(p_key).address1,
           l_addr2                => G_SOLD_TO_SITE_TBL(p_key).address2,
           l_addr3                => G_SOLD_TO_SITE_TBL(p_key).address3,
           l_addr4                => G_SOLD_TO_SITE_TBL(p_key).address4,
           l_addr_alt             => l_addr_alt,
           l_city                 => G_SOLD_TO_SITE_TBL(p_key).city,
           l_county               => G_SOLD_TO_SITE_TBL(p_key).county,
           l_state                => G_SOLD_TO_SITE_TBL(p_key).state,
           l_zip                  => G_SOLD_TO_SITE_TBL(p_key).zip,
           l_province             => G_SOLD_TO_SITE_TBL(p_key).province,
           l_country              => G_SOLD_TO_SITE_TBL(p_key).country,
           l_region1              => l_region1,
           l_region2              => l_region2,
           l_region3              => l_region3,
           x_return_status        => l_return_status);

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;



   END IF;


   RETURN p_key;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'NO DATA FOUND IN LOAD SOLD_TO_SITE:'||TO_CHAR ( P_KEY ) ) ;
    END IF;
     IF G_SOLD_TO_SITE_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_SOLD_TO_SITE_TBL.DELETE(p_key);
     END IF;
    RAISE NO_DATA_FOUND;
  WHEN OTHERS THEN
     IF G_SOLD_TO_SITE_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_SOLD_TO_SITE_TBL.DELETE(p_key);
     END IF;
    OE_BULK_MSG_PUB.Add_Exc_Msg
      (   G_PKG_NAME
        , 'Load_Sold_To_Site'
       );
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Load_End_Customer_Site;



FUNCTION Load_Invoice_To
( p_key                      IN NUMBER
, p_default_attributes       IN VARCHAR2
, p_edi_attributes           IN VARCHAR2
)
RETURN NUMBER
IS
  l_addr_alt                    VARCHAR2(3200) := NULL;
  l_region1                     VARCHAR2(3200) := NULL;
  l_region2                     VARCHAR2(3200) := NULL;
  l_region3                     VARCHAR2(3200) := NULL;
  l_return_status               VARCHAR2(30);
  --
  l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
  --
BEGIN

   IF G_INVOICE_TO_TBL.EXISTS(p_key)
      AND ( p_default_attributes = 'N'
            OR (p_default_attributes = 'Y'
                 AND G_INVOICE_TO_TBL(p_key).default_attributes = 'Y'))
   THEN

      RETURN p_key;

   END IF;


   IF p_default_attributes = 'N' THEN

      SELECT s.site_use_id
            ,a.cust_account_id
      INTO   G_INVOICE_TO_TBL(p_key).invoice_to_org_id
            ,G_INVOICE_TO_TBL(p_key).customer_id
      FROM  hz_cust_site_uses s
           ,hz_cust_acct_sites a
      WHERE s.site_use_id = p_key
        AND s.site_use_code = 'BILL_TO'
        AND s.cust_acct_site_id = a.cust_acct_site_id
        AND s.status = 'A'
	    AND a.status ='A'; --bug 2752321

   ELSIF p_default_attributes = 'Y' THEN

      SELECT s.site_use_id
            ,a.cust_account_id
            ,o.transaction_type_id
            ,term.term_id
            ,pl.list_header_id
            ,'Y'
      INTO   G_INVOICE_TO_TBL(p_key).invoice_to_org_id
            ,G_INVOICE_TO_TBL(p_key).customer_id
            ,G_INVOICE_TO_TBL(p_key).order_type_id
            ,G_INVOICE_TO_TBL(p_key).payment_term_id
            ,G_INVOICE_TO_TBL(p_key).price_list_id
            ,G_INVOICE_TO_TBL(p_key).default_attributes
      FROM   hz_cust_site_uses s
            ,hz_cust_acct_sites a
            ,oe_transaction_types_all o
            ,ra_terms term
            ,qp_list_headers pl
      WHERE s.site_use_id = p_key
        AND s.site_use_code = 'BILL_TO'
        AND s.cust_acct_site_id = a.cust_acct_site_id
        AND s.status = 'A'
	AND a.status ='A'--bug 2752321
        AND s.order_type_id = o.transaction_type_id(+)
        AND sysdate between nvl(o.start_date_active(+),sysdate)
                   and nvl(o.end_date_active(+),sysdate)
        AND s.payment_term_id = term.term_id(+)
        AND sysdate between nvl(term.start_date_active(+),sysdate)
                  and nvl(term.end_date_active(+),sysdate)
        AND s.price_list_id = pl.list_header_id(+)
        AND nvl(pl.active_flag(+),'Y') = 'Y'
        ;

   END IF;

   IF p_edi_attributes = 'Y' THEN

      SELECT b.cust_acct_site_id
            ,a.ece_tp_location_code
            ,b.location
      INTO  G_INVOICE_TO_TBL(p_key).address_id
            ,G_INVOICE_TO_TBL(p_key).edi_location_code
            ,G_INVOICE_TO_TBL(p_key).location
      FROM hz_cust_acct_sites_all a
           , hz_cust_site_uses_all b
      WHERE a.cust_acct_site_id = b.cust_acct_site_id
       AND b.site_use_id = p_key
       AND b.site_use_code='BILL_TO';

      Get_Address
          (p_address_type_in      => 'CUSTOMER',
           p_org_id_in            => OE_BULK_ORDER_PVT.G_ITEM_ORG,
           p_address_id_in        => G_INVOICE_TO_TBL(p_key).address_id,
           p_tp_location_code_in  => NULL,
           p_tp_translator_code_in => NULL,
           l_addr1                => G_INVOICE_TO_TBL(p_key).address1,
           l_addr2                => G_INVOICE_TO_TBL(p_key).address2,
           l_addr3                => G_INVOICE_TO_TBL(p_key).address3,
           l_addr4                => G_INVOICE_TO_TBL(p_key).address4,
           l_addr_alt             => l_addr_alt,
           l_city                 => G_INVOICE_TO_TBL(p_key).city,
           l_county               => G_INVOICE_TO_TBL(p_key).county,
           l_state                => G_INVOICE_TO_TBL(p_key).state,
           l_zip                  => G_INVOICE_TO_TBL(p_key).zip,
           l_province             => G_INVOICE_TO_TBL(p_key).province,
           l_country              => G_INVOICE_TO_TBL(p_key).country,
           l_region1              => l_region1,
           l_region2              => l_region2,
           l_region3              => l_region3,
           x_return_status        => l_return_status);

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;
   END IF;


   RETURN p_key;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'NO DATA FOUND IN LOAD INVOICE TO :'||TO_CHAR ( P_KEY ) ) ;
    END IF;
     IF G_INVOICE_TO_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_INVOICE_TO_TBL.DELETE(p_key);
     END IF;
    RAISE NO_DATA_FOUND;
  WHEN OTHERS THEN
     IF G_INVOICE_TO_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_INVOICE_TO_TBL.DELETE(p_key);
     END IF;
    OE_BULK_MSG_PUB.Add_Exc_Msg
      (   G_PKG_NAME
        , 'Load_Invoice_To'
       );
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Load_Invoice_To;
/*sdatti*/
FUNCTION Load_Sold_To_Site
( p_key                      IN NUMBER
, p_default_attributes       IN VARCHAR2
, p_edi_attributes           IN VARCHAR2
)
RETURN NUMBER
IS
  l_addr_alt                    VARCHAR2(3200) := NULL;
  l_region1                     VARCHAR2(3200) := NULL;
  l_region2                     VARCHAR2(3200) := NULL;
  l_region3                     VARCHAR2(3200) := NULL;
  l_return_status               VARCHAR2(30);
  --
  l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
  --
BEGIN

   IF G_SOLD_TO_SITE_TBL.EXISTS(p_key)
      AND ( p_default_attributes = 'N'
            OR (p_default_attributes = 'Y'
                 AND G_SOLD_TO_SITE_TBL(p_key).default_attributes = 'Y'))
   THEN

      RETURN p_key;

   END IF;


   IF p_default_attributes = 'N' THEN

      SELECT s.site_use_id
            ,a.cust_account_id
      INTO   G_SOLD_TO_SITE_TBL(p_key).sold_to_site_use_id
            ,G_SOLD_TO_SITE_TBL(p_key).customer_id
      FROM  hz_cust_site_uses s
           ,hz_cust_acct_sites a
      WHERE s.site_use_id = p_key
        AND s.site_use_code = 'SOLD_TO'
        AND s.cust_acct_site_id = a.cust_acct_site_id
        AND s.status = 'A'
	AND a.status ='A';

   ELSIF p_default_attributes = 'Y' THEN

      SELECT s.site_use_id
            ,a.cust_account_id
            ,o.transaction_type_id
            ,term.term_id
            ,pl.list_header_id
            ,'Y'
      INTO   G_SOLD_TO_SITE_TBL(p_key).sold_to_site_use_id
            ,G_SOLD_TO_SITE_TBL(p_key).customer_id
            ,G_SOLD_TO_SITE_TBL(p_key).order_type_id
            ,G_SOLD_TO_SITE_TBL(p_key).payment_term_id
            ,G_SOLD_TO_SITE_TBL(p_key).price_list_id
            ,G_SOLD_TO_SITE_TBL(p_key).default_attributes
      FROM   hz_cust_site_uses s
            ,hz_cust_acct_sites a
            ,oe_transaction_types_all o
            ,ra_terms term
            ,qp_list_headers pl
      WHERE s.site_use_id = p_key
        AND s.site_use_code = 'SOLD_TO'
        AND s.cust_acct_site_id = a.cust_acct_site_id
        AND s.status = 'A'
	AND a.status ='A'--bug 2752321
        AND s.order_type_id = o.transaction_type_id(+)
        AND sysdate between nvl(o.start_date_active(+),sysdate)
                   and nvl(o.end_date_active(+),sysdate)
        AND s.payment_term_id = term.term_id(+)
        AND sysdate between nvl(term.start_date_active(+),sysdate)
                  and nvl(term.end_date_active(+),sysdate)
        AND s.price_list_id = pl.list_header_id(+)
        AND nvl(pl.active_flag(+),'Y') = 'Y'
        ;

   END IF;

   IF p_edi_attributes = 'Y' THEN

      SELECT b.cust_acct_site_id
            ,a.ece_tp_location_code
            ,b.location
      INTO  G_SOLD_TO_SITE_TBL(p_key).address_id
            ,G_SOLD_TO_SITE_TBL(p_key).edi_location_code
            ,G_SOLD_TO_SITE_TBL(p_key).location
      FROM hz_cust_acct_sites_all a
           , hz_cust_site_uses_all b
      WHERE a.cust_acct_site_id = b.cust_acct_site_id
       AND b.site_use_id = p_key
       AND b.site_use_code='SOLD_TO';

      Get_Address
          (p_address_type_in      => 'CUSTOMER',
           p_org_id_in            => OE_BULK_ORDER_PVT.G_ITEM_ORG,
           p_address_id_in        => G_SOLD_TO_SITE_TBL(p_key).address_id,
           p_tp_location_code_in  => NULL,
           p_tp_translator_code_in => NULL,
           l_addr1                => G_SOLD_TO_SITE_TBL(p_key).address1,
           l_addr2                => G_SOLD_TO_SITE_TBL(p_key).address2,
           l_addr3                => G_SOLD_TO_SITE_TBL(p_key).address3,
           l_addr4                => G_SOLD_TO_SITE_TBL(p_key).address4,
           l_addr_alt             => l_addr_alt,
           l_city                 => G_SOLD_TO_SITE_TBL(p_key).city,
           l_county               => G_SOLD_TO_SITE_TBL(p_key).county,
           l_state                => G_SOLD_TO_SITE_TBL(p_key).state,
           l_zip                  => G_SOLD_TO_SITE_TBL(p_key).zip,
           l_province             => G_SOLD_TO_SITE_TBL(p_key).province,
           l_country              => G_SOLD_TO_SITE_TBL(p_key).country,
           l_region1              => l_region1,
           l_region2              => l_region2,
           l_region3              => l_region3,
           x_return_status        => l_return_status);

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;
   END IF;


   RETURN p_key;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'NO DATA FOUND IN LOAD SOLD_TO_SITE:'||TO_CHAR ( P_KEY ) ) ;
    END IF;
     IF G_SOLD_TO_SITE_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_SOLD_TO_SITE_TBL.DELETE(p_key);
     END IF;
    RAISE NO_DATA_FOUND;
  WHEN OTHERS THEN
     IF G_SOLD_TO_SITE_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_SOLD_TO_SITE_TBL.DELETE(p_key);
     END IF;
    OE_BULK_MSG_PUB.Add_Exc_Msg
      (   G_PKG_NAME
        , 'Load_Sold_To_Site'
       );
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Load_Sold_To_Site;
/*sdatti*/
FUNCTION Load_Salesrep
( p_key                      IN NUMBER
)
RETURN NUMBER
IS
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN

   IF G_SALESREP_TBL.EXISTS(p_key)
   THEN

      RETURN p_key;

   END IF;

   SELECT salesrep_id
         ,sales_credit_type_id
         ,person_id
         ,sales_tax_geocode
         ,sales_tax_inside_city_limits
   INTO   G_SALESREP_TBL(p_key).salesrep_id
         ,G_SALESREP_TBL(p_key).sales_credit_type_id
         ,G_SALESREP_TBL(p_key).person_id
         ,G_SALESREP_TBL(p_key).sales_tax_geocode
         ,G_SALESREP_TBL(p_key).sales_tax_inside_city_limits
   FROM RA_SALESREPS s
   WHERE SALESREP_ID = p_key;

   RETURN p_key;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'NO DATA FOUND IN LOAD SALESREP :'||TO_CHAR ( P_KEY ) ) ;
    END IF;
     IF G_SALESREP_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_SALESREP_TBL.DELETE(p_key);
     END IF;
    RAISE NO_DATA_FOUND;
  WHEN OTHERS THEN
     IF G_SALESREP_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_SALESREP_TBL.DELETE(p_key);
     END IF;
    OE_BULK_MSG_PUB.Add_Exc_Msg
      (   G_PKG_NAME
        , 'Load_Salesrep'
       );
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Load_Salesrep;

FUNCTION Load_Ship_From
( p_key                      IN NUMBER
)
RETURN NUMBER
IS
   l_addr_id                     NUMBER;
   l_location_code               VARCHAR2(40);
   l_addr_code                   VARCHAR2(40);
   l_addr1                       VARCHAR2(3200) := NULL;
   l_addr2                       VARCHAR2(3200) := NULL;
   l_addr3                       VARCHAR2(3200) := NULL;
   l_addr4                       VARCHAR2(3200) := NULL;
   l_addr_alt                    VARCHAR2(3200) := NULL;
   l_city                        VARCHAR2(3200) := NULL;
   l_county                      VARCHAR2(3200) := NULL;
   l_state                       VARCHAR2(3200) := NULL;
   l_zip                         VARCHAR2(3200) := NULL;
   l_province                    VARCHAR2(3200) := NULL;
   l_country                     VARCHAR2(3200) := NULL;
   l_region1                     VARCHAR2(3200) := NULL;
   l_region2                     VARCHAR2(3200) := NULL;
   l_region3                     VARCHAR2(3200) := NULL;
   l_return_status               VARCHAR2(30);
   --
   l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
   --
BEGIN

   -- Initially, ship from cache is only for EDI attributes therefore
   -- no need to have separate in parameters to indicate what kind of
   -- attributes need to be cached.
   IF G_SHIP_FROM_TBL.EXISTS(p_key)
   THEN

      RETURN p_key;

   END IF;


   BEGIN

    SELECT hu.location_id,hl.ece_tp_location_code, hl.location_code
     INTO l_addr_id, l_location_code,l_addr_code
     FROM hr_all_organization_units hu,
          hr_locations hl
    WHERE hl.location_id = hu.location_id
      AND hu.organization_id = p_key;

   EXCEPTION
     WHEN OTHERS THEN
       NULL;
                           IF l_debug_level  > 0 THEN
                               oe_debug_pub.add(  'UNABLE TO DERIVE SHIP FROM ADDR' ||' KEY :'||P_KEY ) ;
                           END IF;
   END;

   Get_Address(
           p_address_type_in      => 'HR_LOCATION',
           p_org_id_in            => OE_BULK_ORDER_PVT.G_ITEM_ORG,
           p_address_id_in        => l_addr_id,
           p_tp_location_code_in  => NULL,
           p_tp_translator_code_in => NULL,
           l_addr1                => l_addr1,
           l_addr2                => l_addr2,
           l_addr3                => l_addr3,
           l_addr4                => l_addr4,
           l_addr_alt             => l_addr_alt,
           l_city                 => l_city,
           l_county               => l_county,
           l_state                => l_state,
           l_zip                  => l_zip,
           l_province             => l_province,
           l_country              => l_country,
           l_region1              => l_region1,
           l_region2              => l_region2,
           l_region3              => l_region3,
           x_return_status        => l_return_status);

    IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

    G_SHIP_FROM_TBL(p_key).address1 := SUBSTR(l_addr1,0,30);
    G_SHIP_FROM_TBL(p_key).address2 := SUBSTR(l_addr2,0,30);
    G_SHIP_FROM_TBL(p_key).address3 := SUBSTR(l_addr3,0,30);
    G_SHIP_FROM_TBL(p_key).address4 := SUBSTR(l_addr4,0,30);
    G_SHIP_FROM_TBL(p_key).state := SUBSTR(l_state,0,30);
    G_SHIP_FROM_TBL(p_key).city := SUBSTR(l_city,0,30);
    G_SHIP_FROM_TBL(p_key).zip := SUBSTR(l_zip,0,30);
    G_SHIP_FROM_TBL(p_key).country := SUBSTR(l_country,0,30);
    G_SHIP_FROM_TBL(p_key).county := SUBSTR(l_county,0,30);
    G_SHIP_FROM_TBL(p_key).province := SUBSTR(l_province,0,240);
    G_SHIP_FROM_TBL(p_key).location := l_addr_code;
    G_SHIP_FROM_TBL(p_key).edi_location_code := l_location_code;

    RETURN p_key;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'NO DATA FOUND IN LOAD SHIP FROM :'||TO_CHAR ( P_KEY ) ) ;
    END IF;
     IF G_SHIP_FROM_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_SHIP_FROM_TBL.DELETE(p_key);
     END IF;
    RAISE NO_DATA_FOUND;
  WHEN OTHERS THEN
     IF G_SHIP_FROM_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_SHIP_FROM_TBL.DELETE(p_key);
     END IF;
    OE_BULK_MSG_PUB.Add_Exc_Msg
      (   G_PKG_NAME
        , 'Load_Ship_From'
       );
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Load_Ship_From;

FUNCTION Load_Price_List
( p_key                      IN NUMBER
)
RETURN NUMBER
IS
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN

   IF G_PRICE_LIST_TBL.EXISTS(p_key)
   THEN

      RETURN p_key;

   END IF;


    SELECT list_header_id
          ,name
          ,list_type_code
          ,start_date_active
          ,end_date_active
          ,currency_code
     INTO  G_PRICE_LIST_TBL(p_key).price_list_id
          ,G_PRICE_LIST_TBL(p_key).name
          ,G_PRICE_LIST_TBL(p_key).list_type_code
          ,G_PRICE_LIST_TBL(p_key).start_date_active
          ,G_PRICE_LIST_TBL(p_key).end_date_active
          ,G_PRICE_LIST_TBL(p_key).currency_code
     FROM  qp_list_headers_vl
    WHERE list_header_id = p_key;

   RETURN p_key;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'NO DATA FOUND IN LOAD PRICE LIST :'||TO_CHAR ( P_KEY ) ) ;
    END IF;
     IF G_PRICE_LIST_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_PRICE_LIST_TBL.DELETE(p_key);
     END IF;
    RAISE NO_DATA_FOUND;
  WHEN OTHERS THEN
     IF G_PRICE_LIST_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_PRICE_LIST_TBL.DELETE(p_key);
     END IF;
    OE_BULK_MSG_PUB.Add_Exc_Msg
      (   G_PKG_NAME
        , 'Load_Price_List'
       );
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Load_Price_List;

FUNCTION IS_CC_REQUIRED
( p_key     IN NUMBER
)
RETURN BOOLEAN
IS
BEGIN

    IF G_ORDER_TYPE_TBL(p_key).entry_credit_check_rule_id IS NOT NULL
    THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;

END IS_CC_REQUIRED;

FUNCTION Load_Loc_Info
( p_key                      IN NUMBER
)
RETURN NUMBER
IS
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN

   IF G_LOC_INFO_TBL.EXISTS(p_key)
   THEN

      RETURN p_key;

   END IF;

SELECT SU.SITE_USE_ID,
       SU.CUST_ACCT_SITE_ID,
       ACCT_SITE.CUST_ACCOUNT_ID,
       LOC.POSTAL_CODE,
       LOC_ASSIGN.LOC_ID,
       PARTY.PARTY_NAME,
       CUST_ACCT.ACCOUNT_NUMBER,
       CUST_ACCT.TAX_HEADER_LEVEL_FLAG ACCT_TAX_HEADER_LEVEL_FLAG,
       CUST_ACCT.TAX_ROUNDING_RULE ACCT_TAX_ROUNDING_RULE,
       LOC.STATE,
       SU.TAX_HEADER_LEVEL_FLAG SU_TAX_HEADER_LEVEL_FLAG,
       SU.TAX_ROUNDING_RULE SU_TAX_ROUNDING_RULE
INTO
    G_LOC_INFO_TBL(p_key).site_use_id,
    G_LOC_INFO_TBL(p_key).cust_acct_site_id,
    G_LOC_INFO_TBL(p_key).cust_account_id,
    G_LOC_INFO_TBL(p_key).postal_code,
    G_LOC_INFO_TBL(p_key).loc_id,
    G_LOC_INFO_TBL(p_key).party_name,
    G_LOC_INFO_TBL(p_key).account_number,
    G_LOC_INFO_TBL(p_key).acct_tax_header_level_flag,
    G_LOC_INFO_TBL(p_key).acct_tax_rounding_rule,
    G_LOC_INFO_TBL(p_key).state,
    G_LOC_INFO_TBL(p_key).tax_header_level_flag,
    G_LOC_INFO_TBL(p_key).tax_rounding_rule
FROM
       HZ_CUST_SITE_USES_ALL       SU ,
       HZ_CUST_ACCT_SITES          ACCT_SITE,
       HZ_PARTY_SITES              PARTY_SITE,
       HZ_LOCATIONS                LOC,
       HZ_LOC_ASSIGNMENTS          LOC_ASSIGN,
       HZ_PARTIES                  PARTY,
       HZ_CUST_ACCOUNTS            CUST_ACCT
WHERE  SU.SITE_USE_ID = p_key
  AND  SU.CUST_ACCT_SITE_ID  = acct_site.cust_acct_site_id
  and  acct_site.cust_account_id = cust_acct.cust_account_id
  and  cust_acct.party_id = party.party_id
  and  acct_site.party_site_id = party_site.party_site_id
  and  party_site.location_id = loc.location_id
  and  loc.location_id       = loc_assign.location_id
AND  NVL(acct_site.org_id,
         NVL(TO_NUMBER(DECODE(SUBSTRB(USERENV('CLIENT_INFO'),1 ,1), ' ',NULL,
              SUBSTRB(USERENV('CLIENT_INFO'), 1,10))),-99)) =
     NVL(loc_assign.org_id,
      NVL(TO_NUMBER(DECODE( SUBSTRB(USERENV('CLIENT_INFO'),1,1), ' ',NULL,
        SUBSTRB(USERENV('CLIENT_INFO'),1,10))), -99));

    RETURN p_key;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
     IF G_LOC_INFO_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_LOC_INFO_TBL.DELETE(p_key);
     END IF;
     RAISE NO_DATA_FOUND;
  WHEN OTHERS THEN
     IF G_LOC_INFO_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_LOC_INFO_TBL.DELETE(p_key);
     END IF;
    OE_BULK_MSG_PUB.Add_Exc_Msg
      (   G_PKG_NAME
        ,'Load_Loc_Info'
       );
  RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Load_Loc_Info;

FUNCTION Load_Tax_Attributes
( p_key                      IN VARCHAR2,
  p_tax_date                 IN DATE
)
RETURN NUMBER
IS
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN

     SELECT  V.AMOUNT_INCLUDES_TAX_FLAG,
               V.TAXABLE_BASIS TAXABLE_BASIS,
               V.TAX_CALCULATION_PLSQL_BLOCK,
               V.VAT_TAX_ID
     INTO      G_TAX_ATTRIBUTES_TBL(1).AMOUNT_INCLUDES_TAX_FLAG,
               G_TAX_ATTRIBUTES_TBL(1).TAXABLE_BASIS,
               G_TAX_ATTRIBUTES_TBL(1).TAX_CALCULATION_PLSQL_BLOCK,
               G_TAX_ATTRIBUTES_TBL(1).VAT_TAX_ID
     FROM      AR_VAT_TAX V
     WHERE    V.TAX_CODE = p_key
     AND       trunc(p_tax_date)
                BETWEEN trunc(V.START_DATE)
                AND NVL(trunc(V.END_DATE),trunc(p_tax_date))
     AND       V.TAX_CLASS = 'O'
     AND       NVL(V.ENABLED_FLAG,'Y') = 'Y'
     AND       V.SET_OF_BOOKS_ID = OE_BULK_ORDER_PVT.G_SOB_ID;

     RETURN 1;

END Load_Tax_Attributes;

FUNCTION Load_Person
( p_key                      IN NUMBER,
  p_tax_date                 IN DATE
)
RETURN NUMBER
IS
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN

   IF G_PERSON_TBL.EXISTS(p_key)
   AND p_tax_date between G_PERSON_TBL(p_key).start_date and G_PERSON_TBL(p_key).end_date
   THEN

      RETURN p_key;

   END IF;

         SELECT ASGN.ORGANIZATION_ID,
	         nvl(ASGN.EFFECTIVE_START_DATE,TO_DATE( '01011900', 'DDMMYYYY')),
             nvl(ASGN.EFFECTIVE_END_DATE,TO_DATE( '31122199', 'DDMMYYYY'))
         INTO 	G_PERSON_TBL(p_key).organization_id,
         		G_PERSON_TBL(p_key).start_date,
         		G_PERSON_TBL(p_key).end_date
         FROM PER_ALL_ASSIGNMENTS_F ASGN
         WHERE ASGN.PERSON_ID = p_key
         AND  NVL(ASGN.PRIMARY_FLAG, 'Y') = 'Y'
         AND    p_tax_date
            BETWEEN nvl(ASGN.EFFECTIVE_START_DATE,TO_DATE( '01011900'
             , 'DDMMYYYY'))
            AND nvl(ASGN.EFFECTIVE_END_DATE,TO_DATE( '31122199', 'DDMMYYYY'))
         AND ASSIGNMENT_TYPE = 'E';

    RETURN p_key;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
     IF G_PERSON_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_PERSON_TBL.DELETE(p_key);
     END IF;
     RAISE NO_DATA_FOUND;
  WHEN OTHERS THEN
     IF G_PERSON_TBL.EXISTS(p_key) THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'DELETE INVALID RECORD' ) ;
        END IF;
        G_PERSON_TBL.DELETE(p_key);
     END IF;
    OE_BULK_MSG_PUB.Add_Exc_Msg
      (   G_PKG_NAME
        ,'Load_Person'
       );
  RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Load_Person;

END OE_BULK_CACHE;
/
SHOW ERRORS PACKAGE BODY END OE_BULK_CACHE;
EXIT;
