-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | NAME        : XX_AP_TRADE_INVOICE_MV.vw                                  |
-- | RICE#       : ES3522  OD:Dashboard Reports Sol#211,213,214,215,216,217,218|                                          
-- | DESCRIPTION : Create the MAteralized view of ap_invoices_all for         |
-- |               better    performance                                      |
-- |                            .                                             |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ===========  =============        ==============================|
-- | V1.0     18-Jan-2018  Digamber Somavanshi  Initial version               |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

CREATE MATERIALIZED VIEW XX_AP_TRADE_INVOICE_MV (ORG_ID, INVOICE_ID, INVOICE_NUM, APPROVAL_STATUS, VENDOR_ID, VENDOR_SITE_ID, INVOICE_DATE, GL_DATE, CREATION_DATE, LAST_UPDATE_DATE, TRADE_SOURCE, INVOICE_SOURCE, INVOICE_TYPE, QUICK_PO_HEADER_ID, PO_HEADER_ID, INVOICE_AMOUNT)
  ORGANIZATION HEAP PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 131072 NEXT 131072 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE APPS_TS_TX_DATA 
  BUILD IMMEDIATE
  USING INDEX 
  REFRESH FORCE ON DEMAND START WITH sysdate+0 NEXT SYSDATE+1/24
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  USING ENFORCED CONSTRAINTS EVALUATE USING CURRENT EDITION  DISABLE QUERY REWRITE
  AS SELECT ai.Org_Id,
    Ai.Invoice_Id,
    Ai.Invoice_Num,
    apps.Ap_Invoices_Pkg.Get_Approval_Status(Ai.Invoice_Id, Ai.Invoice_Amount,Ai.Payment_Status_Flag,Ai.Invoice_Type_Lookup_Code)Approval_Status ,
    Ai.Vendor_Id,
    Ai.Vendor_Site_Id,
    Ai.Invoice_Date,
    ai.Gl_Date,
    Ai.Creation_Date,
    Ai.Last_Update_Date,
    Ai.Attribute7 TRADE_SOURCE,
    Ai.Source Invoice_Source,
    Ai.Invoice_Type_Lookup_Code Invoice_Type,
    Ai.Quick_Po_Header_Id ,
    Ai.Po_Header_Id,
    AI.INVOICE_AMOUNT
  FROM AP.AP_INVOICES_ALL AI,
  AP_SUPPLIER_SITES_ALL SIT
  WHERE 1=1
   AND AI.CREATION_DATE  > SYSDATE -2
   AND   apps.Ap_Invoices_Pkg.Get_Approval_Status(Ai.Invoice_Id, Ai.Invoice_Amount,Ai.Payment_Status_Flag,Ai.Invoice_Type_Lookup_Code) = 'APPROVED'
  AND EXISTS
    (SELECT 1
    FROM xx_fin_translatevalues tv ,
      xx_fin_translatedefinition td
    WHERE td.TRANSLATION_NAME = 'XX_AP_TR_MATCH_INVOICES'
    AND tv.TRANSLATE_ID       = td.TRANSLATE_ID
    AND tv.enabled_flag       ='Y'
    AND Sysdate BETWEEN Tv.Start_Date_Active AND NVL(Tv.End_Date_Active,Sysdate)
    AND Tv.Target_Value1 = Ai.Source
    )
  AND Sit.Vendor_Site_Id = Ai.Vendor_Site_Id
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
    );

   COMMENT ON MATERIALIZED VIEW XX_AP_TRADE_INVOICE_MV  IS 'snapshot table for snapshot APPS.XX_AP_TRADE_INVOICE_MV';

SHOW ERRORS;
EXIT;