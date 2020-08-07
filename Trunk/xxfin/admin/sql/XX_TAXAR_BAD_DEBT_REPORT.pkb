CREATE OR REPLACE PACKAGE BODY APPS.xx_taxar_bad_debt_report
AS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                       WIPRO Technologies                                |
-- +=========================================================================+
-- | Name        :      XX_TAXAR_BAD_DEBT_REPORT                             |
-- | Description : Procedure to extract the bad debts written off            |
-- |               and insert the corresponding Adjustment Numbers           |
-- |               to Custom Batch Audit Table                               |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date          Author              Remarks                      |
-- |=======   ==========   =============   ==================================|
-- |   1      02-AUG-08    SHESHI ODETI    Initial version                   |
-- |   2      07-Oct-08    SUBBU PILLAI    CR 433                            |
-- |   3      18-MAR-09    HARINI G        Added new procedure -             |
-- |                                       BAD_DEBT_VALUES.                  |
-- |                                       Defect fix for                    |
-- |                                       defect 13733                      |
-- |   4     17-APR-09     SUBBU PILLAI    Defect Fix - Defect 14246         |
-- |   5     28-May-09     GANGA DEVI R    Added Where conditions to         |
-- |                                       both BAD_DEBT_TRANSACTIONS        |
-- |                                       and BAD_DEBT_CREDITCARD           |
-- |                                       Procedures as per Defect#15482    |
-- |   6     20-Nov-09     GANGA DEVI R    Updated for defect #3207          |
-- |   7     19-Dec-09     POORNIMADEVI R  Added for the defect #3448        |
-- |   8     25-Dec-09     HARINI G           Added new procedure            |
-- |                                          BAD_DEBT_DISPUTES and updated  |
-- |                                          BAD_DEBT_TRANSACTIONS procedure|
-- |                                          for the the defect # 3674      |
-- |   9     25-Dec-09     Rama Krishna K     Modified Count(*) to Count(1)  |
-- |                                          for Performance Changes        |
-- |                                                                         |
-- |   10    28-Dec-2009   HARINI G         Added for  the Defect #3448      |
-- |   11   29-DEC-09     HARINI G         Modified code for defect 3448     |
-- |                                       in bad_debt_values,               |
-- |                                       respective Cursors and Insert stmt|
-- |   12   31-DEC-09     HARINI G         Reverting changes made in         |
-- |                                       version 11 for credit trx- 3448   |
-- |                                       1. Reverted BAD_DEBT_VALUES       |
-- |                                       2. Reverted changes for Credit trx|
-- |                                        -Removed the changes done as part|
-- |                                         of version 11.                  |
-- |   13  20-JAN-10      USHA R            Added refunds transactions
-- |                                       and proration logic for tax       |
-- |                                       calculation for defect 3448       |
-- |   14  02-FEB-10      USHA R            Modified the code for receipt paid
-- |                                       off Multiple Invoices and applied |
-- |                                       and proration logic for Regular   |
-- |                                       bad dept for defect 3448 and 3674 |
-- |   15  05-FEB-10     USHA R           Removed Pro-rated adjustment amount|
-- |                                      Column and Renamed the label       |
-- |                                      PRO-RATED GROSS AMOUNT to          |
-- |                                      GROSS ADJ AMOUNT for defect
-- |                                      3448 and 3674                      |
-- |   16  08-FEB-10     USHA R           Changed the sign for disputes amount
-- |                                      And Populating correct value for   |
-- |                                      prorated gross amount and tax amount
-- |                                      for defect 3674                    |
-- |   17  18-FEB-10     USHA R           Changed the code for populate the
-- |                                      Gross Adj amount and pro-rated tax |
-- |                                      amount in batch audit table and
-- |                                      added customer_trx_id column in batch
-- |                                      Audit and history table            |
-- |                                      for defect 4450                    |
-- |   18  02-JUN-10    SNEHA ANAND       Added Log messages and exception to|
-- |                                      the BAD_DEBT_VALUES procedure for  |
-- |                                      defect 6018                        |
-- |   19  17-JUN-10    RAMYAPRIYA        Modified for Defect #6018          |
-- |                                                                         |
-- |   20  10-MAR-11    SINON PERLAS      Modify program for SDR project     |
-- |                                                                         |
-- |   21  08-DEC-11    SINON PERLAS      Modify program for WEBCOLLECT-CR911|
-- |                                      Defect-15910                       |
-- |   22  25-APR-12    DHANISHYA         Modified for Defect 17226          |
-- |   23  20-JUN-12    Adithya           Modified for Defect 18774          |
-- |   24  30-AUG-12      Archana N.        Added print options before       |
-- |                            submission of the child request              |
-- |                                        defect# 19726 .                  |
-- |   25  10-OCT-12    DHANISHYA         Added Org Id condition to filter   |
-- |                                      data from batch sources for defect |
-- |                                      #20570                             |
-- |   26  19-MAR-13    DHANISHYA         Defect#22506-Replacing             |
-- |                                      Customer_trx_number with           |
-- |                                      customer_trx_id to get unique      |
-- |                                      records.                           |
-- |                                                                         |
-- |   27 20-JUN-2013    Shruthi Vasisht       Modified for R12              |
-- |                                             Upgrade retrofit            |
-- |   28 17-JAN-2014    Veronica M       Modified for defect 27634:         |
-- |                                 Included function is_legacy_batch_source|
-- |                                 from XX_AR_TWE_UTIL_PKG and             |
-- |                                 changes from TAXPKG_10_PARAM            |
-- |   29 10-NOV-2014    Dhanishya Raman      Defect#32418-added Org Id      |
-- |                                      condition in the select statement  |
-- |                                        of Batch source name 'OD_WC_CM'  |
-- |                                  Also Commented dispute_trx_number,     |
-- |                                       instead added customer_trx_id     |
-- |   30 20-OCT-2015    Havish Kasina     Removed the Schema References     |
-- |                                       in the existing code              |
-- |   31 23-May-2018    Suresh Ponnambalam Modified for SCM modernization   |
-- +=========================================================================+
--Global Variables:
   g_shipto_country              VARCHAR2 (100);
   g_shipto_city                 VARCHAR2 (100);
   g_shipto_cnty                 VARCHAR2 (100);
   g_shipto_state                VARCHAR2 (100);
   g_shipto_zip                  VARCHAR2 (100);
   g_shipto_code                 VARCHAR2 (100);
   g_shipfr_country              VARCHAR2 (100);
   g_shipfr_city                 VARCHAR2 (100);
   g_shipfr_cnty                 VARCHAR2 (100);
   g_shipfr_state                VARCHAR2 (100);
   g_shipfr_zip                  VARCHAR2 (100);
   g_shipfr_code                 VARCHAR2 (100);
   g_cust_name                   VARCHAR2 (50);
   g_gross_amt                   NUMBER;
   g_prorated_gross_amount       NUMBER := NULL;
                                         --Added for defect 3448 on 27-JAN-10
   g_prorated_tax_amount         NUMBER := NULL;
                                         --Added for defect 3448 on 27-JAN-10
   --g_prorated_adjustment_amount NUMBER :=NULL; --Added for defect 3448 on 27-JAN-10--Commented  for defect 3448 on 05-FEB-10
   g_tax_amt                     NUMBER := NULL;
                                         --Added for defect 3448 on 27-JAN-10
   g_order_date                  DATE;
   g_poa_country                 VARCHAR2 (100);
   g_poa_city                    VARCHAR2 (100);
   g_poa_cnty                    VARCHAR2 (100);
   g_poa_state                   VARCHAR2 (100);
   g_poa_zip                     VARCHAR2 (100);
   g_poa_code                    VARCHAR2 (100);
   g_poo_country                 VARCHAR2 (100);
   g_poo_city                    VARCHAR2 (100);
   g_poo_cnty                    VARCHAR2 (100);
   g_poo_state                   VARCHAR2 (100);
   g_poo_zip                     VARCHAR2 (100);
   g_poo_code                    VARCHAR2 (100);
   g_billto_country              VARCHAR2 (100);
   g_billto_city                 VARCHAR2 (100);
   g_billto_cnty                 VARCHAR2 (100);
   g_billto_state                VARCHAR2 (100);
   g_billto_zip                  VARCHAR2 (100);
   g_billto_code                 VARCHAR2 (100);
   g_customer_number             NUMBER;
   g_quantity                    NUMBER;
   g_company                     VARCHAR2 (100);
   g_period_start_date           DATE;               --Added for Defect 14246
   g_period_end_date             DATE;               --Added for Defect 14246
   g_error_flag                  VARCHAR2 (10) := NULL;
                                                      --Added for Defect 6018
   l_output                      UTL_FILE.file_type;
                                             --added for defect 10843 - sinon
   fname                         VARCHAR (50);
                                             --added for defect 10843 - sinon
   lc_ftp_process                VARCHAR2 (50);
                                             --added for defect 10843 - sinon
   ln_req_id                     NUMBER;     --added for defect 10843 - sinon
   lc_printer                    BOOLEAN;
                                       --added for defect# 19726 - Archana N.

--The get_string Function has been commented out as it is not necessary to have the function.
--We do not have to get the full string from this function because once the data enter the
--batch audit table,the full string will be retireved by I2083 before pushing it to the taxware
--tables. So this function is unnecessary at this stage.
-- +===================================================================+
-- | Name        : get_string                                          |
-- | Description : Function to derive Forcecountry based on the Invoice|
-- |               Number and data from TWE batch tables               |
-- |                                                                   |
-- | Parameters  :    p_invoice_no                                     |
-- +===================================================================+
/*FUNCTION get_string ( p_invoice_no  IN VARCHAR2 ) RETURN VARCHAR2
IS
    l_string         VARCHAR2(10000) := NULL;
    l_country_name   VARCHAR2(50)    := NULL;
  lc_error_loc     VARCHAR2(10000) := NULL;
    CURSOR c1(l_country_name  VARCHAR2) IS
        SELECT  DISTINCT
            '|TJ'||ltr.tj_type_id||'|'||to_char(ltr.tax_rate)||':'||100*ltr.tax_rate||':'||ltr.tax_name_id||':'||
            ltr.tax_rate_threshold_id||':'||ltr.tax_type_id||':'||ltr.exempt_amount||':100.0:'||ltr.tj_id||'~'||l_country_name||
            decode(tj2.parent_tj_id,'','~'||tj.tj_name,'~'||tj2.tj_name||'~'||tj.tj_name)||'|TJ'||ltr.tj_type_id||'|' a
        FROM            twe60trdb.Line_tj_result_audit@twe ltr,
          twe60trdb.line_item_audit@twe lta,
            twe60trdb.document_audit@twe  da,
            twe60trdb.tj@twe              tj,
            twe60trdb.tj@twe              tj2
        WHERE   da.transaction_doc_number =   p_invoice_no
        AND   ltr.line_item_audit_id      =   lta.line_item_audit_id
        AND     lta.document_audit_id     =   da.document_audit_id
        AND     ltr.tj_id = tj.tj_id
        AND     tj2.tj_id IN
            (
            SELECT tj1.tj_id FROM twe60trdb.tj@twe tj1 WHERE tj1.tj_id = tj.parent_tj_id
            )
        ORDER BY 1;
BEGIN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Before getting g_forcecountry');
        SELECT   DISTINCT tj2.tj_name
        INTO              l_country_name
        FROM
            twe60trdb.Line_tj_result_audit@twe ltr,
            twe60trdb.line_item_audit@twe lta,
            twe60trdb.document_audit@twe da,
            twe60trdb.tj@twe   tj,
            twe60trdb.tj@twe   tj2
        WHERE  da.transaction_doc_number     =   p_invoice_no
        AND    ltr.line_item_audit_id        =   lta.line_item_audit_id
        AND    lta.document_audit_id         =   da.document_audit_id
        AND    ltr.tj_id                     =   tj.tj_id
        AND    tj2.tj_id IN
            (
            SELECT tj1.tj_id FROM twe60trdb.tj@twe tj1 WHERE tj1.tj_id = tj.parent_tj_id
            )
        AND         tj2.parent_tj_id IS NULL
        AND         ROWNUM < 2       ;
        --FND_FILE.PUT_LINE(FND_FILE.LOG,'Before getting g_forcecountry'||l_country_name);
        FOR crec IN c1(l_country_name)
        LOOP
        l_string := l_string||crec.a;
        END LOOP;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'After Getting g_forcecountry'||l_string);
        RETURN l_string;
EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'String Cant Be Derived:');
END get_string;         */
-- +===================================================================+
-- | Name : BAD_DEBT_VALUES                                            |
-- | Description : Procedure to derive values for ship to ship from    |
-- |               and other values previously got from taxware tables.|
-- |                                                                   |
-- | Parameters :    p_trx_number                                      |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE bad_debt_values (
      p_trx_number               IN       VARCHAR2
     ,p_customer_trx_id          IN       NUMBER    ---Added for defect 17226
     ,p_dispute_trx_number       IN       VARCHAR2
                                         --Added for defect 3674 on 08-FEB-10
     ,p_adjusted_amount                   NUMBER
     ,p_flag                     IN       VARCHAR2
     ,p_reference_id                      NUMBER
                                       --Added for defect 3448 on 20-JAN-2010
     ,p_error_flag               OUT      VARCHAR2
   )                                                  --Added for defect 6018
   ---sinonremove,p_adj_amt_flag        OUT VARCHAR2) --SDR project sinon
   AS
      ln_ship_to_site_use_id        NUMBER;
      ln_customer_trx_id            NUMBER;
      ln_org_id                     NUMBER;
      ln_location_id                NUMBER;
      lc_source_name                VARCHAR2 (100);
      ln_customer_trx_line_id       NUMBER;
      ln_cust_trx_type_id           NUMBER;
      ln_invoice_amount             NUMBER;
                                       --Added for defect 3448 on 20-JAN-2010
      ln_tax_amount                 NUMBER;
                                       --Added for defect 3448 on 20-JAN-2010
      ln_prorated_tax               NUMBER (5, 2);
                                       --Added for defect 3448 on 20-JAN-2010
      ln_sign                       NUMBER;
                                       --Added for defect 3448 on 27-JAN-2010
      ln_gross_tax_amt              NUMBER;
      ln_gross_invoice_amt          NUMBER;
      ln_count                      NUMBER := NULL;
      ln_adjusted_amount            NUMBER (11, 2);
      lc_error_loc                  VARCHAR2 (30000) := NULL;
                                                      --Added for Defect 6018
   BEGIN
      ---sinonremovep_adj_amt_flag := 'N';  -- set this flag to 'N' as default value - sinon SDR project
        SELECT COUNT (1)
        INTO ln_count
        FROM ar_cash_receipts_all acr
            ,ar_receivable_applications_all ara
            ,ra_customer_trx_all rct
            ,ra_cust_trx_types_all rctt
       WHERE acr.cash_receipt_id = p_reference_id
         AND acr.cash_receipt_id = ara.cash_receipt_id
         AND ara.status = 'APP'
         AND ara.display = 'Y'
         AND ara.applied_customer_trx_id = rct.customer_trx_id
         AND rct.cust_trx_type_id = rctt.cust_trx_type_id
         AND rctt.TYPE = 'INV';



      IF (ln_count > 1)
      THEN
         lc_error_loc               :=
                                    'Getting the count of receipts '
                                 || ln_count;          --Added for Defect 6018

         SELECT NVL (SUM (rctl.extended_amount), 0)
           INTO ln_gross_invoice_amt
           FROM ar_cash_receipts_all acr
               ,ar_receivable_applications_all ara
               ,ra_customer_trx_all rct
               ,ra_customer_trx_lines_all rctl
          WHERE acr.cash_receipt_id = p_reference_id
            AND acr.cash_receipt_id = ara.cash_receipt_id
            AND ara.status = 'APP'
            AND ara.applied_customer_trx_id = rct.customer_trx_id
            AND rctl.customer_trx_id = rct.customer_trx_id
            AND rctl.line_type = 'LINE';

         SELECT NVL (SUM (rctl.extended_amount), 0)
           INTO ln_gross_tax_amt
           FROM ar_cash_receipts_all acr
               ,ar_receivable_applications_all ara
               ,ra_customer_trx_all rct
               ,ra_customer_trx_lines_all rctl
          WHERE acr.cash_receipt_id = p_reference_id
            AND acr.cash_receipt_id = ara.cash_receipt_id
            AND ara.status = 'APP'
            AND ara.applied_customer_trx_id = rct.customer_trx_id
            AND rctl.customer_trx_id = rct.customer_trx_id
            AND rctl.line_type = 'TAX';

         SELECT bs.NAME
               ,trx.org_id
               ,trx.customer_trx_id
               ,NVL (trx.ship_to_site_use_id, trx.bill_to_site_use_id)
               , (SELECT customer_trx_line_id
                    FROM ra_customer_trx_lines_all
                   WHERE customer_trx_id = trx.customer_trx_id
                     AND line_type = 'LINE'
                     AND ROWNUM < 2)
               , (SELECT interface_line_attribute10
                    FROM ra_customer_trx_lines_all
                   WHERE customer_trx_id = trx.customer_trx_id
                     AND line_type = 'LINE'
                     AND ROWNUM < 2)
               ,--  commented and added by shruthi for R12 Upgrade Retrofit
                -- RC.customer_name ,
                -- RC.customer_number ,
                hp.party_name
               ,hp.party_number
               -- end of addition
               ,trx.cust_trx_type_id
               , (SELECT SUM (rctl.quantity_invoiced)
                    FROM ra_customer_trx_lines_all rctl
                   WHERE rctl.customer_trx_id = trx.customer_trx_id
                     AND rctl.line_type = 'LINE')
               --NOTE:
               --1. COMMENTED THE BELOW LINE_AMOUNT AND TAX_AMOUNT COLUMNS AS IT SHOULD BE PICKED UP BASED ON THE QUANTITY/AMOUNT ADJUSTED - 3448 - 29-DEC-09
               --2. Reverted this change on 31st dec09 for 3448, that is removed the comments added, because these values would be required in the credit trx scenario
         ,      (SELECT NVL (SUM (rctl.extended_amount), 0)
                   FROM ra_customer_trx_lines_all rctl
                  WHERE rctl.customer_trx_id = trx.customer_trx_id
                    AND rctl.line_type = 'LINE')
               , (SELECT NVL (SUM (rctl.extended_amount), 0)
                    FROM ra_customer_trx_lines_all rctl
                   WHERE rctl.customer_trx_id = trx.customer_trx_id
                     AND rctl.line_type = 'TAX')
           INTO lc_source_name
               ,ln_org_id
               ,ln_customer_trx_id
               ,ln_ship_to_site_use_id
               ,ln_customer_trx_line_id
               ,ln_location_id
               ,g_cust_name
               ,g_customer_number
               ,ln_cust_trx_type_id
               ,g_quantity
               ,ln_invoice_amount         --Added for defect 3448 on 27-JAN-10
               ,ln_tax_amount             --Added for defect 3448 on 27-JAN-10
           FROM ra_customer_trx_all trx
               ,ra_batch_sources_all bs
               ,--  commented and added by shruthi for R12 Upgrade Retrofit
                -- ra_customers RC
                hz_parties hp,
                hz_cust_accounts hca
                -- end of addition
          WHERE trx.customer_trx_id =
                   p_customer_trx_id
----Defect#22506-Replacing Customer_trx_number with customer_trx_id to get unique records.
            --TRX.trx_number        = p_trx_number
            AND trx.batch_source_id = bs.batch_source_id
            --  commented and added by shruthi for R12 Upgrade Retrofit
            --  AND TRX.bill_to_customer_id = RC.customer_id;
            and hca.cust_account_id = trx.bill_to_customer_id
            and hca.party_id = hp.party_id;
            -- end of addition

         lc_error_loc               :=
               lc_error_loc
            || 'Line Amount: '
            || ln_gross_invoice_amt
            || 'Tax Amount:: '
            || ln_gross_tax_amt;                       --Added for Defect 6018
         --Added for defect 3448 on 27-JAN-10
         ln_sign                    := SIGN (ln_invoice_amount);

         IF (    ln_gross_invoice_amt = 0
             AND ln_gross_tax_amt = 0)
         THEN
            ln_adjusted_amount         := 0;
         ELSE
            ln_adjusted_amount         :=
                 (  p_adjusted_amount
                  * (  ln_invoice_amount
                     + ln_tax_amount)
                 )
               / (  ln_gross_invoice_amt
                  + ln_gross_tax_amt);
         END IF;

         /*sinonremoveIF (ABS(ln_adjusted_amount)>ABS(ln_invoice_amount)) THEN    --SDR project sinon evaluate adj vs original amount
         p_adj_amt_flag := 'Y';
         ELSE
         p_adj_amt_flag := 'N';
         END IF;*/
         IF (ABS (ln_adjusted_amount) = ABS (ln_invoice_amount))
         THEN
            g_gross_amt                := ln_invoice_amount;
            g_tax_amt                  := ln_tax_amount;
            g_prorated_gross_amount    := ln_invoice_amount;
            g_prorated_tax_amount      := ln_tax_amount;
         --g_prorated_adjustment_amount :=ln_adjusted_amount;--Commented  for defect 3448 on 05-FEB-10
         ELSE
            IF (p_flag = 'A')
            THEN
               IF (ln_sign IN (1, 0))
               THEN
                  g_gross_amt                := ln_invoice_amount;
                  g_tax_amt                  := ln_tax_amount;
                  ln_prorated_tax            :=
                     ABS ((  (  ln_adjusted_amount
                              * ln_tax_amount)
                           / (  ln_invoice_amount
                              + ln_tax_amount)
                          ));
                  g_prorated_gross_amount    :=
                                       ABS (ln_adjusted_amount)
                                     - ln_prorated_tax;
                  g_prorated_tax_amount      := ln_prorated_tax;
               --g_prorated_adjustment_amount := ln_adjusted_amount;--Commented  for defect 3448 on 05-FEB-10
               ELSE
                  g_gross_amt                := ln_invoice_amount;
                  g_tax_amt                  := ln_tax_amount;
                  ln_prorated_tax            :=
                     ABS ((  (  ln_adjusted_amount
                              * ln_tax_amount)
                           / (  ln_invoice_amount
                              + ln_tax_amount)
                          ));
                  g_prorated_gross_amount    :=
                                            ln_adjusted_amount
                                          - ln_prorated_tax;
                  g_prorated_tax_amount      :=   (ln_prorated_tax)
                                                * (-1);
               --g_prorated_adjustment_amount := ln_adjusted_amount;--Commented  for defect 3448 on 05-FEB-10
               END IF;
            ELSE                                                     -- p_flag
               g_gross_amt                := ln_invoice_amount;
               g_tax_amt                  := ln_tax_amount;
               ln_prorated_tax            :=
                  (  (  ln_adjusted_amount
                      * ln_tax_amount)
                   / (  ln_invoice_amount
                      + ln_tax_amount)
                  );
               g_prorated_gross_amount    :=
                                            ln_adjusted_amount
                                          - ln_prorated_tax;
               g_prorated_tax_amount      := ln_prorated_tax;
            --g_prorated_adjustment_amount :=ln_adjusted_amount;--Commented  for defect 3448 on 05-FEB-10
            END IF;                                                  -- p_flag
         END IF;

         lc_error_loc               :=
               lc_error_loc
            || 'Prorated Gross Amount: '
            || g_prorated_gross_amount
            || 'Prorated Tax Amount: '
            || g_prorated_tax_amount;                  --Added for Defect 6018
      ELSE                                                         -- ln_count
         lc_error_loc               :=
                                         'Count not equal to 1 '
                                      || lc_error_loc; --Added for Defect 6018

         SELECT bs.NAME
               ,trx.org_id
               ,trx.customer_trx_id
               ,NVL (trx.ship_to_site_use_id, trx.bill_to_site_use_id)
               , (SELECT customer_trx_line_id
                    FROM ra_customer_trx_lines_all
                   WHERE customer_trx_id = trx.customer_trx_id
                     AND line_type = 'LINE'
                     AND ROWNUM < 2)
               , (SELECT interface_line_attribute10
                    FROM ra_customer_trx_lines_all
                   WHERE customer_trx_id = trx.customer_trx_id
                     AND line_type = 'LINE'
                     AND ROWNUM < 2)
               ,/* commented and added by shruthi for R12 Upgrade Retrofit
                   RC.customer_name ,
                   RC.customer_number ,
                 */
                hp.party_name
               ,hp.party_number
               -- end of addition
               ,trx.cust_trx_type_id
               , (SELECT SUM (rctl.quantity_invoiced)
                    FROM ra_customer_trx_lines_all rctl
                   WHERE rctl.customer_trx_id = trx.customer_trx_id
                     AND rctl.line_type = 'LINE')
               --NOTE:
               --1. COMMENTED THE BELOW LINE_AMOUNT AND TAX_AMOUNT COLUMNS AS IT SHOULD BE PICKED UP BASED ON THE QUANTITY/AMOUNT ADJUSTED - 3448 - 29-DEC-09
               --2. Reverted this change on 31st dec09 for 3448, that is removed the comments added, because these values would be required in the credit trx scenario
         ,      (SELECT NVL (SUM (rctl.extended_amount), 0)
                   FROM ra_customer_trx_lines_all rctl
                  WHERE rctl.customer_trx_id = trx.customer_trx_id
                    AND rctl.line_type = 'LINE')
               , (SELECT NVL (SUM (rctl.extended_amount), 0)
                    FROM ra_customer_trx_lines_all rctl
                   WHERE rctl.customer_trx_id = trx.customer_trx_id
                     AND rctl.line_type = 'TAX')
           INTO lc_source_name
               ,ln_org_id
               ,ln_customer_trx_id
               ,ln_ship_to_site_use_id
               ,ln_customer_trx_line_id
               ,ln_location_id
               ,g_cust_name
               ,g_customer_number
               ,ln_cust_trx_type_id
               ,g_quantity
               ,ln_invoice_amount         --Added for defect 3448 on 27-JAN-10
               ,ln_tax_amount             --Added for defect 3448 on 27-JAN-10
           FROM ra_customer_trx_all trx
               ,ra_batch_sources_all bs
               ,--  commented and added by shruthi for R12 Upgrade Retrofit
                --  ra_customers RC  -- shruthi
                hz_parties hp,
                hz_cust_accounts hca
                -- end of addition
          WHERE trx.customer_trx_id =
                                     p_customer_trx_id
                                                      --Added For Defect 17226
            --TRX.trx_number          =  p_trx_number --Commented for Defect 17226
            AND trx.batch_source_id = bs.batch_source_id
            --  commented and added by shruthi for R12 Upgrade Retrofit
            -- AND TRX.bill_to_customer_id = RC.customer_id
           and hca.cust_account_id = trx.bill_to_customer_id
           and hca.party_id = hp.party_id
            -- end of addition
            AND trx.org_id = bs.org_id;       --Added as part of defect #20570

         --Added for defect 3448 on 27-JAN-10
         ln_sign                    := SIGN (ln_invoice_amount);
         lc_error_loc               :=
               lc_error_loc
            || ' Line Amount: '
            || ln_invoice_amount
            || ' Tax Amount:: '
            || ln_tax_amount;                          --Added for Defect 6018

         IF (ABS (p_adjusted_amount) = ABS (ln_invoice_amount))
         THEN
            g_gross_amt                := ln_invoice_amount;
            g_tax_amt                  := ln_tax_amount;
            g_prorated_gross_amount    := ln_invoice_amount;
            g_prorated_tax_amount      := ln_tax_amount;
         --g_prorated_adjustment_amount :=p_adjusted_amount;--Commented  for defect 3448 on 05-FEB-10
         ELSE
            IF (p_flag = 'A')
            THEN
               IF (ln_sign IN (1, 0))
               THEN
                  g_gross_amt                := ln_invoice_amount;
                  g_tax_amt                  := ln_tax_amount;
                  ln_prorated_tax            :=
                     ABS ((  (  p_adjusted_amount
                              * ln_tax_amount)
                           / (  ln_invoice_amount
                              + ln_tax_amount)
                          ));
                  g_prorated_gross_amount    :=
                                        ABS (p_adjusted_amount)
                                      - ln_prorated_tax;
                  g_prorated_tax_amount      := ln_prorated_tax;
               --g_prorated_adjustment_amount := p_adjusted_amount;--Commented  for defect 3448 on 05-FEB-10
               ELSE
                  g_gross_amt                := ln_invoice_amount;
                  g_tax_amt                  := ln_tax_amount;
                  ln_prorated_tax            :=
                     ABS ((  (  p_adjusted_amount
                              * ln_tax_amount)
                           / (  ln_invoice_amount
                              + ln_tax_amount)
                          ));
                  g_prorated_gross_amount    :=
                                             p_adjusted_amount
                                           - ln_prorated_tax;
                  g_prorated_tax_amount      :=   (ln_prorated_tax)
                                                * (-1);
               --g_prorated_adjustment_amount := p_adjusted_amount;--Commented  for defect 3448 on 05-FEB-10
               END IF;
            -- Added ELSIF condition for defect 3674 on 08-FEB-10
            ELSIF (p_flag = 'D')
            THEN
               g_gross_amt                := ln_invoice_amount;
               g_tax_amt                  := ln_tax_amount;

               SELECT (SELECT NVL (SUM (rctl.extended_amount), 0)
                         FROM ra_customer_trx_lines_all rctl
                        WHERE rctl.customer_trx_id = trx.customer_trx_id
                          AND rctl.line_type = 'LINE')
                     , (SELECT NVL (SUM (rctl.extended_amount), 0)
                          FROM ra_customer_trx_lines_all rctl
                         WHERE rctl.customer_trx_id = trx.customer_trx_id
                           AND rctl.line_type = 'TAX')
                 INTO ln_gross_invoice_amt
                     ,ln_gross_tax_amt
                 FROM ra_customer_trx_all trx
                WHERE --trx.trx_number = p_dispute_trx_number--commented Defect#32418
				trx.customer_trx_id=p_customer_trx_id;--added Defect#32418

               g_prorated_gross_amount    := ln_gross_invoice_amt;
               g_prorated_tax_amount      := ln_gross_tax_amt;
            ELSE                                                     -- p_flag
               g_gross_amt                := ln_invoice_amount;
               g_tax_amt                  := ln_tax_amount;
               ln_prorated_tax            :=
                  (  (  p_adjusted_amount
                      * ln_tax_amount)
                   / (  ln_invoice_amount
                      + ln_tax_amount)
                  );
               g_prorated_gross_amount    :=
                                             p_adjusted_amount
                                           - ln_prorated_tax;
               g_prorated_tax_amount      := ln_prorated_tax;
            --g_prorated_adjustment_amount := p_adjusted_amount;--Commented  for defect 3448 on 05-FEB-10
            END IF;                                                  -- p_flag
         END IF;

         lc_error_loc               :=
               lc_error_loc
            || 'Prorated Gross Amount: '
            || g_prorated_gross_amount
            || 'Prorated Tax Amount: '
            || g_prorated_tax_amount;                  --Added for Defect 6018
      END IF;                                                       --ln_count

      --End of Addition for defect 3448 on 27-JAN-10
      --BATCH SOURCE

      IF (--xx_ar_twe_util_pkg.is_legacy_batch_source (lc_source_name) =
	        is_legacy_batch_source (lc_source_name) =                              --Commented/Added for defect 27364
                                                                             1
         )
      THEN
         --taxpkg_10.g_is_legacy_order_batch := TRUE;
		 taxpkg_10_param.g_is_legacy_order_batch := TRUE;   -- Global variable created in taxpkg_10_param as part of Defect 27634
      ELSE
         --taxpkg_10.g_is_legacy_order_batch := FALSE;
		 taxpkg_10_param.g_is_legacy_order_batch := FALSE;  -- Global variable created in taxpkg_10_param as part of Defect 27634
      END IF;

      --SHIP TO
      lc_error_loc               :=
                                   lc_error_loc
                                || ' Getting the Ship To Details';
                                                       --Added for Defect 6018

      taxpkg_10_param.get_shipto
                                      (NULL                        --p_Cust_id
                                      ,ln_ship_to_site_use_id --p_Site_use_id,
                                      ,ln_customer_trx_id       --p_Cus_trx_id
                                      ,NULL         -- p_customer_trx_line_id,
                                      ,NULL
                                      ,ln_org_id
                                      ,g_shipto_country
                                      ,g_shipto_city
                                      ,g_shipto_cnty
                                      ,g_shipto_state
                                      ,g_shipto_zip
                                      ,g_shipto_code
                                      );
      --SHIP FROM
      lc_error_loc               :=
                                  lc_error_loc
                               || 'Getting the Ship From Details';
                                                       --Added for Defect 6018
      taxpkg_10_param.get_shipfrom
                           (NULL                                   --p_Cust_id
                           ,NULL                              --p_Site_use_id,
                           ,ln_customer_trx_id                  --p_Cus_trx_id
                           ,ln_customer_trx_line_id -- p_customer_trx_line_id,
                           ,ln_location_id
                           ,ln_org_id
                           ,'BAD_DEBT'
                           ,g_shipfr_country
                           ,g_shipfr_city
                           ,g_shipfr_cnty
                           ,g_shipfr_state
                           ,g_shipfr_zip
                           ,g_shipfr_code
                           );
--  commented and added by shruthi for R12 Upgrade Retrofit
    --  IF arp_tax.tax_info_rec.ship_from_code = 'XXXXXXXXXX' -- shruthi

    IF ZX_PRODUCT_INTEGRATION_PKG.tax_info_rec.ship_from_code = 'XXXXXXXXXX'
    -- end of addition
      THEN
         g_shipfr_country           := g_shipto_country;
         g_shipfr_state             := g_shipto_state;
         g_shipfr_cnty              := g_shipto_cnty;
         g_shipfr_city              := g_shipto_city;
         g_shipfr_zip               := g_shipto_zip;
      END IF;

      --POA
      lc_error_loc               :=    lc_error_loc
                                    || 'Getting the POA Details';
                                                       --Added for Defect 6018
      taxpkg_10_param.get_poa (NULL                         --p_Cust_id
                                     ,NULL                     --p_Site_use_id
                                     ,ln_customer_trx_id        --p_Cus_trx_id
                                     ,ln_customer_trx_line_id
                                     ,ln_location_id
                                     ,ln_org_id
                                     ,g_poa_country
                                     ,g_poa_city
                                     ,g_poa_cnty
                                     ,g_poa_state
                                     ,g_poa_zip
                                     ,g_poa_code
                                     ,g_order_date
                                     );
--  commented and added by shruthi for R12 Upgrade Retrofit
    --  IF arp_tax.tax_info_rec.poa_code = 'XXXXXXXXXX' -- shruthi
    IF ZX_PRODUCT_INTEGRATION_PKG.tax_info_rec.poa_code = 'XXXXXXXXXX'
    -- end of addition
      THEN
         g_poa_country              := g_shipfr_country;
         g_poa_state                := g_shipfr_state;
         g_poa_cnty                 := g_shipfr_cnty;
         g_poa_city                 := g_shipfr_city;
         g_poa_zip                  := g_shipfr_zip;
         g_poa_code                 := g_shipfr_code;
      END IF;

      --POO:
      lc_error_loc               :=    lc_error_loc
                                    || 'Getting the POO Details';
                                                       --Added for Defect 6018
      taxpkg_10_param.get_poo (NULL                                --p_Cust_id
                              ,NULL                           --p_Site_use_id,
                              ,ln_customer_trx_id               --p_Cus_trx_id
                              ,ln_customer_trx_line_id
                              ,ln_location_id
                              ,ln_org_id
                              ,g_poo_country
                              ,g_poo_city
                              ,g_poo_cnty
                              ,g_poo_state
                              ,g_poo_zip
                              ,g_poo_code
                              );
--  commented and added by shruthi for R12 Upgrade Retrofit
     -- IF arp_tax.tax_info_rec.poo_code = 'XXXXXXXXXX'-- shruthi

      IF ZX_PRODUCT_INTEGRATION_PKG.tax_info_rec.poo_code = 'XXXXXXXXXX'
      -- end of addition
      THEN
         g_poo_country              := g_shipfr_country;
         g_poo_state                := g_shipfr_state;
         g_poo_cnty                 := g_shipfr_cnty;
         g_poo_city                 := g_shipfr_city;
         g_poo_zip                  := g_shipfr_zip;
         g_poo_code                 := g_shipfr_code;
      END IF;

      --Bill To
      g_billto_country           := g_shipto_country;
      g_billto_state             := g_shipto_state;
      g_billto_cnty              := g_shipto_cnty;
      g_billto_city              := g_shipto_city;
      g_billto_zip               := g_shipto_zip;
      --Company Code:
      lc_error_loc               :=
                                lc_error_loc
                             || 'Geting the Company Code Details';
                                                       --Added for Defect 6018
      g_company                  :=
         taxpkg_10_param.get_organization (ln_org_id
                                          ,NULL
                                          ,ln_customer_trx_id
                                          ,ln_customer_trx_line_id
                                          ,NULL
                                          ,ln_cust_trx_type_id
                                          ,'BAD_DEBT'
                                          );
      p_error_flag               := 'N';
          --Added for defect 6018 to reset the error flag for each transaction
   EXCEPTION
      --Start of changes for Defect 6018
      WHEN NO_DATA_FOUND
      THEN
         fnd_file.put_line (fnd_file.LOG
                           ,    'For the Transaction No '
                             || p_trx_number);
         fnd_file.put_line (fnd_file.LOG
                           ,    'No data found at the error Location: '
                             || lc_error_loc
                             || ' where p_flag: '
                             || p_flag);
      WHEN OTHERS
      THEN
         --FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while '||SQLERRM);
         --RAISE;
         fnd_file.put_line (fnd_file.LOG, ' ');
         fnd_file.put_line (fnd_file.LOG
                           ,    'For the Transaction No: '
                             || p_trx_number);
         fnd_file.put_line (fnd_file.LOG, 'Error while '
                             || lc_error_loc);
         fnd_file.put_line (fnd_file.LOG, 'Error Message: '
                             || SQLERRM);
         g_error_flag               := 'Y';    --Setting the status to Warning
         p_error_flag               := 'Y';
                                       --exception flag for failed transaction
         fnd_file.put_line (fnd_file.LOG, ' ');
         fnd_file.put_line (fnd_file.LOG
                           ,    'Exception in BAD_DEBT_VALUES '
                             || 'Error Flag: '
                             || g_error_flag);
         fnd_file.put_line (fnd_file.LOG
                           ,    'Transaction Error Flag: '
                             || p_error_flag);
         fnd_file.put_line (fnd_file.LOG, ' ');
   --End of changes for Defect 6018
   END bad_debt_values;

---- FOR SDR PROJECT. Begin -Sinon
-- +===================================================================+
-- | Name : BAD_DEBT_VALUES_OM                                         |
-- | Description : Procedure to derive values for ship to ship from    |
-- |               and other values previously got from taxware tables.|
-- |                                                                   |
-- | Parameters  : p_trx_number                                        |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE bad_debt_values_om (
      p_trx_number               IN       VARCHAR2             -- ORDER NUMBER
     ,p_dispute_trx_number       IN       VARCHAR2                     -- NULL
     ,p_adjusted_amount                   NUMBER          -- ADJ.LINE_ADJUSTED
     ,p_flag                     IN       VARCHAR2
     ,p_reference_id                      NUMBER                        --NULL
     ,p_error_flag               OUT      VARCHAR2
   )
   AS
      ln_ship_to_site_use_id        NUMBER;
      ln_customer_trx_id            NUMBER;
      ln_org_id                     NUMBER;
      ln_location_id                NUMBER;
      lc_source_name                VARCHAR2 (100);
      ln_customer_trx_line_id       NUMBER;
      ln_cust_trx_type_id           NUMBER;
      ln_invoice_amount             NUMBER;
      ln_tax_amount                 NUMBER;
      ln_prorated_tax               NUMBER (5, 2);
      ln_sign                       NUMBER;
      ln_gross_tax_amt              NUMBER;
      ln_gross_invoice_amt          NUMBER;
      ln_count                      NUMBER := NULL;
      ln_adjusted_amount            NUMBER (11, 2);
      lc_error_loc                  VARCHAR2 (30000) := NULL;
      ln_location_id_char           fnd_flex_values.flex_value%TYPE;
   BEGIN

      SELECT NVL (SUM (  ol.unit_selling_price
                       * ol.fulfilled_quantity), 0)
            ,NVL (SUM (ol.fulfilled_quantity), 0)
        INTO ln_gross_invoice_amt
            ,g_quantity
        FROM xx_oe_order_lines_v ol, xx_oe_order_headers_v om
       WHERE om.order_number = TO_NUMBER (p_trx_number)
         AND om.header_id = ol.header_id;

      SELECT NVL (SUM (ol.tax_value), 0)
        INTO ln_gross_tax_amt
        FROM xx_oe_order_lines_v ol, xx_oe_order_headers_v om
       WHERE om.order_number = TO_NUMBER (p_trx_number)
         AND om.header_id = ol.header_id;

      SELECT NULL                                                    --BS.name
            ,om.org_id
            ,NULL                                     ---,XREF.customer_trx_id
            ,NVL (om.ship_to_org_id, 0)
            ,NULL
            ,NVL (org.location_id, 0)
            , (SELECT cust.account_name
                 FROM hz_cust_accounts cust
                WHERE cust_account_id = om.sold_to_org_id)  --Rc.Customer_Name
            , (SELECT cust.account_number
                 FROM hz_cust_accounts cust
                WHERE cust_account_id = om.sold_to_org_id)
                                                          --RC.customer_number
            ,NULL
            ,ln_gross_invoice_amt
            ,ln_gross_tax_amt
        INTO lc_source_name
            ,ln_org_id
            ,ln_customer_trx_id
            ,ln_ship_to_site_use_id
            ,ln_customer_trx_line_id
            ,ln_location_id
            ,g_cust_name
            ,g_customer_number
            ,ln_cust_trx_type_id
            --,g_quantity
      ,      ln_invoice_amount
            ,ln_tax_amount
        FROM xx_oe_order_headers_v om
                                         --,Xx_Ar_Order_Receipt_Dtl           Xar
             , hr_all_organization_units org
       WHERE om.order_number = p_trx_number
         --And   Om.Orig_Sys_Document_Ref = Xar.Orig_Sys_Document_Ref
         AND om.ship_from_org_id = org.organization_id
         AND EXISTS (
                SELECT *
                  FROM xx_ar_order_receipt_dtl xar
                 WHERE om.orig_sys_document_ref = xar.orig_sys_document_ref
                   AND xar.header_id = om.header_id);
                             ---Added to improve the performance Defect 17226;

      ln_sign                    := SIGN (ln_invoice_amount);

      IF (    ln_gross_invoice_amt = 0
          AND ln_gross_tax_amt = 0)
      THEN
         ln_adjusted_amount         := 0;
      ELSE
         ln_adjusted_amount         :=
              (  p_adjusted_amount
               * (  ln_invoice_amount
                  + ln_tax_amount)
              )
            / (  ln_gross_invoice_amt
               + ln_gross_tax_amt);
      END IF;

      IF (ABS (ln_adjusted_amount) = ABS (ln_invoice_amount))
      THEN
         g_gross_amt                := ln_invoice_amount;
         g_tax_amt                  := ln_tax_amount;
         g_prorated_gross_amount    := ln_invoice_amount;
         g_prorated_tax_amount      := ln_tax_amount;
      ELSE
         IF (p_flag = 'A')
         THEN
            IF (ln_sign IN (1, 0))
            THEN
               g_gross_amt                := ln_invoice_amount;
               g_tax_amt                  := ln_tax_amount;
               ln_prorated_tax            :=
                  ABS ((  (  ln_adjusted_amount
                           * ln_tax_amount)
                        / (  ln_invoice_amount
                           + ln_tax_amount)
                       ));
               g_prorated_gross_amount    :=
                                       ABS (ln_adjusted_amount)
                                     - ln_prorated_tax;
               g_prorated_tax_amount      := ln_prorated_tax;
            ELSE
               g_gross_amt                := ln_invoice_amount;
               g_tax_amt                  := ln_tax_amount;
               ln_prorated_tax            :=
                  ABS ((  (  ln_adjusted_amount
                           * ln_tax_amount)
                        / (  ln_invoice_amount
                           + ln_tax_amount)
                       ));
               g_prorated_gross_amount    :=
                                            ln_adjusted_amount
                                          - ln_prorated_tax;
               g_prorated_tax_amount      :=   (ln_prorated_tax)
                                             * (-1);
            END IF;
         ELSE                                                        -- p_flag
            g_gross_amt                := ln_invoice_amount;
            g_tax_amt                  := ln_tax_amount;
            ln_prorated_tax            :=
               (  (  ln_adjusted_amount
                   * ln_tax_amount)
                / (  ln_invoice_amount
                   + ln_tax_amount)
               );
            g_prorated_gross_amount    :=   ln_adjusted_amount
                                          - ln_prorated_tax;
            g_prorated_tax_amount      := ln_prorated_tax;
         END IF;                                                     -- p_flag
      END IF;

      lc_error_loc               :=
            lc_error_loc
         || 'Prorated Gross Amount: '
         || g_prorated_gross_amount
         || 'Prorated Tax Amount: '
         || g_prorated_tax_amount;                     --Added for Defect 6018
      --BATCH SOURCE --- ALWAYS FALSE FOR SDR
      --IF (xx_ar_twe_util_pkg.is_legacy_batch_source (lc_source_name) = 1) THEN
      --   Taxpkg_10.g_is_legacy_order_batch := TRUE;
      --ELSE
      --taxpkg_10.g_is_legacy_order_batch := FALSE;
	  taxpkg_10_param.g_is_legacy_order_batch := FALSE;    -- Global variable created in taxpkg_10_param as part of Defect 27634
      --End If;
      --SHIP FROM
      lc_error_loc               :=
                                  lc_error_loc
                               || 'Getting the Ship From Details';
                                                       --Added for Defect 6018

      -- FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_location_id: '||ln_location_id);
      SELECT SUBSTR (hl.location_code
                    ,1
                    ,30
                    )
            ,SUBSTR (hl.postal_code
                    ,1
                    ,5
                    )
            ,hl.town_or_city
            ,DECODE (hl.country
                    ,'CA', NULL
                    ,hl.region_1
                    )
            ,
             --County
             DECODE (hl.country
                    ,'CA', hl.region_1
                    ,hl.region_2
                    )
            ,
             --State
             DECODE (hl.country
                    ,'CA', 'CANADA'
                    ,'US', 'UNITED STATES'
                    )                                                --Country
        INTO g_shipfr_code
            ,g_shipfr_zip
            ,g_shipfr_city
            ,g_shipfr_cnty
            ,g_shipfr_state
            ,g_shipfr_country
        FROM hr_locations_all hl
       WHERE hl.location_id = ln_location_id;

      --FND_FILE.PUT_LINE(FND_FILE.LOG,'G_Shipfr_City: '||G_Shipfr_City);
      --SHIP TO
      g_shipto_country           := g_shipfr_country;
      g_shipto_state             := g_shipfr_state;
      g_shipto_cnty              := g_shipfr_cnty;
      g_shipto_city              := g_shipfr_city;
      g_shipto_zip               := g_shipfr_zip;
      --POA
      g_poa_country              := g_shipfr_country;
      g_poa_state                := g_shipfr_state;
      g_poa_cnty                 := g_shipfr_cnty;
      g_poa_city                 := g_shipfr_city;
      g_poa_zip                  := g_shipfr_zip;
      g_poa_code                 := g_shipfr_code;
      --POO:
      g_poo_country              := g_shipfr_country;
      g_poo_state                := g_shipfr_state;
      g_poo_cnty                 := g_shipfr_cnty;
      g_poo_city                 := g_shipfr_city;
      g_poo_zip                  := g_shipfr_zip;
      g_poo_code                 := g_shipfr_code;
      --Bill To
      g_billto_country           := g_shipfr_country;
      g_billto_state             := g_shipfr_state;
      g_billto_cnty              := g_shipfr_cnty;
      g_billto_city              := g_shipfr_city;
      g_billto_zip               := g_shipfr_zip;
      --Company Code:
      lc_error_loc               :=
                                lc_error_loc
                             || 'Geting the Company Code Details';
                                                       --Added for Defect 6018
      --/retrieve company
      --Fnd_File.Put_Line(Fnd_File.Log,'ln_location_id :'|| Ln_Location_Id);
      ln_location_id_char        := TO_CHAR (ln_location_id, 'FM000000');

      --FND_FILE.PUT_LINE(FND_FILE.LOG,'Ln_Location_Id_Char: |'||Ln_Location_Id_Char||'|');
      SELECT ffv.attribute1
        INTO g_company
        FROM fnd_flex_values ffv, fnd_flex_value_sets ffvs
       WHERE ffv.flex_value_set_id = ffvs.flex_value_set_id
         AND ffvs.flex_value_set_name = 'OD_GL_GLOBAL_LOCATION'
         AND ffv.flex_value = ln_location_id_char;

      --Fnd_File.Put_Line(Fnd_File.Log,'g_company: '||G_Company);
      p_error_flag               := 'N';
          --Added for defect 6018 to reset the error flag for each transaction
   EXCEPTION
      --Start of changes for Defect 6018
      WHEN NO_DATA_FOUND
      THEN
         fnd_file.put_line (fnd_file.LOG
                           ,    'For the Transaction No '
                             || p_trx_number);
         fnd_file.put_line (fnd_file.LOG
                           ,    'No data found at the error Location: '
                             || lc_error_loc
                             || ' where p_flag: '
                             || p_flag);
      WHEN OTHERS
      THEN
         --FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while '||SQLERRM);
         --RAISE;
         fnd_file.put_line (fnd_file.LOG, ' ');
         fnd_file.put_line (fnd_file.LOG
                           ,    'For the Transaction No: '
                             || p_trx_number);
         fnd_file.put_line (fnd_file.LOG, 'Error while '
                             || lc_error_loc);
         fnd_file.put_line (fnd_file.LOG, 'Error Message: '
                             || SQLERRM);
         g_error_flag               := 'Y';    --Setting the status to Warning
         p_error_flag               := 'Y';
                                       --exception flag for failed transaction
         fnd_file.put_line (fnd_file.LOG, ' ');
         fnd_file.put_line (fnd_file.LOG
                           ,    'Exception in BAD_DEBT_VALUES '
                             || 'Error Flag: '
                             || g_error_flag);
         fnd_file.put_line (fnd_file.LOG
                           ,    'Transaction Error Flag: '
                             || p_error_flag);
         fnd_file.put_line (fnd_file.LOG, ' ');
   --End of changes for Defect 6018
   END bad_debt_values_om;

---- FOR SDR PROJECT. End -Sinon
-- +===================================================================+
-- | Name        : BAD_DEBT_TRANSACTIONS                               |
-- | Description : Program to extract bad debt information on the      |
-- |               Transactions written off directly and insert into   |
-- |               Custom Batch Audit Table                            |
-- |                                                                   |
-- | Parameters  : p_od_calendar_month                                 |
-- |               p_error                                             |
-- | Added for CR 433                                                  |
-- | Changed the Signature for the Defect 14246
-- +===================================================================+
   PROCEDURE bad_debt_transactions (
      p_period_start_date        IN       DATE
     ,p_period_end_date          IN       DATE
     ,p_error                    IN OUT NOCOPY BOOLEAN
   )
   AS
      l_trx_number                  VARCHAR2 (100);
      -- l_forcecountry    VARCHAR2(10000) := NULL;  --Commented because we are going to get the string value anyway.
      -- l_da_count        NUMBER;
      l_batch_count                 NUMBER;
      l_batch_hist_count            NUMBER;
      lc_error_loc                  VARCHAR (30000) := NULL;
                                                     -- Added for defect 6018
      lc_error_flag                 VARCHAR2 (10) := NULL;
                                                     -- Added for defect 6018

      ---sinonremovelc_adj_amt_flag      VARCHAR2(10) :='N';   -- SDR project sinon adj amt > original amt
      CURSOR c_bad_debt_trx (
         c_period_start_date                 DATE
        ,c_period_end_date                   DATE
      )
      IS
         SELECT trx.trx_number trx_number
               ,adj.line_adjusted adjusted_amount
                                        --Added for defect 3448 on 27-JAN-2010
               ,'A' p_flag              --Added for defect 3448 on 20-JAN-2010
               ,NULL p_reference_id
               ,twe_ora_trx_id_s.NEXTVAL twe_ora_trx_id
               ,fnd_profile.VALUE ('ORG_ID') orcl_org_id
               --lnit6.country_name                          JRPARM_SHIPFR_COUNTRY,
               --lnit6.state_name                            JRPARM_SHIPFR_STATE,
               --lnit6.county_name                           JRPARM_SHIPFR_CNTY,
               --lnit6.city_name                             JRPARM_SHIPFR_CITY,
               --lnit6.postal_code                           JRPARM_SHIPFR_ZIP,
         ,      NULL jrparm_shipfr_geo
               ,NULL jrparm_shipfr_zipext
               --lnit2.country_name                          JRPARM_SHIPTO_COUNTRY,
               --lnit2.state_name                            JRPARM_SHIPTO_STATE,
               --lnit2.county_name                           JRPARM_SHIPTO_CNTY,
               --lnit2.city_name                             JRPARM_SHIPTO_CITY,
               --lnit2.postal_code                           JRPARM_SHIPTO_ZIP,
         ,      NULL jrparm_shipto_geo
               ,NULL jrparm_shipto_zipext
               ,NULL jrparm_shipto_geocode
               --lnit1.country_name                          JRPARM_POA_COUNTRY,
               --lnit1.state_name                            JRPARM_POA_STATE,
               --lnit1.county_name                           JRPARM_POA_CNTY,
               --lnit1.city_name                             JRPARM_POA_CITY,
               --lnit1.postal_code                           JRPARM_POA_ZIP,
         ,      NULL jrparm_poa_geo
               ,NULL jrparm_poa_zipext
               --lnit7.country_name                          JRPARM_POO_COUNTRY,
               --lnit7.state_name                            JRPARM_POO_STATE,
               --lnit7.county_name                           JRPARM_POO_CNTY,
               --lnit7.city_name                             JRPARM_POO_CITY,
               --lnit7.postal_code                           JRPARM_POO_ZIP,
         ,      NULL jrparm_poo_geo
               ,NULL jrparm_poo_zipext
               --lnit5.country_name                          JRPARM_BILLTO_COUNTRY,
               --lnit7.state_name                            JRPARM_BILLTO_STATE,
               --lnit7.county_name                           JRPARM_BILLTO_CNTY,
               --lnit7.city_name                             JRPARM_BILLTO_CITY,
               --lnit7.postal_code                           JRPARM_BILLTO_ZIP,
         ,      NULL jrparm_billto_geo
               ,NULL jrparm_billto_zipext
               ,NULL jrparm_billto_geocode
               ,'O' jrparm_pot
               --ABS(lta.gross_amount)                       TXPARM_GROSSAMT,
         ,      NVL (adj.line_adjusted, 0) txparm_grossamt
 --Added to get the line amount for the adjustment for defect 3448 - 29-DEC-09
               ,NULL txparm_frghtamt
               ,NULL txparm_discountamt
               --lta.business_party_code                     TXPARM_CUSTNO,
               --lta.business_party_name                     TXPARM_CUSTNAME,
               --lta.quantity                                TXPARM_NUMITEMS,
         ,      10 txparm_calctype
               ,NULL txparm_prodcode
               --decode(lta.debit_credit_ind, 2, 0, 1)       TXPARM_CREDITIND,
         ,      DECODE (SIGN (NVL (adj.line_adjusted, adj.tax_adjusted))
                       ,-1, 2
                       ,1
                       ) txparm_creditind             --Added for Defect 15482
               ,0 txparm_invoicesumind
               ,adj.apply_date txparm_invoicedate
               ,adj.adjustment_number txparm_invoiceno
               ,NULL txparm_invoicelineno
               --lta.ou_code                                 TXPARM_COMPANYID,
         ,      NULL txparm_locncode
               ,NULL txparm_costcenter
               ,1 txparm_reptind
               ,NULL txparm_jobno
               ,NULL txparm_volume
               ,NULL txparm_afeworkord
               ,NULL txparm_partnumber
               ,NULL txparm_miscinfo
               --da.currency_code                            TXPARM_CURRENCYCD1,
         ,      trx.invoice_currency_code txparm_currencycd1
               --lta.drop_shipper_ind_id                     TXPARM_DROPSHIPIND,
         ,      0 txparm_dropshipind
               ,NULL txparm_streasoncode
               ,'Y' txparm_audit_flag
               ,'Y' txparm_forcetrans
               --ABS(da.tax_amount)                          LOCAL_TOTAL_TAX,
         ,      NVL (adj.tax_adjusted, 0) local_total_tax
  --Added to get the tax amount for the adjustment for defect 3448 - 29-DEC-09
               ,NULL local_taxableamount
               ,NULL local_staterate
               ,NULL local_stateamnt_new
               ,NULL local_countyrate
               ,NULL local_countyamnt_new
               ,NULL local_cityrate
               ,NULL local_cityamnt_new
               ,NULL local_districtrate
               ,NULL local_districtamnt_new
               ,NULL txparm_forcestate
               ,NULL txparm_forcecounty
               ,NULL txparm_forcecity
               ,NULL txparm_forcedist
               ,NULL txparm_shipto_code
               ,NULL txparm_billto_code
               --lta.ship_from_location_code                 TXPARM_SHIPFROM_CODE,
               --lta.lor_location_code                       TXPARM_POO_CODE,
               --lta.loa_location_code                       TXPARM_POA_CODE,
         ,      NULL txparm_custom_attributes
               ,NULL taxware_trans_id
               ,NULL record_status
               ,NULL parent_request_id
               ,NULL request_id
               ,NULL thread_id
               ,NULL txparm_gencmplcd1
               ,NULL txparm_gencmplcd2
               ,NULL txparm_gencmpltxt
               ,NULL jrparm_returncode
               ,SYSDATE creation_date
               ,fnd_profile.VALUE ('USER_ID') created_by
               ,NULL last_update_date
               ,NULL last_updated_by
               ,NULL last_update_login
               ,trx.customer_trx_id customer_trx_id   -- Added for defect 4450
               ,    gcc.segment1
                 || '.'
                 || gcc.segment2
                 || '.'
                 || gcc.segment3
                 || '.'
                 || gcc.segment4
                 || '.'
                 || gcc.segment5
                 || '.'
                 || gcc.segment6
                 || '.'
                 || gcc.segment7 ACCOUNT                       ---14246 Defect
           FROM ar_adjustments_all adj
               ,ar_receivables_trx_all art
               ,xx_fin_translatedefinition td
               ,xx_fin_translatevalues tv
               ,ra_customer_trx_all trx
               ,ra_cust_trx_types_all ctt
               ,gl_code_combinations gcc
          --TWE60TRDB.document_audit@TWE           da,
          --TWE60TRDB.line_item_audit@TWE          lta,
          --TWE60TRDB.location_type_desc@TWE       lct1,
          --TWE60TRDB.location_type_desc@TWE       lct2,
          --TWE60TRDB.location_type_desc@TWE       lct3,
          --TWE60TRDB.location_type_desc@TWE       lct4,
          --TWE60TRDB.location_type_desc@TWE       lct5,
          --TWE60TRDB.location_type_desc@TWE       lct6,
          --TWE60TRDB.location_type_desc@TWE       lct7,
          --TWE60TRDB.line_item_loc_add_audit@TWE  lnit1,
          --TWE60TRDB.line_item_loc_add_audit@TWE  lnit2,
          --TWE60TRDB.line_item_loc_add_audit@TWE  lnit3,
          --TWE60TRDB.line_item_loc_add_audit@TWE  lnit4,
          --TWE60TRDB.line_item_loc_add_audit@TWE  lnit5,
          --TWE60TRDB.line_item_loc_add_audit@TWE  lnit6,
          --TWE60TRDB.line_item_loc_add_audit@TWE  lnit7
         WHERE  trx.cust_trx_type_id = ctt.cust_trx_type_id
            AND adj.receivables_trx_id = art.receivables_trx_id
            AND td.translation_name = 'OD_TAX_AR_BAD_DEBTS'
            AND td.translate_id = tv.translate_id
            AND art.NAME LIKE    tv.source_value1
                              || '%'
            AND adj.customer_trx_id = trx.customer_trx_id
            AND adj.org_id = fnd_profile.VALUE ('ORG_ID')
            AND adj.code_combination_id = gcc.code_combination_id
            AND adj.gl_date BETWEEN c_period_start_date AND c_period_end_date
                                                      --Added for Defect 14246
            AND ctt.TYPE != 'DM'
            AND adj.status = 'A'                      --Added for Defect 15482
            AND adj.TYPE IN ('INVOICE', 'TAX');       --Added for Defect 15482
   --AND da.transaction_doc_number = TRX.TRX_NUMBER
   --AND da.document_audit_id=lta.document_audit_id
   --AND lta.line_item_audit_id=lnit1.line_item_audit_id
   --AND lta.line_item_audit_id=lnit2.line_item_audit_id
   --AND lta.line_item_audit_id=lnit3.line_item_audit_id
   --AND lta.line_item_audit_id=lnit4.line_item_audit_id
   --AND lta.line_item_audit_id=lnit5.line_item_audit_id
   --AND lta.line_item_audit_id=lnit6.line_item_audit_id
   --AND lta.line_item_audit_id=lnit7.line_item_audit_id
   --AND lct1.location_type_id=lnit1.location_type_id
   --AND lct2.location_type_id=lnit2.location_type_id
   --AND lct3.location_type_id=lnit3.location_type_id
   --AND lct4.location_type_id=lnit4.location_type_id
   --AND lct5.location_type_id=lnit5.location_type_id
   --AND lct6.location_type_id=lnit6.location_type_id
   --AND lct7.location_type_id=lnit7.location_type_id
   --AND lct1.location_type_name='Location of Order of Approval'
   --AND lct2.location_type_name='Ship To'
   --AND lct3.location_type_name='Location of Service Performance'
   --AND lct4.location_type_name='Location of Use'
   --AND lct5.location_type_name='Bill To'
   --AND lct6.location_type_name='Ship From'
   --AND lct7.location_type_name='Location of Order of Recording'
   BEGIN
      -- Start of changes for Defect 6018
      /* FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
      FND_FILE.PUT_LINE(FND_FILE.LOG,FND_PROFILE.VALUE('ORG_ID'));
      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Parameters');
      FND_FILE.PUT_LINE(FND_FILE.LOG,p_period_start_date);
      FND_FILE.PUT_LINE(FND_FILE.LOG,p_period_end_date);
      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');*/
      -- End of changes for Defect 6018
      fnd_file.put_line (fnd_file.LOG, ' ');
      fnd_file.put_line (fnd_file.LOG, '------------------------------- ');
      fnd_file.put_line (fnd_file.LOG, 'Bad Debt Transactions');
      fnd_file.put_line (fnd_file.LOG, '------------------------------- ');
      fnd_file.put_line (fnd_file.LOG, ' ');
      ---Added three columns for defect 3448 on 27-JAN-10
      --Removed the column PRO-RATED ADJUSTMENT NUMBER and Rename the label PRO-RATED GROSS AMOUNT to GROSS ADJ AMOUNT for defect 3448 on 05-FEB-10
      fnd_file.put_line
         (fnd_file.LOG
         ,'BAD DEBT TYPE|INVOICE NO|ADJUSTMENT NUMBER|ORIGINAL INVOICE AMOUNT|ORIGINAL TAX AMOUNT|GROSS ADJ AMOUNT|PRO-RATED TAX AMOUNT|APPLY DATE|ACCOUNT|COMPANY ID|SHIP FROM CODE|SHIP FROM COUNTRY|SHIP FROM STATE|SHIP FROM COUNTY|SHIP FROM CITY|SHIP FROM ZIP|SHIP TO COUNTRY|SHIP TO STATE|SHIP TO COUNTY|SHIP TO CITY|SHIP TO ZIP|POA COUNTRY|POA STATE|POA COUNTY|POA CITY|POA ZIP|');
      fnd_file.put_line (fnd_file.LOG, ' ');

      FOR lcu_bad_debt_trx IN c_bad_debt_trx (p_period_start_date
                                             ,p_period_end_date)
      LOOP
         /********** To Check if the Adjustment has been processed already ********/
         /*SELECT count(*) into l_da_count
         FROM TWE60TRDB.document_audit@TWE           da                        --This has been commented because we are not
         WHERE transaction_doc_number=lcu_bad_debt_trx.TXPARM_INVOICENO;*/
         -- using any reference to taxware tables
         SELECT COUNT (1)
           INTO l_batch_count
           FROM xx_ar_twe_audit_trans_all twe
          WHERE txparm_invoiceno = lcu_bad_debt_trx.txparm_invoiceno
            AND customer_trx_id = lcu_bad_debt_trx.customer_trx_id;
                                                       --Added for defect 4450

         SELECT COUNT (1)
           INTO l_batch_hist_count
           FROM xx_ar_twe_audit_trans_all_hist twe
          WHERE txparm_invoiceno = lcu_bad_debt_trx.txparm_invoiceno
            AND customer_trx_id = lcu_bad_debt_trx.customer_trx_id;
                                                       --Added for defect 4450

         lc_error_flag              := NULL;
         lc_error_loc               := NULL;
                                         --Added for Defect #6018 on 17-JUN-10

         IF     l_batch_count = 0
            AND l_batch_hist_count = 0
         THEN                  --Removed this check condition IF l_da_count =0
            --l_trx_number       := lcu_bad_debt_trx.TRX_NUMBER;
            --fnd_file.put_line(FND_FILE.LOG, l_trx_number);
            --fnd_file.put_line(FND_FILE.LOG,'Before Inserting');
            --l_forcecountry     := get_string(l_trx_number);   --We are not using the function as we do not require the fullstring value
            --FETCHING VALUES FOR SHIPTO,SHIPFROM,POO,POA,BILLTO,COMPANY CODE
            fnd_file.put_line (fnd_file.LOG
                              ,    'Customer_trx_id :'
                                || lcu_bad_debt_trx.customer_trx_id);
            lc_error_loc               :=
                  lc_error_loc
               || ' Calling the BAD_DEBT_VALUES procedure from BAD_DEBT_TRANSACTIONS';
                                                       --Added for defect 6018
            bad_debt_values
               (lcu_bad_debt_trx.trx_number
               ,lcu_bad_debt_trx.customer_trx_id     --Added for defect #17226
               ,NULL                     --Added  for defect 3674 on 08-FEB-10
               ,lcu_bad_debt_trx.adjusted_amount
                                          --Added for defect 3448 on 27-JAN-10
               ,lcu_bad_debt_trx.p_flag  --Added  for defect 3448 on 27-JAN-10
               ,lcu_bad_debt_trx.p_reference_id
                                         --Added  for defect 3448 on 27-JAN-10
               ,lc_error_flag
               );                                      --Added for defect 6018

            ---sinonremove,lc_adj_amt_flag);                  --SDR project sinon
            IF lc_error_flag <> 'Y'
            THEN                                      -- Added for defect 6018
               ---sinonremoveIF lc_adj_amt_flag <> 'Y' THEN                           -- SDR project sinon - adj amt <= original amt
               IF (ABS (  g_gross_amt
                        + g_tax_amt) >=
                         ABS (  g_prorated_gross_amount
                              + g_prorated_tax_amount)
                  )
               THEN             -- SDR project sinon - adj amt <= original amt
                  INSERT INTO xx_ar_twe_audit_trans_all
                              (twe_ora_trx_id
                              ,orcl_org_id
                              ,jrparm_shipfr_country
                              ,jrparm_shipfr_state
                              ,jrparm_shipfr_cnty
                              ,jrparm_shipfr_city
                              ,jrparm_shipfr_zip
                              ,jrparm_shipfr_geo
                              ,jrparm_shipfr_zipext
                              ,jrparm_shipto_country
                              ,jrparm_shipto_state
                              ,jrparm_shipto_cnty
                              ,jrparm_shipto_city
                              ,jrparm_shipto_zip
                              ,jrparm_shipto_geo
                              ,jrparm_shipto_zipext
                              ,jrparm_shipto_geocode
                              ,jrparm_poa_country
                              ,jrparm_poa_state
                              ,jrparm_poa_cnty
                              ,jrparm_poa_city
                              ,jrparm_poa_zip
                              ,jrparm_poa_geo
                              ,jrparm_poa_zipext
                              ,jrparm_poo_country
                              ,jrparm_poo_state
                              ,jrparm_poo_cnty
                              ,jrparm_poo_city
                              ,jrparm_poo_zip
                              ,jrparm_poo_geo
                              ,jrparm_poo_zipext
                              ,jrparm_billto_country
                              ,jrparm_billto_state
                              ,jrparm_billto_cnty
                              ,jrparm_billto_city
                              ,jrparm_billto_zip
                              ,jrparm_billto_geo
                              ,jrparm_billto_zipext
                              ,jrparm_billto_geocode
                              ,jrparm_pot
                              ,txparm_grossamt
                              ,txparm_frghtamt
                              ,txparm_discountamt
                              ,txparm_custno
                              ,txparm_custname
                              ,txparm_numitems
                              ,txparm_calctype
                              ,txparm_prodcode
                              ,txparm_creditind
                              ,txparm_invoicesumind
                              ,txparm_invoicedate
                              ,txparm_invoiceno
                              ,txparm_invoicelineno
                              ,txparm_companyid
                              ,txparm_locncode
                              ,txparm_costcenter
                              ,txparm_reptind
                              ,txparm_jobno
                              ,txparm_volume
                              ,txparm_afeworkord
                              ,txparm_partnumber
                              ,txparm_miscinfo
                              ,txparm_currencycd1
                              ,txparm_dropshipind
                              ,txparm_streasoncode
                              ,txparm_audit_flag
                              ,txparm_forcetrans
                              ,local_total_tax
                              ,local_taxableamount
                              ,local_staterate
                              ,local_stateamnt_new
                              ,local_countyrate
                              ,local_countyamnt_new
                              ,local_cityrate
                              ,local_cityamnt_new
                              ,local_districtrate
                              ,local_districtamnt_new
                              ,
                               --TXPARM_FORCECOUNTRY,
                               txparm_forcestate
                              ,txparm_forcecounty
                              ,txparm_forcecity
                              ,txparm_forcedist
                              ,txparm_shipto_code
                              ,txparm_billto_code
                              ,txparm_shipfrom_code
                              ,txparm_poo_code
                              ,txparm_poa_code
                              ,txparm_custom_attributes
                              ,taxware_trans_id
                              ,record_status
                              ,parent_request_id
                              ,request_id
                              ,thread_id
                              ,txparm_gencmplcd1
                              ,txparm_gencmplcd2
                              ,txparm_gencmpltxt
                              ,jrparm_returncode
                              ,creation_date
                              ,created_by
                              ,last_update_date
                              ,last_updated_by
                              ,last_update_login
                              ,customer_trx_id
                  --Added the column xx_ar_twe_audit_trans_all for defect 4450
                              )
                       VALUES (lcu_bad_debt_trx.twe_ora_trx_id
                              ,lcu_bad_debt_trx.orcl_org_id
                              --lcu_bad_debt_trx.JRPARM_SHIPFR_COUNTRY,
                              --lcu_bad_debt_trx.JRPARM_SHIPFR_STATE,
                              --lcu_bad_debt_trx.JRPARM_SHIPFR_CNTY,
                              --lcu_bad_debt_trx.JRPARM_SHIPFR_CITY,
                              --lcu_bad_debt_trx.JRPARM_SHIPFR_ZIP,
                  ,            g_shipfr_country
                              ,g_shipfr_state
                              ,g_shipfr_cnty
                              ,g_shipfr_city
                              ,g_shipfr_zip
                              ,lcu_bad_debt_trx.jrparm_shipfr_geo
                              ,lcu_bad_debt_trx.jrparm_shipfr_zipext
                              --lcu_bad_debt_trx.JRPARM_SHIPTO_COUNTRY,
                              --lcu_bad_debt_trx.JRPARM_SHIPTO_STATE,
                              --lcu_bad_debt_trx.JRPARM_SHIPTO_CNTY,
                              --lcu_bad_debt_trx.JRPARM_SHIPTO_CITY,
                              --lcu_bad_debt_trx.JRPARM_SHIPTO_ZIP,
                  ,            g_shipto_country
                              ,g_shipto_state
                              ,g_shipto_cnty
                              ,g_shipto_city
                              ,g_shipto_zip
                              ,lcu_bad_debt_trx.jrparm_shipto_geo
                              ,lcu_bad_debt_trx.jrparm_shipto_zipext
                              ,lcu_bad_debt_trx.jrparm_shipto_geocode
                              --lcu_bad_debt_trx.JRPARM_POA_COUNTRY,
                              --lcu_bad_debt_trx.JRPARM_POA_STATE,
                              --lcu_bad_debt_trx.JRPARM_POA_CNTY,
                              --lcu_bad_debt_trx.JRPARM_POA_CITY,
                              --lcu_bad_debt_trx.JRPARM_POA_ZIP,
                  ,            g_poa_country
                              ,g_poa_state
                              ,g_poa_cnty
                              ,g_poa_city
                              ,g_poa_zip
                              ,lcu_bad_debt_trx.jrparm_poa_geo
                              ,lcu_bad_debt_trx.jrparm_poa_zipext
                              --lcu_bad_debt_trx.JRPARM_POO_COUNTRY,
                              --lcu_bad_debt_trx.JRPARM_POO_STATE,
                              --lcu_bad_debt_trx.JRPARM_POO_CNTY,
                              --lcu_bad_debt_trx.JRPARM_POO_CITY,
                              --lcu_bad_debt_trx.JRPARM_POO_ZIP,
                  ,            g_poo_country
                              ,g_poo_state
                              ,g_poo_cnty
                              ,g_poo_city
                              ,g_poo_zip
                              --g_poo_code,
                  ,            lcu_bad_debt_trx.jrparm_poo_geo
                              ,lcu_bad_debt_trx.jrparm_poo_zipext
                              --lcu_bad_debt_trx.JRPARM_BILLTO_COUNTRY,
                              --lcu_bad_debt_trx.JRPARM_BILLTO_STATE,
                              --lcu_bad_debt_trx.JRPARM_BILLTO_CNTY,
                              --lcu_bad_debt_trx.JRPARM_BILLTO_CITY,
                              --lcu_bad_debt_trx.JRPARM_BILLTO_ZIP,
                  ,            g_billto_country
                              ,g_billto_state
                              ,g_billto_cnty
                              ,g_billto_city
                              ,g_billto_zip
                              ,lcu_bad_debt_trx.jrparm_billto_geo
                              ,lcu_bad_debt_trx.jrparm_billto_zipext
                              ,lcu_bad_debt_trx.jrparm_billto_geocode
                              ,lcu_bad_debt_trx.jrparm_pot
                              --,g_gross_amt  -- Commented as the gross amount needs to be taken from the cursor for defect 3448 - 29-DEC-09--Reverted this line for defect 3448 on 27-JAN-10 --Commented for defect 4450
                  ,            NVL (g_prorated_gross_amount, 0)
                                                            --Added for defect
                              --,lcu_bad_debt_trx.TXPARM_GROSSAMT  -- Added this to get the value from the cursor for defect 3448 - 29-DEC-09--Commented this line for defect 3448 on 27-JAN-10
                  ,            lcu_bad_debt_trx.txparm_frghtamt
                              ,lcu_bad_debt_trx.txparm_discountamt
                              --lcu_bad_debt_trx.TXPARM_CUSTNO,
                  ,            g_customer_number
                              --lcu_bad_debt_trx.TXPARM_CUSTNAME,
                  ,            g_cust_name
                              --lcu_bad_debt_trx.TXPARM_NUMITEMS,
                  ,            g_quantity
                              ,lcu_bad_debt_trx.txparm_calctype
                              ,lcu_bad_debt_trx.txparm_prodcode
                              ,lcu_bad_debt_trx.txparm_creditind
                              ,lcu_bad_debt_trx.txparm_invoicesumind
                              ,lcu_bad_debt_trx.txparm_invoicedate
                              ,lcu_bad_debt_trx.txparm_invoiceno
                              ,lcu_bad_debt_trx.txparm_invoicelineno
                              --lcu_bad_debt_trx.TXPARM_COMPANYID,
                  ,            g_company
                              ,lcu_bad_debt_trx.txparm_locncode
                              ,lcu_bad_debt_trx.txparm_costcenter
                              ,lcu_bad_debt_trx.txparm_reptind
                              ,lcu_bad_debt_trx.txparm_jobno
                              ,lcu_bad_debt_trx.txparm_volume
                              ,lcu_bad_debt_trx.txparm_afeworkord
                              ,lcu_bad_debt_trx.txparm_partnumber
                              ,lcu_bad_debt_trx.txparm_miscinfo
                              ,lcu_bad_debt_trx.txparm_currencycd1
                              ,lcu_bad_debt_trx.txparm_dropshipind
                              ,lcu_bad_debt_trx.txparm_streasoncode
                              ,lcu_bad_debt_trx.txparm_audit_flag
                              ,lcu_bad_debt_trx.txparm_forcetrans
                              --,NVL(g_tax_amt,0) --Updated for defect3207 -- Commented as this value needs to be taken from cursor for defect 3448 - 29-DEC-09--Reverted this line for defect 3448 on 27-JAN-10--Commented for defect 4450
                  ,            NVL
                                  (g_prorated_tax_amount, 0)
                                                       --Added for defect 4450
                              --,lcu_bad_debt_trx.LOCAL_TOTAL_TAX          -- Added this to get the value from the cursor for defect 3448 - 29-DEC-09--Commented this line for defect 3448 on 27-JAN-10
                  ,            lcu_bad_debt_trx.local_taxableamount
                              ,lcu_bad_debt_trx.local_staterate
                              ,lcu_bad_debt_trx.local_stateamnt_new
                              ,lcu_bad_debt_trx.local_countyrate
                              ,lcu_bad_debt_trx.local_countyamnt_new
                              ,lcu_bad_debt_trx.local_cityrate
                              ,lcu_bad_debt_trx.local_cityamnt_new
                              ,lcu_bad_debt_trx.local_districtrate
                              ,lcu_bad_debt_trx.local_districtamnt_new
                              -- l_forcecountry,
                  ,            lcu_bad_debt_trx.txparm_forcestate
                              ,lcu_bad_debt_trx.txparm_forcecounty
                              ,lcu_bad_debt_trx.txparm_forcecity
                              ,lcu_bad_debt_trx.txparm_forcedist
                              ,lcu_bad_debt_trx.txparm_shipto_code
                              ,lcu_bad_debt_trx.txparm_billto_code
                              --lcu_bad_debt_trx.TXPARM_SHIPFROM_CODE,
                  ,            g_shipfr_code
                              --lcu_bad_debt_trx.TXPARM_POO_CODE,
                  ,            g_poo_code
                              --lcu_bad_debt_trx.TXPARM_POA_CODE,
                  ,            g_poa_code
                              ,lcu_bad_debt_trx.txparm_custom_attributes
                              ,lcu_bad_debt_trx.taxware_trans_id
                              ,lcu_bad_debt_trx.record_status
                              ,lcu_bad_debt_trx.parent_request_id
                              ,lcu_bad_debt_trx.request_id
                              ,lcu_bad_debt_trx.thread_id
                              ,lcu_bad_debt_trx.txparm_gencmplcd1
                              ,lcu_bad_debt_trx.txparm_gencmplcd2
                              ,lcu_bad_debt_trx.txparm_gencmpltxt
                              ,lcu_bad_debt_trx.jrparm_returncode
                              ,lcu_bad_debt_trx.creation_date
                              ,lcu_bad_debt_trx.created_by
                              ,lcu_bad_debt_trx.last_update_date
                              ,lcu_bad_debt_trx.last_updated_by
                              ,lcu_bad_debt_trx.last_update_login
                              ,lcu_bad_debt_trx.customer_trx_id
                                                       --Added for defect 4450
                              );

                  lc_error_loc               :=
                                             lc_error_loc
                                          || ' Insert Successful';
                  fnd_file.put_line
                     (fnd_file.output
                     ,    'T-'
                       || '|'
                       || lcu_bad_debt_trx.trx_number
                       || '|'
                       || lcu_bad_debt_trx.txparm_invoiceno
                       --||'|'||lcu_bad_debt_trx.TXPARM_GROSSAMT---Commenting this value for defect 3448 on 27-JAN-10
                       || '|'
                       || NVL
                             (g_gross_amt, 0)
-- Commenting this as the value to be taken from the cursor 3448 - 29-DEC-09---Reverted this for defect 3448 on 27-JAN-10
                       --||'|'||lcu_bad_debt_trx.LOCAL_TOTAL_TAX --Commenting this value for defect 3448 on 27-JAN-10
                       || '|'
                       || NVL
                             (g_tax_amt, 0)
-- Commenting this as the value to be taken from the cursor per 3448 - 29-DEC-09
                       || '|'
                       || g_prorated_gross_amount
                                          --Added for defect 3448 on 27-JAN-10
                       --||'|'||g_prorated_adjustment_amount--Added for defect 3448 on 27-JAN-10--Commented  for defect 3448 on 05-FEB-10
                       || '|'
                       || g_prorated_tax_amount
                                          --Added for defect 3448 on 27-JAN-10
                       || '|'
                       || lcu_bad_debt_trx.txparm_invoicedate
                       || '|'
                       || lcu_bad_debt_trx.ACCOUNT
                       || '|'
                       || g_company
                       || '|'
                       || g_shipfr_code
                       || '|'
                       || g_shipfr_country
                       || '|'
                       || g_shipfr_state
                       || '|'
                       || g_shipfr_cnty
                       || '|'
                       || g_shipfr_city
                       || '|'
                       || g_shipfr_zip
                       || '|'
                       || g_shipto_country
                       || '|'
                       || g_shipto_state
                       || '|'
                       || g_shipto_cnty
                       || '|'
                       || g_shipto_city
                       || '|'
                       || g_shipto_zip
                       || '|'
                       || g_poa_country
                       || '|'
                       || g_poa_state
                       || '|'
                       || g_poa_cnty
                       || '|'
                       || g_poa_city
                       || '|'
                       || g_poa_zip
                       || '|');
                  fnd_file.put_line
                     (fnd_file.LOG
                     ,    'T-'
                       || '|'
                       || lcu_bad_debt_trx.trx_number
                       || '|'
                       || lcu_bad_debt_trx.txparm_invoiceno
                       --||'|'||lcu_bad_debt_trx.TXPARM_GROSSAMT---Commenting this value for defect 3448 on 27-JAN-10
                       || '|'
                       || NVL
                             (g_gross_amt, 0)
-- Commenting this as the value to be taken from the cursor 3448 - 29-DEC-09--Reverted this for defect 3448 on 27-JAN-10
                       --||'|'||lcu_bad_debt_trx.LOCAL_TOTAL_TAX --Commenting this value for defect 3448 on 27-JAN-10
                       || '|'
                       || NVL
                             (g_tax_amt, 0)
-- Commenting this as the value to be taken from the cursor per 3448 - 29-DEC-09--Reverted this for defect 3448 on 27-JAN-10
                       || '|'
                       || g_prorated_gross_amount
                                          --Added for defect 3448 on 27-JAN-10
                       --||'|'||g_prorated_adjustment_amount--Added for defect 3448 on 27-JAN-10--Commented  for defect 3448 on 05-FEB-10
                       || '|'
                       || g_prorated_tax_amount
                                          --Added for defect 3448 on 27-JAN-10
                       || '|'
                       || lcu_bad_debt_trx.txparm_invoicedate
                       || '|'
                       || lcu_bad_debt_trx.ACCOUNT
                       || '|'
                       || g_company
                       || '|'
                       || g_shipfr_code
                       || '|'
                       || g_shipfr_country
                       || '|'
                       || g_shipfr_state
                       || '|'
                       || g_shipfr_cnty
                       || '|'
                       || g_shipfr_city
                       || '|'
                       || g_shipfr_zip
                       || '|'
                       || g_shipto_country
                       || '|'
                       || g_shipto_state
                       || '|'
                       || g_shipto_cnty
                       || '|'
                       || g_shipto_city
                       || '|'
                       || g_shipto_zip
                       || '|'
                       || g_poa_country
                       || '|'
                       || g_poa_state
                       || '|'
                       || g_poa_cnty
                       || '|'
                       || g_poa_city
                       || '|'
                       || g_poa_zip
                       || '|');
               -- END IF;                                            -- Added for defect 6018
               ELSE              -- SDR project sinon - adj amt > original amt
                  lc_error_loc               :=
                        lc_error_loc
                     || ' Writing to UTL File in XXFIN_OUTBOUND '
                     || lcu_bad_debt_trx.trx_number
                     || ' AND '
                     || lcu_bad_debt_trx.txparm_invoiceno;
                                                   -- Add for the defect 17226
                  UTL_FILE.put_line
                     (l_output
                     ,    ' '
                       || '|'
                       || lcu_bad_debt_trx.trx_number
                       || '|'
                       || lcu_bad_debt_trx.txparm_invoiceno
                       || '|'
                       || NVL
                             (g_gross_amt, 0)
-- Commenting this as the value to be taken from the cursor 3448 - 29-DEC-09---Reverted this for defect 3448 on 27-JAN-10
                       || '|'
                       || NVL
                             (g_tax_amt, 0)
-- Commenting this as the value to be taken from the cursor per 3448 - 29-DEC-09
                       || '|'
                       || g_prorated_gross_amount
                                          --Added for defect 3448 on 27-JAN-10
                       || '|'
                       || g_prorated_tax_amount
                                          --Added for defect 3448 on 27-JAN-10
                       || '|'
                       || lcu_bad_debt_trx.txparm_invoicedate
                       || '|'
                       || lcu_bad_debt_trx.ACCOUNT
                       || '|'
                       || g_company
                       || '|'
                       || g_shipfr_code
                       || '|'
                       || g_shipfr_country
                       || '|'
                       || g_shipfr_state
                       || '|'
                       || g_shipfr_cnty
                       || '|'
                       || g_shipfr_city
                       || '|'
                       || g_shipfr_zip
                       || '|'
                       || g_shipto_country
                       || '|'
                       || g_shipto_state
                       || '|'
                       || g_shipto_cnty
                       || '|'
                       || g_shipto_city
                       || '|'
                       || g_shipto_zip
                       || '|'
                       || g_poa_country
                       || '|'
                       || g_poa_state
                       || '|'
                       || g_poa_cnty
                       || '|'
                       || g_poa_city
                       || '|'
                       || g_poa_zip
                       || '|'
                       || 'Exception due to chargeback > original transaction amount');
                  UTL_FILE.fflush (l_output);
               END IF;  -- SDR project sinon - compare adj amt to original amt
            END IF;
         END IF;
      END LOOP;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         --Start of changes for defect 6018
         fnd_file.put_line (fnd_file.LOG, ' ');
         fnd_file.put_line (fnd_file.LOG, lc_error_loc);
         fnd_file.put_line (fnd_file.LOG, 'Error while '
                             || SQLERRM);
         --   p_error := FALSE;
         --   RAISE;
         --   FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message: '||SQLERRM);
         g_error_flag               := 'Y';
         fnd_file.put_line (fnd_file.LOG, ' ');
         fnd_file.put_line (fnd_file.LOG
                           ,    'Exception in BAD_DEBT_TRANSACTIONS '
                             || 'Error Flag: '
                             || g_error_flag);
         fnd_file.put_line (fnd_file.LOG, ' ');
   --End of changes for defect 6018
   END bad_debt_transactions;

-- +===================================================================+
-- | Name        : BAD_DEBT_CREDITCARD                                 |
-- | Description : Program to extract bad debt information and insert  |
-- |               into Custom Batch Audit Table                       |
-- |                                                                   |
-- | Parameters  : p_od_calendar_month                                 |
-- |               p_od_chargeback_type1                               |
-- |               p_od_chargeback_type2                               |
-- |               p_od_chargeback_type3                               |
-- |               p_od_chargeback_type4                               |
-- |               p_od_chargeback_type5                               |
-- |               p_od_chargeback_type6                               |
-- |               p_od_chargeback_type7                               |
-- |               p_od_chargeback_type8                               |
-- |               p_od_chargeback_type9                               |
-- |               p_od_chargeback_type10                              |
-- |               p_error                                             |
-- | Returns     :                                                     |
-- |               p_error                                             |
-- +===================================================================+
   PROCEDURE bad_debt_creditcard (
      p_period_start_date        IN       DATE
     ,p_period_end_date          IN       DATE
     ,p_od_chargeback_type1      IN       VARCHAR2
     ,p_od_chargeback_type2      IN       VARCHAR2
     ,p_od_chargeback_type3      IN       VARCHAR2
     ,p_od_chargeback_type4      IN       VARCHAR2
     ,p_od_chargeback_type5      IN       VARCHAR2
     ,p_od_chargeback_type6      IN       VARCHAR2
     ,p_od_chargeback_type7      IN       VARCHAR2
     ,p_od_chargeback_type8      IN       VARCHAR2
     ,p_od_chargeback_type9      IN       VARCHAR2
     ,p_od_chargeback_type10     IN       VARCHAR2
     ,p_error                    IN OUT NOCOPY BOOLEAN
   )
   AS
      l_twe_ora_trx_id              NUMBER;           --Added for Defect#3448
      --lp_calendar_month    VARCHAR2(100) := p_od_calendar_month;
      lp_period_start_date          DATE := p_period_start_date;
      lp_period_end_date            DATE := p_period_end_date;
      lp_chargeback_type1           VARCHAR2 (100) := p_od_chargeback_type1;
      lp_chargeback_type2           VARCHAR2 (100) := p_od_chargeback_type2;
      lp_chargeback_type3           VARCHAR2 (100) := p_od_chargeback_type3;
      lp_chargeback_type4           VARCHAR2 (100) := p_od_chargeback_type4;
      lp_chargeback_type5           VARCHAR2 (100) := p_od_chargeback_type5;
      lp_chargeback_type6           VARCHAR2 (100) := p_od_chargeback_type6;
      lp_chargeback_type7           VARCHAR2 (100) := p_od_chargeback_type7;
      lp_chargeback_type8           VARCHAR2 (100) := p_od_chargeback_type8;
      lp_chargeback_type9           VARCHAR2 (100) := p_od_chargeback_type9;
      lp_chargeback_type10          VARCHAR2 (100) := p_od_chargeback_type10;
      lc_error_msg                  VARCHAR2 (1000);
      ln_req_id                     NUMBER;
      l_trx_number                  VARCHAR2 (100);
      l_forcecountry                VARCHAR2 (10000) := NULL;
      l_da_count                    NUMBER;
      l_batch_count                 NUMBER;
      l_batch_hist_count            NUMBER;
      lc_error_loc                  VARCHAR2 (30000) := NULL;
                                                      --Added for defect 6018
      lc_error_flag                 VARCHAR2 (10);   -- Added for defect 6018

      ---sinonremovelc_adj_amt_flag      VARCHAR2(10) :='N';   -- SDR project sinon adj amt > original amt
      CURSOR c_bad_debt_credit (
         p_period_start_date        IN       DATE
        ,p_period_end_date          IN       DATE
        ,p_od_chargeback_type1               VARCHAR2
        ,p_od_chargeback_type2               VARCHAR2
        ,p_od_chargeback_type3               VARCHAR2
        ,p_od_chargeback_type4               VARCHAR2
        ,p_od_chargeback_type5               VARCHAR2
        ,p_od_chargeback_type6               VARCHAR2
        ,p_od_chargeback_type7               VARCHAR2
        ,p_od_chargeback_type8               VARCHAR2
        ,p_od_chargeback_type9               VARCHAR2
        ,p_od_chargeback_type10              VARCHAR2
      )
      IS
         (SELECT trx.trx_number trx_number
                ,adj.line_adjusted adjusted_amount
                                        --Added for defect 3448 on 20-JAN-2010
                ,'A' p_flag             --Added for defect 3448 on 20-JAN-2010
                ,acr.cash_receipt_id p_reference_id
                                        --Added for defect 3448 on 20-JAN-2010
                --,TWE_ORA_TRX_ID_s.nextval                TWE_ORA_TRX_ID
          ,      fnd_profile.VALUE ('ORG_ID') orcl_org_id
                --lnit6.country_name                    JRPARM_SHIPFR_COUNTRY,
                --lnit6.state_name                      JRPARM_SHIPFR_STATE,
                --lnit6.county_name                     JRPARM_SHIPFR_CNTY,
                --lnit6.city_name                       JRPARM_SHIPFR_CITY,
                --lnit6.postal_code                     JRPARM_SHIPFR_ZIP,
          ,      NULL jrparm_shipfr_geo
                ,NULL jrparm_shipfr_zipext
                --lnit2.country_name                    JRPARM_SHIPTO_COUNTRY,
                --lnit2.state_name                      JRPARM_SHIPTO_STATE,
                --lnit2.county_name                     JRPARM_SHIPTO_CNTY,
                --lnit2.city_name                       JRPARM_SHIPTO_CITY,
                --lnit2.postal_code                     JRPARM_SHIPTO_ZIP,
          ,      NULL jrparm_shipto_geo
                ,NULL jrparm_shipto_zipext
                ,NULL jrparm_shipto_geocode
                --lnit1.country_name                    JRPARM_POA_COUNTRY,
                --lnit1.state_name                      JRPARM_POA_STATE,
                --lnit1.county_name                     JRPARM_POA_CNTY,
                --lnit1.city_name                       JRPARM_POA_CITY,
                --lnit1.postal_code                     JRPARM_POA_ZIP,
          ,      NULL jrparm_poa_geo
                ,NULL jrparm_poa_zipext
                --lnit7.country_name                    JRPARM_POO_COUNTRY,
                --lnit7.state_name                      JRPARM_POO_STATE,
                --lnit7.county_name                     JRPARM_POO_CNTY,
                --lnit7.city_name                       JRPARM_POO_CITY,
                --lnit7.postal_code                     JRPARM_POO_ZIP,
          ,      NULL jrparm_poo_geo
                ,NULL jrparm_poo_zipext
                --lnit5.country_name                    JRPARM_BILLTO_COUNTRY,
                --lnit7.state_name                      JRPARM_BILLTO_STATE,
                --lnit7.county_name                     JRPARM_BILLTO_CNTY,
                --lnit7.city_name                       JRPARM_BILLTO_CITY,
                --lnit7.postal_code                     JRPARM_BILLTO_ZIP,
          ,      NULL jrparm_billto_geo
                ,NULL jrparm_billto_zipext
                ,NULL jrparm_billto_geocode
                ,'O' jrparm_pot
                --ABS(lta.gross_amount)                 TXPARM_GROSSAMT,
          ,      NULL txparm_frghtamt
                ,NULL txparm_discountamt
                --lta.business_party_code               TXPARM_CUSTNO,
                --lta.business_party_name               TXPARM_CUSTNAME,
                --lta.quantity                          TXPARM_NUMITEMS,
          ,      10 txparm_calctype
                ,NULL txparm_prodcode
                --decode(lta.debit_credit_ind, 2, 0, 1) TXPARM_CREDITIND,
          ,      DECODE (SIGN (NVL (adj.line_adjusted, adj.tax_adjusted))
                        ,-1, 2
                        ,1
                        ) txparm_creditind            --Added for Defect 15482
                ,0 txparm_invoicesumind
                ,adj.apply_date txparm_invoicedate
                ,adj.adjustment_number txparm_invoiceno
                ,NULL txparm_invoicelineno
                --lta.ou_code                           TXPARM_COMPANYID,
          ,      NULL txparm_locncode
                ,NULL txparm_costcenter
                ,1 txparm_reptind
                ,NULL txparm_jobno
                ,NULL txparm_volume
                ,NULL txparm_afeworkord
                ,NULL txparm_partnumber
                ,NULL txparm_miscinfo
                --da.currency_code                      TXPARM_CURRENCYCD1,
          ,      trx.invoice_currency_code txparm_currencycd1
                ,0 txparm_dropshipind
                ,NULL txparm_streasoncode
                ,'Y' txparm_audit_flag
                ,'Y' txparm_forcetrans
                --ABS(da.tax_amount)                    LOCAL_TOTAL_TAX,
          ,      NULL local_taxableamount
                ,NULL local_staterate
                ,NULL local_stateamnt_new
                ,NULL local_countyrate
                ,NULL local_countyamnt_new
                ,NULL local_cityrate
                ,NULL local_cityamnt_new
                ,NULL local_districtrate
                ,NULL local_districtamnt_new
                --l_force_country                       TXPARM_FORCECOUNTRY,
          ,      NULL txparm_forcestate
                ,NULL txparm_forcecounty
                ,NULL txparm_forcecity
                ,NULL txparm_forcedist
                ,NULL txparm_shipto_code
                ,NULL txparm_billto_code
                --lta.ship_from_location_code           TXPARM_SHIPFROM_CODE,
                --lta.lor_location_code                 TXPARM_POO_CODE,
                --lta.loa_location_code                 TXPARM_POA_CODE,
          ,      NULL txparm_custom_attributes
                ,NULL taxware_trans_id
                ,NULL record_status
                ,NULL parent_request_id
                ,NULL request_id
                ,NULL thread_id
                ,NULL txparm_gencmplcd1
                ,NULL txparm_gencmplcd2
                ,NULL txparm_gencmpltxt
                ,NULL jrparm_returncode
                ,SYSDATE creation_date
                ,fnd_profile.VALUE ('USER_ID') created_by
                ,NULL last_update_date
                ,NULL last_updated_by
                ,NULL last_update_login
                ,trx.customer_trx_id customer_trx_id   --Added for defect 4450
                ,    gcc.segment1
                  || '.'
                  || gcc.segment2
                  || '.'
                  || gcc.segment3
                  || '.'
                  || gcc.segment4
                  || '.'
                  || gcc.segment5
                  || '.'
                  || gcc.segment6
                  || '.'
                  || gcc.segment7 ACCOUNT                       --Defect 14246
            FROM ra_cust_trx_types_all ctt
                ,ra_customer_trx_all dm
                ,ar_adjustments_all adj
                ,ar_receivables_trx_all art
                ,xx_fin_translatedefinition td
                ,xx_fin_translatevalues tv
                ,ar_cash_receipts_all acr
                ,ar_receivable_applications_all ara
                ,ra_customer_trx_all trx
                ,gl_code_combinations gcc
           --TWE60TRDB.document_audit@TWE           da,
           --TWE60TRDB.line_item_audit@TWE          lta,
           --TWE60TRDB.location_type_desc@TWE       lct1,
           --TWE60TRDB.location_type_desc@TWE       lct2,
           --TWE60TRDB.location_type_desc@TWE       lct3,
           --TWE60TRDB.location_type_desc@TWE       lct4,
           --TWE60TRDB.location_type_desc@TWE       lct5,
           --TWE60TRDB.location_type_desc@TWE       lct6,
           --TWE60TRDB.location_type_desc@TWE       lct7,
           --TWE60TRDB.line_item_loc_add_audit@TWE  lnit1,
           --TWE60TRDB.line_item_loc_add_audit@TWE  lnit2,
           --TWE60TRDB.line_item_loc_add_audit@TWE  lnit3,
           --TWE60TRDB.line_item_loc_add_audit@TWE  lnit4,
           --TWE60TRDB.line_item_loc_add_audit@TWE  lnit5,
           --TWE60TRDB.line_item_loc_add_audit@TWE  lnit6,
           --TWE60TRDB.line_item_loc_add_audit@TWE  lnit7
          where  1 = 1
             AND dm.cust_trx_type_id = ctt.cust_trx_type_id
             AND dm.customer_trx_id = adj.customer_trx_id
             AND adj.receivables_trx_id = art.receivables_trx_id
             AND td.translation_name = 'OD_TAX_AR_BAD_DEBTS'
             AND td.translate_id = tv.translate_id
             AND art.NAME LIKE    tv.source_value1
                               || '%'
             AND acr.cash_receipt_id = dm.reversed_cash_receipt_id
             AND acr.cash_receipt_id = ara.cash_receipt_id
             AND ara.applied_customer_trx_id IS NOT NULL
             AND ara.status = 'APP'
             AND ara.display = 'Y'
             AND ara.applied_customer_trx_id = trx.customer_trx_id
             AND dm.org_id = fnd_profile.VALUE ('ORG_ID')
             AND adj.code_combination_id = gcc.code_combination_id
             AND adj.gl_date BETWEEN p_period_start_date AND p_period_end_date
                                                      --Added for Defect 14246
             AND adj.status = 'A'                     --Added for Defect 15482
             AND adj.TYPE IN ('INVOICE')              --Added for Defect 15482
          UNION ALL                    /*--    Start changes for Defect#3448*/
          SELECT trx1.trx_number trx_number         -- Changed for defect 3448
                ,adj.line_adjusted adjusted_amount
                                       -- Added for defect 3448 on 20-JAN-2010
                ,'A' p_flag            -- Added for defect 3448 on 20-JAN-2010
                ,acr.cash_receipt_id p_reference_id
                                       -- Added for defect 3448 on 20-JAN-2010
                --,TWE_ORA_TRX_ID_s.nextval                TWE_ORA_TRX_ID
          ,      fnd_profile.VALUE ('ORG_ID') orcl_org_id
                --lnit6.country_name                    JRPARM_SHIPFR_COUNTRY,
                --lnit6.state_name                      JRPARM_SHIPFR_STATE,
                --lnit6.county_name                     JRPARM_SHIPFR_CNTY,
                --lnit6.city_name                       JRPARM_SHIPFR_CITY,
                --lnit6.postal_code                     JRPARM_SHIPFR_ZIP,
          ,      NULL jrparm_shipfr_geo
                ,NULL jrparm_shipfr_zipext
                --lnit2.country_name                    JRPARM_SHIPTO_COUNTRY,
                --lnit2.state_name                      JRPARM_SHIPTO_STATE,
                --lnit2.county_name                     JRPARM_SHIPTO_CNTY,
                --lnit2.city_name                       JRPARM_SHIPTO_CITY,
                --lnit2.postal_code                     JRPARM_SHIPTO_ZIP,
          ,      NULL jrparm_shipto_geo
                ,NULL jrparm_shipto_zipext
                ,NULL jrparm_shipto_geocode
                --lnit1.country_name                    JRPARM_POA_COUNTRY,
                --lnit1.state_name                      JRPARM_POA_STATE,
                --lnit1.county_name                     JRPARM_POA_CNTY,
                --lnit1.city_name                       JRPARM_POA_CITY,
                --lnit1.postal_code                     JRPARM_POA_ZIP,
          ,      NULL jrparm_poa_geo
                ,NULL jrparm_poa_zipext
                --lnit7.country_name                    JRPARM_POO_COUNTRY,
                --lnit7.state_name                      JRPARM_POO_STATE,
                --lnit7.county_name                     JRPARM_POO_CNTY,
                --lnit7.city_name                       JRPARM_POO_CITY,
                --lnit7.postal_code                     JRPARM_POO_ZIP,
          ,      NULL jrparm_poo_geo
                ,NULL jrparm_poo_zipext
                --lnit5.country_name                    JRPARM_BILLTO_COUNTRY,
                --lnit7.state_name                      JRPARM_BILLTO_STATE,
                --lnit7.county_name                     JRPARM_BILLTO_CNTY,
                --lnit7.city_name                       JRPARM_BILLTO_CITY,
                --lnit7.postal_code                     JRPARM_BILLTO_ZIP,
          ,      NULL jrparm_billto_geo
                ,NULL jrparm_billto_zipext
                ,NULL jrparm_billto_geocode
                ,'O' jrparm_pot
                --ABS(lta.gross_amount)                 TXPARM_GROSSAMT,
          ,      NULL txparm_frghtamt
                ,NULL txparm_discountamt
                --lta.business_party_code               TXPARM_CUSTNO,
                --lta.business_party_name               TXPARM_CUSTNAME,
                --lta.quantity                          TXPARM_NUMITEMS,
          ,      10 txparm_calctype
                ,NULL txparm_prodcode
                --decode(lta.debit_credit_ind, 2, 0, 1) TXPARM_CREDITIND,
          ,      DECODE (SIGN (NVL (adj.line_adjusted, adj.tax_adjusted))
                        ,-1, 2
                        ,1
                        ) txparm_creditind            --Added for Defect 15482
                ,0 txparm_invoicesumind
                ,adj.apply_date txparm_invoicedate
                ,adj.adjustment_number txparm_invoiceno
                ,NULL txparm_invoicelineno
                --lta.ou_code                           TXPARM_COMPANYID,
          ,      NULL txparm_locncode
                ,NULL txparm_costcenter
                ,1 txparm_reptind
                ,NULL txparm_jobno
                ,NULL txparm_volume
                ,NULL txparm_afeworkord
                ,NULL txparm_partnumber
                ,NULL txparm_miscinfo
                --da.currency_code                      TXPARM_CURRENCYCD1,
          ,      trx1.invoice_currency_code txparm_currencycd1
                ,0 txparm_dropshipind
                ,NULL txparm_streasoncode
                ,'Y' txparm_audit_flag
                ,'Y' txparm_forcetrans
                --ABS(da.tax_amount)                    LOCAL_TOTAL_TAX,
          ,      NULL local_taxableamount
                ,NULL local_staterate
                ,NULL local_stateamnt_new
                ,NULL local_countyrate
                ,NULL local_countyamnt_new
                ,NULL local_cityrate
                ,NULL local_cityamnt_new
                ,NULL local_districtrate
                ,NULL local_districtamnt_new
                --l_force_country                       TXPARM_FORCECOUNTRY,
          ,      NULL txparm_forcestate
                ,NULL txparm_forcecounty
                ,NULL txparm_forcecity
                ,NULL txparm_forcedist
                ,NULL txparm_shipto_code
                ,NULL txparm_billto_code
                --lta.ship_from_location_code           TXPARM_SHIPFROM_CODE,
                --lta.lor_location_code                 TXPARM_POO_CODE,
                --lta.loa_location_code                 TXPARM_POA_CODE,
          ,      NULL txparm_custom_attributes
                ,NULL taxware_trans_id
                ,NULL record_status
                ,NULL parent_request_id
                ,NULL request_id
                ,NULL thread_id
                ,NULL txparm_gencmplcd1
                ,NULL txparm_gencmplcd2
                ,NULL txparm_gencmpltxt
                ,NULL jrparm_returncode
                ,SYSDATE creation_date
                ,fnd_profile.VALUE ('USER_ID') created_by
                ,NULL last_update_date
                ,NULL last_updated_by
                ,NULL last_update_login
                ,trx1.customer_trx_id customer_trx_id  --Added for defect 4450
                ,    gcc.segment1
                  || '.'
                  || gcc.segment2
                  || '.'
                  || gcc.segment3
                  || '.'
                  || gcc.segment4
                  || '.'
                  || gcc.segment5
                  || '.'
                  || gcc.segment6
                  || '.'
                  || gcc.segment7 ACCOUNT                       --Defect 14246
            FROM ra_customer_trx_all trx_dm
                ,ra_customer_trx_all trx1         --Added for defect 3448
                ,ar_cash_receipts_all acr         --Added for defect 3448
                ,ar_receivable_applications_all ara
                                                       --Added for defect 3448
                ,ar_adjustments_all adj
                ,gl_code_combinations gcc
                ,ar_receivables_trx_all art
                ,xx_fin_translatedefinition td
                ,xx_fin_translatevalues tv
                ,xx_ce_chargeback_dm xccd
                ,ra_cust_trx_types_all rctt
                                          --Added for defect 3448 on 02-FEB-10
                ,xx_ce_ajb996 xca    --Added for defect 3448 on 03-FEB-10
           --TWE60TRDB.document_audit@TWE           da,
           --TWE60TRDB.line_item_audit@TWE          lta,
           --TWE60TRDB.location_type_desc@TWE       lct1,
           --TWE60TRDB.location_type_desc@TWE       lct2,
           --TWE60TRDB.location_type_desc@TWE       lct3,
           --TWE60TRDB.location_type_desc@TWE       lct4,
           --TWE60TRDB.location_type_desc@TWE       lct5,
           --TWE60TRDB.location_type_desc@TWE       lct6,
           --TWE60TRDB.location_type_desc@TWE       lct7,
           --TWE60TRDB.line_item_loc_add_audit@TWE  lnit1,
           --TWE60TRDB.line_item_loc_add_audit@TWE  lnit2,
           --TWE60TRDB.line_item_loc_add_audit@TWE  lnit3,
           --TWE60TRDB.line_item_loc_add_audit@TWE  lnit4,
           --TWE60TRDB.line_item_loc_add_audit@TWE  lnit5,
           --TWE60TRDB.line_item_loc_add_audit@TWE  lnit6,
           --TWE60TRDB.line_item_loc_add_audit@TWE  lnit7
          where
             xccd.debit_memo_number = trx_dm.trx_number
             AND xccd.receipt_number =
                           xca.receipt_num
                                          --Added for defect 3448 on 03-FEB-10
             AND xca.trx_type = 'SALE'    --Added for defect 3448 on 03-FEB-10
             AND trx_dm.customer_trx_id = adj.customer_trx_id
             AND xccd.cash_receipt_id =
                       acr.cash_receipt_id
                                          --Added for defect 3448 on 28-Dec-09
             AND acr.cash_receipt_id =
                       ara.cash_receipt_id
                                          --Added for defect 3448 on 28-Dec-09
             AND ara.applied_customer_trx_id =
                      trx1.customer_trx_id
                                          --Added for defect 3448 on 28-Dec-09
             AND trx1.cust_trx_type_id =
                    rctt.cust_trx_type_id
                                         ---Added for defect 3448 on 02-FEB-10
             AND rctt.TYPE = 'INV'       ---Added for defect 3448 on 02-FEB-10
             AND ara.status = 'APP'                    --Added for defect 3448
             AND ara.display = 'Y'                     --Added for defect 3448
             AND adj.code_combination_id = gcc.code_combination_id
             AND adj.receivables_trx_id = art.receivables_trx_id
             AND adj.status = 'A'
             AND adj.TYPE IN ('INVOICE')
             AND adj.gl_date BETWEEN p_period_start_date AND p_period_end_date
             AND art.NAME LIKE    tv.source_value1
                               || '%'
             AND td.translate_id = tv.translate_id
             AND td.translation_name = 'OD_TAX_AR_BAD_DEBTS'
             AND trx1.org_id = fnd_profile.VALUE ('ORG_ID')
          UNION ALL
          SELECT rct.trx_number trx_number
                                        --Added for defect 3448 on 20-JAN-2010
                ,adj.line_adjusted adjusted_amount
                                        --Added for defect 3448 on 20-JAN-2010
                ,'R' p_flag             --Added for defect 3448 on 20-JAN-2010
                ,acr1.cash_receipt_id p_reference_id
                                        --Added for defect 3448 on 20-JAN-2010
                --,TWE_ORA_TRX_ID_s.nextval                TWE_ORA_TRX_ID
          ,      fnd_profile.VALUE ('ORG_ID') orcl_org_id
                --lnit6.country_name                    JRPARM_SHIPFR_COUNTRY,
                --lnit6.state_name                      JRPARM_SHIPFR_STATE,
                --lnit6.county_name                     JRPARM_SHIPFR_CNTY,
                --lnit6.city_name                       JRPARM_SHIPFR_CITY,
                --lnit6.postal_code                     JRPARM_SHIPFR_ZIP,
          ,      NULL jrparm_shipfr_geo
                ,NULL jrparm_shipfr_zipext
                --lnit2.country_name                    JRPARM_SHIPTO_COUNTRY,
                --lnit2.state_name                      JRPARM_SHIPTO_STATE,
                --lnit2.county_name                     JRPARM_SHIPTO_CNTY,
                --lnit2.city_name                       JRPARM_SHIPTO_CITY,
                --lnit2.postal_code                     JRPARM_SHIPTO_ZIP,
          ,      NULL jrparm_shipto_geo
                ,NULL jrparm_shipto_zipext
                ,NULL jrparm_shipto_geocode
                --lnit1.country_name                    JRPARM_POA_COUNTRY,
                --lnit1.state_name                      JRPARM_POA_STATE,
                --lnit1.county_name                     JRPARM_POA_CNTY,
                --lnit1.city_name                       JRPARM_POA_CITY,
                --lnit1.postal_code                     JRPARM_POA_ZIP,
          ,      NULL jrparm_poa_geo
                ,NULL jrparm_poa_zipext
                --lnit7.country_name                    JRPARM_POO_COUNTRY,
                --lnit7.state_name                      JRPARM_POO_STATE,
                --lnit7.county_name                     JRPARM_POO_CNTY,
                --lnit7.city_name                       JRPARM_POO_CITY,
                --lnit7.postal_code                     JRPARM_POO_ZIP,
          ,      NULL jrparm_poo_geo
                ,NULL jrparm_poo_zipext
                --lnit5.country_name                    JRPARM_BILLTO_COUNTRY,
                --lnit7.state_name                      JRPARM_BILLTO_STATE,
                --lnit7.county_name                     JRPARM_BILLTO_CNTY,
                --lnit7.city_name                       JRPARM_BILLTO_CITY,
                --lnit7.postal_code                     JRPARM_BILLTO_ZIP,
          ,      NULL jrparm_billto_geo
                ,NULL jrparm_billto_zipext
                ,NULL jrparm_billto_geocode
                ,'O' jrparm_pot
                --ABS(lta.gross_amount)                 TXPARM_GROSSAMT,
          ,      NULL txparm_frghtamt
                ,NULL txparm_discountamt
                --lta.business_party_code               TXPARM_CUSTNO,
                --lta.business_party_name               TXPARM_CUSTNAME,
                --lta.quantity                          TXPARM_NUMITEMS,
          ,      10 txparm_calctype
                ,NULL txparm_prodcode
                --decode(lta.debit_credit_ind, 2, 0, 1) TXPARM_CREDITIND,
          ,      DECODE (SIGN (NVL (adj.line_adjusted, adj.tax_adjusted))
                        ,-1, 2
                        ,1
                        ) txparm_creditind            --Added for Defect 15482
                ,0 txparm_invoicesumind
                ,adj.apply_date txparm_invoicedate
                ,adj.adjustment_number txparm_invoiceno
                ,NULL txparm_invoicelineno
                --lta.ou_code                           TXPARM_COMPANYID,
          ,      NULL txparm_locncode
                ,NULL txparm_costcenter
                ,1 txparm_reptind
                ,NULL txparm_jobno
                ,NULL txparm_volume
                ,NULL txparm_afeworkord
                ,NULL txparm_partnumber
                ,NULL txparm_miscinfo
                --da.currency_code                      TXPARM_CURRENCYCD1,
          ,      trx_dm.invoice_currency_code txparm_currencycd1
                ,0 txparm_dropshipind
                ,NULL txparm_streasoncode
                ,'Y' txparm_audit_flag
                ,'Y' txparm_forcetrans
                --ABS(da.tax_amount)                    LOCAL_TOTAL_TAX,
          ,      NULL local_taxableamount
                ,NULL local_staterate
                ,NULL local_stateamnt_new
                ,NULL local_countyrate
                ,NULL local_countyamnt_new
                ,NULL local_cityrate
                ,NULL local_cityamnt_new
                ,NULL local_districtrate
                ,NULL local_districtamnt_new
                --l_force_country                       TXPARM_FORCECOUNTRY,
          ,      NULL txparm_forcestate
                ,NULL txparm_forcecounty
                ,NULL txparm_forcecity
                ,NULL txparm_forcedist
                ,NULL txparm_shipto_code
                ,NULL txparm_billto_code
                --lta.ship_from_location_code           TXPARM_SHIPFROM_CODE,
                --lta.lor_location_code                 TXPARM_POO_CODE,
                --lta.loa_location_code                 TXPARM_POA_CODE,
          ,      NULL txparm_custom_attributes
                ,NULL taxware_trans_id
                ,NULL record_status
                ,NULL parent_request_id
                ,NULL request_id
                ,NULL thread_id
                ,NULL txparm_gencmplcd1
                ,NULL txparm_gencmplcd2
                ,NULL txparm_gencmpltxt
                ,NULL jrparm_returncode
                ,SYSDATE creation_date
                ,fnd_profile.VALUE ('USER_ID') created_by
                ,NULL last_update_date
                ,NULL last_updated_by
                ,NULL last_update_login
                ,rct.customer_trx_id customer_trx_id   --Added for defect 4450
                ,    gcc.segment1
                  || '.'
                  || gcc.segment2
                  || '.'
                  || gcc.segment3
                  || '.'
                  || gcc.segment4
                  || '.'
                  || gcc.segment5
                  || '.'
                  || gcc.segment6
                  || '.'
                  || gcc.segment7 ACCOUNT
            FROM ra_customer_trx_all trx_dm
                ,ar_adjustments_all adj
                ,ar_cash_receipts_all acr
                ,xx_ce_chargeback_dm xccd
                ,ar_receivables_trx_all art
                ,xx_fin_translatedefinition td
                ,xx_fin_translatevalues tv
                ,gl_code_combinations gcc
                ,ar_cash_receipts_all acr1
                ,ar_receivable_applications_all ara
                ,ra_customer_trx_all rct
                ,ra_cust_trx_types_all rctt
           where
             xccd.debit_memo_number = trx_dm.trx_number
             AND trx_dm.customer_trx_id = adj.customer_trx_id
             AND xccd.cash_receipt_id = acr.cash_receipt_id
             AND acr.TYPE = 'MISC'
             AND acr.reference_type = 'RECEIPT'
             AND adj.receivables_trx_id = art.receivables_trx_id
             AND td.translation_name = 'OD_TAX_AR_BAD_DEBTS'
             AND td.translate_id = tv.translate_id
             AND art.NAME LIKE    tv.source_value1
                               || '%'
             AND adj.code_combination_id = gcc.code_combination_id
             AND adj.gl_date BETWEEN p_period_start_date AND p_period_end_date
             AND adj.status = 'A'
             AND adj.TYPE IN ('INVOICE')
             AND acr1.cash_receipt_id = acr.reference_id
             AND acr1.cash_receipt_id = ara.cash_receipt_id
             AND ara.status = 'APP'
             AND ara.display = 'Y'
             AND ara.applied_customer_trx_id = rct.customer_trx_id
             AND rct.cust_trx_type_id = rctt.cust_trx_type_id
             AND rctt.TYPE = 'INV'
             AND rct.org_id =
                    fnd_profile.VALUE
                            ('ORG_ID')
                                     --); --End of changes for the Defect#3448
          UNION ALL
---- select statement below for SDR project.  Retrieve POS transactions from OM tables - Sinon
          SELECT /*+ INDEX(ADJ, AR_ADJUSTMENTS_N2) */
                 TO_CHAR (om.order_number, '000000000000') trx_number
                ,adj.line_adjusted adjusted_amount
                ,'A' p_flag
                ,NULL p_reference_id
                ,fnd_profile.VALUE ('ORG_ID') orcl_org_id
                ,NULL jrparm_shipfr_geo
                ,NULL jrparm_shipfr_zipext
                ,NULL jrparm_shipto_geo
                ,NULL jrparm_shipto_zipext
                ,NULL jrparm_shipto_geocode
                ,NULL jrparm_poa_geo
                ,NULL jrparm_poa_zipext
                ,NULL jrparm_poo_geo
                ,NULL jrparm_poo_zipext
                ,NULL jrparm_billto_geo
                ,NULL jrparm_billto_zipext
                ,NULL jrparm_billto_geocode
                ,'O' jrparm_pot
                ,NULL txparm_frghtamt
                ,NULL txparm_discountamt
                ,10 txparm_calctype
                ,NULL txparm_prodcode
                ,DECODE (SIGN (NVL (adj.line_adjusted, adj.tax_adjusted))
                        ,-1, 2
                        ,1
                        ) txparm_creditind
                ,0 txparm_invoicesumind
                ,adj.apply_date txparm_invoicedate
                ,adj.adjustment_number txparm_invoiceno
                ,NULL txparm_invoicelineno
                ,NULL txparm_locncode
                ,NULL txparm_costcenter
                ,1 txparm_reptind
                ,NULL txparm_jobno
                ,NULL txparm_volume
                ,NULL txparm_afeworkord
                ,NULL txparm_partnumber
                ,NULL txparm_miscinfo
                ,om.transactional_curr_code txparm_currencycd1
                ,0 txparm_dropshipind
                ,NULL txparm_streasoncode
                ,'Y' txparm_audit_flag
                ,'Y' txparm_forcetrans
                ,NULL local_taxableamount
                ,NULL local_staterate
                ,NULL local_stateamnt_new
                ,NULL local_countyrate
                ,NULL local_countyamnt_new
                ,NULL local_cityrate
                ,NULL local_cityamnt_new
                ,NULL local_districtrate
                ,NULL local_districtamnt_new
                ,NULL txparm_forcestate
                ,NULL txparm_forcecounty
                ,NULL txparm_forcecity
                ,NULL txparm_forcedist
                ,NULL txparm_shipto_code
                ,NULL txparm_billto_code
                ,NULL txparm_custom_attributes
                ,NULL taxware_trans_id
                ,NULL record_status
                ,NULL parent_request_id
                ,NULL request_id
                ,NULL thread_id
                ,NULL txparm_gencmplcd1
                ,NULL txparm_gencmplcd2
                ,NULL txparm_gencmpltxt
                ,NULL jrparm_returncode
                ,SYSDATE creation_date
                ,fnd_profile.VALUE ('USER_ID') created_by
                ,NULL last_update_date
                ,NULL last_updated_by
                ,NULL last_update_login
                ,om.header_id customer_trx_id
                ,    gcc.segment1
                  || '.'
                  || gcc.segment2
                  || '.'
                  || gcc.segment3
                  || '.'
                  || gcc.segment4
                  || '.'
                  || gcc.segment5
                  || '.'
                  || gcc.segment6
                  || '.'
                  || gcc.segment7 ACCOUNT                       --Defect 14246
            FROM ra_customer_trx_all trx_dm
                ,xx_oe_order_headers_v om
                ,ar_adjustments_all adj
                ,gl_code_combinations gcc
                ,ar_receivables_trx_all art
                ,xx_fin_translatedefinition td
                ,xx_fin_translatevalues tv
                ,xx_ce_chargeback_dm xccd
                ,ra_cust_trx_types_all rctt
                                          --Added for defect 3448 on 02-FEB-10
                ,xx_ce_ajb996 xca    --Added for defect 3448 on 03-FEB-10
                ,xx_ar_pos_receipts pos    -- POS SUMMARY FOR SDR project
           where xccd.debit_memo_number = trx_dm.trx_number
             AND xccd.sequence_id_996 = xca.sequence_id_996
             AND xca.trx_type = 'SALE'    --Added for defect 3448 on 03-FEB-10
             AND trx_dm.customer_trx_id = adj.customer_trx_id
             AND om.orig_sys_document_ref =
                       LPAD (TRIM (SUBSTR (xccd.invoice_num
                                          ,1
                                          ,20
                                          ))
                            ,20
                            ,'0'
                            )
             AND trx_dm.cust_trx_type_id = rctt.cust_trx_type_id
             AND rctt.TYPE = 'DM'        ---Added for defect 3448 on 02-FEB-10
             AND adj.code_combination_id = gcc.code_combination_id
             AND adj.receivables_trx_id = art.receivables_trx_id
             AND adj.status = 'A'
             AND adj.TYPE IN ('INVOICE')
             AND adj.gl_date BETWEEN p_period_start_date AND p_period_end_date
             AND art.NAME LIKE    tv.source_value1
                               || '%'
             AND td.translate_id = tv.translate_id
             AND td.translation_name = 'OD_TAX_AR_BAD_DEBTS'
             AND trx_dm.org_id = fnd_profile.VALUE ('ORG_ID')
             AND xccd.cash_receipt_id = pos.cash_receipt_id
          UNION ALL
---- select statement below for SDR project.  Retrieve POS transactions from OM tables - Sinon
          SELECT /*+ INDEX(ADJ, AR_ADJUSTMENTS_N2) */
                 TO_CHAR (om.order_number, '000000000000') trx_number
                ,adj.line_adjusted adjusted_amount
                ,'A' p_flag
                ,NULL p_reference_id
                ,fnd_profile.VALUE ('ORG_ID') orcl_org_id
                ,NULL jrparm_shipfr_geo
                ,NULL jrparm_shipfr_zipext
                ,NULL jrparm_shipto_geo
                ,NULL jrparm_shipto_zipext
                ,NULL jrparm_shipto_geocode
                ,NULL jrparm_poa_geo
                ,NULL jrparm_poa_zipext
                ,NULL jrparm_poo_geo
                ,NULL jrparm_poo_zipext
                ,NULL jrparm_billto_geo
                ,NULL jrparm_billto_zipext
                ,NULL jrparm_billto_geocode
                ,'O' jrparm_pot
                ,NULL txparm_frghtamt
                ,NULL txparm_discountamt
                ,10 txparm_calctype
                ,NULL txparm_prodcode
                ,DECODE (SIGN (NVL (adj.line_adjusted, adj.tax_adjusted))
                        ,-1, 2
                        ,1
                        ) txparm_creditind
                ,0 txparm_invoicesumind
                ,adj.apply_date txparm_invoicedate
                ,adj.adjustment_number txparm_invoiceno
                ,NULL txparm_invoicelineno
                ,NULL txparm_locncode
                ,NULL txparm_costcenter
                ,1 txparm_reptind
                ,NULL txparm_jobno
                ,NULL txparm_volume
                ,NULL txparm_afeworkord
                ,NULL txparm_partnumber
                ,NULL txparm_miscinfo
                ,om.transactional_curr_code txparm_currencycd1
                ,0 txparm_dropshipind
                ,NULL txparm_streasoncode
                ,'Y' txparm_audit_flag
                ,'Y' txparm_forcetrans
                ,NULL local_taxableamount
                ,NULL local_staterate
                ,NULL local_stateamnt_new
                ,NULL local_countyrate
                ,NULL local_countyamnt_new
                ,NULL local_cityrate
                ,NULL local_cityamnt_new
                ,NULL local_districtrate
                ,NULL local_districtamnt_new
                ,NULL txparm_forcestate
                ,NULL txparm_forcecounty
                ,NULL txparm_forcecity
                ,NULL txparm_forcedist
                ,NULL txparm_shipto_code
                ,NULL txparm_billto_code
                ,NULL txparm_custom_attributes
                ,NULL taxware_trans_id
                ,NULL record_status
                ,NULL parent_request_id
                ,NULL request_id
                ,NULL thread_id
                ,NULL txparm_gencmplcd1
                ,NULL txparm_gencmplcd2
                ,NULL txparm_gencmpltxt
                ,NULL jrparm_returncode
                ,SYSDATE creation_date
                ,fnd_profile.VALUE ('USER_ID') created_by
                ,NULL last_update_date
                ,NULL last_updated_by
                ,NULL last_update_login
                ,om.header_id customer_trx_id
                ,    gcc.segment1
                  || '.'
                  || gcc.segment2
                  || '.'
                  || gcc.segment3
                  || '.'
                  || gcc.segment4
                  || '.'
                  || gcc.segment5
                  || '.'
                  || gcc.segment6
                  || '.'
                  || gcc.segment7 ACCOUNT                       --Defect 14246
            FROM ra_customer_trx_all trx_dm
                ,xx_oe_order_headers_v om
                ,ar_adjustments_all adj
                ,gl_code_combinations gcc
                ,ar_receivables_trx_all art
                ,xx_fin_translatedefinition td
                ,xx_fin_translatevalues tv
                ,xx_ce_chargeback_dm xccd
                ,ra_cust_trx_types_all rctt
                                          --Added for defect 3448 on 02-FEB-10
                ,xx_ce_ajb996 xca    --Added for defect 3448 on 03-FEB-10
           WHERE  xccd.debit_memo_number = trx_dm.trx_number
             AND xccd.sequence_id_996 = xca.sequence_id_996
             AND xca.trx_type = 'SALE'    --Added for defect 3448 on 03-FEB-10
             AND trx_dm.customer_trx_id = adj.customer_trx_id
             AND om.orig_sys_document_ref =
                       LPAD (TRIM (SUBSTR (xccd.invoice_num
                                          ,1
                                          ,20
                                          ))
                            ,20
                            ,'0'
                            )
             AND trx_dm.cust_trx_type_id = rctt.cust_trx_type_id
             AND rctt.TYPE = 'DM'        ---Added for defect 3448 on 02-FEB-10
             AND adj.code_combination_id = gcc.code_combination_id
             AND adj.receivables_trx_id = art.receivables_trx_id
             AND adj.status = 'A'
             AND adj.TYPE IN ('INVOICE')
             AND adj.gl_date BETWEEN p_period_start_date AND p_period_end_date
             AND art.NAME LIKE    tv.source_value1
                               || '%'
             AND td.translate_id = tv.translate_id
             AND td.translation_name = 'OD_TAX_AR_BAD_DEBTS'
             AND trx_dm.org_id = fnd_profile.VALUE ('ORG_ID')
             AND xccd.cash_receipt_id IS NULL);
                                          --End of changes for the Defect#3448
   ---- select statement above for SDR project. Retrieve POS transactions from OM tables - Sinon
   /*AND  UPPER (CTT.name) IN (UPPER(p_od_chargeback_type1)
   ,UPPER(p_od_chargeback_type2)
   ,UPPER(p_od_chargeback_type3)
   ,UPPER(p_od_chargeback_type4)
   ,UPPER(p_od_chargeback_type5)
   ,UPPER(p_od_chargeback_type6)
   ,UPPER(p_od_chargeback_type7)
   ,UPPER(p_od_chargeback_type8)
   ,UPPER(p_od_chargeback_type9)
   ,UPPER(p_od_chargeback_type10));*/
   --AND da.transaction_doc_number = TRX.TRX_NUMBER
   --AND da.document_audit_id=lta.document_audit_id
   --AND lta.line_item_audit_id=lnit1.line_item_audit_id
   --AND lta.line_item_audit_id=lnit2.line_item_audit_id
   --AND lta.line_item_audit_id=lnit3.line_item_audit_id
   --AND lta.line_item_audit_id=lnit4.line_item_audit_id
   --AND lta.line_item_audit_id=lnit5.line_item_audit_id
   --AND lta.line_item_audit_id=lnit6.line_item_audit_id
   --AND lta.line_item_audit_id=lnit7.line_item_audit_id
   --AND lct1.location_type_id=lnit1.location_type_id
   --AND lct2.location_type_id=lnit2.location_type_id
   --AND lct3.location_type_id=lnit3.location_type_id
   --AND lct4.location_type_id=lnit4.location_type_id
   --AND lct5.location_type_id=lnit5.location_type_id
   --AND lct6.location_type_id=lnit6.location_type_id
   --AND lct7.location_type_id=lnit7.location_type_id
   --AND lct1.location_type_name='Location of Order of Approval'
   --AND lct2.location_type_name='Ship To'
   --AND lct3.location_type_name='Location of Service Performance'
   --AND lct4.location_type_name='Location of Use'
   --AND lct5.location_type_name='Bill To'
   --AND lct6.location_type_name='Ship From'
   --AND lct7.location_type_name='Location of Order of Recording'
   BEGIN
      -- Start of changes for Defect 6018
      /*
      FND_FILE.PUT_LINE(FND_FILE.LOG,'ORG ID: '||FND_PROFILE.VALUE('ORG_ID'));
      FND_FILE.PUT_LINE(FND_FILE.LOG, '**************************Parameters**************************');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                               ');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Period Start Date: '||lp_period_start_date);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Period End Date  : '||lp_period_end_date);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Chargeback Type1 : '||lp_chargeback_type1);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Chargeback Type2 : '||lp_chargeback_type2);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Chargeback Type3 : '||lp_chargeback_type3);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Chargeback Type4 : '||lp_chargeback_type4);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Chargeback Type5 : '||lp_chargeback_type5);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Chargeback Type6 : '||lp_chargeback_type6);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Chargeback Type7 : '||lp_chargeback_type7);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Chargeback Type8 : '||lp_chargeback_type8);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Chargeback Type8 : '||lp_chargeback_type9);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Chargeback Type10: '||lp_chargeback_type10);*/
      -- End of changes for Defect 6018
      fnd_file.put_line (fnd_file.LOG, ' ');
      fnd_file.put_line (fnd_file.LOG
                        ,'------------------------------------- ');
      fnd_file.put_line (fnd_file.LOG, 'Bad Debt Credit Card Transactions');
      fnd_file.put_line (fnd_file.LOG
                        ,'------------------------------------- ');
      fnd_file.put_line (fnd_file.LOG, ' ');
      --Added two columns for defect 3448 on 27-JAN-10
      --Removed the column PRO-RATED ADJUSTMENT NUMBER and Rename the label PRO-RATED GROSS AMOUNT to GROSS ADJ AMOUNT for defect 3448 on 05-FEB-10
      fnd_file.put_line
         (fnd_file.LOG
         ,'BAD DEBT TYPE|INVOICE NO|ADJUSTMENT NUMBER|ORIGINAL INVOICE AMOUNT|ORIGINAL TAX AMOUNT|GROSS ADJ AMOUNT|PRO-RATED TAX AMOUNT|APPLY DATE|ACCOUNT|COMPANY ID|SHIP FROM CODE|SHIP FROM COUNTRY|SHIP FROM STATE|SHIP FROM COUNTY|SHIP FROM CITY|SHIP FROM ZIP|SHIP TO COUNTRY|SHIP TO STATE|SHIP TO COUNTY|SHIP TO CITY|SHIP TO ZIP|POA COUNTRY|POA STATE|POA COUNTY|POA CITY|POA ZIP|');
      fnd_file.put_line (fnd_file.LOG, ' ');

      FOR lcu_bad_debt_credit IN c_bad_debt_credit (lp_period_start_date
                                                   ,lp_period_end_date
                                                   ,lp_chargeback_type1
                                                   ,lp_chargeback_type2
                                                   ,lp_chargeback_type3
                                                   ,lp_chargeback_type4
                                                   ,lp_chargeback_type5
                                                   ,lp_chargeback_type6
                                                   ,lp_chargeback_type7
                                                   ,lp_chargeback_type8
                                                   ,lp_chargeback_type9
                                                   ,lp_chargeback_type10
                                                   )
      LOOP
         /********** To Check if the Adjustment has been processed already ********/
         /*SELECT COUNT(*) INTO l_da_count
         FROM TWE60TRDB.document_audit@TWE           da                            -- This has been commented because we are not using
         WHERE transaction_doc_number=lcu_bad_debt_credit.TXPARM_INVOICENO; */
         -- any reference to taxware tables.


         SELECT COUNT (1)
           INTO l_batch_count
           FROM xx_ar_twe_audit_trans_all twe
          --WHERE  txparm_invoiceno=lcu_bad_debt_credit.TRX_NUMBER;      -- Commented the condition for defect 4450
         WHERE  txparm_invoiceno =
                   lcu_bad_debt_credit.txparm_invoiceno
                                                       --Added for defect 4450
            AND customer_trx_id = lcu_bad_debt_credit.customer_trx_id;
                                                       --Added for defect 4450

         SELECT COUNT (1)
           INTO l_batch_hist_count
           FROM xx_ar_twe_audit_trans_all_hist twe
          --WHERE  txparm_invoiceno=lcu_bad_debt_credit.TRX_NUMBER;      -- Commented the condition for defect 4450
         WHERE  txparm_invoiceno =
                   lcu_bad_debt_credit.txparm_invoiceno
                                                       --Added for defect 4450
            AND customer_trx_id = lcu_bad_debt_credit.customer_trx_id;
                                                       --Added for defect 4450


         SELECT twe_ora_trx_id_s.NEXTVAL twe_ora_trx_id
                                                       --Added for Defect#3448
           INTO l_twe_ora_trx_id
           FROM DUAL;

         IF     l_batch_count = 0
            AND l_batch_hist_count = 0
         THEN                      -- Commented the if condition l_da_count =0
            lc_error_flag              := NULL;
            lc_error_loc               := NULL;
                                        --Added for Defect #6018 on 17-JUN-10
            --l_trx_number       := lcu_bad_debt_credit.TRX_NUMBER;
            --fnd_file.put_line(FND_FILE.LOG, l_trx_number);
            --fnd_file.put_line(FND_FILE.LOG,'Before Inserting');
            --l_forcecountry     := get_string(l_trx_number);
            --FETCHING VALUES FOR SHIPTO,SHIPFROM,POO,POA,BILLTO,COMPANY CODE
            lc_error_loc               :=
                  lc_error_loc
               || ' Calling the BAD_DEBT_VALUES procedure from BAD_DEBT_CREDITCARD';
                                                       --Added for defect 6018

            IF lcu_bad_debt_credit.p_reference_id IS NOT NULL
            THEN
   ---- FOR SDR changes. Perform procedure if cash receipt ID not null - Sinon
               bad_debt_values
                  (lcu_bad_debt_credit.trx_number
                  ,lcu_bad_debt_credit.customer_trx_id
                                                      --Added for defect 17226
                  ,NULL                  --Added  for defect 3674 on 08-FEB-10
                  ,lcu_bad_debt_credit.adjusted_amount
                  ,lcu_bad_debt_credit.p_flag
                  ,lcu_bad_debt_credit.p_reference_id
                                         --Added  for defect 3448 on 27-JAN-10
                  ,lc_error_flag
                  );                                   --Added for defect 6018
            ---sinonremove,lc_adj_amt_flag);                     --SDR project sinon
            ELSE
-- For SDR changes. Perform Procedure below if cash receipt ID is null - Sinon
               bad_debt_values_om (lcu_bad_debt_credit.trx_number
                                  ,NULL
                                  ,lcu_bad_debt_credit.adjusted_amount
                                  ,lcu_bad_debt_credit.p_flag
                                  ,lcu_bad_debt_credit.p_reference_id
                                  ,lc_error_flag
                                  );
            ---sinonremove,lc_adj_amt_flag);                     --SDR project sinon
            END IF;
-- For SDR changes. Perform Procedure above if cash receipt ID is null - Sinon

            IF lc_error_flag <> 'Y'
            THEN                                      -- Added for defect 6018
               ---sinonremoveIF lc_adj_amt_flag <> 'Y' THEN                        -- SDR project sinon - adj amt <= original amt
               IF (ABS (  g_gross_amt
                        + g_tax_amt) >=
                         ABS (  g_prorated_gross_amount
                              + g_prorated_tax_amount)
                  )
               THEN             -- SDR project sinon - adj amt <= original amt
                                 INSERT INTO xx_ar_twe_audit_trans_all
                              (twe_ora_trx_id
                              ,orcl_org_id
                              ,jrparm_shipfr_country
                              ,jrparm_shipfr_state
                              ,jrparm_shipfr_cnty
                              ,jrparm_shipfr_city
                              ,jrparm_shipfr_zip
                              ,jrparm_shipfr_geo
                              ,jrparm_shipfr_zipext
                              ,jrparm_shipto_country
                              ,jrparm_shipto_state
                              ,jrparm_shipto_cnty
                              ,jrparm_shipto_city
                              ,jrparm_shipto_zip
                              ,jrparm_shipto_geo
                              ,jrparm_shipto_zipext
                              ,jrparm_shipto_geocode
                              ,jrparm_poa_country
                              ,jrparm_poa_state
                              ,jrparm_poa_cnty
                              ,jrparm_poa_city
                              ,jrparm_poa_zip
                              ,jrparm_poa_geo
                              ,jrparm_poa_zipext
                              ,jrparm_poo_country
                              ,jrparm_poo_state
                              ,jrparm_poo_cnty
                              ,jrparm_poo_city
                              ,jrparm_poo_zip
                              ,jrparm_poo_geo
                              ,jrparm_poo_zipext
                              ,jrparm_billto_country
                              ,jrparm_billto_state
                              ,jrparm_billto_cnty
                              ,jrparm_billto_city
                              ,jrparm_billto_zip
                              ,jrparm_billto_geo
                              ,jrparm_billto_zipext
                              ,jrparm_billto_geocode
                              ,jrparm_pot
                              ,txparm_grossamt
                              ,txparm_frghtamt
                              ,txparm_discountamt
                              ,txparm_custno
                              ,txparm_custname
                              ,txparm_numitems
                              ,txparm_calctype
                              ,txparm_prodcode
                              ,txparm_creditind
                              ,txparm_invoicesumind
                              ,txparm_invoicedate
                              ,txparm_invoiceno
                              ,txparm_invoicelineno
                              ,txparm_companyid
                              ,txparm_locncode
                              ,txparm_costcenter
                              ,txparm_reptind
                              ,txparm_jobno
                              ,txparm_volume
                              ,txparm_afeworkord
                              ,txparm_partnumber
                              ,txparm_miscinfo
                              ,txparm_currencycd1
                              ,txparm_dropshipind
                              ,txparm_streasoncode
                              ,txparm_audit_flag
                              ,txparm_forcetrans
                              ,local_total_tax
                              ,local_taxableamount
                              ,local_staterate
                              ,local_stateamnt_new
                              ,local_countyrate
                              ,local_countyamnt_new
                              ,local_cityrate
                              ,local_cityamnt_new
                              ,local_districtrate
                              ,local_districtamnt_new
                              --TXPARM_FORCECOUNTRY,
                  ,            txparm_forcestate
                              ,txparm_forcecounty
                              ,txparm_forcecity
                              ,txparm_forcedist
                              ,txparm_shipto_code
                              ,txparm_billto_code
                              ,txparm_shipfrom_code
                              ,txparm_poo_code
                              ,txparm_poa_code
                              ,txparm_custom_attributes
                              ,taxware_trans_id
                              ,record_status
                              ,parent_request_id
                              ,request_id
                              ,thread_id
                              ,txparm_gencmplcd1
                              ,txparm_gencmplcd2
                              ,txparm_gencmpltxt
                              ,jrparm_returncode
                              ,creation_date
                              ,created_by
                              ,last_update_date
                              ,last_updated_by
                              ,last_update_login
                              ,customer_trx_id
         --Added the column in xx_ar_twe_audit_trans_all table for defect 4450
                              )
                       VALUES (l_twe_ora_trx_id
                                              --         Added for Defect#3448
                              --lcu_bad_debt_credit.TWE_ORA_TRX_ID
                  ,            lcu_bad_debt_credit.orcl_org_id
                              --lcu_bad_debt_credit.JRPARM_SHIPFR_COUNTRY,
                              --lcu_bad_debt_credit.JRPARM_SHIPFR_STATE,
                              --lcu_bad_debt_credit.JRPARM_SHIPFR_CNTY,
                              --lcu_bad_debt_credit.JRPARM_SHIPFR_CITY,
                              --lcu_bad_debt_credit.JRPARM_SHIPFR_ZIP,
                  ,            g_shipfr_country
                              ,g_shipfr_state
                              ,g_shipfr_cnty
                              ,g_shipfr_city
                              ,g_shipfr_zip
                              ,lcu_bad_debt_credit.jrparm_shipfr_geo
                              ,lcu_bad_debt_credit.jrparm_shipfr_zipext
                              --lcu_bad_debt_credit.JRPARM_SHIPTO_COUNTRY,
                              --lcu_bad_debt_credit.JRPARM_SHIPTO_STATE,
                              --lcu_bad_debt_credit.JRPARM_SHIPTO_CNTY,
                              --lcu_bad_debt_credit.JRPARM_SHIPTO_CITY,
                              --lcu_bad_debt_credit.JRPARM_SHIPTO_ZIP,
                  ,            g_shipto_country
                              ,g_shipto_state
                              ,g_shipto_cnty
                              ,g_shipto_city
                              ,g_shipto_zip
                              ,lcu_bad_debt_credit.jrparm_shipto_geo
                              ,lcu_bad_debt_credit.jrparm_shipto_zipext
                              ,lcu_bad_debt_credit.jrparm_shipto_geocode
                              --lcu_bad_debt_credit.JRPARM_POA_COUNTRY,
                              --lcu_bad_debt_credit.JRPARM_POA_STATE,
                              --lcu_bad_debt_credit.JRPARM_POA_CNTY,
                              --lcu_bad_debt_credit.JRPARM_POA_CITY,
                              --lcu_bad_debt_credit.JRPARM_POA_ZIP,
                  ,            g_poa_country
                              ,g_poa_state
                              ,g_poa_cnty
                              ,g_poa_city
                              ,g_poa_zip
                              ,lcu_bad_debt_credit.jrparm_poa_geo
                              ,lcu_bad_debt_credit.jrparm_poa_zipext
                              --lcu_bad_debt_credit.JRPARM_POO_COUNTRY,
                              --lcu_bad_debt_credit.JRPARM_POO_STATE,
                              --lcu_bad_debt_credit.JRPARM_POO_CNTY,
                              --lcu_bad_debt_credit.JRPARM_POO_CITY,
                              --lcu_bad_debt_credit.JRPARM_POO_ZIP,
                  ,            g_poo_country
                              ,g_poo_state
                              ,g_poo_cnty
                              ,g_poo_city
                              ,g_poo_zip
                              ,lcu_bad_debt_credit.jrparm_poo_geo
                              ,lcu_bad_debt_credit.jrparm_poo_zipext
                              --lcu_bad_debt_credit.JRPARM_BILLTO_COUNTRY,
                              --lcu_bad_debt_credit.JRPARM_BILLTO_STATE,
                              --lcu_bad_debt_credit.JRPARM_BILLTO_CNTY,
                              --lcu_bad_debt_credit.JRPARM_BILLTO_CITY,
                              --lcu_bad_debt_credit.JRPARM_BILLTO_ZIP,
                  ,            g_billto_country
                              ,g_billto_state
                              ,g_billto_cnty
                              ,g_billto_city
                              ,g_billto_zip
                              ,lcu_bad_debt_credit.jrparm_billto_geo
                              ,lcu_bad_debt_credit.jrparm_billto_zipext
                              ,lcu_bad_debt_credit.jrparm_billto_geocode
                              ,lcu_bad_debt_credit.jrparm_pot
                              --,NVL(g_gross_amt,0)--Commented for defect 4450
                  ,            NVL
                                  (g_prorated_gross_amount, 0)
                                                       --Added for defect 4450
                              ,lcu_bad_debt_credit.txparm_frghtamt
                              ,lcu_bad_debt_credit.txparm_discountamt
                              --lcu_bad_debt_credit.TXPARM_CUSTNO,
                  ,            g_customer_number
                              --lcu_bad_debt_credit.TXPARM_CUSTNAME,
                  ,            g_cust_name
                              --lcu_bad_debt_credit.TXPARM_NUMITEMS,
                  ,            g_quantity
--Commented this as the value should be got from the cursor per 3448 - 29-DEC-09 --Reverted - 31-DEC-09
                              ,lcu_bad_debt_credit.txparm_calctype
                              ,lcu_bad_debt_credit.txparm_prodcode
                              ,lcu_bad_debt_credit.txparm_creditind
                              ,lcu_bad_debt_credit.txparm_invoicesumind
                              ,lcu_bad_debt_credit.txparm_invoicedate
                              ,lcu_bad_debt_credit.txparm_invoiceno
                              ,lcu_bad_debt_credit.txparm_invoicelineno
                              --lcu_bad_debt_credit.TXPARM_COMPANYID,
                  ,            g_company
                              ,lcu_bad_debt_credit.txparm_locncode
                              ,lcu_bad_debt_credit.txparm_costcenter
                              ,lcu_bad_debt_credit.txparm_reptind
                              ,lcu_bad_debt_credit.txparm_jobno
                              ,lcu_bad_debt_credit.txparm_volume
                              ,lcu_bad_debt_credit.txparm_afeworkord
                              ,lcu_bad_debt_credit.txparm_partnumber
                              ,lcu_bad_debt_credit.txparm_miscinfo
                              ,lcu_bad_debt_credit.txparm_currencycd1
                              ,lcu_bad_debt_credit.txparm_dropshipind
                              ,lcu_bad_debt_credit.txparm_streasoncode
                              ,lcu_bad_debt_credit.txparm_audit_flag
                              ,lcu_bad_debt_credit.txparm_forcetrans
                              --,NVL(g_tax_amt,0)                          -- Updated for defect #3207 --Commented for defect 4450
                  ,            NVL
                                  (g_prorated_tax_amount, 0)
                                                       --Added for defect 4450
                              ,lcu_bad_debt_credit.local_taxableamount
                              ,lcu_bad_debt_credit.local_staterate
                              ,lcu_bad_debt_credit.local_stateamnt_new
                              ,lcu_bad_debt_credit.local_countyrate
                              ,lcu_bad_debt_credit.local_countyamnt_new
                              ,lcu_bad_debt_credit.local_cityrate
                              ,lcu_bad_debt_credit.local_cityamnt_new
                              ,lcu_bad_debt_credit.local_districtrate
                              ,lcu_bad_debt_credit.local_districtamnt_new
                              --l_forcecountry,
                  ,            lcu_bad_debt_credit.txparm_forcestate
                              ,lcu_bad_debt_credit.txparm_forcecounty
                              ,lcu_bad_debt_credit.txparm_forcecity
                              ,lcu_bad_debt_credit.txparm_forcedist
                              ,lcu_bad_debt_credit.txparm_shipto_code
                              ,lcu_bad_debt_credit.txparm_billto_code
                              --lcu_bad_debt_credit.TXPARM_SHIPFROM_CODE,
                  ,            g_shipfr_code
                              --lcu_bad_debt_credit.TXPARM_POO_CODE,
                  ,            g_poo_code
                              --lcu_bad_debt_credit.TXPARM_POA_CODE,
                  ,            g_poa_code
                              ,lcu_bad_debt_credit.txparm_custom_attributes
                              ,lcu_bad_debt_credit.taxware_trans_id
                              ,lcu_bad_debt_credit.record_status
                              ,lcu_bad_debt_credit.parent_request_id
                              ,lcu_bad_debt_credit.request_id
                              ,lcu_bad_debt_credit.thread_id
                              ,lcu_bad_debt_credit.txparm_gencmplcd1
                              ,lcu_bad_debt_credit.txparm_gencmplcd2
                              ,lcu_bad_debt_credit.txparm_gencmpltxt
                              ,lcu_bad_debt_credit.jrparm_returncode
                              ,lcu_bad_debt_credit.creation_date
                              ,lcu_bad_debt_credit.created_by
                              ,lcu_bad_debt_credit.last_update_date
                              ,lcu_bad_debt_credit.last_updated_by
                              ,lcu_bad_debt_credit.last_update_login
                              ,lcu_bad_debt_credit.customer_trx_id
                                                       --Added for defect 4450
                              );

                  lc_error_loc               :=
                                             lc_error_loc
                                          || ' Insert Successful';
                  fnd_file.put_line
                     (fnd_file.output
                     ,    ' '
                       || '|'
                       || lcu_bad_debt_credit.trx_number
                       || '|'
                       || lcu_bad_debt_credit.txparm_invoiceno
                       || '|'
                       || g_gross_amt
                       || '|'
                       || g_tax_amt
                       || '|'
                       || g_prorated_gross_amount
                                          --Added for defect 3448 on 27-JAN-10
                       --||'|'||g_prorated_adjustment_amount--Added for defect 3448 on 27-JAN-10--Commented  for defect 3448 on 05-FEB-10
                       || '|'
                       || g_prorated_tax_amount
                                          --Added for defect 3448 on 27-JAN-10
                       || '|'
                       || lcu_bad_debt_credit.txparm_invoicedate
                       || '|'
                       || lcu_bad_debt_credit.ACCOUNT
                       || '|'
                       || g_company
                       || '|'
                       || g_shipfr_code
                       || '|'
                       || g_shipfr_country
                       || '|'
                       || g_shipfr_state
                       || '|'
                       || g_shipfr_cnty
                       || '|'
                       || g_shipfr_city
                       || '|'
                       || g_shipfr_zip
                       || '|'
                       || g_shipto_country
                       || '|'
                       || g_shipto_state
                       || '|'
                       || g_shipto_cnty
                       || '|'
                       || g_shipto_city
                       || '|'
                       || g_shipto_zip
                       || '|'
                       || g_poa_country
                       || '|'
                       || g_poa_state
                       || '|'
                       || g_poa_cnty
                       || '|'
                       || g_poa_city
                       || '|'
                       || g_poa_zip
                       || '|');
                  fnd_file.put_line
                     (fnd_file.LOG
                     ,    ' '
                       || '|'
                       || lcu_bad_debt_credit.trx_number
                       || '|'
                       || lcu_bad_debt_credit.txparm_invoiceno
                       || '|'
                       || g_gross_amt
                       || '|'
                       || g_tax_amt
                       || '|'
                       || g_prorated_gross_amount
                                          --Added for defect 3448 on 27-JAN-10
                       --||'|'||g_prorated_adjustment_amount--Added for defect 3448 on 27-JAN-10--Commented  for defect 3448 on 05-FEB-10
                       || '|'
                       || g_prorated_tax_amount
                                          --Added for defect 3448 on 27-JAN-10
                       || '|'
                       || lcu_bad_debt_credit.txparm_invoicedate
                       || '|'
                       || lcu_bad_debt_credit.ACCOUNT
                       || '|'
                       || g_company
                       || '|'
                       || g_shipfr_code
                       || '|'
                       || g_shipfr_country
                       || '|'
                       || g_shipfr_state
                       || '|'
                       || g_shipfr_cnty
                       || '|'
                       || g_shipfr_city
                       || '|'
                       || g_shipfr_zip
                       || '|'
                       || g_shipto_country
                       || '|'
                       || g_shipto_state
                       || '|'
                       || g_shipto_cnty
                       || '|'
                       || g_shipto_city
                       || '|'
                       || g_shipto_zip
                       || '|'
                       || g_poa_country
                       || '|'
                       || g_poa_state
                       || '|'
                       || g_poa_cnty
                       || '|'
                       || g_poa_city
                       || '|'
                       || g_poa_zip
                       || '|');
               -- END IF;                                           --Added for defect 6018
               ELSE              -- SDR project sinon - adj amt > original amt
                  lc_error_loc               :=
                        lc_error_loc
                     || ' Writing to UTL File in XXFIN_OUTBOUND '
                     || lcu_bad_debt_credit.trx_number
                     || ' AND '
                     || lcu_bad_debt_credit.txparm_invoiceno;
                                                   -- Add for the defect 17226
                  UTL_FILE.put_line
                     (l_output
                     ,    ' '
                       || '|'
                       || lcu_bad_debt_credit.trx_number
                       || '|'
                       || lcu_bad_debt_credit.txparm_invoiceno
                       || '|'
                       || g_gross_amt
                       || '|'
                       || g_tax_amt
                       || '|'
                       || g_prorated_gross_amount
                       || '|'
                       || g_prorated_tax_amount
                       || '|'
                       || lcu_bad_debt_credit.txparm_invoicedate
                       || '|'
                       || lcu_bad_debt_credit.ACCOUNT
                       || '|'
                       || g_company
                       || '|'
                       || g_shipfr_code
                       || '|'
                       || g_shipfr_country
                       || '|'
                       || g_shipfr_state
                       || '|'
                       || g_shipfr_cnty
                       || '|'
                       || g_shipfr_city
                       || '|'
                       || g_shipfr_zip
                       || '|'
                       || g_shipto_country
                       || '|'
                       || g_shipto_state
                       || '|'
                       || g_shipto_cnty
                       || '|'
                       || g_shipto_city
                       || '|'
                       || g_shipto_zip
                       || '|'
                       || g_poa_country
                       || '|'
                       || g_poa_state
                       || '|'
                       || g_poa_cnty
                       || '|'
                       || g_poa_city
                       || '|'
                       || g_poa_zip
                       || '|'
                       || 'Exception due to chargeback > original transaction amount');
                  UTL_FILE.fflush (l_output);
               END IF;  -- SDR project sinon - compare adj amt to original amt
            END IF;
         END IF;
      END LOOP;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         --Start of changes for defect 6018
         fnd_file.put_line (fnd_file.LOG, ' ');
         fnd_file.put_line (fnd_file.LOG, lc_error_loc);
         fnd_file.put_line (fnd_file.LOG, 'Error while '
                             || SQLERRM);
         --   p_error := FALSE;
         --   RAISE;
         --   FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message: '||SQLERRM);
         g_error_flag               := 'Y';
         fnd_file.put_line (fnd_file.LOG, ' ');
         fnd_file.put_line (fnd_file.LOG
                           ,    'Exception in BAD_DEBT_CREDITCARD '
                             || 'Error Flag: '
                             || g_error_flag);
         fnd_file.put_line (fnd_file.LOG, ' ');
   --End of changes for defect 6018
   END bad_debt_creditcard;

--The below Bad Debt Disputes is added for defect 3674
-- +===================================================================+
-- | Name        : BAD_DEBT_DISPUTES                                   |
-- | Description : Program to extract disputes created for tax lines   |
-- |               of a transaction and insert into                    |
-- |               Custom Batch Audit Table                            |
-- | Parameters  : p_od_calendar_month                                 |
-- |               p_error                                             |
-- | Returns     :                                                     |
-- |                p_error                                            |
-- +===================================================================+
   PROCEDURE bad_debt_disputes (
      p_period_start_date        IN       DATE
     ,p_period_end_date          IN       DATE
     ,p_error                    IN OUT NOCOPY BOOLEAN
   )
   AS
      ld_period_start_date          DATE := p_period_start_date;
      ld_period_end_date            DATE := p_period_end_date;
      lc_error_msg                  VARCHAR2 (2000);
      ln_req_id                     NUMBER;
      ln_batch_count                NUMBER := 0;
      ln_batch_hist_count           NUMBER := 0;
      lc_error_loc                  VARCHAR (30000) := NULL;
                                                     -- Added for defect 6018
      lc_error_flag                 VARCHAR2 (10);   -- Added for defect 6018
      ---sinonremovelc_adj_amt_flag      VARCHAR2(10) :='N';      -- SDR project sinon adj amt > original amt
      l_twe_ora_trx_id_2            NUMBER;

      CURSOR c_bad_debt_disp (
         p_period_start_date        IN       DATE
        ,p_period_end_date          IN       DATE
      )
      IS
         (SELECT rct.trx_number trx_number
		                 ,NVL (rctl.extended_amount, 0) adjusted_amount
                ,'D' p_flag
--Added for defect 3448 on 03-FEB-2010--Changed the flag from A to D for defect 3674 on 08-FEB-10
                ,NULL p_reference_id    --Added for defect 3448 on 03-FEB-2010
                --,TWE_ORA_TRX_ID_s.nextval                TWE_ORA_TRX_ID
          ,      fnd_profile.VALUE ('ORG_ID') orcl_org_id
                ,NULL jrparm_shipfr_geo
                ,NULL jrparm_shipfr_zipext
                ,NULL jrparm_shipto_geo
                ,NULL jrparm_shipto_zipext
                ,NULL jrparm_shipto_geocode
                ,NULL jrparm_poa_geo
                ,NULL jrparm_poa_zipext
                ,NULL jrparm_poo_geo
                ,NULL jrparm_poo_zipext
                ,NULL jrparm_billto_geo
                ,NULL jrparm_billto_zipext
                ,NULL jrparm_billto_geocode
                ,'O' jrparm_pot
                ,NULL txparm_frghtamt
                ,NULL txparm_discountamt
                ,10 txparm_calctype
                ,NULL txparm_prodcode
                ,DECODE (SIGN (DECODE (rctl.line_type
                                      ,'TAX', NVL (rctl.extended_amount, 0)
                                      ))
                        ,-1, 1
                        ,0
                        ) txparm_creditind
                ,0 txparm_invoicesumind
                ,rct_1.trx_number txparm_invoiceno
                ,NULL txparm_invoicelineno
                ,NULL txparm_locncode
                ,NULL txparm_costcenter
                ,1 txparm_reptind
                ,NULL txparm_jobno
                ,NULL txparm_volume
                ,NULL txparm_afeworkord
                ,NULL txparm_partnumber
                ,NULL txparm_miscinfo
                ,rct_1.invoice_currency_code txparm_currencycd1
                ,rct_1.trx_date ar_credit_date
                ,rctgl.gl_date txparm_invoicedate
                ,NULL txparm_streasoncode
                ,'Y' txparm_audit_flag
                ,'Y' txparm_forcetrans
                ,0 txparm_dropshipind
                ,NULL local_taxableamount
                ,NULL local_staterate
                ,NULL local_stateamnt_new
                ,NULL local_countyrate
                ,NULL local_countyamnt_new
                ,NULL local_cityrate
                ,NULL local_cityamnt_new
                ,NULL local_districtrate
                ,NULL local_districtamnt_new
                ,NULL txparm_forcestate
                ,NULL txparm_forcecounty
                ,NULL txparm_forcecity
                ,NULL txparm_forcedist
                ,NULL txparm_shipto_code
                ,NULL txparm_billto_code
                ,NULL txparm_custom_attributes
                ,NULL taxware_trans_id
                ,NULL record_status
                ,NULL parent_request_id
                ,NULL request_id
                ,NULL thread_id
                ,NULL txparm_gencmplcd1
                ,NULL txparm_gencmplcd2
                ,NULL txparm_gencmpltxt
                ,NULL jrparm_returncode
                ,SYSDATE creation_date
                ,fnd_profile.VALUE ('USER_ID') created_by
                ,NULL last_update_date
                ,NULL last_updated_by
                ,NULL last_update_login
                ,rct.customer_trx_id customer_trx_id   --Added for defect 4450
                ,    glcc.segment1
                  || '.'
                  || glcc.segment2
                  || '.'
                  || glcc.segment3
                  || '.'
                  || glcc.segment4
                  || '.'
                  || glcc.segment5
                  || '.'
                  || glcc.segment6
                  || '.'
                  || glcc.segment7 ACCOUNT
            FROM ra_cm_requests_all rcr
                ,iex_disputes ied
                ,ra_customer_trx_all rct
                ,ra_customer_trx_all rct_1
                ,ra_customer_trx_lines_all rctl
                ,xx_oe_order_headers_v ooh
                ,ra_cust_trx_line_gl_dist_all rctgl
                ,gl_code_combinations glcc
                --,xx_om_header_attributes_all              XOHA
                --,org_organization_definitions             OOD
          ,      ra_cust_trx_types_all ctt
                ,ra_batch_sources_all rbs
           where rcr.request_id = ied.cm_request_id(+)
             AND rcr.approval_date IS NOT NULL
             and rcr.customer_trx_id = rct.customer_trx_id
             AND rcr.cm_customer_trx_id = rct_1.customer_trx_id
             AND rctl.customer_trx_id = rct_1.customer_trx_id
             AND rct_1.batch_source_id = rbs.batch_source_id
             AND rbs.NAME = 'SERVICE'
             AND rctl.line_type = 'TAX'
             AND rctl.extended_amount != 0
             AND rct.attribute14 = ooh.header_id
             AND ooh.org_id = fnd_profile.VALUE ('ORG_ID')
             AND rct_1.customer_trx_id = rctgl.customer_trx_id
             AND rctgl.account_class = 'REC'
             AND rctgl.code_combination_id = glcc.code_combination_id
             --AND     OOD.organization_id = OOH.ship_from_org_id
             --AND     XOHA.header_id  = OOH.header_id
             AND rct.cust_trx_type_id = ctt.cust_trx_type_id
             AND rctgl.gl_date BETWEEN p_period_start_date AND p_period_end_date
             AND ctt.tax_calculation_flag = 'N'
          UNION
          ---*****   FOR WEBCOLLECT PROJECT - HANDLE NEW SOURCE TYPE CALLED 'OD_WC_CM' DEFECT 15910
          SELECT rct.trx_number trx_number
                ,NVL (rctl.extended_amount, 0) adjusted_amount
                ,'D' p_flag
--Added for defect 3448 on 03-FEB-2010--Changed the flag from A to D for defect 3674 on 08-FEB-10
                ,NULL p_reference_id    --Added for defect 3448 on 03-FEB-2010
                --,Null                                    Twe_Ora_Trx_Id
                --,TWE_ORA_TRX_ID_s.nextval                TWE_ORA_TRX_ID
          ,      fnd_profile.VALUE ('ORG_ID') orcl_org_id
                ,NULL jrparm_shipfr_geo
                ,NULL jrparm_shipfr_zipext
                ,NULL jrparm_shipto_geo
                ,NULL jrparm_shipto_zipext
                ,NULL jrparm_shipto_geocode
                ,NULL jrparm_poa_geo
                ,NULL jrparm_poa_zipext
                ,NULL jrparm_poo_geo
                ,NULL jrparm_poo_zipext
                ,NULL jrparm_billto_geo
                ,NULL jrparm_billto_zipext
                ,NULL jrparm_billto_geocode
                ,'O' jrparm_pot
                ,NULL txparm_frghtamt
                ,NULL txparm_discountamt
                ,10 txparm_calctype
                ,NULL txparm_prodcode
                ,DECODE (SIGN (DECODE (rctl.line_type
                                      ,'TAX', NVL (rctl.extended_amount, 0)
                                      ))
                        ,-1, 1
                        ,0
                        ) txparm_creditind
                ,0 txparm_invoicesumind
                ,rct_1.trx_number txparm_invoiceno
                ,NULL txparm_invoicelineno
                ,NULL txparm_locncode
                ,NULL txparm_costcenter
                ,1 txparm_reptind
                ,NULL txparm_jobno
                ,NULL txparm_volume
                ,NULL txparm_afeworkord
                ,NULL txparm_partnumber
                ,NULL txparm_miscinfo
                ,rct_1.invoice_currency_code txparm_currencycd1
                ,rct_1.trx_date ar_credit_date
                ,rctgl.gl_date txparm_invoicedate
                ,NULL txparm_streasoncode
                ,'Y' txparm_audit_flag
                ,'Y' txparm_forcetrans
                ,0 txparm_dropshipind
                ,NULL local_taxableamount
                ,NULL local_staterate
                ,NULL local_stateamnt_new
                ,NULL local_countyrate
                ,NULL local_countyamnt_new
                ,NULL local_cityrate
                ,NULL local_cityamnt_new
                ,NULL local_districtrate
                ,NULL local_districtamnt_new
                ,NULL txparm_forcestate
                ,NULL txparm_forcecounty
                ,NULL txparm_forcecity
                ,NULL txparm_forcedist
                ,NULL txparm_shipto_code
                ,NULL txparm_billto_code
                ,NULL txparm_custom_attributes
                ,NULL taxware_trans_id
                ,NULL record_status
                ,NULL parent_request_id
                ,NULL request_id
                ,NULL thread_id
                ,NULL txparm_gencmplcd1
                ,NULL txparm_gencmplcd2
                ,NULL txparm_gencmpltxt
                ,NULL jrparm_returncode
                ,SYSDATE creation_date
                ,fnd_profile.VALUE ('USER_ID') created_by
                ,NULL last_update_date
                ,NULL last_updated_by
                ,NULL last_update_login
                ,rct.customer_trx_id customer_trx_id   --Added for defect 4450
                ,    glcc.segment1
                  || '.'
                  || glcc.segment2
                  || '.'
                  || glcc.segment3
                  || '.'
                  || glcc.segment4
                  || '.'
                  || glcc.segment5
                  || '.'
                  || glcc.segment6
                  || '.'
                  || glcc.segment7 ACCOUNT
            FROM ra_customer_trx_all rct
                ,ra_customer_trx_all rct_1
                ,ra_customer_trx_lines_all rctl
                ,ra_cust_trx_line_gl_dist_all rctgl
                ,gl_code_combinations glcc
                ,ra_cust_trx_types_all ctt
                ,ra_batch_sources_all rbs
           where rct.customer_trx_id = rctl.customer_trx_id
             AND rctl.customer_trx_id = rct_1.customer_trx_id
             AND rct_1.batch_source_id = rbs.batch_source_id
			 AND rct.org_id = fnd_profile.VALUE ('ORG_ID')--added Defect#32418
             AND rbs.NAME = 'OD_WC_CM'
             AND rctl.line_type = 'TAX'
             AND rctl.extended_amount != 0
             AND rct_1.customer_trx_id = rctgl.customer_trx_id
             AND rctgl.account_class = 'REC'
             AND rctgl.code_combination_id = glcc.code_combination_id
             AND rct.cust_trx_type_id = ctt.cust_trx_type_id
             AND rctgl.gl_date BETWEEN p_period_start_date AND p_period_end_date
             AND ctt.tax_calculation_flag = 'N');
   ---***** FOR WEBCOLLECT PROJECT
   BEGIN
      -- Start of changes for Defect 6018
      /*
      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
      FND_FILE.PUT_LINE(FND_FILE.LOG,FND_PROFILE.VALUE('ORG_ID'));
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Parameters');
      FND_FILE.PUT_LINE(FND_FILE.LOG,ld_period_start_date);
      FND_FILE.PUT_LINE(FND_FILE.LOG,ld_period_end_date);
      */
      -- End of changes for Defect 6018
      fnd_file.put_line (fnd_file.LOG, ' ');
      fnd_file.put_line (fnd_file.LOG, '------------------------------- ');
      fnd_file.put_line (fnd_file.LOG, 'Disputes Transactions');
      fnd_file.put_line (fnd_file.LOG, '------------------------------- ');
      fnd_file.put_line (fnd_file.LOG, ' ');
      --Removed the column PRO-RATED ADJUSTMENT NUMBER and Rename the label PRO-RATED GROSS AMOUNT to GROSS ADJ AMOUNT for defect 3448 on 05-FEB-10
      fnd_file.put_line
         (fnd_file.LOG
         ,'BAD DEBT TYPE|INVOICE NO|ADJUSTMENT NUMBER|ORIGINAL INVOICE AMOUNT|ORIGINAL TAX AMOUNT|GROSS ADJ AMOUNT|PRO-RATED TAX AMOUNT|APPLY DATE|ACCOUNT|COMPANY ID|SHIP FROM CODE|SHIP FROM COUNTRY|SHIP FROM STATE|SHIP FROM COUNTY|SHIP FROM CITY|SHIP FROM ZIP|SHIP TO COUNTRY|SHIP TO STATE|SHIP TO COUNTY|SHIP TO CITY|SHIP TO ZIP|POA COUNTRY|POA STATE|POA COUNTY|POA CITY|POA ZIP|');
      fnd_file.put_line (fnd_file.LOG, ' ');

      FOR lcu_bad_debt_disp IN c_bad_debt_disp (ld_period_start_date
                                               ,ld_period_end_date)
      LOOP
         /********** To Check if the Dispute has been processed already ********/
         -- SELECT COUNT(*)
         SELECT COUNT (1)           -- Changed for performance for Defect 3674
           INTO ln_batch_count
           FROM xx_ar_twe_audit_trans_all twe
          WHERE txparm_invoiceno = lcu_bad_debt_disp.txparm_invoiceno
            AND customer_trx_id = lcu_bad_debt_disp.customer_trx_id;
                                                       --Added for defect 4450

         -- SELECT COUNT(*)
         SELECT COUNT (1)           -- Changed for performance for Defect 3674
           INTO ln_batch_hist_count
           FROM xx_ar_twe_audit_trans_all_hist twe
          WHERE txparm_invoiceno = lcu_bad_debt_disp.txparm_invoiceno
            AND customer_trx_id = lcu_bad_debt_disp.customer_trx_id;
                                                       --Added for defect 4450

         lc_error_loc               := NULL;
                                         --Added for Defect #6018 on 17-JUN-10

         SELECT twe_ora_trx_id_s.NEXTVAL twe_ora_trx_id
           INTO l_twe_ora_trx_id_2
           FROM DUAL;

         IF     ln_batch_count = 0
            AND ln_batch_hist_count = 0
         THEN
            --FETCHING VALUES FOR SHIPTO,SHIPFROM,POO,POA,BILLTO,COMPANY CODE
            lc_error_loc               :=
                  lc_error_loc
               || ' Calling the BAD_DEBT_VALUES procedure from BAD_DEBT_DISPUTES';
                                                       --Added for defect 6018
            bad_debt_values
               (lcu_bad_debt_disp.trx_number
                                          --Added for defect 3674 on 08-FEB-10
               ,lcu_bad_debt_disp.customer_trx_id     --Added for defect 17226
               ,lcu_bad_debt_disp.txparm_invoiceno
               ,lcu_bad_debt_disp.adjusted_amount -- Added for the Defect 3448
               ,lcu_bad_debt_disp.p_flag          -- Added for the Defect 3448
               ,lcu_bad_debt_disp.p_reference_id  -- Added for the Defect 3448
               ,lc_error_flag
               );                                 -- Added for the Defect 6018

            ---sinonremove,lc_adj_amt_flag);                  --SDR project sinon
            IF lc_error_flag <> 'Y'
            THEN                                  -- Added for the Defect 6018
               --sinonremoveIF lc_adj_amt_flag <> 'Y' THEN                     -- SDR project sinon - adj amt <= original amt
               IF (ABS (  g_gross_amt
                        + g_tax_amt) >=
                         ABS (  g_prorated_gross_amount
                              + g_prorated_tax_amount)
                  )
               THEN             -- SDR project sinon - adj amt <= original amt
                  INSERT INTO xx_ar_twe_audit_trans_all
                              (twe_ora_trx_id
                              ,orcl_org_id
                              ,jrparm_shipfr_country
                              ,jrparm_shipfr_state
                              ,jrparm_shipfr_cnty
                              ,jrparm_shipfr_city
                              ,jrparm_shipfr_zip
                              ,jrparm_shipfr_geo
                              ,jrparm_shipfr_zipext
                              ,jrparm_shipto_country
                              ,jrparm_shipto_state
                              ,jrparm_shipto_cnty
                              ,jrparm_shipto_city
                              ,jrparm_shipto_zip
                              ,jrparm_shipto_geo
                              ,jrparm_shipto_zipext
                              ,jrparm_shipto_geocode
                              ,jrparm_poa_country
                              ,jrparm_poa_state
                              ,jrparm_poa_cnty
                              ,jrparm_poa_city
                              ,jrparm_poa_zip
                              ,jrparm_poa_geo
                              ,jrparm_poa_zipext
                              ,jrparm_poo_country
                              ,jrparm_poo_state
                              ,jrparm_poo_cnty
                              ,jrparm_poo_city
                              ,jrparm_poo_zip
                              ,jrparm_poo_geo
                              ,jrparm_poo_zipext
                              ,jrparm_billto_country
                              ,jrparm_billto_state
                              ,jrparm_billto_cnty
                              ,jrparm_billto_city
                              ,jrparm_billto_zip
                              ,jrparm_billto_geo
                              ,jrparm_billto_zipext
                              ,jrparm_billto_geocode
                              ,jrparm_pot
                              ,txparm_grossamt
                              ,txparm_frghtamt
                              ,txparm_discountamt
                              ,txparm_custno
                              ,txparm_custname
                              ,txparm_numitems
                              ,txparm_calctype
                              ,txparm_prodcode
                              ,txparm_creditind
                              ,txparm_invoicesumind
                              ,txparm_invoicedate
                              ,txparm_invoiceno
                              ,txparm_invoicelineno
                              ,txparm_companyid
                              ,txparm_locncode
                              ,txparm_costcenter
                              ,txparm_reptind
                              ,txparm_jobno
                              ,txparm_volume
                              ,txparm_afeworkord
                              ,txparm_partnumber
                              ,txparm_miscinfo
                              ,txparm_currencycd1
                              ,txparm_dropshipind
                              ,txparm_streasoncode
                              ,txparm_audit_flag
                              ,txparm_forcetrans
                              ,local_total_tax
                              ,local_taxableamount
                              ,local_staterate
                              ,local_stateamnt_new
                              ,local_countyrate
                              ,local_countyamnt_new
                              ,local_cityrate
                              ,local_cityamnt_new
                              ,local_districtrate
                              ,local_districtamnt_new
                              ,txparm_forcestate
                              ,txparm_forcecounty
                              ,txparm_forcecity
                              ,txparm_forcedist
                              ,txparm_shipto_code
                              ,txparm_billto_code
                              ,txparm_shipfrom_code
                              ,txparm_poo_code
                              ,txparm_poa_code
                              ,txparm_custom_attributes
                              ,taxware_trans_id
                              ,record_status
                              ,parent_request_id
                              ,request_id
                              ,thread_id
                              ,txparm_gencmplcd1
                              ,txparm_gencmplcd2
                              ,txparm_gencmpltxt
                              ,jrparm_returncode
                              ,creation_date
                              ,created_by
                              ,last_update_date
                              ,last_updated_by
                              ,last_update_login
                              ,customer_trx_id
         --Added the column in xx_ar_twe_audit_trans_all table for defect 4450
                              )
                       --VALUES    (  lcu_bad_debt_disp.TWE_ORA_TRX_ID
                  VALUES      (l_twe_ora_trx_id_2
                              ,lcu_bad_debt_disp.orcl_org_id
                              ,g_shipfr_country
                              ,g_shipfr_state
                              ,g_shipfr_cnty
                              ,g_shipfr_city
                              ,g_shipfr_zip
                              ,lcu_bad_debt_disp.jrparm_shipfr_geo
                              ,lcu_bad_debt_disp.jrparm_shipfr_zipext
                              ,g_shipto_country
                              ,g_shipto_state
                              ,g_shipto_cnty
                              ,g_shipto_city
                              ,g_shipto_zip
                              ,lcu_bad_debt_disp.jrparm_shipto_geo
                              ,lcu_bad_debt_disp.jrparm_shipto_zipext
                              ,lcu_bad_debt_disp.jrparm_shipto_geocode
                              ,g_poa_country
                              ,g_poa_state
                              ,g_poa_cnty
                              ,g_poa_city
                              ,g_poa_zip
                              ,lcu_bad_debt_disp.jrparm_poa_geo
                              ,lcu_bad_debt_disp.jrparm_poa_zipext
                              ,g_poo_country
                              ,g_poo_state
                              ,g_poo_cnty
                              ,g_poo_city
                              ,g_poo_zip
                              ,lcu_bad_debt_disp.jrparm_poo_geo
                              ,lcu_bad_debt_disp.jrparm_poo_zipext
                              ,g_billto_country
                              ,g_billto_state
                              ,g_billto_cnty
                              ,g_billto_city
                              ,g_billto_zip
                              ,lcu_bad_debt_disp.jrparm_billto_geo
                              ,lcu_bad_debt_disp.jrparm_billto_zipext
                              ,lcu_bad_debt_disp.jrparm_billto_geocode
                              ,lcu_bad_debt_disp.jrparm_pot
                              --,NVL(g_gross_amt,0)                          --Commented for defect 4450
                  ,            NVL
                                  (g_prorated_gross_amount, 0)
                                                       --Added for defect 4450
                              ,lcu_bad_debt_disp.txparm_frghtamt
                              ,lcu_bad_debt_disp.txparm_discountamt
                              ,g_customer_number
                              ,g_cust_name
                              ,NVL (g_quantity, 0)
                              ,lcu_bad_debt_disp.txparm_calctype
                              ,lcu_bad_debt_disp.txparm_prodcode
                              ,lcu_bad_debt_disp.txparm_creditind
                              ,lcu_bad_debt_disp.txparm_invoicesumind
                              ,lcu_bad_debt_disp.txparm_invoicedate
                              ,lcu_bad_debt_disp.txparm_invoiceno
                              ,lcu_bad_debt_disp.txparm_invoicelineno
                              ,g_company
                              ,lcu_bad_debt_disp.txparm_locncode
                              ,lcu_bad_debt_disp.txparm_costcenter
                              ,lcu_bad_debt_disp.txparm_reptind
                              ,lcu_bad_debt_disp.txparm_jobno
                              ,lcu_bad_debt_disp.txparm_volume
                              ,lcu_bad_debt_disp.txparm_afeworkord
                              ,lcu_bad_debt_disp.txparm_partnumber
                              ,lcu_bad_debt_disp.txparm_miscinfo
                              ,lcu_bad_debt_disp.txparm_currencycd1
                              ,lcu_bad_debt_disp.txparm_dropshipind
                              ,lcu_bad_debt_disp.txparm_streasoncode
                              ,lcu_bad_debt_disp.txparm_audit_flag
                              ,lcu_bad_debt_disp.txparm_forcetrans
                              --,NVL(g_tax_amt,0)                          --Commented for defect 4450
                  ,            NVL
                                  (g_prorated_tax_amount, 0)
                                                       --Added for defect 4450
                              ,lcu_bad_debt_disp.local_taxableamount
                              ,lcu_bad_debt_disp.local_staterate
                              ,lcu_bad_debt_disp.local_stateamnt_new
                              ,lcu_bad_debt_disp.local_countyrate
                              ,lcu_bad_debt_disp.local_countyamnt_new
                              ,lcu_bad_debt_disp.local_cityrate
                              ,lcu_bad_debt_disp.local_cityamnt_new
                              ,lcu_bad_debt_disp.local_districtrate
                              ,lcu_bad_debt_disp.local_districtamnt_new
                              ,lcu_bad_debt_disp.txparm_forcestate
                              ,lcu_bad_debt_disp.txparm_forcecounty
                              ,lcu_bad_debt_disp.txparm_forcecity
                              ,lcu_bad_debt_disp.txparm_forcedist
                              ,lcu_bad_debt_disp.txparm_shipto_code
                              ,lcu_bad_debt_disp.txparm_billto_code
                              ,g_shipfr_code
                              ,g_poo_code
                              ,g_poa_code
                              ,lcu_bad_debt_disp.txparm_custom_attributes
                              ,lcu_bad_debt_disp.taxware_trans_id
                              ,lcu_bad_debt_disp.record_status
                              ,lcu_bad_debt_disp.parent_request_id
                              ,lcu_bad_debt_disp.request_id
                              ,lcu_bad_debt_disp.thread_id
                              ,lcu_bad_debt_disp.txparm_gencmplcd1
                              ,lcu_bad_debt_disp.txparm_gencmplcd2
                              ,lcu_bad_debt_disp.txparm_gencmpltxt
                              ,lcu_bad_debt_disp.jrparm_returncode
                              ,lcu_bad_debt_disp.creation_date
                              ,lcu_bad_debt_disp.created_by
                              ,lcu_bad_debt_disp.last_update_date
                              ,lcu_bad_debt_disp.last_updated_by
                              ,lcu_bad_debt_disp.last_update_login
                              ,lcu_bad_debt_disp.customer_trx_id
                                                       --Added for defect 4450
                              );

                  lc_error_flag              := NULL;
                  lc_error_loc               :=
                                             lc_error_loc
                                          || ' Insert Successful';
                  fnd_file.put_line
                     (fnd_file.output
                     ,    'D-'
                       || '|'
                       || lcu_bad_debt_disp.trx_number
                       || '|'
                       || lcu_bad_debt_disp.txparm_invoiceno
                       || '|'
                       || NVL (g_gross_amt, 0)
                       || '|'
                       || NVL (g_tax_amt, 0)
                       || '|'
                       || g_prorated_gross_amount
                                          --Added for defect 3448 on 03-FEB-10
                       --||'|'||g_prorated_adjustment_amount --Added for defect 3448 on 27-JAN-10--Commented  for defect 3448 on 05-FEB-10
                       || '|'
                       || g_prorated_tax_amount
                                          --Added for defect 3448 on 03-FEB-10
                       || '|'
                       || lcu_bad_debt_disp.txparm_invoicedate
                       || '|'
                       || lcu_bad_debt_disp.ACCOUNT
                       || '|'
                       || g_company
                       || '|'
                       || g_shipfr_code
                       || '|'
                       || g_shipfr_country
                       || '|'
                       || g_shipfr_state
                       || '|'
                       || g_shipfr_cnty
                       || '|'
                       || g_shipfr_city
                       || '|'
                       || g_shipfr_zip
                       || '|'
                       || g_shipto_country
                       || '|'
                       || g_shipto_state
                       || '|'
                       || g_shipto_cnty
                       || '|'
                       || g_shipto_city
                       || '|'
                       || g_shipto_zip
                       || '|'
                       || g_poa_country
                       || '|'
                       || g_poa_state
                       || '|'
                       || g_poa_cnty
                       || '|'
                       || g_poa_city
                       || '|'
                       || g_poa_zip
                       || '|');
                  fnd_file.put_line
                     (fnd_file.LOG
                     ,    'D-'
                       || '|'
                       || lcu_bad_debt_disp.trx_number
                       || '|'
                       || lcu_bad_debt_disp.txparm_invoiceno
                       || '|'
                       || NVL (g_gross_amt, 0)
                       || '|'
                       || NVL (g_tax_amt, 0)
                       || '|'
                       || g_prorated_gross_amount
                                          --Added for defect 3448 on 27-JAN-10
                       --||'|'||g_prorated_adjustment_amount--Added for defect 3448 on 27-JAN-10--Commented  for defect 3448 on 05-FEB-10
                       || '|'
                       || g_prorated_tax_amount
                                          --Added for defect 3448 on 27-JAN-10
                       || '|'
                       || lcu_bad_debt_disp.txparm_invoicedate
                       || '|'
                       || lcu_bad_debt_disp.ACCOUNT
                       || '|'
                       || g_company
                       || '|'
                       || g_shipfr_code
                       || '|'
                       || g_shipfr_country
                       || '|'
                       || g_shipfr_state
                       || '|'
                       || g_shipfr_cnty
                       || '|'
                       || g_shipfr_city
                       || '|'
                       || g_shipfr_zip
                       || '|'
                       || g_shipto_country
                       || '|'
                       || g_shipto_state
                       || '|'
                       || g_shipto_cnty
                       || '|'
                       || g_shipto_city
                       || '|'
                       || g_shipto_zip
                       || '|'
                       || g_poa_country
                       || '|'
                       || g_poa_state
                       || '|'
                       || g_poa_cnty
                       || '|'
                       || g_poa_city
                       || '|'
                       || g_poa_zip
                       || '|');
               --      END IF;                                 -- Added for the Defect 6018
               ELSE              -- SDR project sinon - adj amt > original amt
                  lc_error_loc               :=
                        lc_error_loc
                     || ' Writing to UTL File in XXFIN_OUTBOUND '
                     || lcu_bad_debt_disp.trx_number
                     || ' AND '
                     || lcu_bad_debt_disp.txparm_invoiceno;
                                                   -- Add for the defect 17226
                  UTL_FILE.put_line
                     (l_output
                     ,    ' '
                       || '|'
                       || lcu_bad_debt_disp.trx_number
                       || '|'
                       || lcu_bad_debt_disp.txparm_invoiceno
                       || '|'
                       || NVL (g_gross_amt, 0)
                       || '|'
                       || NVL (g_tax_amt, 0)
                       || '|'
                       || g_prorated_gross_amount
                                          --Added for defect 3448 on 27-JAN-10
                       || '|'
                       || g_prorated_tax_amount
                                          --Added for defect 3448 on 27-JAN-10
                       || '|'
                       || lcu_bad_debt_disp.txparm_invoicedate
                       || '|'
                       || lcu_bad_debt_disp.ACCOUNT
                       || '|'
                       || g_company
                       || '|'
                       || g_shipfr_code
                       || '|'
                       || g_shipfr_country
                       || '|'
                       || g_shipfr_state
                       || '|'
                       || g_shipfr_cnty
                       || '|'
                       || g_shipfr_city
                       || '|'
                       || g_shipfr_zip
                       || '|'
                       || g_shipto_country
                       || '|'
                       || g_shipto_state
                       || '|'
                       || g_shipto_cnty
                       || '|'
                       || g_shipto_city
                       || '|'
                       || g_shipto_zip
                       || '|'
                       || g_poa_country
                       || '|'
                       || g_poa_state
                       || '|'
                       || g_poa_cnty
                       || '|'
                       || g_poa_city
                       || '|'
                       || g_poa_zip
                       || '|'
                       || 'Exception due to chargeback > original transaction amount');
                  UTL_FILE.fflush (l_output);
               END IF;  -- SDR project sinon - compare adj amt to original amt
            END IF;
         END IF;
      END LOOP;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         --Start of changes for defect 6018
         fnd_file.put_line (fnd_file.LOG, ' ');
         fnd_file.put_line (fnd_file.LOG, lc_error_loc);
         fnd_file.put_line (fnd_file.LOG, 'Error while '
                             || SQLERRM);
         --   p_error := FALSE;
         --   RAISE;
         --   FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message: '||SQLERRM);
         g_error_flag               := 'Y';
         fnd_file.put_line (fnd_file.LOG, ' ');
         fnd_file.put_line (fnd_file.LOG
                           ,    'Exception in BAD_DEBT_DISPUTES '
                             || 'Error Flag: '
                             || g_error_flag);
         fnd_file.put_line (fnd_file.LOG, ' ');
   --End of changes for defect 6018
   END bad_debt_disputes;

-- +===================================================================+
-- | Name : SUBMIT_REQUEST                                             |
-- | Description : Procedure to Submit the main BAD_DEBT_CREDITCARD    |
-- |               procedure                                           |
-- | This procedure will be the executable of Concurrent               |
-- | program : OD: TAX AR Bad Debt Process                             |
-- | Parameters :    p_od_calendar_month                               |
-- |                 p_od_chargeback_type1                             |
-- |                 p_od_chargeback_type2                             |
-- |                 p_od_chargeback_type3                             |
-- |                 p_od_chargeback_type4                             |
-- |                 p_od_chargeback_type5                             |
-- |                 p_od_chargeback_type6                             |
-- |                 p_od_chargeback_type7                             |
-- |                 p_od_chargeback_type8                             |
-- |                 p_od_chargeback_type9                             |
-- |                 p_od_chargeback_type10                            |
-- |                 p_error                                           |
-- | Returns :                                                         |
-- |        return code , error msg                                    |
-- +===================================================================+
   PROCEDURE submit_request (
      x_error_buff               OUT NOCOPY VARCHAR2
     ,x_ret_code                 OUT NOCOPY NUMBER
     ,p_od_calendar_month        IN       VARCHAR2
     ,p_od_chargeback_type1      IN       VARCHAR2
     ,p_od_chargeback_type2      IN       VARCHAR2
     ,p_od_chargeback_type3      IN       VARCHAR2
     ,p_od_chargeback_type4      IN       VARCHAR2
     ,p_od_chargeback_type5      IN       VARCHAR2
     ,p_od_chargeback_type6      IN       VARCHAR2
     ,p_od_chargeback_type7      IN       VARCHAR2
     ,p_od_chargeback_type8      IN       VARCHAR2
     ,p_od_chargeback_type9      IN       VARCHAR2
     ,p_od_chargeback_type10     IN       VARCHAR2
   )
   AS
      lp_calendar_month             VARCHAR2 (100) := p_od_calendar_month;
      lp_chargeback_type1           VARCHAR2 (100) := p_od_chargeback_type1;
      lp_chargeback_type2           VARCHAR2 (100) := p_od_chargeback_type2;
      lp_chargeback_type3           VARCHAR2 (100) := p_od_chargeback_type3;
      lp_chargeback_type4           VARCHAR2 (100) := p_od_chargeback_type4;
      lp_chargeback_type5           VARCHAR2 (100) := p_od_chargeback_type5;
      lp_chargeback_type6           VARCHAR2 (100) := p_od_chargeback_type6;
      lp_chargeback_type7           VARCHAR2 (100) := p_od_chargeback_type7;
      lp_chargeback_type8           VARCHAR2 (100) := p_od_chargeback_type8;
      lp_chargeback_type9           VARCHAR2 (100) := p_od_chargeback_type9;
      lp_chargeback_type10          VARCHAR2 (100) := p_od_chargeback_type10;
      lc_error                      BOOLEAN := TRUE;
      lc_error_loc                  VARCHAR2 (2000) := NULL;
   BEGIN
      ---Added two columns for defect 3448 on 27-JAN-10
      --Removed the column PRO-RATED ADJUSTMENT NUMBER and Rename the label PRO-RATED GROSS AMOUNT to GROSS ADJ AMOUNT for defect 3448 on 05-FEB-10
      fnd_file.put_line
         (fnd_file.output
         ,'BAD DEBT TYPE|INVOICE NO|ADJUSTMENT NUMBER|ORIGINAL INVOICE AMOUNT|ORIGINAL TAX AMOUNT|GROSS ADJ AMOUNT|PRO-RATED TAX AMOUNT|APPLY DATE|ACCOUNT|COMPANY ID|SHIP FROM CODE|SHIP FROM COUNTRY|SHIP FROM STATE|SHIP FROM COUNTY|SHIP FROM CITY|SHIP FROM ZIP|SHIP TO COUNTRY|SHIP TO STATE|SHIP TO COUNTY|SHIP TO CITY|SHIP TO ZIP|POA COUNTRY|POA STATE|POA COUNTY|POA CITY|POA ZIP|');

      -- To Get the Period Dates ---For Defect 14246
      SELECT start_date
            ,end_date
        INTO g_period_start_date
            ,g_period_end_date
        FROM gl_period_statuses
       WHERE set_of_books_id = fnd_profile.VALUE ('GL_SET_OF_BKS_ID')
         AND application_id = 101
         AND period_name = lp_calendar_month;

      --Start of changes for defect 6018
      fnd_file.put_line (fnd_file.LOG, ' ');
      fnd_file.put_line
             (fnd_file.LOG
             ,'**************************Parameters**************************');
      fnd_file.put_line
            (fnd_file.LOG
            ,'                                                               ');
      fnd_file.put_line (fnd_file.LOG
                        ,    'Period Start Date: '
                          || g_period_start_date);
      fnd_file.put_line (fnd_file.LOG
                        ,    'Period End Date  : '
                          || g_period_end_date);
      fnd_file.put_line (fnd_file.LOG
                        ,    'Chargeback Type1 : '
                          || lp_chargeback_type1);
      fnd_file.put_line (fnd_file.LOG
                        ,    'Chargeback Type2 : '
                          || lp_chargeback_type2);
      fnd_file.put_line (fnd_file.LOG
                        ,    'Chargeback Type3 : '
                          || lp_chargeback_type3);
      fnd_file.put_line (fnd_file.LOG
                        ,    'Chargeback Type4 : '
                          || lp_chargeback_type4);
      fnd_file.put_line (fnd_file.LOG
                        ,    'Chargeback Type5 : '
                          || lp_chargeback_type5);
      fnd_file.put_line (fnd_file.LOG
                        ,    'Chargeback Type6 : '
                          || lp_chargeback_type6);
      fnd_file.put_line (fnd_file.LOG
                        ,    'Chargeback Type7 : '
                          || lp_chargeback_type7);
      fnd_file.put_line (fnd_file.LOG
                        ,    'Chargeback Type8 : '
                          || lp_chargeback_type8);
      fnd_file.put_line (fnd_file.LOG
                        ,    'Chargeback Type8 : '
                          || lp_chargeback_type9);
      fnd_file.put_line (fnd_file.LOG
                        ,    'Chargeback Type10: '
                          || lp_chargeback_type10);
      fnd_file.put_line (fnd_file.LOG
                        ,    'ORG ID: '
                          || fnd_profile.VALUE ('ORG_ID'));

  --End of changes for defect 6018
  -- Start of changes for defect 10843 for SDR changes - sinon
--Start modification by Adithya for 18774
  --FNAME    := 'Bad_Debt_Exception_Report_' || sysdate || '.txt';
      IF fnd_profile.VALUE ('ORG_ID') = 404
      THEN
         fname                      :=
                            'Bad_Debt_Exception_Report_US_'
                         || SYSDATE
                         || '.txt';
      ELSE
         fname                      :=
                            'Bad_Debt_Exception_Report_CA_'
                         || SYSDATE
                         || '.txt';
      END IF;

    --End  modification by Adithya for 18774
      l_output                   :=     UTL_FILE.fopen ('XXFIN_OUTBOUND'
                                         ,fname
                                         ,'W'
                                         ,32767
                                         );  -- 32767 add for the defect 17226
      UTL_FILE.fflush (l_output);
      UTL_FILE.put_line (l_output, '#FILE_NAME:Bad_Debt_Exception_Report.TXT');
      UTL_FILE.fflush (l_output);
      UTL_FILE.put_line
         (l_output
         ,'BAD DEBT TYPE|INVOICE NO|ADJUSTMENT NUMBER|ORIGINAL INVOICE AMOUNT|ORIGINAL TAX AMOUNT|GROSS ADJ AMOUNT|PRO-RATED TAX AMOUNT|APPLY DATE|ACCOUNT|COMPANY ID|SHIP FROM CODE|SHIP FROM COUNTRY|SHIP FROM STATE|SHIP FROM COUNTY|SHIP FROM CITY|SHIP FROM ZIP|SHIP TO COUNTRY|SHIP TO STATE|SHIP TO COUNTY|SHIP TO CITY|SHIP TO ZIP|POA COUNTRY|POA STATE|POA COUNTY|POA CITY|POA ZIP|COMMENTS');
      UTL_FILE.fflush (l_output);
      -- End of changes for defect 10843 for SDR changes - sinon
      lc_error_loc               :=
                  lc_error_loc
               || ' The BAD_DEBT_CREDITCARD procedure is called ';
                                                       --Added for defect 6018

      bad_debt_creditcard (g_period_start_date
                          ,g_period_end_date
                          ,lp_chargeback_type1
                          ,lp_chargeback_type2
                          ,lp_chargeback_type3
                          ,lp_chargeback_type4
                          ,lp_chargeback_type5
                          ,lp_chargeback_type6
                          ,lp_chargeback_type7
                          ,lp_chargeback_type8
                          ,lp_chargeback_type9
                          ,lp_chargeback_type10
                          ,lc_error
                          );
      lc_error_loc               :=
                lc_error_loc
             || ' The BAD_DEBT_TRANSACTIONS procedure is called ';
                                                       --Added for defect 6018
       bad_debt_transactions (g_period_start_date
                            ,g_period_end_date
                            ,lc_error
                            );
      -- Added the below procedure call for defect 3674
      lc_error_loc               :=
                    lc_error_loc
                 || ' The BAD_DEBT_DISPUTES procedure is called ';
                                                       --Added for defect 6018
        bad_debt_disputes (g_period_start_date
                        ,g_period_end_date
                        ,lc_error
                        );

            --Start of changes for defect 6018
      IF g_error_flag = 'Y'
      THEN
         fnd_file.put_line (fnd_file.LOG, ' ');
         fnd_file.put_line
                     (fnd_file.LOG
                     ,'Ending the Program in a Warning because of exceptions');
         fnd_file.put_line (fnd_file.LOG, ' ');
         x_ret_code                 := 1;
      END IF;

      --End of changes for defect 6018
      --Start of defect 10843 for SDR changes - sinon
      UTL_FILE.fclose (l_output);
      lc_ftp_process             := 'OD_AP_TAX_AUDIT';
      --start of changes for defect# 19726 - Archana N.
      lc_printer                 :=
             fnd_request.set_print_options (printer                       => 'noprint'
                                           ,copies                        => 0);
                            -- setting print option for the Common put program
      --end of changes for defect# 19726 - Archana N.
      ln_req_id                  :=
         fnd_request.submit_request ('XXFIN'
                                    ,'XXCOMFTP'
                                    ,''
                                    ,'01-OCT-04 00:00:00'
                                    ,FALSE
                                    ,lc_ftp_process
                                    ,fname
                                    ,fname
                                    ,'Y'
                                    );
      COMMIT;

      IF ln_req_id > 0
      THEN
         fnd_file.put_line (fnd_file.LOG, 'SUBMITTED FOR'
                             || fname);
      ELSE
         fnd_file.put_line (fnd_file.LOG, 'FAILED SUBMISSION FOR '
                             || fname);
      END IF;
   --End of defect 10843 for SDR changes - sinon
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Error while '
                             || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, lc_error_loc);
   END submit_request;

--ADDING the FUNCTION is_legacy_batch_source from XX_AR_TWE_UTIL_PKG as part of defect 27364
FUNCTION is_legacy_batch_source (
    p_ar_batch_source in varchar2 ) return number is

    l_is_legacy_batch_source number(15) := 0;

     cursor csr_twe_recsrc_lkp IS
      select lookup_code
      from fnd_lookup_values
      where lookup_type = 'TWE_RECORD_SOURCES'
      and enabled_flag ='Y'
      and sysdate between start_date_active and nvl(end_date_active,sysdate);

  BEGIN
  -- Procedure taxpkg_10_param.printout_fromtaxpkg_10 is renamed from taxpkg_10.printout for defect 27634
    taxpkg_10_param.printout_fromtaxpkg_10(':OD Custom: XX_AR_TWE_UTIL_PKG.is_legacy_batch_source + ');
    for crec in csr_twe_recsrc_lkp
    loop
      if (crec.lookup_code = p_ar_batch_source)
      then
        l_is_legacy_batch_source := 1;
        exit;
      end if;
    end loop;
    taxpkg_10_param.printout_fromtaxpkg_10(':OD Custom: XX_AR_TWE_UTIL_PKG.is_legacy_batch_source - ');
    return l_is_legacy_batch_source;

  EXCEPTION
    WHEN OTHERS THEN
      taxpkg_10_param.printout_fromtaxpkg_10('XX_AR_TWE_UTIL_PKG:(E)-is_legacy_batch_source:' || SQLERRM);
      return 0;
  END is_legacy_batch_source;
--END of adding FUNCTION is_legacy_batch_source for defect 27364
END xx_taxar_bad_debt_report;
/
