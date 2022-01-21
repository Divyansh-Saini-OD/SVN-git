create or replace PACKAGE  XX_AP_INV_BUILD_PO_LINES_PKG
AS

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | Name :  XX_AP_INV_BUILD_PO_LINES_PKG                                     |
-- | Description :  This package is used to create invoices                   |
-- |                distribution lines for PO invoices.  The procedure        |
-- |                will use the PO number from the invoice header that       |
-- |                is created by an external interface.                      |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date              Author              Remarks                   |
-- |======   ==========     =============        =======================      |
-- |1.0       09-oct-2007     Chaitanya Nath.G   Initial version              |
-- |                                            Created as per the defect 1936|
-- |2.0       24-Mar-2017     Praveen vanga     Added code for Trade invoice  |
-- |                                             Changes                      | 
-- +==========================================================================+



-- +===================================================================+
-- | Name        : XX_AP_CREATE_PO_INV_LINES                           |
-- |                                                                   |
-- | Description : This procedure is used to create invoices           |
-- |               distribution lines for PO invoices.  The procedure  |
-- |               will use the PO number from the invoice header that |
-- |               is created by an external interface.                |
-- |                                                                   |
-- |               The invoice matching option will be set to purchase |
-- |               order.  Freight will be prorated over all lines of  |
-- |               ITEM type using standard functionality during import|
-- |               US Taxes will be prorated over the lines that have  |
-- |               the same tax code on the PO.  PO matching will occur|
-- |               during invoice import.                              |
-- |                                                                   |
-- | Parameters  : p_group_id                                          |
-- |                                                                   |
-- | Returns     :                                                     |
-- +===================================================================+
   PROCEDURE XX_AP_CREATE_PO_INV_LINES (p_group_id IN VARCHAR2);
   
-- +===================================================================+
-- | Name        : XX_AP_RESET_INVOICE_STG                             |
-- |                                                                   |
-- | Description : This procedure is used to reset the process of the  |
-- |               staging table for failed invoices. The failure would|
-- |               be due to invalid PO.                               |
-- |                                                                   |
-- |               This procedure will also delete the invoices in the |
-- |               invoice header and lines interface for failed       |
-- |               invoices.                                            |
-- | Parameters  : p_group_id                                          |
-- | Parameters  : p_invoice_id                                        |
-- |                                                                   |
-- | Returns     :                                                     |
-- +===================================================================+
   PROCEDURE XX_AP_RESET_INVOICE_STG (p_group_id IN VARCHAR2,
                                      p_invoice_id IN NUMBER);

-- +===================================================================+
-- | Name        : XX_AP_CREATE_TRDPO_INV_LINES                        |
-- |                                                                   |
-- | Description : This procedure is used to insert the records into   |
-- |               ap invoice interface table.                         |
-- |                                                                   |
-- | Parameters  : p_group_id                                          |
-- |                                                                   |
-- | Returns     :                                                     |
-- +===================================================================+

   PROCEDURE XX_AP_CREATE_TRDPO_INV_LINES(p_group_id IN VARCHAR2);
   
   
END XX_AP_INV_BUILD_PO_LINES_PKG;
/
SHOW ERRORS;