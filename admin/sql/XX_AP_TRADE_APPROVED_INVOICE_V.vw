-- +===============================================================================+
-- |                  Office Depot - Project Simplify                               |
-- +===============================================================================+
-- | NAME        : XX_AP_TRADE_APPROVED_INVOICE_V.vw                                |
-- | RICE#       : ES3522  OD:Dashboard Reports Sol#211,213,214,215,216,217,218,219 |                                          
-- | DESCRIPTION : Create the  view of XX_AP_TRADE_APPROVED_INVOICE                 |
-- |               better    performance                                            |
-- |                            .                                                   |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author               Remarks                             |
-- |=======   ===========  =============        ====================================|
-- | V1.0     18-Jan-2018  Digamber Somavanshi  Initial version                     |
-- +================================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

CREATE OR REPLACE  VIEW XX_AP_TRADE_APPROVED_INVOICE_V (ORG_ID, INVOICE_ID, INVOICE_NUM, APPROVAL_STATUS, VENDOR_ID, VENDOR_SITE_ID, INVOICE_DATE, GL_DATE, CREATION_DATE, LAST_UPDATE_DATE, INVOICE_SOURCE, INVOICE_TYPE, PO_HEADER_ID, INVOICE_AMOUNT) AS 
  (
 Select Ai.Org_Id,
    Ai.Invoice_Id,
    Ai.Invoice_Num,
    ai.Approval_Status ,
    Ai.Vendor_Id,
    Ai.Vendor_Site_Id,
    Ai.Invoice_Date,
    ai.Gl_Date,
    Ai.Creation_Date,
    Ai.Last_Update_Date,
    NVL(Ai.TRADE_SOURCE,Ai.Invoice_Source) Invoice_Source,
    Ai.Invoice_Type,
    NVL( Ai.Po_Header_Id,Ai.Quick_Po_Header_Id ) Po_Header_Id,
    Ai.Invoice_Amount
 From Xx_Ap_Trade_approved_Invoice ai
Union All
   SELECT ai.Org_Id,
    Ai.Invoice_Id,
    Ai.Invoice_Num,
    ai.Approval_Status ,
    Ai.Vendor_Id,
    Ai.Vendor_Site_Id,
    Ai.Invoice_Date,
    ai.Gl_Date,
    Ai.Creation_Date,
    Ai.Last_Update_Date,
     NVL(Ai.TRADE_SOURCE,Ai.Invoice_Source) Invoice_Source,
    Ai.Invoice_Type,
    NVL( Ai.Po_Header_Id,Ai.Quick_Po_Header_Id ) Po_Header_Id,
    Ai.Invoice_Amount
 FROM XX_AP_TRADE_INVOICE_MV AI);

SHOW ERRORS;
EXIT;