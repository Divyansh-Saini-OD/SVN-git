SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  XX_AP_INV_TERMS_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL 

WHENEVER SQLERROR CONTINUE

create or replace
PACKAGE XX_AP_INV_TERMS_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name :  E1281                                                       |
-- | Description : TO extend the Oracle validation process to            |
-- |               automatically assign the receipt date to the invoice  |
-- |               Terms Date when the invoice and PO match takes place  |
-- |               If no receipt exists the invoice should be placed on  |
-- |               'OD No Receipt Hold' .                                |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0       23-MAY-2007   Chaitanya Nath        Initial version        |
-- |                       Wipro Technologies                            |
-- |1.1       22-OCT-2007   Sandeep Pandhare      Defect 2053        |
-- |1.2       14-FEB-2008   Greg Dill             To fix defect 3845     |
-- +=====================================================================+

-- +==========================================================================+
-- | Name : INV_TERMS_DATE                                                    |
-- | Description :  To populate the Terms Date of the invoice in the table    |
-- |                XX_AP_INV_INTERFACE_STG with the receipt date             |
-- |                and if more than one receipt exists then terms            |
-- |                date will be populted with the latest of all              |
-- |                the receipt dates.                                        |
-- |                                                                          |
-- | Parameters : p_invoice_num,p_po_number,p_invoice_date,                   |      
-- |                                   P_DATE_GOODS_REC, p_vendor_d           |
-- |                                                                          |
-- +==========================================================================+

   PROCEDURE INV_TERMS_DATE(
      p_invoice_num    IN VARCHAR2
     ,p_po_number      IN po_headers.SEGMENT1%TYPE --defect 3845
     ,P_INVOICE_DATE   IN OUT DATE  -- defect 2053
     ,P_DATE_GOODS_REC OUT DATE     -- Added per CR729
     ,P_RELEASE_NUM    IN  NUMBER   -- Added per CR729
     ,p_vendor_id      IN  NUMBER
       );
-- +==========================================================================+
-- | Name : INV_HOLD                                                          |
-- | Description :  To keep the invocies without the receipt on 'OD No Receipt|
-- |                 Hold' and update the global attribute2  column in the    |
-- |                table  XX_AP_INV_INTERFACE_STG with 'H'                   |
-- |                                                                          |
-- | Parameters : p_batch_id,p_source,p_group_id,p_hold_name                  |
-- |                                                                          |
-- | Returns    :  x_error_buff,x_ret_code                                    |
-- +==========================================================================+

   PROCEDURE INV_HOLD(
      x_error_buff       OUT  VARCHAR2
     ,x_ret_code         OUT  NUMBER
     ,p_batch_id         IN   VARCHAR2
     ,p_group_id         IN   VARCHAR2
     ,p_source           IN   VARCHAR2
     ,p_hold_name        IN   VARCHAR2
      );

END XX_AP_INV_TERMS_PKG;
/

SHO ERR 