create or replace PACKAGE BODY  XX_AP_INV_BUILD_PO_LINES_PKG
AS

-- +===============================================================================================+
-- |                  Office Depot - Project Simplify                                              |
-- |                       WIPRO Technologies                                                      |
-- +===============================================================================================+
-- | Name :  XX_AP_INV_BUILD_PO_LINES_PKG                                                          |
-- | Description :  This package is used to create invoices distribution lines for PO invoices.    |
-- |                The procedure will use the PO number from the invoice header that is created   |
-- |                by an external interface.                                                      |
-- |                                                                                               |
-- |Change Record:                                                                                 |
-- |===============                                                                                |
-- |Version   Date           Author                 Remarks                                        |
-- |======   ==========     =============           =======================                        |
-- |1.0       09-oct-2007   Stedfield Thomas        Moved the procedure XX_AP_CREATE_PO_INV_LINES  |
-- |                                                from XXAPINVOICEVALIDATEPKG to this package as |
-- |                                                per the Defect ID 1936.                        |
-- |1.1       12-OCT-2007   Nandini Bhimana Boina   Changes for the defect # 2279                  |
-- |1.2       19-OCT-2007   Sambasiva Reddy D       Changes for the defect # 2280                  |
-- |1.3       25-OCT-2007   Radhika Raman           Changes made for CR 260, defect 2303;          |
-- |                                                Changes for tax proration                      |
-- |1.4       26-OCT-2007   Radhika Raman           Changed price column for Blanket PO            |
-- |                                                defect - 2280                                  |
-- |1.5       30-OCT-2007   Radhika Raman           Changes made to prorate tax for Blanket        |
-- |                                                releases. Proration is done for the quantity   |
-- |                                                (Quantity ordered - Quantity billed) for 2-way |
-- |                                                and (quantity delivered - quantity billed) for |
-- |                                                3-way -- Defect 2533                           |
-- |                                                                                               |
-- |1.6       24-JAN-2008   Aravind A.              Fixed defect 3686                              |
-- |1.7       13-FEB-2008   KK                      Fixed defect 4505                              |
-- |1.8       22-FEB-2008   KK                      Fixed defect 4748,4782                         |
-- |1.6       03-MAR-2008   Aravind A.              Fixed defect 5000                              |
-- |1.7       08-MAY-2008   Hemalatha S             Fixed defect 6683                              |
-- |1.8       13-JUN-2008   Aravind A.              Fixed defect 7937                              |
-- |1.9       28-JUL-2008   Ram                     Fixed defect 8916                              |
-- |2.0       25-AUG-2008   Aravind A.              Fixed defect 9420                              |
-- |2.1       21-OCT-2008   Aravind A.              Fixed defect 5309                              |
-- |2.2       05-JAN-2009   Aravind A.              Fixed defect 12718                             |
-- |2.3       23-FEB-2009   P. Marco	            Defect 13332 Added default value for ln_frieght|
-- |                                                _cnt.  Without value being reset the records   |
-- |                                                were incorrectly rolling back to savepoint     |
-- |2.4       04-MAR-2009   P. Marco                Defect 13461 an exception to the CR 359        |
-- |                                                requirements by evaluating if the PO is 3-way  |
-- |                                                match and has NO  unbilled receipt lines       |
-- |2.5       02-AUG-2010   p. Marco                AP - E1281 / E1282 (CR-729) - TDM Invoice Build|
-- |                                                Report corrections and Ability to manage In-   |
-- |                                                voices w/issues                                | 
-- |2.6       27-Feb-2014   Darshini                I0013 - Modified for Defect#27988 and 28294    |
-- |2.7       16-mAR-2014   Jay Gupta               Defect# 28912 - performance                    |
-- |2.8		  19-Mar-2014	SGorla					Defect# 28765 - Invoice validation perf.Tax    |
-- |												                issue due to prorate flag to N |
-- |2.9       27-Oct-2015   Harvinder Rakhra        Retrofit R12.2                                 |
-- |3.0       24-Mar-2017   Havish Kasina           Code Changes for Trade Invoice changes         |
-- |3.1       04-Oct-2017   Havish Kasina           Rounding the Unit price and Line amount by 2   |
-- |                                                digits                                         |
-- |3.2       10-Oct-2017   Havish Kasina           Added the logic to get the Converted Dropship  |
-- |                                                TDM invoices.                                  | 
-- |3.3       01-Dec-2017   Havish Kasina           Added the new condition to handle the freight  |
-- |                                                line for TDM Unapproved invoices               |
-- |3.4       11-Dec-2017   Havish Kasina           Added the UOM in the Invoice Interface         |
-- |3.5       18-Apr-2018   Havish Kasina           Added the ROUND function for line amount field |
-- |                                                in ap_invoice_lines_interface table            |
-- |3.6       03-AUG-2018   Vivek Kumar             Added logic for NAIT-48588                     |
-- +===============================================================================================+


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
   PROCEDURE xx_ap_create_po_inv_lines (p_group_id IN VARCHAR2)
   IS
-- -------------------------------------------------------------------------
-- Declare Local Constants
-- -------------------------------------------------------------------------
      l_reject_code_table       CONSTANT ap_interface_rejections.parent_table%TYPE
                                                   := 'AP_INVOICES_INTERFACE';
      l_reject_code_type                 VARCHAR2(200)
                                                   := 'INVALID PO NUM'; -- changed the variable from constant for Defect 4505
      l_inv_item_line_type      CONSTANT ap_invoice_lines_interface.line_type_lookup_code%TYPE
                                                                    := 'ITEM';
      l_inv_tax_line_type       CONSTANT ap_invoice_lines_interface.line_type_lookup_code%TYPE
                                                                     := 'TAX';
      l_inv_freight_line_type   CONSTANT ap_invoice_lines_interface.line_type_lookup_code%TYPE
                                                                 := 'FREIGHT';
     -- l_inv_match_option      CONSTANT ap_invoice_lines_interface.match_option%TYPE  := 'P';
       --------- Commented the hardcoding and fetching the invoice line match option from P
       ----------O shipment line for defect # 2279

-- -------------------------------------------------------------------------
-- Local Variables
-- -------------------------------------------------------------------------
      lc_error_msg                       VARCHAR2 (2000);
      lc_error_loc                       VARCHAR2 (2000);
      lc_error_debug                     VARCHAR2 (2000);
      lc_unbilled_amount                 NUMBER;
      lc_invoice_number                  ap_invoices_all.invoice_num%TYPE;
      lc_tax_code                        ap_invoice_lines_interface.tax_code%TYPE;
      ln_freight_cnt                     ap_invoices_all.invoice_id%TYPE;
      ln_invoice_line_id                 ap_invoice_lines_interface.invoice_line_id%TYPE;
      ln_tax_invoice_line_id             ap_invoice_lines_interface.invoice_line_id%TYPE;
      ln_tax_prorate_difference          ap_invoice_lines_interface.amount%TYPE;
      ln_total_tax_amount                ap_invoice_lines_interface.amount%TYPE;
      ln_total_tax_line_amount           ap_invoice_lines_interface.amount%TYPE;
      lc_inv_match_option                ap_invoice_lines_interface.match_option%TYPE;
      ln_translation_id                  NUMBER;
      ln_tax                             NUMBER;
      lc_inv_rejected                    CHAR(1) := 'N'; -- added for Defect 4505
      lc_tax_line_exists                 CHAR(1) := 'N'; -- added for Defect 4505
      ln_tax_lines                       NUMBER;  -- added for Defect 4505
      lc_hdr_message                     VARCHAR2(300);
      lc_par_rcv_po                      CHAR(1) := 'Y';
      ln_par_rcv_po_cnt                  NUMBER :=0;
      ln_dff_tax_total                   NUMBER := 0;
      ln_dff_tax_total_2way              NUMBER := 0;
      ln_tot_tax_per_inv                 NUMBER := 0;
      ln_lar_tax_inv_ln_id               ap_invoice_lines_interface.invoice_line_id%TYPE;
      ln_lar_tax_amt                     NUMBER := 0;
      ln_line_number                     NUMBER := 1;
      ln_po_dist_tot                     NUMBER := 0;     --Added for defect 5309
      ln_freight_amt                     NUMBER := 0;     --Added for defect 5309
      ln_tax_amt                         NUMBER := 0;     --Added for defect 5309
      lc_inv_var_flag                    VARCHAR2(1) := 'N';     --Added for defect 5309
      lc_inv_var_account                 ap_invoice_lines_interface.dist_code_concatenated%TYPE;
      LN_MAX_LINE_NUMBER                 AP_INVOICE_LINES_INTERFACE.LINE_NUMBER%TYPE := 0;
      LC_INV_MATCH_EXP_FLAG              VARCHAR2(1) := 'Y';  -- Added for defect 13461
      LN_REL_UNAPPRV_FLG                 VARCHAR2(50);          --added per CR728  
      LC_AUTH_OUTPUT                     VARCHAR2(50);          --added per CR728    
 
-- -------------------------------------------------------------------------
-- Cursor to obtain a list of unprocessed PO invoices from interface table
-- -------------------------------------------------------------------------
      CURSOR lcu_po_invoices
      IS
         SELECT api.invoice_id
                ,api.invoice_num
                ,api.po_number
                ,api.last_updated_by
                ,api.last_update_date
                ,api.last_update_login
                ,api.created_by
                ,api.creation_date
                ,poha.po_header_id
                ,NVL(poha.authorization_status, 'INCOMPLETE') authorization_status  -- Added NVL() per CR729 
                ,poha.closed_code                               -- added per CR729
                ,poha.type_lookup_code
                ,poha.approved_flag                              -- added to handle defect 4505
                ,api.attribute15 -- added to handle defect 4782 -- blanket PO with release
                ,api.invoice_amount    --Added for defect 5309
                ,api.org_id            --Added for defect 5309
           FROM ap_invoices_interface api
                ,po_headers_all poha
          WHERE api.GROUP_ID = p_group_id
            AND api.po_number IS NOT NULL
            AND NVL (api.status, 'x') <> 'PROCESSED'
            AND api.po_number = poha.segment1
            AND api.org_id = poha.org_id;     --Fixed defect 3686

       LR_PO_INVOICES_REC                 LCU_PO_INVOICES%ROWTYPE;
       ln_mixed_type_cnt                  NUMBER;  -- added per CR729

-- -------------------------------------------------------------------------
-- Cursor to obtain a list of PO lines
-- -------------------------------------------------------------------------
      CURSOR lcu_invoice_lines (p_invoice_id NUMBER, p_release_num NUMBER)
      IS
-- -------------------------------------------------------------------------
--    Select Statement Added to get Blanket PO releses for the Defect : 2280
-- -------------------------------------------------------------------------

         SELECT api.invoice_id
                ,api.po_number
                ,api.last_updated_by
                ,api.last_update_date
                ,api.created_by
                ,api.creation_date
                ,api.last_update_login
                ,api.org_id
                ,pola.line_num
                ,poll.shipment_num
                ,poll.match_option
                --poll.tax_code_id,   -- defect 2303
                --aptc.NAME tax_code
                ,poll.inspection_required_flag
                ,poll.receipt_required_flag
                ,poda.distribution_num
                ,DECODE(NVL(poda.quantity_ordered,0)
                        ,0
                        ,poda.amount_ordered
                        ,poda.quantity_ordered) quantity_ordered         --Fixed defect 7937
                ,NVL(DECODE(NVL(poda.quantity_ordered,0)
                        ,0
                        ,poda.amount_billed
                        ,poda.quantity_billed),0) quantity_billed        --Fixed defect 7937
                ,NVL(DECODE(NVL(poda.quantity_ordered,0)
                        ,0
                        ,poda.amount_delivered
                        ,poda.quantity_delivered),0) quantity_delivered  --Fixed defect 7937
                --pola.unit_price,
                ,NVL(poll.price_override,1) unit_price -- defect 2280
                ,POLL.PRICE_OVERRIDE ACTUAL_UNIT_PRICE                   --Added for Defect 8916
                ,pra.AUTHORIZATION_STATUS          -- added per CR729
                ,pra.po_release_id 
         FROM   ap_invoices_interface api
                ,po_headers_all poha
                ,po_lines_all pola
                ,po_line_locations_all poll
                ,po_distributions_all poda
                --ap_tax_codes_all aptc,  -- defect 2303
                ,po_releases_all  pra
         WHERE  api.invoice_id = p_invoice_id
         AND    api.po_number = poha.segment1
         AND    api.org_id = poha.org_id            --Added for defect 3686
         AND    poha.po_header_id = pola.po_header_id
         AND    poha.po_header_id = pra.po_header_id
         AND    pola.po_line_id = poll.po_line_id
         AND    UPPER(SUBSTR(poll.match_option,1,1)) = 'P'
         AND    poll.line_location_id = poda.line_location_id
         AND    pra.po_release_id = poda.po_release_id
         AND (DECODE(NVL(poda.quantity_ordered,0)
                        ,0
                        ,poda.amount_ordered
                        ,poda.quantity_ordered) 
                        - NVL(DECODE(NVL(poda.quantity_ordered,0)
                                         ,0
                                         ,poda.amount_billed
                                         ,poda.quantity_billed),0)) > 0
         --AND    (poda.quantity_ordered - poda.quantity_billed) > 0
         --AND    poll.tax_code_id = aptc.tax_id(+)  -- defect 2303
         AND    poha.type_lookup_code = 'BLANKET'
         AND    pra.release_num = p_release_num
         UNION ALL
         SELECT api.invoice_id
                ,api.po_number
                ,api.last_updated_by
                ,api.last_update_date
                ,api.created_by
                ,api.creation_date
                ,api.last_update_login
                ,api.org_id
                ,pola.line_num
                ,poll.shipment_num
                ,poll.match_option
                -- poll.tax_code_id,
                -- aptc.NAME tax_code,  --defect 2303
                ,poll.inspection_required_flag
                ,poll.receipt_required_flag
                ,poda.distribution_num
                ,DECODE(NVL(poda.quantity_ordered,0)
                        ,0
                        ,poda.amount_ordered
                        ,poda.quantity_ordered) quantity_ordered         --Fixed defect 7937
                ,NVL(DECODE(NVL(poda.quantity_ordered,0)
                        ,0
                        ,poda.amount_billed
                        ,poda.quantity_billed),0) quantity_billed        --Fixed defect 7937
                ,NVL(DECODE(NVL(poda.quantity_ordered,0)
                        ,0
                        ,poda.amount_delivered
                        ,poda.quantity_delivered),0) quantity_delivered  --Fixed defect 7937
                ,NVL(pola.unit_price,1)                                  --Fixed defect 7937
                ,pola.unit_price actual_unit_price                       --Added for Defect 8916
                --------------- pola.unit_price
                -----------    * (poda.quantity_ordered - poda.quantity_billed) unbilled_amount
                ---------- unbilled amount calculated based on match approval level for the defect # 2279
                ,NULL    -- added per CR729
                ,NULL    -- Added for the Defect : 2280
         FROM   ap_invoices_interface api
                ,po_headers_all poha
                ,po_lines_all pola
                ,po_line_locations_all poll
                ,po_distributions_all poda
                --ap_tax_codes_all aptc -- defect 2303
         WHERE  api.invoice_id = p_invoice_id
         AND    api.po_number = poha.segment1
         AND    api.org_id = poha.org_id                  --Added for defect 3686
         AND    poha.po_header_id = pola.po_header_id
         AND    pola.po_line_id = poll.po_line_id
         AND    UPPER(SUBSTR(poll.match_option,1,1)) = 'P'
         AND    poll.line_location_id = poda.line_location_id
         AND (DECODE(NVL(poda.quantity_ordered,0)
                        ,0
                        ,poda.amount_ordered
                        ,poda.quantity_ordered) 
                        - NVL(DECODE(NVL(poda.quantity_ordered,0)
                                         ,0
                                         ,poda.amount_billed
                                         ,poda.quantity_billed),0)) > 0
         --AND    (poda.quantity_ordered - poda.quantity_billed) > 0
         --AND    poll.tax_code_id = aptc.tax_id(+)  --defect 2303
         AND    poha.type_lookup_code != 'BLANKET';  -- Added for the Defect : 2280


      -- added outer join Fixed Defect 1936
      lr_invoice_line_rec                lcu_invoice_lines%ROWTYPE;

-- -------------------------------------------------------------------------
-- Cursor obtain a list of ITEM lines to prorate taxes for
-- -------------------------------------------------------------------------
      CURSOR lcu_tax_lines ( p_invoice_id              NUMBER
                            --,p_total_tax_amount        NUMBER,
                            -- p_total_tax_line_amount   NUMBER  --defect 2533
                            )
      IS
         SELECT api.invoice_id
                ,api.po_number
                ,api.last_updated_by
                ,api.last_update_date
                ,api.created_by
                ,api.creation_date
                ,api.last_update_login
                ,api.org_id
                --  pola.unit_price * poda.quantity_ordered amount,
                ,NVL(pola.unit_price,1)
                --Commented for defect 7937
                /*poda.quantity_ordered, -- defect 2533 - the columns added to calculate tax for 2-way and 3-way separately
                poda.quantity_billed,
                poda.quantity_delivered,*/
                ,DECODE(NVL(poda.quantity_ordered,0)
                        ,0
                        ,poda.amount_ordered
                        ,poda.quantity_ordered) quantity_ordered         --Fixed defect 7937
                ,NVL(DECODE(NVL(poda.quantity_ordered,0)
                        ,0
                        ,poda.amount_billed
                        ,poda.quantity_billed),0) quantity_billed        --Fixed defect 7937
                ,NVL(DECODE(NVL(poda.quantity_ordered,0)
                        ,0
                        ,poda.amount_delivered
                        ,poda.quantity_delivered),0) quantity_delivered  --Fixed defect 7937
                ,poll.inspection_required_flag
                ,poll.receipt_required_flag
                -- Removed for defect 6683
                -- ROUND ( ( p_total_tax_amount * (  pola.unit_price * (poda.quantity_ordered - poda.quantity_billed) )
                     --    / p_total_tax_line_amount), 2  ) tax,
                     --defect 2533 --tax is being calculated outside based on 2-way and 3-way
                --gcc.segment1  || '.' || gcc.segment2 || '.' || gcc.segment3 || '.' || gcc.segment4
                -- || '.' || gcc.segment5|| '.'|| gcc.segment6 || '.' || gcc.segment7 charge_account,
                -- Added for defect 6683, Code combination id
               ,DECODE (poda.accrue_on_receipt_flag,
                           'Y', poda.accrual_account_id,
                           poda.code_combination_id
                          ) charge_account
               --,poda.attribute2 dff_tax_amount
			   ,NVL(poda.attribute2,poda.nonrecoverable_tax) dff_tax_amount --Commented and added for Defect# 27988 and 28294
               ,poha.segment1   po_num
               ,pola.line_num   po_line_number
               ,poll.shipment_num po_shipment_num
               ,poda.distribution_num po_distribution_num
               ,poda.project_id
               ,poda.task_id
               ,poda.expenditure_type
               ,poda.project_accounting_context
               ,poda.expenditure_organization_id
               ,poda.expenditure_item_date
               ,aili.line_group_number
               --Added the  charge account  for the tax lines from PO distribution line for Defect # 2021
         FROM   ap_invoices_interface api,
                po_headers_all poha,
                po_lines_all pola,
                po_line_locations_all poll,
                po_distributions_all poda,
                ap_invoice_lines_interface aili          --Defect 9420
                --gl_code_combinations gcc -- Removed for defect 6683
                -- Added the table to include charge account details for Defect # 2021
         WHERE  api.invoice_id = p_invoice_id
            AND api.invoice_id = aili.invoice_id
            AND aili.po_line_number = pola.line_num
            AND aili.po_shipment_num = poll.shipment_num
            AND aili.po_distribution_num = poda.distribution_num
            AND api.po_number = poha.segment1
            AND api.org_id = poha.org_id                 --Added for defect 3686
            AND poha.po_header_id = pola.po_header_id
            AND pola.po_line_id = poll.po_line_id
            --AND poll.tax_code_id IS NOT NULL  -- defect 2303
            AND poll.line_location_id = poda.line_location_id
            --AND NVL(TO_NUMBER(poda.attribute2),0) <> 0 -- changed for defect 4505
			AND NVL(TO_NUMBER(NVL(poda.attribute2,poda.nonrecoverable_tax)),0) <> 0 --Commented and added for Defect# 27988 and 28294
            AND (DECODE(NVL(poda.quantity_ordered,0)
                        ,0
                        ,poda.amount_ordered
                        ,poda.quantity_ordered) 
                        - NVL(DECODE(NVL(poda.quantity_ordered,0)
                                         ,0
                                         ,poda.amount_billed
                                         ,poda.quantity_billed),0)) > 0
            /* Removed for defect 6683
               AND gcc.code_combination_id =    -- Added the condition to join gl_code_combinations for Defect # 2021
                   DECODE (poda.accrue_on_receipt_flag,
                           'Y', poda.accrual_account_id,
                           poda.code_combination_id
                          )*/;


      CURSOR lcu_tax_lines_blanket (p_invoice_id NUMBER, p_release_num NUMBER)  -- defect 2533 -- added to calculate tax for blanket releases
      IS
         SELECT api.invoice_id
                ,api.po_number
                ,api.last_updated_by
                ,api.last_update_date
                ,api.created_by
                ,api.creation_date
                ,api.last_update_login
                ,api.org_id
                ,NVL(poll.price_override,1) unit_price --defect 2533  --NVL added for defect 7937
                --Commented for defect 7937
                /*poda.quantity_ordered,
                poda.quantity_billed,
                poda.quantity_delivered,*/
                ,DECODE(NVL(poda.quantity_ordered,0)
                        ,0
                        ,poda.amount_ordered
                        ,poda.quantity_ordered) quantity_ordered         --Fixed defect 7937
                ,NVL(DECODE(NVL(poda.quantity_ordered,0)
                        ,0
                        ,poda.amount_billed
                        ,poda.quantity_billed),0) quantity_billed        --Fixed defect 7937
                ,NVL(DECODE(NVL(poda.quantity_ordered,0)
                        ,0
                        ,poda.amount_delivered
                        ,poda.quantity_delivered),0) quantity_delivered  --Fixed defect 7937
                ,poll.inspection_required_flag
                ,poll.receipt_required_flag
                --Removed for defect 6683
                --gcc.segment1  || '.' || gcc.segment2 || '.' || gcc.segment3 || '.' || gcc.segment4
                --|| '.' || gcc.segment5|| '.'|| gcc.segment6 || '.' || gcc.segment7 charge_account,
                --Added for defect 6683, Code combination id
                ,DECODE (poda.accrue_on_receipt_flag,
                        'Y',
                         poda.accrual_account_id,
                         poda.code_combination_id
                        ) charge_account
                --,poda.attribute2 dff_tax_amount
				,NVL(poda.attribute2,poda.nonrecoverable_tax) dff_tax_amount --Commented and added for Defect# 27988 and 28294
                ,poha.segment1   po_num
                ,pola.line_num   po_line_number
                ,poll.shipment_num po_shipment_num
                ,poda.distribution_num po_distribution_num
                ,poda.project_id
                ,poda.task_id
                ,poda.expenditure_type
                ,poda.project_accounting_context
                ,poda.expenditure_organization_id
                ,poda.expenditure_item_date
                ,aili.line_group_number    --Defect 9420
         FROM   ap_invoices_interface api
                ,po_headers_all poha
                ,po_lines_all pola
                ,po_line_locations_all poll
                ,po_distributions_all poda
                --gl_code_combinations gcc, --Removed for defect 6683
                ,po_releases_all pra
                ,ap_invoice_lines_interface aili    --Defect 9420
         WHERE  api.invoice_id = p_invoice_id
            AND api.invoice_id = aili.invoice_id
            AND aili.po_line_number = pola.line_num
            AND aili.po_shipment_num = poll.shipment_num
            AND aili.po_distribution_num = poda.distribution_num
            AND api.po_number = poha.segment1
            AND api.org_id = poha.org_id              --Added for defect 3686
            AND poha.po_header_id = pola.po_header_id
            AND pola.po_line_id = poll.po_line_id
            AND poll.line_location_id = poda.line_location_id  
            --AND NVL(TO_NUMBER(poda.attribute2),0) <> 0 -- changed for defect 4505
			AND NVL(TO_NUMBER(NVL(poda.attribute2,poda.nonrecoverable_tax)),0) <> 0 --Commented and added for Defect# 27988 and 28294
            AND pra.po_header_id = poha.po_header_id
            AND poda.po_release_id = pra.po_release_id
            AND (DECODE(NVL(poda.quantity_ordered,0)
                        ,0
                        ,poda.amount_ordered
                        ,poda.quantity_ordered) 
                        - NVL(DECODE(NVL(poda.quantity_ordered,0)
                                         ,0
                                         ,poda.amount_billed
                                         ,poda.quantity_billed),0)) > 0
            /* --Removed for defect 6683
            AND gcc.code_combination_id =
                   DECODE (poda.accrue_on_receipt_flag,
                           'Y', poda.accrual_account_id,
                           poda.code_combination_id
                          )*/
            AND pra.release_num = p_release_num;

      lr_tax_line_rec                    lcu_tax_lines%ROWTYPE;
-- ---------------------------------------------------------------------------
-- Main Block for Creating Invoice Lines from Purchase Orders
-- ---------------------------------------------------------------------------

   BEGIN

      BEGIN
        lc_error_loc:='Fetching translation id for tax codes translation';
        SELECT translate_id
        INTO   ln_translation_id
        FROM   xx_fin_translatedefinition
        WHERE  translation_name = 'AP_PRORATE_US_TAX_CODES'
        AND    SYSDATE BETWEEN start_date_active AND NVL(end_date_active, SYSDATE + 1 )
        AND    enabled_flag = 'Y'; -- defect 2303. Change made for faster execution of queries.
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
           fnd_message.set_name ('XXFIN', 'XX_AP_0027_NO_TRANSLATION');
           lc_error_msg := fnd_message.get;
           fnd_file.put_line (fnd_file.LOG,'Error:: ' || lc_error_msg );
      WHEN OTHERS THEN
           fnd_file.put_line (fnd_file.LOG,'Error:: ' || SQLERRM );
      END;

      --lc_hdr_message := 'Invoices got rejected due to Oracle Ebiz Issue';
      lc_error_loc := 'Find PO Invoices for Supplied Group ID';
      lc_error_debug := 'Group ID: ' || p_group_id;
      fnd_message.set_name ('XXFIN', 'XX_AP_0050_REJECTION_HDR');
      LC_HDR_MESSAGE := FND_MESSAGE.GET;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '-----------------------------------------------------------------------------------------------------------------');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '                                      '||lc_hdr_message||'                            ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '-----------------------------------------------------------------------------------------------------------------');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    Invoice Number        PO Number             Error Reason                                       Release Number');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '-----------------------------------------------------------------------------------------------------------------');
      OPEN lcu_po_invoices;

      LOOP
         FETCH lcu_po_invoices
          INTO lr_po_invoices_rec;

         EXIT WHEN lcu_po_invoices%NOTFOUND;
         ln_line_number := 1;
         --Fixed defect 5309              
         ln_po_dist_tot := 0;
         ln_freight_amt := 0;
         ln_tax_amt     := 0;
         lc_inv_var_flag := 'N';
         lc_inv_match_exp_flag := 'Y';  -- Added for defect 13461

         SAVEPOINT sp_inv_var;
         --End of fix defect 5309
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Processing started for PO number '||lr_po_invoices_rec.po_number);
         lc_error_loc := 'Invoice PO Number Validation Check';
         lc_error_debug :=
               '  Invoice Number: '
            || lr_po_invoices_rec.invoice_num
            || '  PO Number: '
            || lr_po_invoices_rec.po_number
            || '  Invoice ID: '
            || lr_po_invoices_rec.invoice_id;
            --FND_FILE.PUT_LINE(FND_FILE.output, '--------------------------------------E1282 Log Message------------------------------'); -- change this to log file.
            --#--FND_FILE.PUT_LINE(FND_FILE.output, 'Processing for Invoice no :'|| lr_po_invoices_rec.invoice_id ||' Po_Number : '||lr_po_invoices_rec.po_number);

         ln_mixed_type_cnt := 1;   -- Added Per CR729

         --------------------------------------------------------------------
         -- Select added below will handle looking to Purchase Orders that have
         -- Multiple Match Type per CR729
         --------------------------------------------------------------------- 
          SELECT count(distinct (DECODE (POLL.RECEIPT_REQUIRED_FLAG, 'N', 
               DECODE (POLL.INSPECTION_REQUIRED_FLAG,'N', '2-Way', '2-Way'),
                     'Y', DECODE (POLL.INSPECTION_REQUIRED_FLAG,'N', '3-Way', 
                                                         'Y','4-Way','3-Way'))))           
            INTO   LN_MIXED_TYPE_CNT 
         /* V2.7   FROM  PO_LINE_LOCATIONS_INQ_V POLL
           WHERE  POLL.PO_NUM = LR_PO_INVOICES_REC.PO_NUMBER
             AND (POLL.RELEASE_NUM = LR_PO_INVOICES_REC.ATTRIBUTE15
                   OR POLL.RELEASE_NUM IS NULL);  */
		--V2.7, Added tables instead of view
		FROM PO_LINE_LOCATIONS PoLL,
   			PO_HEADERS poh,
  			PO_RELEASES POR
		WHERE poll.po_header_id = poh.po_header_id
		AND por.po_header_id   = poh.po_header_id
		AND poll.po_release_id  = por.po_release_id(+)
		AND Poh.segment1       = LR_PO_INVOICES_REC.PO_NUMBER
		AND (POR.RELEASE_NUM   = LR_PO_INVOICES_REC.ATTRIBUTE15
		OR POR.RELEASE_NUM    IS NULL);

            
         ------------------------------------------------------------------
         -- Select Added to release approval status.  If a row is returned 
         -- then the Blanket PO is not approved.
         ------------------------------------------------------------------
         LN_REL_UNAPPRV_FLG := NULL;    
         LC_AUTH_OUTPUT     := NULL;

         IF LR_PO_INVOICES_REC.TYPE_LOOKUP_CODE = 'BLANKET' THEN
    
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Before approval status select LR_PO_INVOICES_REC.INVOICE_ID = '
                              ||LR_PO_INVOICES_REC.INVOICE_ID);
                            
            lc_error_loc := 'Approval Status select statment';
          
           BEGIN  
            SELECT pra.AUTHORIZATION_STATUS 
                INTO LN_REL_UNAPPRV_FLG 
               FROM 
                     AP_INVOICES_INTERFACE API
                    ,po_headers_all poha
                    ,po_lines_all pola
                    ,PO_LINE_LOCATIONS_ALL POLL
                    ,PO_DISTRIBUTIONS_ALL PODA
                    ,PO_RELEASES_ALL  PRA     
              WHERE  API.INVOICE_ID = LR_PO_INVOICES_REC.INVOICE_ID
              AND    api.po_number = poha.segment1  
              AND    api.org_id = poha.org_id           
              AND    poha.po_header_id = pola.po_header_id
              AND    POHA.PO_HEADER_ID = PRA.PO_HEADER_ID
              AND    pola.po_line_id   = poll.po_line_id
              AND    UPPER(SUBSTR(poll.match_option,1,1)) = 'P'
              AND    poll.line_location_id = poda.line_location_id
              AND    PRA.PO_RELEASE_ID = PODA.PO_RELEASE_ID
              AND   (DECODE(NVL(poda.quantity_ordered,0)
                        ,0
                        ,poda.amount_ordered
                        ,poda.quantity_ordered) 
                        - NVL(DECODE(NVL(poda.quantity_ordered,0)
                                         ,0
                                         ,poda.amount_billed
                                         ,poda.quantity_billed),0)) > 0
             AND  POHA.TYPE_LOOKUP_CODE = 'BLANKET'
             AND  PRA.RELEASE_NUM =  LR_PO_INVOICES_REC.ATTRIBUTE15
             AND  PRA.AUTHORIZATION_STATUS  <> 'APPROVED'
             AND  ROWNUM < 2;

           EXCEPTION
             WHEN NO_DATA_FOUND
                  THEN  
                                    
                  fnd_message.CLEAR;
                  fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERROR');
                  fnd_message.set_token ('ERR_LOC', lc_error_loc);
                  fnd_message.set_token ('ERR_DEBUG', lc_error_debug);
                  fnd_message.set_token ('ERR_ORA', SQLERRM);
                  lc_error_msg := fnd_message.get;
                  FND_FILE.PUT_LINE (FND_FILE.LOG,
                               'NO_DATA_FOUND Exception Encountered in '
                            || 'XX_AP_CREATE_PO_INV_LINES: '
                            || LC_ERROR_MSG
                           ); 
                              
             WHEN OTHERS
                  THEN  
                  fnd_message.CLEAR;
                  fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERROR');
                  fnd_message.set_token ('ERR_LOC', lc_error_loc);
                  fnd_message.set_token ('ERR_DEBUG', lc_error_debug);
                  fnd_message.set_token ('ERR_ORA', SQLERRM);
                  lc_error_msg := fnd_message.get;
                  fnd_file.put_line (fnd_file.LOG,
                               'Other Exception Encountered in '
                            || 'XX_AP_CREATE_PO_INV_LINES: '
                            || LC_ERROR_MSG
                           );    
                           
                        
           END; 
         END IF;
    
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'After approval status select LR_PO_INVOICES_REC.INVOICE_ID = '
                              ||LR_PO_INVOICES_REC.INVOICE_ID);  
         -- -----------------------------------------------------------------------
         -- If po_header_id exists, the PO is valid.  If previsouly rejected due to
         -- to an invalid po and a  po_head_id exists now, the po lines will now be
         -- created and the hold will be released automatically by the import program.
         -- -----------------------------------------------------------------------
         IF lr_po_invoices_rec.po_header_id IS NULL
         THEN
            -- If the PO number is NOT valid, create a standard rejection/hold
            BEGIN
               lc_error_loc       := 'Create AP Rejection for Invalid PO# ';
               l_reject_code_type := 'INVALID PO NUM';

               --#--FND_FILE.PUT_LINE(FND_FILE.output, 'Inside Invalid PO before message');
               fnd_message.set_name ('XXFIN', 'XX_AP_0051_INVALID_PO');
               l_reject_code_type := fnd_message.get;
               --#--FND_FILE.PUT_LINE(FND_FILE.output, 'Inside Invalid PO after message');

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    '||RPAD(TRIM(LR_PO_INVOICES_REC.INVOICE_NUM),22) 
                                                        ||RPAD(TRIM(LR_PO_INVOICES_REC.PO_NUMBER),22)
                                                        ||RPAD(L_REJECT_CODE_TYPE,50)
                                                        || ' ' 
                                                        || LR_PO_INVOICES_REC.ATTRIBUTE15);  -- added per CR729 


               --xx_ap_reset_invoice_stg (p_group_id,lr_po_invoices_rec.invoice_id);
               --#--FND_FILE.PUT_LINE(FND_FILE.output, 'Inside Invalid PO After Reset');
            END;
         --added to handle defect 4505
         ELSIF NVL(LR_PO_INVOICES_REC.APPROVED_FLAG,'N') <> 'Y' 
               OR UPPER(LN_REL_UNAPPRV_FLG) <> 'APPROVED'
         THEN
            -- If the PO is NOT approved, reject the invoice
            BEGIN
               LC_ERROR_LOC       := 'Create AP Rejection for unapproved PO# ';
               L_REJECT_CODE_TYPE := 'PO not Approved';
               
               IF LR_PO_INVOICES_REC.TYPE_LOOKUP_CODE = 'BLANKET' THEN               
                  LC_AUTH_OUTPUT := LN_REL_UNAPPRV_FLG;
               ELSE
                  LC_AUTH_OUTPUT := LR_PO_INVOICES_REC.AUTHORIZATION_STATUS;
               END IF;
               
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    '||RPAD(TRIM(LR_PO_INVOICES_REC.INVOICE_NUM),22) 
                                                        ||RPAD(TRIM(LR_PO_INVOICES_REC.PO_NUMBER),22)
                                                        ||L_REJECT_CODE_TYPE ||': '|| RPAD(LC_AUTH_OUTPUT,33)
                                                        || ' ' 
                                                        || LR_PO_INVOICES_REC.ATTRIBUTE15);  -- added per CR729

               XX_AP_RESET_INVOICE_STG (P_GROUP_ID,LR_PO_INVOICES_REC.INVOICE_ID);  -- added Per CR729  
               COMMIT;                                                              -- added Per CR729

             end;
          --end of defect 4505 change         
         -------------------------------------------------------------------------
         -- ELSIF statement added below will check for Purchase orders that have 
         -- been closed or finally closed per CR729
         ------------------------------------------------------------------------
         ELSIF (UPPER(NVL(lr_po_invoices_rec.CLOSED_CODE,'OPEN')) = 'CLOSED') 
                      OR (UPPER(NVL(lr_po_invoices_rec.CLOSED_CODE,'OPEN')) = 'FINALLY CLOSED')
           THEN
             LC_ERROR_LOC       := 'Create AP Rejection for Closed PO# ';
             L_REJECT_CODE_TYPE := 'PO Closed';
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    '||RPAD(TRIM(LR_PO_INVOICES_REC.INVOICE_NUM),22) 
                                                      ||RPAD(TRIM(LR_PO_INVOICES_REC.PO_NUMBER),22)
                                                      ||RPAD(L_REJECT_CODE_TYPE,50)
                                                      || ' ' 
                                                      || LR_PO_INVOICES_REC.ATTRIBUTE15);  -- added per CR729 

             XX_AP_RESET_INVOICE_STG (P_GROUP_ID,LR_PO_INVOICES_REC.INVOICE_ID);  -- added Per CR729
             commit;                                                              -- added Per CR729         
             ----------------------------------------------------------
             -- Per 729 if statement to check for mixed match PO lines 
             ---------------------------------------------------------
         ELSIF  LN_MIXED_TYPE_CNT > 1 THEN
              BEGIN
      
                   LC_ERROR_LOC       := ' Multiple Match Type ';
                   L_REJECT_CODE_TYPE := 'MULTIPLE MATCH TYPE';
                   FND_MESSAGE.SET_NAME ('XXFIN', 
                                          'XX_AP_0052_MULTI_MATCH_TYPE');
                    l_reject_code_type := fnd_message.get;

                    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    '||RPAD(TRIM(LR_PO_INVOICES_REC.INVOICE_NUM),22) 
                                                             ||RPAD(TRIM(LR_PO_INVOICES_REC.PO_NUMBER),22)
                                                             ||RPAD(L_REJECT_CODE_TYPE,50)
                                                             || ' ' 
                                                             || LR_PO_INVOICES_REC.ATTRIBUTE15);  -- added per CR729 
         
              
         
                 XX_AP_RESET_INVOICE_STG (P_GROUP_ID,LR_PO_INVOICES_REC.INVOICE_ID);  -- added Per CR729
                 commit;                                                               -- added Per CR729       
                 
               END;
         
         ELSE
         ---------------------------------------------------------------------
         -- Create Invoice Lines for Valid Purchase Order Numbers
         ---------------------------------------------------------------------
            BEGIN

               lc_error_loc := 'Create Invoices Lines from Valid PO# ';
               OPEN lcu_invoice_lines (lr_po_invoices_rec.invoice_id,lr_po_invoices_rec.attribute15);

               LOOP
                  FETCH lcu_invoice_lines
                   INTO lr_invoice_line_rec;
                  EXIT WHEN lcu_invoice_lines%NOTFOUND;
                  
            
                 ------- Unbilled amount calculated based on the match approval level for the defect # 2279 -------------
                 -----------------------------------2-Way match-----------------------------------
                 IF  NVL(lr_invoice_line_rec.inspection_required_flag,'N') = 'N'
                 AND NVL(lr_invoice_line_rec.receipt_required_flag,'N')    = 'N'
                 AND (lr_invoice_line_rec.quantity_ordered - lr_invoice_line_rec.quantity_billed) > 0

                   --Fixed defect 3686
                   /*THEN lc_unbilled_amount := lr_invoice_line_rec.unit_price *
                               (lr_invoice_line_rec.quantity_ordered - lr_invoice_line_rec.quantity_billed);*/
                   THEN lc_unbilled_amount := ROUND(lr_invoice_line_rec.unit_price *
                                (LR_INVOICE_LINE_REC.QUANTITY_ORDERED - LR_INVOICE_LINE_REC.QUANTITY_BILLED),2);

                      lc_inv_match_exp_flag := 'N';  -- Added for defect 13461

                   --#--FND_FILE.PUT_LINE(FND_FILE.output, 'Inside Lines Cursor and in 2 way  ln_par_rcv_po_cnt count'||ln_par_rcv_po_cnt);
                         --lc_par_rcv_po := 'Y';
                         ln_par_rcv_po_cnt := ln_par_rcv_po_cnt + 1; 
                         LN_PO_DIST_TOT := LN_PO_DIST_TOT + LC_UNBILLED_AMOUNT;    --Defect 5309
                   FND_FILE.PUT_LINE(FND_FILE.log, 'Inside Lines Cursor and in 2 way  ln_par_rcv_po_cnt count'||ln_par_rcv_po_cnt);
                   -----------------------------------3-Way match-----------------------------------

                 ELSIF NVL(LR_INVOICE_LINE_REC.INSPECTION_REQUIRED_FLAG,'N')  <> 'Y'
                   AND   NVL(LR_INVOICE_LINE_REC.RECEIPT_REQUIRED_FLAG,'N')      = 'Y'
                   AND (lr_invoice_line_rec.quantity_delivered - lr_invoice_line_rec.quantity_billed) > 0

                 --Fixed defect 3686
                 /*THEN lc_unbilled_amount := lr_invoice_line_rec.unit_price *
                            (lr_invoice_line_rec.quantity_delivered - lr_invoice_line_rec.quantity_billed);*/
                    THEN lc_unbilled_amount := ROUND(lr_invoice_line_rec.unit_price *
                            (lr_invoice_line_rec.quantity_delivered - lr_invoice_line_rec.quantity_billed),2);

                        lc_inv_match_exp_flag := 'N';  -- Added for defect 13461 

                         -- Added to handle rejection if PO is 3 way and not received -- defect no : 4505 -------------------
                         FND_FILE.PUT_LINE(FND_FILE.log, 'Inside Lines Cursor and in 3 way  ln_par_rcv_po_cnt count'||ln_par_rcv_po_cnt);
                         --lc_par_rcv_po := 'Y';
                         ln_par_rcv_po_cnt := ln_par_rcv_po_cnt + 1;
                         LN_PO_DIST_TOT := LN_PO_DIST_TOT + LC_UNBILLED_AMOUNT;    --Defect 5309
                         --#--FND_FILE.PUT_LINE(FND_FILE.output, 'Inside Lines Cursor and in 3 way  ln_par_rcv_po_cnt count'||ln_par_rcv_po_cnt);
                 -----------------------If 3 Way and PO not received --------------------------------------
                 ELSIF NVL(lr_invoice_line_rec.inspection_required_flag,'N')  <> 'Y'
                   and   NVL(LR_INVOICE_LINE_REC.RECEIPT_REQUIRED_FLAG,'N')      = 'Y'
                   AND lr_invoice_line_rec.quantity_delivered = 0

                   then LC_UNBILLED_AMOUNT := 0;
                     --#--FND_FILE.PUT_LINE(FND_FILE.output, 'Inside Lines Cursor and in 3 way and PO not received');
                         begin

 
                            lc_error_loc := 'Create AP Rejection for PO Not received';
                            L_REJECT_CODE_TYPE := 'PO NOT RECEIVED';

                            --lc_inv_rejected    := 'Y';
                            --FND_FILE.PUT_LINE(FND_FILE.output, 'Inside Lines Cursor and in 3 way and PO not received  message');
                        
                            fnd_message.set_name ('XXFIN', 'XX_AP_0052_PO_NOT_RECEIVED');
                            L_REJECT_CODE_TYPE := FND_MESSAGE.GET;

                           FND_FILE.PUT_LINE(FND_FILE.log, 'Inside Lines Cursor and in 3 way and PO not received   ln_par_rcv_po_cnt count'||ln_par_rcv_po_cnt);
                           FND_FILE.PUT_LINE(FND_FILE.log, '         '||LR_PO_INVOICES_REC.INVOICE_NUM ||'              '||LR_PO_INVOICES_REC.INVOICE_ID||'          '||L_REJECT_CODE_TYPE);
                         
                           --lc_par_rcv_po := 'N';
                           --xx_ap_reset_invoice_stg (p_group_id,lr_po_invoices_rec.invoice_id);
                           --#--FND_FILE.PUT_LINE(FND_FILE.output, 'Inside Lines Cursor and in 3 way and PO not received   ln_par_rcv_po_cnt count'||ln_par_rcv_po_cnt);
                            --EXIT; -- commented for partially received
  
                         END;
                -------------------------End of defect 4505 change -------------------------------------------------

                ------------------------If neither 2 Way nor a 3 Way match ----------------------

                ELSE LC_UNBILLED_AMOUNT := 0;
                         FND_FILE.PUT_LINE(FND_FILE.log, 'Inside Lines Cursor and in else  ln_par_rcv_po_cnt count'||ln_par_rcv_po_cnt);
                         --lc_par_rcv_po := 'Y';
                         --#--FND_FILE.PUT_LINE(FND_FILE.output, 'Inside Lines Cursor and in else  ln_par_rcv_po_cnt count'||ln_par_rcv_po_cnt);
                END IF;

                -- -----------------------------------------------------------------
                -- Get next invoice line ID
                -- -----------------------------------------------------------------
                BEGIN
                     lc_error_loc := 'Getting next Invoice Line ID ';

                     SELECT ap_invoice_lines_interface_s.NEXTVAL
                       INTO ln_invoice_line_id
                       FROM DUAL;
                END;

                -- -----------------------------------------------------------------
                -- Create Invoice Line
                -- ------------------------------------------------------------------
                 
                   BEGIN
                     lc_error_loc := 'Insert invoice line.';
                     IF lc_unbilled_amount > 0 THEN
                     --#--FND_FILE.PUT_LINE(FND_FILE.output, 'Inside unbill amt > 0 before insert');
                     INSERT INTO ap_invoice_lines_interface
                                 (invoice_id
                                  ,invoice_line_id
                                  ,line_type_lookup_code
                                  ,line_number             --Defect 9420
                                  ,line_group_number       --Defect 9420
                                  ,amount
                                  ,tax_code
                                  ,po_number
                                  ,po_line_number
                                  ,po_shipment_num
                                  ,po_distribution_num
                                  ,unit_price
                                  ,last_updated_by
                                  ,last_update_date
                                  ,created_by
                                  ,creation_date
                                  ,org_id
                                  ,match_option
                                  ,po_release_id   -- Added for the Defect : 2280
                                 )
                          VALUES (lr_invoice_line_rec.invoice_id
                                  ,ln_invoice_line_id
                                  ,l_inv_item_line_type
                                  ,ln_line_number
                                  ,ln_line_number
                                  ,lc_unbilled_amount
                                  --lr_invoice_line_rec.tax_code  -- defect 2303
                                  ,NULL
                                  ,lr_invoice_line_rec.po_number
                                  ,lr_invoice_line_rec.line_num
                                  ,lr_invoice_line_rec.shipment_num
                                  ,lr_invoice_line_rec.distribution_num
                                  --,lr_invoice_line_rec.unit_price
                                  ,lr_invoice_line_rec.actual_unit_price --Added for Defect 8916
                                  ,lr_invoice_line_rec.last_updated_by
                                  ,lr_invoice_line_rec.last_update_date
                                  ,lr_invoice_line_rec.created_by
                                  ,lr_invoice_line_rec.creation_date
                                  ,lr_invoice_line_rec.org_id
                                  ,lr_invoice_line_rec.match_option
                                  ,lr_invoice_line_rec.po_release_id   -- Added for the Defect : 2280
                                 );
                            --#--FND_FILE.PUT_LINE(FND_FILE.output, 'Inside unbill amt > 0 after insert');
                         end if;
                   -------------- The calculated unbilled amount is inserted for the Defect # 2279-------------------
                   ---------------The match option is fetched from PO Shipment line for the Defect # 2279 ---------
                   END;
                  ln_line_number := ln_line_number + 1;
               END LOOP;

               CLOSE lcu_invoice_lines;
               FND_FILE.PUT_LINE(FND_FILE.LOG,'PO Distribution Total after item validations is '||ln_po_dist_tot);
               --added for defect 4505 to reject and reset partially received PO
               IF ln_par_rcv_po_cnt = 0 THEN
                  --#--FND_FILE.PUT_LINE(FND_FILE.output, 'Inside partially rcved PO with 3 way and PO not received before message');
                  fnd_message.set_name ('XXFIN', 'XX_AP_0052_PO_NOT_RECEIVED');
                  l_reject_code_type := fnd_message.get;
                  --#--FND_FILE.PUT_LINE(FND_FILE.output, 'Inside partially rcved PO with 3 way and PO not received after message');                  

                 -- FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    '||lr_po_invoices_rec.invoice_num ||'              '||lr_po_invoices_rec.po_number||'              '||l_reject_code_type);
                  --#--FND_FILE.PUT_LINE(FND_FILE.output, 'Inside partially rcved PO with 3 way and PO not received before reset call');

                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '    '||RPAD(TRIM(LR_PO_INVOICES_REC.INVOICE_NUM),22) 
                                                           ||RPAD(TRIM(LR_PO_INVOICES_REC.PO_NUMBER),22)
                                                           ||RPAD(L_REJECT_CODE_TYPE,50)
                                                           || ' ' 
                                                           ||LR_PO_INVOICES_REC.ATTRIBUTE15);  -- added per CR729 


                  xx_ap_reset_invoice_stg (p_group_id,lr_po_invoices_rec.invoice_id);

                  --#--FND_FILE.PUT_LINE(FND_FILE.output, 'Inside partially rcved PO with 3 way and PO not received after reset call');

                  ln_par_rcv_po_cnt := 0;
               ELSE
                  lc_par_rcv_po := 'Y';
                  ln_par_rcv_po_cnt := 0;
               END IF;
               --end of change for defect 4505 to reject and reset partially received PO
            --  IF lc_inv_rejected = 'N' THEN -- Defect 4505
-- -------------------------------------------------------------------
-- Check if Freight invoice line exists in the interface table
-- -------------------------------------------------------------------
               BEGIN
                  lc_error_loc := 'Check if Freight Invoice Line exists.';

--                  ln_freight_cnt := 0;                                 --Added per defect 13332

                  --Commented for defect 5309
                  /*SELECT COUNT (1)
                    INTO ln_freight_cnt
                    FROM ap_invoice_lines_interface apl
                   WHERE apl.invoice_id = lr_po_invoices_rec.invoice_id
                     AND apl.line_type_lookup_code = l_inv_freight_line_type;*/
                   
                   --SELECT amount
				   SELECT SUM(amount) --Commented and added for Defect# 27988, 28294, 28591
                    INTO ln_freight_amt
                    FROM ap_invoice_lines_interface apl
                   WHERE apl.invoice_id = lr_po_invoices_rec.invoice_id
                     AND apl.line_type_lookup_code = l_inv_freight_line_type;
                   
                   ln_freight_cnt := 1;                                   --Defect 5309
                   ln_po_dist_tot := ln_po_dist_tot + NVL(ln_freight_amt,0); --Defect 5309

               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     lc_error_loc :=
                                'NO_DATA_FOUND: Freight Line does not exist.';
                     fnd_message.CLEAR;
                     fnd_message.set_name ('XXFIN', 'XX_AP_0023_NO_FREIGHT');
                     fnd_message.set_token ('INVOICE_NUM',
                                            lr_po_invoices_rec.invoice_num
                                           );
                     fnd_message.set_token ('PO_NUM',
                                            lr_po_invoices_rec.po_number
                                           );
                     lc_error_msg := fnd_message.get;
                     fnd_file.put_line (fnd_file.LOG,
                                           'XX_AP_CREATE_PO_INV_LINES: '
                                        || lc_error_msg
                                       );
               END;

               FND_FILE.PUT_LINE(FND_FILE.LOG,'PO Distribution Total after freight validations is '||ln_po_dist_tot);


-- -------------------------------------------------------------------
-- Prorate Freight Lines across ITEM type invoices lines
-- -------------------------------------------------------------------
               BEGIN
                  lc_error_loc := 'Set Prorate Freight';

                  IF ln_freight_cnt > 0
                  THEN
                     lc_error_loc :=
                                   'Set Prorate Across Flag for Freight Line';

                     UPDATE ap_invoice_lines_interface apl
                        SET apl.prorate_across_flag = 'Y'
                            ,apl.line_number = ln_line_number     --Defect 9420
                      WHERE apl.invoice_id = lr_po_invoices_rec.invoice_id
                        AND apl.line_type_lookup_code =
                                                       l_inv_freight_line_type;
                     
                     ln_line_number := ln_line_number + 1;      --Defect 9420
                    
                     --Commented the line_group_number population per defect 9420
                     /*lc_error_loc :=
                           'Set Line Group Number for Freight and Item '
                        || 'Lines';

                     UPDATE ap_invoice_lines_interface apl
                        SET apl.line_group_number =
                                                 lr_po_invoices_rec.invoice_id
                      WHERE apl.invoice_id = lr_po_invoices_rec.invoice_id
                        AND apl.line_type_lookup_code IN
                               (l_inv_item_line_type, l_inv_freight_line_type);*/
                  END IF;
               END;
               --#--FND_FILE.PUT_LINE(FND_FILE.output, 'After Frieght');

               --Fixed defect 5309
               BEGIN

                  SELECT NVL(SUM(amount),0)
                  INTO   ln_tax_amt
                  FROM   ap_invoice_lines_interface AILI
                  WHERE  invoice_id = lr_po_invoices_rec.invoice_id
                  AND    line_type_lookup_code = l_inv_tax_line_type;
                  
                  ln_po_dist_tot := ln_po_dist_tot + ln_tax_amt;
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     NULL;
               END;
               
               FND_FILE.PUT_LINE(FND_FILE.LOG,'PO Distribution Total after tax validations is '||ln_po_dist_tot);

               IF (lr_po_invoices_rec.invoice_amount <> ln_po_dist_tot) THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'PO Distribution Total do not match Invoice header ');
                  lc_inv_var_flag := 'Y';
               END IF;
-- -------------------------------------------------------------------
-- Check if Tax invoice line exists in the interface table
-- -------------------------------------------------------------------
               IF (lc_inv_var_flag <> 'Y') THEN
               fnd_file.put_line(fnd_file.log,'At lc_inv_var_flag<>Y');
                  BEGIN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Tax lines being prorated');
                     lc_error_loc :=
                        'Check if Tax Invoice Line for US Tax Code '
                        || 'Exists.';
                     ln_total_tax_amount := 0;
                     ln_dff_tax_total    := 0;

                   IF lr_po_invoices_rec.type_lookup_code = 'STANDARD' THEN
                     /*
                     SELECT   apl.amount tax_amt,
                              apl.tax_code,
                              apl.invoice_line_id tax_inv_line_id,
                              SUM (apl2.amount) item_line_total
                         INTO ln_total_tax_amount,
                              lc_tax_code,
                              ln_tax_invoice_line_id,
                              ln_total_tax_line_amount
                         FROM ap_invoice_lines_interface apl,
                              ap_invoice_lines_interface apl2,
                              hr_operating_units hou,
                              po_headers_all pha,
                              po_lines_all pla,
                              po_line_locations_all plla,
                              po_distributions_all pda
                        -- Added to check with tranlsation for US ou's inly
                     WHERE    apl.invoice_id = lr_po_invoices_rec.invoice_id
                          AND apl.line_type_lookup_code = l_inv_tax_line_type
                          AND apl2.invoice_id = apl.invoice_id
                          AND apl2.line_type_lookup_code = l_inv_item_line_type
                          --AND apl2.tax_code = apl.tax_code  -- defect 2303
                          AND hou.organization_id = apl.org_id
                          AND (apl.tax_code, hou.NAME) IN (
                                 SELECT source_value1, source_value2
                                   FROM xx_fin_translatevalues
                                  WHERE translate_id = ln_translation_id
                                    AND SYSDATE BETWEEN start_date_active AND NVL(end_date_active, SYSDATE + 1 )
                                    AND enabled_flag = 'Y')
                         AND pha.segment1 = apl2.po_number
                         AND pha.org_id = apl2.org_id                  --Added for defect 3686
                         AND pla.po_header_id = pha.po_header_id
                         AND pla.line_num = apl2.po_line_number
                         AND plla.po_line_id = pla.po_line_id
                         AND plla.shipment_num = apl2.po_shipment_num
                         AND pda.line_location_id = plla.line_location_id
                         AND pda.distribution_num = apl2.po_distribution_num
                         AND NVL(TO_NUMBER(pda.attribute2),0) > 0
                     -- Joined PO tables to check if tax amount exists in PO dist DFF
                     -- Condition added to check if only US tax codes are prorated.
                     GROUP BY apl.amount, apl.tax_code, apl.invoice_line_id;
                     */
                     SELECT   apl.amount tax_amt
                              ,apl.tax_code
                              ,apl.invoice_line_id tax_inv_line_id  
                              --,SUM (pda.attribute2) dff_tax_total_2way
							  ,SUM (NVL(pda.attribute2,pda.nonrecoverable_tax)) dff_tax_total_2way --Commented and added for Defect# 27988 and 28294
                              --,SUM ((pda.attribute2/DECODE(NVL(pda.quantity_ordered,0)
							  ,SUM ((NVL(pda.attribute2,pda.nonrecoverable_tax)/DECODE(NVL(pda.quantity_ordered,0) /*Commented and added for Defect# 27988 and 28294*/ 
                                                               ,0
                                                               ,pda.amount_ordered
                                                               ,pda.quantity_ordered))
                                    *(NVL(DECODE(NVL(pda.quantity_ordered,0)
                                                        ,0
                                                        ,pda.amount_delivered
                                                        ,pda.quantity_delivered),0) 
                                      - NVL(DECODE(NVL(pda.quantity_ordered,0)
                                                        ,0
                                                        ,pda.amount_billed
                                                        ,pda.quantity_billed),0))) dff_tax_total  --Fixed defect 7937
                         INTO ln_total_tax_amount
                              ,lc_tax_code
                              ,ln_tax_invoice_line_id
                              ,ln_dff_tax_total_2way
                              ,ln_dff_tax_total
                         FROM ap_invoice_lines_interface apl
                              ,ap_invoices_interface aph
                              ,hr_operating_units hou
                              ,po_headers_all pha
                              ,po_distributions_all pda
                         WHERE apl.invoice_id = lr_po_invoices_rec.invoice_id
                           AND aph.invoice_id = lr_po_invoices_rec.invoice_id
                           AND apl.line_type_lookup_code = l_inv_tax_line_type
                           AND aph.invoice_id = apl.invoice_id
                           AND hou.organization_id = apl.org_id
                           AND hou.organization_id = aph.org_id
                           AND (apl.tax_code, hou.NAME) IN (
                                 SELECT source_value1, source_value2
                                   FROM xx_fin_translatevalues
                                  WHERE translate_id = ln_translation_id
                                    AND SYSDATE BETWEEN start_date_active AND NVL(end_date_active, SYSDATE + 1 )
                                    AND enabled_flag = 'Y')
                           AND pha.segment1 = aph.po_number
                           AND pha.org_id = aph.org_id
                           AND pda.po_header_id = pha.po_header_id
                           AND (DECODE(NVL(pda.quantity_ordered,0)
                                           ,0
                                           ,pda.amount_ordered
                                           ,pda.quantity_ordered) 
                                       - NVL(DECODE(NVL(pda.quantity_ordered,0)
                                                        ,0
                                                        ,pda.amount_billed
                                                        ,pda.quantity_billed),0)) > 0
                           --AND NVL(TO_NUMBER(pda.attribute2),0) <> 0
						   AND NVL(TO_NUMBER(NVL(pda.attribute2,pda.nonrecoverable_tax)),0) <> 0 --Commented and added for Defect# 27988 and 28294
                        GROUP BY apl.amount, apl.tax_code, apl.invoice_line_id;

                     --#--FND_FILE.PUT_LINE(FND_FILE.output, 'Inside tax  tax amt fo standard PO');
                   ELSIF lr_po_invoices_rec.type_lookup_code = 'BLANKET' THEN
                       /*
                       SELECT apl.amount tax_amt,
                              apl.tax_code,
                              apl.invoice_line_id tax_inv_line_id,
                              SUM (apl2.amount) item_line_total
                         INTO ln_total_tax_amount,
                              lc_tax_code,
                              ln_tax_invoice_line_id,
                              ln_total_tax_line_amount
                         FROM ap_invoice_lines_interface apl,
                              ap_invoice_lines_interface apl2,
                              hr_operating_units hou,
                              po_headers_all pha,
                              po_lines_all pla,
                              po_line_locations_all plla,
                              po_distributions_all pda,
                              po_releases_all pra
                        -- Added to check with tranlsation for US ou's inly
                     WHERE    apl.invoice_id = lr_po_invoices_rec.invoice_id
                          AND apl.line_type_lookup_code = l_inv_tax_line_type
                          AND apl2.invoice_id = apl.invoice_id
                          AND apl2.line_type_lookup_code = l_inv_item_line_type
                          --AND apl2.tax_code = apl.tax_code  -- defect 2303
                          AND hou.organization_id = apl.org_id
                          AND (apl.tax_code, hou.NAME) IN (
                                 SELECT source_value1, source_value2
                                   FROM xx_fin_translatevalues
                                  WHERE translate_id = ln_translation_id
                                    AND SYSDATE BETWEEN start_date_active AND NVL(end_date_active, SYSDATE + 1 )
                                    AND enabled_flag = 'Y')
                         AND pha.segment1 = apl2.po_number
                         AND pha.org_id = apl2.org_id                --Added for defect 3686
                         AND pla.po_header_id = pha.po_header_id
                         AND pla.line_num = apl2.po_line_number
                         AND plla.po_line_id = pla.po_line_id
                         AND plla.shipment_num = apl2.po_shipment_num
                         AND pda.line_location_id = plla.line_location_id
                         AND pda.distribution_num = apl2.po_distribution_num
                         AND NVL(TO_NUMBER(pda.attribute2),0) > 0
                         AND pra.po_header_id = pha.po_header_id
                         AND pda.po_release_id = pra.po_release_id
                         AND (pda.quantity_ordered - pda.quantity_billed )>0
                     -- Joined PO tables to check if tax amount exists in PO dist DFF
                     -- Condition added to check if only US tax codes are prorated.
                     GROUP BY apl.amount, apl.tax_code, apl.invoice_line_id;
                     */

                     SELECT  apl.amount tax_amt
                             ,apl.tax_code
                             ,apl.invoice_line_id tax_inv_line_id
                             --,SUM (pda.attribute2) dff_tax_total_2way
							 ,SUM (NVL(pda.attribute2,pda.nonrecoverable_tax)) dff_tax_total_2way --Commented and added for Defect# 27988 and 28294
                             --,SUM ((pda.attribute2/DECODE(NVL(pda.quantity_ordered,0)
							 ,SUM ((NVL(pda.attribute2,pda.nonrecoverable_tax)/DECODE(NVL(pda.quantity_ordered,0) /*Commented and added for Defect# 27988 and 28294*/
                                                               ,0
                                                               ,pda.amount_ordered
                                                               ,pda.quantity_ordered))
                                    *(NVL(DECODE(NVL(pda.quantity_ordered,0)
                                                        ,0
                                                        ,pda.amount_delivered
                                                        ,pda.quantity_delivered),0) 
                                      - NVL(DECODE(NVL(pda.quantity_ordered,0)
                                                        ,0
                                                        ,pda.amount_billed
                                                        ,pda.quantity_billed),0))) dff_tax_total     --Fixed defect 7937
                         INTO ln_total_tax_amount
                              ,lc_tax_code
                              ,ln_tax_invoice_line_id
                              ,ln_dff_tax_total_2way
                              ,ln_dff_tax_total
                         FROM ap_invoice_lines_interface apl
                              ,ap_invoices_interface aph
                              ,hr_operating_units hou
                              ,po_headers_all pha
                              ,po_distributions_all pda
                              ,po_releases_all pra
                         -- Added to check with tranlsation for US ou's inly
                         WHERE apl.invoice_id = lr_po_invoices_rec.invoice_id
                           AND aph.invoice_id = lr_po_invoices_rec.invoice_id
                           AND apl.line_type_lookup_code = l_inv_tax_line_type
                           AND aph.invoice_id = apl.invoice_id
                           AND hou.organization_id = apl.org_id
                           AND hou.organization_id = aph.org_id
                           AND (apl.tax_code, hou.NAME) IN (
                                 SELECT source_value1, source_value2
                                   FROM xx_fin_translatevalues
                                  WHERE translate_id = ln_translation_id
                                    AND SYSDATE BETWEEN start_date_active AND NVL(end_date_active, SYSDATE + 1 )
                                    AND enabled_flag = 'Y')
                           AND pha.segment1 = aph.po_number
                           AND pha.org_id = aph.org_id
                           --AND NVL(TO_NUMBER(pda.attribute2),0) <> 0
						   AND NVL(TO_NUMBER(NVL(pda.attribute2,pda.nonrecoverable_tax)),0) <> 0 --Commented and added for Defect# 27988 and 28294
                           AND pha.po_header_id = pda.po_header_id
                           AND pda.po_header_id = pra.po_header_id
                           AND pda.po_release_id = pra.po_release_id
                           AND (DECODE(NVL(pda.quantity_ordered,0)
                                           ,0
                                           ,pda.amount_ordered
                                           ,pda.quantity_ordered) 
                                       - NVL(DECODE(NVL(pda.quantity_ordered,0)
                                                        ,0
                                                        ,pda.amount_billed
                                                        ,pda.quantity_billed),0)) > 0
                           AND pra.release_num = lr_po_invoices_rec.attribute15
                         GROUP BY apl.amount, apl.tax_code, apl.invoice_line_id;

                   END IF;
                   --#--FND_FILE.PUT_LINE(FND_FILE.output, 'Inside tax  tax amt fo blanket PO');
                   --#--FND_FILE.PUT_LINE(FND_FILE.output, 'Inside tax  lc_tax_line_exists flag set'||lc_tax_line_exists);
                   lc_tax_line_exists := 'Y';
                   --#--FND_FILE.PUT_LINE(FND_FILE.output, 'Inside tax  lc_tax_line_exists flag set'||lc_tax_line_exists);
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        lc_error_loc :=
                              'NO_DATA_FOUND: Tax Invoice Line for US Tax '
                           || 'Codes does not exist.';
                        fnd_message.CLEAR;
                        fnd_message.set_name ('XXFIN', 'XX_AP_0025_NO_TAX_LINE');
                        fnd_message.set_token ('INVOICE_NUM',
                                               lr_po_invoices_rec.invoice_num
                                              );
                        fnd_message.set_token ('PO_NUM',
                                               lr_po_invoices_rec.po_number
                                              );
                        lc_error_msg := fnd_message.get;
                        fnd_file.put_line (fnd_file.LOG,
                                              'XX_AP_CREATE_PO_INV_LINES: '
                                           || lc_error_msg
                                          );
                        --#--FND_FILE.PUT_LINE(FND_FILE.output, 'Inside exception for tax amt fetch  flag lc_tax_line_exists set'||lc_tax_line_exists);
                        lc_tax_line_exists := 'N';
                        --#--FND_FILE.PUT_LINE(FND_FILE.output, 'Inside exception for tax amt fetch  flag lc_tax_line_exists set'||lc_tax_line_exists);
                        SELECT COUNT(1)
                        INTO ln_tax_lines
                        FROM ap_invoice_lines_interface AILI
                        WHERE AILI.invoice_id = lr_po_invoices_rec.invoice_id
                          AND NVL(UPPER(AILI.line_type_lookup_code),'X') = l_inv_tax_line_type;
                        --#--FND_FILE.PUT_LINE(FND_FILE.output, 'count of tax lines : ln_tax_lines'||ln_tax_lines||' for invoice id:'||lr_po_invoices_rec.invoice_id);
                        IF (ln_tax_lines > 0) THEN
                           UPDATE ap_invoice_lines_interface AILI
                           SET --prorate_across_flag = 'N'--Defect #28765 --Only for source OD_US_RENT prorate flag should be 'N' .All others it should be 'Y'
                                prorate_across_flag = 'Y'--Defect #28765
                               ,line_number = NULL                              --Fixed defect 12718
                           WHERE AILI.invoice_id = lr_po_invoices_rec.invoice_id
                           AND NVL(UPPER(AILI.line_type_lookup_code),'X') = l_inv_tax_line_type;

                           l_reject_code_type := 'XX_NO_ITEM_LINES';
                         --ELSE
                           --l_reject_code_type := 'NO INVOICE LINES';
                           --#--FND_FILE.PUT_LINE(FND_FILE.output, 'inside count of tax lines before message');
                           fnd_message.set_name ('XXFIN', 'XX_AP_0053_INPROPER_TAX_LINE');
                           l_reject_code_type := fnd_message.get;
                           --#--FND_FILE.PUT_LINE(FND_FILE.output, 'inside count of tax lines after message for invoice'||lr_po_invoices_rec.invoice_id);
                           FND_FILE.PUT_LINE(FND_FILE.LOG, '         '||lr_po_invoices_rec.invoice_num ||'          '||lr_po_invoices_rec.invoice_id||'          '||l_reject_code_type);
                           --xx_ap_reset_invoice_stg (p_group_id,lr_po_invoices_rec.invoice_id);
                           --#--FND_FILE.PUT_LINE(FND_FILE.output, 'inside count of tax lines after reset');
                        END IF;
                     WHEN TOO_MANY_ROWS
                     THEN
                        lc_error_loc :=
                              'TOO_MANY_ROWS Exception: Multiple US Tax '
                           || 'Lines Exist for the invoice';
                        fnd_message.CLEAR;
                        fnd_message.set_name ('XXFIN',
                                              'XX_AP_0024_MULTIPLE_TAX_LINES'
                                             );
                        fnd_message.set_token ('INVOICE_NUM',
                                               lr_po_invoices_rec.invoice_num
                                              );
                        fnd_message.set_token ('PO_NUM',
                                               lr_po_invoices_rec.po_number
                                              );
                        lc_error_msg := fnd_message.get;
                        fnd_file.put_line (fnd_file.LOG,
                                              'XX_AP_CREATE_PO_INV_LINES: '
                                           || lc_error_msg);
                        --#--FND_FILE.PUT_LINE(FND_FILE.output, 'inside count of tax inside too many rec');
                  END;
                  --#--FND_FILE.PUT_LINE(FND_FILE.output, 'before tax amt greater than zero and tax lines exist ln_total_tax_amount:'||ln_total_tax_amount||''||lc_tax_line_exists);
                  IF ln_total_tax_amount > 0 AND lc_tax_line_exists <>'N'
                  THEN
   -- ----------------------------------------------------------------
   -- Create Invoice Distribution Lines for taxes
   -- ----------------------------------------------------------------
                     --#--FND_FILE.PUT_LINE(FND_FILE.output, 'inside tax amt greater than zero and tax lines exist ');
                     BEGIN
                        lc_error_loc :=
                                     'Tax Invoice Line for US Tax Codes Exists.';


                        IF lr_po_invoices_rec.type_lookup_code = 'STANDARD' THEN

                             OPEN lcu_tax_lines (lr_po_invoices_rec.invoice_id
                                                 --,ln_total_tax_amount,
                                                 --ln_total_tax_line_amount
                                                 );

                        ELSIF  lr_po_invoices_rec.type_lookup_code = 'BLANKET' THEN

                             OPEN lcu_tax_lines_blanket (lr_po_invoices_rec.invoice_id,lr_po_invoices_rec.attribute15);
                        END IF;

                        LOOP

                          IF lr_po_invoices_rec.type_lookup_code = 'STANDARD' THEN

                             FETCH lcu_tax_lines INTO lr_tax_line_rec;
                             EXIT WHEN lcu_tax_lines%NOTFOUND;

                          ELSIF  lr_po_invoices_rec.type_lookup_code = 'BLANKET' THEN

                             FETCH lcu_tax_lines_blanket INTO lr_tax_line_rec;
                             EXIT WHEN lcu_tax_lines_blanket%NOTFOUND;
                          END IF;

                          --#--FND_FILE.PUT_LINE(FND_FILE.output, 'inside tax line cursor');
   -- ------------------------------------------------------------
   -- Select Tax Line Invoice Line ID
   -- ------------------------------------------------------------
                           BEGIN
                              lc_error_loc :=
                                    'Getting next Invoice Line ID for tax '
                                 || 'line.';

                              SELECT ap_invoice_lines_interface_s.NEXTVAL
                                INTO ln_invoice_line_id
                                FROM DUAL;
                           END;
   -- ---------------------------------------------------------------
   -- Calculate Tax based on 2-way, 3-way --defect 2533
   -- ---------------------------------------------------------------


                     -----------------------------------2-Way match-----------------------------------

                    IF  NVL(lr_tax_line_rec.inspection_required_flag,'N') = 'N'
                    AND NVL(lr_tax_line_rec.receipt_required_flag,'N')    = 'N'
                    THEN
                         -- changed for defect 4748
                         /*ln_tax := lr_tax_line_rec.unit_price *
                                  (lr_tax_line_rec.quantity_ordered - lr_tax_line_rec.quantity_billed) * ln_total_tax_amount / ln_total_tax_line_amount;*/
                         ln_tax := (((lr_tax_line_rec.dff_tax_amount/lr_tax_line_rec.quantity_ordered)
                                   *(lr_tax_line_rec.quantity_ordered - lr_tax_line_rec.quantity_billed))/ln_dff_tax_total_2way)
                                   *ln_total_tax_amount;
                         ln_tax := ROUND(ln_tax,2);
                        IF ln_tot_tax_per_inv <> 0 THEN
                            IF ln_tax > ln_lar_tax_amt THEN
                               ln_lar_tax_amt := ln_tax;
                               ln_lar_tax_inv_ln_id := ln_invoice_line_id;
                            END IF;
                        ELSE
                           ln_lar_tax_amt := ln_tax;
                           ln_lar_tax_inv_ln_id := ln_invoice_line_id;
                        END IF;
                        ln_tot_tax_per_inv := ln_tot_tax_per_inv + ln_tax;
                         --#--FND_FILE.PUT_LINE(FND_FILE.output, 'inside tax line cursor  way');
                    -----------------------------------3-Way match-----------------------------------

                    ELSIF NVL(lr_tax_line_rec.inspection_required_flag,'N')  <> 'Y'
                    AND   NVL(lr_tax_line_rec.receipt_required_flag,'N')      = 'Y'
                    AND (lr_tax_line_rec.quantity_delivered - lr_tax_line_rec.quantity_billed) > 0
                    THEN
                       -- changed for defect 4748
                       /* ln_tax := lr_tax_line_rec.unit_price *
                               (lr_tax_line_rec.quantity_delivered - lr_tax_line_rec.quantity_billed)
                               * ln_total_tax_amount / ln_total_tax_line_amount;*/
                        ln_tax := (((lr_tax_line_rec.dff_tax_amount/lr_tax_line_rec.quantity_ordered)
                                   *(lr_tax_line_rec.quantity_delivered - lr_tax_line_rec.quantity_billed))/ln_dff_tax_total)
                                   *ln_total_tax_amount;
                        ln_tax := ROUND(ln_tax,2);
                        IF ln_tot_tax_per_inv <> 0 THEN
                            IF ln_tax > ln_lar_tax_amt THEN
                               ln_lar_tax_amt := ln_tax;
                               ln_lar_tax_inv_ln_id := ln_invoice_line_id;
                            END IF;
                        ELSE
                           ln_lar_tax_amt := ln_tax;
                           ln_lar_tax_inv_ln_id := ln_invoice_line_id;
                        END IF;
                        ln_tot_tax_per_inv := ln_tot_tax_per_inv + ln_tax;
                    ------------------------If neither 2 Way nor a 3 Way match ----------------------
                         --#--FND_FILE.PUT_LINE(FND_FILE.output, 'inside tax line cursor  way');
                    ELSE ln_tax := 0;
                    END IF;

   -- ------------------------------------------------------------
   -- Create and prorate tax lines for US Tax Code
   -- ------------------------------------------------------------
                           BEGIN

                              lc_error_loc :=
                                    'Checking for project or non project Invoices - Tax ';

                              lc_error_loc :=
                                    'Create and prorate tax line for US tax '
                                 || 'code.';
                                 IF ln_tax > 0 THEN

                                    IF (lr_tax_line_rec.project_id IS NULL) THEN -- Added for defect 6683

                                       --#--FND_FILE.PUT_LINE(FND_FILE.output, 'inside tax line cursor  insert');
                                       INSERT INTO ap_invoice_lines_interface
                                                   (invoice_id
                                                    ,invoice_line_id
                                                    ,line_type_lookup_code
                                                    ,line_number            --Defect 9420
                                                    ,line_group_number      --Defect 9420
                                                    ,prorate_across_flag    --Defect 9420
                                                    ,amount
                                                    ,tax_code
                                                    ,last_updated_by
                                                    ,last_update_date
                                                    ,created_by
                                                    ,creation_date
                                                    ,org_id
                                                    ,dist_code_combination_id -- Added for defect 6683, Code combination id
                                                    --dist_code_concatenated,
                                                    --po_number,
                                                    --po_line_number,
                                                    --po_shipment_num,
                                                    --po_distribution_num
                                                    --project_id,
                                                    --task_id,
                                                    --expenditure_type,
                                                    --project_accounting_context,
                                                    --expenditure_organization_id,
                                                    --expenditure_item_date
                                                   -- added the charge account to insert for Defect # 2021
                                                   )
                                            VALUES (lr_po_invoices_rec.invoice_id    --defect 2533
                                                    ,ln_invoice_line_id
                                                    ,l_inv_tax_line_type
                                                    ,ln_line_number                     --Defect 9420
                                                    ,lr_tax_line_rec.line_group_number  --Defect 9420
                                                    ,'Y'                        --Defect 9420/ Set to NULL for Defect# 27988 and 28294/--Modified to 'Y' for defect#28758
                                                    ,ln_tax      --defect 2533
                                                    ,lc_tax_code
                                                    ,lr_tax_line_rec.last_updated_by
                                                    ,lr_tax_line_rec.last_update_date
                                                    ,lr_tax_line_rec.created_by
                                                    ,lr_tax_line_rec.creation_date
                                                    ,lr_tax_line_rec.org_id
                                                    ,lr_tax_line_rec.charge_account -- Added for defect 6683, Code combination id
                                                    --lr_tax_line_rec.po_num,
                                                    --lr_tax_line_rec.po_line_number,
                                                    --lr_tax_line_rec.po_shipment_num,
                                                    --lr_tax_line_rec.po_distribution_num
                                                    --lr_tax_line_rec.project_id,
                                                    --lr_tax_line_rec.task_id,
                                                    --lr_tax_line_rec.expenditure_type,
                                                    --lr_tax_line_rec.project_accounting_context,
                                                    --lr_tax_line_rec.expenditure_organization_id,
                                                    --lr_tax_line_rec.expenditure_item_date
                                                   -- added the charge account to insert for Defect # 2021
                                                   );
                                        --#--FND_FILE.PUT_LINE(FND_FILE.output, 'inside tax line cursor  insert');
                                       ELSIF (lr_tax_line_rec.project_id IS NOT NULL) THEN -- Added for defect 6683

                                       INSERT INTO ap_invoice_lines_interface
                                                   (invoice_id
                                                    ,invoice_line_id
                                                    ,line_type_lookup_code
                                                    ,line_number            --Defect 9420
                                                    ,line_group_number      --Defect 9420
                                                    ,prorate_across_flag    --Defect 9420
                                                    ,amount
                                                    ,tax_code
                                                    ,last_updated_by
                                                    ,last_update_date
                                                    ,created_by
                                                    ,creation_date
                                                    ,org_id
                                                    --dist_code_concatenated, -- Removed for defect 6683
                                                    --po_number,
                                                    --po_line_number,
                                                    --po_shipment_num,
                                                    --po_distribution_num
                                                    --,project_id
                                                    --,task_id
                                                    --,expenditure_type
                                                    --,project_accounting_context
                                                    --,expenditure_organization_id
                                                    --,expenditure_item_date
                                                   -- added the charge account to insert for Defect # 2021
                                                   )
                                            VALUES (lr_po_invoices_rec.invoice_id    --defect 2533
                                                    ,ln_invoice_line_id
                                                    ,l_inv_tax_line_type
                                                    ,ln_line_number                     --Defect 9420
                                                    ,lr_tax_line_rec.line_group_number  --Defect 9420
                                                    ,'Y'                        --Defect 9420/Set to NULL for Defect# 27988 and 28294/--Modified to 'Y' for defect#28758
                                                    ,ln_tax --defect 2533
                                                    ,lc_tax_code
                                                    ,lr_tax_line_rec.last_updated_by
                                                    ,lr_tax_line_rec.last_update_date
                                                    ,lr_tax_line_rec.created_by
                                                    ,lr_tax_line_rec.creation_date
                                                    ,lr_tax_line_rec.org_id
                                                    --lr_tax_line_rec.charge_account, -- Removed for defect 6683
                                                    --lr_tax_line_rec.po_num,
                                                    --lr_tax_line_rec.po_line_number,
                                                    --lr_tax_line_rec.po_shipment_num,
                                                    --lr_tax_line_rec.po_distribution_num
                                                    --,lr_tax_line_rec.project_id
                                                    --,lr_tax_line_rec.task_id
                                                    --,lr_tax_line_rec.expenditure_type
                                                    --,lr_tax_line_rec.project_accounting_context
                                                    --,lr_tax_line_rec.expenditure_organization_id
                                                    --,lr_tax_line_rec.expenditure_item_date
                                                   -- added the charge account to insert for Defect # 2021
                                                   );
                                       END IF; -- Added for defect 6683
                              END IF;
                           END;
                           ln_line_number := ln_line_number + 1;
                        END LOOP;

                        IF lr_po_invoices_rec.type_lookup_code = 'STANDARD' THEN
                             CLOSE lcu_tax_lines;
                        ELSIF  lr_po_invoices_rec.type_lookup_code = 'BLANKET' THEN
                             CLOSE lcu_tax_lines_blanket;
                        END IF;

                     IF ln_total_tax_amount - ln_tot_tax_per_inv <> 0 THEN
                       UPDATE ap_invoice_lines_interface
                       SET amount = amount + (ln_total_tax_amount - ln_tot_tax_per_inv)
                       WHERE invoice_id = lr_po_invoices_rec.invoice_id
                       AND   invoice_line_id = ln_lar_tax_inv_ln_id;
                     END IF;

                       ln_lar_tax_inv_ln_id := NULL;
                       ln_tot_tax_per_inv := 0;
                       ln_lar_tax_amt := 0;

                     EXCEPTION
                        WHEN ZERO_DIVIDE
                        THEN
                           lc_error_loc :=
                                 'ZERO_DIVIDE Exception: Tax Line Exists '
                              || 'with ITEM line amounts totaling zero';
                           fnd_message.CLEAR;
                           fnd_message.set_name ('XXFIN',
                                                 'XX_AP_0026_TAX_PRORATE_ERR'
                                                );
                           fnd_message.set_token ('INVOICE_NUM',
                                                  lr_po_invoices_rec.invoice_num
                                                 );
                           fnd_message.set_token ('PO_NUM',
                                                  lr_po_invoices_rec.po_number
                                                 );
                           lc_error_msg := fnd_message.get;
                           fnd_file.put_line (fnd_file.LOG,
                                                 'XX_AP_CREATE_PO_INV_LINES: '
                                              || lc_error_msg
                                             );
                     END;

   -- ----------------------------------------------------------------
   --  Delete tax line from interface source
   -- ----------------------------------------------------------------
                     BEGIN
                        lc_error_loc :=
                              'Deleting TAX Line from source: '
                           || ln_tax_invoice_line_id;
                        --#--FND_FILE.PUT_LINE(FND_FILE.output, 'befoer delete');
                        DELETE      ap_invoice_lines_interface apl
                              WHERE apl.invoice_line_id = ln_tax_invoice_line_id;
                        --#--FND_FILE.PUT_LINE(FND_FILE.output, 'AFTER delete');
                     END;
                  END IF;
                 --ELSE -- added for Defect 4505
    --               lc_inv_rejected := 'N'; -- added for Defect 4505
    --             END IF; -- added for Defect 4505

            --Fixed defect 5000
            --Updated PO number to null at header level so that default PO number field is null
            UPDATE ap_invoices_interface
            SET po_number = NULL
            WHERE invoice_id = lr_po_invoices_rec.invoice_id;

            COMMIT;

         ELSIF lc_inv_match_exp_flag  = 'Y'  THEN      --added for Defect 13332 
          fnd_file.put_line(fnd_file.log,' At lc_inv_match_exp_flag=Y');
            -- Commit delete of three way match invoice without reciepts from the 
            -- interface tables added for Defect 13332 
            
            COMMIT;                                     --added for Defect 13332

         --Added for defect 5309
         ELSE
          fnd_file.put_line(fnd_file.log,'Rolling back the transaction');
            lc_error_loc := 'Rolling back the transaction';
            ROLLBACK TO sp_inv_var;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Transaction rolled back');

            /*DELETE FROM ap_invoice_lines_interface AILI
            WHERE  invoice_id = lr_po_invoices_rec.invoice_id
            AND    line_type_lookup_code = l_inv_item_line_type;*/

            lc_error_loc := 'Inserting $0 item line';
            SELECT NVL(MAX(line_number),0)
            INTO   ln_max_line_number
            FROM   ap_invoice_lines_interface AILI
            WHERE  invoice_id = lr_po_invoices_rec.invoice_id;

            SELECT ap_invoice_lines_interface_s.NEXTVAL
            INTO ln_invoice_line_id
            FROM DUAL;

            SELECT XFTV.target_value1
            INTO   lc_inv_var_account
            FROM   xx_fin_translatedefinition XFTD
                  ,xx_fin_translatevalues XFTV
                  ,hr_operating_units HOU
            WHERE  XFTD.translate_id = XFTV.translate_id
            AND   HOU.name = XFTV.source_value1
            AND   HOU.organization_id = lr_invoice_line_rec.org_id
            AND   XFTD.translation_name = 'AP_INV_VAR_ACCOUNT'
            AND   SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
            AND   SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
            AND   XFTV.enabled_flag = 'Y'
            AND   XFTD.enabled_flag = 'Y';

            INSERT INTO ap_invoice_lines_interface
                  (invoice_id
                   ,invoice_line_id
                   ,line_type_lookup_code
                   ,line_number     
                   ,amount  
                   ,description
                   ,last_updated_by
                   ,last_update_date
                   ,created_by
                   ,creation_date
                   ,org_id
                   ,dist_code_concatenated
                  )
            VALUES (lr_po_invoices_rec.invoice_id
                   ,ln_invoice_line_id
                   ,l_inv_item_line_type
                   ,ln_max_line_number + 1                   
                   --,0
				   ,0.01 --Modified for defect#28758
                   ,lr_po_invoices_rec.po_number
                   ,lr_po_invoices_rec.last_updated_by
                   ,lr_po_invoices_rec.last_update_date
                   ,lr_po_invoices_rec.created_by
                   ,lr_po_invoices_rec.creation_date
                   ,lr_po_invoices_rec.org_id 
                   ,lc_inv_var_account
                  ); 
            
            UPDATE ap_invoices_interface
            SET attribute11 = lr_po_invoices_rec.po_number
                ,po_number  = NULL
            WHERE invoice_id = lr_po_invoices_rec.invoice_id;

            UPDATE ap_invoice_lines_interface
            SET    prorate_across_flag = NULL
                  ,dist_code_concatenated = lc_inv_var_account
            WHERE invoice_id = lr_po_invoices_rec.invoice_id
            AND   line_type_lookup_code = l_inv_freight_line_type;

            COMMIT;

         END IF;         --Invoice variance branch
         --End of fix for defect 5309

         lc_tax_line_exists := 'N';
      END;
      END IF;       --PO valid branch
      
      ln_po_dist_tot := 0;
      ln_freight_amt := 0;
      ln_tax_amt     := 0;
      lc_inv_var_flag := 'N';
      
      FND_FILE.PUT_LINE(FND_FILE.LOG,'End of processing PO');
      END LOOP;

      CLOSE lcu_po_invoices;

   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_message.CLEAR;
         fnd_message.set_name ('XXFIN', 'XX_AP_0001_ERROR');
         fnd_message.set_token ('ERR_LOC', lc_error_loc);
         fnd_message.set_token ('ERR_DEBUG', lc_error_debug);
         fnd_message.set_token ('ERR_ORA', SQLERRM);
         lc_error_msg := fnd_message.get;
         fnd_file.put_line (fnd_file.LOG,
                               'Other Exception Encountered in '
                            || 'XX_AP_CREATE_PO_INV_LINES: '
                            || lc_error_msg
                           );
         xx_com_error_log_pub.log_error
                                  (p_program_type                => 'CONCURRENT PROGRAM',
                                   p_program_id                  => fnd_global.conc_program_id,
                                   p_module_name                 => 'AP',
                                   p_error_location              =>    'Error at '
                                                                    || lc_error_loc,
                                   p_error_message_count         => 1,
                                   p_error_message_code          => 'E',
                                   p_error_message               => lc_error_msg,
                                   p_error_message_severity      => 'Warning',
                                   p_notify_flag                 => 'N',
                                   p_object_type                 => 'PO Invoice Line',
                                   p_object_id                   => ''
                                  );
   END XX_AP_CREATE_PO_INV_LINES;

   PROCEDURE xx_ap_reset_invoice_stg (p_group_id IN VARCHAR2,
                                      p_invoice_id IN NUMBER)
   IS
   BEGIN
       --#--FND_FILE.PUT_LINE(FND_FILE.output, 'befoer delete of interface lines in reset');
       DELETE FROM ap_invoice_lines_interface
       WHERE invoice_id = p_invoice_id;
       --#--FND_FILE.PUT_LINE(FND_FILE.output, 'befoer delete of interface hdr in reset');
       DELETE FROM ap_invoices_interface
       WHERE group_id = p_group_id
       AND invoice_id = p_invoice_id;
       --#--FND_FILE.PUT_LINE(FND_FILE.output, 'befoer update of stg hdr in reset');
       UPDATE xx_ap_inv_interface_stg
       SET global_attribute16 = NULL
       WHERE group_id = p_group_id
       AND invoice_id = p_invoice_id;
       --#--FND_FILE.PUT_LINE(FND_FILE.output, 'befoer update of stg lines in reset');
       UPDATE xx_ap_inv_lines_interface_stg
       SET global_attribute16 = NULL
       WHERE invoice_id = p_invoice_id;
   EXCEPTION
   WHEN OTHERS THEN
    xx_com_error_log_pub.log_error
                                  (p_program_type                => 'CONCURRENT PROGRAM',
                                   p_program_id                  => fnd_global.conc_program_id,
                                   p_module_name                 => 'AP',
                                   p_error_location              =>    'Error at '
                                                                    || 'Error in restoring the failed invoices',
                                   p_error_message_count         => 1,
                                   p_error_message_code          => 'E',
                                   p_error_message               => 'Error in restoring the failed invoices',
                                   p_error_message_severity      => 'Warning',
                                   p_notify_flag                 => 'N',
                                   p_object_type                 => 'PO Invoice Line',
                                   p_object_id                   => ''
                                  );
   END xx_ap_reset_invoice_stg;
   
 -- +===================================================================+
-- | Name        : XX_AP_CREATE_TRDPO_INV_LINES                        |
-- |                                                                   |
-- | Description :                				                       |
-- |                                                                   |
-- | Parameters  : Input: Group Id                                     |
-- |                                                                   |
-- | Returns     : None                                                |
-- +===================================================================+

   PROCEDURE XX_AP_CREATE_TRDPO_INV_LINES(p_group_id IN VARCHAR2) IS
   
   CURSOR Trade_PO is
   select * 
   from ap_invoices_interface aii
   where ((aii.source = ('US_OD_TDM') AND (aii.group_id IS NULL or aii.group_id='TDM-TRADE') ) OR (aii.source = 'US_OD_DCI_TRADE') OR (aii.source = 'US_OD_DROPSHIP' AND invoice_type_lookup_code = 'STANDARD' AND attribute2 IS NULL)) -- Changes added as per version 3.2
   and attribute13 = '1'
   and not exists 
                 (select 'X' 
                    from  ap_invoice_lines_interface xxapl 
                   where  xxapl.invoice_id = aii.invoice_id
				     and  xxapl.line_type_lookup_code = 'ITEM'); -- Added as per Version 3.3
   
   CURSOR Trade_Po_lines(p_ponum VARCHAR2) IS
   SELECT poha.po_header_id
         ,pola.po_line_id
         ,pola.line_num
		 ,ROUND(pola.unit_price,2) unit_price -- Changes done as per Version 3.1
		 ,pola.item_id
         ,pola.item_description
		 ,pola.unit_meas_lookup_code
         ,sum(nvl(poda.quantity_ordered,0)-nvl(poda.quantity_billed,0))  Unbilled_qty
         ,sum((nvl(poda.quantity_ordered,0)-nvl(poda.quantity_billed,0))* ROUND(pola.unit_price,2))  Unbilled_amount -- Changes done as per Version 3.1
    FROM   po_distributions_all poda
          ,po_line_locations_all poll
          ,po_lines_all pola
          ,po_headers_all poha
   WHERE  poha.segment1=p_ponum
     AND  pola.po_header_id=poha.po_header_id
     AND  pola.po_line_id = poll.po_line_id
     AND  poll.line_location_id = poda.line_location_id
  GROUP BY poha.po_header_id
          ,pola.po_line_id
          ,pola.line_num
		  ,pola.item_id
		  ,pola.item_description
          -- ,poda.accrual_account_id
		  ,pola.unit_price
		  ,pola.unit_meas_lookup_code
   ;
   
   l_drp_count  NUMBER:=0;
   LN_INVOICE_LINE_ID NUMBER;
   Ln_invoice_exception varchar2(1);
   lc_closed_code       VARCHAR2(100);  -- : 3.6: Added  for NAIT-48588
   ln_po_header_id      VARCHAR2(100);  -- : 3.6: Added  for NAIT-48588 
   ln_line_number       NUMBER;         -- : 3.6: Added  for NAIT-48588
   lc_gl_string         VARCHAR2(100);  -- : 3.6: Added  for NAIT-48588 
   lc_description       VARCHAR2(100); -- : 3.6: Added  for NAIT-48588 
   lc_gl_account        VARCHAR2(50); -- : 3.6: Added   for NAIT-48588 
   lv_count             NUMBER;       -- : 3.6: Added   for NAIT-48588 
   
   BEGIN 
   
   FOR i IN Trade_PO loop
-- Start : 3.6: Added for NAIT-48588
lc_closed_code  :=NULL;
ln_po_header_id :=NULL;

BEGIN
SELECT closed_code  ,po_header_id
INTO lc_closed_code,ln_po_header_id
FROM po_headers_all
WHERE segment1=i.po_number
AND org_id=i.org_id;
EXCEPTION
WHEN OTHERS THEN
lc_closed_code :=NULL;
ln_po_header_id :=NULL;
END;

 -- To fetch the gl string from the PO Line Num = 1
BEGIN
			    lc_gl_string := NULL;
				SELECT  
				--cardinality(poh 1) INDEX(GL_CODE_COMBINATIONS XX_GL_CODE_COMBINATIONS_N8) 
                       gcck.concatenated_segments
				  INTO lc_gl_string
                  FROM po_headers_all poh,
                       po_lines_all pol,
                       po_distributions_all pod,
                       gl_code_combinations_kfv gcck
                 WHERE poh.po_header_id = pol.po_header_id
                   AND poh.po_header_id = pod.po_header_id
                   AND pol.po_line_id = pod.po_line_id
                   AND pod.code_combination_id = gcck.code_combination_id
                   AND poh.segment1 = i.po_number
                   AND pol.line_num = 1;
			 EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
				    lc_gl_string := NULL;
				WHEN OTHERS
                THEN
				    lc_gl_string := NULL;
             END; 
			 
 -- To fetch the GL Account and Description from the Translation for the Reason Code GV
             BEGIN
			 lc_gl_account := NULL;
			 lc_description := NULL;

            -- lc_error_loc :='Getting the reason code mapping for Gross Variance';
			    SELECT b.target_value6,
                       b.target_value2
				  INTO lc_gl_account,
				       lc_description
				  FROM xx_fin_translatevalues b,
					   xx_fin_translatedefinition a
				 WHERE a.translation_name='OD_AP_REASON_CD_ACCT_MAP'
				   AND b.translate_id=a.translate_id
				   AND b.enabled_flag='Y'
				   AND b.target_value1 = 'DS'
				   AND nvl(b.end_date_active,SYSDATE+1)>SYSDATE;
		     EXCEPTION
		     WHEN OTHERS
			 THEN
			   -- fnd_file.put_line(fnd_file.log,'Unable to get the new Invoice Line ID for new line');
			   lc_gl_account := NULL;
			   lc_description := NULL;
		     END;			 
lv_count :=0;			 
begin

select count(*)
into lv_count
from ap_invoice_lines_interface where invoice_id = i.invoice_id and po_header_id = ln_po_header_id;
end;			 

IF lc_closed_code IN ('FINALLY CLOSED','CLOSED') and lv_count = 0 THEN  -- Closed Code If

SELECT ap_invoice_lines_interface_s.NEXTVAL
            INTO ln_invoice_line_id
            FROM DUAL;


			
INSERT INTO ap_invoice_lines_interface
									   (invoice_id,
										invoice_line_id,
										line_number,
										line_type_lookup_code,
										amount,
										accounting_date,
										description,
										tax_code,
										po_header_id,
										po_number,
										po_line_id,
										po_line_number,
										po_distribution_num,
										po_unit_of_measure,
										quantity_invoiced,
										inventory_item_id,
										ship_to_location_code,
										unit_price,
										dist_code_concatenated,
										dist_code_combination_id,
										last_updated_by,
										last_update_date,
										last_update_login,
										created_by,
										creation_date,
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
										account_segment,
										balancing_segment,
										cost_center_segment,
										project_id,
										task_id,
										expenditure_type,
										expenditure_item_date,
										expenditure_organization_id,
										org_id,
										receipt_number,
										receipt_line_number,
										match_option,
										tax_code_id,
										external_doc_line_ref,
								        prorate_across_flag
									   )
							  VALUES    (i.invoice_id,
										ln_invoice_line_id,  -- ln_invoice_line_id,
										 1,
										'MISCELLANEOUS', --line_type_lookup_code,
										i.invoice_amount,
										NULL,
										lc_description,
										NULL,
										NULL, --po_header_id
										NULL, -- po_number,
										NULL, -- po_line_id,
										NULL, -- po_line_number,
										NULL, -- po_distribution_num,
										NULL, -- po_unit_of_measure,
										NULL,
										NULL,
										NULL,
										NULL,
										SUBSTR(lc_gl_string,1,4)||'.'||
                                        SUBSTR(lc_gl_string,6,5)||'.'||
                                        NVL(lc_gl_account,SUBSTR(lc_gl_string,12,8))||'.'||
                                        SUBSTR(lc_gl_string,21,6)||'.'||
                                        SUBSTR(lc_gl_string,28,4)||'.'||
                                        SUBSTR(lc_gl_string,33,2)||'.'||
                                        SUBSTR(lc_gl_string,36,6),
										NULL,
										NVL (fnd_profile.VALUE ('USER_ID'), 0),
										SYSDATE,
										-1,
										NVL(fnd_profile.VALUE ('USER_ID'), 0),
										SYSDATE,
										NULL,
										NULL,
										NULL,
										'Y',
										NULL,
										NULL,
										NULL,
										NULL,
										NULL,
										NULL,
										NULL, -- Added for Version 2.15
										NULL,
										NULL,
										NULL,
										NULL,
										NULL,
										NULL,
										NULL,
										NULL,
										NULL, 
										NULL,
										NULL,
										NULL,
										NULL,
										NVL (fnd_profile.VALUE ('ORG_ID'), 0),
										NULL,
										NULL,
										NULL,
										NULL,
										NULL,
								        NULL);
										
			/* INSERT 
			   INTO ap_invoice_lines_interface
					   (invoice_id,
						invoice_line_id,
						line_number,
						line_type_lookup_code,
						amount, 
						accounting_date,
						inventory_item_id,
						description,
						po_header_id,
						po_line_id,
						quantity_invoiced,
						unit_price,
						unit_of_meas_lookup_code,  
						last_updated_by,
						last_update_date,
						created_by,
						creation_date
					  )
				 VALUES
					  (i.invoice_id,
					  ln_invoice_line_id,
					   1,
					  'MISCELLANEOUS',
					  i.invoice_amount,
					  SYSDATE,
					  Null,
					  NULL,
					  ln_po_header_id, 
					  NULL,
					  1 ,
					  NULL,--i.invoice_amount,
					  NULL,--j.unit_meas_lookup_code,
					  NVL (fnd_profile.VALUE ('USER_ID'), 0),
					  SYSDATE,
					  NVL(fnd_profile.VALUE ('USER_ID'), 0),
					  SYSDATE
				  );
 */
ELSE 
ln_invoice_line_id :=null;
-- End : 3.6 Added for NAIT-48588

    FOR j IN Trade_Po_lines(i.po_number) loop
    
          SELECT ap_invoice_lines_interface_s.NEXTVAL
            INTO ln_invoice_line_id
            FROM DUAL;
			
			Ln_invoice_exception:='N';
     
       if j.Unbilled_qty = 0 then   
	       Ln_invoice_exception:='Y';
       --else  -- 3.6 commented for NAIT-48588
	   
	   ELSIf j.Unbilled_qty < 0 THEN -- Start : 3.6: Added for NAIT-48588
	   
	    -- To fetch the maximum line number
		     BEGIN
                ln_line_number := NULL;

			    SELECT MAX(LINE_NUMBER)
			      INTO ln_line_number
			      FROM ap_invoice_lines_interface
                 WHERE INVOICE_ID = i.invoice_id;
		     EXCEPTION
		     WHEN OTHERS
			 THEN
			   -- fnd_file.put_line(fnd_file.log,'Unable to get the new Invoice Line ID for new line');
			   ln_line_number := NULL;
		     END;
	   
	   INSERT INTO ap_invoice_lines_interface
									   (invoice_id,
										invoice_line_id,
										line_number,
										line_type_lookup_code,
										amount,
										accounting_date,
										description,
										tax_code,
										po_header_id,
										po_number,
										po_line_id,
										po_line_number,
										po_distribution_num,
										po_unit_of_measure,
										quantity_invoiced,
										inventory_item_id,
										ship_to_location_code,
										unit_price,
										dist_code_concatenated,
										dist_code_combination_id,
										last_updated_by,
										last_update_date,
										last_update_login,
										created_by,
										creation_date,
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
										account_segment,
										balancing_segment,
										cost_center_segment,
										project_id,
										task_id,
										expenditure_type,
										expenditure_item_date,
										expenditure_organization_id,
										org_id,
										receipt_number,
										receipt_line_number,
										match_option,
										tax_code_id,
										external_doc_line_ref,
								        prorate_across_flag
									   )
							  VALUES    (i.invoice_id,
										ln_invoice_line_id,  -- ln_invoice_line_id,
										ln_line_number + 1,
										'MISCELLANEOUS', --line_type_lookup_code,
										ROUND(j.Unbilled_amount,2),
										NULL,
										lc_description,
										NULL,
										NULL,
       									NULL, -- po_number,
										NULL, -- po_line_id,
										NULL, -- po_line_number,
										NULL, -- po_distribution_num,
										NULL, -- po_unit_of_measure,
										NULL,
										NULL,
										NULL,
										NULL,
										SUBSTR(lc_gl_string,1,4)||'.'||
                                        SUBSTR(lc_gl_string,6,5)||'.'||
                                        NVL(lc_gl_account,SUBSTR(lc_gl_string,12,8))||'.'||
                                        SUBSTR(lc_gl_string,21,6)||'.'||
                                        SUBSTR(lc_gl_string,28,4)||'.'||
                                        SUBSTR(lc_gl_string,33,2)||'.'||
                                        SUBSTR(lc_gl_string,36,6),
										NULL,
										NVL (fnd_profile.VALUE ('USER_ID'), 0),
										SYSDATE,
										-1,
										NVL(fnd_profile.VALUE ('USER_ID'), 0),
										SYSDATE,
										NULL,
										NULL,
										NULL,
										'Y',
										NULL,
										NULL,
										NULL,
										NULL,
										NULL,
										NULL,
										NULL, -- Added for Version 2.15
										NULL,
										NULL,
										NULL,
										NULL,
										NULL,
										NULL,
										NULL,
										NULL,
										NULL, 
										NULL,
										NULL,
										NULL,
										NULL,
										NVL (fnd_profile.VALUE ('ORG_ID'), 0),
										NULL,
										NULL,
										NULL,
										NULL,
										NULL,
								        NULL);
	   /* INSERT 
			   INTO ap_invoice_lines_interface
					   (invoice_id,
						invoice_line_id,
						line_number,
						line_type_lookup_code,
						amount, 
						accounting_date,
						inventory_item_id,
						description,
						po_header_id,
						po_line_id,
						quantity_invoiced,
						unit_price,
						unit_of_meas_lookup_code,  
						last_updated_by,
						last_update_date,
						created_by,
						creation_date
					  )
				 VALUES
					  (i.invoice_id,
					  ln_invoice_line_id,
					  1,
					  'MISCELLANEOUS',
					   ROUND(j.Unbilled_amount,2),
					  SYSDATE,
					  Null,
					  NULL,
					  j.po_header_id, 
					  NULL,
					  1,
					  NULL,--i.invoice_amount,
					  NULL,--j.unit_meas_lookup_code,  
					  NVL (fnd_profile.VALUE ('USER_ID'), 0),
					  SYSDATE,
					  NVL(fnd_profile.VALUE ('USER_ID'), 0),
					  SYSDATE
				  ); */
			ELSIF  j.Unbilled_qty > 0 THEN	  
	   -- End : 3.6 Added for NAIT-48588
      fnd_file.put_line(fnd_file.log,'Able to insert the data into ap_invoice_lines_interface Table');
		   INSERT 
			   INTO ap_invoice_lines_interface
					   (invoice_id,
						invoice_line_id,
						line_number,
						line_type_lookup_code,
						amount, 
						accounting_date,
						inventory_item_id,
						description,
						po_header_id,
						po_line_id,
						quantity_invoiced,
						unit_price,
						unit_of_meas_lookup_code,  -- -- Added as per version 3.4
						last_updated_by,
						last_update_date,
						created_by,
						creation_date
					  )
				 VALUES
					  (i.invoice_id,
					  ln_invoice_line_id,
					  j.line_num,
					  'ITEM',
					  ROUND(j.Unbilled_amount,2), -- Added ROUND function as per version 3.5
					  SYSDATE,
					  j.item_id,
					  j.item_description,
					  j.po_header_id,
					  j.po_line_id,
					  j.Unbilled_qty,
					  j.unit_price,
					  j.unit_meas_lookup_code,  -- Added as per version 3.4
					  NVL (fnd_profile.VALUE ('USER_ID'), 0),
					  SYSDATE,
					  NVL(fnd_profile.VALUE ('USER_ID'), 0),
					  SYSDATE
				  );

         End if;    

     END loop;
	 

	  
    
      -- check if it is a drop ship PO
       SELECT count(1) into l_drp_count
       FROM po_headers_all 
       WHERE segment1 = i.po_number
       AND attribute_category LIKE 'DropShip%';
       
       IF l_drp_count > 0 THEN
         UPDATE ap_invoices_interface 
         SET source= 'US_OD_DROPSHIP',
             attribute7 = 'US_OD_DROPSHIP',
			 group_id = null		 
         WHERE invoice_id = i.invoice_id;
         
       END IF;
	   
	   -- If any line unbilled qty is 0 then inawrt the record into custom exception table
	     IF Ln_invoice_exception ='Y' THEN
         Begin 
          INSERT INTO XX_AP_TR_MATCH_EXCEPTIONS 
         (Invoice_id,
				  Invoice_num,
				  vendor_id,
				  vendor_site_id,
				  exception_code, 
				  Exception_description, 
				  process_Flag,
				  last_updated_by,
				  last_update_date,
				  created_by,
				  creation_date
				 )
        VALUES
        (i.INVOICE_ID,
			   i.INVOICE_NUM, 
			   i.vendor_id, 
			   i.vendor_site_id, 
			   'E003',
         'For Voucher Build, No Unmatched Lines exists for the Invoice : '||i.INVOICE_NUM ,
			   'N', 
			   NVL(fnd_profile.VALUE ('USER_ID'), 0),
			   SYSDATE,
			   NVL(fnd_profile.VALUE ('USER_ID'), 0),
			   SYSDATE
			  );
			  
			    commit;
			  
         EXCEPTION 
		     WHEN OTHERS THEN
		      fnd_file.put_line (fnd_file.LOG,
                               'Other Exception Encountered while inserting unbilled_qty = 0 in '
                            || 'XX_AP_CREATE_TRDPO_INV_LINES: '
                            || SQLERRM
                             );
         End;
        END IF;

   commit;
   	 END IF; ---- Closed Code If 3.6: Added for NAIT-48588
   END loop;
COMMIT;   
      EXCEPTION
      WHEN OTHERS THEN
        
         fnd_file.put_line (fnd_file.LOG,
                               'Other Exception Encountered in '
                            || 'XX_AP_CREATE_TRDPO_INV_LINES: '
                            || SQLERRM
                           );

   END XX_AP_CREATE_TRDPO_INV_LINES;

END XX_AP_INV_BUILD_PO_LINES_PKG;
/
SHOW ERRORS;