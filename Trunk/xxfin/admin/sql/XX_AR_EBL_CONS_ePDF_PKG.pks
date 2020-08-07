SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE SPEC XX_AR_EBL_CONS_EPDF_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

 CREATE OR REPLACE
 PACKAGE apps.XX_AR_EBL_CONS_EPDF_PKG
 AS
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : XX_AR_EBL_CONS_EPDF_PKG                                             |
-- | Description : This Package is used to get the Consolidated Bills through ePDF.    |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 15-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- |      1.1 03-JUN-2016  Havish Kasina           Kitting Changes (Defect 37675)      |
-- |      1.2 27-FEB-2018  Atul Khard              trx_rec type change order_type_code |
-- |                                               size change to VARCHAR2(4)(Defect   |
-- |                                               44398)                              |
-- |      1.3 30-Aug-2018  Sravan Basireddy        Changes done for SKU Level Tax,     |
-- |                                               NAIT-58403                          |
-- +===================================================================================+

    TYPE trx_rec IS RECORD ( sfdata1                          VARCHAR2(120)
                            ,sfdata2                          VARCHAR2(120)
                            ,sfdata3                          VARCHAR2(120)
                            ,sfdata4                          VARCHAR2(120)
                            ,sfdata5                          VARCHAR2(120)
                            ,sfdata6                          VARCHAR2(120)
                            ,sfhdr1                           VARCHAR2(60)
                            ,sfhdr2                           VARCHAR2(60)
                            ,sfhdr3                           VARCHAR2(60)
                            ,sfhdr4                           VARCHAR2(60)
                            ,sfhdr5                           VARCHAR2(60)
                            ,sfhdr6                           VARCHAR2(60)
                            ,customer_trx_id                  NUMBER
                            ,order_header_id                  NUMBER
                            --,inv_source_id                    NUMBER
                            ,inv_number                       VARCHAR2(20)
                            ,inv_type                         VARCHAR2(20)
                            ,inv_source                       VARCHAR2(30)
                            ,order_date                       DATE
                            ,order_type_code                  VARCHAR2(4)--Changed for Defect 44398
                            ,ship_date                        DATE
                            ,original_order_number            VARCHAR2(50)
                            ,original_invoice_amount          NUMBER
                            ,spc_comment                      VARCHAR2(100)
                            ,gift_amount                      NUMBER
                            ,td_amount                        NUMBER
                            ,bill_to_address1                 VARCHAR2(240)
                            ,bill_to_address2                 VARCHAR2(240)
                            ,bill_to_address3                 VARCHAR2(240)
                            ,bill_to_address4                 VARCHAR2(240)
                            ,bill_to_state                    VARCHAR2(60)
                            ,bill_to_city                     VARCHAR2(60)
                            ,bill_to_zip                      VARCHAR2(60)
                            ,bill_to_country                  VARCHAR2(60)
                            ,remit_address1                   VARCHAR2(240)
                            ,remit_address2                   VARCHAR2(240)
                            ,remit_address3                   VARCHAR2(240)
                            ,remit_address4                   VARCHAR2(240)
                            ,remit_state                      VARCHAR2(60)
                            ,remit_city                       VARCHAR2(60)
                            ,remit_zip                        VARCHAR2(60)
                            ,remit_country                    VARCHAR2(60)
                            ,order_subtotal                   NUMBER
                            ,delvy_charges                    NUMBER
                            ,order_discount                   NUMBER
                            ,order_tax                        NUMBER
                            );

    p_conc_name            VARCHAR2(15);
    p_appl_name            VARCHAR2(5);
    p_batch_id             NUMBER;
    p_debug_flag           VARCHAR2(1);
/*
    p_request_id           NUMBER;
    p_spl_handling_flag    VARCHAR2(1);
    p_cons_bill_num        ar_cons_inv_all.cons_billing_number%TYPE;
    p_date_from            DATE;
    p_date_to              DATE;
    p_cust_account_id      hz_cust_accounts.cust_account_id%TYPE;
    p_multiple_bills       VARCHAR2(250);
    p_cust_doc_id          NUMBER;
    p_infocopy_flag        VARCHAR2(1);
    p_mbs_document_id      NUMBER;
*/
    p_cm_text1             VARCHAR2(50);
    p_cm_text2             VARCHAR2(50);
    p_gift_card_text1      VARCHAR2(50);
    p_gift_card_text2      VARCHAR2(50);
    p_gift_card_text3      VARCHAR2(50);

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : MULTI_THREAD_ePDF                                                   |
-- | Description : This Procedure is used to multi thread the bills getting printed    |
-- |               through ePDF. The number of consolidated bills in each thread is    |
-- |               controlled using the batch size.                                    |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 15-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE MULTI_THREAD_EPDF ( x_error_buff                 OUT VARCHAR2
                                 ,x_retcode                    OUT NUMBER
                                 ,p_batch_size                 IN  NUMBER
                                 ,p_thread_count               IN  NUMBER
                                 ,p_debug_flag                 IN  VARCHAR2
                                 ,p_del_meth                   IN  VARCHAR2
                                 ,p_doc_type                   IN  VARCHAR2
                                 ,p_cycle_date                 IN  VARCHAR2
                                 );

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : SUBMIT_ePDF_CHILD                                                   |
-- | Description : This Procedure is used to submit the exact ePDF pgm and the         |
-- |               bursting program.                                                   |
-- | Parameters   :                                                                    |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 14-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE SUBMIT_EPDF_CHILD ( x_error_buff                 OUT VARCHAR2
                                 ,x_retcode                    OUT NUMBER
                                 ,p_appl_name                  IN  VARCHAR2
                                 ,p_conc_name                  IN  VARCHAR2
                                 ,p_batch_id                   IN  NUMBER
                                 ,p_debug_flag                 IN  VARCHAR2
                                 ,p_cm_text1                   IN  VARCHAR2
                                 ,p_cm_text2                   IN  VARCHAR2
                                 ,p_gift_card_text1            IN  VARCHAR2
                                 ,p_gift_card_text2            IN  VARCHAR2
                                 ,p_gift_card_text3            IN  VARCHAR2
                                 ,p_del_meth                   IN  VARCHAR2
                                 ,p_doc_type                   IN  VARCHAR2
                                 ,p_cycle_date                 IN  VARCHAR2
                                 );

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : BEFOREREPORT                                                        |
-- | Description : This function is used to insert records into the custom tables      |
-- |               according to the document level.                                    |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 16-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    FUNCTION beforereport
    RETURN BOOLEAN;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GET_DYNAMIC_SQL                                                     |
-- | Description : This function is used to get the dynamic sql for the consolidated   |
-- |               bill numnber.                                                       |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 16-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+

    FUNCTION GET_DYNAMIC_SQL( p_sort_order         IN VARCHAR2
                             ,p_master_alias       IN VARCHAR2
                             ,p_spl_handling_flag  IN VARCHAR2
                             )
    RETURN VARCHAR2;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GET_ORDER_BY_SQL                                                    |
-- | Description : This function is used to get the order by clause for the dynamic    |
-- |               sql.                                                                |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 16-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+

    FUNCTION GET_ORDER_BY_SQL( p_sort_order   IN VARCHAR2
                              ,p_master_alias IN VARCHAR2
                              ,p_lc_sort      IN VARCHAR2 DEFAULT ''
                              )
    RETURN VARCHAR2;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GENERATE_DETAIL_SUBTOTALS                                           |
-- | Description : This Procedure is used to calculate the subtotals for detail        |
-- |               document type.                                                      |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 17-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE GENERATE_DETAIL_SUBTOTALS  ( p_billing_id              IN VARCHAR2
                                          ,p_cons_id                 IN NUMBER
                                          ,p_cust_doc_id             IN NUMBER
                                          ,p_site_use_id             IN NUMBER
                                          ,p_reqs_id                 IN NUMBER
                                          ,p_total_by                IN VARCHAR2
                                          ,p_page_by                 IN VARCHAR2
                                          ,p_doc_type                IN VARCHAR2
                                          );

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GENERATE_SUMM_ONE_SUBTOTALS                                         |
-- | Description : This Procedure is used to calculate the subtotals for summary and   |
-- |               one document type.                                                  |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 17-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE GENERATE_SUMM_ONE_SUBTOTALS ( p_billing_id              IN VARCHAR2
                                           ,p_cons_id                 IN NUMBER
                                           ,p_cust_doc_id             IN NUMBER
                                           ,p_site_use_id             IN NUMBER
                                           ,p_reqs_id                 IN NUMBER
                                           ,p_total_by                IN VARCHAR2
                                           ,p_page_by                 IN VARCHAR2
                                           ,p_doc_type                IN VARCHAR2
                                           );

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : INSERT_TRANSACTIONS                                                 |
-- | Description : This Procedure is used to insert transaction into the custom table  |
-- |               XX_AR_EBL_CONS_TRX_STG.                                             |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 17-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE INSERT_TRANSACTIONS( p_sfdata1              IN VARCHAR2
                                  ,p_sfdata2              IN VARCHAR2
                                  ,p_sfdata3              IN VARCHAR2
                                  ,p_sfdata4              IN VARCHAR2
                                  ,p_sfdata5              IN VARCHAR2
                                  ,p_sfdata6              IN VARCHAR2
                                  ,p_sfhdr1               IN VARCHAR2
                                  ,p_sfhdr2               IN VARCHAR2
                                  ,p_sfhdr3               IN VARCHAR2
                                  ,p_sfhdr4               IN VARCHAR2
                                  ,p_sfhdr5               IN VARCHAR2
                                  ,p_sfhdr6               IN VARCHAR2
                                  ,p_inv_id               IN NUMBER
                                  ,p_ord_id               IN NUMBER
                                  --,p_src_id               IN NUMBER
                                  ,p_inv_num              IN VARCHAR2
                                  ,p_inv_type             IN VARCHAR2
                                  ,p_inv_src              IN VARCHAR2
                                  ,p_ord_dt               IN DATE
                                  ,p_ship_dt              IN DATE
                                  ,p_cons_id              IN NUMBER
                                  ,p_cust_doc_id          IN NUMBER
                                  ,p_reqs_id              IN NUMBER
                                  ,p_subtot               IN NUMBER
                                  ,p_delvy                IN NUMBER
                                  ,p_disc                 IN NUMBER
                                  ,p_US_tax_amt           IN NUMBER
                                  ,p_CA_gst_amt           IN NUMBER
                                  ,p_CA_tax_amt           IN NUMBER
                                  ,p_US_tax_id            IN VARCHAR2
                                  ,p_CA_gst_id            IN VARCHAR2
                                  ,p_CA_prov_id           IN VARCHAR2
                                  ,p_insert_seq           IN NUMBER
                                  ,p_doc_tag              IN VARCHAR2
                                  ,p_cbi_num              IN VARCHAR2
                                  ,p_site_use_id          IN NUMBER
                                  ,p_bill_to_address      IN VARCHAR2
                                  ,p_remit_address        IN VARCHAR2
                                  );

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : INSERT_TRX_LINES                                                    |
-- | Description : This Procedure is used to insert the transaction lines information  |
-- |               into the custom table XX_AR_EBL_CONS_LINES_STG.                     |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 17-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- |      1.1 08-DEC-2015  Havish Kasina           Added new parameters p_dept_code,   |
-- |                                               p_dept_desc and p_dept_sft_hdr      |
-- |                                               Defect 36437 (MOD 4B Release 3)     |
-- |      1.2 03-JUN-2016  Havish Kasina           Added a new parameter p_kit_sku for |
-- |                                               kitting changes (Defect 37675)      |
-- |      1.3 30-Aug-2018  Sravan Basireddy        Changes done for SKU Level Tax,     |
-- |                                               NAIT-58403                          |
-- +===================================================================================+
    PROCEDURE INSERT_TRX_LINES ( p_reqs_id                   IN NUMBER
                                ,p_cons_id                   IN NUMBER
                                ,p_cust_doc_id               IN NUMBER
                                ,p_inv_id                    IN NUMBER
                                ,p_line_seq                  IN NUMBER
                                ,p_item_code                 IN VARCHAR2
                                ,p_customer_product_code     IN VARCHAR2
                                ,p_item_description          IN VARCHAR2
                                ,p_manuf_code                IN VARCHAR2
                                ,p_qty                       IN NUMBER
                                ,p_uom                       IN VARCHAR2
                                ,p_unit_price                IN NUMBER
                                ,p_extended_price            IN NUMBER
                                ,p_line_comments             IN VARCHAR2
                                ,p_site_use_id               IN NUMBER
                                ,p_gsa_comments              IN VARCHAR2
                                ,p_dept_code                 IN VARCHAR2 -- Added for the Defect 36437
                                ,p_dept_desc                 IN VARCHAR2 -- Added for the Defect 36437
								,p_dept_sft_hdr              IN VARCHAR2 -- Added for the Defect 36437
								,p_kit_sku                   IN VARCHAR2 -- Added for Kitting, Defect# 37675
								,p_kit_sku_desc              IN VARCHAR2 -- Added for Kitting, Defect# 37675
								,p_sku_level_tax             IN NUMBER   -- Added for SKU Level Tax NAIT-58403
                                );

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : INSERT_TRX_ROWS                                                     |
-- | Description : This Procedure is used to insert the transaction lines information  |
-- |               into the custom table XX_AR_EBL_CONS_TRX_ROWS_STG.                  |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 17-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE INSERT_TRX_ROWS ( p_reqs_id         IN NUMBER
                               ,p_cons_id         IN NUMBER
                               ,p_cust_doc_id     IN NUMBER
                               ,p_line_type       IN VARCHAR2
                               ,p_line_seq        IN NUMBER
                               ,p_sf_text         IN VARCHAR2
                               ,p_pg_brk          IN VARCHAR2
                               ,p_ordnum_attr1    IN VARCHAR2
                               ,p_ord_dt_attr2    IN VARCHAR2
                               ,p_subtotal        IN VARCHAR2
                               ,p_delivery        IN VARCHAR2
                               ,p_discounts       IN VARCHAR2
                               ,p_tax             IN VARCHAR2
                               ,p_total           IN VARCHAR2
                               ,p_sf_data1        IN VARCHAR2
                               ,p_sf_data2        IN VARCHAR2
                               ,p_sf_data3        IN VARCHAR2
                               ,p_sf_data4        IN VARCHAR2
                               ,p_sf_data5        IN VARCHAR2
                               ,p_invoice_id      IN NUMBER
                               ,p_site_use_id     IN NUMBER
                               );

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : INSERT_TRX_TOTALS                                                   |
-- | Description : This Procedure is used to insert the transaction's sub total        |
-- |               information into the custom table XX_AR_EBL_CONS_TRX_TOTAL_STG.     |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 17-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE INSERT_TRX_TOTALS ( p_reqs_id        IN NUMBER
                                 ,p_cons_id        IN NUMBER
                                 ,p_cust_doc_id    IN NUMBER
                                 ,p_inv_id         IN NUMBER
                                 ,p_linetype       IN VARCHAR2
                                 ,p_line_seq       IN NUMBER
                                 ,p_trx_num        IN VARCHAR2
                                 ,p_sftext         IN VARCHAR2
                                 ,p_sfamount       IN NUMBER
                                 ,p_page_brk       IN VARCHAR2
                                 ,p_ord_count      IN NUMBER
                                 ,p_prov_tax       IN VARCHAR2
                                 ,p_site_use_id    IN NUMBER
                                 );

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : INSERT_SUMM_ONE_TOTALS                                              |
-- | Description : This Procedure is used to insert the transaction information into   |
-- |               the custom table XX_AR_EBL_CONS_TRX_STG for Summary and One format. |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 17-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE INSERT_SUMM_ONE_TOTALS ( p_reqs_id       IN NUMBER
                                      ,p_cons_id       IN NUMBER
                                      ,p_cust_doc_id   IN NUMBER
                                      ,p_inv_id        IN NUMBER
                                      ,p_inv_num       IN VARCHAR2
                                      ,p_line_seq      IN NUMBER
                                      ,p_total_type    IN VARCHAR2
                                      ,p_inv_source    IN VARCHAR2
                                      ,p_subtotl       IN NUMBER
                                      ,p_delvy         IN NUMBER
                                      ,p_discounts     IN NUMBER
                                      ,p_tax           IN NUMBER
                                      ,p_page_brk      IN VARCHAR2
                                      ,p_ord_count     IN NUMBER
                                      ,p_site_use_id   IN NUMBER
                                      );
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : RETURN_ADDRESS                                                      |
-- | Description : This funciton is used to get the return address for the Consolidated|
-- |               Bill.                                                               |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 01-APR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
     FUNCTION RETURN_ADDRESS
     RETURN VARCHAR2;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GET_TRX_SEQ                                                         |
-- | Description : This funciton is used to sequence number from                       |
-- |               XX_AR_EBL_CONS_TRX_STG_s sequence.                                  |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 01-APR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    FUNCTION GET_TRX_SEQ
    RETURN NUMBER;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GET_ROWS_SEQ                                                        |
-- | Description : This funciton is used to sequence number from                       |
-- |               XX_AR_EBL_CONS_TRX_ROWS_STG_S sequence.                             |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 01-APR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    FUNCTION GET_ROWS_SEQ
    RETURN NUMBER;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : AFTERREPORT                                                         |
-- | Description : This function is used to do all the post processing like bursting   |
-- |               inserting BLOB file into table after the XML data is generated      |
-- |               for the current thread.                                             |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 16-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    FUNCTION afterreport
    RETURN BOOLEAN;

 END XX_AR_EBL_CONS_EPDF_PKG;
/
SHOW ERRORS;