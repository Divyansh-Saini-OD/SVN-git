SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET TERM ON

PROMPT Creating PACKAGE Body XX_AR_CREATE_ACCT_PKG
PROMPT Program exits IF the creation is not successful

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE
PACKAGE BODY XX_AR_CREATE_ACCT_PKG AS
ln_msg_cnt NUMBER := 1;

-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : AR AUTO INVOCIE CREATE ACCT                                  |
-- | RICE ID : E0080                                                     |
-- | Description : package to extend the existing Oracle process         |
-- |               of  creating accounting segments based on the         |
-- |               business rules of office depot                        |
-- |                                                                     |
-- |                                                                     |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A 22-JUN-2007    Chetan.K              Initial version        |
-- |                         Wipro Technologies                          |
-- |Draft 1B 31-JUL-2007    Chetan.K              Org Type changed into  |
-- |                         Wipro Technologies   Store% and LOB,CCvalues|
-- |1.0      08-AUG-2007    Chetan.K              Email Address, Customer|
-- |                         Wipro Technologies   Type added             |
-- |1.1      31-AUG-2007    Arul Justin Raj G     Distribution rec delete|
-- |                         Wipro Technologies   and SalesOrder Grouping|
-- |                                              Defect 1543,1555,1718  |
-- |1.2      05-SEP-2007    Raji Natarajan        Sales order Parameter  |
-- |                         Wipro Technologies   and check inclusion    |
-- |                                              Translation usage      |
-- |                                              for trx type           |
-- |1.3      07-SEP-2007    Raji Natarajan        Updation of trx number |
-- |                         Wipro Technologies   with order number      |
-- |                                              and insertion of       |
-- |                                             distribution lines      |
-- |                                             Account lines insertion |
-- |                                             even when data not in   |
-- |                                             custom table            |
-- |1.4      11-SEP-2007     Chetan.K            Added if condition for  |
-- |                                             Defect 1904             |
-- |1.5      11-SEP-07       Raji Natarajan      Replaced the IF condition|
-- |                                             for defect 1904 in proper|
-- |                                             place.                  |
-- |1.6      12-SEP-07       Raji Natarajan      Changed tax line cursor.|
-- |                                             Tax line updation only  |
-- |                                             for PST Accounts.       |
-- |                                             Modified CCID derivation|
-- |                                             Modified dept derivation|
-- |                                             Changed COGS flag to N. |
-- |1.7      13-SEP-07       Raghu               Changed PST query       |
-- |                                             for tax line            |
-- |1.8      18-SEP-07       Raghu               Changed delete and update|
-- |                                             query                   |
-- |1.9      24-SEP-07       Raghu               added line number to    |
-- |                                             coupon query, ra interface|
-- |                                             line update,select query.|
-- |2.0      25-SEP-07       Raghu               added where condition    |
-- |                                             to c_interface_lines     |
-- |                                             cursor.                  |
-- |2.1      26-SEP-07       Prakash             Changed criteria for    |
-- |                                             OE_ORDER_HEADERS_ALL    |
-- |                                             to remove TO_CHAR       |
-- |2.2      26-SEP-07       Raghu               Changed ar_customers_v  |
-- |                                             to hz_cust_accounts_all |
-- |                                             modified 1st delete stmt|
-- |2.3      9-OCT-07        chetan.K            Removed SOB hardcoding  |
-- |2.4      17-OCT-07       Raghu               defect 2426- added      |
-- |                                             consignment field target|
-- |                                             value4 from sales       |
-- |                                             accounting matrix.      |
-- |2.5      23-OCT-07       Raghu                CR#280 defect 2492     |
-- |                                        Remove reference_line_id from|
-- |                                        the interface to prevent     |
-- |                                      standard credit memo processing|
-- |                                        consignment field target     |
-- |                                                                     |
-- |2.6      05-NOV-07       Raghu           Defect 2580: populate       |
-- |                                         description in ra_interface_|
-- |                                         lines_all table for price   |
-- |                                         adjustments.                |
-- |2.7      26-NOV-07       Raghu           removed trx type translation|
-- |                                                                     |
-- |2.8      05-Dec-07       Chetan.K        Defect 2395-CR279 Updating  |
-- |                                         Interface table-Mixed Orders|
-- |                                                                     |
-- |2.9      13-Dec-07       Justin          Change Customer Type Ucase  |
-- |                                         Display the consignment amt |
-- |2.10     21-Dec-07       Raghu          workaround to fix harcode of |
-- |                                         cross val name              |
-- |2.11     26-Dec-07       Afan           Removed the hard codes and   |
-- |                                        added the following translat-|
-- |                                        ion definitions:             |
-- |                                        'OD_AR_INVOICING_DEFAULTS'   |
-- |                                        'GL_E0080_CVR_NAME'          |
-- |                                        'GL_E0080_DEFAULT_CC'        |
-- |2.12     02-Jan-08       Raghu          replaced the CVR derivation  |
-- |                                         query with function for     |
-- |                                         defect 3287.                |
-- |2.13     09-Jan-08       Chetan.K      Addeed parameter p_display_log|
-- |                                         for Defect 3418             |
-- |2.14     11-Jan-08       Chetan.K       Modified the NET AMOUNT query|
-- |                                        for Defect 3479              |
-- |2.15     16-Jan-08       Prakash.S     Modified program to include   |
-- |                         Satish.R      dynamic reference cursors     |
-- |2.16     17-Jan-08       Chetan.K      Tuning of the main cursor and |
-- |                                        fix for the defect 3680      |
-- |2.17     17-Jan-08       Chetan.K      Added parameters for          |
-- |                                       Defect 3679                   |
-- |2.18     17-Jan-08       Chetan.K      Fix for the Defect 3682       |
-- |2.19     22-Jan-08       Prakash.S	   Added one more variation      |
-- |                                       to dynamic cursor             |
-- |2.20     25-Jan-08       Raghu	   Removed batch source name like|
-- |                                       instead checking from         |
-- |                                       the parameterp_inv_source     |
-- |2.21     25-Jan-08       Raghu	   Removed update statement      |
-- |                                       written for error summary --  |
-- |                                       for performance improvement   |
-- |2.22     29-Jan-08     Raghu           Fix for Mixed Order issue     |
-- |2.23     30-Jan-08     Chetan.K        Fix for  CR 3723 to populate  |
-- |                                       order header_id to  DFF on the|
-- |                                       invoice screen at attribute14 |
-- |                                       Tuning query for defect 3944  |
-- |2.24     31-Jan-08     Chetan.K       Added parameter p_error_message|
-- |                                       and added IF condtion for     |
-- |                                        defect 3723                  |
-- |2.25     06-Feb-08     Chetan.K        Fix for the defect 4129 to    |
-- |                                       make average cost NULL        |
-- +=====================================================================+
-- +=====================================================================+
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- | Name : XX_AR_CREATE_ACCT_PROC                                       |
-- +=====================================================================+
-- | Description : proceudure to extend the existing Oracle process      |
-- |               of  creating accounting segments based on the         |
-- |               business rules of office depot                        |
-- |                                                                     |
-- | Parameters : p_run_flag, p_email_address,p_sales_order_low          |
-- |             ,p_sales_order_high,p_display_log,p_invoice_source      |
-- |             ,p_default_date,p_error_message                         |
-- | Returns   : x_error_buff, x_ret_code                                |
-- +=====================================================================+
PROCEDURE  XX_AR_CREATE_ACCT_PROC(
                                   x_err_buff         OUT VARCHAR2
                                  ,x_ret_code         OUT NUMBER
                                  ,p_run_flag         IN  VARCHAR2 DEFAULT 'B'
                                  ,p_email_address    IN  VARCHAR2 DEFAULT NULL
                                  ,p_sales_order_low  IN VARCHAR2
                                  ,p_sales_order_high IN VARCHAR2
                                  ,p_display_log      IN VARCHAR2 DEFAULT 'N'--Defect 3418
                                  ,p_invoice_source   IN VARCHAR2  --Defect 3679
                                  ,p_default_date     IN VARCHAR2  --Defect 3679
                                  ,p_error_message    IN VARCHAR2  DEFAULT 'N' --Defect 3944
  )
  AS
    --Adding the translations for the Batch source and attribute category.
    lc_batch_source_prefix   xx_fin_translatevalues.source_value1%TYPE;
    lc_attribute_category    xx_fin_translatevalues.target_value1%TYPE;

------------------------------------------------------------------------------
          --Fix for Defect 3680 Tuning the Cursor Main Query
------------------------------------------------------------------------------

    /* Change to Incorporate the Logic to Pickup Selective data based on sales
    orders */

-- Record Type Defination based on some columns of the RA_INTERFACE_LINES_ALL table.

    TYPE ra_interface_lines_rec_type IS RECORD (
     ROWID   VARCHAR2(255)
    ,currency_code               ra_interface_lines_all.currency_code%TYPE
    ,cust_trx_type_id            ra_interface_lines_all.cust_trx_type_id%TYPE
    ,sales_order                 ra_interface_lines_all.sales_order%TYPE
    ,inventory_item_id           ra_interface_lines_all.inventory_item_id%TYPE
    ,accounting_rule_id          ra_interface_lines_all.accounting_rule_id%TYPE
    ,batch_source_name           ra_interface_lines_all.batch_source_name%TYPE
    ,warehouse_id                ra_interface_lines_all.warehouse_id%TYPE
    ,sales_order_line            ra_interface_lines_all.sales_order_line%TYPE
    ,interface_line_id           ra_interface_lines_all.interface_line_id%TYPE
    ,interface_line_context      ra_interface_lines_all.interface_line_context%TYPE
    ,interface_line_attribute1   ra_interface_lines_all.interface_line_attribute1%TYPE
    ,interface_line_attribute2   ra_interface_lines_all.interface_line_attribute2%TYPE
    ,interface_line_attribute3   ra_interface_lines_all.interface_line_attribute3%TYPE
    ,interface_line_attribute4   ra_interface_lines_all.interface_line_attribute4%TYPE
    ,interface_line_attribute5   ra_interface_lines_all.interface_line_attribute5%TYPE
    ,interface_line_attribute6   ra_interface_lines_all.interface_line_attribute6%TYPE
    ,interface_line_attribute7   ra_interface_lines_all.interface_line_attribute7%TYPE
    ,interface_line_attribute8   ra_interface_lines_all.interface_line_attribute8%TYPE
    ,interface_line_attribute9   ra_interface_lines_all.interface_line_attribute9%TYPE
    ,interface_line_attribute10  ra_interface_lines_all.interface_line_attribute10%TYPE
    ,interface_line_attribute11  ra_interface_lines_all.interface_line_attribute11%TYPE
    ,interface_line_attribute12  ra_interface_lines_all.interface_line_attribute12%TYPE
    ,interface_line_attribute13  ra_interface_lines_all.interface_line_attribute13%TYPE
    ,interface_line_attribute14  ra_interface_lines_all.interface_line_attribute14%TYPE
    ,interface_line_attribute15  ra_interface_lines_all.interface_line_attribute15%TYPE
    ,orig_system_bill_customer_id    ra_interface_lines_all.orig_system_bill_customer_id%TYPE
    ,amount                          ra_interface_lines_all.amount%TYPE
    ,reference_line_id               ra_interface_lines_all.reference_line_id%TYPE
    ,attribute6                      ra_interface_lines_all.attribute6%TYPE
    ,attribute7                      ra_interface_lines_all.attribute7%TYPE
    ,attribute8                      ra_interface_lines_all.attribute8%TYPE
    ,attribute11                     ra_interface_lines_all.attribute11%TYPE
    ,credit_method_for_acct_rule     ra_interface_lines_all.credit_method_for_acct_rule%TYPE
    ,credit_method_for_installments  ra_interface_lines_all.credit_method_for_installments%TYPE
    ,purchase_order                  ra_interface_lines_all.purchase_order%TYPE
    ,reason_code                     ra_interface_lines_all.reason_code%TYPE
    ,fob_point                       ra_interface_lines_all.fob_point%TYPE
    ,term_id                         ra_interface_lines_all.term_id%TYPE
    ,description                     ra_interface_lines_all.description%TYPE
    ,header_attribute_category       ra_interface_lines_all.header_attribute_category%TYPE
    ,header_attribute1               ra_interface_lines_all.header_attribute1%TYPE
    ,header_attribute2               ra_interface_lines_all.header_attribute2%TYPE
    ,header_attribute3               ra_interface_lines_all.header_attribute3%TYPE
    ,header_attribute4               ra_interface_lines_all.header_attribute4%TYPE
    ,header_attribute5               ra_interface_lines_all.header_attribute5%TYPE
    ,header_attribute6               ra_interface_lines_all.header_attribute6%TYPE
    ,header_attribute7               ra_interface_lines_all.header_attribute7%TYPE
    ,header_attribute8               ra_interface_lines_all.header_attribute8%TYPE
    ,header_attribute9               ra_interface_lines_all.header_attribute9%TYPE
    ,header_attribute10              ra_interface_lines_all.header_attribute10%TYPE
    ,header_attribute11              ra_interface_lines_all.header_attribute11%TYPE
    ,header_attribute12              ra_interface_lines_all.header_attribute12%TYPE
    ,header_attribute13              ra_interface_lines_all.header_attribute13%TYPE
    ,header_attribute14              ra_interface_lines_all.header_attribute14%TYPE
    ,header_attribute15              ra_interface_lines_all.header_attribute15%TYPE
    ,quantity                        ra_interface_lines_all.quantity%TYPE
    ,Payment_set_id                  ra_interface_lines_all.Payment_set_id%TYPE
    ,line_type                       ra_interface_lines_all.line_type%TYPE
      );

     --Variables of the record type ra_interface_lines_rec_type
    lcu_process_interface_lines ra_interface_lines_rec_type;


    -- Long Variable for the SELECT statement to be used in the REF CURSOR.
    lc_cursor_query     VARCHAR2(4000)
        := 'SELECT ROWID'
          ||',currency_code'
          ||',cust_trx_type_id'
          ||',sales_order'
          ||',inventory_item_id'
          ||',accounting_rule_id'
          ||',batch_source_name'
          ||',warehouse_id'
          ||',sales_order_line'
          ||',interface_line_id'
          ||',interface_line_context'
          ||',interface_line_attribute1'
          ||',interface_line_attribute2'
          ||',interface_line_attribute3'
          ||',interface_line_attribute4'
          ||',interface_line_attribute5'
          ||',interface_line_attribute6'
          ||',interface_line_attribute7'
          ||',interface_line_attribute8'
          ||',interface_line_attribute9'
          ||',interface_line_attribute10'
          ||',interface_line_attribute11'
          ||',interface_line_attribute12'
          ||',interface_line_attribute13'
          ||',interface_line_attribute14'
          ||',interface_line_attribute15'
          ||',orig_system_bill_customer_id'
          ||',amount'
          ||',reference_line_id'
          ||',attribute6'
          ||',attribute7'
          ||',attribute8'
          ||',attribute11'
          ||',credit_method_for_acct_rule'
          ||',credit_method_for_installments'
          ||',purchase_order'
          ||',reason_code'
          ||',fob_point'
          ||',term_id'
          ||',description'
          ||',header_attribute_category'
          ||',header_attribute1'
          ||',header_attribute2'
          ||',header_attribute3'
          ||',header_attribute4'
          ||',header_attribute5'
          ||',header_attribute6'
          ||',header_attribute7'
          ||',header_attribute8'
          ||',header_attribute9'
          ||',header_attribute10'
          ||',header_attribute11'
          ||',header_attribute12'
          ||',header_attribute13'
          ||',header_attribute14'
          ||',header_attribute15'
          ||',quantity'
          ||',Payment_set_id'
          ||',line_type'
          ||' FROM ra_interface_lines_all ';

    -- Long Variable declaration to Build the WHERE clause in the REF CURSOR.
     lc_where_clause   VARCHAR2 (500) ;

      -- REF CURSOR Type Defination.
    TYPE t_interface_lines IS REF CURSOR;

      -- Defination of REF CURSOR Type Variable.
    c_interface_lines t_interface_lines;

---------------------------------------------------------------------------------------------------------


    /* Commenting out this is used in refcursor
    --Cursor Declaration for Interface Lines has no Distribution Line
    CURSOR c_interface_lines
    IS
    SELECT ROWID
          ,currency_code
          ,cust_trx_type_id
          ,sales_order
          ,inventory_item_id
          ,accounting_rule_id
          ,batch_source_name
          ,warehouse_id
          ,sales_order_line
          ,interface_line_id
          ,interface_line_context
          ,interface_line_attribute1
          ,interface_line_attribute2
          ,interface_line_attribute3
          ,interface_line_attribute4
          ,interface_line_attribute5
          ,interface_line_attribute6
          ,interface_line_attribute7
          ,interface_line_attribute8
          ,interface_line_attribute9
          ,interface_line_attribute10
          ,interface_line_attribute11
          ,interface_line_attribute12
          ,interface_line_attribute13
          ,interface_line_attribute14
          ,interface_line_attribute15
          ,orig_system_bill_customer_id
          ,amount
          ,reference_line_id
          ,attribute6
          ,attribute7
          ,attribute8
          ,attribute11
          ,credit_method_for_acct_rule
          ,credit_method_for_installments
          ,purchase_order
          ,reason_code
          ,fob_point
          ,term_id
          ,description
          ,header_attribute_category
          ,header_attribute1
          ,header_attribute2
          ,header_attribute3
          ,header_attribute4
          ,header_attribute5
          ,header_attribute6
          ,header_attribute7
          ,header_attribute8
          ,header_attribute9
          ,header_attribute10
          ,header_attribute11
          ,header_attribute12
          ,header_attribute13
          ,header_attribute14
          ,header_attribute15
          ,quantity
          ,Payment_set_id
    FROM  ra_interface_lines_all RIL
    WHERE RIL.batch_source_name LIKE lc_batch_source_prefix||'%'
       AND org_id = FND_PROFILE.VALUE('ORG_ID')
       AND (RIL.interface_status IS NULL
       OR   RIL.interface_status = 'E')
       AND ((p_sales_order_low is not null AND
            sales_order >= p_sales_order_low and sales_order <= p_sales_order_high) OR
            p_sales_order_low is null)
       ORDER BY RIL.currency_code
               ,RIL.sales_order
               ,RIL.sales_order_line;

   */

--Cursor For Tax Lines
    CURSOR c_cust_trx (p_req_id NUMBER
                      ,p_sob_id NUMBER)
    IS
   SELECT RA.customer_trx_id
          ,RAL.customer_trx_line_id
          --,ship_to_customer_id
          ,ship_to_site_use_id
    FROM  apps.ra_customer_trx_all RA
         ,apps.ra_customer_trx_lines_all RAL
         ,apps.RA_CUST_TRX_LINE_GL_DIST_ALL RAD
         ,apps.gl_code_combinations GCC
    WHERE  RA.org_id = FND_PROFILE.VALUE('ORG_ID')
    AND RA.customer_trx_id = RAL.customer_trx_id
    AND RAL.customer_trx_line_id = RAD.customer_trx_line_id
    AND RAL.line_number = 2
    AND RAD.code_combination_id = gcc.code_combination_id
    AND RAD.account_class   = 'TAX'
   /*AND gcc.segment3 in (SELECT target_value1
                         FROM   xx_fin_translatedefinition DEF
                               ,xx_fin_translatevalues VAL
                         WHERE  DEF.translate_id = VAL.translate_id
                         AND    DEF.translation_name = 'XX_AR_PST_ACCOUNT'
                         AND VAL.source_value1 = 'PST')*/
    AND RA.request_id = p_req_id;

   -- Local Variable Declaration
    lc_customer_type         ar_customers_v.attribute18%TYPE;
    lc_trx_type              ra_interface_lines_all.CUST_TRX_TYPE_ID%TYPE;
    ln_oloc                  gl_code_combinations.segment4%TYPE;
    lc_sloc                  gl_code_combinations.segment4%TYPE;
    lc_oloc_type             hr_organization_units.type%TYPE;
    lc_sloc_type             hr_organization_units.type%TYPE;
    lc_source_type_code      oe_order_lines_all.source_type_code%TYPE;
    ls_disc_description      ra_interface_lines_all.description%TYPE;
    lc_item_source           xx_om_line_attributes_all.item_source%TYPE;
    lc_dept                  mtl_item_categories_v.category_concat_segs%TYPE;
    lc_item                  mtl_system_items.segment1%TYPE;
    lc_item_type             mtl_system_items_fvl.item_type%TYPE;
    lc_coupon_code           oe_price_adjustments_v.attribute8%type;
    lc_coupon_owner          oe_price_adjustments_v.attribute9%type;
    lc_avg_cost              xx_om_line_attributes_all.average_cost%type;
    lc_cost_center_dept      xx_om_header_attributes_all.cost_center_dept%TYPE;
    lc_desk_del_addr         xx_om_header_attributes_all.desk_del_addr%TYPE;
    lc_contract_details      xx_om_line_attributes_all.contract_details%TYPE;
    lc_release_num           xx_om_line_attributes_all.release_num%TYPE;
    lc_consignment           xx_om_line_attributes_all.consignment_bank_code%TYPE;
    --lc_legacy_cust_name      xx_om_header_attributes_all.legacy_cust_name%TYPE;
    lc_actual_ship_date      oe_order_lines_all.actual_shipment_date%TYPE;
    ln_order_number          oe_order_headers_all.order_number%TYPE;
    ln_inventory_item_id     oe_order_lines_all.inventory_item_id%TYPE;
    ln_request_id            fnd_concurrent_requests.request_id%TYPE;
    ln_ccid                  ar_vat_tax_all.tax_account_id%TYPE;
    ln_category_strucutre_id mtl_item_categories_v.category_structure_id%TYPE;
    ln_mtl_org_id            mtl_parameters.master_organization_id%TYPE;
    TYPE ril_tbl_type        IS TABLE OF VARCHAR2(100) INDEX BY PLS_INTEGER;
    lt_ril                   ril_tbl_type;
    ln_array                 NUMBER := 1;
    lc_error_flag_val        VARCHAR2(1) := 'N';


    ln_interface_line_id     NUMBER := NULL;
    lc_error_msg             VARCHAR2(4000);
    lc_error_loc             VARCHAR2(2000);
    ln_count                 NUMBER := 0;
    ln_tot_count             NUMBER := 0;
    ln_rec_acct_count        NUMBER := 0;
    ln_rev_acct_count        NUMBER := 0;
    ln_err_count             NUMBER := 0;
    ln_err_order_count       NUMBER := 0;
    ln_req_id                NUMBER;
    ln_sob_id                gl_sets_of_books.set_of_books_id%TYPE;
    lc_prev_sales_order      ra_interface_lines_all.sales_order%TYPE := 0;
    lc_prev_currency         ra_interface_lines_all.currency_code%TYPE := 'N';

    ln_translation_id        xx_fin_translatedefinition.translate_id%TYPE;
    ln_int_amount            NUMBER := 0;
    ln_dummysku_count        NUMBER := 0;
    lc_sob_name              VARCHAR2(240);
    lc_mixed_updated         VARCHAR2(1) := 'N';
    lc_default_date          DATE;
    EX_SALES_ORDER           EXCEPTION;

    -- Local Variable Declaration for translation matrix
    lc_sales_value1    xx_fin_translatevalues.target_value1%TYPE;
    lc_cogs_value2     xx_fin_translatevalues.target_value2%TYPE;
    lc_inv_value3      xx_fin_translatevalues.target_value3%TYPE;
    lc_cons_value4     xx_fin_translatevalues.target_value4%TYPE;
    lc_target_value4   xx_fin_translatevalues.target_value4%TYPE;
    lc_target_value5   xx_fin_translatevalues.target_value5%TYPE;
    lc_target_value6   xx_fin_translatevalues.target_value6%TYPE;
    lc_target_value7   xx_fin_translatevalues.target_value7%TYPE;
    lc_target_value8   xx_fin_translatevalues.target_value8%TYPE;
    lc_target_value9   xx_fin_translatevalues.target_value9%TYPE;
    lc_target_value10  xx_fin_translatevalues.target_value10%TYPE;
    lc_target_value11  xx_fin_translatevalues.target_value11%TYPE;
    lc_target_value12  xx_fin_translatevalues.target_value12%TYPE;
    lc_target_value13  xx_fin_translatevalues.target_value13%TYPE;
    lc_target_value14  xx_fin_translatevalues.target_value14%TYPE;
    lc_target_value15  xx_fin_translatevalues.target_value15%TYPE;
    lc_target_value16  xx_fin_translatevalues.target_value16%TYPE;
    lc_target_value17  xx_fin_translatevalues.target_value17%TYPE;
    lc_target_value18  xx_fin_translatevalues.target_value18%TYPE;
    lc_target_value19  xx_fin_translatevalues.target_value19%TYPE;
    lc_target_value20  xx_fin_translatevalues.target_value20%TYPE;
    lc_trans_error_msg VARCHAR2(4000);

    -- Local Variable Declaration for Segments
    lc_rev_company      gl_code_combinations.segment1%TYPE;
    lc_rev_costcenter   gl_code_combinations.segment1%TYPE;
    lc_rev_account      gl_code_combinations.segment1%TYPE;
    lc_rev_location     gl_code_combinations.segment1%TYPE;
    lc_rev_intercompany gl_code_combinations.segment1%TYPE;
    lc_rev_lob          gl_code_combinations.segment1%TYPE;
    lc_rev_future       gl_code_combinations.segment1%TYPE;
    ln_rev_ccid         NUMBER;

    lc_rec_company      gl_code_combinations.segment1%TYPE;
    lc_rec_costcenter   gl_code_combinations.segment1%TYPE;
    lc_rec_account      gl_code_combinations.segment1%TYPE;
    lc_rec_location     gl_code_combinations.segment1%TYPE;
    lc_rec_intercompany gl_code_combinations.segment1%TYPE;
    lc_rec_lob          gl_code_combinations.segment1%TYPE;
    lc_rec_future       gl_code_combinations.segment1%TYPE;
    ln_rec_ccid         NUMBER;

    lc_tax_company      gl_code_combinations.segment1%TYPE;
    lc_tax_costcenter   gl_code_combinations.segment1%TYPE;
    lc_tax_account      gl_code_combinations.segment1%TYPE;
    lc_tax_location     gl_code_combinations.segment1%TYPE;
    lc_tax_intercompany gl_code_combinations.segment1%TYPE;
    lc_tax_lob          gl_code_combinations.segment1%TYPE;
    lc_tax_future       gl_code_combinations.segment1%TYPE;
    ln_tax_ccid         NUMBER;
    ln_order_header_id  oe_order_headers_all.header_id%TYPE;
    ln_order_line_id    oe_order_lines_all.line_id%TYPE;
    ln_order_net_amount ra_interface_lines_all.amount%TYPE;


  BEGIN

    --Added the query to fetch the translations for the batch source prefix and attribute category

    lc_default_date := fnd_date.canonical_to_date(p_default_date);

    SELECT
          source_value1,
          target_value1
    INTO  lc_batch_source_prefix,
          lc_attribute_category
    FROM  xx_fin_translatevalues XFTV,
          xx_fin_translatedefinition XFTD
    WHERE XFTD.translate_id=XFTV.translate_id
          and XFTD.translation_name='OD_AR_INVOICING_DEFAULTS'
          and XFTD.enabled_flag='Y'
          and XFTV.enabled_flag='Y';

    -- Long Variable to Build the WHERE clause in the REF CURSOR

    lc_where_clause := ' WHERE  '
                      ||'batch_source_name = ''' || p_invoice_source  || ''''
                      ||' AND org_id = FND_PROFILE.VALUE(''ORG_ID'')';

    IF UPPER(SUBSTR(p_run_flag,1,1)) = 'B' THEN

       IF p_sales_order_low IS NOT NULL AND p_sales_order_high IS NOT NULL
         THEN

    -- Added for Defect 1555 to delete the previous run records.
        DELETE FROM RA_INTERFACE_DISTRIBUTIONS_ALL RID
        WHERE  RID.org_id = FND_PROFILE.VALUE('ORG_ID')
        AND RID.interface_line_context ='ORDER ENTRY'
        AND RID.interface_line_attribute1 >= p_sales_order_low
        AND RID.interface_line_attribute1 <= p_sales_order_high;

      /*
        DELETE FROM RA_INTERFACE_DISTRIBUTIONS_ALL RID
        WHERE   RID.interface_line_attribute1
         IN   ( SELECT distinct RID1.interface_line_attribute1
                      FROM ra_interface_distributions_all RID1
                       WHERE RID1.attribute_category = 'SALES_ACCT'
                       AND RID1.org_id = FND_PROFILE.VALUE('ORG_ID')
                       AND RID1.interface_line_attribute1 >= p_sales_order_low
                       AND RID1.interface_line_attribute1 <= p_sales_order_high
                       --AND RID1.ACCOUNT_CLASS='REV'
                       --AND RID1.SEGMENT1='0000'
                       --AND RID1.CODE_COMBINATION_ID IS NULL
               );
      */
        /*FND_FILE.PUT_LINE(FND_FILE.LOG, 'The Number of Accounting Records Deleted by Previous Run : '
                                        || SQL%ROWCOUNT);*/
        COMMIT;
        END IF;

        IF p_sales_order_high IS NULL and p_sales_order_low IS NULL
        THEN

        DELETE FROM RA_INTERFACE_DISTRIBUTIONS_ALL RID
        WHERE   RID.interface_line_attribute1
         IN   ( SELECT distinct RID1.interface_line_attribute1
                      FROM ra_interface_distributions_all RID1
                       WHERE RID1.attribute_category = lc_attribute_category
                       AND RID1.ORG_ID = FND_PROFILE.VALUE('ORG_ID')
                       AND RID1.ACCOUNT_CLASS='REV'
                       AND RID1.SEGMENT1='0000'
                       AND RID1.CODE_COMBINATION_ID IS NULL
               );

        /*FND_FILE.PUT_LINE(FND_FILE.LOG, 'The Number of Accounting Records Deleted by Previous Run : '
                                        || SQL%ROWCOUNT);*/
        COMMIT;
        END IF;

        IF p_sales_order_low IS NULL AND p_sales_order_high IS NULL
         THEN

        UPDATE ra_interface_lines_all
        SET interface_status = NULL
           ,request_id       = NULL
        --WHERE batch_source_name LIKE lc_batch_source_prefix||'%'
        --WHERE batch_source_name = '' || p_invoice_source  || ''''
        WHERE batch_source_name = p_invoice_source
        AND org_id = FND_PROFILE.VALUE('ORG_ID');
        --AND interface_status = 'E';

        COMMIT;

        END IF;

        IF p_sales_order_low IS NOT NULL AND p_sales_order_high IS NOT NULL
         THEN

        UPDATE ra_interface_lines_all ril
        SET ril.interface_status = NULL
           ,ril.request_id       = NULL
        --WHERE RIL.batch_source_name LIKE lc_batch_source_prefix||'%'
        --WHERE RIL.batch_source_name = '' || p_invoice_source  || ''''
        WHERE RIL.batch_source_name = p_invoice_source
        AND RIL.org_id = FND_PROFILE.VALUE('ORG_ID')
        AND RIL.sales_order >= p_sales_order_low
        AND RIL.sales_order <= p_sales_order_high
        ;

        COMMIT;

        END IF;


        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The List of Processed/Unprocessed Order Transaction Lines');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'---------------------------------------------------------');


---------------------------------------------------------------------------
          --Fix for Defect 3680 Tuning the Cursor Main Query
---------------------------------------------------------------------------

BEGIN

    -- 2.19 Prakash Sankaran - added this variation below if high and low values are equal for sales order
    IF p_sales_order_low IS NOT NULL AND p_sales_order_high is NOT NULL AND p_sales_order_low = p_sales_order_high THEN
        OPEN c_interface_lines FOR
                lc_cursor_query || ' ' || lc_where_clause
                 ||' AND (interface_status IS NULL '
                 ||' OR   interface_status = ''E'')'
                 ||' AND  sales_order = ''' || p_sales_order_low || ''''
                 ||' ORDER BY currency_code '
                 ||',sales_order '
                 ||',sales_order_line ';

    ELSIF p_sales_order_low IS NOT NULL AND p_sales_order_high IS NOT NULL THEN
        OPEN c_interface_lines FOR
                lc_cursor_query || ' ' || lc_where_clause
                 ||' AND (interface_status IS NULL '
                 ||' OR   interface_status = ''E'')'
                 ||' AND  sales_order >= '''|| p_sales_order_low  || ''''
                 ||' AND  sales_order <= '''|| p_sales_order_high || ''''
                 ||'  ORDER BY currency_code '
                 ||',sales_order '
                 ||',sales_order_line ';

    ELSIF p_sales_order_low IS NOT NULL AND p_sales_order_high IS NULL THEN

-- If above condition is satisfied then EX_SALES_ORDER user defined exception is raised and make the requestset error out

     RAISE EX_SALES_ORDER;

    ELSIF p_sales_order_low IS NULL AND p_sales_order_high IS NOT NULL THEN

-- If above condition is satisfied then EX_SALES_ORDER user defined exception is raised and make the requestset error out

    RAISE EX_SALES_ORDER;

    ELSIF p_sales_order_low IS NULL AND p_sales_order_high IS NULL THEN
       OPEN   c_interface_lines FOR
                lc_cursor_query || ' ' || lc_where_clause
               ||' AND (interface_status IS NULL'
               ||' OR   interface_status = ''E'')'
               ||' ORDER BY currency_code '
               ||',sales_order '
               ||',sales_order_line';
    END IF;

    END;
-------------------------------------------------------------------------------------------------



/*    FOR lcu_process_interface_lines IN c_interface_lines*/
    LOOP
      FETCH c_interface_lines into lcu_process_interface_lines;
      EXIT WHEN c_interface_lines%NOTFOUND;
        lc_rev_account := NULL;
        lc_rev_company := NULL;
        ln_oloc        := NULL;
        lc_oloc_type   := NULL;
        lc_sloc        := NULL;
        lc_sloc_type   := NULL;
        ln_rev_ccid    := NULL;
        ln_rec_ccid    := NULL;
        lc_rev_company := NULL;
        lc_rec_company := NULL;
        lc_tax_company := NULL;
        lc_coupon_code := NULL;
        lc_coupon_owner := NULL;
        ln_dummysku_count := 0;
        lc_trx_type := lcu_process_interface_lines.cust_trx_type_id;

      IF (lcu_process_interface_lines.sales_order
           between p_sales_order_low and p_sales_order_high)
         OR (p_sales_order_high IS NULL and p_sales_order_low IS NULL)
    THEN

        -------------------------------------------------------------------
      -- Fix for Defect 2395 - CR 279
      -- for Mixed Orders updating the Interface lines table
        -------------------------------------------------------------------

        IF lcu_process_interface_lines.sales_order <> lc_prev_sales_order THEN
             lc_mixed_updated := 'N';
        END IF;

        IF lc_mixed_updated = 'N' THEN

           BEGIN
              SELECT OOHA.header_id
              INTO   ln_order_header_id
              FROM   oe_order_headers_all OOHA
              WHERE  OOHA.order_number = lcu_process_interface_lines.sales_order;

           --Due to manual numbering of invoices, inv number updated with sales order.
              UPDATE ra_interface_lines_all RIL
              SET    RIL.trx_number  = lcu_process_interface_lines.sales_order
              WHERE  sales_order     = lcu_process_interface_lines.sales_order
             --AND   inventory_item_id = lcu_process_interface_lines.inventory_item_id
              AND    RIL.interface_line_context = 'ORDER ENTRY'
              AND    RIL.org_id                 = FND_PROFILE.VALUE('ORG_ID') ;

           EXCEPTION
           WHEN NO_DATA_FOUND THEN
           FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
           FND_MESSAGE.SET_TOKEN('COL','Header_id : '||ln_order_header_id ||'For Sales order : '
                                  ||lcu_process_interface_lines.sales_order);
           lc_error_msg := FND_MESSAGE.GET;
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg);
           XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                           p_program_type            => 'CONCURRENT PROGRAM'
                                          ,p_program_name            => 'OD: AR Create Autoinvoice Accounting'
                                          ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                          ,p_module_name             => 'AR'
                                          ,p_error_location          => 'Oracle Error '||SQLERRM
                                          ,p_error_message_count     => ln_msg_cnt
                                          ,p_error_message_code      => 'E'
                                          ,p_error_message           => lc_error_msg
                                          ,p_error_message_severity  => 'Major'
                                          ,p_notify_flag             => 'N'
                                          ,p_object_type             => 'Creating Accounts'
           );
           WHEN OTHERS THEN
           FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
           FND_MESSAGE.SET_TOKEN('COL','Header_id : '||ln_order_header_id ||' for Sales order : '
                                 ||lcu_process_interface_lines.sales_order);
           lc_error_msg := FND_MESSAGE.GET || SQLERRM;
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg);
           XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                           p_program_type             => 'CONCURRENT PROGRAM'
                                          ,p_program_name            => 'OD: AR Create Autoinvoice Accounting'
                                          ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                          ,p_module_name             => 'AR'
                                          ,p_error_location          => 'Oracle Error '||SQLERRM
                                          ,p_error_message_count     => ln_msg_cnt + 1
                                          ,p_error_message_code      => 'E'
                                          ,p_error_message           => lc_error_msg
                                          ,p_error_message_severity  => 'Major'
                                          ,p_notify_flag             => 'N'
                                          ,p_object_type             => 'Creating Accounts'
           );

           END;

           BEGIN
           -- Checking the Order Line id is a MIXED ORDER or not

             SELECT COUNT(OLA.line_id)
             INTO   ln_order_line_id
             FROM   oe_order_lines_all OLA
             WHERE  OLA.header_id = ln_order_header_id
             AND    UPPER(OLA.line_category_code) = 'RETURN'
             AND    EXISTS (SELECT OLA1.line_id
                            FROM   oe_order_lines_all OLA1
                            WHERE  OLA.header_id = OLA1.header_id
                            AND    OLA.line_id   <> OLA1.line_id
                            AND    UPPER(OLA1.line_category_code) = 'ORDER');

           EXCEPTION
           WHEN OTHERS THEN
           FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
           FND_MESSAGE.SET_TOKEN('COL','line_id : '||ln_order_line_id ||'For Sales order : '||
                                 lcu_process_interface_lines.sales_order);
           lc_error_msg := FND_MESSAGE.GET || SQLERRM;
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg);
           XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                           p_program_type             => 'CONCURRENT PROGRAM'
                                          ,p_program_name            => 'OD: AR Create Autoinvoice Accounting'
                                          ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                          ,p_module_name             => 'AR'
                                          ,p_error_location          => 'Oracle Error '||SQLERRM
                                          ,p_error_message_count     => ln_msg_cnt + 1
                                          ,p_error_message_code      => 'E'
                                          ,p_error_message           => lc_error_msg
                                          ,p_error_message_severity  => 'Major'
                                          ,p_notify_flag             => 'N'
                                          ,p_object_type             => 'Creating Accounts'
           );
            END;
            IF (p_display_log ='Y' ) THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG, '---------------------------------------');
            FND_FILE.PUT_LINE (FND_FILE.LOG,  ' Number of Mixed Order Lines : ' || ln_order_line_id);
            END IF;

            IF (ln_order_line_id > 0  AND lc_mixed_updated = 'N') THEN

               -- Taking the net amount of a sales_order
              BEGIN

                /*SELECT SUM(amount)
                INTO   ln_order_net_amount
                FROM   ra_interface_lines_all RIL
                WHERE  sales_order = lcu_process_interface_lines.sales_order
                AND    batch_source_name LIKE lc_batch_source_prefix||'%'
                AND    org_id      = FND_PROFILE.VALUE('ORG_ID') ;*/

                -- Modified the above query for Defect 3479

                  SELECT SUM((NVL(invoiced_quantity,1) * NVL(unit_selling_price,0))
                           +  (SIGN(invoiced_quantity) * NVL(tax_value,0)))
                  INTO   ln_order_net_amount
                  FROM   oe_order_lines_all
                  WHERE  header_id = ln_order_header_id;

                IF (p_display_log )='Y' THEN
                FND_FILE.PUT_LINE (FND_FILE.LOG, ' Sales Order Net amount : ' || ln_order_net_amount);
                END IF;

            -- Checking  the condition if net amount is positive

              IF (ln_order_net_amount >= 0) THEN

               -- To get the first Invoice(Positive) line
              IF (lcu_process_interface_lines.quantity >= 0) THEN

                 IF (p_display_log ='Y') THEN
                 FND_FILE.PUT_LINE (FND_FILE.LOG, ' Transaction Type : Invoice ' );
                 FND_FILE.PUT_LINE (FND_FILE.LOG, ' Sales Order Net amount is POSITIVE : '
                                    || ln_order_net_amount);
                 FND_FILE.PUT_LINE (FND_FILE.LOG, '---------------------------------------');
                 END IF;


                 UPDATE ra_interface_lines_all
                 SET credit_method_for_acct_rule = lcu_process_interface_lines.credit_method_for_acct_rule
                    ,credit_method_for_installments = lcu_process_interface_lines.credit_method_for_installments
                    ,purchase_order = lcu_process_interface_lines.purchase_order
                    ,reason_code = lcu_process_interface_lines.reason_code
                    ,fob_point = lcu_process_interface_lines.fob_point
                    ,term_id = lcu_process_interface_lines.term_id
                    ,cust_trx_type_id = lcu_process_interface_lines.cust_trx_type_id
                    ,header_attribute_category = lcu_process_interface_lines.header_attribute_category
                    ,header_attribute1 = lcu_process_interface_lines.header_attribute1
                    ,header_attribute2 = lcu_process_interface_lines.header_attribute2
                    ,header_attribute3 = lcu_process_interface_lines.header_attribute3
                    ,header_attribute4 = lcu_process_interface_lines.header_attribute4
                    ,header_attribute5 = lcu_process_interface_lines.header_attribute5
                    ,header_attribute6 = lcu_process_interface_lines.header_attribute6
                    ,header_attribute7 = lcu_process_interface_lines.header_attribute7
                    ,header_attribute8 = lcu_process_interface_lines.header_attribute8
                    ,header_attribute9 = lcu_process_interface_lines.header_attribute9
                    ,header_attribute10 = lcu_process_interface_lines.header_attribute10
                    ,header_attribute11 = lcu_process_interface_lines.header_attribute11
                    ,header_attribute12 = lcu_process_interface_lines.header_attribute12
                    ,header_attribute13 = lcu_process_interface_lines.header_attribute13
                    ,header_attribute14 = lcu_process_interface_lines.header_attribute14
                    ,header_attribute15 = lcu_process_interface_lines.header_attribute15
                    ,attribute6 = lcu_process_interface_lines.attribute6
                    ,attribute7 = lcu_process_interface_lines.attribute7
                    ,attribute11 = lcu_process_interface_lines.attribute11
                    ,interface_line_attribute3 = lcu_process_interface_lines.interface_line_attribute3
                    ,interface_line_attribute10 = lcu_process_interface_lines.interface_line_attribute10
                    ,Payment_set_id = lcu_process_interface_lines.Payment_set_id
              WHERE  sales_order = lcu_process_interface_lines.sales_order
              --AND    batch_source_name LIKE lc_batch_source_prefix||'%'
              --AND batch_source_name = '' || p_invoice_source  || ''''
              AND batch_source_name = p_invoice_source
              --AND  amount < 0
              AND    quantity < 0   --Fix for the Defect 3682
              AND    org_id = FND_PROFILE.VALUE('ORG_ID');

                   lc_mixed_updated :='Y';

              END IF;

            -- Checking  the condition if net amount is negative

              ELSIF (ln_order_net_amount < 0) THEN
                    -- To get the first Credit Memo line
                  IF (lcu_process_interface_lines.quantity  < 0) THEN

                   IF (p_display_log ='Y') THEN
                   FND_FILE.PUT_LINE (FND_FILE.LOG, ' Transaction Type : Credit Memo ' );
                   FND_FILE.PUT_LINE (FND_FILE.LOG,  ' Sales Order Net amount is NEGATIVE : '
                                      || ln_order_net_amount);
                   FND_FILE.PUT_LINE (FND_FILE.LOG, '---------------------------------------');
                   END IF;

                      UPDATE ra_interface_lines_all
                      SET credit_method_for_acct_rule = lcu_process_interface_lines.credit_method_for_acct_rule
                         ,credit_method_for_installments = lcu_process_interface_lines.credit_method_for_installments
                         ,purchase_order = lcu_process_interface_lines.purchase_order
                         ,reason_code = lcu_process_interface_lines.reason_code
                         ,fob_point = lcu_process_interface_lines.fob_point
                         ,term_id = lcu_process_interface_lines.term_id
                         ,cust_trx_type_id = lcu_process_interface_lines.cust_trx_type_id
                         ,header_attribute_category = lcu_process_interface_lines.header_attribute_category
                         ,header_attribute1 = lcu_process_interface_lines.header_attribute1
                         ,header_attribute2 = lcu_process_interface_lines.header_attribute2
                         ,header_attribute3 = lcu_process_interface_lines.header_attribute3
                         ,header_attribute4 = lcu_process_interface_lines.header_attribute4
                         ,header_attribute5 = lcu_process_interface_lines.header_attribute5
                         ,header_attribute6 = lcu_process_interface_lines.header_attribute6
                         ,header_attribute7 = lcu_process_interface_lines.header_attribute7
                         ,header_attribute8 = lcu_process_interface_lines.header_attribute8
                         ,header_attribute9 = lcu_process_interface_lines.header_attribute9
                         ,header_attribute10 = lcu_process_interface_lines.header_attribute10
                         ,header_attribute11 = lcu_process_interface_lines.header_attribute11
                         ,header_attribute12 = lcu_process_interface_lines.header_attribute12
                         ,header_attribute13 = lcu_process_interface_lines.header_attribute13
                         ,header_attribute14 = lcu_process_interface_lines.header_attribute14
                         ,header_attribute15 = lcu_process_interface_lines.header_attribute15
                         ,attribute6 = lcu_process_interface_lines.attribute6
                         ,attribute7 = lcu_process_interface_lines.attribute7
                         ,attribute11 = lcu_process_interface_lines.attribute11
                         ,interface_line_attribute3 = lcu_process_interface_lines.interface_line_attribute3
                         ,interface_line_attribute10 = lcu_process_interface_lines.interface_line_attribute10
                         ,Payment_set_id = lcu_process_interface_lines.Payment_set_id
                       WHERE sales_order = lcu_process_interface_lines.sales_order
                       --AND   batch_source_name LIKE lc_batch_source_prefix||'%'
                       --AND   batch_source_name = '' || p_invoice_source  || ''''
                       AND   batch_source_name = p_invoice_source  
                       --AND   amount >= 0
                       AND   quantity >= 0  --Fix for the Defect 3682
                       AND   org_id = FND_PROFILE.VALUE('ORG_ID');
                       lc_mixed_updated :='Y';
                  END IF;
              END IF;  --Checking the net amount
              EXCEPTION
           WHEN OTHERS THEN
           FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
           FND_MESSAGE.SET_TOKEN('COL',' Updating Mixed Order for the Sales order : '||
                                 lcu_process_interface_lines.sales_order);
           lc_error_msg := FND_MESSAGE.GET || SQLERRM;
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg);
           XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                           p_program_type             => 'CONCURRENT PROGRAM'
                                          ,p_program_name            => 'OD: AR Create Autoinvoice Accounting'
                                          ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                          ,p_module_name             => 'AR'
                                          ,p_error_location          => 'Oracle Error '||SQLERRM
                                          ,p_error_message_count     => ln_msg_cnt + 1
                                          ,p_error_message_code      => 'E'
                                          ,p_error_message           => lc_error_msg
                                          ,p_error_message_severity  => 'Major'
                                          ,p_notify_flag             => 'N'
                                          ,p_object_type             => 'Creating Accounts'
           );
         END;
        ELSE
               --For Non Mixed Orders
               lc_mixed_updated :='Y';
        END IF;  -- For checking the sales order is a mixed order
     END IF;
     -- End of the fix for Defect 2395
     ------------------------------------------

    --To Get CUSTOMER TYPE
    BEGIN
    /*
    SELECT AC.attribute18
    INTO   lc_customer_type
    FROM   ar_customers_v AC
    WHERE  AC.customer_id = lcu_process_interface_lines.orig_system_bill_customer_id;
    */

    SELECT AC.attribute18
    INTO   lc_customer_type
    FROM   hz_cust_accounts_all AC
    WHERE  AC.cust_account_id = lcu_process_interface_lines.orig_system_bill_customer_id;

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
      FND_MESSAGE.SET_TOKEN('COL','Customer type for sales order :'||lcu_process_interface_lines.sales_order);
      lc_error_msg := FND_MESSAGE.GET;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg);
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'OD: AR Create Autoinvoice Accounting'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => ln_msg_cnt
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts'
      );
    WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
      FND_MESSAGE.SET_TOKEN('COL','Customer type for sales order :'||lcu_process_interface_lines.sales_order);
      lc_error_msg := FND_MESSAGE.GET;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg);
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type             => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'OD: AR Create Autoinvoice Accounting'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => ln_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts'
      );
    END;

    --To Get Order Location
    --Order Location is not Mandatory
    BEGIN
/*
    SELECT SUBSTR(HU.location_code,1,6)
           ,HU.organization_type
    INTO   ln_oloc
           ,lc_oloc_type
    FROM   xx_om_header_attributes_all OHAL
           ,oe_order_headers_all OHA
           ,hr_organization_units_v HU
    WHERE  TO_CHAR(OHA.order_number) = lcu_process_interface_lines.sales_order
      AND  OHA.header_id = OHAL.header_id
      AND  OHAL.created_by_store_id = HU.organization_id
      AND  OHA.org_id = FND_PROFILE.VALUE('ORG_ID');
*/
-----------
     SELECT   SUBSTR (hla.location_code,1,6)   "LOCATION_CODE",
              hl.meaning                     "ORGANIZATION_TYPE"
      INTO    ln_oloc
             ,lc_oloc_type
      FROM   hr_lookups HL,
             hr_locations_all HLA,
             hr_all_organization_units HAOU,
             xx_om_header_attributes_all OHAL,
             oe_order_headers_all OOHA
      WHERE HAOU.type = HL.lookup_code
       AND HAOU.location_id = HLA.location_id
       AND HAOU.organization_id   = OHAL.created_by_store_id
       AND OHAL.header_id         = OOHA.header_id
       AND HL.lookup_type         = 'ORG_TYPE'
       AND HL.enabled_flag        = 'Y'
       AND OOHA.order_number      = lcu_process_interface_lines.sales_order; --order_number


    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
      FND_MESSAGE.SET_TOKEN('COL','Order Location for sales order:'||lcu_process_interface_lines.sales_order ||'and inventory item ID:'||lcu_process_interface_lines.inventory_item_id);
      FND_MESSAGE.SET_TOKEN('COL','Order Location Type for sales order:'||lcu_process_interface_lines.sales_order ||'and inventory item ID:'||lcu_process_interface_lines.inventory_item_id);
      lc_error_msg := FND_MESSAGE.GET;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'OD: AR Create Autoinvoice Accounting'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => ln_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts'
      );
    WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
      FND_MESSAGE.SET_TOKEN('COL','Order Location for sales order:'||lcu_process_interface_lines.sales_order);
      lc_error_msg := FND_MESSAGE.GET;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => ln_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts'
      );
    END;

    --To Get Shipping Location

    BEGIN
      /*
    SELECT DISTINCT SUBSTR(HU.location_code,1,6)
           ,HU.organization_type
    INTO   lc_sloc
           ,lc_sloc_type
    FROM   oe_order_headers_all OHA
           ,oe_order_lines_all OLA
           ,hr_organization_units_v HU
    WHERE  TO_CHAR(OHA.order_number) = lcu_process_interface_lines.sales_order
      AND  lcu_process_interface_lines.inventory_item_id = OLA.inventory_item_id
      AND  OLA.ship_from_org_id = HU.organization_id
      AND  OHA.header_id = OLA.header_id
      AND  OHA.org_id = FND_PROFILE.VALUE('ORG_ID');

*/
      ----
       SELECT SUBSTR (hla.location_code,1,6)   "LOCATION_CODE",
              hl.meaning                       "ORGANIZATION_TYPE"
      INTO    lc_sloc
             ,lc_sloc_type
      FROM   hr_lookups HL,
             hr_locations_all HLA,
             hr_all_organization_units HAOU,
             oe_order_headers_all OOHA,
             oe_order_lines_all OOLA
      WHERE HAOU.type = HL.lookup_code
       AND HAOU.location_id = HLA.location_id
       AND HAOU.organization_id    = OOLA.ship_from_org_id
       AND OOHA.header_id         = OOLA.header_id
       AND HL.lookup_type         = 'ORG_TYPE'
       AND HL.enabled_flag        = 'Y'
       AND OOHA.order_number      = lcu_process_interface_lines.sales_order --order_number
       AND OOLA.inventory_item_id = lcu_process_interface_lines.inventory_item_id --item_id
       AND OOLA.line_number       = lcu_process_interface_lines.sales_order_line;


    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
      FND_MESSAGE.SET_TOKEN('COL','Shipping Location for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
      FND_MESSAGE.SET_TOKEN('COL','Shipping Location Type for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
      lc_error_msg := FND_MESSAGE.GET;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => ln_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts'
      );
    WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
      FND_MESSAGE.SET_TOKEN('COL','Shipping Location for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
      FND_MESSAGE.SET_TOKEN('COL','Shipping Location Typefor sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
      lc_error_msg := FND_MESSAGE.GET;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => ln_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts'
      );
    END;

    --Source Type validation
    BEGIN
    SELECT OLA.source_type_code
    INTO   lc_source_type_code
    FROM   oe_order_headers_all OHA,
           oe_order_lines_all OLA
    WHERE OHA.order_number = lcu_process_interface_lines.sales_order
      AND   OHA.header_id = OLA.header_id
      AND   OLA.inventory_item_id = lcu_process_interface_lines.inventory_item_id;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
      FND_MESSAGE.SET_TOKEN('COL','Source Type for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
      lc_error_msg :=  FND_MESSAGE.GET;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => ln_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts'
      );
    WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
      FND_MESSAGE.SET_TOKEN('COL','Source Type for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
      lc_error_msg := FND_MESSAGE.GET;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => ln_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts'
       );
    END;

    --Item Source Validation
    IF lcu_process_interface_lines.interface_line_attribute11 = '0' THEN

    --FND_FILE.PUT_LINE(FND_FILE.LOG,'attribute11a --  : '||lcu_process_interface_lines.interface_line_attribute11);
      BEGIN
      SELECT OOL.item_source
            ,OOL.consignment_bank_code
      INTO   lc_item_source
            ,lc_consignment
      FROM   xx_om_line_attributes_all OOL
            ,oe_order_headers_all OHA
            ,oe_order_lines_all OLA
     WHERE   OHA.order_number = lcu_process_interface_lines.sales_order
       AND   OHA.header_id = OLA.header_id
       AND   OLA.line_id = OOL.line_id
       AND   OLA.inventory_item_id = lcu_process_interface_lines.inventory_item_id;

    --FND_FILE.PUT_LINE(FND_FILE.LOG,'Item Source-1          : '||lc_item_source);
        --Defect 1904
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
       FND_MESSAGE.SET_TOKEN('COL','Item Source for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
       lc_error_msg := FND_MESSAGE.GET;
       XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                       p_program_type            => 'CONCURRENT PROGRAM'
                                      ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                      ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                      ,p_module_name             => 'AR'
                                      ,p_error_location          => 'Oracle Error '||SQLERRM
                                      ,p_error_message_count     => ln_msg_cnt + 1
                                      ,p_error_message_code      => 'E'
                                      ,p_error_message           => lc_error_msg
                                      ,p_error_message_severity  => 'Major'
                                      ,p_notify_flag             => 'N'
                                      ,p_object_type             => 'Creating Accounts'
       );
     WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
       FND_MESSAGE.SET_TOKEN('COL','Item Source for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
       lc_error_msg := FND_MESSAGE.GET;
       XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                       p_program_type            => 'CONCURRENT PROGRAM'
                                      ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                      ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                      ,p_module_name             => 'AR'
                                      ,p_error_location          => 'Oracle Error '||SQLERRM
                                      ,p_error_message_count     => ln_msg_cnt + 1
                                      ,p_error_message_code      => 'E'
                                      ,p_error_message           => lc_error_msg
                                      ,p_error_message_severity  => 'Major'
                                      ,p_notify_flag             => 'N'
                                      ,p_object_type             => 'Creating Accounts'
       );
     END;
    BEGIN
       IF lc_item_source ='00' OR lc_item_source = 'OD' THEN
          lc_item_source:=NULL;
          --FND_FILE.PUT_LINE(FND_FILE.LOG,'Item Source-2          : '||lc_item_source);
       ELSIF lc_item_source IS NULL THEN

           SELECT COUNT(*)
           INTO  ln_dummysku_count
           FROM fnd_lookup_values
           WHERE lookup_type='OD_FEES_ITEMS'
           AND ATTRIBUTE6 = lcu_process_interface_lines.inventory_item_id;

       IF  ln_dummysku_count >=1 THEN
           SELECT DISTINCT SEGMENT1
           INTO  lc_item_source
           FROM  apps.mtl_system_items_b
           WHERE inventory_item_id = lcu_process_interface_lines.inventory_item_id;
       END IF;
       /*IF (p_display_log='Y') THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Item Source-3         : '||lc_item_source);
       END IF;*/
       END IF;

    END;
    ELSE

        -- To avoid too much info in Log file, Below line commented
        --FND_FILE.PUT_LINE(FND_FILE.LOG,'ITEM SOURCE is not derived.');
    --COUPON AND OWNER
      BEGIN

      SELECT OPA.ATTRIBUTE8,OPA.ATTRIBUTE9
      INTO   lc_coupon_code,lc_coupon_owner
      FROM   OE_PRICE_ADJUSTMENTS_V OPA
            ,OE_ORDER_HEADERS_ALL OHA
            ,OE_ORDER_LINES_ALL OLA
      WHERE  lcu_process_interface_lines.sales_order = OHA.order_number
        AND  OHA.HEADER_ID = OPA.header_id
        AND  OHA.HEADER_ID = OLA.header_id
        AND  OLA.inventory_item_id = lcu_process_interface_lines.inventory_item_id
        AND  OLA.line_number       = lcu_process_interface_lines.sales_order_line
        AND  OPA.price_adjustment_id = lcu_process_interface_lines.interface_line_attribute11
        AND  OPA.automatic_flag='N';

        IF lc_coupon_owner IS NOT NULL THEN
           lc_item_source := lc_coupon_code||'-'||lc_coupon_owner;
        ELSE
           lc_item_source := lc_coupon_code;
        END IF;
        /*IF (p_display_log='Y') THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Item Source--4          : '||lc_item_source);
        END IF;*/

        -- To avoid too much info in Log file, Below line commented
        --FND_FILE.PUT_LINE(FND_FILE.LOG,'ITEM SOURCE is derived for coupon '||' '||lc_item_source);
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
        FND_MESSAGE.SET_TOKEN('COL','Coupon for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
        FND_MESSAGE.SET_TOKEN('COL','Owner for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
        lc_error_msg := FND_MESSAGE.GET;
        XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                        p_program_type            => 'CONCURRENT PROGRAM'
                                       ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                       ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                       ,p_module_name             => 'AR'
                                       ,p_error_location          => 'Oracle Error '||SQLERRM
                                       ,p_error_message_count     => ln_msg_cnt + 1
                                       ,p_error_message_code      => 'E'
                                       ,p_error_message           => lc_error_msg
                                       ,p_error_message_severity  => 'Major'
                                       ,p_notify_flag             => 'N'
                                       ,p_object_type             => 'Creating Accounts'
        );
      WHEN OTHERS THEN
        FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
        FND_MESSAGE.SET_TOKEN('COL','Coupon for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
        FND_MESSAGE.SET_TOKEN('COL','Owner for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
        lc_error_msg := FND_MESSAGE.GET;
        XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                         p_program_type            => 'CONCURRENT PROGRAM'
                                        ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                        ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                        ,p_module_name             => 'AR'
                                        ,p_error_location          => 'Oracle Error '||SQLERRM
                                        ,p_error_message_count     => ln_msg_cnt + 1
                                        ,p_error_message_code      => 'E'
                                        ,p_error_message           => lc_error_msg
                                        ,p_error_message_severity  => 'Major'
                                        ,p_notify_flag             => 'N'
                                        ,p_object_type             => 'Creating Accounts'
        );
      END;
    END IF;

    --To Get Item
    BEGIN
    SELECT MSI.segment1
    INTO   lc_item
    FROM   mtl_system_items MSI
    WHERE  MSI.inventory_item_id = lcu_process_interface_lines.inventory_item_id
      AND  organization_id IN (
                               SELECT  DISTINCT master_organization_id
                               FROM mtl_parameters
                              );

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
      FND_MESSAGE.SET_TOKEN('COL','Item for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
      lc_error_msg := FND_MESSAGE.GET;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => ln_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts'
      );
    WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
      FND_MESSAGE.SET_TOKEN('COL','Item for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
      lc_error_msg := FND_MESSAGE.GET;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => ln_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts'
      );
    END;

    --To Get Department
    BEGIN
    SELECT --MIC.category_structure_id
           MIC.segment3
         -- ,MIC.organization_id
    INTO   --ln_category_strucutre_id
          lc_dept
          --,ln_mtl_org_id
    FROM   mtl_item_categories_v MIC
    WHERE  MIC.inventory_item_id = lcu_process_interface_lines.inventory_item_id
      AND  MIC.organization_id IN (
                                   SELECT  distinct master_organization_id
                                   FROM mtl_parameters
                                  )
      AND  MIC.category_set_name IN ('Inventory');--,'PO CATEGORY');

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
      FND_MESSAGE.SET_TOKEN('COL','Department for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
      lc_error_msg := FND_MESSAGE.GET;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => ln_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts'
      );
    WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
      FND_MESSAGE.SET_TOKEN('COL','Department for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
      lc_error_msg := FND_MESSAGE.GET;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => ln_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts'
      );
    END;
     --ITEM TYPE Validation
    BEGIN
    SELECT MSIF.item_type
    INTO   lc_item_type
    FROM   MTL_SYSTEM_ITEMS_FVL MSIF
    WHERE  MSIF.inventory_item_id = lcu_process_interface_lines.inventory_item_id
      AND   MSIF.organization_id IN (
                                     SELECT distinct master_organization_id
                                     FROM mtl_parameters
                                     );
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
      FND_MESSAGE.SET_TOKEN('COL','Item Type for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
      lc_error_msg := FND_MESSAGE.GET;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => ln_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts'
      );
    WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
      FND_MESSAGE.SET_TOKEN('COL','Item Type for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
      lc_error_msg := FND_MESSAGE.GET;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => ln_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts'
      );
    END;
     --Average Item Cost
    BEGIN
    SELECT OOL.average_cost
    INTO   lc_avg_cost
    FROM   xx_om_line_attributes_all OOL
           ,oe_order_lines_all OLA
           ,oe_order_headers_all OHA
    WHERE  OLA.line_id = OOL.line_id
      AND  OLA.header_id = OHA.header_id
      AND  OHA.order_number = lcu_process_interface_lines.sales_order
      AND  OLA.inventory_item_id = lcu_process_interface_lines.inventory_item_id
      AND  OLA.ship_from_org_id = lcu_process_interface_lines.warehouse_id;

     -- Fix for the defect 4129 to make average cost NULL
      IF  (lcu_process_interface_lines.interface_line_attribute11 <>0 ) THEN
          lc_avg_cost := NULL;
      END IF;

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
      FND_MESSAGE.SET_TOKEN('COL','Item Average Cost for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
      lc_error_msg := FND_MESSAGE.GET;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => ln_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts'
      );
    WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
      FND_MESSAGE.SET_TOKEN('COL','Item Average Cost for sales order:'||lcu_process_interface_lines.sales_order || 'and inverntory item ID:'||lcu_process_interface_lines.inventory_item_id);
      lc_error_msg := FND_MESSAGE.GET;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                      ,p_error_message_count     => ln_msg_cnt + 1
                                      ,p_error_message_code      => 'E'
                                      ,p_error_message           => lc_error_msg
                                      ,p_error_message_severity  => 'Major'
                                      ,p_notify_flag             => 'N'
                                      ,p_object_type             => 'Creating Accounts'
      );
    END;
    --Geting The Sales Account From Translation
    BEGIN
    SELECT translate_id
    INTO   ln_translation_id
    FROM   xx_fin_translatedefinition
    WHERE  translation_name = 'SALES ACCOUNTING MATRIX'
      AND  enabled_flag = 'Y'
      AND  (start_date_active <= SYSDATE
      AND  (end_date_active >= SYSDATE OR end_date_active IS NULL));

      --Getting Sales Account For ITEM_SOURCE And DEPT Combination
       IF lc_item_source IS NOT NULL AND lc_dept IS NOT  NULL THEN
         BEGIN
         SELECT target_value1
               ,target_value2
               ,target_value3
               ,target_value4
         INTO   lc_rev_account
               ,lc_cogs_value2
               ,lc_inv_value3
               ,lc_cons_value4
         FROM   xx_fin_translatevalues
         WHERE  translate_id = ln_translation_id
           AND  (source_value1 = lc_item_source)
           AND  (source_value2 IS NULL)
           AND  (source_value3 = lc_dept)
           AND  enabled_flag   = 'Y'
           AND  (start_date_active <= SYSDATE
           AND  (end_date_active >= SYSDATE OR end_date_active IS NULL));

           /*IF (p_display_log='Y') THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Item Source --5         : '||lc_item_source);
           -- To avoid too much info in Log file, Below line commented
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Account Derived by ITEM SOURCE, DEPT');
           END IF;*/

         EXCEPTION
         WHEN OTHERS THEN
           -- To avoid too much info in Log file, Below line commented
           NULL; --To Proceed Further

           /*IF (p_display_log ='Y') THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'No translation present for ITEM SOURCE and DEPT');
           END IF;*/

         END;

       --Getting Sales Account For ITEM_SOURCE Alone
       IF lc_rev_account IS NULL THEN
         BEGIN
         SELECT target_value1
               ,target_value2
               ,target_value3
               ,target_value4
         INTO   lc_rev_account
               ,lc_cogs_value2
               ,lc_inv_value3
               ,lc_cons_value4
         FROM   xx_fin_translatevalues
         WHERE  translate_id = ln_translation_id
           AND  (source_value1 = lc_item_source)
           AND  (source_value2 IS NULL )
           AND  (source_value3 IS NULL )
           AND  enabled_flag   = 'Y'
           AND  (start_date_active <= SYSDATE
           AND  (end_date_active >= SYSDATE OR end_date_active IS NULL));

         -- To avoid too much info in Log file, Below line commented
         --FND_FILE.PUT_LINE(FND_FILE.LOG,'Account Derived by ITEM SOURCE');

         EXCEPTION
         WHEN OTHERS THEN
           -- To avoid too much info in Log file, Below line commented
           NULL; -- To Proceed Further

           /*IF (p_display_log ='Y') THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'No translation present for ITEM SOURCE alone');
           END IF;*/

         END;
       END IF;
       --Getting Sales Account For Default
       IF lc_rev_account IS NULL THEN
          lc_item_source := 'DEFAULT';
          BEGIN
          SELECT target_value1
                ,target_value2
                ,target_value3
                ,target_value4
          INTO   lc_rev_account
                ,lc_cogs_value2
                ,lc_inv_value3
                ,lc_cons_value4
          FROM   xx_fin_translatevalues
          WHERE  translate_id = ln_translation_id
            AND  (source_value1 = lc_item_source)
            AND  (source_value2 IS NULL )
            AND  (source_value3 IS NULL )
            AND  enabled_flag   = 'Y'
            AND  (start_date_active <= SYSDATE
            AND  (end_date_active >= SYSDATE OR end_date_active IS NULL));

            /*IF (p_display_log ='Y') THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Account Derived by DEFAULT');
            END IF;*/

          EXCEPTION
          WHEN OTHERS THEN
            -- To avoid too much info in Log file, Below line commented
           NULL; -- To Proceed Further

           /*IF (p_display_log ='Y') THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'No translation present for ITEM SOURCE=DEFAULT');
           END IF;*/

          END;
       END IF;

       ELSIF lc_item_type IS NOT NULL AND lc_dept IS NOT  NULL THEN

         --Getting Sales Account For ITEM_TYPE And DEPT Combination
         BEGIN
         SELECT target_value1
               ,target_value2
               ,target_value3
               ,target_value4
         INTO   lc_rev_account
               ,lc_cogs_value2
               ,lc_inv_value3
               ,lc_cons_value4
         FROM   xx_fin_translatevalues
         WHERE  translate_id = ln_translation_id
           AND  (source_value1 IS NULL )
           AND  (source_value2 = lc_item_type)
           AND  (source_value3 = lc_dept)
           AND  enabled_flag   = 'Y'
           AND  (start_date_active <= SYSDATE
           AND  (end_date_active >= SYSDATE OR end_date_active IS NULL));

            /*IF (p_display_log ='Y') THEN
            -- To avoid too much info in Log file, Below line commented
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Account Derived by ITEM TYPE,DEPT');
            END IF;*/

         EXCEPTION
         WHEN OTHERS THEN
            -- To avoid too much info in Log file, Below line commented
           NULL; -- To Proceed Further

            /*IF (p_display_log ='Y') THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'No translation present for ITEM TYPE and DEPT');
            END IF;*/

         END;

         --Getting Sales Account For ITEM_TYPE Alone
         IF lc_rev_account IS NULL THEN
           BEGIN
           SELECT target_value1
                 ,target_value2
                 ,target_value3
                 ,target_value4
           INTO   lc_rev_account
                 ,lc_cogs_value2
                 ,lc_inv_value3
                 ,lc_cons_value4
           FROM   xx_fin_translatevalues
           WHERE  translate_id = ln_translation_id
             AND  (source_value1 IS NULL )
             AND (source_value2 = lc_item_type)
             AND (source_value3 IS NULL )
             AND enabled_flag   = 'Y'
             AND (start_date_active <= SYSDATE
             AND (end_date_active >= SYSDATE OR end_date_active IS NULL));

            -- To avoid too much info in Log file, Below line commented
            --FND_FILE.PUT_LINE(FND_FILE.LOG,'Account Derived by ITEM TYPE');

           EXCEPTION
           WHEN OTHERS THEN
            -- To avoid too much info in Log file, Below line commented
           NULL; -- To Proceed Further

           /*IF (p_display_log ='Y') THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'No translation present for ITEM TYPE alone');
           END IF;*/

           END;
         END IF;

         --Getting Sales Account For  DEPT Alone
         IF lc_rev_account IS NULL THEN
           BEGIN
           SELECT target_value1
                 ,target_value2
                 ,target_value3
                 ,target_value4
           INTO   lc_rev_account
                  ,lc_cogs_value2
                  ,lc_inv_value3
                  ,lc_cons_value4
           FROM   xx_fin_translatevalues
           WHERE  translate_id = ln_translation_id
             AND (source_value1 IS NULL )
             AND (source_value2 IS NULL )
             AND (source_value3 = lc_dept)
             AND enabled_flag   = 'Y'
             AND (start_date_active <= SYSDATE
             AND (end_date_active >= SYSDATE OR end_date_active IS NULL));

            -- To avoid too much info in Log file, Below line commented
            -- FND_FILE.PUT_LINE(FND_FILE.LOG,'Account Derived by DEPT');
           EXCEPTION
           WHEN OTHERS THEN
            -- To avoid too much info in Log file, Below line commented
            NULL; -- To Proceed Further

             /*IF (p_display_log ='Y') THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'No translation present for DEPT alone');
             END IF ;*/

           END;
          END IF;
       END IF;
       -- IF the Item is found, Then Derive the REV Account and Overwrite it.
       --IF lc_rev_account IS NULL AND lc_item IS NOT NULL THEN
       IF lc_item IS NOT NULL THEN
         BEGIN
         SELECT target_value1
               ,target_value2
               ,target_value3
               ,target_value4
         INTO   lc_rev_account
               ,lc_cogs_value2
               ,lc_inv_value3
               ,lc_cons_value4
         FROM   xx_fin_translatevalues
         WHERE  translate_id = ln_translation_id
           AND (source_value1 IS NULL )
           AND (source_value2 IS NULL )
           AND (source_value3 IS NULL )
           AND (source_value4 = lc_item)
           AND enabled_flag   = 'Y'
           AND (start_date_active <= SYSDATE
           AND (end_date_active >= SYSDATE OR end_date_active IS NULL));
            -- To avoid too much info in Log file, Below line commented
            --FND_FILE.PUT_LINE(FND_FILE.LOG,'Account is overridden by ITEM from SALES ACCOUNTING MATRIX Translation ');
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
            NULL; -- To Proceed Further

            /*IF (p_display_log ='Y') THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'No translation present for ITEM ID alone');
            END IF;*/

         WHEN OTHERS THEN
            -- To avoid too much info in Log file, Below line commented
           NULL; -- To Proceed Further

            /*IF (p_display_log ='Y') THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'No translation present for ITEM ID alone');
            END IF;*/

         END;
       END IF;
    EXCEPTION
    WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME(application => 'XXFIN'
                           ,name       => 'XX_AR_0011_CREATE_ACT_OTHERS');
      FND_MESSAGE.SET_TOKEN(token => 'COL'
                            ,value => 'Deriving Sales Account');
      lc_error_msg := FND_MESSAGE.GET;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_msg);
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => ln_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts'
      );
    END;



    -- Commented the below log file message to avoid printing large info
    -- Display the Derived Values

    IF (p_display_log ='Y') THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'--------------------------------------------------');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Sales Order Number   : '||lcu_process_interface_lines.sales_order);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'--------------------------------------------------');
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Customer Type        : '||lc_customer_type);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Trx Type             : '||lc_trx_type);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Order Location id    : '||ln_oloc);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Shipping Location id : '||lc_sloc);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Order Location       : '||lc_oloc_type);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Shipping Location    : '||lc_sloc_type);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Item Source          : '||lc_item_source);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Source Type          : '||lc_source_type_code );
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Item Number          : '||lc_item);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Dept                 : '||lc_dept);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Item Type            : '||lc_item_type);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Average Cost         : '||lc_avg_cost);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Line Quantity        : '||lcu_process_interface_lines.quantity); --Defect 3418
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Revenue Account      : '||lc_rev_account);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'COGS    Account      : '||lc_cogs_value2);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Inventory Account    : '||lc_inv_value3);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Consignment Bank code: '||lc_consignment);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Consignment Account  : '||lc_cons_value4);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'--------------------------------------------------');
    END IF;


    -- The below IF clause commented for Defect 1718
    -- Order Location can be blank for Web or Sales order

    IF lc_sloc_type IS NOT NULL AND lc_sloc IS NOT NULL THEN
      -- Deriving the REV oracle account segments
      XX_GET_GL_COA(
                    p_oloc          => ln_oloc
                   ,p_sloc          => lc_sloc
                   ,p_oloc_type     => lc_oloc_type
                   ,p_sloc_type     => lc_sloc_type
                   ,p_line_id       => ln_interface_line_id
                   ,p_rev_account   => lc_rev_account
                   ,p_acc_class     => 'REV'
                   ,p_cust_type     => lc_customer_type
                   ,p_trx_type      => lc_trx_type
                   ,p_log_flag      => p_display_log
                   ,x_company       => lc_rev_company
                   ,x_costcenter    => lc_rev_costcenter
                   ,x_account       => lc_rev_account
                   ,x_location      => lc_rev_location
                   ,x_intercompany  => lc_rev_intercompany
                   ,x_lob           => lc_rev_lob
                   ,x_future        => lc_rev_future
                   ,x_ccid          => ln_rev_ccid
                   ,x_error_message => lc_error_msg
      );

    ELSE
          IF lc_sloc_type IS NULL OR lc_sloc IS NULL  THEN

             IF (p_display_log ='Y') THEN
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Shipping Location Type is Mandatory for Sales Order : '
                                                         || lcu_process_interface_lines.sales_order);
             FND_FILE.PUT_LINE(FND_FILE.LOG,'The Shipping Location Type is Mandatory for Sales Order : '
                                                         || lcu_process_interface_lines.sales_order);
             END IF;

                lt_ril(ln_array) := lcu_process_interface_lines.sales_order;
                lc_error_flag_val := 'Y';

          END IF;

    END IF;

    IF lcu_process_interface_lines.accounting_rule_id IS NOT NULL THEN
        BEGIN
        XX_GET_GL_COA(
                     p_oloc         => ln_oloc
                    ,p_sloc         => lc_sloc
                    ,p_oloc_type    => lc_oloc_type
                    ,p_sloc_type    => lc_sloc_type
                    ,p_line_id      => ln_interface_line_id
                    ,p_rev_account  => lc_rev_account
                    ,p_cust_type    => lc_customer_type
                    ,p_trx_type      => lc_trx_type
                    ,p_acc_class    => 'UNEARN'
                    ,p_log_flag      => p_display_log
                    ,x_company      => lc_rec_company
                    ,x_costcenter   => lc_rec_costcenter
                    ,x_account      => lc_rec_account
                    ,x_location     => lc_rec_location
                    ,x_intercompany => lc_rec_intercompany
                    ,x_lob          => lc_rec_lob
                    ,x_future       => lc_rec_future
                    ,x_ccid         => ln_rec_ccid
                    ,x_error_message => lc_error_msg
                    );

         EXCEPTION
         WHEN OTHERS THEN

            IF (p_display_log ='Y') THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception Raised while deriving UNEARN Accounts for Sales Order '
                          || lcu_process_interface_lines.sales_order );
            END IF;


         END;

    /*    IF   lc_rec_company      IS NOT NULL
         AND lc_rec_costcenter   IS NOT NULL
         AND lc_rec_account      IS NOT NULL
         AND lc_rec_location     IS NOT NULL
         AND lc_rec_intercompany IS NOT NULL
         AND lc_rec_lob          IS NOT NULL
         AND lc_rec_future       IS NOT NULL
         AND ln_rec_ccid         IS NOT NULL
         THEN*/
         BEGIN
       --inserting data into ra_distributions_all with acc_class "UNEARN"

       INSERT
       INTO ra_interface_distributions_all(
                                           interface_line_context
                                          ,interface_line_attribute1
                                          ,interface_line_attribute2
                                          ,interface_line_attribute3
                                          ,interface_line_attribute4
                                          ,interface_line_attribute5
                                          ,interface_line_attribute6
                                          ,interface_line_attribute7
                                          ,interface_line_attribute8
                                          ,interface_line_attribute9
                                          ,interface_line_attribute10
                                          ,interface_line_attribute11
                                          ,interface_line_attribute12
                                          ,interface_line_attribute13
                                          ,interface_line_attribute14
                                          ,interface_line_attribute15
                                          ,amount
                                          ,account_class
                                          ,code_combination_id
                                          ,segment1
                                          ,segment2
                                          ,segment3
                                          ,segment4
                                          ,segment5
                                          ,segment6
                                          ,segment7
                                          ,org_id
                                          ,percent
                                          ,created_by
                                          ,creation_date
                                          ,last_updated_by
                                          ,last_update_date
                                          ,last_update_login
      )
      VALUES
      (
       lcu_process_interface_lines.interface_line_context
       ,lcu_process_interface_lines.interface_line_attribute1
       ,lcu_process_interface_lines.interface_line_attribute2
       ,lcu_process_interface_lines.interface_line_attribute3
       ,lcu_process_interface_lines.interface_line_attribute4
       ,lcu_process_interface_lines.interface_line_attribute5
       ,lcu_process_interface_lines.interface_line_attribute6
       ,lcu_process_interface_lines.interface_line_attribute7
       ,lcu_process_interface_lines.interface_line_attribute8
       ,lcu_process_interface_lines.interface_line_attribute9
       ,lcu_process_interface_lines.interface_line_attribute10
       ,lcu_process_interface_lines.interface_line_attribute11
       ,lcu_process_interface_lines.interface_line_attribute12
       ,lcu_process_interface_lines.interface_line_attribute13
       ,lcu_process_interface_lines.interface_line_attribute14
       ,lcu_process_interface_lines.interface_line_attribute15
       ,lcu_process_interface_lines.amount
       ,'UNEARN'
       ,ln_rec_ccid
       ,NVL(lc_rec_company,'0000')
       ,lc_rec_costcenter
       ,lc_rec_account
       ,lc_rec_location
       ,lc_rec_intercompany
       ,lc_rec_lob
       ,lc_rec_future
       ,FND_PROFILE.VALUE('ORG_ID')
       ,100
       ,FND_PROFILE.VALUE('USER_ID')
       ,SYSDATE
       ,FND_PROFILE.VALUE('USER_ID')
       ,SYSDATE
       ,FND_PROFILE.VALUE('LOGIN_ID')
       );
        EXCEPTION
         WHEN OTHERS THEN

            IF (p_display_log ='Y') THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception Raised while inserting UNEARN Accounts for Sales Order '
                          || lcu_process_interface_lines.sales_order );
            END IF;

        END;
     --  END IF;
      END IF;

      /*IF (p_display_log ='Y') THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Prev Sales Order: '|| lcu_process_interface_lines.sales_order );
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Curr Sales Order: '|| lc_prev_sales_order );
      END IF;*/
      -- RECEIVABLE accounts into ra_distributions_all with acc_class "REC"
        -- Defect 1555 Auto Accounting- Multiple REC accounts
        -- IF Clause added to resolve the Defect 1555
        IF lcu_process_interface_lines.sales_order <> lc_prev_sales_order
          --AND lcu_process_interface_lines.currency_code <> lc_prev_currency
          THEN
            lc_prev_sales_order := lcu_process_interface_lines.sales_order;
            lc_prev_currency    := lcu_process_interface_lines.currency_code;
            BEGIN
            -- Deriving the REC oracle account segments
               XX_GET_GL_COA(
                             p_oloc          => ln_oloc
                            ,p_sloc          => lc_sloc
                            ,p_oloc_type     => lc_oloc_type
                            ,p_sloc_type     => lc_sloc_type
                            ,p_line_id       => ln_interface_line_id
                            ,p_rev_account   => lc_rev_account
                            ,p_cust_type     => lc_customer_type
                            ,p_trx_type      => lc_trx_type
                            ,p_acc_class     => 'REC'
                            ,p_log_flag      => p_display_log
                            ,x_company       => lc_rec_company
                            ,x_costcenter    => lc_rec_costcenter
                            ,x_account       => lc_rec_account
                            ,x_location      => lc_rec_location
                            ,x_intercompany  => lc_rec_intercompany
                            ,x_lob           => lc_rec_lob
                            ,x_future        => lc_rec_future
                            ,x_ccid          => ln_rec_ccid
                            ,x_error_message => lc_error_msg
                             );

                EXCEPTION
                  WHEN OTHERS THEN

                        IF (p_display_log ='Y') THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception Raised while deriving REC Accounts '
                          || 'for Sales Order ' || lcu_process_interface_lines.sales_order );
                        END IF;

                END;
        BEGIN
               /****************************************************************/
         IF    ln_rec_ccid  IS NULL THEN

               lc_rec_company := '0000';
               -- Display the Sales Order Number if Account is not derived.
            IF (p_display_log ='Y') THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Unprocessed Sales Order : '||lcu_process_interface_lines.sales_order);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Invalid REC Segment : ' ||
                                lc_rec_company ||  '.' || lc_rec_costcenter || '.' ||
                                lc_rec_account ||  '.' || lc_rec_location || '.' ||
                                lc_rec_intercompany ||  '.' || lc_rec_lob || '.' ||
                                lc_rec_future);
            END IF;

             IF (p_display_log ='N') THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'The Unprocessed Sales Order  : '|| lcu_process_interface_lines.sales_order);
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Unprocessed Sales Order  : '|| lcu_process_interface_lines.sales_order);
             END IF;



             BEGIN
                lt_ril(ln_array) := lcu_process_interface_lines.sales_order;
                ln_array := ln_array + 1;
                lc_error_flag_val := 'Y';
             EXCEPTION
               WHEN OTHERS THEN

                 IF (p_display_log ='Y') THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception Raised while marking error record for Sales Order '
                          || lcu_process_interface_lines.sales_order );
                 END IF;
              END;

              ELSE -- For Defect 3418 output file
                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Processed Sales Order  : '|| lcu_process_interface_lines.sales_order);
          END IF;

          --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Sales Order Number : '||lcu_process_interface_lines.sales_order);

          /*IF (p_display_log ='N') THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Sales Order Number   : '||lcu_process_interface_lines.sales_order);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'-----------------------------------------------------------------------------');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Sales Order Number   : '||lcu_process_interface_lines.sales_order);
          END IF;*/

          /****************************************************************/
                INSERT
                INTO ra_interface_distributions_all(
                                                    interface_line_context
                                                   ,interface_line_attribute1
                                                   ,interface_line_attribute2
                                                   ,interface_line_attribute3
                                                   ,interface_line_attribute4
                                                   ,interface_line_attribute5
                                                   ,interface_line_attribute6
                                                   ,interface_line_attribute7
                                                   ,interface_line_attribute8
                                                   ,interface_line_attribute9
                                                   ,interface_line_attribute10
                                                   ,interface_line_attribute11
                                                   ,interface_line_attribute12
                                                   ,interface_line_attribute13
                                                   ,interface_line_attribute14
                                                   ,interface_line_attribute15
                                                   ,account_class
                                                   ,code_combination_id
                                                   ,segment1
                                                   ,segment2
                                                   ,segment3
                                                   ,segment4
                                                   ,segment5
                                                   ,segment6
                                                   ,segment7
                                                   ,org_id
                                                   ,percent
                                                   ,created_by
                                                   ,creation_date
                                                   ,last_updated_by
                                                   ,last_update_date
                                                   ,last_update_login
                                                   )
                VALUES
                (
                 lcu_process_interface_lines.interface_line_context
                ,lcu_process_interface_lines.interface_line_attribute1
                ,lcu_process_interface_lines.interface_line_attribute2
                ,lcu_process_interface_lines.interface_line_attribute3
                ,lcu_process_interface_lines.interface_line_attribute4
                ,lcu_process_interface_lines.interface_line_attribute5
                ,lcu_process_interface_lines.interface_line_attribute6
                ,lcu_process_interface_lines.interface_line_attribute7
                ,lcu_process_interface_lines.interface_line_attribute8
                ,lcu_process_interface_lines.interface_line_attribute9
                ,lcu_process_interface_lines.interface_line_attribute10
                ,lcu_process_interface_lines.interface_line_attribute11
                ,lcu_process_interface_lines.interface_line_attribute12
                ,lcu_process_interface_lines.interface_line_attribute13
                ,lcu_process_interface_lines.interface_line_attribute14
                ,lcu_process_interface_lines.interface_line_attribute15
                ,'REC'
                ,ln_rec_ccid
                ,NVL(lc_rec_company,'0000')
                ,lc_rec_costcenter
                ,lc_rec_account
                ,lc_rec_location
                ,lc_rec_intercompany
                ,lc_rec_lob
                ,lc_rec_future
                ,FND_PROFILE.VALUE('ORG_ID')
                ,100
                ,FND_PROFILE.VALUE('USER_ID')
                ,SYSDATE
                ,FND_PROFILE.VALUE('USER_ID')
                ,SYSDATE
                ,FND_PROFILE.VALUE('LOGIN_ID')
                 );

                 IF ln_rec_ccid  IS NOT NULL THEN
                 ln_rec_acct_count := ln_rec_acct_count + 1;
                 END IF;


            EXCEPTION
             WHEN OTHERS THEN

               IF (p_display_log ='Y') THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception Raised while inserting REC Accounts for Sales Order '
                          || lcu_process_interface_lines.sales_order );
               END IF;

            END;

      END IF;

      --inserting REVENUE into ra_distributions_all with acc_class "REV"
     BEGIN

     /*************************************************************/
IF   ln_rev_ccid  IS NULL  THEN

     lc_rev_company := '0000' ;
    -- Display the Sales Order Number if Account is not derived.
        --ln_int_amount := ln_int_amount + NVL(lcu_process_interface_lines.amount,0);

        IF (p_display_log ='Y') THEN
        --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Sales Order         : ' ||lcu_process_interface_lines.sales_order);
        --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Order Amount        : ' ||lcu_process_interface_lines.amount);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Invalid REV Segment : ' ||
                                lc_rev_company ||  '.' || lc_rev_costcenter || '.' ||
                                lc_rev_account ||  '.' || lc_rev_location || '.' ||
                                lc_rev_intercompany ||  '.' || lc_rev_lob || '.' ||
                                lc_rev_future);
        END IF;

         BEGIN
          lt_ril(ln_array) := lcu_process_interface_lines.sales_order;
          ln_array := ln_array + 1;
          ln_err_count := ln_err_count + 1;
          lc_error_flag_val := 'Y';
         EXCEPTION
             WHEN OTHERS THEN

               IF (p_display_log ='Y') THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception Raised while marking error records for Sales Order and line id '
                || lcu_process_interface_lines.sales_order || lcu_process_interface_lines.interface_line_id );
               END IF;

         END;
END IF;

IF  lc_consignment IS NULL THEN
    lc_cons_value4 := '';
END IF;

/*************************************************************/


      INSERT
      INTO ra_interface_distributions_all(
                                          interface_line_context
                                         ,interface_line_attribute1
                                         ,interface_line_attribute2
                                         ,interface_line_attribute3
                                         ,interface_line_attribute4
                                         ,interface_line_attribute5
                                         ,interface_line_attribute6
                                         ,interface_line_attribute7
                                         ,interface_line_attribute8
                                         ,interface_line_attribute9
                                         ,interface_line_attribute10
                                         ,interface_line_attribute11
                                         ,interface_line_attribute12
                                         ,interface_line_attribute13
                                         ,interface_line_attribute14
                                         ,interface_line_attribute15
                                         ,amount
                                         ,account_class
                                         ,code_combination_id
                                         ,segment1
                                         ,segment2
                                         ,segment3
                                         ,segment4
                                         ,segment5
                                         ,segment6
                                         ,segment7
                                         ,org_id
                                         ,percent
                                         ,Attribute_category
                                         ,attribute6
                                         ,attribute7
                                         ,attribute8
                                         ,attribute9
                                         ,attribute10   --requirment for defect 2426
                                         ,created_by
                                         ,creation_date
                                         ,last_updated_by
                                         ,last_update_date
                                         ,last_update_login
      )
      VALUES
      (
       lcu_process_interface_lines.interface_line_context
      ,lcu_process_interface_lines.interface_line_attribute1
      ,lcu_process_interface_lines.interface_line_attribute2
      ,lcu_process_interface_lines.interface_line_attribute3
      ,lcu_process_interface_lines.interface_line_attribute4
      ,lcu_process_interface_lines.interface_line_attribute5
      ,lcu_process_interface_lines.interface_line_attribute6
      ,lcu_process_interface_lines.interface_line_attribute7
      ,lcu_process_interface_lines.interface_line_attribute8
      ,lcu_process_interface_lines.interface_line_attribute9
      ,lcu_process_interface_lines.interface_line_attribute10
      ,lcu_process_interface_lines.interface_line_attribute11
      ,lcu_process_interface_lines.interface_line_attribute12
      ,lcu_process_interface_lines.interface_line_attribute13
      ,lcu_process_interface_lines.interface_line_attribute14
      ,lcu_process_interface_lines.interface_line_attribute15
      ,lcu_process_interface_lines.amount
      ,'REV'
      ,ln_rev_ccid
      ,NVL(lc_rev_company,'0000')
      ,lc_rev_costcenter
      ,lc_rev_account
      ,lc_rev_location
      ,lc_rev_intercompany
      ,lc_rev_lob
      ,lc_rec_future
      ,FND_PROFILE.VALUE('ORG_ID')
      ,100
      ,lc_attribute_category
      ,'N'
      ,lc_cogs_value2
      ,lc_inv_value3
      ,lc_avg_cost
      ,lc_cons_value4  --requirment for defect 2426
      ,FND_PROFILE.VALUE('USER_ID')
      ,SYSDATE
      ,FND_PROFILE.VALUE('USER_ID')
      ,SYSDATE
      ,FND_PROFILE.VALUE('LOGIN_ID')
      );
      IF ln_rev_ccid  IS NOT NULL THEN
      ln_rev_acct_count := ln_rev_acct_count + 1;
      END IF;

      EXCEPTION
      WHEN OTHERS THEN

        IF (p_display_log ='Y') THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception Raised while inserting REV Accounts for Sales Order and line id'
           || lcu_process_interface_lines.sales_order || lcu_process_interface_lines.interface_line_id );
        END IF;

      END;

    --Requirement for updating ra_interface_lines_all
    BEGIN

       -- To update only when line_type is 'LINE'
       IF (lcu_process_interface_lines.line_type = 'LINE' )THEN
           -- CR 3723 to have order header_id to populate into DFF of invoice header.
              UPDATE ra_interface_lines_all ril
              SET    RIL.header_attribute_category = lc_attribute_category
                    ,RIL.header_attribute14        = ln_order_header_id
              WHERE  sales_order                   = lcu_process_interface_lines.sales_order
              AND    RIL.interface_line_context    = 'ORDER ENTRY'
              AND    RIL.line_type                 = 'LINE'
              AND    RIL.org_id                    = FND_PROFILE.VALUE('ORG_ID') ;

       END IF;

     IF (lcu_process_interface_lines.reference_line_id IS NOT NULL) THEN

       UPDATE ra_interface_lines_all RIL
          SET RIL.attribute14        = ril.reference_line_id,
              RIL.reference_line_id  = NULL
        WHERE RIL.sales_order = lcu_process_interface_lines.sales_order
          AND RIL.org_id      = FND_PROFILE.VALUE('ORG_ID')
          AND RIL.interface_line_context = 'ORDER ENTRY'
          AND RIL.interface_line_attribute6 = lcu_process_interface_lines.interface_line_attribute6
          AND RIL.reference_line_id IS NOT NULL
          AND EXISTS
              (SELECT 1
                FROM oe_order_headers_all OOH,
                     xx_om_return_tenders_all XORT
                WHERE OOH.header_id = XORT.header_id
                AND OOH.order_number = RIL.sales_order);
     END IF;
    --Update description for price adjustments. defect 2580

    IF (lcu_process_interface_lines.interface_line_attribute11 <> 0 AND
        lcu_process_interface_lines.attribute8 IS NOT NULL) THEN
  BEGIN
          SELECT meaning
            INTO ls_disc_description
            FROM fnd_lookup_values
           WHERE lookup_type='OD_DISCOUNT_ITEMS'
             AND lookup_code = lcu_process_interface_lines.attribute8;

           UPDATE ra_interface_lines_all RIL
              SET RIL.description = ls_disc_description
            WHERE RIL.sales_order = lcu_process_interface_lines.sales_order
              AND RIL.org_id = FND_PROFILE.VALUE('ORG_ID')
              AND RIL.inventory_item_id = lcu_process_interface_lines.inventory_item_id
              AND RIL.sales_order_line  = lcu_process_interface_lines.sales_order_line
              AND RIL.interface_line_attribute11 = lcu_process_interface_lines.interface_line_attribute11;

        Exception
           WHEN NO_DATA_FOUND THEN
                  FND_MESSAGE.SET_NAME(application => 'XXFIN'
                                       ,name       => 'XX_AR_0010_CREATE_ACT_NO_DATA');
                  FND_MESSAGE.SET_TOKEN(token  => 'COL'
                                        ,value => 'No Description for Discount line:'||lcu_process_interface_lines.sales_order||'Coupon code:'||lcu_process_interface_lines.attribute8);
                  lc_error_msg := FND_MESSAGE.GET;

     IF (p_display_log ='Y') THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_msg);
     END IF;

     XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                     p_program_type            => 'CONCURRENT PROGRAM'
                                    ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                    ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                    ,p_module_name             => 'AR'
                                    ,p_error_location          => 'Oracle Error '||SQLERRM
                                    ,p_error_message_count     => ln_msg_cnt + 1
                                    ,p_error_message_code      => 'E'
                                    ,p_error_message           => lc_error_msg
                                    ,p_error_message_severity  => 'Major'
                                    ,p_notify_flag             => 'N'
                                    ,p_object_type             => 'Creating Accounts'
     );
     WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME(application => 'XXFIN'
                            ,name       => 'XX_AR_0011_CREATE_ACT_OTHERS');
       FND_MESSAGE.SET_TOKEN(token  => 'COL'
                             ,value => 'No Description for Discount line:'||lcu_process_interface_lines.sales_order||'Coupon code:'||lcu_process_interface_lines.attribute8);
       lc_error_msg := FND_MESSAGE.GET;
       FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_msg);
       XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                       p_program_type            => 'CONCURRENT PROGRAM'
                                      ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                      ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                      ,p_module_name             => 'AR'
                                      ,p_error_location          => 'Oracle Error '||SQLERRM
                                      ,p_error_message_count     => ln_msg_cnt+1
                                      ,p_error_message_code      => 'E'
                                      ,p_error_message           => lc_error_msg
                                      ,p_error_message_severity  => 'Major'
                                      ,p_notify_flag             => 'N'
                                      ,p_object_type             => 'Creating Accounts');
  END;

END IF;

    SELECT XOHA.cost_center_dept
          ,XOHA.desk_del_addr
          ,XOLA.contract_details
          ,XOLA.release_num
          --,XOHA.legacy_cust_name
          ,OLA.actual_shipment_date
    INTO   lc_cost_center_dept
          ,lc_desk_del_addr
          ,lc_contract_details
          ,lc_release_num
          --,lc_legacy_cust_name
          ,lc_actual_ship_date
    FROM   oe_order_headers_all OHA
          ,oe_order_lines_all OLA
          ,xx_om_header_attributes_all XOHA
          ,xx_om_line_attributes_all   XOLA
    WHERE  OHA.order_number = lcu_process_interface_lines.sales_order
      AND  OHA.header_id = OLA.header_id
      AND  OHA.header_id = XOHA.header_id
      AND  OLA.line_id = XOLA.line_id
      AND  OLA.inventory_item_id = lcu_process_interface_lines.inventory_item_id
      AND  OLA.line_number       = lcu_process_interface_lines.sales_order_line;


   UPDATE ra_interface_lines_all
   SET    attribute6 = lc_cost_center_dept
         ,attribute7 = lc_desk_del_addr
         ,attribute8 = SUBSTR(lc_contract_details,1,1)
         ,attribute9 = SUBSTR(lc_contract_details,3,7)
         ,attribute10 = SUBSTR(lc_contract_details,11,3)
         ,attribute11 = lc_release_num
         --,trx_number = lcu_process_interface_lines.sales_order
         --,attribute15 = lc_legacy_cust_name
         ,ship_date_actual = lc_actual_ship_date
         ,attribute_category = lc_attribute_category
   WHERE sales_order = lcu_process_interface_lines.sales_order
   AND   inventory_item_id = lcu_process_interface_lines.inventory_item_id
   AND   sales_order_line  = lcu_process_interface_lines.sales_order_line
   AND   org_id = FND_PROFILE.VALUE('ORG_ID');


   EXCEPTION
   WHEN NO_DATA_FOUND THEN
     FND_MESSAGE.SET_NAME(application => 'XXFIN'
                         ,name       => 'XX_AR_0010_CREATE_ACT_NO_DATA');
     FND_MESSAGE.SET_TOKEN(token  => 'COL'
                          ,value => 'Custom OE table values for sales order:'||lcu_process_interface_lines.sales_order||'and inventory intem ID:'||lcu_process_interface_lines.inventory_item_id);
     lc_error_msg := FND_MESSAGE.GET;
     FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_msg);
     XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                     p_program_type            => 'CONCURRENT PROGRAM'
                                    ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                    ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                    ,p_module_name             => 'AR'
                                    ,p_error_location          => 'Oracle Error '||SQLERRM
                                    ,p_error_message_count     => ln_msg_cnt + 1
                                    ,p_error_message_code      => 'E'
                                    ,p_error_message           => lc_error_msg
                                    ,p_error_message_severity  => 'Major'
                                    ,p_notify_flag             => 'N'
                                    ,p_object_type             => 'Creating Accounts'
     );
     WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME(application => 'XXFIN'
                            ,name       => 'XX_AR_0011_CREATE_ACT_OTHERS');
       FND_MESSAGE.SET_TOKEN(token  => 'COL'
                             ,value => 'Custom OE table values for sales order:'||lcu_process_interface_lines.sales_order||'and inventory intem ID:'||lcu_process_interface_lines.inventory_item_id);
       lc_error_msg := FND_MESSAGE.GET;
       FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_msg);
       XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                       p_program_type            => 'CONCURRENT PROGRAM'
                                      ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                      ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                      ,p_module_name             => 'AR'
                                      ,p_error_location          => 'Oracle Error '||SQLERRM
                                      ,p_error_message_count     => ln_msg_cnt+1
                                      ,p_error_message_code      => 'E'
                                      ,p_error_message           => lc_error_msg
                                      ,p_error_message_severity  => 'Major'
                                      ,p_notify_flag             => 'N'
                                      ,p_object_type             => 'Creating Accounts');
    END;


    ln_tot_count := ln_tot_count + 1; --to get the total number of records processed


    ln_count := ln_count + 1;

    IF ln_count = 2000 then
       ln_count := 1;
       COMMIT;
    END IF;

    --ln_array := ln_array + 1;

    END IF;----Closing if for the Sales order range

    END LOOP;
    COMMIT;

     -- Defect 1543
     -- Update ra_interface_lines_table with status 'E'
     -- 20-sep-07 --Raghu--Commenting this section as the error records are not showing up in the Interface line window.
     /*
        IF lc_error_flag_val = 'Y' THEN

        BEGIN
              -- Updating Error Flag in ra_interface_lines_all table

              FORALL ln_array IN lt_ril.FIRST..lt_ril.LAST
	      UPDATE ra_interface_lines_all
              SET interface_status  = 'E'
                  ,request_id       = NVL(FND_GLOBAL.CONC_REQUEST_ID,0)
                  --,trx_number = lt_ril(ln_array)
              WHERE sales_order = lt_ril(ln_array)
              AND org_id = FND_PROFILE.VALUE('ORG_ID');
              --ln_err_order_count       := SQL%ROWCOUNT;
              COMMIT;

        EXCEPTION
        WHEN OTHERS THEN
             FND_MESSAGE.SET_NAME(application => 'XXFIN'
                            ,name       => 'XX_AR_0011_CREATE_ACT_OTHERS');
             FND_MESSAGE.SET_TOKEN(token  => 'COL'
                             ,value => 'Update Error in ra_interface_lines table');
            lc_error_msg := FND_MESSAGE.GET;
            FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_msg);
            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                       p_program_type            => 'CONCURRENT PROGRAM'
                                      ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                      ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                      ,p_module_name             => 'AR'
                                      ,p_error_location          => 'Oracle Error '||SQLERRM
                                      ,p_error_message_count     => ln_msg_cnt+1
                                      ,p_error_message_code      => 'E'
                                      ,p_error_message           => lc_error_msg
                                      ,p_error_message_severity  => 'Major'
                                      ,p_notify_flag             => 'N'
                                      ,p_object_type             => 'Creating Accounts');
        END;
     END IF;
   */

     BEGIN
              /*SELECT NVL(SUM(ril.amount) ,0),count(ril.sales_order)
              INTO  ln_int_amount,ln_err_order_count
              FROM  APPS.RA_INTERFACE_LINES_ALL RIL
              WHERE RIL.org_id = FND_PROFILE.VALUE('ORG_ID')
              AND   RIL.SALES_ORDER IN (SELECT DISTINCT interface_line_attribute1
              FROM apps.ra_interface_distributions_all WHERE segment1='0000')
 --             AND   RIL.interface_status='E'
                AND   RIL.request_id = NVL(FND_GLOBAL.CONC_REQUEST_ID,0);*/

        --Modifed the above query to improve performance issue for defect 3944
        --Added parameter p_error_message to display the error information

            IF (p_error_message ='Y' )THEN

              SELECT NVL(SUM(RIL.amount) ,0),count(RIL.sales_order)
              INTO  ln_int_amount,ln_err_order_count
              FROM  ra_interface_lines_all RIL
              WHERE RIL.org_id = FND_PROFILE.VALUE('ORG_ID')
              AND   EXISTS (SELECT 1
                            FROM  ra_interface_distributions_all RID
                            WHERE RID.interface_line_attribute1 = RIL.sales_order
                            AND RID.code_combination_id IS NULL
                            AND RID.account_class = 'REC');

            END IF;

     END;

    FND_FILE.PUT_LINE (FND_FILE.LOG,'Total Invoice LINES Selected           : ' || ln_tot_count);
    FND_FILE.PUT_LINE (FND_FILE.LOG,'Total Invoice RECEIVABLE Lines Created : ' || ln_rec_acct_count);
    FND_FILE.PUT_LINE (FND_FILE.LOG,'Total Invoice REVENUE    Lines Created : ' || ln_rev_acct_count);

    IF (p_error_message ='Y' )THEN
    FND_FILE.PUT_LINE (FND_FILE.LOG,'Total Invoice LINES Updated as ERROR   : ' || ln_err_order_count);
    FND_FILE.PUT_LINE (FND_FILE.LOG,'Total Amount of Errored Transactions   : ' || '$' || ln_int_amount);
    END IF;

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'---------------------------------------------------------');
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'Total Invoice LINES Selected           : ' || ln_tot_count);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'Total Invoice RECEIVABLE Lines Created : ' || ln_rec_acct_count);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'Total Invoice REVENUE    Lines Created : ' || ln_rev_acct_count);

    IF (p_error_message ='Y' )THEN
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'Total Invoice LINES Updated as ERROR   : ' || ln_err_order_count);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'Total Amount of Errored Transactions   : ' || '$' || ln_int_amount);
    END IF;

    IF ln_count = 0 THEN
       FND_FILE.PUT_LINE (FND_FILE.LOG,'No Invoice found in Interface table for the source SALES_ACCT%');
       FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'No Invoice found in Interface table for the source SALES_ACCT%');
    END IF;

      -- Sending Output file to the concerned Person
         ln_req_id := FND_REQUEST.SUBMIT_REQUEST (
                                                  'xxfin'
                                                 ,'XXODROEMAILER'
                                                 ,''
                                                 ,''
                                                 ,FALSE
                                                 ,'OD: AR Create Autoinvoice Accounting'
                                                 ,p_email_address
                                                 ,'Sales Order Auto Invoice Create Account Error Records Output File'
                                                 ,'Sales Order Auto Invoice Create Account Error Records Output File'
                                                 ,'Y'
                                                 ,FND_GLOBAL.CONC_REQUEST_ID
                      );
         COMMIT;

    ELSIF UPPER(SUBSTR(p_run_flag,1,1)) = 'A' THEN
       BEGIN
       lc_error_loc   := 'Determining the invoices processed by Import Program.';
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Create Account Request Id : ' || FND_GLOBAL.CONC_REQUEST_ID);

       SELECT FCR2.request_id
       INTO   ln_request_id
       FROM   fnd_concurrent_programs FCPM
             ,fnd_concurrent_requests FCR2
             ,fnd_concurrent_requests FCR1
       WHERE  FCR1.request_id = FND_GLOBAL.CONC_REQUEST_ID
         AND  FCR2.priority_request_id = FCR1.priority_request_id
         AND  FCR2.concurrent_program_id = FCPM.concurrent_program_id
         AND  FCPM.concurrent_program_name = 'RAXTRX';

       EXCEPTION
       WHEN NO_DATA_FOUND THEN
         FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
         lc_error_msg :=  FND_MESSAGE.GET;
         FND_FILE.PUT_LINE (FND_FILE.LOG,lc_error_msg);
         XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                         p_program_type            => 'CONCURRENT PROGRAM'
                                        ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                        ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                        ,p_module_name             => 'AR'
                                        ,p_error_location          => 'Error at ' || lc_error_loc
                                        ,p_error_message_count     => ln_msg_cnt+1
                                        ,p_error_message_code      => 'E'
                                        ,p_error_message           => lc_error_msg
                                        ,p_error_message_severity  => 'Major'
                                        ,p_notify_flag             => 'N'
                                        ,p_object_type             => 'Creating Accounts'
         );
       WHEN OTHERS THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Location: '||lc_error_loc);
         FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Message : '||SQLERRM);
         FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
         lc_error_msg := FND_MESSAGE.GET;
         FND_FILE.PUT_LINE (FND_FILE.LOG,lc_error_msg);
         XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                          p_program_type            => 'CONCURRENT PROGRAM'
                                         ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                         ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                         ,p_module_name             => 'AR'
                                         ,p_error_location          => 'Error at ' || lc_error_loc
                                         ,p_error_message_count     => ln_msg_cnt+1
                                         ,p_error_message_code      => 'E'
                                         ,p_error_message           => SQLERRM
                                         ,p_error_message_severity  => 'Major'
                                         ,p_notify_flag             => 'N'
                                         ,p_object_type             => 'Creating Accounts'
         );
       END;
       --Added to remove SOB hardcoding
       BEGIN

       SELECT VAL.target_value1
       INTO   lc_sob_name
       FROM   xx_fin_translatedefinition DEF
             ,xx_fin_translatevalues VAL
       WHERE  DEF.translate_id = VAL.translate_id
       AND    DEF.translation_name = 'OD_COUNTRY_DEFAULTS'
       AND    VAL.source_value1 = 'CA';
       END;

       IF ln_request_id IS NOT NULL THEN
         BEGIN
         SELECT GSB.set_of_books_id
         INTO   ln_sob_id
         FROM   gl_sets_of_books GSB
         --WHERE  GSB.short_name = 'CA_CAD_P';
         WHERE  GSB.short_name = lc_sob_name;

         FOR lcu_cust_trx IN c_cust_trx( ln_request_id
                                       ,ln_sob_id)
         LOOP

         -- Derive Tax Account id
         XX_GET_GL_COA(
                       p_oloc         => lcu_cust_trx.ship_to_site_use_id
                      ,p_sloc         => lcu_cust_trx.ship_to_site_use_id
                      ,p_oloc_type    => lc_oloc_type
                      ,p_sloc_type    => lc_sloc_type
                      ,p_line_id      => ln_interface_line_id
                      ,p_rev_account  => lc_rev_account
                      ,p_cust_type    => lc_customer_type
                      ,p_trx_type      => lc_trx_type
                      ,p_acc_class    => 'TAX'
                      ,p_log_flag      => p_display_log
                      ,x_company      => lc_tax_company
                      ,x_costcenter   => lc_tax_costcenter
                      ,x_account      => lc_tax_account
                      ,x_location     => lc_tax_location
                      ,x_intercompany => lc_tax_intercompany
                      ,x_lob          => lc_tax_lob
                      ,x_future       => lc_tax_future
                      ,x_ccid         => ln_tax_ccid
                      ,x_error_message => lc_error_msg
         );

         -- Updating Tax Lines
         UPDATE RA_CUST_TRX_LINE_GL_DIST_ALL
         SET   code_combination_id = ln_tax_ccid
         WHERE customer_trx_line_id = lcu_cust_trx.customer_trx_line_id
           AND   account_class   = 'TAX'
           AND   request_id      = ln_request_id
           AND   set_of_books_id  = ln_sob_id;
           ln_tot_count := SQL%ROWCOUNT;
         END LOOP;
         COMMIT;

         FND_FILE.PUT_LINE (FND_FILE.LOG,'Total Tax Lines Updated for CANADA PST Lines : ' || ln_tot_count);
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'Total Tax Lines Updated for CANADA PST Lines : ' || ln_tot_count);

         EXCEPTION
         WHEN OTHERS THEN
           FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Location: '||lc_error_loc);
           FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Message : '||SQLERRM);
           FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
           lc_error_msg :=  FND_MESSAGE.get;
           FND_FILE.PUT_LINE (FND_FILE.LOG,lc_error_msg);
           XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                           p_program_type            => 'CONCURRENT PROGRAM'
                                          ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                          ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                          ,p_module_name             => 'AR'
                                          ,p_error_location          => 'Error at ' || lc_error_loc
                                          ,p_error_message_count     => ln_msg_cnt+1
                                          ,p_error_message_code      => 'E'
                                          ,p_error_message           => SQLERRM
                                          ,p_error_message_severity  => 'Major'
                                          ,p_notify_flag             => 'N'
                                          ,p_object_type             => 'Creating Accounts'
           );
           END;

       ELSE

         FND_FILE.PUT_LINE (FND_FILE.LOG,   'No Invoice found for this Request id : ' || ln_request_id);
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'No Invoice found for this Request id : ' || ln_request_id);

       END IF;
    END IF;
    EXCEPTION

-- EX_SALES_ORDER user defined exception is raised when any one of the Sales Order Parameter IS NULL
-- and makes the requestset error not to proceed further by AUTOINVOICE MASTER PROGRAM

    WHEN  EX_SALES_ORDER THEN
    x_ret_code:=2; -- making the CONCURENT PROG to ERROR OUT so that the shared Parameter will not pass the values to AUTOINVOICE MASTER PROGRAM
    FND_FILE.PUT_LINE (FND_FILE.LOG,'Exception : Please Pass Values for Both Parameters Sales Order From And Sales Order To ');
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'Exception : Please Pass Values for Both Parameters Sales Order From And Sales Order To ');


    WHEN OTHERS THEN
      FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Location : Exception Raised in Main Procedure: '||lc_error_loc);
      FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Message : '||SQLERRM);
      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
      lc_error_msg := FND_MESSAGE.get;
      FND_FILE.PUT_LINE (FND_FILE.LOG,lc_error_msg);
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'XX_AR_CREATE_ACCT_PKG'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Error at ' || lc_error_loc
                                     ,p_error_message_count     => ln_msg_cnt+1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => SQLERRM
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts');



 END XX_AR_CREATE_ACCT_PROC;


-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name :        XX_GET_GL_COA                                         |
-- | Description : proceudure to derive segments                         |
-- | Parameters : p_oloc,p_sloc,p_line_id,p_acc_class,p_rev_account      |
-- | Returns    : x_company,x_costcenter,x_account,x_location,           |
-- |              x_intercompany,x_lob,x_future,x_ccid,x_error_message   |
-- +=====================================================================+
   PROCEDURE XX_GET_GL_COA(
    p_oloc         IN VARCHAR2
   ,p_sloc         IN VARCHAR2
   ,p_oloc_type    IN VARCHAR2
   ,p_sloc_type    IN VARCHAR2
   ,p_line_id      IN NUMBER
   ,p_acc_class    IN VARCHAR2
   ,p_rev_account  IN VARCHAR2
   ,p_cust_type    IN VARCHAR2
   ,p_trx_type     IN VARCHAR2
   ,p_log_flag     IN VARCHAR2 --Defect 3418
   ,x_company      OUT VARCHAR2
   ,x_costcenter   OUT VARCHAR2
   ,x_account      OUT VARCHAR2
   ,x_location     OUT VARCHAR2
   ,x_intercompany OUT VARCHAR2
   ,x_lob          OUT VARCHAR2
   ,x_future       OUT VARCHAR2
   ,x_ccid         OUT VARCHAR2
   ,x_error_message OUT VARCHAR2
   )
   AS
     lt_tbl_ora_segments           FND_FLEX_EXT.SEGMENTARRAY;
     lc_concat_segments            VARCHAR2(2000);
     lc_ccid_enabled_flag          VARCHAR2(1);
     lb_return                     BOOLEAN;
     lc_ccid_exist_flag            VARCHAR2(1);
     lc_error_message              VARCHAR2(4000);
     lc_error_loc                  VARCHAR2(2000);
     lc_error_debug                VARCHAR2(2000);
     lc_coa_id                     gl_sets_of_books.chart_of_accounts_id%TYPE;
     ln_tot_segments               NUMBER(1):=7;
     lc_error_msg                  VARCHAR2(4000);
     ln_user_id                    NUMBER;
     ln_resp_id                    NUMBER;
     ln_resp_appl_id               NUMBER;
     lc_ora_company                gl_code_combinations.segment1%TYPE;
     lc_ora_cost_center            gl_code_combinations.segment2%TYPE := '00000';
     lc_ora_account                gl_code_combinations.segment3%TYPE;
     lc_ora_location               gl_code_combinations.segment4%TYPE;
     lc_ora_intercompany           gl_code_combinations.segment5%TYPE := '0000';
     lc_ora_lob                    gl_code_combinations.segment6%TYPE := '10';
     lc_ora_future                 gl_code_combinations.segment7%TYPE := '000000' ;
     ln_ccid                       NUMBER;
     ln_sob_id                     gl_sets_of_books.set_of_books_id%TYPE;
     lc_store_loc                  VARCHAR2(30) := 'STORE%';
     ln_org_id                     VARCHAR2(30) := FND_PROFILE.VALUE('ORG_ID');
     --lc_trx_type                   VARCHAR2(30); --:= 'US_SA INVOICE_OD';
     lc_temp_transaction_type      ra_cust_trx_types_all.name%TYPE;
     lc_transaction_type           xx_fin_translatevalues.target_value1%TYPE;
     lc_cvr_name                   xx_fin_translatevalues.target_value1%TYPE;
     lc_tax_type_code              gl_tax_option_accounts.tax_type_code%TYPE;
     lc_flex_validation_rule_name  fnd_flex_vdation_rules_vl.flex_validation_rule_name%TYPE;
     lc_error_message_text         fnd_flex_vdation_rules_vl.error_message_text%TYPE;
     lc_concatenated_segments_low  fnd_flex_validation_rule_lines.concatenated_segments_low%TYPE;
     lc_concatenated_segments_high fnd_flex_validation_rule_lines.concatenated_segments_high%TYPE;
     lc_company_segment1_high      fnd_flex_include_rule_lines.segment1_high%TYPE;
     lc_company_segment1_low       fnd_flex_include_rule_lines.segment1_low%TYPE;
     lc_location_segment4_high     fnd_flex_include_rule_lines.segment4_high%TYPE;
     lc_location_segment4_low      fnd_flex_include_rule_lines.segment4_low%TYPE;
     lc_sob_name                   VARCHAR2(240);
     lc_GL_Acc_Start1              xx_fin_translatevalues.source_value1%TYPE;
     lc_GL_Acc_Start2              xx_fin_translatevalues.source_value2%TYPE;
     lc_GL_Acc_Start3              xx_fin_translatevalues.source_value3%TYPE;
     lc_GL_Acc_Start4              xx_fin_translatevalues.source_value4%TYPE;
     lc_GL_Acc_Start5              xx_fin_translatevalues.source_value5%TYPE;
     lc_GL_Acc_Start6              xx_fin_translatevalues.source_value6%TYPE;
     lc_GL_Acc_Start7              xx_fin_translatevalues.source_value7%TYPE;
     lc_GL_Acc_Start9              xx_fin_translatevalues.source_value8%TYPE;
     lc_CC1                        xx_fin_translatevalues.target_value1%TYPE;
     lc_CC2                        xx_fin_translatevalues.target_value2%TYPE;
     lc_CC3                        xx_fin_translatevalues.target_value3%TYPE;
     lc_CC4                        xx_fin_translatevalues.target_value4%TYPE;
     lc_CC5                        xx_fin_translatevalues.target_value5%TYPE;
     lc_CC6                        xx_fin_translatevalues.target_value6%TYPE;
     lc_CC7                        xx_fin_translatevalues.target_value7%TYPE;
     lc_CC9                        xx_fin_translatevalues.target_value8%TYPE;


   BEGIN
   /*BEGIN
               lc_error_loc   := 'Validating Trx type ';
              -- lc_error_debug := lcu_process_records.set_of_books_id;

              SELECT target_value1
              INTO lc_trx_type
              FROM   xx_fin_translatedefinition DEF
                  ,xx_fin_translatevalues VAL
             WHERE  DEF.translate_id = VAL.translate_id
            AND    DEF.translation_name = 'AR_AUTO_ACCOUNTING'
            AND source_value1 = ln_org_id;

             EXCEPTION
     WHEN OTHERS THEN
       --FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
       --FND_MESSAGE.SET_TOKEN('COL','Chart of Account id');
       lc_error_msg :=  'Exception Raised while fetching the trx type';
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg
                                    || FND_PROFILE.VALUE('ORG_ID'));
       XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                       p_program_type            => 'CONCURRENT PROGRAM'
                                      ,p_program_name            => 'OD: AR Create Autoinvoice Accounting'
                                      ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                      ,p_module_name             => 'AR'
                                      ,p_error_location          => 'Oracle Error '||SQLERRM
                                      ,p_error_message_count     => ln_msg_cnt + 1
                                      ,p_error_message_code      => 'E'
                                      ,p_error_message           => lc_error_msg
                                      ,p_error_message_severity  => 'Major'
                                      ,p_notify_flag             => 'N'
                                      ,p_object_type             => 'Creating Accounts'
       );
     END;
     */

     --Fetching CVR name from translation. This translation will have only one row and the target is to be fetched.
  /*   SELECT target_value1
     INTO   lc_cvr_name
     FROM  xx_fin_translatevalues XFTV,
           xx_fin_translatedefinition XFTD
     WHERE XFTD.translate_id=XFTV.translate_id
           AND XFTD.translation_name='GL_E0080_CVR_NAME'
           AND XFTD.enabled_flag='Y'
           AND XFTV.enabled_flag='Y';
   */

     BEGIN
     SELECT GSB.chart_of_accounts_id
     INTO   lc_coa_id
     FROM   gl_sets_of_books GSB
     WHERE  GSB.set_of_books_id = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID');
     EXCEPTION
     WHEN OTHERS THEN

       IF (p_log_flag ='Y') THEN
       FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
       FND_MESSAGE.SET_TOKEN('COL','Chart of Account id');
       lc_error_msg :=  FND_MESSAGE.GET;
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg
                                    || '.Exception Raised While COA id for Set of Books'
                                    || FND_PROFILE.VALUE('GL_SET_OF_BKS_NAME'));
       XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                       p_program_type            => 'CONCURRENT PROGRAM'
                                      ,p_program_name            => 'OD: AR Create Autoinvoice Accounting'
                                      ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                      ,p_module_name             => 'AR'
                                      ,p_error_location          => 'Oracle Error '||SQLERRM
                                      ,p_error_message_count     => ln_msg_cnt + 1
                                      ,p_error_message_code      => 'E'
                                      ,p_error_message           => lc_error_msg
                                      ,p_error_message_severity  => 'Major'
                                      ,p_notify_flag             => 'N'
                                      ,p_object_type             => 'Creating Accounts'
       );
       END IF;

     END;
     IF p_acc_class = 'REV' THEN
        lc_ora_account := p_rev_account;

        ELSIF p_acc_class = 'REC' THEN
        BEGIN
        SELECT GCC.segment3
        INTO   lc_ora_account
        FROM   ra_cust_trx_types_all RCTA
               ,gl_code_combinations  GCC
        WHERE  RCTA.cust_trx_type_id = p_trx_type
        --WHERE  RCTA.cust_trx_type_id = lcu_process_interface_lines.cust_trx_type_id
          --AND org_id = FND_PROFILE.VALUE('ORG_ID')
          --AND  name   = lc_trx_type
          AND  GCC.chart_of_accounts_id = lc_coa_id
          AND  RCTA.gl_id_rec = GCC.code_combination_id;
        EXCEPTION
        WHEN OTHERS THEN
          lc_ora_account := p_rev_account;
          FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
          FND_MESSAGE.SET_TOKEN('COL','Account segment');
          lc_error_msg :=  FND_MESSAGE.GET;
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg
                               || '.Exception Raised While Fetching REC Account');
          XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                          p_program_type            => 'CONCURRENT PROGRAM'
                                         ,p_program_name            => 'OD: AR Create Autoinvoice Accounting'
                                         ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                         ,p_module_name             => 'AR'
                                         ,p_error_location          => 'Oracle Error '||SQLERRM
                                         ,p_error_message_count     => ln_msg_cnt + 1
                                         ,p_error_message_code      => 'E'
                                         ,p_error_message           => lc_error_msg
                                         ,p_error_message_severity  => 'Major'
                                         ,p_notify_flag             => 'N'
                                         ,p_object_type             => 'Creating Accounts'
          );
        END;
        ELSIF p_acc_class = 'TAX' THEN
          -- Assiging other segments
          lc_ora_cost_center  := '00000';
          lc_ora_lob := '90';
          BEGIN

       --Added to remove SOB hardcoding
          SELECT VAL.target_value1
          INTO   lc_sob_name
          FROM   xx_fin_translatedefinition DEF
                ,xx_fin_translatevalues VAL
         WHERE  DEF.translate_id = VAL.translate_id
           AND  DEF.translation_name = 'OD_COUNTRY_DEFAULTS'
           AND  VAL.source_value1 = 'CA';


          SELECT GSB.set_of_books_id
          INTO   ln_sob_id
          FROM   gl_sets_of_books GSB
        --WHERE  GSB.short_name = 'CA_CAD_P';
          WHERE  GSB.short_name = lc_sob_name;

          SELECT tax_account_id
          INTO   ln_ccid
          FROM   ar_vat_tax_all
          WHERE  set_of_books_id = ln_sob_id
          AND    tax_code = ( SELECT   'PST_SALES_'||HL.PROVINCE
                                FROM   APPS.HZ_LOCATIONS HL,
                                       APPS.HZ_CUST_SITE_USES_ALL HCAS
                                WHERE  HL.ORIG_SYSTEM_REFERENCE = substr(HCAS.ORIG_SYSTEM_REFERENCE,1,17)
                                  AND    HCAS.site_use_id = p_sloc
                            ) ;


                            /*(SELECT distinct 'PST_SALES_'|| province
                             FROM  APPS.HZ_LOCATIONS RAA
                             WHERE  RAA.orig_system_reference = p_sloc||'CA'
                             );*/

         IF (p_log_flag ='Y') THEN
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'tax account id:'||ln_ccid);
         END IF;

          -- Derive Account and Location Segment
          SELECT GCC.segment1
                 ,GCC.segment3
                ,GCC.segment4
          INTO   lc_ora_company
                ,lc_ora_account
                ,lc_ora_location
          FROM   gl_code_combinations GCC
                ,gl_sets_of_books    GSB
          WHERE  GCC.code_combination_id   = ln_ccid
          AND    GCC.chart_of_accounts_id  = GSB.chart_of_accounts_id
          AND    GSB.set_of_books_id       = ln_sob_id;

         FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Segs:'||lc_ora_company||lc_ora_account||lc_ora_location);
          -- Deriving CCID
          EXCEPTION
          WHEN OTHERS THEN
            FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
            FND_MESSAGE.SET_TOKEN('COL','Deriving CCID');
            lc_error_msg :=  FND_MESSAGE.GET;
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg
                                  || '.Exception Raised While Fetching Tax Code');
            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'OD: AR Create Autoinvoice Accounting'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => ln_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Creating Accounts'
            );

          END;
        ELSIF p_acc_class = 'UNEARN' THEN
           BEGIN
           SELECT GCC.segment3
           INTO   lc_ora_account
           FROM   ra_cust_trx_types_all RCTA
                  ,gl_code_combinations  GCC
           WHERE  RCTA.cust_trx_type_id = p_trx_type
           --WHERE  RCTA.cust_trx_type_id = lcu_process_interface_lines.cust_trx_type_id
             --org_id = FND_PROFILE.VALUE('ORG_ID')
             --AND  name = lc_trx_type
             AND  GCC.chart_of_accounts_id = lc_coa_id
             AND  RCTA.gl_id_unbilled = GCC.code_combination_id;
           EXCEPTION
           WHEN OTHERS THEN
             FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
             FND_MESSAGE.SET_TOKEN('COL','Deriving Account for UNEARN ');
             lc_error_msg := FND_MESSAGE.GET;
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg
                                  || '.Exception Raised while fetching  account');
             XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                             p_program_type            => 'CONCURRENT PROGRAM'
                                            ,p_program_name            => 'OD: AR Create Autoinvoice Accounting'
                                            ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                            ,p_module_name             => 'AR'
                                            ,p_error_location          => 'Oracle Error '||SQLERRM
                                            ,p_error_message_count     => ln_msg_cnt + 1
                                            ,p_error_message_code      => 'E'
                                            ,p_error_message           => lc_error_msg
                                            ,p_error_message_severity  => 'Major'
                                            ,p_notify_flag             => 'N'
                                            ,p_object_type             => 'Creating Accounts'
             );

           END;
        END IF;



     BEGIN



     IF NVL(p_oloc_type,1) LIKE lc_store_loc AND p_sloc_type LIKE lc_store_loc THEN
/*
       SELECT segment1_high
             ,segment4_high
       INTO  lc_ora_company
             ,lc_ora_location
       FROM   fnd_flex_include_rule_lines FFIRL
       WHERE  application_id = 101
         AND  id_flex_code='GL#'
         AND  flex_validation_rule_name = lc_cvr_name
         AND  p_oloc BETWEEN segment4_low AND segment4_high
         AND  enabled_flag = 'Y';
*/
--Code added for defect 3287. replaced the above sql with the below two lines.


        lc_ora_company  := XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION(LTRIM(RTRIM(p_oloc)));
        lc_ora_location := LTRIM(RTRIM(p_oloc));

       x_company      := lc_ora_company;
       x_costcenter   := lc_ora_cost_center;
       x_account      := lc_ora_account;
       x_location     := lc_ora_location;
       x_intercompany := lc_ora_intercompany;
       x_lob          := lc_ora_lob;
       x_future       := lc_ora_future;

     ELSIF NVL(p_oloc_type,1) LIKE lc_store_loc AND p_sloc_type NOT LIKE lc_store_loc THEN
/*
        SELECT segment1_high
              ,segment4_high
        INTO   lc_ora_company
              ,lc_ora_location
        FROM   fnd_flex_include_rule_lines FFIRL
        WHERE  application_id = 101
           AND id_flex_code='GL#'
           AND flex_validation_rule_name =lc_cvr_name
           AND p_oloc BETWEEN segment4_low AND segment4_high
           AND enabled_flag = 'Y';
*/

--Code added for defect 3287. replaced the above sql with the below two lines.

        lc_ora_company  := XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION(LTRIM(RTRIM(p_oloc)));
        lc_ora_location := LTRIM(RTRIM(p_oloc));


        x_company      := lc_ora_company;
        x_costcenter   := lc_ora_cost_center;
        x_account      := lc_ora_account;
        x_location     := lc_ora_location;
        x_intercompany := lc_ora_intercompany;
        x_lob          := lc_ora_lob;
        x_future       := lc_ora_future;

     ELSIF NVL(p_oloc_type,1) NOT LIKE lc_store_loc AND p_sloc_type LIKE lc_store_loc THEN
/*
       SELECT segment1_high
             ,segment4_high
       INTO   lc_ora_company
             ,lc_ora_location
       FROM   fnd_flex_include_rule_lines FFIRL
       WHERE  application_id = 101
         AND  id_flex_code='GL#'
         AND  flex_validation_rule_name = lc_cvr_name
         AND  p_sloc BETWEEN segment4_low AND segment4_high
         AND  enabled_flag = 'Y';
*/

--Code added for defect 3287. replaced the above sql with the below two lines.


        lc_ora_company  := XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION(LTRIM(RTRIM(p_sloc)));
        lc_ora_location := LTRIM(RTRIM(p_sloc));

       x_company      := lc_ora_company;
       x_costcenter   := lc_ora_cost_center;
       x_account      := lc_ora_account;
       x_location     := lc_ora_location;
       x_intercompany := lc_ora_intercompany;
       x_lob          := lc_ora_lob;
       x_future       := lc_ora_future;

     ELSIF NVL(p_oloc_type,1) NOT LIKE lc_store_loc AND p_sloc_type NOT LIKE lc_store_loc THEN
/*
        SELECT  segment1_high
               ,segment4_high
        INTO    lc_ora_company
               ,lc_ora_location
        FROM    fnd_flex_include_rule_lines FFIRL
        WHERE   application_id = 101
          AND     id_flex_code = 'GL#'
          AND     flex_validation_rule_name = lc_cvr_name
          AND     p_sloc BETWEEN segment4_low AND segment4_high
          AND     enabled_flag = 'Y';
*/
      --Code added for defect 3287. replaced the above sql with the below two lines.


        lc_ora_company  := XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION(LTRIM(RTRIM(p_sloc)));
        lc_ora_location := LTRIM(RTRIM(p_sloc));

          -- Modified to check the Uppercase of Customer Type on 12-13-07
          IF UPPER(p_cust_type) = 'DIRECT' Then
             --lc_ora_lob := '50';

            SELECT FFVV.FLEX_VALUE
            INTO   lc_ora_lob
            FROM   APPS.FND_FLEX_VALUE_SETS FFVS,
                   APPS.FND_FLEX_VALUES_VL  FFVV
            WHERE  FFVS.FLEX_VALUE_SET_NAME = 'OD_GL_GLOBAL_LOB'
            AND    FFVS.FLEX_VALUE_SET_ID   = FFVV.FLEX_VALUE_SET_ID
            AND    UPPER(FFVV.DESCRIPTION)  = UPPER(p_cust_type) ;

          ELSIF UPPER(p_cust_type) = 'CONTRACT' Then
             --lc_ora_lob := '40';

            SELECT FFVV.FLEX_VALUE
            INTO   lc_ora_lob
            FROM   APPS.FND_FLEX_VALUE_SETS FFVS,
                   APPS.FND_FLEX_VALUES_VL  FFVV
            WHERE  FFVS.FLEX_VALUE_SET_NAME = 'OD_GL_GLOBAL_LOB'
            AND    FFVS.FLEX_VALUE_SET_ID   = FFVV.FLEX_VALUE_SET_ID
            AND    UPPER(FFVV.DESCRIPTION)  = UPPER(p_cust_type) ;

          END IF;

        x_company      := lc_ora_company;
        x_costcenter   := lc_ora_cost_center;
        x_account      := lc_ora_account;
        x_location     := lc_ora_location;
        x_intercompany := lc_ora_intercompany;
        x_lob          := lc_ora_lob;
        x_future       := lc_ora_future;

     END IF;

     EXCEPTION
     when too_many_rows THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Same location range defined for different companies. Error message= '||sqlerrm);
     WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_NO_DATA');
       FND_MESSAGE.SET_TOKEN('COL','Deriving Accounts');
       lc_error_msg := FND_MESSAGE.GET;
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg
                            || '.Exception Raised while fetching Company,Location Segment');
       XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                       p_program_type            => 'CONCURRENT PROGRAM'
                                      ,p_program_name            => 'OD: AR Create Autoinvoice Accounting'
                                      ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                      ,p_module_name             => 'AR'
                                      ,p_error_location          => 'Oracle Error '||SQLERRM
                                      ,p_error_message_count     => ln_msg_cnt + 1
                                      ,p_error_message_code      => 'E'
                                      ,p_error_message           => lc_error_msg
                                      ,p_error_message_severity  => 'Major'
                                      ,p_notify_flag             => 'N'
                                      ,p_object_type             => 'Creating Accounts'
       );
     END;

       --Substituting the hard code of the Cost Center and account with translation values.

       select
              source_value1,
              source_value2,
              source_value3,
              source_value4,
              source_value5,
              source_value6,
              source_value7,
              source_value8,
              target_value1,
              target_value2,
              target_value3,
              target_value4,
              target_value5,
              target_value6,
              target_value7,
              target_value8
       INTO
              lc_GL_Acc_Start1,
              lc_GL_Acc_Start2,
              lc_GL_Acc_Start3,
              lc_GL_Acc_Start4,
              lc_GL_Acc_Start5,
              lc_GL_Acc_Start6,
              lc_GL_Acc_Start7,
              lc_GL_Acc_Start9,
              lc_CC1,
              lc_CC2,
              lc_CC3,
              lc_CC4,
              lc_CC5,
              lc_CC6,
              lc_CC7,
              lc_CC9
       FROM   xx_fin_translatevalues XFTV,
              xx_fin_translatedefinition XFTD
       WHERE  XFTD.translate_id=XFTV.translate_id
              AND XFTD.translation_name='GL_E0080_DEFAULT_CC'
              AND XFTD.enabled_flag='Y'
              AND XFTV.enabled_flag='Y';


       IF SUBSTR(lc_ora_account,1,1) = lc_GL_Acc_Start1  THEN
             lc_ora_cost_center   := lc_CC1;
       ELSIF SUBSTR(lc_ora_account,1,1) = lc_GL_Acc_Start2 THEN
             lc_ora_cost_center   := lc_CC2;
       ELSIF SUBSTR(lc_ora_account,1,1) = lc_GL_Acc_Start3 THEN
             lc_ora_cost_center   := lc_CC3;
       ELSIF SUBSTR(lc_ora_account,1,1) = lc_GL_Acc_Start4 THEN
             lc_ora_cost_center   := lc_CC4;
       ELSIF SUBSTR(lc_ora_account,1,1) = lc_GL_Acc_Start5 THEN
             lc_ora_cost_center   := lc_CC5;
       ELSIF SUBSTR(lc_ora_account,1,1) = lc_GL_Acc_Start6 THEN
             lc_ora_cost_center   := lc_CC6;
       ELSIF SUBSTR(lc_ora_account,1,1) = lc_GL_Acc_Start7 THEN
             lc_ora_cost_center   := lc_CC7;
       ELSIF SUBSTR(lc_ora_account,1,1) = lc_GL_Acc_Start9 THEN
             lc_ora_cost_center   := lc_CC9;
       END IF;

         IF  lc_ora_company       IS NOT NULL
         AND lc_ora_cost_center   IS NOT NULL
         AND lc_ora_account       IS NOT NULL
         AND lc_ora_location      IS NOT NULL
         AND lc_ora_intercompany  IS NOT NULL
         AND lc_ora_lob           IS NOT NULL
         AND lc_ora_future        IS NOT NULL
         THEN

         lc_concat_segments := lc_ora_company ||  '.' || lc_ora_cost_center || '.' ||
                                lc_ora_account ||  '.' || lc_ora_location || '.' ||
                                lc_ora_intercompany ||  '.' || lc_ora_lob || '.' ||
                                lc_ora_future;

         BEGIN
            SELECT GCC.code_combination_id
                   ,GCC.enabled_flag
            INTO   ln_ccid
                   ,lc_ccid_enabled_flag
            FROM   gl_code_combinations GCC
                   ,gl_sets_of_books    GSB
            WHERE  GCC.SEGMENT1 = lc_ora_company
               AND GCC.SEGMENT2 = lc_ora_cost_center
               AND GCC.SEGMENT3 = lc_ora_account
               AND GCC.SEGMENT4 = lc_ora_location
               AND GCC.SEGMENT5 = lc_ora_intercompany
               AND GCC.SEGMENT6 = lc_ora_lob
               AND GCC.SEGMENT7 = lc_ora_future
               AND GCC.chart_of_accounts_id = GSB.chart_of_accounts_id
               AND GSB.set_of_books_id = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID');
               lc_ccid_exist_flag := 'Y';

         IF lc_ccid_enabled_flag <> 'Y' THEN
             IF (p_log_flag ='Y') THEN
             FND_FILE.PUT_LINE (FND_FILE.LOG,'Account Combination is not enabled for Oracle Segment : '
                                             || lc_concat_segments);
             END IF;

         ELSE

            IF (p_log_flag ='Y') THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG,'Derived '
                                   || p_acc_class || ' Oracle Segment : ' || lc_concat_segments);
            END IF;

         END IF;
         EXCEPTION
         WHEN OTHERS THEN
           lc_ccid_exist_flag := 'N';
         END;

         IF lc_ccid_exist_flag = 'N' THEN
            ln_user_id := fnd_global.user_id;
            ln_resp_id := fnd_global.resp_id;
            ln_resp_appl_id := fnd_global.resp_appl_id;
            FND_GLOBAL.APPS_INITIALIZE (ln_user_id, ln_resp_id, ln_resp_appl_id);
            lb_return := fnd_flex_keyval.validate_segs(
                                                       OPERATION         => 'CHECK_COMBINATION'
                                                      ,APPL_SHORT_NAME   => 'SQLGL'
                                                      ,KEY_FLEX_CODE     => 'GL#'
                                                      ,STRUCTURE_NUMBER  => lc_coa_id
                                                      ,CONCAT_SEGMENTS   => lc_concat_segments
                                                      );

            IF lb_return = FALSE  THEN
               x_error_message := x_error_message || 'GL Cross Validation Rule does not allow to create CCID for Oracle Segments:'
                           || lc_concat_segments;
               FND_FILE.PUT_LINE (FND_FILE.LOG,'GL Cross Validation Rule does not allow to create CCID for Oracle Segments');
            ELSE
               lt_tbl_ora_segments(1) := lc_ora_company;
               lt_tbl_ora_segments(2) := lc_ora_cost_center;
               lt_tbl_ora_segments(3) := lc_ora_account;
               lt_tbl_ora_segments(4) := lc_ora_location;
               lt_tbl_ora_segments(5) := lc_ora_intercompany;
               lt_tbl_ora_segments(6) := lc_ora_lob;
               lt_tbl_ora_segments(7) := lc_ora_future;

               lb_return   := FND_FLEX_EXT.GET_COMBINATION_ID(
                                                             application_short_name => 'SQLGL'
                                                             ,key_flex_code         => 'GL#'
                                                             ,structure_number      => lc_coa_id
                                                             ,validation_date       => SYSDATE
                                                             ,n_segments            => ln_tot_segments
                                                             ,segments              => lt_tbl_ora_segments
                                                             ,combination_id        => ln_ccid
                                                             );
                /*FND_FILE.PUT_LINE (FND_FILE.LOG,'Account Combination created for '  || p_acc_class
                                                || ' Oracle Segment : ' || lc_concat_segments);*/
            END IF;

            x_ccid := ln_ccid;
         ELSE
            x_error_message := 'To get CCID, all the Oracle segments are required';
         END IF;

         END IF;

         x_company      := lc_ora_company;
         x_costcenter   := lc_ora_cost_center;
         x_account      := lc_ora_account;
         x_location     := lc_ora_location;
         x_intercompany := lc_ora_intercompany;
         x_lob          := lc_ora_lob;
         x_future       := lc_ora_future;
         x_ccid         := ln_ccid;

      EXCEPTION
      WHEN NO_DATA_FOUND THEN
         lc_error_loc     := 'Exception Raised while Derving GL COA='
                                                                 || lc_concat_segments;
         lc_error_debug   := 'GET_GL_COA';
         lc_error_message := 'Exception raised ' || SQLERRM;
         x_error_message := x_error_message || lc_error_message || lc_error_loc || lc_error_debug;

       FND_FILE.PUT_LINE (FND_FILE.LOG,x_error_message);
       FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
       FND_MESSAGE.SET_TOKEN('COL','Deriving Accounts');
       lc_error_msg := FND_MESSAGE.GET;
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg
                            || '.Exception Raised while fetching Company,Location Segment');
       XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                       p_program_type            => 'CONCURRENT PROGRAM'
                                      ,p_program_name            => 'OD: AR Create Autoinvoice Accounting'
                                      ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                      ,p_module_name             => 'AR'
                                      ,p_error_location          => 'Oracle Error '||SQLERRM
                                      ,p_error_message_count     => ln_msg_cnt + 1
                                      ,p_error_message_code      => 'E'
                                      ,p_error_message           => lc_error_msg
                                      ,p_error_message_severity  => 'Major'
                                      ,p_notify_flag             => 'N'
                                      ,p_object_type             => 'Creating Accounts'
        );
      WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
       FND_MESSAGE.SET_TOKEN('COL','Deriving Accounts');
       lc_error_msg := FND_MESSAGE.GET;
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg
                            || '.Exception Raised while fetching Company,Location Segment');
       XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                       p_program_type            => 'CONCURRENT PROGRAM'
                                      ,p_program_name            => 'OD: AR Create Autoinvoice Accounting'
                                      ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                      ,p_module_name             => 'AR'
                                      ,p_error_location          => 'Oracle Error '||SQLERRM
                                      ,p_error_message_count     => ln_msg_cnt + 1
                                      ,p_error_message_code      => 'E'
                                      ,p_error_message           => lc_error_msg
                                      ,p_error_message_severity  => 'Major'
                                      ,p_notify_flag             => 'N'
                                      ,p_object_type             => 'Creating Accounts'
       );
    END XX_GET_GL_COA;

END  XX_AR_CREATE_ACCT_PKG;
/
SHO ERR;