create or replace
PACKAGE XX_AP_INV_VALIDATE_PKG AS
-- +===============================================================================================================+
-- |                  Office Depot - Project Simplify                                                              |
-- |                                                                                                               |
-- +===============================================================================================================+
-- | Name :  XX_AP_INV_VALIDATE_PKG                                                                                |
-- | Description : TThis package performs the following for invoices in the invoices staging tables:               |
-- | 	 * Purge records from Invoice staging tables                                                               |
-- |     * checks for invoices that have already been imported into AP                                             |
-- | 	 * Check and Submit the Concurrent Request Emailer program to notify vendor of existing duplicate files    |
-- | 	 * Create vendor and bank records for Extensity invoices with no existing supplier records.                |
-- | 	 * Populates the terms date with the receipt date for TDM Expense PO invoices                              |
-- | 	 * Translates the Project Numbers and Task Numbers to Project ID and Task ID.                              |
-- | 	 * Builds invoice details from PO distribution line for the TDM PO invoices without any detail lines.      |
-- | 	 * Translates legacy GL account codes to Oracle GL account codes                                           |
-- | 	 * Import records from Invoice staging tablesto AP interface tables                                        |
--       * Translates Project Numbers, Task Numbers and Expenditure Org Name to Project ID,                        |
-- | 	   Task ID, Expenditure Org ID, Terms and Tax Codes for each invoice lines in                              |
-- |                                                                                                               |
-- |Change Record:                                                                                                 |
-- |===============                                                                                                |
-- |Version   Date              Author              Remarks                                                        |
-- |======   ==========     =============        =======================                                           |
-- |1.0       26-MAY-2007   Stedfield Thomas        Initial version                                                |
-- |1.1       09-OCT-2007   Chiatanya Nath.G       Commented procedure for the Defect ID 1936                      |
-- |1.2       15-OCT-2007   Sandeep Pandhare       Added procedures for Defect 2326, 2103                          |
-- |1.3       18-DEC-2008   Joe Klein              Defect 12231 - Added p_source to proc XX_AP_PROCESS_REASON_CD   |
-- |1.4       30-MAR-2017   Havish Kasina          Added procedures for the AP Trade Match                         |
-- |===============================================================================================================+


   --------------------------------------------
-- Translate Project Number to Project ID --
--------------------------------------------

 FUNCTION f_project_inbound (v_project_num_in IN VARCHAR2 DEFAULT NULL)
 RETURN VARCHAR2;

   --------------------------------------------------------------------------
-- Use  the combined Task Number and Project Number to derive the Task ID --
--------------------------------------------------------------------------

 FUNCTION f_task_inbound (v_task_num_in IN VARCHAR2 DEFAULT NULL,
                          v_project_num_in IN VARCHAR2 DEFAULT NULL)
 RETURN VARCHAR2;

   -----------------------------------------------------------
-- Translate Expenditure Org Name to Expenditure Org ID --
-----------------------------------------------------------

 FUNCTION f_exp_org_name_inbound (v_exp_org_name_in IN VARCHAR2 DEFAULT NULL)
 RETURN VARCHAR2;

--------------------------------------------------------------------------
-- Translate GL Account segment to populate the Expenditure Type column --
--------------------------------------------------------------------------

 FUNCTION f_exp_type_inbound (v_gl_account_in IN VARCHAR2 DEFAULT NULL)
 RETURN VARCHAR2;

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

-- PROCEDURE XX_AP_CREATE_PO_INV_LINES (p_group_id IN VARCHAR2);   Changed as per the Defect ID 1936


         ----------------------------
          --  Purge invoice records --
          ----------------------------

PROCEDURE xx_ap_validate_inv_interface (errbuff    OUT varchar2,
                                        retcode    OUT varchar2,
                                        p_source   IN varchar2,
                                        p_group_id IN varchar2);
          -------------------------------------------------
          --  Update the source in the Invoice staging tables
          -------------------------------------------------

PROCEDURE xx_ap_update_source         (errbuff    OUT varchar2,
                                        retcode    OUT varchar2);

           -------------------------------------------------
           --  Purge records from Invoice staging tables  --
           -------------------------------------------------

PROCEDURE xx_ap_invoices_purge         (errbuff    OUT varchar2,
                                        retcode    OUT varchar2,
                                        p_source   IN varchar2,
                                        p_group_id IN varchar2);

         -----------------------------------------------------------------
           --  Processes invoices that have already been imported into AP --
          -----------------------------------------------------------------

PROCEDURE xx_ap_duplicate_invoices     (errbuff    OUT varchar2,
                                        retcode    OUT varchar2,
                                        p_source   IN varchar2,
                                        p_group_id IN varchar2);

         -----------------------------------------------------------------
          --  Update Control Totals for Extensity/RETAIL/EDI into BATCH table Defect 2103--
          -----------------------------------------------------------------

PROCEDURE xx_ap_update_control_totals    ;
PROCEDURE xx_EDI_update_control_totals    ;


         -----------------------------------------------------------------
          --  Update Amount for DFi Calculation Defect 2326--
          -----------------------------------------------------------------
PROCEDURE xx_ap_process_reason_cd (
      errbuff      OUT      VARCHAR2,
      retcode      OUT      VARCHAR2,
      p_batch_id   IN       NUMBER,
      p_source     IN       VARCHAR2    --Defect 12231
   );

PROCEDURE XX_AP_UPDATE_INTEGRAL_SOURCE (
      errbuff      OUT      VARCHAR2,
      retcode      OUT      VARCHAR2
   );


------------------------------------------------------------------------------
-- Create new supplier and bank info for OD employees using the Employee ID --
------------------------------------------------------------------------------

        /*xx_ap_inv_validate_pkg.xx_po_employee_vendor_proc (x_employee_id       IN NUMBER,
                                                             x_vendor_id        OUT NUMBER,
                                                             x_vendor_site_id   OUT NUMBER);*/
															 
-- Added for the AP Trade match
-- +===================================================================+
-- | Name        : xx_insert_ap_tr_match_excepns                       |
-- |                                                                   |
-- | Description : This procedure is used to insert the exception      |
-- |               records into staging table XX_AP_TR_MATCH_EXCEPTIONS|                       
-- |                                                                   |
-- +===================================================================+
PROCEDURE XX_INSERT_AP_TR_MATCH_EXCEPNS(p_invoice_id            IN  number,
                                        p_invoice_num           IN  varchar2,
                                        p_vendor_id             IN  number ,
                                        p_vendor_site_id        IN  number ,
		                                p_invoice_line_id       IN  number ,
		                                p_invoice_line_num      IN  number ,
		                                p_po_num                IN  varchar2,
		                                p_po_header_id          IN  number,
		                                p_po_line_id            IN  number,
		                                p_po_line_num           IN  number,
		                                p_exception_code        IN  varchar2,
		                                p_exception_description IN  varchar2,
		                                p_process_flag          IN  varchar2
										);

END XX_AP_INV_VALIDATE_PKG;
/
show errors;
