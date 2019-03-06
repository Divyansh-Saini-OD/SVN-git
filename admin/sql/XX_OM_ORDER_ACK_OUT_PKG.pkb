SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_ORDER_ACK_OUT_PKG

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        : XX_OM_ORDER_ACK_OUT_PKG                             |
-- | RICE ID     : I0194_OrdAck                                        |
-- | Description : Package containing procedures to extract the Order  |
-- |               acknowledgement related data from the EBS.          |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A  01-Jan-2007    Shashi Kumar    Initial draft version     |
-- |                                                                   |
-- +===================================================================+
AS

g_entity_ref        VARCHAR2(1000) := 'HEADER_ID';
g_entity_ref_id     NUMBER;

-- +===================================================================+
-- | Name       : Log_Exceptions                                       |
-- | Description: This procedure will be responsible to store all      |
-- |              the exceptions occured during the procees using      |
-- |              global custom exception handling framework           |
-- |                                                                   |
-- | Parameters:  p_error_code , p_error_description                   |
-- |                                                                   |
-- | Returns :    None                                                 |
-- +===================================================================+

PROCEDURE log_exceptions(
                         p_error_code        IN  VARCHAR2
                        ,p_error_description IN  VARCHAR2
                        )

AS

-- Variables holding the values from the global exception framework package
----------------------------------------------------------------------------
x_errbuf                    VARCHAR2(1000);
x_retcode                   VARCHAR2(40);

BEGIN

   g_exception.p_error_code        := p_error_code;
   g_exception.p_error_description := p_error_description;
   g_exception.p_entity_ref        := g_entity_ref;
   g_exception.p_entity_ref_id     := g_entity_ref_id;

   BEGIN
      xx_om_global_exception_pkg.insert_exception(g_exception
                                                 ,x_errbuf
                                                 ,x_retcode
                                                 );
   END;

END log_exceptions;

-- +===================================================================+
-- | Name       : order_ack_header                                     |
-- |                                                                   |
-- | Description: This Procedure is used to derive and extract the     |
-- |              Order Header details.                                |
-- |                                                                   |
-- | Parameters : p_header_id                                          |
-- |              p_order_source                                       |
-- |              p_subtotal                                           |
-- |              p_fr_ord_tot                                         |
-- |              p_misc_ord_tot                                       |
-- |              p_tax_value                                          |
-- |              p_email                                              |
-- |              p_ftp                                                |
-- |              p_record_type                                        |
-- |              p_odemanddt                                          |
-- |              p_ofrom                                              |
-- | Returns    : None                                                 |
-- |                                                                   |
-- +===================================================================+

PROCEDURE order_ack_header(p_header_id     IN  NUMBER,
                           p_order_source  IN  VARCHAR2,
                           p_subtotal      OUT NUMBER,
                           p_fr_ord_tot    OUT NUMBER,
                           p_misc_ord_tot  OUT NUMBER,
                           p_tax_value     OUT NUMBER,
                           p_email         OUT VARCHAR2,
                           p_ftp           OUT VARCHAR2,
                           p_record_type   OUT VARCHAR2,
                           p_odemanddt     OUT VARCHAR2,
                           p_ofrom         OUT VARCHAR2
                          )
IS

ln_discount             NUMBER;
ln_charges              NUMBER;
ln_tax                  NUMBER;
ln_adj_amount           NUMBER;
ln_net_amount           NUMBER;
ln_fr_adj_amt           NUMBER;
ln_subtotal             NUMBER;
ln_misc_adj_amount      NUMBER;
ln_ofrom                NUMBER;
ln_header_id            NUMBER;
lc_order_source         VARCHAR2(100);
ln_subtotal             NUMBER;
ln_fr_ord_tot           NUMBER;
ln_misc_ord_tot         NUMBER;
ln_tax_value            NUMBER;
lc_email                VARCHAR2(100);
lc_ftp                  VARCHAR2(1000);
lc_record_type          VARCHAR2(1000);
lc_odemanddt            VARCHAR2(1000);
lc_ofrom                VARCHAR2(1000);

p_error_code            VARCHAR2(100);
p_error_description     VARCHAR2(4000);


CURSOR lcu_adj_amount(lc_line_type VARCHAR2) IS
SELECT OPA.adjusted_amount
FROM   oe_price_adjustments OPA
WHERE  OPA.list_line_type_code = lc_line_type             ---- check the list line type code Shashi
AND    OPA.header_id = p_header_id;

CURSOR lcu_tax_value IS
SELECT OLA.tax_value
FROM   oe_line_acks  OLA
WHERE  OLA.header_id = p_header_id;

CURSOR lcu_email IS
SELECT HP.email_address
FROM   hz_parties       HP,
       hz_cust_accounts HCA,
       oe_order_headers OOH
WHERE  OOH.sold_to_org_id = HCA.cust_account_id
AND    HCA.party_id       = HP.party_id
AND    OOH.header_id      = p_header_id;


CURSOR lcu_ofrom IS
SELECT COUNT(*) delivery_count
FROM   wsh_deliverables_v WDV,
       oe_order_headers_all OOHA
WHERE  OOHA.header_id  = WDV.source_header_id
AND    OOHA.header_id  = p_header_id
GROUP BY source_header_id;

BEGIN

   ln_header_id         :=   p_header_id;
   lc_order_source      :=   p_order_source;
   ln_subtotal          :=   p_subtotal;
   ln_fr_ord_tot        :=   p_fr_ord_tot;
   ln_misc_ord_tot      :=   p_misc_ord_tot;
   ln_tax_value         :=   p_tax_value;
   lc_email             :=   p_email;
   lc_ftp               :=   p_ftp;
   lc_record_type       :=   p_record_type;
   lc_odemanddt         :=   p_odemanddt;
   lc_ofrom             :=   p_ofrom;

   --   DR01 : Derive the order total from Order   --
   --   Call the procedure to get the order total  --

   oe_oe_totals_summary.order_totals(p_header_id,
                                     p_subtotal,
                                     ln_discount,
                                     ln_charges,
                                     ln_tax
                                    );

   -- DR02 : Derive the order total from Order   --
   --    lc_line_type := 'FREIGHT_CHARGE';

   FOR  cur_adj_amount IN lcu_adj_amount('FREIGHT_CHARGE') LOOP
      ln_fr_adj_amt := cur_adj_amount.adjusted_amount;
   END LOOP;

   p_fr_ord_tot :=  ln_subtotal -  ln_fr_adj_amt;

   -- DR03 : Derive the order total from Order   --
   -- lc_line_type := 'MISCELLANEOUS';

   FOR  cur_adj_amount IN lcu_adj_amount('MISCELLANEOUS') LOOP
       ln_misc_adj_amount := cur_adj_amount.adjusted_amount;
   END LOOP;

   p_misc_ord_tot :=  ln_subtotal -  ln_misc_adj_amount;

   --DR04 05 06 : Derive from OE_LINE_ACKS.TAX_VALUE --

   FOR  cur_tax_value IN lcu_tax_value LOOP
      p_tax_value := cur_tax_value.tax_value;
   END LOOP;

   --DR13 : Derive from HZ_PARTIES.EMAIL --
   FOR  cur_email IN lcu_email LOOP
       p_email := cur_email.email_address;
   END LOOP;

   --DR21 23 24 : Derive from HZ_PARTIES.EMAIL --

   IF p_order_source = 'SAGAWA' THEN

      p_record_type := 'AA';
      p_odemanddt := '222';
      p_ftp := 'FTP';

   END IF;

   --DR19 : Derive for record type --

   IF p_order_source = 'SAGAWA' THEN
      p_record_type := 'AA';
   END IF;

   -- DR20 : For multiple Deliveries --
   FOR  cur_ofrom IN lcu_ofrom LOOP
      ln_ofrom := cur_ofrom.delivery_count;

      IF  ln_ofrom > 1 then
         p_ofrom := '1';
      ELSE
         p_ofrom := 'S';
      END IF;
   END LOOP;

EXCEPTION WHEN OTHERS THEN

   g_entity_ref        := 'HEADER_ID ';
   g_entity_ref_id     := p_header_id;

   FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
   FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
   FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

   p_error_description:= FND_MESSAGE.GET;
   p_error_code       := 'ODP_OM_UNEXPECTED_ERR';

   log_exceptions(p_error_code,
                  p_error_description
                 );

END order_ack_header;

-- +===================================================================+
-- | Name       : order_ack_line                                       |
-- |                                                                   |
-- | Description: This Procedure is used to derive and extract the     |
-- |              Order Line details.                                  |
-- |                                                                   |
-- | Parameters : p_header_id                                          |
-- |              p_line_id                                            |
-- |              p_cross_item_type                                    |
-- |              p_unit_price                                         |
-- |              p_email                                              |
-- |              p_netamount                                          |
-- |              p_ship_qty                                           |
-- | Returns    : None                                                 |
-- |                                                                   |
-- +===================================================================+

PROCEDURE order_ack_line(p_header_id       IN  NUMBER,
                         p_line_id         IN  NUMBER,
                         p_cross_item_type OUT VARCHAR2,
                         p_unit_price      OUT NUMBER,
                         p_email           OUT VARCHAR2,
                         p_netamount       OUT NUMBER,
                         p_ship_qty        OUT NUMBER
                        )

AS

p_error_code            VARCHAR2(100);
p_error_description     VARCHAR2(4000);


CURSOR lcu_cross_itemtype IS
SELECT cross_reference_type
FROM   mtl_cross_references_v MCRV,
       mtl_system_items_b     MSIB,
       oe_order_lines_all     OOLA
WHERE  OOLA.inventory_item_id = MSIB.inventory_item_id
AND    OOLA.org_id            = MSIB.organization_id
AND    MCRV.inventory_item_id = MSIB.inventory_item_id
AND    OOLA.header_id         = p_header_id
AND    OOLA.line_id           = p_line_id;

CURSOR lcu_unit_price IS
SELECT OLA.unit_list_price
FROM   oe_line_acks OLA
WHERE  OLA.header_id = p_header_id;

CURSOR lcu_email IS
SELECT email_address
FROM   hz_parties       HP,
       hz_cust_accounts HCA,
       oe_order_headers OOH
WHERE  OOH.sold_to_org_id = HCA.cust_account_id
AND    HCA.party_id       = HP.party_id
AND    OOH.header_id      = p_header_id;

CURSOR lcu_net_amount IS
SELECT OLA.ordered_quantity * OLA.unit_selling_price  net_amount
FROM   oe_line_acks OLA
WHERE  header_id = p_header_id;

CURSOR lcu_ship_qty IS             --- change it
SELECT OOLA.shipping_quantity
FROM   oe_order_lines_all  OOLA
WHERE  OOLA.header_id = p_header_id
AND    OOLA.line_id   = p_line_id;

BEGIN

   --DR09   --

   FOR cur_ship_qty IN lcu_ship_qty LOOP
      p_ship_qty :=  cur_ship_qty.shipping_quantity;
   END LOOP;

   --DR10   --

   FOR cur_cross_item_type IN lcu_cross_itemtype LOOP
      p_cross_item_type :=  cur_cross_item_type.cross_reference_type;
   END LOOP;

   --DR11 --

   FOR cur_unit_price IN lcu_unit_price LOOP
      p_unit_price :=  cur_unit_price.unit_list_price;
   END LOOP;

   --DR13 : Derive from HZ_PARTIES.EMAIL --

   FOR  cur_email IN lcu_email LOOP
      p_email := cur_email.email_address;
   END LOOP;

   --DR16--
   --- Derive the Net amount ---

   FOR  cur_net_amount IN lcu_net_amount LOOP
      p_netamount := cur_net_amount.net_amount;
   END LOOP;

EXCEPTION WHEN OTHERS THEN

    g_entity_ref        := 'HEADER_ID';
    g_entity_ref_id     := p_header_id;

    FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

    p_error_description:= FND_MESSAGE.GET;
    p_error_code       := 'ODP_OM_UNEXPECTED_ERR';

    log_exceptions(p_error_code,
                   p_error_description
                  );

END order_ack_line;

END XX_OM_ORDER_ACK_OUT_PKG;
/

SHOW ERRORS;

--EXIT;