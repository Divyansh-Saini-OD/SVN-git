SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  XX_AP_INV_TRADE_DASHBOARD_PKG
PROMPT Program exits IF the creation IS NOT SUCCESSFUL
WHENEVER SQLERROR CONTINUE
--

CREATE OR REPLACE PACKAGE body XX_AP_INV_TRADE_DASHBOARD_PKG
AS
  -- +============================================================================================+
  --   Office Depot - Project Simplify
  --
  -- +============================================================================================+
  --   Name        : xx_ap_inv_trade_dashboard_pkg
  --   RICE ID     : 3522 AP Dashboard Report Package
  --   Solution ID : 213 Invoice Lines section
  --   Description : Dash board Query are build using pipeline Function for performance
  --   Change Record
  -- +============================================================================================+
  --  Version     Date         Author           Remarks
  --  =========   ===========  =============    ===============================================
  --  1.0         15-Nov-17    Priyam Parmar    Initial version
  --  1.0         03-Feb-18    Digamber
  --  1.1         16-Feb-18    Priyam           Code fix for NAIT-27229
  --  1.2         21-May-20    Mayur Palsokar   Modified XX_AP_INV_PAY_INQ and GET_INV_STATUSfor NAIT-61763
  -- +============================================================================================+
  ------------------------------------------------------------
  -- AP trade match Invoice and Payment Inquiry
  -- Function to get vendor assistant information
  ------------------------------------------------------------
FUNCTION vendor_assistant(
    p_assistant_code VARCHAR2)
  RETURN VARCHAR2
IS
  l_vendor_assistant xx_fin_translatevalues.target_value1%type;
BEGIN
  BEGIN
    SELECT b.target_value2
    INTO l_vendor_assistant
    FROM xx_fin_translatevalues b ,
      xx_fin_translatedefinition a
    WHERE a.translation_name = 'XX_AP_VENDOR_ASSISTANTS'
    AND b.translate_id       = a.translate_id
    AND b.enabled_flag       ='Y'
    AND sysdate BETWEEN b.start_date_active AND NVL(b.end_date_active,sysdate)
    AND b.target_value1 = p_assistant_code;
  EXCEPTION
  WHEN OTHERS THEN
    l_vendor_assistant := NULL;
  END ;
  RETURN l_vendor_assistant;
END vendor_assistant;
-----------------

FUNCTION GET_INV_STATUS(
    P_INVOICE_ID NUMBER)
  RETURN VARCHAR2
IS
  V_STATUS   VARCHAR2(1) :='N';
  INV_STATUS VARCHAR2(50):='N'; -- Added by Mayur for NAIT-61763
BEGIN
  XLA_SECURITY_PKG.SET_SECURITY_CONTEXT(602);
  /*
  SELECT 'Y'
  INTO v_status
  FROM dual
  WHERE NOT EXISTS
  (SELECT 'x'
  FROM ap_holds_all
  WHERE invoice_id         =p_invoice_id
  AND release_lookup_code IS NULL
  )
  AND EXISTS
  (SELECT 'x'
  FROM xla_events xev,
  xla_transaction_entities xte
  WHERE xte.source_id_int_1=p_invoice_id
  AND xte.application_id   = 200
  AND xte.entity_code      = 'AP_INVOICES'
  AND xev.entity_id        = xte.entity_id
  AND xev.event_type_code LIKE '%VALIDATED%'
  );
  RETURN(v_status);
  */
  -- Commented by Mayur for NAIT-61763
  /*Start: Added by Mayur for NAIT-61763 */
  BEGIN
    SELECT DECODE(APPS.AP_INVOICES_PKG.GET_APPROVAL_STATUS(I.INVOICE_ID, I.INVOICE_AMOUNT,I.PAYMENT_STATUS_FLAG,I.INVOICE_TYPE_LOOKUP_CODE), 'NEVER APPROVED', 'Never Validated', 'NEEDS REAPPROVAL', 'Needs Revalidation', 'CANCELLED', 'Cancelled', 'Validated') INVOICE_STATUS
    INTO INV_STATUS
    FROM AP_INVOICES_ALL I
    WHERE I.INVOICE_ID = P_INVOICE_ID
    AND NOT EXISTS
      (SELECT 'X'
      FROM AP_HOLDS_ALL
      WHERE INVOICE_ID         =P_INVOICE_ID
      AND RELEASE_LOOKUP_CODE IS NULL
      );
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    INV_STATUS := 'N';
  WHEN OTHERS THEN
    INV_STATUS := 'N';
  END;
  IF (INV_STATUS   = 'Never Validated' OR INV_STATUS = 'Needs Revalidation') THEN
    V_STATUS      := 'N';
  ELSIF INV_STATUS = 'Validated' THEN
    V_STATUS      := 'Y';
  END IF;
  RETURN(V_STATUS);
  /*End: Added by Mayur for NAIT-61763 */
EXCEPTION
WHEN OTHERS THEN
  RETURN(V_STATUS);
END GET_INV_STATUS;
------

FUNCTION xx_ap_hold_placed(
    p_invoice_id       NUMBER,
    p_line_location_id NUMBER,
    p_type             NUMBER)
  RETURN VARCHAR2
IS
  l_hold_concanated1 VARCHAR2(2000);
  l_hold_concanated2 VARCHAR2(2000);
  l_hold_concanated3 VARCHAR2(2000);
BEGIN
  /*  BEGIN
  SELECT
  CASE
  WHEN p_type= 1
  THEN listagg(H.hold_lookup_code,',') within GROUP(
  ORDER BY H.LAST_UPDATE_DATE)
  WHEN p_type=2
  THEN listagg(H.release_reason,', ') within GROUP(
  ORDER BY H.LAST_UPDATE_DATE)
  END hold_lookup_code1
  INTO l_hold_concanated1
  FROM ap_holds_all h
  WHERE h.invoice_id     =p_invoice_id--155670654
  AND h.line_Location_id =p_line_location_id;
  EXCEPTION
  WHEN OTHERS THEN
  l_hold_concanated1 := NULL;
  END;
  BEGIN
  SELECT
  CASE
  WHEN p_type= 1
  THEN listagg(H.hold_lookup_code,', ') within GROUP(
  ORDER BY H.LAST_UPDATE_DATE)
  WHEN p_type=2
  THEN listagg(H.release_reason,', ') within GROUP(
  ORDER BY H.LAST_UPDATE_DATE)
  END hold_lookup_code2
  INTO l_hold_concanated2
  FROM ap_holds_all h
  WHERE h.invoice_id      =p_invoice_id
  AND h.line_location_id IS NULL;
  EXCEPTION
  WHEN OTHERS THEN
  l_hold_concanated2 :=NULL;
  END;
  l_hold_concanated3 :=l_hold_concanated1||','||l_hold_concanated2;
  RETURN l_hold_concanated3;
  EXCEPTION
  WHEN OTHERS THEN
  l_hold_concanated3 :=NULL;*/
  IF p_type=1 THEN
    BEGIN
      SELECT listagg(h.hold_lookup_code,',') within GROUP(
      ORDER BY h.last_update_date)
      INTO l_hold_concanated1
      FROM ap_holds_all h
      WHERE h.invoice_id     =p_invoice_id       --155671003--155670654
      AND h.line_location_id =p_line_location_id;--7918806;;
    EXCEPTION
    WHEN OTHERS THEN
      l_hold_concanated1 := NULL;
    END;
    BEGIN
      SELECT listagg(h.hold_lookup_code,',') within GROUP(
      ORDER BY h.last_update_date)
      INTO l_hold_concanated2
      FROM ap_holds_all h
      WHERE h.invoice_id      =p_invoice_id--155671003----155670654
      AND h.line_location_id IS NULL;      --p_line_location_id;
    EXCEPTION
    WHEN OTHERS THEN
      l_hold_concanated2 := NULL;
    END;
  END IF;
  IF p_type=2 THEN
    BEGIN
      SELECT listagg(h.release_reason,',') within GROUP(
      ORDER BY h.last_update_date)
      INTO l_hold_concanated1
      FROM ap_holds_all h
      WHERE h.invoice_id     =p_invoice_id--155671003--155670654
      AND h.line_location_id =p_line_location_id
      AND h.release_reason  IS NOT NULL;--7918806;;
    EXCEPTION
    WHEN OTHERS THEN
      l_hold_concanated1 := NULL;
    END;
    BEGIN
      SELECT listagg(h.release_reason,',') within GROUP(
      ORDER BY h.last_update_date)
      INTO l_hold_concanated2
      FROM ap_holds_all h
      WHERE h.invoice_id      =p_invoice_id--155671003----155670654
      AND h.line_location_id IS NULL
      AND h.release_reason   IS NOT NULL;--p_line_location_id;
    EXCEPTION
    WHEN OTHERS THEN
      l_hold_concanated2 := NULL;
    END;
  END IF;
  l_hold_concanated3 :=l_hold_concanated1||','||l_hold_concanated2;
  RETURN l_hold_concanated3;
EXCEPTION
WHEN OTHERS THEN
  l_hold_concanated3 := NULL;
END xx_ap_hold_placed ;


------------------------------------------------------------
-- AP trade match Invoice and Payment Inquiry
--PIPE Function to get Invoice Header and Lines information
------------------------------------------------------------
FUNCTION xx_ap_inv_pay_inq(
    p_date_from      DATE ,
    p_date_to        DATE ,
    p_gl_date_from   DATE,
    p_gl_date_to     DATE,
    p_po_date_from   DATE,
    p_po_date_to     DATE,
    p_pay_date_from  DATE, --   Added by Mayur for NAIT-61763
    p_pay_date_to    DATE, --   Added by Mayur for NAIT-61763
    p_vendor_id      NUMBER,
    p_vendor_site_id NUMBER,
    p_assist_code    VARCHAR2,
    p_po_header_id   NUMBER,
    p_invoice_num    VARCHAR2,
    p_org_id         NUMBER,
    p_invoice_source VARCHAR2,
    p_invoice_type   VARCHAR2,
    p_invoice_status VARCHAR2,
    p_pay_status     VARCHAR2,
    p_payment_num    NUMBER,--CHECK THIS
    p_dropship       VARCHAR2,
    p_frontdoor      VARCHAR2,
    p_noncode        VARCHAR2,
    p_consignment    VARCHAR2,
    p_trade          VARCHAR2,
    p_newstore       VARCHAR2,
    p_replenishment  VARCHAR2,
    p_directimport   VARCHAR2,
    p_freight        VARCHAR2,
    p_tax            VARCHAR2,
    p_chargeback     VARCHAR2,
    p_excep_pricing  VARCHAR2,
    p_excep_qty      VARCHAR2,
    p_excep_freight  VARCHAR2,
    p_excep_oth      VARCHAR2 )
  RETURN xx_ap_inv_trade_dashboard_pkg.ap_inv_trade_header_db_ctt pipelined
IS
  -- CURSOR c_inv(p_dt_from DATE,p_dt_to DATE, p_date_usage VARCHAR2)  -- Commented by Mayur for NAIT-61763
  CURSOR c_inv(p_date_usage VARCHAR2) -- Added by Mayur for NAIT-61763
  IS
    SELECT
      /*+ LEADING (ai) INDEX(ss AP_SUPPLIER_SITES_UI) */
      tv.target_value2 vendorasistant,
      ai.invoice_id,
      s.segment1 sup_num,
      s.vendor_name sup_name,
      ss.vendor_site_code sup_site,
      ai.invoice_num invoice_num,
      ai.invoice_date,
      ai.invoice_amount,
      xx_ap_inv_trade_dashboard_pkg.f_freight_amount(ai.invoice_id) freight_amount,
      xx_ap_inv_trade_dashboard_pkg.f_tax_amount(ai.invoice_id) tax_amount,
      pha.segment1 po_num,
      pha.creation_date po_date,
      pterm.name payment_term,
      ai.terms_date,
      NVL(ps.discount_date,ps.due_date) due_date,
      ai.gl_date,
      ai.invoice_currency_code inv_cur_code,
      ai.payment_method_code payment_method,
      ai.pay_group_lookup_code pay_group,
      ai.source inv_source,
      ai.invoice_type_lookup_code invoice_type,
      p_invoice_status invoice_status,
      pha.attribute_category po_type,
      aca.check_number payment_numb , --aipa.PAYMENT_NUMB,
      aca.check_date payment_date,    -- Aipa.Payment_Date,
      ipa.amount amount_paid,
      (ps.gross_amount-ps.amount_remaining) pyamount_paid,
      DECODE(ps.payment_status_flag,'Y','Paid','N','Unpaid','P','Partially') payment_status,
      ai.payment_status_flag payment_status_code,
      NVL(ai.attribute12,'N') chargeback_flag
    FROM ap_supplier_sites_all ss ,
      ap_suppliers s,
      ap_invoices_all ai ,
      ap_terms pterm,
      xx_fin_translatevalues tv,
      xx_fin_translatedefinition td,
      ap_payment_schedules_all ps,
      po_headers_all pha,
      ap_invoice_payments_all ipa,
      ap_checks_all aca
    WHERE 1         =1
    AND p_date_usage='INV'
      /* AND ai.invoice_date BETWEEN to_date(TO_CHAR(p_dt_from)
      ||' 00:00:00','DD-MON-RR HH24:MI:SS')
      AND to_date(TO_CHAR(p_dt_to)
      ||' 23:59:59','DD-MON-RR HH24:MI:SS') */
      -- Commented by Mayur for NAIT-61763
      /*Start: Added by Mayur for NAIT-61763 */
    AND (((p_date_from IS NOT NULL
    AND p_date_to      IS NOT NULL)
    AND (ai.invoice_date BETWEEN to_date(TO_CHAR(p_date_from)
      ||' 00:00:00','DD-MON-RR HH24:MI:SS')
    AND to_date(TO_CHAR(p_date_to)
      ||' 23:59:59','DD-MON-RR HH24:MI:SS')))
    OR ((p_invoice_num IS NOT NULL)
    AND (p_date_from   IS NULL
    AND p_date_to      IS NULL))
    OR ((p_invoice_status IS NOT NULL AND p_invoice_status LIKE 'Y')
    AND ((ai.invoice_date BETWEEN to_date(TO_CHAR(p_date_from)
      ||' 00:00:00','DD-MON-RR HH24:MI:SS')
    AND to_date(TO_CHAR(p_date_to)
      ||' 23:59:59','DD-MON-RR HH24:MI:SS'))
    OR (s.vendor_id = p_vendor_id) ) ) )
      /*End: Added by Mayur for NAIT-61763 */
    AND ai.invoice_num NOT LIKE '%ODDBUIA%'
    AND ai.cancelled_date IS NULL
    AND ai.invoice_num LIKE NVL(p_invoice_num,ai.invoice_num)
      || '%'
    AND ai.org_id                                                   = NVL(p_org_id,ai.org_id)
    AND ai.source                                                   = NVL(p_invoice_source,ai.source)
    AND xx_ap_inv_trade_dashboard_pkg.get_inv_status(ai.invoice_id) = p_invoice_status
    AND ai.invoice_type_lookup_code                                 = NVL(p_invoice_type,ai.invoice_type_lookup_code)
    AND NVL(ai.payment_status_flag,'N')                             = NVL(p_pay_status,NVL(ai.payment_status_flag,'N'))
    AND s.vendor_id                                                 = NVL(p_vendor_id,s.vendor_id)
    AND ss.vendor_id                                                = s.vendor_id
    AND ss.vendor_site_id                                           = NVL(p_vendor_site_id,ss.vendor_site_id)
    AND ss.vendor_site_id                                           = ai.vendor_site_id
    AND ss.attribute6                                               = NVL(p_assist_code ,ss.attribute6)
    AND EXISTS
      (SELECT 1
      FROM xx_fin_translatevalues tv,
        xx_fin_translatedefinition td
      WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
      AND tv.translate_id       = td.translate_id
      AND tv.enabled_flag       = 'Y'
      AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
      AND tv.target_value1 = ss.attribute8
        ||''
      )
  AND pterm.term_id       = ai.terms_id
  AND td.translation_name = 'XX_AP_VENDOR_ASSISTANTS'
  AND tv.translate_id     = td.translate_id
  AND tv.enabled_flag     ='Y'
  AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
  AND tv.target_value1    = NVL(ss.attribute6,'Open')
  AND ps.invoice_id       =ai.invoice_id
  AND pha.po_header_id(+) = NVL(ai.po_header_id ,ai.quick_po_header_id)
  AND ( p_po_header_id   IS NULL
  OR ( p_po_header_id    IS NOT NULL
  AND pha.po_header_id    = p_po_header_id ) )
  AND ((pha.po_header_id IS NULL
  AND p_dropship
    ||p_frontdoor
    ||p_noncode
    ||p_consignment
    ||p_trade
    ||p_newstore
    ||p_replenishment
    ||p_directimport     = 'NNNNNNNN' )
  OR ( pha.po_header_id IS NOT NULL
  AND (pha.attribute_category LIKE DECODE(p_dropship,'Y',(nvl2('DropShip%','DropShip%',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category LIKE DECODE(p_frontdoor,'Y',(nvl2('FrontDoor%','FrontDoor%',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_noncode,'Y',(nvl2('Non-Code','Non-Code',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_consignment,'Y',(nvl2('Consignment','Consignment',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_trade,'Y',(nvl2('Trade','Trade',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_newstore,'Y',(nvl2('New Store','New Store',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_replenishment,'Y',(nvl2('Replenishment','Replenishment',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_directimport,'Y',(nvl2('Direct Import','Direct Import',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR NVL(pha.attribute_category,'X') =DECODE(p_dropship
    ||p_frontdoor
    ||p_noncode
    ||p_consignment
    ||p_trade
    ||p_newstore
    ||p_replenishment
    ||p_directimport,'NNNNNNNN',NVL(pha.attribute_category,'X'))) ))
  AND EXISTS
    (SELECT 1
    FROM ap_invoice_lines_all ail2
    WHERE 1             =1
    AND ail2.invoice_id = ai.invoice_id
      -- Fright Tax Exception
    AND ( ail2.line_type_lookup_code = DECODE(p_freight,'Y',(nvl2('FREIGHT','FREIGHT',ail2.line_type_lookup_code)), (nvl2('X','X',ail2.line_type_lookup_code)))
    OR ail2.line_type_lookup_code    = DECODE(p_tax,'Y',(nvl2('TAX','TAX',ail2.line_type_lookup_code)), (nvl2('X','X',ail2.line_type_lookup_code)))
      --OR ail2.line_type_lookup_code    =DECODE(p_freight||p_tax ,'NN',ail2.line_type_lookup_code) -- Commented by Mayur for NAIT-61763
    OR ail2.line_type_lookup_code =DECODE(p_freight
      ||p_tax ,'YY',ail2.line_type_lookup_code) -- Added by Mayur for NAIT-61763
      )
      -- Debit Memo Exception
    AND ( NVL(ai.attribute12,'N')              = 'N'
    OR ( NVL(ai.attribute12,'N')               = 'Y'
    AND ( ( p_excep_qty                        = 'Y'
    AND upper(SUBSTR(ail2.description,1,3))    ='QTY' )
    OR (p_excep_pricing                        = 'Y'
    AND upper(SUBSTR(ail2.description,1,3))    ='PRI' )
    OR (p_excep_freight                        = 'Y'
    AND upper(SUBSTR(ail2.description,1,3))    ='FRE' )
    OR (p_excep_oth                            = 'Y'
    AND ( upper(SUBSTR(ail2.description,1,3)) <> 'PRI'
    AND upper(SUBSTR(ail2.description,1,3))   <> 'QTY'
    AND upper(SUBSTR(ail2.description,1,3))   <> 'FRE'))) ) )
    )
  AND NVL(ai.attribute12,'N')   = DECODE(p_chargeback, 'Y', 'Y', NVL(ai.attribute12,'N'))
  AND ( NVL(ai.attribute12,'N') = 'Y'
  OR ( NVL(ai.attribute12,'N')  = 'N'
  AND EXISTS
    (SELECT 1
    FROM ap_holds_all b
    WHERE 1            =1
    AND b.invoice_id   = ai.invoice_id
    AND ( (p_excep_qty ='Y'
    AND upper(b.hold_lookup_code) LIKE 'QTY%')
    OR (p_excep_pricing ='Y'
    AND upper(hold_lookup_code) LIKE '%PRICE%')
    OR (p_excep_freight  ='Y'
    AND hold_lookup_code = 'OD Max Freight')
    OR (p_excep_oth      ='Y'
      -- AND upper(hold_lookup_code) IN ('OD Favorable', 'OD Line Variance', 'OD MISC HOLD', 'OD NO Receipt', 'OD PO NO Ref') ) ) Commented for Defect NAIT-27229
    AND hold_lookup_code IN ('OD Favorable', 'OD Line Variance', 'OD MISC HOLD', 'OD NO Receipt', 'OD PO NO Ref') ) )
    )
    -- First pass
  OR NOT EXISTS
    (SELECT 1 FROM ap_holds_all b WHERE 1 =1 AND b.invoice_id = ai.invoice_id
    ) ) )
  AND ipa.invoice_id(+) = ai.invoice_id
  AND aca.check_id(+)   = ipa.check_id
  AND (p_payment_num   IS NULL
  OR (p_payment_num    IS NOT NULL
  AND aca.check_number  = p_payment_num )) ;
  
  -- GL Date Parameter
  -- CURSOR c_gl(p_dt_from DATE,p_dt_to DATE, p_date_usage VARCHAR2)     -- Commented by Mayur for NAIT-61763
  CURSOR c_gl(p_date_usage VARCHAR2) -- Added by Mayur for NAIT-61763
  IS
    SELECT
      /*+ LEADING (ai) INDEX(ss AP_SUPPLIER_SITES_UI) */
      tv.target_value2 vendorasistant,
      ai.invoice_id,
      s.segment1 sup_num,
      s.vendor_name sup_name,
      ss.vendor_site_code sup_site,
      ai.invoice_num invoice_num,
      ai.invoice_date,
      ai.invoice_amount,
      xx_ap_inv_trade_dashboard_pkg.f_freight_amount(ai.invoice_id) freight_amount,
      xx_ap_inv_trade_dashboard_pkg.f_tax_amount(ai.invoice_id) tax_amount,
      pha.segment1 po_num,
      pha.creation_date po_date,
      pterm.name payment_term,
      ai.terms_date,
      NVL(ps.discount_date,ps.due_date) due_date,
      ai.gl_date,
      ai.invoice_currency_code inv_cur_code,
      ai.payment_method_code payment_method,
      ai.pay_group_lookup_code pay_group,
      ai.source inv_source,
      ai.invoice_type_lookup_code invoice_type,
      p_invoice_status invoice_status,
      pha.attribute_category po_type,
      aca.check_number payment_numb , --aipa.PAYMENT_NUMB,
      aca.check_date payment_date,    -- Aipa.Payment_Date,
      ipa.amount amount_paid,
      (ps.gross_amount-ps.amount_remaining) pyamount_paid,
      DECODE(ps.payment_status_flag,'Y','Paid','N','Unpaid','P','Partially') payment_status,
      ai.payment_status_flag payment_status_code,
      NVL(ai.attribute12,'N') chargeback_flag
    FROM ap_supplier_sites_all ss ,
      ap_suppliers s,
      ap_invoices_all ai ,
      ap_terms pterm,
      xx_fin_translatevalues tv,
      xx_fin_translatedefinition td,
      ap_payment_schedules_all ps,
      po_headers_all pha,
      ap_invoice_payments_all ipa,
      ap_checks_all aca
    WHERE 1         =1
    AND p_date_usage='GL'
      /*  AND ai.gl_date BETWEEN to_date(TO_CHAR(p_dt_from)
      ||' 00:00:00','DD-MON-RR HH24:MI:SS')
      AND to_date(TO_CHAR(p_dt_to)
      ||' 23:59:59','DD-MON-RR HH24:MI:SS')  */
      -- Commented by Mayur for NAIT-61763
      /*Start: Added by Mayur for NAIT-61763 */
    AND (((p_gl_date_from IS NOT NULL
    AND p_gl_date_to     IS NOT NULL)
    AND (ai.gl_date BETWEEN to_date(TO_CHAR(p_gl_date_from)
      ||' 00:00:00','DD-MON-RR HH24:MI:SS')
    AND to_date(TO_CHAR(p_gl_date_to)
      ||' 23:59:59','DD-MON-RR HH24:MI:SS')))
    OR ((p_invoice_status IS NOT NULL AND p_invoice_status LIKE 'Y') AND (p_gl_date_from IS NOT NULL
    AND p_gl_date_to     IS NOT NULL)
    AND ((ai.gl_date BETWEEN to_date(TO_CHAR(p_date_from)
      ||' 00:00:00','DD-MON-RR HH24:MI:SS')
    AND to_date(TO_CHAR(p_date_to)
      ||' 23:59:59','DD-MON-RR HH24:MI:SS')) ) ) )
      /*End: Added by Mayur for NAIT-61763 */
    AND ai.invoice_num NOT LIKE '%ODDBUIA%'
    AND ai.cancelled_date IS NULL
    AND ai.invoice_num LIKE NVL(p_invoice_num,ai.invoice_num)
      || '%'
    AND ai.org_id                                                   = NVL(p_org_id,ai.org_id)
    AND ai.source                                                   = NVL(p_invoice_source,ai.source)
    AND xx_ap_inv_trade_dashboard_pkg.get_inv_status(ai.invoice_id) =p_invoice_status
    AND ai.invoice_type_lookup_code                                 = NVL(p_invoice_type,ai.invoice_type_lookup_code)
    AND NVL(ai.payment_status_flag,'N')                             =NVL(p_pay_status,NVL(ai.payment_status_flag,'N'))
    AND s.vendor_id                                                 = NVL(p_vendor_id,s.vendor_id)
    AND ss.vendor_id                                                = s.vendor_id
    AND ss.vendor_site_id                                           = NVL(p_vendor_site_id,ss.vendor_site_id)
    AND ss.vendor_site_id                                           =ai.vendor_site_id
    AND ss.attribute6                                               = NVL(p_assist_code ,ss.attribute6)
    AND EXISTS
      (SELECT 1
      FROM xx_fin_translatevalues tv,
        xx_fin_translatedefinition td
      WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
      AND tv.translate_id       = td.translate_id
      AND tv.enabled_flag       = 'Y'
      AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
      AND tv.target_value1 = ss.attribute8
        ||''
      )
  AND pterm.term_id       = ai.terms_id
  AND td.translation_name = 'XX_AP_VENDOR_ASSISTANTS'
  AND tv.translate_id     = td.translate_id
  AND tv.enabled_flag     ='Y'
  AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
  AND tv.target_value1    = NVL(ss.attribute6,'Open')
  AND ps.invoice_id       =ai.invoice_id
  AND pha.po_header_id(+) = NVL(ai.po_header_id ,ai.quick_po_header_id)
  AND ( p_po_header_id   IS NULL
  OR ( p_po_header_id    IS NOT NULL
  AND pha.po_header_id    = p_po_header_id ) )
  AND ((pha.po_header_id IS NULL
  AND p_dropship
    ||p_frontdoor
    ||p_noncode
    ||p_consignment
    ||p_trade
    ||p_newstore
    ||p_replenishment
    ||p_directimport     = 'NNNNNNNN' )
  OR ( pha.po_header_id IS NOT NULL
  AND (pha.attribute_category LIKE DECODE(p_dropship,'Y',(nvl2('DropShip%','DropShip%',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category LIKE DECODE(p_frontdoor,'Y',(nvl2('FrontDoor%','FrontDoor%',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_noncode,'Y',(nvl2('Non-Code','Non-Code',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_consignment,'Y',(nvl2('Consignment','Consignment',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_trade,'Y',(nvl2('Trade','Trade',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_newstore,'Y',(nvl2('New Store','New Store',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_replenishment,'Y',(nvl2('Replenishment','Replenishment',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_directimport,'Y',(nvl2('Direct Import','Direct Import',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR NVL(pha.attribute_category,'X') =DECODE(p_dropship
    ||p_frontdoor
    ||p_noncode
    ||p_consignment
    ||p_trade
    ||p_newstore
    ||p_replenishment
    ||p_directimport,'NNNNNNNN',NVL(pha.attribute_category,'X'))) ))
  AND EXISTS
    (SELECT 1
    FROM ap_invoice_lines_all ail2
    WHERE 1             =1
    AND ail2.invoice_id = ai.invoice_id
      -- Fright Tax Exception
    AND ( ail2.line_type_lookup_code = DECODE(p_freight,'Y',(nvl2('FREIGHT','FREIGHT',ail2.line_type_lookup_code)), (nvl2('X','X',ail2.line_type_lookup_code)))
    OR ail2.line_type_lookup_code    = DECODE(p_tax,'Y',(nvl2('TAX','TAX',ail2.line_type_lookup_code)), (nvl2('X','X',ail2.line_type_lookup_code)))
      --OR ail2.line_type_lookup_code    =DECODE(p_freight||p_tax ,'NN',ail2.line_type_lookup_code) -- Commented by Mayur for NAIT-61763
    OR ail2.line_type_lookup_code =DECODE(p_freight
      ||p_tax ,'YY',ail2.line_type_lookup_code) -- Added by Mayur for NAIT-61763
      )
      -- Debit Memo Exception
    AND ( NVL(ai.attribute12,'N')              = 'N'
    OR ( NVL(ai.attribute12,'N')               = 'Y'
    AND ( ( p_excep_qty                        = 'Y'
    AND upper(SUBSTR(ail2.description,1,3))    ='QTY' )
    OR (p_excep_pricing                        = 'Y'
    AND upper(SUBSTR(ail2.description,1,3))    ='PRI' )
    OR (p_excep_freight                        = 'Y'
    AND upper(SUBSTR(ail2.description,1,3))    ='FRE' )
    OR (p_excep_oth                            = 'Y'
    AND ( upper(SUBSTR(ail2.description,1,3)) <> 'PRI'
    AND upper(SUBSTR(ail2.description,1,3))   <> 'QTY'
    AND upper(SUBSTR(ail2.description,1,3))   <> 'FRE')))
      /* OR ( NVL(UPPER(SUBSTR(AIL2.DESCRIPTION,1,3)),'X') =DECODE( :p_excep_qty
      ||:p_excep_pricing
      ||:p_excep_freight
      ||:p_excep_oth,'NNNN',NVL(UPPER(SUBSTR(AIL2.DESCRIPTION,1,3)),'X')) )*/
      ) )
    )
  AND NVL(ai.attribute12,'N')   = DECODE(p_chargeback, 'Y', 'Y', NVL(ai.attribute12,'N'))
  AND ( NVL(ai.attribute12,'N') = 'Y'
  OR ( NVL(ai.attribute12,'N')  = 'N'
  AND EXISTS
    (SELECT 1
    FROM ap_holds_all b
    WHERE 1            =1
    AND b.invoice_id   = ai.invoice_id
    AND ( (p_excep_qty ='Y'
    AND upper(b.hold_lookup_code) LIKE 'QTY%')
    OR (p_excep_pricing ='Y'
    AND upper(hold_lookup_code) LIKE '%PRICE%')
    OR (p_excep_freight  ='Y'
    AND hold_lookup_code = 'OD Max Freight')
    OR (p_excep_oth      ='Y'
      -- AND (hold_lookup_code <> 'QTY REC'
      --  And Hold_Lookup_Code   <> 'QTY ORD'
      -- And Hold_Lookup_Code   <> 'OD Max Freight'
      -- And Upper(Hold_Lookup_Code) Not Like '%PRICE%'
      ---  AND upper(hold_lookup_code) IN ('OD Favorable', 'OD Line Variance', 'OD MISC HOLD', 'OD NO Receipt', 'OD PO NO Ref') ) )
    AND hold_lookup_code IN ('OD Favorable', 'OD Line Variance', 'OD MISC HOLD', 'OD NO Receipt', 'OD PO NO Ref') ) )
    )
    /*OR ( NVL(b.hold_lookup_code,'X') =DECODE( :p_excep_qty
    ||:p_excep_pricing
    ||:p_excep_freight
    ||:p_excep_oth,'NNNN',NVL(b.hold_lookup_code,'X')) )*/
    -- )
    -- First pass
  OR NOT EXISTS
    (SELECT 1 FROM ap_holds_all b WHERE 1 =1 AND b.invoice_id = ai.invoice_id
    ) ) )
  AND ipa.invoice_id(+) = ai.invoice_id
  AND aca.check_id(+)   = ipa.check_id
  AND (p_payment_num   IS NULL
  OR (p_payment_num    IS NOT NULL
  AND aca.check_number  = p_payment_num )) ;
 
 -- PO Parameter
  -- CURSOR c_po(p_dt_from DATE,p_dt_to DATE, p_date_usage VARCHAR2)   -- Commented by Mayur for NAIT-61763
  CURSOR c_po(p_date_usage VARCHAR2) -- Added by Mayur for NAIT-61763
  IS
    --
    SELECT
      /*+ LEADING (pha) */
      tv.target_value2 vendorasistant,
      ai.invoice_id,
      aps.segment1 sup_num,
      aps.vendor_name sup_name,
      apsite.vendor_site_code sup_site,
      ai.invoice_num invoice_num,
      ai.invoice_date,
      ai.invoice_amount,
      xx_ap_inv_trade_dashboard_pkg.f_freight_amount(ai.invoice_id) freight_amount,
      xx_ap_inv_trade_dashboard_pkg.f_tax_amount(ai.invoice_id) tax_amount,
      pha.segment1 po_num,
      pha.creation_date po_date,
      pterm.name payment_term,
      ai.terms_date,
      NVL(py.discount_date,py.due_date) due_date,
      ai.gl_date,
      ai.invoice_currency_code inv_cur_code,
      ai.payment_method_code payment_method,
      ai.pay_group_lookup_code pay_group,
      ai.source inv_source,
      ai.invoice_type_lookup_code invoice_type,
      p_invoice_status invoice_status,
      pha.attribute_category po_type,
      aipa.payment_numb,
      aipa.payment_date,
      aipa.amount_paid,
      (py.gross_amount-py.amount_remaining) pyamount_paid,
      DECODE(py.payment_status_flag,'Y','Paid','N','Unpaid','P','Partially') payment_status,
      ai.payment_status_flag payment_status_code,
      NVL(ai.attribute12,'N') chargeback_flag
    FROM xx_fin_translatevalues tv,
      xx_fin_translatedefinition td,
      po_headers_all pha,
      ap_terms pterm,
      (SELECT aca.check_number payment_numb,
        aipa.invoice_id,
        aca.check_date payment_date,
        aipa.amount amount_paid
      FROM ap_checks_all aca,
        ap_invoice_payments_all aipa
      WHERE 1                     =1
      AND aca.check_id            =aipa.check_id
      AND NVL(aca.check_number,1) =NVL(p_payment_num,NVL(aca.check_number,1)) ---CHECK THIS
      )aipa,
    ap_supplier_sites_all apsite ,
    ap_suppliers aps,
    ap_invoices_all ai,
    ap_payment_schedules_all py
  WHERE 1         =1
  AND p_date_usage='PO'
    /* AND pha.creation_date BETWEEN to_date(TO_CHAR(p_dt_from)
    ||' 00:00:00','DD-MON-RR HH24:MI:SS')
    AND to_date(TO_CHAR(p_dt_to)
    ||' 23:59:59','DD-MON-RR HH24:MI:SS') */
    -- Commented by Mayur for NAIT-61763
    /*Start: Added by Mayur for NAIT-61763 */
  AND (((p_po_date_from IS NOT NULL
  AND p_po_date_to      IS NOT NULL)
  AND (pha.creation_date BETWEEN to_date(TO_CHAR(p_po_date_from)
    ||' 00:00:00','DD-MON-RR HH24:MI:SS')
  AND to_date(TO_CHAR(p_po_date_to)
    ||' 23:59:59','DD-MON-RR HH24:MI:SS')))
  OR (p_po_header_id IS NOT NULL))
    /*End: Added by Mayur for NAIT-61763 */
    --   AND PHA.SEGMENT1=:p_SEGMENT1
  AND (pha.attribute_category LIKE DECODE(p_dropship,'Y',(nvl2('DropShip%','DropShip%',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category LIKE DECODE(p_frontdoor,'Y',(nvl2('FrontDoor%','FrontDoor%',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_noncode,'Y',(nvl2('Non-Code','Non-Code',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_consignment,'Y',(nvl2('Consignment','Consignment',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_trade,'Y',(nvl2('Trade','Trade',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_newstore,'Y',(nvl2('New Store','New Store',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_replenishment,'Y',(nvl2('Replenishment','Replenishment',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_directimport,'Y',(nvl2('Direct Import','Direct Import',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR NVL(pha.attribute_category,'X') =DECODE(p_dropship
    ||p_frontdoor
    ||p_noncode
    ||p_consignment
    ||p_trade
    ||p_newstore
    ||p_replenishment
    ||p_directimport,'NNNNNNNN',NVL(pha.attribute_category,'X')))
  AND (( p_po_header_id IS NOT NULL
  AND pha.po_header_id   = p_po_header_id )
  OR p_po_header_id     IS NULL)
  AND (pha.po_header_id  = ai.po_header_id--NVL(ai.po_header_id , ai.quick_po_header_id)
  OR pha.po_header_id    = ai.quick_po_header_id)
  AND ai.org_id          = NVL(p_org_id,ai.org_id)
  AND py.invoice_id      =ai.invoice_id
  AND ai.invoice_num NOT LIKE '%ODDBUIA%'
  AND ai.cancelled_date IS NULL
  AND ai.invoice_num LIKE NVL(p_invoice_num,ai.invoice_num)
    || '%'
  AND ai.source                                                   = NVL(p_invoice_source,ai.source)
  AND xx_ap_inv_trade_dashboard_pkg.get_inv_status(ai.invoice_id) =p_invoice_status
  AND ai.invoice_type_lookup_code                                 = NVL(p_invoice_type,ai.invoice_type_lookup_code)
  AND NVL(ai.payment_status_flag,'N')                             =NVL(p_pay_status,NVL(ai.payment_status_flag,'N'))
  AND NVL(aipa.payment_numb,-1)                                   = NVL(p_payment_num,NVL(aipa.payment_numb,-1))
  AND aps.vendor_id                                               = NVL(p_vendor_id,aps.vendor_id)
  AND apsite.vendor_id                                            =aps.vendor_id
  AND apsite.vendor_site_id                                       = NVL(p_vendor_site_id,apsite.vendor_site_id)
  AND apsite.vendor_site_id                                       =ai.vendor_site_id
  AND apsite.attribute6                                           = NVL(p_assist_code ,apsite.attribute6)
  AND EXISTS
    (SELECT 1
    FROM xx_fin_translatevalues tv,
      xx_fin_translatedefinition td
    WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
    AND tv.translate_id       = td.translate_id
    AND tv.enabled_flag       = 'Y'
    AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
    AND tv.target_value1 = apsite.attribute8
      ||''
    )
  AND td.translation_name = 'XX_AP_VENDOR_ASSISTANTS'
  AND tv.translate_id     = td.translate_id
  AND tv.enabled_flag     ='Y'
  AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
  AND tv.target_value1          =NVL(apsite.attribute6,'Open')
  AND NVL(ai.attribute12,'N')   = DECODE(p_chargeback, 'Y', 'Y', NVL(ai.attribute12,'N'))
  AND ( NVL(ai.attribute12,'N') = 'Y'
  OR ( NVL(ai.attribute12,'N')  = 'N'
  AND EXISTS
    (SELECT 1
    FROM ap_holds_all b
    WHERE 1            =1
    AND b.invoice_id   = ai.invoice_id
    AND ( (p_excep_qty ='Y'
    AND upper(b.hold_lookup_code) LIKE 'QTY%')
    OR (p_excep_pricing ='Y'
    AND upper(hold_lookup_code) LIKE '%PRICE%')
    OR (p_excep_freight  ='Y'
    AND hold_lookup_code = 'OD Max Freight')
    OR (p_excep_oth      ='Y'
      -- AND upper(hold_lookup_code) IN ('OD Favorable', 'OD Line Variance', 'OD MISC HOLD', 'OD NO Receipt', 'OD PO NO Ref') ) ) Commented for Defect NAIT-27229
    AND hold_lookup_code IN ('OD Favorable', 'OD Line Variance', 'OD MISC HOLD', 'OD NO Receipt', 'OD PO NO Ref') ) )
    )
    -- First pass
  OR NOT EXISTS
    (SELECT 1 FROM ap_holds_all b WHERE 1 =1 AND b.invoice_id = ai.invoice_id
    ) ) )
  AND EXISTS
    (SELECT 1
    FROM ap_invoice_lines_all ail2
    WHERE 1             =1
    AND ail2.invoice_id = ai.invoice_id
      -- Fright Tax Exception
    AND ( ail2.line_type_lookup_code = DECODE(p_freight,'Y',(nvl2('FREIGHT','FREIGHT',ail2.line_type_lookup_code)), (nvl2('X','X',ail2.line_type_lookup_code)))
    OR ail2.line_type_lookup_code    = DECODE(p_tax,'Y',(nvl2('TAX','TAX',ail2.line_type_lookup_code)), (nvl2('X','X',ail2.line_type_lookup_code)))
      --OR ail2.line_type_lookup_code    =DECODE(p_freight||p_tax ,'NN',ail2.line_type_lookup_code) -- Commented by Mayur for NAIT-61763
    OR ail2.line_type_lookup_code =DECODE(p_freight
      ||p_tax ,'YY',ail2.line_type_lookup_code) -- Added by Mayur for NAIT-61763
      )
      -- Debit Memo Exception
    AND ( NVL(ai.attribute12,'N')              = 'N'
    OR ( NVL(ai.attribute12,'N')               = 'Y'
    AND ( ( p_excep_qty                        = 'Y'
    AND upper(SUBSTR(ail2.description,1,3))    ='QTY' )
    OR (p_excep_pricing                        = 'Y'
    AND upper(SUBSTR(ail2.description,1,3))    ='PRI' )
    OR (p_excep_freight                        = 'Y'
    AND upper(SUBSTR(ail2.description,1,3))    ='FRE' )
    OR (p_excep_oth                            = 'Y'
    AND ( upper(SUBSTR(ail2.description,1,3)) <> 'PRI'
    AND upper(SUBSTR(ail2.description,1,3))   <> 'QTY'
    AND upper(SUBSTR(ail2.description,1,3))   <> 'FRE'))) ) )
    )
  AND pterm.term_id      =ai.terms_id
  AND aipa.invoice_id(+) = ai.invoice_id ;
 
 /*Start: Added by Mayur for NAIT-61763*/
  -- Payment date parameter
  CURSOR c_pay(p_date_usage VARCHAR2)
  IS 
  SELECT
      /*+ LEADING (ai) INDEX(ss AP_SUPPLIER_SITES_UI) */
      tv.target_value2 vendorasistant,
      ai.invoice_id,
      s.segment1 sup_num,
      s.vendor_name sup_name,
      ss.vendor_site_code sup_site,
      ai.invoice_num invoice_num,
      ai.invoice_date,
      ai.invoice_amount,
      xx_ap_inv_trade_dashboard_pkg.f_freight_amount(ai.invoice_id) freight_amount,
      xx_ap_inv_trade_dashboard_pkg.f_tax_amount(ai.invoice_id) tax_amount,
      pha.segment1 po_num,
      pha.creation_date po_date,
      pterm.name payment_term,
      ai.terms_date,
      NVL(ps.discount_date,ps.due_date) due_date,
      ai.gl_date,
      ai.invoice_currency_code inv_cur_code,
      ai.payment_method_code payment_method,
      ai.pay_group_lookup_code pay_group,
      ai.source inv_source,
      ai.invoice_type_lookup_code invoice_type,
      p_invoice_status invoice_status,
      pha.attribute_category po_type,
      aca.check_number payment_numb , --aipa.PAYMENT_NUMB,
      aca.check_date payment_date,    -- Aipa.Payment_Date,
      ipa.amount amount_paid,
      (ps.gross_amount-ps.amount_remaining) pyamount_paid,
      DECODE(ps.payment_status_flag,'Y','Paid','N','Unpaid','P','Partially') payment_status,
      ai.payment_status_flag payment_status_code,
      NVL(ai.attribute12,'N') chargeback_flag
    FROM ap_supplier_sites_all ss ,
      ap_suppliers s,
      ap_invoices_all ai ,
      ap_terms pterm,
      xx_fin_translatevalues tv,
      xx_fin_translatedefinition td,
      ap_payment_schedules_all ps,
      po_headers_all pha,
      ap_invoice_payments_all ipa,
      ap_checks_all aca
    WHERE 1         =1
    AND p_date_usage='PAY'
    AND   (((p_pay_date_from IS NOT NULL
    AND p_pay_date_to      IS NOT NULL)
    AND (ai.invoice_date BETWEEN to_date(TO_CHAR(p_pay_date_from)
      ||' 00:00:00','DD-MON-RR HH24:MI:SS')
    AND to_date(TO_CHAR(p_pay_date_to)
      ||' 23:59:59','DD-MON-RR HH24:MI:SS')))
    OR (p_payment_num IS NOT NULL AND aca.check_number  = p_payment_num)
   -- OR (p_pay_status  IS NOT NULL AND p_pay_status  = 'Unpaid' )
	)
    AND ai.invoice_num NOT LIKE '%ODDBUIA%'
    AND ai.cancelled_date IS NULL
    AND ai.invoice_num LIKE NVL(p_invoice_num,ai.invoice_num)
      || '%'
    AND ai.org_id                                                   = NVL(p_org_id,ai.org_id)
    AND ai.source                                                   = NVL(p_invoice_source,ai.source)
    AND xx_ap_inv_trade_dashboard_pkg.get_inv_status(ai.invoice_id) = p_invoice_status
    AND ai.invoice_type_lookup_code                                 = NVL(p_invoice_type,ai.invoice_type_lookup_code)
    AND NVL(ai.payment_status_flag,'N')                             = NVL(p_pay_status,NVL(ai.payment_status_flag,'N'))
    AND s.vendor_id                                                 = NVL(p_vendor_id,s.vendor_id)
    AND ss.vendor_id                                                = s.vendor_id
    AND ss.vendor_site_id                                           = NVL(p_vendor_site_id,ss.vendor_site_id)
    AND ss.vendor_site_id                                           = ai.vendor_site_id
    AND ss.attribute6                                               = NVL(p_assist_code ,ss.attribute6)
    AND EXISTS
      (SELECT 1
      FROM xx_fin_translatevalues tv,
        xx_fin_translatedefinition td
      WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
      AND tv.translate_id       = td.translate_id
      AND tv.enabled_flag       = 'Y'
      AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
      AND tv.target_value1 = ss.attribute8
        ||''
      )
  AND pterm.term_id       = ai.terms_id
  AND td.translation_name = 'XX_AP_VENDOR_ASSISTANTS'
  AND tv.translate_id     = td.translate_id
  AND tv.enabled_flag     ='Y'
  AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
  AND tv.target_value1    = NVL(ss.attribute6,'Open')
  AND ps.invoice_id       =ai.invoice_id
  AND pha.po_header_id(+) = NVL(ai.po_header_id ,ai.quick_po_header_id)
  AND ( p_po_header_id   IS NULL
  OR ( p_po_header_id    IS NOT NULL
  AND pha.po_header_id    = p_po_header_id ) )
  AND ((pha.po_header_id IS NULL
  AND p_dropship
    ||p_frontdoor
    ||p_noncode
    ||p_consignment
    ||p_trade
    ||p_newstore
    ||p_replenishment
    ||p_directimport     = 'NNNNNNNN' )
  OR ( pha.po_header_id IS NOT NULL
  AND (pha.attribute_category LIKE DECODE(p_dropship,'Y',(nvl2('DropShip%','DropShip%',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category LIKE DECODE(p_frontdoor,'Y',(nvl2('FrontDoor%','FrontDoor%',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_noncode,'Y',(nvl2('Non-Code','Non-Code',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_consignment,'Y',(nvl2('Consignment','Consignment',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_trade,'Y',(nvl2('Trade','Trade',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_newstore,'Y',(nvl2('New Store','New Store',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_replenishment,'Y',(nvl2('Replenishment','Replenishment',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR pha.attribute_category          =DECODE(p_directimport,'Y',(nvl2('Direct Import','Direct Import',pha.attribute_category)), (nvl2('X','X',pha.attribute_category)))
  OR NVL(pha.attribute_category,'X') =DECODE(p_dropship
    ||p_frontdoor
    ||p_noncode
    ||p_consignment
    ||p_trade
    ||p_newstore
    ||p_replenishment
    ||p_directimport,'NNNNNNNN',NVL(pha.attribute_category,'X'))) ))
  AND EXISTS
    (SELECT 1
    FROM ap_invoice_lines_all ail2
    WHERE 1             =1
    AND ail2.invoice_id = ai.invoice_id
      -- Fright Tax Exception
    AND ( ail2.line_type_lookup_code = DECODE(p_freight,'Y',(nvl2('FREIGHT','FREIGHT',ail2.line_type_lookup_code)), (nvl2('X','X',ail2.line_type_lookup_code)))
    OR ail2.line_type_lookup_code    = DECODE(p_tax,'Y',(nvl2('TAX','TAX',ail2.line_type_lookup_code)), (nvl2('X','X',ail2.line_type_lookup_code)))
      --OR ail2.line_type_lookup_code    =DECODE(p_freight||p_tax ,'NN',ail2.line_type_lookup_code) -- Commented by Mayur for NAIT-61763
    OR ail2.line_type_lookup_code =DECODE(p_freight
      ||p_tax ,'YY',ail2.line_type_lookup_code) -- Added by Mayur for NAIT-61763
      )
      -- Debit Memo Exception
    AND ( NVL(ai.attribute12,'N')              = 'N'
    OR ( NVL(ai.attribute12,'N')               = 'Y'
    AND ( ( p_excep_qty                        = 'Y'
    AND upper(SUBSTR(ail2.description,1,3))    ='QTY' )
    OR (p_excep_pricing                        = 'Y'
    AND upper(SUBSTR(ail2.description,1,3))    ='PRI' )
    OR (p_excep_freight                        = 'Y'
    AND upper(SUBSTR(ail2.description,1,3))    ='FRE' )
    OR (p_excep_oth                            = 'Y'
    AND ( upper(SUBSTR(ail2.description,1,3)) <> 'PRI'
    AND upper(SUBSTR(ail2.description,1,3))   <> 'QTY'
    AND upper(SUBSTR(ail2.description,1,3))   <> 'FRE'))) ) )
    )
  AND NVL(ai.attribute12,'N')   = DECODE(p_chargeback, 'Y', 'Y', NVL(ai.attribute12,'N'))
  AND ( NVL(ai.attribute12,'N') = 'Y'
  OR ( NVL(ai.attribute12,'N')  = 'N'
  AND EXISTS
    (SELECT 1
    FROM ap_holds_all b
    WHERE 1            =1
    AND b.invoice_id   = ai.invoice_id
    AND ( (p_excep_qty ='Y'
    AND upper(b.hold_lookup_code) LIKE 'QTY%')
    OR (p_excep_pricing ='Y'
    AND upper(hold_lookup_code) LIKE '%PRICE%')
    OR (p_excep_freight  ='Y'
    AND hold_lookup_code = 'OD Max Freight')
    OR (p_excep_oth      ='Y'
      -- AND upper(hold_lookup_code) IN ('OD Favorable', 'OD Line Variance', 'OD MISC HOLD', 'OD NO Receipt', 'OD PO NO Ref') ) ) Commented for Defect NAIT-27229
    AND hold_lookup_code IN ('OD Favorable', 'OD Line Variance', 'OD MISC HOLD', 'OD NO Receipt', 'OD PO NO Ref') ) )
    )
    -- First pass
  OR NOT EXISTS
    (SELECT 1 FROM ap_holds_all b WHERE 1 =1 AND b.invoice_id = ai.invoice_id
    ) ) )
  AND ipa.invoice_id(+) = ai.invoice_id
  AND aca.check_id(+)   = ipa.check_id;
  
  /*End: Added by Mayur for NAIT-61763*/
  
type ap_inv_trade_header_db_ctt
IS
  TABLE OF xx_ap_inv_trade_dashboard_pkg.ap_inv_trade_header_db INDEX BY pls_integer;
  l_trade_header_db ap_inv_trade_header_db_ctt;
  l_error_count NUMBER;
  ex_dml_errors EXCEPTION;
  pragma exception_init(ex_dml_errors, -24381);
  n              NUMBER := 0;
  l_start_date   DATE;
  l_end_date     DATE;
  l_date_usage   VARCHAR2(5)  :='INV';
  l_invoice_num  VARCHAR2(50) :='X';
  l_po_num       VARCHAR2(50) :='X';
  l_po_header_id NUMBER;
  l_invoice_id   NUMBER;
  
BEGIN
  /*  -- Start: Commented by Mayur for NAIT-61763
  IF ( p_date_from IS NOT NULL AND p_date_to IS NOT NULL ) THEN
  l_start_date   := p_date_from;
  l_end_date     := p_date_to;
  l_date_usage   :='INV';
  END IF;
  IF ( p_gl_date_from IS NOT NULL AND p_gl_date_to IS NOT NULL ) THEN
  l_start_date      := p_gl_date_from;
  l_end_date        := p_gl_date_to;
  l_date_usage      :='GL';
  END IF;
  IF ( p_po_date_from IS NOT NULL AND p_po_date_to IS NOT NULL ) THEN
  l_start_date      := p_po_date_from;
  l_end_date        := p_po_date_to;
  l_date_usage      :='PO';
  END IF;
  -- End: Commented by Mayur for NAIT-61763*/
  
  /*Start: Added by Mayur for NAIT-61763*/
  

 IF  ((p_date_from IS NOT NULL
  AND p_date_to      IS NOT NULL)
    OR ((p_invoice_num IS NOT NULL)
    AND (p_date_from   IS NULL
    AND p_date_to      IS NULL))
    OR ((p_invoice_status IS NOT NULL AND p_invoice_status LIKE 'Y')
    AND ((p_date_from IS NOT NULL
  AND p_date_to      IS NOT NULL)
    OR (p_vendor_id IS NOT NULL) )))  THEN
    l_date_usage   := 'INV';
	
  END IF;
  
  IF   
  ( ((p_gl_date_from IS NOT NULL
    AND p_gl_date_to     IS NOT NULL))
    OR ((p_invoice_status IS NOT NULL AND p_invoice_status LIKE 'Y') AND (p_gl_date_from IS NOT NULL
    AND p_gl_date_to     IS NOT NULL) ) ) THEN
    l_date_usage      :='GL';
	
  END IF;
  
  IF (((p_po_date_from IS NOT NULL
  AND p_po_date_to      IS NOT NULL))
  OR (p_po_header_id IS NOT NULL)) THEN
    l_date_usage      :='PO';
		
  END IF;
	
  IF   ((p_pay_date_from IS NOT NULL
    AND p_pay_date_to      IS NOT NULL)
    OR (p_payment_num  IS NOT NULL)
    OR (p_pay_status  IS NOT NULL AND p_pay_status  = 'Unpaid' )) THEN
    l_date_usage       :='PAY';
	
  END IF;

  /*End: Added by Mayur for NAIT-61763*/
  IF l_trade_header_db.count > 0 THEN
    l_trade_header_db.delete;
  END IF;
  
   
  IF l_date_usage IN ('INV') THEN
    --   FOR i IN c_inv (l_start_date,l_end_date,l_date_usage)   -- Commented by Mayur for NAIT-61763
    FOR i IN c_inv (l_date_usage) -- Commented by Mayur for NAIT-61763
    LOOP
  
      l_trade_header_db(n).vendorasistant      := i.vendorasistant;
      l_trade_header_db(n).sup_num             := i.sup_num;
      l_trade_header_db(n).sup_name            := i.sup_name;
      l_trade_header_db(n).sup_site            := i.sup_site;
      l_trade_header_db(n).invoice_num         := i.invoice_num;
      l_trade_header_db(n).invoice_id          := i.invoice_id;
      l_trade_header_db(n).invoice_date        := i.invoice_date;
      l_trade_header_db(n).invoice_amount      := i.invoice_amount;
      l_trade_header_db(n).freight_amount      := i.freight_amount;
      l_trade_header_db(n).tax_amount          := i.tax_amount;
      l_trade_header_db(n).po_num              := i.po_num;
      l_trade_header_db(n).payment_term        := i.payment_term;
      l_trade_header_db(n).terms_date          := i.terms_date;
      l_trade_header_db(n).due_date            := i.due_date;
      l_trade_header_db(n).gl_date             := i.gl_date;
      l_trade_header_db(n).inv_cur_code        := i.inv_cur_code;
      l_trade_header_db(n).payment_method      := i.payment_method;
      l_trade_header_db(n).pay_group           := i.pay_group;
      l_trade_header_db(n).inv_source          := i.inv_source;
      l_trade_header_db(n).po_type             := i.po_type;
      l_trade_header_db(n).invoice_status      := i.invoice_status;
      l_trade_header_db(n).payment_numb        := i.payment_numb;
      l_trade_header_db(n).payment_date        := i.payment_date;
      l_trade_header_db(n).amount_paid         := i.amount_paid;
      l_trade_header_db(n).payment_status      := i.payment_status;
      l_trade_header_db(n).payment_status_code := i.payment_status_code;
      l_trade_header_db(n).chargeback_flag     := i.chargeback_flag;
      l_trade_header_db(n).invoice_type        := i.invoice_type;
      n                                        :=n+1;
    END LOOP;
  END IF;
  IF l_date_usage = 'GL' THEN
    --   FOR i IN c_gl (l_start_date,l_end_date,l_date_usage)  -- Commented by Mayur for NAIT-61763
    FOR i IN c_gl (l_date_usage) -- Added by Mayur for NAIT-61763
    LOOP
	

      l_trade_header_db(n).vendorasistant := i.vendorasistant;
      ---L_TRADE_HEADER_DB(N).OU_NAME               := I.OU_NAME ;
      l_trade_header_db(n).sup_num             := i.sup_num;
      l_trade_header_db(n).sup_name            := i.sup_name;
      l_trade_header_db(n).sup_site            := i.sup_site;
      l_trade_header_db(n).invoice_num         := i.invoice_num;
      l_trade_header_db(n).invoice_id          := i.invoice_id;
      l_trade_header_db(n).invoice_date        := i.invoice_date;
      l_trade_header_db(n).invoice_amount      := i.invoice_amount;
      l_trade_header_db(n).freight_amount      := i.freight_amount;
      l_trade_header_db(n).tax_amount          := i.tax_amount;
      l_trade_header_db(n).po_num              := i.po_num;
      l_trade_header_db(n).payment_term        := i.payment_term;
      l_trade_header_db(n).terms_date          := i.terms_date;
      l_trade_header_db(n).due_date            := i.due_date;
      l_trade_header_db(n).gl_date             := i.gl_date;
      l_trade_header_db(n).inv_cur_code        := i.inv_cur_code;
      l_trade_header_db(n).payment_method      := i.payment_method;
      l_trade_header_db(n).pay_group           := i.pay_group;
      l_trade_header_db(n).inv_source          := i.inv_source;
      l_trade_header_db(n).po_type             := i.po_type;
      l_trade_header_db(n).invoice_status      := i.invoice_status;
      l_trade_header_db(n).payment_numb        := i.payment_numb;
      l_trade_header_db(n).payment_date        := i.payment_date;
      l_trade_header_db(n).amount_paid         := i.amount_paid;
      l_trade_header_db(n).payment_status      := i.payment_status;
      l_trade_header_db(n).payment_status_code := i.payment_status_code;
      l_trade_header_db(n).chargeback_flag     := i.chargeback_flag;
      l_trade_header_db(n).invoice_type        := i.invoice_type;
      n                                        :=n+1;
    END LOOP;
  END IF;
  IF l_date_usage = 'PO' THEN
    --  FOR i IN c_po (l_start_date,l_end_date,l_date_usage)  -- Commented by Mayur for NAIT-61763
    FOR i IN c_po (l_date_usage) -- Added by Mayur for NAIT-61763
    LOOP
      l_trade_header_db(n).vendorasistant      := i.vendorasistant;
      l_trade_header_db(n).sup_num             := i.sup_num;
      l_trade_header_db(n).sup_name            := i.sup_name;
      l_trade_header_db(n).sup_site            := i.sup_site;
      l_trade_header_db(n).invoice_num         := i.invoice_num;
      l_trade_header_db(n).invoice_id          := i.invoice_id;
      l_trade_header_db(n).invoice_date        := i.invoice_date;
      l_trade_header_db(n).invoice_amount      := i.invoice_amount;
      l_trade_header_db(n).freight_amount      := i.freight_amount;
      l_trade_header_db(n).tax_amount          := i.tax_amount;
      l_trade_header_db(n).po_num              := i.po_num;
      l_trade_header_db(n).payment_term        := i.payment_term;
      l_trade_header_db(n).terms_date          := i.terms_date;
      l_trade_header_db(n).due_date            := i.due_date;
      l_trade_header_db(n).gl_date             := i.gl_date;
      l_trade_header_db(n).inv_cur_code        := i.inv_cur_code;
      l_trade_header_db(n).payment_method      := i.payment_method;
      l_trade_header_db(n).pay_group           := i.pay_group;
      l_trade_header_db(n).inv_source          := i.inv_source;
      l_trade_header_db(n).po_type             := i.po_type;
      l_trade_header_db(n).invoice_status      := i.invoice_status;
      l_trade_header_db(n).payment_numb        := i.payment_numb;
      l_trade_header_db(n).payment_date        := i.payment_date;
      l_trade_header_db(n).amount_paid         := i.amount_paid;
      l_trade_header_db(n).payment_status      := i.payment_status;
      l_trade_header_db(n).payment_status_code := i.payment_status_code;
      l_trade_header_db(n).chargeback_flag     := i.chargeback_flag;
      l_trade_header_db(n).invoice_type        := i.invoice_type;
      n                                        :=n+1;
    END LOOP;
  END IF;
  /*Start: Added by Mayur for NAIT-61763*/
  IF l_date_usage IN ('PAY') THEN
    FOR i         IN c_pay (l_date_usage)
    LOOP
      l_trade_header_db(n).vendorasistant      := i.vendorasistant;
      l_trade_header_db(n).sup_num             := i.sup_num;
      l_trade_header_db(n).sup_name            := i.sup_name;
      l_trade_header_db(n).sup_site            := i.sup_site;
      l_trade_header_db(n).invoice_num         := i.invoice_num;
      l_trade_header_db(n).invoice_id          := i.invoice_id;
      l_trade_header_db(n).invoice_date        := i.invoice_date;
      l_trade_header_db(n).invoice_amount      := i.invoice_amount;
      l_trade_header_db(n).freight_amount      := i.freight_amount;
      l_trade_header_db(n).tax_amount          := i.tax_amount;
      l_trade_header_db(n).po_num              := i.po_num;
      l_trade_header_db(n).payment_term        := i.payment_term;
      l_trade_header_db(n).terms_date          := i.terms_date;
      l_trade_header_db(n).due_date            := i.due_date;
      l_trade_header_db(n).gl_date             := i.gl_date;
      l_trade_header_db(n).inv_cur_code        := i.inv_cur_code;
      l_trade_header_db(n).payment_method      := i.payment_method;
      l_trade_header_db(n).pay_group           := i.pay_group;
      l_trade_header_db(n).inv_source          := i.inv_source;
      l_trade_header_db(n).po_type             := i.po_type;
      l_trade_header_db(n).invoice_status      := i.invoice_status;
      l_trade_header_db(n).payment_numb        := i.payment_numb;
      l_trade_header_db(n).payment_date        := i.payment_date;
      l_trade_header_db(n).amount_paid         := i.amount_paid;
      l_trade_header_db(n).payment_status      := i.payment_status;
      l_trade_header_db(n).payment_status_code := i.payment_status_code;
      l_trade_header_db(n).chargeback_flag     := i.chargeback_flag;
      l_trade_header_db(n).invoice_type        := i.invoice_type;
      n                                        :=n+1;
    END LOOP;
  END IF;
  /*End: Added by Mayur for NAIT-61763*/
  IF l_trade_header_db.count > 0 THEN
    FOR i IN l_trade_header_db.first .. l_trade_header_db.last
    LOOP
      pipe row ( l_trade_header_db(i) ) ;
    END LOOP;
  END IF;
	
  RETURN;
EXCEPTION
WHEN ex_dml_errors THEN
  l_error_count := sql%bulk_exceptions.count;
  dbms_output.put_line('Number of failures: ' || l_error_count);
  FOR i IN 1 .. l_error_count
  LOOP
    dbms_output.put_line ( 'Error: ' || i || ' Array Index: ' || sql%bulk_exceptions(i).error_index || ' Message: ' || sqlerrm(-sql%bulk_exceptions(i).error_code) ) ;
  END LOOP;
END xx_ap_inv_pay_inq;
------------------------------------------------------------
-- AP trade match Invoice and Payment Inquiry
--Fucntion to get Frieght amount on Invoice
------------------------------------------------------------
FUNCTION f_freight_amount(
    p_invoice_id NUMBER)
  RETURN NUMBER
IS
  v_freight_amount NUMBER;
BEGIN
  SELECT NVL(SUM (a.amount),0)
  INTO v_freight_amount
  FROM ap_invoice_lines_all a
  WHERE a.invoice_id         =p_invoice_id
  AND a.line_type_lookup_code='FREIGHT';
  RETURN v_freight_amount;
EXCEPTION
WHEN no_data_found THEN
  v_freight_amount:=0;
  RETURN v_freight_amount;
END f_freight_amount;
------------------------------------------------------------
-- AP trade match Invoice and Payment Inquiry
--Fucntion to get TAX amount on Invoice
------------------------------------------------------------
FUNCTION f_tax_amount(
    p_invoice_id NUMBER)
  RETURN NUMBER
IS
  v_tax_amount NUMBER;
BEGIN
  SELECT NVL(SUM (a.amount),0)
  INTO v_tax_amount
  FROM ap_invoice_lines_all a
  WHERE a.invoice_id         =p_invoice_id
  AND a.line_type_lookup_code='TAX';
  RETURN v_tax_amount;
EXCEPTION
WHEN no_data_found THEN
  v_tax_amount:=0;
  RETURN v_tax_amount;
END f_tax_amount;
----------------------------
FUNCTION xx_ap_inv_pay_line_inq(
    p_invoice_id NUMBER,
    p_chrg_flag  VARCHAR2)
  RETURN xx_ap_inv_trade_dashboard_pkg.ap_inv_trade_line_db_ctt pipelined
AS
  /*CURSOR C_inv_line(l_invoice_id NUMBER)
  IS
  SELECT
  /*+ leading(ail) */
  /*  aia.invoice_num,
  AIL.LINE_NUMBER LINE_NUMBER ,
  ail.line_type_lookup_code line_type ,
  --AIDADM.LINE_TYPE_LOOKUP_CODE LINE_TYPE1,
  AIL.AMOUNT INVOICE_LINE_AMOUNT ,
  AIL.DESCRIPTION DESCRIPTION ,
  PH.SEGMENT1 PO_NUMBER ,
  pl.line_num po_line_num,
  msi1.segment1 sku,
  msi1.description SKU_DESCRIPTION,
  AIL.UNIT_MEAS_LOOKUP_CODE UOM,
  PLLA.QUANTITY PO_QUANTITY ,
  PLLA.QUANTITY_RECEIVED RECEIVED_QUANTITY,
  AIL.QUANTITY_INVOICED INVOICED_QUANTITY,
  PL.UNIT_PRICE PO_PRICE ,
  Ail.Unit_Price Invoice_Price,
  SUBSTR(hld.HOLDS_PLACED,1,1999) holds_placed ,
  hld.hold_date HOLD_DATE,
  --  HLD.REL_DATE ,
  -- HLD.SYS_REL_DATE,
  -- Decode( Hld.Rel_By_Name,'APPSMGR','APPSMGR', Hld.Party_Name)
  Hld.Rel_By Hold_Released_By,--Rel_by
  /* CASE
  WHEN HLD.REL_BY_NAME = 'APPSMGR'
  THEN HLD.SYS_REL_DATE--HLD.REL_DATE
  ELSE HLD.REL_DATE
  END*/
  /*  hld.release_date hold_release_date,
  SUBSTR(HLD.HOLD_RELEASE_REASON,1,1999) HOLD_RELEASE_REASON,
  ail.attribute11 charge_acc_reason_code,
  */
  /*  GCC.SEGMENT1
  ||'.'
  ||GCC.SEGMENT2
  ||'.'
  ||GCC.SEGMENT3
  ||'.'
  ||GCC.SEGMENT4
  ||'.'
  ||GCC.SEGMENT5
  ||'.'
  ||GCC.SEGMENT6
  ||'.'
  ||GCC.SEGMENT7 CHARGE_ACCOUNT ,*/
  /*   acc.CHARGE_ACCOUNT,
  NVL(aia.attribute12,'N') CHARGE_BACK_LINE ,
  (SELECT xacv.answer_code
  FROM xx_ap_cost_variance xacv
  WHERE xacv.po_line_id = pl.po_line_id
  -- AND xacv.invoice_id   = ail.invoice_id
  --  AND xacv.line_num     = ail.line_number
  AND rownum < 2
  ) ANSWER_CODE,
  AIL.ATTRIBUTE5 ORIG_INV_LINE_NUM
  FROM ap_invoices_all aia,
  ap_invoice_lines_all ail,
  (SELECT msi.inventory_item_id,
  msi.SEGMENT1,
  msi.description
  FROM mtl_system_items_b msi
  WHERE msi.organization_id =441
  ) msi1,
  (SELECT aid.invoice_id,
  aid.invoice_line_number ,
  MIN(GCC.SEGMENT1
  ||'.'
  ||GCC.SEGMENT2
  ||'.'
  ||GCC.SEGMENT3
  ||'.'
  ||GCC.SEGMENT4
  ||'.'
  ||GCC.SEGMENT5
  ||'.'
  ||GCC.SEGMENT6
  ||'.'
  ||gcc.segment7 ) charge_account,
  MIN( DECODE (aid.line_type_lookup_code,'ITEM','ITEM','ACCRUAL','ITEM','NONREC_TAX','TAX','FREIGHT','FREIGHT','MISCLINOUS')) line_type
  FROM ap_invoice_distributions_all aid,
  gl_code_combinations gcc
  WHERE aid.dist_code_combination_id = gcc.code_combination_id
  -- and aid.invoice_id in (155569442,155731064)
  GROUP BY aid.invoice_id,
  aid.invoice_line_number
  ) Acc,
  /* (
  SELECT H.INVOICE_ID ,
  (Select Max(Hl.Last_Update_Date)
  FROM AP_HOLDS_ALL HL
  Where Hl.Invoice_Id= H.Invoice_Id
  AND Hl.release_lookup_code is null
  ) SYS_REL_DATE,
  H.LINE_LOCATION_ID,
  MAX(NVL(FU.DESCRIPTION,FU.USER_NAME)) PARTY_NAME,
  MAX(FU.PERSON_PARTY_ID) PERSON_PARTY_ID,
  Max(Hold_Date) Hold_Date,
  Max(Decode(Nvl(H.Release_Lookup_Code,'X'),'X',Null,Fu.User_Name)) Rel_By_Name,
  Max(Decode(Nvl(H.Release_Lookup_Code,'X'),'X',Null,Fu.User_Id)) Rel_By,
  --    MAX(Decode(Nvl(H.Release_Lookup_Code,'X'),'X',Null,H.LAST_UPDATE_DATE )) REL_DATE,
  Max(H.LAST_UPDATE_DATE ) REL_DATE,
  --      XX_AP_INV_TRADE_DASHBOARD_PKG.XX_AP_HOLD_PLACED(H.INVOICE_ID,H.LINE_LOCATION_ID,1) HOLDS_PLACED,
  listagg(H.hold_lookup_code,', ') within GROUP(
  ORDER BY H.LAST_UPDATE_DATE) HOLDS_PLACED,
  --  XX_AP_INV_TRADE_DASHBOARD_PKG.XX_AP_HOLD_PLACED(H.INVOICE_ID,H.LINE_LOCATION_ID,2) HOLD_RELEASE_REASON
  listagg(release_reason,', ') within GROUP(
  ORDER BY H.LAST_UPDATE_DATE) HOLD_RELEASE_REASON
  FROM ap_holds_all h,
  FND_USER FU
  --    HZ_PARTIES HP
  Where 1               =1
  -- AND H.Invoice_Id = 155671003
  AND hold_lookup_code IS NOT NULL
  AND fu.user_id        =h.last_updated_by
  --    AND FU.PERSON_PARTY_ID=HP.PARTY_ID(+)
  Group By Invoice_Id,
  Line_Location_Id ) hld,*/
  /*(SELECT b.invoice_id,
  Line_Location_Id,
  Hold_Date,
  HOLDS_PLACED,
  Rel_date,
  (SELECT NVL(SUBSTR(Fu.Description,1,100),Fu.User_Name)
  FROM fnd_user fu
  WHERE fu.user_id = Rel_by
  ) Rel_by
  FROM
  (SELECT Invoice_Id,
  Line_Location_Id,
  Max(Hold_Date) Hold_Date,
  MAX(
  CASE
  WHEN H.Release_Lookup_Code IS NOT NULL
  THEN last_update_date
  ELSE NULL
  END)Rel_Date ,
  MAX(
  CASE
  WHEN H.Release_Lookup_Code IS NOT NULL
  THEN H.last_updated_by
  ELSE NULL
  END)Rel_by ,
  listagg(H.hold_lookup_code,', ') within GROUP(
  ORDER BY H.INVOICE_ID,LINE_LOCATION_ID) HOLDS_PLACED,
  Listagg(Release_Reason,', ') Within GROUP(
  ORDER BY H.Invoice_Id,Line_Location_Id) Hold_Release_Reason
  FROM Ap_Holds_All H
  GROUP BY H.Invoice_Id,
  H.Line_Location_Id
  ) Hld,
  po_headers_all ph ,
  po_lines_all pl,
  PO_LINE_LOCATIONS_ALL PLLA
  WHERE 1                       =1
  AND aia.invoice_id            = P_INVOICE_ID
  AND ail.invoice_id            = aia.invoice_id
  AND hld.invoice_id (+)        = ail.invoice_id
  AND msi1.INVENTORY_ITEM_ID(+) = NVL(AIL.INVENTORY_ITEM_ID,-1)
  AND hld.line_location_id(+)   = ail.po_line_location_id
  AND ph.po_header_id(+)        = NVL(aia.po_header_id,aia.quick_po_header_id)
  AND pl.po_header_id(+)        = NVL(aia.po_header_id,aia.quick_po_header_id)
  AND PL.PO_LINE_ID (+)         = AIL.PO_LINE_ID
  AND plla.line_location_id(+)  = ail.po_line_location_id
  --and aidadm.invoice_id(+)                                                                                                                      = ail.invoice_id
  -- and aidadm.invoice_line_number(+)                                                                                                             = ail.line_number
  --AND DECODE (AIL.LINE_TYPE_LOOKUP_CODE,'FREIGHT','FREIGHT','ITEM','ACCRUAL','TAX','NONREC_TAX',NVL(AIL.LINE_TYPE_LOOKUP_CODE,'MISCELLANEOUS')) =NVL(aidadm.LINE_TYPE_LOOKUP_CODE,'MISCELLANEOUS')
  --AND gcc.code_combination_id (+)                                                                                                               = aidadm.dist_code_combination_id
  AND acc.invoice_id(+)          = ail.invoice_id
  AND acc.invoice_line_number(+) = ail.line_number
  AND acc.line_type(+)           = ail.line_type_Lookup_code
  ORDER BY ail.Invoice_id,
  Ail.Line_Number;
  */
  CURSOR c_inv_line(l_invoice_id NUMBER)
  IS
    SELECT
      /*+ leading(ail) */
      aia.invoice_num,
      ail.line_number line_number ,
      ail.line_type_lookup_code line_type ,
      --AIDADM.LINE_TYPE_LOOKUP_CODE LINE_TYPE1,
      ail.amount invoice_line_amount ,
      ail.description description ,
      ph.segment1 po_number ,
      pl.line_num po_line_num,
      msi1.segment1 sku,
      msi1.description sku_description,
      ail.unit_meas_lookup_code uom,
      plla.quantity po_quantity ,
      plla.quantity_received received_quantity,
      ail.quantity_invoiced invoiced_quantity,
      pl.unit_price po_price ,
      ail.unit_price invoice_price,
      SUBSTR(hld.holds_placed,1,1999) holds_placed ,
      hld.hold_date hold_date,
      hld.rel_by_name hold_released_by,--Rel_by
      hld.rel_date hold_release_date,
      SUBSTR(hld.hold_release_reason,1,1999) hold_release_reason,
      ail.attribute11 charge_acc_reason_code,
      acc.charge_account,
      NVL(aia.attribute12,'N') charge_back_line ,
      (SELECT xacv.answer_code
      FROM xx_ap_cost_variance xacv
      WHERE xacv.po_line_id = pl.po_line_id
      AND xacv.invoice_id   = ail.invoice_id
      AND xacv.line_num     = ail.line_number
      AND rownum            < 2
      ) answer_code,
    ail.attribute5 orig_inv_line_num
  FROM ap_invoices_all aia,
    ap_invoice_lines_all ail,
    (SELECT msi.inventory_item_id,
      msi.segment1,
      msi.description
    FROM mtl_system_items_b msi
    WHERE msi.organization_id =441
    ) msi1,
    (SELECT aid.invoice_id,
      aid.invoice_line_number ,
      MIN(gcc.segment1
      ||'.'
      ||gcc.segment2
      ||'.'
      ||gcc.segment3
      ||'.'
      ||gcc.segment4
      ||'.'
      ||gcc.segment5
      ||'.'
      ||gcc.segment6
      ||'.'
      ||gcc.segment7 ) charge_account,
      MIN( DECODE (aid.line_type_lookup_code,'ITEM','ITEM','ACCRUAL','ITEM','NONREC_TAX','TAX','FREIGHT','FREIGHT','MISCELLANEOUS')) line_type
    FROM ap_invoice_distributions_all aid,
      gl_code_combinations gcc
    WHERE aid.dist_code_combination_id = gcc.code_combination_id
    GROUP BY aid.invoice_id,
      aid.invoice_line_number
    ) acc,
    (SELECT a.invoice_id ,
      a.line_location_id,
      MAX(a.hold_date) hold_date,
      listagg(a.holds_placed,', ') within GROUP(
    ORDER BY a.invoice_id,a.line_location_id) holds_placed,
      listagg(a.release_reason,', ') within GROUP(
    ORDER BY a.invoice_id,a.line_location_id) hold_release_reason,
      MAX(a.rel_date) rel_date,
      MAX (a.rel_by) rel_by_name
    FROM
      (SELECT h.invoice_id,
        h.line_location_id ,
        MAX(hold_date) hold_date,
        MAX(
        CASE
          WHEN h.release_lookup_code IS NOT NULL
          THEN last_update_date
          ELSE NULL
        END)rel_date ,
        MAX(
        CASE
          WHEN h.release_lookup_code IS NOT NULL
            -- Then H.Last_Updated_By
          THEN
            (SELECT NVL(SUBSTR(FU.DESCRIPTION,1,100),FU.USER_NAME)
            FROM fnd_user fu
            WHERE fu.user_id = h.last_updated_by
            )
          ELSE NULL
        END)rel_by ,
        listagg(h.hold_lookup_code,', ') within GROUP(
      ORDER BY h.invoice_id,line_location_id) holds_placed,
        listagg(DECODE(NVL(line_location_id,-1),-1,h.release_reason),', ') within GROUP(
      ORDER BY H.INVOICE_ID,LINE_LOCATION_ID) RELEASE_REASON
      FROM ap_holds_all h
      WHERE 1               =1
      AND line_location_id IS NOT NULL
      GROUP BY h.invoice_id,
        line_location_id
      UNION ALL
      SELECT H.INVOICE_ID,
        MAX(AL.LINE_LOCATION_ID) LINE_LOCATION_ID ,
        MAX(h.hold_date) hold_date,
        MAX(
        CASE
          WHEN H.RELEASE_LOOKUP_CODE IS NOT NULL
          THEN h.last_update_date
          ELSE NULL
        END)rel_date ,
        MAX(
        CASE
          WHEN h.release_lookup_code IS NOT NULL
            --THEN H.last_updated_by
          THEN
            (SELECT NVL(SUBSTR(FU.DESCRIPTION,1,100),FU.USER_NAME)
            FROM fnd_user fu
            WHERE fu.user_id = h.last_updated_by
            )
          ELSE NULL
        END)REL_BY ,
        LISTAGG(DECODE(NVL(H.LINE_LOCATION_ID,-1),-1,H.HOLD_LOOKUP_CODE),', ') within GROUP(
      ORDER BY H.INVOICE_ID,h.LINE_LOCATION_ID) HOLDS_PLACED ,
        LISTAGG(DECODE(NVL(H.LINE_LOCATION_ID,-1),-1,H.RELEASE_REASON),', ') within GROUP(
      ORDER BY H.INVOICE_ID,h.LINE_LOCATION_ID) RELEASE_REASON
      FROM AP_HOLDS_ALL H,
        (SELECT AIL.INVOICE_ID,
          MAX(AIL.PO_LINE_LOCATION_ID) LINE_LOCATION_ID
        FROM AP_INVOICE_LINES_ALL AIL
        GROUP BY ail.INVOICE_ID
        )AL
      WHERE 1=1
        --AND h.INVOICE_ID = 157565040
      AND h.invoice_id = al.invoice_id
      GROUP BY H.INVOICE_ID
      ) a
    WHERE 1=1 --a.invoice_Id = 157565040
    GROUP BY a.INVOICE_ID,
      a.line_location_id
    ) hld,
    po_headers_all ph ,
    po_lines_all pl,
    po_line_locations_all plla
  WHERE 1                        =1
  AND aia.invoice_id             = p_invoice_id
  AND ail.invoice_id             = aia.invoice_id
  AND hld.invoice_id (+)         = ail.invoice_id
  AND msi1.inventory_item_id(+)  = NVL(ail.inventory_item_id,-1)
  AND hld.line_location_id(+)    = ail.po_line_location_id
  AND ph.po_header_id(+)         = NVL(aia.po_header_id,aia.quick_po_header_id)
  AND pl.po_header_id(+)         = NVL(aia.po_header_id,aia.quick_po_header_id)
  AND pl.po_line_id (+)          = ail.po_line_id
  AND plla.line_location_id(+)   = ail.po_line_location_id
  AND acc.invoice_id(+)          = ail.invoice_id
  AND acc.invoice_line_number(+) = ail.line_number
  AND acc.line_type(+)           = ail.line_type_lookup_code
  ORDER BY ail.invoice_id,
    ail.line_number;
  CURSOR c_chbk_line(l_invoice_id NUMBER)
  IS
    SELECT
      /*+ leading(ail) */
      aia.invoice_num,
      ail.line_number line_number ,
      ail.line_type_lookup_code line_type ,
      --AIDADM.LINE_TYPE_LOOKUP_CODE LINE_TYPE1,
      ail.amount invoice_line_amount ,
      ail.description description ,
      ph.segment1 po_number ,
      pl.line_num po_line_num,
      msi1.segment1 sku,
      msi1.description sku_description,
      ail.unit_meas_lookup_code uom,
      plla.quantity po_quantity ,
      plla.quantity_received received_quantity,
      ail.quantity_invoiced invoiced_quantity,
      pl.unit_price po_price ,
      ail.unit_price invoice_price,
      NULL holds_placed ,
      --      SUBSTR(hld.holds_placed,1,1999)holds_placed ,
      NULL hold_date,
      --     hld.hold_date HOLD_DATE,
      NULL hold_released_by,
      --       DECODE( HLD.REL_BY_NAME,'APPSMGR','APPSMGR', HLD.PARTY_NAME) HOLD_RELEASED_BY,--Rel_by
      NULL hold_release_date,
      --     CASE
      --       WHEN HLD.REL_BY_NAME = 'APPSMGR'
      --      THEN HLD.SYS_REL_DATE--HLD.REL_DATE
      --     ELSE HLD.REL_DATE
      --     END hold_release_date,
      NULL hold_release_reason,
      --    SUBSTR(HLD.HOLD_RELEASE_REASON,1,1999) HOLD_RELEASE_REASON,
      ail.attribute11 charge_acc_reason_code,
      /*  GCC.SEGMENT1
      ||'.'
      ||GCC.SEGMENT2
      ||'.'
      ||GCC.SEGMENT3
      ||'.'
      ||GCC.SEGMENT4
      ||'.'
      ||GCC.SEGMENT5
      ||'.'
      ||GCC.SEGMENT6
      ||'.'
      ||GCC.SEGMENT7 CHARGE_ACCOUNT ,*/
      acc.charge_account,
      NVL(aia.attribute12,'N') charge_back_line ,
      (SELECT xacv.answer_code
      FROM xx_ap_cost_variance xacv
      WHERE xacv.po_line_id = pl.po_line_id
        -- AND xacv.invoice_id   = ail.invoice_id
        --  AND xacv.line_num     = ail.line_number
      AND rownum < 2
      ) answer_code,
    ail.attribute5 orig_inv_line_num
  FROM ap_invoices_all aia,
    ap_invoice_lines_all ail,
    (SELECT msi.inventory_item_id,
      msi.segment1,
      msi.description
    FROM mtl_system_items_b msi
    WHERE msi.organization_id =441
    ) msi1,
    (SELECT aid.invoice_id,
      aid.invoice_line_number ,
      MIN(gcc.segment1
      ||'.'
      ||gcc.segment2
      ||'.'
      ||gcc.segment3
      ||'.'
      ||gcc.segment4
      ||'.'
      ||gcc.segment5
      ||'.'
      ||gcc.segment6
      ||'.'
      ||gcc.segment7 ) charge_account,
      MIN( DECODE (aid.line_type_lookup_code,'ITEM','ITEM','ACCRUAL','ITEM','NONREC_TAX','TAX','FREIGHT','FREIGHT','MISCLINOUS')) line_type
    FROM ap_invoice_distributions_all aid,
      gl_code_combinations gcc
    WHERE aid.dist_code_combination_id = gcc.code_combination_id
      -- and aid.invoice_id in (155569442,155731064)
    GROUP BY aid.invoice_id,
      aid.invoice_line_number
    ) acc,
    -- AP_INVOICE_DISTRIBUTIONS_ALL AIDADM ,
    -- gl_code_combinations gcc,
    --XX_AP_COST_VARIANCE XACV,
    /*   (
    SELECT H.INVOICE_ID ,
    (SELECT MAX(HL.LAST_UPDATE_DATE)
    FROM AP_HOLDS_ALL HL
    WHERE HL.INVOICE_ID= H.INVOICE_ID
    ) SYS_REL_DATE,
    H.LINE_LOCATION_ID,
    MAX(HP.PARTY_NAME) PARTY_NAME,
    MAX(FU.PERSON_PARTY_ID) PERSON_PARTY_ID,
    MAX(HOLD_DATE) HOLD_DATE,
    MAX(FU.USER_NAME) REL_BY_NAME,
    MAX(FU.USER_ID) REL_BY,
    MAX(H.LAST_UPDATE_DATE) REL_DATE,
    listagg(H.hold_lookup_code,', ') within GROUP(
    ORDER BY H.LAST_UPDATE_DATE) HOLDS_PLACED,
    listagg(hold_reason,', ') within GROUP(
    ORDER BY H.LAST_UPDATE_DATE) HOLD_RELEASE_REASON
    FROM ap_holds_all h,
    FND_USER FU,
    HZ_PARTIES HP
    WHERE 1               =1
    AND hold_lookup_code IS NOT NULL
    AND fu.user_id        =h.last_updated_by
    AND FU.PERSON_PARTY_ID=HP.PARTY_ID(+)
    GROUP BY INVOICE_ID,
    line_location_id
    ) hld,*/
    po_headers_all ph ,
    po_lines_all pl,
    po_line_locations_all plla
  WHERE 1            =1
  AND aia.invoice_id = p_invoice_id
  AND ail.invoice_id = aia.invoice_id
    --  AND hld.invoice_id (+)        = ail.invoice_id
  AND msi1.inventory_item_id(+) = NVL(ail.inventory_item_id,-1)
    --  AND hld.line_location_id(+)   = ail.po_line_location_id
  AND ph.po_header_id(+)       = NVL(aia.po_header_id,aia.quick_po_header_id)--
  AND pl.po_header_id (+)      = NVL(aia.po_header_id,aia.quick_po_header_id)--
  AND pl.po_line_id (+)        = ail.po_line_id                              --
  AND plla.line_location_id(+) = ail.po_line_location_id                     --
    --and aidadm.invoice_id(+)                                                                                                                      = ail.invoice_id
    -- and aidadm.invoice_line_number(+)                                                                                                             = ail.line_number
    --AND DECODE (AIL.LINE_TYPE_LOOKUP_CODE,'FREIGHT','FREIGHT','ITEM','ACCRUAL','TAX','NONREC_TAX',NVL(AIL.LINE_TYPE_LOOKUP_CODE,'MISCELLANEOUS')) =NVL(aidadm.LINE_TYPE_LOOKUP_CODE,'MISCELLANEOUS')
    --AND gcc.code_combination_id (+)                                                                                                               = aidadm.dist_code_combination_id
  AND acc.invoice_id(+)          = ail.invoice_id
  AND acc.invoice_line_number(+) = ail.line_number
  AND acc.line_type(+)           = ail.line_type_lookup_code
  ORDER BY ail.invoice_id,
    ail.line_number;
type ap_inv_trade_line_db_ctt
IS
  TABLE OF xx_ap_inv_trade_dashboard_pkg.ap_inv_trade_line_db INDEX BY pls_integer;
  l_trade_line_db ap_inv_trade_line_db_ctt;
  l_error_count NUMBER;
  ex_dml_errors EXCEPTION;
  pragma exception_init(ex_dml_errors, -24381);
  n              NUMBER := 0;
  l_start_date   DATE;
  l_end_date     DATE;
  l_date_usage   VARCHAR2(5)  :='INV';
  l_invoice_num  VARCHAR2(50) :='X';
  l_po_num       VARCHAR2(50) :='X';
  l_po_header_id NUMBER;
BEGIN
  IF l_trade_line_db.count > 0 THEN
    l_trade_line_db.delete;
  END IF;
  IF p_chrg_flag ='N' THEN
    FOR j IN c_inv_line ( p_invoice_id)
    LOOP
      --  NULL;
      ------------------------- Line details
      l_trade_line_db(n).line_number            := j.line_number;
      l_trade_line_db(n).line_type              := j.line_type;
      l_trade_line_db(n).po_number              := j.po_number;
      l_trade_line_db(n).po_line_num            := j.po_line_num;
      l_trade_line_db(n).invoice_line_amount    := j.invoice_line_amount;
      l_trade_line_db(n).description            := j.description;
      l_trade_line_db(n).sku                    := j.sku;
      l_trade_line_db(n).sku_description        := j.sku_description;
      l_trade_line_db(n).uom                    := j.uom;
      l_trade_line_db(n).po_quantity            := j.po_quantity;
      l_trade_line_db(n).received_quantity      := j.received_quantity;
      l_trade_line_db(n).invoiced_quantity      := j.invoiced_quantity;
      l_trade_line_db(n).po_price               := j.po_price;
      l_trade_line_db(n).invoice_price          := j.invoice_price;
      l_trade_line_db(n).holds_placed           := j.holds_placed;
      l_trade_line_db(n).hold_date              := j.hold_date;
      l_trade_line_db(n).hold_released_by       := j.hold_released_by;
      l_trade_line_db(n).hold_release_date      := j.hold_release_date;
      l_trade_line_db(n).hold_release_reason    := j.hold_release_reason;
      l_trade_line_db(n).charge_acc_reason_code := j.charge_acc_reason_code;
      l_trade_line_db(n).charge_account         := j.charge_account;
      l_trade_line_db(n).charge_back_line       := j.charge_back_line;
      l_trade_line_db(n).answer_code            := j.answer_code;
      l_trade_line_db(n).orig_inv_line_num      := j.orig_inv_line_num;
      n                                         := n+1;
    END LOOP;
  ELSE
    FOR j IN c_chbk_line ( p_invoice_id)
    LOOP
      --  NULL;
      ------------------------- Line details
      l_trade_line_db(n).line_number            := j.line_number;
      l_trade_line_db(n).line_type              := j.line_type;
      l_trade_line_db(n).po_number              := j.po_number;
      l_trade_line_db(n).po_line_num            := j.po_line_num;
      l_trade_line_db(n).invoice_line_amount    := j.invoice_line_amount;
      l_trade_line_db(n).description            := j.description;
      l_trade_line_db(n).sku                    := j.sku;
      l_trade_line_db(n).sku_description        := j.sku_description;
      l_trade_line_db(n).uom                    := j.uom;
      l_trade_line_db(n).po_quantity            := j.po_quantity;
      l_trade_line_db(n).received_quantity      := j.received_quantity;
      l_trade_line_db(n).invoiced_quantity      := j.invoiced_quantity;
      l_trade_line_db(n).po_price               := j.po_price;
      l_trade_line_db(n).invoice_price          := j.invoice_price;
      l_trade_line_db(n).holds_placed           := j.holds_placed;
      l_trade_line_db(n).hold_date              := j.hold_date;
      l_trade_line_db(n).hold_released_by       := j.hold_released_by;
      l_trade_line_db(n).hold_release_date      := j.hold_release_date;
      l_trade_line_db(n).hold_release_reason    := j.hold_release_reason;
      l_trade_line_db(n).charge_acc_reason_code := j.charge_acc_reason_code;
      l_trade_line_db(n).charge_account         := j.charge_account;
      l_trade_line_db(n).charge_back_line       := j.charge_back_line;
      l_trade_line_db(n).answer_code            := j.answer_code;
      l_trade_line_db(n).orig_inv_line_num      := j.orig_inv_line_num;
      n                                         := n+1;
    END LOOP;
  END IF;
  IF l_trade_line_db.count > 0 THEN
    FOR i IN l_trade_line_db.first .. l_trade_line_db.last
    LOOP
      pipe row ( l_trade_line_db(i) ) ;
    END LOOP;
  END IF;
  RETURN;
END;
END xx_ap_inv_trade_dashboard_pkg;

/
show error