CREATE OR REPLACE PACKAGE AP_ETAX_SERVICES_PKG AS
/* $Header: apetxsrs.pls 120.10.12010000.11 2012/12/18 11:15:27 nbshaik ship $ */

  -- Define structure to pass tax hold codes to release
  TYPE Rel_Hold_Codes_Type IS TABLE OF ap_holds_all.hold_lookup_code%TYPE INDEX BY BINARY_INTEGER;

   --bug10621602  starts
   -- Created an record structure for capturing the retainage information
   -- This information will be used in calculating the variances such as TIPV , TV , TERV

  TYPE Inv_ret_dists IS RECORD(

  amount                          ap_invoice_distributions_all.amount%TYPE,
  retainage_rate                  po_lines_all.retainage_rate%TYPE,
  retained_amount                 ap_invoice_distributions_all.amount%TYPE,
  retained_invoice_dist_id        ap_invoice_distributions_all.retained_invoice_dist_id%TYPE,
  related_retainage_dist_id       ap_invoice_distributions_all.related_retainage_dist_id%TYPE,
  quantity_invoiced               ap_invoice_distributions_all.quantity_invoiced%TYPE,
  unit_price                      ap_invoice_distributions_all.unit_price%TYPE
  );

   TYPE ret_dists_tab IS TABLE OF Inv_ret_dists INDEX BY VARCHAR2(200);  --bug14155552, changed to INDEX BY VARCHAR2 from PLS_INTEGER

   ret_dists   ret_dists_tab;

  --bug 10621602 ended

/*=============================================================================
 |  FUNCTION - Calculate()
 |
 |  DESCRIPTION
 |      Public function that will call the calculate_tax service for
 |      calculation and recalculation.
 |      This API assumes the calling code controls the commit cycle.
 |      This function returns TRUE if the call to the service is successful.
 |      Otherwise, FALSE.
 |
 |  PARAMETERS
 |      P_Invoice_Id - invoice id
 |      P_Line_Number - This parameter will be used to allow this API to
 |                      calculate tax only for the line specified in this
 |                      parameter.  Additionally, this parameter will be used
 |                      to determine the PREPAY line created for prepayment
 |                      unapplications.
 |      P_Calling_Mode - calling mode.  Identifies which service to call
 |      P_All_Error_Messages - Should API return 1 error message or allow
 |                             calling point to get them from message stack
 |      P_error_code - Error code to be returned
 |      P_calling_sequence -  Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    07-OCT-2003   SYIDNER        Created
 |
 *============================================================================*/
  FUNCTION Calculate(
             P_Invoice_id              IN NUMBER,
             P_Line_Number             IN NUMBER,
             P_Calling_Mode            IN VARCHAR2,
             P_All_Error_Messages      IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN;

/*=============================================================================
 |  FUNCTION - Calculate_Import()
 |
 |  DESCRIPTION
 |      Public function that will call the calculate_tax service for
 |      calculation and recalculation from the import program.
 |      This new calling mode is required to avoid the repopulation of the eTax
 |      global temp tables
 |      This API assumes the calling code controls the commit cycle.
 |      This function returns TRUE if the call to the service is successful.
 |      Otherwise, FALSE.
 |
 |  PARAMETERS
 |      P_Invoice_Id - invoice id
 |      P_Calling_Mode - calling mode.  Identifies which service to call
 |      P_Interface_Invoice_Id - Interface invoice id
 |      P_All_Error_Messages - Should API return 1 error message or allow
 |                             calling point to get them from message stack
 |      P_error_code - Error code to be returned
 |      P_calling_sequence -  Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    14-JAN-2004   SYIDNER        Created
 |
 *============================================================================*/
  FUNCTION Calculate_Import(
             P_Invoice_Id              IN NUMBER,
             P_Calling_Mode            IN VARCHAR2,
             P_Interface_Invoice_Id    IN NUMBER,
             P_All_Error_Messages      IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN;

/*=============================================================================
 |  FUNCTION - Distribute()
 |
 |  DESCRIPTION
 |      Public function that will call the determine_recovery service for
 |      distribution and redistribution.
 |      This API assumes the calling code controls the commit cycle.
 |      This function returns TRUE if the call to the service is successful.
 |      Otherwise, FALSE.
 |
 |  PARAMETERS
 |      P_Invoice_Id - invoice id
 |      P_Line_Number - This parameter will be used to allow this API to
 |                      distribute tax only for the line specified in this
 |                      parameter.
 |      P_Calling_Mode - calling mode.  Identifies which service to call
 |      P_All_Error_Messages - Should API return 1 error message or allow
 |                             calling point to get them from message stack
 |      P_error_code - Error code to be returned
 |      P_calling_sequence -  Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    07-OCT-2003   SYIDNER        Created
 |
 *============================================================================*/
  FUNCTION Distribute(
             P_Invoice_id              IN NUMBER,
             P_Line_Number             IN NUMBER,
             P_Calling_Mode            IN VARCHAR2,
             P_All_Error_Messages      IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN;

/*=============================================================================
 |  FUNCTION - Distribute_Import()
 |
 |  DESCRIPTION
 |      Public function that will call the determine_recovery service for
 |      distribution during the import.  This API will called only in the case
 |      TAX-ONLY lines exist in the invoice.
 |      This API assumes the calling code controls the commit cycle.
 |      This function returns TRUE if the call to the service is successful.
 |      Otherwise, FALSE.
 |
 |  PARAMETERS
 |      P_Invoice_Id - invoice id
 |      P_Calling_Mode - calling mode.  Identifies which service to call
 |      P_All_Error_Messages - Should API return 1 error message or allow
 |                             calling point to get them from message stack
 |      P_error_code - Error code to be returned
 |      P_calling_sequence -  Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    20-JAN-2004   SYIDNER        Created
 |
 *============================================================================*/
  FUNCTION Distribute_Import(
             P_Invoice_id              IN NUMBER,
             P_Calling_Mode            IN VARCHAR2,
             P_All_Error_Messages      IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN;

/*=============================================================================
 |  FUNCTION - Import_Interface()
 |
 |  DESCRIPTION
 |      Public function that will call the import_document_with_tax service for
 |      distribution and redistribution.
 |      This API assumes the calling code controls the commit cycle.
 |      This function returns TRUE if the call to the service is successful.
 |      Otherwise, FALSE.
 |
 |  PARAMETERS
 |      P_Invoice_Id - invoice id
 |      P_Calling_Mode - calling mode.  Identifies which service to call
 |      P_Interface_Invoice_Id - Interface invoice id
 |      P_All_Error_Messages - Should API return 1 error message or allow
 |                             calling point to get them from message stack
 |      P_error_code - Error code to be returned
 |      P_calling_sequence -  Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    07-OCT-2003   SYIDNER        Created
 |
 *============================================================================*/
  FUNCTION Import_Interface(
             P_Invoice_id              IN NUMBER,
             P_Calling_Mode            IN VARCHAR2,
             P_Interface_Invoice_Id    IN NUMBER,
             P_All_Error_Messages      IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN;

/*=============================================================================
 |  FUNCTION - Reverse_Invoice()
 |
 |  DESCRIPTION
 |      Public function that will call the reverse_document_distribution
 |      service for quick credit (full reversal.)
 |      This API assumes the calling code controls the commit cycle.
 |      This function returns TRUE if the call to the service is successful.
 |      Otherwise, FALSE.
 |
 |  PARAMETERS
 |      P_Invoice_Id - invoice id
 |      P_Calling_Mode - calling mode.  Identifies which service to call
 |      P_All_Error_Messages - Should API return 1 error message or allow
 |                             calling point to get them from message stack
 |      P_error_code - Error code to be returned
 |      P_calling_sequence -  Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    07-OCT-2003   SYIDNER        Created
 |
 *============================================================================*/
  FUNCTION Reverse_Invoice(
             P_Invoice_id              IN NUMBER,
             P_Calling_Mode            IN VARCHAR2,
             P_All_Error_Messages      IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN;

/*=============================================================================
 |  FUNCTION - Override_Tax()
 |
 |  DESCRIPTION
 |      Public function that will call the override_tax service.
 |      This API assumes the calling code controls the commit cycle.
 |      This function returns TRUE if the call to the service is successful.
 |      Otherwise, FALSE.
 |
 |  PARAMETERS
 |      P_Invoice_Id         - invoice id
 |      P_Calling_Mode       - calling mode.  Identifies which service to call
 |      P_Override_Status    - override_status parameter returned by the eTax
 |                             UI (Tax lines and summary lines window).
 |      P_Event_id	     - Indicates a specific instance of the override event.
 |                             Tax line windows will return an event_id when there
 |                             are any user overrides.
 |      P_All_Error_Messages - Should API return 1 error message or allow
 |                             calling point to get them from message stack
 |      P_error_code         - Error code to be returned
 |      P_calling_sequence   -  Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    07-OCT-2003   SYIDNER        Created
 |
 *============================================================================*/

  FUNCTION Override_Tax(
             P_Invoice_id              IN NUMBER,
             P_Calling_Mode            IN VARCHAR2,
             P_Override_Status         IN VARCHAR2,
             P_Event_Id		       IN NUMBER,
             P_All_Error_Messages      IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN;

/*=============================================================================
 |  FUNCTION - Override_Recovery()
 |
 |  DESCRIPTION
 |      Public function that will call the override_recovery service.
 |      This API assumes the calling code controls the commit cycle.
 |      This function returns TRUE if the call to the service is successful.
 |      Otherwise, FALSE.
 |
 |  PARAMETERS
 |      P_Invoice_Id - invoice id
 |      P_Calling_Mode - calling mode.  Identifies which service to call
 |      P_All_Error_Messages - Should API return 1 error message or allow
 |                             calling point to get them from message stack
 |      P_error_code - Error code to be returned
 |      P_calling_sequence -  Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    07-OCT-2003   SYIDNER        Created
 |
 *============================================================================*/
  FUNCTION Override_Recovery(
             P_Invoice_id              IN NUMBER,
             P_Calling_Mode            IN VARCHAR2,
             P_All_Error_Messages      IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN;

--Bug7592845
/*=============================================================================
 |  FUNCTION - Freeze_itm_Distributions()
 |
 |  DESCRIPTION
 |      Public function that will call the freeze_tax_dists_for_items service.
 |      This API assumes the calling code controls the commit cycle.
 |      This function returns TRUE if the call to the service is successful.
 |      Otherwise, FALSE.
 |
 |  PARAMETERS
 |      P_Invoice_header_rec - invoice record
 |      P_Calling_Mode - calling mode.  Identifies which service to call
 |      P_Event_Class_Code - Event class code for the invoice type
 |      P_All_Error_Messages - Should API return 1 error message or allow
 |                             calling point to get them from message stack
 |      P_error_code - Error code to be returned
 |      P_calling_sequence -  Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE                  Author                             Action
 |    11-DEC-2008   SCHITLAP/HCHAUDHA        Created
 |
 *============================================================================*/
  FUNCTION Freeze_itm_Distributions(
             P_Invoice_Header_Rec      IN ap_invoices_all%ROWTYPE,
             P_Calling_Mode            IN VARCHAR2,
             P_Event_Class_Code        IN VARCHAR2,
             P_All_Error_Messages      IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN;
--Bug7592845

/*=============================================================================
 |  FUNCTION - Freeze_Distributions()
 |
 |  DESCRIPTION
 |      Public function that will call the freeze_tax_distributions service.
 |      This API assumes the calling code controls the commit cycle.
 |      This function returns TRUE if the call to the service is successful.
 |      Otherwise, FALSE.
 |
 |  PARAMETERS
 |      P_Invoice_header_rec - invoice record
 |      P_Calling_Mode - calling mode.  Identifies which service to call
 |      P_Event_Class_Code - Event class code for the invoice type
 |      P_All_Error_Messages - Should API return 1 error message or allow
 |                             calling point to get them from message stack
 |      P_error_code - Error code to be returned
 |      P_calling_sequence -  Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    07-OCT-2003   SYIDNER        Created
 |
 *============================================================================*/
  /*FUNCTION Freeze_Distributions(
             P_Invoice_Header_Rec      IN ap_invoices_all%ROWTYPE,
             P_Calling_Mode            IN VARCHAR2,
             P_Event_Class_Code        IN VARCHAR2,
             P_All_Error_Messages      IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN;*/
--Bug7592845

/*=============================================================================
 |  FUNCTION - Global_Document_Update()
 |
 |  DESCRIPTION
 |      Public function that will call the global_document_update service to
 |      inform eTax of a cancellation of an invoice, the freeze after the
 |      invoice is validated (meaning is ready to reporting), and the unfreeze
 |      of an invoice because it has to be modified after it was validated.
 |      This API assumes the calling code controls the commit cycle.
 |      This function returns TRUE if the call to the service is successful.
 |      Otherwise, FALSE.
 |
 |  PARAMETERS
 |      P_Invoice_Id - invoice id
 |      P_Calling_Mode - calling mode.  Identifies which service to call
 |      P_All_Error_Messages - Should API return 1 error message or allow
 |                             calling point to get them from message stack
 |      P_error_code - Error code to be returned
 |      P_calling_sequence -  Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    07-OCT-2003   SYIDNER        Created
 |                                 Added p_line_number so that the same
 |                                 routine can be used while discarding
 |                                 an invoice line.
 *============================================================================*/
  FUNCTION Global_Document_Update(
             P_Invoice_id              IN NUMBER,
             P_Line_Number	       IN NUMBER DEFAULT NULL,
             P_Calling_Mode            IN VARCHAR2,
             P_All_Error_Messages      IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN;

/*=============================================================================
 |  FUNCTION - Release_Tax_Holds()
 |
 |  DESCRIPTION
 |      Public function that will call the global_document_update service to
 |      inform eTax the release of tax holds by the user.
 |      This function returns TRUE if the call to the service is successful.
 |      Otherwise, FALSE.
 |
 |  PARAMETERS
 |      P_Invoice_Id - invoice id
 |      P_Calling_Mode - calling mode.  Identifies which service to call
 |      P_Tax_Hold_Code - Tax hold codes released in AP
 |      P_All_Error_Messages - Should API return 1 error message or allow
 |                             calling point to get them from message stack
 |      P_error_code - Error code to be returned
 |      P_calling_sequence -  Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    05-NOV-2003   SYIDNER        Created
 |
 *============================================================================*/
  FUNCTION Release_Tax_Holds(
             P_Invoice_id              IN NUMBER,
             P_Calling_Mode            IN VARCHAR2,
             P_Tax_Hold_Code           IN Rel_Hold_Codes_Type,
             P_All_Error_Messages      IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN;

/*=============================================================================
 |  FUNCTION - Mark_Tax_Lines_Deleted()
 |
 |  DESCRIPTION
 |      Public function that will call the mark_tax_lines_deleted service.
 |      This API assumes the calling code controls the commit cycle.
 |      This function returns TRUE if the call to the service is successful.
 |      Otherwise, FALSE.
 |
 |  PARAMETERS
 |      P_Invoice_Id - invoice id
 |      P_Calling_Mode - calling mode.  Identifies which service to call
 |      P_Line_Number_To_Delete - Tax Line to delete
 |      P_All_Error_Messages - Should API return 1 error message or allow
 |                             calling point to get them from message stack
 |      P_error_code - Error code to be returned
 |      P_calling_sequence -  Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    07-OCT-2003   SYIDNER        Created
 |    05-NOV-2003   SYIDNER        Included new P_Line_Number_To_Delete
 |                                 parameter
 |
 *============================================================================*/
  FUNCTION Mark_Tax_Lines_Deleted(
             P_Invoice_id              IN NUMBER,
             P_Calling_Mode            IN VARCHAR2,
             P_Line_Number_To_Delete   IN NUMBER,
             P_All_Error_Messages      IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN;

--bug 9343533
/*=============================================================================
 |  FUNCTION - Mark_Tax_Lines_Deleted()
 |
 |  DESCRIPTION
 |      Public function that will call the mark_tax_lines_deleted service.
 |      This API assumes the calling code controls the commit cycle.
 |      This function returns TRUE/FALSE as varchar2 for bug 9343533
 |
 |  PARAMETERS
 |      P_Invoice_Id - invoice id
 |      P_Calling_Mode - calling mode.  Identifies which service to call
 |      P_Line_Number_To_Delete - Tax Line to delete
 |      P_All_Error_Messages - Should API return 1 error message or allow
 |                             calling point to get them from message stack
 |      P_error_code - Error code to be returned
 |      P_calling_sequence -  Calling sequence
 |      P_dummy - dummy variable to differentiate from existing
 |                Mark_Tax_Lines_Deleted API
 |
 |  MODIFICATION HISTORY
 |    DATE              Author                  Action
 |    25-MAR-2010   DCSHANMU        Created
 |
 *============================================================================*/
  FUNCTION Mark_Tax_Lines_Deleted(
             P_Invoice_id              IN NUMBER,
             P_Calling_Mode            IN VARCHAR2,
             P_Line_Number_To_Delete   IN NUMBER,
             P_All_Error_Messages      IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2,
             p_dummy                   IN VARCHAR2) RETURN VARCHAR2;

/*=============================================================================
 |  FUNCTION - Validate_Invoice()
 |
 |  DESCRIPTION
 |      Public function that will call the validate_document_for_tax service.
 |      This API assumes the calling code controls the commit cycle.
 |      This function returns TRUE if the call to the service is successful.
 |      Otherwise, FALSE.
 |
 |  PARAMETERS
 |      P_Invoice_Id - invoice id
 |      P_Calling_Mode - calling mode.  Identifies which service to call
 |      P_All_Error_Messages - Should API return 1 error message or allow
 |                             calling point to get them from message stack
 |      P_error_code - Error code to be returned
 |      P_calling_sequence -  Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    07-OCT-2003   SYIDNER        Created
 |
 *============================================================================*/
  FUNCTION Validate_Invoice(
             P_Invoice_id              IN NUMBER,
             P_Calling_Mode            IN VARCHAR2,
             P_All_Error_Messages      IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN;

/*=============================================================================
 |  FUNCTION - Validate_Default_Import()
 |
 |  DESCRIPTION
 |      Public function that will call the validate_and_default_tax_attr service.
 |      This API assumes the calling code controls the commit cycle.
 |      This function returns TRUE if the call to the service is successful.
 |      Otherwise, FALSE.
 |      This API will validate the taxable and tax lines to be imported regarding
 |      tax.  The lines will be passed to this API using the pl/sql structures
 |      defined in the import process.
 |      The service validate_and_default_tax_attr will default any possible tax
 |      value, and this API will modify the pl/sql structures with the defaulted
 |      tax info.
 |
 |  PARAMETERS
 |      p_invoice_rec - record defined in the import program for the invoice header
 |      p_invoice_lines_tab - array with the taxable and tax lines
 |      P_Calling_Mode - calling mode.  Identifies which service to call
 |      P_All_Error_Messages - Should API return 1 error message or allow
 |                             calling point to get them from message stack
 |      p_invoice_status - returns N if the invoice should be rejected.
 |      P_error_code - Error code to be returned
 |      P_calling_sequence -  Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    20-JAN-2004   SYIDNER        Created
 |
 *============================================================================*/
  FUNCTION Validate_Default_Import(
     /*        P_Invoice_Rec             IN OUT NOCOPY
               AP_IMPORT_INVOICES_PKG.r_invoice_info_rec,
             p_invoice_lines_tab       IN OUT NOCOPY
               AP_IMPORT_INVOICES_PKG.t_lines_table, */ --bug 15862708
             P_Invoice_Rec_table             IN OUT NOCOPY
               AP_IMPORT_INVOICES_PKG.t_invoice_table,
             p_invoice_lines_table       IN OUT NOCOPY
               AP_IMPORT_INVOICES_PKG.t_lines_table,
             P_Calling_Mode            IN VARCHAR2,
             P_All_Error_Messages      IN VARCHAR2,
             p_invoice_status          OUT NOCOPY VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN;

/*=============================================================================
 |  FUNCTION - Populate_Headers_GT()
 |
 |  DESCRIPTION
 |      This function will get additional information required to populate the
 |      ZX_TRANSACTION_HEADERS_GT
 |      This function returns TRUE if the insert to the temp table goes
 |      through successfully.  Otherwise, FALSE.
 |
 |  PARAMETERS
 |      P_Invoice_Header_Rec - record with invoice header information
 |      P_Calling_Mode - calling mode. it is used to
 |      P_eTax_Already_called_flag - Flag to know if this is the first time tax
 |                                   has been called
 |      P_Event_Class_Code - Evnet class code
 |      P_Event_Type_Code - Event Class Code
 |      P_error_code - Error code to be returned
 |      P_calling_sequence -  Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    07-OCT-2003   SYIDNER        Created
 |
 *============================================================================*/
  FUNCTION Populate_Headers_GT(
             P_Invoice_Header_Rec        IN ap_invoices_all%ROWTYPE,
             P_Calling_Mode              IN VARCHAR2,
             P_eTax_Already_called_flag  IN VARCHAR2,
             P_Event_Class_Code          OUT NOCOPY VARCHAR2,
             P_Event_Type_Code           OUT NOCOPY VARCHAR2,
             P_Error_Code                OUT NOCOPY VARCHAR2,
             P_Calling_Sequence          IN VARCHAR2) RETURN BOOLEAN;

/*=============================================================================
 |  FUNCTION - Populate_Header_Import_GT()
 |
 |  DESCRIPTION
 |    This function will get additional information required to populate the
 |    ZX_TRANSACTION_HEADERS_GT from the import array structure.
 |    This function returns TRUE if the insert to the temp table goes
 |    through successfully.  Otherwise, FALSE.
 |
 |  PARAMETERS
 |    P_Invoice_Header_Rec - record with invoice header information
 |    P_Calling_Mode - calling mode. it is used to
 |    P_Event_Class_Code - Event class code
 |    P_Event_Type_Code - Event type code
 |    P_error_code - Error code to be returned
 |    P_calling_sequence -  Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    20-JAN-2004   SYIDNER        Created
 |
*============================================================================*/
  FUNCTION Populate_Header_Import_GT(
             P_Invoice_Header_Rec        IN AP_IMPORT_INVOICES_PKG.r_invoice_info_rec,
             P_Calling_Mode              IN VARCHAR2,
             P_Event_Class_Code          OUT NOCOPY VARCHAR2,
             P_Event_Type_Code           OUT NOCOPY VARCHAR2,
             P_Error_Code                OUT NOCOPY VARCHAR2,
             P_Calling_Sequence          IN VARCHAR2) RETURN BOOLEAN;

/*=============================================================================
 |  FUNCTION - Populate_Lines_GT()
 |
 |  DESCRIPTION
 |      This function will get additional information required to populate the
 |      ZX_TRANSACTION_LINES_GT
 |      This function returns TRUE if the population of the temp table goes
 |      through successfully.  Otherwise, FALSE.
 |
 |  PARAMETERS
 |      P_Invoice_Header_Rec - record with invoice header information
 |      P_Calling_Mode - calling mode. it is used to
 |      P_Event_Class_Code - Event class code for document
 |      P_Line_Number - prepay line number to be unapplied
 |      P_error_code - Error code to be returned
 |      P_calling_sequence -  Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    09-OCT-2003   SYIDNER        Created
 |
 *============================================================================*/
  FUNCTION Populate_Lines_GT(
             P_Invoice_Header_Rec      IN ap_invoices_all%ROWTYPE,
             P_Calling_Mode            IN VARCHAR2,
             P_Event_Class_Code        IN VARCHAR2,
             P_Line_Number             IN NUMBER DEFAULT NULL,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN;

/*=============================================================================
 |  FUNCTION - Populate_Lines_Import_GT()
 |
 |  DESCRIPTION
 |      This function will get additional information required to populate the
 |      ZX_TRANSACTION_LINES_GT
 |      This function returns TRUE if the population of the temp table goes
 |      through successfully.  Otherwise, FALSE.
 |
 |  PARAMETERS
 |      P_Invoice_Header_Rec - record with invoice header information
 |      P_Invoice_Lines_Tab - List of trx and tax lines for the invoice
 |        existing in the ap_invoice_lines_interface table
 |      P_Calling_Mode - calling mode. it is used to
 |      P_Event_Class_Code - Event class code for document
 |      P_error_code - Error code to be returned
 |      P_calling_sequence -  Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    20-JAN-2004   SYIDNER        Created
 |
 *============================================================================*/
  FUNCTION Populate_Lines_Import_GT(
             P_Invoice_Header_Rec      IN AP_IMPORT_INVOICES_PKG.r_invoice_info_rec,
             P_Inv_Line_List           IN AP_IMPORT_INVOICES_PKG.t_lines_table,
             P_Calling_Mode            IN VARCHAR2,
             P_Event_Class_Code        IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN;

/*=============================================================================
 |  FUNCTION - Populate_Tax_Lines_GT()
 |
 |  DESCRIPTION
 |      This function will get additional information required to populate the
 |      ZX_TRANSACTION_LINES_GT, and  ZX_IMPORT_TAX_LINES_GT.
 |      There is no need to populate ZX_TRX_TAX_LINK_GT since any tax line
 |      manually created is assume to be allocated to all the ITEM lines in the
 |      invoice.
 |      This function returns TRUE if the population of the temp table goes
 |      through successfully.  Otherwise, FALSE.
 |
 |  PARAMETERS
 |      P_Invoice_Header_Rec - record with invoice header information
 |      P_Calling_Mode - calling mode. it is used to
 |      P_Event_Class_Code - Event class code for document
 |      P_Tax_only_Flag - Indicates if the invoice is tax only
 |      P_Inv_Rcv_Matched - determine if the invoice has any line matched to a
 |                          receipt
 |      P_error_code - Error code to be returned
 |      P_calling_sequence -  Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    06-FEB-2004   SYIDNER        Created
 |
 *============================================================================*/
  FUNCTION Populate_Tax_Lines_GT(
             P_Invoice_Header_Rec      IN ap_invoices_all%ROWTYPE,
             P_Calling_Mode            IN VARCHAR2,
             P_Event_Class_Code        IN VARCHAR2,
             P_Tax_Only_Flag           IN VARCHAR2,
             P_Inv_Rcv_Matched         IN OUT NOCOPY VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN;

/*=============================================================================
 |  FUNCTION - Populate_Distributions_GT()
 |
 |  DESCRIPTION
 |      This function will get additional information required to populate the
 |      ZX_DISTRIBUTION_LINES_GT
 |      This function returns TRUE if the population of the temp table goes
 |      through successfully.  Otherwise, FALSE.
 |
 |  PARAMETERS
 |      P_Invoice_Header_Rec - record with invoice header information
 |      P_Calling_Mode - calling mode. it is used to
 |      P_Event_Class_Code - Event class code for document
 |      P_Event_Type_Code - Evnet type code
 |      P_error_code - Error code to be returned
 |      P_calling_sequence -  Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    20-OCT-2003   SYIDNER        Created
 |
 *============================================================================*/
  FUNCTION Populate_Distributions_GT(
             P_Invoice_Header_Rec      IN ap_invoices_all%ROWTYPE,
             P_Calling_Mode            IN VARCHAR2,
             P_Event_Class_Code        IN VARCHAR2,
             P_Event_Type_Code         IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN;


/*=============================================================================
 |  FUNCTION - Update_AP()
 |
 |  DESCRIPTION
 |      This function will handle the return of values from the eTax repository
 |      This will be called from all the functions that call the etax services
 |      in the case the call is successfull.
 |
 |  PARAMETERS
 |      P_Invoice_header_rec - Invoice header info
 |      P_Calling_Mode - calling mode.
 |      P_All_Error_Messages - Should API return 1 error message or allow
 |                             calling point to get them from message stack
 |      P_error_code - Error code to be returned
 |      P_calling_sequence -  Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    20-OCT-2003   SYIDNER        Created
 |
 *============================================================================*/
  FUNCTION Update_AP(
             P_Invoice_header_rec      IN ap_invoices_all%ROWTYPE,
             P_Calling_Mode            IN VARCHAR2,
             P_All_Error_Messages      IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN;

/*=============================================================================
 |  FUNCTION - Calculate_Quote ()
 |
 |  DESCRIPTION
 |      This function will return the tax amount and indicate if it is inclusive.
 |      This will be called from the recurring invoices form. This is a special
 |      case, as the invoices for which the tax is to be calculated are not yet
 |      saved to the database and eBTax global temporary tables are populated
 |      based on the parameters. A psuedo-line is inserted into the GTT and
 |      removed after the tax amount is calculated.
 |
 |  PARAMETERS
 |      P_Invoice_header_rec 	- Invoice header info
 |      P_Invoice_Lines_Rec	- Invoice lines info
 |      P_Calling_Mode 		- Calling mode. (CALCULATE_QUOTE)
 |      P_All_Error_Messages 	- Should API return 1 error message or allow
 |                                calling point to get them from message stack
 |      P_error_code 		- Error code to be returned
 |      P_calling_sequence 	- Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    13-AUG-2003   Sanjay         Created
 *============================================================================*/
  FUNCTION CALCULATE_QUOTE(
             P_Invoice_Header_Rec      	IN  ap_invoices_all%ROWTYPE,
             P_Invoice_Lines_Rec	IN  ap_invoice_lines_all%ROWTYPE,
             P_Calling_Mode            	IN  VARCHAR2,
             P_Tax_Amount		OUT NOCOPY NUMBER,
	     P_Tax_Amt_Included		OUT NOCOPY VARCHAR2,
             P_Error_Code              	OUT NOCOPY VARCHAR2,
             P_Calling_Sequence         IN  VARCHAR2) RETURN BOOLEAN;

 -- Bug 5110693: Added the new function to generate tax for recouped prepay distributions.

/*=============================================================================
 |  FUNCTION - Generate_Recouped_Tax ()
 |
 |  DESCRIPTION
 |      This function will generate tax distribitons for recouped prepay
 |      distributions.
 |
 *============================================================================*/
  FUNCTION Generate_Recouped_Tax(
             P_Invoice_id              IN NUMBER,
	     P_Invoice_Line_Number     IN NUMBER,
             P_Calling_Mode            IN VARCHAR2,
             P_All_Error_Messages      IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN;

 -- Bug 5185023: Added the new function to delete preview tax distributions

/*=============================================================================
 |  FUNCTION - Delete_Tax_Distributions ()
 |
 |  DESCRIPTION
 |      This function will delete tax distributions in the etax schema that
 |      were generated for preview item distributions. This is called in the
 |      invoice workbench prior to deleting preview distributions.
 |
 *============================================================================*/

  FUNCTION Delete_Tax_Distributions
                        (p_invoice_id         IN  ap_invoice_distributions_all.invoice_id%Type,
                         p_calling_mode       IN  VARCHAR2,
                         p_all_error_messages IN  VARCHAR2,
                         p_error_code         OUT NOCOPY VARCHAR2,
                         p_calling_sequence   IN  VARCHAR2) RETURN BOOLEAN;

/*=============================================================================
 |  FUNCTION - Calculate_Tax_Receipt_Match ()
 |
 |  DESCRIPTION
 |      This function will synch tax repository for tax matched to receipts.
 |
 *============================================================================*/

  FUNCTION Calculate_Tax_Receipt_Match(
			P_Invoice_Id              IN  NUMBER,
			P_Calling_Mode            IN  VARCHAR2,
			P_All_Error_Messages      IN  VARCHAR2,
			P_Error_Code              OUT NOCOPY VARCHAR2,
			P_Calling_Sequence        IN  VARCHAR2) RETURN BOOLEAN;


/*=============================================================================
 |  FUNCTION - Bulk_Populate_Headers_GT ()
 |
 |  DESCRIPTION
 |      This function will populate the invoice headers to the tax staging table
 |      in bulk during invoice validation.
 |
 *============================================================================*/

  FUNCTION Bulk_Populate_Headers_GT
			(p_validation_request_id IN  NUMBER,
			 p_calling_mode		 IN  VARCHAR2,
	     	 p_error_code		 OUT NOCOPY VARCHAR2) RETURN BOOLEAN;

  ------
  TYPE org_rec Is RECORD(
         bill_to_location_id       hr_all_organization_units.location_id%type);

  TYPE org_tab IS TABLE OF org_rec
  INDEX BY PLS_INTEGER;

  g_org_attributes      org_tab;
  ------

  TYPE supplier_site_rec Is RECORD(
         location_id     ap_supplier_sites_all.location_id%type,
         fob_lookup_code ap_supplier_sites_all.fob_lookup_code%type);

  TYPE supplier_site_tab IS TABLE OF supplier_site_rec
  INDEX BY PLS_INTEGER;

  g_site_attributes     supplier_site_tab;
  ------

  TYPE fsp_rec Is RECORD(
         inventory_organization_id financials_system_params_all.inventory_organization_id%type);

  TYPE fsp_tab IS TABLE OF fsp_rec
  INDEX BY PLS_INTEGER;

  g_fsp_attributes      fsp_tab;

  ------


  --Bugfix: 5565310
  PROCEDURE get_po_tax_attributes
                  (p_application_id               IN  NUMBER,
		           p_org_id                       IN  NUMBER,
		           p_entity_code                  IN  VARCHAR2,
		           p_event_class_code             IN  VARCHAR2,
		           p_trx_level_type               IN  VARCHAR2,
		           p_trx_id                       IN  NUMBER,
		           p_trx_line_id                  IN  NUMBER,
		           x_line_intended_use            OUT NOCOPY VARCHAR2,
		           x_product_type                 OUT NOCOPY VARCHAR2,
		           x_product_category             OUT NOCOPY VARCHAR2,
		           x_product_fisc_classification  OUT NOCOPY VARCHAR2,
		           x_user_defined_fisc_class      OUT NOCOPY VARCHAR2,
		           x_assessable_value             OUT NOCOPY NUMBER,
		           x_tax_classification_code      OUT NOCOPY VARCHAR2);

  --bug 8495005 fix starts
  PROCEDURE get_po_tax_attributes
                  (p_application_id               IN  NUMBER,
		           p_org_id                       IN  NUMBER,
		           p_entity_code                  IN  VARCHAR2,
		           p_event_class_code             IN  VARCHAR2,
		           p_trx_level_type               IN  VARCHAR2,
		           p_trx_id                       IN  NUMBER,
		           p_trx_line_id                  IN  NUMBER,
		           x_line_intended_use            OUT NOCOPY VARCHAR2,
		           x_product_type                 OUT NOCOPY VARCHAR2,
		           x_product_category             OUT NOCOPY VARCHAR2,
		           x_product_fisc_classification  OUT NOCOPY VARCHAR2,
		           x_user_defined_fisc_class      OUT NOCOPY VARCHAR2,
		           x_assessable_value             OUT NOCOPY NUMBER,
		           x_tax_classification_code      OUT NOCOPY VARCHAR2,
			       x_taxation_country		OUT NOCOPY VARCHAR2,
			       x_trx_biz_category		OUT NOCOPY VARCHAR2);
  --bug 8495005 fix ends

-- Bug 7570234 Start
  PROCEDURE synchronize_for_doc_seq
                	(p_invoice_id       		  IN NUMBER ,
	           	     p_calling_sequence 		  IN VARCHAR2 ,
		             x_return_status    		  OUT NOCOPY VARCHAR2);
-- Bug 7570234 End

   --Bug9819170

   PROCEDURE synchronize_tax_dff
             (p_invoice_id                 IN NUMBER ,
             p_invoice_dist_id            IN NUMBER   DEFAULT NULL,
             p_related_id                 IN NUMBER   DEFAULT NULL,
             p_detail_tax_dist_id         IN NUMBER   DEFAULT NULL,
             p_line_type_lookup_code      IN VARCHAR2 DEFAULT NULL,
             p_invoice_line_number        IN NUMBER,
             p_distribution_line_number   IN NUMBER,
             P_ATTRIBUTE1                 IN VARCHAR2,
             P_ATTRIBUTE2                 IN VARCHAR2,
             P_ATTRIBUTE3                 IN VARCHAR2,
             P_ATTRIBUTE4                 IN VARCHAR2,
             P_ATTRIBUTE5                 IN VARCHAR2,
             P_ATTRIBUTE6                 IN VARCHAR2,
             P_ATTRIBUTE7                 IN VARCHAR2,
             P_ATTRIBUTE8                 IN VARCHAR2,
             P_ATTRIBUTE9                 IN VARCHAR2,
             P_ATTRIBUTE10                IN VARCHAR2,
             P_ATTRIBUTE11                IN VARCHAR2,
             P_ATTRIBUTE12                IN VARCHAR2,
             P_ATTRIBUTE13                IN VARCHAR2,
             P_ATTRIBUTE14                IN VARCHAR2,
             P_ATTRIBUTE15                IN VARCHAR2,
             P_ATTRIBUTE_CATEGORY         IN VARCHAR2,
       	     p_calling_sequence           IN VARCHAR2 ,
             x_return_status             OUT NOCOPY VARCHAR2);

   --Bug9819170


END AP_ETAX_SERVICES_PKG;
/