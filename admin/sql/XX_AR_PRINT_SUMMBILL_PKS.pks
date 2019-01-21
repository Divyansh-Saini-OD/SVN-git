CREATE OR REPLACE PACKAGE APPS.xx_ar_print_summbill AS
---+========================================================================================================+
---|                                        Office Depot - Project Simplify                                 |
---|                             Oracle NAIO/WIPRO/Office Depot/Consulting Organization                     |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       xx_ar_print_summbill.pks                                            |
---|                                                                                                        |
---|    Description             :                                                                           |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR             DESCRIPTION                                    |
---|    ------------    ----------------- ---------------    ---------------------                          |
---|    1.0             02-AUG-2007       Balaguru Seshadri  Initial Version                                |
---|    1.1             31-JUL-2008       Sarat Uppalapati   Added cut_off_date to the cbi_rec type         |
---|                                                          for defect 9044                               |
---|    1.2             12-AUG-2008       Greg Dill          Added As of Date processing for Defect 9518    |
---|    1.3             07-NOV-2008       Shobana S          Added new function Get_Cer_CBI_Invoice_Total   |
---|                                                          for defect 10998                              |
---|    1.4             12-JAN-2008       Ranjith Prabu      Added parameter cut_off_date and cust_doc_id to|
---|                                                         get_bill_from_date function                    |
---|    1.5             28-JAN-2009       Sambasiva Reddy D  Changes for the CR 460 (Defect # 10750) to     |
---|                                                         handle mail to exceptions                      |
---|    1.6             23-FEB-2009       Shobana S          Changes for Defect 12925                       |
-- |    1.7             09-APR-2009       Sambasiva Reddy D  Changed for the Perf Defect # 13574            |
-- |    1.8             17-JUL-2009       Samabsiva Reddy D  Defect# 631 (CR# 662) -- Applied Credit Memos  |
-- |    1.9             10-SEP-2009       Ranjith Thangasamy Defect# 1451 (CR# 626) -- Applied Credit Memos |
-- |    2.0             10-NOV-2009       Lincy K            Defect# 2858  -- Modified type info_rec        |
-- |    2.1             06-APR-2010       Tamil Vendhan L    Modified for R1.3 CR 738 Defect 2766           |
-- |    2.2             08-JUN-2010       Gokila Tamilselvam Modified for R1.4 CR# 547 Defect# 2424.        |
-- |                                                         Added GET_MAIL_TO_ATTN function.      
-- |    2.3             27-JAN-2014		  V.Deepak           Modification for performance fix QC - 32498    |
---+========================================================================================================+


       g_pkg_name            VARCHAR2(30) :='XX_AR_PRINT_SUMMBILL';
       g_pks_version         NUMBER(2,1)  :='2.1';

       /*      
         Define the number of characters required for certain fields in the report.       
       */
       lc_old_custnum_size NUMBER  :=8;
       ln_custname_size    NUMBER :=40;
       lc_address_size     NUMBER :=40;
       lc_terms_name_size  NUMBER  :=15;       

       ln_request_id         NUMBER :=0;
       p_request_id          NUMBER;
       p_batch_size          NUMBER;
       p_thread_id           NUMBER;
       p_as_of_date          VARCHAR2(30);

       p_template            VARCHAR2(10);
       lv_outfile            VARCHAR2(255) :=TO_CHAR(NULL);
       lv_certegy_file       VARCHAR2(255) :=TO_CHAR(NULL);

       lv_message_buffer     VARCHAR2(4000) :=TO_CHAR(NULL);

       lc_cp_running         BOOLEAN;
       lc_fndconc_phase      VARCHAR2(2000) :=TO_CHAR(NULL);
       lc_fndconc_status     VARCHAR2(2000) :=TO_CHAR(NULL);
       lc_fndconc_dev_phase  VARCHAR2(2000) :=TO_CHAR(NULL);
       lc_fndconc_dev_status VARCHAR2(2000) :=TO_CHAR(NULL);
       lc_fndconc_message    VARCHAR2(2000) :=TO_CHAR(NULL);

      -- Start for Defect# 631 (CR# 662)
       P_CM_TEXT1            VARCHAR2(50);
       P_CM_TEXT2            VARCHAR2(50);
       ln_write_off_amt_low  NUMBER  := FND_PROFILE.VALUE('OD_BILLING_WRITE_OFF_AMT_LOW');
       ln_write_off_amt_high NUMBER  := FND_PROFILE.VALUE('OD_BILLING_WRITE_OFF_AMT_HIGH');
      -- End for Defect# 631 (CR# 662)

      --Start of Changes for R1.1 Defect # 1451 (CR 626)
       P_GIFT_CARD_TEXT1     VARCHAR2(50);
       P_GIFT_CARD_TEXT2     VARCHAR2(50);
       P_GIFT_CARD_TEXT3     VARCHAR2(50);
      --End of Changes for R1.1 Defect # 1451 (CR 626)
       TYPE t_req_id IS TABLE OF fnd_concurrent_requests.request_id%TYPE INDEX BY BINARY_INTEGER;

-- Uncommented for defect 13574
       TYPE cbi_rec IS RECORD
       (
         cons_inv_id   NUMBER
        ,print_date    DATE
        ,cut_off_date  DATE -- Added by Sarat for Defect 9044 on 31-JUL-2008 
        ,customer_id   NUMBER
        ,cust_doc_id   NUMBER
        ,document_id   NUMBER
        ,sort_by       VARCHAR2(20)
        ,doc_flag      VARCHAR2(1)
        ,total_copies  VARCHAR2(10)                                              -- Commented for Defect 12925
        ,layout        VARCHAR2(20)
        ,format        VARCHAR2(40)
        ,delivery      VARCHAR2(30)
        ,invoice_id    NUMBER
        ,total_by      VARCHAR2(40)
        ,page_break    VARCHAR2(40)  
        ,billing_term  VARCHAR2(80)
        ,extension_id  NUMBER
        ,cons_bill_num VARCHAR2(30)
        ,site_use_id   NUMBER    
        ,infocopy_tag  VARCHAR2(10)
        ,billing_id    VARCHAR2(30)
        ,sales_channel VARCHAR2(30)
        ,customer_name VARCHAR2(60)
        ,legacy_cust   VARCHAR2(8)
        ,amount_due    NUMBER
        ,currency      VARCHAR2(15)
       ); 

-- Added for Performance Defect 12925
/*        TYPE cbi_rec IS RECORD
       (
         cons_inv_id   NUMBER
        ,print_date    DATE
        ,cut_off_date  DATE -- Added by Sarat for Defect 9044 on 31-JUL-2008 
        ,customer_id   NUMBER
        ,cust_doc_id   NUMBER
        ,document_id   NUMBER
        ,sort_by       VARCHAR2(20)
        ,doc_flag      VARCHAR2(1)
        ,total_copies  VARCHAR2(10)
        ,layout        VARCHAR2(20)
        ,format        VARCHAR2(40)
        ,delivery      VARCHAR2(30)
        ,invoice_id    NUMBER
        ,total_by      VARCHAR2(40)
        ,page_break    VARCHAR2(40)  
        ,billing_term  VARCHAR2(80)
        ,extension_id  NUMBER
        ,cons_bill_num VARCHAR2(30)
        ,site_use_id   NUMBER    
        ,infocopy_tag  VARCHAR2(10)
        ,currency      VARCHAR2(15)
        ); 

        TYPE cbi_amount_rec IS RECORD
        (
         billing_id    VARCHAR2(30)
        ,sales_channel VARCHAR2(30)
        ,customer_name VARCHAR2(60)
        ,legacy_cust   VARCHAR2(8)
        ,amount_due    NUMBER
        ) ;
*/ -- Commented for defect 13574
-- End of Changes for Defect 12925 

   -- Start for the Defect 10750 for infocopy record type
       TYPE cbi_info_rec IS RECORD
       (
         cons_inv_id1   NUMBER
        ,print_date    DATE
        ,cut_off_date  DATE
        ,customer_id   NUMBER
        ,cust_doc_id   NUMBER
        ,document_id   NUMBER
        ,sort_by       VARCHAR2(20)
        ,total_through_field_id  VARCHAR2(10)
        ,page_break_through_id   VARCHAR2(10)
        ,doc_flag      VARCHAR2(1)
        ,total_copies  VARCHAR2(10)
        ,direct_flag      VARCHAR2(1)
        ,layout        VARCHAR2(20)
        ,delivery      VARCHAR2(30)
        ,billing_term  VARCHAR2(80)
        ,extension_id  NUMBER
        ,cons_bill_num VARCHAR2(30)
        ,site_use_id   NUMBER    
        ,billing_id    VARCHAR2(30)
        ,sales_channel VARCHAR2(240)
        ,customer_name VARCHAR2(240)
        ,legacy_cust   VARCHAR2(240)
        ,currency      VARCHAR2(15)
       );
   -- End for the Defect 10750 

       TYPE info_rec IS RECORD
       (
         direct_flag      VARCHAR2(1) --Added for the Defect 10750 
        ,cust_doc_id      NUMBER
        ,document_id      NUMBER
        ,sort_by          VARCHAR2(20)
        ,doc_flag         VARCHAR2(1)
        ,total_copies     VARCHAR2(10)
        ,layout           VARCHAR2(20)
        ,format           VARCHAR2(40)
        ,delivery         VARCHAR2(30)
        ,total_by         VARCHAR2(40)
        ,page_break       VARCHAR2(40)  
        ,billing_term     VARCHAR2(80)
        ,extension_id     NUMBER
        ,customer_id      NUMBER
        ,creation_date    DATE --Added for the Defect #2858
        ,effec_start_date DATE -- Added for R1.3 CR 738 Defect 2766
		,billing_id       NUMBER          -- Added for 32498
		,sales_channel	  VARCHAR2(100)   -- Added for 32498
		,customer_name    VARCHAR2(100)   -- Added for 32498
		,legacy_cust      VARCHAR2(100)   -- Added for 32498
		,info_bill_term   VARCHAR2(100)   -- Added for 32498
		,org_id           NUMBER          -- Added for 32498
       );

       TYPE doc_rec IS RECORD
       (
         print_date    DATE
        ,delivery      VARCHAR2(30)
        ,format        VARCHAR2(40)
        ,layout        VARCHAR2(20)
        ,sort_by       VARCHAR2(20)
        ,total_copies  NUMBER
        ,total_by      VARCHAR2(20)
        ,page_break    VARCHAR2(20)
        ,billing_term  VARCHAR2(80)
       );

       TYPE arsysparams IS RECORD
       (
         tax_id          VARCHAR2(30)
        ,tax_id_desc     VARCHAR2(30)
        ,account_contact VARCHAR2(30)
        ,order_contact   VARCHAR2(30)
       );

       TYPE softhdr_rec IS RECORD
       (
         cc        VARCHAR2(30)
        ,desktop   VARCHAR2(30)
        ,rel       VARCHAR2(30)
        ,old_order VARCHAR2(30)
       );

       TYPE addressrec is RECORD
       (
         lc_bill_address1    VARCHAR2(40)
        ,lc_bill_address2    VARCHAR2(40)
        ,lc_bill_address3    VARCHAR2(40)
        ,lc_bill_address4    VARCHAR2(40)        
        ,lc_bill_city        VARCHAR2(40)
        ,lc_bill_state       VARCHAR2(40)
        ,lc_bill_postalcode  VARCHAR2(40)
        ,lc_bill_province    VARCHAR2(40)
        ,lc_bill_country     VARCHAR2(40)
        ,lc_remit_address1   VARCHAR2(40)
        ,lc_remit_address2   VARCHAR2(40)
        ,lc_remit_address3   VARCHAR2(40)
        ,lc_remit_address4   VARCHAR2(40)        
        ,lc_remit_city       VARCHAR2(40)
        ,lc_remit_state      VARCHAR2(40)
        ,lc_remit_postalcode VARCHAR2(40)
        ,lc_remit_country    VARCHAR2(40)
        ,lc_order_contact    VARCHAR2(40)
        ,lc_account_contact  VARCHAR2(40)        
       );

       TYPE lr_adj_rec is RECORD
       (
         lc_paydoc          VARCHAR2(3)
        ,ln_billsite_id     NUMBER
        ,ln_cbi_id          NUMBER
        ,ln_trx_id          NUMBER
        ,ln_trx_line_id     NUMBER
        ,ln_customer_id     NUMBER
        ,lc_inv_number      VARCHAR2(40)
        ,ld_inv_date        DATE
        ,lc_inv_type        VARCHAR2(30)
        ,ln_item_ext_amount NUMBER
        ,ln_org_id          NUMBER
       );

       PROCEDURE get_cons_bills;                   
       
       FUNCTION get_od_contact_info 
        -- p_sales_channel -Incoming value
        -- p_country       -Country code like US, CA...
        -- p_contact_type is either 'ORDER' OR 'ACCOUNT'
                      (
                        p_sales_channel IN VARCHAR2 DEFAULT NULL
                       ,p_country       IN VARCHAR2 DEFAULT NULL
                       ,p_contact_type  IN VARCHAR2 DEFAULT NULL
               ) RETURN VARCHAR2;
               
       FUNCTION get_remitaddressid (p_bill_to_site_use_id IN NUMBER) RETURN NUMBER;
       
       FUNCTION xx_fin_check_digit (p_account_number VARCHAR2
                                   ,p_invoice_number VARCHAR2
                                   ,p_amount         VARCHAR2) RETURN VARCHAR2;

       -- Added for Defect 10998

       FUNCTION Get_Cer_CBI_Invoice_Total(p_cbi_id  IN VARCHAR2) RETURN NUMBER;
      
      
       FUNCTION get_cbi_amount_due
             (
               p_cbi_id              IN NUMBER
              ,p_ministmnt_line_type IN VARCHAR2 --TOTAL...               
             ) RETURN NUMBER;   
             
       FUNCTION get_cp_output_file
         (
           p_req_id IN NUMBER
         ) RETURN VARCHAR2;             
                     
       FUNCTION Run_ONE (p_template IN VARCHAR2) RETURN BOOLEAN;
       
       FUNCTION Run_SUMMARIZE (p_template IN VARCHAR2) RETURN BOOLEAN;
       
       FUNCTION Run_DETAIL (p_template IN VARCHAR2) RETURN BOOLEAN;
       
       FUNCTION get_bill_from_date( p_customer_id  IN NUMBER
                                   ,p_site_id      IN NUMBER
                                   ,p_consinv_id   IN NUMBER 
                                   ,p_cut_off_date IN VARCHAR2  -- added for defect 11993
                                   ,infocopy_tag   IN VARCHAR2
                                   ,p_cust_doc_id  IN NUMBER    -- Added for Defect# 11993
                           ) RETURN DATE;
               
       FUNCTION beforereport RETURN BOOLEAN;
       
       FUNCTION afterreport RETURN BOOLEAN;
       
       PROCEDURE gen_cbi_xml
              (
               ERRBUFF OUT VARCHAR2
              ,RETCODE OUT NUMBER
              ,ln_batch_size IN NUMBER
              ,lc_as_of_date IN VARCHAR2
       );
       
       PROCEDURE create_xml_files
              (
               ERRBUFF     OUT VARCHAR2
              ,RETCODE     OUT NUMBER
              ,p_parent_id IN  NUMBER              
       );   
       
       PROCEDURE main
              (
               ERRBUFF     OUT VARCHAR2
              ,RETCODE     OUT NUMBER
              ,ln_batch_size IN NUMBER              
              ,lc_as_of_date IN VARCHAR2
       );          
       
       /* The following function is added as a part of CR 460 to get site use ids by considering
   new mailing address for the scenerio'PAYDOC_IC' for the Defect # 10750*/

   FUNCTION get_paydoc_ic_siteuse_id(p_cust_acct_site_id    NUMBER
                                    ,p_cust_doc_id          NUMBER
                                    ,p_cust_acct_id         NUMBER
                                    ,p_hzsu_site_use_id     NUMBER
                                    ,p_direct_flag          VARCHAR2
                                    )
   RETURN NUMBER;


/* This function is added as part of CR 460 to get totals for the scenerio'PAYDOC_IC'
   for the defect # 10750 */

   FUNCTION get_paydoc_ic_totals
             (
               p_cbi_id              IN NUMBER
              ,p_request_id          IN NUMBER
              ,p_doc_id              IN NUMBER
              ,p_ministmnt_line_type IN VARCHAR2
             ) RETURN NUMBER;

/* This function is added as part of CR 460 to get site use ids by considering
   new mailing address for the scenerio 'INV_IC' for the defect # 10750 */

   FUNCTION get_inv_ic_siteuse_id(p_cust_account_id      NUMBER
                                 ,p_cust_acct_site_id    NUMBER
                                 ,p_cust_doc_id          NUMBER
                                 ,p_ship_to_site_use_id  NUMBER
                                 ,p_direct_flag          VARCHAR2
                                 )
    RETURN NUMBER;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GET_MAIL_TO_ATTN                                                    |
-- | Description : This function is used to submit the Mail to Attention for the       |
-- |               document.                                                           |
-- | Parameters   :  p_cust_account_id   NUMBER                                        |
-- |                ,p_cust_doc_id       NUMBER                                        |
-- |                ,p_site_use_id       NUMBER                                        |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 08-JUN-2010  Gokila Tamilselvam      Initial draft version               |
-- |                                               Added as part of R1.4 CR# 547       |
-- |                                               Defect# 2424                        |
-- +===================================================================================+
   FUNCTION GET_MAIL_TO_ATTN ( p_cust_account_id   NUMBER
                              ,p_cust_doc_id       NUMBER
                              ,p_site_use_id       NUMBER
                              )
   RETURN VARCHAR2;

END xx_ar_print_summbill;
/