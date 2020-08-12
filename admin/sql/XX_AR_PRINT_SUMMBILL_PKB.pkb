create or replace PACKAGE BODY  xx_ar_print_summbill
AS
---+========================================================================================================+
---|                                        Office Depot - Project Simplify                                 |
---|                             Oracle NAIO/WIPRO/Office Depot/Consulting Organization                     |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       XX_AR_PRINT_SUMMBILL.pkb                                            |
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
---|    1.1             07-MAR-2008       Balaguru Seshadri  Sorting Logic -Defect 2971                     |
---|    1.2             09-MAR-2008       Balaguru Seshadri  Cursor G_TRX_LINES /G_INFODOC_LINES modified   |
---|    1.3             09-MAR-2008       Sai Bala           Cursor G_TRX_LINES /G_INFODOC_LINES modified   |
---|                                                         to account for single Tiered Discount line     |
---|                                                         as well as Miscellaneous Credit memo           |
---|    1.4             10-JUL-2008       Greg Dill          Added thread_id for multi-threading.           |
---|    1.5             29-JUL-2008       Greg Dill          Added conditional processing for no XML child  |
---|                                                         jobs for defect 9346.                          |
---|    1.6             30-JUL-2008       Sarat Uppalapati   Changed Bill from date logic for 9044          |
---|    1.7             30-JUL-2008       Sarat Uppalapati   Added additional column bill_from_date to the  |
---|                                                         xx_ar_cons_bills_history for info copies       |
---|    1.8             05-AUG-2008       Sarat Uppalapati   Changed Billing Term logic for 9545            |
---|    1.9             05-AUG-2008       Sarat Uppalapati   Changed zip and done files path for 9453       |
---|    1.10            05-AUG-2008       Sarat Uppalapati   Changed zip and done files names for 9507      |
---|    1.11            06-AUG-2008       Sarat Uppalapati   Copied zip and done files into archieve folder |
---|    1.12            07-AUG-2008       Sarat Uppalapati   Defect 9546                                    |
---|    1.13            07-AUG-2008       Greg Dill          Added NVL to get_cbi_amount_due INTOs for Defect 9597  |
---|    1.14            11-AUG-2008       Greg Dill          Added aps.amount_due_remaining != 0 for Defect 9518  |
---|    1.15            12-AUG-2008       Greg Dill          Added As of Date processing for Defect 9518    |
---|    1.16            19-AUG-2008       Greg Dill          Updated to use cut_off_date instead of issue_date for Defect 9077  |
---|    1.17            25-AUG-2008       Sarat Uppalapti    Defect 9346                                    |
---|    1.18            04-SEP-2008       Balaguru Seshadri  Defect 9632 and 10340 and 341                  |
---|    1.19            08-SEP-2008       Balaguru Seshadri  Defect 10341. Empty zip and done files missing org names like US and CA|
---|    1.20            09-SEP-2008       Balaguru Seshadri  Defect 10340. Created table xx_ar_cbi_xml_threads.|
---|                                                         The table holds every thread_id and the corresponding|
---|                                                         request_id. The status field gets updated in the|
---|                                                         following sequence.                             |
---|                                                         Seq# Status                     Event                               |
---|                                                         ==== =========================  ====================================|
---|                                                          001 COPY-XML-PENDING           for each submission of thread.      |
---|                                                          002                            submit xxcomfilcopy for each thread|
---|                                                          003 COPY-XML-COMPLETE          if the request status in seq 002|
---|                                                                                         is COMPLETED NORMAL. |
---|                                                              COPY-XML-ERROR             if the request status in seq 002|
---|                                                                                         is COMPLETED ERROR. |
---|                                                              COPY-XML-XXXXX             if the request in seq 002|
---|                                                                                         is COMPLETED WARNING OR TERMINATED. |
---|                                                          004                            submit zip program|
---|                                                          005 ZIP-XML-COMPLETE          if the request status in seq 004|
---|                                                                                         is COMPLETED NORMAL. |
---|                                                              ZIP-XML-ERROR             if the request status in seq 004|
---|                                                                                         is COMPLETED ERROR. |
---|                                                              ZIP-XML-XXXXX             if the request in seq 004|
---|                                                                                         is COMPLETED WARNING OR TERMINATED. |
---|                                                          NOTE: All runs where the xml failed to transfer to arinvoice/certegy|
---|                                                                folder will get processed during the next run as the query|
---|                                                                looks for status of not equal to COPY-XML-COMPLETE and not like 'ZIP%'|
---|                                                                from the table xx_ar_cbi_xml_threads.|
---|    1.21            11-SEP-2008       Greg Dill          Added phase_code check to child_requests per 10340 |
---|    1.22            15-SEP-2008       Greg Dill          Fix for defect 11105                           |
---|    1.23            16-SEP-2008       Balaguru Seshadri  Included *.xml for threads that exist.         |
---|    1.24            23-SEP-2008       Balaguru Seshadri  Fixes for defect 10340. Same invoice was picked twice on different runs |
---|    1.25            24-SEP-2008       Balaguru Seshadri  Real consolidated bills sent as info copies was picked twice |
---|    1.26            21-OCT-2008       Sambasiva Reddy D  Added/modified log messages for Defect #11769  |
---|    1.27            04-NOV-2008       Shobana S          Added for Defect 12283                          |
---|    1.28            07-NOV-2008       Shobana S          Added Function Get_Cer_CBI_Invoice_Total for Defect 10998  |
---|    1.29            07-JAN-2009       Ranjith Prabu      Changes for defect 11993 CR 505           |
---|    1.30            28-JAN-2009       Sambasiva Reddy D  Changes for the CR 460 (Defect # 10750) to     |
---|                                                         handle mail to exceptions                      |
---|    1.31            23-FEB-2009       Shobana S          Changes for performance(12925)                 |
---|    1.32            25-FEB-2009       Sambasiva Reddy D  Changes for the Defect # 13403                 |
---|    1.33            18-MAR-2009       Sambasiva Reddy D  Changes for the Defect # 13574                 |
---|    1.34            02-APR-2009       Ranjith Prabu      Changes for the Defect # 13937                 |
-- |    1.35            09-APR-2009       Sambasiva Reddy D  Changed for the Perf Defect # 13574            |
-- |    1.36            15-APR-2009       Sambasiva Reddy D  Added Debug parameter                          |
-- |    1.37            29-MAR-2009       Gokila Tamilselvam Defect# 15063.                                 |
-- |                                                          The logic of the attribute1 column is handled |
-- |                                                          in the procedure XX_AR_PRINT_NEW_CON_PKG.MAIN |
-- |    1.38            11-JUN-2009       Sambasiva Reddy D  Added for the Defect # 15622                   |
-- |    1.39            17-JUL-2009       Samabsiva Reddy D  Defect# 631 (CR# 662) -- Applied Credit Memos  |
-- |    1.40            31-JUL-2009       Ramya Priya M      Modified for Defect# 869                       |
-- |    1.41            20-AUG-2009       Samabsiva Reddy D  Defect# 1745 Perf Changes                      |
-- |    1.42            03-SEP-2009       Ranjith Prabu      Changes for defect # 1451 R1.1 CR 626          |
-- |    1.43            16-NOV-2009       Lincy K            Modified for the Prod Defect # 2858            |
-- |    1.44            27-NOV-2009       Tamil Vendhan L    Modified for R1.2 CR 743 Defect 1744           |
-- |    1.45            04-MAR-2010       Sneha Anand        Modified for R1.3 Defect 3551                  |
-- |    1.46            06-APR-2010       Tamil Vendhan L    Modified for R1.3 CR 738 Defect 2766           |
-- |    1.47            08-APR-2010       Lincy K            Updating attribute15 for defect 4760 and       |
-- |                                                         updating WHO columns for defect 4761           |
-- |    1.48            01-JUN-2010       Ranjith Thangasamy Changes for Defect 6179                        |
-- |    1.49            08-JUN-2010       Gokila Tamilselvam Modified for R1.4 CR# 547 Defect# 2424.        |
-- |                                                         Added GET_MAIL_TO_ATTN function.               |
-- |    1.50            15-JUL-2010       Gokila Tamilselvam Concatenating attribute15 column to the        |
-- |                                                         parameters in calling xx_ar_infocopy_handling  |
-- |                                                         function as part of R1.4 CR# 586.              |
-- |    1.51            12-JUN-2012       Gayathri K         As part of Defect#18203                        |
-- |                                                         get_remitaddressid function modified           |
-- |                   14-AUG-2012        Rohit Ranjan       Incase Remit to logic is changed in furture    |
-- |                                                         then apart from this package, the package      |
-- |                                                         XX_AR_REMIT_ADDRESS_CHILD_PKG.pkb and          |
-- |                                                         XX_AR_EBL_COMMON_UTIL_PKG.pkb function name    |
-- |                                                         get_remitaddressid should be modified. Comment |
-- |                                                         is given because in Defect# 14144 remit to     |
-- |                                                         logic is modified in the package               |
-- |                                                         XX_AR_REMIT_ADDRESS_CHILD_PKG.pkb              |
-- |                                                         but not in billing package                     |
-- |    1.52            29-NOV-2012       Adithya            QC Defect # 19754 - Performance Fix            |
-- |                                                         CURSOR get_infocopy2_invoices                  |
-- |    1.53            25-SEP-2013       Abdul Khan         QC Defect # 25206 - Performance Fix            |
-- |                                                         CURSOR get_infocopy1                           |
-- |    1.54            25-NOV-2013       Arun Gannarapu     Made changes to R12 retrofit                   |
-- |    1.55            04-DEC-2013       Arun Gannarapu     Add the status to FINAL and Accepted for defect|
-- |                                                          26795                                         |
-- |    1.56            31-JAN-2014       Arun Gannarapu     Added the status to FINAL for defect           |
-- |    1.57            14-JAN-2014       Deepak V           Performance fix for Defect 32498               |
-- |    1.58            26-OCT-2015       Vasu Raparla       Removed Schema References for R12.2            |
-- |    1.59            14-DEC-2015       Suresh Naragam     Module 4B Release 3 Changes(Defect#36434)      |
-- |    1.60            24-MAY-2016       Havish Kasina      Removed Schema References for R12.2            |
-- |    1.61            24-MAY-2016       Havish Kasina      Added for Kitting, Defect# 37670               |
-- |    1.62            12-AUG-2016       Rohit Gupta        Removed the join with RA_CUSTOMER_TRX for      |
-- |                                                         Defect #38583(performance fix)                 |
-- |    1.63            12-AUG-2020       Divyansh Saini     Changes done for tariff NAIT - 129167          |
---+========================================================================================================+

/***** IMPORTANT NOTE *****
*****  Remit to logic is cloned at 3 locations XX_AR_PRINT_SUMMBILL_PKB.pkb,XX_AR_REMIT_ADDRESS_CHILD_PKG.pkb and XX_AR_EBL_COMMON_UTIL_PKG.pkb. Any changes done at one place
has to be synched in the other 2 places.*****/

   g_pkb_version        NUMBER (3, 2) := '1.49';
   g_as_of_date         DATE;
   g_attr_group_id_site NUMBER;
   PROCEDURE get_cons_bills
   IS
      --Query1: Fetches all PayDoc summary bill records ready to be processed.

-- The below cursor has been commented for the Defect # 10750
----------------------------

 /*     CURSOR get_paydoc_cbi
      IS
         SELECT   arci.cons_inv_id "cons_inv_id",
            --      TRUNC (arci.cut_off_date) "print_date",   Commented for defect 11993
                  TRUNC (arci.cut_off_date-1) "print_date",
             --     arci.cut_off_date "cut_off_date",        Commented for defect 11993
                  arci.cut_off_date-1 "cut_off_date",
                  -- Added by sarat for Defect 9044
                  arci.customer_id "customer_id",
                  cdh_bill_header.billdocs_cust_doc_id "cust_doc_id",
                  cdh_bill_header.billdocs_doc_id "document_id",
                  mbs_doc_master.doc_sort_order "sort_order",
                  cdh_bill_header.billdocs_paydoc_ind "doc_flag",
                  cdh_bill_header.billdocs_num_copies "total_copies",
                  TRIM (mbs_doc_master.doc_detail_level) "layout",
                  'CONSOLIDATED BILL' "format",
                  cdh_bill_header.billdocs_delivery_meth "delivery",
                  0 "invoice_id",
                     SUBSTR
                        (mbs_doc_master.doc_sort_order,
                         1,
                         INSTR (mbs_doc_master.doc_sort_order,
                                mbs_doc_master.total_through_field_id
                               )
                        )
                  || '1' total_by,
                     SUBSTR
                        (mbs_doc_master.doc_sort_order,
                         1,
                         INSTR (mbs_doc_master.doc_sort_order,
                                mbs_doc_master.page_break_through_id
                               )
                        )
                  || '1' page_break,
                  cdh_bill_header.billdocs_payment_term billing_term,
                  cdh_bill_header.extension_id extension_id,
                  arci.cons_billing_number cons_bill_num,
                  arci.site_use_id "site_use_id", 'PAYDOC' "infocopy_tag",
                  hzca.account_number "billing_id",
                  TRIM (UPPER (hzca.attribute18)) "sales_channel",
                  SUBSTR
                       (hzp.party_name,
                        1,
                        xx_ar_print_summbill.ln_custname_size
                       ) "customer_name",
                  SUBSTR
                      (hzca.orig_system_reference,
                       1,
                       xx_ar_print_summbill.lc_old_custnum_size
                      ) "legacy_cust",
                  xx_ar_print_summbill.get_cbi_amount_due
                                              (arci.cons_inv_id,
                                               'TOTAL'
                                              ) "amount_due",
                  arci.currency_code "currency"
             FROM xx_cdh_mbs_document_master mbs_doc_master,
                  ar_cons_inv arci,
                  hz_cust_accounts hzca,
                  hz_parties hzp,
                  xx_cdh_a_ext_billdocs_v cdh_bill_header
            WHERE 1 = 1
              AND (    arci.attribute2 IS NULL
                   AND arci.attribute4 IS NULL
                   AND arci.attribute10 IS NULL
                  )
              AND cdh_bill_header.cust_account_id = arci.customer_id
              AND cdh_bill_header.billdocs_doc_type = 'Consolidated Bill'
              AND cdh_bill_header.billdocs_delivery_meth = 'PRINT'
              AND cdh_bill_header.billdocs_paydoc_ind = 'Y'
              AND TRIM (cdh_bill_header.billdocs_special_handling) IS NULL
              AND EXISTS (SELECT 1
                            FROM ar_cons_inv_trx_lines
                           WHERE cons_inv_id = arci.cons_inv_id)
              AND mbs_doc_master.document_id = cdh_bill_header.billdocs_doc_id
              AND hzca.cust_account_id = arci.customer_id
              AND hzp.party_id = hzca.party_id
*/            /*  AND xx_ar_inv_freq_pkg.compute_effective_date
                                       (cdh_bill_header.billdocs_payment_term,
                                        --Defect 9632.
                                        TRUNC (arci.cut_off_date)
                                       ) <= g_as_of_date*/  -- commented for defect 11993
/*             AND xx_ar_inv_freq_pkg.compute_effective_date
                                       (cdh_bill_header.billdocs_payment_term,
                                        --Defect 9632.
                                        TRUNC (arci.cut_off_date - 1)
                                       ) <= g_as_of_date    -- Added for defect 11993
         ORDER BY "doc_flag" DESC, "customer_id", "site_use_id",
                  "cons_inv_id";
*/

-- The below cursor has been added for the Defect # 10750

     /*CURSOR get_paydoc_cbi(p_attr_group_id IN NUMBER)         -- Commented this cursor for defect 12925
      IS
         SELECT   arci.cons_inv_id "cons_inv_id"
                 ,TRUNC (arci.cut_off_date-1) "print_date"
                 ,arci.cut_off_date-1 "cut_off_date"
                 ,arci.customer_id "customer_id"
                 ,cdh_bill_header.n_ext_attr2 "cust_doc_id"
                 ,cdh_bill_header.n_ext_attr1 "document_id"
                 ,mbs_doc_master.doc_sort_order "sort_order"
                 ,cdh_bill_header.c_ext_attr2 "doc_flag"
                 ,cdh_bill_header.n_ext_attr3 "total_copies"
                 ,TRIM (mbs_doc_master.doc_detail_level) "layout"
                 ,'CONSOLIDATED BILL' "format"
                 ,cdh_bill_header.c_ext_attr3 "delivery"
                 ,0 "invoice_id"
                 ,SUBSTR(mbs_doc_master.doc_sort_order,1,
                         INSTR (mbs_doc_master.doc_sort_order,mbs_doc_master.total_through_field_id)
                        ) || '1' total_by
                 ,SUBSTR(mbs_doc_master.doc_sort_order,1,
                         INSTR (mbs_doc_master.doc_sort_order,mbs_doc_master.page_break_through_id)
                        ) || '1' page_break
                 ,cdh_bill_header.c_ext_attr14 billing_term
                 ,cdh_bill_header.extension_id extension_id
                 ,arci.cons_billing_number cons_bill_num
                 ,arci.site_use_id "site_use_id"
                 ,'PAYDOC' "infocopy_tag"
                 ,hzca.account_number "billing_id"
                 ,TRIM (UPPER (hzca.attribute18)) "sales_channel"
                 ,SUBSTR(hzp.party_name,1,xx_ar_print_summbill.ln_custname_size) "customer_name"
                 ,SUBSTR(hzca.orig_system_reference,1,xx_ar_print_summbill.lc_old_custnum_size) "legacy_cust"
                 ,xx_ar_print_summbill.get_cbi_amount_due(arci.cons_inv_id,'TOTAL') "amount_due"
                 ,arci.currency_code "currency"
             FROM xx_cdh_mbs_document_master mbs_doc_master
                 ,ar_cons_inv arci
                 ,hz_cust_accounts hzca
                 ,hz_parties hzp
                 ,xx_cdh_cust_acct_ext_b cdh_bill_header
            WHERE 1 = 1
              AND (    arci.attribute2 IS NULL
                   AND arci.attribute4 IS NULL
                   AND arci.attribute10 IS NULL
                  )
              AND cdh_bill_header.cust_account_id = arci.customer_id
              AND cdh_bill_header.c_ext_attr1= 'Consolidated Bill'
              AND cdh_bill_header.c_ext_attr3 = 'PRINT'
              AND cdh_bill_header.c_ext_attr2 = 'Y'
              AND TRIM (cdh_bill_header.c_ext_attr4) IS NULL
              AND EXISTS (SELECT 1
                          FROM   ar_cons_inv_trx_lines
                          WHERE  cons_inv_id = arci.cons_inv_id)
              AND mbs_doc_master.document_id = cdh_bill_header.n_ext_attr1
              AND cdh_bill_header.attr_group_id=p_attr_group_id
              AND hzca.cust_account_id = arci.customer_id
              AND arci.status='ACCEPTED'
              AND hzp.party_id = hzca.party_id
              AND xx_ar_inv_freq_pkg.compute_effective_date
                                       (cdh_bill_header.c_ext_attr14,
                                        TRUNC (arci.cut_off_date - 1)
                                       ) <= g_as_of_date
         ORDER BY "doc_flag" DESC, "customer_id", "site_use_id",
                  "cons_inv_id"; */

-- Below code added for perf defect 13574
--  Below cursor is commented for perf defect # 1745
/*    CURSOR get_paydoc_cbi(p_attr_group_id IN NUMBER)
     IS
     SELECT   +  leading(ARCI)
          ARCI.cons_inv_id "cons_inv_id"
         --,TRUNC (ARCI.cut_off_date-1) "print_date"  -- Commented for Defect# 15063.
         ,TO_DATE(ARCI.attribute1)-1   "print_date"   -- Added for Defect# 15063.
         --,ARCI.cut_off_date-1 "cut_off_date"        -- Commented for Defect# 15063.
         ,TO_DATE(ARCI.attribute1)-1  "cut_off_date"      -- Added for Defect# 15063.
         ,ARCI.customer_id "customer_id"
         ,CDH_BILL_HEADER.n_ext_attr2 "cust_doc_id"
         ,CDH_BILL_HEADER.n_ext_attr1 "document_id"
         ,MBS_DOC_MASTER.doc_sort_order "sort_order"
         ,CDH_BILL_HEADER.c_ext_attr2 "doc_flag"
         ,CDH_BILL_HEADER.n_ext_attr3 "total_copies"
         ,TRIM (MBS_DOC_MASTER.doc_detail_level) "layout"
         ,'CONSOLIDATED BILL' "format"
         ,CDH_BILL_HEADER.c_ext_attr3 "delivery"
         ,0 "invoice_id"
         ,SUBSTR(MBS_DOC_MASTER.doc_sort_order,1,
                 INSTR (MBS_DOC_MASTER.doc_sort_order,MBS_DOC_MASTER.total_through_field_id)
                        ) || '1' total_by
         ,SUBSTR(MBS_DOC_MASTER.doc_sort_order,1,
                         INSTR (MBS_DOC_MASTER.doc_sort_order,MBS_DOC_MASTER.page_break_through_id)
                        ) || '1' page_break
         ,CDH_BILL_HEADER.c_ext_attr14 billing_term
         ,CDH_BILL_HEADER.extension_id extension_id
         ,ARCI.cons_billing_number cons_bill_num
         ,ARCI.site_use_id "site_use_id"
         ,'PAYDOC' "infocopy_tag"
         ,CON2.billing_id       "billing_id"
         ,CON2.sales_channel    "sales_channel"
         ,CON2.customer_name    "customer_name"
         ,CON2.legacy_cust      "legacy_cust"
         ,CON2.amount_due       "amount_due"
         ,ARCI.currency_code "currency"
    FROM  xx_cdh_mbs_document_master MBS_DOC_MASTER
         ,ar_cons_inv                ARCI
         ,xx_cdh_cust_acct_ext_b     CDH_BILL_HEADER
         ,(SELECT   HZCA.account_number billing_id
                   ,TRIM (UPPER (HZCA.attribute18)) sales_channel
                   ,SUBSTR(HZP.party_name,1,xx_ar_print_summbill.ln_custname_size) customer_name
                   ,SUBSTR(HZCA.orig_system_reference,1,xx_ar_print_summbill.lc_old_custnum_size) legacy_cust
                   ,CON1.extended_amount   amount_due
                   ,HZCA.cust_account_id
                   ,CON1.cons_inv_id
           FROM     hz_cust_accounts           HZCA
                   ,hz_parties                 HZP
                   ,ra_customer_trx_all        RCT
                   ,ar_cons_inv_trx_all        ACIT
                  ,( SELECT SUM(rctl.extended_amount) extended_amount
                           ,acit1.cons_inv_id cons_inv_id
                      FROM  ra_customer_trx_lines_all rctl
                           ,ar_cons_inv_trx_all ACIT1
                     where  rctl.customer_trx_id = acit1.customer_trx_id
                     group by acit1.cons_inv_id
                    ) CON1
            WHERE  1=1
            AND     CON1.cons_inv_id    = ACIT.cons_inv_id
            AND     RCT.bill_to_customer_id = HZCA.cust_Account_id
            AND     HZP.party_id            = HZCA.party_id
            AND     RCT.customer_trx_id     = ACIT.customer_trx_id
            GROUP BY hzca.account_number
                      ,hzca.attribute18
                      ,hzp.party_name
                      ,hzca.orig_system_reference
                      ,CON1.extended_amount
                      ,HZCA.CUST_aCCOUNT_ID
                      ,CON1.CONS_INV_ID
         ) CON2
   WHERE 1 = 1
  AND (ARCI.attribute2 IS NULL
       AND ARCI.attribute4 IS NULL
       AND ARCI.attribute10 IS NULL
      )
  AND CDH_BILL_HEADER.cust_account_id = ARCI.customer_id
  AND CDH_BILL_HEADER.c_ext_attr1= 'Consolidated Bill'
  AND CDH_BILL_HEADER.c_ext_attr3 = 'PRINT'
  AND CDH_BILL_HEADER.c_ext_attr2 = 'Y'
  AND TRIM (CDH_BILL_HEADER.c_ext_attr4) IS NULL
  AND EXISTS (SELECT 1
                          FROM   ar_cons_inv_trx_lines
                          WHERE  cons_inv_id = ARCI.cons_inv_id)
  AND mbs_doc_master.document_id = CDH_BILL_HEADER.n_ext_attr1
  AND CDH_BILL_HEADER.attr_group_id= p_attr_group_id
  AND ARCI.status='ACCEPTED'
*/  /*AND xx_ar_inv_freq_pkg.compute_effective_date
                                       (CDH_BILL_HEADER.c_ext_attr14,
                                        TRUNC (ARCI.cut_off_date - 1)
                                       ) <= g_as_of_date*/ -- Commented for Defect# 15063.
/*  AND xx_ar_inv_freq_pkg.compute_effective_date
                                       (CDH_BILL_HEADER.c_ext_attr14,
                                        TO_DATE(ARCI.attribute1) - 1
                                       ) <= g_as_of_date  -- Added for Defect# 15063
  AND ARCI.customer_id    = CON2.cust_account_id
  AND ARCI.cons_inv_id        = CON2.CONS_INV_ID
ORDER BY "doc_flag" DESC, "customer_id", "site_use_id",
                        "cons_inv_id";
          -- End of changes for Performance(13594)
*/

--  Below cursor is Added for perf defect # 1745
    CURSOR get_paydoc_cbi(p_attr_group_id IN NUMBER)
     IS
   --  SELECT  /*+  leading(ARCI) no_use_hash(CON2) */ ARCI.CONS_INV_ID "cons_inv_id"  Commented for perf recommendation 6179
       SELECT  /*+  leading(ARCI) no_use_hash(CON2) PUSH_PRED(CON2) */ ARCI.CONS_INV_ID "cons_inv_id" -- Added for Perf defect 6179
         ,TO_DATE(ARCI.attribute1)-1   "print_date"
         ,TO_DATE(ARCI.attribute1)-1  "cut_off_date"
         ,ARCI.customer_id "customer_id"
         ,CDH_BILL_HEADER.n_ext_attr2 "cust_doc_id"
         ,CDH_BILL_HEADER.n_ext_attr1 "document_id"
         ,MBS_DOC_MASTER.doc_sort_order "sort_order"
         ,CDH_BILL_HEADER.c_ext_attr2 "doc_flag"
         ,CDH_BILL_HEADER.n_ext_attr3 "total_copies"
         ,TRIM (MBS_DOC_MASTER.doc_detail_level) "layout"
         ,'CONSOLIDATED BILL' "format"
         ,CDH_BILL_HEADER.c_ext_attr3 "delivery"
         ,0 "invoice_id"
         ,SUBSTR(MBS_DOC_MASTER.doc_sort_order,1,
                 INSTR (MBS_DOC_MASTER.doc_sort_order,MBS_DOC_MASTER.total_through_field_id)
                        ) || '1' total_by
         ,SUBSTR(MBS_DOC_MASTER.doc_sort_order,1,
                         INSTR (MBS_DOC_MASTER.doc_sort_order,MBS_DOC_MASTER.page_break_through_id)
                        ) || '1' page_break
         ,CDH_BILL_HEADER.c_ext_attr14 billing_term
         ,CDH_BILL_HEADER.extension_id extension_id
         ,ARCI.cons_billing_number cons_bill_num
         ,ARCI.site_use_id "site_use_id"
         ,'PAYDOC' "infocopy_tag"
         ,CON2.billing_id       "billing_id"
         ,CON2.sales_channel    "sales_channel"
         ,CON2.customer_name    "customer_name"
         ,CON2.legacy_cust      "legacy_cust"
         ,CON2.amount_due       "amount_due"
         ,ARCI.currency_code "currency"
    FROM  xx_cdh_mbs_document_master MBS_DOC_MASTER
         ,ar_cons_inv                ARCI
         ,xx_cdh_cust_acct_ext_b     CDH_BILL_HEADER
         ,(-- SELECT /*+ no_use_hash(CON1) */  DISTINCT  Commented for perf recommendation 6179
              SELECT  DISTINCT   -- Added for perf recommendation 6179
              HZCA.account_number BILLING_ID
             ,TRIM (UPPER (HZCA.attribute18)) SALES_CHANNEL
                   ,SUBSTR(HZP.party_name,1,xx_ar_print_summbill.ln_custname_size) customer_name
                   ,SUBSTR(HZCA.orig_system_reference,1,xx_ar_print_summbill.lc_old_custnum_size) legacy_cust
             ,( SELECT /*+ use_nl(ACIT1, RCTL) */ SUM(RCTL.extended_amount) EXTENDED_AMOUNT
                 FROM ra_customer_trx_lines_all RCTL
                     ,ar_cons_inv_trx_all ACIT1
                WHERE RCTL.customer_trx_id = ACIT1.customer_trx_id
                  AND ACIT1.cons_inv_id = ACIT.cons_inv_id) AMOUNT_DUE
             ,HZCA.cust_account_id
             ,ACIT.cons_inv_id
         FROM hz_cust_accounts HZCA
             ,hz_parties HZP
             ,ra_customer_trx_all RCT
             ,ar_cons_inv_trx_all ACIT
        WHERE 1=1
          AND RCT.bill_to_customer_id = HZCA.cust_account_id
          AND HZP.party_id = HZCA.party_id
          AND RCT.customer_trx_id = ACIT.customer_trx_id
                               ) CON2
   WHERE 1 = 1
  AND (ARCI.attribute2 IS NULL
       AND ARCI.attribute4 IS NULL
       AND ARCI.attribute10 IS NULL
       AND ARCI.attribute15 IS NULL  --added for defect 4760
      )
  AND CDH_BILL_HEADER.cust_account_id = ARCI.customer_id
  AND CDH_BILL_HEADER.c_ext_attr1= 'Consolidated Bill'
  AND CDH_BILL_HEADER.c_ext_attr3 = 'PRINT'
  AND CDH_BILL_HEADER.c_ext_attr2 = 'Y'
  AND TRIM (CDH_BILL_HEADER.c_ext_attr4) IS NULL
  AND EXISTS (SELECT 1
                          FROM   ar_cons_inv_trx_lines
                          WHERE  cons_inv_id = ARCI.cons_inv_id)
  AND mbs_doc_master.document_id = CDH_BILL_HEADER.n_ext_attr1
  AND CDH_BILL_HEADER.attr_group_id= p_attr_group_id
  AND ARCI.status IN ( 'FINAL' ,'ACCEPTED')
  AND xx_ar_inv_freq_pkg.compute_effective_date
                                       (CDH_BILL_HEADER.c_ext_attr14,
                                        TO_DATE(ARCI.attribute1) - 1
                                       ) <= g_as_of_date
  AND ARCI.customer_id    = CON2.cust_account_id
  AND ARCI.cons_inv_id        = CON2.CONS_INV_ID
-- Below conditions added for R1.3 CR 738 Defect 2766
  AND g_as_of_date                 >= CDH_BILL_HEADER.d_ext_attr1
  AND (CDH_BILL_HEADER.d_ext_attr2 IS NULL
       OR
       g_as_of_date                <= CDH_BILL_HEADER.d_ext_attr2)
-- End of changes for R1.3 CR 738 Defect 2766
ORDER BY "doc_flag" DESC, "customer_id", "site_use_id", "cons_inv_id";

      --  Query2: Fetches all InfoDoc individual bills ready to be processed.

-- The following cursor has been commented for the Defect # 10750
/*      CURSOR get_infocopy1
      IS
         SELECT  --arci.cons_inv_id || ROWNUM "cons_inv_id",  -- Commneted for the Defect # 10750
                  arci.cons_inv_id  "cons_ind_id1",   -- Added for the Defect # 10750
              --  TRUNC (arci.cut_off_date) "print_date",  Commented for defect 11993
                  TRUNC (arci.cut_off_date-1) "print_date",  --added for defect 11993
             --   arci.cut_off_date "cut_off_date",        Commented for defect 11993
                  arci.cut_off_date-1 "cut_off_date",     -- Added for defect 11993
                                                  -- Added by sarat for Defect 9044
                  arci.customer_id "customer_id",
                  cdh_bill_header.billdocs_cust_doc_id "cust_doc_id",
                  cdh_bill_header.billdocs_doc_id "document_id",
                  mbs_doc_master.doc_sort_order "sort_order",
                  mbs_doc_master.total_through_field_id  "total_through_field_id",---- Added for the Defect # 10750
                  mbs_doc_master.page_break_through_id   "page_break_through_id", ---- Added for the Defect # 10750
                  cdh_bill_header.billdocs_paydoc_ind "doc_flag",
                  cdh_bill_header.billdocs_num_copies "total_copies",
                  SUBSTR(cdh_bill_header.direct_flag,1,1) "direct_flag",   -- Added for the Defect # 10750
                  TRIM (mbs_doc_master.doc_detail_level) "layout",
--                  'CONSOLIDATED BILL' "format",   -- Commented for the Defect # 10750
                  cdh_bill_header.billdocs_delivery_meth "delivery",
                  0 "invoice_id",
                     SUBSTR
                        (mbs_doc_master.doc_sort_order,
                         1,
                         INSTR (mbs_doc_master.doc_sort_order,
                                mbs_doc_master.total_through_field_id
                               )
                        )
                  || '1' total_by,
                     SUBSTR
                        (mbs_doc_master.doc_sort_order,
                         1,
                         INSTR (mbs_doc_master.doc_sort_order,
                                mbs_doc_master.page_break_through_id
                               )
                        )
                  || '1' page_break,
                  cdh_bill_header.billing_term billing_term,
                  cdh_bill_header.extension_id extension_id,
                  arci.cons_billing_number "cons_bill_num",
                  arci.site_use_id "site_use_id",
               'PAYDOC_IC' "infocopy_tag",
                  hzca.account_number "billing_id",
                  hzca.attribute18 "sales_channel",
                  hzp.party_name "customer_name",
                  hzca.orig_system_reference "legacy_cust",
                  SUBSTR
                       (hzp.party_name,
                        1,
                        xx_ar_print_summbill.ln_custname_size
                       ) "customer_name",
                  SUBSTR
                      (hzca.orig_system_reference,
                       1,
                       xx_ar_print_summbill.lc_old_custnum_size
                      ) "legacy_cust",
                  xx_ar_print_summbill.get_cbi_amount_due
                                              (arci.cons_inv_id,
                                               'TOTAL'
                                              ) "amount_due",

                  arci.currency_code "currency"
             FROM (SELECT cust_account_id, extension_id, billdocs_doc_id,
                          billdocs_paydoc_ind, billdocs_cust_doc_id,
                          billdocs_num_copies, billdocs_delivery_meth,
                          billdocs_payment_term billing_term
                         ,billdocs_direct_flag direct_flag   -- Added for the Defect # 10750
                     FROM xx_cdh_a_ext_billdocs_v
                    WHERE 1 = 1
                      AND billdocs_doc_type = 'Consolidated Bill'
                      AND billdocs_delivery_meth = 'PRINT'
                      AND NVL (billdocs_paydoc_ind, 'N') != 'Y'
                      AND TRIM (billdocs_special_handling) IS NULL) cdh_bill_header,
                  xx_cdh_mbs_document_master mbs_doc_master,
                  ar_cons_inv arci,
                  hz_cust_accounts hzca,
                  hz_parties hzp
                  ,hz_cust_acct_sites hzas   -- Added for the Defect # 10750
                  ,hz_cust_site_uses_all hzsu  -- Added for the Defect # 10750
            WHERE 1 = 1
              AND cdh_bill_header.cust_account_id = arci.customer_id
              AND hzca.cust_account_id = arci.customer_id
              AND hzp.party_id = hzca.party_id
              and hzas.cust_account_id = arci.customer_id  -- Added for the Defect # 10750
             and hzsu.cust_acct_site_id       =hzas.cust_acct_site_id  -- Added for the Defect # 10750
             and hzsu.site_use_code='SHIP_TO'  -- Added for the Defect # 10750
              AND NOT EXISTS (
                     SELECT 1
                       FROM xx_ar_cons_bills_history
                      WHERE 1 = 1
                        AND attribute6 = TO_CHAR (arci.cons_inv_id)
                        AND attribute4 = attribute4
                        --cdh_bill_header.billing_term
                        AND attribute8 = 'PAYDOC_IC'
                        AND customer_id = arci.customer_id
                        AND document_id = cdh_bill_header.billdocs_doc_id
                        AND cust_doc_id = cdh_bill_header.billdocs_cust_doc_id -- Added for the Defect # 10750
                        AND process_flag = 'Y')
              AND EXISTS (SELECT 1
                            FROM ar_cons_inv_trx_lines
                           WHERE 1 = 1 AND cons_inv_id = arci.cons_inv_id)
              AND EXISTS (SELECT 1    -- Added for the Defect # 10750
                            FROM ar_cons_inv_trx acit
                                ,ra_customer_trx_all rct
                            WHERE cons_inv_id = arci.cons_inv_id
                            and rct.customer_trx_id= acit.customer_trx_id
                            and rct.ship_to_site_use_id=hzsu.site_use_id)
              AND mbs_doc_master.document_id = cdh_bill_header.billdocs_doc_id
              AND TO_CHAR (g_as_of_date, 'DD') =
                     TO_CHAR
                        (xx_ar_inv_freq_pkg.compute_effective_date
                                                (cdh_bill_header.billing_term,
                                                 g_as_of_date
                                                ),
                         'DD'
                        )
*/              /*AND xx_ar_inv_freq_pkg.compute_effective_date
                                                (cdh_bill_header.billing_term,
                                                 TRUNC (arci.cut_off_date)
                                                ) <= g_as_of_date*/
/*              AND xx_ar_inv_freq_pkg.compute_effective_date                 -- added for defect 11993
                                                (cdh_bill_header.billing_term,
                                                 TRUNC (arci.cut_off_date-1)
                                                ) <= g_as_of_date
         ORDER BY "customer_id",arci.cons_inv_id,"document_id","cust_doc_id","site_use_id";
*/

-- The following cursor has been added for the Defect # 10750

      -- Added three HINTS to this cursor query to improve performance -- QC Defect # 25206
      CURSOR get_infocopy1(p_attr_group_id IN NUMBER)
      IS
         SELECT  /*+ leading(CDH_BILL_HEADER) push_subq(@subq1) push_subq(@subq2) */ arci.cons_inv_id  "cons_ind_id1" -- Added HINT for QC Defect # 25206
                --,TRUNC (arci.cut_off_date-1) "print_date"  -- Commented for Defect# 15063.
                ,TO_DATE(ARCI.attribute1) - 1   "print_date"  -- Added for Defect# 15063.
                --,arci.cut_off_date-1 "cut_off_date"        -- Commented for Defect# 15063
                ,TO_DATE(ARCI.attribute1) - 1   "cut_off_date" -- Added for Defect# 15063.
                ,arci.customer_id "customer_id"
                ,cdh_bill_header.billdocs_cust_doc_id "cust_doc_id"
                ,cdh_bill_header.billdocs_doc_id "document_id"
                ,mbs_doc_master.doc_sort_order "sort_order"
                ,mbs_doc_master.total_through_field_id  "total_through_field_id"
                ,mbs_doc_master.page_break_through_id   "page_break_through_id"
                ,cdh_bill_header.billdocs_paydoc_ind "doc_flag"
                ,cdh_bill_header.billdocs_num_copies "total_copies"
                ,SUBSTR(cdh_bill_header.direct_flag,1,1) "direct_flag"
                ,TRIM (mbs_doc_master.doc_detail_level) "layout"
                ,cdh_bill_header.billdocs_delivery_meth "delivery"
                ,cdh_bill_header.billing_term billing_term
                ,cdh_bill_header.extension_id extension_id
                ,arci.cons_billing_number "cons_bill_num"
                ,xx_ar_print_summbill.get_paydoc_ic_siteuse_id(hzas.cust_acct_site_id
                                                               ,cdh_bill_header.billdocs_cust_doc_id
                                                               ,arci.customer_id
                                                               ,hzsu.site_use_id
                                                               ,cdh_bill_header.direct_flag) "site_use_id"
                ,hzca.account_number "billing_id"
                ,hzca.attribute18 "sales_channel"
                ,hzp.party_name "customer_name"
                ,hzca.orig_system_reference "legacy_cust"
                ,arci.currency_code "currency"
             FROM (SELECT cust_account_id
                         ,extension_id
                         ,n_ext_attr1 billdocs_doc_id
                         ,c_ext_attr2 billdocs_paydoc_ind
                         ,n_ext_attr2 billdocs_cust_doc_id
                         ,n_ext_attr3 billdocs_num_copies
                         ,c_ext_attr3 billdocs_delivery_meth
                         ,c_ext_attr14 billing_term
                         ,c_ext_attr7 direct_flag
                         ,TRUNC(creation_date) creation_date                       -- Added for prod defect # 2858
                         ,d_ext_attr1 effec_start_date                             -- Added for R1.3 CR 738 Defect 2766
                     FROM xx_cdh_cust_acct_ext_b
                    WHERE 1 = 1
                      AND c_ext_attr1 = 'Consolidated Bill'
                      AND c_ext_attr3 = 'PRINT'
                      AND NVL (c_ext_attr2, 'N') != 'Y'
                      AND TRIM (c_ext_attr4) IS NULL
                      AND attr_group_id=p_attr_group_id
                      -- Added below conditions for R1.3 CR 738 Defect 2766
                      AND g_as_of_date        >= d_ext_attr1
                      AND (d_ext_attr2        IS NULL
                           OR
                           g_as_of_date       <= d_ext_attr2)) cdh_bill_header
                      -- End of changes for R1.3 CR 738 Defect 2766
                    ,xx_cdh_mbs_document_master mbs_doc_master
                    ,ar_cons_inv arci
                    ,hz_cust_accounts hzca
                    ,hz_parties hzp
                    ,hz_cust_acct_sites hzas
                    ,hz_cust_site_uses hzsu
             WHERE   1 = 1
              AND    cdh_bill_header.cust_account_id = arci.customer_id
              AND    hzca.cust_account_id = arci.customer_id
              AND    hzp.party_id = hzca.party_id
              AND    hzas.cust_account_id = arci.customer_id
              AND    arci.status IN ( 'FINAL','ACCEPTED')
              AND    hzsu.cust_acct_site_id       =hzas.cust_acct_site_id
              AND    hzsu.site_use_code='SHIP_TO'
              AND    NOT EXISTS (
                     SELECT /*+ no_unnest qb_name(subq1) */ 1 -- Added HINT for QC Defect # 25206
                       FROM xx_ar_cons_bills_history
                      WHERE 1 = 1
                        AND attribute6 = TO_CHAR (arci.cons_inv_id)
                        AND attribute4 = attribute4
                        AND attribute8 = 'PAYDOC_IC'
                        AND customer_id = arci.customer_id
                        AND document_id = cdh_bill_header.billdocs_doc_id
                        AND cust_doc_id = cdh_bill_header.billdocs_cust_doc_id
                        AND process_flag = 'Y')
              AND EXISTS (SELECT /*+ no_unnest qb_name(subq2) */ 1 -- Added HINT for QC Defect # 25206
                            FROM ar_cons_inv_trx_lines
                           WHERE 1 = 1 AND cons_inv_id = arci.cons_inv_id)
              AND EXISTS (SELECT 1
                            FROM ar_cons_inv_trx acit
                                ,ra_customer_trx_all rct
                            WHERE cons_inv_id = arci.cons_inv_id
                            and rct.customer_trx_id= acit.customer_trx_id
                            and rct.ship_to_site_use_id=hzsu.site_use_id)
              AND mbs_doc_master.document_id = cdh_bill_header.billdocs_doc_id
/*              AND TO_CHAR (g_as_of_date, 'DD') =
                     TO_CHAR
                        (xx_ar_inv_freq_pkg.compute_effective_date
                                                (cdh_bill_header.billing_term,
                                                -- g_as_of_date   -- commented for defect 10750
                                                 --TRUNC (arci.cut_off_date-1)   -- added for defect 10750  --Commented for Defect# 15063.
                                                 TO_DATE(ARCI.attribute1) - 1   -- Added for Defect# 15063.
                                                ),
                         'DD'
                        )  */  -- Commented for Defect # 869
/*
---------------------------------------------------------------------------------
To avoid offcycle bills and to handle newly added infodocs for PAYDOC_IC Customer
---------------------------------------------------------------------------------
               AND xx_ar_inv_freq_pkg.compute_effective_date
                                                (cdh_bill_header.billing_term,
                                                 --TRUNC (arci.cut_off_date-1)  -- Commented for Defect# 15063.
                                                 TO_DATE(ARCI.attribute1) - 1   -- Added for Defect# 15063.
                                                ) <= g_as_of_date
*/  --Commented on 16-NOV-09 for Defect #2858
----------------------------------------
--Start of Changes for the Defect #2858
----------------------------------------
             AND xx_ar_inv_freq_pkg.compute_effective_date
                                                        (cdh_bill_header.billing_term
                                                        ,g_as_of_date
                                                        ) = g_as_of_date
/*             AND xx_ar_inv_freq_pkg.compute_effective_date
                                                        (cdh_bill_header.billing_term
                                                        ,TO_DATE(arci.attribute1)-1
                                                        ) >= cdh_bill_header.creation_date
*/ -- Commented for CR 738 changes   -- Added the below condition for R1.3 CR 738 Defect 2766
            AND xx_ar_gen_ebill_pkg.xx_ar_infocopy_handling(arci.attribute2
                                                            ||arci.attribute4
                                                            ||arci.attribute10
                                                            ||ARCI.attribute15      -- Added for R1.4 CR# 586. In order to handle the ebill delivery methods.
                                                            ,cdh_bill_header.billing_term
                                                            ,TO_DATE(arci.attribute1) - 1
                                                            ,cdh_bill_header.effec_start_date
                                                            ,g_as_of_date
                                                            ) = 'Y'
-- End of changes for R1.3 CR 738 Defect 2766
----------------------------------------
--End of Changes for the Defect #2858
----------------------------------------
         GROUP BY  arci.cons_inv_id
                  --,TRUNC (arci.cut_off_date)  -- Commented for Defect# 15063.
                  ,TO_DATE(ARCI.attribute1)     -- Added for Defect# 15063.
                  ---,arci.cut_off_date         -- Commented for Defect# 15063.
                  ,TO_DATE(ARCI.attribute1)     -- Added for Defect# 15063.
                  ,arci.customer_id
                  ,cdh_bill_header.billdocs_cust_doc_id
                  ,cdh_bill_header.billdocs_doc_id
                  ,cdh_bill_header.direct_flag
                  ,mbs_doc_master.doc_sort_order
                  ,mbs_doc_master.total_through_field_id
                  ,mbs_doc_master.page_break_through_id
                  ,cdh_bill_header.billdocs_paydoc_ind
                  ,cdh_bill_header.billdocs_num_copies
                  ,TRIM (mbs_doc_master.doc_detail_level)
                  ,cdh_bill_header.billdocs_delivery_meth
                  ,cdh_bill_header.billing_term
                  ,cdh_bill_header.extension_id
                  ,arci.cons_billing_number
                  ,xx_ar_print_summbill.get_paydoc_ic_siteuse_id(hzas.cust_acct_site_id
                                                               ,cdh_bill_header.billdocs_cust_doc_id
                                                               ,arci.customer_id
                                                               ,hzsu.site_use_id
                                                               ,cdh_bill_header.direct_flag)
                  ,hzca.account_number
                  ,hzca.attribute18
                  ,hzp.party_name
                  ,hzca.orig_system_reference
                  ,arci.currency_code
         ORDER BY "customer_id"
                  ,arci.cons_inv_id
                  ,"document_id"
                  ,"cust_doc_id"
                  ,"site_use_id";

      CURSOR get_inv_amount (
         p_customer_id   IN   NUMBER,
         p_source_id     IN   NUMBER,
         p_doc_id        IN   NUMBER
      )
      IS
      /*   SELECT SUM (NVL (arps.amount_due_original, 0)) amount_due      Commented for the defect 12925
           FROM ar_payment_schedules arps
          WHERE 1 = 1
            AND arps.CLASS = 'INV'
            AND arps.customer_trx_id IN (
                   SELECT TO_NUMBER (attribute1)
                     FROM xx_ar_cons_bills_history od_summbills
                    WHERE 1 = 1
                      AND od_summbills.attribute8 = 'INV_IC'
                      AND od_summbills.document_id = p_doc_id
                      AND od_summbills.customer_id = p_customer_id
                      AND od_summbills.thread_id = p_thread_id
                      AND od_summbills.process_flag != 'Y'); */
           --Added for the defect 12925
           SELECT NVL(SUM(arps.amount_due_original), 0) amount_due
           FROM ar_payment_schedules arps
               ,xx_ar_cons_bills_history od_summbills
          WHERE 1 = 1
            AND arps.CLASS = 'INV'
            AND arps.customer_trx_id = TO_NUMBER(od_summbills.attribute1)
            AND od_summbills.attribute8 = 'INV_IC'
            AND od_summbills.document_id = p_doc_id
            AND od_summbills.customer_id = p_customer_id
            AND od_summbills.thread_id = p_thread_id
            AND od_summbills.process_flag != 'Y';

      --  Query3: Fetches all Invoice original docs and Info consolidated bills.

-- The following cursor has been commneted for defect # 10750

/*      CURSOR get_infocopy2_customers
      IS
         SELECT   SUBSTR(cdh_bill_header.direct_flag,1,1) direct_flag,  -- Added for the Defect # 10750
                  cdh_bill_header.billdocs_cust_doc_id cust_doc_id,
                  cdh_bill_header.billdocs_doc_id document_id,
                  mbs_doc_master.doc_sort_order sort_by,
                  cdh_bill_header.billdocs_paydoc_ind doc_flag,
                  cdh_bill_header.billdocs_num_copies total_copies,
                  TRIM (mbs_doc_master.doc_detail_level) layout,
                  'CONSOLIDATED BILL' format,
                  cdh_bill_header.billdocs_delivery_meth delivery,
                     SUBSTR
                        (mbs_doc_master.doc_sort_order,
                         1,
                         INSTR (mbs_doc_master.doc_sort_order,
                                mbs_doc_master.total_through_field_id
                               )
                        )
                  || '1' total_by,
                     SUBSTR
                        (mbs_doc_master.doc_sort_order,
                         1,
                         INSTR (mbs_doc_master.doc_sort_order,
                                mbs_doc_master.page_break_through_id
                               )
                        )
                  || '1' page_break,
                  cdh_bill_header.billing_term billing_term,
                  cdh_bill_header.extension_id extension_id,
                  cdh_bill_header.cust_account_id customer_id
             FROM (SELECT cust_account_id, extension_id, billdocs_doc_id,
                          billdocs_paydoc_ind,
--                          extension_id billdocs_cust_doc_id,   -- Commented for the Defect # 10750
                          billdocs_cust_doc_id billdocs_cust_doc_id,  --Added for the Defect # 10750
                          billdocs_num_copies, billdocs_delivery_meth,
                          billdocs_payment_term billing_term,
                          billdocs_direct_flag direct_flag  -- Added for the Defect # 10750
                     FROM xx_cdh_a_ext_billdocs_v
                    WHERE 1 = 1
                      AND billdocs_doc_type = 'Consolidated Bill'
                      AND billdocs_delivery_meth = 'PRINT'
                      AND NVL (billdocs_paydoc_ind, 'N') <> 'Y'
                      AND TRIM (billdocs_special_handling) IS NULL) cdh_bill_header,
                  xx_cdh_mbs_document_master mbs_doc_master
            WHERE 1 = 1
              AND mbs_doc_master.document_id = cdh_bill_header.billdocs_doc_id
         ORDER BY cdh_bill_header.cust_account_id,
                  cdh_bill_header.billdocs_doc_id;
*/

-- The following cursor has been Added for defect # 10750

/* Commented for 32498
      CURSOR get_infocopy2_customers(p_attr_group_id IN NUMBER)
      IS
         SELECT   SUBSTR(cdh_bill_header.direct_flag,1,1) direct_flag
                 ,cdh_bill_header.billdocs_cust_doc_id cust_doc_id
                 ,cdh_bill_header.billdocs_doc_id document_id
                 ,mbs_doc_master.doc_sort_order sort_by
                 ,cdh_bill_header.billdocs_paydoc_ind doc_flag
                 ,cdh_bill_header.billdocs_num_copies total_copies
                 ,TRIM (mbs_doc_master.doc_detail_level) layout
                 ,'CONSOLIDATED BILL' format
                 ,cdh_bill_header.billdocs_delivery_meth delivery
                 ,SUBSTR(mbs_doc_master.doc_sort_order,1,
                         INSTR (mbs_doc_master.doc_sort_order,mbs_doc_master.total_through_field_id)
                        )|| '1' total_by
                 ,SUBSTR(mbs_doc_master.doc_sort_order,1,
                         INSTR (mbs_doc_master.doc_sort_order,mbs_doc_master.page_break_through_id)
                        )|| '1' page_break
                 ,cdh_bill_header.billing_term billing_term
                 ,cdh_bill_header.extension_id extension_id
                 ,cdh_bill_header.cust_account_id customer_id
                 ,cdh_bill_header.creation_date -- Added for defect #2858
                 ,cdh_bill_header.effec_start_date  -- Added for R1.3 CR 738 Defect 2766
             FROM (SELECT cust_account_id
                         ,extension_id
                         ,n_ext_attr1 billdocs_doc_id
                         ,c_ext_attr2 billdocs_paydoc_ind
                         ,n_ext_attr2 billdocs_cust_doc_id
                         ,n_ext_attr3 billdocs_num_copies
                         ,c_ext_attr3 billdocs_delivery_meth
                         ,c_ext_attr14 billing_term
                         ,c_ext_attr7 direct_flag
                         ,TRUNC(creation_date) creation_date -- Added for defect #2858
                         ,d_ext_attr1 effec_start_date       -- Added for R1.3 CR 738 Defect 2766
                     FROM xx_cdh_cust_acct_ext_b
                    WHERE 1 = 1
                      AND c_ext_attr1 = 'Consolidated Bill'
                      AND c_ext_attr3 = 'PRINT'
                      AND NVL (c_ext_attr2, 'N') <> 'Y'
                      AND TRIM (c_ext_attr4) IS NULL
                      AND attr_group_id=p_attr_group_id
                      -- Added the below conditions for R1.3 CR 738 Defect 2766
                      AND g_as_of_date      >= d_ext_attr1
                      AND (d_ext_attr2      IS NULL
                           OR
                           g_as_of_date     <= d_ext_attr2)) cdh_bill_header
                      -- End of changes for R1.3 CR 738 Defect 2766
                  ,xx_cdh_mbs_document_master mbs_doc_master
            WHERE 1 = 1
              AND mbs_doc_master.document_id = cdh_bill_header.billdocs_doc_id
         ORDER BY cdh_bill_header.cust_account_id
                 ,cdh_bill_header.billdocs_doc_id;
*/ -- Commented for 32498

	  CURSOR get_infocopy2_customers IS
	  select * from xx_temp_certegy_cust_master
	  where org_id = fnd_profile.VALUE ('ORG_ID')
	  ORDER BY customer_id, document_id;

      CURSOR get_party_info (p_customer_id IN NUMBER)
      IS
         SELECT hzca.account_number billing_id,
                TRIM (UPPER (hzca.attribute18)) sales_channel,

              --SUBSTR (hzp.party_name, 1, 40) customer_name,
                SUBSTR (hzca.account_name, 1, 40) customer_name,
                SUBSTR (hzca.orig_system_reference, 1, 8) legacy_cust
           FROM hz_cust_accounts hzca
          --,hz_parties hzp
         WHERE  1 = 1 AND hzca.cust_account_id = p_customer_id;

      --AND hzp.party_id         =hzca.party_id;

      CURSOR get_infocopy2_invoices (
         p_customer_id     IN   NUMBER,
         p_source_id       IN   NUMBER,
         p_extension_id    IN   NUMBER,
         p_document_id     IN   NUMBER,
         p_billing_cycle   IN   VARCHAR2
        ,p_cust_doc_id     IN   NUMBER   --Added for the Defect # 10750
        ,p_direct_flag     IN   VARCHAR2  --Added for the Defect # 10750
--        ,p_creation_date   IN   DATE     -- Added for defect #2858          -- Commented for R1.3 CR 738 Defect 2766
        ,p_effec_date      IN    DATE      -- Added for R1.3 CR 738 Defect 2766
      )
      IS
	  --Added for defect 32498
	  SELECT *
	  FROM XX_AR_CERTEGY_INV_TEMP
	  WHERE customer_id = p_customer_id
	    AND Billing_Term = p_billing_cycle
		AND cust_doc_id = p_cust_doc_id
		and document_id = p_document_id
		and org_id = fnd_profile.VALUE ('ORG_ID')
	  ORDER BY site_use_id, invoice_id;
      ---Start modification by Adithya for defect#19754 on 13-Dec-2012
         /*SELECT  --  TRUNC (ratrx.creation_date) print_date,   -- commented for defect 10750
                  g_as_of_date     print_date,                  --added for defect 10750
                  ratrx.customer_trx_id invoice_id,
--                  ratrx.bill_to_site_use_id site_use_id,  --Commented for the Defect # 10750
                  xx_ar_print_summbill.get_inv_ic_siteuse_id(p_customer_id
                                                            ,hzsu.cust_acct_site_id
                                                            ,p_cust_doc_id
                                                            ,ratrx.ship_to_site_use_id
                                                            ,p_direct_flag) site_use_id,
                                      -- Added for the Defect # 10750 to get new mailing address site use id
                  'INV_IC' infocopy_tag, ratrx.invoice_currency_code currency
             FROM ar_payment_schedules aps,          --added aps for 9518
                                                ra_customer_trx ratrx
                 ,hz_cust_site_uses hzsu   --Added for the Defect # 10750
            WHERE 1 = 1
              AND ratrx.bill_to_customer_id = p_customer_id
              AND ratrx.batch_source_id <> p_source_id
              AND ratrx.customer_trx_id = aps.customer_trx_id
        --      AND aps.amount_due_remaining != 0  --Commented  for Defect# 631 (CR# 662)
              AND aps.amount_due_original NOT BETWEEN xx_ar_print_summbill.ln_write_off_amt_low
                      AND xx_ar_print_summbill.ln_write_off_amt_high  --Added  for Defect# 631 (CR# 662)
              AND ratrx.ship_to_site_use_id =  hzsu.site_use_id   --Added for the Defect # 10750
              AND NOT EXISTS (
                     SELECT 1
                       FROM xx_ar_cons_bills_history
                      WHERE 1 = 1
                        /*
                         Defect 10340
                         23-SEP-2008
                         Commented the below line as this caused the sql to return the invoice for each info copy run.
                        *-/
                        --AND attribute4 =p_billing_cycle
                        AND attribute4 = attribute4
                        AND attribute8 = 'INV_IC'
                        AND attribute1 = TO_CHAR (ratrx.customer_trx_id)
                        AND customer_id = ratrx.bill_to_customer_id
                        AND document_id = p_document_id
                        AND cust_doc_id = p_cust_doc_id  --Added for the Defect # 10750
                        AND process_flag = 'Y')
              AND NOT EXISTS (
                     SELECT 1
                       FROM ar_cons_inv_trx_lines arcitl
                      WHERE 1 = 1
                        AND arcitl.customer_trx_id = ratrx.customer_trx_id)
               AND EXISTS (
                     SELECT 1
                       FROM xx_ar_invoice_freq_history
                      WHERE 1 = 1
                        AND invoice_id = ratrx.customer_trx_id
                        AND paydoc_flag = 'Y'
                        AND xx_ar_inv_freq_pkg.compute_effective_date(p_billing_cycle
                                                                  --   ,TRUNC(actual_print_date) -- Commented for CR 738 defect 2766
                                                                     ,TRUNC(estimated_print_date) -- Added for CR 738 defect 2766
                                                              --       ) >= p_creation_date  --Added on 16-NOV-09 for defect #2858 -- Commented for CR 738 Defect 2766
                                                                     ) >= p_effec_date -- Added for CR 738 defect 2766
                          )
              /*AND TO_CHAR (g_as_of_date, 'DD') =
                     TO_CHAR
                        (xx_ar_inv_freq_pkg.compute_effective_date
                                                             (p_billing_cycle,
                                                           --   g_as_of_date -- commented for defect 10750
                                                              TRUNC (ratrx.trx_date)   -- added for defect 10750
                                                             ),
                         'DD'
                        ) */ --Commented for the defect #869
/*
-------------------------------------------------------------------------------
To avoid offcycle bills and to handle newly added infodocs for INV_IC Customer
-------------------------------------------------------------------------------
              AND xx_ar_inv_freq_pkg.compute_effective_date
                                                        (p_billing_cycle,
                                                        -- TRUNC (ratrx.trx_date) Commented for the defect #869
                                                        TRUNC(ratrx.creation_date) -- Added for the defect #869
                                                        ) <= g_as_of_date
*-/  -- Commented on 16-NOV-09 for Defect #2858
--------------------------------------------------
--Start of Changes for the Defect #2858
--------------------------------------------------
             AND xx_ar_inv_freq_pkg.compute_effective_date
                                                        (p_billing_cycle
                                                        ,g_as_of_date
                                                        ) = g_as_of_date
--------------------------------------------------
--End of Changes for the Defect #2858
--------------------------------------------------
         ORDER BY  --ratrx.bill_to_site_use_id  --Commented for the Defect # 10750
                   site_use_id   --Added for the Defect # 10750
                  , ratrx.customer_trx_id; */
/* Commented for Defect 32498
				  WITH XX_RA_CUST AS
  (SELECT
    g_as_of_date PRINT_DATE,
    RATRX.CUSTOMER_TRX_ID INVOICE_ID,
    XX_AR_PRINT_SUMMBILL.GET_INV_IC_SITEUSE_ID(p_customer_id ,HZSU.CUST_ACCT_SITE_ID ,p_cust_doc_id ,RATRX.SHIP_TO_SITE_USE_ID ,p_direct_flag ) SITE_USE_ID,
    'INV_IC' INFOCOPY_TAG,
    RATRX.INVOICE_CURRENCY_CODE CURRENCY
  FROM RA_CUSTOMER_TRX RATRX ,
    HZ_CUST_SITE_USES HZSU
  WHERE 1                       = 1
  AND RATRX.BILL_TO_CUSTOMER_ID = p_customer_id
  AND RATRX.SHIP_TO_SITE_USE_ID = HZSU.SITE_USE_ID
  AND ratrx.batch_source_id <> p_source_id
  AND NOT EXISTS
    (SELECT 1
    FROM XX_AR_CONS_BILLS_HISTORY
    WHERE 1          = 1
    AND ATTRIBUTE4   = ATTRIBUTE4
    AND ATTRIBUTE8   = 'INV_IC'
    AND ATTRIBUTE1   = TO_CHAR (RATRX.CUSTOMER_TRX_ID)
    AND CUSTOMER_ID  = RATRX.BILL_TO_CUSTOMER_ID
    AND DOCUMENT_ID  = p_document_id
    AND CUST_DOC_ID  = p_cust_doc_id
    AND PROCESS_FLAG = 'Y'
    )
  AND NOT EXISTS
    (SELECT 1
    FROM AR_CONS_INV_TRX_LINES ARCITL
    WHERE 1                    = 1
    AND ARCITL.CUSTOMER_TRX_ID = RATRX.CUSTOMER_TRX_ID
    )
  AND EXISTS
    (SELECT 1
    FROM XX_AR_INVOICE_FREQ_HISTORY
    WHERE 1                                                                                       = 1
    AND INVOICE_ID                                                                                = RATRX.CUSTOMER_TRX_ID
    AND PAYDOC_FLAG                                                                               = 'Y'
    AND XX_AR_INV_FREQ_PKG.COMPUTE_EFFECTIVE_DATE(p_billing_cycle ,TRUNC(ESTIMATED_PRINT_DATE) ) >= p_effec_date
    )
  AND XX_AR_INV_FREQ_PKG.COMPUTE_EFFECTIVE_DATE (p_billing_cycle ,g_as_of_date ) = g_as_of_date
  )
SELECT *
FROM XX_RA_CUST,
  AR_PAYMENT_SCHEDULES APS
WHERE XX_RA_CUST.INVOICE_ID = APS.CUSTOMER_TRX_ID
AND APS.AMOUNT_DUE_ORIGINAL NOT BETWEEN xx_ar_print_summbill.ln_write_off_amt_low AND xx_ar_print_summbill.ln_write_off_amt_high
ORDER BY  --ratrx.bill_to_site_use_id  --Commented for the Defect # 10750
                   XX_RA_CUST.site_use_id   --Added for the Defect # 10750
                  , XX_RA_CUST.INVOICE_ID ;
*/
--End modification by Adithya for Defect#19754 on 13-Dec-2012

      TYPE cbi_tab IS TABLE OF cbi_rec
         INDEX BY BINARY_INTEGER;

      TYPE cbi_info_tab IS TABLE OF cbi_info_rec
         INDEX BY BINARY_INTEGER; --Added for the Defect # 10750

      TYPE info_tab IS TABLE OF info_rec
         INDEX BY BINARY_INTEGER;

      c_org_id        CONSTANT hr_organization_units.organization_id%TYPE
                                               := fnd_profile.VALUE ('ORG_ID');
      c_who           CONSTANT fnd_user.user_id%TYPE
                                              := fnd_profile.VALUE ('USER_ID');
      c_when          CONSTANT DATE                                 := SYSDATE;
      cbi_documents            cbi_tab;
--      cbi_amt_documents        cbi_amount_rec;   -- Added for performance(12925)
      cbi_info_documents       cbi_info_tab;  --Added for the Defect # 10750
      info_documents           info_tab;
      lr_get_billing_cust      get_infocopy2_customers%ROWTYPE;
      lr_get_party_info        get_party_info%ROWTYPE;
      lr_infocopy2_inv_rec     get_infocopy2_invoices%ROWTYPE;
      ln_prev_seq_id           NUMBER                                     := 0;
      ln_prev_cons_bill_id     NUMBER                                     := 0;
      ln_prev_document_id      NUMBER                                     := 0;
      ln_prev_cust_id          NUMBER                                     := 0;
      ln_prev_site_use_id      NUMBER                                     := 0;
      lc_prev_cons_bill        VARCHAR2 (15);
      ln_cbi_amount_due        NUMBER                                     := 0;
      ln_ignore_batch_source   NUMBER                                     := 0;
      ln_thread_count          NUMBER                                     := 1;
      ln_break_id              NUMBER                                  := NULL;
      ln_thread_id             NUMBER                                  := NULL;
      lc_info_bill_term        VARCHAR2 (100);
      ln_prev_cust_doc_id      NUMBER                                  :=0;--Added for the Defect # 10750
      ln_prev_site_use_id1     NUMBER                                  :=0;--Added for the Defect # 10750
      ln_attr_group_id         NUMBER; --Added for the Defect # 10750
      lc_error_loc             VARCHAR2(500) := NULL; -- Added log message for Defect 10750
      lc_error_debug           VARCHAR2(500) := NULL; -- Added log message for Defect 10750
      ln_amount_due            NUMBER;
      ln_gc_inv_amt            NUMBER;                -- Added for R1.1 Defect # 1451 (CR 626)
      ln_gc_cm_amt             NUMBER;                -- Added for R1.1 Defect # 1451 (CR 626)

	  ln_start_time            DATE;    --Added for defect 32498
	  ln_total_time            NUMBER;  --Added for defect 32498
	  bln_first_rec			   BOOLEAN; --Added for defect 32498
	  lc_record_cnt			   NUMBER;  --Added for defect 32498

	  ln_max_trx_id            NUMBER := NVL(fnd_profile.VALUE ('OD_CERTEGY_MAX_TRX_ID'),479416000); -- Added for Defect 32498


      PROCEDURE proc_set_thread_id
      IS
      BEGIN
         ln_thread_id :=
                        p_request_id || '.' || LPAD (ln_thread_count, 5, '0');
      END proc_set_thread_id;
   BEGIN                                  /* Main */
                                      /* Set the initial ln_thread_id value */
      proc_set_thread_id;
      fnd_file.put_line (fnd_file.LOG, 'p_batch_size is: ' || p_batch_size);

      -- Start for defect # 10750

       lc_error_loc   :='Inside get-cons_bills Procedure' ; -- Added log message for Defect 10750
       lc_error_debug := NULL;                              -- Added log message for Defect 10750
       BEGIN
          SELECT attr_group_id
          INTO   ln_attr_group_id
          FROM   ego_attr_groups_v
          WHERE  attr_group_type = 'XX_CDH_CUST_ACCOUNT'
          AND    attr_group_name = 'BILLDOCS' ;

          SELECT attr_group_id
          INTO g_attr_group_id_site
          FROM ego_attr_groups_v
          WHERE attr_group_type = 'XX_CDH_CUST_ACCT_SITE'
          AND attr_group_name = 'BILLDOCS';

          fnd_file.put_line (fnd_file.LOG,'Attribute ID for the group name BILLDOCS and type XX_CDH_CUST_ACCOUNT is : '||ln_attr_group_id||
                            ' and Attribute ID for the group name BILLDOCS and type XX_CDH_CUST_ACCOUNT_SITE is : '||g_attr_group_id_site);

       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             fnd_file.put_line (fnd_file.LOG,'No attribute ID found for the group name BILLDOCS and type XX_CDH_CUST_ACCOUNT/XX_CDH_CUST_ACCOUNT_SITE');
          WHEN OTHERS THEN
             fnd_file.put_line (fnd_file.LOG,'More than one attribute ID found for the group name BILLDOCS and type XX_CDH_CUST_ACCOUNT/XX_CDH_CUST_ACCOUNT_SITE');
       END;

      -- End for defect # 10750

      FND_FILE.PUT_LINE(FND_FILE.LOG,'WRITEN_OFF_AMT_LOW_VALUE: '||xx_ar_print_summbill.ln_write_off_amt_low);   --Added for the Defect# 631 (CR 662)
      FND_FILE.PUT_LINE(FND_FILE.LOG,'WRITEN_OFF_AMT_HIGH_VALUE: '||xx_ar_print_summbill.ln_write_off_amt_high); --Added for the Defect# 631 (CR 662)


       lc_error_loc   :='Opening get_paydoc_cbi cursor' ; -- Added log message for Defect 10750
       lc_error_debug := NULL;                              -- Added log message for Defect 10750


      OPEN get_paydoc_cbi(ln_attr_group_id);

      LOOP
         FETCH get_paydoc_cbi
         BULK COLLECT INTO cbi_documents LIMIT p_batch_size;

         lc_error_loc   :='Inside get_paydoc_cbi cursor' ; -- Added log message for Defect 10750
         lc_error_debug := NULL;                              -- Added log message for Defect 10750

         EXIT WHEN cbi_documents.COUNT = 0;

         <<thread_idx>>

         FOR i IN cbi_documents.FIRST .. cbi_documents.LAST
         LOOP
            /* Handle the muti-threading for PayDocs */
            IF    ln_break_id IS NULL
               OR ln_break_id = cbi_documents (i).site_use_id
            THEN
               IF thread_idx.i = p_batch_size
               THEN
                  /* Thread is at p_batch_size, set the ln_break_id value */
                  ln_break_id := cbi_documents (i).site_use_id;
               ELSE
                  /* Not at p_batch_size, keep the same thread */
                  NULL;
               END IF;
            ELSIF ln_break_id != cbi_documents (i).site_use_id
            THEN
               /* New site_use_id, increment the thread count */
               ln_break_id := NULL;
               ln_thread_count := ln_thread_count + 1;
               /* Set the ln_thread_id value */
               proc_set_thread_id;
            END IF;
            -- Added for performance(12925)
/*              OPEN get_paydoc_amt_cbi(cbi_documents (i).customer_id,cbi_documents (i).cons_inv_id);

                  FETCH get_paydoc_amt_cbi
                  INTO cbi_amt_documents;

                  lc_error_loc   :='Inside get_paydoc_amt_cbi cursor' ;
                  lc_error_debug := 'Customer ID :'|| cbi_documents (i).customer_id
                                    ||' Cons Inv ID :'|| cbi_documents (i).cons_inv_id;

              -- End of Changes for Defect 12925(performance)
*/-- Commented for the Defect # 13574
            BEGIN
               SAVEPOINT square_1;

            -- Start of changes for R1.1 Defect # 1451 (CR 626)
              ln_amount_due   := cbi_documents(i).amount_due;

              lc_error_loc    := 'Getting the total gift card amount for Invoices';
              lc_error_debug  := 'cons_bill_id : '|| to_char(cbi_documents (i).cons_inv_id);
              SELECT  NVL(SUM(OP.payment_amount),0)
              INTO    ln_gc_inv_amt
              FROM    oe_payments OP
                     ,ra_customer_trx_all RCT
                     ,ar_cons_inv_trx_all ACIT
              WHERE   OP.header_id        = RCT.attribute14
              AND     RCT.customer_trx_id = ACIT.customer_trx_id
              AND     ACIT.cons_inv_id    = cbi_documents (i).cons_inv_id
              AND     ACIT.transaction_type = 'INVOICE';

              lc_error_loc    := 'Getting the total gift card amount for credit memos';
              lc_error_debug  := 'cons_bill_id : '|| to_char(cbi_documents (i).cons_inv_id);

              SELECT  NVL(SUM(ORT.credit_amount),0)
              INTO    ln_gc_cm_amt
              FROM    xx_om_return_tenders_all ORT
                     ,ra_customer_trx_all RCT
                     ,ar_cons_inv_trx_all ACIT
              WHERE   ORT.header_id       = RCT.attribute14
              AND     RCT.customer_trx_id = ACIT.customer_trx_id
              AND     ACIT.cons_inv_id    = cbi_documents (i).cons_inv_id
              AND     ACIT.transaction_type = 'CREDIT_MEMO';

              ln_amount_due := ln_amount_due - ln_gc_inv_amt + ln_gc_cm_amt;

        --End of changes for R1.1 Defect # 1451 (CR 626)

               BEGIN
                  SAVEPOINT square2;

                  lc_error_loc   :='Before Inserting into xx_ar_cbi_totals_v:PAYDOC' ; -- Added log message for Defect 12925
                  lc_error_debug := 'For CBI Number: '||cbi_documents (i).cons_bill_num;             -- Added log message for Defect 12925

                  INSERT INTO xx_ar_cbi_totals_v
                              (request_id,
                               customer_number,
                               cbi_number,
                               cbi_amount, doc_flag,
                               created_by, creation_date, last_updated_by,
                               last_update_date
                              )
                       VALUES (ln_thread_id,                   --p_request_id
                               cbi_documents (i).billing_id,            -- Commented for performance(12925)--Uncommented for Defect # 13574
                              -- cbi_amt_documents.billing_id,           -- Added for performance(12925) --Commented for Defect # 13574
                               cbi_documents (i).cons_bill_num,
                             --  NVL (cbi_documents (i).amount_due, 0), --Commented for Defect # 1451 R1.1 CR 626   -- Commented for performance(12925) --Uncommented for Defect # 13574
                             --  NVL(cbi_amt_documents.amount_due, 0),   --Added for performance(12925)  --Commented for Defect # 13574
                               NVL (ln_amount_due, 0),                -- Added for Defect # 1451 R1.1 CR 626
                              'P',
                               c_who, c_when, c_who,
                               c_when
                              );

                  lc_error_loc   :='After Inserting into xx_ar_cbi_totals_v:PAYDOC' ; -- Added log message for Defect 12925
                  lc_error_debug := 'For CBI Number: '||cbi_documents (i).cons_bill_num;             -- Added log message for Defect 12925

               EXCEPTION
                  WHEN OTHERS
                  THEN
                     fnd_file.put_line
                        (fnd_file.LOG,
                         'ERROR DURING INSERT OF CERTEGY CONTROL TOTALS INTO XX_AR_CBI_TOTALS_V AT CURSOR GET_PAYDOC_CBI. PAY DOC CBI NUMBER:'
                        );  -- Chnaged for Defect #11769
                     fnd_file.put_line (fnd_file.LOG, SQLERRM);
                      fnd_file.put_line (fnd_file.LOG,
                                         'Error:'||lc_error_loc||'Debug:'||lc_error_debug);  -- Added for Defect 12925
                     ROLLBACK TO square2;
               END;

               lc_error_loc   :='Before Inserting into xx_ar_cons_bills_history:PAYDOC' ; -- Added log message for Defect 10750
               lc_error_debug := 'For CBI: '||cbi_documents (i).cons_bill_num;             -- Added log message for Defect 10750

               INSERT INTO xx_ar_cons_bills_history
                           (cons_inv_id,
                            print_date, process_flag,
                            customer_id,
                            cust_doc_id,
                            document_id,
                            sort_by,
                            paydoc,
                            total_copies,
                            layout,
                            format,
                            delivery,
                            attribute1,                       --customer_trx_id
                            attribute2,                              --total_by
                            attribute3,                            --page_break
                            attribute4,                          --billing_term
                            attribute5,                          --extension_id
                            attribute6,                   --cons_billing_number
                            attribute7,                   --billing_site_use_id
                            attribute8,            --pay doc records will ignore this field.
                            attribute9,                            --billing_id
                            attribute10,                        --sales channel
                            attribute11,                        --customer_name
                            attribute12,           --legacy customer number called as account number in MBS
                            attribute13,                --concurrent request_id
                            attribute14,           --cons bill total amount due
                            attribute15,                   --cons bill currency
                            created_by,
                            creation_date,
                            last_updated_by,
                            last_update_date,
                            org_id,
                            thread_id,
                            attribute16    --Added for Defect # 13403  for cons inv id
                           )
                    VALUES (cbi_documents (i).cons_inv_id,
                            cbi_documents (i).print_date, 'N',
                            cbi_documents (i).customer_id,
                            cbi_documents (i).cust_doc_id,
                            cbi_documents (i).document_id,
                            cbi_documents (i).sort_by,
                            cbi_documents (i).doc_flag,
                            cbi_documents (i).total_copies,
                            cbi_documents (i).layout,
                            cbi_documents (i).format,
                            cbi_documents (i).delivery,
                            cbi_documents (i).invoice_id,
                            cbi_documents (i).total_by,
                            cbi_documents (i).page_break,
                            cbi_documents (i).billing_term,
                            cbi_documents (i).extension_id,
                            cbi_documents (i).cons_bill_num,
                            cbi_documents (i).site_use_id,
                            cbi_documents (i).infocopy_tag,
                            cbi_documents (i).billing_id,
                            cbi_documents (i).sales_channel,
                            cbi_documents (i).customer_name,
                            cbi_documents (i).legacy_cust,              -- Commented for Performance(12925)
                       /*     -- Added for performance(10750)
                            cbi_amt_documents.billing_id,
                            cbi_amt_documents.sales_channel,
                            cbi_amt_documents.customer_name,
                            cbi_amt_documents.legacy_cust,
                            -- End of Changes for Performance (10750)
                        */    p_request_id,
                            --NVL (cbi_documents (i).amount_due, 0)          -- Commented for Performance(12925)  --Uncommented for Defect # 13574     -- Commented for R1.1 Defect # 1451 (CR 626)
                          --  NVL (cbi_amt_documents.amount_due, 0),          -- Added for Performance(12925)  --Commented for Defect # 13574
                            NVL(ln_amount_due,0),                             -- Added for the R1.1 Defect # 1451 (CR 626)
                            cbi_documents (i).currency,
                            c_who,                         --FND_GLOBAL.USER_ID
                            c_when,
                            c_who,                         --FND_GLOBAL.USER_ID
                            c_when,
                            c_org_id,
                            ln_thread_id,
                            cbi_documents (i).cons_inv_id   --Added for Defect # 13403  -- cons inv id
                           );
                lc_error_loc   :='After Inserting into xx_ar_cons_bills_history:PAYDOC' ; -- Added log message for Defect 12925
                lc_error_debug := 'For CBI: '||cbi_documents (i).cons_bill_num;             -- Added log message for Defect 12925

            EXCEPTION
               WHEN OTHERS
               THEN
                  fnd_file.put_line
                        (fnd_file.LOG,
                         'ERROR DURING INSERT OF CERTEGY CONTROL TOTALS INTO XX_AR_CONS_BILLS_HISTORY AT CURSOR GET_PAYDOC_CBI. PAY DOC CBI NUMBER:'
                        );-- Chnaged for Defect #11769
                  fnd_file.put_line (fnd_file.LOG, SQLERRM);
                  fnd_file.put_line (fnd_file.LOG,
                                     'Error in get_paydoc_cbi cursorat :'
                                     ||lc_error_loc||'Debug: '||lc_error_debug); -- Added log message for Defect 12925

                  ROLLBACK TO square_1;
            END;

/*                   lc_error_loc   :='Closing Cursor get_paydoc_amt_cbi' ;
                   lc_error_debug := NULL;

            CLOSE get_paydoc_amt_cbi;              -- Added for Performance Changes(12925)
*/ -- Commented for the Defect # 13574
        END LOOP;
      END LOOP;

      lc_error_loc   :='Closing Cursor get_paydoc_cbi' ; -- Added log message for Defect 10750
      lc_error_debug := NULL;             -- Added log message for Defect 10750
      CLOSE get_paydoc_cbi;
     COMMIT; --Added for the Defect # 10750 (!!!)

--  /* Insert Certegy Totals */
--  BEGIN
--    SAVEPOINT square2;

      --    INSERT INTO xx_ar_cbi_totals_v
--     (
--       request_id
--      ,customer_number
--      ,cbi_number
--      ,cbi_amount
--      ,doc_flag
--      ,created_by
--      ,creation_date
--      ,last_updated_by
--      ,last_update_date
--     )
--    SELECT thread_id
--          ,attribute9 --billing_id
--          ,attribute6 --cons_billing_number
--          ,attribute14 --cons bill total amount due
--          ,'P'
--          ,c_who
--          ,c_when
--          ,c_who
--          ,c_when
--    FROM xx_ar_cons_bills_history
--    WHERE p_request_id = attribute13; --concurrent request_id

      --  EXCEPTION
--    WHEN OTHERS THEN
--      fnd_file.put_line(fnd_file.log ,'ERROR DURING INSERT OF CERTEGY CONTROL TOTALS. PAY DOC CBI NUMBER:');
--      fnd_file.put_line(fnd_file.log ,SQLERRM);
--      rollback to square2;
--  end;

      /* Reset the thread_id varaiables */
      ln_break_id := NULL;
      ln_thread_count := ln_thread_count + 1;
      /* Set the ln_thread_id value */
      proc_set_thread_id;

-- ===============================================
-- Insert all info copy bills ready to be sent...
-- These are info copies
-- ===============================================
      lc_error_loc   :='Before Opening get_infocopy1 Cursor:PAYDOC_IC' ; -- Added log message for Defect 10750
      lc_error_debug := NULL;             -- Added log message for Defect 10750
      OPEN get_infocopy1(ln_attr_group_id);
      LOOP
         FETCH get_infocopy1
         BULK COLLECT INTO cbi_info_documents LIMIT p_batch_size;
         EXIT WHEN cbi_info_documents.COUNT = 0;

         lc_error_loc   :='Inside get_infocopy1 Cursor:PAYDOC_IC' ; -- Added log message for Defect 10750
         lc_error_debug := NULL;             -- Added log message for Defect 10750
         <<thread_idx_infocopy1>>
         FOR i IN cbi_info_documents.FIRST .. cbi_info_documents.LAST
         LOOP
            /* Handle the muti-threading for InfoCopies */
            IF    ln_break_id IS NULL
               OR ln_break_id = cbi_info_documents (i).site_use_id
            THEN
               IF thread_idx_infocopy1.i = p_batch_size
               THEN
                  /* Thread is at p_batch_size, set the ln_break_id value */
                  ln_break_id := cbi_info_documents (i).site_use_id;
               ELSE
                  /* Not at p_batch_size, keep the same thread */
                  NULL;
               END IF;
            ELSIF ln_break_id != cbi_info_documents (i).site_use_id
            THEN
               /* New site_use_id, increment the thread count */
               ln_break_id := NULL;
               ln_thread_count := ln_thread_count + 1;
               /* Set the ln_thread_id value */
               proc_set_thread_id;
            END IF;

/*            IF (   (ln_prev_document_id = 0)
                OR (ln_prev_document_id != cbi_documents (i).document_id)
               )*/
            IF (ln_prev_document_id = 0)
               OR (cbi_info_documents (i).cons_bill_num <> lc_prev_cons_bill)
               OR (cbi_info_documents (i).document_id != ln_prev_document_id)
               OR (cbi_info_documents (i).cust_doc_id != ln_prev_cust_doc_id)
               OR (cbi_info_documents (i).site_use_id != ln_prev_site_use_id1)  --Added for the Defect # 10750
            THEN
               IF ln_prev_document_id = 0
               THEN
                  ln_prev_seq_id := 1;
               ELSE
                  ln_prev_seq_id := ln_prev_seq_id + 1;
               END IF;

               --ln_prev_cons_bill_id :=cbi_documents(i).cons_inv_id||ln_prev_seq_id;
               --lc_prev_cons_bill    :=cbi_documents(i).cons_bill_num||'-'||TO_CHAR(ln_prev_seq_id);
               lc_prev_cons_bill := cbi_info_documents (i).cons_bill_num;
               ln_prev_document_id := cbi_info_documents (i).document_id;
               ln_prev_cust_doc_id := cbi_info_documents (i).cust_doc_id;--Added for the Defect # 10750
               ln_prev_site_use_id1 := cbi_info_documents (i).site_use_id; --Added for the Defect # 10750
          ELSE
               ln_prev_document_id := cbi_info_documents (i).document_id;
            END IF;


            BEGIN
               SAVEPOINT square_1;

               BEGIN
                  SAVEPOINT square2;

                  lc_error_loc   :='Before Insering into xx_ar_cbi_totals_v for infocopy:PAYDOC_IC' ; -- Added log message for Defect 10750
                  lc_error_debug := 'For CBI'||cbi_info_documents (i).cons_bill_num;             -- Added log message for Defect 10750
                  INSERT INTO xx_ar_cbi_totals_v
                              (request_id,
                               customer_number,
                               cbi_number,
                               cbi_amount, doc_flag,
                               created_by, creation_date, last_updated_by,
                               last_update_date
                              )
                       VALUES (ln_thread_id                     --p_request_id
                                           ,
                               cbi_info_documents (i).billing_id,
                               cbi_info_documents (i).cons_bill_num,
                               --NVL (cbi_info_documents (i).amount_due, 0)--Commented for the Defect # 10750
                               0  --Added for the Defect # 10750
                              , 'S'
--S for same. S indicates the consolidated bill info copy is on the same cycle as paydoc.
                  ,
                               c_who, c_when, c_who,
                               c_when
                              );
               lc_error_loc   :='After Insering into xx_ar_cbi_totals_v for infocopy:PAYDOC_IC' ; -- Added log message for Defect 10750
               lc_error_debug := 'For CBI'||cbi_info_documents (i).cons_bill_num;             -- Added log message for Defect 10750
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     fnd_file.put_line
                        (fnd_file.LOG,
                         'ERROR DURING INSERT OF CERTEGY CONTROL TOTALS INTO XX_AR_CBI_TOTALS_V AT CURSOR GET_INFOCOPY1. PAY DOC CBI NUMBER:'
                        );-- Chnaged for Defect #11769
                     fnd_file.put_line (fnd_file.LOG, SQLERRM);
                     fnd_file.put_line(fnd_file.LOG,
                                       'Error in Infocopy:'
                                       ||lc_error_loc||'Debug: '||lc_error_debug);      -- Added log message for Defect 10750
                     ROLLBACK TO square2;
               END;

               lc_error_loc   :='Before Insering into xx_ar_cons_bills_history for infocopy:PAYDOC_IC' ; -- Added log message for Defect 10750
               lc_error_debug := 'For CBI'||lc_prev_cons_bill;             -- Added log message for Defect 10750
               -- Added additional column bill_from_date by Sarat on 30-JUL-08
               INSERT INTO xx_ar_cons_bills_history
                           (cons_inv_id,
                            print_date, process_flag,
                            customer_id,
                            cust_doc_id,
                            document_id,
                            sort_by,
                            paydoc,
                            total_copies,
                            layout,
                            format,
                            delivery,
                            attribute1                       --customer_trx_id
                                      ,
                            attribute2                              --total_by
                                      ,
                            attribute3                            --page_break
                                      ,
                            attribute4                          --billing_term
                                      ,
                            attribute5                          --extension_id
                                      ,
                            attribute6                   --cons_billing_number
                                      ,
                            attribute7                   --billing_site_use_id
                                      ,
                            attribute8
                                      --info copy from pay doc or just grouping of invoices...
               ,
                            attribute9                            --billing_id
                                      ,
                            attribute10                        --sales channel
                                       ,
                            attribute11                        --customer_name
                                       ,
                            attribute12
                                       --legacy customer number called as account number in MBS
               ,            attribute13                --concurrent request_id
                                       ,
                            attribute14           --cons bill total amount due
                                       ,
                            attribute15                   --cons bill currency
                                       ,
                            direct_flag,     --Added for the Defect # 10750 for direct_flag
                            created_by, creation_date,
                            last_updated_by, last_update_date,
                            bill_from_date                       -- ADDED 9044
                                          ,
                            org_id, thread_id
                           ,attribute16   --Added for Defect # 13403  for cons inv id
                           )
                    VALUES (cbi_info_documents (i).cons_inv_id1||thread_idx_infocopy1.i,
                            cbi_info_documents (i).print_date, 'N',
                            cbi_info_documents (i).customer_id,
                            cbi_info_documents (i).cust_doc_id,
                            cbi_info_documents (i).document_id,
                            cbi_info_documents (i).sort_by,
                            cbi_info_documents (i).doc_flag,
                            cbi_info_documents (i).total_copies,
                            cbi_info_documents (i).layout,
--                            cbi_info_documents (i).format,--Commented for the Defect # 10750
                            'CONSOLIDATED BILL',--Added for the Defect # 10750
                            cbi_info_documents (i).delivery,
--                            cbi_info_documents (i).invoice_id --Commented for the Defect # 10750
                              0  --Added for the Defect # 10750 -- INVOICE ID FOR PAYDOC INFO COPY IS ZERO
               ,
--                            cbi_info_documents (i).total_by,  --Commneted for the Defect # 10750
                            SUBSTR
                            (cbi_info_documents (i).sort_by,
                             1,
                             INSTR (cbi_info_documents (i).sort_by,
                                    cbi_info_documents (i).total_through_field_id
                                   )
                            ) || '1',  --Added for the Defect # 10750
--                            cbi_info_documents (i).page_break,   --Commneted for the Defect # 10750
                            SUBSTR
                            (cbi_info_documents (i).sort_by,
                             1,
                             INSTR (cbi_info_documents (i).sort_by,
                                    cbi_info_documents (i).page_break_through_id
                                   )
                            ) || '1', -- Added for the Defect # 10750
                            cbi_info_documents (i).billing_term,
                            cbi_info_documents (i).extension_id,
                            lc_prev_cons_bill,
                            cbi_info_documents (i).site_use_id,
--                            cbi_info_documents (i).infocopy_tag, --Commented for the Defect # 10750
                            'PAYDOC_IC',  --Added for the Defect # 10750
                            cbi_info_documents (i).billing_id,
                            TRIM (UPPER (cbi_info_documents (i).sales_channel)), --Added for the Defect # 10750
                            SUBSTR(cbi_info_documents (i).customer_name,1,xx_ar_print_summbill.ln_custname_size), --Added for the Defect # 10750
                            SUBSTR(cbi_info_documents (i).legacy_cust,1,xx_ar_print_summbill.lc_old_custnum_size), --Added for the Defect # 10750
                            p_request_id,
--                            NVL (cbi_info_documents (i).amount_due, 0), --Commneted for the Defect # 10750
                            0, --Added for the Defect # 10750
                            cbi_info_documents (i).currency,
                            cbi_info_documents (i).direct_flag,  --Added for the Defect # 10750
                            c_who                         --FND_GLOBAL.USER_ID
                                 , c_when,
                            c_who                         --FND_GLOBAL.USER_ID
                                 , c_when,
                            cbi_info_documents (i).cut_off_date       -- ADDED 9044
                                                          ,
                            c_org_id, ln_thread_id
                           ,cbi_info_documents (i).cons_inv_id1   -- cons inv id Added for the Defect # 13403
                           );
                           lc_error_loc   :='After Insering into xx_ar_cons_bills_history for infocopy:PAYDOC_IC' ; -- Added log message for Defect 10750
                           lc_error_debug := 'For CBI'||lc_prev_cons_bill;             -- Added log message for Defect 10750
-- The following code has been Commented for the Defect # 10750
            /*
              BEGIN
               update ar_cons_inv
                  set attribute2 ='Y'
                where cons_inv_id =cbi_info_documents(i).cons_inv_id;
              EXCEPTION
               WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.log ,'Failed to update ar_cons_inv attribute2 flag for cons_inv_id :'||cbi_info_documents(i).cons_inv_id);
                ROLLBACK;
              END;
            */
            EXCEPTION
               WHEN DUP_VAL_ON_INDEX
               THEN
                  fnd_file.put_line
                        (fnd_file.LOG,
                         'ERROR DURING INSERT OF CERTEGY CONTROL TOTALS INTO XX_AR_CBI_TOTALS_V AT CURSOR XX_AR_CONS_BILLS_HISTORY. PAY DOC CBI NUMBER:'
                        );-- Chnaged for Defect #11769
                  fnd_file.put_line (fnd_file.LOG, SQLERRM);

                  ROLLBACK TO square_1;
               WHEN OTHERS
               THEN
                  fnd_file.put_line
                        (fnd_file.LOG,
                         'ERROR DURING INSERT OF CERTEGY CONTROL TOTALS INTO XX_AR_CBI_TOTALS_V AT CURSOR XX_AR_CONS_BILLS_HISTORY. PAY DOC CBI NUMBER:'
                        );-- Chnaged for Defect #11769
                  fnd_file.put_line (fnd_file.LOG, SQLERRM);
                  fnd_file.put_line (fnd_file.LOG,
                                     'Error in cursor get_infocopy1 :'
                                     ||lc_error_loc||'Debug:'||lc_error_debug);     -- Added log message for Defect 10750
                  ROLLBACK TO square_1;
            END;
         END LOOP;
      END LOOP;

      CLOSE get_infocopy1;

      /* Reset the thread_id varaiables */
      ln_break_id := NULL;
      ln_thread_count := ln_thread_count + 1;
      /* Set the ln_thread_id value */
      proc_set_thread_id;
      ln_prev_cust_id := 0;
      ln_prev_document_id := 0;
      ln_prev_cons_bill_id := 0;
      lc_prev_cons_bill := TO_CHAR (NULL);

-- ===============================================
-- Insert all info copy bills ready to be sent...
-- These are info copies
-- ===============================================
      BEGIN
         SELECT batch_source_id
           INTO ln_ignore_batch_source
           FROM ra_batch_sources
          WHERE NAME = 'CONVERSION_OD';
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line
                  (fnd_file.LOG,
                   'Error in getting batch source id for converted invoices.'
                  );
            fnd_file.put_line
                  (fnd_file.LOG,
                   'This is required otherwise we would be checking available'
                  );
            fnd_file.put_line
               (fnd_file.LOG,
                'invoice records that are part of conversion and will affect the performance of the Certegy program.'
               );
            raise_application_error (-20000,
                                     'Exit now, Please check the issue.'
                                    );
      END;

	   --START for defect # 32498
	  ln_start_time := sysdate;
	  begin
	  execute immediate 'DELETE FROM xx_temp_certegy_cust_master WHERE ORG_ID = ' || fnd_profile.VALUE ('ORG_ID');
	  execute immediate 'DELETE FROM XX_TEMP_CERTEGY_FREQ_INV WHERE ORG_ID = ' || fnd_profile.VALUE ('ORG_ID');
	  execute immediate 'DELETE FROM XX_AR_CERTEGY_INV_TEMP WHERE ORG_ID = ' || fnd_profile.VALUE ('ORG_ID');
	  --execute immediate 'alter index XX_Tmp_CUST_MASTER_N1 UNUSABLE';

      insert into xx_temp_certegy_cust_master
      SELECT   SUBSTR(cdh_bill_header.direct_flag,1,1) direct_flag
                 ,cdh_bill_header.billdocs_cust_doc_id cust_doc_id
                 ,cdh_bill_header.billdocs_doc_id document_id
                 ,mbs_doc_master.doc_sort_order sort_by
                ,cdh_bill_header.billdocs_paydoc_ind doc_flag
                 ,cdh_bill_header.billdocs_num_copies total_copies
                 ,TRIM (mbs_doc_master.doc_detail_level) layout
                 ,'CONSOLIDATED BILL' format
                 ,cdh_bill_header.billdocs_delivery_meth delivery
                 ,SUBSTR(mbs_doc_master.doc_sort_order,1,
                         INSTR (mbs_doc_master.doc_sort_order,mbs_doc_master.total_through_field_id)
                        )|| '1' total_by
                 ,SUBSTR(mbs_doc_master.doc_sort_order,1,
                         INSTR (mbs_doc_master.doc_sort_order,mbs_doc_master.page_break_through_id)
                        )|| '1' page_break
                 ,cdh_bill_header.billing_term billing_term
                 ,cdh_bill_header.extension_id extension_id
                 ,cdh_bill_header.cust_account_id customer_id
                 ,cdh_bill_header.creation_date -- Added for defect #2858
                 ,cdh_bill_header.effec_start_date  -- Added for R1.3 CR 738 Defect 2766
				 ,hzca.account_number billing_id
                 ,TRIM (UPPER (hzca.attribute18)) sales_channel
                 ,SUBSTR (hzca.account_name, 1, 40) customer_name
                 ,SUBSTR (hzca.orig_system_reference, 1, 8) legacy_cust
				 ,SUBSTR (ra.description, 1, 15) info_bill_term
				 ,fnd_profile.VALUE ('ORG_ID') ORG_ID
             FROM (SELECT cust_account_id
                         ,extension_id
                         ,n_ext_attr1 billdocs_doc_id
                         ,c_ext_attr2 billdocs_paydoc_ind
                         ,n_ext_attr2 billdocs_cust_doc_id
                         ,n_ext_attr3 billdocs_num_copies
                         ,c_ext_attr3 billdocs_delivery_meth
                         ,c_ext_attr14 billing_term
                         ,c_ext_attr7 direct_flag
                         ,TRUNC(creation_date) creation_date -- Added for defect #2858
                         ,d_ext_attr1 effec_start_date       -- Added for R1.3 CR 738 Defect 2766
                     FROM xx_cdh_cust_acct_ext_b
                    WHERE 1 = 1
                      AND c_ext_attr1 = 'Consolidated Bill'
                      AND c_ext_attr3 = 'PRINT'
                      AND NVL (c_ext_attr2, 'N') <> 'Y'
                      AND TRIM (c_ext_attr4) IS NULL
                      AND attr_group_id=166--p_attr_group_id
                      -- Added the below conditions for R1.3 CR 738 Defect 2766
                      AND g_as_of_date      >= d_ext_attr1
                      AND (d_ext_attr2      IS NULL
                           OR
                           g_as_of_date     <= d_ext_attr2)
					  AND XX_AR_INV_FREQ_PKG.COMPUTE_EFFECTIVE_DATE (c_ext_attr14 ,g_as_of_date ) = g_as_of_date) cdh_bill_header
                      -- End of changes for R1.3 CR 738 Defect 2766
                  ,xx_cdh_mbs_document_master mbs_doc_master
				  ,hz_cust_accounts hzca
				  ,ra_terms ra
            Where 1 = 1
              And Mbs_Doc_Master.Document_Id = Cdh_Bill_Header.Billdocs_Doc_Id
			  And cdh_bill_header.cust_account_id = hzca.cust_account_id
			  And ra.NAME = cdh_bill_header.billing_term;

			commit;
		--	execute immediate 'alter index XX_Tmp_CUST_MASTER_N1 REBUILD';


		--	execute immediate 'alter index Xx_ar_Tmp_certegy_freq_n1 UNUSABLE';
		--	execute immediate 'alter index Xx_ar_Tmp_certegy_freq_n2 UNUSABLE';
		--	execute immediate 'alter index Xx_ar_Tmp_certegy_freq_n3 UNUSABLE';
			Insert Into XX_TEMP_CERTEGY_FREQ_INV
            select a.invoice_id, b.customer_id, a.estimated_print_date, b.billing_term, b.effec_start_date, b.document_id, b.cust_doc_id, fnd_profile.VALUE ('ORG_ID') org_id
            FROM XX_AR_INVOICE_FREQ_HISTORY a, xx_temp_certegy_cust_master b
              WHERE 1                     = 1
                And A.Bill_To_Customer_Id = b.Customer_Id
				And a.invoice_id          >  ln_max_trx_id
				And b.org_id = fnd_profile.VALUE ('ORG_ID')
				and a.org_id = b.org_id
                And A.Paydoc_Flag         = 'Y';

			DELETE from XX_TEMP_CERTEGY_FREQ_INV hist
			WHERE EXISTS
					(SELECT 1
					 FROM AR_CONS_INV_TRX_LINES ARCITL
					 WHERE 1                      = 1
					   AND ARCITL.CUSTOMER_TRX_ID = hist.invoice_id
					)
			  AND org_id = fnd_profile.VALUE ('ORG_ID');

			DELETE FROM XX_TEMP_CERTEGY_FREQ_INV hist
            Where Xx_Ar_Inv_Freq_Pkg.Compute_Effective_Date(Billing_Term ,Trunc(Estimated_Print_Date))
                  < Effec_Start_Date
			  And org_id = fnd_profile.VALUE ('ORG_ID');

			DELETE FROM XX_TEMP_CERTEGY_FREQ_INV hist
			WHERE  EXISTS
					(SELECT 1
					FROM XX_AR_CONS_BILLS_HISTORY
					WHERE 1          = 1
					AND ATTRIBUTE8   = 'INV_IC'
					AND ATTRIBUTE1   = TO_CHAR (hist.invoice_id)
					AND DOCUMENT_ID  = hist.document_id
					AND CUSTOMER_ID  = hist.customer_id
					AND CUST_DOC_ID  = hist.cust_doc_id
					AND PROCESS_FLAG = 'Y'
					AND org_id = fnd_profile.VALUE ('ORG_ID')
					)
			  AND hist.org_id = fnd_profile.VALUE ('ORG_ID');

	        commit;

		--	execute immediate 'alter index Xx_ar_Tmp_certegy_freq_n1 REBUILD';
		--	execute immediate 'alter index Xx_ar_Tmp_certegy_freq_n2 REBUILD';
		--	execute immediate 'alter index Xx_ar_Tmp_certegy_freq_n3 REBUILD';

		--execute immediate 'alter index XX_AR_TMP_CERTEGY_N1 UNUSABLE';
		INSERT INTO XX_AR_CERTEGY_INV_TEMP
		SELECT	g_as_of_date PRINT_DATE,
		RATRX.CUSTOMER_TRX_ID INVOICE_ID,
		XX_AR_PRINT_SUMMBILL.GET_INV_IC_SITEUSE_ID(mast.customer_id ,HZSU.CUST_ACCT_SITE_ID ,mast.cust_doc_id ,RATRX.SHIP_TO_SITE_USE_ID ,mast.direct_flag ) SITE_USE_ID,
		'INV_IC' INFOCOPY_TAG,
		RATRX.INVOICE_CURRENCY_CODE CURRENCY,
		0 amount_due,
		mast.*
		FROM
		XX_TEMP_CERTEGY_FREQ_INV hist,
		RA_CUSTOMER_TRX RATRX ,
		HZ_CUST_SITE_USES HZSU ,
		AR_PAYMENT_SCHEDULES APS,
		xx_temp_certegy_cust_master mast
		where 1 = 1
		  AND hist.org_id  = fnd_profile.VALUE ('ORG_ID')
		  AND mast.org_id  = fnd_profile.VALUE ('ORG_ID')
		  AND RATRX.org_id = fnd_profile.VALUE ('ORG_ID')
		  AND HZSU.org_id  = fnd_profile.VALUE ('ORG_ID')
		  AND APS.org_id   = fnd_profile.VALUE ('ORG_ID')
		  AND hist.CUSTOMER_ID = mast.customer_id
		  AND RATRX.SHIP_TO_SITE_USE_ID = HZSU.SITE_USE_ID
		  AND ratrx.batch_source_id <> ln_ignore_batch_source
		  AND hist.invoice_id = ratrx.CUSTOMER_TRX_ID
		  And Aps.Customer_Trx_Id = Ratrx.Customer_Trx_Id
		  AND HIST.DOCUMENT_ID = MAST.DOCUMENT_ID
          AND HIST.CUST_DOC_ID = MAST.CUST_DOC_ID
		  And Aps.Amount_Due_Original Not Between xx_ar_print_summbill.ln_write_off_amt_low AND xx_ar_print_summbill.ln_write_off_amt_high;
        --ORDER BY   XX_RA_CUST.site_use_id
          --        , XX_RA_CUST.INVOICE_ID ;

		/*
		UPDATE XX_AR_CERTEGY_INV_TEMP TMP SET amount_due =
		  (
		  SELECT NVL(SUM(arps.amount_due_original), 0) amount_due
				   FROM ar_payment_schedules arps
					   ,xx_ar_cons_bills_history od_summbills
				  WHERE 1 = 1
					AND arps.CLASS = 'INV'
					AND arps.customer_trx_id = TO_NUMBER(od_summbills.attribute1)
					AND od_summbills.attribute8 = 'INV_IC'
					AND od_summbills.document_id = tmp.document_id
					AND od_summbills.customer_id = tmp.customer_id
					AND od_summbills.thread_id =   p_thread_id
					AND od_summbills.process_flag != 'Y'

			);
		*/
		--execute immediate 'alter index XX_AR_TMP_CERTEGY_N1 REBUILD';
		COMMIT;
		EXCEPTION
		WHEN OTHERS THEN
			fnd_file.put_line (fnd_file.LOG,'Error while generating Certegy data. ' || SQLERRM);
			rollback;
			RETURN;
		END;
       fnd_file.put_line (fnd_file.LOG,'time for invoice insert ' || round((sysdate - ln_start_time) *24 *60,0) || ' Min');
	   ln_total_time := 0;

	   bln_first_rec := false;
	   lc_record_cnt := 0;
	   --END   for defect # 32498

      OPEN get_infocopy2_customers;
	  fnd_file.put_line(fnd_file.log ,'INV_IC 1.1');
      LOOP
         FETCH get_infocopy2_customers
         BULK COLLECT INTO info_documents LIMIT p_batch_size;

         lc_error_loc    := 'Inside get_infocopy2_customer:INV_IC';      -- Added log message for Defect 10750
         lc_error_debug  := NULL; -- Added log message for Defect 10750
         EXIT WHEN info_documents.COUNT = 0;

         <<thread_idx_infocopy2>>
         FOR i IN info_documents.FIRST .. info_documents.LAST
         LOOP
--      fnd_file.put_line(fnd_file.log ,'info_documents (i).customer_id : ' ||info_documents (i).customer_id);  --Commented for the Defect # 10750

			/* Commented for defect 32498
            OPEN get_party_info (info_documents (i).customer_id);

            FETCH get_party_info
             INTO lr_get_party_info;
            lc_error_loc    := 'After Fetching get_party_info:INV_IC';      -- Added log message for Defect 10750
            lc_error_debug  := NULL ; -- Added log message for Defect 10750
            CLOSE get_party_info;
            */
            lc_error_loc    := 'Before get_infocopy2_invoices:INV_IC';      -- Added log message for Defect 10750
            lc_error_debug  := 'For Customer:'||info_documents (i).customer_id ; -- Added log message for Defect 10750

			bln_first_rec := FALSE; --Added for defect 32498

            FOR inv_rec IN
               get_infocopy2_invoices (info_documents (i).customer_id,
                                       ln_ignore_batch_source,
                                       info_documents (i).extension_id,
                                       info_documents (i).document_id,
                                       info_documents (i).billing_term
                                      ,info_documents (i).cust_doc_id  --Added for the Defect # 10750
                                      ,info_documents (i).direct_flag  --Added for the Defect # 10750
--                                      ,info_documents (i).creation_date --Added for the Defect # 2858    -- Commented for R1.3 CR 738 Defect 2766
                                      ,info_documents (i).effec_start_date           -- Added for R1.3 CR 738 Defect 2766
                                      )
            LOOP
			   -- START Added for defect 32498
				IF NOT bln_first_rec THEN
					lc_record_cnt := lc_record_cnt +1;
					bln_first_rec := TRUE;
				END IF;
				fnd_file.put_line (fnd_file.LOG,'Inside inv_rec');
			   --END
               /* Handle the muti-threading for InfoCopies */
               lc_error_loc    := 'Handling Multithreading for:INV_IC';      -- Added log message for Defect 10750
               lc_error_debug  := 'For customer'||info_documents (i).customer_id  ; -- Added log message for Defect 10750
			   --fnd_file.put_line(fnd_file.log ,'LOOP VALUE lc_record_cnt = ' || lc_record_cnt);
               IF ln_break_id IS NULL OR ln_break_id = inv_rec.site_use_id
               THEN
                  IF lc_record_cnt = p_batch_size
                  THEN
                     /* Thread is at p_batch_size, set the ln_break_id value */
                     ln_break_id := inv_rec.site_use_id;
                  ELSE
                     /* Not at p_batch_size, keep the same thread */
                     NULL;
                  END IF;
               ELSIF ln_break_id != inv_rec.site_use_id
               THEN
                  /* New site_use_id, increment the thread count */
				  ln_break_id := NULL;
				  lc_record_cnt := 0;
                  ln_thread_count := ln_thread_count + 1;
                  /* Set the ln_thread_id value */
                  proc_set_thread_id;
               END IF;

               IF (   (ln_prev_document_id = 0 AND ln_prev_site_use_id = 0
                      )                                         --First record
                   OR (ln_prev_site_use_id != inv_rec.site_use_id
                      )                         --Changing inv_rec.site_use_id
                   OR (    (ln_prev_site_use_id = inv_rec.site_use_id)
                       AND (ln_prev_document_id !=
                                                info_documents (i).document_id
                           )
                      )         --Same inv_rec.site_use_id, different document
                  )
               THEN

                  BEGIN
                     SELECT xx_ar_od_cbi_s.NEXTVAL
                       INTO ln_prev_cons_bill_id
                       FROM DUAL;

                     lc_prev_cons_bill := TO_CHAR (ln_prev_cons_bill_id);

                     BEGIN
                        FOR rec IN
                           get_inv_amount (info_documents (i).customer_id,
                                           ln_ignore_batch_source,
                                           info_documents (i).document_id
                                          )
                        LOOP
                           ln_cbi_amount_due := rec.amount_due;
                        END LOOP;
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           ln_cbi_amount_due := 0;
                        WHEN OTHERS
                        THEN
                           ln_cbi_amount_due := 0;
                     END;

                     BEGIN
                        SAVEPOINT square2;

                        lc_error_loc    := 'Before Insering into xx_ar_cbi_totals_v :INV_IC';      -- Added log message for Defect 10750
                        lc_error_debug  := 'For CBI'||ln_prev_cons_bill_id; -- Added log message for Defect 10750
                        INSERT INTO xx_ar_cbi_totals_v
                                    (request_id,
                                     customer_number,
                                     cbi_number,
                                     cbi_amount, doc_flag, created_by,
                                     creation_date, last_updated_by,
                                     last_update_date
                                    )
                             VALUES (ln_thread_id,
                                     --lr_get_party_info.billing_id, Commented for defect  32498
									 info_documents(i).billing_id,
                                     ln_prev_cons_bill_id,
                                     NVL (inv_rec.amount_due, 0), 'I', c_who,
                                     c_when, c_who,
                                     c_when
                                    );
                        lc_error_loc    := 'After Insering into xx_ar_cbi_totals_v :INV_IC';      -- Added log message for Defect 10750
                        lc_error_debug  := 'For CBI'||ln_prev_cons_bill_id; -- Added log message for Defect 10750
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           fnd_file.put_line
                              (fnd_file.LOG,
                               'ERROR DURING INSERT OF CERTEGY CONTROL TOTALS INTO XX_AR_CBI_TOTALS_V AT CURSOR GET_INFOCOPY2_CUSTOMERS. PAY DOC CBI NUMBER:'
                              );-- Chnaged for Defect #11769
                           fnd_file.put_line (fnd_file.LOG, SQLERRM);
                           ROLLBACK TO square2;
                     END;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        fnd_file.put_line
                              (fnd_file.LOG,
                               'Error in getting sequence for info copies...'
                              );
                        fnd_file.put_line (fnd_file.LOG,
                                           'Message :' || SQLERRM
                                          );
                       fnd_file.put_line(fnd_file.LOG,
                                         'Error while inserting into xx_ar_cbi_totals_v :INV_IC:'
                                         ||lc_error_loc||'Debug:'||lc_error_debug);    -- Added log message for Defect 10750
                  END;
               END IF;

               ln_prev_cust_id := info_documents (i).customer_id;
               ln_prev_site_use_id := inv_rec.site_use_id;
               ln_prev_document_id := info_documents (i).document_id;

               -- Defect 9545, Get the Payment Term Descripton
               --by Sarat Uppalapati on 05-AUG-08

               lc_error_loc    := 'Getting Payment Term Description:INV_IC';      -- Added log message for Defect 10750
               lc_error_debug  := 'For Billing Term'||info_documents (i).billing_term; -- Added log message for Defect 10750
               BEGIN
                  SELECT SUBSTR (description, 1, 15)
                    INTO lc_info_bill_term
                    FROM ra_terms
                   WHERE NAME = info_documents (i).billing_term;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     fnd_file.put_line
                          (fnd_file.LOG,
                           'Error in getting billing term for info copies...'
                          );
                     fnd_file.put_line (fnd_file.LOG, 'Message :' || SQLERRM);
               END;


               -- Inserted payment term description instead of payment term name for defect 9545
               -- by Sarat Uppalapati 05-AUG-08
               BEGIN
                  SAVEPOINT square_1;

                  lc_error_loc    := 'Before Inserting into xx_ar_cons_bills_history:INV_IC';      -- Added log message for Defect 10750
                  lc_error_debug  := 'For CBI'||lc_prev_cons_bill; -- Added log message for Defect 10750
				  ln_start_time := sysdate;
                  INSERT INTO xx_ar_cons_bills_history
                              (cons_inv_id, print_date,
                               process_flag, customer_id,
                               cust_doc_id,
                               document_id,
                               sort_by,
                               paydoc,
                               total_copies,
                               layout,
                               format,
                               delivery,
                               attribute1                    --customer_trx_id
                                         ,
                               attribute2                           --total_by
                                         ,
                               attribute3                         --page_break
                                         ,
                               attribute4                       --billing_term
                                         ,
                               attribute5                       --extension_id
                                         ,
                               attribute6                --cons_billing_number
                                         ,
                               attribute7                --billing_site_use_id
                                         , attribute8
                                                     --info copy from pay doc or just grouping of invoices...
                  ,
                               attribute9                         --billing_id
                                         ,
                               attribute10                     --sales channel
                                          ,
                               attribute11                     --customer_name
                                          ,
                               attribute12
                                          --legacy customer number called as account number in MBS
                  ,
                               attribute13             --concurrent request_id
                                          ,
                               attribute14, attribute15   --cons bill currency
                                                       ,
                               created_by, creation_date,
                               last_updated_by, last_update_date,
                               bill_from_date                   -- Defect 9044
                                             ,
                               org_id, thread_id
                              ,attribute16    -- Added for the Defect 13403 cons inv id
                              )
                       VALUES (ln_prev_cons_bill_id, inv_rec.print_date,
                               'N', info_documents (i).customer_id,
                               info_documents (i).cust_doc_id,
                               info_documents (i).document_id,
                               info_documents (i).sort_by,
                               info_documents (i).doc_flag,
                               info_documents (i).total_copies,
                               info_documents (i).layout,
                               info_documents (i).format,
                               info_documents (i).delivery,
                               inv_rec.invoice_id
                                                 --Customer trx id from ra_customer_trx_all.
                  ,
                               info_documents (i).total_by,
                               info_documents (i).page_break
                                                            --,info_documents(i).billing_term -- Defect 9545
                  ,
                               lc_info_bill_term                -- Defect 9545
                                                ,
                               info_documents (i).extension_id,
                               lc_prev_cons_bill,
                               inv_rec.site_use_id, inv_rec.infocopy_tag,
                               /* Commented for Defect 32498
							   lr_get_party_info.billing_id,
                               lr_get_party_info.sales_channel,
                               lr_get_party_info.customer_name,
                               lr_get_party_info.legacy_cust,
							   */
							   info_documents(i).billing_id,
							   info_documents(i).sales_channel,
							   info_documents(i).customer_name,
							   info_documents(i).legacy_cust,
                               p_request_id,
                               NVL (ln_cbi_amount_due, 0),
                               inv_rec.currency,
                               c_who                      --FND_GLOBAL.USER_ID
                                    , c_when,
                               c_who                      --FND_GLOBAL.USER_ID
                                    , c_when,
                               g_as_of_date           --sysdate -- Defect 9044
                                           ,
                               c_org_id, ln_thread_id
                              ,ln_prev_cons_bill_id   -- Added for defect 13403 cons inv id
                              );


				ln_total_time := ln_total_time + round((sysdate - ln_start_time) *24 *60 * 60,0);
               EXCEPTION
                  WHEN DUP_VAL_ON_INDEX
                  THEN
                           fnd_file.put_line
                              (fnd_file.LOG,
                               'ERROR DURING INSERT OF CERTEGY CONTROL TOTALS INTO XX_AR_CONS_BILLS_HISTORY AT CURSOR GET_INFOCOPY2_CUSTOMERS. PAY DOC CBI NUMBER:'
                              );-- Chnaged for Defect #11769
                           fnd_file.put_line (fnd_file.LOG, SQLERRM);
                     ROLLBACK TO square_1;
                  WHEN OTHERS
                  THEN
                           fnd_file.put_line
                              (fnd_file.LOG,
                               'ERROR DURING INSERT OF CERTEGY CONTROL TOTALS INTO XX_AR_CONS_BILLS_HISTORY AT CURSOR GET_INFOCOPY2_CUSTOMERS. PAY DOC CBI NUMBER:'
                              );-- Chnaged for Defect #11769
                           fnd_file.put_line (fnd_file.LOG, SQLERRM);
                           fnd_file.put_line (fnd_file.LOG,
                                              'Error in get_infocopy2_customers :'
                                              ||lc_error_loc||'Debug:'||lc_error_debug); -- Added log message for Defect 10750
                     ROLLBACK TO square_1;
               END;
            END LOOP;
         END LOOP;
      END LOOP;
      fnd_file.put_line (fnd_file.LOG, 'Total Time spent on insert statement in minutes ' || ln_total_time);
      CLOSE get_infocopy2_customers;
   --COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line ('3-' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG,
                                              'Error in get_cons_bills: '
                                              ||lc_error_loc||'Debug:'||lc_error_debug); -- Added log message for Defect 10750
         ROLLBACK;
   END get_cons_bills;

   FUNCTION get_od_contact_info
                                -- p_sales_channel -Incoming value
                                -- p_country       -Country code like US, CA...
                                -- p_contact_type is either 'ORDER' OR 'ACCOUNT'
   (
      p_sales_channel   IN   VARCHAR2 DEFAULT NULL,
      p_country         IN   VARCHAR2 DEFAULT NULL,
      p_contact_type    IN   VARCHAR2 DEFAULT NULL
   )
      RETURN VARCHAR2
   AS
      lc_ph_no_cusrv_order     ar_system_parameters.attribute3%TYPE
                                                            := TO_CHAR (NULL);
      lc_ph_no_cusrv_account   ar_system_parameters.attribute4%TYPE
                                                            := TO_CHAR (NULL);
      lc_error_loc    VARCHAR2(500) := NULL; -- Added log message for Defect 10750
      lc_error_debug  VARCHAR2(500) := NULL; -- Added log message for Defect 10750
   BEGIN
      lc_error_loc   := 'Inside get_od_contact_info'; -- Added log message for Defect 10750
      lc_error_debug := NULL ;                        -- Added log message for Defect 10750
      IF p_contact_type = 'ORDER'
      THEN
          lc_error_loc   := 'Inside IF p_contact_type = ORDER '; -- Added log message for Defect 10750
          lc_error_debug := NULL ;                        -- Added log message for Defect 10750
         IF (p_country = 'US' AND UPPER (p_sales_channel) = 'CONTRACT')
         THEN
            SELECT attribute3       --customer service order contact number...
              INTO lc_ph_no_cusrv_order
              FROM ar_system_parameters;

            RETURN lc_ph_no_cusrv_order;
         ELSIF (    p_country = 'US'
                AND (   p_sales_channel IS NULL
                     OR UPPER (p_sales_channel) != 'CONTRACT'
                    )
               )
         THEN
            SELECT attribute4       --customer service order contact number...
              INTO lc_ph_no_cusrv_order
              FROM ar_system_parameters;

            RETURN lc_ph_no_cusrv_order;
         ELSIF p_country = 'CA'
         THEN
            SELECT attribute4       --customer service order contact number...
              INTO lc_ph_no_cusrv_order
              FROM ar_system_parameters;

            RETURN lc_ph_no_cusrv_order;
         ELSE
            RETURN (TO_CHAR (NULL));
         END IF;
      ELSIF p_contact_type = 'ACCOUNT'
      THEN
          lc_error_loc   := 'Inside IF p_contact_type = ACCOUNT '; -- Added log message for Defect 10750
          lc_error_debug := NULL ;                        -- Added log message for Defect 10750
         IF (p_country = 'US' AND UPPER (p_sales_channel) = 'CONTRACT')
         THEN
            SELECT attribute5     --customer service account contact number...
              INTO lc_ph_no_cusrv_account
              FROM ar_system_parameters;

            RETURN lc_ph_no_cusrv_account;
         ELSIF (    p_country = 'US'
                AND (   p_sales_channel IS NULL
                     OR UPPER (p_sales_channel) != 'CONTRACT'
                    )
               )
         THEN
            SELECT attribute6     --customer service account contact number...
              INTO lc_ph_no_cusrv_account
              FROM ar_system_parameters;

            RETURN lc_ph_no_cusrv_account;
         ELSIF p_country = 'CA'
         THEN
            SELECT attribute6     --customer service account contact number...
              INTO lc_ph_no_cusrv_account
              FROM ar_system_parameters;

            RETURN lc_ph_no_cusrv_account;
         ELSE
            RETURN (TO_CHAR (NULL));
         END IF;
      ELSE
         /*...
          The ar system parameters doesn't store other customer service contact types....
         */
         RETURN TO_CHAR (NULL);
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN TO_CHAR (NULL);
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                               'get_od_contact_info: Outer block error -'
                            || SQLERRM
                           );
         DBMS_OUTPUT.put_line (   'get_od_contact_info: Outer block error -'
                               || SQLERRM
                              );
         fnd_file.put_line (fnd_file.LOG,
                            'Error in get_od_contact_info:'
                            || lc_error_loc||'Debug: '||lc_error_debug); -- Added log message for Defect 10750
   END get_od_contact_info;

   -- Start of Changes for  Defect 10998

   FUNCTION Get_Cer_CBI_Invoice_Total(p_cbi_id IN VARCHAR2)
     RETURN NUMBER
     IS

     ln_total_amount NUMBER;

      BEGIN

         SELECT SUM(extended_amount)
         INTO ln_total_amount
         FROM ra_customer_trx_lines_all RCTLA
             ,xx_ar_cons_bills_history_all XACBH
         WHERE XACBH.cons_inv_id=p_cbi_id
         AND   XACBH.attribute1=RCTLA.customer_trx_id;

             RETURN(ln_total_amount);

         EXCEPTION
          WHEN OTHERS THEN

           fnd_file.put_line(fnd_file.log,'Error-Get_Cer_CBI_Invoice_Total...'||SQLERRM);
           ln_total_amount := '0.00';
           RETURN(ln_total_amount);
      END;
 -- End of Changes for Defect 10998

/***** IMPORTANT NOTE *****
*****  Remit to logic is cloned at 3 locations XX_AR_PRINT_SUMMBILL_PKB.pkb,XX_AR_REMIT_ADDRESS_CHILD_PKG.pkb and XX_AR_EBL_COMMON_UTIL_PKG.pkb. Any changes done at one place
has to be synched in the other 2 places.*****/

   FUNCTION get_remitaddressid (p_bill_to_site_use_id IN NUMBER)
      RETURN NUMBER
   IS
      CURSOR remit_derive (
         inv_country       IN   VARCHAR2,
         inv_state         IN   VARCHAR2,
         inv_postal_code   IN   VARCHAR2
      )
      IS
         SELECT   rt.address_id
             FROM hz_cust_acct_sites a,
                  hz_party_sites party_site,
                  hz_locations loc,
                  ra_remit_tos rt
            WHERE a.cust_acct_site_id = rt.address_id
              AND a.party_site_id = party_site.party_site_id
              AND loc.location_id = party_site.location_id
              AND NVL (rt.status, 'A') = 'A'
              AND NVL (a.status, 'A') = 'A'
              AND (   NVL (rt.state, inv_state) = inv_state
                   OR (inv_state IS NULL AND rt.state IS NULL)
                  )
              AND (   (inv_postal_code BETWEEN rt.postal_code_low
                                           AND rt.postal_code_high
                      )
                   OR (    rt.postal_code_high IS NULL
                       AND rt.postal_code_low IS NULL
                      )
                  )
              AND rt.country = inv_country
         ORDER BY rt.postal_code_low,
                  rt.postal_code_high,
                  rt.state,
                  loc.address1,
                  loc.address2;

      CURSOR address (bill_site_use_id IN NUMBER)
      IS
         SELECT loc.state, loc.country, loc.postal_code
           FROM hz_cust_acct_sites a,
                hz_party_sites party_site,
                hz_locations loc,
                hz_cust_site_uses s
          WHERE a.cust_acct_site_id = s.cust_acct_site_id
            AND a.party_site_id = party_site.party_site_id
            AND loc.location_id = party_site.location_id
            AND s.site_use_id = bill_site_use_id;

      ln_remit_to_add            NUMBER :=0;  --added Defect 18203

      inv_state          hz_locations.state%TYPE;
      inv_country        hz_locations.country%TYPE;
      inv_postal_code    hz_locations.postal_code%TYPE;
      remit_address_id   hz_cust_acct_sites.cust_acct_site_id%TYPE;
      d                  VARCHAR2 (240);
      lc_error_loc    VARCHAR2(500) := NULL ;   -- Added log message for Defect 10750
      lc_error_debug  VARCHAR2(500) := NULL ;   -- Added log message for Defect 10750
   BEGIN


         fnd_file.put_line (fnd_file.LOG, '*****p_bill_to_site_use_id:  '||p_bill_to_site_use_id);

/***** IMPORTANT NOTE *****
*****  Remit to logic is cloned at 3 locations XX_AR_PRINT_SUMMBILL_PKB.pkb,XX_AR_REMIT_ADDRESS_CHILD_PKG.pkb and XX_AR_EBL_COMMON_UTIL_PKG.pkb. Any changes done at one place
has to be synched in the other 2 places.*****/

          BEGIN      -- --added Defect 18203
           SELECT artav.address_id
                INTO   ln_remit_to_add
                FROM   hz_cust_site_uses_all HCSUA
                      ,ar_remit_to_addresses_v ARTAV
                   -- ,ra_addresses_all RAA
                WHERE  HCSUA.site_use_code = 'BILL_TO'
               AND    HCSUA.attribute_category = 'BILL_TO'
                AND    HCSUA.status = 'A'
                AND    HCSUA.org_id = fnd_global.org_id --ln_org_id
                AND    HCSUA.site_use_id =p_bill_to_site_use_id --lc_cust_txn_rec.bill_to_site_use_id
                AND    HCSUA.attribute25 = ARTAV.attribute1;
             EXCEPTION
             WHEN OTHERS THEN
               ln_remit_to_add:=0;
            end;

   IF ln_remit_to_add =0 THEN  -- --added IF clause, only for above query as part of Defect 18203

   OPEN address (p_bill_to_site_use_id);

      FETCH address
       INTO inv_state, inv_country, inv_postal_code;

      lc_error_loc   := 'Inside get_remitaddressid cursor';   -- Added log message for Defect 10750
      lc_error_debug := NULL ;              -- Added log message for Defect 10750
      IF address%NOTFOUND
      THEN
         /* No Default Remit to Address can be found, use the default */
         inv_state := 'DEFAULT';  --commented defect 18203
         inv_country := 'DEFAULT';
         inv_postal_code := NULL;
      END IF;

      CLOSE address;

      OPEN remit_derive (inv_country, inv_state, inv_postal_code);

      FETCH remit_derive
       INTO remit_address_id;

      lc_error_loc   := 'Fetching remit derive';   -- Added log message for Defect 10750
      lc_error_debug := NULL ;              -- Added log message for Defect 10750
      IF remit_derive%NOTFOUND
      THEN
         CLOSE remit_derive;

         OPEN remit_derive ('DEFAULT', inv_state, inv_postal_code);

         FETCH remit_derive
          INTO remit_address_id;

         IF remit_derive%NOTFOUND
         THEN
            CLOSE remit_derive;

            OPEN remit_derive ('DEFAULT', inv_state, '');

            FETCH remit_derive
             INTO remit_address_id;

            IF remit_derive%NOTFOUND
            THEN
               CLOSE remit_derive;

               OPEN remit_derive ('DEFAULT', 'DEFAULT', '');

               FETCH remit_derive
                INTO remit_address_id;
            END IF;
         END IF;
      END IF;

      lc_error_loc   := 'Closing Remit_derive';   -- Added log message for Defect 10750
      lc_error_debug := NULL ;              -- Added log message for Defect 10750
      CLOSE remit_derive;

      RETURN (remit_address_id);
      ELSE
        RETURN (ln_remit_to_add); --added Defect 18203

        END IF;
   EXCEPTION
         WHEN OTHERS
         THEN
          fnd_file.put_line (fnd_file.LOG, 'Error in get_remitaddressid:  '||SQLERRM);
         -- fnd_file.put_line (fnd_file.LOG,'Error in get_remitaddressid:'
                   --          ||lc_error_loc||'Debug:'||lc_error_Debug);     -- Added log message for Defect 10750
          RETURN NULL;
   END get_remitaddressid;
/***** IMPORTANT NOTE *****
*****  Remit to logic is cloned at 3 locations XX_AR_PRINT_SUMMBILL_PKB.pkb,XX_AR_REMIT_ADDRESS_CHILD_PKG.pkb and XX_AR_EBL_COMMON_UTIL_PKG.pkb. Any changes done at one place
has to be synched in the other 2 places.*****/



   FUNCTION xx_fin_check_digit (
      p_account_number   VARCHAR2,
      p_invoice_number   VARCHAR2,
      p_amount           VARCHAR2
   )
      RETURN VARCHAR2
   IS
      v_account_number      VARCHAR2 (8)
                       := LPAD (REPLACE (p_account_number, ' ', '0'), 8, '0');
      v_account_number_cd   NUMBER;
      v_invoice_number      VARCHAR2 (12)
                      := LPAD (REPLACE (p_invoice_number, ' ', '0'), 12, '0');
      v_invoice_number_cd   NUMBER;
      v_amount              VARCHAR2 (11)
          := LPAD (REPLACE (REPLACE (p_amount, ' ', '0'), '-', '0'), 11, '0');
      v_amount_cd           NUMBER;
      v_value_out           VARCHAR2 (50);
      v_final_cd            NUMBER;
      lc_error_loc     VARCHAR2(500) := NULL; -- Added log message for Defect 10750
      lc_error_debug   VARCHAR2(500) := NULL; -- Added log message for Defect 10750
      FUNCTION f_check_digit (v_string VARCHAR2)
         RETURN NUMBER
      IS
         v_sum       NUMBER := 0;
         v_weight    NUMBER;
         v_product   NUMBER;
         lc_error_loc VARCHAR2(500) :=NULL;       -- Added log message for Defect 10750
          lc_error_debug   VARCHAR2(500) := NULL; -- Added log message for Defect 10750
      BEGIN
          lc_error_loc   := 'Inside f_check_digit function '; -- Added log message for Defect 10750
          lc_error_debug := NULL ;               -- Added log message for Defect 10750
         FOR i IN 1 .. LENGTH (v_string)
         LOOP
            /* Set the weight based on the character space */
            lc_error_loc   := 'Set the weight based on character Space'; -- Added log message for Defect 10750
            lc_error_debug := NULL ;               -- Added log message for Defect 10750
            IF MOD (i, 2) = 0
            THEN
               v_weight := 2;
            ELSE
               v_weight := 1;
            END IF;

            --fnd_file.put_line(fnd_file.log ,'Issue 1...');
            /* Calculate the weighted procduct */
            v_product := SUBSTR (v_string, i, 1) * v_weight;

            --fnd_file.put_line(fnd_file.log ,'Issue 1...');
            /* Add the digit or digits to the sum */
            IF LENGTH (v_product) = 1
            THEN
               v_sum := v_sum + v_product;
            ELSE
               v_sum :=
                      v_sum + SUBSTR (v_product, 1, 1)
                      + SUBSTR (v_product, 2);
            END IF;
         END LOOP;

          lc_error_loc   := 'Checking digit is 10-the mod10 of the sum '; -- Added log message for Defect 10750
          lc_error_debug := NULL ;               -- Added log message for Defect 10750
         /* Check digit is 10-the mod10 of the sum */
         IF (MOD (v_sum, 10) = 0)
         THEN                                                   -- defect 7629
            v_sum := 0;
         ELSE
            v_sum := 10 - MOD (v_sum, 10);
         END IF;

         RETURN v_sum;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG,
                               'Problem in function f_check_digit...'
                              );
            fnd_file.put_line (fnd_file.LOG,
                               'Account Number    :' || p_account_number
                              );
            fnd_file.put_line (fnd_file.LOG,
                               'Invoice Number    :' || p_invoice_number
                              );
            fnd_file.put_line (fnd_file.LOG,
                               'Amount            :' || p_amount);
            fnd_file.put_line (fnd_file.LOG, SQLERRM);
            fnd_file.put_line (fnd_file.LOG,'Error in f_check_digit:'
                               ||lc_error_loc||'Debug:'||lc_error_debug);  -- Added log message for Defect 10750
            NULL;
      END;
   BEGIN
      lc_error_loc   := 'Inside xx_fin_check_digit '; -- Added log message for Defect 10750
      lc_error_debug := NULL ;               -- Added log message for Defect 10750
      /* Calculate the account check digit */
      --fnd_file.put_line(fnd_file.log ,'Issue 2...');
      v_account_number_cd := f_check_digit (v_account_number);
      --fnd_file.put_line(fnd_file.log ,'Issue 2...');

      /* Calculate the invoice check digit */
      v_invoice_number_cd := f_check_digit (v_invoice_number);


      /* Set the amount check digit */
      IF p_amount > 0
      THEN
         v_amount_cd := 1;
      ELSE
         v_amount_cd := 0;
      END IF;

      /* Calculate the final check digit */
      lc_error_loc   := 'Before Calling f_check_digit Function '; -- Added log message for Defect 10750
      lc_error_debug := NULL ;               -- Added log message for Defect 10750
      v_final_cd :=
         f_check_digit (   v_account_number
                        || v_account_number_cd
                        || v_invoice_number
                        || v_invoice_number_cd
                        || v_amount
                        || v_amount_cd
                       );
      lc_error_loc   := 'After Calling f_check_digit Function '; -- Added log message for Defect 10750
      lc_error_debug := NULL ;               -- Added log message for Defect 10750
      /* Build and return the out value */
      v_value_out :=
            v_account_number
         || v_account_number_cd
         || ' '
         || v_invoice_number
         || v_invoice_number_cd
         || ' '
         || v_amount
         || ' '
         || v_amount_cd
         || ' '
         || v_final_cd;
      RETURN v_value_out;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'Problem in function xx_fin_check_digit...'
                           );
         fnd_file.put_line (fnd_file.LOG, SQLERRM);
         fnd_file.put_line (fnd_file.LOG,
                            'Error in XX_FIN_CHECK_DIGIT:'
                            ||lc_error_loc||'Debug:'||lc_error_debug );   -- Added log message for Defect 10750
         RETURN NULL;
   END xx_fin_check_digit;



   FUNCTION get_cbi_amount_due (
      p_cbi_id                IN   NUMBER,
      p_ministmnt_line_type        VARCHAR2                         --TOTAL...
   )
      RETURN NUMBER
   AS
      ln_ext_amt_plus_delvy   NUMBER := 0;
      ln_promo_and_disc       NUMBER := 0;
      ln_tax_amount           NUMBER := 0;
      ln_total_amount         NUMBER := 0;
      lc_return_amount        NUMBER := 0;
      lc_error_loc            VARCHAR2(500) := NULL ;  -- Added log message for Defect 10750
      lc_error_debug          VARCHAR2(500) := NULL ;  -- Added log message for Defect 10750
   BEGIN
      lc_error_loc   :='Inside Get_cbi_amount_due';   -- Added log message for Defect 10750
      lc_error_debug := NULL;                         -- Added log message for Defect 10750
      IF p_ministmnt_line_type = 'EXTAMT_PLUS_DELVY'
      THEN
          lc_error_loc   :='Calculating EXTAMT_PLUS_DELVY ';   -- Added log message for Defect 10750
          lc_error_debug := 'FOR CBI'||p_cbi_id;                         -- Added log message for Defect 10750
         BEGIN
             /* SELECT SUM (NVL (ractl.extended_amount, 0))  --Commented for the defect  12925
              INTO ln_ext_amt_plus_delvy
              FROM ra_customer_trx_lines ractl
             WHERE 1 = 1
               --AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'  --For release 1 we need invoices sourced from AOPS only
               AND ractl.line_type = 'LINE'
               AND ractl.description != 'Tiered Discount'
--               AND ractl.customer_trx_line_id NOT IN (
--                      SELECT ractl.customer_trx_line_id
--                        FROM ra_customer_trx_lines ractli,
--                             oe_price_adjustments oepa
--                       WHERE 1 = 1
--                         AND ractl.interface_line_attribute11 =
--                                                      TO_CHAR(oepa.price_adjustment_id)
--                         AND ractli.customer_trx_line_id =
--                                                    ractl.customer_trx_line_id)
               AND ractl.customer_trx_id IN (
                                    SELECT consinv_lines.customer_trx_id
                                      FROM ar_cons_inv_trx_lines consinv_lines
                                     WHERE consinv_lines.cons_inv_id =
                                                                      p_cbi_id); */
               --Added for the defect 12925
              SELECT NVL (SUM(ractl.extended_amount), 0)
              INTO ln_ext_amt_plus_delvy
              FROM ra_customer_trx_lines_all RACTL
                  ,ar_cons_inv_trx_all CONSINV_LINES
             WHERE 1 = 1
               AND RACTL.line_type = 'LINE'
               AND RACTL.description != 'Tiered Discount'
               AND RACTL.customer_trx_id = CONSINV_LINES.customer_trx_id
               AND CONSINV_LINES.cons_inv_id = p_cbi_id;

            lc_return_amount := ln_ext_amt_plus_delvy;
            RETURN lc_return_amount;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               RETURN 0;
            WHEN OTHERS
            THEN
               fnd_file.put_line
                  (fnd_file.LOG,
                   'Error @ xx_ar_cbi_paydoc_ministmnt in formula EXTAMT+DELVY'
                  );
                  fnd_file.put_line(fnd_file.LOG,
                                    'Error in EXTAMT_PLUS_DELVY:'
                                    ||lc_error_loc||'Debug:'||lc_error_debug) ;-- Added log message for Defect 10750

               RETURN 0;
         END;
      ELSIF p_ministmnt_line_type = 'TAX'
      THEN
           lc_error_loc   :='Calculating TAX ';   -- Added log message for Defect 10750
          lc_error_debug := 'FOR CBI'||p_cbi_id;                         -- Added log message for Defect 10750
         BEGIN
            /*
               SELECT SUM(RACTL.EXTENDED_AMOUNT)
               INTO   ln_tax_amount
               FROM   RA_CUSTOMER_TRX_LINES RACTL
               WHERE  1 = 1
                 AND RACTL.LINE_TYPE = 'TAX'
                 --AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'  --For release 1 we need invoices sourced from AOPS only
                 AND RACTL.CUSTOMER_TRX_ID IN (
                       SELECT CONSINV_LINES.CUSTOMER_TRX_ID
                       FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
                       WHERE CONSINV_LINES.CONS_INV_ID            =p_cbi_id
                       );
            */
            SELECT SUM (NVL (tax_original, 0))
              INTO ln_tax_amount
              FROM ar_cons_inv_trx
             WHERE cons_inv_id = p_cbi_id
               AND transaction_type IN ('INVOICE', 'CREDIT_MEMO'
                                                                --,'ADJUSTMENT'
                                       );

            lc_return_amount := ln_tax_amount;
            RETURN lc_return_amount;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               RETURN 0;
            WHEN OTHERS
            THEN
               fnd_file.put_line
                         (fnd_file.LOG,
                          'Error @ xx_ar_cbi_paydoc_ministmnt in formula TAX'
                         );
                fnd_file.put_line(fnd_file.LOG,
                                    'Error in TAX :'
                                    ||lc_error_loc||'Debug:'||lc_error_debug) ;-- Added log message for Defect 10750
               RETURN 0;
         END;
      ELSIF p_ministmnt_line_type = 'DISCOUNT'
      THEN
          lc_error_loc   :='Calculating DISCOUNT ';   -- Added log message for Defect 10750
          lc_error_debug := 'FOR CBI'||p_cbi_id;                         -- Added log message for Defect 10750
         BEGIN
/*            SELECT SUM (NVL (discount.amount, 0))
              INTO ln_promo_and_disc
              FROM (SELECT SUM (NVL (ractl.extended_amount, 0)) amount
                      FROM ra_customer_trx_lines ractl,
                           oe_price_adjustments oepa
                     WHERE 1 = 1
                       AND ractl.line_type = 'LINE'
                       AND ractl.interface_line_context = 'ORDER ENTRY'
                       --For release 1 we need invoices sourced from AOPS only
                       AND TO_NUMBER (ractl.interface_line_attribute11) =
                                                      oepa.price_adjustment_id
                       AND ractl.customer_trx_line_id IN (
                                    SELECT consinv_lines.customer_trx_line_id
                                      FROM ar_cons_inv_trx_lines consinv_lines
                                     WHERE consinv_lines.cons_inv_id =
                                                                      p_cbi_id)
                    UNION ALL
                    SELECT SUM (NVL (ractl.extended_amount, 0))
                      FROM ra_customer_trx_lines ractl
                     WHERE 1 = 1
                       AND ractl.line_type = 'LINE'
                       AND (   ractl.interface_line_context != 'ORDER ENTRY'
                            OR ractl.interface_line_context IS NULL
                           )
--                       AND NVL (ractl.interface_line_context, '?') !=
--                                                                 'ORDER ENTRY'
                       AND ractl.description = 'Tiered Discount'
                       AND ractl.customer_trx_line_id IN (
                                    SELECT consinv_lines.customer_trx_line_id
                                      FROM ar_cons_inv_trx_lines consinv_lines
                                     WHERE consinv_lines.cons_inv_id =
                                                                      p_cbi_id)) discount;
*/

 ---Added for perf defect # 10750
        SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
        INTO   ln_promo_and_disc
        FROM   ar_cons_inv_trx_all ACIT
              ,ra_customer_trx_lines_all RACTL
              ,oe_price_adjustments  OEPA
        WHERE  1 = 1
          AND ACIT.cons_inv_id = p_cbi_id
          AND ACIT.customer_trx_id = RACTL.customer_trx_id
          AND RACTL.line_type = 'LINE'
          AND RACTL.interface_line_attribute11 =OEPA.price_adjustment_id;


            lc_return_amount := ln_promo_and_disc;
            RETURN lc_return_amount;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               RETURN 0;
            WHEN OTHERS
            THEN
               fnd_file.put_line
                   (fnd_file.LOG,
                    'Error @ xx_ar_cbi_paydoc_ministmnt in formula DISCOUNTS'
                   );
               fnd_file.put_line(fnd_file.LOG,
                                    'Error in DISCOUNT:'
                                    ||lc_error_loc||'Debug:'||lc_error_debug) ;-- Added log message for Defect 10750
               RETURN 0;
         END;
      ELSIF p_ministmnt_line_type = 'TOTAL'
      THEN
         lc_error_loc   :='Calculating TOTAL ';   -- Added log message for Defect 10750
          lc_error_debug := 'FOR CBI'||p_cbi_id;                         -- Added log message for Defect 10750
         BEGIN
            /*  SELECT SUM (NVL (ractl.extended_amount, 0))   Commented for the defect 12925
              INTO ln_ext_amt_plus_delvy
              FROM ra_customer_trx_lines ractl
             WHERE 1 = 1
               AND ractl.line_type = 'LINE'
               --AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'  --For release 1 we need invoices sourced from AOPS only
               AND ractl.description != 'Tiered Discount'
--               AND ractl.customer_trx_line_id NOT IN (
--                      SELECT ractl.customer_trx_line_id
--                        FROM ra_customer_trx_lines ractli,
--                             oe_price_adjustments oepa
--                       WHERE 1 = 1
--                         AND ractl.interface_line_attribute11 =
--                                                      TO_CHAR(oepa.price_adjustment_id)
--                         AND ractli.customer_trx_line_id =
--                                                    ractl.customer_trx_line_id)
               AND ractl.customer_trx_id IN (
                                    SELECT consinv_lines.customer_trx_id
                                      FROM ar_cons_inv_trx_lines consinv_lines
                                     WHERE consinv_lines.cons_inv_id =
                                                                      p_cbi_id);
             lc_return_amount := lc_return_amount + ln_ext_amt_plus_delvy;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lc_return_amount := lc_return_amount + 0;
            WHEN OTHERS
            THEN
               fnd_file.put_line
                  (fnd_file.LOG,
                   'Error @ xx_ar_cbi_paydoc_ministmnt in formula EXTAMT+DELVY'
                  );
                  fnd_file.put_line(fnd_file.LOG,
                                    'Error in TOTAL:'
                                    ||lc_error_loc||'Debug:'||lc_error_debug) ;-- Added log message for Defect 10750
               lc_return_amount := lc_return_amount + 0;
         END;

         BEGIN
            /*
                SELECT SUM(RACTL.EXTENDED_AMOUNT)
                INTO   ln_tax_amount
                FROM   RA_CUSTOMER_TRX_LINES RACTL
                WHERE  1 = 1
                  AND RACTL.LINE_TYPE = 'TAX'
                  AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'  --For release 1 we need invoices sourced from AOPS only
                  AND RACTL.CUSTOMER_TRX_ID IN (
                        SELECT CONSINV_LINES.CUSTOMER_TRX_ID
                        FROM   AR_CONS_INV_TRX_LINES CONSINV_LINES
                        WHERE CONSINV_LINES.CONS_INV_ID            =p_cbi_id
                        );

            lc_error_loc   :='Getting Tax Amount ';   -- Added log message for Defect 10750
            lc_error_debug := 'FOR CBI'||p_cbi_id;                         -- Added log message for Defect 10750
            SELECT SUM (NVL (tax_original, 0))
              INTO ln_tax_amount
              FROM ar_cons_inv_trx
             WHERE cons_inv_id = p_cbi_id
               AND transaction_type IN ('INVOICE', 'CREDIT_MEMO'
                                                                --,'ADJUSTMENT'
                                       );

            lc_return_amount := lc_return_amount + ln_tax_amount;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lc_return_amount := lc_return_amount + 0;
            WHEN OTHERS
            THEN
               fnd_file.put_line
                         (fnd_file.LOG,
                          'Error @ xx_ar_cbi_paydoc_ministmnt in formula TAX'
                         );
               fnd_file.put_line(fnd_file.LOG,
                                    'Error in getting tax:'
                                    ||lc_error_loc||'Debug:'||lc_error_debug) ;-- Added log message for Defect 10750
               lc_return_amount := lc_return_amount + 0;
         END;

         BEGIN
             lc_error_loc   :='Getting promotional and discount amount ';   -- Added log message for Defect 10750
             lc_error_debug := 'FOR CBI'||p_cbi_id;                         -- Added log message for Defect 10750
/*            SELECT SUM (NVL (discount.amount, 0))
              INTO ln_promo_and_disc
              FROM (SELECT SUM (NVL (ractl.extended_amount, 0)) amount
                      FROM ra_customer_trx_lines ractl,
                           oe_price_adjustments oepa
                     WHERE 1 = 1
                       AND ractl.line_type = 'LINE'
                       AND ractl.interface_line_context = 'ORDER ENTRY'
                       --For release 1 we need invoices sourced from AOPS only
                       AND TO_NUMBER (ractl.interface_line_attribute11) =
                                                      oepa.price_adjustment_id
                       AND ractl.customer_trx_line_id IN (
                                    SELECT consinv_lines.customer_trx_line_id
                                      FROM ar_cons_inv_trx_lines consinv_lines
                                     WHERE consinv_lines.cons_inv_id =
                                                                      p_cbi_id)
                    UNION ALL
                    SELECT SUM (NVL (ractl.extended_amount, 0))
                      FROM ra_customer_trx_lines ractl
                     WHERE 1 = 1
                       AND ractl.line_type = 'LINE'
                       AND (   ractl.interface_line_context != 'ORDER ENTRY'
                            OR ractl.interface_line_context IS NULL
                           )
--                       AND NVL (ractl.interface_line_context, '?') !=
--                                                                 'ORDER ENTRY'
                       AND ractl.description = 'Tiered Discount'
                       AND ractl.customer_trx_line_id IN (
                                    SELECT consinv_lines.customer_trx_line_id
                                      FROM ar_cons_inv_trx_lines consinv_lines
                                     WHERE consinv_lines.cons_inv_id =
                                                                      p_cbi_id)) discount;
*/
 ---Added for perf defect # 12925

        SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
        INTO   lc_return_amount
        FROM   ar_cons_inv_trx_all ACIT
              ,ra_customer_trx_lines RACTL
        WHERE  1 = 1
          AND ACIT.cons_inv_id = p_cbi_id
          AND ACIT.customer_trx_id = RACTL.customer_trx_id;

          -- lc_return_amount := lc_return_amount + ln_promo_and_disc;
            RETURN lc_return_amount;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lc_return_amount := lc_return_amount + 0;
               RETURN lc_return_amount;
            WHEN OTHERS
            THEN
               fnd_file.put_line
                   (fnd_file.LOG,
                    'Error @ xx_ar_cbi_paydoc_ministmnt in formula DISCOUNTS'
                   );
               fnd_file.put_line(fnd_file.LOG,
                                    'Error in getting promotional and discount:'
                                    ||lc_error_loc||'Debug:'||lc_error_debug) ;-- Added log message for Defect 10750
               lc_return_amount := lc_return_amount + 0;
               RETURN lc_return_amount;
         END;
         /*
      BEGIN
       SELECT SUM(amount_original)
       INTO   ln_total_amount
       FROM   ar_cons_inv_trx
       WHERE  cons_inv_id =p_cbi_id
         AND  transaction_type IN ('INVOICE' ,'CREDIT_MEMO');
         lc_return_amount :=ln_total_amount;
         RETURN lc_return_amount;
      EXCEPTION
       WHEN NO_DATA_FOUND THEN
        RETURN 0;
       WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_get_paydoc_ministmnt in formula TOTAL');
        RETURN 0;
      END;
         */
      ELSE
         RETURN (0);
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'NODATA @ xx_ar_cbi_paydoc_ministmnt...'
                            || SQLERRM
                           );
         RETURN (0);
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'Error @ xx_ar_cbi_paydoc_ministmnt...' || SQLERRM
                           );
         fnd_file.put_line(fnd_file.LOG,
                                    'Error in get_cbi_amount_due function:'
                                    ||lc_error_loc||'Debug:'||lc_error_debug) ;-- Added log message for Defect 10750

         RETURN (0);
   END get_cbi_amount_due;

   FUNCTION get_cp_output_file (p_req_id IN NUMBER)
      RETURN VARCHAR2
   IS
      lv_outfile   fnd_concurrent_requests.outfile_name%TYPE
                                                            := TO_CHAR (NULL);
      lc_error_loc   VARCHAR2(500) := NULL ; -- Added log message for Defect 10750
      lc_error_debug VARCHAR2(500) := NULL ; -- Added log message for Defect 10750
   BEGIN
      lc_error_loc   := 'Inside get_cp_output_file' ; --Added log message for Defect 10750
      lc_error_debug := 'For Request Id'||p_req_id ;  --Added log message for Defect 10750
      SELECT outfile_name
        INTO lv_outfile
        FROM fnd_concurrent_requests
       WHERE request_id = p_req_id;

      RETURN lv_outfile;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN '';
      WHEN TOO_MANY_ROWS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                               'GET_CP_OUTPUT_FILE :TOO MANY ROWS'
                            || SUBSTR (SQLERRM, 1, 2000)
                           );
         RETURN '';
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'GET_CP_OUTPUT_FILE :'
                            || SUBSTR (SQLERRM, 1, 2000)
                           );
         fnd_file.put_line (fnd_file.LOG,
                            'Error in get_cp_output_file:'
                            ||lc_error_loc||'Debug:'||lc_error_debug);      --Added log message for Defect 10750
         RETURN '';
   END get_cp_output_file;

   FUNCTION run_detail (p_template IN VARCHAR2)
      RETURN BOOLEAN
   IS
   BEGIN
      IF p_template != 'DETAIL'
      THEN
         RETURN FALSE;
      END IF;

      RETURN TRUE;
   END run_detail;

   FUNCTION run_summarize (p_template IN VARCHAR2)
      RETURN BOOLEAN
   IS
   BEGIN
      IF p_template != 'SUMMARIZE'
      THEN
         RETURN FALSE;
      END IF;

      RETURN TRUE;
   END run_summarize;

   FUNCTION run_one (p_template IN VARCHAR2)
      RETURN BOOLEAN
   IS
   BEGIN
      IF p_template != 'ONE'
      THEN
         RETURN FALSE;
      END IF;

      RETURN TRUE;
   END run_one;

   FUNCTION get_bill_from_date (
      p_customer_id   IN   NUMBER,
      p_site_id       IN   NUMBER,
      p_consinv_id    IN   NUMBER,
      p_cut_off_date  IN   VARCHAR2,  -- added for defect 11993
      infocopy_tag    IN   VARCHAR2,
      p_cust_doc_id   IN   NUMBER     -- added for defect 11993
   )
      RETURN DATE
   AS
      bill_from_dt   DATE   := TO_DATE (NULL);
      ln_cbi_id      NUMBER := 0;
      ld_cut_off_date DATE;        -- added for defect 11993
      lc_error_loc   VARCHAR2(500) := NULL ; -- Added log message for Defect 10750
      lc_error_debug VARCHAR2(500) := NULL ; -- Added log message for Defect 10750
   BEGIN
      ld_cut_off_date := TRUNC (fnd_conc_date.string_to_date (p_cut_off_date));
      lc_error_loc    :='Inside get_bill_from_Date'; -- Added log message for Defect 10750
      lc_error_debug  := NULL ;   -- Added log message for Defect 10750

      IF infocopy_tag != 'INV_IC'
      THEN

--Commented for Defect # 13403
/*         IF infocopy_tag = 'PAYDOC'
         THEN
            ln_cbi_id := p_consinv_id;
         ELSE
            ln_cbi_id := SUBSTR (p_consinv_id, 1, LENGTH (p_consinv_id) - 1);
         END IF;
*/

            ln_cbi_id := p_consinv_id;   --Added for Defect # 13403

         BEGIN
--     SELECT TRUNC(issue_date)
--     INTO   bill_from_dt
--     FROM   ar_cons_inv
--     WHERE  cons_inv_id = (
--                  SELECT MAX(cons_inv_id)-1
--                  FROM   ar_cons_inv
--                  WHERE  customer_id =p_customer_id
--                    AND  site_use_id =p_site_id
--                 );
    --Defect 9044 changed this query as cons_inv_id does not appear to be truly sequential
    --by Sarat Uppalapati on 30-JUL-08
            lc_error_loc   := 'Getting cut_off_date :infotag<>INV_IC'; -- Added log message for Defect 10750
            lc_error_debug := 'For Customer Id and cons_inv_id'||p_customer_id||':'||p_consinv_id; -- Added log message for Defect 10750
            SELECT
              --MAX (cut_off_date)  -- Commented for Defect# 15063.
              MAX(TO_DATE(attribute1))  -- Added for Defect# 15063.
              INTO bill_from_dt
              FROM ar_cons_inv
             WHERE customer_id = p_customer_id
               AND site_use_id = p_site_id
               AND status IN ('ACCEPTED' ,'FINAL')
                    -- added for defect 11993  -- for picking up max cut_off_date of cons invoices less than the con invoice under consideration
               --AND cut_off_date < ld_cut_off_date  -- Commented for Defect# 15063.
               AND TO_DATE(attribute1) < ld_cut_off_date -- Added for Defect# 15063.
               AND cons_inv_id != p_consinv_id ;-- Defect 9044
            IF bill_from_dt IS NULL
            THEN
               BEGIN
                 lc_error_loc   := 'Inside if bill_from_date is NULL:infotag<>INV_IC'; -- Added log message for Defect 10750
                 lc_error_debug := 'For cons_inv_id'||ln_cbi_id; -- Added log message for Defect 10750
                  SELECT MIN (TRUNC (transaction_date))
                    INTO bill_from_dt
                    FROM ar_cons_inv_trx acit, ar_cons_inv aci  -- Defect 9044
                   WHERE acit.cons_inv_id = ln_cbi_id
                     AND acit.cons_inv_id = aci.cons_inv_id
                     AND aci.status IN( 'ACCEPTED'   , 'FINAL')             -- Defect 9044
                     AND acit.transaction_type IN ('INVOICE', 'CREDIT_MEMO');
                  RETURN bill_from_dt;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     RETURN TO_DATE (NULL);
                  WHEN OTHERS
                  THEN
                     fnd_file.put_line
                          (fnd_file.LOG,
                              '3-Error in get bill from date ,infocopy tag :'
                           || infocopy_tag
                          );
                     fnd_file.put_line (fnd_file.LOG,
                                        '3-get_bill_from_date -' || SQLERRM
                                       );
                     fnd_file.put_line (fnd_file.LOG,
                                        'Error in if bill_from date is NULL:infotag<>INV_IC:'
                                        ||lc_error_loc||'Debug:'||lc_error_debug); --Added log message for Defect 10750
                     RETURN TO_DATE (NULL);
               END;
            ELSE
               RETURN bill_from_dt;
            END IF;
         --RETURN bill_from_dt;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               BEGIN
               lc_error_loc   := 'Inside When nodata found NULL:infotag<>INV_IC'; -- Added log message for Defect 10750
               lc_error_debug := 'For cons_inv_id'||ln_cbi_id; -- Added log message for Defect 10750
--           SELECT MIN(TRUNC(TRANSACTION_DATE))
--           INTO   bill_from_dt
--           FROM  ar_cons_inv_trx
--           WHERE cons_inv_id      =ln_cbi_id
--             AND transaction_type IN ('INVOICE' ,'CREDIT_MEMO');
                  SELECT MIN (TRUNC (transaction_date))
                    INTO bill_from_dt
                    FROM ar_cons_inv_trx acit, ar_cons_inv aci  -- Defect 9044
                   WHERE acit.cons_inv_id = ln_cbi_id
                     AND acit.cons_inv_id = aci.cons_inv_id
                     AND aci.status IN ( 'ACCEPTED' ,'FINAL')                -- Defect 9044
                     AND acit.transaction_type IN ('INVOICE', 'CREDIT_MEMO');
                  RETURN bill_from_dt;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     RETURN TO_DATE (NULL);
                  WHEN OTHERS
                  THEN
                     fnd_file.put_line
                          (fnd_file.LOG,
                              '1-Error in get bill from date ,infocopy tag :'
                           || infocopy_tag
                          );
                     fnd_file.put_line (fnd_file.LOG,
                                        '1-get_bill_from_date -' || SQLERRM
                                       );
                     fnd_file.put_line (fnd_file.LOG,
                                        'Error -'
                                        ||lc_error_loc||'Debug:'||lc_error_debug); -- Added log message for Defect 10750
                     RETURN TO_DATE (NULL);
               END;
            WHEN OTHERS
            THEN
               fnd_file.put_line
                          (fnd_file.LOG,
                              '2-Error in get bill from date ,infocopy tag :'
                           || infocopy_tag
                          );
               fnd_file.put_line (fnd_file.LOG,
                                  '2-get_bill_from_date -' || SQLERRM
                                 );
               fnd_file.put_line (fnd_file.LOG,
                                        'Error :'
                                        ||lc_error_loc||'Debug:'||lc_error_debug); -- Added log message for Defect 10750
               RETURN TO_DATE (NULL);
             END;
      ELSE
         BEGIN
                lc_error_loc   := 'Inside When nodata found NULL:infotag=INV_IC'; -- Added log message for Defect 10750
                lc_error_debug := NULL; -- Added log message for Defect 10750
--     SELECT MAX(TRUNC(od_summbills.bill_from_date))
--     INTO   bill_from_dt
--     FROM   xx_ar_cons_bills_history od_summbills
--     WHERE  od_summbills.cons_inv_id = (
--                  SELECT MAX(cons_inv_id)-1
--                  FROM   xx_ar_cons_bills_history
--                  WHERE  customer_id =p_customer_id
--                    AND  attribute7  =p_site_id
--                    AND  attribute8  ='INV_IC');
    --Defect 9046 changed this query as cons_inv_id does not appear to be truly sequential
    --by Sarat Uppalapati on 30-JUL-08
	-- Commented below as part of defect #38583(v 1.62)
    /*  --    SELECT MAX (TRUNC (od_summbills.bill_from_date)) commented for defect 11993
            SELECT MAX (TRUNC (od_summbills.bill_from_date))+1 --added for defect 11993   from_date must be 1 day greater than the last cut off day
              INTO bill_from_dt
              FROM ra_customer_trx ract,
                   xx_ar_cons_bills_history od_summbills
             WHERE od_summbills.attribute1 = ract.customer_trx_id
               AND od_summbills.cust_doc_id = p_cust_doc_id  -- added for Defect 11993
               AND od_summbills.customer_id = p_customer_id
               AND od_summbills.attribute7 = p_site_id
               AND od_summbills.attribute8 = 'INV_IC'
               AND ract.complete_flag = 'Y'                     -- Defect 9044
               AND od_summbills.cons_inv_id  < p_consinv_id;  -- added for defect 11993
            -- RETURN bill_from_dt; -- Commented for the defect 9546
	*/
    -- Start of changes for defect #38583(v 1.62)
	        SELECT MAX (TRUNC (od_summbills.bill_from_date))+1
              INTO bill_from_dt
              FROM xx_ar_cons_bills_history od_summbills
             WHERE od_summbills.cust_doc_id = p_cust_doc_id  -- added for Defect 11993
               AND od_summbills.customer_id = p_customer_id
               AND od_summbills.attribute7 = p_site_id
               AND od_summbills.attribute8 = 'INV_IC'
               AND od_summbills.cons_inv_id  < p_consinv_id  -- added for defect 11993
			   AND od_summbills.attribute1 > '0';
	-- End of changes for defect #38583(v 1.62)
            IF bill_from_dt IS NULL
            THEN
              BEGIN
               lc_error_loc   := 'Inside if bill_from_date is NULL:infotag=INV_IC'; -- Added log message for Defect 10750
               lc_error_debug := 'For cons_inv_id'||p_consinv_id; -- Added log message for Defect 10750
--           SELECT MIN(TRUNC(ract.trx_date))
--           INTO   bill_from_dt
--           FROM  ra_customer_trx ract,xx_ar_cons_bills_history od_summbills
--           WHERE od_summbills.cons_inv_id =p_consinv_id
--             AND od_summbills.attribute8 ='INV_IC'
--                     AND od_summbills.customer_id =p_customer_id
--                     AND od_summbills.attribute7  =p_site_id
--                     AND od_summbills.attribute1  =ract.customer_trx_id;
                  SELECT MIN (TRUNC (ract.trx_date))
                    INTO bill_from_dt
                    FROM ra_customer_trx ract,
                         xx_ar_cons_bills_history od_summbills
                   WHERE od_summbills.cons_inv_id = p_consinv_id
                     AND od_summbills.attribute8 = 'INV_IC'
                     AND ract.complete_flag = 'Y'               -- Defect 9044
                     AND od_summbills.cust_doc_id = p_cust_doc_id  -- added for Defect 11993
                     AND od_summbills.customer_id = p_customer_id
                     AND od_summbills.attribute7 = p_site_id
                     AND od_summbills.attribute1 = ract.customer_trx_id;
                  RETURN bill_from_dt;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     RETURN TO_DATE (NULL);
                  WHEN OTHERS
                  THEN
                     fnd_file.put_line
                          (fnd_file.LOG,
                              '3-Error in get bill from date ,infocopy tag :'
                           || infocopy_tag
                          );
                     fnd_file.put_line (fnd_file.LOG,
                                        '3-get_bill_from_date -' || SQLERRM
                                       );
                     fnd_file.put_line (fnd_file.LOG,
                                        'Error :'
                                        ||lc_error_loc||'Debug:'||lc_error_debug); -- Added log message for Defect 10750
                                      RETURN TO_DATE (NULL);
               END;
            ELSE
               RETURN bill_from_dt;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               BEGIN
--           SELECT MIN(TRUNC(ract.trx_date))
--           INTO   bill_from_dt
--           FROM  ra_customer_trx ract,xx_ar_cons_bills_history od_summbills
--           WHERE od_summbills.cons_inv_id =p_consinv_id
--             AND od_summbills.attribute8 ='INV_IC'
--                     AND od_summbills.customer_id =p_customer_id
--                     AND od_summbills.attribute7  =p_site_id
--                     AND od_summbills.attribute1  =ract.customer_trx_id;
                  SELECT MIN (TRUNC (ract.trx_date))
                    INTO bill_from_dt
                    FROM ra_customer_trx ract,
                         xx_ar_cons_bills_history od_summbills
                   WHERE od_summbills.cons_inv_id = p_consinv_id
                     AND od_summbills.attribute8 = 'INV_IC'
                     AND ract.complete_flag = 'Y'               -- Defect 9046
                     AND od_summbills.cust_doc_id = p_cust_doc_id  -- added for Defect 11993
                     AND od_summbills.customer_id = p_customer_id
                     AND od_summbills.attribute7 = p_site_id
                     AND od_summbills.attribute1 = ract.customer_trx_id;
                  RETURN bill_from_dt;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     RETURN TO_DATE (NULL);
                  WHEN OTHERS
                  THEN
                     fnd_file.put_line
                          (fnd_file.LOG,
                              '1-Error in get bill from date ,infocopy tag :'
                           || infocopy_tag
                          );
                     fnd_file.put_line (fnd_file.LOG,
                                        '1-get_bill_from_date -' || SQLERRM
                                       );
                     fnd_file.put_line (fnd_file.LOG,
                                        'Error :'
                                        ||lc_error_loc||'Debug:'||lc_error_debug); -- Added log message for Defect 10750
                     RETURN TO_DATE (NULL);
               END;
            WHEN OTHERS
            THEN
               fnd_file.put_line
                          (fnd_file.LOG,
                              '2-Error in get bill from date ,infocopy tag :'
                           || infocopy_tag
                          );
               fnd_file.put_line (fnd_file.LOG,
                                  '2-get_bill_from_date -' || SQLERRM
                                 );
               RETURN TO_DATE (NULL);
         END;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, '3-Error in get bill from date...');
         fnd_file.put_line (fnd_file.LOG,
                            '3-get_bill_from_date -' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG,
                                        'Error in get_bill_from_date:'
                                        ||lc_error_loc||'Debug:'||lc_error_debug); -- Added log message for Defect 10750
         RETURN TO_DATE (NULL);
   END get_bill_from_date;

   FUNCTION beforereport
      RETURN BOOLEAN
   IS
-- ===================================
-- Cursor Declaration...
-- ===================================
      CURSOR g_pay_cust
      IS
         SELECT   od_summbills.customer_id cust_account_id,
                  od_summbills.attribute9 billing_id,
                  hzlo.province bill_to_province,
                  od_summbills.attribute12 account_number,
                  od_summbills.attribute11 customer_name,
                  od_summbills.attribute10 sales_channel,
                  aci.cons_inv_id cbi_id, aci.cons_billing_number cbi_number,
                  od_summbills.attribute14 cbi_amount,
                  aci.currency_code currency
--       ,trunc(aci.issue_date)            issue_date
                  , TRUNC (aci.due_date) due_date,
             --     TRUNC (aci.cut_off_date) billing_period_to,            commented for defect 11993
                  --TRUNC (aci.cut_off_date -1) billing_period_to,           -- added for defect 11993 -- Commented for Defect# 15063.
                  TO_DATE(ACI.attribute1) - 1  billing_period_to,           -- Added for Defect# 15063.
                  aci.site_use_id siteuse_id,
                  od_summbills.layout rtf_template,
                  od_summbills.sort_by sort_by,
                  od_summbills.attribute2 total_by,
                  od_summbills.attribute3 page_break,
                  od_summbills.document_id document_id
                 ,od_summbills.attribute16  cons_inv_id1     --Added for Defect # 13403
             FROM xx_ar_cons_bills_history od_summbills,
                  ar_cons_inv aci,
                  hz_cust_acct_sites hzas,
                  hz_cust_site_uses hzsu,
                  hz_party_sites hzps,
                  hz_locations hzlo
            WHERE od_summbills.print_date <= g_as_of_date     --trunc(sysdate)
              AND od_summbills.paydoc = 'Y'
              AND NVL (od_summbills.process_flag, 'N') != 'Y'
              AND od_summbills.attribute8 = 'PAYDOC'
              AND od_summbills.thread_id = p_thread_id
              AND od_summbills.cons_inv_id = aci.cons_inv_id
              AND hzas.cust_account_id = aci.customer_id
              AND hzsu.cust_acct_site_id = hzas.cust_acct_site_id
              AND hzsu.site_use_id = aci.site_use_id
              AND hzps.party_site_id = hzas.party_site_id
              AND hzlo.location_id = hzps.location_id
         ORDER BY aci.cons_inv_id;

      CURSOR g_paydoc_ic
      IS
         SELECT   od_summbills.customer_id cust_account_id,
                  od_summbills.attribute9 billing_id,
                  hzlo.province bill_to_province,
                  od_summbills.attribute12 account_number,
                  od_summbills.attribute11 customer_name,
                  od_summbills.attribute10 sales_channel,
                  od_summbills.cons_inv_id cbi_id,
                  --aci.cons_billing_number cbi_number,  --Commented for the Defect # 10750
                  od_summbills.attribute6 cbi_number, --Added for the Defect # 10750
                  od_summbills.attribute14 cbi_amount,
                  --aci.currency_code currency  --Commnted for the Defect # 10750
                  od_summbills.attribute15 currency  --Added for the Defect # 10750
                 ,od_summbills.direct_flag direct_flag  --Added for the Defect # 10750
--       ,trunc(aci.issue_date)            issue_date
                  , TRUNC (aci.due_date) due_date,
            --    TRUNC (aci.cut_off_date) billing_period_to, commented for defect 11993
                  --TRUNC (aci.cut_off_date -1) billing_period_to,   --added for defect 11993 -- Commented for Defect# 15063.
                  TO_DATE(ACI.attribute1) - 1   billing_period_to,  -- Added for Defect# 15063.
--                  aci.site_use_id siteuse_id,  --Commnted for the Defect # 10750
                  od_summbills.attribute7 siteuse_id,  --Added for the Defect # 10750
                  od_summbills.layout rtf_template,
                  od_summbills.sort_by sort_by,
                  od_summbills.attribute2 total_by,
                  od_summbills.attribute3 page_break,
                  od_summbills.document_id document_id,
                  od_summbills.cust_doc_id cust_doc_id   --Added for the Defect # 10750
                 ,od_summbills.attribute16  cons_inv_id1     --Added for Defect # 13403
             FROM xx_ar_cons_bills_history od_summbills,
                  ar_cons_inv aci,
                  hz_cust_acct_sites hzas,
                  hz_cust_site_uses hzsu,
                  hz_party_sites hzps,
                  hz_locations hzlo
            WHERE od_summbills.print_date <= g_as_of_date     --trunc(sysdate)
              AND od_summbills.paydoc = 'N'
              AND NVL (od_summbills.process_flag, 'N') != 'Y'
              AND od_summbills.attribute8 = 'PAYDOC_IC'
             /* AND aci.cons_inv_id =
                     SUBSTR (od_summbills.cons_inv_id,
                             1,
                             LENGTH (od_summbills.cons_inv_id) - 1
                            ) */                                    -- Commented for Defect 12283
--              AND aci.cons_inv_id =SUBSTR (od_summbills.cons_inv_id,1,LENGTH(aci.cons_inv_id)) -- Added for defect 12283
                       -- The above condition is commented for Defect # 13403
              AND aci.cons_inv_id = od_summbills.attribute16   -- Added for Defect # 13403
              AND od_summbills.thread_id = p_thread_id
              AND hzas.cust_account_id = aci.customer_id
              AND hzsu.cust_acct_site_id = hzas.cust_acct_site_id
              AND hzsu.site_use_id = aci.site_use_id
              AND hzps.party_site_id = hzas.party_site_id
              AND hzlo.location_id = hzps.location_id
         ORDER BY od_summbills.cons_inv_id;

      --and  od_summbills.cons_inv_id            =aci.cons_inv_id
      CURSOR g_inv_ic
      IS
         SELECT   od_summbills.customer_id cust_account_id,
                  od_summbills.attribute9 billing_id,
                  hzlo.province bill_to_province,
                  od_summbills.attribute12 account_number,
                  od_summbills.attribute11 customer_name,
                  od_summbills.attribute10 sales_channel,
                  od_summbills.cons_inv_id cbi_id,
                  od_summbills.attribute6 cbi_number,
                  od_summbills.attribute14 cbi_amount,
                  od_summbills.attribute15 currency
--       ,TO_DATE(NULL)                    issue_date
                  , TO_DATE (NULL) due_date,
                  g_as_of_date /*TRUNC(SYSDATE)*/ billing_period_to,
                  od_summbills.attribute7 siteuse_id,
                  od_summbills.layout rtf_template,
                  od_summbills.sort_by sort_by,
                  od_summbills.attribute2 total_by,
                  od_summbills.attribute3 page_break,
                  od_summbills.document_id document_id,
                  od_summbills.attribute16  cons_inv_id1     --Added for Defect # 13403
             FROM xx_ar_cons_bills_history od_summbills,
                  hz_cust_acct_sites hzas,
                  hz_cust_site_uses hzsu,
                  hz_party_sites hzps,
                  hz_locations hzlo
            WHERE od_summbills.attribute8 = 'INV_IC'
              AND od_summbills.print_date <= g_as_of_date     --TRUNC(SYSDATE)
              AND od_summbills.paydoc = 'N'
              AND NVL (od_summbills.process_flag, '?') <> 'Y'
              AND hzas.cust_account_id = od_summbills.customer_id
              AND hzsu.cust_acct_site_id = hzas.cust_acct_site_id
              AND hzsu.site_use_id = od_summbills.attribute7
              AND od_summbills.thread_id = p_thread_id
              AND hzps.party_site_id = hzas.party_site_id
              AND hzlo.location_id = hzps.location_id
         GROUP BY od_summbills.customer_id,
                  od_summbills.attribute9,
                  hzlo.province,
                  od_summbills.attribute12,
                  od_summbills.attribute11,
                  od_summbills.attribute10,
                  od_summbills.cons_inv_id,
                  od_summbills.attribute6,
                  od_summbills.attribute14,
                  od_summbills.attribute15,
                  od_summbills.attribute7,
                  od_summbills.layout,
                  od_summbills.sort_by,
                  od_summbills.attribute2,
                  od_summbills.attribute3,
                  od_summbills.document_id,
                  od_summbills.attribute16      --Added for Defect# 13403
         ORDER BY od_summbills.customer_id,
                  od_summbills.document_id,
                  od_summbills.attribute7,
                  od_summbills.cons_inv_id;

-- ===================================
-- Local variables.
-- ===================================
      number_of_subtotal_recs   NUMBER;
      ln_item_master_org        NUMBER;
      ln_commit                 NUMBER := 0;
      lc_error_loc              VARCHAR2(500) := NULL;  --Added log message for defect 10750
      lc_error_debug            VARCHAR2(500) := NULL;  --Added log message for defect 10750


/*
  Main -BeforeReport Trigger....
*/
   BEGIN
      lc_error_loc  := 'Entered into Before Report' ;  --Added log message for defect 10750
      lc_error_debug := NULL;                          -- Added log message for Defect 10750
      fnd_file.put_line (fnd_file.LOG, 'Entered Before Report....');
      g_as_of_date := TRUNC (fnd_conc_date.string_to_date (p_as_of_date));

-- ================================
-- get all bills to be processed.
-- ================================

      -- ========================================
-- Get Item Master Organization ID
-- ========================================
     lc_error_loc  := 'Getting Item Master Organization ID ' ;  -- Added log message for defect 10750
     lc_error_debug := NULL;                                    -- Added log message for defect 10750
      BEGIN
         SELECT odef.organization_id
           INTO ln_item_master_org
           FROM org_organization_definitions odef
          WHERE 1 = 1 AND odef.organization_name = 'OD_ITEM_MASTER';

         fnd_file.put_line (fnd_file.LOG,
                               'Item Master Organization ID is :'
                            || ln_item_master_org
                           );
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            ln_item_master_org := TO_NUMBER (NULL);
         WHEN OTHERS
         THEN
            ln_item_master_org := TO_NUMBER (NULL);
      END;

      fnd_file.put_line (fnd_file.LOG, 'Enter Pay Doc Block-1');
      lc_error_loc  := 'Before g_pay_cust' ;  -- Added log message for defect 10750
      lc_error_debug := NULL;                                    -- Added log message for defect 10750
      BEGIN
--    ln_commit := ln_commit + 1;
         FOR rec IN g_pay_cust
         LOOP
-- ===========================================================
-- Call to the routine xx_ar_cbi_calc_subtotals.get_invoices
-- will insert all invoices for the corresponding consolidated
-- bill with the customer specific sort applied.
-- ===========================================================
            lc_error_loc   := 'Calling xx_ar_cbi_calc_subtotals.get_invoices for PAYDOC' ;  -- Added log message for defect 10750
            lc_error_debug := 'get_invoices for thread :'||p_thread_id||'for CBI:'||rec.cbi_number ; -- Added log message for defect 10750
            xx_ar_cbi_calc_subtotals.get_invoices (p_thread_id,
                                                   rec.cbi_id,
                                                   TO_NUMBER (rec.cbi_amount),
                                                   rec.bill_to_province,
                                                   rec.sort_by,
                                                   rec.total_by,
                                                   rec.page_break,
                                                   rec.rtf_template,
                                                   'PAYDOC',
                                                   rec.cbi_number,
                                                   ln_item_master_org
                                                   ,NULL  --Added for the Defect # 10750
                                                   ,NULL  --Added for the Defect # 10750
                                                   ,NULL  --Added for the Defect # 10750
                                                   ,NULL  --Added for the Defect # 10750
                                                   ,rec.cons_inv_id1 --Added for Defect # 13403
                                                  );
          lc_error_loc   := 'Before Generate Subtotal for DETAIL template-PAYDOC' ;  -- Added log message for defect 10750
-- ===========================================
-- Generate sub totals for DETAIL Template
-- ===========================================
            BEGIN
               number_of_subtotal_recs := 0;

               SELECT COUNT (1)
                 INTO number_of_subtotal_recs
                 FROM xx_ar_cbi_trx
                WHERE request_id = p_thread_id
                  AND cons_inv_id = rec.cbi_id
                  AND attribute1 = 'PAYDOC';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
               WHEN OTHERS
               THEN
                  NULL;
            END;

            IF number_of_subtotal_recs > 0
            THEN
                BEGIN
                  IF rec.rtf_template = 'DETAIL'
                  THEN
                     IF rec.total_by <> 'B1'
                     THEN
                       lc_error_loc   := 'Before calling Generate Detail Subtotal -PAYDOC:'
                                          ||'if total_by <>B1' ;  -- Added log message for defect 10750
                       lc_error_debug := 'Before Calculating Subtotal for CBI: '||rec.cbi_id ; -- Added log message for defect 10750
                        xx_ar_cbi_calc_subtotals.generate_detail_subtotals
                           ((LENGTH (REPLACE (rec.total_by, 'B1', '')) / 2
                            )           -- pn_number_of_soft_headers IN NUMBER
                             ,
                            rec.billing_id
                                          -- p_billing_id              IN VARCHAR2
                        ,
                            rec.cbi_id  -- p_cons_id                 IN NUMBER
                                      ,
                            p_thread_id -- p_reqs_id                 IN NUMBER
                                       ,
                            rec.total_by
                                        -- p_total_by                IN VARCHAR2
                        ,
                            rec.page_break
                                          -- p_page_by                 IN VARCHAR2
                        ,
                            'PAYDOC'
                           );
                     ELSE
                        lc_error_loc   := 'Before calling Generate Detail Subtotal-PAYDOC: '
                                          ||'else total_by <>B1' ;  -- Added log message for defect 10750
                        lc_error_debug := 'Before Calculating Subtotal for CBI: '||rec.cbi_id ; -- Added log message for defect 10750
                        xx_ar_cbi_calc_subtotals.generate_detail_subtotals
                           ((LENGTH (rec.total_by) / 2
                            )           -- pn_number_of_soft_headers IN NUMBER
                             ,
                            rec.billing_id
                                          -- p_billing_id              IN VARCHAR2
                        ,
                            rec.cbi_id  -- p_cons_id                 IN NUMBER
                                      ,
                            p_thread_id -- p_reqs_id                 IN NUMBER
                                       ,
                            rec.total_by
                                        -- p_total_by                IN VARCHAR2
                        ,
                            rec.page_break
                                          -- p_page_by                 IN VARCHAR2
                        ,
                            'PAYDOC'
                           );
                     END IF;
                  ELSE
-- =================================================
-- Generate sub totals for SUMMARIZE and ONE
-- templates. The buckets are a little different
-- from the DETAIL procedure. So we modified
-- and made appropriate changes to it.
-- =================================================
                     IF rec.total_by <> 'B1'
                     THEN
                        lc_error_loc   := 'Before calling Generate Summ One Subtotal-PAYDOC: '
                                          ||'If total_by <>B1' ;  -- Added log message for defect 10750
                        lc_error_debug := 'Before Calculating Subtotal for thread_id and CBI: '
                                          ||p_thread_id||':'||rec.cbi_id ; -- Added log message for defect 10750
                        xx_ar_cbi_calc_subtotals.generate_summ_one_subtotals
                           ((LENGTH (REPLACE (rec.total_by, 'B1', '')) / 2
                            )           -- pn_number_of_soft_headers IN NUMBER
                             ,
                            rec.billing_id
                                          -- p_billing_id              IN VARCHAR2
                        ,
                            rec.cbi_id  -- p_cons_id                 IN NUMBER
                                      ,
                            p_thread_id -- p_reqs_id                 IN NUMBER
                                       ,
                            rec.total_by
                                        -- p_total_by                IN VARCHAR2
                        ,
                            rec.page_break
                                          -- p_page_by                 IN VARCHAR2
                        ,
                            'PAYDOC'
                           );
                     ELSE
                        lc_error_loc   := 'Before calling Generate Summ One Subtotal-PAYDOC: '
                                          ||'Else total_by <>B1' ;  -- Added log message for defect 10750
                        lc_error_debug := 'Before Calculating Subtotal for thread _id and CBI: '
                                          ||p_thread_id||':'||rec.cbi_id ; -- Added log message for defect 10750
                        xx_ar_cbi_calc_subtotals.generate_summ_one_subtotals
                           ((LENGTH (rec.total_by) / 2
                            )           -- pn_number_of_soft_headers IN NUMBER
                             ,
                            rec.billing_id
                                          -- p_billing_id              IN VARCHAR2
                        ,
                            rec.cbi_id  -- p_cons_id                 IN NUMBER
                                      ,
                            p_thread_id -- p_reqs_id                 IN NUMBER
                                       ,
                            rec.total_by
                                        -- p_total_by                IN VARCHAR2
                        ,
                            rec.page_break
                                          -- p_page_by                 IN VARCHAR2
                        ,
                            'PAYDOC'
                           );
                     END IF;
                  END IF;

                  fnd_file.put_line (fnd_file.LOG,
                                        rec.rtf_template
                                     || ' ,BeforeReport Paydoc subtotals:Request ID:' || p_thread_id
                                     || ' ,Cons ID '||rec.cbi_id
                                    );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     fnd_file.put_line (fnd_file.LOG,
                                           rec.rtf_template
                                        || ' ,BeforeReport Paydoc :Request ID:' || p_thread_id
                                        || ' ,Cons ID '||rec.cbi_id
                                        || SUBSTR (SQLERRM, 1, 2000)
                                       );
               END;
            ELSE
               lc_error_loc   := 'Entered into Zero Subtotal Records-PAYDOC ' ;  -- Added log message for defect 10750
               lc_error_debug := NULL;                                    -- Added log message for defect 10750
               NULL;                        --WE GOT ZERO SUBTOTAL RECORDS...
            END IF;
--     IF ln_commit >10 THEN
--      COMMIT WORK;
--      ln_commit :=1;
--     ELSE
--       ln_commit :=ln_commit + 1;
--       NULL; --We have not gone through a min of 10 cons bills so far...
--     END IF;
         END LOOP;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
       fnd_file.put_line(fnd_file.log ,'BeforeReport Paydoc :' || SUBSTR (SQLERRM, 1, 2000));
       fnd_file.put_line(fnd_file.log , 'Error in BeforeReport:'||lc_error_loc||'Debug:'||lc_error_debug); -- Added log message for defect 10750
      END;

      fnd_file.put_line (fnd_file.LOG, 'Exit Pay Doc Block-2');
      fnd_file.put_line
         (fnd_file.LOG,
          'Enter Info Copy where billing cycle is same as PayDoc billing cycle, Block-3'
         );
       lc_error_loc := 'Before g_paydoc_ic cursor ';  -- Added log message for Defect 10750
       lc_error_debug := NULL;                                    -- Added log message for defect 10750
      BEGIN
--    ln_commit :=1;
         FOR rec IN g_paydoc_ic
         LOOP
-- ===========================================================
-- Call to the routine xx_ar_cbi_calc_subtotals.get_invoices
-- will insert all invoices for the corresponding consolidated
-- bill with the customer specific sort applied.
-- ===========================================================
            lc_error_loc   := 'Calling xx_ar_cbi_calc_subtotals.get_invoices for PAYDOC-IC' ;  -- Added log message for defect 10750
            lc_error_debug := 'get_invoices for thread :'
                              ||p_thread_id||'for CBI:'||rec.cbi_number ; -- Added log message for defect 10750
 fnd_file.put_line
         (fnd_file.LOG,'p_thread_id : '|| p_thread_id ||
                       'rec.cbi_id :'||rec.cbi_id||
                       'rec.bill_to_province :'||rec.bill_to_province||
                       'rec.sort_by :'||rec.sort_by||
                       'rec.total_by :'||rec.total_by||
                       'rec.page_break :'||rec.page_break||
                       'rec.rtf_template :'||rec.rtf_template||
                       'rec.cbi_number :'||rec.cbi_number||
                       'ln_item_master_org :'||ln_item_master_org||
                       'rec.siteuse_id :'||rec.siteuse_id||
                       'rec.document_id :'||rec.document_id||
                       'rec.cust_doc_id :'||rec.cust_doc_id||
                       'rec.direct_flag :'||rec.direct_flag); --Defect # 10750

            xx_ar_cbi_calc_subtotals.get_invoices
                                               (p_thread_id,
                                                rec.cbi_id,
                                                0  --TO_NUMBER(rec.cbi_amount)
                                                 ,
                                                rec.bill_to_province,
                                                rec.sort_by,
                                                rec.total_by,
                                                rec.page_break,
                                                rec.rtf_template,
                                                'PAYDOC_IC',
                                                rec.cbi_number,
                                                ln_item_master_org
                                               ,rec.siteuse_id  --Added for the Defect # 10750
                                               ,rec.document_id  --Added for the Defect # 10750
                                               ,rec.cust_doc_id  --Added for the Defect # 10750
                                               ,rec.direct_flag  --Added for the Defect # 10750
                                               ,rec.cons_inv_id1 --Added for Defect # 13403
                                               );

            BEGIN
               number_of_subtotal_recs := 0;

               SELECT COUNT (1)
                 INTO number_of_subtotal_recs
                 FROM xx_ar_cbi_trx
                WHERE request_id = p_thread_id
                  AND cons_inv_id = rec.cbi_id
                  AND attribute1 = 'PAYDOC_IC';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
               WHEN OTHERS
               THEN
                  NULL;
            END;

-- ===========================================
-- Generate sub totals for DETAIL Template
-- ===========================================
            IF number_of_subtotal_recs > 0
            THEN
               BEGIN
                  IF rec.rtf_template = 'DETAIL'
                  THEN
                     IF rec.total_by <> 'B1'
                     THEN
                       lc_error_loc   := 'Before calling Generate Detail Subtotal -PAYDOC_IC:'
                                          ||'if total_by <>B1' ;  -- Added log message for defect 10750
                       lc_error_debug := 'Before Calculating Subtotal for CBI: '||rec.cbi_id ; -- Added log message for defect 10750
                        xx_ar_cbi_calc_subtotals.generate_detail_subtotals
                           ((LENGTH (REPLACE (rec.total_by, 'B1', '')) / 2
                            )           -- pn_number_of_soft_headers IN NUMBER
                             ,
                            rec.billing_id
                                          -- p_billing_id              IN VARCHAR2
                        ,
                            rec.cbi_id  -- p_cons_id                 IN NUMBER
                                      ,
                            p_thread_id -- p_reqs_id                 IN NUMBER
                                       ,
                            rec.total_by
                                        -- p_total_by                IN VARCHAR2
                        ,
                            rec.page_break
                                          -- p_page_by                 IN VARCHAR2
                        ,
                            'PAYDOC_IC'
                           );
                     ELSE
                        lc_error_loc   := 'Before calling Generate Detail Subtotal-PAYDOC_IC: '
                                          ||'else total_by <>B1' ;  -- Added log message for defect 10750
                        lc_error_debug := 'Before Calculating Subtotal for CBI: '||rec.cbi_id ; -- Added log message for defect 10750
                        xx_ar_cbi_calc_subtotals.generate_detail_subtotals
                           ((LENGTH (rec.total_by) / 2
                            )           -- pn_number_of_soft_headers IN NUMBER
                             ,
                            rec.billing_id
                                          -- p_billing_id              IN VARCHAR2
                        ,
                            rec.cbi_id  -- p_cons_id                 IN NUMBER
                                      ,
                            p_thread_id -- p_reqs_id                 IN NUMBER
                                       ,
                            rec.total_by
                                        -- p_total_by                IN VARCHAR2
                        ,
                            rec.page_break
                                          -- p_page_by                 IN VARCHAR2
                        ,
                            'PAYDOC_IC'
                           );
                     END IF;
                  ELSE
-- =================================================
-- Generate sub totals for SUMMARIZE and ONE
-- templates. The buckets are a little different
-- from the DETAIL procedure. So we modified
-- and made appropriate changes to it.
-- =================================================
                     IF rec.total_by <> 'B1'
                     THEN
                        lc_error_loc   := 'Before calling Generate Summ One Subtotal-PAYDOC_IC: '
                                          ||'If total_by <>B1' ;  -- Added log message for defect 10750
                        lc_error_debug := 'Before Calculating Subtotal for thread_id and CBI: '
                                          ||p_thread_id||':'||rec.cbi_id ; -- Added log message for defect 10750
                        xx_ar_cbi_calc_subtotals.generate_summ_one_subtotals
                           ((LENGTH (REPLACE (rec.total_by, 'B1', '')) / 2
                            )           -- pn_number_of_soft_headers IN NUMBER
                             ,
                            rec.billing_id
                                          -- p_billing_id              IN VARCHAR2
                        ,
                            rec.cbi_id  -- p_cons_id                 IN NUMBER
                                      ,
                            p_thread_id -- p_reqs_id                 IN NUMBER
                                       ,
                            rec.total_by
                                        -- p_total_by                IN VARCHAR2
                        ,
                            rec.page_break
                                          -- p_page_by                 IN VARCHAR2
                        ,
                            'PAYDOC_IC'
                           );
                     ELSE
                        lc_error_loc   := 'Before calling Generate Summ One Subtotal-PAYDOC_IC: '
                                          ||'Else total_by <>B1' ;  -- Added log message for defect 10750
                        lc_error_debug := 'Before Calculating Subtotal for thread _id and CBI: '
                                          ||p_thread_id||':'||rec.cbi_id ; -- Added log message for defect 10750
                        xx_ar_cbi_calc_subtotals.generate_summ_one_subtotals
                           ((LENGTH (rec.total_by) / 2
                            )           -- pn_number_of_soft_headers IN NUMBER
                             ,
                            rec.billing_id
                                          -- p_billing_id              IN VARCHAR2
                        ,
                            rec.cbi_id  -- p_cons_id                 IN NUMBER
                                      ,
                            p_thread_id -- p_reqs_id                 IN NUMBER
                                       ,
                            rec.total_by
                                        -- p_total_by                IN VARCHAR2
                        ,
                            rec.page_break
                                          -- p_page_by                 IN VARCHAR2
                        ,
                            'PAYDOC_IC'
                           );
                     END IF;
                  END IF;
               --fnd_file.put_line(fnd_file.log ,REC.RTF_TEMPLATE||' ,BeforeReport Paydoc info copy subtotals:');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     fnd_file.put_line
                             (fnd_file.LOG,
                                 rec.rtf_template
                                     || ' ,BeforeReport Paydoc info copy subtotals:Request ID:' || p_thread_id
                                     || ' ,Cons ID '||rec.cbi_id
                              || SUBSTR (SQLERRM, 1, 2000)
                             );
               END;
            ELSE
              lc_error_loc   := 'Entered into Zero Subtotal Records-PAYDOC_IC ' ;  -- Added log message for defect 10750
              lc_error_debug := NULL;                                    -- Added log message for defect 10750
               NULL;                  --WE GOT ZERO RECORDS FROM SUBTOTALS...
            END IF;
--     IF ln_commit >10 THEN
--      COMMIT WORK;
--      ln_commit :=1;
--     ELSE
--       ln_commit :=ln_commit + 1;
--       NULL; --We have not gone through a min of 10 cons bills so far...
--     END IF;
         END LOOP;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG,
                                  'BeforeReport Paydoc info copy :'
                               || SUBSTR (SQLERRM, 1, 2000)
                              );
            fnd_file.put_line(fnd_file.log , 'Error in BeforeReport:'
                              ||lc_error_loc||'Debug:'||lc_error_debug); -- Added log message for defect 10750
      END;

      fnd_file.put_line
         (fnd_file.LOG,
          'Exit Info Copy where billing cycle is same as PayDoc billing cycle, Block-3'
         );

-- ======================================================================
-- Process Infocopies from Invoices.
-- ======================================================================
      BEGIN
         fnd_file.put_line
            (fnd_file.LOG,
             'Enter Info Copy where paydoc is an invoice and info copy is a consolidated bill, Block-4'
            );
     lc_error_loc := 'Before g_inv_ic Cursor';           -- Added log message for defect 10750
     lc_error_debug := NULL;                                    -- Added log message for defect 10750
--   ln_commit :=1;
         FOR rec IN g_inv_ic
         LOOP
            lc_error_loc   := 'Calling xx_ar_cbi_calc_subtotals.get_invoices for INV-IC' ;  -- Added log message for defect 10750
            lc_error_debug := 'get_invoices for thread :'
                              ||p_thread_id||'for CBI:'||rec.cbi_number ; -- Added log message for defect 10750
            xx_ar_cbi_calc_subtotals.get_invoices
                                               (p_thread_id,
                                                rec.cbi_id,
                                                0  --TO_NUMBER(rec.cbi_amount)
                                                 ,
                                                rec.bill_to_province,
                                                rec.sort_by,
                                                rec.total_by,
                                                rec.page_break,
                                                rec.rtf_template,
                                                'INV_IC',
                                                rec.cbi_number,
                                                ln_item_master_org
                                               ,NULL--Added for the Defect # 10750
                                               ,NULL--Added for the Defect # 10750
                                               ,NULL--Added for the Defect # 10750
                                               ,NULL--Added for the Defect # 10750
                                               ,rec.cons_inv_id1 --Added for Defect # 13403
                                               );

-- ===========================================
-- Generate sub totals for DETAIL Template
-- ===========================================
            BEGIN
               number_of_subtotal_recs := 0;

               SELECT COUNT (1)
                 INTO number_of_subtotal_recs
                 FROM xx_ar_cbi_trx
                WHERE request_id = p_thread_id
                  AND cons_inv_id = rec.cbi_id
                  AND attribute1 = 'INV_IC';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
               WHEN OTHERS
               THEN
                  NULL;
            END;

            IF number_of_subtotal_recs > 0
            THEN
               BEGIN
                  IF rec.rtf_template = 'DETAIL'
                  THEN
                     IF rec.total_by <> 'B1'
                     THEN
                       lc_error_loc   := 'Before calling Generate Detail Subtotal -INV_IC:'
                                          ||'if total_by <>B1' ;  -- Added log message for defect 10750
                       lc_error_debug := 'Before Calculating Subtotal for CBI: '||rec.cbi_id ; -- Added log message for defect 10750
                        xx_ar_cbi_calc_subtotals.generate_detail_subtotals
                           ((LENGTH (REPLACE (rec.total_by, 'B1', '')) / 2
                            )           -- pn_number_of_soft_headers IN NUMBER
                             ,
                            rec.billing_id
                                          -- p_billing_id              IN VARCHAR2
                        ,
                            rec.cbi_id  -- p_cons_id                 IN NUMBER
                                      ,
                            p_thread_id -- p_reqs_id                 IN NUMBER
                                       ,
                            rec.total_by
                                        -- p_total_by                IN VARCHAR2
                        ,
                            rec.page_break
                                          -- p_page_by                 IN VARCHAR2
                        ,
                            'INV_IC'
                           );
                     ELSE
                        lc_error_loc   := 'Before calling Generate Detail Subtotal-INV_IC: '
                                          ||'else total_by <>B1' ;  -- Added log message for defect 10750
                        lc_error_debug := 'Before Calculating Subtotal for CBI: '||rec.cbi_id ; -- Added log message for defect 10750
                        xx_ar_cbi_calc_subtotals.generate_detail_subtotals
                           ((LENGTH (rec.total_by) / 2
                            )           -- pn_number_of_soft_headers IN NUMBER
                             ,
                            rec.billing_id
                                          -- p_billing_id              IN VARCHAR2
                        ,
                            rec.cbi_id  -- p_cons_id                 IN NUMBER
                                      ,
                            p_thread_id -- p_reqs_id                 IN NUMBER
                                       ,
                            rec.total_by
                                        -- p_total_by                IN VARCHAR2
                        ,
                            rec.page_break
                                          -- p_page_by                 IN VARCHAR2
                        ,
                            'INV_IC'
                           );
                     END IF;
                  ELSE
-- =================================================
-- Generate sub totals for SUMMARIZE and ONE
-- templates. The buckets are a little different
-- from the DETAIL procedure. So we modified
-- and made appropriate changes to it.
-- =================================================
                     IF rec.total_by <> 'B1'
                     THEN
                        lc_error_loc   := 'Before calling Generate Summ One Subtotal-INV_IC: '
                                          ||'If total_by <>B1' ;  -- Added log message for defect 10750
                        lc_error_debug := 'Before Calculating Subtotal for thread_id and CBI: '
                                          ||p_thread_id||':'||rec.cbi_id ; -- Added log message for defect 10750
                        xx_ar_cbi_calc_subtotals.generate_summ_one_subtotals
                           ((LENGTH (REPLACE (rec.total_by, 'B1', '')) / 2
                            )           -- pn_number_of_soft_headers IN NUMBER
                             ,
                            rec.billing_id
                                          -- p_billing_id              IN VARCHAR2
                        ,
                            rec.cbi_id  -- p_cons_id                 IN NUMBER
                                      ,
                            p_thread_id -- p_reqs_id                 IN NUMBER
                                       ,
                            rec.total_by
                                        -- p_total_by                IN VARCHAR2
                        ,
                            rec.page_break
                                          -- p_page_by                 IN VARCHAR2
                        ,
                            'INV_IC'
                           );
                     ELSE
                        lc_error_loc   := 'Before calling Generate Summ One Subtotal-INV_IC: '
                                          ||'Else total_by <>B1' ;  -- Added log message for defect 10750
                        lc_error_debug := 'Before Calculating Subtotal for thread _id and CBI: '
                                          ||p_thread_id||':'||rec.cbi_id ; -- Added log message for defect 10750
                        xx_ar_cbi_calc_subtotals.generate_summ_one_subtotals
                           ((LENGTH (rec.total_by) / 2
                            )           -- pn_number_of_soft_headers IN NUMBER
                             ,
                            rec.billing_id
                                          -- p_billing_id              IN VARCHAR2
                        ,
                            rec.cbi_id  -- p_cons_id                 IN NUMBER
                                      ,
                            p_thread_id -- p_reqs_id                 IN NUMBER
                                       ,
                            rec.total_by
                                        -- p_total_by                IN VARCHAR2
                        ,
                            rec.page_break
                                          -- p_page_by                 IN VARCHAR2
                        ,
                            'INV_IC'
                           );
                     END IF;
                  END IF;
               -- fnd_file.put_line(fnd_file.log ,REC.RTF_TEMPLATE||' ,BeforeReport Invoice info copy subtotals:');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     fnd_file.put_line
                                    (fnd_file.LOG,
                                        rec.rtf_template
                                     || ' ,BeforeReport info copy subtotals: Request ID : '||p_thread_id
                                     || ' , Cons ID' ||rec.cbi_id
                                     || SUBSTR (SQLERRM, 1, 2000)
                                    );
               END;
            ELSE
               lc_error_loc   := 'Entered into Zero Subtotal Records-INV_IC ' ;  -- Added log message for defect 10750
               lc_error_debug := NULL;                                    -- Added log message for defect 10750
               NULL;                        --WE GOT ZERO SUBTOTAL RECORDS...
            END IF;
--     IF ln_commit >10 THEN
--      COMMIT WORK;
--      ln_commit :=1;
--     ELSE
--       ln_commit :=ln_commit + 1;
--       NULL; --We have not gone through a min of 10 cons bills so far...
--     END IF;
         END LOOP;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG,
                                  'BeforeReport Info copy:'
                               || SUBSTR (SQLERRM, 1, 2000)
                              );
      END;

      fnd_file.put_line
         (fnd_file.LOG,
          'Exit Info Copy where paydoc is an invoice and info copy is a consolidated bill, Block-4'
         );
      COMMIT;
      RETURN TRUE;
   --OUTER RETURN STATEMENT FOR THE FUNCTION beforereport trigger...
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'BeforeReport :' || SUBSTR (SQLERRM, 1, 2000)
                           );
         fnd_file.put_line(fnd_file.log , 'Error in BeforeReport :'
                              ||lc_error_loc||'Debug:'||lc_error_debug); -- Added log message for defect 10750
         ROLLBACK;
         RETURN FALSE;
   END beforereport;

/*
  End Main -BeforeReport Trigger....
*/
   FUNCTION afterreport
      RETURN BOOLEAN
   IS
      lv_child_outfile   VARCHAR2 (80) := NULL;
      lc_error_loc       VARCHAR2 (500) := NULL;     -- Added log message for Defect 10750
      lc_error_debug     VARCHAR2 (500) := NULL;     -- Added log message for Defect 10750
   BEGIN
      lc_error_loc := 'In the function Afterreport :';  -- Added log message for Defect 10750
      g_as_of_date := TRUNC (fnd_conc_date.string_to_date (p_as_of_date));
      fnd_file.put_line
                      (fnd_file.LOG,
                       'Begin -Update of ar_cons_inv, set attribute2 to YES.'
                      );
      lc_error_loc   := 'Before Update ar_conx_inv table';
      lc_error_debug := 'Updating for thread: '||p_thread_id; -- Added log message for Defect 10750
       UPDATE ar_cons_inv
         SET attribute2         = 'Y'
             ,attribute15       = 'Y' -- added for defect 4760
             ,last_update_date  = SYSDATE  -- added for defect 4761
             ,last_updated_by   = FND_GLOBAL.USER_ID  -- added for defect 4761
             ,last_update_login = FND_GLOBAL.USER_ID  -- added for defect 4761
       WHERE cons_inv_id IN (
                SELECT cons_inv_id
                  FROM xx_ar_cons_bills_history
                 WHERE 1 = 1
                   AND attribute8 = 'PAYDOC'
                   AND print_date <= g_as_of_date
                   AND paydoc = 'Y'
                   AND NVL (process_flag, '?') != 'Y'
                   AND thread_id = p_thread_id);
      lc_error_loc   := 'After Update ar_conx_inv table';
      lc_error_debug := 'After Updating for thread: '||p_thread_id; -- Added log message for Defect 10750
      fnd_file.put_line (fnd_file.LOG,
                         'End -Update of ar_cons_inv, set attribute2 to YES.'
                        );
      fnd_file.put_line
         (fnd_file.LOG,
          'Begin -Update of xx_ar_cons_bills_history, set process_flag to YES.'
         );
      lc_error_loc   := 'Before Updating xx_ar_cons_bills_history';
      lc_error_debug := 'Before Updating for thread: '||p_thread_id; -- Added log message for Defect 10750
      UPDATE xx_ar_cons_bills_history
         SET process_flag = 'Y'
             ,last_updated_by    = FND_GLOBAL.USER_ID  --added for defect 4761
             ,last_update_date = SYSDATE               --added for defect 4761
       WHERE 1 = 1 AND thread_id = p_thread_id;
      lc_error_loc   := 'After Updating xx_ar_cons_bills_history';
      lc_error_debug := 'After Updating for thread: '||p_thread_id; -- Added log message for Defect 10750
      fnd_file.put_line
          (fnd_file.LOG,
           'End -Update of xx_ar_cons_bills_history, set process_flag to YES.'
          );
      fnd_file.put_line
                     (fnd_file.LOG,
                      'Start -Clean up of CERTEGY staging table xx_ar_cbi_trx'
                     );

-- Start of Defect # 10750
      INSERT INTO xx_ar_cbi_trx_history
      SELECT
             request_id
            ,cons_inv_id
            ,customer_trx_id
            ,order_header_id
            ,inv_number
            ,inv_type
            ,inv_source_id
            ,inv_source_name
            ,order_date
            ,ship_date
            ,sfhdr1
            ,sfdata1
            ,sfhdr2
            ,sfdata2
            ,sfhdr3
            ,sfdata3
            ,sfhdr4
            ,sfdata4
            ,sfhdr5
            ,sfdata5
            ,sfhdr6
            ,sfdata6
            ,subtotal_amount
            ,delivery_charges
            ,promo_and_disc
            ,tax_code
            ,tax_amount
            ,cad_county_tax_code
            ,cad_county_tax_amount
            ,cad_state_tax_code
            ,cad_state_tax_amount
            ,insert_seq
            ,attribute1
            ,attribute2
            ,attribute3
            ,attribute4
            ,attribute5
            ,attribute6
            ,attribute7
            ,attribute8
            ,attribute9
            ,attribute10
            ,attribute11
            ,attribute12
            ,attribute13
            ,attribute14
            ,attribute15
            ,org_id
            ,SYSDATE
            ,FND_PROFILE.VALUE ('USER_ID')
            ,SYSDATE
            ,FND_PROFILE.VALUE ('USER_ID')
      FROM   xx_ar_cbi_trx
      WHERE  request_id  =p_thread_id;

-- End of Defect 10750


      DELETE      xx_ar_cbi_trx
            WHERE request_id = p_thread_id;

      --COMMIT WORK;
      fnd_file.put_line
                       (fnd_file.LOG,
                        'End -Clean up of CERTEGY staging table xx_ar_cbi_trx'
                       );
      fnd_file.put_line
               (fnd_file.LOG,
                'Start -Clean up of CERTEGY staging table xx_ar_cbi_trx_lines'
               );

-- Added for Defect 10750
INSERT INTO xx_ar_cbi_trx_lines_history
      SELECT
             request_id
            ,cons_inv_id
            ,customer_trx_id
            ,line_seq
            ,item_code
            ,customer_product_code
            ,item_description
            ,manuf_code
            ,qty
            ,uom
            ,unit_price
            ,extended_price
            ,org_id
            ,SYSDATE
            ,FND_PROFILE.VALUE ('USER_ID')
            ,SYSDATE
            ,FND_PROFILE.VALUE ('USER_ID')
            ,line_comments                           -- Added for R1.2 Defect 1744 (CR 743)
            ,cost_center_dept
            ,cust_dept_description
			,kit_sku                                 -- Added for Kitting, Defect# 37670
            ,fee_type                                -- Added for tariff Billing 129167
            ,fee_line_seq                            -- Added for tariff Billing 129167
      FROM   xx_ar_cbi_trx_lines
      WHERE  request_id  =p_thread_id;
-- End of Defect 10750

      DELETE      xx_ar_cbi_trx_lines
            WHERE request_id = p_thread_id;

      --COMMIT WORK;
      fnd_file.put_line
                 (fnd_file.LOG,
                  'End -Clean up of CERTEGY staging table xx_ar_cbi_trx_lines'
                 );
      fnd_file.put_line
              (fnd_file.LOG,
               'Start -Clean up of CERTEGY staging table xx_ar_cbi_trx_totals'
              );

-- Added for Defect 10750
INSERT INTO xx_ar_cbi_trx_totals_history
      SELECT
             request_id
            ,cons_inv_id
            ,customer_trx_id
            ,line_type
            ,line_seq
            ,trx_number
            ,sf_text
            ,sf_amount
            ,page_break
            ,order_count
            ,org_id
            ,SYSDATE
            ,FND_PROFILE.VALUE ('USER_ID')
            ,SYSDATE
            ,FND_PROFILE.VALUE ('USER_ID')
      FROM   xx_ar_cbi_trx_totals
      WHERE  request_id  =p_thread_id;
-- End of Defect 10750

      DELETE      xx_ar_cbi_trx_totals
            WHERE request_id = p_thread_id;

      --COMMIT WORK;
      fnd_file.put_line
                (fnd_file.LOG,
                 'End -Clean up of CERTEGY staging table xx_ar_cbi_trx_totals'
                );
COMMIT;
      RETURN TRUE;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line
                (fnd_file.LOG,'Error in Afterreport Function:'
                  ||lc_error_loc||'Debug:'||lc_error_debug );               -- Added log message for Defect 10750
         ROLLBACK;
         RETURN FALSE;
   END afterreport;

   PROCEDURE main (
      errbuff         OUT      VARCHAR2,
      retcode         OUT      NUMBER,
      ln_batch_size   IN       NUMBER,
      lc_as_of_date   IN       VARCHAR2
   )
   IS
      lc_request_data   VARCHAR2 (80) := NULL;
      ln_curr_req_id    NUMBER;
      ln_copy_req_id    NUMBER;
      lc_error_loc      VARCHAR2(500) := NULL;                 -- Added log message for defect 10750
    BEGIN

      lc_error_loc := 'Entered into Main Procedure';                        --Added log message for defect 10750
      g_as_of_date := TRUNC (fnd_conc_date.string_to_date (lc_as_of_date));

      lc_request_data := fnd_conc_global.request_data;

-- ln_curr_req_id     :=fnd_global.conc_request_id;
      fnd_file.put_line (fnd_file.LOG,
                         'FND Conc Global Request Data is :'
                         || lc_request_data
                        );
      lc_error_loc := 'Submitting GEN CBI XML Program';                  --Added log message for defect 10750
      ln_curr_req_id :=
         fnd_request.submit_request (application      => 'xxfin',
                                     program          => 'XX_AR_GEN_CBI_XML',
                                     sub_request      => FALSE,
                                     argument1        => ln_batch_size,
                                     argument2        => lc_as_of_date
                                    );

--    COMMIT WORK;
      IF ln_curr_req_id = 0
      THEN
         xx_ar_print_summbill.lv_message_buffer := fnd_message.get;
         fnd_file.put_line
            (fnd_file.LOG,
                'Failed to submit the job to generate the XML data file for Certegy:'
             || xx_ar_print_summbill.lv_message_buffer
            );
      ELSE
         fnd_file.put_line
                  (fnd_file.LOG,
                   'Job submitted to generate the XML data file for Certegy:'
                  );
         fnd_file.put_line (fnd_file.LOG,
                            'Request: ' || TO_CHAR (ln_curr_req_id)
                           );
         COMMIT WORK;
      END IF;

       lc_error_loc := 'Waiting for GEN CBI XML Program to complete';      --Added log message for defect 10750

      xx_ar_print_summbill.lc_cp_running :=
         fnd_concurrent.wait_for_request
                                  (ln_curr_req_id --Check to see if the master request id is complete.
                                   ,10                       --sleep for 6 secs
                                   ,
                                   0,
                                   xx_ar_print_summbill.lc_fndconc_phase,
                                   xx_ar_print_summbill.lc_fndconc_status,
                                   xx_ar_print_summbill.lc_fndconc_dev_phase,
                                   xx_ar_print_summbill.lc_fndconc_dev_status,
                                   xx_ar_print_summbill.lc_fndconc_message
                                  );

      IF     (xx_ar_print_summbill.lc_fndconc_dev_phase = 'COMPLETE')
         AND (xx_ar_print_summbill.lc_fndconc_dev_status = 'NORMAL')
      THEN
         ln_copy_req_id :=

            fnd_request.submit_request (application      => 'xxfin',
                                        program          => 'XXARCOPYXML',
                                        sub_request      => FALSE,
                                        argument1        => ln_curr_req_id
                                       );

         lc_error_loc := 'After submitting COPY XML Program';      --Added log message for defect 10750

         IF ln_copy_req_id = 0
         THEN
            xx_ar_print_summbill.lv_message_buffer := fnd_message.get;
            fnd_file.put_line
               (fnd_file.LOG,
                   'Failed to trigger the creation of XML data files to the ebiz Certegy folder:'
                || xx_ar_print_summbill.lv_message_buffer
               );
         ELSE
            fnd_file.put_line
               (fnd_file.LOG,
                'Job submitted to copy the xml data files to the ebiz certegy folder:'
               );
            fnd_file.put_line (fnd_file.LOG,
                               'Request: ' || TO_CHAR (ln_copy_req_id)
                              );
            COMMIT WORK;
         END IF;
      END IF;

   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'main :');
         fnd_file.put_line (fnd_file.LOG, 'Error Message: ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG,'Error in Main :' || lc_error_loc); -- Added log message for defect 10750
         retcode := 2;
   END main;

   PROCEDURE gen_cbi_xml (
      errbuff         OUT      VARCHAR2,
      retcode         OUT      NUMBER,
      ln_batch_size   IN       NUMBER,
      lc_as_of_date   IN       VARCHAR2
   )
   IS
      CURSOR g_thread
      IS
         SELECT   thread_id
             FROM xx_ar_cons_bills_history
            WHERE print_date <= g_as_of_date                 --TRUNC(SYSDATE)
              AND NVL (process_flag, 'N') != 'Y'
              AND attribute13 = to_char(p_request_id)  --added to_char for defect 12925
              AND thread_id IS NOT NULL
         GROUP BY thread_id
         ORDER BY thread_id;

      lc_request_data   VARCHAR2 (80)                             := NULL;
      c_who             CONSTANT fnd_user.user_id%TYPE := fnd_profile.VALUE ('USER_ID');
      ln_org            NUMBER                 := fnd_profile.VALUE ('ORG_ID');
      p_status          xx_ar_cbi_xml_threads.status%TYPE
                                                         := 'COPY-XML-PENDING';
      lc_error_loc            VARCHAR2(150) := NULL;                 -- Added log message for defect 10750
      lc_error_debug          VARCHAR2(100) := NULL;                 -- Added log message for defect 10750

      lc_cm_text1              VARCHAR2(50)        DEFAULT NULL;  -- Added for Defect # 631 (CR : 662)
      lc_cm_text2              VARCHAR2(50)        DEFAULT NULL;  -- Added for Defect # 631 (CR : 662)
      lc_gift_card_text1       VARCHAR2(50)        DEFAULT NULL;  -- Added for Defect # 1451 (CR : 626)
      lc_gift_card_text2       VARCHAR2(50)        DEFAULT NULL;  -- Added for Defect # 1451 (CR : 626)
      lc_gift_card_text3       VARCHAR2(50)        DEFAULT NULL;  -- Added for Defect # 1451 (CR : 626)


   BEGIN
      lc_error_loc   := 'Inside gen_cbi_xml Procedure';    -- Added log message for defect 10750
      lc_error_debug :=  NULL;                            -- Added log message for defect 10750

      g_as_of_date := TRUNC (fnd_conc_date.string_to_date (lc_as_of_date));
      fnd_file.put_line (fnd_file.LOG,
                         'Current Request ID :' || fnd_global.conc_request_id
                        );
      p_request_id := fnd_global.conc_request_id;
      p_batch_size := ln_batch_size;
      lc_request_data := fnd_conc_global.request_data;
      fnd_file.put_line (fnd_file.LOG,
                         'FND Conc Global Request Data is :'
                         || lc_request_data
                        );

      IF (lc_request_data = '1')
      THEN
         fnd_file.put_line (fnd_file.LOG, 'lc request data is 1, return...');
         RETURN;
      END IF;

-- Start for Defect # 631 (CR 662)
     BEGIN

        SELECT  SUBSTR(description,1,50)
        INTO    lc_cm_text1
        FROM    fnd_lookup_values_vl
        WHERE   lookup_type='OD_BILLING_CM_LINE_TEXT'
        AND     lookup_code='TEXT1'
        AND     enabled_flag='Y'
        AND     TRUNC(SYSDATE) BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active,SYSDATE+1));

     EXCEPTION
        WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'No data found in lookup OD_BILLING_CM_LINE_TEXT to the TEXT1 To Field');
            lc_cm_text1 := NULL;
        WHEN OTHERS THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Exception : TEXT1 -> OD_BILLING_CM_LINE_TEXT lookup');
             lc_cm_text1 := NULL;
     END;

     BEGIN

        SELECT  SUBSTR(description,1,50)
        INTO    lc_cm_text2
        FROM    fnd_lookup_values_vl
        WHERE   lookup_type='OD_BILLING_CM_LINE_TEXT'
        AND     lookup_code='TEXT2'
        AND     enabled_flag='Y'
        AND     trunc(SYSDATE) BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active,SYSDATE+1));

     EXCEPTION
        WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'No data found in lookup OD_BILLING_CM_LINE_TEXT to the TEXT2 To Field');
            lc_cm_text2 := NULL;
        WHEN OTHERS THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Exception : TEXT2 -> OD_BILLING_CM_LINE_TEXT lookup');
             lc_cm_text2 := NULL;
     END;

-- End for Defect # 631 (CR 662)

-- Start for Defect # 1451 (CR 626)
     BEGIN

        SELECT  SUBSTR(description,1,50)
        INTO    lc_gift_card_text1
        FROM    fnd_lookup_values_vl
        WHERE   lookup_type    = 'OD_BILLING_TENDER_PAYMENT_TEXT'
        AND     lookup_code    = 'TEXT1'
        AND     enabled_flag   = 'Y'
        AND     TRUNC(SYSDATE) BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active,SYSDATE+1));

     EXCEPTION
        WHEN NO_DATA_FOUND THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'No data found in lookup OD_BILLING_TENDER_PAYMENT_TEXT to the TEXT1 To Field');
           lc_gift_card_text1 := NULL;
        WHEN OTHERS THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Exception : TEXT1 -> OD_BILLING_TENDER_PAYMENT_TEXT lookup');
           lc_gift_card_text1 := NULL;
     END;

     BEGIN

        SELECT  SUBSTR(description,1,50)
        INTO    lc_gift_card_text2
        FROM    fnd_lookup_values_vl
        WHERE   lookup_type    = 'OD_BILLING_TENDER_PAYMENT_TEXT'
        AND     lookup_code    = 'TEXT2'
        AND     enabled_flag   = 'Y'
        AND     trunc(SYSDATE) BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active,SYSDATE+1));

     EXCEPTION
        WHEN NO_DATA_FOUND THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'No data found in lookup OD_BILLING_TENDER_PAYMENT_TEXT to the TEXT2 To Field');
           lc_gift_card_text2 := NULL;
        WHEN OTHERS THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Exception : TEXT2 -> OD_BILLING_TENDER_PAYMENT_TEXT lookup');
           lc_gift_card_text2 := NULL;
     END;

     BEGIN

        SELECT  SUBSTR(description,1,50)
        INTO    lc_gift_card_text3
        FROM    fnd_lookup_values_vl
        WHERE   lookup_type    = 'OD_BILLING_TENDER_PAYMENT_TEXT'
        AND     lookup_code    = 'TEXT3'
        AND     enabled_flag   = 'Y'
        AND     trunc(SYSDATE) BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active,SYSDATE+1));

     EXCEPTION
        WHEN NO_DATA_FOUND THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'No data found in lookup OD_BILLING_TENDER_PAYMENT_TEXT to the TEXT3 To Field');
           lc_gift_card_text3 := NULL;
        WHEN OTHERS THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Exception : TEXT3 -> OD_BILLING_TENDER_PAYMENT_TEXT lookup');
           lc_gift_card_text3 := NULL;
     END;

-- End for Defect # 1451 (CR 626)


      fnd_file.put_line (fnd_file.LOG, 'Calling xx_ar_print_summbill.get_cons_bills........');
      --DELETE XX_AR_CBI_TOTALS_V;
      lc_error_loc := 'Calling get_cons_bills Procedure';    -- Added log message for defect 10750
      lc_error_debug :=  NULL;                            -- Added log message for defect 10750
      xx_ar_print_summbill.get_cons_bills;
      fnd_file.put_line (fnd_file.LOG, 'Exited xx_ar_print_summbill.get_cons_bills........');

-- =================================================
-- Spawn multiple threads of the Certegy xml
-- data def program XXARCBIPRI based on thread id
-- =================================================
      FOR batch_rec IN g_thread
      LOOP
         lc_error_loc       := 'Calling XXARCBIPRI program for the thread ';    -- Added log message for defect 10750
         lc_error_debug     := 'Debug : '||batch_rec.thread_id ;                -- Added log message for defect 10750
         xx_ar_print_summbill.ln_request_id :=
            fnd_request.submit_request (application      => 'xxfin',
                                        program          => 'XXARCBIPRI',
                                        sub_request      => TRUE,
                                        argument1        => batch_rec.thread_id,--argument1
                                        argument2        => lc_as_of_date, --argument2
                                        argument3        => 'Y', --Added Debug parameter
                                        argument4        => lc_cm_text1,   -- Added for Defect # 631 (CR : 662)
                                        argument5        => lc_cm_text2,   -- Added for Defect # 631 (CR : 662)
                                        argument6        => lc_gift_card_text1,   -- Added for defect 1451 CR 626
                                        argument7        => lc_gift_card_text2,   -- Added for defect 1451 CR 626
                                        argument8        => lc_gift_card_text3   -- Added for defect 1451 CR 626
                                        );
         IF xx_ar_print_summbill.ln_request_id = 0
         THEN
            xx_ar_print_summbill.lv_message_buffer := fnd_message.get;
            fnd_file.put_line
               (fnd_file.LOG,
                   'Failed to submit the job to generate XML data for Certegy:'
                || xx_ar_print_summbill.lv_message_buffer
               );
         ELSE
-- ========================================================================
-- Defect: 10340. This table stores all jobs submitted above.
-- We will use this in create_xml_files to make sure they are picked up again.
-- ========================================================================
            BEGIN
               lc_error_loc   := 'Before Inserting into xx_ar_cbi_xml_threads ';    -- Added log message for defect 10750
               lc_error_debug := 'Inserting thread: '|| batch_rec.thread_id ;       -- Added log message for defect 10750
               INSERT INTO xx_ar_cbi_xml_threads
                           (parent_request_id,
                            child_request_id,
                            thread_id, status, created_by, creation_date,
                            last_updated_by, last_update_date, org_id
                           )
                    VALUES (p_request_id,
                            xx_ar_print_summbill.ln_request_id,
                            batch_rec.thread_id, p_status, c_who, SYSDATE,
                            NULL, NULL, ln_org
                           );
               lc_error_loc   := 'After Inserting into xx_ar_cbi_xml_threads ';    -- Added log message for defect 10750
               lc_error_debug := 'After Inserting thread: '|| batch_rec.thread_id ;       -- Added log message for defect 10750
            EXCEPTION
               WHEN OTHERS
               THEN
                  fnd_file.put_line
                      (fnd_file.LOG,
                          'Location: Insert into XX_AR_CBI_XML_THREADS'
                       || SQLERRM
                      );
                  ROLLBACK;
            END;

            fnd_file.put_line
               (fnd_file.LOG,
                   'Job submitted to generate XML data for Certegy ,Request: '
                || TO_CHAR (xx_ar_print_summbill.ln_request_id)
               );
            /*
                 fnd_file.put_line (fnd_file.LOG,
                                       'Request: '
                                    || TO_CHAR (xx_ar_print_summbill.ln_request_id)
                                   );
            */
            COMMIT WORK;
            END IF;
      END LOOP;                                            --BATCH REC LOOP...

      /* Added this IF, THEN, ELSE for defect 9346 */
      /* If there were child prints submitted wait, otherwise end */
      IF xx_ar_print_summbill.ln_request_id > 0
      THEN
         fnd_conc_global.set_req_globals (conc_status       => 'PAUSED',
                                          request_data      => '1'
                                         );
         COMMIT;
         fnd_file.put_line (fnd_file.LOG,
                               'FND Conc Global Request Data is :'
                            || fnd_conc_global.request_data
                           );
         retcode := 0;
         RETURN;
      ELSE
         fnd_file.put_line
            (fnd_file.LOG,
                'No jobs submitted to generate XML data for Certegy, request_id: '
             || p_request_id
            );
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'GEN_CBI_XML :');
         fnd_file.put_line (fnd_file.LOG, 'Error Message: ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG,'Error in gen_cbi_xml:'|| lc_error_loc
                            ||'Debug:'||lc_error_debug);   -- Added for Defect 10750
         retcode := 2;
   END gen_cbi_xml;

   PROCEDURE create_xml_files (
      errbuff       OUT      VARCHAR2,
      retcode       OUT      NUMBER,
      p_parent_id   IN       NUMBER
   )
   IS
      p_init_status     xx_ar_cbi_xml_threads.status%TYPE
                                                       := 'COPY-XML-COMPLETE';

      CURSOR child_requests
      IS
         SELECT   fcr.request_id, fcr.outfile_name outfile
                 ,fcr.status_code status_code   --Added for Defect # 15622
             FROM fnd_concurrent_requests fcr,
                  xx_ar_cbi_xml_threads xmlreqs
            WHERE 1 = 1
              AND fcr.request_id = xmlreqs.child_request_id
              --Added next two lines for 10340
              AND fcr.phase_code = 'C'                             --Completed
--              and fcr.status_code = 'C' --Normal
              AND (    (xmlreqs.status != p_init_status)
                   AND (xmlreqs.status NOT LIKE 'ZIP%')
                  )
         ORDER BY fcr.request_id;

      /*
            SELECT   request_id, outfile_name outfile
                FROM fnd_concurrent_requests
               WHERE parent_request_id = p_parent_id
            ORDER BY request_id;
      */
      my_requests_tbl   xx_ar_print_summbill.t_req_id;
      lc_request_data   VARCHAR2 (30)                             := NULL;
      ln_copy_id        NUMBER                                    := NULL;
      ln_zip_id         NUMBER                                    := NULL;
      ln_count          NUMBER                                    := 1;
      ln_counter        NUMBER                                    := 0;
      c_who    CONSTANT fnd_user.user_id%TYPE := fnd_profile.VALUE ('USER_ID');
      lc_org            VARCHAR2 (10);
      -- Added by Sarat for Defect 9453 and 9507
      ln_org            NUMBER            := fnd_profile.VALUE ('ORG_ID');
      ln_us_org         NUMBER
                           := xx_fin_country_defaults_pkg.f_org_id ('US');
      ln_ca_org         NUMBER
                           := xx_fin_country_defaults_pkg.f_org_id ('CA');
      ln_zip_cnt        NUMBER                                    := 0;
      -- Added by Sarat for Defect 9346 on 08/25/08
      p_status          xx_ar_cbi_xml_threads.status%TYPE
                                                        := 'COPY-XML-COMPLETE';
      p_final_status    xx_ar_cbi_xml_threads.status%TYPE
                                                         := 'ZIP-XML-COMPLETE';
      lc_error_loc     VARCHAR2(500) := NULL ;   -- Added log message for Defect 10750
      lc_error_debug     VARCHAR2(500) := NULL ;   -- Added log message for Defect 10750
      ln_child_err_cnt   NUMBER := 0;     --Added for the Defect # 15622
   BEGIN
      lc_error_loc   := 'Inside create_xml_files';  --Added log message for Defect 10750
      lc_error_debug := NULL ;
      fnd_file.put_line (fnd_file.LOG, 'Parent Request ID :' || p_parent_id);
      lc_request_data := fnd_conc_global.request_data;
      fnd_file.put_line (fnd_file.LOG,
                         'FND Conc Global Request Data is :'
                         || lc_request_data
                        );

      IF ln_us_org = ln_org
      THEN
         lc_org := 'US';
      ELSIF ln_ca_org = ln_org
      THEN
         lc_org := 'CA';
      ELSE
         lc_org := '??';
      END IF;

-- Start for the Defect # 15622

   ln_child_err_cnt:=0;
 IF p_parent_id IS NOT NULL THEN

   BEGIN

      SELECT COUNT(XACX.child_request_id)
      INTO   ln_child_err_cnt
      FROM   xx_ar_cbi_xml_threads XACX
            ,fnd_concurrent_requests FCR
      WHERE  XACX.parent_request_id = p_parent_id
      AND    XACX.child_request_id = FCR.request_id
      AND    FCR.status_code NOT IN ('C','G');

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
            ln_child_err_cnt := 0;
            fnd_file.put_line (fnd_file.LOG,'NO_DATA_FOUND At Child failed Jobs : ln_child_err_cnt --> '||ln_child_err_cnt);
      WHEN OTHERS THEN
            ln_child_err_cnt :=-1;
            fnd_file.put_line (fnd_file.LOG,'WHEN OTHERS At Child failed Jobs : ln_child_err_cnt --> '||ln_child_err_cnt);
   END;

   fnd_file.put_line (fnd_file.LOG,' Failed Jobs : ln_child_err_cnt --> '||ln_child_err_cnt);

 ELSE

   ln_child_err_cnt := 0;

 END IF;
-- End for the Defect # 15622

   IF (ln_child_err_cnt = 0) THEN    -- Added for the Defect # 15622

      FOR child_request_rec IN child_requests
      LOOP
        IF child_request_rec.status_code IN ('G','C') THEN ---- Added for the Defect # 15622
         ln_zip_cnt := ln_zip_cnt + 1;
         lc_error_loc   := 'Inside child_requests';  --Added log message for Defect 10750
         lc_error_debug := NULL ;
         -- Added by Sarat for Defect 9346 on 08/25/08
         IF ln_us_org = ln_org
         THEN
            xx_ar_print_summbill.lv_certegy_file :=
                  'Certegy_AR_Summary_US_'
               || TO_CHAR (child_request_rec.request_id)
               || '.xml';
         --        := 'Certegy_AR_Summary_US_'||TO_CHAR(SYSDATE ,'DDMONYYHHMISS_')||TO_CHAR(child_request_rec.request_id)||'.xml';
         ELSIF ln_ca_org = ln_org
         THEN
            xx_ar_print_summbill.lv_certegy_file :=
                  'Certegy_AR_Summary_CA_'
               || TO_CHAR (child_request_rec.request_id)
               || '.xml';
         --        := 'Certegy_AR_Summary_CA_'||TO_CHAR(SYSDATE ,'DDMONYYHHMISS_')||TO_CHAR(child_request_rec.request_id)||'.xml';
         ELSE
            /*
             Currently the script will not support other than US and CANADA...
            */
            fnd_file.put_line (fnd_file.LOG,
                                  'Operating Unit NONE, Request Id:'
                               || TO_CHAR (child_request_rec.request_id)
                              );
            NULL;
         END IF;

         lc_error_loc   := 'Calling Commom Copy File Program';  --Added log message for Defect 10750
         lc_error_debug := NULL ;                               --Added log message for Defect 10750
         ln_copy_id :=
            fnd_request.submit_request
                    (application      => 'xxfin',
                     program          => 'XXCOMFILCOPY',
                     description      => 'Create XML File',
                     sub_request      => FALSE                          --TRUE
                                              ,
                     argument1        => child_request_rec.outfile,
                     argument2        =>    '$XXFIN_DATA/ftp/out/arinvoice/certegy/'
                                         || xx_ar_print_summbill.lv_certegy_file,
                     argument3        => '',
                     argument4        => '',
                     argument5        => '',
                     argument6        => ''
                    );

         IF ln_copy_id = 0
         THEN
            xx_ar_print_summbill.lv_message_buffer := fnd_message.get;
            fnd_file.put_line
               (fnd_file.LOG,
                   'Failed to submit the job to copy the XML data file to the ebiz Certegy folder:'
                || xx_ar_print_summbill.lv_message_buffer
               );
         ELSE
            fnd_file.put_line
               (fnd_file.LOG,
                'Job submitted to copy the xml data file to the ebiz certegy folder:'
               );
            fnd_file.put_line (fnd_file.LOG,
                               'Request: ' || TO_CHAR (ln_copy_id)
                              );
            COMMIT;
            ln_counter := ln_counter + 1;

--  ================================
--  Defect: 10340
--  ================================
            LOOP
               xx_ar_print_summbill.lc_cp_running :=
                  fnd_concurrent.wait_for_request
                                 (ln_copy_id,
                                  5                         --sleep for 5 secs
                                   ,
                                  0,
                                  xx_ar_print_summbill.lc_fndconc_phase,
                                  xx_ar_print_summbill.lc_fndconc_status,
                                  xx_ar_print_summbill.lc_fndconc_dev_phase,
                                  xx_ar_print_summbill.lc_fndconc_dev_status,
                                  xx_ar_print_summbill.lc_fndconc_message
                                 );

               IF (xx_ar_print_summbill.lc_fndconc_dev_phase = 'COMPLETE')
               THEN
                  IF (xx_ar_print_summbill.lc_fndconc_dev_status = 'NORMAL'
                     )
                  THEN
                     BEGIN
                        SAVEPOINT start1;

                        UPDATE xx_ar_cbi_xml_threads
                           SET status = 'COPY-XML-COMPLETE',
                               last_updated_by = c_who,
                               last_update_date = SYSDATE
                         WHERE child_request_id = child_request_rec.request_id;

                        my_requests_tbl (ln_counter) :=
                                                  child_request_rec.request_id;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           ROLLBACK TO start1;
                     END;

                     EXIT;
                  ELSIF (xx_ar_print_summbill.lc_fndconc_dev_status = 'ERROR'
                        )
                  THEN
                     BEGIN
                        SAVEPOINT start1;

                        lc_error_loc   := 'Before updating xx_ar_cbi_xml_threads for copy XML Error ';  --Added log message for Defect 10750
                        lc_error_debug := 'For Request Id'||child_request_rec.request_id ;                               --Added log message for Defect 10750
                        UPDATE xx_ar_cbi_xml_threads
                           SET status = 'COPY-XML-ERROR',
                               last_updated_by = c_who,
                               last_update_date = SYSDATE
                         WHERE child_request_id = child_request_rec.request_id;

                        lc_error_loc   := 'After updating xx_ar_cbi_xml_threads for copy XML Error ';  --Added log message for Defect 10750
                        lc_error_debug := 'For Request Id'||child_request_rec.request_id ;                               --Added log message for Defect 10750
                        my_requests_tbl (ln_counter) :=
                                                  child_request_rec.request_id;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           ROLLBACK TO start1;
                     END;

                     EXIT;
                  ELSE
                     BEGIN
                        SAVEPOINT start1;

                        lc_error_loc   := 'Before updating xx_ar_cbi_xml_threads ';  --Added log message for Defect 10750
                        lc_error_debug := 'For Request Id'||child_request_rec.request_id ;                               --Added log message for Defect 10750
                        UPDATE xx_ar_cbi_xml_threads
                           SET status =
                                     'COPY-XML-'
                                  || xx_ar_print_summbill.lc_fndconc_dev_status,
                               last_updated_by = c_who,
                               last_update_date = SYSDATE
                         WHERE child_request_id = child_request_rec.request_id;

                        lc_error_loc   := 'After updating xx_ar_cbi_xml_threads for copy XML Error ';  --Added log message for Defect 10750
                        lc_error_debug := 'For Request Id'||child_request_rec.request_id ;                               --Added log message for Defect 10750
                        my_requests_tbl (ln_counter) :=
                                                  child_request_rec.request_id;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           ROLLBACK TO start1;
                     END;

                     EXIT;
                  END IF;
               --check for normal, error and other statuses when dev phase =complete.
               ELSE
                  NULL;
--loop thru another 6 seconds to find what's going on with the zip program status.
               END IF;
            END LOOP;                 --check whether the request is complete.
         END IF;
    -- Start for the Defect # 15622
       ELSE
          BEGIN
                   SAVEPOINT start1;

                        lc_error_loc   := 'Before updating xx_ar_cbi_xml_threads for threads not completing normally';
                        lc_error_debug := 'For Request Id'||child_request_rec.request_id ;
                        UPDATE xx_ar_cbi_xml_threads
                           SET status = 'CHILD-ERROR',
                               last_updated_by = c_who,
                               last_update_date = SYSDATE
                         WHERE child_request_id = child_request_rec.request_id;

           EXCEPTION
                        WHEN OTHERS
                        THEN
                           ROLLBACK TO start1;
           END;
--           EXIT;
      END IF;
  -- End for the Defect # 15622
      END LOOP;

      /*
          if my_requests_tbl.count >0 then
           for indx in my_requests_tbl.first .. my_requests_tbl.last
            loop
               fnd_file.put_line(fnd_file.LOG,'XML Request ID :'||my_requests_tbl(indx));
            end loop;
          else
            fnd_file.put_line(fnd_file.LOG,'No XML request to display...');
          end if;
      */
      fnd_file.put_line
               (fnd_file.LOG,'FND_GLOBAL.CONC_REQUEST_ID : '||FND_GLOBAL.CONC_REQUEST_ID);
      WHILE ln_count > 0
      LOOP
         SELECT COUNT (fcr.request_id)
           INTO ln_count
           FROM fnd_concurrent_requests fcr, fnd_concurrent_programs fcp
          WHERE fcp.concurrent_program_name = 'XXCOMFILCOPY'
            AND fcp.concurrent_program_id = fcr.concurrent_program_id
            AND parent_request_id = FND_GLOBAL.CONC_REQUEST_ID
            AND fcr.phase_code != 'C';

         DBMS_LOCK.sleep (10);
      END LOOP;

      -- Added IF and END IF for the Defect 9346
      IF (ln_zip_cnt) > 0
      THEN
         lc_error_loc   := 'Calling Ziping Program if zip_count is >0 ';  --Added log message for Defect 10750
         lc_error_debug := NULL ; --Added log message for Defect 10750
         ln_zip_id :=
            fnd_request.submit_request
               (application      => 'xxfin',
                program          => 'XXARINVBILLZIP',
                description      => 'Zip Certegy Summary XML Files',
                sub_request      => FALSE                               --TRUE
                                         ,
                argument1        =>    '$XXFIN_DATA/ftp/out/arinvoice/certegy/Certegy_AR_Summary_'
                                    || lc_org
                                    || '*.xml',
                argument2        =>    '$XXFIN_DATA/ftp/out/arinvoice/certegy/OFFICEDEPOT_CONSOLIDATED_'
                                    || lc_org,
                argument3        =>    '$XXFIN_DATA/ftp/out/arinvoice/certegy/DONE_CONS_'
                                    || lc_org,
                argument4        => '2147483648',
                argument5        => '$XXFIN_DATA/archive/outbound',
                argument6        => '$XXFIN_DATA/archive/outbound',
                argument7        => 'Y',
                argument8        => '',
                argument9        => '',
                argument10       => ''
               );

         IF ln_zip_id = 0
         THEN
            xx_ar_print_summbill.lv_message_buffer := fnd_message.get;
            fnd_file.put_line
               (fnd_file.LOG,
                   'Failed to submit the job to zip the XML data file to the ebiz Certegy folder:'
                || xx_ar_print_summbill.lv_message_buffer
               );
         ELSE
            fnd_file.put_line
               (fnd_file.LOG,
                'Job submitted to zip the xml data file to the ebiz certegy folder:'
               );
            fnd_file.put_line (fnd_file.LOG,
                               'Request: ' || TO_CHAR (ln_zip_id)
                              );
            COMMIT WORK;

-- ==================================================
-- Update xml request id status to ZIP-XML-COMPLETE
-- ==================================================
            LOOP
               xx_ar_print_summbill.lc_cp_running :=
                  fnd_concurrent.wait_for_request
                                 (ln_zip_id,
                                  6                         --sleep for 6 secs
                                   ,
                                  0,
                                  xx_ar_print_summbill.lc_fndconc_phase,
                                  xx_ar_print_summbill.lc_fndconc_status,
                                  xx_ar_print_summbill.lc_fndconc_dev_phase,
                                  xx_ar_print_summbill.lc_fndconc_dev_status,
                                  xx_ar_print_summbill.lc_fndconc_message
                                 );

               lc_error_loc   := 'Update xml request id status to ZIP-XML-COMPLETE';  --Added log message for Defect 10750
               lc_error_debug := NULL ;  --Added log message for Defect 10750
               IF (xx_ar_print_summbill.lc_fndconc_dev_phase = 'COMPLETE')
               THEN
                  IF (xx_ar_print_summbill.lc_fndconc_dev_status = 'NORMAL'
                     )
                  THEN
                     IF my_requests_tbl.COUNT > 0
                     THEN
                        FOR indx IN
                           my_requests_tbl.FIRST .. my_requests_tbl.LAST
                        LOOP
                           BEGIN
                              SAVEPOINT start1;

                              UPDATE xx_ar_cbi_xml_threads
                                 SET status = p_final_status,
                                     last_updated_by = c_who,
                                     last_update_date = SYSDATE
                               WHERE child_request_id = my_requests_tbl (indx);
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 fnd_file.put_line
                                    (fnd_file.LOG,
                                        'Problem during update of xx_ar_cbi_xml_threads with status of'
                                     || p_final_status
                                    );
                                 fnd_file.put_line (fnd_file.LOG,
                                                       'Child request id :'
                                                    || my_requests_tbl (indx)
                                                   );
                                 fnd_file.put_line (fnd_file.LOG, SQLERRM);
                                 ROLLBACK TO start1;
                           END;
                        END LOOP;
                     END IF;

                     EXIT;
                  ELSIF (xx_ar_print_summbill.lc_fndconc_dev_status = 'ERROR'
                        )
                  THEN
                     IF my_requests_tbl.COUNT > 0
                     THEN
                        FOR indx IN
                           my_requests_tbl.FIRST .. my_requests_tbl.LAST
                        LOOP
                           BEGIN
                              SAVEPOINT start1;

                              UPDATE xx_ar_cbi_xml_threads
                                 SET status = 'ZIP-XML-ERROR',
                                     last_updated_by = c_who,
                                     last_update_date = SYSDATE
                               WHERE child_request_id = my_requests_tbl (indx);
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 fnd_file.put_line
                                    (fnd_file.LOG,
                                     'Problem during update of xx_ar_cbi_xml_threads with status of ZIP-XML-ERROR'
                                    );
                                 fnd_file.put_line (fnd_file.LOG,
                                                       'Child request id :'
                                                    || my_requests_tbl (indx)
                                                   );
                                 fnd_file.put_line (fnd_file.LOG, SQLERRM);
                                 ROLLBACK TO start1;
                           END;
                        END LOOP;
                     END IF;

                     EXIT;
                  ELSE
                     IF my_requests_tbl.COUNT > 0
                     THEN
                        FOR indx IN
                           my_requests_tbl.FIRST .. my_requests_tbl.LAST
                        LOOP
                           BEGIN
                              SAVEPOINT start1;

                              UPDATE xx_ar_cbi_xml_threads
                                 SET status =
                                           'ZIP-XML-'
                                        || xx_ar_print_summbill.lc_fndconc_dev_status,
                                     last_updated_by = c_who,
                                     last_update_date = SYSDATE
                               WHERE child_request_id = my_requests_tbl (indx);
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 fnd_file.put_line
                                    (fnd_file.LOG,
                                        'Problem during update of xx_ar_cbi_xml_threads with status of ZIP-XML-'
                                     || xx_ar_print_summbill.lc_fndconc_dev_status
                                    );
                                 fnd_file.put_line (fnd_file.LOG,
                                                       'Child request id :'
                                                    || my_requests_tbl (indx)
                                                   );
                                 fnd_file.put_line (fnd_file.LOG, SQLERRM);
                                 ROLLBACK TO start1;
                           END;
                        END LOOP;
                     END IF;

                     EXIT;
                  END IF;
               --check for normal, error and other statuses when dev phase =complete.
               ELSE
                  NULL;
--loop thru another 6 seconds to find what's going on with the zip program status.
               END IF;
            END LOOP;
         END IF;
      ELSE
         /*
            -- ====================================================
            -- Create an empty zip as well as DONE file when there
            -- are no threads [xml data files].
            -- ====================================================
         */
          lc_error_loc   := 'Create an empty zip as well as DONE file';  --Added log message for Defect 10750
          lc_error_debug := NULL ;  --Added log message for Defect 10750
         ln_zip_id :=
            fnd_request.submit_request
               (application      => 'xxfin',
                program          => 'XXARINVBILLZIP',
                description      => 'Zip Certegy Summary XML Files',
                sub_request      => FALSE                               --TRUE
                                         ,
                argument1        =>    '$XXFIN_DATA/ftp/out/arinvoice/certegy/Certegy_AR_Summary_'
                                    || lc_org,
--                                 || '*.xml', removed 11105
                argument2        =>    '$XXFIN_DATA/ftp/out/arinvoice/certegy/OFFICEDEPOT_CONSOLIDATED_'
                                    || lc_org,
                argument3        =>    '$XXFIN_DATA/ftp/out/arinvoice/certegy/DONE_CONS_'
                                    || lc_org,
                argument4        => '2147483648',
                argument5        => '$XXFIN_DATA/archive/outbound',
                argument6        => '$XXFIN_DATA/archive/outbound',
                argument7        => 'Y',
                argument8        => '',
                argument9        => '',
                argument10       => 'Y'
               );
         COMMIT;
      END IF;
      --Start for the Defect # 15622
   ELSE
        fnd_file.put_line (fnd_file.LOG,'One or more Child programs failed in this run.');
        fnd_file.put_line (fnd_file.LOG,' Please solve the problem and re-run entire process with same parameters ');
        fnd_file.put_line (fnd_file.LOG,'Or run the OD: AR Trigger Consolidated Bill XML Files program without any parameter');
   END IF;
      --End  for the Defect # 15622
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'Error in Routine CREATE_XML_FILES :'
                           );
         fnd_file.put_line (fnd_file.LOG, 'Error Message: ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG,'Error in Create_XML_files:'
                            ||lc_error_loc||'Debug:'||lc_error_debug) ;  -- Added log message for Defect 10750
         retcode := 2;
   END create_xml_files;
/* The following function is added as a part of CR 460 to get site use ids by considering
   new mailing address for the scenerio'PAYDOC_IC' for the Defect # 10750*/

   FUNCTION get_paydoc_ic_siteuse_id(p_cust_acct_site_id  NUMBER
                                    ,p_cust_doc_id  NUMBER
                                    ,p_cust_acct_id  NUMBER
                                    ,p_hzsu_site_use_id  NUMBER
                                    ,p_direct_flag  VARCHAR2
                                    )
   RETURN NUMBER
   AS
   ln_site_use_id NUMBER;
   BEGIN
      BEGIN
         SELECT HZSU1.site_use_id
         INTO   ln_site_use_id
         FROM   xx_cdh_acct_site_ext_b XCAS
               ,hz_cust_acct_sites_all HZAS1
               ,hz_cust_site_uses_all  HZSU1
         WHERE  XCAS.cust_acct_site_id = p_cust_acct_site_id
         AND    XCAS.attr_group_id     = g_attr_group_id_site
         AND    HZAS1.orig_system_reference = c_ext_attr5
         AND    HZAS1.cust_acct_site_id= HZSU1.cust_acct_site_id
         AND    XCAS.n_ext_attr1=p_cust_doc_id
         AND    HZSU1.site_use_code='SHIP_TO'
         AND    XCAS.c_ext_attr20      = 'Y';                -- Added for R1.3 CR 738 Defect 2766

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            IF p_direct_flag ='Y' THEN
               SELECT  HCSU.site_use_id
               INTO    ln_site_use_id
               FROM    hz_cust_acct_sites_all HCAS
                      ,hz_cust_site_uses_all  HCSU
               WHERE   HCAS.cust_account_id = p_cust_acct_id
               AND     HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
               AND     HCSU.site_use_code   = 'BILL_TO'
               AND     HCSU.primary_flag         = 'Y';
            ELSE
               ln_site_use_id := p_hzsu_site_use_id;
            END IF;
       END;
      RETURN ln_site_use_id;
   END get_paydoc_ic_siteuse_id;


/* This function is added as part of CR 460 to get totals for the scenerio'PAYDOC_IC'
   for the defect # 10750 */

   FUNCTION get_paydoc_ic_totals
             (
               p_cbi_id              IN NUMBER
              ,p_request_id          IN NUMBER
              ,p_doc_id              IN NUMBER
              ,p_ministmnt_line_type IN VARCHAR2
             ) RETURN NUMBER AS

 ln_ext_amt_plus_delvy NUMBER :=0;
 ln_promo_and_disc     NUMBER :=0;
 ln_tax_amount     NUMBER :=0;
 ln_total_amount   NUMBER :=0;
 ln_return_amount      NUMBER :=0;
 ln_gc_inv_amt         NUMBER :=0;      -- added for the R1.1 defect # 1451 (CR 626)
 ln_gc_cm_amt          NUMBER :=0;      -- added for the R1.1 defect # 1451 (CR 626)
 lc_error_loc          VARCHAR2(500) := NULL; -- added for the R1.1 defect # 1451 (CR 626)
 lc_error_debug        VARCHAR2(500) := NULL; -- added for the R1.1 defect # 1451 (CR 626)


BEGIN
/**************/
-- below if block commented
-- for code cleanup as part of defect 13937, since there were lots of commented code.
/**************/
/* IF p_ministmnt_line_type ='EXTAMT_PLUS_DELVY' THEN
   BEGIN
/*      SELECT SUM(NVL(extamt,0))
      INTO   ln_ext_amt_plus_delvy
      FROM (
             SELECT SUM(NVL(RACTL.EXTENDED_AMOUNT ,0)) extamt
             FROM   RA_CUSTOMER_TRX_LINES RACTL
             WHERE  1 = 1
             AND    RACTL.interface_line_context ='ORDER ENTRY'
             AND    RACTL.LINE_TYPE = 'LINE'
             AND    RACTL.DESCRIPTION != 'Tiered Discount'
             AND    EXISTS
                   ( SELECT 1
                     FROM   xx_ar_cons_bills_history od_summbills
                           ,xx_ar_cbi_trx xxtrx
                     WHERE  od_summbills.attribute13  =p_request_id
                     AND    od_summbills.cons_inv_id  =p_cbi_id
                     AND    od_summbills.attribute8   ='PAYDOC_IC'
                     AND    od_summbills.document_id  =p_doc_id
                     AND    od_summbills.process_flag !='Y'
                     AND    od_summbills.cons_inv_id =   xxtrx.cons_inv_id
                     AND    od_summbills.thread_id  =xxtrx.request_id
                     AND    xxtrx.customer_trx_id   =RACTL.customer_trx_id
                   )
             UNION ALL
             SELECT SUM(NVL(RACTL.EXTENDED_AMOUNT ,0)) extamt
             FROM   RA_CUSTOMER_TRX_LINES RACTL
             WHERE  1 = 1
             AND NVL(RACTL.interface_line_context ,'?') !='ORDER ENTRY'
             AND RACTL.LINE_TYPE = 'LINE'
             AND RACTL.DESCRIPTION != 'Tiered Discount'
             AND (RACTL.INTERFACE_LINE_ATTRIBUTE11 IS NULL OR RACTL.INTERFACE_LINE_ATTRIBUTE11 =0)
             AND EXISTS
                 ( SELECT 1
                   FROM   xx_ar_cons_bills_history od_summbills
                         ,xx_ar_cbi_trx xxtrx
                   WHERE  od_summbills.attribute13  =p_request_id
                   AND    od_summbills.cons_inv_id  =p_cbi_id
                   AND    od_summbills.attribute8   ='PAYDOC_IC'
                   AND    od_summbills.document_id  =p_doc_id
                   AND    od_summbills.process_flag !='Y'
                   AND    od_summbills.cons_inv_id =   xxtrx.cons_inv_id
                   AND    od_summbills.thread_id  =xxtrx.request_id
                   AND    xxtrx.customer_trx_id   =RACTL.customer_trx_id
                )
          );
*/

/*             SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
             INTO   ln_ext_amt_plus_delvy
             FROM   RA_CUSTOMER_TRX_LINES RACTL
             WHERE  1 = 1
             AND RACTL.LINE_TYPE = 'LINE'
             AND RACTL.DESCRIPTION != 'Tiered Discount'
             AND (RACTL.INTERFACE_LINE_ATTRIBUTE11 IS NULL OR RACTL.INTERFACE_LINE_ATTRIBUTE11 =0)
             AND EXISTS
                 ( SELECT 1
                   FROM   xx_ar_cons_bills_history od_summbills
                         ,xx_ar_cbi_trx xxtrx
                   WHERE  od_summbills.attribute13  =to_char(p_request_id)
                   AND    od_summbills.cons_inv_id  =p_cbi_id
                   AND    od_summbills.attribute8   ='PAYDOC_IC'
                   AND    od_summbills.document_id  =p_doc_id
                   AND    od_summbills.process_flag !='Y'
                   AND    od_summbills.cons_inv_id =   xxtrx.cons_inv_id
                   AND    od_summbills.thread_id  =xxtrx.request_id
                   AND    xxtrx.customer_trx_id   =RACTL.customer_trx_id
                );

      lc_return_amount :=ln_ext_amt_plus_delvy;
      RETURN lc_return_amount;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     RETURN 0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_infocopy_ministmnt in formula EXTAMT+DELVY');
     RETURN 0;
   END;
 ELSIF p_ministmnt_line_type ='TAX' THEN
   BEGIN

        SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
        INTO   ln_tax_amount
        FROM   RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND RACTL.LINE_TYPE = 'TAX'
          AND EXISTS
        ( SELECT 1
          FROM  xx_ar_cons_bills_history od_summbills
               ,xx_ar_cbi_trx xxtrx
          WHERE od_summbills.attribute13  =to_char(p_request_id)  --added to char as part of perf
           AND  od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute8   ='PAYDOC_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag !='Y'
           and   od_summbills.cons_inv_id =   xxtrx.cons_inv_id
           AND  od_summbills.thread_id  =xxtrx.request_id
           AND  xxtrx.customer_trx_id   =RACTL.customer_trx_id
        );
      lc_return_amount :=ln_tax_amount;
      RETURN lc_return_amount;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     RETURN 0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_infocopy_ministmnt in formula TAX');
     RETURN 0;
   END;
 ELSIF p_ministmnt_line_type ='DISCOUNT' THEN
   BEGIN
/*        SELECT SUM(NVL(DISCOUNT.AMOUNT,0))
        INTO   ln_promo_and_disc
        FROM (
        SELECT SUM(NVL(RACTL.EXTENDED_AMOUNT ,0)) AMOUNT
        FROM   RA_CUSTOMER_TRX_LINES RACTL
              ,OE_PRICE_ADJUSTMENTS  OEPA
        WHERE  1 = 1
          AND RACTL.LINE_TYPE = 'LINE'
          AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'
          AND RACTL.INTERFACE_LINE_ATTRIBUTE11   = to_char(OEPA.PRICE_ADJUSTMENT_ID)
          AND EXISTS
        ( SELECT 1
          FROM  xx_ar_cons_bills_history od_summbills
               ,xx_ar_cbi_trx xxtrx
          WHERE od_summbills.attribute13  =p_request_id
           AND  od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute8   ='PAYDOC_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag !='Y'
           and   od_summbills.cons_inv_id =   xxtrx.cons_inv_id
           AND  od_summbills.thread_id  =xxtrx.request_id
           AND  xxtrx.customer_trx_id   =RACTL.customer_trx_id
        )
        UNION ALL
        SELECT SUM(NVL(RACTL.EXTENDED_AMOUNT ,0))
        FROM   RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND ractl.line_type = 'LINE'
          AND NVL(ractl.interface_line_context, '?') != 'ORDER ENTRY'
          AND ractl.description = 'Tiered Discount'
          AND EXISTS
        ( SELECT 1
          FROM  xx_ar_cons_bills_history od_summbills
               ,xx_ar_cbi_trx xxtrx
          WHERE od_summbills.attribute13  =p_request_id
           AND  od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute8   ='PAYDOC_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag !='Y'
           and   od_summbills.cons_inv_id =   xxtrx.cons_inv_id
           AND  od_summbills.thread_id  =xxtrx.request_id
           AND  xxtrx.customer_trx_id   =RACTL.customer_trx_id
          )
        ) DISCOUNT;
*/

 /*       SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
        INTO   ln_promo_and_disc
        FROM   RA_CUSTOMER_TRX_LINES RACTL
              ,OE_PRICE_ADJUSTMENTS  OEPA
        WHERE  1 = 1
          AND RACTL.LINE_TYPE = 'LINE'
          AND RACTL.INTERFACE_LINE_ATTRIBUTE11   = OEPA.PRICE_ADJUSTMENT_ID
          AND EXISTS
        ( SELECT 1
          FROM  xx_ar_cons_bills_history od_summbills
               ,xx_ar_cbi_trx xxtrx
          WHERE od_summbills.attribute13  =to_char(p_request_id)
           AND  od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute8   ='PAYDOC_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag !='Y'
           and   od_summbills.cons_inv_id =   xxtrx.cons_inv_id
           AND  od_summbills.thread_id  =xxtrx.request_id
           AND  xxtrx.customer_trx_id   =RACTL.customer_trx_id
        );

      lc_return_amount :=ln_promo_and_disc;
      RETURN lc_return_amount;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     RETURN 0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_infocopy_ministmnt in formula DISCOUNTS');
     RETURN 0;
   END;
 ELSIF p_ministmnt_line_type ='TOTAL' THEN
   BEGIN
/*   SELECT SUM(NVL(extamt,0)) INTO ln_ext_amt_plus_delvy
   FROM (
    SELECT SUM(NVL(RACTL.EXTENDED_AMOUNT ,0)) extamt
    FROM   RA_CUSTOMER_TRX_LINES RACTL
    WHERE  1 = 1
      AND RACTL.interface_line_context ='ORDER ENTRY'
      AND RACTL.LINE_TYPE = 'LINE'
      AND RACTL.DESCRIPTION != 'Tiered Discount'
     AND EXISTS
        ( SELECT 1
          FROM  xx_ar_cons_bills_history od_summbills
               ,xx_ar_cbi_trx xxtrx
          WHERE od_summbills.attribute13  =p_request_id
           AND  od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute8   ='PAYDOC_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag !='Y'
           and   od_summbills.cons_inv_id =   xxtrx.cons_inv_id
           AND  od_summbills.thread_id  =xxtrx.request_id
           AND  xxtrx.customer_trx_id   =RACTL.customer_trx_id
        )
    UNION ALL
    SELECT SUM(NVL(RACTL.EXTENDED_AMOUNT ,0)) extamt
    FROM   RA_CUSTOMER_TRX_LINES RACTL
    WHERE  1 = 1
      AND NVL(RACTL.interface_line_context ,'?') !='ORDER ENTRY'
      AND RACTL.LINE_TYPE = 'LINE'
      AND RACTL.DESCRIPTION != 'Tiered Discount'
      AND (RACTL.INTERFACE_LINE_ATTRIBUTE11 IS NULL OR RACTL.INTERFACE_LINE_ATTRIBUTE11 =0)
      AND EXISTS
        ( SELECT 1
          FROM  xx_ar_cons_bills_history od_summbills
               ,xx_ar_cbi_trx xxtrx
          WHERE od_summbills.attribute13  =p_request_id
           AND  od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute8   ='PAYDOC_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag !='Y'
           and   od_summbills.cons_inv_id =   xxtrx.cons_inv_id
           AND  od_summbills.thread_id  =xxtrx.request_id
           AND  xxtrx.customer_trx_id   =RACTL.customer_trx_id
          )
    );
*/

/*             SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
             INTO   ln_ext_amt_plus_delvy
             FROM   RA_CUSTOMER_TRX_LINES RACTL
             WHERE  1 = 1
             AND RACTL.LINE_TYPE = 'LINE'
             AND RACTL.DESCRIPTION != 'Tiered Discount'
             AND (RACTL.INTERFACE_LINE_ATTRIBUTE11 IS NULL OR RACTL.INTERFACE_LINE_ATTRIBUTE11 =0)
             AND EXISTS
                 ( SELECT 1
                   FROM   xx_ar_cons_bills_history od_summbills
                         ,xx_ar_cbi_trx xxtrx
                   WHERE  od_summbills.attribute13  =to_char(p_request_id)
                   AND    od_summbills.cons_inv_id  =p_cbi_id
                   AND    od_summbills.attribute8   ='PAYDOC_IC'
                   AND    od_summbills.document_id  =p_doc_id
                   AND    od_summbills.process_flag !='Y'
                   AND    od_summbills.cons_inv_id =   xxtrx.cons_inv_id
                   AND    od_summbills.thread_id  =xxtrx.request_id
                   AND    xxtrx.customer_trx_id   =RACTL.customer_trx_id
                );

      lc_return_amount :=lc_return_amount + ln_ext_amt_plus_delvy;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     lc_return_amount :=lc_return_amount+0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_infocopy_ministmnt in formula EXTAMT+DELVY');
     lc_return_amount :=lc_return_amount+0;
   END;
   BEGIN

        SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
        INTO   ln_tax_amount
        FROM   RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND RACTL.LINE_TYPE = 'TAX'
          AND EXISTS
        ( SELECT 1
          FROM  xx_ar_cons_bills_history od_summbills
               ,xx_ar_cbi_trx xxtrx
          WHERE od_summbills.attribute13  =to_char(p_request_id)  -- added to_char as part of perf
           AND  od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute8   ='PAYDOC_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag !='Y'
           and   od_summbills.cons_inv_id =   xxtrx.cons_inv_id
           AND  od_summbills.thread_id  =xxtrx.request_id
           AND  xxtrx.customer_trx_id   =RACTL.customer_trx_id
          );
      lc_return_amount :=lc_return_amount + ln_tax_amount;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     lc_return_amount :=lc_return_amount+0;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_infocopy_ministmnt in formula TAX');
     lc_return_amount :=lc_return_amount+0;
   END;
   BEGIN
/*        SELECT SUM(NVL(DISCOUNT.AMOUNT,0))
        INTO   ln_promo_and_disc
        FROM (
        SELECT SUM(NVL(RACTL.EXTENDED_AMOUNT ,0)) AMOUNT
        FROM   RA_CUSTOMER_TRX_LINES RACTL
              ,OE_PRICE_ADJUSTMENTS  OEPA
        WHERE  1 = 1
          AND RACTL.LINE_TYPE = 'LINE'
          AND RACTL.INTERFACE_LINE_CONTEXT ='ORDER ENTRY'
          AND RACTL.INTERFACE_LINE_ATTRIBUTE11   = to_char(OEPA.PRICE_ADJUSTMENT_ID)
          AND EXISTS
        ( SELECT 1
          FROM  xx_ar_cons_bills_history od_summbills
               ,xx_ar_cbi_trx xxtrx
          WHERE od_summbills.attribute13  =p_request_id
           AND  od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute8   ='PAYDOC_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag !='Y'
           and   od_summbills.cons_inv_id =   xxtrx.cons_inv_id
           AND  od_summbills.thread_id  =xxtrx.request_id
           AND  xxtrx.customer_trx_id   =RACTL.customer_trx_id
          )
        UNION ALL
        SELECT SUM(NVL(RACTL.EXTENDED_AMOUNT ,0))
        FROM   RA_CUSTOMER_TRX_LINES RACTL
        WHERE  1 = 1
          AND ractl.line_type = 'LINE'
          AND NVL(ractl.interface_line_context, '?') != 'ORDER ENTRY'
          AND ractl.description = 'Tiered Discount'
          AND EXISTS
        ( SELECT 1
          FROM  xx_ar_cons_bills_history od_summbills
               ,xx_ar_cbi_trx xxtrx
          WHERE od_summbills.attribute13  =p_request_id
           AND  od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute8   ='PAYDOC_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag !='Y'
           and   od_summbills.cons_inv_id =   xxtrx.cons_inv_id
           AND  od_summbills.thread_id  =xxtrx.request_id
           AND  xxtrx.customer_trx_id   =RACTL.customer_trx_id
          )
        ) DISCOUNT;
*/

 /*       SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)
        INTO   ln_promo_and_disc
        FROM   RA_CUSTOMER_TRX_LINES RACTL
              ,OE_PRICE_ADJUSTMENTS  OEPA
        WHERE  1 = 1
          AND RACTL.LINE_TYPE = 'LINE'
          AND RACTL.INTERFACE_LINE_ATTRIBUTE11   = OEPA.PRICE_ADJUSTMENT_ID
          AND EXISTS
        ( SELECT 1
          FROM  xx_ar_cons_bills_history od_summbills
               ,xx_ar_cbi_trx xxtrx
          WHERE od_summbills.attribute13  =to_char(p_request_id)
           AND  od_summbills.cons_inv_id  =p_cbi_id
           AND od_summbills.attribute8   ='PAYDOC_IC'
           AND od_summbills.document_id  =p_doc_id
           AND od_summbills.process_flag !='Y'
           and   od_summbills.cons_inv_id =   xxtrx.cons_inv_id
           AND  od_summbills.thread_id  =xxtrx.request_id
           AND  xxtrx.customer_trx_id   =RACTL.customer_trx_id
        );

      lc_return_amount :=lc_return_amount + ln_promo_and_disc;
      RETURN lc_return_amount;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     lc_return_amount :=lc_return_amount+0;
      RETURN lc_return_amount;
    WHEN OTHERS THEN
     fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_infocopy_ministmnt in formula DISCOUNTS');
     lc_return_amount :=lc_return_amount+0;
      RETURN lc_return_amount;
   END;
 ELSE
      RETURN(0);
 END IF;
EXCEPTION
 WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log ,'Error in function xx_ar_cbi_infocopy_ministmnt');
  fnd_file.put_line(fnd_file.log ,'Request           ID :'||p_request_id);
  fnd_file.put_line(fnd_file.log ,'Infocopy Cons Inv ID :'||p_cbi_id);
  fnd_file.put_line(fnd_file.log ,'Document          ID :'||p_doc_id);
  fnd_file.put_line(fnd_file.log ,'Type                 :'||p_ministmnt_line_type  );
  RETURN 0; */
-- changes for defect 13937 starts
   IF (p_ministmnt_line_type ='EXTAMT_PLUS_DELVY') THEN
      BEGIN
         SELECT NVL(SUM(RACTL.extended_amount),0)
         INTO   ln_ext_amt_plus_delvy
         FROM   ra_customer_trx_lines RACTL
         WHERE  1 = 1
         AND RACTL.LINE_TYPE = 'LINE'
         AND RACTL.DESCRIPTION != 'Tiered Discount'
         AND (RACTL.INTERFACE_LINE_ATTRIBUTE11 IS NULL OR RACTL.INTERFACE_LINE_ATTRIBUTE11 =0)
         AND EXISTS
             ( SELECT 1
               FROM   xx_ar_cons_bills_history OD_SUMMBILLS
                     ,xx_ar_cbi_trx XXTRX
               WHERE  OD_SUMMBILLS.attribute13  =to_char(p_request_id)
               AND    OD_SUMMBILLS.cons_inv_id  =p_cbi_id
               AND    OD_SUMMBILLS.attribute8   ='PAYDOC_IC'
               AND    OD_SUMMBILLS.document_id  =p_doc_id
               AND    OD_SUMMBILLS.process_flag !='Y'
               AND    OD_SUMMBILLS.cons_inv_id =   XXTRX.cons_inv_id
               AND    OD_SUMMBILLS.thread_id  =XXTRX.request_id
               AND    XXTRX.customer_trx_id   =RACTL.customer_trx_id
             );

         RETURN ln_ext_amt_plus_delvy;
      EXCEPTION
         WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_infocopy_ministmnt in formula EXTAMT+DELVY');
            RETURN 0;
      END;
   ELSIF (p_ministmnt_line_type ='TAX') THEN
      BEGIN
         SELECT NVL(SUM(RACTL.extended_amount),0)
         INTO   ln_tax_amount
         FROM   ra_customer_trx_lines RACTL
         WHERE  1 = 1
         AND RACTL.line_type = 'TAX'
         AND EXISTS
            ( SELECT 1
              FROM  xx_ar_cons_bills_history od_summbills
                   ,xx_ar_cbi_trx xxtrx
              WHERE OD_SUMMBILLS.attribute13  =to_char(p_request_id)
              AND  OD_SUMMBILLS.cons_inv_id  =p_cbi_id
              AND  OD_SUMMBILLS.attribute8   ='PAYDOC_IC'
              AND  OD_SUMMBILLS.document_id  =p_doc_id
              AND  OD_SUMMBILLS.process_flag !='Y'
              AND  OD_SUMMBILLS.cons_inv_id =   XXTRX.cons_inv_id
              AND  OD_SUMMBILLS.thread_id  =XXTRX.request_id
              AND  XXTRX.customer_trx_id   =RACTL.customer_trx_id
         );
        RETURN ln_tax_amount;
      EXCEPTION
         WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_infocopy_ministmnt in formula TAX');
            RETURN 0;
      END;
   ELSIF (p_ministmnt_line_type ='DISCOUNT') THEN
      BEGIN
         SELECT NVL(SUM(RACTL.extended_amount),0)
         INTO   ln_promo_and_disc
         FROM   ra_customer_trx_lines RACTL
               ,oe_price_adjustments  OEPA
         WHERE  1 = 1
         AND RACTL.line_type = 'LINE'
         AND RACTL.interface_line_attribute11   = OEPA.PRICE_ADJUSTMENT_ID
         AND EXISTS
            ( SELECT 1
              FROM  xx_ar_cons_bills_history od_summbills
                   ,xx_ar_cbi_trx xxtrx
               WHERE OD_SUMMBILLS.attribute13  =to_char(p_request_id)
               AND   OD_SUMMBILLS.cons_inv_id  =p_cbi_id
               AND   OD_SUMMBILLS.attribute8   ='PAYDOC_IC'
               AND   OD_SUMMBILLS.document_id  =p_doc_id
               AND   OD_SUMMBILLS.process_flag !='Y'
               and   OD_SUMMBILLS.cons_inv_id =   XXTRX.cons_inv_id
               AND   OD_SUMMBILLS.thread_id  =XXTRX.request_id
               AND   XXTRX.customer_trx_id   =RACTL.customer_trx_id
            );
    -- Start of changes for R1.1 Defect # 1451 (CR 626)

         lc_error_loc    := 'Getting the total gift card amount for Invoices inside discounts';
         lc_error_debug  := 'p_cbi_id : '|| to_char(p_cbi_id);

         SELECT  NVL(SUM(OP.payment_amount),0)
         INTO    ln_gc_inv_amt
         FROM    oe_payments              OP
                ,xx_ar_cons_bills_history od_summbills
                ,xx_ar_cbi_trx             XACT
         WHERE   OD_SUMMBILLS.cons_inv_id  =  XACT.cons_inv_id
         AND     OD_SUMMBILLS.thread_id    =  XACT.request_id
         AND     od_summbills.attribute13  =  TO_CHAR(p_request_id)
         AND     od_summbills.cons_inv_id  =  p_cbi_id
         AND     od_summbills.document_id  =  p_doc_id
         AND     XACT.order_header_id      =  OP.header_id
         AND     od_summbills.attribute8   =  'PAYDOC_IC'
         AND     XACT.inv_type             =  'INV'
         AND     od_summbills.process_flag != 'Y';

         lc_error_loc    := 'Getting the total gift card amount for credit memos inside discounts';
         lc_error_debug  := 'p_cbi_id : '|| to_char(p_cbi_id);

        SELECT  NVL(SUM(ORT.credit_amount),0)
        INTO    ln_gc_cm_amt
        FROM    xx_om_return_tenders_all  ORT
               ,xx_ar_cons_bills_history  od_summbills
               ,xx_ar_cbi_trx             XACT
        WHERE  OD_SUMMBILLS.cons_inv_id  =  XACT.cons_inv_id
        AND    OD_SUMMBILLS.thread_id    =  XACT.request_id
        AND    od_summbills.attribute13  =  TO_CHAR(p_request_id)
        AND    od_summbills.cons_inv_id  =  p_cbi_id
        AND    od_summbills.document_id  =  p_doc_id
        AND    XACT.order_header_id      =  ORT.header_id
        AND    od_summbills.attribute8   =  'PAYDOC_IC'
        AND    XACT.inv_type             =  'CM'
        AND    od_summbills.process_flag != 'Y';

         ln_promo_and_disc := ln_promo_and_disc - ln_gc_inv_amt + ln_gc_cm_amt;

--End of changes for R1.1 Defect # 1451 (CR 626)


         RETURN ln_promo_and_disc;
      EXCEPTION
         WHEN OTHERS THEN
         fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_infocopy_ministmnt in formula DISCOUNTS');
         RETURN 0;
      END;
   ELSIF (p_ministmnt_line_type ='TOTAL') THEN
      BEGIN
      -- Uncommented the below section for R1.3 Defect #3551
      /**/SELECT NVL(SUM(RACTL.EXTENDED_AMOUNT),0)          --Commented for R1.1 Defect # 1451 (CR 626) --Uncommented for Defect 3551
         -- INTO   lc_return_amount                          Commented for R1.3 Defect # 3551
          INTO    ln_return_amount                        -- Added for R1.3 Defect # 3551
          FROM   RA_CUSTOMER_TRX_LINES RACTL
          WHERE  1 = 1
          AND EXISTS
             ( SELECT 1
              FROM  xx_ar_cons_bills_history OD_SUMMBILLS
                   ,xx_ar_cbi_trx XXTRX
              WHERE OD_SUMMBILLS.attribute13  =to_char(p_request_id)
              AND   OD_SUMMBILLS.cons_inv_id  =p_cbi_id
              AND   OD_SUMMBILLS.attribute8   ='PAYDOC_IC'
              AND   OD_SUMMBILLS.document_id  =p_doc_id
              AND   OD_SUMMBILLS.process_flag !='Y'
              and   OD_SUMMBILLS.cons_inv_id =   XXTRX.cons_inv_id
              AND   OD_SUMMBILLS.thread_id  =XXTRX.request_id
              AND   XXTRX.customer_trx_id   =RACTL.customer_trx_id
           );/**/

         lc_error_loc    := 'Getting the total amount for Paydoc_Ic';
         lc_error_debug  := 'p_cbi_id : '|| to_char(p_cbi_id);

      -- Start of changes for R1.3 Defect # 3551
         SELECT  NVL(SUM(OP.payment_amount),0)
         INTO    ln_gc_inv_amt
         FROM    oe_payments              OP
                ,xx_ar_cons_bills_history od_summbills
                ,xx_ar_cbi_trx             XACT
         WHERE   OD_SUMMBILLS.cons_inv_id  =  XACT.cons_inv_id
         AND     OD_SUMMBILLS.thread_id    =  XACT.request_id
         AND     od_summbills.attribute13  =  TO_CHAR(p_request_id)
         AND     od_summbills.cons_inv_id  =  p_cbi_id
         AND     od_summbills.document_id  =  p_doc_id
         AND     XACT.order_header_id      =  OP.header_id
         AND     od_summbills.attribute8   =  'PAYDOC_IC'
         AND     XACT.inv_type             =  'INV'
         AND     od_summbills.process_flag != 'Y';

         lc_error_loc    := 'Getting the total gift card amount for credit memos inside discounts';
         lc_error_debug  := 'p_cbi_id : '|| to_char(p_cbi_id);

        SELECT  NVL(SUM(ORT.credit_amount),0)
        INTO    ln_gc_cm_amt
        FROM    xx_om_return_tenders_all  ORT
               ,xx_ar_cons_bills_history  od_summbills
               ,xx_ar_cbi_trx             XACT
        WHERE  OD_SUMMBILLS.cons_inv_id  =  XACT.cons_inv_id
        AND    OD_SUMMBILLS.thread_id    =  XACT.request_id
        AND    od_summbills.attribute13  =  TO_CHAR(p_request_id)
        AND    od_summbills.cons_inv_id  =  p_cbi_id
        AND    od_summbills.document_id  =  p_doc_id
        AND    XACT.order_header_id      =  ORT.header_id
        AND    od_summbills.attribute8   =  'PAYDOC_IC'
        AND    XACT.inv_type             =  'CM'
        AND    od_summbills.process_flag != 'Y';

         ln_return_amount := ln_return_amount - ln_gc_inv_amt + ln_gc_cm_amt;
     -- End of changes for R1.3 Defect # 3551

    -- Commented for R1.3 Defect # 3551
    -- Start of changes for R1.1 Defect # 1451 (CR 626)
         /*SELECT  NVL(od_summbills.attribute14,0)
         INTO    ln_return_amount
         FROM    xx_ar_cons_bills_history od_summbills
                ,xx_ar_cons_bills_history od_summbills1
         WHERE   od_summbills1.attribute6    = od_summbills.cons_inv_id
         AND     od_summbills1.attribute13   = TO_CHAR(p_request_id)
         AND     od_summbills1.document_id   = p_doc_id
         AND     od_summbills1.cons_inv_id   = p_cbi_id
         AND     od_summbills1.attribute8    ='PAYDOC_IC'
         AND     od_summbills1.process_flag != 'Y';
    --End of changes for R1.1 Defect # 1451 (CR 626)
         */
         RETURN ln_return_amount;

      EXCEPTION
         WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Error @ xx_ar_cbi_infocopy_ministmnt in formula TOTAL');
            RETURN(0);
      END;
   END IF;
   EXCEPTION
      WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log ,'Error in function xx_ar_cbi_infocopy_ministmnt');
      fnd_file.put_line(fnd_file.log ,'Request           ID :'||p_request_id);
      fnd_file.put_line(fnd_file.log ,'Infocopy Cons Inv ID :'||p_cbi_id);
      fnd_file.put_line(fnd_file.log ,'Document          ID :'||p_doc_id);
      fnd_file.put_line(fnd_file.log ,'Type                 :'||p_ministmnt_line_type  );
      RETURN 0;
    -- changes for defect 13937 ends
   END get_paydoc_ic_totals;

   /* This function is added as part of CR 460 to get site use ids by considering
     new mailing address for the scenerio 'INV_IC' for the defect # 10750 */

   FUNCTION get_inv_ic_siteuse_id(p_cust_account_id NUMBER
                                 ,p_cust_acct_site_id  NUMBER
                                 ,p_cust_doc_id  NUMBER
                                 ,p_ship_to_site_use_id  NUMBER
                                 ,p_direct_flag  VARCHAR2
                                 )
    RETURN NUMBER
AS
ln_site_use_id NUMBER;
BEGIN
                BEGIN

                    SELECT  HCSU.site_use_id
                    INTO    ln_site_use_id
                    FROM    xx_cdh_acct_site_ext_b  XCASE
                           ,hz_cust_site_uses_all  HCSU
                           ,hz_cust_acct_sites_all  HCAS
                    WHERE   XCASE.cust_acct_site_id = p_cust_acct_site_id
                    AND     XCASE.attr_group_id     = g_attr_group_id_site
                    AND     XCASE.n_ext_attr1       = p_cust_doc_id
                    AND     HCSU.cust_acct_site_id  = HCAS.cust_acct_site_id
                    AND     XCASE.c_ext_attr5       = HCAS.orig_system_reference
                    AND     HCSU.site_use_code      = 'SHIP_TO'
                    AND     XCASE.c_ext_attr20      = 'Y';                 -- Added for R1.3 CR 738 Defect 2766

                  EXCEPTION
                  WHEN NO_DATA_FOUND THEN

                     IF (p_direct_flag = 'Y') THEN

                        SELECT  HCSU.site_use_id
                        INTO    ln_site_use_id
                        FROM    hz_cust_acct_sites HCAS
                               ,hz_cust_site_uses  HCSU
                        WHERE HCAS.cust_account_id = p_cust_account_id
                        AND   HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
                        AND   HCSU.site_use_code   = 'BILL_TO'
                        AND   primary_flag         = 'Y';

                     ELSE

                        ln_site_use_id  := p_ship_to_site_use_id ;

                     END IF;

                 END;
return ln_site_use_id;

end get_inv_ic_siteuse_id;

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
   RETURN VARCHAR2
   AS

      ln_doc_attr_id            ego_attr_groups_v.attr_group_id%TYPE;
      ln_site_attr_id           ego_attr_groups_v.attr_group_id%TYPE;
      lc_error_location         VARCHAR2(2000)    := NULL;
      lc_mail_to_attn           VARCHAR2(150);
      lc_mail_to_attn_doc       VARCHAR2(150);
      lc_paydoc_ind             VARCHAR2(1);
      lc_delivery_method        xx_cdh_cust_acct_ext_b.c_ext_attr3%TYPE;
      lc_mail_to_attn_site      VARCHAR2(150);

   BEGIN

      lc_error_location     := 'Fetching the attr_group_id at Customer Document and site Level';
      SELECT attr_group_id
      INTO   ln_doc_attr_id
      FROM   ego_attr_groups_v
      WHERE  attr_group_type   = 'XX_CDH_CUST_ACCOUNT'
      AND    attr_group_name   = 'BILLDOCS';

      SELECT attr_group_id
      INTO   ln_site_attr_id
      FROM   ego_attr_groups_v
      WHERE  attr_group_type   = 'XX_CDH_CUST_ACCT_SITE'
      AND    attr_group_name   = 'BILLDOCS';

      IF p_cust_doc_id IS NULL THEN

         lc_error_location     := 'Fetching the Mail To Attention when cust_doc_id IS NULL';
         SELECT  XCCAEB.c_ext_attr15
         INTO    lc_mail_to_attn
         FROM    xx_cdh_cust_acct_ext_b  XCCAEB
         WHERE   XCCAEB.attr_group_id         = ln_doc_attr_id
         AND     XCCAEB.cust_account_id       = p_cust_account_id
         AND     TRUNC(SYSDATE)               BETWEEN XCCAEB.d_ext_attr1 AND NVL(XCCAEB.d_ext_attr2,TRUNC(SYSDATE))
         AND     XCCAEB.c_ext_attr16          = 'COMPLETE'
         AND     XCCAEB.c_ext_attr2           = 'Y'
         AND     ROWNUM                       = 1;

      ELSE

         lc_error_location     := 'Fetching the cust_doc_id details if cuse_doc_id IS NOT NULL';
         SELECT  c_ext_attr15
                ,c_ext_attr2
                ,c_ext_attr3
         INTO    lc_mail_to_attn_doc
                ,lc_paydoc_ind
                ,lc_delivery_method
         FROM    xx_cdh_cust_acct_ext_b   XCCAEB
         WHERE   XCCAEB.attr_group_id         = ln_doc_attr_id
         AND     XCCAEB.cust_account_id       = p_cust_account_id
         AND     XCCAEB.c_ext_attr16          = 'COMPLETE'
         AND     XCCAEB.n_ext_attr2           = p_cust_doc_id;

         lc_error_location     := 'Checking the document for Infocopy and Delivery Method not in ELEC';
         IF lc_paydoc_ind = 'N' AND lc_delivery_method <> 'ELEC' THEN

            lc_error_location     := 'Fetching the Mail To Attention at Exception Site Level';
            BEGIN
               SELECT XCASE.c_ext_attr3
               INTO   lc_mail_to_attn_site
               FROM   xx_cdh_acct_site_ext_b    XCASE
                     ,hz_cust_site_uses_all     HCSU
                     ,hz_cust_acct_sites_all    HCASA
               WHERE  HCSU.site_use_id             = p_site_use_id
               AND    HCSU.cust_acct_site_id       = HCASA.cust_acct_site_id
               AND    HCASA.orig_system_reference  = XCASE.c_ext_attr5
               AND    XCASE.n_ext_attr1            = p_cust_doc_id
               AND    XCASE.attr_group_id          = ln_site_attr_id
               AND    XCASE.c_ext_attr20           = 'Y';
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  lc_error_location     := 'When No Data Found Exception in fetching Mail To Exception at Exception Site Level';
                  lc_mail_to_attn_site := NULL;
               WHEN OTHERS THEN
                  lc_error_location     := 'When Others Exception in fetching Mail To Exception at Exception Site Level';
                  lc_mail_to_attn_site := NULL;
            END;
         END IF;

         IF lc_mail_to_attn_site IS NULL THEN
            IF lc_mail_to_attn_doc IS NULL THEN
               lc_mail_to_attn := 'ACCTS PAYABLE';
            ELSE
               lc_mail_to_attn := lc_mail_to_attn_doc;
            END IF;
         ELSE
            lc_mail_to_attn := lc_mail_to_attn_site;
         END IF;

     END IF;

     IF lc_mail_to_attn IS NULL THEN
        lc_mail_to_attn := 'ACCTS PAYABLE';
     END IF;

     lc_mail_to_attn := 'ATTN: '||lc_mail_to_attn;

     RETURN (UPPER(lc_mail_to_attn));

   EXCEPTION
   WHEN OTHERS THEN

      lc_mail_to_attn  := 'ATTN: ACCTS PAYABLE';
      FND_FILE.PUT_LINE(FND_FILE.LOG,'When others exception in '||lc_error_location||CHR(13)||'SQLERRM : '||SQLERRM);
      RETURN (lc_mail_to_attn);

   END GET_MAIL_TO_ATTN;

END xx_ar_print_summbill;
/