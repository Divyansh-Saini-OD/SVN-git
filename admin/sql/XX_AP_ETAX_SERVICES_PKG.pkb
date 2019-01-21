create or replace PACKAGE BODY AP_ETAX_SERVICES_PKG AS
/* $Header: apetxsrb.pls 120.115.12010000.127 2014/01/22 15:42:48 harsanan ship $ */

  G_PKG_NAME          CONSTANT VARCHAR2(30) := 'AP_ETAX_SERVICES_PKG';
  G_MSG_UERROR        CONSTANT NUMBER       := FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR;
  G_MSG_ERROR         CONSTANT NUMBER       := FND_MSG_PUB.G_MSG_LVL_ERROR;
  G_MSG_SUCCESS       CONSTANT NUMBER       := FND_MSG_PUB.G_MSG_LVL_SUCCESS;
  G_MSG_HIGH          CONSTANT NUMBER       := FND_MSG_PUB.G_MSG_LVL_DEBUG_HIGH;
  G_MSG_MEDIUM        CONSTANT NUMBER       := FND_MSG_PUB.G_MSG_LVL_DEBUG_MEDIUM;
  G_MSG_LOW           CONSTANT NUMBER       := FND_MSG_PUB.G_MSG_LVL_DEBUG_LOW;
  G_LINES_PER_FETCH   CONSTANT NUMBER       := 1000;

  G_CURRENT_RUNTIME_LEVEL CONSTANT NUMBER   := FND_LOG.G_CURRENT_RUNTIME_LEVEL;
  G_LEVEL_UNEXPECTED      CONSTANT NUMBER   := FND_LOG.LEVEL_UNEXPECTED;
  G_LEVEL_ERROR           CONSTANT NUMBER   := FND_LOG.LEVEL_ERROR;
  G_LEVEL_EXCEPTION       CONSTANT NUMBER   := FND_LOG.LEVEL_EXCEPTION;
  G_LEVEL_EVENT           CONSTANT NUMBER   := FND_LOG.LEVEL_EVENT;
  G_LEVEL_PROCEDURE       CONSTANT NUMBER   := FND_LOG.LEVEL_PROCEDURE;
  G_LEVEL_STATEMENT       CONSTANT NUMBER   := FND_LOG.LEVEL_STATEMENT;
  G_MODULE_NAME           CONSTANT VARCHAR2(100) := 'AP.PLSQL.AP_ETAX_SERVICES_PKG.';

  -- Define the structures for lines and distributions
  TYPE Inv_Lines_Tab_Type IS TABLE OF ap_invoice_lines_all%ROWTYPE;
  TYPE Inv_Dists_Tab_Type IS TABLE OF ap_invoice_distributions_all%ROWTYPE;

  l_inv_line_list       Inv_Lines_Tab_Type;
  l_inv_tax_list        Inv_Lines_Tab_Type;
  l_inv_dist_list       Inv_Dists_Tab_Type;
  l_tax_dist_list       Inv_Dists_Tab_Type;
  p_rct_match_tax_list  Inv_Lines_Tab_Type;

  l_user_id		ap_invoices_all.created_by%TYPE := FND_GLOBAL.user_id;
  l_login_id		ap_invoices_all.last_update_login%TYPE := FND_GLOBAL.login_id;
  l_sysdate             DATE := sysdate;
  g_manual_tax_lines	VARCHAR2(1) := 'N';
  g_invoices_to_process NUMBER;

  l_payment_request_flag       varchar2(1); ---for bug 5967914
  l_manual_tax_line_rcv_mtch   varchar2(1);
  l_inv_header_rec2            ap_invoices_all%rowtype; -- For bug 6064593

  PROCEDURE Cache_Line_Defaults
                        (p_org_id               IN ap_invoices_all.org_id%type,
                         p_vendor_site_id       IN ap_supplier_sites_all.vendor_site_id%type,
                         p_calling_sequence     IN VARCHAR2);

  FUNCTION CANCEL_INVOICE
			(p_invoice_id   IN NUMBER,
			 p_line_number  IN NUMBER DEFAULT NULL,
			 p_calling_mode IN VARCHAR2) RETURN BOOLEAN;

  FUNCTION TAX_DISTRIBUTIONS_EXIST
			(p_invoice_id  IN NUMBER) RETURN BOOLEAN;

  FUNCTION TAX_ONLY_LINE_EXIST
                        (p_invoice_id  IN NUMBER) RETURN BOOLEAN;

  PROCEDURE get_converted_qty_price
			(x_invoice_distribution_id IN  NUMBER,
                         x_inv_price	       	   OUT NOCOPY NUMBER,
                         x_inv_qty		   OUT NOCOPY NUMBER);

  FUNCTION Populate_Rct_Match_Lines_GT
			(P_Invoice_Header_Rec      IN ap_invoices_all%ROWTYPE,
			 P_Event_Class_Code        IN VARCHAR2,
			 P_Error_Code              OUT NOCOPY VARCHAR2,
			 P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN;

  FUNCTION Update_Distributions
			(P_Invoice_header_rec    IN ap_invoices_all%ROWTYPE,
             		 P_Calling_Mode          IN VARCHAR2,
             		 P_All_Error_Messages    IN VARCHAR2,
             		 P_Error_Code            OUT NOCOPY VARCHAR2,
             		 P_Calling_Sequence      IN VARCHAR2) RETURN BOOLEAN;

  PROCEDURE Print(p_api_name   IN VARCHAR2,
	          p_debug_info IN VARCHAR2);

  FUNCTION Return_Other_Charge_Lines(
             P_Invoice_Header_Rec        IN ap_invoices_all%ROWTYPE,
             P_Error_Code                OUT NOCOPY VARCHAR2,
             P_Calling_Sequence          IN VARCHAR2) RETURN BOOLEAN;

  -- Bug 6694536
  FUNCTION SELF_ASSESS_TAX_DIST_EXIST
                        (p_invoice_id  IN NUMBER) RETURN BOOLEAN;
  FUNCTION Freeze_Distributions(
             P_Invoice_Header_Rec      IN ap_invoices_all%ROWTYPE,
             P_Calling_Mode            IN VARCHAR2,
             P_Event_Class_Code        IN VARCHAR2,
             P_All_Error_Messages      IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN;--Bug7592845


-- 7262269
/*=============================================================================
 |  FUNCTION - get_po_ship_to_org_id()
 |
 |  DESCRIPTION
 |      Procedure to return ship to organization id from po_line_locations
 |       table.
 |
 |  PARAMETERS
 |      p_po_line_location_id
 |
 |  RETURNS
 |      p_po_ship_to_org_id
 |
 *============================================================================*/
FUNCTION get_po_ship_to_org_id (
            p_po_line_location_id   IN NUMBER,
            p_inventory_item_id     IN NUMBER DEFAULT NULL, /*Bug 13079028*/
	    p_org_id                IN NUMBER DEFAULT NULL, /*Bug 13079028*/
	    p_application_id        IN NUMBER DEFAULT NULL, /*Bug 13079028*/
	    p_reference_key         IN VARCHAR2 DEFAULT NULL) RETURN NUMBER IS /*Bug 13079028*/
    --Bug9777752
    l_debug_info                 VARCHAR2(240);
    l_api_name			  CONSTANT VARCHAR2(100) := 'Get_po_ship_to_org_id';
    --Bug9777752
    l_po_ship_to_org_id NUMBER := NULL;
    l_application_short_name    fnd_application.application_short_name%type := NULL; /*Bug 13079028*/
BEGIN

    l_debug_info := 'Step 1: Check p_po_line_location_id '||p_po_line_location_id;
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;

    /*Bug 13079028: Need to pass inventory org id for OKL interfaced invoices*/

      IF p_application_id is not null then

         BEGIN

	     Select fa.application_short_name
		into l_application_short_name
	       from fnd_application fa,
		    fnd_product_installations fpi
	      Where fa.application_id = fpi.application_id
		and fa.application_id = p_application_id
		and nvl(fpi.status,'U') <> 'N'
		and rownum = 1;

	   l_debug_info := 'Step 2: Check l_application_short_name '||l_application_short_name;
           IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
           END IF;

	 EXCEPTION
	  WHEN NO_DATA_FOUND THEN
	    l_application_short_name := '';
	  WHEN OTHERS THEN
	    l_application_short_name := '';
	 END;
      END IF;
    /*Bug 13079028 : End*/

    IF (p_po_line_location_id is NULL) THEN /*Bug 13079028: Changed "=" to "IS NULL" */

      /*Bug 13079028: Added below conditions to fetch inventory org id in case inventory item id is populated or interfacing product is OKL*/
      IF (p_inventory_item_id is not null
         AND l_application_short_name = 'OKL') then

         l_po_ship_to_org_id := p_reference_key;

      ELSIF (p_inventory_item_id is not null
       AND p_org_id is not null) then

         l_po_ship_to_org_id := AP_ETAX_SERVICES_PKG.g_fsp_attributes(p_org_id).inventory_organization_id;

      ELSIF p_org_id is not null then

         l_po_ship_to_org_id := p_org_id;

      ELSE
         l_po_ship_to_org_id := '';
      END IF;

       l_debug_info := 'Step 2.1: Check SHIP_TO_ORG_ID '||l_po_ship_to_org_id;
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;

    ELSE /*Bug 13079028*/

     SELECT SHIP_TO_ORGANIZATION_ID
      INTO l_po_ship_to_org_id
     FROM po_line_locations_all pll
     WHERE pll.line_location_id = p_po_line_location_Id;


    l_debug_info := 'Step 2.2: Check SHIP_TO_ORG_ID '||l_po_ship_to_org_id;
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;

    END IF; /*Bug 13079028*/

    return l_po_ship_to_org_id;

EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END get_po_ship_to_org_id;
-- 7262269

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
 |    29-DEC-2003   SYIDNER        Use of new function to validate if tax was
 |                                 already calculated for the invoice.  Function
 |                                 created in the ap_etax_utility_pkg.
 |    28-JAN-2004   SYIDNER        Included handling for tax-only invoices and
 |                                 Manual import from Invoice workbench
 |
 *============================================================================*/

  FUNCTION Calculate(
             P_Invoice_Id              IN NUMBER,
             P_Line_Number             IN NUMBER,
             P_Calling_Mode            IN VARCHAR2,
             P_All_Error_Messages      IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN
  IS

    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);

    l_inv_header_rec             ap_invoices_all%ROWTYPE;
    l_event_class_code           zx_trx_headers_gt.event_class_code%TYPE;
    l_event_type_code            zx_trx_headers_gt.event_type_code%TYPE;

    l_tax_already_calculated     VARCHAR2(1);

    l_return_status_service       VARCHAR2(4000);
    l_msg_count                   NUMBER;
    l_msg_data                    VARCHAR2(4000);
    l_msg                         VARCHAR2(4000);

    l_return_status               BOOLEAN := TRUE;
    l_call_etax                   BOOLEAN :=FALSE; --Bug7136832
    /*l_no_tax_lines              VARCHAR2(1) := 'N';*/ --Bug6521120
    l_no_tax_lines                VARCHAR2(1) := 'Y';  --Bug6521120
    l_inv_rcv_matched             VARCHAR2(1) := 'N';

    l_api_name			  CONSTANT VARCHAR2(100) := 'Calculate';
    l_gt_error                    VARCHAR2(4000);     /*Bug 16842904*/


    --Taxware Custom Code
    l_twe_rec            number;
    l_twe_tax            varchar(1);
    l_twe_source         varchar(30);



    CURSOR Invoice_Header (c_invoice_id NUMBER) IS
    SELECT *
      FROM ap_invoices_all
     WHERE invoice_id = c_invoice_Id;

    CURSOR Invoice_Lines (c_invoice_id NUMBER) IS
    SELECT *
      FROM ap_invoice_lines_all
     WHERE invoice_id = c_invoice_id
       AND (line_type_lookup_code NOT IN ('TAX', 'AWT','RETROTAX','RETROITEM') OR
	   (line_type_lookup_code = 'RETROITEM' AND match_type = 'PO_PRICE_ADJUSTMENT'))  --Bug10416960
       AND nvl(discarded_flag, 'N')  <> 'Y'  --Bug8811102
       AND nvl(cancelled_flag, 'N') <> 'Y';  --Bug8811102;

    -- This cursor will be used in the case the API is call
    -- to calculate tax for only 1 line
    CURSOR Invoice_Line (c_invoice_id  NUMBER,
			 c_line_number NUMBER) IS
    SELECT *
      FROM ap_invoice_lines_all
     WHERE invoice_id  = c_invoice_id
       AND line_number = c_line_number
       AND (line_type_lookup_code NOT IN ('TAX', 'AWT','RETROTAX','RETROITEM') OR
	       (line_type_lookup_code = 'RETROITEM' AND match_type = 'PO_PRICE_ADJUSTMENT'))  --Bug10416960
       AND nvl(discarded_flag, 'N')  <> 'Y'  --Bug8811102
       AND nvl(cancelled_flag, 'N') <> 'Y';  --Bug8811102

    CURSOR Tax_Lines_to_import (c_invoice_id IN NUMBER) IS
    SELECT *
      FROM ap_invoice_lines_all
     WHERE invoice_id            = c_invoice_id
       AND line_type_lookup_code = 'TAX'
       AND summary_tax_line_id   IS NULL
       AND nvl(discarded_flag, 'N')  <> 'Y'  --Bug8811102
       AND nvl(cancelled_flag, 'N') <> 'Y';  --Bug8811102

    l_validation_request_id ap_invoices_all.validation_request_id%TYPE;

    CURSOR c_selected_invoices IS
    SELECT trx_id, event_class_code
      FROM zx_trx_headers_gt
     WHERE application_id   =  ap_etax_pkg.ap_application_id
       AND entity_code      =  ap_etax_pkg.ap_entity_code
       AND event_class_code IN (ap_etax_pkg.ap_inv_event_class_code,
                                ap_etax_pkg.ap_pp_event_class_code,
                                ap_etax_pkg.ap_er_event_class_code);

    --6922266
    l_count   NUMBER;

  BEGIN

    --Print(l_api_name,'AP_ETAX_SERVICES_PKG.Calculate (+)');
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'AP_ETAX_SERVICES_PKG.Calculate (+)');
    END IF;

    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.Calculate<-' || P_calling_sequence;

    l_validation_request_id := ap_approval_pkg.g_validation_request_id;

    g_invoices_to_process := 0;


    --Bug9436217
    IF P_Invoice_Id IS NULL THEN
    --Bug9436217

       IF NOT AP_ETAX_SERVICES_PKG.Bulk_Populate_Headers_GT(
		p_validation_request_id => l_validation_request_id,
		p_calling_mode		=> P_Calling_Mode,
		p_error_code            => p_error_code) THEN

	  l_return_status := FALSE;
       END IF;

       -- Bug 6922266 Begin
       -----------------------------------------------------------------
       l_debug_info := 'Reset Tax Calculation Flag for Concurrent Mode';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
       --Print(l_api_name, l_debug_info);
       -----------------------------------------------------------------

       l_count := 0;
       /* Added the following 3 hints for bug#8263883 */
       UPDATE /*+ index(ail,AP_INVOICE_LINES_U1) */ ap_invoice_lines_all ail
       SET    tax_already_calculated_flag = NULL
       WHERE  ail.invoice_id IN (SELECT /*+ cardinality(gt 10) unnest */ DISTINCT(trx_id)
                                 FROM   zx_trx_headers_gt gt
                                 WHERE  application_id = 200
                                 AND    entity_code = 'AP_INVOICES')
       AND    NVL(ail.tax_already_calculated_flag, 'N') = 'Y'
	   AND    NVL(ail.historical_flag, 'N') = 'N' --bug14671024
       AND    NOT EXISTS
                (SELECT /*+ no_unnest index(zf,ZX_LINES_DET_FACTORS_U1) */ 'Line Determining Factors Exist'
                   FROM zx_lines_det_factors zf
                  WHERE zf.application_id   = 200
                    AND zf.entity_code        = 'AP_INVOICES'
                    AND zf.event_class_code IN ('STANDARD INVOICES',
                                                'PREPAYMENT INVOICES',
                                                'EXPENSE REPORTS')
                    -- bug 7233679
                    AND ZF.TRX_LEVEL_TYPE = 'LINE'
                    AND ZF.INTERNAL_ORGANIZATION_ID = AIL.ORG_ID
                    AND ZF.lEDGER_ID=AIL.SET_OF_BOOKS_ID
                    -- bug 7233679
                    AND zf.trx_id           = ail.invoice_id
                    AND zf.trx_line_id      = ail.line_number);

       l_count := SQL%ROWCOUNT;
       -----------------------------------------------------------------
       l_debug_info := l_count ||' rows updated in ap_invoice_lines_all.';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
       --Print(l_api_name, l_debug_info);
       -----------------------------------------------------------------
       --Bug 6922266 End

    ELSE

       DELETE FROM ZX_TRX_HEADERS_GT;

       -----------------------------------------------------------------
       l_debug_info := 'Populating invoice header local record';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
       --Print(l_api_name,l_debug_info);
       -----------------------------------------------------------------
       OPEN  Invoice_Header(p_invoice_id);
       FETCH Invoice_Header INTO l_inv_header_rec;
       CLOSE Invoice_Header;

       -- Bug 9034372.
       -- In the case of quick credit invoice, Calculate tax should be invoked
       -- only during cancel of quick creditted invoice and not during validation
       -- or any other tax action.
       -- Hence control would return if the invoice is quick credit invoice and
       -- calling mode is not QUICK CANCEL. Added the calling mode check.

       IF ((l_inv_header_rec.quick_credit = 'Y' AND P_Calling_Mode NOT IN ('QUICK CANCEL')) OR    -- Bug 5638822
           (l_inv_header_rec.invoice_type_lookup_code IN ('AWT', 'INTEREST'))) THEN
          RETURN l_return_status;
       END IF;

       -------------------------------------------------------------------
       l_debug_info := 'Is tax already called invoice level';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
       --Print(l_api_name,l_debug_info);
       -------------------------------------------------------------------
       IF (AP_ETAX_UTILITY_PKG.Is_Tax_Already_Calc_Inv(
	          P_Invoice_Id           => p_invoice_id,
	          P_Calling_Sequence     => l_curr_calling_sequence)) THEN

           l_tax_already_calculated := 'Y';
       ELSE
           l_tax_already_calculated := 'N';
       END IF;

       -----------------------------------------------------------------
       l_debug_info := 'Populate Header';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
       --Print(l_api_name,l_debug_info);
       -----------------------------------------------------------------
       IF NOT(AP_ETAX_SERVICES_PKG.Populate_Headers_GT(
	      P_Invoice_Header_Rec         => l_inv_header_rec,
	      P_Calling_Mode               => P_Calling_Mode,
	      P_eTax_Already_called_flag   => l_tax_already_calculated,
	      P_Event_Class_Code           => l_event_class_code,
	      P_Event_Type_Code            => l_event_type_code,
	      P_Error_Code                 => P_error_code,
	      P_Calling_Sequence           => l_curr_calling_sequence )) THEN

		--Bug15914464: Start
        IF AP_APPROVAL_PKG.G_VALIDATION_REQUEST_ID IS NULL THEN
          APP_EXCEPTION.RAISE_EXCEPTION;
        ELSE
         IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Error in AP_ETAX_SERVICES_PKG.Populate_Headers_GT');
         END IF;
		 Insert into ap_errors_gt(invoice_id , message_text) values(l_inv_header_rec.invoice_id , 'Error in AP_ETAX_SERVICES_PKG.Populate_Headers_GT');
		 --Bug15914464: End
 	     l_return_status := FALSE;
	    END IF; --Bug15914464
       END IF;

       ap_etax_pkg.g_inv_id_list(1) := l_inv_header_rec.invoice_id;


       --Bug9436217

    -----------------------------------------------------------------
    l_debug_info := 'Reset Tax Calculation Flag';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    --Print(l_api_name,l_debug_info);
    -----------------------------------------------------------------
    --
    -- Reset invoice lines tax_already_calculated_flag to Null. This
    -- will reset only if the following conditions are met.
    --
    --
    -- 1. Invoices that have gone through tax calculation on recouped
    --    prepay distributions during matching AND tax is calculated
    --    for the first time on the invoice.
    -- 2. This is required to pass document level event type is passed
    --    to eTax as STANDARD UPDATED and line level action as CREATE.
    -- 3. This update must happen ONLY after populate_headers_gt is
    --    invoked.
    --




       l_count:=0;

       UPDATE ap_invoice_lines_all ail
          SET tax_already_calculated_flag = NULL
        WHERE ail.invoice_id = p_invoice_id
          AND nvl(ail.tax_already_calculated_flag, 'N') = 'Y'
		  AND NVL(ail.historical_flag, 'N') = 'N' --bug14671024
          AND NOT EXISTS
		      (SELECT 'Line Determining Factors Exist'
	             from zx_lines_det_factors zf
 	            where zf.application_id   = 200
  	              and zf.entity_code	    = 'AP_INVOICES'
	              and zf.event_class_code IN ('STANDARD INVOICES', 'PREPAYMENT INVOICES', 'EXPENSE REPORTS')
	              and zf.trx_id           = ail.invoice_id
  	              and zf.trx_line_id      = ail.line_number);

       l_count := SQL%ROWCOUNT;
       -----------------------------------------------------------------
       l_debug_info := l_count ||' rows updated in ap_invoice_lines_all.';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
       --Print(l_api_name, l_debug_info);
       -----------------------------------------------------------------
       --Bug 6922266

       --Bug9436217


    END IF;

    IF g_invoices_to_process = 0 THEN
       RETURN TRUE;
    END IF;


    -----------------------------------------------------------------
    l_debug_info := 'Purge staging tables';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    --Print(l_api_name,l_debug_info);
    -----------------------------------------------------------------
    DELETE FROM ZX_TRANSACTION_LINES_GT;
    DELETE FROM ZX_IMPORT_TAX_LINES_GT;
    DELETE FROM ZX_TRX_TAX_LINK_GT;

    AP_ETAX_SERVICES_PKG.G_SITE_ATTRIBUTES.DELETE;
    AP_ETAX_SERVICES_PKG.G_ORG_ATTRIBUTES.DELETE;


    OPEN C_SELECTED_INVOICES;
    LOOP
        FETCH C_SELECTED_INVOICES
        BULK COLLECT INTO AP_ETAX_PKG.G_INV_ID_LIST,
                          AP_ETAX_PKG.G_EVNT_CLS_LIST
        LIMIT AP_ETAX_PKG.G_BATCH_LIMIT;

        --Bug9436217

        IF P_Invoice_Id IS NULL THEN

        --Bug9436217

           EXIT WHEN (C_SELECTED_INVOICES%NOTFOUND
                      AND AP_ETAX_PKG.G_INV_ID_LIST.COUNT <= 0);
        ELSE
           EXIT WHEN AP_ETAX_PKG.G_INV_ID_LIST.COUNT <= 0;
        END IF;

        FOR i IN AP_ETAX_PKG.G_INV_ID_LIST.FIRST.. AP_ETAX_PKG.G_INV_ID_LIST.LAST
        LOOP

           --Bug9436217

           IF P_Invoice_Id IS NULL THEN

           --Bug9436217

              -----------------------------------------------------------------
              l_debug_info := 'Collect Invoice Header Details';
              IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                 FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
              END IF;
              --Print(l_api_name,l_debug_info);
              -----------------------------------------------------------------
              OPEN  Invoice_Header(ap_etax_pkg.g_inv_id_list(i));
              FETCH Invoice_Header INTO l_inv_header_rec;
              CLOSE Invoice_Header;
              l_inv_header_rec2:=l_inv_header_rec; ---for bug 6064593
              -----------------------------------------------------------------
              l_debug_info := 'Get event class code';
              IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                 FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
              END IF;
              --Print(l_api_name,l_debug_info);
              -----------------------------------------------------------------
              l_event_class_code := ap_etax_pkg.g_evnt_cls_list(i);

           ELSE
	          ap_etax_pkg.g_inv_id_list(1) := l_inv_header_rec.invoice_id;
              l_inv_header_rec2:=l_inv_header_rec; ---for bug 6064593

           END IF;

           -- Bug 9526592 : Enhanced debug message
           -----------------------------------------------------------------
           l_debug_info := 'Cache Line Defaults :' ||
	                   ' Invoice Type Lookup Code = ' || l_inv_header_rec.invoice_type_lookup_code ||
			   ' ,Invoice Id = '              || l_inv_header_rec.invoice_id               ||
			   ' ,Org id = '                  || l_inv_header_rec.org_id                   ||
			   ' ,Vendor Site Id = '          || l_inv_header_rec.vendor_site_id           ||
			   ' ,Party Site Id = '           || l_inv_header_rec.party_site_id           ;
           IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
           END IF;
           --Print(l_api_name,l_debug_info);
           --Bug9777752
           -----------------------------------------------------------------
                IF l_inv_header_rec.invoice_type_lookup_code = 'PAYMENT REQUEST' THEN  /* if
                  condition for bug 5967914 as we need tp pass party_site_id instead of
                  vendor_site_id if invoice_type_lookup_code ='PAYMENT REQUEST' */

                  l_payment_request_flag :='Y';  --Bug13899981

                  IF (NOT AP_ETAX_SERVICES_PKG.g_site_attributes.exists(l_inv_header_rec.party_site_id) OR
                      NOT AP_ETAX_SERVICES_PKG.g_org_attributes.exists(l_inv_header_rec.org_id))  THEN


		      -- Bug 9777752 : Added Begin - Exception - End block
		      BEGIN
     	                 Cache_Line_Defaults
	                     (p_org_id           => l_inv_header_rec.org_id
	                      ,p_vendor_site_id   => l_inv_header_rec.party_site_id
	                      ,p_calling_sequence => l_curr_calling_sequence);
		      EXCEPTION
                         WHEN NO_DATA_FOUND THEN
                            FND_MESSAGE.SET_NAME('SQLAP','AP_INVALID_VENDOR_SITE_CODE');
                            IF AP_APPROVAL_PKG.G_VALIDATION_REQUEST_ID IS NULL THEN
                                APP_EXCEPTION.RAISE_EXCEPTION;
                            ELSE

			        --Bug15914464: Start
                                IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                                  FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Error in AP_ETAX_SERVICES_PKG.Cache_Line_Defaults');
                                END IF;
		                       Insert into ap_errors_gt(invoice_id , message_text) values(l_inv_header_rec.invoice_id , 'Error in AP_ETAX_SERVICES_PKG.Cache_Line_Defaults');
				--Bug15914464: End

                                RETURN FALSE;
                            END IF;
		      END ;
                  END IF;
                ELSE

                 l_payment_request_flag :='N';  --Bug13899981
                 IF (NOT AP_ETAX_SERVICES_PKG.g_site_attributes.exists(l_inv_header_rec.vendor_site_id) OR
                     NOT AP_ETAX_SERVICES_PKG.g_org_attributes.exists(l_inv_header_rec.org_id)) THEN


		     -- Bug 9777752 : Added Begin - Exception - End block
		     BEGIN
               	        Cache_Line_Defaults
	                     ( p_org_id           => l_inv_header_rec.org_id
	                       ,p_vendor_site_id   => l_inv_header_rec.vendor_site_id
    	                       ,p_calling_sequence => l_curr_calling_sequence);
		     EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                           FND_MESSAGE.SET_NAME('SQLAP','AP_INVALID_VENDOR_SITE_CODE');
                           IF AP_APPROVAL_PKG.G_VALIDATION_REQUEST_ID IS NULL THEN
                               APP_EXCEPTION.RAISE_EXCEPTION;
                           ELSE
				--Bug15914464: Start
                                IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                                  FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Error in AP_ETAX_SERVICES_PKG.Cache_Line_Defaults');
                                END IF;
		                       Insert into ap_errors_gt(invoice_id , message_text) values(l_inv_header_rec.invoice_id , 'Error in AP_ETAX_SERVICES_PKG.Cache_Line_Defaults');
			        --Bug15914464: End
                               RETURN FALSE;
                           END IF;
		     END ;
                 END IF;
                END IF;

	   -----------------------------------------------------------------
       --Bug9777752
           l_debug_info := 'Populate invoice tax lines collection';
           IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
           END IF;
           --Print(l_api_name,l_debug_info);
           -----------------------------------------------------------------
           BEGIN
             OPEN  Tax_Lines_to_Import (ap_etax_pkg.g_inv_id_list(i));
             FETCH Tax_Lines_to_Import
             BULK  COLLECT INTO l_inv_tax_list;
             CLOSE Tax_Lines_to_Import;
           EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
           END;
            /* Start added for 6014115 - If a invoice has some item lines
               (receipt matched) and manual tax line not matched to receipt
                then we need to pass the applied to fields as null.
                So to do the same we are chking weahter we have manual
                tax lines or not by  g_manual_tax_lines = 'Y' and
                manual tax lines are receipt matched or not by
                l_manual_tax_line_rcv_mtch := 'N'.And then we will make
                the applied to columns values as NULL. also i will pass
                trans_lines(i).applied_to_trx_id   and
                trans_lines(i).applied_to_trx_id   as nullin this case.
                In this case we will proprate the manual tax line among
                all the ITEM lines.We are doing these chages as per
                AP_HLD_ETAX_VERSION_2_3.DOC. This is the documnet in
                in which we have all the guide lines for AP's Etax takeup. */
            IF ( l_inv_tax_list.COUNT > 0) THEN
              FOR i IN l_inv_tax_list.FIRST..l_inv_tax_list.LAST LOOP
                IF (l_inv_tax_list(i).rcv_transaction_id IS NOT NULL) THEN
                   l_manual_tax_line_rcv_mtch := 'Y';
                   EXIT;
                ELSE
                   l_manual_tax_line_rcv_mtch := 'N';
                   EXIT;
                END IF;
               END LOOP;
            ELSE
                l_manual_tax_line_rcv_mtch := NULL;

            END IF;
            ---End for bug 6014115.
           -----------------------------------------------------------------
           l_debug_info := 'Populate invoice lines collection';
           IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
           END IF;
           --Print(l_api_name,l_debug_info);
           -----------------------------------------------------------------
           -- If there is any tax line to be imported the API will call
           -- import document with tax for the whole invoice omiting the
           -- p_line_number parameter

           IF (P_line_number IS NOT NULL AND
               l_inv_tax_list.COUNT = 0 ) THEN
               BEGIN
                 OPEN  Invoice_Line (p_invoice_id, p_line_number);
                 FETCH Invoice_Line
                 BULK  COLLECT INTO l_inv_line_list;
                 CLOSE Invoice_Line;
               EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
               END;
           ELSE
               BEGIN
                 OPEN  Invoice_Lines (ap_etax_pkg.g_inv_id_list(i));
                 FETCH Invoice_Lines
                 BULK  COLLECT INTO l_inv_line_list;
                 CLOSE Invoice_Lines;
               EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
               END;
           END IF;


           --IF l_tax_already_calculated IS NULL THEN --Bug14779241
              -------------------------------------------------------------------
              l_debug_info := 'Is tax already called invoice level';
              IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                 FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
              END IF;
              --Print(l_api_name,l_debug_info);
              -------------------------------------------------------------------
              IF (AP_ETAX_UTILITY_PKG.Is_Tax_Already_Calc_Inv(
             	     P_Invoice_Id           => l_inv_header_rec.invoice_id,
                     P_Calling_Sequence     => l_curr_calling_sequence)) THEN
	           l_tax_already_calculated := 'Y';
              ELSE
                   l_tax_already_calculated := 'N';
              END IF;
           --END IF;


           IF (l_tax_already_calculated = 'Y') THEN
               -----------------------------------------------------------------
               l_debug_info := 'If tax already calculated call freeze distributions';
               IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                 FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
               END IF;
               --Print(l_api_name,l_debug_info);
               -----------------------------------------------------------------
               --Bug7592845
               IF NOT(AP_ETAX_SERVICES_PKG.Freeze_itm_Distributions(
	                P_Invoice_Header_Rec  => l_inv_header_rec,
	                P_Calling_Mode        => 'FREEZE DISTRIBUTIONS',
	                P_Event_Class_Code    => l_event_class_code,
	                P_All_Error_Messages  => P_All_Error_Messages,
	                P_Error_Code          => P_error_code,
	                P_Calling_Sequence    => l_curr_calling_sequence)) THEN

		--Bug15914464: Start
        IF AP_APPROVAL_PKG.G_VALIDATION_REQUEST_ID IS NULL THEN
          APP_EXCEPTION.RAISE_EXCEPTION;
        ELSE
         IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Error in AP_ETAX_SERVICES_PKG.Freeze_itm_Distributions');
         END IF;
		 Insert into ap_errors_gt(invoice_id , message_text) values(l_inv_header_rec.invoice_id , 'Error in AP_ETAX_SERVICES_PKG.Freeze_itm_Distributions');
		 --Bug15914464: End
          l_return_status := FALSE;
		END IF; --Bug15914464
	       END IF;
	   END IF;

           -- This flow assumes that the UI will not call this API when the invoice
           -- has tax lines to be imported and tax lines to matche to receipts. It
           -- is restricted as this flow calls only 1 service at a time.

           IF (l_inv_line_list.COUNT > 0 AND l_inv_tax_list.COUNT = 0) THEN

               g_manual_tax_lines := 'N';
               l_call_etax        := TRUE; --Bug7136832

               -----------------------------------------------------------------
               l_debug_info := 'Populate TRX lines. No tax lines exist';
               IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                  FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
               END IF;
               --Print(l_api_name,l_debug_info);
               -----------------------------------------------------------------
               IF (l_return_status = TRUE)  THEN
                   IF NOT(AP_ETAX_SERVICES_PKG.Populate_Lines_GT(
				P_Invoice_Header_Rec      => l_inv_header_rec,
				P_Calling_Mode            => P_Calling_Mode,
				P_Event_Class_Code        => l_event_class_code,
		          	P_Line_Number             => P_Line_Number,
		          	P_Error_Code              => P_error_code,
		          	P_Calling_Sequence        => l_curr_calling_sequence )) THEN

                       l_return_status := FALSE;
		       l_gt_error      := P_error_code;      /*Bug 16842904*/
					   --Bug15914464: Start
					   IF P_Invoice_Id IS NULL THEN
					      RETURN l_return_status;
					   END IF;
					   --Bug15914464: End
	           END IF;
	       END IF;

               /*l_no_tax_lines := 'Y'; */ --Bug6521120

           ELSIF (l_inv_line_list.COUNT > 0 AND l_inv_tax_list.COUNT > 0) THEN

		      l_no_tax_lines := 'N'; --Bug6521120
                      g_manual_tax_lines := 'Y';
                      l_call_etax        := TRUE; --Bug7136832

                  -----------------------------------------------------------------
                  l_debug_info := 'Populate TRX Lines. IMPORT';
                  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                  END IF;
                  --Print(l_api_name,l_debug_info);
                  -----------------------------------------------------------------
	          IF (l_return_status = TRUE) THEN
	              IF NOT(AP_ETAX_SERVICES_PKG.Populate_Lines_GT(
			          P_Invoice_Header_Rec      => l_inv_header_rec,
			          P_Calling_Mode            => P_Calling_Mode,
			          P_Event_Class_Code        => l_event_class_code,
			          P_Line_Number             => P_Line_Number,
			          P_Error_Code              => P_error_code,
			          P_Calling_Sequence        => l_curr_calling_sequence )) THEN

                       l_return_status := FALSE;
		       l_gt_error      := P_error_code;      /*Bug 16842904*/
					   --Bug15914464: Start
					   IF P_Invoice_Id IS NULL THEN
					      RETURN l_return_status;
					   END IF;
					   --Bug15914464: End
	              END IF;
	          END IF;

	          -----------------------------------------------------------------
	          l_debug_info := 'Populate TAX lines to be imported';
              IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                  FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
              END IF;
	          --Print(l_api_name,l_debug_info);
	          -----------------------------------------------------------------
	          IF (l_return_status = TRUE) THEN
	              IF NOT(AP_ETAX_SERVICES_PKG.Populate_Tax_Lines_GT(
			          P_Invoice_Header_Rec      => l_inv_header_rec,
			          P_Calling_Mode            => P_Calling_Mode,
			          P_Event_Class_Code        => l_event_class_code,
			          P_Tax_only_Flag           => 'N',
			          P_Inv_Rcv_Matched         => l_Inv_Rcv_Matched,
			          P_Error_Code              => P_error_code,
			          P_Calling_Sequence        => l_curr_calling_sequence )) THEN


	                   l_return_status := FALSE;
					   --Bug15914464: Start
					   IF P_Invoice_Id IS NULL THEN
					      RETURN l_return_status;
					   END IF;
					   --Bug15914464: End
	              END IF;
	          END IF;

           ELSIF (l_inv_tax_list.COUNT > 0 AND l_inv_line_list.COUNT = 0) THEN

	          -- Invoice is Tax only. We will need to determine if lines are receipt
		  -- matched to call calculate or if all tax information is populated to
		  -- call import. In both cases a pseudo line should be created to pass
	          -- additional information in the trx_lines GT table.
              l_no_tax_lines := 'N';--Bug6521120
              l_call_etax        := TRUE; --Bug7136832
                  -----------------------------------------------------------------
	          l_debug_info := 'Populate pseudo TRX line, TAX lines to be imported';
              IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                 FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
              END IF;
              --Print(l_api_name,l_debug_info);
	          -----------------------------------------------------------------
		      IF (l_return_status = TRUE) THEN
	              IF NOT(AP_ETAX_SERVICES_PKG.Populate_Tax_Lines_GT(
			          P_Invoice_Header_Rec      => l_inv_header_rec,
			          P_Calling_Mode            => P_Calling_Mode,
			          P_Event_Class_Code        => l_event_class_code,
			          P_Tax_only_Flag           => 'Y',
			          P_Inv_Rcv_Matched         => l_Inv_Rcv_Matched,
			          P_Error_Code              => P_error_code,
			          P_Calling_Sequence        => l_curr_calling_sequence )) THEN


	                   l_return_status := FALSE;
					   --Bug15914464: Start
					   IF P_Invoice_Id IS NULL THEN
					      RETURN l_return_status;
					   END IF;
					   --Bug15914464: End
	              END IF;
	          END IF;
           ELSE
            --Bug7136832
            -----------------------------------------------------------------
            l_debug_info := 'No invoice lines to be processed for Invoice Id '||l_inv_header_rec.invoice_id;
            IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
            END IF;
            --Print(l_api_name,l_debug_info);
            -----------------------------------------------------------------
            DELETE FROM zx_trx_headers_gt
                WHERE application_id   = AP_ETAX_PKG.AP_APPLICATION_ID
                  AND entity_code      = AP_ETAX_PKG.AP_ENTITY_CODE
                  AND event_class_code IN
                                 (AP_ETAX_PKG.AP_INV_EVENT_CLASS_CODE,
                                  AP_ETAX_PKG.AP_PP_EVENT_CLASS_CODE,
                                  AP_ETAX_PKG.AP_ER_EVENT_CLASS_CODE)
                  AND trx_id = l_inv_header_rec.invoice_id;

               --Bug9436217

               If P_Invoice_Id IS  NOT NULL THEN -- Bug 10170317

               --Bug9436217

                  -----------------------------------------------------------------
                  l_debug_info := 'Invoice Id Is Not Null - ' || P_Invoice_Id ; -- Bug 10170317
                  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                     FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                  END IF;
                  --Print(l_api_name,l_debug_info);
                  -----------------------------------------------------------------
                  RETURN TRUE;
               END IF;
           --Bug7136832
           END IF;
        END LOOP;

        --Bug7136832

        IF NOT l_call_etax  THEN
            -----------------------------------------------------------------
            l_debug_info := 'No lines to be processed Hence Return';
            IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
            END IF;
            --Print(l_api_name,l_debug_info);
            -----------------------------------------------------------------
            RETURN TRUE;
        END IF;

        --Bug7136832

        AP_ETAX_PKG.G_INV_ID_LIST.DELETE;
        AP_ETAX_PKG.G_EVNT_CLS_LIST.DELETE;
    END LOOP;
    CLOSE C_SELECTED_INVOICES;

    AP_ETAX_PKG.G_INV_ID_LIST.DELETE;
    AP_ETAX_PKG.G_EVNT_CLS_LIST.DELETE;


    IF (l_Inv_Rcv_Matched = 'Y' OR l_no_tax_lines = 'Y') THEN

        IF (l_return_status = TRUE) THEN
            -----------------------------------------------------------------
            l_debug_info := 'Call calculate_tax service';
            IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
            END IF;
            --Print(l_api_name,l_debug_info);
            -----------------------------------------------------------------


        --Begin Taxware Custom Code to Update Transaction ID and Calculated Tax Y or N
		--Modified below logic to use Global temporary table for Defect ID #43203 
        
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.BEGIN','TWE_P2P_OD: GET TRANS_ID');
       
         /*BEGIN
           SELECT COUNT(*)
           INTO L_TWE_REC
           FROM XXTWE_TAX_PARTNER 
           WHERE REC_TYPE = 'TWE_PARTNER_BYPASS';
          
         
           IF L_TWE_REC = 1 THEN
             
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: L_TWE_REC Count: '||L_TWE_REC);
            
                 
               BEGIN
                   SELECT SOURCE
                   INTO L_TWE_SOURCE
                   FROM AP_INVOICES_ALL
                   WHERE INVOICE_ID = NVL(P_INVOICE_ID,l_inv_header_rec.invoice_id);
                  
                   FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: Found transaction source: '||L_TWE_SOURCE);
                   
               EXCEPTION
                  WHEN OTHERS THEN
                    L_TWE_SOURCE := NULL;
                    FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: Did not find transaction source. Error: '||SQLERRM);
                  
               END;
               
             
              BEGIN
                 
/*                 IF trim(L_TWE_SOURCE) IN ('US_OD_TDM','Manual Invoice Entry') AND trim(L_TAX_ALREADY_CALCULATED) = 'Y' THEN 09-13-2016    */
/* removed "Manual Invoice Entry" from twe_source  exception. Tax will be calculated for this source. Below is modified code : 09-13-2016 
                 IF trim(L_TWE_SOURCE) = 'US_OD_TDM' AND trim(L_TAX_ALREADY_CALCULATED) = 'Y' THEN

                 
                  L_TWE_TAX := 'N';
                 
                 ELSE
                  L_TWE_TAX := 'Y';
                 
                 END IF;
              
         
                  UPDATE XXTWE_TAX_PARTNER 
                  SET TRX_ID = P_INVOICE_ID,
                      TAX_CALCULATED  = L_TAX_ALREADY_CALCULATED,
                      TRX_SOURCE = L_TWE_SOURCE,
                      CALL_TAX_PARTNER = L_TWE_TAX
                  WHERE REC_TYPE = 'TWE_PARTNER_BYPASS';
                  
                  FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: p_invoice_id: '||P_INVOICE_ID);
                  FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: l_tax_already_calculated: '||L_TAX_ALREADY_CALCULATED);
                  FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: l_twe_tax - Call Tax Partner: '||L_TWE_TAX);
                  
              EXCEPTION
               WHEN OTHERS THEN
                     FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: XXTWE_TAX_PARTNER not updated. Error: '||SQLERRM);
                     
              END;
             
             
           
           ELSE
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: XXTWE_TAX_PARTNER not updated. L_TWE_REC Count: '||L_TWE_REC);
           
           END IF;
           
         EXCEPTION
           
            WHEN OTHERS THEN
                
                FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: UPDATE TRANS_ID Error: '||SQLERRM);
             
         END;
     
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.END','TWE_P2P_OD: GET TRANS_ID'); */
		 
		 
		 BEGIN
			  SELECT COUNT(*)
			  INTO L_TWE_REC
			  FROM XXTWE_TAX_PARTNER_GT
			  WHERE REC_TYPE = 'TWE_PARTNER_BYPASS';
  IF L_TWE_REC   = 0 THEN
    FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: L_TWE_REC Count: '||L_TWE_REC);
    BEGIN
      SELECT SOURCE
      INTO L_TWE_SOURCE
      FROM AP_INVOICES_ALL
      WHERE INVOICE_ID = NVL(P_INVOICE_ID,l_inv_header_rec.invoice_id);
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: Found transaction source: '||L_TWE_SOURCE);
    EXCEPTION
    WHEN OTHERS THEN
      L_TWE_SOURCE := NULL;
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: Did not find transaction source. Error: '||SQLERRM);
    END;
    BEGIN
      /*                 IF trim(L_TWE_SOURCE) IN ('US_OD_TDM','Manual Invoice Entry') AND trim(L_TAX_ALREADY_CALCULATED) = 'Y' THEN 09-13-2016    */
      /* removed "Manual Invoice Entry" from twe_source  exception. Tax will be calculated for this source. Below is modified code : 09-13-2016 */
      IF trim(L_TWE_SOURCE) = 'US_OD_TDM' AND trim(L_TAX_ALREADY_CALCULATED) = 'Y' THEN
        L_TWE_TAX          := 'N';
      ELSE
        L_TWE_TAX := 'Y';
      END IF;
      INSERT
      INTO XXTWE_TAX_PARTNER_GT
        (
          REC_TYPE,
          TRX_SOURCE,
          TAX_CALCULATED,
          CALL_TAX_PARTNER,
          TRX_ID,
          TRX_LINE_ID
        )
        VALUES
        (
          'TWE_PARTNER_BYPASS',
          L_TWE_SOURCE,
          L_TAX_ALREADY_CALCULATED,
          L_TWE_TAX,
          P_INVOICE_ID,
          NULL
        );
      
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: p_invoice_id: '||P_INVOICE_ID);
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: l_tax_already_calculated: '||L_TAX_ALREADY_CALCULATED);
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: l_twe_tax - Call Tax Partner: '||L_TWE_TAX);
    EXCEPTION
    WHEN OTHERS THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: XXTWE_TAX_PARTNER_GT not inserted. Error: '||SQLERRM);
    END;
  ELSE
    --FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: XXTWE_TAX_PARTNER not updated. L_TWE_REC Count: '||L_TWE_REC);
    FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: L_TWE_REC Count: '||L_TWE_REC);
    BEGIN
      SELECT SOURCE
      INTO L_TWE_SOURCE
      FROM AP_INVOICES_ALL
      WHERE INVOICE_ID = NVL(P_INVOICE_ID,l_inv_header_rec.invoice_id);
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: Found transaction source: '||L_TWE_SOURCE);
    EXCEPTION
    WHEN OTHERS THEN
      L_TWE_SOURCE := NULL;
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: Did not find transaction source. Error: '||SQLERRM);
    END;
    BEGIN
      /*                 IF trim(L_TWE_SOURCE) IN ('US_OD_TDM','Manual Invoice Entry') AND trim(L_TAX_ALREADY_CALCULATED) = 'Y' THEN 09-13-2016    */
      /* removed "Manual Invoice Entry" from twe_source  exception. Tax will be calculated for this source. Below is modified code : 09-13-2016 */
      IF trim(L_TWE_SOURCE) = 'US_OD_TDM' AND trim(L_TAX_ALREADY_CALCULATED) = 'Y' THEN
        L_TWE_TAX          := 'N';
      ELSE
        L_TWE_TAX := 'Y';
      END IF;
      UPDATE XXTWE_TAX_PARTNER_GT
      SET TRX_ID         = P_INVOICE_ID,
        TAX_CALCULATED   = L_TAX_ALREADY_CALCULATED,
        TRX_SOURCE       = L_TWE_SOURCE,
        CALL_TAX_PARTNER = L_TWE_TAX
      WHERE REC_TYPE     = 'TWE_PARTNER_BYPASS';
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: p_invoice_id: '||P_INVOICE_ID);
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: l_tax_already_calculated: '||L_TAX_ALREADY_CALCULATED);
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: l_twe_tax - Call Tax Partner: '||L_TWE_TAX);
    EXCEPTION
    WHEN OTHERS THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: XXTWE_TAX_PARTNER_GT not updated. Error: '||SQLERRM);
    END;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.','TWE_P2P_OD: UPDATE TRANS_ID Error: '||SQLERRM);
END;
FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||L_API_NAME||'.END','TWE_P2P_OD: GET TRANS_ID'); 
        -- End Taxware Custom Code 


            zx_api_pub.calculate_tax(
	          p_api_version      => 1.0,
	          p_init_msg_list    => FND_API.G_TRUE,
	          p_commit           => FND_API.G_FALSE,
	          p_validation_level => FND_API.G_VALID_LEVEL_FULL,
	          x_return_status    => l_return_status_service,
	          x_msg_count        => l_msg_count,
	          x_msg_data         => l_msg_data);
       END IF;
    ELSE
       IF (l_return_status = TRUE) THEN
           -----------------------------------------------------------------
           l_debug_info := 'Call import_document_with_tax service';
           IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
           END IF;
           --Print(l_api_name,l_debug_info);
           -----------------------------------------------------------------
	   zx_api_pub.import_document_with_tax(
	          p_api_version      => 1.0,
	          p_init_msg_list    => FND_API.G_TRUE,
	          p_commit           => FND_API.G_FALSE,
	          p_validation_level => FND_API.G_VALID_LEVEL_FULL,
	          x_return_status    => l_return_status_service,
	          x_msg_count        => l_msg_count,
	          x_msg_data         => l_msg_data);
       END IF;
    END IF;


    IF (l_return_status_service = 'S') THEN
        -----------------------------------------------------------------
        l_debug_info := 'Handle return of tax lines';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        --Print(l_api_name,l_debug_info);
        -----------------------------------------------------------------
        OPEN C_SELECTED_INVOICES;
        LOOP
           FETCH C_SELECTED_INVOICES
            BULK COLLECT INTO AP_ETAX_PKG.G_INV_ID_LIST,
	                      AP_ETAX_PKG.G_EVNT_CLS_LIST
	   LIMIT AP_ETAX_PKG.G_BATCH_LIMIT;

           --Bug9436217

           IF P_Invoice_Id IS NULL THEN

           --Bug9436217


              EXIT WHEN (C_SELECTED_INVOICES%NOTFOUND
                         AND AP_ETAX_PKG.G_INV_ID_LIST.COUNT <= 0);
           ELSE
              EXIT WHEN AP_ETAX_PKG.G_INV_ID_LIST.COUNT <= 0;
           END IF;

           FOR i IN AP_ETAX_PKG.G_INV_ID_LIST.FIRST..AP_ETAX_PKG.G_INV_ID_LIST.LAST
           LOOP
               OPEN  Invoice_Header(ap_etax_pkg.g_inv_id_list(i));
               FETCH Invoice_Header INTO l_inv_header_rec;
               CLOSE Invoice_Header;

               IF NOT(AP_ETAX_SERVICES_PKG.Update_AP(
		                P_Invoice_header_rec => l_inv_header_rec,
		                P_Calling_Mode       => P_Calling_Mode,
		                P_All_Error_Messages => P_All_Error_Messages,
		                P_Error_Code         => P_error_code,
		                P_Calling_Sequence   => l_curr_calling_sequence)) THEN

                   l_return_status := FALSE;
               END IF;
           END LOOP;
           AP_ETAX_PKG.G_INV_ID_LIST.DELETE;
           AP_ETAX_PKG.G_EVNT_CLS_LIST.DELETE;
        END LOOP;
        CLOSE C_SELECTED_INVOICES;

    ELSE
        -----------------------------------------------------------------
        l_debug_info := 'Handle errors returned by API';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        --Print(l_api_name,l_debug_info);
        -----------------------------------------------------------------
        l_return_status := FALSE;

        IF NOT(AP_ETAX_UTILITY_PKG.Return_Error_Messages(
	               P_All_Error_Messages  => P_All_Error_Messages,
	               P_Msg_Count           => l_msg_count,
	               P_Msg_Data            => l_msg_data,
	               P_Error_Code          => P_Error_Code,
	               P_Calling_Sequence    => l_curr_calling_sequence)) THEN
            NULL;
        END IF;
	    /*Start of Bug 16842904*/
            IF((P_Error_Code is NULL) AND (l_gt_error is not NULL)) THEN
	       P_Error_Code := l_gt_error;
	    END IF;
	    /*End of Bug 16842904*/
    END IF;

    AP_ETAX_PKG.G_INV_ID_LIST.DELETE;
    AP_ETAX_PKG.G_EVNT_CLS_LIST.DELETE;
    g_manual_tax_lines := null; --bug 16656238

    RETURN l_return_status;

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Id = '||P_Invoice_Id||
          ' P_Calling_Mode ='||P_Calling_Mode||
          ' P_Error_Code = '||P_Error_Code||
          ' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;

  END Calculate;

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
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN
  IS

    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);

    l_return_status_service       VARCHAR2(4000);
    l_msg_count                   NUMBER;
    l_msg_data                    VARCHAR2(4000);
    l_msg                         VARCHAR2(4000);

    l_return_status               BOOLEAN := TRUE;
    l_inv_header_rec             ap_invoices_all%ROWTYPE;

    CURSOR Invoice_Header IS
    SELECT *
      FROM ap_invoices_all
     WHERE invoice_id = P_Invoice_Id;

    CURSOR Invoice_Lines (c_invoice_id NUMBER) IS
    SELECT *
      FROM ap_invoice_lines_all
     WHERE invoice_id = c_invoice_id
       AND line_type_lookup_code NOT IN ('TAX', 'AWT');

    l_event_class_code           zx_trx_headers_gt.event_class_code%TYPE;
    l_event_type_code            zx_trx_headers_gt.event_type_code%TYPE;

    l_api_name                    CONSTANT VARCHAR2(100) := 'Calculate_Import';
    l_gt_error                    VARCHAR2(4000);     /*Bug 16842904*/
  BEGIN


    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.Calculate_Import<-' ||
                               P_calling_sequence;

    -----------------------------------------------------------------
    l_debug_info := 'Step 1: Populating invoice header local record';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    -- This call is included to get the data required to call the MC API
    -- and to call Update_AP if the call to the eTax service is succesfull

    BEGIN
      OPEN Invoice_Header;
      FETCH Invoice_Header INTO l_inv_header_rec;
      CLOSE Invoice_Header;
    END;

    --BUG 16656238
    -----------------------------------------------------------------
    l_debug_info := 'Step 1.5: deleting the GT tbls data to populate
                     for actual invoice in Calculate_Import for invoice: '||P_Invoice_Id;
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    DELETE FROM ZX_TRX_HEADERS_GT;
    DELETE FROM ZX_TRANSACTION_LINES_GT;
    DELETE FROM ZX_IMPORT_TAX_LINES_GT;
    DELETE FROM ZX_TRX_TAX_LINK_GT;

    /*
    -----------------------------------------------------------------
    l_debug_info := 'Step 2: Update trx_id in header';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    --Print(l_api_name, l_debug_info);
    -----------------------------------------------------------------
    UPDATE zx_trx_headers_gt
       SET trx_id = P_Invoice_Id
     WHERE application_id   = AP_ETAX_PKG.AP_APPLICATION_ID
       AND entity_code      = AP_ETAX_PKG.AP_ENTITY_CODE
       AND event_class_code IN (AP_ETAX_PKG.AP_INV_EVENT_CLASS_CODE,
                                AP_ETAX_PKG.AP_PP_EVENT_CLASS_CODE,
                                AP_ETAX_PKG.AP_ER_EVENT_CLASS_CODE)
       AND trx_id = P_Interface_Invoice_Id;
   */ --commented for bug 16656238

  -- if condition commented bug 16656238
    -- IF SQL%ROWCOUNT = 0 THEN

           -----------------------------------------------------------------
           l_debug_info := 'Reset Tax Calculation Flag';
           IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
           END IF;
           --Print(l_api_name, l_debug_info);
           -----------------------------------------------------------------
           UPDATE ap_invoice_lines_all ail
              SET ail.tax_already_calculated_flag = NULL
            WHERE ail.invoice_id = p_invoice_id
              AND ail.line_type_lookup_code NOT IN ('TAX', 'AWT')
              AND NVL(ail.tax_already_calculated_flag, 'N') = 'Y';

	   -- 1. validate_default_import is called during import. This populates
	   --    zx_trx_headers_gt and zx_transaction_lines_gt for validation of
	   --    the taxable lines.
	   -- 2. During import of invoices matched to complex work purchase orders,
	   --    matching will recoup prepayments and calculate tax on it. This
	   --    would have purged zx_trx_headers_gt and zx_transaction_lines_gt.
           -- 3. In this case, the staging table will need to repopulated.
           --    Parameter P_eTax_Already_called_flag must be passed as 'Y'
	   --    to ensure document level event type is passed to eTax
           --    as 'STANDARD UPDATED'.
	   -- 4. Use Case is importing ERS invoices matched to complex work
           --    purchase orders with paid advances/prepayments.

	   -----------------------------------------------------------------
	   l_debug_info := 'Populate Headers';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
	   --Print(l_api_name, l_debug_info);
	   -----------------------------------------------------------------

           IF NOT(AP_ETAX_SERVICES_PKG.Populate_Headers_GT(
                      P_Invoice_Header_Rec         => l_inv_header_rec,
                      P_Calling_Mode               => 'CALCULATE',
                      P_eTax_Already_called_flag   => 'Y',
                      P_Event_Class_Code           => l_event_class_code,
                      P_Event_Type_Code            => l_event_type_code,
                      P_Error_Code                 => P_error_code,
                      P_Calling_Sequence           => l_curr_calling_sequence )) THEN

               l_return_status := FALSE;
           END IF;

           IF (l_return_status = TRUE)  THEN

               OPEN  Invoice_Lines (p_invoice_id);
               FETCH Invoice_Lines
               BULK  COLLECT INTO l_inv_line_list;
               CLOSE Invoice_Lines;

               -------------------------------------------------------------------
	           l_debug_info := 'Cache Line Defaults';
               IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                  FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
               END IF;
               --Print(l_api_name, l_debug_info);
	           -------------------------------------------------------------------
               IF l_inv_header_rec.invoice_type_lookup_code = 'PAYMENT REQUEST' THEN  /* if
                  condition for bug 5967914 as we need tp pass party_site_id instead of
                  vendor_site_id if invoice_type_lookup_code ='PAYMENT REQUEST' */
                 l_payment_request_flag :='Y';  -- for bug 5967914
	              Cache_Line_Defaults
	               ( p_org_id           => l_inv_header_rec.org_id
	                ,p_vendor_site_id   => l_inv_header_rec.party_site_id
	                ,p_calling_sequence => l_curr_calling_sequence);
               ELSE
                 l_payment_request_flag :='N';  -- for bug 5967914
               	  Cache_Line_Defaults
	               ( p_org_id           => l_inv_header_rec.org_id
	                ,p_vendor_site_id   => l_inv_header_rec.vendor_site_id
	                ,p_calling_sequence => l_curr_calling_sequence);
             END IF;

               -----------------------------------------------------------------
               l_debug_info := 'Populate Lines';
               IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                   FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
               END IF;
               --Print(l_api_name, l_debug_info);
               -----------------------------------------------------------------

               IF NOT(AP_ETAX_SERVICES_PKG.Populate_Lines_GT(
                                P_Invoice_Header_Rec      => l_inv_header_rec,
                                P_Calling_Mode            => 'CALCULATE',
                                P_Event_Class_Code        => l_event_class_code,
                                P_Error_Code              => P_error_code,
                                P_Calling_Sequence        => l_curr_calling_sequence )) THEN

                  l_return_status := FALSE;
		  l_gt_error  := P_error_code;   /*Bug 16842904*/
               END IF;
           END IF;

   /* ELSE

      -----------------------------------------------------------------
      l_debug_info := 'Step 3: Update trx_id in Lines';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------
      UPDATE zx_transaction_lines_gt
         SET trx_id = P_Invoice_Id
       WHERE application_id   = AP_ETAX_PKG.AP_APPLICATION_ID
         AND entity_code      = AP_ETAX_PKG.AP_ENTITY_CODE
         AND event_class_code IN (AP_ETAX_PKG.AP_INV_EVENT_CLASS_CODE,
                                  AP_ETAX_PKG.AP_PP_EVENT_CLASS_CODE,
                                  AP_ETAX_PKG.AP_ER_EVENT_CLASS_CODE)
         AND trx_id = P_Interface_Invoice_Id;

    END IF;
    */ --bug 16656238

	/* bug 16656238
    -------------------------------------------------------------------
    l_debug_info := 'Step 4: Get event class code';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Class_Code(
      P_Invoice_Type_Lookup_Code => l_inv_header_rec.invoice_type_lookup_code,
      P_Event_Class_Code         => l_event_class_code,
      P_error_code               => p_error_code,
      P_calling_sequence         => l_curr_calling_sequence)) THEN

      l_return_status := FALSE;

    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 5: Get event type code';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF (l_return_status = TRUE) THEN
      IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Type_Code(
        P_Event_Class_Code          => l_event_class_code,
        P_Calling_Mode              => P_Calling_Mode,
        P_eTax_Already_called_flag  => NULL,
        P_Event_Type_Code           => l_event_type_Code,
        P_Error_Code                => P_error_code,
        P_Calling_Sequence          => l_curr_calling_sequence)) THEN

        l_return_status := FALSE;
      END IF;
    END IF;
    */ --bug 16656238


    IF (l_return_status = TRUE) THEN

      -----------------------------------------------------------------
      l_debug_info := 'Step 7: Call calculate_tax service';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      --Print(l_api_name,l_debug_info);
      -----------------------------------------------------------------
      zx_api_pub.calculate_tax(
        p_api_version      => 1.0,
        p_init_msg_list    => FND_API.G_TRUE,
        p_commit           => FND_API.G_FALSE,
        p_validation_level => FND_API.G_VALID_LEVEL_FULL,
        x_return_status    => l_return_status_service,
        x_msg_count        => l_msg_count,
        x_msg_data         => l_msg_data);

    END IF;

    IF (l_return_status_service = 'S') THEN

       -----------------------------------------------------------------
       l_debug_info := 'Step 8: Handle return of tax lines';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
       -----------------------------------------------------------------
       IF NOT(AP_ETAX_SERVICES_PKG.Update_AP(
                P_Invoice_header_rec => l_inv_header_rec,
                P_Calling_Mode       => P_Calling_Mode,
                P_All_Error_Messages => P_All_Error_Messages,
                P_Error_Code         => P_error_code,
                P_Calling_Sequence   => l_curr_calling_sequence)) THEN

          l_return_status := FALSE;
       END IF;

    ELSE  -- handle errors

      -----------------------------------------------------------------
      l_debug_info := 'Step 9: Handle errors returned by API';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------
      l_return_status := FALSE;

      IF NOT(AP_ETAX_UTILITY_PKG.Return_Error_Messages(
               P_All_Error_Messages  => P_All_Error_Messages,
               P_Msg_Count           => l_msg_count,
               P_Msg_Data            => l_msg_data,
               P_Error_Code          => P_Error_Code,
               P_Calling_Sequence    => l_curr_calling_sequence)) THEN
            NULL;
      END IF;
           /*Start of Bug 16842904*/
            IF((P_Error_Code is NULL) AND (l_gt_error is not NULL)) THEN
	       P_Error_Code := l_gt_error;
	    END IF;
	    /*End of Bug 16842904*/

    END IF;

    RETURN l_return_status;

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Id = '||P_Invoice_Id||
          ' P_Calling_Mode ='||P_Calling_Mode||
          ' P_Error_Code = '||P_Error_Code||
          ' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;

  END Calculate_Import;

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
 |    29-DEC-2003   SYIDNER        Use of new function to validate if tax was
 |                                 already distributed for the invoice.  Function
 |                                 created in the ap_etax_utility_pkg.
 |
 *============================================================================*/

  FUNCTION Distribute(
             P_Invoice_id              IN NUMBER,
             P_Line_Number             IN NUMBER,
             P_Calling_Mode            IN VARCHAR2,
             P_All_Error_Messages      IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN IS

    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);
    l_api_name                   CONSTANT VARCHAR2(100) := 'Distribute';

    l_inv_header_rec             ap_invoices_all%ROWTYPE;
    l_event_class_code           zx_trx_headers_gt.event_class_code%TYPE;
    l_event_type_code            zx_trx_headers_gt.event_type_code%TYPE;

    l_return_status_service       VARCHAR2(4000);
    l_msg_count                   NUMBER;
    l_msg_data                    VARCHAR2(4000);
    l_msg                         VARCHAR2(4000);

    l_tax_already_distributed     VARCHAR2(1);
    l_return_status               BOOLEAN := TRUE;

    l_tax_only_invoice            NUMBER := 0;  --Bug7110987

    --Bug 7413378
    call_determine_recovery_flag  BOOLEAN := FALSE;

   CURSOR Invoice_Header (c_invoice_id NUMBER) IS
    SELECT ai.*
      FROM ap_invoices_all ai,
	   ap_system_parameters_all asp --Bug14779241
     WHERE ai.invoice_id = c_invoice_id
	   AND asp.org_id = ai.org_id /* Bug14779241: Start */
	   AND ((asp.base_currency_code = ai.invoice_currency_code) OR
               (asp.base_currency_code <> ai.invoice_currency_code AND
               ai.exchange_rate IS NOT NULL)); /* Bug14779241: End */

    CURSOR Invoice_Dists (c_invoice_id NUMBER) IS
    SELECT aid.*
      FROM ap_invoice_lines_all ail,
           ap_invoice_distributions_all aid,
           ap_invoices_all ai , --Bug14779241
	   ap_system_parameters_all asp  --Bug14779241
     WHERE ail.invoice_id  = aid.invoice_id
       AND ail.line_number = aid.invoice_line_number
       AND ail.invoice_id  = c_invoice_id
       AND ai.invoice_id = ail.invoice_id /* Bug14779241: Start */
       AND asp.org_id = ai.org_id
       AND ((asp.base_currency_code = ai.invoice_currency_code) OR
           (asp.base_currency_code <> ai.invoice_currency_code AND
           ai.exchange_rate IS NOT NULL)) /* Bug14779241: End */
       AND (aid.line_type_lookup_code NOT IN
           ('AWT', 'REC_TAX', 'NONREC_TAX', 'TRV', 'TERV', 'TIPV') OR
           (ail.line_type_lookup_code = 'TAX'
            AND aid.charge_applicable_to_dist_id IS NULL
            AND ail.summary_tax_line_id IS NOT NULL
            AND aid.detail_tax_dist_id IS NOT NULL)) --Bug9494315
       AND (aid.line_type_lookup_code <> 'RETAINAGE'
	    or (aid.line_type_lookup_code = 'RETAINAGE'
	        and ail.line_type_lookup_code = 'RETAINAGE RELEASE'))
       AND (aid.line_type_lookup_code <> 'RETROACCRUAL' OR
           (aid.line_type_lookup_code = 'RETROACCRUAL' AND dist_match_type ='PO_PRICE_ADJUSTMENT'))   --Bug10416960
       AND (related_id IS NULL
            or related_id = invoice_distribution_id)
       AND (aid.prepay_distribution_id IS NULL
            or (aid.prepay_distribution_id IS NOT NULL
                and ail.line_type_lookup_code = 'PREPAY'))
       AND ((nvl(ail.discarded_flag, 'N') <> 'Y' AND nvl(ail.cancelled_flag, 'N') <> 'Y') --Bug8811102
            OR (ail.line_type_lookup_code = 'TAX'  AND aid.reversal_flag IS NULL)) --Bug9494315
       AND p_calling_mode <> 'DISTRIBUTE RECOUP'
       AND   (NVL(aid.reversal_flag,'N') <> 'Y') -- bug 12419997 --Bug14383132
    UNION
    SELECT aid.*
      FROM ap_invoice_lines_all ail,
           ap_invoice_distributions_all aid,
           ap_invoices_all ai,  --Bug14779241
	   ap_system_parameters_all asp  --Bug14779241
     WHERE ail.invoice_id  = aid.invoice_id
       AND ail.line_number = aid.invoice_line_number
       AND ail.invoice_id  = c_invoice_id
       AND ai.invoice_id = ail.invoice_id /* Bug14779241: Start */
       AND asp.org_id = ai.org_id
       AND ((asp.base_currency_code = ai.invoice_currency_code) OR
           (asp.base_currency_code <> ai.invoice_currency_code AND
           ai.exchange_rate IS NOT NULL)) /* Bug14779241: End */
       AND ail.line_type_lookup_code  <> 'PREPAY'
       AND aid.line_type_lookup_code  =  'PREPAY'
       AND aid.prepay_distribution_id IS NOT NULL
       AND p_calling_mode = 'DISTRIBUTE RECOUP'
       AND   (NVL(aid.reversal_flag,'N') <> 'Y') -- bug 12419997  --Bug14383132
	     ;

    -- The plsql table will include the primary distribution, but the amount
    -- will be modified in the populate_distributions_gt function to add the
    -- IPV and ERV amounts if they exist.


    -- If the API is called to distribute only 1 taxable line, the following
    -- cursor will be used
    CURSOR Invoice_Dist (c_invoice_id NUMBER, c_line_number NUMBER) IS
    SELECT aid.*
      FROM ap_invoice_lines_all ail,
           ap_invoice_distributions_all aid,
           ap_invoices_all ai,  --Bug14779241
	   ap_system_parameters_all asp  --Bug14779241
     WHERE ail.invoice_id  = aid.invoice_id
       AND ail.line_number = aid.invoice_line_number
       AND ail.invoice_id  = c_invoice_id
       AND ail.line_number = c_line_number
       AND ai.invoice_id = ail.invoice_id /* Bug14779241: Start */
       AND asp.org_id = ai.org_id
       AND ((asp.base_currency_code = ai.invoice_currency_code) OR
           (asp.base_currency_code <> ai.invoice_currency_code AND
           ai.exchange_rate IS NOT NULL)) /* Bug14779241: End */
       AND (aid.line_type_lookup_code NOT IN
           ('AWT', 'REC_TAX', 'NONREC_TAX', 'TRV', 'TERV', 'TIPV') OR
           (ail.line_type_lookup_code = 'TAX'
            AND aid.charge_applicable_to_dist_id IS NULL
            AND ail.summary_tax_line_id IS NOT NULL
            AND aid.detail_tax_dist_id IS NOT NULL))  --Bug9494315
       AND (aid.line_type_lookup_code <> 'RETROACCRUAL' OR
           (aid.line_type_lookup_code = 'RETROACCRUAL' AND dist_match_type ='PO_PRICE_ADJUSTMENT'))  --Bug10416960
       AND (related_id IS NULL
            or related_id = invoice_distribution_id)
       AND (aid.prepay_distribution_id IS NULL
            or (aid.prepay_distribution_id IS NOT NULL
                and ail.line_type_lookup_code = 'PREPAY'))
       AND ((nvl(ail.discarded_flag, 'N') <> 'Y' AND nvl(ail.cancelled_flag, 'N') <> 'Y') --Bug8811102
            OR (ail.line_type_lookup_code = 'TAX'  AND aid.reversal_flag IS NULL)) --Bug9494315
       AND p_calling_mode <> 'DISTRIBUTE RECOUP'
       AND   (NVL(aid.reversal_flag,'N') <> 'Y') -- bug 12419997  --Bug14383132
    UNION
    SELECT aid.*
      FROM ap_invoice_lines_all ail,
           ap_invoice_distributions_all aid,
	   ap_invoices_all ai,  --Bug14779241
	   ap_system_parameters_all asp  --Bug14779241
     WHERE ail.invoice_id  = aid.invoice_id
       AND ail.line_number = aid.invoice_line_number
       AND ail.invoice_id  = c_invoice_id
       AND ail.line_number = c_line_number
       AND ai.invoice_id = ail.invoice_id /* Bug14779241: Start */
       AND asp.org_id = ai.org_id
       AND ((asp.base_currency_code = ai.invoice_currency_code) OR
           (asp.base_currency_code <> ai.invoice_currency_code AND
           ai.exchange_rate IS NOT NULL)) /* Bug14779241: End */
       AND ail.line_type_lookup_code  <> 'PREPAY'
       AND aid.line_type_lookup_code  =  'PREPAY'
       AND aid.prepay_distribution_id IS NOT NULL
       AND p_calling_mode = 'DISTRIBUTE RECOUP'
       AND   (NVL(aid.reversal_flag,'N') <> 'Y') -- bug 12419997  --Bug14383132
	     ;


    CURSOR c_selected_invoices IS
    SELECT trx_id, event_class_code
      FROM zx_trx_headers_gt
     WHERE application_id   =  ap_etax_pkg.ap_application_id
       AND entity_code      =  ap_etax_pkg.ap_entity_code
       AND event_class_code IN (ap_etax_pkg.ap_inv_event_class_code,
                                ap_etax_pkg.ap_pp_event_class_code,
                                ap_etax_pkg.ap_er_event_class_code);
    --ER CHANGES 6772098
    --Bug6678578 START
    /* bug 7569660 modified the below two cursors added a new attribute discarded_flag */
    /*
    CURSOR c_included_tax_amounts (c_invoice_id NUMBER) IS
    SELECT amount,
	       NVL(included_tax_amount,0) included_tax_amount,
		   line_number,
           (NVL(total_rec_tax_amt_funcl_curr,0) + NVL(total_nrec_tax_amt_funcl_curr,0)) base_included_tax_amount,
	   discarded_flag
      FROM ap_invoice_lines_all
     WHERE invoice_id =  c_invoice_id
       AND line_type_lookup_code IN ('ITEM', 'ACCRUAL', 'FREIGHT', 'MISCELLANEOUS','PREPAY')  -- bug7338249
       AND included_tax_amount IS NOT NULL ;--Bug6874234

    CURSOR c_included_tax_amount (c_invoice_id NUMBER,c_line_number NUMBER) IS
    SELECT amount,
	       NVL(included_tax_amount,0) included_tax_amount,
		   line_number,
           (NVL(total_rec_tax_amt_funcl_curr,0) + NVL(total_nrec_tax_amt_funcl_curr,0)) base_included_tax_amount,
	   discarded_flag
      FROM ap_invoice_lines_all
     WHERE invoice_id =  c_invoice_id
       AND line_number = c_line_number
       AND line_type_lookup_code IN ('ITEM', 'ACCRUAL', 'FREIGHT', 'MISCELLANEOUS','PREPAY') --bug7338249
       AND included_tax_amount IS NOT NULL ;--Bug6874234
    --Bug6678578 END
    */
    --ER CHANGES 6772098

    --Bug9436217

    l_validation_request_id ap_invoices_all.validation_request_id%TYPE;

    --Bug9436217

  BEGIN

    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.Distribute<-' ||
                               P_calling_sequence;

    --Bug9436217

    l_validation_request_id := ap_approval_pkg.g_validation_request_id;

    IF P_Invoice_id IS NOT NULL THEN

    --Bug9436217

       DELETE FROM ZX_TRX_HEADERS_GT;

       -----------------------------------------------------------------
       l_debug_info := 'Populate invoice header local record';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
       --Print(l_api_name,l_debug_info);
       -----------------------------------------------------------------
       OPEN  Invoice_Header (p_invoice_id);
       FETCH Invoice_Header INTO l_inv_header_rec;
       CLOSE Invoice_Header;

	--Bug14779241 start
           IF l_inv_header_rec.invoice_id IS NULL THEN
	    l_return_status :=  TRUE;
	    RETURN l_return_status;
	   END IF;
        --Bug14779241 end

       IF ((l_inv_header_rec.quick_credit = 'Y') OR    -- Bug 5638822
           (l_inv_header_rec.invoice_type_lookup_code IN ('AWT', 'INTEREST'))) THEN
          RETURN l_return_status;
       END IF;


       -------------------------------------------------------------------
       l_debug_info := 'Is tax already distributed for invoice';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
       --Print(l_api_name,l_debug_info);
       -------------------------------------------------------------------
       IF (AP_ETAX_UTILITY_PKG.Is_Tax_Already_Dist_Inv(
	          P_Invoice_Id           => p_invoice_id,
	          P_Calling_Sequence     => l_curr_calling_sequence)) THEN

	         l_tax_already_distributed := 'Y';
       ELSE
           l_tax_already_distributed := 'N';
       END IF;

       -----------------------------------------------------------------
       l_debug_info := 'Populate Header';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
       --Print(l_api_name,l_debug_info);
       -----------------------------------------------------------------
       IF NOT(AP_ETAX_SERVICES_PKG.Populate_Headers_GT(
		      P_Invoice_Header_Rec        => l_inv_header_rec,
		      P_Calling_Mode              => P_Calling_Mode,
		      P_eTax_Already_called_flag  => l_tax_already_distributed,
		      P_Event_Class_Code          => l_event_class_code,
		      P_Event_Type_Code           => l_event_type_code,
		      P_Error_Code                => P_error_code,
		      P_Calling_Sequence          => l_curr_calling_sequence )) THEN

           l_return_status :=  FALSE;
       END IF;

       ap_etax_pkg.g_inv_id_list(1) := l_inv_header_rec.invoice_id;


    ELSE
       -----------------------------------------------------------------
       l_debug_info := 'Batch: Bulk Populate Header';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
       --Print(l_api_name,l_debug_info);
       -----------------------------------------------------------------
       IF NOT AP_ETAX_SERVICES_PKG.Bulk_Populate_Headers_GT(
   		        p_validation_request_id => ap_approval_pkg.g_validation_request_id,
	                p_calling_mode          => p_calling_mode,
	                p_error_code            => p_error_code) THEN

           l_return_status := FALSE;
       END IF;
     END IF;

     IF g_invoices_to_process = 0 THEN
        RETURN TRUE;
     END IF;

     -----------------------------------------------------------------
     l_debug_info := 'Purge Staging Table';
     IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
     END IF;
     --Print(l_api_name,l_debug_info);
     -----------------------------------------------------------------
     DELETE FROM zx_itm_distributions_gt;

    --Bug9436217

    --Bug#11674044 modified the query to improve the performance.
    --Bug8547912: Added additional hints
     IF p_line_number IS NULL THEN
        UPDATE ap_invoice_distributions_All aid1
        /*no_unnest hints and consolidation of query for bug 11674044 */
        SET (aid1.amount, aid1.base_amount) =
            (SELECT /*+ index(aid2 AP_INVOICE_DISTRIBUTIONS_N28 ) */ aid1.amount + NVL(SUM(Nvl(amount, 0)),0)
            , aid1.base_amount + NVL(SUM(Nvl(base_amount, 0)),0)
            FROM ap_invoice_distributions_all aid2
            WHERE aid2.invoice_id = aid1.invoice_id
            AND aid2.charge_applicable_to_dist_id = aid1.invoice_distribution_id
            AND aid2.line_type_lookup_code IN ( 'REC_TAX', 'NONREC_TAX', 'TRV', 'TIPV', 'TERV' )
            AND EXISTS (SELECT /*+ NO_UNNEST index(zd ZX_REC_NREC_DIST_U1)*/ 1
                           FROM zx_rec_nrec_dist zd
                          WHERE zd.application_id = 200
                            AND zd.entity_code = 'AP_INVOICES'
                            AND zd.event_class_code IN ( 'STANDARD INVOICES', 'EXPENSE REPORTS', 'PREPAYMENT INVOICES' )
                            AND zd.trx_id = aid2.invoice_id
                            AND zd.rec_nrec_tax_dist_id = aid2.detail_tax_dist_id
                            AND Nvl(zd.inclusive_flag, 'N') = 'Y'))
         WHERE aid1.invoice_id IN (SELECT /*+ cardinality(gt 10) unnest */ DISTINCT(trx_id)
                                     FROM zx_trx_headers_gt gt
                                    WHERE application_id = 200
                                      AND entity_code = 'AP_INVOICES'
                                      AND event_class_code IN ('STANDARD INVOICES','EXPENSE REPORTS','PREPAYMENT INVOICES'))
           AND aid1.line_type_lookup_code IN ('ITEM', 'ACCRUAL', 'FREIGHT', 'MISCELLANEOUS')   --bug9314506
           AND NOT EXISTS (SELECT /*+  nl_aj */ 1
                             FROM ap_invoice_lines_all ail
                            WHERE ail.invoice_id = aid1.invoice_id
                              AND ail.line_number=aid1.invoice_line_number
                              AND NVL(ail.discarded_flag,'N') = 'Y');
     END IF;

     --Bug9436217



     OPEN C_SELECTED_INVOICES;
     LOOP
     FETCH C_SELECTED_INVOICES
        BULK COLLECT INTO AP_ETAX_PKG.G_INV_ID_LIST,
			  AP_ETAX_PKG.G_EVNT_CLS_LIST
        LIMIT AP_ETAX_PKG.G_BATCH_LIMIT;

        --Bug9436217

        IF P_Invoice_id IS NULL THEN

        --Bug9436217

           EXIT WHEN (C_SELECTED_INVOICES%NOTFOUND
                      AND AP_ETAX_PKG.G_INV_ID_LIST.COUNT <= 0);
        ELSE
           EXIT WHEN AP_ETAX_PKG.G_INV_ID_LIST.COUNT <= 0;
        END IF;

        FOR i IN AP_ETAX_PKG.G_INV_ID_LIST.FIRST.. AP_ETAX_PKG.G_INV_ID_LIST.LAST
        LOOP

        --Bug9436217

	    IF P_Invoice_id IS NULL THEN

        --Bug9436217

	      OPEN  Invoice_Header(ap_etax_pkg.g_inv_id_list(i));
	      FETCH Invoice_Header INTO l_inv_header_rec;
	      CLOSE Invoice_Header;

	      l_event_class_code := ap_etax_pkg.g_evnt_cls_list(i);

	    ELSE

          ap_etax_pkg.g_inv_id_list(1) := l_inv_header_rec.invoice_id;

        END IF;

           -----------------------------------------------------------------
           l_debug_info := 'Populate invoice distributions collection';
           IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
           END IF;
           --Print(l_api_name,l_debug_info);
           -----------------------------------------------------------------
       --ER CHANGES 6772098
       --Bug8547912: Added additional hints in the below SQL.
       IF (p_line_number IS NOT NULL) THEN

        UPDATE ap_invoice_distributions_All aid1
        /*no_unnest hints and consolidation of query for bug 11674044 */
        SET (aid1.amount, aid1.base_amount) =
            (SELECT /*+ index(aid2 AP_INVOICE_DISTRIBUTIONS_N28 ) */ aid1.amount + NVL(SUM(Nvl(amount, 0)),0)
            , aid1.base_amount + NVL(SUM(Nvl(base_amount, 0)),0)
            FROM ap_invoice_distributions_all aid2
            WHERE aid2.invoice_id =  p_invoice_id
	    AND aid2.invoice_line_number = p_line_number
            AND aid2.charge_applicable_to_dist_id = aid1.invoice_distribution_id
            AND aid2.line_type_lookup_code IN ( 'REC_TAX', 'NONREC_TAX', 'TRV', 'TIPV', 'TERV' )
            AND EXISTS (SELECT /*+ NO_UNNEST index(zd ZX_REC_NREC_DIST_U1)*/ 1
                           FROM zx_rec_nrec_dist zd
                          WHERE zd.application_id = 200
                            AND zd.entity_code = 'AP_INVOICES'
                            AND zd.event_class_code IN ( 'STANDARD INVOICES', 'EXPENSE REPORTS', 'PREPAYMENT INVOICES' )
                            AND zd.trx_id = aid2.invoice_id
                            AND zd.rec_nrec_tax_dist_id = aid2.detail_tax_dist_id
                            AND Nvl(zd.inclusive_flag, 'N') = 'Y'))
		         WHERE aid1.invoice_id =  p_invoice_id
		           AND aid1.invoice_line_number = p_line_number
		           AND aid1.line_type_lookup_code IN ('ITEM', 'ACCRUAL', 'FREIGHT', 'MISCELLANEOUS')  --bug9314506
               AND NOT EXISTS (SELECT  /*+  nl_aj */ 1   --9325964
                                 FROM ap_invoice_lines_all ail
                                WHERE ail.invoice_id = aid1.invoice_id
                                  AND ail.line_number=aid1.invoice_line_number
                                  AND NVL(ail.discarded_flag,'N') = 'Y');
	       OPEN  Invoice_Dist (p_invoice_id, p_line_number);
	       FETCH Invoice_Dist
	       BULK COLLECT INTO l_inv_dist_list;
	       CLOSE Invoice_Dist;

	       --Bug 7436274 (7413378)
	       IF (NOT (call_determine_recovery_flag)) AND ((l_inv_dist_list.count > 0) OR  TAX_ONLY_LINE_EXIST(p_invoice_id)) THEN  --Bug8811102
		      call_determine_recovery_flag := TRUE;
	       END IF;
       ELSE

          OPEN Invoice_Dists (ap_etax_pkg.g_inv_id_list(i));
	      FETCH Invoice_Dists
	      BULK COLLECT INTO l_inv_dist_list;
	      CLOSE Invoice_Dists;

	      --Bug 7413378
	      IF (NOT (call_determine_recovery_flag)) AND ((l_inv_dist_list.count > 0) OR TAX_ONLY_LINE_EXIST(l_inv_header_rec.invoice_id)) THEN  --Bug8811102
		      call_determine_recovery_flag := TRUE;
	      END IF;

          --Bug13632623 : DELETE INVOICE HEADERS DATA FROM GT WHERE NO APPLICABLE DISTS FOR PROCESSING EXIST

          IF l_inv_dist_list.count = 0 AND NOT TAX_ONLY_LINE_EXIST(l_inv_header_rec.invoice_id) THEN

             DELETE FROM zx_trx_headers_gt
              WHERE application_id   = AP_ETAX_PKG.AP_APPLICATION_ID
                AND entity_code      = AP_ETAX_PKG.AP_ENTITY_CODE
                AND event_class_code IN (AP_ETAX_PKG.AP_INV_EVENT_CLASS_CODE,
                                         AP_ETAX_PKG.AP_PP_EVENT_CLASS_CODE,
                                         AP_ETAX_PKG.AP_ER_EVENT_CLASS_CODE)
                AND trx_id = l_inv_header_rec.invoice_id;

             -----------------------------------------------------------------
     	     l_debug_info := 'DELETE INV ID '||l_inv_header_rec.invoice_id||' FROM zx_trx_headers_gt';
             IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
             END IF;
             -----------------------------------------------------------------

          END IF;

          --Bug13632623 : DELETE INVOICE HEADERS DATA FROM GT WHERE NO APPLICABLE DISTS FOR PROCESSING EXIST

      END IF;
      --ER CHANGES 6772098
	   -----------------------------------------------------------------
    	   l_debug_info := 'Populate Distributions';
           IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
           END IF;
           --Print(l_api_name,l_debug_info);
    	   -----------------------------------------------------------------
    	   IF (l_return_status = TRUE
	       and l_inv_dist_list.count > 0) THEN

	       IF NOT (AP_ETAX_SERVICES_PKG.Populate_Distributions_GT(
			        P_Invoice_Header_Rec      => l_inv_header_rec,
			        P_Calling_Mode            => P_Calling_Mode,
			        P_Event_Class_Code        => l_event_class_code,
			        P_Event_Type_Code         => l_event_type_code,
			        P_Error_Code              => P_error_code,
			        P_Calling_Sequence        => l_curr_calling_sequence )) THEN

		        l_return_status := FALSE;
	       END IF;
	   END IF;


           IF l_inv_header_rec.historical_flag = 'Y' THEN
	      -------------------------------------------------------------------
       	      l_debug_info := 'Upgrade historical invoice distributions';
              IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                 FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
              END IF;
              --Print(l_api_name,l_debug_info);
       	      -------------------------------------------------------------------
	      UPDATE /*+ ROWID (AID) */ AP_Invoice_Distributions_All AID
	      SET   (RECOVERY_RATE_CODE,
	             RECOVERY_RATE_ID,
	             RECOVERY_TYPE_CODE) =
		                       (SELECT REC.Tax_Rate_Code,
		                               REC.Tax_Rate_ID,
		                               REC.Recovery_Type_Code
		                        FROM   ZX_Rates_B RATE,
		                               ZX_Rates_B REC
		                        WHERE  RATE.Tax_Rate_ID		 = AID.Tax_Code_ID
		                        AND    RATE.Tax_Regime_Code	 = REC.Tax_Regime_Code
		                        AND    RATE.Tax			 = REC.Tax
		                        AND    RATE.Tax_Status_Code	 = REC.Tax_Status_Code
		                        AND    RATE.Content_Owner_ID	 = REC.Content_Owner_ID
		                        AND    REC.Rate_type_code	 = 'RECOVERY'
		                        AND    REC.Effective_From <= AID.Accounting_Date
		                        AND    NVL(REC.Effective_To, AID.Accounting_Date) >= AID.Accounting_Date
		                        AND    REC.Active_Flag		 = 'Y'
		                        AND    REC.Percentage_Rate	 = AID.Rec_NRec_Rate
		                        AND    REC.Tax_Rate_Code 	 = 'STANDARD-' || REC.Percentage_Rate
		                        AND    AID.Line_Type_Lookup_Code = 'REC_TAX')
             WHERE AID.invoice_id            = l_inv_header_rec.invoice_id
	       AND AID.historical_flag       = 'Y'
               AND AID.line_type_lookup_code = 'REC_TAX'
               AND AID.recovery_rate_code    Is Null
               AND AID.recovery_rate_id      Is Null
               AND AID.recovery_type_code    Is Null;
           END IF;
       END LOOP;

       AP_ETAX_PKG.G_INV_ID_LIST.DELETE;
       AP_ETAX_PKG.G_EVNT_CLS_LIST.DELETE;

    END LOOP;
    CLOSE C_SELECTED_INVOICES;

    -----------------------------------------------------------------
    l_debug_info := 'Call determine_recovery service';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    --Print(l_api_name,l_debug_info);
    -----------------------------------------------------------------
    --Bug 7413378
    --At the end of C_SELECTED_INVOICES cursor, l_inv_dist_list.count contains number of distributions
    --for the last invoice id of Invoice Batch.If last invoice has no distributions the
    --"return of tax distributions" code is not executed for any invoice of the Invoice Batch.
    --Hence removed the l_inv_dist_list.count from IF condition.
    /*IF (l_return_status = TRUE
        and l_inv_dist_list.count > 0) THEN*/
    --"determine_recovery" should be executed if atleast one invoice of the Invoice Batch has distributions.
    --Bug7110987
    IF (l_return_status = TRUE
        and (call_determine_recovery_flag = TRUE OR l_tax_only_invoice > 0)) THEN
    --Bug7110987
        zx_api_pub.determine_recovery(
 	        p_api_version      => 1.0,
	        p_init_msg_list    => FND_API.G_TRUE,
	        p_commit           => FND_API.G_FALSE,
	        p_validation_level => FND_API.G_VALID_LEVEL_FULL,
	        x_return_status    => l_return_status_service,
	        x_msg_count        => l_msg_count,
	        x_msg_data         => l_msg_data);

       IF (l_return_status_service = 'S') THEN
           -----------------------------------------------------------------
           l_debug_info := 'Handle return of tax distributions';
           IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
           END IF;
           --Print(l_api_name,l_debug_info);
           -----------------------------------------------------------------
           IF NOT(AP_ETAX_SERVICES_PKG.Update_AP(
 			P_Invoice_header_rec => l_inv_header_rec,
	                P_Calling_Mode       => P_Calling_Mode,
	                P_All_Error_Messages => P_All_Error_Messages,
	                P_Error_Code         => P_error_code,
	                P_Calling_Sequence   => l_curr_calling_sequence)) THEN

              l_return_status := FALSE;
           END IF;

       ELSE  -- handle errors

           l_return_status := FALSE;

           -----------------------------------------------------------------
           l_debug_info := 'Handle errors returned by API';
           IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
           END IF;
           --Print(l_api_name,l_debug_info);
           -----------------------------------------------------------------
           IF NOT(AP_ETAX_UTILITY_PKG.Return_Error_Messages(
			P_All_Error_Messages  => P_All_Error_Messages,
			P_Msg_Count           => l_msg_count,
			P_Msg_Data            => l_msg_data,
			P_Error_Code          => P_Error_Code,
			P_Calling_Sequence    => l_curr_calling_sequence)) THEN
              NULL;
           END IF;
       END IF;

       IF l_return_status = TRUE THEN

       OPEN C_SELECTED_INVOICES;
       LOOP
          FETCH C_SELECTED_INVOICES
          BULK COLLECT INTO AP_ETAX_PKG.G_INV_ID_LIST,
                            AP_ETAX_PKG.G_EVNT_CLS_LIST
          LIMIT AP_ETAX_PKG.G_BATCH_LIMIT;

          --Bug9436217
          IF P_Invoice_id IS NULL THEN
          --Bug9436217
             EXIT WHEN (C_SELECTED_INVOICES%NOTFOUND
                        AND AP_ETAX_PKG.G_INV_ID_LIST.COUNT <= 0);
          ELSE
             EXIT WHEN AP_ETAX_PKG.G_INV_ID_LIST.COUNT <= 0;
          END IF;

          FOR i IN AP_ETAX_PKG.G_INV_ID_LIST.FIRST.. AP_ETAX_PKG.G_INV_ID_LIST.LAST
          LOOP
            --Bug9436217
            IF P_Invoice_id IS NULL THEN
            --Bug9436217
                OPEN  Invoice_Header (ap_etax_pkg.g_inv_id_list(i));
                FETCH Invoice_Header
                INTO  l_inv_header_rec;
                CLOSE Invoice_Header;
             END IF;

             -----------------------------------------------------------------
             l_debug_info := 'Update Invoice Distributions';
             IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
             END IF;
             --Print(l_api_name,l_debug_info);
             -----------------------------------------------------------------
             IF NOT(AP_ETAX_SERVICES_PKG.Update_Distributions(
	                        P_Invoice_header_rec => l_inv_header_rec,
	                        P_Calling_Mode       => P_Calling_Mode,
	                        P_All_Error_Messages => P_All_Error_Messages,
	                        P_Error_Code         => P_error_code,
	                        P_Calling_Sequence   => l_curr_calling_sequence)) THEN

	         l_return_status := FALSE;
	     END IF;
	  END LOOP;
          AP_ETAX_PKG.G_INV_ID_LIST.DELETE;
          AP_ETAX_PKG.G_EVNT_CLS_LIST.DELETE;
      END LOOP;
      CLOSE C_SELECTED_INVOICES;

      END IF;

      AP_ETAX_PKG.G_INV_ID_LIST.DELETE;
      AP_ETAX_PKG.G_EVNT_CLS_LIST.DELETE;

    END IF;

    RETURN l_return_status;

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Id = '||P_Invoice_Id||
          ' P_Calling_Mode ='||P_Calling_Mode||
          ' P_Error_Code = '||P_Error_Code||
          ' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;

  END Distribute;

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
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN IS

    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);
    l_event_class_code
      zx_trx_headers_gt.event_class_code%TYPE;
    l_event_type_code
      zx_trx_headers_gt.event_type_code%TYPE;

    l_return_status_service       VARCHAR2(4000);
    l_msg_count                   NUMBER;
    l_msg_data                    VARCHAR2(4000);
    l_msg                         VARCHAR2(4000);
    l_return_status               BOOLEAN := TRUE;

    l_inv_header_rec             ap_invoices_all%ROWTYPE;
    l_invoice_id                 ap_invoices_all.invoice_id%TYPE; --Bug14779241
    l_api_name                   varchar2(30) := 'Distribute_import'; -- bug 6321366
    CURSOR Invoice_Header IS
    SELECT *
      FROM ap_invoices_all
     WHERE invoice_id = P_Invoice_Id;

    CURSOR Invoice_ex_rate_check IS --Bug14779241
    SELECT ai.invoice_id
      FROM ap_invoices_all ai,
	       ap_system_parameters_all asp
     WHERE ai.invoice_id = P_Invoice_Id
	   AND asp.org_id = ai.org_id
	   AND ((asp.base_currency_code = ai.invoice_currency_code) OR
         (asp.base_currency_code <> ai.invoice_currency_code AND
          ai.exchange_rate IS NOT NULL));

  BEGIN

    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.Distribute_Import<-' ||
                               P_calling_sequence;

    --Bug14779241: Start

    BEGIN
      OPEN Invoice_ex_rate_check;
      FETCH Invoice_ex_rate_check INTO l_invoice_id;
      CLOSE Invoice_ex_rate_check;
    END;

      IF l_invoice_id IS NULL THEN
	    l_return_status :=  TRUE;
	    RETURN l_return_status;
	  END IF;
    --Bug14779241: End

    -----------------------------------------------------------------
    l_debug_info := 'Step 1: Populating invoice header local record';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    BEGIN
      OPEN Invoice_Header;
      FETCH Invoice_Header INTO l_inv_header_rec;
      CLOSE Invoice_Header;
    END;

    -- There is no need to populate the header since this service is called
    -- after the call to calculate tax only if any tax-only line is created
    -- as per the eTax cookbook, in this case there is no need to populate
    -- the distribution global temporary table.
    -----------------------------------------------------------------
    l_debug_info := 'Step 3: Call determine_recovery service';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    IF (l_return_status = TRUE) THEN
    --print(l_api_name,l_debug_info); --bug 6321366

      zx_api_pub.determine_recovery(
        p_api_version      => 1.0,
        p_init_msg_list    => FND_API.G_TRUE,
        p_commit           => FND_API.G_FALSE,
        p_validation_level => FND_API.G_VALID_LEVEL_FULL,
        x_return_status    => l_return_status_service,
        x_msg_count        => l_msg_count,
        x_msg_data         => l_msg_data);

    END IF;

    -----------------------------------------------------------------
    l_debug_info := 'Step 4: Verify return status for determine_recovery';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    IF (l_return_status_service = 'S') THEN

      -----------------------------------------------------------------
      l_debug_info := 'Step 5: Handle return of tax lines';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------
      --print(l_api_name,l_debug_info); -- bug 6321366

       IF NOT(AP_ETAX_SERVICES_PKG.Update_AP(
                P_Invoice_header_rec => l_inv_header_rec,
                P_Calling_Mode       => P_Calling_Mode,
                P_All_Error_Messages => P_All_Error_Messages,
                P_Error_Code         => P_error_code,
                P_Calling_Sequence   => l_curr_calling_sequence)) THEN

          l_return_status := FALSE;
       END IF;


    ELSE  -- handle errors
      l_return_status := FALSE;
      -----------------------------------------------------------------
      l_debug_info := 'Step 6: Handle errors returned by API';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------
      --print(l_api_name,l_debug_info); --bug 6321366

      IF NOT(AP_ETAX_UTILITY_PKG.Return_Error_Messages(
               P_All_Error_Messages  => P_All_Error_Messages,
               P_Msg_Count           => l_msg_count,
               P_Msg_Data            => l_msg_data,
               P_Error_Code          => P_Error_Code,
               P_Calling_Sequence    => l_curr_calling_sequence)) THEN
        NULL;
      END IF;

    END IF;

    RETURN l_return_status;

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Id = '||P_Invoice_Id||
          ' P_Calling_Mode ='||P_Calling_Mode||
          ' P_Error_Code = '||P_Error_Code||
          ' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;

  END Distribute_Import;

/*=============================================================================
 |  FUNCTION - Import_Interface()
 |
 |  DESCRIPTION
 |      Public function that will call the import_document_with_tax service
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
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN
  IS
    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);

    l_return_status_service       VARCHAR2(4000);
    l_msg_count                   NUMBER;
    l_msg_data                    VARCHAR2(4000);
    l_msg                         VARCHAR2(4000);

    l_event_class_code            zx_trx_headers_gt.event_class_code%TYPE;
    l_event_type_code             zx_trx_headers_gt.event_type_code%TYPE;

    l_return_status               BOOLEAN := TRUE;
    l_inv_header_rec             ap_invoices_all%ROWTYPE;
    l_api_name                   varchar2(30) := 'Import_Interface';
    l_inv_rcv_matched     VARCHAR2(1) := 'N'; --BUG 16656238

    CURSOR Invoice_Header IS
    SELECT *
      FROM ap_invoices_all
     WHERE invoice_id = P_Invoice_Id;

     --BUG 16656238
    CURSOR Invoice_Lines (c_invoice_id NUMBER) IS
    SELECT *
      FROM ap_invoice_lines_all
      WHERE invoice_id = c_invoice_id
      AND line_type_lookup_code = 'TAX'
      AND NVL(discarded_flag,'N')='N'
      AND NVL(cancelled_flag,'N')='N'
	  AND summary_tax_line_id IS NULL;

  BEGIN

    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.Import_Interface<-' ||
                               P_calling_sequence;

    -----------------------------------------------------------------
    l_debug_info := 'Step 1: Populating invoice header local record';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    BEGIN
      OPEN Invoice_Header;
      FETCH Invoice_Header INTO l_inv_header_rec;
      CLOSE Invoice_Header;
    END;
    --BUG 16656238 starts
    -----------------------------------------------------------------
    l_debug_info := 'Step 1.5: deleting the GT tbls data to populate
                     for actual invoice in Import Interface for invoice: '||P_Invoice_Id;
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    DELETE FROM ZX_TRX_HEADERS_GT;
    DELETE FROM ZX_TRANSACTION_LINES_GT;
    DELETE FROM ZX_IMPORT_TAX_LINES_GT;
    DELETE FROM ZX_TRX_TAX_LINK_GT;

    -----------------------------------------------------------------
    --bug 16656238 ends

    /* --bug 16656238
    l_debug_info := 'Step 2: Update Header P_Invoice_Id '||P_Invoice_Id;
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    BEGIN
      UPDATE zx_trx_headers_gt
         SET trx_id = P_Invoice_Id
       WHERE application_id   = AP_ETAX_PKG.AP_APPLICATION_ID
         AND entity_code      = AP_ETAX_PKG.AP_ENTITY_CODE
         AND event_class_code IN (AP_ETAX_PKG.AP_INV_EVENT_CLASS_CODE,
                                  AP_ETAX_PKG.AP_PP_EVENT_CLASS_CODE,
                                  AP_ETAX_PKG.AP_ER_EVENT_CLASS_CODE)
         AND trx_id = P_Interface_Invoice_Id;
    EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
    END;

		l_debug_info := 'Header rows updated: '||SQL%ROWCOUNT;
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
    */
    --BUG 16656238 starts
    -- IF SQL%ROWCOUNT = 0 THEN

	   -----------------------------------------------------------------
	   l_debug_info := 'Populate Headers';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
	   --Print(l_api_name, l_debug_info);
	   -----------------------------------------------------------------

           IF NOT(AP_ETAX_SERVICES_PKG.Populate_Headers_GT(
                      P_Invoice_Header_Rec         => l_inv_header_rec,
                      P_Calling_Mode               => 'CALCULATE',
                      P_eTax_Already_called_flag   => 'N',
                      P_Event_Class_Code           => l_event_class_code,
                      P_Event_Type_Code            => l_event_type_code,
                      P_Error_Code                 => P_error_code,
                      P_Calling_Sequence           => l_curr_calling_sequence )) THEN

               l_return_status := FALSE;
           END IF;

           IF (l_return_status = TRUE)  THEN

               OPEN  Invoice_Lines (p_invoice_id);
               FETCH Invoice_Lines
              -- BULK  COLLECT INTO l_inv_line_list; --commented for BUG 16656238
               BULK  COLLECT INTO l_inv_tax_list; --added for BUG 16656238
               CLOSE Invoice_Lines;

               -------------------------------------------------------------------
	           l_debug_info := 'Cache Line Defaults';
               IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                  FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
               END IF;
               --Print(l_api_name, l_debug_info);
	           -------------------------------------------------------------------
               IF l_inv_header_rec.invoice_type_lookup_code = 'PAYMENT REQUEST' THEN  /* if
                  condition for bug 5967914 as we need tp pass party_site_id instead of
                  vendor_site_id if invoice_type_lookup_code ='PAYMENT REQUEST' */
                 l_payment_request_flag :='Y';  -- for bug 5967914
	                Cache_Line_Defaults
	               ( p_org_id           => l_inv_header_rec.org_id
	                ,p_vendor_site_id   => l_inv_header_rec.party_site_id
	                ,p_calling_sequence => l_curr_calling_sequence);
               ELSE
                 l_payment_request_flag :='N';  -- for bug 5967914
               	        Cache_Line_Defaults
	               ( p_org_id           => l_inv_header_rec.org_id
	                ,p_vendor_site_id   => l_inv_header_rec.vendor_site_id
	                ,p_calling_sequence => l_curr_calling_sequence);
               END IF;

               -----------------------------------------------------------------
               l_debug_info := 'Populate Lines';
               IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                   FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
               END IF;
               --Print(l_api_name, l_debug_info);
               -----------------------------------------------------------------

             IF NOT(AP_ETAX_SERVICES_PKG.Populate_Tax_Lines_GT(
			        P_Invoice_Header_Rec      => l_inv_header_rec,
			        P_Calling_Mode            => P_Calling_Mode,
			        P_Event_Class_Code        => l_event_class_code,
			        P_Tax_only_Flag           => 'Y',
			        P_Inv_Rcv_Matched         => l_inv_rcv_matched,
			        P_Error_Code              => P_error_code,
			        P_Calling_Sequence        => l_curr_calling_sequence )) THEN

	                l_return_status := FALSE;
             END IF;
           END IF;

   /* ELSE

      -----------------------------------------------------------------
      l_debug_info := 'Step 3: Update trx_id in Lines';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------
      UPDATE zx_transaction_lines_gt
         SET trx_id = P_Invoice_Id
       WHERE application_id   = AP_ETAX_PKG.AP_APPLICATION_ID
         AND entity_code      = AP_ETAX_PKG.AP_ENTITY_CODE
         AND event_class_code IN (AP_ETAX_PKG.AP_INV_EVENT_CLASS_CODE,
                                  AP_ETAX_PKG.AP_PP_EVENT_CLASS_CODE,
                                  AP_ETAX_PKG.AP_ER_EVENT_CLASS_CODE)
         AND trx_id = P_Interface_Invoice_Id;

    -----------------------------------------------------------------
    l_debug_info := 'Step 4: Update trx_id in tax Lines';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
     BEGIN
      UPDATE zx_import_tax_lines_gt
         SET trx_id = P_Invoice_Id
       WHERE trx_id = P_Interface_Invoice_Id;
     EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
     END;


    -----------------------------------------------------------------
    l_debug_info := 'Step 5: Update trx_id in the allocation structure '||
                    'etax table';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    BEGIN
      UPDATE zx_trx_tax_link_gt
         SET trx_id = P_Invoice_Id
       WHERE trx_id = P_Interface_Invoice_Id;
    EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
    END;

    END IF;
	*/
 --END BUG 16656238
    /*  --bug 16656238
    -------------------------------------------------------------------
    l_debug_info := 'Step 6: Get event class code';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------

    IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Class_Code(
      P_Invoice_Type_Lookup_Code => l_inv_header_rec.invoice_type_lookup_code,
      P_Event_Class_Code         => l_event_class_code,
      P_error_code               => p_error_code,
      P_calling_sequence         => l_curr_calling_sequence)) THEN

      l_return_status := FALSE;

    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 7: Get event type code';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------

    IF (l_return_status = TRUE) THEN
      IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Type_Code(
        P_Event_Class_Code          => l_event_class_code,
        P_Calling_Mode              => P_Calling_Mode,
        P_eTax_Already_called_flag  => NULL,
        P_Event_Type_Code           => l_event_type_Code,
        P_Error_Code                => P_error_code,
        P_Calling_Sequence          => l_curr_calling_sequence)) THEN

        l_return_status := FALSE;
      END IF;
    END IF;
    */
    -----------------------------------------------------------------
    l_debug_info := 'Step 9: Call import_document_with_tax service';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    IF ( l_return_status = TRUE ) THEN --bug 16656238

      zx_api_pub.import_document_with_tax(
        p_api_version      => 1.0,
        p_init_msg_list    => FND_API.G_TRUE,
        p_commit           => FND_API.G_FALSE,
        p_validation_level => FND_API.G_VALID_LEVEL_FULL,
        x_return_status    => l_return_status_service,
        x_msg_count        => l_msg_count,
        x_msg_data         => l_msg_data);

    END IF;

    IF (l_return_status_service = 'S') THEN

      -----------------------------------------------------------------
      l_debug_info := 'Step 10: Handle return of tax lines';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------
       IF NOT(AP_ETAX_SERVICES_PKG.Update_AP(
                P_Invoice_header_rec => l_inv_header_rec,
                P_Calling_Mode       => P_Calling_Mode,
                P_All_Error_Messages => P_All_Error_Messages,
                P_Error_Code         => P_error_code,
                P_Calling_Sequence   => l_curr_calling_sequence)) THEN

          l_return_status := FALSE;
       END IF;

    ELSE  -- handle errors

      -----------------------------------------------------------------
      l_debug_info := 'Step 11: Handle errors returned by API';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------
      l_return_status := FALSE;

      IF NOT(AP_ETAX_UTILITY_PKG.Return_Error_Messages(
               P_All_Error_Messages  => P_All_Error_Messages,
               P_Msg_Count           => l_msg_count,
               P_Msg_Data            => l_msg_data,
               P_Error_Code          => P_Error_Code,
               P_Calling_Sequence    => l_curr_calling_sequence)) THEN
        NULL;
      END IF;

    END IF;

   RETURN l_return_status;

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Id = '||P_Invoice_Id||
          ' P_Calling_Mode ='||P_Calling_Mode||
          ' P_Error_Code = '||P_Error_Code||
          ' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;
  END Import_Interface;

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
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN
  IS

    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);

    l_inv_header_rec             ap_invoices_all%ROWTYPE;
    l_credited_inv_rec           ap_invoices_all%ROWTYPE;

    l_event_class_code_crediting zx_trx_headers_gt.event_class_code%TYPE;
    l_event_class_code_credited  zx_trx_headers_gt.event_class_code%TYPE;

    l_tax_already_distributed     VARCHAR2(1);
    l_event_class_code           zx_trx_headers_gt.event_class_code%TYPE;
    l_event_type_code            zx_trx_headers_gt.event_type_code%TYPE;

    CURSOR Crediting_Inv_Header IS
    SELECT *
      FROM ap_invoices_all
     WHERE invoice_id = P_Invoice_Id
       AND quick_credit = 'Y'
       AND credited_invoice_id IS NOT NULL;

    CURSOR Credited_Inv_Header(c_credited_inv NUMBER) IS
    SELECT *
      FROM ap_invoices_all
     WHERE invoice_id = c_credited_inv;

    l_return_status_service       VARCHAR2(4000);
    l_msg_count                   NUMBER;
    l_msg_data                    VARCHAR2(4000);
    l_msg                         VARCHAR2(4000);

    l_return_status               BOOLEAN := TRUE;

    l_api_name                    CONSTANT VARCHAR2(100) := 'Reverse_Invoice';

  BEGIN
    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.Reverse_Invoice<-' ||
                               P_calling_sequence;

    -----------------------------------------------------------------
    l_debug_info := 'Step 1: Populating crediting invoice header';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    BEGIN
      OPEN Crediting_Inv_Header;
      FETCH Crediting_Inv_Header INTO l_inv_header_rec;
      CLOSE Crediting_Inv_Header;
    END;

    -----------------------------------------------------------------
    l_debug_info := 'Step 2: Populating credited invoice header';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    BEGIN
      OPEN Credited_Inv_Header(l_inv_header_rec.credited_invoice_id);
      FETCH Credited_Inv_Header INTO l_credited_inv_rec;
      CLOSE Credited_Inv_Header;
    END;

    IF NOT (tax_distributions_exist(p_invoice_id  => l_credited_inv_rec.invoice_id)
       OR self_assess_tax_dist_exist (p_invoice_id=>l_credited_inv_rec.invoice_id)) THEN /*Bug 16762912*/
       RETURN l_return_status;
    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 3: Get crediting invoice event class code';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------

    IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Class_Code(
      P_Invoice_Type_Lookup_Code => l_inv_header_rec.invoice_type_lookup_code,
      P_Event_Class_Code         => l_event_class_code_crediting,
      P_error_code               => P_error_code,
      P_calling_sequence         => l_curr_calling_sequence)) THEN

      l_return_status := FALSE;

    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 4: Get credited invoice event class code';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF (l_return_status = TRUE) THEN
      IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Class_Code(
        P_Invoice_Type_Lookup_Code => l_credited_inv_rec.invoice_type_lookup_code,
        P_Event_Class_Code         => l_event_class_code_credited,
        P_error_code               => P_error_code,
        P_calling_sequence         => l_curr_calling_sequence)) THEN

        l_return_status := FALSE;
      END IF;
    END IF;

    INSERT INTO zx_rev_trx_headers_gt(
        internal_organization_id,
        reversing_appln_id,
        reversing_entity_code,
        reversing_evnt_cls_code,
        reversing_trx_id,
        legal_entity_id,
        trx_number
    ) VALUES
	(l_inv_header_rec.org_id,
         200,
         'AP_INVOICES',
         l_event_class_code_credited,
         l_inv_header_rec.invoice_id,
         l_inv_header_rec.legal_entity_id,
         l_inv_header_rec.invoice_num);

    -----------------------------------------------------------------
    l_debug_info := 'Step 5: Populate zx_reverse_trx_lines_gt';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    IF (l_return_status = TRUE) THEN
      INSERT INTO zx_reverse_trx_lines_gt(
        internal_organization_id,
        reversing_appln_id,
        reversing_entity_code,
        reversing_evnt_cls_code,
        reversing_trx_id,
        reversing_trx_level_type,
        reversing_trx_line_id,
        reversed_appln_id,
        reversed_entity_code,
        reversed_evnt_cls_code,
        reversed_trx_id,
        reversed_trx_level_type,
        reversed_trx_line_id,
        trx_line_gl_date -- bug 9880212
      )
      SELECT
        l_inv_header_rec.org_id,        -- internal_organization_id
        200,                            -- reversing_appln_id
        'AP_INVOICES',                  -- reversing_entity_code
        l_event_class_code_crediting,   -- reversing_evnt_cls_code
        ail.invoice_id,                 -- reversing_trx_id
        'LINE',                         -- reversing_trx_level_type
        ail.line_number,                -- reversing_trx_line_id
        200,                            -- reversed_appln_id
        'AP_INVOICES',                  -- reversed_entity_code
        l_event_class_code_credited,    -- reversed_evnt_cls_code
        aic.invoice_id,                 -- reversed_trx_id
        'LINE',                         -- reversed_trx_level_type
        aic.line_number,                -- reversed_trx_line_id
        ail.accounting_date             -- trx_line_gl_date -- bug 9880212
        FROM ap_invoice_lines_all ail,
             ap_invoice_lines_all aic
       WHERE ail.invoice_id = l_inv_header_rec.invoice_id
         AND ail.line_type_lookup_code NOT IN ('TAX', 'AWT')
         AND ail.corrected_inv_id = aic.invoice_id
         AND ail.corrected_line_number = aic.line_number;


    END IF;

    -----------------------------------------------------------------
    l_debug_info := 'Step 6: Populate zx_reverse_dist_gt';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    IF (l_return_status = TRUE) THEN
      INSERT INTO zx_reverse_dist_gt(
        internal_organization_id,
        reversing_appln_id,
        reversing_entity_code,
        reversing_evnt_cls_code,
        reversing_trx_id,
        reversing_trx_level_type,
        reversing_trx_line_id,
        reversing_trx_line_dist_id,
        reversing_tax_line_id,
        reversed_appln_id,
        reversed_entity_code,
        reversed_evnt_cls_code,
        reversed_trx_id,
        reversed_trx_level_type,
        reversed_trx_line_id,
        reversed_trx_line_dist_id,
        reversed_tax_line_id
      )
      SELECT
        l_inv_header_rec.org_id,        -- internal_organization_id
        200,                            -- reversing_appln_id
        'AP_INVOICES',                  -- reversing_entity_code
        l_event_class_code_crediting,   -- reversing_evnt_cls_code
        aid.invoice_id,                 -- reversing_trx_id
        'LINE',                         -- reversing_trx_level_type
        aid.invoice_line_number,        -- reversing_trx_line_id
        aid.invoice_distribution_id,    -- reversing_trx_line_dist_id
        NULL,                           -- reversing_tax_line_id
        200,                            -- reversed_appln_id
        'AP_INVOICES',                  -- reversed_entity_code
        l_event_class_code_credited,    -- reversed_evnt_cls_code
        idc.invoice_id,                 -- reversed_trx_id
        'LINE',                         -- reversed_trx_level_type
        idc.invoice_line_number,        -- reversed_trx_line_id
        idc.invoice_distribution_id,    -- reversed_trx_line_dist_id
        NULL                            -- reversed_tax_line_id
        FROM ap_invoice_distributions_all aid,
             ap_invoice_distributions_all idc
       WHERE aid.invoice_id = l_inv_header_rec.invoice_id
         AND aid.line_type_lookup_code NOT IN
             ('AWT', 'REC_TAX', 'NONREC_TAX', 'TRV', 'TERV', 'TIPV')
         AND (aid.related_id IS NULL
              OR aid.related_id = aid.invoice_distribution_id)
         AND aid.corrected_invoice_dist_id = idc.invoice_distribution_id;

       -- this select make sure that only the primary distribution is populated
       -- in the eTax temporary table.  There is no need to summary because the
       -- amount is not included.  eTax will take the amount from the reversed
       -- tax distributions.

    END IF;

    -----------------------------------------------------------------
    l_debug_info := 'Step 7: Call reverse_document_distribution service';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    IF ( l_return_status = TRUE ) THEN

      zx_api_pub.reverse_document_distribution(
        p_api_version      => 1.0,
        p_init_msg_list    => FND_API.G_TRUE,
        p_commit           => FND_API.G_FALSE,
        p_validation_level => FND_API.G_VALID_LEVEL_FULL,
        x_return_status    => l_return_status_service,
        x_msg_count        => l_msg_count,
        x_msg_data         => l_msg_data);

    END IF;

    -----------------------------------------------------------------
    l_debug_info := 'Step 8: Verify return status';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    IF (l_return_status_service = 'S') THEN
       -----------------------------------------------------------------
       l_debug_info := 'Step 9: Handle return of tax lines and dist';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
       -----------------------------------------------------------------

       -- Tax distributions insert works off of zx_trx_headers_gt. Since
       -- reverse_document_distribution does not require this table to be
       -- populated, we are using this as a proxy to avoid maintaining two
       -- code lines.
       -------------------------------------------------------------------
       l_debug_info := 'Is tax already distributed for invoice';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
       --Print(l_api_name,l_debug_info);
       -------------------------------------------------------------------
       IF (AP_ETAX_UTILITY_PKG.Is_Tax_Already_Dist_Inv(
                  P_Invoice_Id           => p_invoice_id,
                  P_Calling_Sequence     => l_curr_calling_sequence)) THEN

           l_tax_already_distributed := 'Y';
       ELSE
           l_tax_already_distributed := 'N';
       END IF;

       -----------------------------------------------------------------
       l_debug_info := 'Populate Header';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
       --Print(l_api_name,l_debug_info);
       -----------------------------------------------------------------
       IF NOT(AP_ETAX_SERVICES_PKG.Populate_Headers_GT(
                      P_Invoice_Header_Rec        => l_inv_header_rec,
                      P_Calling_Mode              => P_Calling_Mode,
                      P_eTax_Already_called_flag  => l_tax_already_distributed,
                      P_Event_Class_Code          => l_event_class_code,
                      P_Event_Type_Code           => l_event_type_code,
                      P_Error_Code                => P_error_code,
                      P_Calling_Sequence          => l_curr_calling_sequence )) THEN

           l_return_status :=  FALSE;
       END IF;

       IF NOT(AP_ETAX_SERVICES_PKG.Update_AP(
                P_Invoice_header_rec => l_inv_header_rec,
                P_Calling_Mode       => P_Calling_Mode,
                P_All_Error_Messages => P_All_Error_Messages,
                P_Error_Code         => P_error_code,
                P_Calling_Sequence   => l_curr_calling_sequence)) THEN

          l_return_status := FALSE;
       END IF;

   ELSE  -- handle errors

      l_return_status := FALSE;
      -----------------------------------------------------------------
      l_debug_info := 'Step 10: Handle errors returned by API';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------
      l_return_status := FALSE;

      IF NOT(AP_ETAX_UTILITY_PKG.Return_Error_Messages(
               P_All_Error_Messages  => P_All_Error_Messages,
               P_Msg_Count           => l_msg_count,
               P_Msg_Data            => l_msg_data,
               P_Error_Code          => P_Error_Code,
               P_Calling_Sequence    => l_curr_calling_sequence)) THEN
        NULL;
      END IF;

    END IF;


   RETURN l_return_status;

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Id = '||P_Invoice_Id||
          ' P_Calling_Mode ='||P_Calling_Mode||
          ' P_Error_Code = '||P_Error_Code||
          ' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,sqlerrm);
      END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;

  END Reverse_Invoice;

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
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN
  IS

    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);

    l_inv_header_rec             ap_invoices_all%ROWTYPE;
    l_invoice_id                 ap_invoices_all.invoice_id%TYPE; --Bug14779241
    l_event_class_code           zx_trx_headers_gt.event_class_code%TYPE;
    l_event_type_code            zx_trx_headers_gt.event_type_code%TYPE;
    l_transaction_rec		 zx_api_pub.transaction_rec_type;


    CURSOR Invoice_Header IS
    SELECT *
      FROM ap_invoices_all
     WHERE invoice_id = P_Invoice_Id;

    CURSOR Invoice_Lines IS
    SELECT *
      FROM ap_invoice_lines_all
     WHERE invoice_id = P_Invoice_Id
       AND line_type_lookup_code NOT IN ('TAX', 'AWT');

    CURSOR Invoice_ex_rate_check IS --Bug14779241
    SELECT ai.invoice_id
      FROM ap_invoices_all ai,
	       ap_system_parameters_all asp
     WHERE ai.invoice_id = P_Invoice_Id
	   AND asp.org_id = ai.org_id
	   AND ((asp.base_currency_code = ai.invoice_currency_code) OR
         (asp.base_currency_code <> ai.invoice_currency_code AND
          ai.exchange_rate IS NOT NULL));

    l_return_status_service       VARCHAR2(4000);
    l_msg_count                   NUMBER;
    l_msg_data                    VARCHAR2(4000);
    l_msg                         VARCHAR2(4000);

    l_return_status               BOOLEAN := TRUE;
    l_success			  BOOLEAN := TRUE;

    l_api_name			  CONSTANT VARCHAR2(100) := 'Override_Tax';
    l_gt_error                    VARCHAR2(4000);    /*Bug 16842904*/

  BEGIN
    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.Override_Tax<-' ||
                               P_calling_sequence;

    IF (P_Override_Status = 'SYNCHRONIZE') THEN
      -----------------------------------------------------------------
      l_debug_info := 'Step 1: Update ap_invoice_lines_all from eTax '||
                      'repository';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------
      BEGIN
        UPDATE ap_invoice_lines_all ail
           SET
         (-- Bug 10157751 ail.description,
          ail.cancelled_flag,
          ail.last_updated_by,
          ail.last_update_login,
          ail.last_update_date,
          ail.attribute_category,
          ail.attribute1,
          ail.attribute2,
          ail.attribute3,
          ail.attribute4,
          ail.attribute5,
          ail.attribute6,
          ail.attribute7,
          ail.attribute8,
          ail.attribute9,
          ail.attribute10,
          ail.attribute11,
          ail.attribute12,
          ail.attribute13,
          ail.attribute14,
          ail.attribute15,
          ail.global_attribute_category,
          ail.global_attribute1,
          ail.global_attribute2,
          ail.global_attribute3,
          ail.global_attribute4,
          ail.global_attribute5,
          ail.global_attribute6,
          ail.global_attribute7,
          ail.global_attribute8,
          ail.global_attribute9,
          ail.global_attribute10,
          ail.global_attribute11,
          ail.global_attribute12,
          ail.global_attribute13,
          ail.global_attribute14,
          ail.global_attribute15,
          ail.global_attribute16,
          ail.global_attribute17,
          ail.global_attribute18,
          ail.global_attribute19,
          ail.global_attribute20 ) = (
          SELECT
	  /* Bug 10157751
          DECODE( ail.line_source,
		  'MANUAL LINE ENTRY', ail.description,
		  'IMPORTED'         , ail.description,
                  zls.tax_regime_code||' - '||zls.tax ), -- description : Bug 9383712 - Added DECODE
	  */
          zls.cancel_flag,                     -- cancelled_flag
          l_user_id,                           -- last_updated_by
          l_login_id,                          -- last_update_login
          l_sysdate,                           -- last_update_date
          zls.attribute_category,
          zls.attribute1,
          zls.attribute2,
          zls.attribute3,
          zls.attribute4,
          zls.attribute5,
          zls.attribute6,
          zls.attribute7,
          zls.attribute8,
          zls.attribute9,
          zls.attribute10,
          zls.attribute11,
          zls.attribute12,
          zls.attribute13,
          zls.attribute14,
          zls.attribute15,
          zls.global_attribute_category,
          zls.global_attribute1,
          zls.global_attribute2,
          zls.global_attribute3,
          zls.global_attribute4,
          zls.global_attribute5,
          zls.global_attribute6,
          zls.global_attribute7,
          zls.global_attribute8,
          zls.global_attribute9,
          zls.global_attribute10,
          zls.global_attribute11,
          zls.global_attribute12,
          zls.global_attribute13,
          zls.global_attribute14,
          zls.global_attribute15,
          zls.global_attribute16,
          zls.global_attribute17,
          zls.global_attribute18,
          zls.global_attribute19,
          zls.global_attribute20
          FROM zx_lines_summary zls
         WHERE zls.summary_tax_line_id = ail.summary_tax_line_id
           AND nvl(zls.reporting_only_flag, 'N') = 'N'
         )
         WHERE ail.invoice_id = P_Invoice_Id
           AND ail.line_type_lookup_code = 'TAX'
           AND EXISTS (SELECT ls.summary_tax_line_id
                         FROM zx_lines_summary ls
                        WHERE ls.summary_tax_line_id = ail.summary_tax_line_id
                          AND ls.trx_id = ail.invoice_id
                          AND NVL(ls.tax_amt_included_flag, 'N') = 'N'
                          AND NVL(ls.self_assessed_flag, 'N') = 'N'
                          AND nvl(ls.reporting_only_flag, 'N') = 'N');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;

        WHEN OTHERS THEN
          IF (SQLCODE <> -20001) THEN
            FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
            FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
            FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
            FND_MESSAGE.SET_TOKEN('PARAMETERS',
              ' P_Invoice_Id = '||P_Invoice_Id||
              ' P_Error_Code = '||P_Error_Code||
              ' P_Calling_Sequence = '||P_Calling_Sequence);
            FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
          END IF;

        APP_EXCEPTION.RAISE_EXCEPTION;
      END;

    ELSIF (P_Override_Status IN ('DETAIL_OVERRIDE', 'SUMMARY_OVERRIDE')) THEN
      -----------------------------------------------------------------
      l_debug_info := 'Step 2: Populating invoice header local record';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------

      BEGIN
        OPEN Invoice_Header;
        FETCH Invoice_Header INTO l_inv_header_rec;
        CLOSE Invoice_Header;
      END;

      -----------------------------------------------------------------
      l_debug_info := 'Step 3: Populating invoice lines collection';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------

      BEGIN
        OPEN Invoice_Lines;
        FETCH Invoice_Lines
        BULK COLLECT INTO l_inv_line_list;
        CLOSE Invoice_Lines;
      END;

      -----------------------------------------------------------------
      l_debug_info := 'Step 4: Populate Header';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------

      IF NOT(AP_ETAX_SERVICES_PKG.Populate_Headers_GT(
        P_Invoice_Header_Rec         => l_inv_header_rec,
        P_Calling_Mode               => P_Calling_Mode,
        P_eTax_Already_called_flag   => NULL,
        P_Event_Class_Code           => l_event_class_code,
        P_Event_Type_Code            => l_event_type_code,
        P_Error_Code                 => P_error_code,
        P_Calling_Sequence           => l_curr_calling_sequence )) THEN

        l_return_status := FALSE;
      END IF;

      -----------------------------------------------------------------
      l_debug_info := 'Purge staging table, Clear/Load Cache';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      --Print(l_api_name,l_debug_info);
      -----------------------------------------------------------------
      DELETE FROM ZX_TRANSACTION_LINES_GT;

      AP_ETAX_SERVICES_PKG.G_SITE_ATTRIBUTES.DELETE;
      AP_ETAX_SERVICES_PKG.G_ORG_ATTRIBUTES.DELETE;

             IF l_inv_header_rec.invoice_type_lookup_code = 'PAYMENT REQUEST' THEN  /* if
                  condition for bug 5967914 as we need tp pass party_site_id instead of
                  vendor_site_id if invoice_type_lookup_code ='PAYMENT REQUEST' */
                 l_payment_request_flag :='Y';  -- for bug 5967914
	         Cache_Line_Defaults
	               ( p_org_id           => l_inv_header_rec.org_id
	                ,p_vendor_site_id   => l_inv_header_rec.party_site_id
	                ,p_calling_sequence => l_curr_calling_sequence);
             ELSE
                 l_payment_request_flag :='N';  -- for bug 5967914
               	  Cache_Line_Defaults
	               ( p_org_id           => l_inv_header_rec.org_id
	                ,p_vendor_site_id   => l_inv_header_rec.vendor_site_id
	                ,p_calling_sequence => l_curr_calling_sequence);
             END IF;

      -----------------------------------------------------------------
      l_debug_info := 'Step 5: Populate Lines';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------
      IF ( l_return_status = TRUE ) THEN
        IF NOT(AP_ETAX_SERVICES_PKG.Populate_Lines_GT(
          P_Invoice_Header_Rec      => l_inv_header_rec,
          P_Calling_Mode            => P_Calling_Mode,
          P_Event_Class_Code        => l_event_class_code,
          P_Error_Code              => P_error_code,
          P_Calling_Sequence        => l_curr_calling_sequence )) THEN

          l_return_status := FALSE;
	  l_gt_error      := P_error_code;    /*Bug 16842904*/
        END IF;
      END IF;

      l_transaction_rec.internal_organization_id := l_inv_header_rec.org_id;
      l_transaction_rec.application_id		 := 200;
      l_transaction_rec.entity_code		 := 'AP_INVOICES';
      l_transaction_rec.event_class_code	 := l_event_class_code;
      l_transaction_rec.event_type_code		 := l_event_type_code;
      l_transaction_rec.trx_id			 := l_inv_header_rec.invoice_id;

      -----------------------------------------------------------------
      l_debug_info := 'Step 6: Call override_tax service';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------
      IF ( l_return_status = TRUE ) THEN

        zx_api_pub.override_tax(
          p_api_version      => 1.0,
          p_init_msg_list    => FND_API.G_TRUE,
          p_commit           => FND_API.G_FALSE,
          p_validation_level => FND_API.G_VALID_LEVEL_FULL,
          p_override_level   => P_Override_Status,
	      p_transaction_rec  => l_transaction_rec,
	      p_event_id	     => p_event_id,
          x_return_status    => l_return_status_service,
          x_msg_count        => l_msg_count,
          x_msg_data         => l_msg_data);

      END IF;

      -----------------------------------------------------------------
      l_debug_info := 'Step 7: Verify return status';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------

      IF (l_return_status_service = 'S') THEN

        -----------------------------------------------------------------
        l_debug_info := 'Step 8: Handle return of tax lines';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------
         IF NOT(AP_ETAX_SERVICES_PKG.Update_AP(
                  P_Invoice_header_rec => l_inv_header_rec,
                  P_Calling_Mode       => P_Calling_Mode,
                P_All_Error_Messages   => P_All_Error_Messages,
                  P_Error_Code         => P_error_code,
                  P_Calling_Sequence   => l_curr_calling_sequence)) THEN

            l_return_status := FALSE;
         END IF;

      ELSE  -- handle errors
        l_return_status := FALSE;
        -----------------------------------------------------------------
        l_debug_info := 'Step 9: Handle errors returned by API';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------

        IF NOT(AP_ETAX_UTILITY_PKG.Return_Error_Messages(
                 P_All_Error_Messages  => P_All_Error_Messages,
                 P_Msg_Count           => l_msg_count,
                 P_Msg_Data            => l_msg_data,
                 P_Error_Code          => P_Error_Code,
                 P_Calling_Sequence    => l_curr_calling_sequence)) THEN
            NULL;
        END IF;
	    /*Start of Bug 16842904*/
            IF((P_Error_Code is NULL) AND (l_gt_error is not NULL)) THEN
	       P_Error_Code := l_gt_error;
	    END IF;
	   /*End of Bug 16842904*/
      END IF; -- end of return_status_service

      -----------------------------------------------------------------
      l_debug_info := 'Step 10: Call Freeze Distributions';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------
      IF ( l_return_status = TRUE ) THEN -- Bug 9383712
        --Bug7592845
        IF NOT(AP_ETAX_SERVICES_PKG.Freeze_itm_Distributions(
	                  P_Invoice_Header_Rec  => l_inv_header_rec,
	                  P_Calling_Mode        => 'FREEZE DISTRIBUTIONS',
	                  P_Event_Class_Code    => l_event_class_code,
	                  P_All_Error_Messages  => P_All_Error_Messages,
	                  P_Error_Code          => P_error_code,
      	              P_Calling_Sequence    => l_curr_calling_sequence)) THEN

               l_return_status := FALSE;

        END IF;
      END IF ;

      -----------------------------------------------------------------
      l_debug_info := 'Step 11: Call Distribute';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------

	--Bug14779241: Start
	BEGIN
          OPEN Invoice_ex_rate_check;
          FETCH Invoice_ex_rate_check INTO l_invoice_id;
          CLOSE Invoice_ex_rate_check;
        END;
	--Bug14779241: End

      IF l_invoice_id IS NOT NULL THEN --Bug14779241
      IF ( l_return_status = TRUE ) THEN -- Bug 9383712
        l_success := ap_etax_pkg.calling_etax(
			P_Invoice_id         => l_inv_header_rec.invoice_id,
			P_Calling_Mode       => 'DISTRIBUTE',
			P_All_Error_Messages => P_All_Error_Messages,
			P_error_code         => P_error_code,
			P_Calling_Sequence   => l_curr_calling_sequence);

        IF (not l_success) THEN
            l_return_status := FALSE;
        END IF;
      END IF ;
      END IF;

      -----------------------------------------------------------------
      l_debug_info := 'Step 12: Update Total Tax Amount';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------
      IF ( l_return_status = TRUE ) THEN -- Bug 9383712

	--Modified below query for bug#16022947 to consider
	--Prepay lines
       	UPDATE ap_invoices_all ai
          SET (ai.total_tax_amount,
               ai.self_assessed_tax_amount) =
                   (SELECT SUM(DECODE(NVL(zls.self_assessed_flag, 'N'),
                            'N', case when exists (SELECT 'Prepay App Exists'
                                          FROM ap_invoice_lines_all prepay
                                         WHERE prepay.invoice_id = zls.trx_id
                                         AND prepay.line_type_lookup_code = 'PREPAY'
                                         AND prepay.prepay_invoice_id  = zls.applied_from_trx_id
                                         AND prepay.prepay_line_number = zls.applied_from_line_id
                                         AND prepay.invoice_includes_prepay_flag = 'Y'
                                         AND (prepay.discarded_flag is null
                                           or prepay.discarded_flag = 'N')) THEN
                                           0
                                        ELSE NVL(zls.tax_amt, 0) end,
                                       0)),
                        SUM(DECODE(NVL(zls.self_assessed_flag, 'N'),
                                   'Y', NVL(zls.tax_amt, 0),
                                    0))
                   FROM zx_lines_summary zls
            WHERE zls.application_id = 200
           AND zls.entity_code = 'AP_INVOICES'
           AND zls.event_class_code IN
              ('STANDARD INVOICES', 'PREPAYMENT INVOICES', 'EXPENSE REPORTS')
                  AND zls.trx_id   = ai.invoice_id
                  AND NVL(zls.reporting_only_flag, 'N') = 'N')
          WHERE ai.invoice_id = l_inv_header_rec.invoice_id;

     --Bug#16022947. Introduced below UPDATE to consider
     --Retro Tax amounts which will not be in ZLS tables.

      UPDATE ap_invoices_all ai
      SET ai.total_tax_amount = (nvl(ai.total_tax_amount,0) +
                                 (SELECT NVL(sum(NVL(ail.amount,0)),0)
                                  FROM ap_invoice_lines_all ail
                                  WHERE ail.invoice_id = ai.invoice_id
                                   AND line_type_lookup_code ='RETROTAX'))
      WHERE ai.invoice_id = l_inv_header_rec.invoice_id;


         --Bug9494315
        UPDATE ap_invoice_distributions_all
           SET distribution_class = 'PERMANENT'
         WHERE invoice_id = l_inv_header_rec.invoice_id
           AND distribution_class = 'CANDIDATE'
           AND line_type_lookup_code IN ('REC_TAX','NONREC_TAX','TRV','TERV','TIPV');

        --Bug9494315

        --Bug9777752

        UPDATE ap_self_assessed_tax_dist_all
           SET distribution_class = 'PERMANENT'
         WHERE invoice_id = l_inv_header_rec.invoice_id
           AND distribution_class = 'CANDIDATE'
           AND line_type_lookup_code IN ('REC_TAX','NONREC_TAX','TRV','TERV','TIPV');

        --Bug9777752

      END IF ;

   END IF;  -- end of p_override_status

   RETURN l_return_status;

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Id = '||P_Invoice_Id||
          ' P_Calling_Mode ='||P_Calling_Mode||
          ' P_Error_Code = '||P_Error_Code||
          ' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;

  END Override_Tax;


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
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN
  IS

    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);

    l_inv_header_rec             ap_invoices_all%ROWTYPE;
    l_event_class_code           zx_trx_headers_gt.event_class_code%TYPE;
    l_event_type_code            zx_trx_headers_gt.event_type_code%TYPE;

    CURSOR Invoice_Header IS
    SELECT *
      FROM ap_invoices_all
     WHERE invoice_id = P_Invoice_Id;

    l_transaction_rec             zx_api_pub.transaction_rec_type;

    l_return_status_service       VARCHAR2(4000);
    l_msg_count                   NUMBER;
    l_msg_data                    VARCHAR2(4000);
    l_msg                         VARCHAR2(4000);

    l_return_status               BOOLEAN := TRUE;
    l_api_name                  varchar2(30) := 'Override_recovery';

  BEGIN
    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.Override_Recovery<-' ||
                               P_calling_sequence;

    -----------------------------------------------------------------
    l_debug_info := 'Step 1: Populating invoice header local record';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------

    BEGIN
      OPEN Invoice_Header;
      FETCH Invoice_Header INTO l_inv_header_rec;
      CLOSE Invoice_Header;
    END;

    -------------------------------------------------------------------
    l_debug_info := 'Step 2: Get event class code';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------

    IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Class_Code(
      P_Invoice_Type_Lookup_Code => l_inv_header_rec.invoice_type_lookup_code,
      P_Event_Class_Code         => l_event_class_code,
      P_error_code               => P_error_code,
      P_calling_sequence         => l_curr_calling_sequence)) THEN

      l_return_status := FALSE;

    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 3: Get event type code';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF (l_return_status = TRUE) THEN
      IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Type_Code(
        P_Event_Class_Code          => l_event_class_code,
        P_Calling_Mode              => P_Calling_Mode,
        P_eTax_Already_called_flag  => NULL,
        P_Event_Type_Code           => l_Event_Type_Code,
        P_Error_Code                => P_error_code,
        P_Calling_Sequence          => l_curr_calling_sequence)) THEN

        l_return_status := FALSE;
      END IF;
    END IF;
/* added for 6157052 we need to populate zx_headers_gt in this case.*/
    IF NOT(AP_ETAX_SERVICES_PKG.Populate_Headers_GT(
    	      P_Invoice_Header_Rec         => l_inv_header_rec,
    	      P_Calling_Mode               => P_Calling_Mode,
    	      P_eTax_Already_called_flag   => 'Y',
    	      P_Event_Class_Code           => l_event_class_code,
    	      P_Event_Type_Code            => l_event_type_code,
    	      P_Error_Code                 => P_error_code,
	      P_Calling_Sequence           => l_curr_calling_sequence )) THEN

    	  l_return_status := FALSE;
    END IF;

--    IF (l_tax_already_calculated = 'Y') THEN
--For bug 6157052 - Commented the below call as we need to call this api when we
-- are freezing the distributions and after that we are not supposed to change
--the distributons.But here we need to change the tax distributions as we are
--changing the ecovery rate .so we need not make this callhere.
/*
        IF NOT(AP_ETAX_SERVICES_PKG.Freeze_Distributions(
                P_Invoice_Header_Rec  => l_inv_header_rec,
                P_Calling_Mode        => 'FREEZE DISTRIBUTIONS',
                P_Event_Class_Code    => l_event_class_code,
                P_All_Error_Messages  => P_All_Error_Messages,
                P_Error_Code          => P_error_code,
                P_Calling_Sequence    => l_curr_calling_sequence)) THEN

           l_return_status := FALSE;
        END IF; */
--    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 4: Populate service specific parameter';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    l_transaction_rec.internal_organization_id := l_inv_header_rec.org_id;
    l_transaction_rec.application_id           := 200;
    l_transaction_rec.entity_code              := 'AP_INVOICES';
    l_transaction_rec.event_class_code         := l_event_class_code;
    l_transaction_rec.event_type_code          := l_event_type_code;
    l_transaction_rec.trx_id                   := l_inv_header_rec.invoice_id;

    -------------------------------------------------------------------
    l_debug_info := 'Step 6: Call to override_recovery service';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF ( l_return_status = TRUE ) THEN
-- Debug messages added for 6321366
IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, l_debug_info);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'application_id: '           || l_transaction_rec.application_id);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'entity_code: ' || l_transaction_rec.entity_code);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'event_class_code: ' || l_transaction_rec.event_class_code);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'event_type_code: ' || l_transaction_rec.event_type_code);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_id: '           || l_transaction_rec.trx_id);
END IF;

      zx_api_pub.override_recovery(
        p_api_version        => 1.0,
        p_init_msg_list      => FND_API.G_TRUE,
        p_commit             => FND_API.G_FALSE,
        p_validation_level   => FND_API.G_VALID_LEVEL_FULL,
        p_transaction_rec    => l_transaction_rec,
        x_return_status      => l_return_status_service,
        x_msg_count          => l_msg_count,
        x_msg_data           => l_msg_data);

    END IF;

    -----------------------------------------------------------------
    l_debug_info := 'Step 7: Verify return status';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    IF (l_return_status_service = 'S') THEN
      -----------------------------------------------------------------
      l_debug_info := 'Step 8: Handle return of tax lines';
      -----------------------------------------------------------------
-- Debug messages added for 6321366
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, l_debug_info);
      END IF;
       IF NOT(AP_ETAX_SERVICES_PKG.Update_AP(
                P_Invoice_header_rec => l_inv_header_rec,
                P_Calling_Mode       => P_Calling_Mode,
                P_All_Error_Messages => P_All_Error_Messages,
                P_Error_Code         => P_error_code,
                P_Calling_Sequence   => l_curr_calling_sequence)) THEN

          l_return_status := FALSE;
       END IF;

    ELSE -- handle errors

      l_return_status := FALSE;
      -----------------------------------------------------------------
      l_debug_info := 'Step 9: Handle errors returned by API';
      -----------------------------------------------------------------
      -- Debug messages added for 6321366
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, l_debug_info);
      END IF;
      IF NOT(AP_ETAX_UTILITY_PKG.Return_Error_Messages(
               P_All_Error_Messages  => P_All_Error_Messages,
               P_Msg_Count           => l_msg_count,
               P_Msg_Data            => l_msg_data,
               P_Error_Code          => P_Error_Code,
               P_Calling_Sequence    => l_curr_calling_sequence)) THEN
        NULL;
      END IF;

    END IF; -- end of return_status_service

    RETURN l_return_status;

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Id = '||P_Invoice_Id||
          ' P_Calling_Mode ='||P_Calling_Mode||
          ' P_Error_Code = '||P_Error_Code||
          ' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;

  END Override_Recovery;



--Bug7592845
/*=============================================================================
 |  FUNCTION - Freeze_itm_Distributions()
 |
 |  DESCRIPTION
 |      Public function that will call the freeze_tax_distributions service.
 |      This API assumes the calling code controls the commit cycle.
 |      This function returns TRUE if the call to the service is successful.
 |      Otherwise, FALSE.
 |
 |  PARAMETERS
 |      P_Invoice_Header_Rec - Invoice record info
 |      P_Calling_Mode - calling mode.  Identifies which service to call
 |      P_Event_Class_Code - event class code for the invoice type
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
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN
IS

    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);
    l_transaction_rec            zx_api_pub.transaction_rec_type;

    l_event_type_code            zx_trx_headers_gt.event_type_code%TYPE;

    CURSOR itm_Dist IS
      SELECT encumbered_flag,
             reversal_flag,
             prepay_distribution_id,
             accrual_posted_flag,
             cash_posted_flag,
             posted_flag,
             org_id,
             pa_addition_flag,
             match_status_flag,
             corrected_invoice_dist_id,
             invoice_distribution_id,
             po_distribution_id,
             rcv_transaction_id,
             accounting_event_id,
             dist_match_type,
             amount,
             prepay_amount_remaining
        FROM ap_invoice_distributions_all
       WHERE invoice_id = p_invoice_header_rec.invoice_id
         AND line_type_lookup_code NOT IN ('REC_TAX', 'NONREC_TAX', 'TRV', 'TERV', 'TIPV');

    TYPE l_itm_dist_tab_local   IS TABLE OF itm_Dist%ROWTYPE;
    l_itm_dist_list_local 	l_itm_dist_tab_local;

    -- If related_id is equals invoice_distribution_id we are
    -- sure is the primary distribution created (not including variances)
    -- Rules applied to primary taxable distributions apply to
    -- related variances.

    l_return_status_service       VARCHAR2(4000);
    l_msg_count                   NUMBER;
    l_msg_data                    VARCHAR2(4000);
    l_msg                         VARCHAR2(4000);

    l_return_status               BOOLEAN := TRUE;
    l_freeze_dist_flag            VARCHAR2(1);

    l_po_distribution_id      ap_invoice_distributions_all.po_distribution_id%TYPE;
    l_rcv_transaction_id	  ap_invoice_distributions_all.rcv_transaction_id%TYPE;

    freeze_dist_list          ZX_API_PUB.number_tbl_type;
    freeze_dist_count         NUMBER := 0; --bug8302194


    l_api_name                CONSTANT VARCHAR2(100) := 'Freeze_Itm_Distributions';

    l_err varchar2(2000); --10140354

  BEGIN
    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.Freeze_Itm_Distributions<-' ||
                               P_calling_sequence;
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, l_curr_calling_sequence);
    END IF;

    -----------------------------------------------------------------
    l_debug_info := 'Step 1: Populating Item distributions collection';
    -----------------------------------------------------------------

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, l_debug_info);
    END IF;



    BEGIN
      OPEN Itm_Dist;
      FETCH Itm_Dist
      BULK COLLECT INTO l_itm_dist_list_local;
      CLOSE Itm_Dist;
    END;

    -------------------------------------------------------------------
    l_debug_info := 'Step 2: Get event type code';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------

    IF (l_return_status = TRUE) THEN
      IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Type_Code(
        P_Event_Class_Code          => P_event_class_code,
        P_Calling_Mode              => P_Calling_Mode,
        P_eTax_Already_called_flag  => 'Y',
        P_Event_Type_Code           => l_Event_Type_Code,
        P_Error_Code                => P_error_code,
        P_Calling_Sequence          => l_curr_calling_sequence)) THEN

        l_return_status := FALSE;
      END IF;
    END IF;

    IF (l_itm_dist_list_local.COUNT <> 0) THEN

      FOR i IN l_itm_dist_list_local.FIRST..l_itm_dist_list_local.LAST LOOP
        -- set l_freeze_dist_flag to N to initiate process
        l_freeze_dist_flag := 'N';

        -- Rules for distributions
        -----------------------------------------------------------------
        l_debug_info := 'Step 3: Item distribution is encumbered';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------
        IF (NVL(l_itm_dist_list_local(i).encumbered_flag, 'N') IN ('Y','D','W','X')) THEN

          -- possible values verified for encumbered_flag
          -- Y: Regular line, has already been successfully encumbered by AP.
          -- D: Same as Y for reversal distribution line.
          -- W: Regular line, has been encumbered in advisory mode even though
          --    insufficient funds existed.
          -- X: Same as W for reversal distribution line.

          l_freeze_dist_flag := 'Y';

        END IF;
        -----------------------------------------------------------------
        l_debug_info := 'Step 4: Item distribution is part of a reversal pair';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------
        IF (l_freeze_dist_flag = 'N' AND
            l_itm_dist_list_local(i).reversal_flag = 'Y') THEN

          l_freeze_dist_flag := 'Y';

        END IF;

        -----------------------------------------------------------------
        l_debug_info := 'Step 5: Item distribution is PO/RCV matched';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------
        IF (l_freeze_dist_flag = 'N' AND
           (l_itm_dist_list_local(i).po_distribution_id IS NOT NULL
            OR l_itm_dist_list_local(i).rcv_transaction_id IS NOT NULL)) THEN

            l_freeze_dist_flag := 'Y';
        END IF;

        -----------------------------------------------------------------
        l_debug_info := 'Step 6: Item distribution is prepayment '||
                        'application/unapplication';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------

        -- For tax distributions created based on a PREPAY distribution
        -- (parent dist) the prepay_distribution_id will be always populated
        -- with the prepay_distribution_id of the parent (PREPAY) dist.

        IF (l_freeze_dist_flag = 'N' AND
            l_itm_dist_list_local(i).prepay_distribution_id IS NOT NULL) THEN

          l_freeze_dist_flag := 'Y';

        END IF;

        -----------------------------------------------------------------
        l_debug_info := 'Step 7: Item distribution if partially of fully '||
                        'accounted';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------
        IF (l_freeze_dist_flag = 'N' ) THEN
           IF ( ap_invoice_distributions_pkg.Get_Posted_Status(
             X_Accrual_Posted_Flag => l_itm_dist_list_local(i).accrual_posted_flag,
             X_Cash_Posted_Flag    => l_itm_dist_list_local(i).cash_posted_flag,
             X_Posted_Flag         => l_itm_dist_list_local(i).posted_flag,
             X_Org_Id              => l_itm_dist_list_local(i).org_id) <> 'N') THEN
             l_freeze_dist_flag := 'Y';
           END IF;
        END IF;

        -----------------------------------------------------------------
        l_debug_info := 'Step 8: Item distribution is transferred to projects';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------

        IF (l_freeze_dist_flag = 'N' ) THEN
           IF (NVL(l_itm_dist_list_local(i).pa_addition_flag,'N') NOT IN ('N', 'E')) THEN
             -- N means not yet transfer to projects
             -- E means not project related.
             -- If the flag is Y or any rejection code, it is assumed to be
             -- transfered

             l_freeze_dist_flag := 'Y';
           END IF;
        END IF;

        -----------------------------------------------------------------
        l_debug_info := 'Step 9: Item distribution has been validated';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------

        IF (l_freeze_dist_flag = 'N' AND
           NVL(l_itm_dist_list_local(i).match_status_flag,'N') IN ('T', 'A')) THEN

          l_freeze_dist_flag := 'Y';
        END IF;

        -----------------------------------------------------------------
        l_debug_info := 'Step 9.1: accounting_event_id is stamped';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------

        IF (l_freeze_dist_flag = 'N' AND
            l_itm_dist_list_local(i).accounting_event_id IS NOT NULL) THEN

          l_freeze_dist_flag := 'Y';
        END IF;

        -----------------------------------------------------------------
        l_debug_info := 'Step 10: Item distribution is a part of '||
                        'prepayment and has been partially or fully applied';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------

            -- This validation was analized and it is not included since the
            -- this API will not be called after the prepayment is
            -- partiall or fully applied.  The prepayment invoice cannot be
            -- modified after it is partially or fully applied.

         IF(l_freeze_dist_flag = 'N' AND
            P_Invoice_Header_Rec.invoice_type_lookup_code='PREPAYMENT' AND
            l_itm_dist_list_local(i).amount <>l_itm_dist_list_local(i).prepay_amount_remaining) THEN

            l_freeze_dist_flag := 'Y';
         END IF;

         -----------------------------------------------------------------
        l_debug_info := 'Step 12: Check if the parent item line has been '||
                        'adjusted by a PO price Adjustment or it itself an '||
                        'adjustment';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------
        IF (l_freeze_dist_flag = 'N' AND
            l_itm_dist_list_local(i).dist_match_type IN
            ('ADJUSTMENT_CORRECTION','PO_PRICE_ADJUSTMENT')) THEN
            l_freeze_dist_flag := 'Y';
        END IF;

        -----------------------------------------------------------------
        l_debug_info := 'Step 13: Item line is a corrected one ';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------
        -- This rule can be applied at distribution level since the
        -- corrected_invoice_dist_id is populated if it corrects any other
        -- distribution.
        IF (l_freeze_dist_flag = 'N' AND
            l_itm_dist_list_local(i).corrected_invoice_dist_id IS NOT NULL) THEN
          l_freeze_dist_flag := 'Y';
        END IF;

        l_freeze_dist_flag := 'Y'; --Bug9021265
        --Setting the Freeze Flag Y by defauly as per discussion
        --Himesh,Atul,Venkat,Kiran,Ranjith,Taniya
        -----------------------------------------------------------------
        l_debug_info := ' Inv Dist ID: '||l_itm_dist_list_local(i).invoice_distribution_id||
                        ' Freeze Flag: '||l_freeze_dist_flag;
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------

        IF (l_freeze_dist_flag = 'Y') THEN
	  freeze_dist_count := freeze_dist_count + 1; --bug 8302194

           freeze_dist_list(freeze_dist_count) := l_itm_dist_list_local(i).invoice_distribution_id;

           l_debug_info := ' Frozen Dist Id '||freeze_dist_list(freeze_dist_count);

           IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
           END IF;

        END IF;

      END LOOP;
    END IF;

    l_transaction_rec.internal_organization_id := P_Invoice_Header_Rec.org_id;
    l_transaction_rec.application_id           := 200;
    l_transaction_rec.entity_code              := 'AP_INVOICES';
    l_transaction_rec.event_class_code         := P_event_class_code;
    l_transaction_rec.event_type_code          := l_event_type_code;
    l_transaction_rec.trx_id                   := P_Invoice_Header_Rec.invoice_id;


    -----------------------------------------------------------------
    l_debug_info := 'Step 18: Call Freeze_tax_distributions service';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    IF ( l_return_status = TRUE AND freeze_dist_list.count>0) THEN

     zx_new_services_pkg.freeze_tax_dists_for_items(
        p_api_version          => 1.0,
        p_init_msg_list        => FND_API.G_TRUE,
        p_commit               => FND_API.G_FALSE,
        p_validation_level     => FND_API.G_VALID_LEVEL_FULL,
        x_return_status        => l_return_status_service,
        x_msg_count            => l_msg_count,
        x_msg_data             => l_msg_data,
        p_transaction_rec      => l_transaction_rec,
        p_trx_line_dist_id_tbl => freeze_dist_list);

    END IF;


      -----------------------------------------------------------------
      l_debug_info := 'Step 19: Verify return status';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------
    IF (l_return_status_service <> 'S') THEN  -- handle errors

      l_return_status := FALSE;
      -----------------------------------------------------------------
      l_debug_info := 'Step 20: Handle errors returned by API';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------

      IF NOT(AP_ETAX_UTILITY_PKG.Return_Error_Messages(
               P_All_Error_Messages  => P_All_Error_Messages,
               P_Msg_Count           => l_msg_count,
               P_Msg_Data            => l_msg_data,
               P_Error_Code          => P_Error_Code,
               P_Calling_Sequence    => l_curr_calling_sequence)) THEN
        NULL;
      END IF;

    END IF;

  RETURN l_return_status;

EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Id = '||P_Invoice_Header_Rec.Invoice_id||
          ' P_Calling_Mode ='||P_Calling_Mode||
          ' P_Error_Code = '||P_Error_Code||
          ' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      IF ( Itm_Dist%ISOPEN ) THEN
        CLOSE Itm_Dist;
      END IF;

      --bug10140354
      IF AP_APPROVAL_PKG.G_VALIDATION_REQUEST_ID IS NULL THEN
        APP_EXCEPTION.RAISE_EXCEPTION;
    ELSE
    l_err:= SQLERRM;
    insert into ap_errors_gt(invoice_id , message_text) values (P_Invoice_Header_Rec.Invoice_id , l_err);
    RETURN FALSE;
END IF;

END Freeze_itm_Distributions;
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
 |      P_Invoice_Header_Rec - Invoice record info
 |      P_Calling_Mode - calling mode.  Identifies which service to call
 |      P_Event_Class_Code - event class code for the invoice type
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

  FUNCTION Freeze_Distributions(
             P_Invoice_Header_Rec      IN ap_invoices_all%ROWTYPE,
             P_Calling_Mode            IN VARCHAR2,
             P_Event_Class_Code        IN VARCHAR2,
             P_All_Error_Messages      IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN
  IS

    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);
    l_transaction_rec            zx_api_pub.transaction_rec_type;

    l_event_type_code            zx_trx_headers_gt.event_type_code%TYPE;

    CURSOR Tax_Dist IS
    (SELECT encumbered_flag,
            reversal_flag,
            charge_applicable_to_dist_id,
            prepay_distribution_id,
            accrual_posted_flag,
            cash_posted_flag,
            posted_flag,
            org_id,
            pa_addition_flag,
            match_status_flag,
            corrected_invoice_dist_id,
            invoice_distribution_id,
            detail_tax_dist_id,
            accounting_event_id
       FROM ap_invoice_distributions_all
      WHERE invoice_id = p_invoice_header_rec.invoice_id
        AND line_type_lookup_code IN ('REC_TAX', 'NONREC_TAX', 'TRV', 'TERV', 'TIPV')
        AND (related_id IS NULL
                  OR (related_id = invoice_distribution_id
                      OR (related_id IS NOT NULL
                          AND line_type_lookup_code IN ('TRV', 'TERV', 'TIPV'))))
      UNION ALL
      SELECT encumbered_flag,
             reversal_flag,
             charge_applicable_to_dist_id,
             prepay_distribution_id,
             accrual_posted_flag,
             cash_posted_flag,
             posted_flag,
             org_id,
             pa_addition_flag,
             match_status_flag,
             corrected_invoice_dist_id,
             invoice_distribution_id,
             detail_tax_dist_id,
             accounting_event_id
        FROM ap_self_assessed_tax_dist_all
       WHERE invoice_id = p_invoice_header_rec.invoice_id
         AND line_type_lookup_code IN ('REC_TAX', 'NONREC_TAX', 'TRV', 'TERV', 'TIPV')
         AND (related_id IS NULL
                  OR (related_id = invoice_distribution_id
                      OR (related_id IS NOT NULL
                          AND line_type_lookup_code IN ('TRV', 'TERV', 'TIPV')))));


    TYPE l_tax_dist_tab_local   IS TABLE OF Tax_Dist%ROWTYPE;
    l_tax_dist_list_local 	l_tax_dist_tab_local;

    -- If related_id is equals invoice_distribution_id we are
    -- sure is the primary distribution created (not including variances)
    -- Rules applied to primary taxable distributions apply to
    -- related variances.

    l_return_status_service       VARCHAR2(4000);
    l_msg_count                   NUMBER;
    l_msg_data                    VARCHAR2(4000);
    l_msg                         VARCHAR2(4000);

    l_return_status               BOOLEAN := TRUE;
    l_freeze_dist_flag            VARCHAR2(1);

    l_po_distribution_id          ap_invoice_distributions_all.po_distribution_id%TYPE;
    l_rcv_transaction_id          ap_invoice_distributions_all.rcv_transaction_id%TYPE;

    TYPE freeze_tax_dist_type IS TABLE OF zx_tax_dist_id_gt%ROWTYPE;
    freeze_dist_list          freeze_tax_dist_type := freeze_tax_dist_type();

    l_api_name                    CONSTANT VARCHAR2(100) := 'Freeze_Distributions';

  BEGIN
    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.Freeze_Distributions<-' ||
                               P_calling_sequence;

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_curr_calling_sequence);
    END IF;

    -----------------------------------------------------------------
    l_debug_info := 'Step 1: Populating tax distributions collection';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------

    BEGIN
      OPEN Tax_Dist;
      FETCH Tax_Dist
      BULK COLLECT INTO l_tax_dist_list_local;
      CLOSE Tax_Dist;
    END;

    -------------------------------------------------------------------
    l_debug_info := 'Step 2: Get event type code';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------

    IF (l_return_status = TRUE) THEN
      IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Type_Code(
        P_Event_Class_Code          => P_event_class_code,
        P_Calling_Mode              => P_Calling_Mode,
        P_eTax_Already_called_flag  => 'Y',
        P_Event_Type_Code           => l_Event_Type_Code,
        P_Error_Code                => P_error_code,
        P_Calling_Sequence          => l_curr_calling_sequence)) THEN

        l_return_status := FALSE;
      END IF;
    END IF;

    IF (l_tax_dist_list_local.COUNT <> 0) THEN
      -- Initialize freeze_dist_list collection
      freeze_dist_list.EXTEND(l_tax_dist_list_local.COUNT);

      FOR i IN l_tax_dist_list_local.FIRST..l_tax_dist_list_local.LAST LOOP
        -- set l_freeze_dist_flag to N to initiate process
        l_freeze_dist_flag := 'N';

        -- Rules for distributions
        -----------------------------------------------------------------
        l_debug_info := 'Step 3: Tax distribution is encumbered';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------
        IF (NVL(l_tax_dist_list_local(i).encumbered_flag, 'N') IN ('Y','D','W','X')) THEN
          -- possible values verified for encumbered_flag
          -- Y: Regular line, has already been successfully encumbered by AP.
          -- D: Same as Y for reversal distribution line.
          -- W: Regular line, has been encumbered in advisory mode even though
          --    insufficient funds existed.
          -- X: Same as W for reversal distribution line.

          l_freeze_dist_flag := 'Y';

        END IF;
        -----------------------------------------------------------------
        l_debug_info := 'Step 4: Tax distribution is part of a reversal pair';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------
        IF (l_freeze_dist_flag = 'N' AND
            l_tax_dist_list_local(i).reversal_flag = 'Y') THEN

          l_freeze_dist_flag := 'Y';

        END IF;

        -----------------------------------------------------------------
        l_debug_info := 'Step 5: Parent Item distribution is PO/RCV matched';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------
        IF (l_freeze_dist_flag = 'N' AND
           (l_tax_dist_list_local(i).charge_applicable_to_dist_id IS NOT NULL
            and l_tax_dist_list_local(i).charge_applicable_to_dist_id <>-99)) THEN
           /* for bug 6010950 added 'charge_applicable_to_dist_id<>-99 condition'.
              As for Tax only invoices which are not receipt matched below
              select should not fire.I found out that value of charge_applicable_to_dist_id is
              -99 in this case.So aaded the AND condition to avoid the select.  */
            --this validation because it can be null for tax-only lines

           SELECT po_distribution_id, rcv_transaction_id
             INTO l_po_distribution_id, l_rcv_transaction_id
             FROM ap_invoice_distributions_all
            WHERE invoice_distribution_id =
                  l_tax_dist_list_local(i).charge_applicable_to_dist_id;


           IF ( l_po_distribution_id IS NOT NULL OR
              l_rcv_transaction_id IS NOT NULL ) THEN
              l_freeze_dist_flag := 'Y';

           END IF;
        END IF;

        -----------------------------------------------------------------
        l_debug_info := 'Step 6: Parent Item distribution is prepayment '||
                        'application/unapplication';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------
        -- For tax distributions created based on a PREPAY distribution
        -- (parent dist) the prepay_distribution_id will be always populated
        -- with the prepay_distribution_id of the parent (PREPAY) dist.
        IF (l_freeze_dist_flag = 'N' AND
            l_tax_dist_list_local(i).prepay_distribution_id IS NOT NULL) THEN

          l_freeze_dist_flag := 'Y';

        END IF;

        -----------------------------------------------------------------
        l_debug_info := 'Step 7: Tax distribution if partially of fully '||
                        'accounted';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------
        IF (l_freeze_dist_flag = 'N' ) THEN
           IF ( ap_invoice_distributions_pkg.Get_Posted_Status(
             X_Accrual_Posted_Flag => l_tax_dist_list_local(i).accrual_posted_flag,
             X_Cash_Posted_Flag    => l_tax_dist_list_local(i).cash_posted_flag,
             X_Posted_Flag         => l_tax_dist_list_local(i).posted_flag,
             X_Org_Id              => l_tax_dist_list_local(i).org_id) <> 'N') THEN
             l_freeze_dist_flag := 'Y';
           END IF;
        END IF;

        -----------------------------------------------------------------
        l_debug_info := 'Step 8: Tax distribution is transferred to projects';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------
        IF (l_freeze_dist_flag = 'N' ) THEN
           IF (NVL(l_tax_dist_list_local(i).pa_addition_flag,'N') NOT IN ('N', 'E')) THEN
             -- N means not yet transfer to projects
             -- E means not project related.
             -- If the flag is Y or any rejection code, it is assumed to be
             -- transfered

             l_freeze_dist_flag := 'Y';
           END IF;
        END IF;

        -----------------------------------------------------------------
        l_debug_info := 'Step 9: Tax distribution has been validated';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------
        IF (l_freeze_dist_flag = 'N' AND
           NVL(l_tax_dist_list_local(i).match_status_flag,'N') IN ('T', 'A')) THEN

          l_freeze_dist_flag := 'Y';
        END IF;

        -----------------------------------------------------------------
        l_debug_info := 'Step 9.1: accounting_event_id is stamped';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------
        IF (l_freeze_dist_flag = 'N' AND
            l_tax_dist_list_local(i).accounting_event_id IS NOT NULL) THEN

          l_freeze_dist_flag := 'Y';
        END IF;

        -----------------------------------------------------------------
        l_debug_info := 'Step 10: Parent Item distribution is a part of '||
                        'prepayment and has been partially or fully applied';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------
            -- This validation was analized and it is not included since the
            -- this API will not be called after the prepayment is
            -- partiall or fully applied.  The prepayment invoice cannot be
            -- modified after it is partially or fully applied.


        -- Rules for lines
        -----------------------------------------------------------------
        l_debug_info := 'Step 11: Check if tax line has been discarded';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------
        -- This validation is included in the reversal of the distributions.
        -- when the line is discarded the distributions are reversed.

        -----------------------------------------------------------------
        l_debug_info := 'Step 12: Check if the parent item line has been '||
                        'adjusted by a PO price Adjustment or it itself an '||
                        'adjustment';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------
        --YIDSAL.  This validation will be included when the retro pricing code
        -- is included in 11iX

        -----------------------------------------------------------------
        l_debug_info := 'Step 13: Parent Item line is a corrected one or is '||
                        'itself a correction';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------
        -- This rule can be applied at distribution level since the
        -- corrected_invoice_dist_id is populated if it corrects any other
        -- distribution.
        IF (l_freeze_dist_flag = 'N' AND
            l_tax_dist_list_local(i).corrected_invoice_dist_id IS NOT NULL) THEN

          l_freeze_dist_flag := 'Y';
        END IF;

        -- To know if the distribution is a corrected one
        -- Verify if the parent item (taxable) distribution is corrected.
        IF (l_freeze_dist_flag = 'N' ) THEN
          BEGIN
            SELECT 'Y'
              INTO l_freeze_dist_flag
              FROM ap_invoice_distributions_all
             WHERE corrected_invoice_dist_id =
                   l_tax_dist_list_local(i).charge_applicable_to_dist_id
               AND ROWNUM = 1;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN NULL;
          END;
        END IF;

        -----------------------------------------------------------------
        l_debug_info := 'Step 14: Parent item line is a prepayment application'||
                        '/unapplication';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------
        -- this validation is included in the distribution validations for the
        -- parent item distribution

        -----------------------------------------------------------------
        l_debug_info := ' Inv Dist ID: '||l_tax_dist_list_local(i).invoice_distribution_id||
                        ' Freeze Flag: '||l_freeze_dist_flag;
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------

        IF (l_freeze_dist_flag = 'Y') THEN

           freeze_dist_list(i).tax_dist_id := l_tax_dist_list_local(i).detail_tax_dist_id;

           l_debug_info := ' Frozen Dist Id '||freeze_dist_list(i).tax_dist_id;

           IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
           END IF;

        END IF;

      END LOOP;
    END IF;

    delete zx_tax_dist_id_gt;--Bug7582775

    l_debug_info := 'No Of Rows Deleted From zx_tax_dist_id_gt  '||sql%rowcount;

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;

    FOR m IN NVL(freeze_dist_list.FIRST,0)..NVL(freeze_dist_list.LAST,0)
    LOOP
      IF (freeze_dist_list.exists(m)) THEN

        IF (freeze_dist_list(m).tax_dist_id IS NOT NULL) THEN
          INSERT INTO zx_tax_dist_id_gt(tax_dist_id)
          VALUES (freeze_dist_list(m).tax_dist_id);

        END IF;
      END IF;
    END LOOP;

    l_transaction_rec.internal_organization_id := P_Invoice_Header_Rec.org_id;
    l_transaction_rec.application_id           := 200;
    l_transaction_rec.entity_code              := 'AP_INVOICES';
    l_transaction_rec.event_class_code         := P_event_class_code;
    l_transaction_rec.event_type_code          := l_event_type_code;
    l_transaction_rec.trx_id                   := P_Invoice_Header_Rec.invoice_id;

    -----------------------------------------------------------------
    l_debug_info := 'Step 18: Call Freeze_tax_distributions service';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    IF ( l_return_status = TRUE AND freeze_dist_list.count>0) THEN --Bug7582775

     zx_api_pub.freeze_tax_distributions(
        p_api_version        => 1.0,
        p_init_msg_list      => FND_API.G_TRUE,
        p_commit             => FND_API.G_FALSE,
        p_validation_level   => FND_API.G_VALID_LEVEL_FULL,
        x_return_status      => l_return_status_service,
        x_msg_count          => l_msg_count,
        x_msg_data           => l_msg_data,
        p_transaction_rec    => l_transaction_rec);

    END IF;

    -----------------------------------------------------------------
    l_debug_info := 'Step 19: Verify return status';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    IF (l_return_status_service <> 'S') THEN  -- handle errors

      l_return_status := FALSE;
      -----------------------------------------------------------------
      l_debug_info := 'Step 20: Handle errors returned by API';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------

      IF NOT(AP_ETAX_UTILITY_PKG.Return_Error_Messages(
               P_All_Error_Messages  => P_All_Error_Messages,
               P_Msg_Count           => l_msg_count,
               P_Msg_Data            => l_msg_data,
               P_Error_Code          => P_Error_Code,
               P_Calling_Sequence    => l_curr_calling_sequence)) THEN
        NULL;
      END IF;

    END IF;

  RETURN l_return_status;

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Id = '||P_Invoice_Header_Rec.Invoice_id||
          ' P_Calling_Mode ='||P_Calling_Mode||
          ' P_Error_Code = '||P_Error_Code||
          ' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      IF ( tax_dist%ISOPEN ) THEN
        CLOSE tax_dist;
      END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;

  END Freeze_Distributions;

/*=============================================================================
 |  FUNCTION - Global_Document_Update()
 |
 |  DESCRIPTION
 |      Public function that will call the global_document_update service to
 |      inform eTax of a cancellation of an invoice, the freeze after the
 |      invoice is validated (meaning is ready to reporting), the unfreeze
 |      of an invoice because it has to be modified after it was validated, and
 |      the release of tax holds by the user.
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

  FUNCTION Global_Document_Update(
             P_Invoice_id              IN NUMBER,
	     P_Line_Number	       IN NUMBER DEFAULT NULL,
             P_Calling_Mode            IN VARCHAR2,
             P_All_Error_Messages      IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN
  IS

    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);

    l_inv_header_rec             ap_invoices_all%ROWTYPE;
    l_event_class_code           zx_trx_headers_gt.event_class_code%TYPE;
    l_event_type_code            zx_trx_headers_gt.event_type_code%TYPE;

    CURSOR Invoice_Header IS
    SELECT *
      FROM ap_invoices_all
     WHERE invoice_id = P_Invoice_Id;

    l_transaction_rec             zx_api_pub.transaction_rec_type;

    l_return_status_service       VARCHAR2(4000);
    l_msg_count                   NUMBER;
    l_msg_data                    VARCHAR2(4000);
    l_msg                         VARCHAR2(4000);

    l_success			  BOOLEAN;
    Tax_Exception		  EXCEPTION;
    l_return_status               BOOLEAN := TRUE;
    l_api_name                  VARCHAR2(30) := 'global_document_update'; -- bug 6321366
  BEGIN

    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.Global_Document_Update<-' ||
                               P_calling_sequence;

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, l_curr_calling_sequence);
    END IF;

    --Bug8811102
    IF P_Calling_Mode IN('CANCEL INVOICE','DISCARD LINE','UNAPPLY PREPAY') THEN
        --Bug6799496
        --IF control_amount (Control Tax amount is non zero then invoice cancellation
        --errors out. Hence making it 0 before we populate headers_gt (zx table)
        -------------------------------------------------------------------
        l_debug_info := 'If CANCEL INVOICE Then Make Control Amount 0';
        -------------------------------------------------------------------
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, l_debug_info);
        END IF;

        UPDATE ap_invoices_all ail
           SET control_amount= NULL --Bug6887264
         WHERE ail.invoice_id = p_invoice_id
           AND P_Calling_Mode = 'CANCEL INVOICE'
           AND ail.control_amount IS NOT NULL ;
           --bug 6845888
           --Bug6799496

        UPDATE ap_invoice_lines_all ail
          SET control_amount= NULL --Bug6887264
        WHERE ail.invoice_id = p_invoice_id
          AND P_Calling_Mode = 'CANCEL INVOICE'
          AND ail.control_amount IS NOT NULL ;




        IF NOT cancel_invoice
            (p_invoice_id   => p_invoice_id,
			 p_line_number  => p_line_number,
			 p_calling_mode => P_Calling_Mode) THEN

           l_return_status := FALSE;
        END IF;
    END IF;
    --Bug8811102

    RETURN l_return_status;

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Id = '||P_Invoice_Id||
          ' P_Calling_Mode ='||P_Calling_Mode||
          ' P_Error_Code = '||P_Error_Code||
          ' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;

  END Global_Document_Update;


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
 |      P_Tax_Hold_Code - List of tax hold codes released in AP
 |                        Posible values: TAX VARIANCE and TAX AMOUNT RANGE
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
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN
  IS

    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);

    l_inv_header_rec             ap_invoices_all%ROWTYPE;
    l_event_class_code           zx_trx_headers_gt.event_class_code%TYPE;
    l_event_type_code            zx_trx_headers_gt.event_type_code%TYPE;

    CURSOR Invoice_Header IS
    SELECT *
      FROM ap_invoices_all
     WHERE invoice_id = P_Invoice_Id;

    l_transaction_rec             zx_api_pub.transaction_rec_type;
    l_validation_status           zx_api_pub.validation_status_tbl_type;

    l_return_status_service       VARCHAR2(4000);
    l_msg_count                   NUMBER;
    l_msg_data                    VARCHAR2(4000);
    l_msg                         VARCHAR2(4000);

    l_return_status               BOOLEAN := TRUE;
    l_api_name                    VARCHAR2(30) := 'Release_Tax_Holds';

  BEGIN

    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.Release_Tax_Holds<-' ||
                               P_calling_sequence;

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_curr_calling_sequence);
    END IF;

    IF (P_Tax_Hold_Code.COUNT = 0 ) THEN

      RETURN TRUE;
    END IF;

    -----------------------------------------------------------------
    l_debug_info := 'Step 1: Populating invoice header local record';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------

    BEGIN
      OPEN Invoice_Header;
      FETCH Invoice_Header INTO l_inv_header_rec;
      CLOSE Invoice_Header;
    END;

    -------------------------------------------------------------------
    l_debug_info := 'Step 2: Get event class code';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------

    IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Class_Code(
      P_Invoice_Type_Lookup_Code => l_inv_header_rec.invoice_type_lookup_code,
      P_Event_Class_Code         => l_event_class_code,
      P_error_code               => P_error_code,
      P_calling_sequence         => l_curr_calling_sequence)) THEN

      l_return_status := FALSE;

    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 3: Get event type code';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF (l_return_status = TRUE) THEN
      IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Type_Code(
        P_Event_Class_Code          => l_event_class_code,
        P_Calling_Mode              => P_Calling_Mode,
        P_eTax_Already_called_flag  => NULL,
        P_Event_Type_Code           => l_Event_Type_Code,
        P_Error_Code                => P_error_code,
        P_Calling_Sequence          => l_curr_calling_sequence)) THEN

        l_return_status := FALSE;
      END IF;
    END IF;


    -------------------------------------------------------------------
    l_debug_info := 'Step 4: Populate service specific parameter';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    l_transaction_rec.internal_organization_id := l_inv_header_rec.org_id;
    l_transaction_rec.application_id           := 200;
    l_transaction_rec.entity_code              := 'AP_INVOICES';
    l_transaction_rec.event_class_code         := l_event_class_code;
    l_transaction_rec.event_type_code          := l_event_type_code;
    l_transaction_rec.trx_id                   := l_inv_header_rec.invoice_id;

    -------------------------------------------------------------------
    l_debug_info := 'Step 5: Populate tax_hold_release_code ';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF ( l_return_status = TRUE) THEN

      IF ( P_Tax_Hold_Code.COUNT <> 0 ) THEN
        FOR i IN P_Tax_Hold_Code.FIRST..P_Tax_Hold_Code.LAST LOOP
          --  P_Tax_Hold_Code is populated with the tax hold codes to
          --  release.  Posible values are: TAX VARIANCE and TAX AMOUNT RANGE
          --  We need to pass to eTax the release code, so a conversion is
          --  required

          IF (P_Tax_Hold_Code(i) = 'TAX VARIANCE') THEN
            l_validation_status(i) :=  'TAX VARIANCE CORRECTED';

          ELSIF (P_Tax_Hold_Code(i) = 'TAX AMOUNT RANGE') THEN
            l_validation_status(i) :=  'TAX AMOUNT RANGE CORRECTED';

          END IF;
        END LOOP;
      END IF;
    END IF;


    -------------------------------------------------------------------
    l_debug_info := 'Step 6: Call to global_document_update service';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF ( l_return_status = TRUE ) THEN
      zx_api_pub.global_document_update(
        p_api_version        => 1.0,
        p_init_msg_list      => FND_API.G_TRUE,
        p_commit             => FND_API.G_FALSE,
        p_validation_level   => FND_API.G_VALID_LEVEL_FULL,
        p_transaction_rec    => l_transaction_rec,
        p_validation_status  => l_validation_status,
        x_return_status      => l_return_status_service,
        x_msg_count          => l_msg_count,
        x_msg_data           => l_msg_data);

    END IF;

    -----------------------------------------------------------------
    l_debug_info := 'Step 7: Verify return status';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    IF (l_return_status_service <> 'S') THEN  -- handle errors

      l_return_status := FALSE;
      -----------------------------------------------------------------
      l_debug_info := 'Step 8: Handle errors returned by API';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------

      IF NOT(AP_ETAX_UTILITY_PKG.Return_Error_Messages(
               P_All_Error_Messages  => P_All_Error_Messages,
               P_Msg_Count           => l_msg_count,
               P_Msg_Data            => l_msg_data,
               P_Error_Code          => P_Error_Code,
               P_Calling_Sequence    => l_curr_calling_sequence)) THEN
        NULL;
      END IF;
    END IF;

    RETURN l_return_status;

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Id = '||P_Invoice_Id||
          ' P_Calling_Mode ='||P_Calling_Mode||
          ' P_Error_Code = '||P_Error_Code||
          ' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;

  END Release_Tax_Holds;

/*=============================================================================
 |  FUNCTION - Mark_Tax_Lines_Deleted()
 |
 |  DESCRIPTION
 |      Public function that will call the mark_tax_lines_deleted service.
 |      This API assumes the calling code controls the commit cycle.
 |      This function returns TRUE if the call to the service is successful.
 |      Otherwise, FALSE.
 |      This service should be called per invoice line.
 |
 |  PARAMETERS
 |      P_Invoice_Id - invoice id
 |      P_Calling_Mode - calling mode.  Identifies which service to call
 |      P_Line_Number_To_Delete - line number deleted in AP
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

  FUNCTION Mark_Tax_Lines_Deleted(
             P_Invoice_id              IN NUMBER,
             P_Calling_Mode            IN VARCHAR2,
             P_Line_Number_To_Delete   IN NUMBER,
             P_All_Error_Messages      IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN
  IS

    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);
    --Bug8604959: Added debug logging
    l_api_name			 VARCHAR2(30) := 'Mark_Tax_Lines_Deleted';
    l_inv_header_rec             ap_invoices_all%ROWTYPE;
    l_event_class_code           zx_trx_headers_gt.event_class_code%TYPE;
    l_event_type_code            zx_trx_headers_gt.event_type_code%TYPE;

    CURSOR Invoice_Header IS
    SELECT *
      FROM ap_invoices_all
     WHERE invoice_id = P_Invoice_Id;

    l_transaction_line_rec       zx_api_pub.transaction_line_rec_type;

    l_return_status_service      VARCHAR2(4000);
    l_msg_count                  NUMBER;
    l_msg_data                   VARCHAR2(4000);
    l_msg                        VARCHAR2(4000);

    l_return_status              BOOLEAN := TRUE;

  BEGIN
    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.Mark_Tax_Lines_Deleted<-' ||
                               P_calling_sequence;

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_curr_calling_sequence);
    END IF;

    -----------------------------------------------------------------
    l_debug_info := 'Step 1: Populating invoice header local record';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    --Print(l_api_name, l_debug_info);
    -----------------------------------------------------------------

    BEGIN
      OPEN Invoice_Header;
      FETCH Invoice_Header INTO l_inv_header_rec;
      CLOSE Invoice_Header;
    END;


    -------------------------------------------------------------------
    l_debug_info := 'Step 2: Get event class code';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    --Print(l_api_name, l_debug_info);
    -------------------------------------------------------------------

    IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Class_Code(
      P_Invoice_Type_Lookup_Code => l_inv_header_rec.invoice_type_lookup_code,
      P_Event_Class_Code         => l_event_class_code,
      P_error_code               => P_error_code,
      P_calling_sequence         => l_curr_calling_sequence)) THEN

      l_return_status := FALSE;

    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 3: Get event type code';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    --Print(l_api_name, l_debug_info);
    -------------------------------------------------------------------
    IF (l_return_status = TRUE) THEN
      IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Type_Code(
        P_Event_Class_Code          => l_event_class_code,
        P_Calling_Mode              => P_Calling_Mode,
        P_eTax_Already_called_flag  => NULL,
        P_Event_Type_Code           => l_Event_Type_Code,
        P_Error_Code                => P_error_code,
        P_Calling_Sequence          => l_curr_calling_sequence)) THEN

        l_return_status := FALSE;
      END IF;
    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 4: Populate service specific parameter';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    --Print(l_api_name, l_debug_info);
    -------------------------------------------------------------------
    l_transaction_line_rec.internal_organization_id := l_inv_header_rec.org_id;
    l_transaction_line_rec.application_id           := 200;
    l_transaction_line_rec.entity_code              := 'AP_INVOICES';
    l_transaction_line_rec.event_class_code         := l_event_class_code;
    l_transaction_line_rec.event_type_code          := l_event_type_code;
    l_transaction_line_rec.trx_id                   := P_Invoice_Id;
    l_transaction_line_rec.trx_level_type           := 'LINE';
    l_transaction_line_rec.trx_line_id              := P_Line_Number_To_Delete;

    -------------------------------------------------------------------
    l_debug_info := 'Step 6: Call to del_tax_line_and_distributions';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    --Print(l_api_name, l_debug_info);
    -------------------------------------------------------------------
    IF ( l_return_status = TRUE ) THEN

      --Bug8604959: Calling ZX API del_tax_line_and_distributions instead of
      --old zx api Mark_Tax_Lines_Deleted
      zx_api_pub.del_tax_line_and_distributions(
        p_api_version             => 1.0,
        p_init_msg_list           => FND_API.G_TRUE,
        p_commit                  => FND_API.G_FALSE,
        p_validation_level        => FND_API.G_VALID_LEVEL_FULL,
        p_transaction_line_rec    => l_transaction_line_rec,
        x_return_status           => l_return_status_service,
        x_msg_count               => l_msg_count,
        x_msg_data                => l_msg_data);

    END IF;

    -----------------------------------------------------------------
    l_debug_info := 'Step 7: Verify return status';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    --Print(l_api_name, l_debug_info);
    -----------------------------------------------------------------
    --Bug8604959 : Changed the IF ELSE block to add call to Update_AP api
    IF (l_return_status_service = 'S') THEN  -- Sync ZX and AP

	-----------------------------------------------------------------
        l_debug_info := 'Step 8: Sync up ZX and AP data after delete';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        --Print(l_api_name, l_debug_info);
        -----------------------------------------------------------------
        IF NOT(AP_ETAX_SERVICES_PKG.Update_AP(
	        P_Invoice_header_rec => l_inv_header_rec,
	        P_Calling_Mode       => 'DELETE TAX LINE',
	        P_All_Error_Messages => P_All_Error_Messages,
	        P_Error_Code         => P_error_code,
	        P_Calling_Sequence   => l_curr_calling_sequence)) THEN

            l_return_status := FALSE;
        END IF;

    ELSE --Handle errors

      l_return_status := FALSE;
      -----------------------------------------------------------------
      l_debug_info := 'Step 8: Handle errors returned by API';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      --Print(l_api_name, l_debug_info);
      -----------------------------------------------------------------

      IF NOT(AP_ETAX_UTILITY_PKG.Return_Error_Messages(
               P_All_Error_Messages  => P_All_Error_Messages,
               P_Msg_Count           => l_msg_count,
               P_Msg_Data            => l_msg_data,
               P_Error_Code          => P_Error_Code,
               P_Calling_Sequence    => l_curr_calling_sequence)) THEN
        NULL;
      END IF;

    END IF; --l_return_status
    --End of bug8604959
    RETURN l_return_status;

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Id = '||P_Invoice_Id||
          ' P_Line_Number_To_Delete = '||P_Line_Number_To_Delete||
          ' P_Calling_Mode ='||P_Calling_Mode||
          ' P_Error_Code = '||P_Error_Code||
          ' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;

  END Mark_Tax_Lines_Deleted;

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
             p_dummy                   IN VARCHAR2) RETURN VARCHAR2 IS

result boolean := false;
success varchar2(1000) := 'FALSE';

BEGIN
	result := Mark_Tax_Lines_Deleted(
             P_Invoice_id,
             P_Calling_Mode,
             P_Line_Number_To_Delete,
             P_All_Error_Messages,
             P_Error_Code,
             P_Calling_Sequence);

	IF (result = true) THEN
	   success := 'TRUE';
	END IF;

	return success;
END;

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
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN IS


    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);

    l_inv_header_rec             ap_invoices_all%ROWTYPE;
    l_event_class_code           zx_trx_headers_gt.event_class_code%TYPE;
    l_event_type_code            zx_trx_headers_gt.event_type_code%TYPE;

    CURSOR Invoice_Header IS
    SELECT *
      FROM ap_invoices_all
     WHERE invoice_id = P_Invoice_Id;

    l_transaction_rec             zx_api_pub.transaction_rec_type;

--    l_validation_status_tab       zx_api_pub.validation_status_tbl_type;
    l_validation_status		  VARCHAR2(1);
    l_hold_codes_tab		  zx_api_pub.hold_codes_tbl_type;

    l_return_status_service       VARCHAR2(4000);
    l_msg_count                   NUMBER;
    l_msg_data                    VARCHAR2(4000);
    l_msg                         VARCHAR2(4000);

    l_return_status               BOOLEAN := TRUE;

    TYPE hold_lookup_code_tab IS TABLE OF ap_holds_all.hold_lookup_code%TYPE;
    l_hold_lookup_code            hold_lookup_code_tab;
    l_release_lookup_code         ap_holds_all.release_lookup_code%TYPE;
    l_api_name			 varchar2(30);
    --Bug 7410237 start
    l_system_user                 NUMBER := 5;

    l_holds                       AP_APPROVAL_PKG.HOLDSARRAY;
    l_hold_count                  AP_APPROVAL_PKG.COUNTARRAY;
    l_release_count               AP_APPROVAL_PKG.COUNTARRAY;
    --Bug 7410237 End


  BEGIN

    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.Validate_Invoice<-' ||
                               P_calling_sequence;

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_curr_calling_sequence);
    END IF;

    l_api_name := 'Validate_Invoice';
    -----------------------------------------------------------------
    l_debug_info := 'Step 1: Populating invoice header local record';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------

    BEGIN
      OPEN Invoice_Header;
      FETCH Invoice_Header INTO l_inv_header_rec;
      CLOSE Invoice_Header;
    END;

    IF ((l_inv_header_rec.quick_credit = 'Y') OR    -- Bug 5660314
        (l_inv_header_rec.invoice_type_lookup_code IN ('AWT', 'INTEREST'))) THEN
      RETURN l_return_status;
    END IF;


    -------------------------------------------------------------------
    l_debug_info := 'Step 2: Get event class code';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------

    IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Class_Code(
      P_Invoice_Type_Lookup_Code => l_inv_header_rec.invoice_type_lookup_code,
      P_Event_Class_Code         => l_event_class_code,
      P_error_code               => P_error_code,
      P_calling_sequence         => l_curr_calling_sequence)) THEN

      l_return_status := FALSE;

    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 3: Get event type code';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF (l_return_status = TRUE) THEN
      IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Type_Code(
        P_Event_Class_Code          => l_event_class_code,
        P_Calling_Mode              => P_Calling_Mode,
        P_eTax_Already_called_flag  => NULL,
        P_Event_Type_Code           => l_Event_Type_Code,
        P_Error_Code                => P_error_code,
        P_Calling_Sequence          => l_curr_calling_sequence)) THEN

        l_return_status := FALSE;
      END IF;
    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 4: Populate service specific parameter';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    l_transaction_rec.internal_organization_id := l_inv_header_rec.org_id;
    l_transaction_rec.application_id           := 200;
    l_transaction_rec.entity_code              := 'AP_INVOICES';
    l_transaction_rec.event_class_code         := l_event_class_code;
    l_transaction_rec.event_type_code          := l_event_type_code;
    l_transaction_rec.trx_id                   := l_inv_header_rec.invoice_id;

    -------------------------------------------------------------------
    l_debug_info := 'Step 5: Call validate_document_for_tax service';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF ( l_return_status = TRUE ) THEN

      zx_api_pub.validate_document_for_tax(
        p_api_version        => 1.0,
        p_init_msg_list      => FND_API.G_TRUE,
        p_commit             => FND_API.G_FALSE,
        p_validation_level   => FND_API.G_VALID_LEVEL_FULL,
        p_transaction_rec    => l_transaction_rec,
        x_validation_status  => l_validation_status,
	    x_hold_codes_tbl     => l_hold_codes_tab,
        x_return_status      => l_return_status_service,
        x_msg_count          => l_msg_count,
        x_msg_data           => l_msg_data);

    END IF;

    -----------------------------------------------------------------
    l_debug_info := 'Step 6: Verify return status';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    IF (l_return_status_service = 'S') THEN

      l_debug_info := 'l_hold_codes_tab.count is '||l_hold_codes_tab.count;
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;

      -----------------------------------------------------------------
      l_debug_info := 'Step 7: Check for tax holds on invoice';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------
      --bugfix:5523240 Replaced the IF condition as the etax service
      --returns 'Y' eventhough tax holds are place
      --IF ( l_validation_status = 'N' ) THEN
      IF(l_hold_codes_tab.count = 0) THEN
            -----------------------------------------------------------------
            l_debug_info := 'Step 8: Verify if invoice has no released tax '||
                            ' holds';
            IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
            END IF;
            -----------------------------------------------------------------
            BEGIN
              SELECT hold_lookup_code
                BULK COLLECT INTO l_hold_lookup_code
                FROM ap_holds_all
               WHERE invoice_id = l_inv_header_rec.invoice_id
                 AND org_id = l_inv_header_rec.org_id
                 AND hold_lookup_code IN ('TAX VARIANCE', 'TAX AMOUNT RANGE')
                 AND release_lookup_code is NULL;

            EXCEPTION
              WHEN NO_DATA_FOUND THEN NULL;
            END;

            IF (l_hold_lookup_code.COUNT <> 0) THEN
               FOR i IN l_hold_lookup_code.FIRST..l_hold_lookup_code.LAST LOOP

		 ----------------------------------------------------------------------------
	         l_debug_info := 'Release tax holds';
                 IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                   FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                 END IF;
		 ----------------------------------------------------------------------------
                -- Bug 7410237 Start

                /*
                 IF (l_hold_lookup_code(i) = 'TAX VARIANCE') THEN
                  l_release_lookup_code := 'VARIANCE CORRECTED';

                 ELSE
                   l_release_lookup_code := 'HOLDS QUICK RELEASED';

                 END IF;

                 ap_holds_pkg.release_single_hold(
                   X_invoice_id              => l_inv_header_rec.invoice_id,
                   X_hold_lookup_code        => l_hold_lookup_code(i),
                   X_release_lookup_code     => l_release_lookup_code,
                   X_held_by                 => NULL,
                   X_calling_sequence        => l_curr_calling_sequence);
                 */

                  AP_APPROVAL_PKG.Process_Inv_Hold_Status(
                        p_invoice_id              =>   l_inv_header_rec.invoice_id,
                        p_line_location_id        =>   NULL,
                        p_rcv_transaction_id      =>   NULL,
                        p_hold_lookup_code        =>   l_hold_lookup_code(i),
                        p_should_have_hold        =>   'N',
                        p_hold_reason             =>   NULL,
                        p_system_user             =>   l_system_user,
                        p_holds                   =>   l_holds,
                        p_holds_count             =>   l_hold_count,
                        p_release_count           =>   l_release_count,
                        p_calling_sequence        =>   l_curr_calling_sequence);

                   -- Bug 7410237 End
               END LOOP;
            END IF;

        ELSIF (l_hold_codes_tab.count <> 0) THEN
           FOR i IN l_hold_codes_tab.FIRST..l_hold_codes_tab.LAST LOOP

              l_debug_info := 'l_hold_codes_tab(i) is '||l_hold_codes_tab(i);
              IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
              END IF;

              -----------------------------------------------------------------
              l_debug_info := 'Step 9: Create tax hold in AP if not exists';
              IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                 FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
              END IF;
              -----------------------------------------------------------------
              -- the posible values eTax will populate l_validation_status_tab
              -- with are:  TAX VARIANCE and TAX AMOUNT RANGE.  These are the same
              -- holds lookup codes used by API so there is no need to convert any
              -- value here
              -- Bug 7410237 Start
              /*
              ap_holds_pkg.insert_single_hold(
           	   X_invoice_id          => l_inv_header_rec.invoice_id,
              	   X_hold_lookup_code    => l_hold_codes_tab(i),
                   X_hold_type           => NULL,
                   X_hold_reason         => NULL,
                   X_held_by             => l_user_id,
                   X_calling_sequence    => l_curr_calling_sequence);
              */
                  AP_APPROVAL_PKG.Process_Inv_Hold_Status(
                        p_invoice_id              =>   l_inv_header_rec.invoice_id,
                        p_line_location_id        =>   NULL,
                        p_rcv_transaction_id      =>   NULL,
                        p_hold_lookup_code        =>   l_hold_codes_tab(i),
                        p_should_have_hold        =>   'Y',
                        p_hold_reason             =>   NULL,
                        p_system_user             =>   l_system_user,
                        p_holds                   =>   l_holds,
                        p_holds_count             =>   l_hold_count,
                        p_release_count           =>   l_release_count,
                        p_calling_sequence        =>   l_curr_calling_sequence);

               -- Bug 7410237 End
          END LOOP;
        END IF;

   ELSE  -- handle errors

      l_return_status := FALSE;
      -----------------------------------------------------------------
      l_debug_info := 'Step 8: Handle errors returned by API';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------

      IF NOT(AP_ETAX_UTILITY_PKG.Return_Error_Messages(
               P_All_Error_Messages  => P_All_Error_Messages,
               P_Msg_Count           => l_msg_count,
               P_Msg_Data            => l_msg_data,
               P_Error_Code          => P_Error_Code,
               P_Calling_Sequence    => l_curr_calling_sequence)) THEN
        NULL;
      END IF;
    END IF;

    RETURN l_return_status;

  END Validate_Invoice;

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
             P_Invoice_Rec_table             IN OUT NOCOPY
               AP_IMPORT_INVOICES_PKG.t_invoice_table,
             p_invoice_lines_table       IN OUT NOCOPY
               AP_IMPORT_INVOICES_PKG.t_lines_table,
             P_Calling_Mode            IN VARCHAR2,
             P_All_Error_Messages      IN VARCHAR2,
             p_invoice_status          OUT NOCOPY VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN
  IS
    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);

    l_event_class_code
      zx_trx_headers_gt.event_class_code%TYPE;
    l_event_type_code
      zx_trx_headers_gt.event_type_code%TYPE;

    l_return_status_service       VARCHAR2(4000);
    l_msg_count                   NUMBER;
    l_msg_data                    VARCHAR2(4000);
    l_msg                         VARCHAR2(4000);

    l_return_status               BOOLEAN := TRUE;
    l_api_name                    varchar2(30) := 'Validate_Default_Import';
    --bug 15862708 starts
    P_Invoice_Rec       AP_IMPORT_INVOICES_PKG.r_invoice_info_rec;
    p_invoice_lines_tabl AP_IMPORT_INVOICES_PKG.t_lines_table;
    k   number;
    l_cnt number;
   --bug 15862708 ends
  BEGIN

    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.Validate_Default_Import<-'
                               ||P_calling_sequence;

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_curr_calling_sequence);
    END IF;
 --bug 15862708
     IF P_Invoice_Rec_table.COUNT>0  THEN
       p_invoice_lines_tabl.DELETE;
      FOR i IN P_Invoice_Rec_table.FIRST .. P_Invoice_Rec_table.LAST
      LOOP
	    IF P_Invoice_Rec_table(i).invoice_type_lookup_code<>'PAYMENT REQUEST' THEN
         P_Invoice_Rec := P_Invoice_Rec_table(i);
          p_invoice_lines_tabl.delete;
          k :=0;
         FOR j IN p_invoice_lines_table.FIRST .. p_invoice_lines_table.LAST
         LOOP
            IF p_invoice_lines_table(j).invoice_id=P_Invoice_Rec.invoice_id THEN
               p_invoice_lines_tabl(k) := p_invoice_lines_table(j);
               k := k+1;
            END IF;
         END LOOP;
           -----------------------------------------------------------------
           l_debug_info := 'Step 1: Populate Header';
           IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
           END IF;
           -----------------------------------------------------------------
           IF NOT(AP_ETAX_SERVICES_PKG.Populate_Header_Import_GT(
             P_Invoice_Header_Rec         => P_Invoice_Rec,
             P_Calling_Mode               => P_Calling_Mode,
             P_Event_Class_Code           => l_event_class_code,
             P_Event_Type_Code            => l_event_type_code,
             P_Error_Code                 => P_error_code,
             P_Calling_Sequence           => l_curr_calling_sequence )) THEN

             l_return_status := FALSE;
           END IF;



           -----------------------------------------------------------------
           l_debug_info := 'Step 2: Populate Trx and Tax Lines and allocation '||
                           'structure ';
           IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
           END IF;
           -----------------------------------------------------------------
           IF ( l_return_status = TRUE ) THEN
             IF NOT(AP_ETAX_SERVICES_PKG.Populate_Lines_Import_GT(
               P_Invoice_Header_Rec      => P_Invoice_Rec,
               P_Inv_Line_List           => p_invoice_lines_tabl,
               P_Calling_Mode            => P_Calling_Mode,
               P_Event_Class_Code        => l_event_class_code,
               P_Error_Code              => P_error_code,
               P_Calling_Sequence        => l_curr_calling_sequence )) THEN

               l_return_status := FALSE;
             END IF;
           END IF;
         END IF;
       END LOOP;
     END IF;
    -----------------------------------------------------------------
    l_debug_info := 'Step 3: Call validate_and_default_tax_attr service';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    l_debug_info := 'Call validate_and_default_tax_attr service start ' ||to_char(sysdate,'YY-MON-DD HH24:MI:SS');
            IF (AP_IMPORT_INVOICES_PKG.g_debug_switch = 'Y') THEN
              AP_IMPORT_UTILITIES_PKG.Print(
                AP_IMPORT_INVOICES_PKG.g_debug_switch, l_debug_info);
            END IF;

      zx_api_pub.validate_and_default_tax_attr(
        p_api_version      => 1.0,
        p_init_msg_list    => FND_API.G_TRUE,
        p_commit           => FND_API.G_FALSE,
        p_validation_level => FND_API.G_VALID_LEVEL_FULL,
        x_return_status    => l_return_status_service,
        x_msg_count        => l_msg_count,
        x_msg_data         => l_msg_data);


     l_debug_info := 'Call validate_and_default_tax_attr service ends ' ||to_char(sysdate,'YY-MON-DD HH24:MI:SS');
            IF (AP_IMPORT_INVOICES_PKG.g_debug_switch = 'Y') THEN
              AP_IMPORT_UTILITIES_PKG.Print(
                AP_IMPORT_INVOICES_PKG.g_debug_switch, l_debug_info);
            END IF;

   IF (l_return_status_service = 'S') THEN

    IF  P_Invoice_Rec_table.COUNT>0 THEN
     FOR i IN P_Invoice_Rec_table.FIRST .. P_Invoice_Rec_table.LAST
     LOOP
	   IF P_Invoice_Rec_table(i).invoice_type_lookup_code<>'PAYMENT REQUEST' THEN
       P_Invoice_Rec := P_Invoice_Rec_table(i);

       -----------------------------------------------------------------
       l_debug_info := 'Step 4: Handle return of tax lines';

       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
       -----------------------------------------------------------------

      IF NOT (AP_ETAX_UTILITY_PKG.Return_Default_Import(
                P_Invoice_Header_Rec      => P_Invoice_Rec,
                P_Invoice_Lines_Tab       => p_invoice_lines_table,
                P_All_Error_Messages      => 'N',
                P_Error_Code              => P_Error_Code,
                P_Calling_Sequence        => substr(l_curr_calling_sequence,1,100),
		P_invoice_status	  => p_invoice_status --Bug6625518
		)) THEN

        l_return_status := FALSE;

      ELSE

            l_debug_info := 'Return_Default_Import was fine' ;
            IF (AP_IMPORT_INVOICES_PKG.g_debug_switch = 'Y') THEN
              AP_IMPORT_UTILITIES_PKG.Print(
                AP_IMPORT_INVOICES_PKG.g_debug_switch, l_debug_info);
            END IF;
	 --returns the record data to original collection
	 --so that it can be passed to calling proc

           P_Invoice_Rec_table(i) := P_Invoice_Rec;

      END IF;

     END IF;
     END LOOP;
    END IF;


      --Bug6625518 Commenting the assignment below.
      --This was making the flag for processing as 'Y' even in case of rejections.
      --p_invoice_status := 'Y';

   ELSE  -- handle errors

      -----------------------------------------------------------------
      l_debug_info := 'Step 5: Handle errors returned by API';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------
      l_return_status := FALSE;

      IF NOT(AP_ETAX_UTILITY_PKG.Return_Error_Messages(
               P_All_Error_Messages  => P_All_Error_Messages,
               P_Msg_Count           => l_msg_count,
               P_Msg_Data            => l_msg_data,
               P_Error_Code          => P_Error_Code,
               P_Calling_Sequence    => l_curr_calling_sequence)) THEN
        NULL;

      END IF;

      p_invoice_status := 'N';

   END IF;

   RETURN l_return_status;

  EXCEPTION
    WHEN OTHERS THEN
     /* Bug8345322: We dont want to raise an exception since this rollbacks
        the whole the import program and all the imported invoices are rolled back
        The invoice causing the exception will be rejected and we will continue
        with import program
        IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' Invoice_Id = '||P_Invoice_Rec.Invoice_Id||
          ' P_Calling_Mode ='||P_Calling_Mode||
          ' P_Error_Code = '||P_Error_Code||
          ' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;*/
      --IF (AP_IMPORT_INVOICES_PKG.g_debug_switch = 'Y') then
	  --We want to print the error message even if debug switch is off
	  --so user need not run the report again.
      RETURN FALSE;

        AP_IMPORT_UTILITIES_PKG.Print(AP_IMPORT_INVOICES_PKG.g_debug_switch,
                                     l_debug_info);
      --END IF;
      IF (SQLCODE < 0) then
         IF (AP_IMPORT_INVOICES_PKG.g_debug_switch = 'Y') then
          AP_IMPORT_UTILITIES_PKG.Print(AP_IMPORT_INVOICES_PKG.g_debug_switch,
                                       SQLERRM);
         END IF;
      END IF;
	  p_invoice_status := 'N';
      RETURN (FALSE);
      --End of Bug8345322

  END Validate_Default_Import;




/*=============================================================================
 |  FUNCTION - Populate_Headers_GT()
 |
 |  DESCRIPTION
 |      This function will get additional information required to populate the
 |      zx_trx_headers_gt
 |      This function returns TRUE if the insert to the temp table goes
 |      through successfully.  Otherwise, FALSE.
 |
 |  PARAMETERS
 |      P_Invoice_Header_Rec - record with invoice header information
 |      P_Calling_Mode - calling mode. it is used to
 |      P_eTax_Already_called_flag - Flag to know if this is the first time tax
 |                                   has been called
 |      P_Event_Class_Code - Event class code
 |      P_Event_Type_Code - Event type code
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
             P_Calling_Sequence          IN VARCHAR2) RETURN BOOLEAN
  IS

    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);

    l_application_id             zx_trx_headers_gt.application_id%TYPE;
    l_entity_code                zx_trx_headers_gt.entity_code%TYPE;

    l_quote_flag                 zx_trx_headers_gt.quote_flag%TYPE := 'N';
    -- This flag is always N except when the calculate service is called for
    -- quote for the recurring invoices and distributions sets.

    CURSOR tax_related_invoice( c_tax_related_invoice_id IN NUMBER) IS
-- B# 6907814 ...  SELECT invoice_num, invoice_date, invoice_type_lookup_code
    SELECT invoice_num, invoice_type_lookup_code, invoice_date
      FROM ap_invoices_all
     WHERE invoice_id = c_tax_related_invoice_id;

    l_related_inv_application_id
      zx_trx_headers_gt.related_doc_application_id%TYPE;
    l_related_inv_entity_code
      zx_trx_headers_gt.related_doc_entity_code%TYPE;
    l_related_event_class_code
      zx_trx_headers_gt.related_doc_event_class_code%TYPE;
    l_related_inv_number         ap_invoices_all.invoice_num%TYPE;
    l_related_inv_date           ap_invoices_all.invoice_date%TYPE;
    l_related_inv_type           ap_invoices_all.invoice_type_lookup_code%TYPE;

    l_precision                  fnd_currencies.precision%TYPE;
    l_minimum_accountable_unit   fnd_currencies.minimum_accountable_unit%TYPE;
    l_doc_seq_name		 fnd_document_sequences.db_sequence_name%TYPE;

    l_return_status              BOOLEAN := TRUE;
    l_api_name                  VARCHAR2(30) := 'Populate_headers_gt'; --bug 6321366
  BEGIN

    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.Populate_Headers_GT<-' ||
                               P_calling_sequence;

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_curr_calling_sequence);
    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 1: Get event class code';

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------

    IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Class_Code(
      P_Invoice_Type_Lookup_Code => P_Invoice_Header_Rec.invoice_type_lookup_code,
      P_Event_Class_Code         => P_event_class_code,
      P_error_code               => P_error_code,
      P_calling_sequence         => l_curr_calling_sequence)) THEN

      l_return_status := FALSE;

    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 2: Get event type code';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------

    IF (l_return_status = TRUE) THEN
      IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Type_Code(
        P_Event_Class_Code          => P_event_class_code,
        P_Calling_Mode              => P_Calling_Mode,
        P_eTax_Already_called_flag  => P_eTax_Already_called_flag,
        P_Event_Type_Code           => P_Event_Type_Code,
        P_Error_Code                => P_error_code,
        P_Calling_Sequence          => l_curr_calling_sequence)) THEN

        l_return_status := FALSE;
      END IF;
    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 3: Populate product specific attributes';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    l_application_id := 200;   -- Oracle Payables
    -- The same code is used for all invoice types.
    l_entity_code := 'AP_INVOICES';


    -------------------------------------------------------------------
    l_debug_info := 'Step 4: Populate tax related invoice information '||
                    'if tax_related_invoice_id is not null';

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF (l_return_status = TRUE AND
        P_Invoice_Header_Rec.tax_related_invoice_id IS NOT NULL) THEN
      l_related_inv_application_id := 200;  --Oracle Payables
      l_related_inv_entity_code := 'AP_INVOICES';


      BEGIN
        OPEN tax_related_invoice(P_Invoice_Header_Rec.tax_related_invoice_id);
        FETCH tax_related_invoice
          INTO l_related_inv_number, l_related_inv_type,
               l_related_inv_date;
        CLOSE tax_related_invoice;
      END;

      --------------------------------------------------------------------------
      l_debug_info := 'Step 5: Get event class code for tax_related_invoice_id';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      --------------------------------------------------------------------------
      IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Class_Code(
        P_Invoice_Type_Lookup_Code => l_related_inv_type,
        P_Event_Class_Code         => l_related_event_class_code,
        P_error_code               => P_error_code,
        P_calling_sequence         => l_curr_calling_sequence)) THEN

        l_return_status := FALSE;
      END IF;
    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 6: Set quote flag based on calling_mode';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF (p_calling_mode = 'CALCULATE QUOTE') THEN
      l_quote_flag := 'Y';

    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 7: Get transaction currency details';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF (l_return_status = TRUE) THEN
      BEGIN
        SELECT NVL(precision, 0), NVL(minimum_accountable_unit,(1/power(10,precision)))
          INTO l_precision, l_minimum_accountable_unit
          FROM fnd_currencies
         WHERE currency_code = P_Invoice_Header_Rec.invoice_currency_code;

      END;
    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 8: Get doc_sequence_name';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF (l_return_status = TRUE
        and p_invoice_header_rec.doc_sequence_id is not null) THEN
      BEGIN
        SELECT name
          INTO l_doc_seq_name
          FROM fnd_document_sequences
         WHERE doc_sequence_id = p_invoice_header_rec.doc_sequence_id;

      EXCEPTION
	WHEN OTHERS THEN
	     Null;
      END;
    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 9: Populate zx_trx_headers_gt';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF (l_return_status = TRUE) THEN

      DELETE FROM zx_trx_headers_gt
       WHERE application_id   = AP_ETAX_PKG.AP_APPLICATION_ID
         AND entity_code      = AP_ETAX_PKG.AP_ENTITY_CODE
         AND event_class_code IN (AP_ETAX_PKG.AP_INV_EVENT_CLASS_CODE,
                                  AP_ETAX_PKG.AP_PP_EVENT_CLASS_CODE,
                                  AP_ETAX_PKG.AP_ER_EVENT_CLASS_CODE)
         AND trx_id = p_invoice_header_rec.invoice_id;

      INSERT INTO zx_trx_headers_gt(
        internal_organization_id,
        internal_org_location_id,
        application_id,
        entity_code,
        event_class_code,
        event_type_code,
        trx_id,
        hdr_trx_user_key1,
        hdr_trx_user_key2,
        hdr_trx_user_key3,
        hdr_trx_user_key4,
        hdr_trx_user_key5,
        hdr_trx_user_key6,
        trx_date,
        trx_doc_revision,
        ledger_id,
        trx_currency_code,
        currency_conversion_date,
        currency_conversion_rate,
        currency_conversion_type,
        minimum_accountable_unit,
        precision,
        legal_entity_id,
        rounding_ship_to_party_id,
        rounding_ship_from_party_id,
        rounding_bill_to_party_id,
        rounding_bill_from_party_id,
        rndg_ship_to_party_site_id,
        rndg_ship_from_party_site_id,
        rndg_bill_to_party_site_id,
        rndg_bill_from_party_site_id,
        establishment_id,
        receivables_trx_type_id,
        related_doc_application_id,
        related_doc_entity_code,
        related_doc_event_class_code,
        related_doc_trx_id,
        rel_doc_hdr_trx_user_key1,
        rel_doc_hdr_trx_user_key2,
        rel_doc_hdr_trx_user_key3,
        rel_doc_hdr_trx_user_key4,
        rel_doc_hdr_trx_user_key5,
        rel_doc_hdr_trx_user_key6,
        related_doc_number,
        related_doc_date,
        default_taxation_country,
        quote_flag,
        ctrl_total_hdr_tx_amt,
        trx_number,
        trx_description,
        trx_communicated_date,
        batch_source_id,
        batch_source_name,
        doc_seq_id,
        doc_seq_name,
        doc_seq_value,
        trx_due_date,
        trx_type_description,
        document_sub_type,
        supplier_tax_invoice_number,
        supplier_tax_invoice_date,
        supplier_exchange_rate,
        tax_invoice_date,
        tax_invoice_number,
        tax_event_class_code,
        tax_event_type_code,
        doc_event_status,
        rdng_ship_to_pty_tx_prof_id,
        rdng_ship_from_pty_tx_prof_id,
        rdng_bill_to_pty_tx_prof_id,
        rdng_bill_from_pty_tx_prof_id,
        rdng_ship_to_pty_tx_p_st_id,
        rdng_ship_from_pty_tx_p_st_id,
        rdng_bill_to_pty_tx_p_st_id,
        rdng_bill_from_pty_tx_p_st_id,
        bill_third_pty_acct_id,
        bill_third_pty_acct_site_id,
	ship_third_pty_acct_id,
	ship_third_pty_acct_site_id
        ) VALUES (
        p_invoice_header_rec.org_id,                       --internal_organization_id
        NULL,                                              --internal_org_location_id
        l_application_id,                                  --application_id
        l_entity_code,                                     --entity_code
        P_event_class_code,                                --event_class_code
        P_event_type_code,                                 --event_type_code
        p_invoice_header_rec.invoice_id,                   --trx_id
        NULL,                                              --hdr_trx_user_key1
        NULL,                                              --hdr_trx_user_key2
        NULL,                                              --hdr_trx_user_key3
        NULL,                                              --hdr_trx_user_key4
        NULL,                                              --hdr_trx_user_key5
        NULL,                                              --hdr_trx_user_key6
        p_invoice_header_rec.invoice_date,                 --trx_date
        NULL,                                              --trx_doc_revision
        p_invoice_header_rec.set_of_books_id,              --ledger_id
        p_invoice_header_rec.invoice_currency_code,        --trx_currency_code
        p_invoice_header_rec.exchange_date,                --currency_conversion_date
        p_invoice_header_rec.exchange_rate,                --currency_conversion_rate
        p_invoice_header_rec.exchange_rate_type,           --currency_conversion_type
        l_minimum_accountable_unit,                        --minimum_accountable_unit
        l_precision,                                       --precision
        p_invoice_header_rec.legal_entity_id,              --legal_entity_id
        NULL,                                              --rounding_ship_to_party_id
        p_invoice_header_rec.party_id,                     --rounding_ship_from_party_id
        NULL,                                              --rounding_bill_to_party_id
        p_invoice_header_rec.party_id,                     --rounding_bill_from_party_id
        NULL,                                              --rndg_ship_to_party_site_id
        p_invoice_header_rec.party_site_id,                --rndg_ship_from_party_site_id
        NULL,                                              --rndg_bill_to_party_site_id
        p_invoice_header_rec.party_site_id,                --rndg_bill_from_party_site_id
        NULL,                                              --establishment_id
        NULL,                                              --receivables_trx_type_id
        l_related_inv_application_id,                      --related_doc_application_id
        l_related_inv_entity_code,                         --related_doc_entity_code
        l_related_event_class_code,                        --related_doc_event_class_code
        p_invoice_header_rec.tax_related_invoice_id,       --related_doc_trx_id
        NULL,                                              --rel_doc_hdr_trx_user_key1
        NULL,                                              --rel_doc_hdr_trx_user_key2
        NULL,                                              --rel_doc_hdr_trx_user_key3
        NULL,                                              --rel_doc_hdr_trx_user_key4
        NULL,                                              --rel_doc_hdr_trx_user_key5
        NULL,                                              --rel_doc_hdr_trx_user_key6
        l_related_inv_number,                              --related_doc_number
        l_related_inv_date,                                --related_doc_date
        p_invoice_header_rec.taxation_country,             --default_taxation_country
        l_quote_flag,                                      --quote_flag
        p_invoice_header_rec.control_amount,               --ctrl_total_hdr_tx_amt
        p_invoice_header_rec.invoice_num,                  --trx_number
        p_invoice_header_rec.description,                  --trx_description
        NULL,                                              --trx_communicated_date
        NULL,                                              --batch_source_id
        NULL,                                              --batch_source_name
        p_invoice_header_rec.doc_sequence_id,              --doc_seq_id
        l_doc_seq_name,            			   --doc_seq_name
        nvl(to_char(p_invoice_header_rec.doc_sequence_value),--bug6656894
	    p_invoice_header_rec.voucher_num),             --doc_seq_value
        NULL,                                              --trx_due_date
        NULL,                                              --trx_type_description
        p_invoice_header_rec.document_sub_type,            --document_sub_type
        p_invoice_header_rec.supplier_tax_invoice_number,  --supplier_tax_invoice_number
        p_invoice_header_rec.supplier_tax_invoice_date,    --supplier_tax_invoice_date
        p_invoice_header_rec.supplier_tax_exchange_rate,   --supplier_exchange_rate
        p_invoice_header_rec.tax_invoice_recording_date,   --tax_invoice_date
        p_invoice_header_rec.tax_invoice_internal_seq,     --tax_invoice_number
        NULL,                                              --tax_event_class_code
        NULL,                                              --tax_event_type_code
        NULL,                                              --doc_event_status
        NULL,                                              --rdng_ship_to_pty_tx_prof_id
        NULL,                                              --rdng_ship_from_pty_tx_prof_id
        NULL,                                              --rdng_bill_to_pty_tx_prof_id
        NULL,                                              --rdng_bill_from_pty_tx_prof_id
        NULL,                                              --rdng_ship_to_pty_tx_p_st_id
        NULL,                                              --rdng_ship_from_pty_tx_p_st_id
        NULL,                                              --rdng_bill_to_pty_tx_p_st_id
        NULL,                                              --rdng_bill_from_pty_tx_p_st_id
	p_invoice_header_rec.vendor_id,			   --bill_third_pty_acct_id
	p_invoice_header_rec.vendor_site_id,		   --bill_third_pty_acct_site_id
        p_invoice_header_rec.vendor_id,                    --ship_third_pty_acct_id
        p_invoice_header_rec.vendor_site_id                --ship_third_pty_acct_site_id
     );

     -- Global Variable g_invoices_to_process should be initialized right after
     -- the previous insert. No other sql statements must be placed after the
     -- insert because the sql rowcount will be reset. This variable is used in
     -- calculate_tax and determine_recovery.

     g_invoices_to_process := sql%rowcount;

     -- Added log messages for bug 6321366
     IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'zx_trx_headers_gt values ');
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'Application_id: '|| l_application_id);
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'Entity_code: ' || l_entity_code);
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'event_class_code: ' || P_event_class_code);
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'event_type_code: ' ||P_event_type_code);
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'Invoice_id: '|| p_invoice_header_rec.invoice_id);
     END IF;

   END IF;

   RETURN l_return_status;

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Header_Rec = '||P_Invoice_Header_Rec.Invoice_Id||
          ' P_Calling_Mode ='||P_Calling_Mode||
          ' P_Error_Code = '||P_Error_Code||
          ' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      IF ( tax_related_invoice%ISOPEN ) THEN
        CLOSE tax_related_invoice;
      END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;

  END Populate_Headers_GT;

/*=============================================================================
 |  FUNCTION - Populate_Header_Import_GT()
 |
 |  DESCRIPTION
 |    This function will get additional information required to populate the
 |    zx_trx_headers_gt from the import array structure.
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
             P_Calling_Sequence          IN VARCHAR2) RETURN BOOLEAN
  IS

    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);

    l_application_id             zx_trx_headers_gt.application_id%TYPE;
    l_entity_code                zx_trx_headers_gt.entity_code%TYPE;

    l_quote_flag                 zx_trx_headers_gt.quote_flag%TYPE
      := 'N';
    -- This flag is always N except when the calculate service is called for
    -- quote for the recurring invoices and distributions sets.

    CURSOR tax_related_invoice( c_tax_related_invoice_id IN NUMBER) IS
-- B# 6907814 ...  SELECT invoice_num, invoice_date, invoice_type_lookup_code
    SELECT invoice_num, invoice_type_lookup_code, invoice_date
      FROM ap_invoices_all
     WHERE invoice_id = c_tax_related_invoice_id;

    l_related_inv_application_id
      zx_trx_headers_gt.related_doc_application_id%TYPE;
    l_related_inv_entity_code
      zx_trx_headers_gt.related_doc_entity_code%TYPE;
    l_related_event_class_code
      zx_trx_headers_gt.related_doc_event_class_code%TYPE;
    l_related_inv_number         ap_invoices_all.invoice_num%TYPE;
    l_related_inv_date           ap_invoices_all.invoice_date%TYPE;
    l_related_inv_type           ap_invoices_all.invoice_type_lookup_code%TYPE;

    l_precision                  fnd_currencies.precision%TYPE := 0;
    l_minimum_accountable_unit   fnd_currencies.minimum_accountable_unit%TYPE;

    l_return_status              BOOLEAN := TRUE;
    l_api_name                  VARCHAR2(30) := 'populate_header_import_gt';

  BEGIN

    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.Populate_Header_Import_GT<-'||
                               P_calling_sequence;


    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_curr_calling_sequence);
    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 1: Get event class code';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------

    IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Class_Code(
      P_Invoice_Type_Lookup_Code => P_Invoice_Header_Rec.invoice_type_lookup_code,
      P_Event_Class_Code         => P_event_class_code,
      P_error_code               => P_error_code,
      P_calling_sequence         => l_curr_calling_sequence)) THEN

      l_return_status := FALSE;

    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 2: Get event type code';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    -- Since this procedure will be called only from the import program
    -- it is the first time eTax is call so the etax_already_called_flag is N

    IF (l_return_status = TRUE) THEN
      IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Type_Code(
        P_Event_Class_Code          => P_event_class_code,
        P_Calling_Mode              => P_Calling_Mode,
        P_eTax_Already_called_flag  => 'N',
        P_Event_Type_Code           => P_Event_Type_Code,
        P_Error_Code                => P_error_code,
        P_Calling_Sequence          => l_curr_calling_sequence)) THEN

        l_return_status := FALSE;
      END IF;
    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 3: Populate product specific attributes';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    l_application_id := 200;   -- Oracle Payables
    -- The same code is used for all invoice types.
    l_entity_code := 'AP_INVOICES';

    -------------------------------------------------------------------
    l_debug_info := 'Step 4: Populate tax related invoice information '||
                    'if tax_related_invoice_id is not null';

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF (l_return_status = TRUE AND
        P_Invoice_Header_Rec.tax_related_invoice_id IS NOT NULL) THEN

      -- At this moment we are sure the tax_related_invoice_id is valid.
      -- It was validated in the previous to this call in the import
      -- process.

      l_related_inv_application_id := 200;  --Oracle Payables
      l_related_inv_entity_code := 'AP_INVOICES';

      BEGIN
        OPEN tax_related_invoice(P_Invoice_Header_Rec.tax_related_invoice_id);
        FETCH tax_related_invoice
          INTO l_related_inv_number, l_related_inv_type,
               l_related_inv_date;
        CLOSE tax_related_invoice;
      END;

      --------------------------------------------------------------------------
      l_debug_info := 'Step 5: Get event class code for tax_related_invoice_id';

      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      --------------------------------------------------------------------------
      IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Class_Code(
        P_Invoice_Type_Lookup_Code => l_related_inv_type,
        P_Event_Class_Code         => l_related_event_class_code,
        P_error_code               => P_error_code,
        P_calling_sequence         => l_curr_calling_sequence)) THEN

        l_return_status := FALSE;
      END IF;
    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 6: Get transaction currency details';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF (l_return_status = TRUE) THEN
      BEGIN
        SELECT NVL(precision, 0), NVL(minimum_accountable_unit,(1/power(10,precision)))
          INTO l_precision, l_minimum_accountable_unit
          FROM fnd_currencies
         WHERE currency_code = P_Invoice_Header_Rec.invoice_currency_code;

      END;
    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 8: Populate zx_trx_headers_gt';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF (l_return_status = TRUE) THEN

      DELETE FROM zx_trx_headers_gt
       WHERE application_id   = AP_ETAX_PKG.AP_APPLICATION_ID
         AND entity_code      = AP_ETAX_PKG.AP_ENTITY_CODE
         AND event_class_code IN (AP_ETAX_PKG.AP_INV_EVENT_CLASS_CODE,
                                  AP_ETAX_PKG.AP_PP_EVENT_CLASS_CODE,
                                  AP_ETAX_PKG.AP_ER_EVENT_CLASS_CODE)
         AND trx_id = p_invoice_header_rec.invoice_id;

      INSERT INTO zx_trx_headers_gt(
        internal_organization_id,
        internal_org_location_id,
        application_id,
        entity_code,
        event_class_code,
        event_type_code,
        trx_id,
        hdr_trx_user_key1,
        hdr_trx_user_key2,
        hdr_trx_user_key3,
        hdr_trx_user_key4,
        hdr_trx_user_key5,
        hdr_trx_user_key6,
        trx_date,
        trx_doc_revision,
        ledger_id,
        trx_currency_code,
        currency_conversion_date,
        currency_conversion_rate,
        currency_conversion_type,
        minimum_accountable_unit,
        precision,
        legal_entity_id,
        rounding_ship_to_party_id,
        rounding_ship_from_party_id,
        rounding_bill_to_party_id,
        rounding_bill_from_party_id,
        rndg_ship_to_party_site_id,
        rndg_ship_from_party_site_id,
        rndg_bill_to_party_site_id,
        rndg_bill_from_party_site_id,
        establishment_id,
        receivables_trx_type_id,
        related_doc_application_id,
        related_doc_entity_code,
        related_doc_event_class_code,
        related_doc_trx_id,
        rel_doc_hdr_trx_user_key1,
        rel_doc_hdr_trx_user_key2,
        rel_doc_hdr_trx_user_key3,
        rel_doc_hdr_trx_user_key4,
        rel_doc_hdr_trx_user_key5,
        rel_doc_hdr_trx_user_key6,
        related_doc_number,
        related_doc_date,
        default_taxation_country,
        quote_flag,
        ctrl_total_hdr_tx_amt,
        trx_number,
        trx_description,
        trx_communicated_date,
        batch_source_id,
        batch_source_name,
        doc_seq_id,
        doc_seq_name,
        doc_seq_value,
        trx_due_date,
        trx_type_description,
        document_sub_type,
        supplier_tax_invoice_number,
        supplier_tax_invoice_date,
        supplier_exchange_rate,
        tax_invoice_date,
        tax_invoice_number,
        tax_event_class_code,
        tax_event_type_code,
        doc_event_status,
        rdng_ship_to_pty_tx_prof_id,
        rdng_ship_from_pty_tx_prof_id,
        rdng_bill_to_pty_tx_prof_id,
        rdng_bill_from_pty_tx_prof_id,
        rdng_ship_to_pty_tx_p_st_id,
        rdng_ship_from_pty_tx_p_st_id,
        rdng_bill_to_pty_tx_p_st_id,
        rdng_bill_from_pty_tx_p_st_id,
        bill_third_pty_acct_id,
        bill_third_pty_acct_site_id,
        ship_third_pty_acct_id,
	ship_third_pty_acct_site_id
        ) VALUES (
        p_invoice_header_rec.org_id,                       --internal_organization_id
        NULL,                                              --internal_org_location_id
        l_application_id,                                  --application_id
        l_entity_code,                                     --entity_code
        P_event_class_code,                                --event_class_code
        P_event_type_code,                                 --event_type_code
        p_invoice_header_rec.invoice_id,                   --trx_id
        NULL,                                              --hdr_trx_user_key1
        NULL,                                              --hdr_trx_user_key2
        NULL,                                              --hdr_trx_user_key3
        NULL,                                              --hdr_trx_user_key4
        NULL,                                              --hdr_trx_user_key5
        NULL,                                              --hdr_trx_user_key6
        p_invoice_header_rec.invoice_date,                 --trx_date
        NULL,                                              --trx_doc_revision
        p_invoice_header_rec.set_of_books_id,              --ledger_id
        p_invoice_header_rec.invoice_currency_code,        --trx_currency_code
        p_invoice_header_rec.exchange_date,                --currency_conversion_date
        p_invoice_header_rec.exchange_rate,                --currency_conversion_rate
        p_invoice_header_rec.exchange_rate_type,           --currency_conversion_type
        l_minimum_accountable_unit,                        --minimum_accountable_unit
        l_precision,                                       --precision
        p_invoice_header_rec.legal_entity_id,              --legal_entity_id
        NULL,                                              --rounding_ship_to_party_id
        p_invoice_header_rec.party_id,                     --rounding_ship_from_party_id
        NULL,                                              --rounding_bill_to_party_id
        p_invoice_header_rec.party_id,                     --rounding_bill_from_party_id
        NULL,                                              --rndg_ship_to_party_site_id
        p_invoice_header_rec.party_site_id,                --rndg_ship_from_party_site_id
        NULL,                                              --rndg_bill_to_party_site_id
        p_invoice_header_rec.party_site_id,                --rndg_bill_from_party_site_id
        NULL,                                              --establishment_id
        NULL, --receivables_trx_type_id
        l_related_inv_application_id, --related_doc_application_id
        l_related_inv_entity_code, --related_doc_entity_code
        l_related_event_class_code, --related_doc_event_class_code
        p_invoice_header_rec.tax_related_invoice_id,       --related_doc_trx_id
        NULL, --rel_doc_hdr_trx_user_key1
        NULL, --rel_doc_hdr_trx_user_key2
        NULL, --rel_doc_hdr_trx_user_key3
        NULL, --rel_doc_hdr_trx_user_key4
        NULL, --rel_doc_hdr_trx_user_key5
        NULL, --rel_doc_hdr_trx_user_key6
        l_related_inv_number,                              --related_doc_number
        l_related_inv_date,                                --related_doc_date
        p_invoice_header_rec.taxation_country, --default_taxation_country
        l_quote_flag,                                      --quote_flag
        p_invoice_header_rec.control_amount, --ctrl_total_hdr_tx_amt
        p_invoice_header_rec.invoice_num,                  --trx_number
        p_invoice_header_rec.description,                  --trx_description
        NULL, --trx_communicated_date
        NULL,                                              --batch_source_id
        NULL,                                              --batch_source_name
        NULL,                                              --doc_seq_id
        NULL,                                              --doc_seq_name
        NULL,                                              --doc_seq_value
        NULL,                                              --trx_due_date
        NULL, --trx_type_description
        p_invoice_header_rec.document_sub_type,            --document_sub_type
        p_invoice_header_rec.supplier_tax_invoice_number, --supplier_tax_invoice_number
        p_invoice_header_rec.supplier_tax_invoice_date, --supplier_tax_invoice_date
        p_invoice_header_rec.supplier_tax_exchange_rate, --supplier_exchange_rate
        p_invoice_header_rec.tax_invoice_recording_date,   --tax_invoice_date
        p_invoice_header_rec.tax_invoice_internal_seq,     --tax_invoice_number
        NULL, --tax_event_class_code
        NULL,                                              --tax_event_type_code
        NULL,                                              --doc_event_status
        NULL, --rdng_ship_to_pty_tx_prof_id
        NULL, --rdng_ship_from_pty_tx_prof_id
        NULL, --rdng_bill_to_pty_tx_prof_id
        NULL, --rdng_bill_from_pty_tx_prof_id
        NULL, --rdng_ship_to_pty_tx_p_st_id
        NULL, --rdng_ship_from_pty_tx_p_st_id
        NULL, --rdng_bill_to_pty_tx_p_st_id
        NULL, --rdng_bill_from_pty_tx_p_st_id
        p_invoice_header_rec.vendor_id,			   --bill_third_pty_acct_id
        p_invoice_header_rec.vendor_site_id,               --bill_third_pty_acct_site_id
        p_invoice_header_rec.vendor_id,                    --ship_third_pty_acct_id
        p_invoice_header_rec.vendor_site_id                --ship_third_pty_acct_site_id
     );
--Log messages added for bug 6321366
  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'zx_trx_headers_gt values ');
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'Application_id: '|| l_application_id);
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'Entity_code: ' || l_entity_code);
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'event_class_code: ' || P_event_class_code);
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'event_type_code: ' ||P_event_type_code);
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'Invoice_id: '|| p_invoice_header_rec.invoice_id);
  END IF;

   END IF;

   RETURN l_return_status;

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Header_Rec = '||P_Invoice_Header_Rec.Invoice_Id||
          ' P_Calling_Mode ='||P_Calling_Mode||
          ' P_Error_Code = '||P_Error_Code||
          ' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      IF ( tax_related_invoice%ISOPEN ) THEN
        CLOSE tax_related_invoice;
      END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;

  END Populate_Header_Import_GT;


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
 |      P_Line_Number - prepay line number to be unapplied.
 |      P_error_code - Error code to be returned
 |      P_calling_sequence -  Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    09-OCT-2003   SYIDNER        Created
 |    03-MAR-2004   SYIDNER        Including prepayment
 |                                 application/unapplication functionality
 |
 *============================================================================*/

  FUNCTION Populate_Lines_GT(
             P_Invoice_Header_Rec      IN ap_invoices_all%ROWTYPE,
             P_Calling_Mode            IN VARCHAR2,
             P_Event_Class_Code        IN VARCHAR2,
             P_Line_Number             IN NUMBER DEFAULT NULL,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN
  IS

    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);

    -- This structure to populate all the lines information previous to insert
    -- in eTax global temporary table.
    TYPE Trans_Lines_Tab_Type IS TABLE OF zx_transaction_lines_gt%ROWTYPE;
    trans_lines                    Trans_Lines_Tab_Type := Trans_Lines_Tab_Type();

    l_application_id               zx_trx_headers_gt.application_id%TYPE;
    l_ctrl_hdr_tx_appl_flag        zx_transaction_lines_gt.ctrl_hdr_tx_appl_flag%TYPE;
    l_line_level_action            zx_transaction_lines_gt.line_level_action%TYPE;
    l_line_class		   zx_transaction_lines_gt.line_class%TYPE;
    l_line_amt_includes_tax_flag   zx_transaction_lines_gt.line_amt_includes_tax_flag%TYPE;
    l_init_line_amt_incl_tax_fg    zx_transaction_lines_gt.line_amt_includes_tax_flag%TYPE;
    l_product_org_id               zx_transaction_lines_gt.product_org_id%TYPE;
    l_bill_to_location_id          zx_transaction_lines_gt.bill_to_location_id%TYPE;


    -- Purchase Order Info
    l_ref_doc_application_id      zx_transaction_lines_gt.ref_doc_application_id%TYPE;
    l_ref_doc_entity_code	  zx_transaction_lines_gt.ref_doc_entity_code%TYPE;
    l_ref_doc_event_class_code    zx_transaction_lines_gt.ref_doc_event_class_code%TYPE;
    l_ref_doc_line_quantity       zx_transaction_lines_gt.ref_doc_line_quantity%TYPE;
    l_po_header_curr_conv_rat     po_headers_all.rate%TYPE;
    l_ref_doc_trx_level_type      zx_transaction_lines_gt.ref_doc_trx_level_type%TYPE;
    l_po_header_curr_conv_rate    po_headers_all.rate%TYPE;
    l_uom_code			  mtl_units_of_measure.uom_code%TYPE;
    l_dummy			  number;


    -- Receipt Info
    l_applied_to_application_id    zx_transaction_lines_gt.applied_to_application_id%TYPE;
    l_applied_to_entity_code       zx_transaction_lines_gt.applied_to_entity_code%TYPE;
    l_applied_to_event_class_code  zx_transaction_lines_gt.applied_to_event_class_code%TYPE;
    l_trx_receipt_date             zx_transaction_lines_gt.trx_receipt_date%TYPE;
    l_ref_doc_trx_id               zx_transaction_lines_gt.ref_doc_trx_id%TYPE;

    -- Prepayment Info
    l_prepay_doc_application_id    zx_transaction_lines_gt.applied_from_application_id%TYPE;
    l_prepay_doc_entity_code       zx_transaction_lines_gt.applied_from_entity_code%TYPE;
    l_prepay_doc_event_class_code  zx_transaction_lines_gt.applied_from_event_class_code%TYPE;
    l_prepay_doc_number            ap_invoices_all.invoice_num%TYPE;
    l_prepay_doc_date              ap_invoices_all.invoice_date%TYPE;
    l_applied_from_trx_level_type  zx_transaction_lines_gt.applied_from_trx_level_type%TYPE;
    l_applied_from_trx_id	   zx_transaction_lines_gt.applied_from_trx_id%TYPE;
    l_applied_from_line_id         zx_transaction_lines_gt.applied_from_line_id%TYPE;

    -- Corrected Invoice Info
    l_adj_doc_application_id     zx_transaction_lines_gt.adjusted_doc_application_id%TYPE;
    l_adj_doc_entity_code	 zx_transaction_lines_gt.adjusted_doc_entity_code%TYPE;
    l_adj_doc_event_class_code   zx_transaction_lines_gt.adjusted_doc_event_class_code%TYPE;
    l_adj_doc_number             zx_transaction_lines_gt.adjusted_doc_number%TYPE;
    l_adj_doc_date               zx_transaction_lines_gt.adjusted_doc_date%TYPE;
    l_adj_doc_trx_level_type	 zx_transaction_lines_gt.adjusted_doc_trx_level_type%TYPE;

    l_fob_point                  po_vendor_sites_all.fob_lookup_code%TYPE;
    l_location_id		 zx_transaction_lines_gt.ship_from_location_id%type;

    l_dflt_tax_class_code       zx_transaction_lines_gt.input_tax_classification_code%type;
    l_allow_tax_code_override   varchar2(10);

    l_intended_use		zx_lines_det_factors.line_intended_use%type;
    l_product_type		zx_lines_det_factors.product_type%type;
    l_product_category		zx_lines_det_factors.product_category%type;
    l_product_fisc_class	zx_lines_det_factors.product_fisc_classification%type;
    l_user_defined_fisc_class	zx_lines_det_factors.user_defined_fisc_class%type;
    l_assessable_value		zx_lines_det_factors.assessable_value%type;

    l_default_ccid      	ap_invoice_lines_all.default_dist_ccid%TYPE; --Bug6908977

    l_return_status             BOOLEAN := TRUE;

    l_api_name                  VARCHAR2(30) := 'Populate_Lines_GT';
    l_tax_already_calculated_line  VARCHAR2(1);

    l_ship_to_party_id          po_line_locations_all.ship_to_organization_id%type; -- 7262269

     l_err varchar2(2000); --10140354
  BEGIN

    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.Populate_Lines_GT<-' ||
                               P_calling_sequence;

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_curr_calling_sequence);
    END IF;

    --Bug13899981    Added Debug Messages
    ----------------------------------------------------------------------
    l_debug_info := 'Populate Lines - Invoice Id '||p_invoice_header_rec.invoice_id;
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    --Print(l_api_name,l_debug_info);
    ----------------------------------------------------------------------

    ----------------------------------------------------------------------
    l_debug_info := 'Set line defaults from cache';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    --Print(l_api_name,l_debug_info);
    ----------------------------------------------------------------------

    ----------------------------------------------------------------------
    l_debug_info := 'Cache Index : Supplier Site '||p_invoice_header_rec.vendor_site_id;
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    --Print(l_api_name,l_debug_info);
    ----------------------------------------------------------------------

    ----------------------------------------------------------------------
    l_debug_info := 'Cache Index : Party Site '||p_invoice_header_rec.party_site_id;
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    --Print(l_api_name,l_debug_info);
    ----------------------------------------------------------------------

    ----------------------------------------------------------------------
    l_debug_info := 'Cache Index : Org Id '||p_invoice_header_rec.org_id;
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    --Print(l_api_name,l_debug_info);
    ----------------------------------------------------------------------

    IF l_payment_request_flag ='N' THEN ---for bug 5967914

       ----------------------------------------------------------------------
       l_debug_info := 'Non Payment Request Invoice : Populate FOB Point';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
       --Print(l_api_name,l_debug_info);
       ----------------------------------------------------------------------

        l_fob_point            := AP_ETAX_SERVICES_PKG.g_site_attributes
					(p_invoice_header_rec.vendor_site_id).fob_lookup_code;
    END IF;

    IF l_payment_request_flag ='Y' THEN ---if condition added for bug 5967914

       ----------------------------------------------------------------------
       l_debug_info := 'Payment Request Invoice : Populate Location Id';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
       --Print(l_api_name,l_debug_info);
       ----------------------------------------------------------------------

       l_location_id         := AP_ETAX_SERVICES_PKG.g_site_attributes
					(p_invoice_header_rec.party_site_id).location_id;
    ELSE

       ----------------------------------------------------------------------
       l_debug_info := 'Non Payment Request Invoice : Populate Location Id';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
       --Print(l_api_name,l_debug_info);
       ----------------------------------------------------------------------

       l_location_id         := AP_ETAX_SERVICES_PKG.g_site_attributes
					(p_invoice_header_rec.vendor_site_id).location_id;
    END IF;


    ----------------------------------------------------------------------
    l_debug_info := 'For every invoice : Populate Bill To Location Id';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    --Print(l_api_name,l_debug_info);
    ----------------------------------------------------------------------
    --Bug13899981    Added Debug Messages

    l_bill_to_location_id := AP_ETAX_SERVICES_PKG.g_org_attributes
					(p_invoice_header_rec.org_id).bill_to_location_id;

    ----------------------------------------------------------------------
    l_debug_info := 'Go through taxable lines';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    ----------------------------------------------------------------------

    IF ( l_inv_line_list.COUNT > 0) THEN
      -- For non-tax only lines
      trans_lines.EXTEND(l_inv_line_list.COUNT);
      FOR i IN l_inv_line_list.FIRST..l_inv_line_list.LAST LOOP
        -------------------------------------------------------------------
         l_debug_info := 'Get line_level_action for line number: '||l_inv_line_list(i).line_number;
         IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
         END IF;
        -------------------------------------------------------------------
        IF (l_return_status = TRUE) THEN
         IF ( P_calling_mode = 'OVERRIDE TAX' ) THEN
           l_line_level_action := 'NO_CHANGE';

         ELSIF (l_inv_line_list(i).line_type_lookup_code = 'PREPAY'
                or p_calling_mode = 'RECOUPMENT') THEN

           -- The treatment of PREPAY lines is different from a regular
           -- line.  We will differienciate the PREPAY line created
           -- for the prepayment application if no tax has been canculated
           -- for it since we call calculate tax during the prepayment
           -- application.
           -- Since the prepayment unapplication will discard the PREPAY
           -- line created during the application, there is no way to
           -- identify the PREPAY line to unapply if there is more than
           -- one unapplied PREPAY lines in the invoice.  For this reason
           -- the parameter used to calculate tax per line will be used.

           IF (P_calling_mode = 'APPLY PREPAY' or p_calling_mode = 'RECOUPMENT') THEN
             IF (NVL(l_inv_line_list(i).tax_already_calculated_flag, 'N') = 'N'
		 or p_calling_mode = 'RECOUPMENT') THEN
               l_line_level_action := 'APPLY_FROM';

             ELSE
               l_line_level_action := 'NO_CHANGE';

             END IF;

           ELSIF (P_calling_mode = 'UNAPPLY PREPAY') THEN
             IF (l_inv_line_list(i).line_number = p_line_number) THEN
                l_line_level_action := 'UNAPPLY_FROM';

             ELSE
               l_line_level_action := 'NO_CHANGE';

             END IF;
           ELSE
             l_line_level_action := 'NO_CHANGE';

           END IF;

         ELSIF ( NVL(l_inv_line_list(i).discarded_flag, 'N') = 'Y'
                 OR NVL(l_inv_line_list(i).cancelled_flag, 'N') = 'Y') THEN

               -- Bug 7444234
               -- line_level_action as DISCARD irrespective of migrated
               -- transaction.

               l_line_level_action := 'DISCARD';

	       --IF NVL(l_inv_line_list(i).historical_flag, 'N') = 'Y' THEN
	       --   l_line_level_action := 'UPDATE';
	       --ELSE
               --   l_line_level_action := 'DISCARD';
	       --END IF;

	/*  --Bug12660669 Added source, invoice type and line type check */
         ELSIF (P_Invoice_Header_Rec.source = 'SelfService' AND
		        P_Invoice_Header_Rec.invoice_type_lookup_code = 'EXPENSE REPORT' AND
                l_inv_line_list(i).line_type_lookup_code = 'MISCELLANEOUS' ) THEN
		--Bug16362966: Start
                --l_line_level_action := 'NO_CHANGE' ;
                IF (NVL(l_inv_line_list(i).tax_already_calculated_flag, 'N') = 'N') THEN
	           l_line_level_action := 'RECORD_WITH_NO_TAX' ;
                ELSE
                   l_line_level_action := 'NO_CHANGE';
                END IF;
                --Bug16362966: End
         ELSIF (NVL(l_inv_line_list(i).tax_already_calculated_flag, 'N') = 'Y') THEN
	      -- Bug 9068689
	      IF ( l_inv_line_list(i).included_tax_amount IS NOT NULL AND -- Bug 9526592 : Added this condition
	           NOT AP_ETAX_UTILITY_PKG.Is_Incl_Tax_Driver_Updatable(
                                p_invoice_id        => l_inv_line_list(i).invoice_id,
                                p_line_number       => l_inv_line_list(i).line_number,
                                p_calling_sequence  => l_curr_calling_sequence ) )
              THEN
		  l_line_level_action := 'NO_CHANGE' ;
              ELSE
      -- Start for bug 6485124
                  l_line_level_action := 'UPDATE';
	      END IF ;
         ELSE
            BEGIN
              SELECT 'Y'
              INTO   l_tax_already_calculated_line
              FROM   zx_lines_det_factors
              WHERE  application_id        =  200
              AND    entity_code           =  'AP_INVOICES'
              AND    event_class_code      IN ('STANDARD INVOICES', 'PREPAYMENT INVOICES', 'EXPENSE REPORTS')
              AND    trx_id                = l_inv_line_list(i).invoice_id
              AND    trx_line_id           = l_inv_line_list(i).line_number
              AND    ROWNUM = 1;

               IF l_tax_already_calculated_line = 'Y' THEN
                  l_line_level_action := 'UPDATE';
               ELSE
                  l_line_level_action := 'CREATE';
               END IF;
             EXCEPTION
                WHEN NO_DATA_FOUND  THEN
                     l_line_level_action := 'CREATE';
                WHEN OTHERS THEN
                     RAISE;
             END;
      -- End for bug 6485124
          END IF;

         -------------------------------------------------------------------
          l_debug_info := 'Get Additional PO matched  info';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
         -------------------------------------------------------------------

         IF ( l_inv_line_list(i).po_line_location_id IS NOT NULL AND
              l_inv_line_list(i).line_type_lookup_code NOT IN ('MISCELLANEOUS','FREIGHT')) THEN   --Bug14039130

           IF NOT (AP_ETAX_UTILITY_PKG.Get_PO_Info(
              P_Po_Line_Location_Id         => l_inv_line_list(i).po_line_location_id,
              P_PO_Distribution_Id          => null,
              P_Application_Id              => l_ref_doc_application_id,
              P_Entity_code                 => l_ref_doc_entity_code,
              P_Event_Class_Code            => l_ref_doc_event_class_code,
              P_PO_Quantity                 => l_ref_doc_line_quantity,
              P_Product_Org_Id              => l_product_org_id,
              P_Po_Header_Id                => l_ref_doc_trx_id,
              P_Po_Header_curr_conv_rate    => l_po_header_curr_conv_rate,
	          P_Uom_Code		            => l_uom_code,
              P_Dist_Qty                    => l_dummy,
              P_Ship_Price                  => l_dummy,
              P_Error_Code                  => P_error_code,
              P_Calling_Sequence            => l_curr_calling_sequence)) THEN

		--Bug15914464: Start
             IF AP_APPROVAL_PKG.G_VALIDATION_REQUEST_ID IS NULL THEN
               APP_EXCEPTION.RAISE_EXCEPTION;
             ELSE
			  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Error in AP_ETAX_UTILITY_PKG.Get_PO_Info');
              END IF;
		--Bug15914464: End
              --bug10140354
	          Insert into ap_errors_gt(invoice_id , message_text) values(P_Invoice_Header_Rec.invoice_id , 'Error in Get_po_info');
	          l_return_status := FALSE;
			  RETURN l_return_status; --Bug15914464
			 END IF; --Bug15914464
           END IF;

	   l_ref_doc_trx_level_type := 'SHIPMENT';

         ELSE
            l_ref_doc_application_id	 := Null;
            l_ref_doc_entity_code	 := Null;
            l_ref_doc_event_class_code   := Null;
            l_ref_doc_line_quantity      := Null;
            l_product_org_id		 := Null;
            l_ref_doc_trx_id		 := Null;
            l_ref_doc_trx_level_type	 := Null;
            l_uom_code			 := Null;
         END IF;

         -------------------------------------------------------------------
          l_debug_info := 'Get Additional receipt matched info ';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
         -------------------------------------------------------------------
         IF ( l_return_status = TRUE AND
              l_inv_line_list(i).rcv_transaction_id IS NOT NULL AND
              l_inv_line_list(i).line_type_lookup_code NOT IN ('MISCELLANEOUS','FREIGHT')) THEN --Bug14039130
           IF NOT (AP_ETAX_UTILITY_PKG.Get_Receipt_Info(
              P_Rcv_Transaction_Id          => l_inv_line_list(i).rcv_transaction_id,
              P_Application_Id              => l_applied_to_application_id,
              P_Entity_code                 => l_applied_to_entity_code,
              P_Event_Class_Code            => l_applied_to_event_class_code,
              P_Transaction_Date            => l_trx_receipt_date,
              P_Error_Code                  => P_error_code,
              P_Calling_Sequence            => l_curr_calling_sequence)) THEN

		--Bug15914464: Start
             IF AP_APPROVAL_PKG.G_VALIDATION_REQUEST_ID IS NULL THEN
               APP_EXCEPTION.RAISE_EXCEPTION;
             ELSE
			  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Error in AP_ETAX_UTILITY_PKG.Get_Receipt_Info');
              END IF;
		--Bug15914464: End
              --bug10140354
	          Insert into ap_errors_gt(invoice_id , message_text) values(P_Invoice_Header_Rec.invoice_id , 'Error in Get_Receipt_Info');
	          l_return_status := FALSE;
			  RETURN l_return_status; --Bug15914464
			 END IF; --Bug15914464
           END IF;
         ELSE
	    l_applied_to_application_id   := Null;
            l_applied_to_entity_code      := Null;
            l_applied_to_event_class_code := Null;
	    l_trx_receipt_date		  := Null;
         END IF;

         -------------------------------------------------------------------
          l_debug_info := 'Get Additional Prepayment Application Info';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
         -------------------------------------------------------------------

         IF (l_return_status = TRUE) THEN
	     IF (l_inv_line_list(i).prepay_invoice_id IS NOT NULL AND
                 l_inv_line_list(i).prepay_line_number IS NOT NULL) THEN

	         IF NOT (AP_ETAX_UTILITY_PKG.Get_Prepay_Invoice_Info(
			              P_Prepay_Invoice_Id           => l_inv_line_list(i).prepay_invoice_id,
			              P_Prepay_Line_Number          => l_inv_line_list(i).prepay_line_number,
			              P_Application_Id              => l_prepay_doc_application_id,
			              P_Entity_code                 => l_prepay_doc_entity_code,
			              P_Event_Class_Code            => l_prepay_doc_event_class_code,
			              P_Invoice_Number              => l_prepay_doc_number,
			              P_Invoice_Date                => l_prepay_doc_date,
			              P_Error_Code                  => P_error_code,
			              P_Calling_Sequence            => l_curr_calling_sequence)) THEN

		--Bug15914464: Start
             IF AP_APPROVAL_PKG.G_VALIDATION_REQUEST_ID IS NULL THEN
              APP_EXCEPTION.RAISE_EXCEPTION;
             ELSE
			  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Error in AP_ETAX_UTILITY_PKG.Get_Prepay_Invoice_Info');
              END IF;
		--Bug15914464: End
              --bug10140354
	          Insert into ap_errors_gt(invoice_id , message_text) values(P_Invoice_Header_Rec.invoice_id , 'Error in Get_Prepay_Invoice_Info');
	          l_return_status := FALSE;
			  RETURN l_return_status; --Bug15914464
			 END IF; --Bug15914464
		END IF;

		l_applied_from_trx_id         := l_inv_line_list(i).prepay_invoice_id;
		l_applied_from_line_id        := l_inv_line_list(i).prepay_line_number;
		l_applied_from_trx_level_type := 'LINE';

	    ELSIF p_calling_mode = 'RECOUPMENT' THEN

                  IF NOT (AP_ETAX_UTILITY_PKG.Get_Prepay_Invoice_Info(
                                      P_Prepay_Invoice_Id           => l_inv_line_list(i).invoice_id,
                                      P_Prepay_Line_Number          => l_inv_line_list(i).line_number,
                                      P_Application_Id              => l_prepay_doc_application_id,
                                      P_Entity_code                 => l_prepay_doc_entity_code,
                                      P_Event_Class_Code            => l_prepay_doc_event_class_code,
                                      P_Invoice_Number              => l_prepay_doc_number,
                                      P_Invoice_Date                => l_prepay_doc_date,
                                      P_Error_Code                  => P_error_code,
                                      P_Calling_Sequence            => l_curr_calling_sequence)) THEN

		--Bug15914464: Start
             IF AP_APPROVAL_PKG.G_VALIDATION_REQUEST_ID IS NULL THEN
              APP_EXCEPTION.RAISE_EXCEPTION;
             ELSE
			  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Error in AP_ETAX_UTILITY_PKG.Get_Prepay_Invoice_Info');
              END IF;
	      Insert into ap_errors_gt(invoice_id , message_text) values(P_Invoice_Header_Rec.invoice_id , 'Error in Get_Prepay_Invoice_Info');
	      --Bug15914464: End
	          l_return_status := FALSE;
			  RETURN l_return_status; --Bug15914464
			 END IF; --Bug15914464
                  END IF;

                  l_applied_from_trx_id         := l_inv_line_list(i).invoice_id;
                  l_applied_from_line_id        := l_inv_line_list(i).line_number;
                  l_applied_from_trx_level_type := 'LINE';

	    ELSE
	       l_prepay_doc_application_id   := Null;
	       l_prepay_doc_entity_code      := Null;
	       l_prepay_doc_event_class_code := Null;
	       l_prepay_doc_number           := Null;
	       l_prepay_doc_date             := Null;
	       l_applied_from_trx_level_type := Null;
               l_applied_from_trx_id         := Null;
               l_applied_from_line_id        := Null;
	    END IF;
        END IF;

         -------------------------------------------------------------------
          l_debug_info := 'Get Additional Correction Invoice Info ';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
         -------------------------------------------------------------------

         IF ( l_return_status = TRUE AND
              l_inv_line_list(i).corrected_inv_id IS NOT NULL AND
              l_inv_line_list(i).corrected_line_number IS NOT NULL) THEN

           IF NOT (AP_ETAX_UTILITY_PKG.Get_Corrected_Invoice_Info(
              P_Corrected_Invoice_Id        => l_inv_line_list(i).corrected_inv_id,
              P_Corrected_Line_Number       => l_inv_line_list(i).corrected_line_number,
              P_Application_Id              => l_adj_doc_application_id,
              P_Entity_code                 => l_adj_doc_entity_code,
              P_Event_Class_Code            => l_adj_doc_event_class_code,
              P_Invoice_Number              => l_adj_doc_number,
              P_Invoice_Date                => l_adj_doc_date,
              P_Error_Code                  => P_error_code,
              P_Calling_Sequence            => l_curr_calling_sequence)) THEN

		--Bug15914464: Start
             IF AP_APPROVAL_PKG.G_VALIDATION_REQUEST_ID IS NULL THEN
              APP_EXCEPTION.RAISE_EXCEPTION;
             ELSE
			  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Error in AP_ETAX_UTILITY_PKG.Get_Corrected_Invoice_Info');
              END IF;
		--Bug15914464: End
              --bug10140354
	          Insert into ap_errors_gt(invoice_id , message_text) values(P_Invoice_Header_Rec.invoice_id , 'Error in Get_Corrected_Invoice_Info');
	          l_return_status := FALSE;
			  RETURN l_return_status; --Bug15914464
			 END IF; --Bug15914464
          END IF;

          l_adj_doc_trx_level_type := 'LINE';

         ELSE
            l_adj_doc_application_id   := Null;
            l_adj_doc_entity_code      := Null;
            l_adj_doc_event_class_code := Null;
            l_adj_doc_number	       := Null;
            l_adj_doc_date             := Null;
	    l_adj_doc_trx_level_type   := Null;
         END IF;

         -------------------------------------------------------------------
          l_debug_info := 'Get line_amt_includes_tax_flag';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
         -------------------------------------------------------------------

         IF (l_inv_line_list(i).po_line_location_id IS NOT NULL) THEN
           -- NONE
           l_line_amt_includes_tax_flag := 'N';

         ELSE
           IF (p_calling_mode = 'CALCULATE QUOTE')
              OR
              (p_invoice_header_rec.invoice_type_lookup_code = 'EXPENSE REPORT'
               and nvl(l_inv_line_list(i).line_type_lookup_code, 'N') <> 'PREPAY') THEN
             -- ALL
             l_line_amt_includes_tax_flag := 'A';

           ELSE
             -- STANDARD
             l_line_amt_includes_tax_flag := 'S';

           END IF;
         END IF;

	 BEGIN
              IF (l_inv_line_list(i).tax_already_calculated_flag = 'Y') THEN

		 SELECT /*+ index(ZX_LINES_DET_FACTORS ZX_LINES_DET_FACTORS_U1) */  -- 9373895
		        line_amt_includes_tax_flag
		   INTO l_init_line_amt_incl_tax_fg
		   FROM zx_lines_det_factors
		  WHERE application_id = 200
		    AND entity_code    = 'AP_INVOICES'
		    AND event_class_code IN ('STANDARD INVOICES', 'PREPAYMENT INVOICES', 'EXPENSE REPORTS')
		    AND trx_id         = l_inv_line_list(i).invoice_id
		    AND trx_line_id    = l_inv_line_list(i).line_number
		    AND rownum         = 1;

		IF l_init_line_amt_incl_tax_fg IS NOT NULL THEN
		   l_line_amt_includes_tax_flag := l_init_line_amt_incl_tax_fg;
		END IF;

	      END IF;
         EXCEPTION
		WHEN OTHERS THEN
			NULL;
	 END;

         -------------------------------------------------------------------
          l_debug_info := 'Get ctrl_hdr_tx_appl_flag';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
         -------------------------------------------------------------------
         IF P_Invoice_Header_Rec.control_amount IS NOT NULL THEN
           l_ctrl_hdr_tx_appl_flag := 'Y';
         ELSE
           l_ctrl_hdr_tx_appl_flag := 'N';
         END IF;

         -------------------------------------------------------------------
          l_debug_info := 'Get line_class';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
         -------------------------------------------------------------------

         IF (l_return_status = TRUE) THEN

	      IF NOT (AP_ETAX_UTILITY_PKG.Get_Line_Class(
		             P_Invoice_Type_Lookup_Code    => P_Invoice_Header_Rec.invoice_type_lookup_code,
		             P_Inv_Line_Type               => l_inv_line_list(i).line_type_lookup_code,
		             P_Line_Location_Id            => l_inv_line_list(i).po_line_location_id,
		             P_Line_Class                  => l_line_class,
		             P_Error_Code                  => P_error_code,
		             P_Calling_Sequence            => l_curr_calling_sequence)) THEN

	     --Bug15914464: Start
             IF AP_APPROVAL_PKG.G_VALIDATION_REQUEST_ID IS NULL THEN
              APP_EXCEPTION.RAISE_EXCEPTION;
             ELSE
			  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Error in AP_ETAX_UTILITY_PKG.Get_Line_Class');
              END IF;
	      Insert into ap_errors_gt(invoice_id , message_text) values(P_Invoice_Header_Rec.invoice_id , 'Error in Get_Line_Class');
		--Bug15914464: End
	          l_return_status := FALSE;
			  RETURN l_return_status; --Bug15914464
			 END IF; --Bug15914464
             END IF;
         END IF;

       --Bug6908977 STARTS
       IF l_inv_line_list(i).match_type IN --Bug6965650
         ('ITEM_TO_PO','ITEM_TO_RECEIPT','ITEM_TO_SERVICE_PO',
          'ITEM_TO_SERVICE_RECEIPT','PRICE_CORRECTION','QTY_CORRECTION',
          'AMOUNT_CORRECTION') THEN

          IF  l_inv_line_list(i).po_line_location_id IS NOT NULL THEN

              SELECT pd.code_combination_id
                INTO l_default_ccid
                FROM po_distributions_all pd
               WHERE pd.line_location_id = l_inv_line_list(i).po_line_location_id
                 AND rownum = 1;

	      /* Bug 8230574
	         If the account on the Invoice Line is already populated and
		 it is different from that being defaulted from the PO then
		 retain the line level account....else use the defaulting
		 from PO. */

		 IF l_inv_line_list(i).default_dist_ccid IS NOT NULL AND
                    l_inv_line_list(i).default_dist_ccid <> l_default_ccid THEN

		      null; -- retain the Invoice line cc_id

                      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                                 '1 Retaining the Line level cc_id '||l_inv_line_list(i).default_dist_ccid);
                      END IF;

		 ELSE
                      l_inv_line_list(i).default_dist_ccid:=l_default_ccid;

                      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                                 '1 Default CCID passed from PO '||l_default_ccid);
                      END IF;

		 END IF;

          ELSIF l_inv_line_list(i).po_distribution_id IS NOT NULL THEN

              SELECT pd.code_combination_id
                INTO l_default_ccid
                FROM po_distributions_all pd
               WHERE pd.line_location_id =
                    (SELECT pod.line_location_id
                       FROM po_distributions_all pod
                      WHERE po_distribution_id = l_inv_line_list(i).po_distribution_id)
                 AND rownum = 1;

	      /* Bug 8230574
	         If the account on the Invoice Line is already populated and
		 it is different from that being defaulted from the PO then
		 retain the line level account....else use the defaulting
		 from PO. */

		 IF l_inv_line_list(i).default_dist_ccid IS NOT NULL AND
                    l_inv_line_list(i).default_dist_ccid <> l_default_ccid THEN

		      null; -- retain the Invoice line cc_id

                      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                                 '3 Retaining the Line level cc_id '||l_inv_line_list(i).default_dist_ccid);
                      END IF;

		 ELSE
                      l_inv_line_list(i).default_dist_ccid:=l_default_ccid;

                      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                                 '3 Default CCID passed from PO '||l_default_ccid);
                      END IF;

		 END IF;

          ELSIF l_inv_line_list(i).rcv_shipment_line_id IS NOT NULL THEN

              SELECT pd.code_combination_id
                INTO l_default_ccid
                FROM po_distributions_all pd
               WHERE pd.line_location_id =
                     (SELECT rcv.po_line_location_id
                        FROM rcv_shipment_lines rcv
                       WHERE rcv.shipment_line_id = l_inv_line_list(i).rcv_shipment_line_id)
                 AND rownum = 1;

	      /* Bug 8230574
	         If the account on the Invoice Line is already populated and
		 it is different from that being defaulted from the PO then
		 retain the line level account....else use the defaulting
		 from PO. */

		 IF l_inv_line_list(i).default_dist_ccid IS NOT NULL AND
                    l_inv_line_list(i).default_dist_ccid <> l_default_ccid THEN

		      null; -- retain the Invoice line cc_id

                      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                                 '4 Retaining the Line level cc_id '||l_inv_line_list(i).default_dist_ccid);
                      END IF;

		 ELSE
                      l_inv_line_list(i).default_dist_ccid:=l_default_ccid;

                      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                                 '4 Default CCID passed from PO '||l_default_ccid);
                      END IF;

		 END IF;

          ELSIF l_inv_line_list(i).rcv_transaction_id IS NOT NULL THEN

              SELECT pd.code_combination_id
                INTO l_default_ccid
                FROM po_distributions_all pd
               WHERE pd.line_location_id =
                     (SELECT rcv.po_line_location_id
                        FROM rcv_transactions rcv
                       WHERE rcv.transaction_id = l_inv_line_list(i).rcv_transaction_id)
                 AND rownum = 1;


	      /* Bug 8230574
	         If the account on the Invoice Line is already populated and
		 it is different from that being defaulted from the PO then
		 retain the line level account....else use the defaulting
		 from PO. */

		 IF l_inv_line_list(i).default_dist_ccid IS NOT NULL AND
                    l_inv_line_list(i).default_dist_ccid <> l_default_ccid THEN

		      null; -- retain the Invoice line cc_id

                      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                                 '5 Retaining the Line level cc_id '||l_inv_line_list(i).default_dist_ccid);
                      END IF;

		 ELSE
                      l_inv_line_list(i).default_dist_ccid:=l_default_ccid;

                      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                                 '5 Default CCID passed from PO '||l_default_ccid);
                      END IF;

		 END IF;

          ELSE
              IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                  FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                                 '6 Default CCID passed from line rather than of PO Distribution');
              END IF;
          END IF;

  /* Bug 12909089 starts */
ELSE
    IF (l_inv_line_list(i).line_type_lookup_code <> 'PREPAY' AND
	        P_Invoice_Header_Rec.invoice_type_lookup_code <> 'EXPENSE REPORT') THEN
    	  IF (l_inv_line_list(i).default_dist_ccid IS NOT NULL) THEN
    	          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                                               '6 CCID is taken from Line: '||l_default_ccid);
                   END IF;

		   NULL;
    	  ELSE

         		BEGIN

         		 SELECT aid.dist_code_combination_id
         		   INTO l_inv_line_list(i).default_dist_ccid
                         FROM ap_invoice_distributions_all aid
         		  WHERE aid.invoice_id = l_inv_line_list(i).invoice_id
         		    AND aid.invoice_line_number =  l_inv_line_list(i).line_number
					AND ROWNUM = 1;

    	                  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                                                '7 CCID is taken from Distribution: '||l_default_ccid);
                          END IF;

                       EXCEPTION
                        WHEN NO_DATA_FOUND THEN
    	                  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                                               '8 CCID is NULL: '||l_default_ccid);
                          END IF;
                       END;

		 /*Bug 13399833: Begins*/
		      IF l_inv_line_list(i).project_id IS NOT NULL
		       AND l_inv_line_list(i).default_dist_ccid IS NULL then

			 IF NOT(AP_ETAX_UTILITY_PKG.GET_CCID_FROM_PROJECTS(p_invoice_id => l_inv_line_list(i).invoice_id ,
                                                        p_line_number =>l_inv_line_list(i).line_number ,
     				                        p_ccid => l_inv_line_list(i).default_dist_ccid,
							p_error_message  => P_Error_Code   /*Bug 16842904*/)) THEN

			         --Bug15914464: Start
                                 IF AP_APPROVAL_PKG.G_VALIDATION_REQUEST_ID IS NULL THEN
                                   /*APP_EXCEPTION.RAISE_EXCEPTION;*/    /*Commented for Bug 16842904*/
				   /*Start of Bug 16842904*/
				   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                                       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,P_Error_Code||' Validation:Error while retriving the ccid from projects');
                                    END IF;
				   l_return_status := FALSE;
				   RETURN l_return_status;
				   /*End of Bug 16842904*/
                                 ELSE
                                 --Bug15914464: End
                                    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                                       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,P_Error_Code||'Error while retriving the ccid from projects');   /*Bug 16842904*/
                                    END IF;
	                            Insert into ap_errors_gt(invoice_id , message_text) values(P_Invoice_Header_Rec.invoice_id , P_Error_code||'Error in get_ccid_from_projects'); /*Bug 16842904*/
				    l_return_status := FALSE;
		                    RETURN l_return_status; --Bug15914464
			        END IF; --Bug15914464
                         END IF;
		      END IF;
		     /*Bug 13399833 end*/

          END IF;
    END IF;
  /* Bug 12909089 ends */
  END IF;
      --Bug6908977 ENDS

      -- bug7350421
      IF (l_inv_line_list(i).default_dist_ccid IS NULL AND
          l_inv_line_list(i).line_type_lookup_code <> 'PREPAY') THEN

         BEGIN

          SELECT aerd.code_combination_id
            INTO l_inv_line_list(i).default_dist_ccid
            FROM ap_exp_report_dists_all aerd,
                 ap_expense_report_lines_all aerl,
                 ap_invoices_all ai
           WHERE aerd.report_header_id = l_inv_line_list(i).reference_key1
             AND aerd.report_line_id = l_inv_line_list(i).reference_key2
             AND aerd.report_line_id = aerl.report_line_id
             AND aerd.report_header_id = aerl.report_header_id
             AND ai.invoice_id = l_inv_line_list(i).invoice_id
             AND ai.invoice_type_lookup_code = 'EXPENSE REPORT'
             AND rownum = 1;

         EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;

       END IF;

      --
      -- Bug 5565310: Commented out the below code as this is replaced by
      --              code in matching packages and in invoice workbench.
      --
      -- Bug 5605359: Enabled the code only for invoices created from ISP.
      --              Ideally the tax determining attributes should be
      --              added to the ISP UI instead of defaulting here.
      --

      IF  P_Invoice_Header_Rec.source = 'ISP' THEN

        IF  (l_inv_line_list(i).po_header_id         IS NOT NULL AND
             l_inv_line_list(i).po_line_location_id  IS NOT NULL AND
             l_inv_line_list(i).primary_intended_use        IS NULL AND
             l_inv_line_list(i).product_type	            IS NULL AND
             l_inv_line_list(i).product_category            IS NULL AND
             l_inv_line_list(i).product_fisc_classification IS NULL AND
             l_inv_line_list(i).user_defined_fisc_class     IS NULL AND
	     l_inv_line_list(i).tax_classification_code     IS NULL ) THEN

             -------------------------------------------------------------------
             l_debug_info := 'ISP: get_po_tax_attributes';
             IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
             END IF;
             -------------------------------------------------------------------
             get_po_tax_attributes
                        (
                         p_application_id              => l_ref_doc_application_id,
                         p_org_id                      => P_Invoice_Header_Rec.org_id,
                         p_entity_code                 => l_ref_doc_entity_code,
                         p_event_class_code            => l_ref_doc_event_class_code,
                         p_trx_level_type              => 'SHIPMENT',
                         p_trx_id                      => l_ref_doc_trx_id,
                         p_trx_line_id                 => l_inv_line_list(i).po_line_location_id,
                         x_line_intended_use           => l_intended_use,
                         x_product_type                => l_product_type,
                         x_product_category            => l_product_category,
                         x_product_fisc_classification => l_product_fisc_class,
                         x_user_defined_fisc_class     => l_user_defined_fisc_class,
                         x_assessable_value            => l_assessable_value,
			 x_tax_classification_code     => l_dflt_tax_class_code
                        );

        ELSE
           l_intended_use            := Null;
           l_product_type            := Null;
           l_product_category        := Null;
           l_product_fisc_class      := Null;
           l_user_defined_fisc_class := Null;
           l_assessable_value        := Null;
           l_dflt_tax_class_code     := Null;

        END IF;

        IF (l_dflt_tax_class_code IS NULL
            AND l_inv_line_list(i).tax_classification_code IS NULL) THEN

             -------------------------------------------------------------------
             l_debug_info := 'ISP: ZX_PKG.get_default_tax_classification';
             IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
             END IF;
             -------------------------------------------------------------------

             ZX_AP_TAX_CLASSIFICATN_DEF_PKG.get_default_tax_classification
		            (p_ref_doc_application_id           => l_ref_doc_application_id,
		             p_ref_doc_entity_code              => l_ref_doc_entity_code,
		             p_ref_doc_event_class_code         => l_ref_doc_event_class_code,
		             p_ref_doc_trx_id                   => l_ref_doc_trx_id,
		             p_ref_doc_line_id                  => l_inv_line_list(i).po_line_location_id,
		             p_ref_doc_trx_level_type           => 'SHIPMENT',
		             p_vendor_id                        => P_Invoice_Header_Rec.vendor_id,
		             p_vendor_site_id                   => P_Invoice_Header_Rec.vendor_site_id,
		             p_code_combination_id              => l_inv_line_list(i).default_dist_ccid,
		             p_concatenated_segments            => null,
		             p_templ_tax_classification_cd      => null,
		             p_ship_to_location_id              => l_inv_line_list(i).ship_to_location_id,
		             p_ship_to_loc_org_id               => null,
		             p_inventory_item_id                => l_inv_line_list(i).inventory_item_id,
		             p_item_org_id                      => l_product_org_id,
		             p_tax_classification_code          => l_dflt_tax_class_code,
		             p_allow_tax_code_override_flag     => l_allow_tax_code_override,
		             APPL_SHORT_NAME                    => 'SQLAP',
		             FUNC_SHORT_NAME                    => 'NONE',
		             p_calling_sequence                 => 'AP_ETAX_SERVICES_PKG',
		             p_event_class_code                 => P_Event_Class_Code,
		             p_entity_code                      => 'AP_INVOICES',
		             p_application_id                   => 200,
		             p_internal_organization_id         => P_Invoice_Header_Rec.org_id);

        END IF;
      END IF; -- For ISP invoices only

        IF g_manual_tax_lines = 'Y' and l_manual_tax_line_rcv_mtch = 'N' THEN  ---for 6014115
                l_applied_to_application_id   := NULL;
                l_applied_to_entity_code      := Null;
                l_applied_to_event_class_code := Null;
                l_trx_receipt_date            := Null;
        END IF;
        IF g_manual_tax_lines = 'Y'
           and l_prepay_doc_application_id is null
           and l_adj_doc_application_id    is null
           and l_applied_to_application_id is null THEN

	   l_line_level_action := 'CREATE_WITH_TAX';

	END IF;

        -------------------------------------------------------------------
        l_debug_info := 'Populate pl/sql table';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -------------------------------------------------------------------
        IF (l_return_status = TRUE ) THEN

          trans_lines(i).application_id		:= ap_etax_pkg.ap_application_id;
          trans_lines(i).entity_code		:= ap_etax_pkg.ap_entity_code;
          trans_lines(i).event_class_code	:= p_event_class_code;

	  IF p_calling_mode = 'RECOUPMENT' THEN

             trans_lines(i).trx_id      := P_Invoice_Header_Rec.invoice_id;
             trans_lines(i).trx_line_id := -1 * (l_inv_line_list(i).invoice_id || l_inv_line_list(i).line_number || p_line_number);

             SELECT sum(amount)
               INTO trans_lines(i).line_amt
               FROM ap_invoice_distributions_all aids
              WHERE invoice_id            = p_invoice_header_rec.invoice_id
		AND invoice_line_number   = p_line_number
                AND line_type_lookup_code = 'PREPAY'
                AND EXISTS
                      (select 'Prepayment Invoice'
                         from ap_invoice_distributions_all aidp
                         where aidp.invoice_distribution_id = aids.prepay_distribution_id
                           and aidp.invoice_id              = l_inv_line_list(i).invoice_id
                           and aidp.invoice_line_number     = l_inv_line_list(i).line_number);

	  ELSE

	     trans_lines(i).trx_id      := l_inv_line_list(i).invoice_id;
	     trans_lines(i).trx_line_id := l_inv_line_list(i).line_number;
	     trans_lines(i).line_amt    := l_inv_line_list(i).amount + nvl(l_inv_line_list(i).retained_amount,0);

	  END IF;

          trans_lines(i).trx_level_type 		:= 'LINE';
          trans_lines(i).line_level_action 		:= l_line_level_action;
	      trans_lines(i).line_class 			:= l_line_class;

          trans_lines(i).trx_receipt_date 		:= l_trx_receipt_date;
          trans_lines(i).trx_line_type 			:= l_inv_line_list(i).line_type_lookup_code;
          trans_lines(i).trx_line_date 			:= nvl(l_inv_line_list(i).start_expense_date, p_invoice_header_rec.invoice_date);
          trans_lines(i).trx_line_number 		:= l_inv_line_list(i).line_number;
          trans_lines(i).trx_line_description 		:= l_inv_line_list(i).description;
          trans_lines(i).trx_line_gl_date 		:= l_inv_line_list(i).accounting_date;
          trans_lines(i).account_ccid 			:= l_inv_line_list(i).default_dist_ccid;

          trans_lines(i).trx_line_quantity		:= nvl(l_inv_line_list(i).quantity_invoiced, 1);

          --Bug10621602 In Retainange Release Case we will pass unit price from standard invoice to compute the
          --proper variances
          IF P_Invoice_Header_Rec.invoice_type_lookup_code ='RETAINAGE RELEASE' AND
             l_inv_line_list(i).line_type_lookup_code = 'RETAINAGE RELEASE' AND
             l_inv_line_list(i).po_line_location_id IS NOT NULL THEN

             BEGIN
                SELECT unit_price
                  INTO trans_lines(i).unit_price
                  FROM ap_invoice_lines_all ail
                 WHERE ail.invoice_id = l_inv_line_list(i).Retained_invoice_id
                   AND ail.line_number =  l_inv_line_list(i).Retained_line_number;
             EXCEPTION
             WHEN OTHERS THEN
                  NULL;
             END;

             trans_lines(i).unit_price 			:= nvl(trans_lines(i).unit_price,trans_lines(i).line_amt);

          ELSE

             trans_lines(i).unit_price 			:= nvl(l_inv_line_list(i).unit_price, trans_lines(i).line_amt);
          END IF;
           --Bug10621602

          trans_lines(i).uom_code			:= l_uom_code;

          trans_lines(i).trx_business_category 		:= l_inv_line_list(i).trx_business_category;
          trans_lines(i).line_intended_use 		:= nvl(l_inv_line_list(i).primary_intended_use,l_intended_use);
          trans_lines(i).user_defined_fisc_class 	:= nvl(l_inv_line_list(i).user_defined_fisc_class,l_user_defined_fisc_class);
          trans_lines(i).product_fisc_classification	:= nvl(l_inv_line_list(i).product_fisc_classification,l_product_fisc_class);
          trans_lines(i).assessable_value 		:= nvl(l_inv_line_list(i).assessable_value,l_assessable_value);
          trans_lines(i).input_tax_classification_code	:= nvl(l_inv_line_list(i).tax_classification_code,l_dflt_tax_class_code);

          trans_lines(i).product_id 			:= l_inv_line_list(i).inventory_item_id;
          trans_lines(i).product_org_id			:= l_product_org_id;
          trans_lines(i).product_category		:= nvl(l_inv_line_list(i).product_category,l_product_category);
          trans_lines(i).product_type			:= nvl(l_inv_line_list(i).product_type,l_product_type);
          trans_lines(i).product_description 		:= l_inv_line_list(i).item_description;
          trans_lines(i).fob_point			:= l_fob_point;

          -- AP is not going to pass this parameter.  eTax is aware of this and will derive the value
          -- trans_lines(i).product_code

          -- 7262269 /*Bug 13079028: Removed the IF-ELSE and called the function directly to handle all cases*/
          --IF l_inv_line_list(i).po_line_location_id IS NOT NULL THEN
             l_ship_to_party_id := get_po_ship_to_org_id (l_inv_line_list(i).po_line_location_id,
	                                                  l_inv_line_list(i).inventory_item_id, /*Bug 13079028*/
							  l_inv_line_list(i).org_id, /*Bug 13079028*/
							  l_inv_line_list(i).application_id, /*Bug 13079028*/
							  l_inv_line_list(i).reference_key5); /*Bug 13079028*/
          /*ELSE
             l_ship_to_party_id := l_inv_line_list(i).org_id;
          END IF;*/ /*Bug 13079028*/

          trans_lines(i).ship_to_party_id		:= l_ship_to_party_id;
          -- 7262269
          trans_lines(i).ship_from_party_id		:= P_Invoice_Header_Rec.party_id;

          trans_lines(i).bill_to_party_id		:= l_inv_line_list(i).org_id;
          trans_lines(i).bill_from_party_id		:= P_Invoice_Header_Rec.party_id;

          trans_lines(i).ship_from_party_site_id	:= P_Invoice_Header_Rec.party_site_id;
          trans_lines(i).bill_from_party_site_id	:= P_Invoice_Header_Rec.party_site_id;

          trans_lines(i).ship_to_location_id		:= l_inv_line_list(i).ship_to_location_id;
	      trans_lines(i).ship_from_location_id		:= l_location_id;
          trans_lines(i).bill_to_location_id		:= l_bill_to_location_id;
          trans_lines(i).bill_from_location_id          := l_location_id;

          trans_lines(i).ref_doc_application_id 	:= l_ref_doc_application_id;
          trans_lines(i).ref_doc_entity_code 		:= l_ref_doc_entity_code;
          trans_lines(i).ref_doc_event_class_code 	:= l_ref_doc_event_class_code;
          trans_lines(i).ref_doc_trx_id 		:= l_ref_doc_trx_id;
	      trans_lines(i).ref_doc_trx_level_type 	:= l_ref_doc_trx_level_type;

          --Bug14039130
          IF l_inv_line_list(i).line_type_lookup_code NOT IN ('MISCELLANEOUS','FREIGHT') THEN
              trans_lines(i).ref_doc_line_id 		:= l_inv_line_list(i).po_line_location_id;
          ELSE
              trans_lines(i).ref_doc_line_id 		:= NULL;
          END IF;
          --Bug14039130

          trans_lines(i).ref_doc_line_quantity 		:= l_ref_doc_line_quantity;

          trans_lines(i).applied_from_application_id 	:= l_prepay_doc_application_id;
          trans_lines(i).applied_from_entity_code 	:= l_prepay_doc_entity_code;
          trans_lines(i).applied_from_event_class_code 	:= l_prepay_doc_event_class_code;
          trans_lines(i).applied_from_trx_id 		:= l_applied_from_trx_id;
          trans_lines(i).applied_from_trx_level_type 	:= l_applied_from_trx_level_type;
          trans_lines(i).applied_from_line_id 		:= l_applied_from_line_id;

          trans_lines(i).adjusted_doc_application_id 	:= l_adj_doc_application_id;
          trans_lines(i).adjusted_doc_entity_code 	:= l_adj_doc_entity_code;
          trans_lines(i).adjusted_doc_event_class_code 	:= l_adj_doc_event_class_code;
          trans_lines(i).adjusted_doc_trx_id 		:= l_inv_line_list(i).corrected_inv_id;
          trans_lines(i).adjusted_doc_line_id 		:= l_inv_line_list(i).corrected_line_number;
	      trans_lines(i).adjusted_doc_trx_level_type 	:= l_adj_doc_trx_level_type;
          trans_lines(i).adjusted_doc_number 		:= l_adj_doc_number;
          trans_lines(i).adjusted_doc_date 		:= l_adj_doc_date;

          trans_lines(i).applied_to_application_id 	:= l_applied_to_application_id;
          trans_lines(i).applied_to_entity_code 	:= l_applied_to_entity_code;
          trans_lines(i).applied_to_event_class_code 	:= l_applied_to_event_class_code;

           --Bug14039130

          IF (g_manual_tax_lines = 'Y' and l_manual_tax_line_rcv_mtch = 'N') OR
             l_inv_line_list(i).line_type_lookup_code IN ('MISCELLANEOUS','FREIGHT') THEN  ---for 6014115
             trans_lines(i).applied_to_trx_id      := NULL;
          ELSE
             trans_lines(i).applied_to_trx_id 		:= l_inv_line_list(i).rcv_transaction_id;
          END IF;




          IF g_manual_tax_lines = 'Y'THEN---for 6014115
             IF  l_manual_tax_line_rcv_mtch = 'N' THEN
                 trans_lines(i).applied_to_trx_line_id :=NULL;
              END IF;
          ELSIF l_inv_line_list(i).rcv_transaction_id IS NOT NULL AND
                l_inv_line_list(i).line_type_lookup_code NOT IN ('MISCELLANEOUS','FREIGHT') THEN
                trans_lines(i).applied_to_trx_line_id 	:= l_inv_line_list(i).po_line_location_id;
          ELSIF l_inv_line_list(i).rcv_transaction_id IS NOT NULL AND
                l_inv_line_list(i).line_type_lookup_code IN ('MISCELLANEOUS','FREIGHT') THEN
                trans_lines(i).applied_to_trx_line_id 	:= NULL;
          END IF;

          --Bug14039130

          trans_lines(i).source_application_id   	:= l_inv_line_list(i).source_application_id;
          trans_lines(i).source_entity_code	 	:= l_inv_line_list(i).source_entity_code;
          trans_lines(i).source_event_class_code 	:= l_inv_line_list(i).source_event_class_code;
          trans_lines(i).source_trx_id		 	:= l_inv_line_list(i).source_trx_id;
          trans_lines(i).source_line_id		 	:= l_inv_line_list(i).source_line_id;
          trans_lines(i).source_trx_level_type	 	:= l_inv_line_list(i).source_trx_level_type;

          trans_lines(i).merchant_party_name 		:= l_inv_line_list(i).merchant_name;
          trans_lines(i).merchant_party_document_number := l_inv_line_list(i).merchant_document_number;
          trans_lines(i).merchant_party_reference 	:= l_inv_line_list(i).merchant_reference;
          trans_lines(i).merchant_party_taxpayer_id 	:= l_inv_line_list(i).merchant_taxpayer_id;
          trans_lines(i).merchant_party_tax_reg_number 	:= l_inv_line_list(i).merchant_tax_reg_number;
          trans_lines(i).merchant_party_country 	:= l_inv_line_list(i).country_of_supply;

          trans_lines(i).line_amt_includes_tax_flag 	:= l_line_amt_includes_tax_flag;
          trans_lines(i).historical_flag 		:= NVL(l_inv_line_list(i).historical_flag, 'N'); -- Bug 7117591
/*NVL(P_Invoice_Header_Rec.historical_flag, 'N');*/
          trans_lines(i).ctrl_hdr_tx_appl_flag 		:= l_ctrl_hdr_tx_appl_flag;
          trans_lines(i).ctrl_total_line_tx_amt 	:= l_inv_line_list(i).control_amount;

          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'zx_transaction_lines_gt values ');
	          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'event_class_code: ' || trans_lines(i).event_class_code);
	          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_id: '           || trans_lines(i).trx_id);
	          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_line_id: '      || trans_lines(i).trx_line_id);
	          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_level_type: '   || trans_lines(i).trx_level_type);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_line_type: '    || trans_lines(i).trx_line_type );
	          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_level_action: '|| trans_lines(i).line_level_action);
	          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_class: '       || trans_lines(i).line_class);
	          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_amt: '         || trans_lines(i).line_amt);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'unit_price: '       || trans_lines(i).unit_price);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'ship_to_party_id: ' || trans_lines(i).ship_to_party_id);
          END IF;
         END IF;
       END IF;
     END LOOP;

    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Bulk Insert into global temp table';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF ( l_return_status = TRUE ) THEN
      FORALL m IN trans_lines.FIRST..trans_lines.LAST
        INSERT INTO zx_transaction_lines_gt
        VALUES trans_lines(m);
    END IF;

    RETURN l_return_status;

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Header_Rec = '||P_Invoice_Header_Rec.Invoice_Id||
          ' P_Calling_Mode ='||P_Calling_Mode||
          ' P_Error_Code = '||P_Error_Code||
          ' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      --bug10140354
      IF AP_APPROVAL_PKG.G_VALIDATION_REQUEST_ID IS NULL THEN
        APP_EXCEPTION.RAISE_EXCEPTION;
    ELSE
    l_err:= SQLERRM;
    insert into ap_errors_gt(invoice_id , message_text) values(P_Invoice_Header_Rec.Invoice_id , l_err);
    RETURN FALSE;
    END IF;

  END Populate_Lines_GT;

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
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN IS

    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);

    TYPE Trx_Lines_Tab_Type  IS TABLE OF zx_transaction_lines_gt%ROWTYPE;
    TYPE Tax_Lines_Tab_Type  IS TABLE OF zx_import_tax_lines_gt%ROWTYPE;
    TYPE Link_Lines_Tab_Type IS TABLE OF zx_trx_tax_link_gt%ROWTYPE;

    trans_lines                     Trx_Lines_Tab_Type  := Trx_Lines_Tab_Type();
    tax_lines                       Tax_Lines_Tab_Type  := Tax_Lines_Tab_Type();
    link_lines                      Link_Lines_Tab_Type := Link_Lines_Tab_Type();

    l_ctrl_hdr_tx_appl_flag         zx_transaction_lines_gt.ctrl_hdr_tx_appl_flag%TYPE;
    l_line_control_amount           zx_transaction_lines_gt.ctrl_total_line_tx_amt%TYPE;
    l_line_level_action             zx_transaction_lines_gt.line_level_action%TYPE;
    l_line_class                    zx_transaction_lines_gt.line_class%TYPE;
    l_line_amt_includes_tax_flag    zx_transaction_lines_gt.line_amt_includes_tax_flag%TYPE;

    l_product_org_id		    zx_transaction_lines_gt.product_org_id%TYPE;
    l_uom_code			    mtl_units_of_measure.uom_code%TYPE;
    l_fob_point                     po_vendor_sites_all.fob_lookup_code%TYPE;

    l_po_line_location_id           ap_invoice_lines_interface.po_line_location_id%TYPE;
    l_location_id         	    zx_transaction_lines_gt.ship_from_location_id%type;
    l_ship_to_location_id           ap_supplier_sites_all.ship_to_location_id%type;
    l_bill_to_location_id           zx_transaction_lines_gt.bill_to_location_id%TYPE;

    -- Purchase Order Info
    l_ref_doc_application_id	    zx_transaction_lines_gt.ref_doc_application_id%TYPE;
    l_ref_doc_entity_code	    zx_transaction_lines_gt.ref_doc_entity_code%TYPE;
    l_ref_doc_event_class_code	    zx_transaction_lines_gt.ref_doc_event_class_code%TYPE;
    l_ref_doc_line_quantity	    zx_transaction_lines_gt.ref_doc_line_quantity%TYPE;
    l_ref_doc_trx_level_type	    zx_transaction_lines_gt.ref_doc_trx_level_type%TYPE;
    l_ref_doc_trx_id                zx_transaction_lines_gt.ref_doc_trx_id%TYPE;
    l_po_header_curr_conv_rate	    po_headers_all.rate%TYPE;
    l_dummy			    number;

    -- Receipt Info
    l_applied_to_application_id	    zx_transaction_lines_gt.applied_to_application_id%TYPE;
    l_applied_to_entity_code	    zx_transaction_lines_gt.applied_to_entity_code%TYPE;
    l_applied_to_event_class_code   zx_transaction_lines_gt.applied_to_event_class_code%TYPE;
    l_trx_receipt_date		    zx_transaction_lines_gt.trx_receipt_date%TYPE;

    -- Correction Invoices
    l_adj_doc_application_id	    zx_transaction_lines_gt.adjusted_doc_application_id%TYPE;
    l_adj_doc_entity_code	    zx_transaction_lines_gt.adjusted_doc_entity_code%TYPE;
    l_adj_doc_event_class_code	    zx_transaction_lines_gt.adjusted_doc_event_class_code%TYPE;
    l_adj_doc_number		    zx_transaction_lines_gt.adjusted_doc_number%TYPE;
    l_adj_doc_date		    zx_transaction_lines_gt.adjusted_doc_date%TYPE;
    l_adj_doc_trx_level_type	    zx_transaction_lines_gt.adjusted_doc_trx_level_type%TYPE; --Bug8332737


    l_dflt_tax_class_code	    zx_transaction_lines_gt.input_tax_classification_code%type;
    l_allow_tax_code_override	    varchar2(10);

    l_return_status                 BOOLEAN := TRUE;
    j                               INT := 1;
    k                               INT := 1;
    l_pseudo                        INT := 1; -- bug 8839697: add
    l_pseudo2                       INT := 1; -- bug 8839697: add

    l_prorating_total               NUMBER;
    l_total_prorated                NUMBER;

    l_ship_to_party_id          po_line_locations_all.ship_to_organization_id%type; -- 7262269

    l_api_name                    CONSTANT VARCHAR2(100) := 'Populate_Lines_Import_GT';

    l_copy_line_dff_flag         VARCHAR2(1) := 'N'; -- Bug10082937

   l_default_ccid      	AP_INVOICE_LINES_INTERFACE.default_dist_ccid%TYPE; --Bug9841978

  BEGIN

    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.Populate_Lines_Import_GT<-' ||
                               P_calling_sequence;
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_curr_calling_sequence);
    END IF;
    ----------------------------------------------------------------------
    l_debug_info := 'Step 1: Get location_id for org_id';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    ----------------------------------------------------------------------
    BEGIN
      SELECT location_id
        INTO l_bill_to_location_id
        FROM hr_all_organization_units
       WHERE organization_id = P_Invoice_Header_Rec.org_id;

    EXCEPTION
      WHEN no_data_found THEN
         l_bill_to_location_id := null;
    END;

    ----------------------------------------------------------------------
    l_debug_info := 'Step 1.1: Get location_id for vendor site';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    ----------------------------------------------------------------------
    BEGIN
      SELECT location_id, ship_to_location_id, fob_lookup_code
        INTO l_location_id, l_ship_to_location_id, l_fob_point
        FROM ap_supplier_sites_all
       WHERE vendor_site_id = P_Invoice_Header_Rec.vendor_site_id;

    EXCEPTION
      WHEN no_data_found THEN
         l_location_id		:= null;
	 l_ship_to_location_id	:= null;
	 l_fob_point		:= null;
    END;

    ----------------------------------------------------------------------
    l_debug_info := 'Step 3: Determine if the invoice is tax-only.  If the '||
                    ' invoice is not tax-only user line level action CREATE'||
                    ' always';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    ----------------------------------------------------------------------
    IF (P_Inv_Line_List.COUNT <> 0) THEN

    FOR i IN P_Inv_Line_List.FIRST..P_Inv_Line_List.LAST LOOP

      -- Invoice is not tax-only.  TRX lines will be populated in the
      -- ZX_TRANSAXTION_LINES_GT and TAX lines in ZX_IMPORT_TAX_LINES_GT
      -- allocation structure will be store in ZX_TRX_TAX_LINK_GT

      IF ( NVL(P_Invoice_Header_Rec.tax_only_flag, 'N') = 'N' ) THEN

        IF (P_inv_line_list(i).line_type_lookup_code <> 'TAX' ) THEN
          -------------------------------------------------------------------
          l_debug_info := 'Step 4: Get line_level_action for line ITEM number'||
                          P_inv_line_list(i).line_number ;
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------
            /*  --Bug12660669 Added source, invoice type and line type check */
          IF (P_Invoice_Header_Rec.source = 'SelfService' AND
		        P_Invoice_Header_Rec.invoice_type_lookup_code = 'EXPENSE REPORT' AND
                P_inv_line_list(i).line_type_lookup_code = 'MISCELLANEOUS' ) THEN

		   l_line_level_action := 'RECORD_WITH_NO_TAX' ;

          ELSE
                   l_line_level_action := 'CREATE';
	  END IF;
          -------------------------------------------------------------------
          l_debug_info := 'Step 5: Get Additional PO matched  info ';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------

	  --bug14189635, changed IF condition to check variable p_inv_line_list instead of l_inv_line_list
          IF ( P_Inv_Line_List(i).po_line_location_id IS NOT NULL AND
               p_inv_line_list(i).line_type_lookup_code NOT IN ('MISCELLANEOUS','FREIGHT')) THEN   --Bug14039130

              -- this assignment is required since the p_po_line_location_id
              -- parameter is IN/OUT.  However, in this case it will not be
              -- modified because the po_distribution_id is not provided

            l_po_line_location_id := P_Inv_Line_List(i).po_line_location_id;

            IF NOT (AP_ETAX_UTILITY_PKG.Get_PO_Info(
               P_Po_Line_Location_Id         => l_po_line_location_id,
               P_PO_Distribution_Id          => null,
               P_Application_Id              => l_ref_doc_application_id,
               P_Entity_code                 => l_ref_doc_entity_code,
               P_Event_Class_Code            => l_ref_doc_event_class_code,
               P_PO_Quantity                 => l_ref_doc_line_quantity,
               P_Product_Org_Id              => l_product_org_id,
               P_Po_Header_Id                => l_ref_doc_trx_id,
               P_Po_Header_curr_conv_rate    => l_po_header_curr_conv_rate,
	           P_Uom_Code		             => l_uom_code,
               P_Dist_Qty                    => l_dummy,
               P_Ship_Price                  => l_dummy,
               P_Error_Code                  => P_error_code,
               P_Calling_Sequence            => l_curr_calling_sequence)) THEN

              l_return_status := FALSE;
            END IF;

            l_ref_doc_trx_level_type := 'SHIPMENT';

          ELSE
             l_ref_doc_application_id     := Null;
             l_ref_doc_entity_code        := Null;
             l_ref_doc_event_class_code   := Null;
             l_ref_doc_line_quantity      := Null;
             l_product_org_id             := Null;
             l_ref_doc_trx_id             := Null;
             l_ref_doc_trx_level_type     := Null;
          END IF;

          -------------------------------------------------------------------
          l_debug_info := 'Step 6: Get Additional receipt matched info ';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------

	  --bug14189635, changed IF condition to check variable p_inv_line_list instead of l_inv_line_list
          IF ( l_return_status = TRUE AND
               P_Inv_Line_List(i).rcv_transaction_id IS NOT NULL AND
               p_inv_line_list(i).line_type_lookup_code NOT IN ('MISCELLANEOUS','FREIGHT')) THEN   --Bug14039130

            IF NOT (AP_ETAX_UTILITY_PKG.Get_Receipt_Info(
               P_Rcv_Transaction_Id          => P_Inv_Line_List(i).rcv_transaction_id,
               P_Application_Id              => l_applied_to_application_id,
               P_Entity_code                 => l_applied_to_entity_code,
               P_Event_Class_Code            => l_applied_to_event_class_code,
               P_Transaction_Date            => l_trx_receipt_date,
               P_Error_Code                  => P_error_code,
               P_Calling_Sequence            => l_curr_calling_sequence)) THEN

               l_return_status := FALSE;
            END IF;
          ELSE
             l_applied_to_application_id   := Null;
             l_applied_to_entity_code      := Null;
             l_applied_to_event_class_code := Null;
             l_trx_receipt_date            := Null;
          END IF;

          -------------------------------------------------------------------
          l_debug_info := 'Step 8: Get Additional Correction Invoice Info ';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------
          IF ( l_return_status = TRUE AND
               P_Inv_Line_List(i).corrected_inv_id IS NOT NULL AND
               P_Inv_Line_list(i).price_correct_inv_line_num IS NOT NULL) THEN

            IF NOT (AP_ETAX_UTILITY_PKG.Get_Corrected_Invoice_Info(
               P_Corrected_Invoice_Id        => P_Inv_Line_List(i).corrected_inv_id,
               P_Corrected_Line_Number       => P_Inv_Line_List(i).price_correct_inv_line_num,
               P_Application_Id              => l_adj_doc_application_id,
               P_Entity_code                 => l_adj_doc_entity_code,
               P_Event_Class_Code            => l_adj_doc_event_class_code,
               P_Invoice_Number              => l_adj_doc_number,
               P_Invoice_Date                => l_adj_doc_date,
               P_Error_Code                  => P_error_code,
               P_Calling_Sequence            => l_curr_calling_sequence)) THEN

              l_return_status := FALSE;
            END IF;

			l_adj_doc_trx_level_type := 'LINE'; /* Bug 12868432 */

          ELSE
            l_adj_doc_application_id   := Null;
            l_adj_doc_entity_code      := Null;
            l_adj_doc_event_class_code := Null;
            l_adj_doc_number           := Null;
            l_adj_doc_date             := Null;
          END IF;

          -------------------------------------------------------------------
          l_debug_info := 'Step 9: Get line_amt_includes_tax_flag';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------

	  --bug14189635, changed IF condition to check variable p_inv_line_list instead of l_inv_line_list
          IF (P_Inv_Line_List(i).po_line_location_id IS NOT NULL AND
              p_inv_line_list(i).line_type_lookup_code NOT IN ('MISCELLANEOUS','FREIGHT')) THEN   --Bug14039130
            -- NONE
            l_line_amt_includes_tax_flag := 'N';

          ELSE
           IF (p_calling_mode = 'CALCULATE QUOTE')
              OR
              (p_invoice_header_rec.invoice_type_lookup_code = 'EXPENSE REPORT'
               and nvl(p_inv_line_list(i).line_type_lookup_code, 'N') <> 'PREPAY') THEN
             -- ALL
             l_line_amt_includes_tax_flag := 'A';

           ELSE
            -- STANDARD
            l_line_amt_includes_tax_flag := 'S';
           END IF;
          END IF;

	  IF l_line_amt_includes_tax_flag = 'S' AND
             p_inv_line_list(i).amount_includes_tax_flag IS NOT NULL THEN
	     IF (p_inv_line_list(i).amount_includes_tax_flag = 'Y' OR
		 p_inv_line_list(i).amount_includes_tax_flag = 'A') THEN
                 -- ALL
                 l_line_amt_includes_tax_flag := 'A';
	     ELSIF p_inv_line_list(i).amount_includes_tax_flag = 'N' THEN
                 -- NONE
                 l_line_amt_includes_tax_flag := 'N';
	     ELSIF p_inv_line_list(i).amount_includes_tax_flag = 'S' THEN
                 -- STANDARD
                 l_line_amt_includes_tax_flag := 'S';
	     ELSE
                 -- STANDARD
                 l_line_amt_includes_tax_flag := 'S';
	     END IF;
	  END IF;

	  -----------------------------------------------------------------
          l_debug_info := 'l_line_amt_includes_tax_flag: '||l_line_amt_includes_tax_flag;
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;

          l_debug_info := 'p_inv_line_list(i).amount_includes_tax_flag: '||p_inv_line_list(i).amount_includes_tax_flag;
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -----------------------------------------------------------------

          -------------------------------------------------------------------
          l_debug_info := 'Step 10: Get ctrl_hdr_tx_appl_flag';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------
          IF P_Invoice_Header_Rec.control_amount IS NOT NULL THEN
            l_ctrl_hdr_tx_appl_flag := 'Y';
          ELSE
            l_ctrl_hdr_tx_appl_flag := 'N';
          END IF;

          -------------------------------------------------------------------
          l_debug_info := 'Step 10.1: Get line_class';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------
          IF (l_return_status = TRUE) THEN

              IF NOT (AP_ETAX_UTILITY_PKG.Get_Line_Class(
                             P_Invoice_Type_Lookup_Code    => p_invoice_header_rec.invoice_type_lookup_code,
                             P_Inv_Line_Type               => p_inv_line_list(i).line_type_lookup_code,
                             P_Line_Location_Id            => p_inv_line_list(i).po_line_location_id,
                             P_Line_Class                  => l_line_class,
                             P_Error_Code                  => p_error_code,
                             P_Calling_Sequence            => l_curr_calling_sequence)) THEN

                  l_return_status := FALSE;
              END IF;
          END IF;

	  --Bug9841978 STARTS

 IF P_Inv_Line_List(i).match_type IN
         ('ITEM_TO_PO','ITEM_TO_RECEIPT','ITEM_TO_SERVICE_PO',
          'ITEM_TO_SERVICE_RECEIPT','PRICE_CORRECTION','QTY_CORRECTION',
          'AMOUNT_CORRECTION') THEN

          IF  P_Inv_Line_List(i).po_line_location_id IS NOT NULL THEN

              SELECT pd.code_combination_id
                INTO l_default_ccid
                FROM po_distributions_all pd
               WHERE pd.line_location_id = P_Inv_Line_List(i).po_line_location_id
                 AND rownum = 1;

	      /* Bug 8230574
	         If the account on the Invoice Line is already populated and
		 it is different from that being defaulted from the PO then
		 retain the line level account....else use the defaulting
		 from PO. */

		 IF P_Inv_Line_List(i).dist_code_combination_id IS NOT NULL AND
                   P_Inv_Line_List(i).dist_code_combination_id <> l_default_ccid THEN

		      -- retain the Invoice line cc_id

		     l_default_ccid :=  P_Inv_Line_List(i).dist_code_combination_id  ;

                      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                                 '1 Retaining the Line level cc_id '||P_Inv_Line_List(i).dist_code_combination_id);
                      END IF;

		 ELSE
                       null;

                      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                                 '1 Default CCID passed from PO '||l_default_ccid);
                      END IF;

		 END IF;

          ELSIF P_Inv_Line_List(i).po_distribution_id IS NOT NULL THEN

              SELECT pd.code_combination_id
                INTO l_default_ccid
                FROM po_distributions_all pd
               WHERE pd.line_location_id =
                    (SELECT pod.line_location_id
                       FROM po_distributions_all pod
                      WHERE po_distribution_id = P_Inv_Line_List(i).po_distribution_id)
                 AND rownum = 1;

	      /* Bug 8230574
	         If the account on the Invoice Line is already populated and
		 it is different from that being defaulted from the PO then
		 retain the line level account....else use the defaulting
		 from PO. */

		 IF P_Inv_Line_List(i).dist_code_combination_id IS NOT NULL AND
                    P_Inv_Line_List(i).dist_code_combination_id <> l_default_ccid THEN

		       l_default_ccid :=  P_Inv_Line_List(i).dist_code_combination_id  ; -- retain the Invoice line cc_id

                      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                                 '3 Retaining the Line level cc_id '||P_Inv_Line_List(i).dist_code_combination_id);
                      END IF;

		 ELSE
                     null ;

                      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                                 '3 Default CCID passed from PO '||l_default_ccid);
                      END IF;

		 END IF;

          ELSIF P_Inv_Line_List(i).rcv_shipment_line_id IS NOT NULL THEN

              SELECT pd.code_combination_id
                INTO l_default_ccid
                FROM po_distributions_all pd
               WHERE pd.line_location_id =
                     (SELECT rcv.po_line_location_id
                        FROM rcv_shipment_lines rcv
                       WHERE rcv.shipment_line_id = P_Inv_Line_List(i).rcv_shipment_line_id)
                 AND rownum = 1;

	      /* Bug 8230574
	         If the account on the Invoice Line is already populated and
		 it is different from that being defaulted from the PO then
		 retain the line level account....else use the defaulting
		 from PO. */

		 IF P_Inv_Line_List(i).dist_code_combination_id IS NOT NULL AND
                    P_Inv_Line_List(i).dist_code_combination_id <> l_default_ccid THEN

		      l_default_ccid :=  P_Inv_Line_List(i).dist_code_combination_id  ; -- retain the Invoice line cc_id

                      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                                 '4 Retaining the Line level cc_id '||P_Inv_Line_List(i).dist_code_combination_id);
                      END IF;

		 ELSE
                      null;

                      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                                 '4 Default CCID passed from PO '||l_default_ccid);
                      END IF;

		 END IF;

          ELSIF P_Inv_Line_List(i).rcv_transaction_id IS NOT NULL THEN

              SELECT pd.code_combination_id
                INTO l_default_ccid
                FROM po_distributions_all pd
               WHERE pd.line_location_id =
                     (SELECT rcv.po_line_location_id
                        FROM rcv_transactions rcv
                       WHERE rcv.transaction_id = P_Inv_Line_List(i).rcv_transaction_id)
                 AND rownum = 1;


	      /* Bug 8230574
	         If the account on the Invoice Line is already populated and
		 it is different from that being defaulted from the PO then
		 retain the line level account....else use the defaulting
		 from PO. */

		 IF P_Inv_Line_List(i).dist_code_combination_id IS NOT NULL AND
                    P_Inv_Line_List(i).dist_code_combination_id <> l_default_ccid THEN

		      l_default_ccid :=  P_Inv_Line_List(i).dist_code_combination_id  ; -- retain the Invoice line cc_id

                      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                                 '5 Retaining the Line level cc_id '||P_Inv_Line_List(i).dist_code_combination_id);
                      END IF;

		 ELSE
                      null;

                      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                                 '5 Default CCID passed from PO '||l_default_ccid);
                      END IF;

		 END IF;

          ELSE
              IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                  FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                                 '6 Default CCID passed from line rather than of PO Distribution');
              END IF;
          END IF;

	  ELSE
          l_default_ccid :=  P_Inv_Line_List(i).dist_code_combination_id  ;
      END IF;


       IF (P_Inv_Line_List(i).dist_code_combination_id IS NULL AND
           P_Inv_Line_List(i).line_type_lookup_code <> 'PREPAY') THEN

         BEGIN

          SELECT aerd.code_combination_id
            INTO l_default_ccid
            FROM ap_exp_report_dists_all aerd,
                 ap_expense_report_lines_all aerl,
                 ap_invoices_all ai
           WHERE aerd.report_header_id = P_Inv_Line_List(i).reference_key1
             AND aerd.report_line_id = P_Inv_Line_List(i).reference_key2
             AND aerd.report_line_id = aerl.report_line_id
             AND aerd.report_header_id = aerl.report_header_id
             AND ai.invoice_id = P_Invoice_Header_Rec.invoice_id  --9841978
             AND ai.invoice_type_lookup_code = 'EXPENSE REPORT'
             AND rownum = 1;

         EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;

       END IF;

--Bug9841978 ENDS


          IF (p_inv_line_list(i).tax_classification_code IS NULL) THEN
            --Bug12660669 Added source, invoice type and line type check
            IF (p_invoice_header_rec.source = 'SelfService' AND
			    p_invoice_header_rec.invoice_type_lookup_code = 'EXPENSE REPORT' AND
                p_inv_line_list(i).line_type_lookup_code = 'MISCELLANEOUS' ) THEN

                -------------------------------------------------------------------
                l_debug_info := 'tax_classification_code is NULL and Should remain NULL';
                IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                   FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                END IF;
                ----------------------------------------------------------------
                NULL;
            ELSE

	      ZX_AP_TAX_CLASSIFICATN_DEF_PKG.get_default_tax_classification
		            (p_ref_doc_application_id           => l_ref_doc_application_id,
		             p_ref_doc_entity_code              => l_ref_doc_entity_code,
		             p_ref_doc_event_class_code         => l_ref_doc_event_class_code,
		             p_ref_doc_trx_id                   => l_ref_doc_trx_id,
		             p_ref_doc_line_id                  => p_inv_line_list(i).po_line_location_id,
		             p_ref_doc_trx_level_type           => 'SHIPMENT',
		             p_vendor_id                        => p_invoice_header_rec.vendor_id,
		             p_vendor_site_id                   => p_invoice_header_rec.vendor_site_id,
		             p_code_combination_id              => l_default_ccid,  --9841978
		             p_concatenated_segments            => null,
		             p_templ_tax_classification_cd      => null,
		             p_ship_to_location_id              => nvl(p_inv_line_list(i).ship_to_location_id,l_ship_to_location_id),
		             p_ship_to_loc_org_id               => null,
		             p_inventory_item_id                => p_inv_line_list(i).inventory_item_id,
		             p_item_org_id                      => l_product_org_id,
		             p_tax_classification_code          => l_dflt_tax_class_code,
		             p_allow_tax_code_override_flag     => l_allow_tax_code_override,
		             APPL_SHORT_NAME                    => 'SQLAP',
		             FUNC_SHORT_NAME                    => 'NONE',
		             p_calling_sequence                 => 'AP_ETAX_SERVICES_PKG',
		             p_event_class_code                 => p_event_class_code,
		             p_entity_code                      => 'AP_INVOICES',
		             p_application_id                   => 200,
		             p_internal_organization_id         => p_invoice_header_rec.org_id);
	     END IF; --Bug12660669 Added source, invoice type and line type check

	 END IF;

         -------------------------------------------------------------------
         l_debug_info := 'Step 11: Populate pl/sql table';
         IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
         END IF;
         -------------------------------------------------------------------
         IF (l_return_status = TRUE ) THEN

            trans_lines.EXTEND(1);

			j := trans_lines.COUNT; /* bug 12955467 */

            trans_lines(j).application_id		:= 200;
            trans_lines(j).entity_code			:= 'AP_INVOICES';
            trans_lines(j).event_class_code 		:= p_event_class_code;

            trans_lines(j).trx_id 			:= P_Invoice_Header_Rec.invoice_id;
            trans_lines(j).trx_level_type 		:= 'LINE';
            trans_lines(j).trx_line_id			:= p_inv_line_list(i).line_number;
            trans_lines(j).line_level_action		:= l_line_level_action;
	        trans_lines(j).line_class			:= l_line_class;

            trans_lines(j).trx_receipt_date	 	:= l_trx_receipt_date;
            trans_lines(j).trx_line_type 	 	:= p_inv_line_list(i).line_type_lookup_code;
            trans_lines(j).trx_line_date	 	:= p_invoice_header_rec.invoice_date;
            trans_lines(j).trx_line_number              := p_inv_line_list(i).line_number;
            trans_lines(j).trx_line_description         := p_inv_line_list(i).description;
            trans_lines(j).trx_line_gl_date             := p_inv_line_list(i).accounting_date;


            trans_lines(j).account_ccid			:= l_default_ccid; --9841978

            trans_lines(j).line_amt                     := p_inv_line_list(i).amount + nvl(p_inv_line_list(i).retained_amount,0);
            trans_lines(j).trx_line_quantity            := p_inv_line_list(i).quantity_invoiced;
            trans_lines(j).unit_price                   := p_inv_line_list(i).unit_price;
            trans_lines(j).uom_code                     := l_uom_code;

            trans_lines(j).trx_business_category        := p_inv_line_list(i).trx_business_category;
            trans_lines(j).line_intended_use            := p_inv_line_list(i).primary_intended_use;
            trans_lines(j).user_defined_fisc_class      := p_inv_line_list(i).user_defined_fisc_class;
            trans_lines(j).product_fisc_classification	:= p_inv_line_list(i).product_fisc_classification;
	        trans_lines(j).assessable_value		:= p_inv_line_list(i).assessable_value;

              --Bug12660669
              IF (p_invoice_header_rec.source = 'SelfService' AND
			      p_invoice_header_rec.invoice_type_lookup_code = 'EXPENSE REPORT' AND
                  p_inv_line_list(i).line_type_lookup_code = 'MISCELLANEOUS') THEN
                  trans_lines(j).input_tax_classification_code := NULL; --Bug12660669
              ELSE
                  trans_lines(j).input_tax_classification_code := NVL(p_inv_line_list(i).tax_classification_code, l_dflt_tax_class_code);
              END IF;

            trans_lines(j).product_id                   := p_inv_line_list(i).inventory_item_id;
            trans_lines(j).product_org_id		:= l_product_org_id;
            trans_lines(j).product_type			:= p_inv_line_list(i).product_type;
            trans_lines(j).product_category		:= p_inv_line_list(i).product_category;
            trans_lines(j).product_description		:= p_inv_line_list(i).item_description;
            trans_lines(j).fob_point			:= l_fob_point;

            -- AP is not going to pass this parameter.  eTax is aware of this and they will derive this.
            -- trans_lines(j).product_code

            -- 7262269 /*Bug 13079028: Removed the IF-ELSE and called the function directly to handle all cases*/
            --IF p_inv_line_list(i).po_line_location_id IS NOT NULL THEN

            --Bug14039130
	     --bug14189635, changed IF condition to check variable p_inv_line_list instead of l_inv_line_list
             IF p_inv_line_list(i).line_type_lookup_code NOT IN ('MISCELLANEOUS','FREIGHT') THEN
                l_po_line_location_id := p_inv_line_list(i).po_line_location_id;
             ELSE
                l_po_line_location_id := NULL;
             END IF;

             l_ship_to_party_id := get_po_ship_to_org_id (l_po_line_location_id,
	                                                      p_inv_line_list(i).inventory_item_id, /*Bug 13079028*/
							                              p_inv_line_list(i).org_id, /*Bug 13079028*/
							                              p_inv_line_list(i).application_id, /*Bug 13079028*/
							                              p_inv_line_list(i).reference_key5); /*Bug 13079028*/

            --Bug14039130

           /*ELSE
             l_ship_to_party_id := p_inv_line_list(i).org_id;
            END IF;*/ /*Bug 13079028*/

            trans_lines(j).ship_to_party_id		:= l_ship_to_party_id; /* Changed the subscript from i to j for bug#7319191 */
            -- 7262269

            trans_lines(j).ship_from_party_id		:= P_Invoice_Header_Rec.party_id;

            trans_lines(j).bill_to_party_id		:= p_inv_line_list(i).org_id;
            trans_lines(j).bill_from_party_id		:= P_Invoice_Header_Rec.party_id;

            trans_lines(j).ship_from_party_site_id	:= P_Invoice_Header_Rec.party_site_id;
            trans_lines(j).bill_from_party_site_id	:= P_Invoice_Header_Rec.party_site_id;

            trans_lines(j).ship_to_location_id		:= nvl(p_inv_line_list(i).ship_to_location_id,l_ship_to_location_id);
	        trans_lines(j).ship_from_location_id	:= l_location_id;
            trans_lines(j).bill_to_location_id		:= l_bill_to_location_id;
            trans_lines(j).bill_from_location_id        := l_location_id;

            trans_lines(j).ref_doc_application_id	:= l_ref_doc_application_id;
            trans_lines(j).ref_doc_entity_code		:= l_ref_doc_entity_code;
            trans_lines(j).ref_doc_event_class_code	:= l_ref_doc_event_class_code;
            trans_lines(j).ref_doc_trx_id		:= l_ref_doc_trx_id;

            --Bug14039130
	    --bug14189635, changed IF condition to check variable p_inv_line_list instead of l_inv_line_list
            IF p_inv_line_list(i).line_type_lookup_code NOT IN ('MISCELLANEOUS','FREIGHT') THEN
               trans_lines(j).ref_doc_line_id		:= p_inv_line_list(i).po_line_location_id;
            ELSE
               trans_lines(j).ref_doc_line_id		:= NULL;
            END IF;
            --Bug14039130

            trans_lines(j).ref_doc_line_quantity	:= l_ref_doc_line_quantity;
	        trans_lines(j).ref_doc_trx_level_type       := l_ref_doc_trx_level_type; -- bug 8578833

            -- Not require to populate this values here since this function will
            -- not be run for prepayment application
            -- trans_lines(j).applied_from_application_id
            -- trans_lines(j).applied_from_entity_code
            -- trans_lines(j).applied_from_event_class_code
            -- trans_lines(j).applied_from_trx_id
            -- trans_lines(j).applied_from_line_id

            trans_lines(j).adjusted_doc_application_id	 := l_adj_doc_application_id;
            trans_lines(j).adjusted_doc_entity_code	 := l_adj_doc_entity_code;
            trans_lines(j).adjusted_doc_event_class_code := l_adj_doc_event_class_code;
            trans_lines(j).adjusted_doc_trx_id		 := p_inv_line_list(i).corrected_inv_id;
            trans_lines(j).adjusted_doc_line_id		 := p_inv_line_list(i).price_correct_inv_line_num;
            trans_lines(j).adjusted_doc_number		 := l_adj_doc_number;
            trans_lines(j).adjusted_doc_date		 := l_adj_doc_date;
	    trans_lines(j).adjusted_doc_trx_level_type 	 := l_adj_doc_trx_level_type; -- Bug16506167: Added assignment

            trans_lines(j).applied_to_application_id	 := l_applied_to_application_id;
            trans_lines(j).applied_to_entity_code	 := l_applied_to_entity_code;
            trans_lines(j).applied_to_event_class_code	 := l_applied_to_event_class_code;


            --Bug14039130
	    --bug14189635, changed IF condition to check variable p_inv_line_list instead of l_inv_line_list
            IF p_inv_line_list(i).line_type_lookup_code NOT IN ('MISCELLANEOUS','FREIGHT') THEN
               trans_lines(j).applied_to_trx_id		 := p_inv_line_list(i).rcv_transaction_id;
            ELSE
               trans_lines(j).applied_to_trx_id		 := NULL;
            END IF;

	    --bug14189635, changed IF condition to check variable p_inv_line_list instead of l_inv_line_list
            IF p_inv_line_list(i).rcv_transaction_id IS NOT NULL AND
               p_inv_line_list(i).line_type_lookup_code NOT IN ('MISCELLANEOUS','FREIGHT') THEN

               trans_lines(j).applied_to_trx_line_id	 := p_inv_line_list(i).po_line_location_id;
            ELSE
               trans_lines(j).applied_to_trx_line_id	 := NULL;
            END IF;
            --Bug14039130

            trans_lines(j).source_application_id   	 := p_inv_line_list(i).source_application_id;
            trans_lines(j).source_entity_code      	 := p_inv_line_list(i).source_entity_code;
            trans_lines(j).source_event_class_code 	 := p_inv_line_list(i).source_event_class_code;
            trans_lines(j).source_trx_id           	 := p_inv_line_list(i).source_trx_id;
            trans_lines(j).source_line_id          	 := p_inv_line_list(i).source_line_id;
            trans_lines(j).source_trx_level_type   	 := p_inv_line_list(i).source_trx_level_type;

            trans_lines(j).line_amt_includes_tax_flag	 := l_line_amt_includes_tax_flag;
            trans_lines(j).ctrl_hdr_tx_appl_flag	 := l_ctrl_hdr_tx_appl_flag;
            trans_lines(j).ctrl_total_line_tx_amt	 := p_inv_line_list(i).control_amount;

            -- This function will be called only from the import program.  This
            -- flag will be always N.
            trans_lines(j).historical_flag := 'N';
-- Debug messages added for 6321366
 IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'zx_transaction_lines_gt values ');
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'event_class_code: ' || trans_lines(j).event_class_code);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_id: '           || trans_lines(j).trx_id);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_line_id: '      || trans_lines(j).trx_line_id);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_level_type: '   || trans_lines(j).trx_level_type);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_line_type: '    || trans_lines(j).trx_line_type );
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_level_action: '|| trans_lines(j).line_level_action);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_class: '       || trans_lines(j).line_class);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_amt: '         || trans_lines(j).line_amt);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'unit_price: '       || trans_lines(j).unit_price);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_amt_includes_tax_flag: '       || trans_lines(j).line_amt_includes_tax_flag);
                --Bug12660669 Added below two debug stmts
		--bug14189635, changed from trans_lines(i) to trans_lines(j) for below two lines
                FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'default dist ccid: ' || trans_lines(j).account_ccid);
                FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'input_tax_classification_code: ' || trans_lines(j).input_tax_classification_code);
 END IF;

            --j := j + 1; /*  bug 12955467 */

          END IF; -- l_return_status

       ELSE  -- The line is TAX

          -------------------------------------------------------------------
          l_debug_info := 'Step 12: Populate pl/sql table if TAX line';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------
          IF (l_return_status = TRUE ) THEN
            tax_lines.EXTEND(1);

            tax_lines(k).summary_tax_line_number := p_inv_line_list(i).line_number;
            tax_lines(k).internal_organization_id := P_Invoice_Header_Rec.org_id;
            tax_lines(k).application_id := 200;

            tax_lines(k).entity_code := 'AP_INVOICES';
            tax_lines(k).event_class_code := p_event_class_code;
            tax_lines(k).trx_id := P_Invoice_Header_Rec.invoice_id;

            -- Not used by AP
            -- tax_lines(k).hrd_trx_user_key1..6

            tax_lines(k).tax_regime_code := p_inv_line_list(i).tax_regime_code;
            tax_lines(k).tax := p_inv_line_list(i).tax;
            tax_lines(k).tax_status_code := p_inv_line_list(i).tax_status_code;
            tax_lines(k).tax_rate_code := nvl(p_inv_line_list(i).tax_rate_code,
                     p_inv_line_list(i).TAX_CLASSIFICATION_CODE); --bug6255826
            tax_lines(k).tax_rate := p_inv_line_list(i).tax_rate;
            tax_lines(k).tax_amt :=  p_inv_line_list(i).amount;
            tax_lines(k).tax_jurisdiction_code := p_inv_line_list(i).tax_jurisdiction_code;
            tax_lines(k).tax_amt_included_flag := p_inv_line_list(i).incl_in_taxable_line_flag;
            tax_lines(k).tax_rate_id := p_inv_line_list(i).tax_rate_id;

            --Bug10082937
            l_copy_line_dff_flag := NVL(fnd_profile.value('AP_COPY_INV_LINE_DFF'),'N');
            IF l_copy_line_dff_flag = 'Y' THEN
               tax_lines(k).ATTRIBUTE1         :=  p_inv_line_list(i).ATTRIBUTE1;
               tax_lines(k).ATTRIBUTE2         :=  p_inv_line_list(i).ATTRIBUTE2;
               tax_lines(k).ATTRIBUTE3         :=  p_inv_line_list(i).ATTRIBUTE3;
               tax_lines(k).ATTRIBUTE4         :=  p_inv_line_list(i).ATTRIBUTE4;
               tax_lines(k).ATTRIBUTE5         :=  p_inv_line_list(i).ATTRIBUTE5;
               tax_lines(k).ATTRIBUTE6         :=  p_inv_line_list(i).ATTRIBUTE6;
               tax_lines(k).ATTRIBUTE7         :=  p_inv_line_list(i).ATTRIBUTE7;
               tax_lines(k).ATTRIBUTE8         :=  p_inv_line_list(i).ATTRIBUTE8;
               tax_lines(k).ATTRIBUTE9         :=  p_inv_line_list(i).ATTRIBUTE9;
               tax_lines(k).ATTRIBUTE10        :=  p_inv_line_list(i).ATTRIBUTE10;
               tax_lines(k).ATTRIBUTE11        :=  p_inv_line_list(i).ATTRIBUTE11;
               tax_lines(k).ATTRIBUTE12        :=  p_inv_line_list(i).ATTRIBUTE12;
               tax_lines(k).ATTRIBUTE13        :=  p_inv_line_list(i).ATTRIBUTE13;
               tax_lines(k).ATTRIBUTE14        :=  p_inv_line_list(i).ATTRIBUTE14;
               tax_lines(k).ATTRIBUTE15        :=  p_inv_line_list(i).ATTRIBUTE15;  --BUG13719477
               tax_lines(k).ATTRIBUTE_CATEGORY := p_inv_line_list(i).ATTRIBUTE_CATEGORY;
            END IF;
            --Bug10082937




            /*6255826  Added following if condition to populate
                       tax_line_allocation_flag correctly*/

            --bug 6412397 - changed the index of p_inv_line_list
            --              from k to i

            IF  (p_inv_line_list(i).prorate_across_flag = 'Y' AND
                     p_inv_line_list(i).line_group_number IS NOT NULL) THEN
                tax_lines(k).tax_line_allocation_flag       := 'Y';
            ELSE
                tax_lines(k).tax_line_allocation_flag       := 'N';
            END IF;
-- Debug messages added for 6321366
 IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'zx_import_tax_lines_gt values ');
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'summary_tax_line_number: ' || tax_lines(k).summary_tax_line_number);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'application_id: '           || tax_lines(k).application_id);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'event_class_code: '      || tax_lines(k).event_class_code);
	          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_id: '   || tax_lines(k).trx_id);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'tax: '   || tax_lines(k).tax );
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'tax_amt: '    || tax_lines(k).tax_amt );
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'tax_amt_included_flag: '|| tax_lines(k).tax_amt_included_flag);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'tax_line_allocation_flag: '|| tax_lines(k).tax_line_allocation_flag);
 END IF;

            -- k := k + 1; bug 8839697

            -------------------------------------------------------------------
            l_debug_info := 'Step 13: Populate allocation structure if needed';
            IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
            END IF;
            -------------------------------------------------------------------

            IF (AP_IMPORT_INVOICES_PKG.g_source IN('ISP', 'ASBN')) THEN
              -------------------------------------------------------------------
              l_debug_info := 'Step 14: Populate allocation using taxable_flag if '||
                              'source is ISP or ASBN';
              IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
              END IF;
              -------------------------------------------------------------------

              INSERT INTO zx_trx_tax_link_gt (
                application_id,
                entity_code,
                event_class_code,
                trx_id,
                trx_level_type,
                trx_line_id,
                summary_tax_line_number,
                line_amt
              ) SELECT
                  200,                                           -- application_id
                  'AP_INVOICES',                                 -- entity_code
                  p_event_class_code,                            -- event_class_code
                  P_Invoice_Header_Rec.invoice_id,               -- trx_id
                  'LINE',                                        -- trx_level_type
                  aili.line_number,                              -- trx_line_id
                  p_inv_line_list(i).line_number,                -- summary_tax_line_number
                  AP_UTILITIES_PKG.ap_round_currency(
                    p_inv_line_list(i).amount*aili.amount/l_prorating_total,
                    P_Invoice_Header_Rec.invoice_currency_code)  -- line_amt
                 FROM ap_invoice_lines_interface aili
                WHERE aili.invoice_id = P_Invoice_Header_Rec.invoice_id
                  AND aili.line_number <> p_inv_line_list(i).line_number
                  AND aili.line_type_lookup_code <> 'TAX'
                  AND NVL(aili.taxable_flag, 'N') = 'Y';
-- Debug messages added for 6321366

              IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                 FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'Rows instrted in zx_trx_tax_link_gt: '|| sql%rowcount);
              END IF;
              --------------------------------------------------------------
              l_debug_info := 'Step 15: Verify if there is any rounding and '||
                              'apply it to max of largest.';
              IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                 FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
              END IF;
              --------------------------------------------------------------
              BEGIN
                SELECT SUM(NVL(line_amt,0))
                  INTO l_total_prorated
                  FROM zx_trx_tax_link_gt
                 WHERE trx_id = P_Invoice_Header_Rec.invoice_id
                   AND summary_tax_line_number = p_inv_line_list(i).line_number;

                IF (NVL(p_inv_line_list(i).amount, 0) <> l_total_prorated) THEN
                  UPDATE zx_trx_tax_link_gt
                     SET line_amt = line_amt + (p_inv_line_list(i).amount - l_total_prorated)
                   WHERE trx_id = P_Invoice_Header_Rec.invoice_id
                     AND trx_line_id <> p_inv_line_list(i).line_number
                     AND trx_line_id =
                        (SELECT (MAX(aili.line_number))
                           FROM ap_invoice_lines_interface aili
                          WHERE aili.invoice_id = P_Invoice_Header_Rec.invoice_id
                            AND aili.line_number <> p_inv_line_list(i).line_number
                            AND aili.amount <> 0
                            AND aili.line_type_lookup_code <> 'TAX'
                            AND NVL(aili.taxable_flag, 'N') = 'Y'
                            AND ABS(aili.amount) >=
                              ( SELECT MAX(ABS(ail2.amount))
                                  FROM ap_invoice_lines_interface ail2
                                 WHERE ail2.invoice_id = aili.invoice_id
                                   AND ail2.line_number <> p_inv_line_list(i).line_number
                                   AND ail2.line_number <> aili.line_number
                                   AND ail2.line_type_lookup_code <> 'TAX'
                                   AND NVL(ail2.taxable_flag, 'N') = 'Y'));

                END IF;
              EXCEPTION
                WHEN OTHERS THEN
                  l_return_status := FALSE;
              END;


            ELSE -- source is not ISP or ASBN.  Allocations will be based on the
                 -- prorate_across_flag and line_group_number is available
              -------------------------------------------------------------------
              l_debug_info := 'Step 16: Populate allocation structure if needed';
              IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                 FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
              END IF;
              -------------------------------------------------------------------
              IF (p_inv_line_list(i).prorate_across_flag = 'Y' AND
                  p_inv_line_list(i).line_group_number IS NOT NULL) THEN

                   --------------------------------------------------------------
                   l_debug_info := 'Step 17: Get prorated total';
                   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                   END IF;
                   --------------------------------------------------------------
                   SELECT SUM(NVL(amount, 0))
                     INTO l_prorating_total
                     FROM ap_invoice_lines_interface
                    WHERE invoice_id = P_Invoice_Header_Rec.invoice_id
                      AND line_number <> p_inv_line_list(i).line_number
					  AND line_type_lookup_code <> 'TAX'     --Bug6608702**
                      AND line_group_number = p_inv_line_list(i).line_group_number;

                   --------------------------------------------------------------
                   l_debug_info := 'Step 18: Get Insert in global temp table';
                   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                   END IF;
                   --------------------------------------------------------------
                   IF (l_prorating_total <> 0) THEN
                     INSERT INTO zx_trx_tax_link_gt (
                       application_id,
                       entity_code,
                       event_class_code,
                       trx_id,
                       trx_level_type,
                       trx_line_id,
                       summary_tax_line_number,
                       line_amt
                     ) SELECT
                         200,                                           -- application_id
                         'AP_INVOICES',                                 -- entity_code
                         p_event_class_code,                            -- event_class_code
                         P_Invoice_Header_Rec.invoice_id,               -- trx_id
                         'LINE',                                        -- trx_level_type
                         aili.line_number,                              -- trx_line_id
                         p_inv_line_list(i).line_number,                -- summary_tax_line_number
                         AP_UTILITIES_PKG.ap_round_currency(
                           p_inv_line_list(i).amount*aili.amount/l_prorating_total,
                           P_Invoice_Header_Rec.invoice_currency_code)  -- line_amt
                        FROM ap_invoice_lines_interface aili
                       WHERE aili.invoice_id = P_Invoice_Header_Rec.invoice_id
                         AND aili.line_number <> p_inv_line_list(i).line_number
						 AND aili.line_type_lookup_code <> 'TAX' --Bug6608702**
                         AND aili.line_group_number = p_inv_line_list(i).line_group_number;
-- Debug messages added for 6321366
                   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'Rows instrted in zx_trx_tax_link_gt: '|| sql%rowcount);
                   END IF;
                   --------------------------------------------------------------
                   l_debug_info := 'Step 19: Verify if there is any rounding and '||
                                   'apply it to max of largest.';
                   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                   END IF;
                   --------------------------------------------------------------
                   BEGIN
                     SELECT SUM(NVL(line_amt,0))
                       INTO l_total_prorated
                       FROM zx_trx_tax_link_gt
                      WHERE trx_id = P_Invoice_Header_Rec.invoice_id
                        AND summary_tax_line_number = p_inv_line_list(i).line_number;

                     IF (NVL(p_inv_line_list(i).amount, 0) <> l_total_prorated) THEN
                       UPDATE zx_trx_tax_link_gt
                          SET line_amt = line_amt + (p_inv_line_list(i).amount - l_total_prorated)
                        WHERE trx_id = P_Invoice_Header_Rec.invoice_id
                          AND trx_line_id <> p_inv_line_list(i).line_number
                          AND trx_line_id =
                             (SELECT (MAX(aili.line_number))
                                FROM ap_invoice_lines_interface aili
                               WHERE aili.invoice_id = P_Invoice_Header_Rec.invoice_id
                                 AND aili.line_number <> p_inv_line_list(i).line_number
								 AND aili.line_type_lookup_code <> 'TAX' --Bug6608702**
                                 AND aili.amount <> 0
                                 AND aili.line_group_number = p_inv_line_list(i).line_group_number
                                 AND ABS(aili.amount) >=
                                   ( SELECT  MAX(ABS(ail2.amount))
                                       FROM  ap_invoice_lines_interface ail2
                                      WHERE  ail2.invoice_id = aili.invoice_id
                                        AND  ail2.line_number <> p_inv_line_list(i).line_number
                                        AND  ail2.line_number <> aili.line_number
										AND  ail2.line_type_lookup_code <> 'TAX' --Bug6608702**
                                        AND  ail2.line_group_number =
                                               p_inv_line_list(i).line_group_number));
                     END IF;
                   EXCEPTION
                     WHEN OTHERS THEN
                       l_return_status := FALSE;
                   END;

                  END IF;  -- l_prorating_total <> 0
-- bug 8839697: add start
                -- Added functionality to import tax only lines
                -- case only when prorate across flag is set to 'N'
                ELSIF (p_inv_line_list(i).prorate_across_flag = 'N') THEN

                   --------------------------------------------------------------
                   l_debug_info := 'Populating tax only line info';
                   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                   END IF;
                   --------------------------------------------------------------
                      -- allocation flag is marked as N (above) when prorate accross flag is not Y
                      tax_lines(k).tax_line_allocation_flag           := 'Y';

                      trans_lines.EXTEND(1);
                      link_lines.EXTEND(1);

                      l_pseudo := trans_lines.COUNT;
                      l_pseudo2:= link_lines.COUNT;

                      -- add pseudo line for manual non prorated tax line
                      trans_lines(l_pseudo).application_id := 200;
                      trans_lines(l_pseudo).entity_code := 'AP_INVOICES';
                      trans_lines(l_pseudo).event_class_code := p_event_class_code;
                      trans_lines(l_pseudo).trx_id := P_Invoice_Header_Rec.invoice_id;
                      trans_lines(l_pseudo).trx_level_type := 'LINE';
                      trans_lines(l_pseudo).trx_line_id := p_inv_line_list(i).line_number;
                      trans_lines(l_pseudo).line_level_action := 'LINE_INFO_TAX_ONLY';

                      trans_lines(l_pseudo).trx_line_type := 'ITEM';
                      trans_lines(l_pseudo).trx_line_date := P_Invoice_Header_Rec.invoice_date;
                      trans_lines(l_pseudo).trx_business_category := p_inv_line_list(i).trx_business_category;
                      trans_lines(l_pseudo).line_intended_use := p_inv_line_list(i).primary_intended_use;
                      trans_lines(l_pseudo).user_defined_fisc_class := p_inv_line_list(i).user_defined_fisc_class;
                      trans_lines(l_pseudo).line_amt := p_inv_line_list(i).amount;
                      trans_lines(l_pseudo).trx_line_quantity := p_inv_line_list(i).quantity_invoiced;
                      trans_lines(l_pseudo).unit_price := p_inv_line_list(i).unit_price;

                      trans_lines(l_pseudo).product_id := p_inv_line_list(i).inventory_item_id;
                      trans_lines(l_pseudo).product_fisc_classification := p_inv_line_list(i).product_fisc_classification;
                      trans_lines(l_pseudo).product_type := p_inv_line_list(i).product_type;
                      trans_lines(l_pseudo).product_category := p_inv_line_list(i).product_category;
                      trans_lines(l_pseudo).fob_point := l_fob_point;
                      trans_lines(l_pseudo).ship_to_party_id:= p_inv_line_list(i).org_id;

                      trans_lines(l_pseudo).ship_from_party_id := P_Invoice_Header_Rec.party_id;

                      trans_lines(l_pseudo).bill_to_party_id:= p_inv_line_list(i).org_id;
                      trans_lines(l_pseudo).bill_from_party_id:= P_Invoice_Header_Rec.party_id;
                      trans_lines(l_pseudo).ship_from_party_site_id:= P_Invoice_Header_Rec.party_site_id;
                      trans_lines(l_pseudo).bill_from_party_site_id:= P_Invoice_Header_Rec.party_site_id;

                      trans_lines(l_pseudo).ship_to_location_id:= p_inv_line_list(i).ship_to_location_id;
                      trans_lines(l_pseudo).ship_from_location_id:= l_location_id;
                      trans_lines(l_pseudo).bill_to_location_id:= l_bill_to_location_id;
                      trans_lines(l_pseudo).bill_from_location_id:= l_location_id;

                      trans_lines(l_pseudo).account_ccid:= p_inv_line_list(i).default_dist_ccid;
                      trans_lines(l_pseudo).merchant_party_country:= p_inv_line_list(i).country_of_supply;

                      trans_lines(l_pseudo).trx_line_number:= p_inv_line_list(i).line_number;
                      trans_lines(l_pseudo).trx_line_description:= p_inv_line_list(i).description;
                      trans_lines(l_pseudo).product_description:= p_inv_line_list(i).item_description;
                      trans_lines(l_pseudo).trx_line_gl_date:= p_inv_line_list(i).accounting_date;

                      trans_lines(l_pseudo).merchant_party_name:= p_inv_line_list(i).merchant_name;
                      trans_lines(l_pseudo).merchant_party_document_number:= p_inv_line_list(i).merchant_document_number;
                      trans_lines(l_pseudo).merchant_party_reference:= p_inv_line_list(i).merchant_reference;
                      trans_lines(l_pseudo).merchant_party_taxpayer_id:= p_inv_line_list(i).merchant_taxpayer_id;
                      trans_lines(l_pseudo).merchant_party_tax_reg_number:= p_inv_line_list(i).merchant_tax_reg_number;

                      trans_lines(l_pseudo).assessable_value:= p_inv_line_list(i).assessable_value;

                      IF (p_inv_line_list(i).po_line_location_id IS NOT NULL) THEN
                          -- NONE
                          l_line_amt_includes_tax_flag := 'N';
                      ELSE
                          IF (p_calling_mode = 'CALCULATE QUOTE')
                          OR
                         (p_invoice_header_rec.invoice_type_lookup_code = 'EXPENSE REPORT'
                          and nvl(p_inv_line_list(i).line_type_lookup_code, 'N') <> 'PREPAY') THEN
                             -- ALL
                             l_line_amt_includes_tax_flag := 'A';
                          ELSE
                             -- STANDARD
                             l_line_amt_includes_tax_flag := 'S';
                          END IF;
                      END IF;
                      trans_lines(l_pseudo).line_amt_includes_tax_flag:= l_line_amt_includes_tax_flag;
                      trans_lines(l_pseudo).historical_flag:= 'N';

                      IF P_Invoice_Header_Rec.control_amount IS NOT NULL THEN
                         l_ctrl_hdr_tx_appl_flag := 'Y';
                      ELSE
                         l_ctrl_hdr_tx_appl_flag := 'N';
                      END IF;
                      trans_lines(l_pseudo).ctrl_hdr_tx_appl_flag:= l_ctrl_hdr_tx_appl_flag;
                      trans_lines(l_pseudo).ctrl_total_line_tx_amt:= p_inv_line_list(i).control_amount;

                      trans_lines(l_pseudo).source_application_id:= p_inv_line_list(i).source_application_id;
                      trans_lines(l_pseudo).source_entity_code   := p_inv_line_list(i).source_entity_code;
                      trans_lines(l_pseudo).source_event_class_code := p_inv_line_list(i).source_event_class_code;
                      trans_lines(l_pseudo).source_trx_id   := p_inv_line_list(i).source_trx_id;
                      trans_lines(l_pseudo).source_line_id   := p_inv_line_list(i).source_line_id;
                      trans_lines(l_pseudo).source_trx_level_type:= p_inv_line_list(i).source_trx_level_type;

                      trans_lines(l_pseudo).input_tax_classification_code:= p_inv_line_list(i).tax_classification_code;

                      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'zx_transaction_lines_gt values ');
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'event_class_code: ' || trans_lines(l_pseudo).event_class_code);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_id: '           || trans_lines(l_pseudo).trx_id);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_line_id: '      || trans_lines(l_pseudo).trx_line_id);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_level_type: '   || trans_lines(l_pseudo).trx_level_type);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_line_type: '    || trans_lines(l_pseudo).trx_line_type );
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_level_action: '|| trans_lines(l_pseudo).line_level_action);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_amt: '         || trans_lines(l_pseudo).line_amt);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'unit_price: '       || trans_lines(l_pseudo).unit_price);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_amt_includes_tax_flag: ' || trans_lines(l_pseudo).line_amt_includes_tax_flag );
                      END IF;

                      -- add to link gt
                      link_lines(l_pseudo2).application_id:= 200;
                      link_lines(l_pseudo2).entity_code:= 'AP_INVOICES';
                      link_lines(l_pseudo2).event_class_code:= p_event_class_code;
                      link_lines(l_pseudo2).trx_id:= P_Invoice_Header_Rec.invoice_id;
                      link_lines(l_pseudo2).trx_level_type:= 'LINE';
                      link_lines(l_pseudo2).trx_line_id:= p_inv_line_list(i).line_number;
                      link_lines(l_pseudo2).summary_tax_line_number:= p_inv_line_list(i).line_number;
                      link_lines(l_pseudo2).line_amt:= p_inv_line_list(i).amount;

                      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'zx_trx_tax_link_gt values ');
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'summary_tax_line_number: ' || link_lines(l_pseudo2).summary_tax_line_number);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'application_id: '           || link_lines(l_pseudo2).application_id);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'event_class_code: '      || link_lines(l_pseudo2).event_class_code);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_id: '   || link_lines(l_pseudo2).trx_id);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_level_type: '   || link_lines(l_pseudo2).trx_level_type );
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_line_id: '   || link_lines(l_pseudo2).trx_line_id);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_amt: '    || link_lines(l_pseudo2).line_amt );
                      END IF;
-- bug 8839697: add end
              END IF;  -- prorate_accross_flag = 'Y' and line_group_number is not null
            END IF;  -- End of if for the SOURCE of the invoice
            k := k + 1; -- bug 8839697
          END IF;  -- l_return_status validation for TAX lines
        END IF;  -- line type lookup code and it is not tax-only


      ELSE  -- It is a tax-only invoice

          -------------------------------------------------------------------
          l_debug_info := 'Step 4: Get line_level_action for TAX ONLY line number'||
                          P_inv_line_list(i).line_number ;
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------
          IF (NVL(P_Invoice_Header_Rec.tax_only_rcv_matched_flag, 'N') = 'Y') THEN
            -- In this case  eTax will need to run tax
            -- applicability and calculation because it is the matched to other
            -- charges case. This flag is populated in the import program based on
            -- a select from the lines interface table.
            -- In this case the import program will call the calculate service
            -- This is transparent to the user since the
            -- calc_tax_during_import_flag should be set to N.  Otherwise, the
            -- invoice will be rejected.

            l_line_level_action := 'CREATE_TAX_ONLY';
          ELSE
            -- Invoice is tax-only, and there is no need to run applicability.
            -- In this case the user provides all the tax information for the line
            -- to be imported.  However, the additional taxable related info
            -- that eTax need to store will be passed to eTax using a pseudo line
            -- in the zx_transaction_lines_gt table.

            l_line_level_action := 'LINE_INFO_TAX_ONLY';
          END IF;

          -------------------------------------------------------------------
          l_debug_info := 'Step 5: Get Additional PO matched  info ';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------

          IF ( P_Inv_Line_List(i).po_line_location_id IS NOT NULL AND
               P_Inv_Line_List(i).line_type_lookup_code NOT IN ('MISCELLANEOUS','FREIGHT')) THEN  --Bug14039130
              -- this assigned is required since the p_po_line_location_id
              -- parameter is IN/OUT.  However, in this case it will not be
              -- modified because the po_distribution_id is not provided
              l_po_line_location_id := P_Inv_Line_List(i).po_line_location_id;

            IF NOT (AP_ETAX_UTILITY_PKG.Get_PO_Info(
               P_Po_Line_Location_Id         => l_po_line_location_id,
               P_PO_Distribution_Id          => null,
               P_Application_Id              => l_ref_doc_application_id,
               P_Entity_code                 => l_ref_doc_entity_code,
               P_Event_Class_Code            => l_ref_doc_event_class_code,
               P_PO_Quantity                 => l_ref_doc_line_quantity,
               P_Product_Org_Id              => l_product_org_id,
               P_Po_Header_Id                => l_ref_doc_trx_id,
               P_Po_Header_curr_conv_rate    => l_po_header_curr_conv_rate,
               P_Uom_Code                    => l_uom_code,
               P_Dist_Qty                    => l_dummy,
               P_Ship_Price                  => l_dummy,
               P_Error_Code                  => P_error_code,
               P_Calling_Sequence            => l_curr_calling_sequence)) THEN

              l_return_status := FALSE;
            END IF;

            l_ref_doc_trx_level_type := 'SHIPMENT';

          ELSE
            l_ref_doc_application_id     := Null;
            l_ref_doc_entity_code        := Null;
            l_ref_doc_event_class_code   := Null;
            l_ref_doc_line_quantity      := Null;
            l_product_org_id             := Null;
            l_ref_doc_trx_id             := Null;
            l_ref_doc_trx_level_type     := Null;
          END IF;

          -------------------------------------------------------------------
          l_debug_info := 'Step 6: Get Additional receipt matched info ';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------
          IF ( l_return_status = TRUE AND
               P_Inv_Line_List(i).rcv_transaction_id IS NOT NULL AND
               P_Inv_Line_List(i).line_type_lookup_code NOT IN ('MISCELLANEOUS','FREIGHT')) THEN     --Bug14039130
            IF NOT (AP_ETAX_UTILITY_PKG.Get_Receipt_Info(
               P_Rcv_Transaction_Id          => P_Inv_Line_List(i).rcv_transaction_id,
               P_Application_Id              => l_applied_to_application_id,
               P_Entity_code                 => l_applied_to_entity_code,
               P_Event_Class_Code            => l_applied_to_event_class_code,
               P_Transaction_Date            => l_trx_receipt_date,
               P_Error_Code                  => P_error_code,
               P_Calling_Sequence            => l_curr_calling_sequence)) THEN

               l_return_status := FALSE;
            END IF;
          ELSE
            l_applied_to_application_id   := Null;
            l_applied_to_entity_code      := Null;
            l_applied_to_event_class_code := Null;
            l_trx_receipt_date            := Null;
          END IF;

          -------------------------------------------------------------------
          l_debug_info := 'Step 8: Get Additional Correction Invoice Info ';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------

          IF ( l_return_status = TRUE AND
               P_Inv_Line_List(i).corrected_inv_id IS NOT NULL AND
               P_Inv_Line_list(i).price_correct_inv_line_num IS NOT NULL) THEN
            IF NOT (AP_ETAX_UTILITY_PKG.Get_Corrected_Invoice_Info(
               P_Corrected_Invoice_Id        => P_Inv_Line_List(i).corrected_inv_id,
               P_Corrected_Line_Number       => P_Inv_Line_List(i).price_correct_inv_line_num,
               P_Application_Id              => l_adj_doc_application_id,
               P_Entity_code                 => l_adj_doc_entity_code,
               P_Event_Class_Code            => l_adj_doc_event_class_code,
               P_Invoice_Number              => l_adj_doc_number,
               P_Invoice_Date                => l_adj_doc_date,
               P_Error_Code                  => P_error_code,
               P_Calling_Sequence            => l_curr_calling_sequence)) THEN

              l_return_status := FALSE;
            END IF;
              l_adj_doc_trx_level_type := 'LINE'; --Bug8332737
          ELSE
            l_adj_doc_application_id   := Null;
            l_adj_doc_entity_code      := Null;
            l_adj_doc_event_class_code := Null;
            l_adj_doc_number           := Null;
            l_adj_doc_date             := Null;
            l_adj_doc_trx_level_type   := NULL; --Bug8332737

          END IF;

          -------------------------------------------------------------------
          l_debug_info := 'Step 9: Get line_amt_includes_tax_flag';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------

          IF (P_Inv_Line_List(i).po_line_location_id IS NOT NULL) THEN
            -- NONE
            l_line_amt_includes_tax_flag := 'N';

          ELSE
           IF (p_calling_mode = 'CALCULATE QUOTE')
              OR
              (p_invoice_header_rec.invoice_type_lookup_code = 'EXPENSE REPORT'
	      --bug14189635, changed IF condition to check variable p_inv_line_list instead of l_inv_line_list
               and nvl(p_inv_line_list(i).line_type_lookup_code, 'N') <> 'PREPAY') THEN
             -- ALL
             l_line_amt_includes_tax_flag := 'A';

           ELSE
             -- STANDARD
             IF p_calling_mode = 'VALIDATE IMPORT' THEN /* if condition added for 6010950 -
                 For tax only invoices we need to pass it as 'N' */
                l_line_amt_includes_tax_flag := 'N';
            ELSE
                l_line_amt_includes_tax_flag := 'S';
            END IF;

           END IF;
          END IF;

          -------------------------------------------------------------------
          l_debug_info := 'Step 10: Get ctrl_hdr_tx_appl_flag';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------
          IF P_Invoice_Header_Rec.control_amount IS NOT NULL THEN
            l_ctrl_hdr_tx_appl_flag := 'Y';
          ELSE
            l_ctrl_hdr_tx_appl_flag := 'N';
          END IF;


          -------------------------------------------------------------------
          l_debug_info := 'Step 10z: Get control_amount line level';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------
          IF (NVL(P_Invoice_Header_Rec.tax_only_rcv_matched_flag, 'N') = 'Y') THEN
            l_line_control_amount :=
              NVL(p_inv_line_list(i).control_amount, p_inv_line_list(i).amount);

          ELSE
            l_line_control_amount := p_inv_line_list(i).control_amount;
          END IF;

          -------------------------------------------------------------------
          l_debug_info := 'Step 11: Populate pl/sql table';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------
          IF (l_return_status = TRUE ) THEN
            trans_lines.EXTEND(1);
            trans_lines(j).line_amt_includes_tax_flag           := l_line_amt_includes_tax_flag ; ---for bug 6010950
            trans_lines(j).application_id 			:= 200;
            trans_lines(j).entity_code 				:= 'AP_INVOICES';
            trans_lines(j).event_class_code 			:= p_event_class_code;
            trans_lines(j).trx_id 				:= P_Invoice_Header_Rec.invoice_id;
            trans_lines(j).trx_level_type 			:= 'LINE';
            trans_lines(j).trx_line_id 				:= p_inv_line_list(i).line_number;
            trans_lines(j).line_level_action 			:= l_line_level_action;

            trans_lines(j).trx_receipt_date 			:= l_trx_receipt_date;
            trans_lines(j).trx_line_type 			:= 'ITEM';
--bug6255826
            trans_lines(j).trx_line_date 			:= P_Invoice_Header_Rec.invoice_date;
            trans_lines(j).trx_business_category 		:= p_inv_line_list(i).trx_business_category;
            trans_lines(j).line_intended_use 			:= p_inv_line_list(i).primary_intended_use;
            trans_lines(j).user_defined_fisc_class 		:= p_inv_line_list(i).user_defined_fisc_class;
            trans_lines(j).line_amt 				:= p_inv_line_list(i).amount;
            trans_lines(j).trx_line_quantity 			:= p_inv_line_list(i).quantity_invoiced;
            trans_lines(j).unit_price 				:= p_inv_line_list(i).unit_price;

            trans_lines(j).product_id 				:= p_inv_line_list(i).inventory_item_id;
            trans_lines(j).product_fisc_classification 		:= p_inv_line_list(i).product_fisc_classification;
            trans_lines(j).product_org_id 			:= l_product_org_id;
            trans_lines(j).uom_code 				:= l_uom_code;
            trans_lines(j).product_type 			:= p_inv_line_list(i).product_type;
            trans_lines(j).product_category 			:= p_inv_line_list(i).product_category;
            trans_lines(j).fob_point 				:= l_fob_point;

            -- 7262269 /*Bug 13079028: Removed the IF-ELSE and called the function directly to handle all cases*/
            --IF p_inv_line_list(i).po_line_location_id IS NOT NULL THEN

            --Bug14039130

	    --bug14189635, changed IF condition to check variable p_inv_line_list instead of l_inv_line_list
            IF p_inv_line_list(i).line_type_lookup_code NOT IN ('MISCELLANEOUS','FREIGHT') THEN
               l_po_line_location_id := p_inv_line_list(i).po_line_location_id;
            ELSE
               l_po_line_location_id := NULL;
            END IF;


            l_ship_to_party_id := get_po_ship_to_org_id (l_po_line_location_id,
	                                                     p_inv_line_list(i).inventory_item_id, /*Bug 13079028*/
							                             p_inv_line_list(i).org_id, /*Bug 13079028*/
							                             p_inv_line_list(i).application_id, /*Bug 13079028*/
							                             p_inv_line_list(i).reference_key5); /*Bug 13079028*/
           /*ELSE
             l_ship_to_party_id := p_inv_line_list(i).org_id;
            END IF;*/ /*Bug 13079028*/

            --Bug14039130

            trans_lines(j).ship_to_party_id		:= l_ship_to_party_id;  /* Changed the subscript from i to j for bug#7319191 */
            -- 7262269
            trans_lines(j).ship_from_party_id 			:= P_Invoice_Header_Rec.party_id;
            trans_lines(j).bill_to_party_id 			:= p_inv_line_list(i).org_id;
            trans_lines(j).bill_from_party_id 			:= P_Invoice_Header_Rec.party_id;
            trans_lines(j).ship_from_party_site_id 		:= P_Invoice_Header_Rec.party_site_id;
            trans_lines(j).bill_from_party_site_id 		:= P_Invoice_Header_Rec.party_site_id;

            trans_lines(j).ship_to_location_id 			:= p_inv_line_list(i).ship_to_location_id;
	        trans_lines(j).ship_from_location_id 		:= l_location_id;
            trans_lines(j).bill_to_location_id 			:= l_bill_to_location_id;
            trans_lines(j).bill_from_location_id 		:= l_location_id;

            trans_lines(j).account_ccid 			:= p_inv_line_list(i).default_dist_ccid;

            trans_lines(j).ref_doc_application_id 		:= l_ref_doc_application_id;
            trans_lines(j).ref_doc_entity_code 			:= l_ref_doc_entity_code;
            trans_lines(j).ref_doc_event_class_code 		:= l_ref_doc_event_class_code;
            trans_lines(j).ref_doc_trx_id 			:= l_ref_doc_trx_id;

            --Bug14039130
	    --bug14189635, changed IF condition to check variable p_inv_line_list instead of l_inv_line_list
            IF p_inv_line_list(i).line_type_lookup_code NOT IN ('MISCELLANEOUS','FREIGHT') THEN
               trans_lines(j).ref_doc_line_id 			:= p_inv_line_list(i).po_line_location_id;
            ELSE
               trans_lines(j).ref_doc_line_id 			:= NULL;
            END IF;
            --Bug14039130

            trans_lines(j).ref_doc_line_quantity 		:= l_ref_doc_line_quantity;
	        trans_lines(j).ref_doc_trx_level_type               := l_ref_doc_trx_level_type; -- bug 8578833

            trans_lines(j).adjusted_doc_application_id 		:= l_adj_doc_application_id;
            trans_lines(j).adjusted_doc_entity_code 		:= l_adj_doc_entity_code;
            trans_lines(j).adjusted_doc_event_class_code 	:= l_adj_doc_event_class_code;
            trans_lines(j).adjusted_doc_trx_id 			:= p_inv_line_list(i).corrected_inv_id;
            trans_lines(j).adjusted_doc_line_id 		:= p_inv_line_list(i).price_correct_inv_line_num;
            trans_lines(j).adjusted_doc_number 			:= l_adj_doc_number;
            trans_lines(j).adjusted_doc_date 			:= l_adj_doc_date;
            trans_lines(j).adjusted_doc_trx_level_type 	        := l_adj_doc_trx_level_type; --Bug8332737

            trans_lines(j).applied_to_application_id 		:= l_applied_to_application_id;
            trans_lines(j).applied_to_entity_code 		:= l_applied_to_entity_code;
            trans_lines(j).applied_to_event_class_code 		:= l_applied_to_event_class_code;


            --Bug14039130
	    --bug14189635, changed IF condition to check variable p_inv_line_list instead of l_inv_line_list
            IF p_inv_line_list(i).line_type_lookup_code NOT IN ('MISCELLANEOUS','FREIGHT') THEN
               trans_lines(j).applied_to_trx_id		 := p_inv_line_list(i).rcv_transaction_id;
            ELSE
               trans_lines(j).applied_to_trx_id		 := NULL;
            END IF;

	    --bug14189635, changed IF condition to check variable p_inv_line_list instead of l_inv_line_list
            IF p_inv_line_list(i).rcv_transaction_id IS NOT NULL AND
               p_inv_line_list(i).line_type_lookup_code NOT IN ('MISCELLANEOUS','FREIGHT') THEN

               trans_lines(j).applied_to_trx_line_id	 := p_inv_line_list(i).po_line_location_id;
            ELSE
               trans_lines(j).applied_to_trx_line_id	 := NULL;
            END IF;
            --Bug14039130

            trans_lines(j).trx_line_number 			:= p_inv_line_list(i).line_number;
            trans_lines(j).trx_line_description 		:= p_inv_line_list(i).description;
            trans_lines(j).product_description 			:= p_inv_line_list(i).item_description;
            trans_lines(j).trx_line_gl_date 			:= p_inv_line_list(i).accounting_date;

            trans_lines(j).assessable_value 			:= p_inv_line_list(i).assessable_value;

            trans_lines(j).ctrl_hdr_tx_appl_flag 		:= l_ctrl_hdr_tx_appl_flag;
            -- The default for the control amount amount is included only in the
            -- case the tax line is tax only and it is RCV matched.
            trans_lines(j).ctrl_total_line_tx_amt		:= l_line_control_amount;

            trans_lines(j).source_application_id   		:= p_inv_line_list(i).source_application_id;
            trans_lines(j).source_entity_code	   		:= p_inv_line_list(i).source_entity_code;
            trans_lines(j).source_event_class_code 		:= p_inv_line_list(i).source_event_class_code;
            trans_lines(j).source_trx_id	   		:= p_inv_line_list(i).source_trx_id;
            trans_lines(j).source_line_id	   		:= p_inv_line_list(i).source_line_id;
            trans_lines(j).source_trx_level_type   		:= p_inv_line_list(i).source_trx_level_type;

            trans_lines(j).input_tax_classification_code 	:= p_inv_line_list(i).tax_classification_code;
--debug log messages added for 6321366
            IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'zx_transaction_lines_gt values ');
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'event_class_code: ' || trans_lines(j).event_class_code);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_id: '           || trans_lines(j).trx_id);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_line_id: '      || trans_lines(j).trx_line_id);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_level_type: '   || trans_lines(j).trx_level_type);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_line_type: '    || trans_lines(j).trx_line_type );
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_level_action: '|| trans_lines(j).line_level_action);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_amt_includes_tax_flag: '|| trans_lines(j).line_amt_includes_tax_flag );
              END IF;

            -- Increase the index for the next line to be included in the pl/sql
            -- table
            j := j + 1;

          END IF; -- l_return_status

        IF (NVL(P_Invoice_Header_Rec.tax_only_rcv_matched_flag, 'N') = 'N') THEN
         -------------------------------------------------------------------
          l_debug_info := 'Step 12: Populate pl/sql table if TAX line';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------
          IF (l_return_status = TRUE ) THEN
            tax_lines.EXTEND(1);
            link_lines.EXTEND(1);

	        tax_lines(k).tax_line_allocation_flag             := 'Y';  /* for bug 6010950 as for
            tax only line we need to pass it as 'Y'. */
            tax_lines(k).summary_tax_line_number := p_inv_line_list(i).line_number;
            tax_lines(k).internal_organization_id := P_Invoice_Header_Rec.org_id;
            tax_lines(k).application_id := 200;
            tax_lines(k).entity_code := 'AP_INVOICES';
            tax_lines(k).event_class_code := p_event_class_code;
            tax_lines(k).trx_id := P_Invoice_Header_Rec.invoice_id;

            -- Not used by AP
            -- tax_lines(k).hrd_trx_user_key1..6

            tax_lines(k).tax_regime_code := p_inv_line_list(i).tax_regime_code;
            tax_lines(k).tax := p_inv_line_list(i).tax;
            tax_lines(k).tax_status_code := p_inv_line_list(i).tax_status_code;
            tax_lines(k).tax_rate_code := nvl(p_inv_line_list(i).tax_rate_code,
                      p_inv_line_list(i).tax_classification_code); --bug6255826

            --Bug10082937
            l_copy_line_dff_flag := NVL(fnd_profile.value('AP_COPY_INV_LINE_DFF'),'N');
            IF l_copy_line_dff_flag = 'Y' THEN
               tax_lines(k).ATTRIBUTE1         :=  p_inv_line_list(i).ATTRIBUTE1;
               tax_lines(k).ATTRIBUTE2         :=  p_inv_line_list(i).ATTRIBUTE2;
               tax_lines(k).ATTRIBUTE3         :=  p_inv_line_list(i).ATTRIBUTE3;
               tax_lines(k).ATTRIBUTE4         :=  p_inv_line_list(i).ATTRIBUTE4;
               tax_lines(k).ATTRIBUTE5         :=  p_inv_line_list(i).ATTRIBUTE5;
               tax_lines(k).ATTRIBUTE6         :=  p_inv_line_list(i).ATTRIBUTE6;
               tax_lines(k).ATTRIBUTE7         :=  p_inv_line_list(i).ATTRIBUTE7;
               tax_lines(k).ATTRIBUTE8         :=  p_inv_line_list(i).ATTRIBUTE8;
               tax_lines(k).ATTRIBUTE9         :=  p_inv_line_list(i).ATTRIBUTE9;
               tax_lines(k).ATTRIBUTE10        :=  p_inv_line_list(i).ATTRIBUTE10;
               tax_lines(k).ATTRIBUTE11        :=  p_inv_line_list(i).ATTRIBUTE11;
               tax_lines(k).ATTRIBUTE12        :=  p_inv_line_list(i).ATTRIBUTE12;
               tax_lines(k).ATTRIBUTE13        :=  p_inv_line_list(i).ATTRIBUTE13;
               tax_lines(k).ATTRIBUTE14        :=  p_inv_line_list(i).ATTRIBUTE14;
               tax_lines(k).ATTRIBUTE15        :=  p_inv_line_list(i).ATTRIBUTE15;   --BUG13719477
               tax_lines(k).ATTRIBUTE_CATEGORY := p_inv_line_list(i).ATTRIBUTE_CATEGORY;
            END IF;
            --Bug10082937
--            tax_lines(k).tax_rate_code := p_inv_line_list(i).tax_rate_code;
--            commented for 6255826
            tax_lines(k).tax_rate := p_inv_line_list(i).tax_rate;
            --- bug 6429993 - we need to populate tax_jurisdiction_code also.
            tax_lines(k).tax_jurisdiction_code :=p_inv_line_list(i).tax_jurisdiction_code;
            tax_lines(k).tax_amt :=  p_inv_line_list(i).amount;



            --------------------------------------------------------------
            l_debug_info := 'Step 13: Populate link structure';
            --------------------------------------------------------------
            link_lines(k).application_id := 200;
            link_lines(k).entity_code := 'AP_INVOICES';
            link_lines(k).event_class_code := p_event_class_code;
            link_lines(k).trx_id := P_Invoice_Header_Rec.invoice_id;
            link_lines(k).trx_level_type := 'LINE';
            link_lines(k).trx_line_id := p_inv_line_list(i).line_number;
            link_lines(k).summary_tax_line_number := p_inv_line_list(i).line_number;
            link_lines(k).line_amt := p_inv_line_list(i).amount;

-- Debug messages added for 6321366
 IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'zx_import_tax_lines_gt values ');
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'summary_tax_line_number: ' || tax_lines(k).summary_tax_line_number);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'application_id: '           || tax_lines(k).application_id);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'event_class_code: '      || tax_lines(k).event_class_code);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_id: '   || tax_lines(k).trx_id);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'tax: '   || tax_lines(k).tax );
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'tax_amt: '    || tax_lines(k).tax_amt );
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'tax_line_allocation_flag: '|| tax_lines(k).tax_line_allocation_flag);
 END IF;
-- Debug messages added for 6321366
IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'zx_trx_tax_link_gt values ');
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'application_id: '           || link_lines(k).application_id);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'entity_code: ' || link_lines(k).entity_code);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'event_class_code: ' || link_lines(k).event_class_code);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_id: '           || link_lines(k).trx_id);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_level_type: '           || link_lines(k).trx_level_type);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_line_id: '           || link_lines(k).trx_line_id);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_amt: '    || link_lines(k).line_amt );
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'summary_tax_line_number: ' || link_lines(k).summary_tax_line_number);
END IF;
            k := k + 1;

          END IF;  -- l_return_status validation for TAX lines
        END IF;
      END IF;
    END LOOP;   -- end of loop in the p_invoice_lines_tab

    ELSE
      -- There are no TRX or TAX lines to validate.  Return without error
      RETURN TRUE;

    END IF;  -- There are TRX or TAX lines in the invoice to be imported

    -------------------------------------------------------------------
    l_debug_info := 'Step 12: Bulk Insert into global temp tables';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF ( l_return_status = TRUE ) THEN

      DELETE FROM zx_transaction_lines_gt
       WHERE application_id   = AP_ETAX_PKG.AP_APPLICATION_ID
         AND entity_code      = AP_ETAX_PKG.AP_ENTITY_CODE
         AND event_class_code IN (AP_ETAX_PKG.AP_INV_EVENT_CLASS_CODE,
                                  AP_ETAX_PKG.AP_PP_EVENT_CLASS_CODE,
                                  AP_ETAX_PKG.AP_ER_EVENT_CLASS_CODE)
         AND trx_id = p_invoice_header_rec.invoice_id;

      IF (trans_lines.COUNT > 0) THEN
        FORALL m IN trans_lines.FIRST..trans_lines.LAST
          INSERT INTO zx_transaction_lines_gt
          VALUES trans_lines(m);
      END IF;

      IF (tax_lines.COUNT > 0) THEN
        FORALL m IN tax_lines.FIRST..tax_lines.LAST
          INSERT INTO zx_import_tax_lines_gt
          VALUES tax_lines(m);


        --Bug10082937
        -------------------------------------------------------------------
        l_debug_info := 'DFFs Of The Tax Lines';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
       -------------------------------------------------------------------
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           IF l_copy_line_dff_flag = 'Y'  THEN
              FOR i IN (SELECT *
                          FROM zx_import_tax_lines_gt
                         WHERE trx_id = P_Invoice_Header_Rec.invoice_id
                           AND application_id = 200
                           AND entity_code ='AP_INVOICES'
                           AND event_class_code IN ('STANDARD INVOICES','PREPAYMENT INVOICES','EXPENSE REPORTS')) LOOP

                        l_debug_info := '1 '|| i.ATTRIBUTE1;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '2 '||i.ATTRIBUTE2;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '3 '||i.ATTRIBUTE3;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '4 '||i.ATTRIBUTE4;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '5 '||i.ATTRIBUTE5;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '6 '||i.ATTRIBUTE6;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '7 '||i.ATTRIBUTE7;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '8 '||i.ATTRIBUTE8;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '9 '||i.ATTRIBUTE8;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '10 '||i.ATTRIBUTE10;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '11 '||i.ATTRIBUTE11;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '12 '||i.ATTRIBUTE12;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '13 '||i.ATTRIBUTE13;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '14 '||i.ATTRIBUTE14;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '15 '||i.ATTRIBUTE15;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := 'Attrib Cat '||i.ATTRIBUTE_CATEGORY;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
              END LOOP;
           END IF;
        END IF;
      --Bug10082937



      END IF;

      -- This bulk insert will only be effective when the invoice is tax_only
      -- and there are tax lines with the tax info to be imported
      IF (link_lines.COUNT > 0) THEN
        FORALL m IN link_lines.FIRST..link_lines.LAST
          INSERT INTO zx_trx_tax_link_gt
          VALUES link_lines(m);
      END IF;

    END IF;

    RETURN l_return_status;

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Header_Rec = '||P_Invoice_Header_Rec.Invoice_Id||
          ' P_Calling_Mode ='||P_Calling_Mode||
          ' P_Error_Code = '||P_Error_Code||
          ' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;

  END Populate_Lines_Import_GT;

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
 |      P_Tax_only_Flag - determine if the invoice is tax only
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
             P_Tax_only_Flag           IN VARCHAR2,
             P_Inv_Rcv_Matched         IN OUT NOCOPY VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN
  IS

    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);

    TYPE Trx_Lines_Tab_Type IS TABLE OF zx_transaction_lines_gt%ROWTYPE;
    TYPE Tax_Lines_Tab_Type IS TABLE OF zx_import_tax_lines_gt%ROWTYPE;
    TYPE Link_Lines_Tab_Type IS TABLE OF zx_trx_tax_link_gt%ROWTYPE;

    trans_lines		Trx_Lines_Tab_Type := Trx_Lines_Tab_Type();
    tax_lines		Tax_Lines_Tab_Type := Tax_Lines_Tab_Type();
    link_lines		Link_Lines_Tab_Type := Link_Lines_Tab_Type();

    l_ctrl_hdr_tx_appl_flag		zx_transaction_lines_gt.ctrl_hdr_tx_appl_flag%TYPE;
    l_line_control_amount		zx_transaction_lines_gt.ctrl_total_line_tx_amt%TYPE;
    l_line_level_action			zx_transaction_lines_gt.line_level_action%TYPE;
    l_line_amt_includes_tax_flag	zx_transaction_lines_gt.line_amt_includes_tax_flag%TYPE;
    l_product_org_id			zx_transaction_lines_gt.product_org_id%TYPE;

    -- Purchase Order
    l_ref_doc_application_id		zx_transaction_lines_gt.ref_doc_application_id%TYPE;
    l_ref_doc_entity_code		zx_transaction_lines_gt.ref_doc_entity_code%TYPE;
    l_ref_doc_event_class_code		zx_transaction_lines_gt.ref_doc_event_class_code%TYPE;
    l_ref_doc_trx_level_type		zx_transaction_lines_gt.ref_doc_trx_level_type%TYPE;
    l_ref_doc_line_quantity		zx_transaction_lines_gt.ref_doc_line_quantity%TYPE;
    l_po_header_curr_conv_rate		po_headers_all.rate%TYPE;

    -- Receipt Matched
    l_applied_to_application_id		zx_transaction_lines_gt.applied_to_application_id%TYPE;
    l_applied_to_entity_code		zx_transaction_lines_gt.applied_to_entity_code%TYPE;
    l_applied_to_event_class_code	zx_transaction_lines_gt.applied_to_event_class_code%TYPE;
    l_trx_receipt_date			zx_transaction_lines_gt.trx_receipt_date%TYPE;
    l_ref_doc_trx_id			zx_transaction_lines_gt.ref_doc_trx_id%TYPE;
    l_uom_code				mtl_units_of_measure.uom_code%TYPE;
    l_dummy				number;

    -- Corrections
    l_adj_doc_application_id		zx_transaction_lines_gt.adjusted_doc_application_id%TYPE;
    l_adj_doc_entity_code		zx_transaction_lines_gt.adjusted_doc_entity_code%TYPE;
    l_adj_doc_event_class_code		zx_transaction_lines_gt.adjusted_doc_event_class_code%TYPE;
    l_adj_doc_number			zx_transaction_lines_gt.adjusted_doc_number%TYPE;
    l_adj_doc_date			zx_transaction_lines_gt.adjusted_doc_date%TYPE;

    l_fob_point                  	po_vendor_sites_all.fob_lookup_code%TYPE;
    l_location_id                       zx_transaction_lines_gt.ship_from_location_id%type;
    l_bill_to_location_id               zx_transaction_lines_gt.bill_to_location_id%TYPE;
    l_po_line_location_id		ap_invoice_lines_interface.po_line_location_id%TYPE;
    l_ship_to_party_id          po_line_locations_all.ship_to_organization_id%type; -- 7262269

    k                           INT := 1;
    l_pseudo                    INT := 1;

    l_return_status	BOOLEAN := TRUE;
    l_api_name		CONSTANT VARCHAR2(100) := 'Populate_Tax_Lines_GT';
    l_prorating_total   number;    ---for bug 6064593
    l_total_prorated    number;    ---for bug 6064593
    l_copy_line_dff_flag         VARCHAR2(1); -- Bug9819170

      l_err varchar2(2000); --bug10140354
  BEGIN

    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.Populate_Tax_Lines_GT<-'||
                               P_calling_sequence;

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_curr_calling_sequence);
    END IF;


    l_fob_point           := AP_ETAX_SERVICES_PKG.g_site_attributes
                                        (p_invoice_header_rec.vendor_site_id).fob_lookup_code;
    l_location_id         := AP_ETAX_SERVICES_PKG.g_site_attributes
                                        (p_invoice_header_rec.vendor_site_id).location_id;
    l_bill_to_location_id := AP_ETAX_SERVICES_PKG.g_org_attributes
                                        (p_invoice_header_rec.org_id).bill_to_location_id;

    IF (P_Tax_only_Flag = 'N') THEN

      -------------------------------------------------------------------
      l_debug_info := 'Step 1: Populate pl/sql table TAX line will be '||
                      'allocated to all the ITEM lines in the invoice';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -------------------------------------------------------------------
      IF ( l_inv_tax_list.COUNT > 0) THEN
        tax_lines.EXTEND(l_inv_tax_list.COUNT);

        FOR i IN l_inv_tax_list.FIRST..l_inv_tax_list.LAST LOOP

            tax_lines(i).summary_tax_line_number	:= l_inv_tax_list(i).line_number;
            tax_lines(i).internal_organization_id	:= l_inv_tax_list(i).org_id;
            tax_lines(i).application_id 		:= 200;
            tax_lines(i).entity_code 			:= 'AP_INVOICES';
            tax_lines(i).event_class_code 		:= p_event_class_code;
            tax_lines(i).trx_id 			:= l_inv_tax_list(i).invoice_id;

            tax_lines(i).tax_regime_code		:= l_inv_tax_list(i).tax_regime_code;
            tax_lines(i).tax				:= l_inv_tax_list(i).tax;
            tax_lines(i).tax_status_code		:= l_inv_tax_list(i).tax_status_code;
            tax_lines(i).tax_rate_code			:= l_inv_tax_list(i).tax_rate_code;
            tax_lines(i).tax_rate			:= l_inv_tax_list(i).tax_rate;
            tax_lines(i).tax_amt			:= l_inv_tax_list(i).amount;
            tax_lines(i).tax_jurisdiction_code		:= l_inv_tax_list(i).tax_jurisdiction_code;
            tax_lines(i).tax_rate_id                    := l_inv_tax_list(i).tax_rate_id;

            tax_lines(i).tax_amt_included_flag		:= 'N';

            --Bug9819170
            l_copy_line_dff_flag := NVL(fnd_profile.value('AP_COPY_INV_LINE_DFF'),'N');
            IF l_copy_line_dff_flag = 'Y' THEN
               tax_lines(i).ATTRIBUTE1         :=  l_inv_tax_list(i).ATTRIBUTE1;
               tax_lines(i).ATTRIBUTE2         :=  l_inv_tax_list(i).ATTRIBUTE2;
               tax_lines(i).ATTRIBUTE3         :=  l_inv_tax_list(i).ATTRIBUTE3;
               tax_lines(i).ATTRIBUTE4         :=  l_inv_tax_list(i).ATTRIBUTE4;
               tax_lines(i).ATTRIBUTE5         :=  l_inv_tax_list(i).ATTRIBUTE5;
               tax_lines(i).ATTRIBUTE6         :=  l_inv_tax_list(i).ATTRIBUTE6;
               tax_lines(i).ATTRIBUTE7         :=  l_inv_tax_list(i).ATTRIBUTE7;
               tax_lines(i).ATTRIBUTE8         :=  l_inv_tax_list(i).ATTRIBUTE8;
               tax_lines(i).ATTRIBUTE9         :=  l_inv_tax_list(i).ATTRIBUTE9;
               tax_lines(i).ATTRIBUTE10        :=  l_inv_tax_list(i).ATTRIBUTE10;
               tax_lines(i).ATTRIBUTE11        :=  l_inv_tax_list(i).ATTRIBUTE11;
               tax_lines(i).ATTRIBUTE12        :=  l_inv_tax_list(i).ATTRIBUTE12;
               tax_lines(i).ATTRIBUTE13        :=  l_inv_tax_list(i).ATTRIBUTE13;
               tax_lines(i).ATTRIBUTE14        :=  l_inv_tax_list(i).ATTRIBUTE14;
               tax_lines(i).ATTRIBUTE15        :=  l_inv_tax_list(i).ATTRIBUTE15;       --BUG13719477
               tax_lines(i).ATTRIBUTE_CATEGORY := l_inv_tax_list(i).ATTRIBUTE_CATEGORY;
            END IF;
            --Bug9819170

            --Start For bug 6064593 - if there is allocation information provided
            --for the manual tax line then We need to populate zx_trx_tax_link_gt.
            --ie if line_group_number is provided on the tax line and
            --ITEM line then we need to populate the zx_trx_tax_link_gt
            --with the allocation info.And we need to pass tax_line_allocation_flag
            --as 'Y' in zx_import_tax_lines_gt for the tax line.

          IF  (l_inv_tax_list(i).prorate_across_all_items = 'Y'AND
                l_inv_tax_list(i).line_group_number IS NOT NULL) THEN
                tax_lines(i).tax_line_allocation_flag       := 'Y';
          ELSE
                tax_lines(i).tax_line_allocation_flag       := 'N';
          END IF;
-- Debug messages added for 6321366
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'zx_import_tax_lines_gt values ');
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'summary_tax_line_number: ' || tax_lines(i).summary_tax_line_number);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'application_id: '           || tax_lines(i).application_id);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'event_class_code: '      || tax_lines(i).event_class_code);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_id: '   || tax_lines(i).trx_id);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'tax: '   || tax_lines(i).tax );
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'tax_amt: '    || tax_lines(i).tax_amt );
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'tax_amt_included_flag: '|| tax_lines(i).tax_amt_included_flag);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'tax_line_allocation_flag: '|| tax_lines(i).tax_line_allocation_flag);
          END IF;

               -------------------------------------------------------------------
               l_debug_info := 'Step 13: Populate allocation structure if needed';
               IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                  FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
               END IF;
               -------------------------------------------------------------------

                  IF (l_inv_tax_list(i).prorate_across_all_items = 'Y' AND
                     l_inv_tax_list(i).line_group_number IS NOT NULL) THEN

                      --------------------------------------------------------------
                      l_debug_info := 'Step 17: Get prorated total';
                      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                      END IF;
                      --------------------------------------------------------------

					  SELECT SUM(NVL(amount, 0))
                        INTO l_prorating_total
                        FROM ap_invoice_lines
                       WHERE invoice_id = l_inv_tax_list(i).invoice_id
                         AND line_number <> l_inv_tax_list(i).line_number
						 AND line_type_lookup_code <> 'TAX'   --Bug6608702
                         AND line_group_number = l_inv_tax_list(i).line_group_number;

					  /************************************************************
					  Bug6608702- Ebtax expects the line amount in
					  zx_trx_tax_link_gt for each TAX line to be the sum of line
					  amounts of all ITEM lines under same line_group_number.
					  Here All the things worked fine till there was only one tax
					  line linked to ITEM line. When a ITEM line is linked to
					  multiple TAX lines through line_group_number then existing
                      logic did sum of all the lines for the same line_group_no
                      except current TAX line. So other TAX lines within the
                      same line_group_number are also considered. To avoid this
                      we added another WHERE clause line_type_lookup_code <> 'TAX'
                      This would avoid TAX line amount to be considered in the
                      query.
   		              ************************************************************/

					  --------------------------------------------------------------
                      l_debug_info := 'Step 18: Get Insert in global temp table';
                      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                      END IF;
                      --------------------------------------------------------------

                      IF (l_prorating_total <> 0) THEN
                        INSERT INTO zx_trx_tax_link_gt (
                          application_id,
                          entity_code,
                          event_class_code,
                          trx_id,
                          trx_level_type,
                          trx_line_id,
                          summary_tax_line_number,
                          line_amt
                        ) SELECT
                            200,                                           -- application_id
                            'AP_INVOICES',                                 -- entity_code
                            p_event_class_code,                            -- event_class_code
                            l_inv_tax_list(i).invoice_id,               -- trx_id
                            'LINE',                                        -- trx_level_type
                            ail.line_number,                              -- trx_line_id
                            l_inv_tax_list(i).line_number,                -- summary_tax_line_number
                            AP_UTILITIES_PKG.ap_round_currency(
                              l_inv_tax_list(i).amount*ail.amount/l_prorating_total,
                              l_inv_header_rec2.invoice_currency_code)  -- line_amt
                           FROM ap_invoice_lines ail
                          WHERE ail.invoice_id = l_inv_tax_list(i).invoice_id
                            AND ail.line_number <> l_inv_tax_list(i).line_number
							AND ail.line_type_lookup_code <> 'TAX'   --Bug6608702
                            AND ail.line_group_number = l_inv_tax_list(i).line_group_number;
-- Debug messages added for 6321366
               IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                  FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'Rows instrted in zx_trx_tax_link_gt: '|| sql%rowcount);
               END IF;
                      --------------------------------------------------------------
                      l_debug_info := 'Step 19: Verify if there is any rounding and '||
                                      'apply it to max of largest.';
                      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                      END IF;
                      --------------------------------------------------------------
                      BEGIN
                        SELECT SUM(NVL(line_amt,0))
                          INTO l_total_prorated
                          FROM zx_trx_tax_link_gt
                         WHERE trx_id = l_inv_tax_list(i).invoice_id
                           AND summary_tax_line_number = l_inv_tax_list(i).line_number;

                        IF (NVL(l_inv_tax_list(i).amount, 0) <> l_total_prorated) THEN
                          UPDATE zx_trx_tax_link_gt
                             SET line_amt = line_amt + (l_inv_tax_list(i).amount - l_total_prorated)
                           WHERE trx_id = l_inv_tax_list(i).invoice_id
                             AND trx_line_id <> l_inv_tax_list(i).line_number
                             AND trx_line_id =
                                (SELECT (MAX(ail.line_number))
                                   FROM ap_invoice_lines ail
                                  WHERE ail.invoice_id = l_inv_tax_list(i).invoice_id
                                    AND ail.line_number <> l_inv_tax_list(i).line_number
									AND ail.line_type_lookup_code <> 'TAX'   --Bug6608702
                                    AND ail.amount <> 0
                                    AND ail.line_group_number = l_inv_tax_list(i).line_group_number
                                    AND ABS(ail.amount) >=
                                      ( SELECT  MAX(ABS(ail2.amount))
                                          FROM  ap_invoice_lines ail2
                                         WHERE  ail2.invoice_id = ail.invoice_id
                                           AND  ail2.line_number <> l_inv_tax_list(i).line_number
                                           AND  ail2.line_number <> ail.line_number
										   AND  ail2.line_type_lookup_code <> 'TAX'   --Bug6608702
                                           AND  ail2.line_group_number =
                                                  l_inv_tax_list(i).line_group_number));
                      END IF;
                      EXCEPTION
                        WHEN OTHERS THEN
                          l_return_status := FALSE;
                      END;

                     END IF;  -- l_prorating_total <> 0
-- bug 8680775: add start
                -- Added functionality to import tax only lines
                -- case only when prorate across flag is set to 'N'
                ELSIF (l_inv_tax_list(i).prorate_across_all_items = 'N' AND l_inv_tax_list(i).line_source = 'IMPORTED') THEN

                --Added line_source condition for Bug9074940

                      -- allocation flag is marked as N (above) when prorate accross flag is not Y
                      tax_lines(i).tax_line_allocation_flag           := 'Y';

                      trans_lines.EXTEND(1);
                      link_lines.EXTEND(1);

                      -- add pseudo line for manual non prorated tax line
                      trans_lines(l_pseudo).application_id := 200;
                      trans_lines(l_pseudo).entity_code := 'AP_INVOICES';
                      trans_lines(l_pseudo).event_class_code := p_event_class_code;
                      trans_lines(l_pseudo).trx_id := P_Invoice_Header_Rec.invoice_id;
                      trans_lines(l_pseudo).trx_level_type := 'LINE';
                      trans_lines(l_pseudo).trx_line_id := l_inv_tax_list(i).line_number;
                      trans_lines(l_pseudo).line_level_action := 'LINE_INFO_TAX_ONLY';

                      trans_lines(l_pseudo).trx_line_type := l_inv_tax_list(i).line_type_lookup_code;
                      trans_lines(l_pseudo).trx_line_date := P_Invoice_Header_Rec.invoice_date;
                      trans_lines(l_pseudo).trx_business_category := l_inv_tax_list(i).trx_business_category;
                      trans_lines(l_pseudo).line_intended_use := l_inv_tax_list(i).primary_intended_use;
                      trans_lines(l_pseudo).user_defined_fisc_class := l_inv_tax_list(i).user_defined_fisc_class;
                      trans_lines(l_pseudo).line_amt := l_inv_tax_list(i).amount;
                      trans_lines(l_pseudo).trx_line_quantity := l_inv_tax_list(i).quantity_invoiced;
                      trans_lines(l_pseudo).unit_price := l_inv_tax_list(i).unit_price;

                      trans_lines(l_pseudo).product_id := l_inv_tax_list(i).inventory_item_id;
                      trans_lines(l_pseudo).product_fisc_classification := l_inv_tax_list(i).product_fisc_classification;
                      trans_lines(l_pseudo).product_type := l_inv_tax_list(i).product_type;
                      trans_lines(l_pseudo).product_category := l_inv_tax_list(i).product_category;
                      trans_lines(l_pseudo).fob_point := l_fob_point;
                      trans_lines(l_pseudo).ship_to_party_id:= l_inv_tax_list(i).org_id;

                      trans_lines(l_pseudo).ship_from_party_id := P_Invoice_Header_Rec.party_id;

                      trans_lines(l_pseudo).bill_to_party_id:= l_inv_tax_list(i).org_id;
                      trans_lines(l_pseudo).bill_from_party_id:= P_Invoice_Header_Rec.party_id;
                      trans_lines(l_pseudo).ship_from_party_site_id:= P_Invoice_Header_Rec.party_site_id;
                      trans_lines(l_pseudo).bill_from_party_site_id:= P_Invoice_Header_Rec.party_site_id;

                      trans_lines(l_pseudo).ship_to_location_id:= l_inv_tax_list(i).ship_to_location_id;
                      trans_lines(l_pseudo).ship_from_location_id:= l_location_id;
                      trans_lines(l_pseudo).bill_to_location_id:= l_bill_to_location_id;
                      trans_lines(l_pseudo).bill_from_location_id:= l_location_id;

                      trans_lines(l_pseudo).account_ccid:= l_inv_tax_list(i).default_dist_ccid;
                      trans_lines(l_pseudo).merchant_party_country:= l_inv_tax_list(i).country_of_supply;

                      trans_lines(l_pseudo).trx_line_number:= l_inv_tax_list(i).line_number;
                      trans_lines(l_pseudo).trx_line_description:= l_inv_tax_list(i).description;
                      trans_lines(l_pseudo).product_description:= l_inv_tax_list(i).item_description;
                      trans_lines(l_pseudo).trx_line_gl_date:= l_inv_tax_list(i).accounting_date;

                      trans_lines(l_pseudo).merchant_party_name:= l_inv_tax_list(i).merchant_name;
                      trans_lines(l_pseudo).merchant_party_document_number:= l_inv_tax_list(i).merchant_document_number;
                      trans_lines(l_pseudo).merchant_party_reference:= l_inv_tax_list(i).merchant_reference;
                      trans_lines(l_pseudo).merchant_party_taxpayer_id:= l_inv_tax_list(i).merchant_taxpayer_id;
                      trans_lines(l_pseudo).merchant_party_tax_reg_number:= l_inv_tax_list(i).merchant_tax_reg_number;

                      trans_lines(l_pseudo).assessable_value:= l_inv_tax_list(i).assessable_value;

                      IF (l_Inv_tax_List(i).po_line_location_id IS NOT NULL) THEN
                          -- NONE
                          l_line_amt_includes_tax_flag := 'N';
                      ELSE
                          IF (p_calling_mode = 'CALCULATE QUOTE')
                          OR
                         (p_invoice_header_rec.invoice_type_lookup_code = 'EXPENSE REPORT'
                          and nvl(l_inv_tax_list(i).line_type_lookup_code, 'N') <> 'PREPAY') THEN
                             -- ALL
                             l_line_amt_includes_tax_flag := 'A';
                          ELSE
                             -- STANDARD
                             l_line_amt_includes_tax_flag := 'S';
                          END IF;
                      END IF;
                      trans_lines(l_pseudo).line_amt_includes_tax_flag:= l_line_amt_includes_tax_flag;
                      trans_lines(l_pseudo).historical_flag:= 'N';

                      IF P_Invoice_Header_Rec.control_amount IS NOT NULL THEN
                         l_ctrl_hdr_tx_appl_flag := 'Y';
                      ELSE
                         l_ctrl_hdr_tx_appl_flag := 'N';
                      END IF;
                      trans_lines(l_pseudo).ctrl_hdr_tx_appl_flag:= l_ctrl_hdr_tx_appl_flag;
                      trans_lines(l_pseudo).ctrl_total_line_tx_amt:= l_inv_tax_list(i).control_amount;

                      trans_lines(l_pseudo).source_application_id:= l_inv_tax_list(i).source_application_id;
                      trans_lines(l_pseudo).source_entity_code   := l_inv_tax_list(i).source_entity_code;
                      trans_lines(l_pseudo).source_event_class_code := l_inv_tax_list(i).source_event_class_code;
                      trans_lines(l_pseudo).source_trx_id   := l_inv_tax_list(i).source_trx_id;
                      trans_lines(l_pseudo).source_line_id   := l_inv_tax_list(i).source_line_id;
                      trans_lines(l_pseudo).source_trx_level_type:= l_inv_tax_list(i).source_trx_level_type;

                      trans_lines(l_pseudo).input_tax_classification_code:= l_inv_tax_list(i).tax_classification_code;

                      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'zx_transaction_lines_gt values ');
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'event_class_code: ' || trans_lines(l_pseudo).event_class_code);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_id: '           || trans_lines(l_pseudo).trx_id);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_line_id: '      || trans_lines(l_pseudo).trx_line_id);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_level_type: '   || trans_lines(l_pseudo).trx_level_type);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_line_type: '    || trans_lines(l_pseudo).trx_line_type );
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_level_action: '|| trans_lines(l_pseudo).line_level_action);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_amt: '         || trans_lines(l_pseudo).line_amt);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'unit_price: '       || trans_lines(l_pseudo).unit_price);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_amt_includes_tax_flag: ' || trans_lines(l_pseudo).line_amt_includes_tax_flag );
                      END IF;

                      -- add to link gt
                      link_lines(l_pseudo).application_id:= 200;
                      link_lines(l_pseudo).entity_code:= 'AP_INVOICES';
                      link_lines(l_pseudo).event_class_code:= p_event_class_code;
                      link_lines(l_pseudo).trx_id:= P_Invoice_Header_Rec.invoice_id;
                      link_lines(l_pseudo).trx_level_type:= 'LINE';
                      link_lines(l_pseudo).trx_line_id:= l_inv_tax_list(i).line_number;
                      link_lines(l_pseudo).summary_tax_line_number:= l_inv_tax_list(i).line_number;
                      link_lines(l_pseudo).line_amt:= l_inv_tax_list(i).amount;

                      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'zx_trx_tax_link_gt values ');
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'summary_tax_line_number: ' || link_lines(l_pseudo).summary_tax_line_number);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'application_id: '           || link_lines(l_pseudo).application_id);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'event_class_code: '      || link_lines(l_pseudo).event_class_code);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_id: '   || link_lines(l_pseudo).trx_id);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_level_type: '   || link_lines(l_pseudo).trx_level_type );
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_line_id: '   || link_lines(l_pseudo).trx_line_id);
                          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_amt: '    || link_lines(l_pseudo).line_amt );
                      END IF;

                      l_pseudo := l_pseudo + 1;
-- bug 8680775: add end
                  END IF;  -- prorate_accross_flag = 'Y' and line_group_number is not null

            ---End for bug 6064593

        END LOOP;
      END IF; -- is tax pl/sql table populated?

    ELSE
      -- Invoice is tax-only.  We have 2 scenarios.
      -- TAX lines created for the  match other charges case (no tax
      -- information populated and it is expected to call calculate_Tax), and
      -- TAX lines manually created not allocated to any ITEM line in
      -- the invoice.
      -- It is restricted to have both types of tax-only lines in the
      -- same invoice, so we can assume that if the TAX line has populated
      -- the RCV_TRANSACTION_ID field it is a match other charges case.
      -- In this case we expect the tax columns to be null and the we require
      -- the control amount to be populated so that eTax will know how much the
      -- tax should be. In this case we will populate the
      -- zx_transaction_lines_gt GT table.
      -- For the second case, where the tax lines are manually created we will
      -- populate both zx_transaction_lines_gt and zx_import_tax_lines_gt.  It
      -- is also required to populate the zx_trx_tax_link_gt with a one to one
      -- allocation.


      -------------------------------------------------------------------
      l_debug_info := 'Step 4: Populate pl/sql table.  TRX only if match'||
                      'to receipt, and the three GT tables in the other case';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -------------------------------------------------------------------
      IF ( l_inv_tax_list.COUNT > 0) THEN

        trans_lines.EXTEND(l_inv_tax_list.COUNT);

        FOR i IN l_inv_tax_list.FIRST..l_inv_tax_list.LAST LOOP
          -- since for the 2 cases we need to populate the trans_lines pl/sql
          -- table, we populate it and if the rcv_transaction_id is not null
          -- we set the flag P_Inv_Rcv_Matched to Y.  If it is not RCV matched, we
          -- will not modified the flag since N is the initial value and will
          -- populate the zx_import_tax_lines_gt and zx_trx_tax_link_gt GT tables

          -------------------------------------------------------------------
          l_debug_info := 'Step 5: Get line_level_action for TAX ONLY line '||
                          'number:'||l_inv_tax_list(i).line_number;
    	  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------
          IF (l_inv_tax_list(i).rcv_transaction_id IS NOT NULL) THEN
            -- In this case  eTax will need to run tax
            -- applicability and calculation because it is the matched to other
            -- charges case.
            -- since the control amount at line level is required for eTax in
            -- this case we will set it right away

            l_line_level_action := 'CREATE_TAX_ONLY';
            P_Inv_Rcv_Matched := 'Y';
            l_line_control_amount :=
              NVL(l_inv_tax_list(i).control_amount, l_inv_tax_list(i).amount);


          ELSE
            -- Invoice is tax-only, and there is no need to run applicability.
            -- In this case the user provides all the tax information for the line
            -- to be imported.  The additional taxable related info
            -- that eTax need to store will be passed to eTax using a pseudo line
            -- in the zx_transaction_lines_gt table.

            l_line_level_action := 'LINE_INFO_TAX_ONLY';
            l_line_control_amount := l_inv_tax_list(i).control_amount;

          END IF;

          -------------------------------------------------------------------
          l_debug_info := 'Step 6: Get Additional PO matched info if any ';
	      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------
          IF ( l_Inv_tax_List(i).po_line_location_id IS NOT NULL) THEN
              -- this assigned is required since the p_po_line_location_id
              -- parameter is IN/OUT.  However, in this case it will not be
              -- modified because the po_distribution_id is not provided
              l_po_line_location_id := l_Inv_tax_List(i).po_line_location_id;

            IF NOT (AP_ETAX_UTILITY_PKG.Get_PO_Info(
               P_Po_Line_Location_Id         => l_po_line_location_id,
               P_PO_Distribution_Id          => null,
               P_Application_Id              => l_ref_doc_application_id,
               P_Entity_code                 => l_ref_doc_entity_code,
               P_Event_Class_Code            => l_ref_doc_event_class_code,
               P_PO_Quantity                 => l_ref_doc_line_quantity,
               P_Product_Org_Id              => l_product_org_id,
               P_Po_Header_Id                => l_ref_doc_trx_id,
               P_Po_Header_curr_conv_rate    => l_po_header_curr_conv_rate,
               P_Uom_Code                    => l_uom_code,
               P_Dist_Qty                    => l_dummy,
               P_Ship_Price                  => l_dummy,
               P_Error_Code                  => P_error_code,
               P_Calling_Sequence            => l_curr_calling_sequence)) THEN

             --bug10140354
	     insert into ap_errors_gt(invoice_id , message_text) values (P_Invoice_Header_Rec.Invoice_id , 'Error in Get_PO_Info ');
	      l_return_status := FALSE;
            END IF;

            l_ref_doc_trx_level_type := 'SHIPMENT';

          ELSE
            l_ref_doc_application_id     := Null;
            l_ref_doc_entity_code        := Null;
            l_ref_doc_event_class_code   := Null;
            l_ref_doc_line_quantity      := Null;
            l_product_org_id             := Null;
            l_ref_doc_trx_id             := Null;
            l_ref_doc_trx_level_type     := Null;
          END IF;

          -------------------------------------------------------------------
          l_debug_info := 'Step 7: Get Additional receipt matched info ';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------
          IF ( l_return_status = TRUE AND
               l_Inv_tax_List(i).rcv_transaction_id IS NOT NULL) THEN
            IF NOT (AP_ETAX_UTILITY_PKG.Get_Receipt_Info(
               P_Rcv_Transaction_Id          => l_Inv_tax_List(i).rcv_transaction_id,
               P_Application_Id              => l_applied_to_application_id,
               P_Entity_code                 => l_applied_to_entity_code,
               P_Event_Class_Code            => l_applied_to_event_class_code,
               P_Transaction_Date            => l_trx_receipt_date,
               P_Error_Code                  => P_error_code,
               P_Calling_Sequence            => l_curr_calling_sequence)) THEN

              --bug10140354
	       insert into ap_errors_gt(invoice_id , message_text) values (P_Invoice_Header_Rec.Invoice_id , 'Error in Get_Receipt_Info');
	       l_return_status := FALSE;
            END IF;
          ELSE
            l_applied_to_application_id   := Null;
            l_applied_to_entity_code      := Null;
            l_applied_to_event_class_code := Null;
            l_trx_receipt_date            := Null;
          END IF;

          -------------------------------------------------------------------
          l_debug_info := 'Step 8: Get Additional Correction Invoice Info ';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------
          IF ( l_return_status = TRUE AND
               l_Inv_tax_List(i).corrected_inv_id IS NOT NULL AND
               l_Inv_tax_list(i).corrected_line_number IS NOT NULL) THEN
            IF NOT (AP_ETAX_UTILITY_PKG.Get_Corrected_Invoice_Info(
               P_Corrected_Invoice_Id        => l_Inv_tax_List(i).corrected_inv_id,
               P_Corrected_Line_Number       => l_Inv_tax_List(i).corrected_line_number,
               P_Application_Id              => l_adj_doc_application_id,
               P_Entity_code                 => l_adj_doc_entity_code,
               P_Event_Class_Code            => l_adj_doc_event_class_code,
               P_Invoice_Number              => l_adj_doc_number,
               P_Invoice_Date                => l_adj_doc_date,
               P_Error_Code                  => P_error_code,
               P_Calling_Sequence            => l_curr_calling_sequence)) THEN

            --bug10140354
	     insert into ap_errors_gt(invoice_id , message_text) values (P_Invoice_Header_Rec.Invoice_id , 'Error in Get_Corrected_Invoice_Info');
	      l_return_status := FALSE;
            END IF;

          ELSE
            l_adj_doc_application_id   := Null;
            l_adj_doc_entity_code      := Null;
            l_adj_doc_event_class_code := Null;
            l_adj_doc_number           := Null;
            l_adj_doc_date             := Null;
          END IF;

          -------------------------------------------------------------------
          l_debug_info := 'Step 9: Get line_amt_includes_tax_flag';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------

          IF (l_Inv_tax_List(i).po_line_location_id IS NOT NULL) THEN
            -- NONE
            l_line_amt_includes_tax_flag := 'N';

          ELSE
           IF (p_calling_mode = 'CALCULATE QUOTE')
              OR
              (p_invoice_header_rec.invoice_type_lookup_code = 'EXPENSE REPORT'
               and nvl(l_inv_tax_list(i).line_type_lookup_code, 'N') <> 'PREPAY') THEN
             -- ALL
             l_line_amt_includes_tax_flag := 'A';

           ELSE
             -- STANDARD
             l_line_amt_includes_tax_flag := 'S';

           END IF;
          END IF;

          -------------------------------------------------------------------
          l_debug_info := 'Step 10: Get ctrl_hdr_tx_appl_flag';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------
          IF P_Invoice_Header_Rec.control_amount IS NOT NULL THEN
            l_ctrl_hdr_tx_appl_flag := 'Y';
          ELSE
            l_ctrl_hdr_tx_appl_flag := 'N';
          END IF;

          -------------------------------------------------------------------
          l_debug_info := 'Step 11: Populate pl/sql table';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------
          IF (l_return_status = TRUE ) THEN

            trans_lines(i).application_id 			:= 200;
            trans_lines(i).entity_code 				:= 'AP_INVOICES';
            trans_lines(i).event_class_code 			:= p_event_class_code;
            trans_lines(i).trx_id 				:= P_Invoice_Header_Rec.invoice_id;
            trans_lines(i).trx_level_type 			:= 'LINE';
            trans_lines(i).trx_line_id 				:= l_inv_tax_list(i).line_number;
            trans_lines(i).line_level_action 			:= l_line_level_action;

            trans_lines(i).trx_receipt_date 			:= l_trx_receipt_date;
            trans_lines(i).trx_line_type 			:= l_inv_tax_list(i).line_type_lookup_code;
            trans_lines(i).trx_line_date 			:= P_Invoice_Header_Rec.invoice_date;
            trans_lines(i).trx_business_category 		:= l_inv_tax_list(i).trx_business_category;
            trans_lines(i).line_intended_use 			:= l_inv_tax_list(i).primary_intended_use;
            trans_lines(i).user_defined_fisc_class 		:= l_inv_tax_list(i).user_defined_fisc_class;
            trans_lines(i).line_amt 				:= l_inv_tax_list(i).amount;
            trans_lines(i).trx_line_quantity 			:= l_inv_tax_list(i).quantity_invoiced;
            trans_lines(i).unit_price 				:= l_inv_tax_list(i).unit_price;

            trans_lines(i).product_id 				:= l_inv_tax_list(i).inventory_item_id;
            trans_lines(i).product_fisc_classification 		:= l_inv_tax_list(i).product_fisc_classification;
            trans_lines(i).product_org_id 			:= l_product_org_id;
            trans_lines(i).uom_code 				:= l_uom_code;
            trans_lines(i).product_type 			:= l_inv_tax_list(i).product_type;
            trans_lines(i).product_category 			:= l_inv_tax_list(i).product_category;
            trans_lines(i).fob_point 				:= l_fob_point;

            -- 7262269 /*Bug 13079028: Removed the IF-ELSE and called the function directly to handle all cases*/
            --IF l_inv_tax_list(i).po_line_location_id IS NOT NULL THEN
             l_ship_to_party_id := get_po_ship_to_org_id (l_inv_tax_list(i).po_line_location_id,
	                                                  l_inv_tax_list(i).inventory_item_id, /*Bug 13079028*/
							  l_inv_tax_list(i).org_id, /*Bug 13079028*/
							  l_inv_tax_list(i).application_id, /*Bug 13079028*/
							  l_inv_tax_list(i).reference_key5); /*Bug 13079028*/
           /*ELSE
             l_ship_to_party_id := l_inv_tax_list(i).org_id;
            END IF;*/ /*Bug 13079028*/

            trans_lines(i).ship_to_party_id		:= l_ship_to_party_id;
            -- 7262269

            trans_lines(i).ship_from_party_id 			:= P_Invoice_Header_Rec.party_id;

            trans_lines(i).bill_to_party_id			:= l_inv_tax_list(i).org_id;
            trans_lines(i).bill_from_party_id			:= P_Invoice_Header_Rec.party_id;
            trans_lines(i).ship_from_party_site_id		:= P_Invoice_Header_Rec.party_site_id;
            trans_lines(i).bill_from_party_site_id		:= P_Invoice_Header_Rec.party_site_id;

            trans_lines(i).ship_to_location_id			:= l_inv_tax_list(i).ship_to_location_id;
	        trans_lines(i).ship_from_location_id		:= l_location_id;
            trans_lines(i).bill_to_location_id			:= l_bill_to_location_id;
            trans_lines(i).bill_from_location_id		:= l_location_id;

            trans_lines(i).account_ccid				:= l_inv_tax_list(i).default_dist_ccid;
            trans_lines(i).merchant_party_country		:= l_inv_tax_list(i).country_of_supply;

            trans_lines(i).ref_doc_application_id		:= l_ref_doc_application_id;
            trans_lines(i).ref_doc_entity_code			:= l_ref_doc_entity_code;
            trans_lines(i).ref_doc_event_class_code		:= l_ref_doc_event_class_code;
            trans_lines(i).ref_doc_trx_id			:= l_ref_doc_trx_id;
            trans_lines(i).ref_doc_line_id			:= l_inv_tax_list(i).po_line_location_id;
            trans_lines(i).ref_doc_line_quantity		:= l_ref_doc_line_quantity;
	        trans_lines(i).ref_doc_trx_level_type               := l_ref_doc_trx_level_type; -- bug 8578833

            trans_lines(i).adjusted_doc_application_id		:= l_adj_doc_application_id;
            trans_lines(i).adjusted_doc_entity_code		:= l_adj_doc_entity_code;
            trans_lines(i).adjusted_doc_event_class_code	:= l_adj_doc_event_class_code;
            trans_lines(i).adjusted_doc_trx_id			:= l_inv_tax_list(i).corrected_inv_id;
            trans_lines(i).adjusted_doc_line_id			:= l_inv_tax_list(i).corrected_line_number;
            trans_lines(i).adjusted_doc_number			:= l_adj_doc_number;
            trans_lines(i).adjusted_doc_date			:= l_adj_doc_date;

            trans_lines(i).applied_to_application_id		:= l_applied_to_application_id;
            trans_lines(i).applied_to_entity_code		:= l_applied_to_entity_code;
            trans_lines(i).applied_to_event_class_code		:= l_applied_to_event_class_code;
            trans_lines(i).applied_to_trx_id			:= l_inv_tax_list(i).rcv_transaction_id;

	        IF l_inv_tax_list(i).rcv_transaction_id IS NOT NULL THEN
	           trans_lines(i).applied_to_trx_line_id		:= l_inv_tax_list(i).po_line_location_id;
            END IF;

            trans_lines(i).trx_line_number			:= l_inv_tax_list(i).line_number;
            trans_lines(i).trx_line_description			:= l_inv_tax_list(i).description;
            trans_lines(i).product_description			:= l_inv_tax_list(i).item_description;
            trans_lines(i).trx_line_gl_date			:= l_inv_tax_list(i).accounting_date;

            trans_lines(i).merchant_party_name			:= l_inv_tax_list(i).merchant_name;
            trans_lines(i).merchant_party_document_number	:= l_inv_tax_list(i).merchant_document_number;
            trans_lines(i).merchant_party_reference		:= l_inv_tax_list(i).merchant_reference;
            trans_lines(i).merchant_party_taxpayer_id		:= l_inv_tax_list(i).merchant_taxpayer_id;
            trans_lines(i).merchant_party_tax_reg_number	:= l_inv_tax_list(i).merchant_tax_reg_number;

            trans_lines(i).assessable_value			:= l_inv_tax_list(i).assessable_value;
            trans_lines(i).line_amt_includes_tax_flag		:= l_line_amt_includes_tax_flag;
            trans_lines(i).historical_flag			:= 'N';

            trans_lines(i).ctrl_hdr_tx_appl_flag		:= l_ctrl_hdr_tx_appl_flag;
            trans_lines(i).ctrl_total_line_tx_amt		:= l_line_control_amount;

            trans_lines(i).source_application_id		:= l_inv_tax_list(i).source_application_id;
            trans_lines(i).source_entity_code	   		:= l_inv_tax_list(i).source_entity_code;
            trans_lines(i).source_event_class_code 		:= l_inv_tax_list(i).source_event_class_code;
            trans_lines(i).source_trx_id	   		:= l_inv_tax_list(i).source_trx_id;
            trans_lines(i).source_line_id	   		:= l_inv_tax_list(i).source_line_id;
            trans_lines(i).source_trx_level_type		:= l_inv_tax_list(i).source_trx_level_type;

            trans_lines(i).input_tax_classification_code	:= l_inv_tax_list(i).tax_classification_code;
-- Debug messages added for 6321366
           IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'zx_transaction_lines_gt values ');
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'event_class_code: ' || trans_lines(i).event_class_code);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_id: '           || trans_lines(i).trx_id);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_line_id: '      || trans_lines(i).trx_line_id);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_level_type: '   || trans_lines(i).trx_level_type);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_line_type: '    || trans_lines(i).trx_line_type );
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_level_action: '|| trans_lines(i).line_level_action);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_amt: '         || trans_lines(i).line_amt);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'unit_price: '       || trans_lines(i).unit_price);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_amt_includes_tax_flag: '       || trans_lines(i)
                .line_amt_includes_tax_flag );
           END IF;

          END IF; -- l_return_status

          IF (l_inv_tax_list(i).rcv_transaction_id IS NULL) THEN
            -------------------------------------------------------------------
            l_debug_info := 'Step 12: Populate pl/sql table for TAX line if it '||
                            'is not receipt matched';
            IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
            END IF;
            -------------------------------------------------------------------
            IF (l_return_status = TRUE ) THEN
              tax_lines.EXTEND(1);
              link_lines.EXTEND(1);

              tax_lines(k).summary_tax_line_number		:= l_inv_tax_list(i).line_number;
              tax_lines(k).internal_organization_id		:= P_Invoice_Header_Rec.org_id;
              tax_lines(k).application_id			:= 200;
              tax_lines(k).entity_code				:= 'AP_INVOICES';
              tax_lines(k).event_class_code			:= p_event_class_code;
              tax_lines(k).trx_id				:= P_Invoice_Header_Rec.invoice_id;

              tax_lines(k).tax_regime_code			:= l_inv_tax_list(i).tax_regime_code;
              tax_lines(k).tax					:= l_inv_tax_list(i).tax;
              tax_lines(k).tax_status_code			:= l_inv_tax_list(i).tax_status_code;
              tax_lines(k).tax_rate_code			:= l_inv_tax_list(i).tax_rate_code;
              tax_lines(k).tax_rate				:= l_inv_tax_list(i).tax_rate;
              tax_lines(k).tax_amt				:= l_inv_tax_list(i).amount;
              tax_lines(k).tax_line_allocation_flag             := 'Y';
              -- Populating tax jurisdiction code for bug 6411838
              tax_lines(k).tax_jurisdiction_code                := l_inv_tax_list(i).tax_jurisdiction_code ;

              --Bug9819170
              l_copy_line_dff_flag := NVL(fnd_profile.value('AP_COPY_INV_LINE_DFF'),'N');
              IF l_copy_line_dff_flag = 'Y' THEN
               tax_lines(k).ATTRIBUTE1         :=  l_inv_tax_list(i).ATTRIBUTE1;
               tax_lines(k).ATTRIBUTE2         :=  l_inv_tax_list(i).ATTRIBUTE2;
               tax_lines(k).ATTRIBUTE3         :=  l_inv_tax_list(i).ATTRIBUTE3;
               tax_lines(k).ATTRIBUTE4         :=  l_inv_tax_list(i).ATTRIBUTE4;
               tax_lines(k).ATTRIBUTE5         :=  l_inv_tax_list(i).ATTRIBUTE5;
               tax_lines(k).ATTRIBUTE6         :=  l_inv_tax_list(i).ATTRIBUTE6;
               tax_lines(k).ATTRIBUTE7         :=  l_inv_tax_list(i).ATTRIBUTE7;
               tax_lines(k).ATTRIBUTE8         :=  l_inv_tax_list(i).ATTRIBUTE8;
               tax_lines(k).ATTRIBUTE9         :=  l_inv_tax_list(i).ATTRIBUTE9;
               tax_lines(k).ATTRIBUTE10        :=  l_inv_tax_list(i).ATTRIBUTE10;
               tax_lines(k).ATTRIBUTE11        :=  l_inv_tax_list(i).ATTRIBUTE11;
               tax_lines(k).ATTRIBUTE12        :=  l_inv_tax_list(i).ATTRIBUTE12;
               tax_lines(k).ATTRIBUTE13        :=  l_inv_tax_list(i).ATTRIBUTE13;
               tax_lines(k).ATTRIBUTE14        :=  l_inv_tax_list(i).ATTRIBUTE14;
               tax_lines(k).ATTRIBUTE15        :=  l_inv_tax_list(i).ATTRIBUTE15;         --BUG13719477
               tax_lines(k).ATTRIBUTE_CATEGORY := l_inv_tax_list(i).ATTRIBUTE_CATEGORY;
              END IF;
              --Bug9819170

-- Debug messages added for 6321366
            IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'zx_import_tax_lines_gt values ');
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'summary_tax_line_number: ' || tax_lines(k).summary_tax_line_number);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'application_id: '           || tax_lines(k).application_id);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'event_class_code: '      || tax_lines(k).event_class_code);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_id: '   || tax_lines(k).trx_id);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'tax: '   || tax_lines(k).tax );
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'tax_amt: '    || tax_lines(k).tax_amt );
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'tax_line_allocation_flag: '|| tax_lines(k).tax_line_allocation_flag);
            END IF;

              --------------------------------------------------------------
              l_debug_info := 'Step 13: Populate link structure';
              IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                  FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
              END IF;
              --------------------------------------------------------------
              link_lines(k).application_id			:= 200;
              link_lines(k).entity_code				:= 'AP_INVOICES';
              link_lines(k).event_class_code			:= p_event_class_code;
              link_lines(k).trx_id				:= P_Invoice_Header_Rec.invoice_id;
              link_lines(k).trx_level_type			:= 'LINE';
              link_lines(k).trx_line_id				:= l_inv_tax_list(i).line_number;
              link_lines(k).summary_tax_line_number		:= l_inv_tax_list(i).line_number;
              link_lines(k).line_amt				:= l_inv_tax_list(i).amount;

-- Debug messages added for 6321366
            IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'zx_trx_tax_link_gt values ');
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'summary_tax_line_number: ' || link_lines(k).summary_tax_line_number);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'application_id: '           || link_lines(k).application_id);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'event_class_code: '      || link_lines(k).event_class_code);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_id: '   || link_lines(k).trx_id);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_level_type: '   || link_lines(k).trx_level_type );
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_line_id: '   || link_lines(k).trx_line_id);
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_amt: '    || link_lines(k).line_amt );
            END IF;
              k := k + 1;

            END IF;  -- l_return_status validation for TAX lines
          END IF;

        END LOOP;  -- end of loop TAX lines
      END IF; -- is l_inv_tax_list populated
    END IF; -- Is invoice tax only?

    -------------------------------------------------------------------
    l_debug_info := 'Step 14: Bulk Insert into global temp tables';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF ( l_return_status = TRUE ) THEN

      IF (trans_lines.COUNT > 0) THEN
        FORALL m IN trans_lines.FIRST..trans_lines.LAST
          INSERT INTO zx_transaction_lines_gt
          VALUES trans_lines(m);
      END IF;

      IF (tax_lines.COUNT > 0) THEN

    -------------------------------------------------------------------
    l_debug_info := 'Step 15: Populate Tax Lines: '||tax_lines.count;
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------

        FORALL m IN tax_lines.FIRST..tax_lines.LAST
          INSERT INTO zx_import_tax_lines_gt
          VALUES tax_lines(m);

        --Bug9819170
        -------------------------------------------------------------------
        l_debug_info := 'DFFs Of The Tax Lines';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
       -------------------------------------------------------------------
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           IF l_copy_line_dff_flag = 'Y'  THEN
              FOR i IN (SELECT *
                          FROM zx_import_tax_lines_gt
                         WHERE trx_id = P_Invoice_Header_Rec.invoice_id
                           AND application_id = 200
                           AND entity_code ='AP_INVOICES'
                           AND event_class_code IN ('STANDARD INVOICES','PREPAYMENT INVOICES','EXPENSE REPORTS')) LOOP

                        l_debug_info := '1 '|| i.ATTRIBUTE1;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '2 '||i.ATTRIBUTE2;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '3 '||i.ATTRIBUTE3;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '4 '||i.ATTRIBUTE4;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '5 '||i.ATTRIBUTE5;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '6 '||i.ATTRIBUTE6;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '7 '||i.ATTRIBUTE7;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '8 '||i.ATTRIBUTE8;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '9 '||i.ATTRIBUTE8;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '10 '||i.ATTRIBUTE10;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '11 '||i.ATTRIBUTE11;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '12 '||i.ATTRIBUTE12;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '13 '||i.ATTRIBUTE13;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '14 '||i.ATTRIBUTE14;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := '15 '||i.ATTRIBUTE15;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        l_debug_info := 'Attrib Cat '||i.ATTRIBUTE_CATEGORY;
                        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
              END LOOP;
           END IF;
        END IF;
      --Bug9819170

      END IF;

      -- This bulk insert will only be effective when the invoice is tax_only
      -- and there are tax lines with the tax info to be imported
      IF (link_lines.COUNT > 0) THEN
        FORALL m IN link_lines.FIRST..link_lines.LAST
          INSERT INTO zx_trx_tax_link_gt
          VALUES link_lines(m);
      END IF;

    END IF;

    RETURN l_return_status;

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Header_Rec = '||P_Invoice_Header_Rec.Invoice_Id||
          ' P_Calling_Mode ='||P_Calling_Mode||
          ' P_Error_Code = '||P_Error_Code||
          ' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

     --bug10140354
     IF AP_APPROVAL_PKG.G_VALIDATION_REQUEST_ID IS NULL THEN
        APP_EXCEPTION.RAISE_EXCEPTION;
    ELSE
    l_err:= SQLERRM;
    insert into ap_errors_gt(invoice_id , message_text) values(P_Invoice_Header_Rec.Invoice_id , l_err);
    RETURN FALSE;
    END IF;

  END Populate_Tax_Lines_GT;


/*=============================================================================
 |  FUNCTION - Populate_Distributions_GT()
 |
 |  DESCRIPTION
 |      This function will get additional information required to populate the
 |      ZX_ITM_DISTRIBUTIONS_GT
 |      This function returns TRUE if the population of the temp table goes
 |      through successfully.  Otherwise, FALSE.
 |
 |  PARAMETERS
 |      P_Invoice_Header_Rec - record with invoice header information
 |      P_Calling_Mode - calling mode. it is used to
 |      P_Event_Class_Code - Event class code for document
 |      P_Event_Type_Code - Event Type code for invoice
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
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN
  IS
    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);

    TYPE Trans_Dist_Tab_Type IS TABLE OF zx_itm_distributions_gt%ROWTYPE;
    trans_dists                     Trans_Dist_Tab_Type := Trans_Dist_Tab_Type();

    -- Purchase Order Info
    l_ref_doc_application_id	    zx_itm_distributions_gt.ref_doc_application_id%TYPE;
    l_ref_doc_entity_code	    zx_itm_distributions_gt.ref_doc_entity_code%TYPE;
    l_ref_doc_event_class_code      zx_itm_distributions_gt.ref_doc_event_class_code%TYPE;
    l_ref_doc_trx_id                zx_itm_distributions_gt.ref_doc_trx_id%TYPE;
    l_ref_doc_trx_level_type	    zx_itm_distributions_gt.ref_doc_trx_level_type%TYPE;
    l_ref_doc_line_quantity	    zx_transaction_lines_gt.ref_doc_line_quantity%TYPE;
    l_ref_doc_trx_line_dist_qty     zx_itm_distributions_gt.ref_doc_trx_line_dist_qty%TYPE;
    l_po_unit_price		    po_line_locations_all.price_override%TYPE;
    l_po_line_location_id           po_line_locations_all.line_location_id%TYPE;
    l_po_release_id                 zx_itm_distributions_gt.ref_doc_trx_id%TYPE;
    l_product_org_id                zx_transaction_lines_gt.product_org_id%TYPE;
    l_uom_code                      mtl_units_of_measure.uom_code%TYPE;

    l_dist_level_action             zx_itm_distributions_gt.dist_level_action%TYPE;
    l_line_quantity_invoiced        zx_itm_distributions_gt.trx_line_quantity%TYPE;
    l_amount                        zx_itm_distributions_gt.trx_line_dist_amt%TYPE;
    l_price_diff		    zx_itm_distributions_gt.price_diff%TYPE;
    l_po_header_curr_conv_rate      zx_itm_distributions_gt.ref_doc_curr_conv_rate%TYPE;
    l_receipt_curr_conv_rate	    zx_itm_distributions_gt.applied_to_doc_curr_conv_rate%TYPE;
    l_converted_qty		    ap_invoice_distributions_all.quantity_invoiced%TYPE;
    l_converted_price		    ap_invoice_distributions_all.unit_price%TYPE;

    -- Correction Invoice Info
    l_adj_doc_application_id	    zx_transaction_lines_gt.adjusted_doc_application_id%TYPE;
    l_adj_doc_entity_code           zx_transaction_lines_gt.adjusted_doc_entity_code%TYPE;
    l_adj_doc_event_class_code      zx_transaction_lines_gt.adjusted_doc_event_class_code%TYPE;
    l_adj_doc_number                zx_transaction_lines_gt.adjusted_doc_number%TYPE;
    l_adj_doc_date                  zx_transaction_lines_gt.adjusted_doc_date%TYPE;
    l_adj_doc_trx_level_type        zx_transaction_lines_gt.adjusted_doc_trx_level_type%TYPE;
    l_adj_doc_trx_id		    zx_itm_distributions_gt.adjusted_doc_trx_id%TYPE;
    l_adj_doc_line_id		    zx_itm_distributions_gt.adjusted_doc_line_id%TYPE;

    -- Prepayment Info
    l_prepay_doc_application_id     zx_transaction_lines_gt.applied_from_application_id%TYPE;
    l_prepay_doc_entity_code        zx_transaction_lines_gt.applied_from_entity_code%TYPE;
    l_prepay_doc_event_class_code   zx_transaction_lines_gt.applied_from_event_class_code%TYPE;
    l_prepay_doc_number             ap_invoices_all.invoice_num%TYPE;
    l_prepay_doc_date               ap_invoices_all.invoice_date%TYPE;
    l_applied_from_trx_id	    ap_invoice_lines_all.invoice_id%TYPE;
    l_applied_from_line_id	    ap_invoice_lines_all.line_number%TYPE;
    l_applied_from_trx_level_type   zx_transaction_lines_gt.applied_from_trx_level_type%TYPE;

    l_prepay_inv_id	            ap_invoice_lines_all.invoice_id%TYPE;
    l_prepay_line_num               ap_invoice_lines_all.line_number%TYPE;

    l_return_status                 BOOLEAN := TRUE;
    l_api_name                      CONSTANT VARCHAR2(100) := 'Populate_Distributions_GT';
    l_intended_use                ap_invoice_lines_all.primary_intended_use%TYPE; --8796484
    j                               NUMBER:=0;                                    --Bug9494315

    --bug 10621602 Starts Added the below variables to be used

    l_retained_amount  NUMBER ;
    l_retainage_rate  NUMBER ;
    l_retainage_release_factor NUMBER  := 1;
    l_retainage_rrf_amount NUMBER;
    l_quantity_invoiced NUMBER := 0 ;
    l_unit_price NUMBER := 0 ;

    --bug10621602 ends

  BEGIN

    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.Populate_Distributions_GT<-'||
                               P_calling_sequence;

    IF (l_inv_dist_list.COUNT > 0) THEN

      --trans_dists.EXTEND(l_inv_dist_list.COUNT);                                --Bug9494315

      -------------------------------------------------------------------
      l_debug_info := 'Step 1: Loop through all the distributions';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -------------------------------------------------------------------

      FOR i IN l_inv_dist_list.FIRST..l_inv_dist_list.LAST LOOP

          IF (l_inv_dist_list(i).line_type_lookup_code NOT IN
             ('AWT', 'REC_TAX', 'NONREC_TAX', 'TRV', 'TERV', 'TIPV')) THEN  --Bug9494315

                trans_dists.EXTEND(1);   --Bug9494315
                j:=j+1;                  --Bug9494315





        -------------------------------------------------------------------
        l_debug_info := 'Step 2: Get line_level_action for distribution';
	    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -------------------------------------------------------------------
        /*  --Bug12660669 Added source and line type check */
	--bug14189635, changed l_inv_line_list to l_inv_dist_list
        IF (P_Invoice_Header_Rec.source = 'SelfService' AND
		        P_Invoice_Header_Rec.invoice_type_lookup_code = 'EXPENSE REPORT' AND
                l_inv_dist_list(i).line_type_lookup_code = 'MISCELLANEOUS' ) THEN
		--bug14155552, changed to dist level action to 'NO_ACTION' from 'NO_CHANGE'
                l_dist_level_action := 'NO_ACTION';

        ELSIF ( l_inv_dist_list(i).tax_already_distributed_flag ='Y' ) THEN

	   IF l_inv_dist_list(i).prepay_distribution_id is not null then /*Bug13622888*/
	      l_dist_level_action := 'NO_ACTION';  /*Bug13622888*/
	    ELSE
              l_dist_level_action := 'UPDATE';
            END IF;

        ELSE
           l_dist_level_action := 'CREATE';

        END IF;

        -----------------------------------------------------------------
        l_debug_info := 'Step 3: Update the amount including IPV/ERV';
	    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------
        IF (l_inv_dist_list(i).related_retainage_dist_id IS NOT NULL) THEN
           SELECT SUM(amount)
             INTO l_amount
             FROM ap_invoice_distributions_all
            WHERE invoice_id = l_inv_dist_list(i).invoice_id
	      AND (related_id = l_inv_dist_list(i).related_id
                   or related_retainage_dist_id = l_inv_dist_list(i).related_retainage_dist_id);

         /* 9526592 - added elsif condition for better performance of the query */
	ELSIF (l_inv_dist_list(i).related_id IS NOT NULL) THEN

           SELECT SUM(amount)
             INTO l_amount
             FROM ap_invoice_distributions_all
            WHERE invoice_id = l_inv_dist_list(i).invoice_id
	      AND related_id = l_inv_dist_list(i).related_id;

        ELSE
           l_amount := l_inv_dist_list(i).amount;

        END IF;

        -------------------------------------------------------------------
        l_debug_info := 'Step 4: Get correction invoice info';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -------------------------------------------------------------------
        BEGIN
          SELECT quantity_invoiced, po_release_id, primary_intended_use --8796484
            INTO l_line_quantity_invoiced, l_po_release_id, l_intended_use
            FROM ap_invoice_lines_all
           WHERE invoice_id = l_inv_dist_list(i).invoice_id
             AND line_number = l_inv_dist_list(i).invoice_line_number;
        END;

        -------------------------------------------------------------------
        l_debug_info := 'Step 5: Get purchase order info';
	    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -------------------------------------------------------------------

	--bug14189635, changed l_inv_line_list to l_inv_dist_list
        IF ( l_inv_dist_list(i).po_distribution_id IS NOT NULL AND
             l_inv_dist_list(i).line_type_lookup_code NOT IN ('MISCELLANEOUS','FREIGHT')) THEN   --Bug14039130

          IF NOT (AP_ETAX_UTILITY_PKG.Get_PO_Info(
               P_Po_Line_Location_Id      => l_po_line_location_id,
               P_Po_Distribution_Id       => l_inv_dist_list(i).po_distribution_id,
               P_Application_Id           => l_ref_doc_application_id,
               P_Entity_code              => l_ref_doc_entity_code,
               P_Event_Class_Code         => l_ref_doc_event_class_code,
               P_PO_Quantity              => l_ref_doc_line_quantity,
               P_Product_Org_Id           => l_product_org_id,
               P_Po_Header_Id             => l_ref_doc_trx_id,
               P_Po_Header_curr_conv_rate => l_po_header_curr_conv_rate,
               P_Uom_Code                 => l_uom_code,
               P_Dist_Qty                 => l_ref_doc_trx_line_dist_qty,
               P_Ship_Price               => l_po_unit_price,
               P_Error_Code               => P_error_code,
               P_Calling_Sequence         => l_curr_calling_sequence)) THEN

            l_return_status := FALSE;
          END IF;

	  l_ref_doc_trx_level_type := 'SHIPMENT';

        ELSE
          l_ref_doc_application_id     := Null;
          l_ref_doc_entity_code        := Null;
          l_ref_doc_event_class_code   := Null;
          l_ref_doc_line_quantity      := Null;
          l_product_org_id             := Null;
          l_ref_doc_trx_id             := Null;
          l_ref_doc_trx_level_type     := Null;
	  l_ref_doc_trx_line_dist_qty  := Null;
	  l_po_unit_price              := Null;
	  l_po_header_curr_conv_rate   := Null;
	  l_uom_code		       := Null;
        END IF;

        -------------------------------------------------------------------
        l_debug_info := 'Step 6: Set ref_doc_trx_id if distribution is '||
                        'receipt matched';
	    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -------------------------------------------------------------------
	--bug14189635, changed l_inv_line_list to l_inv_dist_list
        IF (l_return_status = TRUE AND
            l_inv_dist_list(i).rcv_transaction_id IS NOT NULL AND
            l_inv_dist_list(i).line_type_lookup_code NOT IN ('MISCELLANEOUS','FREIGHT')) THEN   --Bug14039130

          BEGIN
            SELECT currency_conversion_rate
              INTO l_receipt_curr_conv_rate
              FROM rcv_transactions
             WHERE transaction_id = l_inv_dist_list(i).rcv_transaction_id;
          END;

          get_converted_qty_price
                (x_invoice_distribution_id => l_inv_dist_list(i).invoice_distribution_id,
                 x_inv_qty                 => l_converted_qty,
                 x_inv_price               => l_converted_price);

        ELSE
	    l_receipt_curr_conv_rate := Null;
	    l_converted_qty          := Null;
	    l_converted_price	     := Null;
        END IF;

/*
        -------------------------------------------------------------------
        l_debug_info := 'Step 8: Get Additional Correction Invoice Info ';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -------------------------------------------------------------------
        IF ( l_return_status = TRUE AND
	     l_inv_dist_list(i).corrected_invoice_dist_id IS NOT NULL) THEN

	   Select invoice_id, invoice_line_number
	     Into l_adj_doc_trx_id, l_adj_doc_line_id
	     From ap_invoice_distributions_all
	    Where invoice_distribution_id = l_inv_dist_list(i).corrected_invoice_dist_id;

           IF NOT (AP_ETAX_UTILITY_PKG.Get_Corrected_Invoice_Info(
              P_Corrected_Invoice_Id        => l_inv_line_list(i).corrected_inv_id,
              P_Corrected_Line_Number       => l_inv_line_list(i).corrected_line_number,
              P_Application_Id              => l_adj_doc_application_id,
              P_Entity_code                 => l_adj_doc_entity_code,
              P_Event_Class_Code            => l_adj_doc_event_class_code,
              P_Invoice_Number              => l_adj_doc_number,
              P_Invoice_Date                => l_adj_doc_date,
              P_Error_Code                  => P_error_code,
              P_Calling_Sequence            => l_curr_calling_sequence)) THEN

              l_return_status := FALSE;
          END IF;

          l_adj_doc_trx_level_type := 'LINE';

        ELSE
            l_adj_doc_application_id   := Null;
            l_adj_doc_entity_code      := Null;
            l_adj_doc_event_class_code := Null;
            l_adj_doc_number           := Null;
            l_adj_doc_date             := Null;
            l_adj_doc_trx_level_type   := Null;
        END IF;

        -------------------------------------------------------------------
        l_debug_info := 'Step 8: Get prepayment invoice info';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -------------------------------------------------------------------
        IF ( l_return_status = TRUE AND
	     l_inv_dist_list(i).prepay_distribution_id IS NOT NULL) THEN

	  SELECT invoice_id, invoice_line_number
	    INTO l_applied_from_trx_id, l_applied_from_line_id
	    FROM ap_invoice_distributions_all
	   WHERE invoice_distribution_id = l_inv_dist_list(i).prepay_distribution_id;

          IF NOT (AP_ETAX_UTILITY_PKG.Get_Prepay_Invoice_Info(
              P_Prepay_Invoice_Id           => l_applied_from_trx_id,
              P_Prepay_Line_Number          => l_applied_from_line_id,
              P_Application_Id              => l_prepay_doc_application_id,
              P_Entity_code                 => l_prepay_doc_entity_code,
              P_Event_Class_Code            => l_prepay_doc_event_class_code,
              P_Invoice_Number              => l_prepay_doc_number,
              P_Invoice_Date                => l_prepay_doc_date,
              P_Error_Code                  => P_error_code,
              P_Calling_Sequence            => l_curr_calling_sequence)) THEN

              l_return_status := FALSE;
          END IF;

          l_applied_from_trx_level_type := 'LINE';

        ELSE
          l_prepay_doc_application_id   := Null;
          l_prepay_doc_entity_code      := Null;
          l_prepay_doc_event_class_code := Null;
          l_prepay_doc_number           := Null;
          l_prepay_doc_date             := Null;
          l_applied_from_trx_level_type := Null;
	  l_applied_from_trx_id		:= Null;
	  l_applied_from_line_id	:= Null;
        END IF;
*/
        -------------------------------------------------------------------
        l_debug_info := 'Step 7: Populate pl/sql table';
	    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -------------------------------------------------------------------
        IF (l_return_status = TRUE) THEN

          trans_dists(j).application_id			:= AP_ETAX_PKG.AP_APPLICATION_ID;
          trans_dists(j).entity_code			:= AP_ETAX_PKG.AP_ENTITY_CODE;
          trans_dists(j).event_class_code		:= P_event_class_code;
          trans_dists(j).trx_id				:= l_inv_dist_list(i).invoice_id;

          IF p_calling_mode = 'DISTRIBUTE RECOUP' THEN
             IF  l_inv_dist_list(i).prepay_distribution_id IS NOT NULL THEN

		 SELECT invoice_id, invoice_line_number
                   INTO l_prepay_inv_id, l_prepay_line_num
                   FROM ap_invoice_distributions_all
                  WHERE invoice_distribution_id = l_inv_dist_list(i).prepay_distribution_id;

                 trans_dists(j).trx_line_id := -1 * (l_prepay_inv_id || l_prepay_line_num || l_inv_dist_list(i).invoice_line_number);

	     END IF;
	  ELSE
	     trans_dists(j).trx_line_id := l_inv_dist_list(i).invoice_line_number;

          END IF;


	   --bug10621602 starts
	   --The below changes are done only for the distributions involving retainage and retainage release .
	   --we will populate the structure ret_dists by deriving the values

	    IF (l_inv_dist_list(i).related_retainage_dist_id IS NOT NULL
	        OR (l_inv_dist_list(i).retained_invoice_dist_id IS NOT NULL and l_inv_dist_list(i).po_distribution_id IS NOT NULL)) THEN

	      BEGIN
		    SELECT POL.retainage_rate INTO l_retainage_rate
              FROM po_lines_all POL , po_line_locations_all PLL
             WHERE PLL.po_header_id = POL.po_header_id
               AND PLL.po_line_id = POL.po_line_id
               AND PLL.line_location_id = l_po_line_location_id
               AND PLL.po_header_id =  l_ref_doc_trx_id;

		    IF ( l_inv_dist_list(i).RELATED_RETAINAGE_DIST_ID IS NOT NULL) THEN

		    -- For standard invoice having retainage we will populate the char4 column as 'S' and will get the retained amount

                trans_dists(j).char4 := 'S';

		        select amount into l_retained_amount from ap_invoice_distributions_all aid
		         where  aid.invoice_id = l_inv_dist_list(i).invoice_id
		           and aid.line_type_lookup_code = 'RETAINAGE'
		           and aid.related_retainage_dist_id is NOT NULL
		           and aid.related_retainage_dist_id = l_inv_dist_list(i).invoice_distribution_id;

		    END IF;

            IF (l_inv_dist_list(i).RETAINED_INVOICE_DIST_ID IS NOT NULL) THEN

		        -- For retainge release invoice we will populate the char4 value as 'R' and the retained amount is 0 .

			    trans_dists(j).char4 := 'R';
                l_retained_amount := 0;

		        SELECT amount INTO l_retainage_rrf_amount FROM ap_invoice_distributions_all
		         WHERE line_type_lookup_code = 'RETAINAGE'
			       AND invoice_distribution_id = l_inv_dist_list(i).RETAINED_INVOICE_DIST_ID;

		        SELECT aid1.quantity_invoiced  , aid1.unit_price INTO l_quantity_invoiced  , l_unit_price
                  FROM ap_invoice_distributions_all aid1 , ap_invoice_distributions_all aid2
		         WHERE aid1.line_type_lookup_code IN ('ACCRUAL' ,'ITEM')
		           AND aid1.invoice_distribution_id = aid2.related_retainage_dist_id
			       AND aid2.invoice_distribution_id = l_inv_dist_list(i).RETAINED_INVOICE_DIST_ID
			       AND aid2.line_type_lookup_code = 'RETAINAGE';

			    -- Get the RRF Factor for multiple retainage release invoices . The value will be 1 in case of single release.

			    l_retainage_release_factor := abs(l_amount/l_retainage_rrf_amount);
			    l_inv_dist_list(i).unit_price := l_unit_price;
                l_inv_dist_list(i).quantity_invoiced := l_quantity_invoiced;

                l_debug_info := 'Retainage Release Factor is   ' || l_retainage_release_factor ||
			                    '  Derived Quanity Invoice ' || l_quantity_invoiced ||
				                '  Derived Unit Price ' || l_unit_price  ;
                IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                    FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                END IF;
            END IF;

		  EXCEPTION
	        WHEN OTHERS  THEN
                 NULL;
 	      END;

	        --Populate the char5 column with the value retainage_rate that will be used by EBTAX

	      trans_dists(j).char5 := l_retainage_rate * l_retainage_release_factor ;


	      ap_etax_services_pkg.ret_dists(l_inv_dist_list(i).invoice_distribution_id).retainage_rate  :=
                               l_retainage_rate *  l_retainage_release_factor;
	      ap_etax_services_pkg.ret_dists(l_inv_dist_list(i).invoice_distribution_id).amount := l_amount;
	      ap_etax_services_pkg.ret_dists(l_inv_dist_list(i).invoice_distribution_id).retained_amount := l_retained_amount;
	      ap_etax_services_pkg.ret_dists(l_inv_dist_list(i).invoice_distribution_id).related_retainage_dist_id :=
                               l_inv_dist_list(i).related_retainage_dist_id;
          ap_etax_services_pkg.ret_dists(l_inv_dist_list(i).invoice_distribution_id).retained_invoice_dist_id :=
                               l_inv_dist_list(i).retained_invoice_dist_id;
	      ap_etax_services_pkg.ret_dists(l_inv_dist_list(i).invoice_distribution_id).quantity_invoiced  := l_quantity_invoiced;
	      ap_etax_services_pkg.ret_dists(l_inv_dist_list(i).invoice_distribution_id).unit_price  := l_unit_price;


	     l_debug_info := 'Populating the char4 and char5 value for retainage invoice as  '
                         || trans_dists(j).char4 || '  and ' || trans_dists(j).char5;
         IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
         END IF;

	    END IF;
        --bug10621602 ends

          -- Bug 8624271 Restructing fix 7476261
          trans_dists(j).trx_level_type			:= 'LINE';
          trans_dists(j).trx_line_dist_id		:= l_inv_dist_list(i).invoice_distribution_id;
          trans_dists(j).dist_level_action		:= l_dist_level_action;
          trans_dists(j).item_dist_number		:= l_inv_dist_list(i).distribution_line_number;
          trans_dists(j).dist_intended_use		:= nvl(l_inv_dist_list(i).intended_use,
		                                               l_intended_use); --8796484

          trans_dists(j).trx_line_dist_amt 		:= l_amount;
          trans_dists(j).trx_line_quantity 		:= l_line_quantity_invoiced;
          trans_dists(j).trx_line_dist_qty 		:= coalesce(
                                                            l_converted_qty,
                                                            l_inv_dist_list(i).quantity_invoiced,
  							    l_inv_dist_list(i).corrected_quantity,
  							    1); --8624271

	      trans_dists(j).unit_price			:= nvl(l_inv_dist_list(i).unit_price,l_amount);
          trans_dists(j).trx_line_dist_date		:= l_inv_dist_list(i).accounting_date;

          trans_dists(j).task_id			:= l_inv_dist_list(i).task_id;
          trans_dists(j).award_id			:= l_inv_dist_list(i).award_id;
          trans_dists(j).project_id			:= l_inv_dist_list(i).project_id;
          trans_dists(j).expenditure_type		:= l_inv_dist_list(i).expenditure_type;
          trans_dists(j).expenditure_organization_id	:= l_inv_dist_list(i).expenditure_organization_id;
          trans_dists(j).expenditure_item_date		:= l_inv_dist_list(i).expenditure_item_date;
          trans_dists(j).account_ccid 			:= l_inv_dist_list(i).dist_code_combination_id;

          trans_dists(j).ref_doc_application_id 	:= l_ref_doc_application_id;
          trans_dists(j).ref_doc_entity_code 		:= l_ref_doc_entity_code;
          trans_dists(j).ref_doc_event_class_code 	:= l_ref_doc_event_class_code;
          trans_dists(j).ref_doc_trx_id 		:= l_ref_doc_trx_id;
          trans_dists(j).ref_doc_line_id		:= l_po_line_location_id;

          --Bug14039130
	  --bug14189635, changed l_inv_line_list to l_inv_dist_list
          IF l_inv_dist_list(i).line_type_lookup_code NOT IN ('MISCELLANEOUS','FREIGHT') THEN
            trans_dists(j).ref_doc_dist_id 		:= l_inv_dist_list(i).po_distribution_id;
          ELSE
            trans_dists(j).ref_doc_dist_id 		:= NULL;
	      END IF;
          --Bug14039130


          trans_dists(j).ref_doc_trx_level_type 	:= l_ref_doc_trx_level_type;
	      trans_dists(j).ref_doc_trx_line_dist_qty 	:= l_ref_doc_trx_line_dist_qty;

          trans_dists(j).adjusted_doc_dist_id           := l_inv_dist_list(i).corrected_invoice_dist_id;
          trans_dists(j).applied_from_dist_id           := l_inv_dist_list(i).prepay_distribution_id;

          /*
          trans_dists(j).adjusted_doc_application_id 	:= l_adj_doc_application_id;
          trans_dists(j).adjusted_doc_entity_code 	:= l_adj_doc_entity_code;
          trans_dists(j).adjusted_doc_event_class_code 	:= l_adj_doc_event_class_code;
          trans_dists(j).adjusted_doc_trx_id 		:= l_adj_doc_trx_id;
          trans_dists(j).adjusted_doc_line_id 		:= l_adj_doc_line_id;
          trans_dists(j).adjusted_doc_dist_id		:= l_inv_dist_list(i).corrected_invoice_dist_id;
          trans_dists(j).adjusted_doc_trx_level_type 	:= l_adj_doc_trx_level_type;

          trans_dists(j).applied_from_application_id 	:= l_prepay_doc_application_id;
          trans_dists(j).applied_from_entity_code 	:= l_prepay_doc_entity_code;
          trans_dists(j).applied_from_event_class_code 	:= l_prepay_doc_event_class_code;
          trans_dists(j).applied_from_trx_id 		:= l_applied_from_trx_id;
          trans_dists(j).applied_from_line_id 		:= l_applied_from_line_id;
       	  trans_dists(j).applied_from_dist_id		:= l_inv_dist_list(i).prepay_distribution_id;
          trans_dists(j).applied_from_trx_level_type 	:= l_applied_from_trx_level_type;
          */

          trans_dists(j).ref_doc_curr_conv_rate 	:= l_po_header_curr_conv_rate;
          trans_dists(j).applied_to_doc_curr_conv_rate 	:= l_receipt_curr_conv_rate;


           --Bug9363214
 	   --l_price_diff				:= l_inv_dist_list(i).unit_price - l_po_unit_price;
           --Bug9643462 started using corrected_invoice_dist_id
           if ((l_inv_dist_list(i).corrected_invoice_dist_id is not null) and (l_inv_dist_list(i).dist_match_type = 'PRICE_CORRECTION'))then
                  l_price_diff				:= l_inv_dist_list(i).unit_price;
           else
                  l_price_diff				:= l_inv_dist_list(i).unit_price - l_po_unit_price;
           end if;
           --Bug9363214
	 --Bug 7476261 End

          trans_dists(j).price_diff 			:= l_price_diff;
          trans_dists(j).historical_flag		:= NVL(l_inv_dist_list(i).historical_flag, 'N'); -- Bug 7117591
/*NVL(P_Invoice_Header_Rec.historical_flag, 'N');*/

          IF (G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
				'trans_dists(j).trx_id: '||trans_dists(j).trx_id);
              FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
                                'trans_dists(j).trx_line_id: '||trans_dists(j).trx_line_id);
              FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
				'trans_dists(j).trx_line_dist_amt: '||trans_dists(j).trx_line_dist_amt);
              FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
				'l_ref_doc_application_id: '||l_ref_doc_application_id);
              FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
				'l_ref_doc_entity_code: '   ||l_ref_doc_entity_code);
              FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
				'l_ref_doc_event_class_code: ' ||l_ref_doc_event_class_code);
              FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
				'l_ref_doc_trx_id: '||l_ref_doc_trx_id);
              FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
				'l_po_line_location_id: '||l_po_line_location_id);
              FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
				'l_inv_dist_list(i).po_distribution_id: '||l_inv_dist_list(i).po_distribution_id);
              FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
				'l_adj_doc_application_id: '|| l_adj_doc_application_id);
              FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
				'l_adj_doc_entity_code: '|| l_adj_doc_entity_code);
              FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
				'l_adj_doc_event_class_code: '|| l_adj_doc_event_class_code);
              FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
				'l_adj_doc_trx_id: '|| l_adj_doc_trx_id);
              FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
				'l_adj_doc_line_id: '|| l_adj_doc_line_id);
              FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
				'l_adj_doc_trx_level_type: '|| l_adj_doc_trx_level_type);
	      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
				'l_prepay_doc_application_id: '||l_prepay_doc_application_id);
	      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
				'l_prepay_doc_entity_code: '||l_prepay_doc_entity_code);
	      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
				'l_prepay_doc_event_class_code: '||l_prepay_doc_event_class_code);
	      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
				'l_applied_from_trx_id: '||l_applied_from_trx_id);
	      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
				'l_applied_from_line_id: '||l_applied_from_line_id);
	      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
				'l_inv_dist_list(i).prepay_distribution_id: '||l_inv_dist_list(i).prepay_distribution_id);
	      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
				'l_applied_from_trx_level_type: '||l_applied_from_trx_level_type);
          --Bug12834600
          FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
        		'trx_line_dist_qty : '||trans_dists(j).trx_line_dist_qty);
          FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,
				'Converted Qty : '||l_converted_qty);
          --Bug12834600

          END IF;

          -- Reset the derived values
          l_po_line_location_id := Null;
	  l_prepay_inv_id	:= Null;
	  l_prepay_line_num	:= Null;
        END IF;
      END IF; --Bug9494315
      END LOOP;

      -------------------------------------------------------------------
      l_debug_info := 'Step 7: Bulk Insert into global temp table';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -------------------------------------------------------------------
      IF (l_return_status = TRUE) THEN

        FORALL m IN trans_dists.FIRST..trans_dists.LAST
          INSERT INTO zx_itm_distributions_gt
          VALUES trans_dists(m);

      END IF;
    END IF;

    RETURN l_return_status;

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Header_Rec = '||P_Invoice_Header_Rec.Invoice_Id||
          ' P_Calling_Mode ='||P_Calling_Mode||
          ' P_Error_Code = '||P_Error_Code||
          ' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;
  END Populate_Distributions_GT;

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
             P_Invoice_header_rec    IN ap_invoices_all%ROWTYPE,
             P_Calling_Mode          IN VARCHAR2,
             P_All_Error_Messages    IN VARCHAR2,
             P_Error_Code            OUT NOCOPY VARCHAR2,
             P_Calling_Sequence      IN VARCHAR2) RETURN BOOLEAN
  IS

    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);
    l_return_status              BOOLEAN := TRUE;
    l_api_name                   CONSTANT VARCHAR2(30) := 'Update_AP';

    l_err varchar2(2000); --bug10140354
  BEGIN

    l_curr_calling_sequence :=
      'AP_ETAX_SERVICES_PKG.Update_AP<-'||P_calling_sequence;

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_curr_calling_sequence);
    END IF;

    ------------------------------------------------------------------
    l_debug_info := 'Step 1: Calling_Mode is:'||P_Calling_Mode;
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    ------------------------------------------------------------------

    IF (P_Calling_Mode IN ('CALCULATE', 'CALCULATE IMPORT',
                           'OVERRIDE TAX', 'IMPORT INTERFACE',
                           'APPLY PREPAY', 'UNAPPLY PREPAY')) THEN
      -------------------------------------------------------------------
      l_debug_info := 'Step 2: Calling Return_Tax_Lines ';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -------------------------------------------------------------------
      IF NOT (AP_ETAX_UTILITY_PKG.Return_Tax_Lines(
                P_Invoice_Header_Rec => P_invoice_header_rec,
                P_Error_Code         => P_Error_Code,
                P_Calling_Sequence   => l_curr_calling_sequence)) THEN

        l_return_status :=  FALSE;
      END IF;


    ELSIF (P_Calling_Mode IN ('DISTRIBUTE', 'DISTRIBUTE RECOUP', 'OVERRIDE RECOVERY','DISTRIBUTE IMPORT')) THEN
        /*  for bug  6010950 added 'DISTRIBUTE IMPORT' to create the tax distributions while import itself for
              tax only invoices. */
      -------------------------------------------------------------------
      l_debug_info := 'Step 3: Calling Return_Tax_Distributions ';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -------------------------------------------------------------------
      IF NOT (AP_ETAX_UTILITY_PKG.Return_Tax_Distributions(
                P_Invoice_Header_Rec => P_invoice_header_rec,
                P_All_Error_Messages => P_All_Error_Messages,
                P_Error_Code         => P_Error_Code,
                P_Calling_Sequence   => l_curr_calling_sequence)) THEN

        l_return_status := FALSE;
      END IF;

    ELSIF (P_Calling_Mode = 'CALCULATE QUOTE') THEN
      -------------------------------------------------------------------
      l_debug_info := 'Step 4: Calling Return_Tax_Quote ';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -------------------------------------------------------------------
      IF NOT (AP_ETAX_UTILITY_PKG.Return_Tax_Quote(
                P_Invoice_Header_Rec => P_invoice_header_rec,
                P_Error_Code         => P_Error_Code,
                P_Calling_Sequence   => l_curr_calling_sequence)) THEN


        l_return_status := FALSE;
      END IF;
    --Bug8604959: Added p_calling_mode 'DELETE TAX LINE'
    ELSIF (P_Calling_Mode in ('REVERSE INVOICE','DELETE TAX LINE')) THEN
      -------------------------------------------------------------------
      l_debug_info := 'Step 5: Calling Return_Tax_Lines for '||
                      'REVERSE INVOICE';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -------------------------------------------------------------------
      IF NOT (AP_ETAX_UTILITY_PKG.Return_Tax_Lines(
                P_Invoice_Header_Rec => P_invoice_header_rec,
                P_Error_Code         => P_Error_Code,
                P_Calling_Sequence   => l_curr_calling_sequence)) THEN

        l_return_status := FALSE;
      END IF;

      -------------------------------------------------------------------
      l_debug_info := 'Step 6: Calling Return_Tax_Distributions for '||
                      'REVERSE INVOICE';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -------------------------------------------------------------------
      IF NOT (AP_ETAX_UTILITY_PKG.Return_Tax_Distributions(
                P_Invoice_Header_Rec => P_invoice_header_rec,
                P_All_Error_Messages => P_All_Error_Messages,
                P_Error_Code         => P_Error_Code,
                P_Calling_Sequence   => l_curr_calling_sequence)) THEN

        l_return_status := FALSE;
      END IF;

    END IF;

    RETURN l_return_status;

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Id = '||P_Invoice_header_rec.Invoice_Id||
          ' P_Calling_Mode ='||P_Calling_Mode||
          ' P_Error_Code = '||P_Error_Code||
          ' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

     --bug10140354
     IF AP_APPROVAL_PKG.G_VALIDATION_REQUEST_ID IS NULL THEN
                  APP_EXCEPTION.RAISE_EXCEPTION;
               ELSE
	       l_err:= SQLERRM;
                insert into ap_errors_gt(invoice_id , message_text) values(P_Invoice_Header_Rec.Invoice_id , l_err);
                  RETURN FALSE;
               END IF;

  END Update_AP;

/*=============================================================================
 |  FUNCTION - Calculate_Quote ()
 |
 |  DESCRIPTION
 |      This function will return the tax amount and indicate if it is inclusive.
 |      This will be called from the recurring invoices form. This is a special
 |      case, as the invoices for which the tax is to be calculated are not yet
 |      saved to the database and eBTax global temporary tables are populated
 |      based on the parameter p_invoice_header_rec. A psuedo-line is inserted
 |      into the GTT and removed after the tax amount is calculated.
 |
 |  PARAMETERS
 |      P_Invoice_Header_Rec 	- Invoice header info
 |      P_Invoice_Lines_Rec	- Invoice lines info
 |      P_Calling_Mode 		- Calling mode. (CALCULATE_QUOTE)
 |      P_All_Error_Messages 	- Should API return 1 error message or allow
 |                                calling point to get them from message stack
 |      P_error_code 		- Error code to be returned
 |      P_calling_sequence 	- Calling sequence
 |
 |  MODIFICATION HISTORY
 |    DATE          Author         Action
 |    13-AUG-2004   Sanjay         Created
 *============================================================================*/

  FUNCTION CALCULATE_QUOTE(
             P_Invoice_Header_Rec      	IN  ap_invoices_all%ROWTYPE,
             P_Invoice_Lines_Rec	    IN  ap_invoice_lines_all%ROWTYPE,
             P_Calling_Mode            	IN  VARCHAR2,
	         P_Tax_Amount		        OUT NOCOPY NUMBER,
	         P_Tax_Amt_Included		    OUT NOCOPY VARCHAR2,
             P_Error_Code              	OUT NOCOPY VARCHAR2,
             P_Calling_Sequence         IN  VARCHAR2) RETURN BOOLEAN
  IS

    l_debug_info                 	VARCHAR2(240);
    l_curr_calling_sequence      	VARCHAR2(4000);

    l_tax_already_calculated     	VARCHAR2(1);

    l_event_class_code           	zx_trx_headers_gt.event_class_code%TYPE;
    l_event_type_code            	zx_trx_headers_gt.event_type_code%TYPE;

    l_location_id			zx_transaction_lines_gt.ship_from_location_id%type;
    l_bill_to_location_id          	zx_transaction_lines_gt.bill_to_location_id%TYPE;
    l_fob_point                  	po_vendor_sites_all.fob_lookup_code%TYPE;
    l_po_line_location_id		ap_invoice_lines_all.po_line_location_id%TYPE;

    l_ctrl_hdr_tx_appl_flag         	zx_transaction_lines_gt.ctrl_hdr_tx_appl_flag%TYPE;
    l_line_level_action            	zx_transaction_lines_gt.line_level_action%TYPE;
    l_line_amt_includes_tax_flag	zx_transaction_lines_gt.line_amt_includes_tax_flag%TYPE;
    l_product_org_id               	zx_transaction_lines_gt.product_org_id%TYPE;
    l_uom_code                          mtl_units_of_measure.uom_code%TYPE;

    -- Variables for PO doc info
    l_ref_doc_application_id		zx_transaction_lines_gt.ref_doc_application_id%TYPE;
    l_ref_doc_entity_code		zx_transaction_lines_gt.ref_doc_entity_code%TYPE;
    l_ref_doc_event_class_code		zx_transaction_lines_gt.ref_doc_event_class_code%TYPE;
    l_ref_doc_line_quantity		zx_transaction_lines_gt.ref_doc_line_quantity%TYPE;
    l_ref_doc_trx_level_type		zx_transaction_lines_gt.ref_doc_trx_level_type%TYPE;
    l_po_header_curr_conv_rate		po_headers_all.rate%TYPE;
    l_dummy				number;

    l_ref_doc_trx_id			zx_transaction_lines_gt.ref_doc_trx_id%TYPE;

    l_return_status              	BOOLEAN := TRUE;
    l_return_status_service       	VARCHAR2(4000);
    l_msg_count                   	NUMBER;
    l_msg_data                    	VARCHAR2(4000);
    l_api_name              	        CONSTANT VARCHAR2(200) := 'Calculate_Quote';

    CURSOR c_tax_amount IS
    SELECT SUM(NVL(zdl.tax_amt,0))
    FROM   zx_detail_tax_lines_gt zdl
    WHERE  zdl.application_id = 200
    AND    zdl.entity_code    = 'AP_INVOICES'
    AND    zdl.trx_id         = P_Invoice_Lines_Rec.invoice_id
    AND    NVL(zdl.self_assessed_flag,  'N') = 'N'
    AND    NVL(zdl.reporting_only_flag, 'N') = 'N';

  BEGIN

    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.CALCULATE_QUOTE<-' || P_calling_sequence;

    IF (G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name,'AP_ETAX_SERVICES_PKG.Calculate_Quote (+)');
    END IF;

    ----------------------------------------------------------------------
    l_debug_info := 'Get location_id for vendor site';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    ----------------------------------------------------------------------
    BEGIN
      SELECT location_id, fob_lookup_code
        INTO l_location_id, l_fob_point
        FROM ap_supplier_sites_all
       WHERE vendor_site_id = P_Invoice_Header_Rec.vendor_site_id;

    EXCEPTION
      WHEN no_data_found THEN
         l_location_id := null;
         l_fob_point   := null;
    END;
    ----------------------------------------------------------------------
    l_debug_info := 'Location_id for vendor site' || l_location_id ||'& '||l_fob_point;
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    ----------------------------------------------------------------------
    -------------------------------------------------------------------
    l_debug_info := 'Is tax already called invoice level?';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF (AP_ETAX_UTILITY_PKG.Is_Tax_Already_Calc_Inv(
          P_Invoice_Id           => p_invoice_header_rec.invoice_id,
          P_Calling_Sequence     => l_curr_calling_sequence)) THEN

      l_tax_already_calculated := 'Y';
    ELSE
      l_tax_already_calculated := 'N';

    END IF;

    -------------------------------------------------------------------------
    l_debug_info := 'Step 1: Call AP_ETAX_SERVICES_PKG.Populate_Headers_GT';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------------
    IF NOT(AP_ETAX_SERVICES_PKG.Populate_Headers_GT(
		      P_Invoice_Header_Rec         => P_Invoice_Header_Rec,
		      P_Calling_Mode               => P_Calling_Mode,
		      P_eTax_Already_called_flag   => l_tax_already_calculated,
		      P_Event_Class_Code           => l_event_class_code,
		      P_Event_Type_Code            => l_event_type_code,
		      P_Error_Code                 => P_error_code,
		      P_Calling_Sequence           => l_curr_calling_sequence )) THEN

      l_return_status := FALSE;

    END IF;

    ------------------------------------------------------------------------
    l_debug_info := 'Step 2: Get location_id for org_id';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    ------------------------------------------------------------------------
    BEGIN
      SELECT location_id
        INTO l_bill_to_location_id
        FROM hr_all_organization_units
       WHERE organization_id = P_Invoice_Header_Rec.org_id;

    EXCEPTION
      WHEN no_data_found THEN
         l_bill_to_location_id := null;
    END;
    ------------------------------------------------------------------------
    l_debug_info := 'Location_id for org_id '||P_Invoice_Header_Rec.org_id||'& '||l_bill_to_location_id;
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    ------------------------------------------------------------------------
    ------------------------------------------------------------------------
    l_debug_info := 'Step 4: Go through taxable lines';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    ------------------------------------------------------------------------
    IF ( P_Invoice_Lines_Rec.invoice_id IS NOT NULL ) THEN

        --------------------------------------------------------------------
         l_debug_info := 'Step 5: Get line_level_action for line number: '||
			  P_Invoice_Lines_Rec.line_number;
         IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
         END IF;
        --------------------------------------------------------------------
        IF (l_return_status = TRUE) THEN

         l_line_level_action := 'CREATE';

         -------------------------------------------------------------------
          l_debug_info := 'Step 6: Get Additional PO matched  info ';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
         -------------------------------------------------------------------

         IF ( P_Invoice_Lines_Rec.po_line_location_id IS NOT NULL) THEN

	   l_po_line_location_id := P_Invoice_Lines_Rec.po_line_location_id;

           IF NOT (AP_ETAX_UTILITY_PKG.Get_PO_Info(
              P_Po_Line_Location_Id         => l_po_line_location_id,
              P_PO_Distribution_Id          => null,
              P_Application_Id              => l_ref_doc_application_id,
              P_Entity_code                 => l_ref_doc_entity_code,
              P_Event_Class_Code            => l_ref_doc_event_class_code,
              P_PO_Quantity                 => l_ref_doc_line_quantity,
              P_Product_Org_Id              => l_product_org_id,
              P_Po_Header_Id                => l_ref_doc_trx_id,
              P_Po_Header_curr_conv_rate    => l_po_header_curr_conv_rate,
              P_Uom_Code                    => l_uom_code,
              P_Dist_Qty                    => l_dummy,
              P_Ship_Price                  => l_dummy,
              P_Error_Code                  => P_error_code,
              P_Calling_Sequence            => l_curr_calling_sequence)) THEN

             l_return_status := FALSE;
           END IF;

	   l_ref_doc_trx_level_type := 'SHIPMENT';

         END IF;

         -------------------------------------------------------------------
          l_debug_info := 'Step 7: Get line_amt_includes_tax_flag';
	      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
         -------------------------------------------------------------------

         IF (P_Invoice_Lines_Rec.po_line_location_id IS NOT NULL) THEN
           -- NONE
           l_line_amt_includes_tax_flag := 'N';

         ELSE
           IF (p_calling_mode = 'CALCULATE QUOTE') THEN

	     -- Refer eTax bug 3819487 for the value of line_amt_includes_tax_flag
	     -- that AP should be passing.

             l_line_amt_includes_tax_flag := 'I';

           ELSE
             -- STANDARD
             l_line_amt_includes_tax_flag := 'S';

           END IF;
         END IF;
          -------------------------------------------------------------------
          l_debug_info := 'Line_Amt_Includes_Tax_Flag '||l_line_amt_includes_tax_flag;
	      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
         -------------------------------------------------------------------
         -------------------------------------------------------------------
          l_debug_info := 'Step 8: Get ctrl_hdr_tx_appl_flag';
	      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
         -------------------------------------------------------------------
         IF P_Invoice_Header_Rec.control_amount IS NOT NULL THEN
           l_ctrl_hdr_tx_appl_flag := 'Y';
         ELSE
           l_ctrl_hdr_tx_appl_flag := 'N';
         END IF;

       END IF;
    END IF;

    ------------------------------------------------------------------------
    l_debug_info := 'Step 9: Insert into zx_transaction_lines_gt';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    ------------------------------------------------------------------------
    IF ( l_return_status = TRUE ) THEN

	INSERT INTO zx_transaction_lines_gt
	(
	 application_id,
	 entity_code,
	 event_class_code,
	 trx_id,
	 trx_level_type,
	 trx_line_id,
	 line_level_action,
	 trx_line_type,
	 trx_line_date,
	 trx_business_category,
	 line_intended_use,
	 user_defined_fisc_class,
	 line_amt,
	 trx_line_quantity,
	 unit_price,
	 product_id,
	 product_fisc_classification,
	 product_org_id,
	 uom_code,
	 product_type,
	 product_category,
	 fob_point,
	 ship_to_party_id,
	 ship_from_party_id,
	 bill_to_party_id,
	 bill_from_party_id,
	 ship_from_party_site_id,
	 bill_from_party_site_id,
	 ship_to_location_id,
     ship_from_location_id,
	 bill_to_location_id,
	 bill_from_location_id,
	 account_ccid,
	 merchant_party_country,
	 ref_doc_application_id,
	 ref_doc_entity_code,
	 ref_doc_event_class_code,
	 ref_doc_trx_id,
	 ref_doc_line_id,
	 ref_doc_line_quantity,
     ref_doc_trx_level_type,
	 --applied_to_trx_line_id,
	 trx_line_number,
	 trx_line_description,
	 product_description,
	 trx_line_gl_date,
	 merchant_party_name,
	 merchant_party_document_number,
	 merchant_party_reference,
	 merchant_party_taxpayer_id,
	 merchant_party_tax_reg_number,
	 assessable_value,
	 line_amt_includes_tax_flag,
	 historical_flag,
	 ctrl_hdr_tx_appl_flag,
	 ctrl_total_line_tx_amt,
	 input_tax_classification_code
	)
	VALUES
	(
	 200,
	 'AP_INVOICES',
	 l_event_class_code,
	 P_Invoice_Lines_Rec.invoice_id,
	 'LINE',
	 P_Invoice_Lines_Rec.line_number,
	 l_line_level_action,
	 P_Invoice_Lines_Rec.line_type_lookup_code,
	 P_Invoice_Header_Rec.invoice_date,
	 P_Invoice_Lines_Rec.trx_business_category,
	 P_Invoice_Lines_Rec.primary_intended_use,
	 P_Invoice_Lines_Rec.user_defined_fisc_class,
	 P_Invoice_Lines_Rec.amount,
	 P_Invoice_Lines_Rec.quantity_invoiced,
	 P_Invoice_Lines_Rec.unit_price,
	 P_Invoice_Lines_Rec.inventory_item_id,
	 P_Invoice_Lines_Rec.product_fisc_classification,
	 l_product_org_id,
	 P_Invoice_Lines_Rec.unit_meas_lookup_code,
	 P_Invoice_Lines_Rec.product_type,
	 P_Invoice_Lines_Rec.product_category,
	 l_fob_point,
	 P_Invoice_Lines_Rec.org_id,
	 P_Invoice_Header_Rec.party_id,
	 P_Invoice_Lines_Rec.org_id,
	 P_Invoice_Header_Rec.party_id,
	 P_Invoice_Header_Rec.party_site_id,
	 P_Invoice_Header_Rec.party_site_id,
	 P_Invoice_Lines_Rec.ship_to_location_id,
     l_location_id,
	 l_bill_to_location_id,
     l_location_id,
	 P_Invoice_Lines_Rec.default_dist_ccid,
	 P_Invoice_Lines_Rec.country_of_supply,
	 l_ref_doc_application_id,
	 l_ref_doc_entity_code,
	 l_ref_doc_event_class_code,
	 l_ref_doc_trx_id,
         --Bug5680407 corrected the wrong ordering of below
         --3 coulmns
	 P_Invoice_Lines_Rec.po_line_location_id,
	 l_ref_doc_line_quantity,
     l_ref_doc_trx_level_type,
	 P_Invoice_Lines_Rec.line_number,
	 P_Invoice_Lines_Rec.description,
	 P_Invoice_Lines_Rec.item_description,
	 P_Invoice_Lines_Rec.accounting_date,
	 P_Invoice_Lines_Rec.merchant_name,
	 P_Invoice_Lines_Rec.merchant_document_number,
	 P_Invoice_Lines_Rec.merchant_reference,
	 P_Invoice_Lines_Rec.merchant_taxpayer_id,
	 P_Invoice_Lines_Rec.merchant_tax_reg_number,
	 P_Invoice_Lines_Rec.assessable_value,
	 l_line_amt_includes_tax_flag,
	 NVL(P_Invoice_Header_Rec.historical_flag, 'N'),
	 l_ctrl_hdr_tx_appl_flag,
	 P_Invoice_Lines_Rec.control_amount,
	 P_Invoice_Lines_Rec.tax_classification_code
	);

    END IF;

    IF ( l_return_status = TRUE ) THEN

       -----------------------------------------------------------------
       l_debug_info := 'Step 10: Call Calculate_Tax service';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
       -----------------------------------------------------------------

       zx_api_pub.calculate_tax(
                 p_api_version      => 1.0,
                 p_init_msg_list    => FND_API.G_TRUE,
                 p_commit           => FND_API.G_FALSE,
                 p_validation_level => FND_API.G_VALID_LEVEL_FULL,
                 x_return_status    => l_return_status_service,
                 x_msg_count        => l_msg_count,
                 x_msg_data         => l_msg_data);

    END IF;

    IF (l_return_status_service = 'S') THEN

       OPEN  c_tax_amount;
       FETCH c_tax_amount
       INTO  p_tax_amount;
       CLOSE c_tax_amount;

       IF p_tax_amount IS NOT NULL THEN

           -----------------------------------------------------------------
           l_debug_info := 'Step 11: Get tax inclusive/exclusive flag';
           IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
           END IF;
           -----------------------------------------------------------------

	   SELECT distinct zdl.tax_amt_included_flag
           INTO   P_Tax_Amt_Included
           FROM   zx_detail_tax_lines_gt zdl
           WHERE  zdl.application_id	= 200
           AND    zdl.entity_code	= 'AP_INVOICES'
           AND    zdl.trx_id 		= P_Invoice_Lines_Rec.invoice_id
           AND    NVL(zdl.self_assessed_flag,  'N') = 'N'
           AND    NVL(zdl.reporting_only_flag, 'N') = 'N';

	END IF;

    ELSE  -- handle errors

       -----------------------------------------------------------------
       l_debug_info := 'Step 12: Calculate_Tax service returns error';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
       -----------------------------------------------------------------

      l_return_status := FALSE;

      IF l_msg_count = 1 THEN

         P_Error_Code := FND_MSG_PUB.Get;

      ELSIF l_msg_count > 1 THEN
         LOOP
             P_Error_Code := FND_MSG_PUB.Get;

             IF P_Error_Code IS NULL THEN
	        EXIT;
	     END IF;

         END LOOP;
      END IF;

    END IF;

    -----------------------------------------------------------------
    l_debug_info := 'Step 13: Delete eTax Global Temporary Tables';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    BEGIN DELETE zx_trx_headers_gt;
    EXCEPTION WHEN NO_DATA_FOUND THEN null;
    END;

    BEGIN DELETE zx_transaction_lines_gt;
    EXCEPTION WHEN NO_DATA_FOUND THEN null;
    END;

    RETURN l_return_status;

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN

        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Header_Rec.Invoice_Id = '||P_Invoice_Header_Rec.Invoice_Id||
          ' P_Calling_Mode ='||P_Calling_Mode||
          ' P_Error_Code = '||P_Error_Code);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;

  END CALCULATE_QUOTE;

PROCEDURE get_po_tax_attributes
			(
			 p_application_id		IN  NUMBER,
			 p_org_id			IN  NUMBER,
			 p_entity_code			IN  VARCHAR2,
			 p_event_class_code		IN  VARCHAR2,
			 p_trx_level_type		IN  VARCHAR2,
			 p_trx_id			IN  NUMBER,
			 p_trx_line_id			IN  NUMBER,
			 x_line_intended_use		OUT NOCOPY VARCHAR2,
			 x_product_type			OUT NOCOPY VARCHAR2,
			 x_product_category		OUT NOCOPY VARCHAR2,
			 x_product_fisc_classification	OUT NOCOPY VARCHAR2,
			 x_user_defined_fisc_class	OUT NOCOPY VARCHAR2,
			 x_assessable_value		OUT NOCOPY NUMBER,
			 x_tax_classification_code	OUT NOCOPY VARCHAR2
			) IS

	CURSOR  c_po_default IS
        SELECT  line_intended_use,
                product_type,
                product_category,
                product_fisc_classification,
                user_defined_fisc_class,
                assessable_value,
		input_tax_classification_code
        FROM	zx_lines_det_factors
        WHERE	application_id           = p_application_id
        AND	internal_organization_id = p_org_id
        AND	entity_code              = p_entity_code
        AND 	event_class_code         = p_event_class_code
        AND	trx_level_type           = p_trx_level_type
        AND	trx_id                   = p_trx_id
        AND	trx_line_id              = p_trx_line_id;

	l_po_default	c_po_default%rowtype;
    l_api_name              	        CONSTANT VARCHAR2(200) := 'get_po_tax_attributes';

BEGIN

     Open  c_po_default;
     Fetch c_po_default
     Into  l_po_default;
     Close c_po_default;

     x_line_intended_use		:= l_po_default.line_intended_use;
     x_product_type			:= l_po_default.product_type;
     x_product_category			:= l_po_default.product_category;
     x_product_fisc_classification	:= l_po_default.product_fisc_classification;
     x_user_defined_fisc_class		:= l_po_default.user_defined_fisc_class;
     x_assessable_value			:= l_po_default.assessable_value;
     x_tax_classification_code		:= l_po_default.input_tax_classification_code;

     -- Need to call on-the-fly po upgrade api when no rows are returned.

     IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'PO Default values ');
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'x_line_intended_use: ' || x_line_intended_use);
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'x_product_type: '           || x_product_type);
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'x_product_category: '      || x_product_category);
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'x_product_fisc_classification: '   || x_product_fisc_classification);
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'x_user_defined_fisc_class: '   || x_user_defined_fisc_class);
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'x_assessable_value: '   || x_assessable_value);
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'x_tax_classification_code: '    || x_tax_classification_code);
     END IF;

EXCEPTION
      WHEN OTHERS THEN
           Null;

END get_po_tax_attributes;

-- bug 8495005 fix starts
PROCEDURE get_po_tax_attributes
			(
			 p_application_id		IN  NUMBER,
			 p_org_id			IN  NUMBER,
			 p_entity_code			IN  VARCHAR2,
			 p_event_class_code		IN  VARCHAR2,
			 p_trx_level_type		IN  VARCHAR2,
			 p_trx_id			IN  NUMBER,
			 p_trx_line_id			IN  NUMBER,
			 x_line_intended_use		OUT NOCOPY VARCHAR2,
			 x_product_type			OUT NOCOPY VARCHAR2,
			 x_product_category		OUT NOCOPY VARCHAR2,
			 x_product_fisc_classification	OUT NOCOPY VARCHAR2,
			 x_user_defined_fisc_class	OUT NOCOPY VARCHAR2,
			 x_assessable_value		OUT NOCOPY NUMBER,
			 x_tax_classification_code	OUT NOCOPY VARCHAR2,
			 x_taxation_country		OUT NOCOPY VARCHAR2,
			 x_trx_biz_category		OUT NOCOPY VARCHAR2
			) IS

	CURSOR  c_po_default IS
        SELECT  line_intended_use,
                product_type,
                product_category,
                product_fisc_classification,
                user_defined_fisc_class,
                assessable_value,
		input_tax_classification_code,
		default_taxation_country,
		trx_business_category
        FROM	 zx_lines_det_factors
        WHERE	application_id           = p_application_id
        AND	internal_organization_id = p_org_id
        AND	entity_code              = p_entity_code
        AND 	event_class_code         = p_event_class_code
        AND	trx_level_type           = p_trx_level_type
        AND	trx_id                   = p_trx_id
        AND	trx_line_id              = p_trx_line_id;

	l_po_default	c_po_default%rowtype;
    l_api_name              	        CONSTANT VARCHAR2(200) := 'get_po_tax_attributes';

BEGIN

     Open  c_po_default;
     Fetch c_po_default
     Into  l_po_default;
     Close c_po_default;

     x_line_intended_use		:= l_po_default.line_intended_use;
     x_product_type			:= l_po_default.product_type;
     x_product_category			:= l_po_default.product_category;
     x_product_fisc_classification	:= l_po_default.product_fisc_classification;
     x_user_defined_fisc_class		:= l_po_default.user_defined_fisc_class;
     x_assessable_value			:= l_po_default.assessable_value;
     x_tax_classification_code		:= l_po_default.input_tax_classification_code;
     x_taxation_country			:= l_po_default.default_taxation_country;
     x_trx_biz_category			:= l_po_default.trx_business_category;


     IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'PO Default values ');
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'x_line_intended_use: ' || x_line_intended_use);
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'x_product_type: '           || x_product_type);
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'x_product_category: '      || x_product_category);
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'x_product_fisc_classification: '   || x_product_fisc_classification);
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'x_user_defined_fisc_class: '   || x_user_defined_fisc_class);
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'x_assessable_value: '   || x_assessable_value);
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'x_tax_classification_code: '    || x_tax_classification_code);
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'x_taxation_country: '    || x_taxation_country);
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'x_trx_biz_category: '    || x_trx_biz_category);
     END IF;

     -- Need to call on-the-fly po upgrade api when no rows are returned.

EXCEPTION
      WHEN OTHERS THEN
           Null;

END get_po_tax_attributes;
-- bug 8495005 ends

FUNCTION CANCEL_INVOICE
		(P_Invoice_Id   IN NUMBER,
		 P_Line_Number  IN NUMBER DEFAULT NULL,
                 P_Calling_Mode IN VARCHAR2) RETURN BOOLEAN IS

    l_debug_info		VARCHAR2(240);
    l_curr_calling_sequence	VARCHAR2(4000);
    l_api_name			CONSTANT VARCHAR2(100) := 'Cancel_Invoice';

    l_return_status              	BOOLEAN := TRUE;
    l_self_assess_tax_dist_exist        BOOLEAN := FALSE ; -- Bug 6694536
    l_tax_distributions_exist           BOOLEAN := FALSE ; -- Bug 6694536
    l_return_status_service       	VARCHAR2(4000);
    l_msg_count                   	NUMBER;
    l_msg_data                    	VARCHAR2(4000);
    l_inv_cancel_date                   DATE ;  --Bug 8350132
    l_open_gl_date                      date;          --bug 13101979
    l_open_gl_period                    varchar2(100); --bug 13101979

    cursor c_reverse_tax_dist is
	  select
            nvl(item_dist.accounting_date,
	        zx_dist.gl_date)                        accounting_date, --Bug 8350132
            'N'						accrual_posted_flag,
            'U'						assets_addition_flag,
            tax_dist.assets_tracking_flag		assets_tracking_flag, --Bug14772756
            'N'						cash_posted_flag,
            AP_INVOICE_LINES_PKG.get_max_dist_line_num(
		              p_invoice_id,
		              tax_dist.invoice_line_number)+1
							distribution_line_number,
            tax_dist.dist_code_combination_id		dist_code_combination_id,
            tax_dist.invoice_id				invoice_id,
            l_user_id					last_updated_by,
            l_sysdate					last_update_date,
            tax_dist.line_type_lookup_code		line_type_lookup_code,
            ap_utilities_pkg.get_gl_period_name(
                              nvl(item_dist.accounting_date, zx_dist.gl_date), /*bug 16971320*/
                              tax_dist.org_id)          period_name,
            tax_dist.set_of_books_id			set_of_books_id,
            (-tax_dist.amount)				amount,
            (-tax_dist.base_amount)			base_amount,
            --P_Invoice_Header_Rec.batch_id		batch_id,
            l_user_id					created_by,
            l_sysdate					creation_date,
            tax_dist.description			description,
            NULL					final_match_flag,
            tax_dist.income_tax_region			income_tax_region,
            l_user_id					last_update_login,
            NULL					match_status_flag,
            'N'						posted_flag,
            tax_dist.po_distribution_id			po_distribution_id,
            NULL					program_application_id,
            NULL					program_id,
            NULL					program_update_date,
            NULL					quantity_invoiced,
            NULL					request_id,
            'Y'						reversal_flag,
            tax_dist.type_1099				type_1099,
            tax_dist.unit_price				unit_price,
            DECODE(tax_dist.encumbered_flag,
		   'R', 'R', 'N')   			encumbered_flag,    --Bug 8733916
            NULL					stat_amount,
            tax_dist.attribute1				attribute1,
            tax_dist.attribute10			attribute10,
            tax_dist.attribute11			attribute11,
            tax_dist.attribute12			attribute12,
            tax_dist.attribute13			attribute13,
            tax_dist.attribute14			attribute14,
            tax_dist.attribute15			attribute15,
            tax_dist.attribute2				attribute2,
            tax_dist.attribute3				attribute3,
            tax_dist.attribute4				attribute4,
            tax_dist.attribute5				attribute5,
            tax_dist.attribute6				attribute6,
            tax_dist.attribute7				attribute7,
            tax_dist.attribute8				attribute8,
            tax_dist.attribute9				attribute9,
            tax_dist.attribute_category			attribute_category,
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
		   tax_dist.expenditure_item_date)	expenditure_item_date, /* bug 11076722 */
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.expenditure_organization_id)  expenditure_organization_id, /* bug 11076722 */
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
            	   tax_dist.expenditure_type)		expenditure_type, /* bug 11076722 */
            tax_dist.parent_invoice_id			parent_invoice_id,
            decode(zx_dist.recoverable_flag,
		   'Y', 'E',
		   item_dist.pa_addition_flag)		pa_addition_flag,
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.pa_quantity)		pa_quantity, /* bug 11076722 */
            NULL					prepay_amount_remaining,
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.project_accounting_context) project_accounting_context, /* bug 11076722 */
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.project_id)		project_id, /* bug 11076722 */
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.task_id)			task_id, /* bug 11076722 */
            NULL					packet_id,
            'N'						awt_flag,
            tax_dist.awt_group_id			awt_group_id,
            NULL					awt_tax_rate_id,
            NULL					awt_gross_amount,
            NULL					awt_invoice_id,
            NULL					awt_origin_group_id,
            NULL					reference_1,
            NULL					reference_2,
            tax_dist.org_id				org_id,
            NULL					awt_invoice_payment_id,
            tax_dist.global_attribute_category		global_attribute_category,
            tax_dist.global_attribute1			global_attribute1,
            tax_dist.global_attribute2			global_attribute2,
            tax_dist.global_attribute3			global_attribute3,
            tax_dist.global_attribute4			global_attribute4,
            tax_dist.global_attribute5			global_attribute5,
            tax_dist.global_attribute6			global_attribute6,
            tax_dist.global_attribute7			global_attribute7,
            tax_dist.global_attribute8			global_attribute8,
            tax_dist.global_attribute9			global_attribute9,
            tax_dist.global_attribute10			global_attribute10,
            tax_dist.global_attribute11			global_attribute11,
            tax_dist.global_attribute12			global_attribute12,
            tax_dist.global_attribute13			global_attribute13,
            tax_dist.global_attribute14			global_attribute14,
            tax_dist.global_attribute15			global_attribute15,
            tax_dist.global_attribute16			global_attribute16,
            tax_dist.global_attribute17			global_attribute17,
            tax_dist.global_attribute18			global_attribute18,
            tax_dist.global_attribute19			global_attribute19,
            tax_dist.global_attribute20			global_attribute20,
            NULL                                 	receipt_verified_flag,
            NULL                                 	receipt_required_flag,
            NULL                                 	receipt_missing_flag,
            NULL                                 	justification,
            NULL                                 	expense_group,
            NULL                                 	start_expense_date,
            NULL                                 	end_expense_date,
            NULL                                 	receipt_currency_code,
            NULL                                 	receipt_conversion_rate,
            NULL                                 	receipt_currency_amount,
            NULL                                 	daily_amount,
            NULL                                 	web_parameter_id,
            NULL                                 	adjustment_reason,
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.award_id)          		award_id,
            NULL                        		credit_card_trx_id,
            tax_dist.dist_match_type    		dist_match_type,
            tax_dist.rcv_transaction_id 		rcv_transaction_id,
            ap_invoice_distributions_s.NEXTVAL   	invoice_distribution_id,
            tax_dist.invoice_distribution_id     	parent_reversal_id,
            tax_dist.tax_recoverable_flag        	tax_recoverable_flag,
            NULL                                 	merchant_document_number,
            NULL                                 	merchant_name,
            NULL                                 	merchant_reference,
            NULL                                 	merchant_tax_reg_number,
            NULL                                 	merchant_taxpayer_id,
            NULL                                 	country_of_supply,
            NULL                                 	matched_uom_lookup_code,
            NULL                                 	gms_burdenable_raw_cost,
            NULL                                 	accounting_event_id,
            tax_dist.prepay_distribution_id  	  	prepay_distribution_id,
            NULL                                 	upgrade_posted_amt,
            NULL                                 	upgrade_base_posted_amt,
            'N'                                  	inventory_transfer_status,
            NULL                                 	company_prepaid_invoice_id,
            NULL                                 	cc_reversal_flag,
            NULL                                  	awt_withheld_amt,
            NULL                                  	pa_cmt_xface_flag,
	    -- bug9321979
            decode(p_calling_mode,'CANCEL INVOICE',
                   DECODE(tax_dist.prepay_distribution_id,NULL, 'Y',NULL),Null) cancellation_flag,   --Bug8811102
            tax_dist.invoice_line_number	  	invoice_line_number,
            tax_dist.corrected_invoice_dist_id		corrected_invoice_dist_id,
            tax_dist.rounding_amt       	  	rounding_amt,
            decode(NVL(zx_dist.tax_only_line_flag,'N'),'Y',
			        NULL,zx_dist.trx_line_dist_id)		charge_applicable_to_dist_id, --Bug14772756
            NULL					corrected_quantity,
            -- bug 5572121
            -- NULL                                  	related_id,
            DECODE( tax_dist.related_id, NULL, NULL,
                    tax_dist.invoice_distribution_id,
                     ap_invoice_distributions_s.CURRVAL, NULL) related_id,
            NULL                                  	asset_book_type_code,
            NULL                                  	asset_category_id,
            tax_dist.distribution_class 	  	distribution_class,
            tax_dist.tax_code_id        	  	tax_code_id,
            tax_dist.intended_use                 	intended_use,
            zx_dist.rec_nrec_tax_dist_id 	  	detail_tax_dist_id,
            zx_dist.rec_nrec_rate     	  	  	rec_nrec_rate,
            zx_dist.recovery_rate_id  	  	  	recovery_rate_id,
            zx_dist.recovery_type_code	  	  	recovery_type_code,
            NULL                                  	withholding_tax_code_id,
            NULL			     	  	taxable_amount,
            NULL			 	  	taxable_base_amount,
            tax_dist.tax_already_distributed_flag	tax_already_distributed_flag,
            tax_dist.summary_tax_line_id 	  	summary_tax_line_id,
	        'N'				      	  	rcv_charge_addition_flag,
            (-1)*tax_dist.prepay_tax_diff_amount  prepay_tax_diff_amount, -- BUG 7338249 bug 9040333 added (-1)* as this is reversal
            tax_dist.pay_awt_group_id     pay_awt_group_id /*BUG 10261626*/
	from	ap_invoice_distributions_all 	tax_dist,
		ap_invoice_distributions_all	item_dist,
		zx_rec_nrec_dist		zx_dist
	where	tax_dist.invoice_id		  = p_invoice_id
	/* -- Bug8575619 start */
	and     tax_dist.invoice_id               = zx_dist.trx_id
	and     zx_dist.application_id   = 200
	and     zx_dist.entity_code        = 'AP_INVOICES'
	and     zx_dist.event_class_code IN ('STANDARD INVOICES',
	                                     'PREPAYMENT INVOICES',
					     'EXPENSE REPORTS')
	/* -- Bug8575619 end */
	and	tax_dist.line_type_lookup_code    IN ('NONREC_TAX', 'REC_TAX', 'TIPV', 'TERV', 'TRV')
	and	tax_dist.detail_tax_dist_id	  = zx_dist.reversed_tax_dist_id
	and	item_dist.invoice_distribution_id(+) = zx_dist.trx_line_dist_id  --bug7394712
	and	zx_dist.reverse_flag 		  = 'Y'
        --and     (p_line_number IS NULL -- bug 6056777
         --       or zx_dist.trx_line_id = p_line_number) --bug605677
	--bugfix:5582836
        and     not exists(select detail_tax_dist_id
			   from ap_invoice_distributions aid
			   where aid.invoice_id = p_invoice_id
			   and aid.detail_tax_dist_id = zx_dist.rec_nrec_tax_dist_id);


/*
Adding a new cursor for bug6056777, IF the parameter p_line_number is null then c_reverse_tax_dist would be opened
Else c_reverse_tax_dist_1 would be opened.
*/

    cursor c_reverse_tax_dist_1 is
	  select /*+ INDEX (ZX_DIST, ZX_REC_NREC_DIST_N2) */ --8576175
              nvl(item_dist.accounting_date,
	        zx_dist.gl_date)                        accounting_date,  --bug 13101979
            'N'						accrual_posted_flag,
            'U'						assets_addition_flag,
            tax_dist.assets_tracking_flag		assets_tracking_flag, --Bug14772756
            'N'						cash_posted_flag,
            AP_INVOICE_LINES_PKG.get_max_dist_line_num(
		              p_invoice_id,
		              tax_dist.invoice_line_number)+1
							distribution_line_number,
            tax_dist.dist_code_combination_id		dist_code_combination_id,
            tax_dist.invoice_id				invoice_id,
            l_user_id					last_updated_by,
            l_sysdate					last_update_date,
            tax_dist.line_type_lookup_code		line_type_lookup_code,
            ap_utilities_pkg.get_gl_period_name(
                               nvl(item_dist.accounting_date, zx_dist.gl_date), /*bug 16971320*/
                              tax_dist.org_id)          period_name,
            tax_dist.set_of_books_id			set_of_books_id,
            (-tax_dist.amount)				amount,
            (-tax_dist.base_amount)			base_amount,
            --P_Invoice_Header_Rec.batch_id		batch_id,
            l_user_id					created_by,
            l_sysdate					creation_date,
            tax_dist.description			description,
            NULL					final_match_flag,
            tax_dist.income_tax_region			income_tax_region,
            l_user_id					last_update_login,
            NULL					match_status_flag,
            'N'						posted_flag,
            tax_dist.po_distribution_id			po_distribution_id,
            NULL					program_application_id,
            NULL					program_id,
            NULL					program_update_date,
            NULL					quantity_invoiced,
            NULL					request_id,
            'Y'						reversal_flag,
            tax_dist.type_1099				type_1099,
            tax_dist.unit_price				unit_price,
            DECODE(tax_dist.encumbered_flag,
		   'R', 'R', 'N')   			encumbered_flag,    --Bug 8733916
            NULL					stat_amount,
            tax_dist.attribute1				attribute1,
            tax_dist.attribute10			attribute10,
            tax_dist.attribute11			attribute11,
            tax_dist.attribute12			attribute12,
            tax_dist.attribute13			attribute13,
            tax_dist.attribute14			attribute14,
            tax_dist.attribute15			attribute15,
            tax_dist.attribute2				attribute2,
            tax_dist.attribute3				attribute3,
            tax_dist.attribute4				attribute4,
            tax_dist.attribute5				attribute5,
            tax_dist.attribute6				attribute6,
            tax_dist.attribute7				attribute7,
            tax_dist.attribute8				attribute8,
            tax_dist.attribute9				attribute9,
            tax_dist.attribute_category			attribute_category,
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
		   tax_dist.expenditure_item_date)	expenditure_item_date, /* bug 11076722 */
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.expenditure_organization_id)  expenditure_organization_id, /* bug 11076722 */
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
            	   tax_dist.expenditure_type)		expenditure_type, /* bug 11076722 */
            tax_dist.parent_invoice_id			parent_invoice_id,
            decode(zx_dist.recoverable_flag,
		   'Y', 'E',
		   item_dist.pa_addition_flag)		pa_addition_flag,
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.pa_quantity)		pa_quantity, /* bug 11076722 */
            NULL					prepay_amount_remaining,
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.project_accounting_context) project_accounting_context, /* bug 11076722 */
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.project_id)		project_id, /* bug 11076722 */
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.task_id)			task_id, /* bug 11076722 */
            NULL					packet_id,
            'N'						awt_flag,
            tax_dist.awt_group_id			awt_group_id,
            NULL					awt_tax_rate_id,
            NULL					awt_gross_amount,
            NULL					awt_invoice_id,
            NULL					awt_origin_group_id,
            NULL					reference_1,
            NULL					reference_2,
            tax_dist.org_id				org_id,
            NULL					awt_invoice_payment_id,
            tax_dist.global_attribute_category		global_attribute_category,
            tax_dist.global_attribute1			global_attribute1,
            tax_dist.global_attribute2			global_attribute2,
            tax_dist.global_attribute3			global_attribute3,
            tax_dist.global_attribute4			global_attribute4,
            tax_dist.global_attribute5			global_attribute5,
            tax_dist.global_attribute6			global_attribute6,
            tax_dist.global_attribute7			global_attribute7,
            tax_dist.global_attribute8			global_attribute8,
            tax_dist.global_attribute9			global_attribute9,
            tax_dist.global_attribute10			global_attribute10,
            tax_dist.global_attribute11			global_attribute11,
            tax_dist.global_attribute12			global_attribute12,
            tax_dist.global_attribute13			global_attribute13,
            tax_dist.global_attribute14			global_attribute14,
            tax_dist.global_attribute15			global_attribute15,
            tax_dist.global_attribute16			global_attribute16,
            tax_dist.global_attribute17			global_attribute17,
            tax_dist.global_attribute18			global_attribute18,
            tax_dist.global_attribute19			global_attribute19,
            tax_dist.global_attribute20			global_attribute20,
            NULL                                 	receipt_verified_flag,
            NULL                                 	receipt_required_flag,
            NULL                                 	receipt_missing_flag,
            NULL                                 	justification,
            NULL                                 	expense_group,
            NULL                                 	start_expense_date,
            NULL                                 	end_expense_date,
            NULL                                 	receipt_currency_code,
            NULL                                 	receipt_conversion_rate,
            NULL                                 	receipt_currency_amount,
            NULL                                 	daily_amount,
            NULL                                 	web_parameter_id,
            NULL                                 	adjustment_reason,
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.award_id)          		award_id,
            NULL                        		credit_card_trx_id,
            tax_dist.dist_match_type    		dist_match_type,
            tax_dist.rcv_transaction_id 		rcv_transaction_id,
            ap_invoice_distributions_s.NEXTVAL   	invoice_distribution_id,
            tax_dist.invoice_distribution_id     	parent_reversal_id,
            tax_dist.tax_recoverable_flag        	tax_recoverable_flag,
            NULL                                 	merchant_document_number,
            NULL                                 	merchant_name,
            NULL                                 	merchant_reference,
            NULL                                 	merchant_tax_reg_number,
            NULL                                 	merchant_taxpayer_id,
            NULL                                 	country_of_supply,
            NULL                                 	matched_uom_lookup_code,
            NULL                                 	gms_burdenable_raw_cost,
            NULL                                 	accounting_event_id,
            tax_dist.prepay_distribution_id  	  	prepay_distribution_id,
            NULL                                 	upgrade_posted_amt,
            NULL                                 	upgrade_base_posted_amt,
            'N'                                  	inventory_transfer_status,
            NULL                                 	company_prepaid_invoice_id,
            NULL                                 	cc_reversal_flag,
            NULL                                  	awt_withheld_amt,
            NULL                                  	pa_cmt_xface_flag,
	    -- bug9321979
            decode(p_calling_mode,'CANCEL INVOICE',
                   DECODE(tax_dist.prepay_distribution_id,NULL, 'Y',NULL),Null) cancellation_flag,   --Bug8811102
            tax_dist.invoice_line_number	  	invoice_line_number,
            tax_dist.corrected_invoice_dist_id		corrected_invoice_dist_id,
            tax_dist.rounding_amt       	  	rounding_amt,
            decode(NVL(zx_dist.tax_only_line_flag,'N'),'Y',
			        NULL,zx_dist.trx_line_dist_id)		charge_applicable_to_dist_id, --Bug14772756
            NULL					corrected_quantity,
            -- bug 5572121
            -- NULL                                  	related_id,
            DECODE( tax_dist.related_id, NULL, NULL,
                    tax_dist.invoice_distribution_id,
                     ap_invoice_distributions_s.CURRVAL, NULL) related_id,

            NULL                                  	asset_book_type_code,
            NULL                                  	asset_category_id,
            tax_dist.distribution_class 	  	distribution_class,
            tax_dist.tax_code_id        	  	tax_code_id,
            tax_dist.intended_use                 	intended_use,
            zx_dist.rec_nrec_tax_dist_id 	  	detail_tax_dist_id,
            zx_dist.rec_nrec_rate     	  	  	rec_nrec_rate,
            zx_dist.recovery_rate_id  	  	  	recovery_rate_id,
            zx_dist.recovery_type_code	  	  	recovery_type_code,
            NULL                                  	withholding_tax_code_id,
            NULL			     	  	taxable_amount,
            NULL			 	  	taxable_base_amount,
            tax_dist.tax_already_distributed_flag	tax_already_distributed_flag,
            tax_dist.summary_tax_line_id 	  	summary_tax_line_id,
	        'N'				      	  	rcv_charge_addition_flag,
            (-1)*tax_dist.prepay_tax_diff_amount prepay_tax_diff_amount, -- BUG 7338249 bug 9040333 added (-1)* as this is reversal
            tax_dist.pay_awt_group_id     pay_awt_group_id /*BUG 10261626*/
	from	ap_invoice_distributions_all 	tax_dist,
		ap_invoice_distributions_all	item_dist,
		zx_rec_nrec_dist		zx_dist
	where	tax_dist.invoice_id		  = p_invoice_id
	/* -- Bug8575619 start */
	and     tax_dist.invoice_id               = zx_dist.trx_id
	and     zx_dist.application_id   = 200
	and     zx_dist.entity_code        = 'AP_INVOICES'
	and     zx_dist.event_class_code IN ('STANDARD INVOICES',
	                                     'PREPAYMENT INVOICES',
					     'EXPENSE REPORTS')
	/* -- Bug8575619 end */
	and	tax_dist.line_type_lookup_code    IN ('NONREC_TAX', 'REC_TAX', 'TIPV', 'TERV', 'TRV')
	and	tax_dist.detail_tax_dist_id	  = zx_dist.reversed_tax_dist_id
	and	item_dist.invoice_distribution_id(+) = zx_dist.trx_line_dist_id  --bug7394712
	and	zx_dist.reverse_flag 		  = 'Y'
        and   zx_dist.trx_line_id = p_line_number --bug6056777
	--bugfix:5582836
        and     not exists(select detail_tax_dist_id
			   from ap_invoice_distributions aid
			   where aid.invoice_id = p_invoice_id
			   and aid.detail_tax_dist_id = zx_dist.rec_nrec_tax_dist_id);



	l_reverse_tax_dist	c_reverse_tax_dist%rowtype ;

    /*
     --  Bug 6694536. Added cursor to fetch reversal lines from ap_self_assessed_tax_dist_all.
     --  Cursor is similar to c_reverse_tax_dist, except it is using ap_self_assessed_tax_dist_all
     --  to fetch lines.
     */

     cursor c_rev_self_assess_tax_dist is
	  select
            nvl(item_dist.accounting_date,
	        zx_dist.gl_date)                        accounting_date, --Bug 8350132
            'N'						accrual_posted_flag,
            'U'						assets_addition_flag,
            tax_dist.assets_tracking_flag		assets_tracking_flag, --Bug14772756
            'N'						cash_posted_flag,
            AP_ETAX_UTILITY_PKG.Get_Max_Dist_Num_Self(
		              p_invoice_id,
		              tax_dist.invoice_line_number)+1
							distribution_line_number,
            tax_dist.dist_code_combination_id		dist_code_combination_id,
            tax_dist.invoice_id				invoice_id,
            l_user_id					last_updated_by,
            l_sysdate					last_update_date,
            tax_dist.line_type_lookup_code		line_type_lookup_code,
            ap_utilities_pkg.get_gl_period_name(
                            nvl(item_dist.accounting_date, zx_dist.gl_date), /*bug 16971320*/
                            tax_dist.org_id)          period_name,
            tax_dist.set_of_books_id			set_of_books_id,
            (-tax_dist.amount)				amount,
            (-tax_dist.base_amount)			base_amount,
            --P_Invoice_Header_Rec.batch_id		batch_id,
            l_user_id					created_by,
            l_sysdate					creation_date,
            tax_dist.description			description,
            NULL					final_match_flag,
            tax_dist.income_tax_region			income_tax_region,
            l_user_id					last_update_login,
            NULL					match_status_flag,
            'N'						posted_flag,
            tax_dist.po_distribution_id			po_distribution_id,
            NULL					program_application_id,
            NULL					program_id,
            NULL					program_update_date,
            NULL					quantity_invoiced,
            NULL					request_id,
            'Y'						reversal_flag,
            tax_dist.type_1099				type_1099,
            tax_dist.unit_price				unit_price,
            DECODE(tax_dist.encumbered_flag,
 		   'R', 'R', 'N')   			encumbered_flag,    --Bug 8733916
            NULL					stat_amount,
            tax_dist.attribute1				attribute1,
            tax_dist.attribute10			attribute10,
            tax_dist.attribute11			attribute11,
            tax_dist.attribute12			attribute12,
            tax_dist.attribute13			attribute13,
            tax_dist.attribute14			attribute14,
            tax_dist.attribute15			attribute15,
            tax_dist.attribute2				attribute2,
            tax_dist.attribute3				attribute3,
            tax_dist.attribute4				attribute4,
            tax_dist.attribute5				attribute5,
            tax_dist.attribute6				attribute6,
            tax_dist.attribute7				attribute7,
            tax_dist.attribute8				attribute8,
            tax_dist.attribute9				attribute9,
            tax_dist.attribute_category			attribute_category,
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
		   tax_dist.expenditure_item_date)	expenditure_item_date, /* bug 11076722 */
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.expenditure_organization_id)  expenditure_organization_id, /* bug 11076722 */
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
            	   tax_dist.expenditure_type)		expenditure_type, /* bug 11076722 */
            tax_dist.parent_invoice_id			parent_invoice_id,
            decode(zx_dist.recoverable_flag,
		   'Y', 'E',
		   item_dist.pa_addition_flag)		pa_addition_flag,
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.pa_quantity)		pa_quantity, /* bug 11076722 */
            NULL					prepay_amount_remaining,
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.project_accounting_context) project_accounting_context, /* bug 11076722 */
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.project_id)		project_id, /* bug 11076722 */
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.task_id)			task_id, /* bug 11076722 */
            NULL					packet_id,
            'N'						awt_flag,
            tax_dist.awt_group_id			awt_group_id,
            NULL					awt_tax_rate_id,
            NULL					awt_gross_amount,
            NULL					awt_invoice_id,
            NULL					awt_origin_group_id,
            NULL					reference_1,
            NULL					reference_2,
            tax_dist.org_id				org_id,
            NULL					awt_invoice_payment_id,
            tax_dist.global_attribute_category		global_attribute_category,
            tax_dist.global_attribute1			global_attribute1,
            tax_dist.global_attribute2			global_attribute2,
            tax_dist.global_attribute3			global_attribute3,
            tax_dist.global_attribute4			global_attribute4,
            tax_dist.global_attribute5			global_attribute5,
            tax_dist.global_attribute6			global_attribute6,
            tax_dist.global_attribute7			global_attribute7,
            tax_dist.global_attribute8			global_attribute8,
            tax_dist.global_attribute9			global_attribute9,
            tax_dist.global_attribute10			global_attribute10,
            tax_dist.global_attribute11			global_attribute11,
            tax_dist.global_attribute12			global_attribute12,
            tax_dist.global_attribute13			global_attribute13,
            tax_dist.global_attribute14			global_attribute14,
            tax_dist.global_attribute15			global_attribute15,
            tax_dist.global_attribute16			global_attribute16,
            tax_dist.global_attribute17			global_attribute17,
            tax_dist.global_attribute18			global_attribute18,
            tax_dist.global_attribute19			global_attribute19,
            tax_dist.global_attribute20			global_attribute20,
            NULL                                 	receipt_verified_flag,
            NULL                                 	receipt_required_flag,
            NULL                                 	receipt_missing_flag,
            NULL                                 	justification,
            NULL                                 	expense_group,
            NULL                                 	start_expense_date,
            NULL                                 	end_expense_date,
            NULL                                 	receipt_currency_code,
            NULL                                 	receipt_conversion_rate,
            NULL                                 	receipt_currency_amount,
            NULL                                 	daily_amount,
            NULL                                 	web_parameter_id,
            NULL                                 	adjustment_reason,
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.award_id)          		award_id,
            NULL                        		credit_card_trx_id,
            tax_dist.dist_match_type    		dist_match_type,
            tax_dist.rcv_transaction_id 		rcv_transaction_id,
            ap_invoice_distributions_s.NEXTVAL   	invoice_distribution_id,
            tax_dist.invoice_distribution_id     	parent_reversal_id,
            tax_dist.tax_recoverable_flag        	tax_recoverable_flag,
            NULL                                 	merchant_document_number,
            NULL                                 	merchant_name,
            NULL                                 	merchant_reference,
            NULL                                 	merchant_tax_reg_number,
            NULL                                 	merchant_taxpayer_id,
            NULL                                 	country_of_supply,
            NULL                                 	matched_uom_lookup_code,
            NULL                                 	gms_burdenable_raw_cost,
            NULL                                 	accounting_event_id,
            tax_dist.prepay_distribution_id  	  	prepay_distribution_id,
            NULL                                 	upgrade_posted_amt,
            NULL                                 	upgrade_base_posted_amt,
            'N'                                  	inventory_transfer_status,
            NULL                                 	company_prepaid_invoice_id,
            NULL                                 	cc_reversal_flag,
            NULL                                  	awt_withheld_amt,
            NULL                                  	pa_cmt_xface_flag,
	    -- bug9321979
            decode(p_calling_mode,'CANCEL INVOICE',
                   DECODE(tax_dist.prepay_distribution_id,NULL,'Y',NULL),Null) cancellation_flag,   --Bug8811102
            tax_dist.invoice_line_number	  	invoice_line_number,
            tax_dist.corrected_invoice_dist_id		corrected_invoice_dist_id,
            tax_dist.rounding_amt       	  	rounding_amt,
            decode(NVL(zx_dist.tax_only_line_flag,'N'),'Y',
			        NULL,zx_dist.trx_line_dist_id)		charge_applicable_to_dist_id, --Bug14772756
            NULL					corrected_quantity,
            -- bug 5572121
            -- NULL                                  	related_id,
            DECODE( tax_dist.related_id, NULL, NULL,
                    tax_dist.invoice_distribution_id,
                     ap_invoice_distributions_s.CURRVAL, NULL) related_id,

            NULL                                  	asset_book_type_code,
            NULL                                  	asset_category_id,
            tax_dist.distribution_class 	  	distribution_class,
            tax_dist.tax_code_id        	  	tax_code_id,
            tax_dist.intended_use                 	intended_use,
            zx_dist.rec_nrec_tax_dist_id 	  	detail_tax_dist_id,
            zx_dist.rec_nrec_rate     	  	  	rec_nrec_rate,
            zx_dist.recovery_rate_id  	  	  	recovery_rate_id,
            zx_dist.recovery_type_code	  	  	recovery_type_code,
            NULL                                  	withholding_tax_code_id,
            NULL			     	  	taxable_amount,
            NULL			 	  	taxable_base_amount,
            tax_dist.tax_already_distributed_flag	tax_already_distributed_flag,
            tax_dist.summary_tax_line_id 	  	summary_tax_line_id,
	        'N'				      	  	rcv_charge_addition_flag,
	        zx_dist.self_assessed_flag                  self_assessed_flag,
            -- bug 6805655
            tax_dist.self_assessed_tax_liab_ccid        self_assessed_tax_liab_ccid,
            (-1)*tax_dist.prepay_tax_diff_amount prepay_tax_diff_amount -- BUG 7338249  bug 9040333 added (-1)* as this is reversal
	from	ap_self_assessed_tax_dist_all 	tax_dist,
		ap_invoice_distributions_all	item_dist,
		zx_rec_nrec_dist		zx_dist
	where	tax_dist.invoice_id		  = p_invoice_id
	/* -- Bug8575619 start */
	and     tax_dist.invoice_id               = zx_dist.trx_id
	and     zx_dist.application_id   = 200
	and     zx_dist.entity_code        = 'AP_INVOICES'
	and     zx_dist.event_class_code IN ('STANDARD INVOICES',
	                                     'PREPAYMENT INVOICES',
					     'EXPENSE REPORTS')
	/* -- Bug8575619 end */
	and	tax_dist.line_type_lookup_code    IN ('NONREC_TAX', 'REC_TAX')
	and	tax_dist.detail_tax_dist_id	  = zx_dist.reversed_tax_dist_id
	and	item_dist.invoice_distribution_id(+) = zx_dist.trx_line_dist_id  --bug7394712
	and	zx_dist.reverse_flag 		  = 'Y'
        --and     (p_line_number IS NULL -- bug 6056777
          --       or zx_dist.trx_line_id = p_line_number) --bug605677
	--bugfix:5582836
    /*  -- bug 6896627
        and     not exists(select detail_tax_dist_id
			   from ap_invoice_distributions aid
			   where aid.invoice_id = p_invoice_id
			   and aid.detail_tax_dist_id = zx_dist.rec_nrec_tax_dist_id)
    */
    AND NOT EXISTS
      (SELECT aid.detail_tax_dist_id
         FROM ap_self_assessed_tax_dist_all aid
        WHERE aid.invoice_id            = p_invoice_id
          AND aid.detail_tax_dist_id    = zx_dist.rec_nrec_tax_dist_id
          AND aid.line_type_lookup_code IN ('REC_TAX','NONREC_TAX'))
    -- bug 6896627
    ;

     /*
       -- Bug 6694536. Added cursor to fetch reversal lines from ap_self_assessed_tax_dist_all.
       -- Cursor is similar to c_reverse_tax_dist_1, except it is using ap_self_assessed_tax_dist_all
       -- to fetch lines. Second cursor for performance reasons(bug 6056777)
     */

    cursor c_rev_self_assess_tax_dist_1 is
	  select
              nvl(item_dist.accounting_date,
	        zx_dist.gl_date)                        accounting_date,  --bug 13101979
            'N'						accrual_posted_flag,
            'U'						assets_addition_flag,
            tax_dist.assets_tracking_flag		assets_tracking_flag, --Bug14772756
            'N'						cash_posted_flag,
            AP_ETAX_UTILITY_PKG.Get_Max_Dist_Num_Self(
		              p_invoice_id,
		              tax_dist.invoice_line_number)+1
							distribution_line_number,
            tax_dist.dist_code_combination_id		dist_code_combination_id,
            tax_dist.invoice_id				invoice_id,
            l_user_id					last_updated_by,
            l_sysdate					last_update_date,
            tax_dist.line_type_lookup_code		line_type_lookup_code,
            ap_utilities_pkg.get_gl_period_name(
                               nvl(item_dist.accounting_date, zx_dist.gl_date), /*bug 16971320*/
                              tax_dist.org_id)          period_name,
            tax_dist.set_of_books_id			set_of_books_id,
            (-tax_dist.amount)				amount,
            (-tax_dist.base_amount)			base_amount,
            --P_Invoice_Header_Rec.batch_id		batch_id,
            l_user_id					created_by,
            l_sysdate					creation_date,
            tax_dist.description			description,
            NULL					final_match_flag,
            tax_dist.income_tax_region			income_tax_region,
            l_user_id					last_update_login,
            NULL					match_status_flag,
            'N'						posted_flag,
            tax_dist.po_distribution_id			po_distribution_id,
            NULL					program_application_id,
            NULL					program_id,
            NULL					program_update_date,
            NULL					quantity_invoiced,
            NULL					request_id,
            'Y'						reversal_flag,
            tax_dist.type_1099				type_1099,
            tax_dist.unit_price				unit_price,
            DECODE(tax_dist.encumbered_flag,
		   'R', 'R', 'N')   			encumbered_flag,    --Bug 8733916
            NULL					stat_amount,
            tax_dist.attribute1				attribute1,
            tax_dist.attribute10			attribute10,
            tax_dist.attribute11			attribute11,
            tax_dist.attribute12			attribute12,
            tax_dist.attribute13			attribute13,
            tax_dist.attribute14			attribute14,
            tax_dist.attribute15			attribute15,
            tax_dist.attribute2				attribute2,
            tax_dist.attribute3				attribute3,
            tax_dist.attribute4				attribute4,
            tax_dist.attribute5				attribute5,
            tax_dist.attribute6				attribute6,
            tax_dist.attribute7				attribute7,
            tax_dist.attribute8				attribute8,
            tax_dist.attribute9				attribute9,
            tax_dist.attribute_category			attribute_category,
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
		   tax_dist.expenditure_item_date)	expenditure_item_date, /* bug 11076722 */
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.expenditure_organization_id)  expenditure_organization_id, /* bug 11076722 */
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
            	   tax_dist.expenditure_type)		expenditure_type, /* bug 11076722 */
            tax_dist.parent_invoice_id			parent_invoice_id,
            decode(zx_dist.recoverable_flag,
		   'Y', 'E',
		   item_dist.pa_addition_flag)		pa_addition_flag,
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.pa_quantity)		pa_quantity, /* bug 11076722 */
            NULL					prepay_amount_remaining,
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.project_accounting_context) project_accounting_context, /* bug 11076722 */
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.project_id)		project_id, /* bug 11076722 */
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.task_id)			task_id, /* bug 11076722 */
            NULL					packet_id,
            'N'						awt_flag,
            tax_dist.awt_group_id			awt_group_id,
            NULL					awt_tax_rate_id,
            NULL					awt_gross_amount,
            NULL					awt_invoice_id,
            NULL					awt_origin_group_id,
            NULL					reference_1,
            NULL					reference_2,
            tax_dist.org_id				org_id,
            NULL					awt_invoice_payment_id,
            tax_dist.global_attribute_category		global_attribute_category,
            tax_dist.global_attribute1			global_attribute1,
            tax_dist.global_attribute2			global_attribute2,
            tax_dist.global_attribute3			global_attribute3,
            tax_dist.global_attribute4			global_attribute4,
            tax_dist.global_attribute5			global_attribute5,
            tax_dist.global_attribute6			global_attribute6,
            tax_dist.global_attribute7			global_attribute7,
            tax_dist.global_attribute8			global_attribute8,
            tax_dist.global_attribute9			global_attribute9,
            tax_dist.global_attribute10			global_attribute10,
            tax_dist.global_attribute11			global_attribute11,
            tax_dist.global_attribute12			global_attribute12,
            tax_dist.global_attribute13			global_attribute13,
            tax_dist.global_attribute14			global_attribute14,
            tax_dist.global_attribute15			global_attribute15,
            tax_dist.global_attribute16			global_attribute16,
            tax_dist.global_attribute17			global_attribute17,
            tax_dist.global_attribute18			global_attribute18,
            tax_dist.global_attribute19			global_attribute19,
            tax_dist.global_attribute20			global_attribute20,
            NULL                                 	receipt_verified_flag,
            NULL                                 	receipt_required_flag,
            NULL                                 	receipt_missing_flag,
            NULL                                 	justification,
            NULL                                 	expense_group,
            NULL                                 	start_expense_date,
            NULL                                 	end_expense_date,
            NULL                                 	receipt_currency_code,
            NULL                                 	receipt_conversion_rate,
            NULL                                 	receipt_currency_amount,
            NULL                                 	daily_amount,
            NULL                                 	web_parameter_id,
            NULL                                 	adjustment_reason,
            decode(zx_dist.recoverable_flag,
                   'Y', NULL,
                   tax_dist.award_id)          		award_id,
            NULL                        		credit_card_trx_id,
            tax_dist.dist_match_type    		dist_match_type,
            tax_dist.rcv_transaction_id 		rcv_transaction_id,
            ap_invoice_distributions_s.NEXTVAL   	invoice_distribution_id,
            tax_dist.invoice_distribution_id     	parent_reversal_id,
            tax_dist.tax_recoverable_flag        	tax_recoverable_flag,
            NULL                                 	merchant_document_number,
            NULL                                 	merchant_name,
            NULL                                 	merchant_reference,
            NULL                                 	merchant_tax_reg_number,
            NULL                                 	merchant_taxpayer_id,
            NULL                                 	country_of_supply,
            NULL                                 	matched_uom_lookup_code,
            NULL                                 	gms_burdenable_raw_cost,
            NULL                                 	accounting_event_id,
            tax_dist.prepay_distribution_id  	  	prepay_distribution_id,
            NULL                                 	upgrade_posted_amt,
            NULL                                 	upgrade_base_posted_amt,
            'N'                                  	inventory_transfer_status,
            NULL                                 	company_prepaid_invoice_id,
            NULL                                 	cc_reversal_flag,
            NULL                                  	awt_withheld_amt,
            NULL                                  	pa_cmt_xface_flag,
	    -- bug9321979
            decode(p_calling_mode,'CANCEL INVOICE',
                   DECODE(tax_dist.prepay_distribution_id,NULL,'Y',NULL),Null) cancellation_flag,   --Bug8811102
            tax_dist.invoice_line_number	  	invoice_line_number,
            tax_dist.corrected_invoice_dist_id		corrected_invoice_dist_id,
            tax_dist.rounding_amt       	  	rounding_amt,
            decode(NVL(zx_dist.tax_only_line_flag,'N'),'Y',
			        NULL,zx_dist.trx_line_dist_id)		charge_applicable_to_dist_id, --Bug14772756
            NULL					corrected_quantity,
            -- bug 5572121
            -- NULL                                  	related_id,
            DECODE( tax_dist.related_id, NULL, NULL,
                    tax_dist.invoice_distribution_id,
                     ap_invoice_distributions_s.CURRVAL, NULL) related_id,

            NULL                                  	asset_book_type_code,
            NULL                                  	asset_category_id,
            tax_dist.distribution_class 	  	distribution_class,
            tax_dist.tax_code_id        	  	tax_code_id,
            tax_dist.intended_use                 	intended_use,
            zx_dist.rec_nrec_tax_dist_id 	  	detail_tax_dist_id,
            zx_dist.rec_nrec_rate     	  	  	rec_nrec_rate,
            zx_dist.recovery_rate_id  	  	  	recovery_rate_id,
            zx_dist.recovery_type_code	  	  	recovery_type_code,
            NULL                                  	withholding_tax_code_id,
            NULL			     	  	taxable_amount,
            NULL			 	  	taxable_base_amount,
            tax_dist.tax_already_distributed_flag	tax_already_distributed_flag,
            tax_dist.summary_tax_line_id 	  	summary_tax_line_id,
	        'N'				      	rcv_charge_addition_flag,
            zx_dist.self_assessed_flag                  self_assessed_flag,
            -- bug 6805655
            tax_dist.self_assessed_tax_liab_ccid        self_assessed_tax_liab_ccid,
            (-1)*tax_dist.prepay_tax_diff_amount  prepay_tax_diff_amount-- BUG 7338249  bug 9040333 added (-1)* as this is reversal
	from	ap_self_assessed_tax_dist_all 	tax_dist,
	        ap_invoice_distributions_all	item_dist,
                zx_rec_nrec_dist		zx_dist
	where	tax_dist.invoice_id		  = p_invoice_id
	/* -- Bug8575619 start */
	and     tax_dist.invoice_id               = zx_dist.trx_id
	and     zx_dist.application_id   = 200
	and     zx_dist.entity_code        = 'AP_INVOICES'
	and     zx_dist.event_class_code IN ('STANDARD INVOICES',
	                                     'PREPAYMENT INVOICES',
					     'EXPENSE REPORTS')
	/* -- Bug8575619 end */
	and	tax_dist.line_type_lookup_code    IN ('NONREC_TAX', 'REC_TAX')
	and	tax_dist.detail_tax_dist_id	  = zx_dist.reversed_tax_dist_id
	and	item_dist.invoice_distribution_id(+) = zx_dist.trx_line_dist_id  --bug7394712
	and	zx_dist.reverse_flag 		  = 'Y'
        and   zx_dist.trx_line_id = p_line_number --bug6056777
	--bugfix:5582836
    /*     -- bug 6896627
        and     not exists(select detail_tax_dist_id
			   from ap_invoice_distributions aid
			   where aid.invoice_id = p_invoice_id
			   and aid.detail_tax_dist_id = zx_dist.rec_nrec_tax_dist_id)
     */

    AND NOT EXISTS
      (SELECT aid.detail_tax_dist_id
         FROM ap_self_assessed_tax_dist_all aid
        WHERE aid.invoice_id            = p_invoice_id
          AND aid.detail_tax_dist_id    = zx_dist.rec_nrec_tax_dist_id
          AND aid.line_type_lookup_code IN ('REC_TAX','NONREC_TAX'))
    -- bug 6896627
    ;


	l_self_assess_rev_tax_dist   c_rev_self_assess_tax_dist%rowtype ;  -- Bug 6694536
	l_self_assess_rev_tax_dist_1 c_rev_self_assess_tax_dist_1%rowtype ; -- Bug 6694536

    l_reverse_dist_count  NUMBER;
    l_Error_Code          ZX_ERRORS_GT.message_text%TYPE;


    --Bug8811102

    l_All_Error_Messages  VARCHAR2(4000);
    l_tax_only_line_flag  VARCHAR2(1):='N';
    l_line_level_action   VARCHAR2(15):='';
    l_line_number         NUMBER;
    l_trx_level_type      VARCHAR2(15);
    l_inv_rcv_matched     VARCHAR2(1) := 'N';


    l_tax_already_calculated VARCHAR2(1) :='N';

    l_inv_header_rec      ap_invoices_all%ROWTYPE;
    l_event_class_code    zx_trx_headers_gt.event_class_code%TYPE;
    l_event_type_code     zx_trx_headers_gt.event_type_code%TYPE;

    l_transaction_rec     zx_api_pub.transaction_rec_type;

    l_msg                 VARCHAR2(4000);
    l_success			  BOOLEAN;
    l_gt_error            VARCHAR2(4000);    /*Bug 16842904*/


    CURSOR Invoice_Header IS
    SELECT *
      FROM ap_invoices_all
     WHERE invoice_id = P_Invoice_Id;

    CURSOR Invoice_Lines IS
    SELECT *
      FROM ap_invoice_lines_all
     WHERE invoice_id = P_Invoice_Id
       AND line_type_lookup_code NOT IN ('TAX', 'AWT')
       AND NVL(tax_already_calculated_flag,'N') = 'Y'
       AND NVL(discarded_flag,'N')='N';
--       AND NVL(cancelled_flag,'N')='N'; --Bug 13714737

    CURSOR Invoice_Line IS
    SELECT *
      FROM ap_invoice_lines_all
     WHERE invoice_id  = P_Invoice_Id
       AND line_number = P_Line_Number
       AND line_type_lookup_code NOT IN ('TAX', 'AWT')
       AND NVL(tax_already_calculated_flag,'N') = 'Y';

    CURSOR Invoice_Tax_OnlyLines IS
    SELECT *
      FROM ap_invoice_lines_all
     WHERE invoice_id = P_Invoice_Id
       AND line_type_lookup_code IN ('TAX')
       AND NVL(discarded_flag,'N')='N'
       AND NVL(cancelled_flag,'N')='N';

    --Bug8811102

    -- Bug 10140793 - Begin
    l_unrev_dist_count         NUMBER := 0 ;
    l_unrev_sa_dist_count      NUMBER := 0 ;
    l_rev_sa_dist_count        NUMBER := 0 ;
    l_rev_dist_cursor_count    NUMBER := 0 ;
    l_rev_sa_dist_cursor_count NUMBER := 0 ;
    -- Bug 10140793 - End

BEGIN

    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.CANCEL_INVOICE';

 /*Added the following delete statements for bug 12418361 -Begin*/
   l_debug_info := 'Purge staging tables of ZX';
   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
   END IF;


    DELETE zx_transaction_lines_gt;
    DELETE zx_import_tax_lines_gt;
    DELETE zx_trx_tax_link_gt;
    DELETE zx_reverse_dist_gt;

    AP_ETAX_SERVICES_PKG.G_SITE_ATTRIBUTES.DELETE;
    AP_ETAX_SERVICES_PKG.G_ORG_ATTRIBUTES.DELETE;

   /*Added the following delete statements for bug 12418361 -End*/


--Bug8811102
--==============================================================================
    -----------------------------------------------------------------
	l_debug_info := 'Step 1: Populating invoice header local record';
    -----------------------------------------------------------------
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, l_debug_info);
    END IF;

	BEGIN
       OPEN Invoice_Header;
       FETCH Invoice_Header INTO l_inv_header_rec;
       CLOSE Invoice_Header;
    END;

    IF (l_inv_header_rec.invoice_type_lookup_code IN ('AWT', 'INTEREST')) THEN
       RETURN l_return_status;
    END IF;

    -----------------------------------------------------------------
	l_debug_info := 'Step 1.1: Populating invoice lines global record';
    -----------------------------------------------------------------
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, l_debug_info);
    END IF;

    IF P_Line_Number IS NOT NULL THEN
        BEGIN
           OPEN Invoice_Line;
          FETCH Invoice_Line
           BULK  COLLECT INTO l_inv_line_list;
          CLOSE Invoice_Line;
        END;
    ELSE
        BEGIN
           OPEN Invoice_Lines;
          FETCH Invoice_Lines
           BULK COLLECT INTO l_inv_line_list;
          CLOSE Invoice_Lines;
        END;
    END IF;

    -------------------------------------------------------------------
	l_debug_info := 'Step 2: Get event class code';
    -------------------------------------------------------------------
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, l_debug_info);
    END IF;

    IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Class_Code(
       P_Invoice_Type_Lookup_Code => l_inv_header_rec.invoice_type_lookup_code,
       P_Event_Class_Code         => l_event_class_code,
       P_error_code               => l_error_code,
       P_calling_sequence         => l_curr_calling_sequence)) THEN

       l_return_status := FALSE;
    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 3: Get event type code';
    -------------------------------------------------------------------
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, l_debug_info);
    END IF;

    IF (l_return_status = TRUE) THEN
      	IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Type_Code(
	       P_Event_Class_Code          => l_event_class_code,
	       P_Calling_Mode              => P_Calling_Mode,
	       P_eTax_Already_called_flag  => NULL,
		   P_Event_Type_Code           => l_Event_Type_Code,
		   P_Error_Code                => l_error_code,
		   P_Calling_Sequence          => l_curr_calling_sequence)) THEN

	       l_return_status := FALSE;
	    END IF;
	END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 4: Populate service specific parameter';
    -------------------------------------------------------------------
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, l_debug_info);
    END IF;

    l_transaction_rec.internal_organization_id := l_inv_header_rec.org_id;
    l_transaction_rec.application_id           := 200;
    l_transaction_rec.entity_code              := 'AP_INVOICES';
    l_transaction_rec.event_class_code         := l_event_class_code;
    l_transaction_rec.event_type_code          := l_event_type_code;
    l_transaction_rec.trx_id                   := l_inv_header_rec.invoice_id;

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'CANCEL_TAX_LINES values');
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'application_id: '|| l_transaction_rec.application_id);
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'entity_code: ' || l_transaction_rec.entity_code);
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'event_class_code: ' || l_transaction_rec.event_class_code);
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'event_type_code: ' || l_transaction_rec.event_type_code);
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_id: '           || l_transaction_rec.trx_id);
    END IF;

    -------------------------------------------------------------------
   	l_debug_info := 'Step 5: Handle Cancel Invoice Mode';
    -------------------------------------------------------------------
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, l_debug_info);
    END IF;

    IF P_Calling_Mode = 'CANCEL INVOICE' THEN
       IF TAX_ONLY_LINE_EXIST(p_invoice_id) THEN
          l_tax_only_line_flag :='Y';
       ELSE
          l_tax_only_line_flag :='N';
       END IF;
          l_line_number           :=NULL;
          l_trx_level_type        :=NULL;
          l_line_level_action     := 'CANCEL';
    ELSIF P_Calling_Mode = 'DISCARD LINE' THEN
          l_tax_only_line_flag :='N';
          l_line_number        :=P_Line_Number;
          l_trx_level_type     :='LINE';
          l_line_level_action  :='DISCARD';
    ELSIF P_Calling_Mode = 'UNAPPLY PREPAY' THEN
          l_tax_only_line_flag :='N';
          l_line_number        :=P_Line_Number;
          l_trx_level_type     :='LINE';
          l_line_level_action  :='UNAPPLY_FROM';
    END IF;

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'Calling Mode '||P_Calling_Mode);
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'Tax Only Flag: '|| l_tax_only_line_flag);
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'Line Number: ' || l_line_number);
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'Trx Line Level Type: ' || l_trx_level_type);
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'Line Level Action: ' || l_line_level_action);
    END IF;

    l_tax_distributions_exist := tax_distributions_exist (p_invoice_id=>p_invoice_id);

    l_self_assess_tax_dist_exist := self_assess_tax_dist_exist (p_invoice_id=>p_invoice_id);

--==============================================================================
--Bug8811102


--bug8733916

   IF(p_calling_mode='DISCARD LINE') THEN  --Bug8811102

   	    UPDATE ap_invoice_distributions_all aid
      	       SET aid.encumbered_flag='R'
    	     WHERE aid.invoice_id=p_invoice_id
     	       AND nvl(aid.encumbered_flag,'N') in ('N','H','P')
	       AND aid.charge_applicable_to_dist_id in (select invoice_distribution_id from ap_invoice_distributions_all aid1
	                                             where aid1.invoice_id=p_invoice_id
				  		       and aid1.invoice_line_number=p_line_number)
               AND aid.line_type_lookup_code in ('REC_TAX','NONREC_TAX','TRV','TERV','TIPV')
	       AND nvl(aid.reversal_flag,'N')<>'Y'
               AND EXISTS (SELECT 1
               		     FROM financials_system_params_all fsp
	                    WHERE fsp.org_id = aid.org_id
		              AND nvl(fsp.purch_encumbrance_flag, 'N') = 'Y');


    END IF;

   IF(p_calling_mode='CANCEL INVOICE') THEN  --Bug8811102

   	    UPDATE ap_invoice_distributions_all aid
               SET aid.encumbered_flag='R'
    	     WHERE aid.invoice_id=p_invoice_id
     	       AND nvl(aid.encumbered_flag,'N') in ('N','H','P')
	       AND aid.line_type_lookup_code in ('REC_TAX','NONREC_TAX','TRV','TERV','TIPV')
	       AND nvl(aid.reversal_flag,'N')<>'Y'
	       AND EXISTS (SELECT 1
                             FROM financials_system_params_all fsp
                            WHERE fsp.org_id = aid.org_id
                              AND nvl(fsp.purch_encumbrance_flag, 'N') = 'Y');

    END IF;

--End of bug 8733916
   --Removed the if statement for bug9749258


    IF l_tax_distributions_exist THEN -- Marker 1

      -----------------------------------------------------------------
      l_debug_info := 'Step 1: Insert into zx_reverse_dist_gt';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------

      INSERT INTO zx_reverse_dist_gt(
        internal_organization_id,
        reversing_appln_id,
        reversing_entity_code,
        reversing_evnt_cls_code,
        reversing_trx_id,
        reversing_trx_level_type,
        reversing_trx_line_id,
        reversing_trx_line_dist_id,
        reversing_tax_line_id,
        reversed_appln_id,
        reversed_entity_code,
        reversed_evnt_cls_code,
        reversed_trx_id,
        reversed_trx_level_type,
        reversed_trx_line_id,
        reversed_trx_line_dist_id,
        reversed_tax_line_id
      )
      select	distinct
		item_dist.org_id                	internal_organization_id,
                zx_dist.application_id          	reversing_appln_id,
                zx_dist.entity_code             	reversing_entity_code,
                zx_dist.event_class_code        	reversing_evnt_cls_code,
                zx_dist.trx_id                  	reversing_trx_id,
                zx_dist.trx_level_type          	reversing_trx_level_type,
                zx_dist.trx_line_id             	reversing_trx_line_id,
                reverse_dist.invoice_distribution_id	reversing_trx_line_dist_id,
                zx_dist.tax_line_id             	reversing_tax_line_id,
                zx_dist.application_id          	reversed_appln_id,
                zx_dist.entity_code             	reversed_entity_code,
                zx_dist.event_class_code        	reversed_evnt_cls_code,
                zx_dist.trx_id                  	reversed_trx_id,
                zx_dist.trx_level_type          	reversed_trx_level_type,
                zx_dist.trx_line_id             	reversed_trx_line_id,
		        zx_dist.trx_line_dist_id        	reversed_trx_line_dist_id,
                zx_dist.tax_line_id             	reversed_tax_line_id
        from    ap_invoice_distributions_all    item_dist,
                ap_invoice_distributions_all    tax_dist,
                ap_invoice_distributions_all    reverse_dist,
                zx_rec_nrec_dist                zx_dist
        where   tax_dist.invoice_id                     = p_invoice_id
        and     tax_dist.invoice_id                     = item_dist.invoice_id
        and     tax_dist.charge_applicable_to_dist_id   = item_dist.invoice_distribution_id
        and  	item_dist.invoice_distribution_id	= reverse_dist.parent_reversal_id
        and     tax_dist.line_type_lookup_code          IN ('NONREC_TAX', 'REC_TAX', 'TIPV', 'TRV', 'TERV')
        and     tax_dist.detail_tax_dist_id             = zx_dist.rec_nrec_tax_dist_id
	and     item_dist.invoice_id                    = reverse_dist.invoice_id  --bug 12920913
        and     nvl(zx_dist.reverse_flag, 'N')          = 'N'
        and     (p_line_number IS NULL
                 or item_dist.invoice_line_number = p_line_number);

      l_reverse_dist_count := SQL%ROWCOUNT;

      -----------------------------------------------------------------
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'Row Count inserted into zx_reverse_dist_gt: ' || l_reverse_dist_count);
      END IF;
      -----------------------------------------------------------------

      -- Bug 10140793 Begin
      IF l_reverse_dist_count = 0 THEN
         IF p_line_number IS NULL THEN
            SELECT COUNT(1)
              INTO l_unrev_dist_count
	      FROM ap_invoice_distributions_all tax_dist
	     WHERE tax_dist.invoice_id                    = p_invoice_id
               AND tax_dist.line_type_lookup_code        IN ('NONREC_TAX', 'REC_TAX', 'TIPV', 'TRV', 'TERV')
	       AND tax_dist.charge_applicable_to_dist_id IS NOT NULL
	       AND tax_dist.detail_tax_dist_id IS NOT NULL
	       AND tax_dist.parent_reversal_id IS NULL
               AND NOT EXISTS ( SELECT 1
	                          FROM ap_invoice_distributions_all rev_tax_dist
			         WHERE rev_tax_dist.invoice_id         = p_invoice_id
			           AND rev_tax_dist.parent_reversal_id = tax_dist.invoice_distribution_id
			      )
	       AND ROWNUM = 1 ;
         ELSE
            SELECT COUNT(1)
              INTO l_unrev_dist_count
	      FROM ap_invoice_distributions_all tax_dist
	     WHERE tax_dist.invoice_id                    = p_invoice_id
               AND tax_dist.line_type_lookup_code        IN ('NONREC_TAX', 'REC_TAX', 'TIPV', 'TRV', 'TERV')
	       AND tax_dist.charge_applicable_to_dist_id IS NOT NULL
	       AND tax_dist.detail_tax_dist_id IS NOT NULL
	       AND tax_dist.parent_reversal_id IS NULL
               AND NOT EXISTS ( SELECT 1
	                          FROM ap_invoice_distributions_all rev_tax_dist
			         WHERE rev_tax_dist.invoice_id         = p_invoice_id
			           AND rev_tax_dist.parent_reversal_id = tax_dist.invoice_distribution_id
			      )
               AND tax_dist.charge_applicable_to_dist_id IN
	           ( SELECT item_dist.invoice_distribution_id
		       FROM ap_invoice_distributions_all item_dist
		      WHERE item_dist.invoice_id          = p_invoice_id
			AND item_dist.invoice_line_number = p_line_number
		   )
	       AND ROWNUM = 1 ;
         END IF ;

         -----------------------------------------------------------------
         IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'Unreversed tax distributions found');
         END IF;
         -----------------------------------------------------------------

	 IF l_unrev_dist_count > 0 THEN
            FND_MESSAGE.SET_NAME('SQLAP','AP_ERR_TAX_DIST_SYNC');
            APP_EXCEPTION.RAISE_EXCEPTION;
	 END IF ;
      END IF;
      -- Bug 10140793 End

    END IF; -- Marker 1


    IF l_self_assess_tax_dist_exist THEN -- Marker 2

       l_debug_info := 'Inserting self assessed tax entries into zx_reverse_dist_gt';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;

       -- Populating zx_reverse_dist_gt with self assessed entries that has to be
       -- reversed. Fetched tax distributions from ap_self_assessed_tax_dist_all.
       -- ITEM line is already reversed in Discard method. reverse_dist refers to
       -- the reversed item line.

       INSERT INTO zx_reverse_dist_gt(
        internal_organization_id,
        reversing_appln_id,
        reversing_entity_code,
        reversing_evnt_cls_code,
        reversing_trx_id,
        reversing_trx_level_type,
        reversing_trx_line_id,
        reversing_trx_line_dist_id,
        reversing_tax_line_id,
        reversed_appln_id,
        reversed_entity_code,
        reversed_evnt_cls_code,
        reversed_trx_id,
        reversed_trx_level_type,
        reversed_trx_line_id,
        reversed_trx_line_dist_id,
        reversed_tax_line_id
      )
      select	distinct
		item_dist.org_id                	internal_organization_id,
                zx_dist.application_id          	reversing_appln_id,
                zx_dist.entity_code             	reversing_entity_code,
                zx_dist.event_class_code        	reversing_evnt_cls_code,
                zx_dist.trx_id                  	reversing_trx_id,
                zx_dist.trx_level_type          	reversing_trx_level_type,
                zx_dist.trx_line_id             	reversing_trx_line_id,
                reverse_dist.invoice_distribution_id	reversing_trx_line_dist_id,
                zx_dist.tax_line_id             	reversing_tax_line_id,
                zx_dist.application_id          	reversed_appln_id,
                zx_dist.entity_code             	reversed_entity_code,
                zx_dist.event_class_code        	reversed_evnt_cls_code,
                zx_dist.trx_id                  	reversed_trx_id,
                zx_dist.trx_level_type          	reversed_trx_level_type,
                zx_dist.trx_line_id             	reversed_trx_line_id,
		zx_dist.trx_line_dist_id        	reversed_trx_line_dist_id,
                zx_dist.tax_line_id             	reversed_tax_line_id
        from    ap_invoice_distributions_all    item_dist,
                ap_self_assessed_tax_dist_all    tax_dist,
                ap_invoice_distributions_all    reverse_dist,
                zx_rec_nrec_dist                zx_dist
        where   tax_dist.invoice_id                     = p_invoice_id
        and     tax_dist.invoice_id                     = item_dist.invoice_id
        and     tax_dist.charge_applicable_to_dist_id   = item_dist.invoice_distribution_id
        and	item_dist.invoice_distribution_id	= reverse_dist.parent_reversal_id
        and     tax_dist.line_type_lookup_code          IN ('NONREC_TAX', 'REC_TAX')
        and     tax_dist.detail_tax_dist_id             = zx_dist.rec_nrec_tax_dist_id
        and     nvl(zx_dist.reverse_flag, 'N')          = 'N'
        and     (p_line_number IS NULL
                 or item_dist.invoice_line_number = p_line_number);

      -- Bug 10140793 l_reverse_dist_count := NVL(l_reverse_dist_count, 0) + SQL%ROWCOUNT;
      l_rev_sa_dist_count :=  SQL%ROWCOUNT ; -- Bug 10140793

      -----------------------------------------------------------------
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'Row Count inserted into zx_reverse_dist_gt: ' || SQL%ROWCOUNT);
      END IF;
      -----------------------------------------------------------------

      -- Bug 10140793 Begin
      IF l_rev_sa_dist_count = 0 THEN
         IF p_line_number IS NULL THEN
            SELECT COUNT(1)
              INTO l_unrev_sa_dist_count
	      FROM ap_self_assessed_tax_dist_all tax_dist
	     WHERE tax_dist.invoice_id                    = p_invoice_id
               AND tax_dist.line_type_lookup_code        IN ('NONREC_TAX', 'REC_TAX' )
	       AND tax_dist.charge_applicable_to_dist_id IS NOT NULL
	       AND tax_dist.detail_tax_dist_id IS NOT NULL
	       AND tax_dist.parent_reversal_id IS NULL
               AND NOT EXISTS ( SELECT 1
	                          FROM ap_self_assessed_tax_dist_all rev_tax_dist
			         WHERE rev_tax_dist.invoice_id         = p_invoice_id
			           AND rev_tax_dist.parent_reversal_id = tax_dist.invoice_distribution_id
			      )
	       AND ROWNUM = 1 ;
         ELSE
            SELECT COUNT(1)
              INTO l_unrev_sa_dist_count
	      FROM ap_self_assessed_tax_dist_all tax_dist
	     WHERE tax_dist.invoice_id                    = p_invoice_id
               AND tax_dist.line_type_lookup_code        IN ('NONREC_TAX', 'REC_TAX' )
	       AND tax_dist.charge_applicable_to_dist_id IS NOT NULL
	       AND tax_dist.detail_tax_dist_id IS NOT NULL
	       AND tax_dist.parent_reversal_id IS NULL
               AND NOT EXISTS ( SELECT 1
	                          FROM ap_self_assessed_tax_dist_all rev_tax_dist
			         WHERE rev_tax_dist.invoice_id         = p_invoice_id
			           AND rev_tax_dist.parent_reversal_id = tax_dist.invoice_distribution_id
			      )
               AND tax_dist.charge_applicable_to_dist_id IN
	           ( SELECT item_dist.invoice_distribution_id
		       FROM ap_invoice_distributions_all item_dist
		      WHERE item_dist.invoice_id          = p_invoice_id
			AND item_dist.invoice_line_number = p_line_number
		   )
	      AND ROWNUM = 1 ;
         END IF ;

         -----------------------------------------------------------------
         IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'Unreversed sa tax distributions exist');
         END IF;
         -----------------------------------------------------------------

	 IF l_unrev_sa_dist_count > 0 THEN
            FND_MESSAGE.SET_NAME('SQLAP','AP_ERR_TAX_DIST_SYNC');
            APP_EXCEPTION.RAISE_EXCEPTION;
	 END IF ;
      END IF;
      -- Bug 10140793 End

    END IF; -- Marker 2

--Bug8811102
--==============================================================================
    IF (AP_ETAX_UTILITY_PKG.Is_Tax_Already_Calc_Inv(
			P_Invoice_Id       => p_invoice_id,
			P_Calling_Sequence => l_curr_calling_sequence)) THEN
       l_tax_already_calculated := 'Y';
    ELSE
       l_tax_already_calculated := 'N';
    END IF;



    -----------------------------------------------------------------
    l_debug_info := 'Populate Header';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    ----------------------------------------------------------------
    IF NOT(AP_ETAX_SERVICES_PKG.Populate_Headers_GT(
	   P_Invoice_Header_Rec         => l_inv_header_rec,
	   P_Calling_Mode               => P_Calling_Mode,
	   P_eTax_Already_called_flag   => l_tax_already_calculated,
	   P_Event_Class_Code           => l_event_class_code,
	   P_Event_Type_Code            => l_event_type_code,
	   P_Error_Code                 => l_error_code,
	   P_Calling_Sequence           => l_curr_calling_sequence )) THEN
       l_return_status := FALSE;
    END IF;

    -----------------------------------------------------------------
    l_debug_info := 'Cache Line Defaults';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------

    IF l_inv_header_rec.invoice_type_lookup_code = 'PAYMENT REQUEST' THEN
        l_payment_request_flag :='Y';
	    Cache_Line_Defaults
	       ( p_org_id           => l_inv_header_rec.org_id
	        ,p_vendor_site_id   => l_inv_header_rec.party_site_id
	        ,p_calling_sequence => l_curr_calling_sequence);
    ELSE
        l_payment_request_flag :='N';
        Cache_Line_Defaults
	       ( p_org_id           => l_inv_header_rec.org_id
	        ,p_vendor_site_id   => l_inv_header_rec.vendor_site_id
            ,p_calling_sequence => l_curr_calling_sequence);
    END IF;


    -----------------------------------------------------------------
    l_debug_info := 'Populate TRX Lines';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
	IF (l_return_status = TRUE) THEN

     IF NOT(AP_ETAX_SERVICES_PKG.Populate_Lines_GT(
	    P_Invoice_Header_Rec      => l_inv_header_rec,
	    P_Calling_Mode            => P_Calling_Mode,
  	    P_Event_Class_Code        => l_event_class_code,
	    P_Line_Number             => p_line_number,
        P_Error_Code              => l_error_code,
	    P_Calling_Sequence        => l_curr_calling_sequence )) THEN
        l_return_status := FALSE;
	l_gt_error    := l_error_code;    /*Bug 16842904*/
     END IF;
    END IF;

    IF (l_return_status = TRUE)
        AND TAX_ONLY_LINE_EXIST(p_invoice_id)
        AND P_Line_Number IS NULL THEN

          BEGIN
             OPEN Invoice_Tax_OnlyLines;
            FETCH Invoice_Tax_OnlyLines
             BULK COLLECT INTO l_inv_tax_list;
            CLOSE Invoice_Tax_OnlyLines;
          END;
          IF NOT(AP_ETAX_SERVICES_PKG.Populate_Tax_Lines_GT(
			        P_Invoice_Header_Rec      => l_inv_header_rec,
			        P_Calling_Mode            => P_Calling_Mode,
			        P_Event_Class_Code        => l_event_class_code,
			        P_Tax_only_Flag           => 'Y',
			        P_Inv_Rcv_Matched         => l_Inv_Rcv_Matched,
			        P_Error_Code              => l_error_code,
			        P_Calling_Sequence        => l_curr_calling_sequence )) THEN

	                l_return_status := FALSE;
          END IF;
    END IF;


    ZX_NEW_SERVICES_PKG.CANCEL_TAX_LINES(
        p_api_version           => 1.0,
        p_init_msg_list         => FND_API.G_TRUE,
        p_commit                => FND_API.G_FALSE,
        p_validation_level      => FND_API.G_VALID_LEVEL_FULL,
        x_return_status         => l_return_status_service,
        x_msg_count             => l_msg_count,
        x_msg_data              => l_msg_data,
        p_transaction_rec       => l_transaction_rec,
        p_tax_only_line_flag    => l_tax_only_line_flag,
        p_trx_line_id           => l_line_number,
        p_trx_level_type        => l_trx_level_type,
        p_line_level_action     => l_line_level_action);


    IF (l_return_status_service <> 'S') THEN  -- handle errors --Marker 0
       l_return_status := FALSE;
       -----------------------------------------------------------------
       l_debug_info := 'Step 5.5: Handle errors returned by API';
	   -----------------------------------------------------------------
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, l_debug_info);
       END IF;

  	   IF NOT(AP_ETAX_UTILITY_PKG.Return_Error_Messages(
	          P_All_Error_Messages  => l_msg_data,
	          P_Msg_Count           => l_msg_count,
	          P_Msg_Data            => l_msg_data,
	          P_Error_Code          => l_Error_Code,
	          P_Calling_Sequence    => l_curr_calling_sequence)) THEN
	      NULL;
   	   END IF;
	    /*Start of Bug 16842904*/
            IF((l_Error_Code is NULL) AND (l_gt_error is not NULL)) THEN
	       l_Error_Code := l_gt_error;
	    END IF;
	    /*End of Bug 16842904*/
       DELETE zx_transaction_lines_gt;
       DELETE zx_import_tax_lines_gt;
       DELETE zx_trx_tax_link_gt;
       DELETE zx_reverse_dist_gt;
       RETURN l_return_status;
    ELSE -- update the tax only line amount to 0
       -----------------------------------------------------------------
       l_debug_info := 'Update the tax line amount to 0';
	   -----------------------------------------------------------------
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, l_debug_info);
       END IF;
       IF P_Line_Number IS NULL THEN

           UPDATE ap_invoice_lines_all a
              SET (amount,
                   base_amount,
                   cancelled_flag) =
                 (select  NVL(b.tax_amt,0),
                          NVL(b.tax_amt_funcl_curr,0),
                          b.cancel_flag
                    from zx_lines_summary b
                   where b.application_id 	 =  200
                     and b.entity_code 	     =  'AP_INVOICES'
                     and b.event_class_code IN ('STANDARD INVOICES', 'PREPAYMENT INVOICES', 'EXPENSE REPORTS')
                     and b.summary_tax_line_id = a.summary_tax_line_id
                     and b.trx_id            = p_invoice_id)
            WHERE a.invoice_id            =  p_invoice_id
              AND a.line_type_lookup_code = 'TAX'
              AND exists
                  (select 'Detail Line'
		             from zx_lines zx
		            where zx.application_id 	 =  200
                      and zx.entity_code 	     =  'AP_INVOICES'
		              and zx.event_class_code IN ('STANDARD INVOICES', 'PREPAYMENT INVOICES', 'EXPENSE REPORTS')
                      and zx.summary_tax_line_id = a.summary_tax_line_id
		              and zx.trx_id              = p_invoice_id);

           -------------------------------------------------------------------
           l_debug_info := 'Update Inclusive tax amount';
           -------------------------------------------------------------------
           IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
           END IF;

           BEGIN
             UPDATE ap_invoice_lines_all ail
                SET ail.included_tax_amount =
                   (SELECT /*+ index(ZL ZX_LINES_U1) */SUM(NVL(zl.tax_amt, 0))
                      FROM zx_lines zl
                     WHERE zl.application_id 	 =  200
                       AND zl.entity_code 	     =  'AP_INVOICES'
		               AND zl.event_class_code IN ('STANDARD INVOICES', 'PREPAYMENT INVOICES', 'EXPENSE REPORTS')
                       AND zl.trx_id 		= ail.invoice_id
                       AND zl.trx_line_id 	= ail.line_number
                       AND NVL(zl.self_assessed_flag,    'N') = 'N'
                       AND NVL(zl.reporting_only_flag,   'N') = 'N'
                       AND NVL(zl.tax_amt_included_flag, 'N') = 'Y')
              WHERE ail.invoice_id = P_Invoice_Id
                AND ail.line_type_lookup_code NOT IN ('TAX', 'AWT');
           EXCEPTION
           WHEN NO_DATA_FOUND THEN
             NULL;
           WHEN OTHERS THEN
             IF (SQLCODE <> -20001) THEN
                FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
                FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
                FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
                FND_MESSAGE.SET_TOKEN('PARAMETERS',
                ' P_Invoice_Id = '||P_Invoice_Id||
                ' P_Calling_Sequence = '||l_curr_calling_sequence);
                FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
             END IF;
             APP_EXCEPTION.RAISE_EXCEPTION;
           END;


           UPDATE ap_invoice_lines_all a
              SET amount = 0,
                  base_amount=0,
                  cancelled_flag='Y'
            WHERE a.invoice_id            = p_invoice_id
              AND a.line_type_lookup_code = 'TAX'
              AND a.summary_tax_line_id IS NULL;

           -----------------------------------------------------------------
           l_debug_info := 'Invoice Cancelled All Tax Lines Synched';
	       -----------------------------------------------------------------
           IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, l_debug_info);
           END IF;

       ELSIF p_line_number IS NOT NULL THEN

             --Bug16668914: Added discarded_flag and who columns
             UPDATE ap_invoice_lines_all a
                SET (amount,base_amount,discarded_flag) =
                    (select nvl(b.tax_amt,0),nvl(b.tax_amt_funcl_curr,0),b.cancel_flag
                       from zx_lines_summary b
                      where b.application_id 	    =  200
                        and b.entity_code 	    =  'AP_INVOICES'
		                and b.event_class_code IN ('STANDARD INVOICES', 'PREPAYMENT INVOICES', 'EXPENSE REPORTS')
                        and b.trx_id              = a.invoice_id
                        and b.summary_tax_line_id = a.summary_tax_line_id)
			,last_updated_by = l_user_id
                        ,last_update_login = l_login_id
                        ,last_update_date = sysdate
              WHERE a.invoice_id            = p_invoice_id
                AND a.line_type_lookup_code = 'TAX'
                AND exists
		            (select 'Detail Line'
		               from zx_lines zx
		              where zx.application_id 	   =  200
                        and zx.entity_code 	       =  'AP_INVOICES'
		                and zx.event_class_code IN ('STANDARD INVOICES', 'PREPAYMENT INVOICES', 'EXPENSE REPORTS')
                        and zx.summary_tax_line_id = a.summary_tax_line_id
		                and zx.trx_id              = p_invoice_id
		                and zx.trx_line_id         = p_line_number);

             -----------------------------------------------------------------
             l_debug_info := 'Invoice Line Discareded '||p_line_number;
	         -----------------------------------------------------------------
             IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, l_debug_info);
             END IF;
       END IF;

       UPDATE ap_invoices_all ai
          SET (ai.total_tax_amount,
               ai.self_assessed_tax_amount) =
              (SELECT SUM(DECODE(NVL(zls.self_assessed_flag, 'N'),
                          'N', NVL(zls.tax_amt, 0),0)),
                      SUM(DECODE(NVL(zls.self_assessed_flag, 'N'),
                          'Y', NVL(zls.tax_amt, 0),0))
                 FROM zx_lines_summary zls
                WHERE application_id   = AP_ETAX_PKG.AP_APPLICATION_ID
                  AND entity_code      = AP_ETAX_PKG.AP_ENTITY_CODE
                  AND event_class_code IN (AP_ETAX_PKG.AP_INV_EVENT_CLASS_CODE,
                                           AP_ETAX_PKG.AP_PP_EVENT_CLASS_CODE,
                                           AP_ETAX_PKG.AP_ER_EVENT_CLASS_CODE)
                  AND zls.trx_id       = ai.invoice_id
                  AND NVL(zls.reporting_only_flag, 'N') = 'N')
        WHERE ai.invoice_id = p_invoice_id;

      --Removed the if statement for the bug9749258

--==============================================================================
--Bug8811102

    IF l_return_status THEN

     IF p_line_number IS NULL THEN -- Marker 4

       delete zx_tax_dist_id_gt;  --Bug 8350132

       IF l_tax_distributions_exist THEN -- Marker 5

       -----------------------------------------------------------------
       l_debug_info := 'Step 3: Insert reverse tax distributions into ap_invoice_distributions';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
       ----------------------------------------------------------------

       OPEN c_reverse_tax_dist;
       LOOP
	   FETCH c_reverse_tax_dist
	   INTO  l_reverse_tax_dist;
	   EXIT WHEN c_reverse_tax_dist%NOTFOUND;

--bug 13101979 starts
	   IF (l_open_gl_date is null and l_open_gl_period is null) THEN

	      BEGIN
	        l_open_gl_period :=  AP_UTILITIES_PKG.get_current_gl_date_no_cache
		                     (l_reverse_tax_dist.accounting_date,l_reverse_tax_dist.org_id);

                   IF l_open_gl_period IS NULL THEN
		     BEGIN
			 select accounting_date,
			        period_name
			  into l_open_gl_date,
			       l_open_gl_period
			from ap_invoice_distributions_All aid
			    where rowid =
					 (select max(rowid)
					  from ap_invoice_distributions_All aid1
					  where aid1.invoice_id=l_reverse_tax_dist.invoice_id
					  and aid1.cancellation_flag = 'Y'
					  and aid1.detail_tax_dist_id is null
					  and aid1.prepay_distribution_id is null);
	             EXCEPTION
		        WHEN OTHERS THEN
			  l_open_gl_date := '' ;
			  l_open_gl_period := '' ;
		     END;

                     IF (l_open_gl_date IS NULL OR l_open_gl_period IS NULL) THEN
                        ap_utilities_pkg.get_open_gl_date_no_cache
		          (l_reverse_tax_dist.accounting_date,l_open_gl_period,l_open_gl_date);

		     END IF;
                   ELSE
		      l_open_gl_date := l_reverse_tax_dist.accounting_date;
                   END IF;
	     EXCEPTION
	       WHEN OTHERS THEN
                  l_open_gl_date := '' ;
	          l_open_gl_period := '' ;
	     END;
	  END IF;
--bug 13101979 ends

	   INSERT INTO ap_invoice_distributions_all (
            accounting_date,
            accrual_posted_flag,
            assets_addition_flag,
            assets_tracking_flag,
            cash_posted_flag,
            distribution_line_number,
            dist_code_combination_id,
            invoice_id,
            last_updated_by,
            last_update_date,
            line_type_lookup_code,
            period_name,
            set_of_books_id,
            amount,
            base_amount,
            --batch_id,
            created_by,
            creation_date,
            description,
            final_match_flag,
            income_tax_region,
            last_update_login,
            match_status_flag,
            posted_flag,
            po_distribution_id,
            program_application_id,
            program_id,
            program_update_date,
            quantity_invoiced,
            request_id,
            reversal_flag,
            type_1099,
            unit_price,
            encumbered_flag,
            stat_amount,
            attribute1,
            attribute10,
            attribute11,
            attribute12,
            attribute13,
            attribute14,
            attribute15,
            attribute2,
            attribute3,
            attribute4,
            attribute5,
            attribute6,
            attribute7,
            attribute8,
            attribute9,
            attribute_category,
            expenditure_item_date,
            expenditure_organization_id,
            expenditure_type,
            parent_invoice_id,
            pa_addition_flag,
            pa_quantity,
            prepay_amount_remaining,
            project_accounting_context,
            project_id,
            task_id,
            packet_id,
            awt_flag,
            awt_group_id,
            awt_tax_rate_id,
            awt_gross_amount,
            awt_invoice_id,
            awt_origin_group_id,
            reference_1,
            reference_2,
            org_id,
            awt_invoice_payment_id,
            global_attribute_category,
            global_attribute1,
            global_attribute2,
            global_attribute3,
            global_attribute4,
            global_attribute5,
            global_attribute6,
            global_attribute7,
            global_attribute8,
            global_attribute9,
            global_attribute10,
            global_attribute11,
            global_attribute12,
            global_attribute13,
            global_attribute14,
            global_attribute15,
            global_attribute16,
            global_attribute17,
            global_attribute18,
            global_attribute19,
            global_attribute20,
            receipt_verified_flag,
            receipt_required_flag,
            receipt_missing_flag,
            justification,
            expense_group,
            start_expense_date,
            end_expense_date,
            receipt_currency_code,
            receipt_conversion_rate,
            receipt_currency_amount,
            daily_amount,
            web_parameter_id,
            adjustment_reason,
            award_id,
            credit_card_trx_id,
            dist_match_type,
            rcv_transaction_id,
            invoice_distribution_id,
            parent_reversal_id,
            tax_recoverable_flag,
            merchant_document_number,
            merchant_name,
            merchant_reference,
            merchant_tax_reg_number,
            merchant_taxpayer_id,
            country_of_supply,
            matched_uom_lookup_code,
            gms_burdenable_raw_cost,
            accounting_event_id,
            prepay_distribution_id,
            upgrade_posted_amt,
            upgrade_base_posted_amt,
            inventory_transfer_status,
            company_prepaid_invoice_id,
            cc_reversal_flag,
            awt_withheld_amt,
            pa_cmt_xface_flag,
            cancellation_flag,
            invoice_line_number,
            corrected_invoice_dist_id,
            rounding_amt,
            charge_applicable_to_dist_id,
            corrected_quantity,
            related_id,
            asset_book_type_code,
            asset_category_id,
            distribution_class,
            tax_code_id,
            intended_use,
            detail_tax_dist_id,
            rec_nrec_rate,
            recovery_rate_id,
            recovery_type_code,
            withholding_tax_code_id,
            taxable_amount,
            taxable_base_amount,
            tax_already_distributed_flag,
            summary_tax_line_id,
	        rcv_charge_addition_flag,
            prepay_tax_diff_amount, -- BUG 7338249
            pay_awt_group_id) /*BUG 10261626*/
	VALUES
	(
	nvl(l_open_gl_date, l_reverse_tax_dist.accounting_date),  --bug 13101979
	l_reverse_tax_dist.accrual_posted_flag,
	l_reverse_tax_dist.assets_addition_flag,
	l_reverse_tax_dist.assets_tracking_flag,
	l_reverse_tax_dist.cash_posted_flag,
	l_reverse_tax_dist.distribution_line_number,
	l_reverse_tax_dist.dist_code_combination_id,
	l_reverse_tax_dist.invoice_id,
	l_reverse_tax_dist.last_updated_by,
	l_reverse_tax_dist.last_update_date,
	l_reverse_tax_dist.line_type_lookup_code,
	nvl(l_open_gl_period , l_reverse_tax_dist.period_name),  --bug 13101979
	l_reverse_tax_dist.set_of_books_id,
	l_reverse_tax_dist.amount,
	l_reverse_tax_dist.base_amount,
	--l_reverse_tax_dist.batch_id,
	l_reverse_tax_dist.created_by,
	l_reverse_tax_dist.creation_date,
	l_reverse_tax_dist.description,
	l_reverse_tax_dist.final_match_flag,
	l_reverse_tax_dist.income_tax_region,
	l_reverse_tax_dist.last_update_login,
	l_reverse_tax_dist.match_status_flag,
	l_reverse_tax_dist.posted_flag,
	l_reverse_tax_dist.po_distribution_id,
	l_reverse_tax_dist.program_application_id,
	l_reverse_tax_dist.program_id,
	l_reverse_tax_dist.program_update_date,
	l_reverse_tax_dist.quantity_invoiced,
	l_reverse_tax_dist.request_id,
	l_reverse_tax_dist.reversal_flag,
	l_reverse_tax_dist.type_1099,
	l_reverse_tax_dist.unit_price,
	l_reverse_tax_dist.encumbered_flag,
	l_reverse_tax_dist.stat_amount,
	l_reverse_tax_dist.attribute1,
	l_reverse_tax_dist.attribute10,
	l_reverse_tax_dist.attribute11,
	l_reverse_tax_dist.attribute12,
	l_reverse_tax_dist.attribute13,
	l_reverse_tax_dist.attribute14,
	l_reverse_tax_dist.attribute15,
	l_reverse_tax_dist.attribute2,
	l_reverse_tax_dist.attribute3,
	l_reverse_tax_dist.attribute4,
	l_reverse_tax_dist.attribute5,
	l_reverse_tax_dist.attribute6,
	l_reverse_tax_dist.attribute7,
	l_reverse_tax_dist.attribute8,
	l_reverse_tax_dist.attribute9,
	l_reverse_tax_dist.attribute_category,
	l_reverse_tax_dist.expenditure_item_date,
	l_reverse_tax_dist.expenditure_organization_id,
	l_reverse_tax_dist.expenditure_type,
	l_reverse_tax_dist.parent_invoice_id,
	l_reverse_tax_dist.pa_addition_flag,
	l_reverse_tax_dist.pa_quantity,
	l_reverse_tax_dist.prepay_amount_remaining,
	l_reverse_tax_dist.project_accounting_context,
	l_reverse_tax_dist.project_id,
	l_reverse_tax_dist.task_id,
	l_reverse_tax_dist.packet_id,
	l_reverse_tax_dist.awt_flag,
	l_reverse_tax_dist.awt_group_id,
	l_reverse_tax_dist.awt_tax_rate_id,
	l_reverse_tax_dist.awt_gross_amount,
	l_reverse_tax_dist.awt_invoice_id,
	l_reverse_tax_dist.awt_origin_group_id,
	l_reverse_tax_dist.reference_1,
	l_reverse_tax_dist.reference_2,
	l_reverse_tax_dist.org_id,
	l_reverse_tax_dist.awt_invoice_payment_id,
	l_reverse_tax_dist.global_attribute_category,
	l_reverse_tax_dist.global_attribute1,
	l_reverse_tax_dist.global_attribute2,
	l_reverse_tax_dist.global_attribute3,
	l_reverse_tax_dist.global_attribute4,
	l_reverse_tax_dist.global_attribute5,
	l_reverse_tax_dist.global_attribute6,
	l_reverse_tax_dist.global_attribute7,
	l_reverse_tax_dist.global_attribute8,
	l_reverse_tax_dist.global_attribute9,
	l_reverse_tax_dist.global_attribute10,
	l_reverse_tax_dist.global_attribute11,
	l_reverse_tax_dist.global_attribute12,
	l_reverse_tax_dist.global_attribute13,
	l_reverse_tax_dist.global_attribute14,
	l_reverse_tax_dist.global_attribute15,
	l_reverse_tax_dist.global_attribute16,
	l_reverse_tax_dist.global_attribute17,
	l_reverse_tax_dist.global_attribute18,
	l_reverse_tax_dist.global_attribute19,
	l_reverse_tax_dist.global_attribute20,
	l_reverse_tax_dist.receipt_verified_flag,
	l_reverse_tax_dist.receipt_required_flag,
	l_reverse_tax_dist.receipt_missing_flag,
	l_reverse_tax_dist.justification,
	l_reverse_tax_dist.expense_group,
	l_reverse_tax_dist.start_expense_date,
	l_reverse_tax_dist.end_expense_date,
	l_reverse_tax_dist.receipt_currency_code,
	l_reverse_tax_dist.receipt_conversion_rate,
	l_reverse_tax_dist.receipt_currency_amount,
	l_reverse_tax_dist.daily_amount,
	l_reverse_tax_dist.web_parameter_id,
	l_reverse_tax_dist.adjustment_reason,
	l_reverse_tax_dist.award_id,
	l_reverse_tax_dist.credit_card_trx_id,
	l_reverse_tax_dist.dist_match_type,
	l_reverse_tax_dist.rcv_transaction_id,
	l_reverse_tax_dist.invoice_distribution_id,
	l_reverse_tax_dist.parent_reversal_id,
	l_reverse_tax_dist.tax_recoverable_flag,
	l_reverse_tax_dist.merchant_document_number,
	l_reverse_tax_dist.merchant_name,
	l_reverse_tax_dist.merchant_reference,
	l_reverse_tax_dist.merchant_tax_reg_number,
	l_reverse_tax_dist.merchant_taxpayer_id,
	l_reverse_tax_dist.country_of_supply,
	l_reverse_tax_dist.matched_uom_lookup_code,
	l_reverse_tax_dist.gms_burdenable_raw_cost,
	l_reverse_tax_dist.accounting_event_id,
	l_reverse_tax_dist.prepay_distribution_id,
	l_reverse_tax_dist.upgrade_posted_amt,
	l_reverse_tax_dist.upgrade_base_posted_amt,
	l_reverse_tax_dist.inventory_transfer_status,
	l_reverse_tax_dist.company_prepaid_invoice_id,
	l_reverse_tax_dist.cc_reversal_flag,
	l_reverse_tax_dist.awt_withheld_amt,
	l_reverse_tax_dist.pa_cmt_xface_flag,
	l_reverse_tax_dist.cancellation_flag,
	l_reverse_tax_dist.invoice_line_number,
	l_reverse_tax_dist.corrected_invoice_dist_id,
	l_reverse_tax_dist.rounding_amt,
	l_reverse_tax_dist.charge_applicable_to_dist_id,
	l_reverse_tax_dist.corrected_quantity,
	l_reverse_tax_dist.related_id,
	l_reverse_tax_dist.asset_book_type_code,
	l_reverse_tax_dist.asset_category_id,
	l_reverse_tax_dist.distribution_class,
	l_reverse_tax_dist.tax_code_id,
	l_reverse_tax_dist.intended_use,
	l_reverse_tax_dist.detail_tax_dist_id,
	l_reverse_tax_dist.rec_nrec_rate,
	l_reverse_tax_dist.recovery_rate_id,
	l_reverse_tax_dist.recovery_type_code,
	l_reverse_tax_dist.withholding_tax_code_id,
	l_reverse_tax_dist.taxable_amount,
	l_reverse_tax_dist.taxable_base_amount,
	l_reverse_tax_dist.tax_already_distributed_flag,
	l_reverse_tax_dist.summary_tax_line_id,
	l_reverse_tax_dist.rcv_charge_addition_flag,
	l_reverse_tax_dist.prepay_tax_diff_amount, -- BUG 7338249
    l_reverse_tax_dist.pay_awt_group_id); /*BUG 10261626*/

        --Bug 8350132

	INSERT into ZX_TAX_DIST_ID_GT (TAX_DIST_ID) values (l_reverse_tax_dist.detail_tax_dist_id) ;
	l_inv_cancel_date := l_reverse_tax_dist.accounting_date ;

        --End Bug 8350132

     END LOOP;

     l_rev_dist_cursor_count := c_reverse_tax_dist%ROWCOUNT  ;  -- Bug 10140793

     CLOSE c_reverse_tax_dist;

     -- Bug 10140793 Begin
     -----------------------------------------------------------------
     IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, '(1) l_rev_dist_cursor_count: ' || l_rev_dist_cursor_count);
     END IF;
     -----------------------------------------------------------------

     IF ( l_reverse_dist_count <> 0 AND l_rev_dist_cursor_count = 0 ) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_ERR_TAX_DIST_SYNC');
        APP_EXCEPTION.RAISE_EXCEPTION;
     END IF ;
     -- Bug 10140793  End

     END IF; -- Marker 5


     IF l_self_assess_tax_dist_exist THEN -- Marker 6

        -----------------------------------------------------------------
        l_debug_info := 'Step 3: Insert reverse self assessed tax distributions into ap_invoice_distributions';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        ----------------------------------------------------------------

        OPEN c_rev_self_assess_tax_dist;
        LOOP
	    FETCH c_rev_self_assess_tax_dist
	     INTO  l_self_assess_rev_tax_dist;
	     EXIT WHEN c_rev_self_assess_tax_dist%NOTFOUND;

--bug 13101979 starts

          IF (l_open_gl_date is null and l_open_gl_period is null) THEN

	     BEGIN
	        l_open_gl_period :=  AP_UTILITIES_PKG.get_current_gl_date_no_cache
		                     (l_self_assess_rev_tax_dist.accounting_date,l_self_assess_rev_tax_dist.org_id);

                   IF l_open_gl_period IS NULL THEN
		     BEGIN
			 select accounting_date,
			        period_name
			  into l_open_gl_date,
			       l_open_gl_period
			from ap_invoice_distributions_All aid
			    where rowid =
					 (select max(rowid)
					  from ap_invoice_distributions_All aid1
					  where aid1.invoice_id=l_self_assess_rev_tax_dist.invoice_id
					  and aid1.cancellation_flag = 'Y'
					  and aid1.detail_tax_dist_id is null
					  and aid1.prepay_distribution_id is null);
	             EXCEPTION
		        WHEN OTHERS THEN
			  l_open_gl_date := '';
			  l_open_gl_period := '';
		     END;

                       IF (l_open_gl_date IS NULL OR l_open_gl_period IS NULL) THEN
                           ap_utilities_pkg.get_open_gl_date_no_cache
		             (l_self_assess_rev_tax_dist.accounting_date,l_open_gl_period,l_open_gl_date);

		       END IF;
	           ELSE
		      l_open_gl_date := l_self_assess_rev_tax_dist.accounting_date;
                   END IF;
	     EXCEPTION
	       WHEN OTHERS THEN
                  l_open_gl_date := '';
	          l_open_gl_period := '';
	     END;
	  END IF;
--bug 13101979 ends

	   INSERT INTO ap_self_assessed_tax_dist_all (
                accounting_date,
                accrual_posted_flag,
                assets_addition_flag,
                assets_tracking_flag,
                cash_posted_flag,
                distribution_line_number,
                dist_code_combination_id,
                invoice_id,
                last_updated_by,
                last_update_date,
                line_type_lookup_code,
                period_name,
                set_of_books_id,
                amount,
                base_amount,
                --batch_id,
                created_by,
                creation_date,
                description,
                final_match_flag,
                income_tax_region,
                last_update_login,
                match_status_flag,
                posted_flag,
                po_distribution_id,
                program_application_id,
                program_id,
                program_update_date,
                quantity_invoiced,
                request_id,
                reversal_flag,
                type_1099,
                unit_price,
                encumbered_flag,
                stat_amount,
                attribute1,
                attribute10,
                attribute11,
                attribute12,
                attribute13,
                attribute14,
                attribute15,
                attribute2,
                attribute3,
                attribute4,
                attribute5,
                attribute6,
                attribute7,
                attribute8,
                attribute9,
                attribute_category,
                expenditure_item_date,
                expenditure_organization_id,
                expenditure_type,
                parent_invoice_id,
                pa_addition_flag,
                pa_quantity,
                prepay_amount_remaining,
                project_accounting_context,
                project_id,
                task_id,
                packet_id,
                awt_flag,
                awt_group_id,
                awt_tax_rate_id,
                awt_gross_amount,
                awt_invoice_id,
                awt_origin_group_id,
                reference_1,
                reference_2,
                org_id,
                awt_invoice_payment_id,
                global_attribute_category,
                global_attribute1,
                global_attribute2,
                global_attribute3,
                global_attribute4,
                global_attribute5,
                global_attribute6,
                global_attribute7,
                global_attribute8,
                global_attribute9,
                global_attribute10,
                global_attribute11,
                global_attribute12,
                global_attribute13,
                global_attribute14,
                global_attribute15,
                global_attribute16,
                global_attribute17,
                global_attribute18,
                global_attribute19,
                global_attribute20,
                receipt_verified_flag,
                receipt_required_flag,
                receipt_missing_flag,
                justification,
                expense_group,
                start_expense_date,
                end_expense_date,
                receipt_currency_code,
                receipt_conversion_rate,
                receipt_currency_amount,
                daily_amount,
                web_parameter_id,
                adjustment_reason,
                award_id,
                credit_card_trx_id,
                dist_match_type,
                rcv_transaction_id,
                invoice_distribution_id,
                parent_reversal_id,
                tax_recoverable_flag,
                merchant_document_number,
                merchant_name,
                merchant_reference,
                merchant_tax_reg_number,
                merchant_taxpayer_id,
                country_of_supply,
                matched_uom_lookup_code,
                gms_burdenable_raw_cost,
                accounting_event_id,
                prepay_distribution_id,
                upgrade_posted_amt,
                upgrade_base_posted_amt,
                inventory_transfer_status,
                company_prepaid_invoice_id,
                cc_reversal_flag,
                awt_withheld_amt,
                pa_cmt_xface_flag,
                cancellation_flag,
                invoice_line_number,
                corrected_invoice_dist_id,
                rounding_amt,
                charge_applicable_to_dist_id,
                corrected_quantity,
                related_id,
                asset_book_type_code,
                asset_category_id,
                distribution_class,
                tax_code_id,
                intended_use,
                detail_tax_dist_id,
                rec_nrec_rate,
                recovery_rate_id,
                recovery_type_code,
                withholding_tax_code_id,
                taxable_amount,
                taxable_base_amount,
                tax_already_distributed_flag,
                summary_tax_line_id,
		        rcv_charge_addition_flag,
                self_assessed_flag,
                self_assessed_tax_liab_ccid, --bug6805655
                prepay_tax_diff_amount -- BUG 7338249
                )
		VALUES
		(
		nvl(l_open_gl_date,l_self_assess_rev_tax_dist.accounting_date), --bug 13101979
		l_self_assess_rev_tax_dist.accrual_posted_flag,
		l_self_assess_rev_tax_dist.assets_addition_flag,
		l_self_assess_rev_tax_dist.assets_tracking_flag,
		l_self_assess_rev_tax_dist.cash_posted_flag,
		l_self_assess_rev_tax_dist.distribution_line_number,
		l_self_assess_rev_tax_dist.dist_code_combination_id,
		l_self_assess_rev_tax_dist.invoice_id,
		l_self_assess_rev_tax_dist.last_updated_by,
		l_self_assess_rev_tax_dist.last_update_date,
		l_self_assess_rev_tax_dist.line_type_lookup_code,
		nvl(l_open_gl_period,l_self_assess_rev_tax_dist.period_name), --bug 13101979
		l_self_assess_rev_tax_dist.set_of_books_id,
		l_self_assess_rev_tax_dist.amount,
		l_self_assess_rev_tax_dist.base_amount,
		--l_self_assess_rev_tax_dist.batch_id,
		l_self_assess_rev_tax_dist.created_by,
		l_self_assess_rev_tax_dist.creation_date,
		l_self_assess_rev_tax_dist.description,
		l_self_assess_rev_tax_dist.final_match_flag,
		l_self_assess_rev_tax_dist.income_tax_region,
		l_self_assess_rev_tax_dist.last_update_login,
		l_self_assess_rev_tax_dist.match_status_flag,
		l_self_assess_rev_tax_dist.posted_flag,
		l_self_assess_rev_tax_dist.po_distribution_id,
		l_self_assess_rev_tax_dist.program_application_id,
		l_self_assess_rev_tax_dist.program_id,
		l_self_assess_rev_tax_dist.program_update_date,
		l_self_assess_rev_tax_dist.quantity_invoiced,
		l_self_assess_rev_tax_dist.request_id,
		l_self_assess_rev_tax_dist.reversal_flag,
		l_self_assess_rev_tax_dist.type_1099,
		l_self_assess_rev_tax_dist.unit_price,
		l_self_assess_rev_tax_dist.encumbered_flag,
		l_self_assess_rev_tax_dist.stat_amount,
		l_self_assess_rev_tax_dist.attribute1,
		l_self_assess_rev_tax_dist.attribute10,
		l_self_assess_rev_tax_dist.attribute11,
		l_self_assess_rev_tax_dist.attribute12,
		l_self_assess_rev_tax_dist.attribute13,
		l_self_assess_rev_tax_dist.attribute14,
		l_self_assess_rev_tax_dist.attribute15,
		l_self_assess_rev_tax_dist.attribute2,
		l_self_assess_rev_tax_dist.attribute3,
		l_self_assess_rev_tax_dist.attribute4,
		l_self_assess_rev_tax_dist.attribute5,
		l_self_assess_rev_tax_dist.attribute6,
		l_self_assess_rev_tax_dist.attribute7,
		l_self_assess_rev_tax_dist.attribute8,
		l_self_assess_rev_tax_dist.attribute9,
		l_self_assess_rev_tax_dist.attribute_category,
		l_self_assess_rev_tax_dist.expenditure_item_date,
		l_self_assess_rev_tax_dist.expenditure_organization_id,
		l_self_assess_rev_tax_dist.expenditure_type,
		l_self_assess_rev_tax_dist.parent_invoice_id,
		l_self_assess_rev_tax_dist.pa_addition_flag,
		l_self_assess_rev_tax_dist.pa_quantity,
		l_self_assess_rev_tax_dist.prepay_amount_remaining,
		l_self_assess_rev_tax_dist.project_accounting_context,
		l_self_assess_rev_tax_dist.project_id,
		l_self_assess_rev_tax_dist.task_id,
		l_self_assess_rev_tax_dist.packet_id,
		l_self_assess_rev_tax_dist.awt_flag,
		l_self_assess_rev_tax_dist.awt_group_id,
		l_self_assess_rev_tax_dist.awt_tax_rate_id,
		l_self_assess_rev_tax_dist.awt_gross_amount,
		l_self_assess_rev_tax_dist.awt_invoice_id,
		l_self_assess_rev_tax_dist.awt_origin_group_id,
		l_self_assess_rev_tax_dist.reference_1,
		l_self_assess_rev_tax_dist.reference_2,
		l_self_assess_rev_tax_dist.org_id,
		l_self_assess_rev_tax_dist.awt_invoice_payment_id,
		l_self_assess_rev_tax_dist.global_attribute_category,
		l_self_assess_rev_tax_dist.global_attribute1,
		l_self_assess_rev_tax_dist.global_attribute2,
		l_self_assess_rev_tax_dist.global_attribute3,
		l_self_assess_rev_tax_dist.global_attribute4,
		l_self_assess_rev_tax_dist.global_attribute5,
		l_self_assess_rev_tax_dist.global_attribute6,
		l_self_assess_rev_tax_dist.global_attribute7,
		l_self_assess_rev_tax_dist.global_attribute8,
		l_self_assess_rev_tax_dist.global_attribute9,
		l_self_assess_rev_tax_dist.global_attribute10,
		l_self_assess_rev_tax_dist.global_attribute11,
		l_self_assess_rev_tax_dist.global_attribute12,
		l_self_assess_rev_tax_dist.global_attribute13,
		l_self_assess_rev_tax_dist.global_attribute14,
		l_self_assess_rev_tax_dist.global_attribute15,
		l_self_assess_rev_tax_dist.global_attribute16,
		l_self_assess_rev_tax_dist.global_attribute17,
		l_self_assess_rev_tax_dist.global_attribute18,
		l_self_assess_rev_tax_dist.global_attribute19,
		l_self_assess_rev_tax_dist.global_attribute20,
		l_self_assess_rev_tax_dist.receipt_verified_flag,
		l_self_assess_rev_tax_dist.receipt_required_flag,
		l_self_assess_rev_tax_dist.receipt_missing_flag,
		l_self_assess_rev_tax_dist.justification,
		l_self_assess_rev_tax_dist.expense_group,
		l_self_assess_rev_tax_dist.start_expense_date,
		l_self_assess_rev_tax_dist.end_expense_date,
		l_self_assess_rev_tax_dist.receipt_currency_code,
		l_self_assess_rev_tax_dist.receipt_conversion_rate,
		l_self_assess_rev_tax_dist.receipt_currency_amount,
		l_self_assess_rev_tax_dist.daily_amount,
		l_self_assess_rev_tax_dist.web_parameter_id,
		l_self_assess_rev_tax_dist.adjustment_reason,
		l_self_assess_rev_tax_dist.award_id,
		l_self_assess_rev_tax_dist.credit_card_trx_id,
		l_self_assess_rev_tax_dist.dist_match_type,
		l_self_assess_rev_tax_dist.rcv_transaction_id,
		l_self_assess_rev_tax_dist.invoice_distribution_id,
		l_self_assess_rev_tax_dist.parent_reversal_id,
		l_self_assess_rev_tax_dist.tax_recoverable_flag,
		l_self_assess_rev_tax_dist.merchant_document_number,
		l_self_assess_rev_tax_dist.merchant_name,
		l_self_assess_rev_tax_dist.merchant_reference,
		l_self_assess_rev_tax_dist.merchant_tax_reg_number,
		l_self_assess_rev_tax_dist.merchant_taxpayer_id,
		l_self_assess_rev_tax_dist.country_of_supply,
		l_self_assess_rev_tax_dist.matched_uom_lookup_code,
		l_self_assess_rev_tax_dist.gms_burdenable_raw_cost,
		l_self_assess_rev_tax_dist.accounting_event_id,
		l_self_assess_rev_tax_dist.prepay_distribution_id,
		l_self_assess_rev_tax_dist.upgrade_posted_amt,
		l_self_assess_rev_tax_dist.upgrade_base_posted_amt,
		l_self_assess_rev_tax_dist.inventory_transfer_status,
		l_self_assess_rev_tax_dist.company_prepaid_invoice_id,
		l_self_assess_rev_tax_dist.cc_reversal_flag,
		l_self_assess_rev_tax_dist.awt_withheld_amt,
		l_self_assess_rev_tax_dist.pa_cmt_xface_flag,
		l_self_assess_rev_tax_dist.cancellation_flag,
		l_self_assess_rev_tax_dist.invoice_line_number,
		l_self_assess_rev_tax_dist.corrected_invoice_dist_id,
		l_self_assess_rev_tax_dist.rounding_amt,
		l_self_assess_rev_tax_dist.charge_applicable_to_dist_id,
		l_self_assess_rev_tax_dist.corrected_quantity,
		l_self_assess_rev_tax_dist.related_id,
		l_self_assess_rev_tax_dist.asset_book_type_code,
		l_self_assess_rev_tax_dist.asset_category_id,
		l_self_assess_rev_tax_dist.distribution_class,
		l_self_assess_rev_tax_dist.tax_code_id,
		l_self_assess_rev_tax_dist.intended_use,
		l_self_assess_rev_tax_dist.detail_tax_dist_id,
		l_self_assess_rev_tax_dist.rec_nrec_rate,
		l_self_assess_rev_tax_dist.recovery_rate_id,
		l_self_assess_rev_tax_dist.recovery_type_code,
		l_self_assess_rev_tax_dist.withholding_tax_code_id,
		l_self_assess_rev_tax_dist.taxable_amount,
		l_self_assess_rev_tax_dist.taxable_base_amount,
		l_self_assess_rev_tax_dist.tax_already_distributed_flag,
		l_self_assess_rev_tax_dist.summary_tax_line_id,
		l_self_assess_rev_tax_dist.rcv_charge_addition_flag,
		l_self_assess_rev_tax_dist.self_assessed_flag,
		l_self_assess_rev_tax_dist.self_assessed_tax_liab_ccid,  --bug6805655
        l_self_assess_rev_tax_dist.prepay_tax_diff_amount -- BUG 7338249
               );

        --Bug 8350132

	INSERT into ZX_TAX_DIST_ID_GT (TAX_DIST_ID) values (l_self_assess_rev_tax_dist.detail_tax_dist_id) ;
        l_inv_cancel_date := l_self_assess_rev_tax_dist.accounting_date ;

        --End Bug 8350132

         END LOOP;

         l_rev_sa_dist_cursor_count := c_rev_self_assess_tax_dist%ROWCOUNT  ;  -- Bug 10140793

         CLOSE c_rev_self_assess_tax_dist;

         -- Bug 10140793 Begin
         -----------------------------------------------------------------
         IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, '(1) l_rev_sa_dist_cursor_count: ' || l_rev_sa_dist_cursor_count);
         END IF;
         -----------------------------------------------------------------

         IF ( l_rev_sa_dist_count <> 0 AND l_rev_sa_dist_cursor_count = 0 ) THEN
            FND_MESSAGE.SET_NAME('SQLAP','AP_ERR_TAX_DIST_SYNC');
            APP_EXCEPTION.RAISE_EXCEPTION;
         END IF ;
         -- Bug 10140793  End

	 END IF; -- Marker 6

        --Bug 8350132
        --bug 13101979 moved the API to the end of if block so that for all it wil update once hence removing redundancy
       /* ZX_API_PUB.Update_Tax_dist_gl_date (
				1.0,
				FND_API.G_TRUE,
				FND_API.G_FALSE,
				FND_API.G_VALID_LEVEL_FULL,
				l_return_status_service,
				l_msg_count,
				l_msg_data,
				l_inv_cancel_date );


        IF (l_return_status_service <> FND_API.G_RET_STS_SUCCESS) THEN  -- handle errors

             l_return_status := FALSE;

             -----------------------------------------------------------------
             l_debug_info := 'Step 2.5: Handle errors returned by API';
             -----------------------------------------------------------------
             IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, l_debug_info);
             END IF;

             IF NOT(AP_ETAX_UTILITY_PKG.Return_Error_Messages(
                   P_All_Error_Messages  => 'N',
                   P_Msg_Count           => l_msg_count,
                   P_Msg_Data            => l_msg_data,
                   P_Error_Code          => l_Error_Code,
                   P_Calling_Sequence    => l_curr_calling_sequence)) THEN
               NULL;
             END IF;

             RETURN l_return_status;
         END IF; */

       --End Bug 8350132

    else -- Marker 4

         IF l_tax_distributions_exist THEN -- Marker 7

         l_debug_info := 'Inserting reverse entries into ap_invoice_distributions_all after line discard';
         IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
         END IF;

         OPEN c_reverse_tax_dist_1;
         LOOP
	     FETCH c_reverse_tax_dist_1
	     INTO  l_reverse_tax_dist;
	     EXIT WHEN c_reverse_tax_dist_1%NOTFOUND;

	     INSERT INTO ap_invoice_distributions_all (
            accounting_date,
            accrual_posted_flag,
            assets_addition_flag,
            assets_tracking_flag,
            cash_posted_flag,
            distribution_line_number,
            dist_code_combination_id,
            invoice_id,
            last_updated_by,
            last_update_date,
            line_type_lookup_code,
            period_name,
            set_of_books_id,
            amount,
            base_amount,
            --batch_id,
            created_by,
            creation_date,
            description,
            final_match_flag,
            income_tax_region,
            last_update_login,
            match_status_flag,
            posted_flag,
            po_distribution_id,
            program_application_id,
            program_id,
            program_update_date,
            quantity_invoiced,
            request_id,
            reversal_flag,
            type_1099,
            unit_price,
            encumbered_flag,
            stat_amount,
            attribute1,
            attribute10,
            attribute11,
            attribute12,
            attribute13,
            attribute14,
            attribute15,
            attribute2,
            attribute3,
            attribute4,
            attribute5,
            attribute6,
            attribute7,
            attribute8,
            attribute9,
            attribute_category,
            expenditure_item_date,
            expenditure_organization_id,
            expenditure_type,
            parent_invoice_id,
            pa_addition_flag,
            pa_quantity,
            prepay_amount_remaining,
            project_accounting_context,
            project_id,
            task_id,
            packet_id,
            awt_flag,
            awt_group_id,
            awt_tax_rate_id,
            awt_gross_amount,
            awt_invoice_id,
            awt_origin_group_id,
            reference_1,
            reference_2,
            org_id,
            awt_invoice_payment_id,
            global_attribute_category,
            global_attribute1,
            global_attribute2,
            global_attribute3,
            global_attribute4,
            global_attribute5,
            global_attribute6,
            global_attribute7,
            global_attribute8,
            global_attribute9,
            global_attribute10,
            global_attribute11,
            global_attribute12,
            global_attribute13,
            global_attribute14,
            global_attribute15,
            global_attribute16,
            global_attribute17,
            global_attribute18,
            global_attribute19,
            global_attribute20,
            receipt_verified_flag,
            receipt_required_flag,
            receipt_missing_flag,
            justification,
            expense_group,
            start_expense_date,
            end_expense_date,
            receipt_currency_code,
            receipt_conversion_rate,
            receipt_currency_amount,
            daily_amount,
            web_parameter_id,
            adjustment_reason,
            award_id,
            credit_card_trx_id,
            dist_match_type,
            rcv_transaction_id,
            invoice_distribution_id,
            parent_reversal_id,
            tax_recoverable_flag,
            merchant_document_number,
            merchant_name,
            merchant_reference,
            merchant_tax_reg_number,
            merchant_taxpayer_id,
            country_of_supply,
            matched_uom_lookup_code,
            gms_burdenable_raw_cost,
            accounting_event_id,
            prepay_distribution_id,
            upgrade_posted_amt,
            upgrade_base_posted_amt,
            inventory_transfer_status,
            company_prepaid_invoice_id,
            cc_reversal_flag,
            awt_withheld_amt,
            pa_cmt_xface_flag,
            cancellation_flag,
            invoice_line_number,
            corrected_invoice_dist_id,
            rounding_amt,
            charge_applicable_to_dist_id,
            corrected_quantity,
            related_id,
            asset_book_type_code,
            asset_category_id,
            distribution_class,
            tax_code_id,
            intended_use,
            detail_tax_dist_id,
            rec_nrec_rate,
            recovery_rate_id,
            recovery_type_code,
            withholding_tax_code_id,
            taxable_amount,
            taxable_base_amount,
            tax_already_distributed_flag,
            summary_tax_line_id,
	        rcv_charge_addition_flag,
            prepay_tax_diff_amount, -- BUG 7338249
            pay_awt_group_id) /*BUG 10261626*/
	VALUES
	(
	l_reverse_tax_dist.accounting_date,
	l_reverse_tax_dist.accrual_posted_flag,
	l_reverse_tax_dist.assets_addition_flag,
	l_reverse_tax_dist.assets_tracking_flag,
	l_reverse_tax_dist.cash_posted_flag,
	l_reverse_tax_dist.distribution_line_number,
	l_reverse_tax_dist.dist_code_combination_id,
	l_reverse_tax_dist.invoice_id,
	l_reverse_tax_dist.last_updated_by,
	l_reverse_tax_dist.last_update_date,
	l_reverse_tax_dist.line_type_lookup_code,
	l_reverse_tax_dist.period_name,
	l_reverse_tax_dist.set_of_books_id,
	l_reverse_tax_dist.amount,
	l_reverse_tax_dist.base_amount,
	--l_reverse_tax_dist.batch_id,
	l_reverse_tax_dist.created_by,
	l_reverse_tax_dist.creation_date,
	l_reverse_tax_dist.description,
	l_reverse_tax_dist.final_match_flag,
	l_reverse_tax_dist.income_tax_region,
	l_reverse_tax_dist.last_update_login,
	l_reverse_tax_dist.match_status_flag,
	l_reverse_tax_dist.posted_flag,
	l_reverse_tax_dist.po_distribution_id,
	l_reverse_tax_dist.program_application_id,
	l_reverse_tax_dist.program_id,
	l_reverse_tax_dist.program_update_date,
	l_reverse_tax_dist.quantity_invoiced,
	l_reverse_tax_dist.request_id,
	l_reverse_tax_dist.reversal_flag,
	l_reverse_tax_dist.type_1099,
	l_reverse_tax_dist.unit_price,
	l_reverse_tax_dist.encumbered_flag,
	l_reverse_tax_dist.stat_amount,
	l_reverse_tax_dist.attribute1,
	l_reverse_tax_dist.attribute10,
	l_reverse_tax_dist.attribute11,
	l_reverse_tax_dist.attribute12,
	l_reverse_tax_dist.attribute13,
	l_reverse_tax_dist.attribute14,
	l_reverse_tax_dist.attribute15,
	l_reverse_tax_dist.attribute2,
	l_reverse_tax_dist.attribute3,
	l_reverse_tax_dist.attribute4,
	l_reverse_tax_dist.attribute5,
	l_reverse_tax_dist.attribute6,
	l_reverse_tax_dist.attribute7,
	l_reverse_tax_dist.attribute8,
	l_reverse_tax_dist.attribute9,
	l_reverse_tax_dist.attribute_category,
	l_reverse_tax_dist.expenditure_item_date,
	l_reverse_tax_dist.expenditure_organization_id,
	l_reverse_tax_dist.expenditure_type,
	l_reverse_tax_dist.parent_invoice_id,
	l_reverse_tax_dist.pa_addition_flag,
	l_reverse_tax_dist.pa_quantity,
	l_reverse_tax_dist.prepay_amount_remaining,
	l_reverse_tax_dist.project_accounting_context,
	l_reverse_tax_dist.project_id,
	l_reverse_tax_dist.task_id,
	l_reverse_tax_dist.packet_id,
	l_reverse_tax_dist.awt_flag,
	l_reverse_tax_dist.awt_group_id,
	l_reverse_tax_dist.awt_tax_rate_id,
	l_reverse_tax_dist.awt_gross_amount,
	l_reverse_tax_dist.awt_invoice_id,
	l_reverse_tax_dist.awt_origin_group_id,
	l_reverse_tax_dist.reference_1,
	l_reverse_tax_dist.reference_2,
	l_reverse_tax_dist.org_id,
	l_reverse_tax_dist.awt_invoice_payment_id,
	l_reverse_tax_dist.global_attribute_category,
	l_reverse_tax_dist.global_attribute1,
	l_reverse_tax_dist.global_attribute2,
	l_reverse_tax_dist.global_attribute3,
	l_reverse_tax_dist.global_attribute4,
	l_reverse_tax_dist.global_attribute5,
	l_reverse_tax_dist.global_attribute6,
	l_reverse_tax_dist.global_attribute7,
	l_reverse_tax_dist.global_attribute8,
	l_reverse_tax_dist.global_attribute9,
	l_reverse_tax_dist.global_attribute10,
	l_reverse_tax_dist.global_attribute11,
	l_reverse_tax_dist.global_attribute12,
	l_reverse_tax_dist.global_attribute13,
	l_reverse_tax_dist.global_attribute14,
	l_reverse_tax_dist.global_attribute15,
	l_reverse_tax_dist.global_attribute16,
	l_reverse_tax_dist.global_attribute17,
	l_reverse_tax_dist.global_attribute18,
	l_reverse_tax_dist.global_attribute19,
	l_reverse_tax_dist.global_attribute20,
	l_reverse_tax_dist.receipt_verified_flag,
	l_reverse_tax_dist.receipt_required_flag,
	l_reverse_tax_dist.receipt_missing_flag,
	l_reverse_tax_dist.justification,
	l_reverse_tax_dist.expense_group,
	l_reverse_tax_dist.start_expense_date,
	l_reverse_tax_dist.end_expense_date,
	l_reverse_tax_dist.receipt_currency_code,
	l_reverse_tax_dist.receipt_conversion_rate,
	l_reverse_tax_dist.receipt_currency_amount,
	l_reverse_tax_dist.daily_amount,
	l_reverse_tax_dist.web_parameter_id,
	l_reverse_tax_dist.adjustment_reason,
	l_reverse_tax_dist.award_id,
	l_reverse_tax_dist.credit_card_trx_id,
	l_reverse_tax_dist.dist_match_type,
	l_reverse_tax_dist.rcv_transaction_id,
	l_reverse_tax_dist.invoice_distribution_id,
	l_reverse_tax_dist.parent_reversal_id,
	l_reverse_tax_dist.tax_recoverable_flag,
	l_reverse_tax_dist.merchant_document_number,
	l_reverse_tax_dist.merchant_name,
	l_reverse_tax_dist.merchant_reference,
	l_reverse_tax_dist.merchant_tax_reg_number,
	l_reverse_tax_dist.merchant_taxpayer_id,
	l_reverse_tax_dist.country_of_supply,
	l_reverse_tax_dist.matched_uom_lookup_code,
	l_reverse_tax_dist.gms_burdenable_raw_cost,
	l_reverse_tax_dist.accounting_event_id,
	l_reverse_tax_dist.prepay_distribution_id,
	l_reverse_tax_dist.upgrade_posted_amt,
	l_reverse_tax_dist.upgrade_base_posted_amt,
	l_reverse_tax_dist.inventory_transfer_status,
	l_reverse_tax_dist.company_prepaid_invoice_id,
	l_reverse_tax_dist.cc_reversal_flag,
	l_reverse_tax_dist.awt_withheld_amt,
	l_reverse_tax_dist.pa_cmt_xface_flag,
	l_reverse_tax_dist.cancellation_flag,
	l_reverse_tax_dist.invoice_line_number,
	l_reverse_tax_dist.corrected_invoice_dist_id,
	l_reverse_tax_dist.rounding_amt,
	l_reverse_tax_dist.charge_applicable_to_dist_id,
	l_reverse_tax_dist.corrected_quantity,
	l_reverse_tax_dist.related_id,
	l_reverse_tax_dist.asset_book_type_code,
	l_reverse_tax_dist.asset_category_id,
	l_reverse_tax_dist.distribution_class,
	l_reverse_tax_dist.tax_code_id,
	l_reverse_tax_dist.intended_use,
	l_reverse_tax_dist.detail_tax_dist_id,
	l_reverse_tax_dist.rec_nrec_rate,
	l_reverse_tax_dist.recovery_rate_id,
	l_reverse_tax_dist.recovery_type_code,
	l_reverse_tax_dist.withholding_tax_code_id,
	l_reverse_tax_dist.taxable_amount,
	l_reverse_tax_dist.taxable_base_amount,
	l_reverse_tax_dist.tax_already_distributed_flag,
	l_reverse_tax_dist.summary_tax_line_id,
	l_reverse_tax_dist.rcv_charge_addition_flag,
	l_reverse_tax_dist.prepay_tax_diff_amount, -- BUG 7338249
    l_reverse_tax_dist.pay_awt_group_id); /*BUG 10261626*/

    INSERT into ZX_TAX_DIST_ID_GT (TAX_DIST_ID) values (l_reverse_tax_dist.detail_tax_dist_id) ; --bug 13101979
    l_inv_cancel_date := l_reverse_tax_dist.accounting_date; --bug 13101979

     END LOOP;

     l_rev_dist_cursor_count := c_reverse_tax_dist_1%ROWCOUNT  ;  -- Bug 10140793
     CLOSE c_reverse_tax_dist_1;

     -- Bug 10140793 Begin
     -----------------------------------------------------------------
     IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, '(2) l_rev_dist_cursor_count: ' || l_rev_dist_cursor_count);
     END IF;
     -----------------------------------------------------------------

     IF ( l_reverse_dist_count <> 0 AND l_rev_dist_cursor_count = 0 ) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_ERR_TAX_DIST_SYNC');
        APP_EXCEPTION.RAISE_EXCEPTION;
     END IF ;
     -- Bug 10140793  End

    END IF; -- Marker 7


    IF l_self_assess_tax_dist_exist THEN -- Marker 8

       l_debug_info := 'Inserting reverse entries into ap_self_assessed_tax_dist_all';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;

       OPEN c_rev_self_assess_tax_dist_1;
       LOOP
           FETCH c_rev_self_assess_tax_dist_1
	    INTO  l_self_assess_rev_tax_dist_1;
	    EXIT WHEN c_rev_self_assess_tax_dist_1%NOTFOUND;

	   INSERT INTO ap_self_assessed_tax_dist_all (
                accounting_date,
                accrual_posted_flag,
                assets_addition_flag,
                assets_tracking_flag,
                cash_posted_flag,
                distribution_line_number,
                dist_code_combination_id,
                invoice_id,
                last_updated_by,
                last_update_date,
                line_type_lookup_code,
                period_name,
                set_of_books_id,
                amount,
                base_amount,
                --batch_id,
                created_by,
                creation_date,
                description,
                final_match_flag,
                income_tax_region,
                last_update_login,
                match_status_flag,
                posted_flag,
                po_distribution_id,
                program_application_id,
                program_id,
                program_update_date,
                quantity_invoiced,
                request_id,
                reversal_flag,
                type_1099,
                unit_price,
                encumbered_flag,
                stat_amount,
                attribute1,
                attribute10,
                attribute11,
                attribute12,
                attribute13,
                attribute14,
                attribute15,
                attribute2,
                attribute3,
                attribute4,
                attribute5,
                attribute6,
                attribute7,
                attribute8,
                attribute9,
                attribute_category,
                expenditure_item_date,
                expenditure_organization_id,
                expenditure_type,
                parent_invoice_id,
                pa_addition_flag,
                pa_quantity,
                prepay_amount_remaining,
                project_accounting_context,
                project_id,
                task_id,
                packet_id,
                awt_flag,
                awt_group_id,
                awt_tax_rate_id,
                awt_gross_amount,
                awt_invoice_id,
                awt_origin_group_id,
                reference_1,
                reference_2,
                org_id,
                awt_invoice_payment_id,
                global_attribute_category,
                global_attribute1,
                global_attribute2,
                global_attribute3,
                global_attribute4,
                global_attribute5,
                global_attribute6,
                global_attribute7,
                global_attribute8,
                global_attribute9,
                global_attribute10,
                global_attribute11,
                global_attribute12,
                global_attribute13,
                global_attribute14,
                global_attribute15,
                global_attribute16,
                global_attribute17,
                global_attribute18,
                global_attribute19,
                global_attribute20,
                receipt_verified_flag,
                receipt_required_flag,
                receipt_missing_flag,
                justification,
                expense_group,
                start_expense_date,
                end_expense_date,
                receipt_currency_code,
                receipt_conversion_rate,
                receipt_currency_amount,
                daily_amount,
                web_parameter_id,
                adjustment_reason,
                award_id,
                credit_card_trx_id,
                dist_match_type,
                rcv_transaction_id,
                invoice_distribution_id,
                parent_reversal_id,
                tax_recoverable_flag,
                merchant_document_number,
                merchant_name,
                merchant_reference,
                merchant_tax_reg_number,
                merchant_taxpayer_id,
                country_of_supply,
                matched_uom_lookup_code,
                gms_burdenable_raw_cost,
                accounting_event_id,
                prepay_distribution_id,
                upgrade_posted_amt,
                upgrade_base_posted_amt,
                inventory_transfer_status,
                company_prepaid_invoice_id,
                cc_reversal_flag,
                awt_withheld_amt,
                pa_cmt_xface_flag,
                cancellation_flag,
                invoice_line_number,
                corrected_invoice_dist_id,
                rounding_amt,
                charge_applicable_to_dist_id,
                corrected_quantity,
                related_id,
                asset_book_type_code,
                asset_category_id,
                distribution_class,
                tax_code_id,
                intended_use,
                detail_tax_dist_id,
                rec_nrec_rate,
                recovery_rate_id,
                recovery_type_code,
                withholding_tax_code_id,
                taxable_amount,
                taxable_base_amount,
                tax_already_distributed_flag,
                summary_tax_line_id,
		        rcv_charge_addition_flag,
                self_assessed_flag,
                self_assessed_tax_liab_ccid,  --bug6805655
                prepay_tax_diff_amount -- BUG 7338249
                )
		VALUES
		(
		l_self_assess_rev_tax_dist_1.accounting_date,
		l_self_assess_rev_tax_dist_1.accrual_posted_flag,
		l_self_assess_rev_tax_dist_1.assets_addition_flag,
		l_self_assess_rev_tax_dist_1.assets_tracking_flag,
		l_self_assess_rev_tax_dist_1.cash_posted_flag,
		l_self_assess_rev_tax_dist_1.distribution_line_number,
		l_self_assess_rev_tax_dist_1.dist_code_combination_id,
		l_self_assess_rev_tax_dist_1.invoice_id,
		l_self_assess_rev_tax_dist_1.last_updated_by,
		l_self_assess_rev_tax_dist_1.last_update_date,
		l_self_assess_rev_tax_dist_1.line_type_lookup_code,
		l_self_assess_rev_tax_dist_1.period_name,
		l_self_assess_rev_tax_dist_1.set_of_books_id,
		l_self_assess_rev_tax_dist_1.amount,
		l_self_assess_rev_tax_dist_1.base_amount,
		--l_self_assess_rev_tax_dist_1.batch_id,
		l_self_assess_rev_tax_dist_1.created_by,
		l_self_assess_rev_tax_dist_1.creation_date,
		l_self_assess_rev_tax_dist_1.description,
		l_self_assess_rev_tax_dist_1.final_match_flag,
		l_self_assess_rev_tax_dist_1.income_tax_region,
		l_self_assess_rev_tax_dist_1.last_update_login,
		l_self_assess_rev_tax_dist_1.match_status_flag,
		l_self_assess_rev_tax_dist_1.posted_flag,
		l_self_assess_rev_tax_dist_1.po_distribution_id,
		l_self_assess_rev_tax_dist_1.program_application_id,
		l_self_assess_rev_tax_dist_1.program_id,
		l_self_assess_rev_tax_dist_1.program_update_date,
		l_self_assess_rev_tax_dist_1.quantity_invoiced,
		l_self_assess_rev_tax_dist_1.request_id,
		l_self_assess_rev_tax_dist_1.reversal_flag,
		l_self_assess_rev_tax_dist_1.type_1099,
		l_self_assess_rev_tax_dist_1.unit_price,
		l_self_assess_rev_tax_dist_1.encumbered_flag,
		l_self_assess_rev_tax_dist_1.stat_amount,
		l_self_assess_rev_tax_dist_1.attribute1,
		l_self_assess_rev_tax_dist_1.attribute10,
		l_self_assess_rev_tax_dist_1.attribute11,
		l_self_assess_rev_tax_dist_1.attribute12,
		l_self_assess_rev_tax_dist_1.attribute13,
		l_self_assess_rev_tax_dist_1.attribute14,
		l_self_assess_rev_tax_dist_1.attribute15,
		l_self_assess_rev_tax_dist_1.attribute2,
		l_self_assess_rev_tax_dist_1.attribute3,
		l_self_assess_rev_tax_dist_1.attribute4,
		l_self_assess_rev_tax_dist_1.attribute5,
		l_self_assess_rev_tax_dist_1.attribute6,
		l_self_assess_rev_tax_dist_1.attribute7,
		l_self_assess_rev_tax_dist_1.attribute8,
		l_self_assess_rev_tax_dist_1.attribute9,
		l_self_assess_rev_tax_dist_1.attribute_category,
		l_self_assess_rev_tax_dist_1.expenditure_item_date,
		l_self_assess_rev_tax_dist_1.expenditure_organization_id,
		l_self_assess_rev_tax_dist_1.expenditure_type,
		l_self_assess_rev_tax_dist_1.parent_invoice_id,
		l_self_assess_rev_tax_dist_1.pa_addition_flag,
		l_self_assess_rev_tax_dist_1.pa_quantity,
		l_self_assess_rev_tax_dist_1.prepay_amount_remaining,
		l_self_assess_rev_tax_dist_1.project_accounting_context,
		l_self_assess_rev_tax_dist_1.project_id,
		l_self_assess_rev_tax_dist_1.task_id,
		l_self_assess_rev_tax_dist_1.packet_id,
		l_self_assess_rev_tax_dist_1.awt_flag,
		l_self_assess_rev_tax_dist_1.awt_group_id,
		l_self_assess_rev_tax_dist_1.awt_tax_rate_id,
		l_self_assess_rev_tax_dist_1.awt_gross_amount,
		l_self_assess_rev_tax_dist_1.awt_invoice_id,
		l_self_assess_rev_tax_dist_1.awt_origin_group_id,
		l_self_assess_rev_tax_dist_1.reference_1,
		l_self_assess_rev_tax_dist_1.reference_2,
		l_self_assess_rev_tax_dist_1.org_id,
		l_self_assess_rev_tax_dist_1.awt_invoice_payment_id,
		l_self_assess_rev_tax_dist_1.global_attribute_category,
		l_self_assess_rev_tax_dist_1.global_attribute1,
		l_self_assess_rev_tax_dist_1.global_attribute2,
		l_self_assess_rev_tax_dist_1.global_attribute3,
		l_self_assess_rev_tax_dist_1.global_attribute4,
		l_self_assess_rev_tax_dist_1.global_attribute5,
		l_self_assess_rev_tax_dist_1.global_attribute6,
		l_self_assess_rev_tax_dist_1.global_attribute7,
		l_self_assess_rev_tax_dist_1.global_attribute8,
		l_self_assess_rev_tax_dist_1.global_attribute9,
		l_self_assess_rev_tax_dist_1.global_attribute10,
		l_self_assess_rev_tax_dist_1.global_attribute11,
		l_self_assess_rev_tax_dist_1.global_attribute12,
		l_self_assess_rev_tax_dist_1.global_attribute13,
		l_self_assess_rev_tax_dist_1.global_attribute14,
		l_self_assess_rev_tax_dist_1.global_attribute15,
		l_self_assess_rev_tax_dist_1.global_attribute16,
		l_self_assess_rev_tax_dist_1.global_attribute17,
		l_self_assess_rev_tax_dist_1.global_attribute18,
		l_self_assess_rev_tax_dist_1.global_attribute19,
		l_self_assess_rev_tax_dist_1.global_attribute20,
		l_self_assess_rev_tax_dist_1.receipt_verified_flag,
		l_self_assess_rev_tax_dist_1.receipt_required_flag,
		l_self_assess_rev_tax_dist_1.receipt_missing_flag,
		l_self_assess_rev_tax_dist_1.justification,
		l_self_assess_rev_tax_dist_1.expense_group,
		l_self_assess_rev_tax_dist_1.start_expense_date,
		l_self_assess_rev_tax_dist_1.end_expense_date,
		l_self_assess_rev_tax_dist_1.receipt_currency_code,
		l_self_assess_rev_tax_dist_1.receipt_conversion_rate,
		l_self_assess_rev_tax_dist_1.receipt_currency_amount,
		l_self_assess_rev_tax_dist_1.daily_amount,
		l_self_assess_rev_tax_dist_1.web_parameter_id,
		l_self_assess_rev_tax_dist_1.adjustment_reason,
		l_self_assess_rev_tax_dist_1.award_id,
		l_self_assess_rev_tax_dist_1.credit_card_trx_id,
		l_self_assess_rev_tax_dist_1.dist_match_type,
		l_self_assess_rev_tax_dist_1.rcv_transaction_id,
		l_self_assess_rev_tax_dist_1.invoice_distribution_id,
		l_self_assess_rev_tax_dist_1.parent_reversal_id,
		l_self_assess_rev_tax_dist_1.tax_recoverable_flag,
		l_self_assess_rev_tax_dist_1.merchant_document_number,
		l_self_assess_rev_tax_dist_1.merchant_name,
		l_self_assess_rev_tax_dist_1.merchant_reference,
		l_self_assess_rev_tax_dist_1.merchant_tax_reg_number,
		l_self_assess_rev_tax_dist_1.merchant_taxpayer_id,
		l_self_assess_rev_tax_dist_1.country_of_supply,
		l_self_assess_rev_tax_dist_1.matched_uom_lookup_code,
		l_self_assess_rev_tax_dist_1.gms_burdenable_raw_cost,
		l_self_assess_rev_tax_dist_1.accounting_event_id,
		l_self_assess_rev_tax_dist_1.prepay_distribution_id,
		l_self_assess_rev_tax_dist_1.upgrade_posted_amt,
		l_self_assess_rev_tax_dist_1.upgrade_base_posted_amt,
		l_self_assess_rev_tax_dist_1.inventory_transfer_status,
		l_self_assess_rev_tax_dist_1.company_prepaid_invoice_id,
		l_self_assess_rev_tax_dist_1.cc_reversal_flag,
		l_self_assess_rev_tax_dist_1.awt_withheld_amt,
		l_self_assess_rev_tax_dist_1.pa_cmt_xface_flag,
		l_self_assess_rev_tax_dist_1.cancellation_flag,
		l_self_assess_rev_tax_dist_1.invoice_line_number,
		l_self_assess_rev_tax_dist_1.corrected_invoice_dist_id,
		l_self_assess_rev_tax_dist_1.rounding_amt,
		l_self_assess_rev_tax_dist_1.charge_applicable_to_dist_id,
		l_self_assess_rev_tax_dist_1.corrected_quantity,
		l_self_assess_rev_tax_dist_1.related_id,
		l_self_assess_rev_tax_dist_1.asset_book_type_code,
		l_self_assess_rev_tax_dist_1.asset_category_id,
		l_self_assess_rev_tax_dist_1.distribution_class,
		l_self_assess_rev_tax_dist_1.tax_code_id,
		l_self_assess_rev_tax_dist_1.intended_use,
		l_self_assess_rev_tax_dist_1.detail_tax_dist_id,
		l_self_assess_rev_tax_dist_1.rec_nrec_rate,
		l_self_assess_rev_tax_dist_1.recovery_rate_id,
		l_self_assess_rev_tax_dist_1.recovery_type_code,
		l_self_assess_rev_tax_dist_1.withholding_tax_code_id,
		l_self_assess_rev_tax_dist_1.taxable_amount,
		l_self_assess_rev_tax_dist_1.taxable_base_amount,
		l_self_assess_rev_tax_dist_1.tax_already_distributed_flag,
		l_self_assess_rev_tax_dist_1.summary_tax_line_id,
		l_self_assess_rev_tax_dist_1.rcv_charge_addition_flag,
		l_self_assess_rev_tax_dist_1.self_assessed_flag,
 		l_self_assess_rev_tax_dist_1.self_assessed_tax_liab_ccid,   --bug6805655
        l_self_assess_rev_tax_dist_1.prepay_tax_diff_amount -- BUG 7338249
        );

	INSERT into ZX_TAX_DIST_ID_GT (TAX_DIST_ID) values (l_self_assess_rev_tax_dist_1.detail_tax_dist_id) ; --bug 13101979
	l_inv_cancel_date := l_self_assess_rev_tax_dist_1.accounting_date ; --bug 13101979

         END LOOP;

         l_rev_sa_dist_cursor_count := c_rev_self_assess_tax_dist_1%ROWCOUNT  ;  -- Bug 10140793

         CLOSE c_rev_self_assess_tax_dist_1;

         -- Bug 10140793 Begin
         -----------------------------------------------------------------
         IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, '(2) l_rev_sa_dist_cursor_count: ' || l_rev_sa_dist_cursor_count);
         END IF;
         -----------------------------------------------------------------

         IF ( l_rev_sa_dist_count <> 0 AND l_rev_sa_dist_cursor_count = 0 ) THEN
            FND_MESSAGE.SET_NAME('SQLAP','AP_ERR_TAX_DIST_SYNC');
            APP_EXCEPTION.RAISE_EXCEPTION;
         END IF ;
         -- Bug 10140793  End

	 END IF; -- Marker 8

    END IF; -- Marker 4

       --bug 13101979 moved the API here, the end of if block so that for all it will update once hence removing redundancy
        ZX_API_PUB.Update_Tax_dist_gl_date (
				1.0,
				FND_API.G_TRUE,
				FND_API.G_FALSE,
				FND_API.G_VALID_LEVEL_FULL,
				l_return_status_service,
				l_msg_count,
				l_msg_data,
				l_inv_cancel_date );

        IF (l_return_status_service <> FND_API.G_RET_STS_SUCCESS) THEN  -- handle errors

             l_return_status := FALSE;

             -----------------------------------------------------------------
             l_debug_info := 'Step 2.5: Handle errors returned by API';
             -----------------------------------------------------------------
             IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, l_debug_info);
             END IF;

             IF NOT(AP_ETAX_UTILITY_PKG.Return_Error_Messages(
                   P_All_Error_Messages  => 'N',
                   P_Msg_Count           => l_msg_count,
                   P_Msg_Data            => l_msg_data,
                   P_Error_Code          => l_Error_Code,
                   P_Calling_Sequence    => l_curr_calling_sequence)) THEN
                NULL;
             END IF;
	     /*Start of Bug 16842904*/
            IF((l_Error_Code is NULL) AND (l_gt_error is not NULL)) THEN
	       l_Error_Code := l_gt_error;
	    END IF;
	    /*End of Bug 16842904*/

             RETURN l_return_status;
         END IF;
        --bug 13101979


    IF l_tax_distributions_exist THEN

        -----------------------------------------------------------------
        l_debug_info := 'Step 4: Update reversal_flag';
        -----------------------------------------------------------------
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;

        UPDATE ap_invoice_distributions_all aid
           SET reversal_flag = (select reverse_flag
                                  from zx_rec_nrec_dist zx
                                 where zx.rec_nrec_tax_dist_id = aid.detail_tax_dist_id)
         WHERE aid.invoice_id = p_invoice_id
           AND aid.detail_tax_dist_id IS NOT NULL;

        -----------------------------------------------------------------
        l_debug_info := 'Step 5: Update related_flag';
        -----------------------------------------------------------------
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;

        UPDATE ap_invoice_distributions aid
           SET aid.related_id =
      			(SELECT invoice_distribution_id
                           FROM ap_invoice_distributions_all aid1
			  WHERE aid1.invoice_id = aid.invoice_id
			    AND aid1.invoice_line_number = aid.invoice_line_number
			    AND aid1.parent_reversal_id =
					(SELECT related_id
			                   FROM ap_invoice_distributions_all aid2
					  WHERE aid2.invoice_id = aid.invoice_id
					    AND aid2.invoice_line_number = aid.invoice_line_number
					    AND aid2.invoice_distribution_id = aid.parent_reversal_id)
                       )
        WHERE aid.related_id IS NULL
          AND aid.parent_reversal_id IS NOT NULL
          AND aid.invoice_id = p_invoice_id
          AND aid.reversal_flag = 'Y'
          AND aid.detail_tax_dist_id IS NOT NULL;

    END IF;



    IF l_self_assess_tax_dist_exist THEN

           -----------------------------------------------------------------
           l_debug_info := 'Step 4: Update reversal_flag';
           -----------------------------------------------------------------
           IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
           END IF;

           UPDATE ap_self_assessed_tax_dist_all aid
              SET reversal_flag = (select reverse_flag
                                     from zx_rec_nrec_dist zx
                                    where zx.rec_nrec_tax_dist_id = aid.detail_tax_dist_id)
            WHERE aid.invoice_id = p_invoice_id
              AND aid.detail_tax_dist_id IS NOT NULL;

           -----------------------------------------------------------------
           l_debug_info := 'Step 5: Update related_flag';
           -----------------------------------------------------------------
           IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
           END IF;

           UPDATE ap_self_assessed_tax_dist_all aid
              SET aid.related_id =
                        (SELECT invoice_distribution_id
                           FROM ap_self_assessed_tax_dist_all aid1
                          WHERE aid1.invoice_id = aid.invoice_id
                            AND aid1.invoice_line_number = aid.invoice_line_number
                            AND aid1.parent_reversal_id =
                                        (SELECT related_id
                                           FROM ap_self_assessed_tax_dist_all aid2
                                          WHERE aid2.invoice_id = aid.invoice_id
                                            AND aid2.invoice_line_number = aid.invoice_line_number
                                            AND aid2.invoice_distribution_id = aid.parent_reversal_id)
                       )
            WHERE aid.related_id IS NULL
              AND aid.parent_reversal_id IS NOT NULL
              AND aid.invoice_id = p_invoice_id
              AND aid.reversal_flag = 'Y'
              AND aid.detail_tax_dist_id IS NOT NULL;

   END IF;

   END IF; -- l_return_status
   END IF; --MARKER 0 --Bug8811102

   RETURN l_return_status;

  EXCEPTION
    WHEN OTHERS THEN

      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Exception: '||sqlerrm);
      END IF;

      IF (SQLCODE <> -20001) THEN

        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Id = '||P_Invoice_Id);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;

END CANCEL_INVOICE;

FUNCTION Generate_Recouped_Tax(
	             P_Invoice_id              IN NUMBER,
		     P_Invoice_Line_Number     IN NUMBER,
	             P_Calling_Mode            IN VARCHAR2,
	             P_All_Error_Messages      IN VARCHAR2,
	             P_Error_Code              OUT NOCOPY VARCHAR2,
	             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN IS

    CURSOR invoice_header IS
    SELECT *
      FROM ap_invoices_all
     WHERE invoice_id = P_Invoice_Id;

    CURSOR prepay_lines IS
    SELECT distinct prepLine.*
      FROM ap_invoice_distributions_all invDist,
           ap_invoice_distributions_all prepDist,
           ap_invoice_lines_all		prepLine
     WHERE invDist.prepay_distribution_id = prepDist.invoice_distribution_id
       AND prepLine.invoice_id		  = prepDist.invoice_id
       AND prepLine.line_number		  = prepDist.invoice_line_number
       AND invDist.line_type_lookup_code  = 'PREPAY'
       AND invDist.invoice_id             = p_invoice_id
       AND invDist.invoice_line_number    = p_invoice_line_number;

    l_inv_header_rec			ap_invoices_all%ROWTYPE;
    l_event_class_code			zx_trx_headers_gt.event_class_code%TYPE;
    l_event_type_code			zx_trx_headers_gt.event_type_code%TYPE;

    l_tax_already_calculated     	VARCHAR2(1);

    l_debug_info                	VARCHAR2(240);
    l_curr_calling_sequence     	VARCHAR2(4000);
    l_api_name                  	CONSTANT VARCHAR2(100) := 'Generate_Recouped_Tax';

    l_return_status                     BOOLEAN := TRUE;
    l_return_status_service             VARCHAR2(4000);
    l_msg_count                         NUMBER;
    l_msg_data                          VARCHAR2(4000);
    l_error_code			VARCHAR2(4000);
    l_gt_error                          VARCHAR2(4000);    /*Bug 16842904*/

BEGIN

    -----------------------------------------------------------------
    l_debug_info := 'Step 1: Populating invoice header local record';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------

    BEGIN
      OPEN  Invoice_Header;
      FETCH Invoice_Header INTO l_inv_header_rec;
      CLOSE Invoice_Header;
    END;

    -------------------------------------------------------------------
    l_debug_info := 'Step 2: Is tax already called invoice level?';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF (AP_ETAX_UTILITY_PKG.Is_Tax_Already_Calc_Inv(
          P_Invoice_Id           => p_invoice_id,
          P_Calling_Sequence     => l_curr_calling_sequence)) THEN

      l_tax_already_calculated := 'Y';
    ELSE
      l_tax_already_calculated := 'N';

    END IF;

    -----------------------------------------------------------------
    l_debug_info := 'Step 3: Populate Header';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    IF NOT(AP_ETAX_SERVICES_PKG.Populate_Headers_GT(
		       P_Invoice_Header_Rec         => l_inv_header_rec
		      ,P_Calling_Mode               => p_calling_mode
		      ,P_eTax_Already_called_flag   => l_tax_already_calculated
		      ,P_Event_Class_Code           => l_event_class_code
		      ,P_Event_Type_Code            => l_event_type_code
		      ,P_Error_Code                 => p_error_code
		      ,P_Calling_Sequence           => l_curr_calling_sequence)) THEN

      l_return_status := FALSE;
    END IF;

    -----------------------------------------------------------------
    l_debug_info := 'Step 4: Populate psuedo prepay lines for the recouped distributions';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    IF ( l_return_status = TRUE ) THEN

      OPEN  prepay_lines;
      FETCH prepay_lines
       BULK COLLECT INTO l_inv_line_list;
      CLOSE prepay_lines;

      IF l_inv_line_list.count > 0 THEN


         -----------------------------------------------------------------
         l_debug_info := 'Purge Staging Tables. Clear/Load Cache';
         IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
         END IF;
         --Print(l_api_name,l_debug_info);
         -----------------------------------------------------------------
         DELETE FROM ZX_TRANSACTION_LINES_GT;

         AP_ETAX_SERVICES_PKG.G_SITE_ATTRIBUTES.DELETE;
         AP_ETAX_SERVICES_PKG.G_ORG_ATTRIBUTES.DELETE;

          -----------------------------------------------------------------
          l_debug_info := 'Cache Line Defaults :' ||
	           ' Invoice Type Lookup Code = ' || l_inv_header_rec.invoice_type_lookup_code ||
			   ' ,Invoice Id = '              || l_inv_header_rec.invoice_id               ||
			   ' ,Org id = '                  || l_inv_header_rec.org_id                   ||
			   ' ,Vendor Site Id = '          || l_inv_header_rec.vendor_site_id           ||
			   ' ,Party Site Id = '           || l_inv_header_rec.party_site_id           ;
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -----------------------------------------------------------------

              IF l_inv_header_rec.invoice_type_lookup_code = 'PAYMENT REQUEST' THEN  /* if
                  condition for bug 5967914 as we need tp pass party_site_id instead of
                  vendor_site_id if invoice_type_lookup_code ='PAYMENT REQUEST' */
                 l_payment_request_flag :='Y';  -- for bug 5967914
	         Cache_Line_Defaults
	               ( p_org_id           => l_inv_header_rec.org_id
	                ,p_vendor_site_id   => l_inv_header_rec.party_site_id
	                ,p_calling_sequence => l_curr_calling_sequence);
              ELSE
                 l_payment_request_flag :='N';  -- for bug 5967914
               	  Cache_Line_Defaults
	               ( p_org_id           => l_inv_header_rec.org_id
	                ,p_vendor_site_id   => l_inv_header_rec.vendor_site_id
	                ,p_calling_sequence => l_curr_calling_sequence);
              END IF;


	 IF NOT(AP_ETAX_SERVICES_PKG.Populate_Lines_GT(
		           P_Invoice_Header_Rec      => l_inv_header_rec
		          ,P_Calling_Mode            => p_calling_mode
		          ,P_Event_Class_Code        => l_event_class_code
		          ,P_Line_Number             => p_invoice_line_number
		          ,P_Error_Code              => p_error_code
		          ,P_Calling_Sequence        => l_curr_calling_sequence )) THEN

	     l_return_status := FALSE;
	     l_gt_error := p_error_code;   /*Bug 16842904*/

         END IF;

         IF ( l_return_status = TRUE ) THEN

             -----------------------------------------------------------------
             l_debug_info := 'Step 5: Call Calculate_Tax service';
             IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                 FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
             END IF;
             -----------------------------------------------------------------

             zx_api_pub.calculate_tax(
		          p_api_version      => 1.0,
		          p_init_msg_list    => FND_API.G_TRUE,
		          p_commit           => FND_API.G_FALSE,
		          p_validation_level => FND_API.G_VALID_LEVEL_FULL,
		          x_return_status    => l_return_status_service,
		          x_msg_count        => l_msg_count,
		          x_msg_data         => l_msg_data);

         END IF;

         IF (l_return_status_service = 'S') THEN

             -----------------------------------------------------------------
             l_debug_info := 'Step 5.1: Update Tax Already Calculated Flag';
             IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                 FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
             END IF;
             -----------------------------------------------------------------

	     UPDATE ap_invoice_lines_all ail
	        SET ail.tax_already_calculated_flag = 'Y'
	      WHERE ail.invoice_id  = p_invoice_id
                AND ail.line_number = p_invoice_line_number;

             -----------------------------------------------------------------
             l_debug_info := 'Step 6: Generate Tax Distributions';
             IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                 FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
             END IF;
             -----------------------------------------------------------------

             l_return_status := ap_etax_pkg.calling_etax
		                        (p_invoice_id         => p_invoice_id,
					             p_line_number	      => p_invoice_line_number,
		                         p_calling_mode       => 'DISTRIBUTE RECOUP',
		                         p_all_error_messages => 'N',
		                         p_error_code         =>  l_error_code,
		                         p_calling_sequence   => l_curr_calling_sequence);

         ELSE  -- handle errors

            -----------------------------------------------------------------
            l_debug_info := 'Step 7: Handle errors returned by API';
            IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
            END IF;
            -----------------------------------------------------------------

            l_return_status := FALSE;

            IF NOT(AP_ETAX_UTILITY_PKG.Return_Error_Messages(
	               P_All_Error_Messages  => P_All_Error_Messages,
	               P_Msg_Count           => l_msg_count,
	               P_Msg_Data            => l_msg_data,
	               P_Error_Code          => P_Error_Code,
	               P_Calling_Sequence    => l_curr_calling_sequence)) THEN
	        NULL;
	    END IF;
	    /*Start of Bug 16842904*/
            IF((P_Error_Code is NULL) AND (l_gt_error is not NULL)) THEN
	       P_Error_Code := l_gt_error;
	    END IF;
	    /*End of Bug 16842904*/

         END IF;
      END IF;
    END IF;

    DELETE FROM ZX_TRX_HEADERS_GT;
    DELETE FROM ZX_TRANSACTION_LINES_GT;

    RETURN l_return_status;

EXCEPTION
    WHEN OTHERS THEN

      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Exception: '||sqlerrm);
      END IF;

      IF (SQLCODE <> -20001) THEN

        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Id = '||P_Invoice_Id);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      DELETE FROM ZX_TRX_HEADERS_GT;
      DELETE FROM ZX_TRANSACTION_LINES_GT;

      APP_EXCEPTION.RAISE_EXCEPTION;

END Generate_Recouped_Tax;

Function Delete_Tax_Distributions
			(p_invoice_id         IN  ap_invoice_distributions_all.invoice_id%Type,
			 p_calling_mode	      IN  VARCHAR2,
			 p_all_error_messages IN  VARCHAR2,
			 p_error_code         OUT NOCOPY VARCHAR2,
		         p_calling_sequence   IN  VARCHAR2) RETURN BOOLEAN IS

   -- Removed the cursor for the bug 9749258


   l_invoice_header_rec		ap_invoices_all%rowtype;
   l_application_id             zx_trx_headers_gt.application_id%TYPE;
   l_entity_code                zx_trx_headers_gt.entity_code%TYPE;
   l_event_class_code           zx_trx_headers_gt.event_class_code%TYPE;
   l_event_type_code            zx_trx_headers_gt.event_type_code%TYPE;
   l_tax_already_calculated     VARCHAR2(1);

   l_debug_info                 VARCHAR2(240);
   l_curr_calling_sequence      VARCHAR2(4000);

   l_return_status_service      VARCHAR2(4000);
   l_return_status              BOOLEAN := TRUE;
   l_error_code                 VARCHAR2(4000);
   l_msg_data			VARCHAR2(2000);
   l_msg_count			NUMBER;

  -- l_preview_dists		c_preview_dists%rowtype;
   l_transaction_line_rec_type  ZX_API_PUB.transaction_line_rec_type;

   l_api_name                    CONSTANT VARCHAR2(100) := 'Delete_Tax_distributions';

Begin

   l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.Delete_Tax_Distributions<-' ||
                               p_calling_sequence;

   IF NOT tax_distributions_exist
                        (p_invoice_id  => p_invoice_id) THEN

       l_debug_info := 'Exit delete_tax_distributions';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;

       RETURN l_return_status;

   END IF;

   -------------------------------------------------------------------
   l_debug_info := 'Step 1: Get invoice header details';
   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
   END IF;
   -------------------------------------------------------------------
   Select * Into l_invoice_header_rec
     From ap_invoices_all
    Where invoice_id = p_invoice_id;

   IF ((l_invoice_header_rec.quick_credit = 'Y') OR    -- Bug 5660314
       (l_invoice_header_rec.invoice_type_lookup_code IN ('AWT', 'INTEREST'))) THEN
     RETURN l_return_status;
   END IF;

   -------------------------------------------------------------------
   l_debug_info := 'Step 2: Populate product specific attributes';
   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
   END IF;
   -------------------------------------------------------------------
   l_application_id := 200;
   l_entity_code    := 'AP_INVOICES';

   -------------------------------------------------------------------
   l_debug_info := 'Step 3: Get event class code';
   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
   END IF;
   -------------------------------------------------------------------
   IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Class_Code(
		      P_Invoice_Type_Lookup_Code => l_invoice_header_rec.invoice_type_lookup_code,
		      P_Event_Class_Code         => l_event_class_code,
		      P_error_code               => l_error_code,
		      P_calling_sequence         => l_curr_calling_sequence)) THEN
      l_return_status := FALSE;
   END IF;

   -------------------------------------------------------------------
   l_debug_info := 'Step 4: Is tax already called invoice level?';
   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
   END IF;
   -------------------------------------------------------------------
   IF (AP_ETAX_UTILITY_PKG.Is_Tax_Already_Calc_Inv(
			P_Invoice_Id       => p_invoice_id,
			P_Calling_Sequence => l_curr_calling_sequence)) THEN
       l_tax_already_calculated := 'Y';
   ELSE
       l_tax_already_calculated := 'N';
   END IF;

   -------------------------------------------------------------------
   l_debug_info := 'Step 5: Get event type code';
   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
   END IF;
   -------------------------------------------------------------------
   IF (l_return_status = TRUE) THEN
      IF NOT(AP_ETAX_UTILITY_PKG.Get_Event_Type_Code(
			P_Event_Class_Code          => l_event_class_code,
			P_Calling_Mode              => 'DISTRIBUTE',
			P_eTax_Already_called_flag  => l_tax_already_calculated,
			P_Event_Type_Code           => l_event_type_code,
			P_Error_Code                => l_error_code,
			P_Calling_Sequence          => l_curr_calling_sequence)) THEN
        l_return_status := FALSE;
      END IF;
   END IF;
   --Bug6678578START
   --ER CHANGES 6772098
   UPDATE ap_invoice_distributions_All aid1
			    SET  aid1.amount = aid1.amount + nvl((SELECT SUM(nvl(amount,0))
			                            FROM ap_invoice_distributions_All aid2
			                           WHERE aid2.invoice_id =  p_invoice_id
                                         AND aid2.invoice_line_number = aid1.invoice_line_number
			                             AND aid2.charge_applicable_to_dist_id = aid1.invoice_distribution_id
			                             AND aid2.line_type_lookup_code IN ('REC_TAX','NONREC_TAX','TRV','TIPV')
                                         AND aid2.distribution_class = 'CANDIDATE'
                                         AND EXISTS (SELECT 1
                                                         FROM zx_rec_nrec_dist zd
                                                        WHERE zd.application_id =200
                                                          AND zd.entity_code = 'AP_INVOICES'
                                                          AND zd.event_class_code IN ('STANDARD INVOICES','EXPENSE REPORTS','PREPAYMENT INVOICES')
                                                          AND zd.trx_id = aid2.invoice_id
                                                          AND zd.rec_nrec_tax_dist_id = aid2.detail_tax_dist_id
                                                          AND NVL(zd.inclusive_flag,'N') = 'Y')),0),
			           aid1.base_amount =aid1.base_amount + nvl((SELECT SUM(nvl(base_amount,0))
			                            FROM ap_invoice_distributions_All aid3
			                           WHERE aid3.invoice_id =  p_invoice_id
                                         AND aid3.invoice_line_number = aid1.invoice_line_number
	                                     AND aid3.charge_applicable_to_dist_id = aid1.invoice_distribution_id
          		                         AND aid3.line_type_lookup_code IN ('REC_TAX','NONREC_TAX','TRV','TIPV')
                                         AND aid3.distribution_class = 'CANDIDATE'
                                         AND EXISTS (SELECT 1
                                                       FROM zx_rec_nrec_dist zd1
                                                      WHERE zd1.application_id =200
                                                        AND zd1.entity_code = 'AP_INVOICES'
                                                        AND zd1.event_class_code IN ('STANDARD INVOICES','EXPENSE REPORTS','PREPAYMENT INVOICES')
                                                        AND zd1.trx_id = aid3.invoice_id
                                                        AND zd1.rec_nrec_tax_dist_id = aid3.detail_tax_dist_id
                                                        AND NVL(zd1.inclusive_flag,'N') = 'Y')),0)   --ER CHANGES
			    WHERE aid1.invoice_id =  p_invoice_id
			      AND  aid1.line_type_lookup_code IN ('ITEM', 'ACCRUAL', 'FREIGHT', 'MISCELLANEOUS');   --bug9314506
   --ER CHANGES 6772098
   --Bug6678578END
   IF (l_return_status = TRUE) THEN


         INSERT INTO zx_tax_dist_id_gt
          (Select distinct  detail_tax_dist_id
             From ap_invoice_distributions_all
            Where invoice_id = p_invoice_id
              AND distribution_class = 'CANDIDATE'
              And line_type_lookup_code  In('NONREC_TAX', 'REC_TAX', 'TRV', 'TERV', 'TIPV')
           UNION
           Select distinct detail_tax_dist_id
             From ap_self_assessed_tax_dist_all
            Where invoice_id = p_invoice_id
              AND distribution_class = 'CANDIDATE'
              And line_type_lookup_code  In('NONREC_TAX', 'REC_TAX', 'TRV', 'TERV', 'TIPV'));
           --bug9749528


       --Removed the open cursor for bug 9749258

           l_transaction_line_rec_type.internal_organization_id := l_invoice_header_rec.org_id; --bug9749258
           l_transaction_line_rec_type.application_id           := l_application_id;
           l_transaction_line_rec_type.entity_code              := l_entity_code;
           l_transaction_line_rec_type.event_class_code         := l_event_class_code;
           l_transaction_line_rec_type.event_type_code          := l_event_type_code;
           l_transaction_line_rec_type.trx_id                   := p_invoice_id; --bug9749258
           l_transaction_line_rec_type.trx_line_id              := NULL; --bug9749258
           l_transaction_line_rec_type.trx_level_type           := 'LINE';

	     -------------------------------------------------------------------
           l_debug_info := 'Step 5: Call eTax API to delete tax distributions';
           IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
           END IF;
           -------------------------------------------------------------------
          --used the new API for bug9749258

	   ZX_NEW_SERVICES_PKG.delete_tax_dists(
	          p_api_version             =>  1.0,
	          p_init_msg_list           =>  FND_API.G_TRUE,
	          p_commit                  =>  FND_API.G_FALSE,
	          p_validation_level        =>  FND_API.G_VALID_LEVEL_FULL,
	          x_return_status           =>  l_return_status_service,
	          x_msg_count               =>  l_msg_count,
	          x_msg_data                =>  l_msg_data,
	          p_transaction_line_rec    =>  l_transaction_line_rec_type
	        );

           IF l_return_status_service <> FND_API.G_RET_STS_SUCCESS THEN
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
           END IF;

   END IF;

   --Bug8811102
   --Bug 9749258 deleted the extra delete statement.
   ---------------------------
   --Bug8811102
   RETURN l_return_status;

EXCEPTION
   WHEN OTHERS THEN

      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Exception: '||sqlerrm);
      END IF;

      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS', ' P_Invoice_Id = '||P_Invoice_Id);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;

END Delete_Tax_distributions;

FUNCTION TAX_DISTRIBUTIONS_EXIST
                        (p_invoice_id  IN NUMBER) RETURN BOOLEAN IS

      l_dummy VARCHAR2(40);

BEGIN
    SELECT 'Tax Distributions Exist'
      INTO l_dummy
      FROM ap_invoice_distributions_all
     WHERE invoice_id = p_invoice_id
       AND line_type_lookup_code IN ('REC_TAX', 'NONREC_TAX', 'TIPV', 'TRV', 'TERV')
       AND rownum = 1;

    RETURN (l_dummy IS NOT NULL);

EXCEPTION
    WHEN OTHERS THEN
         RETURN FALSE;
END TAX_DISTRIBUTIONS_EXIST;

FUNCTION TAX_ONLY_LINE_EXIST
                        (p_invoice_id  IN NUMBER) RETURN BOOLEAN IS

      l_dummy VARCHAR2(40);

BEGIN
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||'TAX_ONLY_LINE_EXIST','Checking if there is tax only line exists');
       END IF;

   /* SELECT 'Tax Only Line Exist'
      INTO l_dummy
      FROM ap_invoice_distributions_all
     WHERE invoice_id = p_invoice_id
       AND line_type_lookup_code IN ('REC_TAX', 'NONREC_TAX', 'TIPV', 'TRV', 'TERV')
       AND charge_applicable_to_dist_id IS NULL
       AND rownum = 1; */

    SELECT 'Tax Only Line Exist'
      INTO l_dummy
      FROM zx_lines_summary zls
     WHERE application_id   = AP_ETAX_PKG.AP_APPLICATION_ID
       AND entity_code      = AP_ETAX_PKG.AP_ENTITY_CODE
       AND event_class_code IN (AP_ETAX_PKG.AP_INV_EVENT_CLASS_CODE,
                                AP_ETAX_PKG.AP_PP_EVENT_CLASS_CODE,
                                AP_ETAX_PKG.AP_ER_EVENT_CLASS_CODE)
       AND zls.trx_id = p_invoice_id
       AND NVL(zls.reporting_only_flag, 'N') = 'N'
       AND NVL(zls.tax_only_line_flag, 'N') = 'Y'
       AND rownum = 1;

       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||'TAX_ONLY_LINE_EXIST','l_dummy: '|| NVL(l_dummy, 'No Tax Only Line'));
       END IF;

       RETURN (l_dummy IS NOT NULL);

EXCEPTION
    WHEN OTHERS THEN
         IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||'TAX_ONLY_LINE_EXIST', 'in others: '|| NVL(l_dummy, 'No Tax Only Line'));
         END IF;
         RETURN FALSE;
END TAX_ONLY_LINE_EXIST;

/* Bug 6694536. Added function to verify whether there are self assessed tax lines
--   associated with an invoice. Join with zx_rec_nrec_dist is required becase
--   self_assessed_flag of zx_rec_nrec_dist actually indicates whether the lines
--   are self assessed or not.
*/

FUNCTION SELF_ASSESS_TAX_DIST_EXIST
                        (p_invoice_id  IN NUMBER) RETURN BOOLEAN IS

      l_dummy VARCHAR2(40);

BEGIN

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||'SELF_ASSESS_TAX_DIST_EXIST','Checking if there is self assessed tax');
    END IF;

    SELECT 'Tax Distributions Exist'
      INTO l_dummy
      FROM ap_self_assessed_tax_dist_all asat,
           zx_rec_nrec_dist zx_dist
     WHERE invoice_id = p_invoice_id
       AND asat.detail_tax_dist_id = zx_dist.rec_nrec_tax_dist_id
       AND zx_dist.self_assessed_flag = 'Y'
       AND nvl(zx_dist.reverse_flag, 'N') <> 'Y'
       AND line_type_lookup_code IN ('REC_TAX', 'NONREC_TAX')
       AND rownum = 1;

    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||'SELF_ASSESS_TAX_DIST_EXIST','l_dummy: '|| NVL(l_dummy, 'No Self Assessed Tax'));
    END IF;

    RETURN (l_dummy IS NOT NULL);

EXCEPTION
    WHEN OTHERS THEN
         RETURN FALSE;
END SELF_ASSESS_TAX_DIST_EXIST;

PROCEDURE get_converted_qty_price (x_invoice_distribution_id IN  NUMBER,
	                               x_inv_price		     OUT NOCOPY NUMBER,
		                           x_inv_qty		     OUT NOCOPY NUMBER) IS

	 CURSOR c_rct_info (c_inv_dist_id NUMBER) IS
	 SELECT  D.unit_price		      unit_price,
                 D.quantity_invoiced      quantity_invoiced,  --Bug12834600
		     pll.matching_basis	      match_basis,
	         pll.match_option             match_option,
	         pl.unit_meas_lookup_code     po_uom,
	         D.matched_uom_lookup_code    rcv_uom,
	         rsl.item_id                  rcv_item_id
	  FROM   ap_invoice_distributions_all D,
	         po_distributions_all 	      PD,
	         po_lines_all		      PL,
	         po_line_locations_all	      PLL,
	         rcv_transactions	      RTXN,
	         rcv_shipment_lines 	      RSL
	  WHERE  D.invoice_distribution_id = c_inv_dist_id
	    AND  D.po_distribution_id      = PD.po_distribution_id
	    AND  PL.po_header_id           = PD.po_header_id
	    AND  PL.po_line_id             = PD.po_line_id
	    AND  PD.line_location_id       = PLL.line_location_id
	    AND  D.rcv_transaction_id      = RTXN.transaction_id
	    AND  RTXN.shipment_line_id     = RSL.shipment_line_id;

	l_match_basis	po_line_types.matching_basis%TYPE;
	l_match_option	po_line_locations.match_option%TYPE;
	l_po_uom	po_line_locations.unit_meas_lookup_code%TYPE;
	l_rct_uom	po_line_locations.unit_meas_lookup_code%TYPE;
	l_rct_item_id	rcv_shipment_lines.item_id%TYPE;

	l_uom_conv_rate NUMBER;
        l_qty_invoiced  NUMBER;
        l_inv_price     NUMBER;
BEGIN
     OPEN  c_rct_info (x_invoice_distribution_id);
     FETCH c_rct_info
     INTO  x_inv_price, x_inv_qty, l_match_basis, l_match_option,
           l_po_uom, l_rct_uom, l_rct_item_id;
     CLOSE c_rct_info;

     IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||'get_converted_qty_price','get_converted_qty_price');
     END IF;

     IF l_match_basis  = 'QUANTITY'  and
        l_match_option = 'R'	     and
        l_po_uom       <> l_rct_uom THEN

        l_uom_conv_rate := po_uom_s.po_uom_convert (
                             l_rct_uom,
                             l_po_uom,
                             l_rct_item_id);

        x_inv_qty   := x_inv_qty * l_uom_conv_rate;
        x_inv_price := x_inv_price / l_uom_conv_rate;

     IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||'get_converted_qty_price','l_uom_conv_rate '||l_uom_conv_rate);
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||'get_converted_qty_price','x_inv_qty '||x_inv_qty);
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||'get_converted_qty_price','x_inv_price '||x_inv_price);
     END IF;

     END IF;

EXCEPTION
     WHEN OTHERS THEN
          NULL;
END get_converted_qty_price;

FUNCTION Calculate_Tax_Receipt_Match(
			P_Invoice_Id              IN  NUMBER,
			P_Calling_Mode            IN  VARCHAR2,
			P_All_Error_Messages      IN  VARCHAR2,
			P_Error_Code              OUT NOCOPY VARCHAR2,
			P_Calling_Sequence        IN  VARCHAR2) RETURN BOOLEAN
IS

    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);

    l_inv_header_rec             ap_invoices_all%ROWTYPE;
    l_event_class_code           zx_trx_headers_gt.event_class_code%TYPE;
    l_event_type_code            zx_trx_headers_gt.event_type_code%TYPE;

    l_tax_already_calculated     VARCHAR2(1);

    l_return_status_service       VARCHAR2(4000);
    l_msg_count                   NUMBER;
    l_msg_data                    VARCHAR2(4000);
    l_msg                         VARCHAR2(4000);

    l_return_status               BOOLEAN := TRUE;
    l_no_tax_lines                VARCHAR2(1) := 'N';
    l_inv_rcv_matched             VARCHAR2(1) := 'N';

    CURSOR Invoice_Header IS
    SELECT *
      FROM ap_invoices_all
     WHERE invoice_id = P_Invoice_Id;

    CURSOR Tax_Lines_to_import IS
    SELECT *
      FROM ap_invoice_lines_all
     WHERE invoice_id = P_Invoice_Id
       AND line_type_lookup_code = 'TAX'
       AND summary_tax_line_id IS NULL;

    l_api_name CONSTANT VARCHAR2(100) := 'Calculate_Tax_Receipt_Match';

  BEGIN
    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.Calculate_Tax_Receipt_Match<-' ||
                               P_calling_sequence;

    -----------------------------------------------------------------
    l_debug_info := 'Step 1: Populating invoice header local record';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    BEGIN
      OPEN Invoice_Header;
      FETCH Invoice_Header INTO l_inv_header_rec;
      CLOSE Invoice_Header;
    END;

    BEGIN
      OPEN  Tax_Lines_to_Import;
      FETCH Tax_Lines_to_Import
      BULK  COLLECT INTO p_rct_match_tax_list;
      CLOSE Tax_Lines_to_Import;
    END;

    -----------------------------------------------------------------
    l_debug_info := 'Step 2: Is tax already called invoice level?';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    IF (AP_ETAX_UTILITY_PKG.Is_Tax_Already_Calc_Inv(
          P_Invoice_Id           => p_invoice_id,
          P_Calling_Sequence     => l_curr_calling_sequence)) THEN

      l_tax_already_calculated := 'Y';
    ELSE
      l_tax_already_calculated := 'N';

    END IF;

    -----------------------------------------------------------------
    l_debug_info := 'Step 3: Populate ZX header tables';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    IF NOT(AP_ETAX_SERVICES_PKG.Populate_Headers_GT(
		P_Invoice_Header_Rec         => l_inv_header_rec,
		P_Calling_Mode               => P_Calling_Mode,
		P_eTax_Already_called_flag   => l_tax_already_calculated,
		P_Event_Class_Code           => l_event_class_code,
		P_Event_Type_Code            => l_event_type_code,
		P_Error_Code                 => P_error_code,
		P_Calling_Sequence           => l_curr_calling_sequence )) THEN

      l_return_status := FALSE;
    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 4: If tax already calculated call freeze '||
                    'distributions';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF (l_tax_already_calculated = 'Y') THEN
         IF NOT(AP_ETAX_SERVICES_PKG.Freeze_itm_Distributions(
                P_Invoice_Header_Rec  => l_inv_header_rec,
                P_Calling_Mode        => 'FREEZE DISTRIBUTIONS',
                P_Event_Class_Code    => l_event_class_code,
                P_All_Error_Messages  => P_All_Error_Messages,
                P_Error_Code          => P_error_code,
                P_Calling_Sequence    => l_curr_calling_sequence)) THEN --Bug7592845

           l_return_status := FALSE;
        END IF;
    END IF;

    ------------------------------------------------------------
    l_debug_info := 'Step 5: Populate zx_transaction_lines_gt';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    ------------------------------------------------------------
    IF ( l_return_status = TRUE ) THEN
        IF NOT(Populate_Rct_Match_Lines_GT(
		P_Invoice_Header_Rec   => l_inv_header_rec,
		P_Event_Class_Code     => l_event_class_code,
		P_Error_Code           => P_error_code,
		P_Calling_Sequence     => l_curr_calling_sequence )) THEN

	   l_return_status := FALSE;
        END IF;
    END IF;

    IF (l_return_status = TRUE) THEN

        -----------------------------------------------------------------
        l_debug_info := 'Step 8: Call Calculate_Tax service';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        -----------------------------------------------------------------
        zx_api_pub.calculate_tax(
          p_api_version      => 1.0,
          p_init_msg_list    => FND_API.G_TRUE,
          p_commit           => FND_API.G_FALSE,
          p_validation_level => FND_API.G_VALID_LEVEL_FULL,
          x_return_status    => l_return_status_service,
          x_msg_count        => l_msg_count,
          x_msg_data         => l_msg_data);
    END IF;

    IF (l_return_status_service = 'S') THEN
      -----------------------------------------------------------------
      l_debug_info := 'Step 9: Handle return of tax lines';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------
      IF NOT(AP_ETAX_SERVICES_PKG.Return_Other_Charge_Lines(
                P_Invoice_header_rec => l_inv_header_rec,
                P_Error_Code         => P_error_code,
                P_Calling_Sequence   => l_curr_calling_sequence)) THEN


          l_return_status := FALSE;
      END IF;

    ELSE  -- handle errors

      -----------------------------------------------------------------
      l_debug_info := 'Step 10: Handle errors returned by API';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      -----------------------------------------------------------------
      l_return_status := FALSE;

      IF NOT(AP_ETAX_UTILITY_PKG.Return_Error_Messages(
               P_All_Error_Messages  => P_All_Error_Messages,
               P_Msg_Count           => l_msg_count,
               P_Msg_Data            => l_msg_data,
               P_Error_Code          => P_Error_Code,
               P_Calling_Sequence    => l_curr_calling_sequence)) THEN
        NULL;
      END IF;

    END IF;

   RETURN l_return_status;

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME ('SQLAP', 'AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR', SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS', ' P_Invoice_Id = '      ||P_Invoice_Id  ||
					    ' P_Calling_Mode ='     ||P_Calling_Mode||
					    ' P_Error_Code = '      ||P_Error_Code  ||
					    ' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);

      END IF;

      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,sqlerrm);
      END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;

  END Calculate_Tax_Receipt_Match;

  FUNCTION Populate_Rct_Match_Lines_GT(
             P_Invoice_Header_Rec      IN ap_invoices_all%ROWTYPE,
             P_Event_Class_Code        IN VARCHAR2,
             P_Error_Code              OUT NOCOPY VARCHAR2,
             P_Calling_Sequence        IN VARCHAR2) RETURN BOOLEAN IS

    TYPE Trx_Lines_Tab_Type IS TABLE OF zx_transaction_lines_gt%ROWTYPE;

    trans_lines				Trx_Lines_Tab_Type := Trx_Lines_Tab_Type();

    l_line_class                   	zx_transaction_lines_gt.line_class%TYPE;
    l_line_level_action			zx_transaction_lines_gt.line_level_action%TYPE;
    l_line_amt_includes_tax_flag	zx_transaction_lines_gt.line_amt_includes_tax_flag%TYPE;
    l_product_org_id			zx_transaction_lines_gt.product_org_id%TYPE;
    l_bill_to_location_id		zx_transaction_lines_gt.bill_to_location_id%TYPE;
    l_location_id		 	zx_transaction_lines_gt.ship_from_location_id%type;
    l_fob_point				zx_transaction_lines_gt.fob_point%TYPE;

    l_po_line_location_id		ap_invoice_lines_interface.po_line_location_id%TYPE;

    -- Purchase Order
    l_ref_doc_application_id		zx_transaction_lines_gt.ref_doc_application_id%TYPE;
    l_ref_doc_entity_code		zx_transaction_lines_gt.ref_doc_entity_code%TYPE;
    l_ref_doc_event_class_code		zx_transaction_lines_gt.ref_doc_event_class_code%TYPE;
    l_ref_doc_line_quantity		zx_transaction_lines_gt.ref_doc_line_quantity%TYPE;
    l_po_header_curr_conv_rate		po_headers_all.rate%TYPE;
    l_uom_code                    	mtl_units_of_measure.uom_code%TYPE;
    l_ref_doc_trx_level_type		zx_transaction_lines_gt.ref_doc_trx_level_type%TYPE;
    l_dummy				number;

    -- Receipt
    l_applied_to_application_id		zx_transaction_lines_gt.applied_to_application_id%TYPE;
    l_applied_to_entity_code		zx_transaction_lines_gt.applied_to_entity_code%TYPE;
    l_applied_to_event_class_code	zx_transaction_lines_gt.applied_to_event_class_code%TYPE;
    l_trx_receipt_date			zx_transaction_lines_gt.trx_receipt_date%TYPE;
    l_ref_doc_trx_id			zx_transaction_lines_gt.ref_doc_trx_id%TYPE;

    -- PO Tax Determining Attributes
    l_trx_bus_category			zx_transaction_lines_gt.trx_business_category%TYPE;
    l_intended_use              	zx_lines_det_factors.line_intended_use%type;
    l_product_type              	zx_lines_det_factors.product_type%type;
    l_product_category          	zx_lines_det_factors.product_category%type;
    l_product_fisc_class        	zx_lines_det_factors.product_fisc_classification%type;
    l_user_def_fisc_class   		zx_lines_det_factors.user_defined_fisc_class%type;
    l_assessable_value          	zx_lines_det_factors.assessable_value%type;
    l_dflt_tax_class_code       	zx_transaction_lines_gt.input_tax_classification_code%type;
    l_allow_tax_code_override           VARCHAR2(10);
    l_ship_to_party_id          po_line_locations_all.ship_to_organization_id%type; -- 7262269

    l_debug_info			Varchar2(240);
    l_curr_calling_sequence		Varchar2(4000);
    l_return_status			BOOLEAN := TRUE;

    l_api_name CONSTANT VARCHAR2(100) := 'Populate_Rct_Match_Lines_GT';

  BEGIN

      ----------------------------------------------------------------------
      l_debug_info := 'Step 1: Get location_id for org_id';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      ----------------------------------------------------------------------
      BEGIN
        SELECT location_id
          INTO l_bill_to_location_id
          FROM hr_all_organization_units
         WHERE organization_id = P_Invoice_Header_Rec.org_id;
      END;
      ----------------------------------------------------------------------
      l_debug_info := 'Location_id for org_id '|| l_bill_to_location_id||'& '||P_Invoice_Header_Rec.org_id;
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      ----------------------------------------------------------------------
      ----------------------------------------------------------------------
      l_debug_info := 'Step 2: Get fob_lookup_code from po_vendor_sites_all';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      ----------------------------------------------------------------------
      BEGIN
        SELECT location_id, fob_lookup_code
          INTO l_location_id, l_fob_point
          FROM ap_supplier_sites_all
         WHERE vendor_site_id = P_Invoice_Header_Rec.vendor_site_id;
      END;
      ----------------------------------------------------------------------
      l_debug_info := 'fob_lookup_code from po_vendor_sites_all '||l_fob_point ||'& '||l_location_id||'& '||P_Invoice_Header_Rec.vendor_site_id;
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      ----------------------------------------------------------------------
      ----------------------------------------------------------------------
      l_debug_info := 'Step 4: Populate zx_transaction_lines_gt';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      ----------------------------------------------------------------------
      IF (p_rct_match_tax_list.COUNT > 0) THEN

        trans_lines.EXTEND(p_rct_match_tax_list.COUNT);

        FOR i IN p_rct_match_tax_list.FIRST..p_rct_match_tax_list.LAST LOOP

          --------------------------------------------------------------------
          l_debug_info := 'Step 5: Get line_level_action for TAX ONLY line ';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          --------------------------------------------------------------------
          IF (p_rct_match_tax_list(i).rcv_transaction_id IS NOT NULL) THEN

              l_line_level_action 	:= 'CREATE_TAX_ONLY';

          END IF;

          -------------------------------------------------------------------
          l_debug_info := 'Step 6: Get Additional PO matched info if any ';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------
          IF (p_rct_match_tax_list(i).po_line_location_id IS NOT NULL) THEN

              l_po_line_location_id := p_rct_match_tax_list(i).po_line_location_id;

              IF NOT (AP_ETAX_UTILITY_PKG.Get_PO_Info(
	              P_Po_Line_Location_Id         => l_po_line_location_id,
	              P_PO_Distribution_Id          => null,
	              P_Application_Id              => l_ref_doc_application_id,
	              P_Entity_code                 => l_ref_doc_entity_code,
	              P_Event_Class_Code            => l_ref_doc_event_class_code,
	              P_PO_Quantity                 => l_ref_doc_line_quantity,
	              P_Product_Org_Id              => l_product_org_id,
	              P_Po_Header_Id                => l_ref_doc_trx_id,
	              P_Po_Header_curr_conv_rate    => l_po_header_curr_conv_rate,
	              P_Uom_Code                    => l_uom_code,
	              P_Dist_Qty                    => l_dummy,
	              P_Ship_Price                  => l_dummy,
	              P_Error_Code                  => P_error_code,
	              P_Calling_Sequence            => l_curr_calling_sequence)) THEN

	             l_return_status := FALSE;
              END IF;

	          l_ref_doc_trx_level_type := 'SHIPMENT';

         ELSE
            l_ref_doc_application_id	 := Null;
            l_ref_doc_entity_code	 := Null;
            l_ref_doc_event_class_code   := Null;
            l_ref_doc_line_quantity      := Null;
            l_product_org_id		 := Null;
            l_ref_doc_trx_id		 := Null;
            l_ref_doc_trx_level_type	 := Null;
            l_uom_code			 := Null;
         END IF;

          -------------------------------------------------------------------
          l_debug_info := 'Step 7: Get Additional receipt matched info ';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------
          IF ( l_return_status = TRUE AND
               p_rct_match_tax_list(i).rcv_transaction_id IS NOT NULL) THEN
            IF NOT (AP_ETAX_UTILITY_PKG.Get_Receipt_Info(
               P_Rcv_Transaction_Id          => p_rct_match_tax_list(i).rcv_transaction_id,
               P_Application_Id              => l_applied_to_application_id,
               P_Entity_code                 => l_applied_to_entity_code,
               P_Event_Class_Code            => l_applied_to_event_class_code,
               P_Transaction_Date            => l_trx_receipt_date,
               P_Error_Code                  => P_error_code,
               P_Calling_Sequence            => l_curr_calling_sequence)) THEN

               l_return_status := FALSE;
            END IF;
         ELSE
	    l_applied_to_application_id   := Null;
            l_applied_to_entity_code      := Null;
            l_applied_to_event_class_code := Null;
	    l_trx_receipt_date		  := Null;
         END IF;

	/*
	IF (l_dflt_tax_class_code IS NULL
            AND p_rct_match_tax_list(i).tax_classification_code IS NULL) THEN

	    ZX_AP_TAX_CLASSIFICATN_DEF_PKG.get_default_tax_classification
			            (p_ref_doc_application_id           => l_ref_doc_application_id,
			             p_ref_doc_entity_code              => l_ref_doc_entity_code,
			             p_ref_doc_event_class_code         => l_ref_doc_event_class_code,
			             p_ref_doc_trx_id                   => l_ref_doc_trx_id,
			             p_ref_doc_line_id                  => p_rct_match_tax_list(i).po_line_location_id,
			             p_ref_doc_trx_level_type           => 'SHIPMENT',
			             p_vendor_id                        => P_Invoice_Header_Rec.vendor_id,
			             p_vendor_site_id                   => P_Invoice_Header_Rec.vendor_site_id,
			             p_code_combination_id              => p_rct_match_tax_list(i).default_dist_ccid,
			             p_concatenated_segments            => null,
			             p_templ_tax_classification_cd      => null,
			             p_ship_to_location_id              => p_rct_match_tax_list(i).ship_to_location_id,
			             p_ship_to_loc_org_id               => null,
			             p_inventory_item_id                => p_rct_match_tax_list(i).inventory_item_id,
			             p_item_org_id                      => l_product_org_id,
			             p_tax_classification_code          => l_dflt_tax_class_code,
			             p_allow_tax_code_override_flag     => l_allow_tax_code_override,
			             APPL_SHORT_NAME                    => 'SQLAP',
			             FUNC_SHORT_NAME                    => 'NONE',
			             p_calling_sequence                 => 'AP_ETAX_SERVICES_PKG',
			             p_event_class_code                 => P_Event_Class_Code,
			             p_entity_code                      => 'AP_INVOICES',
			             p_application_id                   => 200,
			             p_internal_organization_id         => P_Invoice_Header_Rec.org_id);

	END IF; */

         IF (l_return_status = TRUE) THEN

	      IF NOT (AP_ETAX_UTILITY_PKG.Get_Line_Class(
		             P_Invoice_Type_Lookup_Code    => P_Invoice_Header_Rec.invoice_type_lookup_code,
		             P_Inv_Line_Type               => p_rct_match_tax_list(i).line_type_lookup_code,
		             P_Line_Location_Id            => p_rct_match_tax_list(i).po_line_location_id,
		             P_Line_Class                  => l_line_class,
		             P_Error_Code                  => P_error_code,
		             P_Calling_Sequence            => l_curr_calling_sequence)) THEN

                 l_return_status := FALSE;
             END IF;
         END IF;

          -------------------------------------------------------------------
          l_debug_info := 'Step 11: Populate pl/sql table';
          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;
          -------------------------------------------------------------------
          IF (l_return_status = TRUE ) THEN

            trans_lines(i).application_id			:= 200;
            trans_lines(i).entity_code				:= 'AP_INVOICES';
            trans_lines(i).event_class_code			:= p_event_class_code;
            trans_lines(i).trx_id				:= P_Invoice_Header_Rec.invoice_id;
            trans_lines(i).trx_level_type			:= 'LINE';
            trans_lines(i).line_level_action			:= l_line_level_action;
            trans_lines(i).line_class 				:= l_line_class;
            trans_lines(i).account_ccid				:= p_rct_match_tax_list(i).default_dist_ccid;

	    -- Tax for PO/Receipt Match is always treated as exclusive.
            trans_lines(i).line_amt_includes_tax_flag		:= 'N';
            trans_lines(i).historical_flag			:= 'N';

	    -- Pass negative line numbers to not conflict with existing invoice lines.
            trans_lines(i).trx_line_id				:= -i;
            trans_lines(i).trx_line_number			:= -i;

            trans_lines(i).trx_line_type			:= p_rct_match_tax_list(i).line_type_lookup_code;
            trans_lines(i).trx_line_description			:= p_rct_match_tax_list(i).description;
            trans_lines(i).trx_line_date                        := P_Invoice_Header_Rec.invoice_date;
            trans_lines(i).trx_line_gl_date                     := p_rct_match_tax_list(i).accounting_date;
            trans_lines(i).trx_receipt_date                     := l_trx_receipt_date;

            trans_lines(i).uom_code				:= p_rct_match_tax_list(i).unit_meas_lookup_code;
            trans_lines(i).trx_line_quantity 			:= p_rct_match_tax_list(i).quantity_invoiced;
            trans_lines(i).unit_price				:= p_rct_match_tax_list(i).unit_price;
            trans_lines(i).line_amt				:= p_rct_match_tax_list(i).amount;

            -- 7262269 /*Bug 13079028: Removed the IF-ELSE and called the function directly to handle all cases*/
            --IF p_rct_match_tax_list(i).po_line_location_id IS NOT NULL THEN
             l_ship_to_party_id := get_po_ship_to_org_id (p_rct_match_tax_list(i).po_line_location_id,
	                                                  p_rct_match_tax_list(i).inventory_item_id, /*Bug 13079028*/
							  p_rct_match_tax_list(i).org_id, /*Bug 13079028*/
							  p_rct_match_tax_list(i).application_id, /*Bug 13079028*/
							  p_rct_match_tax_list(i).reference_key5); /*Bug 13079028*/
            /*ELSE
             l_ship_to_party_id := p_rct_match_tax_list(i).org_id;
            END IF;*/ /*Bug 13079028*/

            trans_lines(i).ship_to_party_id		:= l_ship_to_party_id;
            -- 7262269

            trans_lines(i).bill_to_party_id			:= p_rct_match_tax_list(i).org_id;

            trans_lines(i).ship_from_party_id			:= P_Invoice_Header_Rec.party_id;
            trans_lines(i).bill_from_party_id			:= P_Invoice_Header_Rec.party_id;

            trans_lines(i).ship_from_party_site_id		:= P_Invoice_Header_Rec.party_site_id;
            trans_lines(i).bill_from_party_site_id		:= P_Invoice_Header_Rec.party_site_id;

            trans_lines(i).ship_to_location_id			:= p_rct_match_tax_list(i).ship_to_location_id;
            trans_lines(i).bill_to_location_id			:= l_bill_to_location_id;

            trans_lines(i).ship_from_location_id		:= l_location_id;
            trans_lines(i).bill_from_location_id          	:= l_location_id;

            trans_lines(i).trx_business_category		:= l_trx_bus_category;
            trans_lines(i).line_intended_use			:= l_intended_use;
            trans_lines(i).user_defined_fisc_class 		:= l_user_def_fisc_class;
            trans_lines(i).product_fisc_classification		:= l_product_fisc_class;
            trans_lines(i).product_type				:= l_product_type;
            trans_lines(i).product_category			:= l_product_category;
            trans_lines(i).assessable_value 		        := nvl(p_rct_match_tax_list(i).assessable_value,l_assessable_value);
            trans_lines(i).input_tax_classification_code	:= nvl(p_rct_match_tax_list(i).tax_classification_code,l_dflt_tax_class_code);

            trans_lines(i).product_id                           := p_rct_match_tax_list(i).inventory_item_id;
            trans_lines(i).product_description                  := p_rct_match_tax_list(i).item_description;
            trans_lines(i).product_org_id                       := l_product_org_id;
            trans_lines(i).fob_point                            := l_fob_point;

            trans_lines(i).ref_doc_application_id		:= l_ref_doc_application_id;
            trans_lines(i).ref_doc_entity_code			:= l_ref_doc_entity_code;
            trans_lines(i).ref_doc_event_class_code		:= l_ref_doc_event_class_code;
            trans_lines(i).ref_doc_trx_id			:= l_ref_doc_trx_id;
            trans_lines(i).ref_doc_line_id			:= p_rct_match_tax_list(i).po_line_location_id;
            trans_lines(i).ref_doc_trx_level_type		:= l_ref_doc_trx_level_type;
            trans_lines(i).ref_doc_line_quantity		:= l_ref_doc_line_quantity;

            trans_lines(i).applied_to_application_id		:= l_applied_to_application_id;
            trans_lines(i).applied_to_entity_code		:= l_applied_to_entity_code;
            trans_lines(i).applied_to_event_class_code		:= l_applied_to_event_class_code;
            trans_lines(i).applied_to_trx_id			:= p_rct_match_tax_list(i).rcv_transaction_id;

	    IF p_rct_match_tax_list(i).rcv_transaction_id IS NOT NULL THEN
               trans_lines(i).applied_to_trx_line_id		:= p_rct_match_tax_list(i).po_line_location_id;
            END IF;

            trans_lines(i).product_id                           := p_rct_match_tax_list(i).inventory_item_id;
            trans_lines(i).product_description                  := p_rct_match_tax_list(i).item_description;
            trans_lines(i).product_org_id			:= l_product_org_id;
            trans_lines(i).fob_point				:= l_fob_point;

          END IF; -- l_return_status

          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
	      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'event_class_code: ' || trans_lines(i).event_class_code);
	      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_id: '           || trans_lines(i).trx_id);
	      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_line_id: '      || trans_lines(i).trx_line_id);
	      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'trx_level_type: '   || trans_lines(i).trx_level_type);
	      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_level_action: '|| trans_lines(i).line_level_action);
	      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_class: '       || trans_lines(i).line_class);
	      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'line_amt: '         || trans_lines(i).line_amt);
          END IF;

        END LOOP;  -- end of loop TAX lines
      END IF; -- is p_rct_match_tax_list populated

    -------------------------------------------------------------------
    l_debug_info := 'Step 14: Bulk Insert into global temp tables';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    IF (l_return_status = TRUE) THEN

      IF (trans_lines.COUNT > 0) THEN

	DELETE FROM zx_transaction_lines_gt;

        FORALL m IN trans_lines.FIRST..trans_lines.LAST
          INSERT INTO zx_transaction_lines_gt
          VALUES trans_lines(m);

      END IF;
    END IF;

    RETURN TRUE;

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME ('SQLAP', 'AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR', SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS', ' P_Invoice_Id = '      ||P_Invoice_Header_Rec.Invoice_Id  ||
                                            ' P_Error_Code = '      ||P_Error_Code  ||
                                            ' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);

      END IF;

      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,sqlerrm);
      END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;

  END Populate_Rct_Match_Lines_GT;

FUNCTION Bulk_Populate_Headers_GT(
             p_validation_request_id    IN  NUMBER,
             p_calling_mode             IN  VARCHAR2,
             p_error_code               OUT NOCOPY VARCHAR2) RETURN BOOLEAN IS

    l_api_name       	CONSTANT VARCHAR2(100) := 'Bulk_Populate_Headers_GT';

BEGIN
        --Print(l_api_name, 'Bulk_Populate_Headers_GT (+)');
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'Bulk_Populate_Headers_GT (+)');
        END IF;

        DELETE FROM zx_trx_headers_gt;

	INSERT INTO zx_trx_headers_gt(
	        internal_organization_id,
	        application_id,
	        entity_code,
	        event_class_code,
	        event_type_code,
	        trx_id,
	        trx_date,
		    ledger_id,
	        trx_currency_code,
	        currency_conversion_date,
	        currency_conversion_rate,
	        currency_conversion_type,
	        minimum_accountable_unit,
	        precision,
	        legal_entity_id,
	        rounding_ship_from_party_id,
	        rounding_bill_from_party_id,
	        rndg_ship_from_party_site_id,
	        rndg_bill_from_party_site_id,
	        related_doc_application_id,
	        related_doc_entity_code,
	        related_doc_event_class_code,
	        related_doc_trx_id,
	        related_doc_number,
	        related_doc_date,
	        default_taxation_country,
	        quote_flag,
	        ctrl_total_hdr_tx_amt,
	        trx_number,
		    trx_description,
	        doc_seq_id,
	        doc_seq_name,
	        doc_seq_value,
	        document_sub_type,
	        supplier_tax_invoice_number,
	        supplier_tax_invoice_date,
	        supplier_exchange_rate,
	        tax_invoice_date,
	        tax_invoice_number,
	        bill_third_pty_acct_id,
	        bill_third_pty_acct_site_id,
		    ship_third_pty_acct_id,
		    ship_third_pty_acct_site_id
	        )
	  SELECT
	        ai.org_id,								--internal_organization_id
	        200,									--application_id
	        'AP_INVOICES',                        					--entity_code
	        (CASE
	           WHEN ai.invoice_type_lookup_code IN
			  ('STANDARD', 'CREDIT', 'DEBIT',   'MIXED',
	                   'ADJUSTMENT', 'PO PRICE ADJUST', 'INVOICE REQUEST',
	                   'CREDIT MEMO REQUEST', 'RETAINAGE RELEASE', 'PAYMENT REQUEST') -- bug 9281264
	                THEN 'STANDARD INVOICES'
	           WHEN (ai.invoice_type_lookup_code = 'PREPAYMENT')
	                 or (p_calling_mode IN ('RECOUPMENT', 'DISTRIBUTE RECOUP'))
	                THEN 'PREPAYMENT INVOICES'
	           WHEN ai.invoice_type_lookup_code = 'EXPENSE REPORT'
	                THEN 'EXPENSE REPORTS'
	        END), 				     					--event_class_code
	        (CASE
	           WHEN ai.invoice_type_lookup_code IN
			  ('STANDARD', 'CREDIT', 'DEBIT',   'MIXED',
	                   'ADJUSTMENT', 'PO PRICE ADJUST', 'INVOICE REQUEST',
	                   'CREDIT MEMO REQUEST', 'RETAINAGE RELEASE', 'PAYMENT REQUEST') -- bug 9281264
	                THEN 'STANDARD '
	           WHEN (ai.invoice_type_lookup_code = 'PREPAYMENT')
	                 or (p_calling_mode IN ('RECOUPMENT', 'DISTRIBUTE RECOUP'))
	                THEN 'PREPAYMENT '
	           WHEN ai.invoice_type_lookup_code = 'EXPENSE REPORT'
	                THEN 'EXPENSE REPORT '
	        END)||
	        DECODE(p_calling_mode,
			'CALCULATE',
                        (CASE ((SELECT 'Y'
				 FROM ap_invoice_lines_all
				WHERE invoice_id = ai.invoice_id
				  AND line_type_lookup_code <> 'AWT'
				  AND (tax_already_calculated_flag = 'Y'
			               OR  summary_tax_line_id IS NOT NULL)
				  AND ROWNUM = 1)
                             --- Start for bug 6485124
                                UNION
                                          (SELECT 'Y'
                                             FROM zx_lines_det_factors
                                            WHERE application_id = 200
                                             AND  entity_code = 'AP_INVOICES'
                                             AND  trx_id = ai.invoice_id
                                             AND  event_class_code in ('STANDARD INVOICES','PREPAYMENT INVOICES','EXPENSE REPORTS')
                                             AND  ROWNUM=1))
                             --- End for bug 6485124
				WHEN 'Y' THEN 'UPDATED'
		            	ELSE 'CREATED'
                	END),
			'DISTRIBUTE',
			(CASE (SELECT 'Y'
				 FROM ap_invoice_distributions_all
				WHERE invoice_id = ai.invoice_id
			          AND line_type_lookup_code <> 'AWT'
				  AND (tax_already_distributed_flag = 'Y'
			               OR detail_tax_dist_id IS NOT NULL)
			          AND (related_id IS NULL
				       OR related_id = invoice_distribution_id)
				  AND ROWNUM = 1)
				WHEN 'Y' THEN 'REDISTRIBUTE'
				ELSE 'DISTRIBUTE'
			END)),								--event_type_code
	        ai.invoice_id,                   					--trx_id
	        ai.invoice_date,                 					--trx_date
	        ai.set_of_books_id,              					--ledger_id
	        ai.invoice_currency_code,        					--trx_currency_code
	        ai.exchange_date,                					--currency_conversion_date
	        ai.exchange_rate,                					--currency_conversion_rate
	        ai.exchange_rate_type,           					--currency_conversion_type
	        NVL(cur.minimum_accountable_unit,
			 (1/power(10,cur.precision))),   				--minimum_accountable_unit
	        nvl(cur.precision,0),            					--precision
	        ai.legal_entity_id,              					--legal_entity_id
	        ai.party_id,                     					--rounding_ship_from_party_id
	        ai.party_id,                     					--rounding_bill_from_party_id
	        ai.party_site_id,                					--rndg_ship_from_party_site_id
	        ai.party_site_id,                					--rndg_bill_from_party_site_id
                (CASE
                   WHEN related_ai.invoice_type_lookup_code IS NOT NULL
                        THEN 200
                        ELSE NULL
                END),									--related_doc_application_id
		(CASE
                   WHEN related_ai.invoice_type_lookup_code IS NOT NULL
                        THEN 'AP_INVOICES'
		        ELSE NULL
                END),									--related_doc_entity_code
	        (CASE
	           WHEN related_ai.invoice_type_lookup_code IN
		          ('STANDARD', 'CREDIT', 'DEBIT',   'MIXED',
	                   'ADJUSTMENT', 'PO PRICE ADJUST', 'INVOICE REQUEST',
	                   'CREDIT MEMO REQUEST', 'RETAINAGE RELEASE')
	                THEN 'STANDARD INVOICES'
	           WHEN ai.invoice_type_lookup_code = 'PREPAYMENT'
	                THEN 'PREPAYMENT INVOICES'
	           WHEN ai.invoice_type_lookup_code = 'EXPENSE REPORT'
	                THEN 'EXPENSE REPORTS'
	        END),									--related_doc_event_class_code
	        ai.tax_related_invoice_id,       					--related_doc_trx_id
	        related_ai.invoice_num,                            			--related_doc_number
	        related_ai.invoice_date,                           			--related_doc_date
	        ai.taxation_country,             					--default_taxation_country
	        decode(p_calling_mode,
				'CALCULATE QUOTE', 'Y', 'N'),				--quote_flag
	        ai.control_amount,               					--ctrl_total_hdr_tx_amt
	        ai.invoice_num,                  					--trx_number
	        ai.description,                  					--trx_description
	        ai.doc_sequence_id,              					--doc_seq_id
	        doc.name,            		     					--doc_seq_name
	        nvl(to_char(ai.doc_sequence_value), ai.voucher_num),				--doc_seq_value bug6656894
	        ai.document_sub_type,            					--document_sub_type
	        ai.supplier_tax_invoice_number,  					--supplier_tax_invoice_number
	        ai.supplier_tax_invoice_date,    					--supplier_tax_invoice_date
	        ai.supplier_tax_exchange_rate,   					--supplier_exchange_rate
	        ai.tax_invoice_recording_date,   					--tax_invoice_date
	        ai.tax_invoice_internal_seq,     					--tax_invoice_number
	        ai.vendor_id,			     					--bill_third_pty_acct_id
		ai.vendor_site_id,		     					--bill_third_pty_acct_site_id
	        ai.vendor_id,                    					--ship_third_pty_acct_id
	        ai.vendor_site_id                					--ship_third_pty_acct_site_id
	  FROM  ap_invoices_all        ai,
	        fnd_currencies         cur,
	        fnd_document_sequences doc,
	        ap_invoices_all        related_ai,
                ap_system_parameters_all asp --Bug14779241
	 WHERE  ai.invoice_currency_code  = cur.currency_code
	   AND  ai.doc_sequence_id        = doc.doc_sequence_id (+)
	   AND  ai.tax_related_invoice_id = related_ai.invoice_id (+)
           AND  nvl(ai.quick_credit,'N') = 'N'
           AND  ai.invoice_type_lookup_code NOT IN ('AWT', 'INTEREST') -- bug 9281264
	   AND  ai.validation_request_id  = p_validation_request_id
       	   AND  asp.org_id = ai.org_id /* Bug14779241: Start */
           AND  ((asp.base_currency_code = ai.invoice_currency_code) OR
	        (p_calling_mode IN ('CALCULATE')) OR
                (asp.base_currency_code <> ai.invoice_currency_code AND
                ai.exchange_rate IS NOT NULL AND p_calling_mode IN ('DISTRIBUTE','DISTRIBUTE IMPORT')
                )); /* Bug14779241: End */

    -- Global Variable g_invoices_to_process should be initialized right after
    -- the previous insert. No other sql statements must be placed after the
    -- insert because the sql rowcount will be reset. This variable is used in
    -- calculate_tax and determine_recovery.

    g_invoices_to_process := sql%rowcount;
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'Rows inserted in zx_trx_headers_gt '||g_invoices_to_process);
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, 'Bulk_Populate_Headers_GT (-)');
    END IF;
    --Print(l_api_name, 'Rows inserted in zx_trx_headers_gt '||g_invoices_to_process);
    --Print(l_api_name, 'Bulk_Populate_Headers_GT (-)');

    RETURN TRUE;

EXCEPTION
     WHEN OTHERS THEN
          RETURN FALSE;

END Bulk_Populate_Headers_GT;

FUNCTION Update_Distributions(
             P_Invoice_header_rec    IN ap_invoices_all%ROWTYPE,
             P_Calling_Mode          IN VARCHAR2,
             P_All_Error_Messages    IN VARCHAR2,
             P_Error_Code            OUT NOCOPY VARCHAR2,
             P_Calling_Sequence      IN VARCHAR2) RETURN BOOLEAN
IS

    CURSOR c_reverse_dist (c_invoice_id NUMBER) IS
        SELECT aid_reverse.invoice_distribution_id invoice_distribution_id,
               aid_parent.invoice_distribution_id  parent_reversal_id,
               aid_parent.dist_code_combination_id parent_ccid
          FROM ap_invoice_distributions_all aid_reverse,
               ap_invoice_distributions_all aid_parent,
               zx_rec_nrec_dist zx
         WHERE aid_reverse.invoice_id         = c_invoice_id
           AND aid_reverse.detail_tax_dist_id = zx.rec_nrec_tax_dist_id
           AND aid_parent.detail_tax_dist_id  = zx.reversed_tax_dist_id
           AND aid_parent.line_type_lookup_code = aid_reverse.line_type_lookup_code;

    -- Bug 10140793 : Added below cursor
    CURSOR c_reverse_dist_sa (c_invoice_id NUMBER) IS
        SELECT aid_reverse.invoice_distribution_id invoice_distribution_id,
               aid_parent.invoice_distribution_id  parent_reversal_id,
               aid_parent.dist_code_combination_id parent_ccid
          FROM ap_self_assessed_tax_dist_all aid_reverse,
               ap_self_assessed_tax_dist_all aid_parent,
               zx_rec_nrec_dist zx
         WHERE aid_reverse.invoice_id         = c_invoice_id
           AND aid_reverse.detail_tax_dist_id = zx.rec_nrec_tax_dist_id
           AND aid_parent.detail_tax_dist_id  = zx.reversed_tax_dist_id
           AND aid_parent.line_type_lookup_code = aid_reverse.line_type_lookup_code;

   --Bug7253420 For RTAX/NRTAX and TRV having same detail_tax_dist_id
   --so the TRV distribution id is populating in the parent_reversal_id of
   --RTAX/NRTAX reversal distribution. So to get the Proper Reversal entries
   --line_type_lookup_code condition is added

   --       Cursor added for 6155675 - To get the tax amount which is included in
   --       the ITEM line (for tax inclusive lines and then we will subtract
   --       the included tax amount from the ITEM distributions .
    CURSOR  c_included_tax_amount is
        SELECT amount,included_tax_amount,line_number,
               (total_rec_tax_amt_funcl_curr +total_nrec_tax_amt_funcl_curr) base_included_tax_amount,discarded_flag --Bug8717396
        FROM   ap_invoice_lines_all
        WHERE  invoice_id =  p_invoice_header_rec.invoice_id
        AND    line_type_lookup_code IN ('ITEM', 'ACCRUAL', 'FREIGHT', 'MISCELLANEOUS','PREPAY') --/*Bug7338249*/
        --Bug9436217
        AND    included_tax_amount <> 0 ; --ER CHANGES
        --Bug9436217

    TYPE reversal_dist_info IS RECORD
                   (invoice_distribution_id ap_invoice_distributions_all.invoice_distribution_id%TYPE,
                    parent_reversal_id      ap_invoice_distributions_all.parent_reversal_id%TYPE,
                    parent_ccid             ap_invoice_distributions_all.dist_code_combination_id%TYPE);

    TYPE reversal_dist_type IS TABLE OF reversal_dist_info;

    l_reveral_dist_tab reversal_dist_type;

    l_debug_info		VARCHAR2(240);
    l_curr_calling_sequence	VARCHAR2(4000);
    l_api_name			CONSTANT VARCHAR2(100) := 'Update_Distributions';
    l_dist_amt                  ap_invoice_distributions_all.amount%type; -- for bug 6326552
    l_tot_tax_amt               ap_invoice_distributions_all.amount%type; -- for bug 6326552
BEGIN

    -------------------------------------------------------------------
    l_debug_info := 'Step 1: Update the related_id column';
    -------------------------------------------------------------------
    IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;

    /*  UPDATE ap_invoice_distributions_all aid
         SET related_id = (SELECT DECODE(MIN(nrtax.invoice_distribution_id),
						NULL, MIN(other.invoice_distribution_id),
                                    		MIN(nrtax.invoice_distribution_id))
                             FROM ap_invoice_distributions_all nrtax,
                                  ap_invoice_distributions_all other
                            WHERE nrtax.invoice_id 	   = aid.invoice_id
                              AND other.invoice_id	   = aid.invoice_id
                              AND nrtax.detail_tax_dist_id = aid.detail_tax_dist_id
                              AND other.detail_tax_dist_id = aid.detail_tax_dist_id
                              AND nrtax.line_type_lookup_code <> 'TERV' --Bug9415464
                              AND (nrtax.line_type_lookup_code = 'NONREC_TAX'
                                   OR other.line_type_lookup_code IN ('TIPV', 'TRV'))
                             GROUP BY 1)
      WHERE aid.invoice_id = P_Invoice_Header_Rec.invoice_id
        AND aid.line_type_lookup_code in ('NONREC_TAX', 'TIPV', 'TRV', 'TERV')
        AND EXISTS (SELECT aid1.detail_tax_dist_id
                      FROM ap_invoice_distributions_all aid1
                     WHERE aid1.invoice_id = aid.invoice_id
                       AND aid1.detail_tax_dist_id = aid.detail_tax_dist_id
                    HAVING count(*) > 1
                     GROUP BY aid1.detail_tax_dist_id);*/


     --Bug11730310 changed the above sql as follows

      UPDATE ap_invoice_distributions_all aid
      SET related_id =DECODE((SELECT MIN(nrtax.invoice_distribution_id)
                                 FROM ap_invoice_distributions_all nrtax
                                 WHERE nrtax.invoice_id         = aid.invoice_id
                                 AND nrtax.detail_tax_dist_id = aid.detail_tax_dist_id
                                 AND nrtax.line_type_lookup_code = 'NONREC_TAX'
                                 GROUP BY 1) ,NULL ,
                                (SELECT MIN(other.invoice_distribution_id)
                                 FROM ap_invoice_distributions_all other
                                 WHERE other.invoice_id         = aid.invoice_id
                                 AND other.detail_tax_dist_id = aid.detail_tax_dist_id
                                 AND other.line_type_lookup_code IN ('TIPV', 'TRV')
                                 GROUP BY 1) ,
                                (SELECT MIN(nrtax.invoice_distribution_id)
                                 FROM ap_invoice_distributions_all nrtax
                                 WHERE nrtax.invoice_id         = aid.invoice_id
                                 AND nrtax.detail_tax_dist_id = aid.detail_tax_dist_id
                                 AND nrtax.line_type_lookup_code = 'NONREC_TAX'
                                 GROUP BY 1))
        WHERE aid.invoice_id = P_Invoice_Header_Rec.invoice_id
        AND aid.line_type_lookup_code in ('NONREC_TAX', 'TIPV', 'TRV', 'TERV')
        AND EXISTS (SELECT aid1.detail_tax_dist_id
                    FROM ap_invoice_distributions_all aid1
                    WHERE aid1.invoice_id = aid.invoice_id
                    AND aid1.detail_tax_dist_id = aid.detail_tax_dist_id
                    HAVING count(*) > 1
                    GROUP BY aid1.detail_tax_dist_id);

    -------------------------------------------------------------------
    l_debug_info := 'Step 2: Update the related_id column for self assessed distributions';
    -------------------------------------------------------------------
    IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;

      UPDATE ap_self_assessed_tax_dist_all aid
         SET related_id = (SELECT DECODE(MIN(nrtax.invoice_distribution_id),
					 NULL, MIN(other.invoice_distribution_id),
					 MIN(nrtax.invoice_distribution_id))
                             FROM ap_self_assessed_tax_dist_all nrtax,
                                  ap_self_assessed_tax_dist_all other
                            WHERE nrtax.invoice_id 	   = aid.invoice_id
                              AND other.invoice_id 	   = aid.invoice_id
                              AND nrtax.detail_tax_dist_id = aid.detail_tax_dist_id
                              AND other.detail_tax_dist_id = aid.detail_tax_dist_id
                              AND nrtax.line_type_lookup_code <> 'TERV' --Bug9415464
                              AND (nrtax.line_type_lookup_code = 'NONREC_TAX'
                                   OR other.line_type_lookup_code IN ('TIPV', 'TRV'))
                             GROUP BY 1)
      WHERE aid.invoice_id = P_Invoice_Header_Rec.invoice_id
        AND aid.line_type_lookup_code in ('NONREC_TAX', 'TIPV', 'TRV', 'TERV')
        AND EXISTS (SELECT aid1.detail_tax_dist_id
                      FROM ap_self_assessed_tax_dist_all aid1
                     WHERE aid1.invoice_id = aid.invoice_id
                       AND aid1.detail_tax_dist_id = aid.detail_tax_dist_id
                    HAVING count(*) > 1
                     GROUP BY aid1.detail_tax_dist_id);


    -------------------------------------------------------------------
    l_debug_info := 'Step 3: Update rounding_amt for the primary NONREC tax dist';
    -------------------------------------------------------------------
    IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;

      UPDATE ap_invoice_distributions_all aid
         SET rounding_amt =
             (SELECT zd.func_curr_rounding_adjustment
                FROM zx_rec_nrec_dist zd
               WHERE zd.rec_nrec_tax_dist_id = aid.detail_tax_dist_id)
      WHERE aid.invoice_id = P_Invoice_Header_Rec.invoice_id
        AND aid.line_type_lookup_code in ('NONREC_TAX', 'TIPV', 'TRV', 'TERV')
        AND (aid.related_id IS NULL
             OR aid.related_id = aid.invoice_distribution_id);


    -------------------------------------------------------------------
    l_debug_info := 'Step 4: Update rounding_amt for the primary NONREC self assessed dist';
    -------------------------------------------------------------------
    IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;

      UPDATE ap_self_assessed_tax_dist_all aid
         SET rounding_amt =
             (SELECT zd.func_curr_rounding_adjustment
                FROM zx_rec_nrec_dist zd
               WHERE zd.rec_nrec_tax_dist_id = aid.detail_tax_dist_id)
      WHERE aid.invoice_id = P_Invoice_Header_Rec.invoice_id
        AND aid.line_type_lookup_code in ('NONREC_TAX', 'TIPV', 'TRV', 'TERV')
        AND (aid.related_id IS NULL
             OR aid.related_id = aid.invoice_distribution_id);


   -----------------------------------------------------------------
   l_debug_info := 'Step 5: Update REC and NONREC totals at line level';
   -----------------------------------------------------------------
    IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;

      UPDATE ap_invoice_lines_all ail
         SET (ail.total_rec_tax_amount,
              ail.total_nrec_tax_amount,
              ail.total_rec_tax_amt_funcl_curr,
              ail.total_nrec_tax_amt_funcl_curr) =
             (SELECT SUM(DECODE(NVL(zd.recoverable_flag, 'N'),
                                'Y', NVL(zd.rec_nrec_tax_amt, 0),
                                0)),
                     SUM(DECODE(NVL(zd.recoverable_flag, 'N'),
                                'N', NVL(zd.rec_nrec_tax_amt, 0),
                                 0)),
                     SUM(DECODE(NVL(zd.recoverable_flag, 'N'),
                                'Y', NVL(zd.rec_nrec_tax_amt_funcl_curr, 0),
                                 0)),
                     SUM(DECODE(NVL(zd.recoverable_flag, 'N'),
                                'N', NVL(zd.rec_nrec_tax_amt_funcl_curr, 0),
                                 0))
                FROM zx_rec_nrec_dist zd
               WHERE application_id   = AP_ETAX_PKG.AP_APPLICATION_ID
                 AND entity_code      = AP_ETAX_PKG.AP_ENTITY_CODE
                 AND event_class_code IN (AP_ETAX_PKG.AP_INV_EVENT_CLASS_CODE,
					  AP_ETAX_PKG.AP_PP_EVENT_CLASS_CODE,
					  AP_ETAX_PKG.AP_ER_EVENT_CLASS_CODE)
                 AND zd.trx_id		= ail.invoice_id
                 AND ((zd.trx_line_id	= ail.line_number AND zd.inclusive_flag = 'Y')
                    OR (ail.summary_tax_line_id = zd.summary_tax_line_id AND zd.inclusive_flag = 'N'))  --Bug11720331
                 AND NVL(zd.self_assessed_flag, 'N') = 'N')
       WHERE ail.invoice_id		= P_Invoice_Header_Rec.invoice_id
         AND (ail.summary_tax_line_id IS NOT NULL
              OR (ail.line_type_lookup_code <> 'TAX'
                  AND ail.included_tax_amount IS NOT NULL));   --Bug11720331

       -- the total will be updated in the TAX lines for any exclusive tax
       -- line created and in the taxable line (ITEM, PREPAY) in the  case
       -- the calculation is inclusive

   -----------------------------------------------------------------
   l_debug_info := 'Step 5: Update tax_already_distributed_flag';
   -----------------------------------------------------------------
   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
   END IF;

      /*Bug 8547912: Added hint */
      UPDATE /*+ index(AID) */ ap_invoice_distributions_all aid
         SET aid.tax_already_distributed_flag = 'Y'
       WHERE aid.invoice_id = p_invoice_header_rec.invoice_id
         AND NVL(aid.tax_already_distributed_flag, 'N') = 'N'
         AND aid.invoice_distribution_id IN
             ( SELECT /*+ unnest leading(aid1) index(aid1 AP_INVOICE_DISTRIBUTIONS_N27 ) index(zd ZX_REC_NREC_DIST_U1) */ aid1.charge_applicable_to_dist_id
                 FROM ap_invoice_distributions_all aid1,
                      zx_rec_nrec_dist zd
                WHERE zd.REC_NREC_TAX_DIST_ID = aid1.DETAIL_TAX_DIST_ID
                  AND aid1.invoice_id = p_invoice_header_rec.invoice_id );

   -----------------------------------------------------------------
   l_debug_info := 'Step 6: Update generate_dists on the invoice line';
   -----------------------------------------------------------------
   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
   END IF;

   UPDATE ap_invoice_lines_all ail
   SET    generate_dists = 'D'
   WHERE  ail.invoice_id = p_invoice_header_rec.invoice_id
   AND    ail.generate_dists <> 'D'
   AND    line_type_lookup_code = 'TAX'
   AND    EXISTS
		(SELECT aid.invoice_distribution_id
	           FROM ap_invoice_distributions_all aid
	          WHERE aid.invoice_id          = ail.invoice_id
	            AND aid.invoice_line_number = ail.line_number);

    -----------------------------------------------------------------
    l_debug_info := 'Step 7: Update Invoice Includes Prepay Flag';
    IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------
    UPDATE ap_invoice_distributions_all tax
    SET    tax.invoice_includes_prepay_flag = 'Y'
    WHERE  tax.invoice_id = p_invoice_header_rec.invoice_id
    AND    nvl(tax.invoice_includes_prepay_flag,'N') <> 'Y'
    AND    line_type_lookup_code in ('NONREC_TAX','REC_TAX','TIPV','TERV','TRV')
    AND    exists
    		(SELECT 1
	         FROM   ap_invoice_lines_all prepay
	         WHERE  prepay.invoice_id	     = tax.invoice_id
       	         AND    prepay.line_number	     = tax.invoice_line_number
	         AND    prepay.line_type_lookup_code = 'TAX'
	         AND    prepay.prepay_line_number    IS NOT NULL
	         AND    nvl(prepay.invoice_includes_prepay_flag,'N') = 'Y');

   -- For Loop added for bug 6155675 to subtract the inclusive tax amount
   -- from ITEM line.
   FOR i  in c_included_tax_amount LOOP

   --Bug9436217

   IF (NVL(i.discarded_flag,'N')='N') THEN

   --Bug9436217

   --Bug16315002: Commented below code

 /*  ------------------------------------------------------------------------
   l_debug_info := 'Step 7.1: Select sum of dist amount for each ITEM line';
   ------------------------------------------------------------------------

   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
   END IF;


     SELECT sum(amount) -- Select added for bug 6326552 to make sure
     INTO   l_dist_amt  -- sure that we update the distributions only once.
     FROM   ap_invoice_distributions_All
     WHERE  invoice_id =  p_invoice_header_rec.invoice_id
     AND    invoice_line_number = i.line_number
     AND    line_type_lookup_code IN ('ITEM',   --Bug6653070 Added SUM()
                                                 --instead of only amount
-- bug 7145041: add start
-- These lookup codes also have inclusive amount included in their amount.
			'ACCRUAL', 'FREIGHT', 'MISCELLANEOUS','PREPAY');
-- bug 7145041: add end

   ------------------------------------------------------------------------
      l_debug_info := 'Step 7.2: sum of dist amount for each ITEM line' ;
   ------------------------------------------------------------------------

   IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info||' '||i.line_number||' '||l_dist_amt);
   END IF; */

   ------------------------------------------------------------------------
   l_debug_info := 'Step 7.3: Select sum of dist amount for each TAX line';
   ------------------------------------------------------------------------

   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
   END IF;



     SELECT SUM(amount)         -- Select added for bug 6326552 to make sure
     INTO   l_tot_tax_amt       -- sure that we update the distributions if
                                --  if included tax amount is changed at
       			       --  line level.       .
     FROM   ap_invoice_distributions_All
     WHERE  invoice_id =  p_invoice_header_rec.invoice_id
     AND    invoice_line_number = i.line_number
     AND    line_type_lookup_code IN ('REC_TAX','NONREC_TAX','TRV','TERV','TIPV');


     ------------------------------------------------------------------------
      l_debug_info := 'Step 7.4: Sum of dist amount for TAX line' ;
     ------------------------------------------------------------------------

      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info||' '||i.line_number||' '||l_tot_tax_amt);
      END IF;


      ------------------------------------------------------------------------
      l_debug_info := 'Step 7.4.1: Discarded Flag' ;
      ------------------------------------------------------------------------


      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info||' '||i.line_number||' '||i.discarded_flag);
      END IF;

      --ER CHANGES 6772098

      --Bug9436217

      -- IF (i.amount = l_dist_amt) THEN --Bug8717396  --Bug16315002: Commented IF

      --Bug9436217

     ------------------------------------------------------------------------
      l_debug_info := 'Step 7.5: Update dist amount for each included TAX' ;
     ------------------------------------------------------------------------

      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;

      UPDATE ap_invoice_distributions_All aid1    --Bug6653070
        SET    aid1.amount = aid1.amount - nvl((SELECT SUM(nvl(amount,0))
                                  FROM ap_invoice_distributions_All aid2
                                 WHERE aid2.invoice_id =  p_invoice_header_rec.invoice_id
                                   AND aid2.invoice_line_number = i.line_number
                                   AND aid2.charge_applicable_to_dist_id = aid1.invoice_distribution_id
                                   AND aid2.line_type_lookup_code IN ('REC_TAX','NONREC_TAX', 'TIPV', 'TRV')
                                   AND EXISTS (SELECT 1
                                                 FROM zx_rec_nrec_dist zd1
                                                WHERE zd1.application_id =200
                                                  AND zd1.entity_code = 'AP_INVOICES'
                                                AND zd1.event_class_code IN ('STANDARD INVOICES','EXPENSE REPORTS','PREPAYMENT INVOICES')
                                                  AND zd1.trx_id = aid2.invoice_id
                                                  AND zd1.rec_nrec_tax_dist_id = aid2.detail_tax_dist_id
                                                  AND NVL(zd1.inclusive_flag,'N') = 'Y')),0),
               aid1.base_amount =aid1.base_amount- nvl((SELECT SUM(nvl(base_amount,0))
                                 FROM ap_invoice_distributions_All aid3
                                WHERE aid3.invoice_id =  p_invoice_header_rec.invoice_id
                                  AND aid3.invoice_line_number = i.line_number
					                        AND aid3.charge_applicable_to_dist_id = aid1.invoice_distribution_id
                                  AND aid3.line_type_lookup_code IN ('REC_TAX','NONREC_TAX', 'TIPV', 'TRV','TERV')
                                  AND EXISTS (SELECT 1
                                                FROM zx_rec_nrec_dist zd2
                                               WHERE zd2.application_id =200
                                                 AND zd2.entity_code = 'AP_INVOICES'
                                                AND zd2.event_class_code IN ('STANDARD INVOICES','EXPENSE REPORTS','PREPAYMENT INVOICES')
                                                 AND zd2.trx_id = aid3.invoice_id
                                                 AND zd2.rec_nrec_tax_dist_id = aid3.detail_tax_dist_id
                                                 AND NVL(zd2.inclusive_flag,'N') = 'Y')),0)
        WHERE  aid1.invoice_id =  p_invoice_header_rec.invoice_id
        AND    aid1.invoice_line_number = i.line_number
        AND    aid1.line_type_lookup_code IN ('ITEM', 'ACCRUAL', 'FREIGHT', 'MISCELLANEOUS');/*Bug7338249, bug9314506*/

      -- END IF;  --Bug8717396  --Bug16315002: Commented IF
      --ER CHANGES 6772098

   --Bug9436217


   END IF;

   --Bug9436217

   END LOOP;


   -----------------------------------------------------------------
   l_debug_info := 'Step 8: Update parent_reversal_id and parent_ccid';
   -----------------------------------------------------------------
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;

    OPEN  c_reverse_dist (p_invoice_header_rec.invoice_id);
    FETCH c_reverse_dist
     BULK COLLECT INTO l_reveral_dist_tab;
    CLOSE c_reverse_dist;

    IF l_reveral_dist_tab.count > 0 THEN
       FOR h in l_reveral_dist_tab.first .. l_reveral_dist_tab.last LOOP

           UPDATE ap_invoice_distributions_all
	   SET    parent_reversal_id       = l_reveral_dist_tab(h).parent_reversal_id
	         ,dist_code_combination_id = l_reveral_dist_tab(h).parent_ccid
           WHERE invoice_distribution_id   = l_reveral_dist_tab(h).invoice_distribution_id
             AND nvl(reversal_flag, 'N') <> 'Y';

       END LOOP;
   END IF;

   -- Bug 10140793 : Begin
   -------------------------------------------------
   l_debug_info := 'Now updating self assessed tax';
   -------------------------------------------------
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;

    l_reveral_dist_tab.delete ;

    OPEN  c_reverse_dist_sa (p_invoice_header_rec.invoice_id);
    FETCH c_reverse_dist_sa
     BULK COLLECT INTO l_reveral_dist_tab;
    CLOSE c_reverse_dist_sa;

    IF l_reveral_dist_tab.count > 0 THEN
       FOR h in l_reveral_dist_tab.first .. l_reveral_dist_tab.last LOOP

           UPDATE ap_self_assessed_tax_dist_all
	   SET    parent_reversal_id       = l_reveral_dist_tab(h).parent_reversal_id
	         ,dist_code_combination_id = l_reveral_dist_tab(h).parent_ccid
           WHERE invoice_distribution_id   = l_reveral_dist_tab(h).invoice_distribution_id
             AND nvl(reversal_flag, 'N') <> 'Y';

       END LOOP;
   END IF;

   -- Bug 10140793 : End

   -----------------------------------------------------------------
   l_debug_info := 'Step 9: Update reversal_flag';
   -----------------------------------------------------------------
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;

    UPDATE ap_invoice_distributions_all aid
       SET reversal_flag = (select reverse_flag
                              from zx_rec_nrec_dist zx
                             where zx.rec_nrec_tax_dist_id = aid.detail_tax_dist_id)
     WHERE aid.invoice_id = p_invoice_header_rec.invoice_id
       AND aid.detail_tax_dist_id IS NOT NULL;

   -- Bug 10140793 : Begin
   -------------------------------------------------
   l_debug_info := 'Now updating self assessed tax';
   -------------------------------------------------
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;

    UPDATE ap_self_assessed_tax_dist_all aid
       SET reversal_flag = (select reverse_flag
                              from zx_rec_nrec_dist zx
                             where zx.rec_nrec_tax_dist_id = aid.detail_tax_dist_id)
     WHERE aid.invoice_id = p_invoice_header_rec.invoice_id
       AND aid.detail_tax_dist_id IS NOT NULL;
   -- Bug 10140793 : End


   RETURN TRUE;

EXCEPTION
       WHEN NO_DATA_FOUND THEN
            IF (G_LEVEL_EXCEPTION >= G_CURRENT_RUNTIME_LEVEL) THEN
                FND_LOG.STRING(G_LEVEL_EXCEPTION,G_MODULE_NAME||l_api_name,SQLERRM);
            END IF;

       WHEN OTHERS THEN
         IF (SQLCODE <> -20001) THEN
             FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
             FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
             FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
             FND_MESSAGE.SET_TOKEN('PARAMETERS',
                                ' P_Invoice_Id = '||P_Invoice_Header_Rec.invoice_id||
                                ' P_Error_Code = '||P_Error_Code||
                                ' P_Calling_Sequence = '||P_Calling_Sequence);
             FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
         END IF;

         IF ( G_LEVEL_EXCEPTION >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_EXCEPTION,G_MODULE_NAME||l_api_name,SQLERRM);
         END IF;

         APP_EXCEPTION.RAISE_EXCEPTION;

END Update_Distributions;

PROCEDURE Cache_Line_Defaults
                        (p_org_id               IN ap_invoices_all.org_id%type,
                         p_vendor_site_id       IN ap_supplier_sites_all.vendor_site_id%type,
                         p_calling_sequence     IN VARCHAR2) IS

    l_api_name                  VARCHAR2(30)    := 'Cache_Line_Defaults';
    l_curr_calling_sequence     VARCHAR2(2000);
    l_debug_info                VARCHAR2(1000);

BEGIN

    l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.'||l_api_name||'<-'||p_calling_sequence;

    IF NOT AP_ETAX_SERVICES_PKG.g_org_attributes.exists(p_org_id) THEN

       ------------------------------------------------------------
       l_debug_info := 'Cache Org Attributes';
       IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
       END IF;
       --Print(l_api_name,l_debug_info);
       ------------------------------------------------------------

        SELECT location_id
          INTO AP_ETAX_SERVICES_PKG.g_org_attributes(p_org_id).bill_to_location_id
          FROM hr_all_organization_units
         WHERE organization_id = p_org_id;

    END IF;

    IF NOT AP_ETAX_SERVICES_PKG.g_site_attributes.exists(p_vendor_site_id) THEN

      ------------------------------------------------------------
      l_debug_info := 'Cache Supplier Site Attributes';
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      --Print(l_api_name,l_debug_info);
      ------------------------------------------------------------

      -- Bug 9526592 : Added debug messages
      ------------------------------------------------------------
      l_debug_info := 'Payment Req Flag '|| l_payment_request_flag;
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      --Print(l_api_name,l_debug_info);
      ------------------------------------------------------------

      ------------------------------------------------------------
      l_debug_info := 'Vendor Site Id  '|| p_vendor_site_id;
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;
      --Print(l_api_name,l_debug_info);
      ------------------------------------------------------------

      IF l_payment_request_flag = 'Y' THEN  --- if condition for bug 5967914

        SELECT  hps.location_id
         INTO   AP_ETAX_SERVICES_PKG.g_site_attributes(p_vendor_site_id).location_id
                FROM hz_party_sites hps
        WHERE party_site_id = p_vendor_site_id;

      ELSE
        SELECT  location_id
             ,fob_lookup_code
        INTO  AP_ETAX_SERVICES_PKG.g_site_attributes(p_vendor_site_id).location_id
             ,AP_ETAX_SERVICES_PKG.g_site_attributes(p_vendor_site_id).fob_lookup_code
        FROM ap_supplier_sites_all
        WHERE vendor_site_id = p_vendor_site_id;
      END IF;

    END IF;

EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE', l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;
      APP_EXCEPTION.RAISE_EXCEPTION;
END Cache_Line_Defaults;

FUNCTION Return_Other_Charge_Lines(
             P_Invoice_Header_Rec        IN ap_invoices_all%ROWTYPE,
             P_Error_Code                OUT NOCOPY VARCHAR2,
             P_Calling_Sequence          IN VARCHAR2) RETURN BOOLEAN
IS

    l_debug_info                 VARCHAR2(240);
    l_curr_calling_sequence      VARCHAR2(4000);

    l_period_name                gl_period_statuses.period_name%TYPE;
    l_gl_date                    ap_invoice_lines_all.accounting_date%TYPE;
    l_wfapproval_flag		 ap_system_parameters_all.approval_workflow_flag%TYPE;
    l_awt_include_tax_amt        ap_system_parameters_all.awt_include_tax_amt%TYPE;
    l_base_currency_code         ap_system_parameters_all.base_currency_code%TYPE;
    l_combined_filing_flag       ap_system_parameters_all.combined_filing_flag%TYPE;
    l_income_tax_region_flag     ap_system_parameters_all.income_tax_region_flag%TYPE;
    l_income_tax_region          ap_system_parameters_all.income_tax_region%TYPE;
    l_disc_is_inv_less_tax_flag	 ap_system_parameters_all.disc_is_inv_less_tax_flag%TYPE;
    l_wfapproval_status          ap_invoice_lines_all.wfapproval_status%TYPE;
    l_new_amt_applicable_to_disc ap_invoices_all.amount_applicable_to_discount%TYPE;
    l_payment_priority           ap_batches_all.payment_priority%TYPE;

    l_total_tax_amount          NUMBER;
    l_self_assessed_tax_amt     NUMBER;

    -- Allocations
    Cursor c_item_line (c_invoice_id IN NUMBER) IS
	Select ail.line_number
	From   ap_invoice_lines_all ail
	Where  ail.invoice_id = c_invoice_id
        And    ail.line_type_lookup_code = 'TAX'
        And    ail.prepay_invoice_id IS NULL;

        /*
	And NOT EXISTS
		(Select chrg_invoice_line_number
		 From ap_allocation_rule_lines arl
          	 Where arl.invoice_id = ail.invoice_id
            	 And arl.chrg_invoice_line_number = ail.line_number);
        */

    l_item_line	     c_item_line%rowtype;

    l_api_name                  CONSTANT VARCHAR2(100) := 'RETURN_TAX_LINES';

  BEGIN

    l_curr_calling_sequence := 'AP_ETAX_UTILITY_PKG.Return_Tax_Lines<-'||
                               P_calling_sequence;

    -------------------------------------------------------------------
    l_debug_info := 'Step 1: Get ap_system_parameters data';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    BEGIN
      SELECT
          approval_workflow_flag,
          awt_include_tax_amt,
          disc_is_inv_less_tax_flag,
          base_currency_code,
          combined_filing_flag,
          income_tax_region_flag,
          income_tax_region
        INTO
          l_wfapproval_flag,
          l_awt_include_tax_amt,
          l_disc_is_inv_less_tax_flag,
          l_base_currency_code,
          l_combined_filing_flag,
          l_income_tax_region_flag,
          l_income_tax_region
        FROM ap_system_parameters_all
       WHERE org_id = P_Invoice_Header_Rec.org_id;
    END;

    -------------------------------------------------------------------
    l_debug_info := 'Step 2: Update existing exclusive tax lines';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    BEGIN
      UPDATE ap_invoice_lines_all ail
         SET
       (-- Bug 10157751 ail.description,
        ail.amount,
        ail.base_amount,
        ail.cancelled_flag,
        ail.last_updated_by,
        ail.last_update_login,
        ail.last_update_date,
        ail.tax_regime_code,
        ail.tax,
        ail.tax_jurisdiction_code,
        ail.tax_status_code,
        ail.tax_rate_id,
        ail.tax_rate_code,
        ail.tax_rate,
	ail.generate_dists) =
	(
      SELECT
        /* Bug 10157751
        DECODE( ail.line_source,
		'MANUAL LINE ENTRY', ail.description,
		'IMPORTED'         , ail.description,
                zls.tax_regime_code||' - '||zls.tax ),		-- description : Bug 9383712 - Added DECODE
	*/
        zls.tax_amt, 						-- amount
        zls.tax_amt_funcl_curr,					-- base_amount
        zls.cancel_flag,					-- cancelled_flag
        l_user_id,						-- last_updated_by
        l_login_id,						-- last_update_login
        l_sysdate, 						-- last_update_date
        zls.tax_regime_code,	    				-- tax_regime_code
        zls.tax,		    				-- tax
        zls.tax_jurisdiction_code,  				-- tax_jurisdiction_code
        zls.tax_status_code,	    				-- tax_status_code
        zls.tax_rate_id,	    				-- tax_rate_id
        zls.tax_rate_code,	    				-- tax_rate_code
        zls.tax_rate, 		    				-- tax_rate
	DECODE(ail.generate_dists,'D','D','Y')		        -- generate_dists  bug 5460342
        FROM zx_lines_summary zls
       WHERE zls.summary_tax_line_id		= ail.summary_tax_line_id
         AND nvl(zls.reporting_only_flag, 'N')	= 'N'
       )
       WHERE ail.invoice_id = P_Invoice_Header_Rec.invoice_id
	 AND ail.line_type_lookup_code	= 'TAX'
         AND EXISTS
	       	    (SELECT ls.summary_tax_line_id
                       FROM zx_lines_summary ls
                      WHERE ls.summary_tax_line_id		= ail.summary_tax_line_id
                        AND ls.trx_id				= ail.invoice_id
                        AND NVL(ls.tax_amt_included_flag, 'N')	= 'N'
                        AND NVL(ls.self_assessed_flag, 'N')	= 'N'
                        AND NVL(ls.reporting_only_flag, 'N')	= 'N');

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;

      WHEN OTHERS THEN
        IF (SQLCODE <> -20001) THEN
          FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
          FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
          FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
          FND_MESSAGE.SET_TOKEN('PARAMETERS',
            ' P_Invoice_Id = '||P_Invoice_Header_Rec.Invoice_Id||
            ' P_Error_Code = '||P_Error_Code||
            ' P_Calling_Sequence = '||P_Calling_Sequence);
          FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
        END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;
    END;

    -------------------------------------------------------------------
    l_debug_info := 'Step 3: Get open gl_date';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------

    l_period_name := AP_UTILITIES_PKG.get_current_gl_date
				(P_Invoice_Header_Rec.gl_date, P_Invoice_header_Rec.org_id);

    IF (l_period_name IS NULL) THEN
	AP_UTILITIES_PKG.get_open_gl_date(
	       P_Date                  => P_Invoice_Header_Rec.gl_date,
	       P_Period_Name           => l_period_name,
	       P_GL_Date               => l_gl_date,
	       P_Org_Id                => P_Invoice_Header_Rec.org_id);
    ELSE
	l_gl_date := P_Invoice_Header_Rec.gl_date;
    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 4: Determine if tax amount will be included in awt';
    -------------------------------------------------------------------
    -- Bug 9160534. Added P_Invoice_Header_Rec.SOURCE check.
    IF (NVL(P_Invoice_Header_Rec.SOURCE, 'DUMMY') = 'RTS' OR
        NVL(l_wfapproval_flag,'N') <> 'Y') THEN
      l_wfapproval_status := 'NOT REQUIRED';
    ELSE
      l_wfapproval_status := 'REQUIRED';
    END IF;

    -------------------------------------------------------------------
    l_debug_info := 'Step 5: Insert exclusive tax lines';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    BEGIN
      INSERT INTO ap_invoice_lines_all (
        invoice_id,
        line_number,
        line_type_lookup_code,
        requester_id,
        description,
        line_source,
        org_id,
        line_group_number,
        inventory_item_id,
        item_description,
        serial_number,
        manufacturer,
        model_number,
        warranty_number,
        generate_dists,
        match_type,
        distribution_set_id,
        account_segment,
        balancing_segment,
        cost_center_segment,
        overlay_dist_code_concat,
        default_dist_ccid,
        prorate_across_all_items,
        accounting_date,
        period_name,
        deferred_acctg_flag,
        def_acctg_start_date,
        def_acctg_end_date,
        def_acctg_number_of_periods,
        def_acctg_period_type,
        set_of_books_id,
        amount,
        base_amount,
        rounding_amt,
        quantity_invoiced,
        unit_meas_lookup_code,
        unit_price,
        wfapproval_status,
        discarded_flag,
        original_amount,
        original_base_amount,
        original_rounding_amt,
        cancelled_flag,
        income_tax_region,
        type_1099,
        stat_amount,
        prepay_invoice_id,
        prepay_line_number,
        invoice_includes_prepay_flag,
        corrected_inv_id,
        corrected_line_number,
        po_header_id,
        po_line_id,
        po_release_id,
        po_line_location_id,
        po_distribution_id,
        rcv_transaction_id,
        final_match_flag,
        assets_tracking_flag,
        asset_book_type_code,
        asset_category_id,
        project_id,
        task_id,
        expenditure_type,
        expenditure_item_date,
        expenditure_organization_id,
        pa_quantity,
        pa_cc_ar_invoice_id,
        pa_cc_ar_invoice_line_num,
        pa_cc_processed_code,
        award_id,
        awt_group_id,
        reference_1,
        reference_2,
        receipt_verified_flag,
        receipt_required_flag,
        receipt_missing_flag,
        justification,
        expense_group,
        start_expense_date,
        end_expense_date,
        receipt_currency_code,
        receipt_conversion_rate,
        receipt_currency_amount,
        daily_amount,
        web_parameter_id,
        adjustment_reason,
        merchant_document_number,
        merchant_name,
        merchant_reference,
        merchant_tax_reg_number,
        merchant_taxpayer_id,
        country_of_supply,
        credit_card_trx_id,
        company_prepaid_invoice_id,
        cc_reversal_flag,
        creation_date,
        created_by,
        last_updated_by,
        last_update_date,
        last_update_login,
        program_application_id,
        program_id,
        program_update_date,
        request_id,
        attribute_category,
        attribute1,
        attribute2,
        attribute3,
        attribute4,
        attribute5,
        attribute6,
        attribute7,
        attribute8,
        attribute9,
        attribute10,
        attribute11,
        attribute12,
        attribute13,
        attribute14,
        attribute15,
        global_attribute_category,
        global_attribute1,
        global_attribute2,
        global_attribute3,
        global_attribute4,
        global_attribute5,
        global_attribute6,
        global_attribute7,
        global_attribute8,
        global_attribute9,
        global_attribute10,
        global_attribute11,
        global_attribute12,
        global_attribute13,
        global_attribute14,
        global_attribute15,
        global_attribute16,
        global_attribute17,
        global_attribute18,
        global_attribute19,
        global_attribute20,
        control_amount,
        assessable_value,
        total_rec_tax_amount,
        total_nrec_tax_amount,
        total_rec_tax_amt_funcl_curr,
        total_nrec_tax_amt_funcl_curr,
        included_tax_amount,
        primary_intended_use,
        ship_to_location_id,
        product_type,
        product_category,
        product_fisc_classification,
        user_defined_fisc_class,
        trx_business_category,
        summary_tax_line_id,
        tax_regime_code,
        tax,
        tax_jurisdiction_code,
        tax_status_code,
        tax_rate_id,
        tax_rate_code,
        tax_rate,
        tax_code_id)
      SELECT
        P_Invoice_Header_Rec.Invoice_Id,				-- invoice_id
        (SELECT NVL(MAX(ail2.line_number),0)
           FROM ap_invoice_lines_all ail2
          WHERE ail2.invoice_id =  zls.trx_id) + ROWNUM,  		-- line_number
        'TAX',								-- line_type_lookup_code
        null,								-- requester_id
        NVL( AI.description, zls.tax_regime_code||' - '||zls.tax ),	-- description    Bug 10157751
        'ETAX',								-- line_source
        P_Invoice_Header_Rec.org_id,   					-- org_id
        null,   							-- line_group_number
        null,   							-- inventory_item_id
        null,   							-- item_description
        null,   							-- serial_number
        null,   							-- manufacturer
        null,   							-- model_number
        null,   							-- warranty_number
        DECODE(NVL(zls.tax_only_line_flag, 'N'),
               'Y', 'D',
               'Y'),   							-- generate_dists
        DECODE(zls.applied_to_trx_id,
               null, 'NOT_MATCHED',
               'OTHER_TO_RECEIPT'),   					-- match_type
        null,   							-- distribution_set_id
        null,   							-- account_segment
        null,   							-- balancing_segment
        null,   							-- cost_center_segment
        null,   							-- overlay_dist_code_concat
        null,   							-- default_dist_ccid
        'N',   								-- prorate_across_all_items
        l_gl_date,   							-- accounting_date
        DECODE(NVL(zls.tax_only_line_flag, 'N'),
               'N', DECODE(zls.applied_to_trx_id,
                           null, null, l_period_name),
                l_period_name),   					-- period_name
        'N',   								-- deferred_acctg_flag
        null,   							-- def_acctg_start_date
        null,   							-- def_acctg_end_date
        null,   							-- def_acctg_number_of_periods
        null,   							-- def_acctg_period_type
        P_Invoice_Header_Rec.set_of_books_id,   			-- set_of_books_id
        zls.tax_amt,   							-- amount
        DECODE(P_Invoice_Header_Rec.invoice_currency_code,
               l_base_currency_code, NULL,
               zls.tax_amt_funcl_curr),    				-- base_amount
        null,   							-- rounding_amt
        null,   							-- quantity_invoiced
        null,   							-- unit_meas_lookup_code
        null,   							-- unit_price
        l_wfapproval_status,   						-- wfapproval_status
        'N',   								-- discarded_flag
        null,   							-- original_amount
        null,   							-- original_base_amount
        null,   							-- original_rounding_amt
        'N',   								-- cancelled_flag
        DECODE(ap.type_1099,
               '','',
               DECODE(l_combined_filing_flag,
                      'N', '',
                      DECODE(l_income_tax_region_flag,
                             'Y', aps.state,
                             l_income_tax_region))),  			-- income_tax_region
        ap.type_1099,   						-- type_1099
        null,   							-- stat_amount
        zls.applied_from_trx_id,   					-- prepay_invoice_id
        zls.applied_from_line_id,   					-- prepay_line_number
        prepay.invoice_includes_prepay_flag,   				-- invoice_includes_prepay_flag
        zls.adjusted_doc_trx_id,   					-- corrected_inv_id
        -- zls.adjusted_doc_line_id,   					-- corrected_line_number
        null,								-- corrected_line_number
        null,   							-- po_header_id
        null,   							-- po_line_id
        null,   							-- po_release_id
        null,   							-- po_line_location_id
        null,   							-- po_distribution_id
        zls.applied_to_trx_id,						-- rcv_transaction_id
        'N',   								-- final_match_flag
        null,   							-- assets_tracking_flag
        null,   							-- asset_book_type_code
        null,   							-- asset_category_id
        null,   							-- project_id
        null,   							-- task_id
        null,   							-- expenditure_type
        null,   							-- expenditure_item_date
        null,   							-- expenditure_organization_id
        null,   							-- pa_quantity
        null,   							-- pa_cc_ar_invoice_id
        null,   							-- pa_cc_ar_invoice_line_num
        null,   							-- pa_cc_processed_code
        null,   							-- award_id
        DECODE(l_awt_include_tax_amt,
               'N', null,
               DECODE(zls.applied_from_trx_id,
                      null, P_Invoice_Header_Rec.awt_group_id,
                      prepay.awt_group_id)),   				-- awt_group_id
        null,   							-- reference_1
        null,   							-- reference_2
        null,   							-- receipt_verified_flag
        null,   							-- receipt_required_flag
        null,   							-- receipt_missing_flag
        null,   							-- justification
        null,   							-- expense_group
        null,   							-- start_expense_date
        null,   							-- end_expense_date
        null,   							-- receipt_currency_code
        null,   							-- receipt_conversion_rate
        null,   							-- receipt_currency_amount
        null,   							-- daily_amount
        null,   							-- web_parameter_id
        null,   							-- adjustment_reason
        null,   							-- merchant_document_number
        null,   							-- merchant_name
        null,   							-- merchant_reference
        null,   							-- merchant_tax_reg_number
        null,								-- merchant_taxpayer_id
        null,								-- country_of_supply
        null,								-- credit_card_trx_id
        null,								-- company_prepaid_invoice_id
        null,								-- cc_reversal_flag
        l_sysdate,							-- creation_date
        l_user_id,   							-- created_by
        l_user_id,   							-- last_updated_by
        l_sysdate,   							-- last_update_date
        l_login_id,   							-- last_update_login
        null,   							-- program_application_id
        null,   							-- program_id
        null,   							-- program_update_date
        null,   							-- request_id
        zls.attribute_category,   					-- attribute_category
        zls.attribute1,   						-- attribute1
        zls.attribute2,   						-- attribute2
        zls.attribute3,   						-- attribute3
        zls.attribute4,   						-- attribute4
        zls.attribute5,   						-- attribute5
        zls.attribute6,   						-- attribute6
        zls.attribute7,   						-- attribute7
        zls.attribute8,   						-- attribute8
        zls.attribute9,   						-- attribute9
        zls.attribute10,   						-- attribute10
        zls.attribute11,   						-- attribute11
        zls.attribute12,   						-- attribute12
        zls.attribute13,   						-- attribute13
        zls.attribute14,   						-- attribute14
        zls.attribute15,   						-- attribute15
        zls.global_attribute_category,   				-- global_attribute_category
        zls.global_attribute1,   					-- global_attribute1
        zls.global_attribute2,   					-- global_attribute2
        zls.global_attribute3,   					-- global_attribute3
        zls.global_attribute4,   					-- global_attribute4
        zls.global_attribute5,   					-- global_attribute5
        zls.global_attribute6,   					-- global_attribute6
        zls.global_attribute7,   					-- global_attribute7
        zls.global_attribute8,   					-- global_attribute8
        zls.global_attribute9,   					-- global_attribute9
        zls.global_attribute10,   					-- global_attribute10
        zls.global_attribute11,   					-- global_attribute11
        zls.global_attribute12,   					-- global_attribute12
        zls.global_attribute13,   					-- global_attribute13
        zls.global_attribute14,   					-- global_attribute14
        zls.global_attribute15,   					-- global_attribute15
        zls.global_attribute16,   					-- global_attribute16
        zls.global_attribute17,   					-- global_attribute17
        zls.global_attribute18,   					-- global_attribute18
        zls.global_attribute19,   					-- global_attribute19
        zls.global_attribute20,   					-- global_attribute20
        null,   							-- control_amount
        null,   							-- assessable_value
        null,   							-- total_rec_tax_amount
        null,   							-- total_nrec_tax_amount
        null,   							-- total_rec_tax_amt_funcl_curr
        null,   							-- total_nrec_tax_amt_funcl_curr
        null,   							-- included_tax_amount
        null,   							-- primary_intended_use
        null,   							-- ship_to_location_id
        null,   							-- product_type
        null,   							-- product_category
        null,   							-- product_fisc_classification
        null,   							-- user_defined_fisc_class
        null,   							-- trx_business_category
        zls.summary_tax_line_id,   					-- summary_tax_line_id
        zls.tax_regime_code,   						-- tax_regime_code
        zls.tax,   							-- tax
        zls.tax_jurisdiction_code,   					-- tax_jurisdiction_code
        zls.tax_status_code,   						-- tax_status_code
        zls.tax_rate_id,   						-- tax_rate_id
        zls.tax_rate_code,   						-- tax_rate_code
        zls.tax_rate,   						-- tax_rate
        null   								-- tax_code_id
     FROM ap_invoices_all       ai,
          ap_suppliers          ap,
          ap_supplier_sites_all aps,
          zx_lines_summary      zls,
          ap_invoice_lines_all  prepay
    WHERE ai.invoice_id				= p_invoice_header_rec.invoice_id
      AND ai.vendor_id                          = ap.vendor_id
      AND ai.vendor_site_id                     = aps.vendor_site_id
      AND zls.application_id 			= 200
      AND zls.entity_code 			= 'AP_INVOICES'
      AND zls.event_class_code			IN ('STANDARD INVOICES', 'PREPAYMENT INVOICES', 'EXPENSE REPORTS')
      AND zls.trx_id 				= ai.invoice_id
      AND NVL(zls.tax_amt_included_flag, 'N') 	= 'N'
      AND NVL(zls.self_assessed_flag, 'N') 	= 'N'
      AND NVL(zls.reporting_only_flag, 'N') 	= 'N'
      AND zls.applied_from_trx_id  		= prepay.invoice_id(+)
      AND zls.applied_from_line_id 		= prepay.line_number(+)
      AND NOT EXISTS (SELECT il.summary_tax_line_id
                        FROM ap_invoice_lines_all il
                       WHERE il.invoice_id = ai.invoice_id
                         AND il.summary_tax_line_id = zls.summary_tax_line_id);

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;

      WHEN OTHERS THEN
        IF (SQLCODE <> -20001) THEN
          FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
          FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
          FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
          FND_MESSAGE.SET_TOKEN('PARAMETERS',
            ' P_Invoice_Id = '||P_Invoice_Header_Rec.invoice_id||
            ' P_Error_Code = '||P_Error_Code||
            ' P_Calling_Sequence = '||P_Calling_Sequence);
          FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
        END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;
    END;

    -------------------------------------------------------------------
    l_debug_info := 'Step 8: Delete exclusive tax lines if required';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    BEGIN
      DELETE ap_invoice_lines_all ail
       WHERE ail.invoice_id = P_Invoice_Header_Rec.invoice_id
         AND ail.line_type_lookup_code = 'TAX'
         AND NOT EXISTS (SELECT ls.summary_tax_line_id
                           FROM zx_lines_summary ls
                          WHERE ls.summary_tax_line_id	= ail.summary_tax_line_id
                            AND ls.trx_id 		= ail.invoice_id
                            AND NVL(ls.tax_amt_included_flag, 'N') = 'N'
                            AND NVL(ls.self_assessed_flag,    'N') = 'N'
                            AND NVL(ls.reporting_only_flag,   'N') = 'N');

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;

      WHEN OTHERS THEN
        IF (SQLCODE <> -20001) THEN
          FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
          FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
          FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
          FND_MESSAGE.SET_TOKEN('PARAMETERS',
            ' P_Invoice_Id = '||P_Invoice_Header_Rec.invoice_id||
            ' P_Error_Code = '||P_Error_Code||
            ' P_Calling_Sequence = '||P_Calling_Sequence);
          FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
        END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;
    END;

    -------------------------------------------------------------------
    l_debug_info := 'Step 10: Update total_tax_amount and self_assessed tax';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -------------------------------------------------------------------
    /*Bug 8638881 added CASE in the below SQL to consider the case of invoice includes prepay*/
    BEGIN
      UPDATE ap_invoices_all ai
          SET (ai.total_tax_amount,
               ai.self_assessed_tax_amount) =
                   (SELECT SUM(DECODE(NVL(zls.self_assessed_flag, 'N'),
                            'N', case when exists (SELECT 'Prepay App Exists'
                                          FROM ap_invoice_lines_all prepay
                                         WHERE prepay.invoice_id = zls.trx_id
                                         AND prepay.line_type_lookup_code = 'PREPAY'
                                         AND prepay.prepay_invoice_id  = zls.applied_from_trx_id
                                         AND prepay.prepay_line_number = zls.applied_from_line_id
                                         AND prepay.invoice_includes_prepay_flag = 'Y'
                                         AND (prepay.discarded_flag is null
                                           or prepay.discarded_flag = 'N')) THEN
                                           0
                                        ELSE NVL(zls.tax_amt, 0) end,
                                       0)),
                        SUM(DECODE(NVL(zls.self_assessed_flag, 'N'),
                                   'Y', NVL(zls.tax_amt, 0),
                                    0))
                   FROM zx_lines_summary zls
            WHERE zls.application_id = 200
           AND zls.entity_code = 'AP_INVOICES'
           AND zls.event_class_code IN
              ('STANDARD INVOICES', 'PREPAYMENT INVOICES', 'EXPENSE REPORTS')
                  AND zls.trx_id   = ai.invoice_id
                  AND NVL(zls.reporting_only_flag, 'N') = 'N')
        WHERE ai.invoice_id = P_Invoice_Header_Rec.invoice_id
        RETURNING ai.total_tax_amount, ai.self_assessed_tax_amount
             INTO l_total_tax_amount, l_self_assessed_tax_amt;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;

      WHEN OTHERS THEN
        IF (SQLCODE <> -20001) THEN
          FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
          FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
          FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
          FND_MESSAGE.SET_TOKEN('PARAMETERS',
            ' P_Invoice_Id = '||P_Invoice_Header_Rec.invoice_id||
            ' P_Error_Code = '||P_Error_Code||
            ' P_Calling_Sequence = '||P_Calling_Sequence);
          FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
        END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;
    END;

    -----------------------------------------------------------------
    l_debug_info := 'Step 12: Update Invoice Includes Prepay Flag';
    IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
    END IF;
    -----------------------------------------------------------------

    /*added the case for bug 8638881*/
   UPDATE ap_invoice_lines_all tax
     SET tax.invoice_includes_prepay_flag = CASE WHEN EXISTS (SELECT 'Prepay App Exists'
                            FROM ap_invoice_lines_all prepay
                           WHERE prepay.invoice_id = tax.invoice_id
                             AND prepay.line_type_lookup_code = 'PREPAY'
                             AND prepay.prepay_invoice_id = tax.prepay_invoice_id
                             AND prepay.prepay_line_number = tax.prepay_line_number
                             AND prepay.invoice_includes_prepay_flag = 'Y'
                             AND (prepay.discarded_flag is null or
                                 prepay.discarded_flag = 'N')) THEN
                               'Y'
                            ELSE
                              'N'
                            END /*added the case for bug 8638881*/
   WHERE tax.invoice_id = P_Invoice_Header_Rec.Invoice_Id
    AND tax.line_type_lookup_code = 'TAX'
    AND tax.prepay_invoice_id is not null;

    RETURN TRUE;

  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          			' P_Invoice_Id = '      ||P_Invoice_Header_Rec.Invoice_Id||
          			' P_Error_Code = '      ||P_Error_Code||
          			' P_Calling_Sequence = '||P_Calling_Sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;

      APP_EXCEPTION.RAISE_EXCEPTION;

  END Return_Other_Charge_Lines;

--Bug 7570234 Start
/*=============================================================================
 |  FUNCTION - synchronize_for_doc_seq()
 |
 |  DESCRIPTION
 |      Public function that will call ZX_API_PUB.synchronize_tax_repository
 |      to make sync between AP and ZX
  *============================================================================*/
PROCEDURE synchronize_for_doc_seq
      (
            p_invoice_id       IN NUMBER ,
            p_calling_sequence IN VARCHAR2 ,
            x_return_status    OUT NOCOPY VARCHAR2)
IS

      l_debug_info                 VARCHAR2(240);
      l_api_name                   CONSTANT VARCHAR2(100) := 'Update';
      l_curr_calling_sequence      VARCHAR2(4000);

      l_message_count              NUMBER;
      l_message_data               VARCHAR2(2000) ;
      l_Error_Code                 VARCHAR2(2000) ;
      l_return_status              VARCHAR2(2000) ;
      l_sync_trx_rec               ZX_API_PUB.sync_trx_rec_type;
      l_sync_trx_lines_t           ZX_API_PUB.sync_trx_lines_tbl_type%type;

      --Bug8975892

      l_invoice_type_lookup_code   AP_INVOICES_ALL.invoice_type_lookup_code%type;
      l_quick_credit               AP_INVOICES_ALL.quick_credit%type;
      l_credited_invoice_id        AP_INVOICES_ALL.credited_invoice_id%type;
      l_credited_inv_rec           AP_INVOICES_ALL%ROWTYPE;

      --Bug8975892



      CURSOR c_trx
      IS
             SELECT
                  (CASE
                        WHEN ai.invoice_type_lookup_code IN('STANDARD' , 'CREDIT' , 'DEBIT' ,
                              'MIXED' , 'ADJUSTMENT' , 'PO PRICE ADJUST' , 'INVOICE REQUEST' ,
                              'CREDIT MEMO REQUEST' , 'RETAINAGE RELEASE','PAYMENT REQUEST')--Bug9122724
                        THEN 'STANDARD INVOICES'
                        WHEN(ai.invoice_type_lookup_code='PREPAYMENT')
                        THEN 'PREPAYMENT INVOICES'
                        WHEN ai.invoice_type_lookup_code='EXPENSE REPORT'
                        THEN 'EXPENSE REPORTS'
                  END) event_class_code
                ,
                  (CASE
                        WHEN ai.invoice_type_lookup_code IN('STANDARD' , 'CREDIT' , 'DEBIT' ,
                              'MIXED' , 'ADJUSTMENT' , 'PO PRICE ADJUST' , 'INVOICE REQUEST' ,
                              'CREDIT MEMO REQUEST' , 'RETAINAGE RELEASE','PAYMENT REQUEST')--Bug9122724
                        THEN 'STANDARD '
                        WHEN(ai.invoice_type_lookup_code='PREPAYMENT')
                        THEN 'PREPAYMENT '
                        WHEN ai.invoice_type_lookup_code='EXPENSE REPORT'
                        THEN 'EXPENSE REPORT '
                  END) || 'UPDATED' event_type_code
                , ai.invoice_id trx_id
                , ai.invoice_num trx_number
                , SUBSTRB(ai.description , 1 , 240) trx_description
                , ai.doc_sequence_id doc_seq_id
                , doc.name doc_seq_name
                , ai.doc_sequence_value doc_seq_value
                , ai.batch_id batch_source_id
                , NULL batch_source_name
                , NULL trx_type_description
                , ai.invoice_date trx_communicated_date
                , ai.terms_date trx_due_date
                , ai.supplier_tax_invoice_number supplier_tax_invoice_number
                , ai.supplier_tax_invoice_date supplier_tax_invoice_date
                , ai.supplier_tax_exchange_rate supplier_exchange_rate
                , ai.tax_invoice_internal_seq tax_invoice_number
                , ai.tax_invoice_recording_date tax_invoice_date
                , ai.tax_invoice_internal_seq tax_invoice_number
                , ai.invoice_type_lookup_code
                , ai.quick_credit
                , ai.credited_invoice_id
               FROM ap_invoices_all ai
                   , fnd_document_sequences doc
              WHERE ai.invoice_id=p_invoice_id
                AND ai.doc_sequence_id=doc.doc_sequence_id (+);

BEGIN

      --Print(l_api_name,'AP_ETAX_SERVICES_PKG.synchronize_for_doc_seq');
      l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.synchronize_for_doc_seq  <- '||p_calling_sequence;
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_curr_calling_sequence);
      END IF;

      l_debug_info := 'Step. 1 Open c_trx cursor';

      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;

      l_sync_trx_rec.application_id:=200;
      l_sync_trx_rec.entity_code   :='AP_INVOICES';

      IF p_invoice_id  IS NOT NULL THEN

        l_debug_info := 'Step 2. The invoice is  '||p_invoice_id;
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        --Print(l_api_name,l_debug_info);

            OPEN c_trx;

            FETCH c_trx INTO
                  l_sync_trx_rec.event_class_code
                , l_sync_trx_rec.event_type_code
                , l_sync_trx_rec.trx_id
                , l_sync_trx_rec.trx_number
                , l_sync_trx_rec.trx_description
                , l_sync_trx_rec.doc_seq_id
                , l_sync_trx_rec.doc_seq_name
                , l_sync_trx_rec.doc_seq_value
                , l_sync_trx_rec.batch_source_id
                , l_sync_trx_rec.batch_source_name
                , l_sync_trx_rec.trx_type_description
                , l_sync_trx_rec.trx_communicated_date
                , l_sync_trx_rec.trx_due_date
                , l_sync_trx_rec.supplier_tax_invoice_number
                , l_sync_trx_rec.supplier_tax_invoice_date
                , l_sync_trx_rec.supplier_exchange_rate
                , l_sync_trx_rec.tax_invoice_number
                , l_sync_trx_rec.tax_invoice_date
                , l_sync_trx_rec.tax_invoice_number
                , l_invoice_type_lookup_code
                , l_quick_credit
                , l_credited_invoice_id;


        --Bug8975892

        IF (l_invoice_type_lookup_code IN ('AWT','INTEREST')) THEN
           l_debug_info := 'Step 2.1. Exiting with Success since AWT/Interest Invoice ';
           IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
              FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
           END IF;
           --Print(l_api_name,l_debug_info);
           x_return_status:= FND_API.G_RET_STS_SUCCESS;
           RETURN ;
        END IF;

        IF (l_quick_credit = 'Y' AND l_credited_invoice_id IS NOT NULL)THEN
           IF NOT tax_distributions_exist(p_invoice_id  => l_credited_invoice_id) THEN
              l_debug_info := 'Step 2.2. Exiting with Success since Quick Invoice With no tax';
              IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                 FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
              END IF;
              --Print(l_api_name,l_debug_info);
              x_return_status:= FND_API.G_RET_STS_SUCCESS;
              RETURN;
           END IF;
        END IF;

        --Bug8975892

        --Bug9122724
        IF NVL(l_quick_credit,'N') = 'N' THEN
           IF NOT (AP_ETAX_UTILITY_PKG.Is_Tax_Already_Calc_Inv(
	                 P_Invoice_Id           => p_invoice_id,
	                 P_Calling_Sequence     => l_curr_calling_sequence)) THEN
                        l_debug_info := 'Step 2.3. Tax Already Calculated Flag is N';
                        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
                           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
                        END IF;
                        x_return_status:= FND_API.G_RET_STS_SUCCESS;
              RETURN;
           END IF;
        END IF;
        --Bug9122724

        l_debug_info := 'Step 3. Before calling ZX_API_PUB.synchronize_tax_repository() API ';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        --Print(l_api_name,l_debug_info);


            ZX_API_PUB.synchronize_tax_repository(
                               p_api_version        =>  1.0
                             , p_init_msg_list      =>  FND_API.G_FALSE
                             , p_commit             =>  FND_API.G_FALSE
                             , p_validation_level   =>  FND_API.G_VALID_LEVEL_FULL
                             , x_return_status      =>  l_return_status
                             , x_msg_count          =>  l_message_count
                             , x_msg_data           =>  l_message_data
                             , p_sync_trx_rec       =>  l_sync_trx_rec
                             , p_sync_trx_lines_tbl =>  l_sync_trx_lines_t) ;

            l_debug_info := 'Step 4. Retun status is '||l_return_status;
            IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
            END IF;
            --Print(l_api_name,l_debug_info);

            IF (l_return_status = FND_API.G_RET_STS_SUCCESS) then
                x_return_status:= FND_API.G_RET_STS_SUCCESS;
            ELSE
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
                IF NOT(AP_ETAX_UTILITY_PKG.Return_Error_Messages(
                       P_All_Error_Messages  => 'Y',
                       P_Msg_Count           => l_message_count,
                       P_Msg_Data            => l_message_data,
                       P_Error_Code          => l_Error_Code,
                       P_Calling_Sequence    => l_curr_calling_sequence)) THEN

                     NULL;

                END IF;
            END IF;

            CLOSE c_trx;
      ELSE -- IF p_invoice_id  IS NOT NULL THEN

        l_debug_info := 'Step 5. Invoice ID is null';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;
        --Print(l_api_name,l_debug_info);

        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',' P_Invoice_Id = '||p_invoice_id||
                              ' l_curr_calling_sequence = '||l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);

        APP_EXCEPTION.RAISE_EXCEPTION;

      END IF;  -- IF p_invoice_id  IS NOT NULL THEN

        l_debug_info := 'Step 6. End of the API';
        Print(l_api_name,l_debug_info);
  EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Id = '||p_invoice_id||
          ' l_Error_Code ='||l_Error_Code||
          ' l_curr_calling_sequence = '||l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;
      APP_EXCEPTION.RAISE_EXCEPTION;
END synchronize_for_doc_seq;
--Bug 7570234 End

--Bug9819170
/*=============================================================================
 |  FUNCTION - synchronize_tax_dff()
 |
 |  DESCRIPTION
 |      Public function that will call ZX_NEW_SERVICES_PKG.SYNC_TAX_DIST_DFF()
 |      to sync DFF on Tax distribution from AP to Ebtax
  *============================================================================*/
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
             x_return_status              OUT NOCOPY VARCHAR2)
IS

      l_debug_info                 VARCHAR2(2000);
      l_api_name                   CONSTANT VARCHAR2(100) := 'synchronize_tax_dff';
      l_curr_calling_sequence      VARCHAR2(4000);

      l_message_count              NUMBER;
      l_message_data               VARCHAR2(2000) ;
      l_Error_Code                 VARCHAR2(2000) ;
      l_return_status              VARCHAR2(2000) ;

      l_detail_tax_dist_id     AP_INVOICE_DISTRIBUTIONS_ALL.DETAIL_TAX_DIST_ID%TYPE;
      l_line_type_lookup_code  AP_INVOICE_DISTRIBUTIONS_ALL.LINE_TYPE_LOOKUP_CODE%TYPE;
      l_inv_dist_id            AP_INVOICE_DISTRIBUTIONS_ALL.INVOICE_DISTRIBUTION_ID%TYPE;
      l_related_id             AP_INVOICE_DISTRIBUTIONS_ALL.RELATED_ID%TYPE;


      l_sync_trx_dist_dff_t        ZX_NEW_SERVICES_PKG.tax_dist_dff_type%TYPE;

BEGIN

      l_curr_calling_sequence := 'AP_ETAX_SERVICES_PKG.synchronize_tax_dff  <- '||p_calling_sequence;

      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_curr_calling_sequence);
      END IF;

      l_debug_info := 'Synching DFFS For Invoice Id '||p_invoice_id;

      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;

      IF p_invoice_dist_id IS NULL THEN

         l_debug_info := 'Get the details based on Invoice Line Number, Distribution Line Number and Invoice Id ';

         IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
         END IF;

          l_debug_info := 'Invoice Line Number '||p_invoice_line_number||
                          ' and Distribution Line Number '||p_distribution_line_number;

          IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
             FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
          END IF;


         BEGIN

           SELECT line_type_lookup_code,detail_tax_dist_id,
                  invoice_distribution_id,related_id
             INTO l_line_type_lookup_code,l_detail_tax_dist_id,
                  l_inv_dist_id,l_related_id
             FROM ap_invoice_distributions_all
            WHERE invoice_id               = p_invoice_id
              AND distribution_line_number = p_distribution_line_number
              AND invoice_line_number      = p_invoice_line_number;

         EXCEPTION
              WHEN OTHERS THEN
                   APP_EXCEPTION.RAISE_EXCEPTION;
         END;



      END IF;


      l_debug_info := 'Step. 1 Local Related Dist Id '||l_related_id||
                      ', Parameter Related Dist Id '||p_related_id||
                      ', Local Invoice Dist Id '||l_inv_dist_id||
                      ', Parameter Invoice Dist Id '||p_invoice_dist_id||
                      ', Local Detail Tax Dist Id '||l_detail_tax_dist_id||
                      ', Parameter Detail Tax Dist Id '||p_detail_tax_dist_id||
                      ', Local Line Type Lookup Code '||l_line_type_lookup_code||
                      ', Parameter Line Type Lookup Code '||p_line_type_lookup_code;

      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;


      l_related_id            := NVL(l_related_id,p_related_id);
      l_line_type_lookup_code := NVL(l_line_type_lookup_code,p_line_type_lookup_code);
      l_detail_tax_dist_id    := NVL(l_detail_tax_dist_id,p_detail_tax_dist_id);
      l_inv_dist_id           := NVL(l_inv_dist_id,p_invoice_dist_id);


      l_debug_info := 'Step. 2 All Local : Related Dist Id '||l_related_id||
                      ', Invoice Dist Id '||l_inv_dist_id||
                      ', Detail Tax Dist Id '||l_detail_tax_dist_id||
                      ', Line Type Lookup Code '||l_line_type_lookup_code;


      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
      END IF;


      IF (l_related_id IS NULL OR l_related_id = l_inv_dist_id)
         AND (l_line_type_lookup_code IN ('REC_TAX','NONREC_TAX','TRV','TERV','TIPV'))
         AND (l_detail_tax_dist_id IS NOT NULL) THEN

        l_debug_info := 'Step 2. Before calling ZX_API_PUB.SYNC_TAX_DIST_DFF() API ';
        IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
        END IF;

            l_sync_trx_dist_dff_t.attribute1(1) :=  P_ATTRIBUTE1;
            l_sync_trx_dist_dff_t.attribute2(1) :=  P_ATTRIBUTE2;
            l_sync_trx_dist_dff_t.attribute3(1) :=  P_ATTRIBUTE3;
            l_sync_trx_dist_dff_t.attribute4(1) :=  P_ATTRIBUTE4;
            l_sync_trx_dist_dff_t.attribute5(1) :=  P_ATTRIBUTE5;
            l_sync_trx_dist_dff_t.attribute6(1) :=  P_ATTRIBUTE6;
            l_sync_trx_dist_dff_t.attribute7(1) :=  P_ATTRIBUTE7;
            l_sync_trx_dist_dff_t.attribute8(1) :=  P_ATTRIBUTE8;
            l_sync_trx_dist_dff_t.attribute9(1) :=  P_ATTRIBUTE9;
            l_sync_trx_dist_dff_t.attribute10(1) := P_ATTRIBUTE10;
            l_sync_trx_dist_dff_t.attribute11(1) := P_ATTRIBUTE11;
            l_sync_trx_dist_dff_t.attribute12(1) := P_ATTRIBUTE12;
            l_sync_trx_dist_dff_t.attribute13(1) := P_ATTRIBUTE13;
            l_sync_trx_dist_dff_t.attribute14(1) := P_ATTRIBUTE14;
            l_sync_trx_dist_dff_t.attribute15(1) := P_ATTRIBUTE15;
            l_sync_trx_dist_dff_t.attribute_category(1) := P_attribute_category;
            l_sync_trx_dist_dff_t.rec_nrec_tax_dist_id(1) := l_detail_tax_dist_id ;


            IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
               l_debug_info := '1 '||  l_sync_trx_dist_dff_t.attribute1(1);
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
               l_debug_info := '2 '||l_sync_trx_dist_dff_t.attribute2(1) ;
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
               l_debug_info := '3 '||l_sync_trx_dist_dff_t.attribute3(1);
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
               l_debug_info := '4 '||l_sync_trx_dist_dff_t.attribute4(1);
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
               l_debug_info := '5 '||l_sync_trx_dist_dff_t.attribute5(1);
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
               l_debug_info := '6 '||l_sync_trx_dist_dff_t.attribute6(1);
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
               l_debug_info := '7 '||l_sync_trx_dist_dff_t.attribute7(1);
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
               l_debug_info := '8 '||l_sync_trx_dist_dff_t.attribute8(1);
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
               l_debug_info := '9 '||l_sync_trx_dist_dff_t.attribute9(1);
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
               l_debug_info := '10 '||l_sync_trx_dist_dff_t.attribute10(1);
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
               l_debug_info := '11 '||l_sync_trx_dist_dff_t.attribute11(1);
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
               l_debug_info := '12 '||l_sync_trx_dist_dff_t.attribute12(1);
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
               l_debug_info := '13 '||l_sync_trx_dist_dff_t.attribute14(1);
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
               l_debug_info := '14 '||l_sync_trx_dist_dff_t.attribute14(1);
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
               l_debug_info := '15 '||l_sync_trx_dist_dff_t.attribute15(1);
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
               l_debug_info := 'Attrib Cat '||l_sync_trx_dist_dff_t.attribute_category(1);
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
               l_debug_info := 'Detail Tax Dist Id '||l_sync_trx_dist_dff_t.rec_nrec_tax_dist_id(1);
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
            END IF;

            ZX_NEW_SERVICES_PKG.SYNC_TAX_DIST_DFF(
                               p_api_version        =>  1.0
                             , p_init_msg_list      =>  FND_API.G_FALSE
                             , p_commit             =>  FND_API.G_FALSE
                             , p_validation_level   =>  FND_API.G_VALID_LEVEL_FULL
                             , x_return_status      =>  l_return_status
                             , x_msg_count          =>  l_message_count
                             , x_msg_data           =>  l_message_data
                             , p_tax_dist_dff_tbl   =>  l_sync_trx_dist_dff_t);

            l_debug_info := 'Step 4. Retun status is '||l_return_status;
            IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
               FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,l_debug_info);
            END IF;

            IF (l_return_status = FND_API.G_RET_STS_SUCCESS) THEN
                x_return_status:= FND_API.G_RET_STS_SUCCESS;
            ELSE
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
                IF NOT(AP_ETAX_UTILITY_PKG.Return_Error_Messages(
                       P_All_Error_Messages  => 'Y',
                       P_Msg_Count           => l_message_count,
                       P_Msg_Data            => l_message_data,
                       P_Error_Code          => l_Error_Code,
                       P_Calling_Sequence    => l_curr_calling_sequence)) THEN

                     NULL;
                END IF;
            END IF;
     END IF;

EXCEPTION
    WHEN OTHERS THEN
      IF (SQLCODE <> -20001) THEN
        FND_MESSAGE.SET_NAME('SQLAP','AP_DEBUG');
        FND_MESSAGE.SET_TOKEN('ERROR',SQLERRM);
        FND_MESSAGE.SET_TOKEN('CALLING_SEQUENCE',l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('PARAMETERS',
          ' P_Invoice_Id = '||p_invoice_id||
          ' l_Error_Code ='||l_Error_Code||
          ' l_curr_calling_sequence = '||l_curr_calling_sequence);
        FND_MESSAGE.SET_TOKEN('DEBUG_INFO',l_debug_info);
      END IF;
      APP_EXCEPTION.RAISE_EXCEPTION;
END synchronize_tax_dff;
--Bug9819170

PROCEDURE Print
             (P_API_NAME   IN VARCHAR2,
              p_debug_info IN VARCHAR2) IS
BEGIN
  IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||p_api_name,p_debug_info);
  END IF;
END Print;

END AP_ETAX_SERVICES_PKG;
/