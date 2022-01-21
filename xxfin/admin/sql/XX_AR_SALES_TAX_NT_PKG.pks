 SET SHOW OFF
 SET VERIFY OFF
 SET ECHO OFF
 SET TAB OFF
 SET FEEDBACK OFF
 SET TERM ON

 PROMPT Creating Package Specification XX_AR_SALES_TAX_AMT_PKG
 PROMPT Program exits if the creation is not successful
 WHENEVER SQLERROR CONTINUE

 CREATE OR REPLACE PACKAGE XX_AR_SALES_TAX_AMT_PKG
 AS

 -- +===================================================================+
 -- |                  Office Depot - Project Simplify                  |
 -- |                       WIPRO Technologies                          |
 -- +===================================================================+
 -- | Name        : Extract Program for Sales and Tax Collected Amount  |
 -- |               for Non-Office supply items.                        |
 -- | Description :                                                     |
 -- |Change Record:                                                     |
 -- |===============                                                    |
 -- |Version   Date          Author              Remarks                |
 -- |=======   ==========   =============        =======================|
 -- |1.0       31-DEC-2007  Hemalatha.S          Initial version        |
 -- |                       Wipro Technologies                          |
 -- +===================================================================+
 -- +===================================================================+
 -- | Name        : NT_SALES_TAX_AMT                                    |
 -- | Description : Extracts the sales and tax collected on non-office  |
 -- |               supply items and copies on to a data file.          |
 -- |                                                                   |
 -- | Parameters  : x_error_buff, x_ret_code,p_state,p_store,p_company  |
 -- |              ,p_date_of_revenue_recog,p_gsc_code,p_file_path      |
 -- |              ,p_dest_file_path,p_file_extension                   |
 -- |                                                                   |
 -- | Returns     : Return Code                                         |
 -- |               Error Message                                       |
 -- +===================================================================+

   TYPE ar_sal_tax_rec IS RECORD (
                                  lr_gsc_code                mtl_system_items_b.attribute1%TYPE
                                 ,lr_inventory_location      hr_locations.location_code%TYPE
                                 ,lr_customer_ship_to_state  hz_locations.state%TYPE
                                 ,lr_date_of_revenue_recog   VARCHAR2(15)
                                 ,lr_gross_sales             ra_customer_trx_lines.extended_amount%TYPE
                                 ,lr_tax_amount              ra_customer_trx_lines.extended_amount%TYPE
                                 );

   PROCEDURE NT_SALES_TAX_AMT(
                              x_error_buff             OUT      VARCHAR2
                             ,x_ret_code               OUT      NUMBER
                             ,p_state                  IN       hz_locations.state%TYPE
                             ,p_store                  IN       hr_locations.location_code%TYPE
                             ,p_legal_entity           IN       VARCHAR2
                             ,p_date_of_revenue_recog  IN       DATE
                             ,p_gsc_code               IN       mtl_system_items_b.attribute1%TYPE
                             ,p_delimiter              IN       VARCHAR2
                             ,p_file_path              IN       VARCHAR2
                             ,p_dest_file_path         IN       VARCHAR2
                             ,p_file_name              IN       VARCHAR2
                             ,p_file_extension         IN       VARCHAR2
                             );

 -- +===================================================================+
 -- | Name        : AR_DATA_WRITE_FILE                                  |
 -- |                                                                   |
 -- | Parameters  : ar_sal_tax_rec_type, lt_file,p_delimiter            |
 -- +===================================================================+

    PROCEDURE AR_DATA_WRITE_FILE(
                                ar_sal_tax_rec_type         IN  ar_sal_tax_rec
                               ,lt_file                     IN  UTL_FILE.FILE_TYPE
                               ,p_delimiter                 IN  VARCHAR2
                               );

END XX_AR_SALES_TAX_AMT_PKG;
/
SHOW ERROR;