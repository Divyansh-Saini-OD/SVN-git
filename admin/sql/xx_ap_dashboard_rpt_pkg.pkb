SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE body xx_ap_dashboard_rpt_pkg
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  xx_ap_dashboard_rpt_pkg                                                          |
  -- |  RICE ID   :  E3522 AP Dashboard Report Package                                            |
  -- |  Description:  Dash board Query are build using pipeline Function for performance          |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         11/10/2017   Digamber S       Initial version                                  |
  -- | 1.1         11/10/2017   Digamber S       RTV Reconcilation                                |
  -- | 1.1         18/01/2018   Digamber S       Incorporetd hint for performance                 |
  -- | 1.2         10/04/2018   Priyam P         Fix for Revalidated Invoices                     |
  -- | 1.3         16/01/2018   Madhan Sanjeevi  Code Modified for NAIT-52933                     |
  -- | 1.4         30/03/2020   Mayur Palsokar   Modified xx_ap_trade_chbk_summary for NAIT-106309|
  -- +============================================================================================+

FUNCTION get_po_category(
    p_po_header_id NUMBER)
  RETURN VARCHAR2
AS
  l_po_category VARCHAR2(150);
BEGIN
  FOR i IN
  (SELECT Attribute_category
  FROM po_headers_all
  WHERE po_header_id = p_po_header_id
  )
  LOOP
    l_po_category := i.Attribute_category;
  END LOOP;
  RETURN l_po_category;
END;

FUNCTION get_user_name(
    p_user_id NUMBER)
  RETURN VARCHAR2
AS
  L_user_name VARCHAR2(50):= NULL;
BEGIN
  FOR i IN
  (SELECT u.user_name FROM fnd_user u WHERE u.user_id =p_user_id
  )
  LOOP
    L_user_name := i.user_name;
  END LOOP;
  RETURN L_user_name;
END;

FUNCTION get_hold_release_date(
    p_invoice_id NUMBER)
  RETURN DATE
AS
  l_date DATE ;
BEGIN
  FOR i IN
  (SELECT invoice_id, --, h.hold_id,
    u.user_name released_by ,
    h.last_update_date released_date
  FROM ap_holds_all h ,
    fnd_user u
  WHERE 1               =1
  AND h.invoice_id      = p_invoice_id
  AND h.last_updated_by = u.user_id
  ORDER BY h.last_update_date ,
    DECODE(u.user_name,'APPSMGR',2,1)
  )
  LOOP
    l_date := i.released_date;
  END LOOP;
  RETURN l_date;
END;

FUNCTION get_hold_release_by(
    p_invoice_id NUMBER)
  RETURN VARCHAR2
AS
  L_released_by VARCHAR2(50):= NULL;
  --l_date date ;
BEGIN
  FOR i IN
  (SELECT invoice_id, --, h.hold_id,
    u.user_name released_by ,
    h.last_update_date released_date
  FROM ap_holds_all h ,
    fnd_user u
  WHERE 1               =1
  AND h.invoice_id      = p_invoice_id
  AND h.last_updated_by = u.user_id
  ORDER BY h.last_update_date ,
    DECODE(u.user_name,'APPSMGR',2,1)
  )
  LOOP
    l_released_by := i.released_by;
    --   l_date := i.released_date;
  END LOOP;
  RETURN l_released_by;
END;

FUNCTION VENDOR_ASSISTANT(
    p_assistant_code VARCHAR2)
  RETURN VARCHAR2
IS
  l_vendor_assistant xx_fin_translatevalues.target_value1%Type;
BEGIN
  BEGIN
    SELECT b.target_value2
      -- b.target_value1 vend_assistant_code
    INTO l_vendor_assistant
    FROM xx_fin_translatevalues b ,
      xx_fin_translatedefinition a
    WHERE a.TRANSLATION_NAME = 'XX_AP_VENDOR_ASSISTANTS'
    AND b.TRANSLATE_ID       = a.TRANSLATE_ID
    AND b.enabled_flag       ='Y'
    AND sysdate BETWEEN b.start_date_active AND NVL(b.end_date_active,sysdate)
    AND b.target_value1 = p_assistant_code;
  EXCEPTION
  WHEN OTHERS THEN
    l_vendor_assistant := NULL;
  END ;
  RETURN l_vendor_assistant;
END;
--
------------------------------------------------------------
-- AP Trade – Charge Back Summary
-- Solution ID:214
-- RICE_ID : E3522
------------------------------------------------------------
FUNCTION xx_ap_trade_chbk_summary(
    P_DATE_FROM      DATE ,
    P_DATE_TO        DATE,
    P_ORG_ID         NUMBER,
    P_VENDOR_ID      NUMBER,
    P_VENDOR_SITE_ID NUMBER,
    P_ASSIST_CODE    VARCHAR2,
    P_ITEM_ID        NUMBER,
    P_REPORT_OPTION  VARCHAR2, -- 'V' 'A'
    P_DISP_OPTION    VARCHAR2, -- 'S' 'D'
    P_PRC_EXCEP      VARCHAR2,
    P_QTY_EXCEP      VARCHAR2,
    P_OTH_EXCEP      VARCHAR2,
    P_GL_DATE_FROM   DATE, -- Added by Mayur for NAIT-106309
    P_GL_DATE_TO     DATE  -- Added by Mayur for NAIT-106309
  )
  RETURN xx_ap_dashboard_rpt_pkg.chargeback_db_ctt pipelined
IS
  L_Total NUMBER ;
  CURSOR Vendor
  IS
    SELECT a.org_id,
      a.vendor_id,
      a.vendor_site_id,
      a.assistant_code,
      a.Sup_num,
      a.supplier ,
      A.VENDOR_SITE_CODE ,
      XX_AP_DASHBOARD_RPT_PKG.VENDOR_ASSISTANT(a.assistant_code) VendorAsistant,
      SUM(a.pd_amt) pd_amt ,
      COUNT(a.pd_line_cnt) pd_line_cnt,
      COUNT(DISTINCT a.pd_vcr_cnt) pd_vcr_cnt,
      SUM(a.SH_AMT) SH_AMT,
      COUNT(a.SH_LINE_CNT) SH_LINE_CNT,
      COUNT(DISTINCT a.SH_VCR_CNT) SH_VCR_CNT ,
      SUM(a.OTH_AMT) OTH_AMT ,
      COUNT(a.OTH_LINE_CNT) OTH_LINE_CNT ,
      COUNT(DISTINCT A.Oth_Vcr_Cnt) Oth_Vcr_Cnt,
      SUM(DECODE(P_PRC_EXCEP, 'Y', a.PD_AMT,0)+ DECODE(P_QTY_EXCEP, 'Y', a.SH_AMT,0)+DECODE(P_OTH_EXCEP, 'Y', a.OTH_AMT,0)) total_amt
    FROM
      (SELECT
        /*+ LEADING (ai) */
        ai.vendor_id,
        ai.vendor_site_id,
        NVL(sit.attribute6,'Open') assistant_code,
        sup.segment1 Sup_num,
        sup.vendor_name supplier,
        sit.vendor_site_code,
        ai.invoice_id,
        ai.invoice_num,
        ai.invoice_date,
        DECODE( NVL(UPPER(SUBSTR(AIL.DESCRIPTION,1,3)),'OTH'),'PRI',AIL.AMOUNT,0) PD_AMT,
        DECODE(NVL(UPPER(SUBSTR(AIL.DESCRIPTION,1,3)),'OTH'),'PRI',ail.invoice_id,NULL) pd_line_cnt,
        DECODE(NVL(UPPER(SUBSTR(AIL.DESCRIPTION,1,3)),'OTH'),'PRI' , ail.invoice_id,NULL) pd_vcr_cnt,
        DECODE(NVL(UPPER(SUBSTR(AIL.DESCRIPTION,1,3)),'OTH'),'QTY',AIL.AMOUNT,0) SH_AMT ,
        DECODE(NVL(UPPER(SUBSTR(AIL.DESCRIPTION,1,3)),'OTH'),'QTY' , AIL.INVOICE_ID,NULL) SH_LINE_CNT,
        DECODE(NVL(UPPER(SUBSTR(AIL.DESCRIPTION,1,3)),'OTH'),'QTY' , AIL.INVOICE_ID,NULL) SH_VCR_CNT,
        DECODE(NVL(UPPER(SUBSTR(AIL.DESCRIPTION,1,3)),'OTH'),'PRI',0,'QTY',0,AIL.AMOUNT) OTH_AMT,
        DECODE(NVL(UPPER(SUBSTR(AIL.DESCRIPTION,1,3)),'OTH'),'PRI',NULL,'QTY',NULL,AIL.INVOICE_ID) OTH_LINE_CNT,
        DECODE(NVL(upper(SUBSTR(ail.description,1,3)),'OTH'),'PRI',NULL,'QTY',NULL,ail.invoice_id) oth_vcr_cnt,
        ai.org_id,
        ail.line_type_lookup_code Line_type,
        ail.description,
        --Typecode,
        PHA.SEGMENT1 PO_NUM,
        (SELECT MSIB.SEGMENT1
        FROM MTL_SYSTEM_ITEMS_B MSIB
        WHERE MSIB.INVENTORY_ITEM_ID = AIL.INVENTORY_ITEM_ID
        AND MSIB.ORGANIZATION_ID     = 441
        ) SKU,
      --msib.segment1 sKU,
      NVL(UPPER(SUBSTR(AIL.DESCRIPTION,1,3)),'OTH') REASON_CODE,
      NVL(ail.amount,0) line_amount,
      ai.gl_date GL_DATE -- Added by Mayur for NAIT-106309
      --total_amt;
    FROM AP_INVOICES_ALL AI,
      AP_INVOICE_LINES_ALL AIL,
      AP_SUPPLIER_SITES_ALL SIT,
      AP_SUPPLIERS SUP,
      po_headers_all pha
    WHERE 1              =1
    AND AIL.INVOICE_ID   = AI.INVOICE_ID
    AND PHA.PO_HEADER_ID = NVL(AI.PO_HEADER_ID,AI.QUICK_PO_HEADER_ID)
    AND AI.INVOICE_DATE BETWEEN TO_DATE(TO_CHAR(P_DATE_FROM)
      ||' 00:00:00','DD-MON-RR HH24:MI:SS')
    AND TO_DATE(TO_CHAR(p_date_to)
      ||' 23:59:59','DD-MON-RR HH24:MI:SS')
    AND (AI.GL_DATE >= TO_DATE(TO_CHAR(P_GL_DATE_FROM),'DD-MON-RR') OR P_GL_DATE_FROM IS NULL) -- Added by Mayur for NAIT-106309
    AND (AI.GL_DATE <= TO_DATE(TO_CHAR(P_GL_DATE_TO),'DD-MON-RR') OR P_GL_DATE_TO IS NULL)     -- Added by Mayur for NAIT-106309
    AND AI.ORG_ID   = NVL(P_ORG_ID,AI.ORG_ID)
    AND AI.INVOICE_NUM LIKE '%DM'
    AND NVL(ai.attribute12 ,'N')     = 'Y'
    AND ai.invoice_type_lookup_code <> 'STANDARD'
    AND ai.cancelled_date           IS NULL
    AND EXISTS
      (SELECT 1
      FROM XX_FIN_TRANSLATEVALUES TV ,
        xx_fin_translatedefinition td
      WHERE td.TRANSLATION_NAME = 'XX_AP_TR_MATCH_INVOICES'
      AND tv.TRANSLATE_ID       = td.TRANSLATE_ID
      AND tv.enabled_flag       ='Y'
      AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
      AND tv.target_value1 = ai.source
      )
    AND AI.VENDOR_ID       = NVL(P_VENDOR_ID,AI.VENDOR_ID)
    AND AI.VENDOR_SITE_ID  = NVL(P_VENDOR_SITE_ID,AI.VENDOR_SITE_ID)
    AND SIT.VENDOR_SITE_ID = AI.VENDOR_SITE_ID
    AND SIT.VENDOR_ID      = SUP.VENDOR_ID
    AND SIT.ATTRIBUTE6     = NVL(P_ASSIST_CODE,SIT.ATTRIBUTE6)
    AND sit.attribute8    IS NOT NULL
    AND EXISTS
      (SELECT 1
      FROM XX_FIN_TRANSLATEVALUES TV,
        xx_fin_translatedefinition td
      WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
      AND tv.translate_id       = td.translate_id
      AND tv.enabled_flag       = 'Y'
      AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
      AND tv.target_value1 = sit.attribute8
        ||''
      )
    AND EXISTS
      (SELECT 1
      FROM AP_INVOICE_LINES_ALL AIL2
      WHERE AIL2.INVOICE_ID = AI.INVOICE_ID
        --AND AIL2.INVENTORY_ITEM_ID              = NVL(P_ITEM_ID,AIL2.INVENTORY_ITEM_ID)
      AND NVL(AIL2.INVENTORY_ITEM_ID ,-1)     = NVL(P_ITEM_ID,NVL(AIL2.INVENTORY_ITEM_ID,-1))
      AND (( P_PRC_EXCEP                      = 'N'
      AND P_QTY_EXCEP                         = 'N'
      AND P_OTH_EXCEP                         = 'N')
      OR (( P_PRC_EXCEP                       = 'Y'
      AND UPPER(SUBSTR(AIL2.DESCRIPTION,1,3)) ='PRI' )
      OR ( P_QTY_EXCEP                        = 'Y'
      AND UPPER(SUBSTR(AIL2.DESCRIPTION,1,3)) ='QTY' )
      OR ( P_OTH_EXCEP                        = 'Y'
        -- AND UPPER(SUBSTR(AIL2.DESCRIPTION,1,3)) NOT IN ('QTY','PRI') )))--25 jan
      AND (UPPER(SUBSTR(AIL2.DESCRIPTION,1,3)) <> 'QTY'
      OR UPPER(SUBSTR(AIL2.DESCRIPTION,1,3))   <> 'PRI') )))
      )
      ) A
    HAVING SUM(DECODE(P_PRC_EXCEP, 'Y', A.PD_AMT,0)+ DECODE(P_QTY_EXCEP, 'Y', A.SH_AMT,0)+DECODE(P_OTH_EXCEP, 'Y', A.OTH_AMT,0)) <> 0
    GROUP BY a.org_id,
      a.vendor_id,
      a.vendor_site_id,
      a.assistant_code,
      a.Sup_num,
      a.supplier ,
      a.vendor_site_code;
	  
    -- Vendor Assistant
    CURSOR Ven_assit
    IS
      SELECT a.org_id,
        A.ASSISTANT_CODE,
        XX_AP_DASHBOARD_RPT_PKG.VENDOR_ASSISTANT( A.ASSISTANT_CODE) VendorAsistant,
        SUM(a.pd_amt) pd_amt ,
        COUNT(a.pd_line_cnt) pd_line_cnt,
        COUNT(DISTINCT a.pd_vcr_cnt) pd_vcr_cnt,
        SUM(a.sh_amt) sh_amt,
        COUNT(a.SH_LINE_CNT) SH_LINE_CNT,
        COUNT(DISTINCT a.SH_VCR_CNT) SH_VCR_CNT ,
        SUM(a.OTH_AMT) OTH_AMT ,
        COUNT(a.OTH_LINE_CNT) OTH_LINE_CNT ,
        COUNT(DISTINCT a.oth_vcr_cnt) oth_vcr_cnt,
        SUM(DECODE(P_PRC_EXCEP, 'Y', a.PD_AMT,0)+ DECODE(P_QTY_EXCEP, 'Y', a.SH_AMT,0)+DECODE(P_OTH_EXCEP, 'Y', a.OTH_AMT,0)) total_amt
      FROM
        (SELECT
          /*+ LEADING (ai) */
          ai.vendor_id,
          ai.vendor_site_id,
          NVL(sit.attribute6,'Open') assistant_code,
          sup.segment1 Sup_num,
          sup.vendor_name supplier,
          sit.vendor_site_code,
          ai.invoice_id,
          ai.invoice_num,
          AI.INVOICE_DATE,
          DECODE( NVL(UPPER(SUBSTR(AIL.DESCRIPTION,1,3)),'OTH'),'PRI',AIL.AMOUNT,0) PD_AMT,
          DECODE(NVL(UPPER(SUBSTR(AIL.DESCRIPTION,1,3)),'OTH'),'PRI',ail.invoice_id,NULL) pd_line_cnt,
          DECODE(NVL(UPPER(SUBSTR(AIL.DESCRIPTION,1,3)),'OTH'),'PRI' , ail.invoice_id,NULL) pd_vcr_cnt,
          DECODE(NVL(UPPER(SUBSTR(AIL.DESCRIPTION,1,3)),'OTH'),'QTY',AIL.AMOUNT,0) SH_AMT ,
          DECODE(NVL(UPPER(SUBSTR(AIL.DESCRIPTION,1,3)),'OTH'),'QTY' , AIL.INVOICE_ID,NULL) SH_LINE_CNT,
          DECODE(NVL(UPPER(SUBSTR(AIL.DESCRIPTION,1,3)),'OTH'),'QTY' , AIL.INVOICE_ID,NULL) SH_VCR_CNT,
          DECODE(NVL(UPPER(SUBSTR(AIL.DESCRIPTION,1,3)),'OTH'),'PRI',0,'QTY',0,AIL.AMOUNT) OTH_AMT,
          DECODE(NVL(UPPER(SUBSTR(AIL.DESCRIPTION,1,3)),'OTH'),'PRI',NULL,'QTY',NULL,AIL.INVOICE_ID) OTH_LINE_CNT,
          DECODE(NVL(upper(SUBSTR(ail.description,1,3)),'OTH'),'PRI',NULL,'QTY',NULL,ail.invoice_id) oth_vcr_cnt,
          ai.org_id,
          ail.line_type_lookup_code Line_type,
          ail.description,
          --Typecode,
          PHA.SEGMENT1 PO_NUM,
          (SELECT MSIB.SEGMENT1
          FROM MTL_SYSTEM_ITEMS_B MSIB
          WHERE MSIB.INVENTORY_ITEM_ID = AIL.INVENTORY_ITEM_ID
          AND MSIB.ORGANIZATION_ID     = 441
          ) SKU,
        --msib.segment1 sKU,
        NVL(UPPER(SUBSTR(AIL.DESCRIPTION,1,3)),'OTH') REASON_CODE,
        NVL(ail.amount,0) line_amount,
        ai.gl_date GL_DATE -- Added by Mayur for NAIT-106309
        --total_amt;
      FROM AP_INVOICES_ALL AI,
        AP_INVOICE_LINES_ALL AIL,
        AP_SUPPLIER_SITES_ALL SIT,
        AP_SUPPLIERS SUP,
        po_headers_all pha
      WHERE 1              =1
      AND AIL.INVOICE_ID   = AI.INVOICE_ID
      AND PHA.PO_HEADER_ID = NVL(AI.PO_HEADER_ID,AI.QUICK_PO_HEADER_ID)
      AND AI.INVOICE_DATE BETWEEN TO_DATE(TO_CHAR(P_DATE_FROM)
        ||' 00:00:00','DD-MON-RR HH24:MI:SS')
      AND TO_DATE(TO_CHAR(p_date_to)
        ||' 23:59:59','DD-MON-RR HH24:MI:SS')
      AND (AI.GL_DATE >= TO_DATE(TO_CHAR(P_GL_DATE_FROM),'DD-MON-RR') OR P_GL_DATE_FROM IS NULL) -- Added by Mayur for NAIT-106309
      AND (AI.GL_DATE <= TO_DATE(TO_CHAR(P_GL_DATE_TO),'DD-MON-RR') OR P_GL_DATE_TO IS NULL)     -- Added by Mayur for NAIT-106309
      AND AI.ORG_ID   = NVL(P_ORG_ID,AI.ORG_ID)
      AND AI.INVOICE_NUM LIKE '%DM'
      AND NVL(ai.attribute12 ,'N')     = 'Y'
      AND ai.invoice_type_lookup_code <> 'STANDARD'
      AND ai.cancelled_date           IS NULL
      AND EXISTS
        (SELECT 1
        FROM XX_FIN_TRANSLATEVALUES TV ,
          xx_fin_translatedefinition td
        WHERE td.TRANSLATION_NAME = 'XX_AP_TR_MATCH_INVOICES'
        AND tv.TRANSLATE_ID       = td.TRANSLATE_ID
        AND tv.enabled_flag       ='Y'
        AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
        AND tv.target_value1 = ai.source
        )
      AND AI.VENDOR_ID       = NVL(P_VENDOR_ID,AI.VENDOR_ID)
      AND AI.VENDOR_SITE_ID  = NVL(P_VENDOR_SITE_ID,AI.VENDOR_SITE_ID)
      AND SIT.VENDOR_SITE_ID = AI.VENDOR_SITE_ID
      AND SIT.VENDOR_ID      = SUP.VENDOR_ID
      AND SIT.ATTRIBUTE6     = NVL(P_ASSIST_CODE,SIT.ATTRIBUTE6)
      AND sit.attribute8    IS NOT NULL
      AND EXISTS
        (SELECT 1
        FROM XX_FIN_TRANSLATEVALUES TV,
          xx_fin_translatedefinition td
        WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
        AND tv.translate_id       = td.translate_id
        AND tv.enabled_flag       = 'Y'
        AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
        AND tv.target_value1 = sit.attribute8
          ||''
        )
      AND EXISTS
        (SELECT 1
        FROM AP_INVOICE_LINES_ALL AIL2
        WHERE AIL2.INVOICE_ID = AI.INVOICE_ID
          --AND AIL2.INVENTORY_ITEM_ID              = NVL(P_ITEM_ID,AIL2.INVENTORY_ITEM_ID)
        AND NVL(AIL2.INVENTORY_ITEM_ID ,-1)     = NVL(P_ITEM_ID,NVL(AIL2.INVENTORY_ITEM_ID,-1))
        AND (( P_PRC_EXCEP                      = 'N'
        AND P_QTY_EXCEP                         = 'N'
        AND P_OTH_EXCEP                         = 'N')
        OR (( P_PRC_EXCEP                       = 'Y'
        AND UPPER(SUBSTR(AIL2.DESCRIPTION,1,3)) ='PRI' )
        OR ( P_QTY_EXCEP                        = 'Y'
        AND UPPER(SUBSTR(AIL2.DESCRIPTION,1,3)) ='QTY' )
        OR ( P_OTH_EXCEP                        = 'Y'
          -- AND UPPER(SUBSTR(AIL2.DESCRIPTION,1,3)) NOT IN ('QTY','PRI') )))--25 jan
        AND (UPPER(SUBSTR(AIL2.DESCRIPTION,1,3)) <> 'QTY'
        OR UPPER(SUBSTR(AIL2.DESCRIPTION,1,3))   <> 'PRI') )))
        )
        ) A
      HAVING SUM(DECODE(P_PRC_EXCEP, 'Y', a.PD_AMT,0)+ DECODE(P_QTY_EXCEP, 'Y', a.SH_AMT,0)+DECODE(P_OTH_EXCEP, 'Y', a.OTH_AMT,0)) <> 0
      GROUP BY a.org_id,
        a.assistant_code;
    
	-- Detail Cursor
      CURSOR Detail
      IS
        SELECT
          /*+ LEADING (ai) */
          ai.vendor_id,
          ai.vendor_site_id,
          NVL(SIT.ATTRIBUTE6,'Open') ASSISTANT_CODE,
          xx_ap_dashboard_rpt_pkg.vendor_assistant( NVL(sit.attribute6,'Open')) VendorAsistant,
          sup.segment1 Sup_num,
          sup.vendor_name supplier,
          sit.vendor_site_code,
          ai.invoice_id,
          ai.invoice_num,
          AI.INVOICE_DATE,
          AI.ORG_ID,
          --ail.line_type_lookup_code Line_type,
          ail.description,
          --Typecode,
          PHA.SEGMENT1 PO_NUM,
          DECODE(NVL(AIL.INVENTORY_ITEM_ID,-1), -1,NULL,
          (SELECT MSIB.SEGMENT1
          FROM MTL_SYSTEM_ITEMS_B MSIB
          WHERE MSIB.INVENTORY_ITEM_ID = AIL.INVENTORY_ITEM_ID
          AND MSIB.ORGANIZATION_ID     = 441
          )) SKU,
          --msib.segment1 sKU,
          --  DECODE(nvl(AIL.INVENTORY_ITEM_ID,-1), -1,'Other','Item') Line_type,
          NVL(UPPER(SUBSTR(AIL.DESCRIPTION,1,3)),'OTH') REASON_CODE,
          NVL(ail.amount,0) line_amount,
          ai.gl_date GL_DATE -- Added by Mayur for NAIT-106309
          --total_amt;
        FROM AP_INVOICES_ALL AI,
          AP_INVOICE_LINES_ALL AIL,
          AP_SUPPLIER_SITES_ALL SIT,
          AP_SUPPLIERS SUP,
          po_headers_all pha
        WHERE 1              =1
        AND AIL.INVOICE_ID   = AI.INVOICE_ID
        AND PHA.PO_HEADER_ID = NVL(AI.PO_HEADER_ID,AI.QUICK_PO_HEADER_ID)
        AND AI.INVOICE_DATE BETWEEN TO_DATE(TO_CHAR(P_DATE_FROM)
          ||' 00:00:00','DD-MON-RR HH24:MI:SS')
        AND TO_DATE(TO_CHAR(p_date_to)
          ||' 23:59:59','DD-MON-RR HH24:MI:SS')
        AND (AI.GL_DATE >= TO_DATE(TO_CHAR(P_GL_DATE_FROM),'DD-MON-RR') OR P_GL_DATE_FROM IS NULL) -- Added by Mayur for NAIT-106309
        AND (AI.GL_DATE <= TO_DATE(TO_CHAR(P_GL_DATE_TO),'DD-MON-RR') OR P_GL_DATE_TO IS NULL)     -- Added by Mayur for NAIT-106309
        AND AI.ORG_ID   = NVL(P_ORG_ID,AI.ORG_ID)
        AND AI.INVOICE_NUM LIKE '%DM'
        AND NVL(ai.attribute12 ,'N')     = 'Y'
        AND ai.invoice_type_lookup_code <> 'STANDARD'
        AND ai.cancelled_date           IS NULL
        AND EXISTS
          (SELECT 1
          FROM XX_FIN_TRANSLATEVALUES TV ,
            xx_fin_translatedefinition td
          WHERE td.TRANSLATION_NAME = 'XX_AP_TR_MATCH_INVOICES'
          AND tv.TRANSLATE_ID       = td.TRANSLATE_ID
          AND tv.enabled_flag       ='Y'
          AND SYSDATE BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
          AND tv.target_value1 = ai.source
          )
        AND AI.VENDOR_ID       = NVL(P_VENDOR_ID,AI.VENDOR_ID)
        AND AI.VENDOR_SITE_ID  = NVL(P_VENDOR_SITE_ID,AI.VENDOR_SITE_ID)
        AND SIT.VENDOR_SITE_ID = AI.VENDOR_SITE_ID
        AND SIT.VENDOR_ID      = SUP.VENDOR_ID
        AND SIT.ATTRIBUTE6     = NVL(P_ASSIST_CODE,SIT.ATTRIBUTE6)
        AND sit.attribute8    IS NOT NULL
        AND EXISTS
          (SELECT 1
          FROM XX_FIN_TRANSLATEVALUES TV,
            xx_fin_translatedefinition td
          WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
          AND tv.translate_id       = td.translate_id
          AND tv.enabled_flag       = 'Y'
          AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
          AND tv.target_value1 = sit.attribute8
            ||''
          )
        AND EXISTS
          (SELECT 1
          FROM AP_INVOICE_LINES_ALL AIL2
          WHERE AIL2.INVOICE_ID = AI.INVOICE_ID
            --AND AIL2.INVENTORY_ITEM_ID              = NVL(P_ITEM_ID,AIL2.INVENTORY_ITEM_ID)
          AND NVL(AIL2.INVENTORY_ITEM_ID ,-1)     = NVL(P_ITEM_ID,NVL(AIL2.INVENTORY_ITEM_ID,-1))
          AND (( P_PRC_EXCEP                      = 'N'
          AND P_QTY_EXCEP                         = 'N'
          AND P_OTH_EXCEP                         = 'N')
          OR (( P_PRC_EXCEP                       = 'Y'
          AND UPPER(SUBSTR(AIL2.DESCRIPTION,1,3)) ='PRI' )
          OR ( P_QTY_EXCEP                        = 'Y'
          AND UPPER(SUBSTR(AIL2.DESCRIPTION,1,3)) ='QTY' )
          OR ( P_OTH_EXCEP                        = 'Y'
            -- AND UPPER(SUBSTR(AIL2.DESCRIPTION,1,3)) NOT IN ('QTY','PRI') )))--25 jan
          AND (UPPER(SUBSTR(AIL2.DESCRIPTION,1,3)) <> 'QTY'
          OR UPPER(SUBSTR(AIL2.DESCRIPTION,1,3))   <> 'PRI') )))
          )
        ORDER BY ai.vendor_id,
          ai.vendor_site_id,
          AI.INVOICE_ID,
          ai.gl_date; -- Added by Mayur for NAIT-106309
     
	 --chargeback_db_tab xx_ap_dashboard_rpt_pkg.chargeback_db_ctt;
      TYPE chargeback_db_ctt
    IS
      TABLE OF xx_ap_dashboard_rpt_pkg.chargeback_db INDEX BY PLS_INTEGER;
      l_chargeback_db chargeback_db_ctt;
      l_error_count NUMBER;
      ex_dml_errors EXCEPTION;
      PRAGMA EXCEPTION_INIT(EX_DML_ERRORS, -24381);
      N             NUMBER        := 0;
      L_LINE_TYPE   VARCHAR2(100) := 'Item';
      L_EXCEPTION   VARCHAR2(100) := 'Other';
      L_REASON_CODE VARCHAR2(100) := 'OTH';
      l_exp         VARCHAR2(100) := NULL;
    
	BEGIN
      xla_security_pkg.set_security_context(602);
      l_exp                   := P_OTH_EXCEP;
      IF l_chargeback_db.count > 0 THEN
        l_chargeback_db.delete;
      END IF;
      IF p_disp_option = 'D' THEN
        FOR i IN Detail
        LOOP
          L_LINE_TYPE   := '';
          L_EXCEPTION   := '';
          L_REASON_CODE := '';
          IF I.SKU      IS NOT NULL THEN
            L_LINE_TYPE := 'Item';
          ELSE
            L_LINE_TYPE := 'Other';
          END IF;
          IF I.REASON_CODE    = 'FRE' THEN
            L_EXCEPTION      := 'Freight';
            L_REASON_CODE    := 'FR';
          Elsif I.REASON_CODE = 'QTY' THEN
            L_EXCEPTION      := 'Qty';
            L_REASON_CODE    := 'SH';
          Elsif I.REASON_CODE = 'PRI' THEN
            L_EXCEPTION      := 'Price';
            L_REASON_CODE    := 'PD';
          ELSE
            L_EXCEPTION   := 'Other';
            L_REASON_CODE := 'OTH';
          END IF;
          L_Total                                 := 0;
          l_chargeback_db(n).vendor_id            := i.vendor_id;
          l_chargeback_db(n).vendor_site_id       := i.vendor_site_id;
          l_chargeback_db(n).VendorAssistant_code := i.assistant_code;
          l_chargeback_db(n).VendorAssistant_Name := i.VendorAsistant;
          l_chargeback_db(n).SupplierNum          := i.Sup_num;
          l_chargeback_db(n).SupplierName         := i.supplier;
          l_chargeback_db(n).vendorsite_code      := i.vendor_site_code;
          l_chargeback_db(n).invoice_id           := i.invoice_id;
          l_chargeback_db(n).invoice_num          := i.invoice_num;
          L_CHARGEBACK_DB(N).INVOICE_DATE         := I.INVOICE_DATE;
          /*   l_chargeback_db(n).pricing_amt          := i.pd_amt;
          l_chargeback_db(n).Pricing_Ln_cnt       := i.pd_line_cnt;
          l_chargeback_db(n).Pricing_voucr_cnt    := i.pd_vcr_cnt;
          l_chargeback_db(n).Shortage_amt         := i.SH_amt;
          l_chargeback_db(n).Shortage_Ln_cnt      := i.sh_line_cnt;
          l_chargeback_db(n).shortage_vouchr_cnt  := i.sh_vcr_cnt;
          l_chargeback_db(n).Other_amt            := i.oth_amt;
          l_chargeback_db(n).other_ln_cnt         := i.oth_line_cnt;
          L_CHARGEBACK_DB(N).OTHER_VOUCHER_CNT    := i.OTH_VCR_CNT;*/
          L_CHARGEBACK_DB(N).ORG_ID      := I.ORG_ID;
          l_chargeback_db(n).Line_type   := L_LINE_TYPE ; --i.Line_type;
          L_CHARGEBACK_DB(N).DESCRIPTION := I.DESCRIPTION;
          l_chargeback_db(n).Typecode    := L_EXCEPTION;
          L_CHARGEBACK_DB(N).PO_NUM      := i.PO_NUM;
          l_chargeback_db(n).sku         := i.sku;
          L_CHARGEBACK_DB(N).REASON_CODE := L_REASON_CODE;
          /*  IF P_Prc_Excep                           = 'Y' THEN
          L_Total                               := L_Total+I.Pd_Amt;
          END IF;
          IF P_Qty_Excep = 'Y' THEN
          L_Total     := L_Total+I.Sh_Amt;
          END IF;
          IF P_OTH_EXCEP = 'Y' THEN
          L_Total     := L_Total+I.Oth_Amt;
          END IF;*/
          L_Chargeback_Db(N).Line_Amount := i.line_amount;
          L_Chargeback_Db(N).GL_DATE     := i.GL_DATE; -- Added by Mayur for NAIT-106309
          --dbms_output.put_line('Test '||l_chargeback_db(n).vendor_id);
          n := n+1;
        END LOOP;
      ELSE
        IF p_report_option = 'V' THEN
          FOR i IN Vendor
          LOOP
            l_chargeback_db(n).vendor_id            := i.vendor_id;
            l_chargeback_db(n).vendor_site_id       := i.vendor_site_id;
            l_chargeback_db(n).VendorAssistant_code := i.assistant_code;
            l_chargeback_db(n).VendorAssistant_Name := i.VendorAsistant;
            l_chargeback_db(n).SupplierNum          := i.Sup_num;
            l_chargeback_db(n).SupplierName         := i.supplier;
            l_chargeback_db(n).vendorsite_code      := i.vendor_site_code;
            --   l_chargeback_db(n).invoice_id           := i.invoice_id;
            --   l_chargeback_db(n).invoice_num          := i.invoice_num;
            ---    l_chargeback_db(n).invoice_date         := i.invoice_date;
            l_chargeback_db(n).pricing_amt         := i.pd_amt;
            l_chargeback_db(n).Pricing_Ln_cnt      := i.pd_line_cnt;
            l_chargeback_db(n).Pricing_voucr_cnt   := i.pd_vcr_cnt;
            l_chargeback_db(n).Shortage_amt        := i.SH_amt;
            l_chargeback_db(n).Shortage_Ln_cnt     := i.sh_line_cnt;
            l_chargeback_db(n).shortage_vouchr_cnt := i.sh_vcr_cnt;
            l_chargeback_db(n).Other_amt           := i.oth_amt;
            l_chargeback_db(n).other_ln_cnt        := i.oth_line_cnt;
            L_CHARGEBACK_DB(N).OTHER_VOUCHER_CNT   := i.OTH_VCR_CNT;
            l_chargeback_db(n).Org_id              := i.Org_id;
            --     l_chargeback_db(n).Line_type            := j.Line_type;
            --    l_chargeback_db(n).DESCRIPTION          := j.DESCRIPTION;
            --  l_chargeback_db(n).Typecode             := j.Typecode;
            --  L_CHARGEBACK_DB(N).PO_NUM               := J.PO_NUM;
            --  l_chargeback_db(n).sku                  := j.sku;
            --   l_chargeback_db(n).Reason_code          := j.Reason_code;
            --  l_chargeback_db(n).line_amount          := j.line_amount;
            l_chargeback_db(n).line_amount := i. total_amt;
            --dbms_output.put_line('Test '||l_chargeback_db(n).vendor_id);
            n := n+1;
          END LOOP;
        ELSE
          FOR i IN Ven_assit
          LOOP
            -- l_chargeback_db(n).vendor_id            := i.vendor_id;
            -- l_chargeback_db(n).vendor_site_id       := i.vendor_site_id;
            l_chargeback_db(n).VendorAssistant_code := i.assistant_code;
            l_chargeback_db(n).vendorassistant_name := i.vendorasistant;
            -- l_chargeback_db(n).SupplierNum          := i.Sup_num;
            -- l_chargeback_db(n).SupplierName         := i.supplier;
            -- l_chargeback_db(n).vendorsite_code      := i.vendor_site_code;
            --   l_chargeback_db(n).invoice_id           := i.invoice_id;
            --   l_chargeback_db(n).invoice_num          := i.invoice_num;
            ---    l_chargeback_db(n).invoice_date         := i.invoice_date;
            l_chargeback_db(n).pricing_amt         := i.pd_amt;
            l_chargeback_db(n).Pricing_Ln_cnt      := i.pd_line_cnt;
            l_chargeback_db(n).Pricing_voucr_cnt   := i.pd_vcr_cnt;
            l_chargeback_db(n).Shortage_amt        := i.SH_amt;
            l_chargeback_db(n).Shortage_Ln_cnt     := i.sh_line_cnt;
            l_chargeback_db(n).shortage_vouchr_cnt := i.sh_vcr_cnt;
            l_chargeback_db(n).Other_amt           := i.oth_amt;
            l_chargeback_db(n).other_ln_cnt        := i.oth_line_cnt;
            L_CHARGEBACK_DB(N).OTHER_VOUCHER_CNT   := i.OTH_VCR_CNT;
            l_chargeback_db(n).Org_id              := i.Org_id;
            --     l_chargeback_db(n).Line_type            := j.Line_type;
            --    l_chargeback_db(n).DESCRIPTION          := j.DESCRIPTION;
            --  l_chargeback_db(n).Typecode             := j.Typecode;
            --  L_CHARGEBACK_DB(N).PO_NUM               := J.PO_NUM;
            --  l_chargeback_db(n).sku                  := j.sku;
            --   l_chargeback_db(n).Reason_code          := j.Reason_code;
            --  l_chargeback_db(n).line_amount          := j.line_amount;
            l_chargeback_db(n).line_amount := i. total_amt;
            --dbms_output.put_line('Test '||l_chargeback_db(n).vendor_id);
            n := n+1;
          END LOOP;
        END IF;
      END IF;
      IF l_chargeback_db.count                   = 0 THEN
        l_chargeback_db(0).vendor_id            := NULL;
        l_chargeback_db(0).vendor_site_id       := NULL;
        l_chargeback_db(0).VendorAssistant_code := NULL;
        l_chargeback_db(0).VendorAssistant_Name := NULL;
        l_chargeback_db(0).SupplierNum          := NULL;
        l_chargeback_db(0).SupplierName         := NULL;
        l_chargeback_db(0).VendorSite_code      := NULL;
        l_chargeback_db(0).invoice_id           := NULL;
        l_chargeback_db(0).invoice_num          := NULL;
        l_chargeback_db(0).invoice_date         := NULL;
        l_chargeback_db(0).Pricing_amt          := NULL;
        l_chargeback_db(0).Pricing_Ln_cnt       := NULL;
        l_chargeback_db(0).Pricing_voucr_cnt    := NULL;
        l_chargeback_db(0).Shortage_amt         := NULL;
        l_chargeback_db(0).Shortage_Ln_cnt      := NULL;
        l_chargeback_db(0).Shortage_vouchr_cnt  := NULL;
        l_chargeback_db(0).Other_amt            := NULL;
        l_chargeback_db(0).Other_Ln_cnt         := NULL;
        l_chargeback_db(0).Other_voucher_cnt    := NULL;
        l_chargeback_db(0).Org_id               := NULL;
        l_chargeback_db(0).Line_type            := NULL;
        l_chargeback_db(0).DESCRIPTION          := NULL;
        l_chargeback_db(0).Typecode             := NULL;
        l_chargeback_db(0).po_num               := NULL;
        l_chargeback_db(0).sku                  := NULL;
        l_chargeback_db(0).Reason_code          := NULL;
        l_chargeback_db(0).line_amount          := NULL;
        L_Chargeback_Db(0).GL_DATE              := NULL; -- Added by Mayur for NAIT-106309
      END IF;
      FOR i IN l_chargeback_db.First .. l_chargeback_db.last
      LOOP
        --dbms_output.put_line('Test '||l_chargeback_db(i).vendor_id);
        pipe row ( l_chargeback_db(i) ) ;
      END LOOP;
      RETURN;
    EXCEPTION
    WHEN ex_dml_errors THEN
      l_error_count := SQL%BULK_EXCEPTIONS.count;
      DBMS_OUTPUT.put_line('Number of failures: ' || l_error_count);
      FOR i IN 1 .. l_error_count
      LOOP
        DBMS_OUTPUT.put_line ( 'Error: ' || i || ' Array Index: ' || SQL%BULK_EXCEPTIONS(i).error_index || ' Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE) ) ;
      END LOOP;
    END xx_ap_trade_chbk_summary;
    ------------------------------------------------------------
    -- Ap Trade AP Trade – RTV Reconcilation
    -- Solution ID: 217.0
    -- RICE_ID : E3522
    ------------------------------------------------------------
  FUNCTION xx_ap_trade_rtv_reconcilation(
      p_date_from   DATE ,
      p_date_to     DATE ,
      p_period_from VARCHAR2,
      P_Period_to   VARCHAR2)
    RETURN xx_ap_dashboard_rpt_pkg.ap_trade_rtv_recon_ctt pipelined
  IS
    CURSOR Sitran (p_dt_from DATE,p_dt_to DATE)
    IS
      SELECT 'SITRAN' Application,
        DECODE(h.company_code,'0001', 'OU_US', 'OU_CA') Country,
        h.return_code,
        SUM(DECODE(H.Frequency_code,'DY', DECODE(H.RETURN_CODE,'73',L.line_amount,0),0)) DY_73_AMT,
        SUM(DECODE(H.FREQUENCY_CODE,'WY', DECODE(H.RETURN_CODE,'73',L.LINE_AMOUNT,0),0)) WY_73_AMT,
        SUM(DECODE(H.Frequency_code,'MY', DECODE(H.RETURN_CODE,'73',L.line_amount,0),0)) MY_73_AMT,
        SUM(DECODE(H.Frequency_code,'QY', DECODE(H.RETURN_CODE,'73',L.line_amount,0),0)) QY_73_AMT
      FROM xx_ap_rtv_lines_attr l,
        xx_ap_rtv_hdr_attr h
      WHERE 1 =1
        --and h.record_status  = 'C'
      AND l.rtv_date BETWEEN to_date(TO_CHAR(p_dt_from)
        ||' 00:00:00','DD-MON-RR HH24:MI:SS')
      AND to_date(TO_CHAR(p_dt_to)
        ||' 23:59:59','DD-MON-RR HH24:MI:SS')
      AND h.rtv_number       = l.rtv_number
      AND NVL(h.header_id,1) = NVL(l.header_id,1)
      AND H.RETURN_CODE      = '73'
      GROUP BY 1,
        h.company_code,
        H.Return_Code ;
    -- CURSOR I1 (p_vendor_id NUMBER,p_site_id NUMBER)
    CURSOR ORCL (p_dt_from DATE,p_dt_to DATE)
    IS
      SELECT
        /*+ leading (mt) */
        'Oracle AP' Application,
        DECODE(h.company_code,'0001', 'OU_US', 'OU_CA') country,
        ROUND(SUM(DECODE(h.frequency_code,'DY', DECODE(h.return_code,'73',mt.transaction_cost,0),0)),2) dy_73_amt,
        ROUND(SUM(DECODE(h.frequency_code,'WY', DECODE(h.return_code,'73',mt.transaction_cost,0),0)),2) wy_73_amt,
        ROUND(SUM(DECODE(h.frequency_code,'MY', DECODE(h.return_code,'73',mt.transaction_cost,0),0)),2) my_73_amt,
        ROUND(SUM(DECODE(h.frequency_code,'QY', DECODE(h.return_code,'73',mt.transaction_cost,0),0)),2) qy_73_amt
      FROM Xx_Ap_Rtv_Hdr_Attr H,
        Xx_Ap_Rtv_Lines_Attr L,
        Mtl_Material_Transactions Mt
      WHERE 1 =1
        --AND H.header_id     = l.header_id
      AND H.Rtv_Number               = L.Rtv_Number
      AND H.Request_Id               = L.Request_Id
      AND H.Record_Status            = 'C'
      AND H.Return_Code              = '73'
      AND mt.subinventory_code       = 'STOCK'
      AND Mt.Transaction_Source_Name = 'OD CONSIGNMENT RTV'
      AND Mt.Attribute1              = '0'
        ||L.Vendor_Num
      AND Mt.Attribute2 = L.Rtv_Number
      AND Mt.Attribute6 = L.Vendor_Product_Code
      AND MT.transaction_date BETWEEN to_date(TO_CHAR(p_dt_from)
        ||' 00:00:00','DD-MON-RR HH24:MI:SS')
      AND to_date(TO_CHAR(p_dt_to)
        ||' 23:59:59','DD-MON-RR HH24:MI:SS')
        /*AND EXISTS
        (SELECT 1
        From Mtl_System_Items_B Msi
        WHERE Msi.Segment1        = Ltrim(L.Sku,'0')
        And Msi.Inventory_Item_Id = Mt.Inventory_Item_Id
        --AND Msi.Organization_Id(+)   = Mt.Organization_Id
        )*/
      GROUP BY 1,
        H.Company_Code ,
        H.Return_Code,
        H.Record_Status ;
    --chargeback_db_tab xx_ap_dashboard_rpt_pkg.chargeback_db_ctt;
  TYPE ap_trade_rtv_recon
IS
  TABLE OF xx_ap_dashboard_rpt_pkg.ap_trade_rtv_recon INDEX BY PLS_INTEGER;
  l_ap_trade_rtv_recon ap_trade_rtv_recon;
  l_error_count NUMBER;
  ex_dml_errors EXCEPTION;
  PRAGMA EXCEPTION_INIT(ex_dml_errors, -24381);
  n            NUMBER := 0;
  l_start_date DATE;
  l_end_date   DATE;
BEGIN
  xla_security_pkg.set_security_context(602);
  IF p_period_from IS NOT NULL AND p_period_to IS NOT NULL THEN
    BEGIN
      SELECT start_date
      INTO l_start_date
      FROM gl_periods
      WHERE 1         =1
      AND period_name = p_period_from;
    EXCEPTION
    WHEN OTHERS THEN
      l_start_date := sysdate;
    END;
    BEGIN
      SELECT end_date
      INTO l_end_date
      FROM gl_periods
      WHERE 1         =1
      AND period_name = p_period_to;
    EXCEPTION
    WHEN OTHERS THEN
      l_start_date := sysdate;
    END;
  END IF;
  IF ( p_date_from IS NOT NULL AND p_date_to IS NOT NULL ) THEN
    l_start_date   := p_date_from;
    l_end_date     := p_date_to;
  END IF;
  IF l_ap_trade_rtv_recon.count > 0 THEN
    l_ap_trade_rtv_recon.delete;
  END IF;
  --dbms_output.put_line ('Date '||l_start_date||' - '||l_end_date);
  --Code commented based on NAIT-52933
  /*FOR i IN sitran (l_start_date,l_end_date)
  LOOP
  l_ap_trade_rtv_recon(n).APPLICATION := i.APPLICATION;
  L_Ap_Trade_Rtv_Recon(N).Country     := I.Country;
  l_ap_trade_rtv_recon(n).DY_73_AMT   := i.DY_73_AMT;
  l_ap_trade_rtv_recon(n).wy_73_amt   := i.wy_73_amt;
  l_ap_trade_rtv_recon(n).my_73_amt   := i.my_73_amt;
  L_Ap_Trade_Rtv_Recon(N).Qy_73_Amt   := I.Qy_73_Amt;
  -- l_ap_trade_rtv_recon(n).INVOICE_NUM        := i.INVOICE_NUM;
  -- l_ap_trade_rtv_recon(n).INVOICE_DATE       := i.INVOICE_DATE;
  -- l_ap_trade_rtv_recon(n).RTV_NUMBER         := i.RTV_NUMBER;
  -- L_Ap_Trade_Rtv_Recon(N).Sku                := I.Sku;
  -- l_ap_trade_rtv_recon(n).RETURN_CODE        := i.RETURN_CODE;
  --  l_ap_trade_rtv_recon(n).RETURN_DESCRIPTION := i.RETURN_DESCRIPTION;
  -- l_ap_trade_rtv_recon(n).FREQUENCY_CODE     := i.FREQUENCY_CODE;
  --l_ap_trade_rtv_recon(n).DY_OTH_AMT         := i.DY_OTH_AMT;
  --l_ap_trade_rtv_recon(n).wy_oth_amt         := i.wy_oth_amt;
  --l_ap_trade_rtv_recon(n).my_oth_amt         := i.my_oth_amt;
  --l_ap_trade_rtv_recon(n).qy_oth_amt         := i.qy_oth_amt;
  N := N+1;
  END LOOP;*/
  FOR j IN ORCL ( l_start_date,l_end_date)
  LOOP
    l_ap_trade_rtv_recon(n).APPLICATION := j.APPLICATION;
    l_ap_trade_rtv_recon(n).COUNTRY     := j.COUNTRY;
    l_ap_trade_rtv_recon(n).DY_73_AMT   := j.DY_73_AMT;
    l_ap_trade_rtv_recon(n).wy_73_amt   := j.wy_73_amt;
    l_ap_trade_rtv_recon(n).my_73_amt   := j.my_73_amt;
    L_Ap_Trade_Rtv_Recon(N).Qy_73_Amt   := J.Qy_73_Amt;
    --   l_ap_trade_rtv_recon(n).INVOICE_NUM        := j.INVOICE_NUM;
    --   l_ap_trade_rtv_recon(n).INVOICE_DATE       := j.INVOICE_DATE;
    --   l_ap_trade_rtv_recon(n).RTV_NUMBER         := j.RTV_NUMBER;
    --   l_ap_trade_rtv_recon(n).SKU                := j.SKU;
    --   l_ap_trade_rtv_recon(n).RETURN_CODE        := j.RETURN_CODE;
    --   l_ap_trade_rtv_recon(n).RETURN_DESCRIPTION := j.RETURN_DESCRIPTION;
    --   l_ap_trade_rtv_recon(n).FREQUENCY_CODE     := j.FREQUENCY_CODE;
    --   l_ap_trade_rtv_recon(n).DY_OTH_AMT         := j.DY_OTH_AMT;
    --   l_ap_trade_rtv_recon(n).wy_oth_amt         := j.wy_oth_amt;
    --   l_ap_trade_rtv_recon(n).my_oth_amt         := j.my_oth_amt;
    --   l_ap_trade_rtv_recon(n).QY_OTH_AMT         := j.QY_oth_AMT;
    n := n+1;
  END LOOP;
  -- Add placeholder Records
  -- 'SITRAN', 'Oracle AP'
  FOR i IN 1..2
  LOOP
    --Code commented based on NAIT-52933
    /*IF i                                   = 1 THEN
    l_ap_trade_rtv_recon(n).application := 'SITRAN';
    l_ap_trade_rtv_recon(n).country     := 'OU_US';
    END IF;*/
    IF i                                   = 1 THEN
      L_Ap_Trade_Rtv_Recon(N).Application := 'Oracle AP';
      l_ap_trade_rtv_recon(n).country     := 'OU_US';
    END IF;
    IF i                                   = 2 THEN
      l_ap_trade_rtv_recon(n).application := 'Oracle AP';
      l_ap_trade_rtv_recon(n).country     :='OU_CA';
    END IF;
    --Code commented based on NAIT-52933
    /*IF i                                   = 4 THEN
    l_ap_trade_rtv_recon(n).application := 'SITRAN';
    l_ap_trade_rtv_recon(n).country     :='OU_CA';
    END IF;*/
    l_ap_trade_rtv_recon(n).dy_73_amt := 0;
    l_ap_trade_rtv_recon(n).wy_73_amt := 0;
    l_ap_trade_rtv_recon(n).my_73_amt := 0;
    L_Ap_Trade_Rtv_Recon(N).Qy_73_Amt := 0;
    -- l_ap_trade_rtv_recon(n).invoice_num        := NULL;
    --  l_ap_trade_rtv_recon(n).invoice_date       := NULL;
    --  l_ap_trade_rtv_recon(n).rtv_number         := NULL;
    --  l_ap_trade_rtv_recon(n).SKU                := NULL;
    --  l_ap_trade_rtv_recon(n).return_code        := NULL;
    --  l_ap_trade_rtv_recon(n).return_description := NULL;
    --  l_ap_trade_rtv_recon(n).FREQUENCY_CODE     := NULL;
    --  l_ap_trade_rtv_recon(n).dy_oth_amt         := 0;
    --  l_ap_trade_rtv_recon(n).wy_oth_amt         := 0;
    --  l_ap_trade_rtv_recon(n).my_oth_amt         := 0;
    --  l_ap_trade_rtv_recon(n).qy_oth_amt         := 0;
    N := N+1;
  END LOOP;
  FOR i IN l_ap_trade_rtv_recon.First .. l_ap_trade_rtv_recon.last
  LOOP
    --dbms_output.put_line('Test '||l_ap_trade_rtv_recon(i).RTV_NUMBER);
    PIPE ROW ( l_ap_trade_rtv_recon(I) ) ;
  END LOOP;
  RETURN;
EXCEPTION
WHEN ex_dml_errors THEN
  l_error_count := SQL%BULK_EXCEPTIONS.count;
  DBMS_OUTPUT.put_line('Number of failures: ' || l_error_count);
  FOR i IN 1 .. l_error_count
  LOOP
    DBMS_OUTPUT.put_line ( 'Error: ' || i || ' Array Index: ' || SQL%BULK_EXCEPTIONS(i).error_index || ' Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE) ) ;
  END LOOP;
END xx_ap_trade_rtv_reconcilation;
------------------------------------------------------------
-- AP Trade – Match Analysis
-- Solution ID: 215.0
-- RICE_ID : E3522
------------------------------------------------------------
FUNCTION xx_ap_trade_match_analysis(
    p_date_from      DATE ,
    p_date_to        DATE ,
    P_Period_From    VARCHAR2,
    P_Period_To      VARCHAR2,
    P_Org_Id         NUMBER,
    P_Vendor_Id      NUMBER,
    P_vendor_site_id NUMBER,
    P_Assist         VARCHAR2,
    P_Drop_Ship_Flag VARCHAR2,
    P_report_option  VARCHAR2 )
  RETURN xx_ap_dashboard_rpt_pkg.ap_trade_match_analysis_ctt pipelined
IS
  L_Vendassistant_Code VARCHAR2(100) := NULL;
  L_Svc_Esp_Vps        NUMBER; -- 3839857
  L_Svc_Esp_Fin        NUMBER; --90102
  L_Appsmgr            NUMBER; -- 5
  ------
  CURSOR c_Hold_Vendor (p_dt_from DATE,p_dt_to DATE)
  IS
    SELECT B.Assistant_Code,
      B.Vendor_Id,
      B.Vendor_Site_Id,
      B.Vendor_Site_Code,
      B.Sup_Num,
      b.Supplier,
      Xx_Ap_Dashboard_Rpt_Pkg.Vendor_Assistant(B.Assistant_Code) vendor_Assistant,
      SUM ( B.Sys_Tdm) Sys_Tdm,
      SUM ( B.Sys_Edi) Sys_Edi,
      SUM ( B.Sys_Man) Sys_Man,
      SUM( B.Sys_Other) Sys_Other,
      SUM( b.man_matched ) man_matched
    FROM
      (SELECT
        /*+ LEADING (h) */
        NVL(Sit.Attribute6,'Open') Assistant_Code,
        Ai.Vendor_Id,
        Ai.Vendor_Site_Id,
        Sit.Vendor_Site_Code,
        Sup.Segment1 Sup_Num,
        SUP.VENDOR_NAME SUPPLIER,
        H.LAST_UPDATE_DATE HOLD_REL_DATE,
        AI.LAST_UPDATE_DATE INV_last_upd_date,
        ai.invoice_num,
        (
        CASE
          WHEN Ai.Source         IN ( 'US_OD_TDM','US_OD_DCI_TRADE')
          AND NVL(H.Rel_By,'SYS') = 'SYS'
          THEN 1
          ELSE 0
        END ) Sys_Tdm,
        (
        CASE
          WHEN Ai.Source          = 'US_OD_TRADE_EDI'
          AND NVL(H.Rel_By,'SYS') = 'SYS'
          THEN 1
          ELSE 0
        END ) Sys_Edi,
        (
        CASE
          WHEN Ai.Source          = 'Manual Invoice Entry'
          AND NVL(H.Rel_By,'SYS') = 'SYS'
          THEN 1
          ELSE 0
        END ) Sys_Man,
        (
        CASE
            -- when ai.source not     in ( 'Manual Invoice Entry','US_OD_TDM','US_OD_DCI_TRADE', 'US_OD_TRADE_EDI')
          WHEN ai.source         IN ( 'US_OD_DROPSHIP')
          AND NVL(H.Rel_By,'SYS') = 'SYS'
          THEN 1
          ELSE 0
        END )Sys_Other,
        (
        CASE
          WHEN NVL(H.Rel_By,'SYS') = 'MAN'
          THEN 1
          ELSE 0
        END ) Man_matched
      FROM AP_SUPPLIER_SITES_ALL SIT,
        Ap_Suppliers Sup,
        (SELECT M.Last_Update_Date,
          M.Last_Updated_By,
          M.INVOICE_ID,
          DECODE( M.Last_Updated_By,L_Appsmgr,'SYS',L_Svc_Esp_Fin,'SYS',L_Svc_Esp_Vps,'SYS','MAN') Rel_By
        FROM Ap_Holds_All M
        WHERE rowid =
          (SELECT MAX(Rowid)
          FROM Ap_Holds_All A
          WHERE A.Last_Update_Date =
            (SELECT MAX(b.Last_Update_Date)
            FROM AP_HOLDS_ALL B
              /* WHERE 1=1
              -- AND NVL(B.Status_Flag,'S') = 'S'
              AND B.Invoice_Id = A.Invoice_Id*/
              --Comment 29 Jan
            WHERE 1=1
              -- AND NVL(B.Status_Flag,'S') = 'S'
            AND b.LAST_UPDATE_DATE BETWEEN TO_DATE(TO_CHAR(P_DT_FROM)
              ||' 00:00:00','DD-MON-RR HH24:MI:SS')
            AND TO_DATE(TO_CHAR(P_DT_TO)
              ||' 23:59:59','DD-MON-RR HH24:MI:SS')
            AND B.INVOICE_ID = A.INVOICE_ID
            )
        AND A.LAST_UPDATE_DATE BETWEEN TO_DATE(TO_CHAR(P_DT_FROM)
          ||' 00:00:00','DD-MON-RR HH24:MI:SS')
        AND TO_DATE(TO_CHAR(P_DT_TO)
          ||' 23:59:59','DD-MON-RR HH24:MI:SS')
        AND A.Invoice_Id           = M.Invoice_Id
        AND A.RELEASE_LOOKUP_CODE IS NOT NULL
          )
        ) H,
        Ap_Invoices_All Ai
      WHERE 1                        =1
      AND ai.invoice_type_lookup_code='STANDARD'
      AND H.LAST_UPDATE_DATE BETWEEN TO_DATE(TO_CHAR(P_DT_FROM)
        ||' 00:00:00','DD-MON-RR HH24:MI:SS')
      AND TO_DATE(TO_CHAR(P_DT_TO)
        ||' 23:59:59','DD-MON-RR HH24:MI:SS')
      AND AI.INVOICE_ID = H.INVOICE_ID
        --AND AI.LAST_UPDATE_DATE BETWEEN TO_DATE(TO_CHAR(:P_DT_FROM) ||' 00:00:00','DD-MON-RR HH24:MI:SS')  AND TO_DATE(TO_CHAR(:P_DT_TO)||' 23:59:59','DD-MON-RR HH24:MI:SS')
      AND AI.ORG_ID = NVL(P_ORG_ID,AI.ORG_ID)
        -- Approved Invoice Clause start
        --  AND Ap_Invoices_Pkg.Get_Approval_Status(Ai.Invoice_Id, Ai.Invoice_Amount,Ai.Payment_Status_Flag,Ai.Invoice_Type_Lookup_Code)='APPROVED'
      AND AI.INVOICE_NUM NOT LIKE '%ODDBUIA%'
      AND AI.CANCELLED_DATE IS NULL
      AND EXISTS
        (SELECT 'x'
        FROM Xla_Events Xev,
          XLA_TRANSACTION_ENTITIES XTE
        WHERE XTE.SOURCE_ID_INT_1=AI.INVOICE_ID
        AND XTE.APPLICATION_ID   = 200
        AND XTE.ENTITY_CODE      = 'AP_INVOICES'
        AND XEV.ENTITY_ID        = XTE.ENTITY_ID
        AND XEV.EVENT_TYPE_CODE LIKE '%VALIDATED%'
          --AND xev.last_update_date BETWEEN to_date(TO_CHAR(p_dt_from) ||' 00:00:00','DD-MON-RR HH24:MI:SS')  AND to_date(TO_CHAR(p_dt_to) ||' 23:59:59','DD-MON-RR HH24:MI:SS')
        )
        -- Approved Invoice Clause End
      AND ai.source IN ( 'US_OD_DROPSHIP', 'US_OD_TDM','US_OD_DCI_TRADE','US_OD_TRADE_EDI','Manual Invoice Entry')
      AND EXISTS
        (SELECT 1
        FROM xx_fin_translatevalues tv ,
          xx_fin_translatedefinition td
        WHERE td.TRANSLATION_NAME = 'XX_AP_TR_MATCH_INVOICES'
        AND tv.TRANSLATE_ID       = td.TRANSLATE_ID
        AND tv.enabled_flag       ='Y'
        AND SYSDATE BETWEEN TV.START_DATE_ACTIVE AND NVL(TV.END_DATE_ACTIVE,SYSDATE)
        AND TV.TARGET_VALUE1 = DECODE (P_DROP_SHIP_FLAG,'Y', 'US_OD_DROPSHIP',TV.TARGET_VALUE1 )
        AND TV.TARGET_VALUE1 = NVL(AI.ATTRIBUTE7,AI.SOURCE)
        )
      AND SIT.VENDOR_ID      = NVL(P_VENDOR_ID,SIT.VENDOR_ID)
      AND SIT.Vendor_Site_Id = NVL(P_Vendor_Site_Id,SIT.Vendor_Site_Id)
      AND SIT.VENDOR_SITE_ID = AI.VENDOR_SITE_ID
      AND SUP.VENDOR_ID      = SIT.VENDOR_ID
      AND SIT.ATTRIBUTE6     = NVL(L_VENDASSISTANT_CODE,SIT.ATTRIBUTE6)
      AND SIT.ATTRIBUTE8    IS NOT NULL
      AND EXISTS
        (SELECT 1
        FROM xx_fin_translatevalues tv,
          xx_fin_translatedefinition td
        WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
        AND tv.translate_id       = td.translate_id
        AND tv.enabled_flag       = 'Y'
        AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
        AND Tv.Target_Value1 = Sit.Attribute8
          ||''
        )
        ------Start Post Go-Live code fix 10-Apr-2018 for Revalidated Invoices
      AND NOT EXISTS
        (SELECT 'x'
        FROM ap_holds_all
        WHERE invoice_id         =AI.INVOICE_ID
        AND release_lookup_code IS NULL
        )
      ------End  Post Go-Live code fix 10-Apr-2018 for Revalidated Invoices
      UNION ALL
      SELECT
        /*+ LEADING (ai) */
        NVL(Sit.Attribute6,'Open') Assistant_Code,
        Ai.Vendor_Id,
        Ai.Vendor_Site_Id,
        Sit.Vendor_Site_Code,
        Sup.Segment1 Sup_Num,
        SUP.VENDOR_NAME SUPPLIER,
        AI.LAST_UPDATE_DATE HOLD_REL_DATE,
        AI.LAST_UPDATE_DATE INV_last_upd_date,
        ai.invoice_num,
        (
        CASE
          WHEN AI.SOURCE IN ( 'US_OD_TDM','US_OD_DCI_TRADE')
            -- AND NVL(H.Rel_By,'SYS') = 'SYS'
          THEN 1
          ELSE 0
        END ) Sys_Tdm,
        (
        CASE
          WHEN AI.SOURCE = 'US_OD_TRADE_EDI'
            --  AND NVL(H.Rel_By,'SYS') = 'SYS'
          THEN 1
          ELSE 0
        END ) Sys_Edi,
        (
        CASE
          WHEN AI.SOURCE = 'Manual Invoice Entry'
            --  AND NVL(H.Rel_By,'SYS') = 'SYS'
          THEN 1
          ELSE 0
        END ) Sys_Man,
        (
        CASE
            -- when ai.source not     in ( 'Manual Invoice Entry','US_OD_TDM','US_OD_DCI_TRADE', 'US_OD_TRADE_EDI')
          WHEN AI.SOURCE IN ( 'US_OD_DROPSHIP')
            --  AND NVL(H.Rel_By,'SYS') = 'SYS'
          THEN 1
          ELSE 0
        END )Sys_Other,
        (
        CASE
          WHEN 'SYS' = 'MAN'
          THEN 1
          ELSE 0
        END ) Man_matched
      FROM AP_SUPPLIER_SITES_ALL SIT,
        AP_SUPPLIERS SUP,
        AP_INVOICES_ALL AI
      WHERE 1                        =1
      AND ai.invoice_type_lookup_code='STANDARD'
      AND AI.LAST_UPDATE_DATE BETWEEN TO_DATE(TO_CHAR(P_DT_FROM)
        ||' 00:00:00','DD-MON-RR HH24:MI:SS')
      AND TO_DATE(TO_CHAR(P_DT_TO)
        ||' 23:59:59','DD-MON-RR HH24:MI:SS')
      AND AI.ORG_ID = NVL(P_ORG_ID,AI.ORG_ID)
        -- Approved Invoice Clause start
        --  AND Ap_Invoices_Pkg.Get_Approval_Status(Ai.Invoice_Id, Ai.Invoice_Amount,Ai.Payment_Status_Flag,Ai.Invoice_Type_Lookup_Code)='APPROVED'
      AND AI.INVOICE_NUM NOT LIKE '%ODDBUIA%'
      AND AI.CANCELLED_DATE IS NULL
      AND EXISTS
        (SELECT 'x'
        FROM Xla_Events Xev,
          XLA_TRANSACTION_ENTITIES XTE
        WHERE XTE.SOURCE_ID_INT_1=AI.INVOICE_ID
        AND XTE.APPLICATION_ID   = 200
        AND XTE.ENTITY_CODE      = 'AP_INVOICES'
        AND XEV.ENTITY_ID        = XTE.ENTITY_ID
        AND XEV.EVENT_TYPE_CODE LIKE '%VALIDATED%'
        )
      AND AI.SOURCE IN ( 'US_OD_DROPSHIP', 'US_OD_TDM','US_OD_DCI_TRADE','US_OD_TRADE_EDI','Manual Invoice Entry')
      AND EXISTS
        (SELECT 1
        FROM XX_FIN_TRANSLATEVALUES TV ,
          xx_fin_translatedefinition td
        WHERE td.TRANSLATION_NAME = 'XX_AP_TR_MATCH_INVOICES'
        AND tv.TRANSLATE_ID       = td.TRANSLATE_ID
        AND tv.enabled_flag       ='Y'
        AND SYSDATE BETWEEN TV.START_DATE_ACTIVE AND NVL(TV.END_DATE_ACTIVE,SYSDATE)
        AND TV.TARGET_VALUE1 = DECODE (P_DROP_SHIP_FLAG,'Y', 'US_OD_DROPSHIP',TV.TARGET_VALUE1 )
        AND TV.TARGET_VALUE1 = NVL(AI.ATTRIBUTE7,AI.SOURCE)
        )
      AND SIT.VENDOR_ID      = NVL(P_VENDOR_ID,SIT.VENDOR_ID)
      AND SIT.VENDOR_SITE_ID = NVL(P_VENDOR_SITE_ID,SIT.VENDOR_SITE_ID)
      AND SIT.VENDOR_SITE_ID = AI.VENDOR_SITE_ID
      AND SUP.VENDOR_ID      = SIT.VENDOR_ID
      AND SIT.ATTRIBUTE6     = NVL(L_VENDASSISTANT_CODE,SIT.ATTRIBUTE6)
      AND SIT.ATTRIBUTE8    IS NOT NULL
      AND EXISTS
        (SELECT 1
        FROM XX_FIN_TRANSLATEVALUES TV,
          xx_fin_translatedefinition td
        WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
        AND tv.translate_id       = td.translate_id
        AND tv.enabled_flag       = 'Y'
        AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
        AND Tv.Target_Value1 = Sit.Attribute8
          ||''
        )
        ------Start Post Go-Live code fix 10-Apr-2018 for Revalidated Invoices
        /*  AND NOT EXISTS
        (SELECT 'x' FROM AP_HOLDS_ALL H1 WHERE H1.INVOICE_ID =AI.INVOICE_ID
        )*/
      AND NOT EXISTS
        (SELECT 'x'
        FROM ap_holds_all
        WHERE invoice_id         =AI.INVOICE_ID
        AND release_lookup_code IS NULL
        )
        ------end  Post Go-Live code fix 10-Apr-2018 for Revalidated Invoices
      ) B
    GROUP BY B.Assistant_Code,
      B.Vendor_Id,
      B.Vendor_Site_Id,
      B.Vendor_Site_Code,
      B.Sup_Num,
      B.Supplier;
    -- Report option Vendor Assistant
    --Added 29 Jan
    CURSOR c_Hold_Assist (p_dt_from DATE,p_dt_to DATE)
    IS
      SELECT B.Assistant_Code,
        Xx_Ap_Dashboard_Rpt_Pkg.Vendor_Assistant(B.Assistant_Code) vendor_Assistant,
        SUM ( B.Sys_Tdm) Sys_Tdm,
        SUM ( B.Sys_Edi) Sys_Edi,
        SUM ( B.Sys_Man) Sys_Man,
        SUM( B.Sys_Other) Sys_Other,
        SUM( b.man_matched ) man_matched
      FROM
        (SELECT
          /*+ LEADING (h) */
          NVL(Sit.Attribute6,'Open') Assistant_Code,
          Ai.Vendor_Id,
          Ai.Vendor_Site_Id,
          Sit.Vendor_Site_Code,
          Sup.Segment1 Sup_Num,
          SUP.VENDOR_NAME SUPPLIER,
          H.LAST_UPDATE_DATE HOLD_REL_DATE,
          AI.LAST_UPDATE_DATE INV_last_upd_date,
          ai.invoice_num,
          (
          CASE
            WHEN Ai.Source         IN ( 'US_OD_TDM','US_OD_DCI_TRADE')
            AND NVL(H.Rel_By,'SYS') = 'SYS'
            THEN 1
            ELSE 0
          END ) Sys_Tdm,
          (
          CASE
            WHEN Ai.Source          = 'US_OD_TRADE_EDI'
            AND NVL(H.Rel_By,'SYS') = 'SYS'
            THEN 1
            ELSE 0
          END ) Sys_Edi,
          (
          CASE
            WHEN Ai.Source          = 'Manual Invoice Entry'
            AND NVL(H.Rel_By,'SYS') = 'SYS'
            THEN 1
            ELSE 0
          END ) Sys_Man,
          (
          CASE
              -- when ai.source not     in ( 'Manual Invoice Entry','US_OD_TDM','US_OD_DCI_TRADE', 'US_OD_TRADE_EDI')
            WHEN ai.source         IN ( 'US_OD_DROPSHIP')
            AND NVL(H.Rel_By,'SYS') = 'SYS'
            THEN 1
            ELSE 0
          END )Sys_Other,
          (
          CASE
            WHEN NVL(H.Rel_By,'SYS') = 'MAN'
            THEN 1
            ELSE 0
          END ) Man_matched
        FROM AP_SUPPLIER_SITES_ALL SIT,
          Ap_Suppliers Sup,
          (SELECT M.Last_Update_Date,
            M.Last_Updated_By,
            M.INVOICE_ID,
            DECODE( M.Last_Updated_By,L_Appsmgr,'SYS',L_Svc_Esp_Fin,'SYS',L_Svc_Esp_Vps,'SYS','MAN') Rel_By
          FROM Ap_Holds_All M
          WHERE rowid =
            (SELECT MAX(Rowid)
            FROM Ap_Holds_All A
            WHERE A.Last_Update_Date =
              (SELECT MAX(b.Last_Update_Date)
              FROM AP_HOLDS_ALL B
                /* WHERE 1=1
                -- AND NVL(B.Status_Flag,'S') = 'S'
                AND B.Invoice_Id = A.Invoice_Id*/
                -- Commented 29 Jan
              WHERE 1=1
                -- AND NVL(B.Status_Flag,'S') = 'S'
              AND b.LAST_UPDATE_DATE BETWEEN TO_DATE(TO_CHAR(P_DT_FROM)
                ||' 00:00:00','DD-MON-RR HH24:MI:SS')
              AND TO_DATE(TO_CHAR(P_DT_TO)
                ||' 23:59:59','DD-MON-RR HH24:MI:SS')
              AND B.INVOICE_ID = A.INVOICE_ID
              )
          AND A.LAST_UPDATE_DATE BETWEEN TO_DATE(TO_CHAR(P_DT_FROM)
            ||' 00:00:00','DD-MON-RR HH24:MI:SS')
          AND TO_DATE(TO_CHAR(P_DT_TO)
            ||' 23:59:59','DD-MON-RR HH24:MI:SS')
          AND A.Invoice_Id           = M.Invoice_Id
          AND A.RELEASE_LOOKUP_CODE IS NOT NULL
            )
          ) H,
          Ap_Invoices_All Ai
        WHERE 1                        =1
        AND ai.invoice_type_lookup_code='STANDARD'
        AND H.LAST_UPDATE_DATE BETWEEN TO_DATE(TO_CHAR(P_DT_FROM)
          ||' 00:00:00','DD-MON-RR HH24:MI:SS')
        AND TO_DATE(TO_CHAR(P_DT_TO)
          ||' 23:59:59','DD-MON-RR HH24:MI:SS')
        AND AI.INVOICE_ID = H.INVOICE_ID
          --AND AI.LAST_UPDATE_DATE BETWEEN TO_DATE(TO_CHAR(:P_DT_FROM) ||' 00:00:00','DD-MON-RR HH24:MI:SS')  AND TO_DATE(TO_CHAR(:P_DT_TO)||' 23:59:59','DD-MON-RR HH24:MI:SS')
        AND AI.ORG_ID = NVL(P_ORG_ID,AI.ORG_ID)
          -- Approved Invoice Clause start
          --  AND Ap_Invoices_Pkg.Get_Approval_Status(Ai.Invoice_Id, Ai.Invoice_Amount,Ai.Payment_Status_Flag,Ai.Invoice_Type_Lookup_Code)='APPROVED'
        AND AI.INVOICE_NUM NOT LIKE '%ODDBUIA%'
        AND AI.CANCELLED_DATE IS NULL
        AND EXISTS
          (SELECT 'x'
          FROM Xla_Events Xev,
            XLA_TRANSACTION_ENTITIES XTE
          WHERE XTE.SOURCE_ID_INT_1=AI.INVOICE_ID
          AND XTE.APPLICATION_ID   = 200
          AND XTE.ENTITY_CODE      = 'AP_INVOICES'
          AND XEV.ENTITY_ID        = XTE.ENTITY_ID
          AND XEV.EVENT_TYPE_CODE LIKE '%VALIDATED%'
            --AND xev.last_update_date BETWEEN to_date(TO_CHAR(p_dt_from) ||' 00:00:00','DD-MON-RR HH24:MI:SS')  AND to_date(TO_CHAR(p_dt_to) ||' 23:59:59','DD-MON-RR HH24:MI:SS')
          )
          -- Approved Invoice Clause End
        AND ai.source IN ( 'US_OD_DROPSHIP', 'US_OD_TDM','US_OD_DCI_TRADE','US_OD_TRADE_EDI','Manual Invoice Entry')
        AND EXISTS
          (SELECT 1
          FROM xx_fin_translatevalues tv ,
            xx_fin_translatedefinition td
          WHERE td.TRANSLATION_NAME = 'XX_AP_TR_MATCH_INVOICES'
          AND tv.TRANSLATE_ID       = td.TRANSLATE_ID
          AND tv.enabled_flag       ='Y'
          AND SYSDATE BETWEEN TV.START_DATE_ACTIVE AND NVL(TV.END_DATE_ACTIVE,SYSDATE)
          AND TV.TARGET_VALUE1 = DECODE (P_DROP_SHIP_FLAG,'Y', 'US_OD_DROPSHIP',TV.TARGET_VALUE1 )
          AND TV.TARGET_VALUE1 = NVL(AI.ATTRIBUTE7,AI.SOURCE)
          )
        AND SIT.VENDOR_ID      = NVL(P_VENDOR_ID,SIT.VENDOR_ID)
        AND SIT.Vendor_Site_Id = NVL(P_Vendor_Site_Id,SIT.Vendor_Site_Id)
        AND SIT.VENDOR_SITE_ID = AI.VENDOR_SITE_ID
        AND SUP.VENDOR_ID      = SIT.VENDOR_ID
        AND SIT.ATTRIBUTE6     = NVL(L_VENDASSISTANT_CODE,SIT.ATTRIBUTE6)
        AND SIT.ATTRIBUTE8    IS NOT NULL
        AND EXISTS
          (SELECT 1
          FROM xx_fin_translatevalues tv,
            xx_fin_translatedefinition td
          WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
          AND tv.translate_id       = td.translate_id
          AND tv.enabled_flag       = 'Y'
          AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
          AND Tv.Target_Value1 = Sit.Attribute8
            ||''
          )
          ------Start Post Go-Live code fix 10-Apr-2018 for Revalidated Invoices
        AND NOT EXISTS
          (SELECT 'x'
          FROM ap_holds_all
          WHERE invoice_id         =AI.INVOICE_ID
          AND release_lookup_code IS NULL
          )
        ------End  Post Go-Live code fix 10-Apr-2018 for Revalidated Invoices
        UNION ALL
        SELECT
          /*+ LEADING (ai) */
          NVL(Sit.Attribute6,'Open') Assistant_Code,
          Ai.Vendor_Id,
          Ai.Vendor_Site_Id,
          Sit.Vendor_Site_Code,
          Sup.Segment1 Sup_Num,
          SUP.VENDOR_NAME SUPPLIER,
          AI.LAST_UPDATE_DATE HOLD_REL_DATE,
          AI.LAST_UPDATE_DATE INV_last_upd_date,
          ai.invoice_num,
          (
          CASE
            WHEN AI.SOURCE IN ( 'US_OD_TDM','US_OD_DCI_TRADE')
              -- AND NVL(H.Rel_By,'SYS') = 'SYS'
            THEN 1
            ELSE 0
          END ) Sys_Tdm,
          (
          CASE
            WHEN AI.SOURCE = 'US_OD_TRADE_EDI'
              --  AND NVL(H.Rel_By,'SYS') = 'SYS'
            THEN 1
            ELSE 0
          END ) Sys_Edi,
          (
          CASE
            WHEN AI.SOURCE = 'Manual Invoice Entry'
              --  AND NVL(H.Rel_By,'SYS') = 'SYS'
            THEN 1
            ELSE 0
          END ) Sys_Man,
          (
          CASE
              -- when ai.source not     in ( 'Manual Invoice Entry','US_OD_TDM','US_OD_DCI_TRADE', 'US_OD_TRADE_EDI')
            WHEN AI.SOURCE IN ( 'US_OD_DROPSHIP')
              --  AND NVL(H.Rel_By,'SYS') = 'SYS'
            THEN 1
            ELSE 0
          END )Sys_Other,
          (
          CASE
            WHEN 'SYS' = 'MAN'
            THEN 1
            ELSE 0
          END ) Man_matched
        FROM AP_SUPPLIER_SITES_ALL SIT,
          AP_SUPPLIERS SUP,
          AP_INVOICES_ALL AI
        WHERE 1                        =1
        AND ai.invoice_type_lookup_code='STANDARD'
        AND AI.LAST_UPDATE_DATE BETWEEN TO_DATE(TO_CHAR(P_DT_FROM)
          ||' 00:00:00','DD-MON-RR HH24:MI:SS')
        AND TO_DATE(TO_CHAR(P_DT_TO)
          ||' 23:59:59','DD-MON-RR HH24:MI:SS')
        AND AI.ORG_ID = NVL(P_ORG_ID,AI.ORG_ID)
          -- Approved Invoice Clause start
          --  AND Ap_Invoices_Pkg.Get_Approval_Status(Ai.Invoice_Id, Ai.Invoice_Amount,Ai.Payment_Status_Flag,Ai.Invoice_Type_Lookup_Code)='APPROVED'
        AND AI.INVOICE_NUM NOT LIKE '%ODDBUIA%'
        AND AI.CANCELLED_DATE IS NULL
        AND EXISTS
          (SELECT 'x'
          FROM Xla_Events Xev,
            XLA_TRANSACTION_ENTITIES XTE
          WHERE XTE.SOURCE_ID_INT_1=AI.INVOICE_ID
          AND XTE.APPLICATION_ID   = 200
          AND XTE.ENTITY_CODE      = 'AP_INVOICES'
          AND XEV.ENTITY_ID        = XTE.ENTITY_ID
          AND XEV.EVENT_TYPE_CODE LIKE '%VALIDATED%'
          )
        AND AI.SOURCE IN ( 'US_OD_DROPSHIP', 'US_OD_TDM','US_OD_DCI_TRADE','US_OD_TRADE_EDI','Manual Invoice Entry')
        AND EXISTS
          (SELECT 1
          FROM XX_FIN_TRANSLATEVALUES TV ,
            xx_fin_translatedefinition td
          WHERE td.TRANSLATION_NAME = 'XX_AP_TR_MATCH_INVOICES'
          AND tv.TRANSLATE_ID       = td.TRANSLATE_ID
          AND tv.enabled_flag       ='Y'
          AND SYSDATE BETWEEN TV.START_DATE_ACTIVE AND NVL(TV.END_DATE_ACTIVE,SYSDATE)
          AND TV.TARGET_VALUE1 = DECODE (P_DROP_SHIP_FLAG,'Y', 'US_OD_DROPSHIP',TV.TARGET_VALUE1 )
          AND TV.TARGET_VALUE1 = NVL(AI.ATTRIBUTE7,AI.SOURCE)
          )
        AND SIT.VENDOR_ID      = NVL(P_VENDOR_ID,SIT.VENDOR_ID)
        AND SIT.VENDOR_SITE_ID = NVL(P_VENDOR_SITE_ID,SIT.VENDOR_SITE_ID)
        AND SIT.VENDOR_SITE_ID = AI.VENDOR_SITE_ID
        AND SUP.VENDOR_ID      = SIT.VENDOR_ID
        AND SIT.ATTRIBUTE6     = NVL(L_VENDASSISTANT_CODE,SIT.ATTRIBUTE6)
        AND SIT.ATTRIBUTE8    IS NOT NULL
        AND EXISTS
          (SELECT 1
          FROM XX_FIN_TRANSLATEVALUES TV,
            xx_fin_translatedefinition td
          WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
          AND tv.translate_id       = td.translate_id
          AND tv.enabled_flag       = 'Y'
          AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
          AND Tv.Target_Value1 = Sit.Attribute8
            ||''
          )
          ------Start Post Go-Live code fix 10-Apr-2018 for Revalidated Invoices
          /*  AND NOT EXISTS
          (SELECT 'x' FROM AP_HOLDS_ALL H1 WHERE H1.INVOICE_ID =AI.INVOICE_ID
          )*/
        AND NOT EXISTS
          (SELECT 'x'
          FROM ap_holds_all
          WHERE invoice_id         =AI.INVOICE_ID
          AND release_lookup_code IS NULL
          )
          ------End  Post Go-Live code fix 10-Apr-2018 for Revalidated Invoices
        ) B
      GROUP BY B.Assistant_Code ;
      --chargeback_db_tab xx_ap_dashboard_rpt_pkg.ap_trade_match_analysis_ctt;
    TYPE ap_trade_match_analysis
  IS
    TABLE OF xx_ap_dashboard_rpt_pkg.ap_trade_match_analysis INDEX BY PLS_INTEGER;
    l_ap_trade_mat_ana ap_trade_match_analysis;
    l_error_count NUMBER;
    ex_dml_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT(ex_dml_errors, -24381);
    n             NUMBER := 0;
    l_start_date  DATE;
    L_END_DATE    DATE;
    l_total       NUMBER;
    L_MAN_INV     NUMBER := 0;
    L_TDM_INV     NUMBER := 0;
    L_EDI_INV     NUMBER := 0;
    L_OTH_INV     NUMBER := 0;
    L_Man_Matched NUMBER := 0;
  BEGIN
    xla_security_pkg.set_security_context(602);
    IF p_period_from IS NOT NULL AND p_period_to IS NOT NULL THEN
      BEGIN
        SELECT start_date
        INTO l_start_date
        FROM gl_periods
        WHERE 1         =1
        AND period_name = p_period_from;
      EXCEPTION
      WHEN OTHERS THEN
        l_start_date := sysdate;
      END;
      BEGIN
        SELECT end_date
        INTO l_end_date
        FROM gl_periods
        WHERE 1         =1
        AND period_name = p_period_to;
      EXCEPTION
      WHEN OTHERS THEN
        l_start_date := sysdate;
      END;
    END IF;
    IF ( p_date_from IS NOT NULL AND p_date_to IS NOT NULL ) THEN
      l_start_date   := p_date_from;
      l_end_date     := p_date_to;
    END IF;
    IF P_Assist IS NOT NULL THEN
      BEGIN
        SELECT b.target_value1
        INTO L_Vendassistant_Code
        FROM Xx_Fin_Translatevalues B ,
          xx_fin_translatedefinition a
        WHERE a.TRANSLATION_NAME = 'XX_AP_VENDOR_ASSISTANTS'
        AND b.TRANSLATE_ID       = a.TRANSLATE_ID
        AND b.enabled_flag       ='Y'
        AND Sysdate BETWEEN B.Start_Date_Active AND NVL(B.End_Date_Active,Sysdate)
        AND B.Target_Value2 = P_Assist;
      EXCEPTION
      WHEN OTHERS THEN
        L_Vendassistant_Code := NULL;
      END;
    ELSE
      L_Vendassistant_Code := NULL;
    END IF;
    -- Get System user ID
    BEGIN
      SELECT MAX(DECODE(U.User_Name,'SVC_ESP_VPS',U.User_Id,-1)),
        MAX(DECODE(U.User_Name,'SVC_ESP_FIN',U.User_Id,     -1)),
        MAX(DECODE(U.User_Name,'APPSMGR',U.User_Id,         -1))
      INTO L_Svc_Esp_Vps,
        L_Svc_Esp_Fin,
        L_Appsmgr
      FROM Fnd_User U
      WHERE U.User_Name IN ('SVC_ESP_VPS', 'SVC_ESP_FIN','APPSMGR') ;
    EXCEPTION
    WHEN OTHERS THEN
      L_Svc_Esp_Vps:= 3839857;
      L_Svc_Esp_Fin:=90102;
      L_Appsmgr    := 5;
    END;
    IF l_ap_trade_mat_ana.count > 0 THEN
      l_ap_trade_mat_ana.delete;
    END IF;
    --dbms_output.put_line ('Date '||l_start_date||' - '||l_end_date);
    -- Vendor Assistant Report option
    IF P_report_option = 'A' THEN
      FOR i IN c_Hold_Assist (l_start_date,l_end_date)
      LOOP
        L_MAN_INV                             := 0;
        L_TDM_INV                             := 0;
        L_EDI_INV                             := 0;
        L_OTH_INV                             := 0;
        L_Man_Matched                         := 0;
        L_Total                               := 0;
        L_Man_Inv                             := I.Sys_Man;
        L_Tdm_Inv                             := I.Sys_Tdm;
        L_Edi_Inv                             := I.Sys_Edi;
        L_Oth_Inv                             := I.Sys_Other;
        L_Man_Matched                         := i.man_matched;
        L_Ap_Trade_Mat_Ana(N).Assistant_Code  := I.Assistant_Code;
        L_Ap_Trade_Mat_Ana(N).VendorAsistant  := i.vendor_Assistant;
        l_ap_trade_mat_ana(n).Man_inv         := L_Man_inv;
        l_ap_trade_mat_ana(n).TDM_inv         := L_TDM_inv;
        l_ap_trade_mat_ana(n).EDI_inv         := L_EDI_inv;
        L_AP_TRADE_MAT_ANA(N).OTH_INV         := L_OTH_INV;
        L_AP_TRADE_MAT_ANA(N).MANUALY_MATCHED := L_MAN_MATCHED;
        --  Total Invoice Count: Sum of QM Online, TDM, EDI, Others and Manually Matched columns
        L_TOTAL                               := L_MAN_INV + L_TDM_INV + L_EDI_INV+ L_OTH_INV + L_MAN_MATCHED;
        L_AP_TRADE_MAT_ANA(N).TOTAL_INV_COUNT := l_total;
        L_AP_TRADE_MAT_ANA(N).SYSTEM_MATCHED  := L_MAN_INV + L_TDM_INV + L_EDI_INV+ L_OTH_INV;
        -- System matched %: ( (Total Invoice Count - Manually Matched) / Total Invoice Count) * 100
        L_AP_TRADE_MAT_ANA(N).SYSTEM_MATCHED_PER := (( l_total - L_MAN_MATCHED) / l_total) *100 ;
        -- MANUALLY MATCHED %: (MANUALLY MATCHED / TOTAL INVOICE COUNT) * 100
        L_AP_TRADE_MAT_ANA(N).manually_matched_per := ( L_MAN_MATCHED/l_total) *100;
        n                                          := n              +1;
      END LOOP;
    ELSE
      FOR i IN c_Hold_Vendor (l_start_date,l_end_date)
      LOOP
        L_MAN_INV                              := 0;
        L_TDM_INV                              := 0;
        L_EDI_INV                              := 0;
        L_OTH_INV                              := 0;
        L_Man_Matched                          := 0;
        L_Total                                := 0;
        L_Man_Inv                              := I.Sys_Man;
        L_Tdm_Inv                              := I.Sys_Tdm;
        L_Edi_Inv                              := I.Sys_Edi;
        L_Oth_Inv                              := I.Sys_Other;
        L_Man_Matched                          := i.man_matched;
        l_ap_trade_mat_ana(n).vendor_id        := i.vendor_id;
        l_ap_trade_mat_ana(n).vendor_site_id   := i.vendor_site_id;
        L_Ap_Trade_Mat_Ana(N).Assistant_Code   := I.Assistant_Code;
        L_Ap_Trade_Mat_Ana(N).VendorAsistant   := i.vendor_Assistant;
        l_ap_trade_mat_ana(n).Sup_num          := i.Sup_num;
        l_ap_trade_mat_ana(n).supplier         := i.supplier;
        L_Ap_Trade_Mat_Ana(N).Vendor_Site_Code := I.Vendor_Site_Code;
        l_ap_trade_mat_ana(n).Man_inv          := L_Man_inv;
        l_ap_trade_mat_ana(n).TDM_inv          := L_TDM_inv;
        l_ap_trade_mat_ana(n).EDI_inv          := L_EDI_inv;
        L_AP_TRADE_MAT_ANA(N).OTH_INV          := L_OTH_INV;
        L_AP_TRADE_MAT_ANA(N).MANUALY_MATCHED  := L_MAN_MATCHED;
        --  Total Invoice Count: Sum of QM Online, TDM, EDI, Others and Manually Matched columns
        L_TOTAL                               := L_MAN_INV + L_TDM_INV + L_EDI_INV+ L_OTH_INV + L_MAN_MATCHED;
        L_AP_TRADE_MAT_ANA(N).TOTAL_INV_COUNT := l_total;
        L_AP_TRADE_MAT_ANA(N).SYSTEM_MATCHED  := L_MAN_INV + L_TDM_INV + L_EDI_INV+ L_OTH_INV;
        -- System matched %: ( (Total Invoice Count - Manually Matched) / Total Invoice Count) * 100
        L_AP_TRADE_MAT_ANA(N).SYSTEM_MATCHED_PER := (( l_total - L_MAN_MATCHED) / l_total) *100 ;
        -- MANUALLY MATCHED %: (MANUALLY MATCHED / TOTAL INVOICE COUNT) * 100
        L_AP_TRADE_MAT_ANA(N).manually_matched_per := ( L_MAN_MATCHED/l_total) *100;
        n                                          := n              +1;
      END LOOP;
    END IF;
    -- Place holder for null data
    IF L_AP_TRADE_MAT_ANA.COUNT                   = 0 THEN
      l_ap_trade_mat_ana(n).OU_NAME              := NULL;
      l_ap_trade_mat_ana(n).Invoice_id           := NULL;
      l_ap_trade_mat_ana(n).invoice_date         := NULL;
      l_ap_trade_mat_ana(n).INVOICE_NUM          := NULL;
      l_ap_trade_mat_ana(n).vendor_id            := NULL;
      l_ap_trade_mat_ana(n).vendor_site_id       := NULL;
      l_ap_trade_mat_ana(n).assistant_code       := NULL;
      l_ap_trade_mat_ana(n).VendorAsistant       := NULL;
      L_AP_TRADE_MAT_ANA(N).PO_TYPE              := NULL;
      l_ap_trade_mat_ana(n).Sup_num              := NULL;
      l_ap_trade_mat_ana(n).supplier             := NULL;
      l_ap_trade_mat_ana(n).vendor_site_code     := NULL;
      l_ap_trade_mat_ana(n).inv_source           := NULL;
      l_ap_trade_mat_ana(n).Oracle_User_Name     := NULL;
      l_ap_trade_mat_ana(n).Man_inv              := 0;
      l_ap_trade_mat_ana(n).TDM_inv              := 0;
      l_ap_trade_mat_ana(n).EDI_inv              := 0;
      l_ap_trade_mat_ana(n).OTH_inv              := 0;
      l_ap_trade_mat_ana(n).Manualy_matched      := 0;
      l_ap_trade_mat_ana(n).system_matched       := 0;
      l_ap_trade_mat_ana(n).system_matched_per   := 0;
      l_ap_trade_mat_ana(n).manually_matched_per := 0;
    END IF;
    FOR i IN l_ap_trade_mat_ana.First .. l_ap_trade_mat_ana.last
    LOOP
      --dbms_output.put_line('Test '||l_ap_trade_rtv_recon(i).RTV_NUMBER);
      PIPE ROW ( l_ap_trade_mat_ana(I) ) ;
    END LOOP;
    RETURN;
  EXCEPTION
  WHEN ex_dml_errors THEN
    l_error_count := SQL%BULK_EXCEPTIONS.count;
    DBMS_OUTPUT.put_line('Number of failures: ' || l_error_count);
    FOR i IN 1 .. l_error_count
    LOOP
      DBMS_OUTPUT.put_line ( 'Error: ' || i || ' Array Index: ' || SQL%BULK_EXCEPTIONS(i).error_index || ' Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE) ) ;
    END LOOP;
  END Xx_Ap_Trade_Match_Analysis;
END xx_ap_dashboard_rpt_pkg;
/
SHOW ERRORS;